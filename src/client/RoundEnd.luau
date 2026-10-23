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
local LevelBar = require(script.Parent.LevelBar)

local MODES = { { "FFA", "Free-for-all", "blue" }, { "TDM", "Team dogfight", "pink" }, { "CONTROL", "Airspace Control", "green" } }
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
local PLACES = { "1st", "2nd", "3rd" }

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
	local headline = words(banner, "Headline", "", 40, 18, 720, 80, 72)
	headline.TextXAlignment, headline.FontFace = Enum.TextXAlignment.Center, Font.fromEnum(Enum.Font.PermanentMarker)
	local subline = words(banner, "Subline", "", 40, 92, 720, 44, 34)
	subline.TextXAlignment = Enum.TextXAlignment.Center

	-- Results card (right): every pilot's folds, assists, crashes and points; team totals in team rounds; your
	-- Paper and XP from the round with your level bar filling up.
	-- The index card art has tape above the paper: the paper itself runs x 44-639, y 150-974 inside this box.
	local card = image(sheet, "Results", UIArt.ingame.indexCard, 1220, 40, 680, 1000, 1)
	card.ScaleType = Enum.ScaleType.Stretch
	local title = words(card, "Title", "Results", 44, 158, 595, 56, 50)
	title.TextXAlignment = Enum.TextXAlignment.Center
	local teams = words(card, "Teams", "", 44, 210, 595, 44, 38)
	teams.TextXAlignment, teams.RichText = Enum.TextXAlignment.Center, true
	local function cell(name, text, x, y, w, size, centred)
		local label = words(card, name, text, x, y, w, 44, size)
		label.TextTruncate = Enum.TextTruncate.AtEnd
		if centred then label.TextXAlignment = Enum.TextXAlignment.Center end
		return label
	end
	local COLUMNS = { { "Folds", 300, 74, "kills" }, { "Assists", 374, 84, "assists" }, { "Crashes", 458, 90, "deaths" }, { "Pts", 548, 80, "contribution" } }
	cell("HeadPilot", "Pilot", 100, 256, 200, 26).TextColor3 = Color3.fromRGB(30, 60, 140)
	for _, column in COLUMNS do cell("Head" .. column[1], column[1], column[2], 256, column[3], 24, true).TextColor3 = Color3.fromRGB(30, 60, 140) end
	local rows = {}
	for i = 1, 9 do
		local y = 248 + i * 44
		local highlight = image(card, "Mine" .. i, UIArt.results.rowHighlight, 50, y - 2, 584, 44)
		highlight.ScaleType, highlight.Visible = Enum.ScaleType.Stretch, false
		rows[i] = { highlight = highlight, place = cell("Place" .. i, "", 56, y, 46, 26), name = cell("Name" .. i, "", 100, y, 200, 30), numbers = {} }
		for _, column in COLUMNS do rows[i].numbers[column[4]] = cell(column[1] .. i, "", column[2], y, column[3], 30, true) end
	end
	local earned = cell("Earned", "", 44, 746, 595, 36, true)
	local xpBar = LevelBar.new(card, 64, 790, 556, 34)

	-- Vote card (top): one strip per mode with its live count; yours is ticked.
	local vote = Instance.new("Frame")
	-- Below the match strip, which shows the vote lap's clock (Alan 2026-10-23: the cards covered it).
	vote.Name, vote.BackgroundTransparency, vote.Size, vote.Position, vote.Parent = "Vote", 1, UDim2.fromOffset(1920, 300), UDim2.fromOffset(0, 80), sheet
	local voteHelp = words(vote, "Help", "", 360, 186, 1200, 50, 36)
	voteHelp.TextXAlignment, voteHelp.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(250, 245, 230)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Parent = 3, voteHelp
	local strips = {}
	for i, mode in MODES do
		strips[i] = button(vote, "Vote" .. mode[1], UIArt.results.strip[mode[3]], "", 330 + (i - 1) * 430, 50, 400, 130, (i - 2) * 1.5, function()
			Root.RoundAction:FireServer("vote", mode[1])
		end, 38)
	end

	local state = { phase = nil, snap = nil, stage = "banner", profileXP = nil, mine = nil, cardAt = 0 }
	local function show(part) for _, child in { banner, card, vote } do child.Visible = child == part or (type(part) == "table" and table.find(part, child) ~= nil) end end

	local TEAM_INK = { ["team:1"] = Color3.fromRGB(200, 40, 40), ["team:2"] = Color3.fromRGB(40, 80, 200) }
	local function fillResults(snap)
		local result = snap.result or {}
		local list = table.clone(result.participants or {})
		table.sort(list, function(a, b) return (a.place or 99) < (b.place or 99) end)
		local me = player.DisplayName
		state.mine = nil
		for _, p in list do if p.displayName == me then state.mine = p end end
		for i, row in rows do
			local p = list[i]
			-- The last line is always you, if you didn't make the top 8.
			local myLine = state.mine and table.find(list, state.mine)
			if i == #rows and myLine and myLine >= #rows then p = state.mine end
			row.place.Text = p and (PLACES[p.place] or tostring(p.place or "")) or ""
			row.name.Text = p and p.displayName or ""
			row.name.TextColor3 = p and TEAM_INK[p.teamId] or PaperUI.INK
			for key, label in row.numbers do label.Text = p and tostring(math.floor(p[key] or 0)) or "" end
			row.highlight.Visible = p ~= nil and p == state.mine
		end
		local totals = snap.mode ~= "FFA" and snap.teams
		teams.Text = totals and string.format('<font color="#C82828">Red %d</font>  -  <font color="#2850C8">Blue %d</font>', math.floor(totals["team:1"] or 0), math.floor(totals["team:2"] or 0)) or ""
		earned.Text = state.mine and string.format("You: +%d Paper   +%d XP", state.mine.paper or 0, state.mine.xp or 0) or ""
	end
	-- Your level bar fills from where you were before this round to where you are now.
	RunService.RenderStepped:Connect(function()
		local mine = state.mine
		local shown = cover.Visible and card.Visible and mine ~= nil and state.profileXP ~= nil
		xpBar.show(shown)
		if not shown then return end
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
			Cutscene.stop()
			if snap.phase == "RESULTS" and inMatch then
				state.stage, state.cardAt = "card", os.clock() -- stays on the card if the cutscene can't play
				Cutscene.play(MatchRules.winners(snap.result), function(stage)
					if stage == "card" and state.stage ~= "card" then state.cardAt = os.clock() end
					state.stage = stage
					if state.snap then update(state.snap) end
				end)
			end
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
	Input.InputBegan:Connect(function(input, processed)
		local index = KEYS[input.KeyCode]
		if index and not processed and state.phase == "VOTE" and not Input:GetFocusedTextBox() then
			Root.RoundAction:FireServer("vote", MODES[index][1])
		end
	end)
end

return RoundEnd
