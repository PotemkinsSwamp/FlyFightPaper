-- The Hangar's Customize screen: an open school binder (Alan's pick 2026-10-20: assets/references/ui-concepts/
-- hangar-customize-b.png). Index tabs down its edge pick a category, the left page shows the plane (the Gear page shows
-- its numbered mounts), the right page holds the cards, and the stat sheet and Save sit beside it.
-- Categories are a list so it can grow: skins, trails and part skins later are one more TABS row plus their page.
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Schema = require(Root.Shared.ProfileSchema)
local CombatRules = require(Root.Shared.CombatRules)
local Assets = require(Root.Shared.UIAssets)
local Art, Binder = Assets.hangar, Assets.hangarShelf
local Looks = require(Root.Shared.LooksRules)
local PaperUI = require(script.Parent.PaperUI)
local PlaneLooks = require(script.Parent.PlaneLooks)
local Customize = {}

-- slot = the build part it edits; Gear is the weapons (Alan 2026-10-20). Tints follow the concept's tabs.
Customize.TABS = {
	{ slot = "body", label = "Body", tint = Color3.fromRGB(255, 215, 60) },
	{ slot = "nose", label = "Nose", tint = Color3.fromRGB(240, 110, 130) },
	{ slot = "wings", label = "Wings", tint = Color3.fromRGB(175, 130, 220) },
	{ slot = "tail", label = "Tail", tint = Color3.fromRGB(90, 150, 230) },
	{ slot = "weapons", label = "Gear", tint = Color3.fromRGB(110, 190, 100) },
	{ slot = "boost", label = "Boost", tint = Color3.fromRGB(245, 150, 60) },
	-- Skins and Trails (Alan 2026-11-13): how your plane looks, not part of a build; worn on every build you fly.
	{ slot = "skin", label = "Skins", tint = Color3.fromRGB(70, 195, 185) },
	{ slot = "trail", label = "Trails", tint = Color3.fromRGB(225, 95, 85) },
}

-- Binder layout (sheet pixels): the two halves meet at the rings; the plane photo fills the left page.
local BINDER_X, BINDER_Y, PAGE_W, PAGE_H = 20, 165, 630, 920
-- Everything of the binder (title, pages, tabs, cards, plane) is drawn this much smaller, from the sheet's top left,
-- so the stats paper beside it can be bigger (Alan 2026-11-09). The stats paper, Save and Fly are on the full sheet.
Customize.BINDER_SCALE = 0.95
local PHOTO = { 75, 250, 530, 635 } -- the 3D plane on the left page, above its name tape

-- ctx comes from Hangar: state, builder, draft, profile, range, dev, owned(part), choose(pick, ...),
-- placeWeapon(id), statSheet(stats, compare, x, y, w, kind, note), preview(draft, box, diagram), nameTag(...), save(fly),
-- atDesk(), api, mountColours, tryOn(pick) (the build after pick(scratch builder), or nil).
-- The stats paper: a little bigger than the 490 it was (at its own shape), right of the shrunk tabs, its bottom just
-- above Save (Alan 2026-11-10). Save and Fly sit centred under it.
local STATS_W, STATS_Y = 540, 160
local STATS_X = 1900 - STATS_W
local MID = STATS_X + STATS_W / 2

-- "Unlock now": a part's Robux price from its Paper price (docs/plan/SHOP-PRICES-PLAN.md, approved 2026-11-11).
-- ponytail: display only, like ShopScreen's PRICE; live, the price comes from Roblox's product info.
local UNLOCK_ROBUX = { { 700, 49 }, { 1600, 79 }, { 2500, 129 }, { 4000, 199 }, { 6000, 279 }, { 8500, 449 }, { 13000, 599 }, { 18500, 999 } }
function Customize.unlockRobux(paperPrice)
	for _, row in UNLOCK_ROBUX do if paperPrice <= row[1] then return row[2] end end
	return 1699
end
local LOCKED_TINT = Color3.fromRGB(175, 170, 165) -- a locked card: the same paper, greyed

-- A padlock drawn in ink (a shackle ring over a rounded body), `h` tall, its top left at (x, y).
local function padlock(parent, x, y, h)
	local w = h * 0.8
	local shackle = Instance.new("Frame")
	shackle.Name, shackle.BackgroundTransparency = "LockShackle", 1
	shackle.Position, shackle.Size = UDim2.fromOffset(x + w * 0.2, y), UDim2.fromOffset(w * 0.6, h * 0.6)
	Instance.new("UICorner", shackle).CornerRadius = UDim.new(0.5, 0)
	local ring = Instance.new("UIStroke")
	ring.Thickness, ring.Color, ring.Parent = math.max(3, h * 0.12), PaperUI.INK, shackle
	shackle.Parent = parent
	local body = Instance.new("Frame")
	body.Name, body.BackgroundColor3, body.BorderSizePixel = "LockBody", PaperUI.INK, 0
	body.Position, body.Size = UDim2.fromOffset(x, y + h * 0.38), UDim2.fromOffset(w, h * 0.62)
	Instance.new("UICorner", body).CornerRadius = UDim.new(0.2, 0)
	body.Parent = parent
end

local robuxButton = PaperUI.robuxButton

-- Everything under `root` drawn above the binder (the pop-up).
local function lift(root, z)
	for _, item in { root, table.unpack(root:GetDescendants()) } do
		if item:IsA("GuiObject") then item.ZIndex = z + (item.ZIndex - 1) end
	end
end

-- Skins and Trails pages. Cards are Gear's wide, short ones so all nine skins fit one page; clicking a card tries it
-- on the plane photo, then Wear (owned), Buy (Paper) or Unlock now (Robux, when you're short of Paper).
local TIER = { common = "Common", rare = "Rare", legendary = "Legendary", mythical = "Mythical", trail = "Trail" }
local function lookList(slot)
	local list = {}
	for _, entry in slot == "skin" and Looks.config().skins or Looks.config().trails do table.insert(list, Looks.item(entry.id)) end
	return list
end
local function saved(ctx) return ctx.profile and ctx.profile.looks or { owned = {}, skin = "", trail = "" } end
local function wearing(ctx, kind) -- Studio's dev try-on wins on your own screen
	if kind == "skin" and PlaneLooks.devSkin ~= nil then return PlaneLooks.devSkin end
	return saved(ctx)[kind] or ""
end
local function ownsLook(ctx, id) return saved(ctx).owned[id] == true end
local function bundledWith(id) -- a matching trail comes with its skin
	for _, entry in Looks.config().skins do if entry.trail == id then return entry.name end end
	return nil
end
-- The skin the plane photo wears: the card being tried on, else the one you wear.
function Customize.shownSkin(ctx)
	local trying = ctx.state.tryLook
	if trying and trying.kind == "skin" then return trying.id end
	local id = wearing(ctx, "skin")
	return id ~= "" and id or nil
end

local function lookCards(content, ctx)
	local state, image, words, button = ctx.state, PaperUI.image, PaperUI.words, PaperUI.button
	local on = wearing(ctx, state.slot)
	for i, item in lookList(state.slot) do
		local x, y = 700 + (i - 1) % 2 * 272, 236 + math.floor((i - 1) / 2) * 126
		local worn = item.id == on
		local card = button(content, item.id, worn and Art.cardSelectedWide or Art.cardWide, "", x, y, 262, 120, 0, function()
			game.Players.LocalPlayer:SetAttribute("MenuMessage", nil)
			state.tryLook = state.tryLook ~= item and not worn and item or nil
			ctx.render()
		end)
		if state.tryLook == item then
			local ring = image(content, "Trying", Binder.outline, x - 14, y - 14, 290, 148)
			ring.ScaleType, ring.SliceCenter, ring.SliceScale, ring.ZIndex = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 0.5, 3
		end
		-- Inside the card picture's paper (9-87% across, 10-88% down), as the other cards.
		local name = PaperUI.loud(words(card, "Name", item.name, 24, 12, 204, 32, 30))
		name.TextScaled = true
		local status = state.tryLook == item and "Trying it on" or worn and "Wearing" or ownsLook(ctx, item.id) and "Owned"
			or not item.sold and "Comes with " .. (bundledWith(item.id) or "its skin")
			or string.format("%s Paper", PaperUI.commas(item.paper))
		words(card, "Tier", TIER[item.tier], 24, 46, 204, 24, 24)
		local line = words(card, "Status", status, 24, 72, 204, 34, 30)
		line.TextScaled = true
		for _, label in { name, line } do
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = PaperUI.isPhone() and 40 or 30, label
		end
	end
end

-- Under the cards: what the look is, then Wear / Buy / Unlock now and Cancel, or Take off. Returns the note line.
local function lookControls(content, ctx, about)
	local state, button, kind, item = ctx.state, PaperUI.button, ctx.state.slot, ctx.state.tryLook
	local player = game.Players.LocalPlayer
	local function wear(id) -- the save keeps one skin and one trail; change just this one
		local looks = saved(ctx)
		ctx.api.action:FireServer("wearLook", { skin = kind == "skin" and id or looks.skin or "", trail = kind == "trail" and id or looks.trail or "" })
		if ctx.profile and ctx.profile.looks then ctx.profile.looks[kind] = id end -- shown now; the next refresh confirms it
		if kind == "skin" and PlaneLooks.devSkin ~= nil then PlaneLooks.setDevSkin(nil) end
		state.tryLook = nil
		ctx.render()
	end
	if kind == "trail" then
		about("Trails fly behind your plane. They're coming soon: you can already pick one.")
	elseif item then
		about(string.format("%s: a %s skin. It changes how your plane looks, never how it flies or where it can be hit.", item.name, string.lower(TIER[item.tier])))
	else
		about("Skins change how your plane looks, never how it flies or where it can be hit. Click one to try it on.")
	end
	if not item then
		if wearing(ctx, kind) ~= "" then
			button(content, "TakeOff", Art.tab, "Take off", 840, 980, 260, 70, 0, function() wear("") end, 32)
		end
		return nil
	end
	button(content, "CancelTry", Art.tab, "Cancel", 995, 980, 240, 70, 1, function() state.tryLook = nil; ctx.render() end, 40)
	if ownsLook(ctx, item.id) then
		button(content, "WearLook", Art.buttonGreen, "Wear", 735, 980, 240, 70, -1, function() wear(item.id) end, 46)
		return item.name .. ": yours. Wear puts it on every plane you fly."
	elseif ctx.dev and kind == "skin" then -- Studio only: on your own screen, nothing bought or saved
		button(content, "WearLook", Art.buttonGreen, "Try on", 735, 980, 240, 70, -1, function()
			PlaneLooks.setDevSkin(item.id); state.tryLook = nil; ctx.render()
		end, 46)
		return "Studio: Try on shows it on your plane, on your screen only. Nothing is bought."
	elseif not item.sold then
		return string.format("%s comes with the %s skin.", item.name, bundledWith(item.id) or "matching")
	end
	local paper = player:GetAttribute("Paper") or 0
	if paper < item.paper then -- short of Paper: the Robux way in Buy's place (as a part above your level)
		PaperUI.robuxButton(content, "UnlockNow", 695, 975, 290, 80, "Unlock now", item.robux, 38, function()
			ctx.api.action:FireServer("buyProduct", "look_" .. item.id)
		end)
		return string.format("%s: %s Paper. You need %s more, or unlock it now.", item.name, PaperUI.commas(item.paper), PaperUI.commas(item.paper - paper))
	end
	button(content, "BuyLook", Art.buttonGreen, "Buy", 735, 980, 240, 70, -1, function()
		ctx.api.action:FireServer("buyLook", item.id)
	end, 46)
	return string.format("%s: %s Paper.", item.name, PaperUI.commas(item.paper))
end

function Customize.draw(content, ctx)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local state, builder, draft = ctx.state, ctx.builder, ctx.draft
	local title = image(content, "TitleTape", Assets.ingame.tapeLabel, 400, 21, 900, 123) -- the tape's own shape
	PaperUI.loud(words(title, "Label", ctx.range and "Range Customize" or "Customize", 0, 0, 900, 123, ctx.range and 72 or 88)).TextXAlignment = Enum.TextXAlignment.Center

	-- Index tabs first so they tuck under the right page; the picked one sticks out further.
	for i, tab in Customize.TABS do
		local picked = tab.slot == state.slot
		local t = button(content, "Tab" .. tab.slot, Binder.indexTab, tab.label, BINDER_X + 2 * PAGE_W - 80 + (picked and 30 or 0), 225 + (i - 1) * 100, 200, 88, 0,
			function()
				if tab.slot ~= state.slot then state.turn = true end
				state.slot, state.trying, state.tryLook = tab.slot, nil, nil
				ctx.render()
			end, PaperUI.isPhone() and 50 or 40)
		t.ImageColor3 = tab.tint
		t.Label.Position, t.Label.Size = UDim2.fromOffset(80, 0), UDim2.new(1, -80, 1, 0)
	end
	-- The Range's binder is pink (its builds are a separate set).
	local white = Color3.new(1, 1, 1)
	local tints = ctx.range and { Color3.fromRGB(255, 175, 200), Color3.fromRGB(255, 222, 230) } or { white, white }
	local binderTint = tints[2] -- the right page's (the page that turns)
	for i, half in { Binder.binderLeft, Binder.binderRight } do
		local page = image(content, "Binder" .. i, half, BINDER_X + (i - 1) * PAGE_W, BINDER_Y, PAGE_W, PAGE_H)
		page.ScaleType, page.ImageColor3 = Enum.ScaleType.Stretch, tints[i]
	end

	-- Right page: the cards, 2 across and 3 down. Gear (ten weapons, Alan 2026-11-08: all on one page) has 5 rows of
	-- shorter cards, with what the weapon does in the box under them.
	local looks = state.slot == "skin" or state.slot == "trail"
	local definitions = looks and {} or ctx.catalog.structuresBySlot[state.slot] or (state.slot == "weapons" and ctx.catalog.weapons) or ctx.catalog.utilities
	local gear = state.slot == "weapons"
	if looks then lookCards(content, ctx) end
	local cardH, top = gear and 120 or 205, gear and 236 or 245 -- gear cards start where the others do, inside the page
	local player = game.Players.LocalPlayer
	local level = player:GetAttribute("Level") or 1
	for i, part in definitions do
		local owned = ctx.owned(part)
		-- Locked (Alan 2026-11-12: nothing said so at a glance): above your level, so the card is greyed with a padlock
		-- and its level; a part you can buy shows its Paper price instead.
		local locked = not owned and level < part.min_level
		local equipped = draft[state.slot] == part.id or draft.utility == part.id and state.slot == "boost"
			or state.slot == "weapons" and table.find(draft.weapon_mounts, part.id) ~= nil
		local x, y = 700 + (i - 1) % 2 * 272, top + math.floor((i - 1) / 2) * (cardH + (gear and 6 or 10))
		-- Gear that can't go on this plane at all right now: a crayon X and why, so a kid sees what to change (note 21).
		local blocked = state.slot == "weapons" and owned and not equipped and select(2, builder:findPlace(part.id, state.mount))
		-- Clicking a card tries it on (Alan 2026-10-21): the plane and the numbers show it against what you have on now,
		-- and Select puts it on. The card you already have on stops trying. Gear you own skips that (Alan 2026-10-21):
		-- pick a spot number, click the gear, it goes on.
		-- The card at this page's card shape (gear cards are wide and short), so it never stretches.
		local art = gear and (equipped and Art.cardSelectedWide or Art.cardWide) or (equipped and Art.cardSelectedSquare or Art.cardSquare)
		local card = button(content, part.id, art, "", x, y, 262, cardH, 0, function()
			player:SetAttribute("MenuMessage", nil) -- the last buy's reply is about another card (Alan 2026-11-12)
			if blocked or state.slot == "weapons" and owned then -- blocked: says why not
				state.trying = nil
				ctx.choose(function() return ctx.placeWeapon(part.id) end)
				return
			end
			local here = state.slot == "weapons" and draft.weapon_mounts[math.min(state.mount, ctx.catalog:get(draft.body).mount_count)] == part.id
				or state.slot ~= "weapons" and equipped
			state.trying, builder.message = not here and part or nil, ""
			ctx.render()
		end)
		if state.trying == part then
			local ring = image(content, "Trying", Binder.outline, x - 14, y - 14, 290, cardH + 28)
			ring.ScaleType, ring.SliceCenter, ring.SliceScale, ring.ZIndex = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 0.5, 3
		end
		-- Words stay inside every card picture's paper, the yellow picked border included: 9-87% across, 10-88% down
		-- (Alan 2026-11-09: "Paper Pellet Gun" ran off its card). IN = that box on this card.
		local IN = { x = 24, y = math.floor(cardH * 0.1), w = 204, h = math.floor(cardH * 0.78) }
		local name = PaperUI.loud(words(card, "Name", part.name, IN.x, IN.y, IN.w, 80, 34))
		name.TextWrapped, name.TextYAlignment = true, Enum.TextYAlignment.Top
		if locked then card.ImageColor3 = LOCKED_TINT end
		local detail = state.trying == part and "Trying it on" or owned and (equipped and "Equipped" or ctx.range and not ctx.catalog:owns(ctx.profile.ownership, part.id, level) and "Range only" or "Owned")
			or locked and string.format("Level %d", part.min_level) or string.format("%s Paper", PaperUI.commas(part.paper_price))
		-- The status words, with the padlock in front when locked.
		local function status(sx, sy, sw, sh, size)
			if locked and state.trying ~= part then
				padlock(card, sx, sy + 2, size * 0.9)
				sx, sw = sx + size * 0.9, sw - size * 0.9
			end
			local label = words(card, "Status", detail, sx, sy, sw, sh, size)
			return label
		end
		if state.slot == "weapons" then
			-- Pips for how hard one shot hits (Alan); damage a second and the rest are in the box under the cards.
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(IN.w, 32), false, true -- long names shrink to one line
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 30, name
			-- A slimmer Hit row so the size-and-weight line under it can be bigger (Alan 2026-11-12: card words too small).
			words(card, "HitLabel", "Hit", IN.x, IN.y + 31, 40, 22, 20)
			local hit = ctx.catalog.hitRating(part)
			for k = 1, 5 do image(card, "Hit" .. k, k <= hit and Art.bar.red or Art.bar.empty, IN.x + 38 + (k - 1) * 24, IN.y + 33, 20, 18) end
			-- Owned or equipped (the yellow card says which): just its size and weight, big enough to read.
			if owned and state.trying ~= part then
				detail = string.format("%s, weight %d%s", part.class, part.capacity, detail == "Range only" and ". Range only" or "")
			end
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
			local line = status(IN.x, IN.y + 54, IN.w, IN.h - 54, 34)
			line.TextWrapped, line.TextScaled = true, true
			local fit = Instance.new("UITextSizeConstraint")
			fit.MaxTextSize, fit.Parent = 34, line
			if blocked then line.TextColor3, line.ZIndex = Color3.fromRGB(190, 20, 30), 6 end
		elseif state.slot == "boost" then
			-- What each booster does (Alan 2026-10-21: three boosters looked the same).
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(IN.w, 40), false, true
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 32, name
			local boost = words(card, "Boost", string.format("+%d%% speed for %d seconds", math.round((part.speed_factor - 1) * 100), part.boost_seconds), IN.x, IN.y + 44, IN.w, 60, 24)
			boost.TextWrapped = true
			local info = status(IN.x, IN.y + 108, IN.w, IN.h - 108, 30)
			info.TextWrapped = true
		else
			local info = status(IN.x, IN.y + 92, IN.w, IN.h - 92, 46)
			info.TextWrapped, info.TextYAlignment = true, Enum.TextYAlignment.Top
		end
		-- Phones: the card's words were 7-12 points; each grows as big as its box allows. (The binder is redrawn on
		-- every change, so this reads the screen size each time instead of PaperUI.phone's watcher.)
		if PaperUI.isPhone() then
			for _, label in card:GetChildren() do
				if label:IsA("TextLabel") then
					local cap = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
					cap.MaxTextSize, cap.Parent = label.Name == "Name" and 44 or 32, label
					label.TextScaled = true
				end
			end
		end
	end

	-- Switching tabs turns the page (Alan 2026-10-21): the old right page folds over toward the rings while the new
	-- cards show underneath.
	if state.turn then
		state.turn = nil
		local page = image(content, "PageTurn", Binder.binderRight, 0, 0, PAGE_W, PAGE_H)
		page.ScaleType, page.ZIndex, page.AnchorPoint, page.ImageColor3 = Enum.ScaleType.Stretch, 8, Vector2.new(0, 0.5), binderTint
		page.Position = UDim2.fromOffset(BINDER_X + PAGE_W, BINDER_Y + PAGE_H / 2)
		local fold = TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.fromOffset(0, PAGE_H), ImageColor3 = Color3.fromRGB(150, 140, 120) })
		fold.Completed:Connect(function() page:Destroy() end)
		fold:Play()
	end

	-- Left page: the build's name, then the plane (the Gear page: a still diagram with a numbered tag on every mount).
	local diagram = state.slot == "weapons" and not state.trying
	ctx.nameTag(content, 115, 905, 450, 61, PaperUI.isPhone() and 50 or 40) -- the tape's own shape
	-- The plane as it would be with the card you're trying on: the same move Select makes, on a scratch copy; a part
	-- you don't own yet is just swapped in.
	local candidate = nil
	if state.trying then
		local part = state.trying
		candidate = ctx.owned(part) and ctx.tryOn(function(scratch)
			if state.slot == "weapons" then return scratch:placeWeapon(part.id, state.mount)
			elseif state.slot == "boost" then return scratch:selectUtility(part.id)
			else return scratch:selectStructure(state.slot, part.id) end
		end)
		if not candidate then
			candidate = assert(Schema.copy(draft))
			if state.slot == "weapons" then candidate.weapon_mounts[math.min(state.mount, ctx.catalog:get(candidate.body).mount_count)] = part.id
			elseif state.slot == "boost" then candidate.utility = part.id
			else
				candidate[state.slot] = part.id
				if state.slot == "body" then
					local mounts = {}
					for i = 1, part.mount_count do mounts[i] = candidate.weapon_mounts[i] or false end
					candidate.weapon_mounts = mounts
				end
			end
		end
	end
	ctx.preview(candidate or draft, PHOTO, diagram, true, nil, content, Customize.shownSkin(ctx))
	local valid, reason = builder:validate(draft)
	local stats = ctx.catalog:deriveStats(draft)
	local note = builder.message ~= "" and builder.message or (not valid and tostring(reason))
		or state.dropAsk and "You have changes you haven't saved. Click Back again to drop them."
		or game.Players.LocalPlayer:GetAttribute("MenuMessage") or (ctx.range and "Range loadouts: every part works here, only in the Range." or "")
	-- Bottom of the right page: Select / Cancel for a card you're trying on (Buy / Cancel for one you don't own yet), else
	-- the mount line (Gear) and the no-booster card (Boost). Trying on: each number shows its change from what you have on.
	-- Gear: what the weapon does and its numbers (catalog description), in the box under the cards (Alan 2026-11-08).
	local function about(text)
		local info = words(content, "MountInfo", text, 700, 860, 540, 92, 26)
		info.TextXAlignment, info.TextWrapped, info.TextScaled = Enum.TextXAlignment.Center, true, true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = PaperUI.isPhone() and 40 or 26, info
	end
	if state.trying then
		local part = state.trying
		if state.slot == "weapons" then about(part.name .. ": " .. part.description) end
		ctx.statSheet(ctx.catalog:deriveStats(candidate) or stats, stats, STATS_X, STATS_Y, STATS_W, "tall")
		if ctx.owned(part) then
			note = part.name .. ": the numbers show what it changes. Select puts it on."
			button(content, "SelectPart", Art.buttonGreen, "Select", 735, 980, 240, 70, -1, function()
				state.trying = nil
				if state.slot == "weapons" then ctx.choose(function() return ctx.placeWeapon(part.id) end)
				elseif state.slot == "boost" then ctx.choose(builder.selectUtility, part.id)
				else ctx.choose(builder.selectStructure, state.slot, part.id) end
			end, 46)
		else
			local robux = Customize.unlockRobux(part.paper_price)
			if part.paper_price == 0 then -- the free weapons: no product, they come with the level
				note = string.format("%s: free at level %d. The numbers show what it changes.", part.name, part.min_level)
			elseif level < part.min_level then
				-- Above your level: no Paper buy; "Unlock now" for Robux in its place (Alan 2026-11-12).
				note = string.format("Level %d, or unlock it now. A prestige takes it back.", part.min_level)
				robuxButton(content, "UnlockNow", 695, 975, 290, 80, "Unlock now", robux, 38, function()
					ctx.api.action:FireServer("buyProduct", "part_" .. part.id)
				end)
			else
				note = string.format("%s: %s Paper. The numbers show what it changes.", part.name, PaperUI.commas(part.paper_price))
				button(content, "BuyPart", Art.buttonGreen, "Buy", 735, 980, 240, 70, -1, function()
					local paper = player:GetAttribute("Paper") or 0
					if paper < part.paper_price then -- short of Paper: a pop-up with both ways to get it (Alan 2026-11-12)
						state.ask = { part = part, robux = robux, paper = paper }
					else
						ctx.api.action:FireServer("purchasePart", part.id); state.trying = nil
					end
					ctx.render()
				end, 46)
			end
		end
		button(content, "CancelTry", Art.tab, "Cancel", 995, 980, 240, 70, 1, function() state.trying = nil; ctx.render() end, 40)
	else
		ctx.statSheet(stats, nil, STATS_X, STATS_Y, STATS_W, "tall")
		if state.slot == "weapons" then
			local body = ctx.catalog:get(draft.body)
			local groups = assert(CombatRules.triggerGroups(draft))
			local m = math.min(state.mount, body.mount_count)
			local part = draft.weapon_mounts[m] and ctx.catalog:get(draft.weapon_mounts[m])
			-- Key: a coloured dot and the size word for each mount size, top-left of the photo.
			for k, size in { "light", "medium", "heavy" } do
				local dot = Instance.new("Frame")
				dot.Position, dot.Size, dot.BackgroundColor3 = UDim2.fromOffset(PHOTO[1] + 60 + (k - 1) * 150, PHOTO[2] + 75), UDim2.fromOffset(26, 26), ctx.mountColours[size]
				Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
				Instance.new("UIStroke", dot).Thickness = 2
				dot.Parent = content
				words(content, "Key" .. size, size, PHOTO[1] + 93 + (k - 1) * 150, PHOTO[2] + 67, 110, 40, 34)
			end
			about(string.format("Spot %d: %s%s. %s", m, body.mount_types[m], part and (groups[m] == 1 and ", left click" or ", right click") or "",
				part and part.name .. ": " .. part.description or "Empty: pick a gear card."))
			-- In the Buy / Cancel pair's two places (Alan 2026-11-11: a Clear all for every spot, the same taped paper in red).
			button(content, "ClearMount", Art.buttonGreen, "Clear spot", 735, 980, 240, 70, -1, function() ctx.choose(builder.selectMount, state.mount, false) end, 32)
			button(content, "ClearAll", Art.buttonRed, "Clear all", 995, 980, 240, 70, -1, function() ctx.choose(builder.clearMounts) end, 32)
		elseif state.slot == "boost" then
			button(content, "NoBoost", Art.tab, "No booster", 840, 980, 260, 70, 0, function() ctx.choose(builder.selectUtility, nil) end, 32)
		end
	end
	if looks then
		local line = lookControls(content, ctx, about) -- the server's reply to a buy wins over the card's own line
		note = builder.message ~= "" and builder.message or player:GetAttribute("MenuMessage") or line or ""
		gear = true -- the same short card rows and message line as Gear
	end
	local message = words(content, "Message", note, 700, gear and 950 or 932, 540, gear and 32 or 46, 26)
	local problem = builder.message ~= "" or not valid or state.dropAsk ~= nil
	message.TextColor3, message.TextWrapped = problem and Color3.fromRGB(170, 30, 30) or Color3.fromRGB(30, 110, 50), true
	if gear then -- a thinner line under the gear box: long messages shrink instead of running onto the buttons
		message.TextScaled = true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = PaperUI.isPhone() and 40 or 26, message
	end

	-- Short of Paper (Alan 2026-11-12: a pop-up, not the small line under the cards): the welcome card's sticky note over
	-- the whole sheet, the game dimmed, with both ways to get the part. Sizes: Tutorial's note, 1.3x on the sheet.
	if state.ask then
		local ask, side = state.ask, ctx.side
		local dim = Instance.new("TextButton") -- takes the clicks under it
		dim.Name, dim.Text, dim.AutoButtonColor, dim.BackgroundColor3, dim.BackgroundTransparency = "Ask", "", false, Color3.fromRGB(20, 14, 8), 0.45
		dim.Position, dim.Size, dim.Parent = UDim2.fromOffset(-PaperUI.W, -PaperUI.H), UDim2.fromOffset(3 * PaperUI.W, 3 * PaperUI.H), side -- past the sheet: wide screens too
		local X0, Y0 = PaperUI.W + (PaperUI.W - 1100) / 2, PaperUI.H + (PaperUI.H - 388) / 2 -- (the dim starts a sheet up and left)
		local card = image(dim, "Note", Assets.ingame.stickyWide, X0, Y0, 1100, 388)
		local head = PaperUI.loud(words(card, "Title", "Not enough Paper", 117, 112, 858, 64, 56))
		head.TextXAlignment = Enum.TextXAlignment.Center
		local short = ask.part.paper_price - ask.paper
		local text = words(card, "Text", string.format("%s costs %s Paper. You need %s more.", ask.part.name,
			PaperUI.commas(ask.part.paper_price), PaperUI.commas(short)), 117, 178, 858, 96, 42)
		text.TextXAlignment, text.TextWrapped = Enum.TextXAlignment.Center, true
		local function close() state.ask = nil; ctx.render() end
		button(card, "GetPaper", Assets.mainmenu.strip.blue, "Get Paper", 370 - 160, 312 - 40, 320, 80, -1, function()
			close()
			if ctx.api.shop then ctx.api.shop() end
		end, 46)
		robuxButton(card, "UnlockNow", 722 - 175, 312 - 40, 350, 80, "Unlock now", ask.robux, 40, function()
			close()
			ctx.api.action:FireServer("buyProduct", "part_" .. ask.part.id)
		end)
		button(card, "Close", Assets.mainmenu.boxRed, "X", 980, 75, 62, 62, 2, close, 38)
		lift(dim, 40)
	end

	-- Save, and a clearly separate second button: Save & fly at the desk (spends Paper, Alan 2026-10-17), Test in Range
	-- in the Range (saves and drops you back in flying it, Alan 2026-10-20).
	local second = ctx.range and "Test in Range" or ctx.atDesk() and "Save & fly - 120 Paper"
	if second then
		button(ctx.side, "SavePreset", Art.buttonGreen, "Save", MID - 300, 810, 280, 74, -1, function() ctx.save(false) end, 48)
		button(ctx.side, "SaveFly", Art.buttonGreen, second, MID + 10, 806, 300, 80, 1, function() ctx.save(true) end, 32)
	else
		button(ctx.side, "SavePreset", Art.buttonGreen, "Save loadout", MID - 230, 790, 460, 122, -1, function() ctx.save(false) end, 60)
	end
	-- Studio only: fly the draft straight away, nothing saved.
	if ctx.dev and not ctx.range then button(ctx.side, "FlyBuild", Art.buttonGreen, "Fly this build", MID - 165, 945, 330, 88, -2, function() ctx.api.fly() end, 40) end
end

return Customize
