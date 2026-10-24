-- Phones and tablets (docs/plan/TOUCH-PLAN.md, Alan 2026-10-23). Left thumb: a steering stick that appears where the
-- thumb lands on the left half of the screen; pushing it keeps the aim turning that way (FlightController) and letting
-- go flies on straight and levels out, like letting go of the mouse. Right thumb: Fire (weapon 1), weapon 2 and Boost
-- (only with a boost part), held like the mouse buttons and Shift (CombatController, FlightController). Shown only
-- while flying on a touch screen.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Config = require(Root.Generated.Gameplay).flight
local PaperUI = require(script.Parent.PaperUI)
local Words = require(Root.Shared.TouchWords)

local Touch = { stick = Vector2.zero, boost = false, onFire = nil } -- onFire(which, down): CombatController's triggers

-- Studio: ReplicatedStorage.FlyFightPaper's DevTouch attribute shows the phone layout on a PC, to look at it.
function Touch.active()
	return Input.PreferredInput == Enum.PreferredInput.Touch or RunService:IsStudio() and Root:GetAttribute("DevTouch") == true
end

local PAPER = Color3.fromRGB(250, 246, 232)
local function disc(name, color, parent)
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundColor3, frame.AnchorPoint, frame.Parent = name, color, Vector2.new(0.5, 0.5), parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0.5, 0), frame
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Parent = PaperUI.INK, 3, frame
	return frame
end

function Touch.start(getPlane)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder, gui.Enabled = "TouchControls", false, true, 5, false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- The stick: a see-through ring and its knob, hidden until a thumb lands.
	local base = disc("StickBase", PAPER, gui)
	base.BackgroundTransparency, base.Visible = 0.65, false
	local knob = disc("Knob", PAPER, base)
	knob.BackgroundTransparency = 0.1
	local stickTouch, stickFrom, radius = nil, Vector2.zero, 60

	-- Held buttons: each follows the one touch that pressed it, so sliding a thumb off doesn't stick it on.
	local buttons = {}
	local function holdButton(name, label, color, onHold)
		local button = disc(name, color, gui)
		button.Active = true
		local words = PaperUI.words(button, "Label", label, 0, 0, 10, 10, 24)
		words.Size, words.TextXAlignment, words.TextScaled = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center, true
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft, padding.PaddingRight = UDim.new(0.15, 0), UDim.new(0.15, 0)
		padding.PaddingTop, padding.PaddingBottom, padding.Parent = UDim.new(0.3, 0), UDim.new(0.3, 0), words
		local entry = { frame = button, touch = nil }
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch or entry.touch then return end
			entry.touch = input
			button.BackgroundTransparency = 0.35
			onHold(true)
		end)
		function entry.release()
			if not entry.touch then return end
			entry.touch = nil
			button.BackgroundTransparency = 0
			onHold(false)
		end
		table.insert(buttons, entry)
		return button
	end
	local fire = holdButton("Fire", "FIRE", Color3.fromRGB(240, 90, 70), function(down) if Touch.onFire then Touch.onFire(1, down) end end)
	local fire2 = holdButton("Fire2", "2", Color3.fromRGB(250, 205, 40), function(down) if Touch.onFire then Touch.onFire(2, down) end end)
	local boost = holdButton("Boost", "BOOST", Color3.fromRGB(110, 170, 240), function(down) Touch.boost = down end)

	-- Sizes follow the screen's short side, so a phone and a tablet both get thumb-sized pieces.
	local function fit()
		local view = workspace.CurrentCamera.ViewportSize
		local short = math.min(view.X, view.Y)
		radius = short * Config.touch_stick_radius
		base.Size, knob.Size = UDim2.fromOffset(radius * 2, radius * 2), UDim2.fromOffset(radius * 0.9, radius * 0.9)
		local big, small = short * 0.24, short * 0.16
		fire.Size = UDim2.fromOffset(big, big)
		fire.Position = UDim2.new(1, -big * 0.5 - short * 0.06, 1, -big * 0.5 - short * 0.08)
		fire2.Size = UDim2.fromOffset(small, small)
		fire2.Position = UDim2.new(1, -big * 0.5 - short * 0.06, 1, -big - small * 0.5 - short * 0.12)
		boost.Size = UDim2.fromOffset(small, small)
		boost.Position = UDim2.new(1, -big - small * 0.5 - short * 0.12, 1, -small * 0.5 - short * 0.08)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()

	local function releaseAll()
		stickTouch, Touch.stick, base.Visible = nil, Vector2.zero, false
		for _, entry in buttons do entry.release() end
	end
	Input.TouchStarted:Connect(function(touch, processed)
		if processed or stickTouch or not gui.Enabled then return end
		local at = Vector2.new(touch.Position.X, touch.Position.Y)
		if at.X > workspace.CurrentCamera.ViewportSize.X * 0.5 then return end
		stickTouch, stickFrom = touch, at
		base.Position, base.Visible = UDim2.fromOffset(at.X, at.Y), true
		knob.Position = UDim2.fromScale(0.5, 0.5)
	end)
	Input.TouchMoved:Connect(function(touch)
		if touch ~= stickTouch then return end
		local offset = Vector2.new(touch.Position.X, touch.Position.Y) - stickFrom
		if offset.Magnitude > radius then offset = offset.Unit * radius end
		knob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
		-- A gentle curve: small pushes turn slowly for fine aim, a full push turns at the full rate.
		local push = offset.Magnitude / radius
		Touch.stick = push > 0.08 and offset.Unit * push ^ Config.touch_stick_curve or Vector2.zero
	end)
	Input.TouchEnded:Connect(function(touch)
		if touch == stickTouch then stickTouch, Touch.stick, base.Visible = nil, Vector2.zero, false end
		for _, entry in buttons do if entry.touch == touch then entry.release() end end
	end)

	-- Every text on screen says touch words on a phone ("Tap", "hold FIRE"; TouchWords), however it got there: menus,
	-- lessons, tips, the HUD, messages from the server. Texts typed by the player (TextBoxes) are left alone.
	local function fix(label)
		if not Touch.active() then return end
		local said = Words.say(label.Text, true)
		if said ~= label.Text then label.Text = said end
	end
	local function watch(object)
		if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
		object:GetPropertyChangedSignal("Text"):Connect(function() fix(object) end)
		fix(object)
	end
	local playerGui = gui.Parent
	playerGui.DescendantAdded:Connect(watch)
	for _, object in playerGui:GetDescendants() do watch(object) end
	local function fixAll() for _, object in playerGui:GetDescendants() do if object:IsA("TextLabel") or object:IsA("TextButton") then fix(object) end end end
	Input:GetPropertyChangedSignal("PreferredInput"):Connect(fixAll)
	if RunService:IsStudio() then Root:GetAttributeChangedSignal("DevTouch"):Connect(fixAll) end

	-- Roblox's own walking stick and jump button would sit under the thumbs; the plane needs neither.
	local controls, controlsOff
	task.spawn(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		controls = module and require(module):GetControls()
	end)
	RunService.RenderStepped:Connect(function()
		local plane = getPlane()
		local flying = Touch.active() and plane ~= nil and plane.Parent ~= nil and plane:GetAttribute("State") == "FLYING"
			and not plane:GetAttribute("Held") and not Root:GetAttribute("OverlayOpen")
		if flying ~= gui.Enabled then
			gui.Enabled = flying
			if not flying then releaseAll() end
		end
		boost.Visible = flying and (plane:GetAttribute("BoostMax") or 0) > 0
		if controls and controlsOff ~= Touch.active() then
			controlsOff = Touch.active()
			if controlsOff then controls:Disable() else controls:Enable() end
		end
	end)
end

return Touch
