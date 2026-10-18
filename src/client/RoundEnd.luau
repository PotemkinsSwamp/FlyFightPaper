-- The round end, played out in the room (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md):
-- "Pencils down!", then the camera visits the top 3 standing on their desks while a results card shows the scores;
-- then the vote lap card (fly through a ring, or press 1/2/3); then the next round's name. No menu opens.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local MatchRules = require(Root.Shared.MatchRules)
local Lines = require(Root.Shared.Lines)
local Rounds = require(Root.Generated.Gameplay).rounds
local UIArt = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)

local MODES = { { "FFA", "Free-for-all", "blue" }, { "TDM", "Team dogfight", "pink" }, { "CONTROL", "Airspace Control", "green" } }
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
local PLACES = { "1st", "2nd", "3rd" }
local BANNER_SECONDS = 1.6 -- "Pencils down!" on its own before the camera leaves your plane

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

	-- Results card (right), and the place tag for whoever the camera is looking at (bottom left).
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
	local tag = image(sheet, "PlaceTag", UIArt.hud.notebook, 60, 840, 620, 150, -2)
	tag.ScaleType = Enum.ScaleType.Stretch
	local tagWords = words(tag, "Words", "", 30, 20, 560, 110, 64)
	tagWords.TextXAlignment, tagWords.FontFace = Enum.TextXAlignment.Center, Font.fromEnum(Enum.Font.PermanentMarker)

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

	local state = { phase = nil, snap = nil, shots = nil, startedAt = 0 }
	local function show(part) for _, child in { banner, card, tag, vote } do child.Visible = child == part or (type(part) == "table" and table.find(part, child) ~= nil) end end

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

	-- Camera shots: 3rd, then 2nd, then 1st, each from the middle of the room looking back at their desk.
	local function planShots(snap)
		local shots = {}
		local winners = MatchRules.winners(snap.result)
		for place = #winners, 1, -1 do
			local row = winners[place]
			for _, model in (workspace:FindFirstChild("Arena") or workspace):GetChildren() do
				if model:IsA("Model") and model:GetAttribute("PilotId") == row.actorId then
					table.insert(shots, { model = model, place = place, name = row.displayName, points = math.floor(row.contribution or 0) })
					break
				end
			end
		end
		return shots
	end

	RunService:BindToRenderStep("RoundEndCamera", Enum.RenderPriority.Camera.Value + 2, function()
		if state.phase ~= "RESULTS" or not state.shots or #state.shots == 0 then return end
		local elapsed = os.clock() - state.startedAt - BANNER_SECONDS
		if elapsed < 0 then return end
		local each = (Rounds.results_seconds - BANNER_SECONDS - 0.4) / #state.shots
		local shot = state.shots[math.min(#state.shots, math.floor(elapsed / each) + 1)]
		if not shot.model.Parent then return end
		local box, size = shot.model:GetBoundingBox()
		local toward = (Vector3.new(0, box.Position.Y, 0) - box.Position) * Vector3.new(1, 0, 1)
		toward = toward.Magnitude > 1 and toward.Unit or Vector3.zAxis
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		local drift = (elapsed % each) / each -- a slow push in
		camera.CFrame = CFrame.lookAt(box.Position + toward * size.Y * (2.6 - drift * 0.4) + Vector3.new(0, size.Y * 0.35, 0), box.Position)
		tagWords.Text = string.format("%s  %s  %d pts", PLACES[shot.place], shot.name, shot.points)
		show({ card, tag })
	end)

	local function update(snap)
		state.snap = snap
		if snap.phase ~= state.phase then
			state.phase, state.startedAt = snap.phase, os.clock()
			if snap.phase == "RESULTS" then state.shots = planShots(snap) end
		end
		if not player:GetAttribute("InMatch") or snap.phase == "ACTIVE" or snap.phase == "READY" or snap.phase == "ENDING" then
			cover.Visible = false
			return
		end
		cover.Visible = true
		if snap.phase == "RESULTS" then
			fillResults(snap)
			headline.Text, subline.Text = "Pencils down!", winnerLine(snap)
			if os.clock() - state.startedAt < BANNER_SECONDS or #state.shots == 0 then show({ banner, card }) end
			-- An avatar still loading at the start: look again; with none found, the card just stays up.
			if #state.shots < #MatchRules.winners(snap.result) then state.shots = planShots(snap) end
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
