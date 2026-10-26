-- Runs before the rest of the game arrives (ReplicatedFirst), so the loading screen's own pictures and its crayon font
-- are the first files a phone asks for (Alan 2026-10-25: queued behind the town's thousands of files,
-- the loading screen showed only plain words). Loading.luau draws the screen once the game is in; its art is ready.
local Content = game:GetService("ContentProvider")
script.Parent:SetAttribute("FirstAt", os.clock()) -- the load times count from here (Loading.luau)
script.Parent:SetAttribute("QueueAtStart", Content.RequestQueueSize) -- files already waiting ahead of ours
local Art = require(script.Parent:WaitForChild("UIAssets"))
-- Menu sheets (tools/ui_sheets.py): most small menu pieces share a few big files. Any label showing a packed piece is
-- pointed at its sheet and the piece's spot on it, however the screen code set it; the code keeps using piece ids.
-- ponytail: one watcher on PlayerGui (all menus live there); a helper per call site if this ever misses one.
local Sheets = require(script.Parent:WaitForChild("UISheets"))
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local function fit(label)
	local id = label.Image
	if label:GetAttribute("Sheet") == id then return end -- (our own change, or a copy of a label already pointed)
	local piece = Sheets[id]
	if piece then
		label:SetAttribute("Sheet", piece[1])
		label.Image, label.ImageRectOffset, label.ImageRectSize = piece[1], Vector2.new(piece[2], piece[3]), Vector2.new(piece[4], piece[5])
	elseif label:GetAttribute("Sheet") then -- now a picture of its own: the whole file again
		label:SetAttribute("Sheet", nil)
		label.ImageRectOffset, label.ImageRectSize = Vector2.zero, Vector2.zero
	end
end
local function watch(item)
	if item:IsA("ImageLabel") or item:IsA("ImageButton") then
		fit(item)
		item:GetPropertyChangedSignal("Image"):Connect(function() fit(item) end)
	end
end
for _, item in playerGui:GetDescendants() do watch(item) end
playerGui.DescendantAdded:Connect(watch)
local menu, results = Art.mainmenu, Art.results
-- PreloadAsync doesn't fetch a picture given as id text (2026-10-25: it fails at once in Studio and stalls on a client),
-- so each id goes in on a picture label.
-- They stay drawn (almost see-through, in a corner) until the menu is up: the engine throws away preloaded pictures
-- that nothing draws (Roblox staff, 2026-02: "if you preload ImageLabels but don't make them visible, the engine will
-- think these textures are unused and collect them"). Loading.luau adds the main menu's and removes it all at the end.
local keep = Instance.new("ScreenGui")
keep.Name, keep.ResetOnSpawn, keep.DisplayOrder = "KeepDrawn", false, -10
keep.Parent = playerGui
local function image(id)
	local label = Instance.new("ImageLabel")
	label.Image, label.Size, label.BackgroundTransparency, label.ImageTransparency = id, UDim2.fromOffset(8, 8), 1, 0.99
	fit(label) -- now, not when the watcher hears of it: the preload below fetches whatever the label shows
	label.Parent = keep
	return label
end
local first = { image(menu.title), image(results.xpCard), image(results.xpFill), image(results.xpFrame), image(menu.plane) }
for _, tile in menu.bg do table.insert(first, image(tile)) end
local font = Instance.new("TextLabel") -- (the font loads through a label that uses it)
font.FontFace, font.Text = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold), "Loading"
table.insert(first, font)
-- Each file in its own request, all at once: PreloadAsync fetches a list one file after another (slow on a phone).
local failed, left, slowest, slowestAt = 0, #first, "", 0
local start = os.clock()
for _, item in first do
	task.spawn(function()
		pcall(Content.PreloadAsync, Content, { item }, function(id, fetch) if id ~= "" and fetch ~= Enum.AssetFetchStatus.Success then failed += 1 end end) -- ("": the font label)
		left -= 1
		if os.clock() - start > slowestAt then -- for the load recorder: which file the screen waited for
			slowestAt, slowest = os.clock() - start, item:IsA("ImageLabel") and item.Image:match("%d+$") or "font"
		end
	end)
end
local since = os.clock()
while left > 0 and os.clock() - since < 30 do task.wait() end
script.Parent:SetAttribute("ArtFailed", failed) -- for the load recorder
script.Parent:SetAttribute("ArtSlowest", string.format("%s %.1f", slowest, slowestAt))
-- The loading screen shows once its own art is in (Loading.show), never as a bare brown board. Nothing else is fetched
-- here: every other screen's pictures queued at once held this art back 50 s on a phone (2026-10-25).
script.Parent:SetAttribute("ArtAt", os.clock())
