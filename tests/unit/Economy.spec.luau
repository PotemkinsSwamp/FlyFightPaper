local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.EconomyRules)
local Catalog = require(Root.Shared.Catalog)
local CatalogConfig = require(Root.Generated.Catalog)
local EconomyConfig = require(Root.Generated.Economy)
local Suite = require(script.Parent.Parent.fixtures.Suite)

local function profile(paper, xp, ownership)
	return { paperMilli = paper or 0, earnedPaperMilli = 0, purchasedPaperMilli = 0,
		xpMilli = xp or 0, ownership = ownership or {} }
end

local function rejected(result, err, code)
	assert(result == nil and type(err) == "table" and err.type == "EconomyRejected", "expected typed rejection")
	if code then assert(err.code == code, tostring(err.code) .. " != " .. code) end
end

local Spec = {}
function Spec.run()
	local result, test = Suite.new()
	local catalog = Catalog.new(CatalogConfig, require(Root.Generated.Gameplay))
	test("EC01 new reference earns 312.18 Paper and 584.8 XP before final bonuses", function()
		local oldRates=table.clone(EconomyConfig)
		oldRates.paper_per_point,oldRates.xp_per_point=0.4,0.75
		local old=assert(Rules.contributionMilli(780,1,1,oldRates))
		assert(old.paperMilli==312000 and old.xpMilli==585000)
		local reference,points=EconomyConfig.reference_match,EconomyConfig.points
		assert(reference.eliminations==6 and reference.assists==4 and reference.assist_damage_share==0.4
			and reference.paper_targets==2 and reference.control_points==0 and reference.prop_points==nil)
		local assist=math.clamp(5*math.round(100*reference.assist_damage_share/5),points.fold_assist_min,points.fold_assist_max)
		local contribution=reference.eliminations*points.fold+reference.assists*assist
			+reference.paper_targets*points.target+reference.control_points
		assert(contribution==860 and EconomyConfig.paper_per_point==0.363 and EconomyConfig.xp_per_point==0.680)
		local amount = assert(Rules.contributionMilli(contribution, 1, 1))
		assert(amount.paperMilli == 312180 and amount.xpMilli == 584800)
		local finalPaper=(reference.completion and EconomyConfig.completion_paper or 0)
			+reference.expected_win_fraction*EconomyConfig.win_paper+reference.expected_podium_paper
		local finalXP=(reference.completion and EconomyConfig.completion_xp or 0)
			+reference.expected_win_fraction*EconomyConfig.win_xp+reference.expected_podium_xp
		local referenceBonuses = assert(Rules.applyFinalBonuses(profile(), { finalPaper = finalPaper, finalXP = finalXP }, { paper = 1, xp = 1 }, "illustration"))
		assert(referenceBonuses.profile.paperMilli == 120000 and referenceBonuses.profile.xpMilli == 165000)
		assert(amount.paperMilli + referenceBonuses.profile.paperMilli == 432180)
		assert(amount.xpMilli + referenceBonuses.profile.xpMilli == 749800)
	end)
	test("fractional resource earnings retain exact milli residual regardless of partition or order", function()
		local function fold(events)
			local p = profile()
			for i, points in ipairs(events) do p = assert(Rules.applyContribution(p, points, { paper = 1, xp = 1 }, "evt:" .. i)).profile end
			return p
		end
		local a, b = fold({ 1, 2, 3, 4 }), fold({ 4, 3, 2, 1 })
		assert(a.paperMilli == b.paperMilli and a.xpMilli == b.xpMilli)
		local whole=fold({10})
		assert(a.paperMilli==whole.paperMilli and a.xpMilli==whole.xpMilli)
		assert(a.paperMilli == 3630 and a.xpMilli == 6800)
		local paper = assert(Rules.wholeAndResidual(363))
		local xp = assert(Rules.wholeAndResidual(680))
		assert(paper.whole == 0 and paper.residualMilli == 363)
		assert(xp.whole == 0 and xp.residualMilli == 680)
	end)
	test("independent event-time multipliers double only the selected resource and cap at2", function()
		local base = assert(Rules.contributionMilli(1, 1, 1))
		local xp2 = assert(Rules.contributionMilli(1, 1, 2))
		local paper2 = assert(Rules.contributionMilli(1, 2, 1))
		local both = assert(Rules.contributionMilli(1, 2, 2))
		assert(base.paperMilli == 363 and base.xpMilli == 680)
		assert(xp2.paperMilli == 363 and xp2.xpMilli == 1360)
		assert(paper2.paperMilli == 726 and paper2.xpMilli == 680)
		assert(both.paperMilli == 726 and both.xpMilli == 1360)
		local invalid, invalidError = Rules.contributionMilli(1, 3, 1)
		rejected(invalid, invalidError, "invalid_multiplier")
	end)
	test("generated and explicitly supplied conversion rates drive arithmetic; unsupported precision rejects", function()
		local tuned = table.clone(EconomyConfig)
		tuned.paper_per_point, tuned.xp_per_point = 0.125, 1.25
		local amount = assert(Rules.contributionMilli(8, 1, 1, tuned))
		assert(amount.paperMilli == 1000 and amount.xpMilli == 10000)
		tuned.paper_per_point = 0.1255
		local invalid, err = Rules.contributionMilli(8, 1, 1, tuned)
		rejected(invalid, err, "invalid_economy_rate")
		local baseline = assert(Rules.contributionMilli(1, 1, 1))
		assert(baseline.paperMilli == 363 and baseline.xpMilli == 680)
		assert(getmetatable(EconomyConfig) == nil)
		local generated = assert(Rules.contributionMilli(1, 1, 1, EconomyConfig))
		assert(generated.paperMilli == baseline.paperMilli and generated.xpMilli == baseline.xpMilli)
	end)
	test("final contribution totals stay informational; final row bonuses are applied once per caller operation", function()
		local initial = profile()
		local afterContribution = assert(Rules.applyContribution(initial, 860, { paper = 1, xp = 1 }, "contrib"))
		local settled = assert(Rules.applyFinalBonuses(afterContribution.profile,
			{ contribution = 860, finalPaper = 120, finalXP = 170 }, { paper = 1, xp = 1 }, "settlement"))
		assert(settled.profile.paperMilli == 432180 and settled.profile.xpMilli == 754800)
		assert(initial.paperMilli == 0 and afterContribution.profile.paperMilli == 312180)
		assert(settled.operation.type == "FinalBonusesApplied" and settled.operation.operationID == "settlement")
		assert(settled.operation.contributionPoints == nil)
	end)
	test("XP exact boundaries, jumps, cap50 and continued cumulative XP", function()
		local lvl, rem = Rules.levelForXP(199999, EconomyConfig); assert(lvl == 1 and rem == 199999)
		lvl, rem = Rules.levelForXP(200000, EconomyConfig); assert(lvl == 2 and rem == 0)
		lvl, rem = Rules.levelForXP(439999, EconomyConfig); assert(lvl == 2 and rem == 239999)
		lvl, rem = Rules.levelForXP(440000, EconomyConfig); assert(lvl == 3 and rem == 0)
		local totalTo50 = 0
		for level = 1, 49 do totalTo50 += (200 + 40 * (level - 1)) * 1000 end
		lvl, rem = Rules.levelForXP(totalTo50, EconomyConfig); assert(lvl == 50 and rem == 0)
		lvl, rem = Rules.levelForXP(totalTo50 + 1234567, EconomyConfig); assert(lvl == 50 and rem == 1234567)
		lvl = Rules.levelForXP(totalTo50 * 100, EconomyConfig); assert(lvl == 50)
		local tuned = table.clone(EconomyConfig)
		tuned.xp_next_level_base, tuned.xp_next_level_step = 100, 25
		lvl, rem = Rules.levelForXP(225000, tuned); assert(lvl == 3 and rem == 0)
		tuned.xp_next_level_base = 0
		local bad, err = Rules.levelForXP(0, tuned); rejected(bad, err, "invalid_level_config")
		tuned.xp_next_level_base, tuned.level_cap = 100, 51
		bad, err = Rules.levelForXP(0, tuned); rejected(bad, err, "invalid_level_config")
		tuned.level_cap = 50
		tuned.xp_next_level_base, tuned.xp_next_level_step = Rules.MAX_SAFE_INTEGER, Rules.MAX_SAFE_INTEGER
		bad, err = Rules.levelForXP(Rules.MAX_SAFE_INTEGER, tuned); rejected(bad, err, "overflow")
	end)
	test("catalog starter ownership comes from actual starter loadout, including repeated pellet as one type", function()
		local own = assert(Rules.starterOwnership(catalog))
		for _, id in ipairs({ "body_standard", "nose_0", "wings_0", "tail_0", "pellet" }) do assert(own[id] == true, id) end
		assert(own.staple == nil and own.pencil == nil)
		local fresh = profile(0, 0, own)
		local starter = assert(Rules.validateEquipmentPurchase(fresh, catalog, "pellet", "starter-owned"))
		assert(starter.operation.alreadyOwned and starter.operation.chargedMilli == 0 and starter.profile.paperMilli == 0)
	end)
	test("rich level1 profile stays level gated; level40 low-paper profile stays price gated", function()
		local richLow = profile(100000000, 0, {})
		local result, err = Rules.validateEquipmentPurchase(richLow, catalog, "pencil", "blocked-level")
		rejected(result, err, "level_locked")
		local poorHigh = profile(4999999, 37440000, {})
		result, err = Rules.validateEquipmentPurchase(poorHigh, catalog, "pencil", "blocked-price")
		rejected(result, err, "insufficient_paper")
	end)
	test("owned item repeats return unchanged immutable profile and no charge", function()
		local own = { staple = true }
		local before = profile(900000, 1200000, own)
		local bought = assert(Rules.validateEquipmentPurchase(before, catalog, "staple", "retry-operation"))
		assert(bought.operation.alreadyOwned and bought.operation.priceMilli == 0)
		assert(bought.profile.paperMilli == before.paperMilli and bought.profile.xpMilli == before.xpMilli)
		assert(before.ownership.staple == true and before.paperMilli == 900000)
		assert(table.isfrozen(bought) and table.isfrozen(bought.profile) and table.isfrozen(bought.operation))
	end)
	test("repeated different catalog items use their own bounded catalog price", function()
		local p = profile(10000000, 5000000, {})
		local first = assert(Rules.validateEquipmentPurchase(p, catalog, "staple", "buy-staple"))
		local second = assert(Rules.validateEquipmentPurchase(first.profile, catalog, "rubber", "buy-rubber"))
		assert(first.operation.chargedMilli == 500000 and second.operation.chargedMilli == 900000)
		assert(second.profile.paperMilli == 8600000 and second.profile.ownership.staple and second.profile.ownership.rubber)
		assert(first.profile.ownership.rubber == nil and p.ownership.staple == nil)
	end)
	test("purchased Paper never becomes earned Paper, receives no multiplier and grants no XP or level", function()
		local before = profile(0, 0, {})
		local bought = assert(Rules.addPurchasedPaper(before, 500, "pack"))
		assert(bought.profile.paperMilli == 500000 and bought.profile.purchasedPaperMilli == 500000)
		assert(bought.profile.earnedPaperMilli == 0 and bought.profile.xpMilli == 0)
		local level = assert(Rules.levelForXP(bought.profile.xpMilli))
		assert(level == 1 and before.paperMilli == 0)
	end)
	test("humanity/controller source cannot alter pure reward arithmetic", function()
		local sameHuman = assert(Rules.contributionMilli(100, 2, 1))
		local sameBot = assert(Rules.contributionMilli(100, 2, 1))
		assert(sameHuman.paperMilli == sameBot.paperMilli and sameHuman.xpMilli == sameBot.xpMilli)
	end)
	test("reject NaN infinity negative unsafe integer invalid profiles and overflow", function()
		for _, value in ipairs({ 0 / 0, math.huge, -1, Rules.MAX_SAFE_INTEGER + 1 }) do
			local amount, err = Rules.contributionMilli(value, 1, 1); rejected(amount, err)
		end
		local result, err = Rules.applyContribution(profile(), 1, { paper = 1, xp = 0 }, "bad-multiplier")
		rejected(result, err, "invalid_multiplier")
		result, err = Rules.applyContribution(profile(Rules.MAX_SAFE_INTEGER - 100, 0, {}), 1, { paper = 1, xp = 1 }, "overflow")
		rejected(result, err, "overflow")
		result, err = Rules.applyFinalBonuses(profile(), { finalPaper = math.huge, finalXP = 0 }, { paper = 1, xp = 1 }, "bad-final")
		rejected(result, err, "invalid_result")
		result, err = Rules.contributionMilli(math.floor(Rules.MAX_SAFE_INTEGER / 680) + 1, 1, 1)
		rejected(result, err, "overflow")
		result, err = Rules.applyFinalBonuses(profile(),
			{ finalPaper = math.floor(Rules.MAX_SAFE_INTEGER / 1000) + 1, finalXP = 0 },
			{ paper = 1, xp = 1 }, "final-overflow")
		rejected(result, err, "overflow")
		result, err = Rules.addPurchasedPaper(profile(), 9007199254741, "buy-overflow")
		rejected(result, err, "overflow")
		local incomplete = { ownership = {} }
		local snapshot = table.clone(incomplete)
		result, err = Rules.applyContribution(incomplete, 1, { paper = 1, xp = 1 }, "missing-ledger")
		rejected(result, err, "invalid_profile")
		assert(incomplete.paperMilli == snapshot.paperMilli and incomplete.ownership == snapshot.ownership)
		local function deepChain(depth)
			local root, cursor = {}, nil
			cursor = root
			for _ = 1, depth do cursor.next = {}; cursor = cursor.next end
			root.paperMilli, root.earnedPaperMilli, root.purchasedPaperMilli, root.xpMilli, root.ownership = 0, 0, 0, 0, {}
			return root
		end
		result, err = Rules.addPurchasedPaper(deepChain(Rules.MAX_PROFILE_DEPTH + 1), 1, "deep-profile")
		rejected(result, err, "invalid_profile")
	end)
	return result
end

return Spec
