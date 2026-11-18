-- Counts distinct saved owners across servers. Each child contributes its latest totals.
-- Replaying a partially completed update or receiving an older save cannot count an owner twice.
local DataStoreService = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local Looks = require(game.ReplicatedStorage.FlyFightPaper.Shared.LooksRules)
local Owners = {}
Owners.__index = Owners

local WIDTH, ROOT_LEVEL = 256, 6
local TOP = "6:0"

function Owners.new(profileStoreName, mock, override)
	local store = override
	if not store and mock then
		local rows = {}
		store = {
			GetAsync = function(_, key) return rows[key] end,
			UpdateAsync = function(_, key, update) rows[key] = update(rows[key]) or rows[key] end,
		}
	elseif not store then
		store = DataStoreService:GetDataStore(profileStoreName .. "_LookOwners1")
	end
	return setmetatable({ store = store }, Owners)
end

function Owners:record(userId, owned)
	local contribution = {}
	for id, yes in owned do
		if yes and Looks.item(id) then contribution[id] = 1 end
	end
	if not next(contribution) then return {} end
	local child = userId
	for level = 0, ROOT_LEVEL do
		local bucket, slot = math.floor(child / WIDTH), tostring(child % WIDTH)
		local totals
		self.store:UpdateAsync(level .. ":" .. bucket, function(node)
			node = node or { children = {}, totals = {} }
			local prior = node.children[slot] or {}
			local changed = false
			for id, n in contribution do
				local previous = prior[id] or 0
				if n > previous then
					prior[id] = n
					node.totals[id] = (node.totals[id] or 0) + n - previous
					changed = true
				end
			end
			totals = node.totals
			if not changed then return nil end
			node.children[slot] = prior
			return node
		end)
		child, contribution = bucket, totals
	end
	return contribution
end

-- Enrol old collections even if their owners never return. Only one live server scans
-- a page. A lost lease can repeat a page safely because record() merges by owner.
function Owners:backfillPage(profiles, worker)
	local cursor, finished = nil, false
	self.store:UpdateAsync("backfill", function(state)
		state = state or { cursor = "" }
		cursor, finished = nil, state.done == true
		if finished or (state.worker ~= worker and (state.expires or 0) > os.time()) then return nil end
		cursor = state.cursor
		return { cursor = cursor, worker = worker, expires = os.time() + 300 }
	end)
	if not cursor then return finished, 300 end
	local pages = profiles:ListKeysAsync("Player_", 8, cursor, true)
	for _, info in pages:GetCurrentPage() do
		local id = tonumber(info.KeyName:match("^Player_(%d+)$"))
		if id then
			local raw = profiles:GetAsync(info.KeyName)
			local looks = raw and raw.Data and raw.Data.looks
			if looks and looks.owned then self:record(id, looks.owned) end
		end
		task.wait(1)
	end
	local done, nextCursor = pages.IsFinished, pages.Cursor
	if not done and (not nextCursor or nextCursor == "" or nextCursor == cursor) then
		error("Missing cursor while indexing saved collections")
	end
	self.store:UpdateAsync("backfill", function(state)
		if not state or state.worker ~= worker or state.cursor ~= cursor then return nil end
		return done and { done = true } or { cursor = nextCursor, worker = worker, expires = os.time() + 300 }
	end)
	return done, 10
end

function Owners:startBackfill(profileStoreName)
	local profiles = DataStoreService:GetDataStore(profileStoreName)
	task.spawn(function()
		while true do
			local ok, done, delay = pcall(self.backfillPage, self, profiles, game.JobId)
			if ok and done then return end
			task.wait(ok and delay or 120)
		end
	end)
end

-- One worker per session, independent of saves. Consolidate repeated snapshots while the store yields.
function Owners:observe(entry, data)
	local owned, result = data.looks and data.looks.owned, data.chests
	if not owned or not next(owned) then return end
	local ids = {}
	for id in owned do table.insert(ids, id) end
	table.sort(ids)
	local signature = table.concat(ids, ",")
	local key = signature .. ":" .. tostring(result and result.opened or 0)
	if entry.ownerKey == key then return end
	entry.ownerKey = key
	entry.ownerPending = { owned = owned, signature = signature, result = result, key = key }
	if entry.ownerRunning then return end
	entry.ownerRunning = true
	task.spawn(function()
		while entry.ownerPending do
			local pending = entry.ownerPending
			entry.ownerPending = nil
			local ok, totals = pcall(function()
				if entry.indexedLooks == pending.signature then
					local root = self.store:GetAsync(TOP)
					if root then return root.totals end
				end
				return self:record(math.abs(entry.player.UserId), pending.owned)
			end)
			if ok then
				entry.indexedLooks = pending.signature
				local chest = pending.result
				if chest and chest.opened > 0 and totals[chest.lastSkin] and entry.player.Parent then
					entry.player:SetAttribute("CosmeticOwnerTally", Http:JSONEncode({
						item = chest.lastSkin, count = totals[chest.lastSkin], opened = chest.opened,
					}))
				end
			elseif not entry.ownerPending and entry.player.Parent then
				task.wait(20)
				if not entry.ownerPending and entry.player.Parent then entry.ownerPending = pending end
			end
		end
		entry.ownerRunning = false
	end)
end

return Owners
