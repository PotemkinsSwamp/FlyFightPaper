-- The Range's lead ring, fired at for real (Alan 2026-10-20): every row, difficulty and steady weapon, 40 moments along
-- each target's path. Each shot is aimed exactly at the ring (CombatRules.lead, as FlightHUD draws it), flown with the
-- server's own shot motion (CombatRules.shotOffset, 60 steps a second, as CombatService) from a gun beside the plane,
-- and judged on the target's card (HitShapes) where its path puts it at that moment.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.CombatRules)
local Course = require(Root.Shared.TrainingCourse)
local Aircraft = require(Root.Shared.Aircraft)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog))
local HitShapes = require(game.ServerScriptService.FlyFightPaper.HitShapes)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}
local MOMENTS, STEP = 40, 1 / 60
local MUZZLE = Vector3.new(3, -1, -2) -- a wing gun's spot next to the plane's middle

-- `blocked(from, delta)`: optional, true when the stage stops the shot first (the Edit check passes the real stage).
function Spec.measure(blocked)
	local seat = (Course.RANGE.origin * CFrame.new(Course.RANGE.seat)).Position
	local card = Instance.new("Model");card:SetAttribute("RangeTarget", "red")
	local rows = {}
	for _, weapon in Catalog.weapons do
		if weapon.homing or weapon.spread_deg > 0 then continue end -- erasers seek; spread misses on purpose
		local size, rotation = Aircraft.projectile(weapon.id, false)
		size, rotation = size or Vector3.one * weapon.projectile_radius * 2, rotation or CFrame.identity
		for level in Course.DIFFICULTY do
			for i, base in Course.RANGE.targets do
				local spec = Course.difficulty(base, level)
				local center, side = Course.RANGE.origin * spec.at, Course.RANGE.origin.RightVector
				local key = weapon.id .. " " .. level .. " " .. spec.row
				local row = rows[key] or { hits = 0, shots = 0, far = 0, blocked = 0, worst = 0 }
				rows[key] = row
				for k = 1, MOMENTS do
					local t0 = k * 0.77 + i
					local function at(t) return Course.pose(spec, center, t0 + t, seat, side) end
					local lead = Rules.lead(weapon, seat, function(t) return at(t).Position end)
					if Rules.travelTime(weapon, (lead - seat).Magnitude) == math.huge then row.far += 1;continue end
					local muzzle = seat + MUZZLE
					local direction = (lead - muzzle).Unit
					row.shots += 1
					local previous, landed, near = muzzle, false, math.huge
					for n = 1, math.ceil(weapon.lifetime / STEP) do
						local position = muzzle + Rules.shotOffset(weapon, direction, n * STEP)
						local delta = position - previous
						if blocked and blocked(previous, delta) then row.blocked += 1;break end
						local pose = at(n * STEP)
						near = math.min(near, (pose.Position - position).Magnitude)
						if HitShapes.cast({ model = card }, pose, previous, delta, size, rotation) then landed = true;break end
						previous = position
					end
					if landed then row.hits += 1 else row.worst = math.max(row.worst, near) end
				end
			end
		end
	end
	card:Destroy()
	return rows
end

function Spec.run()
	local result, test = Suite.new()
	test("a shot aimed dead on the lead ring hits every Range target, every row, difficulty and steady weapon", function()
		local misses = {}
		for key, row in Spec.measure() do
			if row.hits < row.shots then table.insert(misses, string.format("%s %d/%d (closest miss %.1f studs)", key, row.hits, row.shots, row.worst)) end
		end
		table.sort(misses)
		assert(#misses == 0, table.concat(misses, "; "))
	end)
	return result
end
return Spec
