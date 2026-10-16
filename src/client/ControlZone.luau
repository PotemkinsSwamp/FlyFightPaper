-- Airspace Control zone, drawn on this client only (Alan's pick: assets/references/mode-concepts/zone-confetti.png).
-- A field, not a prop: a wobbly crayon circle drawn on whatever is under it, plus two loops of confetti and paper
-- streamers drifting round its top and bottom edges. Nothing is solid; planes fly straight through.
-- Yellow (like its arrow) while nobody holds it, the holder's team colour when held, red and blue when contested. In the warning
-- seconds before it moves, the next spot shows as a faint circle. A zone high off the floor (the ceiling spot)
-- gets its circle floating at its bottom face instead of on the ground.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rounds = require(Root.Generated.Gameplay).rounds

local PER_LOOP = 180 -- confetti bits in each of the two loops (sized to read from across the room)
local TURNS_PER_SECOND = 0.02 -- the loops drift slowly round the zone
local DASHES = 220 -- crayon strokes in a circle (about one per 9 studs round a 300-stud radius)
local FLOATING_ABOVE = 300 -- a zone whose bottom is higher than this draws its circle in the air
local WHITE = Color3.fromRGB(250, 248, 240)
local PALETTES = {
	none = { Color3.fromRGB(255, 205, 40), WHITE },
	["team:1"] = { Color3.fromRGB(215, 40, 40), WHITE },
	["team:2"] = { Color3.fromRGB(40, 80, 210), WHITE },
	contested = { Color3.fromRGB(215, 40, 40), Color3.fromRGB(40, 80, 210) },
}

local ControlZone = {}
-- Read by FlightHUD: the current and next zone (rows of rounds.control_zones), who holds it, seconds until it moves.
ControlZone.state = { zone = nil, nextZone = nil, holder = nil, moveIn = 0 }

function ControlZone.start()
	local folder = Instance.new("Folder")
	folder.Name = "ControlZone"
	local function piece(size)
		local part = Instance.new("Part")
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
		part.Material, part.Size, part.Parent = Enum.Material.SmoothPlastic, size, folder
		return part
	end
	local bits, parts, frames = {}, {}, {}
	for i = 1, PER_LOOP * 2 do
		local streamer = i % 6 == 0
		local part = piece(streamer and Vector3.new(3, 22, 0.2) or Vector3.new(14, 14, 0.2))
		bits[i] = { part = part, top = i > PER_LOOP, angle = (i % PER_LOOP) / PER_LOOP * math.pi * 2 + math.random() * 0.05,
			phase = math.random() * 10, spin = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * 2 }
		parts[i] = part
	end
	local function circle(transparency)
		local strokes = {}
		for i = 1, DASHES do
			strokes[i] = piece(Vector3.new(14, 0.4, 10))
			strokes[i].Transparency = transparency
		end
		return strokes
	end
	local ring, ghost = circle(0), circle(0.6)
	local sight = RaycastParams.new()
	sight.FilterType = Enum.RaycastFilterType.Exclude
	-- Lay a circle's strokes round `zone`: on the ground (first surface below the zone's top) or floating.
	local function draw(strokes, zone)
		local c, radius = zone.center, zone.radius
		local floating = c[2] - zone.half_height > FLOATING_ABOVE
		sight.FilterDescendantsInstances = { folder, workspace:FindFirstChild("Planes") }
		for i, stroke in strokes do
			local a = i / DASHES * math.pi * 2
			local r = radius + math.noise(i * 0.3, 7) * 6 -- a child's hand: the line wobbles a little
			local x, z = c[1] + math.cos(a) * r, c[3] + math.sin(a) * r
			local at, up = Vector3.new(x, c[2] - zone.half_height, z), Vector3.yAxis
			if not floating then
				local hit = workspace:Raycast(Vector3.new(x, c[2] + zone.half_height, z), Vector3.new(0, -2000, 0), sight)
				if hit then at, up = hit.Position + hit.Normal * 0.25, hit.Normal end
				-- The city's street map lies just above the classroom floor and can't be hit by rays: draw on top of it.
				if at.Y < 2 then at = Vector3.new(at.X, 2, at.Z) end
			end
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
			tangent = (tangent - up * tangent:Dot(up)).Unit
			stroke.Size = Vector3.new(14, 0.4, 9 + math.noise(i * 0.7, 3) * 4)
			stroke.CFrame = CFrame.fromMatrix(at, tangent, up)
		end
	end
	local function paint(holder)
		local palette = PALETTES[holder or "none"] or PALETTES.none
		for i, bit in bits do bit.part.Color = palette[i % 2 + 1] end
		for _, stroke in ring do stroke.Color = palette[1] end
	end
	local function show(strokes, on) for _, stroke in strokes do stroke.LocalTransparencyModifier = on and 0 or 1 end end

	local state = ControlZone.state
	local index, nextIndex, holder, moveAt, heardAt, drawnAt = nil, nil, false, 0, 0, 0
	Root:WaitForChild("RoundView").OnClientEvent:Connect(function(snapshot)
		local zone = snapshot.mode == "CONTROL" and snapshot.zone or nil
		if not zone or not Rounds.control_zones[zone.index] then
			index, state.zone, state.nextZone, folder.Parent = nil, nil, nil, nil
			return
		end
		moveAt, heardAt = zone.moveAt - snapshot.serverTime, os.clock()
		-- Redrawn now and then too: with streaming on, the buildings under a far zone may not have loaded yet.
		if zone.index ~= index or zone.nextIndex ~= nextIndex or os.clock() - drawnAt > 15 then
			index, nextIndex, drawnAt = zone.index, zone.nextIndex, os.clock()
			draw(ring, Rounds.control_zones[index])
			if Rounds.control_zones[nextIndex] then draw(ghost, Rounds.control_zones[nextIndex]) end
		end
		if zone.holder ~= holder then holder = zone.holder; paint(holder) end
		state.zone, state.nextZone, state.holder = Rounds.control_zones[index], Rounds.control_zones[nextIndex], holder
		folder.Parent = workspace
	end)
	RunService.RenderStepped:Connect(function()
		if not index then return end
		state.moveIn = math.max(0, moveAt - (os.clock() - heardAt))
		show(ghost, state.moveIn <= Rounds.control_warning_seconds)
		local zone, now = state.zone, os.clock()
		local c, turn = zone.center, now * TURNS_PER_SECOND * math.pi * 2
		for i, bit in bits do
			local a = bit.angle + turn
			local r = zone.radius + math.sin(now * 0.7 + bit.phase) * 8
			local y = c[2] + (bit.top and zone.half_height or -zone.half_height) + math.sin(now * 1.3 + bit.phase) * 10
			frames[i] = CFrame.new(c[1] + math.cos(a) * r, y, c[3] + math.sin(a) * r)
				* CFrame.Angles(bit.spin.X * now, bit.spin.Y * now, bit.spin.Z * now)
		end
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return ControlZone
