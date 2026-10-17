local Queue=require(game.ServerScriptService.FlyFightPaper.RewardQueue)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture()
 local f={now=100,fail={},awards={},warnings={},players={},present={[1]=true,[2]=true},messages={}}
 for i=1,2 do f.players[i]={UserId=i} end
 local profiles={entries={},service={}}
 for i,p in ipairs(f.players) do profiles.entries[p]={account=i} end
 function profiles:playerForUserId(id) return f.players[id] end
 function profiles:hasPlayer(id) return f.present[id]==true end
 function profiles.service:operationID()return "queue"end
 function profiles:messageReward(userId,input,source)
  table.insert(f.messages,{userId=userId,input=table.clone(input),source=source})
  return not f.messageFail
 end
 function profiles.service:producerCapture(account,at)
  if f.fail[account]=="capture" then error("injected capture failure") end
  return {status="ok",value={paper=f.multiplier or 1,xp=1,at=at or f.now}}
 end
 function profiles:enqueue(player,input,source)
  if f.fail[player.UserId]=="throw" then error("injected profile failure") end
  if f.fail[player.UserId] then return false end
  f.awards[source]={player=player.UserId,input=input};return true
 end
 f.queue=Queue.new(profiles,function()return f.now end,function(message)table.insert(f.warnings,message)end)
 function f:add(id,source) self.queue:add(id,source,{kind="contribution",points=10},99) end
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("one rejecting player cannot block another player's rewards",function()
  local f=fixture();f.fail[1]=true;f:add(1,"first");f:add(2,"second");f.queue:step()
  assert(f.awards.first==nil and f.awards.second.player==2 and f.queue.players[1] and #f.warnings==1)
  f.fail[1]=nil;f.now+=2;f.queue:step()
  assert(f.awards.first.player==1 and next(f.queue.players)==nil)
 end)
 test("thrown profile and multiplier errors stay isolated",function()
  for _,failure in ipairs({"throw","capture"}) do
   local f=fixture();f.fail[1]=failure;f:add(1,"broken");f:add(2,"healthy");f.queue:step()
   assert(f.awards.healthy and not f.awards.broken and f.queue.players[1])
   f.fail[1]=nil;f.now+=2;f.queue:step();assert(f.awards.broken)
  end
 end)
 test("a retry freezes the multiplier from the first delivery attempt",function()
  local f=fixture();f.fail[1]=true;f.multiplier=2;f:add(1,"boosted");f.queue:step()
  f.fail[1]=nil;f.multiplier=1;f.now+=2;f.queue:step()
  assert(f.awards.boosted.input.multipliers.paper==2)
 end)
 test("a queued reward keeps its original payload across duplicate submissions",function()
  local f=fixture();f.fail[1]=true;f:add(1,"same")
  f.queue:add(1,"same",{kind="contribution",points=9999});f.queue:step()
  f.fail[1]=nil;f.now+=2;f.queue:step();assert(f.awards.same.input.points==10)
 end)
 test("retry and warning limits avoid busy loops and log spam",function()
  local f=fixture();f.fail[1]=true;f:add(1,"retry");f.queue:step()
  for _=1,100 do f.queue:step() end
  assert(#f.warnings==1)
  f.now+=2;f.queue:step();assert(#f.warnings==1)
  f.now+=16;f.queue:step();assert(#f.warnings==2)
 end)
 test("display callback errors cannot block reward delivery",function()
  local f=fixture();f.queue:add(1,"callback",{kind="statistics",deltas={matches=1}},nil,function()error("display failed")end)
  f:add(2,"other");f.queue:step()
  assert(f.awards.callback and f.awards.other and next(f.queue.players)==nil)
 end)
 test("an absent player's reward becomes a message with a stable operation id",function()
  local f=fixture();f.players[1]=nil;f.present[1]=false;f.messageFail=true;f:add(1,"late_assist");f.queue:step()
  local sent=f.messages[1];assert(sent.userId==1 and sent.source=="late_assist" and sent.input.rewardSource=="late_assist" and sent.input.id and f.queue.players[1])
  f.messageFail=false;f.now+=2;f.queue:step()
  assert(#f.messages==2 and f.messages[2].input.id==sent.input.id and next(f.queue.players)==nil)
  f:add(1,"late_assist");f.queue:step();assert(#f.messages==2)
 end)
 test("present players use their profile and loading or failing profiles are never messaged",function()
  local f=fixture();f:add(1,"present");f.queue:step();assert(f.awards.present and #f.messages==0)
  f.players[1]=nil;f:add(1,"loading");f.fail[2]=true;f:add(2,"retry");f.queue:step()
  assert(#f.messages==0 and f.queue.players[1] and f.queue.players[2])
 end)
 test("a blocked message cannot hold up another player's reward",function()
  local f=fixture();f.players[1]=nil;f.present[1]=false
  function f.queue.profiles:messageReward()task.wait(.1);return true end
  f:add(1,"offline");f:add(2,"online");f.queue:step();f.queue:step()
  assert(f.awards.online and f.queue.players[1].busy)
  local deadline=os.clock()+1;while f.queue.players[1] and os.clock()<deadline do task.wait() end
  assert(next(f.queue.players)==nil)
 end)
 test("close flush ignores the retry delay for absent players and leaves present players alone",function()
  local f=fixture();f.fail[1]=true;f.fail[2]=true;f:add(1,"leaver");f:add(2,"present");f.queue:step()
  f.players[1]=nil;f.present[1]=false;f.queue:flushOffline(os.clock()+1)
  assert(#f.messages==1 and f.messages[1].source=="leaver" and not f.queue.players[1] and f.queue.players[2])
 end)
 test("close flush returns at its deadline when a send is still waiting",function()
  local f=fixture();f.players[1]=nil;f.present[1]=false;local finish=false
  function f.queue.profiles:messageReward()while not finish do task.wait()end;return true end
  f:add(1,"blocked");local started=os.clock();f.queue:flushOffline(started+.1);finish=true
  assert(os.clock()-started<1 and f.queue.players[1])
  local deadline=os.clock()+1;while f.queue.players[1] and os.clock()<deadline do task.wait()end
  assert(not f.queue.players[1])
 end)
 return result
end
return Spec
