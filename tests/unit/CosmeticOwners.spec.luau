local Owners = require(game.ServerScriptService.FlyFightPaper.CosmeticOwners)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}

function Spec.run()
	local result, test = Suite.new()
	test("older observations, duplicate prizes and partial retries count distinct owners", function()
		local rows, fail = {}, true
		local store = {}
		function store:UpdateAsync(key, apply)
			if fail and key == "2:0" then fail = false; error("interrupted") end
			rows[key] = apply(rows[key]) or rows[key]
		end
		local index = Owners.new("", true, store)
		local first = {ninja = true, smoke_bomb = true}
		assert(not pcall(index.record, index, 17, first))
		assert(index:record(17, first).ninja == 1)
		assert(index:record(17, {ninja = true}).smoke_bomb == 1)
		assert(index:record(18, {smoke_bomb = true}).smoke_bomb == 2)
		local total = index:record(2 ^ 36 + 17, {ninja = true})
		assert(total.ninja == 2 and total.smoke_bomb == 2)
	end)
	test("the historical collection scan preserves its cursor and finishes once", function()
		local index = Owners.new("", true)
		local read = 0
		local profiles = {}
		function profiles:ListKeysAsync(prefix, size, cursor)
			assert(prefix == "Player_" and size > 0)
			read += 1
			assert(cursor == (read == 1 and "" or "page-two"))
			return {IsFinished = read == 2, Cursor = "page-two",
				GetCurrentPage = function() return {{KeyName = "Player_" .. read}} end}
		end
		function profiles:GetAsync() return {Data = {looks = {owned = {dragon = true}}}} end
		assert(not index:backfillPage(profiles, "server-a"))
		assert(not index:backfillPage(profiles, "server-b") and read == 1)
		assert(index:backfillPage(profiles, "server-a"))
		assert(index:backfillPage(profiles, "server-b") and read == 2)
		assert(index:record(1, {dragon = true}).dragon == 2)
	end)
	return result
end
return Spec
