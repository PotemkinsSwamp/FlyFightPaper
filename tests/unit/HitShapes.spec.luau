-- Plane hits (HitShapes.cast): a shot whose box already overlaps the plane where a server step starts still hits
-- (a cast alone never reports a part it starts touching), and the normal sweep still hits and misses as before.
local HitShapes = require(game.ServerScriptService.FlyFightPaper.HitShapes)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local SHOT = Vector3.new(0.5, 0.5, 2)

function Spec.run()
	local result, test = Suite.new()
	-- A plane stand-in: one 10 x 2 x 10 piece round its middle (no mesh, so its own box is the hit shape).
	local model = Instance.new("Model")
	local body = Instance.new("Part");body.Name = "Root";body.Size = Vector3.one;body.Parent = model
	local appearance = Instance.new("Folder");appearance.Name = "Appearance";appearance.Parent = model
	local wing = Instance.new("MeshPart");wing.Size = Vector3.new(10, 2, 10);wing.Parent = appearance
	local plane = { id = "hitshapes-spec", model = model, body = body }
	local pose = CFrame.new(40, 300, -20) * CFrame.Angles(0, 0.6, 0)
	local function cast(from, delta) return HitShapes.cast(plane, pose, pose * from, pose:VectorToWorldSpace(delta), SHOT, CFrame.identity) end
	test("a shot starting inside the plane hits at once", function()
		assert(cast(Vector3.new(0, 0, 3), Vector3.new(0, 0, 20)) == 0)
	end)
	test("a shot from outside hits where it reaches the plane", function()
		local t = cast(Vector3.new(0, 0, -30), Vector3.new(0, 0, 60))
		assert(t and math.abs(t * 60 - 24) < 0.1, tostring(t)) -- 30 out, minus 5 to the edge, minus 1 (half the shot)
	end)
	test("a shot passing above misses", function()
		assert(cast(Vector3.new(0, 4, -30), Vector3.new(0, 0, 60)) == nil)
	end)
	HitShapes.forget(plane)
	model:Destroy()
	return result
end
return Spec
