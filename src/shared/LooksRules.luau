-- Pure cosmetic ownership rules. Callers persist returned copies and journal operation IDs.
local DefaultLooks = require(script.Parent.Parent.Generated.Looks)
local Economy = require(script.Parent.EconomyRules)
local LooksRules = {}
local config, items, skinsByTier, soldTrails
local skinTiers = { common = true, rare = true, legendary = true, mythical = true }
local tierOrder = { "common", "rare", "legendary", "mythical" }
local chests = {}
local trailPools = {}

local function integer(n)
	return type(n) == "number" and n == n and n >= 0 and n <= Economy.MAX_SAFE_INTEGER and n % 1 == 0
end
local function freeze(value)
	if type(value) == "table" and not table.isfrozen(value) then
		for _, child in pairs(value) do freeze(child) end
		table.freeze(value)
	end
	return value
end
-- Match EconomyRules' bounded, detached JSON copies without depending on ProfileSchema.
local function copy(value, state, depth)
	local kind = type(value)
	if kind == "string" then assert(#value <= 512, "profile string exceeds 512 bytes"); return value end
	if kind == "boolean" then return value end
	if kind == "number" then
		assert(value == value and math.abs(value) < math.huge, "profile contains a nonfinite number")
		return value
	end
	assert(kind == "table" and getmetatable(value) == nil, "profile must contain only plain JSON values")
	assert(depth < Economy.MAX_PROFILE_DEPTH and not state.seen[value], "profile exceeds maximum depth or contains a cycle")
	state.seen[value] = true
	local out = {}
	for key, child in pairs(value) do
		state.entries += 1
		assert(state.entries <= Economy.MAX_PROFILE_ENTRIES, "profile exceeds maximum entry count")
		assert(type(key) == "string" or (type(key) == "number" and key == key and math.abs(key) < math.huge), "invalid profile key")
		out[key] = copy(child, state, depth + 1)
	end
	state.seen[value] = nil
	return out
end
local function detached(value) return copy(value, { seen = {}, entries = 0 }, 0) end
local function array(value)
	assert(type(value) == "table" and getmetatable(value) == nil, "looks list must be a plain array")
	local count = 0
	for key in pairs(value) do assert(integer(key) and key >= 1 and key <= #value, "invalid looks array key"); count += 1 end
	assert(count == #value, "sparse looks array")
end
function LooksRules.config()
	if config then return config end
	local raw = detached(DefaultLooks)
	assert(type(raw.tiers) == "table" and type(raw.bot_tiers) == "table", "missing looks tiers")
	for tier, prices in pairs(raw.tiers) do
		assert(skinTiers[tier] or tier == "trail" or tier == "rare_trail", "unknown look tier: " .. tostring(tier))
		assert(type(prices) == "table" and integer(prices.paper) and integer(prices.robux), "invalid look prices")
		assert(prices.paper <= math.floor(Economy.MAX_SAFE_INTEGER / Economy.MILLI), "look price exceeds safe milliunits")
	end
	for _, tier in ipairs({ "common", "rare", "legendary", "mythical", "trail" }) do assert(raw.tiers[tier], "missing look tier: " .. tier) end
	local byID, byTier, trails = {}, {}, {}
	local function add(list, kind)
		array(list)
		for _, entry in ipairs(list) do
			assert(type(entry) == "table" and type(entry.id) == "string" and #entry.id > 0 and #entry.id <= 160, "invalid look id")
			assert(not byID[entry.id], "duplicate look id: " .. entry.id)
			assert(type(entry.name) == "string" and #entry.name > 0, "missing look name")
			assert(skinTiers[entry.tier], "unknown look tier")
			assert(kind == "skin" or type(entry.sold) == "boolean", "missing trail sold flag")
			assert(entry.price_tier == nil or (kind == "trail" and entry.sold and entry.price_tier == "rare_trail"), "invalid trail price tier")
			local prices = raw.tiers[entry.price_tier or (kind == "trail" and "trail") or entry.tier]
			local item = { id = entry.id, name = entry.name, kind = kind, tier = entry.tier,
				paper = prices.paper, robux = prices.robux, trail = entry.trail, sold = entry.sold == true,
				matchingTrail = entry.matching_trail or entry.trail,
				picture = entry.picture }
			assert(entry.picture == nil or integer(entry.picture), "invalid look picture")
			byID[item.id] = item
			if kind == "skin" then
				byTier[item.tier] = byTier[item.tier] or {}; table.insert(byTier[item.tier], item.id)
			elseif item.sold then
				trailPools[item.tier] = trailPools[item.tier] or {}
				table.insert(trailPools[item.tier], item.id)
				table.insert(trails, item.id)
			end
		end
	end
	add(raw.skins, "skin"); add(raw.trails, "trail")
	for _, item in pairs(byID) do
		if item.matchingTrail then
			local trail = byID[item.matchingTrail]
			assert(item.kind == "skin" and trail and trail.kind == "trail", "unknown matching trail")
			assert((item.tier == "mythical") == (item.trail ~= nil) and trail.sold == (item.trail == nil), "only Mythical trails are bundled")
			-- Legendary trails drop separately. Bots only use those with the matching skin.
			local index = table.find(trails, item.matchingTrail)
			if index then table.remove(trails, index) end
		end
	end
	assert(integer(raw.duplicate_refund_percent) and raw.duplicate_refund_percent <= 100, "invalid duplicate refund")
	for _, chest in ipairs(raw.chests) do
		assert(type(chest.id) == "string" and type(chest.name) == "string" and not chests[chest.id]
			and integer(chest.cost) and chest.cost > 0 and chest.cost <= math.floor(Economy.MAX_SAFE_INTEGER / Economy.MILLI), "invalid chest")
		assert(chest.family == "skin" or chest.family == "trail", "invalid chest family")
		assert(chest.id == (chest.family == "trail" and "trail_" or "") .. chest.base and integer(chest.robux) and chest.robux>0, "invalid chest mapping")
		local total = 0
		for _, tier in ipairs(tierOrder) do
			local weight = chest.weights[tier]
			assert(type(weight) == "number" and weight >= 0 and weight <= 100, "invalid chest tier weight")
			local units = math.round(weight * 100)
			assert(math.abs(weight * 100 - units) < 1e-8 and (units == 0 or (chest.family == "skin" and byTier or trailPools)[tier]), "missing prize tier")
			total += units
		end
		assert(total == 10000, "chest weights must total 100")
		chests[chest.id] = chest
	end
	for skill, tier in pairs(raw.bot_tiers) do
		assert(skill == "rookie" or skill == "regular" or skill == "experienced" or skill == "ace", "unknown bot skill")
		assert(skinTiers[tier] and byTier[tier] and #byTier[tier] > 0, "bot tier has no skins")
	end
	for _, skill in ipairs({ "rookie", "regular", "experienced", "ace" }) do assert(raw.bot_tiers[skill], "missing bot skill") end
	assert(#trails > 0, "bots need a sold trail")
	local odds = raw.bot_looks -- chances in 100 (Alan 2026-11-16: one roll for a skin and a trail both)
	assert(type(odds) == "table" and integer(odds.both) and integer(odds.skin) and integer(odds.trail) and integer(odds.neither), "invalid bot look chances")
	assert(odds.both + odds.skin + odds.trail + odds.neither == 100, "bot look chances must add up to 100")
	items, skinsByTier, soldTrails = freeze(byID), freeze(byTier), freeze(trails)
	config = freeze(raw)
	return config
end
function LooksRules.item(id)
	LooksRules.config()
	return type(id) == "string" and items[id] or nil
end
function LooksRules.chest(id)
	LooksRules.config()
	return chests[id]
end
-- Duplicate prizes pay Paper, so owned cosmetics stay in the draw.
function LooksRules.chestOdds(id)
	local chest = assert(LooksRules.chest(id))
	local counts = {}
	for _, tier in ipairs(tierOrder) do
		counts[tier] = chest.weights[tier] > 0 and #(chest.family == "skin" and skinsByTier or trailPools)[tier] or 0
	end
	return chest.weights, counts
end
function LooksRules.chestItems(id)
	local chest = assert(LooksRules.chest(id))
	local list = {}
	local pools = chest.family == "skin" and skinsByTier or trailPools
	for _, tier in tierOrder do
		if chest.weights[tier] > 0 then
			for _, itemID in pools[tier] do table.insert(list, items[itemID]) end
		end
	end
	return list
end
function LooksRules.duplicateRefund(id)
	local item = assert(LooksRules.item(id))
	return math.floor(item.paper * config.duplicate_refund_percent / 100)
end
function LooksRules.drawChest(chest, random)
	local roll = random(10000)
	local pools = chest.family == "skin" and skinsByTier or trailPools
	for _, tier in ipairs(tierOrder) do
		roll -= math.round(chest.weights[tier] * 100)
		if roll <= 0 then
			local pool = pools[tier]
			return pool[random(#pool)]
		end
	end
end
function LooksRules.owns(profile, id)
	return LooksRules.item(id) ~= nil and type(profile) == "table" and type(profile.looks) == "table"
		and type(profile.looks.owned) == "table" and profile.looks.owned[id] == true or false
end
local function failure(code, message) return nil, { type = "LooksRejected", code = code, message = message } end
local function validateOperationID(operationID)
	if type(operationID) ~= "string" or #operationID == 0 or #operationID > 160 then
		return failure("invalid_operation_id", "operationID must be a nonempty string of at most 160 bytes")
	end
	return true
end
local function cloneProfile(profile)
	LooksRules.config()
	local ok, updated = pcall(function()
		assert(type(profile) == "table", "profile must be a plain table")
		local p = detached(profile)
		assert(type(p.ownership) == "table", "profile ownership must be a plain table")
		for _, field in ipairs({ "paperMilli", "earnedPaperMilli", "purchasedPaperMilli", "xpMilli" }) do
			assert(integer(p[field]), field .. " must be a nonnegative safe integer")
		end
		assert(type(p.looks) == "table" and type(p.looks.owned) == "table", "profile looks must be initialized")
		for field in pairs(p.looks) do assert(field == "owned" or field == "skin" or field == "trail", "unknown looks field") end
		for id, owned in pairs(p.looks.owned) do assert(items[id] and owned == true, "invalid look ownership") end
		for _, kind in ipairs({ "skin", "trail" }) do
			local id = p.looks[kind]
			assert(id == "" or (type(id) == "string" and items[id] and items[id].kind == kind and p.looks.owned[id] == true), "invalid worn look")
		end
		return p
	end)
	if not ok then return failure("invalid_profile", tostring(updated)) end
	return updated
end
function LooksRules.buyWithPaper(_, id, operationID)
	local ok, err = validateOperationID(operationID); if not ok then return nil, err end
	local item = LooksRules.item(id)
	if not item then return failure("unknown_look", "look id is not in the server catalog") end
	if item.kind == "trail" and not item.sold then return failure("not_sold", "this trail comes with its Mythical skin") end
	return failure("chest_only", "individual cosmetics come from chests")
end
function LooksRules.grant(profile, id, operationID)
	local ok, err = validateOperationID(operationID); if not ok then return nil, err end
	local item = LooksRules.item(id)
	if not item then return failure("unknown_look", "look id is not in the server catalog") end
	if item.kind == "trail" and not item.sold then return failure("not_sold", "this trail comes with its Mythical skin") end
	local updated, rejected = cloneProfile(profile); if not updated then return nil, rejected end
	local alreadyOwned = updated.looks.owned[id] == true
	updated.looks.owned[id] = true
	if item.trail then updated.looks.owned[item.trail] = true end
	return freeze({ profile = updated, operation = { type = "LookGranted", operationID = operationID,
		lookID = id, priceMilli = 0, chargedMilli = 0, alreadyOwned = alreadyOwned } })
end
function LooksRules.wear(profile, skinID, trailID, operationID)
	local ok, err = validateOperationID(operationID); if not ok then return nil, err end
	local updated, rejected = cloneProfile(profile); if not updated then return nil, rejected end
	for kind, id in pairs({ skin = skinID, trail = trailID }) do
		if id ~= "" then
			local item = LooksRules.item(id)
			if not item then return failure("not_owned", "look must be owned before wearing it") end
			if item.kind ~= kind then return failure("wrong_kind", "look is not a " .. kind) end
			if not LooksRules.owns(updated, id) then return failure("not_owned", "look must be owned before wearing it") end
		end
	end
	if type(skinID) ~= "string" or type(trailID) ~= "string" then return failure("not_owned", "both worn look ids must be strings") end
	updated.looks.skin, updated.looks.trail = skinID, trailID
	return freeze({ profile = updated, operation = { type = "LooksWorn", operationID = operationID, skinID = skinID, trailID = trailID } })
end
-- One roll for each bot, four results (Alan 2026-11-16: "Not every bot needs skins. Not every bot needs trails. They
-- also need a roll for having both"): a skin and a trail, a skin only, a trail only, or neither. A bot with both wears
-- its skin's matching trail when the skin has one.
function LooksRules.botLooks(skill, random)
	local cfg = LooksRules.config()
	local function choose(list, n)
		local index = random(n or #list)
		assert(integer(index) and index >= 1 and index <= (n or #list), "random must return an integer in 1..n")
		return list and list[index] or index
	end
	local odds, roll = cfg.bot_looks, choose(nil, 100)
	local skin = roll <= odds.both + odds.skin and choose(skinsByTier[cfg.bot_tiers[skill] or cfg.bot_tiers.rookie]) or nil
	local trailed = roll <= odds.both or (roll > odds.both + odds.skin and roll <= 100 - odds.neither)
	return skin, trailed and (skin and items[skin].matchingTrail or choose(soldTrails)) or nil
end
return table.freeze(LooksRules)
