local Root=game.ReplicatedStorage.FlyFightPaper
local Catalog=require(Root.Shared.Catalog)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local catalog=Catalog.new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 test("six classes: three from level 1, the rest by level 10",function()
  local open=0
  assert(#catalog:classes()==6)
  for _,class in catalog:classes() do
   if class.min_level==1 then open+=1 end
   assert(class.min_level<=10,class.id)
  end
  assert(open==3)
 end)
 test("every class plane is legal, without owning its parts",function()
  for _,class in catalog:classes() do
   local plane=catalog:classLoadout(class.id,50)
   assert(catalog:validateLoadout(plane,nil,1000000000),class.id)
   assert(catalog:deriveStats(plane),class.id)
  end
 end)
 test("no class carries an eraser or a pencil",function()
  for _,class in catalog:classes() do
   for _,weapon in catalog:classLoadout(class.id,50).weapon_mounts do assert(weapon~="eraser" and weapon~="pencil",class.id) end
  end
 end)
 test("a class stays shut below its level",function()
  assert(catalog:classLoadout("bomber",7)==nil and catalog:classLoadout("bomber",8)~=nil)
  assert(catalog:classLoadout("nope",50)==nil and catalog:classById("nope")==nil)
 end)
 test("a class's plane is a copy, so changing one can't change the class",function()
  local plane=catalog:classLoadout("striker",50)
  plane.weapon_mounts[1]="pencil"
  assert(catalog:classLoadout("striker",50).weapon_mounts[1]=="staple")
 end)
 test("a refold accepts only an open class's exact plane",function()
  local plane=catalog:classLoadout("carrier",50)
  assert(catalog:isClassLoadout(plane,10) and not catalog:isClassLoadout(plane,9))
  plane.weapon_mounts[3]="pellet"
  assert(not catalog:isClassLoadout(plane,50))
 end)
 test("a saved build's parts don't pass as a class",function()
  local plane=catalog:classLoadout("striker",50)
  plane.utility=nil
  assert(not catalog:isClassLoadout(plane,50))
 end)
 return result
end
return Spec
