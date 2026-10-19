-- Connect the tested match rules to native flight and authoritative combat.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Match=require(script.Parent.MatchService)
local MatchRules=require(game.ReplicatedStorage.FlyFightPaper.Shared.MatchRules)
local Config=require(Root.Generated.Gameplay)
local Economy=require(Root.Generated.Economy)
local ServerConfig=require(Root.Generated.Server)
local ServiceRules=require(Root.Shared.ServiceRules)
local RewardQueue=require(script.Parent.RewardQueue)
local VoteRings=require(script.Parent.VoteRings)
local Runtime={};Runtime.__index=Runtime
function Runtime.new(flight,combat,bots,profiles,commerce)
 local self=setmetatable({flight=flight,combat=combat,bots=bots,profiles=profiles,joined={},sequence=0,earningCursor=0,clock=0,finished=false},Runtime)
 self.matchmaking=require(script.Parent.Matchmaking).new(profiles)
 self.engine=Match.new({clock={now=os.clock},config=Config,economy=Economy,sessionId=Http:GenerateGUID(false):gsub("%-",""):sub(1,12),seed=ServerConfig.round.seed,
  allowStudioTestUsers=Run:IsStudio(),combatDrainState=function() return {through=os.clock(),blocked=false} end})
 self.bots.match=self.engine
 self.rings=VoteRings.new(flight.room)
 if Run:IsStudio() then
  local status=Instance.new("BindableFunction");status.Name="MatchStatus";status.Parent=game.ServerStorage
  status.OnInvoke=function()return self.engine:snapshot(),self.engine.round and self.engine.round.lifeBounds,self.rejections,{records=flight.records,lastRound=self.lastRound,elapsed=self.engine.round and self.engine.now-self.engine.round.startedAt,fired=combat.totalFired,hits=combat.totalHits,flightMs=flight.lastWorkMs,combatMs=combat.lastWorkMs,botMs=bots.lastWorkMs} end
 end
 self.view=Instance.new("RemoteEvent");self.view.Name="RoundView";self.view.Parent=Root
 self.profileView=Instance.new("RemoteEvent");self.profileView.Name="ProfileView";self.profileView.Parent=Root
 self.action=Instance.new("RemoteEvent");self.action.Name="RoundAction";self.action.Parent=Root
 self.hangar=require(script.Parent.HangarService).new(flight,profiles,commerce)
 flight.selectedLoadout=function(player)
  local profile=profiles:view(player)
  return profile and profile.presets[player:GetAttribute("SelectedPreset") or 1].loadout
 end
 self.action.OnServerEvent:Connect(function(player,action,value)
  if type(action)~="string" then return end
  if action=="mapReady" then
   if player:GetAttribute("ClassroomLoaded") then return end
   player:SetAttribute("ClassroomLoaded",true)
   local entry=profiles.entries[player];if entry and entry.loaded then profiles.service:setProducerMapLoaded(entry.account,true) end
   self:firstJoin(player)
   return
  end
  -- Click budget: a short burst of quick clicks always lands (a colour then a size, a preset then Save build),
  -- then one per menu_action_seconds. Overlay and the background profile refresh are passive and never spend it.
  if action~="overlay" and action~="profile" then
   local now=os.clock()
   local ok,tokens=ServiceRules.clickBudget(player:GetAttribute("MenuTokens"),player:GetAttribute("LastMenuAction"),now,ServerConfig.round.menu_action_burst,ServerConfig.round.menu_action_seconds)
   if not ok then return end
   player:SetAttribute("MenuTokens",tokens);player:SetAttribute("LastMenuAction",now)
  end
  if action=="join" then self:join(player)
  elseif action=="devMode" and Run:IsStudio() and (MatchRules.mode(value) or value=="NEXTSPOT") then
   -- Studio test mode: the next round uses this mode, and a running round ends now so the switch is quick.
   -- "NEXTSPOT" (Alan 2026-10-16): Airspace with the zone held still; each click moves it to the next spot, so every
   -- spot can be seen in one round. From another mode, the first click starts an Airspace round on spot 1.
   -- In an Airspace round it only moves the zone (from the spot it is on now); in any other mode it starts one.
   local spotOnly=value=="NEXTSPOT" and self.engine.round~=nil and self.engine.round.mode=="CONTROL"
   local current=nil;if spotOnly then current=select(2,self.engine:_zone()) end
   self.engine.devZone=value=="NEXTSPOT" and (current or self.engine.devZone or 0)%#Config.rounds.control_zones+1 or nil
   Root:SetAttribute("DevMode",value=="NEXTSPOT" and "CONTROL" or value)
   if not spotOnly and (self.engine.phase=="ACTIVE" or self.engine.phase=="COUNTDOWN") then self.engine:_close(self.engine:_clock(),"dev_mode") end
  elseif action=="endMatch" and Run:IsStudio() then
   -- Studio test button: end the running round now; the next mode is left as it was.
   if self.engine.phase=="ACTIVE" or self.engine.phase=="COUNTDOWN" then self.engine:_close(self.engine:_clock(),"dev_end") end
  elseif action=="practice" then self:practice(player,value)
  elseif action=="practiceTarget" then local p=flight.pilots[player];if p and p.practice then combat:practiceTarget(p) end
  elseif action=="tutorialFoe" then self:tutorialFoe(player,true)
  elseif action=="tutorialFoeDone" then self:tutorialFoe(player,false)
  elseif action=="practiceDone" then
   self:tutorialFoe(player,false)
   if flight.pilots[player] and flight.pilots[player].practice then self:withdraw(player) end
   -- Studio's stand-in tutorial room turns back into a normal room; a real one sends the player on to a match room.
   if Run:IsStudio() and Root:GetAttribute("DevTutorialRoom") then Root:SetAttribute("DevTutorialRoom",false);flight.tutorialRoom=false end
   self:join(player);bots:fill()
  elseif action=="withdraw" and value==true then self:withdraw(player)
  elseif action=="overlay" and type(value)=="boolean" then
   local p=flight.pilots[player];if p then p.overlay=value;if value then combat:trigger(p,1,false);combat:trigger(p,2,false) end end
  elseif action=="service" and type(value)=="string" then
   local p=flight.pilots[player];if p and flight.onService then flight.onService(p,value) end
  elseif action=="profile" then
   -- Not in the click budget (the client refreshes every 3 s), but at most once a second per player.
   if os.clock()-(player:GetAttribute("LastProfileAt") or -math.huge)>=1 then player:SetAttribute("LastProfileAt",os.clock());self:sendProfile(player) end
  elseif action=="vote" and type(value)=="string" then self:castVote(player,value)
  else self.hangar:handle(player,action,value) end
 end)
 Players.PlayerRemoving:Connect(function(player) self.joined[player]=nil end)
 flight.onRemoved=function(p) if self.engine.phase=="ACTIVE" then self.engine:withdraw(p.id) end end
 combat.onDamage=function(attacker,victim,amount,at) self:combatEvent("weaponDamage",victim,{attacker=attacker.identity,amount=amount},at) end
 combat.onDeath=function(victim,cause,killer,assists,history,damage,total,finisher)
  self:combatDeath(victim,cause,killer,assists,history,damage,total,finisher)
 end
 Run.Heartbeat:Connect(function(dt) self:step(dt) end)
 flight.active=false;bots.enabled=false;combat.enabled=false
 return self
end
function Runtime:combatDeath(victim,cause,killer,assists,history,damage,total,finisher)
 local identities={}
 local function identity(id)
  for i=#history,1,-1 do if history[i].attacker==id and history[i].identity then return history[i].identity end end
  local actor=self.flight.byId[id];return actor and actor.identity
 end
 for _,id in ipairs(assists) do
  local value=identity(id)
  if value then
   value=table.clone(value);value.share=total>0 and (damage[id] or 0)/total or 0;value.finisher=id==finisher or nil
   table.insert(identities,value)
  end
 end
 self:combatEvent("lifeEnded",victim,{killer=killer and identity(killer),assists=identities,reason=cause=="fresh" and "fresh_plane" or cause})
end
function Runtime:bind(p)
 -- A practice flight is never in the match: it can't hold the zone, score, earn or qualify (2026-10-17 audit).
 if p.practice then return end
 -- tick first: a round whose time just ran out must not take a new life (lifeStarted ticks and would refuse it)
 if self.engine:tick()~="ACTIVE" then return end
 local prior=self.profiles:view(p.player)
 local present=self.engine.round.participants[p.id]
 if not present or not present.present then
  local ok,facts=self.engine:join({key=p.id,actorId=p.id,controllerType=p.kind,userId=p.player and p.player.UserId,
   displayName=p.name,priorQualifyingMatches=prior and prior.qualification.count or 0})
  if not ok then warn("Could not join pilot: "..tostring(facts));return end
  p.team=facts.teamId
 end
 p.identity={actorId=p.id,lifeId=tostring(p.life),participationId=p.id,matchId=self.engine.round.id,teamId=p.team}
 assert(self.engine:lifeStarted(p.identity))
 p.model:SetAttribute("Team",p.team or "")
 local text=p.body.PilotName:FindFirstChildOfClass("TextLabel")
 if p.team then
  text.Text=(p.team=="team:1" and "[■] " or "[●] ")..p.name
  text.TextColor3=p.team=="team:1" and Color3.fromRGB(255,120,110) or Color3.fromRGB(110,170,255)
 else text.Text=p.name;text.TextColor3=Color3.fromHSV((p.seat*.133)%1,0.65,0.9) end -- a plane flying on into a free-for-all
end
function Runtime:combatEvent(kind,victim,extra,at)
 if not self.engine.round or not victim.identity or (self.engine.phase~="ACTIVE" and self.engine.phase~="ENDING") then return end
 if extra.reason=="vacancy" or extra.reason=="round_end" then return end
 self.sequence+=1
 local event={eventId="combat:"..self.sequence,serverSequence=self.sequence,at=at or os.clock(),kind=kind,victim=victim.identity}
 for key,value in pairs(extra) do event[key]=value end
 local ok,reason=self.engine:consumeCombat(event)
 if not ok then
  workspace:SetAttribute("CombatRejection",reason)
  if not self.rejections then self.rejections={} end
  if not self.rejections[reason] then warn("Match rejected combat: "..tostring(reason));self.rejections[reason]=event end
 end
 self:earnings()
end
function Runtime:reward(userId,source,input,at,accepted)
 if not self.rewardQueue then self.rewardQueue=RewardQueue.new(self.profiles) end
 self.rewardQueue:add(userId,source,input,at,accepted)
end
function Runtime:scorePopup(row)
 local player=Players:GetPlayerByUserId(row.userId)
 if player then Root.CombatEvents:FireClient(player,{{kind="score",reason=row.kind,points=row.points}}) end
end
function Runtime:earnings()
 local r=self.engine.round;if not r then return end
 for _,p in pairs(r.participants) do
  local record=self.flight and self.flight.records and self.flight.records[p.actorId]
  if record then record.points=p.contribution end
  if p.controllerType=="human" and p.qualified and not p.qualificationQueued then
   self:reward(p.userId,r.id..":qualification:"..p.key,{kind="qualification",matchId=r.id,activeSeconds=p.activeSeconds,events=p.qualifyingEvents})
   p.qualificationQueued=true
  end
 end
 while self.earningCursor<#r.earnings do
  local event=r.earnings[self.earningCursor+1]
  if event.controllerType=="human" then
   local totals=self.earnedTotals
   self:reward(event.userId,event.factId,{kind="contribution",points=event.points},event.at,function(input)
    local total=totals[event.actorId] or {paper=0,xp=0};totals[event.actorId]=total
    total.paper+=event.points*Economy.paper_per_point*input.multipliers.paper
    total.xp+=event.points*Economy.xp_per_point*input.multipliers.xp
   end)
   self:scorePopup(event)
  end
  self.earningCursor+=1
 end
 if self.rewardQueue then self.rewardQueue:step() end
end
function Runtime:begin(mode)
 local previous=self.engine.round
 if previous then
  self.engine:acknowledgeSettlement(previous.id,previous.settlementId)
  assert(self.engine:cleanup(previous.id,{upstreamDrained=true,livesEnded=true,replayBarrier=true}))
 end
 assert(self.engine:startRound(mode or "FFA"))
 if self.onBegin then self.onBegin() end
 self.sequence=0;self.earningCursor=0;self.finished=false;self.settled=false;self.earnedTotals={};self.finalRewards={};self.settledRows={}
 self.startShots=self.combat.totalFired;self.startHits=self.combat.totalHits
 -- Rounds never stop (Alan 2026-10-17): planes already in the room carry on into this round.
 self.flight.records={};self.flight.active=true;self.flight.safe=false;self.bots.enabled=true;self.combat.enabled=true
 self.flight:hold(false);self.rings:hide()
 for _,p in pairs(self.flight.pilots) do self.flight:newRound(p);p.team=nil end -- teams are dealt again as each joins
 for _,player in ipairs(Players:GetPlayers()) do player:SetAttribute("Vote",nil) end
 for player in pairs(self.joined) do
  if not self.matchmaking:admit(player) then self.joined[player]=nil;player:SetAttribute("InMatch",false) end
 end
 self.bots.eligibility=self.matchmaking.class or "rookie";self.bots.mode=mode or "FFA"
 self.flight.mode=mode or "FFA";self.flight.eligibility=self.bots.eligibility
 local zone=self.flight.room:FindFirstChild("ControlZone");if zone then zone.Transparency=mode=="CONTROL" and .84 or 1 end
 for player in pairs(self.joined) do
  if player.Parent and self.profiles:view(player) and not self.flight.pilots[player] then
   local profile=self.profiles:view(player)
   local p=self.flight:add(player,{loadout=profile.presets[player:GetAttribute("SelectedPreset") or 1].loadout})
   if p then self:bind(p);player:SetAttribute("JoinQueued",false) end
  end
 end
 -- Planes carried over join the new round (and get their team) before bots fill the empty desks around them.
 local function bindNew() for _,p in pairs(self.flight.pilots) do if not p.practice and (not p.identity or p.identity.matchId~=self.engine.round.id) then self:bind(p) end end end
 bindNew();self.bots:fill();bindNew()
end
-- Practice flight (Stage 6, first 60 seconds): the player flies in the live room but is nobody's enemy, is not in
-- the match and earns nothing (practice is never reward-eligible). Their screen walks them through it.
-- The tutorial's own empty room (MILESTONES "Tutorial"): a private server with no match and no bots. Studio stands in
-- for one with the DevTutorialRoom attribute on ReplicatedStorage.FlyFightPaper.
function Runtime:tutorialRoom()
 return self.matchmaking:isTutorialRoom() or (Run:IsStudio() and Root:GetAttribute("DevTutorialRoom")==true)
end
-- A brand-new player is sent to their own tutorial room as soon as the classroom has loaded (live servers only).
function Runtime:firstJoin(player)
 if self:tutorialRoom() then return end
 local data=player:GetJoinData().TeleportData
 if type(data)=="table" and data.tutorialSeen then return end
 task.spawn(function()
  local deadline=os.clock()+30
  while player.Parent and not self.profiles:view(player) and os.clock()<deadline do task.wait(.5) end
  local profile=self.profiles:view(player)
  if profile and self.matchmaking.needsTutorial(profile) and not player:GetAttribute("InMatch") then self.matchmaking:routeTutorial(player) end
 end)
end
-- The lesson's one enemy: a rookie bot that fights only this player (CombatService:enemy), from its own desk.
function Runtime:tutorialFoe(player,wanted)
 local id="tutorialFoe"..player.UserId;local foe=self.flight.byId[id]
 if not wanted then
  if foe then self.flight:remove(foe,"vacancy");self.bots.brains[id]=nil end
  player:SetAttribute("TutorialFoe",nil);return
 end
 local p=self.flight.pilots[player]
 if foe or not p or not p.practice or not self:tutorialRoom() then return end
 foe=self.flight:add(nil,{id=id,name="Paper Pal",tier="rookie",loadout=self.flight.catalog:starterLoadout(),loadoutName="pellet"})
 if foe then foe.foeOf=p.id;player:SetAttribute("TutorialFoe",id) end
end
function Runtime:practice(player,lesson)
 if not player:GetAttribute("ClassroomLoaded") or not self.profiles:view(player) then return end
 if self.flight.pilots[player] then self:withdraw(player) end
 -- Replaying the tutorial from a match room opens a private room for it (live). Studio can't move players between
 -- servers, so this room becomes the tutorial room instead: the match pauses where it is and every bot leaves.
 if not self:tutorialRoom() and not self.matchmaking:routeTutorial(player) and Run:IsStudio() then Root:SetAttribute("DevTutorialRoom",true) end
 if self:tutorialRoom() then
  -- No round here: flying, shooting and the lesson's one enemy run without a clock, a score or a roster.
  self.flight.tutorialRoom=true;self.flight.active=true;self.flight.safe=false;self.combat.enabled=true;self.bots.enabled=true
  self.flight:hold(false)
  for _,other in pairs(table.clone(self.flight.pilots)) do
   if other.kind=="bot" and not other.foeOf then self.flight:remove(other,"vacancy");self.bots.brains[other.id]=nil end
  end
 else
  if self.matchmaking.transfers[player] then return end -- on its way to a private tutorial room
  if not self.engine.round or self.engine.phase=="READY" then self:begin("FFA") end
  if self.engine.phase~="ACTIVE" then player:SetAttribute("MenuMessage","Practice opens when the next round starts.");return end
 end
 -- Lessons fly a fixed training plane (Alan 2026-10-18); the player's own builds are untouched.
 local p=self.flight:add(player,{loadout=require(Root.Shared.WeaponLoadouts).make(self.flight.catalog,"training"),loadoutName="training",practice=true})
 if not p then player:SetAttribute("MenuMessage","No free desk for practice right now. Try again in a moment.");return end
 -- Flight School can't be lost (Alan 2026-10-18): walls only bounce you off and Lift stops at 1 second.
 p.gentle=lesson=="flight"
 player:SetAttribute("InMatch",true)
end
function Runtime:join(player)
 if not player:GetAttribute("ClassroomLoaded") then player:SetAttribute("MenuMessage","The classroom is still loading.");return end
 if not self.profiles:view(player) then return end
 if not self.matchmaking:admit(player) then return end
 self.joined[player]=true;player:SetAttribute("InMatch",true)
 -- Studio test hook: ReplicatedStorage.FlyFightPaper's DevMode attribute ("TDM"/"CONTROL") picks the first round's mode.
 if not self.engine.round or self.engine.phase=="READY" then self:begin(Run:IsStudio() and Root:GetAttribute("DevMode") or "FFA")
 elseif self.engine.phase=="ACTIVE" and not self.flight.pilots[player] then
  local profile=self.profiles:view(player)
  local p=self.flight:add(player,{loadout=profile.presets[player:GetAttribute("SelectedPreset") or 1].loadout})
  if p then self:bind(p);player:SetAttribute("JoinQueued",false)
  else player:SetAttribute("JoinQueued",true);player:SetAttribute("MenuMessage","Waiting for a safe desk vacancy. You'll join automatically.") end
 end
end
function Runtime:withdraw(player)
 local p=self.flight.pilots[player]
 if p then self.flight:remove(p,"withdrawal") end
 self.joined[player]=nil;player:SetAttribute("InMatch",false)
 player:SetAttribute("JoinQueued",false)
 if self.engine.round and self.engine.phase=="ACTIVE" then self.engine:withdraw(tostring(player.UserId));self.bots:fill() end
end
-- Round end (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md): nobody leaves the room. Scoring
-- stops, nothing can hurt anyone, and every flying plane holds still for the winners' moment; the vote lap follows.
function Runtime:finish()
 if self.finished then return end
 self.flight.safe=true;self.combat.enabled=false;self.bots.enabled=false
 for _,shot in pairs(self.combat.shots) do self.combat:finish(shot) end
 assert(self.engine:sealCombatDrain(self.engine.round.id,self.engine.round.lastSequence))
 self.finished=true
 self.lastRound={mode=self.engine.round.mode,seconds=self.engine.round.endedAt-self.engine.round.startedAt,records=self.flight.records,shots=self.combat.totalFired-(self.startShots or 0),hits=self.combat.totalHits-(self.startHits or 0)}
 self:earnings()
 self:queueSettlement()
 local pilots={};for _,p in pairs(self.flight.pilots) do if p.practice then table.insert(pilots,p) end end
 for _,p in ipairs(pilots) do
  self.flight:remove(p,"round_end")
  if p.player then p.player:SetAttribute("InMatch",false) end -- practice ends with the round
 end
 self.flight:hold(true) -- each client plays the winners' cutscene (src/client/WinnersCutscene.luau)
end
-- A vote from the 1/2/3 keys, the card, or flying through a ring. The player's attribute lights their choice.
function Runtime:castVote(player,mode)
 if self.engine:vote(tostring(player.UserId),mode) then player:SetAttribute("Vote",mode) end
end
-- Each step of the vote lap: whose plane flew through a ring since last step.
function Runtime:watchRings()
 for _,p in pairs(self.flight.pilots) do
  if p.player and p.model:GetAttribute("State")=="FLYING" then
   local now=p.body.Position
   local mode=p.ringFrom and self.rings:passed(p.ringFrom,now)
   if mode then self:castVote(p.player,mode) end
   p.ringFrom=now
  else p.ringFrom=nil end
 end
end
-- What happens as the round break moves on: the vote lap frees the planes and puts up the rings; the countdown
-- takes them down again.
function Runtime:phaseChanged(phase)
 if phase=="VOTE" then
  self.flight:hold(false);self.bots.enabled=true;self.rings:show()
 elseif phase=="COUNTDOWN" then self.rings:hide() end
end
function Runtime:queueSettlement()
 local r=self.engine.round
 for _,row in ipairs(r.result.participants) do
  if row.controllerType=="human" and not self.settledRows[row.key] then
   local rewards=self.finalRewards
   if row.finalPaper>0 or row.finalXP>0 then self:reward(row.userId,r.id..":bonus:"..row.key,{kind="finalBonus",finalPaper=row.finalPaper,finalXP=row.finalXP},r.endedAt,function(input)
    rewards[row.key]={paper=row.finalPaper*input.multipliers.paper,xp=row.finalXP*input.multipliers.xp}
   end) else rewards[row.key]={paper=0,xp=0} end
   if row.qualified then self:reward(row.userId,r.id..":qualification:"..row.key,{kind="qualification",matchId=r.id,activeSeconds=row.activeSeconds,events=row.qualifyingEvents}) end
   self:reward(row.userId,r.id..":stats:"..row.key,{kind="statistics",deltas={matches=row.present and 1 or 0,wins=row.victory and row.present and 1 or 0,eliminations=row.kills,deaths=row.deaths}})
   self.settledRows[row.key]=true
  end
 end
 -- Handed off for independent retries. A failed player cannot freeze the intermission.
 self.settled=true
 if self.rewardQueue then self.rewardQueue:step() end
end
function Runtime:sendProfile(player)
 local profile=self.profiles:view(player)
 if profile then
  local e=self.profiles.entries[player]
  local boost=self.profiles.service:liveBoostView(e.account)
  self.profileView:FireClient(player,{paper=math.floor(profile.paperMilli/1000),xp=math.floor(profile.xpMilli/1000),ownership=profile.ownership,
   presets=profile.presets,settings=profile.settings,qualification=profile.qualification,statistics=profile.statistics,boosts=boost.status=="ok" and boost.value.boosts or profile.boosts,mock=self.profiles.mock})
 end
end
function Runtime:step(dt)
 self.clock+=dt;if self.clock<ServerConfig.round.step_seconds then return end;self.clock%=ServerConfig.round.step_seconds
 Root:SetAttribute("TutorialRoom",self:tutorialRoom())
 -- The tutorial room has no match: the round engine waits (Studio's stand-in room resumes its paused match after).
 if self.flight.tutorialRoom then return end
 if self.engine.round then
  if self.engine.phase=="ACTIVE" then
   for player in pairs(self.joined) do
    if player:GetAttribute("JoinQueued") and player.Parent then self:join(player) end
   end
   for _,p in pairs(self.flight.pilots) do
    if p.identity then
     self.engine:observe(p.id,{state=p.model:GetAttribute("State"),protected=self.flight:protected(p,workspace:GetServerTimeNow()),eligible=true,overlay=p.overlay==true,position=p.body.Position})
     if p.player and p.model:GetAttribute("State")=="FLYING" then
      local direction=p.body.CFrame.LookVector
      if not p.activityDirection or direction:Dot(p.activityDirection)<.995 then self.engine:controlActivity(p.id);p.activityDirection=direction end
     end
    end
   end
  end
  self.engine:tick();self:earnings()
  if self.engine.phase=="ENDING" then self:finish() end
  if self.engine.phase~=self.lastPhase then self.lastPhase=self.engine.phase;self:phaseChanged(self.engine.phase) end
  if self.engine.phase=="VOTE" then self:watchRings() end
  if self.finished and not self.settled then self:queueSettlement() end
  if self.engine.phase=="READY" and self.settled and next(self.joined) then self:begin(Run:IsStudio() and Root:GetAttribute("DevMode") or self.engine.nextMode or "FFA") end
 end
 local snapshot=table.clone(self.engine:publicSnapshot())
 if self.engine.phase=="VOTE" then self.rings:update(snapshot.voteTotals or {}) end
 snapshot.endsAt=self.engine.round and self.engine.round.endsAt;snapshot.serverTime=os.clock()
 if self.engine.round and self.engine.round.result then
  local result=table.clone(snapshot.result);result.participants={}
  for _,public in ipairs(snapshot.result.participants) do
   local copy=table.clone(public)
   for _,private in ipairs(self.engine.round.result.participants) do
    if public.actorId==private.actorId then
     local earned=self.earnedTotals[private.actorId] or {paper=private.contribution*Economy.paper_per_point,xp=private.contribution*Economy.xp_per_point}
     local final=self.finalRewards[private.key] or {paper=private.finalPaper,xp=private.finalXP}
     copy.paper=math.floor(earned.paper+final.paper)
     copy.xp=math.floor(earned.xp+final.xp)
    end
   end
   table.insert(result.participants,copy)
  end
  snapshot.result=result
 end
 self.view:FireAllClients(snapshot)
end
return Runtime
