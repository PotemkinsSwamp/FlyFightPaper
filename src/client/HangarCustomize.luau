-- The Hangar's Customize screen: an open school binder (Alan's pick 2026-10-20: assets/references/ui-concepts/
-- hangar-customize-b.png). Index tabs down its edge pick a category, the left page shows the plane (the Gear page shows
-- its numbered mounts), the right page holds the cards, and the stat sheet and Save sit beside it.
-- Categories are a list so it can grow: skins, trails and part skins later are one more TABS row plus their page.
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
local PHOTO = { 75, 250, 530, 680 }

-- ctx comes from Hangar: state, builder, draft, profile, range, dev, owned(part), choose(pick, ...),
-- placeWeapon(id), statSheet(stats, compare, x, y, w, h), preview(draft, box, diagram), nameTag(...), save(fly),
-- atDesk(), api, mountColours.
function Customize.draw(content, ctx)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local state, builder, draft = ctx.state, ctx.builder, ctx.draft
	local title = image(content, "TitleTape", Assets.ingame.tapeLabel, 500, 12, 700, 140)
	title.ScaleType = Enum.ScaleType.Stretch
	words(title, "Label", "Customize", 0, 0, 700, 140, 88).TextXAlignment = Enum.TextXAlignment.Center

	-- Index tabs first so they tuck under the right page; the picked one sticks out further.
	for i, tab in Customize.TABS do
		local picked = tab.slot == state.slot
		local t = button(content, "Tab" .. tab.slot, Binder.indexTab, tab.label, BINDER_X + 2 * PAGE_W - 80 + (picked and 30 or 0), 225 + (i - 1) * 100, 200, 88, 0,
			function() state.slot = tab.slot; state.purchase = nil; ctx.render() end, 40)
		t.ImageColor3 = tab.tint
		t.Label.Position, t.Label.Size = UDim2.fromOffset(80, 0), UDim2.new(1, -80, 1, 0)
	end
	image(content, "BinderLeft", Binder.binderLeft, BINDER_X, BINDER_Y, PAGE_W, PAGE_H).ScaleType = Enum.ScaleType.Stretch
	image(content, "BinderRight", Binder.binderRight, BINDER_X + PAGE_W, BINDER_Y, PAGE_W, PAGE_H).ScaleType = Enum.ScaleType.Stretch

	-- Right page: the cards, 2 across and 3 down (no category has more than 6 today; more would flip to a page 2).
	local definitions = ctx.catalog.structuresBySlot[state.slot] or (state.slot == "weapons" and ctx.catalog.weapons) or ctx.catalog.utilities
	for i, part in definitions do
		local owned = ctx.owned(part)
		local equipped = draft[state.slot] == part.id or draft.utility == part.id and state.slot == "boost"
			or state.slot == "weapons" and table.find(draft.weapon_mounts, part.id) ~= nil
		local x, y = 700 + (i - 1) % 2 * 272, 245 + math.floor((i - 1) / 2) * 215
		local card = button(content, part.id, equipped and Art.cardSelected or Art.card, "", x, y, 262, 205, 0, function()
			if not owned then state.purchase = part; ctx.render(); return end
			state.purchase = nil
			if state.slot == "weapons" then
				-- Clicking the weapon already on the picked mount takes it off (Alan 2026-10-17).
				local m = math.min(state.mount, ctx.catalog:get(draft.body).mount_count)
				if draft.weapon_mounts[m] == part.id then ctx.choose(builder.selectMount, m, false)
				else ctx.choose(function() return ctx.placeWeapon(part.id) end) end
			elseif state.slot == "boost" then ctx.choose(builder.selectUtility, part.id)
			else ctx.choose(builder.selectStructure, state.slot, part.id) end
		end)
		local name = words(card, "Name", part.name, 18, 14, 216, 96, 36)
		name.TextWrapped, name.TextYAlignment = true, Enum.TextYAlignment.Top
		local detail = owned and (equipped and "Equipped" or ctx.range and ctx.profile.ownership[part.id] ~= true and "Range only" or "Owned") or string.format("%d Paper, lvl %d", part.paper_price, part.min_level)
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
			-- Can't go on this plane at all right now: a crayon X and why, so a kid sees what to change (note 21).
			local blocked = owned and not equipped and select(2, builder:findPlace(part.id, state.mount))
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
		else
			local info = words(card, "Status", detail, 18, 110, 216, 66, 24)
			info.TextWrapped, info.TextYAlignment = true, Enum.TextYAlignment.Top
		end
	end

	-- Left page: the build's name, then the plane (the Gear page: a still diagram with a numbered tag on every mount).
	local diagram = state.slot == "weapons" and not state.purchase
	ctx.nameTag(content, 125, 890, 430, 92, false)
	ctx.preview(draft, PHOTO, diagram)
	local valid, reason = builder:validate(draft)
	local stats = ctx.catalog:deriveStats(draft)
	local note = builder.message ~= "" and builder.message or (not valid and tostring(reason))
		or state.dropAsk and "You have changes you haven't saved. Click Back again to drop them."
		or game.Players.LocalPlayer:GetAttribute("MenuMessage") or (ctx.range and "Range builds: every part works here, only in the Range." or "")
	-- Bottom of the right page: the mount line (Gear), the no-booster card (Boost), or Buy / Cancel for a locked part.
	if state.purchase then
		local part = state.purchase
		local candidate = assert(Schema.copy(draft))
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
		ctx.statSheet(ctx.catalog:deriveStats(candidate) or stats, stats, 1415, 140, 490, 610)
		note = string.format("%s: %d Paper, level %d. Bars show the plane with it.", part.name, part.paper_price, part.min_level)
		button(content, "BuyPart", Art.buttonGreen, "Buy", 735, 980, 240, 70, -1, function()
			ctx.api.action:FireServer("purchasePart", part.id); state.purchase = nil; ctx.render()
		end, 46)
		button(content, "CancelBuy", Art.tab, "Cancel", 995, 980, 240, 70, 1, function() state.purchase = nil; ctx.render() end, 40)
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
			local info = words(content, "MountInfo", string.format("Mount %d: %s%s. %s", m, body.mount_types[m],
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
