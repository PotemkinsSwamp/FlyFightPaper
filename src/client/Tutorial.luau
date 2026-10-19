-- The tutorial's step engine (docs/plan/TUTORIAL-PLAN.md): a goal note at the top with the key to press; one focus
-- look for every step ("Grabbing attention"): the screen dims round the one button, bar or 3D target, a 3D target
-- glows with its distance, and when it's off-screen a big arrow in front of the plane and a guide line point the
-- way. A tick and a ding for each finished step, a hint when stuck, and Skip (tap K: step, hold K: lesson). The
-- steps live in TutorialLessons.luau.
-- Lessons are practice: the server makes the plane nobody's enemy and pays nothing.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Art=require(Root.Shared.UIAssets)
local PaperUI=require(script.Parent.PaperUI)
local Audio=require(script.Parent.Audio)
local Lessons=require(script.Parent.TutorialLessons)
local Tutorial={active=false}
local HINT_SECONDS=10
local HOLD_SKIP_SECONDS=1.5
local HOOP_RADIUS=30
local POINTER_STUDS=16 -- the pointer arrow's width
local POINTER_AHEAD=30 -- how far in front of the plane it floats
local MIN_HOLE_PIXELS=70 -- half the dim hole's size for a far-away target
local PULSE_FIRST_SECONDS=3
local GUI_DIM,WORLD_DIM=.22,.4 -- how see-through the dim is (lighter while flying: you still need to see the room)
local YELLOW=Color3.fromRGB(255,225,70)

function Tutorial.begin(lesson)
 Tutorial.lesson=Lessons[lesson or "flight"];Tutorial.index=0;Tutorial.active=true;Tutorial.askedAt=os.clock()
 Root:SetAttribute("TutorialOpen",true)
 Root.RoundAction:FireServer("practice")
end

function Tutorial.start(getPlane)
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui");gui.Name="Tutorial";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=20;gui.Parent=player.PlayerGui

 -- Spotlight: the whole screen dims except a hole on the target. The dim is one frame the size of the hole with a
 -- screen-wide outline, so the hole can be round (hoops) or a rounded box (buttons). Pulse: the frame only.
 local hole=Instance.new("Frame");hole.Name="Dim";hole.BackgroundTransparency=1;hole.Visible=false;hole.Parent=gui
 local holeCorner=Instance.new("UICorner");holeCorner.Parent=hole
 local dimStroke=Instance.new("UIStroke");dimStroke.Color=Color3.new(0,0,0);dimStroke.Thickness=4000;dimStroke.Parent=hole
 -- The frame: a thick crayon-yellow border with a soft white glow inside, and a big arrow bouncing above it.
 local frame=Instance.new("Frame");frame.BackgroundColor3=YELLOW;frame.BackgroundTransparency=.85;frame.Visible=false;frame.Parent=gui
 local stroke=Instance.new("UIStroke");stroke.Color=YELLOW;stroke.Thickness=8;stroke.Parent=frame
 local frameCorner=Instance.new("UICorner");frameCorner.Parent=frame
 local glow=Instance.new("Frame");glow.BackgroundTransparency=1;glow.Size=UDim2.new(1,-10,1,-10);glow.Position=UDim2.fromOffset(5,5);glow.Parent=frame
 local glowStroke=Instance.new("UIStroke");glowStroke.Color=Color3.new(1,1,1);glowStroke.Thickness=3;glowStroke.Parent=glow
 local glowCorner=Instance.new("UICorner");glowCorner.Parent=glow
 -- Arrows are the HUD's crayon arrow picture (it points right; turned to point down). The font has no arrow signs.
 local function crayonArrow(parent,name,size,rotation)
  local image=Instance.new("ImageLabel");image.Name=name;image.Image=Art.hud.arrow;image.ImageColor3=YELLOW;image.BackgroundTransparency=1
  image.ScaleType=Enum.ScaleType.Fit;image.AnchorPoint=Vector2.new(.5,.5);image.Size=UDim2.fromOffset(size,size);image.Rotation=rotation;image.Visible=false;image.Parent=parent
  return image
 end
 local pointer=crayonArrow(gui,"SpotArrow",110,90)

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
 local tick=PaperUI.words(note,"Tick","Done!",470,112,130,50,38);tick.TextColor3=Color3.fromRGB(40,150,60);tick.Visible=false
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

 -- Markers: a label with the distance and a bouncing arrow over the thing to fly to (drawn on top of everything).
 local anchor=Instance.new("Part");anchor.Name="TutorialAnchor";anchor.Anchored,anchor.CanCollide,anchor.CanQuery,anchor.CanTouch,anchor.Transparency=true,false,false,false,1;anchor.Size=Vector3.one
 local board=Instance.new("BillboardGui");board.Name="TutorialMarker";board.AlwaysOnTop=true;board.Size=UDim2.fromOffset(220,110);board.LightInfluence=0;board.Adornee=anchor;board.Enabled=false
 board.Parent=player.PlayerGui -- billboards do not draw inside a ScreenGui
 local label=PaperUI.words(board,"Text","",0,0,220,40,26);label.Size=UDim2.new(1,0,0,40);label.TextXAlignment=Enum.TextXAlignment.Center;label.TextColor3=YELLOW
 local outline=Instance.new("UIStroke");outline.Thickness=2;outline.Parent=label
 local arrow=crayonArrow(board,"Arrow",64,90);arrow.Position=UDim2.new(.5,0,0,74);arrow.Visible=true
 -- The target glows through walls.
 local glowOutline=Instance.new("Highlight");glowOutline.Name="TutorialGlow";glowOutline.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
 glowOutline.OutlineColor=YELLOW;glowOutline.FillColor=YELLOW;glowOutline.FillTransparency=.75;glowOutline.Enabled=false;glowOutline.Parent=player.PlayerGui
 -- Off-screen: a big arrow floating in front of the plane turns to point the way (like racing games), and a
 -- glowing guide line runs from the plane to the target. The arrow is the crayon picture on a card, drawn on top.
 local pointCard=Instance.new("Part");pointCard.Name="TutorialPointer";pointCard.Anchored,pointCard.CanCollide,pointCard.CanQuery,pointCard.CanTouch,pointCard.Transparency=true,false,false,false,1
 pointCard.Size=Vector3.new(POINTER_STUDS,POINTER_STUDS*.6,.2)
 local pointFace=Instance.new("SurfaceGui");pointFace.Face=Enum.NormalId.Back;pointFace.AlwaysOnTop=true;pointFace.LightInfluence=0;pointFace.PixelsPerStud=20;pointFace.Adornee=pointCard;pointFace.Parent=player.PlayerGui
 local pointImage=Instance.new("ImageLabel");pointImage.Image=Art.hud.arrow;pointImage.ImageColor3=YELLOW;pointImage.BackgroundTransparency=1;pointImage.ScaleType=Enum.ScaleType.Fit;pointImage.Size=UDim2.fromScale(1,1);pointImage.Parent=pointFace
 local lineStart,lineEnd=Instance.new("Attachment"),Instance.new("Attachment");lineEnd.Parent=workspace.Terrain
 local guide=Instance.new("Beam");guide.Name="TutorialGuide";guide.Attachment0,guide.Attachment1=lineStart,lineEnd;guide.FaceCamera=true;guide.Width0,guide.Width1=1.6,1.6
 guide.Color=ColorSequence.new(YELLOW);guide.LightEmission=1;guide.LightInfluence=0;guide.Transparency=NumberSequence.new(.25,.6);guide.Enabled=false;guide.Parent=workspace.Terrain

 -- Hoops: a fixed course in clear air ahead of the Training Room desk (DeskSouth3), checked by hand in Studio so
 -- none sits in a building (each has 50 studs of empty air round it and the legs between them are clear). All
 -- hoops show at once so the next one is already in view; the one to fly through now is bright, the rest pale.
 -- ponytail: world points for the tutorial room's desk only; another desk still gets the same hoops.
 local COURSE={Vector3.new(-225,205,440),Vector3.new(-300,235,280),Vector3.new(-410,265,110)}
 local hoops,lastLocal={},nil
 local function paint(model,now)
  for _,piece in model:GetChildren() do piece.Transparency=now and 0 or .55 end
 end
 local function clearHoop()
  local done=table.remove(hoops,1);if done then done.model:Destroy() end;lastLocal=nil
  if hoops[1] then paint(hoops[1].model,true) end
 end
 local function clearCourse() for _,h in hoops do h.model:Destroy() end;table.clear(hoops);lastLocal=nil end
 local function placeCourse(from)
  for i=from,#COURSE do
   local at=COURSE[i];local ahead=COURSE[i+1] or at+(at-COURSE[i-1])
   local spot=CFrame.lookAt(at,ahead)
   local model=Instance.new("Model");model.Name="TutorialHoop"
   for k=1,20 do
    local a=k/20*math.pi*2
    local piece=Instance.new("Part");piece.Anchored,piece.CanCollide,piece.CanQuery,piece.CanTouch=true,false,false,false
    piece.Size=Vector3.new(4,10,3);piece.Material=Enum.Material.SmoothPlastic;piece.Color=k%2==0 and Color3.fromRGB(255,190,60) or Color3.fromRGB(255,120,80)
    piece.CFrame=spot*CFrame.Angles(0,0,a)*CFrame.new(0,HOOP_RADIUS,0);piece.Parent=model
   end
   paint(model,i==from);model.Parent=workspace
   table.insert(hoops,{cframe=spot,model=model})
  end
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
 -- When a step is done the spotlight fades out at once (Alan: it lingered after LAUNCH was clicked).
 -- `dim` is how dark the rest of the screen gets (nil = no dim, just the frame); `round` makes the hole a circle.
 local spotAlpha,last=0,nil
 local function drawSpot(low,high,dim,round,dt)
  if low then spotAlpha,last=1,{low,high,dim,round}
  elseif spotAlpha>0 then spotAlpha=math.max(0,spotAlpha-dt/.25);if spotAlpha>0 then low,high,dim,round=table.unpack(last) end end
  local fade=function(t) return 1-(1-t)*spotAlpha end
  frame.Visible=low~=nil;pointer.Visible=low~=nil;hole.Visible=dim~=nil and low~=nil
  if not low then return end
  -- Flash in and out to catch the eye: the border breathes, the dim deepens and lifts, the arrow bounces.
  local beat=(math.sin(os.clock()*5)+1)/2
  local grow=6+beat*8
  low-=Vector2.new(grow,grow);high+=Vector2.new(grow,grow)
  local corner=round and UDim.new(.5,0) or UDim.new(0,14)
  frameCorner.CornerRadius,glowCorner.CornerRadius,holeCorner.CornerRadius=corner,corner,corner
  frame.Position=UDim2.fromOffset(low.X,low.Y);frame.Size=UDim2.fromOffset(high.X-low.X,high.Y-low.Y)
  hole.Position,hole.Size=frame.Position,frame.Size
  stroke.Transparency=fade(beat*.35);glowStroke.Transparency=fade(.2+beat*.5);frame.BackgroundTransparency=fade(.8+beat*.15)
  pointer.Position=UDim2.fromOffset((low.X+high.X)/2,low.Y-55-beat*18);pointer.ImageTransparency=fade(0)
  if dim then dimStroke.Transparency=fade(dim+beat*.18) end
 end

 -- A 3D target: its glow, the label with the distance, the dim hole round it when it's on screen, and the pointer
 -- arrow and guide line when it isn't. Returns the hole's box (in this layer's pixels) or nil.
 local marked=nil
 local function drawMarker(body)
  board.Enabled=marked~=nil
  glowOutline.Adornee=marked and marked.instance;glowOutline.Enabled=marked~=nil and marked.instance~=nil
  guide.Enabled=false;pointCard.Parent=nil
  if not marked then anchor.Parent=nil;return end
  local camera=workspace.CurrentCamera
  local distance=body and math.floor((marked.position-body.Position).Magnitude) or 0
  anchor.Position=marked.position+Vector3.new(0,marked.radius+14+math.sin(os.clock()*5)*3,0);anchor.Parent=workspace
  label.Text=string.format("%s  %d",marked.text,distance)
  local point,onScreen=camera:WorldToViewportPoint(marked.position)
  local view=camera.ViewportSize
  local inView=onScreen and point.X>view.X*.1 and point.X<view.X*.9 and point.Y>view.Y*.1 and point.Y<view.Y*.9
  if not inView and body then
   -- The card faces the camera as far as it can while its arrow (pointing right in the picture) lies along the way to go.
   local at=body.Position+camera.CFrame.LookVector*POINTER_AHEAD+camera.CFrame.UpVector*6
   local way=(marked.position-at).Unit;local toCamera=(camera.CFrame.Position-at).Unit
   local facing=toCamera-way*toCamera:Dot(way);if facing.Magnitude<.05 then facing=camera.CFrame.UpVector end
   facing=facing.Unit
   pointCard.CFrame=CFrame.fromMatrix(at,way,facing:Cross(way),facing);pointCard.Parent=workspace
   pointImage.ImageTransparency=.1-math.sin(os.clock()*6)*.1
   lineStart.Parent=body;lineEnd.WorldPosition=marked.position;guide.Enabled=true
  end
  if not onScreen then return end
  -- Hole size: the target's radius seen from here, never smaller than a thumb.
  local across=marked.radius*view.Y/(2*point.Z*math.tan(math.rad(camera.FieldOfView)/2))
  local half=math.max(MIN_HOLE_PIXELS,across)
  local center=Vector2.new(point.X,point.Y) -- viewport pixels = this layer's pixels (it ignores the top bar)
  return center-Vector2.new(half,half),center+Vector2.new(half,half)
 end

 local bolts=workspace:FindFirstChild("SpeedPickups")
 local ctx={data={},dt=0}
 -- marker(where, words, how big round it is, the thing to make glow)
 ctx.marker=function(position,words,radius,instance) marked={position=position,text=words,radius=radius or 20,instance=instance} end
 local clicked,hooked={},{}
 ctx.spotlight=function(...)
  spotNames={...}
  for _,name in spotNames do
   local item=findGui(name)
   if item and item:IsA("GuiButton") and not hooked[item] then hooked[item]=true;item.Activated:Connect(function() clicked[name]=true end) end
  end
 end
 ctx.clicked=function(name) return clicked[name]==true end
 ctx.pulse=function(name) pulseName=name end
 ctx.ding=function() Audio.play("purchase") end
 -- The hoop to fly through now (the course is laid out the first time): its CFrame and its model.
 ctx.hoop=function() if not hoops[1] then placeCourse(1) end;return hoops[1].cframe,hoops[1].model end
 ctx.clearHoop=clearHoop
 ctx.passedHoop=function()
  if not hoops[1] or not ctx.body then return false end
  local now=hoops[1].cframe:PointToObjectSpace(ctx.body.Position);local before=lastLocal;lastLocal=now
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
  Tutorial.index=index;ctx.data={};table.clear(clicked);stepStarted=os.clock();doneAt=nil;tick.Visible=false;Tutorial.gotIt=false;Tutorial.skipStep=false
  clearCourse()
  local step=Tutorial.lesson.steps[index]
  if step and step.enter then step.enter(ctx) end
 end
 local function finish(skipped)
  Tutorial.active=false;Root:SetAttribute("TutorialOpen",false);clearCourse();note.Visible=false
  Audio.play("finish")
  cardTitle.Text=skipped and "Lesson skipped" or (Tutorial.lesson.name.." done!")
  card.Visible=true
  -- Skipping mid-flight: the mouse steers the plane, so go straight on to the match and keep the card up a moment.
  if skipped and ctx.state and ctx.state~="DESK" then Root.RoundAction:FireServer("practiceDone");task.delay(5,function()card.Visible=false end) end
 end
 Input.InputBegan:Connect(function(input,processed)
  if processed or not Tutorial.active then return end
  if input.KeyCode==Enum.KeyCode.Space then Tutorial.gotIt=true
  elseif input.KeyCode==Enum.KeyCode.Return then clicked.Launch=true
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
  if Root:GetAttribute("TutorialRoom") and not Tutorial.autoStarted and not Tutorial.active then Tutorial.autoStarted=true;task.delay(1,Tutorial.begin) end
 end
 Root:GetAttributeChangedSignal("TutorialRoom"):Connect(autoStart);autoStart()

 RunService.RenderStepped:Connect(function(dt)
  marked,spotNames,pulseName=nil,nil,nil
  if not Tutorial.active then note.Visible=false;drawMarker();drawSpot(nil,nil,nil,false,dt);return end
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
  title.Text=string.format("%s  -  step %d of %d",Tutorial.lesson.name,Tutorial.index,#Tutorial.lesson.steps)
  local result=plane and step.update(ctx) or false
  local count=step.count
  local finished=count and type(result)=="number" and result>=count or result==true or (step.gotIt and Tutorial.gotIt)
  text.Text=step.text..(count and type(result)=="number" and string.format("  %d/%d",math.min(result,count),count) or "")
  key.Text=step.key or "";key.Visible=step.key~=nil
  gotIt.Visible=step.gotIt==true
  local stuck=os.clock()-stepStarted>HINT_SECONDS and not doneAt
  hint.Text=stuck and step.hint and ("Tip: "..step.hint) or ""
  local swell=stuck and marked and math.abs(math.sin(os.clock()*4))*30 or 0
  arrow.Size=UDim2.fromOffset(64+swell,64+swell)
  skipFill.Size=UDim2.fromScale(holdK and math.min(1,(os.clock()-holdK)/HOLD_SKIP_SECONDS) or 0,1)
  if holdK and os.clock()-holdK>=HOLD_SKIP_SECONDS then holdK=nil;finish(true);return end
  if finished and not doneAt then doneAt=os.clock();tick.Visible=true;ctx.ding() end
  if doneAt then spotNames,pulseName,marked=nil,nil,nil end
  -- One focus look for everything: a button or bar (spotlight dims, pulse doesn't) or the 3D target.
  -- A bar pulse and a 3D target in one step (Lift bar + fan): the bar first, then the target.
  local low,high=drawMarker(ctx.body)
  if low and pulseName and os.clock()-stepStarted>PULSE_FIRST_SECONDS then pulseName=nil end
  local names=spotNames or (pulseName and {pulseName})
  if names then low,high=box(names);drawSpot(low,high,spotNames and GUI_DIM or nil,false,dt)
  else drawSpot(low,high,low and WORLD_DIM or nil,true,dt) end
  if Tutorial.skipStep and not doneAt then doneAt=os.clock()-1 end
  if doneAt and os.clock()-doneAt>.8 then startStep(Tutorial.index+1) end
 end)
end
return Tutorial
