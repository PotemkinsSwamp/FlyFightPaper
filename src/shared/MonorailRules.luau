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

-- Each car's CFrame (middle of its box, looking the way the train goes) and size (width, height, length) at server
-- time `now`. Both ends of a car sit on the line, so the cars bend round curves one by one like a real train.
-- Wrapped first: server time is ~1.8 billion seconds, too big for exact distances otherwise.
function MonorailRules.cars(now)
	local head = (now % (LENGTH / Mono.speed)) * Mono.speed
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

-- Which car (index) a plane whose middle is at `position` is touching, or nil.
function MonorailRules.hit(cars, position)
	for i, car in ipairs(cars) do
		local p, half = car.cframe:PointToObjectSpace(position), car.size / 2 + Vector3.one * Mono.plane_margin
		if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then return i end
	end
	return nil
end

return MonorailRules
