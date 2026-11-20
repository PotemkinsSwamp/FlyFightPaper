-- The winners' moment (Alan 2026-11-19, docs/decisions/2026-11-19-winners-circle-redo.md): "Pencils down!", the
-- room's lights fade to near-dark, and in the dark the camera glides from wherever you are (your plane or the
-- hangar) to one steady shot of the three winner desks by the chalkboard. Local copies of the top 3 already stand on
-- their desks as dark shapes, each drawn in their own layer over the room. A spotlight clicks on over 3rd, then 2nd,
-- then 1st, each with its name plate (place, name, points), and each starts their emote in their own light. The
-- camera stays on all three (no zoom in, no confetti: Alan 2026-11-19), then the lights come up as it glides back and
-- the results card shows. Each winner stands on a stack of books, 1st's the tallest.
-- It all happens on this screen only: the server's seated avatars are just hidden here.
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
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
local BLUR_RADIUS, BLUR_NEAR, BLUR_FAR = 200, 0.8, 0.2
-- Only what would block a winner in their shot fades out on this screen; the rest of the town and the ceiling
-- decorations stay in view. Never faded: the room shell, the chalkboard, desks, chairs and the desks' hangars and
-- runways. Always faded: planes, other name tags, the desk landing rings and the monorail's pillars and track.
local KEEP_ARENA = { "^Wall", "^Floor", "^Window", "^Chalkboard", "^Desk", "^Chair", "^NeutralDesk" }
local KEEP_TOYS = { ["school-desk"] = true, ["school-chair"] = true, ["desk-hangar"] = true, ["desk-runway-droop"] = true,
	["runway-light"] = true, ["runway-light-tip"] = true }
-- The dark, on this screen only: the room's own lighting goes to these values, every lamp in the room goes out and
-- the haze clears, so the room can only just be made out (Alan 2026-11-19 on 46, 49, 64: "a little darker").
local DARK = { Brightness = 0, Ambient = Color3.fromRGB(24, 26, 34), OutdoorAmbient = Color3.fromRGB(24, 26, 34),
	EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0 }
-- A winner's spotlight. Real lamps can't do it: Roblox's lights reach 60 studs (a winner stands 140 tall) and are
-- drawn badly or not at all from the group shot's distance (seen in Play 2026-11-19: dark from afar, burnt out
-- close up). So the room never lights the winners: each is drawn in their own layer over the dark room (a
-- ViewportFrame whose camera follows the scene's), lit by the layer's own light, and their light coming on is the
-- layer's tint going from UNLIT (a black shape with no detail: Alan 2026-11-19) to full colour over CLICK seconds. In the layer the winner is their
-- normal small size, with the layer's camera brought in to match: animations then move the hips the right distance
-- (on a scaled-up avatar Roblox scales that movement twice, measured 2026-10-17). In the room the spotlight is a see-through shaft just behind the winner
-- and a glowing pool on the desk top: the shaft's top over the desk and its width at the desk in winner heights, and
-- how see-through shaft and pool are.
local UNLIT, LIT, LAMP_COLOR = Color3.new(), Color3.fromRGB(120, 118, 125), Color3.fromRGB(255, 244, 214)
local CLICK = 0.12
local IDLE = { [Enum.HumanoidRigType.R15] = "rbxassetid://507766666", [Enum.HumanoidRigType.R6] = "rbxassetid://180435571" } -- Roblox's standing idles
local SHAFT_TOP, SHAFT_WIDE, SHAFT_CLEAR, POOL_CLEAR = 3, 0.95, 0.82, 0.8
local Cutscene = {}
local active

local function setDark(state, amount)
	if state.air then
		-- Haze turns far dark walls into bright sky, and other code keeps putting it back (the options code sets its
		-- density every few seconds: seen in Play 2026-11-19), so it is cleared again every frame and set aside
		-- altogether while it is fully dark.
		state.air.Density = state.airWas * (1 - amount)
		local home = if amount < 1 then Lighting else nil
		if state.air.Parent ~= home then state.air.Parent = home end
	end
	if state.dark == amount then return end
	state.dark = amount
	for name, was in state.lit do
		local dark = DARK[name]
		Lighting[name] = if typeof(was) == "number" then was + (dark - was) * amount else was:Lerp(dark, amount)
	end
	for lamp, was in state.lamps do lamp.Brightness = was * (1 - amount) end
end

-- A full-screen layer over the room with its own little world, camera and light, dark until its tint comes up.
local function makeLayer(gui, back, right, order)
	local layer = Instance.new("ViewportFrame")
	layer.Name, layer.Size, layer.BackgroundTransparency, layer.ZIndex = "Winner", UDim2.fromScale(1, 1), 1, order
	layer.Ambient, layer.LightColor, layer.ImageColor3 = LIT, LAMP_COLOR, UNLIT
	layer.LightDirection = (-Vector3.yAxis - back * 0.5 + right * 0.2).Unit -- from above, a little from the camera's side
	local world = Instance.new("WorldModel")
	world.Parent = layer
	local lens = Instance.new("Camera")
	lens.Parent = layer
	layer.CurrentCamera = lens
	layer.Parent = gui
	return layer, world, lens
end

local function makeSpotlight(gui, spot, back, right, height, order)
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
	pool.Size = Vector3.new(0.5, SHAFT_WIDE * height, SHAFT_WIDE * height)
	pool.CFrame = CFrame.new(spot + Vector3.yAxis * 0.3) * CFrame.Angles(0, 0, math.rad(90)) -- lying flat on the desk top
	pool.Parent = part
	part.Parent = workspace
	local layer, world, lens = makeLayer(gui, back, right, order)
	return { part = part, shaft = shaft, pool = pool, layer = layer, world = world, lens = lens }
end
-- `glow`: the winner's own light, 0 off to 1 on; `room`: how much of the shaft and pool shows (they go as the
-- room's lights come back).
local function shine(light, glow, room)
	light.shaft.Enabled = glow * room > 0.5
	light.pool.Transparency = 1 - (1 - POOL_CLEAR) * glow * room
	light.layer.ImageColor3 = UNLIT:Lerp(Color3.new(1, 1, 1), glow)
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
local function holdPlane(model, actorId, height)
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
	height = height or model:GetScale() * 5 -- an R15 avatar is about 5 studs tall at scale 1
	plane:ScaleTo(plane:GetScale() * height * PLANE_LENGTH / plane:GetExtentsSize().Z)
	plane.Name = "HeldPlane"
	return { plane = plane, hand = hand, length = height * PLANE_LENGTH, span = plane:GetExtentsSize().X, last = hand.Position, heading = model:GetPivot().LookVector }
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
-- slides down the lens; the scene moves on from there. Seconds from 1st's light: the plane leaves the hand at
-- FLICK_RELEASE and flies FLICK_FLIGHT to the lens; the camera's fall takes FLICK_FALL; the scene leaves at FLICK_END.
-- Not uploaded yet (Alan's go), so it only plays in Studio: the cleaned-up clip (Assets.CameraFlickClip, made by
-- tools/emote_preview.lua) is registered for the session, when the Dev panel's "end: flick" button asked for it.
local FLICK_RELEASE, FLICK_FLIGHT, FLICK_FALL, FLICK_END = 0.87, 0.42, 0.65, 2.6
local FLICK_FLAT = CFrame.Angles(0, 0, math.rad(15)) * CFrame.Angles(math.rad(90), 0, 0) -- on the lens: top to it, nose up, a little askew
local function flickClip()
	local clip = RunService:IsStudio() and Root:GetAttribute("DevCameraFlick") and Root.Assets:FindFirstChild("CameraFlickClip")
	return clip and game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(clip) or nil
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
-- The plane `t` seconds after 1st's light, in its own full-size layer over everything: in the hand with its nose at
-- the camera, then straight to the lens (fast off the hand, slower as it fills the picture) turning flat as it
-- arrives, then stuck on the lens and sliding down it. `view`: the camera this frame; `steady`: without the knock.
local function flickPlane(w, t, view, steady, height)
	local prop = w.prop
	local pressed = prop.span * 0.4 -- how far in front of the lens it ends, so its wings fill the picture
	if t < FLICK_RELEASE then
		local hand = w.spot + (prop.hand.Position - w.spot) * w.scale -- the winner's layer is `scale` times smaller
		prop.from = hand
		local nose = (CFrame.lookAt(hand, steady.Position) * CFrame.Angles(math.rad(30), math.rad(-35), 0)).LookVector -- up and askew, so its shape shows
		prop.plane:PivotTo(CFrame.lookAt(hand + nose * prop.length * 0.2, hand + nose * (prop.length * 0.2 + 1)))
	elseif t < FLICK_RELEASE + FLICK_FLIGHT then
		local s = 1 - (1 - (t - FLICK_RELEASE) / FLICK_FLIGHT) ^ 2
		local to = (steady * CFrame.new(0, 0, -pressed)).Position
		local at = prop.from:Lerp(to, s)
		local flying = CFrame.lookAt(at, at + (to - prop.from).Unit) * CFrame.Angles(0, 0, math.rad(40) * s)
		prop.plane:PivotTo(flying:Lerp(CFrame.new(at) * (steady.Rotation * FLICK_FLAT), math.clamp((s - 0.8) / 0.2, 0, 1)))
	else
		local slide = math.max(t - FLICK_RELEASE - FLICK_FLIGHT - 0.45, 0)
		prop.plane:PivotTo(view * CFrame.new(0, -slide * slide * 3.7 * height, -pressed) * FLICK_FLAT)
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
-- Builds `place`'s stack on `spot` in a winner's layer, where everything is `shrink` times smaller (the layer's
-- camera makes up for it); returns the stack's height in the room's studs.
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

-- A local copy of a winner's avatar in its own layer's `world`, back at its normal small size, standing on its
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
	model.Parent = world
	local flick = place == 1 and humanoid.RigType == Enum.HumanoidRigType.R15 and flickClip() or nil
	local planeEmote = flick or Root:GetAttribute("DevWinnerEmote") or Rounds.winner_plane_emote
	local prop = place == 1 and planeEmote ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15
		and holdPlane(model, actorId, flick and Avatars.standing_height_studs) or nil
	flick = prop and flick
	local animation = Instance.new("Animation"); animation.AnimationId = prop and planeEmote or emoteFor(place)
	local emote = animator:LoadAnimation(animation); emote.Looped, emote.Priority = not flick, Enum.AnimationPriority.Action
	local standing = Instance.new("Animation"); standing.AnimationId = IDLE[humanoid.RigType] or IDLE[Enum.HumanoidRigType.R15]
	local idle = animator:LoadAnimation(standing); idle.Looped, idle.Priority = true, Enum.AnimationPriority.Idle
	idle:Play(0)
	return { model = model, emote = emote, prop = prop, flick = flick ~= nil, place = place, scale = scale, spot = spot, desk = desk, lit = false }
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
	local state = { start = os.clock(), winners = {}, hidden = {}, lit = {}, lamps = {}, cleared = {}, stage = "banner", cameraType = camera.CameraType, fov = camera.FieldOfView, written = nil, home = camera.CFrame }
	active = state
	state.blur = Instance.new("DepthOfFieldEffect") -- Roblox's own camera blur, on this screen only
	state.blur.Name, state.blur.NearIntensity, state.blur.FarIntensity, state.blur.Parent = "WinnersFocus", 0, 0, camera
	for name in DARK do state.lit[name] = Lighting[name] end
	for _, item in workspace:GetDescendants() do if item:IsA("Light") then state.lamps[item] = item.Brightness end end
	state.air = Lighting:FindFirstChildOfClass("Atmosphere")
	state.airWas = state.air and state.air.Density
	state.stageGui = Instance.new("ScreenGui") -- the winners' layers, under their name plates
	state.stageGui.Name, state.stageGui.IgnoreGuiInset, state.stageGui.ResetOnSpawn, state.stageGui.DisplayOrder = "WinnerStage", true, false, 8
	state.stageGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
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
						local light = makeSpotlight(state.stageGui, spots[place], back, right, height, 4 - place)
						local copy = copyWinner(source, place, back, entry.actorId, spots[place], light.world)
						if copy then copy.light = light; state.winners[place] = copy else light.part:Destroy(); light.layer:Destroy() end
						if copy and copy.flick then -- the plane's own layer, over the winners and their plates
							local layer, world, lens = makeLayer(state.plateGui, back, right, 10)
							copy.prop.plane.Parent, copy.propLayer, copy.propLens = world, layer, lens
							state.flickEnd = LIGHT_AT + 2 * TURN + FLICK_END
						end
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
	local function leaving() return state.flickEnd and arrive + state.flickEnd or math.max(arrive + LIGHT_AT + 2 * TURN + 3, Rounds.results_seconds - CARD) end
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
		return state.flickEnd and knocked(steady, t - state.flickEnd + FLICK_END - FLICK_RELEASE - FLICK_FLIGHT, height) or steady, steady
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
		-- The lights: out over DIM, back up as the camera leaves; each spotlight on at its turn, off with the dark.
		local up = t < leave and 1 or 1 - ease((t - leave) / GLIDE)
		setDark(state, t < depart and ease((t - BANNER) / DIM) or up)
		if t >= depart and t < arrive then standWinners() end
		-- The winners' layers follow the camera; they fade in at the end of the glide over and out on the way home
		-- (a layer shows through everything in the room, so it must be gone before the camera turns away).
		local seen = t < arrive and ease((t - depart - GLIDE * 0.6) / (GLIDE * 0.4)) or 1 - ease((t - leave) / (GLIDE * 0.4))
		for place, w in state.winners do
			local since = t - arrive - LIGHT_AT - (3 - place) * TURN
			if since >= 0 and not w.lit then w.lit = true; w.emote:Play(0.3) end
			shine(w.light, math.clamp(since / CLICK, 0, 1), up)
			-- the layer's camera: the scene's, brought in towards the small winner by their scale
			w.light.lens.CFrame = shot.Rotation + (w.spot + (shot.Position - w.spot) / w.scale)
			w.light.lens.FieldOfView, w.light.layer.ImageTransparency = fov, 1 - seen
			if w.flick then
				w.propLens.CFrame, w.propLens.FieldOfView = shot, fov
				w.propLayer.ImageColor3, w.propLayer.ImageTransparency = w.light.layer.ImageColor3, 1 - seen
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
		-- Focus on the winners, soft in front and a little behind. Roblox's focus stops at 500 studs, so a farther
		-- shot widens the sharp band instead.
		local strength = t < arrive and ease((t - depart) / GLIDE) or t < leave and 1 or 1 - ease((t - leave) / GLIDE)
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
	for _, w in state.winners do w.light.part:Destroy() end
	if state.stageGui then state.stageGui:Destroy() end
	setDark(state, 0)
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
