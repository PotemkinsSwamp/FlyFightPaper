local Root = game.ReplicatedStorage.FlyFightPaper
local Emotes = require(Root.Shared.EmoteRules)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}

function Spec.run()
	local result, test = Suite.new()
	test("the catalog lists both cutscene casts in order", function()
		local leaders = { "ToyPilot", "CameraFlick", "BookKicker", "Bubblegum", "Magician", "APlus", "SkeetShoot", "FoldItUp" }
		local runnersUp = { "GoodGame", "Nap", "NextOne", "SoClose", "SneakyToss", "SoreLoser", "TestFlight", "Doodler" }
		local all = Emotes.list()
		assert(#all == #leaders + #runnersUp and all == Emotes.config().emotes)
		for kind, ids in { leader = leaders, runner_up = runnersUp } do
			local entries = Emotes.list(kind)
			local offset = kind == "leader" and 0 or #leaders
			assert(#entries == #ids)
			for i, id in ipairs(ids) do
				local entry = entries[i]
				assert(entry.id == id and entry.kind == kind and entry == Emotes.get(id) and entry == all[i + offset])
			end
		end
		assert(Emotes.get("missing") == nil and #Emotes.list("missing") == 0)
	end)
	test("paid prices come from the listed tier", function()
		local tiers = { good = { 2800, 135 }, cool = { 5600, 269 }, best = { 30000, 599 } }
		for tier, expected in tiers do
			local price = Emotes.config().tiers[tier]
			assert(price.paper == expected[1] and price.robux == expected[2])
		end
		for _, emote in Emotes.list() do
			local price = Emotes.price(emote.id)
			if emote.tier == "free" then assert(price == nil)
			else assert(price and price == Emotes.config().tiers[emote.tier]) end
		end
	end)
	test("free emotes belong to everyone, can be worn and cannot be bought", function()
		local saved = { owned = {} }
		assert(Emotes.free("leader") == "ToyPilot" and Emotes.free("runner_up") == "GoodGame")
		for kind, slot in { leader = "leader", runner_up = "runnerUp" } do
			local id = Emotes.free(kind)
			assert(Emotes.owns(saved, id) and Emotes.worn(saved, kind) == id)
			local bought, why = Emotes.buy(saved, id, 0)
			assert(not bought and why == "free")
			local worn, reason, field = Emotes.wear(saved, id)
			assert(worn and reason == nil and field == slot)
		end
		assert(next(saved.owned) == nil)
	end)
	test("buy and wear return the price or slot without changing saved picks or ownership", function()
		local saved = { owned = { Nap = true, Doodler = true }, leader = "ToyPilot", runnerUp = "Doodler" }
		local price = assert(Emotes.price("APlus")).paper
		local ok, reason, charge = Emotes.buy(saved, "APlus", price)
		assert(ok and reason == nil and charge == price and saved.owned.APlus == nil)
		for id, refusal in { APlus = "paper", Nap = "owned", missing = "unknown" } do
			ok, reason = Emotes.buy(saved, id, price - 1)
			assert(not ok and reason == refusal)
		end
		local worn, why, slot = Emotes.wear(saved, "Nap")
		assert(worn and why == nil and slot == "runnerUp")
		for id, refusal in { APlus = "not_owned", missing = "unknown" } do
			worn, why = Emotes.wear(saved, id)
			assert(not worn and why == refusal and not Emotes.owns(saved, id))
		end
		assert(saved.leader == "ToyPilot" and saved.runnerUp == "Doodler")
	end)
	test("worn choices fall back for unowned, missing or wrong-kind ids", function()
		local saved = { owned = { Nap = true, APlus = true }, leader = "APlus", runnerUp = "Nap" }
		assert(Emotes.worn(saved, "leader") == "APlus" and Emotes.worn(saved, "runner_up") == "Nap")
		saved.leader, saved.runnerUp = "Nap", "missing"
		assert(Emotes.worn(saved, "leader") == "ToyPilot" and Emotes.worn(saved, "runner_up") == "GoodGame")
		saved.leader = "CameraFlick"
		assert(Emotes.worn(saved, "leader") == "ToyPilot" and Emotes.worn(nil, "runner_up") == "GoodGame")
	end)
	return result
end

return Spec
