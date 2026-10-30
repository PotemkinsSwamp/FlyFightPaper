-- Phones and tablets (docs/plan/TOUCH-PLAN.md, Alan 2026-10-23). Left thumb: a steering stick that appears where the
-- thumb lands on the left half of the screen; pushing it keeps the aim turning that way (FlightController) and letting
-- go flies on straight and levels out, like letting go of the mouse. Right thumb: Fire (weapon 1), weapon 2 and Boost
-- (only with a boost part), held like the mouse buttons and Shift (CombatController, FlightController). Shown only
-- while flying on a touch screen.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Config = require(Root.Generated.Gameplay).flight
local PaperUI = require(script.Parent.PaperUI)
local Words = require(Root.Shared.TouchWords)
local Layout = require(Root.Shared.TouchLayout)
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local UI = require(Root.Shared.UIAssets)
local Art = require(Root.Shared.UIAssets).touch -- peel stickers (Alan 2026-10-28, ui-concepts/touch-buttons-c.png)

local Touch = { stick = Vector2.zero, boost = false, brake = false, onFire = nil } -- onFire(which, down): CombatController's triggers
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

	-- Moving the buttons (Settings > Phone buttons): while `editing`, presses move buttons instead of using them.
	local editing, releaseAll = nil, nil
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
			if editing or input.UserInputType ~= Enum.UserInputType.Touch or entry.touch then return end
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
	-- onShot(): a FIRE or 2 press (RangeBoard: what the crosshair is on).
	local fire = holdButton("Fire", "FIRE", CRAYON.green, function(down) if Touch.onFire then Touch.onFire(1, down) end; if down and Touch.onShot then Touch.onShot() end end)
	local fire2 = holdButton("Fire2", "2", CRAYON.green, function(down) if Touch.onFire then Touch.onFire(2, down) end; if down and Touch.onShot then Touch.onShot() end end)
	local boost = holdButton("Boost", "BOOST", CRAYON.blue, function(down) Touch.boost = down end)
	-- The brake (Alan 2026-10-29), always there, Speed match or not (FlightController).
	local brake = holdButton("Brake", "BRAKE", CRAYON.orange, function(down) Touch.brake = down end)

	-- Sizes follow the screen's short side, kept thumb-sized (points): a phone and a tablet both get pieces a thumb
	-- can hit, and a tablet's don't grow huge. Spots: the player's own layout where it fits (TouchLayout), else these.
	local frames = { Fire = fire, Fire2 = fire2, Boost = boost, Brake = brake }
	local sizes, defaults, spots, view, top = {}, {}, {}, Vector2.one, 0
	local function show(name) frames[name].Position = UDim2.fromOffset(spots[name].X, spots[name].Y) end
	local function saved()
		local ok, layout = pcall(HttpService.JSONDecode, HttpService, Root:GetAttribute("TouchLayout") or "null")
		return ok and Layout.valid(layout) and layout or nil
	end
	local function fit()
		view = workspace.CurrentCamera.ViewportSize
		top = GuiService.TopbarInset.Max.Y
		local short = math.min(view.X, view.Y)
		radius = math.clamp(short * Config.touch_stick_radius, 44, 80)
		base.Size, knob.Size = UDim2.fromOffset(radius * 2, radius * 2), UDim2.fromOffset(radius * 0.9, radius * 0.9)
		local big, small = math.clamp(short * 0.24, 76, 120), math.clamp(short * 0.16, 52, 84)
		sizes = { Fire = big, Fire2 = small, Boost = small, Brake = small }
		local fireAt = view - Vector2.new(big * 0.5 + short * 0.06, big * 0.5 + short * 0.08)
		-- BRAKE hugs FIRE's top-left edge, between 2 and BOOST, where the thumb rolls to it (Alan 2026-10-29: the corner
		-- above BOOST was too far out).
		local reach = (big + small) * 0.5 + short * 0.05
		defaults = {
			Fire = fireAt,
			Fire2 = Vector2.new(fireAt.X, view.Y - big - small * 0.5 - short * 0.12),
			Boost = Vector2.new(view.X - big - small * 0.5 - short * 0.12, view.Y - small * 0.5 - short * 0.08),
			Brake = fireAt - Vector2.new(reach, reach) * 0.707,
		}
		for name, frame in frames do frame.Size = UDim2.fromOffset(sizes[name], sizes[name]) end
		if editing then return end
		spots = Layout.place(saved(), defaults, sizes, view, top)
		for name in frames do show(name) end
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	Root:GetAttributeChangedSignal("TouchLayout"):Connect(fit)
	fit()

	-- The editor (docs/plan/CONTROLS-PLAN.md, Alan 2026-10-30): the left half shaded for the stick, a sticky note with
	-- Save / Reset / Cancel, and every button draggable. A button that would leave its area or touch another turns red
	-- and slides back to its last good spot when let go.
	local editor = Instance.new("ScreenGui")
	editor.Name, editor.ResetOnSpawn, editor.IgnoreGuiInset, editor.DisplayOrder, editor.Enabled = "TouchLayoutEditor", false, true, 6, false
	editor.Parent = gui.Parent
	local shade = Instance.new("Frame")
	shade.Name, shade.BackgroundColor3, shade.BackgroundTransparency, shade.Size = "StickHalf", Color3.new(0, 0, 0), 0.55, UDim2.fromScale(0.5, 1)
	shade.Parent = editor
	local stickWords = PaperUI.words(shade, "StickWords", "Steering stick", 0, 0, 10, 10, 26)
	stickWords.AnchorPoint, stickWords.Position, stickWords.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.85), UDim2.fromScale(0.9, 0.1)
	stickWords.TextXAlignment, stickWords.TextColor3 = Enum.TextXAlignment.Center, Color3.new(1, 1, 1)
	local note = Instance.new("ImageLabel")
	note.Name, note.Image, note.ScaleType, note.BackgroundTransparency = "Note", UI.ingame.stickyNote, Enum.ScaleType.Stretch, 1
	note.AnchorPoint, note.Position, note.Size, note.Rotation = Vector2.new(0.5, 0.5), UDim2.fromScale(0.25, 0.45), UDim2.fromOffset(330, 190), -1
	note.Parent = editor
	local noteWords = PaperUI.words(note, "Words", "Drag a button to move it.", 20, 22, 290, 60, 26)
	noteWords.TextXAlignment, noteWords.TextWrapped = Enum.TextXAlignment.Center, true
	local strip = UI.mainmenu.strip
	local finish -- finish(saveIt)
	PaperUI.button(note, "Save", strip.green, "Save", 18, 112, 96, 48, 1, function() finish("save") end, 24)
	PaperUI.button(note, "Reset", strip.yellow, "Reset", 117, 112, 96, 48, -1, function() finish("reset") end, 24)
	PaperUI.button(note, "Cancel", strip.red, "Cancel", 216, 112, 96, 48, 1, function() finish("cancel") end, 24)
	-- A see-through red disc over a button in a bad spot (tinting the art alone barely showed on blue or green).
	local warns = {}
	for name, frame in frames do
		local warn = Instance.new("Frame")
		warn.Name, warn.Size, warn.BackgroundColor3, warn.BackgroundTransparency = "Warn", UDim2.fromScale(1, 1), Color3.fromRGB(230, 30, 30), 0.35
		warn.ZIndex, warn.Visible, warn.Parent = 5, false, frame
		Instance.new("UICorner", warn).CornerRadius = UDim.new(0.5, 0)
		warns[name] = warn
	end
	local function tint(name, bad) warns[name].Visible = bad end
	-- The dragged button is drawn over the others (ZIndex is global in this gui).
	local function lift(name, by)
		local frame = frames[name]
		for _, piece in { frame, unpack(frame:GetDescendants()) } do
			if piece:IsA("GuiObject") then piece.ZIndex += by end
		end
	end
	local drag
	for name, frame in frames do
		frame.InputBegan:Connect(function(input)
			if not editing or drag then return end
			if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			drag = { name = name, input = input, from = Vector2.new(input.Position.X, input.Position.Y), start = spots[name], good = spots[name] }
			lift(name, 10)
		end)
	end
	Input.InputChanged:Connect(function(input)
		if not drag or (input ~= drag.input and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement and drag.input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local at = drag.start + Vector2.new(input.Position.X, input.Position.Y) - drag.from
		local fits = Layout.fits(drag.name, at, spots, sizes, view, top)
		if fits then drag.good = at end
		spots[drag.name] = at; show(drag.name); tint(drag.name, not fits)
	end)
	Input.InputEnded:Connect(function(input)
		local mouse = input.UserInputType == Enum.UserInputType.MouseButton1 and drag and drag.input.UserInputType == Enum.UserInputType.MouseButton1
		if not drag or (input ~= drag.input and not mouse) then return end
		local name = drag.name
		spots[name] = drag.good; drag = nil
		tint(name, false); lift(name, -10)
		TweenService:Create(frames[name], TweenInfo.new(0.15), { Position = UDim2.fromOffset(spots[name].X, spots[name].Y) }):Play()
	end)
	-- Opens the editor; done(layout) gets the shares to save (nil = the game's layout), or false when cancelled.
	function Touch.editLayout(done)
		releaseAll()
		local before = table.clone(spots)
		editing = done
		for name in frames do frames[name].Visible = true end
		editor.Enabled = true
		finish = function(how)
			if how == "reset" then
				spots = table.clone(defaults)
				for name in frames do show(name) end
				return
			end
			if drag then lift(drag.name, -10) end
			drag, editing, editor.Enabled = nil, nil, false
			for name in frames do tint(name, false) end
			if how == "cancel" then
				spots = before
				for name in frames do show(name) end
				done(false)
				return
			end
			local moved = {}
			for name, at in spots do if (at - defaults[name]).Magnitude > 1 then moved[name] = at end end
			done(next(moved) and Layout.shares(moved, view) or nil)
		end
	end

	function releaseAll()
		stickTouch, Touch.stick, base.Visible = nil, Vector2.zero, false
		for _, entry in buttons do entry.release() end
	end
	Input.TouchStarted:Connect(function(touch, processed)
		if processed or stickTouch or not gui.Enabled or editing then return end
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
		local showing = flying or editing ~= nil
		if showing ~= gui.Enabled then
			gui.Enabled = showing
			if not showing then releaseAll() end
		end
		if editing then return end
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
