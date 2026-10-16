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
	test("the train moves forward at its speed, also on huge server times", function()
		local a, b = Rules.cars(1e9)[1].cframe, Rules.cars(1e9 + 1)[1].cframe
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
	end)
	return result
end
return Spec
