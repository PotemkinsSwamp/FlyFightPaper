local Config = require(script.Parent.Parent.Generated.Economy).playtime
local MathUtil = require(script.Parent.MathUtil)

local BOX_COUNT = 16
local CAP = BOX_COUNT * Config.box_seconds
local Rules = { BOX_COUNT = BOX_COUNT, CAP = CAP }

local wheelWeight = 0
for _, entry in ipairs(Config.chest.wheel) do
	wheelWeight += entry.weight
end

function Rules.fresh(day)
	return { day = day, seconds = 0, taken = 0 }
end

function Rules.forDay(state, day)
	if state.day == day then return state end
	if state.day < day then return Rules.fresh(day) end
	return nil, "stale_day"
end

function Rules.earned(seconds)
	return math.clamp(math.floor(seconds / Config.box_seconds), 0, BOX_COUNT)
end

function Rules.add(state, seconds)
	if not MathUtil.isInteger(seconds, 1, Config.max_add_seconds) then return nil, "invalid_seconds" end
	local total = math.min(CAP, state.seconds + seconds)
	local newlyEarned = {}
	for box = Rules.earned(state.seconds) + 1, Rules.earned(total) do
		table.insert(newlyEarned, box)
	end
	return { day = state.day, seconds = total, taken = state.taken }, newlyEarned
end

function Rules.isTaken(state, box)
	return MathUtil.isInteger(box, 1, BOX_COUNT) and bit32.btest(state.taken, bit32.lshift(1, box - 1))
end

function Rules.canTake(state, box)
	if not MathUtil.isInteger(box, 1, BOX_COUNT) then return false, "invalid_box" end
	if box > Rules.earned(state.seconds) then return false, "not_earned" end
	if Rules.isTaken(state, box) then return false, "taken" end
	return true
end

function Rules.take(state, box)
	local ok, reason = Rules.canTake(state, box)
	if not ok then return nil, reason end
	return { day = state.day, seconds = state.seconds, taken = bit32.bor(state.taken, bit32.lshift(1, box - 1)) }
end

function Rules.ready(state)
	local ready = 0
	for box = 1, Rules.earned(state.seconds) do
		if not Rules.isTaken(state, box) then ready += 1 end
	end
	return ready
end

function Rules.nextBox(state)
	local box = Rules.earned(state.seconds) + 1
	if box > BOX_COUNT then return nil end
	return box, box * Config.box_seconds - state.seconds
end

function Rules.prize(box)
	if MathUtil.isInteger(box, 1, BOX_COUNT) then return Config.boxes[box] end
	return nil
end

function Rules.counts(inMatch, idleSeconds)
	return inMatch == true and idleSeconds < Config.idle_seconds
end

function Rules.wheel()
	local wheel = {}
	for index, entry in ipairs(Config.chest.wheel) do
		wheel[index] = { prize = entry.prize, weight = entry.weight, percent = entry.weight * 100 / wheelWeight }
	end
	return wheel
end

function Rules.wheelIndex(roll)
	if not MathUtil.isFinite(roll) or roll < 0 or roll >= 1 then return nil end
	local cumulative = 0
	for index, entry in ipairs(Config.chest.wheel) do
		cumulative += entry.weight
		if roll < cumulative / wheelWeight then return index end
	end
end

function Rules.chestPrize(choice, roll)
	if choice == "paper" then return Config.chest.paper end
	if choice == "boosts" then return Config.chest.boosts end
	if choice == "spin" then
		local index = Rules.wheelIndex(roll)
		if not index then return nil, "invalid_roll" end
		return Config.chest.wheel[index].prize, index
	end
	return nil, "invalid_choice"
end

function Rules.covered(prize, permanentPaper, permanentXP)
	local covered = table.clone(prize)
	if permanentPaper and covered.paper_seconds then
		covered.paper = (covered.paper or 0) + math.floor(Config.boost_covered_paper_per_hour * covered.paper_seconds / 3600)
		covered.paper_seconds = nil
	end
	if permanentXP and covered.xp_seconds then
		covered.paper = (covered.paper or 0) + math.floor(Config.boost_covered_paper_per_hour * covered.xp_seconds / 3600)
		covered.xp_seconds = nil
	end
	return covered
end

return Rules
