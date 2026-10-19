-- Mouse-aim flight: the mouse moves a free aim direction and the shared autopilot flies the nose toward it.
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.FlightRules)
local Deaths = require(script.Parent.PlaneDeaths)
local Gameplay = require(Root.Generated.Gameplay)
local Config = Gameplay.flight
local Controller = {}
-- Read by the camera and HUD. `aimOverride` lets dev tools fly the plane without a mouse.
Controller.state = { aim = nil, aimUp = nil, aimOverride = nil }
local solid = OverlapParams.new()
solid.FilterType, solid.RespectCanCollide = Enum.RaycastFilterType.Include, true
solid.FilterDescendantsInstances = { workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom") }
local single = RaycastParams.new()
single.FilterType = Enum.RaycastFilterType.Include

function Controller.start(plane)
	local state = Controller.state
	local body = plane:WaitForChild("Root")
	local drive = body:WaitForChild("ForwardVelocity")
	local orientation = body:WaitForChild("NoseOrientation")
	-- The aim is a full rotation, not yaw/pitch angles, so it can go over the top: loops, rolls, inverted.
	local heading, bank, aimFrame, lastSteer = body.CFrame.LookVector, 0, CFrame.identity, 0
	local wasFlying, locked, focused, boostSent, glide, momentum = false, false, true, false, nil, nil
	-- A scrape's wobble: when it started and which way the plane rolls.
	local wobbleAt, wobbleSide = -math.huge, 0
	local function setAim(direction)
		local look = aimFrame.LookVector
		local angle = math.acos(math.clamp(look:Dot(direction), -1, 1))
		if angle < 1e-4 then return end
		local axis = look:Cross(direction)
		aimFrame = CFrame.fromAxisAngle(axis.Magnitude > 1e-4 and axis.Unit or aimFrame.UpVector, angle) * aimFrame
	end
	-- A scrape knocks the nose and the pilot's aim away from the wall, so they have to steer back, and rolls the
	-- touching wing up into a wobble (Alan 2026-10-18). Once per wobble, however long the contact lasts.
	local function scrape(normal, now)
		if now - wobbleAt < Config.scrape_wobble_seconds * 0.6 or normal.Magnitude < .5 then return end
		local axis = heading:Cross(normal)
		if axis.Magnitude > 1e-3 then
			local knock = CFrame.fromAxisAngle(axis.Unit, math.rad(Config.scrape_knock_deg))
			heading, aimFrame = knock:VectorToWorldSpace(heading), knock * aimFrame
		end
		wobbleAt, wobbleSide = now, orientation.CFrame.RightVector:Dot(normal) >= 0 and 1 or -1
	end
	local function lockMouse(lock)
		if lock == locked then return end
		locked = lock
		Input.MouseBehavior = lock and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
		Input.MouseIconEnabled = not lock
	end
	-- The default camera scripts reset the mouse on right-click; re-lock after them every frame.
	RunService:BindToRenderStep("FlightMouseLock", Enum.RenderPriority.Camera.Value + 2, function()
		if locked then Input.MouseBehavior = Enum.MouseBehavior.LockCenter end
	end)
	local focusLost = Input.WindowFocusReleased:Connect(function() focused = false end)
	local focusGained = Input.WindowFocused:Connect(function() focused = true end)
	local connection = RunService.PreSimulation:Connect(function(dt)
		if not plane.Parent or plane:GetAttribute("State") ~= "FLYING" then
			wasFlying, state.aim, state.aimUp = false, nil, nil
			lockMouse(false)
			return
		end
		if not wasFlying then
			heading, bank, wasFlying = body.CFrame.LookVector, 0, true
			aimFrame = CFrame.lookAt(Vector3.zero, heading)
		end
		if Deaths.dying(plane) then drive.VectorVelocity = Vector3.zero; return end
		local blocked = not focused or Input:GetFocusedTextBox() ~= nil or Root:GetAttribute("OverlayOpen") == true
		lockMouse(not blocked)
		if not blocked then
			-- Mouse moves turn the aim around its own axes, so "up" on screen is always up for the pilot.
			local delta = Input:GetMouseDelta() * math.rad(Config.aim_degrees_per_pixel) * (Root:GetAttribute("Sensitivity") or 1)
			if delta.Magnitude > 0 then aimFrame = aimFrame * CFrame.Angles(-delta.Y, -delta.X, 0); lastSteer = os.clock() end
		end
		if state.aimOverride then setAim(state.aimOverride(body)); lastSteer = os.clock() end
		if os.clock() - lastSteer > Config.aim_level_delay_s then aimFrame = Rules.levelAim(aimFrame, dt) end
		aimFrame = aimFrame:Orthonormalize()
		state.aim, state.aimUp = aimFrame.LookVector, aimFrame.UpVector
		local boost = not blocked and Input:IsKeyDown(Enum.KeyCode.LeftShift)
		if boost ~= boostSent then boostSent = boost; Root.FlightAction:FireServer("boost", boost) end
		local before = heading
		heading, bank, orientation.CFrame = Rules.autopilot(heading, bank, state.aim, plane:GetAttribute("YawRate"), plane:GetAttribute("PitchRate"), dt, state.aimUp)
		local now = workspace:GetServerTimeNow()
		local cruise = plane:GetAttribute("Speed") * (plane:GetAttribute("BoostSpeedFactor") or 1)
		local speed = cruise * Rules.turnSpeedFactor(before, heading, dt, plane:GetAttribute("TurnRate"))
		-- Boosting flies along the nose like having Lift, even when Lift is empty (Alan 2026-10-14).
		local lift = plane:GetAttribute("Boosting") and math.max(plane:GetAttribute("Lift"), 1) or plane:GetAttribute("Lift")
		-- Momentum is kept against the plain cruise: a hard turn slows the plane only while it turns.
		-- Running out of Lift mid-dive carries the dive's speed into the glide.
		glide = lift <= 0 and Rules.glide(glide or momentum, heading, cruise, dt) or nil
		momentum = lift > 0 and Rules.dive(momentum, heading, cruise, dt) or nil
		local desired = Rules.velocity(heading, speed * (momentum or cruise) / cruise, lift, plane:GetAttribute("Updraft") or 0, glide, cruise)
		-- Touching the room: never sink into it; slide along it. The server decides scrape damage or a crash.
		local part, normal = Rules.contact(plane, heading, solid, single)
		if part then
			-- A real crash (the server's own test): crumple now instead of sliding until the server's word arrives.
			local into = math.max(0, -drive.VectorVelocity:Dot(normal), -heading:Dot(normal) * speed)
			-- Flight School planes (Gentle) never crash: the server only bounces them off, so the client mustn't crumple.
			if not plane:GetAttribute("Gentle") and (Rules.crashes(into, math.max(drive.VectorVelocity.Magnitude, speed)) or part.Name == "Floor" and lift <= 0) then
				Deaths.predict(plane)
			else
				scrape(normal, now)
			end
			drive.VectorVelocity -= normal * math.min(0, drive.VectorVelocity:Dot(normal))
			desired -= normal * math.min(0, desired:Dot(normal))
			desired += normal * Config.graze_slide_push_studs_s
		elseif now < (plane:GetAttribute("DeflectUntil") or 0) then
			-- Graze: drop the push into the surface and slide along it. The server's word is the only one for the
			-- train, which the pilot's own wall check doesn't see.
			local normal = plane:GetAttribute("CollisionNormal") or Vector3.zero
			scrape(normal, now)
			desired -= normal * math.min(0, desired:Dot(normal))
			desired += normal * Config.graze_slide_push_studs_s
		end
		if now < (plane:GetAttribute("KnockUntil") or 0) then desired += plane:GetAttribute("Knock") end -- a duct fan's shove
		local wobbling = now - wobbleAt
		if wobbling < Config.scrape_wobble_seconds then
			-- The roll swings back and forth and dies away over the wobble's length.
			local fade = 1 - wobbling / Config.scrape_wobble_seconds
			orientation.CFrame *= CFrame.Angles(0, 0, -wobbleSide * math.rad(Config.scrape_wobble_deg) * fade * fade * math.cos(2 * math.pi * Config.scrape_wobble_hz * wobbling))
		end
		drive.VectorVelocity = drive.VectorVelocity:Lerp(desired, 1 - math.exp(-Config.velocity_response * dt))
	end)
	return function()
		connection:Disconnect()
		RunService:UnbindFromRenderStep("FlightMouseLock")
		focusLost:Disconnect()
		focusGained:Disconnect()
		lockMouse(false)
		state.aim, state.aimUp = nil, nil
	end
end
return Controller
