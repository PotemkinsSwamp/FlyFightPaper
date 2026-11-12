-- Folded by a part you don't own (Alan 2026-11-12): a card with that part, whose it was, the level it unlocks at and
-- its Paper price, and how to get it: Buy with Paper first when you can (level and Paper), else what you're waiting
-- for, and always Buy now for Robux. It comes up on the fold screen and stays at the desk; its X, LAUNCH, a menu
-- opening over the desk, the round ending or buying the part put it away. Once per part a session.
-- The card is the shop's Featured card (same art, smaller), so the offer looks the same in and out of a match.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Players = game:GetService("Players")
local PaperUI = require(script.Parent.PaperUI)
local Unlock = require(script.Parent.UnlockMoment)
local Customize = require(script.Parent.HangarCustomize) -- (a part's Robux price)
local Assets = require(Root.Shared.UIAssets)
local Art = Assets.shop
local FoldOffer = {}

local W, H, SCALE = 1237, 325, 0.6
local WHITE, YELLOW = Color3.new(1, 1, 1), Color3.fromRGB(255, 222, 40)
local MAT = Color3.fromRGB(176, 128, 84) -- the shop's kraft paper behind pictures

function FoldOffer.new(playerGui)
	local cover, sheet = PaperUI.screen(playerGui, "FoldOffer", {}, true)
	cover.Parent.DisplayOrder = 5 -- with the desk (5), under the report card (6) and the menus
	local action = Root:WaitForChild("RoundAction")
	local owned, seen, card, current, started, shownAt = {}, {}, nil, nil, false, 0
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile) owned = profile.ownership or owned end)
	local function close()
		if card then card:Destroy() end
		card, current, started, cover.Visible = nil, nil, false, false
	end
	local function words(parent, name, text, x, y, w, h, size, color, outline)
		local label = PaperUI.loud(PaperUI.words(parent, name, text, x, y, w, h, size))
		label.TextXAlignment, label.TextColor3 = Enum.TextXAlignment.Center, color or PaperUI.INK
		if outline then -- white and yellow words on the card get an ink edge, as the shop's (replaces the crayon copies)
			local stroke = Instance.new("UIStroke")
			stroke.Color, stroke.Thickness, stroke.LineJoinMode, stroke.Parent = PaperUI.INK, outline, Enum.LineJoinMode.Round, label
		end
		PaperUI.fitWords(label, w * 0.96)
		return label
	end
	local self = {}
	-- part: the Catalog part that folded you; killer: its pilot's name.
	function self.show(part, killer)
		if seen[part.id] or owned[part.id] then return end
		local item
		for _, each in Unlock.items(0, 999) do if each.part.id == part.id then item = each end end
		if not item then return end
		seen[part.id] = true
		close()
		current, shownAt = part, os.clock()
		local me = Players.LocalPlayer
		local level, paper = me:GetAttribute("Level") or 1, me:GetAttribute("Paper") or 0
		card = Instance.new("Frame")
		card.Name, card.BackgroundTransparency, card.AnchorPoint = "Card", 1, Vector2.new(0.5, 0)
		card.Size, card.Position = UDim2.fromOffset(W, H), UDim2.fromOffset(PaperUI.W / 2, 150)
		local scale = Instance.new("UIScale")
		scale.Scale, scale.Parent = SCALE, card
		card.Parent = sheet
		PaperUI.image(card, "PaperL", Art.cardFeatured[1], 0, 0, 620, H).ScaleType = Enum.ScaleType.Stretch
		PaperUI.image(card, "PaperR", Art.cardFeatured[2], 618, 0, 619, H).ScaleType = Enum.ScaleType.Stretch
		PaperUI.image(card, "Mat", Art.circlePale, 35, 25, 270, 270).ImageColor3 = MAT
		Unlock.view(card, item, 50, 40, 240, 240)
		words(card, "Tag", "Folded by " .. killer .. "'s", 330, 18, 620, 64, 40, WHITE, 3)
		words(card, "Name", part.name, 330, 76, 620, 110, 76, YELLOW, 5)
		local short = part.paper_price - paper
		words(card, "Line", (level < part.min_level and "Unlocks at level " .. part.min_level .. ". " or "")
			.. PaperUI.commas(part.paper_price) .. " Paper", 330, 196, 620, 90, 40)
		if level >= part.min_level and short <= 0 then
			PaperUI.button(card, "BuyPaper", Assets.mainmenu.strip.green, "Buy: " .. PaperUI.commas(part.paper_price) .. " Paper",
				967, 50, 250, 110, -1, function() action:FireServer("purchasePart", part.id) end, 34)
		else -- what you're waiting for, on the shop's dark label (not a button)
			PaperUI.image(card, "WaitPaper", Art.labelDark, 967, 60, 250, 90).ScaleType = Enum.ScaleType.Stretch
			words(card, "Wait", level < part.min_level and "Wait for level " .. part.min_level
				or "Need " .. PaperUI.commas(short) .. " more", 977, 60, 230, 90, 34, WHITE)
		end
		PaperUI.robuxButton(card, "Buy", 967, 180, 250, 110, "Buy now", Customize.unlockRobux(part.paper_price), 34,
			function() action:FireServer("buyProduct", "part_" .. part.id) end)
		PaperUI.button(card, "Close", Art.close, "", 1185, -35, 90, 90, 0, close, 10)
	end
	-- Each HUD tick: shown on the fold screen and at the desk; anything else (after it has shown) puts it away.
	function self.step(state, blocked)
		if not current then return end
		local here = state == "DESTROYED" or state == "DESK"
		-- (never reached the fold screen in 3 s: a stale card would pop up at a later death)
		if owned[current.id] or (started and (not here or blocked)) or (not started and os.clock() - shownAt > 3) then close(); return end
		started = started or here
		cover.Visible = here and not blocked
	end
	return self
end

return FoldOffer
