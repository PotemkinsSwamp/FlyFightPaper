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

local cover, status, fill, skip, skipNote, shownAt
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
	-- Said beside Skip, like other games do: you can play, the town is still painting in.
	skipNote = words(card, "SkipNote", "You can play now! Grey buildings fill in as you fly.", 100, 295, 600, 70, 34)
	skipNote.TextWrapped, skipNote.TextXAlignment, skipNote.Visible = true, Enum.TextXAlignment.Center, false
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
	-- Shown once its own art is in (first/LoadingFirst), so it never appears as a bare brown board; 10 s at most.
	local first = game.ReplicatedFirst.FlyFightPaper
	task.spawn(function()
		while not first:GetAttribute("ArtAt") and os.clock() - shownAt < 10 do task.wait(0.05) end
		mine.Visible = true
	end)
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
	while not game.ReplicatedFirst.FlyFightPaper:GetAttribute("ArtAt") and os.clock() - started < 10 do task.wait(0.05) end
	local artFailed = game.ReplicatedFirst.FlyFightPaper:GetAttribute("ArtFailed") or 0
	lap(artFailed > 0 and ("loading screen (" .. artFailed .. " failed)") or "loading screen")
	-- Everything the game shows, before you get in (Alan 2026-10-25: on a phone the game let him in long before the
	-- menus' paper and the town arrived): the menus' pictures first, then the town. PreloadAsync rejects mesh ids
	-- given as text and scripts can't read a SurfaceAppearance's maps, so the town goes in as the things themselves
	-- (MeshParts, SurfaceAppearances, decals) and PreloadAsync fetches what each one draws.
	-- In the order a player meets them (Alan 2026-10-25): the main menu (with its level bar and pin), then training
	-- (a new player's first stop), the hangar, settings and the in-game screens. Skip only once all of those and the
	-- town's parts are in; then the world's own pictures: the training range, then the town.
	local MENUS = { "mainmenu", "results", "tutorial", "trainingboard", "hangar", "settings", "ingame", "hud", "deskMenu", "hangarShelf" }
	local WORLD = { "range", "targets" }
	-- Pictures go in on picture labels: PreloadAsync doesn't fetch id text (see first/LoadingFirst).
	local function image(id) local label = Instance.new("ImageLabel"); label.Image = id; return label end
	local seen = {}
	local function walk(t, into)
		for _, v in t do
			if type(v) == "table" then walk(v, into)
			elseif type(v) == "string" and v:find("^rbxassetid://%d") and not seen[v] then seen[v] = true; table.insert(into, image(v)) end
		end
	end
	local menus, world = {}, {}
	for _, name in MENUS do walk(UIAssets[name], menus) end
	for _, name in WORLD do walk(UIAssets[name], world) end
	walk(UIAssets, menus) -- any screen not listed above still loads before Skip
	local town, shapes, room, assets = {}, {}, nil, nil
	local function collect(parent)
		for _, item in parent:GetDescendants() do
			if item:IsA("MeshPart") then
				local key = item.MeshId .. "|" .. item.TextureID -- one part per shape (toys repeat a lot)
				if not shapes[key] then shapes[key] = true; table.insert(town, item) end
			elseif item:IsA("SurfaceAppearance") or item:IsA("Decal") or item:IsA("Texture") then table.insert(town, item) end
		end
	end
	-- The bar is the true share of everything handed in that has finished (Alan 2026-10-25). Menus one file per
	-- request, 12 side by side; the town's thousands in groups: PreloadAsync fetches a list one file after another, and on a phone each round trip is slow
	-- (2026-10-25: 28 menu pictures in one call took over 15 s). A request can stall for good, so a step stops
	-- waiting once nothing has finished for 45 s (3 minutes in all); a step cut short shows as "cut" in the times.
	-- The bar: the menus fill its first 40%, the training range to 50%, the town the rest.
	local total, finished, failures, from, span = 1, 0, 0, 0, 0
	local function step(items, start, width) total, finished, from, span = math.max(#items, 1), 0, start, width end
	local stopAt, heard = os.clock() + 180, os.clock()
	local function preload(items, size, slots)
		local nextItem, running = 1, 0
		heard = os.clock()
		local function worker()
			running += 1
			while nextItem <= #items and os.clock() < stopAt do
				local batch, back = table.move(items, nextItem, math.min(nextItem + size - 1, #items), 1, {}), false
				nextItem += size
				-- 8 s per file at most (plus 1 s a file in a group): a few plane pieces kept in ReplicatedStorage never report back (2026-10-25),
				-- and each would hold one of the 12 slots for good. It keeps loading on its own.
				task.spawn(function()
					pcall(function()
						Content:PreloadAsync(batch, function(_, fetch)
							if fetch ~= Enum.AssetFetchStatus.Success then failures += 1 end
						end)
					end)
					back = true
				end)
				local asked = os.clock()
				while not back and os.clock() - asked < 8 + size do task.wait() end
				finished += #batch; heard = os.clock()
				progress(from + span * finished / total)
			end
			running -= 1
		end
		for _ = 1, slots do task.spawn(worker) end
		while (running > 0 or nextItem <= #items) and os.clock() < stopAt and os.clock() - heard < 45 do task.wait(0.1) end
		return (running > 0 or nextItem <= #items) and " cut" or ""
	end
	step(menus, 0, 0.4)
	lap("menus" .. preload(menus, 1, 12))
	-- Only now does the server send the town (streaming, docs/plan/LOAD-PLAN.md step 1), so it doesn't queue in front
	-- of the menus. Its parts arrive in a moment; with them in, Skip is safe: the game plays, and buildings still
	-- without their pictures fill in while you fly.
	Root:WaitForChild("RoundAction"):FireServer("sendTown")
	room, assets = Loading.waitTown()
	lap("town arrived")
	skip.Visible, skipNote.Visible = true, true
	collect(assets)
	-- The plane pieces first, one file at a time: a few never report back and must not hold up a group of 40.
	local planes = town
	town = {}
	collect(room)
	if workspace:FindFirstChild("CityRug") then collect(workspace.CityRug) end
	step(world, 0.4, 0.1)
	lap("range" .. preload(world, 1, 12))
	step(planes, 0.5, 0.05)
	lap("planes" .. preload(planes, 1, 12))
	-- The town in groups of 40, 12 at a time: fastest of the sizes tried (2026-10-25: 40x6 9 s, 20x24 35 s, 5x48 20 s).
	step(town, 0.55, 0.45)
	lap("preloaded" .. preload(town, 40, 12))
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
