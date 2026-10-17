-- Pure server-side roster planning. Inputs are trusted server summaries only.
-- Callers own persistence, actor creation/removal, routing, and monotonic bot identity allocation.
local Rules = {}

Rules.MAX_ACTORS = 12
Rules.MAX_PENDING_HUMANS = 64
local UINT32 = 4294967296
local PROFILE_NAMES = { "rookie", "regular", "experienced" }
local PRESETS = {
	"paper_pilot_skywright_v1", "paper_pilot_cloudtail_v1",
	"paper_pilot_inkwing_v1", "paper_pilot_foldcrest_v1",
}
local BotNames = require(script.Parent.BotNames)

local function integer(value, low, high)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= low and value <= high
end

local function denseLength(list, maximum)
	if type(list) ~= "table" then return nil end
	local count, highest = 0, 0
	for key in pairs(list) do
		if not integer(key, 1, maximum) then return nil end
		count += 1
		if key > highest then highest = key end
	end
	if count ~= highest then return nil end
	return count
end

-- FNV-style byte folding plus an integer avalanche. All arithmetic remains exactly
-- representable in Luau's number type; adjacent seat ordinals do not share a linear sample.
local function hash(seed, value)
	local result = seed % UINT32
	for index = 1, #value do
		result = bit32.bxor(result, string.byte(value, index))
		result = (result + bit32.lshift(result, 1) + bit32.lshift(result, 4)
			+ bit32.lshift(result, 7) + bit32.lshift(result, 8) + bit32.lshift(result, 24)) % UINT32
	end
	result = bit32.bxor(result, bit32.rshift(result, 16))
	result = (result + bit32.lshift(result, 3) + bit32.lshift(result, 7)) % UINT32
	result = bit32.bxor(result, bit32.rshift(result, 11))
	result = (result + bit32.lshift(result, 5) + bit32.lshift(result, 9)) % UINT32
	return bit32.bxor(result, bit32.rshift(result, 15))
end

local function teamMode(mode)
	return mode == "TDM" or mode == "CONTROL"
end

local function validMode(mode)
	return mode == "FFA" or teamMode(mode)
end

local function validProfile(profile)
	return profile == "rookie" or profile == "regular" or profile == "experienced"
end

local function validate(input)
	if type(input) ~= "table" then return nil, "input_required" end
	if input.eligibility ~= "rookie" and input.eligibility ~= "regular" then return nil, "invalid_eligibility" end
	if input.serverClass ~= "rookie" and input.serverClass ~= "regular" then return nil, "invalid_server_class" end
	if not integer(input.seed, 0, 4294967295) then return nil, "invalid_seed" end
	if not integer(input.botIdentitySerial, 1, 2147483647) then return nil, "invalid_bot_identity_serial" end
	if not validMode(input.mode) then return nil, "invalid_mode" end
	if type(input.config) ~= "table" or type(input.config.bots) ~= "table" or type(input.config.world) ~= "table" then
		return nil, "gameplay_config_required"
	end
	local maximum = input.config.world.maximum_actors
	local configuredCap = input.config.bots.experienced_cap_per_team_or_ffa
	if maximum ~= Rules.MAX_ACTORS or configuredCap ~= 1 then return nil, "unsupported_roster_config" end
	local actorCount = denseLength(input.actors, Rules.MAX_ACTORS)
	if actorCount == nil then return nil, "actors_must_be_dense_and_at_most_12" end
	local pendingCount = denseLength(input.pendingHumanQueue, Rules.MAX_PENDING_HUMANS)
	if pendingCount == nil then return nil, "pending_queue_must_be_dense_and_bounded" end

	local actorKeys, humanKeys, names, botNames = {}, {}, {}, {}
	local counts = { ["team:1"] = 0, ["team:2"] = 0 }
	local experiencedByGroup = {}
	for index = 1, actorCount do
		local actor = input.actors[index]
		if type(actor) ~= "table" or type(actor.key) ~= "string" or #actor.key < 1 or #actor.key > 80
			or actorKeys[actor.key] then return nil, "invalid_or_duplicate_actor_key" end
		actorKeys[actor.key] = true
		if actor.controllerType ~= "human" and actor.controllerType ~= "bot" then return nil, "invalid_actor_controller" end
		if teamMode(input.mode) then
			if actor.teamId ~= "team:1" and actor.teamId ~= "team:2" then return nil, "invalid_actor_team" end
			counts[actor.teamId] += 1
		elseif actor.teamId ~= nil then
			return nil, "unexpected_actor_team"
		end
		if actor.displayName ~= nil then
			if type(actor.displayName) ~= "string" or #actor.displayName < 1 or #actor.displayName > 48
				or actor.controllerType == "bot" and botNames[actor.displayName] then return nil, "invalid_or_duplicate_display_name" end
			names[actor.displayName] = true
			if actor.controllerType == "bot" then botNames[actor.displayName] = true end
		end
		if actor.controllerType == "human" then
			if type(actor.userKey) ~= "string" or #actor.userKey < 1 or #actor.userKey > 80 or humanKeys[actor.userKey] then
				return nil, "invalid_or_duplicate_human_key"
			end
			humanKeys[actor.userKey] = true
		else
			if not validProfile(actor.profileName) then return nil, "invalid_existing_bot_profile" end
			if type(actor.displayName) ~= "string" or #actor.displayName < 1 or #actor.displayName > 48 then
				return nil, "invalid_existing_bot_name"
			end
			if actor.avatarPresetId ~= nil then
				local presetKnown = false
				for _, preset in ipairs(PRESETS) do if actor.avatarPresetId == preset then presetKnown = true end end
				if not presetKnown then return nil, "invalid_existing_bot_preset" end
			end
			if input.serverClass == "rookie" and actor.profileName == "experienced" then
				return nil, "existing_rookie_roster_has_experienced_bot"
			end
			if actor.profileName == "experienced" then
				local group = input.mode == "FFA" and "ffa" or actor.teamId
				experiencedByGroup[group] = (experiencedByGroup[group] or 0) + 1
			end
		end
	end
	for _, count in pairs(experiencedByGroup) do
		if count > configuredCap then return nil, "existing_experienced_cap_exceeded" end
	end

	local pendingSeen = {}
	for index = 1, pendingCount do
		local queued = input.pendingHumanQueue[index]
		if type(queued) ~= "table" or type(queued.userKey) ~= "string" or #queued.userKey < 1 or #queued.userKey > 80
			or pendingSeen[queued.userKey] or humanKeys[queued.userKey] then return nil, "invalid_or_duplicate_pending_human" end
		if not integer(queued.arrivalOrder, 0, 2147483647) then return nil, "invalid_arrival_order" end
		pendingSeen[queued.userKey] = true
	end
	return { actorCount = actorCount, pendingCount = pendingCount, counts = counts,
		experiencedByGroup = experiencedByGroup, names = names, actorKeys = actorKeys }
end

local function queuedOrder(input)
	local queue = {}
	for _, row in ipairs(input.pendingHumanQueue) do table.insert(queue, row) end
	table.sort(queue, function(a, b)
		if a.arrivalOrder ~= b.arrivalOrder then return a.arrivalOrder < b.arrivalOrder end
		local left, right = hash(input.seed, a.userKey), hash(input.seed, b.userKey)
		if left ~= right then return left < right end
		return a.userKey < b.userKey
	end)
	return queue
end

local function newIdentity(input, names, serial)
	-- Names compare without case, as Roblox's do: "PixelPanda" and "pixelpanda" never meet in one match.
	local taken = {}
	for name in pairs(names) do taken[string.lower(name)] = true end
	for attempt = 1, 64 do
		local draws = 0
		local function pick(n)
			draws += 1
			return hash(input.seed, "identity:" .. tostring(serial) .. ":" .. attempt .. ":" .. draws) % n + 1
		end
		local displayName = BotNames.make(pick)
		if BotNames.valid(displayName) and not taken[string.lower(displayName)] then
			names[displayName] = true
			local presetIndex = (hash(input.seed, "preset:" .. tostring(serial)) % #PRESETS) + 1
			return displayName, PRESETS[presetIndex]
		end
	end
	return nil, nil
end

local function teamForBot(input, counts, ordinal)
	if not teamMode(input.mode) then return nil end
	if counts["team:1"] < counts["team:2"] then return "team:1" end
	if counts["team:2"] < counts["team:1"] then return "team:2" end
	return hash(input.seed, "team:" .. tostring(ordinal)) % 2 == 0 and "team:1" or "team:2"
end

local function teamForHuman(input, counts, userKey)
	if not teamMode(input.mode) then return nil end
	if counts["team:1"] < counts["team:2"] then return "team:1" end
	if counts["team:2"] < counts["team:1"] then return "team:2" end
	return hash(input.seed, "human-team:" .. userKey) % 2 == 0 and "team:1" or "team:2"
end

local function profileFor(input, group, serial, experiencedByGroup)
	local mix = input.config.bots[input.eligibility == "rookie" and "rookie_mix" or "regular_mix"]
	if type(mix) ~= "table" then return nil end
	local sample = hash(input.seed, "profile:" .. tostring(serial)) % 100000
	local profile, cumulative = nil, 0
	for _, name in ipairs(PROFILE_NAMES) do
		local weight = mix[name]
		if type(weight) ~= "number" or weight ~= weight or weight == math.huge or weight == -math.huge
			or weight < 0 or weight > 1 then return nil end
		cumulative += weight * 100000
		if profile == nil and sample < cumulative then profile = name end
	end
	if math.abs(cumulative - 100000) > 0.01 or not profile then return nil end
	if input.eligibility == "rookie" and profile == "experienced" then return nil end
	if profile == "experienced" and (experiencedByGroup[group] or 0) >= input.config.bots.experienced_cap_per_team_or_ffa then
		return "regular"
	end
	return profile
end

-- plan(input) returns additions only. Required fields include trusted eligibility/serverClass,
-- mode/config, dense actor summaries, bounded pendingHumanQueue, uint32 seed, and botIdentitySerial.
-- botIdentitySerial is a caller-owned, match-monotonic next-identity counter. Reserve the returned
-- serial range atomically and never rewind it, including after bot removal, to avoid MatchService history reuse.
function Rules.plan(input)
	local checked, reason = validate(input)
	if not checked then return nil, reason end
	if input.eligibility ~= input.serverClass then
		return { status = "route_required", reason = "eligibility_class_changed", admissions = {}, botAdds = {},
			actorCount = checked.actorCount, nextBotIdentitySerial = input.botIdentitySerial }
	end
	local queue = queuedOrder(input)
	local available = Rules.MAX_ACTORS - checked.actorCount
	local admissions, admittedKeys = {}, {}
	for index = 1, math.min(available, #queue) do
		local queued = queue[index]
		local row = { userKey = queued.userKey, teamId = teamForHuman(input, checked.counts, queued.userKey) }
		if row.teamId then checked.counts[row.teamId] += 1 end
		table.insert(admissions, row)
		admittedKeys[queued.userKey] = true
	end

	local botAdds, seat = {}, checked.actorCount + 1
	local botSeats = available - #admissions
	if input.botIdentitySerial + botSeats > 2147483648 then return nil, "bot_identity_serial_exhausted" end
	while #botAdds < botSeats do
		local serial = input.botIdentitySerial + #botAdds
		local actorKey = "bot-roster:" .. tostring(serial)
		if checked.actorKeys[actorKey] then return nil, "bot_identity_serial_collision" end
		local teamId = teamForBot(input, checked.counts, seat)
		local group = input.mode == "FFA" and "ffa" or teamId
		local profile = profileFor(input, group, serial, checked.experiencedByGroup)
		if not profile then return nil, "invalid_profile_mix" end
		local displayName, avatarPresetId = newIdentity(input, checked.names, serial)
		if not displayName then return nil, "fictional_name_pool_exhausted" end
		checked.actorKeys[actorKey] = true
		table.insert(botAdds, { actorKey = actorKey, identitySerial = serial, profileName = profile,
			displayName = displayName, avatarPresetId = avatarPresetId, teamId = teamId })
		if teamId then checked.counts[teamId] += 1 end
		if profile == "experienced" then checked.experiencedByGroup[group] = (checked.experiencedByGroup[group] or 0) + 1 end
		seat += 1
	end
	local waiting = {}
	for _, queued in ipairs(queue) do if not admittedKeys[queued.userKey] then table.insert(waiting, queued.userKey) end end
	return { status = "ready", eligibility = input.eligibility, actorCount = checked.actorCount + #admissions + #botAdds,
		admissions = admissions, botAdds = botAdds, waitingHumanKeys = waiting,
		nextBotIdentitySerial = input.botIdentitySerial + #botAdds }
end

-- Which bot leaves first for a joining human: a dead one, then one safely parked at its desk, then one flying
-- nobody is fighting, then any bot (Alan 2026-10-17: players join straight into the match, never wait).
local function releaseRank(actor)
	if actor.state == "DESTROYED" then return 0 end
	if (actor.state == "SPAWN_READY" or actor.state == "SERVICING") and actor.trustedSafeParkedService == true
		and actor.recentDamageCredit == false then return 1 end
	return actor.recentDamageCredit == true and 3 or 2
end

local function releaseOrder(input, candidates)
	table.sort(candidates, function(a, b)
		local rankA, rankB = releaseRank(a), releaseRank(b)
		if rankA ~= rankB then return rankA < rankB end
		local tieA, tieB = hash(input.seed, a.key), hash(input.seed, b.key)
		if tieA ~= tieB then return tieA < tieB end
		return a.key < b.key
	end)
	return candidates
end

-- Plan only; lifecycle ownership stays with the caller. Parked bodies require both an
-- approved parked state and explicit safe/no-credit server facts. Boundary rebuilds require
-- a trusted boundary and settled ledger plus bot cleanup readiness.
function Rules.humanPriority(input)
	local checked, reason = validate(input)
	if not checked then return nil, reason end
	if input.eligibility ~= input.serverClass then return { status = "route_required", admission = nil, releaseProposal = nil } end
	local queue = queuedOrder(input)
	local first = queue[1]
	if not first then return { status = "no_pending_human", admission = nil, releaseProposal = nil } end
	if Rules.MAX_ACTORS - checked.actorCount > 0 then
		return { status = "admit_vacancy", admission = { userKey = first.userKey,
			teamId = teamForHuman(input, checked.counts, first.userKey) }, releaseProposal = nil }
	end
	if input.trustedRoundBoundary == true and input.roundLedgerSettled == true and input.botCleanupReady == true then
		return { status = "round_boundary_rebuild", admission = { userKey = first.userKey,
			teamId = teamForHuman(input, checked.counts, first.userKey) },
			releaseProposal = { reason = "round_boundary", preserveRoundLedger = true, cleanupReady = true } }
	end
	local candidates = {}
	for _, actor in ipairs(input.actors) do
		if actor.controllerType == "bot" then table.insert(candidates, actor) end
	end
	releaseOrder(input, candidates)
	if #candidates > 0 then
		local candidate = candidates[1]
		return { status = "release_proposed", admission = nil,
			releaseProposal = { actorKey = candidate.key, reason = ({ "dead_life", "safe_parked_service", "flying_bot",
				"flying_bot" })[releaseRank(candidate) + 1], damageCreditDisposition = "preserve_round_ledger" } }
	end
	return { status = "wait_menu", admission = nil, releaseProposal = nil }
end

-- Public presentation uses an ordinary opaque presentation ID supplied by the parent.
-- Internal actor keys, profile/controller fields, and native identity fields are never projected.
function Rules.publicProjection(actor)
	if type(actor) ~= "table" then return nil, "actor_required" end
	if type(actor.publicId) ~= "string" or #actor.publicId < 1 or #actor.publicId > 80
		or type(actor.displayName) ~= "string" or #actor.displayName < 1 or #actor.displayName > 48
		or type(actor.avatarPresetId) ~= "string" then return nil, "public_identity_required" end
	if actor.teamId ~= nil and actor.teamId ~= "team:1" and actor.teamId ~= "team:2" then return nil, "invalid_public_team" end
	if type(actor.state) ~= "string" then return nil, "public_state_required" end
	return { id = actor.publicId, displayName = actor.displayName, avatarPresetId = actor.avatarPresetId,
		state = actor.state, teamId = actor.teamId }
end

return Rules
