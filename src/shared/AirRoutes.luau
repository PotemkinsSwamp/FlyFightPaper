-- Navigation nodes are gameplay data, derived from the native room. They do not build geometry. Shared: the bots
-- fly these routes (server) and the tutorial draws its guide line along them (client).
local Routes={};Routes.__index=Routes
function Routes.new(flight)
	local self=setmetatable({flight=flight,nodes={},edges={}},Routes)
	local box=OverlapParams.new();box.FilterType=Enum.RaycastFilterType.Include;box.FilterDescendantsInstances={flight.room};box.RespectCanCollide=true
	local size=flight.boundsSize
	local config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).world
	for _,y in ipairs(config.route_y_positions) do
		local height=y*math.min(1,size.Y/config.height_studs)
		for _,column in ipairs(config.route_x_positions) do
			local x=column*math.min(1,size.X/config.width_studs)
			for _,row in ipairs(config.route_z_positions) do
				local z=row*math.min(1,size.Z/config.depth_studs)
				local position=Vector3.new(x,height,z)
				if #workspace:GetPartBoundsInBox(CFrame.new(position),Vector3.new(36,36,36),box)==0 then table.insert(self.nodes,position) end
			end
		end
	end
	for i,a in ipairs(self.nodes) do
		self.edges[i]={}
		for j,b in ipairs(self.nodes) do
			local delta=b-a
			if i~=j and delta.Magnitude<510 and self:clear(a,b,18) then self.edges[i][j]=delta.Magnitude end
		end
	end
	return self
end
function Routes:clear(a,b,radius)
	local d=b-a
	local length=d.Magnitude
	if length<.01 then return true end
	local direction=d.Unit
	-- Roblox limits each shape sweep to 1024 studs.
	for offset=0,length,1000 do
		local remaining=math.min(1000,length-offset)
		if remaining>.001 and workspace:Spherecast(a+direction*offset,radius or 8,direction*remaining,self.flight.cast) then return false end
	end
	return true
end
function Routes:nearest(position)
	local best,index=math.huge,nil
 for i,p in ipairs(self.nodes) do local distance=(p-position).Magnitude;if distance<best and self:clear(position,p,18) and self:clear(p,position,18) then best,index=distance,i end end
	return index
end
function Routes:escape(from,forward)
 local best,index=-math.huge,nil
 for i,node in ipairs(self.nodes) do
  local delta=node-from
  if delta.Magnitude>75 and self:clear(from,node,18) then
   local score=forward:Dot(delta.Unit)*2-math.abs(delta.Magnitude-250)/1000
   if score>best then best,index=score,i end
  end
 end
 return index and {self.nodes[index]} or {}
end
function Routes:path(from,to,forward)
 local delta=to-from
 forward=forward or (delta.Magnitude>.01 and delta.Unit or Vector3.zAxis)
 local start,goal=self:nearest(from),self:nearest(to)
 if not start or not goal then return self:escape(from,forward) end
	local distance,previous,open={[start]=0},{},{[start]=true}
	while next(open) do
		local current,best=nil,math.huge
		for i in pairs(open) do if distance[i]<best then current,best=i,distance[i] end end
		if current==goal then break end
		open[current]=nil
		for neighbor,cost in pairs(self.edges[current]) do
			local d=best+cost
			if d<(distance[neighbor] or math.huge) then distance[neighbor]=d;previous[neighbor]=current;open[neighbor]=true end
		end
	end
 if not distance[goal] then return self:escape(from,forward) end
	local result={};local i=goal
	while i do table.insert(result,1,self.nodes[i]);if i==start then break end;i=previous[i] end
	table.insert(result,to)
	-- Skip visible intermediate nodes. Replanning must not repeatedly turn a moving
	-- plane back toward the nearest node it has already flown past.
	return self:compact(result,from)
end
function Routes:compact(path,from)
	local result={};local cursor=from;local index=1
	while index<=#path do
		local nextIndex=index
		for j=#path,index+1,-1 do if self:clear(cursor,path[j],18) then nextIndex=j;break end end
		table.insert(result,path[nextIndex]);cursor=path[nextIndex];index=nextIndex+1
	end
	return result
end
return Routes
