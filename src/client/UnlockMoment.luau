-- The unlock moment (docs/plan/UNLOCK-PLAN.md, Alan 2026-11-11). Leveling up in a match shows a small taped note with
-- confetti ("open Menu to see them"); opening the Menu with unlocks waiting plays the backpack: drag its zipper (right
-- to left), the things you unlocked pop out, each turning in 3D with Put it on / See it and Later. What's been opened
-- is saved (profile.unlocksSeen, schema 8), so unopened unlocks pile up until the Menu is opened.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local Art = Assets.unlock
local Economy = require(Root.Shared.EconomyRules)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Aircraft = require(Root.Shared.Aircraft)
local PaperUI = require(script.Parent.PaperUI)
local ScreenFit = require(script.Parent.ScreenFit)
local Audio = require(script.Parent.Audio)
local Unlock = {}

local INK = PaperUI.INK
local MID, ROW_Y = 985, 532 -- the card's middle across (the page's writing area); its arrows-and-dots row
-- "Bag Zipper From Nylon Bag Backpack Luggage 5" (Pro Sound Effects, Roblox library): one unbroken zip from 1.0 s to
-- 2.3 s (measured), long enough to play straight through as you pull (Alan 2026-11-11: a looped zip sounded like a car starting).
local ZIP_SOUND, ZIP_FROM, ZIP_LONG = "rbxassetid://9113260940", 1.0, 1.3
local ZIP_PER_PULL = 2 -- seconds of zip sound a whole pull along the zipper is worth
local NOTE_SECONDS, HINT_AFTER, HINT_UP_TO = 4, 2, 4 -- level-up note on screen; drag hint after idle seconds, while seen <= this level
local FRAMES = 12 -- in-between zipper pictures (tools/art/unlock_pieces.py)
local FRAME_BOX = { 0.0336, 0.1508, 0.9444, 0.4535 } -- where they sit on the bag (shares of the bag picture)
-- The pull's path from the closed pull (right) to the open pull (left), as shares of the bag picture.
local PATH = { {0.8452, 0.3731}, {0.8244, 0.3444}, {0.8049, 0.3138}, {0.7796, 0.2866}, {0.7493, 0.2634}, {0.7148, 0.2454},
	{0.6772, 0.2331}, {0.6390, 0.2238}, {0.6004, 0.2180}, {0.5620, 0.2144}, {0.5237, 0.2118}, {0.4854, 0.2119}, {0.4467, 0.2125},
	{0.4077, 0.2152}, {0.3680, 0.2194}, {0.3279, 0.2265}, {0.2877, 0.2366}, {0.2495, 0.2521}, {0.2136, 0.2720}, {0.1821, 0.2971},
	{0.1559, 0.3265}, {0.1351, 0.3589}, {0.1194, 0.3932}, {0.1082, 0.4284}, {0.1000, 0.4637} }

function Unlock.levelOf(profile)
	return (Economy.levelForXP(math.max(0, math.floor((profile and profile.xp or 0) * 1000)))) or 1
end

-- Everything unlocked above level `from` up to `to`: free things first (the presets too), then by level and price.
function Unlock.items(from, to)
	local list = {}
	local function add(part, kind)
		if part.min_level > from and part.min_level <= to then
			table.insert(list, { part = part, kind = kind, free = kind == "class" or part.paper_price == 0 })
		end
	end
	for _, w in Catalog.weapons do add(w, "weapons") end
	for _, u in Catalog.utilities do add(u, "boost") end
	for slot, parts in Catalog.structuresBySlot do for _, s in parts do add(s, slot) end end
	for _, c in Catalog:classes() do add(c, "class") end
	table.sort(list, function(a, b)
		if a.free ~= b.free then return a.free end
		if a.part.min_level ~= b.part.min_level then return a.part.min_level < b.part.min_level end
		if (a.part.paper_price or 0) ~= (b.part.paper_price or 0) then return (a.part.paper_price or 0) < (b.part.paper_price or 0) end
		return a.part.name < b.part.name
	end)
	return list
end

-- The unlocked thing in 3D: the whole plane for a preset, otherwise the plane's pieces of that one part.
local KEEP = { body = "body", nose = "nose", wings = "wings", tail = "tail", weapons = "Mount1", boost = "Booster" }
local function view(parent, item, x, y, w, h)
	local frame = Instance.new("ViewportFrame")
	frame.Name, frame.BackgroundTransparency, frame.Size = "Item", 1, UDim2.fromOffset(w, h)
	frame.AnchorPoint, frame.Position = Vector2.new(0.5, 0.5), UDim2.fromOffset(x + w / 2, y + h / 2)
	frame.Ambient, frame.LightColor, frame.LightDirection = Color3.fromRGB(140, 140, 150), Color3.fromRGB(255, 250, 235), Vector3.new(-0.6, -1, -0.4)
	frame.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = frame
	local model = Instance.new("Model")
	model.Parent = world
	local loadout
	if item.kind == "class" then
		loadout = Catalog:classLoadout(item.part.id, item.part.min_level)
	else
		loadout = Catalog:starterLoadout()
		if item.kind == "weapons" then loadout.weapon_mounts = { item.part.id }
		elseif item.kind == "boost" then loadout.utility = item.part.id
		else loadout[item.kind] = item.part.id end
	end
	Aircraft.build(model, loadout, Catalog, true)
	local look = model:FindFirstChild("Appearance") or model
	local keep = KEEP[item.kind]
	if keep then
		for _, piece in look:GetChildren() do
			if piece.Name ~= keep and piece.Name:sub(1, #keep + 1) ~= keep .. "-" then piece:Destroy() end
		end
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, frame.CurrentCamera = 40, frame, camera
	-- Close enough that it fills most of its box as it turns: its widest turn across 85% of the width, its height 85% of
	-- the height, measured from its near side.
	local center, size = look:GetBoundingBox()
	local across, tan = math.max(size.X, size.Z), math.tan(math.rad(20))
	local distance = math.max(across / 2 / (tan * w / h * 0.85), size.Y / 2 / (tan * 0.85)) + across / 2
	local function turn(angle)
		camera.CFrame = CFrame.new(center.Position) * CFrame.Angles(0, angle, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, distance)
	end
	turn(0.6)
	return frame, turn
end

function Unlock.start(api)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local image, words = PaperUI.image, PaperUI.words

	-- ===== The backpack (over the Menu) =====
	local cover, sheet = PaperUI.screen(playerGui, "UnlockMoment", {})
	-- Over the menus and the tutorial's questions (20), under the loading screen (100); the menu underneath can't be clicked.
	cover.Parent.DisplayOrder, cover.BackgroundTransparency, cover.Active = 25, 0.55, true
	-- Ink strokes (Path2D) don't follow a UIScale: their points are shares of their parent's box (w x h units) and
	-- their thickness follows the sheet's scale.
	local function ink(parent, points, thickness, w, h)
		local path = Instance.new("Path2D")
		path.Color3, path.ZIndex, path.Parent = INK, 6, parent
		local controls = {}
		for _, pt in points do
			local tangent = UDim2.fromScale((pt[3] or 0) / w, 0)
			table.insert(controls, Path2DControlPoint.new(UDim2.fromScale(pt[1] / w, pt[2] / h), UDim2.new() - tangent, tangent))
		end
		path:SetControlPoints(controls)
		local function thick() path.Thickness = thickness * sheet.UIScale.Scale end
		sheet.UIScale:GetPropertyChangedSignal("Scale"):Connect(thick); thick()
		return path
	end
	local group = Instance.new("Frame") -- the paper and everything on it (shakes while you drag)
	group.Name, group.BackgroundTransparency, group.Size, group.Parent = "Paper", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet
	local paper = image(group, "Sheet", Art.sheet, 585, 30, 750, 1020)
	local tape = image(group, "Tape", Art.tape, 610, 52, 700, 193, -2)
	local title = PaperUI.loud(words(group, "Title", "", 616, 92, 700, 120, 118))
	title.TextXAlignment, title.Rotation = Enum.TextXAlignment.Center, -2
	PaperUI.fitWords(title, 540)
	local tapes = image(group, "CornerTapes", Art.sheetTapes, 585, 30, 750, 153) -- hold the strip down (Alan 2026-11-11)
	paper.ZIndex, tape.ZIndex, title.ZIndex, tapes.ZIndex = 1, 2, 3, 4

	-- The backpack sits on the screen's bottom edge on any screen (its bottom never shows): its own frame, scaled like the sheet.
	local bottom = Instance.new("Frame")
	bottom.Name, bottom.BackgroundTransparency, bottom.AnchorPoint = "Bottom", 1, Vector2.new(0.5, 1)
	bottom.Position, bottom.Size, bottom.Parent = UDim2.fromScale(0.5, 1), UDim2.fromOffset(PaperUI.W, 700), cover
	local bottomScale = Instance.new("UIScale")
	bottomScale.Parent = bottom
	local function rescale() bottomScale.Scale = sheet.UIScale.Scale end
	sheet.UIScale:GetPropertyChangedSignal("Scale"):Connect(rescale); rescale()
	local BAG_X, BAG_Y = 626, 281
	local bag = image(bottom, "Bag", Art.bagClosed, BAG_X, BAG_Y, 667, 634)
	bag.ScaleType = Enum.ScaleType.Stretch -- drawn 1.2x wider than the picture (Alan: bigger and wider)
	local function overlay(name, id)
		local o = Instance.new("ImageLabel")
		o.Name, o.BackgroundTransparency, o.Image = name, 1, id or ""
		o.Position, o.Size = UDim2.fromScale(FRAME_BOX[1], FRAME_BOX[2]), UDim2.fromScale(FRAME_BOX[3], FRAME_BOX[4])
		o.ImageRectSize, o.Visible, o.Parent = Vector2.new(512, 280), false, bag
		return o
	end
	local frameA, frameB = overlay("FrameA"), overlay("FrameB")
	local opened = Instance.new("ImageLabel") -- the open bag, faded in over the last step
	opened.Name, opened.BackgroundTransparency, opened.Image, opened.Size = "Open", 1, Art.bagOpen, UDim2.fromScale(1, 1)
	opened.Visible, opened.ZIndex, opened.Parent = false, 3, bag
	frameA.ZIndex, frameB.ZIndex = 1, 2
	local pull = Instance.new("ImageLabel")
	pull.Name, pull.BackgroundTransparency, pull.Image, pull.AnchorPoint = "Pull", 1, Art.pull, Vector2.new(0.42, 0.12)
	pull.Size, pull.Visible, pull.ZIndex, pull.Parent = UDim2.fromOffset(92, 124), false, 4, bag
	local skip -- set below

	-- "Drag to unzip" with an ink arrow along the zipper (right to left), after a moment idle, the first few times.
	local hint = Instance.new("Frame")
	hint.Name, hint.BackgroundTransparency, hint.Size, hint.Visible, hint.Parent = "Hint", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), false, group
	PaperUI.loud(words(hint, "Words", "Drag to unzip", 630, 432, 660, 76, 64)).TextXAlignment = Enum.TextXAlignment.Center
	ink(hint, { { 1150, 560 }, { 960, 522, -110 }, { 785, 552 } }, 9, PaperUI.W, PaperUI.H)
	ink(hint, { { 812, 528 }, { 772, 556 }, { 814, 578 } }, 9, PaperUI.W, PaperUI.H)

	-- The card for each unlocked thing.
	local card = Instance.new("Frame")
	card.Name, card.BackgroundTransparency, card.Size, card.Visible, card.Parent = "Card", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), false, group
	card.ZIndex = 5
	local dots = Instance.new("Frame")
	dots.Name, dots.BackgroundTransparency, dots.Size, dots.Parent = "Dots", 1, UDim2.fromOffset(PaperUI.W, 30), card
	-- Everything on the card is centred on the page's writing area (MID: between its red margin line and its right
	-- edge), clear of the binder holes (Alan 2026-11-11).
	local you = PaperUI.loud(words(card, "YouUnlocked", "You unlocked", MID - 300, 560, 600, 54, 44))
	local name = PaperUI.loud(words(card, "Name", "", MID - 300, 606, 600, 96, 88))
	local desc = words(card, "Description", "", MID - 280, 712, 560, 108, 32)
	local status = words(card, "Status", "", MID - 300, 824, 600, 46, 34)
	local counter = PaperUI.loud(words(card, "Counter", "", MID - 90, ROW_Y - 24, 180, 48, 34)) -- "3 of 18" when dots won't fit
	counter.TextXAlignment = Enum.TextXAlignment.Center
	for _, label in { you, name, desc, status } do label.TextXAlignment = Enum.TextXAlignment.Center end
	PaperUI.fitWords(name, 560); PaperUI.fitWords(status, 560)
	desc.TextScaled, desc.TextWrapped = true, true
	local most = Instance.new("UITextSizeConstraint")
	most.MaxTextSize, most.Parent = 32, desc
	PaperUI.onPhone(function(phone) most.MaxTextSize = phone and 40 or 32 end)
	PaperUI.phone(you, { TextSize = 52 }); PaperUI.phone(status, { TextSize = 42 })

	-- ===== State =====
	local items, index, level, stage = {}, 1, 1, nil -- stage: nil (closed), "zip", "pop", "card"
	local p, dragging, lastMove, idle, offered = 0, false, 0, 0, false
	local seenLocal, testing = 0, false -- the level opened this session (until the server's word comes back); a Studio test
	local turnMain, mainView, sideViews, spin = nil, nil, {}, 0
	local blur

	local function pathAt(t)
		local x = math.clamp(t, 0, 1) * (#PATH - 1)
		local i = math.min(math.floor(x) + 1, #PATH - 1)
		local f, a, b = x - (i - 1), PATH[i], PATH[i + 1]
		return Vector2.new(a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f)
	end
	local function setFrame(o, k)
		o.Image = k <= 6 and Art.unzip1 or Art.unzip2
		local n = (k - 1) % 6
		o.ImageRectOffset = Vector2.new((n % 2) * 512, math.floor(n / 2) * 280)
	end
	-- Draws the bag at progress p (0 shut, 1 open): the in-between pictures cross-fade so the gap grows smoothly.
	local function drawZip()
		local x = p * (FRAMES + 1)
		local k0, t = math.floor(x), x - math.floor(x)
		frameA.Visible = k0 >= 1 and k0 <= FRAMES
		if frameA.Visible then setFrame(frameA, k0) end
		frameB.Visible = k0 + 1 <= FRAMES and t > 0
		if frameB.Visible then setFrame(frameB, k0 + 1); frameB.ImageTransparency = 1 - t end
		opened.Visible = k0 >= FRAMES
		opened.ImageTransparency = k0 >= FRAMES + 1 and 0 or 1 - t
		local at = pathAt(p)
		pull.Position, pull.Visible = UDim2.fromScale(at.X, at.Y), p > 0 and p < 1
	end

	-- The zipper's sound: one long zip at its own pitch. Moving the pull, either way, earns zip sound for the distance
	-- moved (Alan 2026-11-11: stop and it pauses, carry on and it carries on, back and forth zips too); stopped, it
	-- pauses where it is. At the zip's end it starts the zip again; it plays out as the bag pops open.
	local zipSound = Instance.new("Sound")
	zipSound.Name, zipSound.SoundId, zipSound.Looped, zipSound.Volume = "Zipper", ZIP_SOUND, false, 0
	local zipBudget = 0 -- seconds of zip the pull has earned and not yet played
	zipSound.Parent = game:GetService("SoundService")
	task.spawn(function() game:GetService("ContentProvider"):PreloadAsync({ zipSound }) end)
	local haptic = Instance.new("HapticEffect")
	haptic.Type, haptic.Parent = Enum.HapticEffectType.UIClick, cover.Parent
	local function buzz() pcall(function() haptic:Play() end) end

	local function showCard()
		local item = items[index]
		if not item then return end
		if mainView then mainView:Destroy() end
		for _, v in sideViews do v:Destroy() end
		sideViews = {}
		mainView, turnMain = view(card, item, MID - 260, 250, 520, 262)
		mainView.ZIndex = 6
		-- Its neighbours peek past the paper's edges (the concept's frame 7; Alan: fine with the background this dark).
		for side, k in { [-1] = index - 1, [1] = index + 1 } do
			local other = items[k]
			if other then
				local v, turn = view(card, other, side < 0 and 250 or 1370, 290, 300, 190)
				v.ImageTransparency = 0.35; turn(0.6 + side * 0.4)
				table.insert(sideViews, v)
			end
		end
		name.Text, desc.Text = item.part.name, item.part.description or ""
		status.Text = item.free and "Now in your Hangar" or "Now available for purchase in the Hangar"
		card.Action.Label.Text = item.free and "Put it on" or "See it"
		card.Back.Visible, card.Next.Visible = #items > 1, #items > 1
		dots:ClearAllChildren()
		counter.Text = #items > 8 and (index .. " of " .. #items) or ""
		for i = 1, #items <= 8 and #items or 0 do
			local dot = Instance.new("Frame")
			dot.BorderSizePixel, dot.Size = 0, UDim2.fromOffset(16, 16)
			dot.Position = UDim2.fromOffset(MID - (#items - 1) * 12 + (i - 1) * 24 - 8, ROW_Y - 8)
			dot.BackgroundColor3 = i == index and INK or Color3.fromRGB(190, 180, 165)
			Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
			dot.Parent = dots
		end
		dots.Visible, counter.Visible = #items > 1, #items > 1
		spin = 0
	end

	local function close()
		stage, dragging = nil, false
		cover.Visible = false
		if blur then blur:Destroy(); blur = nil end
		if mainView then mainView:Destroy(); mainView = nil end
		for _, v in sideViews do v:Destroy() end
		sideViews = {}
	end

	-- The bag is open: it counts as seen, the first thing pops out turning once, then the card shows.
	local function popOut()
		if stage ~= "zip" then return end
		stage, dragging, p = "pop", false, 1
		drawZip()
		hint.Visible, skip.Visible = false, false
		if not testing and level > seenLocal then seenLocal = level; api.seen(level) end
		Audio.play("ding"); buzz()
		local item = items[index]
		if not item then close(); return end
		showCard()
		card.Visible = true
		for _, label in { you, name, desc, status, counter } do label.Visible = false end
		card.Action.Visible, card.Later.Visible, card.Back.Visible, card.Next.Visible, dots.Visible = false, false, false, false, false
		mainView.Position, mainView.Size = UDim2.fromOffset(960, 700), UDim2.fromOffset(120, 70)
		TweenService:Create(mainView, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(960, 400), Size = UDim2.fromOffset(520, 290) }):Play()
		task.delay(0.25, function() Audio.play("purchase") end)
		task.delay(1.2, function()
			if stage ~= "pop" then return end
			stage = "card"
			TweenService:Create(bag, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(BAG_X + 667 / 2, BAG_Y + 317 + 700) }):Play()
			for _, label in { you, name, desc, status, counter } do label.Visible = true end
			card.Action.Visible, card.Later.Visible, card.Back.Visible, card.Next.Visible, dots.Visible = true, true, #items > 1, #items > 1, #items > 1
		end)
	end

	-- Opens the backpack for these unlocks (a test from Studio passes its own list and doesn't save).
	local function play(list, newLevel, test)
		if stage or #list == 0 then return end
		-- Ready at the zip's start, paused (Resume later continues from here).
		zipSound.Volume = 0; zipSound:Play(); zipSound:Pause(); zipSound.TimePosition = ZIP_FROM
		zipBudget = 0
		items, index, level, stage, testing = list, 1, newLevel, "zip", test == true
		title.Text = "LEVEL " .. newLevel .. "!"
		p, dragging, idle = 0, false, 0
		bag.Image, bag.Position = Art.bagClosed, UDim2.fromOffset(BAG_X + 667 / 2, BAG_Y + 317 + 420)
		card.Visible, hint.Visible, skip.Visible = false, false, true
		drawZip()
		blur = Instance.new("BlurEffect")
		blur.Name, blur.Size, blur.Parent = "UnlockBlur", 16, Lighting
		cover.Visible = true
		-- The backpack rises from the bottom edge.
		TweenService:Create(bag, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(BAG_X + 667 / 2, BAG_Y + 317) }):Play()
	end
	Unlock.play = play

	skip = PaperUI.button(bottom, "Skip", Art.buttonCream, "Skip", 1395, 585, 150, 58, -1, function() popOut() end, 34)
	local function step(d)
		if stage ~= "card" or #items < 2 then return end
		index = (index - 1 + d) % #items + 1
		showCard()
	end
	-- Back and next: ink chevrons drawn on the page either side of the dots (Alan 2026-11-11: paper tags over the
	-- binder holes looked bad).
	local function chevron(name, x, dir)
		local b = Instance.new("TextButton")
		b.Name, b.Text, b.BackgroundTransparency, b.AutoButtonColor = name, "", 1, false
		b.AnchorPoint, b.Position, b.Size, b.ZIndex, b.Parent = Vector2.new(0.5, 0.5), UDim2.fromOffset(x, ROW_Y), UDim2.fromOffset(70, 70), 6, card
		ink(b, { { 35 - 10 * dir, 14 }, { 35 + 12 * dir, 35 }, { 35 - 10 * dir, 56 } }, 10, 70, 70)
		local grow = Instance.new("UIScale")
		grow.Parent = b
		b.MouseEnter:Connect(function() grow.Scale = 1.15 end)
		b.MouseLeave:Connect(function() grow.Scale = 1 end)
		local hit = PaperUI.tapArea(b)
		for _, target in { b, hit } do target.Activated:Connect(function() step(dir) end) end
		return b
	end
	chevron("Back", MID - 150, -1)
	chevron("Next", MID + 150, 1)
	PaperUI.button(card, "Action", Assets.hangar.buttonGreen, "Put it on", MID - 268, 885, 240, 76, -1, function()
		local item = items[index]
		close()
		if item then api.open(item.kind ~= "class" and item.kind or nil) end
	end, 42)
	PaperUI.button(card, "Later", Art.buttonCream, "Later", MID + 28, 885, 240, 76, -1, function()
		table.remove(items, index)
		if #items == 0 then close(); return end
		index = math.min(index, #items)
		showCard()
	end, 42)

	-- Dragging the zipper: grab near the pull, and it follows your finger along the zipper's path.
	local function screenPoint(input)
		if input.UserInputType == Enum.UserInputType.Touch then return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset() end
		return Input:GetMouseLocation()
	end
	local function nearest(point)
		local origin, size = bag.AbsolutePosition, bag.AbsoluteSize
		local best, bestDistance = p, math.huge
		for i = 1, #PATH - 1 do
			local a = origin + size * Vector2.new(PATH[i][1], PATH[i][2])
			local b = origin + size * Vector2.new(PATH[i + 1][1], PATH[i + 1][2])
			local ab = b - a
			local t = math.clamp((point - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
			local distance = (a + ab * t - point).Magnitude
			if distance < bestDistance then best, bestDistance = (i - 1 + t) / (#PATH - 1), distance end
		end
		return best
	end
	local swipeFrom
	Input.InputBegan:Connect(function(input)
		local press = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		if not press or not cover.Visible then return end
		local point = screenPoint(input)
		if stage == "zip" then
			local at = bag.AbsolutePosition + bag.AbsoluteSize * pathAt(p)
			if (point - at).Magnitude < math.max(150 * bottomScale.Scale, 50) then dragging, idle = true, 0 end
		elseif stage == "card" then
			swipeFrom = point
		end
	end)
	Input.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local q = nearest(screenPoint(input))
		if math.abs(q - p) < 0.3 then
			local before = math.floor(p * (FRAMES + 1))
			zipBudget = math.min(zipBudget + math.abs(q - p) * ZIP_PER_PULL, 0.3)
			p, lastMove = q, os.clock()
			if math.floor(p * (FRAMES + 1)) ~= before then buzz() end
			drawZip()
			if p >= 0.96 then popOut() end
		end
	end)
	Input.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = false
		if swipeFrom and stage == "card" then
			local dx = screenPoint(input).X - swipeFrom.X
			if math.abs(dx) > 80 * sheet.UIScale.Scale then step(dx < 0 and 1 or -1) end
		end
		swipeFrom = nil
	end)
	Input.InputBegan:Connect(function(input, processed)
		if processed or stage ~= "card" then return end
		if input.KeyCode == Enum.KeyCode.Left then step(-1) elseif input.KeyCode == Enum.KeyCode.Right then step(1) end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not stage then return end
		-- A small shake while the zipper moves; the hint after a moment idle, for your first few backpacks.
		local shaking = dragging and os.clock() - lastMove < 0.1
		group.Position = shaking and UDim2.fromOffset(math.random(-3, 3), math.random(-3, 3)) or UDim2.new()
		bottom.Position = shaking and UDim2.new(0.5, math.random(-3, 3), 1, math.random(-3, 3)) or UDim2.fromScale(0.5, 1)
		if stage == "zip" then
			if zipSound.IsPlaying then zipBudget -= dt end
			if dragging and zipBudget > 0.05 and not zipSound.IsPlaying then
				if zipSound.TimePosition >= ZIP_FROM + ZIP_LONG - 0.05 then zipSound.TimePosition = ZIP_FROM end
				zipSound.Volume = 0.6 * (Root:GetAttribute("SoundVolume") or 1)
				zipSound:Resume()
			elseif zipSound.IsPlaying and (zipBudget <= 0 or not dragging) then
				zipSound:Pause()
			elseif zipSound.IsPlaying and zipSound.TimePosition >= ZIP_FROM + ZIP_LONG then
				zipSound:Pause(); zipSound.TimePosition = ZIP_FROM; zipSound:Resume() -- the zip again
			end
		elseif zipSound.TimePosition < ZIP_FROM + ZIP_LONG - 0.05 and zipSound.TimePosition > ZIP_FROM then
			if not zipSound.IsPlaying then zipSound:Resume() end -- the bag is open: the zip plays out
		elseif zipSound.IsPlaying then
			zipSound:Stop()
		end
		if stage == "zip" then
			idle += dt
			hint.Visible = not dragging and p == 0 and idle > HINT_AFTER and api.seenLevel() <= HINT_UP_TO
		end
		-- The item turns all the way round as it pops out, then keeps turning slowly.
		if turnMain then
			spin += dt
			local angle = stage == "pop" and 0.6 + math.pi * 2 * math.min(spin / 1.2, 1) ^ 0.7 or 0.6 + (spin - 1.2) * 0.6
			turnMain(angle)
		end
	end)

	-- ===== The level-up note (in a match) =====
	local noteGui = Instance.new("ScreenGui")
	noteGui.Name, noteGui.IgnoreGuiInset, noteGui.ResetOnSpawn, noteGui.DisplayOrder, noteGui.Enabled = "LevelUpNote", true, false, 7, false
	noteGui.Parent = playerGui
	local note = Instance.new("CanvasGroup") -- clips the unfold
	note.Name, note.BackgroundTransparency, note.AnchorPoint, note.Size = "Note", 1, Vector2.new(0.5, 0), UDim2.fromOffset(640, 270)
	note.Parent = noteGui
	local noteScale = Instance.new("UIScale")
	noteScale.Parent = note
	ScreenFit.inColumn(note, 4.5, true)
	local inner = Instance.new("Frame")
	inner.Name, inner.BackgroundTransparency, inner.Size, inner.Parent = "Inner", 1, UDim2.fromOffset(640, 270), note
	local cardImage = image(inner, "Card", Assets.ingame.indexCard, 10, 8, 620, 254, 1)
	local noteTape = image(inner, "Tape", Art.tape, 60, 18, 300, 83, -3)
	local noteTitle = PaperUI.loud(words(inner, "Title", "", 70, 28, 280, 60, 54))
	noteTitle.TextXAlignment, noteTitle.Rotation = Enum.TextXAlignment.Center, -3
	PaperUI.fitWords(noteTitle, 250)
	local bits = { image(inner, "Bit1", Assets.ingame.tapeLabel, 40, 14, 80, 22, 35), image(inner, "Bit2", Assets.ingame.tapeLabel, 318, 8, 80, 22, -30) }
	local line1 = PaperUI.loud(words(inner, "Line1", "", 30, 128, 580, 56, 42))
	local line2 = words(inner, "Line2", "", 30, 186, 580, 48, 34)
	line1.TextXAlignment, line2.TextXAlignment = Enum.TextXAlignment.Center, Enum.TextXAlignment.Center
	PaperUI.fitWords(line1, 570); PaperUI.fitWords(line2, 570)
	cardImage.ZIndex, noteTape.ZIndex, noteTitle.ZIndex, bits[1].ZIndex, bits[2].ZIndex = 1, 2, 3, 4, 4
	local confetti = Instance.new("Frame")
	confetti.Name, confetti.BackgroundTransparency, confetti.Size, confetti.Parent = "Confetti", 1, UDim2.fromScale(1, 1), noteGui
	local COLOURS = { Color3.fromRGB(230, 60, 50), Color3.fromRGB(40, 110, 220), Color3.fromRGB(250, 200, 30), Color3.fromRGB(60, 170, 70), Color3.fromRGB(240, 130, 30), Color3.fromRGB(170, 80, 200) }
	local noteUntil, noteHeight = 0, 270

	local function burst()
		local centre = note.AbsolutePosition + note.AbsoluteSize / 2 - noteGui.AbsolutePosition
		local s = noteScale.Scale
		for _ = 1, 40 do
			local bit = Instance.new("Frame")
			bit.BorderSizePixel, bit.BackgroundColor3 = 0, COLOURS[math.random(#COLOURS)]
			bit.AnchorPoint, bit.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(math.random(8, 16) * s, math.random(5, 9) * s)
			bit.Position, bit.Rotation, bit.Parent = UDim2.fromOffset(centre.X, centre.Y), math.random(0, 180), confetti
			local away = Vector2.new(math.random(-420, 420), math.random(-150, 220)) * s
			TweenService:Create(bit, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(centre.X + away.X, centre.Y + away.Y), Rotation = bit.Rotation + math.random(-360, 360),
				BackgroundTransparency = 1 }):Play()
			task.delay(1.5, function() bit:Destroy() end)
		end
	end

	local function levelNote(newLevel, unlocked)
		noteTitle.Text = "LEVEL " .. newLevel .. "!"
		local any = #unlocked > 0
		cardImage.Visible, line1.Visible, line2.Visible, bits[1].Visible, bits[2].Visible = any, any, any, any, any
		line1.Text = #unlocked == 1 and "You unlocked something new!" or ("You unlocked " .. #unlocked .. " new things!")
		line2.Text = #unlocked == 1 and "Open Menu to see it." or "Open Menu to see them."
		noteHeight = any and 270 or 110
		noteUntil = os.clock() + NOTE_SECONDS
		note.Size, note.GroupTransparency = UDim2.fromOffset(640, 0), 0
		noteGui.Enabled = true
		TweenService:Create(note, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(640, noteHeight) }):Play()
		task.delay(0.15, burst)
		Audio.play("ding")
	end
	Unlock.levelNote = levelNote

	RunService.RenderStepped:Connect(function()
		if not noteGui.Enabled then return end
		if os.clock() > noteUntil then
			if note.GroupTransparency == 0 then
				TweenService:Create(note, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
				task.delay(0.35, function() if os.clock() > noteUntil then noteGui.Enabled = false end end)
			end
			return
		end
		local s = ScreenFit.scale(ScreenFit.NOTE) * (ScreenFit.kind() == "phone" and 0.85 or 1)
		local x, y, fit = ScreenFit.place(note, s)
		note.Position, noteScale.Scale = UDim2.new(0.5, x, 0, y), s * fit
	end)

	-- A level-up while playing shows the note (the backpack waits for the Menu).
	local lastLevel
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if type(profile) ~= "table" then return end
		local now = Unlock.levelOf(profile)
		if lastLevel and now > lastLevel and player:GetAttribute("InMatch") then levelNote(now, Unlock.items(lastLevel, now)) end
		lastLevel = now
	end)

	-- What's waiting to be opened: things above the level already opened, up to yours.
	function Unlock.waiting(profile)
		if type(profile) ~= "table" or type(profile.unlocksSeen) ~= "number" then return {} end
		if profile.unlocksSeen >= seenLocal then seenLocal = 0 end -- the server has caught up (or a prestige started over)
		return Unlock.items(math.max(profile.unlocksSeen, seenLocal), Unlock.levelOf(profile))
	end
	-- The Menu opened: plays the backpack if anything is waiting.
	function Unlock.offer(profile)
		if stage then return end
		local list = Unlock.waiting(profile)
		if #list > 0 then play(list, Unlock.levelOf(profile)) end
	end
	function Unlock.playing() return stage ~= nil end

	-- Studio tests: DevUnlock = a level opens a backpack with everything up to it (not saved); DevLevelNote = a level
	-- shows that level's note.
	if RunService:IsStudio() then
		Root:GetAttributeChangedSignal("DevUnlock"):Connect(function()
			local n = Root:GetAttribute("DevUnlock")
			if type(n) == "number" then close(); play(Unlock.items(1, n), n, true) end
		end)
		Root:GetAttributeChangedSignal("DevLevelNote"):Connect(function()
			local n = Root:GetAttribute("DevLevelNote")
			if type(n) == "number" then levelNote(n, Unlock.items(n - 1, n)) end
		end)
	end
end

return Unlock
