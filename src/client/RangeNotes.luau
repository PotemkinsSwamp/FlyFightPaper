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
-- What each note says, what it points at (a part of the stage, or a button: gui), and what finishes it. Got it
-- (Space) also moves on. The Back note shows over the Hangar, only if the Hangar note's Hangar was opened.
local STEPS = {
	{ text = "Shoot a plate to pick which row moves.", done = "pick", find = upPlate },
	{ text = "Your shots, hits and aim. Shoot Reset to start over.", done = "reset", find = boardPart("reset") },
	{ text = "Your 5 Range builds and how hard the targets are.", done = "menu", find = boardPart("menu") },
	{ text = "Change your Range builds. Any part works here, even ones you don't own.", done = "hangar", find = boardPart("hangar") },
	{ text = "Back takes you to the Range.", done = "back", gui = "back" },
	-- The last note (Alan 2026-10-23: a "Menu, then Leave" note of its own made people leave): Got it, or opening the Menu.
	{ text = "That's it! The Range is yours: practise as long as you like. To leave, press Menu, then Leave.", done = "pause", gui = "menu" },
}

-- getStage() = the Range's stage model or nil.
function Notes.new(getStage)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.Enabled = "RangeNotes", true, false, 11, false -- over the Hangar (10)
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

	local step, seen, saved, profileLoaded = 1, false, false, false
	local viaHangar, hangarWasOpen = false, false
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		if type(profile) == "table" and type(profile.lessons) == "table" then
			profileLoaded, seen = true, seen or profile.lessons.rangeNotes == true
		end
	end)
	-- Saved once the last note shows (leaving from the Menu note still counts as seen); gone after its Got it.
	local function save()
		if saved then return end
		saved = true
		Root.RoundAction:FireServer("lessonDone", "rangeNotes")
	end
	local function finish()
		seen = true
		save()
	end
	local function advance()
		step += 1
		if step >= #STEPS then save() end
		if step > #STEPS then finish() end
	end
	local function active()
		return gui.Enabled and not seen and STEPS[step] ~= nil
	end
	PaperUI.button(note, "GotIt", Art.mainmenu.strip.green or Art.mainmenu.strip.red, "Got it  [Space]", 40, 176, 240, 48, 1, function() if active() then advance() end end, 24)
	local skip = PaperUI.button(note, "Skip", Art.mainmenu.strip.red, "Skip all  [K]", 330, 176, 250, 48, -1, function() if active() then finish() end end, 24)
	Input.InputBegan:Connect(function(input, processed)
		if processed or not active() then return end
		if input.KeyCode == Enum.KeyCode.Space then advance() elseif input.KeyCode == Enum.KeyCode.K then finish() end
	end)

	local function hangarBack()
		local layer = player.PlayerGui:FindFirstChild("HangarScreen")
		local cover = layer and layer:FindFirstChild("Cover")
		return cover and cover.Visible and cover.Sheet:FindFirstChild("Back"), layer
	end
	-- The box (screen pixels, low and high corners) of what the current note points at; nil when it isn't there.
	local function target()
		local current = STEPS[step]
		if current.gui == "back" then
			local back, layer = hangarBack()
			if not back then return nil end
			local low = back.AbsolutePosition - layer.AbsolutePosition
			return low, low + back.AbsoluteSize
		elseif current.gui == "menu" then
			local menu = player.PlayerGui:FindFirstChild("GameMenu")
			local button = menu and menu:FindFirstChild("OpenMenu")
			if not button or not button.Visible then return nil end
			local low = button.AbsolutePosition - menu.AbsolutePosition
			return low, low + button.AbsoluteSize
		end
		local stage = getStage()
		local part = stage and current.find(stage)
		if not part then return nil end
		local low, high = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
		for _, x in { -0.5, 0.5 } do
			for _, y in { -0.5, 0.5 } do
				for _, z in { -0.5, 0.5 } do
					local point, onScreen = workspace.CurrentCamera:WorldToViewportPoint((part.CFrame * CFrame.new(part.Size * Vector3.new(x, y, z))).Position)
					if not onScreen then return nil end
					low, high = low:Min(Vector2.new(point.X, point.Y)), high:Max(Vector2.new(point.X, point.Y))
				end
			end
		end
		return low, high
	end

	RunService.RenderStepped:Connect(function()
		local current = STEPS[step]
		-- The Back note: only after the Hangar note opened the Hangar; done when the Hangar closes.
		if current and current.done == "back" and not hangarBack() then
			if hangarWasOpen or not viaHangar then advance() end
			current = STEPS[step]
		end
		local onStage = getStage() ~= nil
		local inRange = FlightState.aimPoint ~= nil and onStage
		-- The Range itself runs as the tutorial's "range" room; any other lesson open (the Hangar Tour) hides the notes.
		local lesson = Root:GetAttribute("TutorialOpen") and Root:GetAttribute("TutorialLesson") ~= "range"
		local inHangar = current ~= nil and current.done == "back"
		if inHangar then hangarWasOpen = true end
		local where = if inHangar then onStage else inRange and not Root:GetAttribute("OverlayOpen")
		local show = profileLoaded and not seen and current ~= nil and where and not lesson
		local low, high
		if show and (current.find or current.gui) then low, high = target() end
		gui.Enabled = show and (low ~= nil or not (current.find or current.gui))
		if not gui.Enabled then return end
		local s = math.max(0.6, workspace.CurrentCamera.ViewportSize.Y / 1080)
		scale.Scale, arrowScale.Scale = s, s
		title.Text, words.Text = string.format("The Range  -  note %d of %d", step, #STEPS), current.text
		skip.Visible = step < #STEPS
		-- Over the Hangar the note sits bottom right, like the Hangar Tour's (clear of the shelf); top middle otherwise.
		note.AnchorPoint = if inHangar then Vector2.new(1, 1) else Vector2.new(0.5, 0)
		note.Position = if inHangar then UDim2.new(1, -20, 0.95, 0) else UDim2.fromScale(0.5, 0.05)
		arrow.Visible = low ~= nil
		if not low then return end
		-- The arrow sits just outside what the note explains, on the note's side, pointing at it.
		local middle, half = (low + high) / 2, (high - low) / 2
		local from = note.AbsolutePosition - gui.AbsolutePosition + note.AbsoluteSize / 2
		local away = from - middle
		away = away.Magnitude > 1 and away.Unit or Vector2.new(0, -1)
		local edge = math.min(math.abs(away.X) > 1e-3 and half.X / math.abs(away.X) or math.huge, math.abs(away.Y) > 1e-3 and half.Y / math.abs(away.Y) or math.huge)
		local tip = middle + away * (edge + 70 * s)
		arrow.Position, arrow.Rotation = UDim2.fromOffset(tip.X, tip.Y), math.deg(math.atan2(-away.Y, -away.X))
	end)
	-- Opening the game menu (the Menu button, Esc) finishes the last note.
	Root:GetAttributeChangedSignal("OverlayOpen"):Connect(function()
		if Root:GetAttribute("OverlayOpen") and active() and STEPS[step].done == "pause" then advance() end
	end)

	local self = {}
	-- RangeBoard reports each control used: "pick" (a row plate), "reset", "menu", "hangar", ...
	function self.used(what)
		if what == "hangar" and active() and STEPS[step].done == "hangar" then viaHangar = true end
		if active() and STEPS[step].done == what then advance() end
	end
	return self
end

return Notes
