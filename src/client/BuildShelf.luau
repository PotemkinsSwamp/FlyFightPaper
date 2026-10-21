-- The cubby shelf on the Hangar's first screen (Alan's pick 2026-10-20: assets/references/ui-concepts/
-- hangar-shelf-screen.png). Each saved build stands in its own cubby as its real 3D plane, with its name on masking
-- tape; the picked one has a yellow crayon outline. A cubby's plane is a still ViewportFrame, rebuilt only when that
-- build changes, so the shelf costs no more than a row of pictures. Tapping a cubby calls pick(i).
local HttpService = game:GetService("HttpService")
local Root = game.ReplicatedStorage.FlyFightPaper
local Aircraft = require(Root.Shared.Aircraft)
local Builder = require(Root.Shared.BuilderModel)
local Assets = require(Root.Shared.UIAssets)
local Art = Assets.hangarShelf
local PaperUI = require(script.Parent.PaperUI)
local BuildShelf = {}

-- Sheet pixels: a cubby's width (its inside is square), the front piece's height (the shelf's top board seen from a
-- little above, then the frame), how much of that is the top board, the side boards, and where the top board starts.
local CUBBY, FRONT_H, TOP_FACE, END_W, TOP = 345, 414, 69, 60, 655

-- The plane seen from above and behind, nose away and a little to the side, filling the cubby's opening.
local function draw(view, catalog, loadout)
	view:ClearAllChildren()
	local model = Instance.new("Model")
	model.Parent = view
	Aircraft.build(model, Builder.new(catalog, loadout).candidate, catalog, true)
	local camera = Instance.new("Camera")
	camera.FieldOfView, camera.Parent, view.CurrentCamera = 40, view, camera
	local box, size = model:GetBoundingBox()
	local distance = math.max(size.X, size.Z) / 2 * 1.1 / math.sin(math.rad(20))
	camera.CFrame = CFrame.new(box.Position) * CFrame.Angles(0, 0.5, 0) * CFrame.Angles(-0.6, 0, 0) * CFrame.new(0, 0, distance)
end

function BuildShelf.new(parent, catalog, pick)
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundTransparency, frame.Size, frame.Parent = "Shelf", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), parent
	-- The group's tab on the top rail: My builds, or Range in the Range (Special joins when special planes exist).
	local tab = PaperUI.image(frame, "GroupTab", Art.shelfTab, 110, TOP - 58, 320, 92) -- standing on the top board
	tab.ScaleType, tab.ImageColor3 = Enum.ScaleType.Stretch, Color3.fromRGB(255, 215, 60)
	local group = PaperUI.words(tab, "Label", "", 0, 4, 320, 84, 46)
	group.TextXAlignment = Enum.TextXAlignment.Center
	local outline = PaperUI.image(frame, "Picked", Art.outline, 0, 0, CUBBY + 20, FRONT_H - TOP_FACE + 20)
	-- The crayon band sits in the outer 48 px of the trimmed 480 px piece.
	outline.ScaleType, outline.SliceCenter, outline.ZIndex = Enum.ScaleType.Slice, Rect.new(48, 48, 432, 432), 3
	local cubbies = {}
	local self = { frame = frame }

	-- ponytail: one row of up to five cubbies (every group has five builds); the arrow and sideways scroll come
	-- with the first group that has more.
	function self.set(builds, picked, groupName)
		group.Text = groupName
		local left = (PaperUI.W - #builds * CUBBY - 2 * END_W) / 2
		if #cubbies == 0 then
			PaperUI.image(frame, "EndLeft", Art.endLeft, left, TOP, END_W, FRONT_H).ScaleType = Enum.ScaleType.Stretch
			PaperUI.image(frame, "EndRight", Art.endRight, left + END_W + #builds * CUBBY, TOP, END_W, FRONT_H).ScaleType = Enum.ScaleType.Stretch
		end
		for i, build in builds do
			local cubby = cubbies[i]
			if not cubby then
				local x = left + END_W + (i - 1) * CUBBY
				PaperUI.image(frame, "Back" .. i, Art.cubbyBack, x, TOP + TOP_FACE, CUBBY, CUBBY).ScaleType = Enum.ScaleType.Stretch
				local view = Instance.new("ViewportFrame")
				view.Name, view.BackgroundTransparency = "Plane" .. i, 1
				view.Position, view.Size = UDim2.fromOffset(x + 28, TOP + 108), UDim2.fromOffset(CUBBY - 56, 200)
				view.Ambient, view.LightColor, view.LightDirection = Color3.fromRGB(140, 140, 150), Color3.fromRGB(255, 250, 235), Vector3.new(-0.6, -1, -0.4)
				view.Parent = frame
				PaperUI.image(frame, "Front" .. i, Art.cubbyFront, x, TOP, CUBBY, FRONT_H).ScaleType = Enum.ScaleType.Stretch
				PaperUI.image(frame, "Tape" .. i, Assets.ingame.tapeLabel, x + 24, TOP + FRONT_H - 84, CUBBY - 48, 66).ScaleType = Enum.ScaleType.Stretch
				local name = PaperUI.words(frame, "Name" .. i, "", x + 40, TOP + FRONT_H - 80, CUBBY - 80, 58, 34)
				name.TextXAlignment, name.TextScaled = Enum.TextXAlignment.Center, true -- long names shrink to fit
				local cap = Instance.new("UITextSizeConstraint")
				cap.MaxTextSize, cap.Parent = 34, name
				local hit = Instance.new("TextButton")
				hit.Name, hit.Text, hit.BackgroundTransparency, hit.ZIndex = "Pick" .. i, "", 1, 4
				hit.Position, hit.Size, hit.Parent = UDim2.fromOffset(x, TOP), UDim2.fromOffset(CUBBY, FRONT_H), frame
				hit.Activated:Connect(function() pick(i) end)
				cubby = { x = x, view = view, name = name }
				cubbies[i] = cubby
			end
			cubby.name.Text = build.name
			local key = HttpService:JSONEncode(build.loadout)
			if key ~= cubby.key then
				cubby.key = key
				draw(cubby.view, catalog, build.loadout)
			end
			if i == picked then outline.Position = UDim2.fromOffset(cubby.x + CUBBY / 2, TOP + (TOP_FACE + FRONT_H) / 2) end
		end
	end
	return self
end

return BuildShelf
