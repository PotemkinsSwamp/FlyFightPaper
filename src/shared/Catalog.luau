local JSONTypes = require(script.Parent.Parent.Generated.JSONTypes)
local CombatRules = require(script.Parent.CombatRules)

local Catalog = {}
Catalog.__index = Catalog

local STRUCTURE_SLOTS = { "body", "nose", "wings", "tail" }
local LOADOUT_FIELDS = {
	body = true,
	nose = true,
	wings = true,
	tail = true,
	weapon_mounts = true,
	utility = true,
}
local COMPATIBLE = {
	heavy = { heavy = true, medium = true, light = true },
	medium = { medium = true, light = true },
	light = { light = true },
}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isPlainTable(value)
	return type(value) == "table" and getmetatable(value) == nil
end

local function isDenseArray(value, expectedLength)
	if not isPlainTable(value) then
		return false
	end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > expectedLength then
			return false
		end
		count += 1
	end
	return count == expectedLength
end

local function clamp(value, low, high)
	return math.max(low, math.min(high, value))
end

function Catalog.new(config, gameplay)
	assert(isPlainTable(config), "Catalog config must be a table")
	if gameplay == nil then
		gameplay = require(script.Parent.Parent.Generated.Gameplay)
	end
	assert(isPlainTable(gameplay) and isPlainTable(gameplay.flight), "Gameplay flight config is required")
	local self = setmetatable({
		config = config,
		flight = gameplay.flight,
		byId = {},
		structuresBySlot = {},
		weapons = {},
		utilities = {},
	}, Catalog)

	for _, slot in ipairs(STRUCTURE_SLOTS) do
		self.structuresBySlot[slot] = {}
	end
	local function indexAll(entries, destination, expectedSlot)
		assert(type(entries) == "table", "Catalog entry list is missing")
		for _, entry in ipairs(entries) do
			assert(isPlainTable(entry) and type(entry.id) == "string", "Catalog entry has invalid ID")
			assert(self.byId[entry.id] == nil, "Duplicate catalog ID: " .. entry.id)
			if expectedSlot then
				assert(entry.slot == expectedSlot, "Catalog structure has an invalid slot")
			end
			self.byId[entry.id] = entry
			table.insert(destination, entry)
		end
	end

	for _, slot in ipairs(STRUCTURE_SLOTS) do
		local entries = {}
		for _, entry in ipairs(config.structures or {}) do
			if entry.slot == slot then
				table.insert(entries, entry)
			end
		end
		indexAll(entries, self.structuresBySlot[slot], slot)
	end
	indexAll(config.weapons, self.weapons)
	indexAll(config.utilities, self.utilities)
	return self
end

function Catalog:get(id)
	if type(id) ~= "string" then
		return nil
	end
	return self.byId[id]
end

function Catalog:starterLoadout()
	local seed = self.config.starter_loadout
	assert(isPlainTable(seed), "Starter loadout is missing")
	local body = self.byId[seed.body]
	assert(body and body.slot == "body", "Starter body is invalid")
	local mounts = {}
	for index = 1, body.mount_count do
		local weaponId = seed.weapon_mounts[index]
		if weaponId == nil or weaponId == JSONTypes.Null then
			mounts[index] = false
		else
			mounts[index] = weaponId
		end
	end
	local utility = seed.utility
	if utility == JSONTypes.Null then
		utility = nil
	end
	return {
		body = seed.body,
		nose = seed.nose,
		wings = seed.wings,
		tail = seed.tail,
		weapon_mounts = mounts,
		utility = utility,
	}
end

function Catalog:validateLoadout(loadout, ownership, level)
	if not isPlainTable(loadout) then
		return nil, "loadout must be a plain table"
	end
	for key in pairs(loadout) do
		if not LOADOUT_FIELDS[key] then
			return nil, "unknown loadout field: " .. tostring(key)
		end
	end
	if ownership ~= nil and not isPlainTable(ownership) then
		return nil, "ownership must be a set keyed by catalog ID"
	end
	if not isFiniteNumber(level) or level % 1 ~= 0 or level < 1 then
		return nil, "level must be a positive integer"
	end

	local selected = {}
	local body
	for _, slot in ipairs(STRUCTURE_SLOTS) do
		local id = loadout[slot]
		if type(id) ~= "string" then
			return nil, "missing or invalid " .. slot
		end
		local definition = self.byId[id]
		if not definition or definition.slot ~= slot then
			return nil, "unknown or incorrect " .. slot .. " ID: " .. id
		end
		selected[id] = definition
		if slot == "body" then
			body = definition
		end
	end

	if not isFiniteNumber(body.mount_count) or body.mount_count % 1 ~= 0 or body.mount_count < 0 then
		return nil, "body mount count is invalid"
	end
	if not isDenseArray(loadout.weapon_mounts, body.mount_count) then
		return nil, "weapon_mounts must contain exactly the ordered body mount slots"
	end
	if not isFiniteNumber(body.capacity) or body.capacity < 0 then
		return nil, "body capacity is invalid"
	end

	local usedCapacity = 0
	for mountIndex = 1, body.mount_count do
		local weaponId = loadout.weapon_mounts[mountIndex]
		if weaponId ~= false then
			if type(weaponId) ~= "string" then
				return nil, "empty mounts must be false and weapons must be string IDs"
			end
			local weapon = self.byId[weaponId]
			local mountType = body.mount_types and body.mount_types[mountIndex]
			if not weapon or not weapon.class then
				return nil, "unknown weapon ID: " .. weaponId
			end
			if not (COMPATIBLE[mountType] and COMPATIBLE[mountType][weapon.class]) then
				return nil, "weapon is incompatible with ordered mount " .. tostring(mountIndex)
			end
			selected[weaponId] = weapon
			usedCapacity += weapon.capacity
		end
	end
	local groups, groupError = CombatRules.triggerGroups(loadout)
	if not groups then return nil, groupError end
	if usedCapacity > body.capacity then
		return nil, "weapon capacity exceeds body capacity"
	end

	local utilityId = loadout.utility
	if utilityId ~= nil then
		if type(utilityId) ~= "string" then
			return nil, "utility must be an ID or nil"
		end
		local utility = self.byId[utilityId]
		if not utility or utility.boost_seconds == nil then
			return nil, "unknown utility ID: " .. utilityId
		end
		selected[utilityId] = utility
	end

	for id, definition in pairs(selected) do
		if level < definition.min_level and not (ownership ~= nil and ownership[id] == true) then
			return nil, id .. " requires level " .. tostring(definition.min_level)
		end
		-- nil ownership is reserved for trusted internal all-owned analysis.
		if ownership ~= nil and ownership[id] ~= true then
			return nil, "not owned: " .. id
		end
	end
	return true
end

function Catalog:deriveStats(loadout)
	local valid, validationError = self:validateLoadout(loadout, nil, 1000000000)
	if not valid then
		return nil, validationError
	end
	local body = self.byId[loadout.body]
	local parts = { self.byId[loadout.nose], self.byId[loadout.wings], self.byId[loadout.tail] }
	local health = body.base_health
	local speed = body.base_speed
	local lift = body.base_lift
	local mass = 0
	local usedCapacity = 0
	for _, part in ipairs(parts) do
		health += part.health_delta
		speed += part.speed_delta
		lift += part.lift_delta
	end
	-- Like a real plane: the tail's elevator sets pitch (up/down), the wings' ailerons set yaw (left/right
	-- through banking). The nose trims both.
	local pitch = body.base_turn + parts[1].turn_delta + parts[3].turn_delta
	local yaw = body.base_turn + parts[1].turn_delta + parts[2].turn_delta
	for mountIndex = 1, body.mount_count do
		local weaponId = loadout.weapon_mounts[mountIndex]
		if weaponId ~= false then
			local weapon = self.byId[weaponId]
			mass += weapon.mass
			usedCapacity += weapon.capacity
		end
	end
	if loadout.utility ~= nil then
		mass += self.byId[loadout.utility].mass
	end

	local archetypeSpeedCeiling = { heavy = 95, standard = 135, slim = 155 }
	local finalSpeed = clamp(speed - self.flight.speed_equipment_penalty_per_mass * mass,
		self.flight.speed_min_studs_s, self.flight.speed_max_studs_s)
	finalSpeed = math.min(finalSpeed, archetypeSpeedCeiling[body.archetype] or math.huge)
	-- Catalog turn values are relative handling; the scale sets how fast planes really turn.
	local function rate(value)
		return clamp(value - self.flight.turn_equipment_penalty_per_mass * mass,
			self.flight.turn_min_deg_s, self.flight.turn_max_deg_s) * self.flight.turn_rate_scale
	end
	return {
		health = clamp(health, 45, 400),
		speed = finalSpeed,
		pitch = rate(pitch),
		yaw = rate(yaw),
		-- Fastest axis: server checks and aim slack use it as the limit.
		turn = math.max(rate(pitch), rate(yaw)),
		lift = clamp(lift - self.flight.lift_equipment_penalty_per_mass * mass,
			self.flight.lift_min_seconds, self.flight.lift_max_seconds),
		mass = mass,
		equipment_mass = mass,
		capacity = body.capacity,
		used_capacity = usedCapacity,
		remaining_capacity = body.capacity - usedCapacity,
	}
end

-- Damage per second from one gun firing nonstop (bursts count their pause; ignores misses and reloads).
function Catalog.weaponDPS(weapon)
	if weapon.fire_mode == "burst" then return weapon.damage * weapon.burst_count / weapon.burst_period end
	return weapon.damage / weapon.shot_interval
end

-- How hard one shot hits, 1-5, for the hangar's pips (per-shot damage runs from 1.6 to 260).
-- Does a weapon of this class go on a mount of this size (a bigger mount takes smaller weapons)?
function Catalog.mountFits(mountType, class)
	return COMPATIBLE[mountType] ~= nil and COMPATIBLE[mountType][class] == true
end
function Catalog.hitRating(weapon)
	for rating, limit in { 2, 10, 25, 60 } do if weapon.damage <= limit then return rating end end
	return 5
end

return Catalog
