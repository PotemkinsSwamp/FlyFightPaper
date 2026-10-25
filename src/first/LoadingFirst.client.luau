-- Runs before the rest of the game arrives (ReplicatedFirst), so the loading screen's own pictures and its crayon font
-- are the first files a phone asks for, then the menus' (Alan 2026-10-25: queued behind the town's thousands of files,
-- the loading screen showed only plain words). Loading.luau draws the screen once the game is in; its art is ready.
local Content = game:GetService("ContentProvider")
local Art = require(script.Parent:WaitForChild("UIAssets"))
local menu, results = Art.mainmenu, Art.results
local first = { menu.title, results.xpCard, results.xpFill, results.xpFrame, menu.plane }
for _, tile in menu.bg do table.insert(first, tile) end
local font = Instance.new("TextLabel") -- (the font loads through a label that uses it)
font.FontFace, font.Text = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold), "Loading"
table.insert(first, font)
pcall(Content.PreloadAsync, Content, first)
local rest, seen = {}, {}
local function walk(t)
	for _, v in t do
		if type(v) == "table" then walk(v)
		elseif type(v) == "string" and v:find("^rbxassetid://%d") and not seen[v] then seen[v] = true; table.insert(rest, v) end
	end
end
walk(Art)
pcall(Content.PreloadAsync, Content, rest)
