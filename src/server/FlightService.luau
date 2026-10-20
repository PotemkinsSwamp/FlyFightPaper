-- Native assemblies; human physics on their client, scripted pilots on the server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Physics=game:GetService("PhysicsService")
local Root=RS:WaitForChild("FlyFightPaper")
local Rules=require(Root.Shared.FlightRules)
local Landing=require(Root.Shared.ServiceRules)
local Catalog=require(Root.Shared.Catalog)
local Lines=require(Root.Shared.Lines)
-- For messages set every tick (scraping, waiting): keep the line already showing instead of picking a new one each tick.
local function say(p,set) if not Lines.is(set,p.model:GetAttribute("Message") or "") then p.model:SetAttribute("Message",Lines.pick(set)) end end
local Gameplay=require(Root.Generated.Gameplay)
local Desk=Gameplay.service
local Loadouts=require(Root.Shared.WeaponLoadouts)
local Aircraft=require(Root.Shared.Aircraft)
local Roster=require(Root.Shared.BotRosterRules)
local HitShapes=require(script.Parent.HitShapes)
local DuctRules=require(Root.Shared.DuctRules)
local MonorailRules=require(Root.Shared.MonorailRules)
local Course=require(Root.Shared.TrainingCourse)
local Service={};Service.__index=Service

function Service.new()
 local self=setmetatable({},Service)
 self.room=workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom")
 -- The room collides by what is drawn: every visible solid mesh in it has an exact collision shape, worked out once
 -- in Studio and saved in the place (tools/save_place.py keeps it through rebuilds), so the server builds none at start.
 local NativeAssets=require(Root.Shared.NativeAssets)
 NativeAssets.mark(self.room);NativeAssets.mark(Root:WaitForChild("Assets"))
 self.planes=Instance.new("Folder");self.planes.Name="Planes";self.planes.Parent=workspace
 self.template=SS:WaitForChild("Assets"):WaitForChild("PaperPlane")
 self.catalog=Catalog.new(require(Root.Generated.Catalog),Gameplay)
 self.pilots={};self.byId={};self.records={};self.seats={};self.padReservations={};self.landingQueues={};self.lifeSerial=0
 pcall(function() Physics:RegisterCollisionGroup("Planes") end)
 Physics:CollisionGroupSetCollidable("Planes","Planes",false)
 self.cast=RaycastParams.new();self.cast.FilterType=Enum.RaycastFilterType.Include;self.cast.FilterDescendantsInstances={self.room};self.cast.RespectCanCollide=true
 self.overlap=OverlapParams.new();self.overlap.FilterType=Enum.RaycastFilterType.Include;self.overlap.FilterDescendantsInstances={self.room};self.overlap.RespectCanCollide=true
 self.single=RaycastParams.new();self.single.FilterType=Enum.RaycastFilterType.Include
 self.other=OverlapParams.new();self.other.FilterType=Enum.RaycastFilterType.Include
 self.regions=OverlapParams.new();self.regions.FilterType=Enum.RaycastFilterType.Include;self.regions.FilterDescendantsInstances={self.planes}
 self.boundsCF,self.boundsSize=self.room:GetBoundingBox()
 if self.room.Name=="Arena" then self.boundsSize=Vector3.new(Gameplay.world.width_studs,Gameplay.world.height_studs,Gameplay.world.depth_studs);self.boundsCF=CFrame.new(0,Gameplay.world.height_studs/2,0) end
 -- The ducts above the ceiling are part of the room: planes may fly up to their roof (bots still use boundsSize).
 local ducts=Gameplay.world.ducts;self.headroom=self.room.Name=="Arena" and ducts.floor_y+ducts.height-Gameplay.world.height_studs or 0
 self.ductFans={};for _,spot in ipairs(ducts.fans.spots) do table.insert(self.ductFans,DuctRules.fanFrame(spot)) end
 -- Fan volumes come from config; the room's fan models are only their visuals.
 self.fans={};self.updrafts={}
 for _,fan in ipairs(Gameplay.world.fans) do
  local center,half,dir=fan.center,fan.halfsize,fan.direction
  local entry={Name=fan.id,upward=fan.kind=="upward",Position=Vector3.new(center[1],center[2],center[3]),Size=Vector3.new(half[1],half[2],half[3])*2,Direction=Vector3.new(dir[1],dir[2],dir[3]).Unit}
  table.insert(self.fans,entry);if entry.upward then table.insert(self.updrafts,entry) end
 end
 -- Speed power-ups at the fly-throughs: the server owns pick-up and respawn; clients spin the markers.
 local Pickups=Gameplay.world.speed_pickups
 self.pickups={};local pickupFolder=Instance.new("Folder");pickupFolder.Name="SpeedPickups"
 for i,spot in ipairs(Pickups.spots) do
  local marker=Instance.new("Part");marker.Name="SpeedPickup"..i;marker.Anchored=true;marker.CanCollide=false;marker.CanQuery=false;marker.CanTouch=false
  marker.Size=Vector3.new(table.unpack(spot.box));marker.Transparency=1;marker.Position=Vector3.new(table.unpack(spot.at));marker:SetAttribute("ReadyAt",0);marker.Parent=pickupFolder
  table.insert(self.pickups,marker)
 end
 pickupFolder.Parent=workspace
 self.desks={self.room.DeskSouth3}
 for _,side in ipairs({"South","North"}) do for i=1,6 do local desk=self.room["Desk"..side..i];if desk~=self.desks[1] then table.insert(self.desks,desk) end end end
 self.neutralDesks={}
 for _,part in ipairs(self.room:GetChildren()) do if part:IsA("BasePart") and part.Name:match("^NeutralDesk%d+$") then table.insert(self.neutralDesks,part) end end
 self.remote=Instance.new("RemoteEvent");self.remote.Name="FlightAction";self.remote.Parent=Root
 self.remote.OnServerEvent:Connect(function(player,action,value)
  local p=self.pilots[player];if not p then return end
  if action=="boost" then
   if type(value)=="boolean" then p.boostHeld=value end
   return
  end
  local now=workspace:GetServerTimeNow();if now-p.lastAction<0.35 then return end;p.lastAction=now
  if action=="launch" and p.model:GetAttribute("State")=="DESK" and not p.serviceBusy then self:launch(p)
  elseif action=="fresh" and p.model:GetAttribute("State")=="DESK" and not p.serviceBusy then self:destroy(p,{kind="fresh"},"fresh")
  elseif action=="loadout" and Run:IsStudio() and p.model:GetAttribute("State")=="DESK" and not p.serviceBusy then
   -- Studio test flights: a desk picker name or a whole hangar build, with every part unlocked.
   -- It lasts until the player picks a hangar preset and is never saved to the profile.
   local loadout=type(value)=="string" and Loadouts.make(self.catalog,value) or type(value)=="table" and self.catalog:validateLoadout(value,nil,50) and value
   if loadout then p.testLoadout=loadout;p.loadoutName=type(value)=="string" and value or "test build";self:replace(p) end
  elseif action=="mixedBots" and Run:IsStudio() then
   -- Studio test: replace every bot with an even mix of all builds, skills, personalities and quirks.
   self.eraserDuel=false;self.mixedBots=(self.mixedBots or 0)+1
   for _,bot in pairs(self.pilots) do if bot.kind=="bot" then self:remove(bot,"vacancy") end end
  elseif action=="eraserBots" and Run:IsStudio() then
   -- Studio dodge practice: one enemy bot with only an eraser hunts you; the other bots leave (until Play stops).
   self.eraserDuel=true
   local hunter
   for _,bot in pairs(self.pilots) do if bot.kind=="bot" then
    if hunter then self:remove(bot,"vacancy") else hunter=bot end
   end end
   if hunter then
    hunter.team=nil;hunter.testLoadout=Loadouts.make(self.catalog,"eraser_only");hunter.loadoutName="eraser_only"
    if hunter.model:GetAttribute("State")=="DESK" then self:replace(hunter) else self:destroy(hunter,{kind="fresh"},"fresh") end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(player) local p=self.pilots[player];if p then self:remove(p,"departure") end end)
 Run.Heartbeat:Connect(function(dt) local start=os.clock();self:step(dt);self.lastWorkMs=(os.clock()-start)*1000 end)
 Service.active=self
 return self
end
function Service:seat()
 for index=1,#self.desks do if not self.seats[index] and not self.padReservations["desk:"..index] then self.seats[index]=true;return index end end
 return nil
end
function Service:rosterActors()
 local actors={};local now=workspace:GetServerTimeNow()
 for _,p in pairs(self.pilots) do
  local state=p.model:GetAttribute("State")
  table.insert(actors,{key=p.id,userKey=p.player and p.id,controllerType=p.kind,displayName=p.name,profileName=p.kind=="bot" and p.tier or nil,
   teamId=p.team,state=state=="DESK" and "SPAWN_READY" or state,trustedSafeParkedService=state=="DESK" and self:protected(p,now),recentDamageCredit=now-(p.lastHitAt or -math.huge)<=10})
 end
 return actors
end
function Service:add(player,options)
 options=options or {}
 local key=player or options.id;local id=player and tostring(player.UserId) or options.id
 local seat=options.seat or self:seat()
 if not seat and player then
  local plan=Roster.humanPriority({eligibility=self.eligibility or "rookie",serverClass=self.eligibility or "rookie",mode=self.mode or "FFA",seed=Gameplay.world.seed,config=Gameplay,
   actors=self:rosterActors(),pendingHumanQueue={{userKey=id,arrivalOrder=0}},botIdentitySerial=1})
  local other=plan and plan.releaseProposal and self.byId[plan.releaseProposal.actorKey]
  -- Studio test modes skip the roster rules: any bot gives up its desk.
  if not other and (self.mixedBots or self.eraserDuel) then for _,bot in pairs(self.pilots) do if bot.kind=="bot" then other=bot;break end end end
  if other then self:remove(other,"vacancy");seat=self:seat() end
 end
 if not seat then return nil end
 self.seats[seat]=true
 local desk=self.desks[seat]
 local home=CFrame.new(desk.Position+Vector3.new(0,desk.Size.Y/2+2.8,0))*CFrame.Angles(0,desk.Name:find("North") and math.pi or 0,0)
 local p={key=key,id=id,player=player,kind=player and "human" or "bot",name=player and player.DisplayName or options.name,
  seat=seat,home=home,loadout=options.loadout or self.catalog:starterLoadout(),loadoutName=options.loadoutName or "pellet",tier=options.tier or "regular",practice=options.practice,life=0}
 self.records[id]=self.records[id] or self:newRecord(p)
 self.pilots[key]=p;self.byId[id]=p;self:build(p)
 return p
end
function Service:newRecord(p)
 return {name=p.name,kind=p.kind,tier=p.kind=="bot" and p.tier or nil,shots=0,hits=0,kills=0,assists=0,deaths=0,weaponDeaths=0,collisionDeaths=0,damage=0,points=0}
end
-- Rounds never stop (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md). A new round starts where
-- everyone is: a clean record, full health (wear gone), Lift and boost.
function Service:newRound(p)
 self.records[p.id]=self:newRecord(p);p.protectionRemaining=Desk.protected_seconds_per_life
 for key,value in pairs({Health=p.stats.health,MaxHealth=p.stats.health,OriginalHealth=p.stats.health,Lift=p.stats.lift,Boost=p.model:GetAttribute("BoostMax") or 0,Kills=0}) do p.model:SetAttribute(key,value) end
end
-- The winners' moment: every flying plane holds still in the air until the vote lap, then flies on from there.
function Service:hold(on)
 for _,p in pairs(self.pilots) do
  if not on then p.model:SetAttribute("Lift",p.stats.lift) end
  self:freeze(p,on)
 end
end
-- One flying plane held still in the air (the winners' moment; a lesson's "read, then act" pause), then flown on.
function Service:freeze(p,on)
 if on and not p.held and p.model:GetAttribute("State")=="FLYING" then
  p.held=true;p.body:SetNetworkOwner(nil);p.body.Anchored=true;p.drive.Enabled=false;p.orientation.Enabled=false
  p.model:SetAttribute("Held",true) -- the pilot's screen keeps the aim on the nose meanwhile
 elseif not on and p.held then p.held=nil;p.model:SetAttribute("Held",nil);self:fly(p) end
end
function Service:build(p)
 -- A returning account gets a new identity even when its previous pilot was removed.
 self.lifeSerial=(self.lifeSerial or 0)+1;p.life=self.lifeSerial;p.stats=assert(self.catalog:deriveStats(p.loadout))
 local model=self.template:Clone();model.Name=p.id
 -- Root is only the flight body; it never collides. The exact-shape Colliders below decide what the plane touches.
 local body=model:WaitForChild("Root");model.PrimaryPart=body;body.Anchored=true;body.CanCollide=false;body.CanQuery=true;body.CollisionGroup="Planes"
 body.CustomPhysicalProperties=PhysicalProperties.new(0.3,0.15,0.1)
 for key,value in pairs({OwnerId=p.player and p.player.UserId or 0,Life=p.life,State="DESK",LiftMax=p.stats.lift,Lift=p.stats.lift,Speed=p.stats.speed,
  TurnRate=p.stats.turn,PitchRate=p.stats.pitch,YawRate=p.stats.yaw,Health=p.stats.health,MaxHealth=p.stats.health,OriginalHealth=p.stats.health,DisplayName=p.name,ControllerType=p.kind,
  Message=Lines.pick("atDesk"),Loadout=p.loadoutName,LoadoutData=game:GetService("HttpService"):JSONEncode(p.loadout),Protected=true,Kills=self.records[p.id].kills}) do model:SetAttribute(key,value) end
 -- A practice flight stays one through crashes: every new plane carries the mark and its desk ring.
 if p.practice then model:SetAttribute("Practice",true);model:SetAttribute("PracticeRing",Landing.approach(p.home,Desk)) end
 -- Flight School (p.gentle): the pilot's client must not crumple it either, only bounce it off.
 if p.gentle then model:SetAttribute("Gentle",true) end
 -- Aiming lesson slow motion: the pilot's own screen flies the plane at this share of its speed.
 if p.slow then model:SetAttribute("SlowMo",p.slow) end
 local color=Color3.fromHSV((p.seat*.133)%1,0.65,0.9)
 if Aircraft.build(model,p.loadout,self.catalog,false) then
  for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=body then part:Destroy() end end
  -- Invisible exact copies of every part (body, nose, wings, tail, mounts, booster), welded on.
  local colliders=Instance.new("Folder");colliders.Name="Colliders";colliders.Parent=model
  for _,part in ipairs(model.Appearance:GetChildren()) do if part:IsA("MeshPart") then
   local piece=HitShapes.solid(part);piece.Name=part.Name;piece.CFrame=part.CFrame;piece.Transparency=1;piece.Massless=true
   piece.Anchored=false;piece.CanQuery=true;piece.CastShadow=false;piece.Parent=colliders
   local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=piece;weld.Parent=piece
  end end
 end
 local attachment=Instance.new("Attachment");attachment.Name="FlightAttachment";attachment.Parent=body
 local drive=Instance.new("LinearVelocity");drive.Name="ForwardVelocity";drive.Attachment0=attachment;drive.RelativeTo=Enum.ActuatorRelativeTo.World
 drive.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector;drive.ForceLimitsEnabled=true;drive.Enabled=false;drive.Parent=body
 local orientation=Instance.new("AlignOrientation");orientation.Name="NoseOrientation";orientation.Attachment0=attachment;orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
 orientation.Responsiveness=Gameplay.flight.orientation_response;orientation.MaxTorque=1e6;orientation.MaxAngularVelocity=math.rad(p.stats.turn)*Gameplay.flight.orientation_angular_headroom;orientation.Enabled=false;orientation.Parent=body
 local label=Instance.new("BillboardGui");label.Name="PilotName";label.Size=UDim2.fromOffset(180,26);label.StudsOffset=Vector3.new(0,5,0);label.MaxDistance=800;label.AlwaysOnTop=false;label.Parent=body
 local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=p.name;text.TextColor3=color;text.TextStrokeTransparency=.3;text.Font=Enum.Font.GothamMedium;text.TextSize=14;text.Parent=label
 p.hangar=Landing.hangar(p.home,Desk)
 model.Parent=self.planes;model:PivotTo(p.hangar)
 p.model,p.body,p.drive,p.orientation=model,body,drive,orientation
 p.lastAction,p.lastImpact,p.lastContact=0,0,0;p.fanInside={};p.lastPosition=body.Position;p.checkCFrame=body.CFrame
 p.checkAt=workspace:GetServerTimeNow();p.regionClock=0;p.protectionRemaining=Desk.protected_seconds_per_life;p.outOfHangar=0;p.spawnProtectionUntil=0;p.outSince=nil;p.lastCFrame=body.CFrame
 p.launchAt=nil;p.respawnAt=nil;p.hasLaunched=false;p.serviceBusy=false;p.serviceHome=p.hangar
 local utility=p.loadout.utility and self.catalog:get(p.loadout.utility)
 p.boostHeld=false;model:SetAttribute("BoostMax",utility and utility.boost_seconds or 0);model:SetAttribute("Boost",utility and utility.boost_seconds or 0);model:SetAttribute("BoostSpeedFactor",1)
 p.padKey="desk:"..p.seat;self.padReservations[p.padKey]=p.id
 if self.onSpawn then self.onSpawn(p) end
end
function Service:replace(p)
 if p.testLoadout then p.loadout=p.testLoadout
 -- A practice plane respawns as the same training plane, not the player's own build (it may have no booster).
 elseif p.player and self.selectedLoadout and not p.practice then p.loadout=self.selectedLoadout(p.player) or p.loadout end
 if p.model then p.model:Destroy() end
 self:build(p)
end
function Service:remove(p,cause)
 if p.model:GetAttribute("State")~="DESTROYED" then self:destroy(p,{kind="left"},cause) end
 p.model:Destroy();self.pilots[p.key]=nil;self.byId[p.id]=nil;self.seats[p.seat]=nil
 if self.onRemoved then self.onRemoved(p) end
 -- A lesson's targets and Pal go with their player.
 for _,other in pairs(self.pilots) do if other.foeOf==p.id then self:remove(other,cause) end end
end
-- Automatic takeoff (D11): a scripted roll down the runway, off the desk and through the ring, like the scripted
-- landing; the pilot (or bot) gets the plane once it is through. Weapons and steering wait for FLYING.
function Service:launch(p)
 if not self.active or p.serviceBusy then return end
 self:clearLandingQueue(p)
 local hangar=p.serviceHome or p.hangar
 p.body.CFrame=hangar
 p.model:SetAttribute("State","TAKEOFF");p.model:SetAttribute("Message",Lines.pick("takeoff"))
 -- Physics (server-owned) carries the plane along the path: an anchored plane moved by the server reaches each
 -- player at half the frame rate and judders; a moving unanchored one is smoothed on every screen.
 p.takeoff={legs=Landing.takeoff(hangar*CFrame.new(0,0,-Desk.hangar_back_studs),Desk,p.stats.speed),leg=1,t=0,from=hangar}
 p.body.Anchored=false;p.body:SetNetworkOwner(nil)
 p.drive.MaxForce=p.body.AssemblyMass*workspace.Gravity*Gameplay.flight.drive_force_g;p.drive.VectorVelocity=Vector3.zero
 p.orientation.CFrame=hangar.Rotation;p.drive.Enabled=true;p.orientation.Enabled=true
end
-- One frame of the takeoff: steer toward where the path is next frame. The roll eases in from rest; the climb is steady.
function Service:takeoffStep(p,dt)
 local k=p.takeoff;k.t+=dt
 while k.legs[k.leg] and k.t>=k.legs[k.leg].seconds do k.t-=k.legs[k.leg].seconds;k.from=k.legs[k.leg].cframe;k.leg+=1 end
 local leg=k.legs[k.leg]
 if not leg then p.takeoff=nil;self:fly(p);return end
 local eased=Tween:GetValue(math.min(1,(k.t+dt)/leg.seconds),k.leg==1 and Enum.EasingStyle.Quad or Enum.EasingStyle.Linear,Enum.EasingDirection.In)
 local goal=k.from:Lerp(leg.cframe,eased)
 p.drive.VectorVelocity=(goal.Position-p.body.Position)/dt;p.orientation.CFrame=goal.Rotation
end
function Service:fly(p)
 p.body.Anchored=false;p.body:SetNetworkOwner(p.player)
 if p.padKey then self.padReservations[p.padKey]=nil;p.padKey=nil end
 p.drive.VectorVelocity=p.body.CFrame.LookVector*p.stats.speed;p.orientation.CFrame=p.body.CFrame.Rotation
 -- Finite force: walls push back and the plane slides instead of being driven through them.
 p.drive.MaxForce=p.body.AssemblyMass*workspace.Gravity*Gameplay.flight.drive_force_g
 p.drive.Enabled=true;p.orientation.Enabled=true;p.body.AssemblyLinearVelocity=p.drive.VectorVelocity
 p.launchAt=workspace:GetServerTimeNow();p.checkAt=p.launchAt;p.checkCFrame=p.body.CFrame;p.emptySince=nil;p.lastPosition=p.body.Position;p.lastCFrame=p.body.CFrame;p.fanInside={}
 if not p.hasLaunched then p.spawnProtectionUntil=p.launchAt+Gameplay.combat.spawn_protection_seconds;p.hasLaunched=true end
 p.model:SetAttribute("State","FLYING");p.model:SetAttribute("Message","")
end
function Service:protected(p,now)
 local state=p.model:GetAttribute("State")
 return state=="TAKEOFF" or (state=="DESK" or state=="LANDING") and self:atDesk(p) and p.protectionRemaining>0 or now<(p.spawnProtectionUntil or 0)
end
function Service:refold(p,loadout)
 p.loadout=loadout;p.stats=assert(self.catalog:deriveStats(loadout))
 Aircraft.build(p.model,loadout,self.catalog,false)
 -- New parts welded on can hand the plane back to the server, which then flies it straight off (Alan 2026-10-20,
 -- swapping loadouts in the Range): give it back to its pilot.
 if p.player and not p.body.Anchored then p.body:SetNetworkOwner(p.player) end
 p.model:SetAttribute("LoadoutData",game:GetService("HttpService"):JSONEncode(loadout))
 for key,value in pairs({Speed=p.stats.speed,TurnRate=p.stats.turn,PitchRate=p.stats.pitch,YawRate=p.stats.yaw,OriginalHealth=p.stats.health,MaxHealth=p.stats.health,Health=p.stats.health,LiftMax=p.stats.lift,Lift=p.stats.lift}) do p.model:SetAttribute(key,value) end
 p.orientation.MaxAngularVelocity=math.rad(p.stats.turn)*Gameplay.flight.orientation_angular_headroom
 local utility=loadout.utility and self.catalog:get(loadout.utility)
 p.model:SetAttribute("BoostMax",utility and utility.boost_seconds or 0);p.model:SetAttribute("Boost",utility and utility.boost_seconds or 0)
 if self.onRefold then self.onRefold(p) end
end
function Service:atDesk(p)
 local position=(p.serviceHome or p.home):PointToObjectSpace(p.body.Position)
 return math.abs(position.X)<=48 and math.abs(position.Z)<=48 and math.abs(position.Y)<=16
end
-- `walls`: the room hurts even a protected plane; protection only stops enemy fire and rams.
-- `how`: how this hit could bring the plane down, for the death line (Lines.death).
function Service:damage(p,amount,cause,walls,how)
 if self.safe then return 0 end -- between rounds nothing hurts
 if p.model:GetAttribute("State")=="DESTROYED" or not walls and self:protected(p,workspace:GetServerTimeNow()) then return 0 end
 local actual=math.min(p.model:GetAttribute("Health"),math.max(0,amount))
 p.model:SetAttribute("Health",p.model:GetAttribute("Health")-actual)
 if p.model:GetAttribute("Health")<=0 then self:destroy(p,how or {kind=cause=="weapon" and "weapon" or "crash"},cause) end
 return actual
end
-- `how` (Lines.death) picks the top note; CombatService rewrites it once it knows who gets the fold.
function Service:destroy(p,how,cause)
 if p.model:GetAttribute("State")=="DESTROYED" then return end
 self:clearLandingQueue(p)
 -- DeathCause picks the client's death animation (PlaneDeaths): "weapon" tears the plane up, anything else crumples it.
 p.model:SetAttribute("DeathCause",cause or "collision");p.model:SetAttribute("State","DESTROYED");p.model:SetAttribute("Health",0);p.how=how;p.model:SetAttribute("Message",Lines.death(how,"you"))
 p.drive.Enabled=false;p.orientation.Enabled=false
 if not p.body.Anchored then p.body:SetNetworkOwner(nil) end
 p.body.Anchored=true;p.body.CanCollide=false;p.body.CanQuery=false;p.respawnAt=workspace:GetServerTimeNow()+Gameplay.combat.respawn_seconds
 if p.padKey then self.padReservations[p.padKey]=nil;p.padKey=nil end
 local record=self.records[p.id];record.deaths+=1
 if cause=="weapon" then record.weaponDeaths+=1 elseif cause=="collision" then record.collisionDeaths+=1 end
 -- Lessons count what the player has folded: practice target planes and the Pals.
 if p.lessonPlayer and cause=="weapon" then local key=p.drill and "DrillDown" or "PalFolds";p.lessonPlayer:SetAttribute(key,(p.lessonPlayer:GetAttribute(key) or 0)+1) end
 if self.onDeath then self.onDeath(p,cause or "collision") end
end
function Service:clearLandingQueue(p)
 if self.landingQueues then
  for _,queue in pairs(self.landingQueues) do for i=#queue,1,-1 do if queue[i]==p.id then table.remove(queue,i) end end end
 end
 p.waitingPad=nil;p.waitingHome=nil;p.queuedAt=nil
 p.model:SetAttribute("HoldingPosition",nil);p.model:SetAttribute("DeskAvailable",nil);p.model:SetAttribute("DeskQueuePosition",nil)
end
function Service:padAvailable(key,id)
 local queue=self.landingQueues[key]
 while queue and queue[1] do
  local first=self.byId[queue[1]]
  if first and first.model.Parent and first.model:GetAttribute("State")=="FLYING" and first.waitingPad==key then break end
  table.remove(queue,1)
 end
 return (not self.padReservations[key] or self.padReservations[key]==id) and (not queue or not queue[1] or queue[1]==id)
end
function Service:queueLanding(p,home,key)
 if p.waitingPad~=key then self:clearLandingQueue(p) end
 local queue=self.landingQueues[key] or {};self.landingQueues[key]=queue
 local index=table.find(queue,p.id)
 if not index then table.insert(queue,p.id);index=#queue end
 p.waitingPad=key;p.waitingHome=home;p.queuedAt=p.queuedAt or workspace:GetServerTimeNow()
 p.model:SetAttribute("HoldingPosition",Landing.approach(home,Desk).Position+home.LookVector*120+home.RightVector*(index-1)*55+Vector3.new(0,70,0))
 p.model:SetAttribute("DeskQueuePosition",index)
 p.model:SetAttribute("DeskAvailable",false);say(p,"deskBusy")
end
function Service:land(p,home,padKey)
 padKey=padKey or "desk:"..p.seat
 home=home or p.home
 if not self:padAvailable(padKey,p.id) then self:queueLanding(p,home,padKey);return false end
 self:clearLandingQueue(p)
 self.padReservations[padKey]=p.id;p.padKey=padKey
 local hangar=Landing.hangar(home,Desk)
 p.serviceHome=hangar
 p.model:SetAttribute("State","LANDING");p.model:SetAttribute("Message",Lines.pick("landing"))
 p.body:SetNetworkOwner(nil);p.drive.Enabled=false;p.orientation.Enabled=false;p.body.Anchored=true
 -- Inbound = facing the wall. Touch down where the runway tape starts (just inside the desk's room-side edge).
 local inbound=CFrame.Angles(0,math.pi,0)
 local touchdown=home*CFrame.new(0,0,-Desk.touchdown_out_studs)*inbound
 local stages={{touchdown,Desk.touchdown_seconds,Enum.EasingStyle.Sine},{hangar*inbound,Desk.taxi_seconds,Enum.EasingStyle.Quad}}
 local function stage(i)
  if not p.model.Parent or self.pilots[p.key]~=p or p.model:GetAttribute("State")~="LANDING" then return end
  if not stages[i] then
   p.body.CFrame=hangar   -- turned to face out while the hangar menu covers the view
   p.model:SetAttribute("State","DESK");p.model:SetAttribute("Message",Lines.pick("landed"))
   if self.onLand then self.onLand(p) end
   return
  end
  local goal,seconds,style=table.unpack(stages[i])
  local tween=Tween:Create(p.body,TweenInfo.new(seconds,style,Enum.EasingDirection.Out),{CFrame=goal})
  tween.Completed:Once(function() stage(i+1) end);tween:Play()
 end
 stage(1);return true
end
-- The plane's exact shape touching the room: head-on hits destroy it, shallow scrapes cost health while they last.
function Service:impact(p,normal,part,now,dt,pushed)
 local incoming=p.previousVelocity or p.body.AssemblyLinearVelocity
 -- The pilot's own client already stops the plane at the surface, so judge by where the nose points too.
 -- `pushed`: how fast the surface itself moves into the plane (the monorail train).
 local into=math.max(0,-incoming:Dot(normal),-p.body.CFrame.LookVector:Dot(normal)*p.stats.speed,pushed or 0)
 -- Contact counts as continuous while touches are less than a quarter second apart.
 if not p.scrapeSince or now-(p.lastScrape or 0)>.25 then p.scrapeSince=now end
 p.lastScrape=now
 -- Crash or scrape by angle (Alan 2026-10-18): `into` against the plane's own speed.
 local amount=Rules.collisionDamage(into,math.max(incoming.Magnitude,p.stats.speed),part.Name=="Floor" and p.model:GetAttribute("Lift")<=0,p.stats.health,dt,now-p.scrapeSince)
 if Run:IsStudio() then self.records[p.id].lastImpact={part=part:GetFullName(),speed=into,at=now,position=tostring(p.body.Position)} end
 -- Between rounds, and in Flight School, walls only bounce you off.
 if self.safe or p.gentle then p.model:SetAttribute("CollisionNormal",normal);p.model:SetAttribute("DeflectUntil",now+.35);return end
 local how={kind="crash",part=part.Name,outOfLift=p.model:GetAttribute("Lift")<=0}
 if amount>=p.stats.health then
  self:destroy(p,how,"collision")
  return
 end
 self:damage(p,amount,"collision",true,how)
 p.model:SetAttribute("CollisionNormal",normal);p.model:SetAttribute("DeflectUntil",now+.35)
 say(p,"scraping")
end
-- A duct fan blade: a big bite out of the plane and a shove the way the blade was moving.
function Service:fanHit(p,push,now)
 if self.safe or p.gentle then return end
 self:damage(p,p.stats.health*Gameplay.world.ducts.fans.damage_share,"fan",true,{kind="fan"})
 if p.model:GetAttribute("State")~="FLYING" then return end
 p.model:SetAttribute("Knock",push*60);p.model:SetAttribute("KnockUntil",now+.3)
 say(p,"fanClip")
end
function Service:contact(p)
 local travel=(p.previousVelocity and p.previousVelocity.Magnitude>1) and p.previousVelocity.Unit or p.body.CFrame.LookVector
 return Rules.contact(p.model,travel,self.overlap,self.single)
end
function Service:touching(a,b)
 local colliders=b.model:FindFirstChild("Colliders");local mine=a.model:FindFirstChild("Colliders")
 if not colliders or not mine then return false end
 self.other.FilterDescendantsInstances={colliders}
 for _,piece in ipairs(mine:GetChildren()) do if #workspace:GetPartsInPart(piece,self.other)>0 then return true end end
 return false
end
-- Two planes' exact shapes meet. A brush costs both a little; a real ram destroys the plane with less health
-- and costs the other that much health (equal health: both go).
function Service:ram(a,b,now)
 a.lastContact,b.lastContact=now,now
 local closing=((a.previousVelocity or Vector3.zero)-(b.previousVelocity or Vector3.zero)):Dot((b.body.Position-a.body.Position).Unit)
 if closing<Gameplay.combat.ram_closing_speed then
  for _,p in ipairs({a,b}) do self:damage(p,p.stats.health*Gameplay.combat.plane_contact_health_fraction,"contact",nil,{kind="ram",other=(p==a and b or a).name}) end
  return
 end
 local ha,hb=a.model:GetAttribute("Health"),b.model:GetAttribute("Health")
 local hitA,hitB={kind="ram",other=b.name},{kind="ram",other=a.name}
 if ha<=hb then self:damage(b,ha,"collision",nil,hitB);self:damage(a,ha,"collision",nil,hitA) end
 if hb<ha then self:damage(a,hb,"collision",nil,hitA);self:damage(b,hb,"collision",nil,hitB) end
end
function Service:inServiceZone(p,origin)
 local homes={}
 for _,desk in ipairs(self.desks) do table.insert(homes,desk.CFrame*CFrame.new(0,desk.Size.Y/2+2.8,0)) end
 for _,desk in ipairs(self.neutralDesks) do for _,x in ipairs({-48,48}) do table.insert(homes,desk.CFrame*CFrame.new(x,desk.Size.Y/2+2.8,0)) end end
 for _,home in ipairs(homes) do
  for _,spot in ipairs({home,Landing.hangar(home,Desk)}) do
   local position=spot:PointToObjectSpace(origin or p.body.Position)
   if math.abs(position.X)<=48 and math.abs(position.Z)<=48 and math.abs(position.Y)<=16 then return true end
  end
 end
 return false
end
function Service:regionsFor(p,now)
 local updraft=0
 for _,fan in ipairs(self.fans) do
  local name=fan.Name;local upward=fan.upward
  local inside=false
  for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(fan.Position),fan.Size,self.regions)) do if part==p.body then inside=true;break end end
  if inside and upward then
   if not p.fanInside[name] then p.model:SetAttribute("Message",Lines.pick("updraft")) end
   -- ponytail: called every ~0.1 s (regionClock), so 0.1 s of gust per call.
   p.model:SetAttribute("Lift",Rules.fanLift(p.model:GetAttribute("Lift"),p.stats.lift,.1))
   updraft=Gameplay.flight.fan_updraft_studs_s
  end
  p.fanInside[name]=inside
 end
 p.model:SetAttribute("Updraft",updraft)
 -- Moving air in the ducts (fans, the blower): faster with it, slower against it.
 local wind=DuctRules.wind(p.body.Position,p.body.CFrame.LookVector)
 if (wind>1.05)~=((p.wind or 1)>1.05) and wind>1.05 then p.model:SetAttribute("Message",Lines.pick("tailwind")) end
 if (wind<.95)~=((p.wind or 1)<.95) and wind<.95 then p.model:SetAttribute("Message",Lines.pick("headwind")) end
 if math.abs(wind-1)<.05 and math.abs((p.wind or 1)-1)>=.05 then p.model:SetAttribute("Message","") end
 p.wind=wind;if wind>1 then p.windAt=now end
 -- Checked 10 times a second along the path flown since the last check, so a fast plane can't skip one.
 local Pickups=Gameplay.world.speed_pickups
 local from,to=p.pickupFrom or p.body.Position,p.body.Position;p.pickupFrom=to
 if p.model:GetAttribute("State")=="FLYING" then
  for _,marker in ipairs(self.pickups) do
   if now>=marker:GetAttribute("ReadyAt") and Rules.segmentHitsBox(marker.Position,marker.Size,from,to) then
    marker:SetAttribute("ReadyAt",now+Pickups.respawn_seconds);p.pickupBonus,p.pickupUntil=Rules.stackPickup(p.pickupBonus or 0,p.pickupUntil or 0,now,Pickups)
    p.model:SetAttribute("PickupUntil",p.pickupUntil);p.model:SetAttribute("Message",Lines.pick("speedPickup"))
   end
  end
 end
 if p.waitingPad then
  if (p.body.Position-p.waitingHome.Position).Magnitude>450 or now-p.queuedAt>25 then self:clearLandingQueue(p)
  elseif self:padAvailable(p.waitingPad,p.id) then
   p.model:SetAttribute("HoldingPosition",Landing.approach(p.waitingHome,Desk).Position)
   p.model:SetAttribute("DeskAvailable",true);say(p,"padFree")
  end
 end
 if now-p.launchAt<3 then return end
 local homes={{home=p.home,key="desk:"..p.seat}}
 for index,desk in ipairs(self.neutralDesks) do
  for slot=1,2 do table.insert(homes,{home=desk.CFrame*CFrame.new(slot==1 and -48 or 48,desk.Size.Y/2+2.8,0),key="neutral:"..index..":"..slot}) end
 end
 if p.team then
  for _,other in pairs(self.pilots) do if other~=p and other.team==p.team then table.insert(homes,{home=other.home,key="desk:"..other.seat}) end end
 end
 for _,slot in ipairs(homes) do
  if Landing.linedUp(slot.home,p.body.Position,p.body.CFrame.LookVector,Desk) and self:land(p,slot.home,slot.key) then return end
 end
end
function Service:step(dt)
 local now=workspace:GetServerTimeNow()
 if not self.active then return end
 local train=Gameplay.world.monorail.enabled and MonorailRules.cars(now)   -- the toy monorail: solid, it kills
 for _,p in pairs(self.pilots) do
  local state=p.model:GetAttribute("State")
  p.model:SetAttribute("Protected",self:protected(p,now))
  p.model:SetAttribute("ProtectionRemaining",p.protectionRemaining)
  p.protectionRemaining,p.outOfHangar=Landing.hangarSafety(p.protectionRemaining,p.outOfHangar or 0,(state=="DESK" or state=="LANDING") and self:atDesk(p),dt,Desk.protected_seconds_per_life,Desk.protection_refill_out_seconds)
  if state=="DESTROYED" and p.drill then
   if now>=p.respawnAt then self:remove(p,"vacancy") end -- a folded practice target is gone for good
  elseif state=="DESTROYED" and now>=p.respawnAt then
   if not self.padReservations["desk:"..p.seat] then self:replace(p) else say(p,"padWait") end
  elseif state=="TAKEOFF" then self:takeoffStep(p,dt)
  elseif state=="FLYING" and p.held then -- holding still for the winners' moment
  elseif state=="FLYING" and p.drill then
   -- A practice target plane: held on its spot or sweeping left and right in front of its pilot (TrainingCourse).
   local d=p.drill;d.t+=dt
   local pose,velocity=Course.pose(d.spec,d.center,d.t,d.face,d.side)
   p.drive.VectorVelocity=velocity+(pose.Position-p.body.Position)*3;p.orientation.CFrame=pose.Rotation
  elseif state=="FLYING" then
   local utility=p.loadout.utility and self.catalog:get(p.loadout.utility)
   local boosting=utility and p.boostHeld and (p.model:GetAttribute("Boost") or 0)>0
   local blown=p.wind or 1
   p.model:SetAttribute("BoostSpeedFactor",(boosting and utility.speed_factor or 1)*(1+(now<(p.pickupUntil or 0) and p.pickupBonus or 0))*blown)
   -- Boost drives the plane along its nose even with no Lift (Alan 2026-10-14), so it counts as powered flight.
   p.model:SetAttribute("Boosting",boosting==true);if boosting then p.boostedAt=now end
   -- Drain in 0.2 s steps so these attributes replicate at 5 Hz, not every frame.
   p.liftDrain=(p.liftDrain or 0)+dt;p.boostDrain=(p.boostDrain or 0)+(boosting and dt or 0)
   if p.liftDrain>=.2 then
    -- Slow motion (the tutorial's aiming) keeps Lift full: you only turn and aim there (Alan 2026-10-19).
    p.model:SetAttribute("Lift",(p.slow or p.keepLift) and p.stats.lift or math.max(p.gentle and 1 or 0,Rules.lift(p.model:GetAttribute("Lift"),p.stats.lift,p.liftDrain)));p.liftDrain=0
    if p.boostDrain>0 then p.model:SetAttribute("Boost",math.max(p.gentle and .01 or 0,p.model:GetAttribute("Boost")-p.boostDrain));p.boostDrain=0 end
   end
   local localPos=self.boundsCF:PointToObjectSpace(p.body.Position)
   local outside=math.abs(localPos.X)>self.boundsSize.X/2+12 or (localPos.Y>self.boundsSize.Y/2+self.headroom+12 or localPos.Y<-self.boundsSize.Y/2-12) or math.abs(localPos.Z)>self.boundsSize.Z/2+12
   if outside and not p.pin then p.outSince=p.outSince or now;say(p,"turnBack") elseif p.outSince then p.outSince=nil;p.model:SetAttribute("Message","") end
   if p.outSince and now-p.outSince>Gameplay.combat.bounds_grace_seconds and not self.safe and not p.gentle then self:destroy(p,{kind="bounds"},"bounds");continue end
   -- Blink check every step (2026-10-17): a teleport and back inside the 0.25 s window. It compares against the last
   -- position the server saw change, over the time since, so bursty replication can't trip it.
   -- ponytail: one generous speed cap (2.5x cruise + 40) catches blinks only; the 0.25 s check still judges speed.
   if p.player then
    local pos=p.body.Position
    if pos~=p.seenPos then
     if p.seenPos and (pos-p.seenPos).Magnitude>(p.stats.speed*2.5+40)*(now-p.seenAt)+16 then p.blink=true end
     p.seenPos,p.seenAt=pos,now
    end
   end
   if p.player and (now-p.checkAt>=.25 or p.blink) then
    p.blink=nil
    local elapsed=now-p.checkAt;local cf=p.body.CFrame
    -- The booster's extra speed only counts while it is (or just was) firing (2026-10-17 audit: it was always on).
    local cruise=p.stats.speed*(utility and now-(p.boostedAt or -math.huge)<1 and utility.speed_factor or 1)*(1+(now<(p.pickupUntil or 0)+1 and p.pickupBonus or 0))*(now<(p.windAt or -math.huge)+1 and 1+Gameplay.world.ducts.blower.wind or 1)
    -- A short grace after boosting covers the client hearing late that the boost ran out.
    local empty=p.model:GetAttribute("Lift")<=0 and now-(p.boostedAt or -math.huge)>.6
    if empty and not p.emptySince then p.emptySince,p.emptyY,p.emptyUp=now,p.checkCFrame.Y,0 end
    if not empty then p.emptySince=nil end
    if empty then p.emptyUp+=(p.model:GetAttribute("Updraft") or 0)*elapsed end
    local allowed=Rules.movementAllowed(p.checkCFrame.Position,cf.Position,p.body.AssemblyLinearVelocity,elapsed,cruise*(empty and Gameplay.flight.glide_max_speed_factor or Gameplay.flight.lift_dive_max_speed_factor))
     and Rules.turnAllowed(p.checkCFrame.LookVector,cf.LookVector,elapsed,p.stats.turn)
     and (not empty or Rules.climbAllowed(cf.Y,p.emptyY,cruise,now-p.emptySince,p.emptyUp))
    p.checkAt=now
    if allowed then p.checkCFrame=cf;p.corrections=0
    else
     -- A client that keeps ignoring the correction is cheating (or hopelessly lagged): after 1.5 s of it the plane
     -- is lost, like leaving the room. One lag spike only snaps it back.
     p.corrections=(p.corrections or 0)+1
     if p.corrections>=6 then self:destroy(p,{kind="unfolded"},"bounds");continue end
     -- Lag or a bad client: put the plane back where it last flew legally instead of killing it.
     p.body.CFrame=p.checkCFrame;p.body.AssemblyLinearVelocity=p.checkCFrame.LookVector*p.stats.speed
     p.lastPosition,p.lastCFrame,p.seenPos,p.seenAt=p.checkCFrame.Position,p.checkCFrame,p.checkCFrame.Position,now
     -- Count the empty-Lift climb limit again from the corrected spot, or the old spot fails too and every check snaps.
     if empty then p.emptySince,p.emptyY,p.emptyUp=now,p.checkCFrame.Y,0 end
     say(p,"wobble")
     continue
    end
   end
   p.regionClock+=dt
   if p.regionClock>=.1 then p.regionClock%=.1;self:regionsFor(p,now) end
   if p.model:GetAttribute("State")~="FLYING" then continue end
   -- ponytail: overlap each frame, no sweep. A plane is ~15 studs long and moves under 10 per update, so it
   -- cannot skip through the room's solid parts; add a swept check if thin, fast-crossed parts appear.
   local part,normal=self:contact(p)
   if part then self:impact(p,normal,part,now,dt) end
   if p.lastPosition and p.body.Position.Y>Gameplay.world.ducts.floor_y then
    for i,frame in ipairs(self.ductFans) do
     local push=DuctRules.fanClip(frame:PointToObjectSpace(p.lastPosition),frame:PointToObjectSpace(p.body.Position),DuctRules.fanAngle(now,i))
     if push then self:fanHit(p,frame:VectorToWorldSpace(push),now) end
    end
   end
   if train and p.model:GetAttribute("State")=="FLYING" then
    -- The train is solid like a building (Alan 2026-10-16): a skim scrapes, a hard hit or the train running into you crashes.
    -- Every corner of the plane's parts (wingtips, nose, tail fin) counts, checked only when the train is near.
    local points,near={p.body.Position},false
    for _,car in ipairs(train) do near=near or (car.cframe.Position-p.body.Position).Magnitude<car.size.Magnitude/2+40 end
    local colliders=near and p.model:FindFirstChild("Colliders")
    for _,piece in ipairs(colliders and colliders:GetChildren() or {}) do
     for i=0,7 do table.insert(points,piece.CFrame*(piece.Size*Vector3.new(i%2-.5,(i//2)%2-.5,i//4-.5))) end
    end
    local moving=near and {}
    for i in ipairs(moving and train or {}) do moving[i]=MonorailRules.velocity(i,now) end
    local car,normal=MonorailRules.hit(train,points,p.previousVelocity or p.body.AssemblyLinearVelocity,moving)
    if car then
     self.trainCars=self.trainCars or workspace:FindFirstChild("MonorailTrain",true)
     -- The front of the moving train running into a plane (a T-bone, or catching a slow plane from behind) kills at
     -- once (Alan 2026-10-18); everywhere else the train is a building wall.
     local pushed=math.max(0,MonorailRules.velocity(car,now):Dot(normal))
     if pushed>Gameplay.world.monorail.nose_kill_speed then pushed=math.huge end
     self:impact(p,normal,self.trainCars and self.trainCars:FindFirstChild("car-"..car) or p.body,now,dt,pushed)
    end
   end
   if p.model:GetAttribute("State")~="FLYING" then continue end
   if now-p.lastContact>.6 then
    for _,other in ipairs(workspace:GetPartsInPart(p.body,self.regions)) do
     local q=other~=p.body and other.Name=="Root" and self.byId[other.Parent.Name]
     -- A lesson's targets and Pals never ram their player (Alan: a Pal can't fold you).
     if q and not (p.foeOf or q.foeOf) and q.model:GetAttribute("State")=="FLYING" and now-q.lastContact>.6 and self:touching(p,q) then self:ram(p,q,now);break end
    end
   end
   p.lastPosition,p.lastCFrame=p.body.Position,p.body.CFrame;p.previousVelocity=p.body.AssemblyLinearVelocity
  end
 end
end
return Service
