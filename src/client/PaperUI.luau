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

-- Style C (Alan 2026-11-08, docs/decisions/2026-11-08-text-style-crayon.md): warm-black Kalam over a cream edge and a soft
-- shadow. Loud words (buttons, titles, names, HUD slips: `PaperUI.loud`) are also made heavier with a stroke of their own
-- colour and get the full edge; every other word is quiet (Alan, same night: descriptive words with the full look were
-- hard to read), a thin edge and a fainter shadow. A label draws only one UIStroke, so the label's own letters are hidden
-- (MaxVisibleGraphemes 0 keeps its TextBounds) and three child copies draw the look, following its text, colour and
-- fades. A label that gets its own UIStroke later keeps that look; a text box shows its own letters while typing or empty.
local CREAM, SHADOW = Color3.fromRGB(255, 248, 232), Color3.new(0, 0, 0)
-- ZIndex too: copies left at 1 drew under whatever the label sits over (Alan's phone 2026-11-11: FIRE's crayon fill
-- covered its words).
local FOLLOW = { "Text", "TextSize", "TextScaled", "TextWrapped", "RichText", "FontFace", "TextXAlignment",
	"TextYAlignment", "LineHeight", "TextTruncate", "ZIndex" }
local WATCH = { TextColor3 = true, TextTransparency = true, TextBounds = true }
for _, key in FOLLOW do WATCH[key] = true end
function PaperUI.crayon(label)
	local copies, watching, typing = {}, nil, false
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
		local own = typing or label:IsA("TextBox") and label.Text == ""
		label.MaxVisibleGraphemes = own and -1 or 0
		-- A size cap on the label caps its copies too (they drew scaled words at full box size: 2026-11-09).
		local cap = label:FindFirstChildOfClass("UITextSizeConstraint")
		for _, copy in copies do
			copy.Visible = not own
			for _, key in FOLLOW do copy[key] = label[key] end
			local mine = copy:FindFirstChildOfClass("UITextSizeConstraint")
			if cap and not mine then mine = Instance.new("UITextSizeConstraint"); mine.Parent = copy end
			if mine then mine.MaxTextSize, mine.MinTextSize = cap and cap.MaxTextSize or 1000, cap and cap.MinTextSize or 1 end
		end
		-- Sheet-sized letters: a scaled label's TextBounds are screen pixels, its offset height is sheet units.
		local size = label.TextSize
		if label.TextScaled and label.AbsoluteSize.Y > 0 then
			size = ink.TextBounds.Y * (label.Size.Y.Offset > 0 and label.Size.Y.Offset / label.AbsoluteSize.Y or 1)
		end
		local loud, t = label:GetAttribute("Loud") == true, label.TextTransparency
		local heavy = loud and size * (size >= 40 and 0.03 or 0.018) or 0
		local edge = loud and heavy + math.max(2, size * 0.07) or math.max(1, size * 0.035)
		local dim = (loud and 0.72 or 0.85) + (loud and 0.28 or 0.15) * t
		local drop = loud and 1 or 0.6
		ink.TextColor3, ink.TextTransparency = label.TextColor3, t
		ink.UIStroke.Enabled, ink.UIStroke.Color, ink.UIStroke.Thickness, ink.UIStroke.Transparency = loud, label.TextColor3, heavy, t
		outline.TextColor3, outline.TextTransparency = CREAM, t
		outline.UIStroke.Color, outline.UIStroke.Thickness, outline.UIStroke.Transparency = CREAM, edge, t
		shadow.TextColor3, shadow.TextTransparency = SHADOW, dim
		shadow.UIStroke.Color, shadow.UIStroke.Thickness, shadow.UIStroke.Transparency = SHADOW, edge, dim
		shadow.Position = UDim2.fromOffset((size * 0.04 + 1) * drop, (size * 0.06 + 1) * drop)
	end
	refresh()
	watching = label.Changed:Connect(function(key) if WATCH[key] then refresh() end end)
	label:GetAttributeChangedSignal("Loud"):Connect(function() if watching then refresh() end end)
	if label:IsA("TextBox") then
		label.Focused:Connect(function() typing = true; if watching then refresh() end end)
		label.FocusLost:Connect(function() typing = false; if watching then refresh() end end)
	end
	label.ChildAdded:Connect(function(child)
		if child:IsA("UITextSizeConstraint") and watching then
			refresh()
			child.Changed:Connect(function() if watching then refresh() end end)
		end
		if child:IsA("UIStroke") and watching then
			watching:Disconnect(); watching = nil
			for _, copy in copies do copy:Destroy() end
			label.MaxVisibleGraphemes = -1
		end
	end)
	return label
end
-- 18500 -> "18,500".
function PaperUI.commas(n)
	local s = tostring(n)
	while true do
		local next, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = next
		if k == 0 then return s end
	end
end

-- Words that grab attention (buttons, titles, names) get the full style C.
function PaperUI.loud(label)
	label:SetAttribute("Loud", true)
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
-- Words too long for `room` (sheet units across, or a function giving it) get smaller until they fit; words that fit
-- keep their size (Alan 2026-11-09: "Paper Pellet Gun" ran off its card while "Spitball Straw" fit). Follows later
-- changes of the text.
local TextService = game:GetService("TextService")
function PaperUI.fitWords(label, room)
	local want, mine, asked = label.TextSize, nil, 0
	local function fit()
		asked += 1
		local ticket = asked
		task.spawn(function()
			local params = Instance.new("GetTextBoundsParams")
			params.Text, params.Font, params.Size, params.Width = label.Text, label.FontFace, want, 100000
			params.RichText = label.RichText
			local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			if not ok or ticket ~= asked then return end
			local across = type(room) == "function" and room() or room
			mine = bounds.X > across and math.floor(want * across / bounds.X) or want
			label.TextSize = mine
		end)
	end
	label:GetPropertyChangedSignal("Text"):Connect(fit)
	-- A size set from outside (a phone's bigger words) is the new size to aim for.
	label:GetPropertyChangedSignal("TextSize"):Connect(function()
		if label.TextSize ~= mine then want = label.TextSize; fit() end
	end)
	fit()
end

-- A paper button with a word on it: grows and tilts under the mouse, squishes when pressed.
function PaperUI.button(parent, name, id, label, x, y, w, h, rotation, callback, size)
	local button = Instance.new("ImageButton")
	button.Name, button.Image, button.BackgroundTransparency = name, id, 1
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position, button.Size, button.Rotation = UDim2.fromOffset(x + w / 2, y + h / 2), UDim2.fromOffset(w, h), rotation or 0
	-- The picture keeps its own shape inside the box (Alan 2026-11-09: stretched strips squashed their painted tacks);
	-- the box is still what takes the clicks.
	button.ScaleType = Enum.ScaleType.Fit
	button.Parent = parent
	rest[button] = { size = button.Size, rotation = button.Rotation }
	local text = PaperUI.loud(PaperUI.words(button, "Label", label, 0, 0, w, h, size or 80))
	text.Size, text.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
	PaperUI.fitWords(text, function() return (rest[button] or { size = button.Size }).size.X.Offset * 0.7 end) -- between a strip's painted tacks
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

-- A green strip with words, Roblox's own Robux symbol and a price, centred: "Unlock now (R) 49" (Hangar), "2x Paper (R) 79"
-- (report card).
-- A soft shadow under a picture instead of a backing circle (Alan 2026-11-12, docs/workshop/design-examples.md):
-- stacked faint ovals centred on x, y, the widest w across. Make it before the picture so the picture sits on top.
function PaperUI.shadow(parent, x, y, w)
	for i, f in { 1, 0.82, 0.64, 0.45 } do
		local shade = Instance.new("Frame")
		shade.Name, shade.AnchorPoint, shade.BorderSizePixel = "Shadow" .. i, Vector2.new(0.5, 0.5), 0
		shade.Position, shade.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w * f, w * f * 0.21)
		shade.BackgroundColor3, shade.BackgroundTransparency = Color3.fromRGB(10, 10, 40), 0.85
		Instance.new("UICorner", shade).CornerRadius = UDim.new(0.5, 0)
		shade.Parent = parent
	end
end

function PaperUI.robuxButton(parent, name, x, y, w, h, label, price, size, callback)
	local button = PaperUI.button(parent, name, require(game.ReplicatedStorage.FlyFightPaper.Shared.UIAssets).mainmenu.strip.green, "", x, y, w, h, -1, callback, size)
	local row = Instance.new("Frame")
	row.Name, row.BackgroundTransparency, row.Size, row.ZIndex = "Price", 1, UDim2.fromScale(1, 1), button.ZIndex
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.HorizontalAlignment, list.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
	list.Padding, list.SortOrder, list.Parent = UDim.new(0, size * 0.25), Enum.SortOrder.LayoutOrder, row
	for i, text in { label, false, tostring(price) } do
		local piece
		if text then
			piece = PaperUI.loud(PaperUI.words(row, "Word" .. i, text, 0, 0, 0, h, size))
			piece.AutomaticSize = Enum.AutomaticSize.X
		else
			piece = Instance.new("ImageLabel")
			piece.Name, piece.Image, piece.BackgroundTransparency, piece.ImageColor3 = "Robux", "rbxasset://textures/ui/common/robux@3x.png", 1, PaperUI.INK
			piece.Size = UDim2.fromOffset(size * 0.9, size * 0.9)
		end
		piece.LayoutOrder, piece.Parent = i, row
	end
	row.Parent = button
	return button
end

return PaperUI
