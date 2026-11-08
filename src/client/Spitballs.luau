-- Spitballs stuck on planes (Alan 2026-11-07): every plane shows a wet paper blob on itself for each one (the server's
-- `Spitballs` attribute, FlightService:spit), and your own screen gets a splatter per spitball that slides off as they
-- fall off or a fan blows them away. No HUD counter: you see them on the plane and the screen.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Spitballs = {}

local WET = Color3.fromRGB(226, 226, 214)
-- Where the blobs land on a plane, as a share of its half-width (X) and half-length (Z, + is the tail), in order.
local ON_PLANE = { Vector2.new(0, -0.15), Vector2.new(-0.5, 0.25), Vector2.new(0.5, 0.25), Vector2.new(-0.2, 0.45), Vector2.new(0.3, -0.05) }
-- Where the splatters land on the screen (centre of each), kept clear of the aim in the middle.
local ON_SCREEN = { Vector2.new(0.2, 0.25), Vector2.new(0.8, 0.7), Vector2.new(0.75, 0.2), Vector2.new(0.25, 0.75), Vector2.new(0.5, 0.88) }

-- Drop a blob straight down onto the plane's visible paper at a fixed spot, welded so it rides along.
local function blob(model, index)
	local root = model:FindFirstChild("Root")
	if not root then return end
	local size = model:GetExtentsSize()
	local spot = ON_PLANE[index]
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local visible = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 and part ~= root and not part.Name:match("^Spitball") then table.insert(visible, part) end
	end
	params.FilterDescendantsInstances = visible
	local above = root.CFrame * Vector3.new(spot.X * size.X / 2, size.Y, spot.Y * size.Z / 2)
	local hit = workspace:Raycast(above, -root.CFrame.UpVector * size.Y * 2, params)
	local part = Instance.new("Part")
	part.Name = "Spitball" .. index
	part.Shape = Enum.PartType.Ball
	local width = math.max(0.5, size.X * 0.06)
	part.Size = Vector3.new(width, width * 0.55, width) -- a squashed ball: a wet lump, not a marble
	part.Color = WET
	part.Material = Enum.Material.SmoothPlastic
	part.Reflectance = 0.15
	part.CanCollide, part.CanQuery, part.CanTouch, part.Massless, part.CastShadow = false, false, false, true, false
	part.CFrame = CFrame.fromMatrix(hit and hit.Position or above - root.CFrame.UpVector * size.Y, root.CFrame.RightVector, root.CFrame.UpVector)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = part, hit and hit.Instance or root
	weld.Parent = part
	part.Parent = model
	return part
end

-- One splatter: a big wet blot with a few drops round it, popping in quickly.
local function splat(gui, index)
	local at = ON_SCREEN[index]
	local frame = Instance.new("Frame")
	frame.Name = "Splat" .. index
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(at.X, at.Y)
	frame.Size = UDim2.fromScale(0, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	local random = Random.new(index * 7)
	local function drop(x, y, scale)
		local d = Instance.new("Frame")
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.Position = UDim2.fromScale(x, y)
		d.Size = UDim2.fromScale(scale, scale)
		d.BackgroundColor3 = WET
		d.BackgroundTransparency = 0.3
		d.BorderSizePixel = 0
		Instance.new("UICorner", d).CornerRadius = UDim.new(0.5, 0)
		d.Parent = frame
	end
	drop(0.5, 0.5, 0.75)
	for _ = 1, 5 do
		local angle, reach = random:NextNumber(0, 2 * math.pi), random:NextNumber(0.4, 0.62)
		drop(0.5 + math.cos(angle) * reach, 0.5 + math.sin(angle) * reach, random:NextNumber(0.1, 0.22))
	end
	Instance.new("UIAspectRatioConstraint", frame)
	TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.16, 0.16) }):Play()
	return frame
end

-- Gone: a splatter slides down and fades; a blob just goes.
local function slideOff(frame)
	frame.Name = "Leaving"
	for _, d in ipairs(frame:GetChildren()) do
		if d:IsA("Frame") then TweenService:Create(d, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play() end
	end
	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = frame.Position + UDim2.fromScale(0, 0.15) }):Play()
	task.delay(0.5, frame.Destroy, frame)
end

function Spitballs.start(getPlane)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpitballSplatter"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < 0.1 then return end
		clock = 0
		local planes = workspace:FindFirstChild("Planes")
		for _, model in ipairs(planes and planes:GetChildren() or {}) do
			local want = model:GetAttribute("State") == "FLYING" and model:GetAttribute("Spitballs") or 0
			for index = 1, #ON_PLANE do
				local part = model:FindFirstChild("Spitball" .. index)
				if index <= want and not part then blob(model, index)
				elseif index > want and part then part:Destroy() end
			end
		end
		local mine = getPlane()
		local want = mine and mine:GetAttribute("State") == "FLYING" and mine:GetAttribute("Spitballs") or 0
		for index = 1, #ON_SCREEN do
			local frame = gui:FindFirstChild("Splat" .. index)
			if index <= want and not frame then splat(gui, index)
			elseif index > want and frame then slideOff(frame) end
		end
	end)
end

return Spitballs
