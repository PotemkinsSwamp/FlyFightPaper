local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Root=RS.FlyFightPaper
local Rules=require(Root.Shared.CombatRules)
local Lines=require(Root.Shared.Lines)
local FlightRules=require(Root.Shared.FlightRules)
local Config=require(Root.Generated.Gameplay).combat
local PaperSigns=require(Root.Generated.Gameplay).world.paper_targets
local Chalk=require(Root.Generated.Gameplay).world.chalk_eraser
local Aircraft=require(Root.Shared.Aircraft)
local HitShapes=require(script.Parent.HitShapes)
local Course=require(Root.Shared.TrainingCourse)
local Service={};Service.__index=Service
function Service.new(flight)
 local self=setmetatable({flight=flight,info={},shots={},paperDown={},serial=0,events={},clock=0,shotCount=0,totalFired=0,totalHits=0,random=Random.new(),cards={}},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="CombatEvents";self.remote.Parent=Root
 -- Tracer news can be lost without harm, so it goes unreliable; hits, kills and deaths stay reliable.
 self.cosmetics=Instance.new("UnreliableRemoteEvent");self.cosmetics.Name="CombatCosmetics";self.cosmetics.Parent=Root;self.cosmeticEvents={}
 self.input=Instance.new("RemoteEvent");self.input.Name="CombatInput";self.input.Parent=Root
 -- Shots test the room (and anything else solid) here; planes are tested separately at rewound positions.
 self.worldCast=RaycastParams.new();self.worldCast.FilterType=Enum.RaycastFilterType.Exclude
 self.worldCast.FilterDescendantsInstances={flight.planes};self.worldCast.RespectCanCollide=false
 self.trackClock=0
 self.input.OnServerEvent:Connect(function(player,packet)
  local p=flight.pilots[player];if p then self:receive(p,packet,workspace:GetServerTimeNow()) end
 end)
 for _,p in pairs(flight.pilots) do self:attach(p) end
 Run.Heartbeat:Connect(function(dt)local start=os.clock();self:step(dt);self.lastWorkMs=(os.clock()-start)*1000 end)
 HitShapes.preload({Root.Assets.AircraftParts,Root.Assets.EquipmentParts,Root.Assets:FindFirstChild("AircraftPieces")}) -- last: ipairs stops at a missing folder
 self.eraser=workspace:FindFirstChild("ChalkEraser",true) -- in the Arena
 Service.active=self;return self
end
function Service:attach(p)
 local previous=self.info[p.id]
 local now=workspace:GetServerTimeNow()
 local info={mounts={},held={false,false},roundRobin={0,0},history={},track={},activeErasers=previous and previous.activeErasers or 0,seq=0,window=0,messages={0,0},aim=p.body.CFrame.LookVector,aims={},aimData={}}
 local groups=assert(Rules.triggerGroups(p.loadout))
 for index,weaponId in ipairs(p.loadout.weapon_mounts) do
  if weaponId then local weapon=self.flight.catalog.byId[weaponId];table.insert(info.mounts,{slot=index,weapon=weapon,group=groups[index],readyAt=0,burstLeft=0,heat=0,cooling=false,heatAt=now}) end
 end
 self.info[p.id]=info
 self:publishMounts(p)
 self:publishHeat(p,now)
end
function Service:coolMount(mount,firing,now)
 mount.heat,mount.cooling=Rules.heatStep(mount.heat or 0,mount.cooling==true,firing,now-(mount.heatAt or now),mount.weapon)
 mount.heatAt=now
end
function Service:publishHeat(p,now)
 local info=self.info[p.id];local heat,cooling,count={0,0},{false,false},{0,0};local slots={}
 for _,mount in ipairs(info.mounts) do slots[mount.slot]=mount end
 for slot in ipairs(p.loadout.weapon_mounts) do
  local mount=slots[slot];local weapon=mount and mount.weapon
  local amount=mount and mount.heat or 0
  local untilAt=weapon and weapon.shots_before_cooldown and mount.cooling and now+amount*weapon.cooldown_seconds/weapon.shots_before_cooldown or 0
  p.model:SetAttribute("MountHeat"..slot,amount)
  p.model:SetAttribute("MountCoolingUntil"..slot,untilAt)
  if weapon and weapon.shots_before_cooldown then
   local group=mount.group
   count[group]+=1;heat[group]=math.max(heat[group],amount/weapon.shots_before_cooldown);cooling[group]=cooling[group] or mount.cooling
  end
 end
 for group=1,2 do
  local name=group==1 and "Primary" or "Alternate"
  p.model:SetAttribute(name.."Heat",heat[group]);p.model:SetAttribute(name.."Cooling",cooling[group]);p.model:SetAttribute(name.."HasHeat",count[group]>0)
 end
 p.model:SetAttribute("HeatUpdatedAt",now)
end
-- The shooter's client draws its own shots instantly; it needs each mount's weapon and the plane's scale.
function Service:publishMounts(p)
 local ids={}
 for slot,id in ipairs(p.loadout.weapon_mounts) do ids[slot]=id or "" end
 p.model:SetAttribute("Mounts",table.concat(ids,","))
 p.model:SetAttribute("MountScale",self.flight.catalog:get(p.loadout.body).visual_scale/2)
end
local cosmetic={shot=true,update=true,["end"]=true}
-- A new round stands every pilot's paper targets back up.
function Service:resetPaperTargets() self.paperDown={} end
function Service:emit(event) table.insert(cosmetic[event.kind] and self.cosmeticEvents or self.events,event) end
function Service:detach(p)
 HitShapes.forget(p)
 for _,c in pairs(self.cards) do if c.foeOf==p.id then self:removeCard(c) end end
 for _,shot in pairs(self.shots) do if shot.owner==p.id then self:finish(shot) end end
 self.info[p.id]=nil
end
-- The Range's targets (docs/systems/tutorial.md): each painted card is the target itself, not a plane. It holds its
-- Health, flies its set path (TrainingCourse.pose, published as `DrillPath` so the client draws it and its lead ring
-- on the same path) and only its pilot can hit it. Its `Root` follows the path so eraser lock-on and seeking work.
function Service:addCard(p,id,spec,center,side)
 local folder=workspace:FindFirstChild("RangeCards")
 if not folder then folder=Instance.new("Folder");folder.Name="RangeCards";folder.Parent=workspace end
 local model,body=Instance.new("Model"),Instance.new("Part")
 body.Name,body.Size,body.Transparency="Root",Vector3.new(26,13.6,2),1 -- HitShapes.CARD
 body.Anchored,body.CanCollide,body.CanQuery,body.CanTouch,body.CastShadow=true,false,false,false,false
 local c={id=id,name="Target",card=true,life=1,foeOf=p.id,spec=spec,t0=workspace:GetServerTimeNow(),center=center,face=p.body.Position,side=side,model=model,body=body}
 body.CFrame=self:cardPose(c,c.t0);body.Parent=model;model.PrimaryPart=body
 local function v(x) return {x.X,x.Y,x.Z} end
 model:SetAttribute("DrillPath",game:GetService("HttpService"):JSONEncode({t0=c.t0,center=v(center),face=v(c.face),side=v(side),
  speed=spec.speed,span=spec.span,depth=spec.depth,bob=spec.bob,phase=spec.phase,weave=spec.weave}))
 model:SetAttribute("Health",spec.health);model:SetAttribute("MaxHealth",spec.health);model:SetAttribute("State","FLYING")
 model:SetAttribute("RangeTarget",spec.color or "red");model:SetAttribute("DrillOf",p.player and p.player.UserId or 0)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent -- arrives whole, Root and all
 model.Name=id;model.Parent=folder;self.cards[id]=c
 return c
end
function Service:cardPose(c,at) return (Course.pose(c.spec,c.center,at-c.t0,c.face,c.side)) end
function Service:removeCard(c)
 if self.cards[c.id]~=c then return end
 self.cards[c.id]=nil;c.model:Destroy()
end
function Service:receive(p,packet,now)
 if type(packet)~="table" then return false end
 local info=self.info[p.id]
 if not info or packet.life~=p.life or not FlightRules.finite(packet.seq) or packet.seq%1~=0 or packet.seq<=info.seq or packet.seq>info.seq+2000 then return false end
 if packet.group~=1 and packet.group~=2 or type(packet.down)~="boolean" then return false end
 if now-info.window>=1 then info.window=now;info.messages={0,0} end
 -- Releases never depend on a stale aiming transform. Origins always come from the server's mount.
 -- ponytail: releases are never capped, so a trigger can always be let go; each costs one table write.
 if packet.down then
  info.messages[packet.group]+=1;if info.messages[packet.group]>60 then return false end
  if not FlightRules.finite(packet.at) or packet.at>now+.1 or now-packet.at>Config.input_delay_allowance_seconds then return false end
  if not FlightRules.vector(packet.direction) or math.abs(packet.direction.Magnitude-1)>.01 then return false end
  -- The client's claimed age can't exceed its measured round trip (+0.1 s), so it can't widen its own aim cone.
  local ping=p.player and p.player:GetNetworkPing() or 0
  local age=math.clamp(math.min(now-packet.at,ping+.1),0,Config.input_delay_allowance_seconds)
  local arc=math.rad(math.min(Config.input_max_aim_deg,Config.input_aim_slack_deg+(p.stats.turn)*(age+.1)))
  if p.body.CFrame.LookVector:Dot(packet.direction)<math.cos(arc) then return false end
  -- Where the guns meet: the client's target range (clamped; only moves where the two streams cross).
  local range=FlightRules.finite(packet.range) and math.clamp(packet.range,20,1000) or nil
  info.aimData[packet.group]={arc=arc,at=now,latency=age,range=range};info.latency=age
 end
 info.seq=packet.seq;self:trigger(p,packet.group,packet.down,packet.down and packet.direction or nil)
 return true
end
function Service:refit(p)
 local info=self.info[p.id];if not info then return end
 local now=workspace:GetServerTimeNow()
 for _,mount in ipairs(info.mounts) do self:coolMount(mount,info.held[mount.group] and self:eligible(p) and not p.overlay,now) end
 local previous={};for _,m in ipairs(info.mounts) do previous[m.slot]=m end
 info.mounts={};info.held={false,false};info.aims={};info.aimData={};info.roundRobin={0,0};info.lockPilot=nil;self:publishMounts(p)
 local groups=assert(Rules.triggerGroups(p.loadout))
 for slot,id in ipairs(p.loadout.weapon_mounts) do
  if id then
   local weapon=self.flight.catalog:get(id);local old=previous[slot]
   local ready=old and old.weapon.id==id and old.readyAt or now+(weapon.burst_period or weapon.shot_interval)
   local same=old and old.weapon.id==id
   if old and old.cooling and not same then ready=math.max(ready,now+old.heat*old.weapon.cooldown_seconds/old.weapon.shots_before_cooldown) end
   table.insert(info.mounts,{slot=slot,weapon=weapon,group=groups[slot],readyAt=math.max(old and old.readyAt or 0,ready),burstLeft=0,
    heat=same and old.heat or 0,cooling=same and old.cooling or false,heatAt=now})
  end
 end
 self:publishHeat(p,now)
end
function Service:visible(from,to)
 local delta=to-from
 if Rules.chalkBlocks(self.eraser,from,to,workspace:GetServerTimeNow(),Chalk) then return false end
 if delta.Magnitude<.01 then return true end
 return workspace:Raycast(from,delta,self.flight.cast)==nil
end
function Service:eligible(p)
 return self.enabled~=false and p and p.model.Parent and p.model:GetAttribute("State")=="FLYING" and not p.held -- held still: no firing
end
function Service:targetable(p,now)
 return self.enabled~=false and p and p.model.Parent and p.model:GetAttribute("State")~="DESTROYED" and not self.flight:protected(p,now or workspace:GetServerTimeNow())
end
-- Chalk eraser easter egg (MILESTONES D14): any shot that hits the dropped eraser puffs a chalk cloud round it,
-- unless it puffed in the last few minutes. Clients draw the cloud from the attributes.
function Service:chalkHit(part,now)
 local eraser=self.eraser
 if not eraser or not part:IsDescendantOf(eraser) or now<(eraser:GetAttribute("CloudReadyAt") or 0) then return end
 eraser:SetAttribute("CloudAt",eraser:GetBoundingBox().Position+Vector3.new(0,Chalk.radius*.35,0))
 eraser:SetAttribute("CloudUntil",now+Chalk.seconds);eraser:SetAttribute("CloudReadyAt",now+Chalk.cooldown_seconds)
end
-- Practice pilots (first 60 seconds) are nobody's enemy: they can't hit or be hit, and bots ignore them.
function Service:enemy(a,b)
 -- Except the tutorial's one enemy and the pilot it was made for.
 if a~=b and (a.foeOf==b.id or b.foeOf==a.id) then return true end
 return a~=b and not a.practice and not b.practice and (not a.team or not b.team or a.team~=b.team)
end
function Service:trigger(p,which,down,aim)
 local info=self.info[p.id];if not info then return end
 local now=workspace:GetServerTimeNow();local old=info.held[which]
 for _,mount in ipairs(info.mounts) do if mount.group==which then self:coolMount(mount,old and self:eligible(p) and not p.overlay,now) end end
 info.held[which]=down;info.aim=aim or p.body.CFrame.LookVector
 info.aims=info.aims or {};info.aims[which]=info.aim
 if not down or not self:eligible(p) or p.overlay then return end
 if not old then
  -- A short click may arrive and release between server frames. Fire its first round here.
  for _,mount in ipairs(info.mounts) do if mount.group==which and mount.readyAt<=now then
   if mount.weapon.fire_mode=="automatic" then self:fire(p,mount,now)
   elseif mount.weapon.fire_mode=="burst" and mount.burstLeft==0 and self:fire(p,mount,now) then
    mount.readyAt=now+mount.weapon.burst_period;mount.burstLeft=mount.weapon.burst_count-1;mount.burstNext=now+mount.weapon.burst_spacing
   end
  end end
  local index=Rules.readyMount(info.mounts,which,now,info.roundRobin[which],"semiautomatic")
  if index and info.mounts[index].weapon.fire_mode=="semiautomatic" then
   if self:fire(p,info.mounts[index],workspace:GetServerTimeNow()) then info.roundRobin[which]=index end
  end
 end
end
function Service:lock(p,info,now)
 local hasEraser=false
 for _,m in ipairs(info.mounts) do if m.weapon.homing then hasEraser=true end end
 if not hasEraser or not self:eligible(p) then p.model:SetAttribute("LockProgress",0);return end
 -- Lock the enemy nearest the nose, then stay on it while it remains in a slightly wider cone. Without the
 -- stickiness the lock jumps between planes flying close together and the timer never finishes.
 local function cone(target,degrees)
  if not self:enemy(p,target) or not self:targetable(target,now) then return nil end
  local d=target.body.Position-p.body.Position;local distance=d.Magnitude
  if distance<=.1 or distance>Config.eraser_lock_range then return nil end
  local dot=p.body.CFrame.LookVector:Dot(d.Unit)
  return dot>math.cos(math.rad(degrees)) and self:visible(p.body.Position,target.body.Position) and dot or nil
 end
 local candidate=info.lockPilot and cone(info.lockPilot,Config.eraser_lock_keep_deg) and info.lockPilot or nil
 if not candidate then
  local best=-1
  for _,list in {self.flight.pilots,self.cards} do
   for _,target in pairs(list) do
    local dot=cone(target,Config.eraser_lock_cone_deg)
    if dot and dot>best then candidate,best=target,dot end
   end
  end
 end
 if info.lockPilot~=candidate then info.lockPilot=candidate;info.lockAt=now end
 local progress=candidate and math.clamp((now-info.lockAt)/Config.eraser_lock_seconds,0,1) or 0
 p.model:SetAttribute("LockProgress",progress);p.model:SetAttribute("LockName",candidate and candidate.name or "")
 p.model:SetAttribute("LockTarget",candidate and candidate.id or "")
 -- The target is told while it is being locked (quiet warning) and once the lock is complete (loud warning).
 if candidate then candidate.model:SetAttribute(progress>=1 and "IncomingLockUntil" or "LockingUntil",now+.25) end
end
function Service:fire(p,mount,now)
 if self.shotCount>=768 or not self:eligible(p) or p.overlay or (mount.readyAt>now and mount.weapon.fire_mode~="burst") then return false end
 local info=self.info[p.id];local weapon=mount.weapon
 self:coolMount(mount,info.held and info.held[mount.group] and self:eligible(p) and not p.overlay,now)
 local heat,cooling,allowed=Rules.heatShot(mount.heat,mount.cooling,weapon)
 if not allowed then return false end
 local target
 if weapon.homing then
  -- Fires the moment you click (Alan, 2026-10-13): locked, it seeks; not locked yet (or nothing in the circle),
  -- it flies straight like a pencil. Waiting for the lock is the smart play, never forced.
  if not Rules.canEraser(info.activeErasers) then return false end
  if info.lockPilot and now-info.lockAt>=Config.eraser_lock_seconds and self:targetable(info.lockPilot,now)
   and self:visible(p.body.Position,info.lockPilot.body.Position) then target=info.lockPilot end
 end
 if not self:launch(p,mount,now,target) then return false end
 Rules.consume(mount,now)
 mount.heat,mount.cooling=heat,cooling
 if cooling then self:publishHeat(p,now) end
 return true
end
-- `origin`: the shot starts there, aimed at `target`, instead of at the plane's gun (the eraser Pal's erasers).
function Service:launch(p,mount,now,target,origin)
 if not self:eligible(p) then return false end
 local info=self.info[p.id];local weapon=mount.weapon
 local direction=info.aims and info.aims[mount.group] or info.aim or p.body.CFrame.LookVector
 local aimData=info.aimData and info.aimData[mount.group]
 local arc=p.kind=="human" and aimData and now-aimData.at<.3 and aimData.arc or math.rad(25)
 if p.body.CFrame.LookVector:Dot(direction)<math.cos(arc) then direction=p.body.CFrame.LookVector end
 local factor=self.flight.catalog:get(p.loadout.body).visual_scale/2
 local position=p.body.CFrame:PointToWorldSpace(Aircraft.muzzleOffset(mount.slot,factor,mount.weapon.id,Aircraft.fitOf(p.model)))
 -- Bots' guns meet at 150 studs, except where BotService sets info.range (the tutorial's hunting Pal).
 direction=Aircraft.converge(p.body,position,direction,p.kind=="human" and aimData and aimData.range or info.range or Config.gun_convergence_studs)
 if weapon.spread_deg>0 then
  local spread=math.rad(weapon.spread_deg)
  direction=(CFrame.lookAt(Vector3.zero,direction)*CFrame.Angles(self.random:NextNumber(-spread,spread),self.random:NextNumber(-spread,spread),0)).LookVector
 end
 if origin then position,direction=origin,(target.body.Position-origin).Unit
 elseif self.flight.inServiceZone and self.flight:inServiceZone(p,position) then return false end
 p.spawnProtectionUntil=0
 self.serial+=1
 -- Humans aim at where they saw targets. Their view is one trip old (positions reaching them) plus Roblox's
 -- display smoothing, and their shot took another trip to get here, so rewind two trips plus smoothing, capped.
 local latency=aimData and aimData.latency or 0
 local rewind=p.kind=="human" and math.min(Config.max_rewind_seconds,2*latency+Config.view_delay_seconds) or 0
 -- Practice targets fly a set path drawn on the client's synced clock, so only the trigger message's own trip is
 -- rewound for them: exactly the moment the pilot aimed (TrainingCourse.pathAt).
 local pathRewind=p.kind=="human" and aimData and math.min(Config.max_rewind_seconds,latency+now-aimData.at) or 0
 local shot={id=self.serial,owner=p.id,life=p.life,weapon=weapon,position=position,origin=position,direction=direction,direction0=direction,born=now,expires=now+weapon.lifetime,rewind=rewind,pathRewind=pathRewind,flown=0,
  target=target,targetLife=target and target.life,radius=weapon.projectile_radius,speed=weapon.projectile_speed*(weapon.homing and p.pal and p.pal.eraserSlow or 1)}
 -- Studio shot recorder: how close each of a player's shots came to the nearest enemy (see :finish).
 if Run:IsStudio() and p.player and not weapon.homing then shot.dev={miss=math.huge,range=aimData and aimData.range} end
 self.shots[shot.id]=shot;self.shotCount+=1;self.totalFired+=1
 local record=self.flight.records[p.id];if record then record.shots+=1 end
 if p.pin and p.player then p.player:SetAttribute("RangeShots",(p.player:GetAttribute("RangeShots") or 0)+1) end -- the Range's score card
 if weapon.homing then info.activeErasers+=1 end
 self:emit({kind="shot",id=shot.id,owner=p.id,slot=mount.slot,weapon=weapon.id,position=position,direction=direction,speed=shot.speed,expires=shot.expires,time=now})
 return true
end
function Service:finish(shot,position,wall)
 if not self.shots[shot.id] then return end
 self.shots[shot.id]=nil;self.shotCount-=1
 -- Studio: the player attribute DevShotLog keeps the last 40 shots: H(it)/W(all)/A(ir), the gun range sent, how far
 -- the shot passed from the target's centre, and where (target's right, up, back), all in studs.
 local owner=shot.dev and self.flight.byId[shot.owner]
 if owner and owner.player then
  local d,o=shot.dev,shot.dev.off or Vector3.zero
  local entry=string.format("%s r%s m%.1f(%.1f,%.1f,%.1f)@%.0f",shot.struck and "H" or wall and "W" or "A",d.range and string.format("%.0f",d.range) or "-",math.min(d.miss,99),o.X,o.Y,o.Z,d.dist or 0)
  local log=string.split(owner.player:GetAttribute("DevShotLog") or "","|");if log[1]=="" then table.remove(log,1) end
  table.insert(log,entry);while #log>40 do table.remove(log,1) end
  owner.player:SetAttribute("DevShotLog",table.concat(log,"|"))
 end
 if shot.weapon.homing and self.info[shot.owner] then self.info[shot.owner].activeErasers=math.max(0,self.info[shot.owner].activeErasers-1) end
 -- Combat Training's dodge step: did the Pal's eraser miss its player? A hit makes the next one slower still.
 local pal=shot.weapon.homing and self.flight.byId[shot.owner]
 local victim=pal and pal.foeOf and self.flight.byId[pal.foeOf]
 -- An eraser that flew on because its player crashed doesn't count as dodged.
 if pal and pal.pal and pal.lessonPlayer and (shot.struck or victim and victim.model:GetAttribute("State")=="FLYING") then
  local key=shot.struck and "PalEraserHits" or "PalEraserMisses"
  pal.lessonPlayer:SetAttribute(key,(pal.lessonPlayer:GetAttribute(key) or 0)+1)
  if shot.struck then pal.pal.eraserSlow=math.max(.6,pal.pal.eraserSlow*.9) else pal.pal.mode="circle" end -- dodged: it stops shooting
 end
 self:emit({kind="end",id=shot.id,position=position or shot.position,wall=wall})
end
function Service:hit(attacker,target,amount,now,position,weaponId)
 if not attacker or not self:enemy(attacker,target) or target.model:GetAttribute("State")=="DESTROYED" or self.flight:protected(target,now) then return end
 -- Lessons: an eraser-only practice target ignores everything else, and a Pal can never fold its player.
 local homing=weaponId and self.flight.catalog:get(weaponId).homing
 if target.drill and target.drill.spec.eraserOnly and not homing then return end
 if homing and attacker.practice and attacker.player then attacker.player:SetAttribute("EraserHits",(attacker.player:GetAttribute("EraserHits") or 0)+1) end
 local health=target.model:GetAttribute("Health")
 local actual=math.min(amount,attacker.foeOf==target.id and health-1 or health);if actual<=0 then return end
 if target.card then return self:cardHit(attacker,target,health-actual,actual,position) end
 local history=self.info[target.id].history
 for i=#history,1,-1 do if now-history[i].at>Config.assist_window_seconds then table.remove(history,i) end end
 table.insert(history,{attacker=attacker.id,at=now,damage=actual,identity=attacker.identity,weapon=weaponId})
 local record=self.flight.records[attacker.id];record.damage+=actual;record.hits+=1;self.totalHits+=1
 target.lastHitAt=now;target.lastHitBy=attacker
 if self.onDamage then self.onDamage(attacker,target,actual,os.clock()) end
 self.flight:damage(target,actual,"weapon",nil,{kind="weapon",weapon=weaponId})
 self:emit({kind="hit",owner=attacker.id,target=target.id,damage=actual,position=position or target.body.Position})
end
-- A Range card takes the hit itself; folded, it tears (client RangeTargets) and is cleared after the respawn wait, and
-- RoundRuntime:rangeTargets puts up a fresh one.
function Service:cardHit(attacker,c,left,actual,position)
 if attacker.player then attacker.player:SetAttribute("RangeHits",(attacker.player:GetAttribute("RangeHits") or 0)+1) end
 c.model:SetAttribute("Health",left)
 self:emit({kind="hit",owner=attacker.id,target=c.id,damage=actual,position=position or c.body.Position})
 if left>0 then return end
 c.model:SetAttribute("State","DESTROYED")
 self:emit({kind="death",victim=c.name,victimId=c.id,killer=attacker.name,killerId=attacker.id,cause="weapon",position=c.body.Position,practice=true})
 task.delay(Config.respawn_seconds,function() self:removeCard(c) end)
end
function Service:death(p,cause)
 local now=workspace:GetServerTimeNow();local info=self.info[p.id]
 local killer,assists,damage,total,finisher=Rules.credit(info and info.history or {},now,p.stats.health,p.id,p.repairedAt)
 if cause=="vacancy" or cause=="round_end" then killer=nil;assists={} end
 if killer and self.flight.records[killer] then
  local record=self.flight.records[killer];record.kills+=1
  local actor=self.flight.byId[killer];if actor then actor.model:SetAttribute("Kills",record.kills) end
  if actor then actor.protectionRemaining=require(Root.Generated.Gameplay).service.protected_seconds_per_life end -- a kill earns hangar safety back
 end
 -- Match earnings supply record points, including zone points and fold bonuses.
 for _,id in ipairs(assists) do local record=self.flight.records[id];if record then record.assists+=1 end end
 -- The death line, now that the fold has an owner: the folder's name and the weapon of their last hit.
 local how=table.clone(p.how or {kind=cause=="weapon" and "weapon" or "crash"})
 local killerName=killer and self.flight.records[killer] and self.flight.records[killer].name or nil
 if how.kind=="weapon" then
  for _,entry in ipairs(info and info.history or {}) do if entry.attacker==killer then how.weapon=entry.weapon end end
 end
 how.template,how.t=Lines.plan(how,killerName)
 if p.model and p.model:GetAttribute("State")=="DESTROYED" then p.model:SetAttribute("Message",Lines.death(how,"you",killerName)) end
 p.deathHow=how
 if self.onDeath then self.onDeath(p,cause,killer,assists,info and info.history or {},damage,total,finisher) end
 for _,shot in pairs(self.shots) do if shot.owner==p.id then self:finish(shot) end end
 if info then info.held={false,false};info.history={} end
 self:emit({kind="death",victim=p.name,victimId=p.id,killer=killer and self.flight.records[killer].name or nil,killerId=killer,cause=cause,how=p.deathHow,position=p.body.Position,practice=p.practice or nil})
end
-- Earliest plane on a shot's path this step, tested where each target was when the shooter saw it.
function Service:planeHit(shot,delta,now)
 local shooter=self.flight.byId[shot.owner];if not shooter then return nil end
 local best,bestT=nil,math.huge
 local reach=delta.Magnitude/2+30
 -- Strict hits: the projectile's drawn box against the target plane's exact model shape.
 local size,rotation=Aircraft.projectile(shot.weapon.id,shot.weapon.homing)
 size,rotation=size or Vector3.one*shot.radius*2,rotation or CFrame.identity
 for _,target in pairs(self.flight.pilots) do
  local info=self.info[target.id]
  if info and self:enemy(shooter,target) and target.model:GetAttribute("State")=="FLYING" then
   -- A practice target is judged on its set path, as its card is drawn (TrainingCourse.pathOf).
   local d=target.drill
   local cf=d and Course.pose(d.spec,d.center,now-shot.pathRewind-d.t0,d.face,d.side) or Rules.sample(info.track,now-shot.rewind) or target.body.CFrame
   if (cf.Position-(shot.position+delta/2)).Magnitude<reach then
    if shot.dev then
     local along=math.clamp((cf.Position-shot.position):Dot(delta)/math.max(delta:Dot(delta),1e-6),0,1)
     local near=shot.position+delta*along
     if (near-cf.Position).Magnitude<shot.dev.miss then shot.dev.miss=(near-cf.Position).Magnitude;shot.dev.off=cf:PointToObjectSpace(near);shot.dev.dist=(near-shot.origin).Magnitude end
    end
    local function at(pose)
     local t=HitShapes.cast(target,pose,shot.position,delta,size,rotation)
     -- No plane model to test (unit fixtures): its body box.
     if t==false then t=Rules.segmentBox(shot.position,delta,pose,target.body.Size/2+Vector3.one*shot.radius) end
     return t
    end
    local t=at(cf)
    -- Bots feel a shot that passes close (within 10 studs) as being shot at; that, not reading aim, makes them break.
    if not t and target.kind=="bot" then
     local along=math.clamp((cf.Position-shot.position):Dot(delta)/math.max(delta:Dot(delta),1e-6),0,1)
     if (shot.position+delta*along-cf.Position).Magnitude<10 then target.shotAtAt,target.shotAtBy=now,shooter end
    end
    -- Erasers are slow and dodged on sight: a human pilot is only hit if the eraser also reaches where they
    -- already are on their own screen (the server sees their plane a moment late).
    if t and shot.weapon.homing and target.kind=="human" then
     local t2=at(cf+target.body.AssemblyLinearVelocity*(Config.view_delay_seconds+(info.latency or 0)));t=t2 and math.max(t,t2)
    end
    if t and t<bestT then best,bestT=target,t end
   end
  end
 end
 -- The shooter's own Range cards, judged where the path had them when the shot was aimed (TrainingCourse.pathAt).
 for _,c in pairs(self.cards) do
  if c.foeOf==shooter.id and c.model:GetAttribute("State")=="FLYING" then
   local t=HitShapes.card(self:cardPose(c,now-shot.pathRewind),shot.position,delta,size)
   if t and t<bestT then best,bestT=c,t end
  end
 end
 return best,bestT
end
function Service:step(dt)
 local now=workspace:GetServerTimeNow();self.clock+=dt;self.trackClock+=dt
 for _,c in pairs(self.cards) do if c.model:GetAttribute("State")=="FLYING" then c.body.CFrame=self:cardPose(c,now) end end
 if self.trackClock>=1/Config.track_hz then
  self.trackClock=0
  for _,p in pairs(self.flight.pilots) do
   local info=self.info[p.id]
   if info then
    table.insert(info.track,{at=now,cf=p.body.CFrame})
    while info.track[1] and now-info.track[1].at>Config.max_rewind_seconds+.75 do table.remove(info.track,1) end
   end
  end
 end
 for _,p in pairs(self.flight.pilots) do
  local info=self.info[p.id]
  if info then
   for _,mount in ipairs(info.mounts) do self:coolMount(mount,info.held[mount.group] and self:eligible(p) and not p.overlay,now) end
  end
  if info and self:eligible(p) and not p.overlay then
   if self.clock>=.1 then self:lock(p,info,now) end
   for _,mount in ipairs(info.mounts) do
    local weapon=mount.weapon
    if info.held[mount.group] and mount.readyAt<=now then
     -- Holding the trigger on an eraser launches it the moment the lock completes.
     if weapon.homing then
      if info.lockPilot and now-info.lockAt>=Config.eraser_lock_seconds then self:fire(p,mount,now) end
     elseif weapon.fire_mode=="automatic" then self:fire(p,mount,now)
     elseif weapon.fire_mode=="burst" and mount.burstLeft==0 then mount.burstLeft=weapon.burst_count;mount.burstNext=now;mount.readyAt=now+weapon.burst_period end
    end
    if mount.burstLeft>0 then
     for _=1,3 do
      if mount.burstLeft==0 or now<mount.burstNext then break end
      self:fire(p,mount,now);mount.burstLeft-=1;mount.burstNext+=weapon.burst_spacing
     end
    end
   end
  end
  if info and self.clock>=.1 then
   self:publishHeat(p,now)
   -- HUD reload pips: how ready each mount is (0 just fired, 1 ready).
   for _,m in ipairs(info.mounts) do
    p.model:SetAttribute("MountReady"..m.slot,math.clamp(1-(m.readyAt-now)/(m.weapon.burst_period or m.weapon.shot_interval),0,1))
   end
   for which=1,2 do
    local label="None"
    for _,m in ipairs(info.mounts) do if m.group==which then label=m.weapon.name end end
    p.model:SetAttribute(which==1 and "PrimaryName" or "AlternateName",label)
   end
  end
 end
 for _,shot in pairs(self.shots) do
  if now>=shot.expires then self:finish(shot);continue end
  if shot.target then
   if not self:targetable(shot.target,now) or shot.target.life~=shot.targetLife then shot.target=nil
   elseif self:visible(shot.position,shot.target.body.Position) then
    shot.lostAt=nil;local d=shot.target.body.Position-shot.position
    local steered=d.Magnitude>.01 and Rules.eraserSteer(shot.direction,d.Unit,dt)
    if steered then
     shot.direction=steered
     shot.target.model:SetAttribute("EraserIncomingUntil",now+.25);shot.target.model:SetAttribute("EraserDistance",d.Magnitude)
    else shot.target=nil end
   else
    shot.lostAt=shot.lostAt or now
    if now-shot.lostAt>.4 then shot.target=nil end
   end
  end
  local delta -- ponytail: a server hitch slows shots instead of breaking the 1024-stud cast limit
  if shot.weapon.homing then delta=shot.direction*Rules.eraserSpeed(shot.speed,shot.flown,Config)*math.min(dt,.5)
  else
   if dt>.5 then shot.born+=dt-.5 end
   delta=shot.origin+Rules.shotOffset(shot.weapon,shot.direction0,now-shot.born)-shot.position
  end
  -- A fast shot after a long hitch could still pass the cast limit: it catches up over the next steps instead.
  if delta.Magnitude>1000 then delta=delta.Unit*1000 end
  if delta.Magnitude>.001 then
   local result=workspace:Spherecast(shot.position,shot.radius,delta,self.worldCast)
   local target,t=self:planeHit(shot,delta,now)
   local attacker=self.flight.byId[shot.owner]
   local taken=false
   -- Hidden paper targets: only the shooter's own still-standing signs (each pilot has a private set per round).
   local signs=not taken and attacker and attacker.player and PaperSigns
   if signs then
    local down=self.paperDown[attacker.id] or {};self.paperDown[attacker.id]=down
    for index,row in ipairs(signs) do
     local t3=not down[index] and Rules.segmentBox(shot.position,delta,Rules.paperTargetPose(row),Rules.PAPER_TARGET_HALF+Vector3.one*shot.radius)
     if t3 and (not result or t3*delta.Magnitude<=result.Distance) and (not target or t3<=t) then taken=true;down[index]=true
      local at=shot.position+delta*t3
      self:emit({kind="paperTarget",owner=attacker.id,index=index,position=at})
      if self.onPaperTarget then self.onPaperTarget(attacker,index) end
      self:finish(shot,at);break
     end
    end
   end
   if taken then -- a paper sign took the shot
   elseif target and (not result or t*delta.Magnitude<=result.Distance) then
    local at=shot.position+delta*t
    shot.struck=target;self:hit(attacker,target,shot.weapon.damage,now,at,shot.weapon.id);self:finish(shot,at)
   elseif result then
    self:chalkHit(result.Instance,now)
    if attacker and self.onProp then self.onProp(attacker,result.Instance) end
    self:finish(shot,result.Position,true)
   else shot.position+=delta;shot.flown+=delta.Magnitude end
  end
  if self.clock>=.1 and shot.weapon.homing then self:emit({kind="update",id=shot.id,position=shot.position,direction=shot.direction,flown=shot.flown,time=now}) end
 end
 if self.clock>=.1 then self.clock%=.1 end
 -- Send shot and hit news 20 times a second; the shooter's own tracers are already drawn locally.
 self.flushClock=(self.flushClock or 0)+dt
 if self.flushClock>=.05 then
  self.flushClock=0
  if #self.events>0 then self.remote:FireAllClients(self.events);self.events={} end
  -- Unreliable messages are capped near 1 KB, so send tracer news a few events at a time.
  local list=self.cosmeticEvents
  for i=1,#list,5 do self.cosmetics:FireAllClients(table.move(list,i,math.min(i+4,#list),1,{})) end
  self.cosmeticEvents={}
 end
end
return Service
