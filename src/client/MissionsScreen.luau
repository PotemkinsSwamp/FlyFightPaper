-- The Missions sheet (docs/decisions/2026-11-18-daily-and-weekly-missions.md): the chest sheet's notebook paper over the
-- main menu board, Daily and Weekly tabs, one construction-paper card per mission (goal, progress, reward), its colour
-- the difficulty (Alan 2026-11-18), with Claim and Swap beside it on the notebook paper.
-- The missions themselves are made and checked on the server (src/shared/Missions.luau); this only draws them.
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local Looks = require(Root.Shared.LooksRules)
local Catalog = require(Root.Generated.Catalog)
local PaperUI = require(script.Parent.PaperUI)
local Widgets = require(script.Parent.HangarWidgets)
local Opening = require(script.Parent.ChestOpening)
local MissionsScreen = {}

-- One white construction-paper card cut neatly with scissors (Alan 2026-11-18: neat, not crumpled or torn), tinted by
-- difficulty, easier to harder: green, yellow, red; blue for the Blue Ribbon card. The tints give the desk buttons'
-- paper colours on this white. The reward words tell the tiers apart too.
local GREEN, YELLOW, RED = Color3.fromRGB(73, 218, 65), Color3.fromRGB(255, 215, 13), Color3.fromRGB(255, 66, 79)
local TINT = { easy = GREEN, medium = YELLOW, hard = RED, two_day = GREEN, three_day = YELLOW, five_day = RED,
	fixed = Color3.fromRGB(46, 129, 252) }
-- Sheet pixels. Cards and buttons are centred between the paper's red
-- margin line (x 297) and its right edge (x 1779). The paper picture's ruled lines run 1.3 degrees downhill (it was
-- widened along them), so it is turned back level and everything else sits on a straight layer over it.
-- Daily cards a little taller: three of them fill the sheet as the weekly four do (Alan 2026-11-18: no empty space).
local CARD = { x = 357, y = 262, w = 1069, h = { daily = 200, weekly = 164 }, gap = { daily = 30, weekly = 12 } }
local BUTTONS = 1450
local LEVEL = -1.3
local MODES = { FFA = "Free-for-all", TDM = "Team", CONTROL = "Airspace Control" }
local DAYS = { "M", "T", "W", "T", "F", "S", "S" }
local REWARDS = {
	easy = "100 Paper + 150 XP", medium = "200 Paper + 250 XP", hard = "300 Paper + 400 XP",
	two_day = "2,000 Paper", three_day = "Sticker chest", five_day = "Sticker chest + 2,000 Paper", fixed = "Blue Ribbon chest",
}
local CHEST = { three_day = "sticker", five_day = "sticker", fixed = "blue_ribbon" }

local names = {}
for _, list in { Catalog.structures, Catalog.weapons, Catalog.utilities } do
	for _, item in list do names[item.id] = item end
end
local function gearWords(id)
	local item = names[id]
	if not item then return "" end
	return (item.slot and " flying the " or " with the ") .. item.name -- parts are flown, weapons and boosters are used
end
local function count(n, one, many) return n == 1 and one or (PaperUI.commas(n) .. " " .. many) end

-- One mission in plain words: "Fold 12 planes with the Thumbtack Shooter", "In 5 matches, fold 3 before you're folded".
function MissionsScreen.describe(m)
	local n, k = m.count, m.threshold
	local mode = m.mode and m.action ~= "zone_points" and m.action ~= "zone_folds" and (" in " .. MODES[m.mode] .. " matches") or ""
	local gear = m.gear and gearWords(m.gear) or ""
	if m.kind == "feat" then
		local feat = m.feat == "best_life" and ("fold " .. k .. " planes before you're folded")
			or m.feat == "deaths" and ("finish a match folded " .. k .. " times or fewer")
			or ({ folds = "fold %s planes", assists = "get %s assists", damage = "deal %s damage", paper = "earn %s Paper",
				boosts = "collect %s speed boosts", targets = "hit %s paper targets", minutes = "fly for %s minutes",
				matches = "play %s matches", wins = "win %s matches", top3 = "place in the top 3 %s times",
				zone_points = "earn %s zone points", zone_folds = "fold %s planes in the zone" })[m.action]:format(PaperUI.commas(k)) .. " in one match"
		local text = n == 1 and feat or ("In " .. n .. " matches, " .. feat:gsub(" in one match$", ""))
		return (text:gsub("^%l", string.upper)) .. gear .. mode
	end
	local base = ({
		folds = "Fold " .. count(n, "a plane", "planes"), assists = "Get " .. count(n, "an assist", "assists"),
		damage = "Deal " .. PaperUI.commas(n) .. " damage", paper = "Earn " .. PaperUI.commas(n) .. " Paper",
		minutes = "Fly " .. count(n, "a minute", "minutes"), matches = "Play " .. count(n, "a match", "matches"),
		wins = "Win " .. count(n, "a match", "matches"), top3 = n == 1 and "Finish in the top 3" or ("Finish in the top 3 " .. n .. " times"),
		targets = "Hit " .. count(n, "a paper target", "paper targets"), boosts = "Collect " .. count(n, "a speed boost", "speed boosts"),
		zone_points = "Earn " .. PaperUI.commas(n) .. " zone points in Airspace Control",
		zone_folds = "Fold " .. count(n, "a plane", "planes") .. " in the zone",
	})[m.action] or m.action
	return base .. gear .. mode
end

-- Progress: the level bar's hand-drawn frame and green crayon fill (LevelBar), the frame at its own thin shape
-- (799 x 79). Returns the bar's height.
function MissionsScreen.bar(ui, parent, name, x, y, w, fraction)
	local h = math.floor(w * 79 / 799 + 0.5)
	-- (ZIndex set, not left to the order they were made: Roblox draws equal siblings in no fixed order)
	local frame = ui.image(parent, name .. "Bar", Assets.results.xpFrame, x, y, w, h)
	frame.ScaleType, frame.ZIndex = Enum.ScaleType.Stretch, 1
	local fill = ui.image(parent, name .. "Fill", Assets.results.xpFill, x + w * 0.02, y + h * 0.17, w * 0.96 * math.clamp(fraction, 0, 1), h * 0.66)
	fill.ScaleType, fill.Visible, fill.ZIndex = Enum.ScaleType.Stretch, fraction > 0, 2
	return h
end

local function goalOf(m) return m.action == "minutes" and m.kind == "total" and m.count * 60 or m.count end
local function finished(m) return m.progress >= goalOf(m) end
-- Where a mission stands as the player reads it: done so far, the number to reach, and the bar's fill. Minutes read in
-- minutes; while a match is played a one-match goal shows that match's running count, "5 / 9" (Alan 2026-11-18).
function MissionsScreen.counts(m)
	if m.kind == "feat" and m.count == 1 and m.match and m.progress < 1 then
		return math.floor(m.match), m.threshold, m.match / m.threshold
	end
	local minutes = m.action == "minutes" and m.kind == "total"
	return math.min(minutes and m.progress // 60 or m.progress, m.count), m.count, m.progress / (minutes and m.count * 60 or m.count)
end
local function progressWords(m)
	local now, target = MissionsScreen.counts(m)
	return PaperUI.commas(now) .. " / " .. PaperUI.commas(target) .. (m.kind == "feat" and m.count > 1 and " matches" or "")
end
local function left(seconds)
	local d, h, mins = seconds // 86400, seconds % 86400 // 3600, seconds % 3600 // 60
	if d > 0 then return d .. (d == 1 and " day " or " days ") .. h .. " h" end
	return h > 0 and (h .. " h " .. mins .. " m") or (math.max(1, mins) .. " m")
end

-- api = { claim(list, index), swap(list, index), swapPrice(missions, list, index) -> Paper or nil, back() }
function MissionsScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "MissionsScreen", Assets.mainmenu.bg)
	local ui = Widgets.new()
	local self = { frame = cover }
	local tab, missions, message = "daily", nil, ""

	local function card(layer, name, m, list, index, y, fixed)
		local x, h = CARD.x, CARD.h[list == "daily" and "daily" or "weekly"]
		local done = fixed and missions.dailiesDone >= 15 or not fixed and finished(m)
		local claimed = fixed and missions.fixedClaimed or not fixed and m.claimed
		local tier = fixed and "fixed" or m.tier
		-- The card under everything on it (Alan's Play 2026-11-18: same-ZIndex pieces drew under it, the week vanished).
		local paper = ui.image(layer, name, Assets.mainmenu.cardWhite, x, y, CARD.w, h)
		paper.ScaleType, paper.ZIndex, paper.ImageColor3 = Enum.ScaleType.Stretch, 0, TINT[tier]
		-- Everything as big as the card allows (Alan 2026-11-18: "I do not like negative space"): the goal across the top,
		-- as big as 52 (a long goal takes two lines a little smaller); along the bottom the bar and its count on the left,
		-- the reward on the right, lined up to the card's right edge with its chest after the words.
		local row = y + h - 38 -- the bottom row's middle
		-- ponytail: by length, not measured (Kalam is about 0.3 of its size per letter: 58 letters fill one line at 52; at
		-- 42 two lines hold about 150). TextScaled would cap in screen pixels, a different size on every screen.
		local words = fixed and "Finish 15 daily missions" or MissionsScreen.describe(m)
		local goal = PaperUI.loud(ui.words(layer, name .. "Goal", words, x + 36, y + 12, CARD.w - 72, row - 30 - y - 12, #words > 58 and 42 or 52))
		goal.TextWrapped, goal.TextYAlignment, goal.LineHeight = true, Enum.TextYAlignment.Center, 1 -- centred above the bar
		if fixed then
			-- The week: a day gets the Hangar's green crayon square and the Training board's tick when a daily mission was
			-- finished on it.
			for i, letter in DAYS do
				local on = missions.calendar:sub(i, i) == "1"
				local dayX = x + 36 + (i - 1) * 56
				ui.image(layer, name .. "Day" .. i, on and Assets.hangar.bar.green or Assets.hangar.bar.empty, dayX, row - 22, 50, 44).ZIndex = 1
				local mark = ui.words(layer, name .. "Letter" .. i, letter, dayX, row - 22, 50, 44, 32)
				mark.TextXAlignment, mark.ZIndex = Enum.TextXAlignment.Center, 2
				local tick = ui.image(layer, name .. "Tick" .. i, Assets.trainingboard.tick, dayX + 5, row - 34, 50, 44)
				tick.Visible, tick.ZIndex = on, 3
			end
			ui.words(layer, name .. "Progress", math.min(missions.dailiesDone, 15) .. " / 15", x + 36 + 7 * 56 + 10, row - 24, 180, 48, 40)
		else
			MissionsScreen.bar(ui, layer, name, x + 36, row - 20, 400, select(3, MissionsScreen.counts(m)))
			ui.words(layer, name .. "Progress", done and "Done!" or progressWords(m), x + 452, row - 24, 200, 48, 40)
		end
		local right = x + CARD.w - 34
		local chest = CHEST[tier]
		if chest then
			Opening.picture(ui.image(layer, name .. "Chest", Assets.hangarShelf.chestAtlas, right - 68, row - 30, 68, 60), Looks.chest(chest))
			right -= 78
		end
		local reward = PaperUI.loud(ui.words(layer, name .. "Reward", REWARDS[tier], x + 600, row - 24, right - x - 600, 48, 40))
		reward.TextXAlignment = Enum.TextXAlignment.Right
		-- Claim beside every card in the same place; Swap under it, only while the mission is still open.
		if claimed then
			ui.button(layer, name .. "Claim", Assets.unlock.buttonCream, "Claimed", BUTTONS, y + 8, 270, 82, 0, function() end, 38)
		elseif done then
			ui.button(layer, name .. "Claim", Assets.hangar.buttonGreen, "Claim!", BUTTONS, y + 8, 270, 82, -1, function() api.claim(list, index) end, 44)
		else
			ui.button(layer, name .. "Claim", Assets.unlock.buttonCream, "Not yet", BUTTONS, y + 8, 270, 82, 0, function() end, 38)
		end
		local price = not fixed and not done and api.swapPrice(missions, list, index)
		if price then
			ui.button(layer, name .. "Swap", Assets.mainmenu.strip.blue, price == 0 and "Free swap" or ("Swap: " .. PaperUI.commas(price) .. " Paper"),
				BUTTONS + 5, y + h - 64, 260, 58, 0, function() api.swap(list, index) end, 30)
		end
	end

	local function draw()
		ui.begin()
		local paper = ui.image(sheet, "MissionsSheet", Assets.hangarShelf.statsWide, 102, 13, 1716, 1054, LEVEL)
		paper.ScaleType = Enum.ScaleType.Stretch
		local layer = ui.instance(sheet, "MissionsLayer", "Frame")
		layer.BackgroundTransparency, layer.Size, layer.ZIndex = 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), 2
		PaperUI.loud(ui.words(layer, "Title", "Missions", CARD.x, 84, 380, 86, 66))
		-- Tabs drawn nearer their pictures' own size and shape (Alan 2026-11-18: small and squashed, their edges were rough).
		for i, name in { "daily", "weekly" } do
			local on = tab == name
			ui.button(layer, name .. "Tab", on and Assets.hangar.buttonGreen or Assets.unlock.buttonCream, name == "daily" and "Daily" or "Weekly",
				CARD.x + (i - 1) * 320, 168, 300, 84, on and -1 or 1, function() tab = name; draw() end, 44)
		end
		ui.button(layer, "Close", Assets.mainmenu.boxRed, "X", 1633, 144, 87, 87, 1, function() api.back() end, 50)
		if missions then
			local now = workspace:GetServerTimeNow()
			local reset = tab == "daily" and (missions.day + 1) * 86400 or ((missions.week + 1) * 7 - 3) * 86400
			local timer = ui.words(layer, "Timer", "New missions in " .. left(math.max(0, math.floor(reset - now))), 990, 182, 620, 48, 36)
			timer.TextXAlignment = Enum.TextXAlignment.Right
			local step = CARD.h[tab] + CARD.gap[tab]
			for i, m in missions[tab] do card(layer, (tab == "daily" and "Daily" or "Weekly") .. i, m, tab, i, CARD.y + (i - 1) * step) end
			if tab == "weekly" then card(layer, "Fixed", nil, "fixed", 1, CARD.y + #missions.weekly * step, true) end
		end
		if message ~= "" then
			local note = ui.words(layer, "MissionMessage", message, CARD.x, 958, BUTTONS + 270 - CARD.x, 40, 30)
			note.TextXAlignment = Enum.TextXAlignment.Center
		end
		ui.finish()
	end

	function self.update(player, profile)
		missions = profile and profile.missions
		message = player:GetAttribute("MenuMessage") or ""
		draw()
	end
	function self.open(which) tab = which or "daily"; draw() end
	draw()
	return self
end

return MissionsScreen
