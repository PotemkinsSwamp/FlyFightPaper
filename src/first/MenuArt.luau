-- Menu pictures drawn as 3D pictures (Alan 2026-10-27): a label on a menu screen showing a file of the "3d" group
-- (first/UISheets, tools/ui_sheets.py) keeps its place, size, tilt and clicks, but its picture is drawn on a flat card
-- inside its own little ViewportFrame, which Roblox downloads GPU-compressed (~4-7x smaller than a menu picture).
-- Only screens never on show while flying (frame rate there doesn't matter); the card is never in the world.
-- first/LoadingFirst calls draw() after pointing a label at its sheet.
local Sheets = require(script.Parent:WaitForChild("UISheets"))
local FLAT = Sheets["3d"] or {}
local MenuArt = {}

-- (tools/ui_sheets.py has the same list)
local MENU_GUIS = { LoadingClassroom = true, KeepDrawn = true, MenuBoard = true, SettingsScreen = true, HangarScreen = true,
	ShopScreen = true, WaitScreen = true, TrainingBoard = true, RoundEnd = true }
local FOV = 20
local watched = setmetatable({}, { __mode = "k" }) -- labels whose colour/fade the card follows (copies need their own)

local function card(id, size, offset, rect)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency = "MenuArt3D", 1
	view.Ambient, view.LightColor = Color3.new(1, 1, 1), Color3.new(0, 0, 0) -- flat light: the picture's own colours
	view.AnchorPoint, view.Position, view.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1)
	local w, h = rect.X / 100, rect.Y / 100
	local part = Instance.new("Part")
	part.Anchored, part.Transparency, part.Size = true, 1, Vector3.new(w, h, 0.05)
	-- The piece's spot on its file (checked in Studio 2026-10-27: same cut and way up as ImageRectOffset/Size).
	local texture = Instance.new("Texture")
	texture.Face, texture.Texture = Enum.NormalId.Front, id
	texture.StudsPerTileU, texture.StudsPerTileV = size[1] / 100, size[2] / 100
	texture.OffsetStudsU, texture.OffsetStudsV = offset.X / 100, offset.Y / 100
	texture.Parent, part.Parent = part, view
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, -(h / 2) / math.tan(math.rad(FOV / 2))), Vector3.zero)
	camera.Parent, view.CurrentCamera = view, camera
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.Parent = rect.X / rect.Y, view
	return view, texture
end

-- A whole 3d-group file drawn full size, for preloading (a phone fetches a 3D picture only as sharp as it's drawn).
-- Returns nil for a file outside the group.
function MenuArt.preload(id, parent)
	local size = FLAT[id]
	if not size then return nil end
	local view, texture = card(id, size, Vector2.zero, Vector2.new(size[1], size[2]))
	view.AnchorPoint, view.Position, view.Size = Vector2.zero, UDim2.fromScale(0, 0), UDim2.fromOffset(size[1], size[2])
	view.ImageTransparency, view.Parent = 0.99, parent
	return texture
end

-- What PreloadAsync should fetch for this label: its card's texture once drawn the 3D way.
function MenuArt.fetchable(label)
	local view = label:FindFirstChild("MenuArt3D")
	return view and view:FindFirstChildOfClass("Part"):FindFirstChildOfClass("Texture") or label
end

function MenuArt.draw(label)
	local id = label.Image
	local gui = label:FindFirstAncestorOfClass("ScreenGui")
	local size = FLAT[id]
	if not size or not (gui and MENU_GUIS[gui.Name]) or label.ScaleType == Enum.ScaleType.Slice or label.ScaleType == Enum.ScaleType.Tile then
		return
	end
	local old = label:FindFirstChild("MenuArt3D")
	if old then old:Destroy() end
	local rect, offset = label.ImageRectSize, label.ImageRectOffset
	if rect.X == 0 then rect, offset = Vector2.new(size[1], size[2]), Vector2.zero end
	local view = card(id, size, offset, rect)
	if label.ScaleType == Enum.ScaleType.Stretch then
		-- Stretched to the label's shape: the card and its picture widen (or narrow) to the frame's shape.
		view:FindFirstChildOfClass("UIAspectRatioConstraint"):Destroy()
		local part = view:FindFirstChildOfClass("Part")
		local texture = part:FindFirstChildOfClass("Texture")
		local function stretch()
			local box = view.AbsoluteSize
			if box.Y < 1 then return end
			local wide = (rect.Y / 100) * box.X / box.Y / (rect.X / 100)
			part.Size = Vector3.new(rect.X / 100 * wide, rect.Y / 100, 0.05)
			texture.StudsPerTileU, texture.OffsetStudsU = size[1] / 100 * wide, offset.X / 100 * wide
		end
		view:GetPropertyChangedSignal("AbsoluteSize"):Connect(stretch)
		stretch()
	end
	-- Same layer as the label and first among its children, so its words and pieces stay on top (a lower ZIndex
	-- hides a ViewportFrame altogether, 2026-10-27). A child on a lower layer than the label is lifted to it, or the
	-- card covers it (Alan's phone run 2026-10-28: the Hangar shelf's "Range" tab showed as a blank strip).
	view.ZIndex, view.ImageColor3, view.ImageTransparency = label.ZIndex, label.ImageColor3, label.ImageTransparency
	local others = label:GetChildren()
	view.Parent = label
	for _, child in others do
		if child:IsA("GuiObject") then child.ZIndex = math.max(child.ZIndex, label.ZIndex); child.Parent = nil; child.Parent = label end
	end
	label:SetAttribute("Art3D", id)
	label.Image = "" -- (first/LoadingFirst's fit leaves a label with Art3D and no picture alone)
	if not watched[label] then
		watched[label] = true
		for _, property in { "ImageRectOffset", "ImageRectSize", "ScaleType" } do -- a new cut or fit: draw again
			label:GetPropertyChangedSignal(property):Connect(function()
				local art = label:GetAttribute("Art3D")
				if art and label.Image == "" then label.Image = art end -- (first/LoadingFirst's fit redraws it)
			end)
		end
		for _, property in { "ImageColor3", "ImageTransparency", "ZIndex" } do
			label:GetPropertyChangedSignal(property):Connect(function()
				local current = label:FindFirstChild("MenuArt3D")
				if current then current[property] = label[property] end
				if current and property == "ZIndex" then
					for _, child in label:GetChildren() do if child:IsA("GuiObject") then child.ZIndex = math.max(child.ZIndex, label.ZIndex) end end
				end
			end)
		end
		label.ChildAdded:Connect(function(child) -- words added after the card (BuildShelf's tab)
			if child:IsA("GuiObject") and child.Name ~= "MenuArt3D" and label:FindFirstChild("MenuArt3D") then child.ZIndex = math.max(child.ZIndex, label.ZIndex) end
		end)
	end
end

-- A label pointed at a new picture by its screen's code: back to an ordinary label until draw() looks at it again.
function MenuArt.forget(label)
	local view = label:FindFirstChild("MenuArt3D")
	if view then view:Destroy() end
	label:SetAttribute("Art3D", nil)
end

return MenuArt
