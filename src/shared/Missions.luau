-- Pure mission rules. The caller supplies owned gear IDs and settles each eligible match once.
local Config = require(script.Parent.Parent.Generated.Missions)
local Missions = {}

local TIME = Config.time
local MAX_DAY = TIME.max_timestamp // TIME.seconds_per_day
local MAX_INTEGER = 2 ^ 53 - 1
local EMPTY_CALENDAR = string.rep("0", TIME.days_per_week)
local TIERS = {daily = {"easy", "medium", "hard"}, weekly = {"two_day", "three_day", "five_day"}}
local MODES = {"FFA", "TDM", "CONTROL"}
local GEAR_ACTIONS = {folds = true, assists = true, damage = true, minutes = true}
local MODE_ACTIONS = {
	folds = true, assists = true, damage = true, minutes = true, matches = true,
	paper = true, targets = true, boosts = true,
}
local ZONE_ACTIONS = {zone_points = true, zone_folds = true}
local ONE_MATCH_ACTIONS = {folds = true, assists = true, damage = true, paper = true, boosts = true, targets = true}
local CONDITIONS = {"gear", "mode", "one_match"}
local STATE_KEYS = {
	day = true, week = true, daily = true, weekly = true, dailySwaps = true, weeklySwaps = true,
	dailiesDone = true, fixedClaimed = true, calendar = true,
}
local MISSION_KEYS = {
	tier = true, kind = true, action = true, gear = true, mode = true, feat = true,
	threshold = true, count = true, progress = true, claimed = true,
}
local SUMMARY_KEYS = {
	eligible = true, completedAt = true, mode = true, folds = true, assists = true, damage = true,
	paper = true, seconds = true, wins = true, top3 = true, targets = true, boosts = true,
	zone_points = true, zone_folds = true, deaths = true, best_life = true, byGear = true,
}
local GEAR_KEYS = {folds = true, assists = true, damage = true, seconds = true}

local function friendly(value)
	for _, band in Config.rounding.bands do
		if band.under == nil or value < band.under then
			return math.max(Config.rounding.minimum, math.round(value / band.step) * band.step)
		end
	end
end

local function poolsFor(tier, list)
	local pools = {plain = {}, gear = {}, mode = {}, one_match = {}}
	local tuning = Config.tiers[tier]
	local isDaily = list == "daily"
	local modeMultiplier = if isDaily then Config.multipliers.daily_mode else Config.multipliers.weekly_mode
	local featTier = if isDaily then tier else "easy"
	local featCount = tuning.feat_matches or Config.feats.daily_count

	local function addTotal(pool, action, multiplier, mode)
		local raw = Config.average[action] * tuning.matches * multiplier
		if raw >= Config.offer_cutoff then
			table.insert(pool, {kind = "total", action = action, mode = mode, count = friendly(raw)})
		end
	end

	local function addFeat(pool, action, feat, threshold)
		if threshold ~= nil then
			table.insert(pool, {kind = "feat", action = action, feat = feat, threshold = threshold, count = featCount})
		end
	end

	local actions = {}
	for action in Config.average do
		table.insert(actions, action)
	end
	table.sort(actions)
	for _, action in actions do
		if ZONE_ACTIONS[action] then
			if tuning.allow_mode then addTotal(pools.mode, action, modeMultiplier, "CONTROL") end
		else
			addTotal(pools.plain, action, 1)
			if GEAR_ACTIONS[action] then addTotal(pools.gear, action, Config.multipliers.gear) end
			if tuning.allow_mode and MODE_ACTIONS[action] then
				for _, mode in MODES do
					addTotal(pools.mode, action, modeMultiplier, mode)
				end
			end
			if ONE_MATCH_ACTIONS[action] then
				addFeat(pools.one_match, action, "one_match", friendly(Config.average[action] * Config.feats.one_match[featTier]))
			end
		end
	end
	addFeat(pools.plain, "best_life", "best_life", Config.feats.best_life[featTier])
	addFeat(pools.plain, "deaths", "deaths", Config.feats.max_deaths[featTier])
	return pools
end

local POOLS = {}
for list, tiers in TIERS do
	for _, tier in tiers do
		POOLS[tier] = poolsFor(tier, list)
	end
end

local function weekOf(day)
	return (day + TIME.monday_offset) // TIME.days_per_week
end

local function plainTable(value)
	return type(value) == "table" and getmetatable(value) == nil
end

local function onlyKeys(value, keys)
	if not plainTable(value) then return false end
	for key in value do
		if not keys[key] then return false end
	end
	return true
end

local function numberInRange(value, maximum)
	return type(value) == "number" and value >= 0 and value <= maximum
end

local function wholeInRange(value, maximum)
	return numberInRange(value, maximum) and value % 1 == 0
end

local function gearId(value)
	return type(value) == "string" and value ~= ""
end

-- Owned is a dense array of eligible gear IDs. Sort unique IDs for stable seeded picks.
local function ownedGear(owned)
	if not plainTable(owned) then return nil end
	local ids, set = {}, {}
	local size, entries = #owned, 0
	for index, id in owned do
		if not wholeInRange(index, size) or index < 1 or not gearId(id) then return nil end
		entries += 1
		if not set[id] then
			set[id] = true
			table.insert(ids, id)
		end
	end
	if entries ~= size then return nil end
	table.sort(ids)
	return ids, set
end

local function validSeed(seed)
	return type(seed) == "number" and math.abs(seed) <= MAX_INTEGER and seed % 1 == 0
end

local function periodRandom(seed, period)
	-- Keep seed + period representable even at the upper edge of Random's seed range.
	if seed > MAX_INTEGER - period then
		return Random.new(-MAX_INTEGER + (period - (MAX_INTEGER - seed) - 1))
	end
	return Random.new(seed + period)
end

local function goal(mission)
	return if mission.action == "minutes" then mission.count * TIME.seconds_per_minute else mission.count
end

local function isFinished(mission)
	return mission.progress >= goal(mission)
end

local function validMission(mission, tier)
	if not onlyKeys(mission, MISSION_KEYS) or mission.tier ~= tier or type(mission.claimed) ~= "boolean" then
		return false
	end
	local condition = "plain"
	if mission.gear ~= nil then
		if not gearId(mission.gear) then return false end
		condition = "gear"
	elseif mission.mode ~= nil then
		condition = "mode"
	elseif mission.feat == "one_match" then
		condition = "one_match"
	end

	for _, shape in POOLS[tier][condition] do
		if mission.action == shape.action and mission.kind == shape.kind and mission.mode == shape.mode
			and mission.feat == shape.feat and mission.threshold == shape.threshold and mission.count == shape.count then
			local progress = mission.progress
			local validProgress
			if shape.kind == "feat" then
				validProgress = wholeInRange(progress, shape.count)
			elseif shape.action == "damage" or shape.action == "minutes" then
				validProgress = numberInRange(progress, MAX_INTEGER)
			else
				validProgress = wholeInRange(progress, MAX_INTEGER)
			end
			return validProgress and (not mission.claimed or isFinished(mission))
		end
	end
	return false
end

local function validList(list, tiers)
	for index in list do
		if not wholeInRange(index, #tiers) or index < 1 then return false end
	end
	local actions, hasMode = {}, false
	for index, tier in tiers do
		local mission = list[index]
		if not validMission(mission, tier) or actions[mission.action] then return false end
		if mission.mode then
			if hasMode then return false end
			hasMode = true
		end
		actions[mission.action] = true
	end
	return true
end

function Missions.defaults()
	return {
		day = 0, week = 0, daily = {}, weekly = {}, dailySwaps = 0, weeklySwaps = 0,
		dailiesDone = 0, fixedClaimed = false, calendar = EMPTY_CALENDAR,
	}
end

function Missions.valid(state)
	if not onlyKeys(state, STATE_KEYS) or not wholeInRange(state.day, MAX_DAY) or state.week ~= weekOf(state.day)
		or not wholeInRange(state.dailySwaps, #Config.swaps.daily_prices)
		or not wholeInRange(state.weeklySwaps, Config.swaps.weekly_limit)
		or not wholeInRange(state.dailiesDone, Config.fixed.target)
		or type(state.fixedClaimed) ~= "boolean" or (state.fixedClaimed and state.dailiesDone < Config.fixed.target)
		or type(state.calendar) ~= "string" or #state.calendar ~= TIME.days_per_week or state.calendar:find("[^01]")
		or not plainTable(state.daily) or not plainTable(state.weekly) then
		return false
	end
	if next(state.daily) == nil and next(state.weekly) == nil then
		return state.day == 0 and state.dailySwaps == 0 and state.weeklySwaps == 0 and state.dailiesDone == 0
			and state.calendar == EMPTY_CALENDAR
	end
	return validList(state.daily, TIERS.daily) and validList(state.weekly, TIERS.weekly)
end

local function copyState(state)
	local result = table.clone(state)
	for list in TIERS do
		result[list] = {}
		for index, mission in state[list] do
			result[list][index] = table.clone(mission)
		end
	end
	return result
end

local function chooseMission(tier, list, index, ids, random)
	local blocked, hasMode = {}, false
	for slot, mission in list do
		-- A replacement must also differ from the action already in its own slot.
		blocked[mission.action] = true
		hasMode = hasMode or (slot ~= index and mission.mode ~= nil)
	end

	local pools = POOLS[tier]
	local condition, candidates = "plain", nil
	if random:NextNumber() < Config.condition_chance then
		local available = {}
		for _, name in CONDITIONS do
			if (name ~= "gear" or #ids > 0) and (name ~= "mode" or not hasMode) then
				local shapes = {}
				for _, shape in pools[name] do
					if not blocked[shape.action] then table.insert(shapes, shape) end
				end
				if #shapes > 0 then table.insert(available, {name = name, shapes = shapes}) end
			end
		end
		if #available > 0 then
			local picked = available[random:NextInteger(1, #available)]
			condition, candidates = picked.name, picked.shapes
		end
	end
	if not candidates then
		candidates = {}
		for _, shape in pools.plain do
			if not blocked[shape.action] then table.insert(candidates, shape) end
		end
	end

	local mission = table.clone(candidates[random:NextInteger(1, #candidates)])
	mission.tier, mission.progress, mission.claimed = tier, 0, false
	if condition == "gear" then mission.gear = ids[random:NextInteger(1, #ids)] end
	return mission
end

local function refreshList(state, list, reset, ids, owned, random, paid)
	if reset then
		for _, mission in state[list] do
			if not mission.claimed and isFinished(mission) then
				table.insert(paid, table.clone(Config.tiers[mission.tier].reward))
			end
		end
		state[list] = {}
	end
	for index, tier in TIERS[list] do
		local mission = state[list][index]
		if not mission or (mission.gear and not owned[mission.gear]) then
			state[list][index] = chooseMission(tier, state[list], index, ids, random)
		end
	end
end

-- Rewards use the same flat chest IDs as ChestProgress and may also contain paper or xp.
function Missions.refresh(state, now, owned, seed)
	if not Missions.valid(state) then return nil, "invalid_mission_state" end
	if not wholeInRange(now, TIME.max_timestamp) then return nil, "invalid_time" end
	if not validSeed(seed) then return nil, "invalid_seed" end
	local ids, ownedSet = ownedGear(owned)
	if not ids then return nil, "invalid_owned_gear" end

	local day = now // TIME.seconds_per_day
	local week = weekOf(day)
	if day < state.day then return nil, "stale_period" end
	local empty = next(state.daily) == nil
	local newDay, newWeek = empty or day ~= state.day, empty or week ~= state.week
	local result, paid = copyState(state), {}
	refreshList(result, "daily", newDay, ids, ownedSet, periodRandom(seed, day), paid)
	refreshList(result, "weekly", newWeek, ids, ownedSet, periodRandom(seed, week), paid)
	if newDay then result.dailySwaps = 0 end
	if newWeek then
		if not result.fixedClaimed and result.dailiesDone >= Config.fixed.target then
			table.insert(paid, table.clone(Config.fixed.reward))
		end
		result.weeklySwaps, result.dailiesDone = 0, 0
		result.fixedClaimed, result.calendar = false, EMPTY_CALENDAR
	end
	result.day, result.week = day, week
	return result, paid
end

local function validGearStats(stats)
	return onlyKeys(stats, GEAR_KEYS) and wholeInRange(stats.folds, MAX_INTEGER)
		and wholeInRange(stats.assists, MAX_INTEGER) and numberInRange(stats.damage, MAX_INTEGER)
		and numberInRange(stats.seconds, MAX_INTEGER)
end

local function validSummary(summary)
	if not onlyKeys(summary, SUMMARY_KEYS) or type(summary.eligible) ~= "boolean"
		or not wholeInRange(summary.completedAt, TIME.max_timestamp) or not table.find(MODES, summary.mode)
		or not numberInRange(summary.damage, MAX_INTEGER) or not numberInRange(summary.seconds, MAX_INTEGER)
		or not wholeInRange(summary.wins, 1) or not wholeInRange(summary.top3, 1)
		or not plainTable(summary.byGear) then
		return false
	end
	for _, field in {"folds", "assists", "paper", "targets", "boosts", "zone_points", "zone_folds", "deaths", "best_life"} do
		if not wholeInRange(summary[field], MAX_INTEGER) then return false end
	end
	for id, stats in summary.byGear do
		if not gearId(id) or not validGearStats(stats) then return false end
	end
	return true
end

local function earnedProgress(mission, summary)
	if mission.mode and mission.mode ~= summary.mode then return 0 end
	if mission.kind == "feat" then
		local met
		if mission.feat == "deaths" then
			met = summary.deaths <= mission.threshold
		else
			met = summary[mission.action] >= mission.threshold
		end
		return if met then 1 else 0
	end
	if mission.action == "matches" then return 1 end
	local stats = summary
	if mission.gear then stats = summary.byGear[mission.gear] end
	local field = if mission.action == "minutes" then "seconds" else mission.action
	return if stats then stats[field] else 0
end

function Missions.applyMatch(state, summary)
	if not Missions.valid(state) then return nil, "invalid_mission_state" end
	if not validSummary(summary) then return nil, "invalid_match_summary" end
	local result, finished = copyState(state), {}
	if not summary.eligible then return result, finished end
	if next(state.daily) == nil or summary.completedAt // TIME.seconds_per_day ~= state.day then
		return nil, "refresh_required"
	end

	for _, list in {"daily", "weekly"} do
		for _, mission in result[list] do
			if not isFinished(mission) then
				mission.progress = math.min(MAX_INTEGER, mission.progress + earnedProgress(mission, summary))
				if isFinished(mission) then
					table.insert(finished, table.clone(mission))
					if list == "daily" then
						result.dailiesDone = math.min(Config.fixed.target, result.dailiesDone + 1)
						local weekday = (state.day + TIME.monday_offset) % TIME.days_per_week + 1
						result.calendar = result.calendar:sub(1, weekday - 1) .. "1" .. result.calendar:sub(weekday + 1)
					end
				end
			end
		end
	end
	return result, finished
end

local function atIndex(state, list, index)
	if (list == "daily" or list == "weekly") and wholeInRange(index, #TIERS[list]) and index > 0 then
		return state[list][index]
	end
	return nil
end

-- The fixed card is a singleton, so its index can be omitted.
function Missions.claim(state, list, index)
	if not Missions.valid(state) then return nil, "invalid_mission_state" end
	if list == "fixed" then
		if index ~= nil and index ~= 1 then return nil, "invalid_mission" end
		if state.fixedClaimed or state.dailiesDone < Config.fixed.target then return nil, "not_claimable" end
		local result = copyState(state)
		result.fixedClaimed = true
		return result, table.clone(Config.fixed.reward)
	end
	local mission = atIndex(state, list, index)
	if not mission then return nil, "invalid_mission" end
	if mission.claimed or not isFinished(mission) then return nil, "not_claimable" end
	local result = copyState(state)
	result[list][index].claimed = true
	return result, table.clone(Config.tiers[mission.tier].reward)
end

function Missions.swapPrice(state, list, index)
	if not Missions.valid(state) then return nil, "invalid_mission_state" end
	local mission = atIndex(state, list, index)
	if not mission then return nil, "invalid_mission" end
	if isFinished(mission) then return nil, "not_swappable" end
	if list == "daily" then
		local price = Config.swaps.daily_prices[state.dailySwaps + 1]
		if price == nil then return nil, "swap_limit" end
		return price
	end
	if state.weeklySwaps >= Config.swaps.weekly_limit then return nil, "swap_limit" end
	return Config.swaps.weekly_rate * Config.tiers[mission.tier].paper_value * (state.weeklySwaps + 1)
end

function Missions.swap(state, list, index, owned, seed)
	local price, reason = Missions.swapPrice(state, list, index)
	if price == nil then return nil, reason end
	if not validSeed(seed) then return nil, "invalid_seed" end
	local ids = ownedGear(owned)
	if not ids then return nil, "invalid_owned_gear" end
	local result = copyState(state)
	local counter = list .. "Swaps"
	local tier = result[list][index].tier
	result[list][index] = chooseMission(tier, result[list], index, ids, periodRandom(seed, state[counter]))
	result[counter] += 1
	return result, price
end

return Missions
