local SpeedMatch=require(game.ReplicatedStorage.FlyFightPaper.Shared.SpeedMatch)
local Cfg=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).flight.speed_match
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local ME={position=Vector3.zero,look=Vector3.new(0,0,-1),velocity=Vector3.new(0,0,-120)}
local function plane(x,z,vx,vz) return {position=Vector3.new(x,0,z),velocity=Vector3.new(vx,0,vz)} end
function Spec.run()
 local result,test=Suite.new()
 test("picks the plane you are tailing, not one crossing in front or coming head-on",function()
  local others={ahead=plane(0,-200,0,-80),crossing=plane(0,-100,100,0),headOn=plane(5,-90,0,100)}
  assert(SpeedMatch.pick({},ME,others,0,Cfg)=="ahead")
 end)
 test("nothing to follow when the plane is far or well off the nose",function()
  assert(SpeedMatch.pick({},ME,{far=plane(0,-Cfg.pick_range_studs-10,0,-80)},0,Cfg)==nil)
  assert(SpeedMatch.pick({},ME,{side=plane(150,-150,0,-80)},0,Cfg)==nil)
 end)
 test("keeps its plane when another passes closer in front",function()
  local memory={}
  local others={a=plane(0,-200,0,-80)}
  SpeedMatch.pick(memory,ME,others,0,Cfg)
  others.b=plane(0,-60,0,-80) -- closer, and also tailed
  assert(SpeedMatch.pick(memory,ME,others,.1,Cfg)=="a")
 end)
 test("holds on for a moment after losing the plane, then lets go",function()
  local memory={}
  local others={a=plane(0,-200,0,-80)}
  SpeedMatch.pick(memory,ME,others,0,Cfg)
  others.a=plane(300,-100,80,0) -- broke away sideways
  assert(SpeedMatch.pick(memory,ME,others,1,Cfg)=="a")
  assert(SpeedMatch.pick(memory,ME,others,1+Cfg.lost_seconds+.01,Cfg)==nil)
  others.a=nil
  assert(SpeedMatch.pick({id="a"},ME,others,2,Cfg)==nil) -- a folded plane is let go at once
 end)
 test("slows to a slower plane's speed once close, closes in from further back, never speeds up or stalls",function()
  local close=SpeedMatch.factor(ME,plane(0,-Cfg.follow_studs,0,-90),120,Cfg)
  assert(math.abs(close-.75)<1e-6)
  assert(SpeedMatch.factor(ME,plane(0,-240,0,-90),120,Cfg)>close)
  assert(SpeedMatch.factor(ME,plane(0,-100,0,-200),120,Cfg)==1)
  assert(SpeedMatch.factor(ME,plane(0,-100,0,-10),120,Cfg)==Cfg.floor_factor)
 end)
 return result
end
return Spec
