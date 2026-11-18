local Progress = require(game.ReplicatedStorage.FlyFightPaper.Shared.ChestProgress)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local DAY = 86400
local JAN_1 = 1704067200 -- Monday 2024-01-01 00:00:00 UTC
local FEB_29 = 1709164800
local MAR_1 = 1709251200
local APR_1 = 1711929600
local JUN_1 = 1717200000

function Spec.run()
	local result, test = Suite.new()
	test("three eligible finishes in one week give exactly one Sticker chest", function()
		local initial = Progress.defaults()
		local p, a = Progress.complete(initial, JAN_1)
		assert(Progress.valid(initial) and Progress.valid(p) and initial.weekly.counts == "")
		assert(a.sticker == 0 and a.paper == 0 and a.blue_ribbon == 0 and a.golden_star == 0)
		p, a = Progress.complete(p, JAN_1)
		assert(a.sticker == 0)
		p, a = Progress.complete(p, JAN_1)
		assert(a.sticker == 1)
		p, a = Progress.complete(p, JAN_1 + 6 * DAY)
		assert(a.sticker == 0 and Progress.status(p, JAN_1 + 6 * DAY).mission.count == 3)
		local reset = Progress.status(p, JAN_1 + 7 * DAY)
		assert(reset.mission.count == 0 and reset.weekly.count == 1 and reset.daily.count == 1)
	end)
	test("midnight Monday at New Year can finish all three streak pairs", function()
		local p = Progress.complete(Progress.defaults(), JAN_1 - 1)
		local a
		p, a = Progress.complete(p, JAN_1)
		assert(a.paper == 1 and a.blue_ribbon == 1 and a.golden_star == 1 and a.sticker == 0)
		local status = Progress.status(p, JAN_1)
		assert(status.daily.count == 2 and status.weekly.count == 2 and status.monthly.count == 2)
		assert(status.daily.target == 2 and status.mission.target == 3 and status.mission.count == 1)
		p, a = Progress.complete(p, JAN_1 + 600)
		assert(a.paper == 0 and a.blue_ribbon == 0 and a.golden_star == 0)
		assert(Progress.status(p, JAN_1 + DAY).daily.count == 0)
	end)
	test("February 29 counts as a day and March starts the next calendar month", function()
		local p = Progress.complete(Progress.defaults(), FEB_29 - DAY)
		local a
		p, a = Progress.complete(p, FEB_29)
		assert(a.paper == 1 and a.golden_star == 0)
		p, a = Progress.complete(p, MAR_1)
		assert(a.paper == 0 and a.golden_star == 1)
		p, a = Progress.complete(p, APR_1)
		assert(a.golden_star == 0 and Progress.status(p, APR_1).monthly.count == 1)
		assert(Progress.status(p, JUN_1).monthly.count == 0)
		p, a = Progress.complete(p, JUN_1)
		assert(a.golden_star == 0 and a.paper == 0 and a.blue_ribbon == 0)
	end)
	test("late completions can join days and finish a past mission without rolling back this week", function()
		local p = Progress.complete(Progress.defaults(), JAN_1)
		local a
		p, a = Progress.complete(p, JAN_1 + 2 * DAY)
		assert(a.paper == 0)
		p, a = Progress.complete(p, JAN_1 + DAY)
		assert(a.paper == 1 and a.sticker == 1)
		p, a = Progress.complete(p, JAN_1 + 3 * DAY)
		assert(a.paper == 1 and a.sticker == 0)
		local mon = JAN_1 + 7 * DAY
		p, a = Progress.complete(p, mon)
		assert(a.blue_ribbon == 1 and a.paper == 0)
		p, a = Progress.complete(p, JAN_1 + 4 * DAY)
		assert(a.sticker == 0 and Progress.status(p, mon).mission.count == 1)
		local q = Progress.complete(Progress.defaults(), mon)
		for i = 1, 3 do
			q, a = Progress.complete(q, JAN_1 + i)
			assert(a.sticker == (if i == 3 then 1 else 0))
		end
		assert(Progress.status(q, mon).mission.count == 1)
	end)
	test("an earlier historical run awards only genuinely new pairs in either delivery order", function()
		local forwards, backwards = Progress.defaults(), Progress.defaults()
		local layout = {0, 1, 3, 4, 5, 6, 8, 11, 12}
		local forwardTotal, backwardTotal = 0, 0
		for i = 1, #layout do
			local a, b
			forwards, a = Progress.complete(forwards, JAN_1 + layout[i] * DAY)
			backwards, b = Progress.complete(backwards, JAN_1 + layout[#layout + 1 - i] * DAY)
			forwardTotal += a.paper
			backwardTotal += b.paper
		end
		assert(forwardTotal == 4 and backwardTotal == forwardTotal)
		for name, track in forwards do
			assert(track.counts == backwards[name].counts and track.last == backwards[name].last)
		end
	end)
	test("window rollover preserves long streak parity and old events cannot reset current progress", function()
		local p = Progress.defaults()
		for day = 1, 80 do
			local a
			p, a = Progress.complete(p, JAN_1 + day * DAY)
			assert(a.paper == (if day % 2 == 0 then 1 else 0) and Progress.valid(p))
		end
		local late, a = Progress.complete(p, JAN_1)
		assert(late.daily.counts == p.daily.counts and late.daily.last == p.daily.last and a.paper == 0)
		local q = Progress.complete(p, JAN_1 + 1024 * DAY)
		assert(Progress.valid(q) and Progress.status(q, JAN_1 + 1024 * DAY).daily.count == 1)
	end)
	test("invalid saves or timestamps cannot grant rewards", function()
		local p = Progress.defaults()
		assert(not Progress.complete(p, -1) and not Progress.complete(p, 1.5))
		assert(not Progress.complete(p, math.huge) and not Progress.complete(p, 253402300800))
		assert(Progress.valid(Progress.complete(p, 0)))
		p.daily.counts = "9"
		assert(not Progress.valid(p) and not Progress.complete(p, JAN_1))
	end)
	return result
end

return Spec
