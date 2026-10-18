local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).avatar_display
local Service={};Service.__index=Service
function Service.new(flight)
 return setmetatable({flight=flight,models={},requests={},celebrating={}},Service)
end
-- A bot dresses like a player: hair, shirt, pants, skin tone and sometimes a cap, shades or a backpack, all free
-- Roblox-made catalog items (config avatar_display.bot_outfits). The same name always gets the same outfit.
function Service.outfit(name)
 local outfits=Config.bot_outfits
 local seed=0
 for i=1,#name do seed=(seed*31+string.byte(name,i))%2147483647 end
 local rng=Random.new(seed)
 local function any(list) return list[rng:NextInteger(1,#list)] end
 local description=Instance.new("HumanoidDescription")
 local skin=Color3.fromRGB(table.unpack(any(outfits.skin_tones)))
 for _,part in ipairs({"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}) do description[part.."Color"]=skin end
 description.HairAccessory=tostring(any(outfits.hair))
 description.Shirt,description.Pants=any(outfits.shirts),any(outfits.pants)
 if rng:NextNumber()<outfits.hat_chance then description.HatAccessory=tostring(any(outfits.hats)) end
 if rng:NextNumber()<outfits.glasses_chance then description.FaceAccessory=tostring(any(outfits.glasses)) end
 if rng:NextNumber()<outfits.backpack_chance then description.BackAccessory=tostring(any(outfits.backpacks)) end
 return description
end
function Service:remove(p)
 self.requests[p.id]=nil
 local model=self.models[p.id];if model then model:Destroy();self.models[p.id]=nil end
end
function Service:assign(p)
 if self.models[p.id] or self.requests[p.id] or self.flight.room.Name~="Arena" then return end
 local token={};self.requests[p.id]=token
 task.spawn(function()
  local ok,model=pcall(function()
   if p.player then return Players:CreateHumanoidModelFromUserIdAsync(p.player.UserId) end
   return Players:CreateHumanoidModelFromDescriptionAsync(Service.outfit(p.name),Enum.HumanoidRigType.R15)
  end)
  if self.requests[p.id]~=token or self.flight.byId[p.id]~=p then if ok then model:Destroy() end;return end
  if not ok then
   self.requests[p.id]=nil
   if p.player then
    p.player:SetAttribute("AvatarStatus","Appearance unavailable. Your equipped avatar will retry next round.")
    local label=Instance.new("BillboardGui");label.Name="AppearanceUnavailable";label.Size=UDim2.fromOffset(250,44);label.StudsOffset=Vector3.new(0,65,0);label.Adornee=self.flight.desks[p.seat];label.Parent=self.flight.room
    local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=.25;text.Text=p.name.."\nAppearance unavailable";text.TextColor3=Color3.fromRGB(245,235,215);text.TextSize=14;text.Parent=label;self.models[p.id]=label
   end
   return
  end
  self.requests[p.id]=nil
  model.Name=p.name.." at desk";model:SetAttribute("SeatedAvatar",true);model:SetAttribute("PilotId",p.id)
  for _,item in ipairs(model:GetDescendants()) do
   if item:IsA("LuaSourceContainer") then item:Destroy()
   elseif item:IsA("BasePart") then item.CanCollide=false;item.CanQuery=false;item.CanTouch=false;item.Massless=true end
   if item:IsA("AnimationConstraint") then item.IsKinematic=true end
  end
  local humanoid=model:FindFirstChildOfClass("Humanoid");local root=model:FindFirstChild("HumanoidRootPart")
  if not humanoid or not root then model:Destroy();return end
  humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.AutoRotate=false;humanoid.EvaluateStateMachine=false
  local top,bottom=-math.huge,math.huge
  for _,part in ipairs(model:GetChildren()) do
   if part:IsA("BasePart") and part~=root then top=math.max(top,part.Position.Y+part.Size.Y/2);bottom=math.min(bottom,part.Position.Y-part.Size.Y/2) end
  end
  model:ScaleTo(model:GetScale()*Config.standing_height_studs/math.max(1,top-bottom))
  root.Anchored=true
  local offset=p.home.LookVector*-115+Vector3.new(0,8,0)
  model:PivotTo(CFrame.new(p.home.Position+offset)*p.home.Rotation)
  model.Parent=self.flight.room;self.models[p.id]=model
  -- Roblox's own sitting animation supports supplied R6/R15 joints, including AnimationConstraint.
  local seated=pcall(function()
   local animation=Instance.new("Animation");animation.Name="SeatedPose"
   animation.AnimationId=humanoid.RigType==Enum.HumanoidRigType.R15 and "rbxassetid://2506281703" or "rbxassetid://178130996"
   animation.Parent=model
   local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator",humanoid)
   local track=animator:LoadAnimation(animation);track.Priority=Enum.AnimationPriority.Action;track:Play(0,1,1)
   humanoid.Sit=true
   local deadline=os.clock()+5
   repeat Run.Heartbeat:Wait() until track.Length>0 or os.clock()>=deadline or not model.Parent
   assert(model.Parent and track.Length>0,"Seated animation unavailable")
   track.TimePosition=math.min(.2,track.Length*.5);track:AdjustSpeed(0)
   Run.Heartbeat:Wait();Run.Heartbeat:Wait()
   local chair=self.flight.room:FindFirstChild("Chair"..self.flight.desks[p.seat].Name:sub(5))
   local torso=model:FindFirstChild("LowerTorso") or model:FindFirstChild("Torso")
   if chair and torso then
    -- Hips on the seat, a little toward the backrest, so knees stay clear of the desk (Alan, 2026-10-11).
    local back=(chair.Position-self.flight.desks[p.seat].Position)*Vector3.new(1,0,1)
    local hips=chair.Position+back.Unit*10+Vector3.new(0,chair.Size.Y/2+1,0)
    model:PivotTo(model:GetPivot()+hips-Vector3.new(torso.Position.X,torso.Position.Y-torso.Size.Y/2,torso.Position.Z))
   end
  end)
  model:SetAttribute("SeatedPoseLoaded",seated)
  if not seated and p.player then p.player:SetAttribute("AvatarStatus","Your avatar loaded, but its seated pose is unavailable.") end
  if not model.Parent then return end
  local proxies=Instance.new("Folder");proxies.Name="Collision";proxies.Parent=model
  for _,part in ipairs(model:GetChildren()) do
   if part:IsA("BasePart") and part~=root then
    local proxy=Instance.new("Part");proxy.Name="AvatarSurface";proxy.Size=part.Size;proxy.CFrame=part.CFrame;proxy.Transparency=1
    proxy.Anchored=true;proxy.CanTouch=false;proxy.CanQuery=true;proxy.CanCollide=true;proxy.Parent=proxies
   end
  end
 end)
end
-- The winners' moment (Alan 2026-10-17): 1st, 2nd and 3rd jump up onto their desks and dance, cheer or wave
-- (Roblox's own R15 emotes). sitDown puts everyone back in their chair for the vote lap.
local EMOTES={"rbxassetid://507771019","rbxassetid://507770677","rbxassetid://507770239"}
local JUMP_SECONDS=.7
function Service:celebrate(ids)
 self:sitDown()
 for place,id in ipairs(ids) do
  local p,model=self.flight.byId[id],self.models[id]
  local humanoid=model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
  local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
  if p and animator then
   local seated=animator:GetPlayingAnimationTracks()
   for _,track in ipairs(seated) do track:Stop(0) end
   local from=model:GetPivot()
   local emote=Instance.new("Animation");emote.Name="WinnerEmote";emote.AnimationId=EMOTES[place];emote.Parent=model
   local track=animator:LoadAnimation(emote);track.Looped=true;track.Priority=Enum.AnimationPriority.Action
   self.celebrating[id]={from=from,seated=seated,track=track,model=model}
   model:SetAttribute("Celebrating",place)
   task.spawn(function()
    Run.Heartbeat:Wait()
    -- Feet on the desk top, beside the runway, facing the middle of the room.
    local desk=self.flight.desks[p.seat]
    local box,size=model:GetBoundingBox()
    local spot=desk.CFrame*Vector3.new(desk.Size.X*.3,desk.Size.Y/2,0)
    local stand=from.Position.Y-(box.Position.Y-size.Y/2)
    local goal=CFrame.lookAt(spot+Vector3.new(0,stand,0),Vector3.new(0,spot.Y+stand,0))
    local start=os.clock()
    while self.celebrating[id] and os.clock()-start<JUMP_SECONDS do
     local t=(os.clock()-start)/JUMP_SECONDS
     model:PivotTo(from:Lerp(goal,t)+Vector3.new(0,math.sin(t*math.pi)*size.Y*.6,0))
     Run.Heartbeat:Wait()
    end
    if self.celebrating[id] then model:PivotTo(goal);track:Play(.2) end
   end)
  end
 end
end
function Service:sitDown()
 for id,c in pairs(self.celebrating) do
  self.celebrating[id]=nil
  if c.model.Parent then
   c.track:Stop(0);c.model:PivotTo(c.from);c.model:SetAttribute("Celebrating",nil)
   for _,track in ipairs(c.seated) do track:Play(0);track.TimePosition=math.min(.2,track.Length*.5);track:AdjustSpeed(0) end
  end
 end
end
return Service
