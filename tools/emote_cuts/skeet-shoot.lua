-- Skeet Shoot, a 1st-place emote using all three winners (docs/workshop/emotes/skeet-shoot.md; card OK'd by Alan
-- 2026-11-22, the reference video .planning/emotes/skeet-shoot-gemini-api-2.mp4 "good enough", the ending changed to
-- arms crossed over the chest). The feeling: a cocky, lazy sharpshooter; only the puffs are sharp.
-- Two kinds of clip:
-- * SkeetShoot, 1st's body, once, in seconds after 1st's light: the right hand reaches behind the back and comes out
--   with a straw (the scene's prop, src/client/emotes/SkeetShoot.luau) and lifts it to the mouth; a look and a nod at
--   the runner-up on the kid's left (3rd, on the picture's right); the straw follows that plane and puffs (Shot1); a
--   nod to the other side without looking; the straw swings out at the second plane, eyes on the camera, and puffs
--   (Shot2); the straw comes off the mouth (Off), the hand holds it out in front while it twirls (Twirl to Twirled,
--   the spin is the module's), tucks it behind the back (Tucked), and the arms cross over the chest.
--   While the straw is at the mouth the hand is at the mouth plus AIM's way times SK.grip of the straw. The module
--   points the straw itself (at the plane, or ahead), through the hand: on a big head the baked arm can land the hand
--   in the face, and a straw laid from the mouth through the hand then pointed backwards (measured on bots' bodies).
-- * SkeetThrowRight / SkeetThrowLeft, a runner-up's throw towards their own right / left, once, 1.3 s: the left arm
--   reaches behind the back (Grab: the scene puts their own plane in the hand), comes up cocked by the shoulder and
--   throws up and across (Release), follows through; the chest winds and turns into it, the head follows the throw.
--   Upper body only (chest, head, left arm): played over the runner-up's frozen emote, so a sitting kid stays sitting
--   (Alan 2026-11-22: "we can try it"). The module fades it out at End.
-- Places are in winner heights in the root's frame (forwards -Z, the kid's right +X). The planes' hit points (HIT_A
-- for the first plane, from the kid's left; HIT_B the second) are from the head and must match the module's.
local SK = { length = 11, straw = 0.3, grip = 0.55 }
SK.marks = { Grab = 0.5, Mouth = 1.1, Shot1 = 2.7, Shot2 = 4.7, Off = 5.5, Twirl = 6.0, Twirled = 7.4, Tucked = 8.25 }
SK.HIT_A, SK.HIT_B = V(0.4, 0.3, -0.55), V(-0.4, 0.3, -0.55)
local REST = V(0.12, -0.3, -1) -- where the straw points while nothing is flying (from the head, a point ahead)
-- What the straw points at (from the head): resting, at 3rd's hand, along the first plane's flight, leading it to the
-- hit point, a kick up at the puff, back; then out at the second plane's hit point without a look, the kick, back.
local AIM = { { 2.0, REST }, { 2.25, V(-0.8, 0.1, -1.0) }, { 2.45, V(-0.4, 0.3, -0.6) }, { 2.6, SK.HIT_A }, { 2.7, SK.HIT_A },
	{ 2.78, SK.HIT_A + V(0, 0.12, 0) }, { 3.0, SK.HIT_A }, { 3.5, REST }, { 4.25, REST }, { 4.6, SK.HIT_B }, { 4.7, SK.HIT_B },
	{ 4.78, SK.HIT_B + V(0, 0.12, 0) }, { 5.0, SK.HIT_B }, { 5.5, REST } }
-- The head: where it looks (straight ahead, at 3rd, a little towards 2nd while it nods), how much it follows the straw
-- instead, its nods down (degrees), its cocky tilt (degrees).
local F = V(0, 0, -1)
local LOOK = { { 1.1, F }, { 1.3, V(-0.75, 0, -1) }, { 1.85, V(-0.75, 0, -1) }, { 2.2, F }, { 3.2, F }, { 3.35, V(0.25, 0, -1) }, { 3.7, F } }
local FOLLOW = { { 1.9, 0 }, { 2.2, 0.8 }, { 2.95, 0.8 }, { 3.3, 0 } }
local NOD = { { 1.3, 0 }, { 1.45, 12 }, { 1.65, 0 }, { 3.3, 0 }, { 3.45, 10 }, { 3.65, 0 } }
local TILT = { { 0, 6 }, { 8.6, 6 }, { 9.3, 9 } }
local CHIN = { { 8.6, 0 }, { 9.3, 6 } } -- degrees up, arms crossed
-- The puffs: 1 at the sharpest (the chest pitches forward SK_POKE degrees, the head stays level: it pokes forward).
local POKE = { { 2.68, 0 }, { 2.72, 1 }, { 2.95, 0 }, { 4.68, 0 }, { 4.72, 0.7 }, { 4.95, 0 } }
local SK_POKE, SK_SHIFT, SK_HIP = 7, 0.025, 5
-- The arms: which pose when, eased from one to the next round the shoulder.
-- (lift and low: out at the side on the way round, so the hand never cuts through the chest or hips)
local R_ARMS = { { 0.1, "hang" }, { 0.5, "back" }, { 0.78, "lift" }, { 1.1, "mouth" }, { 5.5, "mouth" }, { 6.0, "front" }, { 7.6, "front" }, { 7.88, "low" }, { 8.15, "back" }, { 8.45, "back" }, { 8.8, "low" }, { 9.3, "cross" } }
local L_ARMS = { { 8.4, "hang" }, { 8.85, "fore" }, { 9.3, "cross" } }
local ELBOW = { hang = V(1, -0.2, 0.3), back = V(1, -0.3, 0.6), lift = V(1, -0.6, 0.4), low = V(1, -0.3, 0.4), fore = V(1, -0.8, 0.3), mouth = V(1, -0.8, 0.1), front = V(0.6, -1, 0.3), cross = V(0.6, -1, -0.6) }
-- Crossed: the upper arm's way from the shoulder and the forearm's from the elbow (x out to its own side), for the arm
-- over and the arm under.
local CROSS_UPPER = { over = V(-0.2, -0.5, -0.85), under = V(-0.15, -0.65, -0.7) }
local CROSS_FORE = { over = V(-1, 0.05, -0.1), under = V(-1, -0.02, 0.05) }

local function looked(turn, dir, nod, tilt)
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(-math.rad(nod), 0, math.rad(tilt))).Rotation * joints.Head.c1.Rotation
end
-- The hips over the kid's left leg a little, a slow sway and breath; as high as the straighter leg allows.
local function skTrunk(t, body)
	local turn = table.clone(body.base)
	for _, side in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[side .. part] = CFrame.identity end
	end
	local hip = math.rad(SK_HIP)
	turn.LowerTorso = CFrame.new(V(-SK_SHIFT + 0.004 * math.sin(t / 4.3 * 2 * math.pi), 0, 0) * HEIGHT) * turn.LowerTorso * CFrame.Angles(0, 0, -hip)
	turn.UpperTorso *= CFrame.Angles(-math.rad(SK_POKE * keyed(POKE, t)) + math.rad(0.7 * math.sin(t / 3.1 * 2 * math.pi)), 0, hip * 0.6)
	local at, sink = build(turn), -math.huge
	for name, stand in body.feet do
		local top = (at.LowerTorso * joints[name .. "UpperLeg"].c0).Position
		local flat = V(top.X - stand.ankle.X, 0, top.Z - stand.ankle.Z).Magnitude
		sink = math.max(sink, top.Y - stand.ankle.Y - math.sqrt(math.max((body.leg * 0.99) ^ 2 - flat * flat, 0)))
	end
	turn.LowerTorso = CFrame.new(0, -sink, 0) * turn.LowerTorso
	return turn
end
-- The mouth: low on the front of the head.
local function mouthOf(at)
	local head = first.Head.Size
	return at.Head * V(0, -0.2 * head.Y, -0.5 * head.Z)
end
-- One arm's hand and elbow pole for a named pose.
local function skArm(name, side, at, body, mouth, aim)
	local s = side == "Left" and -1 or 1
	local shoulder = (at.UpperTorso * joints[side .. "UpperArm"].c0).Position
	local pole = shoulder + V(s * ELBOW[name].X, ELBOW[name].Y, ELBOW[name].Z) * body.arm
	local hips, hand, chest = first.LowerTorso.Size, first.RightHand.Size, first.UpperTorso.Size
	if name == "hang" then return shoulder + V(s * 0.06, -0.96, -0.02) * body.arm, pole
	elseif name == "back" then return at.LowerTorso * V(s * 0.4 * hips.X, 0.6 * hips.Y, 0.5 * hips.Z + 0.9 * hand.Z), pole
	elseif name == "lift" then return shoulder + V(s * 0.5, 0, -0.3) * body.arm, pole
	elseif name == "low" then return shoulder + V(s * 0.6, -0.6, 0.1) * body.arm, pole
	elseif name == "fore" then return shoulder + V(s * 0.25, -0.65, -0.6) * body.arm, pole
	elseif name == "mouth" then return mouth + aim * SK.grip * SK.straw * HEIGHT, pole
	elseif name == "front" then return shoulder + V(s * 0.1, -0.35, -0.85).Unit * 0.85 * body.arm, pole
	end -- crossed (Alan 2026-11-22: "one arm folds under the other", not straight arms meeting at the elbows; aimed at
	-- the other side, a kid's arm only got there straight): the elbow is placed, the upper arm down and forward
	-- (CROSS_UPPER), and the forearm folds straight across from it (CROSS_FORE); the right arm over and in front, the
	-- left tucked under
	local over = s > 0
	local elbowAt = (at[side .. "UpperArm"] * joints[side .. "LowerArm"].c0).Position
	local upper, lower = (elbowAt - shoulder).Magnitude, (at[side .. "Hand"].Position - elbowAt).Magnitude
	local u, f = CROSS_UPPER[over and "over" or "under"], CROSS_FORE[over and "over" or "under"]
	local elbow = shoulder + V(s * u.X, u.Y, u.Z).Unit * upper
	return elbow + V(s * f.X, f.Y, f.Z).Unit * lower, elbow
end
-- Round the shoulder from the pose before to the next (straight across, a hand can pass through the body).
local function between(list, t)
	local i = 1
	while i < #list - 1 and list[i + 1][1] <= t do i += 1 end
	local from, to = list[i], list[math.min(i + 1, #list)]
	return from[2], to[2], to[1] > from[1] and eased((t - from[1]) / (to[1] - from[1])) or 0
end
local function moveArm(turn, side, list, t, body, mouth, aim)
	local at = build(turn)
	local shoulder = (at.UpperTorso * joints[side .. "UpperArm"].c0).Position
	local a, b, s = between(list, t)
	local hand0, elbow0 = skArm(a, side, at, body, mouth, aim)
	local hand1, elbow1 = skArm(b, side, at, body, mouth, aim)
	local v0, v1 = hand0 - shoulder, hand1 - shoulder
	local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
	reach(turn, side, shoulder + CFrame.fromAxisAngle(axis, angle * s) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * s), elbow0:Lerp(elbow1, s), false, 0.96)
end
local function plantFeet(turn, body)
	for name, stand in body.feet do
		reach(turn, name, stand.ankle, stand.knee, true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * stand.foot * joints[name .. "Foot"].c1.Rotation
	end
end
function SK.pose(t, c)
	local body = standing(c)
	local turn = skTrunk(t, body)
	-- the head first: the mouth moves with it
	local at = build(turn)
	local mouth = mouthOf(at)
	local aimAt = at.Head.Position + keyed(AIM, t) * HEIGHT
	local aim = (aimAt - mouth).Unit
	local look = keyed(LOOK, t).Unit:Lerp(aim, keyed(FOLLOW, t))
	looked(turn, (look + V(0, math.sin(math.rad(keyed(CHIN, t))), 0)).Unit, keyed(NOD, t), keyed(TILT, t))
	at = build(turn)
	mouth = mouthOf(at)
	aim = (aimAt - mouth).Unit
	moveArm(turn, "Right", R_ARMS, t, body, mouth, aim)
	moveArm(turn, "Left", L_ARMS, t, body, mouth, aim)
	plantFeet(turn, body)
	return turn
end
CUTS.SkeetShoot = { length = SK.length, once = true, marks = SK.marks, clips = { fly = P.fly }, pose = SK.pose }

-- The throw (`dir` 1: towards the kid's own right).
local THROW = { Grab = 0.4, Release = 0.7, End = 1.05, length = 1.3 }
local T_ARMS = { { 0, "hang" }, { 0.4, "back" }, { 0.6, "cock" }, { THROW.Release, "throw" }, { 0.9, "follow" }, { 1.3, "follow" } }
local T_ELBOW = { hang = V(-1, -0.2, 0.3), back = V(-1, -0.3, 0.6), cock = V(-1, -0.5, 0.2), throw = V(-1, -0.6, -0.1), follow = V(-1, -0.8, 0) }
local THROW_PARTS = { "UpperTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand" }
function SK.throw(t, c, dir)
	local body = standing(c)
	local turn = table.clone(body.base)
	for _, part in { "UpperArm", "LowerArm", "Hand" } do turn["Left" .. part] = CFrame.identity end
	local yaw = keyed({ { 0.4, 0 }, { 0.62, dir * 10 }, { 0.8, -dir * 15 }, { 1.3, -dir * 8 } }, t)
	local pitch = keyed({ { 0.4, 0 }, { 0.62, -6 }, { 0.8, 5 }, { 1.3, 2 } }, t)
	turn.UpperTorso *= CFrame.Angles(-math.rad(pitch), math.rad(yaw), 0)
	local at = build(turn)
	local shoulder = (at.UpperTorso * joints.LeftUpperArm.c0).Position
	local hips, hand = first.LowerTorso.Size, first.LeftHand.Size
	local function pose(name)
		local pole = shoulder + T_ELBOW[name] * body.arm
		if name == "hang" then return shoulder + V(-0.06, -0.96, -0.02) * body.arm, pole
		elseif name == "back" then return at.LowerTorso * V(-0.4 * hips.X, 0.6 * hips.Y, 0.5 * hips.Z + 0.9 * hand.Z), pole
		elseif name == "cock" then return shoulder + V(-0.45, 0.55, 0.35) * body.arm, pole
		elseif name == "throw" then return shoulder + V(dir * 0.45, 0.75, -0.45) * body.arm, pole end
		return shoulder + V(dir * 0.5, 0, -0.8) * body.arm, pole
	end
	local a, b, s = between(T_ARMS, t)
	local hand0, elbow0 = pose(a)
	local hand1, elbow1 = pose(b)
	local v0, v1 = hand0 - shoulder, hand1 - shoulder
	local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
	reach(turn, "Left", shoulder + CFrame.fromAxisAngle(axis, angle * s) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * s), elbow0:Lerp(elbow1, s), false, 0.96)
	looked(turn, keyed({ { 0, F }, { 0.35, V(dir * 0.6, 0.15, -1) }, { THROW.Release, V(dir * 0.8, 0.5, -1) }, { 1.3, V(dir * 0.9, 0.4, -1) } }, t).Unit, 0, 0)
	return only(THROW_PARTS, turn)
end
local throwMarks = { Grab = THROW.Grab, Release = THROW.Release, End = THROW.End }
CUTS.SkeetThrowRight = { length = THROW.length, once = true, marks = throwMarks, clips = { fly = P.fly }, pose = function(t, c) return SK.throw(t, c, 1) end }
CUTS.SkeetThrowLeft = { length = THROW.length, once = true, marks = throwMarks, clips = { fly = P.fly }, pose = function(t, c) return SK.throw(t, c, -1) end }
_G.SKEET = SK -- for the number checks (emote_preview.py --run)
