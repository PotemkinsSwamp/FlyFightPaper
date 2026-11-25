-- The Emotes page (docs/plan/EMOTE-SHOP-PLAN.md; Alan 2026-11-24): the shop for the winners' emotes and the place you
-- put them on, in one. A box TV on its cart stands in the middle; tap a card and the TV flicks on and your own
-- character does that emote once, then it switches off. Leader emotes (1st place) hang on the left board, Runner-up
-- emotes (2nd and 3rd) on the right. Under the TV: the emote's name and its buttons (Paper and Robux, or Use).
-- The TV's glass is a real hole in this page: the emote plays in the game's own picture behind it
-- (WinnersCutscene's `tv`), so the hole has to sit exactly in the middle of the screen. That is why this page lays
-- itself out round the screen's middle instead of using PaperUI.screen's background plate.
-- The classroom, the two boards, the TV and its cart are one painting (Alan's OK 2026-11-25; assets/ui/emoteshop,
-- docs/plan/EMOTE-SHOP-PLAN.md "The page's picture"): four tiles with the glass see-through, 100 sheet pixels taller
-- than the page above and below; past that, and past its sides, its outermost pixels are stretched.
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
local Audio = require(script.Parent.Audio)
local EmoteShop = {}

local W, H = PaperUI.W, PaperUI.H
local INK, WHITE = PaperUI.INK, Color3.new(1, 1, 1)
-- Sheet pixels. The glass (4:3) is centred on the sheet; the sheet is centred on the screen. Every number below is
-- where the painting has that thing.
local GLASS_W, GLASS_H = 600, 450
local OVER = 100 -- the painting's extra rows above and below the page
local CARD_W, CARD_H, GAP, PITCH = 166, 127, 8, 134 -- a card (its paper's own shape), the gap, row to row
local GRID = 3 * CARD_W + 2 * GAP
local CHALK = Color3.fromRGB(240, 240, 232)
local GLASS_OFF = Color3.fromRGB(24, 31, 28)
local LAMP_OFF = Color3.fromRGB(70, 22, 22)
local TAP_GAP = 0.5 -- seconds after a card is tapped in which another tap is ignored
local KINDS = {
	{ kind = "leader", title = "Leader emotes", line = "Plays when you finish 1st.", x = 57, pin = "pinRed" }, -- the chalkboard
	{ kind = "runner_up", title = "Runner-up emotes", line = "Plays when you finish 2nd or 3rd.", x = 1350, pin = "pinBlue" }, -- the bulletin board
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
	-- Four unseen pieces round the glass: nothing behind the page can be clicked.
	local walls = {}
	for i = 1, 4 do
		walls[i] = frame(cover, "Wall" .. i, WHITE, 0, 0, 0, 0)
		walls[i].BackgroundTransparency, walls[i].Active = 1, true
	end
	local sheet = Instance.new("Frame")
	sheet.Name, sheet.AnchorPoint, sheet.Position = "Sheet", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	sheet.Size, sheet.BackgroundTransparency, sheet.Parent = UDim2.fromOffset(W, H), 1, cover
	local scale = Instance.new("UIScale")
	scale.Parent = sheet
	local gx, gy = (W - GLASS_W) / 2, (H - GLASS_H) / 2
	local glass = frame(sheet, "Glass", GLASS_OFF, gx, gy, GLASS_W, GLASS_H)
	glass.BackgroundTransparency, glass.ClipsDescendants, glass.ZIndex = 1, true, -2 -- under the painting, which is under everything else
	-- The painting: tiles 1 2 over 3 4, then its edges pulled out over whatever more of the screen there is.
	local function tile(name, i, x, y, w, h, rect)
		local piece = Instance.new("ImageLabel")
		piece.Name, piece.Image, piece.BackgroundTransparency, piece.ZIndex = name, Assets.emoteshop.room[i], 1, -1
		piece.Position, piece.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
		if rect then piece.ImageRectOffset, piece.ImageRectSize = Vector2.new(rect[1], rect[2]), Vector2.new(rect[3], rect[4]) end
		piece.Parent = sheet
	end
	local FAR, top = 1400, -OVER
	for i = 1, 4 do
		local col, row = (i - 1) % 2, (i - 1) // 2
		local x, y = col * 960, top + row * 640
		tile("Room" .. i, i, x, y, 961, 641) -- (a pixel over its neighbour: no hairline between tiles at odd screen sizes)
		local sideX, sideRect = col == 0 and -FAR or W, col == 0 and 0 or 956
		local endY, endRect = row == 0 and top - FAR or top + 1280, row == 0 and 0 or 636
		tile("RoomSide" .. i, i, sideX, y, FAR, 640, { sideRect, 0, 4, 640 })
		tile("RoomEnd" .. i, i, x, endY, 960, FAR, { 0, endRect, 960, 4 })
		tile("RoomCorner" .. i, i, sideX, endY, FAR, FAR, { sideRect, endRect, 4, 4 })
	end
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

	local state = { pick = nil, owned = {}, worn = {}, profile = nil, playing = false, shown = false, token = 0, tapped = -math.huge }

	-- The TV's power light: painted lit; this covers it while the TV is off.
	local lamp = round(frame(sheet, "Lamp", LAMP_OFF, 1259, 787, 14, 14), 7)

	-- The glass while the TV is off, and the pieces that switch it on and off.
	local off = frame(glass, "Off", GLASS_OFF, 0, 0, GLASS_W, GLASS_H)
	local glow = frame(glass, "Glow", Color3.fromRGB(235, 245, 255), 0, 0, GLASS_W, GLASS_H) -- the white of a tube warming up
	glow.AnchorPoint, glow.Position, glow.Visible, glow.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromOffset(GLASS_W / 2, GLASS_H / 2), false, 5
	local wait = centred(PaperUI.words(off, "Wait", "", 0, GLASS_H / 2 - 30, GLASS_W, 60, 34))
	wait.TextColor3 = Color3.fromRGB(190, 200, 205)

	-- ===== Title, close, your Paper =====
	local title = PaperUI.image(sheet, "TitleTape", Assets.ingame.tapeLabel, 700, 18, 520, 108)
	PaperUI.loud(centred(PaperUI.words(title, "Label", "Emotes", 0, 0, 520, 108, 76))).Size = UDim2.fromScale(1, 1)
	PaperUI.button(sheet, "Close", Assets.shop.close, "", W - 150, 22, 104, 104, 0, function() api.back() end, 10)
	local walletTape = PaperUI.image(sheet, "PaperTape", Assets.ingame.tapeLabel, 60, 34, 440, 74, -1.5)
	local wallet = PaperUI.loud(centred(PaperUI.words(walletTape, "Label", "", 0, 0, 440, 74, 38)))
	wallet.Size = UDim2.fromScale(1, 1)

	-- ===== On the cart's front: the emote's name, a line, its buttons =====
	local BUTTON_W, BUTTON_H, by = 260, 66, 954
	local nameWords = PaperUI.blackOutline(PaperUI.loud(centred(PaperUI.words(sheet, "Name", "Pick an emote", W / 2 - 290, 884, 580, 46, 42))))
	local lineWords = PaperUI.blackOutline(centred(PaperUI.words(sheet, "Line", "Tap a card to watch it on the TV.", W / 2 - 290, 926, 580, 26, 22)))
	nameWords.TextColor3, lineWords.TextColor3 = WHITE, CHALK
	local strip = Assets.mainmenu.strip
	local buyPaper = PaperUI.button(sheet, "BuyPaper", strip.yellow, "", W / 2 - BUTTON_W - 8, by, BUTTON_W, BUTTON_H, -1, function()
		if state.pick then api.action:FireServer("buyEmote", state.pick) end
	end, 38)
	buyPaper.Label.TextColor3 = INK
	local buyRobux -- (made per pick: PaperUI.robuxButton takes its price when made)
	local use = PaperUI.button(sheet, "Use", strip.blue, "Use", W / 2 - BUTTON_W / 2, by, BUTTON_W, BUTTON_H, -1, function()
		if state.pick then api.action:FireServer("wearEmote", state.pick) end
	end, 42)
	local using = PaperUI.image(sheet, "Using", Assets.ingame.tapeLabel, W / 2 - 160, by, 320, BUTTON_H)
	local usingCheck = PaperUI.image(using, "Check", Assets.settings.check, 70, 15, 36, 36)
	PaperUI.loud(centred(PaperUI.words(using, "Label", "Using", 60, 0, 240, BUTTON_H, 40)))
	for _, piece in { buyPaper, use, using } do piece.Visible = false end
	usingCheck.ZIndex = 2

	-- ===== The two boards and their cards =====
	local cards = {} -- id -> { button, price, view, emote }
	local select
	for _, column in KINDS do
		local head = PaperUI.loud(centred(PaperUI.words(sheet, "Head" .. column.kind, column.title, column.x, 160, GRID, 48, 44)))
		head.TextColor3 = WHITE
		PaperUI.blackOutline(head)
		local sub = centred(PaperUI.words(sheet, "Sub" .. column.kind, column.line, column.x, 203, GRID, 30, 24))
		sub.TextColor3 = CHALK
		PaperUI.blackOutline(sub)
		-- Cheapest first, the free one leading (Alan 2026-11-25); same price: the config's order.
		local list, place = table.clone(Emotes.list(column.kind)), {}
		for i, emote in list do place[emote] = i end
		local function paper(emote) local price = Emotes.price(emote.id); return price and price.paper or 0 end
		table.sort(list, function(a, b)
			if paper(a) ~= paper(b) then return paper(a) < paper(b) end
			return place[a] < place[b]
		end)
		for i, emote in list do -- three across; the ninth spot on each board is a painted doodle
			local x, y = column.x + ((i - 1) % 3) * (CARD_W + GAP), 236 + ((i - 1) // 3) * PITCH
			local button = PaperUI.button(sheet, "Card" .. emote.id, Assets.hangar.cardSquare, "", x, y, CARD_W, CARD_H, 0, function() select(emote.id, true) end, 10)
			local view = Instance.new("ViewportFrame")
			view.Name, view.BackgroundTransparency, view.Position, view.Size = "Pose", 1, UDim2.fromOffset(25, 13), UDim2.fromOffset(CARD_W - 50, 58)
			view.Ambient, view.LightColor, view.LightDirection = Color3.fromRGB(170, 170, 175), Color3.fromRGB(255, 250, 235), Vector3.new(-0.5, -1, -0.6)
			view.Parent = button
			local name = centred(PaperUI.words(button, "Name", emote.name, 8, 71, CARD_W - 16, 28, 22))
			PaperUI.loud(name)
			PaperUI.fitWords(name, CARD_W - 28)
			local price = centred(PaperUI.words(button, "Price", "", 8, 94, CARD_W - 16, 22, 20))
			PaperUI.image(button, "Pin", Assets.hud[column.pin], CARD_W / 2 - 8, -9, 16, 16)
			cards[emote.id] = { button = button, view = view, price = price, emote = emote, kind = column }
		end
	end

	-- A card's still: the player's own avatar held at one moment of the emote's body clip.
	local function pose(card)
		local source = Cutscene.tv.source
		local id, share, turn = Cutscene.tv.pose(card.emote.id)
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
			local far = math.max(size.Y, size.X * 58 / (CARD_W - 50)) / 2 * 1.12 / math.tan(math.rad(15))
			local front = CFrame.Angles(0, math.rad(turn or 0), 0) * model:GetPivot().LookVector
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
		-- Its front is where a flying plane's is (that one's Root). Left to Roblox, a model with no main part takes a
		-- piece's own turn, half a circle round: every emote flew it tail first (Alan 2026-11-25, Test Flight).
		model.WorldPivot = CFrame.identity
		return model
	end

	-- ===== The TV switching on and off =====
	local function tween(piece, seconds, goal, style)
		local t = TweenService:Create(piece, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad), goal)
		t:Play()
		return t
	end
	local function switchOff(token)
		-- the click, then the picture folds to a bright line, the line to a dot, the dot goes out
		Audio.play("tvOff")
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
		lamp.BackgroundTransparency = 0
	end
	local function stop()
		state.token += 1
		state.playing = false
		Cutscene.tv.stop()
		off.Visible, glow.Visible = true, false
		lamp.BackgroundTransparency = 0
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
		lamp.BackgroundTransparency = 1
		Audio.play("tvOn")
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
				buyRobux = PaperUI.robuxButton(sheet, "BuyRobux", W / 2 + 8, by, BUTTON_W, BUTTON_H, "", price.robux, 38, function() api.buy("emote_" .. id) end)
			else
				buyPaper.Position = UDim2.fromOffset(W / 2, by + BUTTON_H / 2) -- alone: in the middle
			end
		end
	end
	select = function(id, watch)
		-- A second tap this soon is a double click (Alan 2026-11-25: his mouse sends two, and the TV went on twice with
		-- two clicks heard): it does nothing.
		if watch then
			if os.clock() - state.tapped < TAP_GAP then return end
			state.tapped = os.clock()
		end
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
