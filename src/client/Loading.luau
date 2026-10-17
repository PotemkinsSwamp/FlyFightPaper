-- Loading screen on the classroom bulletin board (same art as the main menu): crayon title, a card saying what is
-- loading, a crayon progress bar and the paper plane flying across. Its own pictures load first.
local Players = game:GetService("Players")
local Content = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local NativeAssets = require(Root:WaitForChild("Shared"):WaitForChild("NativeAssets"))
local UIAssets = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local Loading = {}

local cover, status, fill, shownAt
local LINES = {
	"The other pilots are setting up the classroom...", "Colouring in the pages...", "Folding paper planes...",
	"Sharpening the pencils...", "Drawing the roads on the rug...", "Taping the town together...",
	"Winding up the toy train...", "Hanging the paper chains...", "Filling the paint jars...",
	"Stacking the books into towers...", "Practising loop-the-loops...", "Picking the best paper...",
}

-- Called first thing on join so the player never sees the bare room while the game connects.
function Loading.show()
	shownAt = os.clock()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local menu, results = UIAssets.mainmenu, UIAssets.results
	local sheet
	cover, sheet = PaperUI.screen(playerGui, "LoadingClassroom", menu.bg)
	cover.Parent.DisplayOrder = 100
	local image, words = PaperUI.image, PaperUI.words
	image(sheet, "Title", menu.title, 450, 140, 1010, 340, -1)
	local card = image(sheet, "Card", results.xpCard, 560, 520, 800, 380, 1)
	status = words(card, "Status", "Loading the classroom", 70, 50, 660, 120, 66)
	status.TextXAlignment, status.TextWrapped = Enum.TextXAlignment.Center, true
	fill = image(card, "Fill", results.xpFill, 95, 205, 1, 80)
	fill.AnchorPoint, fill.Position, fill.ScaleType = Vector2.new(0, 0.5), UDim2.fromOffset(95, 245), Enum.ScaleType.Stretch
	image(card, "Frame", results.xpFrame, 80, 190, 640, 110).ScaleType = Enum.ScaleType.Stretch
	-- The plane flies nose first (Alan 2026-10-17): turned 24 degrees so the picture's nose points along its gentle
	-- climb (checked in a Studio preview), and cropped so its dashed trail no longer sits in front of the nose.
	local plane = image(sheet, "Plane", menu.plane, 0, 0, 215, 200, 24)
	plane.ImageRectOffset, plane.ImageRectSize = Vector2.zero, Vector2.new(630, 589)
	plane.Position = UDim2.fromOffset(-250, 760)
	TweenService:Create(plane, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Position = UDim2.fromOffset(PaperUI.W + 250, 260),
	}):Play()
	-- What the other pilots are busy with while you load (Alan 2026-10-17), a new line every few seconds.
	task.spawn(function()
		local i = math.random(#LINES)
		while cover and cover.Parent do
			status.Text = LINES[i]; i = i % #LINES + 1
			task.wait(2.5)
		end
	end)
	cover.Visible = true
end

function Loading.run()
	if not cover then Loading.show() end

	-- The words rotate on their own (see LINES); this only moves the crayon bar.
	local function progress(fraction)
		fill.Size = UDim2.fromOffset(610 * math.clamp(fraction, 0.02, 1), 80)
	end
	-- Seconds spent in each step, kept on workspace (LoadTimes) so slow joins can be traced.
	local started, times = shownAt or os.clock(), {}
	local function lap(step) table.insert(times, string.format("%s %.1f", step, os.clock() - started)); workspace:SetAttribute("LoadTimes", table.concat(times, ", ")) end
	lap("server ready")
	local room
	repeat room = workspace:FindFirstChild("Arena") or workspace:FindFirstChild("GreyboxRoom"); if not room then task.wait() end until room
	local assets = Root:WaitForChild("Assets")
	lap("room")
	while not NativeAssets.ready(room) or not NativeAssets.ready(assets) do task.wait(0.1) end
	lap("replicated")
	local list, seen = {}, {}
	local function collect(parent)
		for _, item in parent:GetDescendants() do
			-- Pictures only: PreloadAsync rejects mesh ids (all ~440 failed every join); Roblox streams meshes itself.
			if item:IsA("MeshPart") then
				if item.TextureID ~= "" and not seen[item.TextureID] then seen[item.TextureID] = true; table.insert(list, item.TextureID) end
			elseif item:IsA("Decal") or item:IsA("Texture") then
				if item.Texture ~= "" and not seen[item.Texture] then seen[item.Texture] = true; table.insert(list, item.Texture) end
			end
		end
	end
	collect(room)
	collect(assets)
	local failed, completed, loaded = {}, 0, 0
	-- PreloadAsync can stall for good, and in Studio it reports nearly every asset as failed even though the art
	-- shows. So stop waiting once nothing has answered for 4 s (30 s at most), and only retry when most assets
	-- loaded (if most failed, the check itself is broken and retrying just makes the player wait).
	local stopAt = os.clock() + 30
	local function preload(ids)
		for _, id in ids do failed[id] = true end
		local done, heard = false, os.clock()
		task.spawn(function()
			pcall(function()
				Content:PreloadAsync(ids, function(id, fetch)
					completed += 1
					heard = os.clock()
					progress(math.min(completed, #list) / math.max(#list, 1))
					if fetch == Enum.AssetFetchStatus.Success then failed[id] = nil; loaded += 1 end
				end)
			end)
			done = true
		end)
		while not done and os.clock() < stopAt and os.clock() - heard < 4 do task.wait(0.1) end
	end
	preload(list)
	lap("preloaded")
	for attempt = 1, 2 do
		local retry = {}
		for id in failed do table.insert(retry, id) end
		-- A handful of misses isn't worth seconds of waiting (one failed picture cost ~5 s): retry only past 5%.
		if #retry <= #list * 0.05 or loaded < #retry or os.clock() + attempt >= stopAt then break end
		progress(1)
		task.wait(attempt)
		preload(retry)
	end
	local failures = 0
	for _ in failed do failures += 1 end
	workspace:SetAttribute("AssetLoadFailures", failures)
	-- ponytail: no "pictures didn't load" note (Alan 2026-10-17: it showed every join; the count stays in AssetLoadFailures).
	lap("done")
	cover.Parent:Destroy()
	Root.RoundAction:FireServer("mapReady")
end

return Loading
