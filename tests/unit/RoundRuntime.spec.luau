local Server=game.ServerScriptService.FlyFightPaper
local Runtime=require(Server.RoundRuntime)
local MatchSpec=require(script.Parent["Match.spec"])
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 test("combat death carries damage shares without changing history identities and updates record points",function()
  local Combat=require(Server.CombatService)
  for _,case in ipairs({{60,60,50},{12,228,10},{58,2,80}}) do
   local f=MatchSpec.fixture();f:join("folder",true);f:join("victim",true);f:join("helper",true)
   local folder,victim,helper=f:identity("folder"),f:identity("victim"),table.freeze(f:identity("helper"))
   local now=workspace:GetServerTimeNow()
   local history={{attacker=helper.actorId,at=now,damage=case[1],identity=helper},
    {attacker=folder.actorId,at=now,damage=case[2],identity=folder}}
   local flight={byId={},records={}}
   for _,identity in ipairs({folder,victim,helper}) do flight.records[identity.actorId]={name=identity.actorId,kills=0,assists=0,points=17} end
   local runtime=setmetatable({engine=f.m,flight=flight,earningCursor=0},Runtime)
   function runtime:combatEvent(kind,p,extra)
    assert(kind=="lifeEnded" and p.identity==victim)
    assert(extra.assists[1]~=helper and helper.share==nil)
    assert(extra.assists[1].lifeId==helper.lifeId and extra.assists[1].participationId==helper.participationId)
    MatchSpec.near(extra.assists[1].share,case[1]/(case[1]+case[2]))
    f:event(kind,"folder","victim",extra);self:earnings()
   end
   local combat=setmetatable({flight=flight,info={[victim.actorId]={history=history}},shots={},events={},cosmeticEvents={}},Combat)
   combat.onDeath=function(p,cause,killer,assists,h,damage,total)runtime:combatDeath(p,cause,killer,assists,h,damage,total)end
   combat:death({id=victim.actorId,name="Victim",identity=victim,stats={health=120},body={Position=Vector3.zero}},"weapon")
   assert(flight.records[helper.actorId].assists==1 and flight.records[helper.actorId].points==case[3])
   assert(flight.records[folder.actorId].kills==1 and flight.records[folder.actorId].points==200)
   assert(history[1].identity==helper and helper.share==nil and #combat.info[victim.actorId].history==0)
  end
 end)
 test("big damage takes the fold and the last hitter earns an assist plus the finishing shot (Alan 2026-10-17)",function()
  local Combat=require(Server.CombatService)
  local f=MatchSpec.fixture();f:join("folder",true);f:join("victim",true);f:join("finisher",true)
  local folder,victim,finisher=f:identity("folder"),f:identity("victim"),f:identity("finisher")
  local now=workspace:GetServerTimeNow()
  local history={{attacker=folder.actorId,at=now-2,damage=96,identity=folder},{attacker=finisher.actorId,at=now,damage=24,identity=finisher}}
  local flight={byId={},records={}}
  for _,identity in ipairs({folder,victim,finisher}) do flight.records[identity.actorId]={name=identity.actorId,kills=0,assists=0,points=0} end
  local runtime=setmetatable({engine=f.m,flight=flight,earningCursor=0},Runtime)
  function runtime:combatEvent(kind,p,extra)
   assert(extra.killer.actorId==folder.actorId and extra.assists[1].finisher==true)
   f:event(kind,"folder","victim",extra);self:earnings()
  end
  local combat=setmetatable({flight=flight,info={[victim.actorId]={history=history}},shots={},events={},cosmeticEvents={}},Combat)
  combat.onDeath=function(...)runtime:combatDeath(...)end
  combat:death({id=victim.actorId,name="Victim",identity=victim,stats={health=120},body={Position=Vector3.zero}},"weapon")
  assert(flight.records[folder.actorId].kills==1 and flight.records[finisher.actorId].assists==1)
  assert(flight.records[finisher.actorId].points==20+25,"20 for a fifth of the damage, 25 for the finishing shot")
 end)
 test("human earning rows each send one score popup and record points match all earned kinds",function()
  local f=MatchSpec.fixture();f:join("a");f:join("b",true);f:join("helper",true);f:join("humanHelper")
  for i=1,3 do
   if i>1 then f:newLife("b") end
   f:event("lifeEnded","a","b",{assists={f:assist("helper",0.5),f:assist("humanHelper",0.2)}})
  end
  assert(f.m:propContribution("target:1:a","a"));assert(f.m:propContribution("prop:1","a"))
  local popups,rewards={},{}
  local runtime=setmetatable({engine=f.m,earningCursor=0,earnedTotals={},flight={records={
   [f:identity("a").actorId]={points=0},[f:identity("helper").actorId]={points=0},
   [f:identity("humanHelper").actorId]={points=0}}}},Runtime)
  function runtime:reward(userId,source,input,at,accepted)
   assert((userId==1 or userId==4) and input.kind=="contribution" and not rewards[source]);rewards[source]=input.points
   if accepted then accepted({multipliers={paper=1,xp=1}}) end
  end
  function runtime:scorePopup(row)assert(row.controllerType=="human");table.insert(popups,row)end
  runtime:earnings();runtime:earnings()
  assert(#popups==10 and runtime.earningCursor==#f.m.round.earnings)
  local counts={};local ids={}
  for _,row in ipairs(popups) do
   assert(not ids[row.factId] and rewards[row.factId]==row.points);ids[row.factId]=true
   counts[row.kind]=(counts[row.kind] or 0)+1
  end
  assert(counts.fold==3 and counts.fold_assist==3 and counts.first_fold==1 and counts.streak==1 and counts.target==1 and counts.prop==1)
  assert(runtime.flight.records[f:identity("a").actorId].points==477)
  assert(runtime.flight.records[f:identity("helper").actorId].points==150)
  assert(runtime.flight.records[f:identity("humanHelper").actorId].points==60)
  assert(runtime.earnedTotals[f:identity("helper").actorId]==nil)
  MatchSpec.near(runtime.earnedTotals[f:identity("a").actorId].paper,477*0.363)
  MatchSpec.near(runtime.earnedTotals[f:identity("a").actorId].xp,477*0.680)
  assert(f.m:propContribution("target:2:a","a"));runtime:earnings();runtime:earnings()
  assert(#popups==11 and runtime.flight.records[f:identity("a").actorId].points==527)
  assert(runtime.earningCursor==#f.m.round.earnings)
 end)
 test("score popups skip an account that has no connected player",function()
  local runtime=setmetatable({},Runtime)
  runtime:scorePopup({userId=9007199254740991,kind="fold",points=100})
 end)
 test("zone and revenge earnings each reach the human popup feed once",function()
  local f=MatchSpec.fixture("CONTROL");f:join("a");f:join("b")
  f:sample("a");f:advance(5);f:event("lifeEnded","a","b")
  f:newLife("b");f:event("lifeEnded","b","a");f:newLife("a")
  f:sample("a");f:advance(5)
  local runtime=setmetatable({engine=f.m,earningCursor=0,earnedTotals={},flight={records={
   [f:identity("a").actorId]={points=0},[f:identity("b").actorId]={points=0}}}},Runtime)
  local counts,total={},0
  function runtime:reward(userId,source,input,at,accepted)if accepted then accepted({multipliers={paper=1,xp=1}})end end
  function runtime:scorePopup(row)
   assert(row.controllerType=="human");total+=1;counts[row.kind]=(counts[row.kind] or 0)+1
   if row.kind=="zone" then assert(row.points==20 and row.userId==1) end
   if row.kind=="revenge" then assert(row.points==25 and row.userId==2) end
  end
  runtime:earnings();runtime:earnings()
  assert(total==6 and counts.zone==2 and counts.revenge==1 and counts.first_fold==1 and counts.fold==2)
  assert(runtime.flight.records[f:identity("a").actorId].points==240)
  assert(runtime.flight.records[f:identity("b").actorId].points==125)
 end)
 test("withdraw and rejoin creates a new damage-eligible life for the same account",function()
  local f=MatchSpec.fixture()
  local Catalog=require(game.ReplicatedStorage.FlyFightPaper.Shared.Catalog)
  local Flight=require(Server.FlightService)
  local catalog=Catalog.new(require(game.ReplicatedStorage.FlyFightPaper.Generated.Catalog))
  local planes=Instance.new("Folder");planes.Parent=game.ServerStorage
  local flight=setmetatable({catalog=catalog,template=game.ServerStorage.Assets.PaperPlane,planes=planes,records={["1"]={kills=0}},padReservations={}},Flight)
  local runtime=setmetatable({engine=f.m,profiles={view=function()return nil end}},Runtime)
  local player={UserId=1}
  local function newPilot()
   return {id="1",player=player,kind="human",name="Pilot",seat=1,home=CFrame.new(0,120,0),loadout=catalog:starterLoadout()}
  end
  local first=newPilot();flight:build(first);runtime:bind(first)
  assert(f.m:withdraw("1"));f:advance(1)
  local nextPilot=newPilot();flight:build(nextPilot);runtime:bind(nextPilot)
  assert(first.identity.lifeId~=nextPilot.identity.lifeId)
  f:join("target",true);f:event("weaponDamage","1","target")
  assert(f.m.round.participants["1"].damage==2 and f.m.round.participants["1"].forfeited)
  -- The round's time runs out just as a plane respawns (nothing has ticked yet): no new life, no error.
  f.clock:advance(500)
  local late=newPilot();flight:build(late);runtime:bind(late)
  assert(late.identity==nil and f.m.phase~="ACTIVE")
  planes:Destroy()
 end)
 test("Timer results drain combat before reading the finalized result",function()
  local f=MatchSpec.fixture();f:join("pilot",true);f:advance(480)
  assert(f.m.phase=="ENDING" and f.m.round.result==nil and f.m.round.endedAt==nil)
  local removed=0
  local pilot={id="pilot"}
  local runtime=setmetatable({engine=f.m,finished=false,earningCursor=0,earnedTotals={},settledRows={},
   flight={active=true,records={{cause="weapon"}},pilots={pilot},remove=function(_,p,cause)
    assert(p==pilot and cause=="round_end");removed+=1
   end},combat={enabled=true,shots={},totalFired=17,totalHits=3},bots={enabled=true}},Runtime)
  runtime:finish()
  assert(f.m.phase=="RESULTS" and f.m.round.result~=nil)
  assert(runtime.lastRound.seconds==480 and runtime.lastRound.shots==17 and runtime.lastRound.hits==3)
  assert(runtime.finished and runtime.settled and removed==1)
  assert(not runtime.flight.active and not runtime.combat.enabled and not runtime.bots.enabled)
  runtime:finish();assert(removed==1)
 end)
 test("a failed player reward cannot hold the server in results",function()
  local f=MatchSpec.fixture();f:join("a");f:join("b");f:timer()
  local failed=true;local paid={};local p1={UserId=1};local p2={UserId=2}
  local profiles={entries={[p1]={account=1},[p2]={account=2}},service={producerCapture=function()return {status="ok",value={paper=1,xp=1}}end}}
  function profiles:playerForUserId(id)return id==1 and p1 or p2 end
  function profiles:enqueue(p,input,source)if p==p1 and failed then error("save unavailable")end;paid[source]=p.UserId;return true end
  local runtime=setmetatable({engine=f.m,profiles=profiles,earningCursor=0,earnedTotals={},finalRewards={},settledRows={}},Runtime)
  runtime:earnings();runtime:queueSettlement()
  assert(runtime.settled and runtime.rewardQueue.players[1] and paid[f.matchId..":stats:b"]==2)
  f:advance(23);assert(f.m.phase=="READY")
  -- Cleanup is allowed after the handoff, even while one player's retries remain.
  assert(f.m:acknowledgeSettlement(f.matchId,f.m.round.settlementId))
  assert(f.m:cleanup(f.matchId,{upstreamDrained=true,livesEnded=true,replayBarrier=true}))
  assert(f.m:startRound("FFA"))
  failed=false
  for _,item in pairs(runtime.rewardQueue.players[1].items)do item.nextTry=0 end
  runtime.rewardQueue:step();assert(next(runtime.rewardQueue.players)==nil)
 end)
 return result
end
return Spec
