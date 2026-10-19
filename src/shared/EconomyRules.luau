-- Pure economy arithmetic. Callers persist returned copies and journal operation IDs.
-- Financial values are nonnegative safe integers in milliunits. Profiles must be bounded
-- JSON-like tables; functions, Instances/userdata, metatables and cyclic graphs are rejected.
local DefaultEconomy = require(script.Parent.Parent.Generated.Economy)
local EconomyRules = {}

EconomyRules.MILLI = 1000
EconomyRules.MAX_SAFE_INTEGER = 9007199254740991
EconomyRules.LEVEL_CAP = 50
EconomyRules.MAX_PROFILE_DEPTH = 8
EconomyRules.MAX_PROFILE_ENTRIES = 4096

local MAX_SAFE, MILLI = EconomyRules.MAX_SAFE_INTEGER, EconomyRules.MILLI

local function validSafeInteger(value)
	return type(value) == "number" and value == value and value >= 0 and value <= MAX_SAFE
		and value % 1 == 0
end

local function validMultiplier(value)
	return value == 1 or value == 2
end

local function validOperationID(value)
	return type(value) == "string" and #value > 0 and #value <= 160
end

local function failure(code, message)
	return nil, { type = "EconomyRejected", code = code, message = message }
end

local function safeAdd(a, b)
	if not validSafeInteger(a) or not validSafeInteger(b) or a > MAX_SAFE - b then return nil end
	return a + b
end

local function safeMultiply(a, b)
	if not validSafeInteger(a) or not validSafeInteger(b) then return nil end
	if a ~= 0 and b > math.floor(MAX_SAFE / a) then return nil end
	return a * b
end

local function boundedCopy(value, state, depth)
	local kind = type(value)
	if kind == "string" then
		if #value > 512 then return nil, "profile string exceeds 512 bytes" end
		return value
	elseif kind == "boolean" then
		return value
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return nil, "profile contains a nonfinite number"
		end
		return value
	elseif kind ~= "table" then
		return nil, "profile contains a non-JSON value"
	end
	if depth >= EconomyRules.MAX_PROFILE_DEPTH then return nil, "profile exceeds maximum depth" end
	if getmetatable(value) ~= nil then return nil, "profile contains a metatable" end
	if state.seen[value] then return nil, "profile contains a cycle or shared table" end
	state.seen[value] = true
	local copy = {}
	for key, child in pairs(value) do
		state.entries += 1
		if state.entries > EconomyRules.MAX_PROFILE_ENTRIES then return nil, "profile exceeds maximum entry count" end
		local keyKind = type(key)
		if keyKind ~= "string" and keyKind ~= "number" then return nil, "profile has an invalid table key" end
		if keyKind == "number" and (key ~= key or key == math.huge or key == -math.huge) then
			return nil, "profile has a nonfinite numeric key"
		end
		local copied, err = boundedCopy(child, state, depth + 1)
		if err then return nil, err end
		copy[key] = copied
	end
	state.seen[value] = nil
	return copy
end

local function freezeDeep(value)
	if type(value) ~= "table" or table.isfrozen(value) then return value end
	for _, child in pairs(value) do freezeDeep(child) end
	table.freeze(value)
	return value
end

local FINANCIAL_FIELDS = { "paperMilli", "earnedPaperMilli", "purchasedPaperMilli", "xpMilli" }
local function cloneProfile(profile)
	if type(profile) ~= "table" or getmetatable(profile) ~= nil then return nil, "profile must be a plain table" end
	local copy, copyError = boundedCopy(profile, { seen = {}, entries = 0 }, 0)
	if not copy then return nil, copyError end
	if type(copy.ownership) ~= "table" or getmetatable(copy.ownership) ~= nil then
		return nil, "profile ownership must be a plain table"
	end
	for _, field in ipairs(FINANCIAL_FIELDS) do
		if copy[field] == nil then return nil, field .. " is required; migrate or initialize profile explicitly" end
		if not validSafeInteger(copy[field]) then return nil, field .. " must be a nonnegative safe integer" end
	end
	return copy
end

local function immutableResult(profileCopy, operation)
	return freezeDeep({ profile = profileCopy, operation = operation })
end

local function validateOperationID(operationID)
	if not validOperationID(operationID) then
		return failure("invalid_operation_id", "operationID must be a nonempty string of at most 160 bytes")
	end
	return true
end

local function economyConfig(config)
	if config == nil then config = DefaultEconomy end
	if type(config) ~= "table" or getmetatable(config) ~= nil then return nil end
	return config
end

local function rateToMilli(rate)
	if type(rate) ~= "number" or rate ~= rate or rate <= 0 or rate == math.huge then return nil end
	local scaled = rate * MILLI
	if scaled ~= scaled or scaled == math.huge or scaled % 1 ~= 0 or scaled > MAX_SAFE then return nil end
	return scaled
end

local function convertContribution(points, paperMultiplier, xpMultiplier, config)
	if not validSafeInteger(points) then return nil, nil, { type = "EconomyRejected", code = "invalid_points", message = "points must be a nonnegative safe integer" } end
	if not validMultiplier(paperMultiplier) or not validMultiplier(xpMultiplier) then
		return nil, nil, { type = "EconomyRejected", code = "invalid_multiplier", message = "each event-time multiplier must be exactly 1 or 2" }
	end
	config = economyConfig(config)
	if not config then return nil, nil, { type = "EconomyRejected", code = "invalid_economy_config", message = "economy config must be a plain table" } end
	local paperRate, xpRate = rateToMilli(config.paper_per_point), rateToMilli(config.xp_per_point)
	if not paperRate or not xpRate then
		return nil, nil, { type = "EconomyRejected", code = "invalid_economy_rate", message = "configured conversion rates must be positive exact milliunit rates" }
	end
	local basePaper, baseXP = safeMultiply(points, paperRate), safeMultiply(points, xpRate)
	if not basePaper or not baseXP then return nil, nil, { type = "EconomyRejected", code = "overflow", message = "base conversion exceeds safe integer range" } end
	local paperMilli, xpMilli = safeMultiply(basePaper, paperMultiplier), safeMultiply(baseXP, xpMultiplier)
	if not paperMilli or not xpMilli then return nil, nil, { type = "EconomyRejected", code = "overflow", message = "multiplied conversion exceeds safe integer range" } end
	return paperMilli, xpMilli
end

-- config defaults to Generated.Economy. Rates must map exactly to integer milliunits.
function EconomyRules.contributionMilli(points, paperMultiplier, xpMultiplier, config)
	local paperMilli, xpMilli, err = convertContribution(points, paperMultiplier, xpMultiplier, config)
	if err then return nil, err end
	return table.freeze({ paperMilli = paperMilli, xpMilli = xpMilli })
end

function EconomyRules.applyContribution(profile, points, multipliers, operationID, config)
	local ok, err = validateOperationID(operationID)
	if not ok then return nil, err end
	if type(multipliers) ~= "table" or getmetatable(multipliers) ~= nil then return failure("invalid_multiplier", "multipliers must be a plain table") end
	local paperMilli, xpMilli, conversionError = convertContribution(points, multipliers.paper, multipliers.xp, config)
	if conversionError then return nil, conversionError end
	local updated, profileError = cloneProfile(profile)
	if not updated then return failure("invalid_profile", profileError) end
	local paper, earned, xp = safeAdd(updated.paperMilli, paperMilli), safeAdd(updated.earnedPaperMilli, paperMilli), safeAdd(updated.xpMilli, xpMilli)
	if not paper or not earned or not xp then return failure("overflow", "contribution would exceed safe integer range") end
	updated.paperMilli, updated.earnedPaperMilli, updated.xpMilli = paper, earned, xp
	return immutableResult(updated, { type = "ContributionApplied", operationID = operationID,
		contributionPoints = points, paperMilli = paperMilli, xpMilli = xpMilli, purchasedPaperMilli = 0 })
end

-- finalPaper/finalXP are authoritative final bonuses, already computed by MatchService.
-- Any contribution fields in resultRow are informational and are never paid again here.
function EconomyRules.applyFinalBonuses(profile, resultRow, multipliers, operationID, config)
	local ok, err = validateOperationID(operationID)
	if not ok then return nil, err end
	if type(resultRow) ~= "table" or getmetatable(resultRow) ~= nil then return failure("invalid_result", "result row must be a plain table") end
	if not validSafeInteger(resultRow.finalPaper) or not validSafeInteger(resultRow.finalXP) then
		return failure("invalid_result", "finalPaper and finalXP must be nonnegative safe whole-unit integers")
	end
	if type(multipliers) ~= "table" or getmetatable(multipliers) ~= nil
		or not validMultiplier(multipliers.paper) or not validMultiplier(multipliers.xp) then
		return failure("invalid_multiplier", "each finalization multiplier must be exactly 1 or 2")
	end
	config = economyConfig(config)
	if not config then return failure("invalid_economy_config", "economy config must be a plain table") end
	local paperRate, xpRate = rateToMilli(config.paper_per_point), rateToMilli(config.xp_per_point)
	if not paperRate or not xpRate then return failure("invalid_economy_rate", "configured conversion rates must be positive exact milliunit rates") end
	local paperMilli, xpMilli = safeMultiply(resultRow.finalPaper, MILLI), safeMultiply(resultRow.finalXP, MILLI)
	if not paperMilli or not xpMilli then return failure("overflow", "final bonuses exceed safe integer range") end
	paperMilli, xpMilli = safeMultiply(paperMilli, multipliers.paper), safeMultiply(xpMilli, multipliers.xp)
	if not paperMilli or not xpMilli then return failure("overflow", "multiplied final bonuses exceed safe integer range") end
	local updated, profileError = cloneProfile(profile)
	if not updated then return failure("invalid_profile", profileError) end
	local paper, earned, xp = safeAdd(updated.paperMilli, paperMilli), safeAdd(updated.earnedPaperMilli, paperMilli), safeAdd(updated.xpMilli, xpMilli)
	if not paper or not earned or not xp then return failure("overflow", "final bonuses would exceed safe integer range") end
	updated.paperMilli, updated.earnedPaperMilli, updated.xpMilli = paper, earned, xp
	return immutableResult(updated, { type = "FinalBonusesApplied", operationID = operationID,
		paperMilli = paperMilli, xpMilli = xpMilli, purchasedPaperMilli = 0 })
end

function EconomyRules.wholeAndResidual(amountMilli)
	if not validSafeInteger(amountMilli) then return failure("invalid_amount", "amount must be a nonnegative safe integer") end
	return table.freeze({ whole = math.floor(amountMilli / MILLI), residualMilli = amountMilli % MILLI })
end

function EconomyRules.levelForXP(cumulativeXPmilli, config)
	if not validSafeInteger(cumulativeXPmilli) then return failure("invalid_xp", "cumulative XP must be a nonnegative safe integer") end
	config = economyConfig(config)
	if not config then return failure("invalid_level_config", "economy config must be a plain table") end
	local cap, base, step = config.level_cap, config.xp_next_level_base, config.xp_next_level_step
	if not validSafeInteger(cap) or cap < 1 or cap > EconomyRules.LEVEL_CAP
		or not validSafeInteger(base) or base < 1 or not validSafeInteger(step) then
		return failure("invalid_level_config", "level cap must be 1..50, base positive, and step nonnegative safe integers")
	end
	local required = safeMultiply(base, MILLI)
	if not required then return failure("overflow", "level threshold exceeds safe integer range") end
	local level, remaining = 1, cumulativeXPmilli
	while level < cap and remaining >= required do
		remaining -= required
		level += 1
		local increment = safeMultiply(step, level - 1)
		local units = increment and safeAdd(base, increment)
		required = units and safeMultiply(units, MILLI)
		if not required then return failure("overflow", "level threshold exceeds safe integer range") end
	end
	return level, remaining, required
end

function EconomyRules.starterOwnership(catalog)
	if type(catalog) ~= "table" or type(catalog.starterLoadout) ~= "function" then return failure("invalid_catalog", "starter ownership requires an actual Catalog instance") end
	local ok, loadout = pcall(function() return catalog:starterLoadout() end)
	if not ok or type(loadout) ~= "table" then return failure("invalid_catalog", "Catalog could not provide its starter loadout") end
	local ownership = {}
	for _, slot in ipairs({ "body", "nose", "wings", "tail" }) do
		if type(loadout[slot]) ~= "string" then return failure("invalid_catalog", "Catalog starter loadout has an invalid " .. slot) end
		ownership[loadout[slot]] = true
	end
	for _, id in ipairs(loadout.weapon_mounts or {}) do if type(id) == "string" then ownership[id] = true end end
	if type(loadout.utility) == "string" then ownership[loadout.utility] = true end
	return freezeDeep(ownership)
end

function EconomyRules.validateEquipmentPurchase(profile, catalog, catalogID, operationID, config)
	local ok, err = validateOperationID(operationID)
	if not ok then return nil, err end
	if type(catalog) ~= "table" or type(catalog.get) ~= "function" then return failure("invalid_catalog", "purchase validation requires an actual Catalog instance") end
	if type(catalogID) ~= "string" or #catalogID == 0 or #catalogID > 160 then return failure("invalid_catalog_id", "catalogID must be a nonempty bounded string") end
	local got, definition = pcall(function() return catalog:get(catalogID) end)
	if not got or type(definition) ~= "table" or definition.id ~= catalogID then return failure("unknown_catalog_id", "catalogID is not in the server Catalog") end
	if not validSafeInteger(definition.paper_price) or not validSafeInteger(definition.min_level) or definition.min_level < 1 then
		return failure("invalid_catalog_entry", "Catalog price and min_level must be nonnegative safe whole integers")
	end
	local updated, profileError = cloneProfile(profile)
	if not updated then return failure("invalid_profile", profileError) end
	if updated.ownership[catalogID] == true then
		return immutableResult(updated, { type = "EquipmentPurchase", operationID = operationID,
			catalogID = catalogID, priceMilli = 0, chargedMilli = 0, alreadyOwned = true })
	end
	local level, levelError = EconomyRules.levelForXP(updated.xpMilli, config)
	if not level then return failure("invalid_level_config", levelError and levelError.message or "profile XP cannot produce a valid level") end
	if level < definition.min_level then return failure("level_locked", "item requires level " .. tostring(definition.min_level)) end
	local priceMilli = safeMultiply(definition.paper_price, MILLI)
	if not priceMilli then return failure("overflow", "Catalog price exceeds safe integer range") end
	if updated.paperMilli < priceMilli then return failure("insufficient_paper", "profile Paper is below Catalog price") end
	updated.paperMilli -= priceMilli
	updated.ownership[catalogID] = true
	return immutableResult(updated, { type = "EquipmentPurchase", operationID = operationID,
		catalogID = catalogID, priceMilli = priceMilli, chargedMilli = priceMilli, alreadyOwned = false })
end

function EconomyRules.prestige(profile, catalog, operationID, config)
	local ok, err = validateOperationID(operationID)
	if not ok then return nil, err end
	if type(catalog) ~= "table" or type(catalog.starterLoadout) ~= "function" or type(catalog.validateLoadout) ~= "function" then
		return failure("invalid_catalog", "prestige requires an actual Catalog instance")
	end
	config = economyConfig(config)
	if not config or not validSafeInteger(config.prestige_max) or config.prestige_max < 1 then
		return failure("invalid_economy_config", "prestige maximum must be a positive safe integer")
	end
	local initialXP = type(config.initial_total_xp) == "number" and config.initial_total_xp * MILLI
	if not validSafeInteger(initialXP) then return failure("invalid_economy_config", "initial XP must be exact nonnegative milliunits") end
	local updated, profileError = cloneProfile(profile)
	if not updated then return failure("invalid_profile", profileError) end
	if not validSafeInteger(updated.prestige) or updated.prestige > config.prestige_max
		or type(updated.presets) ~= "table" or (updated.refolds ~= nil and type(updated.refolds) ~= "table") then
		return failure("invalid_profile", "prestige requires a valid rank, presets and refolds")
	end
	local level, levelError = EconomyRules.levelForXP(updated.xpMilli, config)
	if not level then return nil, levelError end
	if level ~= config.level_cap then return failure("not_at_level_cap", "prestige requires the level cap") end
	if updated.prestige >= config.prestige_max then return failure("prestige_max", "maximum prestige rank reached") end
	if updated.refolds and next(updated.refolds) ~= nil then return failure("refold_pending", "finish pending refolds before prestige") end
	local ownership, ownershipError = EconomyRules.starterOwnership(catalog)
	if not ownership then return nil, ownershipError end
	local newLevel, newLevelError = EconomyRules.levelForXP(initialXP, config)
	if not newLevel then return nil, newLevelError end
	updated.prestige += 1
	updated.xpMilli = initialXP
	updated.ownership = ownership
	for _, preset in ipairs(updated.presets) do
		if type(preset) ~= "table" then return failure("invalid_profile", "presets must be tables") end
		if not catalog:validateLoadout(preset.loadout, ownership, newLevel) then preset.loadout = catalog:starterLoadout() end
	end
	return immutableResult(updated, { type = "Prestiged", operationID = operationID, prestige = updated.prestige })
end

-- Purchased Paper is added without conversion, multiplier, earned balance or XP effects.
function EconomyRules.addPurchasedPaper(profile, wholePaper, operationID)
	local ok, err = validateOperationID(operationID)
	if not ok then return nil, err end
	if not validSafeInteger(wholePaper) then return failure("invalid_amount", "purchased Paper must be a nonnegative safe whole-unit amount") end
	local amountMilli = safeMultiply(wholePaper, MILLI)
	if not amountMilli then return failure("overflow", "purchased Paper exceeds safe integer range") end
	local updated, profileError = cloneProfile(profile)
	if not updated then return failure("invalid_profile", profileError) end
	local paper, purchased = safeAdd(updated.paperMilli, amountMilli), safeAdd(updated.purchasedPaperMilli, amountMilli)
	if not paper or not purchased then return failure("overflow", "purchased Paper would exceed safe integer range") end
	updated.paperMilli, updated.purchasedPaperMilli = paper, purchased
	return immutableResult(updated, { type = "PurchasedPaperAdded", operationID = operationID,
		paperMilli = amountMilli, purchasedPaperMilli = amountMilli, earnedPaperMilli = 0, xpMilli = 0 })
end

return table.freeze(EconomyRules)
