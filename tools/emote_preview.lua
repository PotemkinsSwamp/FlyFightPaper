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
local PULL_AT, PUSH_AT, PULL_TIME, PUSH_TIME, LET_GO = 2.0, 2.5, 0.6, 0.16, 0.6
local LEGS = { "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
-- Before the throw (Alan 2026-11-19: it came too soon): the kid admires the plane, then looks at the camera. Smug
-- means slow and unrushed (Alan 2026-11-20). The right arm and the head are posed to his order, picked from numbered
-- stills (2026-11-20): they start with the elbow tucked into the side, the hand and plane up in front of the chest,
-- looking only slightly down at the plane's BOTTOM; from TURN_FROM to TURN_TO the elbow goes out and then forward
-- while the forearm rolls right over, so they now look at its TOP; that is held; at LOOK_UP the head comes up to the
-- camera; at JOIN the arm winds back and throws. The rest of the body is the admire clip (version A) almost standing
-- still (its own seconds LOOKED to SLOW_TO), then its look up (to ADMIRE_END).
local ADMIRE = "rbxassetid://95093448348238"
local LOOKED, SLOW_TO, ADMIRE_END = 0.9, 1.3, 1.9
local TURN_FROM, TURN_TO, LOOK_UP = 1.2, 2.8, 4.0
local JOIN = LOOK_UP + ADMIRE_END - SLOW_TO -- when the arm winds back
local RELEASE, FLIGHT = JOIN + PULL_TIME + PUSH_TIME * LET_GO, 0.42 -- the plane leaves the hand; how long it flies to the lens
-- The arm, in degrees, at the start and after the turn: the elbow out from the side (OUT_MID more on the way: out
-- first, then forward), the upper arm forward, turned in across the body, the elbow's bend; the forearm's roll
-- (ROLL at the start, none after). The head: HEAD_DOWN and a little towards the hand, tipping TILT with the turn.
local OUT, OUT_MID, FORWARD, INWARD, BEND = { 0, 14 }, 12, { 6, 22 }, { 55, 42 }, { 118, 100 }
local ROLL, HEAD_DOWN, TILT = 180, 14, 5
-- The plane in the hand (Alan 2026-11-20: it must sit snugly in the hand on every body, with nothing tuned per body;
-- the hand's own turn need not look right). It is held the way Roblox holds a tool: fixed, with one grip for every
-- avatar, to the hand's own grip point (RightGripAttachment, which every avatar has where a tool sits in its hand).
-- So the plane only ever moves with the hand, and the animation turns the wrist to show it: its bottom towards the
-- kid's eyes, rolled over to its top (nose to the kid's left and away at both ends), and from JOIN to READY round to
-- how a paper plane is held to throw: its nose towards the camera, a little up, askew and banked (HOLD: straight at
-- the lens it is a dot).
local READY = JOIN + 0.5
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

-- The test kid: Roblox's plain blocky body in a red shirt and blue trousers (the body the clip is baked on), or, to
-- look at another body, the avatar of the user id in _G.EMOTE_BODY.
local look = Instance.new("HumanoidDescription")
local skin, shirt, legs = Color3.fromRGB(234, 184, 146), Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172)
look.HeadColor, look.LeftArmColor, look.RightArmColor, look.TorsoColor, look.LeftLegColor, look.RightLegColor = skin, skin, skin, shirt, legs, legs
if _G.EMOTE_BODY then look = Players:GetHumanoidDescriptionFromUserId(_G.EMOTE_BODY) end
local kid = Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
kid.Name = "EmotePreviewKid"
kid:ScaleTo(HEIGHT / (kid.Head.Position.Y + kid.Head.Size.Y / 2 - math.min(kid.LeftFoot.Position.Y - kid.LeftFoot.Size.Y / 2, kid.RightFoot.Position.Y - kid.RightFoot.Size.Y / 2))) -- head to feet: hats and wings don't count
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
local function bodyAt(t)
	local clipTime = if t < LOOK_UP then LOOKED + t / LOOK_UP * (SLOW_TO - LOOKED) else SLOW_TO + t - LOOK_UP
	local a = sample(admire, math.min(clipTime, ADMIRE_END))
	local u = eased((t - TURN_FROM) / (TURN_TO - TURN_FROM)) -- 0 the bottom towards the eyes, 1 the top
	local function at(pair, share) return math.rad(pair[1] + (pair[2] - pair[1]) * (share or u)) end
	a.RightUpperArm = CFrame.Angles(0, 0, at(OUT) + math.rad(OUT_MID) * math.sin(u * math.pi)) * CFrame.Angles(at(FORWARD, u * u), 0, 0) * CFrame.Angles(0, at(INWARD), 0)
	a.RightLowerArm = CFrame.Angles(at(BEND), 0, 0) * CFrame.Angles(0, math.rad(ROLL) * (1 - u), 0)
	a.RightHand = CFrame.identity
	local look = CFrame.Angles(math.rad(-HEAD_DOWN), math.rad(-8), 0) * CFrame.Angles(0, 0, math.rad(TILT) * u)
	a.Head = look:Lerp(a.Head, eased((t - LOOK_UP) / (JOIN - LOOK_UP)))
	if t <= JOIN then return a end
	local s = (t - JOIN) / PULL_TIME
	if s < 1 then return mix(a, sample(throw, PULL_AT), s * s * (3 - 2 * s)) end -- pulled back
	s = (t - JOIN - PULL_TIME) / PUSH_TIME
	if s < 1 then return mix(sample(throw, PULL_AT), sample(throw, PUSH_AT), 1 - (1 - s) ^ 2) end -- pushed at the camera
	return sample(throw, PUSH_AT + t - JOIN - PULL_TIME - PUSH_TIME) -- held pointing
end
-- Where the plane points at `t`, in the kid's own frame (forward is -Z, right +X): SEEN is its top towards their
-- eyes; before the turn it is rolled right over about its own nose (`spin`: which way round).
local SEEN = CFrame.lookAt(Vector3.zero, Vector3.new(-0.6, 0.15, -0.8).Unit, Vector3.new(0, 0.75, 0.65))
local THROWN = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0.12, -1)) * HOLD
local function planeAt(t, spin)
	local u = eased((t - TURN_FROM) / (TURN_TO - TURN_FROM))
	return (SEEN * CFrame.Angles(0, 0, spin * math.pi * (1 - u))):Lerp(THROWN, eased((t - JOIN) / (READY - JOIN)))
end
-- The plane against the hand part (after the turn the wrist is straight), and against its grip point: GRIP is the
-- one grip the game uses on every avatar.
local gripPoint = kid.RightHand:FindFirstChild("RightGripAttachment")
local IN_HAND = build(bodyAt(TURN_TO)).RightHand.Rotation:Inverse() * SEEN
local GRIP = (gripPoint and gripPoint.CFrame.Rotation or CFrame.identity):Inverse() * IN_HAND
-- The body at `t` with the wrist turned so the plane, fixed in the hand, points where it should.
local function aimed(turn, planeTurn)
	local at = build(turn)
	turn.RightHand = ((at.RightLowerArm * joints.RightHand.c0):Inverse() * (planeTurn * IN_HAND:Inverse()) * joints.RightHand.c1).Rotation
	return turn
end
local function wrist(t, spin) return math.deg(select(2, aimed(bodyAt(t), planeAt(t, spin)).RightHand:ToAxisAngle())) end
-- The roll goes the way the forearm rolls: the way that asks less of the wrist half-way through.
local SPIN = wrist((TURN_FROM + TURN_TO) / 2, 1) < wrist((TURN_FROM + TURN_TO) / 2, -1) and 1 or -1
local function turnsAt(t) return aimed(bodyAt(t), planeAt(t, SPIN)) end
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
-- The plane for the pose `at`: fixed to the hand's grip point, turned by GRIP, its middle a little ahead of the
-- fingers, and lifted off the grip point until its underside clears the hand (the plane is always on the same side
-- of the hand, so the lift depends only on the hand's own shape): in the hand, never through it. `belly`: from the
-- plane's middle down to its underside, BELLY of the way to its lowest point and at most THIN of its length (what
-- hangs under the wings may touch the fingers; with all of it the plane floated over the hand).
local BELLY, THIN, belly = 0.6, 0.05, nil
do
	local box, size = plane:GetBoundingBox()
	belly = math.min(BELLY * (size.Y / 2 - plane:GetPivot():ToObjectSpace(box).Position.Y), THIN * length)
end
local function held(at)
	local hand = kid.RightHand
	local grip = rootAt * at.RightHand * (gripPoint and gripPoint.CFrame or CFrame.identity)
	local under = CFrame.new(grip.Position) * (grip.Rotation * GRIP) * CFrame.new(0, 0, -length * 0.05)
	local top = 0
	for i = 0, 7 do
		local corner = rootAt * at.RightHand * (hand.Size * Vector3.new(i % 2 - 0.5, (i // 2) % 2 - 0.5, i // 4 - 0.5))
		top = math.max(top, under:PointToObjectSpace(corner).Y)
	end
	return under * CFrame.new(0, top + belly, 0)
end
E.wrist = 0
for n = 0, math.floor(LENGTH * 10) do
	E.wrist = math.max(E.wrist, math.deg(select(2, turnsAt(n / 10).RightHand:ToAxisAngle())))
end

function E.frame(t)
	local at = pose(t)
	for name, cf in at do
		local part = kid:FindFirstChild(name)
		if part then part.CFrame = rootAt * cf end
	end
	local view = cameraAt(t)
	if t < RELEASE then -- in the hand
		plane:PivotTo(held(at))
	elseif t < HIT then -- flying at the lens, turning flat as it arrives
		local s = 1 - (1 - (t - RELEASE) / FLIGHT) ^ 2 -- fast off the hand, slower as it fills the picture, so the approach is seen
		local from = held(pose(RELEASE)).Position
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
-- Trying a pose by hand, for picture choices (Alan picks a numbered still when words can't carry a pose): the pose at
-- `t` with some joints' turns replaced (part name -> its turn from the rest pose) and the wrist turned so the plane
-- points `planeTurn` (in the kid's own frame: forward is -Z, right +X), seen from `out` studs in front, `side` to the kid's
-- left and `up` over the desk.
function E.try(t, replaced, planeTurn, out, side, up)
	local turn = bodyAt(t)
	for name, cf in replaced do turn[name] = cf end
	local at = build(aimed(turn, planeTurn or planeAt(t, SPIN)))
	for name, cf in at do
		local part = kid:FindFirstChild(name)
		if part then part.CFrame = rootAt * cf end
	end
	plane:PivotTo(held(at))
	local from = spot + back * out + back:Cross(Vector3.yAxis) * side + Vector3.yAxis * up
	camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, FOV
	camera.CFrame = CFrame.lookAt(from, spot + Vector3.yAxis * 95)
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
	out:SetAttribute("Grip", GRIP)
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
return string.format("ready: %.2f s, release at %.2f s, wrist turns up to %.0f degrees, kid scale %.1f, plane %.0f long %.0f wide; hid %s", LENGTH, RELEASE, E.wrist, scale, length, span, table.concat(names, ", "))
