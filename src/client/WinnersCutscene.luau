-- The winners' moment (Alan 2026-11-19, docs/decisions/2026-11-19-winners-circle-redo.md): "Pencils down!", the
-- room's lights fade to near-dark, and in the dark the camera glides from wherever you are (your plane or the
-- hangar) to one steady shot of the three winner desks by the chalkboard. Local copies of the top 3 already stand on
-- their desks as dark shapes. A spotlight clicks on over 3rd, then 2nd,
-- then 1st, each with its name plate (place, name, points), and each starts their emote in their own light. The
-- camera stays on all three (no zoom in, no confetti: Alan 2026-11-19), then the lights come up as it glides back and
-- the results card shows. Each winner stands on a stack of books, 1st's the tallest.
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
-- Seconds. The banner alone, the lights fading out, the glide over in the dark. After arriving: 3rd's spotlight at
-- LIGHT_AT, then 2nd's and 1st's TURN apart.
local BANNER, DIM, GLIDE = 0.5, 1.5, 2.0
local LIGHT_AT, TURN = 0.6, 1.0
local CARD = 10 -- the results card's seconds at the end of the winners' moment (Alan 2026-10-18: about 10)
local ARC = 250 -- studs the camera rises mid-glide, so it sweeps over the room instead of skimming through it
-- The shot, square on to the desk row: the lens, a slow push in over the whole hold (share of the distance), and the
-- frame: wide enough that SIDE_ROOM fits beside the outside winners (body, arms and the whole plate: Alan 2026-10-18),
-- from GROUP_EYE over the desk top looking GROUP_TILT degrees down at them. One steady shot of all three: the zoom
-- in on 1st is gone (Alan 2026-11-19: they kept coming out of frame). Sizes in winner heights.
local SHOT_FOV, PUSH_IN, SIDE_ROOM = 50, 0.04, 1.2
local GROUP_TILT, GROUP_EYE = 8, 1.6
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
local BLUR_FAR = 0.2
-- Only what would block a winner in their shot fades out on this screen; the rest of the town and the ceiling
-- decorations stay in view. Never faded: the room shell, the chalkboard, desks, chairs and the desks' hangars and
-- runways. Always faded: planes, other name tags, the desk landing rings and the monorail's pillars and track.
local KEEP_ARENA = { "^Wall", "^Floor", "^Window", "^Chalkboard", "^Desk", "^Chair", "^NeutralDesk" }
local KEEP_TOYS = { ["school-desk"] = true, ["school-chair"] = true, ["desk-hangar"] = true, ["desk-runway-droop"] = true,
	["runway-light"] = true, ["runway-light-tip"] = true }
-- The dark, on this screen only, is a curtain (Alan's OK 2026-11-20): one nearly black, slightly see-through sheet
-- that fills the view, so the room behind it can only just be made out (CURTAIN_CLEAR: how much of the room shows).
-- The room's own lighting is never touched. While the dark comes down and the camera glides, the curtain hangs
-- CURTAIN_LENS studs from the lens, in front of everything; while the camera holds on the winners it hangs
-- CURTAIN_BEHIND studs away, just behind them.
local CURTAIN_CLEAR, CURTAIN_LENS, CURTAIN_BEHIND = 0.15, 1, 40 -- at 0.08 the room was pitch black (Play 2026-11-20); 0.15 not yet seen
-- The winners in the dark. Each winner, their books and their plane are real models at their NORMAL small size,
-- standing in the room right in front of the camera: every point of the big winner far away is moved towards the
-- camera by the avatar's scale, which gives exactly the same picture at full sharpness (drawn in layers,
-- ViewportFrames, they came out pixelated: Alan 2026-11-20). They are placed again every frame as the camera moves.
-- (At normal size animations also move the hips the right distance: on a scaled-up avatar Roblox scales that
-- movement twice, measured 2026-10-17.) They stand in front of the curtain in the room's ordinary light: no lamp
-- lights them (real spotlights on them came on late and pulsed: Alan in Play 2026-11-20). Unlit, a winner is a black
-- shape: a solid black Highlight over them, their books and plane, taken off in CLICK seconds when their spotlight
-- comes on. The spotlight itself is for show and stands in the small winner's world too: a see-through shaft just
-- behind them and a glowing pool under their books: the shaft's top over the desk and its width at the desk in
-- winner heights, and how see-through shaft and pool are.
local LAMP_COLOR = Color3.fromRGB(255, 244, 214)
local CLICK = 0.12
local IDLE = { [Enum.HumanoidRigType.R15] = "rbxassetid://507766666", [Enum.HumanoidRigType.R6] = "rbxassetid://180435571" } -- Roblox's standing idles
local SHAFT_TOP, SHAFT_WIDE, SHAFT_CLEAR, POOL_CLEAR = 3, 0.95, 0.82, 0.8
local Cutscene = {}
local active

-- A spotlight for show in `world` (a small winner's own model): `height` is that winner's real height in studs.
local function makeSpotlight(spot, back, height, world)
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Transparency = "WinnerLights", true, false, false, false, 1
	part.Size, part.CFrame = Vector3.one, CFrame.new(spot)
	local function at(offset)
		local point = Instance.new("Attachment")
		point.Position, point.Parent = offset, part
		return point
	end
	local shaft = Instance.new("Beam")
	shaft.Attachment0, shaft.Attachment1 = at((Vector3.yAxis * SHAFT_TOP - back * 0.2) * height), at(-back * 0.2 * height)
	shaft.Width0, shaft.Width1, shaft.FaceCamera, shaft.Segments = SHAFT_WIDE * height * 0.2, SHAFT_WIDE * height, true, 1
	shaft.Color, shaft.Transparency = ColorSequence.new(LAMP_COLOR), NumberSequence.new(SHAFT_CLEAR)
	shaft.LightEmission, shaft.LightInfluence, shaft.Enabled = 1, 0, false
	shaft.Parent = part
	local pool = Instance.new("Part")
	pool.Name, pool.Shape, pool.Material, pool.Color = "Pool", Enum.PartType.Cylinder, Enum.Material.Neon, LAMP_COLOR
	pool.Anchored, pool.CanCollide, pool.CanQuery, pool.CanTouch, pool.CastShadow, pool.Transparency = true, false, false, false, false, 1
	pool.Size = Vector3.new(0.004 * height, SHAFT_WIDE * height, SHAFT_WIDE * height)
	pool.CFrame = CFrame.new(spot + Vector3.yAxis * 0.002 * height) * CFrame.Angles(0, 0, math.rad(90)) -- lying flat on the desk top
	pool.Parent = part
	part.Parent = world
	return { part = part, shaft = shaft, pool = pool }
end
-- `glow`: the winner's own light, 0 off to 1 on; `room`: how much of it shows (it goes as the room's lights come
-- back); `seen`: how much of the winner shows. Their black cover comes off as the light comes on.
local function shine(w, glow, room, seen)
	w.light.shaft.Enabled = glow * room > 0.5
	w.light.pool.Transparency = 1 - (1 - POOL_CLEAR) * glow * room
	w.cover.Enabled, w.cover.FillTransparency = glow < 1, 1 - seen * (1 - glow)
end

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
		if entry.Name == "landing-ring" or entry.Name:match("^monorail%-pylon") or entry.Name:match("^monorail%-beam") then return "always" end
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

-- 1st's emote: playing with their plane (Alan 2026-10-18, docs/decisions/2026-10-18-emotes-and-bot-looks.md). A
-- full-body animation from Meshy text-to-motion (tools/meshy_to_r15.py) moves the body; a copy of their own plane
-- sits in the right hand, nose turning the way the hand moves. Studio tests set a temporary id on DevWinnerEmote.
local PLANE_LENGTH, PLANE_TURN = 0.3, 0.15 -- plane length as a share of the winner's height; how fast the nose turns
local function holdPlane(model, actorId, height, shrink)
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
	-- `height`: the winner's height its sizes are worked out for; `shrink`: how many times smaller the model itself is
	-- (Camera Flick works in the big winner's studs and places the small plane: see flickPlane).
	height = height or model:GetScale() * 5 -- an R15 avatar is about 5 studs tall at scale 1
	shrink = shrink or 1
	plane:ScaleTo(plane:GetScale() * height * PLANE_LENGTH / shrink / plane:GetExtentsSize().Z)
	plane.Name = "WinnerPlane"
	local box, size = plane:GetBoundingBox()
	return { plane = plane, hand = hand, grip = hand:FindFirstChild("RightGripAttachment"), length = height * PLANE_LENGTH, span = plane:GetExtentsSize().X * shrink,
		-- from its middle down to its underside (see flickPlane)
		belly = math.min(0.6 * shrink * (size.Y / 2 - plane:GetPivot():ToObjectSpace(box).Position.Y), 0.05 * height * PLANE_LENGTH),
		last = hand.Position, heading = model:GetPivot().LookVector }
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

-- Camera Flick, a 1st-place emote (Alan 2026-11-19; recipe and numbers: docs/workshop/emote-making.md): 1st throws
-- their plane at the camera; it fills the picture, the camera is knocked back, tips over forward, and the plane
-- slides down the lens; the scene moves on from there. First they look down and admire the plane, then up at the
-- camera (Alan 2026-11-19: the throw came too soon). The plane is held the way Roblox holds a tool (Alan
-- 2026-11-20: snugly in the hand on every body, nothing tuned per body): fixed to the hand's own grip point
-- (RightGripAttachment, which every avatar has where a tool sits in its hand) with the clip's one "Grip", so it only
-- ever moves with the hand, and the clip turns the wrist to show its bottom, its top, then to aim it at the camera.
-- At the clip's "Release" (seconds after 1st's light) it leaves the hand and flies FLICK_FLIGHT to the lens; the
-- camera's fall takes FLICK_FALL; the scene leaves FLICK_AFTER after the release.
-- Not uploaded yet (Alan's go), so it only plays in Studio: the cleaned-up clip (Assets.CameraFlickClip, made by
-- tools/emote_preview.lua) is registered for the session, when the Dev panel's "end: flick" button asked for it.
local FLICK_FLIGHT, FLICK_FALL, FLICK_AFTER = 0.42, 0.65, 1.73
local FLICK_FLAT = CFrame.Angles(0, 0, math.rad(15)) * CFrame.Angles(math.rad(90), 0, 0) -- on the lens: top to it, nose up, a little askew
local function flickClip()
	local clip = RunService:IsStudio() and Root:GetAttribute("DevCameraFlick") and Root.Assets:FindFirstChild("CameraFlickClip")
	if not clip then return nil end
	return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(clip),
		{ release = clip:GetAttribute("Release") or 0.87, grip = clip:GetAttribute("Grip") or CFrame.identity }
end
local function bounce(v)
	if v < 1 / 2.75 then return 7.5625 * v * v
	elseif v < 2 / 2.75 then v -= 1.5 / 2.75; return 7.5625 * v * v + 0.75
	elseif v < 2.5 / 2.75 then v -= 2.25 / 2.75; return 7.5625 * v * v + 0.9375 end
	v -= 2.625 / 2.75
	return 7.5625 * v * v + 0.984375
end
-- The camera `u` seconds after the plane hits it: knocked back and shaken, then it tips over forward and lands with
-- a bounce. `steady`: where it would be otherwise; sizes in winner heights.
local function knocked(steady, u, height)
	if u <= 0 then return steady end
	local jolt = 0.11 * height * math.exp(-u * 9) * math.sin(math.min(u / 0.05, 1) * math.pi / 2)
	local shake = Vector3.new(math.sin(u * 95), math.cos(u * 80), 0) * 0.016 * height * math.exp(-u * 10)
	local fall = bounce(math.clamp((u - 0.1) / FLICK_FALL, 0, 1))
	return CFrame.new(steady.Position - steady.LookVector * jolt + steady:VectorToWorldSpace(shake) - Vector3.yAxis * 0.34 * height * fall)
		* steady.Rotation * CFrame.Angles(math.rad(-68) * fall, 0, 0) * CFrame.Angles(0, 0, math.rad(10) * fall)
end
-- The plane `t` seconds after 1st's light: in the hand, then straight to the lens (fast off the hand, slower as it
-- fills the picture) turning flat as it arrives, then stuck on the lens and sliding down it. `view`: the camera this
-- frame; `steady`: without the knock. Worked out in the big winner's studs; the small plane is then put where it
-- looks the same (`put`).
local function flickPlane(w, t, view, steady, height)
	local prop, flick = w.prop, w.flick
	-- how far in front of the lens it ends, so its wings fill the picture (no nearer: the small plane would be cut off)
	local pressed = prop.span * 0.55
	local function put(at) prop.plane:PivotTo(at.Rotation + (view.Position + (at.Position - view.Position) / w.scale)) end
	if t < flick.release or not prop.held then
		-- Fixed to the hand's grip point, its middle a little ahead of the fingers, and lifted off the grip point until
		-- its underside clears this avatar's own hand: in the hand, never through it. (Its underside is 0.6 of the
		-- way to its lowest point and at most 0.05 of its length: what hangs under the wings may touch the fingers;
		-- with all of it the plane floated over the hand.)
		local grip = prop.hand.CFrame * (prop.grip and prop.grip.CFrame or CFrame.identity)
		local function room(point) return w.spot + (point - w.shift - w.spot) * w.scale end -- where that point of the small winner seems to be
		local under = CFrame.new(room(grip.Position)) * (grip.Rotation * flick.grip) * CFrame.new(0, 0, -prop.length * 0.05)
		local top = 0
		for i = 0, 7 do
			local corner = prop.hand.CFrame * (prop.hand.Size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5))
			top = math.max(top, under:PointToObjectSpace(room(corner)).Y)
		end
		prop.held = under * CFrame.new(0, top + prop.belly, 0)
		put(prop.held)
	elseif t < flick.release + FLICK_FLIGHT then
		local s = 1 - (1 - (t - flick.release) / FLICK_FLIGHT) ^ 2
		local from, to = prop.held.Position, (steady * CFrame.new(0, 0, -pressed)).Position
		local at = from:Lerp(to, s)
		local flying = CFrame.lookAt(at, at + (to - from).Unit) * CFrame.Angles(0, 0, math.rad(40) * s)
		put(flying:Lerp(CFrame.new(at) * (steady.Rotation * FLICK_FLAT), math.clamp((s - 0.8) / 0.2, 0, 1)))
	else
		local slide = math.max(t - flick.release - FLICK_FLIGHT - 0.45, 0)
		put(view * CFrame.new(0, -slide * slide * 3.7 * height, -pressed) * FLICK_FLAT)
	end
end

-- 1st's emote comes from the first list; 2nd and 3rd each get a different one from the second.
local picked = {}
local function emoteFor(place)
	local list, id = EMOTES[place == 1 and 1 or 2], nil
	repeat id = list[math.random(#list)] until place == 1 or id ~= picked[5 - place]
	picked[place] = id
	return id
end

-- The book podiums (Alan 2026-11-19): each winner stands on a stack of single books (Assets.WinnerBooks: eight
-- free Creator Store books, each its own model lying flat, 10 studs on its longer side, its thickness in "Thick"),
-- in clear steps (Alan 2026-11-19: on four, three and two books 1st's did not look taller than 2nd's): about 0.78,
-- 0.41 and 0.2 of a winner's height. Which books, bottom to top, under 1st, 2nd and 3rd; and a book's longer side in winner heights:
-- wider than a winner's stance, so they stand on it comfortably.
local STACKS = { { 1, 7, 4, 2, 3, 8 }, { 5, 8, 6, 4 }, { 8, 5 } }
local BOOK_WIDE = 0.56
-- Builds `place`'s stack on `spot` in a small winner's `world`, where everything is `shrink` times smaller; returns
-- the stack's height in the big winner's studs.
local function stackBooks(world, place, spot, shrink)
	local books, rise = Root.Assets:FindFirstChild("WinnerBooks"), 0
	local grow = BOOK_WIDE * Avatars.standing_height_studs / 10
	for i, id in STACKS[place] do
		local book = books and books:FindFirstChild("Book" .. id)
		if book then
			book = book:Clone()
			book:ScaleTo(book:GetScale() * grow / shrink)
			local askew = ((place * 7 + i * 5) % 5 - 2) * 5 -- each a little turned, the same every time
			book:PivotTo(CFrame.new(spot + Vector3.yAxis * rise / shrink) * CFrame.Angles(0, math.rad(askew), 0))
			book.Parent = world
			rise += book:GetAttribute("Thick") * grow
		end
	end
	return rise
end

-- A local copy of a winner's avatar in `world` (a model of its own), back at its normal small size, standing on its
-- book stack at `spot` (the desk top) and facing `facing`: it stands still in the dark until its spotlight comes on.
local function copyWinner(source, place, facing, actorId, spot, world)
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
	-- Feet sit this far below the root: hip height plus half the root for R15, the legs for R6.
	local leg = model:FindFirstChild("Left Leg")
	local feet = humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.HipHeight + rootPart.Size.Y / 2 or rootPart.Size.Y / 2 + (leg and leg.Size.Y or 2)
	local scale = model:GetScale()
	model:ScaleTo(1)
	-- The copy comes with its student's sitting pose: stood up straight, with Roblox's own standing idle under the emote.
	for _, joint in model:GetDescendants() do
		if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then joint.Transform = CFrame.identity end
	end
	local onDesk = spot + Vector3.new(0, (stackBooks(world, place, spot, scale) + feet) / scale, 0)
	local desk = CFrame.lookAt(onDesk, onDesk + facing)
	model:PivotTo(desk)
	rootPart.Anchored = true
	humanoid.EvaluateStateMachine, humanoid.DisplayDistanceType = false, Enum.HumanoidDisplayDistanceType.None
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then item.CanCollide, item.CanQuery, item.CanTouch = false, false, false end
	end
	model.Parent = world
	local flick, flickInfo
	if place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 then flick, flickInfo = flickClip() end
	local planeEmote = flick or Root:GetAttribute("DevWinnerEmote") or Rounds.winner_plane_emote
	local prop = place == 1 and planeEmote ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15
		and holdPlane(model, actorId, flick and Avatars.standing_height_studs, flick and scale) or nil
	flick = prop and flick
	local animation = Instance.new("Animation"); animation.AnimationId = prop and planeEmote or emoteFor(place)
	local emote = animator:LoadAnimation(animation); emote.Looped, emote.Priority = not flick, Enum.AnimationPriority.Action
	local standing = Instance.new("Animation"); standing.AnimationId = IDLE[humanoid.RigType] or IDLE[Enum.HumanoidRigType.R15]
	local idle = animator:LoadAnimation(standing); idle.Looped, idle.Priority = true, Enum.AnimationPriority.Idle
	idle:Play(0)
	return { model = model, emote = emote, prop = prop, flick = flick and flickInfo or nil, place = place, scale = scale, spot = spot, desk = desk, lit = false }
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
	state.set = Instance.new("Folder") -- the small winners, their books and plane ("Winner...": never hidden for the shot)
	state.set.Name, state.set.Parent = "WinnerStage", workspace
	-- The curtain: a flat black picture on an unseen sheet, so the room's light and shine never show on it.
	state.curtain = Instance.new("Part")
	state.curtain.Name, state.curtain.Anchored, state.curtain.CanCollide, state.curtain.CanQuery, state.curtain.CanTouch = "WinnerCurtain", true, false, false, false
	state.curtain.Transparency, state.curtain.CastShadow = 1, false
	local sheet = Instance.new("SurfaceGui")
	sheet.Face, sheet.LightInfluence, sheet.SizingMode, sheet.CanvasSize = Enum.NormalId.Back, 0, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(100, 100)
	state.shade = Instance.new("Frame")
	state.shade.Size, state.shade.BorderSizePixel, state.shade.BackgroundColor3, state.shade.BackgroundTransparency = UDim2.fromScale(1, 1), 0, Color3.new(), 1
	state.shade.Parent = sheet
	sheet.Parent = state.curtain
	state.curtain.Parent = state.set
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

	-- Once it is dark, the students at the winner desks step out of sight on this screen and copies of the winners
	-- stand on the desks, each under its own spotlight (off).
	local function standWinners()
		for place, desk in desks do
			local entry = winners[place]
			if entry and not state.winners[place] then
				for _, source in room:GetChildren() do
					if source:IsA("Model") and source:GetAttribute("PilotId") == entry.actorId then
						-- The small winner's own model, moved as one: an anchor at the desk spot, the spotlight for show, and
						-- `cast` (the avatar, books and plane: what the black cover covers).
						local world = Instance.new("Model")
						local anchor = Instance.new("Part")
						anchor.Name, anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch, anchor.Transparency = "Anchor", true, false, false, false, 1
						anchor.Size, anchor.CFrame, anchor.Parent = Vector3.one * 0.2, CFrame.new(spots[place]), world
						world.Name, world.PrimaryPart = "Winner" .. place .. "Stage", anchor
						local cast = Instance.new("Model")
						cast.Name, cast.Parent = "Cast", world
						world.Parent = state.set -- in the room before the avatar goes in: animations only load on an avatar that is in the game
						local copy = copyWinner(source, place, back, entry.actorId, spots[place], cast)
						if copy then
							copy.world, copy.light = world, makeSpotlight(spots[place], back, height / copy.scale, world)
							copy.cover = Instance.new("Highlight")
							copy.cover.Name, copy.cover.FillColor, copy.cover.FillTransparency, copy.cover.OutlineTransparency = "Unlit", Color3.new(), 1, 1
							copy.cover.DepthMode, copy.cover.Parent = Enum.HighlightDepthMode.Occluded, cast
							if copy.flick then
								copy.prop.plane.Parent = cast
								state.flickAt = LIGHT_AT + 2 * TURN + copy.flick.release -- the release, in seconds after arriving
							end
							copy.fading = {} -- everything of theirs that fades in and out
							for _, piece in cast:GetDescendants() do
								if piece:IsA("BasePart") and piece.Transparency < 1 or piece:IsA("Decal") or piece:IsA("Texture") then table.insert(copy.fading, piece) end
							end
							state.winners[place] = copy
						else world:Destroy() end
						break
					end
				end
				local w = state.winners[place]
				local chair = w and room:FindFirstChild("Chair" .. desk.Name:sub(5))
				for _, model in room:GetChildren() do
					if chair and model:GetAttribute("SeatedAvatar") and flat(model:GetPivot().Position - chair.Position).Magnitude < 120 then
						state.hidden[model] = true; setHidden(model, true)
					end
				end
			end
		end
	end

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
	local top = deskTop + 2.1 * height -- over the head of a winner on the tallest stack
	local center = (chairs + flat(middle)) / 2 + back * 20 + Vector3.new(0, (deskTop + top) / 2, 0)
	local size = Vector3.new(2 * (across + SIDE_ROOM * height), top - deskTop, (flat(middle) - chairs).Magnitude + 120)
	local box = CFrame.fromMatrix(center, right, Vector3.yAxis)
	local points = { center }
	for i = 0, 7 do points[#points + 1] = box * (size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5)) end
	local groupDistance = (across + SIDE_ROOM * height) / aspect / tanHalf
	local tilt = -math.rad(GROUP_TILT)
	local eye = Vector3.new(middle.X, deskTop + GROUP_EYE * height, (spots[1].Z + spots[2].Z + spots[3].Z) / 3) + back * groupDistance
	local group = CFrame.lookAt(eye, eye - back * math.cos(tilt) + Vector3.yAxis * math.sin(tilt))
	local rect, near = onScreen(group, tanHalf, box, size)
	state.shots = { { view = group, rect = rect or { -1, -1, 1, 1 }, near = near, points = points, aspect = aspect, tanHalf = tanHalf, clear = NEAR_CLEAR } }
	state.overhead = { view = group, depth = groupDistance, y = deskTop + 1.5 * height }
	local drift = group + group.LookVector * groupDistance * PUSH_IN
	state.plateGui, state.plates = makePlates(winners)
	local depart = BANNER + DIM
	local arrive = depart + GLIDE
	-- When the camera leaves the winners: so the results card gets its CARD seconds, or as Camera Flick ends.
	local function leaving() return state.flickAt and arrive + state.flickAt + FLICK_AFTER or math.max(arrive + LIGHT_AT + 2 * TURN + 3, Rounds.results_seconds - CARD) end
	local function clearShot()
		state.added = workspace.DescendantAdded:Connect(function(item) hideForShot(state, item) end)
		task.spawn(function() -- a few hundred parts a frame, so nothing stutters; done well before the camera lands
			for i, item in workspace:GetDescendants() do
				if active ~= state then return end
				hideForShot(state, item)
				if i % 400 == 0 then RunService.Heartbeat:Wait() end
			end
			hideStrings(state)
		end)
	end
	-- The camera while it holds, `t` seconds after arriving: on all three, pushing in slowly (and where it would be
	-- without Camera Flick's knock).
	local function holdAt(t, leave)
		local steady = group:Lerp(drift, ease(t / (leave - arrive)))
		return state.flickAt and knocked(steady, t - state.flickAt - FLICK_FLIGHT, height) or steady, steady
	end
	RunService:BindToRenderStep("WinnersCutscene", Enum.RenderPriority.Camera.Value + 3, function()
		local t = os.clock() - state.start
		-- The camera as the game would show it this frame (your plane or hangar view); if nothing moved it, where it was.
		local live = camera.CFrame ~= state.written and camera.CFrame or state.home
		local liveFov = camera.CFrame ~= state.written and camera.FieldOfView or state.fov
		state.home, state.fov = live, liveFov
		local leave = leaving()
		local hold, steady = holdAt(t - arrive, leave)
		local shot, fov
		if t < depart then shot, fov = live, liveFov
		elseif t < arrive then
			local a = ease((t - depart) / GLIDE)
			fadeShot(state, ease((t - depart) / (GLIDE * 0.6)))
			shot, fov = live:Lerp(group, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), liveFov + (SHOT_FOV - liveFov) * a
		elseif t < leave then shot, fov = hold, SHOT_FOV
		else
			local a = ease((t - leave) / GLIDE)
			fadeShot(state, 1 - a)
			shot, fov = hold:Lerp(live, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), SHOT_FOV + (liveFov - SHOT_FOV) * a
		end
		if t >= BANNER and not state.added then clearShot() end
		-- The dark: the curtain comes down over DIM and lifts as the camera leaves; each spotlight on at its turn, off with the dark.
		local up = t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		local far = t >= arrive and t < leave + GLIDE * 0.4 -- behind the winners while they are in view, else at the lens
		local away = far and CURTAIN_BEHIND or CURTAIN_LENS
		local tall = 3 * away * math.tan(math.rad(fov / 2)) -- half as big again as the view
		state.curtain.Size, state.curtain.CFrame = Vector3.new(tall * aspect, tall, 0.05), shot * CFrame.new(0, 0, -away)
		state.shade.BackgroundTransparency = 1 - (1 - CURTAIN_CLEAR) * (t < depart and ease((t - BANNER) / DIM) or up)
		if t >= depart and t < arrive then standWinners() end
		-- The small winners are put in front of the camera where they look like big ones on their desks; they fade in at
		-- the end of the glide over and out on the way home (they stand in front of everything in the room, so they
		-- must be gone before the camera turns away).
		local seen = t < arrive and ease((t - depart - GLIDE * 0.6) / (GLIDE * 0.4)) or 1 - ease((t - leave) / (GLIDE * 0.4))
		for place, w in state.winners do
			local since = t - arrive - LIGHT_AT - (3 - place) * TURN
			if since >= 0 and not w.lit then w.lit = true; w.emote:Play(0.3) end
			shine(w, math.clamp(since / CLICK, 0, 1), up, seen)
			-- every point of the big winner, moved towards the camera by their scale: for the small winner standing at
			-- the desk spot that is one slide
			w.shift = (shot.Position - w.spot) * (1 - 1 / w.scale)
			w.world:PivotTo(CFrame.new(w.spot + w.shift))
			if w.seen ~= seen then
				w.seen = seen
				for _, piece in w.fading do piece.LocalTransparencyModifier = 1 - seen end
			end
			if w.flick then
				flickPlane(w, since, shot, steady, height)
			elseif w.prop and w.emote.IsPlaying then flyPlane(w) end
		end
		local stage = t < arrive and "banner" or t < leave and "group" or "card"
		if stage ~= state.stage then state.stage = stage; onStage(stage) end
		if t >= leave + GLIDE then Cutscene.stop(); return end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame, camera.FieldOfView = shot, fov
		-- Each plate pops in with its winner's light, its top on its desk's front edge.
		local screen = camera.ViewportSize
		for place, w in state.winners do
			local plate = state.plates[place]
			local shown = t - arrive - LIGHT_AT - (3 - place) * TURN
			plate.frame.Visible = shown > 0 and t < leave
			if plate.frame.Visible then
				local desk = desks[place]
				local edge = spots[place] + back * ((desk.Position - spots[place]):Dot(back) + desk.Size.Z / 2)
				local at = camera:WorldToViewportPoint(edge)
				plate.scale.Scale = screen.Y / 1080 * popIn(shown / 0.35)
				plate.frame.Position = UDim2.fromOffset(at.X, math.min(at.Y + 6, screen.Y - PLATE_H * screen.Y / 1080 - 8))
			end
		end
		-- Focus on the winners (the small ones, near the camera); the room behind them a little soft.
		local strength = t < arrive and ease((t - depart) / GLIDE) or t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		local first = state.winners[1] or state.winners[2] or state.winners[3]
		local depth = math.max(0, (spots[1] - shot.Position):Dot(shot.LookVector)) / (first and first.scale or 28)
		state.blur.FocusDistance, state.blur.InFocusRadius = depth, math.max(8, depth * 0.5)
		state.blur.NearIntensity, state.blur.FarIntensity = 0, BLUR_FAR * strength
		state.written = shot
	end)
end

function Cutscene.stop()
	if not active then return end
	local state = active
	active = nil
	RunService:UnbindFromRenderStep("WinnersCutscene")
	if state.set then state.set:Destroy() end
	for model in state.hidden do if model.Parent then setHidden(model, false) end end
	if state.added then state.added:Disconnect() end
	fadeShot(state, 0)
	for item, was in state.cleared do
		if was == true then item.Enabled = true elseif was == "visible" then item.Visible = true end
	end
	state.blur:Destroy()
	state.plateGui:Destroy()
	for item, was in state.moved do if item.Parent then item:PivotTo(was) end end
	workspace.CurrentCamera.CameraType, workspace.CurrentCamera.FieldOfView = state.cameraType, state.fov
	Root:SetAttribute("Cutscene", false)
end

return Cutscene
