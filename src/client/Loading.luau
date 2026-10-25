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

local cover, status, fill, skip, shownAt
local skipped, townReady = false, false
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
	-- Once the main menu's pictures are in, you can go in while the rest keeps loading (Alan 2026-10-25).
	skip = PaperUI.button(sheet, "Skip", menu.strip.green, "Skip", 780, 920, 360, 110, -1, function() skipped = true end, 48)
	skip.Visible = false
	-- While loading, the plane keeps flying across nose first (Alan 2026-10-17), turned 24 degrees to its climb. No pin:
	-- it only gets pinned on the menu board.
	local plane = image(sheet, "Plane", menu.plane, 0, 0, 226, 195, 24)
	plane.Position = UDim2.fromOffset(-250, 760)
	TweenService:Create(plane, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Position = UDim2.fromOffset(PaperUI.W + 250, 260),
	}):Play()
	-- What the other pilots are busy with while you load (Alan 2026-10-17), a new line every few seconds.
	local mine = cover
	task.spawn(function()
		local i = math.random(#LINES)
		while mine.Parent do
			status.Text = LINES[i]; i = i % #LINES + 1
			task.wait(2.5)
		end
	end)
	cover.Visible = true
end

local function run()

	-- The words rotate on their own (see LINES); this only moves the crayon bar.
	local function progress(fraction)
		fill.Size = UDim2.fromOffset(610 * math.clamp(fraction, 0.02, 1), 80)
	end
	-- Seconds spent in each step, kept on workspace (LoadTimes) so slow joins can be traced.
	local started, times = game.ReplicatedFirst.FlyFightPaper:GetAttribute("FirstAt") or shownAt or os.clock(), {}
	local function lap(step) table.insert(times, string.format("%s %.1f", step, os.clock() - started)); workspace:SetAttribute("LoadTimes", table.concat(times, ", ")) end
	lap("game in")
	-- Everything the game shows, before you get in (Alan 2026-10-25: on a phone the game let him in long before the
	-- menus' paper and the town arrived): the menus' pictures first, then the town. PreloadAsync rejects mesh ids
	-- given as text and scripts can't read a SurfaceAppearance's maps, so the town goes in as the things themselves
	-- (MeshParts, SurfaceAppearances, decals) and PreloadAsync fetches what each one draws.
	-- The main menu's own pictures first (the board, its strips, the level bar, the pin), then every other screen's.
	local menuArt, ui, seen = {}, {}, {}
	local function walk(t, into)
		for _, v in t do
			if type(v) == "table" then walk(v, into)
			elseif type(v) == "string" and v:find("^rbxassetid://%d") and not seen[v] then seen[v] = true; table.insert(into, v) end
		end
	end
	walk(UIAssets.mainmenu, menuArt)
	walk(UIAssets.results, menuArt)
	table.insert(menuArt, UIAssets.hud.pinRed); seen[UIAssets.hud.pinRed] = true
	walk(UIAssets, ui)
	local town, shapes, room, assets = {}, {}, nil, nil
	local function collect(parent)
		for _, item in parent:GetDescendants() do
			if item:IsA("MeshPart") then
				local key = item.MeshId .. "|" .. item.TextureID -- one part per shape (toys repeat a lot)
				if not shapes[key] then shapes[key] = true; table.insert(town, item) end
			elseif item:IsA("SurfaceAppearance") or item:IsA("Decal") or item:IsA("Texture") then table.insert(town, item) end
		end
	end
	-- The bar is the true share of everything handed in that has finished (Alan 2026-10-25). Batches go in a few
	-- at a time; each counts when PreloadAsync returns. It can stall for good, so stop waiting once nothing has
	-- finished for 15 s (3 minutes at most: a phone's first join is slow).
	local total, finished, failures = #menuArt + #ui, 0, 0
	local stopAt, heard = os.clock() + 180, os.clock()
	local function preload(items)
		local queue, running = {}, 0
		for i = 1, #items, 40 do table.insert(queue, table.move(items, i, math.min(i + 39, #items), 1, {})) end
		local function worker()
			running += 1
			while #queue > 0 and os.clock() < stopAt do
				local batch = table.remove(queue, 1)
				pcall(function()
					Content:PreloadAsync(batch, function(_, fetch)
						if fetch ~= Enum.AssetFetchStatus.Success then failures += 1 end
					end)
				end)
				finished += #batch; heard = os.clock()
				progress(finished / math.max(total, 1))
			end
			running -= 1
		end
		for _ = 1, 6 do task.spawn(worker) end
		while (running > 0 or #queue > 0) and os.clock() < stopAt and os.clock() - heard < 15 do task.wait(0.1) end
	end
	preload(menuArt)
	lap("main menu")
	-- Menus first (docs/plan/LOAD-PLAN.md step 1): only now does the server send the town (streaming), so its files
	-- don't queue in front of the menus'.
	Root:WaitForChild("RoundAction"):FireServer("sendTown")
	skip.Visible = true
	preload(ui)
	lap("menu pictures")
	room, assets = Loading.waitTown()
	lap("town arrived")
	collect(room)
	collect(assets)
	if workspace:FindFirstChild("CityRug") then collect(workspace.CityRug) end
	total += #town
	preload(town)
	lap("preloaded")
	workspace:SetAttribute("AssetLoadFailures", failures)
	-- ponytail: no "pictures didn't load" note (Alan 2026-10-17: it showed every join; the count stays in AssetLoadFailures).
	lap("done")
	print("FlyFightPaper load times (seconds): " .. workspace:GetAttribute("LoadTimes")) -- readable on a phone: type /console in chat
	-- The load recorder (server LoadLog): this join's times, read later in Studio.
	local view = workspace.CurrentCamera.ViewportSize
	Root.RoundAction:FireServer("loadTimes", { times = workspace:GetAttribute("LoadTimes"), skipped = workspace:GetAttribute("LoadSkippedAt"),
		failures = failures, device = string.format("%s%s %dx%d", require(script.Parent.ScreenFit).kind(),
			game:GetService("UserInputService").TouchEnabled and " touch" or "", view.X, view.Y) })
end

function Loading.run()
	if not cover then Loading.show() end
	-- Whatever goes wrong while loading, the player still gets in (2026-10-25: an error here kept a published
	-- build on the loading screen for good). Skip lets them in early; the loading carries on behind the menu.
	local finished = false
	task.spawn(function()
		local ok, problem = pcall(run)
		if not ok then warn("Loading stopped early: " .. tostring(problem)) end
		finished = true
	end)
	while not finished and not skipped do task.wait(0.1) end
	if skipped and not finished then workspace:SetAttribute("LoadSkippedAt", os.clock() - (game.ReplicatedFirst.FlyFightPaper:GetAttribute("FirstAt") or shownAt)) end
	cover.Parent:Destroy()
end

-- The town's parts (not yet their pictures) are all on this phone: the room, the rug and the plane pieces.
function Loading.waitTown()
	local room
	repeat room = workspace:FindFirstChild("Arena") or workspace:FindFirstChild("GreyboxRoom"); if not room then task.wait(0.1) end until room
	local assets = Root:WaitForChild("Assets")
	local function ready(model) return model and NativeAssets.ready(model) end
	while not (ready(room) and ready(assets) and (ready(workspace:FindFirstChild("CityRug")) or room.Name == "GreyboxRoom")) do task.wait(0.1) end
	return room, assets
end

-- Bootstrap calls this once everything that needs the town has started.
function Loading.ready() townReady = true end

-- Play, Fly and Training wait for the town if it isn't here yet (a fast Skip on a slow phone): the loading screen
-- comes back until it is, then the action goes ahead.
function Loading.town(action)
	if not townReady then
		Loading.show()
		while not townReady do task.wait(0.1) end
		cover.Parent:Destroy()
	end
	action()
end

return Loading
