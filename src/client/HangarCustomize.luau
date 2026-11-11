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
local PaperUI = require(script.Parent.PaperUI)
local Customize = {}

-- slot = the build part it edits; Gear is the weapons (Alan 2026-10-20). Tints follow the concept's tabs.
Customize.TABS = {
	{ slot = "body", label = "Body", tint = Color3.fromRGB(255, 215, 60) },
	{ slot = "nose", label = "Nose", tint = Color3.fromRGB(240, 110, 130) },
	{ slot = "wings", label = "Wings", tint = Color3.fromRGB(175, 130, 220) },
	{ slot = "tail", label = "Tail", tint = Color3.fromRGB(90, 150, 230) },
	{ slot = "weapons", label = "Gear", tint = Color3.fromRGB(110, 190, 100) },
	{ slot = "boost", label = "Boost", tint = Color3.fromRGB(245, 150, 60) },
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
				state.slot, state.trying = tab.slot, nil
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
	local definitions = ctx.catalog.structuresBySlot[state.slot] or (state.slot == "weapons" and ctx.catalog.weapons) or ctx.catalog.utilities
	local gear = state.slot == "weapons"
	local cardH, top = gear and 120 or 205, gear and 236 or 245 -- gear cards start where the others do, inside the page
	for i, part in definitions do
		local owned = ctx.owned(part)
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
		local detail = state.trying == part and "Trying it on" or owned and (equipped and "Equipped" or ctx.range and not ctx.catalog:owns(ctx.profile.ownership, part.id, game.Players.LocalPlayer:GetAttribute("Level") or 1) and "Range only" or "Owned") or part.paper_price == 0 and string.format("Free at level %d", part.min_level) or string.format("%d Paper, lvl %d", part.paper_price, part.min_level)
		if state.slot == "weapons" then
			-- Pips for how hard one shot hits (Alan); damage a second and the rest are in the box under the cards.
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(IN.w, 32), false, true -- long names shrink to one line
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 30, name
			words(card, "HitLabel", "Hit", IN.x, IN.y + 34, 44, 26, 22)
			local hit = ctx.catalog.hitRating(part)
			for k = 1, 5 do image(card, "Hit" .. k, k <= hit and Art.bar.red or Art.bar.empty, IN.x + 42 + (k - 1) * 27, IN.y + 37, 24, 22) end
			detail = string.format("%s, weight %d. %s", part.class, part.capacity, detail)
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
			local status = words(card, "Status", detail, IN.x, IN.y + 62, IN.w, IN.h - 62, 21)
			status.TextWrapped, status.TextScaled = true, true
			local fit = Instance.new("UITextSizeConstraint")
			fit.MaxTextSize, fit.Parent = 21, status
			if blocked then status.TextColor3, status.ZIndex = Color3.fromRGB(190, 20, 30), 6 end
		elseif state.slot == "boost" then
			-- What each booster does (Alan 2026-10-21: three boosters looked the same).
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(IN.w, 40), false, true
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 32, name
			local boost = words(card, "Boost", string.format("+%d%% speed for %d seconds", math.round((part.speed_factor - 1) * 100), part.boost_seconds), IN.x, IN.y + 44, IN.w, 60, 24)
			boost.TextWrapped = true
			local info = words(card, "Status", detail, IN.x, IN.y + 108, IN.w, IN.h - 108, 20)
			info.TextWrapped = true
		else
			local info = words(card, "Status", detail, IN.x, IN.y + 92, IN.w, IN.h - 92, 22)
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
	ctx.preview(candidate or draft, PHOTO, diagram, true, nil, content)
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
			note = part.paper_price == 0 and string.format("%s: free at level %d. The numbers show what it changes.", part.name, part.min_level)
				or string.format("%s: %d Paper, level %d. The numbers show what it changes.", part.name, part.paper_price, part.min_level)
			if part.paper_price > 0 then button(content, "BuyPart", Art.buttonGreen, "Buy", 735, 980, 240, 70, -1, function()
				ctx.api.action:FireServer("purchasePart", part.id); state.trying = nil; ctx.render()
			end, 46) end
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
	local message = words(content, "Message", note, 700, gear and 950 or 932, 540, gear and 32 or 46, 26)
	local problem = builder.message ~= "" or not valid or state.dropAsk ~= nil
	message.TextColor3, message.TextWrapped = problem and Color3.fromRGB(170, 30, 30) or Color3.fromRGB(30, 110, 50), true
	if gear then -- a thinner line under the gear box: long messages shrink instead of running onto the buttons
		message.TextScaled = true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = PaperUI.isPhone() and 40 or 26, message
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
