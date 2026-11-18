local Progress = require(game.ReplicatedStorage.FlyFightPaper.Shared.ChestProgress)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local DAY = 86400
local JAN_1 = 1704067200 -- Monday 2024-01-01 00:00:00 UTC
function Spec.run()
	local result, test = Suite.new()
	test("three eligible finishes in one UTC week give exactly one Sticker chest", function()
		local initial = Progress.defaults()
		local p = initial
		for match = 1, 4 do
			local awards
			p, awards = Progress.complete(p, JAN_1 + match * DAY)
			assert(Progress.valid(p) and awards.sticker == (if match == 3 then 1 else 0))
			assert(awards.paper == nil and awards.blue_ribbon == nil and awards.golden_star == nil)
		end
		assert(initial.weekly.counts == "")
		assert(Progress.status(p, JAN_1 + 6 * DAY).mission.count == 3)
		assert(Progress.status(p, JAN_1 + 7 * DAY).mission.count == 0)
	end)
	test("late settlement finishes a previous week's mission without changing this week", function()
		local p = Progress.complete(Progress.defaults(), JAN_1 + 7 * DAY)
		for match = 1, 4 do
			local awards
			p, awards = Progress.complete(p, JAN_1 + match * DAY)
			assert(awards.sticker == (if match == 3 then 1 else 0))
			assert(Progress.status(p, JAN_1 + 7 * DAY).mission.count == 1)
		end
		assert(Progress.status(p, JAN_1 + 5 * DAY).mission.count == 3)
	end)
	test("old completions cannot reopen a week after the settlement window expires", function()
		local p = Progress.complete(Progress.defaults(), JAN_1)
		local recent = JAN_1 + 32 * 7 * DAY
		p = Progress.complete(p, recent)
		local late, awards = Progress.complete(p, JAN_1)
		assert(Progress.valid(late) and late.weekly.counts == p.weekly.counts and awards.sticker == 0)
		assert(Progress.status(late, recent).mission.count == 1)
	end)
	test("invalid saves or timestamps cannot grant rewards", function()
		local p = Progress.defaults()
		assert(not Progress.complete(p, -1) and not Progress.complete(p, 1.5))
		assert(not Progress.complete(p, math.huge) and not Progress.complete(p, 253402300800))
		assert(Progress.valid(Progress.complete(p, 0)))
		p.weekly.counts = "9"
		assert(not Progress.valid(p) and not Progress.complete(p, JAN_1))
	end)
	return result
end
return Spec
