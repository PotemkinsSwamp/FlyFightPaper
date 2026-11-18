-- Classroom chest picker and reward sheet. Ownership, spending and the draw are server decisions.
local Root = game.ReplicatedStorage.FlyFightPaper
local Assets = require(Root.Shared.UIAssets)
local Looks = require(Root.Shared.LooksRules)
local Progress = require(Root.Shared.ChestProgress)
local PaperUI = require(script.Parent.PaperUI)

local Chests = {}
local TIERS = { "common", "rare", "legendary", "mythical" }
local TIER_NAMES = { common = "Common", rare = "Rare", legendary = "Legendary", mythical = "Mythical" }
local CHEST_CELLS = {
	paper = Vector2.new(0, 0), sticker = Vector2.new(512, 0),
	blue_ribbon = Vector2.new(0, 512), golden_star = Vector2.new(512, 512),
}

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

local function chestPicture(ui, parent, id, x, y, w, h, name)
	local image = ui.image(parent, name or "ChestPicture", Assets.hangarShelf.chestAtlas, x, y, w, h)
	image.ImageRectSize, image.ImageRectOffset = Vector2.new(512, 512), CHEST_CELLS[id]
	return image
end

function Chests.show(ctx, tier)
	local choices = Looks.config().chests
	local selected = choices[1]
	if tier then
		for _, chest in choices do
			if (chest.weights[tier] or 0) > 0 then selected = chest; break end
		end
	end
	ctx.state.chestPanel = { selected = selected }
	ctx.state.chestReward = nil
	game.Players.LocalPlayer:SetAttribute("MenuMessage", nil)
	ctx.render()
end

-- The saved sequence, ownership and award arrive in the same profile. Ignore earlier snapshots.
function Chests.receive(ctx)
	local state, wallet = ctx.state, ctx.profile.chests
	local panel = state.chestPanel
	if not wallet or not panel or panel.expected == nil or wallet.opened <= panel.expected then return end
	local skin = Looks.item(wallet.lastSkin)
	if not skin or not ctx.profile.looks.owned[skin.id] or wallet.lastChest ~= panel.selected.id then
		state.chestPanel = nil
		return
	end
	state.chestReward = { chest = panel.selected, skin = skin, refund = wallet.lastRefund or 0 }
	state.tryLook, state.slot, state.focusLook, state.chestPanel = skin, "skin", skin.id, nil
end

function Chests.reward(content, ctx)
	local ui, reward = ctx.ui, ctx.state.chestReward
	local paper = ui.image(content, "PrizePaper", Assets.unlock.sheet, 720, 220, 480, 625, 0)
	paper.ScaleType = Enum.ScaleType.Stretch
	paper.ZIndex = 2
	center(PaperUI.loud(ui.words(paper, "Title", reward.refund > 0 and "Already owned" or "You found", 50, 65, 390, 72, 45)))
	chestPicture(ui, paper, reward.chest.id, 104, 136, 288, 240)
	local name = center(PaperUI.loud(ui.words(paper, "Skin", reward.skin.name, 54, 378, 379, 77, 53)))
	name.TextWrapped, name.TextScaled = true, true
	local cap = name:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint", name)
	cap.MaxTextSize = 54
	center(ui.words(paper, "Tier", TIER_NAMES[reward.skin.tier] .. " skin", 55, 466, 380, 58, 39))
	local extra = reward.skin.trail and Looks.item(reward.skin.trail)
	if reward.refund > 0 then
		center(PaperUI.loud(ui.words(paper, "Refund", "+" .. paperValue(reward.refund), 48, 530, 388, 57, 38)))
	elseif extra then
		local trail = center(ui.words(paper, "Trail", "Includes " .. extra.name, 48, 530, 388, 48, 30))
		trail.TextWrapped = true
	end
end

local function shortName(chest)
	return (chest.name:gsub(" Treasure Chest$", ""))
end

local function go(ctx, page)
	local panel = ctx.state.chestPanel
	if panel.expected ~= nil then return end
	panel.page = page
	ctx.render()
end

local function open(ctx, source)
	local panel, wallet = ctx.state.chestPanel, ctx.profile.chests
	if not panel or not wallet then return end
	if panel.expected ~= nil and (not panel.retry or source ~= panel.source) then return end
	if source == "paper" and (ctx.profile.chestPaperAllowed ~= true or panel.page ~= "buy") then return end
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

local function backButton(ctx, sheet)
	ctx.ui.button(sheet, "ChestBack", Assets.range.stripRed, "Back", 160, 131, 262, 77, -1, function()
		go(ctx, nil)
	end, 44)
end

local function chestShelf(ctx, sheet)
	local ui, panel, wallet = ctx.ui, ctx.state.chestPanel, ctx.profile.chests
	local selected = panel.selected
	local stock = wallet and wallet.stock or {}
	local balance = ctx.profile.paper or 0
	local odds = Looks.chestOdds(selected.id)
	local pending = panel.expected ~= nil

	center(PaperUI.loud(ui.words(sheet, "Heading", "Treasure chests", 131, 134, 643, 77, 61)))
	center(ui.words(sheet, "Balance", "Your Paper  " .. PaperUI.commas(balance), 151, 208, 609, 57, 41))
	for i, chest in Looks.config().chests do
		local x, y = 131 + (i - 1) % 2 * 335, 276 + math.floor((i - 1) / 2) * 253
		local card = ui.button(sheet, chest.id, chest == selected and Assets.hangar.cardSelectedSquare or Assets.hangar.cardSquare,
			"", x, y, 318, 237, 0, function()
				if pending or chest == panel.selected then return end
				panel.selected = chest
				ctx.render()
			end)
		chestPicture(ui, card, chest.id, 56, 19, 202, 123)
		center(PaperUI.loud(ui.words(card, "Name", shortName(chest), 29, 137, 260, 45, 39)))
		center(ui.words(card, "Stock", string.format("%d earned", stock[chest.id] or 0), 28, 178, 262, 43, 31))
	end
	ui.button(sheet, "ChestProgress", Assets.mainmenu.strip.blue, "How to earn chests", 165, 812, 582, 105, -1, function()
		go(ctx, "progress")
	end, 44)

	center(PaperUI.loud(ui.words(sheet, "ChestTitle", shortName(selected) .. " chest", 827, 143, 654, 74, 53)))
	center(ui.words(sheet, "RarityHeading", "Skin chances", 829, 229, 643, 55, 40))
	for i, tier in TIERS do
		local x, y = 850 + (i - 1) % 2 * 326, 302 + math.floor((i - 1) / 2) * 64
		ui.words(sheet, tier, TIER_NAMES[tier], x, y, 170, 54, 36)
		local chance = ui.words(sheet, tier .. "Odds", percentage(odds[tier]), x + 169, y, 105, 54, 36)
		chance.TextXAlignment = Enum.TextXAlignment.Right
	end
	ui.button(sheet, "ChestOdds", Assets.mainmenu.strip.blue, "All skins & odds", 884, 444, 539, 90, 0, function()
		go(ctx, "odds")
	end, 42)
	local dup = center(ui.words(sheet, "Duplicates", "Duplicates return 10% of the skin's Paper value.", 838, 541, 624, 106, 37))
	dup.TextWrapped = true
	local have = stock[selected.id] or 0
	local freeLabel = string.format("Open earned (%d)", have)
	if pending then freeLabel = panel.retry and "Retry earned opening" or "Opening" end
	action(ui, sheet, "OpenEarned", freeLabel, 876, 654, 557, 99, have > 0 and (not pending or panel.retry), function() open(ctx, "earned") end)
	local notice = nil
	if ctx.profile.chestPaperAllowed == true then
		local canBuy = wallet ~= nil and balance >= selected.cost and not pending
		action(ui, sheet, "BuyChest", "Open for " .. paperValue(selected.cost), 862, 776, 585, 103, canBuy, function()
			go(ctx, "buy")
		end)
		if balance < selected.cost then notice = "Need " .. paperValue(selected.cost - balance) .. " more." end
	else
		notice = "Earn this chest by playing."
	end
	if panel.retry then notice = game.Players.LocalPlayer:GetAttribute("MenuMessage") or "Still waiting. You can retry." end
	if notice then
		local label = center(ui.words(sheet, "Status", notice, 823, ctx.profile.chestPaperAllowed and 889 or 788, 658, 64, 34))
		label.TextWrapped = true
	end
end

local function oddsPage(ctx, sheet)
	local ui, panel = ctx.ui, ctx.state.chestPanel
	local selected = panel.selected
	local buying = panel.page == "buy"
	local costsPaper = buying and ctx.profile.chestPaperAllowed == true
	local balance = ctx.profile.paper or 0
	local odds, counts = Looks.chestOdds(selected.id)
	backButton(ctx, sheet)
	center(PaperUI.loud(ui.words(sheet, "OddsTitle", shortName(selected) .. " chest odds", 468, 131, 754, 78, 53)))
	local sentence = costsPaper and ("Spend " .. paperValue(selected.cost) .. " for one draw. You have " .. paperValue(balance) .. ".")
		or "Each opening gives one skin. Owned skins pay the duplicate amount."
	center(ui.words(sheet, "Terms", sentence, 182, 219, 1282, 64, 36))
	ui.words(sheet, "SkinHeading", "Skin", 210, 309, 440, 57, 39)
	ui.words(sheet, "ChanceHeading", "Chance", 692, 309, 202, 57, 39)
	ui.words(sheet, "RefundHeading", "If already owned", 1013, 309, 469, 57, 39)
	local list = ui.instance(sheet, "PossibleSkins", "ScrollingFrame")
	list.Position, list.Size = UDim2.fromOffset(185, 375), UDim2.fromOffset(1297, 376)
	list.BackgroundTransparency, list.BorderSizePixel = 1, 0
	list.ScrollBarImageColor3, list.ScrollBarThickness = PaperUI.INK, 11
	list.ScrollingDirection, list.ElasticBehavior = Enum.ScrollingDirection.Y, Enum.ElasticBehavior.Never
	local rows = 0
	for _, skin in Looks.config().skins do
		local y = rows * 59
		local name = skin.name .. (ctx.profile.looks.owned[skin.id] and " (owned)" or "")
		ui.words(list, skin.id, name, 24, y, 465, 57, 37)
		local perSkin = odds[skin.tier] > 0 and odds[skin.tier] / counts[skin.tier] or 0
		ui.words(list, skin.id .. "Odds", percentage(perSkin), 506, y, 247, 57, 37)
		ui.words(list, skin.id .. "Refund", paperValue(Looks.duplicateRefund(skin.id)), 829, y, 422, 57, 37)
		rows += 1
	end
	list.CanvasSize = UDim2.fromOffset(0, rows * 59)
	if list:GetAttribute("Chest") ~= selected.id then
		list:SetAttribute("Chest", selected.id)
		list.CanvasPosition = Vector2.zero
	end
	center(ui.words(sheet, "Rounding", "Percentages are rounded to four decimal places.", 208, 760, 1220, 56, 31))
	if costsPaper then
		local busy = panel.expected ~= nil
		local allowed = ctx.profile.chests ~= nil and balance >= selected.cost and (not busy or panel.retry)
		local label = busy and (panel.retry and "Retry this opening" or "Opening") or "Spend " .. paperValue(selected.cost)
		action(ui, sheet, "ConfirmPaper", label, 198, 827, 620, 104, allowed, function() open(ctx, "paper") end, 43)
		local status = panel.retry and (game.Players.LocalPlayer:GetAttribute("MenuMessage") or "Still waiting. You can retry.")
			or balance < selected.cost and "Need " .. paperValue(selected.cost - balance) .. " more."
		if status then
			local text = center(ui.words(sheet, "Status", status, 839, 839, 590, 83, 34))
			text.TextWrapped = true
		end
	end
end

local GOALS = {
	{ key = "daily", chest = "paper", name = "Daily streak", rule = "Play 2 days in a row", unit = "days" },
	{ key = "mission", chest = "sticker", name = "Weekly mission", rule = "Finish 3 matches this week", unit = "matches" },
	{ key = "weekly", chest = "blue_ribbon", name = "Weekly streak", rule = "Play 2 weeks in a row", unit = "weeks" },
	{ key = "monthly", chest = "golden_star", name = "Monthly streak", rule = "Play 2 months in a row", unit = "months" },
}

local function progressPage(ctx, sheet)
	local ui, wallet = ctx.ui, ctx.profile.chests
	backButton(ctx, sheet)
	center(PaperUI.loud(ui.words(sheet, "GoalsTitle", "Earn treasure chests", 455, 133, 803, 76, 56)))
	center(ui.words(sheet, "GoalsNote", "Finish a match and earn rewards for it to count.", 211, 220, 1250, 62, 39))
	local progress = Progress.status(wallet and wallet.progress or Progress.defaults(), math.floor(workspace:GetServerTimeNow()))
	for i, goal in GOALS do
		local y = 316 + (i - 1) * 141
		local chest = Looks.chest(goal.chest)
		local current = progress[goal.key]
		chestPicture(ui, sheet, goal.chest, 171, y, 152, 113, goal.chest .. "Picture")
		PaperUI.loud(ui.words(sheet, goal.key, goal.name, 353, y + 4, 544, 54, 41))
		ui.words(sheet, goal.key .. "Rule", goal.rule, 354, y + 58, 590, 50, 34)
		ui.words(sheet, goal.key .. "Reward", shortName(chest) .. " chest", 986, y + 4, 460, 52, 39)
		local count = current.count == current.target and "Earned" or string.format("%d / %d %s", current.count, current.target, goal.unit)
		ui.words(sheet, goal.key .. "Count", count, 987, y + 57, 457, 51, 34)
	end
	center(ui.words(sheet, "WeekStart", "Weeks start Monday. Days and months follow UTC.", 203, 906, 1240, 52, 32))
end

function Chests.draw(ctx)
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
	elseif page == "buy" or page == "odds" then
		oddsPage(ctx, sheet)
	else
		chestShelf(ctx, sheet)
	end
	ui.button(sheet, "CloseChest", Assets.mainmenu.boxRed, "X", 1531, 131, 87, 87, 1, function()
		ctx.state.chestPanel = nil
		ctx.render()
	end, 50)
end

return Chests
