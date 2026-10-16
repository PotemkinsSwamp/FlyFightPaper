-- Round results on lined paper pinned to cork (Alan's approved concept: assets/references/ui-concepts/results.png).
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets).results
local Economy = require(Root.Shared.EconomyRules)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local PaperUI = require(script.Parent.PaperUI)
local ResultsScreen = {}

local COLUMNS = { -- header, x, width, value
	{ "#", 70, 60, function(row) return tostring(row.place or "-") end },
	{ "Pilot", 140, 470, function(row) return row.displayName end },
	{ "Downed", 620, 160, function(row) return tostring(row.kills) end },
	{ "Assists", 790, 160, function(row) return tostring(row.assists) end },
	{ "Points", 960, 150, function(row) return tostring(row.contribution) end },
	{ "Paper", 1120, 130, function(row) return tostring(row.paper or 0) end },
	{ "XP", 1260, 120, function(row) return tostring(row.xp or 0) end },
}
local MODES = { { "FFA", "Free-for-all", "blue" }, { "TDM", "Team dogfight", "pink" }, { "CONTROL", "Airspace Control", "green" } }

-- The cheapest part unlocked at the next level above yours, for the "next unlock" card.
local function nextUnlock(level)
	local best
	local function consider(part)
		if part.min_level > level and (not best or part.min_level < best.min_level or part.min_level == best.min_level and part.paper_price < best.paper_price) then best = part end
	end
	for _, list in { Catalog.weapons, Catalog.utilities } do for _, part in list do consider(part) end end
	for _, list in Catalog.structuresBySlot do for _, part in list do consider(part) end end
	return best
end

-- api = { vote(mode), stay(), leave() }
function ResultsScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "ResultsScreen", Art.bg)
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local content = Instance.new("Frame")
	content.Name, content.BackgroundTransparency, content.Size, content.Parent = "Content", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), sheet

	local self = { frame = cover }
	function self.update(player, profile, snap)
		for _, child in content:GetChildren() do child:Destroy() end
		-- Scoreboard: header plus one ruled line per pilot (12 fit); the winner gets highlighter and a star, you are in red.
		for _, column in COLUMNS do
			local header = words(content, "Head" .. column[1], column[1], column[2], 205, column[3], 55, 36)
			header.TextColor3 = Color3.fromRGB(30, 60, 140)
		end
		local rows = snap and snap.result and snap.result.participants or {}
		for i, row in rows do
			if i > 12 then break end
			local y = 262 + (i - 1) * 44
			if i == 1 then
				local mark = image(content, "Winner", Art.rowHighlight, 60, y - 4, 1330, 50)
				mark.ScaleType, mark.ImageTransparency = Enum.ScaleType.Stretch, 0.25
				image(content, "Star", Art.goldStar, 1340, y - 10, 60, 60)
			end
			for _, column in COLUMNS do
				local cell = words(content, column[1] .. i, column[4](row), column[2], y, column[3], 44, 32)
				cell.TextTruncate = Enum.TextTruncate.AtEnd
				if row.displayName == player.DisplayName or row.displayName == player.Name then cell.TextColor3 = Color3.fromRGB(180, 40, 40) end
			end
		end

		-- XP card: crayon bar filled to how far you are into this level.
		local xpMilli = (profile and profile.xp or 0) * 1000
		local level, into, need = Economy.levelForXP(xpMilli)
		-- At the level cap there is no next level: show a full bar and "max level".
		if level == require(Root.Generated.Economy).level_cap then need = nil end
		image(content, "XPCard", Art.xpCard, 1430, 195, 460, 270, 2)
		words(content, "XPTitle", "XP", 1475, 215, 120, 70, 60)
		words(content, "Level", "Level " .. tostring(level or 1), 1600, 225, 250, 60, 44).TextXAlignment = Enum.TextXAlignment.Right
		local fraction = need and need > 0 and math.clamp(into / need, 0, 1) or 1
		local fill = image(content, "XPFill", Art.xpFill, 1480, 310, 360 * fraction, 54)
		fill.ScaleType = Enum.ScaleType.Stretch
		image(content, "XPFrame", Art.xpFrame, 1470, 300, 380, 72).ScaleType = Enum.ScaleType.Stretch
		local count = words(content, "XPCount", need and string.format("%d / %d", into // 1000, need // 1000) or "max level", 1470, 385, 380, 50, 40)
		count.TextXAlignment = Enum.TextXAlignment.Center

		-- Next unlock card.
		image(content, "UnlockCard", Art.unlockCard, 1430, 480, 460, 290, -2)
		words(content, "UnlockTitle", "Next unlock", 1480, 495, 360, 60, 46)
		local part = nextUnlock(level or 1)
		local unlock = words(content, "Unlock", part and string.format("%s\nat level %d", part.name, part.min_level) or "Everything unlocked!", 1485, 570, 350, 170, 38)
		unlock.TextWrapped, unlock.TextXAlignment = true, Enum.TextXAlignment.Center

		-- Vote buttons (live only while voting) and the leave/stay choices.
		local voting = snap and snap.phase == "VOTE"
		for i, mode in MODES do
			local votes = snap and snap.voteTotals and snap.voteTotals[mode[1]] or 0
			local b = button(content, "Vote" .. mode[1], Art.strip[mode[3]], string.format("%s (%d)", mode[2], votes), 70 + (i - 1) * 440, 895, 420, 150, (i - 2) * 1.5,
				function() if voting then api.vote(mode[1]) end end, 44)
			if not voting then b.ImageTransparency, b.Label.TextTransparency = 0.45, 0.45 end
		end
		local help = words(content, "VoteHelp", voting and "Pick the next mode!" or snap and snap.phase == "COUNTDOWN" and "Next round: " .. tostring(snap.nextMode) or "Voting opens soon.", 1440, 785, 440, 50, 34)
		help.TextColor3 = Color3.fromRGB(250, 245, 230)
		button(content, "NextRound", Art.strip.green, "Stay", 1440, 835, 210, 95, -2, api.stay, 44)
		button(content, "MainMenu", Art.strip.pink, "Menu", 1665, 835, 210, 95, 2, api.leave, 44)
	end
	return self
end

return ResultsScreen
