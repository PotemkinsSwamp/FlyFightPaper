-- In-game desk quick menu, shown while your plane sits in its desk hangar (Alan's pick 2026-10-22: concept
-- assets/references/ui-concepts/desk-quick-menu-b.png). Pieces pinned round the screen edges with the new Hangar's
-- art, so the runway, the match strip (top middle) and the kill feed (top right) stay in view: top left the plane's
-- photo, name tape and a short stat sheet; down the left your five builds as small photos; down the right the
-- service strips and Customize; bottom middle the hangar note and LAUNCH!.
-- Picking a build selects it and shows it on the photo; Full refold (or a fresh plane) flies it. Customize opens the
-- full Hangar's binder on it: builds only change at the desk (Alan 2026-10-17).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local Rules = require(Root.Shared.ServiceRules)
local Builder = require(Root.Shared.BuilderModel)
local Assets = require(Root.Shared.UIAssets)
local Art, Shelf = Assets.hangar, Assets.hangarShelf
local Hangar = require(script.Parent.Hangar)
local BuildStats = {}
for _, entry in Hangar.STATS do BuildStats[entry[1]] = entry end
local PaperUI = require(script.Parent.PaperUI)
local DeskHangar = {}

local SKY_BLUE = Color3.fromRGB(140, 185, 230)
local TOPBAR = 64 -- screen pixels kept clear for Roblox's top bar and the Menu button

-- A camera framing a model in a ViewportFrame like the Hangar's cubbies: from above and behind, nose away and a
-- little to the side. room: camera distance as a share of "whole model just fits" (smaller = bigger plane).
local function frame(view, model, room)
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, view.CurrentCamera = 40, view, camera
	local box, size = model:GetBoundingBox()
	local distance = math.max(size.X, size.Z) / 2 * 1.1 / math.sin(math.rad(20)) * room
	camera.CFrame = CFrame.new(box.Position) * CFrame.Angles(0, 0.5, 0) * CFrame.Angles(-0.6, 0, 0) * CFrame.new(0, 0, distance)
end

local function viewport(parent, name, x, y, w, h)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency = name, 1
	view.Position, view.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	view.Ambient, view.LightColor, view.LightDirection = Color3.fromRGB(140, 140, 150), Color3.fromRGB(255, 250, 235), Vector3.new(-0.6, -1, -0.4)
	view.Parent = parent
	return view
end

-- A fresh copy of a build's 3D plane in a view (the old one goes).
local function showBuild(view, loadout, room)
	view:ClearAllChildren()
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = Instance.new("Model")
	model.Parent = world
	if Aircraft.build(model, loadout, Catalog, true) then frame(view, model, room) end
end

-- api = { flight(action) = FlightAction, round = RoundAction remote }
function DeskHangar.new(playerGui, api)
	-- Just pieces over the live game (Alan: you are still in the match, the quick menu is only pulled up).
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.IgnoreGuiInset, layer.ResetOnSpawn, layer.DisplayOrder = "DeskHangar", true, false, 5 -- under the Menu button (6)
	layer.ZIndexBehavior, layer.Parent = Enum.ZIndexBehavior.Sibling, playerGui
	local cover = Instance.new("Frame")
	cover.Name, cover.Size, cover.BackgroundTransparency, cover.Visible, cover.Parent = "Cover", UDim2.fromScale(1, 1), 1, false, layer
	-- Three groups pinned to the screen's edges, drawn in 1920x1080 sheet pixels and scaled to fit the screen.
	local scales = {}
	local function panel(name, anchor, w, h)
		local group = Instance.new("Frame")
		group.Name, group.AnchorPoint, group.BackgroundTransparency, group.Size, group.Parent = name, anchor, 1, UDim2.fromOffset(w, h), cover
		local scale = Instance.new("UIScale")
		scale.Parent = group
		table.insert(scales, scale)
		return group
	end
	local left = panel("Left", Vector2.new(0, 0), 640, 1010)
	local right = panel("Right", Vector2.new(1, 0), 400, 540)
	local bottom = panel("Bottom", Vector2.new(0.5, 1), 640, 214)
	local function fit()
		local view = workspace.CurrentCamera.ViewportSize
		local s = math.min(view.X / PaperUI.W, (view.Y - TOPBAR) / 1016)
		for _, scale in scales do scale.Scale = s end
		left.Position, bottom.Position = UDim2.fromOffset(16, TOPBAR), UDim2.new(0.5, 0, 1, -12)
		-- The service strips start under the flight HUD's kill feed (FlightHUD: 10 px down, 4 slips, its own scale).
		right.Position = UDim2.new(1, -16, 0, 10 + 250 * math.max(0.6, view.Y / 1080))
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button

	-- Top left: the plane's taped sky-blue photo with its name on masking tape, and beside it the short stat sheet.
	local photo = image(left, "Photo", Art.preview, 0, 0, 300, 220, -2)
	photo.ScaleType, photo.ImageColor3 = Enum.ScaleType.Stretch, SKY_BLUE
	local planeView = viewport(left, "Plane", 24, 30, 252, 158)
	local notYet = words(left, "NotFlyingYet", "", 24, 10, 252, 28, 24)
	notYet.TextXAlignment, notYet.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(190, 35, 30)
	image(left, "NameTape", Assets.ingame.tapeLabel, 20, 188, 260, 56).ScaleType = Enum.ScaleType.Stretch
	local name = words(left, "BuildName", "", 40, 190, 220, 52, 32)
	name.TextXAlignment, name.TextScaled = Enum.TextXAlignment.Center, true
	local nameCap = Instance.new("UITextSizeConstraint")
	nameCap.MaxTextSize, nameCap.Parent = 32, name

	-- Health, Lift and Boost show what is left now; Speed shows the build (Alan 2026-10-22: these four, no turning
	-- or weight here; Customize has the full sheet).
	image(left, "StatsSheet", Shelf.statsPaper, 315, 0, 320, 250, 1).ScaleType = Enum.ScaleType.Stretch
	local speed = BuildStats.Speed
	local colours = Hangar.STAT_COLOURS
	local rows = {
		{ "Health", colours.Health, function(p) return p:GetAttribute("Health") or 0, p:GetAttribute("MaxHealth") or 1 end },
		{ "Speed", colours.Speed, function(p)
			return speed[4]({ speed = p:GetAttribute("Speed") or speed[5] }) - speed[5], speed[6] - speed[5]
		end, least = 1 }, -- like the Hangar, a build stat shows at least one box
		{ "Lift", colours.Lift, function(p) return p:GetAttribute("Lift") or 0, p:GetAttribute("LiftMax") or 90 end },
		{ "Boost", colours.Swerve, function(p) return p:GetAttribute("Boost") or 0, p:GetAttribute("BoostMax") or 0 end },
	}
	for i, row in rows do
		local y = 42 + (i - 1) * 50
		local strip = image(left, row[1] .. "Row", Shelf.statLabel, 333, y, 116, 42)
		strip.ScaleType, strip.ImageColor3 = Enum.ScaleType.Stretch, row[2]
		local label = words(left, row[1] .. "Name", row[1], 341, y, 100, 42, 28)
		label.TextXAlignment = Enum.TextXAlignment.Center
		row.cells = {}
		for k = 1, 5 do
			row.cells[k] = image(left, row[1] .. "Box" .. k, Shelf.statBoxEmpty, 456 + (k - 1) * 34, y + 6, 30, 30)
			row.cells[k].ImageColor3 = row[2]
		end
	end

	-- Bottom middle: the hangar note on masking tape, and LAUNCH! on the green taped paper.
	local label = image(bottom, "NotePaper", Assets.ingame.tapeLabel, 0, 0, 640, 56)
	label.ScaleType, label.SliceCenter, label.SliceScale = Enum.ScaleType.Slice, Rect.new(90, 30, 894, 104), 0.45
	local note = words(bottom, "Note", "", 30, 4, 580, 48, 26)
	note.TextXAlignment, note.TextScaled = Enum.TextXAlignment.Center, true
	local noteCap = Instance.new("UITextSizeConstraint")
	noteCap.MaxTextSize, noteCap.Parent = 26, note
	local launch = button(bottom, "Launch", Art.buttonGreen, "LAUNCH!", 40, 66, 560, 148, -1, function() api.flight("launch") end, 84)

	-- Down the right: the service strips (the Range's torn construction paper), then Customize (the Hangar's orange).
	local service = function(kind) return function() api.round:FireServer("service", kind) end end
	local REFOLD = "Full refold - 120 Paper"
	local buttons = {}
	for i, entry in {
		{ "Refill", "Refill Lift", Assets.range.stripBlue, service("refill") },
		{ "Repair", "Repair", Assets.range.stripGreen, service("repair") },
		{ "Fresh", "Fresh plane", Assets.range.stripYellow, function() api.flight("fresh") end },
		{ "Refold", REFOLD, Assets.range.stripRed, function()
			-- Spending Paper asks once: the first click turns the strip into a question for 3 seconds.
			local text = buttons.Refold.Label
			if text.Text ~= "Sure? Click again" then
				text.Text = "Sure? Click again"
				task.delay(3, function() text.Text = REFOLD end)
				return
			end
			text.Text = REFOLD
			service("refold")()
		end },
	} do
		buttons[entry[1]] = button(right, entry[1], entry[3], entry[2], 0, (i - 1) * 104, 400, 88, i % 2 == 0 and 1 or -1, entry[4], entry[1] == "Refold" and 32 or 44)
	end
	local customize = button(right, "Customize", Shelf.buttonOrange, "Customize", 0, 424, 400, 112, 1, function()
		Root:SetAttribute("HangarEdited", true)
		require(script.Parent.MenuController).show("hangar", true, "customize")
	end, 52)
	-- Customize wiggles until a new player has used it once (Alan 2026-10-17).
	if not Root:GetAttribute("HangarEdited") then
		local wiggle = TweenService:Create(customize, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = -3 })
		wiggle:Play()
		Root:GetAttributeChangedSignal("HangarEdited"):Once(function() wiggle:Cancel(); customize.Rotation = 1 end)
	end

	-- Down the left: your five builds as small taped photos with their names; the picked one has the yellow crayon outline.
	local preset, presets, shownPresets, picked = Players.LocalPlayer:GetAttribute("SelectedPreset") or 1, nil, nil, -9
	local outline = image(left, "Picked", Shelf.outline, 0, 0, 214, 150)
	outline.ScaleType, outline.SliceCenter, outline.SliceScale, outline.ZIndex = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 0.4, 3
	local slots = {}
	for i = 1, 5 do
		local y = 272 + (i - 1) * 146
		local mini = image(left, "BuildPhoto" .. i, Art.preview, 12, y, 190, 112, i % 2 == 0 and 2 or -2)
		mini.ScaleType, mini.ImageColor3 = Enum.ScaleType.Stretch, SKY_BLUE
		local view = viewport(left, "BuildPlane" .. i, 26, y + 14, 162, 80)
		image(left, "BuildTape" .. i, Assets.ingame.tapeLabel, 17, y + 90, 180, 44).ScaleType = Enum.ScaleType.Stretch
		local tag = words(left, "BuildName" .. i, "", 30, y + 92, 154, 40, 26)
		tag.TextXAlignment, tag.TextScaled = Enum.TextXAlignment.Center, true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = 26, tag
		local hit = Instance.new("TextButton")
		hit.Name, hit.Text, hit.BackgroundTransparency, hit.ZIndex = "Pick" .. i, "", 1, 4
		hit.Position, hit.Size, hit.Parent = UDim2.fromOffset(4, y - 4), UDim2.fromOffset(206, 142), left
		hit.Activated:Connect(function()
			preset = i; api.round:FireServer("selectPreset", i); picked = os.clock()
		end)
		slots[i] = { y = y, view = view, tag = tag, hit = hit }
	end
	PaperUI.popIn(cover, { buttons.Refill, buttons.Repair, buttons.Fresh, buttons.Refold, customize, launch })
	Players.LocalPlayer:GetAttributeChangedSignal("SelectedPreset"):Connect(function()
		preset = Players.LocalPlayer:GetAttribute("SelectedPreset") or 1
	end)

	local function showPresets(list)
		presets = list
		local key = HttpService:JSONEncode(presets)
		if key == shownPresets then return end
		shownPresets = key
		for i, slot in slots do
			local build = presets[i]
			slot.tag.Text = build and build.name or ("Build " .. i)
			if build and build.loadout then showBuild(slot.view, build.loadout, 0.85) else slot.view:ClearAllChildren() end
		end
	end
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if profile and profile.presets then showPresets(profile.presets) end
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
			Boost = boost, BoostMax = boost }
		return loadout, { GetAttribute = function(_, key) return values[key] end }
	end

	-- The live plane: a copy of what your plane looks like now, rebuilt when its parts change.
	local shownPlane
	local function showPlane(plane)
		local loadout = pickedBuild(plane)
		if loadout then
			local key = HttpService:JSONEncode(loadout)
			if shownPlane == key then return end
			shownPlane = key
			showBuild(planeView, loadout, 0.75)
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
		frame(planeView, model, 0.75)
	end

	local self = {}
	local lastMessage, messageAt = nil, -9 -- service results ("Service complete", "You need 120 Paper") show for 4 s
	-- Called by the HUD every 0.1 s: shown while the plane is in its hangar.
	function self.update(plane, visible)
		cover.Visible = visible
		if not visible then shownPlane = nil; return end
		showPlane(plane)
		local loadout, pickedStats = pickedBuild(plane)
		local build = presets and presets[preset]
		name.Text = build and build.name or ""
		notYet.Text = loadout and "Not flying yet" or ""
		outline.Position = UDim2.fromOffset(107, slots[preset] and slots[preset].y + 58 or -999)
		for _, row in rows do
			local value, max = row[3](pickedStats or plane)
			local cells = math.max(row.least or 0, max > 0 and math.ceil(math.clamp(value / max, 0, 1) * 5) or 0)
			for k = 1, 5 do row.cells[k].Image = k <= cells and Shelf.statBox or Shelf.statBoxEmpty end
		end
		local remaining = plane:GetAttribute("ProtectionRemaining") or 120
		local repair = Rules.repair(plane:GetAttribute("OriginalHealth"), plane:GetAttribute("MaxHealth"), plane:GetAttribute("Health"))
		local message = plane:GetAttribute("Message")
		if message ~= lastMessage then lastMessage, messageAt = message, os.clock() end
		note.Text = (plane:GetAttribute("ServiceBusy") or os.clock() - messageAt < 4) and message and message ~= "" and message
			or os.clock() - picked < 4 and string.format("%s picked: Full refold flies it, Customize changes it.", build and build.name or "Build")
			or remaining <= 0 and "Hangar safety used up: back after 2 minutes out, or with a kill."
			or string.format("Safe in the hangar: %.0fs. Repair leaves %.0f max health. A fresh plane ends your streak.", remaining, repair and repair.lifeMaxHealth or 0)
		note.TextColor3 = remaining <= 10 and Color3.fromRGB(200, 40, 30) or remaining <= 30 and Color3.fromRGB(200, 110, 20) or PaperUI.INK
	end
	self.sheet = cover
	return self
end

return DeskHangar
