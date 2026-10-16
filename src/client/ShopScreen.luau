-- Studio-only practice shop on the bulletin board: three index-card columns (2x XP, 2x Paper, Paper packs).
-- Buttons only simulate products; no Robux, and the server refuses it outside Studio.
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Commerce = require(Root.Generated.Commerce)
local Art = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local ShopScreen = {}

local COLUMNS = {
	{ title = "2x XP", strip = "blue", match = function(p) return p.benefit == "xp_seconds" or p.benefit == "permanent_xp" end, boost = "xp" },
	{ title = "2x Paper", strip = "green", match = function(p) return p.benefit == "paper_seconds" or p.benefit == "permanent_paper" end, boost = "paper" },
	{ title = "Paper packs", strip = "yellow", match = function(p) return p.benefit == "paper_balance" end },
}

-- Placeholder Robux prices (Alan picked the "typical set", 2026-10-08). Display only: real prices must come from
-- Roblox's product info once live sales are approved (docs/systems/economy-and-shop.md).
local PRICE = {
	xp_boost_15m = 25, xp_boost_30m = 45, xp_boost_60m = 75, xp_boost_180m = 179, xp_boost_300m = 249,
	paper_boost_15m = 25, paper_boost_30m = 45, paper_boost_60m = 75, paper_boost_180m = 179, paper_boost_300m = 249,
	paper_pack_1000 = 49, paper_pack_3500 = 149, paper_pack_10000 = 399,
	permanent_2x_xp = 499, permanent_2x_paper = 499,
}
local ROBUX_ICON = "rbxasset://textures/ui/common/robux@3x.png" -- Roblox's own Robux symbol, shipped with the client

local function label(product)
	if product.benefit == "paper_balance" then return string.format("%d Paper", product.amount) end
	if product.kind == "pass" then return "Forever" end
	local minutes = product.amount / 60
	local hours = minutes / 60
	return hours == 1 and "1 hour" or minutes >= 60 and string.format("%g hours", hours) or string.format("%d minutes", minutes)
end

-- api = { buy(key), back() }
function ShopScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "ShopScreen", Art.mainmenu.bg)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Size, content.Parent = "Content", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet
	local header = image(sheet, "Header", Art.ingame.tapeLabel, 560, 95, 800, 120, -1)
	header.ScaleType, header.SliceCenter, header.SliceScale = Enum.ScaleType.Slice, Rect.new(90, 30, 894, 104), 0.9
	local title = words(header, "Title", "Practice shop", 0, 4, 800, 70, 64)
	title.TextXAlignment = Enum.TextXAlignment.Center
	local warn = words(header, "Note", "Practice only: nothing is really bought.", 0, 66, 800, 44, 34)
	warn.TextXAlignment, warn.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(170, 30, 30)
	button(sheet, "Back", Art.mainmenu.strip.red, "Back", 1560, 120, 240, 90, 3, api.back, 50)

	local self = { frame = cover }
	local shown
	function self.update(player, profile)
		-- Redraw only on a change, so a click never lands on a button that was just replaced.
		local key = game:GetService("HttpService"):JSONEncode({ profile and profile.boosts, player:GetAttribute("MenuMessage") })
		if key == shown then return end
		shown = key
		for _, child in content:GetChildren() do child:Destroy() end
		local boosts = profile and profile.boosts or {}
		for c, column in COLUMNS do
			local x = 165 + (c - 1) * 545
			local card = image(content, "Card" .. c, Art.ingame.indexCard, x, 235, 500, 180, (c - 2) * 1.5)
			card.ScaleType = Enum.ScaleType.Stretch
			words(card, "Title", column.title, 30, 42, 440, 60, 54).TextXAlignment = Enum.TextXAlignment.Center
			local status = ""
			local forever = column.boost and boosts[column.boost == "xp" and "permanentXP" or "permanentPaper"]
			if column.boost then
				local minutes = (boosts[column.boost .. "Seconds"] or 0) / 60
				status = forever and "You have it forever" or string.format("%d minutes left", math.floor(minutes))
			end
			words(card, "Status", status, 30, 102, 440, 44, 34).TextXAlignment = Enum.TextXAlignment.Center
			local row = 0
			for _, product in Commerce.products do
				-- Once a boost is forever, its timed versions are hidden (they would do nothing).
				if column.match(product) and not (forever and product.kind ~= "pass") then
					-- What you get on the left, the price with the Robux symbol on the right, like Roblox's own shops.
					local strip = button(content, product.key, Art.mainmenu.strip[product.kind == "pass" and "red" or column.strip], "",
						x + 20, 432 + row * 78, 460, 72, (row % 2 == 0 and -1 or 1), function() api.buy(product.key) end)
					words(strip, "What", label(product), 34, 6, 250, 60, 38)
					local icon = Instance.new("ImageLabel")
					icon.Name, icon.Image, icon.BackgroundTransparency, icon.ImageColor3 = "Robux", ROBUX_ICON, 1, Color3.fromRGB(28, 26, 30)
					icon.Position, icon.Size, icon.Parent = UDim2.fromOffset(300, 18), UDim2.fromOffset(34, 34), strip
					words(strip, "Price", tostring(PRICE[product.key] or "?"), 338, 6, 100, 60, 40)
					row += 1
				end
			end
		end
		-- Replies ("Purchase simulated...") on a tape strip under the title, dark ink so they read on the cork.
		local reply = game.Players.LocalPlayer:GetAttribute("MenuMessage") or ""
		if reply ~= "" then
			local tape = image(content, "MessageTape", Art.ingame.tapeLabel, 460, 912, 1000, 64, 0)
			tape.ScaleType, tape.SliceCenter, tape.SliceScale = Enum.ScaleType.Slice, Rect.new(90, 30, 894, 104), 0.5
			words(tape, "Message", reply, 40, 8, 920, 48, 32).TextXAlignment = Enum.TextXAlignment.Center
		end
	end
	return self
end

return ShopScreen
