-- Pure rules for the saved emotes table. Callers apply successful changes in the save queue.
local Config = require(script.Parent.Parent.Generated.Emotes)
local Economy = require(script.Parent.EconomyRules)
local Rules = {}
local slots = { leader = "leader", runner_up = "runnerUp" }
local byKind = { leader = {}, runner_up = {} }
local byID, freeByKind = {}, {}
local empty = table.freeze({})

local function positiveInteger(n, max)
	return type(n) == "number" and n > 0 and n <= max and n % 1 == 0
end
for _, prices in Config.tiers do
	assert(positiveInteger(prices.paper, math.floor(Economy.MAX_SAFE_INTEGER / Economy.MILLI))
		and positiveInteger(prices.robux, Economy.MAX_SAFE_INTEGER), "invalid emote tier prices")
	table.freeze(prices)
end
for _, emote in ipairs(Config.emotes) do
	local id, kind = emote.id, emote.kind
	assert(type(id) == "string" and #id <= 128 and id:match("^%w+$") and not byID[id], "invalid or duplicate emote id")
	assert(byKind[kind] and type(emote.name) == "string" and #emote.name > 0, "invalid emote kind or name")
	if emote.tier == "free" then
		assert(not freeByKind[kind], "duplicate free emote")
		freeByKind[kind] = id
	else
		assert(Config.tiers[emote.tier], "unknown emote tier")
	end
	byID[id] = table.freeze(emote)
	table.insert(byKind[kind], emote)
end
for kind, emotes in byKind do
	assert(freeByKind[kind], "missing free emote")
	table.freeze(emotes)
end
table.freeze(Config.emotes)
table.freeze(Config.tiers)
table.freeze(Config)

function Rules.config()
	return Config
end
function Rules.list(kind)
	if kind == nil then return Config.emotes end
	return byKind[kind] or empty
end
function Rules.get(id)
	return type(id) == "string" and byID[id] or nil
end
function Rules.price(id)
	local emote = Rules.get(id)
	return emote and Config.tiers[emote.tier] or nil
end
function Rules.free(kind)
	return freeByKind[kind]
end
function Rules.owns(saved, id)
	local emote = Rules.get(id)
	return emote ~= nil and (emote.tier == "free" or type(saved) == "table"
		and type(saved.owned) == "table" and saved.owned[id] == true)
end
function Rules.worn(saved, kind)
	local slot = slots[kind]
	if not slot then return nil end
	local pick = type(saved) == "table" and saved[slot]
	local emote = Rules.get(pick)
	if emote and emote.kind == kind and Rules.owns(saved, pick) then return pick end
	return Rules.free(kind)
end
function Rules.buy(saved, id, paperBalance)
	if not Rules.get(id) then return false, "unknown" end
	local price = Rules.price(id)
	if not price then return false, "free" end
	if Rules.owns(saved, id) then return false, "owned" end
	if not (type(paperBalance) == "number" and paperBalance >= price.paper) then return false, "paper" end
	return true, nil, price.paper
end
function Rules.wear(saved, id)
	local emote = Rules.get(id)
	if not emote then return false, "unknown" end
	if not Rules.owns(saved, id) then return false, "not_owned" end
	return true, nil, slots[emote.kind]
end

return table.freeze(Rules)
