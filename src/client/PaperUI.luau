-- Shared pieces for the paper-and-crayon menu screens (concepts: assets/references/ui-concepts/).
-- Each screen is a fixed 1920x1080 sheet that UIScale stretches to cover the screen; words are live text.
local TweenService = game:GetService("TweenService")
local ScreenFit = require(script.Parent.ScreenFit)
local BoardPlate = require(game.ReplicatedFirst:WaitForChild("FlyFightPaper"):WaitForChild("BoardPlate"))
local PaperUI = {}

PaperUI.W, PaperUI.H = 1920, 1080
PaperUI.INK = Color3.fromRGB(40, 30, 24) -- warm black (text style C)
PaperUI.font = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold)

-- A full-screen layer (own ScreenGui so its pieces stack simply) holding a hidden cover and the scaled sheet.
-- With no background ids the cover is a see-through dim (for overlays on top of the game). floating: the background
-- art has its own see-through edges (the game shows around it), so the cover is clear and the sheet fits inside.
-- A number for floating also shrinks the sheet to that share of the screen (the Training board: a smaller board).
function PaperUI.screen(playerGui, name, backgroundIds, floating)
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.IgnoreGuiInset, layer.ResetOnSpawn, layer.DisplayOrder = name, true, false, 10
	layer.ScreenInsets = Enum.ScreenInsets.None -- the background reaches past a phone's notch; the sheet stays clear of it
	layer.ZIndexBehavior, layer.Parent = Enum.ZIndexBehavior.Sibling, playerGui
	-- The safe area (clear of notches and rounded corners) is what a default ScreenGui fills: one empty probe measures it.
	local safe = playerGui:FindFirstChild("SafeArea")
	if not safe then
		safe = Instance.new("ScreenGui")
		safe.Name, safe.IgnoreGuiInset, safe.ResetOnSpawn, safe.Parent = "SafeArea", true, false, playerGui
	end
	local cover = Instance.new("Frame")
	cover.Name, cover.Size, cover.BackgroundColor3, cover.BorderSizePixel = "Cover", UDim2.fromScale(1, 1), Color3.fromRGB(150, 105, 60), 0
	cover.ClipsDescendants, cover.Visible, cover.Parent = true, false, layer -- hidden until shown (plays the pop-in)
	if #backgroundIds == 0 then cover.BackgroundColor3, cover.BackgroundTransparency = Color3.fromRGB(20, 14, 8), 0.45 end
	if floating then cover.BackgroundTransparency = 1 end
	local function page(name)
		local frame = Instance.new("Frame")
		frame.Name, frame.AnchorPoint, frame.Position = name, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
		frame.Size, frame.BackgroundTransparency, frame.Parent = UDim2.fromOffset(PaperUI.W, PaperUI.H), 1, cover
		Instance.new("UIScale").Parent = frame
		return frame
	end
	-- The background art covers the screen (cropping its edges on other shapes); the buttons and words sit on their own
	-- sheet that always fits inside it, so on a phone's wide screen nothing is cut off at the top and bottom (2026-10-24).
	local backdrop = #backgroundIds > 0 and not floating and page("Backdrop") or nil
	local sheet = page("Sheet")
	local function fit()
		local full, room = layer.AbsoluteSize, safe.AbsoluteSize
		if full.X < 2 or room.X < 2 or not sheet.Parent then return end -- (a screen that was destroyed: the safe area's signal outlives it)
		sheet.UIScale.Scale = math.min(room.X / PaperUI.W, room.Y / PaperUI.H) * (type(floating) == "number" and floating or 1)
		local middle = safe.AbsolutePosition + room / 2 - layer.AbsolutePosition
		sheet.Position = UDim2.fromOffset(middle.X, middle.Y)
		if backdrop then
			backdrop.UIScale.Scale = math.max(full.X / PaperUI.W, full.Y / PaperUI.H)
			-- Phones crop a lot off a drawn background: from the bottom only, so titles drawn at the top stay whole.
			local phone = PaperUI.isPhone()
			backdrop.AnchorPoint, backdrop.Position = Vector2.new(0.5, phone and 0 or 0.5), UDim2.fromScale(0.5, phone and 0 or 0.5)
		end
	end
	for _, gui in { layer, safe } do
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(fit)
	end
	fit()
	-- Background plates come as a 2x2 grid of tiles, drawn as one 3D board (first/BoardPlate: ~7x smaller downloads).
	if #backgroundIds > 0 then
		local board = BoardPlate.new(backgroundIds)
		board.Size, board.Parent = UDim2.fromOffset(PaperUI.W, PaperUI.H), backdrop or sheet
	end
	return cover, sheet
end

-- Pieces are centred on their box so they can pop in from the middle.
function PaperUI.image(parent, name, id, x, y, w, h, rotation)
	local label = Instance.new("ImageLabel")
	label.Name, label.Image, label.BackgroundTransparency = name, id, 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position, label.Size, label.Rotation = UDim2.fromOffset(x + w / 2, y + h / 2), UDim2.fromOffset(w, h), rotation or 0
	label.ScaleType = Enum.ScaleType.Fit
	label.Parent = parent
	return label
end

function PaperUI.words(parent, name, value, x, y, w, h, size)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.BackgroundTransparency = name, value, 1
	label.Position, label.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	label.FontFace, label.TextSize, label.TextColor3 = PaperUI.font, size, PaperUI.INK
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return PaperUI.crayon(label)
end

-- Style C (Alan 2026-11-08, docs/decisions/2026-11-08-text-style-crayon.md): Kalam made heavier by a stroke of its own
-- colour, a light cream outline and a soft shadow. A label draws only one UIStroke, so the label's own letters are hidden
-- (MaxVisibleGraphemes 0 keeps its TextBounds) and three child copies draw the look, following its text, colour and
-- fades. A label that gets its own UIStroke later keeps that look instead.
local CREAM, SHADOW = Color3.fromRGB(255, 248, 232), Color3.new(0, 0, 0)
local FOLLOW = { "Text", "TextSize", "TextScaled", "TextWrapped", "RichText", "FontFace", "TextXAlignment",
	"TextYAlignment", "LineHeight", "TextTruncate" }
local WATCH = { TextColor3 = true, TextTransparency = true, TextBounds = true }
for _, key in FOLLOW do WATCH[key] = true end
function PaperUI.crayon(label)
	local copies, watching = {}, nil
	for _, name in { "CrayonShadow", "CrayonOutline", "CrayonInk" } do -- later children draw on top
		local copy = Instance.new("TextLabel")
		copy.Name, copy.BackgroundTransparency, copy.Size = name, 1, UDim2.fromScale(1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.LineJoinMode, stroke.Parent = Enum.LineJoinMode.Round, copy
		copy.Parent = label
		table.insert(copies, copy)
	end
	local shadow, outline, ink = copies[1], copies[2], copies[3]
	local function refresh()
		for _, copy in copies do for _, key in FOLLOW do copy[key] = label[key] end end
		-- Sheet-sized letters: a scaled label's TextBounds are screen pixels, its offset height is sheet units.
		local size = label.TextSize
		if label.TextScaled and label.AbsoluteSize.Y > 0 then
			size = ink.TextBounds.Y * (label.Size.Y.Offset > 0 and label.Size.Y.Offset / label.AbsoluteSize.Y or 1)
		end
		local heavy = size * (size >= 40 and 0.03 or 0.018)
		local edge, t = heavy + math.max(2, size * 0.07), label.TextTransparency
		local dim = 0.72 + 0.28 * t
		ink.TextColor3, ink.TextTransparency = label.TextColor3, t
		ink.UIStroke.Color, ink.UIStroke.Thickness, ink.UIStroke.Transparency = label.TextColor3, heavy, t
		outline.TextColor3, outline.TextTransparency = CREAM, t
		outline.UIStroke.Color, outline.UIStroke.Thickness, outline.UIStroke.Transparency = CREAM, edge, t
		shadow.TextColor3, shadow.TextTransparency = SHADOW, dim
		shadow.UIStroke.Color, shadow.UIStroke.Thickness, shadow.UIStroke.Transparency = SHADOW, edge, dim
		shadow.Position = UDim2.fromOffset(size * 0.04 + 1, size * 0.06 + 1)
	end
	label.MaxVisibleGraphemes = 0
	refresh()
	watching = label.Changed:Connect(function(key) if WATCH[key] then refresh() end end)
	label.ChildAdded:Connect(function(child)
		if child:IsA("UIStroke") and watching then
			watching:Disconnect(); watching = nil
			for _, copy in copies do copy:Destroy() end
			label.MaxVisibleGraphemes = -1
		end
	end)
	return label
end

-- Phones (Alan 2026-10-24: readable and good-looking there too): a screen under 540 points tall. Sheets drawn for
-- 1080p shrink to about a third there, so pieces get phone sizes (bigger words, bigger taps) while a PC keeps exactly
-- what was drawn. The pop-in and the buttons' squish go back to a piece's resting size, kept here.
local rest = setmetatable({}, { __mode = "k" }) -- piece -> { size, rotation }

function PaperUI.isPhone()
	return ScreenFit.kind() == "phone"
end

-- apply(phone) now and again whenever the screen crosses the phone size.
function PaperUI.onPhone(apply)
	local last
	local function check()
		local phone = PaperUI.isPhone()
		if phone ~= last then last = phone; apply(phone) end
	end
	ScreenFit.watch(check)
end

-- Gives a piece other property values on a phone, e.g. PaperUI.phone(label, { TextSize = 40 }).
function PaperUI.phone(piece, props)
	local pc = {}
	for key in props do pc[key] = piece[key] end
	PaperUI.onPhone(function(phone)
		PaperUI.set(piece, phone and props or pc)
	end)
	return piece
end

-- Sets a piece's properties now; a button keeps its new size as its resting size.
function PaperUI.set(piece, props)
	for key, value in props do piece[key] = value end
	if rest[piece] then rest[piece] = { size = piece.Size, rotation = piece.Rotation } end
end

PaperUI.TAP = 46 -- points: a phone's least tap size (44 asked, a little over so rounding never drops under)
-- Phones (Alan 2026-10-28: make mobile work): a sheet drawn for 1080p shows at a third on a small phone, so a
-- button can come out 18-37 points tall. An invisible tap area ("Hit") reaches at least TAP points each way around
-- it, the size Apple and Google ask for; the art stays as drawn. It takes the taps, so code that listens to a
-- button's own presses (a hold, a drag) listens to its Hit too. tallOnly: grow up and down only (a row of buttons
-- close together, so one's tap area never covers its neighbour).
function PaperUI.tapArea(button, tallOnly)
	local hit = Instance.new("TextButton")
	hit.Name, hit.Text, hit.BackgroundTransparency, hit.AutoButtonColor = "Hit", "", 1, false
	hit.AnchorPoint, hit.Position, hit.Visible, hit.Parent = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), false, button
	local function grow()
		-- Measured at the button's resting size: the hover grow (1.05x) once lifted a button just under TAP over it,
		-- hiding the Hit mid-tap so the tap was lost (the Range Hangar's Back, Alan's phone run 2026-10-28).
		local scale = button.AbsoluteSize.X / math.max(button.Size.X.Offset, 1) -- screen points per drawn point
		local base = rest[button] and rest[button].size or button.Size
		local size = Vector2.new(base.X.Offset, base.Y.Offset) * scale
		local wide, tall = tallOnly and 0 or math.max(0, PaperUI.TAP - size.X), math.max(0, PaperUI.TAP - size.Y)
		hit.Visible = PaperUI.isPhone() and scale > 0 and (wide > 0 or tall > 0)
		if hit.Visible then hit.Size = UDim2.new(1, wide / scale, 1, tall / scale) end
	end
	button:GetPropertyChangedSignal("AbsoluteSize"):Connect(grow)
	grow()
	return hit
end
-- A paper button with a word on it: grows and tilts under the mouse, squishes when pressed.
function PaperUI.button(parent, name, id, label, x, y, w, h, rotation, callback, size)
	local button = Instance.new("ImageButton")
	button.Name, button.Image, button.BackgroundTransparency = name, id, 1
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position, button.Size, button.Rotation = UDim2.fromOffset(x + w / 2, y + h / 2), UDim2.fromOffset(w, h), rotation or 0
	button.ScaleType = Enum.ScaleType.Stretch
	button.Parent = parent
	rest[button] = { size = button.Size, rotation = button.Rotation }
	local text = PaperUI.words(button, "Label", label, 0, 0, w, h, size or 80)
	text.Size, text.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	local function to(sx, sy, turn)
		local base = rest[button]
		local size = base.size
		TweenService:Create(button, info, { Size = UDim2.fromOffset(size.X.Offset * sx, size.Y.Offset * sy), Rotation = base.rotation + turn }):Play()
	end
	local hit = PaperUI.tapArea(button)
	for _, target in { button, hit } do
		target.MouseEnter:Connect(function() to(1.05, 1.05, -1.5) end)
		target.MouseLeave:Connect(function() to(1, 1, 0) end)
		target.MouseButton1Down:Connect(function() to(0.95, 0.92, -1.5) end)
		target.MouseButton1Up:Connect(function() to(1.05, 1.05, -1.5) end)
		target.Activated:Connect(callback)
	end
	return button
end

-- Every time the cover is shown, the named pieces pop onto the sheet one after another.
-- Puts the crayon arrow just outside a box (screen pixels, low and high corners), on the side facing `from`, pointing
-- in at it. `s` is the screen's scale. Used by the Range's notes and the Match Tips.
function PaperUI.pointArrow(arrow, from, low, high, s)
	local middle, half = (low + high) / 2, (high - low) / 2
	local away = from - middle
	away = away.Magnitude > 1 and away.Unit or Vector2.new(0, -1)
	local edge = math.min(math.abs(away.X) > 1e-3 and half.X / math.abs(away.X) or math.huge, math.abs(away.Y) > 1e-3 and half.Y / math.abs(away.Y) or math.huge)
	local tip = middle + away * (edge + 70 * s)
	arrow.Position, arrow.Rotation = UDim2.fromOffset(tip.X, tip.Y), math.deg(math.atan2(-away.Y, -away.X))
end

function PaperUI.popIn(cover, pieces)
	for _, piece in pieces do rest[piece] = rest[piece] or { size = piece.Size, rotation = piece.Rotation } end
	local pop = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		if not cover.Visible then return end
		for i, piece in pieces do
			local base = rest[piece]
			piece.Size = UDim2.fromOffset(base.size.X.Offset * 0.6, base.size.Y.Offset * 0.6)
			piece.Rotation = base.rotation + (i % 2 == 0 and 8 or -8)
			task.delay(0.04 * i, function()
				TweenService:Create(piece, pop, { Size = base.size, Rotation = base.rotation }):Play()
			end)
		end
	end)
end

return PaperUI
