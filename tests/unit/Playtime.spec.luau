local Root = game.ReplicatedStorage.FlyFightPaper
local Playtime = require(Root.Shared.PlaytimeRules)
local Config = require(Root.Generated.Economy).playtime
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}

function Spec.run()
	local result, test = Suite.new()
	local B, CAP = Config.box_seconds, Playtime.CAP
	test("a box is earned every box_seconds up to the cap", function()
		assert(Playtime.BOX_COUNT == 16 and CAP == 16 * B)
		for seconds, boxes in pairs({[0] = 0, [B - 1] = 0, [B] = 1, [CAP] = 16, [CAP * 10] = 16}) do
			assert(Playtime.earned(seconds) == boxes)
		end
	end)
	test("adding time preserves claimed boxes, reports new boxes and caps the total", function()
		local state = table.freeze({day = 12, seconds = CAP - 50, taken = 1})
		local added, earned = Playtime.add(state, 100)
		assert(added.day == 12 and added.seconds == CAP and added.taken == 1)
		assert(#earned == 1 and earned[1] == 16 and state.seconds == CAP - 50)
		local capped, noBoxes = Playtime.add(added, 1)
		assert(capped ~= added and capped.seconds == CAP and #noBoxes == 0)
	end)
	test("one update reports every crossed box threshold in order", function()
		-- Raise the usual limit only for this case, so one add crosses three boxes.
		local limit = Config.max_add_seconds
		Config.max_add_seconds = 3 * B
		local ok, err = pcall(function()
			local added, earned = Playtime.add({day = 12, seconds = B - 1, taken = 0}, 3 * B)
			assert(added.seconds == 4 * B - 1 and #earned == 3)
			assert(earned[1] == 1 and earned[2] == 2 and earned[3] == 3)
		end)
		Config.max_add_seconds = limit
		assert(ok, err)
	end)
	test("only bounded whole seconds can be added", function()
		local state = Playtime.fresh(12)
		for _, seconds in ipairs({0, -1, Config.max_add_seconds + 1, 1.5, "10", false, 0/0, math.huge}) do
			local added, why = Playtime.add(state, seconds)
			assert(added == nil and why == "invalid_seconds")
		end
		local added, why = Playtime.add(state, nil)
		assert(added == nil and why == "invalid_seconds" and state.seconds == 0)
	end)
	test("the same day keeps its chart, a newer day starts fresh, and an older day is stale", function()
		local state = table.freeze({day = 12, seconds = B, taken = 1})
		assert(Playtime.forDay(state, 12) == state)
		local nextDay = Playtime.forDay(state, 13)
		assert(nextDay.day == 13 and nextDay.seconds == 0 and nextDay.taken == 0)
		local older, why = Playtime.forDay(state, 11)
		assert(older == nil and why == "stale_day")
	end)
	test("only earned, valid boxes can be taken and each box has its own bit", function()
		local state = table.freeze({day = 12, seconds = 2 * B, taken = 0})
		assert(Playtime.canTake(state, 2) and not Playtime.isTaken(state, 2))
		local taken = assert(Playtime.take(state, 2))
		assert(taken.taken == 2 and taken.day == 12 and taken.seconds == 2 * B and state.taken == 0)
		assert(Playtime.isTaken(taken, 2) and not Playtime.isTaken(taken, 1))
		for box, expected in pairs({[2] = "taken", [3] = "not_earned", [0] = "invalid_box", [17] = "invalid_box", [1.5] = "invalid_box"}) do
			local canTake, why = Playtime.canTake(taken, box)
			assert(canTake == false and why == expected)
			local claimed, takeError = Playtime.take(taken, box)
			assert(claimed == nil and takeError == expected)
		end
		local full = assert(Playtime.take({day = 12, seconds = CAP, taken = 0}, 16))
		assert(full.taken == 32768 and Playtime.isTaken(full, 16))
	end)
	test("ready counts unclaimed boxes and nextBox points to the next threshold", function()
		local fresh = Playtime.fresh(12)
		local box, seconds = Playtime.nextBox(fresh)
		assert(Playtime.ready(fresh) == 0 and box == 1 and seconds == B)
		local state = {day = 12, seconds = 2 * B + 1, taken = 2}
		box, seconds = Playtime.nextBox(state)
		assert(Playtime.ready(state) == 1 and box == 3 and seconds == B - 1)
		local full = {day = 12, seconds = CAP, taken = 65534}
		assert(Playtime.ready(full) == 1 and Playtime.nextBox(full) == nil)
	end)
	test("the chart uses the configured prizes and counts only active match time", function()
		assert(Playtime.prize(1).paper == 100 and Playtime.prize(2).xp_seconds == 300)
		assert(Playtime.prize(4).paper_seconds == 900 and Playtime.prize(12).xp_seconds == 1800)
		assert(Playtime.prize(16).chest == true and Playtime.prize(17) == nil)
		assert(Playtime.counts(true, 0) and Playtime.counts(true, 119.999))
		assert(not Playtime.counts(true, 120) and not Playtime.counts(true, 121))
		assert(not Playtime.counts(false, 0) and not Playtime.counts(1, 0))
	end)
	test("the wheel uses half-open ranges and rejects rolls outside zero to one", function()
		assert(Playtime.wheelIndex(0) == 1 and Playtime.wheelIndex(0.9999) == 6)
		for index, edge in ipairs({0.30, 0.57, 0.82, 0.92, 0.98}) do
			assert(Playtime.wheelIndex(edge - 1e-9) == index)
			assert(Playtime.wheelIndex(edge) == index + 1)
		end
		for _, invalid in ipairs({1, -0.1, 0/0, "0.3", false, math.huge}) do
			assert(Playtime.wheelIndex(invalid) == nil)
		end
		assert(Playtime.wheelIndex(nil) == nil)
	end)
	test("the wheel shows six prizes in order and its odds add up to 100 percent", function()
		local wheel = Playtime.wheel()
		local sum = 0
		for index, percent in ipairs({30, 27, 25, 10, 6, 2}) do
			assert(wheel[index].weight == percent and wheel[index].percent == percent)
			sum += wheel[index].percent
		end
		assert(#wheel == 6 and sum == 100)
		assert(wheel[1].prize.paper == 3000 and wheel[2].prize.xp_seconds == 3600)
		assert(wheel[3].prize.chest == "sticker" and wheel[4].prize.paper == 5000)
		assert(wheel[5].prize.chest == "blue_ribbon" and wheel[6].prize.chest == "golden_star")
	end)
	test("the chest pays the chosen sure prize or wheel slice", function()
		local paper, paperIndex = Playtime.chestPrize("paper")
		assert(paper.paper == 3000 and paperIndex == nil)
		local boosts, boostIndex = Playtime.chestPrize("boosts")
		assert(boosts.paper_seconds == 3600 and boosts.xp_seconds == 3600 and boostIndex == nil)
		local spin, index = Playtime.chestPrize("spin", 0.8)
		assert(spin.chest == "sticker" and index == 3)
		local invalid, why = Playtime.chestPrize("other")
		assert(invalid == nil and why == "invalid_choice")
		local noRoll, rollError = Playtime.chestPrize("spin", 1)
		assert(noRoll == nil and rollError == "invalid_roll")
	end)
	test("permanent passes convert only their own boosts to whole Paper", function()
		local paper = table.freeze({paper = 100})
		local paperCopy = Playtime.covered(paper, true, true)
		assert(paperCopy ~= paper and paperCopy.paper == 100)
		local prize = table.freeze({paper = 100, paper_seconds = 900, xp_seconds = 300})
		local both = Playtime.covered(prize, true, true)
		assert(both.paper == 433 and both.paper_seconds == nil and both.xp_seconds == nil)
		local paperPass = Playtime.covered(prize, true, false)
		assert(paperPass.paper == 350 and paperPass.paper_seconds == nil and paperPass.xp_seconds == 300)
		local xpPass = Playtime.covered(prize, false, true)
		assert(xpPass.paper == 183 and xpPass.paper_seconds == 900 and xpPass.xp_seconds == nil)
		assert(prize.paper == 100 and prize.paper_seconds == 900 and prize.xp_seconds == 300)
	end)
	return result
end

return Spec
