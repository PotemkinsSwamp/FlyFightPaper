"""Rewrite tests/unit/SkinMotion.spec.luau with the preview tool's own numbers, after config/skin-motion.json changes:
    python tools/art/skin_motion_spec.py      (from the project folder)
The spec holds where tools/art/skin_motion.py puts every Rare layer at a few moments; the game's src/shared/SkinMotion.luau
must give the same, so the game moves the way the preview videos Alan approved do."""
import sys, json
sys.path.insert(0, "tools/art"); sys.argv = ["x"]
import skin_motion as sm
rows, hidden = [], []
for skin, spec in sm.SPEC["skins"].items():
    for i, layer in enumerate(spec["layers"], 1):
        times = [0.37, 3.3, 7.9]
        if "loop" in layer: times = [layer["at"][0] + 0.05, layer["at"][-1] + 0.2, layer["at"][0] + 0.6]
        for t in times:
            m, solid, g = sm.state(layer, t)
            if m is None: hidden.append((skin, i, t)); continue
            rows.append('{ "%s", %d, %s, %s }' % (skin, i, repr(round(t, 4)), ", ".join("%.7f" % x for x in (m[0] + m[1] + [solid, g]))))
        if "loop" in layer: hidden.append((skin, i, layer["loop"] - 0.01)) if sm.state(layer, layer["loop"] - 0.01)[0] is None else None
base = ['{ "%s", %s, %.7f }' % (skin, repr(t), sm.glow(spec.get("glow"), t)) for skin, spec in sm.SPEC["skins"].items() for t in (0.4, 2.65)]
spec = '''local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local SkinMotion = require(Root.Shared.SkinMotion)
local Pictures = require(Root.Generated.SkinPictures).pictures
local Looks = require(Root.Generated.Looks)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
-- What tools/art/skin_motion.py (the preview videos Alan approved) works out: { skin, layer, time, the sheet-to-picture
-- map (a, b, tx, c, d, ty), how solid, glow }. Written by tools/art/skin_motion_spec.py; run it again when config/skin-motion.json changes.
local SAME = {
	%s,
}
local HIDDEN = { %s }
local BASE = { %s }
-- Where a Decal with these settings puts the picture, for a spot (u, v) on the piece's box seen from above: the box's
-- far right corner is 0, 0 (both measured in Studio, lessons.md "Moving skin layers").
local function drawn(sx, sy, ox, oy, rot, u, v)
	local cos, sin, x, y = math.cos(math.rad(rot)), math.sin(math.rad(rot)), sx * (u - 0.5), sy * (v - 0.5)
	return 0.5 * sx + ox + cos * x + sin * y, 0.5 * sy + oy - sin * x + cos * y
end
function Spec.run()
	local result, test = Suite.new()
	test("every Rare layer sits and glows where the approved preview put it", function()
		for _, v in SAME do
			local layer = SkinMotion.skins[v[1]].layers[v[2]]
			local got = { SkinMotion.state(layer, v[3]) }
			local label = v[1] .. " " .. layer.name .. " at " .. v[3]
			assert(got[1], label .. " is hidden")
			for i = 1, 8 do assert(math.abs(got[i] - v[3 + i]) < 1e-4, label .. " value " .. i .. ": " .. got[i] .. " ~= " .. v[3 + i]) end
			-- on real pieces (a wing turned half round like the game's, one not turned, one turned a quarter) the Decal
			-- settings put every box spot's picture where the sheet says: box spot -> plane studs -> sheet -> picture
			for _, frame in { CFrame.new(-3.4, 0.9, 1.4) * CFrame.Angles(0, math.pi, 0), CFrame.new(2, 0, -3), CFrame.new(1, 0, 4) * CFrame.Angles(0, math.pi / 2, 0) } do
				local size = Vector3.new(6.8, 0.2, 8.0)
				local sx, sy, ox, oy, rot = SkinMotion.decal(SkinMotion.piece(frame, size), got[1], got[2], got[3], got[4], got[5], got[6])
				for _, spot in { { 0.5, 0.5 }, { 0.1, 0.8 }, { 0.9, 0.3 } } do
					local at = frame * Vector3.new((0.5 - spot[1]) * size.X, 0, (0.5 - spot[2]) * size.Z)
					local u, w = 0.35707 + 0.039473 * at.X, 0.39087 + 0.039473 * at.Z
					local px, py = drawn(sx, sy, ox, oy, rot, spot[1], spot[2])
					assert(math.abs(px - (got[1] * u + got[2] * w + got[3])) < 1e-4 and math.abs(py - (got[4] * u + got[5] * w + got[6])) < 1e-4, label .. " lands wrong on a piece")
				end
			end
		end
		for _, v in HIDDEN do assert(SkinMotion.state(SkinMotion.skins[v[1]].layers[v[2]], v[3]) == nil, v[1] .. " layer " .. v[2] .. " should be hidden") end
		for _, v in BASE do assert(math.abs(SkinMotion.glow(SkinMotion.skins[v[1]].glow, v[2]) - v[3]) < 1e-4, v[1] .. " sheet glow") end
	end)
	test("every sliding layer ends its loop where it began and every layer has its uploaded picture", function()
		local rares = 0
		for _, skin in Looks.skins do
			local spec = SkinMotion.skins[skin.id]
			assert((skin.tier == "rare") == (spec ~= nil), skin.id .. ": every Rare moves and only Rares do")
			if spec then
				rares += 1
				assert(skin.picture == Pictures[skin.id] and (not spec.glow or Pictures[skin.id .. "-glow"]), skin.id .. " still sheet")
				for _, layer in spec.layers do
					assert(Pictures[skin.id .. "-" .. layer.name], skin.id .. " " .. layer.name .. " has no picture")
					if layer.kind == "slide" then
						local a, b = { SkinMotion.state(layer, 0) }, { SkinMotion.state(layer, math.abs(layer.period)) }
						local half = { SkinMotion.state(layer, math.abs(layer.period) / 2) }
						assert(math.abs(a[3] - b[3]) < 1e-9 and math.abs(a[6] - b[6]) < 1e-9, skin.id .. " " .. layer.name .. " jumps at the end of its loop")
						assert(a[3] ~= half[3] or a[6] ~= half[6], skin.id .. " " .. layer.name .. " does not move")
						-- a sliding picture never leaves its own edge (a Decal's picture smears past it)
						for _, s in { a, half } do assert(s[3] >= -1e-9 and s[6] >= -1e-9 and s[3] + s[1] <= 1 + 1e-9 and s[6] + s[5] <= 1 + 1e-9, skin.id .. " " .. layer.name .. " leaves its picture") end
					end
				end
			end
		end
		assert(rares == 8 and SkinMotion.near == 200)
	end)
	return result
end
return Spec
''' % (",\n\t".join(rows), ", ".join('{ "%s", %d, %s }' % h for h in hidden if h), ", ".join(base))
open("tests/unit/SkinMotion.spec.luau", "w", encoding="utf-8", newline="\n").write(spec); print(len(rows), "rows", len([h for h in hidden if h]), "hidden")
