-- Settings on a taped sheet of lined paper (Alan's approved concept: assets/references/ui-concepts/settings.png).
-- Sliders are pencils on rulers, crosshair colours are dot stickers, choices are paper tabs.
local Input = game:GetService("UserInputService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets).settings
local PaperUI = require(script.Parent.PaperUI)
local SettingsScreen = {}

local COLORS = { "red", "blue", "green", "yellow", "purple", "white" }
local SWATCH = { green = Color3.fromRGB(60, 255, 90), red = Color3.fromRGB(255, 60, 70), blue = Color3.fromRGB(0, 235, 255),
	yellow = Color3.fromRGB(255, 225, 40), purple = Color3.fromRGB(190, 110, 255), white = Color3.fromRGB(250, 250, 250) }
local SIZES = { "Small", "Medium", "Large" }

-- api = { save(settings), back() }
function SettingsScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "SettingsScreen", Art.bg)
	local image, words = PaperUI.image, PaperUI.words
	local settings
	local refresh = {}
	local function save() api.save(settings) end

	local Options = require(script.Parent.Options)
	-- A pencil on a ruler. Drag the pencil (or click the ruler); the value saves when the mouse is released.
	local function slider(key, label, y, lo, hi, step, show, minLabel, maxLabel)
		words(sheet, key .. "Label", label, 285, y - 72, 520, 60, 52)
		local ruler = image(sheet, key .. "Ruler", Art.ruler, 280, y, 510, 72)
		ruler.ScaleType = Enum.ScaleType.Stretch
		local pencil = Instance.new("ImageButton")
		pencil.Name, pencil.Image, pencil.BackgroundTransparency, pencil.AnchorPoint = key .. "Pencil", Art.pencil, 1, Vector2.new(0.5, 0.5)
		pencil.Size, pencil.ScaleType, pencil.ZIndex, pencil.Parent = UDim2.fromOffset(150, 52), Enum.ScaleType.Fit, 3, sheet
		local tag = image(sheet, key .. "Tag", Art.tag, 810, y - 8, 120, 88)
		local value = words(tag, "Value", "", 0, 0, 120, 88, 44)
		value.Size, value.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
		-- Phones: the ends' words were about 10 points.
		PaperUI.phone(words(sheet, key .. "Min", minLabel, 285, y + 74, 120, 36, 30), { Size = UDim2.fromOffset(160, 50), TextSize = 42 })
		local max = words(sheet, key .. "Max", maxLabel, 690, y + 74, 100, 36, 30)
		max.TextXAlignment = Enum.TextXAlignment.Right
		PaperUI.phone(max, { Position = UDim2.fromOffset(630, y + 74), Size = UDim2.fromOffset(160, 50), TextSize = 42 })
		local left, width = 280 + 40, 510 - 80 -- the pencil's travel inside the ruler's ends
		refresh[key] = function()
			local t = (settings[key] - lo) / (hi - lo)
			pencil.Position = UDim2.fromOffset(left + width * t, y + 36)
			value.Text = show(settings[key])
		end
		local dragging = false -- the mouse button or the finger (phones) that holds the pencil
		local function follow(screenX)
			local a, s = ruler.AbsolutePosition.X, ruler.AbsoluteSize.X
			local t = math.clamp((screenX - a - s * 40 / 510) / (s * width / 510), 0, 1)
			settings[key] = math.clamp(math.round((lo + t * (hi - lo)) / step) * step, lo, hi)
			refresh[key]()
			Options.apply(settings) -- heard and felt while dragging; saved on release
		end
		local function grab(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = input; follow(input.Position.X) end
		end
		pencil.InputBegan:Connect(grab)
		ruler.InputBegan:Connect(grab)
		Input.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging) then follow(input.Position.X) end
		end)
		Input.InputEnded:Connect(function(input)
			if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.UserInputType == Enum.UserInputType.MouseButton1) then dragging = false; save() end
		end)
	end
	slider("sensitivity", "Mouse sensitivity", 345, 0.2, 3, 0.1, function(v) return string.format("%.1f", v) end, "0.2", "3.0")
	slider("sound", "Sound", 580, 0, 1, 0.05, function(v) return string.format("%d%%", math.round(v * 100)) end, "0%", "100%")
	slider("music", "Music", 805, 0, 1, 0.05, function(v) return string.format("%d%%", math.round(v * 100)) end, "0%", "100%")

	-- Crosshair colour: dot stickers, a check on the chosen one, and a live preview card.
	words(sheet, "ColorLabel", "Crosshair color", 1020, 262, 520, 60, 52)
	local check = image(sheet, "Check", Art.check, 0, 0, 60, 60)
	check.ZIndex = 3 -- above the stickers
	for i, color in COLORS do
		local dot = Instance.new("ImageButton")
		dot.Name, dot.Image, dot.BackgroundTransparency = "Sticker" .. color, Art.sticker[color], 1
		dot.Position, dot.Size, dot.Parent = UDim2.fromOffset(1010 + (i - 1) * 88, 345), UDim2.fromOffset(82, 82), sheet
		dot.Activated:Connect(function() settings.crosshairColor = color; refresh.color(); save() end)
	end
	local card = image(sheet, "CrosshairCard", Art.crosshairCard, 1570, 270, 180, 180, 2)
	local ring = Instance.new("Frame")
	ring.Name, ring.AnchorPoint, ring.Position, ring.BackgroundTransparency = "Ring", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), 1
	Instance.new("UICorner", ring).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke", ring)
	stroke.Thickness = 4
	ring.Parent = card
	local dotPreview = Instance.new("Frame")
	dotPreview.AnchorPoint, dotPreview.Position, dotPreview.BackgroundColor3 = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), SWATCH.green
	Instance.new("UICorner", dotPreview).CornerRadius = UDim.new(0.5, 0)
	dotPreview.Parent = card
	refresh.color = function()
		local i = table.find(COLORS, settings.crosshairColor) or 2
		check.Position = UDim2.fromOffset(1010 + (i - 1) * 88 + 41, 386)
		stroke.Color = SWATCH[settings.crosshairColor] or SWATCH.blue
	end

	-- A row of paper tabs; the chosen one is bright.
	local function tabs(key, label, y, options, names, onImage, x)
		x = x or 1020
		words(sheet, key .. "Label", label, x, y - 72, x == 1020 and 600 or 400, 60, 52)
		local row = {}
		for i, option in options do
			local tab = PaperUI.button(sheet, key .. tostring(option), Art.tabOff, names[i], x + (i - 1) * 200, y, 185, 82, 0,
				function() settings[key] = option; refresh[key](); save() end, 40)
			PaperUI.phone(tab, { Size = UDim2.fromOffset(185, 104) }) -- taller for a finger on a phone
			PaperUI.phone(tab.Label, { TextSize = 48 })
			row[option] = tab
		end
		refresh[key] = function()
			for option, tab in row do tab.Image = settings[key] == option and onImage or Art.tabOff end
		end
	end
	tabs("crosshairSize", "Crosshair size", 540, SIZES, SIZES, Art.tabOn)
	tabs("reducedShake", "Reduced shake", 720, { true, false }, { "On", "Off" }, Art.tabGreen)
	tabs("matchTips", "Match tips", 720, { true, false }, { "On", "Off" }, Art.tabGreen, 1440) -- the tips in your first matches
	tabs("quality", "Graphics quality", 895, { "Low", "Medium", "High" }, { "Low", "Medium", "High" }, Art.tabOn)
	refresh.crosshairSize = (function(base)
		return function()
			base()
			local s = ({ Small = 0.75, Medium = 1, Large = 1.4 })[settings.crosshairSize] or 1
			ring.Size, dotPreview.Size = UDim2.fromOffset(60 * s, 60 * s), UDim2.fromOffset(16 * s, 16 * s)
		end
	end)(refresh.crosshairSize)

	local back = PaperUI.button(sheet, "Back", Art.tabGreen, "Back", 1640, 930, 200, 90, 3, api.back, 48)
	PaperUI.phone(back, { Position = UDim2.fromOffset(1730, 960), Size = UDim2.fromOffset(260, 120) })
	PaperUI.phone(back.Label, { TextSize = 60 })

	local self = { frame = cover }
	function self.update(_, profile)
		-- Take the saved settings only when the screen opens, so a background refresh can't undo a drag.
		if not profile or not profile.settings or (settings and cover.Visible) then return end
		settings = profile.settings
		settings.crosshairColor = settings.crosshairColor or "blue"
		settings.crosshairSize = settings.crosshairSize or "Medium"
		settings.matchTips = settings.matchTips ~= false
		for _, fn in refresh do fn() end
	end
	return self
end

return SettingsScreen
