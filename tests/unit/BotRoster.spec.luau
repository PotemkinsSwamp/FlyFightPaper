local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.BotRosterRules)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local config = require(Root.Generated.Gameplay)

local Spec = {}
local function human(key, teamId, name)
	return { key = "actor:" .. key, userKey = key, controllerType = "human", teamId = teamId,
		displayName = name or ("Pilot " .. key), state = "FLYING" }
end
local function bot(key, profileName, teamId, state, extra)
	local row = { key = "bot:" .. key, controllerType = "bot", profileName = profileName,
		displayName = "Milo " .. key, avatarPresetId = "paper_pilot_skywright_v1", teamId = teamId,
		state = state or "FLYING" }
	for field, value in pairs(extra or {}) do row[field] = value end
	return row
end
local function input(eligibility, mode, actors, queue, seed, serverClass, serial)
	return { eligibility = eligibility or "rookie", serverClass = serverClass or eligibility or "rookie",
		mode = mode or "FFA", actors = actors or {}, pendingHumanQueue = queue or {}, seed = seed or 17029,
		botIdentitySerial = serial or 1, config = config }
end
local function result(inputValue)
	local value, reason = Rules.plan(inputValue)
	assert(value, reason)
	return value
end
local function countProfiles(rows)
	local counts = { rookie = 0, regular = 0, experienced = 0 }
	for _, row in ipairs(rows) do counts[row.profileName] += 1 end
	return counts
end

function Spec.run()
	local resultSet, test = Suite.new()
	test("Humans may share Roblox display names", function()
		local plan = result(input("rookie", "FFA", {human("h1", nil, "Sam"), human("h2", nil, "Sam")}))
		assert(#plan.botAdds == 10 and plan.actorCount == 12)
		for _, row in ipairs(plan.botAdds) do assert(row.displayName ~= "Sam") end
	end)

	test("BR01 seeded recipes repeat, while independent seeds vary", function()
		local first = result(input("rookie", "FFA", { human("h1") }, {}, 17029))
		local same = result(input("rookie", "FFA", { human("h1") }, {}, 17029))
		local changed = result(input("rookie", "FFA", { human("h1") }, {}, 17030))
		assert(#first.botAdds == 11 and #same.botAdds == 11 and first.actorCount == 12)
		for index, row in ipairs(first.botAdds) do
			assert(row.profileName == same.botAdds[index].profileName)
			assert(row.displayName == same.botAdds[index].displayName)
			assert(row.avatarPresetId == same.botAdds[index].avatarPresetId)
			assert(row.actorKey == same.botAdds[index].actorKey)
		end
		local changedRecipe = false
		for index, row in ipairs(first.botAdds) do
			if row.displayName ~= changed.botAdds[index].displayName or row.profileName ~= changed.botAdds[index].profileName then
				changedRecipe = true
			end
		end
		assert(changedRecipe)
	end)

	test("BR02 configured mix probabilities hold across seeds and small populations", function()
		assert(config.bots.rookie_mix.rookie == 0.85 and config.bots.rookie_mix.regular == 0.15
			and config.bots.rookie_mix.experienced == 0)
		assert(config.bots.regular_mix.regular == 0.85 and config.bots.regular_mix.experienced == 0.15)
		local rookieRegular, regularExperienced = 0, 0
		local fullRookieRegular, fullRegularExperienced = 0, 0
		for seed = 1, 1000 do
			local novice = result(input("rookie", "FFA", { human("h1") }, {}, seed))
			local noviceSmall = result(input("rookie", "FFA", { human("h1"), human("h2") }, {}, seed))
			assert(countProfiles(novice.botAdds).experienced == 0)
			assert(#noviceSmall.botAdds == 10)
			local singleNoviceVacancy = result(input("rookie", "FFA",
				{ human("a"), human("b"), human("c"), human("d"), human("e"), human("f"), human("g"), human("h"), human("i"), human("j"), human("k") }, {}, seed))
			local singleRegularVacancy = result(input("regular", "FFA",
				{ human("a"), human("b"), human("c"), human("d"), human("e"), human("f"), human("g"), human("h"), human("i"), human("j"), human("k") }, {}, seed))
			if singleNoviceVacancy.botAdds[1].profileName == "regular" then rookieRegular += 1 end
			if singleRegularVacancy.botAdds[1].profileName == "experienced" then regularExperienced += 1 end
			if seed <= 200 then
				local rookieFull = result(input("rookie", "FFA", {}, {}, seed))
				local regularFull = result(input("regular", "FFA", {}, {}, seed))
				assert(#rookieFull.botAdds == 12 and #regularFull.botAdds == 12)
				local rookieCounts, regularCounts = countProfiles(rookieFull.botAdds), countProfiles(regularFull.botAdds)
				assert(rookieCounts.experienced == 0 and regularCounts.experienced <= 1)
				fullRookieRegular += rookieCounts.regular
				fullRegularExperienced += regularCounts.experienced
			end
		end
		assert(rookieRegular >= 110 and rookieRegular <= 190, "rookie 15% sample outside tolerance: " .. rookieRegular)
		assert(regularExperienced >= 110 and regularExperienced <= 190,
			"regular 15% sample outside tolerance: " .. regularExperienced)
		assert(fullRookieRegular >= 300 and fullRookieRegular <= 420,
			"full rookie 15% mix outside tolerance: " .. fullRookieRegular)
		assert(fullRegularExperienced >= 130 and fullRegularExperienced <= 200,
			"full regular capped mix outside tolerance: " .. fullRegularExperienced)
	end)

	test("BR03 TDM and CONTROL both balance teams and cap experienced bots per team", function()
		for _, mode in ipairs({ "TDM", "CONTROL" }) do
			local actors = { human("a", "team:1"), human("b", "team:2"), human("c", "team:1"), human("d", "team:2") }
			local planned = result(input("regular", mode, actors, {}, 777))
			local experienced = { ["team:1"] = 0, ["team:2"] = 0 }
			local teams = { ["team:1"] = 0, ["team:2"] = 0 }
			for _, actor in ipairs(actors) do teams[actor.teamId] += 1 end
			for _, row in ipairs(planned.botAdds) do
				teams[row.teamId] += 1
				if row.profileName == "experienced" then experienced[row.teamId] += 1 end
			end
			assert(teams["team:1"] == teams["team:2"] and #planned.botAdds == 8)
			assert(experienced["team:1"] <= 1 and experienced["team:2"] <= 1)
		end
		for _, mode in ipairs({ "TDM", "CONTROL" }) do
			local solo = result(input("regular", mode, { human("solo", "team:1") }, {}, 44))
			assert(solo.botAdds[1].teamId == "team:2")
		end
		local humanJoin = assert(Rules.humanPriority(input("rookie", "CONTROL",
			{ human("one", "team:1"), human("two", "team:1"), human("three", "team:2") },
			{ { userKey = "joining", arrivalOrder = 1 } }, 44)))
		assert(humanJoin.admission.teamId == "team:2")
	end)

	test("BR04 invalid existing novice profile and experienced cap fail closed", function()
		local novice = Rules.plan(input("rookie", "FFA", { human("h"), bot("veteran", "experienced") }, {}, 10))
		assert(novice == nil)
		for _, mode in ipairs({ "TDM", "CONTROL" }) do
			local actors = { human("a", "team:1"), bot("x", "experienced", "team:1"),
				bot("y", "experienced", "team:1") }
			local rejected = Rules.plan(input("regular", mode, actors, {}, 9))
			assert(rejected == nil)
		end
	end)

	test("BR05 refill preserves existing profile and consumes caller monotonic serial", function()
		local actors = { human("h1"), bot("kept", "experienced") }
		for index = 3, 11 do table.insert(actors, human("h" .. index)) end
		local oldProfile = actors[2].profileName
		local planned = result(input("regular", "FFA", actors, {}, 99, nil, 730))
		assert(actors[2].profileName == oldProfile)
		assert(#planned.botAdds == 1 and planned.botAdds[1].identitySerial == 730)
		assert(planned.botAdds[1].actorKey == "bot-roster:730" and planned.nextBotIdentitySerial == 731)
		local retired = result(input("regular", "FFA", { human("h1") }, {}, 99, nil, 741))
		assert(retired.botAdds[1].actorKey == "bot-roster:741")
		assert(retired.botAdds[1].actorKey ~= planned.botAdds[1].actorKey)
	end)

	test("BR06 humans consume vacancies before bot fill in stable queue order", function()
		local actors = {}
		for index = 1, 10 do table.insert(actors, human("h" .. index)) end
		local queue = { { userKey = "later", arrivalOrder = 8 }, { userKey = "first", arrivalOrder = 2 },
			{ userKey = "third", arrivalOrder = 12 } }
		local planned = result(input("rookie", "FFA", actors, queue, 123))
		assert(#planned.admissions == 2 and planned.admissions[1].userKey == "first")
		assert(planned.admissions[2].userKey == "later")
		assert(#planned.botAdds == 0 and planned.waitingHumanKeys[1] == "third")
	end)

	test("BR07 eligibility change routes the server and leaves active bots untouched", function()
		local actors = { human("h1"), bot("active", "rookie") }
		local planned = result(input("regular", "FFA", actors, {}, 17029, "rookie"))
		assert(planned.status == "route_required" and #planned.botAdds == 0)
		assert(actors[2].profileName == "rookie")
	end)

	test("BR08 full flying room queues humans without a release proposal", function()
		local actors = { human("h1") }
		for index = 2, 12 do table.insert(actors, bot(tostring(index), "rookie", nil, "FLYING")) end
		local policy = assert(Rules.humanPriority(input("rookie", "FFA", actors,
			{ { userKey = "waiting", arrivalOrder = 1 } }, 5)))
		assert(policy.status == "wait_menu" and policy.admission == nil and policy.releaseProposal == nil)
	end)

	test("BR09 first queued human uses vacancy without deleting an actor", function()
		local actors = { human("h1"), bot("one", "rookie") }
		local policy = assert(Rules.humanPriority(input("rookie", "FFA", actors,
			{ { userKey = "first", arrivalOrder = 4 }, { userKey = "second", arrivalOrder = 5 } }, 8)))
		assert(policy.status == "admit_vacancy" and policy.admission.userKey == "first")
		assert(policy.releaseProposal == nil and #actors == 2)
	end)

	test("BR10 dead or explicitly safe parked bots may be proposed; flying contradiction may not", function()
		local actors = { human("h1") }
		for index = 2, 11 do table.insert(actors, bot(tostring(index), "regular", nil, "FLYING")) end
		table.insert(actors, bot("flying-flag", "regular", nil, "FLYING",
			{ trustedSafeParkedService = true, recentDamageCredit = false }))
		local queue = { { userKey = "waiting", arrivalOrder = 1 } }
		local contradictory = assert(Rules.humanPriority(input("regular", "FFA", actors, queue, 14)))
		assert(contradictory.status == "wait_menu" and contradictory.releaseProposal == nil)
		actors[12] = bot("parked-credit", "regular", nil, "SERVICING",
			{ trustedSafeParkedService = true, recentDamageCredit = true })
		local credited = assert(Rules.humanPriority(input("regular", "FFA", actors, queue, 14)))
		assert(credited.status == "wait_menu")
		actors[12] = bot("parked-safe", "regular", nil, "SERVICING",
			{ trustedSafeParkedService = true, recentDamageCredit = false })
		local parked = assert(Rules.humanPriority(input("regular", "FFA", actors, queue, 14)))
		assert(parked.status == "release_proposed" and parked.releaseProposal.actorKey == "bot:parked-safe")
		local deadActors = { human("deadcase") }
		for index = 2, 12 do table.insert(deadActors, bot("f" .. index, "regular", nil, "FLYING")) end
		deadActors[12] = bot("dead", "regular", nil, "DESTROYED")
		local dead = assert(Rules.humanPriority(input("regular", "FFA", deadActors, queue, 14)))
		assert(dead.status == "release_proposed" and dead.releaseProposal.actorKey == "bot:dead")
		assert(dead.releaseProposal.damageCreditDisposition == "preserve_round_ledger")
	end)

	test("BR11 boundary rebuild requires trusted boundary and settled cleanup", function()
		local actors = { human("h1") }
		for index = 2, 12 do table.insert(actors, bot("boundary" .. index, "rookie")) end
		local queue = { { userKey = "waiting", arrivalOrder = 1 } }
		local request = input("rookie", "FFA", actors, queue, 19)
		request.trustedRoundBoundary = true
		assert(assert(Rules.humanPriority(request)).status == "wait_menu")
		request.roundLedgerSettled, request.botCleanupReady = true, true
		local policy = assert(Rules.humanPriority(request))
		assert(policy.status == "round_boundary_rebuild" and policy.admission.userKey == "waiting")
		assert(policy.releaseProposal.reason == "round_boundary" and policy.releaseProposal.preserveRoundLedger)
	end)

	test("BR12 fictional recipes are unique, bounded, and have no user identity or inherited life", function()
		local planned = result(input("rookie", "FFA", { human("h1") }, {}, 41))
		local names, keys = {}, {}
		for _, row in ipairs(planned.botAdds) do
			assert(not names[row.displayName] and not keys[row.actorKey])
			names[row.displayName], keys[row.actorKey] = true, true
			-- Roblox username shape: 3-20 letters/digits, at most one underscore, not at either end.
			assert(#row.displayName >= 3 and #row.displayName <= 20 and row.displayName:match("^[%w]+_?[%w]+$"), row.displayName)
			assert(row.avatarPresetId:match("^paper_pilot_[a-z]+_v1$"))
			assert(row.userId == nil and row.nativeUserId == nil and row.userKey == nil)
			assert(row.lifeId == nil and row.streak == nil and row.matchParticipation == nil)
		end
	end)

	test("BR13 payer, age, rank, score, and purchase fields do not affect profile choice", function()
		local plain = input("regular", "FFA", { human("h1") }, {}, 202)
		local decorated = input("regular", "FFA", { human("h1") }, {}, 202)
		decorated.payer, decorated.age, decorated.rank, decorated.score = true, 99, 500, 999999
		decorated.purchasePrompt = "buy"
		local first, second = result(plain), result(decorated)
		for index, row in ipairs(first.botAdds) do
			assert(row.profileName == second.botAdds[index].profileName)
			assert(row.displayName == second.botAdds[index].displayName)
		end
	end)

	test("BR14 public projection exposes only ordinary presentation fields", function()
		local internal = bot("private", "experienced", "team:1", "FLYING", {
			publicId = "pilot-slot-4", userId = 123456, username = "NativeIdentity", bot = true,
			controllerType = "bot", controller = "BotService", tier = "experienced", profileName = "experienced" })
		local projection = assert(Rules.publicProjection(internal))
		assert(projection.id == "pilot-slot-4" and projection.displayName == internal.displayName)
		assert(projection.avatarPresetId == internal.avatarPresetId)
		for _, field in ipairs({ "userId", "username", "bot", "controllerType", "controller", "profileName", "tier", "nativeIdentity", "key" }) do
			assert(projection[field] == nil, "leaked " .. field)
		end
	end)

	test("BR15 rejects invalid bounds, sparse inputs, duplicate humans, and serial collisions", function()
		local full = {}
		for index = 1, 12 do table.insert(full, human("h" .. index)) end
		assert(result(input("rookie", "FFA", full, {}, 1)).actorCount == 12)
		table.insert(full, human("extra"))
		local over = Rules.plan(input("rookie", "FFA", full, {}, 1))
		assert(over == nil)
		local sparse = Rules.plan(input("rookie", "FFA", { [1] = human("a"), [3] = human("c") }, {}, 1))
		assert(sparse == nil)
		local duplicate = Rules.plan(input("rookie", "FFA", {},
			{ { userKey = "same", arrivalOrder = 1 }, { userKey = "same", arrivalOrder = 2 } }, 1))
		assert(duplicate == nil)
		local reused = bot("old", "rookie", nil, "FLYING")
		reused.key = "bot-roster:1"
		local repeatedSerial = Rules.plan(input("rookie", "FFA", { reused }, {}, 1, nil, 1))
		assert(repeatedSerial == nil, "caller must advance the never-reused serial")
	end)

	return resultSet
end

return Spec
