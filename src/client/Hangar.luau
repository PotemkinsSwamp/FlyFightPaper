-- Hangar on a kraft-cardboard folder (Alan's approved concept: assets/references/ui-concepts/hangar.png).
-- Folder tabs pick the part slot, part cards on the left, the 3D plane on taped paper, crayon stat bars on the right,
-- five saved builds along the bottom.
local Root = game.ReplicatedStorage.FlyFightPaper
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local Schema = require(Root.Shared.ProfileSchema)
local Builder = require(Root.Shared.BuilderModel)
local CombatRules = require(Root.Shared.CombatRules)
local Art = require(Root.Shared.UIAssets).hangar
local PaperUI = require(script.Parent.PaperUI)
local Hangar = {}

-- Studio dev mode: every part counts as owned at the level cap, and "Fly this build" sends the draft straight
-- to your plane for testing. Nothing here is saved or bought; live servers ignore it.
local RunService = game:GetService("RunService")
local dev = RunService:IsStudio()
local everything = {}
for _, list in { Catalog.weapons, Catalog.utilities } do for _, part in list do everything[part.id] = true end end
for _, list in Catalog.structuresBySlot do for _, part in list do everything[part.id] = true end end

local TABS = { "body", "nose", "wings", "tail", "weapons", "boost" }
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
-- Mount tags on the weapons tab, by mount size (picked to show on red or blue paper and the sky-blue photo).
local MOUNT_COLOURS = { light = Color3.fromRGB(70, 185, 80), medium = Color3.fromRGB(250, 200, 30), heavy = Color3.fromRGB(150, 80, 215) }

-- api = { action = RoundAction remote, back(), fly(loadout) (Studio only) }
function Hangar.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "HangarScreen", Art.bg)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Size, content.Parent = "Content", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet
	button(sheet, "Back", Art.buttonGreen, "Back", 1390, 30, 230, 95, 2, api.back, 50)
	if dev then button(sheet, "FlyBuild", Art.buttonGreen, "Fly this build", 40, 40, 330, 95, -2, function() api.fly() end, 40) end

	local state = { preset = 1, slot = "body", mount = 1, angle = 0.5, pitch = -0.5 }
	local profile, render

	local function choose(pick, ...)
		state.builder.message = ""
		local ok, reason = pick(state.builder, ...)
		if not ok then
			reason = tostring(reason)
			if reason=="two weapon types per plane" then reason = "Two weapon types per plane: one for left click, one for right click."
			elseif reason:find("capacity exceeds") then reason = "Too much weight for this body. Remove a weapon or pick a bigger body."
			elseif reason:find("incompatible with ordered mount") then reason = "That weapon is too big for that mount." end
			state.builder.message = reason
		end
		render()
	end
	-- Weapons go where they fit, moving others around if needed (BuilderModel.placeWeapon, Alan's note 20).
	local function placeWeapon(id)
		local ok, result = state.builder:placeWeapon(id, state.mount)
		if ok then state.mount = result end
		return ok, result
	end

	-- Six rows on the lined sheet: five crayon bars and the weapon capacity row.
	local ROW = 98
	local function statRow(name, art, y, tint)
		local strip = image(content, name .. "Row", art, 1370, y, 490, 84)
		strip.ScaleType = Enum.ScaleType.Stretch
		if tint then strip.ImageColor3 = tint end
		words(content, name .. "Name", name, 1392, y + 6, 190, 72, 38)
	end
	local function statSheet(stats, compare)
		image(content, "StatsSheet", Art.statsSheet, 1310, 255, 575, 640, 1).ScaleType = Enum.ScaleType.Stretch
		for i, entry in STATS do
			local name, row, bar, get, lo, hi, format, tint = table.unpack(entry)
			local y = 275 + (i - 1) * ROW
			statRow(name, Art.statRow[row], y, tint)
			local value = stats and get(stats) or lo
			local filled = math.clamp(math.ceil((value - lo) / (hi - lo) * 5), 1, 5)
			for k = 1, 5 do image(content, name .. "Bar" .. k, k <= filled and Art.bar[bar] or Art.bar.empty, 1570 + (k - 1) * 50, y + 20, 46, 42) end
			local shown = string.format(format, value)
			if compare then shown ..= string.format(" (%+.0f)", get(compare) - value) end
			words(content, name .. "Value", shown, 1395, y + 64, 445, 26, 24).TextXAlignment = Enum.TextXAlignment.Right
		end
		-- Weapon capacity: how much weapon weight this body can carry (each weapon card shows its weight).
		if stats then
			local y = 275 + #STATS * ROW
			statRow("Capacity", Art.statRow.blue, y, Color3.fromRGB(215, 190, 255))
			local cells = math.max(stats.capacity, 1)
			local w = math.min(50, 250 / cells)
			for k = 1, cells do
				image(content, "Cap" .. k, k <= stats.used_capacity and Art.bar.blue or Art.bar.empty, 1570 + (k - 1) * w, y + 20, w - 3, 42)
			end
			local used = words(content, "CapacityValue", string.format("%d of %d used", stats.used_capacity, stats.capacity), 1395, y + 64, 445, 26, 24)
			used.TextXAlignment = Enum.TextXAlignment.Right
			if stats.used_capacity >= stats.capacity then used.TextColor3 = Color3.fromRGB(170, 30, 30) end
		end
	end

	local function preview(draft)
		-- Tinted sky-blue so the plane stands out from the cardboard sheet.
		image(content, "PreviewPaper", Art.preview, 575, 265, 720, 590, 0).ImageColor3 = Color3.fromRGB(140, 185, 230)
		local view = Instance.new("ViewportFrame")
		view.Name, view.BackgroundTransparency = "PlanePreview", 1
		view.Position, view.Size = UDim2.fromOffset(625, 345), UDim2.fromOffset(620, 430) -- the blue area of the paper
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
		local box, size = model:GetBoundingBox()
		local distance = math.max(size.X, size.Z) / 2 * 1.05 / math.sin(math.rad(camera.FieldOfView / 2))
		-- Weapons tab: a still view from above and behind (nose up) with a numbered tag on every mount: the diagram.
		local diagram = state.slot == "weapons" and not state.purchase
		local function aim()
			local angle, pitch = state.angle, state.pitch
			if diagram then angle, pitch = 0, -1.2 end
			camera.CFrame = CFrame.new(box.Position) * CFrame.Angles(0, angle, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, distance)
		end
		aim()
		if diagram then
			local body = Catalog:get(draft.body)
			local tan = math.tan(math.rad(camera.FieldOfView / 2))
			for i = 1, body.mount_count do
				-- Where the mount sits on screen (the preview has no flight body, so model space is the plane's frame).
				local at = camera.CFrame:PointToObjectSpace(Aircraft.mountOffset(i, body.visual_scale / 2, Aircraft.wingFit(draft.body, draft.wings, body.wing_shift), draft.weapon_mounts[i] or nil))
				local x = 625 + 620 * (0.5 + at.X / -at.Z / (2 * tan * 620 / 430))
				local y = 345 + 430 * (0.5 - at.Y / -at.Z / (2 * tan))
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

	render = function()
		for _, child in content:GetChildren() do child:Destroy() end
		if not profile then return end
		local level = dev and 50 or game.Players.LocalPlayer:GetAttribute("Level") or 1
		local ownership = dev and everything or profile.ownership
		local saved = profile.presets[state.preset].loadout
		state.builder = state.builder or Builder.new(Catalog, saved, ownership, level)
		state.builder:update({ selectedLoadout = saved, selectedRevision = state.preset, profile = { ownership = ownership, level = level } })
		local builder = state.builder
		local draft = builder.candidate

		for i, slot in TABS do
			local tab = button(content, "Tab" .. slot, slot == state.slot and Art.tabSelected or Art.tab, slot, 45 + (i - 1) * 305, 150, 290, 110, 0,
				function() state.slot = slot; state.purchase = nil; render() end, 50)
			tab.Label.Position = UDim2.fromOffset(0, -8)
		end

		-- Part cards: a 2-column grid (every slot has at most 6 parts, so they all fit).
		local definitions = Catalog.structuresBySlot[state.slot] or (state.slot == "weapons" and Catalog.weapons) or Catalog.utilities
		for i, part in definitions do
			local owned = dev or profile.ownership[part.id] == true
			local equipped = draft[state.slot] == part.id or draft.utility == part.id and state.slot == "boost"
				or state.slot == "weapons" and table.find(draft.weapon_mounts, part.id) ~= nil
			local x, y = 45 + (i - 1) % 2 * 262, 272 + math.floor((i - 1) / 2) * 200
			local card = button(content, part.id, equipped and Art.cardSelected or Art.card, "", x, y, 252, 190, 0, function()
				if not owned then state.purchase = part; render(); return end
				state.purchase = nil
				if state.slot == "weapons" then choose(function() return placeWeapon(part.id) end)
				elseif state.slot == "boost" then choose(builder.selectUtility, part.id)
				else choose(builder.selectStructure, state.slot, part.id) end
			end)
			local name = words(card, "Name", part.name, 18, 14, 216, 96, 36)
			name.TextWrapped, name.TextYAlignment = true, Enum.TextYAlignment.Top
			local detail = owned and (equipped and "Equipped" or "Owned") or string.format("%d Paper, lvl %d", part.paper_price, part.min_level)
			if state.slot == "weapons" then
				-- Damage (Alan): pips for how hard one shot hits, then damage per second.
				name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(216, 44), false, true -- long names shrink to one line
				local cap = Instance.new("UITextSizeConstraint")
				cap.MaxTextSize, cap.Parent = 34, name
				words(card, "HitLabel", "Hit", 18, 60, 50, 34, 26)
				local hit = Catalog.hitRating(part)
				for k = 1, 5 do image(card, "Hit" .. k, k <= hit and Art.bar.red or Art.bar.empty, 62 + (k - 1) * 30, 64, 27, 26) end
				words(card, "DPS", string.format("%.0f damage per second", Catalog.weaponDPS(part)), 18, 96, 216, 30, 24)
				detail = string.format("%s, weight %d. %s", part.class, part.capacity, detail)
				-- Can't go on this plane at all right now: a crayon X and why, so a kid sees what to change (note 21).
				local blocked = owned and not equipped and select(2, builder:findPlace(part.id, state.mount))
				if blocked then
					detail = blocked
					for _, angle in { 37, -37 } do
						local stroke = Instance.new("Frame")
						stroke.Name, stroke.AnchorPoint, stroke.Position = "CrayonX", Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
						stroke.Size, stroke.Rotation, stroke.ZIndex = UDim2.fromOffset(290, 12), angle, 5
						stroke.BackgroundColor3, stroke.BackgroundTransparency, stroke.BorderSizePixel = Color3.fromRGB(215, 35, 45), .15, 0
						Instance.new("UICorner", stroke).CornerRadius = UDim.new(.5, 0)
						stroke.Parent = card
					end
				end
				local status = words(card, "Status", detail, 18, 128, 216, 50, 21)
				status.TextWrapped = true
				if blocked then status.TextColor3, status.ZIndex = Color3.fromRGB(190, 20, 30), 6 end
			else
				local info = words(card, "Status", detail, 18, 110, 216, 66, 24)
				info.TextWrapped, info.TextYAlignment = true, Enum.TextYAlignment.Top
			end
		end

		local valid, reason = builder:validate(draft)
		local stats = Catalog:deriveStats(draft)
		preview(draft)

		-- Under the plane: mounts (weapons tab), the no-booster card (boost tab), or the purchase card.
		local note = builder.message ~= "" and builder.message or (not valid and tostring(reason))
			or game.Players.LocalPlayer:GetAttribute("MenuMessage") or ""
		if state.purchase then
			local part = state.purchase
			local candidate = assert(Schema.copy(draft))
			if state.slot == "weapons" then candidate.weapon_mounts[math.min(state.mount, Catalog:get(candidate.body).mount_count)] = part.id
			elseif state.slot == "boost" then candidate.utility = part.id
			else
				candidate[state.slot] = part.id
				if state.slot == "body" then
					local mounts = {}
					for i = 1, part.mount_count do mounts[i] = candidate.weapon_mounts[i] or false end
					candidate.weapon_mounts = mounts
				end
			end
			statSheet(Catalog:deriveStats(candidate) or stats, stats)
			note = string.format("%s: %d Paper, level %d. Bars show the plane with it.", part.name, part.paper_price, part.min_level)
			button(content, "BuyPart", Art.buttonGreen, "Buy", 640, 770, 260, 90, -1, function()
				api.action:FireServer("purchasePart", part.id); state.purchase = nil; render()
			end, 46)
			button(content, "CancelBuy", Art.tab, "Cancel", 930, 770, 260, 90, 1, function() state.purchase = nil; render() end, 40)
		else
			statSheet(stats)
			if state.slot == "weapons" then
				local body = Catalog:get(draft.body)
				local groups = assert(CombatRules.triggerGroups(draft))
				local i = math.min(state.mount, body.mount_count)
				local part = draft.weapon_mounts[i] and Catalog:get(draft.weapon_mounts[i])
				-- Key: a coloured dot and the size word for each mount size, top-left of the photo.
				for k, size in { "light", "medium", "heavy" } do
					local dot = Instance.new("Frame")
					dot.Position, dot.Size, dot.BackgroundColor3 = UDim2.fromOffset(645 + (k - 1) * 150, 360), UDim2.fromOffset(26, 26), MOUNT_COLOURS[size]
					Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
					Instance.new("UIStroke", dot).Thickness = 2
					dot.Parent = content
					words(content, "Key" .. size, size, 678 + (k - 1) * 150, 352, 110, 40, 34)
				end
				local info = words(content, "MountInfo", string.format("Mount %d: %s%s. %s", i, body.mount_types[i],
					part and (groups[i] == 1 and ", left click" or ", right click") or "", part and part.name or "Empty: pick a weapon."), 600, 782, 680, 56, 30)
				info.TextXAlignment = Enum.TextXAlignment.Center
				button(content, "ClearMount", Art.buttonGreen, "Clear mount " .. state.mount, 1090, 280, 200, 70, 3, function() choose(builder.selectMount, state.mount, false) end, 28)
			elseif state.slot == "boost" then
				button(content, "NoBoost", Art.tab, "No booster", 840, 775, 240, 80, 0, function() choose(builder.selectUtility, nil) end, 32)
			end
		end
		local message = words(content, "Message", note, 590, 852, 710, 50, 30)
		local problem = builder.message ~= "" or not valid
		message.TextColor3, message.TextWrapped = problem and Color3.fromRGB(170, 30, 30) or Color3.fromRGB(30, 110, 50), true

		-- Saved builds 1-5 and Save.
		for i = 1, 5 do
			button(content, "Preset" .. i, i == state.preset and Art.slotSelected or Art.slot, tostring(i), 600 + (i - 1) * 125, 905, 110, 110, 0, function()
				state.preset = i; state.purchase = nil; builder:reset(profile.presets[i].loadout, i)
				api.action:FireServer("selectPreset", i); render()
			end, 60)
		end
		button(content, "SavePreset", Art.buttonGreen, "Save build", 1320, 900, 560, 125, -1, function()
			api.action:FireServer("savePreset", { slot = state.preset, name = profile.presets[state.preset].name, loadout = draft })
		end, 64)
		state.draft = draft
	end

	local self = { frame = cover }
	-- Redraw only when something the hangar shows changed: redrawing replaces the buttons, and a click that
	-- lands on a replaced button is lost (the menu refreshes the profile every 3 seconds).
	local shown
	function self.update(player, newProfile)
		local key = newProfile and game:GetService("HttpService"):JSONEncode({ newProfile.paper, newProfile.ownership, newProfile.presets,
			player:GetAttribute("MenuMessage") })
		if key == shown and content:FindFirstChild("SavePreset") then return end
		shown, profile = key, newProfile
		render()
	end
	function self.draft() return state.draft end
	return self
end

return Hangar
