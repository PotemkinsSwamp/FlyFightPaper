local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Config = require(Root.Generated.Trails)
local PlaneTrails = require(game.StarterPlayer.StarterPlayerScripts.FlyFightPaper.PlaneTrails)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
function Spec.run()
	local result, test = Suite.new()
	test("every trail row is one the game can draw", function()
		local trails = 0
		for id, trail in Config.trails do
			trails += 1
			assert(trail.ribbons == nil and (#trail.pieces > 0 or trail.effect == "cloak"), id .. ": missing pieces or cloaking wake")
			for i, spec in trail.pieces do
				local name = id .. " piece " .. i
				-- a particle (one of Roblox's own pictures) with a particle look, or a part (plain shape or uploaded model) with a material
				local particle = PlaneTrails.pictures[spec.model] ~= nil
				assert(particle or PlaneTrails.plain[spec.model] or Config.meshes[spec.model] ~= nil, name .. ": a model the game cannot draw")
				assert(particle and PlaneTrails.lit[spec.look] or not particle and PlaneTrails.materials[spec.look], name .. ": a look the game cannot draw")
				assert(spec.align == nil or spec.align == true or spec.align == "grid", name .. ": align")
				assert(spec.rate > 0 and spec.spread >= 0 and spec.shrink >= 0 and #spec.colors > 0, name .. ": numbers")
				assert(spec.life[1] > 0 and spec.life[1] <= spec.life[2] and spec.life[2] <= Config.life, name .. ": lives at most the trail's second")
				assert(spec.size[1] > 0 and spec.size[1] <= spec.size[2], name .. ": sizes")
				assert(not spec.rainbow or PlaneTrails.rainbow(spec), name .. ": rainbow")
				assert(not (spec.light or spec.flash or spec.align or spec.upright or spec.jump or spec.level or spec.lattice or spec.run) or not particle, name .. ": only parts flash, light, stand up, jump, race, line up or lie along the path")
				assert(spec.axes == nil or (spec.align == "grid" and #spec.axes == 3 and spec.axes[1] + spec.axes[2] + spec.axes[3] > 0), name .. ": axes")
			end
		end
		assert(trails >= 18)
	end)
	test("Legendary effects have their source shapes, finishes and exhaust positions", function()
		local used = {}
		for _, model in { "ninja_star", "forked_flame", "wavelet", "upper_jaw", "lower_jaw", "droplet", "tread_shred", "cloak_stream" } do
			local mesh = Config.meshes[model]
			assert(type(mesh) == "number" and mesh > 0 and not used[mesh], model)
			used[mesh] = true
			if model ~= "cloak_stream" then assert(Config.meshTextures[model] > 0, model) end
		end
		assert(Config.trails.water_spray.effect == "shark_jet" and Config.trails.photo_finish.effect == "grinding_sparks")
		assert(Config.trails.silver_chaff.effect == "cloak" and #Config.trails.silver_chaff.pieces == 0)
		assert(PlaneTrails.materials.steel == Enum.Material.Metal and PlaneTrails.materials.incandescent == Enum.Material.Neon)
		for _, id in { "smoke_bomb", "backfire", "water_spray", "silver_chaff", "photo_finish" } do
			local tail = Config.trails[id].tail
			assert(#tail == 2 and tail[1] >= 0 and tail[1] < 0.2 and tail[2] > 0.3 and tail[2] <= 0.5, id)
		end
	end)
	test("a jumping piece keeps one of five sideways places for an eighth of a second", function()
		local seen = {}
		for i = 0, 400 do
			local at = PlaneTrails.snap(37.5, i / 8 + 0.01)
			assert(at == PlaneTrails.snap(37.5, i / 8 + 0.11) and at >= -1 and at <= 1 and at * 2 == math.floor(at * 2))
			seen[at] = true
		end
		for _, at in { -1, -0.5, 0, 0.5, 1 } do assert(seen[at], "never at " .. at) end
	end)
	test("a piece grows out of the tail, then shrinks or swells to its end size", function()
		for _, shrink in { 0.2, 1, 1.7 } do
			local spec = { shrink = shrink, size = { 2, 4 } }
			assert(PlaneTrails.sizeAt(spec, 0) == 0 and math.abs(PlaneTrails.sizeAt(spec, Config.grow_in) - 1) < 1e-9)
			assert(math.abs(PlaneTrails.sizeAt(spec, 1) - shrink) < 1e-9)
			local sizes = PlaneTrails.sizes(spec, 1.3).Keypoints
			assert(sizes[1].Time == 0 and sizes[1].Value == 0 and sizes[#sizes].Time == 1 and #sizes <= 20)
			assert(math.abs(sizes[#sizes].Value - 3 * 1.3 * shrink) < 1e-4 and math.abs(sizes[#sizes].Envelope - 1.3 * shrink) < 1e-4)
		end
	end)
	test("a trail grows only when the plane is faster than its build, up to the limit", function()
		assert(PlaneTrails.growth(50, 100) == 1 and PlaneTrails.growth(100, 100) == 1)
		assert(math.abs(PlaneTrails.growth(100 * Config.fast_at, 100) - Config.fast_growth) < 1e-9 and PlaneTrails.growth(900, 100) == Config.fast_growth)
		local half = PlaneTrails.growth(100 * (1 + Config.fast_at) / 2, 100)
		assert(half > 1 and half < Config.fast_growth)
	end)
	test("a rainbow runs through its colours the given times and ends where it began", function()
		local spec = { rainbow = 3, colors = { { 255, 0, 0 }, { 0, 255, 0 }, { 0, 0, 255 } } }
		local points = PlaneTrails.rainbow(spec).Keypoints
		assert(#points == 10 and points[1].Value == points[10].Value and points[1].Value == points[4].Value and points[2].Value == Color3.fromRGB(0, 255, 0))
		spec.rainbow = 7
		assert(not pcall(PlaneTrails.rainbow, spec), "more colour steps than Roblox takes must fail loudly")
	end)
	return result
end
return Spec
