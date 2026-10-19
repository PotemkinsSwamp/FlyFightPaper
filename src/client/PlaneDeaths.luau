-- How planes die on screen (Alan, 2026-10-13). No explosions: a plane that smashes into something crumples into a
-- paper ball that drops to the floor; a plane shot down tears apart, its pieces and shreds drifting down like ripped
-- paper. Client only: the server marks the plane DESTROYED with a DeathCause. The pilot's own crash starts here the
-- moment its client feels the hit (FlightController), before the server's word arrives.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")

local PAPER = Color3.fromRGB(246, 243, 230)
local WHITE = Color3.fromRGB(252, 252, 255)
local BALL_STUDS = 5
local CRUMPLE_SECONDS = 0.3
local BALL_GRAVITY = 150
local BALL_RADIUS = BALL_STUDS * 0.54 -- the turned cubes' corners reach about this far from the middle
local BALL_BOUNCES = { 35, 20, 10 } -- studs/s up off the floor on each of the 3 bounces, then it rolls
local BALL_ROLL_SLOWING = 8 -- studs/s lost each second while rolling
local SHRED_FALL = { 7, 11 } -- studs/s, torn pieces drift down this fast
local LIFE = 3.6 -- seconds before a death's pieces fade away (a new plane comes at 4)
local PREDICT_TIMEOUT = 1.2 -- the server didn't agree it was a crash: show the plane again

local Deaths = {}
local started = {} -- model -> os.clock() its death began
local predicted = {} -- model -> true while only the pilot's client has seen the crash
local remains = {} -- model -> where its paper ball / shreds are now (the camera follows this until respawn)
local bits = {}
local folder, shreds
local solid = RaycastParams.new()
solid.FilterType, solid.RespectCanCollide = Enum.RaycastFilterType.Include, true

local function hide(model, hidden)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = hidden and 1 or 0
		elseif d:IsA("BillboardGui") then d.Enabled = not hidden end
	end
end

-- Loose copies of the plane's visible parts (wings, body, nose, tail, weapons) to animate.
local function pieces(model)
	local out = {}
	local look = model:FindFirstChild("Appearance")
	for _, part in ipairs(look and look:GetDescendants() or {}) do
		if part:IsA("BasePart") then
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				if not (child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
			end
			copy.Anchored, copy.CanCollide, copy.CanQuery, copy.CanTouch = true, false, false, false
			copy.LocalTransparencyModifier = 0
			copy.Parent = folder
			table.insert(out, copy)
		end
	end
	return out
end

local function centreOf(model)
	local body = model:FindFirstChild("Root")
	return body and body.CFrame or model:GetPivot()
end

-- The plane's own paper colours (red, blue, or both for a split free-for-all plane), then white for its stripes.
local function palette(model)
	local colours, seen = {}, { [WHITE:ToHex()] = true }
	local look = model:FindFirstChild("Appearance")
	for _, part in ipairs(look and look:GetChildren() or {}) do
		local key = part:IsA("BasePart") and part:GetAttribute("Region") == "paper" and part.Color:ToHex()
		if key and not seen[key] then seen[key] = true; table.insert(colours, part.Color) end
	end
	if #colours == 0 then colours[1] = PAPER end
	table.insert(colours, WHITE)
	return colours
end

local function add(model, bit)
	bit.model, bit.born = model, os.clock()
	table.insert(bits, bit)
	return bit
end

-- The paper ball: a few paper-white cubes turned every which way read as a crumpled sheet (like the Creator Store's
-- free paper balls, whose geometry is just that).
local function ball(model, at, velocity)
	-- A crash into the floor leaves the plane's middle closer to it than the ball's size: start on top of it.
	local floor = workspace:Raycast(at.Position + Vector3.yAxis * BALL_RADIUS, Vector3.yAxis * -BALL_RADIUS * 2, solid)
	if floor then at = CFrame.new(floor.Position + Vector3.yAxis * BALL_RADIUS) end
	local cubes = {}
	local colours = palette(model)
	for i = 1, 7 do
		local cube = Instance.new("Part")
		-- Mostly the plane's colour(s); every third cube is a white stripe.
		local colour = i % 3 == 0 and WHITE or colours[i % (#colours - 1) + 1]
		cube.Color, cube.Material = colour, Enum.Material.SmoothPlastic
		cube.Anchored, cube.CanCollide, cube.CanQuery, cube.CanTouch = true, false, false, false
		cube.Parent = folder
		cubes[i] = { part = cube, turn = CFrame.Angles(math.random() * 6.3, math.random() * 6.3, math.random() * 6.3) }
	end
	return add(model, { part = cubes[1].part, cubes = cubes, kind = "ball", cf = at, velocity = velocity, bounces = 0,
		spin = Vector3.new(math.random() * 6 - 3, math.random() * 6 - 3, 0) })
end

-- Smashed: the pieces fold in on the plane's centre while a paper ball grows there, then the ball drops and bounces.
local function crumple(model, parts)
	local at = centreOf(model)
	for _, part in ipairs(parts) do
		add(model, { part = part, kind = "fold", from = part.CFrame, size = part.Size, to = at.Position })
	end
	ball(model, CFrame.new(at.Position), -at.LookVector * 10 + Vector3.new(0, 45, 0)) -- pops up out of the crash
end

-- Shot down: the pieces fly apart a little, then flutter down, tumbling and swaying, in a shower of slow shreds.
local function tear(model, parts)
	local at = centreOf(model)
	for _, part in ipairs(parts) do
		local out = part.Position - at.Position
		out = out.Magnitude > 0.1 and out.Unit or Vector3.new(math.random() - 0.5, 0.5, math.random() - 0.5).Unit
		add(model, { part = part, kind = "flutter", cf = part.CFrame, velocity = out * (8 + math.random() * 8) + at.LookVector * 15 + Vector3.new(0, 6, 0),
			fall = SHRED_FALL[1] + math.random() * (SHRED_FALL[2] - SHRED_FALL[1]), phase = math.random() * 6,
			spin = Vector3.new(math.random() * 4 - 2, math.random() * 4 - 2, math.random() * 4 - 2) })
	end
	shreds.WorldPosition = at.Position
	local colours = palette(model)
	for _, colour in ipairs(colours) do
		shreds.Shreds.Color = ColorSequence.new(colour)
		shreds.Shreds:Emit(math.ceil((Root:GetAttribute("Quality") == "Low" and 35 or 70) / #colours))
	end
end

local function play(model, cause)
	started[model] = os.clock()
	hide(model, true)
	local parts = pieces(model)
	if cause == "weapon" then tear(model, parts) else crumple(model, parts) end
end

-- The pilot's client felt a crash: crumple now; the server's DESTROYED follows a moment later.
function Deaths.predict(model)
	if started[model] then return end
	play(model, "collision")
	predicted[model] = true
end
function Deaths.dying(model)
	return started[model] ~= nil
end
function Deaths.remains(model)
	return started[model] and remains[model]
end

local function settle(bit, position)
	local hit = workspace:Raycast(bit.cf.Position, position - bit.cf.Position, solid)
	if not hit then return position, false end
	return hit.Position + hit.Normal * bit.part.Size.Y / 2, hit.Normal
end

-- Moves the ball's whole sphere (not just its middle, which let half the ball sink into the floor before it
-- bounced back up: Alan saw it clip and jitter). On contact the rest of the move slides along the surface.
local function roll(from, delta)
	local normal
	for _ = 1, 2 do
		local hit = delta.Magnitude > 1e-3 and workspace:Spherecast(from, BALL_RADIUS, delta, solid)
		if not hit then return from + delta, normal end
		from += delta.Unit * math.max(0, hit.Distance - 0.02)
		normal = hit.Normal
		local rest = delta * (1 - hit.Distance / delta.Magnitude)
		delta = rest - rest:Dot(normal) * normal
	end
	return from, normal
end

local function step(dt)
	local now = os.clock()
	local balls, sums = {}, {}
	for i = #bits, 1, -1 do
		local bit = bits[i]
		local age = now - bit.born
		local part = bit.part
		if age > LIFE or not part.Parent then
			part:Destroy()
			for _, cube in ipairs(bit.cubes or {}) do cube.part:Destroy() end
			table.remove(bits, i)
			continue
		end
		if bit.kind == "fold" then
			local t = math.min(1, age / CRUMPLE_SECONDS)
			part.Size = bit.size * (1 - 0.8 * t)
			part.CFrame = (bit.from - bit.from.Position + bit.from.Position:Lerp(bit.to, t)) * CFrame.Angles(t * 2, t * 3, t)
			part.LocalTransparencyModifier = t >= 1 and 1 or 0
		elseif bit.kind == "ball" then
			local size = Vector3.one * BALL_STUDS * 0.62 * math.min(1, 0.1 + age / CRUMPLE_SECONDS)
			if age > CRUMPLE_SECONDS * 0.5 and not bit.resting then
				-- Falls, bounces 3 times off the floor (walls just knock it back), then rolls to a stop.
				bit.velocity -= Vector3.new(0, BALL_GRAVITY * dt, 0)
				local position, normal = roll(bit.cf.Position, bit.velocity * dt)
				local turn = CFrame.Angles(bit.spin.X * dt, bit.spin.Y * dt, 0)
				local rolling = false
				if normal then
					local into = bit.velocity:Dot(normal)
					local along = bit.velocity - into * normal
					if normal.Y < 0.6 then
						if into < 0 then bit.velocity = along * 0.8 - into * normal * 0.5 end
					elseif into < 0 and bit.bounces < #BALL_BOUNCES then
						bit.bounces += 1
						bit.velocity = along * 0.85 + normal * BALL_BOUNCES[bit.bounces]
					elseif bit.bounces >= #BALL_BOUNCES then
						-- Rolling: stay on the floor, slow down, and turn like a rolling ball.
						local speed = math.max(0, along.Magnitude - BALL_ROLL_SLOWING * dt)
						bit.velocity = speed > 0.3 and along.Unit * speed or Vector3.zero
						rolling = speed > 0.3
						if rolling then turn = CFrame.fromAxisAngle(normal:Cross(along).Unit, speed / BALL_RADIUS * dt) end
						if not rolling then bit.resting = true end
					end
				end
				local rotation = bit.cf - bit.cf.Position
				bit.cf = CFrame.new(position) * (rolling and turn * rotation or rotation * turn)
			end
			local fade = math.clamp((age - (LIFE - 0.6)) / 0.6, 0, 1)
			for _, cube in ipairs(bit.cubes) do
				cube.part.Size, cube.part.CFrame, cube.part.LocalTransparencyModifier = size, bit.cf * cube.turn, fade
			end
		elseif bit.kind == "flutter" and not bit.resting then
			-- Paper falls slowly and swings from side to side as it goes.
			local sway = Vector3.new(math.sin(age * 2.3 + bit.phase), 0, math.cos(age * 1.7 + bit.phase)) * 6
			bit.velocity = bit.velocity:Lerp(sway - Vector3.new(0, bit.fall, 0), 1 - math.exp(-2.5 * dt))
			local position, normal = settle(bit, bit.cf.Position + bit.velocity * dt)
			-- Torn paper never lands: a piece about to touch something fades away in a moment (Alan's note 1).
			if normal then bit.resting, bit.vanish = true, age end
			bit.cf = CFrame.new(position) * (bit.cf - bit.cf.Position) * CFrame.Angles(bit.spin.X * dt, bit.spin.Y * dt, bit.spin.Z * dt)
			part.CFrame = bit.cf
		end
		if bit.kind == "flutter" then
			part.LocalTransparencyModifier = math.clamp(math.max((age - (LIFE - 1)) / 1, bit.vanish and (age - bit.vanish) / 0.3 or 0), 0, 1)
		end
		-- The ball alone marks a crash; a tear is the middle of its falling pieces.
		if bit.kind == "ball" then balls[bit.model] = bit.cf.Position
		elseif bit.kind == "flutter" then
			local sum = sums[bit.model] or { Vector3.zero, 0 }
			sums[bit.model] = { sum[1] + bit.cf.Position, sum[2] + 1 }
		end
	end
	for model, sum in pairs(sums) do remains[model] = sum[1] / sum[2] end
	for model, at in pairs(balls) do remains[model] = at end
	for model in pairs(predicted) do
		if model:GetAttribute("State") == "DESTROYED" then predicted[model] = nil
		elseif now - started[model] > PREDICT_TIMEOUT then
			predicted[model], started[model], remains[model] = nil, nil, nil
			hide(model, false)
			for _, bit in ipairs(bits) do if bit.model == model then bit.part:Destroy() end end
		end
	end
end

function Deaths.start()
	folder = Instance.new("Folder")
	folder.Name = "PlaneDeaths"
	folder.Parent = workspace
	solid.FilterDescendantsInstances = { workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom") }
	-- Slow shreds: bigger, longer-lived scraps than a hit's, drifting down instead of dropping.
	shreds = Instance.new("Attachment")
	shreds.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Name, e.Texture, e.Color, e.Rate, e.LightInfluence = "Shreds", "rbxasset://textures/particles/SquareParticle.png", ColorSequence.new(PAPER), 0, 1
	e.Lifetime, e.Speed, e.SpreadAngle = NumberRange.new(2.5, 3.5), NumberRange.new(10, 26), Vector2.new(180, 180)
	e.Acceleration, e.Drag, e.Squash = Vector3.new(0, -8, 0), 1.6, NumberSequence.new(0.5)
	e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-260, 260)
	e.Size = NumberSequence.new(0.7)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Parent = shreds
	local planes = workspace:WaitForChild("Planes")
	local function watch(model)
		model:GetAttributeChangedSignal("State"):Connect(function()
			-- The Range's cut-outs tear their own way (RangeTargets).
			if model:GetAttribute("State") == "DESTROYED" and not started[model] and not model:GetAttribute("RangeTarget") then play(model, model:GetAttribute("DeathCause")) end
		end)
		model.AncestryChanged:Connect(function()
			if not model.Parent then started[model], predicted[model], remains[model] = nil, nil, nil end
		end)
	end
	planes.ChildAdded:Connect(watch)
	for _, model in ipairs(planes:GetChildren()) do watch(model) end
	RunService.RenderStepped:Connect(step)
end

return Deaths
