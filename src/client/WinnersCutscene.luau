-- The winners' moment (Alan 2026-10-18, docs/decisions/2026-10-18-winners-shot-redesign.md), like the big games'
-- winner screens: the camera glides from wherever you are (your plane or the hangar) to the three winner desks by
-- the chalkboard. Local copies of the top 3 take the place of the students sitting there. In close-up, 3rd, then 2nd,
-- then 1st stand up, hop onto their desk and start one of Roblox's own emotes, a name plate popping in under each
-- (place, name, points); confetti falls from 1st's landing; the camera zooms out to one steady shot of all three
-- emoting, then glides back as the results card comes up for its last CARD seconds (Alan 2026-10-18).
-- It all happens on this screen only: the server's seated avatars are just hidden here.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Gameplay = require(Root.Generated.Gameplay)
local Rounds, Avatars = Gameplay.rounds, Gameplay.avatar_display
local UIArt = require(Root.Shared.UIAssets).mainmenu
local PaperUI = require(script.Parent.PaperUI)

local PLACES = { "1st", "2nd", "3rd" }
local COLORS = { Color3.fromRGB(255, 205, 40), Color3.fromRGB(220, 225, 235), Color3.fromRGB(230, 140, 70) }
local STRIPS = { UIArt.strip.yellow, UIArt.strip.blue, UIArt.strip.red } -- the main menu's paper strips, as plates
-- Roblox's own emotes (catalog items made by Roblox; Roblox's animations play in any game). All of these load and
-- keep the feet on the desk on our big avatars (tested 2026-10-18, 24 tried). 1st does a winner's move, 2nd and 3rd
-- each a different dance.
local EMOTES = {
	{ "rbxassetid://10714347256", "rbxassetid://10714016223", "rbxassetid://5895324424", "rbxassetid://10714349037" }, -- Godlike, Celebrate, Jumping Cheer, Greatest
	{ "rbxassetid://10714340543", "rbxassetid://10714403700", "rbxassetid://10714386947", "rbxassetid://6862001787",
		"rbxassetid://10714068222", "rbxassetid://10714352626", "rbxassetid://10714366910", "rbxassetid://10713988674" }, -- Floss, Rock On, Samba, Cha Cha, Dolphin, Happy, Side to Side, Block Partier
}
local SEATED = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" }
local BANNER, GLIDE, STAND, JUMP = 1.2, 2.0, 0.6, 0.7 -- seconds
local TURN, PAN = 1.8, 0.6 -- 3rd moves first, then 2nd, then 1st, TURN apart; the camera pans to the next in PAN
local ZOOM_AT, ZOOM = 2 * TURN + 2.0, 1.6 -- seconds after arriving that the zoom out to all three starts, and its length
local CARD = 10 -- the results card's seconds at the end of the winners' moment (Alan 2026-10-18: about 10)
local HOP_SETTLE = 0.35 -- the hop animation lands, squashes and settles this long before the emote starts
local ARC = 250 -- studs the camera rises mid-glide, so it sweeps over the room instead of skimming through it
-- The shots, square on to the desk row and level: the lens, a slow push in on the group (share of the distance), and
-- the frame: a close-up CLOSE tall with its top CLOSE_TOP over the desk top (just over the head); the group wide
-- enough that SIDE_ROOM fits beside the outside winners (body, arms and the whole plate: Alan 2026-10-18, half bodies
-- and plates were cut off), looking GROUP_TILT degrees down at them with the bottom of the frame GROUP_FLOOR below
-- the desk top under them (just under the plates, so the town's pillars in front stay out: Alan 2026-10-18). Sizes in
-- winner heights.
local SHOT_FOV, PUSH_IN, CLOSE_TOP, CLOSE, SIDE_ROOM = 50, 0.04, 1.3, 1.9, 1.2
local GROUP_TILT, GROUP_FLOOR = 8, 1.05
local EYE_LOW = 0.15 -- a close-up camera never goes lower than this far over the desk top (winner heights)
-- How far forward on their desk 1st and the others stand (shares of the desk depth): 1st a little in front.
local FIRST_FORWARD, SIDE_FORWARD = 0.32, 0.22
-- The two outside winner desks slide in to this many studs from the middle one, on this screen only, for the
-- winners' moment (Alan 2026-10-18: desks closer together, not too close; the map itself stays as it is). What sits
-- on a desk goes with it: the desk, its chair and student, and these toys.
local DESK_GAP = 50
local DESK_KIT = { ["school-desk"] = true, ["school-chair"] = true, ["desk-hangar"] = true, ["desk-runway-droop"] = true,
	["runway-light"] = true, ["runway-light-tip"] = true, ["landing-ring"] = true }
local NEAR_CLEAR = 120 -- anything right in front of the lens fades; the rest blocking a winner fades too
-- Film-style focus (Alan 2026-10-18): the winners sharp, what's in front of them soft, the wall behind a little soft.
local BLUR_RADIUS, BLUR_NEAR, BLUR_FAR = 200, 0.8, 0.2
-- Confetti: Roblox's own square particle, in five crayon colours, falling over the three from when 1st lands.
local CONFETTI = "rbxasset://textures/particles/SquareParticle.png"
local CONFETTI_COLORS = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(60, 110, 230), Color3.fromRGB(250, 205, 40),
	Color3.fromRGB(70, 190, 90), Color3.fromRGB(240, 120, 200) }
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

-- Whether a part hangs from the ceiling between the group shot's camera and the winners (planets, mobiles: Alan
-- 2026-10-18, the planet was too much in the shot). Town buildings are never "hanging".
local function overhead(state, part)
	local o = state.overhead
	if not o or part.Position.Y - part.Size.Y / 2 < o.y or buildingPieces(state, part) then return false end
	local depth = (part.Position - o.view.Position):Dot(o.view.LookVector)
	return depth > 0 and depth < o.depth
end

local function hideForShot(state, item)
	if state.cleared[item] then return end
	local rule = shotRule(item)
	if rule == "never" then return end
	if item:IsA("BasePart") then
		if item.LocalTransparencyModifier < 1 and (rule == "always" or blocks(item, state.shots) or overhead(state, item)) then
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

-- 1st's emote: playing with their plane (Alan 2026-10-18, docs/decisions/2026-10-18-emotes-and-bot-looks.md). A
-- full-body animation from Meshy text-to-motion (tools/meshy_to_r15.py) moves the body; a copy of their own plane
-- sits in the right hand, nose turning the way the hand moves. Studio tests set a temporary id on DevWinnerEmote.
local PLANE_LENGTH, PLANE_TURN = 0.3, 0.15 -- plane length as a share of the winner's height; how fast the nose turns
local function holdPlane(model, actorId)
	local planes = workspace:FindFirstChild("Planes")
	local source = planes and planes:FindFirstChild(tostring(actorId))
	local hand = model:FindFirstChild("RightHand")
	if not source or not hand then return nil end
	source.Archivable = true
	local plane = source:Clone()
	for _, item in plane:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("BillboardGui") or item:IsA("JointInstance") or item:IsA("WeldConstraint") then item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.LocalTransparencyModifier = true, false, false, false, 0
		end
	end
	local height = model:GetScale() * 5 -- an R15 avatar is about 5 studs tall at scale 1
	plane:ScaleTo(plane:GetScale() * height * PLANE_LENGTH / plane:GetExtentsSize().Z)
	plane.Name = "HeldPlane"
	return { plane = plane, hand = hand, length = height * PLANE_LENGTH, last = hand.Position, heading = model:GetPivot().LookVector }
end
local function flyPlane(w)
	local prop = w.prop
	if not prop.plane.Parent then prop.plane.Parent = w.model end
	local at = prop.hand.Position
	local moved = at - prop.last
	prop.last = at
	if moved.Magnitude > prop.length * 0.002 then prop.heading = prop.heading:Lerp(moved.Unit, PLANE_TURN).Unit end
	local grip = at + prop.heading * prop.length * 0.3 -- held by the tail
	local up = math.abs(prop.heading.Y) > 0.97 and w.desk.LookVector or Vector3.yAxis
	prop.plane:PivotTo(CFrame.lookAt(grip, grip + prop.heading, up))
end

-- 1st's emote comes from the first list; 2nd and 3rd each get a different one from the second.
local picked = {}
local function emoteFor(place)
	local list, id = EMOTES[place == 1 and 1 or 2], nil
	repeat id = list[math.random(#list)] until place == 1 or id ~= picked[5 - place]
	picked[place] = id
	return id
end

-- A local copy of a winner's seated avatar, moved to sit in the chair at `desk`; standing on the desk top at `spot`,
-- it faces `facing`.
local function copyWinner(room, source, desk, place, facing, actorId, spot)
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
	local planeEmote = Root:GetAttribute("DevWinnerEmote") or Rounds.winner_plane_emote
	local prop = place == 1 and planeEmote ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15 and holdPlane(model, actorId) or nil
	local emote = load(prop and planeEmote or emoteFor(place)); emote.Looped, emote.Priority = true, Enum.AnimationPriority.Action
	-- The stand-up-and-hop animation, once uploaded (Studio tests can set a temporary id on DevWinnerHop).
	local hopId = Root:GetAttribute("DevWinnerHop") or Rounds.winner_hop_animation
	local hop = hopId ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15 and load(hopId) or nil
	if hop then hop.Priority = Enum.AnimationPriority.Action2 end
	-- Feet sit this far below the root: hip height plus half the root for R15, the legs for R6.
	local leg = model:FindFirstChild("Left Leg")
	local feet = humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.HipHeight + rootPart.Size.Y / 2 or rootPart.Size.Y / 2 + (leg and leg.Size.Y or 2)
	local onChair = toChair.Position + Vector3.new(0, toChair.Size.Y / 2 + feet, 0)
	local onDesk = spot + Vector3.new(0, feet, 0)
	local hips
	for _, joint in model:GetDescendants() do
		if joint.Name == "Root" and (joint:IsA("AnimationConstraint") or joint:IsA("Motor6D")) then hips = joint end
	end
	return { model = model, seated = seated, emote = emote, hop = hop, prop = prop, from = model:GetPivot(), place = place, hips = hips, scale = model:GetScale(), feet = feet,
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
	if w.prop and w.emote.IsPlaying then flyPlane(w) end
end

-- The name plates under the winners (place, name, points) on the main menu's paper strips, one ScreenGui on this screen.
local PLATE_W, PLATE_H = 290, 106 -- pixels on a 1080-tall screen
local function makePlates(rows)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "WinnerPlates", true, false, 9
	local plates = {}
	for place, row in rows do
		local plate = Instance.new("ImageLabel")
		plate.Name, plate.Image, plate.BackgroundTransparency, plate.ScaleType = "Plate" .. place, STRIPS[place], 1, Enum.ScaleType.Stretch
		plate.AnchorPoint, plate.Size, plate.Visible = Vector2.new(0.5, 0), UDim2.fromOffset(PLATE_W, PLATE_H), false
		local size = Instance.new("UIScale"); size.Parent = plate
		local function words(text, y, h, color, outline)
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency, label.Text, label.TextScaled = 1, text, true
			label.Position, label.Size = UDim2.fromScale(0.1, y), UDim2.fromScale(0.8, h)
			label.FontFace, label.TextColor3 = PaperUI.font, color
			if outline then local stroke = Instance.new("UIStroke"); stroke.Thickness, stroke.Parent = 2.5, label end
			label.Parent = plate
		end
		words(PLACES[place], 0.06, 0.4, COLORS[place], true)
		words(row.displayName, 0.44, 0.28, PaperUI.INK)
		words(string.format("%d pts", math.floor(row.contribution or 0)), 0.7, 0.22, PaperUI.INK)
		plate.Parent = gui
		plates[place] = { frame = plate, scale = size }
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui, plates
end

-- Confetti over the three: an invisible box at `at`, `size` big, that rains it down while it is on.
local function makeConfetti(at, size, height)
	local cloud = Instance.new("Part")
	cloud.Name, cloud.Anchored, cloud.CanCollide, cloud.CanQuery, cloud.CanTouch, cloud.Transparency = "WinnerConfetti", true, false, false, false, 1
	cloud.CFrame, cloud.Size = at, size
	local flutter = {} -- the pieces flip as they fall
	for i = 0, 4 do flutter[i + 1] = NumberSequenceKeypoint.new(i / 4, i % 2 == 0 and -0.7 or 0.7) end
	for _, color in CONFETTI_COLORS do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture, emitter.Color, emitter.LightInfluence, emitter.Enabled = CONFETTI, ColorSequence.new(color), 0, false
		emitter.EmissionDirection, emitter.Shape = Enum.NormalId.Bottom, Enum.ParticleEmitterShape.Box
		emitter.Size, emitter.Squash = NumberSequence.new(height * 0.022), NumberSequence.new(flutter)
		emitter.Lifetime, emitter.Rate = NumberRange.new(4, 6), 14
		emitter.Speed, emitter.SpreadAngle = NumberRange.new(height * 0.05, height * 0.2), Vector2.new(30, 30)
		emitter.Acceleration, emitter.Drag = Vector3.new(0, -height * 0.3, 0), 1
		emitter.Rotation, emitter.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-220, 220)
		emitter.Parent = cloud
	end
	cloud.Parent = workspace
	return cloud
end

local function popIn(a) a = math.clamp(a, 0, 1) - 1; return 1 + 2.7 * a ^ 3 + 1.7 * a ^ 2 end -- overshoots a little

-- winners: { { actorId, displayName, contribution }, ... } in place order. onStage("banner" | "group" | "card") as it
-- moves on: the banner while the camera sets off, nothing over the winners' shot, the results card as it glides back.
function Cutscene.play(winners, onStage)
	Cutscene.stop()
	local room = workspace:FindFirstChild("Arena")
	local desks = {}
	for i, name in Rounds.winner_desks do desks[i] = room and room:FindFirstChild(name) end
	if not room or #desks < 3 then return end
	local camera = workspace.CurrentCamera
	-- Square on to the row: straight out from the desks towards the room, the row running across the screen.
	local row = flat(desks[3].Position - desks[2].Position).Unit
	local back = row:Cross(Vector3.yAxis)
	if back:Dot(flat(-desks[1].Position)) < 0 then back = -back end
	local right = Vector3.yAxis:Cross(back) -- screen right when looking at the desks from the room side
	local aspect = camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1)
	local state = { start = os.clock(), winners = {}, hidden = {}, cleared = {}, stage = "banner", cameraType = camera.CameraType, fov = camera.FieldOfView, written = nil, home = camera.CFrame }
	active = state
	state.blur = Instance.new("DepthOfFieldEffect") -- Roblox's own camera blur, on this screen only
	state.blur.Name, state.blur.NearIntensity, state.blur.FarIntensity, state.blur.Parent = "WinnersFocus", 0, 0, camera
	Root:SetAttribute("Cutscene", true)
	onStage("banner")

	-- The outside desks slide in next to the middle one (put back in Cutscene.stop).
	state.moved = {}
	local toys = room:FindFirstChild("CityToys")
	for place = 2, 3 do
		local desk = desks[place]
		local shift = flat(desks[1].Position - desk.Position)
		shift = shift.Unit * (shift.Magnitude - desk.Size.X - DESK_GAP)
		local items = {}
		for _, item in room:GetChildren() do
			if item.Name:match("^Desk") or item.Name:match("^Chair") or item:GetAttribute("SeatedAvatar") then table.insert(items, item) end
		end
		for _, item in toys and toys:GetChildren() or {} do
			if DESK_KIT[item.Name] then table.insert(items, item) end
		end
		local at = desk.Position
		for _, item in items do
			local offset = (item:IsA("BasePart") or item:IsA("Model")) and flat(item:GetPivot().Position - at)
			if offset and math.abs(offset:Dot(right)) < desk.Size.X / 2 + 40 and math.abs(offset:Dot(back)) < 400 then
				state.moved[item] = item:GetPivot()
				item:PivotTo(item:GetPivot() + shift)
			end
		end
	end

	-- Where each winner will stand on their desk top, in the middle: 1st a little forward.
	local height = Avatars.standing_height_studs -- every avatar is scaled to stand this tall (AvatarService)
	local deskTop = desks[1].Position.Y + desks[1].Size.Y / 2
	local spots = {}
	for place, desk in desks do
		spots[place] = Vector3.new(desk.Position.X, deskTop, desk.Position.Z) + back * desk.Size.Z * (place == 1 and FIRST_FORWARD or SIDE_FORWARD)
	end

	-- Students at the winner desks step out of sight on this screen; copies of the winners take their seats.
	local function seatWinners()
		for place, desk in desks do
			local entry = winners[place]
			if entry and not state.winners[place] then
				for _, source in room:GetChildren() do
					if source:IsA("Model") and source:GetAttribute("PilotId") == entry.actorId then
						state.winners[place] = copyWinner(room, source, desk, place, back, entry.actorId, spots[place])
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

	-- A shot of some winners: down from `headRoom` over the desk top, `tall` winner heights tall or wider so SIDE_ROOM
	-- fits beside the outside ones, looking level at them. Each shot also gets the box around all three winners
	-- (chairs to desk fronts, desk top to over their heads) that nothing may block.
	local tanHalf = math.tan(math.rad(SHOT_FOV / 2))
	local chairs = Vector3.zero
	for _, desk in desks do
		local chair = room:FindFirstChild("Chair" .. desk.Name:sub(5))
		chairs += (chair and flat(chair.Position) or flat(desk.Position) - back * 200) / #desks
	end
	local middle = (spots[2] + spots[3]) / 2
	local across = 0
	for _, spot in spots do across = math.max(across, math.abs((spot - middle):Dot(right))) end
	local top = deskTop + 1.3 * height
	local center = (chairs + flat(middle)) / 2 + back * 20 + Vector3.new(0, (deskTop + top) / 2, 0)
	local size = Vector3.new(2 * (across + SIDE_ROOM * height), top - deskTop, (flat(middle) - chairs).Magnitude + 120)
	local box = CFrame.fromMatrix(center, right, Vector3.yAxis)
	local points = { center }
	for i = 0, 7 do points[#points + 1] = box * (size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5)) end
	state.shots = {}
	local function shotOf(places, tall, headRoom)  -- headRoom nil: the group shot
		local mid, wide = Vector3.zero, 0
		for _, place in places do mid += spots[place] / #places end
		for _, place in places do wide = math.max(wide, math.abs((spots[place] - mid):Dot(right))) end
		local half = math.max(tall * height / 2, (wide + SIDE_ROOM * height) / aspect)
		local distance = half / tanHalf
		local eyeY, tilt
		if headRoom then
			-- Level if that keeps the camera at least EYE_LOW over the desk top, else there and tilted down until the
			-- top of the frame is back just over their heads.
			local top = deskTop + headRoom * height
			eyeY = math.max(top - half, deskTop + EYE_LOW * height)
			tilt = math.atan((top - eyeY) / distance) - math.rad(SHOT_FOV / 2)
		else
			tilt = -math.rad(GROUP_TILT)
			eyeY = deskTop - GROUP_FLOOR * height + distance * math.tan(math.rad(SHOT_FOV / 2 + GROUP_TILT))
		end
		local eye = Vector3.new(mid.X, eyeY, mid.Z) + back * distance
		local view = CFrame.lookAt(eye, eye - back * math.cos(tilt) + Vector3.yAxis * math.sin(tilt))
		local rect, near = onScreen(view, tanHalf, box, size)
		table.insert(state.shots, { view = view, rect = rect or { -1, -1, 1, 1 }, near = near, points = points, aspect = aspect, tanHalf = tanHalf, clear = NEAR_CLEAR })
		return view, distance
	end
	local third, second, first = shotOf({ 3 }, CLOSE, CLOSE_TOP), shotOf({ 2 }, CLOSE, CLOSE_TOP), shotOf({ 1 }, CLOSE, CLOSE_TOP)
	local group, groupDistance = shotOf({ 1, 2, 3 }, 0)
	state.overhead = { view = group, depth = groupDistance, y = deskTop + 1.5 * height }
	local drift = group + group.LookVector * groupDistance * PUSH_IN
	state.plateGui, state.plates = makePlates(winners)
	state.confetti = makeConfetti(CFrame.new(middle + Vector3.new(0, 1.5 * height, 0)), Vector3.new(2 * across + height, 1, height * 0.8), height)

	-- Roblox scales an animation's hip movement twice on a scaled-up avatar (27 x 27 instead of 27, measured
	-- 2026-10-17), which throws the body far off its root. Once standing, take the extra scale back out each step.
	state.fixHips = RunService.PreSimulation:Connect(function()
		for _, w in state.winners do
			if w.stood and w.hips then w.hips.Transform = w.hips.Transform.Rotation + w.hips.Transform.Position / w.scale end
		end
	end)

	local arrive = BANNER + GLIDE
	local leave = math.max(arrive + ZOOM_AT + ZOOM + 1, Rounds.results_seconds - CARD)
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
	-- The camera while it holds, `t` seconds after arriving: on 3rd, pan to 2nd, pan to 1st, zoom out to all three,
	-- then push in slowly.
	local function holdAt(t)
		if t < TURN - PAN then return third end
		if t < TURN then return third:Lerp(second, ease((t - TURN + PAN) / PAN)) end
		if t < 2 * TURN - PAN then return second end
		if t < 2 * TURN then return second:Lerp(first, ease((t - 2 * TURN + PAN) / PAN)) end
		if t < ZOOM_AT then return first end
		if t < ZOOM_AT + ZOOM then return first:Lerp(group, ease((t - ZOOM_AT) / ZOOM)) end
		return group:Lerp(drift, ease((t - ZOOM_AT - ZOOM) / (leave - arrive - ZOOM_AT - ZOOM)))
	end
	RunService:BindToRenderStep("WinnersCutscene", Enum.RenderPriority.Camera.Value + 3, function()
		local t = os.clock() - state.start
		-- The camera as the game would show it this frame (your plane or hangar view); if nothing moved it, where it was.
		local live = camera.CFrame ~= state.written and camera.CFrame or state.home
		local liveFov = camera.CFrame ~= state.written and camera.FieldOfView or state.fov
		state.home, state.fov = live, liveFov
		local hold = holdAt(t - arrive)
		local shot, fov
		if t < BANNER then shot, fov = live, liveFov
		elseif t < arrive then
			if not state.added then clearShot() end
			local a = ease((t - BANNER) / GLIDE)
			fadeShot(state, ease((t - BANNER) / (GLIDE * 0.6)))
			shot, fov = live:Lerp(third, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), liveFov + (SHOT_FOV - liveFov) * a
		elseif t < leave then shot, fov = hold, SHOT_FOV
		else
			local a = ease((t - leave) / GLIDE)
			fadeShot(state, 1 - a)
			shot, fov = hold:Lerp(live, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), SHOT_FOV + (liveFov - SHOT_FOV) * a
		end
		if t < arrive then seatWinners() end
		for _, w in state.winners do moveWinner(w, t - arrive) end
		local stage = t < arrive and "banner" or t < leave and "group" or "card"
		if stage ~= state.stage then state.stage = stage; onStage(stage) end
		if t >= leave + GLIDE then Cutscene.stop(); return end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame, camera.FieldOfView = shot, fov
		-- Confetti from 1st's landing until the camera leaves; the plates pop in once all three are in frame (Alan
		-- 2026-10-18), 3rd to 1st, each with its top on its desk's front edge.
		local landed = state.winners[1] and state.winners[1].landed
		local screen = camera.ViewportSize
		for place, w in state.winners do
			local plate = state.plates[place]
			local shown = t - arrive - ZOOM_AT - ZOOM - (3 - place) * 0.15
			plate.frame.Visible = shown > 0 and t < leave
			if plate.frame.Visible then
				local desk = desks[place]
				local edge = spots[place] + back * ((desk.Position - spots[place]):Dot(back) + desk.Size.Z / 2)
				local at = camera:WorldToViewportPoint(edge)
				plate.scale.Scale = screen.Y / 1080 * popIn(shown / 0.35)
				plate.frame.Position = UDim2.fromOffset(at.X, math.min(at.Y + 6, screen.Y - PLATE_H * screen.Y / 1080 - 8))
			end
		end
		for _, emitter in state.confetti:GetChildren() do
			if landed and t < leave and not emitter.Enabled then emitter:Emit(30) end
			emitter.Enabled = landed and t < leave
		end
		-- Focus on the winners, soft in front and a little behind. Roblox's focus stops at 500 studs, so a farther
		-- shot widens the sharp band instead.
		local strength = t < arrive and ease((t - BANNER) / GLIDE) or t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		local depth = math.max(0, (spots[1] - shot.Position):Dot(shot.LookVector))
		state.blur.FocusDistance = math.min(depth, 480)
		state.blur.InFocusRadius = math.min(500, depth - state.blur.FocusDistance + BLUR_RADIUS)
		state.blur.NearIntensity, state.blur.FarIntensity = BLUR_NEAR * strength, BLUR_FAR * strength
		state.written = shot
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
	state.plateGui:Destroy()
	state.confetti:Destroy()
	for item, was in state.moved do if item.Parent then item:PivotTo(was) end end
	workspace.CurrentCamera.CameraType, workspace.CurrentCamera.FieldOfView = state.cameraType, state.fov
	Root:SetAttribute("Cutscene", false)
end

return Cutscene
