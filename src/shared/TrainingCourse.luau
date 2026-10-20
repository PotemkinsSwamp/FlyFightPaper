-- The Training Room's fixed course (docs/systems/tutorial.md), shared by the lesson screen (hoops, markers) and the
-- server (practice target planes, the Pals' flying route). Points are clear air in front of the Training Room desk
-- (DeskSouth3), checked by hand in Studio: 50 studs of empty air round each and the legs between them clear.
-- ponytail: world points for the tutorial room's desk only; another desk still gets the same course.
local Course={}
Course.POINTS={Vector3.new(-225,205,440),Vector3.new(-210,280,270),Vector3.new(-170,340,100)}
-- Aiming slow motion (Alan 2026-10-19: "way slower, almost to a standstill, but you can turn and aim"): only your own
-- plane slows to this share; shots and targets keep their speed.
Course.SLOW_MO=.06
-- Practice target planes, placed where the pilot is when the step starts (Alan: the course points were too far to
-- reach in slow motion): `yaw` degrees off the plane's heading, `range` studs ahead, in clear air (RoundRuntime
-- checks and tries nearby spots). Still ones face the pilot. Moving ones sweep left and right across in front of
-- the pilot at a real plane's speed (Alan: crossing your view is what shows the lead; head-on it doesn't): a long
-- flat loop `span` studs to each side and `depth` studs toward and away, `speed` studs/s at its middle.
-- `health`: pellet targets fold after about 6 pellets; eraser targets after one eraser, and only erasers count.
Course.DRILLS={
 still={{yaw=-25,range=220,health=12},{yaw=0,range=220,health=12},{yaw=25,range=220,health=12}},
 -- Measured in Play (2026-10-19): crossing at 100 studs/s 220 away, the plane's nose trailed the ring by 30-60 px, so
 -- the dot never sat in it. Further and slower: about 10 degrees/s across, the ring still a clear 40 px ahead.
 moving={{yaw=0,range=350,health=12,speed=60,span=130,depth=20},{yaw=0,range=350,rise=45,health=12,speed=60,span=130,depth=20,phase=math.pi}},
 eraser={{yaw=0,range=350,health=30,speed=45,span=110,depth=20,eraserOnly=true}}, -- one: its second lock step was cut
 -- Still slow motion for you, but twice as fast across (Alan 2026-10-19: at full speed you just caught up with it).
 fast={{yaw=0,range=350,health=12,speed=120,span=170,depth=25}},
 fastEraser={{yaw=0,range=350,health=30,speed=45,span=110,depth=20,eraserOnly=true}},
}
-- The Range (docs/plan/TUTORIAL-PLAN.md): far from the classroom, the plane hangs at `origin` facing the stage (-Z);
-- targets are flat cut-outs on sticks in three rows (`at`: offset from origin; `row`: close, medium or long), each
-- swinging side to side (it turns over at the ends) and bobbing. A folded one is replaced after the usual respawn wait.
-- `yaw`/`up`/`down`: how far the crosshair may move from straight ahead (radians) over the still Range camera's view;
-- down reaches the picker plates on the floor.
-- `picks`: the knock-down plates on the stage floor at the bottom of the view that pick which rows stand (Alan
-- 2026-10-19): shoot one and it tips back on its hinge and stays down while picked. Bigger plate = closer row.
-- `x`: across the stage, `w`: width in studs.
-- `seat`: where the plane hangs, from origin: back toward the still camera so it sits low and out of the way.
Course.RANGE={origin=CFrame.new(0,900,12000),seat=Vector3.new(0,0,10),yaw=math.rad(48),up=math.rad(28),down=math.rad(34),targets={
 -- Wide, high sweeps so the targets use the whole stage (Alan approved the flying area 2026-10-20). Speeds are
 -- Challenge's; the other difficulties scale them (DIFFICULTY).
 {row="close",at=Vector3.new(0,20,-150),health=40,speed=65,span=130,depth=4,bob=35,color="red"},
 {row="close",at=Vector3.new(0,10,-172),health=40,speed=65,span=130,depth=4,bob=35,color="blue",phase=math.pi},
 {row="medium",at=Vector3.new(-40,70,-360),health=40,speed=117,span=260,depth=4,bob=70,color="blue",phase=math.pi},
 {row="medium",at=Vector3.new(40,55,-385),health=40,speed=117,span=260,depth=4,bob=70,color="red",phase=math.pi/2},
 {row="long",at=Vector3.new(30,130,-620),health=40,speed=185,span=450,depth=4,bob=110,color="red"},
 {row="long",at=Vector3.new(-30,115,-645),health=40,speed=185,span=450,depth=4,bob=110,color="blue",phase=math.pi},
},picks={
 {row="close",label="Close",x=-98,w=35},{row="medium",label="Medium",x=-63,w=28},
 {row="long",label="Long\nrange",x=70,w=22},{row="all",label="All",x=100,w=19},
}}
-- The Range's difficulty strips: how fast the targets sweep and how far they swoop up and down. Maneuvers adds a
-- quick weave on top, like a real enemy dodging.
-- Alan 2026-10-20: Maneuvers at Veteran's speed was impossible, so it weaves at Challenge's speed.
Course.DIFFICULTY={noob={speed=.6,bob=.6},challenge={speed=1,bob=1},veteran={speed=1.4,bob=1.2},maneuvers={speed=1,bob=1,weave=true}}
function Course.difficulty(spec,level)
 local d=Course.DIFFICULTY[level] or Course.DIFFICULTY.noob
 local copy=table.clone(spec);copy.speed=spec.speed*d.speed;copy.bob=(spec.bob or 0)*d.bob;copy.weave=d.weave
 return copy
end
-- Where a target is `t` seconds after it appeared, sweeping round `center` along `side` (the pilot's right when it
-- appeared), and its velocity; a still one faces `face`.
function Course.pose(drill,center,t,face,side)
 if not drill.speed then
  return CFrame.lookAt(center,Vector3.new(face.X,center.Y,face.Z)),Vector3.zero
 end
 local toward=side:Cross(Vector3.yAxis)
 local w=drill.speed/drill.span;local a=t*w+(drill.phase or 0)
 -- `bob`: up and down twice per sweep (the Range's targets swoop as they cross).
 local bob=drill.bob or 0
 local at=center+side*math.cos(a)*drill.span+toward*math.sin(a)*drill.depth+Vector3.yAxis*math.sin(2*a)*bob
 local velocity=(-side*math.sin(a)*drill.span+toward*math.cos(a)*drill.depth+Vector3.yAxis*math.cos(2*a)*2*bob)*w
 if drill.weave then -- a quick side-step and dip on top of the sweep, out of step with it
  at+=side*math.sin(2.3*a)*drill.span*.14+Vector3.yAxis*math.sin(3.1*a+1)*bob*.35
  velocity+=(side*math.cos(2.3*a)*2.3*drill.span*.14+Vector3.yAxis*math.cos(3.1*a+1)*3.1*bob*.35)*w
 end
 return CFrame.lookAt(at,at+velocity),velocity
end
-- The points a target passes through, to check its whole sweep is in clear air.
function Course.sweep(drill,center,side)
 if not drill.speed then return {center} end
 local list={}
 for k=-2,2 do table.insert(list,center+side*drill.span*k/2) end
 return list
end
-- Spots to try for a target, best first: its own, then turned further, closer, higher or lower.
function Course.candidates(drill,origin,heading)
 local list={}
 for _,turn in {0,15,-15,35,-35,60,-60} do
  for _,share in {1,.75} do
   for _,rise in {0,50,-30,100} do
    local look=CFrame.Angles(0,math.rad(drill.yaw+turn),0):VectorToWorldSpace(heading)
    table.insert(list,origin+look*drill.range*share+Vector3.new(0,rise+(drill.rise or 0),0))
   end
  end
 end
 return list
end
return Course
