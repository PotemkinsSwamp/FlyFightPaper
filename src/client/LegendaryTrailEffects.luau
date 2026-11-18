-- The three continuous Legendary effects use the recent flight path of the plane wearing them.
-- Work stays on this client. All pieces for one plane disappear together when it lands or changes trails.
local Effects = {}
local random = Random.new()
local OFF = CFrame.new(0, 1e5, 0)
local WHITE = Color3.new(1, 1, 1)
local JAWS = {
	upper_jaw = { offset = Vector3.new(0, 0.058356, 0.494816), size = Vector3.new(1.259032, 0.371288, 1.070369), turn = -1 },
	lower_jaw = { offset = Vector3.new(0, -0.058218, 0.422755), size = Vector3.new(1.159108, 0.371564, 0.914490), turn = 0.8 },
}
local SPARK_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 27, 5)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(246, 116, 28)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 227, 154)),
})
local GLINT_COLORS = ColorSequence.new(Color3.fromRGB(147, 118, 190), Color3.fromRGB(205, 162, 238))
local GLINT_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.78),
	NumberSequenceKeypoint.new(0.65, 0.76), NumberSequenceKeypoint.new(1, 1),
})
local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Keep at most one committed sample per 1/40 second plus the current frame.
local function remember(s, now, frame, growth)
	local h = s.history
	if #h < 2 or now - h[#h - 1].time >= 1 / 40 then
		h[#h + 1] = { time = now, frame = frame, growth = growth }
	else
		local last = h[#h]
		last.time, last.frame, last.growth = now, frame, growth
	end
	if #h > 2 and h[2].time < now - 0.85 then table.remove(h, 1) end
end

local function past(s, time)
	local h = s.history
	local lo, hi = 1, #h
	while lo < hi do
		local mid = math.ceil((hi + lo) / 2)
		if h[mid].time <= time then lo = mid else hi = mid - 1 end
	end
	local a, b = h[lo], h[lo + 1]
	if not b or time <= a.time then return a.frame, a.growth end
	local k = math.clamp((time - a.time) / (b.time - a.time), 0, 1)
	return a.frame:Lerp(b.frame, k), a.growth + (b.growth - a.growth) * k
end

local function makeBeam(s, name, colors, fade)
	local a, b, beam = Instance.new("Attachment"), Instance.new("Attachment"), Instance.new("Beam")
	a.Parent, b.Parent = s.anchor, s.anchor
	beam.Attachment0, beam.Attachment1 = a, b
	beam.Name, beam.Color, beam.Transparency = name, colors, fade
	beam.FaceCamera, beam.LightEmission, beam.LightInfluence, beam.Segments = true, 1, 0, 4
	beam.Enabled, beam.Parent = false, s.anchor
	return { a = a, b = b, beam = beam }
end

local function jaws(s, now)
	local phase = (now - s.start + s.phase) % 2.36
	if phase >= 0.85 then
		if s.showing then
			for _, jaw in s.jaws do jaw.CFrame = OFF end
			s.showing = false
		end
		return
	end
	local delay = 0.024 + 0.026 * phase + 0.024 * smooth((phase - 0.68) / 0.17)
	local frame, growth = past(s, now - delay)
	local gape = 0.12 + 0.65 * smooth(phase / 0.18) - 0.59 * smooth((phase - 0.39) / 0.13)
	local size = math.max(0.005, 3 * growth * smooth(phase / 0.12) * (1 - smooth((phase - 0.66) / 0.19)))
	local hinge = frame * CFrame.new(0.42, 0.22 + 0.88 * math.sin(phase / 0.85 * math.pi), 0) * CFrame.Angles(0, -0.56, 0)
	for name, data in JAWS do
		local jaw = s.jaws[name]
		local needsSize = s.jawSize ~= size
		if not jaw and s.shapes[name] then
			jaw = s.shapes[name].part:Clone()
			jaw.Material, jaw.Color = Enum.Material.SmoothPlastic, WHITE
			jaw.CFrame, jaw.Parent, s.jaws[name] = OFF, s.anchor, jaw
			needsSize = true
		end
		if jaw then
			if needsSize then jaw.Size = data.size * size end
			jaw.CFrame = hinge * CFrame.Angles(gape * data.turn, 0, 0) * CFrame.new(data.offset * size)
		end
	end
	s.showing, s.jawSize = true, size
end

local function triangular(low, high, mode)
	local r = random:NextNumber()
	if r < (mode - low) / (high - low) then return low + math.sqrt(r * (high - low) * (mode - low)) end
	return high - math.sqrt((1 - r) * (high - low) * (high - mode))
end

local function spray(s, now, side, count)
	local kick, lift = random:NextNumber(9, 25), random:NextNumber(2, 13)
	for _ = 1, count do
		local q = table.remove(s.spare) or makeBeam(s, "GrindingSpark", SPARK_COLORS, NumberSequence.new(0))
		q.side, q.born = side, now + random:NextNumber(0, 0.02)
		q.life, q.exposure = triangular(0.14, 0.58, 0.27), triangular(0.030, 0.14, 0.069)
		q.kick, q.lift = kick * random:NextNumber(0.57, 1.46), lift + random:NextNumber(-4, 6)
		q.gravity, q.width, q.heat = random:NextNumber(48, 95), random:NextNumber(0.028, 0.078), random:NextNumber(0.63, 1)
		table.insert(s.sparks, q)
	end
end

local function sparkPoint(s, q, now, age)
	local f = past(s, now - age * 0.56)
	local travel = (1 - math.exp(-1.65 * age)) / 1.65
	return f * Vector3.new(q.side * (1.44 + travel * q.kick), -0.48 + travel * q.lift, 0)
		- Vector3.yAxis * (q.gravity * age * age * 0.5)
end

local function sparks(s, now)
	if now >= s.nextBurst then
		s.nextBurst = now + random:NextNumber(0.52, 0.94)
		local side = if random:NextInteger(0, 1) == 0 then -1 else 1
		spray(s, now, side, random:NextInteger(3, 7))
		if random:NextNumber() < 0.32 then spray(s, now + random:NextNumber(0.04, 0.09), side, random:NextInteger(2, 4)) end
	end
	for i = #s.sparks, 1, -1 do
		local q = s.sparks[i]
		local age = now - q.born
		if age >= q.life then
			q.beam.Enabled = false
			table.insert(s.spare, q)
			s.sparks[i] = s.sparks[#s.sparks]
			s.sparks[#s.sparks] = nil
		elseif age >= 0 then
			local tail = math.max(0, age - q.exposure)
			q.a.WorldPosition, q.b.WorldPosition = sparkPoint(s, q, now, tail), sparkPoint(s, q, now, age)
			local width = q.width * math.min(1, (q.life - age) * 18)
			q.beam.Width0, q.beam.Width1 = width * 0.10, width
			q.beam.Brightness, q.beam.Enabled = 4 * q.heat * (1 - 0.66 * age / q.life), true
		end
	end
end

local function createWake(s)
	local assets = s.assets
	local rig = assets and assets:FindFirstChild("CloakStream")
	local template = rig and (if rig:IsA("MeshPart") then rig else rig:FindFirstChildWhichIsA("MeshPart", true))
	local mesh = s.shapes.cloak_stream
	if not (template and mesh) then return end
	local part = mesh.part:Clone()
	-- Rojo can deliver the binds while Studio strips MeshContent. Always use the canonical mesh from the catalog.
	for _, child in part:GetChildren() do if child:IsA("Bone") then child:Destroy() end end
	for _, child in template:GetChildren() do if child:IsA("Bone") then child:Clone().Parent = part end end
	part.Size = template.Size
	local bones = {}
	for _, bone in part:GetDescendants() do
		if bone:IsA("Bone") then
			local k = bone:GetAttribute("WakeK")
			if typeof(k) == "number" then
				local bind = part.CFrame:ToObjectSpace(bone.WorldCFrame)
				bones[#bones + 1] = {bone = bone, k = k, bind = bind}
			end
		end
	end
	if #bones ~= 13 then part:Destroy(); return end
	table.sort(bones, function(a, b) return a.k < b.k end)
	for _, row in bones do
		row.parentBind = if row.bone.Parent:IsA("Bone") then part.CFrame:ToObjectSpace(row.bone.Parent.WorldCFrame) else CFrame.identity
		row.inverse = row.bone.CFrame:Inverse() * row.parentBind:Inverse()
	end
	part.Name, part.Material, part.Color = "CloakStream", Enum.Material.Glass, Color3.fromRGB(219, 211, 233)
	part.Transparency, part.Reflectance, part.CastShadow = 0.73, 0.04, false
	part.CFrame, part.Parent = OFF, s.anchor
	s.bones, s.wake = bones, part
	for i = 1, 3 do s.glints[i] = makeBeam(s, "CloakGlint", GLINT_COLORS, GLINT_FADE) end
end

local function cloak(s, now)
	if not s.wake then
		if now < s.nextLoad then return end
		s.nextLoad = now + 0.3
		createWake(s)
		if not s.wake then return end
	end
	local first, last = past(s, now), past(s, now - 0.8)
	local frame = CFrame.new((first.Position + last.Position) / 2) * first.Rotation
	-- Keeping the part near the midpoint also keeps its native render bounds over the flight path.
	s.wake.CFrame = frame
	for i, row in s.bones do
		local k = row.k
		local f, growth = past(s, now - k * 0.8)
		local phase = k * 22 - now * 3.9
		local width = (0.48 + 2.25 * (1 - math.exp(-16 * k))) * (1 - k ^ 2.4) * growth
		local height = width * (0.41 + 0.12 * math.sin(phase))
		local center = f * Vector3.new(width * 0.17 * math.sin(phase * 0.74), height * 0.31 * math.cos(phase), 0)
		local turn = f.Rotation * CFrame.Angles(0, 0, 0.20 * math.sin(phase))
		local target = CFrame.new(center) * turn * row.bind.Rotation
		row.bone.Transform = row.inverse * frame:ToObjectSpace(target)
		-- The textureless glass bends the room. Tiny broken reflections pick out three separate creases.
		row.glint = center + turn:VectorToWorldSpace(Vector3.new(width * 0.77 * math.cos(phase), height * math.sin(phase), 0))
	end
	for i, g in s.glints do
		local station = 2 + (i - 1) * 4
		g.a.WorldPosition, g.b.WorldPosition = s.bones[station].glint, s.bones[station + 1].glint
		g.beam.Width0, g.beam.Width1 = 0.025, 0.055
		g.beam.Enabled = now - s.start > s.bones[station].k * 0.8
	end
end

function Effects.new(kind, folder, shapes, assets, now)
	local anchor = Instance.new("Part")
	anchor.Name = "Trail-" .. kind
	anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery, anchor.CastShadow = true, false, false, false, false
	anchor.Size, anchor.Transparency, anchor.Parent = Vector3.one, 1, folder
	return {
		kind = kind, anchor = anchor, shapes = shapes, assets = assets, history = {}, start = now, phase = random:NextNumber(0, 2.36),
		jaws = {}, spare = {}, sparks = {}, glints = {}, nextBurst = now + random:NextNumber(0, 0.52), nextLoad = now,
	}
end

function Effects.step(s, now, frame, growth)
	remember(s, now, frame, growth)
	if s.kind == "shark_jet" then jaws(s, now)
	elseif s.kind == "grinding_sparks" then sparks(s, now)
	elseif s.kind == "cloak" then cloak(s, now) end
end

function Effects.destroy(s)
	s.anchor:Destroy()
end

return Effects
