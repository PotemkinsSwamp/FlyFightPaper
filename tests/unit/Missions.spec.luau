local Game = game.ReplicatedStorage.FlyFightPaper
local Missions = require(Game.Shared.Missions)
local Config = require(Game.Generated.Missions)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local DAY = 86400
local JAN_1 = 1704067200 -- Monday 2024-01-01 00:00:00 UTC
local OWNED = {"paper_pellet", "standard_body"}
local DAILY = {"easy", "medium", "hard"}
local WEEKLY = {"two_day", "three_day", "five_day"}

local function total(tier, action, count, condition)
	local mission = {tier = tier, kind = "total", action = action, count = count, progress = 0, claimed = false}
	for key, value in condition or {} do mission[key] = value end
	return mission
end

local function feat(tier, action, name, threshold, count)
	return {
		tier = tier, kind = "feat", action = action, feat = name, threshold = threshold,
		count = count, progress = 0, claimed = false,
	}
end

local function stateAt(at)
	local state = Missions.defaults()
	state.day = (at or JAN_1) // DAY
	state.week = (state.day + 3) // 7
	state.daily = {total("easy", "folds", 12), total("medium", "assists", 14), total("hard", "damage", 5400)}
	state.weekly = {total("two_day", "folds", 70), total("three_day", "wins", 3), total("five_day", "paper", 8600)}
	return state
end

local function summary(fields)
	local match = {
		eligible = true, completedAt = JAN_1, mode = "FFA", folds = 0, assists = 0, damage = 0,
		paper = 0, seconds = 0, wins = 0, top3 = 0, targets = 0, boosts = 0, zone_points = 0,
		zone_folds = 0, deaths = 10, best_life = 0, byGear = {},
	}
	for key, value in fields or {} do match[key] = value end
	return match
end

local function gearStats(fields)
	local stats = {folds = 0, assists = 0, damage = 0, seconds = 0}
	for key, value in fields do stats[key] = value end
	return stats
end

local function equal(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then return left == right end
	for key, value in left do
		if not equal(value, right[key]) then return false end
	end
	for key in right do
		if left[key] == nil then return false end
	end
	return true
end

local function roundCount(raw)
	local step
	if raw < 20 then step = 1
	elseif raw < 200 then step = 5
	elseif raw < 1000 then step = 50
	elseif raw < 10000 then step = 100
	else step = 500 end
	return math.max(1, math.floor(raw / step + 0.5) * step)
end

local function checkList(list, tiers, owned)
	local daily = tiers == DAILY
	local actions, modeCount = {}, 0
	assert(#list == #tiers)
	for index, mission in list do
		local tier = tiers[index]
		assert(mission.tier == tier and not actions[mission.action])
		actions[mission.action] = true
		assert(mission.progress == 0 and mission.claimed == false)
		local multiplier = 1
		if mission.gear then
			assert(table.find(owned, mission.gear) and not mission.mode and not mission.feat)
			assert(table.find({"folds", "assists", "damage", "minutes"}, mission.action))
			multiplier = 0.5
		elseif mission.mode then
			assert(index < #tiers and table.find({"FFA", "TDM", "CONTROL"}, mission.mode))
			assert(not mission.feat)
			modeCount += 1
			multiplier = if daily then 0.5 else 1 / 3
		end
		if mission.action == "wins" or mission.action == "top3" then
			assert((not daily or tier == "hard") and not mission.gear and not mission.mode and not mission.feat)
		elseif mission.action == "zone_points" or mission.action == "zone_folds" then
			assert(mission.mode == "CONTROL")
		end
		if mission.kind == "total" then
			local raw = Config.average[mission.action] * Config.tiers[tier].matches * multiplier
			assert(raw >= 0.75 and mission.count == roundCount(raw))
		else
			assert(mission.kind == "feat" and not mission.gear and not mission.mode)
			assert(mission.count == (if daily then 1 else ({3, 5, 7})[index]))
			local target = if daily then tier else "easy"
			if mission.feat == "one_match" then
				assert(table.find({"folds", "assists", "damage", "paper", "boosts", "targets"}, mission.action))
				local factors = {easy = 0.75, medium = 1, hard = 1.25}
				assert(mission.threshold == roundCount(Config.average[mission.action] * factors[target]))
			elseif mission.feat == "best_life" then
				assert(mission.action == "best_life" and target ~= "medium")
				assert(mission.threshold == (if target == "easy" then 3 else 4))
			else
				assert(mission.feat == "deaths" and mission.action == "deaths")
				assert(mission.threshold == ({easy = 8, medium = 6, hard = 4})[target])
			end
		end
	end
	assert(modeCount <= 1)
end

function Spec.run()
	local result, test = Suite.new()

	test("generated lists obey tier, action, condition and rounding rules across seeds", function()
		local seen, conditioned = {}, 0
		for seed = 1, 1024 do
			local state = assert(Missions.refresh(Missions.defaults(), JAN_1, OWNED, seed))
			assert(Missions.valid(state))
			checkList(state.daily, DAILY, OWNED)
			checkList(state.weekly, WEEKLY, OWNED)
			for _, list in {state.daily, state.weekly} do
				for _, mission in list do
					local condition = if mission.gear then "gear" elseif mission.mode then "mode" else mission.feat or "plain"
					local key = mission.tier .. ":" .. mission.action .. ":" .. condition
					seen[key] = mission
					if mission.gear or mission.mode or mission.feat == "one_match" then conditioned += 1 end
				end
			end
		end
		assert(seen["easy:folds:plain"].count == 12)
		assert(seen["medium:folds:plain"].count == 25)
		assert(seen["hard:damage:plain"].count == 5400)
		assert(seen["medium:folds:gear"].count == 12)
		assert(seen["five_day:folds:plain"].count == 155)
		assert(seen["five_day:best_life:best_life"].threshold == 3 and seen["five_day:best_life:best_life"].count == 7)
		assert(seen["hard:wins:plain"] and seen["hard:top3:plain"])
		assert(seen["two_day:wins:plain"] and seen["three_day:top3:plain"])
		assert(conditioned > 1024 * 6 * 0.29 and conditioned < 1024 * 6 * 0.37)
	end)

	test("refresh is deterministic, with stable picks when ownership order changes", function()
		local first = Missions.refresh(Missions.defaults(), JAN_1, OWNED, 5)
		local second = Missions.refresh(Missions.defaults(), JAN_1, {OWNED[2], OWNED[1]}, 5)
		assert(equal(first, second))
		local sameDay, paid = Missions.refresh(first, JAN_1 + DAY - 1, OWNED, 99)
		assert(equal(first, sameDay) and #paid == 0 and first.daily[1] ~= sameDay.daily[1])
		local nextDay = Missions.refresh(first, JAN_1 + DAY, OWNED, 5)
		local newSave = Missions.refresh(Missions.defaults(), JAN_1 + DAY, OWNED, 5)
		assert(nextDay.day == first.day + 1 and nextDay.week == first.week)
		assert(equal(first.weekly, nextDay.weekly) and equal(newSave.daily, nextDay.daily))
		local epoch = Missions.refresh(Missions.defaults(), 0, {}, 0)
		assert(Missions.valid(epoch) and epoch.day == 0 and epoch.week == 0)
		checkList(epoch.daily, DAILY, {})
		checkList(epoch.weekly, WEEKLY, {})
	end)

	test("totals, owned gear, seconds, wins and zone missions use their designated match stats", function()
		local state = stateAt()
		state.daily[2] = total("medium", "minutes", 7, {gear = OWNED[1]})
		state.daily[3] = total("hard", "matches", 3)
		state.weekly[1] = total("two_day", "zone_points", 700, {mode = "CONTROL"})
		state.weekly[2] = total("three_day", "folds", 110)
		state.weekly[3] = total("five_day", "wins", 5)
		local nextState, finished = Missions.applyMatch(state, summary({folds = 3, seconds = 600, zone_points = 900}))
		assert(#finished == 0 and nextState.daily[1].progress == 3 and nextState.daily[2].progress == 0)
		assert(nextState.weekly[1].progress == 0 and state.daily[1].progress == 0)
		nextState, finished = Missions.applyMatch(nextState, summary({
			mode = "CONTROL", folds = 4, seconds = 500, zone_points = 400,
			byGear = {[OWNED[1]] = gearStats({seconds = 419.5}), [OWNED[2]] = gearStats({seconds = 500})},
		}))
		assert(#finished == 0 and nextState.daily[2].progress == 419.5 and nextState.weekly[1].progress == 400)
		nextState, finished = Missions.applyMatch(nextState, summary({
			mode = "CONTROL", folds = 9, wins = 1, zone_points = 350,
			byGear = {[OWNED[1]] = gearStats({seconds = 0.5})},
		}))
		assert(#finished == 4 and nextState.dailiesDone == 3 and nextState.calendar == "1000000")
		assert(nextState.daily[1].progress == 16 and nextState.daily[2].progress == 420 and nextState.daily[3].progress == 3)
		assert(nextState.weekly[1].progress == 750 and nextState.weekly[2].progress == 16 and nextState.weekly[3].progress == 1)
		assert(finished[1].tier == "easy" and finished[4].tier == "two_day" and Missions.valid(nextState))
		finished[1].progress = 0
		assert(nextState.daily[1].progress == 16)
		-- (50, not 100: 100 more folds would honestly finish the 110-fold weekly, at 16 now)
		local again, repeated = Missions.applyMatch(nextState, summary({folds = 50}))
		assert(#repeated == 0 and again.daily[1].progress == 16 and again.dailiesDone == 3 and again.weekly[2].progress == 66)
	end)

	test("plain minutes, gear folds and mode-restricted matches count independently", function()
		local state = stateAt()
		state.daily[1] = total("easy", "minutes", 7)
		state.daily[2] = total("medium", "matches", 1, {mode = "TDM"})
		state.daily[3] = total("hard", "folds", 18, {gear = OWNED[1]})
		local nextState, finished = Missions.applyMatch(state, summary({
			mode = "CONTROL", seconds = 419, folds = 50, byGear = {[OWNED[1]] = gearStats({folds = 2})},
		}))
		assert(#finished == 0 and nextState.daily[1].progress == 419)
		assert(nextState.daily[2].progress == 0 and nextState.daily[3].progress == 2)
		nextState, finished = Missions.applyMatch(nextState, summary({mode = "TDM", seconds = 1}))
		assert(#finished == 2 and nextState.daily[1].progress == 420 and nextState.daily[2].progress == 1)
	end)

	test("feats count qualifying matches and include exact threshold values", function()
		local state = stateAt()
		state.daily = {
			feat("easy", "best_life", "best_life", 3, 1),
			feat("medium", "deaths", "deaths", 6, 1),
			feat("hard", "folds", "one_match", 15, 1),
		}
		state.weekly = {
			feat("two_day", "deaths", "deaths", 8, 3),
			feat("three_day", "damage", "one_match", 1400, 5),
			feat("five_day", "best_life", "best_life", 3, 7),
		}
		local nextState, finished = Missions.applyMatch(state, summary({best_life = 2, deaths = 9, folds = 14, damage = 1399.5}))
		assert(equal(nextState, state) and #finished == 0)
		nextState, finished = Missions.applyMatch(nextState, summary({best_life = 3, deaths = 8, folds = 15, damage = 1400}))
		assert(#finished == 2 and nextState.daily[2].progress == 0 and nextState.weekly[1].progress == 1)
		assert(nextState.weekly[2].progress == 1 and nextState.weekly[3].progress == 1)
		for count = 2, 7 do
			nextState, finished = Missions.applyMatch(nextState, summary({best_life = 3, deaths = 6, damage = 1400}))
			assert(nextState.weekly[1].progress == math.min(count, 3))
			assert(nextState.weekly[2].progress == math.min(count, 5))
			assert(nextState.weekly[3].progress == count)
		end
		assert(#finished == 1 and finished[1].tier == "five_day" and nextState.dailiesDone == 3)
	end)

	test("the live view adds running counts, leaves end-only ones for the end, and agrees with the saved result", function()
		local state = stateAt()
		state.daily = {total("easy", "boosts", 10), feat("medium", "folds", "one_match", 12, 1), feat("hard", "deaths", "deaths", 4, 1)}
		state.weekly = {total("two_day", "matches", 6), total("three_day", "wins", 3), total("five_day", "damage", 23400)}
		local running = summary({boosts = 4, folds = 5, damage = 900, deaths = 0, wins = 1, top3 = 1})
		local live, finished = Missions.applyMatch(state, running, true)
		assert(#finished == 0 and live.daily[1].progress == 4 and live.weekly[3].progress == 900)
		assert(live.daily[2].progress == 0 and live.daily[2].match == 5) -- read as "5 / 12" this match
		assert(live.daily[3].progress == 0 and live.daily[3].match == nil) -- "folded 4 or fewer" ticks at the end
		assert(live.weekly[1].progress == 0 and live.weekly[2].progress == 0 and state.daily[2].match == nil)
		local saved = Missions.applyMatch(state, running)
		assert(saved.daily[1].progress == live.daily[1].progress and saved.weekly[3].progress == live.weekly[3].progress)
		assert(saved.daily[3].progress == 1 and saved.weekly[1].progress == 1 and saved.weekly[2].progress == 1)
		assert(saved.daily[2].match == nil and Missions.valid(saved))
		live, finished = Missions.applyMatch(state, summary({boosts = 10, folds = 12}), true)
		assert(#finished == 2 and live.daily[1].progress == 10 and live.daily[2].progress == 1 and live.dailiesDone == 2)
	end)

	test("ineligible matches leave state alone and eligible matches require the refreshed day", function()
		local state = stateAt()
		local unchanged, finished = Missions.applyMatch(state, summary({eligible = false, folds = 1000, completedAt = JAN_1 + DAY}))
		assert(equal(unchanged, state) and #finished == 0 and unchanged ~= state and unchanged.daily[1] ~= state.daily[1])
		assert(not Missions.applyMatch(state, summary({completedAt = JAN_1 + DAY})))
		assert(not Missions.applyMatch(Missions.defaults(), summary()))
	end)

	test("the fixed card tracks 15 finished dailies and ticks Monday through Sunday", function()
		local state = stateAt()
		for offset = 0, 4 do
			local at = JAN_1 + offset * DAY
			state = Missions.refresh(state, at, {}, 17)
			state.daily = stateAt(at).daily
			assert(not Missions.claim(state, "fixed", 1))
			local finished
			state, finished = Missions.applyMatch(state, summary({completedAt = at, folds = 12, assists = 14, damage = 5400}))
			assert(#finished == 3 and state.dailiesDone == 3 * (offset + 1))
			assert(state.calendar == string.rep("1", offset + 1) .. string.rep("0", 6 - offset))
		end
		local claimed, reward = Missions.claim(state, "fixed")
		assert(equal(reward, {blue_ribbon = 1}) and claimed.fixedClaimed and not state.fixedClaimed)
		assert(not Missions.claim(claimed, "fixed", 1))
		local sunday = JAN_1 + 6 * DAY
		state = Missions.refresh(claimed, sunday, {}, 17)
		state.daily = stateAt(sunday).daily
		state = Missions.applyMatch(state, summary({completedAt = sunday, folds = 12}))
		assert(state.dailiesDone == 15 and state.calendar == "1111101" and state.fixedClaimed)
	end)

	test("claims return the configured rewards once and refuse unfinished or invalid cards", function()
		local state = stateAt()
		assert(not Missions.claim(state, "daily", 1) and not Missions.claim(state, "weekly", 1))
		assert(not Missions.claim(state, "other", 1) and not Missions.claim(state, "weekly", 4))
		local dailyRewards = {{paper = 100, xp = 150}, {paper = 200, xp = 250}, {paper = 300, xp = 400}}
		local weeklyRewards = {{paper = 2000}, {sticker = 1}, {sticker = 1, paper = 2000}}
		for list, rewards in {daily = dailyRewards, weekly = weeklyRewards} do
			for index, expected in rewards do
				local mission = state[list][index]
				mission.progress = mission.count
				local nextState, reward = Missions.claim(state, list, index)
				assert(equal(reward, expected) and nextState[list][index].claimed and not mission.claimed)
				assert(not Missions.claim(nextState, list, index))
				reward.paper = 999
				local _, freshReward = Missions.claim(state, list, index)
				assert(equal(freshReward, expected))
			end
		end
	end)

	test("daily swaps share the free, 150, 300 and 450 prices across the list", function()
		local state = stateAt()
		local slots = {1, 3, 2, 1}
		for swapNumber, expected in {0, 150, 300, 450} do
			local index = slots[swapNumber]
			local original = state.daily[index]
			assert(Missions.swapPrice(state, "daily", index) == expected)
			local swapped, price = Missions.swap(state, "daily", index, OWNED, 12)
			assert(price == expected and swapped.dailySwaps == swapNumber and swapped.weeklySwaps == 0)
			assert(swapped.daily[index].tier == original.tier and swapped.daily[index].action ~= original.action)
			assert(swapped.daily[index].progress == 0 and Missions.valid(swapped))
			assert(state.dailySwaps == swapNumber - 1 and state.daily[index] == original)
			state = swapped
		end
		assert(not Missions.swapPrice(state, "daily", 1) and not Missions.swap(state, "daily", 1, OWNED, 12))
	end)

	test("weekly swaps share the escalating prices across tier rewards and stop after three", function()
		local state = stateAt()
		local prices = {{500, 1000, 1500}, {750, 1500, 2250}, {1250, 2500, 3750}}
		for swapNumber = 1, 3 do
			for index, tierPrices in prices do
				assert(Missions.swapPrice(state, "weekly", index) == tierPrices[swapNumber])
			end
			local nextState, price = Missions.swap(state, "weekly", swapNumber, OWNED, 23)
			assert(price == prices[swapNumber][swapNumber] and nextState.weeklySwaps == swapNumber and nextState.dailySwaps == 0)
			assert(nextState.weekly[swapNumber].action ~= state.weekly[swapNumber].action and Missions.valid(nextState))
			state = nextState
		end
		assert(not Missions.swapPrice(state, "weekly", 1) and not Missions.swap(state, "weekly", 2, {}, 1))
	end)

	test("swaps exclude every current action and refuse fixed, finished and claimed cards", function()
		local state = stateAt()
		state.daily[1] = total("easy", "zone_folds", 3, {mode = "CONTROL"})
		state.weekly[1] = total("two_day", "zone_folds", 10, {mode = "CONTROL"})
		for _, list in {"daily", "weekly"} do
			for index = 1, 3 do
				for seed = 1, 32 do
					local swapped = Missions.swap(state, list, index, OWNED, seed)
					local again = Missions.swap(state, list, index, {OWNED[2], OWNED[1]}, seed)
					assert(Missions.valid(swapped) and equal(swapped, again))
					for _, old in state[list] do assert(swapped[list][index].action ~= old.action) end
				end
			end
		end
		state.daily[1].progress = state.daily[1].count
		assert(not Missions.swapPrice(state, "daily", 1) and not Missions.swapPrice(state, "fixed", 1))
		state.daily[1].claimed = true
		assert(not Missions.swap(state, "daily", 1, OWNED, 1))
	end)

	test("daily rollover pays unclaimed finished dailies and preserves weekly progress", function()
		local state = stateAt()
		state.daily[1].progress = 12
		state.daily[2].progress, state.daily[2].claimed = 14, true
		state.weekly[1].progress = 70
		state.dailySwaps, state.weeklySwaps, state.dailiesDone, state.calendar = 4, 2, 2, "1000000"
		local nextState, paid = Missions.refresh(state, JAN_1 + DAY, OWNED, 9)
		assert(equal(paid, {{paper = 100, xp = 150}}) and nextState.dailySwaps == 0)
		assert(nextState.weeklySwaps == 2 and equal(nextState.weekly, state.weekly))
		assert(nextState.dailiesDone == 2 and nextState.calendar == "1000000" and state.dailySwaps == 4)
		checkList(nextState.daily, DAILY, OWNED)
		local _, again = Missions.refresh(nextState, JAN_1 + DAY, OWNED, 9)
		assert(#again == 0 and not Missions.refresh(nextState, JAN_1, OWNED, 9))
	end)

	test("Monday rollover pays both expired lists and the completed fixed card, then resets the week", function()
		local sunday, monday = JAN_1 + 6 * DAY, JAN_1 + 7 * DAY
		local state = stateAt(sunday)
		state.daily[3].progress = 5400
		state.weekly[1].progress, state.weekly[1].claimed = 70, true
		state.weekly[3].progress = 8600
		state.dailiesDone, state.calendar, state.weeklySwaps, state.dailySwaps = 15, "1011111", 3, 4
		local before, early = Missions.refresh(state, monday - 1, OWNED, 41)
		assert(equal(before, state) and #early == 0)
		local nextState, paid = Missions.refresh(state, monday, OWNED, 41)
		assert(equal(paid, {{paper = 300, xp = 400}, {paper = 2000, sticker = 1}, {blue_ribbon = 1}}))
		assert(nextState.day == state.day + 1 and nextState.week == state.week + 1)
		assert(nextState.dailySwaps == 0 and nextState.weeklySwaps == 0 and nextState.dailiesDone == 0)
		assert(nextState.calendar == "0000000" and not nextState.fixedClaimed and Missions.valid(nextState))
		checkList(nextState.weekly, WEEKLY, OWNED)
		state.fixedClaimed = true
		local _, onlyGenerated = Missions.refresh(state, monday, OWNED, 41)
		assert(#onlyGenerated == 2)
	end)

	test("refresh replaces lost gear for free at the same tier and keeps owned gear missions", function()
		local state = stateAt()
		state.daily[1] = total("easy", "folds", 6, {gear = OWNED[1]})
		state.daily[2] = total("medium", "assists", 7, {gear = OWNED[2]})
		state.weekly[1] = total("two_day", "minutes", 20, {gear = OWNED[1]})
		state.daily[1].progress, state.daily[2].progress, state.weekly[1].progress = 3, 2, 30
		state.dailySwaps, state.weeklySwaps = 4, 3
		local stillOwned = Missions.refresh(state, JAN_1, OWNED, 100)
		assert(equal(stillOwned, state))
		local nextState, paid = Missions.refresh(state, JAN_1, {OWNED[2]}, 100)
		assert(#paid == 0 and Missions.valid(nextState) and nextState.dailySwaps == 4 and nextState.weeklySwaps == 3)
		for _, list in {"daily", "weekly"} do
			local replacement = nextState[list][1]
			assert(replacement.tier == state[list][1].tier and replacement.action ~= state[list][1].action)
			assert(replacement.progress == 0 and not replacement.claimed and replacement.gear ~= OWNED[1])
			assert(equal(nextState[list][2], state[list][2]) and equal(nextState[list][3], state[list][3]))
		end
	end)

	test("finished gear cards stay claimable after losing gear and still pay at reset", function()
		local state = stateAt()
		state.daily[1] = total("easy", "folds", 6, {gear = OWNED[1]})
		state.daily[2] = total("medium", "assists", 7, {gear = OWNED[1]})
		state.daily[1].progress = 7
		state.daily[2].progress, state.daily[2].claimed = 7, true
		local refreshed, paid, changed = Missions.refresh(state, JAN_1, {}, 100)
		assert(equal(refreshed, state) and #paid == 0 and not changed)
		local claimed, reward = Missions.claim(refreshed, "daily", 1)
		assert(claimed.daily[1].claimed and equal(reward, {paper = 100, xp = 150}))
		local _, expired = Missions.refresh(refreshed, JAN_1 + DAY, {}, 100)
		assert(equal(expired, {{paper = 100, xp = 150}}))
	end)

	test("saved counts and thresholds remain valid after mission tuning changes", function()
		local state = stateAt()
		state.daily[1].count, state.daily[1].progress = 13, 11
		state.weekly[1] = feat("two_day", "best_life", "best_life", 3.5, 4)
		assert(Missions.valid(state))
		local same, paid = Missions.refresh(state, JAN_1, {}, 22)
		assert(equal(state, same) and #paid == 0)
		local nextDay = Missions.refresh(state, JAN_1 + DAY, {}, 22)
		assert(Missions.valid(nextDay) and equal(nextDay.weekly[1], state.weekly[1]))
	end)

	test("strict validation rejects malformed saves, cards and lists", function()
		assert(Missions.valid(Missions.defaults()) and Missions.valid(stateAt()))
		local edits = {
			function(s) s.extra = true end,
			function(s) s.day = -1 end,
			function(s) s.day = math.huge end,
			function(s) s.week += 1 end,
			function(s) s.dailySwaps = 5 end,
			function(s) s.weeklySwaps = 1.5 end,
			function(s) s.dailiesDone = 16 end,
			function(s) s.fixedClaimed = true end,
			function(s) s.fixedClaimed = 0 end,
			function(s) s.calendar = "0000002" end,
			function(s) s.calendar = "00000000" end,
			function(s) s.daily[2] = nil end,
			function(s) s.weekly[4] = s.weekly[3] end,
			function(s) s.daily[1].tier = "medium" end,
			function(s) s.daily[1].extra = true end,
			function(s) s.daily[1].progress = -1 end,
			function(s) s.daily[1].progress = 0 / 0 end,
			function(s) s.daily[1].progress = "12" end,
			function(s) s.daily[1].count = 0 end,
			function(s) s.daily[1].count = 13.5 end,
			function(s) s.daily[1].progress = math.huge end,
			function(s) s.daily[1].progress = 0.5 end,
			function(s) s.daily[1].claimed = "true" end,
			function(s) s.daily[1].claimed = true end,
			function(s) s.daily[1].threshold = 12 end,
			function(s) s.daily[1] = total("easy", "unknown", 1) end,
			function(s) s.daily[1] = total("easy", "deaths", 1) end,
			function(s) s.daily[1] = total("easy", "matches", 1, {mode = "unknown"}) end,
			function(s) s.daily[1] = total("easy", "folds", 6, {gear = ""}) end,
			function(s) s.daily[1] = total("easy", "folds", 6, {gear = OWNED[1], mode = "TDM"}) end,
			function(s) s.daily[2] = total("medium", "folds", 25) end,
			function(s) s.daily[2] = feat("medium", "best_life", "deaths", 3, 1) end,
			function(s) s.daily[2] = feat("medium", "best_life", "best_life", -1, 1) end,
			function(s) s.daily[2] = feat("medium", "best_life", nil, 3, 1) end,
			function(s) s.daily[2] = feat("medium", "deaths", "one_match", 3, 1) end,
			function(s) s.daily[2] = feat("medium", "assists", "one_match", 3, 1); s.daily[2].mode = "TDM" end,
			function(s) s.daily[2] = feat("medium", "deaths", "deaths", 3, 1); s.daily[2].progress = 2 end,
			function(s)
				s.daily[1] = total("easy", "zone_folds", 3, {mode = "CONTROL"})
				s.daily[2] = total("medium", "matches", 1, {mode = "FFA"})
			end,
		}
		for index, edit in edits do
			local state = stateAt()
			edit(state)
			assert(not Missions.valid(state), "invalid fixture " .. index .. " was accepted")
		end
		assert(not Missions.valid(nil) and not Missions.valid("save"))
	end)

	test("bad timestamps, seeds, owned gear and match data return a reason", function()
		local state = stateAt()
		local function rejected(value, reason)
			assert(value == nil and type(reason) == "string")
		end
		rejected(Missions.refresh(state, -1, OWNED, 1))
		rejected(Missions.refresh(state, 253402300800, OWNED, 1))
		rejected(Missions.refresh(state, JAN_1, OWNED, math.huge))
		rejected(Missions.refresh(state, JAN_1, {[2] = OWNED[1]}, 1))
		rejected(Missions.swap(state, "daily", 1, {true}, 1))
		rejected(Missions.swap(state, "weekly", 1, OWNED, 1.5))
		rejected(Missions.applyMatch(state, summary({wins = 2})))
		rejected(Missions.applyMatch(state, summary({mode = "unknown"})))
		rejected(Missions.applyMatch(state, summary({byGear = {[OWNED[1]] = gearStats({damage = -1})}})))
		rejected(Missions.claim(state, "fixed", 2))
		rejected(Missions.swapPrice(state, "daily", "1"))
	end)

	return result
end

return Spec
