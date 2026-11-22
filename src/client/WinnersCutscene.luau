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
local Audio = require(script.Parent.Audio)

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
-- The camera comes as close as the screen allows, both ways (Alan 2026-11-20: scale to the screen; the phone was too
-- zoomed out). Across: SIDE_ROOM beside the outside winners to the edge of the whole screen (at 1.1 on a phone their
-- arms and lights ran under its camera island and into its round corners; the outside name plates slide in to stay
-- whole). Up and down: the picture at the winners is never less than FRAME_TALL winner heights tall; at it the name
-- plates' bottoms reach the bottom of the screen. That is Alan's approved PC view (a pane 2.55 times wider than
-- tall, where 1.7 of side room came to the same distance), and it holds on any wider screen.
local SHOT_FOV, PUSH_IN, SIDE_ROOM, FRAME_TALL = 50, 0.04, 1.25, 3.45
local GROUP_TILT, GROUP_EYE = 8, 1.6
-- How far forward of the middle of their desk 1st and the others stand (shares of the desk depth): 1st a touch in
-- front. (At 0.32 and 0.22 the books stood on the desk's front edge and the light hung over it: Alan 2026-11-20.)
local FIRST_FORWARD, SIDE_FORWARD = 0.06, 0
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
-- CURTAIN_BEHIND studs away, behind them and their spotlights.
local CURTAIN_CLEAR, CURTAIN_LENS, CURTAIN_BEHIND = 0.15, 1, 60 -- at 0.08 the room was pitch black (Play 2026-11-20)
-- The winners in the dark. Each winner, their books and their plane are real models at their NORMAL small size,
-- standing in the room right in front of the camera: every point of the big winner far away is moved towards the
-- camera by the avatar's scale, which gives exactly the same picture at full sharpness (drawn in layers,
-- ViewportFrames, they came out pixelated: Alan 2026-11-20). They are placed again every frame as the camera moves.
-- (At normal size animations also move the hips the right distance: on a scaled-up avatar Roblox scales that
-- movement twice, measured 2026-10-17.) They stand in front of the curtain in the room's ordinary light: no lamp
-- lights them (real spotlights on them came on late and pulsed: Alan in Play 2026-11-20). Unlit, a winner is a black
-- shape: a solid black Highlight over them, their books and plane, taken off in CLICK seconds when their spotlight
-- comes on. The spotlight itself is for show: a real cone of light around them (Alan 2026-11-20: the flat strip
-- behind them looked bad) and a pool of light on the desk top under their books. The cone is CONE_LAYERS very faint
-- cones, one inside the other from full width down to nothing, so it is brightest in the middle and fades to its
-- edge (one cone alone looked like a glass tube; four showed stripes; Alan picked 24 at 0.99 from a Studio preview).
-- Its width at the desk and how far up its tip is are in winner heights (wide enough for held-out arms on the
-- tallest book stack; the tip is far off the top of the picture; up to CONE_BIG times wider for an avatar that
-- stands taller than the rest, so they are in their light too: Alan); then how see-through each layer and the pool
-- are. The pool is a glowing disc no wider than the desk is deep where they stand, so no light hangs out over the
-- desk's edge (Alan). So the light never lies over the winner (Alan: its haze made them milky and a white avatar
-- glowed), the whole spotlight stands LIGHT_BACK times further from the camera than the winner and that much bigger:
-- it lands on the same spot of the picture, behind them.
local LAMP_COLOR = Color3.fromRGB(255, 244, 214)
local CLICK = 0.12
local IDLE = { [Enum.HumanoidRigType.R15] = "rbxassetid://507766666", [Enum.HumanoidRigType.R6] = "rbxassetid://180435571" } -- Roblox's standing idles
local CONE_WIDE, CONE_TALL, CONE_LAYERS, CONE_CLEAR, CONE_BIG = 1.52, 8, 24, 0.99, 1.4
local POOL_CLEAR, LIGHT_BACK = 0.8, 1.8
local Cutscene = {}
local active

-- The cone's shape is Roblox's own classic cone (asset 1033714: 2 wide, 0.75 tall, tip up; measured 2026-11-20),
-- loaded once when the game starts.
local coneSource
task.spawn(function()
	local ok, cone = pcall(function() return game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri("rbxassetid://1033714")) end)
	if not ok then warn("WinnersCutscene: the spotlight cone did not load:", cone); return end
	cone.Name, cone.Anchored, cone.CanCollide, cone.CanQuery, cone.CanTouch, cone.CastShadow = "Cone", true, false, false, false, false
	cone.Material, cone.Color, cone.Transparency = Enum.Material.Neon, LAMP_COLOR, 1
	coneSource = cone
end)

-- A spotlight for show in `world` (the model of one winner's light), off: the cone `wide` at the desk and `tall`,
-- the pool `pool` across, in that model's studs.
local function makeSpotlight(spot, world, wide, tall, pool)
	local cones = {}
	for i = 1, coneSource and CONE_LAYERS or 0 do
		local across = wide * (1 - (i - 1) / CONE_LAYERS)
		local cone = coneSource:Clone()
		cone.Size, cone.CFrame = Vector3.new(across, tall, across), CFrame.new(spot + Vector3.yAxis * tall / 2)
		cone.Parent = world
		cones[i] = cone
	end
	local disc = Instance.new("Part")
	disc.Name, disc.Shape, disc.Material, disc.Color = "Pool", Enum.PartType.Cylinder, Enum.Material.Neon, LAMP_COLOR
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch, disc.CastShadow, disc.Transparency = true, false, false, false, false, 1
	disc.Size = Vector3.new(0.003 * wide, pool, pool)
	disc.CFrame = CFrame.new(spot + Vector3.yAxis * 0.0015 * wide) * CFrame.Angles(0, 0, math.rad(90)) -- lying flat on the desk top
	disc.Parent = world
	return { cones = cones, pool = disc }
end
-- `glow`: the winner's own light, 0 off to 1 on; `room`: how much of it shows (it goes as the room's lights come
-- back); `seen`: how much of the winner shows (the light goes with them). Their black cover comes off as the light
-- comes on.
local function shine(w, glow, room, seen)
	local level = glow * math.min(room, seen)
	if w.light.level ~= level then
		w.light.level = level
		w.light.pool.Transparency = 1 - (1 - POOL_CLEAR) * level
		for _, cone in w.light.cones do cone.Transparency = 1 - (1 - CONE_CLEAR) * level end
	end
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
	elseif item:IsA("BillboardGui") or (rule == "always" and (item:IsA("SurfaceGui") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("ParticleEmitter") or item:IsA("Highlight"))) then
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
-- Toy Pilot (ours, docs/workshop/emote-making.md) is played this way when the Dev panel's "end: pilot" button asked
-- for it: Studio only, from its draft clip, until it is uploaded.
local PLANE_LENGTH, PLANE_TURN = 0.3, 0.15 -- plane length as a share of the winner's height; how fast the nose turns
local function holdPlane(model, actorId, height, shrink)
	local planes = workspace:FindFirstChild("Planes")
	local source = planes and planes:FindFirstChild(tostring(actorId))
	local hand = model:FindFirstChild("RightHand")
	if not source or not hand then return nil end
	source.Archivable = true
	local plane = source:Clone()
	for _, item in plane:GetDescendants() do
		-- Highlight: the HUD's coloured outline round other planes came along with the copy and showed through the dark
		-- (Alan in Play 2026-11-20).
		if item:IsA("LuaSourceContainer") or item:IsA("BillboardGui") or item:IsA("JointInstance") or item:IsA("WeldConstraint") or item:IsA("Highlight") then item:Destroy()
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
		-- until the hand moves: side on to the room, nose out to the winner's right and a little up (pointing at the camera it was a sliver)
		heading = (model:GetPivot().RightVector * 0.8 + model:GetPivot().LookVector * 0.5 + Vector3.yAxis * 0.2).Unit }
end
local function flyPlane(w)
	local prop = w.prop
	local at = prop.hand.Position
	local here = at - w.shift -- without the slide that keeps the small winner in front of the camera: only the hand's own movement turns the nose
	local moved = here - (prop.last or here)
	prop.last = here
	if moved.Magnitude > prop.length * 0.002 then prop.heading = prop.heading:Lerp(moved.Unit, PLANE_TURN).Unit end
	local grip = at + prop.heading * prop.length * 0.3 -- held by the tail
	local up = math.abs(prop.heading.Y) > 0.97 and w.desk.LookVector or Vector3.yAxis
	prop.plane:PivotTo(CFrame.lookAt(grip, grip + prop.heading, up))
end
-- Toy Pilot's sounds: a whoosh as the plane swoops down and out, and one as it comes back up (seconds after 1st's
-- light, which are the clip's own). A quiet whoosh, in time with the plane's moves, and nothing else (Alan
-- 2026-11-21: "this is practically it").
local PILOT_SOUNDS = { 3.0, 4.5 }
local function pilotSounds(w, t)
	for index, at in PILOT_SOUNDS do
		if (w.heard or 0) < index and t >= at then
			w.heard = index
			Audio.play("pilotWhoosh")
		end
	end
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
-- Its clip is uploaded (Alan's go 2026-11-21); it still plays in Studio only, when the Dev panel's "end: flick"
-- button asked for it, until who gets which emote is decided.
local FLICK_FLIGHT, FLICK_FALL, FLICK_AFTER = 0.42, 0.65, 1.73
local FLICK_FLAT = CFrame.Angles(0, 0, math.rad(15)) * CFrame.Angles(math.rad(90), 0, 0) -- on the lens: top to it, nose up, a little askew
-- Our own emote clips (docs/workshop/emote-making.md) are uploaded animations, their ids in the config
-- (rounds.emote_clips). One still being worked on sits in Assets as "<name>Clip" (tools/emote_clips.lua and
-- tools/emote_preview.lua bake it there) and is played instead, registered for the Studio session: `ourClip` gives
-- the id to play and that draft, which carries its own moments as attributes (an uploaded clip's are in the config).
local function ourClip(name)
	local draft = RunService:IsStudio() and Root.Assets:FindFirstChild(name .. "Clip") or nil
	if draft then return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(draft), draft end
	return Rounds.emote_clips[name], nil
end
local function flickClip()
	if not (RunService:IsStudio() and Root:GetAttribute("DevFirstEmote") == "CameraFlick") then return nil end
	local id, draft = ourClip("CameraFlick")
	return id, { release = draft and draft:GetAttribute("Release") or Rounds.camera_flick_release,
		grip = draft and draft:GetAttribute("Grip") or CFrame.new(table.unpack(Rounds.camera_flick_grip)) }
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
-- Camera Flick's sounds, each once, `t` seconds after 1st's light: the throw at the release, the smack as the plane
-- reaches the lens, the camera hitting the ground at its fall's first bounce (see `knocked` and `bounce`).
local FLICK_SOUNDS = { { "flickThrow", 0 }, { "flickSmack", FLICK_FLIGHT }, { "flickFall", FLICK_FLIGHT + 0.1 + FLICK_FALL / 2.75 } }
local function flickSounds(w, t)
	for index, cue in FLICK_SOUNDS do
		if (w.heard or 0) < index and t >= w.flick.release + cue[2] then
			w.heard = index
			Audio.play(cue[1])
		end
	end
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

-- Book Kicker, a 1st-place emote (Alan 2026-11-21; docs/workshop/emote-making.md): 1st jumps down off their book
-- stack, landing a little to its side, still facing the camera, and kicks it at the camera. The clip keeps the kid
-- at one height and moves them sideways; here they are dropped by their own stack's height between the clip's
-- HopFrom and HopTo (rising HopUp winner heights first), and at its Kick the books burst towards the camera. The
-- top one opens on the way, slaps flat on the lens KICK_FLIGHT later (the camera jolts), covers the picture for
-- KICK_STUCK and slides down it while the scene leaves (KICK_AFTER after the kick): what it uncovers is the way
-- back to your desk. The others pass beside the lens. Studio only, from its draft clip, behind the Dev panel's
-- "end: kicker" button, until it is uploaded and who gets which emote is decided.
local KICK_FLIGHT, KICK_STUCK, KICK_AFTER = 0.45, 0.45, 0.95
local KICK_PAGES, KICK_COVER = Color3.fromRGB(244, 236, 214), Color3.fromRGB(40, 60, 120)
-- On the lens: the pages to it, but not square on (Alan 2026-11-21: "for it to land perfect like that would be
-- insane ... tilted, not so vertical and symmetrical"): turned KICK_ROLL degrees in the picture, one side KICK_LEAN
-- degrees nearer than the other, its spine KICK_OFF of the book's width and height off the middle; and close enough
-- (KICK_FILL of the distance at which the pages just fill the picture) that turned like that it still covers it.
-- And out of focus, as a book held against a lens is ("it would be hard to read what was in it"): the whole
-- picture is blurred (a BlurEffect; name plates and other screen pieces stay sharp), more the nearer the book is
-- (Alan 2026-11-21: "it should get blurrier as it gets closer to the camera", from sharp to the heaviest of three
-- strengths he was shown, "C", once it is on the lens: KICK_BLUR of the screen's height), as a real lens does: by
-- how much nearer than the winners it is, counted in 1 / distance, so most of it comes in the last part of the
-- flight (the book ends KICK_NEAR of the winners' distance from the lens). It clears as the book slides off: the
-- room it uncovers comes back into focus. (The focus effect's near blur was tried first and left the pages sharp
-- in Play, 2026-11-21.)
local KICK_ROLL, KICK_LEAN, KICK_OFF, KICK_FILL, KICK_BLUR, KICK_NEAR = -11, 5, Vector2.new(0.09, 0.05), 0.68, 0.025, 0.1
local KICK_FLAT = CFrame.Angles(0, 0, math.rad(KICK_ROLL)) * CFrame.Angles(0, math.rad(KICK_LEAN), 0) * CFrame.Angles(math.rad(90), 0, 0)
-- Where they land, in winner heights from the stack's middle: to their own left and back (Alan 2026-11-21 on the
-- first run, where they landed 0.65 out: "landing outside the spotlight ... landing closer to the book ... you can't
-- see the tip of her foot because it's behind the box. Right now, it looks like she's kicking the air"). From the
-- clip, measured on the test kid (tools/emote_clips.lua): at the kick the foot's tip is 0.43 to the right of their
-- middle and 0.25 in front of it, and their trunk is 0.11 deep; the stack's side is 0.26 out, its back 0.28 behind.
-- So the tip ends 0.12 behind the stack's side (0.14 = 0.26 - 0.12) and reaches its back as the books go, and the
-- trunk stays behind the stack's back; never further out than 0.45, the edge of the bright part of the beam (a
-- standard kid's foot then goes 0.24 behind the stack). `legs`: their hip height against a standard kid's
-- (KICK_HIPS winner heights): short legs reach less far, so they land closer.
local KICK_HIPS = 0.423
local function kickLanding(legs)
	return math.min(0.45, 0.14 + 0.43 * legs), 0.3 + 0.17 * legs
end
-- A page's writing (Alan 2026-11-21: "fake scribbles to make it look like it's filled with stuff, but nothing
-- actually legible"): rows of joined-up handwriting that says nothing, in ink: words of uneven length, their strokes
-- up from the line and back with a tall or a hanging one now and then, a row left empty here and there as between
-- paragraphs; the same every time. Path2D strokes (as UnlockMoment's ink) on the page's `face`, off until the kick.
-- On a top or bottom face the canvas's x runs along the part's z, here the spine (seen in Play 2026-11-21, where a
-- first try's rows ran up the page, and were three times too big): so the rows run down the canvas, side by side
-- along it. Margins and rows are the same from both ends, so it does not matter which way up a page's canvas is.
local KICK_INK, KICK_CANVAS = Color3.fromRGB(40, 30, 24), 600
local function scribbled(page, face, seed)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.Enabled = face, Enum.SurfaceGuiSizingMode.FixedSize, false
	gui.CanvasSize = Vector2.new(math.round(KICK_CANVAS * page.Size.Z / page.Size.X), KICK_CANVAS)
	local sheet = Instance.new("Frame")
	sheet.BackgroundTransparency, sheet.Size, sheet.Parent = 1, UDim2.fromScale(1, 1), gui
	local random = Random.new(seed)
	for row = 44, gui.CanvasSize.X - 44, 24 do
		if random:NextNumber() < 0.12 then continue end
		local at = 40
		while at < KICK_CANVAS - 60 do
			local points, to, up = {}, math.min(at + random:NextNumber(22, 75), KICK_CANVAS - 40), false
			while at < to do
				local step = random:NextNumber(4, 6.5)
				local off = if up then -(random:NextNumber() < 0.14 and random:NextNumber(13, 15) or random:NextNumber(5, 8)) else random:NextNumber() < 0.08 and 5 or 0
				table.insert(points, Path2DControlPoint.new(UDim2.fromOffset(row + 4 + off, at), UDim2.fromOffset(0, -step / 2), UDim2.fromOffset(0, step / 2)))
				at += step
				up = not up
			end
			if #points > 1 then
				local path = Instance.new("Path2D")
				path.Color3, path.Thickness, path.Parent = KICK_INK, 2, sheet
				path:SetControlPoints(points)
			end
			at += random:NextNumber(9, 14)
		end
	end
	gui.Parent = page
	return gui
end
local function kickClip()
	if not (RunService:IsStudio() and Root:GetAttribute("DevFirstEmote") == "BookKicker") then return nil end
	local id, draft = ourClip("BookKicker")
	local marks = draft and draft:GetAttributes() or Rounds.book_kicker
	if not id or not marks or not marks.Kick then return nil end
	return id, marks
end
-- What the kick needs: the stack's books, and the book that opens: two halves hinged on a spine, covers in the top
-- book's colour and cream pages, as big as that book, unseen until it takes the top book's place at the kick.
-- Each piece's place is from the spine's middle, the pages up; `rise`: the stack's height in the big winner's studs;
-- `legs`: see kickLanding.
local function kickProps(stack, cast, rise, marks, legs)
	local top = stack[#stack]
	if not top then return nil end
	local box, size = top:GetBoundingBox()
	local colour, most = KICK_COVER, 0
	for _, part in top:GetDescendants() do -- its biggest coloured face
		if part:IsA("BasePart") then
			local _, saturation = part.Color:ToHSV()
			local face = part.Size.X * part.Size.Z
			if saturation > 0.15 and face > most then most, colour = face, part.Color end
		end
	end
	local model, halves, pages = Instance.new("Model"), {}, {}
	model.Name = "KickedBook"
	for half = 1, 2 do
		local side = half == 1 and -1 or 1 -- the lower half under the spine's level, the upper one over it
		halves[half] = {}
		for index, piece in { { size.X, size.Y * 0.08, size.Z, side * size.Y * 0.46, colour }, { size.X * 0.94, size.Y * 0.4, size.Z * 0.94, side * size.Y * 0.21, KICK_PAGES } } do
			local part = Instance.new("Part")
			part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
			part.Size, part.Color, part.Material, part.Transparency = Vector3.new(piece[1], piece[2], piece[3]), piece[5], Enum.Material.SmoothPlastic, 1
			part.Parent = model
			table.insert(halves[half], { part = part, at = CFrame.new(size.X / 2, piece[4], 0) })
			-- the pages' open side: the lower half's top, the upper half's underside
			if index == 2 then pages[half] = scribbled(part, half == 1 and Enum.NormalId.Top or Enum.NormalId.Bottom, half) end
		end
	end
	model.Parent = cast
	local side, back = kickLanding(math.clamp(legs, 0.3, 1.5))
	return { marks = marks, rise = rise, side = side, back = back, stack = stack, top = top, halves = halves, pages = pages, wide = size.X, deep = size.Z, lies = top:GetPivot():ToObjectSpace(box) }
end
-- The camera `u` seconds after the book hits it: knocked back and shaken (Camera Flick's knock without the fall).
local function jolted(steady, u, height)
	if u <= 0 then return steady end
	local jolt = 0.11 * height * math.exp(-u * 9) * math.sin(math.min(u / 0.05, 1) * math.pi / 2)
	local shake = Vector3.new(math.sin(u * 95), math.cos(u * 80), 0) * 0.016 * height * math.exp(-u * 10)
	return steady + (steady:VectorToWorldSpace(shake) - steady.LookVector * jolt)
end
-- The kid's drop and the books `t` seconds after 1st's light. `view`: the camera this frame; `steady`: without the
-- jolt. Worked out in the big winner's studs; each small book is then put where it looks the same (`put`).
local function kickBooks(w, t, view, steady, height)
	local kick = w.kick
	local marks = kick.marks
	local hop = math.clamp((t - marks.HopFrom) / (marks.HopTo - marks.HopFrom), 0, 1)
	if hop > 0 then -- out sideways first, then down: the feet pass the stack's back corner above it
		local out = (1 - (1 - hop) ^ 3) * height / w.scale
		w.model:PivotTo((w.desk + w.shift) * CFrame.new(-kick.side * out, (4 * marks.HopUp * height * hop * (1 - hop) - kick.rise * hop * hop) / w.scale, kick.back * out))
		if hop >= 1 and not kick.landed then -- the feet reach the floor: a soft thump
			kick.landed = true
			Audio.play("kickLand")
		end
	end
	local flown = t - marks.Kick
	if flown < 0 then return end
	local function small(at) return at.Rotation + (view.Position + (at.Position - view.Position) / w.scale) end
	if not kick.from then -- the kick: where each book was, as the big winner's; the top one makes way for the one that opens
		kick.from = {}
		Audio.play("kickThud") -- the foot on the books; the book on the lens follows in the same sound
		for i, book in kick.stack do
			local at = book:GetPivot()
			kick.from[i] = at.Rotation + (w.spot + (at.Position - w.shift - w.spot) * w.scale)
		end
		for _, part in kick.top:GetDescendants() do if part:IsA("BasePart") then part.Transparency = 1 end end
		for _, pieces in kick.halves do for _, piece in pieces do piece.part.Transparency = 0 end end
		for _, page in kick.pages do page.Enabled = true end
		-- where the open book ends, from the lens: near enough that its pages cover the picture
		local screen = workspace.CurrentCamera.ViewportSize
		local tanHalf = math.tan(math.rad(SHOT_FOV / 2))
		local pressed = KICK_FILL * math.min(kick.wide / (tanHalf * screen.X / math.max(screen.Y, 1)), kick.deep / (2 * tanHalf))
		kick.lands = Vector3.new(KICK_OFF.X * kick.wide, KICK_OFF.Y * kick.deep, -pressed) * w.scale
	end
	for i = 1, #kick.stack - 1 do -- past the lens on both sides, tumbling; gone once behind it
		local book, from = kick.stack[i], kick.from[i]
		local s = flown / (KICK_FLIGHT * (1.1 + 0.12 * i))
		if s < 1.15 then
			local side = i % 2 == 0 and 1 or -1
			local aim = steady * Vector3.new(side * (0.9 + 0.25 * (i % 3)) * height, (0.15 * i - 0.2) * height, 0)
			local at = from.Position:Lerp(aim, s) + Vector3.yAxis * 0.1 * height * math.sin(math.min(s, 1) * math.pi)
			book:PivotTo(small(CFrame.new(at) * CFrame.fromAxisAngle(Vector3.new(side, 0.3 * i, 0.6).Unit, flown * (7 + i)) * from.Rotation))
		elseif not kick.gone or kick.gone < i then
			kick.gone = i
			for _, part in book:GetDescendants() do if part:IsA("BasePart") then part.Transparency = 1 end end
		end
	end
	local spine, opened -- the book's middle shut, its spine open
	if flown < KICK_FLIGHT then
		local s = 1 - (1 - flown / KICK_FLIGHT) ^ 2
		local from = kick.from[#kick.stack] * (kick.lies.Rotation + kick.lies.Position * w.scale) -- its middle, not its pivot
		local at = from.Position:Lerp(steady * kick.lands, s)
		local tumbling = CFrame.new(at) * CFrame.fromAxisAngle(Vector3.new(1, 0.2, 0.3).Unit, (1 - s) * 9) * from.Rotation
		spine, opened = tumbling:Lerp(CFrame.new(at) * (steady.Rotation * KICK_FLAT), math.clamp((s - 0.6) / 0.4, 0, 1)), math.clamp((s - 0.3) / 0.6, 0, 1)
	else
		local slide = math.max(flown - KICK_FLIGHT - KICK_STUCK, 0)
		spine, opened = view * CFrame.new(kick.lands - Vector3.yAxis * slide * slide * 3.7 * height) * KICK_FLAT, 1
	end
	spine = small(spine) * CFrame.new(-kick.wide / 2 * (1 - opened), 0, 0)
	for half, pieces in kick.halves do
		local hinge = half == 2 and CFrame.Angles(0, 0, math.pi * opened) or CFrame.identity
		for _, piece in pieces do piece.part.CFrame = spine * hinge * piece.at end
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

-- The runner-up emotes (Alan's OK 2026-11-20: Good Game, Nap, Next One), for 2nd and 3rd: small, calm loops. Studio
-- only until who gets which is decided (all three approved by him in Play, their clips uploaded 2026-11-21): the Dev
-- panel's "2nd/3rd" button names one (DevRunnerUp).
local function runnerUpClip()
	local name = RunService:IsStudio() and Root:GetAttribute("DevRunnerUp")
	return name and (ourClip(name))
end

-- Good Game, the free one (Alan's OK on the remake 2026-11-20; he found arms typed in by numbers stiff and too
-- fast): real body moves, round and round, timed to show a runner-up's feelings (Alan 2026-11-20: the face can't
-- show it, so the movement must). A dramatic slow clap, in his words "1, 2, 3", a second between claps, "never
-- waiting ... one smooth rhythm" (his "the slow clap is good now"): Roblox's Applaud emote (a clap every half
-- second) at half speed for three claps. Then the wave he described: the arms drop to the sides, the right forearm
-- comes up into a low V, elbow down, hand beside the head, and sways five times, lazy, 0.8 s a wave
-- (the GoodGameWave clip, cut from a generated clip whose sway is 0.6 s: played at 0.75). Then the kid stands. (Tried and rejected by him: holding the hands apart and striking fast;
-- resting them together with a quick swing, 0.65 s a clap, from Fortnite's Slow Clap, "still too fast"; Roblox's
-- own wave, slowed and half raised, "too enthusiastic".)
-- Each step: { clip (Roblox's id or the name of one of ours), the clip's seconds played before the next step
-- starts, speed, weight } or { false, seconds }. What goodGame returns stands in for an AnimationTrack: Play only.
local GOOD_GAME = { { "rbxassetid://10713966026", 1.5, 0.5, 1 }, { "GoodGameWave", 5.6, 0.75, 1 }, { false, 2 } }
local GOOD_GAME_BLEND = 0.7
-- The hands by each body's own shape (Alan 2026-11-21, on two bots: "the hands dont connect and the waving is to
-- close to the body almost inside"). A clip turns joints by fixed angles, so each body's shoulders and arm lengths
-- carry the hands somewhere else: measured on the 12 bots, the wave's hand was beside the head on 4 and on the face
-- or chest on 7 (docs/workshop/emote-making.md). So after the clips have posed the arms they are bent again
-- (goodGameArms, with bendArm), from that pose and keeping each elbow on its own side:
-- * The clap: both hands go to the middle between where the clip has them, each stopping where the two hand boxes
--   touch along the line between them, times CLAP_PRESS (under 1: the boxes are a little bigger than the hands);
--   fully at each clap (every CLAP_EVERY seconds of the clip, from its start) and for CLAP_HOLD of its seconds around
--   it (0.2 s on screen at half speed: the contact is seen), not at all while the hands are open.
-- * The wave: once the wave has the arm, the raised hand is moved out sideways, by one distance for the whole wave
--   (the most it has needed so far), so that its middle is never nearer the body's middle than the chest's side,
--   nor than the head's side plus WAVE_PAST of the hand's width: exactly where the clip has it on a plain body, which
--   is left as it was. The sway, the low elbow and the wrist stay the clip's own; a hanging hand is left alone
--   (`raised`).
local CLAP_EVERY, CLAP_PRESS, CLAP_HOLD, WAVE_PAST = 0.5, 0.8, 0.1, 0.28
local goodGameArms -- below, after the arm bending it uses
-- 1st's emote owns the sound once its own effects begin (Alan 2026-11-21: the runner-ups' sounds "have to stop before
-- that ... naturally", and "shouldn't have existed" after): a runner-up's sound plays only if it will be over by
-- then, and never after. `firstSoundAt`: that moment on os.clock() in this scene; nil while 1st's emote has no sounds.
local firstSoundAt
local function runnerSound(name)
	if firstSoundAt and os.clock() + Audio.seconds(name) > firstSoundAt then return nil end
	return Audio.play(name)
end
local function goodGame(animator, model)
	local tracks = {}
	for i, step in GOOD_GAME do
		local id = step[1] and (step[1]:find("^rbxassetid") and step[1] or (ourClip(step[1])))
		if id then
			local animation = Instance.new("Animation"); animation.AnimationId = id
			tracks[i] = animator:LoadAnimation(animation); tracks[i].Looped, tracks[i].Priority = true, Enum.AnimationPriority.Action
		end
	end
	goodGameArms(model, tracks[1], tracks[2])
	-- The stance (the GoodGameStance clip): the weight on the right leg, the left foot out to the side, the hips
	-- tilted, from the dark on. It holds only the hips and legs, one priority above the clap and wave, which keep the
	-- chest, head and arms.
	local stance = ourClip("GoodGameStance")
	if stance then
		local animation = Instance.new("Animation"); animation.AnimationId = stance
		local hold = animator:LoadAnimation(animation); hold.Looped, hold.Priority = true, Enum.AnimationPriority.Action2
		hold:Play(0)
	end
	return { IsPlaying = false, Play = function()
		task.spawn(function()
			while model:IsDescendantOf(game) do -- the scene destroys the winners when it ends
				for i, step in GOOD_GAME do
					local track = tracks[i]
					if track then
						track:Play(GOOD_GAME_BLEND, step[4], step[3])
						track.TimePosition = 0
						local began = os.clock() -- a clip that never loads never gets there: move on after 12 s
						repeat task.wait() until track.TimePosition >= step[2] or os.clock() - began > 12 or not model:IsDescendantOf(game)
						track:Stop(GOOD_GAME_BLEND)
					else
						task.wait(step[2])
					end
				end
			end
		end)
	end }
end

-- Sitting emotes: the kid rests on the top book whatever their body (Alan in Play 2026-11-20: "the models are not
-- always sitting on the books. They're kind of floating": a clip drops every body's hips the same distance). Each
-- frame the kid is moved up or down so the lowest point of their hips and legs, taken as rounded limbs, is at
-- `seat` (an unseen part at the top of their stack, which moves with the stage).
local SEAT = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" }
local function sit(model, seat)
	local low = math.huge
	for _, name in SEAT do
		local part = model:FindFirstChild(name)
		if part then
			local at, half = part.CFrame, part.Size / 2
			low = math.min(low, at.Position.Y - math.sqrt((at.XVector.Y * half.X) ^ 2 + (at.YVector.Y * half.Y) ^ 2 + (at.ZVector.Y * half.Z) ^ 2))
		end
	end
	if low < math.huge then model:PivotTo(model:GetPivot() + Vector3.yAxis * (seat.Position.Y - low)) end
end

-- A hand put on a point, on every body (measured in Play 2026-11-20: one set of joint turns left the hand 0.5 to 0.7
-- studs off the head on some avatars; Roblox's IKControl closed that on some, stayed 0.75 off on one, and while the
-- kid was awake flipped one body's arm right over, up to 178 degrees a frame: the glitch Alan saw). So the arm is
-- bent here, after the animation has posed it and from that pose: the shoulder turns so the elbow is where a
-- two-bone arm must have it, on the side of `pole`, and the elbow turns so the hand's middle is on `target`;
-- `weight` 0 to 1 is how much of that is done. Measured in Play on four bodies: 0.00 studs off, nothing jumping.
-- `rig` gives every joint of a body and `at(part)`: where a part is by this frame's animation (its own CFrame is
-- still last frame's when this runs). Call from RunService.PreSimulation.
local function rig(model)
	local joints = {}
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") and item.Part0 and item.Part1 then
			joints[item.Part1] = { joint = item, c0 = item.C0, c1 = item.C1, parent = item.Part0 }
		elseif item:IsA("AnimationConstraint") and item.Attachment0 and item.Attachment1 then
			joints[item.Attachment1.Parent] = { joint = item, c0 = item.Attachment0.CFrame, c1 = item.Attachment1.CFrame, parent = item.Attachment0.Parent }
		end
	end
	local function at(part)
		local j = joints[part]
		return j and at(j.parent) * j.c0 * j.joint.Transform * j.c1:Inverse() or part.CFrame
	end
	return joints, at
end
local function arc(from, to) -- the shortest turn that takes one direction to another
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-6 then return CFrame.identity end
	return CFrame.fromAxisAngle(axis.Unit, math.atan2(axis.Magnitude, from:Dot(to)))
end
local function bendArm(joints, at, upper, lower, hand, target, pole, weight)
	local u, l = joints[upper], joints[lower]
	if not (u and l) or weight <= 0 then return end
	local turnU, turnL = u.joint.Transform, l.joint.Transform
	local shoulder = at(u.parent) * u.c0
	local bend = shoulder * turnU * u.c1:Inverse() * l.c0
	local s, elbow0, hand0 = shoulder.Position, bend.Position, at(hand).Position
	local l1, l2 = (elbow0 - s).Magnitude, (hand0 - elbow0).Magnitude
	local d = math.clamp((target - s).Magnitude, math.abs(l1 - l2) * 1.01, (l1 + l2) * 0.98)
	local along = (target - s).Unit
	local a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
	local out = pole - s
	out -= along * out:Dot(along)
	if out.Magnitude < 1e-4 then return end
	local elbow = s + along * a + out.Unit * math.sqrt(math.max(l1 * l1 - a * a, 0))
	local function some(turn) local axis, angle = turn:ToAxisAngle(); return CFrame.fromAxisAngle(axis, angle * weight) end
	local first = some(arc(elbow0 - s, elbow - s))
	local second = some(arc(s + first * (hand0 - s) - elbow, s + along * d - elbow))
	u.joint.Transform = shoulder.Rotation:Inverse() * first * (shoulder * turnU).Rotation + turnU.Position
	l.joint.Transform = (first * bend.Rotation):Inverse() * second * first * (bend * turnL).Rotation + turnL.Position
end

local function thick(size, at, along) -- half a hand box's thickness along a direction
	return (math.abs(along:Dot(at.XVector)) * size.X + math.abs(along:Dot(at.YVector)) * size.Y + math.abs(along:Dot(at.ZVector)) * size.Z) / 2
end
-- Good Game's arms on this body (see CLAP_EVERY): `applaud` and `wave` are its two tracks (`wave` may be missing).
function goodGameArms(model, applaud, wave)
	local part = {}
	for _, name in { "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand" } do
		part[name] = model:FindFirstChild(name)
		if not part[name] then return end
	end
	local chest, head = part.UpperTorso, part.Head
	local rUpper, rLower, rHand, lUpper, lLower, lHand = part.RightUpperArm, part.RightLowerArm, part.RightHand, part.LeftUpperArm, part.LeftLowerArm, part.LeftHand
	local joints, at = rig(model)
	for _, arm in { rUpper, rLower, rHand, lUpper, lLower, lHand } do if not joints[arm] then return end end
	local shoulder = joints[rUpper].c0.Position.Y -- in the chest's own frame
	local reach = (joints[rLower].c0.Position - joints[rUpper].c1.Position).Magnitude + (joints[rHand].c0.Position - joints[rLower].c1.Position).Magnitude
	local clapped
	local out = 0 -- how far the waving hand is moved out, this wave
	local beat
	beat = RunService.PreSimulation:Connect(function()
		if not model:IsDescendantOf(game) then beat:Disconnect(); return end
		local clap = math.floor(applaud.TimePosition / CLAP_EVERY) -- the sound, as the hands meet
		if clap ~= clapped then
			clapped = clap
			if clap > 0 and applaud.WeightCurrent > 0.5 then runnerSound("ggClap") end
		end
		local press = applaud.WeightCurrent * math.min(1, math.max(0, math.cos(applaud.TimePosition / CLAP_EVERY * 2 * math.pi)) / math.cos(CLAP_HOLD / CLAP_EVERY * math.pi))
		if press > 0 then
			local right, left = at(rHand), at(lHand)
			local apart = left.Position - right.Position
			if apart.Magnitude > 1e-3 then
				local along, middle = apart.Unit, (left.Position + right.Position) / 2
				local rElbow, lElbow = (at(rUpper) * joints[rLower].c0).Position, (at(lUpper) * joints[lLower].c0).Position
				bendArm(joints, at, rUpper, rLower, rHand, middle - along * thick(rHand.Size, right, along) * CLAP_PRESS, rElbow, press)
				bendArm(joints, at, lUpper, lLower, lHand, middle + along * thick(lHand.Size, left, along) * CLAP_PRESS, lElbow, press)
			end
		end
		local waving = wave and wave.WeightCurrent or 0
		if waving <= 0 then out = 0; return end
		local frame, hand = at(chest), at(rHand)
		local where = frame:PointToObjectSpace(hand.Position)
		local raised = math.clamp((where.Y - shoulder + 0.6 * reach) / (0.5 * reach), 0, 1)
		raised = raised * raised * (3 - 2 * raised)
		if raised <= 0 then return end
		if waving > 0.99 then -- the wave alone has the arm: the clap's pose must not count
			local clear = math.max(frame:PointToObjectSpace(at(head).Position).X + head.Size.X / 2 + WAVE_PAST * rHand.Size.X, chest.Size.X / 2)
			out = math.max(out, clear - where.X)
		end
		if out > 0 then
			local move = frame.XVector * out * raised
			bendArm(joints, at, rUpper, rLower, rHand, hand.Position + move, (at(rUpper) * joints[rLower].c0).Position + move, waving)
		end
	end)
end

-- Nap (Alan's own version 2026-11-20; the napper is bored and done, asleep at the back of the class): sitting
-- cross-legged, the right elbow on the thigh and the head hanging limp, face to the lap, held by the brow on the
-- hand (his second look: "their head needs to be more down ... it makes them look awake, if you can see their
-- faces"), asleep from the dark on
-- (the NapSleep clip, a loop: a breath every 4 s, a small nod). When 1st's light clicks on they jolt awake, sit
-- stiff, look right, left, right and forward, and sink back onto the hand in a dip, a catch and a sink
-- (the NapWake clip, once, one priority higher; it starts and ends in the loop's first pose). Both are cut by
-- tools/emote_clips.lua. The right arm is bent so the hand is on the brow on every body, the elbow towards the knee
-- (bendArm); from the jolt on that is let go (NAP_OFF seconds) and the clip alone leaves the hand in the air about
-- where the brow was; it comes back over the last NAP_ON seconds, as the head lands.
-- Two props, plain parts made here (sizes in head heights), in the kid's own frame so they keep their place on the
-- stage: three paper Z's, each three thin white strips, leave the head on the kid's right one every Z_EVERY seconds,
-- rise, drift, sway, grow and fade over Z_LIFE; a snore bubble at the mouth, out to the kid's left and towards the
-- camera so it shows under the lowered face, grows over
-- BUBBLE_GROW seconds, swelling and shrinking with the breath, and pops at the jolt (POP seconds, five small strips
-- flying off); a new one starts when they are asleep again. No Z's leave while they are awake.
local Z_EVERY, Z_LIFE, Z_RISE, Z_DRIFT, Z_SMALL, Z_BIG = 4 / 3, 4, 1.5, 0.6, 0.3, 0.9
local BUBBLE_SMALL, BUBBLE_BIG, BUBBLE_GROW, BUBBLE_BREATH, BUBBLE_CLEAR, POP, POP_BITS = 0.06, 0.25, 6, 0.03, 0.45, 0.1, 0.3
local NAP_BREATH, NAP_OFF, NAP_ON = 4, 0.15, 0.4 -- seconds a breath in the sleeping clip; the hand let go and taken back
local function paper(parent, color, shape) -- `shape`: a Part's shape, or "WedgePart" for a triangle
	local part = Instance.new(shape == "WedgePart" and "WedgePart" or "Part")
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Material, part.Color, part.Size = Enum.Material.SmoothPlastic, color, Vector3.one * 0.01
	if shape and shape ~= "WedgePart" then part.Shape = shape end
	part.Parent = parent
	return part
end
local function seatOn(cast, top) -- the unseen part at the top of a kid's stack that `sit` rests them on
	local seat = Instance.new("Part")
	seat.Name, seat.Anchored, seat.CanCollide, seat.CanQuery, seat.CanTouch, seat.Transparency = "Seat", true, false, false, false, 1
	seat.Size, seat.CFrame, seat.Parent = Vector3.one * 0.05, CFrame.new(top), cast
	return seat
end
local function nap(animator, model, place, cast, top)
	local head, hand, root = model:FindFirstChild("Head"), model:FindFirstChild("RightHand"), model:FindFirstChild("HumanoidRootPart")
	local upper, shin = model:FindFirstChild("RightUpperArm"), model:FindFirstChild("RightLowerLeg")
	local function track(name, looped, priority)
		local id = (ourClip(name))
		if not id then return nil end
		local animation = Instance.new("Animation"); animation.AnimationId = id
		local made = animator:LoadAnimation(animation); made.Looped, made.Priority = looped, priority
		return made
	end
	local sleep, wake = track("NapSleep", true, Enum.AnimationPriority.Action), track("NapWake", false, Enum.AnimationPriority.Action2)
	if not (sleep and wake and head and hand and root and upper and shin) then return { IsPlaying = false, Play = function() end } end
	sleep:Play(0)
	local seat = seatOn(cast, top)
	-- the hand against the right side of the brow (the same point the clips were cut for)
	local browAt = Vector3.new(0.22 * head.Size.X, -0.05 * head.Size.Y, -0.5 * head.Size.Z - 0.3 * hand.Size.Y)
	local joints, at = rig(model)
	local lower = model:FindFirstChild("RightLowerArm")
	local bent
	bent = RunService.PreSimulation:Connect(function()
		if not model:IsDescendantOf(game) then bent:Disconnect(); return end
		local weight = 1
		if wake.IsPlaying then weight = math.max(1 - wake.TimePosition / NAP_OFF, 1 - (wake.Length - wake.TimePosition) / NAP_ON, 0) end
		if lower then bendArm(joints, at, upper, lower, hand, at(head) * browAt, at(shin) * Vector3.new(0, shin.Size.Y / 2, 0), weight) end
	end)

	local size, white = head.Size.Y, Color3.new(1, 1, 1)
	local thin = 0.03 * size
	local zs = {}
	for i = 1, 3 do zs[i] = { paper(cast, white), paper(cast, white), paper(cast, white) } end -- top, slash, bottom
	local ball, glint, bits = paper(cast, Color3.fromRGB(190, 225, 255), Enum.PartType.Ball), paper(cast, white), {}
	for i = 1, 5 do bits[i] = paper(cast, white) end
	local nextZ = os.clock()
	local began = os.clock() - 0.75 * BUBBLE_GROW -- when this bubble started: the first is already big in the dark
	local popped, burst -- when the bubble popped; where and how big it was (the kid's frame)
	local lit, breath, snore -- in their light; the breath last snored on; that snore's sound (cut off by the pop)
	wake.Stopped:Connect(function() sleep.TimePosition = 0; began = os.clock() end)
	local beat
	beat = RunService.RenderStepped:Connect(function()
		if not model:IsDescendantOf(game) then beat:Disconnect(); return end
		sit(model, seat)
		local now, awake, stage = os.clock(), wake.IsPlaying, root.CFrame
		-- a snore on every breath asleep, once their light is on; the first as it comes on and as they doze off again
		if awake then
			breath = nil
		elseif lit and breath ~= math.floor(sleep.TimePosition / NAP_BREATH) then
			breath = math.floor(sleep.TimePosition / NAP_BREATH)
			snore = runnerSound("napSnore")
		end
		-- the Z's
		if not awake and now >= nextZ then
			for _, z in zs do
				if not z.born then
					z.born, z.from, nextZ = now, stage:PointToObjectSpace(head.Position) + Vector3.new(0.3, 0.45, 0) * size, now + Z_EVERY
					break
				end
			end
		end
		for i, z in zs do
			local age = z.born and now - z.born
			if age and age < Z_LIFE then
				local u = age / Z_LIFE
				local tall = size * (Z_SMALL + (Z_BIG - Z_SMALL) * u ^ 0.7)
				local wide, bar = tall * 0.8, tall * 0.16
				local at = stage * CFrame.new(z.from + Vector3.new(Z_DRIFT * u + 0.1 * math.sin(age * 2.2 + i), Z_RISE * u, 0) * size)
					* CFrame.Angles(0, math.rad(20) * math.sin(age * 1.3 + i), math.rad(10) * math.sin(age * 1.7 + i))
				local clear = math.max(1 - age / 0.3, (u - 0.65) / 0.35, 0)
				z[1].Size, z[1].CFrame = Vector3.new(wide, bar, thin), at * CFrame.new(0, (tall - bar) / 2, 0)
				z[3].Size, z[3].CFrame = Vector3.new(wide, bar, thin), at * CFrame.new(0, (bar - tall) / 2, 0)
				-- the slash: from the top bar's end on the viewer's right (the kid's left) down to the bottom bar's other end
				z[2].Size, z[2].CFrame = Vector3.new(math.sqrt((wide - bar) ^ 2 + (tall - bar) ^ 2), bar, thin), at * CFrame.Angles(0, 0, -math.atan2(tall - bar, wide - bar))
				for _, strip in ipairs(z) do strip.Transparency = clear end
			else
				z.born = nil
				for _, strip in ipairs(z) do strip.Transparency = 1 end
			end
		end
		-- the bubble
		local since = popped and now - popped
		if not awake then
			local grown = math.min((now - began) / BUBBLE_GROW, 1)
			local r = size * (BUBBLE_SMALL + (BUBBLE_BIG - BUBBLE_SMALL) * grown + BUBBLE_BREATH * math.sin(sleep.TimePosition / NAP_BREATH * 2 * math.pi))
			local mouth = head.CFrame * (Vector3.new(-0.2, -0.2, -0.5) * head.Size)
			local middle = mouth + (head.CFrame.LookVector * 0.4 + stage.LookVector * 0.6 - stage.RightVector * 0.6).Unit * r
			ball.Size, ball.CFrame, ball.Transparency = Vector3.one * 2 * r, CFrame.new(middle), BUBBLE_CLEAR
			burst = { at = stage:PointToObjectSpace(middle), r = r }
		elseif burst and since and since < POP then -- it puffs up and is gone
			local k = since / POP
			ball.Size, ball.CFrame, ball.Transparency = Vector3.one * 2 * burst.r * (1 + 0.35 * k), stage * CFrame.new(burst.at), BUBBLE_CLEAR + (1 - BUBBLE_CLEAR) * k
		else
			ball.Transparency = 1
		end
		local r = ball.Size.X / 2
		glint.Size, glint.Transparency = Vector3.new(0.4, 0.12, 0.02) * r, ball.Transparency < 1 and (ball.Transparency - BUBBLE_CLEAR) / (1 - BUBBLE_CLEAR) or 1
		glint.CFrame = stage.Rotation * CFrame.Angles(0, 0, math.rad(35)) + ball.Position + (stage.LookVector * 0.8 + stage.UpVector * 0.45 + stage.RightVector * 0.35) * r
		for i, bit in bits do
			if awake and burst and since and since < POP_BITS then
				local k, angle = since / POP_BITS, math.rad(i * 72 + 15)
				bit.Size, bit.Transparency = Vector3.new(0.45 * burst.r, 0.05 * size, thin), k
				bit.CFrame = stage * CFrame.new(burst.at + Vector3.new(math.cos(angle), math.sin(angle), 0) * burst.r * (1.1 + 1.4 * k)) * CFrame.Angles(0, 0, angle)
			else
				bit.Transparency = 1
			end
		end
	end)
	-- What nap returns stands in for an AnimationTrack (Play only): their own light changes nothing, 1st's wakes them.
	return { IsPlaying = false, Play = function()
		lit = true
		task.delay((place - 1) * TURN, function()
			if not model:IsDescendantOf(game) then return end
			wake:Play(0.05); popped = os.clock()
			if snore then snore:Stop() end
			runnerSound("napPop")
		end)
	end }
end

-- Next One (plan approved by Alan in words 2026-11-20: "fine, you got this one, the next one is mine"; already over
-- it and planning the rematch, busy, head down on the work): sitting cross-legged with a white sheet on the right
-- hand from the dark on; at their light the left hand runs over it four times, a still moment after each (RUNS),
-- and every run changes the paper once (Alan's first look in Play 2026-11-20: "they run their hands over it more
-- than the paper changes ... run their hand over it, it's flat, then ... again, then there's a fold, ... again,
-- there's another fold, ... again, and then it's done, and they pick it up"; a first build also ran the hand along
-- each new crease): the first smooths the flat sheet, the others fold it in half, fold the nose, fold the wings.
-- The paper really folds: ten thin white pieces, the two halves of a
-- sheet each cut along its folds, swung about the fold lines (`hinges`). Then the right hand raises the finished
-- plane to eye level and rocks it slowly, the kid looking at it, until the scene ends (no sighting along it: his
-- "leave the sighting out"). The body is the NextOne clip (tools/emote_clips.lua; the config has the moments of the
-- raise), held on its first pose until the light and going round its last seconds after the raise.
-- The paper does the acting (the generator cannot do hand work, and he found arms typed in by numbers stiff): it is
-- fixed to the right hand the way a tool is (its nose along the fingers, lying on the hand's thumb side), and the
-- left hand is put on it with bendArm: on the edge of the flap being folded, so its path is the fold's own arc,
-- then still, with a short hop to the next flap's edge just before its run. The clip holds the right hand in front
-- of the belly, fingers to the kid's left: the sheet lies across the body, its nose to their left, and each fold
-- goes away from or towards them. Sizes come from this avatar's own arm (his OK: a plane about a forearm long;
-- an avatar's two arms together only reach about a quarter of its height, so a bigger sheet cannot be folded).
-- The sheet's length in forearm parts; its width and thickness in lengths (letter paper); the keel's depth in
-- widths; where along it, from the nose, the right hand is.
local SHEET_LONG, SHEET_WIDE, SHEET_THIN, KEEL, HELD_AT = 0.9, 0.77, 0.012, 0.125, 0.7
-- Seconds after the kid's light: when each of the left hand's four runs starts and ends (the first over the flat
-- sheet, then the three folds), and how long before a run the hand hops to where it starts.
local RUNS, HOP = { { 0.15, 0.7 }, { 1.2, 1.75 }, { 2.25, 2.8 }, { 3.3, 3.85 } }, 0.25
-- The left hand's middle rides PRESS of its own half-thickness over the paper, and ARC more at the top of a fold
-- (the fold's arc alone is too small to see from the camera); it lets go over LET_GO seconds as the plane goes up;
-- the wings end WINGS_UP degrees above level.
local PRESS, ARC, LET_GO, WINGS_UP = 0.9, 0.6, 0.6, 10
local function nextOne(animator, model, cast, top)
	local hand, left, root = model:FindFirstChild("RightHand"), model:FindFirstChild("LeftHand"), model:FindFirstChild("HumanoidRootPart")
	local forearm, upper, lower = model:FindFirstChild("RightLowerArm"), model:FindFirstChild("LeftUpperArm"), model:FindFirstChild("LeftLowerArm")
	local id, draft = ourClip("NextOne")
	if not (id and hand and left and root and forearm and upper and lower) then return { IsPlaying = false, Play = function() end } end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local track = animator:LoadAnimation(animation); track.Looped, track.Priority = false, Enum.AnimationPriority.Action
	track:Play(0, 1, 0) -- its first pose, held: already at work in the dark
	local marks = Rounds.next_one
	local raise, raised, round = draft and draft:GetAttribute("Raise") or marks.raise, draft and draft:GetAttribute("Raised") or marks.raised, draft and draft:GetAttribute("Turn") or marks.turn
	local seat = seatOn(cast, top)
	local long = forearm.Size.Y * SHEET_LONG
	local wide, thin = long * SHEET_WIDE, long * SHEET_THIN
	local half, keel = wide / 2, wide * KEEL
	-- The paper's own frame: x to the plane's right, y up out of the sheet, the nose towards -z; its middle is the
	-- point of the wings' fold line that is on the right hand. `pt`: a point of the flat sheet, `u` to the right of
	-- its middle line and `v` back from its front edge.
	local function pt(u, v, y) return Vector3.new(u - keel, y or 0, v - HELD_AT * long) end
	-- The fold lines, each a point and a direction: a piece swung about one goes up and over.
	local back = Vector3.zAxis
	local hinges = { { at = pt(0, 0, thin / 2), axis = -back }, -- in half: the left half over onto the right
		{ at = pt(0, 0, 1.5 * thin), axis = Vector3.new(1, 0, 1).Unit }, -- the nose: the front outer corner, both layers
		{ at = pt(keel, 0, 1.5 * thin), axis = back }, -- the wings: the upper layer back over to the left
		{ at = pt(keel, 0, -thin / 2), axis = back }, -- as it is picked up: the keel down,
		{ at = pt(keel, 0, -thin / 2), axis = back }, { at = pt(keel, 0, 1.5 * thin), axis = -back } } -- the right and left wings tipped up
	local function swung(i, angle) return CFrame.new(hinges[i].at) * CFrame.fromAxisAngle(hinges[i].axis, angle) * CFrame.new(-hinges[i].at) end
	-- The pieces: each where it lies in the flat sheet, and the fold lines it swings about, in order.
	local pieces, white = {}, Color3.new(1, 1, 1)
	local function strip(side, folds, u0, v0, u1, v1) -- a rectangle
		local part = paper(cast, white)
		part.Size = Vector3.new(u1 - u0, thin, v1 - v0)
		table.insert(pieces, { part = part, at = CFrame.new(pt(side * (u0 + u1) / 2, (v0 + v1) / 2)), folds = folds })
	end
	local function corner(side, folds, ru, rv, au, av, bu, bv) -- a triangle: its right angle, then its other two corners
		local r, a, b = pt(side * ru, rv), pt(side * au, av), pt(side * bu, bv)
		local part = paper(cast, white, "WedgePart")
		part.Size = Vector3.new(thin, (a - r).Magnitude, (b - r).Magnitude)
		local y, z = (a - r).Unit, (r - b).Unit
		table.insert(pieces, { part = part, at = CFrame.fromMatrix((a + b) / 2, y:Cross(z), y, z), folds = folds })
	end
	for side, folds in { [1] = { nose = { 2 }, keel = { 4 }, wing = { 5 } }, [-1] = { nose = { 1, 2 }, keel = { 1, 4 }, wing = { 1, 3, 6 } } } do
		corner(side, folds.nose, half, 0, 0, 0, half, half)
		pieces[#pieces].tucked = true -- once folded it lies flat on the rest, white on white: not drawn from then on
		corner(side, folds.keel, 0, keel, 0, 0, keel, keel)
		strip(side, folds.keel, 0, keel, keel, long)
		corner(side, folds.wing, keel, half, keel, keel, half, half)
		strip(side, folds.wing, keel, half, half, long)
	end
	-- How far each fold line is turned `t` seconds in, and how far the plane is taken into the fingers (0 to 1).
	local function folded(t)
		local turned = {}
		for i = 1, 3 do turned[i] = math.pi * ease((t - RUNS[i + 1][1]) / (RUNS[i + 1][2] - RUNS[i + 1][1])) end
		local taken = ease((t - raise) / (raised / 2))
		turned[4], turned[5], turned[6] = taken * math.pi / 2, taken * math.rad(WINGS_UP), taken * math.rad(WINGS_UP)
		return turned, taken
	end
	-- The paper's frame on the right hand at `grip`: on its thumb side, the nose along the fingers; taken into the
	-- fingers, the keel goes half into the hand.
	local function paperAt(grip, taken)
		local up = grip.LookVector
		local from = grip.Position + up * (hand.Size.Z / 2 + thin / 2 + taken * (keel - thin) / 2)
		return CFrame.lookAt(from, from - grip.UpVector, up)
	end
	-- Where the left hand's middle is `t` seconds in, in the paper's frame. `grabs`: the point of each flap's edge it
	-- folds by, picked so one run ends near where the next starts. The first run crosses the flat sheet from its far
	-- side to the near edge, where the first fold starts.
	local grabs = { pt(-0.8 * half, 0.3 * long), pt(0.8 * half, 0.2 * half, thin), pt(0.85 * half, 0.45 * long, thin) }
	local clear = (left.Size.X + left.Size.Y + left.Size.Z) / 6 -- about half the hand's thickness, whichever way it is turned
	local function pinch(i, angle) return swung(i, angle) * grabs[i] + Vector3.yAxis * clear * (PRESS + ARC * math.sin(angle)) end
	local far = pt(0.7 * half, 0.3 * long) + Vector3.yAxis * clear * PRESS
	local function leftAt(t)
		if t < RUNS[1][2] then return far:Lerp(pinch(1, 0), ease((t - RUNS[1][1]) / (RUNS[1][2] - RUNS[1][1]))) end
		for i = 1, 3 do
			local run = RUNS[i + 1]
			if t < run[1] then return i == 1 and pinch(1, 0) or pinch(i - 1, math.pi):Lerp(pinch(i, 0), ease((t - run[1] + HOP) / HOP)) end
			if t < run[2] then return pinch(i, math.pi * ease((t - run[1]) / (run[2] - run[1]))) end
		end
		return pinch(3, math.pi)
	end
	local joints, at = rig(model)
	local started = false
	local creased = 0 -- how many of the three folds have sounded
	local bent
	bent = RunService.PreSimulation:Connect(function()
		if not model:IsDescendantOf(game) then bent:Disconnect(); return end
		local t = track.TimePosition
		local _, taken = folded(t)
		local sheet = paperAt(at(hand), taken)
		-- the elbow stays on the side the clip has it
		bendArm(joints, at, upper, lower, left, sheet * leftAt(t), (at(upper) * joints[lower].c0).Position, 1 - ease((t - raise) / LET_GO))
	end)
	local beat
	beat = RunService.RenderStepped:Connect(function()
		if not model:IsDescendantOf(game) then beat:Disconnect(); return end
		sit(model, seat)
		local t = track.TimePosition
		if started and not track.IsPlaying then track:Play(0, 1, 1); t = raise + raised; track.TimePosition = t end -- a long hitch ran it out
		if started and creased < 3 and t >= RUNS[creased + 2][1] then -- a fold begins
			creased += 1
			runnerSound("fold")
		end
		if t >= raise + raised + round then t -= round; track.TimePosition = t end -- round the rocking again
		local turned, taken = folded(t)
		local sheet = paperAt(hand.CFrame, taken)
		for _, piece in pieces do
			local lies = piece.at
			for _, i in piece.folds do lies = swung(i, turned[i]) * lies end
			piece.part.CFrame = sheet * lies
			piece.part.Transparency = piece.tucked and t >= RUNS[3][2] and 1 or 0
		end
	end)
	-- What nextOne returns stands in for an AnimationTrack (Play only): their own light starts the folding.
	return { IsPlaying = false, Play = function() started = true; track:AdjustSpeed(1) end }
end

-- Bubblegum, a 1st-place emote (Alan 2026-11-22: sassy from start to finish; docs/workshop/emote-making.md): the
-- kid stands on their stack, weight on one leg, and blows a small bubble that snaps, then a big one that grows until
-- it reaches the lens, pops on it and leaves one sheet of gum over the whole picture; the sheet is torn off, and what it
-- uncovers is the way back to your desk. The body is the Bubblegum clip (tools/emote_clips.lua); its marks say when:
-- Small to Snap the first bubble, Blow the second one's start, Pop. The camera does not move in (Alan 2026-11-20:
-- "No zoom in on 1st"; a first card of mine had it creep in to meet a kid-sized bubble): the bubble does the
-- travelling. Plain parts made here, no pictures.
-- The bubbles hang on the mouth, sizes (radius) in a standard kid's heights: the first grows to `fist`; the second
-- to `head` in `headBy` seconds, steadily to `kid` until `swell` seconds before the pop, then swells until its skin
-- is `lens` of the way from the mouth to the camera (more than the whole picture) and hangs still for the last
-- `still` seconds. Nearly solid (`skin`, Alan 2026-11-22: only the kid's shape behind it, never the face: a face
-- seen through it is seen not blowing; he saw 0.1 and said it looked fine); thick gum pink while
-- small, paler the bigger it gets.
-- On the lens, `near` studs from it (Alan 2026-11-22: one layer, ripped off as sticky gum is; the first build's rows
-- of lumps read as a pile of gum): one flat sheet, `side` half pictures to each side and as far below, its top edge
-- `top` over the middle, there `snap` seconds after the pop (the camera jolts), with soft pale streaks for a shine
-- (`shine`: x, y from its middle, length, width). It sticks for `stuck` seconds, creeping down `sag`.
-- Then it is torn off downward (Alan on the second run: pulled down whole with strands on a straight top edge, "it
-- just comes out as a flat sheet"; it must stretch, "very asymmetric, very broken up", as gum scraped off something).
-- Its edge comes down faster and faster (`pull`: half pictures a second, squared), the left first and the right up
-- to `lead` seconds later. The gum stays stuck at `pins` (each: x, height, how far below it the edge is when it lets
-- go, and how much of the way up to it the gum is dragged): the edge is drawn up into a curved tent at each, with a
-- strand from the tent's point to the pin (a hair of a thread and on it a spike, `thread` wide at its foot, thinner
-- the longer), and at a pin inside the picture a dab left on the glass (`dab` across, drawn down to a point: a drop;
-- a plain disc on a plain thread drew a lollipop); between pins the edge sags to where nothing holds it. A pin that lets go springs back into the
-- sheet in `recoil` seconds. The edge is drawn in straight pieces, `cuts` between neighbouring pins. All of it is
-- gone `gone` seconds into the tear. Sized to the camera's angle that frame (it widens on the way home: sized to the
-- shot's, the sheet's sides came into the picture).
-- The scene leaves `after` seconds after the pop. From the swell on the name plates and the "Menu" tag are put away
-- (Book Kicker's rule: nothing sharp on top of what covers the lens).
-- Studio only, from its draft clip, behind the Dev panel's "end: gum" button, until it is uploaded and who gets which
-- emote is decided. Its sounds (Audio: gumSnap at the mark Snap, gumPop at Pop, gumPeel `peel` seconds into the tear,
-- when the edge first shows).
local GUM = { fist = 0.07, head = 0.12, kid = 0.5, lens = 0.45, headBy = 1.6, swell = 1.0, still = 0.3, skin = 0.1,
	near = 0.75, snap = 0.08, stuck = 0.9, after = 1.0, side = 1.15, top = 1.25, sag = 0.05, pull = 2.6, lead = 0.3, gone = 1.25, peel = 0.38,
	recoil = 0.15, thread = 0.06, dab = 0.11, cuts = 6, pins = { { -0.98, 1.15, 0.9, 0.8 }, { -0.6, 0.45, 0.8, 0.9 }, { -0.3, 1.15, 0.3, 0.7 },
		{ 0.05, 0.8, 1.5, 0.85 }, { 0.42, 1.15, 0.6, 0.75 }, { 0.62, 0.1, 0.7, 0.9 }, { 0.97, 1.15, 1.7, 0.8 } },
	shine = { { -0.5, 0.45, 0.9, 0.11 }, { -0.2, 0.18, 0.3, 0.07 } }, pink = Color3.fromRGB(255, 120, 175), pale = Color3.fromRGB(255, 176, 208) }
-- A right-angled triangle on the lens, `deep` studs in front of the camera `view`: its right angle at (x, foot), its
-- point straight above or below it at `peak`, its third corner at (to, foot).
function GUM.wedge(part, view, deep, x, peak, foot, to)
	local side, up = to < x and 1 or -1, peak < foot and -1 or 1
	part.Size = Vector3.new(0.002, math.max((peak - foot) * up, 0.001), math.max((x - to) * side, 0.001))
	part.CFrame = view * CFrame.fromMatrix(Vector3.new((x + to) / 2, (peak + foot) / 2, -deep), Vector3.new(0, 0, -up * side), Vector3.new(0, up, 0), Vector3.new(side, 0, 0))
end
local function gumClip()
	if not (RunService:IsStudio() and Root:GetAttribute("DevFirstEmote") == "Bubblegum") then return nil end
	local id, draft = ourClip("Bubblegum")
	local marks = draft and draft:GetAttributes() or Rounds.bubblegum
	if not id or not marks or not marks.Pop then return nil end
	return id, marks
end
-- What it needs: the bubble with its glint and the first one's five scraps, and for the lens the sheet and its
-- shine, and for the tear the pins (each with its strand, its dab, and `lets`: the second of the tear it lets go)
-- and the pieces of the torn edge (each from one post, a pin or a side of the sheet, `u0` to `u1` of the way to the
-- next: a block up to its lower end and a triangle on it). All unseen until their moment.
local function gumProps(model, cast, marks)
	local head, root = model:FindFirstChild("Head"), model:FindFirstChild("HumanoidRootPart")
	if not head or not root then return nil end
	local function unseen(part) part.Transparency = 1; return part end
	local gum = { marks = marks, head = head, root = root, bits = {}, shine = {}, pins = {}, edge = {}, sheet = unseen(paper(cast, GUM.pink)),
		ball = unseen(paper(cast, GUM.pink, Enum.PartType.Ball)), glint = unseen(paper(cast, Color3.new(1, 1, 1))) }
	for i = 1, 5 do gum.bits[i] = unseen(paper(cast, GUM.pink)) end
	for i = 1, #GUM.shine do
		gum.shine[i] = unseen(paper(cast, GUM.pale))
		local mesh = Instance.new("SpecialMesh") -- rounded ends
		mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, gum.shine[i]
	end
	local posts = { { x = -GUM.side, lift = 0 } }
	for _, pin in GUM.pins do
		local x, anchor, reach, hold = table.unpack(pin)
		local function wedges() return { unseen(paper(cast, GUM.pink, "WedgePart")), unseen(paper(cast, GUM.pink, "WedgePart")) } end
		table.insert(gum.pins, { x = x, anchor = anchor, hold = hold, lift = 0, thread = unseen(paper(cast, GUM.pink)), spike = wedges(),
			blob = anchor < 1 and unseen(paper(cast, GUM.pink, Enum.PartType.Cylinder)) or nil, neck = anchor < 1 and wedges() or nil,
			lets = math.sqrt((GUM.top - GUM.sag - anchor + reach) / GUM.pull) + GUM.lead * (x + GUM.side) / (2 * GUM.side) })
		table.insert(posts, gum.pins[#gum.pins])
	end
	table.insert(posts, { x = GUM.side, lift = 0 })
	for i = 1, #posts - 1 do
		for cut = 1, GUM.cuts do
			table.insert(gum.edge, { from = posts[i], to = posts[i + 1], u0 = (cut - 1) / GUM.cuts, u1 = cut / GUM.cuts,
				block = unseen(paper(cast, GUM.pink)), wedge = unseen(paper(cast, GUM.pink, "WedgePart")) })
		end
	end
	return gum
end
-- The bubbles and the gum `t` seconds after 1st's light. `view`, `fov`: the camera this frame (with the pop's jolt): what
-- is on the lens moves with it. The small winner stands where they look big, so the bubble is made on them as they are.
local function gumBubble(w, t, view, height, fov)
	local gum = w.gum
	local marks, head, stage, ball = gum.marks, gum.head, gum.root.CFrame, gum.ball
	local size = height / w.scale -- a standard kid's height here
	local mouth = head.CFrame * (Vector3.new(0, -0.22, -0.5) * head.Size)
	local toLens = view.Position - mouth
	local popped = t - marks.Pop
	if t >= marks.Snap and not gum.snapped then gum.snapped = true; Audio.play("gumSnap") end
	if popped >= 0 and not gum.burstLoud then gum.burstLoud = true; Audio.play("gumPop") end
	local r, clear = 0, 1
	if t >= marks.Small and t < marks.Snap then
		r, clear = size * GUM.fist * ((t - marks.Small) / (marks.Snap - marks.Small)) ^ 0.7, GUM.skin
	elseif t >= marks.Blow and popped < 0 then
		local steady, swell, still = marks.Blow + GUM.headBy, marks.Pop - GUM.swell, marks.Pop - GUM.still
		if t < steady then r = size * GUM.head * (1 - (1 - (t - marks.Blow) / GUM.headBy) ^ 2)
		elseif t < swell then r = size * (GUM.head + (GUM.kid - GUM.head) * (t - steady) / (swell - steady))
		else r = size * GUM.kid + (GUM.lens * toLens.Magnitude - size * GUM.kid) * ease((t - swell) / (still - swell)) end
		r *= 1 + 0.02 * math.sin(t * 14) * math.clamp((still - t) / 0.3, 0, 1) -- it wobbles as it grows; still at the end
		clear = GUM.skin
	end
	if r > 0 then
		local grown = math.clamp(r / (size * GUM.kid), 0, 1)
		-- out of the mouth, and the bigger it is the straighter at the lens
		local middle = mouth + (head.CFrame.LookVector * 0.4 + stage.LookVector * 0.6).Unit:Lerp(toLens.Unit, grown).Unit * r
		ball.Size, ball.CFrame, ball.Transparency, ball.Color = Vector3.one * 2 * r, CFrame.new(middle), clear, GUM.pink:Lerp(GUM.pale, grown)
		gum.glint.Size, gum.glint.Transparency = Vector3.new(0.4, 0.12, 0.02) * math.min(r, size * GUM.kid), 0.2 + 0.8 * math.clamp((r / size - GUM.kid) / 0.3, 0, 1)
		gum.glint.CFrame = stage.Rotation * CFrame.Angles(0, 0, math.rad(35)) + middle + (toLens.Unit * 0.8 + stage.UpVector * 0.45 + stage.RightVector * 0.35) * r
		gum.burst = t < marks.Snap and { at = stage:PointToObjectSpace(middle), r = r } or nil
	else
		-- the first bubble's snap: it puffs up and is gone, five scraps fly off (Nap's pop)
		local since, burst = t - marks.Snap, gum.burst
		if burst and since >= 0 and since < POP then
			local k = since / POP
			ball.Size, ball.CFrame, ball.Transparency = Vector3.one * 2 * burst.r * (1 + 0.35 * k), stage * CFrame.new(burst.at), GUM.skin + (1 - GUM.skin) * k
		else
			ball.Transparency = 1
		end
		gum.glint.Transparency = 1
		for i, bit in gum.bits do
			if burst and since >= 0 and since < POP_BITS then
				local k, angle = since / POP_BITS, math.rad(i * 72 + 15)
				bit.Size, bit.Transparency = Vector3.new(0.45 * burst.r, 0.012 * size, 0.004 * size), k
				bit.CFrame = stage * CFrame.new(burst.at + Vector3.new(math.cos(angle), math.sin(angle), 0) * burst.r * (1.1 + 1.4 * k)) * CFrame.Angles(0, 0, angle)
			else
				bit.Transparency = 1
			end
		end
	end
	if popped < 0 then return end
	-- on the lens: places in half pictures from its middle
	local screen = workspace.CurrentCamera.ViewportSize
	local tall = GUM.near * math.tan(math.rad(fov / 2))
	local wide = tall * screen.X / math.max(screen.Y, 1)
	local landed = 0.6 + 0.4 * math.min(popped / GUM.snap, 1) ^ 0.5
	local pulled = math.max(popped - GUM.snap - GUM.stuck, 0) -- seconds into the tear
	if pulled >= GUM.peel and not gum.peeled then gum.peeled = true; Audio.play("gumPeel") end
	local whole, torn = pulled == 0, pulled > 0 and pulled < GUM.gone
	local rest = GUM.top - GUM.sag * math.min(popped / (GUM.snap + GUM.stuck), 1)
	local function loose(x) -- the gum's top edge where nothing holds it: the left comes away first
		local late = math.max(pulled - GUM.lead * (x + GUM.side) / (2 * GUM.side), 0)
		return rest - GUM.pull * late * late
	end
	local high, bottom = GUM.top + GUM.side, -GUM.side - 0.1
	gum.sheet.Transparency = whole and 0 or 1
	gum.sheet.Size = Vector3.new(2 * GUM.side * wide, high * tall, 0.004) * landed
	gum.sheet.CFrame = view * CFrame.new(0, (rest - high / 2) * tall, -GUM.near)
	for i, streak in gum.shine do
		local x, y, long, thick = table.unpack(GUM.shine[i])
		streak.Transparency = (whole or torn) and 0.5 or 1
		streak.Size = Vector3.new(long, thick, 0.002) * tall * landed
		streak.CFrame = view * CFrame.new(x * wide * landed, (loose(x) - high / 2 + y * landed) * tall, -GUM.near + 0.006) * CFrame.Angles(0, 0, math.rad(30))
	end
	for _, pin in gum.pins do
		local back = math.clamp((pulled - pin.lets) / GUM.recoil, 0, 1) -- let go: how far it has sprung back
		local floor = loose(pin.x)
		pin.lift = math.max(pin.anchor - floor, 0) * pin.hold * (1 - back)
		local peak = floor + pin.lift
		local tip = pin.anchor + (peak - pin.anchor) * back
		local shown = torn and tip - peak > 0.01
		pin.thread.Transparency = shown and 0 or 1
		pin.spike[1].Transparency, pin.spike[2].Transparency = pin.thread.Transparency, pin.thread.Transparency
		if shown then -- from a little inside the tent's point: fat at the sheet, thin at the pin
			local foot, half = peak - 0.04, GUM.thread / (1 + 3 * (tip - peak)) / 2
			pin.thread.Size = Vector3.new(0.006 * wide, (tip - foot) * tall, 0.002)
			pin.thread.CFrame = view * CFrame.new(pin.x * wide, (tip + foot) / 2 * tall, -GUM.near)
			for n, to in { pin.x - half, pin.x + half } do GUM.wedge(pin.spike[n], view, GUM.near, pin.x * wide, tip * tall, foot * tall, to * wide) end
		end
		if pin.blob then -- it goes with its strand
			local across = GUM.dab * tall * (1 - back)
			pin.blob.Transparency = torn and back < 1 and 0 or 1
			pin.neck[1].Transparency, pin.neck[2].Transparency = pin.blob.Transparency, pin.blob.Transparency
			pin.blob.Size = Vector3.new(0.002, across, across)
			pin.blob.CFrame = view * CFrame.new(pin.x * wide, tip * tall, -GUM.near) * CFrame.Angles(0, math.rad(90), 0)
			for n, to in { -across / 2, across / 2 } do GUM.wedge(pin.neck[n], view, GUM.near, pin.x * wide, tip * tall - 1.3 * across, tip * tall, pin.x * wide + to) end
		end
	end
	for _, cut in gum.edge do
		local function at(u)
			local x = cut.from.x + (cut.to.x - cut.from.x) * u
			return x, loose(x) + cut.from.lift * (1 - u) ^ 3 + cut.to.lift * u ^ 3
		end
		local x0, h0 = at(cut.u0)
		local x1, h1 = at(cut.u1)
		local low, top = math.min(h0, h1), math.max(h0, h1)
		cut.block.Transparency, cut.wedge.Transparency = torn and low > bottom and 0 or 1, torn and top > bottom and 0 or 1
		if torn and low > bottom then -- a hair wider than its piece: no crack between neighbours
			cut.block.Size = Vector3.new((x1 - x0 + 0.004) * wide, (low - bottom) * tall, 0.004)
			cut.block.CFrame = view * CFrame.new((x0 + x1) / 2 * wide, (low + bottom) / 2 * tall, -GUM.near)
		end
		if torn and top > bottom then
			local under, far = h0 > h1 and x0 - 0.002 or x1 + 0.002, h0 > h1 and x1 or x0 -- its point over the higher end
			GUM.wedge(cut.wedge, view, GUM.near, under * wide, top * tall, (low - 0.01) * tall, far * wide)
		end
	end
end

-- Magician, a 1st-place emote (Alan 2026-11-22, docs/decisions/2026-11-22-magician.md): the kid goes into Roblox's
-- Godlike emote and floats up off the books, paper planes come down from above and circle them, and as the kid
-- comes back down the planes leave in a line past the camera (Alan on the first recording: "cooler if they followed
-- in a line and flew past the camera"; that build scattered them outwards, one past the lens). Both body clips are
-- Roblox's own, played by id (nothing bought): Godlike (`clip`, at `speed`: its 7.1 s fill the scene) and, from
-- `bowAt` seconds after 1st's light, Curtsy over it (`bow`, blended in over `bowFade`). It is a curtsy, legs crossed
-- and hands out, not the bow its keys had read like; Alan, having seen it: "Keep the curtsy". Sizes in a standard
-- kid's heights.
-- The scene lifts the kid `lift` more than the emote's own sixth of a height, up over `up` and down over `down`.
-- `planes` white paper planes `long` (Next One's finished shape and its SHEET numbers: a keel and two wings). The
-- first comes at `first`, the others `every` apart: each from `drop` over the ring, down in `fall` seconds, spiralling
-- in from `wide` rings out. The ring: `ring` around the kid's chest (it follows the body), a turn every `turn`
-- seconds, each plane rising and sinking `bob` and banked `bank` degrees into the turn, the whole ring tipped `tilt`
-- degrees towards the camera (the camera is at about chest height: a level ring of level planes is six thin lines).
-- From `out` the ring unwinds: it turns up to `spin` times as fast (reached over `ramp` seconds) and each plane
-- leaves it at the spot where the ring's own way points at the camera (`peel` of a turn: the kid's left, screen
-- right), so they go one behind the other, a sixth of a turn apart. `out` is a moment a plane is at that spot. A plane
-- that has left flies one curve, the same for all, in `passIn` seconds: on along the ring's way for `reach`, then
-- round to straight at the camera for its last `straight`, to `pass` (right of, below and ahead of the lens: from
-- above its top is seen; level with the lens it would be a line), and on past the camera. Never across the lens.
-- Studio only, behind the Dev panel's "end: magic" button, until who gets which emote is decided. No sounds yet.
local MAGIC = { clip = "rbxassetid://10714347256", speed = 0.7, bow = "rbxassetid://10714061912", bowAt = 8.5, bowFade = 0.5,
	lift = 0.34, up = { 0.9, 4.2 }, down = { 8.3, 10 }, planes = 6, long = 0.36, first = 3.3, every = 0.3, fall = 1.4, drop = 2.6,
	wide = 1.5, ring = 1, turn = 2.4, bob = 0.07, bank = 40, tilt = 12, out = 8, spin = 2, ramp = 0.3, peel = 0.5,
	reach = 1.4, straight = 1, pass = Vector3.new(0.25, -0.2, -0.35), passIn = 0.8 }
local function magicClip()
	return RunService:IsStudio() and Root:GetAttribute("DevFirstEmote") == "Magician" and MAGIC.clip or nil
end
-- The ring's own clock `t` seconds after 1st's light: from `out` it runs faster.
function MAGIC.clock(t)
	local u = math.max(t - MAGIC.out, 0)
	return t + (MAGIC.spin - 1) * (u < MAGIC.ramp and u * u / (2 * MAGIC.ramp) or u - MAGIC.ramp / 2)
end
-- Plane `i`'s place on the ring, in the ring's own frame (x to the kid's right, z away from the camera), `t` seconds
-- after 1st's light.
function MAGIC.path(i, t)
	local s = math.clamp((t - MAGIC.first - (i - 1) * MAGIC.every) / MAGIC.fall, 0, 1)
	local angle = 2 * math.pi * (MAGIC.clock(t) / MAGIC.turn + i / MAGIC.planes)
	local r = MAGIC.ring * (MAGIC.wide + (1 - MAGIC.wide) * ease(s))
	return Vector3.new(r * math.cos(angle), MAGIC.drop * (1 - s) ^ 2 + MAGIC.bob * math.sin(3.1 * t + 2 * i), r * math.sin(angle))
end
-- When plane `i` leaves the ring: the first time from `out` on that it is at `peel`.
function MAGIC.leaves(i)
	local due = (MAGIC.peel - MAGIC.out / MAGIC.turn - i / MAGIC.planes + 1e-6) % 1 * MAGIC.turn -- seconds of the ring's clock
	local gain = MAGIC.spin - 1
	if due < MAGIC.ramp * (MAGIC.spin + 1) / 2 then return MAGIC.out + (math.sqrt(1 + 2 * gain * due / MAGIC.ramp) - 1) * MAGIC.ramp / gain end
	return MAGIC.out + (due + gain * MAGIC.ramp / 2) / MAGIC.spin
end
-- The curtsy's track and the planes, unseen: each plane's pieces with where they lie in it (nose to -z), at the small
-- winner's size (`scale` times smaller), and when each leaves the ring.
local function magicProps(model, cast, animator, scale)
	local animation = Instance.new("Animation"); animation.AnimationId = MAGIC.bow
	local bow = animator:LoadAnimation(animation); bow.Looped, bow.Priority = false, Enum.AnimationPriority.Action2
	local magic = { bow = bow, chest = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart"), planes = {}, shown = {}, leaves = {} }
	local long = MAGIC.long * Avatars.standing_height_studs / scale
	local half, thin = long * SHEET_WIDE / 2, long * SHEET_THIN
	local keel = 2 * half * KEEL
	local wing, white = half - keel, Color3.new(1, 1, 1)
	local function pt(x, y, back) return Vector3.new(x, y, back - long / 2) end -- `back` from the nose
	for i = 1, MAGIC.planes do
		local pieces = {}
		local function block(size, at) -- a rectangle
			local part = paper(cast, white)
			part.Size, part.Transparency = size, 1
			table.insert(pieces, { part = part, at = at })
		end
		local function corner(tip, r, a, b) -- a triangle (Next One's): its right angle, then its other two corners
			local part = paper(cast, white, "WedgePart")
			part.Size, part.Transparency = Vector3.new(thin, (a - r).Magnitude, (b - r).Magnitude), 1
			local y, z = (a - r).Unit, (r - b).Unit
			table.insert(pieces, { part = part, at = tip * CFrame.fromMatrix((a + b) / 2, y:Cross(z), y, z) })
		end
		corner(CFrame.identity, pt(0, -keel, keel), pt(0, 0, keel), pt(0, -keel, 0)) -- the keel: its lower edge runs to the nose
		block(Vector3.new(thin, keel, long - keel), CFrame.new(pt(0, -keel / 2, (keel + long) / 2)))
		for _, side in { 1, -1 } do
			local tip = CFrame.Angles(0, 0, side * math.rad(WINGS_UP))
			corner(tip, pt(0, 0, half), pt(0, 0, keel), pt(side * wing, 0, half))
			block(Vector3.new(wing, thin, long - half), tip * CFrame.new(pt(side * wing / 2, 0, (half + long) / 2)))
		end
		magic.planes[i], magic.leaves[i] = pieces, MAGIC.leaves(i)
	end
	return magic
end
-- The kid's extra lift, the curtsy and the planes `t` seconds after 1st's light. `view`: the camera this frame. Worked
-- out in the big winner's studs; each small plane is then put where it looks the same.
local function magicPlanes(w, t, view, height)
	local magic = w.magic
	local lift = MAGIC.lift * height * (ease((t - MAGIC.up[1]) / (MAGIC.up[2] - MAGIC.up[1])) - ease((t - MAGIC.down[1]) / (MAGIC.down[2] - MAGIC.down[1])))
	w.model:PivotTo((w.desk + w.shift) * CFrame.new(0, lift / w.scale, 0))
	if t >= MAGIC.bowAt and not magic.bowed then magic.bowed = true; magic.bow:Play(MAGIC.bowFade) end
	-- the ring around the chest, where the big winner's is
	local ring = w.desk.Rotation * CFrame.Angles(-math.rad(MAGIC.tilt), 0, 0) + (view.Position + (magic.chest.Position - view.Position) * w.scale)
	local to = view * (MAGIC.pass * height)
	local last = view * ((MAGIC.pass - Vector3.zAxis * MAGIC.straight) * height) -- from here straight at the camera
	local function where(i, at) -- plane i, `at` seconds after the light, in the big winner's studs
		local left = magic.leaves[i]
		if at <= left then return ring * (MAGIC.path(i, at) * height) end
		local from = ring * (MAGIC.path(i, left) * height)
		local on = from + ring.LookVector * MAGIC.reach * height
		local e = (at - left) / MAGIC.passIn
		if e >= 1 then return to + (to - last) * 3 * (e - 1) end
		local f = 1 - e
		return from * f ^ 3 + on * (3 * f * f * e) + last * (3 * f * e * e) + to * e ^ 3
	end
	for i, pieces in magic.planes do
		local gone = t - magic.leaves[i] -- seconds since it left the ring
		local shown = t >= MAGIC.first + (i - 1) * MAGIC.every and gone < 1.3 * MAGIC.passIn -- by then it is behind the camera
		if shown then
			local at, ahead = where(i, t), where(i, t + 0.02)
			local level = 1 - math.clamp(gone / 0.3, 0, 1) -- out of the turn: wings level
			local lies = CFrame.lookAt(at, ahead) * CFrame.Angles(0, 0, -math.rad(MAGIC.bank) * level)
			lies = lies.Rotation + (view.Position + (at - view.Position) / w.scale)
			for _, piece in pieces do piece.part.CFrame = lies * piece.at end
		end
		if shown ~= magic.shown[i] then
			magic.shown[i] = shown
			for _, piece in pieces do piece.part.Transparency = shown and 0 or 1 end
		end
	end
end

-- The book podiums (Alan 2026-11-19): each winner stands on a stack of single books (Assets.WinnerBooks: eight
-- free Creator Store books, each its own model lying flat, 10 studs on its longer side, its thickness in "Thick"),
-- in clear steps (Alan 2026-11-19: on four, three and two books 1st's did not look taller than 2nd's): about 0.78,
-- 0.41 and 0.2 of a winner's height. Which books, bottom to top, under 1st, 2nd and 3rd; and a book's longer side in winner heights:
-- wider than a winner's stance, so they stand on it comfortably.
local STACKS = { { 1, 7, 4, 2, 3, 8 }, { 5, 8, 6, 4 }, { 8, 5 } }
local BOOK_WIDE = 0.56
-- Builds `place`'s stack on `spot` in a small winner's `world`, where everything is `shrink` times smaller; returns
-- the stack's height in the big winner's studs, and its books, bottom to top.
local function stackBooks(world, place, spot, shrink)
	local books, rise, stack = Root.Assets:FindFirstChild("WinnerBooks"), 0, {}
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
			table.insert(stack, book)
		end
	end
	return rise, stack
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
	local legs = humanoid.HipHeight / (KICK_HIPS * Avatars.standing_height_studs) -- against a standard kid's (Book Kicker)
	local scale = model:GetScale()
	model:ScaleTo(1)
	-- The copy comes with its student's sitting pose: stood up straight, with Roblox's own standing idle under the emote.
	for _, joint in model:GetDescendants() do
		if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then joint.Transform = CFrame.identity end
	end
	local rise, stack = stackBooks(world, place, spot, scale)
	local onDesk = spot + Vector3.new(0, (rise + feet) / scale, 0)
	local desk = CFrame.lookAt(onDesk, onDesk + facing)
	model:PivotTo(desk)
	local big = math.clamp(model:GetExtentsSize().Y * scale / Avatars.standing_height_studs, 1, CONE_BIG) -- taller than the rest, hair and hats too
	rootPart.Anchored = true
	humanoid.EvaluateStateMachine, humanoid.DisplayDistanceType = false, Enum.HumanoidDisplayDistanceType.None
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then item.CanCollide, item.CanQuery, item.CanTouch = false, false, false end
	end
	model.Parent = world
	local flick, flickInfo
	if place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 then flick, flickInfo = flickClip() end
	local kickId, kickMarks
	if place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 then kickId, kickMarks = kickClip() end
	local kick = kickId and kickProps(stack, world, rise, kickMarks, legs) or nil -- Book Kicker: no plane in the hand
	local gumId, gumMarks
	if place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 then gumId, gumMarks = gumClip() end
	local gum = gumId and gumProps(model, world, gumMarks) or nil -- Bubblegum: no plane either
	local magicId = place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 and magicClip() or nil
	local magic = magicId and magicProps(model, world, animator, scale) or nil -- Magician: nor here
	local pilot = RunService:IsStudio() and Root:GetAttribute("DevFirstEmote") == "ToyPilot" and (ourClip("ToyPilot"))
	local planeEmote = flick or pilot or Root:GetAttribute("DevWinnerEmote") or Rounds.winner_plane_emote
	local prop = place == 1 and not kick and not gum and not magic and planeEmote ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15
		and holdPlane(model, actorId, flick and Avatars.standing_height_studs, flick and scale) or nil
	flick = prop and flick
	local runnerUp = place > 1 and humanoid.RigType == Enum.HumanoidRigType.R15
	local emote
	local ours = runnerUp and RunService:IsStudio() and Root:GetAttribute("DevRunnerUp")
	if ours == "GoodGame" then
		emote = goodGame(animator, model)
	elseif ours == "Nap" then
		emote = nap(animator, model, place, world, onDesk - Vector3.yAxis * feet / scale)
	elseif ours == "NextOne" then
		emote = nextOne(animator, model, world, onDesk - Vector3.yAxis * feet / scale)
	else
		local animation = Instance.new("Animation"); animation.AnimationId = kick and kickId or gum and gumId or magicId or prop and planeEmote or runnerUp and runnerUpClip() or emoteFor(place)
		emote = animator:LoadAnimation(animation); emote.Looped, emote.Priority = not (flick or kick or gum or magic), Enum.AnimationPriority.Action
		-- A plane emote's first pose is held from the dark on (Alan 2026-11-21: starting at the light, the arm snapped up
		-- from the side in a fifth of a second, "extremely rushed"); the light only sets it going.
		if prop and not flick or kick or gum or magic then emote:Play(0, 1, 0) end -- Book Kicker, Bubblegum and Magician too: they start in their stance on the stack
	end
	local standing = Instance.new("Animation"); standing.AnimationId = IDLE[humanoid.RigType] or IDLE[Enum.HumanoidRigType.R15]
	local idle = animator:LoadAnimation(standing); idle.Looped, idle.Priority = true, Enum.AnimationPriority.Idle
	idle:Play(0)
	return { model = model, emote = emote, prop = prop, held = prop and not flick or kick ~= nil or gum ~= nil or magic ~= nil, kick = kick, gum = gum, magic = magic, pilot = prop and not flick and pilot and true, flick = flick and flickInfo or nil, place = place, scale = scale, big = big, spot = spot, desk = desk, lit = false }
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

local wholeScreen = Instance.new("ScreenGui") -- empty: only measures the whole screen, a phone's notch strips included
wholeScreen.Name, wholeScreen.ScreenInsets, wholeScreen.IgnoreGuiInset, wholeScreen.ResetOnSpawn = "WinnersWholeScreen", Enum.ScreenInsets.None, true, false
wholeScreen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function popIn(a) a = math.clamp(a, 0, 1) - 1; return 1 + 2.7 * a ^ 3 + 1.7 * a ^ 2 end -- overshoots a little

-- winners: { { actorId, displayName, contribution }, ... } in place order. onStage("banner" | "group" | "card") as it
-- moves on: the banner while the camera sets off, nothing over the winners' shot, the results card as it glides back.
function Cutscene.play(winners, onStage)
	Cutscene.stop()
	firstSoundAt = nil
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
	-- The whole screen's shape. On a phone ViewportSize is only the notch-free middle (749 x 381 of a picture drawn
	-- 873 x 401 in the simulator), which left the camera too far back; fitted to the whole screen is the distance Alan
	-- picked there ("zoom 1.2", 2026-11-20), and on a PC the two are the same.
	local whole = wholeScreen.AbsoluteSize.Y > 1 and wholeScreen.AbsoluteSize or camera.ViewportSize
	local aspect = whole.X / math.max(whole.Y, 1)
	local state = { start = os.clock(), winners = {}, hidden = {}, cleared = {}, stage = "banner", cameraType = camera.CameraType, fov = camera.FieldOfView, written = nil, home = camera.CFrame }
	active = state
	state.blur = Instance.new("DepthOfFieldEffect") -- Roblox's own camera blur, on this screen only
	state.smear = Instance.new("BlurEffect") -- Book Kicker's book on the lens
	state.smear.Name, state.smear.Size, state.smear.Enabled, state.smear.Parent = "WinnersLens", 0, false, camera
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
						-- The small winner's own model, moved as one: an anchor at the desk spot and `cast` (the avatar,
						-- books and plane: what the black cover covers). Their spotlight is a model of its own, further away.
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
							local glow, k = Instance.new("Model"), LIGHT_BACK / copy.scale
							local base = anchor:Clone()
							base.Parent = glow
							glow.Name, glow.PrimaryPart, glow.Parent = "Winner" .. place .. "Light", base, state.set
							local wide = CONE_WIDE * height * copy.big
							-- from where they stand to the nearer long edge of their desk
							local onDesk = desk.Size.Z / 2 - math.abs((spots[place] - desk.Position):Dot(back))
							copy.world, copy.glow, copy.light = world, glow, makeSpotlight(spots[place], glow, wide * k, CONE_TALL * height * k, math.min(wide, 1.9 * onDesk) * k)
							copy.cover = Instance.new("Highlight")
							copy.cover.Name, copy.cover.FillColor, copy.cover.FillTransparency, copy.cover.OutlineTransparency = "Unlit", Color3.new(), 1, 1
							copy.cover.DepthMode, copy.cover.Parent = Enum.HighlightDepthMode.Occluded, cast
							if copy.prop then copy.prop.plane.Parent = cast end -- in the hand from the dark on, under the same cover
							if copy.flick then
								state.flickAt = LIGHT_AT + 2 * TURN + copy.flick.release -- the release, in seconds after arriving
								firstSoundAt = state.start + BANNER + DIM + GLIDE + state.flickAt -- the throw's sound (flickSounds)
							elseif copy.pilot then
								firstSoundAt = state.start + BANNER + DIM + GLIDE + LIGHT_AT + 2 * TURN + PILOT_SOUNDS[1] -- the first whoosh (pilotSounds)
							elseif copy.kick then
								state.kickAt = LIGHT_AT + 2 * TURN + copy.kick.marks.Kick -- the kick, in seconds after arriving
								firstSoundAt = state.start + BANNER + DIM + GLIDE + LIGHT_AT + 2 * TURN + copy.kick.marks.HopTo -- the landing's thump (kickBooks)
							elseif copy.gum then
								state.gumAt = LIGHT_AT + 2 * TURN + copy.gum.marks.Pop -- the pop, in seconds after arriving
							firstSoundAt = state.start + BANNER + DIM + GLIDE + LIGHT_AT + 2 * TURN + copy.gum.marks.Snap -- the small bubble's snap (gumBubble)
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
	-- Fitted to the screen both ways: the row and its side room across, FRAME_TALL up and down; the tighter one wins.
	local groupDistance = math.max((across + SIDE_ROOM * height) / aspect, FRAME_TALL * height / 2) / tanHalf
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
	local function leaving() return state.flickAt and arrive + state.flickAt + FLICK_AFTER or state.kickAt and arrive + state.kickAt + KICK_AFTER or state.gumAt and arrive + state.gumAt + GUM.after or math.max(arrive + LIGHT_AT + 2 * TURN + 3, Rounds.results_seconds - CARD) end
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
		return state.flickAt and knocked(steady, t - state.flickAt - FLICK_FLIGHT, height) or state.kickAt and jolted(steady, t - state.kickAt - KICK_FLIGHT, height) or state.gumAt and jolted(steady, t - state.gumAt, height) or steady, steady
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
		if t >= BANNER + DIM * 0.8 and t < arrive then standWinners() end
		-- The small winners are put in front of the camera where they look like big ones on their desks. They are there,
		-- as solid black shapes, from just before the camera sets off (Alan 2026-11-20: he saw them pop in during the
		-- glide; and faded in, their black cover did not hold and they showed lit for a moment), and fade out on the
		-- way home (they stand in front of everything in the room, so they must be gone before the camera turns away).
		local seen = t < leave and 1 or 1 - ease((t - leave) / (GLIDE * 0.4))
		for place, w in state.winners do
			local since = t - arrive - LIGHT_AT - (3 - place) * TURN
			if since >= 0 and not w.lit then
				w.lit = true
				if w.held then w.emote:AdjustSpeed(w.magic and MAGIC.speed or 1) else w.emote:Play(0.3) end
			end
			shine(w, math.clamp(since / CLICK, 0, 1), up, seen)
			-- every point of the big winner, moved towards the camera by their scale: for the small winner standing at
			-- the desk spot that is one slide
			w.shift = (shot.Position - w.spot) * (1 - 1 / w.scale)
			w.world:PivotTo(CFrame.new(w.spot + w.shift))
			w.glow:PivotTo(CFrame.new(w.spot + (shot.Position - w.spot) * (1 - LIGHT_BACK / w.scale)))
			if w.seen ~= seen then
				w.seen = seen
				for _, piece in w.fading do piece.LocalTransparencyModifier = 1 - seen end
			end
			if w.flick then
				flickPlane(w, since, shot, steady, height)
				flickSounds(w, since)
			elseif w.prop then
				flyPlane(w)
				if w.pilot then pilotSounds(w, since) end
			elseif w.kick then kickBooks(w, since, shot, steady, height)
			elseif w.gum then gumBubble(w, since, shot, height, fov)
			elseif w.magic then magicPlanes(w, since, shot, height) end
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
			-- Book Kicker: gone once the open book is most of the way to the lens (Alan 2026-11-21: "The nameplates
			-- can't stay on top of the book when the book covers it")
			-- Bubblegum: gone once the bubble swells over the picture
			plate.frame.Visible = shown > 0 and t < leave and not (state.kickAt and t - arrive > state.kickAt + KICK_FLIGHT * 0.6)
				and not (state.gumAt and t - arrive > state.gumAt - GUM.swell)
			if plate.frame.Visible then
				local desk = desks[place]
				local edge = spots[place] + back * ((desk.Position - spots[place]):Dot(back) + desk.Size.Z / 2)
				local at = camera:WorldToViewportPoint(edge)
				plate.scale.Scale = screen.Y / 1080 * popIn(shown / 0.35)
				local half = PLATE_W / 2 * screen.Y / 1080 + 6 -- a whole plate stays on the screen (clear of a phone's notch strips)
				plate.frame.Position = UDim2.fromOffset(math.clamp(at.X, half, screen.X - half), math.min(at.Y + 6, screen.Y - PLATE_H * screen.Y / 1080 - 8))
			end
		end
		-- Focus on the winners (the small ones, near the camera); the room behind them a little soft.
		local strength = t < arrive and ease((t - depart) / GLIDE) or t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		local first = state.winners[1] or state.winners[2] or state.winners[3]
		local depth = math.max(0, (spots[1] - shot.Position):Dot(shot.LookVector)) / (first and first.scale or 28)
		state.blur.FocusDistance, state.blur.InFocusRadius = depth, math.max(8, depth * 0.5)
		state.blur.NearIntensity, state.blur.FarIntensity = 0, BLUR_FAR * strength
		-- Book Kicker: the open book on the lens is out of focus (see KICK_BLUR)
		local flown = state.kickAt and t - arrive - state.kickAt or 0
		local come = 1 - (1 - math.clamp(flown / KICK_FLIGHT, 0, 1)) ^ 2 -- how far along its flight the book is (kickBooks)
		local soft = (1 / (1 - (1 - KICK_NEAR) * come) - 1) / (1 / KICK_NEAR - 1) * (1 - math.clamp((flown - KICK_FLIGHT - KICK_STUCK) / 0.45, 0, 1))
		state.smear.Size, state.smear.Enabled = KICK_BLUR * screen.Y * soft, soft > 0
		-- and the HUD's "Menu" tag is put away with the name plates until the book has slid off (Alan 2026-11-21;
		-- MenuController reads LensCovered): sharp on a blurred book, it stood out
		local covered = state.kickAt ~= nil and flown > KICK_FLIGHT * 0.6 and flown < KICK_FLIGHT + KICK_STUCK + 0.45
			or state.gumAt ~= nil and t - arrive > state.gumAt - GUM.swell and t - arrive < state.gumAt + GUM.snap + GUM.stuck + GUM.gone -- Bubblegum: from the swell until the gum is torn off
		if covered ~= state.covered then state.covered = covered; Root:SetAttribute("LensCovered", covered or nil) end
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
	state.smear:Destroy()
	Root:SetAttribute("LensCovered", nil)
	state.plateGui:Destroy()
	for item, was in state.moved do if item.Parent then item:PivotTo(was) end end
	workspace.CurrentCamera.CameraType, workspace.CurrentCamera.FieldOfView = state.cameraType, state.fov
	Root:SetAttribute("Cutscene", false)
end

return Cutscene
