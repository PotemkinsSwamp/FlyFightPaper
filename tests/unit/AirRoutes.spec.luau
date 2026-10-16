local Routes=require(game.ServerScriptService.FlyFightPaper.AirRoutes)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 test("open flight paths skip waypoints behind a moving aircraft",function()
  local routes=setmetatable({},Routes)
  function routes:clear() return true end
  local goal=Vector3.new(100,0,0)
  local path=routes:compact({Vector3.zero,Vector3.new(50,0,0),goal},Vector3.new(25,0,0))
  assert(#path==1 and path[1]==goal)
 end)
 test("path shortcuts retain necessary turns around cover",function()
  local routes=setmetatable({},Routes)
  local corner=Vector3.new(0,0,80);local goal=Vector3.new(100,0,80)
  function routes:clear(a,b,radius)
   assert(radius==18)
   return a==corner or b==corner or b==Vector3.zero
  end
  local path=routes:compact({Vector3.zero,corner,Vector3.new(50,0,80),goal},Vector3.new(0,0,-20))
  assert(#path==2 and path[1]==corner and path[2]==goal)
 end)
 test("unreachable goals use open air ahead rather than a blocked target",function()
  local ahead=Vector3.new(250,0,0);local behind=-ahead;local blocked=Vector3.new(300,0,0)
  local routes=setmetatable({nodes={behind,ahead,blocked}},Routes)
  function routes:nearest() return nil end
  function routes:clear(_,to,radius) assert(radius==18);return to~=blocked end
  local path=routes:path(Vector3.zero,Vector3.new(0,0,500),Vector3.xAxis)
  assert(#path==1 and path[1]==ahead)
 end)
 test("a waypoint inside native scenery is not accepted as reachable",function()
  local part=Instance.new("Part");part.Size=Vector3.new(40,40,40);part.Position=Vector3.new(10000,200,0);part.Anchored=true;part.Parent=workspace
  local cast=RaycastParams.new();cast.FilterType=Enum.RaycastFilterType.Include;cast.FilterDescendantsInstances={part};cast.RespectCanCollide=true
  local routes=setmetatable({flight={cast=cast},nodes={part.Position+Vector3.xAxis*100}},Routes)
  local nearest=routes:nearest(part.Position)
  part:Destroy()
  assert(nearest==nil)
 end)
 return result
end
return Spec
