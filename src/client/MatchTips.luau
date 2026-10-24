-- Match Tips (docs/plan/TUTORIAL-PLAN.md "Lesson 5"; Alan OK'd the plan 2026-10-23): a small sticky note the first
-- time something happens in a real match, each tip once per account. The match never pauses: a tip goes after six
-- seconds on screen or on Got it (Space), one at a time, at least 20 seconds apart, so it never nags; only while a
-- round is on (the break has its own cards: Alan 2026-10-23, the tip covered the vote lap's). Tips a finished
-- lesson already taught are skipped. Settings > Match tips turns them off. Seen tips save in `lessons` (Schema.TIPS).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets)
local Lines = require(Root.Shared.Lines)
local PaperUI = require(script.Parent.PaperUI)
local ScreenFit = require(script.Parent.ScreenFit)
local Touch = require(script.Parent.TouchControls)
local FlightState = require(script.Parent.FlightController).state
local Zone = require(script.Parent.ControlZone).state
local Tips = {}

local SHOW_SECONDS, GAP_SECONDS, RECENT_SECONDS = 6, 20, 8 -- on screen; between tips; how long an event (a fold, a scrape) stays tip-worthy
local TEAM_NAMES = { ["team:1"] = "Red", ["team:2"] = "Blue" }

-- In priority order. when(c) = this tip fits right now; skip = a lesson that already taught it; point = what the
-- arrow points at ("lift" bar or the "zone"), if anything.
local TIPS = {
	{ key = "tipEdge", text = "Stay out there too long and your plane unfolds. Turn back!", when = function(c)
		return c.flying and Lines.is("turnBack", c.plane:GetAttribute("Message") or "") end },
	{ key = "tipLift", skip = "flight", text = "Lift is low: land at your desk or fly through a fan.", point = "lift", when = function(c)
		return c.flying and (c.plane:GetAttribute("Lift") or 1) / (c.plane:GetAttribute("LiftMax") or 90) < 0.25 end },
	{ key = "tipFolded", skip = "combat", text = "Folded! You'll be back at your desk in a moment.", when = function(c) return c.state == "DESTROYED" end },
	{ key = "tipFold", text = "Folded one! Every fold is points.", when = function(c) return c.recent(c.foldedAt) end },
	{ key = "tipWall", text = "Scrapes tear your paper. Turn early.", when = function(c) return c.flying and c.recent(FlightState.scrapedAt) end },
	{ key = "tipControl", text = "Hold the zone with your team.", point = "zone", when = function(c) return c.flying and c.mode == "CONTROL" end },
	{ key = "tipTeam", text = function(c) return "You're on " .. TEAM_NAMES[c.plane:GetAttribute("Team")] .. ". Blue outlines are your team: fold the orange ones." end,
		when = function(c) return c.flying and c.mode == "TDM" and TEAM_NAMES[c.plane:GetAttribute("Team")] ~= nil end },
	{ key = "tipFfa", text = "Fold enemy planes for points. Most points wins.", when = function(c) return c.flying and c.mode == "FFA" end },
	{ key = "tipDesk", skip = "flight", text = "Your desk: change your build here, then LAUNCH.", when = function(c) return c.state == "DESK" end },
}

function Tips.start(getPlane)
	local player = Players.LocalPlayer
	local myId = tostring(player.UserId)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.Enabled = "MatchTips", true, false, 6, false
	gui.Parent = player:WaitForChild("PlayerGui")
	-- The tutorial's sticky note, smaller: one line and Got it. Just under the match strip, clear of the middle of the view.
	-- (A button: on a phone, tapping the note is its Got it; a 44-point button wouldn't fit on it.)
	local note = Instance.new("ImageButton")
	note.Name, note.Image, note.ScaleType, note.BackgroundTransparency, note.AutoButtonColor = "Note", Art.ingame.stickyNote, Enum.ScaleType.Stretch, 1, false
	note.AnchorPoint, note.Position, note.Size, note.Rotation, note.Parent = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 130), UDim2.fromOffset(560, 140), 1, gui
	local scale = Instance.new("UIScale")
	scale.Parent = note
	ScreenFit.inColumn(note, 5, true) -- on a phone it stays up top (Alan 2026-10-24: not in the middle of the view)
	local title = PaperUI.phone(PaperUI.words(note, "Title", "Match tip", 34, 16, 300, 30, 22), { TextSize = 28 })
	title.TextColor3 = Color3.fromRGB(150, 60, 40)
	local words = PaperUI.words(note, "Text", "", 34, 44, 492, 40, 28)
	words.TextWrapped, words.TextYAlignment = true, Enum.TextYAlignment.Top
	local current, shownFor, lastEnded = nil, 0, -math.huge
	local gotIt = PaperUI.button(note, "GotIt", Art.mainmenu.strip.green or Art.mainmenu.strip.red, "Got it  [Space]", 34, 86, 220, 42, 1, function() shownFor = SHOW_SECONDS end, 22)
	note.Activated:Connect(function() shownFor = SHOW_SECONDS end)
	local arrow = PaperUI.image(gui, "Arrow", Art.tutorial.arrow, 0, 0, 120, 75)
	local arrowScale = Instance.new("UIScale")
	arrowScale.Parent = arrow

	local lessons, profileLoaded, seen = {}, false, {}
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if type(profile) == "table" and type(profile.lessons) == "table" then profileLoaded, lessons = true, profile.lessons end
	end)
	local snapshot = {}
	Root:WaitForChild("RoundView").OnClientEvent:Connect(function(s) if type(s) == "table" then snapshot = s end end)
	local foldedAt
	Root:WaitForChild("CombatEvents").OnClientEvent:Connect(function(events)
		for _, event in ipairs(events) do
			if event.kind == "death" and event.killerId == myId and event.victimId ~= myId and not event.practice then foldedAt = os.clock() end
		end
	end)
	Input.InputBegan:Connect(function(input, processed)
		if not processed and current and gui.Enabled and input.KeyCode == Enum.KeyCode.Space then shownFor = SHOW_SECONDS end
	end)

	local function recent(at) return at ~= nil and os.clock() - at < RECENT_SECONDS end
	-- The box (screen pixels) the arrow points at, or nil.
	local function pointAt(what)
		if what == "zone" and Zone.zone then
			local centre = Zone.zone.center
			local point, onScreen = workspace.CurrentCamera:WorldToViewportPoint(Vector3.new(centre[1], centre[2], centre[3]))
			if onScreen then return Vector2.new(point.X, point.Y), Vector2.new(point.X, point.Y) end
		elseif what == "lift" then
			local hud = player.PlayerGui:FindFirstChild("FlightHUD")
			local strip = hud and hud.Enabled and hud:FindFirstChild("LiftStrip", true)
			if strip then
				local low = strip.AbsolutePosition - gui.AbsolutePosition
				return low, low + strip.AbsoluteSize
			end
		end
		return nil
	end

	RunService.RenderStepped:Connect(function(dt)
		local plane = getPlane()
		-- A real match only: not the Range, a lesson, the tutorial's own room, a menu, photo mode or the winners' show.
		local inMatch = plane ~= nil and plane.Parent ~= nil and player:GetAttribute("InMatch") == true and plane:GetAttribute("Pinned") == nil
			and not Root:GetAttribute("TutorialOpen") and not Root:GetAttribute("TutorialRoom")
		-- (and not over the tutorial's own question, "Welcome, pilot!")
		local tutorial = player.PlayerGui:FindFirstChild("Tutorial")
		local asking = tutorial ~= nil and tutorial:FindFirstChild("Ask") ~= nil and tutorial.Ask.Visible
		local hidden = not inMatch or asking or (snapshot.phase ~= "ACTIVE" and snapshot.phase ~= nil) or Root:GetAttribute("OverlayOpen") or Root:GetAttribute("PhotoMode") or Root:GetAttribute("Cutscene")
		if hidden or Root:GetAttribute("MatchTips") == false or not profileLoaded then gui.Enabled = false; return end
		local state = plane:GetAttribute("State")
		local c = { plane = plane, state = state, flying = state == "FLYING", mode = snapshot.mode, phase = snapshot.phase, foldedAt = foldedAt, recent = recent }
		if current and shownFor >= SHOW_SECONDS then current, lastEnded = nil, os.clock() end
		if not current and os.clock() - lastEnded >= GAP_SECONDS then
			for _, tip in TIPS do
				if not seen[tip.key] and lessons[tip.key] ~= true and not (tip.skip and lessons[tip.skip] == true) and tip.when(c) then
					current, shownFor, seen[tip.key] = tip, 0, true
					words.Text = type(tip.text) == "function" and tip.text(c) or tip.text
					Root.RoundAction:FireServer("lessonDone", tip.key)
					break
				end
			end
		end
		gui.Enabled = current ~= nil
		if not current then return end
		shownFor += dt
		-- Last in the top middle's column (ScreenFit): under the match strip and any news, warning or lock note (on a
		-- phone over them, a bit smaller: Alan 2026-10-24).
		local s = ScreenFit.scale(ScreenFit.NOTE) * (ScreenFit.kind() == "phone" and 0.85 or 1)
		local x, y, fit = ScreenFit.place(note, s)
		scale.Scale, arrowScale.Scale = s * fit, s
		gotIt.Visible = not Touch.active()
		note.Position = UDim2.new(0.5, x, 0, y)
		local low, high = nil, nil
		if current.point then low, high = pointAt(current.point) end
		arrow.Visible = low ~= nil
		if low then PaperUI.pointArrow(arrow, note.AbsolutePosition - gui.AbsolutePosition + note.AbsoluteSize / 2, low, high, s) end
	end)
end

return Tips
