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
local PHOTO = { 75, 250, 530, 635 } -- the 3D plane on the left page, above its name tape

-- ctx comes from Hangar: state, builder, draft, profile, range, dev, owned(part), choose(pick, ...),
-- placeWeapon(id), statSheet(stats, compare, x, y, w, h), preview(draft, box, diagram), nameTag(...), save(fly),
-- atDesk(), api, mountColours, tryOn(pick) (the build after pick(scratch builder), or nil).
function Customize.draw(content, ctx)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local state, builder, draft = ctx.state, ctx.builder, ctx.draft
	local title = image(content, "TitleTape", Assets.ingame.tapeLabel, 500, 12, 700, 140)
	title.ScaleType = Enum.ScaleType.Stretch
	words(title, "Label", ctx.range and "Range Customize" or "Customize", 0, 0, 700, 140, ctx.range and 72 or 88).TextXAlignment = Enum.TextXAlignment.Center

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

	-- Right page: the cards, 2 across and 3 down (no category has more than 6 today; more would flip to a page 2).
	local definitions = ctx.catalog.structuresBySlot[state.slot] or (state.slot == "weapons" and ctx.catalog.weapons) or ctx.catalog.utilities
	for i, part in definitions do
		local owned = ctx.owned(part)
		local equipped = draft[state.slot] == part.id or draft.utility == part.id and state.slot == "boost"
			or state.slot == "weapons" and table.find(draft.weapon_mounts, part.id) ~= nil
		local x, y = 700 + (i - 1) % 2 * 272, 245 + math.floor((i - 1) / 2) * 215
		-- Gear that can't go on this plane at all right now: a crayon X and why, so a kid sees what to change (note 21).
		local blocked = state.slot == "weapons" and owned and not equipped and select(2, builder:findPlace(part.id, state.mount))
		-- Clicking a card tries it on (Alan 2026-10-21): the plane and the numbers show it against what you have on now,
		-- and Select puts it on. The card you already have on stops trying. Gear you own skips that (Alan 2026-10-21):
		-- pick a spot number, click the gear, it goes on.
		local card = button(content, part.id, equipped and Art.cardSelected or Art.card, "", x, y, 262, 205, 0, function()
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
			local ring = image(content, "Trying", Binder.outline, x - 14, y - 14, 290, 233)
			ring.ScaleType, ring.SliceCenter, ring.SliceScale, ring.ZIndex = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 0.5, 3
		end
		local name = words(card, "Name", part.name, 18, 14, 216, 96, 36)
		name.TextWrapped, name.TextYAlignment = true, Enum.TextYAlignment.Top
		local detail = state.trying == part and "Trying it on" or owned and (equipped and "Equipped" or ctx.range and ctx.profile.ownership[part.id] ~= true and "Range only" or "Owned") or string.format("%d Paper, lvl %d", part.paper_price, part.min_level)
		if state.slot == "weapons" then
			-- Damage (Alan): pips for how hard one shot hits, then damage per second.
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(216, 44), false, true -- long names shrink to one line
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 34, name
			words(card, "HitLabel", "Hit", 18, 60, 50, 34, 26)
			local hit = ctx.catalog.hitRating(part)
			for k = 1, 5 do image(card, "Hit" .. k, k <= hit and Art.bar.red or Art.bar.empty, 62 + (k - 1) * 30, 64, 27, 26) end
			words(card, "DPS", string.format("%.0f damage per second", ctx.catalog.weaponDPS(part)), 18, 96, 216, 30, 24)
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
			local status = words(card, "Status", detail, 18, 128, 216, 50, 21)
			status.TextWrapped = true
			if blocked then status.TextColor3, status.ZIndex = Color3.fromRGB(190, 20, 30), 6 end
		elseif state.slot == "boost" then
			-- What each booster does (Alan 2026-10-21: three boosters looked the same).
			name.Size, name.TextWrapped, name.TextScaled = UDim2.fromOffset(216, 44), false, true
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize, cap.Parent = 34, name
			local boost = words(card, "Boost", string.format("+%d%% speed for %d seconds", math.round((part.speed_factor - 1) * 100), part.boost_seconds), 18, 60, 216, 60, 26)
			boost.TextWrapped = true
			local info = words(card, "Status", detail, 18, 128, 216, 50, 21)
			info.TextWrapped = true
		else
			local info = words(card, "Status", detail, 18, 110, 216, 66, 24)
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
	ctx.nameTag(content, 115, 890, 450, 92, PaperUI.isPhone() and 54 or 44)
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
	ctx.preview(candidate or draft, PHOTO, diagram, true)
	local valid, reason = builder:validate(draft)
	local stats = ctx.catalog:deriveStats(draft)
	local note = builder.message ~= "" and builder.message or (not valid and tostring(reason))
		or state.dropAsk and "You have changes you haven't saved. Click Back again to drop them."
		or game.Players.LocalPlayer:GetAttribute("MenuMessage") or (ctx.range and "Range builds: every part works here, only in the Range." or "")
	-- Bottom of the right page: Select / Cancel for a card you're trying on (Buy / Cancel for one you don't own yet), else
	-- the mount line (Gear) and the no-booster card (Boost). Trying on: each number shows its change from what you have on.
	if state.trying then
		local part = state.trying
		ctx.statSheet(ctx.catalog:deriveStats(candidate) or stats, stats, 1415, 140, 490, 610)
		if ctx.owned(part) then
			note = part.name .. ": the numbers show what it changes. Select puts it on."
			button(content, "SelectPart", Art.buttonGreen, "Select", 735, 980, 240, 70, -1, function()
				state.trying = nil
				if state.slot == "weapons" then ctx.choose(function() return ctx.placeWeapon(part.id) end)
				elseif state.slot == "boost" then ctx.choose(builder.selectUtility, part.id)
				else ctx.choose(builder.selectStructure, state.slot, part.id) end
			end, 46)
		else
			note = string.format("%s: %d Paper, level %d. The numbers show what it changes.", part.name, part.paper_price, part.min_level)
			button(content, "BuyPart", Art.buttonGreen, "Buy", 735, 980, 240, 70, -1, function()
				ctx.api.action:FireServer("purchasePart", part.id); state.trying = nil; ctx.render()
			end, 46)
		end
		button(content, "CancelTry", Art.tab, "Cancel", 995, 980, 240, 70, 1, function() state.trying = nil; ctx.render() end, 40)
	else
		ctx.statSheet(stats, nil, 1415, 140, 490, 610)
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
			local info = words(content, "MountInfo", string.format("Spot %d: %s%s. %s", m, body.mount_types[m],
				part and (groups[m] == 1 and ", left click" or ", right click") or "", part and part.name or "Empty: pick a gear card."), 700, 888, 540, 44, 28)
			info.TextXAlignment, info.TextWrapped = Enum.TextXAlignment.Center, true
			button(content, "ClearMount", Art.buttonGreen, "Clear spot", 840, 980, 260, 70, 2, function() ctx.choose(builder.selectMount, state.mount, false) end, 32)
		elseif state.slot == "boost" then
			button(content, "NoBoost", Art.tab, "No booster", 840, 980, 260, 70, 0, function() ctx.choose(builder.selectUtility, nil) end, 32)
		end
	end
	local message = words(content, "Message", note, 700, 932, 540, 46, 26)
	local problem = builder.message ~= "" or not valid or state.dropAsk ~= nil
	message.TextColor3, message.TextWrapped = problem and Color3.fromRGB(170, 30, 30) or Color3.fromRGB(30, 110, 50), true

	-- Save, and a clearly separate second button: Save & fly at the desk (spends Paper, Alan 2026-10-17), Test in Range
	-- in the Range (saves and drops you back in flying it, Alan 2026-10-20).
	local second = ctx.range and "Test in Range" or ctx.atDesk() and "Save & fly - 120 Paper"
	if second then
		button(content, "SavePreset", Art.buttonGreen, "Save", 1425, 775, 220, 150, -1, function() ctx.save(false) end, 52)
		button(content, "SaveFly", Art.buttonGreen, second, 1655, 775, 250, 150, 1, function() ctx.save(true) end, 32)
	else
		button(content, "SavePreset", Art.buttonGreen, "Save build", 1440, 775, 460, 150, -1, function() ctx.save(false) end, 60)
	end
	-- Studio only: fly the draft straight away, nothing saved.
	if ctx.dev and not ctx.range then button(content, "FlyBuild", Art.buttonGreen, "Fly this build", 1505, 945, 330, 90, -2, function() ctx.api.fly() end, 40) end
end

return Customize
