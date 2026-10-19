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

Lessons.flight={
 name="Flight School",next="combat",
 steps={
  launch(),
  {text="Move the mouse to steer through the hoops.",key="Mouse",count=3,hint="Your plane turns toward the circle.",
   enter=function(ctx) ctx.data.passed=0 end,
   update=function(ctx)
    if ctx.state~="FLYING" and ctx.state~="TAKEOFF" then return ctx.data.passed end
    local hoop,model=ctx.hoop()
    ctx.marker(hoop.Position,"FLY HERE",34,model)
    if ctx.passedHoop() then ctx.data.passed+=1;ctx.ding();ctx.clearHoop() end
    return ctx.data.passed
   end},
  {text="Your Lift drops every second. Fill it up in a fan: follow the line!",key=nil,hint="Follow the yellow line, then fly up into the fan's wind.",
   update=function(ctx)
    ctx.spotlight("LiftStrip") -- everything greyed out but the Lift bar (Alan); the line and glow show the fan
    local fan=ctx.body and nearestFan(ctx.body.Position)
    if fan then ctx.marker(fan.center,"FLY UP HERE",fan.half.X,blades(fan)) end
    return ctx.state=="FLYING" and ctx.body~=nil and inFan(ctx.body.Position)
   end},
  {text="Fly through a speed bolt for extra speed.",hint="Bolts spin inside the rings and tubes.",
   enter=function(ctx) ctx.data.before=ctx.plane and ctx.plane:GetAttribute("PickupUntil") or 0 end,
   update=function(ctx)
    local bolt=ctx.body and ctx.nearestBolt(ctx.body.Position)
    if bolt then ctx.marker(bolt.Position,"SPEED BOLT",14,bolt) end
    return ctx.plane~=nil and (ctx.plane:GetAttribute("PickupUntil") or 0)>ctx.data.before
   end},
  {text="Hold Shift to boost.",key="Shift",
   enter=function(ctx) ctx.data.boosted=0 end,
   update=function(ctx)
    ctx.pulse("BoostStrip")
    if ctx.plane and ctx.plane:GetAttribute("Boosting") then ctx.data.boosted+=ctx.dt end
    return ctx.data.boosted>=1
   end},
  {text="Land: fly through your desk's ring.",hint="Line up in front of the desk first, then fly straight in.",land=true,
   update=function(ctx)
    local ring=ctx.plane and ctx.plane:GetAttribute("PracticeRing")
    local rel=ring and ctx.body and ring:PointToObjectSpace(ctx.body.Position)
    local lined=rel and rel.Z<-80 and math.abs(rel.X)<30 and math.abs(rel.Y)<40
    if ring and ctx.state=="FLYING" then ctx.marker(lined and ring.Position or (ring*CFrame.new(0,10,-260)).Position,lined and "YOUR DESK: STRAIGHT ON" or "LINE UP HERE",24) end
    return ctx.state=="DESK" and ctx.data.flew
   end},
  {text="At your desk: Refill Lift and Repair are free. Full refold changes your plane. Fresh plane starts over.",gotIt=true,
   update=function(ctx)
    ctx.spotlight("Refill","Repair","Fresh","Refold")
    return false
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
-- the circle, the dot, the orange ring and the eraser lock work; then once more at full speed. Walls only bounce
-- you off here (gentle). HUD pieces get the soft frame (thin, see-through, no dim) so the crosshair stays visible.
local AIM_STEPS={
  {text="Slow motion! The circle is where you steer. The dot is where your guns point. Put the dot on the star.",key="Mouse",
   hint="Hold the circle on the star and wait: the dot slides over to it.",
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
  {text=shootText("Put the dot on a target. When the dot turns red, hold left click!"),key="Left click",count=3,
   hint="Wait for the dot to turn red: that means your pellets will hit. Then hold left click.",
   enter=function(ctx) ctx.lesson({drill="still"}) end,
   update=function(ctx)
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
  -- Leading (Alan 2026-10-19: nothing taught it): first just look at the ring in front of a plane flying past.
  {text="Pellets take time to get there. The orange ring is where the plane WILL be: that's leading. Get close and your guns aim at it.",gotIt=true,
   enter=function(ctx) ctx.lesson({drill="moving"}) end,
   update=function(ctx)
    ctx.softSpot("LeadPipper");ctx.softTag("AIM HERE")
    markTarget(ctx,"WATCH")
    return false
   end},
  {text=shootText("Get the dot close to the orange ring. When the dot turns red, hold left click!"),key="Left click",count=2,
   hint="Red means your guns will hit: once you're close, they aim at the ring for you.",
   update=function(ctx)
    ctx.softSpot("LeadPipper");ctx.softTag("AIM HERE")
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
  -- Holding right click through the 1.5 s lock fires the eraser by itself (CombatService), so no "let go" step.
  {text="Your eraser chases planes. Hold right click and keep a target inside the big circle.",key="Right click",
   hint="Turn so the target sits inside the big circle round your nose.",
   enter=function(ctx) ctx.lesson({drill="eraser"}) end,
   update=function(ctx)
    ctx.softSpot("EraserSeeker")
    markTarget(ctx,"LOCK ON")
    return ctx.plane~=nil and (ctx.plane:GetAttribute("LockProgress") or 0)>=.3
   end},
  {text=function(ctx)
    local progress=ctx.plane and ctx.plane:GetAttribute("LockProgress") or 0
    return progress>0 and progress<1 and "Keep holding... when the box turns red, the eraser fires!" or "Keep it in the circle until the box turns red: the eraser fires and chases!"
   end,key="Right click",count=2,
   hint="Lost it? The box starts over when the target leaves the big circle. A quick click fires straight, with no chase.",
   update=function(ctx)
    markTarget(ctx,"LOCK ON")
    return ctx.count("DrillDown")
   end},
  {text="Erasers take 4 seconds to reload: watch the right-click row fill up.",gotIt=true,
   update=function(ctx)
    ctx.spotlight("RightStrip")
    return false
   end},
  {text=shootText("Full speed! Shoot the one flying past: dot on the orange ring."),key="Left click",count=1,
   hint="Same as before, just faster. Dot on the orange ring.",
   enter=function(ctx) ctx.lesson({slow=false,drill="fast"}) end,
   update=function(ctx)
    markTarget(ctx,"SHOOT")
    return ctx.count("DrillDown")
   end},
  {text="Now lock on with your eraser: hold right click.",key="Right click",count=1,
   hint="Keep the target in the big circle until the box turns red.",
   enter=function(ctx) ctx.lesson({drill="fastEraser"}) end,
   update=function(ctx)
    markTarget(ctx,"LOCK ON")
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
  {text=shootText("An enemy! It's slow and won't shoot. Shoot it down: dot on the orange ring."),key="Left click",
   hint="Follow the line to it, then put the dot on the orange ring and hold left click.",
   enter=function(ctx) ctx.lesson({drill=false,pal="circle",gentle=false});ctx.data.start=ctx.count("PalFolds") end,
   update=function(ctx)
    markPal(ctx,"ENEMY")
    return ctx.count("PalFolds")>ctx.data.start
   end},
  {text=function(ctx)
    local plane=ctx.plane
    local low=plane and plane:GetAttribute("Health")<=(plane:GetAttribute("MaxHealth") or 1)*.5
    if overheated(ctx) then return "Too hot! Let go of left click to cool down." end
    return low and "It hit you: your Health went down. Now it's stopped. Shoot it down!" or "This one shoots back! Watch your Health bar."
   end,key="Left click",
   hint="It only shoots until you're at half Health. Then chase it and shoot.",
   enter=function(ctx) ctx.lesson({pal="pellet"});ctx.data.start=ctx.count("PalFolds") end,
   update=function(ctx)
    ctx.pulse("HealthStrip")
    markPal(ctx,"ENEMY")
    return ctx.count("PalFolds")>ctx.data.start
   end},
  {text=function(ctx)
    local plane=ctx.plane;local now=workspace:GetServerTimeNow()
    if plane and now<(plane:GetAttribute("EraserIncomingUntil") or 0) then
     return (plane:GetAttribute("EraserDistance") or math.huge)<Gameplay.combat.eraser_break_studs and "BREAK NOW! Turn hard, right now!" or "INCOMING! An eraser is chasing you. Wait for BREAK NOW!"
    end
    if plane and now<(plane:GetAttribute("IncomingLockUntil") or 0) then return "LOCKED ON! It's about to fire an eraser at you." end
    if ctx.data.hitOnce then return "It hit you! The next one is slower. Turn hard as soon as you see BREAK NOW!" end
    return "This one fires slow erasers. Dodge one: when you see BREAK NOW!, turn hard."
   end,
   hint="Turn hard the moment BREAK NOW! shows. Turning too early lets it follow you.",
   enter=function(ctx) ctx.lesson({repair=true,pal="eraser"});ctx.data.misses=ctx.count("PalEraserMisses");ctx.data.hits=ctx.count("PalEraserHits") end,
   update=function(ctx)
    if ctx.count("PalEraserHits")>ctx.data.hits then ctx.data.hitOnce=true end
    markPal(ctx,"ENEMY")
    return ctx.count("PalEraserMisses")>ctx.data.misses
   end},
  {text="Dodged it! Your turn: hold right click with the enemy inside the big circle.",key="Right click",
   hint="Keep it in the big circle until the box turns red: your eraser fires and chases it.",
   enter=function(ctx) ctx.lesson({pal="circle"});ctx.data.start=ctx.count("EraserHits") end,
   update=function(ctx)
    ctx.softSpot("EraserSeeker")
    markPal(ctx,"LOCK ON")
    return ctx.count("EraserHits")>ctx.data.start
   end},
}
-- One lesson after Flight School (Alan 2026-10-19: "flight school, then combat school").
Lessons.combat={name="Combat School",doneTitle="You're ready!",steps={launch()}}
for _,list in {AIM_STEPS,FIGHT_STEPS} do for _,step in list do table.insert(Lessons.combat.steps,step) end end
return Lessons
