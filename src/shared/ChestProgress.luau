-- Count three qualifying matches per Monday-start UTC week. Retain recent weeks so a delayed
-- settlement credits its original week. The caller journals match IDs and delivers each once.
local ChestProgress = {}
local WINDOW = 32
local MAX_TIME = 253402300799
local function week(at)
	return (math.floor(at / 86400) + 3) // 7
end
function ChestProgress.defaults()
	return {weekly = {last = 0, counts = ""}}
end
function ChestProgress.valid(progress)
	if type(progress) ~= "table" or type(progress.weekly) ~= "table" then return false end
	for k in progress do if k ~= "weekly" then return false end end
	local w = progress.weekly
	for k in w do if k ~= "last" and k ~= "counts" then return false end end
	if type(w.last) ~= "number" or w.last % 1 ~= 0 or w.last < 0 or w.last > week(MAX_TIME)
		or type(w.counts) ~= "string" then return false end
	if w.counts == "" then return w.last == 0 end
	return #w.counts == math.min(WINDOW, w.last+1) and w.counts:find("[^0-3]") == nil and w.counts:sub(-1) ~= "0"
end
function ChestProgress.complete(progress, completedAt)
	if type(completedAt) ~= "number" or completedAt % 1 ~= 0 or completedAt < 0 or completedAt > MAX_TIME then
		return nil, "invalid_match_time"
	end
	if not ChestProgress.valid(progress) then return nil, "invalid_chest_progress" end
	local period, previous = week(completedAt), progress.weekly
	local last = math.max(period, previous.last)
	local width = math.min(WINDOW, last + 1)
	local counts = previous.counts
	if counts == "" or last - previous.last >= width then
		counts = string.rep("0", width)
	elseif last > previous.last then
		counts = (counts .. string.rep("0", last - previous.last)):sub(-width)
	end
	local i = #counts - (last - period)
	local award = 0
	if i >= 1 then
		local n = counts:byte(i) - 48
		if n < 3 then
			counts = counts:sub(1, i-1) .. tostring(n+1) .. counts:sub(i+1)
			if n == 2 then award = 1 end
		end
	end
	return {weekly = {last = last, counts = counts}}, {sticker = award}
end
function ChestProgress.status(progress, now)
	local w = progress.weekly
	local index = #w.counts + week(now) - w.last
	local digit = index >= 1 and index <= #w.counts and w.counts:byte(index)
	return {mission = {count = digit and digit-48 or 0, target = 3}}
end
return ChestProgress
