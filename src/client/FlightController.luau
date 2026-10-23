-- Mouse-aim flight: the mouse moves a free aim direction and the shared autopilot flies the nose toward it.
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.FlightRules)
local Deaths = require(script.Parent.PlaneDeaths)
local Gameplay = require(Root.Generated.Gameplay)
local Config = Gameplay.flight
local Course = require(Root.Shared.TrainingCourse)
local Controller = {}
-- Read by the camera and HUD. `aimOverride` lets dev tools fly the plane without a mouse.
Controller.state = { aim = nil, aimUp = nil, aimOverride = nil }
local plateCast = RaycastParams.new() -- the Range's picker plates and target cut-outs (what the crosshair can be on)
plateCast.FilterType = Enum.RaycastFilterType.Include
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
	local wasFlying, locked, focused, boostSent, glide, momentum, lockedAt = false, false, true, false, nil, nil, 0
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
		state.scrapedAt = os.clock() -- Match Tips' wall tip
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
		if lock then lockedAt = os.clock() end
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
		-- Held still (a lesson's read pause, the winners' moment): the aim stays on the nose and the mouse is free to
		-- click, so when it lets go the plane flies on where it points (Alan 2026-10-19: the aim drifted off while frozen).
		if plane:GetAttribute("Held") then
			heading, bank = body.CFrame.LookVector, 0
			aimFrame = CFrame.lookAt(Vector3.zero, heading)
			state.aim, state.aimUp = aimFrame.LookVector, aimFrame.UpVector
			lockMouse(false)
			return
		end
		local blocked = not focused or Input:GetFocusedTextBox() ~= nil or Root:GetAttribute("OverlayOpen") == true
		lockMouse(not blocked)
		if not blocked then
			-- Mouse moves turn the aim around its own axes, so "up" on screen is always up for the pilot.
			local delta = Input:GetMouseDelta() * math.rad(Config.aim_degrees_per_pixel) * (Root:GetAttribute("Sensitivity") or 1)
			-- Locking pulls the free cursor (just used on LAUNCH or the lesson's Go, right of centre) to the middle of
			-- the screen, which reads as one big mouse move: the "jolt to the left" (Alan 2026-10-19). Skip that moment.
			if os.clock() - lockedAt < 0.1 then delta = Vector2.zero end
			if delta.Magnitude > 0 then aimFrame = aimFrame * CFrame.Angles(-delta.Y, -delta.X, 0); lastSteer = os.clock() end
		end
		if state.aimOverride then setAim(state.aimOverride(body)); lastSteer = os.clock() end
		local pinned = plane:GetAttribute("Pinned")
		if not pinned and os.clock() - lastSteer > Config.aim_level_delay_s then aimFrame = Rules.levelAim(aimFrame, dt) end
		aimFrame = aimFrame:Orthonormalize()
		-- The Range: the aim is the crosshair's line from the still camera; it stays on the screen and never rolls
		-- (Alan 2026-10-19), and the plane points at what the crosshair is on, so shots land on it.
		local steer
		if pinned then
			local stage = Course.RANGE.origin.Rotation
			local pitch, yaw = stage:ToObjectSpace(aimFrame):ToOrientation()
			aimFrame = stage * CFrame.fromOrientation(math.clamp(pitch, -Course.RANGE.down, Course.RANGE.up), math.clamp(yaw, -Course.RANGE.yaw, Course.RANGE.yaw), 0)
			local eye = workspace.CurrentCamera.CFrame.Position
			local stageModel = workspace:FindFirstChild("RangeStage")
			local cards = workspace:FindFirstChild("RangeTargets")
			plateCast.FilterDescendantsInstances = { stageModel, cards }
			if not stageModel then plateCast.FilterDescendantsInstances = { cards } end
			local hit = workspace:Raycast(eye, aimFrame.LookVector * 1000, plateCast)
			local target = state.target and state.target.Parent and state.target
			-- Nothing under the crosshair: as far as the lead ring of the target the aim help picked (you're leading it, so
			-- the nose lands on the ring and it turns red), else that target, else the far row.
			local reach = hit and hit.Distance or state.leadPoint and (state.leadPoint - eye).Magnitude or target and (target.Position - eye).Magnitude or 640
			state.aimPoint = eye + aimFrame.LookVector * reach
			steer = (state.aimPoint - body.Position).Unit
		else
			state.aimPoint = nil
			-- The aim circle is drawn from the camera, which sits above and behind the plane; flying the nose along the
			-- same direction left the nose dot short of the circle for good (Alan 2026-10-21). So steer at the point on the
			-- circle's line at the dot's range (the lead's, else 300: FlightHUD), and the dot settles on the circle.
			local eye = workspace.CurrentCamera.CFrame.Position
			local range = state.leadPoint and (state.leadPoint - body.Position).Magnitude or 300
			local toward = eye + aimFrame.LookVector * ((body.Position - eye):Dot(aimFrame.LookVector) + range) - body.Position
			if toward.Magnitude > 1 then steer = toward.Unit end
		end
		state.aim, state.aimUp = aimFrame.LookVector, aimFrame.UpVector
		local boost = not blocked and Input:IsKeyDown(Enum.KeyCode.LeftShift)
		if boost ~= boostSent then boostSent = boost; Root.FlightAction:FireServer("boost", boost) end
		local before = heading
		heading, bank, orientation.CFrame = Rules.autopilot(heading, bank, steer or state.aim, plane:GetAttribute("YawRate"), plane:GetAttribute("PitchRate"), dt, state.aimUp)
		if pinned then bank, orientation.CFrame = 0, CFrame.lookAt(Vector3.zero, heading) end -- wings stay level in the Range
		local now = workspace:GetServerTimeNow()
		-- SlowMo: the Aiming lesson's slow motion (the server allows any speed below cruise).
		local cruise = plane:GetAttribute("Speed") * (plane:GetAttribute("BoostSpeedFactor") or 1) * (plane:GetAttribute("SlowMo") or 1)
		local speed = cruise * Rules.turnSpeedFactor(before, heading, dt, plane:GetAttribute("TurnRate"))
		-- Boosting flies along the nose like having Lift, even when Lift is empty (Alan 2026-10-14).
		local lift = plane:GetAttribute("Boosting") and math.max(plane:GetAttribute("Lift"), 1) or plane:GetAttribute("Lift")
		-- Momentum is kept against the plain cruise: a hard turn slows the plane only while it turns.
		-- Running out of Lift mid-dive carries the dive's speed into the glide.
		glide = lift <= 0 and Rules.glide(glide or momentum, heading, cruise, dt) or nil
		momentum = lift > 0 and Rules.dive(momentum, heading, cruise, dt) or nil
		local desired = Rules.velocity(heading, speed * (momentum or cruise) / cruise, lift, plane:GetAttribute("Updraft") or 0, glide, cruise)
		-- The Range: the plane hangs on its spot and only turns to aim.
		local pin = plane:GetAttribute("Pinned")
		if pin then desired = (pin - body.Position) * 4 end
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
