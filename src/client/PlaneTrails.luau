-- Trails drawn on each player's own screen only (skins plan, "Trails: how it works"): the server marks a plane with a
-- Trail attribute; each row of config/trails.json is drawn here, out of the tail, while the plane flies. Soft smoke and
-- sparkle dust are Roblox particles (flat cards that face you are what particles are, and Roblox ships both pictures);
-- stars, flakes and bolts are real small parts moved here every frame (no physics, nothing on the server).
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Config = require(Root:WaitForChild("Generated"):WaitForChild("Trails"))
local PlaneTrails = {}

local PICTURE = { soft = "rbxasset://textures/particles/smoke_main.dds", spark = "rbxasset://textures/particles/sparkles_main.dds" }
local MATERIAL = { foil = Enum.Material.Foil, glow = Enum.Material.Neon, matte = Enum.Material.Fabric }
-- How each look takes the room's light as a particle: smoke is lit by the room and by lightning, a glint is its own light.
local LIT = { soft = { emission = 0.3, influence = 0.8, clear = 0.2 }, glow = { emission = 1, influence = 0, clear = 0 } }
local FAR = CFrame.new(0, 1e5, 0) -- where resting and blinked-off parts wait (moving a part is cheaper than hiding it)
local STEP = 0.08 -- ponytail: a part is resized only when its size has changed by this share (resizing is the costly call); 0 if steps ever show
local rng = Random.new()
local folder
local worn = {} -- plane -> { id, holder, rows = { { spec, emitters | model, owed } }, last (the tail a frame ago), g }
local live, spare, shapes = {}, {}, {} -- flying parts; resting parts by model; model -> { part, unit, long }
local movers, frames = {}, {}

-- The share of its full size a piece has at share k of its life: it grows out of the tail, then shrinks (or swells).
function PlaneTrails.sizeAt(spec, k)
	local grow = Config.grow_in
	return math.min(k / grow, 1) * (1 + (spec.shrink - 1) * math.max(0, (k - grow) / (1 - grow)) ^ 1.5)
end
-- How much bigger a trail is at this speed against the build's own.
function PlaneTrails.growth(speed, normal)
	return 1 + (Config.fast_growth - 1) * math.clamp((speed / normal - 1) / (Config.fast_at - 1), 0, 1)
end
-- A particle's size over its life. A twinkling one flickers: every other point is small.
function PlaneTrails.sizes(spec, g)
	local mid, range = (spec.size[1] + spec.size[2]) / 2 * g, (spec.size[2] - spec.size[1]) / 2 * g
	local points = {}
	for i = 0, 19 do
		local k = i / 19
		local share = PlaneTrails.sizeAt(spec, k) * ((spec.twinkle and i % 2 == 1) and 0.35 or 1)
		points[i + 1] = NumberSequenceKeypoint.new(k, mid * share, range * share)
	end
	return NumberSequence.new(points)
end
local function color(c) return Color3.fromRGB(c[1], c[2], c[3]) end
-- A rainbow piece's colour over its life: through the list `rainbow` times, ending where it began.
function PlaneTrails.rainbow(spec)
	local runs = math.max(1, math.floor(tonumber(spec.rainbow) or 1))
	local count = #spec.colors * runs
	assert(count <= 19, "a rainbow has at most 19 colour steps") -- Roblox takes 20 points
	local points = {}
	for i = 0, count do points[i + 1] = ColorSequenceKeypoint.new(i / count, color(spec.colors[i % #spec.colors + 1])) end
	return ColorSequence.new(points)
end

local function emitter(spec, tint, holder)
	local lit = LIT[spec.look]
	local e = Instance.new("ParticleEmitter")
	e.Enabled, e.Texture, e.Color = false, PICTURE[spec.model], tint
	e.Lifetime, e.Speed, e.SpreadAngle = NumberRange.new(spec.life[1], spec.life[2]), NumberRange.new(0, spec.drift or 0), Vector2.new(180, 180)
	e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-(spec.spin or 0), spec.spin or 0)
	e.Acceleration, e.LightEmission, e.LightInfluence = Vector3.new(0, spec.rise or 0, 0), lit.emission, lit.influence
	local gone = spec.vanish or 0
	e.Transparency = gone > 0 and NumberSequence.new({ NumberSequenceKeypoint.new(0, lit.clear), NumberSequenceKeypoint.new(1 - gone, lit.clear), NumberSequenceKeypoint.new(1, 1) })
		or NumberSequence.new(lit.clear)
	e.Size = PlaneTrails.sizes(spec, 1)
	e.Parent = holder
	return e
end

local function dress(plane, id)
	local old = worn[plane]
	if old then task.delay(Config.life + 0.5, old.holder.Destroy, old.holder) end -- what is in the air fades out first
	worn[plane] = nil
	local trail = Config.trails[id]
	if not trail then return end
	local holder = Instance.new("Attachment")
	holder.Name, holder.Parent = "Trail", workspace.Terrain
	local rows = {}
	for i, spec in trail.pieces do
		local row = { spec = spec, owed = 0 }
		if PICTURE[spec.model] then
			row.emitters = {}
			if spec.rainbow then row.emitters[1] = emitter(spec, PlaneTrails.rainbow(spec), holder)
			else for j, c in spec.colors do row.emitters[j] = emitter(spec, ColorSequence.new(color(c)), holder) end end
		end
		rows[i] = row
	end
	worn[plane] = { id = id, holder = holder, rows = rows, g = 1 }
end

local function take(spec)
	local shape = shapes[spec.model]
	if not shape then return end -- its model has not loaded (or is not uploaded yet)
	local part = table.remove(spare[spec.model])
	if not part then
		part = shape.part:Clone()
		if spec.light then
			local lamp = Instance.new("PointLight")
			lamp.Brightness, lamp.Range, lamp.Shadows, lamp.Color, lamp.Parent = spec.light / 1500, 18, false, color(spec.colors[1]), part
		end
		part.CFrame, part.Parent = FAR, folder
	end
	return part, shape
end

-- A turn that lays a part's long side along dir.
local function along(dir, long)
	local look = CFrame.lookAlong(Vector3.zero, dir)
	return long == "X" and look * CFrame.Angles(0, math.pi / 2, 0) or long == "Y" and look * CFrame.Angles(math.pi / 2, 0, 0) or look
end

local function emit(w, root, tail, dt)
	local shift = tail - w.last
	local far = shift.Magnitude
	if far > 60 then return end -- put somewhere new (a respawn), not flown there
	local normal = math.max(1, root.Parent:GetAttribute("Speed") or 105)
	local g = PlaneTrails.growth(far / math.max(dt, 1e-3), normal)
	local right, up, nose = root.CFrame.RightVector, root.CFrame.UpVector, root.CFrame.LookVector
	local resize = math.abs(g - w.g) > 0.04
	if resize then w.g = g end
	local now = os.clock()
	for _, row in w.rows do
		local spec = row.spec
		if resize and row.emitters then for _, e in row.emitters do e.Size = PlaneTrails.sizes(spec, g) end end
		row.owed += spec.rate * far / normal -- as many a stud at any speed, so the spacing stays even
		while row.owed >= 1 do
			row.owed -= 1
			local a, reach = rng:NextNumber(0, 2 * math.pi), spec.spread * math.sqrt(rng:NextNumber())
			local at = w.last + shift * rng:NextNumber() + (right * math.cos(a) + up * math.sin(a)) * reach
			if row.emitters then
				w.holder.WorldPosition = at
				row.emitters[rng:NextInteger(1, #row.emitters)]:Emit(1)
			else
				local part, shape = take(spec)
				if not part then break end
				part.Material, part.Color = MATERIAL[spec.look], color(spec.colors[rng:NextInteger(1, #spec.colors)])
				local q = { part = part, model = spec.model, spec = spec, unit = shape.unit, born = now, life = rng:NextNumber(spec.life[1], spec.life[2]), at = at,
					vel = rng:NextUnitVector() * rng:NextNumber(0, spec.drift or 0), shown = 0,
					size = (spec.size[1] + (spec.size[2] - spec.size[1]) * rng:NextNumber() ^ 2) * g } -- more small ones than big
				if spec.align then
					local dir = (nose + rng:NextUnitVector() * 0.45).Unit
					q.turn = CFrame.fromAxisAngle(dir, rng:NextNumber(0, 2 * math.pi)) * along(dir, shape.long)
				else
					q.axis, q.start = rng:NextUnitVector(), rng:NextNumber(0, 2 * math.pi)
					q.spin = math.rad(spec.spin or 0) * rng:NextNumber(0.5, 1) * (rng:NextInteger(0, 1) * 2 - 1)
				end
				table.insert(live, q)
			end
		end
	end
end

local function step(dt)
	local planes = workspace:FindFirstChild("Planes")
	if not planes then return end
	for plane, w in worn do if not plane.Parent then dress(plane, nil) end end
	for _, plane in planes:GetChildren() do
		local id = PlaneTrails.devTrail or plane:GetAttribute("Trail")
		id = Config.trails[id] and id or nil
		local w = worn[plane]
		if (w and w.id) ~= id then dress(plane, id); w = worn[plane] end
		local root = w and plane:FindFirstChild("Root")
		if root and plane:GetAttribute("State") == "FLYING" then
			local tail = root.CFrame * Vector3.new(0, 0, root.Size.Z / 2)
			if w.last then emit(w, root, tail, dt) end
			w.last = tail
		elseif w then w.last = nil end
	end
	local now, n = os.clock(), 0
	table.clear(movers); table.clear(frames)
	for i = #live, 1, -1 do
		local q = live[i]
		local age = now - q.born
		local k = age / q.life
		n += 1; movers[n] = q.part
		if k >= 1 then
			frames[n] = FAR
			table.insert(spare[q.model], q.part)
			live[i] = live[#live]; live[#live] = nil
		elseif q.spec.flash and not (k < 0.3 or (k > 0.42 and k < 0.7)) then frames[n] = FAR -- lightning: on, off, on, gone
		else
			local size = math.max(q.size * PlaneTrails.sizeAt(q.spec, k), 0.02)
			if math.abs(size - q.shown) > STEP * q.shown then q.shown = size; q.part.Size = q.unit * size end
			frames[n] = CFrame.new(q.at + q.vel * age + Vector3.new(0, 0.5 * (q.spec.rise or 0) * age * age, 0))
				* (q.turn or CFrame.fromAxisAngle(q.axis, q.start + q.spin * age))
		end
	end
	if n > 0 then workspace:BulkMoveTo(movers, frames, Enum.BulkMoveMode.FireCFrameChanged) end
end

local function shape(model, part)
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow, part.Name = true, false, false, false, false, "Trail-" .. model
	local size = part.Size
	local longest = math.max(size.X, size.Y, size.Z)
	shapes[model] = { part = part, unit = size / longest, long = longest == size.X and "X" or longest == size.Y and "Y" or "Z" }
	spare[model] = {}
end

function PlaneTrails.start()
	folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Trails", workspace
	local chip = Instance.new("Part") -- a foil flake is too small to need a model: a thin chip
	chip.Size = Vector3.new(1, 0.07, 0.6)
	shape("flake", chip)
	for model, id in Config.meshes do
		if type(id) == "number" and id > 0 then
			task.spawn(function()
				local ok, made = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. id), { CollisionFidelity = Enum.CollisionFidelity.Box })
				if ok then shape(model, made) else warn("PlaneTrails " .. model .. ": " .. tostring(made)) end
			end)
		end
	end
	RunService.RenderStepped:Connect(step)
end

-- Studio dev button: every plane on this screen wears this trail (nil: each wears its own).
function PlaneTrails.setDevTrail(id) PlaneTrails.devTrail = id end

return PlaneTrails
