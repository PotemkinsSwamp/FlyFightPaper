-- Shape skins (Legendary, Mythical: the Origami Crane) measured and fitted to one plane: ONE rule for the screen
-- (client/SkinShapes draws the pieces) and the server (HitShapes turns the real wings' hit and crash shapes up and
-- moves the guns' to where the skin draws them; Alan 2026-11-14, docs/plan/SKINS-PLAN.md "Wing-hitbox tilt").
-- The fit follows tools/art/crane_skin.py (crane(), wing_under(), hang_guns()); the pieces, their boxes and the
-- starter build's numbers come from config/skin-shapes.json.
local Shapes = require(script.Parent.Parent:WaitForChild("Generated"):WaitForChild("SkinShapes")).shapes
local SkinFit = { shapes = Shapes }

local function v3(t) return Vector3.new(t[1], t[2], t[3]) end
local function clamp(x, lo, hi) return math.min(math.max(x, lo), hi) end

function SkinFit.has(id) return type(id) == "string" and Shapes[id] ~= nil end

-- The plane's outline in its own frame (crane_skin.py outline()), from the corners of each slot's part boxes.
function SkinFit.outline(appearance, frame)
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

-- Where each piece goes (crane_skin.py crane()): CFrame and Size in the plane's frame, plus what the guns need and the
-- right wing's hinge (the left one mirrors it in x).
function SkinFit.fit(shape, o)
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
	local hinge = Vector3.new(cw * 0.97, hy + 0.02 * s, zc)
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
			out[name] = { CFrame.new(hinge * Vector3.new(name == "wingL" and -1 or 1, 1, 1) + centre * ks), size * ks }
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
		local u = clamp((math.abs(x) - hinge.X) / (ks * math.cos(rise)), 0.25, K.R0 - 1.2)
		local m = math.max(0.9, half / ks + 0.3)
		local front, back = -K.C0 / 2 + u * (K.SW + K.C0 / 2) / K.R0 + m, K.C0 / 2 - u * (K.C0 / 2 - K.SW) / K.R0 - m
		local w = front <= back and clamp((z - zc) / ks, front, back) or (front + back) / 2
		local xx = hinge.X + u * ks * math.cos(rise)
		return Vector3.new(x < 0 and -xx or xx, hinge.Y + u * ks * math.sin(rise) - 0.035 * s, zc + w * ks)
	end
	return out, under, rise, hinge
end

-- Everything shape skin `id` moves on this plane (frame = its Root), in the plane's frame: the pieces to draw, and where
-- each real wing part and gun part goes (`move * frame:ToObjectSpace(part.CFrame)`, same size). A wing part turns
-- about its side's hinge line (front to back), tip up by the skin's rise; a gun hangs under the drawn wing by its top
-- (hang_guns()): it keeps its spot seen from above and rolls with the wing. `offsets[slot]`: how far that gun's top
-- moved; `hinge`: the right wing's hinge (the left one mirrors it in x). nil when `id` has no shape or the plane's parts
-- aren't there yet.
function SkinFit.plane(id, appearance, frame)
	local shape = type(id) == "string" and Shapes[id]
	local o = shape and appearance and SkinFit.outline(appearance, frame)
	if not o then return nil end
	local placed, under, rise, hinge = SkinFit.fit(shape, o)
	local result, guns = { placed = placed, wings = {}, guns = {}, offsets = {}, hinge = hinge }, {}
	for _, part in appearance:GetChildren() do
		if not part:IsA("BasePart") or part:GetAttribute("SkinPiece") then continue end
		local mount = tonumber(string.match(part.Name, "^Mount(%d+)"))
		if string.match(part.Name, "^(%a+)") == "wings" then
			local left = frame:PointToObjectSpace(part.Position).X < 0
			local at = left and hinge * Vector3.new(-1, 1, 1) or hinge
			result.wings[part] = CFrame.new(at) * CFrame.Angles(0, 0, left and -rise or rise) * CFrame.new(-at)
		elseif mount then guns[mount] = guns[mount] or {}; table.insert(guns[mount], part) end
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
		result.offsets[mount] = to - top
		for _, part in parts do result.guns[part] = move end
	end
	return result
end

return SkinFit
