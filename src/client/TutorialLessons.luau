-- The lessons' steps (docs/plan/TUTORIAL-PLAN.md). Each step: what the note says, which key picture it shows, and
-- update(ctx), called every frame, which places markers / spotlights through ctx and returns true once the step is
-- done (or a count for "1/3" steps). The engine in Tutorial.luau draws the note, ticks, hints and skipping.
local Root=game.ReplicatedStorage.FlyFightPaper
local Gameplay=require(Root.Generated.Gameplay)
local Lessons={}

local function fans()
 local list={}
 for _,fan in Gameplay.world.fans do
  if fan.kind=="upward" then table.insert(list,{center=Vector3.new(fan.center[1],fan.center[2],fan.center[3]),half=Vector3.new(fan.halfsize[1],fan.halfsize[2],fan.halfsize[3])}) end
 end
 return list
end
local FANS=fans()
-- The fan's spinning blades glow (the floor fan is one model of many parts; the blades are one of them). Looked up
-- when needed: the classroom loads after this module.
local function blades(fan)
 if (fan.blades and fan.blades.Parent) or os.clock()-(fan.looked or -9)<2 then return fan.blades end
 fan.looked=os.clock()
 for _,part in workspace:GetDescendants() do
  if part.Name=="floor-fan-blades" and part:IsA("BasePart") and (Vector3.new(fan.center.X,part.Position.Y,fan.center.Z)-part.Position).Magnitude<fan.half.X then fan.blades=part;return part end
 end
end
local function nearestFan(position)
 local best,distance=nil,math.huge
 for _,fan in FANS do local d=(fan.center-position).Magnitude;if d<distance then best,distance=fan,d end end
 return best
end
local function inFan(position)
 for _,fan in FANS do
  local o=position-fan.center
  if math.abs(o.X)<=fan.half.X and math.abs(o.Y)<=fan.half.Y and math.abs(o.Z)<=fan.half.Z then return true end
 end
 return false
end

local function launch()
 return {text="Click LAUNCH to take off!",key="Enter",
  update=function(ctx)
   ctx.spotlight("Launch")
   return ctx.clicked("Launch") or (ctx.state~="DESK" and ctx.state~=nil)
  end}
end

-- Flight School's hoops and landing pull the plane's speed back (Alan 2026-10-29: so you can't just miss them); not
-- slow motion, which only the aiming steps use.
local HOOP_SLOW=.8
local LAND_SLOW=.5
-- Landing: your desk's approach ring (FlightService PracticeRing), where the plane is from it, and the desk's paper
-- ring that glows (DeskPieces' "landing-ring" parts; the one nearest the approach ring).
local LINE_UP=CFrame.new(0,10,-260)
local function approach(ctx)
 local ring=ctx.plane and ctx.plane:GetAttribute("PracticeRing")
 return ring,ring and ctx.body and ring:PointToObjectSpace(ctx.body.Position)
end
local function lined(rel) return rel~=nil and rel.Z<-80 and math.abs(rel.X)<30 and math.abs(rel.Y)<40 end
local function drifted(rel) return rel~=nil and (math.abs(rel.X)>80 or math.abs(rel.Y)>80 or rel.Z<-450) end
local function ringPart(ctx,ring)
 if ctx.data.ringPart==nil then
  ctx.data.ringPart=false
  for _,part in workspace:GetDescendants() do
   if part.Name=="landing-ring" and part:IsA("BasePart") and (part.Position-ring.Position).Magnitude<60 then ctx.data.ringPart=part;break end
  end
 end
 return ctx.data.ringPart or nil
end

-- Every note says what to do, where (by the colour of what's on screen), how many or how long, and which button
-- (Alan 2026-10-29: a 10-year-old must manage each step from its note alone; docs/systems/tutorial.md).
Lessons.flight={
 name="Flight School",next="combat",
 steps={
  launch(),
  {text="Move the mouse to steer. Follow the yellow line through 3 hoops.",key="Mouse",count=3,hint="Lost? The paper arrow by your circle points the way to turn.",
   enter=function(ctx) ctx.data.passed=0;ctx.lesson({slow=HOOP_SLOW}) end,
   update=function(ctx)
    if ctx.state~="FLYING" and ctx.state~="TAKEOFF" then return ctx.data.passed end
    local hoop,model=ctx.hoop()
    ctx.marker(hoop.Position,"FLY HERE",34,model)
    if ctx.passedHoop() then ctx.data.passed+=1;ctx.ding();ctx.clearHoop() end
    return ctx.data.passed
   end},
  {text="Your Lift bar goes down as you fly. Follow the yellow line to the fan, then fly up into its wind.",key=nil,hint="Fly into the glowing fan. Its wind fills your Lift.",
   enter=function(ctx) ctx.lesson({slow=false}) end,
   update=function(ctx)
    ctx.spotlight("LiftStrip") -- everything greyed out but the Lift bar (Alan); the line and glow show the fan
    local fan=ctx.body and nearestFan(ctx.body.Position)
    if fan then ctx.marker(fan.center,"FLY UP HERE",fan.half.X,blades(fan)) end
    return ctx.state=="FLYING" and ctx.body~=nil and inFan(ctx.body.Position)
   end},
  {text="Follow the yellow line to the spinning speed bolt. Fly right through it.",hint="Bolts spin inside the rings and tubes. Fly through the middle.",
   enter=function(ctx) ctx.data.before=ctx.plane and ctx.plane:GetAttribute("PickupUntil") or 0 end,
   update=function(ctx)
    local bolt=ctx.body and ctx.nearestBolt(ctx.body.Position)
    if bolt then ctx.marker(bolt.Position,"SPEED BOLT",14,bolt) end
    return ctx.plane~=nil and (ctx.plane:GetAttribute("PickupUntil") or 0)>ctx.data.before
   end},
  {text="Hold Shift for 1 second to boost.",key="Shift",
   enter=function(ctx) ctx.data.boosted=0 end,
   update=function(ctx)
    ctx.pulse("BoostStrip")
    if ctx.plane and ctx.plane:GetAttribute("Boosting") then ctx.data.boosted+=ctx.dt end
    return ctx.data.boosted>=1
   end},
  -- Landing in two steps (Alan 2026-10-29): line up first, then slowed down with the desk's ring glowing, fly in.
  {text="Time to land! Follow the yellow line to the LINE UP HERE sign in front of your desk.",hint="Fly to the sign, then turn so your desk is straight ahead.",land=true,
   update=function(ctx)
    local ring,rel=approach(ctx)
    if ring and ctx.state=="FLYING" then ctx.marker((ring*LINE_UP).Position,"LINE UP HERE",24) end
    return ctx.state=="FLYING" and lined(rel) or ctx.state=="DESK" and ctx.data.flew
   end},
  {text=function(ctx) return ctx.data.off and "Turn back: follow the yellow line to LINE UP HERE." or "Slowing you down... Now fly straight into the glowing circle at your desk!" end,
   hint="Missed it? Follow the line back to LINE UP HERE and try again.",land=true,
   enter=function(ctx) ctx.data.home=ctx.state=="DESK";ctx.lesson({slow=LAND_SLOW}) end,
   update=function(ctx)
    local ring,rel=approach(ctx)
    if ring and ctx.state=="FLYING" then
     -- Wandered off the approach: full speed and the line-up sign again until lined up once more.
     local off=ctx.data.off
     if off and lined(rel) then off=false elseif not off and drifted(rel) then off=true end
     if off~=ctx.data.off then ctx.data.off=off;ctx.lesson({slow=not off and LAND_SLOW or false}) end
     if off then ctx.marker((ring*LINE_UP).Position,"LINE UP HERE",24) else ctx.marker(ring.Position,"FLY IN HERE",24,ringPart(ctx,ring)) end
    end
    return ctx.state=="DESK" and (ctx.data.flew or ctx.data.home)
   end},
  {text="You landed! Click a glowing button. Refill Lift and Repair are free. Full refold: change your plane. Fresh plane: start over.",gotIt=true,
   enter=function(ctx) ctx.lesson({slow=false}) end,
   update=function(ctx)
    ctx.spotlight("Refill","Repair","Fresh","Refold")
    -- Using one ends the step too (Alan 2026-10-28: he tapped Repair and still had to press Got it).
    return ctx.clicked("Refill") or ctx.clicked("Repair") or ctx.clicked("Fresh") or ctx.clicked("Refold")
   end},
 },
}

-- Shared by the shooting steps: a marker on the nearest practice target, and the overheat tip (doesn't hold you up).
local function markTarget(ctx,words)
 local target=ctx.targets()[1]
 if target then ctx.marker(target.Root.Position,words,16,target) end
end
local function overheated(ctx)
 return ctx.plane~=nil and workspace:GetServerTimeNow()<(ctx.plane:GetAttribute("MountCoolingUntil1") or 0)
end
local function shootText(words)
 return function(ctx) return overheated(ctx) and "Too hot! Let go of left click to cool down." or words end
end
local function noseOn(ctx,position,degrees)
 return ctx.body~=nil and ctx.body.CFrame.LookVector:Dot((position-ctx.body.Position).Unit)>math.cos(math.rad(degrees))
end
local Course=require(Root.Shared.TrainingCourse)

-- Combat School, part 1: aiming (Alan 2026-10-19). First in slow motion, almost still, so there's time to see how
-- the circle, the dot and the orange ring work; then once more at full speed. Walls only bounce
-- you off here (gentle). HUD pieces get the soft frame (thin, see-through, no dim) so the crosshair stays visible.
local AIM_STEPS={
  {text="Slow motion! Move your circle onto the yellow star. Keep it there until the green dot reaches the star, then hold it 1 second.",key="Mouse",
   hint="The dot is slow. Keep your circle still on the star and wait.",
   enter=function(ctx) ctx.lesson({slow=true,gentle=true});ctx.data.point=1;ctx.data.held=0 end,
   update=function(ctx)
    if ctx.state~="FLYING" then return false end
    local star=ctx.star(Course.POINTS[ctx.data.point])
    -- Flew past it: the star waits at the next point instead.
    if (star.Position-ctx.body.Position).Magnitude<45 then ctx.data.point=ctx.data.point%#Course.POINTS+1 end
    ctx.softSpot("AimCircle","NoseDot")
    ctx.marker(star.Position,"STAR",12,star)
    ctx.data.held=not ctx.reading and noseOn(ctx,star.Position,4) and ctx.data.held+ctx.dt or 0
    return ctx.data.held>=1
   end},
  {text=shootText("Put the green dot on a paper plane. When the dot turns red, hold left click until the plane falls. Do 3."),key="Left click",count=3,
   hint="Red dot = your shots will hit. Keep holding until it falls.",
   enter=function(ctx) ctx.lesson({drill="still"}) end,
   update=function(ctx)
    ctx.pulse("Fire") -- (a phone's FIRE button gets a frame; a PC has no "Fire", so nothing shows there)
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
  -- Leading (Alan 2026-10-19: nothing taught it): first just look at the ring in front of a plane flying past.
  {text="Shots take time to fly. The orange ring shows where the plane WILL be. Aim at the ring, not the plane.",gotIt=true,
   enter=function(ctx) ctx.lesson({drill="moving"}) end,
   update=function(ctx)
    ctx.softSpot("LeadPipper");ctx.softTag("AIM HERE")
    markTarget(ctx,"WATCH")
    return false
   end},
  {text=shootText("Put the green dot on the orange ring. When the dot turns red, hold left click until the plane falls. Do 2."),key="Left click",count=2,
   hint="Steer a little ahead of the plane, onto its ring.",
   update=function(ctx)
    ctx.softSpot("LeadPipper");ctx.softTag("AIM HERE")
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
  {text=shootText("This one is fast, so its ring is further ahead. Keep the dot on the orange ring and hold left click until it falls."),key="Left click",count=1,
   hint="Follow the ring as it zooms across.",
   enter=function(ctx) ctx.lesson({drill="fast"}) end,
   update=function(ctx)
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
}

-- Combat School, part 2: fighting. One Pal at a time. Pals can never fold you (only crashes can) and stop
-- fighting while you're down; the engine shows a countdown and flies you back to the same step.
local function markPal(ctx,words)
 local pal=ctx.pal()
 if pal then ctx.marker(pal.Root.Position,words,16,pal) end
end
local FIGHT_STEPS={
  {text=shootText("An enemy plane! It's slow and won't shoot. Follow the yellow line to it. Put the dot on its orange ring and hold left click."),key="Left click",
   hint="Get behind it first. Then aim at the ring.",
   enter=function(ctx) ctx.lesson({drill=false,pal="circle",gentle=false,slow=false});ctx.data.start=ctx.count("PalFolds") end,
   update=function(ctx)
    markPal(ctx,"ENEMY")
    return ctx.count("PalFolds")>ctx.data.start
   end},
  {text=function(ctx)
    local plane=ctx.plane
    local low=plane and plane:GetAttribute("Health")<=(plane:GetAttribute("MaxHealth") or 1)*.5
    if overheated(ctx) then return "Too hot! Let go of left click to cool down." end
    -- It shoots from behind (BotService:palAmbush): once it has hit you, say where it is while it's back there
    -- (Alan 2026-10-22: said before the first shot, you turned round before it could hit you).
    local pal=ctx.pal()
    local hit=plane and plane:GetAttribute("Health")<(plane:GetAttribute("MaxHealth") or 0)
    if hit and not low and pal and ctx.body and (pal.Root.Position-ctx.body.Position):Dot(ctx.body.CFrame.LookVector)<0 then
     return "It's behind you, shooting! Turn round and follow the yellow line to it."
    end
    return low and "It stopped shooting and is flying away. Chase it! Dot on its orange ring, hold left click." or "This one shoots back! Follow the yellow line and chase it."
   end,key="Left click",
   hint="It shoots only until your Health bar is half full. Then it runs. Get behind it.",
   enter=function(ctx) ctx.lesson({pal="pellet"});ctx.data.start=ctx.count("PalFolds") end,
   update=function(ctx)
    ctx.pulse("HealthStrip")
    markPal(ctx,"ENEMY")
    return ctx.count("PalFolds")>ctx.data.start
   end},
}

-- Combat School, part 3: the eraser (Alan 2026-10-19: until now the plane has no eraser, so its big circle and
-- sounds don't distract from aiming; it is the one weapon that works differently). Slow motion again to lock on,
-- full speed once, then dodge a Pal's eraser and fire one back.
local ERASER_STEPS={
  {text="Last part: erasers! Hold right click to fire an eraser that chases the plane you lock on to.",gotIt=true,
   enter=function(ctx) ctx.lesson({pal=false,eraser=true,slow=true,gentle=true}) end,
   update=function(ctx) ctx.pulse("Fire2");return false end}, -- (phones: frames the 2 button)
  -- Holding right click through the 1.5 s lock fires the eraser by itself (CombatService), so no "let go" step.
  {text="Hold right click. Keep the paper plane inside the big pink circle.",key="Right click",
   hint="Turn so the plane sits inside the pink circle round your nose.",
   enter=function(ctx) ctx.lesson({drill="eraser"}) end,
   update=function(ctx)
    ctx.softSpot("EraserSeeker")
    markTarget(ctx,"LOCK ON")
    return ctx.plane~=nil and (ctx.plane:GetAttribute("LockProgress") or 0)>=.3
   end},
  {text=function(ctx)
    local progress=ctx.plane and ctx.plane:GetAttribute("LockProgress") or 0
    return progress>0 and progress<1 and "Keep holding... it fires when the box turns red!" or "Keep holding right click with the plane in the pink circle. Count to 2: the box turns red and the eraser fires by itself!"
   end,key="Right click",count=1,
   hint="Lost it? The box starts over if the plane leaves the pink circle.",
   update=function(ctx)
    markTarget(ctx,"LOCK ON")
    return ctx.count("DrillDown")
   end},
  -- The reload card comes between the first eraser shot and the full-speed one, while the reload fills (Alan
  -- 2026-10-19; a second slow-motion lock was cut as redundant).
  {text="Erasers take 4 seconds to reload. Watch the right-click row fill up.",gotIt=true,
   update=function(ctx)
    ctx.spotlight("RightStrip")
    return false
   end},
  {text="Now at full speed! Hold right click and keep the plane in the pink circle until the eraser fires.",key="Right click",count=1,
   hint="Count to 2 with it in the circle.",
   enter=function(ctx) ctx.lesson({slow=false,drill="fastEraser"}) end,
   update=function(ctx)
    markTarget(ctx,"LOCK ON")
    return ctx.count("DrillDown")
   end},
  {text=function(ctx)
    local plane=ctx.plane;local now=workspace:GetServerTimeNow()
    if plane and now<(plane:GetAttribute("EraserIncomingUntil") or 0) then
     return (plane:GetAttribute("EraserDistance") or math.huge)<Gameplay.combat.eraser_break_studs and "BREAK NOW! Move the mouse all the way to one side!" or "An eraser is chasing you! Don't turn yet. Wait for BREAK NOW!"
    end
    if plane and now<(plane:GetAttribute("IncomingLockUntil") or 0) then return "It's locking on to you. An eraser is coming!" end
    if ctx.data.hitOnce then return "It hit you. The next one is slower. Turn hard when you see BREAK NOW!" end
    return "This enemy fires erasers at you. Wait for BREAK NOW!, then turn hard."
   end,
   hint="Turning too early lets the eraser follow you. Wait for the words.",
   enter=function(ctx) ctx.lesson({drill=false,gentle=false,repair=true,pal="eraser"});ctx.data.misses=ctx.count("PalEraserMisses");ctx.data.hits=ctx.count("PalEraserHits") end,
   update=function(ctx)
    if ctx.count("PalEraserHits")>ctx.data.hits then ctx.data.hitOnce=true end
    markPal(ctx,"ENEMY")
    return ctx.count("PalEraserMisses")>ctx.data.misses
   end},
  {text="Dodged it! Your turn. Hold right click and keep the enemy in the pink circle until your eraser fires.",key="Right click",
   hint="Count to 2 with it in the circle.",
   enter=function(ctx) ctx.lesson({pal="circle"});ctx.data.start=ctx.count("EraserHits") end,
   update=function(ctx)
    ctx.softSpot("EraserSeeker")
    markPal(ctx,"LOCK ON")
    return ctx.count("EraserHits")>ctx.data.start
   end},
}
-- One lesson after Flight School (Alan 2026-10-19: "flight school, then combat school").
-- Then the Hangar Tour (Alan 2026-10-22: it is part of the same series), offered beside "Go to a match".
Lessons.combat={name="Combat School",doneTitle="You're ready!",next="hangar",steps={launch()}}
for _,list in {AIM_STEPS,FIGHT_STEPS,ERASER_STEPS} do for _,step in list do table.insert(Lessons.combat.steps,step) end end
-- The Hangar Range (Alan 2026-10-19: its name; not a lesson: it never ends; Menu > Leave goes back). `room`: the engine
-- shows no note and allows no skipping (Tutorial.luau); its one step only gets the plane onto the stage.
Lessons.range={name="Hangar Range",room=true,steps={{
 update=function(ctx)
  -- Asked again until the plane is on the stage (the first ask can come before the server has made it).
  if ctx.state~="FLYING" and os.clock()-(ctx.data.asked or 0)>1 then ctx.data.asked=os.clock();ctx.lesson({range=true}) end
  return false
 end}}}

-- Lesson 3, the Hangar Tour (TUTORIAL-PLAN "Lesson 3", OK'd by Alan 2026-10-21): in the Range, on the Range's own
-- builds (your match builds never change), over the real Hangar. Each step watches the Hangar's own state (Hangar.tour)
-- rather than clicks, since most clicks redraw the Hangar. `page`: the Hangar page the step is on (lesson.ready turns
-- to it); `out`: the step needs the Hangar closed. A step whose change you should see (a new wing, new gear) waits a
-- moment with the spotlight off before it ticks.
local HttpService=game:GetService("HttpService")
local Hangar=require(script.Parent.Hangar)
local Catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),Gameplay)
local LOOK_AFTER=2.3 -- seconds a step with a visible change stays up after it (the usual .8 + 1.5 to see it)
local GEAR_IDS={};for _,part in Catalog.weapons do table.insert(GEAR_IDS,part.id) end
local function tour() local t=Hangar.tour;return t and t.state.draft and t.state or nil end
local function watch(update) return function(ctx) local s=tour();return s~=nil and update(ctx,s) end end
local tourWings -- the wings on the plane when the try-on steps began
local function spot(s) return math.min(2,Catalog:get(s.draft.body).mount_count) end
local function hangarOpen(ctx) local layer=ctx.player.PlayerGui:FindFirstChild("HangarScreen");return layer~=nil and layer.Cover.Visible end
-- Step 4 walks down the stat sheet one row at a time, in kid words (Alan 2026-10-21: say what every bar means).
local STATS={
 {"Health","Health: how many hits your plane can take before it folds. More boxes = tougher."},
 {"Speed","Speed: how fast your plane flies. More boxes = faster."},
 {"Climb","Climb: how fast your nose turns up and down. Good for loops and dodging."},
 {"Swerve","Swerve: how fast you turn left and right. Good for chasing other planes."},
 {"Lift","Lift: how long you can stay up before you must refill at a fan or your desk."},
 {"Weight","Weight: how much gear your plane can carry. Each gear fills some of these boxes."},
}
-- A stat's row on the sheet: its label strip and its boxes (Weight has as many boxes as the body carries).
local function statRow(name) local names={name.."Row"};for k=1,12 do table.insert(names,name.."Box"..k) end;return table.unpack(names) end
-- A gear card on the page showing the red X (it can't go on this plane), if there is one right now.
local function crossedCard(ctx)
 local layer=ctx.player.PlayerGui:FindFirstChild("HangarScreen")
 for _,id in GEAR_IDS do local card=layer and layer:FindFirstChild(id,true);if card and card:FindFirstChild("CrayonX") then return id end end
end
Lessons.hangar={name="Hangar Tour",screen="HangarScreen",stay="range",ding="softDing",waitText="Opening your Hangar...",doneTitle="Hangar Tour done!",
 doneText="Your match planes are in the main menu's Hangar: same screens. In matches, some parts unlock with levels and Paper. The Range is yours now!",
 ready=function(ctx,step)
  -- First the plane onto the Range stage (asked again until the server has made it), then the Hangar open on the right page.
  if not ctx.plane or ctx.plane:GetAttribute("Pinned")==nil then
   if os.clock()-(ctx.data.asked or 0)>1 then ctx.data.asked=os.clock();ctx.lesson({range=true}) end
   return false
  end
  if step.out then
   if hangarOpen(ctx) and Hangar.tour then Hangar.tour.close() end -- Test in Range was skipped: back to the stage
   return true
  end
  local s=tour()
  if s and hangarOpen(ctx) then
   if step.page and s.page~=step.page then
    if step.page=="shelf" then s.builder:reset(s.builds[s.preset].loadout,s.preset) end -- what Back does: unsaved changes go
    s.page,s.dropAsk,s.trying=step.page,nil,nil;Hangar.tour.render()
   end
   return true
  end
  -- Closed (Back, or Esc then Resume): open it again, but never over the game menu.
  if not game.ReplicatedStorage.FlyFightPaper:GetAttribute("OverlayOpen") and os.clock()-(ctx.data.opened or 0)>1 then
   ctx.data.opened=os.clock();require(script.Parent.MenuController).show("hangar",true)
  end
  return false
 end,
 steps={
  {text="This is your Hangar. Each cubby holds one of your planes.",gotIt=true,page="shelf",
   update=function(ctx) ctx.spotlight("EndLeft","EndRight");return false end},
  {text="Click the glowing cubby to pick that plane.",page="shelf",hint="Click the cubby in the bright frame.",
   update=watch(function(ctx,s)
    ctx.data.from=ctx.data.from or s.preset
    if s.preset~=ctx.data.from then return true end
    ctx.spotlight("Pick"..(ctx.data.from==1 and 2 or 1));return false
   end)},
  {text="Name it! Click the glowing pencil, type a name, press Enter.",key="Enter",pcKey=true,page="shelf",hint="Like the name? Press K to skip this step.",
   update=watch(function(ctx,s)
    local name=s.builds[s.preset].name;ctx.data.name=ctx.data.name or name
    ctx.spotlight("NameTape","Rename")
    -- Done on Enter, not when the save comes back (that takes a couple of seconds and the ding came late).
    local layer=ctx.player.PlayerGui:FindFirstChild("HangarScreen");local box=layer and layer:FindFirstChild("BuildName",true)
    local typed=box and not box:IsFocused() and box.Text:match("%S") and box.Text~=ctx.data.name
    return name~=ctx.data.name or typed==true
   end)},
  {text=function(ctx) local page=ctx.data.page or 1;return STATS[page][2].."  "..page.."/"..#STATS end,gotIt=true,pages=#STATS,page="shelf",
   update=function(ctx) ctx.spotlight(statRow(STATS[ctx.data.page or 1][1]));return false end},
  {text="Click the glowing Customize button to change its parts.",page="shelf",
   update=watch(function(ctx,s) ctx.spotlight("Customize");return s.page=="customize" end)},
  {text="Each tab is one part of the plane. Click the glowing Wings tab.",page="customize",
   update=watch(function(ctx,s) ctx.spotlight("Tabwings");return s.slot=="wings" end)},
  -- Two steps (Alan 2026-10-28: as one, it moved on before the numbers could be read): try a card on, then Select.
  {text="Click a wing card to try it on: the numbers on the sheet show what it would change.",page="customize",hint="Pick a wing card that doesn't say Equipped.",
   linger=LOOK_AFTER,update=watch(function(ctx,s)
    tourWings=tourWings or s.draft.wings
    if s.trying or s.draft.wings~=tourWings then return true end
    for _,part in Catalog.structuresBySlot.wings do if part.id~=tourWings then ctx.spotlight(part.id);break end end
    return false
   end)},
  {text="Like them? Click Select to put them on.",page="customize",hint="No Select? Click a wing card first.",
   linger=LOOK_AFTER,update=watch(function(ctx,s)
    if s.draft.wings~=tourWings then tourWings=nil;return true end
    if s.trying then ctx.spotlight("SelectPart") else for _,part in Catalog.structuresBySlot.wings do if part.id~=tourWings then ctx.spotlight(part.id);break end end end
    return false
   end)},
  {text="Gear is what your plane shoots. Click the glowing Gear tab.",page="customize",
   update=watch(function(ctx,s) ctx.spotlight("Tabweapons");return s.slot=="weapons" end)},
  {text=function(ctx) return "These numbers are your gear spots. Click spot "..(ctx.data.spot or 2).."." end,page="customize",
   update=watch(function(ctx,s) ctx.data.spot=spot(s);ctx.spotlight("Mount"..ctx.data.spot);return s.mount==ctx.data.spot end)},
  {text=function(ctx) return "Click a gear card: it goes on spot "..(ctx.data.spot or 2)..". Too big for it? It goes on a spot that fits." end,page="customize",
   hint="A card with a red X can't go there: try another.",linger=LOOK_AFTER,
   update=watch(function(ctx,s)
    ctx.data.spot=spot(s)
    local mounts=HttpService:JSONEncode(s.draft.weapon_mounts);ctx.data.before=ctx.data.before or mounts
    if mounts~=ctx.data.before then return true end
    ctx.spotlight(table.unpack(GEAR_IDS));return false
   end)},
  -- Three pages: the Weight boxes, the left/right click line, and a red X, shown only when a card really has one.
  {text=function(ctx)
    local page=ctx.data.page or 1
    local text=page==1 and "Each gear weighs something. Its weight fills these boxes: a plane can't carry more than they hold."
     or page==2 and "This line says which click fires this spot's gear: one gear type on left click, the other on right."
     or "A red X means that gear can't go on your plane right now. The card says why."
    return text.."  "..page.."/"..(crossedCard(ctx) and 3 or 2)
   end,gotIt=true,page="customize",pages=function(ctx) return crossedCard(ctx) and 3 or 2 end,
   update=function(ctx)
    local page=ctx.data.page or 1
    if page==1 then ctx.spotlight(statRow("Weight")) elseif page==2 then ctx.spotlight("MountInfo") else ctx.spotlight(crossedCard(ctx) or "MountInfo") end
    return false
   end},
  {text="Click the glowing Save button to keep your build.",page="customize",
   update=watch(function(ctx,s)
    ctx.spotlight("SavePreset");ctx.data.dirty=ctx.data.dirty or s.unsaved
    return ctx.clicked("SavePreset") or ctx.data.dirty and not s.unsaved
   end)},
  {text="Click the glowing Test in Range button to fly it.",page="customize",
   update=function(ctx) ctx.spotlight("SaveFly");return ctx.clicked("SaveFly") end},
  {text="Now try it! Put the green dot on 3 different targets and hold left click.",key="Left click",count=3,out=true,hint="A target counts once its Health drops. Try a different one each time.",
   update=function(ctx)
    -- Different targets (Alan 2026-10-21: one target hit three times finished it): a card counts once its Health drops.
    -- A torn-down card is replaced by a new one, which counts as another target.
    ctx.data.health=ctx.data.health or {};ctx.data.hit=ctx.data.hit or {}
    local folder=workspace:FindFirstChild("RangeCards");local n=0
    for _,card in folder and folder:GetChildren() or {} do
     if card:GetAttribute("DrillOf")==ctx.player.UserId then
      local health=card:GetAttribute("Health") or 0
      if ctx.data.health[card] and health<ctx.data.health[card] then ctx.data.hit[card]=true end
      ctx.data.health[card]=health
     end
    end
    for _ in ctx.data.hit do n+=1 end
    return n
   end},
 }}
return Lessons
