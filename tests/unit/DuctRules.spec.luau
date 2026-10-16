local Root = game:GetService("ReplicatedStorage").FlyFightPaper
local Rules = require(Root.Shared.DuctRules)
local Ducts = require(Root.Generated.Gameplay).world.ducts
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
function Spec.run()
	local result, test = Suite.new()
	local function through(x, y) return Vector3.new(x, y, 3), Vector3.new(x, y, -3) end
	test("a plane crossing a blade or the hub is clipped and pushed the way the blades turn", function()
		local push = Rules.fanClip(Vector3.new(40, 0, 3), Vector3.new(40, 0, -3), 0) -- blade 0 points along +X
		assert(push and push:FuzzyEq(Vector3.yAxis, 1e-6), "blade at 0 should clip and push toward +Y")
		assert(Rules.fanClip(Vector3.new(2, 3, 3), Vector3.new(2, 3, -3), 1.3), "the hub always clips")
	end)
	test("the gap between blades is safe, and it moves as the fan turns", function()
		local a, b = through(-40, 0) -- blades at 0, 120, 240 degrees: 180 is between two of them
		assert(Rules.fanClip(a, b, 0) == nil, "half way between blades should be clear")
		assert(Rules.fanClip(a, b, math.pi), "turned half round, a blade is there")
	end)
	test("no clip without crossing the fan, or outside its opening", function()
		assert(Rules.fanClip(Vector3.new(40, 0, 9), Vector3.new(40, 0, 3), 0) == nil, "still in front of it")
		local half = Ducts.fans.opening / 2
		assert(Rules.fanClip(Vector3.new(half + 1, 0, 3), Vector3.new(half + 1, 0, -3), 0) == nil, "outside the opening")
		assert(Ducts.fans.reach <= Ducts.height / 2 and Ducts.fans.reach <= Ducts.width / 2, "blades stay inside the duct")
	end)
	test("the blade's width plus the plane's own size counts", function()
		local edge = Ducts.fans.blade_width / 2 + Ducts.fans.plane_margin
		assert(Rules.fanClip(Vector3.new(40, edge - 0.5, 3), Vector3.new(40, edge - 0.5, -3), 0), "just inside the edge")
		assert(Rules.fanClip(Vector3.new(40, edge + 0.5, 3), Vector3.new(40, edge + 0.5, -3), 0) == nil, "just past it")
	end)
	test("fans turn at their set speed and start out of step", function()
		local turn = Ducts.fans.turns_per_second * 2 * math.pi
		assert(math.abs(Rules.fanAngle(0.1, 0) - Rules.fanAngle(0, 0) - turn * 0.1) < 1e-9)
		assert(Rules.fanAngle(5, 0) ~= Rules.fanAngle(5, 1))
	end)
	test("a fan's frame sits mid-duct and looks along it", function()
		local frame = Rules.fanFrame({ 575, -850, "x" })
		assert(frame.Position:FuzzyEq(Vector3.new(575, Ducts.floor_y + Ducts.height / 2, -850), 1e-6))
		assert(frame.LookVector:FuzzyEq(Vector3.xAxis, 1e-6))
	end)
	test("moving air: with it faster, against it slower, still air elsewhere", function()
		local spot = Ducts.fans.spots[1]
		local flow = (spot[3] == "x" and Vector3.xAxis or Vector3.zAxis) * spot[4]
		local at = Vector3.new(spot[1], Ducts.floor_y + 60, spot[2]) + flow * 40
		assert(math.abs(Rules.wind(at, flow) - (1 + Ducts.fans.wind)) < 1e-6, "with the fan's air")
		assert(math.abs(Rules.wind(at, -flow) - (1 - Ducts.fans.wind * Ducts.fans.headwind_share)) < 1e-6, "against it, gentler")
		assert(Rules.wind(at - Vector3.yAxis * 100, flow) == 1, "under the ceiling")
		local B = Ducts.blower
		local home, other = Ducts.rooms[B.room], Ducts.rooms[B.link[1] == B.room and B.link[2] or B.link[1]]
		local out = (Vector3.new(other[1], 0, other[2]) - Vector3.new(home[1], 0, home[2])).Unit
		local mid = Vector3.new((home[1] + other[1]) / 2, Ducts.floor_y + 60, (home[2] + other[2]) / 2)
		assert(math.abs(Rules.wind(mid, out) - (1 + B.wind)) < 1e-6, "the blower's air")
		assert(Rules.wind(Vector3.new(0, 500, 0), out) == 1, "out in the room")
	end)
	test("bot duct runs: in by one vent, room to room without fans or the pipe, out by another", function()
		local World = require(Root.Generated.Gameplay).world
		local runs, exits = Rules.botRuns(), {}
		assert(#runs >= 6, "several runs to choose from, got " .. #runs)
		local function linked(a, b)
			for _, l in ipairs(Ducts.links) do if l[1] == a and l[2] == b or l[1] == b and l[2] == a then return true end end
			return false
		end
		for _, run in ipairs(runs) do
			local rooms, label = run.rooms, run.vent .. "->" .. run.exit
			assert(rooms[1] == run.vent and rooms[#rooms] == run.exit and run.vent ~= run.exit, label)
			for i = 1, #rooms - 1 do
				local a, b = rooms[i], rooms[i + 1]
				assert(linked(a, b), label .. ": " .. a .. b .. " is not a duct")
				local pipe = Ducts.pipe.link
				assert(not (pipe[1] == a and pipe[2] == b or pipe[1] == b and pipe[2] == a), label .. " uses the pipe")
				for _, spot in ipairs(Ducts.fans.spots) do
					local ra, rb = Ducts.rooms[a], Ducts.rooms[b]
					local onLine = (spot[1] - ra[1]) * (rb[2] - ra[2]) == (spot[2] - ra[2]) * (rb[1] - ra[1])
					local between = math.min(ra[1], rb[1]) <= spot[1] and spot[1] <= math.max(ra[1], rb[1])
						and math.min(ra[2], rb[2]) <= spot[2] and spot[2] <= math.max(ra[2], rb[2])
					assert(not (onLine and between), label .. " goes through a fan")
				end
			end
			for i = 1, 2 do
				local p = run.points[i]
				assert(math.abs(p.X) <= World.width_studs / 2 - 155 and math.abs(p.Z) <= World.depth_studs / 2 - 155, label .. " starts outside the room")
				assert(p.Y < World.height_studs, label .. " starts under the ceiling")
			end
			assert(run.points[#run.points].Y < World.height_studs - 60, label .. " ends out under the ceiling")
			-- the vent grilles are solid: no climb in from their side, no dive out toward it
			local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
			local function hinge(v)
				local side = Ducts.vent_hinge[v]
				return (side:sub(2) == "x" and Vector3.xAxis or Vector3.zAxis) * (side:sub(1, 1) == "+" and 1 or -1)
			end
			assert(flat(run.points[2] - run.points[1]):Dot(hinge(run.vent)) > -0.5, label .. " climbs in through the grille")
			assert(flat(run.points[#run.points] - run.points[#run.points - 1]):Dot(hinge(run.exit)) < 0.5, label .. " dives out into the grille")
			exits[run.exit] = true
		end
		for _, vent in ipairs(Ducts.vents) do assert(exits[vent], "no run comes out of vent " .. vent) end
	end)
	return result
end
return Spec
