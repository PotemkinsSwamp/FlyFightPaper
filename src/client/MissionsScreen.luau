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

-- The desk buttons' construction paper, easier to harder: green, yellow, red; blue for the Blue Ribbon card (Alan
-- 2026-11-18: no new pictures). The reward words tell the tiers apart too.
local STRIP = { easy = "stripGreen", medium = "stripYellow", hard = "stripRed", two_day = "stripGreen", three_day = "stripYellow",
	five_day = "stripRed", fixed = "stripBlue" }
-- Sheet pixels. Cards and buttons are centred between the paper's red
-- margin line (x 297) and its right edge (x 1779). The paper picture's ruled lines run 1.3 degrees downhill (it was
-- widened along them), so it is turned back level and everything else sits on a straight layer over it.
local CARD = { x = 357, y = 262, w = 1069, h = 164, gap = { daily = 24, weekly = 12 } }
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
local function progressWords(m)
	local now = m.action == "minutes" and m.kind == "total" and m.progress // 60 or m.progress
	return PaperUI.commas(math.min(now, m.count)) .. " / " .. PaperUI.commas(m.count) .. (m.kind == "feat" and m.count > 1 and " matches" or "")
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
		local x, h = CARD.x, CARD.h
		local done = fixed and missions.dailiesDone >= 15 or not fixed and finished(m)
		local claimed = fixed and missions.fixedClaimed or not fixed and m.claimed
		local tier = fixed and "fixed" or m.tier
		-- The card under everything on it (Alan's Play 2026-11-18: same-ZIndex pieces drew under it, the week vanished).
		local paper = ui.image(layer, name, Assets.deskMenu[STRIP[tier]], x, y, CARD.w, h)
		paper.ScaleType, paper.ZIndex = Enum.ScaleType.Stretch, 0
		local goal = PaperUI.loud(ui.words(layer, name .. "Goal", fixed and "Finish 15 daily missions" or MissionsScreen.describe(m), x + 36, y + 16, CARD.w - 72, 84, 36))
		goal.TextWrapped, goal.TextYAlignment, goal.LineHeight = true, Enum.TextYAlignment.Top, 1
		local rowY = y + 108
		if fixed then
			-- The week: a day gets the Hangar's green crayon square and the Training board's tick when a daily mission was
			-- finished on it.
			for i, letter in DAYS do
				local on = missions.calendar:sub(i, i) == "1"
				local dayX = x + 36 + (i - 1) * 46
				ui.image(layer, name .. "Day" .. i, on and Assets.hangar.bar.green or Assets.hangar.bar.empty, dayX, rowY - 4, 40, 36).ZIndex = 1
				local mark = ui.words(layer, name .. "Letter" .. i, letter, dayX, rowY - 4, 40, 36, 26)
				mark.TextXAlignment, mark.ZIndex = Enum.TextXAlignment.Center, 2
				local tick = ui.image(layer, name .. "Tick" .. i, Assets.trainingboard.tick, dayX + 4, rowY - 14, 40, 36)
				tick.Visible, tick.ZIndex = on, 3
			end
			ui.words(layer, name .. "Progress", math.min(missions.dailiesDone, 15) .. " / 15", x + 372, rowY - 6, 160, 44, 32)
		else
			MissionsScreen.bar(ui, layer, name, x + 36, rowY + 2, 300, m.progress / goalOf(m))
			ui.words(layer, name .. "Progress", done and "Done!" or progressWords(m), x + 350, rowY - 6, 180, 44, 32)
		end
		local rewardX = x + 545
		local chest = CHEST[tier]
		if chest then
			Opening.picture(ui.image(layer, name .. "Chest", Assets.hangarShelf.chestAtlas, rewardX, rowY - 10, 56, 50), Looks.chest(chest))
			rewardX += 62
		end
		PaperUI.loud(ui.words(layer, name .. "Reward", REWARDS[tier], rewardX, rowY - 6, x + CARD.w - 30 - rewardX, 44, 32))
		-- Claim beside every card in the same place; Swap under it, only while the mission is still open.
		if claimed then
			ui.button(layer, name .. "Claim", Assets.unlock.buttonCream, "Claimed", BUTTONS, y + 10, 270, 84, 0, function() end, 36)
		elseif done then
			ui.button(layer, name .. "Claim", Assets.hangar.buttonGreen, "Claim!", BUTTONS, y + 10, 270, 84, -1, function() api.claim(list, index) end, 42)
		else
			ui.button(layer, name .. "Claim", Assets.unlock.buttonCream, "Not yet", BUTTONS, y + 10, 270, 84, 0, function() end, 36)
		end
		local price = not fixed and not done and api.swapPrice(missions, list, index)
		if price then
			ui.button(layer, name .. "Swap", Assets.mainmenu.strip.blue, price == 0 and "Free swap" or ("Swap: " .. PaperUI.commas(price) .. " Paper"),
				BUTTONS + 10, y + 104, 250, 52, 0, function() api.swap(list, index) end, 26)
		end
	end

	local function draw()
		ui.begin()
		local paper = ui.image(sheet, "MissionsSheet", Assets.hangarShelf.statsWide, 102, 13, 1716, 1054, LEVEL)
		paper.ScaleType = Enum.ScaleType.Stretch
		local layer = ui.instance(sheet, "MissionsLayer", "Frame")
		layer.BackgroundTransparency, layer.Size, layer.ZIndex = 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), 2
		PaperUI.loud(ui.words(layer, "Title", "Missions", CARD.x, 84, 380, 86, 66))
		for i, name in { "daily", "weekly" } do
			local on = tab == name
			ui.button(layer, name .. "Tab", on and Assets.hangar.buttonGreen or Assets.unlock.buttonCream, name == "daily" and "Daily" or "Weekly",
				CARD.x + (i - 1) * 240, 168, 220, 76, on and -1 or 1, function() tab = name; draw() end, 40)
		end
		ui.button(layer, "Close", Assets.mainmenu.boxRed, "X", 1633, 144, 87, 87, 1, function() api.back() end, 50)
		if missions then
			local now = workspace:GetServerTimeNow()
			local reset = tab == "daily" and (missions.day + 1) * 86400 or ((missions.week + 1) * 7 - 3) * 86400
			local timer = ui.words(layer, "Timer", "New missions in " .. left(math.max(0, math.floor(reset - now))), 990, 184, 620, 44, 30)
			timer.TextXAlignment = Enum.TextXAlignment.Right
			local step = CARD.h + CARD.gap[tab]
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
