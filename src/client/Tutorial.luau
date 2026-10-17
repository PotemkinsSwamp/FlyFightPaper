-- The first 60 seconds (Stage 6): a guided practice flight in the live classroom. The server makes the plane
-- nobody's enemy and earns it nothing; this sticky note walks through steer, fire, Lift/fans and a landing, then
-- drops the player into a Rookie match. Skippable (Skip goes straight to the match) and replayable (Tutorial button).
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Rules=require(Root.Shared.CombatRules)
local Gameplay=require(Root.Generated.Gameplay)
local Tutorial={active=false,step=1}
local STEPS={
 "Practice flight! Your plane takes off by itself...",
 "Steer: move the mouse. Your plane turns toward the circle.",
 "Fire: left click. Shoot down the paper target ahead!",
 "Lift keeps you flying and runs out. Fly up through the cyan fan to refill it.",
 "Land: fly back to your desk, through its paper-chain ring.",
 "Nice flying! At your desk, Edit build changes your plane. Joining a Rookie match...",
}
local LAUNCH,STEER,FIRE,LIFT,LAND,DONE=1,2,3,4,5,6
function Tutorial.begin()
 Tutorial.active=true;Tutorial.step=LAUNCH;Tutorial.heading=nil;Tutorial.flyingLife=nil;Tutorial.doneAt=nil
 Root:SetAttribute("TutorialOpen",true)
 Root.RoundAction:FireServer("practice")
end
function Tutorial.start(getPlane)
 local gui=Instance.new("ScreenGui");gui.Name="Tutorial";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=5;gui.Parent=Players.LocalPlayer.PlayerGui
 -- A sticky note near the top of the screen (Alan's paper menu look).
 local PaperUI=require(script.Parent.PaperUI);local Art=require(Root.Shared.UIAssets)
 local panel=Instance.new("ImageLabel");panel.Name="Note";panel.Image=Art.ingame.stickyNote;panel.ScaleType=Enum.ScaleType.Stretch;panel.BackgroundTransparency=1
 panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.fromScale(.5,.13);panel.Size=UDim2.fromOffset(540,200);panel.Rotation=-1;panel.Parent=gui
 local scale=Instance.new("UIScale");scale.Parent=panel
 local function fit() scale.Scale=math.max(.6,workspace.CurrentCamera.ViewportSize.Y/1080) end
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
 local label=PaperUI.words(panel,"Step","",45,42,450,90,30);label.TextWrapped=true;label.TextYAlignment=Enum.TextYAlignment.Top
 local function close()
  Tutorial.active=false;Root:SetAttribute("TutorialOpen",false)
 end
 local skip=PaperUI.button(panel,"Skip",Art.mainmenu.strip.red,"Skip to a match",290,138,220,52,2,function()
  if Tutorial.active then close();Root.RoundAction:FireServer("practiceDone") end
 end,24)

 -- Things to fly to: a label over the target, the nearest fan or the desk ring, drawn on top of everything.
 local pointer=Instance.new("BillboardGui");pointer.Name="TutorialPointer";pointer.AlwaysOnTop=true;pointer.Size=UDim2.fromOffset(180,60);pointer.LightInfluence=0
 local pointerText=PaperUI.words(pointer,"Text","",0,0,180,60,26);pointerText.Size=UDim2.fromScale(1,1);pointerText.TextXAlignment=Enum.TextXAlignment.Center
 pointerText.TextColor3=Color3.fromRGB(255,235,90);local outline=Instance.new("UIStroke");outline.Thickness=2;outline.Parent=pointerText
 local anchor=Instance.new("Part");anchor.Name="TutorialAnchor";anchor.Anchored,anchor.CanCollide,anchor.CanQuery,anchor.CanTouch,anchor.Transparency=true,false,false,false,1
 anchor.Size=Vector3.one;pointer.Adornee=anchor;pointer.Parent=Players.LocalPlayer.PlayerGui -- billboards do not draw inside a ScreenGui
 local function pointAt(position,text)
  pointer.Enabled=position~=nil
  if position then anchor.Position=position;anchor.Parent=workspace;pointerText.Text=text else anchor.Parent=nil end
 end

 -- The practice target: a copy of the player's own plane drawn only on this screen, placed every frame from the
 -- same numbers the server uses for hits (CombatRules.practiceTargetPose).
 local target
 local function clearTarget() if target then target:Destroy();target=nil end end
 local function drawTarget(plane)
  local at=plane:GetAttribute("PracticeTargetAt")
  if not at or (plane:GetAttribute("PracticeTargetHealth") or 0)<=0 then clearTarget();return nil end
  if not target then
   target=plane:Clone();target.Name="PracticeTarget"
   -- Plain white paper with an orange outline, so it never looks like the player's own plane.
   for _,item in target:GetDescendants() do
    if item:IsA("BasePart") then item.Anchored,item.CanCollide,item.CanQuery,item.CanTouch=true,false,false,false;item.Color=Color3.fromRGB(240,238,228)
     if item:IsA("MeshPart") then item.TextureID="" end
    elseif item:IsA("Constraint") or item:IsA("Script") or item:IsA("LocalScript") or item:IsA("Highlight") or item:IsA("BillboardGui")
     or item:IsA("Decal") or item:IsA("Texture") or item:IsA("SurfaceAppearance") then item:Destroy() end
   end
   local outline=Instance.new("Highlight");outline.FillTransparency=1;outline.OutlineColor=Color3.fromRGB(255,120,80);outline.Parent=target
   target.PrimaryPart=target:FindFirstChild("Root");target.Parent=workspace
  end
  local pose=Rules.practiceTargetPose(plane:GetAttribute("PracticeTargetFrom"),plane:GetAttribute("PracticeTargetDirection"),workspace:GetServerTimeNow()-at)
  target:PivotTo(pose)
  return pose.Position
 end
 local function inFan(position)
  for _,fan in Gameplay.world.fans do
   if fan.kind=="upward" then
    local offset=position-Vector3.new(fan.center[1],fan.center[2],fan.center[3])
    if math.abs(offset.X)<=fan.halfsize[1] and math.abs(offset.Y)<=fan.halfsize[2] and math.abs(offset.Z)<=fan.halfsize[3] then return true end
   end
  end
  return false
 end
 local function nearestFan(position)
  local best,distance=nil,math.huge
  for _,fan in Gameplay.world.fans do
   if fan.kind=="upward" then
    local center=Vector3.new(fan.center[1],fan.center[2],fan.center[3]);local d=(center-position).Magnitude
    if d<distance then best,distance=center,d end
   end
  end
  return best
 end

 local requested=0
 RunService.RenderStepped:Connect(function()
  panel.Visible=Tutorial.active and not Root:GetAttribute("OverlayOpen")
  local plane=getPlane()
  if not Tutorial.active or not plane or not plane.Parent or not plane:GetAttribute("Practice") then
   pointAt(nil);clearTarget()
   -- The round ended under the practice flight, or the player left it: put the note away.
   if Tutorial.active and Tutorial.step>LAUNCH and not Players.LocalPlayer:GetAttribute("InMatch") then close() end
   return
  end
  label.Text=STEPS[Tutorial.step];Root:SetAttribute("TutorialStep",Tutorial.step)
  local state,life=plane:GetAttribute("State"),plane:GetAttribute("Life")
  local body=plane:FindFirstChild("Root")
  -- At the desk (first time, or after a crash) the plane goes again by itself, until it is time to land.
  if state=="DESK" and (Tutorial.step<LAND or Tutorial.flyingLife~=life) and os.clock()-requested>2 then requested=os.clock();Root.FlightAction:FireServer("launch") end
  if state=="FLYING" then Tutorial.flyingLife=life end
  local step=Tutorial.step
  if step==LAUNCH and state=="FLYING" and body then Tutorial.heading=body.CFrame.LookVector;Tutorial.step=STEER
  elseif step==STEER and body and Tutorial.heading and body.CFrame.LookVector:Dot(Tutorial.heading)<.7 then Tutorial.step=FIRE
  elseif step==FIRE then
   -- Ask for a target; a new one if it flew off for half a minute without being hit.
   local at=plane:GetAttribute("PracticeTargetAt")
   if state=="FLYING" and (not at or workspace:GetServerTimeNow()-at>30) and os.clock()-requested>2 then requested=os.clock();Root.RoundAction:FireServer("practiceTarget") end
   local where=drawTarget(plane)
   pointAt(where and where+Vector3.new(0,12,0),"Target")
   if at and (plane:GetAttribute("PracticeTargetHealth") or 1)<=0 then Tutorial.step=LIFT end
  elseif step==LIFT then
   clearTarget()
   pointAt(body and nearestFan(body.Position),"Fan: fly through")
   if state=="FLYING" and body and inFan(body.Position) then Tutorial.step=LAND end
  elseif step==LAND then
   -- Like a real approach: line up out in front of the desk first, then fly straight through its ring.
   local ring=plane:GetAttribute("PracticeRing")
   local rel=ring and body and ring:PointToObjectSpace(body.Position)
   local lined=rel and rel.Z<-80 and math.abs(rel.X)<30 and math.abs(rel.Y)<40
   if ring then pointAt(lined and ring.Position or (ring*CFrame.new(0,10,-260)).Position,lined and "Your desk: straight on" or "Line up here") end
   if state=="DESK" and Tutorial.flyingLife==life then Tutorial.step=DONE;Tutorial.doneAt=os.clock() end
  elseif step==DONE then
   pointAt(nil)
   if os.clock()-Tutorial.doneAt>2.5 then close();Root.RoundAction:FireServer("practiceDone") end
  end
 end)
end
return Tutorial
