-- The winners' cutscene (Alan 2026-10-17/18, docs/decisions/2026-10-17-rounds-never-stop.md): the camera glides
-- from wherever you are (your plane or the hangar) to close-ups of the winner desks by the chalkboard. Local copies of the
-- top 3 take the place of the students sitting there, stand up on their chairs, jump onto the desks and emote, then
-- the camera glides back. It all happens on this screen only: the server's seated avatars are just hidden here.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rounds = require(Root.Generated.Gameplay).rounds

local PLACES = { "1st", "2nd", "3rd" }
local COLORS = { Color3.fromRGB(255, 205, 40), Color3.fromRGB(220, 225, 235), Color3.fromRGB(230, 140, 70) }
local EMOTES = { "rbxassetid://507771019", "rbxassetid://507770677", "rbxassetid://507770239" } -- Roblox R15 dance, cheer, wave
local SEATED = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" }
local BANNER, GLIDE, STAND, JUMP, TURN = 1.2, 2.0, 0.6, 0.7, 1.8 -- seconds; 3rd goes first, then 2nd, then 1st, TURN apart
local HOP_SETTLE = 0.35 -- the hop animation lands, squashes and settles this long before the emote starts
local ARC = 250 -- studs the camera rises mid-glide, so it sweeps over the room instead of skimming through it
-- The shots (Alan 2026-10-18: closer, cinematic, no bare floor or ceiling): a close-up of each winner in turn as they
-- stand and hop, square on to the desk and a little from below, the winner on the left of the screen and the results
-- card on the right; the camera pans to the next winner just before they move, pushes in on 1st as they land and
-- emote, then the card goes and it zooms out to all three emoting together (Alan 2026-10-18).
-- Lens, how much of the screen height the winner fills (as multiples of their leg length), low angle (height lost
-- per stud back), where the winner sits across the screen (0.5 = middle), push in and how long each pan takes.
local SHOT_FOV, SHOT_HEIGHT, SHOT_LOW, SHOT_SIDE, PUSH_IN, PAN = 40, 3.3, 0.08, 0.33, 0.12, 0.6
-- The group shot looks down a little from above the town's roofs (height gained per stud back), so the roofs fill
-- the bottom of the screen; anything closer than NEAR_CLEAR studs in front of any shot fades so it never films
-- from inside a building.
local GROUP_RISE, NEAR_CLEAR = 0.16, 350
local GROUP_FOV = 70 -- a wide lens, so the camera stays within the 500 studs Roblox's focus blur can reach
local GROUP_CLEAR = 120 -- the group shot keeps the town in front (soft in the blur), clearing only at the lens
-- Film-style focus (Alan 2026-10-18: the town in front looked bad): the winners sharp, what's in front of them soft
-- and the wall behind slightly soft. Studs either side of the desk row kept sharp (wider for the group), blur amounts.
local BLUR_RADIUS, BLUR_NEAR, BLUR_FAR = 130, 0.8, 0.2
local ZOOM_AT, ZOOM = 2 * TURN + 2.6, 1.6 -- seconds after arriving that the zoom out to all three starts, and its length
-- Only what would block a winner in their shot fades out on this screen; the rest of the town and the ceiling
-- decorations stay in view. Never faded: the room shell, the chalkboard, desks, chairs and the desks' hangars and
-- runways. Always faded: planes, other name tags and the desk landing rings.
local KEEP_ARENA = { "^Wall", "^Floor", "^Window", "^Chalkboard", "^Desk", "^Chair", "^NeutralDesk" }
local KEEP_TOYS = { ["school-desk"] = true, ["school-chair"] = true, ["desk-hangar"] = true, ["desk-runway-droop"] = true,
	["runway-light"] = true, ["runway-light-tip"] = true }
local Cutscene = {}
local active

local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function matchesAny(name, patterns)
	for _, pattern in patterns do if name:find(pattern) then return true end end
	return false
end

-- "always", "never" or "check" (fade only if it blocks a shot), decided by what the thing sits under: its top-level
-- child of the workspace, then for the room the room's child, then for the toy folder the folder's child.
local function shotRule(item)
	local chain, at = {}, item
	while at.Parent and at ~= workspace do table.insert(chain, 1, at); at = at.Parent end
	local top, child, entry = chain[1], chain[2], chain[3]
	if at ~= workspace or top.Name:match("^Winner") or top == workspace.Terrain or top:IsA("Camera") then return "never" end
	if item:IsA("BillboardGui") or top.Name == "Planes" then return "always" end
	if top.Name ~= "Arena" or not child then return "check" end
	if child:GetAttribute("SeatedAvatar") then return "never" end -- students: the winner desks' are handled on their own
	if child.Name == "CityToys" and entry then
		if entry.Name == "landing-ring" then return "always" end
		return KEEP_TOYS[entry.Name] and "never" or "check"
	end
	if child.Name == "Ducts" and entry and entry.Name == "Ceiling" then return "never" end
	return matchesAny(child.Name, KEEP_ARENA) and "never" or "check"
end

-- Where a box's corners land on screen for a camera: the screen rectangle (in units of the screen half-height) and
-- the nearest depth, or nil if part of it is behind the camera.
local function onScreen(view, tanHalf, cframe, size)
	local x0, y0, x1, y1, near = math.huge, math.huge, -math.huge, -math.huge, math.huge
	for i = 0, 7 do
		local corner = cframe * (size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5))
		local q = view:PointToObjectSpace(corner)
		if q.Z > -1 then return nil, -q.Z end
		local sx, sy = q.X / (-q.Z * tanHalf), q.Y / (-q.Z * tanHalf)
		x0, y0, x1, y1, near = math.min(x0, sx), math.min(y0, sy), math.max(x1, sx), math.max(y1, sy), math.min(near, -q.Z)
	end
	return { x0, y0, x1, y1 }, near
end

-- Whether the straight line from a to b passes through a box.
local function lineHits(a, b, cframe, size)
	local from, to, half = cframe:PointToObjectSpace(a), cframe:PointToObjectSpace(b), size / 2
	local t0, t1 = 0, 1
	for _, axis in { "X", "Y", "Z" } do
		local start, step, h = from[axis], to[axis] - from[axis], half[axis]
		if math.abs(step) < 1e-6 then
			if math.abs(start) > h then return false end
		else
			local u, v = (-h - start) / step, (h - start) / step
			t0, t1 = math.max(t0, math.min(u, v)), math.min(t1, math.max(u, v))
			if t0 > t1 then return false end
		end
	end
	return true
end

-- Whether a part sits between a shot's camera and its winner: nearer than the winner and overlapping them on screen
-- (or, for something reaching past the camera, crossing a sight line to the winner).
local function blocks(part, shots)
	for _, shot in shots do
		local rect, near = onScreen(shot.view, shot.tanHalf, part.CFrame, part.Size)
		if not rect then
			for _, point in shot.points do
				if lineHits(shot.view.Position, point, part.CFrame, part.Size) then return true end
			end
		elseif near < shot.near and rect[1] < shot.rect[3] and rect[3] > shot.rect[1] and rect[2] < shot.rect[4] and rect[4] > shot.rect[2] then
			return true
		elseif near < shot.clear and rect[1] < shot.aspect and rect[3] > -shot.aspect and rect[2] < 1 and rect[4] > -1 then
			return true -- right in front of the camera
		end
	end
	return false
end

-- Fade everything out of the shot (0 = as it was, 1 = gone); it fades during the glides so nothing pops.
local function fadeShot(state, amount)
	if state.faded == amount then return end
	state.faded = amount
	for item, was in state.cleared do
		if typeof(was) == "number" then item.LocalTransparencyModifier = was + (1 - was) * amount end
	end
end

-- Take one thing out of the shot if it blocks a winner, remembering how to put it back. Name tags go at once.
local function fadePart(state, part)
	for _, look in { part, table.unpack(part:GetChildren()) } do
		if (look:IsA("BasePart") or look:IsA("Decal") or look:IsA("Texture")) and not state.cleared[look] and look.LocalTransparencyModifier < 1 then
			state.cleared[look] = look.LocalTransparencyModifier
			look.LocalTransparencyModifier = look.LocalTransparencyModifier + (1 - look.LocalTransparencyModifier) * (state.faded or 0)
		end
	end
end

-- The town's buildings are loose pieces named "building/piece" in CityToys: all pieces of the one this part is in.
local function buildingPieces(state, part)
	local toys = workspace:FindFirstChild("Arena") and workspace.Arena:FindFirstChild("CityToys")
	if not toys or not part:IsDescendantOf(toys) then return nil end
	local entry = part
	while entry.Parent ~= toys do entry = entry.Parent end
	local name = entry.Name:match("^(.-)/")
	if not name then return nil end
	if not state.buildings then
		state.buildings = {}
		for _, piece in toys:GetChildren() do
			local key = piece.Name:match("^(.-)/")
			if key then state.buildings[key] = state.buildings[key] or {}; table.insert(state.buildings[key], piece) end
		end
	end
	return state.buildings[name]
end

local function hideForShot(state, item)
	if state.cleared[item] then return end
	local rule = shotRule(item)
	if rule == "never" then return end
	if item:IsA("BasePart") then
		if item.LocalTransparencyModifier < 1 and (rule == "always" or blocks(item, state.shots)) then
			-- A whole building goes, never half of one (that shows its dark inside).
			for _, piece in buildingPieces(state, item) or { item } do
				if piece:IsA("BasePart") then fadePart(state, piece) end
				for _, part in piece:GetDescendants() do if part:IsA("BasePart") then fadePart(state, part) end end
			end
		end
	elseif item:IsA("BillboardGui") or (rule == "always" and (item:IsA("SurfaceGui") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("ParticleEmitter"))) then
		if item.Enabled then state.cleared[item] = true; item.Enabled = false end
	end
end

-- Mobile strings go with whatever they hold.
local function hideStrings(state)
	for _, item in workspace:GetDescendants() do
		if (item:IsA("RopeConstraint") or item:IsA("RodConstraint") or item:IsA("SpringConstraint")) and item.Visible then
			local a, b = item.Attachment0, item.Attachment1
			if (a and state.cleared[a.Parent]) or (b and state.cleared[b.Parent]) then state.cleared[item] = "visible"; item.Visible = false end
		end
	end
end

local function setHidden(model, hidden)
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("Decal") then item.LocalTransparencyModifier = hidden and 1 or 0 end
	end
end

-- The chair nearest a point, and a frame at it that faces away from its desk (seats are the same in both rows).
local function chairAt(room, position)
	local best, distance = nil, 200
	for _, chair in room:GetChildren() do
		if chair.Name:match("^Chair") and chair:IsA("BasePart") and flat(chair.Position - position).Magnitude < distance then
			best, distance = chair, flat(chair.Position - position).Magnitude
		end
	end
	return best
end
local function seatFrame(room, chair)
	local desk = room:FindFirstChild("Desk" .. chair.Name:sub(6))
	return CFrame.lookAt(chair.Position, chair.Position + flat(chair.Position - desk.Position))
end

local function play(track) track:Play(0); track.TimePosition = math.min(0.2, track.Length * 0.5); track:AdjustSpeed(0) end

-- A local copy of a winner's seated avatar, moved to sit in the chair at `desk`; standing, it faces `facing`.
local function copyWinner(room, source, desk, place, name, facing)
	local fromChair, toChair = chairAt(room, source:GetPivot().Position), room:FindFirstChild("Chair" .. desk.Name:sub(5))
	if not fromChair or not toChair then return nil end
	source.Archivable = true
	local model = source:Clone()
	for _, item in model:GetDescendants() do
		if item.Name == "Collision" or item:IsA("BillboardGui") or item:IsA("Animation") then item:Destroy()
		elseif item:IsA("BasePart") or item:IsA("Decal") then item.LocalTransparencyModifier = 0 end
	end
	local humanoid, rootPart = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or not rootPart then model:Destroy(); return nil end
	model.Name = "Winner" .. place
	model:PivotTo(seatFrame(room, toChair) * seatFrame(room, fromChair):ToObjectSpace(source:GetPivot()))
	model.Parent = workspace
	local function load(id)
		local animation = Instance.new("Animation"); animation.AnimationId = id
		return animator:LoadAnimation(animation)
	end
	local seated = load(SEATED[humanoid.RigType] or SEATED[Enum.HumanoidRigType.R15])
	seated.Priority = Enum.AnimationPriority.Action
	play(seated)
	task.spawn(function() -- the pose needs the animation loaded to hold still on the right frame
		local deadline = os.clock() + 5
		repeat RunService.Heartbeat:Wait() until seated.Length > 0 or os.clock() > deadline
		if seated.IsPlaying and seated.Speed == 0 then play(seated) end
	end)
	local emote = load(EMOTES[place]); emote.Looped, emote.Priority = true, Enum.AnimationPriority.Action
	-- The stand-up-and-hop animation, once uploaded (Studio tests can set a temporary id on DevWinnerHop).
	local hopId = Root:GetAttribute("DevWinnerHop") or Rounds.winner_hop_animation
	local hop = hopId ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15 and load(hopId) or nil
	if hop then hop.Priority = Enum.AnimationPriority.Action2 end
	-- Feet sit this far below the root: hip height plus half the root for R15, the legs for R6.
	local leg = model:FindFirstChild("Left Leg")
	local feet = humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.HipHeight + rootPart.Size.Y / 2 or rootPart.Size.Y / 2 + (leg and leg.Size.Y or 2)
	local onChair = toChair.Position + Vector3.new(0, toChair.Size.Y / 2 + feet, 0)
	local onDesk = desk.Position + Vector3.new(0, desk.Size.Y / 2 + feet, 0) + facing * desk.Size.Z * 0.3 -- in front of the hangar
	local tag = Instance.new("BillboardGui")
	local head = model:FindFirstChild("Head")
	local above = head and rootPart.CFrame:PointToObjectSpace(head.Position).Y + head.Size.Y / 2 + 15 or feet
	tag.Size, tag.StudsOffsetWorldSpace, tag.LightInfluence, tag.Parent = UDim2.fromOffset(320, 64), Vector3.new(0, above, 0), 0, model
	tag.Adornee = rootPart
	local words = Instance.new("TextLabel")
	words.Size, words.BackgroundTransparency, words.TextScaled = UDim2.fromScale(1, 1), 1, true
	words.FontFace, words.TextColor3, words.Text = Font.fromEnum(Enum.Font.PermanentMarker), COLORS[place], PLACES[place] .. "  " .. name
	local stroke = Instance.new("UIStroke"); stroke.Thickness, stroke.Parent = 3, words
	words.Parent = tag
	local hips
	for _, joint in model:GetDescendants() do
		if joint.Name == "Root" and (joint:IsA("AnimationConstraint") or joint:IsA("Motor6D")) then hips = joint end
	end
	return { model = model, seated = seated, emote = emote, hop = hop, from = model:GetPivot(), place = place, hips = hips, scale = model:GetScale(), feet = feet,
		chair = CFrame.lookAt(onChair, onChair + facing), desk = CFrame.lookAt(onDesk, onDesk + facing), stood = false, landed = false }
end

-- Where each winner is at `t` seconds after the camera arrived: standing up on the chair, then hopping onto the desk.
local function moveWinner(w, t)
	t -= (3 - w.place) * TURN
	if t < 0 then return end
	if not w.stood then
		w.stood = true
		w.seated:Stop(w.hop and 0.15 or STAND)
		if w.hop then w.hop:Play(0.15) end
	end
	if t < STAND then
		w.model:PivotTo(w.from:Lerp(w.chair, ease(t / STAND)))
	elseif t < STAND + JUMP then
		local a = (t - STAND) / JUMP
		w.model:PivotTo(w.chair:Lerp(w.desk, a) + Vector3.new(0, math.sin(a * math.pi) * 70, 0))
	elseif not w.landed then
		w.landed = true; w.model:PivotTo(w.desk)
	end
	if w.landed and not w.emote.IsPlaying and t >= STAND + JUMP + (w.hop and HOP_SETTLE or 0) then w.emote:Play(0.3) end
end

-- winners: { { actorId, displayName }, ... } in place order. onStage("banner" | "card" | "back") as it moves on.
function Cutscene.play(winners, onStage)
	Cutscene.stop()
	local room = workspace:FindFirstChild("Arena")
	local desks = {}
	for i, name in Rounds.winner_desks do desks[i] = room and room:FindFirstChild(name) end
	if not room or #desks < 3 then return end
	local camera = workspace.CurrentCamera
	-- Square on to the row: straight out from the middle desk towards the room, the row running across the screen.
	local middle = desks[1].Position
	local row = flat(desks[3].Position - desks[2].Position).Unit
	local back = row:Cross(Vector3.yAxis)
	if back:Dot(flat(-middle)) < 0 then back = -back end
	local right = Vector3.yAxis:Cross(back) -- screen right when looking at the desks from the room side
	local aspect = camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1)
	local state = { start = os.clock(), winners = {}, hidden = {}, cleared = {}, stage = "banner", cameraType = camera.CameraType, fov = camera.FieldOfView, written = nil, home = camera.CFrame }
	active = state
	state.blur = Instance.new("DepthOfFieldEffect") -- Roblox's own camera blur, on this screen only
	state.blur.Name, state.blur.NearIntensity, state.blur.FarIntensity, state.blur.Parent = "WinnersFocus", 0, 0, camera
	Root:SetAttribute("Cutscene", true)
	onStage("banner")

	-- Students at the winner desks step out of sight on this screen; copies of the winners take their seats.
	local function seatWinners()
		for place, desk in desks do
			local row = winners[place]
			if row and not state.winners[place] then
				for _, source in room:GetChildren() do
					if source:IsA("Model") and source:GetAttribute("PilotId") == row.actorId then
						state.winners[place] = copyWinner(room, source, desk, place, row.displayName, back)
						break
					end
				end
				local chair = state.winners[place] and room:FindFirstChild("Chair" .. desk.Name:sub(5))
				for _, model in room:GetChildren() do
					if chair and model:GetAttribute("SeatedAvatar") and flat(model:GetPivot().Position - chair.Position).Magnitude < 120 then
						state.hidden[model] = true; setHidden(model, true)
					end
				end
			end
		end
	end
	seatWinners()

	-- Each winner's close-up: framed on where they end up standing on the desk, and the box around them (chair to
	-- desk front, desk top to name tag) that nothing may block.
	local shots = {}
	-- A shot of some winners: square on to the desks and a little from below, the winners placed at `side` across
	-- the screen, close enough to fill SHOT_HEIGHT leg lengths (or wider to fit them all); and the box around them
	-- (chair to desk front, desk top to name tag) that nothing may block.
	local function shotOf(places, side, rise, fov, clear)
		local stands, feet, froms = {}, 0, {}
		for _, place in places do
			local desk, w = desks[place], state.winners[place]
			local legs = w and w.feet or 80
			local stand = w and w.desk.Position or desk.Position + Vector3.new(0, desk.Size.Y / 2 + legs, 0) + back * desk.Size.Z * 0.3
			local chair = room:FindFirstChild("Chair" .. desk.Name:sub(5))
			table.insert(stands, stand)
			table.insert(froms, chair and flat(chair.Position) or flat(stand) - back * 200)
			feet = math.max(feet, legs)
		end
		local middle, from = Vector3.zero, Vector3.zero
		for i, stand in stands do middle += stand / #stands; from += froms[i] / #stands end
		local across = 0
		for _, stand in stands do across = math.max(across, math.abs((stand - middle):Dot(right))) end
		local share = 1 - 2 * math.abs(0.5 - side) -- share of the screen width the winners may use
		local tanHalf = math.tan(math.rad(fov / 2))
		local distance = math.max(SHOT_HEIGHT * feet / 2 / tanHalf, (across + 150) / (tanHalf * aspect * share))
		local target = middle + Vector3.new(0, feet * 0.05, 0) + right * (0.5 - side) * 2 * distance * tanHalf * aspect
		local eye = target + back * distance + Vector3.new(0, distance * rise, 0)
		local deskTop = desks[places[1]].Position.Y + desks[places[1]].Size.Y / 2
		local top = middle.Y + feet * 0.75 + 60
		local center = (from + flat(middle)) / 2 + back * 20 + Vector3.new(0, (deskTop + top) / 2, 0)
		local size = Vector3.new(2 * across + 260, top - deskTop, (flat(middle) - from).Magnitude + 120)
		local box = CFrame.fromMatrix(center, right, Vector3.yAxis)
		local view = CFrame.lookAt(eye, target)
		local rect, near = onScreen(view, tanHalf, box, size)
		local points = { center }
		for i = 0, 7 do points[#points + 1] = box * (size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5)) end
		table.insert(shots, { view = view, rect = rect or { -1, -1, 1, 1 }, near = near, points = points, aspect = aspect, tanHalf = tanHalf, clear = clear })
		return view, distance
	end
	local third, second = shotOf({ 3 }, SHOT_SIDE, -SHOT_LOW, SHOT_FOV, NEAR_CLEAR), shotOf({ 2 }, SHOT_SIDE, -SHOT_LOW, SHOT_FOV, NEAR_CLEAR)
	local first, firstDistance = shotOf({ 1 }, SHOT_SIDE, -SHOT_LOW, SHOT_FOV, NEAR_CLEAR)
	local closer = first + first.LookVector * firstDistance * PUSH_IN
	local group, groupDistance = shotOf({ 2, 1, 3 }, 0.5, GROUP_RISE, GROUP_FOV, GROUP_CLEAR) -- all three, centred, once the card has gone
	local drift = group + group.LookVector * groupDistance * PUSH_IN * 0.5
	state.shots = shots

	-- Roblox scales an animation's hip movement twice on a scaled-up avatar (27 x 27 instead of 27, measured
	-- 2026-10-17), which throws the body far off its root. Once standing, take the extra scale back out each step.
	state.fixHips = RunService.PreSimulation:Connect(function()
		for _, w in state.winners do
			if w.stood and w.hips then w.hips.Transform = w.hips.Transform.Rotation + w.hips.Transform.Position / w.scale end
		end
	end)

	local arrive = BANNER + GLIDE
	local leave = Rounds.results_seconds - GLIDE - 0.3
	local function clearShot()
		state.added = workspace.DescendantAdded:Connect(function(item) hideForShot(state, item) end)
		task.spawn(function() -- a few hundred parts a frame, so the glide doesn't stutter; done well before it lands
			for i, item in workspace:GetDescendants() do
				if active ~= state then return end
				hideForShot(state, item)
				if i % 400 == 0 then RunService.Heartbeat:Wait() end
			end
			hideStrings(state)
		end)
	end
	-- The camera while it holds, `t` seconds after arriving: on 3rd, pan to 2nd, pan to 1st, then push in on 1st.
	local function holdAt(t)
		if t < TURN - PAN then return third end
		if t < TURN then return third:Lerp(second, ease((t - TURN + PAN) / PAN)) end
		if t < 2 * TURN - PAN then return second end
		if t < 2 * TURN then return second:Lerp(first, ease((t - 2 * TURN + PAN) / PAN)) end
		if t < ZOOM_AT then return first:Lerp(closer, ease((t - 2 * TURN) / (ZOOM_AT - 2 * TURN))) end
		if t < ZOOM_AT + ZOOM then return closer:Lerp(group, ease((t - ZOOM_AT) / ZOOM)) end
		return group:Lerp(drift, ease((t - ZOOM_AT - ZOOM) / (leave - arrive - ZOOM_AT - ZOOM)))
	end
	RunService:BindToRenderStep("WinnersCutscene", Enum.RenderPriority.Camera.Value + 3, function()
		local t = os.clock() - state.start
		-- The camera as the game would show it this frame (your plane or hangar view); if nothing moved it, where it was.
		local live = camera.CFrame ~= state.written and camera.CFrame or state.home
		local liveFov = camera.CFrame ~= state.written and camera.FieldOfView or state.fov
		state.home, state.fov = live, liveFov
		local hold = holdAt(t - arrive)
		local holdFov = SHOT_FOV + (GROUP_FOV - SHOT_FOV) * ease((t - arrive - ZOOM_AT) / ZOOM)
		local view, fov
		if t < BANNER then view, fov = live, liveFov
		elseif t < arrive then
			if not state.added then clearShot() end
			local a = ease((t - BANNER) / GLIDE)
			fadeShot(state, ease((t - BANNER) / (GLIDE * 0.6)))
			view, fov = live:Lerp(third, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), liveFov + (SHOT_FOV - liveFov) * a
		elseif t < leave then view, fov = hold, holdFov
		else
			local a = ease((t - leave) / GLIDE)
			fadeShot(state, 1 - a)
			view, fov = hold:Lerp(live, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), holdFov + (liveFov - holdFov) * a
		end
		if t < arrive then seatWinners() end
		for _, w in state.winners do moveWinner(w, t - arrive) end
		local stage = t < arrive and "banner" or t < arrive + ZOOM_AT and "card" or t < leave and "group" or "back"
		if stage ~= state.stage then state.stage = stage; onStage(stage) end
		if t >= leave + GLIDE then Cutscene.stop(); return end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame, camera.FieldOfView = view, fov
		-- Focus on the desk row (all winners stand the same distance back), soft in front and a little behind.
		local row = state.winners[1] or state.winners[2] or state.winners[3]
		local strength = t < arrive and ease((t - BANNER) / GLIDE) or t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		state.blur.FocusDistance = row and math.max(0, (row.desk.Position - view.Position):Dot(view.LookVector)) or 500
		state.blur.InFocusRadius = t < arrive + ZOOM_AT and BLUR_RADIUS or BLUR_RADIUS * 1.6
		state.blur.NearIntensity, state.blur.FarIntensity = BLUR_NEAR * strength, BLUR_FAR * strength
		state.written = view
	end)
end

function Cutscene.stop()
	if not active then return end
	local state = active
	active = nil
	RunService:UnbindFromRenderStep("WinnersCutscene")
	if state.fixHips then state.fixHips:Disconnect() end
	for _, w in state.winners do w.model:Destroy() end
	for model in state.hidden do if model.Parent then setHidden(model, false) end end
	if state.added then state.added:Disconnect() end
	fadeShot(state, 0)
	for item, was in state.cleared do
		if was == true then item.Enabled = true elseif was == "visible" then item.Visible = true end
	end
	state.blur:Destroy()
	workspace.CurrentCamera.CameraType, workspace.CurrentCamera.FieldOfView = state.cameraType, state.fov
	Root:SetAttribute("Cutscene", false)
end

return Cutscene
