-- The Range's first-visit sticky notes (Alan OK'd the plan 2026-10-22; docs/plan/TUTORIAL-PLAN.md "The Hangar Range").
-- The tutorial's own note (Alan 2026-10-23: "so it just looks like a tutorial"): one at a time, top middle, with the
-- lessons' crayon arrow by what it explains; nothing is dimmed, so you can keep shooting. Got it (Space) or using the
-- thing moves on; Skip all (K) ends them; no timer. Seen once: the last note (or Skip all) saves "rangeNotes" in your
-- lessons, like a lesson's tick. Not during another lesson (the Hangar Tour runs in the Range), nor under a menu.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
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
-- A plate that's up (the row in use lies down): Medium, or Close when Medium is the one down.
local function upPlate(stage)
	local plates = {}
	for _, p in stage:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("RangePick") then plates[p:GetAttribute("RangePick")] = p end
	end
	local medium = plates.medium
	return if medium and not medium:GetAttribute("Down") then medium else plates.close
end
-- What each note says, what it points at (a part of the stage, or the game's Menu button), and what finishes it.
local STEPS = {
	{ text = "Shoot a plate to pick which row moves.", done = "pick", find = upPlate },
	{ text = "Your shots, hits and aim. Shoot Reset to start over.", done = "reset", find = function(stage) return stage:FindFirstChild("ScoreCard") end },
	{ text = "Your 5 Range builds and how hard the targets are.", done = "menu", find = boardPart("menu") },
	{ text = "Change your Range builds. Any part works here, even ones you don't own.", done = "hangar", find = boardPart("hangar") },
	{ text = "Menu, then Leave, takes you back.", done = "pause", gui = true },
}

-- getStage() = the Range's stage model or nil.
function Notes.new(getStage)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.Enabled = "RangeNotes", true, false, 7, false
	gui.Parent = player:WaitForChild("PlayerGui")
	-- The tutorial's goal note (Tutorial.luau): same paper, size, place and words.
	local note = Instance.new("ImageLabel")
	note.Name, note.Image, note.ScaleType, note.BackgroundTransparency = "Note", Art.ingame.stickyNote, Enum.ScaleType.Stretch, 1
	note.AnchorPoint, note.Position, note.Size, note.Rotation, note.Parent = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.05), UDim2.fromOffset(620, 230), -1, gui
	local scale = Instance.new("UIScale")
	scale.Parent = note
	local title = PaperUI.words(note, "Title", "", 40, 24, 540, 34, 24)
	title.TextColor3 = Color3.fromRGB(150, 60, 40)
	local words = PaperUI.words(note, "Text", "", 40, 58, 540, 96, 30)
	words.TextWrapped, words.TextYAlignment = true, Enum.TextYAlignment.Top
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
	PaperUI.button(note, "GotIt", Art.mainmenu.strip.green or Art.mainmenu.strip.red, "Got it  [Space]", 40, 176, 240, 48, 1, function() if active() then advance() end end, 24)
	PaperUI.button(note, "Skip", Art.mainmenu.strip.red, "Skip all  [K]", 330, 176, 250, 48, -1, function() if active() then finish() end end, 24)
	Input.InputBegan:Connect(function(input, processed)
		if processed or not active() then return end
		if input.KeyCode == Enum.KeyCode.Space then advance() elseif input.KeyCode == Enum.KeyCode.K then finish() end
	end)

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
		local s = math.max(0.6, workspace.CurrentCamera.ViewportSize.Y / 1080)
		scale.Scale, arrowScale.Scale = s, s
		title.Text, words.Text = string.format("The Range  -  note %d of %d", step, #STEPS), STEPS[step].text
		-- The arrow sits by what the note explains, pointing at it from the note's side.
		local from = note.AbsolutePosition - gui.AbsolutePosition + note.AbsoluteSize / 2
		local away = from - spot
		away = away.Magnitude > 1 and away.Unit or Vector2.new(0, -1)
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
	return self
end

return Notes
