-- Sore Loser (docs/workshop/emotes/sore-loser.md; card OK'd by Alan 2026-11-24: "Sore loser looks good", standing,
-- silent; the reference video OK'd: "This is a good reference video. I would just fix the timing a bit. It's a little
-- fast."). A runner-up, jealous and sulking, pretending not to care: stiff and held, turned away from 1st, arms
-- crossed tight and high, chin up; almost nothing moves, so the peeks are the joke: the head creeps round slowly over
-- the shoulder to 1st, holds, and snaps back fast as if caught. Two clips, the same but for the side: SoreLoserLeft
-- for 1st on the kid's own left (the body turned to the kid's right, the peeks over the left shoulder),
-- SoreLoserRight the mirror. Played once, 12 s; the module (src/client/emotes/SoreLoser.luau) sets the clip's time
-- each frame: clip second 1.0 is 1st's light.
-- The stance is Toy Pilot's standing pose (`standing`, as Bubblegum's: feet planted apart), the whole body turned
-- TURN degrees about the hips; the feet stay where that puts them. By numbers, in this clip's seconds (SL below):
-- * all through, a breath every BREATH_EVERY seconds (the chest BREATH degrees), so the held pose is not a statue;
-- * the huff: from HUFF_AT the chest goes HUFF degrees back over HUFF_UP seconds (the shoulders rise with it) and
--   drops HUFF_DROP past where it was over HUFF_DOWN, settling back;
-- * the arms crossed as Skeet Shoot's (Alan 2026-11-22: "one arm folds under the other", not straight arms meeting
--   at the elbows): each elbow placed, the upper arm down and forward (CROSS_UPPER), the forearm folded straight
--   across from it (CROSS_FORE); the right arm over and in front, the left tucked under. Skeet Shoot's numbers, here
--   in the chest's own frame, so the arms turn and huff with it;
-- * the head level whatever the chest does, the chin CHIN degrees up, CHIN_AFTER more after the first snap back;
-- * PEEKS: { start, creep, hold, snap }: the head turns PEEK degrees back towards 1st, the chest PEEK_CHEST with it,
--   the chin dipping PEEK_DOWN (sneaking), eased over `creep` seconds; held `hold`; snapped back in `snap`;
-- * TAPS: { start, seconds }: the toes of the foot away from 1st lift TAP degrees and drop, the heel planted.
-- Alan's "a little fast": every move the video makes, made slower here (its creeps 0.8 s, its holds 0.8 and 1.2 s);
-- only the snaps stay fast (they are the joke). Two peeks fit before the scene leaves, the second held longer.
local SL = { length = 12, TURN = 70, BREATH_EVERY = 4, BREATH = 1, HUFF_AT = 1.3, HUFF_UP = 0.5, HUFF_DOWN = 0.9, HUFF = 5, HUFF_DROP = 2,
	CHIN = 8, CHIN_AFTER = 4, PEEK = 55, PEEK_CHEST = 15, PEEK_DOWN = 6, TAP = 18,
	PEEKS = { { 3.0, 1.3, 1.3, 0.25 }, { 7.2, 1.3, 2.0, 0.25 } }, TAPS = { { 6.5, 0.5 } },
	-- the way from the shoulder to the elbow and from the elbow to the hand (x out to the arm's own side), over and
	-- under. Skeet Shoot's, the elbows further forward and the tucked hand a little out from the chest: with Skeet
	-- Shoot's own the tucked arm went 0.04 to 0.11 heights into the chest's box on the bots' bodies (a search on the
	-- test kid: from 0.083 to 0.043, and the forearms into each other from 0.055 to 0.043)
	CROSS_UPPER = { over = V(-0.2, -0.5, -1.2), under = V(-0.15, -0.65, -1.2) }, CROSS_FORE = { over = V(-1, 0.05, -0.1), under = V(-1, -0.02, -0.25) } }
SL.marks = { Huff = SL.HUFF_AT, Peek = SL.PEEKS[1][1], Snap = SL.PEEKS[1][1] + SL.PEEKS[1][2] + SL.PEEKS[1][3],
	Peek2 = SL.PEEKS[2][1], Snap2 = SL.PEEKS[2][1] + SL.PEEKS[2][2] + SL.PEEKS[2][3] }
-- How far round the head is towards 1st at `t` (0 to 1), and whether the first snap is past.
local function peeking(t)
	for _, p in SL.PEEKS do
		local into = t - p[1]
		if into > 0 and into < p[2] + p[3] + p[4] then
			return into < p[2] + p[3] and eased(into / p[2]) or 1 - eased((into - p[2] - p[3]) / p[4])
		end
	end
	return 0
end
-- The pose at `t`; `side` 1: 1st on the kid's left (turned to the right, peeking over the left shoulder), -1 the mirror.
function SL.pose(t, c, side)
	local body = standing(c)
	local turn = table.clone(body.base)
	for _, s in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[s .. part] = CFrame.identity end
	end
	local yaw = -side * math.rad(SL.TURN)
	turn.LowerTorso = CFrame.Angles(0, yaw, 0) * turn.LowerTorso
	local huff = t < SL.HUFF_AT + SL.HUFF_UP and SL.HUFF * eased((t - SL.HUFF_AT) / SL.HUFF_UP)
		or SL.HUFF - (SL.HUFF + SL.HUFF_DROP) * eased((t - SL.HUFF_AT - SL.HUFF_UP) / (SL.HUFF_DOWN * 0.6))
			+ SL.HUFF_DROP * eased((t - SL.HUFF_AT - SL.HUFF_UP - SL.HUFF_DOWN * 0.6) / (SL.HUFF_DOWN * 0.4 + 0.4))
	local peek = peeking(t)
	turn.UpperTorso *= CFrame.Angles(math.rad(huff + SL.BREATH * math.sin(t / SL.BREATH_EVERY * 2 * math.pi)), side * math.rad(SL.PEEK_CHEST * peek), 0)
	-- the arms, crossed (the arms hang straight in `turn` here, so the lengths are the arm's own)
	local at = build(turn)
	local chest = at.UpperTorso
	for _, s in { "Right", "Left" } do
		local sign, over = s == "Right" and 1 or -1, s == "Right"
		local shoulder = (chest * joints[s .. "UpperArm"].c0).Position
		local elbowAt = (at[s .. "UpperArm"] * joints[s .. "LowerArm"].c0).Position
		local upper, lower = (elbowAt - shoulder).Magnitude, (at[s .. "Hand"].Position - elbowAt).Magnitude
		local u, f = SL.CROSS_UPPER[over and "over" or "under"], SL.CROSS_FORE[over and "over" or "under"]
		local elbow = shoulder + chest:VectorToWorldSpace(V(sign * u.X, u.Y, u.Z).Unit) * upper
		reach(turn, s, elbow + chest:VectorToWorldSpace(V(sign * f.X, f.Y, f.Z).Unit) * lower, elbow, false, 0.96)
	end
	-- the head: level, facing where the body faces plus the peek, the chin up
	local snapped = t > SL.marks.Snap and SL.CHIN_AFTER * eased((t - SL.marks.Snap) / 0.3) or 0
	local up = math.rad(SL.CHIN + snapped - SL.PEEK_DOWN * peek)
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * CFrame.Angles(0, yaw + side * math.rad(SL.PEEK + SL.PEEK_CHEST) * peek, 0) * CFrame.Angles(up, 0, 0) * joints.Head.c1.Rotation
	-- the foot tap: the foot away from 1st, toes up about the heel's end of the foot
	local tap = 0
	for _, k in SL.TAPS do
		local u = (t - k[1]) / k[2]
		if u > 0 and u < 1 then tap = math.sin(math.pi * eased(u)) end
	end
	if tap > 0 then
		local foot = side == 1 and "RightFoot" or "LeftFoot"
		local heel = V(0, -first[foot].Size.Y / 2, first[foot].Size.Z / 2) -- the back of the sole, in the foot's frame
		local lift = CFrame.new(heel) * CFrame.Angles(math.rad(SL.TAP * tap), 0, 0) * CFrame.new(-heel)
		turn[foot] = turn[foot] * joints[foot].c1:Inverse() * lift * joints[foot].c1
	end
	return turn
end
CUTS.SoreLoserLeft = { length = SL.length, once = true, marks = SL.marks, clips = { fly = P.fly }, pose = function(t, c) return SL.pose(t, c, 1) end }
CUTS.SoreLoserRight = { length = SL.length, once = true, marks = SL.marks, clips = { fly = P.fly }, pose = function(t, c) return SL.pose(t, c, -1) end }
_G.SORE_LOSER = SL -- for the number checks (emote_preview.py --run)
