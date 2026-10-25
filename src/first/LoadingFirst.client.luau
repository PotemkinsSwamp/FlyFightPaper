-- Runs before the rest of the game arrives (ReplicatedFirst), so the loading screen's own pictures and its crayon font
-- are the first files a phone asks for (Alan 2026-10-25: queued behind the town's thousands of files,
-- the loading screen showed only plain words). Loading.luau draws the screen once the game is in; its art is ready.
local Content = game:GetService("ContentProvider")
script.Parent:SetAttribute("FirstAt", os.clock()) -- the load times count from here (Loading.luau)
local Art = require(script.Parent:WaitForChild("UIAssets"))
local menu, results = Art.mainmenu, Art.results
-- PreloadAsync doesn't fetch a picture given as id text (2026-10-25: it fails at once in Studio and stalls on a client),
-- so each id goes in on a picture label.
local function image(id) local label = Instance.new("ImageLabel"); label.Image = id; return label end
local first = { image(menu.title), image(results.xpCard), image(results.xpFill), image(results.xpFrame), image(menu.plane) }
for _, tile in menu.bg do table.insert(first, image(tile)) end
local font = Instance.new("TextLabel") -- (the font loads through a label that uses it)
font.FontFace, font.Text = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold), "Loading"
table.insert(first, font)
-- Each file in its own request, all at once: PreloadAsync fetches a list one file after another (slow on a phone).
local failed, left = 0, #first
for _, item in first do
	task.spawn(function()
		pcall(Content.PreloadAsync, Content, { item }, function(id, fetch) if id ~= "" and fetch ~= Enum.AssetFetchStatus.Success then failed += 1 end end) -- ("": the font label)
		left -= 1
	end)
end
local since = os.clock()
while left > 0 and os.clock() - since < 20 do task.wait() end
script.Parent:SetAttribute("ArtFailed", failed) -- for the load recorder
-- The loading screen shows once its own art is in (Loading.show), never as a bare brown board. Nothing else is fetched
-- here: every other screen's pictures queued at once held this art back 50 s on a phone (2026-10-25).
script.Parent:SetAttribute("ArtAt", os.clock())
