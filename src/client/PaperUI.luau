-- Shared pieces for the paper-and-crayon menu screens (concepts: assets/references/ui-concepts/).
-- Each screen is a fixed 1920x1080 sheet that UIScale stretches to cover the screen; words are live text.
local TweenService = game:GetService("TweenService")
local PaperUI = {}

PaperUI.W, PaperUI.H = 1920, 1080
PaperUI.INK = Color3.fromRGB(28, 26, 30)
PaperUI.font = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold)

-- A full-screen layer (own ScreenGui so its pieces stack simply) holding a hidden cover and the scaled sheet.
-- With no background ids the cover is a see-through dim (for overlays on top of the game). floating: the background
-- art has its own see-through edges (the game shows around it), so the cover is clear and the sheet fits inside.
-- A number for floating also shrinks the sheet to that share of the screen (the Training board: a smaller board).
function PaperUI.screen(playerGui, name, backgroundIds, floating)
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.IgnoreGuiInset, layer.ResetOnSpawn, layer.DisplayOrder = name, true, false, 10
	layer.ZIndexBehavior, layer.Parent = Enum.ZIndexBehavior.Sibling, playerGui
	local cover = Instance.new("Frame")
	cover.Name, cover.Size, cover.BackgroundColor3, cover.BorderSizePixel = "Cover", UDim2.fromScale(1, 1), Color3.fromRGB(150, 105, 60), 0
	cover.ClipsDescendants, cover.Visible, cover.Parent = true, false, layer -- hidden until shown (plays the pop-in)
	if #backgroundIds == 0 then cover.BackgroundColor3, cover.BackgroundTransparency = Color3.fromRGB(20, 14, 8), 0.45 end
	if floating then cover.BackgroundTransparency = 1 end
	local sheet = Instance.new("Frame")
	sheet.Name, sheet.AnchorPoint, sheet.Position = "Sheet", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	sheet.Size, sheet.BackgroundTransparency, sheet.Parent = UDim2.fromOffset(PaperUI.W, PaperUI.H), 1, cover
	local scale = Instance.new("UIScale")
	scale.Parent = sheet
	local function fit()
		local view = workspace.CurrentCamera.ViewportSize
		-- Backgrounds cover the screen (cropping frame edges on odd shapes); overlays fit inside it.
		scale.Scale = (#backgroundIds > 0 and not floating and math.max or math.min)(view.X / PaperUI.W, view.Y / PaperUI.H) * (type(floating) == "number" and floating or 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
	-- Background plates come as a 2x2 grid of tiles (Roblox images max out at 1024 pixels).
	for i, id in backgroundIds do
		local tile = PaperUI.image(sheet, "Background" .. i, id, ((i - 1) % 2) * PaperUI.W / 2, math.floor((i - 1) / 2) * PaperUI.H / 2, PaperUI.W / 2, PaperUI.H / 2)
		tile.ScaleType = Enum.ScaleType.Stretch
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
	return label
end

-- A paper button with a word on it: grows and tilts under the mouse, squishes when pressed.
function PaperUI.button(parent, name, id, label, x, y, w, h, rotation, callback, size)
	local button = Instance.new("ImageButton")
	button.Name, button.Image, button.BackgroundTransparency = name, id, 1
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position, button.Size, button.Rotation = UDim2.fromOffset(x + w / 2, y + h / 2), UDim2.fromOffset(w, h), rotation or 0
	button.ScaleType = Enum.ScaleType.Stretch
	button.Parent = parent
	local text = PaperUI.words(button, "Label", label, 0, 0, w, h, size or 80)
	text.Size, text.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	local function to(sx, sy, turn)
		TweenService:Create(button, info, { Size = UDim2.fromOffset(w * sx, h * sy), Rotation = (rotation or 0) + turn }):Play()
	end
	button.MouseEnter:Connect(function() to(1.05, 1.05, -1.5) end)
	button.MouseLeave:Connect(function() to(1, 1, 0) end)
	button.MouseButton1Down:Connect(function() to(0.95, 0.92, -1.5) end)
	button.MouseButton1Up:Connect(function() to(1.05, 1.05, -1.5) end)
	button.Activated:Connect(callback)
	return button
end

-- Every time the cover is shown, the named pieces pop onto the sheet one after another.
function PaperUI.popIn(cover, pieces)
	local start = {}
	for _, piece in pieces do start[piece] = { size = piece.Size, rotation = piece.Rotation } end
	local pop = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		if not cover.Visible then return end
		for i, piece in pieces do
			local base = start[piece]
			piece.Size = UDim2.fromOffset(base.size.X.Offset * 0.6, base.size.Y.Offset * 0.6)
			piece.Rotation = base.rotation + (i % 2 == 0 and 8 or -8)
			task.delay(0.04 * i, function()
				TweenService:Create(piece, pop, { Size = base.size, Rotation = base.rotation }):Play()
			end)
		end
	end)
end

return PaperUI
