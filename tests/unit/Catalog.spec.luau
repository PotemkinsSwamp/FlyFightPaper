-- Studio unit suite for CFG02/CFG03. Fixtures come from generated modules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local root = ReplicatedStorage:WaitForChild("FlyFightPaper")
local generated = root:WaitForChild("Generated")
local shared = root:WaitForChild("Shared")
local Catalog = require(shared:WaitForChild("Catalog"))
local JSONTypes = require(generated:WaitForChild("JSONTypes"))
local catalogConfig = require(generated:WaitForChild("Catalog"))

local Suite = {}

local function expect(condition, message)
	if not condition then
		error(message or "expectation failed", 2)
	end
end

local function expectRejected(catalog, loadout, ownership, level, messagePart)
	local result, err = catalog:validateLoadout(loadout, ownership, level)
	expect(result == nil and type(err) == "string", "invalid loadout was accepted")
	if messagePart then
		expect(string.find(err, messagePart, 1, true) ~= nil, "unexpected rejection: " .. err)
	end
end

local function cloneLoadout(loadout)
	local mounts = table.clone(loadout.weapon_mounts)
	return {
		body = loadout.body,
		nose = loadout.nose,
		wings = loadout.wings,
		tail = loadout.tail,
		weapon_mounts = mounts,
		utility = loadout.utility,
	}
end

local function cloneTable(value)
	-- JSON null is an identity sentinel, not an ordinary mutable config map.
	if value == JSONTypes.Null or type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = cloneTable(child)
	end
	return copy
end

function Suite.run()
	local catalog = Catalog.new(catalogConfig)
	local output = { passed = 0, failed = 0, results = {} }
	local function check(name, callback)
		local ok, err = pcall(callback)
		table.insert(output.results, { name = name, passed = ok, message = ok and "PASS" or tostring(err) })
		if ok then
			output.passed += 1
		else
			output.failed += 1
		end
	end

	check("CFG02 catalog contains all seeded definitions", function()
		local expectedSlots = { body = 6, nose = 6, wings = 6, tail = 6 }
		for slot, expected in pairs(expectedSlots) do
			local count = 0
			for _, entry in ipairs(catalogConfig.structures) do
				if entry.slot == slot then count += 1 end
			end
			expect(count == expected, slot .. " count mismatch")
		end
		expect(#catalogConfig.structures == 24, "structure count mismatch")
		expect(#catalogConfig.weapons == 6, "weapon count mismatch")
		expect(#catalogConfig.utilities == 3, "utility count mismatch")
		for _, list in ipairs({ catalogConfig.structures, catalogConfig.weapons, catalogConfig.utilities }) do
			for _, definition in ipairs(list) do
				expect(catalog:get(definition.id) == definition, "definition missing from index: " .. definition.id)
			end
		end
		expect(catalog:get("not_a_catalog_id") == nil, "unknown get() ID returned a definition")
	end)

	check("CFG02 starter normalization preserves ordered empty mounts", function()
		local starter = catalog:starterLoadout()
		expect(starter.body == "body_standard" and starter.weapon_mounts[1] == "pellet"
			and starter.weapon_mounts[2] == "pellet", "starter seed IDs changed")
		expect(starter.weapon_mounts[3] == false and starter.weapon_mounts[4] == false,
			"null seed mounts were not normalized to false")
		expect(starter.weapon_mounts[5] == nil and starter.utility == nil, "starter has extra mounts or utility")
		local accepted, err = catalog:validateLoadout(starter, nil, 1)
		expect(accepted == true, err)
		starter.weapon_mounts[3] = "pellet"
		expect(starter.weapon_mounts[4] == false, "filling a mount shifted a later empty slot")
	end)

	check("CFG02 strict shape, holes, excess slots, and unknown fields reject", function()
		local starter = catalog:starterLoadout()
		local hole = cloneLoadout(starter)
		hole.weapon_mounts[2] = nil
		expectRejected(catalog, hole, nil, 1, "ordered")
		local oversized = cloneLoadout(starter)
		table.insert(oversized.weapon_mounts, false)
		expectRejected(catalog, oversized, nil, 1, "ordered")
		local unknown = cloneLoadout(starter)
		unknown.client_price = 0
		expectRejected(catalog, unknown, nil, 1, "unknown loadout field")
		local missing = cloneLoadout(starter)
		missing.tail = nil
		expectRejected(catalog, missing, nil, 1, "tail")
		local arbitraryNull = cloneLoadout(starter)
		arbitraryNull.weapon_mounts[3] = {}
		expectRejected(catalog, arbitraryNull, nil, 1, "false")
		local generatedNull = cloneLoadout(starter)
		generatedNull.weapon_mounts[3] = JSONTypes.Null
		expectRejected(catalog, generatedNull, nil, 1, "false")
		local metatableLoadout = cloneLoadout(starter)
		setmetatable(metatableLoadout, {})
		expectRejected(catalog, metatableLoadout, nil, 1, "plain table")
	end)

	check("CFG02 ordered compatibility and capacity boundaries", function()
		local starter = catalog:starterLoadout()
		local wrongMount = cloneLoadout(starter)
		wrongMount.weapon_mounts[3] = "pencil"
		expectRejected(catalog, wrongMount, nil, 40, "incompatible")
		local full = {
			body = "body_heavy", nose = "nose_0", wings = "wings_0", tail = "tail_0",
			weapon_mounts = { "pencil", "pencil", false, false, false, false }, utility = nil,
		}
		local accepted, err = catalog:validateLoadout(full, nil, 40)
		expect(accepted == true, err)
		local overCapacity = cloneLoadout(full)
		overCapacity.weapon_mounts[4] = "paperclip"
		expectRejected(catalog, overCapacity, nil, 40, "capacity")
		local tooManyHeavy = cloneLoadout(full)
		tooManyHeavy.weapon_mounts[3] = "pencil"
		expectRejected(catalog, tooManyHeavy, nil, 40, "incompatible")
		local unknownWeapon = cloneLoadout(starter)
		unknownWeapon.weapon_mounts[3] = "made_up"
		expectRejected(catalog, unknownWeapon, nil, 40, "unknown weapon")
	end)

	check("CFG02 accepts repeated mounts of two types and refuses a third", function()
		local loadout=catalog:starterLoadout()
		loadout.weapon_mounts={"pellet","staple","staple","pellet"}
		expect(catalog:validateLoadout(loadout,nil,50)==true)
		loadout.weapon_mounts[3]="rubber"
		expectRejected(catalog,loadout,nil,50,"two weapon types per plane")
		loadout.weapon_mounts={"paperclip","paperclip","pellet","staple"}
		expectRejected(catalog,loadout,nil,50,"two weapon types per plane")
		loadout.weapon_mounts={false,false,false,false}
		expect(catalog:validateLoadout(loadout,nil,50)==true)
	end)

	check("CFG02 ownership and level validation", function()
		local starter = catalog:starterLoadout()
		expectRejected(catalog, starter, { body_standard = true, nose_0 = true, wings_0 = true }, 1, "not owned")
		expectRejected(catalog, starter, false, 1, "ownership")
		local locked = cloneLoadout(starter)
		locked.weapon_mounts[1] = "staple"
		expectRejected(catalog, locked, nil, 2, "requires level 3")
		local owned = { body_standard = true, nose_0 = true, wings_0 = true, tail_0 = true, pellet = true }
		local accepted, err = catalog:validateLoadout(starter, owned, 1)
		expect(accepted == true, err)
	end)

	check("CFG03 starter reference stats", function()
		local stats, err = catalog:deriveStats(catalog:starterLoadout())
		expect(stats ~= nil, err)
		expect(stats.health == 120, "starter health mismatch")
		expect(math.abs(stats.speed - 107.6) < 1e-8, "starter speed mismatch")
		expect(math.abs(stats.turn - 116.9) < 1e-6 and stats.lift == 90, "starter turn/lift mismatch")
		expect(stats.mass == 2 and stats.capacity == 6 and stats.used_capacity == 2
			and stats.remaining_capacity == 4, "starter mass/capacity metrics mismatch")
	end)

	check("more turn on a tail or wing always means less health", function()
		for _, slot in ipairs({ "tail", "wings" }) do
			local parts = table.clone(catalog.structuresBySlot[slot])
			table.sort(parts, function(a, b) return a.turn_delta < b.turn_delta end)
			for i = 2, #parts do
				expect(parts[i].health_delta < parts[i - 1].health_delta, slot .. " turn without a health cost: " .. parts[i].id)
			end
		end
		local starter = catalog:starterLoadout()
		local base = assert(catalog:deriveStats(starter))
		starter.tail = "tail_4"
		local fin = assert(catalog:deriveStats(starter))
		expect(fin.pitch > base.pitch * 1.4 and fin.yaw == base.yaw, "best tail must pitch far faster and leave yaw alone")
	end)

	check("CFG03 heavy twin-pencil reference stats", function()
		local heavy = {
			body = "body_heavy_mk2", nose = "nose_0", wings = "wings_0", tail = "tail_0",
			weapon_mounts = { "pencil", "pencil", false, false, false, false }, utility = nil,
		}
		local stats, err = catalog:deriveStats(heavy)
		expect(stats ~= nil, err)
		expect(stats.health == 300, "heavy health mismatch")
		expect(math.abs(stats.speed - 62.8) < 1e-8, "heavy speed mismatch")
		expect(math.abs(stats.turn - 72.45) < 1e-8 and math.abs(stats.lift - 61.5) < 1e-8,
			"heavy turn/lift mismatch")
		expect(stats.mass == 11 and stats.capacity == 10 and stats.used_capacity == 10
			and stats.remaining_capacity == 0, "heavy mass/capacity metrics mismatch")
	end)

	check("equipment mass changes mobility but never health", function()
		local light = catalog:starterLoadout()
		local heavier = cloneLoadout(light)
		heavier.weapon_mounts[3] = "pellet"
		local lightStats = catalog:deriveStats(light)
		local heavyStats = catalog:deriveStats(heavier)
		expect(heavyStats.mass > lightStats.mass, "added weapon mass was not counted")
		expect(heavyStats.health == lightStats.health, "weapon mass changed health")
		expect(heavyStats.speed < lightStats.speed and heavyStats.turn < lightStats.turn
			and heavyStats.lift < lightStats.lift, "weapon mass did not penalize mobility")
		local utilityBuild = cloneLoadout(light)
		utilityBuild.utility = "boost_band"
		local utilityStats = catalog:deriveStats(utilityBuild)
		expect(utilityStats.health == lightStats.health and utilityStats.mass == lightStats.mass + 1.5,
			"utility mass/health accounting mismatch")
	end)

	check("CFG03 mass penalty precedes standard and heavy speed ceilings", function()
		local highSpeedConfig = cloneTable(catalogConfig)
		expect(highSpeedConfig.starter_loadout.weapon_mounts[3] == JSONTypes.Null,
			"config fixture must preserve JSON null identity")
		for _, definition in ipairs(highSpeedConfig.structures) do
			if definition.id == "body_standard" or definition.id == "body_heavy" then
				definition.base_speed = 200
			end
		end
		local highSpeedCatalog = Catalog.new(highSpeedConfig)

		local standard = highSpeedCatalog:starterLoadout()
		local standardStats, standardError = highSpeedCatalog:deriveStats(standard)
		expect(standardStats ~= nil, standardError)
		expect(standardStats.mass > 0, "standard regression build must carry equipment mass")
		expect(standardStats.speed == 135, "standard speed ceiling must apply after mass penalty")

		local heavy = {
			body = "body_heavy", nose = "nose_0", wings = "wings_0", tail = "tail_0",
			weapon_mounts = { "pencil", "pencil", false, false, false, false }, utility = nil,
		}
		local heavyStats, heavyError = highSpeedCatalog:deriveStats(heavy)
		expect(heavyStats ~= nil, heavyError)
		expect(heavyStats.mass > 0, "heavy regression build must carry equipment mass")
		expect(heavyStats.speed == 95, "heavy speed ceiling must apply after mass penalty")
	end)

	check("all 1296 structural combinations keep heavy mobility below lighter chassis with the same parts",function()
		local examined=0
		for _,nose in ipairs(catalog.structuresBySlot.nose) do for _,wings in ipairs(catalog.structuresBySlot.wings) do for _,tail in ipairs(catalog.structuresBySlot.tail) do
			local statsByBody={}
			for _,body in ipairs(catalog.structuresBySlot.body) do
				local mounts={};for i=1,body.mount_count do mounts[i]=false end
				statsByBody[body.id]=assert(catalog:deriveStats({body=body.id,nose=nose.id,wings=wings.id,tail=tail.id,weapon_mounts=mounts}))
				examined+=1
			end
			for _,heavy in ipairs(catalog.structuresBySlot.body) do if heavy.archetype=="heavy" then
				for _,other in ipairs(catalog.structuresBySlot.body) do if other.archetype~="heavy" then
					local a,b=statsByBody[heavy.id],statsByBody[other.id]
					expect(a.speed<b.speed and a.turn<b.turn,"heavy chassis lost its mobility cost")
				end end
			end end
		end end end
		expect(examined==1296,"catalog enumeration missed structural choices")
	end)
	check("every legal weapon arrangement keeps equipment health neutral and charges mass",function()
		local examined=0
		for _,body in ipairs(catalog.structuresBySlot.body) do
			local loadout={body=body.id,nose="nose_0",wings="wings_0",tail="tail_0",weapon_mounts={}}
			for i=1,body.mount_count do loadout.weapon_mounts[i]=false end
			local empty=assert(catalog:deriveStats(loadout))
			local function enumerate(slot)
				if slot>body.mount_count then
					local stats=catalog:deriveStats(loadout)
					if stats then
						examined+=1
						expect(stats.health==empty.health,"weapons added structural durability")
						expect(stats.speed<=empty.speed and stats.turn<=empty.turn and stats.lift<=empty.lift,"equipment escaped its mobility cost")
						expect(stats.used_capacity<=body.capacity,"illegal whole build escaped capacity")
					end
					return
				end
				loadout.weapon_mounts[slot]=false;enumerate(slot+1)
				for _,weapon in ipairs(catalog.weapons) do loadout.weapon_mounts[slot]=weapon.id;enumerate(slot+1) end
			end
			enumerate(1)
		end
		expect(examined>1000,"whole-loadout enumeration missed legal arrangements")
	end)
	check("weapon damage per second and hit rating", function()
		local dps, hit = {}, {}
		for _, weapon in ipairs(catalog.weapons) do dps[weapon.id] = Catalog.weaponDPS(weapon); hit[weapon.id] = Catalog.hitRating(weapon) end
		expect(math.abs(dps.pellet - 20) < 1e-6, "pellet dps " .. tostring(dps.pellet))
		expect(math.abs(dps.staple - 17.5) < 1e-6, "burst dps counts the pause between bursts: " .. tostring(dps.staple))
		expect(math.abs(dps.pencil - 65) < 1e-6, "pencil dps " .. tostring(dps.pencil))
		expect(hit.rubber == 1 and hit.staple == 2 and hit.paperclip == 3 and hit.eraser == 4 and hit.pencil == 5, "hit ratings")
	end)
	return output
end

return Suite
