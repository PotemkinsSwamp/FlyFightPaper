local AirMapRules=require(game.ReplicatedStorage.FlyFightPaper.Shared.AirMapRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}

local function grid(height,width,blocked)
 local rows={}
 for row=1,height do rows[row]=table.create(width,blocked) end
 return rows
end

local function clearRectangle(blocked,bottom,top,left,right)
 for row=bottom,top do
  for col=left,right do blocked[row][col]=false end
 end
end

function Spec.run()
 local result,test=Suite.new()
 test("a cheaper chain beats a costly direct edge",function()
  local nodes,edges={},{}
  for i=1,7 do nodes[i]=Vector3.new(i,0,0) end
  for i=1,6 do edges[i]={[i+1]=1} end
  edges[1][7]=10
  local path=AirMapRules.search(nodes,edges,1,7)
  -- Six unit edges cost 6, and the direct edge costs 10.
  assert(path and #path==7)
  for i=1,7 do assert(path[i]==i) end
 end)
 test("unreachable goals return nil with missing nodes and edges",function()
  local nodes={Vector3.zero,Vector3.xAxis,Vector3.xAxis*2}
  local edges={{[2]=1,[4]=3}}
  -- Only node 2 can be reached from node 1. Node 4 is missing and node 2 has no exits.
  assert(AirMapRules.search(nodes,edges,1,3)==nil)
 end)
 test("the start is the whole path when it is also the goal",function()
  local path=AirMapRules.search({Vector3.zero},{},1,1)
  -- Reaching node 1 from itself takes zero edges and returns one node.
  assert(path and #path==1 and path[1]==1)
 end)
 test("one-way edges only work in their listed direction",function()
  local nodes={Vector3.zero,Vector3.xAxis}
  local edges={{[2]=1}}
  local path=AirMapRules.search(nodes,edges,1,2)
  -- The only edge costs 1 and leads from node 1 to node 2.
  assert(path and #path==2 and path[1]==1 and path[2]==2)
  assert(AirMapRules.search(nodes,edges,2,1)==nil)
 end)
 test("a 40 by 40 grid gives the cheapest path between opposite corners",function()
  local size=40
  local nodes,edges={},{}
  for row=1,size do
   for col=1,size do
    local i=(row-1)*size+col
    nodes[i]=Vector3.new(col,0,row)
    local neighbors={}
    if row>1 then neighbors[i-size]=1 end
    if row<size then neighbors[i+size]=1 end
    if col>1 then neighbors[i-1]=1 end
    if col<size then neighbors[i+1]=1 end
    edges[i]=neighbors
   end
  end
  local path=AirMapRules.search(nodes,edges,1,size*size)
  assert(path and path[1]==1 and path[#path]==size*size)
  local cost=0
  for i=2,#path do cost+=assert(edges[path[i-1]][path[i]]) end
  -- 39 steps across and 39 up cost 78, with no diagonal shortcuts.
  assert(cost==78)
 end)
 test("a nine-cell square tunnel has five cells of centre clearance",function()
  local blocked=grid(11,11,true)
  clearRectangle(blocked,2,10,2,10)
  local holes=AirMapRules.holes(blocked,5)
  -- The centre is row 6, col 6. The walls at 1 and 11 are five cells away.
  assert(#holes==1 and holes[1].row==6 and holes[1].col==6 and holes[1].clearance==5)
 end)
 test("a small tunnel below the minimum clearance is skipped",function()
  local blocked=grid(5,5,true)
  clearRectangle(blocked,2,4,2,4)
  -- The centre at row 3, col 3 is two cells from the wall, below the minimum of 3.
  assert(#AirMapRules.holes(blocked,3)==0)
 end)
 test("an arch can have a hole at the open bottom of the grid",function()
  local blocked=grid(5,8,false)
  for row=1,4 do blocked[row][2],blocked[row][7]=true,true end
  for col=2,7 do blocked[5][col]=true end
  local holes=AirMapRules.holes(blocked,2)
  -- The middle columns 4 and 5 get two cells of clearance in rows 1 to 3.
  -- The tie goes to row 1, col 4.
  assert(#holes==1 and holes[1].row==1 and holes[1].col==4 and holes[1].clearance==2)
 end)
 test("an open-topped U has no enclosed cells",function()
  local blocked=grid(5,8,false)
  for row=2,5 do blocked[row][2],blocked[row][7]=true,true end
  for col=2,7 do blocked[1][col]=true end
  -- None of the cells between the legs has a blocked cell above it.
  assert(#AirMapRules.holes(blocked,1)==0)
 end)
 test("separate tunnels are sorted by the row and column of their centres",function()
  local blocked=grid(10,14,true)
  clearRectangle(blocked,2,8,2,8)
  clearRectangle(blocked,3,5,10,12)
  local holes=AirMapRules.holes(blocked,2)
  -- The 3 by 3 tunnel has centre (row 4, col 11), two cells from the wall.
  -- The 7 by 7 tunnel has centre (row 5, col 5), four cells from the wall.
  assert(#holes==2)
  assert(holes[1].row==4 and holes[1].col==11 and holes[1].clearance==2)
  assert(holes[2].row==5 and holes[2].col==5 and holes[2].clearance==4)
 end)
 test("diagonal contact between enclosed cells leaves separate holes",function()
  local blocked=grid(4,5,true)
  blocked[2][2],blocked[2][4],blocked[3][3]=false,false,false
  local holes=AirMapRules.holes(blocked,1)
  -- Each clear cell touches a wall one step away and has no clear side neighbor.
  -- Row 2 has the first two holes, with col 2 before col 4.
  assert(#holes==3)
  assert(holes[1].row==2 and holes[1].col==2 and holes[1].clearance==1)
  assert(holes[2].row==2 and holes[2].col==4 and holes[2].clearance==1)
  assert(holes[3].row==3 and holes[3].col==3 and holes[3].clearance==1)
 end)
 test("a diagonal block sets the Euclidean clearance",function()
  local blocked=grid(5,5,true)
  clearRectangle(blocked,2,4,2,4)
  blocked[2][2]=true
  local holes=AirMapRules.holes(blocked,1.4)
  -- From row 3, col 3 the block is one row and one column away, giving sqrt(2).
  -- Every other clear cell is one step from the wall.
  assert(#holes==1 and holes[1].row==3 and holes[1].col==3 and holes[1].clearance==math.sqrt(2))
 end)
 return result
end
return Spec
