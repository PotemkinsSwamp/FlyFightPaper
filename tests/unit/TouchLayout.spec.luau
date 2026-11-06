local TouchLayout=require(game.ReplicatedStorage.FlyFightPaper.Shared.TouchLayout)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local VIEW,TOP=Vector2.new(800,390),40
local SIZES={Fire=94,Fire2=62,Boost=62,Brake=62}
local DEFAULTS={Fire=Vector2.new(730,320),Fire2=Vector2.new(730,227),Boost=Vector2.new(627,328),Brake=Vector2.new(651,240)}
function Spec.run()
 local result,test=Suite.new()
 test("the game's own layout fits",function()
  for name,at in DEFAULTS do assert(TouchLayout.fits(name,at,DEFAULTS,SIZES,VIEW,TOP),name) end
 end)
 test("a button can't go on the stick's half, off the screen, under the top bar or on another button",function()
  assert(not TouchLayout.fits("Brake",Vector2.new(390,200),DEFAULTS,SIZES,VIEW,TOP))
  assert(not TouchLayout.fits("Brake",Vector2.new(790,200),DEFAULTS,SIZES,VIEW,TOP))
  assert(not TouchLayout.fits("Brake",Vector2.new(600,50),DEFAULTS,SIZES,VIEW,TOP))
  assert(not TouchLayout.fits("Brake",DEFAULTS.Fire+Vector2.new(-50,-50),DEFAULTS,SIZES,VIEW,TOP))
  assert(TouchLayout.fits("Brake",Vector2.new(520,150),DEFAULTS,SIZES,VIEW,TOP))
 end)
 test("saved spots are used as shares of the screen, and fit a different screen",function()
  local saved=TouchLayout.shares({Brake=Vector2.new(520,150)},VIEW)
  local spots=TouchLayout.place(saved,DEFAULTS,SIZES,VIEW,TOP)
  assert((spots.Brake-Vector2.new(520,150)).Magnitude<1 and spots.Fire==DEFAULTS.Fire)
  local tablet=Vector2.new(1024,768)
  local big=TouchLayout.place(saved,{Fire=Vector2.new(950,690),Fire2=Vector2.new(950,590),Boost=Vector2.new(840,700),Brake=Vector2.new(870,610)},SIZES,tablet,TOP)
  assert((big.Brake-Vector2.new(.65*1024,150/390*768)).Magnitude<2)
 end)
 test("two buttons can swap places",function()
  local saved=TouchLayout.shares({Fire=DEFAULTS.Boost+Vector2.new(-40,-10),Boost=DEFAULTS.Fire},VIEW)
  local spots=TouchLayout.place(saved,DEFAULTS,SIZES,VIEW,TOP)
  assert((spots.Boost-DEFAULTS.Fire).Magnitude<1 and spots.Fire~=DEFAULTS.Fire)
 end)
 test("a spot pushed off a narrower screen is pulled back on; one that then clashes goes home",function()
  local spots=TouchLayout.place({Brake={x=.99,y=.1}},DEFAULTS,SIZES,VIEW,TOP)
  assert(spots.Brake==Vector2.new(VIEW.X-SIZES.Brake/2,TOP+SIZES.Brake/2))
  spots=TouchLayout.place({Brake={x=730/800,y=320/390}},DEFAULTS,SIZES,VIEW,TOP) -- right on FIRE
  assert(spots.Brake==DEFAULTS.Brake)
 end)
 test("a button dropped right up against another stays there after saving",function()
  -- (a share is rounded, so the saved spot can land a hair closer than the closest spot the editor allows)
  local closest=SIZES.Fire/2+SIZES.Brake/2+TouchLayout.GAP+.01
  local homes={Fire=DEFAULTS.Fire,Fire2=Vector2.new(730,80),Boost=Vector2.new(450,350),Brake=DEFAULTS.Brake} -- (2 and BOOST out of the way)
  for degrees=185,265,5 do
   local at=DEFAULTS.Fire+Vector2.new(math.cos(math.rad(degrees)),math.sin(math.rad(degrees)))*closest
   assert(TouchLayout.fits("Brake",at,homes,SIZES,VIEW,TOP),degrees)
   local spots=TouchLayout.place(TouchLayout.shares({Brake=at},VIEW),homes,SIZES,VIEW,TOP)
   assert((spots.Brake-at).Magnitude<2,"BRAKE went back to its own spot at "..degrees)
  end
 end)
 test("a tight layout survives a screen of another shape",function()
  -- (Alan's real save, 2026-11-05: all four moved, FIRE and BRAKE only 3 points apart on this shorter screen)
  local saved={Fire={x=.938,y=.848},Fire2={x=.945,y=.624},Boost={x=.815,y=.864},Brake={x=.855,y=.701}}
  local view=Vector2.new(667,375)
  local sizes={Fire=90,Fire2=60,Boost=60,Brake=60}
  local spots=TouchLayout.place(saved,{Fire=view-Vector2.new(68,75),Fire2=Vector2.new(599,210),Boost=view-Vector2.new(165,60),Brake=Vector2.new(530,240)},sizes,view,TOP)
  for name,share in saved do assert((spots[name]-Vector2.new(share.x*view.X,share.y*view.Y)).Magnitude<5,name) end -- (FIRE is pulled 4 back on screen)
 end)
 test("the save check takes only the four buttons with x and y from 0 to 1",function()
  assert(TouchLayout.valid(nil) and TouchLayout.valid({}) and TouchLayout.valid({Fire={x=.9,y=.8}}))
  assert(not TouchLayout.valid({Jump={x=.5,y=.5}}))
  assert(not TouchLayout.valid({Fire={x=1.2,y=.5}}) and not TouchLayout.valid({Fire={x=0/0,y=.5}}))
  assert(not TouchLayout.valid({Fire={x=.5}}) and not TouchLayout.valid({Fire={x=.5,y=.5,z=1}}) and not TouchLayout.valid("left"))
 end)
 return result
end
return Spec
