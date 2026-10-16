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
local Runtime={};Runtime.__index=Runtime
function Runtime.new(flight,combat,bots,profiles)
 local self=setmetatable({flight=flight,combat=combat,bots=bots,profiles=profiles,joined={},sequence=0,earningCursor=0,clock=0,finished=false},Runtime)
 self.matchmaking=require(script.Parent.Matchmaking).new(profiles)
 self.engine=Match.new({clock={now=os.clock},config=Config,economy=Economy,sessionId=Http:GenerateGUID(false):gsub("%-",""):sub(1,12),seed=ServerConfig.round.seed,
  allowStudioTestUsers=Run:IsStudio(),combatDrainState=function() return {through=os.clock(),blocked=false} end})
 self.bots.match=self.engine
 if Run:IsStudio() then
  local status=Instance.new("BindableFunction");status.Name="MatchStatus";status.Parent=game.ServerStorage
  status.OnInvoke=function()return self.engine:snapshot(),self.engine.round and self.engine.round.lifeBounds,self.rejections,{records=flight.records,lastRound=self.lastRound,elapsed=self.engine.round and self.engine.now-self.engine.round.startedAt,fired=combat.totalFired,hits=combat.totalHits,flightMs=flight.lastWorkMs,combatMs=combat.lastWorkMs,botMs=bots.lastWorkMs} end
 end
 self.view=Instance.new("RemoteEvent");self.view.Name="RoundView";self.view.Parent=Root
 self.profileView=Instance.new("RemoteEvent");self.profileView.Name="ProfileView";self.profileView.Parent=Root
 self.action=Instance.new("RemoteEvent");self.action.Name="RoundAction";self.action.Parent=Root
 self.hangar=require(script.Parent.HangarService).new(flight,profiles)
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
  elseif action=="devMode" and Run:IsStudio() and (MatchRules.mode(value) or value=="CEILING") then
   -- Studio test mode: the next round uses this mode, and a running round ends now so the switch is quick.
   -- "CEILING" is Airspace with the zone held on the ceiling spot all round.
   self.engine.devZone=value=="CEILING" and #Config.rounds.control_zones or nil
   Root:SetAttribute("DevMode",value=="CEILING" and "CONTROL" or value)
   if self.engine.phase=="ACTIVE" or self.engine.phase=="COUNTDOWN" then self.engine:_close(self.engine:_clock(),"dev_mode") end
  elseif action=="practice" then self:practice(player)
  elseif action=="practiceTarget" then local p=flight.pilots[player];if p and p.practice then combat:practiceTarget(p) end
  elseif action=="practiceDone" then if flight.pilots[player] and flight.pilots[player].practice then self:withdraw(player) end;self:join(player)
  elseif action=="withdraw" and value==true then self:withdraw(player)
  elseif action=="overlay" and type(value)=="boolean" then
   local p=flight.pilots[player];if p then p.overlay=value;if value then combat:trigger(p,1,false);combat:trigger(p,2,false) end end
  elseif action=="service" and type(value)=="string" then
   local p=flight.pilots[player];if p and flight.onService then flight.onService(p,value) end
  elseif action=="profile" then self:sendProfile(player)
  elseif action=="vote" and type(value)=="string" then self.engine:vote(tostring(player.UserId),value)
  else self.hangar:handle(player,action,value) end
 end)
 Players.PlayerRemoving:Connect(function(player) self.joined[player]=nil end)
 flight.onRemoved=function(p) if self.engine.phase=="ACTIVE" then self.engine:withdraw(p.id) end end
 combat.onDamage=function(attacker,victim,amount,at) self:combatEvent("weaponDamage",victim,{attacker=attacker.identity,amount=amount},at) end
 combat.onDeath=function(victim,cause,killer,assists,history,damage,total)
  self:combatDeath(victim,cause,killer,assists,history,damage,total)
 end
 Run.Heartbeat:Connect(function(dt) self:step(dt) end)
 flight.active=false;bots.enabled=false;combat.enabled=false
 return self
end
function Runtime:combatDeath(victim,cause,killer,assists,history,damage,total)
 local identities={}
 local function identity(id)
  for i=#history,1,-1 do if history[i].attacker==id and history[i].identity then return history[i].identity end end
  local actor=self.flight.byId[id];return actor and actor.identity
 end
 for _,id in ipairs(assists) do
  local value=identity(id)
  if value then
   value=table.clone(value);value.share=total>0 and (damage[id] or 0)/total or 0
   table.insert(identities,value)
  end
 end
 self:combatEvent("lifeEnded",victim,{killer=killer and identity(killer),assists=identities,reason=cause=="fresh" and "fresh_plane" or cause})
end
function Runtime:bind(p)
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
 if p.team then
  local text=p.body.PilotName:FindFirstChildOfClass("TextLabel")
  text.Text=(p.team=="team:1" and "[■] " or "[●] ")..p.name
  text.TextColor3=p.team=="team:1" and Color3.fromRGB(255,120,110) or Color3.fromRGB(110,170,255)
 end
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
 self.flight.records={};self.flight.active=true;self.bots.enabled=true;self.combat.enabled=true
 for player in pairs(self.joined) do
  if not self.matchmaking:admit(player) then self.joined[player]=nil;player:SetAttribute("InMatch",false) end
 end
 self.bots.eligibility=self.matchmaking.class or "rookie";self.bots.mode=mode or "FFA"
 self.flight.mode=mode or "FFA";self.flight.eligibility=self.bots.eligibility
 local zone=self.flight.room:FindFirstChild("ControlZone");if zone then zone.Transparency=mode=="CONTROL" and .84 or 1 end
 for player in pairs(self.joined) do
  if player.Parent and self.profiles:view(player) then
   local profile=self.profiles:view(player)
   local p=self.flight:add(player,{loadout=profile.presets[player:GetAttribute("SelectedPreset") or 1].loadout})
   if p then self:bind(p);player:SetAttribute("JoinQueued",false) end
  end
 end
 self.bots:fill()
 for _,p in pairs(self.flight.pilots) do if not p.practice and (not p.identity or p.identity.matchId~=self.engine.round.id) then self:bind(p) end end
end
-- Practice flight (Stage 6, first 60 seconds): the player flies in the live room but is nobody's enemy, is not in
-- the match and earns nothing (practice is never reward-eligible). Their screen walks them through it.
function Runtime:practice(player)
 if not player:GetAttribute("ClassroomLoaded") or not self.profiles:view(player) then return end
 if self.flight.pilots[player] then self:withdraw(player) end
 if not self.engine.round or self.engine.phase=="READY" then self:begin("FFA") end
 if self.engine.phase~="ACTIVE" then player:SetAttribute("MenuMessage","Practice opens when the next round starts.");return end
 local profile=self.profiles:view(player)
 local p=self.flight:add(player,{loadout=profile.presets[player:GetAttribute("SelectedPreset") or 1].loadout,practice=true})
 if not p then player:SetAttribute("MenuMessage","No free desk for practice right now. Try again in a moment.");return end
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
function Runtime:finish()
 if self.finished then return end
 self.flight.active=false;self.combat.enabled=false;self.bots.enabled=false
 for _,shot in pairs(self.combat.shots) do self.combat:finish(shot) end
 assert(self.engine:sealCombatDrain(self.engine.round.id,self.engine.round.lastSequence))
 self.finished=true
 self.lastRound={mode=self.engine.round.mode,seconds=self.engine.round.endedAt-self.engine.round.startedAt,records=self.flight.records,shots=self.combat.totalFired-(self.startShots or 0),hits=self.combat.totalHits-(self.startHits or 0)}
 self:earnings()
 self:queueSettlement()
 local pilots={};for _,p in pairs(self.flight.pilots) do table.insert(pilots,p) end
 for _,p in ipairs(pilots) do
  self.flight:remove(p,"round_end")
  if p.practice and p.player then p.player:SetAttribute("InMatch",false) end -- practice ends with the round
 end
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
  if self.finished and not self.settled then self:queueSettlement() end
  if self.engine.phase=="READY" and self.settled and next(self.joined) then self:begin(Run:IsStudio() and Root:GetAttribute("DevMode") or self.engine.nextMode or "FFA") end
 end
 local snapshot=table.clone(self.engine:publicSnapshot())
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
