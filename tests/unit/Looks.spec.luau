local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Looks = require(Root.Shared.LooksRules)
local Schema = require(Root.Shared.ProfileSchema)
local Economy = require(Root.Shared.EconomyRules)
local Commerce = require(Root.Shared.CommerceRules)
local EconomyConfig = require(Root.Generated.Economy)
local CommerceConfig = require(Root.Generated.Commerce)
local JSON = require(Root.Generated.JSONTypes)
local Catalog = require(Root.Shared.Catalog)
local Profile = require(game.ServerScriptService.FlyFightPaper.ProfileService)
local Fake = require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local function configCopy(value)
	if value == JSON.Null or type(value) ~= "table" then return value end
	local out = {}; for key, child in pairs(value) do out[key] = configCopy(child) end; return out
end
local function rejected(result, err, code)
	assert(result == nil and type(err) == "table" and err.type == "LooksRejected", "expected typed rejection")
	assert(err.code == code, tostring(err.code) .. " != " .. code)
end
local function xpAtCap()
	local xp = 0
	for level = 1, EconomyConfig.level_cap - 1 do
		xp += (EconomyConfig.xp_next_level_base + math.floor(EconomyConfig.xp_next_level_step * (level - 1) ^ EconomyConfig.xp_next_level_power)) * Economy.MILLI
	end
	return xp
end
function Spec.run()
	local result, test = Suite.new()
	local catalog = Catalog.new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
	local function fresh(paper)
		local p = Schema.defaults(catalog); p.paperMilli = paper or 0; return p
	end
	local function fixture()
		local data = fresh(1234567); data.extensions = { keep = string.rep("x", 600) }
		local profile = Fake.new(data)
		local service = Profile.new({ catalog = catalog, monotonic = function() return 100 end, unix = function() return 20000 * 86400 end })
		assert(service:attach("user", profile, { connected = true, mapLoaded = true }).status == "ok")
		return service, profile
	end
	test("looks config and item identities are cached frozen and match the approved prices", function()
		local cfg = Looks.config()
		assert(cfg == Looks.config() and table.isfrozen(cfg) and table.isfrozen(cfg.skins[1]) and table.isfrozen(cfg.tiers.common))
		assert(#cfg.skins == 9 and #cfg.trails == 5)
		for tier, prices in pairs({ common = {2800,149}, rare = {5600,299}, legendary = {30000,599}, mythical = {60000,999}, trail = {900,49} }) do
			assert(cfg.tiers[tier].paper == prices[1] and cfg.tiers[tier].robux == prices[2])
		end
		for _, entry in ipairs(cfg.skins) do
			local item = assert(Looks.item(entry.id))
			assert(item.id == entry.id and item.name == entry.name and item.kind == "skin" and item.tier == entry.tier and item.sold)
			assert(item.paper == cfg.tiers[item.tier].paper and item.robux == cfg.tiers[item.tier].robux and item.trail == entry.trail)
			assert(table.isfrozen(item))
		end
		for _, entry in ipairs(cfg.trails) do
			local item = assert(Looks.item(entry.id))
			assert(item.kind == "trail" and item.sold == entry.sold and item.paper == 900 and item.robux == 49)
		end
		assert(Looks.item("missing") == nil and Looks.item(nil) == nil and not Looks.owns(nil, "dragon"))
		assert(not pcall(function() cfg.tiers.common.paper = 1 end))
	end)
	test("Paper buys charge exact milliunits with no level requirement and detach every returned table", function()
		for _, example in ipairs({ {"hazard_stripes",2800}, {"gold_foil",5600}, {"shark_jet",30000}, {"dragon",60000}, {"confetti",900} }) do
			local p = fresh(example[2] * 1000 + 123); p.earnedPaperMilli = 99; p.purchasedPaperMilli = 77
			local before = Schema.canonical(p)
			local bought = assert(Looks.buyWithPaper(Schema.freeze(p), example[1], "paper-buy"))
			assert(bought.profile.paperMilli == 123 and bought.profile.looks.owned[example[1]] == true)
			assert(bought.operation.chargedMilli == example[2] * 1000 and bought.operation.priceMilli == example[2] * 1000 and not bought.operation.alreadyOwned)
			assert(bought.operation.operationID == "paper-buy" and bought.operation.lookID == example[1])
			assert(bought.profile.earnedPaperMilli == 99 and bought.profile.purchasedPaperMilli == 77 and bought.profile.xpMilli == p.xpMilli)
			assert(Looks.owns(bought.profile, example[1]) and Schema.canonical(p) == before and Schema.validate(bought.profile, catalog))
			assert(bought.profile ~= p and bought.profile.looks ~= p.looks and bought.profile.presets ~= p.presets)
			assert(table.isfrozen(bought) and table.isfrozen(bought.operation) and table.isfrozen(bought.profile.looks.owned))
			assert(not pcall(function() bought.profile.looks.owned[example[1]] = nil end))
		end
	end)
	test("Legendary and Mythical buys own their matching trails without automatically wearing them", function()
		for skin, trail in pairs({ shark_jet = "water_spray", dragon = "dragon_embers" }) do
			local bought = assert(Looks.buyWithPaper(fresh(60000000), skin, "bundle"))
			assert(Looks.owns(bought.profile, skin) and Looks.owns(bought.profile, trail))
			assert(bought.profile.looks.skin == "" and bought.profile.looks.trail == "")
		end
	end)
	test("matching trails are never sold or granted alone and unknown looks are rejected", function()
		for _, method in ipairs({ Looks.buyWithPaper, Looks.grant }) do
			for _, id in ipairs({ "water_spray", "dragon_embers" }) do
				local p = fresh(60000000); local before = Schema.canonical(p)
				local value, err = method(p, id, "not-sold"); rejected(value, err, "not_sold")
				assert(Schema.canonical(p) == before)
			end
			local value, err = method(fresh(), "missing", "unknown"); rejected(value, err, "unknown_look")
		end
	end)
	test("an owned look costs nothing even when the balance is empty", function()
		local p = assert(Looks.grant(fresh(), "dragon", "grant-first")).profile
		local bought = assert(Looks.buyWithPaper(p, "dragon", "owned-buy"))
		assert(bought.operation.alreadyOwned and bought.operation.chargedMilli == 0 and bought.operation.priceMilli == 0)
		assert(Schema.canonical(bought.profile) == Schema.canonical(p))
	end)
	test("one milliunit below the price fails without changing the input", function()
		local p = fresh(2800000 - 1); local before = Schema.canonical(p)
		local value, err = Looks.buyWithPaper(p, "hazard_stripes", "poor"); rejected(value, err, "insufficient_paper")
		assert(Schema.canonical(p) == before and not Looks.owns(p, "hazard_stripes"))
	end)
	test("receipt grants do not charge money and repeat grants report already owned", function()
		local p = fresh(123)
		local granted = assert(Looks.grant(p, "shark_jet", "grant"))
		assert(granted.profile.paperMilli == 123 and granted.operation.chargedMilli == 0 and not granted.operation.alreadyOwned)
		assert(Looks.owns(granted.profile, "water_spray") and not Looks.owns(p, "shark_jet"))
		local again = assert(Looks.grant(granted.profile, "shark_jet", "grant-again"))
		assert(again.operation.alreadyOwned and Schema.canonical(again.profile) == Schema.canonical(granted.profile))
		assert(Looks.owns(assert(Looks.grant(p, "confetti", "plain-trail")).profile, "confetti"))
	end)
	test("all mutations require bounded operation ids and reject malformed profiles", function()
		for _, id in ipairs({ "", string.rep("x", 161), false, 7 }) do
			local value, err = Looks.buyWithPaper(fresh(), "dragon", id); rejected(value, err, "invalid_operation_id")
			value, err = Looks.grant(fresh(), "dragon", id); rejected(value, err, "invalid_operation_id")
			value, err = Looks.wear(fresh(), "", "", id); rejected(value, err, "invalid_operation_id")
		end
		for _, damage in ipairs({ function(p) p.paperMilli = -1 end, function(p) p.paperMilli = 0.5 end,
			function(p) p.paperMilli = math.huge end, function(p) p.looks = nil end,
			function(p) p.looks.owned.dragon = false end, function(p) p.loop = p end,
			function(p) p.extra = function() end end, function(p) setmetatable(p.looks, {}) end }) do
			for _, method in ipairs({ Looks.buyWithPaper, Looks.grant }) do
				local p = fresh(60000000); damage(p)
				local value, err = method(p, "dragon", "bad-profile"); rejected(value, err, "invalid_profile")
			end
		end
	end)
	test("wear requires owned items of the correct kind and saves both selections atomically", function()
		local p = assert(Looks.grant(fresh(), "shark_jet", "wear-grant")).profile
		local value, err = Looks.wear(p, "dragon", "water_spray", "not-owned"); rejected(value, err, "not_owned")
		value, err = Looks.wear(p, "shark_jet", "confetti", "trail-not-owned"); rejected(value, err, "not_owned")
		value, err = Looks.wear(p, "water_spray", "", "wrong-skin"); rejected(value, err, "wrong_kind")
		value, err = Looks.wear(p, "", "shark_jet", "wrong-trail"); rejected(value, err, "wrong_kind")
		local worn = assert(Looks.wear(p, "shark_jet", "water_spray", "wear"))
		assert(worn.profile.looks.skin == "shark_jet" and worn.profile.looks.trail == "water_spray" and Schema.validate(worn.profile, catalog))
		assert(p.looks.skin == "" and p.looks.trail == "" and table.isfrozen(worn.profile.looks))
		local removed = assert(Looks.wear(worn.profile, "", "", "remove"))
		assert(removed.profile.looks.skin == "" and removed.profile.looks.trail == "" and Looks.owns(removed.profile, "shark_jet"))
		assert(assert(Looks.wear(worn.profile, "", "water_spray", "trail-only")).profile.looks.skin == "")
	end)
	test("fresh profiles have empty valid looks and schema validation rejects invalid ownership or selections", function()
		local p = fresh()
		assert(Schema.VERSION == 13 and p.schemaVersion == 13 and next(p.looks.owned) == nil and p.looks.skin == "" and p.looks.trail == "")
		assert(Schema.validate(p, catalog))
		for _, damage in ipairs({ function(q) q.looks = nil end, function(q) q.looks.extra = true end,
			function(q) q.looks.owned.missing = true end, function(q) q.looks.owned.dragon = false end,
			function(q) q.looks.skin = "dragon" end, function(q) q.looks.trail = "confetti" end,
			function(q) q.looks.owned.confetti = true; q.looks.skin = "confetti" end,
			function(q) q.looks.owned.dragon = true; q.looks.trail = "dragon" end }) do
			local q = fresh(); damage(q); assert(not Schema.validate(q, catalog))
		end
	end)
	test("old saves gain empty looks without changing the original save or unrelated progress", function()
		local p = fresh(12345); p.schemaVersion = 12; p.looks = nil; p.extensions = { keep = true }
		local before = Schema.canonical(p); local expected = assert(Schema.copy(p))
		expected.schemaVersion = Schema.VERSION; expected.looks = { owned = {}, skin = "", trail = "" }
		local migrated = assert(Schema.migrate(Schema.freeze(p), catalog))
		assert(Schema.canonical(migrated) == Schema.canonical(expected) and Schema.validate(migrated, catalog))
		assert(Schema.canonical(p) == before)
	end)
	test("migration drops retired look ids and worn retired choices while retaining known ownership", function()
		for _, version in ipairs({ 12, Schema.VERSION }) do
			local p = fresh(); p.schemaVersion = version
			p.looks = { owned = { retired_skin = true, retired_trail = true, hazard_stripes = true, confetti = true }, skin = "retired_skin", trail = "retired_trail" }
			local migrated = assert(Schema.migrate(p, catalog))
			assert(next(migrated.looks.owned) and migrated.looks.owned.retired_skin == nil and migrated.looks.owned.retired_trail == nil)
			assert(Looks.owns(migrated, "hazard_stripes") and Looks.owns(migrated, "confetti") and migrated.looks.skin == "" and migrated.looks.trail == "")
			assert(Schema.validate(migrated, catalog) and p.looks.owned.retired_skin == true)
		end
	end)
	test("economic copies merge looks and prestige retains owned and worn cosmetics", function()
		local p = assert(Schema.copy(assert(Looks.grant(fresh(), "dragon", "prestige-grant")).profile))
		p = assert(Schema.copy(assert(Looks.wear(p, "dragon", "dragon_embers", "prestige-wear")).profile))
		p.xpMilli = xpAtCap()
		local saved = Schema.canonical(p.looks)
		local view = Schema.economicView(p)
		assert(view.looks ~= p.looks and table.isfrozen(view.looks.owned))
		local prestiged = assert(Economy.prestige(p, catalog, "prestige"))
		assert(prestiged.profile.prestige == 1 and Schema.canonical(prestiged.profile.looks) == saved)
		Schema.mergeEconomic(p, view); assert(Schema.canonical(p.looks) == saved and p.looks ~= view.looks)
		assert(Schema.validate(prestiged.profile, catalog))
	end)
	test("bot looks use every skill tier with matching trails or a sold plain trail", function()
		for skill, tier in pairs({ rookie = "common", regular = "rare", experienced = "legendary", ace = "mythical", unknown = "common" }) do
			for _, last in ipairs({ false, true }) do
				local skin, trail = Looks.botLooks(skill, function(n) return last and n or 1 end)
				assert(Looks.item(skin).tier == tier)
				if skin == "shark_jet" then assert(trail == "water_spray")
				elseif skin == "dragon" then assert(trail == "dragon_embers")
				else assert(Looks.item(trail).kind == "trail" and Looks.item(trail).sold) end
			end
		end
	end)
	test("all twelve look products are disabled priced and produce frozen lookUnlock grants", function()
		local commerce = assert(Commerce.catalog(CommerceConfig)); local count = 0
		local prices = { hazard_stripes=149,tiger_stripes=149,flame_decals=149,gold_foil=299,lava=299,galaxy=299,
			shark_jet=599,dragon=999,origami_crane=999,confetti=49,rainbow_marker=49,gold_stars=49 }
		for _, product in ipairs(CommerceConfig.products) do
			if product.benefit == "look_unlock" then
				count += 1
				assert(prices[product.look_id] and product.key == "look_" .. product.look_id and product.kind == "developer_product")
				assert(product.enabled == false and product.roblox_product_id == JSON.Null and product.approved_robux_price == prices[product.look_id])
				local offer = assert(commerce.byKey[product.key]); local op = Commerce.operation(offer)
				local fields = 0; for _ in pairs(op) do fields += 1 end
				assert(offer.lookID == product.look_id and offer.approvedPrice == prices[product.look_id] and not offer.productID)
				assert(op.kind == "lookUnlock" and op.lookID == product.look_id and fields == 2 and table.isfrozen(op))
			end
		end
		for id in pairs(prices) do assert(commerce.byKey["look_" .. id]) end
		assert(count == 12 and not commerce.byKey.look_water_spray and not commerce.byKey.look_dragon_embers)
		local owned = assert(Looks.grant(fresh(), "shark_jet", "preview-grant")).profile
		local dto = Commerce.preview(commerce, owned.boosts, owned)
		for _, offer in ipairs(dto.offers) do
			if offer.benefit == "look_unlock" then
				assert(not offer.available and offer.owned == (offer.lookID == "shark_jet") and not offer.ownedPermanent)
				if offer.owned then assert(offer.reason == "owned") end
			end
		end
	end)
	test("look offer validation rejects malformed identities fields prices and unmapped enabled sales", function()
		for _, change in ipairs({ function(p) p.look_id = "missing" end, function(p) p.look_id = "water_spray"; p.key = "look_water_spray" end,
			function(p) p.key = "look_wrong" end, function(p) p.kind = "pass" end, function(p) p.look_id = nil end,
			function(p) p.amount = 1 end, function(p) p.catalog_id = "dragon" end, function(p) p.extra = true end,
			function(p) p.approved_robux_price = -1 end, function(p) p.approved_robux_price = 1.5 end,
			function(p) p.enabled = true end }) do
			local raw = configCopy(CommerceConfig)
			for _, product in ipairs(raw.products) do if product.key == "look_dragon" then change(product); break end end
			assert(Commerce.catalog(raw) == nil)
		end
	end)
	test("server receipts grant matching trails once preserve unrelated data and prestige keeps them", function()
		local service, profile = fixture(); local paper = profile.Data.paperMilli
		local op = assert(service:prepare("user", { kind = "receipt", receiptId = "looks/shark", grant = { kind = "lookUnlock", lookID = "shark_jet" } }))
		local granted = service:apply("user", op)
		assert(granted.status == "ok" and granted.value.type == "LookGranted" and not granted.value.alreadyOwned, granted.code)
		assert(Looks.owns(profile.Data, "shark_jet") and Looks.owns(profile.Data, "water_spray") and profile.Data.paperMilli == paper)
		assert(profile.Data.extensions.keep == string.rep("x", 600) and profile.Data.receiptIds[Profile.receiptKey("looks/shark")])
		local after = Schema.canonical(profile.Data)
		assert(service:apply("user", op).status == "ok" and Schema.canonical(profile.Data) == after)
		local duplicate = service:apply("user", assert(service:prepare("user", { kind="receipt",receiptId="looks/shark",grant={kind="lookUnlock",lookID="shark_jet"} })))
		assert(duplicate.status == "ok" and duplicate.value.type == "ReceiptAlreadyGranted" and profile.Data.paperMilli == paper)
		local already = service:apply("user", assert(service:prepare("user", { kind="receipt",receiptId="looks/shark-again",grant={kind="lookUnlock",lookID="shark_jet"} })))
		assert(already.status == "ok" and already.value.alreadyOwned)
		profile.Data.looks = assert(Schema.copy(assert(Looks.wear(Schema.economicView(profile.Data), "shark_jet", "water_spray", "server-wear")).profile.looks))
		profile.Data.xpMilli = xpAtCap(); local worn = Schema.canonical(profile.Data.looks)
		local prestige = service:apply("user", assert(service:prepare("user", { kind="prestige" })))
		assert(prestige.status == "ok" and Schema.canonical(profile.Data.looks) == worn and profile.Data.extensions.keep == string.rep("x", 600), prestige.code)
		assert(profile:Save() and Schema.validate(profile.LastSavedData, catalog))
	end)
	test("invalid cosmetic receipt grants leave ownership balances and receipt records unchanged", function()
		for _, example in ipairs({ { {kind="lookUnlock",lookID="missing"}, "unknown_look" },
			{ {kind="lookUnlock",lookID="water_spray"}, "not_sold" }, { {kind="lookUnlock"}, "invalid_receipt_grant" },
			{ {kind="lookUnlock",lookID="dragon",wholePaper=1}, "invalid_receipt_grant" } }) do
			local service, profile = fixture(); local before = Schema.canonical(profile.Data)
			local applied = service:apply("user", assert(service:prepare("user", {kind="receipt",receiptId="bad-look",grant=example[1]})))
			assert(applied.status == "error" and applied.code == example[2], applied.code)
			assert(Schema.canonical(profile.Data) == before)
		end
		local service, profile = fixture(); local before = Schema.canonical(profile.Data)
		local applied = service:apply("user", assert(service:prepare("user", {kind="lookUnlock",lookID="dragon"})))
		assert(applied.status == "error" and applied.code == "invalid_operation" and Schema.canonical(profile.Data) == before)
	end)
	return result
end
return Spec
