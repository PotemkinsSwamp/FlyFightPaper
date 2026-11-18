-- UTC progress on reward-eligible match completions. The settlement that calls complete()
-- owns match idempotency; different matches can legitimately finish in the same second.
local ChestProgress = {}
local WINDOW = 32 -- Keep late results for 32 days, weeks or months independently.
local MAX_TIME = 253402300799 -- last whole second in calendar year 9999
local LIMITS = {daily = 1, weekly = 3, monthly = 1}
local AWARD = {daily = "paper", weekly = "blue_ribbon", monthly = "golden_star"}
local function empty()
	return {last = 0, counts = "", beforeOdd = false}
end

function ChestProgress.defaults()
	return {daily = empty(), weekly = empty(), monthly = empty()}
end

local function whole(value, high)
	return type(value) == "number" and value >= 0 and value <= high and value % 1 == 0
end

local function periods(at)
	local day = math.floor(at / 86400)
	local utc = DateTime.fromUnixTimestamp(at):ToUniversalTime()
	-- 1970-01-01 was Thursday, three days into its Monday-start week.
	return {daily = day, weekly = math.floor((day + 3) / 7), monthly = (utc.Year - 1970) * 12 + utc.Month - 1}
end

local LAST_DAY = math.floor(MAX_TIME / 86400)
local LAST_PERIOD = {daily = LAST_DAY, weekly = math.floor((LAST_DAY + 3) / 7), monthly = (9999 - 1970) * 12 + 11}
function ChestProgress.valid(progress)
	if type(progress) ~= "table" then return false end
	for name in progress do if not LIMITS[name] then return false end end
	for name, limit in LIMITS do
		local track = progress[name]
		if type(track) ~= "table" or not whole(track.last, LAST_PERIOD[name])
			or type(track.counts) ~= "string" or type(track.beforeOdd) ~= "boolean" then return false end
		for field in track do
			if field ~= "last" and field ~= "counts" and field ~= "beforeOdd" then return false end
		end
		if track.counts == "" then
			if track.last ~= 0 or track.beforeOdd then return false end
		else
			if #track.counts ~= math.min(WINDOW, track.last + 1) or track.counts:sub(-1) == "0"
				or track.counts:find("[^0-" .. limit .. "]") or (track.beforeOdd and track.last < WINDOW) then return false end
		end
	end
	if progress.daily.counts == "" then return progress.weekly.counts == "" and progress.monthly.counts == "" end
	local latest = periods(progress.daily.last * 86400)
	return progress.weekly.counts ~= "" and progress.weekly.last == latest.weekly
		and progress.monthly.counts ~= "" and progress.monthly.last == latest.monthly
end

-- Is the consecutive run finishing at this position odd? Retain one bit of the earlier
-- run at the window edge, so a long uninterrupted streak keeps its payout cadence.
local function oddThrough(counts, index, beforeOdd)
	local odd = beforeOdd
	for i = 1, index do
		odd = counts:byte(i) ~= 48 and not odd
	end
	return odd
end

local function advance(track, period)
	local newSize = math.min(WINDOW, period + 1)
	if track.counts == "" or period - track.last > WINDOW then
		return {last = period, counts = string.rep("0", newSize), beforeOdd = false}
	end
	if period <= track.last then return table.clone(track) end
	local distance = period - track.last
	local drop = #track.counts + distance - newSize
	return {
		last = period, counts = track.counts:sub(drop + 1) .. string.rep("0", distance),
		beforeOdd = oddThrough(track.counts, drop, track.beforeOdd),
	}
end

local function record(track, period, limit)
	local nextTrack = advance(track, period)
	local counts = nextTrack.counts
	local index = #counts - (nextTrack.last - period)
	if index < 1 then return nextTrack, false, false end
	local old = counts:byte(index) - 48
	if old == limit then return nextTrack, false, false end
	local pair = false
	if old == 0 then
		-- A late completion can connect runs on either side. Inserting one new active period
		-- creates one more pair exactly when at least one neighbouring run has odd length.
		local rightRun = counts:sub(index + 1):match("^[1-3]*")
		pair = oddThrough(counts, index - 1, nextTrack.beforeOdd) or #rightRun % 2 == 1
	end
	nextTrack.counts = counts:sub(1, index - 1) .. tostring(old + 1) .. counts:sub(index + 1)
	return nextTrack, pair, limit == 3 and old == 2
end

function ChestProgress.complete(progress, completedAt)
	if not whole(completedAt, MAX_TIME) then return nil, "invalid_match_time" end
	if not ChestProgress.valid(progress) then return nil, "invalid_chest_progress" end
	local nextProgress = {}
	local dates = periods(completedAt)
	local awards = {paper = 0, sticker = 0, blue_ribbon = 0, golden_star = 0}
	for name, limit in LIMITS do
		local updated, pair, mission = record(progress[name], dates[name], limit)
		nextProgress[name] = updated
		if pair then awards[AWARD[name]] = 1 end
		if mission then awards.sticker = 1 end
	end
	return nextProgress, awards
end

function ChestProgress.status(progress, now)
	local dates = periods(now)
	local status = {mission = {count = 0, target = 3}}
	for name in LIMITS do
		local track = progress[name]
		local index = #track.counts + dates[name] - track.last
		local count = 0
		if index >= 1 and index <= #track.counts + 1 then
			local active = index <= #track.counts and track.counts:byte(index) ~= 48
			if active then
				count = if oddThrough(track.counts, index, track.beforeOdd) then 1 else 2
				if name == "weekly" then status.mission.count = track.counts:byte(index) - 48 end
			elseif oddThrough(track.counts, index - 1, track.beforeOdd) then
				count = 1 -- One consecutive prior period can still pair with the current one.
			end
		end
		status[name] = {count = count, target = 2}
	end
	return status
end

return ChestProgress
