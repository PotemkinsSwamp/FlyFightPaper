-- A+ (docs/workshop/emotes/a-plus.md; card OK'd by Alan 2026-11-22: "show only the front ... lands and then gloats";
-- built from his pick of the two Gemini videos, the first: .planning/emotes/a-plus-gemini-api-1.mp4). A 1st-place
-- emote: a smug show-off, "read it and weep", slow and showy, chest out, chin up, then one sharp slap. The body only:
-- the report card in the hand, its flight to the lens and the take-over by the real card are the module's
-- (src/client/emotes/APlus.luau), which also bends both arms again on each avatar's own body so the hands are on the
-- card's two side edges: the arm poses here for reading and holding up are where that starts from.
-- Posed by numbers on Toy Pilot's standing pose (P.fly at P.held; both feet stay exactly where they stand). Seconds
-- after 1st's light (AP below), the card's own times, spread as the video's are (its misses fixed: the card stays in the
-- right hand, it is shown to both sides, the reading shows the back):
-- * 0 to read: reading the card held at the chest, head down (READ_LOOK), one slow nod at nod;
-- * snap to up: both arms up in front of the face (lift: the hands and card never pass through the head) and straight
--   up over it, chest out (CHEST_OUT), chin up (CHIN);
-- * up to lower: from the waist (HIPS_TURN of it in the hips) a turn to the kid's left and a hold, across to the right and
--   a hold, back (TURNS: { seconds, degrees, positive to the kid's left }), the head LOOK_MORE further the same way;
-- * lower to wind: the arms come down round the outside (spread), the right hand out beside the head (the card stands
--   over it), the left fist on the hip, a nod at nod2;
-- * wind to release: the right arm back past the shoulder, the chest twisted away (TWIST), then whipped forward through
--   release (the card leaves the hand: the mark Release) to the follow-through, palm at the camera;
-- * brush to fold: the palms meet at the belly, the right one brushes once up the left;
-- * fold on: arms folded (CROSS below), the weight on the right leg (SHIFT heights, the hips rolled HIP degrees), chin up, still.
-- ARMS: which pose when (eased from one to the next, round the shoulder: straight across a hand passed through it).
-- ARM: each pose's hands from the middle of the shoulders and its elbows' pull, in winner heights { to the kid's right,
-- up, back }; "hips" is Book Kicker's fist on the side of the hips.
local AP = { read = 2.0, nod = 1.5, snap = 2.0, up = 2.4, lower = 5.0, nod2 = 6.0, wind = 6.5, whip = 7.25, release = 7.4,
	through = 7.55, brush = 7.9, brushed = 8.4, fold = 8.6, folded = 9.1, length = 11 }
AP.marks = { Snap = AP.snap, Release = AP.release }
local CHEST_OUT, CHIN, READ_LOOK, LOOK_MORE, HIPS_TURN, TWIST, SHIFT, HIP = 6, 8, 35, 5, 0.4, 28, 0.03, 5
local TURNS = { { AP.up, 0 }, { 3.0, 35 }, { 3.4, 35 }, { 4.2, -35 }, { 4.5, -35 }, { AP.lower, 0 }, { AP.wind, 0 }, { 7.2, -TWIST }, { AP.through, 15 }, { AP.brush, 0 } }
local ARMS = { { 0, "read" }, { AP.snap, "read" }, { 2.2, "lift" }, { AP.up, "high" }, { AP.lower, "high" }, { 5.3, "spread" }, { 5.6, "face" }, { AP.wind, "face" }, { 7.2, "wind" },
	{ AP.whip, "wind" }, { AP.through, "slap" }, { 7.75, "slap" }, { 8.1, "palms" }, { AP.brushed, "palms" }, { AP.folded, "fold" } }
local EDGE = 0.155 -- both hands on the card: each one this far from the body's middle, on a side edge (the card is 0.264 wide)
local ARM = {
	read = { Right = { V(EDGE, -0.2, -0.2), V(0.6, -1, 0.3) }, Left = { V(-EDGE, -0.2, -0.2), V(-0.6, -1, 0.3) } },
	lift = { Right = { V(EDGE, 0.12, -0.3), V(1, -0.2, -0.2) }, Left = { V(-EDGE, 0.12, -0.3), V(-1, -0.2, -0.2) } }, -- the snap goes up in front of the face
	high = { Right = { V(EDGE, 0.335, -0.03), V(1, 0.5, 0.5) }, Left = { V(-EDGE, 0.335, -0.03), V(-1, 0.5, 0.5) } },
	spread = { Right = { V(0.32, 0.25, -0.06), V(1, -0.6, 0.2) }, Left = { V(-0.38, 0.1, -0.05), V(-1, -0.6, 0.2) } }, -- down round the outside
	face = { Right = { V(0.28, 0, -0.06), V(1, -0.6, 0.2) }, Left = { "hips" } },
	wind = { Right = { V(0.3, 0.1, 0.25), V(0.5, -0.4, 1) }, Left = { V(-0.2, -0.15, -0.2), V(-1, -0.5, 0.2) } },
	slap = { Right = { V(0.15, 0.12, -0.32), V(0.5, -1, 0) }, Left = { V(-0.2, -0.2, -0.05), V(-1, -0.5, 0.3) } },
	palms = { Right = { V(0.03, -0.25, -0.15), V(1, -1, 0.3) }, Left = { V(-0.03, -0.25, -0.15), V(-1, -1, 0.3) } },
}
-- Folded arms (Alan on the first recording: "the arm cross is unnatural": each hand was pulled to a point across the
-- chest, which no avatar's arms reach bent (the shoulders are too far apart for them), so it left two nearly
-- straight arms in an X low at the waist, the hands sticking out past the sides). Two references: the fold in the
-- video he picked (9 to 11 s): forearms across the chest, one over the other, hands tucked; and how Roblox's own
-- move generator folds an avatar's arms: the end pose of our clip Camera Flick C (docs/workshop/emote-making.md:
-- "then cross the arms ... ending with arms crossed"), which is what a fold looks like on these bodies: the
-- forearms crossed high and tight on the chest, the elbows out. The arms' joint turns are taken from that pose
-- (CROSS of its seconds), which every body plays the same.
local CROSS = { clip = "rbxassetid://139618321795363", at = 2.9 }
local BRUSH = { { 8.1, 0 }, { 8.25, 0.04 }, { AP.brushed, 0 } } -- the right palm up the left one, heights
local NODS = { { 1.2, 0 }, { AP.nod, 8 }, { 1.85, 0 }, { 5.7, 0 }, { AP.nod2, 8 }, { 6.35, 0 } } -- head down, degrees
local LOOK_DOWN = { { 0, READ_LOOK }, { AP.read, READ_LOOK }, { AP.up, -CHIN }, { AP.wind, -CHIN }, { 7.2, 0 }, { AP.brush, 10 }, { AP.brushed, 10 }, { AP.folded, -CHIN } }
local PROUD = { { 0, 0 }, { AP.snap, 0 }, { AP.up, 1 }, { AP.lower, 1 }, { AP.wind, 0.5 }, { 7.2, 0 }, { AP.brushed, 0 }, { AP.folded, 1 } } -- chest out
local WEIGHT = { { AP.fold, 0 }, { AP.folded, 1 } }
function AP.pose(t, c)
	local body = standing(c)
	local turn = table.clone(body.base)
	for _, side in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[side .. part] = CFrame.identity end
	end
	local yaw, proud, weight = math.rad(keyed(TURNS, t)), keyed(PROUD, t), keyed(WEIGHT, t)
	turn.LowerTorso = CFrame.new(V(SHIFT * weight, 0, 0) * HEIGHT) * turn.LowerTorso * CFrame.Angles(0, yaw * HIPS_TURN, math.rad(HIP * weight))
	turn.UpperTorso *= CFrame.Angles(math.rad(CHEST_OUT * proud), yaw * (1 - HIPS_TURN), -math.rad(HIP * weight))
	-- the arms
	local i = 1
	while i < #ARMS - 1 and ARMS[i + 1][1] <= t do i += 1 end
	local from, to = ARMS[i], ARMS[i + 1]
	local s = eased((t - from[1]) / (to[1] - from[1]))
	local at = build(turn)
	local hips, fist = first.LowerTorso.Size, first.LeftHand.Size
	local mid = ((at.UpperTorso * joints.RightUpperArm.c0).Position + (at.UpperTorso * joints.LeftUpperArm.c0).Position) / 2
	local chest = at.UpperTorso.Rotation
	for _, side in { "Left", "Right" } do
		local sign = side == "Left" and -1 or 1
		local shoulder = (at.UpperTorso * joints[side .. "UpperArm"].c0).Position
		local function arm(name)
			local p = ARM[name][side]
			if p[1] == "hips" then
				return at.LowerTorso * V(sign * (hips.X / 2 + fist.X * 0.3), hips.Y * 0.4, -hips.Z * 0.2), shoulder + V(sign, -0.45, 0.15) * body.arm
			end
			local hand = mid + chest * p[1] * HEIGHT
			if name == "palms" and side == "Right" then hand += chest * V(0, keyed(BRUSH, t), 0) * HEIGHT end
			return hand, shoulder + chest * p[2] * body.arm
		end
		local hand0, elbow0 = arm(from[2])
		if to[2] == "fold" then
			reach(turn, side, hand0, elbow0, false, 0.97) -- the pose it comes from, then joint by joint into the fold
			local crossed = c.cross(CROSS.at)
			for _, part in { "UpperArm", "LowerArm", "Hand" } do
				turn[side .. part] = turn[side .. part]:Lerp(crossed[side .. part].Rotation, s)
			end
			continue
		end
		local hand1, elbow1 = arm(to[2])
		local v0, v1 = hand0 - shoulder, hand1 - shoulder
		local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
		reach(turn, side, shoulder + CFrame.fromAxisAngle(axis, angle * s) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * s), elbow0:Lerp(elbow1, s), false, 0.97)
	end
	-- the head: the chest's turn and LOOK_MORE further, down at the card or chin up, and the nods
	at = build(turn)
	local neck = at.UpperTorso * joints.Head.c0
	local down = math.rad(keyed(LOOK_DOWN, t) + keyed(NODS, t))
	turn.Head = neck.Rotation:Inverse() * CFrame.Angles(0, yaw + math.rad(LOOK_MORE) * math.clamp(yaw / math.rad(35), -1, 1), 0) * CFrame.Angles(-down, 0, 0) * joints.Head.c1.Rotation
	for name, stand in body.feet do
		reach(turn, name, stand.ankle, stand.knee, true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * stand.foot * joints[name .. "Foot"].c1.Rotation
	end
	return turn
end
CUTS.APlus = { length = AP.length, once = true, marks = AP.marks, clips = { fly = P.fly, cross = CROSS.clip }, pose = AP.pose }
_G.A_PLUS = AP -- for the number checks (emote_preview.py --run)
