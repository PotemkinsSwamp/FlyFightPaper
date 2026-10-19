-- The tutorial's step engine (docs/plan/TUTORIAL-PLAN.md): a goal note at the top with the key to press; one focus
-- look for every step ("Grabbing attention"): the screen dims round the one button, bar or 3D target, a 3D target
-- glows with its distance, a bold guide line leads to it along a path you can fly, and a small arrow by the aim
-- circle shows which way to turn when you're flying the wrong way. A tick and a ding for each finished step, a hint
-- when stuck, and Skip (tap K: step, hold K: lesson). The steps live in TutorialLessons.luau.
-- Lessons are practice: the server makes the plane nobody's enemy and pays nothing.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Art=require(Root.Shared.UIAssets)
local Gameplay=require(Root.Generated.Gameplay)
local PaperUI=require(script.Parent.PaperUI)
local Audio=require(script.Parent.Audio)
local Lessons=require(script.Parent.TutorialLessons)
local Course=require(Root.Shared.TrainingCourse)
local Tutorial={active=false}
local HINT_SECONDS=10
local HOLD_SKIP_SECONDS=1.5
local HOOP_RADIUS=30
local HOOP_PIECES=24
local WRONG_WAY_DEGREES=75 -- the turn arrow shows when the way to go is more than this far off the plane's nose
local TURN_ARROW_REACH=170 -- how far from the middle of the screen it sits, on the side to turn to
local MIN_HOLE_PIXELS=70 -- half the dim hole's size for a far-away target
local MAX_HOLE_SHARE=.28 -- and at most this share of the screen's height for a close one
local ROUTE_SECONDS=1 -- how often the guide line re-plans its path (often enough to follow you, not so often it jumps)
local LINE_STEP_STUDS=20 -- the line is smoothed into pieces about this long
local LINE_PIECES=48 -- at most this many pieces
local LINE_WIDTH=4.5 -- studs; bold enough to see from the chase camera (Alan)
local LINE_HIDE_STUDS=40 -- the guide line goes away this close to the target
local DASH_SPEED=1.5 -- how fast the line's dashes crawl toward the target
local BURST_ANGLES={-150,180,150,-30,0,30} -- the "look here" marks: three each side, like the concept
local FRAME_SLICE=Rect.new(64,64,448,192) -- frame-box.png (512x256): corners stay, sides stretch
local FRAME_OUTSET=30 -- pixels a box frame sits outside its target: its crayon band (40 px art x .6 slice scale) clears the content
local TAG_SLICE=Rect.new(96,40,416,120) -- tag.png (512x160)
local STEP_DING_DELAY=.4
local GUI_DIM,WORLD_DIM=.22,.4 -- how see-through the dim is (lighter while flying: you still need to see the room)
local YELLOW=Color3.fromRGB(255,225,70)
local SOFT_SLICE,SOFT_SEE_THROUGH=.2,.5 -- the soft frame: a third as thick as the usual one, half see-through
local CRASH_TIP_AFTER=3 -- crashes on one step before the note suggests open air
-- How long each step's note holds the world still before it moves on its own (Alan 2026-10-19: 2.5 s, a draining bar,
-- no countdown); a look step's longer note gets 5.
local READ_SECONDS,LOOK_SECONDS=2.5,5

function Tutorial.begin(lesson)
 if Tutorial.closeAsk then Tutorial.closeAsk() end -- a lesson starting closes the welcome question (found in Play)
 if Tutorial.active and Tutorial.close then Tutorial.close() end -- switching lessons: the old one's targets, Pal and slow motion go first
 Tutorial.lessonKey=Lessons[lesson] and lesson or "flight";Tutorial.lesson=Lessons[Tutorial.lessonKey];Tutorial.index=0;Tutorial.active=true;Tutorial.askedAt=os.clock()
 Root:SetAttribute("TutorialLesson",Tutorial.lessonKey);Root:SetAttribute("TutorialOpen",true) -- lesson first: its song is picked when TutorialOpen changes
 Root.RoundAction:FireServer("practice",Tutorial.lessonKey)
end

function Tutorial.start(getPlane)
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui");gui.Name="Tutorial";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=20;gui.Parent=player.PlayerGui

 -- Spotlight: the whole screen dims except a hole on the target. The dim is one frame the size of the hole with a
 -- screen-wide outline, so the hole can be round (hoops) or a rounded box (buttons). Pulse: the frame only.
 local hole=Instance.new("Frame");hole.Name="Dim";hole.BackgroundTransparency=1;hole.Visible=false;hole.Parent=gui
 local holeCorner=Instance.new("UICorner");holeCorner.Parent=hole
 local dimStroke=Instance.new("UIStroke");dimStroke.Color=Color3.new(0,0,0);dimStroke.Thickness=4000;dimStroke.Parent=hole
 -- The frame (Alan's approved concept, assets/references/ui-concepts/attention-*.png): a crayon outline that
 -- stretches to any button (9-slice) or a crayon ring round a 3D target, crayon "look here" marks that pulse out
 -- round it, and for a 3D target a taped tag under it with what to do and how far.
 local Pieces=Art.tutorial
 local frame=Instance.new("ImageLabel");frame.Name="Frame";frame.BackgroundTransparency=1;frame.SliceCenter=FRAME_SLICE;frame.SliceScale=.6;frame.Visible=false;frame.Parent=gui
 local bursts={}
 for i,angle in BURST_ANGLES do
  local mark=Instance.new("ImageLabel");mark.Name="Burst";mark.Image=Pieces.burst;mark.BackgroundTransparency=1;mark.AnchorPoint=Vector2.new(.5,.5)
  mark.Size=UDim2.fromOffset(60,22);mark.Rotation=angle;mark.Visible=false;mark.Parent=gui;bursts[i]=mark
 end
 local tag=Instance.new("ImageLabel");tag.Name="Tag";tag.Image=Pieces.tag;tag.ScaleType=Enum.ScaleType.Slice;tag.SliceCenter=TAG_SLICE;tag.SliceScale=.45
 tag.BackgroundTransparency=1;tag.AnchorPoint=Vector2.new(.5,0);tag.Size=UDim2.fromOffset(300,76);tag.Visible=false;tag.Parent=gui
 local barFrame=frame:Clone();barFrame.Name="BarFrame";barFrame.Image=Pieces.frameBox;barFrame.ScaleType=Enum.ScaleType.Slice;barFrame.Parent=gui
 -- A 3D target's ring while the spotlight is on a bar (Lift bar + fan): no dim of its own, just the ring and tag.
 local targetRing=frame:Clone();targetRing.Name="TargetRing";targetRing.Image=Pieces.frameRing;targetRing.ScaleType=Enum.ScaleType.Stretch;targetRing.Parent=gui
 local tagText=PaperUI.words(tag,"Text","",0,0,300,76,36);tagText.Size=UDim2.fromScale(1,1);tagText.TextXAlignment=Enum.TextXAlignment.Center

 -- The goal note: sticky note near the top, lesson and step, the instruction, the key picture, the count.
 local note=Instance.new("ImageLabel");note.Name="Note";note.Image=Art.ingame.stickyNote;note.ScaleType=Enum.ScaleType.Stretch;note.BackgroundTransparency=1
 -- The note sits just under where a match's clock would be (Alan 2026-10-19: higher, so INCOMING fits under it).
 note.AnchorPoint=Vector2.new(.5,0);note.Position=UDim2.fromScale(.5,.05);note.Size=UDim2.fromOffset(620,230);note.Rotation=-1;note.Visible=false;note.Parent=gui -- just under the top strip, out of the middle of the view
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
 -- While the world is held for reading, a bar along the button drains to empty, then it lets go.
 local readBar=Instance.new("Frame");readBar.Name="ReadBar";readBar.BorderSizePixel=0;readBar.BackgroundColor3=Color3.fromRGB(35,35,35)
 readBar.BackgroundTransparency=.3;readBar.AnchorPoint=Vector2.new(0,1);readBar.Position=UDim2.new(0,8,1,-5);readBar.ZIndex=gotIt.ZIndex+2;readBar.Visible=false;readBar.Parent=gotIt
 local skip=PaperUI.button(note,"Skip",Art.mainmenu.strip.red,"Skip  [K]",330,176,250,48,-1,function() Tutorial.skipStep=true end,24)
 local skipFill=Instance.new("Frame");skipFill.BackgroundColor3=Color3.new(1,1,1);skipFill.BackgroundTransparency=.5;skipFill.BorderSizePixel=0;skipFill.Size=UDim2.fromScale(0,1);skipFill.Parent=skip

 -- A short card in the middle: lesson finished or skipped, and how to come back (Alan: always tell them).
 local card=Instance.new("ImageLabel");card.Image=Art.ingame.stickyNote;card.ScaleType=Enum.ScaleType.Stretch;card.BackgroundTransparency=1
 card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.45);card.Size=UDim2.fromOffset(620,260);card.Visible=false;card.Parent=gui
 local cardScale=scale:Clone();cardScale.Parent=card
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()cardScale.Scale=scale.Scale end)
 local cardTitle=PaperUI.words(card,"Title","",40,30,540,56,44);cardTitle.TextXAlignment=Enum.TextXAlignment.Center
 local cardText=PaperUI.words(card,"Text","You can replay any lesson: Menu > Tutorial.",40,96,540,60,26);cardText.TextWrapped=true;cardText.TextXAlignment=Enum.TextXAlignment.Center
 local matchButton=PaperUI.button(card,"Play",Art.mainmenu.strip.green or Art.mainmenu.strip.red,"Go to a match",160,170,300,60,-1,function()
  card.Visible=false;Root.RoundAction:FireServer("practiceDone")
 end,30)
 -- The lessons run in order (Flight School, Aiming, Combat Training): the next one is a click away.
 local nextButton=PaperUI.button(card,"Next",Art.mainmenu.strip.green or Art.mainmenu.strip.red,"Next lesson",320,170,280,60,1,function()
  card.Visible=false;if Tutorial.nextKey then Tutorial.begin(Tutorial.nextKey) end
 end,30)

 -- A question card (Alan 2026-10-19): which lesson (the Tutorial button), or, the first time in the game, would
 -- you like the tutorial (most games ask once, can be skipped in one click, and say where to find it again).
 local ask=card:Clone();ask.Name="Ask";ask.Parent=gui;ask.Visible=false
 for _,child in ask:GetChildren() do if child:IsA("GuiButton") then child:Destroy() end end
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()ask.UIScale.Scale=scale.Scale end)
 local choices={}
 local function choose(title,words,options)
  ask.Title.Text,ask.Text.Text=title,words
  for _,button in choices do button:Destroy() end;table.clear(choices)
  for i,option in options do
   local x=#options==1 and 160 or (i==1 and 20 or 320)
   table.insert(choices,PaperUI.button(ask,"Choice"..i,Art.mainmenu.strip[option[3] or "green"] or Art.mainmenu.strip.red,option[1],x,170,280,60,i==1 and -1 or 1,function() ask.Visible=false;option[2]() end,28))
  end
  local close=PaperUI.button(ask,"Close",Art.mainmenu.strip.red,"X",560,10,50,50,0,function() ask.Visible=false end,28)
  table.insert(choices,close)
  ask.Visible=true
 end
 Tutorial.closeAsk=function() ask.Visible=false end
 -- The Training board (the Tutorial button; Alan 2026-10-19, concept assets/references/ui-concepts/training-board-c.png):
 -- its own cork board floating over the game, the title on a taped sheet, each card a pinned sheet of coloured paper
 -- (name, line and doodle drawn on it) with a live Play strip under them (Replay, and a tick, once a lesson is finished:
 -- the tick is saved on the account). The Range is a card too but not a lesson (no tick). From a match, Play first
 -- says you'll leave it (the lesson runs on another server).
 local BoardArt=Art.trainingboard
 Tutorial.lessons={}
 Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile) if type(profile)=="table" and type(profile.lessons)=="table" then Tutorial.lessons=profile.lessons end end)
 -- Sheet positions measured from the concept (1920x1080 sheet).
 local CARDS={{key="flight",art="paperFlight",x=106,turn=-1},{key="combat",art="paperCombat",x=548,turn=1},
  {key="hangar",art="paperHangar",x=980,turn=-1.5},{key="range",art="paperRange",x=1414,turn=1.5}}
 local boardCover,boardSheet=PaperUI.screen(player.PlayerGui,"TrainingBoard",BoardArt.bg,.85)
 boardCover.BackgroundTransparency,boardCover.BackgroundColor3=.45,Color3.fromRGB(20,14,8) -- the game dims behind the board
 boardCover.Parent.DisplayOrder=15 -- above the menus, under the lesson's own cards (Leave this match?)
 local pieces={PaperUI.image(boardSheet,"Title",BoardArt.title,365,80,1170,290,0)}
 local boardBefore=nil
 table.insert(pieces,PaperUI.button(boardSheet,"Back",BoardArt.stripRed,"Back",1555,135,270,170,0,function() boardCover.Visible=false end,72))
 local cards={}
 local function go(key)
  boardCover.Visible=false
  if not Lessons[key] then -- ponytail: the Hangar Tour and the Range are being built (2026-10-19); this note goes when they land
   choose("Almost ready!","This one is being built right now. Try it again soon!",{{"OK",function() end}});return
  end
  local before=boardBefore
  local function start() if before then before() end;Tutorial.begin(key) end
  if player:GetAttribute("InMatch") and not Root:GetAttribute("TutorialRoom") then
   choose("Leave this match?","This runs in your own private room, so you'll leave this match. Your progress is saved.",
    {{"Go",start},{"Stay",function() end,"red"}})
  else start() end
 end
 for _,card in CARDS do
  local paper=PaperUI.image(boardSheet,"Card_"..card.key,BoardArt[card.art],card.x,378,420,600,card.turn);table.insert(pieces,paper)
  local tickMark=PaperUI.image(paper,"Tick",BoardArt.tick,297,332,110,100,-4);tickMark.Visible=false
  cards[card.key]={tick=tickMark,button=PaperUI.button(paper,"Play",BoardArt.stripGreen,"Play",38,443,355,115,0,function() go(card.key) end,80)}
 end
 PaperUI.popIn(boardCover,pieces)
 function Tutorial.choose(before)
  ask.Visible=false;boardBefore=before
  for key,card in cards do local done=Lessons[key]~=nil and Tutorial.lessons[key]==true;card.tick.Visible=done;card.button.Label.Text=done and "Replay" or "Play" end
  boardCover.Visible=true
 end
 local function offer()
  if not player:GetAttribute("OfferTutorial") or Tutorial.active then return end
  player:SetAttribute("OfferTutorial",nil)
  choose("Welcome, pilot!","Want a quick tutorial? Learn to fly and fight in about 5 minutes. (Later: Menu > Tutorial.)",
   {{"Yes, teach me!",function() Tutorial.begin("flight") end},{"No thanks",function() end,"red"}})
 end
 player:GetAttributeChangedSignal("OfferTutorial"):Connect(offer);task.defer(offer)

 -- Slow motion (the Aiming lesson, Alan 2026-10-19): the server slows the plane and targets; this screen shows it.
 -- Colours soften and cool, the music slows, a whoosh, and a crayon tag says so. Off again with a quick whoosh.
 local slowLook=Instance.new("ColorCorrectionEffect");slowLook.Name="TutorialSlowMo";slowLook.Enabled=false;slowLook.Parent=game:GetService("Lighting")
 local slowTag=Instance.new("ImageLabel");slowTag.Name="SlowTag";slowTag.Image=Art.tutorial.tag;slowTag.ScaleType=Enum.ScaleType.Slice;slowTag.SliceCenter=TAG_SLICE;slowTag.SliceScale=.45
 slowTag.BackgroundTransparency=1;slowTag.AnchorPoint=Vector2.new(1,0);slowTag.Position=UDim2.new(1,-30,0,110);slowTag.Size=UDim2.fromOffset(320,76);slowTag.Rotation=3;slowTag.Visible=false;slowTag.Parent=gui
 local slowWords=PaperUI.words(slowTag,"Text","SLOW MOTION",0,0,320,76,36);slowWords.Size=UDim2.fromScale(1,1);slowWords.TextXAlignment=Enum.TextXAlignment.Center
 local slowOn=false
 local function setSlow(on)
  if on==slowOn then return end
  slowOn=on;Audio.play(on and "slowDown" or "speedUp");Audio.slowMusic(on)
  slowLook.Enabled=true;slowTag.Visible=on
  game:GetService("TweenService"):Create(slowLook,TweenInfo.new(.6),{Saturation=on and -.45 or 0,Contrast=on and .08 or 0,TintColor=on and Color3.fromRGB(215,230,255) or Color3.new(1,1,1)}):Play()
 end
 -- The Aiming lesson's first target: a glowing star in clear air.
 local star=Instance.new("Part");star.Name="TutorialStar";star.Shape=Enum.PartType.Ball;star.Size=Vector3.one*12;star.Material=Enum.Material.Neon;star.Color=YELLOW
 star.Anchored,star.CanCollide,star.CanQuery,star.CanTouch,star.CastShadow=true,false,false,false,false

 -- The target glows through walls.
 local glowOutline=Instance.new("Highlight");glowOutline.Name="TutorialGlow";glowOutline.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
 glowOutline.OutlineColor=YELLOW;glowOutline.FillColor=YELLOW;glowOutline.FillTransparency=.75;glowOutline.Enabled=false;glowOutline.Parent=player.PlayerGui
 -- Flying the wrong way: a paper arrow by the aim circle points the way to turn (back if it's behind you).
 -- See-through and smaller than the line, which does the main pointing (Alan).
 local turnArrow=Instance.new("ImageLabel");turnArrow.Name="TurnArrow";turnArrow.Image=Pieces.arrow;turnArrow.BackgroundTransparency=1;turnArrow.ScaleType=Enum.ScaleType.Fit
 turnArrow.AnchorPoint=Vector2.new(.5,.5);turnArrow.Size=UDim2.fromOffset(130,82);turnArrow.Visible=false;turnArrow.Parent=gui
 -- The guide line: crayon dashes that crawl toward the target along a path you can really fly (the bots' air
 -- routes round the buildings when the straight way is blocked), so following it gets you there.
 local Routes=require(Root.Shared.AirRoutes)
 local routes=nil
 local function airRoutes()
  local room=workspace:FindFirstChild("Arena")
  if not routes and room then
   local cast=RaycastParams.new();cast.FilterType=Enum.RaycastFilterType.Include;cast.FilterDescendantsInstances={room};cast.RespectCanCollide=true
   local world=Gameplay.world
   routes=Routes.new({room=room,cast=cast,boundsSize=Vector3.new(world.width_studs,world.height_studs,world.depth_studs)})
  end
  return routes
 end
 local lineStart=Instance.new("Attachment");lineStart.Name="TutorialLine"
 local dots,lines={},{}
 local function lineTo(i)
  if not lines[i] then
   local dot=Instance.new("Attachment");dot.Parent=workspace.Terrain;dots[i]=dot
   local line=Instance.new("Beam");line.Name="TutorialGuide";line.Attachment0=i==1 and lineStart or dots[i-1];line.Attachment1=dot
   line.FaceCamera=true;line.Width0,line.Width1=LINE_WIDTH,LINE_WIDTH;line.Texture=Pieces.dash;line.TextureMode=Enum.TextureMode.Wrap;line.TextureLength=16
   line.TextureSpeed=DASH_SPEED;line.LightEmission=1;line.LightInfluence=0;line.Enabled=false;line.Parent=workspace.Terrain;lines[i]=line
  end
  return lines[i],dots[i]
 end
 local route,routeAt,routeFor={},0,nil

 -- Hoops: the Training Room's fixed course (TrainingCourse.luau, clear air checked by hand in Studio). All
 -- hoops show at once so the next one is already in view; the one to fly through now is bright, the rest pale.
 -- The last hoop sends you north with the west fan 90 degrees to your left and 450 studs of clear air ahead, so
 -- there's time to read the Lift note and turn (Alan: the old course aimed straight into the fan).
 local COURSE=Course.POINTS
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
   -- 24 pieces laid end to end round the circle (each a little longer than its share, so there are no gaps).
   for k=1,HOOP_PIECES do
    local a=k/HOOP_PIECES*math.pi*2
    local piece=Instance.new("Part");piece.Anchored,piece.CanCollide,piece.CanQuery,piece.CanTouch=true,false,false,false
    piece.Size=Vector3.new(2*math.pi*HOOP_RADIUS/HOOP_PIECES*1.08,3.5,3);piece.Material=Enum.Material.SmoothPlastic;piece.Color=k%2==0 and Color3.fromRGB(235,60,50) or Color3.fromRGB(250,248,240) -- red and white paper, like the concept
    piece.CFrame=spot*CFrame.Angles(0,0,a)*CFrame.new(0,HOOP_RADIUS,0);piece.Parent=model
   end
   paint(model,i==from);model.Parent=workspace
   table.insert(hoops,{cframe=spot,model=model})
  end
 end

 -- Spotlight on GUI pieces found by name anywhere on screen; pulse = a HUD bar's own frame, no dim.
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
    -- Paper buttons have see-through margins above and below the art: frame the paper, not the whole box. Their
    -- ends reach the sides, so only a sliver comes off there (Alan: the desk card's strips were cut off).
    local trim=item:IsA("ImageButton") and item.AbsoluteSize*Vector2.new(.02,.1) or Vector2.zero
    local a=item.AbsolutePosition-gui.AbsolutePosition+trim;local b=a+item.AbsoluteSize-trim*2
    low=low and Vector2.new(math.min(low.X,a.X),math.min(low.Y,a.Y)) or a
    high=high and Vector2.new(math.max(high.X,b.X),math.max(high.Y,b.Y)) or b
   end
  end
  return low,high
 end
 -- When a step is done the spotlight fades out at once (Alan: it lingered after LAUNCH was clicked).
 -- `dim` is how dark the rest of the screen gets (nil = no dim, just the frame); `round` makes the hole a circle;
 -- `words` puts the tag under it.
 local spotAlpha,last=0,nil
 local function placeTag(center,high,words,transparency)
  local clock=os.clock()
  tagText.Text=words;tag.Size=UDim2.fromOffset(math.max(240,#words*22+80),76);tag.Visible=true
  tag.Position=UDim2.fromOffset(center.X,high.Y+10+math.sin(clock*3)*4);tag.Rotation=-2+math.sin(clock*1.7)*1.5
  tag.ImageTransparency=transparency;tagText.TextTransparency=transparency
 end
 -- `soft`: a HUD piece you must still see through (the crosshair, Alan 2026-10-19: the bold frame hid it): a thin,
 -- see-through frame close round it, no dim and no marks.
 local function drawSpot(low,high,dim,round,words,dt,soft)
  if low then spotAlpha,last=1,{low,high,dim,round,words,soft}
  elseif spotAlpha>0 then spotAlpha=math.max(0,spotAlpha-dt/.25);if spotAlpha>0 then low,high,dim,round,words,soft=table.unpack(last) end end
  local fade=function(t) return 1-(1-t)*spotAlpha end
  frame.Visible=low~=nil;hole.Visible=dim~=nil and low~=nil;tag.Visible=low~=nil and words~=nil
  for _,mark in bursts do mark.Visible=low~=nil and not soft end
  if not low then return end
  -- Alive, to catch the eye: the frame breathes and wobbles, the marks pulse outward, the dim deepens and lifts.
  local clock=os.clock();local beat=(math.sin(clock*5)+1)/2
  -- A box frame stays fully outside what it frames even at its smallest (Alan: it covered the bar's words).
  local grow=soft and 10+beat*3 or (round and 6 or FRAME_OUTSET)+beat*8
  frame.SliceScale=soft and SOFT_SLICE or .6
  low-=Vector2.new(grow,grow);high+=Vector2.new(grow,grow)
  local center,half=(low+high)/2,(high-low)/2
  holeCorner.CornerRadius=round and UDim.new(.5,0) or UDim.new(0,14)
  frame.Image=round and Pieces.frameRing or Pieces.frameBox;frame.ScaleType=round and Enum.ScaleType.Stretch or Enum.ScaleType.Slice
  frame.Position=UDim2.fromOffset(low.X,low.Y);frame.Size=UDim2.fromOffset(high.X-low.X,high.Y-low.Y)
  frame.Rotation=round and math.sin(clock*2.3)*1.5 or 0;frame.ImageTransparency=fade(soft and SOFT_SEE_THROUGH or 0)
  hole.Position,hole.Size=frame.Position,frame.Size
  for i,mark in bursts do
   local angle=math.rad(BURST_ANGLES[i]);local out=24+beat*16
   local at=center+Vector2.new(math.cos(angle)*(half.X+out),math.sin(angle)*(half.Y+out))
   mark.Position=UDim2.fromOffset(at.X,at.Y);mark.ImageTransparency=fade(beat*.3)
  end
  if words then placeTag(center,high,words,fade(0)) end
  if dim then dimStroke.Transparency=fade(dim+beat*.18) end
 end

 -- A 3D target: its glow, the guide line along a flyable path, the dim hole and tag round it when it's on screen,
 -- and the big arrow when it isn't. Returns the hole's box (in this layer's pixels) and the tag's words, or nil.
 local marked=nil
 local function drawMarker(body)
  glowOutline.Adornee=marked and marked.instance;glowOutline.Enabled=marked~=nil and marked.instance~=nil
  turnArrow.Visible=false
  local shown=0
  if marked and body then
   -- Re-plan the path a few times a second (and at once for a new target).
   if routeFor~=marked.position or os.clock()-routeAt>ROUTE_SECONDS then
    routeFor,routeAt=marked.position,os.clock()
    local paths=airRoutes()
    route=(not paths or paths:clear(body.Position,marked.position,12)) and {marked.position} or paths:path(body.Position,marked.position,body.CFrame.LookVector)
    if route[#route]~=marked.position then table.insert(route,marked.position) end
   end
   if (marked.position-body.Position).Magnitude>LINE_HIDE_STUDS then
    -- A smooth curve (Catmull-Rom) through the plane and the path's turns, starting straight at the first turn.
    local points={body.Position};for _,point in route do table.insert(points,point) end
    lineStart.Parent=body
    for i=1,#points-1 do
     local p1,p2=points[i],points[i+1]
     local p0=points[i-1] or p1-(p2-p1)
     local p3=points[i+2] or p2+(p2-p1)
     for k=1,math.max(1,math.ceil((p2-p1).Magnitude/LINE_STEP_STUDS)) do
      if shown>=LINE_PIECES then break end
      local t=k/math.max(1,math.ceil((p2-p1).Magnitude/LINE_STEP_STUDS))
      local point=.5*((2*p1)+(p2-p0)*t+(2*p0-5*p1+4*p2-p3)*t*t+(3*p1-p0-3*p2+p3)*t*t*t)
      shown+=1;local line,dot=lineTo(shown);dot.WorldPosition=point;line.Enabled=true
     end
    end
   end
  end
  for i=shown+1,#lines do lines[i].Enabled=false end
  if not marked then return end
  local camera=workspace.CurrentCamera
  local distance=body and math.floor((marked.position-body.Position).Magnitude) or 0
  local point,onScreen=camera:WorldToViewportPoint(marked.position)
  local view=camera.ViewportSize
  local nextPoint=route[1] or marked.position
  if body and (nextPoint-body.Position).Unit:Dot(body.CFrame.LookVector)<math.cos(math.rad(WRONG_WAY_DEGREES)) then
   -- The way to go, seen from the camera, flattened onto the screen; straight behind = turn right.
   local way=camera.CFrame:VectorToObjectSpace((nextPoint-body.Position).Unit)
   local flat=Vector2.new(way.X,-way.Y);if flat.Magnitude<.15 then flat=Vector2.new(1,0) end
   flat=flat.Unit
   local at=view/2+flat*(TURN_ARROW_REACH+math.sin(os.clock()*5)*10)
   turnArrow.Position=UDim2.fromOffset(at.X,at.Y);turnArrow.Rotation=math.deg(math.atan2(flat.Y,flat.X));turnArrow.ImageTransparency=.3;turnArrow.Visible=true
  end
  if not onScreen then return end
  -- Hole size: the target's radius seen from here, never smaller than a thumb nor bigger than a big part of the screen.
  local across=marked.radius*view.Y/(2*point.Z*math.tan(math.rad(camera.FieldOfView)/2))
  local half=math.clamp(across,MIN_HOLE_PIXELS,view.Y*MAX_HOLE_SHARE)
  local center=Vector2.new(point.X,point.Y) -- viewport pixels = this layer's pixels (it ignores the top bar)
  return center-Vector2.new(half,half),center+Vector2.new(half,half),string.format("%s %d",marked.text,distance)
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
 local softSpot,softTag=false,nil
 ctx.softSpot=function(...) ctx.spotlight(...);softSpot=true end
 ctx.softTag=function(words) softTag=words end -- a tag under the soft frame ("AIM HERE")
 ctx.pulse=function(name) pulseName=name end
 local dingAt=0
 ctx.ding=function() dingAt=os.clock();Audio.play("ding") end
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
 -- The lesson's server side (RoundRuntime:lesson): targets, the Pal, slow motion, a repair.
 ctx.player=player
 ctx.lesson=function(cmd) if cmd.slow~=nil then setSlow(cmd.slow) end;Root.RoundAction:FireServer("lesson",cmd) end
 -- Practice target planes still in the air, nearest first.
 ctx.targets=function()
  local list={}
  for _,model in workspace.Planes:GetChildren() do
   local root=model:FindFirstChild("Root")
   if root and model:GetAttribute("DrillOf")==player.UserId and model:GetAttribute("State")=="FLYING" then table.insert(list,model) end
  end
  if ctx.body then table.sort(list,function(a,b) return (a.Root.Position-ctx.body.Position).Magnitude<(b.Root.Position-ctx.body.Position).Magnitude end) end
  return list
 end
 -- Counts the server keeps on the player (DrillDown, PalFolds, PalEraserMisses, EraserHits...).
 ctx.count=function(name) return player:GetAttribute(name) or 0 end
 ctx.pal=function()
  local model=workspace.Planes:FindFirstChild(player:GetAttribute("TutorialFoe") or "")
  return model and model:GetAttribute("State")=="FLYING" and model or nil
 end
 ctx.star=function(position) star.Position=position;star.Parent=workspace;return star end
 ctx.nearestBolt=function(position)
  bolts=bolts or workspace:FindFirstChild("SpeedPickups");if not bolts then return nil end
  local best,distance=nil,math.huge;local now=workspace:GetServerTimeNow()
  for _,bolt in bolts:GetChildren() do
   if bolt:IsA("BasePart") and (bolt:GetAttribute("ReadyAt") or 0)<=now then local d=(bolt.Position-position).Magnitude;if d<distance then best,distance=bolt,d end end
  end
  return best
 end

 local stepStarted,doneAt,holdK,relaunchAsked=0,nil,nil,0
 local crashedAt,crashes=nil,0
 -- Read, then act (Alan 2026-10-19: "it gives the player time to read and then act"): every step that starts in the
 -- air first holds the world still (RoundRuntime:lesson freeze) with its note up, until Go (Space). A "look" step
 -- (gotIt) is all reading: its Got it lets the world go and finishes it. `reading`: nil, "waiting" (not flying yet), true.
 -- It lets go by itself after READ_SECONDS with a countdown on the button (Alan: don't make them press anything);
 -- Space still goes early.
 local reading,readingAt=nil,0
 local function startStep(index)
  Tutorial.index=index;ctx.data={};table.clear(clicked);stepStarted=os.clock();doneAt=nil;tick.Visible=false;Tutorial.gotIt=false;Tutorial.skipStep=false
  clearCourse();star.Parent=nil;crashes=0;reading="waiting"
  if index==1 then airRoutes() end -- plan the room's air routes once, while the plane still sits on the desk
  local step=Tutorial.lesson.steps[index]
  if step and step.enter then step.enter(ctx) end
 end
 local function close()
  Tutorial.active=false;Root:SetAttribute("TutorialOpen",false);clearCourse();note.Visible=false;star.Parent=nil;reading=nil
  ctx.lesson({freeze=false,slow=false,drill=false,pal=false})
 end
 Tutorial.close=close
 -- Menu > Leave during a lesson: end it with no end card and back to the menu. (Only withdrawing the plane used to
 -- leave the lesson running, and it kept asking for a new plane: Alan 2026-10-19, "it keeps pulling me back".)
 function Tutorial.quit()
  if not Tutorial.active then return false end
  close();Root.RoundAction:FireServer("practiceDone","menu");return true
 end
 local function finish(skipped)
  close()
  Audio.play("finish")
  if not skipped then Tutorial.lessons[Tutorial.lessonKey]=true;Root.RoundAction:FireServer("lessonDone",Tutorial.lessonKey) end -- its tick on the Training board
  cardTitle.Text=skipped and "Lesson skipped" or Tutorial.lesson.doneTitle or (Tutorial.lesson.name.." done!")
  Tutorial.nextKey=Tutorial.lesson.next
  nextButton.Visible=Tutorial.nextKey~=nil;nextButton.Label.Text=Tutorial.nextKey and "Next: "..Lessons[Tutorial.nextKey].name or ""
  matchButton.Position=UDim2.fromOffset(Tutorial.nextKey and 170 or 310,200) -- buttons sit by their middle
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
  if Root:GetAttribute("TutorialRoom") and not Tutorial.autoStarted and not Tutorial.active then
   Tutorial.autoStarted=true;task.delay(1,function() Tutorial.begin(player:GetAttribute("StartLesson")) end)
  end
 end
 Root:GetAttributeChangedSignal("TutorialRoom"):Connect(autoStart);autoStart()
 -- Studio test hook: set DevLesson (flight, aim, combat) on ReplicatedStorage.FlyFightPaper to open that lesson.
 if RunService:IsStudio() then Root:GetAttributeChangedSignal("DevLesson"):Connect(function() Tutorial.begin(Root:GetAttribute("DevLesson")) end) end

 RunService.RenderStepped:Connect(function(dt)
  marked,spotNames,pulseName,softSpot,softTag=nil,nil,nil,false,nil
  -- A menu open over the lesson (Esc) is what the player is looking at: no dim, spotlight or note on top of it (Alan 2026-10-19).
  if not Tutorial.active or Root:GetAttribute("OverlayOpen") then note.Visible=false;barFrame.Visible=false;targetRing.Visible=false;drawMarker();drawSpot(nil,nil,nil,false,nil,dt);return end
  if Tutorial.index==0 then startStep(1) end
  local plane=getPlane()
  if not plane or not plane.Parent or not plane:GetAttribute("Practice") then plane=nil end
  ctx.plane=plane;ctx.body=plane and plane:FindFirstChild("Root");ctx.state=plane and plane:GetAttribute("State");ctx.dt=dt
  -- The server refuses practice until the classroom and the save have loaded: keep asking.
  if not plane and os.clock()-Tutorial.askedAt>4 then Tutorial.askedAt=os.clock();Root.RoundAction:FireServer("practice",Tutorial.lessonKey) end
  local step=Tutorial.lesson.steps[Tutorial.index]
  if not step then finish(false);return end
  if ctx.state=="FLYING" then ctx.data.flew=true end
  -- Back at the desk after a crash: fly again by yourself (only the launch and landing steps wait for you).
  if ctx.state=="DESK" and Tutorial.index>1 and not step.land and not step.gotIt and os.clock()-relaunchAsked>2 then relaunchAsked=os.clock();Root.FlightAction:FireServer("launch") end
  note.Visible=not Root:GetAttribute("OverlayOpen")
  title.Text=string.format("%s  -  step %d of %d",Tutorial.lesson.name,Tutorial.index,#Tutorial.lesson.steps)
  -- Folded mid-lesson (Combat Training keeps crashes): a kind word and a countdown, then the plane takes off by
  -- itself and the step carries on where it was (the server keeps the targets and holds the Pal's fire).
  if ctx.state=="DESTROYED" and not crashedAt then crashedAt=os.clock();crashes+=1 end
  if crashedAt and ctx.state=="FLYING" then crashedAt=nil end
  if crashedAt and not step.land then
   local left=math.ceil(Gameplay.combat.respawn_seconds-(os.clock()-crashedAt))
   text.Text=left>0 and string.format("Folded! Walls fold paper planes. Back in the air in %d...",left) or "Taking off again..."
   key.Visible,gotIt.Visible,tick.Visible=false,false,false
   hint.Text=crashes>=CRASH_TIP_AFTER and "Tip: fly higher, away from the buildings." or ""
   drawMarker();drawSpot(nil,nil,nil,false,nil,dt);barFrame.Visible=false;targetRing.Visible=false
   if ctx.state=="DESK" and os.clock()-relaunchAsked>1 then relaunchAsked=os.clock();Root.FlightAction:FireServer("launch") end
   return
  end
  -- The read pause starts the first moment this step is in the air; Go lets the world move again.
  if reading=="waiting" and ctx.state=="FLYING" then reading=true;readingAt=os.clock();Tutorial.gotIt=false;ctx.lesson({freeze=true}) end
  local readFor=step.gotIt and LOOK_SECONDS or READ_SECONDS
  if reading==true and os.clock()-readingAt>=readFor then Tutorial.gotIt=true end
  if reading=="waiting" and ctx.state~="FLYING" and ctx.state~="TAKEOFF" then reading=nil end -- starts at a desk: nothing to freeze
  if reading==true and Tutorial.gotIt then
   reading=nil;ctx.lesson({freeze=false});stepStarted=os.clock()
   if not step.gotIt then Tutorial.gotIt=false end
  end
  ctx.reading=reading==true
  local result=plane and step.update(ctx) or false
  if reading then result=step.count and 0 or false end -- nothing counts while frozen
  local count=step.count
  local finished=count and type(result)=="number" and result>=count or result==true or (step.gotIt and Tutorial.gotIt)
  -- A step's words can change with what's happening (a function of ctx), e.g. the eraser warnings.
  text.Text=(type(step.text)=="function" and step.text(ctx) or step.text)..(count and type(result)=="number" and string.format("  %d/%d",math.min(result,count),count) or "")
  key.Text=step.key or "";key.Visible=step.key~=nil
  gotIt.Visible=step.gotIt==true or reading==true
  gotIt.Label.Text=reading==true and not step.gotIt and "Go  [Space]" or "Got it  [Space]"
  local left=reading==true and math.clamp(1-(os.clock()-readingAt)/readFor,0,1) or 0
  readBar.Visible=left>0;readBar.Size=UDim2.new(left,-16*left,0,6)
  local stuck=os.clock()-stepStarted>HINT_SECONDS and not doneAt and not reading
  hint.Text=stuck and step.hint and ("Tip: "..step.hint) or crashes>=CRASH_TIP_AFTER and "Tip: fly higher, away from the buildings." or ""
  skipFill.Size=UDim2.fromScale(holdK and math.min(1,(os.clock()-holdK)/HOLD_SKIP_SECONDS) or 0,1)
  if holdK and os.clock()-holdK>=HOLD_SKIP_SECONDS then holdK=nil;finish(true);return end
  if finished and not doneAt then
   -- The step's ding comes a beat after (on LAUNCH it clashed with take-off), and only once if a hoop just dinged.
   doneAt=os.clock();tick.Visible=true
   if os.clock()-dingAt>.5 then task.delay(STEP_DING_DELAY,ctx.ding) end
  end
  if doneAt then spotNames,pulseName,marked=nil,nil,nil end
  -- One focus look for everything: a button (spotlight, dims the rest) or the 3D target. A HUD bar the step
  -- talks about (pulse) gets its own breathing frame the whole step, so it shows next to a 3D target (Lift + fan).
  local low,high,words=drawMarker(ctx.body)
  targetRing.Visible=spotNames~=nil and low~=nil
  if spotNames then
   local targetLow,targetHigh=low,high
   low,high=box(spotNames);drawSpot(low,high,not softSpot and (ctx.state=="FLYING" and WORLD_DIM or GUI_DIM) or nil,false,softSpot and softTag or nil,dt,softSpot)
   if targetLow then
    local grow=6+(math.sin(os.clock()*5)+1)*4
    targetRing.Position=UDim2.fromOffset(targetLow.X-grow,targetLow.Y-grow);targetRing.Size=UDim2.fromOffset(targetHigh.X-targetLow.X+grow*2,targetHigh.Y-targetLow.Y+grow*2)
    targetRing.Rotation=math.sin(os.clock()*2.3)*1.5;targetRing.ImageTransparency=0
    placeTag((targetLow+targetHigh)/2,targetHigh+Vector2.new(grow,grow),words,0)
   end
  else drawSpot(low,high,low and WORLD_DIM or nil,true,words,dt) end
  local barLow,barHigh=nil,nil;if pulseName then barLow,barHigh=box({pulseName}) end
  barFrame.Visible=barLow~=nil
  if barLow then
   local grow=FRAME_OUTSET+(math.sin(os.clock()*6)+1)*5
   barFrame.Position=UDim2.fromOffset(barLow.X-grow,barLow.Y-grow);barFrame.Size=UDim2.fromOffset(barHigh.X-barLow.X+grow*2,barHigh.Y-barLow.Y+grow*2)
   barFrame.Rotation=0;barFrame.ImageTransparency=0
  end
  if Tutorial.skipStep and not doneAt then doneAt=os.clock()-1 end
  if doneAt and os.clock()-doneAt>.8 then startStep(Tutorial.index+1) end
 end)
end
return Tutorial
