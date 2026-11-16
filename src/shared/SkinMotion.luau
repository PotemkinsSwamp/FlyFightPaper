-- Where a Rare skin's moving layers sit at a moment (skins plan, "Moving Rares"): the same sums as
-- tools/art/skin_motion.py, which plays them for the preview videos; the numbers are in config/skin-motion.json.
-- state() gives a layer's map from a spot on the printed sheet to a spot on the layer's picture; decal() turns that map
-- into a Roblox Decal's settings for one plane piece. A Decal ignores the piece's sheet layout: it stretches its picture
-- over the piece's own box seen from above, and lands it at turn(scale * (box spot - middle)) + scale * middle + offset
-- (both measured in Studio 2026-11-16, lessons.md "Moving skin layers"), so a placed picture's patch must be square.
local Motion = require(script.Parent.Parent.Generated.SkinMotion)
local SkinMotion = { skins = Motion.skins, near = Motion.near_studs }
local ST, TAU = Motion.studs, 2 * math.pi

-- Which scheduled event ({ loop, at = { start, ... } }) is playing and for how long; nil between events.
local function since(ev, t)
	local tt, best = t % ev.loop, nil
	for i, start in ev.at do
		if tt >= start and (not best or start > ev.at[best]) then best = i end
	end
	if best then return best, tt - ev.at[best] end
	return nil, 0
end
-- 0..1: a lightning double flash from each event (on, off, on, fade), or fully on for `hold` seconds.
local function flicker(ev, t)
	local i, s = since(ev, t)
	if not i then return 0 end
	if ev.hold then return s < ev.hold and 1 or 0 end
	return s < 0.07 and 1 or s < 0.13 and 0.12 or s < 0.27 and 1 or math.max(0, 1 - (s - 0.27) / 0.35)
end
-- A glow's strength at time t: steady, breathing between `low` of it and all of it, or flashing up from `floor`.
function SkinMotion.glow(g, t)
	if not g then return 0 end
	local s = g.strength
	if g.pulse then s *= g.pulse.low + (1 - g.pulse.low) * (0.5 - 0.5 * math.cos(TAU * (t / g.pulse.period + (g.pulse.phase or 0)))) end
	if g.flash then
		local floor = g.flash.floor or 0
		s *= floor + (1 - floor) * flicker(g.flash, t)
	end
	return s
end
-- Sheet -> picture for a square picture `size` studs wide, centred at plane studs (x, z), its top pointing along (du, dv).
local function placed(x, z, size, du, dv)
	local n = math.sqrt(du * du + dv * dv)
	if n == 0 then n = 1 end
	local k = 1 / (size * ST.per)
	local sin, cos, qu, qv = k * du / n, -k * dv / n, ST.u0 + ST.per * x, ST.v0 + ST.per * z
	return cos, sin, 0.5 - cos * qu - sin * qv, -sin, cos, 0.5 + sin * qu - cos * qv
end
-- What decal() needs to know about a plane piece: where its middle sits on the sheet and how its box (seen from above)
-- lies on the sheet. `frame` and `size` are the piece's own, in plane space (its template in Assets.AircraftPieces).
function SkinMotion.piece(frame, size)
	local right, back = frame.RightVector, -frame.LookVector
	return { ST.u0 + ST.per * frame.X, ST.v0 + ST.per * frame.Z,
		-ST.per * right.X * size.X, -ST.per * back.X * size.Z, -ST.per * right.Z * size.X, -ST.per * back.Z * size.Z }
end
-- A Decal's UVScale x, y, UVOffset x, y and Rotation on a piece, for the sheet -> picture map (a, b, tx, c, d, ty).
function SkinMotion.decal(piece, a, b, tx, c, d, ty)
	local g11, g12, g21, g22 = a * piece[3] + b * piece[5], a * piece[4] + b * piece[6], c * piece[3] + d * piece[5], c * piece[4] + d * piece[6]
	local sx = math.sqrt(g11 * g11 + g21 * g21)
	local sy = (g11 * g22 - g12 * g21) / sx
	return sx, sy, a * piece[1] + b * piece[2] + tx - 0.5 * sx, c * piece[1] + d * piece[2] + ty - 0.5 * sy, math.deg(math.atan2(-g21, g11))
end

-- A layer at time t: its sheet -> picture map (a, b, tx, c, d, ty: picture x = a * u + b * v + tx), how solid (0..1) and
-- its glow strength; nil while it is hidden.
function SkinMotion.state(layer, t)
	local kind, g = layer.kind, SkinMotion.glow(layer.glow, t)
	if kind == "still" then return 1, 0, 0, 0, 1, 0, 1, g end
	if kind == "slide" then
		local f, wob = (t / layer.period) % 1, layer.wobble
		local s = wob and math.sin(TAU * t / wob.period) or 0
		return layer.zoom[1], 0, layer.at[1] + layer.travel[1] * f + (wob and wob.amount[1] * s or 0),
			0, layer.zoom[2], layer.at[2] + layer.travel[2] * f + (wob and wob.amount[2] * s or 0), 1, g
	end
	local a, b, tx, c, d, ty
	if kind == "spin" then
		local turn = TAU * ((t / layer.period + (layer.phase or 0)) % 1)
		a, b, tx, c, d, ty = placed(layer.centre[1], layer.centre[2], layer.size, math.sin(turn), -math.cos(turn))
		return a, b, tx, c, d, ty, 1, g
	end
	if kind == "pass" then -- a picture crossing along a path, now and then
		local tt = t % layer.loop
		for i, start in layer.at do
			local f = (tt - start) / layer.time
			if f >= 0 and f < 1 then
				local p = layer.paths[(i - 1) % #layer.paths + 1]
				a, b, tx, c, d, ty = placed(p[1] + (p[3] - p[1]) * f, p[2] + (p[4] - p[2]) * f, layer.size, p[3] - p[1], p[4] - p[2])
				return a, b, tx, c, d, ty, math.min(1, f / 0.12, (1 - f) / 0.12), g
			end
		end
		return nil
	end
	local i, s = since(layer, t)
	if not i then return nil end
	if kind == "flash" then -- a picture that flickers at one of its spots (lightning)
		local f = flicker(layer, t)
		if f <= 0 then return nil end
		local spot = layer.spots[(i - 1) % #layer.spots + 1]
		local turn = math.rad(spot[3])
		a, b, tx, c, d, ty = placed(spot[1], spot[2], layer.size, math.sin(turn), -math.cos(turn))
		return a, b, tx, c, d, ty, f, g * f
	end
	if kind == "snap" then -- the whole layer jumps into view, shifted, for a moment (glitch)
		if s >= layer.hold then return nil end
		local shift = layer.shifts[(i - 1) % #layer.shifts + 1]
		return 1, 0, shift[1], 0, 1, shift[2], 1, g
	end
	if kind == "slam" then -- a word slams in big, squashes, shakes, holds, fades (comic)
		local hit, hold = 0.14, layer.hold
		if s >= hit + hold + 0.3 then return nil end
		local size = s < hit and 1 + 1.9 * (1 - s / hit) ^ 2 or s < hit + 0.16 and 1 - 0.13 * math.sin(math.pi * (s - hit) / 0.16) or 1
		local shake = s >= hit and 0.28 * math.sin((s - hit) * 70) * math.max(0, 1 - (s - hit) / 0.3) or 0
		local turn = math.rad(layer.turn or 0)
		a, b, tx, c, d, ty = placed(layer.centre[1] + shake, layer.centre[2], layer.size * size, math.sin(turn), -math.cos(turn))
		return a, b, tx, c, d, ty, s < hit + hold and math.min(1, s / 0.05) or math.max(0, 1 - (s - hit - hold) / 0.3),
			g * (s >= hit and math.exp(-(s - hit) / 0.22) or 0)
	end
	error("SkinMotion: unknown layer kind " .. tostring(kind))
end

return SkinMotion
