-- The round end, played out in the room (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md):
-- "Pencils down!", then the winners' cutscene (WinnersCutscene) with the results card; then the vote lap card (fly
-- through a ring, or press 1/2/3); then the next round's name. No menu opens.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local MatchRules = require(Root.Shared.MatchRules)
local Lines = require(Root.Shared.Lines)
local Rounds = require(Root.Generated.Gameplay).rounds
local UIArt = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local Cutscene = require(script.Parent.WinnersCutscene)
local WinnersSound = require(script.Parent.WinnersSound)
local LevelBar = require(script.Parent.LevelBar)

local MODES = { { "FFA", "Free-for-all", "blue" }, { "TDM", "Team dogfight", "pink" }, { "CONTROL", "Airspace Control", "green" } }
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
local PLACES = { "1st", "2nd", "3rd" } -- then "4th".."12th" (ponytail: a room holds 12; 21st and up would need more)

local RoundEnd = {}

local function modeName(code)
	for _, mode in MODES do if mode[1] == code then return mode[2] end end
	return tostring(code)
end

function RoundEnd.start()
	local player = Players.LocalPlayer
	local cover, sheet = PaperUI.screen(player:WaitForChild("PlayerGui"), "RoundEnd", {}, true)
	cover.Parent.DisplayOrder = 6 -- under the menus, over the flight HUD
	cover.Active = false
	local words, image, button = PaperUI.words, PaperUI.image, PaperUI.button

	-- Top banner: a notebook strip with big crayon words and a smaller line under it.
	local banner = image(sheet, "Banner", UIArt.hud.notebook, 560, 40, 800, 150)
	banner.ScaleType = Enum.ScaleType.Stretch
	-- Phones: the banner and the vote drop below Roblox's top bar, where the Menu button and match strip sit.
	PaperUI.phone(banner, { Position = UDim2.fromOffset(960, 245) })
	local headline = words(banner, "Headline", "", 40, 18, 720, 80, 72)
	headline.TextXAlignment, headline.FontFace = Enum.TextXAlignment.Center, Font.fromEnum(Enum.Font.PermanentMarker)
	local subline = PaperUI.phone(words(banner, "Subline", "", 40, 92, 720, 44, 34), { TextSize = 40 })
	subline.TextXAlignment = Enum.TextXAlignment.Center

	-- Results card, a school report card (docs/plan/REPORT-CARD-PLAN.md, Alan 2026-11-11): the top five and your own
	-- row with folds, assists, crashes, points and a red-pen grade from their place; the teacher's note about the round;
	-- your Paper and XP with your level bar filling up. The card picture is only paper, printing and lines
	-- (tools/art/report_card.py); every word is game text. Free-for-all: one card on the right, its top box your place.
	-- Team rounds (Alan 2026-10-29: see both scores side by side): a card per team, Red left and Blue right, its top box
	-- the team score; the winners' card has the gold star.
	local card = Instance.new("Frame")
	card.Name, card.BackgroundTransparency, card.Size, card.Parent = "Results", 1, UDim2.fromOffset(1920, 1080), sheet
	-- Every cell keeps to its own column (Alan 2026-10-29: a long name ran into the numbers): its words are `size`
	-- points (`phoneSize` on a phone) and shrink, on one line, until they fit.
	local function cell(page, name, text, x, y, w, h, size, centred, phoneSize)
		local label = words(page, name, text, x, y, w, h, size)
		label.TextWrapped, label.TextScaled = false, true -- (this order: turning wrap off after turns shrink off)
		if centred then label.TextXAlignment = Enum.TextXAlignment.Center end
		local cap = Instance.new("UITextSizeConstraint")
		cap.Parent = label
		PaperUI.onPhone(function(phone) cap.MaxTextSize = phone and phoneSize or size end)
		return label
	end
	-- The card's table (keep in step with report_card.py): place | pupil | folds | assists | crashes | pts | grade.
	local COLS = { 40, 92, 268, 336, 418, 500, 568, 640 }
	local NUMBERS = { { "Folds", "kills" }, { "Assists", "assists" }, { "Crashes", "deaths" }, { "Pts", "contribution" } }
	local ROWS, ROW_TOP, ROW_PITCH = 6, 236, 58
	local NAVY, INK, RED_PEN = Color3.fromRGB(38, 58, 116), Color3.fromRGB(28, 48, 120), Color3.fromRGB(200, 38, 38)
	-- Printed words in a typewriter face, heads in round print, the teacher's note in red pen; names and numbers ink.
	local PRINTED, HEADS, PEN = Font.fromEnum(Enum.Font.SpecialElite), Font.fromEnum(Enum.Font.FredokaOne), Font.fromEnum(Enum.Font.IndieFlower)
	local function style(label, font, colour)
		if font then label.FontFace = font end
		label.TextColor3 = colour
		return label
	end
	local function ring(page, name, x, y, w, h)
		local loop = image(page, name, UIArt.results.redRing, x, y, w, h)
		loop.ScaleType, loop.Visible = Enum.ScaleType.Stretch, false
		return loop
	end
	local function makePage(name)
		local page = image(card, name, UIArt.results.reportCard, 1220, 40, 680, 900)
		page.ScaleType = Enum.ScaleType.Stretch
		local fit = Instance.new("UIScale")
		fit.Name, fit.Parent = "Fit", page
		local it = { page = page, rows = {} }
		style(cell(page, "School", "PAPER FLIGHT 101", 150, 52, 330, 34, 26, false, 30), PRINTED, NAVY)
		style(cell(page, "Title", "REPORT CARD", 150, 84, 330, 62, 56, false, 56), HEADS, NAVY)
		it.term = style(cell(page, "Term", "", 150, 146, 330, 30, 22, false, 28), PRINTED, NAVY)
		-- Top right box: your place (circled) or the team's score.
		it.boxLabel = style(cell(page, "BoxLabel", "", 504, 52, 132, 30, 21, true, 26), PRINTED, NAVY)
		it.boxRing = ring(page, "BoxRing", 512, 88, 116, 78)
		it.boxValue = style(cell(page, "BoxValue", "", 520, 92, 100, 70, 60, true, 60), nil, RED_PEN)
		for k, head in { "", "Pupil", "Folds", "Assists", "Crashes", "Pts", "Grade" } do
			if head ~= "" then
				style(cell(page, "Head" .. head, head, COLS[k] + 5, ROW_TOP - 40, COLS[k + 1] - COLS[k] - 10, 34, 24, head ~= "Pupil", 28), HEADS, NAVY)
			end
		end
		for i = 1, ROWS do
			local y = ROW_TOP + (i - 1) * ROW_PITCH
			local highlight = image(page, "Mine" .. i, UIArt.results.rowHighlight, COLS[1] + 3, y + 4, COLS[8] - COLS[1] - 6, ROW_PITCH - 8)
			highlight.ScaleType, highlight.Visible = Enum.ScaleType.Stretch, false
			local function at(k, key, size, phoneSize)
				return style(cell(page, key .. i, "", COLS[k] + 4, y + 6, COLS[k + 1] - COLS[k] - 8, ROW_PITCH - 12, size, k ~= 2, phoneSize), nil, INK)
			end
			local row = { highlight = highlight, place = at(1, "Place", 30, 38), name = at(2, "Name", 30, 38), numbers = {} }
			for k, column in NUMBERS do row.numbers[column[2]] = at(k + 2, column[1], 30, 40) end
			row.ring = ring(page, "GradeRing" .. i, COLS[7] + 5, y + 7, COLS[8] - COLS[7] - 10, ROW_PITCH - 14)
			row.grade = style(at(7, "Grade", 38, 44), nil, RED_PEN)
			it.rows[i] = row
		end
		local noteY = ROW_TOP + ROWS * ROW_PITCH + 16
		style(cell(page, "NoteLabel", "Teacher's note:", 46, noteY + 4, 186, 36, 22, false, 28), PRINTED, NAVY)
		it.note = style(cell(page, "Note", "", 242, noteY - 2, 388, 44, 36, false, 40), PEN, RED_PEN)
		-- The winners' gold star, stuck by the note (the note gets shorter to make room).
		it.star = image(page, "Star", UIArt.results.goldStar, 562, noteY - 10, 70, 66)
		it.star.Rotation = -12
		it.pocket = style(cell(page, "PocketLabel", "Your pocket money:", 46, noteY + 62, 246, 40, 24, false, 28), PRINTED, NAVY)
		it.earned = style(cell(page, "Earned", "", 296, noteY + 58, 338, 46, 34, false, 38), nil, INK)
		it.xpBar = LevelBar.new(page, 64, noteY + 112, 556, 34)
		PaperUI.phone(page.Level, { TextSize = 44, Size = UDim2.fromOffset(250, 41) })
		PaperUI.phone(page.XPCount, { TextSize = 36 })
		PaperUI.phone(page.NextUnlock, { TextSize = 36 })
		return it
	end
	local pages = { makePage("Page1"), makePage("Page2") }

	-- Vote card (top): one strip per mode with its live count; yours is ticked.
	local vote = Instance.new("Frame")
	-- Below the match strip, which shows the vote lap's clock (Alan 2026-10-23: the cards covered it).
	vote.Name, vote.BackgroundTransparency, vote.Size, vote.Position, vote.Parent = "Vote", 1, UDim2.fromOffset(1920, 300), UDim2.fromOffset(0, 80), sheet
	PaperUI.phone(vote, { Position = UDim2.fromOffset(0, 190) })
	local voteHelp = words(vote, "Help", "", 360, 186, 1200, 50, 36)
	-- Phones: the help line and the cards' words were about 13 points (2026-10-29 check); taller cards, ~17-point words.
	PaperUI.phone(voteHelp, { Position = UDim2.fromOffset(110, 236), Size = UDim2.fromOffset(1700, 80), TextSize = 64 })
	voteHelp.TextXAlignment, voteHelp.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(250, 245, 230)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Parent = 3, voteHelp
	local strips = {}
	for i, mode in MODES do
		strips[i] = button(vote, "Vote" .. mode[1], UIArt.results.strip[mode[3]], "", 330 + (i - 1) * 430, 50, 400, 130, (i - 2) * 1.5, function()
			Root.RoundAction:FireServer("vote", mode[1])
		end, 38)
		PaperUI.phone(strips[i], { Size = UDim2.fromOffset(400, 170), Position = strips[i].Position + UDim2.fromOffset(0, 20) })
		PaperUI.phone(strips[i].Label, { TextScaled = true }) -- as big as fits, up to 50 ("3  Airspace Control" is long)
		local most = Instance.new("UITextSizeConstraint")
		most.MaxTextSize, most.Parent = 50, strips[i].Label
	end

	local state = { phase = nil, snap = nil, stage = "banner", profileXP = nil, mine = nil, minePage = 1, cardAt = 0 }
	local function show(part) for _, child in { banner, card, vote } do child.Visible = child == part or (type(part) == "table" and table.find(part, child) ~= nil) end end

	local TEAM_NAMES = { ["team:1"] = "Red team", ["team:2"] = "Blue team" }
	-- Where the pages sit (centre x, y, scale, turn): free-for-all one page on the right; team rounds two smaller pages
	-- side by side, turned a little.
	-- live: Tab's standings, a small page at each side so the middle of the screen stays clear to fly.
	local LAYOUT = { solo = { { 1560, 490, 1, 0 } }, teams = { { 1060, 439, 0.8, 1.5 }, { 1636, 439, 0.8, -1.5 } },
		live = { { 250, 470, 0.7, 1 }, { 1670, 470, 0.7, -1 } },
		-- A phone's Health, Lift and Boost sit top left, so the left page goes below them (phone check 2026-11-07).
		livePhone = { { 250, 750, 0.7, 1 }, { 1670, 470, 0.7, -1 } } }
	local function placeWord(place) return PLACES[place] or place .. "th" end
	-- A page's rows: the top five of `list` and, if you're not among them, you on the last line. gradeOf: a pilot's
	-- grade (results only).
	local function fillRows(it, list, rank, gradeOf)
		local myLine = state.mine and table.find(list, state.mine)
		for i, row in it.rows do
			local p = list[i]
			if i == ROWS and myLine and myLine >= ROWS then p = state.mine end
			local place = p and rank(p, p == state.mine and myLine or i)
			row.place.Text = place and placeWord(place) or ""
			local name, cut = p and p.displayName or "", nil
			-- A phone's Tab page is small: a long name would shrink too far to read, so it's cut short instead.
			if state.live and PaperUI.isPhone() and utf8.len(name) and utf8.len(name) > 11 then cut = utf8.offset(name, 11) end
			row.name.Text = cut and name:sub(1, cut - 1) .. ".." or name
			for key, label in row.numbers do label.Text = p and tostring(math.floor(p[key] or 0)) or "" end
			row.grade.Text = p and gradeOf and gradeOf(p) or ""
			row.ring.Visible = row.grade.Text == "A+"
			row.highlight.Visible = p ~= nil and p == state.mine
		end
	end
	-- A card's top: the term (mode, and the team on a team card) and the top right box: the team's score on a team card
	-- (a team dogfight counts folds, Airspace Control zone points), else your place, circled.
	local function heading(it, snap, teamId, live, yourPlace)
		it.term.Text = "Term: " .. modeName(snap.mode) .. (teamId and ", " .. TEAM_NAMES[teamId] or "") .. (live and " (so far)" or "")
		it.boxLabel.Text = teamId and "Team score" or "Your place"
		it.boxValue.Text = teamId and tostring(math.floor(snap.teams[teamId] or 0)) or yourPlace and placeWord(yourPlace) or ""
		it.boxRing.Visible = not teamId and yourPlace ~= nil
	end
	-- The teacher's note and gold star (results only; the note is shorter beside the star).
	local function note(it, text, star)
		it.note.Text, it.star.Visible = text, star
		it.note.Size = UDim2.fromOffset(star and 300 or 388, 44)
	end
	local function layOut(name, count)
		for k, spot in LAYOUT[name == "live" and PaperUI.isPhone() and "livePhone" or name] do
			local page = pages[k].page
			page.Position, page.Fit.Scale, page.Rotation = UDim2.fromOffset(spot[1], spot[2]), spot[3], spot[4]
		end
		pages[2].page.Visible = count > 1
	end
	-- Tab's live standings (Alan 2026-11-06): every pilot, best first, from the same round news as the score strip, so
	-- it keeps up by itself. A free-for-all fills page 1 then page 2; a team round has a page per team. No grades yet.
	local function fillLive(snap)
		local list = table.clone(snap.pilots)
		table.sort(list, function(a, b)
			if (a.contribution or 0) ~= (b.contribution or 0) then return (a.contribution or 0) > (b.contribution or 0) end
			return a.displayName < b.displayName
		end)
		state.mine = nil
		for _, p in list do if p.displayName == player.DisplayName or p.displayName == player.Name then state.mine = p end end
		local function place(p)
			local at = 1
			for _, other in list do if (other.contribution or 0) > (p.contribution or 0) then at += 1 end end
			return at
		end
		local teamRound = snap.mode ~= "FFA" and snap.teams ~= nil
		layOut("live", (teamRound or #list > ROWS) and 2 or 1)
		for k, it in pages do
			local teamId = teamRound and "team:" .. k or nil
			note(it, "", false)
			it.pocket.Visible, it.earned.Text = false, ""
			heading(it, snap, teamId, true, state.mine and place(state.mine))
			local shown = {}
			for i, p in list do
				if teamId and p.teamId == teamId or not teamId and (i - 1) // ROWS + 1 == k then table.insert(shown, p) end
			end
			fillRows(it, shown, function(p) return place(p) end)
		end
	end
	local function fillResults(snap)
		local result = snap.result or {}
		local list = table.clone(result.participants or {})
		table.sort(list, function(a, b)
			if (a.place or 99) ~= (b.place or 99) then return (a.place or 99) < (b.place or 99) end
			return (a.contribution or 0) > (b.contribution or 0)
		end)
		local me = player.DisplayName
		state.mine = nil
		for _, p in list do if p.displayName == me then state.mine = p end end
		local teamRound = snap.mode ~= "FFA" and snap.teams ~= nil
		-- Grades from each pilot's place in the whole class: free-for-all the place shown; a team round by points across
		-- both teams (its places only rank the winning team, so the losing team's best got a C; seen in Play 2026-11-11).
		local function gradeOf(p)
			local place = not teamRound and p.place
			if not place then
				place = 1
				for _, other in list do if (other.contribution or 0) > (p.contribution or 0) then place += 1 end end
			end
			return MatchRules.grade(place, #list)
		end
		layOut(teamRound and "teams" or "solo", teamRound and 2 or 1)
		state.minePage = 1
		for k, it in pages do
			local teamId = teamRound and "team:" .. k or nil
			local mine = state.mine ~= nil and (not teamRound or state.mine.teamId == teamId)
			if mine then state.minePage = k end
			heading(it, snap, teamId, false, state.mine and state.mine.place)
			it.pocket.Visible = mine
			it.earned.Text = mine and string.format("+%d Paper   +%d XP", state.mine.paper or 0, state.mine.xp or 0) or ""
			if teamId then
				-- (both scores are in the cards' top boxes, side by side)
				local won = not result.draw and result.winningTeam == teamId
				note(it, result.draw and "A tie! Well flown, everyone." or won and TEAM_NAMES[teamId] .. " wins!" or "Good try, " .. TEAM_NAMES[teamId] .. "!", won)
				local team = {}
				for _, p in list do if p.teamId == teamId then table.insert(team, p) end end
				fillRows(it, team, function(_, line) return line end, gradeOf) -- places inside the team
			else
				note(it, list[1] and "Top of the class: " .. (list[1] == state.mine and "you" or list[1].displayName) .. "!" or "", false)
				fillRows(it, list, function(p) return p.place end, gradeOf)
			end
		end
	end
	-- Your level bar fills from where you were before this round to where you are now.
	RunService.RenderStepped:Connect(function()
		local mine = state.mine
		local shown = cover.Visible and card.Visible and mine ~= nil and state.profileXP ~= nil and not state.live
		for k, it in pages do it.xpBar.show(shown and k == state.minePage) end
		if not shown then return end
		local xpBar = pages[state.minePage].xpBar
		-- ponytail: "before" assumes the profile already holds this round's XP (it is paid as it is earned).
		local after = math.max(state.profileXP, mine.xp or 0)
		local before = math.max(0, after - (mine.xp or 0))
		local t = math.clamp((os.clock() - state.cardAt - 0.5) / 1.5, 0, 1)
		xpBar.set(before + (after - before) * (1 - (1 - t) ^ 2))
	end)
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile) state.profileXP = profile.xp end)

	local function winnerLine(snap)
		local result = snap.result or {}
		if result.draw then return "It's a tie!" end
		if result.winningTeam then return result.winningTeam == "team:1" and "Red team wins!" or "Blue team wins!" end
		local first = MatchRules.winners(result)[1]
		return first and (first.displayName == player.DisplayName and "You win the round!" or first.displayName .. " wins the round!") or "Round over"
	end

	local update
	function update(snap)
		state.snap = snap
		local inMatch = player:GetAttribute("InMatch")
		if snap.phase ~= state.phase then
			state.phase = snap.phase
			Root:SetAttribute("StandingsOpen", nil) -- each round starts with it closed
			Cutscene.stop()
			if state.stopSound then state.stopSound(); state.stopSound = nil end
			Root:SetAttribute("WinnersMoment", snap.phase == "RESULTS" and inMatch or nil) -- the match music fades out for it (Audio)
			if snap.phase == "RESULTS" and inMatch then
				local song = WinnersSound.TRACKS[Root:GetAttribute("DevWinnersSong")] -- the dev panel's "end: <song>" buttons, once
				Root:SetAttribute("DevWinnersSong", nil)
				state.stopSound = WinnersSound.play(song or WinnersSound.TRACKS[WinnersSound.pick()])
				state.stage, state.cardAt = "card", os.clock() -- stays on the card if the cutscene can't play
				Cutscene.play(MatchRules.winners(snap.result), function(stage)
					if stage == "card" and state.stage ~= "card" then state.cardAt = os.clock() end
					state.stage = stage
					if state.snap then update(state.snap) end
				end)
			end
		end
		state.live = inMatch and snap.phase == "ACTIVE" and snap.pilots ~= nil and Root:GetAttribute("StandingsOpen") == true
			and not Root:GetAttribute("TutorialOpen")
		if state.live then
			fillLive(snap)
			show(card)
			cover.Visible = true
			return
		end
		if not inMatch or snap.phase == "ACTIVE" or snap.phase == "READY" or snap.phase == "ENDING" then
			cover.Visible = false
			return
		end
		cover.Visible = true
		if snap.phase == "RESULTS" then
			fillResults(snap)
			headline.Text, subline.Text = "Pencils down!", winnerLine(snap)
			show(state.stage == "banner" and banner or state.stage == "card" and card or nil)
		elseif snap.phase == "VOTE" then
			local totals, mine = snap.voteTotals or {}, player:GetAttribute("Vote")
			for i, mode in MODES do
				local count = totals[mode[1]] or 0
				strips[i].Label.Text = string.format("%d  %s\n%d %s%s", i, mode[2], count, count == 1 and "vote" or "votes", mine == mode[1] and " (yours)" or "")
			end
			voteHelp.Text = mine and "Vote counted! Fly through another ring to change it." or "Fly through a ring to vote, or press 1, 2 or 3. Nothing can hurt you now."
			show(vote)
		elseif snap.phase == "COUNTDOWN" then
			headline.Text, subline.Text = Lines.stable("nextRound", snap.matchId and #snap.matchId or 0, modeName(Root:GetAttribute("DevMode") or snap.nextMode)), "Get ready to fight!" -- DevMode: Studio's mode buttons win over the vote
			show(banner)
		end
	end
	Root:WaitForChild("RoundView").OnClientEvent:Connect(update)
	player:GetAttributeChangedSignal("Vote"):Connect(function() if state.snap then update(state.snap) end end)
	Root:GetAttributeChangedSignal("StandingsOpen"):Connect(function() if state.snap then update(state.snap) end end)
	Input.InputBegan:Connect(function(input, processed)
		local index = KEYS[input.KeyCode]
		if index and not processed and state.phase == "VOTE" and not Input:GetFocusedTextBox() then
			Root.RoundAction:FireServer("vote", MODES[index][1])
		end
	end)
end

return RoundEnd
