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
local Art = require(Root.Shared.UIAssets).touch -- peel stickers (Alan 2026-10-28, ui-concepts/touch-buttons-c.png)

local Touch = { stick = Vector2.zero, boost = false, onFire = nil } -- onFire(which, down): CombatController's triggers
-- The HUD's crayon colours (the weapon rows' cells): each button fills with its own weapon's state.
local CRAYON = { green = Color3.fromRGB(110, 200, 95), red = Color3.fromRGB(230, 75, 60), orange = Color3.fromRGB(245, 155, 50),
	blue = Color3.fromRGB(85, 150, 235) }
local gauges = {}
-- FlightHUD: button `name` ("Fire", "Fire2", "Boost") shows `share` (0-1) filled with crayon `color`, and `caption`
-- (the weapon's name) under its word.
function Touch.gauge(name, share, color, caption)
	local gauge = gauges[name]
	if gauge then gauge(share, color, caption) end
end

-- Studio: ReplicatedStorage.FlyFightPaper's DevTouch attribute shows the phone layout on a PC, to look at it.
function Touch.active()
	return Input.PreferredInput == Enum.PreferredInput.Touch or RunService:IsStudio() and Root:GetAttribute("DevTouch") == true
end

local PAPER = Color3.fromRGB(250, 246, 232)
-- A sticker: its picture drawn 1.1x the piece (room for the peel's shadow), centred; the piece itself is the circle.
local function sticker(name, image, parent, z)
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundTransparency, frame.AnchorPoint, frame.Parent = name, 1, Vector2.new(0.5, 0.5), parent
	local art = Instance.new("ImageLabel")
	art.Name, art.Image, art.BackgroundTransparency, art.ZIndex = "Art", image, 1, z or 2
	art.AnchorPoint, art.Position, art.Size, art.Parent = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.1, 1.1), frame
	return frame, art
end
local function round(frame) local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(0.5, 0), frame end

function Touch.start(getPlane)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder, gui.Enabled = "TouchControls", false, true, 5, false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- The stick: a clear sticker and its knob, hidden until a thumb lands.
	local base, baseArt = sticker("StickBase", Art.pad, gui)
	baseArt.ImageTransparency, base.Visible = 0.35, false
	local knob = sticker("Knob", Art.knob, base, 3)
	local stickTouch, stickFrom, radius = nil, Vector2.zero, 60

	-- Held buttons: each follows the one touch that pressed it, so sliding a thumb off doesn't stick it on.
	local buttons = {}
	local function holdButton(name, label, color, onHold)
		-- Peel stickers with a crayon fill rising from the bottom (the weapon's heat, reload or lock; Boost's charge):
		-- a paper disc inside the sticker's ink ring, the crayon disc clipped from the bottom, the sticker on top.
		local button = sticker(name, Art.button, gui, 3)
		button.Active = true
		local paper = Instance.new("Frame")
		paper.Name, paper.BackgroundColor3, paper.AnchorPoint, paper.ZIndex = "Paper", PAPER, Vector2.new(0.5, 0.5), 1
		paper.Position, paper.Size, paper.Parent = UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.9), button
		round(paper)
		local clip = Instance.new("Frame")
		clip.Name, clip.BackgroundTransparency, clip.ClipsDescendants, clip.AnchorPoint = "Fill", 1, true, Vector2.new(0, 1)
		clip.Position, clip.ZIndex, clip.Parent = UDim2.fromScale(0, 1), 2, button
		local crayon = Instance.new("ImageLabel")
		crayon.Name, crayon.Image, crayon.BackgroundTransparency, crayon.AnchorPoint, crayon.ZIndex = "Crayon", Art.crayon, 1, Vector2.new(0.5, 0.5), 2
		crayon.Parent = clip
		local words = PaperUI.words(button, "Label", label, 0, 0, 10, 10, 24)
		words.AnchorPoint, words.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.45)
		words.Size, words.TextXAlignment, words.TextScaled, words.ZIndex = UDim2.fromScale(0.7, 0.34), Enum.TextXAlignment.Center, true, 4
		local caption = PaperUI.words(button, "Caption", "", 0, 0, 10, 10, 14)
		caption.AnchorPoint, caption.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.72)
		caption.Size, caption.TextXAlignment, caption.TextScaled, caption.ZIndex = UDim2.fromScale(0.62, 0.16), Enum.TextXAlignment.Center, true, 4
		-- The clip is the bottom `share` of the button; the crayon disc inside it stays put on the button's middle.
		gauges[name] = function(share, tint, text)
			local edge = math.clamp(share, 0, 1)
			clip.Visible, clip.Size = edge > 0.001, UDim2.fromScale(1, edge)
			if edge > 0.001 then crayon.Position, crayon.Size = UDim2.fromScale(0.5, 1 - 0.5 / edge), UDim2.fromScale(0.9, 0.9 / edge) end
			crayon.ImageColor3 = CRAYON[tint] or color
			caption.Text = text or ""
		end
		gauges[name](1, nil)
		paper.BackgroundTransparency = 0.12 -- the game shows faintly through a small screen's biggest pieces
		local entry = { frame = button, touch = nil }
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch or entry.touch then return end
			entry.touch = input
			paper.BackgroundTransparency = 0.3
			onHold(true)
		end)
		function entry.release()
			if not entry.touch then return end
			entry.touch = nil
			paper.BackgroundTransparency = 0.12
			onHold(false)
		end
		table.insert(buttons, entry)
		return button
	end
	local fire = holdButton("Fire", "FIRE", CRAYON.green, function(down) if Touch.onFire then Touch.onFire(1, down) end end)
	local fire2 = holdButton("Fire2", "2", CRAYON.green, function(down) if Touch.onFire then Touch.onFire(2, down) end end)
	local boost = holdButton("Boost", "BOOST", CRAYON.blue, function(down) Touch.boost = down end)

	-- Sizes follow the screen's short side, kept thumb-sized (points): a phone and a tablet both get pieces a thumb
	-- can hit, and a tablet's don't grow huge.
	local function fit()
		local view = workspace.CurrentCamera.ViewportSize
		local short = math.min(view.X, view.Y)
		radius = math.clamp(short * Config.touch_stick_radius, 44, 80)
		base.Size, knob.Size = UDim2.fromOffset(radius * 2, radius * 2), UDim2.fromOffset(radius * 0.9, radius * 0.9)
		local big, small = math.clamp(short * 0.24, 76, 120), math.clamp(short * 0.16, 52, 84)
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
			and (not plane:GetAttribute("Held") or Root:GetAttribute("TutorialOpen")) and not Root:GetAttribute("OverlayOpen") -- (a lesson's read pause shows the buttons it talks about)
		if flying ~= gui.Enabled then
			gui.Enabled = flying
			if not flying then releaseAll() end
		end
		local boostMax = flying and plane:GetAttribute("BoostMax") or 0
		boost.Visible = boostMax > 0
		if boost.Visible then Touch.gauge("Boost", (plane:GetAttribute("Boost") or 0) / boostMax, "blue") end
		fire2.Visible = flying and (plane:GetAttribute("AlternateName") or "None") ~= "None"
		if controls and controlsOff ~= Touch.active() then
			controlsOff = Touch.active()
			if controlsOff then controls:Disable() else controls:Enable() end
		end
	end)
end

return Touch
