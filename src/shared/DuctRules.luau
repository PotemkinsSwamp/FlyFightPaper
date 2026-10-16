-- Rules for the ceiling ducts (config world.ducts): where the spinning fans are, when a plane clips a blade, and
-- when the middle blower speeds a plane up. Pure: the server judges with them, the client spins blades to match.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Ducts = require(Root.Generated.Gameplay).world.ducts

local DuctRules = {}

-- The fan's frame: middle of the duct at its spot, looking along the duct. Blades turn in its local X-Y plane.
function DuctRules.fanFrame(spot)
	local at = Vector3.new(spot[1], Ducts.floor_y + Ducts.height / 2, spot[2])
	return CFrame.lookAt(at, at + (spot[3] == "x" and Vector3.xAxis or Vector3.zAxis))
end

-- How far fan `index` has turned (radians). Both sides use server time, so everyone sees the same blades.
function DuctRules.fanAngle(now, index)
	-- Wrapped to one turn first: server time is ~1.8 billion seconds and CFrame angles are 32-bit floats, so an
	-- unwrapped angle stops the blades moving at all.
	return (now * Ducts.fans.turns_per_second % 1) * 2 * math.pi + index
end

-- Did a plane whose middle went from `before` to `after` (both in the fan's frame) go through a blade or the hub?
-- Returns the push direction (in the fan's frame, the way the blades move) when it did.
function DuctRules.fanClip(before, after, angle)
	local F = Ducts.fans
	if (before.Z > 0) == (after.Z > 0) then return nil end
	local p = before:Lerp(after, before.Z / (before.Z - after.Z))
	local r = math.sqrt(p.X * p.X + p.Y * p.Y)
	if r > F.opening / 2 then return nil end -- the housing round the opening is solid
	local push = r > 0.01 and Vector3.new(-p.Y / r, p.X / r, 0) or Vector3.xAxis
	if r <= F.hub_radius + F.plane_margin then return push end
	local width = F.blade_width / 2 + F.plane_margin
	for k = 0, F.blades - 1 do
		local theta = angle + k * 2 * math.pi / F.blades
		local c, s = math.cos(theta), math.sin(theta)
		local along, across = p.X * c + p.Y * s, -p.X * s + p.Y * c
		if along > 0 and along <= F.reach and math.abs(across) <= width then return push end
	end
	return nil
end

-- Moving air: each fan's duct and the blower's duct, as boxes with the way the air blows and how strong it is.
local function room(name) return Vector3.new(Ducts.rooms[name][1], Ducts.floor_y + Ducts.height / 2, Ducts.rooms[name][2]) end
local WINDS = {}
local function addWind(a, b, flow, strength)
	local half = (b - a) / 2
	local size = Vector3.new(math.abs(half.X) * 2, Ducts.height, math.abs(half.Z) * 2):Max(Vector3.new(Ducts.width, 0, Ducts.width))
	table.insert(WINDS, { center = a + half, size = size, flow = flow, strength = strength })
end
for _, spot in ipairs(Ducts.fans.spots) do
	-- the fan's duct: the link whose straight line runs through the fan
	for _, link in ipairs(Ducts.links) do
		local a, b = room(link[1]), room(link[2])
		local at = Vector3.new(spot[1], a.Y, spot[2])
		if math.abs((at - a).Unit:Dot((b - a).Unit) - 1) < 1e-6 and (at - a).Magnitude < (b - a).Magnitude then
			addWind(a, b, (spot[3] == "x" and Vector3.xAxis or Vector3.zAxis) * spot[4], Ducts.fans.wind)
		end
	end
end
do
	local B = Ducts.blower
	local home, other = room(B.room), room(B.link[1] == B.room and B.link[2] or B.link[1])
	addWind(home, other, (other - home).Unit, B.wind)
end

-- The blower's frame: on its room's far wall, looking down its duct (blades turn in its X-Y plane).
function DuctRules.blowerFrame()
	local B = Ducts.blower
	local home, other = room(B.room), room(B.link[1] == B.room and B.link[2] or B.link[1])
	local out = (other - home).Unit
	local at = home - out * (Ducts.room / 2 - 14)
	return CFrame.lookAt(at, at + out)
end

-- Every stretch of moving air: { center, size, flow (unit), strength }.
function DuctRules.winds()
	return WINDS
end

-- Duct runs for veteran bots: up one vent, room to room, out another. Bots skip the ducts with fans and the round
-- pipe. A run starts out in the room on a line through the vent along its first duct, so the climb carries the plane
-- straight in (`approach` studs of open room needed there, inside the room's 155-stud wall margin bots keep); it
-- leaves low down the last duct and dives through the exit vent. Never across the solid grille hanging under a vent
-- (vent_hinge: the side it hangs from). Each run: { vent, exit, rooms, points = { Vector3... } }.
local World = require(Root.Generated.Gameplay).world
local B = Ducts.bot_runs
local function linkOf(a, b)
	for _, link in ipairs(Ducts.links) do
		if link[1] == a and link[2] == b or link[1] == b and link[2] == a then return link end
	end
	return nil
end
local function allowed(a, b)
	local link = linkOf(a, b)
	if not link then return false end
	local pipe = Ducts.pipe.link
	if (pipe[1] == a and pipe[2] == b) or (pipe[1] == b and pipe[2] == a) then return false end
	local ra, rb = room(a), room(b)
	for _, spot in ipairs(Ducts.fans.spots) do
		local at = Vector3.new(spot[1], ra.Y, spot[2])
		if (at - ra).Magnitude + (rb - at).Magnitude < (rb - ra).Magnitude + 1e-3 then return false end
	end
	return true
end
local function hinge(vent)
	local side = Ducts.vent_hinge[vent]
	return (side:sub(2) == "x" and Vector3.xAxis or Vector3.zAxis) * (side:sub(1, 1) == "+" and 1 or -1)
end
DuctRules.ventHinge = hinge
local function inRoom(p)
	return math.abs(p.X) <= World.width_studs / 2 - 155 and math.abs(p.Z) <= World.depth_studs / 2 - 155
end
local RUNS = {}
do
	local names = {}
	for name in pairs(Ducts.rooms) do table.insert(names, name) end
	table.sort(names)
	local isVent = {}
	for _, v in ipairs(Ducts.vents) do isVent[v] = true end
	for _, vent in ipairs(Ducts.vents) do
		for _, first in ipairs(names) do
			local along = allowed(vent, first) and (room(first) - room(vent)).Unit
			local at = room(vent)
			-- the climb comes in from behind the vent (-along), the dive leaves forward (out): neither under the grille
			if along and inRoom(at - along * (B.approach + 300)) and (-along):Dot(hinge(vent)) < 0.5 then
				-- shortest way from the first room on to each other vent, never back through the entry
				local from, queue = { [first] = vent, [vent] = false }, { first }
				local head = 1
				while queue[head] do
					local here = queue[head]
					head += 1
					for _, next in ipairs(names) do
						if from[next] == nil and allowed(here, next) then from[next] = here; table.insert(queue, next) end
					end
				end
				for _, exit in ipairs(Ducts.vents) do
					if exit ~= vent and from[exit] then
						local rooms = { exit }
						while rooms[1] ~= vent do table.insert(rooms, 1, from[rooms[1]]) end
						local points = {
							Vector3.new(at.X, B.approach_y, at.Z) - along * (B.approach + 300),
							Vector3.new(at.X, B.approach_y + 30, at.Z) - along * B.approach,
						}
						for i = 1, #rooms - 1 do table.insert(points, room(rooms[i])) end
						local last = room(exit)
						local out = (last - room(rooms[#rooms - 1])).Unit
						if out:Dot(hinge(exit)) > 0.5 then continue end
						table.insert(points, Vector3.new(last.X, Ducts.floor_y + 35, last.Z) - out * Ducts.room / 2)
						table.insert(points, Vector3.new(last.X, B.exit_y, last.Z) + out * 30)
						table.insert(RUNS, { vent = vent, exit = exit, rooms = rooms, points = points })
					end
				end
			end
		end
	end
end

-- Every duct run a bot can take (see above).
function DuctRules.botRuns()
	return RUNS
end

-- Speed factor from moving air for a plane at `position` flying along `look`: up to 1 + strength with the air,
-- down to 1 - strength x headwind_share against it, 1 anywhere still.
function DuctRules.wind(position, look)
	local factor = 1
	for _, w in ipairs(WINDS) do
		local d = position - w.center
		if math.abs(d.X) <= w.size.X / 2 and math.abs(d.Y) <= w.size.Y / 2 and math.abs(d.Z) <= w.size.Z / 2 then
			local along = look:Dot(w.flow)
			factor *= 1 + w.strength * along * (along < 0 and Ducts.fans.headwind_share or 1)
		end
	end
	return factor
end

return DuctRules
