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
local dev = RunService:IsStudio()
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

-- api = { action = RoundAction remote, back(), flown() (after Save & fly), fly(loadout) (Studio only) }
function Hangar.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "HangarScreen", Shelf.bg)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Size, content.Parent = "Content", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet

	local player = game.Players.LocalPlayer
	local state = { preset = player:GetAttribute("SelectedPreset") or 1, page = "shelf", slot = "body", mount = 1, angle = 0.5, pitch = -0.5 }
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
	button(sheet, "Back", Assets.range.stripRed, "Back", 30, 25, 270, 110, -3, function()
		if state.page == "shelf" then api.back(); return end
		if state.unsaved and not state.dropAsk then state.dropAsk = true; render(); return end
		state.page, state.purchase, state.dropAsk = "shelf", nil, nil
		state.builder:reset(state.builds[state.preset].loadout, state.preset)
		render()
	end, 54).ZIndex = 5

	-- Tapping a cubby picks that build: the one you fly next (in the Range it swaps your plane).
	local shelf = BuildShelf.new(sheet, Catalog, function(i)
		if i == state.preset then return end
		state.preset, state.purchase, state.dropAsk = i, nil, nil
		state.builder:reset(state.builds[i].loadout, i)
		if state.range then api.action:FireServer("range", "load" .. i) else api.action:FireServer("selectPreset", i) end
		render()
	end)

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

	-- The stat sheet (concept hangar-shelf-screen.png): taped notebook paper, a coloured paper label per stat and five
	-- crayon boxes, then the weight row (how much gear this body carries). It lays itself out to fit its box (the
	-- shelf screen's is wide, the binder's tall). compare (buying a part): each label shows what the part changes.
	local function statSheet(stats, compare, x, y, w, h)
		image(content, "StatsSheet", Shelf.statsPaper, x, y, w, h).ScaleType = Enum.ScaleType.Stretch
		local rowH = h * 0.8 / (#STATS + 1)
		local labelX, labelW = x + w * 0.1, w * 0.36
		local function row(i, name, tint, filled, cells)
			local top = y + h * 0.13 + (i - 1) * rowH
			local strip = image(content, name .. "Row", Shelf.statLabel, labelX, top + rowH * 0.08, labelW, rowH * 0.84)
			strip.ScaleType, strip.ImageColor3 = Enum.ScaleType.Stretch, tint
			local label = words(content, name .. "Name", name, labelX + 10, top, labelW - 20, rowH, 40)
			label.TextXAlignment, label.TextScaled = Enum.TextXAlignment.Center, true
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = math.floor(rowH * 0.55), label
			local size = math.min(rowH * 0.72, w * 0.46 / (math.max(cells, 5) * 1.12))
			for k = 1, cells do
				local cell = image(content, name .. "Box" .. k, k <= filled and Shelf.statBox or Shelf.statBoxEmpty, labelX + labelW + 14 + (k - 1) * size * 1.12, top + (rowH - size) / 2, size, size)
				cell.ImageColor3 = tint
			end
			return label
		end
		for i, entry in STATS do
			local name, _, _, get, lo, hi = table.unpack(entry)
			local value = stats and get(stats) or lo
			local label = row(i, name, STAT_COLOURS[name], math.clamp(math.ceil((value - lo) / (hi - lo) * 5), 1, 5), 5)
			if compare then
				local change = value - get(compare)
				label.Text = string.format("%s %+.0f", name, change)
				label.TextColor3 = change < 0 and Color3.fromRGB(170, 30, 30) or change > 0 and Color3.fromRGB(20, 100, 40) or PaperUI.INK
			end
		end
		if stats then
			local label = row(#STATS + 1, "Weight", STAT_COLOURS.Weight, stats.used_capacity, math.max(stats.capacity, 1))
			if stats.used_capacity >= stats.capacity then label.TextColor3 = Color3.fromRGB(170, 30, 30) end
		end
	end

	-- The build's name on masking tape with a pencil (concept hangar-name-tape-a.png), on both screens: click the name
	-- or the pencil to type a new one (up to NAME_MAX letters, Roblox-filtered on the server). size = letter size.
	local function nameTag(parent, x, y, w, h, size)
		local build = state.builds[state.preset]
		image(parent, "NameTape", Assets.ingame.tapeLabel, x, y, w, h).ScaleType = Enum.ScaleType.Stretch
		local nameBox = Instance.new("TextBox")
		nameBox.Name, nameBox.Text, nameBox.PlaceholderText, nameBox.ClearTextOnFocus = "BuildName", build.name, "Name this build", false
		nameBox.Position, nameBox.Size, nameBox.BackgroundTransparency = UDim2.fromOffset(x + 30, y), UDim2.fromOffset(w - 130, h), 1
		nameBox.FontFace, nameBox.TextSize, nameBox.TextColor3 = PaperUI.font, size, PaperUI.INK
		nameBox.TextTruncate, nameBox.Parent = Enum.TextTruncate.AtEnd, parent
		local pencil = Instance.new("ImageButton")
		pencil.Name, pencil.Image, pencil.BackgroundTransparency, pencil.Rotation = "Rename", Assets.settings.pencil, 1, -35
		pencil.AnchorPoint, pencil.Position, pencil.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(x + w - 55, y + h / 2), UDim2.fromOffset(96, 26)
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
		end)
	end

	-- The plane in 3D. box = (x, y, w, h). On the shelf screen it sits on taped sky-blue paper; bare (the binder's
	-- left page, which is blue already) it fills the box with no paper (Alan 2026-10-21: a stretched photo looked bad).
	-- diagram (Gear page): a still view from above and behind (nose up) with a numbered tag on every mount.
	local function preview(draft, box, diagram, bare)
		local px, py, pw, ph = table.unpack(box)
		local vx, vy, vw, vh = px, py, pw, ph
		if not bare then
			local paper = image(content, "PreviewPaper", Art.preview, px, py, pw, ph, 0)
			paper.ScaleType, paper.ImageColor3 = Enum.ScaleType.Stretch, state.range and Color3.fromRGB(235, 165, 195) or SKY_BLUE
			vx, vy, vw, vh = px + pw * 0.07, py + ph * 0.13, pw * 0.86, ph * 0.74
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
				local r = chosen and 19 or 15
				local tag = button(content, "Mount" .. i, "", tostring(i), x - r, y - r, r * 2, r * 2, 0, function() state.mount = i; render() end, chosen and 30 or 24)
				tag.BackgroundTransparency, tag.BackgroundColor3, tag.ZIndex, tag.Label.ZIndex = 0, MOUNT_COLOURS[body.mount_types[i]], 3, 4
				Instance.new("UICorner", tag).CornerRadius = UDim.new(0.5, 0)
				local ring = Instance.new("UIStroke")
				ring.Thickness, ring.Color, ring.Parent = chosen and 5 or 3, chosen and Color3.fromRGB(255, 255, 255) or PaperUI.INK, tag
			end
		end
		-- Drag to turn the plane: sideways spins it, up and down tips it over to see the top or the underside.
		local last
		view.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then last = input.Position end end)
		view.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then last = nil end end)
		view.InputChanged:Connect(function(input)
			if last and not diagram and input.UserInputType == Enum.UserInputType.MouseMovement then
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
		shelf.frame.Visible = state.page == "shelf"
		if not profile then return end
		local range = state.range and profile.rangePresets ~= nil
		local builds = range and profile.rangePresets or profile.presets
		local level = (dev or range) and 50 or player:GetAttribute("Level") or 1
		local ownership = (dev or range) and everything or profile.ownership
		local saved = builds[state.preset].loadout
		state.builder = state.builder or Builder.new(Catalog, saved, ownership, level)
		state.builder:update({ selectedLoadout = saved, selectedRevision = state.preset, profile = { ownership = ownership, level = level } })
		local builder = state.builder
		local draft = builder.candidate
		state.builds, state.draft = builds, draft
		-- Unsaved: the draft differs from the saved build (compared after the same mount clean-up the draft had).
		state.unsaved = not Builder.equal(draft, Builder.new(Catalog, saved).candidate)

		if state.page == "shelf" then
			shelf.set(builds, state.preset, range and "Range" or "My builds", range and RANGE_PINK or Color3.fromRGB(255, 215, 60))
			if range then
				local note = image(content, "RangeNote", Assets.range.stripRed, 20, 170, 300, 130, -4)
				note.ScaleType = Enum.ScaleType.Stretch
				local text = words(note, "Label", "Range builds: practice only", 20, 0, 270, 130, 36)
				text.TextXAlignment, text.TextWrapped = Enum.TextXAlignment.Center, true
			end
			preview(draft, PHOTO)
			nameTag(content, PHOTO[1] + 125, PHOTO[2] + PHOTO[4] - 75, 530, 100, 52)
			statSheet(Catalog:deriveStats(draft), nil, 1140, 8, 750, 530)
			local open = button(content, "Customize", Shelf.buttonOrange, "Customize", 1235, 530, 600, 120, -1, function()
				state.page, state.slot, state.purchase = "customize", "body", nil
				render()
			end, 72)
			open.ZIndex = 2
			return
		end
		Customize.draw(content, {
			state = state, builder = builder, draft = draft, profile = profile, range = range, dev = dev, catalog = Catalog,
			owned = function(part) return dev or range or profile.ownership[part.id] == true end,
			choose = choose, placeWeapon = placeWeapon, statSheet = statSheet, preview = preview, nameTag = nameTag,
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
	function self.open()
		local range = inRange()
		local selected = range and (player:GetAttribute("RangeSlot") or 1) or player:GetAttribute("SelectedPreset") or 1
		local unsaved = range == state.range and state.unsaved
		if range ~= state.range then state.builder = nil end
		state.range = range
		state.page, state.dropAsk, state.purchase = unsaved and "customize" or "shelf", nil, nil
		if not unsaved then
			state.preset = selected
			if state.builder and state.builds then state.builder:reset(state.builds[selected].loadout, selected) end
		end
		shown = nil
	end
	return self
end

return Hangar
