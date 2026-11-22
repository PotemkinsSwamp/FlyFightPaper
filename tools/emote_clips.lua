-- Body-move clips and the runner-up emotes cut from them, side by side, as stills or a video, without Play
-- (docs/workshop/emote-making.md): one plain R15 test kid per entry stands in a row on 1st's desk in the real
-- classroom and is posed from keyframes (the same walk as tools/emote_check.lua and tools/emote_preview.lua: extra
-- bones passed down to the next real part, hips kept over the spot). Run in Studio's Edit:
--   _G.EMOTE_CLIPS = { "NapB", "cut:NapSleep", ... }  -- clips in ServerStorage.RBX_ASSISTANT_ANIMGEN, asset
--                                                -- ids, or "cut:<name>" for one of the CUTS below
--   _G.EMOTE_VIEW = { out = 330, side = 0, up = 80, at = 60 }  -- optional: the camera, in studs from the desk's middle
-- then this file; tools/emote_preview.py --lua=emote_clips.lua renders it (it calls _G.EMOTE.frame(t)).
-- _G.EMOTE.bake("NapSleep", parent, "NapSleepClip") writes a cut as a plain looping R15 animation: what the game
-- registers in Studio (WinnersCutscene) and what gets uploaded.
local CLIPS = assert(_G.EMOTE_CLIPS, "set _G.EMOTE_CLIPS first")
local VIEW = _G.EMOTE_VIEW or {}
local HEIGHT, FOV, GAP = 140, 50, 150 -- a kid's height in the room; the lens; studs between kids

local function eased(v) v = math.clamp(v, 0, 1); return v * v * (3 - 2 * v) end
local function mix(a, b, s)
	local out = {}
	for name, cf in b do out[name] = (a[name] or cf):Lerp(cf, s) end
	return out
end
-- The runner-up emotes (Alan's OK 2026-11-20): each a loop of `length` seconds; `pose(t, c)` gives the turn of
-- every joint the cut moves at `t` (a joint it leaves out is left to what plays underneath), where c.<key>(seconds)
-- is the named generated clip's pose at its own seconds. Ids: the generator's uploads.
-- (Good Game's arms are not a cut: a first one, posed by numbers, Alan found stiff and too fast; the scene plays
-- Roblox's own clap and wave, in WinnersCutscene.)
local CUTS = {}
-- A cut may hold only some parts (here: what a stance needs): played one priority above another clip, it takes
-- just those parts and the other clip keeps the rest.
local STANCE = { "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local function only(parts, all)
	local out = {}
	for _, part in parts do out[part] = all[part] end
	return out
end
-- Good Game's stance (Alan's go 2026-11-20; a first one, a bent knee on its toes, he called "the rested leg"): the
-- hips and legs from the first half second of a generated "leaning stance" clip: the right foot under the body, the
-- left out to the side, both flat, the hips tilted 5 degrees. (After 0.6 s that clip shuffles its feet: not used.)
CUTS.GoodGameStance = { length = 0.5, clips = { stance = "rbxassetid://106864956338262" }, pose = function(t, c)
	return only(STANCE, c.stance(t))
end }
-- Good Game's wave (Alan 2026-11-20: a first cut had the hand in front of the body; he wants "a low V L shape ...
-- elbow pointing downwards", the hand to the side, chin height is fine, "5 waves", "0.8 seconds between each",
-- "lazy ... their hand flows a little bit"). The whole body from generated clip B, in its own seconds (W): arms
-- hanging (hang to rise) and the arm coming up (to up), a short join over a second it holds with the elbow out high, the
-- elbow settling down at the side (settle to wave), then its one small sway (wave to waved, 0.6 s: 0.8 s at the
-- scene's 0.75 speed) five times, a join, and its own arm drop (drop to done). Two things are changed by numbers:
-- the upper arm is turned out WAVE_TWIST degrees about its own length while it is up (the clip's forearm leans
-- forward and in: the hand sat half a stud in front; turned, it stands over the elbow beside the head), and the
-- sway of the arm's three joints away from where the sway starts is made WAVE_BIG times bigger (the clip's is 0.16
-- studs at the hand: too small to see from the winners' camera).
local W = { hang = 0.9, rise = 1.5, up = 2.0, settle = 2.85, wave = 3.3, waved = 3.9, drop = 4.9, done = 5.6 }
local WAVES, WAVE_TWIST, WAVE_BIG, JOIN_UP, JOIN_DROP, JOIN_LOOP, JOIN_END = 5, -30, 2.5, 0.2, 0.25, 0.1, 0.3
local ARM = { "RightUpperArm", "RightLowerArm", "RightHand" }
local WAVE_RAISE, WAVE_SETTLE, WAVE_SWAY = W.up - W.hang, W.wave - W.settle, W.waved - W.wave
CUTS.GoodGameWave = { length = WAVE_RAISE + JOIN_UP + WAVE_SETTLE + WAVES * WAVE_SWAY + JOIN_DROP + W.done - W.drop,
	clips = { wave = "rbxassetid://98868591718671" }, pose = function(t, c)
	local settled = WAVE_RAISE + JOIN_UP + WAVE_SETTLE
	local waved = settled + WAVES * WAVE_SWAY
	local p, turned
	if t < WAVE_RAISE then
		p = c.wave(W.hang + t)
	elseif t < WAVE_RAISE + JOIN_UP then
		p = mix(c.wave(W.up), c.wave(W.settle), eased((t - WAVE_RAISE) / JOIN_UP))
	elseif t < settled then
		p = c.wave(W.settle + t - WAVE_RAISE - JOIN_UP)
	elseif t < waved then
		local into = (t - settled) % WAVE_SWAY
		local from = c.wave(W.wave)
		p = c.wave(W.wave + into)
		for _, part in ARM do -- the sway, bigger
			local axis, angle = from[part]:ToObjectSpace(p[part]):ToAxisAngle()
			p[part] = from[part] * CFrame.fromAxisAngle(axis, angle * WAVE_BIG)
		end
		if into > WAVE_SWAY - JOIN_LOOP then p = mix(p, from, eased((into - WAVE_SWAY + JOIN_LOOP) / JOIN_LOOP)) end
	elseif t < waved + JOIN_DROP then
		p = mix(c.wave(W.wave), c.wave(W.drop), eased((t - waved) / JOIN_DROP))
	else
		p = c.wave(W.drop + t - waved - JOIN_DROP)
	end
	-- turned out: in from the moment the arm starts up until it has settled, out again over the drop
	local rise = W.rise - W.hang
	turned = t < settled and eased((t - rise) / (settled - rise)) or 1 - eased((t - waved) / (JOIN_DROP + 0.3))
	p.RightUpperArm = p.RightUpperArm * CFrame.Angles(0, math.rad(WAVE_TWIST) * turned, 0)
	-- the clip ends with its head tilted the other way: back to the first pose, so the loop closes without a jerk
	local last = waved + JOIN_DROP + W.done - W.drop - JOIN_END
	if t > last then p = mix(p, c.wave(W.hang), eased((t - last) / JOIN_END)) end
	return p
end }

local Players = game:GetService("Players")
if _G.EMOTE and _G.EMOTE.clean then _G.EMOTE.clean() end
local E = {}
_G.EMOTE = E
local camera = workspace.CurrentCamera
local home = { cf = camera.CFrame, fov = camera.FieldOfView }
local desk = workspace.Arena.DeskNorth3
local back, right = Vector3.zAxis, Vector3.xAxis -- the kids face out into the room; screen right seen from there
local middle = Vector3.new(desk.Position.X, desk.Position.Y + desk.Size.Y / 2, desk.Position.Z)

local look = Instance.new("HumanoidDescription")
local skin, shirt, legs = Color3.fromRGB(234, 184, 146), Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172)
look.HeadColor, look.LeftArmColor, look.RightArmColor, look.TorsoColor, look.LeftLegColor, look.RightLegColor = skin, skin, skin, shirt, legs, legs
local first = Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
first:ScaleTo(HEIGHT / (first.Head.Position.Y + first.Head.Size.Y / 2 - (first.LeftFoot.Position.Y - first.LeftFoot.Size.Y / 2)))
local scale = first:GetScale()
local joints = {} -- part name -> where it hangs on its parent
for _, j in first:GetDescendants() do
	if j:IsA("Motor6D") and j.Part1 then
		joints[j.Part1.Name] = { parent = j.Part0.Name, c0 = j.C0, c1 = j.C1 }
	elseif j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
		joints[j.Attachment1.Parent.Name] = { parent = j.Attachment0.Parent.Name, c0 = j.Attachment0.CFrame, c1 = j.Attachment1.CFrame }
	end
end
for _, d in first:GetDescendants() do
	if d:IsA("Motor6D") or d:IsA("Constraint") or d:IsA("LuaSourceContainer") then d:Destroy()
	elseif d:IsA("BasePart") then d.Anchored = true end
end
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
-- A pose as every joint's own turn (what an animation stores), and back to each part's place in the root's frame.
local function build(turn)
	local at = { HumanoidRootPart = CFrame.identity }
	for _, name in order do
		local joint = joints[name]
		if at[joint.parent] then at[name] = at[joint.parent] * joint.c0 * (turn[name] or CFrame.identity) * joint.c1:Inverse() end
	end
	return at
end
-- One keyframe as joint turns; `hips0`: where this clip's hips started (they stay over it: no stepping off the desk).
local function turnsOf(keyframe, hips0)
	local done, turn = { HumanoidRootPart = CFrame.identity }, {}
	local function walk(pose, carried)
		for _, child in pose:GetChildren() do
			if not child:IsA("Pose") then continue end
			local joint = joints[child.Name]
			if joint and done[joint.parent] then
				local at = child.CFrame.Position * scale
				if child.Name == "LowerTorso" then
					hips0.at = hips0.at or at
					at = Vector3.new(hips0.at.X, at.Y, hips0.at.Z)
				end
				done[child.Name] = done[joint.parent] * joint.c0 * carried * (CFrame.new(at) * child.CFrame.Rotation) * joint.c1:Inverse()
				turn[child.Name] = (done[joint.parent] * joint.c0):Inverse() * done[child.Name] * joint.c1
				walk(child, CFrame.identity)
			else
				walk(child, carried * child.CFrame.Rotation)
			end
		end
	end
	for _, top in keyframe:GetChildren() do if top:IsA("Pose") then walk(top, CFrame.identity) end end
	return turn
end

-- Nap (Alan's own version, 2026-11-20: "sitting crisscross applesauce, elbow on the knee, holding their head up ...
-- they jolt up, and then they look around like side to side. 1, 2, 3. Then they look forward, and then they kind of
-- just fall back to sleep"; the napper is bored and done; after his first look in Play: "their head needs to be more
-- down ... fully, like, limp down, resting on the hand ... it makes them look awake, if you can see their faces", the
-- elbow anywhere on that leg, the hand anywhere on the head). Two clips the scene plays one over the other:
-- NapSleep, the loop, and NapWake, once, when 1st's light clicks on; NapWake starts and ends in NapSleep's first pose.
-- The body is generated clip Nap B sitting still (N.rest of its own seconds) and, awake, sitting up straight after
-- its own start (N.up). By numbers, the same on every frame: the head hangs NAP_DOWN degrees down (the face to the
-- lap) and NAP_ROLL over onto the right hand, which holds it by the brow; the chest slumps forward and to the
-- right, as near NAP_LEAN degrees forward as lets the right elbow rest on the right thigh (worked out below for
-- this body); and both arms are bent to reach: the right hand to the brow, the left to where it lay on the left
-- knee. (In the game Roblox's IKControl does the right arm again on each avatar's own body: WinnersCutscene.)
local N = { clip = "rbxassetid://103826141789730", rest = 3.0, up = 3.9 }
local NAP_DOWN, NAP_ROLL, NAP_LEAN = 70, 15, 25
-- Asleep: a breath every BREATH_EVERY seconds (the chest leans BREATH degrees back and forth; Nap B has no
-- breathing of its own), and once a loop, at NOD_AT, a small nod: the chest NOD_LEAN and the head NOD_HEAD degrees
-- lower over NOD_DOWN seconds, caught in NOD_UP.
local BREATH_EVERY, BREATH, NOD_AT, NOD_DOWN, NOD_UP, NOD_LEAN, NOD_HEAD = 4, 2.5, 5, 0.8, 0.25, 5, 14
-- The shortest turn that takes one direction to another.
local function arc(from, to)
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-5 then return CFrame.identity end
	return CFrame.fromAxisAngle(axis.Unit, math.atan2(axis.Magnitude, from:Dot(to)))
end
-- Bends one arm of a pose so the middle of its hand is at `target`, the elbow towards `pole` (root frame). Never
-- quite straight (0.95 of its length at most: a straight arm looks stiff), so a far target is not quite reached.
-- `leg`: the leg of that side instead, its ankle joint to `target`, the knee towards `pole` (it may stand straight).
-- `most`: another share of its length it may stretch to (0.95 leaves the elbow bent 36 degrees: no victory arm).
local function reach(turn, side, target, pole, leg, most)
	local upper, lower, hand = side .. (leg and "UpperLeg" or "UpperArm"), side .. (leg and "LowerLeg" or "LowerArm"), side .. (leg and "Foot" or "Hand")
	local function tip(at) return leg and (at[lower] * joints[hand].c0).Position or at[hand].Position end
	local at = build(turn)
	local shoulder = at[joints[upper].parent] * joints[upper].c0
	local s, elbow0 = shoulder.Position, (at[upper] * joints[lower].c0).Position
	local l1, l2 = (elbow0 - s).Magnitude, (tip(at) - elbow0).Magnitude
	local d = math.clamp((target - s).Magnitude, math.abs(l1 - l2) * 1.01, (l1 + l2) * (most or leg and 0.999 or 0.95))
	local along = (target - s).Unit
	local a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
	local out = pole - s
	out -= along * out:Dot(along)
	local elbow = s + along * a + out.Unit * math.sqrt(math.max(l1 * l1 - a * a, 0))
	turn[upper] = shoulder.Rotation:Inverse() * (arc(elbow0 - s, elbow - s) * (shoulder * turn[upper]).Rotation)
	at = build(turn)
	local bend = at[upper] * joints[lower].c0
	turn[lower] = bend.Rotation:Inverse() * (arc(tip(at) - bend.Position, s + along * d - bend.Position) * (bend * turn[lower]).Rotation)
end
-- Nap B's sitting pose with the chest leaning `lean` degrees forward and `side` to the right and the head held
-- `down` and rolled NAP_ROLL to the right whatever the chest does; and where the hand goes: against the right
-- side of the brow.
local function propped(base, lean, side, down)
	local turn = table.clone(base)
	turn.UpperTorso = base.UpperTorso * CFrame.Angles(-math.rad(lean), 0, -math.rad(side))
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * CFrame.fromOrientation(-math.rad(down), 0, -math.rad(NAP_ROLL)) * joints.Head.c1.Rotation
	local head = first.Head.Size
	return turn, neck * turn.Head * joints.Head.c1:Inverse() * Vector3.new(0.22 * head.X, -0.05 * head.Y, -0.5 * head.Z - 0.3 * first.RightHand.Size.Y)
end
local nap -- this body's numbers, worked out once
local function napping(c)
	if nap then return nap end
	local base = c.nap(N.rest)
	local at = build(base)
	-- the elbow's place: anywhere along the top of the right thigh, the two limbs just pressed into each other
	local up = Vector3.yAxis * 0.8 * (first.RightUpperLeg.Size.X + first.RightUpperArm.Size.X) / 2
	local hip, knee = (at.LowerTorso * joints.RightUpperLeg.c0).Position + up, (at.RightUpperLeg * joints.RightLowerLeg.c0).Position + up
	nap = { base = base, rest = hip:Lerp(knee, 0.6), leftHand = at.LeftHand.Position, leftElbow = (at.LeftUpperArm * joints.LeftLowerArm.c0).Position }
	local least
	for lean = 0, 50 do
		for side = -5, 25 do
			local turn, brow = propped(base, lean, side, NAP_DOWN)
			reach(turn, "Right", brow, nap.rest)
			local elbow = (build(turn).RightUpperArm * joints.RightLowerArm.c0).Position
			local on = hip:Lerp(knee, math.clamp((elbow - hip):Dot(knee - hip) / (knee - hip):Dot(knee - hip), 0, 1))
			local off = (elbow - on).Magnitude ^ 2 + ((lean - NAP_LEAN) ^ 2 + side * side) * 1e-5 * scale * scale
			if not least or off < least then least, nap.lean, nap.side = off, lean, side end
		end
	end
	return nap
end
-- Asleep on the hand, `breath` -1 to 1 and `nod` 0 to 1 into a nod; and where the hand is.
local function asleep(c, breath, nod)
	local n = napping(c)
	local turn, jaw = propped(n.base, n.lean + BREATH * breath + NOD_LEAN * nod, n.side, NAP_DOWN + NOD_HEAD * nod)
	reach(turn, "Right", jaw, n.rest)
	reach(turn, "Left", n.leftHand, n.leftElbow)
	return turn, jaw
end
CUTS.NapSleep = { length = 2 * BREATH_EVERY, clips = { nap = N.clip }, pose = function(t, c)
	local into = t - NOD_AT
	local nod = into < 0 and 0 or into < NOD_DOWN and (into / NOD_DOWN) ^ 2 or 1 - eased((into - NOD_DOWN) / NOD_UP)
	return (asleep(c, math.sin(t / BREATH_EVERY * 2 * math.pi), nod))
end }
-- Waking: the jolt (JOLT seconds, JOLT_PAST past upright and back), sitting stiff, then the look-around. The looks
-- are Roblox's own, from its standing idle (the one under every emote in the scene): the turns of its head and
-- chest away from facing forward, laid over the sitting-up pose. LOOKS: { from, to in this clip's seconds, from, to
-- in the idle's seconds }: to the right (its 0.15-0.55 s), across to the left with its dip of the head (its
-- 1.8-2.45 s, a little faster), back to the right (the same, backwards), forward. Then the sink, SINK seconds:
-- 0.6 of the way down, caught back up to 0.3, then all the way. The right hand stays where the jaw left it the
-- whole time, and the head comes back down onto it.
local JOLT, JOLT_PAST, LOOK_FROM, LOOK_END, SINK, DIP, CATCH = 0.2, 0.08, 0.15, 2.6, 2.5, 0.9, 0.3
local LOOKS = { { 0.45, 0.8, 0.15, 0.55 }, { 0.8, 0.95, 0.55, 0.7 }, { 0.95, 1.45, 1.8, 2.45 }, { 1.45, 1.6, 2.45, 2.6 },
	{ 1.6, 2.1, 2.45, 1.8 }, { 2.1, 2.25, 1.8, 1.65 }, { 2.25, LOOK_END, 0.55, 0.15 } }
CUTS.NapWake = { length = LOOK_END + SINK, clips = { nap = N.clip, idle = "rbxassetid://507766666" }, pose = function(t, c)
	local sleeping, jaw = asleep(c, 0, 0)
	local awake -- 0 asleep, 1 sitting up
	if t < JOLT then awake = (1 + JOLT_PAST) * (1 - (1 - t / JOLT) ^ 2) -- fast off the hand, slowing (all at once it popped: 47 degrees in a frame)
	elseif t < LOOK_END then awake = 1 + JOLT_PAST * (1 - eased((t - JOLT) / JOLT))
	else
		local u = t - LOOK_END
		awake = u < DIP and 1 - 0.6 * eased(u / DIP) or u < DIP + CATCH and 0.4 + 0.3 * eased((u - DIP) / CATCH)
			or 0.7 * (1 - eased((u - DIP - CATCH) / (SINK - DIP - CATCH)))
	end
	local turn = mix(sleeping, c.nap(N.up), awake)
	for _, look in LOOKS do
		if t >= look[1] and t < look[2] then
			local from, now = c.idle(LOOK_FROM), c.idle(look[3] + (look[4] - look[3]) * (t - look[1]) / (look[2] - look[1]))
			for _, part in { "Head", "UpperTorso" } do turn[part] *= from[part]:ToObjectSpace(now[part]).Rotation end
		end
	end
	for _, part in ARM do turn[part] = sleeping[part] end
	reach(turn, "Right", jaw, napping(c).rest)
	return turn
end }

-- Next One (plan approved by Alan in words 2026-11-20: the kid is already over it and planning the rematch; head
-- down on the work, three brisk folds, then the finished plane held up at eye level and slowly turned; no sighting
-- along it). One clip, played once; the scene (WinnersCutscene) holds its first pose in the dark, folds the paper
-- and puts the left hand on it, and from NEXT_RAISE + NEXT_RAISED on goes round the last NEXT_TURN seconds (the
-- clip runs NEXT_TAIL longer, so there is always a next key). The body is generated clip Next One A sitting still
-- (X.rest of its own seconds: its hands never move). By numbers: at work the chest hunches NEXT_LEAN degrees
-- forward, the left hand stays where the clip has it (on the lap: where it goes back to when it lets go) and the
-- right hand is at NEXT_WORK from the root (body heights: in front of the belly, in the left hand's reach), its
-- elbow towards NEXT_WORK_ELBOW from the shoulder, its thumb side up and level (the sheet lies on it) and its
-- fingers towards NEXT_FINGERS (to the kid's left); held up, the chest is back where the clip has it, the right hand is NEXT_HOLD from the
-- head's middle with the elbow out towards NEXT_ELBOW from the shoulder (body heights), the wrist straight (the
-- plane's nose points along the forearm) and the forearm turned so the plane's top faces up and towards the face,
-- then rocked NEXT_ROLL degrees either way about its own length, once every NEXT_TURN seconds (the raise ends at
-- one end of the rock, so nothing jumps). The head goes NEXT_FOLLOW of the way from straight ahead to looking at
-- the right hand, the whole time.
local X = { clip = "rbxassetid://98981684256935", rest = 1.0 }
local NEXT_RAISE, NEXT_RAISED, NEXT_TURN, NEXT_TAIL = 4.3, 0.9, 3, 0.2
local NEXT_LEAN, NEXT_FOLLOW, NEXT_ROLL = 10, 0.5, 35
local NEXT_WORK, NEXT_WORK_ELBOW, NEXT_FINGERS = Vector3.new(0.02, -0.32, -0.19), Vector3.new(0.1, -0.3, -0.1), Vector3.new(-1, 0, -0.2).Unit
local NEXT_HOLD, NEXT_ELBOW = Vector3.new(0.14, -0.02, -0.22), Vector3.new(0.3, -0.12, 0)
local function elbowOf(at, side) return (at[side .. "UpperArm"] * joints[side .. "LowerArm"].c0).Position end
-- Turns one part of a pose about its own joint by `by`, a turn in the root's frame.
local function spin(turn, part, by)
	local hinge = (build(turn)[joints[part].parent] * joints[part].c0).Rotation
	turn[part] = hinge:Inverse() * by * hinge * turn[part]
end
-- The right forearm turned about its own length until the hand's thumb side faces `want` as nearly as it can, and
-- `more` degrees on.
local function thumbTo(turn, want, more)
	local at = build(turn)
	local axis = (at.RightHand.Position - elbowOf(at, "Right")).Unit
	local now = at.RightHand.LookVector
	local a, b = now - axis * now:Dot(axis), want - axis * want:Dot(axis)
	spin(turn, "RightLowerArm", CFrame.fromAxisAngle(axis, math.atan2(a:Cross(b):Dot(axis), a:Dot(b)) + math.rad(more or 0)))
end
local nextOne -- this body's numbers, worked out once
local function folding(c)
	if nextOne then return nextOne end
	local base = c.sit(X.rest)
	local at = build(base)
	local work = table.clone(base)
	work.UpperTorso = base.UpperTorso * CFrame.Angles(-math.rad(NEXT_LEAN), 0, 0)
	reach(work, "Right", NEXT_WORK * HEIGHT, (build(work).UpperTorso * joints.RightUpperArm.c0).Position + NEXT_WORK_ELBOW * HEIGHT)
	reach(work, "Left", at.LeftHand.Position, elbowOf(at, "Left"))
	thumbTo(work, Vector3.yAxis)
	-- the wrist bent until the hand is exactly so: its look (the thumb side) up, its own up away from the fingers
	local wrist = (build(work).RightLowerArm * joints.RightHand.c0).Rotation
	work.RightHand = wrist:Inverse() * CFrame.fromMatrix(Vector3.zero, NEXT_FINGERS:Cross(Vector3.yAxis), -NEXT_FINGERS, -Vector3.yAxis) * joints.RightHand.c1.Rotation
	nextOne = { base = base, work = work }
	return nextOne
end
local function heldUp(c, roll)
	local turn = table.clone(folding(c).base)
	local at = build(turn)
	turn.RightHand = CFrame.new(turn.RightHand.Position)
	local hand = at.Head.Position + NEXT_HOLD * HEIGHT
	reach(turn, "Right", hand, (at.UpperTorso * joints.RightUpperArm.c0).Position + NEXT_ELBOW * HEIGHT)
	thumbTo(turn, Vector3.yAxis + (at.Head.Position - hand).Unit * 0.6, roll)
	return turn
end
CUTS.NextOne = { length = NEXT_RAISE + NEXT_RAISED + NEXT_TURN + NEXT_TAIL, once = true, clips = { sit = X.clip },
	marks = { Raise = NEXT_RAISE, Raised = NEXT_RAISED, Turn = NEXT_TURN }, pose = function(t, c)
	local up = eased(math.clamp((t - NEXT_RAISE) / NEXT_RAISED, 0, 1) ^ 0.7) -- quick off the lap, slower as it arrives
	local rocked = math.max(t - NEXT_RAISE - NEXT_RAISED, 0) / NEXT_TURN
	local turn = up > 0 and mix(folding(c).work, heldUp(c, -NEXT_ROLL * math.cos(rocked * 2 * math.pi)), up) or table.clone(folding(c).work)
	local at = build(turn)
	local neck = at.UpperTorso * joints.Head.c0
	local to = (at.RightHand.Position - at.Head.Position).Unit
	turn.Head = neck.Rotation:Inverse() * CFrame.lookAt(Vector3.zero, (-Vector3.zAxis):Lerp(to, NEXT_FOLLOW)).Rotation * joints.Head.c1.Rotation
	return turn
end }

-- Toy Pilot, the free 1st-place emote: the kid is lost in playing with their plane, then proud. Posed by numbers
-- from a reference video Alan made with Gemini from our prompt and called "perfect" (2026-11-21; a first cut from
-- generated clips he rejected: the hand ended up in the face). One clip, played once, in the video's own seconds:
-- 0 to 2 the plane held up beside the head and looked at; 2 to 7 flown by hand: up, out wide and low to the kid's
-- right with the whole trunk leaning after it, back up, the trunk leaning left under it, back again; from 7.5
-- pushed up and held, left fist on the hip, a small sway.
-- TOY: the video traced every TOY_STEP seconds by tools/emote_trace.py: { right, up, lean, shift, left }: the right
-- hand from the right shoulder in arm lengths (to the kid's right, up), the trunk's lean in degrees (to the kid's
-- right), the hips' shift in body heights (to the kid's right), the left arm's angle out from hanging in degrees.
-- A smooth line runs through the rows. The stance and the planted feet are a generated clip's standing pose
-- (P.fly at P.held: feet apart): both ankles stay exactly there on every frame, the legs bent to reach them.
-- Made for Roblox bodies, not the video's (Alan's two looks in Play and a recording laid beside the video,
-- 2026-11-21: short arms and a big head put the hand and the plane in the face and on top of the head wherever
-- the video's long arm is merely near the head). In the trunk's own frame (`side` out from it, `along` up it):
-- the hand is never further in than TOY_OUT_LOW arm lengths out to the side, and a raised one (from TOY_HIGH arm
-- lengths up, over TOY_HIGH_BY) TOY_OUT_HIGH: a wide V, and really straight (TOY_STRAIGHT of its length; Alan
-- 2026-11-21: bent, "it looks like they're just holding the paper airplane"). The ending is the victory (his "not
-- extending their arm up enough"): from TOY_END, over TOY_END_IN, the V closes to TOY_OUT_END, the video's own
-- high arm, and on the way the arm is pulled in to TOY_PULL of its length and punched out again, so the hand's
-- last move is straight up along the arm and the plane ends nose up. Where the video takes the plane across
-- over the head (a folded arm no blocky avatar has) the trunk leans after it instead: TOY_FOLLOW degrees for
-- every arm length the video's hand is past TOY_CLEAR, TOY_FOLLOW_MOST at most. What is missing of one arm length
-- goes TOY_FORWARD of the way forwards and the rest into the elbow (all forwards pointed the arm at the camera,
-- over the face). The trunk's lean is shared TOY_HIPS to the hips, the rest to the waist; the chest turns
-- TOY_TWIST degrees towards the plane at a full arm's length to the side; the head goes TOY_LOOK of the way from
-- straight ahead to looking at the hand; from TOY_HIP_AT, over TOY_HIP_IN, the left fist goes to the side of the
-- hips, the elbow straight out; held (from TOY_HELD), the trunk sways TOY_SWAY degrees every TOY_SWAY_EVERY seconds.
-- The plane is the scene's own (WinnersCutscene: in the hand, its nose turning the way the hand moves); the scene
-- holds this clip's first pose in the dark, so nothing snaps into place at the light.
local P = { fly = "rbxassetid://93519745518213", held = 5.5 }
local TOY_STEP, TOY_LENGTH, TOY_OUT_LOW, TOY_OUT_HIGH, TOY_HIGH, TOY_HIGH_BY = 0.2, 13, 0.45, 0.64, 0.3, 0.4
local TOY_CLEAR, TOY_FOLLOW, TOY_FOLLOW_MOST, TOY_FORWARD = 0.1, 20, 12, 0.6
local TOY_STRAIGHT, TOY_END, TOY_END_IN, TOY_OUT_END, TOY_PULL = 0.995, 6.8, 0.7, 0.25, 0.75
local TOY_HIPS, TOY_TWIST, TOY_LOOK, TOY_HIP_AT, TOY_HIP_IN, TOY_HELD, TOY_SWAY, TOY_SWAY_EVERY = 0.3, 15, 0.5, 6.8, 0.6, 8, 1.5, 3
local TOY = {
	{ 0.38, 0.13, 0, -0.000, 18 }, { 0.38, 0.13, 0, -0.000, 18 }, { 0.34, 0.09, -0, 0.000, 17 }, { 0.39, 0.13, -0, 0.000, 17 }, { 0.42, 0.14, -1, -0.000, 17 }, { 0.45, 0.14, -1, -0.000, 17 },
	{ 0.50, 0.14, -2, 0.000, 17 }, { 0.57, 0.15, -2, 0.000, 16 }, { 0.61, 0.15, -2, -0.000, 16 }, { 0.64, 0.15, -1, -0.000, 17 }, { 0.66, 0.19, -1, 0.001, 18 }, { 0.68, 0.31, -2, 0.005, 21 },
	{ 0.64, 0.49, -4, 0.011, 27 }, { 0.56, 0.63, -6, 0.016, 34 }, { 0.47, 0.74, -9, 0.021, 43 }, { 0.50, 0.77, -9, 0.023, 53 }, { 0.68, 0.64, -3, 0.022, 62 }, { 0.86, 0.39, 5, 0.019, 71 },
	{ 0.89, 0.18, 12, 0.016, 77 }, { 0.88, -0.04, 19, 0.013, 84 }, { 0.84, -0.16, 23, 0.012, 86 }, { 0.81, -0.14, 22, 0.011, 85 }, { 0.84, 0.03, 17, 0.011, 79 }, { 0.77, 0.26, 10, 0.011, 72 },
	{ 0.56, 0.58, 2, 0.011, 64 }, { 0.33, 0.83, -5, 0.009, 55 }, { 0.09, 0.89, -8, 0.007, 49 }, { -0.17, 0.86, -8, 0.005, 45 }, { -0.38, 0.74, -9, 0.004, 43 }, { -0.58, 0.50, -11, 0.003, 41 },
	{ -0.67, 0.32, -12, 0.003, 40 }, { -0.66, 0.31, -12, 0.004, 38 }, { -0.52, 0.46, -10, 0.004, 36 }, { -0.38, 0.61, -8, 0.004, 35 }, { -0.20, 0.72, -7, 0.004, 33 }, { 0.01, 0.80, -7, 0.004, 31 },
	{ 0.16, 0.89, -7, 0.005, 30 }, { 0.27, 0.94, -7, 0.006, 30 }, { 0.31, 0.96, -7, 0.006, 30 }, { 0.32, 0.93, -7, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 },
	{ 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 },
	{ 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 }, { 0.32, 0.92, -6, 0.006, 30 },
}
-- The traced numbers at `t`: a smooth line through the rows (Catmull-Rom), held at the ends.
local function traced(t)
	local at = math.clamp(t / TOY_STEP, 0, #TOY - 1)
	local i, s = math.floor(at), at % 1
	local function row(k) return TOY[math.clamp(k, 0, #TOY - 1) + 1] end
	local a, b, c, d = row(i - 1), row(i), row(i + 1), row(i + 2)
	local out = {}
	for k = 1, 5 do
		out[k] = b[k] + 0.5 * s * (c[k] - a[k] + s * (2 * a[k] - 5 * b[k] + 4 * c[k] - d[k] + s * (3 * (b[k] - c[k]) + d[k] - a[k])))
	end
	return out
end
local toy -- this body's numbers, worked out once
local function standing(c)
	if toy then return toy end
	local base = c.fly(P.held)
	local at = build(base)
	local elbow = elbowOf(at, "Right")
	toy = { base = base, arm = ((at.UpperTorso * joints.RightUpperArm.c0).Position - elbow).Magnitude + (at.RightHand.Position - elbow).Magnitude, feet = {} }
	for _, side in { "Left", "Right" } do
		toy.feet[side] = { ankle = (at[side .. "LowerLeg"] * joints[side .. "Foot"].c0).Position, foot = at[side .. "Foot"].Rotation,
			knee = (at[side .. "UpperLeg"] * joints[side .. "LowerLeg"].c0).Position - Vector3.zAxis * 0.2 * HEIGHT } -- knees bend forwards
	end
	return toy
end
CUTS.ToyPilot = { length = TOY_LENGTH, once = true, clips = { fly = P.fly }, pose = function(t, c)
	local body = standing(c)
	local right, up, lean, shift, left = table.unpack(traced(t))
	lean += TOY_SWAY * math.sin(math.max(t - TOY_HELD, 0) / TOY_SWAY_EVERY * 2 * math.pi)
	-- the hand out from the trunk and up along it; kept wide of the head
	local a = math.rad(lean)
	local side, along = right * math.cos(a) - up * math.sin(a), right * math.sin(a) + up * math.cos(a)
	lean -= math.min(math.max(TOY_CLEAR - side, 0) * TOY_FOLLOW, TOY_FOLLOW_MOST)
	a = math.rad(lean)
	local raised = eased((along - TOY_HIGH) / TOY_HIGH_BY)
	local ending = eased((t - TOY_END) / TOY_END_IN)
	side = math.max(side, TOY_OUT_LOW + (TOY_OUT_HIGH + (TOY_OUT_END - TOY_OUT_HIGH) * ending - TOY_OUT_LOW) * raised)
	along += (math.sqrt(math.max(1 - side * side, 0)) - along) * raised
	right, up = side * math.cos(a) + along * math.sin(a), along * math.cos(a) - side * math.sin(a)
	local flat = math.sqrt(right * right + up * up)
	if flat > 1 then right, up, flat = right / flat, up / flat, 1 end
	local turn = table.clone(body.base)
	turn.LowerTorso = CFrame.new(shift * HEIGHT, 0, 0) * turn.LowerTorso * CFrame.Angles(0, 0, -a * TOY_HIPS)
	turn.UpperTorso *= CFrame.Angles(0, -math.rad(TOY_TWIST) * right, -a * (1 - TOY_HIPS))
	local at = build(turn)
	local shoulder = (at.UpperTorso * joints.RightUpperArm.c0).Position
	reach(turn, "Right", shoulder + Vector3.new(right, up, -TOY_FORWARD * math.sqrt(1 - flat * flat)) * body.arm, shoulder + Vector3.new(0.5, -0.5, 0.3) * body.arm,
		false, (0.95 + (TOY_STRAIGHT - 0.95) * raised) * (1 - (1 - TOY_PULL) * math.sin(math.pi * ending) ^ 2))
	-- the left arm: out to the side, then the fist against the side of the hips with the elbow straight out
	local out = math.rad(left)
	shoulder = (at.UpperTorso * joints.LeftUpperArm.c0).Position
	local hips, hand = first.LowerTorso.Size, first.LeftHand.Size
	local floating = shoulder + Vector3.new(-math.sin(out), -math.cos(out), -0.15) * body.arm
	local onHip = eased((t - TOY_HIP_AT) / TOY_HIP_IN)
	reach(turn, "Left", floating:Lerp(at.LowerTorso * Vector3.new(-hips.X / 2 - hand.X * 0.3, hips.Y * 0.4, -hips.Z * 0.2), onHip),
		shoulder + Vector3.new(-0.3, -0.2, 0.6):Lerp(Vector3.new(-1, -0.45, 0.15), onHip) * body.arm)
	at = build(turn)
	local neck = at.UpperTorso * joints.Head.c0
	local to = (at.RightHand.Position - at.Head.Position).Unit
	turn.Head = neck.Rotation:Inverse() * CFrame.lookAt(Vector3.zero, (-Vector3.zAxis):Lerp(to, TOY_LOOK)).Rotation * joints.Head.c1.Rotation
	for name, stand in body.feet do
		reach(turn, name, stand.ankle, stand.knee, true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * stand.foot * joints[name .. "Foot"].c1.Rotation
	end
	return turn
end }

-- Book Kicker, a 1st-place emote (Alan 2026-11-21: "jump a little bit to the side of the books, still looking at the
-- camera, and kick them so that they fly towards the camera"; the feeling: the cheeky kid who is done with
-- schoolwork, unbothered, then one sudden hard kick). Timed from his Gemini video
-- (.planning/emotes/book-kicker-gemini-api-1.mp4), posed by numbers: its stack is shin high, 1st's is 0.77 of a
-- winner's height and 0.56 wide, and its dismount was a step down behind the stack ("you will have to make a better
-- dismount"). Seconds after 1st's light (KICK): fists on the hips, head bowed at the books; looks up, head tilted;
-- crouches (crouch); jumps (off to land), knees tucked, lands deep and stands up (up); glances at the tower; draws
-- the right leg back (wind to swing) and kicks forwards and in at the tower (hit); holds the leg high (through to
-- lower); foot down (planted); fists on the hips, chest out (proud). The kid faces the camera throughout. The clip
-- keeps the kid on one spot: the scene (WinnersCutscene) moves them between HopFrom and HopTo, to their left and
-- back by their own legs' reach (its kickLanding, from this clip's numbers: at the kick the foot's tip is 0.43
-- winner heights to the right of the kid's middle and 0.25 in front of it) and down by their own stack's height,
-- rising HopUp winner heights first, and sends the books off at Kick (the marks). (A first build moved them in the
-- clip, 0.65 to the side: Roblox scales a clip's moves by the body, the stack does not shrink, and Alan saw a short
-- kid "kicking the air" outside the spotlight.) The stance is Toy Pilot's (P.fly at P.held); the left foot stays
-- where it lands.
local KICK = { crouch = 3.0, off = 3.35, land = 3.85, up = 4.6, wind = 5.0, swing = 5.5, hit = 5.62, through = 5.9, lower = 6.6, planted = 7.1, proud = 7.8 }
local KICK_LENGTH, KICK_HOP = 10, 0.1
-- A value at `t` from { seconds, value } rows (numbers or Vector3s), held at the ends: eased from row to row (it
-- stops at every row), or with `through` a smooth line through them (Catmull-Rom: it keeps moving).
local function keyed(keys, t, through)
	local i = 1
	while i < #keys - 1 and keys[i + 1][1] <= t do i += 1 end
	local function row(k) return keys[math.clamp(k, 1, #keys)][2] end
	local b, c = keys[i], keys[i + 1]
	local s = math.clamp((t - b[1]) / (c[1] - b[1]), 0, 1)
	if not through then return b[2] + (c[2] - b[2]) * eased(s) end
	local a, d = row(i - 1), row(i + 2)
	return b[2] + 0.5 * s * (c[2] - a + s * (2 * a - 5 * b[2] + 4 * c[2] - d + s * (3 * (b[2] - c[2]) + d - a)))
end
local V = Vector3.new
-- In winner heights: how far the hips sink, and shift over the standing foot; in degrees: the trunk's lean
-- forwards, its roll to the kid's left, the hips' turn to the kid's left.
local KICK_SINK = { { KICK.crouch, 0 }, { KICK.off - 0.05, 0.1 }, { KICK.off + 0.08, 0 }, { KICK.land, 0 }, { KICK.land + 0.18, 0.17 }, { KICK.up, 0 }, { KICK.wind, 0 }, { KICK.swing, 0.03 }, { KICK.through, 0.02 }, { KICK.planted, 0 } }
local KICK_WEIGHT = { { KICK.up, 0 }, { KICK.swing, -0.05 }, { KICK.lower, -0.05 }, { KICK.planted, 0 } }
local KICK_PITCH = { { KICK.crouch, 0 }, { KICK.off - 0.05, 18 }, { KICK.off + 0.2, 4 }, { KICK.land, 8 }, { KICK.land + 0.18, 26 }, { KICK.up, 0 }, { KICK.wind, 0 }, { KICK.swing, 12 }, { KICK.through, -15 }, { KICK.lower, -12 }, { KICK.planted, 0 }, { KICK.proud, -4 } }
local KICK_ROLL = { { KICK.wind, 0 }, { KICK.swing, 5 }, { KICK.through, 8 }, { KICK.lower, 6 }, { KICK.planted, 0 } }
local KICK_YAW = { { KICK.wind, 0 }, { KICK.swing, -10 }, { KICK.through, 14 }, { KICK.lower, 10 }, { KICK.planted, 0 } }
-- Where the head looks (root frame: forwards is -Z) and its tilt in degrees.
local KICK_LOOK = { { 2.0, V(0, -0.75, -1) }, { 2.9, V(0, 0, -1) }, { KICK.crouch, V(0, 0, -1) }, { KICK.off, V(-0.5, -0.6, -1) }, { KICK.land + 0.14, V(-0.1, -0.5, -1) }, { KICK.up, V(0, 0, -1) }, { KICK.up + 0.15, V(0.9, -0.5, -1) }, { KICK.wind - 0.1, V(0.9, -0.5, -1) }, { KICK.wind + 0.25, V(0, -0.05, -1) }, { KICK.planted, V(0, 0, -1) }, { KICK.proud, V(0, 0.14, -1) } }
local KICK_TILT = { { 2.2, 0 }, { 2.9, 12 }, { KICK.crouch, 12 }, { KICK.off, 0 } }
-- Both ankles off the ground in the air; the kicking ankle from where it stands: back and up, low through the
-- middle, into the tower, high in front (to the kid's right, up, back).
local KICK_TUCK = { { KICK.off, 0 }, { (KICK.off + KICK.land) / 2, 0.13 }, { KICK.land, 0 } }
local KICK_FOOT = { { KICK.wind, V(0, 0, 0) }, { KICK.swing, V(0.02, 0.16, 0.3) }, { KICK.swing + 0.07, V(0.1, 0.06, 0.05) }, { KICK.hit + 0.02, V(0.24, 0.2, -0.2) }, { KICK.through, V(0.28, 0.42, -0.45) }, { KICK.lower, V(0.26, 0.36, -0.42) }, { KICK.planted, V(0, 0, 0) } }
local KICK_TOES = { { KICK.wind, 0 }, { KICK.swing, 1 }, { KICK.lower, 1 }, { KICK.planted, 0 } } -- 0: the foot flat; 1: in line with the shin
-- The arms: which pose when (eased from one to the next). A hand's place from its shoulder in arm lengths
-- { out to its own side, up, back }; the elbows point back and a little down (KICK_ELBOW: no arm here ever points
-- along that line, where an elbow flips); "hips": the fist against the side of the hips, the elbow out.
local KICK_ARMS = { { 2.9, "hips" }, { KICK.off - 0.05, "back" }, { KICK.off + 0.25, "up" }, { KICK.land + 0.1, "land" }, { KICK.up, "loose" }, { KICK.wind, "loose" }, { KICK.swing, "wind" }, { KICK.through, "kick" }, { KICK.lower, "kick" }, { KICK.planted, "loose" }, { KICK.proud, "hips" } }
local KICK_ELBOW = V(0, -0.3, 1)
local KICK_ARM = {
	back = { Left = V(0.25, -0.75, 0.5), Right = V(0.25, -0.75, 0.5) },
	up = { Left = V(0.75, 0.4, -0.15), Right = V(0.35, 0.55, -0.3) }, -- the right arm stays on its own side of the tower
	land = { Left = V(0.5, -0.35, -0.7), Right = V(0.25, -0.7, 0.4) }, -- the right arm back: forwards it went into the tower
	loose = { Left = V(0.2, -0.95, -0.05), Right = V(0.15, -0.95, -0.1) },
	wind = { Left = V(0.6, -0.3, -0.6), Right = V(0.3, -0.5, 0.6) },
	kick = { Left = V(0.85, -0.05, 0.3), Right = V(0.8, 0.1, 0.25) },
}
CUTS.BookKicker = { length = KICK_LENGTH, once = true, clips = { fly = P.fly },
	marks = { HopFrom = KICK.off, HopTo = KICK.land, HopUp = KICK_HOP, Kick = KICK.hit }, pose = function(t, c)
	local body = standing(c)
	local turn = table.clone(body.base)
	-- The stance's right arm is raised straight up (it is Toy Pilot's ending): bent down from there, the upper arm
	-- spun round its own length. It starts as the left arm's mirror image instead.
	for _, part in { "UpperArm", "LowerArm", "Hand" } do
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = body.base["Left" .. part]:GetComponents()
		turn["Right" .. part] = CFrame.new(-x, y, z, r00, -r01, -r02, -r10, r11, r12, -r20, r21, r22)
	end
	local pitch, roll = math.rad(keyed(KICK_PITCH, t)), math.rad(keyed(KICK_ROLL, t))
	turn.LowerTorso = CFrame.new(V(keyed(KICK_WEIGHT, t), -keyed(KICK_SINK, t), 0) * HEIGHT) * turn.LowerTorso
		* CFrame.Angles(-pitch * 0.3, math.rad(keyed(KICK_YAW, t)), roll * 0.5)
	turn.UpperTorso *= CFrame.Angles(-pitch * 0.7, 0, roll * 0.5)
	-- the arms
	local i = 1
	while i < #KICK_ARMS - 1 and KICK_ARMS[i + 1][1] <= t do i += 1 end
	local from, to = KICK_ARMS[i], KICK_ARMS[i + 1]
	local s = eased((t - from[1]) / (to[1] - from[1]))
	local at = build(turn)
	local hips, fist = first.LowerTorso.Size, first.LeftHand.Size
	for _, side in { "Left", "Right" } do
		local sign = side == "Left" and -1 or 1
		local shoulder = (at.UpperTorso * joints[side .. "UpperArm"].c0).Position
		local function arm(name)
			if name == "hips" then
				return at.LowerTorso * V(sign * (hips.X / 2 + fist.X * 0.3), hips.Y * 0.4, -hips.Z * 0.2), shoulder + V(sign, -0.45, 0.15) * body.arm
			end
			local p = KICK_ARM[name][side]
			return shoulder + V(sign * p.X, p.Y, p.Z) * body.arm, shoulder + KICK_ELBOW * body.arm
		end
		local hand0, elbow0 = arm(from[2])
		local hand1, elbow1 = arm(to[2])
		-- round the shoulder from one to the other (straight across, the hand passed through the shoulder and the arm flipped)
		local v0, v1 = hand0 - shoulder, hand1 - shoulder
		local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
		reach(turn, side, shoulder + CFrame.fromAxisAngle(axis, angle * s) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * s), elbow0:Lerp(elbow1, s))
	end
	-- the head
	at = build(turn)
	local neck = at.UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * (CFrame.lookAt(Vector3.zero, keyed(KICK_LOOK, t)).Rotation * CFrame.Angles(0, 0, math.rad(keyed(KICK_TILT, t)))) * joints.Head.c1.Rotation
	-- the legs: the left foot stands where it is, the right one too until it kicks
	local tuck = V(0, keyed(KICK_TUCK, t), 0) * HEIGHT
	for name, stand in body.feet do
		local kicking = name == "Right" and keyed(KICK_FOOT, t, true) * HEIGHT or Vector3.zero
		reach(turn, name, stand.ankle + tuck + kicking, stand.knee + tuck + kicking * 0.5, true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		local flatFoot = ankle.Rotation:Inverse() * stand.foot * joints[name .. "Foot"].c1.Rotation
		turn[name .. "Foot"] = name == "Right" and flatFoot:Lerp(body.base.RightFoot.Rotation, keyed(KICK_TOES, t)) or flatFoot
	end
	return turn
end }

local folder = game.ServerStorage:FindFirstChild("RBX_ASSISTANT_ANIMGEN")
-- A clip as a function of its own seconds (held at its ends), and its length.
local function clip(name)
	local source = name:find("^rbxassetid") and game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(name) or assert(folder and folder:FindFirstChild(name), "no clip " .. name)
	local keys = source:GetKeyframes()
	table.sort(keys, function(a, b) return a.Time < b.Time end)
	local hips0, list = {}, {}
	for _, key in keys do -- Roblox's own clips have keys in between whose poses count for nothing (Weight 0): skipped
		local head = key:FindFirstChild("Head", true)
		if head and head.Weight > 0 then table.insert(list, { t = key.Time, turn = turnsOf(key, hips0) }) end
	end
	return function(t)
		local i = 1
		while i < #list - 1 and list[i + 1].t <= t do i += 1 end
		local a, b = list[i], list[math.min(i + 1, #list)]
		return mix(a.turn, b.turn, b.t > a.t and math.clamp((t - a.t) / (b.t - a.t), 0, 1) or 0)
	end, list[#list].t
end
-- A cut as a function of seconds (it loops), and its length.
local function cut(name)
	local recipe, c = assert(CUTS[name], "no cut " .. name), {}
	for key, id in recipe.clips do c[key] = clip(id) end
	return function(t) return recipe.pose(t % recipe.length, c) end, recipe.length, recipe
end
-- Standing straight (no clip): the feet's height under the root, so a sitting clip sits on the desk, not in the air.
local low = math.huge
for name, cf in build({}) do
	local part = first:FindFirstChild(name)
	if part then low = math.min(low, cf.Position.Y - part.Size.Y / 2) end
end

local kids, longest = {}, 0
for i, name in CLIPS do
	local cutName = name:match("^cut:(.+)")
	local pose, length
	if cutName then pose, length = cut(cutName) else pose, length = clip(name) end
	local kid = i == 1 and first or first:Clone()
	kid.Name = "EmoteClipKid" .. i
	local spot = middle + right * (i - (#CLIPS + 1) / 2) * GAP - Vector3.yAxis * low
	kid.Parent = workspace
	kids[i] = { model = kid, pose = pose, root = CFrame.lookAt(spot, spot + back) }
	longest = math.max(longest, length)
end

-- Whatever stands between the lens and the kids is hidden and put back by clean() (emote_preview.lua's walk).
local eye = middle + back * (VIEW.out or 330) + right * (VIEW.side or 0) + Vector3.yAxis * (VIEW.up or 80)
local hidden = {}
local toEye = Vector3.new(eye.X - middle.X, 0, eye.Z - middle.Z)
local reach, along = toEye.Magnitude, toEye.Unit
for _, part in workspace.Arena:GetDescendants() do
	if not part:IsA("BasePart") or part == desk or hidden[part] ~= nil then continue end
	local offset = part.Position - middle
	local forward, sideways = offset:Dot(along), math.abs(offset:Dot(along:Cross(Vector3.yAxis)))
	if forward > -60 and forward < reach + 10 and sideways < GAP * #CLIPS / 2 + 60 and offset.Y > 2 and offset.Y < 170 and part.Size.Magnitude < 300 then
		local top = part
		while top.Parent and top.Parent ~= workspace.Arena and top.Parent.Name ~= "CityToys" do top = top.Parent end
		for _, piece in top:IsA("BasePart") and { top, table.unpack(top:GetDescendants()) } or top:GetDescendants() do
			if piece:IsA("BasePart") and hidden[piece] == nil then hidden[piece] = piece.Transparency; piece.Transparency = 1 end
		end
	end
end

-- Every kid at `t` seconds.
function E.frame(t)
	for _, kid in kids do
		for name, cf in build(kid.pose(t)) do
			local part = kid.model:FindFirstChild(name)
			if part then part.CFrame = kid.root * cf end
		end
	end
	camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, FOV
	camera.CFrame = CFrame.lookAt(eye, middle + Vector3.yAxis * (VIEW.at or 60))
	task.wait(0.05)
	return "ok"
end
-- A cut as a plain R15 animation named `name` under `parent`, 30 keys a second: looping, its last key the same as
-- its first, or for a cut marked `once` played through to its own last pose. `marks` (or the cut's own): attributes
-- for the scene to read (seconds of the moments its props follow).
function E.bake(cutName, parent, name, marks)
	local pose, length, recipe = cut(cutName)
	local out = Instance.new("KeyframeSequence")
	out.Name, out.Loop, out.Priority = name, not recipe.once, Enum.AnimationPriority.Action
	for key, value in marks or recipe.marks or {} do out:SetAttribute(key, value) end
	local last = math.floor(length * 30 + 0.5)
	for n = 0, last do
		local frame = Instance.new("Keyframe")
		frame.Time = n / 30
		local turn = pose(n == last and (recipe.once and length - 1e-3 or 0) or n / 30)
		local poses = { HumanoidRootPart = Instance.new("Pose") }
		poses.HumanoidRootPart.Name, poses.HumanoidRootPart.Parent = "HumanoidRootPart", frame
		local function add(part)
			if poses[part] then return poses[part] end
			local made = Instance.new("Pose")
			made.Name, made.Parent = part, add(joints[part].parent)
			if turn[part] then made.CFrame = turn[part].Rotation + turn[part].Position / scale
			else made.Weight = 0 end -- a part the cut leaves alone: whatever plays underneath (the standing idle) shows
			poses[part] = made
			return made
		end
		for _, part in order do if turn[part] then add(part) end end
		frame.Parent = out
	end
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	out.Parent = parent
	return string.format("ok baked %s: %.2f s", name, length)
end
E.clip, E.cut, E.build, E.joints, E.first, E.scale = clip, cut, build, joints, first, scale -- for number checks (emote_preview.py --run)
function E.clean()
	for _, kid in kids do kid.model:Destroy() end
	for part, was in hidden do part.Transparency = was end
	camera.CFrame, camera.FieldOfView = home.cf, home.fov
	_G.EMOTE = nil
	task.wait(0.2) -- set last and after a wait: set first, Studio's camera stayed Scriptable
	camera.CameraType = Enum.CameraType.Fixed
end
return string.format("ready: %d kids, longest %.2f s, kid scale %.1f", #kids, longest, scale)
