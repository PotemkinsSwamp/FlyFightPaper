-- Rules for the new town's toy monorail train (config world.monorail, track config/monorail-track.json).
-- Pure and on server time: the server judges hits with them, each client moves its own train to match.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Track = require(Root.Generated.MonorailTrack)
local Mono = require(Root.Generated.Gameplay).world.monorail

local MonorailRules = {}

-- The loop's corners and how far round the loop each one is.
local points, along = {}, { 0 }
for i, p in ipairs(Track.line) do
	points[i] = Vector3.new(p[1], 0, p[2])
	if i > 1 then along[i] = along[i - 1] + (points[i] - points[i - 1]).Magnitude end
end
local LENGTH = along[#along]
MonorailRules.length = LENGTH

-- The point on the track's centre line `s` studs round the loop (wraps; y 0).
function MonorailRules.pointAt(s)
	s %= LENGTH
	local lo, hi = 1, #along
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if along[mid] <= s then lo = mid else hi = mid end
	end
	local span = along[hi] - along[lo]
	return points[lo]:Lerp(points[hi], span > 0 and (s - along[lo]) / span or 0)
end

-- How far round the loop the point nearest to (x, z) is.
local function alongAt(x, z)
	local p, best, bestS = Vector3.new(x, 0, z), math.huge, 0
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local t = math.clamp((p - a):Dot(b - a) / math.max((b - a):Dot(b - a), 1e-9), 0, 1)
		local d = (a:Lerp(b, t) - p).Magnitude
		if d < best then best, bestS = d, along[i - 1] + t * (b - a).Magnitude end
	end
	return bestS
end

-- The stops: the train's nose stands half a train past each station's middle, so the whole train is inside it.
-- Between stops it speeds up and slows down at `brake` (studs/s per second); `arrive` is when it gets to a stop,
-- counted from the first stop's arrival, and `period` is one lap with every wait.
local trainLength = 0
for _, car in ipairs(Mono.cars) do trainLength += car.size[3] end
local stops = {}
for _, st in ipairs(Track.stations or {}) do table.insert(stops, { head = (alongAt(st[1], st[2]) + trainLength / 2) % LENGTH }) end
table.sort(stops, function(a, b) return a.head < b.head end)
local period = 0
for k, stop in ipairs(stops) do
	local L = ((stops[k % #stops + 1].head - stop.head - 1e-6) % LENGTH) + 1e-6       -- one stop alone: a whole lap
	local top = math.min(Mono.speed, math.sqrt(Mono.brake * L))
	stop.arrive, stop.length, stop.top, stop.speedUp = period, L, top, top / Mono.brake
	stop.leave = period + Mono.station_wait
	stop.travel = 2 * stop.speedUp + (L - top * stop.speedUp) / top
	period = stop.leave + stop.travel
end
MonorailRules.stops, MonorailRules.period = stops, period

-- How far round the loop the train's nose is at server time `now`.
-- Wrapped first: server time is ~1.8 billion seconds, too big for exact distances otherwise.
function MonorailRules.headAt(now)
	if #stops == 0 then return (now % (LENGTH / Mono.speed)) * Mono.speed end
	local t = now % period
	for _, stop in ipairs(stops) do
		if t < stop.leave + stop.travel then
			local m, a, top, up = math.max(t - stop.leave, 0), Mono.brake, stop.top, stop.speedUp
			local gone = if m < up then a * m * m / 2
				elseif m < stop.travel - up then top * up / 2 + top * (m - up)
				else stop.length - a * (stop.travel - m) ^ 2 / 2
			return (stop.head + gone) % LENGTH
		end
	end
	return stops[1].head
end

-- Each car's CFrame (middle of its box, looking the way the train goes) and size (width, height, length) at server
-- time `now`. Both ends of a car sit on the line, so the cars bend round curves one by one like a real train.
function MonorailRules.cars(now)
	local head = MonorailRules.headAt(now)
	local out, behind = {}, 0
	for i, car in ipairs(Mono.cars) do
		local size = Vector3.new(car.size[1], car.size[2], car.size[3])
		local front, back = MonorailRules.pointAt(head - behind), MonorailRules.pointAt(head - behind - size.Z)
		local y = Mono.rug_top + Track.track_top - Mono.skirt_below_top + size.Y / 2
		local middle = (front + back) / 2 + Vector3.new(0, y, 0)
		out[i] = { cframe = CFrame.lookAt(middle, middle + (front - back)), size = size, turned = car.turned }
		behind += size.Z
	end
	return out
end

-- Which car (index) a plane is touching, or nil, from points on the plane: its middle, or every corner of its parts
-- (Alan 2026-10-18: a wing or the tail touching the train counts, not only the plane's middle). Also the world
-- normal of the face it came in through (the way out), so a touch scrapes like a building wall: traced back along
-- the plane's motion against that car (`velocity` and `carVelocities`, world), else the nearest face. Where two cars
-- meet is inside the train, never a face (Alan 2026-10-18: a wing near a joint was taken for the next car's front).
local AXES = { "X", "Y", "Z" }
function MonorailRules.hit(cars, points, velocity, carVelocities)
	if typeof(points) == "Vector3" then points = { points } end
	local hitCar, deepest, normal = nil, -1, nil
	for i, car in ipairs(cars) do
		local half = car.size / 2 + Vector3.one * Mono.plane_margin
		local moving = velocity and carVelocities and car.cframe:VectorToObjectSpace(velocity - carVelocities[i])
		for _, position in points do
			local p = car.cframe:PointToObjectSpace(position)
			if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
				local depth = { half.X - math.abs(p.X), half.Y - math.abs(p.Y), half.Z - math.abs(p.Z) }
				-- The front (-Z) of every car but the first, and the back of every car but the last, are joints.
				local joint = (p.Z < 0 and i > 1) or (p.Z >= 0 and i < #cars)
				local least = math.min(depth[1], depth[2], joint and math.huge or depth[3])
				if least > deepest then
					local axis, soonest = nil, math.huge
					for k, name in AXES do
						local v = moving and moving[name] or 0
						if not (k == 3 and joint) and v ~= 0 and (p[name] >= 0) == (v < 0) and depth[k] / math.abs(v) < soonest then
							axis, soonest = k, depth[k] / math.abs(v)
						end
					end
					axis = axis or (depth[1] == least and 1 or depth[2] == least and 2 or 3)
					local unit = ({ Vector3.xAxis, Vector3.yAxis, Vector3.zAxis })[axis]
					hitCar, deepest, normal = i, least, car.cframe:VectorToWorldSpace(unit * (p[AXES[axis]] >= 0 and 1 or -1))
				end
			end
		end
	end
	return hitCar, normal
end

-- A car's velocity at server time `now` (studs/s), for judging how hard it runs into a plane.
function MonorailRules.velocity(index, now)
	return (MonorailRules.cars(now)[index].cframe.Position - MonorailRules.cars(now - 0.1)[index].cframe.Position) / 0.1
end

return MonorailRules
