local Shared = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared
local Lines = require(Shared.Lines)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
function Spec.run()
	local output, test = Suite.new()
	test("every line is short, counts no seconds, and each set has at least two", function()
		for name, set in Lines.sets do
			assert(#set >= 2, name)
			for _, line in set do assert(#line <= 60 and not line:find("%d"), name .. ": " .. line) end
		end
	end)
	test("pick never repeats a line twice in a row and stays in its set", function()
		local previous
		for _ = 1, 50 do
			local line = Lines.pick("crashed")
			assert(line ~= previous and Lines.is("crashed", line))
			previous = line
		end
	end)
	test("kill feed keeps the victim at the end (fold) or start (crash) for the blue pin", function()
		for _, line in Lines.sets.fold do assert(string.format(line, "Bob", "you"):find(" you$"), line) end
		for _, line in Lines.sets.crash do assert(string.format(line, "You"):find("^You "), line) end
	end)
	test("stable gives the same line for the same seed", function()
		assert(Lines.stable("nextRound", 41.7, "Team dogfight") == Lines.stable("nextRound", 41.2, "Team dogfight"))
		assert(Lines.stable("nextRound", 41, "Team dogfight"):find("Team dogfight"))
	end)
	return output
end
return Spec
