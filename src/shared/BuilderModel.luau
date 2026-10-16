-- Local-only equipment candidate. Catalog remains the only source of legality and stats.
local BuilderModel = {}
BuilderModel.__index = BuilderModel

local function cloneLoadout(source)
	if type(source) ~= "table" then return nil end
	local result = { body = source.body, nose = source.nose, wings = source.wings, tail = source.tail, utility = source.utility }
	result.weapon_mounts = {}
	for index, value in ipairs(source.weapon_mounts or {}) do result.weapon_mounts[index] = value end
	return result
end

local function equal(a, b)
	if not a or not b then return a == b end
	for _, key in ipairs({ "body", "nose", "wings", "tail", "utility" }) do
		if a[key] ~= b[key] then return false end
	end
	if #a.weapon_mounts ~= #b.weapon_mounts then return false end
	for i = 1, #a.weapon_mounts do if a.weapon_mounts[i] ~= b.weapon_mounts[i] then return false end end
	return true
end

function BuilderModel.new(catalog, loadout, ownership, level)
	assert(type(catalog) == "table" and type(catalog.validateLoadout) == "function" and type(catalog.deriveStats) == "function", "Builder requires Catalog")
	local self = setmetatable({ catalog = catalog, ownership = ownership or {}, level = level or 1, message = "", changed = false }, BuilderModel)
	self:reset(loadout, nil)
	return self
end

function BuilderModel:reset(loadout, revision)
	local candidate = cloneLoadout(loadout) or self.catalog:starterLoadout()
	local body = self.catalog:get(candidate.body)
	if body then
		local mounts = {}
		for index = 1, body.mount_count do mounts[index] = candidate.weapon_mounts[index] or false end
		candidate.weapon_mounts = mounts
	end
	self.candidate, self.baseline, self.authoritative, self.revision, self.message, self.changed = candidate, cloneLoadout(candidate), cloneLoadout(candidate), revision, "", false
end

function BuilderModel:update(vm)
	vm = type(vm) == "table" and vm or {}
	local profile = vm.profile or {}
	self.level = type(profile.level) == "number" and math.max(1, math.floor(profile.level)) or 1
	self.ownership = type(profile.ownership) == "table" and profile.ownership or {}
	local incoming = cloneLoadout(vm.selectedLoadout)
	local hasRevision = vm.selectedRevision ~= nil
	if hasRevision and vm.selectedRevision ~= self.revision then
		self:reset(incoming, vm.selectedRevision)
	elseif not hasRevision and incoming and not equal(incoming, self.authoritative) and not equal(incoming, self.candidate) then
		-- A changed selection matching this candidate reflects the local onSelect callback.
		-- A different selection from the parent is treated as an explicit external selection.
		self:reset(incoming, nil)
	end
	if incoming then self.authoritative = incoming end
end

function BuilderModel:validate(candidate)
	return self.catalog:validateLoadout(candidate, self.ownership, self.level)
end

function BuilderModel:stats(candidate)
	local valid, reason = self:validate(candidate or self.candidate)
	if not valid then return nil, reason end
	return self.catalog:deriveStats(candidate or self.candidate)
end

function BuilderModel:selectStructure(slot, id)
	if slot ~= "body" and slot ~= "nose" and slot ~= "wings" and slot ~= "tail" then return false, "Unknown structure slot" end
	local definition = self.catalog:get(id)
	if not definition or definition.slot ~= slot then return false, "This selection is not a " .. slot end
	if definition.min_level > self.level then return false, id .. " requires level " .. tostring(definition.min_level) end
	if self.ownership[id] ~= true then return false, "not owned: " .. id end
	local nextBuild = cloneLoadout(self.candidate)
	nextBuild[slot] = id
	if slot == "body" then
		local body = definition
		local mounts = {}
		local cleared = 0
		for index = 1, body.mount_count do
			mounts[index] = false
		end
		nextBuild.weapon_mounts = mounts
		local baseValid, baseReason = self:validate(nextBuild)
		if not baseValid then return false, baseReason end
		-- Validate each retained ordered mount against Catalog. This preserves the
		-- earliest legal mounts without copying Catalog's compatibility/capacity rules.
		for index = 1, body.mount_count do
			local prior = self.candidate.weapon_mounts[index]
			if prior and prior ~= false then
				mounts[index] = prior
				local valid = self:validate(nextBuild)
				if not valid then mounts[index], cleared = false, cleared + 1 end
			end
		end
		for index = body.mount_count + 1, #self.candidate.weapon_mounts do if self.candidate.weapon_mounts[index] ~= false then cleared += 1 end end
		if cleared > 0 then self.message = "Body changed. " .. tostring(cleared) .. " incompatible or excess mount(s) were cleared from this local draft." end
	end
	local valid, reason = self:validate(nextBuild)
	if not valid then return false, reason end
	return self:setCandidate(nextBuild)
end

function BuilderModel:setCandidate(candidate)
	local valid, reason = self:validate(candidate)
	if not valid then return false, reason end
	self.candidate = cloneLoadout(candidate)
	self.changed = not equal(self.candidate, self.baseline)
	return true
end

function BuilderModel:selectMount(index, id)
	local build = cloneLoadout(self.candidate)
	local body = self.catalog:get(build.body)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > body.mount_count then return false, "Mount is unavailable on this body" end
	build.weapon_mounts[index] = id or false
	return self:setCandidate(build)
end

-- Every arrangement worth trying when weapon `id` is picked with mount `selected` chosen (Alan's note 20, for young
-- kids: no "no" when a fix exists), best first: on the chosen mount; on an empty mount; on a taken mount whose
-- weapon moves to an empty one (or the chosen one); finally swapping out every copy of the chosen mount's weapon.
local function arrangements(draft, id, selected)
	local mounts, out = draft.weapon_mounts, {}
	local function with(changes)
		local build = cloneLoadout(draft)
		for index, value in pairs(changes) do build.weapon_mounts[index] = value end
		table.insert(out, { build = build, index = next(changes) })
	end
	with({ [selected] = id })
	for i = 1, #mounts do if i ~= selected and not mounts[i] then with({ [i] = id }) end end
	for i = 1, #mounts do
		if i ~= selected and mounts[i] and mounts[i] ~= id then
			for k = 1, #mounts do
				if k ~= i and (not mounts[k] or k == selected) then
					local build = cloneLoadout(draft)
					build.weapon_mounts[i], build.weapon_mounts[k] = id, mounts[i]
					table.insert(out, { build = build, index = i })
				end
			end
		end
	end
	-- Replacing one of a pair would make a third type: swap every mount holding the old weapon, or empty the ones
	-- the new weapon doesn't fit.
	local old = mounts[selected]
	if old then
		for _, fill in { id, false } do
			local build = cloneLoadout(draft)
			for k, w in build.weapon_mounts do if w == old then build.weapon_mounts[k] = k == selected and id or fill end end
			table.insert(out, { build = build, index = selected })
		end
	end
	return out
end

-- The first legal arrangement for weapon `id`, or nil and why it can't go on (for a crossed-out card, note 21).
function BuilderModel:findPlace(id, selected)
	local body, weapon = self.catalog:get(self.candidate.body), self.catalog:get(id)
	selected = math.clamp(selected or 1, 1, body.mount_count)
	for _, option in arrangements(self.candidate, id, selected) do
		if self:validate(option.build) then return option end
	end
	local fits = false
	for _, mountType in body.mount_types do fits = fits or self.catalog.mountFits(mountType, weapon.class) end
	if not fits then return nil, "No " .. weapon.class .. " mount" end
	local types = {}
	for _, w in self.candidate.weapon_mounts do if w and w ~= id then types[w] = true end end
	if next(types) and next(types, next(types)) then return nil, "Already two weapon types" end
	return nil, "Make room for a " .. weapon.class
end

-- Put weapon `id` on the plane (chosen mount `selected`), moving things around if needed. Returns the mount used.
function BuilderModel:placeWeapon(id, selected)
	local option, reason = self:findPlace(id, selected)
	if not option then return false, reason end
	self:setCandidate(option.build)
	return true, option.index
end

function BuilderModel:selectUtility(id)
	local build = cloneLoadout(self.candidate)
	build.utility = id
	return self:setCandidate(build)
end

function BuilderModel:selectPreset(loadout)
	local candidate = cloneLoadout(loadout)
	if not candidate then return false, "Preset is empty" end
	local body = self.catalog:get(candidate.body)
	if not body then return false, "Preset has an unknown body" end
	local dense = {}
	for index = 1, body.mount_count do dense[index] = candidate.weapon_mounts[index] or false end
	candidate.weapon_mounts = dense
	local valid, reason = self:validate(candidate)
	if not valid then return false, reason end
	self.candidate, self.changed, self.message = candidate, not equal(candidate, self.baseline), "Preset loaded into the local draft. Apply it only when the server allows it."
	return true
end

function BuilderModel.clone(loadout) return cloneLoadout(loadout) end
function BuilderModel.equal(a, b) return equal(a, b) end
return BuilderModel
