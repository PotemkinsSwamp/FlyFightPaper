-- Classroom chest picker and reward sheet. Ownership, spending and the draw are server decisions.
local Root = game.ReplicatedStorage.FlyFightPaper
local Assets = require(Root.Shared.UIAssets)
local Looks = require(Root.Shared.LooksRules)
local Progress = require(Root.Shared.ChestProgress)
local Commerce = require(Root.Generated.Commerce)
local Rules = require(Root.Shared.CommerceRules)
local Daily = require(Root.Generated.Economy).daily_gift
local Opening = require(script.Parent.ChestOpening)
local PaperUI = require(script.Parent.PaperUI)

local Chests = {}
local TIERS = { "common", "rare", "legendary", "mythical" }
local TIER_NAMES = { common = "Common", rare = "Rare", legendary = "Legendary", mythical = "Mythical" }
local TIER_PAPER = {
	common = Color3.fromRGB(236, 235, 213), rare = Color3.fromRGB(155, 218, 250),
	legendary = Color3.fromRGB(255, 195, 105), mythical = Color3.fromRGB(219, 169, 246),
}
local catalog = Rules.catalog(Commerce)

function Chests.purchaseLabel(profile, key, previewPrice)
	if not profile or profile.chestPaperAllowed ~= true then return nil end
	if profile.mock and Commerce.mode == "mock" then return previewPrice .. " Robux" end
	local offer = catalog and catalog.byKey[key]
	if catalog and catalog.mode == "live" and catalog.authorized and offer and offer.enabled and offer.productID then
		return "Buy with Robux"
	end
	return nil
end

function Chests.baseName(chest)
	return (chest.name:gsub(" Treasure Chest$", ""))
end

local function familyName(chest)
	return chest.family == "trail" and "Trail" or "Skin"
end

local function title(chest)
	return Chests.baseName(chest) .. " " .. familyName(chest) .. " Chest"
end

local function paperValue(value)
	return PaperUI.commas(value) .. " Paper"
end

local function percentage(value)
	return (string.format("%.4f", value):gsub("0+$", ""):gsub("%.$", "")) .. "%"
end

local function center(label)
	label.TextXAlignment = Enum.TextXAlignment.Center
	return label
end

local function chestPicture(ui, parent, chest, x, y, w, h, name)
	local image = ui.image(parent, name or "ChestPicture", Assets.hangarShelf.chestAtlas, x, y, w, h)
	Opening.picture(image, chest)
	return image
end

function Chests.show(ctx, tier, family, id, page, previewPrice)
	family = family or ctx.state.slot or "skin"
	local selected = id and Looks.chest(id)
	if not selected then
		for _, chest in Looks.config().chests do
			if chest.family == family and (not tier or chest.weights[tier] > 0) then selected = chest; break end
		end
	end
	if not selected then return end
	ctx.state.chestPanel = {selected = selected, page = page, previewPrice = previewPrice}
	ctx.state.chestReward = nil
	game.Players.LocalPlayer:SetAttribute("MenuMessage", nil)
	ctx.render()
end

local open

function Chests.receive(ctx)
	local state, wallet = ctx.state, ctx.profile and ctx.profile.chests
	local panel = state.chestPanel
	if not wallet or not panel then return end
	if panel.boughtAt ~= nil and wallet.paidStock and (wallet.paidStock[panel.selected.id] or 0) > panel.boughtAt then
		panel.boughtAt, panel.page = nil, nil
		task.defer(function()
			if state.chestPanel == panel and not panel.expected then open(ctx, "paidStock") end
		end)
		return
	end
	if panel.expected == nil or wallet.opened <= panel.expected then return end
	local item = Looks.item(wallet.lastSkin)
	state.chestPanel = nil
	if item and ctx.profile.looks.owned[item.id] and wallet.lastChest == panel.selected.id then
		state.chestReward = {chest = panel.selected, skin = item, refund = wallet.lastRefund or 0}
		state.tryLook, state.slot, state.focusLook = item, item.kind, item.id
	end
end

function Chests.reward(content, ctx)
	local ui, reward = ctx.ui, ctx.state.chestReward
	local paper = ui.image(content, "PrizePaper", Assets.unlock.sheet, 720, 220, 480, 625, 0)
	paper.ScaleType = Enum.ScaleType.Stretch
	paper.ZIndex = 2
	center(PaperUI.loud(ui.words(paper, "Title", reward.refund > 0 and "Already owned" or "You found", 50, 65, 390, 72, 45)))
	chestPicture(ui, paper, reward.chest, 104, 136, 288, 240)
	local name = center(PaperUI.loud(ui.words(paper, "Skin", reward.skin.name, 54, 378, 379, 77, 53)))
	name.TextWrapped, name.TextScaled = true, true
	local cap = name:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint", name)
	cap.MaxTextSize = 54
	center(ui.words(paper, "Tier", TIER_NAMES[reward.skin.tier] .. " " .. reward.skin.kind, 55, 466, 380, 58, 39))
	local extra = reward.skin.trail and Looks.item(reward.skin.trail)
	if reward.refund > 0 then
		center(PaperUI.loud(ui.words(paper, "Refund", "+" .. paperValue(reward.refund), 48, 530, 388, 57, 38)))
	elseif extra then
		local trail = center(ui.words(paper, "Trail", "Includes " .. extra.name, 48, 530, 388, 48, 30))
		trail.TextWrapped = true
	end
end

local function go(ctx, page)
	local panel = ctx.state.chestPanel
	if panel.expected ~= nil and page ~= nil then return end
	if page == nil then panel.boughtAt = nil end
	panel.page = page
	ctx.render()
end

open = function(ctx, source)
	local panel, wallet = ctx.state.chestPanel, ctx.profile.chests
	if not panel or not wallet then return end
	if panel.expected ~= nil and (not panel.retry or source ~= panel.source) then return end
	if source ~= "earned" and ctx.profile.chestPaperAllowed ~= true then return end
	if source == "paper" and panel.page ~= "buy" then return end
	panel.expected, panel.source, panel.retry = panel.expected or wallet.opened, source, nil
	local sent = (panel.sent or 0) + 1
	panel.sent = sent
	game.Players.LocalPlayer:SetAttribute("MenuMessage", nil)
	ctx.api.action:FireServer("openChest", { chest = panel.selected.id, opened = panel.expected, source = source })
	ctx.render()
	task.delay(5, function()
		if ctx.state.chestPanel == panel and panel.expected ~= nil and sent == panel.sent then
			panel.retry = true
			ctx.render()
		end
	end)
end

local function action(ui, parent, id, text, x, y, w, h, enabled, callback, size)
	local art = enabled and Assets.hangar.buttonGreen or Assets.unlock.buttonCream
	local btn = ui.button(parent, id, art, text, x, y, w, h, -1, function()
		if enabled then callback() end
	end, size or 43)
	btn.ImageColor3 = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(169, 172, 164)
	return btn
end

-- Use the Shop's own two payment signs everywhere a chest can be bought.
local function payment(ui, parent, id, currency, text, x, y, w, h, enabled, callback, size)
	local robux = currency == "robux"
	local art = robux and Assets.shop.buyGreen or Assets.shop.labelDark
	local btn = ui.button(parent, id, art, robux and "" or text, x, y, w, h, 0, function()
		if enabled then callback() end
	end, size)
	btn.ImageColor3 = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(171, 172, 169)
	if not robux then
		btn.Label.TextColor3 = Color3.new(1, 1, 1)
		return
	end
	btn.ScaleType = Enum.ScaleType.Stretch
	local row = ui.instance(btn, "Price", "Frame")
	row.Size, row.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	local layout = ui.instance(row, "Layout", "UIListLayout")
	layout.FillDirection, layout.SortOrder = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment, layout.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	local icon = ui.image(row, "Robux", "rbxasset://textures/ui/common/robux@3x.png", 0, 0, size, size)
	icon.LayoutOrder, icon.ImageColor3 = 1, PaperUI.INK
	local amount = PaperUI.loud(ui.words(row, "Amount", text, 0, 0, 0, h, size))
	amount.AutomaticSize, amount.LayoutOrder = Enum.AutomaticSize.X, 2
end

local function backButton(ctx, sheet, x)
	ctx.ui.button(sheet, "ChestBack", Assets.range.stripRed, "Back", x, 131, 262, 77, -1, function()
		go(ctx, nil)
	end, 44)
end

local function chestShelf(ctx, sheet)
	local ui, panel, wallet = ctx.ui, ctx.state.chestPanel, ctx.profile.chests
	local selected, balance = panel.selected, ctx.profile.paper or 0
	local busy = panel.expected ~= nil
	local function switch(chest)
		if busy or panel.selected == chest then return end
		panel.boughtAt, panel.selected = nil, chest
		ctx.render()
	end
	center(PaperUI.loud(ui.words(sheet, "Heading", "Treasure chests", 130, 126, 652, 72, 55)))
	for i, family in {"skin", "trail"} do
		local key = family == "trail" and "trail_" .. selected.base or selected.base
		ui.button(sheet, family .. "Family", family == selected.family and Assets.hangar.buttonGreen or Assets.unlock.buttonCream,
			family == "skin" and "Skins" or "Trails", 143 + (i-1)*324, 202, 306, 83, 0, function() switch(Looks.chest(key)) end, 42)
	end
	local i = 0
	for _, chest in Looks.config().chests do
		if chest.family ~= selected.family then continue end
		local x, y = 131 + i % 2 * 335, 306 + math.floor(i / 2) * 232
		local card = ui.button(sheet, chest.id, chest == selected and Assets.hangar.cardSelectedSquare or Assets.hangar.cardSquare,
			"", x, y, 318, 221, 0, function() switch(chest) end)
		chestPicture(ui, card, chest, 61, 17, 196, 116)
		center(PaperUI.loud(ui.words(card, "Name", Chests.baseName(chest), 28, 130, 262, 43, 37)))
		center(ui.words(card, "Stock", string.format("%d earned", wallet and wallet.stock[chest.base] or 0), 29, 169, 260, 41, 31))
		i += 1
	end
	ui.button(sheet, "ChestProgress", Assets.mainmenu.strip.blue, "How to earn chests", 166, 807, 584, 108, -1, function() go(ctx, "progress") end, 44)

	center(PaperUI.loud(ui.words(sheet, "ChestTitle", title(selected), 808, 136, 693, 74, 50)))
	center(ui.words(sheet, "Balance", "Your Paper  " .. PaperUI.commas(balance), 841, 213, 616, 56, 40))
	local odds, row = Looks.chestOdds(selected.id), 0
	for _, tier in TIERS do
		if not odds[tier] or odds[tier] <= 0 then continue end
		local x, y = 850 + row % 2 * 324, 287 + math.floor(row / 2) * 54
		ui.words(sheet, tier, TIER_NAMES[tier], x, y, 166, 50, 36)
		local chance = ui.words(sheet, tier .. "Odds", percentage(odds[tier]), x + 151, y, 126, 50, 35)
		chance.TextXAlignment = Enum.TextXAlignment.Right
		row += 1
	end
	ui.button(sheet, "ChestOdds", Assets.mainmenu.strip.blue, "Prizes & odds", 892, 412, 523, 86, 0, function() go(ctx, "odds") end, 42)
	local count = wallet and wallet.stock[selected.base] or 0
	local paid = wallet and wallet.paidStock and wallet.paidStock[selected.id] or 0
	local canPay = ctx.profile.chestPaperAllowed == true
	local label = busy and panel.source == "earned" and (panel.retry and "Retry opening" or "Opening") or "Open earned (" .. count .. ")"
	action(ui, sheet, "OpenEarned", label, 854, 526, 605, 92, count > 0 and (not busy or panel.retry), function() open(ctx, "earned") end)
	if paid > 0 and canPay then
		action(ui, sheet, "OpenPurchased", "Open purchased (" .. paid .. ")", 854, 619, 605, 88, not busy or panel.retry, function() open(ctx, "paidStock") end)
	end
	local notice = nil
	if canPay then
		payment(ui, sheet, "BuyChest", "paper", paperValue(selected.cost), 828, 725, 338, 92, balance >= selected.cost and not busy,
			function() go(ctx, "buy") end, 37)
		local price = Chests.purchaseLabel(ctx.profile, "chest_" .. selected.id, selected.robux)
		if price then
			local amount = price == "Buy with Robux" and "Robux" or tostring(selected.robux)
			payment(ui, sheet, "BuyRobux", "robux", amount, 1182, 738, 264, 66, not busy,
				function() go(ctx, "robux") end, 37)
		end
		if balance < selected.cost then notice = "Need " .. paperValue(selected.cost - balance) .. " more for the Paper option." end
	else
		notice = "Earn this chest through play."
	end
	if panel.retry then notice = game.Players.LocalPlayer:GetAttribute("MenuMessage") or "Still waiting. You can retry." end
	if notice then
		local line = center(ui.words(sheet, "Status", notice, 828, 837, 647, 69, 32))
		line.TextWrapped = true
	end
end

local function oddsPage(ctx, sheet)
	local ui, panel = ctx.ui, ctx.state.chestPanel
	local selected = panel.selected
	local paying = ctx.profile.chestPaperAllowed == true
	local costsPaper = panel.page == "buy" and paying
	local robux = (panel.page == "robux" or panel.page == "starter") and paying
	local starter = panel.page == "starter"
	local balance = ctx.profile.paper or 0
	local odds, counts = Looks.chestOdds(selected.id)
	backButton(ctx, sheet, 1356)
	chestPicture(ui, sheet, selected, 436, 104, 211, 180)
	local heading = costsPaper and "Confirm Paper purchase" or robux and "Confirm Robux purchase" or "Prizes & odds"
	ui.words(sheet, "PageHeading", heading, 657, 128, 674, 49, 36)
	PaperUI.loud(ui.words(sheet, "OddsTitle", title(selected), 651, 175, 680, 76, 57))
	local sentence = costsPaper and ("Open for " .. paperValue(selected.cost) .. ". Your balance is " .. paperValue(balance) .. ".")
		or starter and "The Starter Pack includes this chest. Open it to get one skin."
		or ("Get one " .. familyName(selected):lower() .. " per opening. If you already own it, you get Paper.")
	center(ui.words(sheet, "Terms", sentence, 171, 265, 1335, 55, 36))

	-- Header and scroll body share the same four column centres, including on a phone.
	local listX, listWidth = 183, 1326
	local function columns(parent, prefix, x, y, name, chance, refund, collection, header)
		local size = header and 37 or 36
		local item = ui.words(parent, prefix .. "Name", name, x + 45, y, 439, 52, size)
		local oddsText = center(ui.words(parent, prefix .. "Odds", chance, x + 500, y, 202, 52, size))
		local paper = center(ui.words(parent, prefix .. "Refund", refund, x + 725, y, 259, 52, size))
		local status = center(ui.words(parent, prefix .. "Collection", collection, x + 1000, y, 278, 52, size))
		if header then
			for _, label in {item, oddsText, paper, status} do PaperUI.loud(label) end
		end
	end
	columns(sheet, "Heading", listX, 332, familyName(selected), "Chance", "If duplicate", "Collection", true)
	local list = ui.instance(sheet, "PossibleSkins", "ScrollingFrame")
	local listHeight = (costsPaper or robux) and 371 or 471
	list.Position, list.Size = UDim2.fromOffset(listX, 394), UDim2.fromOffset(listWidth, listHeight)
	list.BackgroundTransparency, list.BorderSizePixel = 1, 0
	list.ScrollBarImageColor3, list.ScrollBarThickness = PaperUI.INK, 13
	list.ScrollingDirection, list.ElasticBehavior = Enum.ScrollingDirection.Y, Enum.ElasticBehavior.Never
	local lastTier, y = nil, 0
	for _, item in Looks.chestItems(selected.id) do
		local tier = item.tier
		if tier ~= lastTier then
			if lastTier then y += 15 end
			local divider = ui.image(list, "Divider_" .. tier, Assets.ingame.tapeLabel, 6, y, listWidth - 37, 63)
			divider.ScaleType, divider.ImageColor3 = Enum.ScaleType.Stretch, TIER_PAPER[tier]
			PaperUI.loud(ui.words(divider, "Tier", TIER_NAMES[tier], 52, 4, 366, 54, 38))
			center(PaperUI.loud(ui.words(divider, "TierOdds", percentage(odds[tier]) .. " total", 468, 4, 256, 54, 36)))
			y += 69
			lastTier = tier
		end
		local chance = percentage(odds[tier] / counts[tier])
		local status = ctx.profile.looks.owned[item.id] and "Owned" or "Unowned"
		columns(list, item.id, 0, y, item.name, chance, paperValue(Looks.duplicateRefund(item.id)), status, false)
		y += 55
	end
	list.CanvasSize = UDim2.fromOffset(0, y + 7)
	if list:GetAttribute("Chest") ~= selected.id then
		list:SetAttribute("Chest", selected.id)
		list.CanvasPosition = Vector2.zero
	end
	center(ui.words(sheet, "Rounding", "Item chances are rounded to four decimal places.", 208, 402 + listHeight, 1277, 48, 30))
	if costsPaper then
		local busy = panel.expected ~= nil
		local allowed = ctx.profile.chests ~= nil and balance >= selected.cost and (not busy or panel.retry)
		local label = busy and (panel.retry and "Retry this opening" or "Opening") or "Spend " .. paperValue(selected.cost)
		payment(ui, sheet, "ConfirmPaper", "paper", label, 201, 835, 615, 96, allowed, function() open(ctx, "paper") end, 43)
		local status = panel.retry and (game.Players.LocalPlayer:GetAttribute("MenuMessage") or "Still waiting. You can retry.")
			or balance < selected.cost and "Need " .. paperValue(selected.cost - balance) .. " more."
		if status then
			local text = center(ui.words(sheet, "Status", status, 839, 839, 590, 83, 34))
			text.TextWrapped = true
		end
	elseif robux then
		local practice = ctx.profile.mock == true
		local key = starter and "starter_pack" or "chest_" .. selected.id
		local price = starter and panel.previewPrice or selected.robux
		local label = practice and ("Practice buy " .. tostring(price)) or "Buy with Robux"
		payment(ui, sheet, "ConfirmRobux", "robux", label, 266, 829, 478, 103, panel.boughtAt == nil and Chests.purchaseLabel(ctx.profile, key, price) ~= nil, function()
			if panel.boughtAt ~= nil then return end
			panel.boughtAt = ctx.profile.chests.paidStock and ctx.profile.chests.paidStock[selected.id] or 0
			game.Players.LocalPlayer:SetAttribute("MenuMessage", nil)
			ctx.api.action:FireServer(practice and "mockProduct" or "buyProduct", key)
			ctx.render()
		end, 42)
		local help = practice and "Studio practice. No Robux are spent." or "Roblox shows the final price before purchase."
		if panel.boughtAt ~= nil then help = game.Players.LocalPlayer:GetAttribute("MenuMessage") or "Waiting for the purchase. Back returns to the chests." end
		local line = center(ui.words(sheet, "Status", help, 853, 828, 593, 98, 32))
		line.TextWrapped = true
	end
end

local function progressPage(ctx, sheet)
	local ui, wallet = ctx.ui, ctx.profile.chests
	backButton(ctx, sheet, 160)
	center(PaperUI.loud(ui.words(sheet, "GoalsTitle", "Earn treasure chests", 448, 132, 829, 76, 53)))
	center(ui.words(sheet, "GoalsNote", "Claim your free gift each day in the Shop.", 216, 232, 1237, 59, 40))
	local streak = ctx.profile.dailyGift
	local mission = Progress.status(wallet and wallet.progress or Progress.defaults(), math.floor(workspace:GetServerTimeNow())).mission
	for i, base in Daily.chests do
		local y = 316 + (i - 1) * 85
		chestPicture(ui, sheet, Looks.chest(base), 196, y, 132, 82, base.."Picture")
		ui.words(sheet, base.."Rule", "Day " .. i * 7, 381, y + 10, 350, 62, 40)
		PaperUI.loud(ui.words(sheet, base.."Reward", Chests.baseName(Looks.chest(base)) .. " chest", 800, y + 10, 570, 62, 43))
	end
	local day = streak and Rules.dailyGiftDay(streak, math.floor(workspace:GetServerTimeNow()/86400)) or 1
	center(ui.words(sheet, "Streak", "Day " .. day .. " of 28. Missing a daily claim restarts the streak.", 190, 666, 1289, 62, 37))
	center(PaperUI.loud(ui.words(sheet, "WeeklyMission", "Weekly match mission", 373, 746, 930, 61, 46)))
	center(ui.words(sheet, "Mission", string.format("%d / %d qualifying matches for a Sticker chest", mission.count, mission.target), 211, 819, 1245, 67, 38))
end

function Chests.draw(ctx)
	Opening.prepare(ctx.state.chestPanel.selected)
	local ui = ctx.ui
	local dim = ui.instance(ctx.side.Parent, "ChestCover", "TextButton")
	dim.Text, dim.AutoButtonColor, dim.BorderSizePixel = "", false, 0
	dim.BackgroundColor3, dim.BackgroundTransparency = Color3.fromRGB(32, 28, 24), 0.32
	dim.Position, dim.Size, dim.ZIndex = UDim2.fromOffset(-1920, -1080), UDim2.fromOffset(5760, 3240), 20
	local sheet = ui.image(dim, "ChestSheet", Assets.hangarShelf.statsWide, 1920 + 102, 1080 + 13, 1716, 1054)
	sheet.ScaleType = Enum.ScaleType.Stretch
	local page = ctx.state.chestPanel.page
	if page == "progress" then
		progressPage(ctx, sheet)
	elseif page == "buy" or page == "robux" or page == "starter" or page == "odds" then
		oddsPage(ctx, sheet)
		return
	else
		chestShelf(ctx, sheet)
	end
	ui.button(sheet, "CloseChest", Assets.mainmenu.boxRed, "X", 1531, 131, 87, 87, 1, function()
		ctx.state.chestPanel = nil
		ctx.render()
	end, 50)
end

return Chests
