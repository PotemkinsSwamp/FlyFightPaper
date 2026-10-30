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
 test("the save check takes only the four buttons with x and y from 0 to 1",function()
  assert(TouchLayout.valid(nil) and TouchLayout.valid({}) and TouchLayout.valid({Fire={x=.9,y=.8}}))
  assert(not TouchLayout.valid({Jump={x=.5,y=.5}}))
  assert(not TouchLayout.valid({Fire={x=1.2,y=.5}}) and not TouchLayout.valid({Fire={x=0/0,y=.5}}))
  assert(not TouchLayout.valid({Fire={x=.5}}) and not TouchLayout.valid({Fire={x=.5,y=.5,z=1}}) and not TouchLayout.valid("left"))
 end)
 return result
end
return Spec
