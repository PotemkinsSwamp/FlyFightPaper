-- Navigation nodes are gameplay data, derived from the native room. They do not build geometry. Shared: the bots
-- fly these routes (server) and the tutorial draws its guide line along them (client).
local Rules=require(script.Parent.AirMapRules)
local Routes={};Routes.__index=Routes
local JOIN_STUDS=110 -- town points join neighbours this close (the coarse grid's points join up to 510 apart)
local HOLE_CELL=4 -- studs between the rays cast across a building to find its holes
local HOLE_CLEAR=20 -- a hole needs this much room from its middle to the nearest wall (a route ball is 18)
local function roomOverlap(flight)
	local box=OverlapParams.new();box.FilterType=Enum.RaycastFilterType.Include;box.FilterDescendantsInstances={flight.room};box.RespectCanCollide=true
	return box
end
-- A point a plane fits at: nothing solid within 18 studs (a 36 stud box).
local function fits(position,box) return #workspace:GetPartBoundsInBox(CFrame.new(position),Vector3.new(36,36,36),box)==0 end
function Routes.new(flight)
	local self=setmetatable({flight=flight,nodes={},edges={}},Routes)
	local box=roomOverlap(flight)
	local size=flight.boundsSize
	local config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).world
	for _,y in ipairs(config.route_y_positions) do
		local height=y*math.min(1,size.Y/config.height_studs)
		for _,column in ipairs(config.route_x_positions) do
			local x=column*math.min(1,size.X/config.width_studs)
			for _,row in ipairs(config.route_z_positions) do
				local z=row*math.min(1,size.Z/config.depth_studs)
				local position=Vector3.new(x,height,z)
				if fits(position,box) then table.insert(self.nodes,position) end
			end
		end
	end
	self.coarse=#self.nodes
	for i,a in ipairs(self.nodes) do
		self.edges[i]={}
		for j,b in ipairs(self.nodes) do
			local delta=b-a
			if i~=j and delta.Magnitude<510 and self:clear(a,b,18) then self.edges[i][j]=delta.Magnitude end
		end
	end
	return self
end
-- Bots in the town (docs/plan/BOTS-IN-TOWN-PLAN.md step 1): low points over the town mat and points before, inside and
-- after every hole a plane fits through, joined to their neighbours. The server runs it once after start, a few
-- milliseconds a frame (it yields); bots fly the coarse routes until the finished map swaps in.
function Routes:buildTown()
	local started,clock=os.clock(),os.clock()
	local function breathe() if os.clock()-clock>.003 then task.wait();clock=os.clock() end end
	local town=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay).world.town_routes
	local half=town.half_size
	local box=roomOverlap(self.flight)
	local nodes=table.clone(self.nodes)
	local edges={};for i,e in pairs(self.edges) do edges[i]=table.clone(e) end
	for _,y in ipairs(town.y_positions) do
		for x=-half[1]+town.spacing/2,half[1],town.spacing do
			for z=-half[2]+town.spacing/2,half[2],town.spacing do
				local position=Vector3.new(x,y,z)
				if fits(position,box) then table.insert(nodes,position) end
				breathe()
			end
		end
	end
	local holes=self:findHoles(half,box,breathe)
	local legs={}
	for _,hole in ipairs(holes) do
		local first=#nodes+1
		for _,p in ipairs(hole) do table.insert(nodes,p) end
		hole.inside=first+1
		table.insert(legs,{first,first+1});table.insert(legs,{first+1,first+2})
	end
	local function join(i,j)
		if self:clear(nodes[i],nodes[j],18) then
			local d=(nodes[j]-nodes[i]).Magnitude
			edges[i]=edges[i] or {};edges[j]=edges[j] or {}
			edges[i][j],edges[j][i]=d,d
		end
		breathe()
	end
	-- Neighbours through a grid of JOIN_STUDS cells. Coarse pairs are already joined (up to 510 apart). Town points are
	-- all clear of parts by 18 studs, so one cast serves both ways.
	local cells={}
	local function cell(p) return Vector3.new(math.floor(p.X/JOIN_STUDS),math.floor(p.Y/JOIN_STUDS),math.floor(p.Z/JOIN_STUDS)) end
	for i,p in ipairs(nodes) do local c=cell(p);cells[c]=cells[c] or {};table.insert(cells[c],i) end
	for i,p in ipairs(nodes) do
		local c=cell(p)
		for dx=-1,1 do for dy=-1,1 do for dz=-1,1 do
			for _,j in ipairs(cells[c+Vector3.new(dx,dy,dz)] or {}) do
				if j>i and j>self.coarse and (nodes[j]-p).Magnitude<JOIN_STUDS then join(i,j) end
			end
		end end end
	end
	for _,leg in ipairs(legs) do join(leg[1],leg[2]) end
	self.nodes,self.edges,self.holes=nodes,edges,holes
	if game:GetService("RunService"):IsStudio() then
		print(("Air routes: %d points (%d coarse), %d holes, built in %.1f s"):format(#nodes,self.coarse,#holes,os.clock()-started))
	end
end
-- A hole is where rays cross a building's box without touching it while rays above and to both sides do
-- (AirMapRules.holes). Buildings are the town's solid pieces grouped by name ("tube-tower/3-left" -> tube-tower) and
-- nearness, each scanned along x and along z; pieces under 50 studs tall (lamps, trees, cars) are skipped. Returns
-- {before, inside, after} for each hole.
function Routes:findHoles(half,box,breathe)
	local city=self.flight.room:FindFirstChild("CityToys")
	if not city then return {} end
	local groups={}
	for _,part in ipairs(city:GetChildren()) do
		if part:IsA("BasePart") and part.CanCollide and math.abs(part.Position.X)<half[1] and math.abs(part.Position.Z)<half[2] then
			local name=part.Name:match("^[^/]+")
			local cf,size=part.CFrame,part.Size
			local reach=((cf.RightVector*size.X):Abs()+(cf.UpVector*size.Y):Abs()+(cf.LookVector*size.Z):Abs())/2
			local group
			for _,g in ipairs(groups) do if g.name==name and (g.at-part.Position).Magnitude<260 then group=g;break end end
			if not group then group={name=name,at=part.Position,low=part.Position,high=part.Position,parts={}};table.insert(groups,group) end
			group.low,group.high=group.low:Min(part.Position-reach),group.high:Max(part.Position+reach);table.insert(group.parts,part)
			breathe()
		end
	end
	local holes={}
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.RespectCanCollide=true
	for _,g in ipairs(groups) do
		local size=g.high-g.low
		if size.Y>=50 then
			params.FilterDescendantsInstances=g.parts
			-- On the ground the floor is the hole's bottom wall: row 1 is the floor.
			local floor=g.low.Y<10 and 1 or 0
			for _,axis in ipairs({Vector3.xAxis,Vector3.zAxis}) do
				local side=axis==Vector3.xAxis and Vector3.zAxis or Vector3.xAxis
				local depth=size:Dot(axis)
				local blocked={}
				local rows,cols=math.ceil(size.Y/HOLE_CELL)+floor,math.ceil(size:Dot(side)/HOLE_CELL)
				local function at(col,row) return g.low+side*((col-.5)*HOLE_CELL)+Vector3.yAxis*((row-floor-.5)*HOLE_CELL) end
				for row=1,rows do
					blocked[row]={}
					for col=1,cols do
						blocked[row][col]=row<=floor or workspace:Raycast(at(col,row)-axis*5,axis*(depth+10),params)~=nil
						breathe()
					end
				end
				for _,hole in ipairs(Rules.holes(blocked,HOLE_CLEAR/HOLE_CELL)) do
					local middle=at(hole.col,hole.row)+axis*(depth/2)
					local before,after=middle-axis*(depth/2+35),middle+axis*(depth/2+35)
					if fits(before,box) and fits(after,box) then table.insert(holes,{before,middle,after}) end
				end
			end
		end
	end
	return holes
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
-- Checks a plan may spend finding a point in reach (ponytail: a cap, not a smarter search; each check is a shape cast,
-- and checking every point of the town map stalled a frame for up to 55 ms).
local REACH_CHECKS=12
-- The nearest point a plane can fly straight to and back from, among the REACH_CHECKS closest.
function Routes:nearest(position)
	local close={}
	for i,p in ipairs(self.nodes) do
		local d=(p-position).Magnitude
		if #close<REACH_CHECKS or d<close[#close][2] then
			local k=#close+1
			while k>1 and close[k-1][2]>d do k-=1 end
			table.insert(close,k,{i,d})
			if #close>REACH_CHECKS then table.remove(close) end
		end
	end
	for _,entry in ipairs(close) do
		local p=self.nodes[entry[1]]
		if self:clear(position,p,18) and self:clear(p,position,18) then return entry[1] end
	end
	return nil
end
-- Open air ahead: the best-placed point (ahead, about 250 studs off) in reach, among the REACH_CHECKS best placed.
function Routes:escape(from,forward)
	local scored={}
	for _,node in ipairs(self.nodes) do
		local delta=node-from
		if delta.Magnitude>75 then table.insert(scored,{node,forward:Dot(delta.Unit)*2-math.abs(delta.Magnitude-250)/1000}) end
	end
	table.sort(scored,function(a,b) return a[2]>b[2] end)
	for k=1,math.min(#scored,REACH_CHECKS) do if self:clear(from,scored[k][1],18) then return {scored[k][1]} end end
	return {}
end
-- The next leg of a street run (plan step 5): a low town point 150-450 studs from `from`, not behind it, that takes the
-- bot furthest from `threat`; the first of the REACH_CHECKS furthest that `threat` can't see, else the furthest. Nil
-- before the town map is built or when no low point leads away.
function Routes:runSpot(from,forward,threat)
	local spots={}
	local start=(threat-from).Magnitude
	for i=(self.coarse or #self.nodes)+1,#self.nodes do
		local p=self.nodes[i]
		local delta=p-from;local d=delta.Magnitude
		local gain=(p-threat).Magnitude-start
		if p.Y<100 and d>150 and d<450 and gain>60 and forward:Dot(delta.Unit)>-.2 then table.insert(spots,{p,gain}) end
	end
	table.sort(spots,function(a,b) return a[2]>b[2] end)
	for k=1,math.min(#spots,REACH_CHECKS) do
		local p=spots[k][1]
		if workspace:Raycast(threat,p-threat,self.flight.cast) then return p end
	end
	return spots[1] and spots[1][1]
end
-- A hole whose way in is 40-`reach` studs ahead (within about 50 degrees of the nose) and runs the way the bot is going:
-- {in, middle, out}, ordered from the bot's side.
function Routes:holeAhead(from,forward,reach)
	for _,hole in ipairs(self.holes or {}) do
		local near=(hole[1]-from).Magnitude<(hole[3]-from).Magnitude
		local entry,exit=near and hole[1] or hole[3],near and hole[3] or hole[1]
		local delta=entry-from;local d=delta.Magnitude
		if d>40 and d<reach and forward:Dot(delta.Unit)>.65 and forward:Dot((exit-entry).Unit)>.3 then return {entry,hole[2],exit} end
	end
	return nil
end
-- A random low town point within `radius` of `at` (a bot searching where it lost a low target, plan step 6).
function Routes:pickNear(random,at,radius)
	local near={}
	for i=(self.coarse or #self.nodes)+1,#self.nodes do
		local p=self.nodes[i]
		if p.Y<100 and (p-at).Magnitude<radius then table.insert(near,p) end
	end
	return #near>0 and near[random:NextInteger(1,#near)] or nil
end
-- The hole ({before, inside, after}) whose middle is within `radius` of `position`.
function Routes:holeAt(position,radius)
	for _,hole in ipairs(self.holes or {}) do if (hole[2]-position).Magnitude<radius then return hole end end
	return nil
end
-- Whether the straight line a -> b passes within `radius` of a hole's middle.
function Routes:passes(a,b,hole,radius)
	local d=b-a
	local t=d:Dot(d)>0 and math.clamp((hole[2]-a):Dot(d)/d:Dot(d),0,1) or 0
	return (a+d*t-hole[2]).Magnitude<radius
end
-- Route leg costs that skip one hole (for AirMapRules.search).
function Routes:without(hole)
	return function(_,to,cost) if to==hole.inside then return nil end return cost end
end
-- A random point to cruise to: low over the town (under 100 studs) when `low`, else one of the coarse grid's.
function Routes:pick(random,low)
	local first,last=1,self.coarse or #self.nodes
	if low and #self.nodes>last then first,last=last+1,#self.nodes end
	for _=1,20 do
		local p=self.nodes[random:NextInteger(first,last)]
		if not low or p.Y<100 then return p end
	end
	return self.nodes[random:NextInteger(1,#self.nodes)]
end
function Routes:path(from,to,forward,legCost)
	local delta=to-from
	forward=forward or (delta.Magnitude>.01 and delta.Unit or Vector3.zAxis)
	local start,goal=self:nearest(from),self:nearest(to)
	if not start or not goal then return self:escape(from,forward) end
	local indices=Rules.search(self.nodes,self.edges,start,goal,legCost)
	if not indices then return self:escape(from,forward) end
	local result={}
	for _,i in ipairs(indices) do table.insert(result,self.nodes[i]) end
	table.insert(result,to)
	-- Skip visible intermediate nodes. Replanning must not repeatedly turn a moving
	-- plane back toward the nearest node it has already flown past.
	return self:compact(result,from)
end
-- Looks at most eight points ahead (ponytail: a town path can be 30 points; checking every one ahead of each would be
-- hundreds of casts a plan).
function Routes:compact(path,from)
	local result={};local cursor=from;local index=1
	while index<=#path do
		local nextIndex=index
		for j=math.min(#path,index+8),index+1,-1 do if self:clear(cursor,path[j],18) then nextIndex=j;break end end
		table.insert(result,path[nextIndex]);cursor=path[nextIndex];index=nextIndex+1
	end
	return result
end
return Routes
