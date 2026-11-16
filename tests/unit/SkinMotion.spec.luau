local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local SkinMotion = require(Root.Shared.SkinMotion)
local Pictures = require(Root.Generated.SkinPictures).pictures
local Looks = require(Root.Generated.Looks)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
-- What tools/art/skin_motion.py (the preview videos Alan approved) works out: { skin, layer, time, the sheet-to-picture
-- map (a, b, tx, c, d, ty), how solid, glow }. Written by tools/art/skin_motion_spec.py; run it again when config/skin-motion.json changes.
local SAME = {
	{ "lava", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.2436207, 1.0000000, 0.4033626 },
	{ "lava", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.1931034, 1.0000000, 0.5274531 },
	{ "lava", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.1137931, 1.0000000, 0.3540013 },
	{ "lava", 2, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.0000000 },
	{ "lava", 2, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.0000000 },
	{ "lava", 2, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.0000000 },
	{ "galaxy", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4936207, 1.0000000, 0.9865169 },
	{ "galaxy", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4431034, 1.0000000, 0.4743517 },
	{ "galaxy", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.3637931, 1.0000000, 1.2745494 },
	{ "galaxy", 2, 0.37, 4.2229800, 1.1157594, -0.9260381, -1.1157594, 4.2229800, -1.4240783, 1.0000000, 1.1000000 },
	{ "galaxy", 2, 3.3, -2.9226901, 3.2459762, -0.5594677, -3.2459762, -2.9226901, 2.6478338, 1.0000000, 1.1000000 },
	{ "galaxy", 2, 7.9, 3.1419984, -3.0341926, 1.4070615, 3.0341926, 3.1419984, -1.7165065, 1.0000000, 1.1000000 },
	{ "galaxy", 3, 0.37, 4.3078089, -0.7219842, -1.3336551, 0.7219842, 4.3078089, -2.0628642, 1.0000000, 1.1000000 },
	{ "galaxy", 3, 3.3, 0.3915348, -4.3503080, 2.5154839, 4.3503080, 0.3915348, -1.9224757, 1.0000000, 1.1000000 },
	{ "galaxy", 3, 7.9, -4.0163978, 1.7166908, 1.6781466, -1.7166908, -4.0163978, 3.4227615, 1.0000000, 1.1000000 },
	{ "galaxy", 4, 1.05, 2.4898670, 3.4100353, -1.7484309, -3.4100353, 2.4898670, -0.7153733, 0.2777778, 1.6000000 },
	{ "galaxy", 4, 12.2, -3.4255820, 2.4684341, 1.1277990, -2.4684341, -3.4255820, 1.8389252, 1.0000000, 1.6000000 },
	{ "galaxy", 4, 1.6, 2.4898670, 3.4100353, -1.7484309, -3.4100353, 2.4898670, 0.2380383, 1.0000000, 1.6000000 },
	{ "slime", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4962475, 1.0000000, 0.2644400 },
	{ "slime", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4665314, 1.0000000, 0.4794137 },
	{ "slime", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4198783, 1.0000000, 0.2774764 },
	{ "slime", 2, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4920259, 1.0000000, 0.5155600 },
	{ "slime", 2, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4288793, 1.0000000, 0.3005863 },
	{ "slime", 2, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.3297414, 1.0000000, 0.5025236 },
	{ "holographic", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.2020725, 1.0000000, 0.0000000 },
	{ "holographic", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.0725389, 1.0000000, 0.0000000 },
	{ "holographic", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.2266839, 1.0000000, 0.0000000 },
	{ "holographic", 2, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.2500000, 0.6945000, 1.0000000, 1.2000000 },
	{ "holographic", 2, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.2500000, 0.2550000, 1.0000000, 1.2000000 },
	{ "holographic", 2, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.2500000, 0.3150000, 1.0000000, 1.2000000 },
	{ "glitch", 1, 0.55, 1.0000000, 0.0000000, 0.0200000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.9000000 },
	{ "thunderstorm", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4893678, 1.0000000, 0.0000000 },
	{ "thunderstorm", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4051724, 1.0000000, 0.0000000 },
	{ "thunderstorm", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.2729885, 1.0000000, 0.0000000 },
	{ "thunderstorm", 2, 0.85, 2.2960195, 1.0706515, -0.4772305, -1.0706515, 2.2960195, -0.4017088, 1.0000000, 2.0000000 },
	{ "thunderstorm", 2, 10.1, -2.4470545, 0.6556863, 0.7538476, -0.6556863, -2.4470545, 1.9658701, 1.0000000, 2.0000000 },
	{ "thunderstorm", 2, 1.4, 2.2960195, 1.0706515, -0.4772305, -1.0706515, 2.2960195, -0.4017088, 0.0571429, 0.1142857 },
	{ "circuit_board", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.4574713, 1.0000000, 1.1000000 },
	{ "circuit_board", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.1206897, 1.0000000, 1.1000000 },
	{ "circuit_board", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.5000000, 0.0919540, 1.0000000, 1.1000000 },
	{ "circuit_board", 2, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 1.2634103 },
	{ "circuit_board", 2, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.9817627 },
	{ "circuit_board", 2, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 1.0000000, 0.0000000, 1.0000000, 0.1432373 },
	{ "comic_book", 1, 0.37, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.1215278, 1.0000000, 0.0000000 },
	{ "comic_book", 1, 3.3, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.1041667, 1.0000000, 0.0000000 },
	{ "comic_book", 1, 7.9, 1.0000000, 0.0000000, 0.0000000, 0.0000000, 0.7500000, 0.0069444, 1.0000000, 0.0000000 },
	{ "comic_book", 2, 0.35, 2.5880323, -0.4563399, 0.2103167, 0.4563399, 2.5880323, -0.9311820, 1.0000000, 0.0000000 },
	{ "comic_book", 2, 0.5, 5.2508110, -0.9258597, -0.0472681, 0.9258597, 5.2508110, -2.3965638, 1.0000000, 0.7613004 },
	{ "comic_book", 2, 0.9, 4.6201658, -0.8146599, -0.0171438, 0.8146599, 4.6201658, -2.0549520, 1.0000000, 0.1235747 },
	{ "comic_book", 3, 2.85, 2.5880323, 0.4563399, -1.0585341, -0.4563399, 2.5880323, -0.6052915, 1.0000000, 0.0000000 },
	{ "comic_book", 3, 3.0, 5.2508110, 0.9258597, -2.6216160, -0.9258597, 5.2508110, -1.7496405, 1.0000000, 0.7613004 },
	{ "comic_book", 3, 3.4, 4.6201658, 0.8146599, -2.2823014, -0.8146599, 4.6201658, -1.4731708, 1.0000000, 0.1235747 },
	{ "comic_book", 4, 5.35, 2.6023818, 0.3657409, -0.2397532, -0.3657409, 2.6023818, -0.7790030, 1.0000000, 0.0000000 },
	{ "comic_book", 4, 5.5, 5.2799244, 0.7420450, -0.9601823, -0.7420450, 5.2799244, -2.1006640, 1.0000000, 0.7613004 },
	{ "comic_book", 4, 5.9, 4.6457826, 0.6529222, -0.8206105, -0.6529222, 4.6457826, -1.7832813, 1.0000000, 0.1235747 },
}
local HIDDEN = { { "galaxy", 4, 16.49 }, { "glitch", 1, 5.5 }, { "glitch", 1, 1.1 }, { "glitch", 1, 5.99 }, { "thunderstorm", 2, 12.99 }, { "comic_book", 2, 7.49 }, { "comic_book", 3, 7.49 }, { "comic_book", 4, 7.49 } }
local BASE = { { "lava", 0.4, 0.4120695 }, { "lava", 2.65, 0.8448120 }, { "galaxy", 0.4, 0.6193112 }, { "galaxy", 2.65, 1.0160751 }, { "slime", 0.4, 0.2774764 }, { "slime", 2.65, 0.1947469 }, { "holographic", 0.4, 0.0000000 }, { "holographic", 2.65, 0.0000000 }, { "glitch", 0.4, 0.4500000 }, { "glitch", 2.65, 0.9000000 }, { "thunderstorm", 0.4, 0.0000000 }, { "thunderstorm", 2.65, 0.0000000 }, { "circuit_board", 0.4, 0.9000000 }, { "circuit_board", 2.65, 0.9000000 }, { "comic_book", 0.4, 0.0000000 }, { "comic_book", 2.65, 0.0000000 } }
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
