local Queue=require(game.ServerScriptService.FlyFightPaper.RewardQueue)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture()
 local f={now=100,fail={},awards={},warnings={},players={}}
 for i=1,2 do f.players[i]={UserId=i} end
 local profiles={entries={},service={}}
 for i,p in ipairs(f.players) do profiles.entries[p]={account=i} end
 function profiles:playerForUserId(id) return f.players[id] end
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
 return result
end
return Spec
