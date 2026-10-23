-- The Range's first-visit sticky notes (Alan OK'd the plan 2026-10-22; docs/plan/TUTORIAL-PLAN.md "The Hangar Range").
-- One note at a time, each with the lessons' crayon arrow pointing at what it explains; nothing is dimmed, so you can
-- keep shooting. A note goes when you use the thing it points at, or when you shoot/click the note; "Skip all" ends
-- them. Seen once: the last note (or Skip all) saves "rangeNotes" in your lessons, like a lesson's tick.
-- Not during another lesson (the Hangar Tour runs in the Range), nor while a menu is open over the Range.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local FlightState = require(script.Parent.FlightController).state
local Notes = {}

local function boardPart(what)
	return function(stage)
		for _, p in stage:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("RangeBoard") == what then return p end
		end
	end
end
-- What each note says, what it points at (a part of the stage, or the game's Menu button), and what finishes it.
local STEPS = {
	{ text = "Shoot a plate to pick which row moves.", done = "pick", find = function(stage)
		for _, p in stage:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("RangePick") == "all" then return p end
		end
		return stage:FindFirstChild("Pick", true)
	end },
	{ text = "Your shots, hits and aim. Shoot Reset to start over.", done = "reset", find = function(stage) return stage:FindFirstChild("ScoreCard") end },
	{ text = "Your 5 Range builds and how hard the targets are.", done = "menu", find = boardPart("menu") },
	{ text = "Change your Range builds. Any part works here, even ones you don't own.", done = "hangar", find = boardPart("hangar") },
	{ text = "Menu, then Leave, takes you back.", done = "pause", gui = true },
}
local W, H = 330, 250 -- the note at 1080 px tall (sheet pixels), scaled with the screen

-- getStage() = the Range's stage model or nil.
function Notes.new(getStage)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.Enabled = "RangeNotes", true, false, 7, false
	gui.Parent = player:WaitForChild("PlayerGui")
	local note = PaperUI.image(gui, "Note", Art.ingame.stickyNote, 0, 0, W, H, -2)
	note.ScaleType = Enum.ScaleType.Stretch
	local scale = Instance.new("UIScale")
	scale.Parent = note
	local words = PaperUI.words(note, "Words", "", 30, 40, W - 60, H - 100, 34)
	words.TextXAlignment, words.TextWrapped, words.TextScaled = Enum.TextXAlignment.Center, true, true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize, cap.Parent = 34, words
	local skip = PaperUI.words(note, "SkipAll", "Skip all", W - 150, H - 58, 110, 34, 24)
	skip.TextXAlignment, skip.TextColor3 = Enum.TextXAlignment.Right, Color3.fromRGB(190, 35, 30)
	local count = PaperUI.words(note, "Count", "", 40, H - 58, 80, 34, 24)
	local arrow = PaperUI.image(gui, "Arrow", Art.tutorial.arrow, 0, 0, 120, 75)
	local arrowScale = Instance.new("UIScale")
	arrowScale.Parent = arrow

	local step, seen, profileLoaded = 1, false, false
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if type(profile) == "table" and type(profile.lessons) == "table" then
			profileLoaded, seen = true, seen or profile.lessons.rangeNotes == true
		end
	end)
	local function finish()
		if seen then return end
		seen = true
		Root.RoundAction:FireServer("lessonDone", "rangeNotes")
	end
	local function advance()
		step += 1
		if step > #STEPS then finish() end
	end
	local function active()
		return gui.Enabled and not seen and STEPS[step] ~= nil
	end

	-- Where the current note points, in screen pixels (nil when its target isn't there).
	local function target()
		local current = STEPS[step]
		if current.gui then
			local menu = player.PlayerGui:FindFirstChild("GameMenu")
			local button = menu and menu:FindFirstChild("OpenMenu")
			if not button or not button.Visible then return nil end
			return button.AbsolutePosition - menu.AbsolutePosition + button.AbsoluteSize / 2
		end
		local stage = getStage()
		local part = stage and current.find(stage)
		if not part then return nil end
		local point, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
		return onScreen and Vector2.new(point.X, point.Y) or nil
	end

	RunService.RenderStepped:Connect(function()
		local inRange = FlightState.aimPoint ~= nil and getStage() ~= nil
		-- The Range itself runs as the tutorial's "range" room; any other lesson open (the Hangar Tour) hides the notes.
		local lesson = Root:GetAttribute("TutorialOpen") and Root:GetAttribute("TutorialLesson") ~= "range"
		local show = profileLoaded and not seen and inRange and STEPS[step] ~= nil and not lesson and not Root:GetAttribute("OverlayOpen")
		local spot = if show then target() else nil
		gui.Enabled = spot ~= nil
		if not spot then return end
		local view = workspace.CurrentCamera.ViewportSize
		local s = math.max(0.6, view.Y / 1080)
		scale.Scale, arrowScale.Scale = s, s
		words.Text, count.Text = STEPS[step].text, step .. " of " .. #STEPS
		-- The note sits toward the middle of the screen from what it explains; the arrow between points at it.
		local away = view / 2 - spot
		away = away.Magnitude > 1 and away.Unit or Vector2.new(0, 1)
		local centre = spot + away * 290 * s
		centre = Vector2.new(math.clamp(centre.X, W / 2 * s + 8, view.X - W / 2 * s - 8), math.clamp(centre.Y, H / 2 * s + 8, view.Y - H / 2 * s - 8))
		note.Position = UDim2.fromOffset(centre.X, centre.Y)
		local tip = spot + away * 85 * s
		arrow.Position, arrow.Rotation = UDim2.fromOffset(tip.X, tip.Y), math.deg(math.atan2(-away.Y, -away.X))
	end)
	-- Opening the game menu (the Menu button, Esc) finishes the last note.
	Root:GetAttributeChangedSignal("OverlayOpen"):Connect(function()
		if Root:GetAttribute("OverlayOpen") and active() and STEPS[step].done == "pause" then advance() end
	end)

	local self = {}
	-- RangeBoard reports each control used: "pick" (a row plate), "reset", "menu", "hangar", ...
	function self.used(what)
		if active() and STEPS[step].done == what then advance() end
	end
	-- A click where the crosshair is (screen pixels, the GUI's own frame): true when it landed on the note.
	function self.clicked(spot)
		if not active() then return false end
		local low, size = note.AbsolutePosition - gui.AbsolutePosition, note.AbsoluteSize
		if spot.X < low.X or spot.X > low.X + size.X or spot.Y < low.Y or spot.Y > low.Y + size.Y then return false end
		local skipLow, skipSize = skip.AbsolutePosition - gui.AbsolutePosition, skip.AbsoluteSize
		if spot.X >= skipLow.X and spot.X <= skipLow.X + skipSize.X and spot.Y >= skipLow.Y - 10 and spot.Y <= skipLow.Y + skipSize.Y + 10 then
			finish()
		else
			advance()
		end
		return true
	end
	return self
end

return Notes
