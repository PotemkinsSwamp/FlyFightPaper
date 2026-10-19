-- The Range's targets (docs/plan/TUTORIAL-PLAN.md): a practice target plane marked `RangeTarget` (its colour) is drawn
-- as a flat painted paper-plane cut-out on a stick instead of a plane (pieces in UIAssets.range). It faces the stage
-- front, tilts with its swoop, and turns over on its stick when it changes direction. Each hit tears it more (pictures
-- 0-3); when folded it rips in two, the halves fall away in a burst of scraps and the stick sinks out of sight (the
-- server brings a fresh one up after the wait).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets).range
local Course = require(Root.Shared.TrainingCourse)
local Targets = {}

local LENGTH = 26 -- studs nose to tail; the picture's own shape gives the height
local PX = { full = Vector2.new(1024, 535), back = Vector2.new(687, 717), front = Vector2.new(745, 364), scrap = Vector2.new(448, 366) }
local STICK = 240 -- long enough to reach below the row in front of it
local TURN = 0.3 -- seconds to turn over on the stick
local RISE = 0.6 -- seconds a fresh one takes to rise into place
local TEARS = 4 -- pictures 0..3, then it splits

local function image(color, key)
	return Art["target" .. (color == "blue" and "Blue" or "Red") .. key]
end
-- A thin card showing `art` the right way round from the front and mirrored from behind, like real paper.
local function card(art, px)
	local size = px / PX.full.X * LENGTH
	local part = Instance.new("Part")
	part.Name, part.Size, part.Transparency = "Card", Vector3.new(size.X, size.Y, 0.2), 1
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.LightInfluence, gui.MaxDistance, gui.Parent = face, 0, 5000, part
		local label = Instance.new("ImageLabel")
		label.Name, label.Size, label.BackgroundTransparency, label.Image, label.Parent = "Art", UDim2.fromScale(1, 1), 1, art, gui
		if face == Enum.NormalId.Front then
			label.ImageRectOffset, label.ImageRectSize = Vector2.new(px.X, 0), Vector2.new(-px.X, px.Y)
		end
	end
	return part
end
local function setArt(part, art)
	for _, gui in part:GetChildren() do
		if gui:IsA("SurfaceGui") then gui.Art.Image = art end
	end
end

function Targets.start()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RangeTargets", workspace
	local stage = Course.RANGE.origin.Rotation -- cards face the front of the stage
	task.spawn(function()
		local list = {}
		for _, color in { "Red", "Blue" } do
			for _, key in { "0", "1", "2", "3", "HalfBack", "HalfFront" } do table.insert(list, Art["target" .. color .. key]) end
		end
		table.insert(list, Art.scrap)
		ContentProvider:PreloadAsync(list)
	end)
	local live = {}
	local function hide(model)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
			if part:IsA("BillboardGui") then part.Enabled = false end
		end
	end
	local function add(model)
		local color = model:GetAttribute("RangeTarget")
		if not color or live[model] then return end
		hide(model)
		model.DescendantAdded:Connect(function() hide(model) end)
		local t = { color = color, step = 0, turn = 0, tilt = 0, born = os.clock(), card = card(image(color, "0"), PX.full) }
		t.stick = Instance.new("Part")
		t.stick.Name, t.stick.Shape, t.stick.Size = "Stick", Enum.PartType.Cylinder, Vector3.new(STICK, 1.2, 1.2)
		t.stick.Color, t.stick.Material = Color3.fromRGB(205, 165, 110), Enum.Material.Wood
		t.stick.Anchored, t.stick.CanCollide, t.stick.CanQuery, t.stick.CanTouch, t.stick.CastShadow = true, false, false, false, false
		t.card.Parent, t.stick.Parent = folder, folder
		live[model] = t
	end
	local function tearDown(model, t)
		live[model] = nil
		-- Two halves fly apart and fall, scraps burst out, the stick sinks below the row.
		for _, half in { { key = "HalfBack", px = PX.back, at = Vector3.new(-0.19, 0.12, 0), push = -1 }, { key = "HalfFront", px = PX.front, at = Vector3.new(0.21, -0.05, 0), push = 1 } } do
			local piece = card(image(t.color, half.key), half.px)
			piece.CFrame = t.card.CFrame * CFrame.new(half.at * LENGTH)
			piece.Anchored, piece.Parent = false, folder
			piece.AssemblyLinearVelocity = t.card.CFrame:VectorToWorldSpace(Vector3.new(half.push * 16, 14, 0))
			piece.AssemblyAngularVelocity = t.card.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -half.push * 4))
			Debris:AddItem(piece, 3)
		end
		local burst = card(Art.scrap, PX.scrap)
		burst.CFrame, burst.Size, burst.Parent = t.card.CFrame, burst.Size * 0.5, folder
		local grow = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(burst, grow, { Size = burst.Size * 3.2 }):Play()
		for _, gui in burst:GetChildren() do
			if gui:IsA("SurfaceGui") then TweenService:Create(gui.Art, grow, { ImageTransparency = 1 }):Play() end
		end
		Debris:AddItem(burst, 0.5)
		t.card:Destroy()
		TweenService:Create(t.stick, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = t.stick.CFrame - Vector3.new(0, STICK, 0) }):Play()
		Debris:AddItem(t.stick, 1.1)
	end
	local planes = workspace:WaitForChild("Planes")
	local function watch(model)
		add(model)
		model:GetAttributeChangedSignal("RangeTarget"):Connect(function() add(model) end)
	end
	planes.ChildAdded:Connect(watch)
	for _, model in planes:GetChildren() do watch(model) end
	RunService.RenderStepped:Connect(function(dt)
		for model, t in live do
			local body = model.Parent and model:FindFirstChild("Root")
			if not body or model:GetAttribute("State") == "DESTROYED" then
				tearDown(model, t)
				continue
			end
			-- Its heading on the stage: across (turns it over) and up/down (tilts it).
			local look = stage:VectorToObjectSpace(body.CFrame.LookVector)
			local facing = look.X >= 0 and 0 or math.pi
			t.turn += math.clamp(facing - t.turn, -math.pi * dt / TURN, math.pi * dt / TURN)
			local tilt = math.clamp(math.atan2(look.Y, math.abs(look.X)), -0.6, 0.6)
			t.tilt += (tilt - t.tilt) * math.min(1, dt * 6)
			local share = 1 - (model:GetAttribute("Health") or 0) / math.max(1, model:GetAttribute("MaxHealth") or 1)
			local step = math.min(TEARS - 1, math.floor(share * TEARS))
			if step ~= t.step then
				t.step = step
				setArt(t.card, image(t.color, tostring(step)))
			end
			local rise = math.max(0, 1 - (os.clock() - t.born) / RISE)
			local at = body.Position - Vector3.new(0, rise * rise * 60, 0)
			-- Tilting about the turned card's own axis lifts the nose whichever way it faces.
			t.card.CFrame = CFrame.new(at) * stage * CFrame.Angles(0, t.turn, 0) * CFrame.Angles(0, 0, t.tilt)
			t.stick.CFrame = CFrame.new(at - Vector3.new(0, t.card.Size.Y * 0.3 + STICK / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
end

return Targets
