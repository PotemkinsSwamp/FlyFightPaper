-- The stationary plane stays on the binder page. Its wake flows backwards through the same WorldModel.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Config = require(Root.Generated.Trails)
local Trails = require(script.Parent.PlaneTrails)
local Legendary = require(script.Parent.LegendaryTrailEffects)

local Preview = {}
Preview.__index = Preview
local rng = Random.new()

local function color(rgb)
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Use the uploaded skin's own nozzle even when the player pairs it with another trail.
local function nozzle(plane, trail, baseFrame)
	local skin = plane:GetAttribute("Skin")
	local appearance = plane:FindFirstChild("Appearance")
	local body = appearance and appearance:FindFirstChild("Skin-body")
	for _, spec in Config.trails do
		if spec.preview_skin and (spec.preview_skin == skin or (skin == "shark_jet" and spec.preview_skin == "shark")) then
			trail = spec
			break
		end
	end
	local offset = Trails.exhaust(trail, appearance, skin, body, baseFrame)
	if offset then return baseFrame:PointToWorldSpace(offset) end
	local box, size = plane:GetBoundingBox()
	return box:PointToWorldSpace(Vector3.new(0, 0, size.Z / 2))
end

function Preview.new(world, plane, id)
	local trail = Config.trails[id]
	if not trail then return nil end
	local _, size = plane:GetBoundingBox()
	local root = plane:FindFirstChild("Root")
	local baseFrame = root and root.CFrame or CFrame.identity
	local tail = nozzle(plane, trail, baseFrame)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "TrailPreview", world
	folder:SetAttribute("Trail", id)
	local length = math.min(Config.hangar_length, math.max(12, size.Z * 1.45))
	local self = setmetatable({
		tail = tail, length = length, speed = length / Config.life, id = id,
		frame = CFrame.new(tail) * baseFrame.Rotation,
		folder = folder, rows = {}, clock = 0, elapsed = 0,
	}, Preview)
	-- A fixed number of slots gives every row its normal life cycle with no churn on the render thread.
	-- Density is scaled to the short run behind the still model. Thin filler has a smaller screen budget.
	for _, spec in trail.pieces do
		local density = if spec.model == "spark" or spec.model == "square" then 0.16 else 0.50
		local count = math.clamp(math.ceil(spec.rate * (spec.life[1] + spec.life[2]) * 0.5 * density), 2, 54)
		local row = {spec = spec, count = count, slots = {}, nextSlot = 1}
		if spec.rainbow then row.palette = Trails.rainbow(spec, id == "backfire").Keypoints end
		if spec.model == "soft" and not self.sourceRow then
			self.sourceRow, self.sourcePuffs = row, {}
		end
		table.insert(self.rows, row)
	end
	if trail.effect then
		self.effect = Legendary.new(trail.effect, folder, Trails.meshShapes, Root.Assets, 0, self.speed)
	end
	return self
end

local function tintAt(keys, k)
	for i = 2, #keys do
		local nextKey = keys[i]
		if k <= nextKey.Time then
			local prev = keys[i - 1]
			return prev.Value:Lerp(nextKey.Value, (k - prev.Time) / (nextKey.Time - prev.Time))
		end
	end
	return keys[#keys].Value
end

-- ViewportFrames render textured surfaces but don't simulate ParticleEmitters. A front-facing Decal
-- carries exactly the smoke, spark or paper picture used by the flying emitter.
local function sprite(model, folder)
	local part = Instance.new("Part")
	part.Name = "Trail-" .. model
	part.Size, part.Transparency, part.Anchored = Vector3.new(1, 1, 0.02), 1, true
	part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
	local decal = Instance.new("Decal")
	decal.Face, decal.Texture, decal.Parent = Enum.NormalId.Front, Trails.pictures[model], part
	part.Parent = folder
	return part, decal
end

-- Overlap the first few smoke pictures at the nozzle. A flight particle grows from zero over
-- the first tenth of its life, which left a visible hole on the short, top-down page view.
local function smokeAtNozzle(self, now, camera)
	local row = self.sourceRow
	local spec = row.spec
	local reach = math.clamp(self.length * 0.13, 1.6, 4)
	local tracks = spec.pattern == "tracks"
	local lanes = if tracks then 2 else 1
	local rotation = camera.CFrame.Rotation * CFrame.Angles(0, math.pi, 0)
	for lane = 1, lanes do
		for i = 0, 7 do
			local key = (lane - 1) * 8 + i + 1
			local puff = self.sourcePuffs[key]
			if not puff then
				local part, decal = sprite("soft", self.folder)
				part.Name = "ExhaustSmoke"
				decal.Color3 = color(spec.colors[(key - 1) % #spec.colors + 1])
				puff = {part = part, decal = decal}
				self.sourcePuffs[key] = puff
			end
			local t = i / 7
			local wave = math.sin(5.2 * now - 6 * t + lane)
			local diameter = 1.25 + (spec.size[2] * 0.85 - 1.25) * t
			diameter *= 1 + 0.08 * t * wave
			local x = if tracks then (lane * 2 - 3) * (0.26 + 0.97 * t) else 0
			local pos = self.frame * Vector3.new(x + 0.13 * t * wave, 0, -0.22 + reach * t)
			puff.part.Size = Vector3.new(diameter, diameter, 0.02)
			puff.part.CFrame = CFrame.new(pos) * rotation * CFrame.Angles(0, 0, key * 2.4 + now * 0.33)
			puff.decal.Transparency = 0.16 + 0.78 * t ^ 2
			if row.palette then puff.decal.Color3 = tintAt(row.palette, t * reach / self.length) end
		end
	end
end

local function respawn(self, row, slot, born)
	local spec = row.spec
	local across, above = Trails.birthOffset(spec)
	local at = self.frame * Vector3.new(across, above, 0)
	local size = spec.size[1] + (spec.size[2] - spec.size[1]) * rng:NextNumber() ^ 2
	if Trails.pictures[spec.model] then
		if not slot.part then slot.part, slot.decal = sprite(spec.model, self.folder) end
		slot.decal.Color3 = color(spec.colors[rng:NextInteger(1, #spec.colors)])
		slot.life = rng:NextNumber(spec.life[1], spec.life[2])
		slot.velocity = rng:NextUnitVector() * rng:NextNumber(0, spec.drift or 0) - self.frame.LookVector * self.speed
		slot.at, slot.size, slot.startAngle = at, size, rng:NextNumber(0, math.pi * 2)
		slot.spin = math.rad(spec.spin or 0) * rng:NextNumber(-1, 1)
	else
		local shape = Trails.meshShapes[spec.model]
		if not shape then return false end -- the shared async mesh loader will populate this row
		if not slot.part then
			slot.part = shape.part:Clone()
			slot.part.Parent = self.folder
		end
		local q = Trails.newPiece(spec, slot.part, shape, at, self.frame, born, size)
		q.vel -= self.frame.LookVector * self.speed
		-- A traveling circuit LED covers a proportion of the shorter display path.
		if spec.run then q.vel += self.frame.LookVector * spec.run * (1 - self.speed / 105) end
		slot.piece, slot.life = q, q.life
	end
	slot.born = born
	return true
end

local function drawSprite(row, slot, now, camera)
	local spec = row.spec
	local age = now - slot.born
	local k = math.clamp(age / slot.life, 0, 1)
	local size = slot.size * Trails.sizeAt(spec, k)
	if spec.twinkle then size *= 0.35 + 0.65 * math.abs(math.cos(age * spec.twinkle * math.pi)) end
	local position = slot.at + slot.velocity * age + Vector3.new(0, 0.5 * (spec.rise or 0) * age * age, 0)
	local rotation = camera.CFrame.Rotation * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, slot.startAngle + slot.spin * age)
	slot.part.CFrame = CFrame.new(position) * rotation
	if not slot.shown or math.abs(size - slot.shown) > math.max(0.02, slot.shown * 0.08) then
		slot.part.Size = Vector3.new(math.max(0.02, size), math.max(0.02, size), 0.02)
		slot.shown = size
	end
	if row.palette then slot.decal.Color3 = tintAt(row.palette, k) end
	local vanish = spec.vanish or 0
	local fade = if vanish > 0 then math.clamp((k - (1 - vanish)) / vanish, 0, 1) else 0
	local clear = Trails.lit[spec.look].clear
	slot.decal.Transparency = clear + (1 - clear) * fade
end

function Preview:step(dt, camera)
	if not camera or not self.folder.Parent then return end
	self.elapsed += dt
	if self.elapsed < 1 / 30 then return end
	self.clock += math.min(self.elapsed, 0.1)
	self.elapsed = 0
	local now = self.clock
	for _, row in self.rows do
		-- Fill over the first few frames, with staggered ages. Even cold card changes leave input responsive.
		if row.nextSlot <= row.count and (Trails.pictures[row.spec.model] or Trails.meshShapes[row.spec.model]) then
			for i = row.nextSlot, math.min(row.count, row.nextSlot + 7) do
				local slot = {}
				local period = row.spec.life[2]
				local age = (now + (i - 0.5) * period / row.count) % period
				respawn(self, row, slot, now - age)
				table.insert(row.slots, slot)
				row.nextSlot = i + 1
			end
		end
		for _, slot in row.slots do
			local age = now - slot.born
			local period = row.spec.life[2]
			if age >= period then
				respawn(self, row, slot, slot.born + period)
				age = now - slot.born
			end
			if age >= slot.life then
				slot.part.CFrame = CFrame.new(0, 1e5, 0)
			elseif slot.piece then
				slot.part.CFrame = Trails.piecePose(slot.piece, now, age, age / slot.life, camera.CFrame.Position)
			else
				drawSprite(row, slot, now, camera)
			end
		end
	end
	if self.sourceRow then smokeAtNozzle(self, now, camera) end
	if self.effect then Legendary.step(self.effect, now, self.frame, 1) end
end

function Preview:destroy()
	self.folder:Destroy()
	table.clear(self.rows)
	self.effect = nil
end

return Preview
