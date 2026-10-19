-- The Range's targets (docs/plan/TUTORIAL-PLAN.md): a practice target plane marked `RangeTarget` (its colour) is drawn
-- as a flat paper-plane cut-out on a stick instead of a plane. It tears more as its Health drops; when folded it rips
-- in two, the halves fall away and the stick sinks out of sight (the server brings a fresh one up after the wait).
-- ponytail: stand-in shapes for the feel check; the real cut-outs (2D pieces from the concepts) replace them.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Targets = {}

local COLORS = { red = Color3.fromRGB(214, 78, 72), blue = Color3.fromRGB(70, 128, 214) }
local CUT = Vector3.new(0.4, 9, 24) -- thin toward you, tall, long along its flight
local STICK = 240 -- long enough to reach below the ledge in front of it
local TEARS = 4 -- tear steps before it splits

local function piece(name, size, color)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color, part.Material = name, size, color, Enum.Material.SmoothPlastic
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	return part
end

function Targets.start()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RangeTargets", workspace
	local live = {}
	local function hide(model)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
			if part:IsA("BillboardGui") then part.Enabled = false end
		end
	end
	local function add(model)
		local color = COLORS[model:GetAttribute("RangeTarget")]
		if not color or live[model] then return end
		hide(model)
		model.DescendantAdded:Connect(function() hide(model) end)
		local t = {
			cut = piece("CutOut", CUT, color),
			tear = piece("Tear", Vector3.new(CUT.X + 0.1, 0.1, 0.8), Color3.fromRGB(30, 25, 25)),
			stick = piece("Stick", Vector3.new(STICK, 1.2, 1.2), Color3.fromRGB(205, 165, 110)),
		}
		t.stick.Shape = Enum.PartType.Cylinder
		for _, part in t do part.Parent = folder end
		t.tear.Transparency = 1
		live[model] = t
	end
	local function tearDown(model, t)
		live[model] = nil
		-- Two halves fall away spinning; the stick sinks below the ledge.
		for _, side in { -1, 1 } do
			local half = t.cut:Clone()
			half.Size = Vector3.new(CUT.X, CUT.Y, CUT.Z / 2)
			half.CFrame = t.cut.CFrame * CFrame.new(0, 0, side * CUT.Z / 4)
			half.Anchored, half.Parent = false, folder
			half.AssemblyLinearVelocity = t.cut.CFrame:VectorToWorldSpace(Vector3.new(0, 12, side * 14))
			half.AssemblyAngularVelocity = Vector3.new(side * 3, 0, side * 2)
			Debris:AddItem(half, 3)
		end
		t.cut:Destroy()
		t.tear:Destroy()
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
	RunService.RenderStepped:Connect(function()
		for model, t in live do
			local body = model.Parent and model:FindFirstChild("Root")
			if not body or model:GetAttribute("State") == "DESTROYED" then
				tearDown(model, t)
				continue
			end
			t.cut.CFrame = body.CFrame
			local share = 1 - (model:GetAttribute("Health") or 0) / math.max(1, model:GetAttribute("MaxHealth") or 1)
			local step = math.min(TEARS, math.floor(share * (TEARS + 1)))
			local length = CUT.Y * step / TEARS
			t.tear.Transparency = step > 0 and 0 or 1
			t.tear.Size = Vector3.new(CUT.X + 0.1, math.max(0.1, length), 0.8)
			t.tear.CFrame = body.CFrame * CFrame.new(0, CUT.Y / 2 - length / 2, 0) -- the rip runs down from the top edge
			t.stick.CFrame = CFrame.new(body.Position - Vector3.new(0, CUT.Y / 2 + STICK / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
end

return Targets
