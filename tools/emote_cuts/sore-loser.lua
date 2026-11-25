-- Sore Loser (docs/workshop/emotes/sore-loser.md; card OK'd by Alan 2026-11-24, standing, silent; reference video OK'd
-- "a little fast"). A runner-up, jealous and sulking. Rebuilt after Alan's own Play (2026-11-24): "there's not enough
-- body language ... they're not stamping their foot ... the reference video was better at showing it ... at the start,
-- turn away from the first place. They need to physically turn and cross their arms and then look back." So the sulk
-- is acted out with the whole body, and the turn away is seen: the kid stands facing us until 1st's light, looks at
-- 1st, then hop-turns away crossing the arms, stamps, huffs, and looks back over the shoulder, all within about
-- 3 s of 1st's light (the scene may cut the runner-ups short under a lens emote: `kit.seenFor`).
-- Two clips, the same but for the side: SoreLoserLeft for 1st on the kid's own left (1st on the picture's right: the
-- kid turns to their right and looks back over the left shoulder), SoreLoserRight the mirror. Played once, 12 s; the
-- module (src/client/emotes/SoreLoser.luau) sets the clip's time each frame: clip second 1.0 is 1st's light.
-- The stance is Toy Pilot's standing pose (`standing`, as Bubblegum's). Every row below is { clip seconds, value },
-- eased from row to row (`keyed`). In clip seconds:
--   0 to 1.0   faces us, arms hanging, breathing (2nd is lit 1 s before 1st)
--   1.0 to 1.3 the head turns LOOK degrees to 1st (sees them win); a beat
--   1.5 to 2.45 the hop-turn: a dip, a little hop (HOP heights) turning TURN degrees away, both arms folding into the
--              cross on the way (the tucked one first), the chin up; lands with a dip
--   2.45 to 3.0 the stamp: the foot away from 1st lifts STAMP heights (knee up) and slams down, the body jolts
--   2.85 to 3.7 the huff: the chest 12 degrees back, then slumps past, back
--   3.5 to 5.55 the first look back: the chest turns PEEK_CHEST degrees round and the head with it until the face is
--              to us (the video's), the chin dipping, creeping; held; snapped back with a jerk of the chin
--   5.8 to 7.4 weight onto the away leg, impatient; the other foot kicks up behind (KICK_*) and stamps down
--   7.4 to 9.85 the second look back, held longer; snapped back
--   10 to 12   a smaller huff, the weight onto the other leg
-- The arms cross as Skeet Shoot's (Alan 2026-11-22: "one arm folds under the other"): each elbow placed, the forearm
-- folded straight across, the right over and in front, the left tucked under; in the chest's own frame, the elbows
-- further forward than Skeet Shoot's (with its own the tucked arm went up to 0.11 heights into the chest's box on the
-- bots' bodies; this way 0.06 at most). While folding, each arm joint turns from hanging to crossed.
-- Sizes for the scene's distance (the kids stand small, far from the lens): a first build at a hop of 0.03 heights,
-- a stamp of 0.07 and a huff of 8 degrees was made bigger before anyone saw it, since "no movement" was the note.
local SL = { length = 12, TURN = 70, LOOK = 35, HOP = 0.05, STAMP = 0.10, KICK_UP = 0.12, KICK_BACK = 0.08, KICK_TOE = 40,
	PEEK = 70, PEEK_CHEST = 30, PEEK_DOWN = 6, SHIFT = 0.03, SHIFT_ROLL = 6, BREATH_EVERY = 4, BREATH = 1, JOLT = 7,
	CROSS_UPPER = { over = V(-0.2, -0.5, -1.2), under = V(-0.15, -0.65, -1.2) }, CROSS_FORE = { over = V(-1, 0.05, -0.1), under = V(-1, -0.02, -0.25) } }
SL.TURNING = { { 1.68, 0 }, { 2.12, 1 } } -- share of TURN
SL.LOOKING = { { 1.0, 0 }, { 1.3, 1 }, { 1.65, 1 }, { 2.05, 0 } } -- share of LOOK (towards 1st)
SL.UNDER = { { 1.6, 0 }, { 2.05, 1 } } -- the tucked arm's fold
SL.OVER = { { 1.72, 0 }, { 2.15, 1 } } -- the arm over it
SL.HOPPING = { { 1.65, 0 }, { 1.9, 1 }, { 2.13, 0 } } -- share of HOP, the feet with the hips
SL.DIP = { { 1.5, 0 }, { 1.62, 0.012 }, { 1.7, 0 }, { 2.12, 0 }, { 2.2, 0.025 }, { 2.45, 0 }, { 2.74, 0 }, { 2.79, 0.015 }, { 3.0, 0 },
	{ 7.12, 0 }, { 7.17, 0.015 }, { 7.4, 0 } } -- the hips down, in heights (the knees bend)
SL.STAMPING = { { 2.45, 0 }, { 2.66, 1 }, { 2.74, 0 } } -- the away foot up (share of STAMP)
SL.KICKING = { { 6.6, 0 }, { 6.95, 1 }, { 7.05, 1 }, { 7.15, 0 } } -- the other foot up behind
SL.JOLTS = { { 2.74, 0 }, { 2.78, 1 }, { 3.0, 0 }, { 7.12, 0 }, { 7.16, 1 }, { 7.4, 0 } } -- the stamp's jolt: chest JOLT forward, a nod
SL.CHEST = { { 2.85, 0 }, { 3.1, 12 }, { 3.4, -5 }, { 3.7, 0 }, { 5.3, 0 }, { 5.4, 3 }, { 5.7, 0 }, { 9.6, 0 }, { 9.7, 3 }, { 9.95, 0 },
	{ 10.0, 0 }, { 10.25, 9 }, { 10.55, -4 }, { 10.85, 0 } } -- degrees back: the huffs and the shrugs on the snaps
SL.CHIN = { { 1.3, 0 }, { 2.1, 10 }, { 3.1, 14 }, { 3.7, 10 }, { 5.3, 10 }, { 5.45, 15 }, { 5.8, 13 }, { 9.6, 13 }, { 9.75, 16 }, { 10.2, 13 } } -- degrees up
SL.PEEKING = { { 3.5, 0 }, { 4.4, 1 }, { 5.3, 1 }, { 5.55, 0 }, { 7.4, 0 }, { 8.4, 1 }, { 9.6, 1 }, { 9.85, 0 } }
SL.SHIFTING = { { 5.8, 0 }, { 6.5, 1 }, { 7.4, 1 }, { 8.0, 0 }, { 10.6, 0 }, { 11.4, -0.7 } } -- 1: on the away leg
SL.marks = { Look = 1.0, Turn = 1.68, Stamp = 2.74, Peek = 3.5, Snap = 5.3, Kick = 7.12, Peek2 = 7.4, Snap2 = 9.6 }

-- The pose at `t`; `side` 1: 1st on the kid's left (turned to the right, looking back over the left shoulder), -1 the mirror.
function SL.pose(t, c, side)
	local body = standing(c)
	local turn = table.clone(body.base)
	for _, s in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[s .. part] = CFrame.identity end
	end
	local yaw = -side * math.rad(SL.TURN) * keyed(SL.TURNING, t)
	local spin = CFrame.Angles(0, yaw, 0)
	local shift, hop = keyed(SL.SHIFTING, t), keyed(SL.HOPPING, t) * SL.HOP
	local roll = side * shift * math.rad(SL.SHIFT_ROLL)
	turn.LowerTorso = CFrame.new(spin * V(side * shift * SL.SHIFT, hop - keyed(SL.DIP, t), 0) * HEIGHT) * spin * turn.LowerTorso * CFrame.Angles(0, 0, roll)
	local peek, jolt = keyed(SL.PEEKING, t), keyed(SL.JOLTS, t)
	local back = keyed(SL.CHEST, t) - SL.JOLT * jolt + SL.BREATH * math.sin(t / SL.BREATH_EVERY * 2 * math.pi)
	turn.UpperTorso *= CFrame.Angles(math.rad(back), side * math.rad(SL.PEEK_CHEST) * peek, -roll * 1.4)
	-- the arms: from hanging to crossed, each joint turning
	local at = build(turn)
	local chest, crossed = at.UpperTorso, table.clone(turn)
	for _, s in { "Right", "Left" } do
		local sign, over = s == "Right" and 1 or -1, s == "Right"
		local shoulder = (chest * joints[s .. "UpperArm"].c0).Position
		local elbowAt = (at[s .. "UpperArm"] * joints[s .. "LowerArm"].c0).Position
		local upper, lower = (elbowAt - shoulder).Magnitude, (at[s .. "Hand"].Position - elbowAt).Magnitude
		local u, f = SL.CROSS_UPPER[over and "over" or "under"], SL.CROSS_FORE[over and "over" or "under"]
		local elbow = shoulder + chest:VectorToWorldSpace(V(sign * u.X, u.Y, u.Z).Unit) * upper
		reach(crossed, s, elbow + chest:VectorToWorldSpace(V(sign * f.X, f.Y, f.Z).Unit) * lower, elbow, false, 0.96)
		local fold = keyed(over and SL.OVER or SL.UNDER, t)
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[s .. part] = CFrame.identity:Lerp(crossed[s .. part], fold) end
	end
	-- the head: level whatever the chest does; facing where the body faces, plus the look at 1st and the looks back
	-- (at a full look back the face is to us); the chin up, dipping as it peeks, nodding at a stamp
	local up = math.rad(keyed(SL.CHIN, t) - SL.PEEK_DOWN * peek - 6 * jolt)
	local face = yaw + side * math.rad(SL.LOOK * keyed(SL.LOOKING, t) + SL.PEEK * peek)
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * CFrame.Angles(0, face, 0) * CFrame.Angles(up, 0, 0) * joints.Head.c1.Rotation
	-- the legs: both feet where they stand, turned with the body; up with the hop; the away foot stamps, the other
	-- kicks up behind
	local away = side == 1 and "Right" or "Left"
	local stamp, kick = keyed(SL.STAMPING, t), keyed(SL.KICKING, t)
	for name, stand in body.feet do
		local lift, knee, toe = V(0, hop, 0), V(0, 0, 0), 0
		if name == away then
			lift += V(0, SL.STAMP * stamp, -0.02 * stamp); knee = V(0, SL.STAMP * stamp, -0.1 * stamp)
		else
			lift += V(0, SL.KICK_UP * kick, SL.KICK_BACK * kick); toe = -SL.KICK_TOE * kick
		end
		reach(turn, name, spin * (stand.ankle + lift * HEIGHT), spin * (stand.knee + (lift + knee) * HEIGHT), true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * spin * stand.foot * CFrame.Angles(math.rad(toe), 0, 0) * joints[name .. "Foot"].c1.Rotation
	end
	return turn
end
CUTS.SoreLoserLeft = { length = SL.length, once = true, marks = SL.marks, clips = { fly = P.fly }, pose = function(t, c) return SL.pose(t, c, 1) end }
CUTS.SoreLoserRight = { length = SL.length, once = true, marks = SL.marks, clips = { fly = P.fly }, pose = function(t, c) return SL.pose(t, c, -1) end }
_G.SORE_LOSER = SL -- for the number checks (emote_preview.py --run)
