-- Cosmetics from the approved Blender rig (tools/art/ninja_motion.py). The bind-pose
-- conversion and the skinned mesh travel together in Assets.NinjaRig.
local NinjaMotion = {}
local worn = {}
local SAMPLE = 1 / 24
local HISTORY = 8 -- six frames of lag at the tips, plus interpolation on both ends
local IDENTITY = CFrame.identity

-- Resize the bind offsets from the pristine template, once per fit. Bone offsets
-- are local to their parent bone. The Ninja always fits with one uniform scale.
function NinjaMotion.fitBones(part, template, size)
	local scale = size.Z / template.Size.Z
	part.Size = size
	for _, source in template:GetDescendants() do
		if source:IsA("Bone") then
			local bone = part:FindFirstChild(source.Name, true)
			bone.CFrame = CFrame.new(source.CFrame.Position * scale) * source.CFrame.Rotation
			bone.Transform = IDENTITY
		end
	end
end

function NinjaMotion.clear(model)
	worn[model] = nil
end

function NinjaMotion.wear(model, root, pieces, shape, glint, preview)
	local chains = {}
	for tail, prefix in { "ribbon_upper_", "ribbon_lower_" } do
		local chain = {}
		for joint = 1, 5 do
			local bone = pieces.body:FindFirstChild(prefix .. joint, true)
			if not (bone and bone:IsA("Bone")) then
				warn("Ninja scarf is missing " .. prefix .. joint)
				return
			end
			local basis = bone:GetAttribute("MotionBasis") or IDENTITY
			chain[joint] = { bone = bone, basis = basis.Rotation, inverse = basis.Rotation:Inverse() }
		end
		chains[tail] = chain
	end

	local blades = {}
	if glint then
		local hull = shape.pieces[shape.hitPiece]
		local length = hull.max[3] - hull.min[3]
		for _, name in { "bladeL", "bladeR" } do
			local blade, box = pieces[name], shape.pieces[name]
			local decal = glint:Clone()
			decal.Name = "Blade reflection"
			-- The Rare foil glint is one slanted white line at the middle of a
			-- transparent picture. Its Top decal only covers this blade mesh.
			local sx = 0.24 * (box.max[1] - box.min[1]) / length
			local sy = 0.24 * (box.max[3] - box.min[3]) / length
			local middleZ = (box.min[3] + box.max[3]) / 2 - hull.min[3]
			local middleX = (box.min[1] + box.max[1]) / 2
			decal.Face = Enum.NormalId.Top
			decal.UVScale = Vector2.new(sx, sy)
			decal.Rotation = -math.deg(math.atan(0.28) + math.atan(0.10))
			decal.EmissiveStrength = 1
			decal.Transparency = 1
			decal.Parent = blade
			table.insert(blades, {
				decal = decal, center = (middleZ + 0.28 * middleX) / length,
				offset = Vector2.new(0.5 - sx / 2, 0.5 - sy / 2),
			})
		end
	end
	worn[model] = {
		body = pieces.body, root = root or pieces.body, preview = preview,
		chains = chains, blades = blades, history = table.create(HISTORY), head = 1,
	}
end

-- Sample at Blender's 24 Hz regardless of the player's frame rate. A delayed
-- turn is measured against the plane's current axes so it works on climbs too.
local function sample(w, frame, now)
	local elapsed = now - (w.lastTime or now)
	local teleport = w.lastFrame and (frame.Position - w.lastFrame.Position).Magnitude > 60
	if not w.lastTime or elapsed > 0.3 or teleport then
		for i = 1, HISTORY do w.history[i] = frame end
		w.sampled = now
	else
		while w.sampled + SAMPLE <= now do
			w.sampled += SAMPLE
			w.head = w.head % HISTORY + 1
			w.history[w.head] = w.lastFrame:Lerp(frame, math.clamp((w.sampled - w.lastTime) / elapsed, 0, 1))
		end
	end
	w.lastTime, w.lastFrame = now, frame
end

local function stepScarf(w, model, now)
	local frame = w.root.CFrame
	sample(w, frame, now)
	local fraction = (now - w.sampled) / SAMPLE
	local cruise = math.max(1, model:GetAttribute("Speed") or 105)
	for joint = 1, 5 do
		local delay = joint + 1
		local old = (w.head - 1 - delay) % HISTORY + 1
		local previous = w.history[old]:Lerp(w.history[old % HISTORY + 1], fraction)
		local dt = delay * SAMPLE
		local speed = (previous.Position - frame.Position).Magnitude / (dt * cruise)
		-- The preview cruises at 1.4 plane lengths/s. At boost the cloth pulls taut.
		local air = w.preview and 1.4 or 1.4 * math.min(speed, 1) + 6 * math.max(0, speed - 1)
		local wind = math.min(1, air) / (1 + 0.55 * air)
		local _, yaw, roll = frame:ToObjectSpace(previous):ToOrientation()
		roll = math.clamp(roll, -1.25 * dt, 1.25 * dt)
		yaw = math.clamp(yaw, -0.75 * dt, 0.75 * dt)
		for tail, chain in w.chains do
			local phase = (joint - 1) * 1.13 + (tail - 1) * 0.58
			local lift = wind * 0.272 * math.sin(now * 24 * 0.36 - phase) - 0.232 * roll + (tail == 1 and 0.06 or -0.06)
			local swing = wind * 0.16 * math.sin(now * 24 * 0.31 - phase) + 0.352 * yaw
			local entry = chain[joint]
			-- Blender XYZ Euler applies X first, then Z, in its bone's rest axes.
			entry.bone.Transform = entry.basis * CFrame.Angles(0, 0, swing) * CFrame.Angles(lift, 0, 0) * entry.inverse
		end
	end
end

function NinjaMotion.step(now, eye, near)
	for model, w in worn do
		if not (model.Parent and w.body.Parent and w.root.Parent) then
			worn[model] = nil
		elseif w.preview or (w.body.Position - eye).Magnitude <= near then
			stepScarf(w, model, now)
			local sweep = 0.34 + ((now * 24 + 7) % 44) * 0.034
			for _, blade in w.blades do
				local distance = sweep - blade.center
				blade.decal.Transparency = 0
				blade.decal.UVOffset = blade.offset + Vector2.new(0, 0.24 * distance)
			end
		elseif w.lastTime then
			w.lastTime, w.lastFrame = nil, nil
			for _, blade in w.blades do blade.decal.Transparency = 1 end
		end
	end
end

return NinjaMotion
