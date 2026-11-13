-- Hangar: a cubby shelf of your builds, and a Customize binder that edits one (Alan picked both 2026-10-20: concepts
-- assets/references/ui-concepts/hangar-shelf-screen.png and hangar-customize-b.png; plan docs/plan/HANGAR-PLAN.md).
-- The shelf screen shows the picked build big with its name and stats; tapping a cubby picks the build you fly (in the
-- Range it swaps your plane, and the shelf holds only the Range's builds). Customize opens the binder
-- (HangarCustomize). Saving makes a build the one you fly next, and at your desk "Save & fly" also refolds it.
local Root = game.ReplicatedStorage.FlyFightPaper
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local Builder = require(Root.Shared.BuilderModel)
local Assets = require(Root.Shared.UIAssets)
local Art, Shelf = Assets.hangar, Assets.hangarShelf
local PaperUI = require(script.Parent.PaperUI)
local BuildShelf = require(script.Parent.BuildShelf)
local Customize = require(script.Parent.HangarCustomize)
local Hangar = {}

-- Studio dev mode: every part counts as owned at the level cap, and "Fly this build" sends the draft straight
-- to your plane for testing. Nothing here is saved or bought; live servers ignore it.
local RunService = game:GetService("RunService")
-- Not with the level test account (Alan's dev switch, docs/workshop/testing.md): it shows what that player sees.
local function devMode() return RunService:IsStudio() and game.Players.LocalPlayer:GetAttribute("DevAll") ~= false end
local everything = {}
for _, list in { Catalog.weapons, Catalog.utilities } do for _, part in list do everything[part.id] = true end end
for _, list in Catalog.structuresBySlot do for _, part in list do everything[part.id] = true end end

-- Bar ranges cover every body/nose/wing/tail swap on the starter build (measured 2026-10-08).
local STATS = {
	{ "Health", "red", "red", function(s) return s.health end, 60, 340, "%.0f" },
	{ "Speed", "blue", "blue", function(s) return s.speed end, 60, 150, "%.0f" },
	-- Turning is two stats (Alan): Climb = nose up/down (tail), Swerve = side to side (wings). Kid words, not pitch/yaw.
	{ "Climb", "green", "green", function(s) return s.pitch end, 70, 200, "%.0f" },
	{ "Swerve", "green", "green", function(s) return s.yaw end, 70, 175, "%.0f", Color3.fromRGB(150, 230, 255) },
	{ "Lift", "yellow", "orange", function(s) return s.lift end, 70, 110, "%.0fs" },
}
Hangar.STATS = STATS -- the in-game hangar menu shows the same rows
local NAME_MAX = 20 -- letters in a build's name (HangarService checks it too)
-- Mount tags on the Gear page, by mount size (picked to show on red or blue paper and the sky-blue photo).
local MOUNT_COLOURS = { light = Color3.fromRGB(70, 185, 80), medium = Color3.fromRGB(250, 200, 30), heavy = Color3.fromRGB(150, 80, 215) }
-- The Range's builds are a separate set (Alan 2026-10-21: "look slightly different so it's recognizable"): a pink tab,
-- pink photo paper, a pinned note on the shelf screen, a pink binder titled "Range Customize".
local RANGE_PINK, SKY_BLUE = Color3.fromRGB(240, 110, 130), Color3.fromRGB(140, 185, 230)
Hangar.RANGE_PINK = RANGE_PINK
local PHOTO = { 330, 12, 780, 560 } -- the shelf screen's big taped photo (x, y, w, h in sheet pixels)
-- Label and box colours on the stat sheet (white pieces, tinted).
local STAT_COLOURS = {
	Health = Color3.fromRGB(230, 90, 90), Speed = Color3.fromRGB(80, 140, 230), Climb = Color3.fromRGB(90, 180, 90),
	Swerve = Color3.fromRGB(90, 190, 200), Lift = Color3.fromRGB(245, 150, 60), Weight = Color3.fromRGB(175, 130, 220),
}
Hangar.STAT_COLOURS = STAT_COLOURS -- the desk's quick menu tints its rows the same

-- api = { action = RoundAction remote, back(), flown() (after Save & fly), fly(loadout) (Studio only) }
function Hangar.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "HangarScreen", Shelf.bg)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Size, content.Parent = "Content", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet
	content.ZIndex = 2 -- in front of the shelf, so Customize stands on its top board (Alan 2026-10-21)

	local player = game.Players.LocalPlayer
	local state = { preset = player:GetAttribute("SelectedPreset") or 1, page = "shelf", slot = "body", mount = 1, angle = 0.5, pitch = -0.5, names = {} }
	-- Your plane waiting at its desk: only then can Save & fly refold it.
	local function atDesk()
		local plane = workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(tostring(player.UserId))
		return player:GetAttribute("InMatch") == true and plane ~= nil and plane:GetAttribute("State") == "DESK"
	end
	-- In the Range the hangar edits the Range's own five builds: every part, never flown in matches (TUTORIAL-PLAN).
	local function inRange()
		local plane = workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(tostring(player.UserId))
		return plane ~= nil and plane:GetAttribute("Pinned") ~= nil
	end
	local profile, render

	-- Back: from Customize to the shelf (unsaved changes ask once first), from the shelf out of the Hangar.
	local back = button(sheet, "Back", Assets.range.stripRed, "Back", 22, 47, 300, 66, -3, function() -- the strip's own shape, clear of the photo
		if state.page == "shelf" then api.back(); return end
		if state.unsaved and not state.dropAsk then state.dropAsk = true; render(); return end
		state.page, state.trying, state.dropAsk = "shelf", nil, nil
		state.builder:reset(state.builds[state.preset].loadout, state.preset)
		render()
	end, 54)
	back.ZIndex = 5
	-- Phones: under Roblox's own buttons (top left) a finger opened Roblox's menu instead; Back drops below them.
	PaperUI.phone(back, { Position = UDim2.fromOffset(140, 245), Size = UDim2.fromOffset(300, 130) }) -- (130: a 44-point tap on a small phone)

	-- Tapping a cubby picks that build: the one you fly next (in the Range it swaps your plane).
	local shelf = BuildShelf.new(sheet, Catalog, function(i)
		if i == state.preset and not player:GetAttribute("SelectedClass") then return end
		state.preset, state.trying, state.dropAsk = i, nil, nil
		state.builder:reset(state.builds[i].loadout, i)
		if state.range then api.action:FireServer("range", "load" .. i) else api.action:FireServer("selectPreset", i) end
		render()
	end)

	-- The Presets shelf: ready-made planes you can fly but not change. Six cubbies, so narrower ones.
	local classShelf = BuildShelf.new(sheet, Catalog, function(i)
		local class = state.builds[i]
		if class.locked or class.id == player:GetAttribute("SelectedClass") then return end
		state.preset = i
		state.builder:reset(class.loadout, i)
		api.action:FireServer("selectClass", class.id)
		render()
	end, 300)
	player:GetAttributeChangedSignal("SelectedClass"):Connect(function() if render and state.page == "shelf" then render() end end)
	local function switchShelf(classes)
		state.classes, state.builder, state.trying, state.dropAsk = classes, nil, nil, nil
		state.preset = 1
		local picked = player:GetAttribute("SelectedClass")
		if classes then
			for i, class in Catalog:classes() do if class.id == picked then state.preset = i end end
		elseif not picked then
			state.preset = player:GetAttribute("SelectedPreset") or 1
		end
		render()
	end
	-- Presets are the fixed planes, loadouts your own (in this code `class` is a preset and `preset` a saved loadout: the
	-- save keeps its names).

	local function choose(pick, ...)
		state.builder.message = ""
		local ok, reason = pick(state.builder, ...)
		if not ok then
			reason = tostring(reason)
			if reason=="two weapon types per plane" then reason = "Two gear types per plane: one for left click, one for right click."
			elseif reason:find("capacity exceeds") then reason = "Too much weight for this body. Take some gear off or pick a bigger body."
			elseif reason:find("incompatible with ordered mount") then reason = "That gear is too big for that mount." end
			state.builder.message = reason
		end
		render()
	end
	-- Gear goes where it fits, moving others around if needed (BuilderModel.placeWeapon, Alan's note 20).
	local function placeWeapon(id)
		local ok, result = state.builder:placeWeapon(id, state.mount)
		if ok then state.mount = result end
		return ok, result
	end

	-- The stat sheet (concept hangar-shelf-screen.png): taped notebook paper, a coloured paper label per stat, five
	-- crayon boxes and the real number written after them, then the weight row (how much gear this body carries, "4/6").
	-- It lays itself out to fit its box (the shelf screen's is wide, the binder's tall). compare: the stats to measure
	-- against (the saved build while you try parts, or your build while looking at a part to buy); each number then
	-- shows its change in green or red (Alan 2026-10-21: the boxes alone lost the exact numbers).
	local GAIN, LOSS = "#1e7a32", "#b4231e"
	-- Where each stat name's letters fall inside a Kalam Bold line, in text sizes (left, right, top, bottom; measured in
	-- Studio 2026-11-08). Speed and Weight reach lower for their p and g.
	local LABEL_INK = {
		Health = { 0.032, 1.832, 0.160, 0.660 }, Speed = { 0, 1.651, 0.149, 0.819 }, Climb = { 0.021, 1.576, 0.160, 0.660 },
		Swerve = { 0, 1.907, 0.192, 0.660 }, Lift = { 0.032, 1.076, 0.160, 0.660 }, Weight = { 0.043, 1.917, 0.160, 0.830 },
	}
	-- The two stats papers at their own shapes and where they can be written on (fractions of the picture: right of the red
	-- margin, left of the torn right edge, under the tape, above the torn bottom edge).
	local PAPERS = {
		-- The original paper (Customize): each row written between two of its ruled lines (`lines`: where they cross the
		-- paper's middle, the first under the tape), the label, boxes and number at the sizes they always had (Alan
		-- 2026-11-10: "it fits inside the paper, like it's written on the lines"). label, box: widths, as shares of the paper.
		tall = { id = Shelf.statsPaper, shape = 720 / 800, area = { 0.15, 0.156, 0.955, 0.94 },
			lines = { 190 / 800, 266 / 800, 346 / 800, 431 / 800, 513 / 800, 597 / 800, 680 / 800 }, label = 0.3, box = 0.0583 },
		-- The same paper widened on both sides of its tape (tools/art/widen_paper.py; Hangar page): rows fill it evenly.
		wide = { id = Shelf.statsWide, shape = 926 / 800, area = { 0.12, 0.155, 0.94, 0.925 } },
	}
	local LABEL_SHAPE = 313 / 90 -- the stat label strip's own shape
	-- The stats paper at (x, y), `w` across, at its own shape (Alan 2026-11-09: papers never stretch, and the rows sit
	-- inside the paper with the same room above them, under the tape, as below them). `note`: a line written under the
	-- rows (the Presets page). Returns its height.
	local function statSheet(stats, compare, x, y, w, kind, note)
		local paper = PAPERS[kind or "tall"]
		local h = w / paper.shape
		image(content, "StatsSheet", paper.id, x, y, w, h)
		local ax, ay = x + w * paper.area[1], y + h * paper.area[2]
		local aw, ah = w * (paper.area[3] - paper.area[1]), h * (paper.area[4] - paper.area[2])
		local rowTop, rowHeight, labelH, boxSize, gap, cap, wordScale
		if paper.lines then
			rowTop = function(i) return y + h * paper.lines[i] end
			rowHeight = function(i) return h * (paper.lines[i + 1] - paper.lines[i]) end
			labelH, boxSize, gap, wordScale = w * paper.label / LABEL_SHAPE, w * paper.box, w * 0.026, 1.15
			cap = function(i) return math.floor(rowHeight(i) * 0.9) end
		else
			local rows = #STATS + 1 + (note and 0.8 or 0)
			local rowH = ah / (rows + 0.7) -- 0.35 of a row free above and below
			ay += rowH * 0.35
			if note then
				local line = words(content, "ClassNote", note, ax, ay + rowH * (#STATS + 1), aw, rowH * 0.8, math.floor(rowH * 0.42))
				line.TextXAlignment = Enum.TextXAlignment.Center
				PaperUI.fitWords(line, aw) -- one line
			end
			-- Label, five boxes and the number share the row's width: on a narrow paper they all shrink together.
			labelH, boxSize, gap, wordScale = rowH * 0.82, rowH * 0.62, rowH * 0.2, 1
			local fit = math.min(1, (aw - rowH * 1.1 - gap * 2) / (labelH * LABEL_SHAPE + 5 * boxSize * 1.14))
			labelH, boxSize = labelH * fit, boxSize * fit
			rowTop = function(i) return ay + (i - 1) * rowH end
			rowHeight = function() return rowH end
			cap = function() return math.floor(rowH * 0.62 * math.max(fit, 0.8)) end
		end
		local labelW = labelH * LABEL_SHAPE
		-- The number after the boxes, with its change when there is one (the font shrinks to fit the column).
		local function number(i, name, from, text, change)
			local top, rowH = rowTop(i), rowHeight(i)
			local value = words(content, name .. "Value", text, from, top + rowH * 0.1, ax + aw - from, rowH * 0.8, 40)
			value.RichText, value.TextScaled = true, true
			local most = Instance.new("UITextSizeConstraint")
			most.MaxTextSize, most.Parent = cap(i), value
			if change and math.abs(change) >= 0.5 then
				value.Text = string.format('%s <font color="%s">%+.0f</font>', text, change > 0 and GAIN or LOSS, change)
			end
		end
		local function row(i, name, tint, filled, cells)
			local top, rowH = rowTop(i), rowHeight(i)
			local strip = image(content, name .. "Row", Shelf.statLabel, ax, top + (rowH - labelH) / 2, labelW, labelH)
			strip.ImageColor3 = tint
			-- The name sits in the middle of the label's visible paper (the art's opaque part: 2-98% across, 7-88% down),
			-- its letters with even room above and below and to the sides (Alan 2026-11-08: they filled the box). One size
			-- for every row: the tallest word (Weight, with its g) keeps 18% of the paper's height above and below.
			local boxX, boxW = ax + labelW * 0.022, labelW * 0.962
			local boxY, boxH = top + (rowH - labelH) / 2 + labelH * 0.067, labelH * 0.811
			local size = math.min(boxH * 0.64 / 0.67 * wordScale, boxW * 0.8 / 1.91)
			local ink = LABEL_INK[name] or LABEL_INK.Health
			local label = words(content, name .. "Name", name, boxX + boxW / 2 - (ink[1] + ink[2]) / 2 * size,
				boxY + boxH / 2 - (ink[3] + ink[4]) / 2 * size, 2.2 * size, size, size)
			label.TextYAlignment = Enum.TextYAlignment.Top
			-- More than five boxes (Weight on a big body) share the five boxes' width.
			local cell = math.min(boxSize, boxSize * 5 / math.max(cells, 5))
			local from = ax + labelW + gap
			for k = 1, cells do
				local box = image(content, name .. "Box" .. k, k <= filled and Shelf.statBox or Shelf.statBoxEmpty, from + (k - 1) * cell * 1.14, top + (rowH - cell) / 2, cell, cell)
				box.ImageColor3 = tint
			end
			return label, from + 5 * boxSize * 1.14 + gap * 0.6
		end
		for i, entry in STATS do
			local name, _, _, get, lo, hi, format = table.unpack(entry)
			local value = stats and get(stats) or lo
			local _, after = row(i, name, STAT_COLOURS[name], math.clamp(math.ceil((value - lo) / (hi - lo) * 5), 1, 5), 5)
			if stats then number(i, name, after, string.format(format, value), compare and value - get(compare)) end
		end
		if stats then
			local i = #STATS + 1
			local label, after = row(i, "Weight", STAT_COLOURS.Weight, stats.used_capacity, math.max(stats.capacity, 1))
			if stats.used_capacity >= stats.capacity then label.TextColor3 = Color3.fromRGB(170, 30, 30) end
			number(i, "Weight", after, string.format("%d/%d", stats.used_capacity, stats.capacity)) -- its boxes already show the change
		end
		return h
	end

	-- The build's name on masking tape with a pencil (concept hangar-name-tape-a.png), on both screens: click the name
	-- or the pencil to type a new one (up to NAME_MAX letters, Roblox-filtered on the server). size = letter size.
	local function nameTag(parent, x, y, w, h, size)
		local build = state.builds[state.preset]
		image(parent, "NameTape", Assets.ingame.tapeLabel, x, y, w, h) -- (the tape keeps its own shape)
		local nameBox = Instance.new("TextBox")
		nameBox.Name, nameBox.Text, nameBox.PlaceholderText, nameBox.ClearTextOnFocus = "BuildName", build.name, "Name this build", false
		nameBox.Position, nameBox.Size, nameBox.BackgroundTransparency = UDim2.fromOffset(x + 30, y), UDim2.fromOffset(w - 130, h), 1
		nameBox.FontFace, nameBox.TextSize, nameBox.TextColor3 = PaperUI.font, size, PaperUI.INK
		nameBox.TextTruncate, nameBox.Parent = Enum.TextTruncate.AtEnd, parent
		PaperUI.loud(PaperUI.crayon(nameBox)) -- the build's name reads like a title (Alan 2026-11-08)
		local pencil = Instance.new("ImageButton")
		pencil.Name, pencil.Image, pencil.BackgroundTransparency, pencil.Rotation = "Rename", Assets.settings.pencil, 1, -35
		-- (On a phone a bigger pencil: 26 tall was a 9-point tap.)
		pencil.AnchorPoint, pencil.Position, pencil.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(x + w - 55, y + h / 2), UDim2.fromOffset(PaperUI.isPhone() and 130 or 96, PaperUI.isPhone() and 130 or 26)
		pencil.ScaleType, pencil.Parent = Enum.ScaleType.Fit, parent
		pencil.Activated:Connect(function() nameBox:CaptureFocus() end)
		-- Clicking in selects the whole name, so typing replaces it (Ctrl+A isn't something a kid knows).
		nameBox.Focused:Connect(function() nameBox.SelectionStart, nameBox.CursorPosition = 1, #nameBox.Text + 1 end)
		nameBox:GetPropertyChangedSignal("Text"):Connect(function()
			if utf8.len(nameBox.Text) and utf8.len(nameBox.Text) > NAME_MAX then nameBox.Text = nameBox.Text:sub(1, utf8.offset(nameBox.Text, NAME_MAX + 1) - 1) end
		end)
		nameBox.FocusLost:Connect(function()
			local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" or name == build.name then nameBox.Text = build.name; return end
			api.action:FireServer("renamePreset", { range = state.range, slot = state.preset, name = name })
			-- The save takes a couple of seconds: show the new name meanwhile instead of the old one (Alan 2026-10-21).
			state.names[(state.range and "range" or "my") .. state.preset] = { name = name, at = os.clock() }
			render()
		end)
	end

	-- The plane in 3D. box = (x, y, w, h). On the shelf screen it sits on taped sky-blue paper; bare (the binder's
	-- left page, which is blue already) it fills the box with no paper (Alan 2026-10-21: a stretched photo looked bad).
	-- diagram (Gear page): a still view from above and behind (nose up) with a numbered tag on every mount.
	-- under: room kept free at the photo's bottom (its name tape sits there, on the photo).
	local function preview(draft, box, diagram, bare, under, parent)
		local content = parent or content
		local px, py, pw, ph = table.unpack(box)
		local vx, vy, vw, vh = px, py, pw, ph
		if not bare then
			local paper = image(content, "PreviewPaper", Art.preview, px, py, pw, ph, 0)
			paper.ScaleType, paper.ImageColor3 = Enum.ScaleType.Stretch, state.range and Color3.fromRGB(235, 165, 195) or SKY_BLUE
			vx, vy, vw, vh = px + pw * 0.07, py + ph * 0.13, pw * 0.86, ph * 0.74 - (under or 0)
		end
		local view = Instance.new("ViewportFrame")
		view.Name, view.BackgroundTransparency = "PlanePreview", 1
		view.Position, view.Size = UDim2.fromOffset(vx, vy), UDim2.fromOffset(vw, vh)
		-- Softer fill and a warm key light so the folds show shading instead of flat colour.
		view.Ambient, view.LightColor, view.LightDirection = Color3.fromRGB(140, 140, 150), Color3.fromRGB(255, 250, 235), Vector3.new(-0.6, -1, -0.4)
		view.Parent = content
		local world = Instance.new("WorldModel")
		world.Parent = view
		local model = Instance.new("Model")
		model.Parent = world
		Aircraft.build(model, draft, Catalog, true)
		local camera = Instance.new("Camera")
		camera.Parent, view.CurrentCamera, camera.FieldOfView = view, camera, 45
		-- Every build fills the same frame (Alan): the camera backs off until the plane's longer side (wingspan or
		-- nose to tail) nearly fills the frame's height; the wider frame takes the corners when it turns.
		local center, size = model:GetBoundingBox()
		-- (A frame taller than wide is limited by its width instead.)
		local distance = math.max(size.X, size.Z) / 2 * 1.05 / math.sin(math.rad(camera.FieldOfView / 2)) / math.min(1, vw / vh)
		local function aim()
			local angle, pitch = state.angle, state.pitch
			if diagram then angle, pitch = 0, -1.2 end
			camera.CFrame = CFrame.new(center.Position) * CFrame.Angles(0, angle, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, distance)
		end
		aim()
		if diagram then
			local body = Catalog:get(draft.body)
			local tan = math.tan(math.rad(camera.FieldOfView / 2))
			for i = 1, body.mount_count do
				-- Where the mount sits on screen (the preview has no flight body, so model space is the plane's frame).
				local at = camera.CFrame:PointToObjectSpace(Aircraft.mountOffset(i, body.visual_scale / 2, Aircraft.wingFit(draft.body, draft.wings, body.wing_shift), draft.weapon_mounts[i] or nil))
				local x = vx + vw * (0.5 + at.X / -at.Z / (2 * tan * vw / vh))
				local y = vy + vh * (0.5 - at.Y / -at.Z / (2 * tan))
				local chosen = i == state.mount
				-- Twice the size on a phone (Alan 2026-10-28: the numbers were too small to tap).
				local big = PaperUI.isPhone() and 2 or 1
				local r = (chosen and 19 or 15) * big
				local tag = button(content, "Mount" .. i, "", tostring(i), x - r, y - r, r * 2, r * 2, 0, function() state.mount = i; render() end, (chosen and 30 or 24) * big)
				tag.BackgroundTransparency, tag.BackgroundColor3, tag.ZIndex, tag.Label.ZIndex = 0, MOUNT_COLOURS[body.mount_types[i]], 3, 4
				Instance.new("UICorner", tag).CornerRadius = UDim.new(0.5, 0)
				local ring = Instance.new("UIStroke")
				ring.Thickness, ring.Color, ring.Parent = chosen and 5 or 3, chosen and Color3.fromRGB(255, 255, 255) or PaperUI.INK, tag
			end
		end
		-- Drag to turn the plane (mouse or a finger): sideways spins it, up and down tips it over to see the top or the
		-- underside.
		local last, finger
		local function press(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
		view.InputBegan:Connect(function(input) if press(input) then last, finger = input.Position, input end end)
		view.InputEnded:Connect(function(input) if input == finger or input.UserInputType == Enum.UserInputType.MouseButton1 then last, finger = nil, nil end end)
		view.InputChanged:Connect(function(input)
			if last and not diagram and (input.UserInputType == Enum.UserInputType.MouseMovement or input == finger) then
				state.angle += (input.Position.X - last.X) * 0.015
				state.pitch = math.clamp(state.pitch - (input.Position.Y - last.Y) * 0.015, -1.5, 1.5)
				last = input.Position; aim()
			end
		end)
		-- Turns slowly by itself while nobody is dragging it.
		local spin = RunService.RenderStepped:Connect(function(dt) if not last and not diagram then state.angle += dt * 0.35; aim() end end)
		view.Destroying:Connect(function() spin:Disconnect() end)
	end

	local function save(fly)
		state.dropAsk = nil
		local range = state.range and profile.rangePresets ~= nil
		api.action:FireServer(range and "saveRangePreset" or "savePreset", { slot = state.preset, name = state.builds[state.preset].name, loadout = state.draft, fly = fly })
		if fly then api.flown() end
	end

	render = function()
		for _, child in content:GetChildren() do child:Destroy() end
		shelf.frame.Visible, classShelf.frame.Visible = state.page == "shelf" and not state.classes, state.page == "shelf" and state.classes == true
		if not profile then return end
		local range = state.range and profile.rangePresets ~= nil
		local classes = state.classes and not range
		local builds = range and profile.rangePresets or profile.presets
		if classes then
			builds = {}
			for i, class in Catalog:classes() do
				local own = player:GetAttribute("Level") or 1
				builds[i] = { id = class.id, name = class.name, loadout = Catalog:classLoadout(class.id, 50), locked = own < class.min_level and class.min_level or nil }
			end
		end
		local dev = devMode()
		local level = (dev or range or classes) and 50 or player:GetAttribute("Level") or 1
		local ownership = (dev or range or classes) and everything or profile.ownership
		local saved = builds[state.preset].loadout
		state.builder = state.builder or Builder.new(Catalog, saved, ownership, level)
		state.builder:update({ selectedLoadout = saved, selectedRevision = state.preset, profile = { ownership = ownership, level = level } })
		local builder = state.builder
		local draft = builder.candidate
		state.builds, state.draft = builds, draft
		-- A rename still saving (or just saved: the server may have filtered it) shows the typed name for 10 s.
		for i, build in builds do
			local pending = state.names[(range and "range" or "my") .. i]
			if pending and os.clock() - pending.at < 10 then build.name = pending.name end
		end
		-- Unsaved: the draft differs from the saved build (compared after the same mount clean-up the draft had).
		local savedBuild = Builder.new(Catalog, saved).candidate
		state.unsaved = not Builder.equal(draft, savedBuild)

		if state.page == "shelf" then
			local class = player:GetAttribute("SelectedClass")
			if classes then
				local picked
				for i, build in builds do if build.id == class then picked = i end end
				classShelf.set(builds, picked, "Presets", Color3.fromRGB(120, 200, 255))
			else shelf.set(builds, not (class and not range) and state.preset or nil, range and "Range" or "Loadouts", range and RANGE_PINK or Color3.fromRGB(255, 215, 60)) end
			if not range and not Root:GetAttribute("TutorialOpen") then
				local other = button(content, "ShelfSwitch", Shelf.shelfTab, classes and "Loadouts" or "Presets", 440, 582, 320, 92, 0, function() switchShelf(not classes) end, 46)
				other.ZIndex = 3
			end
			if range then
				-- Purple, and under Back on a phone (Alan 2026-10-28: red and on top of the moved Back, it read as a second Back).
				-- At the strip's own shape (1024 x 227), the words between its ends.
				local note = image(content, "RangeNote", Assets.range.stripPurple, 15, PaperUI.isPhone() and 390 or 170, 300, 67, -4)
				local text = words(note, "Label", "Range loadouts: practice only", 30, 0, 240, 67, 24)
				text.TextXAlignment = Enum.TextXAlignment.Center
				PaperUI.fitWords(text, 240)
			end
			-- The name tape sits on the photo's paper, between its two bottom corner tapes (Alan 2026-11-09: no paper
			-- hanging off another); the plane's view stops above it.
			local TAPE = { PHOTO[1] + 140, 441, 500, 68 } -- the tape's own shape (984 x 134)
			preview(draft, PHOTO, nil, nil, PHOTO[2] + PHOTO[4] * 0.87 - TAPE[2] + 6)
			-- Presets: what they are, written on the stats paper under the rows (it floated on the cork).
			statSheet(Catalog:deriveStats(draft), nil, 1535 - 316, 8, 632, "wide", -- centred over Customize
				classes and "Presets can't be changed. Level up to unlock parts for your own loadouts." or nil)
			if classes then
				image(content, "NameTape", Assets.ingame.tapeLabel, table.unpack(TAPE))
				words(content, "BuildName", builds[state.preset].name, TAPE[1] + 30, TAPE[2], TAPE[3] - 60, TAPE[4], 46).TextXAlignment = Enum.TextXAlignment.Center
				return
			end
			nameTag(content, TAPE[1], TAPE[2], TAPE[3], TAPE[4], 46)
			local open = button(content, "Customize", Shelf.buttonOrange, "Customize", 1235, 564, 600, PaperUI.isPhone() and 130 or 120, -1, function()
				state.page, state.slot, state.trying = "customize", "body", nil
				render()
			end, 72)
			open.ZIndex = 2
			return
		end
		local binder = Instance.new("Frame")
		binder.Name, binder.BackgroundTransparency, binder.Size, binder.Parent = "BinderSide", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), content
		binder.Position = UDim2.fromOffset(0, PaperUI.H * (1 - Customize.BINDER_SCALE) / 2) -- the same cork above and below
		local shrink = Instance.new("UIScale")
		shrink.Scale, shrink.Parent = Customize.BINDER_SCALE, binder
		Customize.draw(binder, {
			side = content, -- the unshrunk sheet: the stats paper, Save and Fly sit there
			state = state, builder = builder, draft = draft, profile = profile, range = range, dev = devMode(), catalog = Catalog,
			owned = function(part) return devMode() or range or Catalog:owns(profile.ownership, part.id, player:GetAttribute("Level") or 1) end,
			choose = choose, placeWeapon = placeWeapon, statSheet = statSheet, preview = preview, nameTag = nameTag,
			-- A card being tried on: the same change on a scratch copy of the build, so the real one is untouched.
			tryOn = function(pick) local scratch = Builder.new(Catalog, draft, ownership, level); return pick(scratch) and scratch.candidate or nil end,
			save = save, atDesk = atDesk, api = api, render = render, mountColours = MOUNT_COLOURS,
		})
	end

	local self = { frame = cover }
	-- The Hangar Tour (TutorialLessons) watches what the player does here (page, tab, picked build, spot, draft) and
	-- can turn back to the binder or close it. ponytail: there is one Hangar screen, so a module field is enough.
	Hangar.tour = { state = state, render = function() render() end, close = function() api.flown() end }
	-- Redraw only when something the hangar shows changed: redrawing replaces the buttons, and a click that
	-- lands on a replaced button is lost (the menu refreshes the profile every 3 seconds).
	local shown
	function self.update(player, newProfile)
		local key = newProfile and game:GetService("HttpService"):JSONEncode({ newProfile.paper, newProfile.ownership, newProfile.presets, newProfile.rangePresets,
			player:GetAttribute("MenuMessage"), atDesk() })
		if key == shown and #content:GetChildren() > 0 then return end
		shown, profile = key, newProfile
		render()
	end
	function self.draft() return state.draft end
	-- Opening the hangar shows the shelf on the build you fly, unless you left changes unsaved: then it reopens
	-- Customize on them. Opened in the Range it shows the Range's builds (switching lists drops the other list's draft).
	-- page "customize" (the desk's Customize button) opens straight on the binder; slot: on that tab, on your own
	-- loadout even if you fly a preset (the unlock card's Put it on / See it).
	function self.open(page, slot)
		local range = inRange()
		local selected = range and (player:GetAttribute("RangeSlot") or 1) or player:GetAttribute("SelectedPreset") or 1
		local unsaved = range == state.range and state.unsaved
		if range ~= state.range then state.builder = nil end
		state.range = range
		-- A preset opens on the Presets board, even from the desk's Customize (nothing on it can be changed); the Hangar Tour
		-- always uses your own loadouts.
		local classes = not slot and not range and not unsaved and not Root:GetAttribute("TutorialOpen") and player:GetAttribute("SelectedClass") ~= nil
		if classes then page = nil end
		if classes ~= (state.classes == true) then state.builder = nil end
		state.classes = classes
		if classes then
			for i, class in Catalog:classes() do if class.id == player:GetAttribute("SelectedClass") then selected = i end end
		end
		state.page, state.dropAsk, state.trying = (unsaved or page == "customize") and "customize" or "shelf", nil, nil
		if page == "customize" and not unsaved then state.slot = slot or "body" end
		if not unsaved then
			state.preset = selected
			if state.builder and state.builds and state.builds[selected] then state.builder:reset(state.builds[selected].loadout, selected) end
		end
		shown = nil
	end
	return self
end

return Hangar
