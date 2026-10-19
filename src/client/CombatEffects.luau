local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Tween=game:GetService("TweenService")
local Root=RS:WaitForChild("FlyFightPaper")
local Fans=require(Root.Generated.Gameplay).world.fans
local Catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
local Rules=require(Root.Shared.CombatRules)
local Config=require(Root.Generated.Gameplay).combat
local Aircraft=require(Root.Shared.Aircraft)
local Lines=require(Root.Shared.Lines)
local Audio=require(script.Parent.Audio)
local Motion=require(script.Parent.WeaponMotion)
local FlightState=require(script.Parent.FlightController).state
local assist=math.cos(math.rad(require(Root.Generated.Gameplay).combat.gun_assist_deg))
local convergence=require(Root.Generated.Gameplay).combat.gun_convergence_studs
local Effects={}
-- Gun assist: when the nose is within combat.gun_assist_deg (3) of the lead marker, shots go to the marker: a
-- nudge for the nose trailing a moving aim. Alan 2026-10-19: 7 degrees felt like magnetised bullets ("like War
-- Thunder" is the model), 1 made hitting anything too hard; lessons get the same 3.
-- Also returns the target's range: both guns meet there. At a fixed 150 studs they crossed and flew past either
-- side of a plane seen from behind at 300 (measured 2026-10-19), though the dot was red on the ring.
function Effects.aim(body,weapon)
 local leadFor=FlightState.leadFor
 if leadFor and weapon then
  local offset=leadFor(weapon)-body.Position
  if body.CFrame.LookVector:Dot(offset.Unit)>=assist then return offset.Unit,offset.Magnitude end
  return body.CFrame.LookVector,offset.Magnitude
 end
 return body.CFrame.LookVector
end
local colors={pellet=Color3.fromRGB(255,240,170),staple=Color3.fromRGB(220,230,240),rubber=Color3.fromRGB(250,180,100),paperclip=Color3.fromRGB(125,225,255),eraser=Color3.fromRGB(255,145,175),pencil=Color3.fromRGB(255,210,70)}
function Effects.start(getPlane)
 local folder=Instance.new("Folder");folder.Name="CombatEffects";folder.Parent=workspace
 local pool,active={},{}
 local created,activeCount=0,0
 local equipment=Root.Assets:FindFirstChild("EquipmentParts")
 local function acquire(weapon)
  local kind=weapon or "paper"
  pool[kind]=pool[kind] or {}
  local cap=Root:GetAttribute("Quality")=="Low" and 64 or Root:GetAttribute("Quality")=="Medium" and 128 or 256
  if activeCount>=cap then return nil end
  if #pool[kind]>0 then activeCount+=1;local p=table.remove(pool[kind]);p.Transparency=0;return p end
  if created>=cap then
   -- A full pool of another projectile type must not silence this weapon's visuals.
   for _,free in pairs(pool) do if #free>0 then table.remove(free):Destroy();created-=1;break end end
   if created>=cap then return nil end
  end
  created+=1;activeCount+=1
  local look=Aircraft.shotLook(weapon)
  local template=look or weapon and equipment and equipment:FindFirstChild("ammo_"..weapon)
  local p=template and template.MeshId~="" and template:Clone() or Instance.new("Part")
  p:SetAttribute("OwnLook",look~=nil)
  p:SetAttribute("EffectKind",kind);p:SetAttribute("EffectRotation",template and template.CFrame.Rotation or CFrame.identity)
  p.Name="ShotVisual";p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  local start=Instance.new("Attachment");start.Name="StreakStart";start.Parent=p
  local finish=Instance.new("Attachment");finish.Name="StreakEnd";finish.Parent=p
  local beam=Instance.new("Beam");beam.Name="Streak";beam.Attachment0=start;beam.Attachment1=finish;beam.FaceCamera=true
  beam.LightEmission=1;beam.Width0=.5;beam.Width1=.15;beam.Enabled=false;beam.Parent=p
  return p
 end
 local function release(id)
  local shot=active[id];if not shot then return end
  shot.part.Streak.Enabled=false;shot.part.Parent=nil;table.insert(pool[shot.part:GetAttribute("EffectKind")],shot.part);active[id]=nil;activeCount-=1
 end
 -- Paper shreds and dust puffs: a few pooled emitters moved to each impact and fired with Emit().
 local function emitter(name,texture,color,lifetime,speed)
  local e=Instance.new("ParticleEmitter");e.Name=name;e.Texture=texture;e.Color=ColorSequence.new(color)
  e.Lifetime=lifetime;e.Speed=speed;e.SpreadAngle=Vector2.new(180,180);e.Rate=0;e.LightInfluence=1
  return e
 end
 local function sizes(e,from,to) e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,from),NumberSequenceKeypoint.new(1,to)}) end
 local function shredEmitter()
  local e=emitter("Shreds","rbxasset://textures/particles/SquareParticle.png",Color3.fromRGB(246,243,230),NumberRange.new(.6,1.2),NumberRange.new(12,30))
  e.Squash=NumberSequence.new(.6);e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-420,420)
  e.Acceleration=Vector3.new(0,-35,0);e.Drag=3;sizes(e,.45,.3)
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.8,0),NumberSequenceKeypoint.new(1,1)})
  return e
 end
 local function puffEmitter(color)
  local e=emitter("Puff","rbxasset://textures/particles/smoke_main.dds",color,NumberRange.new(.35,.6),NumberRange.new(4,10))
  e.Drag=4;sizes(e,1,4);e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,1)})
  return e
 end
 local bursts,burstIndex={},0
 for i=1,8 do
  local a=Instance.new("Attachment");a.Name="CombatBurst";a.Parent=workspace.Terrain
  shredEmitter().Parent=a;puffEmitter(Color3.fromRGB(225,220,205)).Parent=a;bursts[i]=a
 end
 local function burst(position,shreds,puffs,scale)
  if not position or (position-workspace.CurrentCamera.CFrame.Position).Magnitude>700 then return end
  if Root:GetAttribute("Quality")=="Low" then shreds=math.ceil(shreds/2) end
  burstIndex=burstIndex%#bursts+1;local a=bursts[burstIndex];a.WorldPosition=position
  sizes(a.Shreds,.45*scale,.3*scale);sizes(a.Puff,scale,4*scale)
  if shreds>0 then a.Shreds:Emit(shreds) end
  if puffs>0 then a.Puff:Emit(puffs) end
 end
 local feed={}
 local myId=tostring(Players.LocalPlayer.UserId)
 -- Damage direction: a red bar on a ring around the screen centre, on the side the shot came from.
 local function incoming(gui,attackerId)
  local attacker=workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(attackerId)
  local root=attacker and attacker:FindFirstChild("Root");if not root then return end
  local camera=workspace.CurrentCamera.CFrame
  local offset=camera:VectorToObjectSpace(root.Position-camera.Position)
  local angle=(math.abs(offset.X)+math.abs(offset.Y)<1e-3) and math.pi or math.atan2(offset.X,offset.Y)
  local bar=Instance.new("Frame");bar.Name="DamageDirection";bar.AnchorPoint=Vector2.new(.5,.5);bar.BorderSizePixel=0
  bar.Size=UDim2.fromOffset(70,10);bar.BackgroundColor3=Color3.fromRGB(255,70,60);bar.Rotation=math.deg(angle)
  bar.Position=UDim2.new(.5,math.sin(angle)*190,.5,-math.cos(angle)*190);bar.Parent=gui
  Tween:Create(bar,TweenInfo.new(.9),{BackgroundTransparency=1}):Play()
  game:GetService("Debris"):AddItem(bar,1)
 end
 -- Hit marker: a white X on the nose dot for each confirmed hit; a bigger red X for a kill.
 local function marker(gui,kill)
  local nose=gui:FindFirstChild("NoseDot");local x=gui:FindFirstChild("HitMarker")
  if not x then
   x=Instance.new("Frame");x.Name="HitMarker";x.AnchorPoint=Vector2.new(.5,.5);x.BackgroundTransparency=1;x.Parent=gui
   for i,angle in ipairs({45,-45}) do
    local bar=Instance.new("Frame");bar.Name="Bar"..i;bar.AnchorPoint=Vector2.new(.5,.5);bar.Position=UDim2.fromScale(.5,.5)
    bar.Size=UDim2.new(1,0,0,3);bar.Rotation=angle;bar.BorderSizePixel=0;bar.Parent=x
   end
  end
  x.Position=nose and nose.Position or UDim2.fromScale(.5,.5);x.Size=UDim2.fromOffset(kill and 40 or 22,kill and 40 or 22)
  for _,bar in ipairs(x:GetChildren()) do
   bar.BackgroundColor3=kill and Color3.fromRGB(255,80,70) or Color3.new(1,1,1);bar.BackgroundTransparency=0
   Tween:Create(bar,TweenInfo.new(kill and .5 or .18),{BackgroundTransparency=1}):Play()
  end
 end
 local function notify(event)
  if event.kind=="hit" then
   -- (Deaths have their own animation: PlaneDeaths.) Bigger hits tear off more paper: a pellet a few scraps, a pencil a shower.
   burst(event.position,math.clamp(math.floor(3+event.damage/2),3,30),event.damage>=20 and 2 or 1,event.damage>=20 and 1.6 or 1)
  end
  local gui=Players.LocalPlayer.PlayerGui:FindFirstChild("FlightHUD");if not gui then return end
  if event.kind=="hit" and event.owner==myId then
   marker(gui,false);Audio.play("hit")
  elseif event.kind=="hit" and event.target==myId then
   incoming(gui,event.owner)
  elseif event.kind=="death" or event.kind=="prop" then
   if event.kind=="death" then
   if event.killerId==myId then marker(gui,true);Audio.play("kill") end
   -- Lesson crashes and leaving a lesson never reach the kill feed (Alan: they carried into the next match).
   if not event.practice then table.insert(feed,1,Lines.death(event.how or {kind=event.cause=="weapon" and "weapon" or "crash"},event.victimId==myId and "you" or event.victim,event.killer and (event.killerId==myId and "you" or event.killer))) end
   while #feed>4 do table.remove(feed) end
   -- One notebook slip per line (FlightHUD makes Slip1..4, newest on top).
   local slips=gui:FindFirstChild("KillFeed")
   for i=1,4 do local slip=slips and slips:FindFirstChild("Slip"..i);if slip then slip.Visible=feed[i]~=nil;slip.Words.Text=feed[i] or "" end end
   end
  end
 end
 local function drawShot(id,weapon,position,direction,speed,expires,time,enemy)
  local part=acquire(weapon)
  if not part then return end
  -- Erasers are missiles: drawn big, with a smoke trail, so everyone can see one coming.
  local row=Catalog:get(weapon);local missile=row and row.homing
  if missile and not part:FindFirstChild("Smoke") then
   local smoke=puffEmitter(Color3.fromRGB(240,236,228));smoke.Name="Smoke";smoke.Rate=70;smoke.Speed=NumberRange.new(1,3)
   smoke.Lifetime=NumberRange.new(.7,1.1);sizes(smoke,1.2,3.5);smoke.Parent=part
  end
  -- The paperclip is a thin wire: a trail of metal glints lets you see it coming (Alan's note 16).
  if weapon=="paperclip" and not part:FindFirstChild("Glint") then
   local glint=emitter("Glint","rbxasset://textures/particles/sparkles_main.dds",Color3.fromRGB(235,245,255),NumberRange.new(.15,.3),NumberRange.new(0))
   glint.Rate=60;glint.LightEmission=1;glint.LightInfluence=0;glint.Rotation=NumberRange.new(0,360);sizes(glint,1.6,0);glint.Parent=part
  end
  if part:IsA("MeshPart") then
   part.Size=Aircraft.shotSize(weapon,missile,part:GetAttribute("OwnLook") and Aircraft.shotLook(weapon))
   if not part:GetAttribute("OwnLook") then part.Material=Enum.Material.SmoothPlastic;part.Color=Color3.new(1,1,1) end
  else part.Material=Enum.Material.Neon;part.Color=colors[weapon];part.Size=Vector3.new(.14,.14,4) end
  part.Parent=folder
  local rotation=part:GetAttribute("EffectRotation") or CFrame.identity
  local length=math.clamp(speed*.018,8,24)
  part.StreakEnd.Position=rotation:VectorToObjectSpace(Vector3.new(0,0,length))
  part.Streak.Color=ColorSequence.new(colors[weapon]);part.Streak.Enabled=true
  Audio.flight(part,weapon)
  active[id]={part=part,position=position,direction=direction,speed=speed,expires=expires,time=time,homing=missile,ballistic=row and not missile and row or nil,flown=0,wobble=row and row.wobble_studs or 0,enemy=enemy}
 end
 local function hostile(ownerId)
  local mine=workspace.Planes:FindFirstChild(myId);local other=workspace.Planes:FindFirstChild(ownerId)
  local team=mine and mine:GetAttribute("Team") or ""
  return ownerId~=myId and (team=="" or not other or other:GetAttribute("Team")~=team)
 end
 local function receive(events)
  for _,event in ipairs(events) do
   if event.kind=="shot" then
    if event.owner==myId and event.weapon=="eraser" then Players.LocalPlayer:SetAttribute("EraserAwayAt",os.clock()) end
    -- The shooter already drew its own shots on the click frame (erasers wait for the server's lock check).
    if event.owner~=myId or event.weapon=="eraser" then Motion.fired(workspace.Planes:FindFirstChild(event.owner),event.slot);drawShot(event.id,event.weapon,event.position,event.direction,event.speed,event.expires,event.time,hostile(event.owner)) end
   elseif event.kind=="end" then
    local shot=active[event.id]
    if shot and event.wall then burst(event.position,2,2,.8) end
    if shot then
     -- A close hit can be received in the same packet as its shot. Give its trail one visible pulse.
     shot.position=event.position;shot.time=workspace:GetServerTimeNow();shot.speed=0;shot.ballistic=nil;shot.expires=shot.time+.08
    end
   elseif event.kind=="update" and active[event.id] then
    local shot=active[event.id];shot.position=event.position;shot.direction=event.direction;shot.flown=event.flown or shot.flown;shot.time=event.time
   else notify(event) end
  end
 end
 Root:WaitForChild("CombatEvents").OnClientEvent:Connect(receive)
 Root:WaitForChild("CombatCosmetics").OnClientEvent:Connect(receive)
 local nearMissAt=0
 Run.RenderStepped:Connect(function()
  local now=workspace:GetServerTimeNow()
  local me=workspace.Planes:FindFirstChild(myId);local body=me and me:GetAttribute("State")=="FLYING" and me:FindFirstChild("Root")
  for id,shot in pairs(active) do
   if now>=shot.expires then release(id)
   else
    local elapsed=math.max(0,now-shot.time)
    local speed=shot.homing and Rules.eraserSpeed(shot.speed,shot.flown,Config) or shot.speed
    local position=shot.follow and shot.follow.CFrame:PointToWorldSpace(shot.offset) or shot.ballistic and shot.position+Rules.shotOffset(shot.ballistic,shot.direction,elapsed) or shot.position+shot.direction*speed*(shot.homing and math.min(elapsed,.5) or elapsed)
    if shot.homing then shot.flown+=(position-shot.position).Magnitude;shot.position=position;shot.time=now end
    -- Near miss: an enemy shot passing within a few studs this frame shakes the camera and whooshes.
    if shot.enemy and body and not shot.passed and shot.last then
     local step=position-shot.last;local rel=body.Position-shot.last
     local along=step.Magnitude>0 and math.clamp(rel:Dot(step.Unit),0,step.Magnitude) or 0
     if (rel-(step.Magnitude>0 and step.Unit*along or Vector3.zero)).Magnitude<12 then
      shot.passed=true
      if os.clock()-nearMissAt>.25 then nearMissAt=os.clock();Players.LocalPlayer:SetAttribute("NearMissAt",nearMissAt) end
     end
    end
    shot.last=position
    if shot.wobble and shot.wobble>0 then position+=CFrame.lookAt(Vector3.zero,shot.direction).RightVector*math.sin(elapsed*40)*shot.wobble end
    shot.part.CFrame=CFrame.lookAt(position,position+shot.direction)*(shot.part:GetAttribute("EffectRotation") or CFrame.identity)
   end
  end
 end)
 local fanClock=0
 Run.Heartbeat:Connect(function(dt)
  fanClock+=dt;if fanClock<.25 then return end;fanClock%=.25
  for _,fan in ipairs(Fans) do
   local center=Vector3.new(table.unpack(fan.center));local half=Vector3.new(table.unpack(fan.halfsize))
   if (center-workspace.CurrentCamera.CFrame.Position).Magnitude<350+half.Magnitude then
    for i=1,3 do
     local part=acquire();if not part then break end
     part.Material=Enum.Material.Neon;part.Color=fan.kind=="upward" and Color3.fromRGB(150,235,245) or Color3.fromRGB(235,245,255);part.Transparency=.55;part.Size=Vector3.new(.12,.12,4);part.Parent=folder
     local direction=Vector3.new(table.unpack(fan.direction)).Unit
     local now=workspace:GetServerTimeNow();local offset=Vector3.new(math.sin(now*3+i*2)*half.X*.7,math.cos(now*2+i)*half.Y*.7,math.cos(now*3+i*2)*half.Z*.7)
     active["wind_"..now.."_"..fan.id..i]={part=part,position=center+offset,direction=direction,speed=35,expires=now+.65,time=now}
    end
   end
  end
 end)
 -- Protection bubbles: anchored and moved each frame (no welds onto planes the server simulates), reused when they end.
 local domes,domePool,spareDomes={},{},{}
 local function dome(plane)
  local part=table.remove(spareDomes) or Instance.new("Part")
  part.Name,part.Shape,part.Material,part.Color="ProtectionDome",Enum.PartType.Ball,Enum.Material.ForceField,Color3.fromRGB(120,200,255)
  part.Anchored,part.CanCollide,part.CanQuery,part.CanTouch,part.CastShadow=true,false,false,false,false
  local reach=plane:GetAttribute("ContactSize") or Vector3.new(16,6,16)
  part.Size=Vector3.one*math.max(reach.X,reach.Z)*1.1;part.Parent=folder;domePool[plane]=part
  return part
 end
 -- Damaged planes shed paper below half health and trail grey smoke below a quarter, so a weak plane reads at a glance.
 local damageClock=0
 Run.Heartbeat:Connect(function(dt)
  damageClock+=dt;if damageClock<.25 then return end;damageClock=0
  for _,plane in ipairs(workspace.Planes:GetChildren()) do
   local root=plane:FindFirstChild("Root")
   if root then
    local tatters=root:FindFirstChild("Shreds")
    if not tatters then
     tatters=shredEmitter();tatters.Speed=NumberRange.new(3,8);tatters.Parent=root
     local smoke=puffEmitter(Color3.fromRGB(120,118,112));smoke.Name="DamageSmoke";smoke.Lifetime=NumberRange.new(.8,1.4);smoke.Parent=root
    end
    local ratio=(plane:GetAttribute("Health") or 1)/math.max(1,plane:GetAttribute("MaxHealth") or 1)
    local flying=plane:GetAttribute("State")=="FLYING"
    tatters.Rate=flying and (ratio<.25 and 14 or ratio<.5 and 5 or 0) or 0
    root.DamageSmoke.Rate=flying and ratio<.25 and 12 or 0
    -- A white streak behind a plane going faster than its build (boost or a speed power-up).
    if not root:FindFirstChild("BoostTrail") then
     local top,bottom=Instance.new("Attachment"),Instance.new("Attachment")
     top.Position,bottom.Position=Vector3.new(0,.7,root.Size.Z/2),Vector3.new(0,-.7,root.Size.Z/2);top.Parent,bottom.Parent=root,root
     local trail=Instance.new("Trail");trail.Name="BoostTrail";trail.Attachment0,trail.Attachment1=top,bottom;trail.Lifetime=.4;trail.FaceCamera=true
     trail.Transparency=NumberSequence.new(.25,1);trail.Enabled=false;trail.Parent=root
    end
    root.BoostTrail.Enabled=flying and (plane:GetAttribute("BoostSpeedFactor") or 1)>1
    -- A light-blue bubble while the plane can't be hurt (takeoff and the launch protection).
    local state=plane:GetAttribute("State")
    domes[plane]=plane:GetAttribute("Protected") and (flying or state=="TAKEOFF") and (domes[plane] or dome(plane)) or nil
   end
  end
  for plane,part in pairs(domePool) do if domes[plane]~=part then part.Parent=nil;domePool[plane]=nil;table.insert(spareDomes,part) end end
 end)
 Run.RenderStepped:Connect(function()
  for plane,part in pairs(domes) do local root=plane:FindFirstChild("Root");if root then part.CFrame=root.CFrame else domes[plane]=nil end end
 end)
 -- Prediction: draw this player's shots, muzzle flashes and sounds on the click frame, using the same
 -- mounts and reload times as the server. The server still decides every hit.
 local room=RaycastParams.new();room.FilterType=Enum.RaycastFilterType.Include
 room.FilterDescendantsInstances={workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom")}
 local held,mounts,mountKey,serial,roundRobin={false,false},{},nil,0,{0,0}
 local mountPlane,mountLife=nil,nil
 local function flying()
  local plane=getPlane()
  if plane and plane.Parent and plane:GetAttribute("State")=="FLYING" and not Root:GetAttribute("OverlayOpen") and plane:FindFirstChild("Root") then return plane end
 end
 local function refresh(plane)
  local key=tostring(plane:GetAttribute("Mounts")).."|"..tostring(plane:GetAttribute("Life"))
  if key==mountKey and plane==mountPlane then return end
  local previous={};local now=workspace:GetServerTimeNow()
  if plane==mountPlane and plane:GetAttribute("Life")==mountLife then for _,mount in ipairs(mounts) do previous[mount.slot]=mount end end
  mountPlane,mountLife=plane,plane:GetAttribute("Life")
  mountKey,mounts=key,{}
  local ids=string.split(plane:GetAttribute("Mounts") or "",",");local groups=assert(Rules.triggerGroups({weapon_mounts=ids}))
  roundRobin={0,0}
  for slot,id in ipairs(ids) do
   local weapon=id~="" and Catalog:get(id)
   if weapon and not weapon.homing then
    local old=previous[slot];local same=old and old.weapon.id==id
    local heat,cooling=plane:GetAttribute("MountHeat"..slot) or 0,(plane:GetAttribute("MountCoolingUntil"..slot) or 0)>0
    heat,cooling=Rules.heatStep(heat,cooling,held[groups[slot]],now-(plane:GetAttribute("HeatUpdatedAt") or now),weapon)
    local ready=old and old.readyAt or 0
    if old and old.cooling and not same then ready=math.max(ready,now+old.heat*old.weapon.cooldown_seconds/old.weapon.shots_before_cooldown) end
    table.insert(mounts,{slot=slot,weapon=weapon,group=groups[slot],readyAt=ready,burstLeft=0,
     heat=same and old.heat or heat,cooling=same and old.cooling or cooling,heatAt=same and old.heatAt or now})
   end
  end
 end
 local function coolMount(plane,mount,firing,now)
  local weapon=mount.weapon
  mount.heat,mount.cooling=Rules.heatStep(mount.heat,mount.cooling,firing,now-mount.heatAt,weapon);mount.heatAt=now
  -- Local heat blocks instant feedback at the limit; the server's deadline also blocks a drifting prediction.
  local untilAt=plane:GetAttribute("MountCoolingUntil"..mount.slot) or 0
  if weapon.shots_before_cooldown and untilAt>now then
   mount.heat=math.max(mount.heat,(untilAt-now)*weapon.shots_before_cooldown/weapon.cooldown_seconds);mount.cooling=true
  end
 end
 local spreadRandom=Random.new()
 local function shoot(plane,mount,now)
  local body,weapon=plane.Root,mount.weapon
  Motion.fired(plane,mount.slot)
  local factor=plane:GetAttribute("MountScale") or 1
  local position=body.CFrame:PointToWorldSpace(Aircraft.muzzleOffset(mount.slot,factor,mount.weapon.id,Aircraft.fitOf(plane)))
  local aim,range=Effects.aim(body,weapon)
  local direction=Aircraft.converge(body,position,aim,range or convergence)
  if weapon.spread_deg>0 then
   local spread=math.rad(weapon.spread_deg)
   direction=(CFrame.lookAt(Vector3.zero,direction)*CFrame.Angles(spreadRandom:NextNumber(-spread,spread),spreadRandom:NextNumber(-spread,spread),0)).LookVector
  end
  local wall=workspace:Raycast(position,direction*Rules.shotRange(weapon),room)
  serial+=1
  -- ponytail: the wall is found along the straight aim line; the drop is a few studs over the shot's life.
  local hitAfter=wall and math.min(weapon.lifetime,Rules.travelTime(weapon,wall.Distance))
  if wall then task.delay(hitAfter,burst,wall.Position,2,2,.8) end
  drawShot("local"..serial,weapon.id,position,direction,weapon.projectile_speed,now+(hitAfter or weapon.lifetime),now)
  local flash=acquire()
  if flash then
   flash.Material=Enum.Material.Neon;flash.Color=Color3.fromRGB(255,240,180);flash.Size=Vector3.new(.7,.7,1.6);flash.Parent=folder
   active["flash"..serial]={part=flash,position=position,direction=direction,speed=0,expires=now+.05,time=now,follow=body,offset=body.CFrame:PointToObjectSpace(position)}
  end
  Audio.play(weapon.id)
 end
 local function step(plane,now,pressed)
  for _,mount in ipairs(mounts) do
   local weapon=mount.weapon
   coolMount(plane,mount,held[mount.group],now)
   if held[mount.group] and mount.readyAt<=now then
    if weapon.fire_mode=="automatic" then
     local heat,cooling,allowed=Rules.heatShot(mount.heat,mount.cooling,weapon)
     if allowed then shoot(plane,mount,now);mount.readyAt=now+weapon.shot_interval;mount.heat,mount.cooling=heat,cooling end
    elseif weapon.fire_mode=="burst" and mount.burstLeft==0 then mount.burstLeft,mount.burstNext,mount.readyAt=weapon.burst_count,now,now+weapon.burst_period end
   end
   while mount.burstLeft>0 and now>=mount.burstNext do shoot(plane,mount,now);mount.burstLeft-=1;mount.burstNext+=weapon.burst_spacing end
  end
  -- Semi-automatic weapons fire once per press, one mount at a time.
  if pressed then
   for offset=1,#mounts do
    local index=(roundRobin[pressed]+offset-1)%#mounts+1;local mount=mounts[index]
    if mount.group==pressed and mount.weapon.fire_mode=="semiautomatic" and mount.readyAt<=now then
     shoot(plane,mount,now);mount.readyAt=now+mount.weapon.shot_interval;roundRobin[pressed]=index;break
    end
   end
  end
 end
 Run.RenderStepped:Connect(function()
  local plane=getPlane();if not plane or not plane.Parent then return end
  refresh(plane);local now=workspace:GetServerTimeNow()
  local activePlane=flying()
  if activePlane then step(plane,now)
  else for _,mount in ipairs(mounts) do coolMount(plane,mount,false,now) end end
 end)
 -- The aim sent for a trigger leads for the first unguided gun on it.
 local function aimFor(body,group)
  for _,mount in ipairs(mounts) do if mount.group==group then return Effects.aim(body,mount.weapon) end end
  return body.CFrame.LookVector
 end
 return {aim=aimFor,press=function(which,down)
  local plane=flying();local now=workspace:GetServerTimeNow()
  if plane then refresh(plane);for _,mount in ipairs(mounts) do if mount.group==which then coolMount(plane,mount,held[which],now) end end end
  held[which]=down
  if down and plane then step(plane,now,which) end
 end}
end
return Effects
