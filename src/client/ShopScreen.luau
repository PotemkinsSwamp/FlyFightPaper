-- The shop (docs/plan/SHOP-SCREEN-PLAN.md): a Roblox-style shop window in our paper look, built to the approved concept
-- (.planning/shop-concept/shop2-a.png and shop2-b.png). Every position below is in that picture's pixels (1672 wide,
-- `K` turns them into sheet units), so the window keeps the concept's proportions. Every picture is one named piece in
-- UIAssets.shop: swapping a picture is one line there (tools/art/shop_pieces.py says how to make the new one).
-- Studio only for now (live sales are off; the server refuses mock buys outside Studio). The starter pack, the free
-- gift and the gift buttons are previews with example numbers until Alan OKs their own notes.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Commerce = require(Root.Generated.Commerce)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local Assets = require(Root.Shared.UIAssets)
local Art = Assets.shop
local PaperUI = require(script.Parent.PaperUI)
local Unlock = require(script.Parent.UnlockMoment)
local Customize = require(script.Parent.HangarCustomize) -- (a part's Unlock now price)
local ShopScreen = {}

local K = PaperUI.W / 1672 -- concept pixels -> sheet units
local TEXT = 1.3 -- Kalam draws smaller letters than the concept's lettering at the same size
local INK, WHITE, CHALK = PaperUI.INK, Color3.new(1, 1, 1), Color3.fromRGB(240, 240, 232)
-- Chalk words: white with a dark board-green outline (Alan 2026-11-12: the cream crayon edge blurred them on the board).
local CHALKY = { color = CHALK, outline = Color3.fromRGB(12, 28, 18), thick = 3 }
local PREVIEW = RunService:IsStudio() -- the not-yet-approved cards (starter pack, free gift, gifting)
local ROBUX_ICON = "rbxasset://textures/ui/common/robux@3x.png" -- Roblox's own Robux symbol, shipped with the client
-- The Robux prices Alan approved (docs/plan/SHOP-PRICES-PLAN.md). Display only: real prices must come from Roblox's
-- product info once live sales are approved (docs/systems/economy-and-shop.md).
local PRICE = {
	xp_boost_15m = 25, xp_boost_30m = 45, xp_boost_60m = 79, xp_boost_180m = 199, xp_boost_300m = 299,
	paper_boost_15m = 25, paper_boost_30m = 45, paper_boost_60m = 79, paper_boost_180m = 199, paper_boost_300m = 299,
	paper_pack_1500 = 99, paper_pack_5000 = 299, paper_pack_7500 = 549, paper_pack_15000 = 799, paper_pack_40000 = 1999,
	permanent_2x_xp = 1499, permanent_2x_paper = 999,
}
ShopScreen.PRICE = PRICE -- (the report card's 2x Paper button)
-- Value stickers (true per Robux: bigger packs and longer boosts give more for each Robux).
-- Paper packs per Robux: 40,000 20.0, 15,000 18.8, 5,000 16.7, 1,500 15.2, the 7,500 decoy 13.7 (SHOP-MONEY-PLAN).
local BADGE = { paper_pack_15000 = "Good Value", paper_pack_40000 = "Most Value",
	paper_boost_180m = "Good Value", paper_boost_300m = "Most Value", xp_boost_180m = "Good Value", xp_boost_300m = "Most Value" }
-- Pictures grow with the amount: small, stack (5,000 and the 7,500 decoy), pile, box (the 40,000 anchor).
local PACK_ICON = { paper_pack_1500 = "iconPaperSmall", paper_pack_5000 = "iconStack", paper_pack_7500 = "iconStack",
	paper_pack_15000 = "iconPaperPile", paper_pack_40000 = "iconPaperBox" }
local DAILY = require(Root.Generated.Economy).daily_gift -- the 7-day gift row (nil until its save rules are in)
-- How a real part is shown in a card, by kind: { turn, tilt } in degrees. Flat parts from nearly above, the rest at a
-- three-quarter angle. An item can give its own `pose` instead.
local POSE = { wings = { 0, -65 }, tail = { 0, -60 }, default = { 35, -25 } }
-- The starter pack preview (example contents, Alan's OK pending: docs/decisions/2026-11-11-shop-direction.md).
local STARTER = { price = 99, worth = 227, seconds = (2 * 24 + 14) * 3600 + 5 * 60,
	items = { { part = "wings_1", kind = "wings" }, { icon = "iconStack", label = "1,500 Paper" }, { icon = "iconClockStar", label = "1 hour\n2x XP" } } } -- Alan 2026-11-12: 2x XP, not 2x Paper

local commas = PaperUI.commas
local function now() return math.floor(workspace:GetServerTimeNow()) end -- the server's clock: every timer and day ends at once for everyone

local function duration(seconds)
	local minutes = seconds // 60
	if minutes < 60 then return minutes .. " min" end
	local hours = minutes / 60
	return hours == 1 and "1 hour" or string.format("%g hours", hours)
end

-- api = { buy(key), back() }
function ShopScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "ShopScreen", Assets.mainmenu.bg)
	-- The main menu behind, darkened (between the backdrop and the sheet).
	local dim = Instance.new("Frame")
	dim.Name, dim.Size, dim.BackgroundColor3, dim.BackgroundTransparency, dim.BorderSizePixel = "Dim", UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 0.6, 0
	dim.ZIndex, sheet.ZIndex, dim.Parent = 2, 3, cover
	local board = Instance.new("Frame")
	board.Name, board.BackgroundTransparency, board.Size, board.Parent = "Board", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet
	local pop = Instance.new("UIScale")
	pop.Parent = board

	local moving = {} -- pieces the loop below animates: { inst, kind, phase, size, pos, rot, ... }
	local function move(inst, kind, phase, extra)
		local entry = { inst = inst, kind = kind, phase = phase or 0, size = inst.Size, pos = inst.Position, rot = inst.Rotation }
		for key, value in extra or {} do entry[key] = value end
		table.insert(moving, entry)
		return inst
	end

	-- A picture in a box given as concept-pixel corners (relative to its parent's concept origin), stretched to it.
	local function pic(parent, name, id, x0, y0, x1, y1, rot)
		local label = PaperUI.image(parent, name, id, x0 * K, y0 * K, (x1 - x0) * K, (y1 - y0) * K, rot)
		label.ScaleType = Enum.ScaleType.Stretch
		return label
	end
	local function fit(label) label.ScaleType = Enum.ScaleType.Fit; return label end
	-- Faded chalk green behind every picture (Alan 2026-11-12 picked it, docs/workshop/design-examples.md): middle
	-- brightness, so white pieces and dark pieces both stand out; the board's own colour family. Made before the picture.
	local BACKING = Color3.fromRGB(104, 133, 118)
	local function backing(parent, x0, y0, x1, y1) local circle = fit(pic(parent, "Backing", Art.circlePale, x0, y0, x1, y1)); circle.ImageColor3 = BACKING; return circle end
	-- Words in a box (concept px), centred unless told; size in concept px. outline: a plain ink (or given) stroke instead
	-- of the cream crayon edge, for words on bright paper like the concept's titles.
	local function say(parent, name, text, x0, y0, x1, y1, size, opts)
		opts = opts or {}
		local label = PaperUI.words(parent, name, text, x0 * K, y0 * K, (x1 - x0) * K, (y1 - y0) * K, math.round(size * K * TEXT))
		label.TextXAlignment = opts.left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
		label.TextColor3 = opts.color or INK
		if opts.loud then PaperUI.loud(label) end
		if opts.outline then
			local stroke = Instance.new("UIStroke")
			stroke.Color, stroke.Thickness, stroke.LineJoinMode = opts.outline, (opts.thick or 3) * K, Enum.LineJoinMode.Round
			stroke.Parent = label
		end
		if opts.rot then label.Rotation = opts.rot end
		if not opts.grow then PaperUI.fitWords(label, (x1 - x0) * K * 0.96) end -- too long: smaller, never past its box
		return label
	end
	-- A paper button (hover grow, press squish from PaperUI) in a concept-pixel box.
	local function press(parent, name, id, x0, y0, x1, y1, callback, rot)
		local button = PaperUI.button(parent, name, id, "", x0 * K, y0 * K, (x1 - x0) * K, (y1 - y0) * K, rot or 0, callback, 10)
		button.ScaleType = Enum.ScaleType.Stretch
		return button
	end

	-- A short note on tape at the bottom of the window (the server's replies, and the previews' "not built yet").
	local note = pic(board, "NoteTape", Assets.ingame.tapeLabel, 380, 900, 1150, 950)
	note.ScaleType, note.SliceCenter, note.SliceScale, note.ZIndex, note.Visible = Enum.ScaleType.Slice, Rect.new(90, 30, 894, 104), 0.5, 5, false
	local noteWords = say(note, "Words", "", 30, 0, 740, 50, 30)
	noteWords.ZIndex = 5
	local localNote, localUntil = "", 0
	local function showNote()
		local text = os.clock() < localUntil and localNote or (game.Players.LocalPlayer:GetAttribute("MenuMessage") or "")
		note.Visible, noteWords.Text = text ~= "", text
	end
	local function preview(text)
		localNote, localUntil = text, os.clock() + 4
		showNote()
		task.delay(4.1, showNote)
	end
	game.Players.LocalPlayer:GetAttributeChangedSignal("MenuMessage"):Connect(showNote)

	-- ===== The window: chalkboard in its frame (2x2 tiles), title bar, Gift a friend, close =====
	local mx, my = (95 + 1432) / 2, (30 + 940) / 2
	-- Tiles overlap by a pixel at the middle lines, or a thin seam shows between them.
	for i, b in { { 95, 30, mx + 1, my + 1 }, { mx - 1, 30, 1432, my + 1 }, { 95, my - 1, mx + 1, 940 }, { mx - 1, my - 1, 1432, 940 } } do
		pic(board, "Window" .. i, Art.window[i], b[1], b[2], b[3], b[4])
	end
	-- The board's scrolling part: everything between the title bar and the frame's bottom edge.
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel, scroll.ScrollBarThickness = "Scroll", 1, 0, 0
	scroll.Position, scroll.Size = UDim2.fromOffset(118 * K, 158 * K), UDim2.fromOffset((1408 - 118) * K, (920 - 158) * K)
	scroll.ScrollingDirection, scroll.ElasticBehavior, scroll.Parent = Enum.ScrollingDirection.Y, Enum.ElasticBehavior.Never, board
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Parent = "Content", 1, scroll
	local handle = pic(board, "ScrollHandle", Art.scrollbar, 1384, 175, 1400, 245)
	pic(board, "TitleLeft", Art.titlebar[1], 120, 40, 766, 160)
	pic(board, "TitleRight", Art.titlebar[2], 765, 40, 1410, 160)
	say(board, "Title", "Shop", 160, 50, 420, 150, 82, { left = true, loud = true })
	local friend = press(board, "GiftFriend", Art.giftFriend, 945, 58, 1282, 145, function()
		preview("Gift a friend comes next, after you OK how it works.")
	end)
	friend.Visible = PREVIEW
	fit(pic(friend, "Icon", Art.giftWhite, 20, 12, 90, 77))
	say(friend, "Words", "Gift a friend", 100, 0, 325, 87, 38, { loud = true, color = WHITE, outline = INK })
	press(board, "Close", Art.close, 1300, 48, 1405, 153, function() api.back() end)

	-- ===== Tabs beside the window: jump to a section; the one you're in lights up =====
	local TABS = { { "Featured", "tabStar", 175, 345 }, { "Passes", "tabTicket", 365, 520 }, { "Boosts", "tabClock", 540, 695 }, { "Paper", "tabPaper", 720, 880 } }
	local sections = {} -- tab name -> top of its section in the scroll (sheet units), filled by each redraw
	-- CanvasPosition is in screen pixels, not sheet units: the sheet's UIScale shrinks a small window's sheet (2026-11-12:
	-- the Paper tab scrolled past its heading and top row).
	local function perUnit() return scroll.AbsoluteSize.Y > 0 and scroll.AbsoluteSize.Y / scroll.Size.Y.Offset or 1 end -- (1: not drawn yet)
	local tabs = {}
	for _, tab in TABS do
		local name, icon, y0, y1 = tab[1], tab[2], tab[3], tab[4]
		local paper = press(board, "Tab" .. name, Art.tabCream, 1450, y0, 1650, y1, function()
			local top = sections[name]
			if top then
				TweenService:Create(scroll, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CanvasPosition = Vector2.new(0, top * perUnit()) }):Play()
			end
		end)
		fit(pic(paper, "Icon", Art[icon], 40, 15, 160, 105))
		say(paper, "Words", name, 0, 98, 200, y1 - y0 - 8, 36, { loud = true })
		fit(pic(board, "Pin" .. name, Art.pin, 1535, y0 - 12, 1560, y0 + 13))
		tabs[name] = paper
	end
	local function scrolled()
		local y, lit, best = scroll.CanvasPosition.Y / perUnit(), "Featured", -1
		local bottom = y >= scroll.CanvasSize.Y.Offset - scroll.Size.Y.Offset - 2
		for name, top in sections do
			-- The last section you've scrolled to (at the very bottom: the last one, even if its top can't reach the top).
			if (top <= y + scroll.Size.Y.Offset * 0.4 or bottom) and top > best then lit, best = name, top end
		end
		for name, paper in tabs do paper.Image = name == lit and Art.tabYellow or Art.tabCream end
		-- Our scrollbar handle (Roblox's own bar is hidden): along the board's right edge, 175-850.
		local share = math.clamp(y / math.max(1, scroll.CanvasSize.Y.Offset - scroll.Size.Y.Offset), 0, 1)
		handle.Position = UDim2.fromOffset(1392 * K, (210 + share * 640) * K)
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(scrolled)

	-- ===== Card pieces =====
	local function heading(y, text)
		-- Chalk letters with a chalk line on each side (the concept's centre is x 765, i.e. 647 in the scroll).
		local half = #text * 17 + 40
		say(content, "Head" .. text, text, 347, y - 2, 947, y + 52, 50, CHALKY)
		pic(content, "LineL" .. text, Art.chalkLine, 92, y + 23, 647 - half, y + 28)
		pic(content, "LineR" .. text, Art.chalkLine, 647 + half, y + 23, 1222, y + 28)
	end
	local function robux(parent, h)
		local icon = Instance.new("ImageLabel")
		icon.Name, icon.Image, icon.BackgroundTransparency, icon.ImageColor3 = "Robux", ROBUX_ICON, 1, INK
		icon.Size, icon.LayoutOrder, icon.Parent = UDim2.fromOffset(h * K, h * K), 1, parent
		return icon
	end
	-- The green buy button: Robux symbol + price, or a word (OWNED) instead.
	local function buy(parent, name, x0, y0, x1, y1, price, size, callback, word)
		local button = press(parent, name, Art.buyGreen, x0, y0, x1, y1, callback)
		local row = Instance.new("Frame")
		row.Name, row.BackgroundTransparency, row.Size = "Price", 1, UDim2.fromScale(1, 1)
		local list = Instance.new("UIListLayout")
		list.FillDirection, list.HorizontalAlignment, list.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
		list.Padding, list.SortOrder, list.Parent = UDim.new(0, 8 * K), Enum.SortOrder.LayoutOrder, row
		row.Parent = button
		if not word then robux(row, (y1 - y0) * 0.7) end
		local label = say(row, "Amount", word or commas(price), 0, 0, 10, y1 - y0, size, { loud = true, grow = true })
		label.AutomaticSize, label.LayoutOrder = Enum.AutomaticSize.X, 2
		return button
	end
	local function gift(parent, x0, y0, x1, y1)
		if not PREVIEW then return end
		press(parent, "Gift", Art.giftButton, x0, y0, x1, y1, function() preview("Gift a friend comes next, after you OK how it works.") end)
	end
	local rainbow = {}
	local function sticker(parent, text, x0, y0, x1, y1, size, rot)
		local paper = pic(parent, "Sticker", Art.stickerWhite, x0, y0, x1, y1, rot)
		paper.ZIndex = 3
		if text == "Most Value" then
			local gradient = Instance.new("UIGradient")
			gradient.Parent = paper
			table.insert(rainbow, gradient)
		else
			paper.ImageColor3 = Color3.fromRGB(40, 110, 240)
		end
		local words = say(paper, "Words", text, 0, 0, x1 - x0, y1 - y0, size, { loud = true })
		words.ZIndex = 3
		return paper
	end
	local function ticks(parent, x0, y0, x1, y1, rot, phase)
		move(pic(parent, "Ticks", Art.ticks, x0, y0, x1, y1, rot), "twist", phase)
	end

	-- ===== Sections (each draws from its top y in scroll pixels and returns the next top) =====
	local function featured(y)
		heading(y, "FEATURED")
		local cx, cy = 135 - 118, y + 55 -- the card's corner in the scroll
		local card = Instance.new("Frame")
		card.Name, card.BackgroundTransparency, card.Position, card.Size = "StarterPack", 1, UDim2.fromOffset(cx * K, cy * K), UDim2.fromOffset(1237 * K, 325 * K)
		card.Parent = content
		pic(card, "PaperL", Art.cardFeatured[1], 0, 0, 620, 325)
		pic(card, "PaperR", Art.cardFeatured[2], 618, 0, 1237, 325)
		-- The shine that sweeps across every 4 s, kept inside the paper.
		local clip = Instance.new("Frame")
		clip.Name, clip.BackgroundTransparency, clip.ClipsDescendants = "ShineClip", 1, true
		clip.Position, clip.Size, clip.Parent = UDim2.fromOffset(14 * K, 14 * K), UDim2.fromOffset(1209 * K, 297 * K), card
		local shine = Instance.new("Frame")
		shine.Name, shine.BackgroundColor3, shine.BorderSizePixel, shine.Size = "Shine", WHITE, 0, UDim2.new(0, 120 * K, 1.6, 0)
		shine.AnchorPoint, shine.Position, shine.Rotation, shine.Parent = Vector2.new(0.5, 0.5), UDim2.fromScale(-0.2, 0.5), 18, clip
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1) })
		fade.Parent = shine
		move(shine, "shine")
		ticks(card, 5, 180, 50, 230, -90, 0.3)
		move(fit(pic(card, "Bag", Art.iconGiftBag, 55, 85, 275, 305)), "bob", 0)
		local burst = pic(card, "New", Art.burstNew, 15, -10, 200, 115, -10)
		say(burst, "Words", "New!", 0, 0, 185, 125, 46, { loud = true })
		move(burst, "wobble")
		say(card, "Name", "STARTER PACK", 225, 8, 825, 82, 74, { color = Color3.fromRGB(255, 222, 40), outline = INK, thick = 5 })
		say(card, "Limited", "Limited time!", 380, 70, 645, 110, 36, { color = WHITE, outline = INK })
		pic(card, "TimerPaper", Art.labelDark, 945, 18, 1220, 75)
		local timer = say(card, "Timer", "", 945, 18, 1220, 75, 40, { color = WHITE })
		-- The real timer: from the first time the player came in, saved (StarterPackEnds); Studio before the save rules: a preview.
		local ends = game.Players.LocalPlayer:GetAttribute("StarterPackEnds") or now() + STARTER.seconds
		move(timer, "timer", 0, { ends = ends })
		for i, item in STARTER.items do
			local x0 = 310 + (i - 1) * 185
			local square = pic(card, "Item" .. i, Art.itemSquare, x0, 113, x0 + 176, 303)
			backing(square, 18, 4, 158, 126)
			ticks(card, x0 + 105, 113, x0 + 165, 148, 15, i)
			if item.part then
				local part = Catalog:get(item.part)
				local view = Unlock.view(square, { kind = item.kind, part = part }, 10 * K, 6 * K, 156 * K, 118 * K)
				-- Still, at its kind's best angle (or the item's own pose), bobbing like the other pictures (Alan 2026-11-12:
				-- turning in circles looked bad). Framed on its own pieces, whatever its shape.
				local model = view:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
				local look = model:FindFirstChild("Appearance") or model
				local centre, size = look:GetBoundingBox()
				local pose = item.pose or POSE[item.kind] or POSE.default
				local far = size.Magnitude / 2 / math.tan(math.rad(20)) * 1.05
				view.CurrentCamera.CFrame = CFrame.new(centre.Position) * CFrame.Angles(0, math.rad(pose[1]), 0)
					* CFrame.Angles(math.rad(pose[2]), 0, 0) * CFrame.new(0, 0, far)
				move(view, "bob", i)
				say(square, "Label", part.name, 0, 122, 176, 180, 27, { loud = true })
			else
				move(fit(pic(square, "Icon", Art[item.icon], 18, 12, 158, 120)), "bob", i)
				local one, two = item.label:match("^(.-)\n(.*)$")
				if one then
					say(square, "Label1", one, 0, 116, 176, 150, 27, { loud = true }); say(square, "Label2", two, 0, 146, 176, 182, 27, { loud = true })
				else
					say(square, "Label", item.label, 0, 122, 176, 180, 27, { loud = true })
				end
			end
		end
		move(fit(pic(card, "Sparkle", Art.sparkle, 860, 30, 925, 85, 12)), "twinkle", 0)
		move(fit(pic(card, "Sparkle2", Art.sparkle, 1185, 100, 1215, 130, -10)), "twinkle", 1.7)
		local worth = say(card, "Worth", tostring(STARTER.worth), 985, 115, 1130, 170, 50)
		local cross = Instance.new("Frame")
		cross.Name, cross.BackgroundColor3, cross.BorderSizePixel, cross.AnchorPoint = "Cross", Color3.fromRGB(220, 30, 30), 0, Vector2.new(0.5, 0.5)
		cross.Position, cross.Size, cross.Rotation, cross.Parent = UDim2.fromScale(0.5, 0.55), UDim2.new(0.75, 0, 0, 6 * K), -6, worth
		ticks(card, 1160, 130, 1205, 180, 30, 2.2)
		gift(card, 875, 188, 965, 280)
		buy(card, "Buy", 977, 185, 1217, 295, STARTER.price, 74, function() api.buy("starter_pack") end)
		return y + 380
	end

	-- "100 Paper" / "15 min 2x XP"
	local function giftWords(reward)
		if reward.paper then return commas(reward.paper) .. " Paper" end
		local seconds = reward.xp_seconds or reward.paper_seconds
		return math.floor(seconds / 60) .. " min 2x " .. (reward.xp_seconds and "XP" or "Paper")
	end
	local function giftIcon(reward, day)
		if day == 7 then return Art.iconGiftBox end
		if reward.xp_seconds then return Art.iconClockStar elseif reward.paper_seconds then return Art.iconClockPaper end
		return reward.paper <= 150 and Art.iconPaperSmall or Art.iconPaperPile
	end

	-- The free daily gift (docs/plan/SHOP-MONEY-PLAN.md): today's gift and Claim on the card, the week's 7 gifts in a
	-- row under it (claimed ones ticked). A missed day doesn't reset the row; the server keeps the count.
	local function freeGift(y)
		heading(y, "FREE GIFT")
		local player = game.Players.LocalPlayer
		local rewards = DAILY and DAILY.rewards
		local day = player:GetAttribute("DailyGiftNext") or 1
		local ready = player:GetAttribute("DailyGiftReady") ~= false
		local cx, cy = 175 - 118, y + 48
		local card = Instance.new("Frame")
		card.Name, card.BackgroundTransparency, card.Position, card.Size = "FreeGift", 1, UDim2.fromOffset(cx * K, cy * K), UDim2.fromOffset(1160 * K, 120 * K)
		card.Parent = content
		pic(card, "PaperL", Art.cardFree[1], 0, 0, 582, 120)
		pic(card, "PaperR", Art.cardFree[2], 580, 0, 1160, 120)
		ticks(card, 60, 15, 110, 80, -90, 0.5)
		move(fit(pic(card, "Box", Art.iconGiftBox, 125, -8, 285, 122)), "bob", 0.8)
		say(card, "Line1", "Free daily gift", 300, 8, 700, 55, 42, { loud = true })
		say(card, "Line2", rewards and ((ready and "Today: " or "Next: ") .. giftWords(rewards[day])) or "Today: 150 Paper", 300, 55, 700, 102, 42, { loud = true })
		ticks(card, 690, 25, 740, 90, 90, 1.4)
		if ready then
			local claim = press(card, "Claim", Art.claimGreen, 820, 15, 1115, 107, function()
				if rewards then api.claimGift() else preview("The daily gift's saving comes next.") end
			end)
			say(claim, "Words", "Claim!", 0, 0, 295, 92, 64, { loud = true })
			move(claim, "pulse")
		else -- the time to the next gift, on the dark label the starter pack's timer uses
			pic(card, "WaitPaper", Art.labelDark, 820, 22, 1115, 100)
			local wait = say(card, "Wait", "", 820, 22, 1115, 100, 40, { color = WHITE })
			move(wait, "timer", 0, { ends = (now() // 86400 + 1) * 86400, short = true }) -- the next gift: UTC midnight, as on the server
		end
		if not rewards then return y + 165 end
		-- The week: 7 squares on the board under the card.
		local top = y + 48 + 132
		for d, reward in rewards do
			local x0 = 57 + (d - 1) * 166
			local square = pic(content, "Day" .. d, Art.itemSquare, x0, top, x0 + 156, top + 168)
			say(square, "Day", "Day " .. d, 0, 6, 156, 42, 28, { loud = true })
			backing(square, 32, 40, 124, 120)
			move(fit(pic(square, "Icon", giftIcon(reward, d), 30, 44, 126, 116)), "bob", d * 0.5)
			say(square, "Gift", giftWords(reward), 6, 118, 150, 160, 24, { loud = true })
			if d < day then -- claimed this week: faded, with a green crayon tick
				square.ImageTransparency = 0.35
				for _, stroke in { { 0.36, 0.62, 0.25, 45 }, { 0.6, 0.5, 0.55, -55 } } do
					local line = Instance.new("Frame")
					line.Name, line.AnchorPoint, line.BorderSizePixel = "Tick", Vector2.new(0.5, 0.5), 0
					line.Position, line.Size = UDim2.fromScale(stroke[1], stroke[2]), UDim2.new(stroke[3], 0, 0, 12 * K)
					line.Rotation, line.BackgroundColor3, line.ZIndex = stroke[4], Color3.fromRGB(40, 160, 60), 3
					Instance.new("UICorner", line).CornerRadius = UDim.new(0.5, 0)
					line.Parent = square
				end
			elseif d == day and ready then
				move(square, "pulse")
			end
		end
		return top + 168 + 20
	end

	-- A part's 3D picture, still at its kind's best angle, bobbing (as the starter pack's items).
	local function partView(parent, item, x, y, w, h, phase)
		local view = Unlock.view(parent, item, x * K, y * K, w * K, h * K)
		local model = view:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
		local centre, size = (model:FindFirstChild("Appearance") or model):GetBoundingBox()
		local pose = POSE[item.kind] or POSE.default
		view.CurrentCamera.CFrame = CFrame.new(centre.Position) * CFrame.Angles(0, math.rad(pose[1]), 0)
			* CFrame.Angles(math.rad(pose[2]), 0, 0) * CFrame.new(0, 0, size.Magnitude / 2 / math.tan(math.rad(20)) * 1.05)
		move(view, "bob", phase)
	end
	-- Paper buy (at your level) or Unlock now for Robux, the Hangar's two ways (Paper short: the shop's note says how much).
	local function buyPaper(part)
		local short = part.paper_price - (game.Players.LocalPlayer:GetAttribute("Paper") or 0)
		if short > 0 then preview(string.format("%s costs %s Paper. You need %s more.", part.name, commas(part.paper_price), commas(short)))
		else api.action:FireServer("purchasePart", part.id) end
	end
	local function unlockNow(part) api.action:FireServer("buyProduct", "part_" .. part.id) end
	-- The parts you don't have yet (not the free ones or presets), lowest level first.
	local function lockedParts(owned)
		local list = {}
		for _, item in Unlock.items(0, 999) do
			if not item.free and not owned[item.part.id] then table.insert(list, item) end
		end
		return list
	end

	-- Your next part (docs/plan/SHOP-MONEY-PLAN.md F), the Featured card once the starter pack is gone: the part that
	-- last folded you (the fold screen's goal), else the part you're closest to buying, else the next level's part.
	local function nextPart(y, owned)
		local me = game.Players.LocalPlayer
		local level, paper = me:GetAttribute("Level") or 1, me:GetAttribute("Paper") or 0
		local locked, pick = lockedParts(owned), nil
		for _, item in locked do
			if item.part.id == me:GetAttribute("FoldGoal") then pick = item; break end
			if item.part.min_level <= level and (not pick or item.part.paper_price < pick.part.paper_price) then pick = item end
		end
		pick = pick or locked[1]
		if not pick then return y end
		local part = pick.part
		heading(y, "FEATURED")
		local card = Instance.new("Frame")
		card.Name, card.BackgroundTransparency, card.Position, card.Size = "NextPart", 1, UDim2.fromOffset(17 * K, (y + 55) * K), UDim2.fromOffset(1237 * K, 325 * K)
		card.Parent = content
		pic(card, "PaperL", Art.cardFeatured[1], 0, 0, 620, 325)
		pic(card, "PaperR", Art.cardFeatured[2], 618, 0, 1237, 325)
		backing(card, 35, 25, 305, 295)
		partView(card, pick, 50, 40, 240, 240, 0)
		say(card, "Tag", "YOUR NEXT PART", 340, 18, 920, 64, 36, { color = WHITE, outline = INK })
		say(card, "Name", part.name, 340, 62, 920, 142, 70, { color = Color3.fromRGB(255, 222, 40), outline = INK, thick = 5 })
		local gap = part.paper_price - paper
		say(card, "Line", level < part.min_level and "Unlocks at level " .. part.min_level .. ", or unlock it now"
			or gap > 0 and commas(gap) .. " more Paper, or unlock it now" or "You have the Paper: buy it now!", 330, 160, 930, 215, 38, { loud = true })
		if level >= part.min_level then
			buy(card, "BuyPaper", 977, 60, 1217, 165, 0, 44, function() buyPaper(part) end, commas(part.paper_price) .. " Paper")
		end
		buy(card, "Buy", 977, 185, 1217, 295, Customize.unlockRobux(part.paper_price), 74, function() unlockNow(part) end)
		return y + 380
	end

	-- Today's parts (docs/plan/SHOP-MONEY-PLAN.md H): three of the six parts nearest your level that you don't have,
	-- a new three every day at UTC midnight (the daily gift's day) for everyone; which three is personal.
	local function todaysParts(y, owned)
		local me = game.Players.LocalPlayer
		local level, day = me:GetAttribute("Level") or 1, now() // 86400
		local near = lockedParts(owned)
		table.sort(near, function(a, b) return math.abs(a.part.min_level - level) < math.abs(b.part.min_level - level) end)
		local pool = table.move(near, 1, math.min(6, #near), 1, {})
		if #pool == 0 then return y end
		heading(y, "TODAY'S PARTS")
		local rng = Random.new(day * 7919 + me.UserId) -- ponytail: picked on the client; a server pick if it ever matters
		for i = 1, math.min(3, #pool) do
			local item = table.remove(pool, rng:NextInteger(1, #pool))
			local part, x0, top = item.part, 22 + (i - 1) * 411, y + 125
			local card = pic(content, "Today" .. i, Art.itemSquare, x0, top, x0 + 405, top + 405)
			say(card, "Name", part.name, 15, 12, 390, 66, 40, { loud = true })
			backing(card, 100, 64, 305, 269)
			partView(card, item, 70, 64, 265, 205, i)
			pic(card, "PricePaper", Art.labelDark, 50, 272, 355, 318)
			say(card, "Price", level < part.min_level and "Unlocks at level " .. part.min_level or commas(part.paper_price) .. " Paper", 50, 272, 355, 318, 32, { color = WHITE })
			if level >= part.min_level then
				buy(card, "BuyPaper", 30, 326, 195, 392, 0, 40, function() buyPaper(part) end, "Buy")
				buy(card, "Buy", 210, 326, 375, 392, Customize.unlockRobux(part.paper_price), 44, function() unlockNow(part) end)
			else
				buy(card, "Buy", 102, 326, 302, 392, Customize.unlockRobux(part.paper_price), 44, function() unlockNow(part) end)
			end
		end
		-- New parts in: on dark paper (chalk words were hard to read on the board, Alan 2026-11-12), under the heading.
		pic(content, "TodayTimerPaper", Art.labelDark, 432, y + 58, 862, y + 112)
		move(say(content, "TodayTimer", "", 432, y + 58, 862, y + 112, 34, { color = WHITE, grow = true }), "timer", 0,
			{ ends = (day + 1) * 86400, short = true, prefix = "New parts in " })
		return y + 545
	end

	local function passes(y, boosts)
		heading(y, "PASSES")
		for i, info in { { "permanent_2x_paper", Art.cardPassGreen, Art.iconPassPaper, "2x Paper Forever", "Double Paper from\nevery match!", "permanentPaper" },
			{ "permanent_2x_xp", Art.cardPassPurple, Art.iconPassStar, "2x XP Forever", "Double XP from\nevery match!", "permanentXP" } } do
			local key, paper, icon, title, words, owned = table.unpack(info)
			local card = pic(content, "Pass" .. i, paper, 17 + (i - 1) * 625, y + 47, 632 + (i - 1) * 625, y + 222)
			backing(card, 15, 13, 165, 158)
			move(fit(pic(card, "Icon", icon, 35, 33, 145, 143)), "bob", i)
			ticks(card, 5, 22, 45, 62, -45, i * 0.7)
			pic(card, "TwoPill", Art.labelDark, 105, 110, 170, 150)
			say(card, "Two", "x2", 105, 110, 170, 150, 30, { color = WHITE })
			say(card, "Name", title, 175, 6, 600, 54, 44, { left = true, color = WHITE, outline = INK, thick = 4 })
			local one, two = words:match("^(.-)\n(.*)$")
			say(card, "Desc1", one, 185, 56, 500, 84, 28, { left = true }); say(card, "Desc2", two, 185, 82, 500, 110, 28, { left = true })
			gift(card, 370, 100, 430, 163)
			if boosts[owned] then
				buy(card, "Buy", 440, 88, 605, 163, 0, 40, function() end, "OWNED")
			else
				buy(card, "Buy", 440, 88, 605, 163, PRICE[key], 48, function() api.buy(key) end)
			end
		end
		return y + 232
	end

	local function paperPacks(y)
		heading(y, "PAPER")
		-- Biggest first, so the first price seen is the big one; the 7,500 decoy sits beside the 15,000 it sells
		-- (docs/plan/SHOP-MONEY-PLAN.md). Three to a row; a short last row is centred.
		local packs = {}
		for _, product in Commerce.products do
			if product.benefit == "paper_balance" then table.insert(packs, product) end
		end
		table.sort(packs, function(a, b) return a.amount > b.amount end)
		local used = string.split(game.Players.LocalPlayer:GetAttribute("FirstBuysUsed") or "", ",")
		for i, product in packs do
			local row, col = (i - 1) // 3, (i - 1) % 3
			local inRow = math.min(3, #packs - row * 3)
			local x0, top = 22 + col * 411 + (3 - inRow) * 411 / 2, y + 55 + row * 350
			-- The first buy of each pack gives double (the server decides; this only shows it).
			local first = not table.find(used, product.key)
			local card = pic(content, product.key, Art.cardPackOrange, x0, top, x0 + 405, top + 340)
			move(pic(card, "Rays", Art.rays, 55, 8, 355, 218), "spin", i)
			move(fit(pic(card, "Icon", Art[PACK_ICON[product.key] or "iconPaperSmall"], 105, 58, 310, 205)), "bob", i)
			pic(card, "AmountPaper", Art.labelDark, 55, 205, 360, 253)
			say(card, "Amount", "+" .. commas(product.amount * (first and 2 or 1)) .. " Paper", 55, 205, 360, 253, 40, { color = WHITE })
			gift(card, 55, 260, 130, 330)
			buy(card, "Buy", 143, 257, 355, 330, PRICE[product.key], 60, function() api.buy(product.key) end)
			if first then
				local burst = pic(card, "FirstBuy", Art.burstNew, -12, -18, 153, 94, -10)
				say(burst, "Words1", "First buy", 0, 16, 165, 56, 28, { loud = true })
				say(burst, "Words2", "2x!", 0, 48, 165, 98, 40, { loud = true })
				move(burst, "wobble")
			end
			if BADGE[product.key] then
				local most = BADGE[product.key] == "Most Value"
				local x = first and 180 or (most and 93 or 22) -- beside the First buy burst, never touching it
				sticker(card, BADGE[product.key], x, most and -10 or -8, x + (first and 218 or 230), most and 55 or 70, first and 36 or 40, -6)
			end
		end
		return y + 55 + math.ceil(#packs / 3) * 350
	end

	local function boostRows(y, boosts)
		heading(y, "BOOSTS")
		y += 60
		for _, row in { { "paper", "2x Paper", Art.cardBoostGreen, Art.iconClockPaper, "permanentPaper" }, { "xp", "2x XP", Art.cardBoostBlue, Art.iconClockStar, "permanentXP" } } do
			local resource, title, paper, icon, forever = table.unpack(row)
			local left = (boosts[resource .. "Seconds"] or 0)
			if boosts[forever] then
				-- Timed boosts do nothing once a boost is forever (the server refuses them too).
				say(content, "Forever" .. resource, title .. ": yours forever", 22, y, 1250, y + 40, 34, CHALKY)
				y += 50
			else
				if left > 0 then
					say(content, "Left" .. resource, title .. ": " .. math.floor(left / 60) .. " min left", 22, y - 8, 1250, y + 22, 30, CHALKY)
					y += 26
				end
				local i = 0
				for _, product in Commerce.products do
					if product.benefit == resource .. "_seconds" then
						i += 1
						local x0 = 22 + (i - 1) * 246
						local badge = BADGE[product.key]
						local card = pic(content, product.key, paper, x0, y, x0 + 237, y + 250)
						move(pic(card, "Rays", Art.rays, 25, 50, 212, 165), "spin", i * 0.9)
						say(card, "Name", title, 0, badge and 27 or 15, 237, badge and 72 or 60, 40, { color = WHITE, outline = INK, thick = 4 })
						move(fit(pic(card, "Icon", icon, 40, 65, 197, 153)), "bob", i * 0.6)
						pic(card, "TimePaper", Art.labelDark, 35, 153, 205, 187)
						say(card, "Time", duration(product.amount), 35, 153, 205, 187, 30, { color = WHITE })
						gift(card, 15, 190, 70, 243)
						buy(card, "Buy", 80, 190, 222, 243, PRICE[product.key], 42, function() api.buy(product.key) end)
						if badge then sticker(card, badge, 30, -25, 205, 20, 30, -4) end
					end
				end
				y += 275
			end
		end
		return y
	end

	-- ===== The animation loop (only while the shop is open) =====
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		if not cover.Visible then return end
		clock += dt
		local t = clock
		for _, m in moving do
			local inst, p = m.inst, m.phase
			if m.kind == "spin" then -- rays: turn slowly and breathe
				local s = 1 + 0.05 * math.sin(t * 2 + p)
				inst.Rotation = m.rot + t * 25 + p * 40
				inst.Size = UDim2.fromOffset(m.size.X.Offset * s, m.size.Y.Offset * s)
			elseif m.kind == "bob" then
				inst.Position = m.pos + UDim2.fromOffset(0, 4 * K * math.sin(t * 2.6 + p))
			elseif m.kind == "twist" then -- little ray ticks: twist and flicker
				local s = 1 + 0.12 * math.sin(t * 3.1 + p)
				inst.Rotation = m.rot + 8 * math.sin(t * 1.9 + p)
				inst.Size = UDim2.fromOffset(m.size.X.Offset * s, m.size.Y.Offset * s)
			elseif m.kind == "twinkle" then
				local s = 0.75 + 0.35 * math.abs(math.sin(t * 1.7 + p))
				inst.Rotation = m.rot + 18 * math.sin(t * 1.3 + p)
				inst.Size = UDim2.fromOffset(m.size.X.Offset * s, m.size.Y.Offset * s)
			elseif m.kind == "wobble" then
				inst.Rotation = m.rot + 5 * math.sin(t * 3)
			elseif m.kind == "pulse" then
				local s = 1 + 0.04 * math.sin(t * 4)
				if inst.Rotation == m.rot then inst.Size = UDim2.fromOffset(m.size.X.Offset * s, m.size.Y.Offset * s) end -- (not while the mouse is on it)
			elseif m.kind == "shine" then
				inst.Position = UDim2.fromScale(-0.2 + 1.4 * math.clamp((t % 4) / 1.2, 0, 1), 0.5)
			elseif m.kind == "timer" then
				local left = math.max(0, m.ends - now())
				inst.Text = (m.prefix or "") .. (m.short and string.format("%dh %02dm", left // 3600, left % 3600 // 60)
					or string.format("%dd %dh %02dm", left // 86400, left % 86400 // 3600, left % 3600 // 60))
			end
		end
		if #rainbow > 0 then -- "Most Value": the rainbow's colours slide along
			local keys = {}
			for i = 0, 6 do keys[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6 - t * 0.25) % 1, 0.75, 1)) end
			local colours = ColorSequence.new(keys)
			for _, gradient in rainbow do gradient.Color = colours end
		end
	end)
	-- The window pops open with a springy grow.
	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		if not cover.Visible then return end
		pop.Scale = 0.88
		TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)

	local self = { frame = cover }
	local shown, lastProfile
	function self.update(player, profile)
		lastProfile = profile
		showNote()
		-- Redraw only on a change, so a click never lands on a button that was just replaced.
		local boosts = profile and profile.boosts or {}
		local me = game.Players.LocalPlayer
		local owned = profile and profile.ownership or {}
		local count = 0
		for _ in owned do count += 1 end
		local key = game:GetService("HttpService"):JSONEncode({ boosts.permanentXP, boosts.permanentPaper, count,
			me:GetAttribute("Paper"), me:GetAttribute("Level"), me:GetAttribute("FoldGoal"), now() // 86400,
			math.floor((boosts.xpSeconds or 0) / 60), math.floor((boosts.paperSeconds or 0) / 60),
			me:GetAttribute("DailyGiftNext"), me:GetAttribute("DailyGiftReady"), me:GetAttribute("StarterPackEnds"), me:GetAttribute("FirstBuysUsed") })
		if key == shown then return end
		shown = key
		for _, child in content:GetChildren() do child:Destroy() end
		table.clear(moving); table.clear(rainbow)
		local y = 2
		if PREVIEW then
			sections.Featured = y * K
			local starter = me:GetAttribute("StarterPackEnds")
			y = (starter == nil or starter > now()) and featured(y) or nextPart(y, owned)
			y = freeGift(y)
			y = todaysParts(y, owned)
		end
		sections.Passes = y * K
		if not PREVIEW then sections.Featured = y * K end
		y = passes(y, boosts)
		sections.Paper = y * K
		y = paperPacks(y)
		sections.Boosts = y * K
		y = boostRows(y, boosts)
		content.Size = UDim2.fromOffset((1408 - 118) * K, (y + 20) * K)
		scroll.CanvasSize = UDim2.fromOffset(0, (y + 20) * K)
		scrolled()
	end
	-- The server's gift, starter pack and first-buy answers arrive as attributes: redraw when one changes.
	local WATCHED = { DailyGiftNext = true, DailyGiftReady = true, StarterPackEnds = true, FirstBuysUsed = true }
	game.Players.LocalPlayer.AttributeChanged:Connect(function(name)
		if WATCHED[name] and cover.Visible then self.update(game.Players.LocalPlayer, lastProfile) end
	end)
	return self
end

return ShopScreen
