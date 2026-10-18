local Root = game:GetService("ReplicatedStorage").FlyFightPaper
local Rules = require(Root.Shared.MonorailRules)
local Track = require(Root.Generated.MonorailTrack)
local Mono = require(Root.Generated.Gameplay).world.monorail
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
function Spec.run()
	local result, test = Suite.new()
	local first = Vector3.new(Track.line[1][1], 0, Track.line[1][2])
	test("the track is one closed loop, and distances wrap round it", function()
		local last = Track.line[#Track.line]
		assert(last[1] == Track.line[1][1] and last[2] == Track.line[1][2], "the line should close on itself")
		assert(Rules.pointAt(0):FuzzyEq(first, 1e-3), "0 is the first point")
		assert(Rules.pointAt(Rules.length):FuzzyEq(first, 1e-3), "a whole lap comes back to the start")
		assert(Rules.pointAt(-10):FuzzyEq(Rules.pointAt(Rules.length - 10), 1e-3), "negative distances wrap")
	end)
	test("the cars sit nose to tail on the track, on top of the beam", function()
		local cars = Rules.cars(1000)
		assert(#cars == #Mono.cars, "one box per car")
		for i = 2, #cars do
			local gap = (cars[i - 1].cframe.Position - cars[i].cframe.Position).Magnitude
			local want = (cars[i - 1].size.Z + cars[i].size.Z) / 2
			assert(math.abs(gap - want) < 1, ("car %d is %.1f from the one ahead, want about %.1f"):format(i, gap, want))
		end
		local bottom = cars[1].cframe.Position.Y - cars[1].size.Y / 2
		local top = Mono.rug_top + Track.track_top
		assert(math.abs(top - bottom - Mono.skirt_below_top) < 1e-3, "the skirt hangs skirt_below_top under the track top")
	end)
	test("the train waits station_wait seconds with its middle in each station, then moves off smoothly", function()
		assert(#Rules.stops == #Track.stations and #Rules.stops == 2, "one stop per station")
		local lap = 1e9 - 1e9 % Rules.period                       -- a lap starting at a huge server time
		for _, stop in ipairs(Rules.stops) do
			local start = Rules.cars(lap + stop.arrive + 0.5)
			local finish = Rules.cars(lap + stop.leave - 0.5)
			assert(start[1].cframe.Position:FuzzyEq(finish[1].cframe.Position, 1e-2), "it stands still while it waits")
			local middle = start[2].cframe.Position * Vector3.new(1, 0, 1)
			local miss = math.huge                 -- how much further the middle car is than the track's nearest point
			for _, st in ipairs(Track.stations) do
				local station, track = Vector3.new(st[1], 0, st[2]), math.huge
				for s = 0, Rules.length, 1 do track = math.min(track, (Rules.pointAt(s) - station).Magnitude) end
				miss = math.min(miss, (middle - station).Magnitude - track)
			end
			assert(miss < 3, ("the middle car stops %.1f studs off the station's middle"):format(miss))
			local last = Rules.headAt(lap + stop.leave - 1)
			for t = stop.leave - 1, stop.leave + 10, 0.1 do         -- no jumps: never faster than its top speed
				local now = Rules.headAt(lap + t)
				local step = (now - last) % Rules.length
				assert(step <= Mono.speed * 0.1 + 1e-3, ("jumped %.2f studs in 0.1 s at %.1f s after leaving"):format(step, t - stop.leave))
				last = now
			end
			assert(Rules.headAt(lap + stop.leave + 10) ~= Rules.headAt(lap + stop.leave), "it has left after 10 s")
		end
	end)
	test("the train moves forward at its speed between stations, also on huge server times", function()
		local stop = Rules.stops[1]
		local cruise = 1e9 - 1e9 % Rules.period + stop.leave + stop.speedUp + 1
		local a, b = Rules.cars(cruise)[1].cframe, Rules.cars(cruise + 1)[1].cframe
		local moved = (b.Position - a.Position).Magnitude
		-- straight-line distance: a little under the speed when that second is spent on a curve
		assert(moved > Mono.speed * 0.9 and moved < Mono.speed + 0.5, ("moved %.2f in a second, want about %d"):format(moved, Mono.speed))
		assert((b.Position - a.Position).Unit:Dot(a.LookVector) > 0.95, "it moves the way it looks")
	end)
	test("a plane touching a car is hit; one beside or above it is not", function()
		local cars = Rules.cars(500)
		local car = cars[2].cframe
		local half = cars[2].size / 2
		assert(Rules.hit(cars, car.Position) == 2, "the middle of a car is a hit")
		assert(Rules.hit(cars, car * Vector3.new(half.X + Mono.plane_margin - 0.5, 0, 0)) == 2, "a wing tip's width away still hits")
		assert(Rules.hit(cars, car * Vector3.new(half.X + Mono.plane_margin + 1, 0, 0)) == nil, "just clear of the side")
		assert(Rules.hit(cars, car * Vector3.new(0, half.Y + Mono.plane_margin + 1, 0)) == nil, "just clear of the roof")
		local wingTip = car * Vector3.new(half.X + Mono.plane_margin - 0.5, 0, 0)
		assert(Rules.hit(cars, { car * Vector3.new(half.X + 6, 0, 0), wingTip }) == 2, "a wing tip in the car hits though the plane's middle is clear")
		local _, normal = Rules.hit(cars, car * Vector3.new(0, half.Y + Mono.plane_margin - 0.5, 0))
		assert(normal:Dot(car.UpVector) > 0.99, "skimming the roof scrapes the roof (its way out is up)")
		local _, front = Rules.hit(cars, cars[1].cframe * Vector3.new(0, 0, -(cars[1].size.Z / 2 + Mono.plane_margin - 0.5)))
		assert(front:Dot(cars[1].cframe.LookVector) > 0.99, "in front of the nose car the way out is forward")
	end)
	return result
end
return Spec
