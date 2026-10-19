-- The Training Room's fixed course (docs/systems/tutorial.md), shared by the lesson screen (hoops, markers) and the
-- server (practice target planes, the Pals' flying route). Points are clear air in front of the Training Room desk
-- (DeskSouth3), checked by hand in Studio: 50 studs of empty air round each and the legs between them clear.
-- ponytail: world points for the tutorial room's desk only; another desk still gets the same course.
local Course={}
Course.POINTS={Vector3.new(-225,205,440),Vector3.new(-210,280,270),Vector3.new(-170,340,100)}
-- Aiming lesson slow motion (Alan 2026-10-19): planes and targets fly at this share of their speed; shots don't.
Course.SLOW_MO=.35
-- Practice target planes. Still ones hold their spot facing the desk; moving ones fly a small flat circle round the
-- point (radius 40 keeps the wings inside the 50 clear studs) at `speed` studs/s (times SLOW_MO in slow motion).
-- `health`: pellet targets fold after about 6 pellets; eraser targets after one eraser, and only erasers count.
Course.CIRCLE_RADIUS=40
Course.DRILLS={
 still={{point=1,health=12},{point=2,health=12},{point=3,health=12}},
 moving={{point=2,health=12,speed=60},{point=3,health=12,speed=60,phase=math.pi}},
 eraser={{point=2,health=30,speed=60,eraserOnly=true},{point=3,health=30,speed=60,eraserOnly=true,phase=math.pi}},
 fast={{point=2,health=12,speed=60}},
 fastEraser={{point=3,health=30,speed=60,eraserOnly=true}},
}
-- Where a target is `t` seconds after it appeared (time already scaled for slow motion) and which way it faces.
function Course.pose(drill,t,desk)
 local center=Course.POINTS[drill.point]
 if not drill.speed then
  local face=Vector3.new(desk.X,center.Y,desk.Z)
  return CFrame.lookAt(center,face),Vector3.zero
 end
 local w=drill.speed/Course.CIRCLE_RADIUS;local a=t*w+(drill.phase or 0)
 local at=center+Vector3.new(math.cos(a),0,math.sin(a))*Course.CIRCLE_RADIUS
 local velocity=Vector3.new(-math.sin(a),0,math.cos(a))*drill.speed
 return CFrame.lookAt(at,at+velocity),velocity
end
return Course
