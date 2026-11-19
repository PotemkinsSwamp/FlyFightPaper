-- Shape skins (Legendary, Mythical: the Origami Crane, the Dragon) measured and fitted to one plane: ONE rule for the screen
-- (client/SkinShapes draws the pieces) and the server (HitShapes turns the real wings' hit and crash shapes up and
-- moves the guns' to where the skin draws them; Alan 2026-11-14, docs/plan/SKINS-PLAN.md "Wing-hitbox tilt").
-- The fit follows tools/art/crane_skin.py (crane(), wing_under(), hang_guns()); the pieces, their boxes and the
-- starter build's numbers come from config/skin-shapes.json.
local Generated = script.Parent.Parent:WaitForChild("Generated")
local Shapes = require(Generated:WaitForChild("SkinShapes")).shapes
local Sizes = require(Generated:WaitForChild("SkinSizes")).skins
local Hanging = require(Generated:WaitForChild("SkinUndersides"))
local Undersides, Clips = Hanging.skins, Hanging.clips
local SkinFit = { shapes = Shapes }

local function v3(t) return Vector3.new(t[1], t[2], t[3]) end
local function clamp(x, lo, hi) return math.min(math.max(x, lo), hi) end

-- Skin `id`'s underside grid (config/skin-undersides.json): cols[i][j] = the lowest drawn underside over the cell at
-- x0 + (i - 0.5) step, z0 + (j - 0.5) step, in the skin's own frame; nil = nothing above.
local grids = {}
local function gridOf(id)
	if grids[id] == nil then
		local m = Undersides[id]
		grids[id] = false
		if m then
			local cols = {}
			for i, column in m.columns do
				local cells, j = {}, 0
				for cell in string.gmatch(column .. ",", "([^,]*),") do
					j += 1
					cells[j] = tonumber(cell) and tonumber(cell) / 100
				end
				cols[i] = cells
			end
			grids[id] = { step = m.step, x0 = m.x0, z0 = m.z0, cols = cols }
		end
	end
	return grids[id] or nil
end
-- Spots near a gun's wanted spot, nearest first (skin units): where hang() looks for one with its clip under the skin.
local NEAR = {}
for dx = -2.5, 2.5, 0.05 do for dz = -3.5, 3.5, 0.05 do table.insert(NEAR, Vector2.new(dx, dz)) end end
table.sort(NEAR, function(a, b) return a.Magnitude < b.Magnitude end)
local MAX_TILT = math.tan(math.rad(15))

function SkinFit.has(id) return type(id) == "string" and Shapes[id] ~= nil end

-- How many times "as wide as the plane" skin `id` is drawn on plane `build` (Aircraft's "body|nose|wings|tail") so it
-- covers as much of the chase view as the plain plane (Alan 2026-11-19; config/skin-sizes.json, measured by
-- tools/skin_sizes.lua): the body + wings size times the nose's and the tail's. By the wingspan because a nose or tail
-- changes the plane's length far more than its share of the screen. nil: not measured.
function SkinFit.screenSize(id, build)
	local body, nose, wings, tail = string.match(build or "", "^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
	local row = Sizes[id] and Sizes[id][body]
	local size = row and row.wings[wings]
	return size and size * (row.nose[nose] or 1) * (row.tail[tail] or 1)
end

-- A part's box in the plane's frame, from its eight corners.
local function box(part, frame)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for i = 0, 7 do
		local c = part.Size / 2 * Vector3.new(i % 2 * 2 - 1, math.floor(i / 2) % 2 * 2 - 1, math.floor(i / 4) * 2 - 1)
		local p = frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(c))
		lo, hi = lo:Min(p), hi:Max(p)
	end
	return lo, hi
end

-- The plane's outline in its own frame (crane_skin.py outline()), from the corners of each slot's part boxes.
function SkinFit.outline(appearance, frame)
	local o = { zN = math.huge, zT = -math.huge, yT = -math.huge, bw = 0, by0 = math.huge, bz0 = math.huge, bz1 = -math.huge,
		xo = 0, xi = math.huge }
	local wingY, wingBoxes = {}, {}
	for _, part in appearance:GetChildren() do
		if not part:IsA("BasePart") or part:GetAttribute("SkinPiece") then continue end
		local slot = string.match(part.Name, "^(%a+)")
		local lo, hi = box(part, frame)
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
		end
	end
	if o.zN == math.huge or o.zT == -math.huge or o.bz0 == math.huge or #wingY == 0 then return nil end
	o.build = appearance:GetAttribute("Build")
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

-- A belly line (points down the drawn body's middle, front to back) as "its lowest height between z0 and z1", nil off
-- the body. The belly rises to each side, so a booster under the middle meets it there first.
local function bellyOf(keel)
	return function(z0, z1)
		local low
		for i = 1, #keel - 1 do
			local a, b = keel[i], keel[i + 1]
			local from, to = math.max(z0, a.Z), math.min(z1, b.Z)
			if from > to then continue end
			for _, z in { from, to } do -- straight between corners: lowest at an end
				local y = a.Y + (b.Y - a.Y) * (z - a.Z) / (b.Z - a.Z)
				low = math.min(low or y, y)
			end
		end
		return low
	end
end

-- Shapes that keep their proportions and are the plane's hit and crash shape (the Dragon, the Legendaries; Alan 2026-11-15:
-- "we can't stretch it and make it look odd"): ONE size for the whole model, centred on the plane, wings at the plane's wing
-- height. HitShapes uses its pieces instead of the body, nose, wings and tail. Its wings are flat (rise 0). Sizing by equal
-- target (outlines from above, side and behind, added) is gone (Alan 2026-11-18): flat skins over tall bodies grew far
-- wider and longer than the plane (up to 34% of the chase view against the plane's 8%).
local function evenFit(shape, o, id)
	local E, W = shape.even, shape.even.wing
	local lo0, hi0 = Vector3.one * math.huge, -Vector3.one * math.huge
	for name, piece in shape.pieces do
		-- Size and centre the Ninja by the hull. Its two loose scarf tips extend behind the tail.
		if shape.hitPiece == nil or name == shape.hitPiece then
			lo0, hi0 = lo0:Min(v3(piece.min)), hi0:Max(v3(piece.max))
		end
	end
	-- As much of the chase view as the plain plane (Alan 2026-11-19: "as long or as wide as the plane, whichever comes
	-- first" of 2026-11-18 was too small), as a measured multiple of its wingspan; never stretched. A thinner or thicker
	-- target than the plane is fine ("it's just cosmetic"). A mix not measured keeps the length-or-wingspan size; lengths
	-- from the hit piece (the Ninja's scarf trails past it).
	local size = SkinFit.screenSize(id, o.build)
	local k = size and o.xo / E.half_span * size or math.min((o.zT - o.zN) / (hi0.Z - lo0.Z), o.xo / E.half_span)
	local midZ = (lo0.Z + hi0.Z) / 2
	local function at(p) return Vector3.new(p.X * k, o.wy + (p.Y - E.wing_y) * k, (o.zN + o.zT) / 2 + (p.Z - midZ) * k) end
	local out = {}
	for name, piece in shape.pieces do
		local lo, hi = v3(piece.min), v3(piece.max)
		out[name] = { CFrame.new(at((lo + hi) / 2)), (hi - lo) * k }
	end
	-- crane_skin.py's wing_under() for a wing seen from above as a triangle (root front, root back, tip): the spot under
	-- the wing nearest (x, z), clear of the body's side, `half` (half the gun's length) inside the wing front and back.
	local span, uMin = W.tip_x - W.root_x, (E.body_x - W.root_x) / (W.tip_x - W.root_x) + 0.05
	local function under(x, z, half)
		local u = clamp((math.abs(x) / k - W.root_x) / span, uMin, 0.7)
		local front, back = W.front_z + u * (W.tip_z - W.front_z), W.back_z + u * (W.tip_z - W.back_z)
		local m = half / k + 0.1 * (W.back_z - W.front_z) * (1 - u)
		local w = front + m <= back - m and clamp(midZ + (z - (o.zN + o.zT) / 2) / k, front + m, back - m) or (front + back) / 2
		local p = at(Vector3.new(W.root_x + u * span, W.under_y, w))
		return Vector3.new(x < 0 and -p.X or p.X, p.Y - 0.02 * k, p.Z)
	end
	-- Hang a gun under the drawn skin (Alan 2026-11-19: guns floated under the skins and their clips showed from above):
	-- the nearest spot to `want` (under()'s) where its clip (the parts reaching its top, clipLo..clipHi) is fully under
	-- the skin seen from above, clear of the guns already hung on that side (`taken`), on its own side of the middle and
	-- at most 70% of the way out (under the skin's body if nothing on the wing covers it); its top touching the lowest
	-- underside over the clip, tilted to the underside's slope (at most 15 degrees). Returns the gun top's spot and its
	-- turn (nil: no grid, or no part of the clip under the skin anywhere).
	local grid = gridOf(id)
	local zMid = (o.zN + o.zT) / 2
	local xHi = W.root_x + 0.7 * span
	local function hang(want, lo, hi, clipLo, clipHi, taken)
		if not grid then return nil end
		local side, step = want.X < 0 and -1 or 1, grid.step
		local hx, hz = (hi.X - lo.X) / 2 / k, (hi.Z - lo.Z) / 2 / k
		local ox = ((clipLo.X + clipHi.X) / 2 - (lo.X + hi.X) / 2) / k * side
		local oz = ((clipLo.Z + clipHi.Z) / 2 - (lo.Z + hi.Z) / 2) / k
		local cx, cz = (clipHi.X - clipLo.X) / 2 / k, (clipHi.Z - clipLo.Z) / 2 / k
		-- The clip's cells at gun centre (x, z), centres within `grow` of it; `all`: nil if one has nothing above.
		local function cells(x, z, all, grow)
			local list = {}
			for i = math.ceil((x + ox - cx - grow - grid.x0) / step + 0.5), math.floor((x + ox + cx + grow - grid.x0) / step + 0.5) do
				local column = grid.cols[i]
				for j = math.ceil((z + oz - cz - grow - grid.z0) / step + 0.5), math.floor((z + oz + cz + grow - grid.z0) / step + 0.5) do
					local y = column and column[j]
					if y then table.insert(list, Vector3.new(grid.x0 + (i - 0.5) * step - x, y, grid.z0 + (j - 0.5) * step - z))
					elseif all then return nil end
				end
			end
			return #list > 0 and list or nil
		end
		local wx, wz = math.abs(want.X) / k, midZ + (want.Z - zMid) / k
		local xLo = hx + 0.02
		local x, z, list
		for _, d in NEAR do
			local tx, tz = wx + d.X, wz + d.Y
			if tx < xLo or tx > xHi then continue end
			local clear = true
			for _, t in taken do
				if math.abs(tx - t[1]) < hx + t[3] + 0.05 and math.abs(tz - t[2]) < hz + t[4] + 0.05 then clear = false; break end
			end
			if clear and cells(tx, tz, true, step / 2) then x, z = tx, tz; break end
		end
		if not x then
			-- Nowhere hides the whole clip (longer than the wing there): where it hangs across the span, centred on the wing
			-- front to back (Alan 2026-11-19: a long gun may stick out, never half off one edge with room on the other).
			-- The wing's middle front to back, averaged over the columns under the clip (a swept wing slants across it).
			x, z = clamp(wx, xLo, xHi), wz
			local sum, count = 0, 0
			for i = math.ceil((x + ox - cx - grid.x0) / step + 0.5), math.floor((x + ox + cx - grid.x0) / step + 0.5) do
				local column = grid.cols[i]
				local j = math.floor((wz + oz - grid.z0) / step) + 1
				if not column then continue end
				for reach = 0, #column do -- the nearest cell under the skin
					if column[j - reach] then j -= reach; break elseif column[j + reach] then j += reach; break end
				end
				if column[j] then
					local first, last = j, j
					while column[first - 1] do first -= 1 end
					while column[last + 1] do last += 1 end
					sum, count = sum + grid.z0 + (first - 1 + last) / 2 * step, count + 1
				end
			end
			if count > 0 then z = sum / count - oz end
		end
		-- It touches by the clip itself (a round top only reaches its box's top along its middle): the cells inside it, or
		-- the nearest one to its middle.
		list = cells(x, z, false, 0) or cells(x, z, false, step / 2) or cells(x, z, false, step)
		if not list then return nil end
		table.insert(taken, { x, z, hx, hz })
		-- The underside's slope over the clip (least squares), then the lowest point under that slope.
		local n, sx, sz, sy, sxx, szz, sxz, sxy, szy = #list, 0, 0, 0, 0, 0, 0, 0, 0
		for _, c in list do
			sx += c.X; sz += c.Z; sy += c.Y; sxx += c.X * c.X; szz += c.Z * c.Z; sxz += c.X * c.Z; sxy += c.X * c.Y; szy += c.Z * c.Y
		end
		local mx, mz, my = sx / n, sz / n, sy / n
		local vxx, vzz, vxz, vxy, vzy = sxx / n - mx * mx, szz / n - mz * mz, sxz / n - mx * mz, sxy / n - mx * my, szy / n - mz * my
		local det = vxx * vzz - vxz * vxz
		local b = det > 1e-9 and clamp((vxy * vzz - vzy * vxz) / det, -MAX_TILT, MAX_TILT) or 0
		local c = det > 1e-9 and clamp((vzy * vxx - vxy * vxz) / det, -MAX_TILT, MAX_TILT) or 0
		local y = math.huge
		for _, q in list do y = math.min(y, q.Y - b * q.X - c * q.Z) end
		local spot = at(Vector3.new(x, y - 0.01, z)) -- a hair inside, so no sliver of light shows
		return Vector3.new(side * spot.X, spot.Y, spot.Z), CFrame.Angles(0, 0, math.atan(side * b)) * CFrame.Angles(-math.atan(c), 0, 0)
	end
	local keel = {}
	for i, p in E.keel do keel[i] = at(Vector3.new(0, p[1], p[2])) end
	return out, under, 0, at(Vector3.new(W.root_x, E.wing_y, (W.front_z + W.back_z) / 2)), bellyOf(keel), hang
end

-- Where each piece goes (crane_skin.py crane()): CFrame and Size in the plane's frame, plus what the guns need and the
-- right wing's hinge (the left one mirrors it in x).
function SkinFit.fit(shape, o, id)
	if shape.even then return evenFit(shape, o, id) end
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
	-- The stretched body's belly down its middle (ref.keel).
	local keel = {}
	for i, p in ref.keel do keel[i] = body(Vector3.new(0, p[1], p[2])) end
	return out, under, rise, hinge, bellyOf(keel)
end

-- Everything shape skin `id` moves on this plane (frame = its Root), in the plane's frame: the pieces to draw (and, when
-- `covers`, to hit), and where
-- each real wing part and gun part goes (`move * frame:ToObjectSpace(part.CFrame)`, same size). A wing part turns
-- about its side's hinge line (front to back), tip up by the skin's rise; a gun hangs under the drawn wing by its top
-- (hang_guns()): it keeps its spot seen from above and rolls with the wing. The booster's parts move straight up or down
-- together, never turned, until its top touches the belly (Alan 2026-11-14: it floated below the crane); its tape
-- strap wraps the body, so the strap's top tucks inside. `offsets[slot]`: how far that gun's top moved; `hinge`: the
-- right wing's hinge (the left one mirrors it in x). nil when `id` has no shape or the plane's parts aren't there yet.
function SkinFit.plane(id, appearance, frame)
	local shape = type(id) == "string" and Shapes[id]
	local o = shape and appearance and SkinFit.outline(appearance, frame)
	if not o then return nil end
	local placed, under, rise, hinge, belly, hang = SkinFit.fit(shape, o, id)
	local result, guns, boosters = { placed = placed, wings = {}, guns = {}, boosters = {}, offsets = {}, hinge = hinge,
		covers = shape.even ~= nil }, {}, {} -- covers: the skin's pieces are the hit and crash shapes of the body, nose, wings and tail
	for _, part in appearance:GetChildren() do
		if not part:IsA("BasePart") or part:GetAttribute("SkinPiece") then continue end
		local mount = tonumber(string.match(part.Name, "^Mount(%d+)"))
		local slot = string.match(part.Name, "^(%a+)")
		if slot == "wings" then
			local left = frame:PointToObjectSpace(part.Position).X < 0
			local at = left and hinge * Vector3.new(-1, 1, 1) or hinge
			result.wings[part] = CFrame.new(at) * CFrame.Angles(0, 0, left and -rise or rise) * CFrame.new(-at)
		elseif slot == "Booster" then table.insert(boosters, part)
		elseif mount then guns[mount] = guns[mount] or {}; table.insert(guns[mount], part) end
	end
	-- ponytail: each part's box top against the belly's middle, over the middle 60% of its length (the parts' ends round
	-- off): within 0.04 of touching, mesh against mesh, on all 18 body and booster builds (2026-11-14). Read the meshes'
	-- tops instead if a new booster's top isn't flat down its middle.
	local lift
	for _, part in boosters do
		if string.match(part.Name, "%-tape$") then continue end
		local lo, hi = box(part, frame)
		local trim = (hi.Z - lo.Z) * 0.2
		local y = belly(lo.Z + trim, hi.Z - trim)
		if y then lift = math.min(lift or math.huge, y - hi.Y) end
	end
	if lift then for _, part in boosters do result.boosters[part] = CFrame.new(0, lift, 0) end end
	-- Inner guns first, so an outer one finds the inner one's spot taken.
	local order = {}
	for mount, parts in guns do
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, part in parts do
			local p = frame:PointToObjectSpace(part.Position)
			lo, hi = lo:Min(p - part.Size / 2), hi:Max(p + part.Size / 2)
		end
		table.insert(order, { mount = mount, parts = parts, lo = lo, hi = hi })
	end
	table.sort(order, function(a, b) return math.abs(a.lo.X + a.hi.X) < math.abs(b.lo.X + b.hi.X) end)
	local taken = { {}, {} }
	for _, gun in order do
		local mount, parts, lo, hi = gun.mount, gun.parts, gun.lo, gun.hi
		local top = Vector3.new((lo.X + hi.X) / 2, hi.Y, (lo.Z + hi.Z) / 2)
		local to = under(top.X, top.Z, (hi.Z - lo.Z) / 2)
		local turn = CFrame.Angles(0, 0, to.X < 0 and -rise or rise)
		local clip = Clips[parts[1]:GetAttribute("Look") or ""]
		if hang and clip then
			-- The clip (the patch of its top that touches: the cup's base and strap, the cradle's floor, the crayon's band),
			-- from the weapon's measured shares of its box; a right-side gun is the left one mirrored.
			local u0, u1 = clip[1], clip[2]
			if (lo.X + hi.X) / 2 > 0 then u0, u1 = 1 - clip[2], 1 - clip[1] end
			local clipLo = Vector3.new(lo.X + u0 * (hi.X - lo.X), hi.Y, lo.Z + clip[3] * (hi.Z - lo.Z))
			local clipHi = Vector3.new(lo.X + u1 * (hi.X - lo.X), hi.Y, lo.Z + clip[4] * (hi.Z - lo.Z))
			local spot, tilt = hang(to, lo, hi, clipLo, clipHi, taken[to.X < 0 and 1 or 2])
			if spot then to, turn = spot, tilt end
		end
		local move = CFrame.new(to) * turn * CFrame.new(-top)
		result.offsets[mount] = to - top
		for _, part in parts do result.guns[part] = move end
	end
	return result
end

return SkinFit
