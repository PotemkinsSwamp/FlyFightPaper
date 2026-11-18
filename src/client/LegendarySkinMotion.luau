-- The motion sheets were projected over one complete hull in the approved Blender previews.
-- Decal maps are cloned from SkinLooks because their glow images require authoring permissions.
local Motion = {}
local worn = {}
local UP, DOWN = Enum.NormalId.Top, Enum.NormalId.Bottom

local function layer(source, name, body, face, depth, glow)
	local decal = source[name]:Clone()
	decal.Face, decal.ZIndex, decal.EmissiveStrength = face, depth, glow
	decal.Transparency = 1
	decal.Parent = body
	return decal
end

local function emission(body, name, position, direction)
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = CFrame.lookAt(position, position + direction)
	attachment.Parent = body
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.LockedToPart = true
	emitter.Parent = attachment
	return attachment, emitter
end

local function pipes(body, ports)
	local jets = {}
	local length = body.Size.Z
	for i, p in ports do
		local pos = Vector3.new(p[1],p[2],p[3]) * body.Size
		local _, jet = emission(body, i == 1 and "Nozzle fire" or "Pipe backfire", pos, Vector3.zAxis)
		jet.Texture = "rbxasset://textures/particles/fire_main.dds"
		jet.Color = ColorSequence.new(Color3.fromRGB(255,235,125), Color3.fromRGB(255,84,8))
		jet.LightEmission = 0.9
		jet.SpreadAngle = Vector2.new(4,4)
		jet.Lifetime = NumberRange.new(.09,.13)
		jet.Speed = NumberRange.new(length * .85, length * (i == 1 and 1.25 or 1))
		jet.Size = NumberSequence.new(length * (i == 1 and .095 or .052), 0)
		jet.Rate = i == 1 and 50 or 0
		jets[i] = jet
	end
	return jets
end

local function spray(body)
	local result = {}
	for i, side in {-1, 1} do
		local at, jet = emission(body, "Breach spray", Vector3.zero, Vector3.new(side,.31,.7))
		-- Elongate a round drop along its flight direction, like the preview's spray.
		jet.Texture = "rbxasset://textures/whiteCircle.png"
		jet.Orientation = Enum.ParticleOrientation.VelocityParallel
		jet.Color = ColorSequence.new(Color3.fromRGB(229,250,255), Color3.fromRGB(115,191,234))
		jet.LightEmission = .42
		jet.SpreadAngle = Vector2.new(13,18)
		jet.Lifetime = NumberRange.new(.44,.78)
		jet.Speed = NumberRange.new(body.Size.Z * .58, body.Size.Z * .94)
		jet.Acceleration = Vector3.new(0, -body.Size.Z*.75, 0)
		jet.Size = NumberSequence.new(body.Size.Z*.038, body.Size.Z*.012)
		jet.Squash = NumberSequence.new(-.6)
		jet.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,.16), NumberSequenceKeypoint.new(.63,.3), NumberSequenceKeypoint.new(1,1)})
		result[i] = {at=at, jet=jet, side=side}
	end
	return result
end

function Motion.wear(model, id, body, shape, layers, preview)
	local w = {id=id, body=body, preview=preview, start=os.clock()}
	local box = shape.pieces.body
	-- Authoring X goes from the nose to the tail in units of one reference plane length.
	w.nose = box.min[3]/8.4 + .5
	w.tail = box.max[3]/8.4 + .5
	if id == "stealth" or id == "hot_rod" then
		local name = id == "stealth" and "comet" or "flames"
		local glow = id == "stealth" and 4 or .9
		w.frames = {}
		for i = 1, 3 do
			local d = layer(layers, name, body, UP, i+2, glow)
			d.UVScale = Vector2.one * (248/1024)
			w.frames[i] = d
		end
		if id == "stealth" then
			w.top = layer(layers,"lines",body,UP,1,1)
			w.bottom = layer(layers,"lines",body,DOWN,1,1)
			w.top.UVScale = Vector2.new(.5,1)
			-- The bottom face sees the other side of the box, with its length axis reversed.
			w.bottom.UVScale = Vector2.new(.5,-1)
			w.bottom.UVOffset = Vector2.new(.5,1)
			w.top.Transparency, w.bottom.Transparency = 0, 0
		else
			w.jets = pipes(body,shape.ports)
			w.pulses = {}
		end
	elseif id == "shark_jet" then
		w.top = layer(layers,"water",body,UP,1,.75)
		w.top.UVScale = Vector2.new(1,(w.tail-w.nose)/4.2)
		w.spray = spray(body)
		local low = Vector3.new(table.unpack(box.min))
		local high = Vector3.new(table.unpack(box.max))
		w.box = {center=(low+high)/2, scale=body.Size/(high-low)}
	elseif id == "race_car" then
		w.top = layer(layers,"shine",body,UP,1,.53)
		w.top.UVScale = Vector2.new(1,(w.tail-w.nose)/.7)
	else
		return
	end
	worn[model] = w
end

function Motion.clear(model)
	worn[model] = nil
end

local function flipbook(w, t)
	local phase = t/(w.id == "stealth" and 2 or 2.5)*16
	local cell = math.floor(phase)
	local fade = phase-cell
	for i, decal in w.frames do
		local index = (cell+i-2)%16
		if w.cell ~= cell then
			decal.UVOffset = Vector2.new(index%4/4 + 4/1024, math.floor(index/4)/4 + 4/1024)
		end
		decal.Transparency = i == 1 and fade or i == 2 and 0 or 1-fade
	end
	w.cell = cell
end

local function breach(w, t, dt)
	local age = t%4
	local wave = (age-.47)/.6
	w.top.Transparency = 0
	w.top.UVOffset = Vector2.new(0,(wave-w.tail+.4)/4.2)
	-- Move both sources along the hull as the spray separates from the nose and cheeks.
	if age < .37 or age > .82 then return end
	local x = math.clamp((age-.37)/.6,.03,.66)
	w.drops = (w.drops or 0) + math.min(dt,.08)*240
	local count = math.floor(w.drops)
	w.drops -= count
	if count == 0 then return end
	local body, box = w.body, w.box
	for _, jet in w.spray do
		local point = Vector3.new(jet.side*math.min(.02+x*.15,.05), .04+math.min(x,.25)*.24, x-.5)*8.4
		jet.at.Position = (point - box.center) * box.scale
		jet.jet:Emit(count)
	end
end

function Motion.step(now, eye, near)
	for model, w in worn do
		if not model.Parent or not w.body.Parent then
			worn[model] = nil
		elseif w.preview or (w.body.Position - eye).Magnitude <= near then
			local t = now-w.start
			local dt = w.last and math.min(.1,now-w.last) or 0
			w.last = now
			if w.frames then flipbook(w,t) end
			if w.id == "shark_jet" then
				breach(w,t,dt)
			elseif w.id == "race_car" then
				local sweep = math.min(t%2,1)*2.05-.45
				w.top.Transparency = 0
				w.top.UVOffset = Vector2.new(0,.5+(sweep-w.tail)/.7)
			elseif w.id == "stealth" then
				local strength = 1.5+.36*math.sin(t*math.pi/2)
				w.top.EmissiveStrength, w.bottom.EmissiveStrength = strength, strength
			elseif w.jets then
				w.jets[1].Enabled = true
				for i = 2, #w.jets do
					local phase = (t*2+(i-2)*.25)%1
					if phase < .55 and dt > 0 then
						local bucket = math.floor((t+(i-2)*.125)*32)
						if w.pulses[i] ~= bucket then
							w.pulses[i] = bucket
							w.jets[i]:Emit(2)
						end
					end
				end
			end
		elseif w.last then
			w.last = nil
			if w.jets then w.jets[1].Enabled = false end
		end
	end
end

return Motion
