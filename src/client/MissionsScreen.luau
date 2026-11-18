-- The Missions sheet (docs/decisions/2026-11-18-daily-and-weekly-missions.md): the chest sheet's notebook paper over the
-- main menu board, Daily and Weekly tabs, one paper card per mission (goal, progress, reward, Claim and Swap).
-- The missions themselves are made and checked on the server (src/shared/Missions.luau); this only draws them.
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local Looks = require(Root.Shared.LooksRules)
local Catalog = require(Root.Generated.Catalog)
local PaperUI = require(script.Parent.PaperUI)
local Widgets = require(script.Parent.HangarWidgets)
local Opening = require(script.Parent.ChestOpening)
local MissionsScreen = {}

local CARD = Color3.fromRGB(248, 238, 222)
local DONE = Color3.fromRGB(226, 244, 214)
local BAR = { done = Color3.fromRGB(63, 168, 60), going = Color3.fromRGB(70, 140, 214) }
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
				boosts = "collect %s speed boosts", targets = "hit %s paper targets" })[m.action]:format(PaperUI.commas(k)) .. " in one match"
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

local function finished(m)
	return m.progress >= (m.action == "minutes" and m.kind == "total" and m.count * 60 or m.count)
end
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
	local tab, missions = "daily", nil

	local function card(paper, name, m, list, index, y, h, fixed)
		local box = ui.instance(paper, name, "Frame")
		box.Position, box.Size, box.BorderSizePixel = UDim2.fromOffset(200, y), UDim2.fromOffset(1270, h), 0
		local done = fixed and missions.dailiesDone >= 15 or not fixed and finished(m)
		local claimed = fixed and missions.fixedClaimed or not fixed and m.claimed
		box.BackgroundColor3 = done and DONE or CARD
		local stroke = ui.instance(box, "Edge", "UIStroke"); stroke.Color, stroke.Thickness = PaperUI.INK, 3
		ui.instance(box, "Round", "UICorner").CornerRadius = UDim.new(0, 10)
		PaperUI.loud(ui.words(box, "Goal", fixed and "Finish 15 daily missions" or MissionsScreen.describe(m), 30, 10, 900, 60, 40))
		local barY = h - 54
		if fixed then
			-- The week: a day is ticked when at least one daily mission was finished on it.
			for i, letter in DAYS do
				local on = missions.calendar:sub(i, i) == "1"
				local day = ui.instance(box, "Day" .. i, "Frame")
				day.Position, day.Size, day.BorderSizePixel = UDim2.fromOffset(30 + (i - 1) * 50, barY - 8), UDim2.fromOffset(42, 42), 0
				day.BackgroundColor3 = on and BAR.done or CARD
				local edge = ui.instance(day, "Edge", "UIStroke"); edge.Color, edge.Thickness = PaperUI.INK, 2
				local mark = ui.words(day, "Letter", on and "✓" or letter, 0, 0, 42, 42, 30)
				mark.TextXAlignment = Enum.TextXAlignment.Center
			end
			ui.words(box, "Progress", math.min(missions.dailiesDone, 15) .. " / 15", 390, barY - 10, 200, 46, 34)
		else
			local track = ui.instance(box, "Track", "Frame")
			track.Position, track.Size, track.BorderSizePixel = UDim2.fromOffset(30, barY), UDim2.fromOffset(420, 30), 0
			track.BackgroundColor3 = Color3.fromRGB(236, 222, 202)
			local edge = ui.instance(track, "Edge", "UIStroke"); edge.Color, edge.Thickness = PaperUI.INK, 2
			ui.instance(track, "Round", "UICorner").CornerRadius = UDim.new(0, 8)
			local fill = ui.instance(track, "Fill", "Frame")
			local target = m.action == "minutes" and m.kind == "total" and m.count * 60 or m.count
			fill.Size, fill.BorderSizePixel = UDim2.fromScale(math.clamp(m.progress / target, 0, 1), 1), 0
			fill.BackgroundColor3 = done and BAR.done or BAR.going
			ui.instance(fill, "Round", "UICorner").CornerRadius = UDim.new(0, 8)
			ui.words(box, "Progress", progressWords(m), 465, barY - 8, 230, 46, 34)
		end
		local tier = fixed and "fixed" or m.tier
		ui.words(box, "RewardLabel", "Reward", 720, barY - 40, 300, 32, 26)
		local chest = CHEST[tier]
		local rewardX = 720
		if chest then
			local picture = ui.image(box, "Chest", Assets.hangarShelf.chestAtlas, 712, barY - 8, 56, 50)
			Opening.picture(picture, Looks.chest(chest))
			rewardX = 776
		end
		PaperUI.loud(ui.words(box, "Reward", REWARDS[tier], rewardX, barY - 6, 1000 - rewardX, 46, 34))
		-- Claim sits in the same place on every card; Swap under it, only while the mission is still open.
		local claimH = math.min(86, h - 74)
		if claimed then
			ui.button(box, "Claim", Assets.unlock.buttonCream, "Claimed", 980, 14, 270, claimH, 0, function() end, 36)
		elseif done then
			ui.button(box, "Claim", Assets.hangar.buttonGreen, "Claim!", 980, 14, 270, claimH, -1, function() api.claim(list, index) end, 42)
		else
			ui.button(box, "Claim", Assets.unlock.buttonCream, "Not yet", 980, 14, 270, claimH, 0, function() end, 36)
		end
		local price = not fixed and not done and api.swapPrice(missions, list, index)
		if price then
			ui.button(box, "Swap", Assets.mainmenu.strip.blue, price == 0 and "Free swap" or ("Swap: " .. PaperUI.commas(price) .. " Paper"),
				990, h - 56, 250, 48, 0, function() api.swap(list, index) end, 26)
		end
	end

	local function draw()
		ui.begin()
		local paper = ui.image(sheet, "MissionsSheet", Assets.hangarShelf.statsWide, 102, 13, 1716, 1054)
		paper.ScaleType = Enum.ScaleType.Stretch
		PaperUI.loud(ui.words(paper, "Title", "Missions", 200, 108, 420, 86, 66))
		for i, name in { "daily", "weekly" } do
			local on = tab == name
			ui.button(paper, name .. "Tab", on and Assets.hangar.buttonGreen or Assets.unlock.buttonCream, name == "daily" and "Daily" or "Weekly",
				560 + (i - 1) * 240, 116, 220, 80, on and -1 or 1, function() tab = name; draw() end, 40)
		end
		ui.button(paper, "Close", Assets.mainmenu.boxRed, "X", 1531, 131, 87, 87, 1, function() api.back() end, 50)
		if missions then
			local now = workspace:GetServerTimeNow()
			local reset = tab == "daily" and (missions.day + 1) * 86400 or ((missions.week + 1) * 7 - 3) * 86400
			local timer = ui.words(paper, "Timer", "New missions in " .. left(math.max(0, math.floor(reset - now))), 900, 208, 570, 44, 30)
			timer.TextXAlignment = Enum.TextXAlignment.Right
			if tab == "daily" then
				for i, m in missions.daily do card(paper, "Daily" .. i, m, "daily", i, 262 + (i - 1) * 230, 200) end
			else
				for i, m in missions.weekly do card(paper, "Weekly" .. i, m, "weekly", i, 262 + (i - 1) * 176, 160) end
				card(paper, "Fixed", nil, "fixed", 1, 262 + 3 * 176, 160, true)
			end
		end
		ui.finish()
	end

	function self.update(_, profile)
		missions = profile and profile.missions
		draw()
	end
	function self.open(which) tab = which or "daily"; draw() end
	draw()
	return self
end

return MissionsScreen
