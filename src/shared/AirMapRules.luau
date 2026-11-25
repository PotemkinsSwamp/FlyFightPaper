local AirMapRules={}

local function push(heap,entry)
 local i=#heap+1
 while i>1 do
  local parent=math.floor(i/2)
  if heap[parent].priority<=entry.priority then break end
  heap[i]=heap[parent]
  i=parent
 end
 heap[i]=entry
end

local function pop(heap)
 local first=heap[1]
 local last=table.remove(heap)
 local size=#heap
 if size==0 then return first end
 local i=1
 while i*2<=size do
  local child=i*2
  if child<size and heap[child+1].priority<heap[child].priority then child+=1 end
  if heap[child].priority>=last.priority then break end
  heap[i]=heap[child]
  i=child
 end
 heap[i]=last
 return first
end

function AirMapRules.search(nodes,edges,start,goal)
 if start==goal then return {start} end
 local source,target=nodes[start],nodes[goal]
 if not source or not target then return nil end
 local distance,previous,heap={[start]=0},{},{}
 push(heap,{node=start,cost=0,priority=(source-target).Magnitude})
 while #heap>0 do
  local entry=pop(heap)
  local current=entry.node
  -- A cheaper entry may have been pushed since this one.
  if entry.cost~=distance[current] then continue end
  if current==goal then
   local path={}
   while current do
    path[#path+1]=current
    current=previous[current]
   end
   for i=1,math.floor(#path/2) do
    local j=#path+1-i
    path[i],path[j]=path[j],path[i]
   end
   return path
  end
  local neighbors=edges[current]
  if not neighbors then continue end
  for neighbor,cost in pairs(neighbors) do
   local node=nodes[neighbor]
   if not node then continue end
   local nextCost=entry.cost+cost
   local known=distance[neighbor]
   if not known or nextCost<known then
    distance[neighbor]=nextCost
    previous[neighbor]=current
    push(heap,{node=neighbor,cost=nextCost,priority=nextCost+(node-target).Magnitude})
   end
  end
 end
 return nil
end

local function clearanceSquared(horizontal,vertical,row,col)
 local straight=math.min(horizontal[row][col],vertical[col][row])
 local best=straight*straight
 local radius=1
 while radius*radius<=best do
  local offset=math.huge
  local bottom,top=horizontal[row-radius],horizontal[row+radius]
  local left,right=vertical[col-radius],vertical[col+radius]
  if bottom then offset=math.min(offset,bottom[col]) end
  if top then offset=math.min(offset,top[col]) end
  if left then offset=math.min(offset,left[row]) end
  if right then offset=math.min(offset,right[row]) end
  -- The nearest blocked cell on a ring edge must lie between its corners.
  if offset<=radius then best=math.min(best,radius*radius+offset*offset) end
  radius+=1
 end
 return best
end

function AirMapRules.holes(blocked,minClearance)
 local height=#blocked
 if height==0 then return {} end
 local width=#blocked[1]
 local horizontal,vertical,enclosed={},{},{}
 -- Cache the nearest block along each line and mark cells with two walls and a roof.
 for row=1,height do
  local cells=blocked[row]
  local distances,inside={},{}
  horizontal[row],enclosed[row]=distances,inside
  local left=-math.huge
  for col=1,width do
   if cells[col] then left=col end
   distances[col]=col-left
  end
  local right=math.huge
  for col=width,1,-1 do
   if cells[col] then right=col end
   inside[col]=distances[col]>0 and distances[col]<math.huge and right<math.huge
   distances[col]=math.min(distances[col],right-col)
  end
 end
 for col=1,width do
  local distances={}
  vertical[col]=distances
  local above=math.huge
  for row=height,1,-1 do
   if blocked[row][col] then above=row end
   enclosed[row][col]=enclosed[row][col] and above<math.huge
   distances[row]=above-row
  end
  local below=-math.huge
  for row=1,height do
   if blocked[row][col] then below=row end
   distances[row]=math.min(distances[row],row-below)
  end
 end

 local result={}
 local function enqueue(queue,row,col)
  if enclosed[row] and enclosed[row][col] then
   enclosed[row][col]=false
   queue[#queue+1]=(row-1)*width+col
  end
 end
 for row=1,height do
  for col=1,width do
   if not enclosed[row][col] then continue end
   local queue={}
   enqueue(queue,row,col)
   local bestRow,bestCol,best=row,col,0
   local head=1
   while head<=#queue do
    local index=queue[head]-1
    head+=1
    local r,c=math.floor(index/width)+1,index%width+1
    local score=clearanceSquared(horizontal,vertical,r,c)
    if score>best or (score==best and (r<bestRow or (r==bestRow and c<bestCol))) then
     bestRow,bestCol,best=r,c,score
    end
    enqueue(queue,r-1,c)
    enqueue(queue,r+1,c)
    enqueue(queue,r,c-1)
    enqueue(queue,r,c+1)
   end
   local clearance=math.sqrt(best)
   if clearance>=minClearance then
    result[#result+1]={col=bestCol,row=bestRow,clearance=clearance}
   end
  end
 end
 table.sort(result,function(a,b)
  if a.row==b.row then return a.col<b.col end
  return a.row<b.row
 end)
 return result
end

return AirMapRules
