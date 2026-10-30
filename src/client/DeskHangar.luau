-- In-game desk quick menu, shown while your plane sits in its desk hangar (Alan's pick 2026-10-22: concept
-- assets/references/ui-concepts/desk-quick-menu-b.png). Pieces pinned round the screen edges with the new Hangar's
-- art, so the runway, the match strip (top middle) and the kill feed (top right) stay in view: top left the plane's
-- photo, name tape and a short stat sheet; down the left your five builds as small photos; down the right the
-- service strips and Customize; bottom middle the hangar note and LAUNCH!.
-- Picking a build selects it and shows it on the photo; Full refold (or a fresh plane) flies it. Customize opens the
-- full Hangar's binder on it: builds only change at the desk (Alan 2026-10-17).
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local Rules = require(Root.Shared.ServiceRules)
local Builder = require(Root.Shared.BuilderModel)
local Assets = require(Root.Shared.UIAssets)
local Shelf, Desk = Assets.hangarShelf, Assets.deskMenu
local Hangar = require(script.Parent.Hangar)
local BuildStats = {}
for _, entry in Hangar.STATS do BuildStats[entry[1]] = entry end
local PaperUI = require(script.Parent.PaperUI)
local ScreenFit = require(script.Parent.ScreenFit)
local DeskHangar = {}


-- A camera framing a model in a ViewportFrame like the Hangar's cubbies: from above and behind, nose away and a
-- little to the side. room: camera distance as a share of "whole model just fits" (smaller = bigger plane).
-- tilt: the photo's turn in degrees; the camera rolls with it (a ViewportFrame itself can't turn).
local function frame(view, model, room, tilt)
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, view.CurrentCamera = 40, view, camera
	local box, size = model:GetBoundingBox()
	local distance = math.max(size.X, size.Z) / 2 * 1.1 / math.sin(math.rad(20)) * room
	camera.CFrame = CFrame.new(box.Position) * CFrame.Angles(0, 0.5, 0) * CFrame.Angles(-0.6, 0, 0) * CFrame.new(0, 0, distance)
		* CFrame.Angles(0, 0, math.rad(tilt))
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
local function showBuild(view, loadout, room, tilt)
	view:ClearAllChildren()
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = Instance.new("Model")
	model.Parent = world
	if Aircraft.build(model, loadout, Catalog, true) then frame(view, model, room, tilt) end
end

-- The photo piece's sky-blue picture area, as shares of the piece (measured on assets/ui/deskmenu/ready/photo.png).
local BLUE = { 41 / 464, 50 / 384, 422 / 464, 306 / 384 }
local BIG_TILT, BUILD_TILTS = -2, { -4, 3, -2, 4, -3 }
local PHOTO_Y = 56 -- the big photo's top in the left group (which starts 8 px down, level with the match strip)

-- api = { flight(action) = FlightAction, round = RoundAction remote, feed = the kill feed's frame (FlightHUD) }
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
	local left = panel("Left", Vector2.new(0, 0), 640, 1068)
	local right = panel("Right", Vector2.new(1, 0), 490, 820)
	local bottom = panel("Bottom", Vector2.new(0.5, 1), 760, 300)
	local function fit()
		local view = workspace.CurrentCamera.ViewportSize
		local s = math.min(view.X / PaperUI.W, (view.Y - 12) / 1068)
		for _, scale in scales do scale.Scale = s end
		-- Level with the match strip, but the big photo stays under Roblox's top bar (its buttons sit there): on a
		-- phone the column shrinks a little to make room.
		local bar = GuiService.TopbarInset.Max.Y + ScreenFit.GAP
		local leftScale = math.min(s, (view.Y - 4 - bar) / (1068 - PHOTO_Y))
		left.UIScale.Scale = leftScale
		left.Position, bottom.Position = UDim2.fromOffset(16, math.max(8, bar - PHOTO_Y * leftScale)), UDim2.new(0.5, 0, 1, -12)
		-- The service strips start under the kill feed's real bottom (FlightHUD: 4 slips); they shrink
		-- if needed so Customize still fits above the bottom edge.
		local top = api.feed.AbsolutePosition.Y + api.feed.AbsoluteSize.Y - layer.AbsolutePosition.Y + ScreenFit.GAP
		right.Position = UDim2.new(1, -16, 0, top)
		right.UIScale.Scale = math.min(s, (view.Y - top - 12) / 820)
	end
	ScreenFit.watch(fit)
	api.feed:GetPropertyChangedSignal("AbsolutePosition"):Connect(fit)
	api.feed:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	-- A turned group of pieces (a photo and its tape turn together); x, y, w, h like PaperUI.image.
	local function turned(name, x, y, w, h, rotation)
		local group = Instance.new("Frame")
		group.Name, group.BackgroundTransparency, group.AnchorPoint = name, 1, Vector2.new(0.5, 0.5)
		group.Position, group.Size, group.Rotation, group.Parent = UDim2.fromOffset(x + w / 2, y + h / 2), UDim2.fromOffset(w, h), rotation, left
		return group
	end
	local function centred(label, size)
		label.TextXAlignment, label.TextScaled = Enum.TextXAlignment.Center, true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = size, label
		return label
	end

	-- Top left: the plane's taped photo (just under Roblox's own buttons and the Menu button) with its name on masking
	-- tape, and beside it, its top level with the photo's (Alan 2026-10-24, every screen), the short stat sheet.
	image(left, "Photo", Desk.photo, 0, PHOTO_Y, 300, 250, BIG_TILT).ScaleType = Enum.ScaleType.Stretch
	local planeView = viewport(left, "Plane", 300 * BLUE[1], PHOTO_Y + 250 * BLUE[2], 300 * (BLUE[3] - BLUE[1]), 250 * (BLUE[4] - BLUE[2]))
	local notYet = PaperUI.phone(words(left, "NotFlyingYet", "", 30, PHOTO_Y + 36, 240, 26, 24), { TextSize = 36 })
	notYet.TextXAlignment, notYet.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(190, 35, 30)
	local tape = turned("NameTape", 25, PHOTO_Y + 204, 250, 48, BIG_TILT)
	image(tape, "Tape", Assets.ingame.tapeLabel, 0, 0, 250, 48).ScaleType = Enum.ScaleType.Stretch
	local name = centred(words(tape, "BuildName", "", 20, 3, 210, 42, 34), 34)

	-- Health, Lift and Boost show what is left now; Speed shows the build (Alan 2026-10-22: these four, no turning
	-- or weight here; Customize has the full sheet). Rows sit clear of the paper's binder holes and edges.
	local statsPaper = image(left, "StatsSheet", Shelf.statsPaper, 296, PHOTO_Y, 324, 330, 1)
	statsPaper.ScaleType = Enum.ScaleType.Stretch
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
		local y = PHOTO_Y + 66 + (i - 1) * 56
		local strip = image(left, row[1] .. "Row", Shelf.statLabel, 345, y + 7, 100, 42)
		strip.ScaleType, strip.ImageColor3 = Enum.ScaleType.Stretch, row[2]
		local label = centred(words(left, row[1] .. "Name", row[1], 351, y + 9, 88, 38, 26), 26)
		PaperUI.phone(strip, { Size = UDim2.fromOffset(112, 48) })
		PaperUI.phone(label, { Position = UDim2.fromOffset(345, y + 7), Size = UDim2.fromOffset(100, 42) })
		PaperUI.phone(label.UITextSizeConstraint, { MaxTextSize = 36 })
		row.cells = {}
		for k = 1, 5 do
			row.cells[k] = image(left, row[1] .. "Box" .. k, Shelf.statBoxEmpty, 453 + (k - 1) * 29, y + 14, 27, 27)
			row.cells[k].ImageColor3 = row[2]
		end
	end

	-- Bottom middle: the hangar note on masking tape, and a big LAUNCH! on bright green paper (Alan 2026-10-22).
	local notePaper = image(bottom, "NotePaper", Assets.ingame.tapeLabel, 50, 0, 660, 80)
	notePaper.ScaleType = Enum.ScaleType.Stretch
	local note = centred(words(bottom, "Note", "", 90, 8, 580, 64, 28), 28)
	note.TextWrapped = true
	-- Phones: wider and taller tape (reaching up over the runway) so the note reads at about 12 points.
	PaperUI.phone(notePaper, { Position = UDim2.fromOffset(380, -10), Size = UDim2.fromOffset(820, 130) })
	PaperUI.phone(note, { Position = UDim2.fromOffset(15, -60), Size = UDim2.fromOffset(730, 100) })
	PaperUI.phone(note.UITextSizeConstraint, { MaxTextSize = 40 })
	local launch = button(bottom, "Launch", Desk.launch, "LAUNCH!", 0, 72, 760, 228, -1, function() api.flight("launch") end, 120)

	-- Down the right: the service strips, then Customize (the Hangar's orange). Alan 2026-10-22: big, middle, small,
	-- middle, big, so the column curves and fills the side.
	local service = function(kind) return function() api.round:FireServer("service", kind) end end
	local REFOLD = "Full refold - 120 Paper"
	local buttons = {}
	local top = 0
	for _, entry in {
		{ "Refill", "Refill Lift", Desk.stripBlue, service("refill"), 490, 160, -1.5, 52 },
		{ "Repair", "Repair", Desk.stripGreen, service("repair"), 450, 142, 1, 48 },
		{ "Fresh", "Fresh plane", Desk.stripYellow, function() api.flight("fresh") end, 410, 126, -1, 46 },
		{ "Refold", REFOLD, Desk.stripRed, function()
			-- Spending Paper asks once: the first click turns the strip into a question for 3 seconds.
			local text = buttons.Refold.Label
			if text.Text ~= "Sure? Click again" then
				text.Text = "Sure? Click again"
				task.delay(3, function() text.Text = REFOLD end)
				return
			end
			text.Text = REFOLD
			service("refold")()
		end, 450, 142, 1.5, 38 },
		{ "Customize", "Customize", Shelf.buttonOrange, function()
			Root:SetAttribute("HangarEdited", true)
			require(script.Parent.MenuController).show("hangar", true, "customize")
		end, 490, 160, -1, 62 },
	} do
		local key, label, art, click, w, h, rotation, size = table.unpack(entry)
		local strip = button(right, key, art, label, 490 - w, top, w, h, rotation, click, size)
		-- Pinned at both top corners with the kill feed's pins (Alan 2026-10-22: tape took too much attention); a pin
		-- keeps its size on every strip and when the strip grows under the mouse.
		for _, side in { 0, 1 } do
			local pin = image(strip, "Pin", art == Desk.stripRed and Assets.hud.pinBlue or Assets.hud.pinRed, 0, 0, 30, 30) -- the kill feed's size
			pin.Position = UDim2.new(side, side == 0 and 30 or -30, 0, 24)
		end
		buttons[key] = strip
		top += h + 18
	end
	local customize = buttons.Customize
	PaperUI.phone(buttons.Refold.Label, { TextSize = 44 })
	-- Customize wiggles until a new player has used it once (Alan 2026-10-17).
	if not Root:GetAttribute("HangarEdited") then
		local wiggle = TweenService:Create(customize, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = -3 })
		wiggle:Play()
		Root:GetAttributeChangedSignal("HangarEdited"):Once(function() wiggle:Cancel(); customize.Rotation = -1 end)
	end

	-- Down the left, on a strip of cork: your five builds as small taped photos with their names, each turned a little
	-- (Alan 2026-10-22: photos taped to a board); the picked one has the yellow crayon outline.
	local corkY = PHOTO_Y + 262
	local cork = image(left, "Cork", Desk.corkStrip, 0, corkY, 214, 1068 - corkY)
	cork.ScaleType, cork.ImageColor3 = Enum.ScaleType.Stretch, Color3.fromRGB(240, 225, 210)
	local preset, presets, shownPresets, picked = Players.LocalPlayer:GetAttribute("SelectedPreset") or 1, nil, nil, -9
	local slots = {}
	for i = 1, 5 do
		local y = corkY + 12 + (i - 1) * 146
		local tilt = BUILD_TILTS[i]
		local back = turned("BuildPhoto" .. i, 19, y, 176, 146, tilt)
		image(back, "Photo", Desk.photo, 0, 0, 176, 146).ScaleType = Enum.ScaleType.Stretch
		local view = viewport(left, "BuildPlane" .. i, 19 + 176 * BLUE[1], y + 146 * BLUE[2], 176 * (BLUE[3] - BLUE[1]), 146 * (BLUE[4] - BLUE[2]))
		local front = turned("BuildTag" .. i, 19, y, 176, 146, tilt)
		local tape = image(front, "Tape", Assets.ingame.tapeLabel, 5, 112, 166, 34)
		tape.ScaleType = Enum.ScaleType.Stretch
		local tag = centred(words(front, "Name", "", 18, 114, 140, 30, 24), 24)
		-- Phones: a taller tape with bigger words (they were about 8 points).
		PaperUI.phone(tape, { Position = UDim2.fromOffset(88, 122), Size = UDim2.fromOffset(176, 52) })
		PaperUI.phone(tag, { Position = UDim2.fromOffset(8, 98), Size = UDim2.fromOffset(160, 46) })
		PaperUI.phone(tag.UITextSizeConstraint, { MaxTextSize = 38 })
		local outline = image(front, "Picked", Shelf.outline, -4, -4, 184, 154)
		outline.ScaleType, outline.SliceCenter, outline.SliceScale = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 0.4
		local hit = Instance.new("TextButton")
		hit.Name, hit.Text, hit.BackgroundTransparency = "Pick", "", 1
		hit.Size, hit.Parent = UDim2.fromScale(1, 1), front
		hit.Activated:Connect(function()
			preset = i; api.round:FireServer("selectPreset", i); picked = os.clock()
		end)
		slots[i] = { view = view, tag = tag, outline = outline, tilt = tilt }
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
			if build and build.loadout then showBuild(slot.view, build.loadout, 0.85, slot.tilt) else slot.view:ClearAllChildren() end
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
	local shownPlane, shownCount
	local function showPlane(plane)
		local loadout = pickedBuild(plane)
		if loadout then
			local key = HttpService:JSONEncode(loadout)
			if shownPlane == key then return end
			shownPlane = key
			showBuild(planeView, loadout, 0.75, BIG_TILT)
			return
		end
		local appearance = plane:FindFirstChild("Appearance")
		local body = plane:FindFirstChild("Root")
		if not appearance or not body then return end
		-- Parts can arrive from the server a frame or two after the model (Alan 2026-10-24: the photo was missing a
		-- wing), so a new part count rebuilds it.
		local count = #appearance:GetChildren()
		if appearance == shownPlane and count == shownCount then return end
		shownPlane, shownCount = appearance, count
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
		frame(planeView, model, 0.75, BIG_TILT)
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
		for i, slot in slots do slot.outline.Visible = i == preset end
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
