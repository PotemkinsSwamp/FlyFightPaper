local Shared = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared
local Lines = require(Shared.Lines)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
-- Alan 2026-10-17: no sound words, waits described not counted, every line short enough to read in flight.
local SOUNDS = { "bonk", "splat", "whoosh", "wheee", "zoom", "scritch", "crunch", "boom", "pow", "crash!", "whack", "ouch" }
local function check(name, line)
	local plain = line:gsub("{%a+}", "")
	assert(#plain <= 60, name .. " too long: " .. line)
	assert(not line:find("%d"), name .. " counts: " .. line)
	for _, word in SOUNDS do assert(not line:lower():find("%f[%a]" .. word:gsub("%p", "%%%0") .. "%f[%A]"), name .. " sound word: " .. line) end
end
function Spec.run()
	local output, test = Suite.new()
	test("every line is short, counts nothing, uses no sound words, and each set has two or more", function()
		for _, group in { Lines.sets, Lines.weapons, Lines.ways } do
			for name, set in group do
				assert(#set >= 2, name)
				for _, line in set do check(name, line) end
			end
		end
	end)
	test("pick never repeats a line twice in a row and stays in its set", function()
		local previous
		for _ = 1, 50 do
			local line = Lines.pick("takeoff")
			assert(line ~= previous and Lines.is("takeoff", line))
			previous = line
		end
	end)
	test("crash lines name what was hit", function()
		local name = Lines.thing("milk-carton-tower/3-ground-floor-back-left")
		assert(name == "Milk Carton Tower", tostring(name))
		assert(Lines.thing("Floor") == "classroom floor" and Lines.thing("WindowWallLower") == "window")
		assert(Lines.thing("DeskNorth3Base") == "desk" and Lines.thing("tree-bushy12") == "tree")
		for _ = 1, 20 do
			local line = Lines.death({ kind = "crash", part = "milk-carton-tower/1" }, "you")
			assert(line:find("^You ") and line:find("Milk Carton Tower") and not line:find("{"), line)
		end
	end)
	test("every way down fills in names, and a line about you starts with You or Your", function()
		local hows = { { kind = "weapon", weapon = "eraser" }, { kind = "weapon" }, { kind = "crash", part = "Floor", outOfLift = true },
			{ kind = "fan" }, { kind = "ram", other = "Leo" }, { kind = "bounds" }, { kind = "unfolded" }, { kind = "fresh" },
			{ kind = "left" }, { kind = "crash", part = "nothing-known" } }
		for _, how in hows do
			for _, named in { true, false } do
				local killer = named and "Mia" or nil
				for _ = 1, 10 do
					local line = Lines.death(how, "you", killer)
					assert(not line:find("{") and not line:find("you's"), line)
					local feed = Lines.death(how, "Bob", killer)
					assert(not feed:find("{") and feed ~= "", feed)
				end
			end
		end
		for _ = 1, 20 do
			local line = Lines.death({ kind = "weapon", weapon = "staple" }, "Bob", "you")
			assert(line:find("%f[%a][Yy]our?%f[%A]"), line)
		end
	end)
	test("stable gives the same line for the same seed", function()
		assert(Lines.stable("nextRound", 41.7, "Team dogfight") == Lines.stable("nextRound", 41.2, "Team dogfight"))
		assert(Lines.stable("nextRound", 41, "Team dogfight"):find("Team dogfight"))
	end)
	return output
end
return Spec
