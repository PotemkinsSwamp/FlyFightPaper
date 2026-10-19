-- The tutorial's step engine (docs/plan/TUTORIAL-PLAN.md): a goal note at the top with the key to press, markers on
-- the things to fly to, a spotlight that dims everything but one button or bar, a tick and a ding for each finished
-- step, a hint when stuck, and Skip (tap K: step, hold K: lesson). The steps live in TutorialLessons.luau.
-- Lessons are practice: the server makes the plane nobody's enemy and pays nothing.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Gameplay=require(Root.Generated.Gameplay)
local Art=require(Root.Shared.UIAssets)
local PaperUI=require(script.Parent.PaperUI)
local Audio=require(script.Parent.Audio)
local Lessons=require(script.Parent.TutorialLessons)
local Tutorial={active=false}
local HINT_SECONDS=10
local HOLD_SKIP_SECONDS=1.5
local HOOP_RADIUS=30
local YELLOW=Color3.fromRGB(255,225,70)

function Tutorial.begin(lesson)
 Tutorial.lesson=Lessons[lesson or "flight"];Tutorial.index=0;Tutorial.active=true;Tutorial.askedAt=os.clock()
 Root:SetAttribute("TutorialOpen",true)
 Root.RoundAction:FireServer("practice")
end

function Tutorial.start(getPlane)
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui");gui.Name="Tutorial";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=20;gui.Parent=player.PlayerGui

 -- Spotlight: four dim panes around a hole, a yellow frame on the hole. Pulse: the frame only (while flying).
 local panes={}
 for i=1,4 do
  local pane=Instance.new("Frame");pane.BackgroundColor3=Color3.new(0,0,0);pane.BackgroundTransparency=.45;pane.BorderSizePixel=0;pane.Visible=false;pane.Parent=gui
  panes[i]=pane
 end
 local frame=Instance.new("Frame");frame.BackgroundTransparency=1;frame.Visible=false;frame.Parent=gui
 local stroke=Instance.new("UIStroke");stroke.Color=YELLOW;stroke.Thickness=4;stroke.Parent=frame
 Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)

 -- The goal note: sticky note near the top, lesson and step, the instruction, the key picture, the count.
 local note=Instance.new("ImageLabel");note.Name="Note";note.Image=Art.ingame.stickyNote;note.ScaleType=Enum.ScaleType.Stretch;note.BackgroundTransparency=1
 note.AnchorPoint=Vector2.new(.5,0);note.Position=UDim2.fromScale(.5,.17);note.Size=UDim2.fromOffset(620,230);note.Rotation=-1;note.Visible=false;note.Parent=gui
 local scale=Instance.new("UIScale");scale.Parent=note
 local function fit() scale.Scale=math.max(.6,workspace.CurrentCamera.ViewportSize.Y/1080) end
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
 local title=PaperUI.words(note,"Title","",40,24,540,34,24);title.TextColor3=Color3.fromRGB(150,60,40)
 local text=PaperUI.words(note,"Text","",40,58,440,96,30);text.TextWrapped=true;text.TextYAlignment=Enum.TextYAlignment.Top
 local key=PaperUI.words(note,"Key","",490,64,100,48,26);key.TextXAlignment=Enum.TextXAlignment.Center;key.BackgroundTransparency=0;key.BackgroundColor3=Color3.fromRGB(250,250,245)
 Instance.new("UICorner",key).CornerRadius=UDim.new(0,8);local keyStroke=Instance.new("UIStroke");keyStroke.Thickness=3;keyStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;keyStroke.Parent=key
 local tick=PaperUI.words(note,"Tick","✓",520,110,60,60,56);tick.TextColor3=Color3.fromRGB(40,150,60);tick.Visible=false
 local hint=PaperUI.words(note,"Hint","",40,150,540,30,22);hint.TextColor3=Color3.fromRGB(90,90,100)
 local gotIt=PaperUI.button(note,"GotIt",Art.mainmenu.strip.green or Art.mainmenu.strip.red,"Got it  [Space]",40,176,240,48,1,function() Tutorial.gotIt=true end,24)
 local skip=PaperUI.button(note,"Skip",Art.mainmenu.strip.red,"Skip  [K]",330,176,250,48,-1,function() Tutorial.skipStep=true end,24)
 local skipFill=Instance.new("Frame");skipFill.BackgroundColor3=Color3.new(1,1,1);skipFill.BackgroundTransparency=.5;skipFill.BorderSizePixel=0;skipFill.Size=UDim2.fromScale(0,1);skipFill.Parent=skip

 -- A short card in the middle: lesson finished or skipped, and how to come back (Alan: always tell them).
 local card=Instance.new("ImageLabel");card.Image=Art.ingame.stickyNote;card.ScaleType=Enum.ScaleType.Stretch;card.BackgroundTransparency=1
 card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.45);card.Size=UDim2.fromOffset(620,260);card.Visible=false;card.Parent=gui
 local cardScale=scale:Clone();cardScale.Parent=card
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()cardScale.Scale=scale.Scale end)
 local cardTitle=PaperUI.words(card,"Title","",40,30,540,56,44);cardTitle.TextXAlignment=Enum.TextXAlignment.Center
 local cardText=PaperUI.words(card,"Text","You can replay any lesson: Menu > Tutorial.",40,96,540,60,26);cardText.TextWrapped=true;cardText.TextXAlignment=Enum.TextXAlignment.Center
 PaperUI.button(card,"Play",Art.mainmenu.strip.green or Art.mainmenu.strip.red,"Go to a match",160,170,300,60,-1,function()
  card.Visible=false;Root.RoundAction:FireServer("practiceDone")
 end,30)

 -- Markers: a bouncing arrow over the thing to fly to (drawn on top of everything); an edge arrow when it's off-screen.
 local anchor=Instance.new("Part");anchor.Name="TutorialAnchor";anchor.Anchored,anchor.CanCollide,anchor.CanQuery,anchor.CanTouch,anchor.Transparency=true,false,false,false,1;anchor.Size=Vector3.one
 local board=Instance.new("BillboardGui");board.Name="TutorialMarker";board.AlwaysOnTop=true;board.Size=UDim2.fromOffset(220,110);board.LightInfluence=0;board.Adornee=anchor;board.Enabled=false
 board.Parent=player.PlayerGui -- billboards do not draw inside a ScreenGui
 local label=PaperUI.words(board,"Text","",0,0,220,40,26);label.Size=UDim2.new(1,0,0,40);label.TextXAlignment=Enum.TextXAlignment.Center;label.TextColor3=YELLOW
 local outline=Instance.new("UIStroke");outline.Thickness=2;outline.Parent=label
 local arrow=PaperUI.words(board,"Arrow","▼",0,40,220,60,56);arrow.Size=UDim2.new(1,0,0,60);arrow.TextXAlignment=Enum.TextXAlignment.Center;arrow.TextColor3=YELLOW
 outline:Clone().Parent=arrow
 local edge=PaperUI.words(gui,"EdgeArrow","➤",0,0,70,70,64);edge.AnchorPoint=Vector2.new(.5,.5);edge.TextXAlignment=Enum.TextXAlignment.Center;edge.TextColor3=YELLOW;edge.Visible=false
 outline:Clone().Parent=edge

 -- Hoops: paper rings built here (this screen only), one at a time, a little off to the side so you have to steer.
 local hoop,hoopModel,lastLocal=nil,nil,nil
 local hoopSide=1
 local function clearHoop() if hoopModel then hoopModel:Destroy() end;hoop,hoopModel,lastLocal=nil,nil,nil end
 local function clear(from,to)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={workspace:FindFirstChild("Planes"),hoopModel}
  return workspace:Spherecast(from,HOOP_RADIUS*.6,to-from,params)==nil
 end
 local function placeHoop(body)
  local look=body.CFrame.LookVector;local flat=Vector3.new(look.X,0,look.Z).Unit
  local height=Gameplay.world.height_studs
  hoopSide=-hoopSide
  local spot
  for _,turn in ipairs({20,-20,35,-35,0,60,-60,90,-90,135,180}) do
   local dir=CFrame.Angles(0,math.rad(turn*hoopSide),0):VectorToWorldSpace(flat)
   local at=body.Position+dir*260;at=Vector3.new(at.X,math.clamp(at.Y,90,height-90),at.Z)
   if clear(body.Position,at) and clear(at,at+dir*120) then spot=CFrame.lookAt(at,at+dir);break end
  end
  spot=spot or CFrame.lookAt(Vector3.new(0,height*.55,0),Vector3.new(0,height*.55,0)+flat)
  hoopModel=Instance.new("Model");hoopModel.Name="TutorialHoop"
  for i=1,20 do
   local a=i/20*math.pi*2
   local piece=Instance.new("Part");piece.Anchored,piece.CanCollide,piece.CanQuery,piece.CanTouch=true,false,false,false
   piece.Size=Vector3.new(4,10,3);piece.Material=Enum.Material.SmoothPlastic;piece.Color=i%2==0 and Color3.fromRGB(255,190,60) or Color3.fromRGB(255,120,80)
   piece.CFrame=spot*CFrame.Angles(0,0,a)*CFrame.new(0,HOOP_RADIUS,0);piece.Parent=hoopModel
  end
  hoopModel.Parent=workspace;hoop=spot
 end

 -- Spotlight on GUI pieces found by name anywhere on screen; pulse = the frame without the dim.
 local spotNames,pulseName=nil,nil
 local function findGui(name)
  for _,item in player.PlayerGui:GetDescendants() do
   if item.Name==name and item:IsA("GuiObject") and item.Visible and item.AbsoluteSize.X>0 then
    local layer=item:FindFirstAncestorWhichIsA("ScreenGui");if layer and layer.Enabled and layer~=gui then return item,layer end
   end
  end
 end
 local function box(names)
  local low,high
  for _,name in names do
   local item=findGui(name)
   if item then
    -- Absolute positions are screen-wide; this layer's own offsets start at its corner (under the top bar or not).
    -- Paper buttons have see-through margins round the art: frame the paper, not the whole box.
    local trim=item:IsA("ImageButton") and item.AbsoluteSize*.1 or Vector2.zero
    local a=item.AbsolutePosition-gui.AbsolutePosition+trim;local b=a+item.AbsoluteSize-trim*2
    low=low and Vector2.new(math.min(low.X,a.X),math.min(low.Y,a.Y)) or a
    high=high and Vector2.new(math.max(high.X,b.X),math.max(high.Y,b.Y)) or b
   end
  end
  return low,high
 end
 local function drawSpot(dim)
  local names=spotNames or (pulseName and {pulseName})
  local low,high=nil,nil;if names then low,high=box(names) end
  frame.Visible=low~=nil
  for _,pane in panes do pane.Visible=dim and low~=nil end
  if not low then return end
  low-=Vector2.new(10,10);high+=Vector2.new(10,10)
  frame.Position=UDim2.fromOffset(low.X,low.Y);frame.Size=UDim2.fromOffset(high.X-low.X,high.Y-low.Y)
  stroke.Transparency=dim and 0 or .5+.5*math.sin(os.clock()*6)
  if dim then
   local view=gui.AbsoluteSize
   panes[1].Position,panes[1].Size=UDim2.fromOffset(0,0),UDim2.fromOffset(view.X,low.Y)
   panes[2].Position,panes[2].Size=UDim2.fromOffset(0,high.Y),UDim2.fromOffset(view.X,view.Y-high.Y)
   panes[3].Position,panes[3].Size=UDim2.fromOffset(0,low.Y),UDim2.fromOffset(low.X,high.Y-low.Y)
   panes[4].Position,panes[4].Size=UDim2.fromOffset(high.X,low.Y),UDim2.fromOffset(view.X-high.X,high.Y-low.Y)
  end
 end

 local marked=nil
 local function drawMarker()
  board.Enabled=marked~=nil;edge.Visible=false
  if not marked then anchor.Parent=nil;return end
  anchor.Position=marked.position+Vector3.new(0,14+math.sin(os.clock()*5)*3,0);anchor.Parent=workspace;label.Text=marked.text
  local camera=workspace.CurrentCamera;local point,onScreen=camera:WorldToViewportPoint(marked.position)
  if onScreen then return end
  -- Off-screen: an arrow on the screen edge pointing the way to turn.
  local view=camera.ViewportSize;local center=view/2
  local flat=Vector2.new(point.X,point.Y)-center;if point.Z<0 then flat=-flat end
  if flat.Magnitude<1 then flat=Vector2.new(0,1) end
  local dir=flat.Unit;local reach=math.min((center.X-60)/math.max(math.abs(dir.X),1e-3),(center.Y-60)/math.max(math.abs(dir.Y),1e-3))
  local at=center+dir*reach;edge.Position=UDim2.fromOffset(at.X,at.Y);edge.Rotation=math.deg(math.atan2(dir.Y,dir.X));edge.Visible=true
 end

 local bolts=workspace:FindFirstChild("SpeedPickups")
 local ctx={data={},dt=0}
 ctx.marker=function(position,words) marked={position=position,text=words} end
 ctx.spotlight=function(...) spotNames={...} end
 ctx.pulse=function(name) pulseName=name end
 ctx.ding=function() Audio.play("purchase") end
 ctx.hoop=function() if not hoop and ctx.body then placeHoop(ctx.body) end;return hoop end
 ctx.clearHoop=clearHoop
 ctx.passedHoop=function()
  if not hoop or not ctx.body then return false end
  local now=hoop:PointToObjectSpace(ctx.body.Position);local before=lastLocal;lastLocal=now
  if not before or (before.Z<0)==(now.Z<0) then return false end
  local t=before.Z/(before.Z-now.Z);local cross=before:Lerp(now,t)
  return Vector2.new(cross.X,cross.Y).Magnitude<=HOOP_RADIUS
 end
 ctx.nearestBolt=function(position)
  bolts=bolts or workspace:FindFirstChild("SpeedPickups");if not bolts then return nil end
  local best,distance=nil,math.huge;local now=workspace:GetServerTimeNow()
  for _,bolt in bolts:GetChildren() do
   if bolt:IsA("BasePart") and (bolt:GetAttribute("ReadyAt") or 0)<=now then local d=(bolt.Position-position).Magnitude;if d<distance then best,distance=bolt,d end end
  end
  return best
 end

 local stepStarted,doneAt,holdK,relaunchAsked=0,nil,nil,0
 local function startStep(index)
  Tutorial.index=index;ctx.data={};stepStarted=os.clock();doneAt=nil;tick.Visible=false;Tutorial.gotIt=false;Tutorial.skipStep=false
  clearHoop()
  local step=Tutorial.lesson.steps[index]
  if step and step.enter then step.enter(ctx) end
 end
 local function finish(skipped)
  Tutorial.active=false;Root:SetAttribute("TutorialOpen",false);clearHoop();note.Visible=false
  Audio.play("finish")
  cardTitle.Text=skipped and "Lesson skipped" or (Tutorial.lesson.name.." done!")
  card.Visible=true
  -- Skipping mid-flight: the mouse steers the plane, so go straight on to the match and keep the card up a moment.
  if skipped and ctx.state and ctx.state~="DESK" then Root.RoundAction:FireServer("practiceDone");task.delay(5,function()card.Visible=false end) end
 end
 Input.InputBegan:Connect(function(input,processed)
  if processed or not Tutorial.active then return end
  if input.KeyCode==Enum.KeyCode.Space then Tutorial.gotIt=true
  elseif input.KeyCode==Enum.KeyCode.K then holdK=os.clock() end
 end)
 Input.InputEnded:Connect(function(input)
  if input.KeyCode==Enum.KeyCode.K and holdK then
   if os.clock()-holdK<HOLD_SKIP_SECONDS and Tutorial.active then Tutorial.skipStep=true end
   holdK=nil
  end
 end)

 -- The tutorial's own room (a new player's first join, or a replay) starts Flight School by itself, once.
 local function autoStart()
  if Root:GetAttribute("TutorialRoom") and not Tutorial.autoStarted then Tutorial.autoStarted=true;task.delay(1,Tutorial.begin) end
 end
 Root:GetAttributeChangedSignal("TutorialRoom"):Connect(autoStart);autoStart()

 RunService.RenderStepped:Connect(function(dt)
  marked,spotNames,pulseName=nil,nil,nil
  if not Tutorial.active then note.Visible=false;drawMarker();drawSpot(false);for _,pane in panes do pane.Visible=false end;return end
  if Tutorial.index==0 then startStep(1) end
  local plane=getPlane()
  if not plane or not plane.Parent or not plane:GetAttribute("Practice") then plane=nil end
  ctx.plane=plane;ctx.body=plane and plane:FindFirstChild("Root");ctx.state=plane and plane:GetAttribute("State");ctx.dt=dt
  -- The server refuses practice until the classroom and the save have loaded: keep asking.
  if not plane and os.clock()-Tutorial.askedAt>4 then Tutorial.askedAt=os.clock();Root.RoundAction:FireServer("practice") end
  local step=Tutorial.lesson.steps[Tutorial.index]
  if not step then finish(false);return end
  if ctx.state=="FLYING" then ctx.data.flew=true end
  -- Back at the desk after a crash: fly again by yourself (only the launch and landing steps wait for you).
  if ctx.state=="DESK" and Tutorial.index>1 and not step.land and not step.gotIt and os.clock()-relaunchAsked>2 then relaunchAsked=os.clock();Root.FlightAction:FireServer("launch") end
  note.Visible=not Root:GetAttribute("OverlayOpen")
  title.Text=string.format("%s  ·  step %d of %d",Tutorial.lesson.name,Tutorial.index,#Tutorial.lesson.steps)
  local result=plane and step.update(ctx) or false
  local count=step.count
  local finished=count and type(result)=="number" and result>=count or result==true or (step.gotIt and Tutorial.gotIt)
  text.Text=step.text..(count and type(result)=="number" and string.format("  %d/%d",math.min(result,count),count) or "")
  key.Text=step.key or "";key.Visible=step.key~=nil
  gotIt.Visible=step.gotIt==true
  local stuck=os.clock()-stepStarted>HINT_SECONDS and not doneAt
  hint.Text=stuck and step.hint and ("Tip: "..step.hint) or ""
  if stuck and marked then arrow.TextSize=56+math.abs(math.sin(os.clock()*4))*24 else arrow.TextSize=56 end
  skipFill.Size=UDim2.fromScale(holdK and math.min(1,(os.clock()-holdK)/HOLD_SKIP_SECONDS) or 0,1)
  if holdK and os.clock()-holdK>=HOLD_SKIP_SECONDS then holdK=nil;finish(true);return end
  drawMarker();drawSpot(spotNames~=nil)
  if finished and not doneAt then doneAt=os.clock();tick.Visible=true;ctx.ding() end
  if Tutorial.skipStep and not doneAt then doneAt=os.clock()-1 end
  if doneAt and os.clock()-doneAt>.8 then startStep(Tutorial.index+1) end
 end)
end
return Tutorial
