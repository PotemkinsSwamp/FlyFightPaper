-- A winner emote as a preview video without Play or an upload (docs/workshop/emote-making.md): a plain R15 test kid
-- stands on 1st's desk in the real classroom and is posed frame by frame from the clip's keyframes, with the plane and
-- the camera moved by the emote's recipe; tools/emote_preview.py calls _G.EMOTE.frame(t) and captures each frame.
-- Run in Studio's Edit. It is a preview: the body is worked out from the keyframes (extra bones passed down to the
-- next real part) on a plain blocky body, so how Roblox fits the clip to a real avatar is still only proven in Play.
-- The recipe below is Camera Flick: the clips, release and flight times, the plane's path, the camera's fall.
-- The throw (Alan 2026-11-19: version B's big overarm throw read as a baseball; a paper plane is pushed forward):
-- two poses from version A (dart), in that clip's own seconds: the hand pulled back beside the shoulder (PULL_AT) and
-- the arm stretched out at the camera (PUSH_AT). The body goes from the held-up plane to the first in PULL_TIME
-- seconds and on to the second in PUSH_TIME, fast then slowing; the plane leaves the hand LET_GO of the way through
-- the push; then the clip's own held point carries on. (Played as made, the clip cocks the arm up behind the head
-- on the way: a reviewer still read an overarm throw.) Only its chest, arms and head are used: the legs and hips
-- stay as the admire left them (the clip crouches wide and steps; the winner stands on a stack of books).
local CLIP = "rbxassetid://87115043025421"
local PULL_AT, PUSH_AT, PULL_TIME, PUSH_TIME, LET_GO = 2.0, 2.5, 0.55, 0.16, 0.6
local LEGS = { "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
-- Before the throw (Alan 2026-11-19: it came too soon): the kid looks down and admires the plane, then looks up at
-- the camera (admire version A). Smug means slow and unrushed (Alan 2026-11-20: a quick back-and-forth read as
-- hurried). His order, in the emote's seconds (TURNS): they start looking at the plane's bottom; the forearm slowly
-- rolls it over to its top while the arm comes in closer; it stops there a second; rolls back to the bottom; then
-- the head comes up to the camera and the arm winds back and throws. The admire clip gives the body: its look down
-- (to LOOKED in its own seconds), then almost standing still (to SLOW_TO) for as long as the turning takes, then its
-- look up and raised hand at its own speed (to ADMIRE_END).
local ADMIRE = "rbxassetid://95093448348238"
local LOOKED, SLOW_TO, ADMIRE_END = 0.9, 1.3, 2.3
-- { second, how far over: 0 the bottom towards the face, 1 the top }, eased from one to the next.
local TURNS = { { 0, 0 }, { 1.0, 0 }, { 2.5, 1 }, { 3.5, 1 }, { 4.7, 0 }, { 5.0, 0 } }
local ADMIRED = TURNS[#TURNS][1]
local JOIN = ADMIRED + ADMIRE_END - SLOW_TO -- when the throw starts
local RELEASE, FLIGHT = JOIN + PULL_TIME + PUSH_TIME * LET_GO, 0.42 -- the plane leaves the hand; how long it flies to the lens
-- The plane in the hand (Alan 2026-11-19: it turned by itself in a still hand). While it is admired, until ADMIRED,
-- it is fixed to the hand, along the forearm, and the forearm rolls it over (ROLL degrees from top to bottom) while
-- the elbow bends DRAW degrees more to bring it closer and the head tips TILT with it. Then, by READY, it comes to
-- how a paper plane is held to throw: the hand under it, its nose towards the camera, a little up, askew and banked
-- (HOLD: straight at the lens it is a dot).
local READY = ADMIRED + 0.65
local ROLL, DRAW, TILT = 180, 16, 6
local HOLD = CFrame.Angles(math.rad(12), math.rad(-15), 0) * CFrame.Angles(0, 0, math.rad(-22))
local HEIGHT = 140 -- every avatar stands this tall in the room (config avatar_display.standing_height_studs)
local FOV = 50
-- Facing the camera: the generator's throw swings the hips 60 degrees away in the wind-up and the chest and head go
-- with them. The feet and hips stay as made; the chest keeps this share of its turn and the eyes stay on the lens.
local FACING = { UpperTorso = 0.35, Head = 0 }

local Players = game:GetService("Players")
local Root = game.ReplicatedStorage.FlyFightPaper
if _G.EMOTE and _G.EMOTE.clean then _G.EMOTE.clean() end
local E = {}
_G.EMOTE = E
local camera = workspace.CurrentCamera
local home = { cf = camera.CFrame, fov = camera.FieldOfView }
local desk = workspace.Arena.DeskNorth3
local back = Vector3.zAxis -- from the chalkboard row out into the room: the winner faces this way
local spot = Vector3.new(desk.Position.X, desk.Position.Y + desk.Size.Y / 2, desk.Position.Z) + back * desk.Size.Z * 0.15

-- The test kid: Roblox's plain blocky body in a red shirt and blue trousers.
local look = Instance.new("HumanoidDescription")
local skin, shirt, legs = Color3.fromRGB(234, 184, 146), Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172)
look.HeadColor, look.LeftArmColor, look.RightArmColor, look.TorsoColor, look.LeftLegColor, look.RightLegColor = skin, skin, skin, shirt, legs, legs
local kid = Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
kid.Name = "EmotePreviewKid"
kid:ScaleTo(HEIGHT / kid:GetExtentsSize().Y)
local scale = kid:GetScale()
local joints = {} -- part name -> where it hangs on its parent
for _, j in kid:GetDescendants() do
	if j:IsA("Motor6D") and j.Part1 then
		joints[j.Part1.Name] = { parent = j.Part0.Name, c0 = j.C0, c1 = j.C1 }
	elseif j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
		joints[j.Attachment1.Parent.Name] = { parent = j.Attachment0.Parent.Name, c0 = j.Attachment0.CFrame, c1 = j.Attachment1.CFrame }
	end
end
for _, d in kid:GetDescendants() do
	if d:IsA("Motor6D") or d:IsA("Constraint") or d:IsA("LuaSourceContainer") then d:Destroy()
	elseif d:IsA("BasePart") then d.Anchored = true end
end

-- Each part's CFrame in the root's frame for one keyframe (tools/emote_check.lua's walk), the hips kept over the spot.
local hips0
local function placed(keyframe, fix)
	local done = { HumanoidRootPart = CFrame.identity }
	local function walk(pose, carried)
		for _, child in pose:GetChildren() do
			if not child:IsA("Pose") then continue end
			local joint = joints[child.Name]
			if joint and done[joint.parent] then
				local at = child.CFrame.Position * scale
				if child.Name == "LowerTorso" then
					hips0 = hips0 or at
					at = Vector3.new(hips0.X, at.Y, hips0.Z) -- clean-up: no stepping off the desk
				end
				local cf = done[joint.parent] * joint.c0 * carried * (CFrame.new(at) * child.CFrame.Rotation) * joint.c1:Inverse()
				local keep = fix and FACING[child.Name]
				if keep then -- clean-up: turned back towards the lens about its own joint (the waist, the neck)
					local hinge, facing = (done[joint.parent] * joint.c0).Position, cf.LookVector
					cf = CFrame.new(hinge) * CFrame.Angles(0, (keep - 1) * math.atan2(-facing.X, -facing.Z), 0) * CFrame.new(-hinge) * cf
				end
				done[child.Name] = cf
				walk(child, CFrame.identity)
			else
				walk(child, carried * child.CFrame.Rotation)
			end
		end
	end
	for _, top in keyframe:GetChildren() do if top:IsA("Pose") then walk(top, CFrame.identity) end end
	return done
end
-- A pose as each joint's own turn (what an animation stores), so two clips blend without pulling the body apart.
local order = {} -- the parts, parents first
do
	local seen, added = { HumanoidRootPart = true }, true
	while added do
		added = false
		for name, joint in joints do
			if not seen[name] and seen[joint.parent] then seen[name], added = true, true; table.insert(order, name) end
		end
	end
end
local function turns(at)
	local out = {}
	for _, name in order do
		local joint = joints[name]
		if at[name] and at[joint.parent] then out[name] = (at[joint.parent] * joint.c0):Inverse() * at[name] * joint.c1 end
	end
	return out
end
local function build(turn)
	local at = { HumanoidRootPart = CFrame.identity }
	for _, name in order do
		local joint = joints[name]
		if turn[name] and at[joint.parent] then at[name] = at[joint.parent] * joint.c0 * turn[name] * joint.c1:Inverse() end
	end
	return at
end
-- `stand`: a pose whose legs and hips the clip keeps, taking only the chest's direction, the arms and the head.
local function load(id, fix, stand)
	local keys = game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(id):GetKeyframes()
	table.sort(keys, function(a, b) return a.Time < b.Time end)
	local list = {}
	for i, key in keys do
		local at = placed(key, fix)
		for _, name in stand and LEGS or {} do at[name] = stand[name] end
		list[i] = { t = key.Time, turn = turns(at) }
		if stand then list[i].turn.UpperTorso = list[i].turn.UpperTorso.Rotation end
	end
	return list
end
local function sample(list, t)
	local i = 1
	while i < #list - 1 and list[i + 1].t <= t do i += 1 end
	local a, b = list[i], list[math.min(i + 1, #list)]
	local s = b.t > a.t and math.clamp((t - a.t) / (b.t - a.t), 0, 1) or 0
	local out = {}
	for name, cf in a.turn do out[name] = cf:Lerp(b.turn[name] or cf, s) end
	return out
end
local admire = load(ADMIRE, false) -- keeps its own look at the plane
local throw = load(CLIP, true, build(sample(admire, ADMIRE_END)))
local LENGTH = JOIN + PULL_TIME + PUSH_TIME + throw[#throw].t - PUSH_AT
local function mix(a, b, s)
	local out = {}
	for name, cf in b do out[name] = (a[name] or cf):Lerp(cf, s) end
	return out
end
local function eased(v) v = math.clamp(v, 0, 1); return v * v * (3 - 2 * v) end
-- How far the plane is turned over at `t`: 0 the bottom towards the face, 1 the top (TURNS; the top again as the
-- arm goes up to throw).
local function over(t)
	if t >= ADMIRED then return eased((t - ADMIRED) / (READY - ADMIRED)) end
	for i = #TURNS - 1, 1, -1 do
		local a, b = TURNS[i], TURNS[i + 1]
		if t >= a[1] then return a[2] + (b[2] - a[2]) * eased((t - a[1]) / (b[1] - a[1])) end
	end
	return TURNS[1][2]
end
local function turnsAt(t)
	local clipTime = if t < LOOKED then t elseif t < ADMIRED then LOOKED + (t - LOOKED) / (ADMIRED - LOOKED) * (SLOW_TO - LOOKED) else SLOW_TO + t - ADMIRED
	local a = sample(admire, math.min(clipTime, ADMIRE_END))
	local turned = over(t)
	local near = t < ADMIRED and turned or 0 -- closer, and the head with it, only while it is looked at
	a.RightLowerArm = a.RightLowerArm * CFrame.Angles(math.rad(DRAW) * near, 0, 0) * CFrame.Angles(0, math.rad(ROLL) * (1 - turned), 0)
	a.Head = a.Head * CFrame.Angles(0, 0, math.rad(TILT) * near)
	if t <= JOIN then return a end
	local s = (t - JOIN) / PULL_TIME
	if s < 1 then return mix(a, sample(throw, PULL_AT), s * s * (3 - 2 * s)) end -- pulled back
	s = (t - JOIN - PULL_TIME) / PUSH_TIME
	if s < 1 then return mix(sample(throw, PULL_AT), sample(throw, PUSH_AT), 1 - (1 - s) ^ 2) end -- pushed at the camera
	return sample(throw, PUSH_AT + t - JOIN - PULL_TIME - PUSH_TIME) -- held pointing
end
local function pose(t) return build(turnsAt(t)) end
-- Feet on the desk: the root's height from the lowest foot over the whole clip's first pose.
local low = math.huge
for name, cf in pose(0) do
	local part = kid:FindFirstChild(name)
	if part then low = math.min(low, cf.Position.Y - part.Size.Y / 2) end
end
local rootAt = CFrame.lookAt(spot - Vector3.yAxis * low, spot - Vector3.yAxis * low + back)
kid.Parent = workspace

-- The plane: the starter fighter, as long as 0.3 of the kid's height (WinnersCutscene's held plane).
local function fresh(module)
	local copy = module:Clone()
	copy.Parent = module.Parent
	local ok, result = pcall(require, copy)
	copy:Destroy()
	return assert(ok and result, result)
end
local catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog))
local plane = Instance.new("Model")
plane.Name = "EmotePreviewPlane"
local planeRoot = Instance.new("Part")
planeRoot.Name, planeRoot.Anchored, planeRoot.Transparency, planeRoot.Parent = "Root", true, 1, plane
assert(fresh(Root.Shared.Aircraft).build(plane, catalog:classLoadout("fighter", 99), catalog, true))
plane.PrimaryPart = planeRoot
for _, d in plane:GetDescendants() do
	if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("LuaSourceContainer") then d:Destroy()
	elseif d:IsA("BasePart") then d.Anchored, d.CanCollide = true, false end
end
plane:ScaleTo(plane:GetScale() * 0.3 * HEIGHT / plane:GetExtentsSize().Z)
local length, span = plane:GetExtentsSize().Z, plane:GetExtentsSize().X
plane.Parent = workspace

-- The camera: close on 1st, a little from below.
local eye = spot + back * 225 + Vector3.yAxis * 62
local cam0 = CFrame.lookAt(eye, spot + Vector3.yAxis * 84)
-- Whatever stands between the lens and the kid is hidden for the preview and put back by clean() (the real scene
-- fades blockers too): each top piece under the room that a ray from the lens to the kid meets.
local hidden = {}
-- (a plain walk over the room's parts: spatial queries skip the decorations that have CanQuery off)
local toEye = Vector3.new(eye.X - spot.X, 0, eye.Z - spot.Z)
local reach, along = toEye.Magnitude, toEye.Unit
for _, part in workspace.Arena:GetDescendants() do
	if not part:IsA("BasePart") or part == desk or hidden[part] ~= nil then continue end
	local offset = part.Position - spot
	local forward, sideways = offset:Dot(along), math.abs(offset:Dot(along:Cross(Vector3.yAxis)))
	local size = part.Size.Magnitude / 2
	if forward > 3 and forward < reach + 10 and sideways < 55 and offset.Y > 2 and offset.Y < 170 and size < 150 then
		local top = part
		while top.Parent and top.Parent ~= workspace.Arena and top.Parent.Name ~= "CityToys" do top = top.Parent end
		for _, piece in top:IsA("BasePart") and { top, table.unpack(top:GetDescendants()) } or top:GetDescendants() do
			if piece:IsA("BasePart") and hidden[piece] == nil then hidden[piece] = piece.Transparency; piece.Transparency = 1 end
		end
		E.hid = E.hid or {}
		E.hid[top.Name] = true
	end
end
local pressed = span * 0.4 -- how far in front of the lens the plane ends, flat, so its wings fill the picture
local FLAT = CFrame.Angles(0, 0, math.rad(15)) * CFrame.Angles(math.rad(90), 0, 0) -- top to the lens, nose up, a little askew
local HIT = RELEASE + FLIGHT
local function bounce(v)
	if v < 1 / 2.75 then return 7.5625 * v * v
	elseif v < 2 / 2.75 then v -= 1.5 / 2.75; return 7.5625 * v * v + 0.75
	elseif v < 2.5 / 2.75 then v -= 2.25 / 2.75; return 7.5625 * v * v + 0.9375 end
	v -= 2.625 / 2.75
	return 7.5625 * v * v + 0.984375
end
local function cameraAt(t)
	local u = t - HIT
	if u <= 0 then return cam0 end
	local jolt = 16 * math.exp(-u * 9) * math.sin(math.min(u / 0.05, 1) * math.pi / 2) -- knocked back, settling
	local shake = Vector3.new(math.sin(u * 95), math.cos(u * 80), 0) * 2.2 * math.exp(-u * 10)
	local fall = bounce(math.clamp((u - 0.1) / 0.65, 0, 1)) -- then it tips over forward and lands
	return CFrame.new(cam0.Position - cam0.LookVector * jolt + cam0:VectorToWorldSpace(shake) - Vector3.yAxis * 48 * fall)
		* cam0.Rotation * CFrame.Angles(math.rad(-68) * fall, 0, 0) * CFrame.Angles(0, 0, math.rad(10) * fall)
end

-- How the plane sits against the hand while it is admired: along the forearm, its top tipped back towards the face
-- (worked out from the pose at the start of the look down, then fixed to the hand).
local GRIP
do
	local at = build(sample(admire, LOOKED)) -- as the clip made it: this is the plane's top towards the face
	local nose = (at.RightHand.Position - at.RightLowerArm.Position).Unit
	GRIP = at.RightHand.Rotation:Inverse() * CFrame.lookAt(Vector3.zero, nose, Vector3.new(0, 1, 0.6))
end
local function held(hand, turn) return CFrame.new(hand) * turn * CFrame.new(0, length * 0.06, -length * 0.15) end
local function smooth(v) v = math.clamp(v, 0, 1); return v * v * (3 - 2 * v) end
local function inHand(t)
	local grip = rootAt * pose(t).RightHand
	local level = (CFrame.lookAt(grip.Position, eye) * HOLD).Rotation
	return held(grip.Position, (grip.Rotation * GRIP):Lerp(level, smooth((t - ADMIRED) / (READY - ADMIRED))))
end

function E.frame(t)
	local at = pose(t)
	for name, cf in at do
		local part = kid:FindFirstChild(name)
		if part then part.CFrame = rootAt * cf end
	end
	local view = cameraAt(t)
	if t < RELEASE then -- in the hand
		plane:PivotTo(inHand(t))
	elseif t < HIT then -- flying at the lens, turning flat as it arrives
		local s = 1 - (1 - (t - RELEASE) / FLIGHT) ^ 2 -- fast off the hand, slower as it fills the picture, so the approach is seen
		local from = inHand(RELEASE).Position
		local to = (cam0 * CFrame.new(0, 0, -pressed)).Position
		local p = from:Lerp(to, s)
		local flying = CFrame.lookAt(p, p + (to - from).Unit) * CFrame.Angles(0, 0, math.rad(40) * s)
		local landed = CFrame.new(p) * (cam0.Rotation * FLAT)
		plane:PivotTo(flying:Lerp(landed, math.clamp((s - 0.8) / 0.2, 0, 1)))
	else -- stuck on the lens, then sliding down it
		local slide = math.max(t - HIT - 0.45, 0)
		plane:PivotTo(view * CFrame.new(0, -slide * slide * 520, -pressed) * FLAT)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV
	camera.CFrame = view
	task.wait(0.05)
	return "ok"
end
-- The cleaned-up clip as a plain R15 animation named `name` under `parent`: the extra bones folded into the real
-- parts, the hips locked and the facing fixed, exactly as the preview poses the kid, so a real avatar plays what the
-- preview showed. One-shot. This is what the game registers in Studio (WinnersCutscene) and what gets uploaded.
function E.bake(parent, name)
	local out = Instance.new("KeyframeSequence")
	out.Name, out.Loop, out.Priority = name, false, Enum.AnimationPriority.Action
	-- for the scene: when the plane leaves the hand, and how it sits in the hand until then
	out:SetAttribute("Release", RELEASE)
	out:SetAttribute("Admired", ADMIRED)
	out:SetAttribute("Ready", READY)
	out:SetAttribute("Grip", GRIP)
	out:SetAttribute("Hold", HOLD)
	for n = 0, math.floor(LENGTH * 30 + 0.5) do
		local frame = Instance.new("Keyframe")
		frame.Time = n / 30
		local turn = turnsAt(n / 30)
		local poses = { HumanoidRootPart = Instance.new("Pose") }
		poses.HumanoidRootPart.Name, poses.HumanoidRootPart.Parent = "HumanoidRootPart", frame
		local function add(part)
			if poses[part] then return poses[part] end
			local made = Instance.new("Pose")
			made.Name, made.CFrame, made.Parent = part, turn[part].Rotation + turn[part].Position / scale, add(joints[part].parent)
			poses[part] = made
			return made
		end
		for part in turn do add(part) end
		frame.Parent = out
	end
	out.Parent = parent
	return string.format("baked %s: %.2f s, release at %.2f s", name, LENGTH, RELEASE)
end
function E.clean()
	kid:Destroy()
	plane:Destroy()
	for part, was in hidden do part.Transparency = was end
	camera.CFrame, camera.FieldOfView = home.cf, home.fov
	_G.EMOTE = nil
	task.wait(0.2) -- set last and after a wait: set first, Studio's camera stayed Scriptable
	camera.CameraType = Enum.CameraType.Fixed
end
local names = {}
for name in E.hid or {} do table.insert(names, name) end
return string.format("ready: %.2f s, release at %.2f s, kid scale %.1f, plane %.0f long %.0f wide; hid %s", LENGTH, RELEASE, scale, length, span, table.concat(names, ", "))
