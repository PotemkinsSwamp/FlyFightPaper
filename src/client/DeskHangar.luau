-- In-game hangar menu, shown while your plane sits in its desk hangar. Layout B (plane left, service buttons right,
-- saved builds along the bottom) drawn with the main-menu Hangar's own art (Alan, 2026-10-11): the kraft folder, the
-- taped preview paper, construction-paper strips, crayon stat bars and numbered build squares.
-- Picking a build selects it and shows it on the preview; Full refold (or a fresh plane) flies it. Edit opens the
-- full Hangar on it: builds only change at the desk (Alan 2026-10-17).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local Rules = require(Root.Shared.ServiceRules)
local Builder = require(Root.Shared.BuilderModel)
local Art = require(Root.Shared.UIAssets).hangar
local BuildStats = {}
for _, entry in require(script.Parent.Hangar).STATS do BuildStats[entry[1]] = entry end
local PaperUI = require(script.Parent.PaperUI)
local DeskHangar = {}

-- A camera framing a model in a ViewportFrame: from its left side, a little above and behind, so the nose points right.
-- room: camera distance as a share of "whole model just fits" (smaller = bigger plane).
local function frame(view, model, room)
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, view.CurrentCamera = 40, view, camera
	local cf, size = model:GetBoundingBox()
	local reach = size.Magnitude * 0.5 / math.tan(math.rad(20)) * room
	camera.CFrame = CFrame.lookAt(cf.Position + (cf.RightVector * -0.9 + cf.UpVector * 0.6 + cf.LookVector * -0.2).Unit * reach, cf.Position)
end

local function viewport(parent, name, x, y, w, h)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency = name, 1
	view.Position, view.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	view.Ambient, view.LightDirection, view.Parent = Color3.fromRGB(220, 218, 210), Vector3.new(-1, -1, -1), parent
	return view
end

-- api = { flight(action) = FlightAction, round = RoundAction remote }
function DeskHangar.new(playerGui, api)
	-- Just the folder over the live game (Alan: you are still in the match, the quick menu is only pulled up).
	local cover, sheet = PaperUI.screen(playerGui, "DeskHangar", Art.folder, true)
	cover.Parent.DisplayOrder = 5 -- under the Menu button (6) and the menus and overlays (10)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	PaperUI.words(sheet, "Title", "Hangar", 60, 196, 285, 46, 42).TextXAlignment = Enum.TextXAlignment.Center

	-- The plane on the taped preview paper (sky-tinted like the main Hangar so the white plane stands out), and beside
	-- it, centred on it, the lined stats sheet: the main Hangar's stat strips and five crayon bar cells. Health, Lift and
	-- Boost show what is left now; Speed, Climb and Swerve show the build (same ranges as the main Hangar).
	image(sheet, "Preview", Art.preview, 60, 245, 750, 545).ImageColor3 = Color3.fromRGB(140, 185, 230)
	local planeView = viewport(sheet, "Plane", 95, 290, 680, 450)
	local heading = words(sheet, "PreviewHeading", "", 95, 258, 470, 40, 30)
	-- Your level along the bottom of the preview paper (made after the paper so it draws on top).
	local levelBar = require(script.Parent.LevelBar).new(sheet, 120, 698, 660, 24, true)
	-- Edit: the full Hangar on the picked build. It wiggles until a new player has used it once (Alan 2026-10-17).
	local edit = button(sheet, "Edit", Art.buttonGreen, "Edit build", 580, 250, 220, 80, 2, function()
		Root:SetAttribute("HangarEdited", true)
		require(script.Parent.MenuController).show("hangar", true)
	end, 36)
	if not Root:GetAttribute("HangarEdited") then
		local wiggle = TweenService:Create(edit, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = -3 })
		wiggle:Play()
		Root:GetAttributeChangedSignal("HangarEdited"):Once(function() wiggle:Cancel(); edit.Rotation = 2 end)
	end
	image(sheet, "StatsSheet", Art.statsSheet, 845, 266, 360, 504, 1).ScaleType = Enum.ScaleType.Stretch
	local rows = {
		{ "Health", "red", "red", function(p) return p:GetAttribute("Health") or 0, p:GetAttribute("MaxHealth") or 1 end },
		{ "Speed" }, { "Climb" }, { "Swerve" },
		{ "Lift", "yellow", "orange", function(p) return p:GetAttribute("Lift") or 0, p:GetAttribute("LiftMax") or 90 end },
		{ "Boost", "blue", "blue", function(p) return p:GetAttribute("Boost") or 0, p:GetAttribute("BoostMax") or 0 end },
	}
	for i, row in rows do
		local build = not row[4] and BuildStats[row[1]] -- Health and Lift stay live (what is left now)
		if build then
			local _, strip, bar, get, lo, hi = table.unpack(build)
			row[2], row[3], row[5], row.least = strip, bar, build[8], 1 -- like the main Hangar, a build stat shows at least one cell
			row[4] = function(p)
				return get({ speed = p:GetAttribute("Speed") or lo, pitch = p:GetAttribute("PitchRate") or lo, yaw = p:GetAttribute("YawRate") or lo }) - lo, hi - lo
			end
		end
		local y = 320 + (i - 1) * 65 -- strips glued inside the sheet, close together (Alan)
		local strip = image(sheet, row[1] .. "Row", Art.statRow[row[2]], 893, y, 290, 70)
		strip.ScaleType = Enum.ScaleType.Stretch
		if row[5] then strip.ImageColor3 = row[5] end
		words(sheet, row[1] .. "Name", row[1], 905, y + 5, 100, 60, 30)
		row.cells = {}
		for k = 1, 5 do row.cells[k] = image(sheet, row[1] .. "Bar" .. k, Art.bar.empty, 1010 + (k - 1) * 34, y + 19, 31, 32) end
	end
	-- The note sits on a torn paper label (the flight HUD's) so its red/orange warnings read on the cardboard.
	local label = image(sheet, "NotePaper", require(Root.Shared.UIAssets).ingame.tapeLabel, 90, 784, 1100, 58)
	label.ScaleType, label.SliceCenter, label.SliceScale = Enum.ScaleType.Slice, Rect.new(90, 30, 894, 104), 0.45
	local note = words(sheet, "Note", "", 110, 792, 1060, 42, 28)
	note.TextXAlignment = Enum.TextXAlignment.Center

	-- Score card.
	image(sheet, "ScoreCard", Art.card, 1240, 255, 620, 130).ScaleType = Enum.ScaleType.Stretch
	local score = words(sheet, "Score", "", 1240, 268, 620, 52, 44)
	local clock = words(sheet, "Clock", "", 1240, 318, 620, 52, 38)
	score.TextXAlignment, clock.TextXAlignment, score.RichText = Enum.TextXAlignment.Center, Enum.TextXAlignment.Center, true

	-- Service buttons on construction-paper strips, LAUNCH on the green taped paper (the main Hangar's Save build).
	local service = function(kind) return function() api.round:FireServer("service", kind) end end
	local buttons = {}
	for i, entry in {
		{ "Refill", "Refill Lift", "blue", service("refill") },
		{ "Repair", "Repair", "green", service("repair") },
		{ "Fresh", "Fresh plane", "yellow", function() api.flight("fresh") end },
		{ "Refold", "Full refold - 120 Paper", "red", function()
			-- Spending Paper asks once: the first click turns the strip into a question for 3 seconds.
			local label = buttons.Refold.Label
			if label.Text ~= "Sure? Click again - 120 Paper" then
				label.Text = "Sure? Click again - 120 Paper"
				task.delay(3, function() label.Text = "Full refold - 120 Paper" end)
				return
			end
			label.Text = "Full refold - 120 Paper"
			service("refold")()
		end },
	} do
		buttons[entry[1]] = button(sheet, entry[1], Art.statRow[entry[3]], entry[2], 1240, 385 + (i - 1) * 112, 620, 130, 0, entry[4], entry[1] == "Refold" and 40 or 48)
	end
	local launch = button(sheet, "Launch", Art.buttonGreen, "LAUNCH!", 1250, 840, 600, 160, -1, function() api.flight("launch") end, 80)

	-- Saved builds along the bottom: the main Hangar's numbered squares, each showing its real model.
	local slots, preset, shownPresets, presets, picked = {}, Players.LocalPlayer:GetAttribute("SelectedPreset") or 1, nil, nil, -9
	for i = 1, 5 do
		local slot = button(sheet, "Build" .. i, Art.slot, "", 70 + (i - 1) * 225, 840, 150, 150, 0, function()
			preset = i; api.round:FireServer("selectPreset", i); picked = os.clock()
			for k, other in slots do other.Image = k == i and Art.slotSelected or Art.slot end
		end)
		words(slot, "Number", tostring(i), 14, 6, 40, 40, 36)
		slots[i] = slot
	end
	PaperUI.popIn(cover, { buttons.Refill, buttons.Repair, buttons.Fresh, buttons.Refold, launch, edit })
	Players.LocalPlayer:GetAttributeChangedSignal("SelectedPreset"):Connect(function()
		preset = Players.LocalPlayer:GetAttribute("SelectedPreset") or 1
		for k, other in slots do other.Image = k == preset and Art.slotSelected or Art.slot end
	end)

	local function showPresets(list)
		presets = list
		local key = HttpService:JSONEncode(presets)
		if key == shownPresets then return end
		shownPresets = key
		for i, slot in slots do
			slot.Image = i == preset and Art.slotSelected or Art.slot
			local old = slot:FindFirstChild("Model")
			if old then old:Destroy() end
			local loadout = presets[i] and presets[i].loadout
			if loadout then
				local view = viewport(slot, "Model", 12, 30, 126, 110)
				local world = Instance.new("WorldModel")
				world.Parent = view
				local model = Instance.new("Model")
				model.Parent = world
				if Aircraft.build(model, loadout, Catalog, true) then frame(view, model, 0.85) end
			end
		end
	end
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if profile and profile.presets then showPresets(profile.presets) end
		if profile and profile.xp then levelBar.set(profile.xp) end
	end)
	Root:WaitForChild("RoundView").OnClientEvent:Connect(function(snapshot)
		local remaining = snapshot.endsAt and math.max(0, math.ceil(snapshot.endsAt - snapshot.serverTime)) or 0
		clock.Text = string.format("%d:%02d left", math.floor(remaining / 60), remaining % 60)
		if snapshot.mode ~= "FFA" and snapshot.teams then
			score.Text = string.format('<font color="#D22828">Red %.0f</font> - <font color="#2850D2">Blue %.0f</font>', snapshot.teams["team:1"], snapshot.teams["team:2"])
		else
			score.Text = snapshot.mode or ""
		end
	end)

	-- The picked build when it isn't the one you fly: its model, and its stats read like a fresh plane's.
	local function pickedBuild(plane)
		local loadout = presets and presets[preset] and presets[preset].loadout
		local ok, flying = pcall(HttpService.JSONDecode, HttpService, plane:GetAttribute("LoadoutData") or "")
		if not loadout or not ok or Builder.equal(loadout, flying) then return nil end
		local stats = Catalog:deriveStats(loadout)
		if not stats then return nil end
		local utility = loadout.utility and Catalog:get(loadout.utility)
		local boost = utility and utility.boost_seconds or 0
		local values = { Health = stats.health, MaxHealth = stats.health, Lift = stats.lift, LiftMax = stats.lift, Speed = stats.speed,
			PitchRate = stats.pitch, YawRate = stats.yaw, Boost = boost, BoostMax = boost }
		return loadout, { GetAttribute = function(_, key) return values[key] end }
	end

	-- The live plane: a copy of what your plane looks like now, rebuilt when its parts change.
	local shownPlane
	local function showPlane(plane)
		local picked = pickedBuild(plane)
		if picked then
			local key = HttpService:JSONEncode(picked)
			if shownPlane == key then return end
			shownPlane = key
			planeView:ClearAllChildren()
			local world = Instance.new("WorldModel")
			world.Parent = planeView
			local model = Instance.new("Model")
			model.Parent = world
			if Aircraft.build(model, picked, Catalog, true) then frame(planeView, model, 0.62) end
			return
		end
		local appearance = plane:FindFirstChild("Appearance")
		local body = plane:FindFirstChild("Root")
		if not appearance or not body or appearance == shownPlane then return end
		shownPlane = appearance
		planeView:ClearAllChildren()
		local world = Instance.new("WorldModel")
		world.Parent = planeView
		local model = Instance.new("Model")
		model.Parent = world
		for _, part in appearance:GetChildren() do
			if part:IsA("BasePart") then
				local copy = part:Clone()
				copy:ClearAllChildren()
				for _, look in part:GetChildren() do if look:IsA("SurfaceAppearance") or look:IsA("Decal") then look:Clone().Parent = copy end end
				copy.Anchored, copy.CFrame, copy.Parent = true, body.CFrame:ToObjectSpace(part.CFrame), model
			end
		end
		frame(planeView, model, 0.62)
	end

	local self = {}
	local lastMessage, messageAt = nil, -9 -- service results ("Service complete", "You need 120 Paper") show for 4 s
	-- Called by the HUD every 0.1 s: shown while the plane is in its hangar.
	function self.update(plane, visible)
		cover.Visible = visible
		if not visible then shownPlane = nil; return end
		showPlane(plane)
		local _, pickedStats = pickedBuild(plane)
		heading.Text = pickedStats and string.format("Build %d (not flying yet)", preset) or "Flying now"
		for _, row in rows do
			local value, max = row[4](pickedStats or plane)
			local cells = math.max(row.least or 0, max > 0 and math.ceil(math.clamp(value / max, 0, 1) * 5) or 0)
			for k = 1, 5 do row.cells[k].Image = k <= cells and Art.bar[row[3]] or Art.bar.empty end
		end
		local remaining = plane:GetAttribute("ProtectionRemaining") or 120
		local repair = Rules.repair(plane:GetAttribute("OriginalHealth"), plane:GetAttribute("MaxHealth"), plane:GetAttribute("Health"))
		local message = plane:GetAttribute("Message")
		if message ~= lastMessage then lastMessage, messageAt = message, os.clock() end
		note.Text = (plane:GetAttribute("ServiceBusy") or os.clock() - messageAt < 4) and message and message ~= "" and message
			or os.clock() - picked < 4 and string.format("Build %d picked: Full refold flies it, Edit changes its parts.", preset)
			or remaining <= 0 and "Hangar safety used up: it comes back after 2 minutes out of the hangar, or with a kill."
			or string.format("Safe in the hangar: %.0fs. Repair leaves %.0f max health. A fresh plane ends your streak.", remaining, repair and repair.lifeMaxHealth or 0)
		note.TextColor3 = remaining <= 10 and Color3.fromRGB(200, 40, 30) or remaining <= 30 and Color3.fromRGB(200, 110, 20) or PaperUI.INK
	end
	self.sheet = sheet
	return self
end

return DeskHangar
