-- The Emotes page (docs/plan/EMOTE-SHOP-PLAN.md; Alan 2026-11-24): the shop for the winners' emotes and the place you
-- put them on, in one. A box TV on its cart stands in the middle; tap a card and the TV flicks on and your own
-- character does that emote once, then it switches off. Leader emotes (1st place) hang on the left board, Runner-up
-- emotes (2nd and 3rd) on the right. Under the TV: the emote's name and its buttons (Paper and Robux, or Use).
-- The TV's glass is a real hole in this page: the emote plays in the game's own picture behind it
-- (WinnersCutscene's `tv`), so the hole has to sit exactly in the middle of the screen. That is why this page lays
-- itself out round the screen's middle instead of using PaperUI.screen's background plate.
-- The wall, boards and TV are flat paper colours until the page's picture is drawn (Alan's OK and upload first).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local Emotes = require(Root.Shared.EmoteRules)
local Aircraft = require(Root.Shared.Aircraft)
local Builder = require(Root.Shared.BuilderModel)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local PaperUI = require(script.Parent.PaperUI)
local PlaneLooks = require(script.Parent.PlaneLooks)
local Customize = require(script.Parent.HangarCustomize) -- (the skin you wear)
local Cutscene = require(script.Parent.WinnersCutscene)
local EmoteShop = {}

local W, H = PaperUI.W, PaperUI.H
local INK, WHITE = PaperUI.INK, Color3.new(1, 1, 1)
-- Sheet pixels. The glass (4:3) is centred on the sheet; the sheet is centred on the screen.
local GLASS_W, GLASS_H = 640, 480
local BEZEL = 46 -- the TV's plastic round the glass
local CARD, GAP = 196, 10 -- a card's side and the gap between cards
local WALL = Color3.fromRGB(232, 222, 200) -- the classroom wall (cream paper)
local BOARD = Color3.fromRGB(18, 62, 40) -- the two chalkboards (the shop's chalkboard green)
local TRIM = Color3.fromRGB(176, 128, 78) -- their wooden edge
local PLASTIC = Color3.fromRGB(34, 34, 38) -- the TV and its cart
local GLASS_OFF = Color3.fromRGB(16, 20, 22)
local KINDS = {
	{ kind = "leader", title = "Leader emotes", line = "Plays when you finish 1st.", x = 40, attribute = "EmoteLeader" },
	{ kind = "runner_up", title = "Runner-up emotes", line = "Plays when you finish 2nd or 3rd.", x = W - 40 - 520, attribute = "EmoteRunnerUp" },
}

local function frame(parent, name, color, x, y, w, h)
	local piece = Instance.new("Frame")
	piece.Name, piece.BackgroundColor3, piece.BorderSizePixel = name, color, 0
	piece.Position, piece.Size, piece.Parent = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h), parent
	return piece
end
local function round(piece, radius) local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(0, radius), piece; return piece end
local function centred(label) label.TextXAlignment = Enum.TextXAlignment.Center; return label end

-- api = { action (the Hangar's remote), buy(key) (a practice Robux buy), back() }
function EmoteShop.new(playerGui, api)
	local player = Players.LocalPlayer
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.IgnoreGuiInset, layer.ResetOnSpawn, layer.DisplayOrder = "EmoteShop", true, false, 10
	layer.ScreenInsets, layer.ZIndexBehavior, layer.Parent = Enum.ScreenInsets.None, Enum.ZIndexBehavior.Sibling, playerGui
	local safe = playerGui:FindFirstChild("SafeArea") -- (PaperUI's probe of the notch-free area)
	local cover = Instance.new("Frame")
	cover.Name, cover.Size, cover.BackgroundTransparency, cover.Visible, cover.Parent = "Cover", UDim2.fromScale(1, 1), 1, false, layer
	-- The wall: four pieces round the glass, so the glass itself stays a hole.
	local walls = {}
	for i = 1, 4 do
		walls[i] = frame(cover, "Wall" .. i, WALL, 0, 0, 0, 0)
		walls[i].Active = true -- nothing behind the page can be clicked
	end
	local sheet = Instance.new("Frame")
	sheet.Name, sheet.AnchorPoint, sheet.Position = "Sheet", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	sheet.Size, sheet.BackgroundTransparency, sheet.Parent = UDim2.fromOffset(W, H), 1, cover
	local scale = Instance.new("UIScale")
	scale.Parent = sheet
	local gx, gy = (W - GLASS_W) / 2, (H - GLASS_H) / 2
	local glass = frame(sheet, "Glass", GLASS_OFF, gx, gy, GLASS_W, GLASS_H)
	glass.BackgroundTransparency, glass.ClipsDescendants, glass.ZIndex = 1, true, 4
	local function fit()
		local full = layer.AbsoluteSize
		if full.X < 2 then return end
		-- Centred on the whole screen (the game's picture is), small enough to stay clear of a phone's notch on both sides.
		local room = safe and safe.AbsoluteSize.X > 2 and safe.AbsoluteSize or full
		local inset = safe and safe.AbsoluteSize.X > 2 and (safe.AbsolutePosition - layer.AbsolutePosition) or Vector2.zero
		local sideRoom = full.X - 2 * math.max(inset.X, full.X - inset.X - room.X)
		local tallRoom = full.Y - 2 * math.max(inset.Y, full.Y - inset.Y - room.Y)
		local s = math.min(sideRoom / W, tallRoom / H)
		scale.Scale = s
		local left, top = math.floor(full.X / 2 - GLASS_W / 2 * s), math.floor(full.Y / 2 - GLASS_H / 2 * s)
		local right, bottom = math.ceil(full.X / 2 + GLASS_W / 2 * s), math.ceil(full.Y / 2 + GLASS_H / 2 * s)
		walls[1].Position, walls[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(full.X, top)
		walls[2].Position, walls[2].Size = UDim2.fromOffset(0, bottom), UDim2.fromOffset(full.X, full.Y - bottom)
		walls[3].Position, walls[3].Size = UDim2.fromOffset(0, top), UDim2.fromOffset(left, bottom - top)
		walls[4].Position, walls[4].Size = UDim2.fromOffset(right, top), UDim2.fromOffset(full.X - right, bottom - top)
	end
	layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	if safe then safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit) end
	fit()

	local state = { pick = nil, owned = {}, worn = {}, profile = nil, playing = false, shown = false, token = 0 }

	-- ===== The TV on its cart (flat pieces for now) =====
	-- The cart: only its top shelf and the tops of two legs show (Alan: "The cart needs to be very subtle").
	local body = { x = gx - BEZEL, y = gy - BEZEL + 6, w = GLASS_W + 2 * BEZEL, h = GLASS_H + BEZEL + 74 }
	frame(sheet, "CartLegL", PLASTIC, body.x + 40, body.y + body.h, 22, 60)
	frame(sheet, "CartLegR", PLASTIC, body.x + body.w - 62, body.y + body.h, 22, 60)
	round(frame(sheet, "CartShelf", PLASTIC, body.x - 34, body.y + body.h - 4, body.w + 68, 26), 6)
	-- The TV's plastic: four pieces round the glass (a filled box would cover the hole).
	round(frame(sheet, "TVTop", PLASTIC, body.x, body.y, body.w, gy - body.y + 12), 26)
	frame(sheet, "TVLeft", PLASTIC, body.x, gy - 10, gx - body.x, GLASS_H + 20)
	frame(sheet, "TVRight", PLASTIC, gx + GLASS_W, gy - 10, body.x + body.w - gx - GLASS_W, GLASS_H + 20)
	round(frame(sheet, "TVBottom", PLASTIC, body.x, gy + GLASS_H - 12, body.w, body.y + body.h - gy - GLASS_H + 12), 26)
	frame(sheet, "TVBottomFlat", PLASTIC, body.x, gy + GLASS_H - 12, body.w, 40) -- (square where it meets the sides)
	frame(sheet, "TVTopFlat", PLASTIC, body.x, gy - 28, body.w, 30)
	-- its front: a speaker grille, two knobs and the little red light
	for i = 0, 6 do frame(sheet, "Grille" .. i, Color3.fromRGB(70, 70, 76), body.x + 60 + i * 16, gy + GLASS_H + 28, 6, 30) end
	for i = 0, 1 do round(frame(sheet, "Knob" .. i, Color3.fromRGB(96, 96, 104), body.x + body.w - 150 + i * 48, gy + GLASS_H + 26, 34, 34), 17) end
	local lamp = round(frame(sheet, "Lamp", Color3.fromRGB(90, 30, 30), body.x + body.w - 46, gy + GLASS_H + 36, 14, 14), 7)
	-- the glass's rounded corners: the plastic comes a little over the picture
	local rim = frame(sheet, "Rim", PLASTIC, gx, gy, GLASS_W, GLASS_H)
	rim.BackgroundTransparency, rim.ZIndex = 1, 6
	round(rim, 26)
	local rimStroke = Instance.new("UIStroke")
	rimStroke.Color, rimStroke.Thickness, rimStroke.Parent = PLASTIC, 14, rim
	scale:GetPropertyChangedSignal("Scale"):Connect(function() rimStroke.Thickness = 14 * scale.Scale end)
	rimStroke.Thickness = 14 * scale.Scale

	-- The glass while the TV is off, and the pieces that switch it on and off.
	local off = frame(glass, "Off", GLASS_OFF, 0, 0, GLASS_W, GLASS_H)
	local shine = frame(off, "Shine", WHITE, 0, 0, GLASS_W, GLASS_H) -- a faint reflection across the dark glass
	local sweep = Instance.new("UIGradient")
	sweep.Rotation = 35
	sweep.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(1, 0.96) })
	sweep.Parent = shine
	local glow = frame(glass, "Glow", Color3.fromRGB(235, 245, 255), 0, 0, GLASS_W, GLASS_H) -- the white of a tube warming up
	glow.AnchorPoint, glow.Position, glow.Visible, glow.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromOffset(GLASS_W / 2, GLASS_H / 2), false, 5
	local wait = centred(PaperUI.words(off, "Wait", "", 0, GLASS_H / 2 - 30, GLASS_W, 60, 34))
	wait.TextColor3 = Color3.fromRGB(190, 200, 205)

	-- ===== Title, close, your Paper =====
	local title = PaperUI.image(sheet, "TitleTape", Assets.ingame.tapeLabel, 700, 18, 520, 108)
	PaperUI.loud(centred(PaperUI.words(title, "Label", "Emotes", 0, 0, 520, 108, 76))).Size = UDim2.fromScale(1, 1)
	PaperUI.button(sheet, "Close", Assets.shop.close, "", W - 150, 22, 104, 104, 0, function() api.back() end, 10)
	local wallet = centred(PaperUI.words(sheet, "Paper", "", 40, 40, 520, 60, 40))
	PaperUI.loud(wallet)

	-- ===== Under the TV: the emote's name, a line, its buttons =====
	local under = body.y + body.h + 62
	local nameWords = PaperUI.loud(centred(PaperUI.words(sheet, "Name", "Pick an emote", body.x - 40, under, body.w + 80, 56, 52)))
	local lineWords = centred(PaperUI.words(sheet, "Line", "Tap a card to watch it on the TV.", body.x - 40, under + 54, body.w + 80, 36, 28))
	local strip = Assets.mainmenu.strip
	local by = under + 96
	local buyPaper = PaperUI.button(sheet, "BuyPaper", strip.yellow, "", W / 2 - 330, by, 320, 84, -1, function()
		if state.pick then api.action:FireServer("buyEmote", state.pick) end
	end, 40)
	buyPaper.Label.TextColor3 = INK
	local buyRobux -- (made per pick: PaperUI.robuxButton takes its price when made)
	local use = PaperUI.button(sheet, "Use", strip.blue, "Use", W / 2 - 160, by, 320, 84, -1, function()
		if state.pick then api.action:FireServer("wearEmote", state.pick) end
	end, 44)
	local using = PaperUI.image(sheet, "Using", Assets.ingame.tapeLabel, W / 2 - 170, by + 4, 340, 76)
	local usingCheck = PaperUI.image(using, "Check", Assets.settings.check, 62, 16, 44, 44)
	PaperUI.loud(centred(PaperUI.words(using, "Label", "Using", 60, 0, 280, 76, 44)))
	for _, piece in { buyPaper, use, using } do piece.Visible = false end
	usingCheck.ZIndex = 2

	-- ===== The two boards and their cards =====
	local cards = {} -- id -> { button, price, view, emote }
	local select
	for _, column in KINDS do
		local board = round(frame(sheet, "Board" .. column.kind, BOARD, column.x - 14, 140, 548, H - 150), 18)
		local edge = Instance.new("UIStroke")
		edge.Color, edge.Thickness, edge.Parent = TRIM, 8, board
		scale:GetPropertyChangedSignal("Scale"):Connect(function() edge.Thickness = 8 * scale.Scale end)
		edge.Thickness = 8 * scale.Scale
		local head = PaperUI.loud(centred(PaperUI.words(sheet, "Head" .. column.kind, column.title, column.x, 150, 520, 52, 46)))
		head.TextColor3 = WHITE
		PaperUI.blackOutline(head)
		local sub = centred(PaperUI.words(sheet, "Sub" .. column.kind, column.line, column.x, 200, 520, 34, 27))
		sub.TextColor3 = Color3.fromRGB(240, 240, 232)
		PaperUI.blackOutline(sub)
		local left = column.x + (520 - 2 * CARD - GAP) / 2
		for i, emote in Emotes.list(column.kind) do
			local x, y = left + ((i - 1) % 2) * (CARD + GAP), 246 + ((i - 1) // 2) * (CARD + GAP)
			local button = PaperUI.button(sheet, "Card" .. emote.id, Assets.hangar.cardSquare, "", x, y, CARD, CARD, 0, function() select(emote.id, true) end, 10)
			local view = Instance.new("ViewportFrame")
			view.Name, view.BackgroundTransparency, view.Position, view.Size = "Pose", 1, UDim2.fromOffset(28, 14), UDim2.fromOffset(CARD - 56, 104)
			view.Ambient, view.LightColor, view.LightDirection = Color3.fromRGB(170, 170, 175), Color3.fromRGB(255, 250, 235), Vector3.new(-0.5, -1, -0.6)
			view.Parent = button
			local name = centred(PaperUI.words(button, "Name", emote.name, 12, 116, CARD - 24, 34, 27))
			PaperUI.loud(name)
			PaperUI.fitWords(name, CARD - 36)
			local price = centred(PaperUI.words(button, "Price", "", 12, 148, CARD - 24, 30, 24))
			cards[emote.id] = { button = button, view = view, price = price, emote = emote, kind = column }
		end
	end

	-- A card's still: the player's own avatar held at one moment of the emote's body clip.
	local function pose(card)
		local source = Cutscene.tv.source
		local id, share = Cutscene.tv.pose(card.emote.id)
		if not source or card.posed then return end
		card.posed = true
		local world = Instance.new("WorldModel")
		world.Parent = card.view
		local model = source:Clone()
		model:ScaleTo(1) -- (on a scaled-up avatar Roblox scales an animation's hip movement twice)
		for _, joint in model:GetDescendants() do
			if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then joint.Transform = CFrame.identity end
		end
		model:PivotTo(CFrame.identity)
		model.Parent = world
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local camera = Instance.new("Camera")
		camera.FieldOfView, camera.Parent, card.view.CurrentCamera = 30, card.view, camera
		local function look()
			local box, size = model:GetBoundingBox()
			local far = math.max(size.Y, size.X * 104 / (CARD - 56)) / 2 * 1.12 / math.tan(math.rad(15))
			local front = model:GetPivot().LookVector
			camera.CFrame = CFrame.lookAt(box.Position + front * far + Vector3.yAxis * size.Y * 0.08, box.Position)
		end
		look()
		if not (animator and id and humanoid.RigType == Enum.HumanoidRigType.R15) then return end
		humanoid.EvaluateStateMachine = false
		task.spawn(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
			if not ok then return end
			track.Priority = Enum.AnimationPriority.Action
			track:Play(0, 1, 0)
			local began = os.clock()
			repeat task.wait() until track.Length > 0 or os.clock() - began > 8 or not card.view.Parent
			if track.Length <= 0 then return end
			track.TimePosition = track.Length * share
			task.wait(0.1)
			look()
		end)
	end

	-- The plane in the kid's hand: the build you fly, in the skin you wear.
	local function plane()
		local profile = state.profile
		local build = profile and profile.presets and profile.presets[player:GetAttribute("SelectedPreset") or 1]
		if not build then return nil end
		local model = Instance.new("Model")
		local ok = pcall(function() Aircraft.build(model, Builder.new(Catalog, build.loadout).candidate, Catalog, true) end)
		if not ok then model:Destroy(); return nil end
		local skin = Customize.shownSkin({ state = {}, profile = profile })
		if skin then model:SetAttribute("Skin", skin); pcall(PlaneLooks.dress, model) end
		return model
	end

	-- ===== The TV switching on and off =====
	local function tween(piece, seconds, goal, style)
		local t = TweenService:Create(piece, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad), goal)
		t:Play()
		return t
	end
	local function switchOff(token)
		-- the picture folds to a bright line, the line to a dot, the dot goes out
		glow.Size, glow.BackgroundTransparency, glow.Visible = UDim2.fromOffset(GLASS_W, GLASS_H), 1, true
		tween(glow, 0.08, { BackgroundTransparency = 0 })
		task.wait(0.08)
		if state.token ~= token then return end
		off.Visible = true
		tween(glow, 0.12, { Size = UDim2.fromOffset(GLASS_W, 6) })
		task.wait(0.12)
		tween(glow, 0.14, { Size = UDim2.fromOffset(8, 6) })
		task.wait(0.14)
		tween(glow, 0.25, { BackgroundTransparency = 1 })
		lamp.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
	end
	local function stop()
		state.token += 1
		state.playing = false
		Cutscene.tv.stop()
		off.Visible, glow.Visible = true, false
		lamp.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
	end
	local function play(id)
		stop()
		local token = state.token
		wait.Text = ""
		local held = plane()
		local started = Cutscene.tv.play(id, glass, layer, held, function()
			if held then held:Destroy() end
			if state.token ~= token then return end
			state.playing = false
			task.spawn(switchOff, token)
		end)
		if not started then
			if held then held:Destroy() end
			wait.Text = "One moment..."
			task.delay(0.6, function() if state.token == token and state.shown and state.pick == id then play(id) end end)
			return
		end
		state.playing = true
		lamp.BackgroundColor3 = Color3.fromRGB(255, 70, 60)
		-- the tube warms up: a bright line across the middle opens into a white picture, which clears to the kid
		task.spawn(function()
			glow.Size, glow.BackgroundTransparency, glow.Visible = UDim2.fromOffset(0, 6), 0, true
			tween(glow, 0.1, { Size = UDim2.fromOffset(GLASS_W, 6) })
			task.wait(0.1)
			tween(glow, 0.14, { Size = UDim2.fromOffset(GLASS_W, GLASS_H) })
			task.wait(0.14)
			if state.token ~= token then return end
			off.Visible = false
			tween(glow, 0.3, { BackgroundTransparency = 1 })
		end)
	end

	-- ===== Picking a card =====
	local function buttons()
		local id = state.pick
		local emote = id and Emotes.get(id)
		for _, piece in { buyPaper, use, using } do piece.Visible = false end
		if buyRobux then buyRobux:Destroy(); buyRobux = nil end
		if not emote then return end
		local price, owned = Emotes.price(id), state.owned[id] or Emotes.price(id) == nil
		local message = player:GetAttribute("MenuMessage")
		nameWords.Text = emote.name
		lineWords.Text = message and message ~= "" and message or (emote.kind == "leader" and "Leader emote" or "Runner-up emote")
		if state.worn[emote.kind] == id then
			using.Visible = true
		elseif owned then
			use.Visible = true
		else
			buyPaper.Visible = true
			buyPaper.Label.Text = PaperUI.commas(price.paper) .. " Paper"
			if RunService:IsStudio() then -- practice buys only until live sales are approved (docs/systems/economy-and-shop.md)
				buyRobux = PaperUI.robuxButton(sheet, "BuyRobux", W / 2 + 10, by, 320, 84, "", price.robux, 40, function() api.buy("emote_" .. id) end)
			else
				buyPaper.Position = UDim2.fromOffset(W / 2, by + 42) -- alone: in the middle
			end
		end
	end
	select = function(id, watch)
		state.pick = id
		for other, card in cards do
			card.button.Image = other == id and Assets.hangar.cardSelectedSquare or Assets.hangar.cardSquare
		end
		player:SetAttribute("MenuMessage", nil)
		buttons()
		if watch then play(id) end
	end

	local function refresh()
		state.owned = {}
		for id in string.gmatch(player:GetAttribute("EmotesOwned") or "", "[^,]+") do state.owned[id] = true end
		state.worn = { leader = player:GetAttribute("EmoteLeader") or Emotes.free("leader"), runner_up = player:GetAttribute("EmoteRunnerUp") or Emotes.free("runner_up") }
		wallet.Text = "Your Paper: " .. PaperUI.commas(math.floor(player:GetAttribute("Paper") or 0))
		for id, card in cards do
			local price = Emotes.price(id)
			card.price.Text = state.worn[card.emote.kind] == id and "Using" or not price and "Free" or state.owned[id] and "Owned" or PaperUI.commas(price.paper) .. " Paper"
		end
		buttons()
	end
	for _, name in { "EmotesOwned", "EmoteLeader", "EmoteRunnerUp", "Paper", "MenuMessage" } do
		player:GetAttributeChangedSignal(name):Connect(function() if state.shown then refresh() end end)
	end

	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		state.shown = cover.Visible
		if state.shown then
			fit()
			Cutscene.tv.avatar() -- on its way before the first tap
			refresh()
		else
			stop()
		end
	end)
	-- The card stills, once the avatar is here.
	task.spawn(function()
		while layer.Parent do
			if state.shown and Cutscene.tv.source then
				for _, card in cards do if not card.posed then pose(card); task.wait() end end
			end
			task.wait(0.3)
		end
	end)

	return {
		frame = cover,
		update = function(_, profile) state.profile = profile or state.profile end,
	}
end

return EmoteShop
