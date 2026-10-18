-- The round end, played out in the room (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md):
-- "Pencils down!", then the winners' cutscene (WinnersCutscene) with the results card; then the vote lap card (fly
-- through a ring, or press 1/2/3); then the next round's name. No menu opens.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local MatchRules = require(Root.Shared.MatchRules)
local Lines = require(Root.Shared.Lines)
local Rounds = require(Root.Generated.Gameplay).rounds
local UIArt = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local Cutscene = require(script.Parent.WinnersCutscene)

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

	-- Results card (right).
	local card = image(sheet, "Results", UIArt.ingame.indexCard, 1330, 230, 560, 640, 1.5)
	card.ScaleType = Enum.ScaleType.Stretch
	local title = words(card, "Title", "Results", 0, 40, 560, 60, 52)
	title.TextXAlignment = Enum.TextXAlignment.Center
	local rows = {}
	for i = 1, 9 do
		local highlight = image(card, "Mine" .. i, UIArt.results.rowHighlight, 40, 100 + i * 52, 480, 48)
		highlight.ScaleType, highlight.Visible = Enum.ScaleType.Stretch, false
		rows[i] = { highlight = highlight, place = words(card, "Place" .. i, "", 60, 104 + i * 52, 70, 44, 32),
			name = words(card, "Name" .. i, "", 130, 104 + i * 52, 270, 44, 32), points = words(card, "Points" .. i, "", 400, 104 + i * 52, 100, 44, 32) }
		rows[i].name.TextTruncate, rows[i].points.TextXAlignment = Enum.TextTruncate.AtEnd, Enum.TextXAlignment.Right
	end

	-- Vote card (top): one strip per mode with its live count; yours is ticked.
	local vote = Instance.new("Frame")
	vote.Name, vote.BackgroundTransparency, vote.Size, vote.Parent = "Vote", 1, UDim2.fromOffset(1920, 300), sheet
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

	local state = { phase = nil, snap = nil, stage = "banner" }
	local function show(part) for _, child in { banner, card, vote } do child.Visible = child == part or (type(part) == "table" and table.find(part, child) ~= nil) end end

	local function fillResults(snap)
		local list = table.clone(snap.result and snap.result.participants or {})
		table.sort(list, function(a, b) return (a.place or 99) < (b.place or 99) end)
		local me = player.DisplayName
		for i, row in rows do
			local p = list[i]
			-- The last line is always you, if you didn't make the top 8.
			if i == #rows then
				for _, other in list do if other.displayName == me and (other.place or 99) > #rows - 1 then p = other end end
			end
			row.place.Text = p and PLACES[p.place] or p and tostring(p.place) or ""
			row.name.Text = p and p.displayName or ""
			row.points.Text = p and tostring(math.floor(p.contribution or 0)) or ""
			row.highlight.Visible = p ~= nil and p.displayName == me
		end
	end

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
				state.stage = "card" -- stays on the card if the cutscene can't play
				Cutscene.play(MatchRules.winners(snap.result), function(stage)
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
			headline.Text, subline.Text = Lines.stable("nextRound", snap.matchId and #snap.matchId or 0, modeName(snap.nextMode)), "Get ready to fight!"
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
