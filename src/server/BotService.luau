local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Root=RS.FlyFightPaper
local FlightRules=require(Root.Shared.FlightRules)
local CombatRules=require(Root.Shared.CombatRules)
local Builds=require(Root.Shared.BotBuilds)
local Roster=require(Root.Shared.BotRosterRules)
local Config=require(Root.Generated.Gameplay)
local Routes=require(Root.Shared.AirRoutes)
local Landing=require(Root.Shared.ServiceRules)
local DuctRules=require(Root.Shared.DuctRules)
local Course=require(Root.Shared.TrainingCourse)
local Service={};Service.__index=Service
-- Combat Training's Pals (p.pal, set by RoundRuntime:lesson): they only fight while their player has been flying
-- for 2 seconds (Alan: smooth after a crash), so a player back from a crash isn't jumped on takeoff.
-- Pals are easy prey (Alan 2026-10-19: a Pal that turned back or chased you only made you both fly in circles;
-- 2026-10-21: still circled, "it needs to be pretty dumb when it's running"; 2026-10-22: then too dumb, killed before
-- any chase): they keep their own heading and every 2.5-4 s bank 25-50 degrees one way or the other, turning further
-- only when the way is blocked. Never away from you (that turned them every time you turned, so you both circled).
local function wander(self,b,position,now)
 if b.wanderGoal and now<b.wanderUntil and (position-b.wanderGoal).Magnitude>80 then return b.wanderGoal end
 local heading=b.heading*Vector3.new(1,0,1)
 heading=heading.Magnitude>.1 and heading.Unit or Vector3.zAxis
 local climb=math.clamp((Course.POINTS[2].Y-position.Y)*.3,-40,40) -- drift back toward the course's height
 local first=b.random:NextNumber(25,50)*(b.random:NextNumber()<.5 and -1 or 1)
 for _,turn in {first,first+40,first-40,90,-90,135,-135,180} do
  local goal=position+CFrame.Angles(0,math.rad(turn),0):VectorToWorldSpace(heading)*250+Vector3.yAxis*climb
  if self.routes:clear(position,goal,25) then b.wanderGoal,b.wanderUntil=goal,now+b.random:NextNumber(2.5,4);return goal end
 end
 b.wanderGoal,b.wanderUntil=Course.POINTS[2],now+3;return b.wanderGoal
end
-- Pals appear in the air, never out of a hangar (Alan 2026-10-19: "it's like the enemy's coming out of nowhere"):
-- 400-700 studs ahead of their player (within 40 degrees of the nose; Alan: not off to the side), in clear air inside
-- the room, hidden behind a building if one of those spots is, facing away so the player chases it. Only if nothing
-- ahead is clear: further round, then the course's middle point. The pellet Pal (step 8) instead starts behind you,
-- off to one side where you don't see it, 400-500 studs back in clear sight, flying away from you: you turn round and
-- see it running (Alan 2026-10-19/21; its "shots" are palAmbush's).
function Service:placePal(p)
 local victim=self.flight.byId[p.foeOf]
 if not victim or p.model:GetAttribute("State")~="DESK" then return end
 local from=victim.body.Position
 local heading=victim.body.CFrame.LookVector*Vector3.new(1,0,1);heading=heading.Magnitude>.1 and heading.Unit or Vector3.zAxis
 local ball=Instance.new("Part");ball.Shape=Enum.PartType.Ball;ball.Anchored,ball.CanCollide,ball.CanTouch,ball.Transparency=true,false,false,1
 ball.Size=Vector3.one*80;ball.Parent=workspace
 local half=self.flight.boundsSize/2-Vector3.one*60
 local open,hidden
 local attack=p.pal.mode=="pellet"
 for _,turn in attack and {150,-150,130,-130,170,-170,110,-110} or {0,20,-20,40,-40,70,-70,110,-110,180} do
  for _,range in attack and {450,500,400} or {600,500,700,400} do
   local at=from+CFrame.Angles(0,math.rad(turn),0):VectorToWorldSpace(heading)*range+Vector3.yAxis*20
   local inside=self.flight.boundsCF:PointToObjectSpace(at)
   ball.Position=at
   if math.abs(inside.X)<half.X and math.abs(inside.Y)<half.Y and math.abs(inside.Z)<half.Z and #workspace:GetPartsInPart(ball,self.flight.overlap)==0 then
    open=open or at
    local blocked=workspace:Raycast(from,at-from,self.flight.cast)
    -- `hidden` = the spot wanted: behind a building ahead, or (attacking) behind you with a clear shot
    if attack and not blocked or not attack and math.abs(turn)<=40 and blocked then hidden=at;break end
   end
  end
  if hidden or not attack and open and (turn==-40 or math.abs(turn)>40) then break end
 end
 ball:Destroy()
 local at=hidden or open or Course.POINTS[2]
 local away=(at-from)*Vector3.new(1,0,1);away=away.Magnitude>1 and away.Unit or heading
 p.body.CFrame=CFrame.lookAt(at,at+away);p.hasLaunched=true;self.flight:fly(p)
 -- Half a normal plane's Health in lessons (Alan 2026-10-19: full Health made them frustrating).
 p.model:SetAttribute("MaxHealth",p.stats.health/2);p.model:SetAttribute("Health",p.stats.health/2)
 local b=self.brains[p.id];if b then b.mode="launch" end
end
-- The eraser Pal's erasers appear on their own 300 studs ahead of you, toward the Pal, already chasing you, one at a
-- time with 1.5 s between (Alan 2026-10-19: not waiting for the Pal to lock; ahead so you see it coming and dodge).
function Service:palEraser(p,victim,now)
 local info=self.combat.info[p.id]
 if info.activeErasers>0 then p.pal.nextEraserAt=now+1.5;return end
 if now<(p.pal.nextEraserAt or 0) then return end
 local mount;for _,m in ipairs(info.mounts) do if m.weapon.homing then mount=m end end
 if not mount then return end
 local from=victim.body.Position
 local toward=p.body.Position-from
 local heading=(toward:Dot(victim.body.CFrame.LookVector)>0 and toward or victim.body.CFrame.LookVector)*Vector3.new(1,0,1)
 heading=heading.Magnitude>.1 and heading.Unit or Vector3.zAxis
 for _,range in {300,200} do
  for _,turn in {0,20,-20,40,-40} do
   local at=from+CFrame.Angles(0,math.rad(turn),0):VectorToWorldSpace(heading)*range
   if not workspace:Raycast(from,at-from,self.flight.cast) then self.combat:launch(p,mount,now,victim,at);return end
  end
 end
end
function Service:palReady(p,now)
 local victim=self.flight.byId[p.foeOf]
 -- Not while the lesson's note holds you still either (Alan: an eraser came at a frozen plane), nor in the first
 -- second of a step, before its freeze has reached the server: unfreezing restarts the 2 seconds (fly sets launchAt).
 return victim and victim.model:GetAttribute("State")=="FLYING" and not victim.held and now-(victim.launchAt or 0)>2
  and now-(p.pal.at or 0)>1 and victim or nil
end
-- Step 8's ambush (Alan 2026-10-21): pellets appear just behind you, out of sight, and always hit, as if the Pal far
-- behind had fired them, in bursts until your Health is half; then it only runs. None while it's in front of you,
-- where you'd see they don't come from it.
function Service:palAmbush(p,victim,now)
 if victim.model:GetAttribute("Health")<=victim.stats.health*.5 then p.pal.mode="circle";return end
 local frame=victim.body.CFrame
 if now%1.6>.8 or now<(p.pal.nextShotAt or 0) or (p.body.Position-frame.Position):Dot(frame.LookVector)>0 then return end
 local mount;for _,m in ipairs(self.combat.info[p.id].mounts) do if not m.weapon.homing then mount=m end end
 if not mount then return end
 p.pal.nextShotAt=now+mount.weapon.shot_interval
 self.combat:launch(p,mount,now,victim,frame.Position-frame.LookVector*70+frame.RightVector*math.random(-4,4)+frame.UpVector*2)
end
local MIXED_SKILLS={"rookie","regular","experienced"}
local function aimError(direction,b,now)
 local drift=math.sin(now*.8+b.seed)*b.error
 return (CFrame.lookAt(Vector3.zero,direction)*CFrame.fromOrientation(drift*math.sin(now*.29+b.seed)*.4,drift,0)).LookVector
end
-- Maneuvers are flown, not aimed at: each segment holds a turn for `t` seconds. `roll` says which way the lift
-- pulls around the nose (0 right, 90 up, -90 down, 180 left), `pull` how hard (1 = full turn rate), `spin` rolls
-- the pull around the nose while turning (a barrel roll). Mirrored for left-hand versions.
local MOVES={
 break_turn={{t=2.2,roll=10,pull=1.1}},
 snake={{t=.9,roll=0,pull=1},{t=.9,roll=180,pull=1},{t=.9,roll=0,pull=1}},
 barrel_roll={{t=2.4,roll=0,pull=.75,spin=160}},
 split_s={{t=.8,roll=-75,pull=1.1},{t=1.4,roll=-10,pull=1.1},{t=.8,roll=90,pull=.8}},
 wingover={{t=1,roll=75,pull=1},{t=1.4,roll=15,pull=1.1}},
 flat_reverse={{t=2.4,roll=5,pull=1.1}},
 extend={{t=2,roll=-12,pull=.12}},
 orbit={{t=5,roll=8,pull=.4}},
}
function Service:pickMove(b,weights,position)
 local names={};for name in pairs(weights) do table.insert(names,name) end;table.sort(names)
 local top=self.flight.boundsSize.Y
 local total,pool=0,{}
 for _,name in ipairs(names) do
  local w=weights[name]
  -- Dive moves need room under the plane, climbing ones room above.
  if name=="split_s" and position.Y<230 or name=="wingover" and position.Y>top-180 then w=0 end
  if name=="split_s" and b.quirks.split_s then w*=4 end
  if w>0 then total+=w;table.insert(pool,{name,total}) end
 end
 local roll=b.random:NextNumber()*total
 for _,entry in ipairs(pool) do if roll<entry[2] then return entry[1] end end
 return "break_turn"
end
function Service:startMove(b,now,mode,names,side)
 local segments,length={},0
 for _,name in ipairs(names) do for _,segment in ipairs(MOVES[name]) do table.insert(segments,segment);length+=segment.t end end
 -- Variety: no two moves are flown quite alike.
 b.move={mode=mode,start=now,side=side,segments=segments,scale=b.random:NextNumber(.8,1.25),tilt=b.random:NextNumber(-20,20)}
 return now+length*b.move.scale
end
function Service:moveDirection(p,b,now,turn)
 local move=b.move
 local t=(now-move.start)/move.scale
 for _,s in ipairs(move.segments) do
  if t<s.t then
   local roll=math.rad(s.roll+move.tilt+(s.spin or 0)*t)
   if move.side<0 then roll=math.pi-roll end
   local look=b.heading
   local right=look:Cross(Vector3.yAxis);right=right.Magnitude>.01 and right.Unit or p.body.CFrame.RightVector
   local up=right:Cross(look)
   -- The autopilot turns at settle*angle for small angles, so this offset asks for exactly `pull` of full rate.
   local angle=math.min(math.rad(60),s.pull*b.profile.pull*math.rad(turn)/Config.flight.autopilot_settle_per_s*1.15)
   return look*math.cos(angle)+(right*math.cos(roll)+up*math.sin(roll))*math.sin(angle)
  end
  t-=s.t
 end
 b.move=nil
 return nil
end
function Service:weaponFor(p)
 local mounts=self.combat.info[p.id].mounts
 for _,mount in ipairs(mounts) do if mount.group==1 then return mount.weapon end end
 return mounts[1] and mounts[1].weapon or self.flight.catalog:get("pellet")
end
function Service.new(flight,combat)
 local self=setmetatable({flight=flight,combat=combat,routes=Routes.new(flight),brains={},serial=0,mixed={}},Service)
 Players.PlayerAdded:Connect(function() self:fill() end);Players.PlayerRemoving:Connect(function() task.defer(function() self:fill() end) end)
 self:fill()
 Run.PreSimulation:Connect(function(dt)local start=os.clock();self:step(dt);self.lastWorkMs=(os.clock()-start)*1000 end)
 Service.active=self;return self
end
function Service:fill()
 if self.flight.active==false or self.flight.eraserDuel or self.flight.tutorialRoom then return end
 local count=0;for _ in pairs(self.flight.pilots) do count+=1 end
 -- Studio "mixed bots" test mode skips the roster rules: every build, skill, personality and quirk in turn.
 if self.flight.mixedBots then
  while count<12 do
   local k=self.mixedCount;self.mixedCount+=1
   local tier=MIXED_SKILLS[k%3+1];local loadout,build=Builds.pick(tier,k//3+1)
   self.mixed["bot-mix:"..k]=k
   if not self.flight:add(nil,{id="bot-mix:"..k,name="Mix "..(k+1),tier=tier,loadout=loadout,loadoutName=build}) then break end
   count+=1
  end
  return
 end
 while count>12 do
  local victim;for _,p in pairs(self.flight.pilots) do if p.kind=="bot" then victim=p;break end end
  if not victim then break end
  self.flight:remove(victim,"vacancy");self.brains[victim.id]=nil;count-=1
 end
 local actors=self.flight:rosterActors()
 local eligibility=self.eligibility or "rookie"
 local plan=assert(Roster.plan({eligibility=eligibility,serverClass=eligibility,seed=Config.world.seed,mode=self.mode or "FFA",config=Config,actors=actors,pendingHumanQueue={},botIdentitySerial=self.serial+1}))
 for _,row in ipairs(plan.botAdds) do
  self.serial=row.identitySerial;local loadout,build=Builds.pick(row.profileName,self.serial)
  local p=self.flight:add(nil,{id=row.actorKey,name=row.displayName,tier=row.profileName,loadout=loadout,loadoutName=build})
  if not p then break end
  if p.tier=="experienced" and p.team then
   local experienced=0;for _,other in pairs(self.flight.pilots) do if other.team==p.team and other.tier=="experienced" then experienced+=1 end end
   if experienced>1 then p.tier="regular";self:reset(p) end
  end
  count+=1
 end
end
function Service:reset(p)
 local random=Random.new(1709+p.seat*37+self.serial*101)
 local k=self.mixed[p.id]
 local tier=p.tier
 local profile=Config.bots.profiles[tier]
 self.brains[p.id]={mode="launch",nextDecision=0,launchAt=workspace:GetServerTimeNow()+1+p.seat*.22,
  reaction=random:NextNumber(profile.reaction_seconds[1],profile.reaction_seconds[2]),error=math.rad(random:NextNumber(profile.aim_error_deg[1],profile.aim_error_deg[2])),
  seed=p.seat*2.37,random=random,route={},routeAt=0,avoidAt=0,lastCheck=workspace:GetServerTimeNow(),lastPosition=p.body.Position,
  goal=Vector3.new(p.home.Position.X*.5,210,p.home.Position.Z*.4),heading=p.body.CFrame.LookVector,bank=0,profile=profile}
 local b=self.brains[p.id]
 b.lag=random:NextNumber(profile.hand_delay_seconds[1],profile.hand_delay_seconds[2]);b.tier=tier
 -- Personality is independent of skill. Quirks make bots feel like people: veterans get more and bolder ones,
 -- some rookies get one too.
 local names={"aggressive","cautious","opportunist","objective"}
 b.personality=names[random:NextInteger(1,#names)];b.style=Config.bots.personalities[b.personality]
 b.quirks={}
 local pool=table.clone(Config.bots.quirks)
 for _,chance in ipairs({Config.bots.quirk_chance[tier],Config.bots.second_quirk_chance[tier]}) do
  if random:NextNumber()<chance then b.quirks[table.remove(pool,random:NextInteger(1,#pool))]=true end
 end
 if k then
  b.personality=names[k%4+1];b.style=Config.bots.personalities[b.personality]
  local quirk=Config.bots.quirks[(k//3)%4+1];b.quirks=quirk and {[quirk]=true} or {}
 end
 if Run:IsStudio() then
  local list={};for quirk in pairs(b.quirks) do table.insert(list,quirk) end;table.sort(list)
  p.model:SetAttribute("BotStyle",tier.." "..b.personality..(#list>0 and ", "..table.concat(list,"+") or ""))
 end
end
-- Bots notice planes like people do: only in front of them (a 120 degree view), never through walls and never
-- behind them (Alan's note 17, 2026-10-13: no eyes in the back of their head, even up close).
function Service:sees(p,other)
 local delta=other.body.Position-p.body.Position
 if delta.Magnitude>900 and not self.flight.eraserDuel then return false end
 if p.body.CFrame.LookVector:Dot(delta.Unit)<.5 then return false end
 return self.combat:visible(p.body.Position,other.body.Position)
end
-- Airspace Control (Alan 2026-10-14): every bot splits its time between the zone and hunting. Each stint it rolls
-- whether it plays the zone; skill sets how often (veterans nearly always, rookies now and then). Veterans also move
-- to the next zone during the warning. Returns the zone to play, or nil to hunt.
function Service:objectiveZone(b,now)
 if self.mode~="CONTROL" or not self.match then return nil end
 local zone,_,nextIndex,moveAt=self.match:_zone()
 if not zone then return nil end
 if now>=(b.stintUntil or 0) then
  local stint=Config.bots.objective_stint_seconds
  b.stintUntil=now+b.random:NextNumber(stint[1],stint[2])
  b.onObjective=b.random:NextNumber()<b.profile.objective_drive+b.style.objective_bonus
 end
 if not b.onObjective then return nil end
 -- Match deadlines use os.clock(), unlike the bot's other server-time decisions.
 if b.profile.objective_preposition and moveAt-os.clock()<=Config.rounds.control_warning_seconds then zone=Config.rounds.control_zones[nextIndex] end
 return zone
end
-- Veterans sometimes shake a pursuer (or just wander) through the ceiling ducts: up a vent, along the rooms, out
-- another vent (DuctRules.botRuns). Only with over half their Lift and enough of it to fly the whole run (Lift drains
-- a second per second; a dry plane sinks to the duct floor), never while holding a zone, from a run that starts
-- within `reach` studs (fleeing flies straight, no dodging, so only to a near vent). Studio: workspace attribute DevDuctRuns makes every veteran take one whenever it can.
function Service:tryDuct(p,b,now,chance,reach)
 if b.duct or not chance or chance<=0 then return false end
 local dev=Run:IsStudio() and workspace:GetAttribute("DevDuctRuns")
 if not dev and b.random:NextNumber()>=chance then return false end
 local position=p.body.Position
 if position.Y>Config.world.height_studs or p.model:GetAttribute("Lift")<p.stats.lift*.5 or self.mode=="CONTROL" and b.onObjective then return false end
 local near={}
 local lift,speed=p.model:GetAttribute("Lift"),p.stats.speed*b.profile.speed_factor
 for _,run in ipairs(DuctRules.botRuns()) do
  local length,at=0,position
  for _,point in ipairs(run.points) do length+=(point-at).Magnitude;at=point end
  if (dev or (run.points[1]-position).Magnitude<reach) and lift>=length/speed*1.3+5 then table.insert(near,run) end
 end
 if #near==0 then return false end
 local run=near[b.random:NextInteger(1,#near)]
 b.duct={points=run.points,i=1,untilAt=now+75};b.target=nil;b.move=nil
 return true
end
-- While playing the zone a bot only fights planes near it (leash = how far out, in zone radii).
local function nearZone(position,zone,leash)
 local c=zone.center
 return math.abs(position.Y-c[2])<=zone.half_height+150 and (position.X-c[1])^2+(position.Z-c[3])^2<=(zone.radius*leash)^2
end
-- Spread out: each bot already chasing a plane makes it a worse pick, so bots don't all swarm one pilot.
function Service:chooseTarget(p,b,now,zone)
 local chasers={}
 for id,other in pairs(self.brains) do if id~=p.id and other.target then chasers[other.target]=(chasers[other.target] or 0)+1 end end
 local best,target=math.huge,nil
 for _,other in pairs(self.flight.pilots) do
  if self.combat:enemy(p,other) and self.combat:targetable(other,now) and other.model:GetAttribute("State")=="FLYING" and self:sees(p,other)
   and not (zone and not nearZone(other.body.Position,zone,b.profile.objective_leash)) then
   local delta=other.body.Position-p.body.Position
   local score=delta.Magnitude+(chasers[other] or 0)*300*b.style.crowd_penalty_factor+(1-p.body.CFrame.LookVector:Dot(delta.Unit))*150
    -b.style.wounded_bonus*(1-other.model:GetAttribute("Health")/other.stats.health)
   if score<best then best,target=score,other end
  end
 end
 b.target=target;b.pursueUntil=now+b.random:NextNumber(b.profile.pursuit_seconds[1],b.profile.pursuit_seconds[2])*b.style.pursuit_factor
end
-- Priority state machine, run at the bot's reaction rate. Steering (every frame) adds the avoid override.
function Service:decide(p,b,now)
 local position=p.body.Position
 local forward=p.body.CFrame.LookVector
 local lift=p.model:GetAttribute("Lift")
 local nearestFan,fanDistance=nil,math.huge
 for _,fan in ipairs(self.flight.updrafts) do local d=(fan.Position-position).Magnitude;if d<fanDistance then nearestFan,fanDistance=fan,d end end
 local reserveNeeded=math.max(p.stats.lift*b.profile.seek_lift_at_fraction,math.min(p.stats.lift*.7,fanDistance/p.stats.speed*1.4+15))
 if now-b.lastCheck>2 then
  -- Truly stuck is slow too: a sharp plane can circle back to the same spot in 2 s at full speed.
  if (position-b.lastPosition).Magnitude<25 and p.body.AssemblyLinearVelocity.Magnitude<40 then b.recoverUntil=now+2;b.recoverGoal=position-forward*140+Vector3.new(0,65,0) end
  b.lastPosition=position;b.lastCheck=now
 end
 -- Break away when shot at (a hit, or a shot passing close), but not on every pellet: a bot that dodges each hit
 -- can never be caught. Bots never read where an enemy is pointing (Alan's note 17): only shots tell them.
 -- The break is a flown maneuver (hard turn, snake, barrel roll, split-S, wingover).
 -- Bots get the same eraser warnings a player sees (Alan, 2026-10-13), but use them like pilots of their skill:
 -- each lock-on and each eraser gets one roll (eraser_notice, eraser_break), so even veterans miss some, and a
 -- break comes a little late (eraser_break_late_seconds). Whether a break escapes is down to the plane's own speed
 -- and turn: small agile planes shake erasers, heavy ones mostly don't.
 local model=p.model
 local incoming=now<(model:GetAttribute("EraserIncomingUntil") or 0) and (model:GetAttribute("EraserDistance") or math.huge)<Config.combat.eraser_break_studs
 local locking=now<(model:GetAttribute("IncomingLockUntil") or 0) or now<(model:GetAttribute("LockingUntil") or 0)
 if locking and not b.wasLocking then b.lockNoticed=b.random:NextNumber()<b.profile.eraser_notice end
 if incoming and not b.wasIncoming then
  local late=b.profile.eraser_break_late_seconds
  b.breakAt=b.random:NextNumber()<b.profile.eraser_break and now+b.random:NextNumber(late[1],late[2]) or math.huge
 end
 b.wasLocking,b.wasIncoming=locking,incoming
 locking=locking and b.lockNoticed
 if incoming and now>=b.breakAt and not (b.move and b.move.eraserBreak and now<(b.evadeUntil or 0)) then
  b.evadeUntil=self:startMove(b,now,"evade",{"break_turn"},b.random:NextNumber()<.5 and -1 or 1)
  b.move.eraserBreak=true
  b.nextEvade=b.evadeUntil+b.profile.evade_cooldown_seconds*b.style.evade_cooldown_factor
 elseif locking and not incoming and now>=(b.nextEvade or 0) then
  local side=b.random:NextNumber()<.5 and -1 or 1
  for _,other in pairs(self.flight.pilots) do
   if other.model:GetAttribute("LockTarget")==p.id and other.body then side=forward:Cross(Vector3.yAxis):Dot(other.body.Position-position)>=0 and 1 or -1 end
  end
  b.evadeUntil=self:startMove(b,now,"evade",{self:pickMove(b,b.profile.evade_moves,position)},side)
  b.nextEvade=b.evadeUntil+b.profile.evade_cooldown_seconds*b.style.evade_cooldown_factor
 end
 local shotAt=math.max(p.lastHitAt or 0,p.shotAtAt or 0)
 if now>=(b.nextEvade or 0) and shotAt>(b.lastEvadedHit or 0) then
  b.lastEvadedHit=shotAt
  -- A veteran may run for the ducts instead of dodging (inside them it never dodges).
  if not b.duct and not self:tryDuct(p,b,now,b.profile.duct_escape_chance,500) then
   -- Good pilots turn into the attacker (the shots show where from), forcing an overshoot; rookies pick at random.
   local attacker=(p.shotAtAt or 0)>(p.lastHitAt or 0) and p.shotAtBy or p.lastHitBy
   local side=b.random:NextNumber()<.5 and -1 or 1
   if attacker and attacker.body and b.random:NextNumber()<b.profile.read_attacker then
    side=forward:Cross(Vector3.yAxis):Dot(attacker.body.Position-position)>=0 and 1 or -1
   end
   b.evadeUntil=self:startMove(b,now,"evade",{self:pickMove(b,b.profile.evade_moves,position)},side)
   -- The rest starts once the move is flown, so long moves don't chain into one endless dodge.
   b.nextEvade=b.evadeUntil+b.profile.evade_cooldown_seconds*b.style.evade_cooldown_factor
  end
 end
 local kills=self.flight.records[p.id] and self.flight.records[p.id].kills or 0
 if kills>(b.kills or kills) and b.quirks.waggle then b.celebrateUntil=now+2;b.celebrateForward=forward end
 b.kills=kills
 if b.target and not (self.combat:targetable(b.target,now) and b.target.model:GetAttribute("State")=="FLYING") then b.target=nil end
 local zone=self:objectiveZone(b,now)
 if zone and b.target and not nearZone(b.target.body.Position,zone,b.profile.objective_leash) then b.target=nil end
 local seen=b.target and self:sees(p,b.target)
 if seen then b.lastSeen=now;b.lastKnown=b.target.body.Position;b.lastVelocity=b.target.body.AssemblyLinearVelocity end
 -- Give up a run that is taking too long or got stuck, but only before the vent: once inside, the only way is through.
 if b.duct and position.Y<Config.world.height_studs and (now>b.duct.untilAt or b.recoverUntil and now<b.recoverUntil) then b.duct=nil end
 if b.duct then
  -- In the ducts there is no room to dodge or turn for a fan: finish the run.
  b.mode="duct";b.target=nil;b.goal=b.duct.points[b.duct.i]
 elseif b.move and b.move.eraserBreak and now<(b.evadeUntil or 0) then
  -- Dodging an eraser comes before everything, even heading for a fan or a repair.
  b.mode="evade";b.goal=position+forward*200
 elseif p.waitingPad and not (lift<reserveNeeded) then
  b.mode="waiting";b.target=nil;b.goal=p.model:GetAttribute("HoldingPosition") or b.goal
  if not p.model:GetAttribute("DeskAvailable") and (b.goal-position).Magnitude<75 then b.goal+=p.home.RightVector*(p.seat%2==0 and 140 or -140) end
 elseif b.recoverUntil and now<b.recoverUntil then
  b.mode="unstuck";b.goal=b.recoverGoal
 elseif lift<reserveNeeded or b.mode=="fan" and lift<p.stats.lift*.45 then
  if p.waitingPad then self.flight:clearLandingQueue(p) end
  b.mode="fan";b.target=nil
  if nearestFan then
   b.goal=nearestFan.Position
   if p.fanInside[nearestFan.Name] then b.goal=nearestFan.Position+Vector3.new(nearestFan.Size.X/2+80,0,0) end
  end
 elseif p.model:GetAttribute("Health")<p.stats.health*b.style.repair_at_fraction then
  -- Land like a pilot: line up out in the room first, then fly straight down the runway through the ring.
  local ring=Landing.approach(p.home,Config.service);local rel=ring:PointToObjectSpace(position)
  local lined=rel.Z< -80 and math.abs(rel.X)<30 and math.abs(rel.Y)<40
  b.mode="repair";b.goal=lined and (ring*CFrame.new(0,-5,60)).Position or (ring*CFrame.new(0,10,-260)).Position;b.target=nil
 elseif b.evadeUntil and now<b.evadeUntil then
  b.mode="evade";b.goal=position+forward*200
 elseif b.celebrateUntil and now<b.celebrateUntil then
  b.mode="celebrate";b.goal=position+forward*200
 elseif b.extendUntil and now<b.extendUntil then
  b.mode="extend";b.goal=position+forward*200+Vector3.new(0,25,0)
 else
  -- Keep chasing a hurt target a little longer; otherwise re-pick when the pursuit time runs out.
  if seen and now>(b.pursueUntil or 0) and b.target.model:GetAttribute("Health")<b.target.stats.health*.65 then b.pursueUntil=now+4 end
  if not seen or now>(b.pursueUntil or 0) then
   local previous=b.target;self:chooseTarget(p,b,now,zone)
   if not b.target and previous and not zone and now-(b.lastSeen or 0)<5 then b.target=previous end
   seen=b.target and self:sees(p,b.target)
   if seen then b.lastSeen=now;b.lastKnown=b.target.body.Position;b.lastVelocity=b.target.body.AssemblyLinearVelocity end
  end
  if seen then
   b.mode="chase";b.goal=b.target.body.Position
   -- Rammers fly straight into a weaker plane on purpose: the plane with less health loses a ram.
   local health=p.model:GetAttribute("Health")
   if b.quirks.rammer and (b.target.body.Position-position).Magnitude<160
    and health>=b.target.model:GetAttribute("Health")*Config.bots.ram_health_ratio[b.tier] then b.mode="ram" end
   -- Overshot: the target slipped behind us at close range. Extend away, then reverse back toward it
   -- (flat turn, wingover or split-S) instead of knife-fighting in a circle nobody wins.
   local delta=b.target.body.Position-position
   if delta.Magnitude<150 and forward:Dot(delta.Unit)<-.2 then
    local side=forward:Cross(Vector3.yAxis):Dot(delta)>=0 and 1 or -1
    b.extendUntil=self:startMove(b,now,"extend",{"extend",self:pickMove(b,b.profile.reverse_moves,position)},side)
   end
  elseif not zone and b.target and b.lastKnown and now-(b.lastSeen or 0)<5 then
   b.mode="search";b.goal=b.lastKnown+b.lastVelocity*math.min(2,now-b.lastSeen)
   if (position-b.goal).Magnitude<90 then b.target=nil end
  elseif zone then
   -- Hold the zone: circle inside it, each bot at its own height so they don't stack up.
   local c,r=zone.center,zone.radius*b.profile.objective_orbit
   b.target=nil;b.mode="objective"
   b.goal=Vector3.new(c[1]+math.cos(now*.2+b.seed)*r,c[2]+math.sin(b.seed*3.1)*zone.half_height*.5,c[3]+math.sin(now*.2+b.seed)*r)
  else
   b.target=nil;b.mode="patrol"
   if (not b.patrol or (position-b.patrol).Magnitude<90) and self:tryDuct(p,b,now,b.profile.duct_patrol_chance,900) then
    b.mode="duct";b.goal=b.duct.points[1]
   elseif not b.patrol or (position-b.patrol).Magnitude<90 then
    -- Sometimes circle for a look around before heading to the next spot.
    if b.patrol and b.random:NextNumber()<.35 then self:startMove(b,now,"patrol",{"orbit"},b.random:NextNumber()<.5 and -1 or 1) end
    b.patrol=self.routes.nodes[b.random:NextInteger(1,#self.routes.nodes)]
   end
   b.goal=b.duct and b.goal or b.patrol
   -- Studio eraser practice: the hunter always knows where you are.
   if self.flight.eraserDuel then for _,other in pairs(self.flight.pilots) do if other.kind=="human" and self.combat:targetable(other,now) then b.goal=other.body.Position end end end
  end
 end
 -- A Pal ignores the rest of the brain: it only runs, so it is easy to find and shoot.
 if p.pal then
  b.move=nil -- no stunts: the brain above sometimes starts an orbit or a break turn (Alan: "too many maneuvers")
  -- Every Pal just runs (wander). Step 8's "shots" come from palAmbush (steer); an eraser Pal's erasers come from
  -- ahead on their own (palEraser). Its hits can't fold you.
  b.target=nil;b.mode="patrol";b.goal=wander(self,b,position,now)
 end
 -- Studio spectator camera (F10) shows each bot's intent.
 if Run:IsStudio() then p.model:SetAttribute("BotIntent",b.mode..(b.target and " -> "..b.target.name or "")) end
 if b.mode=="duct" then b.route={}
 elseif now-b.routeAt>1 then
  b.routeAt=now
  b.direct=self.routes:clear(position,b.goal,18)
  if b.direct then b.route={b.goal} else b.route=self.routes:path(position,b.goal,p.body.CFrame.LookVector) end
 end
end
function Service:steer(p,b,dt,now)
 local position=p.body.Position
 -- Following a waypoint is control work, not a reaction-time decision. Fast planes can pass
 -- through a small waypoint between brain ticks and otherwise circle it until Lift runs out.
 -- Bots fly a little slower and turn a little wider than players of the same build, so a chasing player can catch up.
 local turn=p.stats.turn*b.profile.turn_factor
 local arrival=math.clamp(p.stats.speed/math.rad(turn)*1.25,45,100)
 while #b.route>1 and (position-b.route[1]).Magnitude<arrival and self.routes:clear(position,b.route[2],18) do table.remove(b.route,1) end
 local goal=b.route[1] or b.goal
 local duct=b.mode=="duct" and b.duct
 if duct then
  -- Next point once close, or once past it along the way in (a room's middle: turn for the next duct).
  local target,before=duct.points[duct.i],duct.points[duct.i-1]
  if (position-target).Magnitude<(duct.i<=2 and 120 or 70) or before and (position-target):Dot(target-before)>0 then duct.i+=1 end
  if duct.i>#duct.points then b.duct=nil end
  goal=duct.points[math.min(duct.i,#duct.points)]
 end
 local lead=self:lead(p,b,now)
 if b.mode=="chase" and b.direct and lead then
  -- Veterans steer by what they last saw, carried forward, like a pilot does; not by where the target really is.
  local view=b.profile.tracks_in_view and b.view or {position=b.target.body.Position,velocity=b.target.body.AssemblyLinearVelocity,at=now}
  local spot,drift=view.position+view.velocity*(now-view.at),view.velocity
  local delta=spot-position
  goal=(lead-position).Magnitude<450 and lead or spot
  -- Some slack between entering and leaving so the nose doesn't flick between the two aim points.
  b.lagging=delta.Magnitude<350 and b.heading:Dot(delta.Unit)<(b.lagging and .94 or .82)
  if b.lagging then
   -- Target well off the nose. Good pilots aim at its tail (lag pursuit) and turn with it, which is what
   -- makes two planes circle; rookies point straight at it and overshoot.
   goal=b.profile.lag_pursuit and spot-drift*.4 or spot
   -- High yo-yo: closing too fast to make the turn, climb out of the circle and drop back onto the tail.
   if b.profile.yo_yo and (p.body.AssemblyLinearVelocity-drift):Dot(delta.Unit)>40 then goal+=Vector3.yAxis*delta.Magnitude*.6 end
  end
 end
 if b.mode=="ram" and b.target and (lead or not b.profile.tracks_in_view) then
  local view=b.profile.tracks_in_view and b.view or {position=b.target.body.Position,velocity=b.target.body.AssemblyLinearVelocity,at=now}
  goal=view.position+view.velocity*(now-view.at+.3)
 end
 if b.mode=="celebrate" and b.celebrateForward then
  goal=position+(CFrame.lookAt(Vector3.zero,b.celebrateForward)*CFrame.fromOrientation(.25,math.sin((b.celebrateUntil-now)*math.pi*3)*.7,0)).LookVector*100
 end
 if b.move and b.move.mode~=b.mode then b.move=nil end
 local flown=b.move and self:moveDirection(p,b,now,turn)
 if flown then goal=position+flown*300
 elseif (b.mode=="patrol" or b.mode=="search") and not p.pal then
  -- People don't fly ruler lines: drift side to side and up and down while cruising.
  goal+=(p.body.CFrame.RightVector*math.sin(now*.6+b.seed)*.45+Vector3.yAxis*math.sin(now*.37+b.seed*1.7)*.15)*(goal-position).Magnitude
 end
 local delta=goal-position
 local direction=delta.Magnitude>.1 and delta.Unit or p.body.CFrame.LookVector
 local localPos=self.flight.boundsCF:PointToObjectSpace(position)
 local half=self.flight.boundsSize*.5
 if not duct and (math.abs(localPos.X)>half.X-155 or math.abs(localPos.Z)>half.Z-155) then
  local inside=Vector3.new(-localPos.X,0,-localPos.Z)
  if inside.Magnitude>.1 then direction=(direction+inside.Unit*2).Unit end
 end
 if position.Y<75 then direction=(direction+Vector3.yAxis*1.8).Unit end
 if position.Y>half.Y*2-80 and not duct then direction=(direction-Vector3.yAxis*1.8).Unit end
 -- Planes are hard to see coming head-on at 200+ studs/s closing, so look 1.5 s ahead: if another plane's
 -- closest approach would touch, swerve away from that point now, harder the sooner it comes.
 local velocity=p.body.AssemblyLinearVelocity
 for _,other in pairs(self.flight.pilots) do
  if other~=p and other.model:GetAttribute("State")=="FLYING" and not (b.mode=="ram" and other==b.target) then
   local offset=other.body.Position-position
   local closing=other.body.AssemblyLinearVelocity-velocity
   local t=closing:Dot(closing)>1 and math.clamp(-offset:Dot(closing)/closing:Dot(closing),0,1.5) or 0
   local miss=offset+closing*t
   local safe=(p.body.Size.Magnitude+other.body.Size.Magnitude)*.5+20
   if miss.Magnitude<safe and offset.Magnitude<400 then
    local away=miss.Magnitude>1 and -miss.Unit or p.body.CFrame.RightVector*(p.seat%2==0 and 1 or -1)
    direction=(direction+away*(1+3*(1-t/1.5))).Unit
   end
  end
 end
 direction=FlightRules.limitPitch(direction)
 if now>=b.avoidAt then
  b.avoidAt=now+.1
  local forward=p.body.CFrame.LookVector
  local reach=duct and 70 or math.max(150,p.stats.speed*2.1)
  local speed=math.max(p.stats.speed,p.body.AssemblyLinearVelocity.Magnitude)
  local radius=math.max(12,p.body.Size.Magnitude*.5)+3
  local function clearance(candidate)
   local at=position;local heading=forward;local distance=0
   local step=reach/speed/4
   for _=1,4 do
    heading=CombatRules.turnDirection(heading,candidate,math.rad(turn)*step)
    local travel=heading*speed*step
    local obstruction=workspace:Spherecast(at,radius,travel,self.flight.cast)
    if obstruction then return distance+obstruction.Distance end
    at+=travel;distance+=travel.Magnitude
   end
   return distance
  end
  local hit=clearance(direction)<reach-.1 or clearance(forward)<reach-.1
  b.avoid=nil
  if hit then
   -- Choose open air beside the obstacle. Turning into its normal can demand an impossible U-turn.
   local frame=CFrame.lookAt(Vector3.zero,forward)
   local best=-math.huge
   for _,yaw in ipairs({-85,-55,-30,0,30,55,85}) do
    for _,pitch in ipairs({-30,0,30}) do
     local candidate=FlightRules.limitPitch((frame*CFrame.fromOrientation(math.rad(pitch),math.rad(yaw),0)).LookVector)
     local room=clearance(candidate)
     local score=room/reach*4+candidate:Dot(direction)*.7+candidate:Dot(forward)*.25
     if score>best then best=score;b.avoid=candidate end
    end
   end
  end
 end
 if b.avoid then direction=b.avoid end
 -- Same autopilot as human pilots: the bot only chooses where to aim.
 local desired
 desired,b.bank,p.orientation.CFrame=FlightRules.autopilot(b.heading,b.bank,direction,p.stats.yaw*b.profile.turn_factor*(p.pal and .8 or 1),p.stats.pitch*b.profile.turn_factor*(p.pal and .8 or 1),dt)
 local bleed=FlightRules.turnSpeedFactor(b.heading,desired,dt,turn)
 b.heading=desired
 p.boostHeld=(b.mode=="evade" or b.mode=="extend") and b.profile.evade_boost
 -- A Pal flies at `pal.speed` times its plane's own speed, not a bot's slower share (RoundRuntime:lesson), and
 -- slower while you're far from it (Alan 2026-10-21: chasing one took a minute): you close in, then it matches you,
 -- so you catch it by cutting inside its turns (Alan 2026-10-22: 70%/95% made it too easy, no chase).
 local foe=p.pal and self.flight.byId[p.foeOf]
 local catchUp=foe and (foe.body.Position-position).Magnitude>250 and .85 or 1
 local cruise,lift=p.stats.speed*(p.pal and p.pal.speed*catchUp or b.profile.speed_factor)*(p.model:GetAttribute("BoostSpeedFactor") or 1),p.model:GetAttribute("Lift")
 if p.model:GetAttribute("Boosting") then lift=math.max(lift,1) end -- boost flies along the nose even with no Lift
 local speed=cruise*bleed
 b.glide=lift<=0 and FlightRules.glide(b.glide or b.momentum,desired,cruise,dt) or nil
 b.momentum=lift>0 and FlightRules.dive(b.momentum,desired,cruise,dt) or nil
 local velocity=FlightRules.velocity(desired,speed*(b.momentum or cruise)/cruise,lift,p.model:GetAttribute("Updraft") or 0,b.glide,cruise)
 if now<(p.model:GetAttribute("DeflectUntil") or 0) then local normal=p.model:GetAttribute("CollisionNormal") or Vector3.zero;velocity-=normal*math.min(0,velocity:Dot(normal));velocity+=normal*Config.flight.graze_slide_push_studs_s end
 p.drive.VectorVelocity=p.drive.VectorVelocity:Lerp(velocity,1-math.exp(-Config.flight.velocity_response*dt))
 if lead and (lead-position).Magnitude>.1 then self.combat.info[p.id].aim=aimError((lead-position).Unit,b,now) end
 -- Triggers are hand work too: checked every frame against the live lead, not held between decisions.
 local aim=self.combat.info[p.id].aim or p.body.CFrame.LookVector
 local aligned=lead~=nil and p.body.CFrame.LookVector:Dot((lead-position).Unit)>math.cos(math.rad(12)) and (b.target.body.Position-position).Magnitude<450
 if p.pal and p.pal.mode=="pellet" then local victim=self:palReady(p,now);if victim then self:palAmbush(p,victim,now) end end
 for group=1,2 do
  local semi,eraser=false,false
  for _,mount in ipairs(self.combat.info[p.id].mounts) do if mount.group==group then
   eraser=eraser or mount.weapon.homing
   semi=semi or (mount.weapon.fire_mode=="semiautomatic" and not mount.weapon.homing)
  end end
  if semi then self.combat:trigger(p,group,false,aim) end
  -- Bots are smart with erasers: they wait for a full lock. Guns and pencils need alignment.
  local fire=eraser and (p.model:GetAttribute("LockProgress") or 0)>=1 or not eraser and aligned
  if p.pal then
   -- A Pal's own guns never fire (step 8's shots are palAmbush's); one slow eraser at a time.
   local victim=self:palReady(p,now)
   fire=false
   if eraser and victim and p.pal.mode=="eraser" then self:palEraser(p,victim,now) end
  end
  self.combat:trigger(p,group,fire,aim)
 end
end
-- Aim tracks the target every frame like a human's hand, but from what the bot saw `lag` seconds ago (a short
-- hand-eye delay, not the slower decision reaction), then solves where the shot and the target meet. The bot only
-- learns something new while the target is in front of it (its 120 degree view).
function Service:lead(p,b,now)
 local target=b.target
 if not target or now-(b.lastSeen or 0)>=1.1 or target.model:GetAttribute("State")~="FLYING" then b.samples=nil;return nil end
 if not b.samples or b.samples.target~=target then b.samples={target=target} end
 local samples=b.samples
 if not b.profile.tracks_in_view or p.body.CFrame.LookVector:Dot((target.body.Position-p.body.Position).Unit)>.5 then
  table.insert(samples,{at=now,position=target.body.Position,velocity=target.body.AssemblyLinearVelocity})
 end
 if #samples==0 then return nil end
 -- Keep a quarter second more than the hand-eye delay, so the bot also sees how the target is turning.
 local lag=b.lag
 while #samples>1 and samples[2].at<=now-lag-.25 do table.remove(samples,1) end
 local seen,old=samples[1],samples[1]
 for _,sample in ipairs(samples) do if sample.at<=now-lag then seen=sample else break end end
 b.view=seen
 local turning=seen.at-old.at>.05 and (seen.velocity-old.velocity)/(seen.at-old.at) or Vector3.zero
 -- Skill sets lead accuracy: experts follow the whole turn, rookies lead short and shoot behind.
 local accuracy=b.profile.lead_accuracy
 local origin,weapon,age=p.body.Position,self:weaponFor(p),now-seen.at
 local predicted=seen.position
 for _=1,3 do
  local flight=CombatRules.travelTime(weapon,(predicted-origin).Magnitude)
  local t=age+math.min(2,flight==math.huge and weapon.lifetime or flight)
  predicted=seen.position+(seen.velocity*t+turning*(.5*t*t)+Vector3.yAxis*(.5*(weapon.drop or 0)*t*t))*accuracy
 end
 return predicted
end
function Service:step(dt)
 if self.enabled==false then return end
 if self.flight.mixedBots and self.mixedOn~=self.flight.mixedBots then self.mixedOn=self.flight.mixedBots;self.mixedCount=0;self:fill() end
 local now=workspace:GetServerTimeNow()
 for id,b in pairs(self.brains) do
  local p=self.flight.byId[id]
  if not p then self.brains[id]=nil;continue end
  local state=p.model:GetAttribute("State")
  if state=="DESK" and p.pal then self:placePal(p)
  elseif state=="DESK" and now>=b.launchAt then
   if not p.serviceBusy then
    if p.model:GetAttribute("Health")<p.model:GetAttribute("MaxHealth") and self.flight.onService then self.flight.onService(p,"repair")
    else
     self.flight:launch(p);b.mode="launch"
    end
   end
  elseif state=="FLYING" then
   -- Through the takeoff ring: start flying from wherever the scripted takeoff left the plane.
   if b.mode=="launch" then b.heading=p.body.CFrame.LookVector;b.bank=0;b.route={};b.routeAt=-math.huge;b.avoid=nil;b.target=nil;b.duct=nil;b.mode="patrol";b.nextDecision=0 end
   if now>=b.nextDecision then b.nextDecision=now+b.reaction;self:decide(p,b,now) end
   self:steer(p,b,dt,now)
  end
 end
end
return Service
