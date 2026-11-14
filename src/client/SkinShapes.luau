-- Legendary and Mythical skins that change the plane's shape (skins plan): one model cut into a few pieces, each placed
-- and sized from this plane's own parts, on each player's screen only. The real body, nose, wings and tail hide under it;
-- guns move under the wings (Alan 2026-11-13: nothing on top of a Mythical) and boosters stay. The server's plane, hitbox
-- and shots never change. The fit follows tools/art/crane_skin.py (crane(), wing_under(), hang_guns()); the pieces, their
-- boxes and the starter build's numbers come from config/skin-shapes.json.
local AssetService = game:GetService("AssetService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Shapes = require(Root:WaitForChild("Generated"):WaitForChild("SkinShapes")).shapes
local SkinShapes = {}
local meshes = {} -- mesh id -> MeshPart to copy (false while loading)

local function v3(t) return Vector3.new(t[1], t[2], t[3]) end
local function clamp(x, lo, hi) return math.min(math.max(x, lo), hi) end

function SkinShapes.has(id) return type(id) == "string" and Shapes[id] ~= nil end

-- The plane's outline in its own frame (crane_skin.py outline()), from the corners of each slot's part boxes.
local function outline(appearance, frame)
	local o = { zN = math.huge, zT = -math.huge, yT = -math.huge, bw = 0, by0 = math.huge, bz0 = math.huge, bz1 = -math.huge,
		xo = 0, xi = math.huge, boostY = nil, boostZ = nil }
	local wingY, wingBoxes = {}, {}
	for _, part in appearance:GetChildren() do
		if not part:IsA("BasePart") or part:GetAttribute("SkinPiece") then continue end
		local slot = string.match(part.Name, "^(%a+)")
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for i = 0, 7 do
			local c = part.Size / 2 * Vector3.new(i % 2 * 2 - 1, math.floor(i / 2) % 2 * 2 - 1, math.floor(i / 4) * 2 - 1)
			local p = frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(c))
			lo, hi = lo:Min(p), hi:Max(p)
		end
		if slot == "nose" then o.zN = math.min(o.zN, lo.Z)
		elseif slot == "tail" then o.zT, o.yT = math.max(o.zT, hi.Z), math.max(o.yT, hi.Y)
		elseif slot == "body" then
			o.bw, o.by0 = math.max(o.bw, math.abs(lo.X), math.abs(hi.X)), math.min(o.by0, lo.Y)
			o.bz0, o.bz1 = math.min(o.bz0, lo.Z), math.max(o.bz1, hi.Z)
		elseif slot == "wings" then
			table.insert(wingY, (lo.Y + hi.Y) / 2)
			if hi.X > 0 then
				o.xo, o.xi = math.max(o.xo, hi.X), math.min(o.xi, math.max(lo.X, 0))
				table.insert(wingBoxes, { lo, hi })
			end
		elseif slot == "Booster" then
			o.boostY, o.boostZ = math.max(o.boostY or -math.huge, hi.Y), math.max(o.boostZ or -math.huge, hi.Z)
		end
	end
	if o.zN == math.huge or o.zT == -math.huge or o.bz0 == math.huge or #wingY == 0 then return nil end
	table.sort(wingY)
	o.wy = wingY[math.ceil(#wingY / 2)]
	-- ponytail: the wing's root chord from the boxes that reach the root (a swept wing's box is longer than its root);
	-- read the wing's RootFront/RootBack points instead if a swept crane sits too far back.
	o.LI, o.TI = math.huge, -math.huge
	for _, box in wingBoxes do
		if box[1].X < o.xi + 0.6 then o.LI, o.TI = math.min(o.LI, box[1].Z), math.max(o.TI, box[2].Z) end
	end
	return o
end

-- Where each piece goes (crane_skin.py crane()): CFrame and Size in the plane's frame, plus what the guns need.
local function fit(shape, o)
	local K, ref = shape.const, shape.ref
	local rise = math.rad(K.RISE)
	local s = (o.zT - o.zN) / 16
	local wy = o.wy
	local cw = clamp(0.95 * o.bw, 0.9 * s, 1.7 * s)
	local ky = o.by0 -- the belly stops at the real body's bottom (Alan 2026-11-14: reaching down to the booster made it too tall)
	local zF, zB = o.bz0 + 0.2 * s, o.bz1 - 0.2 * s
	local blen = zB - zF
	local run = (o.xo + 0.3 * s - cw) / math.cos(rise) / s
	local chord = (o.TI - o.LI) / s
	local ks = math.min(math.max(math.sqrt(math.max(run / K.R0 * chord / K.C0, 0)), 0.85), 1.2, 0.9 * blen / (K.C0 * s)) * s
	-- The body stretches per axis to the real body; the wings hinge on the middle of its sides (where the stretched
	-- starter body has them), so a wing root never floats off the body.
	local top, bottom = wy + 0.5 * s, ky -- (the roof was 0.9 s up: too tall, Alan 2026-11-14)
	local refTop, refBottom = ref.wy + 0.9 * ref.s, ref.ky - 0.35 * ref.s
	local scale = Vector3.new(cw / ref.cw, (top - bottom) / (refTop - refBottom), blen / (ref.zB - ref.zF))
	local function body(p) return Vector3.new(p.X * scale.X, bottom + (p.Y - refBottom) * scale.Y, zF + (p.Z - ref.zF) * scale.Z) end
	local zc = body(Vector3.new(0, 0, ref.zc)).Z
	-- The wings, neck and tail join the stretched body's side edge, wherever the stretch puts it (Alan 2026-11-14: hinged at the real
	-- wing's height they floated off the body).
	local hy = body(Vector3.new(0, ref.wy, 0)).Y
	local O = Vector3.new(0, hy + 0.05 * s, zF + 0.15 * s)
	local T0 = Vector3.new(0, hy - 0.2 * s, zB - 0.7 * s)
	local Tt = Vector3.new(0, math.max(o.yT, wy + 1.3 * s) + 0.5 * s, o.zT + 0.7 * s)
	local along = (Tt - T0).Unit
	local tailFrame = CFrame.fromMatrix(T0, Vector3.xAxis, along:Cross(Vector3.xAxis), along)
	local out = {}
	for name, piece in shape.pieces do
		local lo, hi = v3(piece.min), v3(piece.max)
		local centre, size = (lo + hi) / 2, hi - lo
		if name == "head" then
			out[name] = { CFrame.new(O + centre * s), size * s }
		elseif name == "wingL" or name == "wingR" then
			local hinge = Vector3.new((name == "wingL" and -1 or 1) * cw * 0.97, hy + 0.02 * s, zc)
			out[name] = { CFrame.new(hinge + centre * ks), size * ks }
		elseif name == "tail" then
			local stretch = Vector3.new(s, s, (Tt - T0).Magnitude)
			out[name] = { tailFrame * CFrame.new(centre * stretch), size * stretch }
		else -- body
			out[name] = { CFrame.new(body(centre)), size * scale }
		end
	end
	-- crane_skin.py wing_under(): the spot under the wing nearest (x, z), and the wing's underside height there. `half`:
	-- half the gun's length, so all of it hangs under the wing, front to back (Alan 2026-11-13: guns stuck out ahead of
	-- the wing); a gun longer than the wing there sits in the wing's middle.
	local function under(x, z, half)
		local u = clamp((math.abs(x) - cw * 0.97) / (ks * math.cos(rise)), 0.25, K.R0 - 1.2)
		local m = math.max(0.9, half / ks + 0.3)
		local front, back = -K.C0 / 2 + u * (K.SW + K.C0 / 2) / K.R0 + m, K.C0 / 2 - u * (K.C0 / 2 - K.SW) / K.R0 - m
		local w = front <= back and clamp((z - zc) / ks, front, back) or (front + back) / 2
		local xx = cw * 0.97 + u * ks * math.cos(rise)
		return Vector3.new(x < 0 and -xx or xx, hy + 0.02 * s + u * ks * math.sin(rise) - 0.035 * s, zc + w * ks)
	end
	return out, under, rise
end

local function meshOf(id)
	while meshes[id] == false do task.wait() end
	if meshes[id] == nil then
		meshes[id] = false
		local ok, made = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id), { CollisionFidelity = Enum.CollisionFidelity.Box })
		end)
		if not ok then warn("SkinShapes mesh " .. id .. ": " .. tostring(made)) end
		meshes[id] = ok and made or nil
	end
	return meshes[id]
end

-- Take the shape off: the real parts and guns come back, the pieces and moved guns go.
function SkinShapes.clear(model)
	local appearance = model:FindFirstChild("Appearance")
	if not appearance then return end
	for _, part in appearance:GetChildren() do
		if part:GetAttribute("SkinPiece") then part:Destroy()
		elseif part:GetAttribute("SkinHidden") then
			part.LocalTransparencyModifier = 0
			part:SetAttribute("SkinHidden", nil)
		end
	end
	for slot = 1, 8 do model:SetAttribute("SkinGunMove" .. slot, nil) end
end

-- Put shape `id` on `model` (a flying plane or the hangar photo). Returns false if the plane's parts aren't there yet.
function SkinShapes.wear(model, id)
	SkinShapes.clear(model)
	local shape, appearance = Shapes[id], model:FindFirstChild("Appearance")
	if not (shape and appearance) then return false end
	local rootPart = model:FindFirstChild("Root")
	local frame = rootPart and rootPart.CFrame or CFrame.identity
	local o = outline(appearance, frame)
	if not o then return false end
	local placed, under, rise = fit(shape, o)
	-- Its look is made ahead (tools/art/skin_looks.py writes SkinLooks/<id>/Shape): scripts can't set a look's pictures.
	local look = Root:WaitForChild("Assets"):FindFirstChild("SkinLooks")
	look = look and look:FindFirstChild(id) and look[id]:FindFirstChild("Shape")
	local preview = rootPart == nil or (appearance:FindFirstChildWhichIsA("BasePart") and appearance:FindFirstChildWhichIsA("BasePart").Anchored)
	local function attach(part, cf)
		part.CFrame = frame * cf
		part.Anchored, part.Massless, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = preview, true, false, false, false, true
		part.Parent = appearance
		if rootPart and not preview then
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = rootPart, part, part
		end
	end
	for name, at in placed do
		local mesh = meshOf(shape.pieces[name].mesh)
		if not (mesh and model.Parent and appearance.Parent) then continue end
		local part = mesh:Clone()
		part.Name, part.Size = "Skin-" .. name, at[2]
		part:SetAttribute("SkinPiece", true)
		if look then look:Clone().Parent = part end
		attach(part, at[1])
	end
	-- Hide what the shape covers; guns hang under the wings (hang_guns()): each keeps its spot seen from above, rolls
	-- with the wing and hangs by its top. The real gun hides; a copy shows at the new spot.
	local guns = {}
	for _, part in appearance:GetChildren() do
		if not part:IsA("BasePart") or part:GetAttribute("SkinPiece") then continue end
		local slot = string.match(part.Name, "^(%a+)")
		if slot == "body" or slot == "nose" or slot == "wings" or slot == "tail" then
			part.LocalTransparencyModifier = 1
			part:SetAttribute("SkinHidden", true)
		else
			local mount = tonumber(string.match(part.Name, "^Mount(%d+)"))
			if mount then guns[mount] = guns[mount] or {}; table.insert(guns[mount], part) end
		end
	end
	for mount, parts in guns do
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, part in parts do
			local p = frame:PointToObjectSpace(part.Position)
			lo, hi = lo:Min(p - part.Size / 2), hi:Max(p + part.Size / 2)
		end
		local top = Vector3.new((lo.X + hi.X) / 2, hi.Y, (lo.Z + hi.Z) / 2)
		local to = under(top.X, top.Z, (hi.Z - lo.Z) / 2)
		local move = CFrame.new(to) * CFrame.Angles(0, 0, to.X < 0 and -rise or rise) * CFrame.new(-top)
		model:SetAttribute("SkinGunMove" .. mount, to - top) -- the drawn bullet starts from the gun you see
		for _, part in parts do
			local copy = part:Clone()
			for _, child in copy:GetChildren() do if child:IsA("WeldConstraint") then child:Destroy() end end
			copy.Name = "SkinGun-" .. part.Name
			copy:SetAttribute("SkinPiece", true)
			copy.LocalTransparencyModifier = 0
			part.LocalTransparencyModifier = 1
			part:SetAttribute("SkinHidden", true)
			attach(copy, move * frame:ToObjectSpace(part.CFrame))
		end
	end
	return true
end

return SkinShapes
