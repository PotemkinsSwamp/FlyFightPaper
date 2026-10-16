-- Chase camera for mouse-aim: looks along the aim, sits behind the plane, never leaves the room.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local FlightState = require(script.Parent.FlightController).state
local Deaths = require(script.Parent.PlaneDeaths)
local Camera = {}

-- Feel tuning. Position follows a bit slower than rotation so turns read as motion.
local DISTANCE, HEIGHT, LOOK_AHEAD = 24, 6, 60
local POSITION_RESPONSE, ROTATION_RESPONSE = 9, 16
local BASE_FOV, MAX_EXTRA_FOV, FOV_RESPONSE = 72, 12, 4
local SHAKE_ON_HIT, SHAKE_ON_NEAR_MISS, SHAKE_DECAY = 0.6, 0.3, 3

local function smooth(rate, dt)
	return 1 - math.exp(-rate * dt)
end

local function speedLines()
	local part = Instance.new("Part")
	part.Name = "SpeedLines"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency, part.Size = 1, Vector3.new(36, 24, 1)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape, emitter.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Speed, emitter.Lifetime = NumberRange.new(140, 180), NumberRange.new(0.18, 0.25)
	emitter.Size = NumberSequence.new(0.06)
	emitter.Squash = NumberSequence.new(4)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
	emitter.LightEmission, emitter.Rate = 0.4, 0
	emitter.Parent = part
	return part, emitter
end

function Camera.start(getPlane)
	local position, look, up
	local previousHealth, previousLife, shake, fov = 0, nil, 0, BASE_FOV
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom") }
	params.RespectCanCollide = true
	local lines, emitter = speedLines()
	-- A smaller shake when an enemy shot passes close by.
	game:GetService("Players").LocalPlayer:GetAttributeChangedSignal("NearMissAt"):Connect(function()
		shake = math.max(shake, SHAKE_ON_NEAR_MISS)
	end)
	RunService:BindToRenderStep("PlaneCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local plane = getPlane()
		local body = plane and plane.Parent and plane:FindFirstChild("Root")
		local camera = workspace.CurrentCamera
		if not body then lines.Parent = nil; return end
		camera.CameraType = Enum.CameraType.Scriptable
		-- The camera rolls with the aim, so it stays behind the pilot through loops and inverted flight.
		-- After a death it keeps its last heading and follows the paper ball or the falling shreds until respawn.
		local remains = Deaths.remains(plane)
		local flat = look and Vector3.new(look.X, 0, look.Z)
		local aim = remains and flat and flat.Magnitude > 0.1 and (flat.Unit - Vector3.yAxis * 0.4).Unit or FlightState.aim or body.CFrame.LookVector
		local aimUp = not remains and FlightState.aimUp or Vector3.yAxis
		local focus = remains or body.Position + aimUp * 2
		if not position then position, look, up = focus - aim * DISTANCE + aimUp * HEIGHT, aim, aimUp end
		up = up:Lerp(aimUp, smooth(ROTATION_RESPONSE, dt)).Unit
		local desired = focus - aim * DISTANCE + up * HEIGHT
		if (desired - position).Magnitude > 150 then position, look = desired, aim end
		position = position:Lerp(desired, smooth(POSITION_RESPONSE, dt))
		look = look:Lerp(aim, smooth(ROTATION_RESPONSE, dt)).Unit
		-- Pull in when a wall or building sits between the plane and the camera.
		local offset = position - focus
		local hit = offset.Magnitude > 0.1 and workspace:Spherecast(focus, 1.5, offset, params)
		local final = hit and focus + offset.Unit * math.max(2, hit.Distance - 0.5) or position
		local health = plane:GetAttribute("Health") or 0
		if previousLife == plane:GetAttribute("Life") and health < previousHealth then shake = SHAKE_ON_HIT end
		previousLife, previousHealth = plane:GetAttribute("Life"), health
		shake = math.max(0, shake - SHAKE_DECAY * dt)
		local jitter = CFrame.identity
		if shake > 0 and not Root:GetAttribute("ReducedShake") then
			local t = os.clock() * 40
			jitter = CFrame.Angles(math.noise(t, 1) * shake * 0.05, math.noise(t, 2) * shake * 0.05, 0)
		end
		camera.CFrame = CFrame.lookAt(final, focus + look * LOOK_AHEAD, up) * jitter
		-- Wider view and speed lines when faster than cruise (boost, speed power-ups, dives).
		local cruise = math.max(1, plane:GetAttribute("Speed") or 1)
		local overspeed = plane:GetAttribute("State") == "FLYING" and math.clamp(body.AssemblyLinearVelocity.Magnitude / cruise - 1, 0, 0.4) / 0.4 or 0
		fov += (BASE_FOV + MAX_EXTRA_FOV * overspeed - fov) * smooth(FOV_RESPONSE, dt)
		camera.FieldOfView = fov
		emitter.Rate = overspeed > 0.15 and 60 * overspeed or 0
		lines.CFrame = camera.CFrame * CFrame.new(0, 0, -30)
		lines.Parent = camera
	end)
end
return Camera
