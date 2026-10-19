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

Lessons.flight={
 name="Flight School",
 steps={
  {text="Click LAUNCH to take off!",key="Enter",
   update=function(ctx)
    ctx.spotlight("Launch")
    return ctx.clicked("Launch") or (ctx.state~="DESK" and ctx.state~=nil)
   end},
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
return Lessons
