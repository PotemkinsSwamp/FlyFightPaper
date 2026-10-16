-- Pure candidate rules and Catalog parity. Run through tests/unit/TestRunner in Studio.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Catalog = require(Root.Shared.Catalog)
local Config = require(Root.Generated.Catalog)
local BuilderModel = require(Root.Shared.BuilderModel)
local Suite = require(game:GetService("ServerStorage").FlyFightPaperTests.fixtures.Suite)

local function allOwned()
	local ownership = {}
	for _, entry in ipairs(Config.structures) do ownership[entry.id] = true end
	for _, entry in ipairs(Config.weapons) do ownership[entry.id] = true end
	for _, entry in ipairs(Config.utilities) do ownership[entry.id] = true end
	return ownership
end

local Spec = {}

function Spec.run()
	local result, test = Suite.new()
	local catalog = Catalog.new(Config)
	local ownership = allOwned()
	local starter = catalog:starterLoadout()
	test("a third weapon type is refused without changing the local draft",function()
		local model=BuilderModel.new(catalog,starter,ownership,50)
		assert(model:selectMount(2,"staple"))
		local before=model.candidate
		local ok,reason=model:selectMount(3,"rubber")
		assert(not ok and reason=="two weapon types per plane" and model.candidate==before)
		assert(model:selectMount(3,"staple") and model:selectMount(2,"pellet"))
	end)
	test("starter stats exactly match Catalog and legal candidate", function()
		local model = BuilderModel.new(catalog, starter, ownership, 50)
		local stats = assert(model:stats())
		local expected = assert(catalog:deriveStats(starter))
		assert(stats.health == expected.health and stats.speed == expected.speed and stats.turn == expected.turn and stats.lift == expected.lift)
		assert(stats.health == 120 and stats.speed == 107.6 and math.abs(stats.turn - 116.9) < 1e-6 and stats.lift == 90)
	end)
	test("ordered six-mount heavy body pads every empty position with false", function()
		local model = BuilderModel.new(catalog, starter, ownership, 50)
		assert(model:selectStructure("body", "body_heavy"))
		assert(#model.candidate.weapon_mounts == 6)
		for index = 3, 6 do assert(model.candidate.weapon_mounts[index] == false) end
		assert(catalog:validateLoadout(model.candidate, ownership, 50))
	end)
	test("standard-to-heavy and heavy-to-slim normalize ordered mounts and report local clears", function()
		local model = BuilderModel.new(catalog, starter, ownership, 50)
		assert(model:selectStructure("body", "body_heavy"))
		for index = 3, 6 do assert(model:selectMount(index, "pellet")) end
		assert(#model.candidate.weapon_mounts == 6)
		assert(model:selectStructure("body", "body_slim"))
		assert(#model.candidate.weapon_mounts == 3)
		assert(string.find(model.message, "3 incompatible or excess", 1, true))
		assert(model:validate(model.candidate))
	end)
	test("capacity, mount compatibility, unowned and level restrictions reject", function()
		local model = BuilderModel.new(catalog, starter, ownership, 50)
		local lowCapacityConfig = table.clone(Config)
		lowCapacityConfig.structures = table.clone(Config.structures)
		for index, entry in ipairs(lowCapacityConfig.structures) do
			if entry.id == "body_standard" then
				local changed = table.clone(entry); changed.capacity = 1
				lowCapacityConfig.structures[index] = changed
			end
		end
		local lowCapacityCatalog = Catalog.new(lowCapacityConfig)
		local tooHeavy = lowCapacityCatalog:starterLoadout()
		local ok, reason = lowCapacityCatalog:validateLoadout(tooHeavy, ownership, 50)
		assert(not ok and string.find(reason, "capacity", 1, true))
		local incompatible = BuilderModel.clone(starter)
		incompatible.weapon_mounts[3] = "pencil"
		ok, reason = model:setCandidate(incompatible)
		assert(not ok and string.find(reason, "incompatible", 1, true))
		model.level = 1
		ok, reason = model:selectStructure("body", "body_slim")
		assert(not ok and string.find(reason, "requires level", 1, true))
		model.level = 50
		model.ownership.body_slim = nil
		ok, reason = model:selectStructure("body", "body_slim")
		assert(not ok and string.find(reason, "not owned", 1, true))
	end)
	test("unchanged refresh preserves staged edits; revision and preset selection reset explicitly", function()
		local model = BuilderModel.new(catalog, starter, ownership, 50)
		local vm = { selectedLoadout = starter, selectedRevision = 7, profile = { ownership = ownership, level = 50 } }
		model:update(vm)
		local edited = BuilderModel.clone(starter); edited.nose = "nose_1"
		assert(model:setCandidate(edited))
		model:update(vm)
		assert(model.candidate.nose == "nose_1", "snapshot refresh erased draft")
		local reflected = { selectedLoadout = edited, profile = { ownership = ownership, level = 50 } }
		model:update(reflected)
		assert(model.candidate.nose == "nose_1" and model.changed, "onSelect reflection was treated as a committed build")
		vm.selectedRevision = 8
		model:update(vm)
		assert(model.candidate.nose == starter.nose, "explicit selection revision did not reset draft")
		assert(model:selectPreset(edited))
		assert(model.candidate.nose == "nose_1")
	end)
	test("heavy reference stats stay identical to Catalog calculation", function()
		local heavy = { body = "body_heavy_mk2", nose = "nose_0", wings = "wings_0", tail = "tail_0", utility = nil,
			weapon_mounts = { "pencil", "pencil", false, false, false, false } }
		local model = BuilderModel.new(catalog, heavy, ownership, 50)
		local stats = assert(model:stats())
		assert(stats.health == 300 and stats.speed == 62.8 and math.abs(stats.turn - 72.45) < 1e-6 and stats.lift == 61.5)
	end)
	test("smart placing: a weapon too big for the chosen mount goes where it fits and moves what was there", function()
		local heavy = { body = "body_heavy", nose = "nose_0", wings = "wings_0", tail = "tail_0",
			weapon_mounts = { "paperclip", "paperclip", false, false, false, false } }
		local model = BuilderModel.new(catalog, heavy, ownership, 50)
		local ok, index = model:placeWeapon("pencil", 3) -- a medium mount is chosen; the heavy mounts hold paperclips
		assert(ok and index == 1 and model.candidate.weapon_mounts[1] == "pencil", tostring(index))
		local clips = 0
		for _, w in model.candidate.weapon_mounts do if w == "paperclip" then clips += 1 end end
		assert(clips == 2, "both paperclips kept, one moved to a medium mount")
	end)
	test("a weapon that can't go on says why: no mount of its size, or no room", function()
		local slim = { body = "body_slim", nose = "nose_0", wings = "wings_0", tail = "tail_0", weapon_mounts = { false, false, false } }
		local _, why = BuilderModel.new(catalog, slim, ownership, 50):findPlace("pencil", 1)
		assert(why == "No heavy mount", tostring(why))
		local full = { body = "body_standard", nose = "nose_0", wings = "wings_0", tail = "tail_0", weapon_mounts = { false, false, "pellet", "pellet" } }
		local model = BuilderModel.new(catalog, full, ownership, 50)
		_, why = model:findPlace("pencil", 2)
		assert(why == "Make room for a heavy", tostring(why))
		assert(not model:placeWeapon("pencil", 2) and model.candidate.weapon_mounts[3] == "pellet", "a refused pick changes nothing")
		assert(model:findPlace("staple", 1), "a light weapon still fits")
	end)
	return result
end
return Spec
