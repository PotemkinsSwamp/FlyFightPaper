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
local PHOTO = { 346, 40, 750, 520 } -- the shelf screen's big taped photo (x, y, w, h in sheet pixels)

-- api = { action = RoundAction remote, back(), flown() (after Save & fly), fly(loadout) (Studio only) }
function Hangar.new(playerGui, api)
	-- ponytail: the old folder background stands in until Alan uploads the cork board.
	local cover, sheet = PaperUI.screen(playerGui, "HangarScreen", #Shelf.bg > 0 and Shelf.bg or Art.bg)
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

	-- The stat sheet: five crayon bars and the weight row, drawn at full size inside a frame that is placed and
	-- scaled (the shelf screen and the binder each fit it beside their own pieces).
	local ROW = 98
	local function statSheet(stats, compare, x, y, scale)
		local holder = Instance.new("Frame")
		holder.Name, holder.BackgroundTransparency = "Stats", 1
		holder.Position, holder.Size, holder.Parent = UDim2.fromOffset(x, y), UDim2.fromOffset(575, 640), content
		local fit = Instance.new("UIScale")
		fit.Scale, fit.Parent = scale, holder
		image(holder, "StatsSheet", Art.statsSheet, 0, 0, 575, 640, 1).ScaleType = Enum.ScaleType.Stretch
		local function statRow(name, art, top, tint)
			local strip = image(holder, name .. "Row", art, 60, top, 490, 84)
			strip.ScaleType = Enum.ScaleType.Stretch
			if tint then strip.ImageColor3 = tint end
			words(holder, name .. "Name", name, 82, top + 6, 190, 72, 38)
		end
		for i, entry in STATS do
			local name, row, bar, get, lo, hi, format, tint = table.unpack(entry)
			local top = 20 + (i - 1) * ROW
			statRow(name, Art.statRow[row], top, tint)
			local value = stats and get(stats) or lo
			local filled = math.clamp(math.ceil((value - lo) / (hi - lo) * 5), 1, 5)
			for k = 1, 5 do image(holder, name .. "Bar" .. k, k <= filled and Art.bar[bar] or Art.bar.empty, 260 + (k - 1) * 50, top + 20, 46, 42) end
			local shown = string.format(format, value)
			if compare then shown ..= string.format(" (%+.0f)", get(compare) - value) end
			words(holder, name .. "Value", shown, 85, top + 64, 445, 26, 24).TextXAlignment = Enum.TextXAlignment.Right
		end
		-- Weight: how much gear this body can carry (each gear card shows its weight).
		if stats then
			local top = 20 + #STATS * ROW
			statRow("Capacity", Art.statRow.blue, top, Color3.fromRGB(215, 190, 255))
			local cells = math.max(stats.capacity, 1)
			local w = math.min(50, 250 / cells)
			for k = 1, cells do
				image(holder, "Cap" .. k, k <= stats.used_capacity and Art.bar.blue or Art.bar.empty, 260 + (k - 1) * w, top + 20, w - 3, 42)
			end
			local used = words(holder, "CapacityValue", string.format("%d of %d used", stats.used_capacity, stats.capacity), 85, top + 64, 445, 26, 24)
			used.TextXAlignment = Enum.TextXAlignment.Right
			if stats.used_capacity >= stats.capacity then used.TextColor3 = Color3.fromRGB(170, 30, 30) end
		end
	end

	-- The build's name on masking tape (concept hangar-name-tape-a.png). On the shelf screen it is a box: click it to
	-- type a new name (up to NAME_MAX letters, Roblox-filtered on the server).
	local function nameTag(parent, x, y, w, h, editable)
		local build = state.builds[state.preset]
		image(parent, "NameTape", Assets.ingame.tapeLabel, x, y, w, h).ScaleType = Enum.ScaleType.Stretch
		if not editable then
			words(parent, "BuildName", build.name, x + 20, y, w - 40, h, 44).TextXAlignment = Enum.TextXAlignment.Center
			return
		end
		local nameBox = Instance.new("TextBox")
		nameBox.Name, nameBox.Text, nameBox.PlaceholderText, nameBox.ClearTextOnFocus = "BuildName", build.name, "Name this build", false
		nameBox.Position, nameBox.Size, nameBox.BackgroundTransparency = UDim2.fromOffset(x + 30, y), UDim2.fromOffset(w - 130, h), 1
		nameBox.FontFace, nameBox.TextSize, nameBox.TextColor3 = PaperUI.font, 52, PaperUI.INK
		nameBox.TextTruncate, nameBox.Parent = Enum.TextTruncate.AtEnd, parent
		local hint = words(parent, "Rename", "rename", x + w - 105, y, 90, h, 24)
		hint.TextTransparency = 0.4
		nameBox:GetPropertyChangedSignal("Text"):Connect(function()
			if utf8.len(nameBox.Text) and utf8.len(nameBox.Text) > NAME_MAX then nameBox.Text = nameBox.Text:sub(1, utf8.offset(nameBox.Text, NAME_MAX + 1) - 1) end
		end)
		nameBox.FocusLost:Connect(function()
			local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" or name == build.name then nameBox.Text = build.name; return end
			api.action:FireServer("renamePreset", { range = state.range, slot = state.preset, name = name })
		end)
	end

	-- The plane on taped sky-blue paper. box = the paper (x, y, w, h); the 3D view sits inside it.
	-- diagram (Gear page): a still view from above and behind (nose up) with a numbered tag on every mount.
	local function preview(draft, box, diagram)
		local px, py, pw, ph = table.unpack(box)
		image(content, "PreviewPaper", Art.preview, px, py, pw, ph, 0).ImageColor3 = Color3.fromRGB(140, 185, 230)
		local vx, vy, vw, vh = px + pw * 0.07, py + ph * 0.13, pw * 0.86, ph * 0.74
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
		local distance = math.max(size.X, size.Z) / 2 * 1.05 / math.sin(math.rad(camera.FieldOfView / 2))
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
			shelf.set(builds, state.preset, range and "Range" or "My builds")
			preview(draft, PHOTO)
			nameTag(content, PHOTO[1] + 110, PHOTO[2] + PHOTO[4] - 60, 530, 100, true)
			statSheet(Catalog:deriveStats(draft), nil, 1290, 12, 0.85)
			local open = button(content, "Customize", Shelf.buttonOrange, "Customize", 1300, 568, 500, 118, -1, function()
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
