-- Fold It Up (docs/workshop/emotes/fold-it-up.md; Alan's OK 2026-11-22 on the second card and its Gemini video,
-- .planning/emotes/fold-it-up-gemini-api-2.mp4: "good enough to work off of"). A 1st-place emote: smug, "that's all
-- you are to me". The kid sizes you up, rubs their hands, reaches straight at the camera and pinches the picture off
-- the lens, shows you it is only a crayon drawing of the winners, crumples it and tosses it over the shoulder without
-- looking. The body only: the sheet at the lens, the poster, the ball and the hand that grows on its way to the lens
-- are the module's (src/client/emotes/FoldItUp.luau). Faces cannot act (Alan): the feeling is in the head and hands.
-- Posed by numbers on Toy Pilot's standing pose (P.fly at P.held; both feet stay where they stand), A+'s way. The
-- video's beats, at the game's pace (it leaves 10.4 s after 1st's light; the video ran 1.3 times slower). Seconds
-- after 1st's light (FU):
-- * 0 to rub: the head tilts to one side looking at the camera (TILT), then slowly to the other, sizing you up;
-- * rub to reach: the hands together in front of the belly, rubbing (RUB: the right palm up and down the left);
-- * reach to pinch: the right arm straight at the camera at face height, fast; the chest leans in (LEAN);
-- * pinch to back: yanked back to the chest (the mark Back: the sheet is in the hand);
-- * back to show: both hands to the poster's sides; it turns round (the module) and is held out at the chest;
--   one small head tilt at it (nod);
-- * crumple to ball: the hands work round each other in front of the chest (SCRUNCH); the ball ends in the right hand;
-- * wind to release: the right hand low in front, then up and back over the right shoulder (the mark Release: the ball
--   leaves the hand), the head facing front: no look;
-- * dust to dusted: the palms meet at the belly and the right brushes up the left twice;
-- * fold on: arms folded, chin up (CHIN), the weight on the right leg (SHIFT, HIP).
-- ARM: each pose's hands from the middle of the shoulders and its elbows' pull, in winner heights { to the kid's right,
-- up, back } (forwards, at the camera, is negative); "hang" is the arms down at the sides.
local FU = { tilt = 1.0, rub = 2.0, rubbed = 3.0, reach = 3.0, pinch = 3.3, back = 3.8, take = 4.1, show = 4.5, nod = 5.6,
	crumple = 6.6, ball = 7.6, wind = 7.8, release = 8.15, through = 8.35, dust = 8.7, dusted = 9.4, fold = 9.6, folded = 10.0, length = 11 }
FU.marks = { Pinch = FU.pinch, Back = FU.back, Show = FU.show, Crumple = FU.crumple, Ball = FU.ball, Release = FU.release }
local TILT, LEAN, CHIN, NOD, SHIFT, HIP = 14, 8, 8, 8, 0.03, 5
local ARMS = { { 0, "hang" }, { 1.9, "hang" }, { FU.rub, "rub" }, { FU.rubbed, "rub" }, { FU.pinch, "reach" }, { FU.back, "chest" }, { FU.take, "hold" },
	{ FU.crumple, "hold" }, { FU.crumple + 0.3, "scrunch" }, { FU.ball, "scrunch" }, { FU.wind, "low" }, { FU.release, "toss" }, { FU.through, "over" }, { 8.55, "side" },
	{ FU.dust, "palms" }, { FU.dusted, "palms" }, { FU.folded, "fold" } }
local ARM = {
	hang = { Right = { V(0.2, -0.42, -0.02), V(1, -0.1, 0.4) }, Left = { V(-0.2, -0.42, -0.02), V(-1, -0.1, 0.4) } },
	rub = { Right = { V(0.02, -0.28, -0.21), V(1, -1, 0.3) }, Left = { V(-0.02, -0.28, -0.21), V(-1, -1, 0.3) } },
	reach = { Right = { V(0.13, 0.06, -0.46), V(1, -0.6, 0) }, Left = { V(-0.2, -0.4, -0.04), V(-1, -0.1, 0.4) } }, -- straight at the lens
	chest = { Right = { V(0.08, -0.18, -0.18), V(1, -0.8, 0.2) }, Left = { V(-0.2, -0.38, -0.06), V(-1, -0.2, 0.4) } },
	hold = { Right = { V(0.26, -0.25, -0.26), V(1, -0.6, 0.3) }, Left = { V(-0.26, -0.25, -0.26), V(-1, -0.6, 0.3) } }, -- the poster's sides
	scrunch = { Right = { V(0.05, -0.18, -0.22), V(1, -0.8, 0.2) }, Left = { V(-0.05, -0.18, -0.22), V(-1, -0.8, 0.2) } },
	low = { Right = { V(0.1, -0.28, -0.2), V(1, -0.8, 0.3) }, Left = { V(-0.2, -0.4, -0.04), V(-1, -0.1, 0.4) } },
	toss = { Right = { V(0.2, 0.22, -0.02), V(1, 0.2, 0.3) }, Left = { V(-0.2, -0.4, -0.04), V(-1, -0.1, 0.4) } }, -- up past the shoulder
	over = { Right = { V(0.2, 0.2, 0.1), V(1, 0.4, 0.4) }, Left = { V(-0.2, -0.4, -0.04), V(-1, -0.1, 0.4) } }, -- and back over it
	side = { Right = { V(0.3, -0.18, -0.06), V(1, -0.3, 0.3) }, Left = { V(-0.2, -0.4, -0.04), V(-1, -0.1, 0.4) } }, -- down round the outside, not through the chest
	palms = { Right = { V(0.03, -0.25, -0.2), V(1, -1, 0.3) }, Left = { V(-0.03, -0.25, -0.2), V(-1, -1, 0.3) } },
}
local FOLD_UPPER = { over = V(-0.1, -0.75, -0.65), under = V(-0.08, -0.8, -0.55) } -- Skeet Shoot's crossed arms, the upper arms more down: a real fold (elbows near 90 degrees)
local FOLD_FORE = { over = V(-1, 0.3, 0.1), under = V(-1, 0.2, 0.15) } -- the hands up towards the other arm, as folded arms tuck
-- the right palm along the left, heights up: rubbing (four strokes) and dusting (two)
local RUB = { { FU.rub + 0.2, 0 } }
for k = 1, 4 do table.insert(RUB, { FU.rub + 0.2 + k * 0.18 - 0.09, 0.035 }); table.insert(RUB, { FU.rub + 0.2 + k * 0.18, 0 }) end
local DUST = { { FU.dust + 0.1, 0 }, { FU.dust + 0.25, 0.05 }, { FU.dust + 0.4, 0 }, { FU.dust + 0.55, 0.05 }, { FU.dust + 0.7, 0 } }
-- crumpling: each hand round a little circle in front of the chest, opposite ways (heights)
local SCRUNCH_R, SCRUNCH_TURNS = 0.03, 3
local ROLL = { { 0, 0 }, { 0.2, 0 }, { FU.tilt, TILT }, { 1.3, TILT }, { FU.rub, -TILT }, { 2.3, -TILT }, { 2.7, 0 }, { FU.nod - 0.3, 0 }, { FU.nod, 6 }, { FU.nod + 0.5, 0 } } -- head roll, degrees, to the kid's right
local DOWN = { { 0, 0 }, { FU.rub + 0.1, 0 }, { FU.rub + 0.4, 15 }, { FU.rubbed, 15 }, { FU.pinch, -4 }, { FU.back, 0 }, { FU.show, 5 }, { FU.nod, NOD + 5 }, { FU.nod + 0.5, 5 },
	{ FU.crumple, 25 }, { FU.ball, 25 }, { FU.wind, 0 }, { FU.dust, 0 }, { FU.dust + 0.2, 20 }, { FU.dusted, 20 }, { FU.folded, -CHIN } } -- head down, degrees
local LEANS = { { 0, 0 }, { FU.rubbed, 0 }, { FU.pinch, 1 }, { FU.back, -0.4 }, { FU.take, 0 } } -- the chest towards the camera, of LEAN
local TWISTS = { { 0, 0 }, { FU.wind, 0 }, { FU.release, -12 }, { FU.through, -15 }, { FU.dust, 0 } } -- the chest's turn, degrees to the kid's left
local WEIGHT = { { FU.fold, 0 }, { FU.folded, 1 } }
function FU.pose(t, c)
	local body = standing(c)
	local turn = table.clone(body.base)
	for _, side in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[side .. part] = CFrame.identity end
	end
	local weight, yaw = keyed(WEIGHT, t), math.rad(keyed(TWISTS, t))
	turn.LowerTorso = CFrame.new(V(SHIFT * weight, 0, 0) * HEIGHT) * turn.LowerTorso * CFrame.Angles(0, 0, math.rad(HIP * weight))
	turn.UpperTorso *= CFrame.Angles(-math.rad(LEAN * keyed(LEANS, t)), yaw, -math.rad(HIP * weight))
	-- the arms
	local i = 1
	while i < #ARMS - 1 and ARMS[i + 1][1] <= t do i += 1 end
	local from, to = ARMS[i], ARMS[i + 1]
	local s = eased((t - from[1]) / (to[1] - from[1]))
	local at = build(turn)
	local mid = ((at.UpperTorso * joints.RightUpperArm.c0).Position + (at.UpperTorso * joints.LeftUpperArm.c0).Position) / 2
	local chest = at.UpperTorso.Rotation
	local spin = math.clamp((t - FU.crumple - 0.3) / (FU.ball - FU.crumple - 0.3), 0, 1) * SCRUNCH_TURNS * 2 * math.pi
	for _, side in { "Left", "Right" } do
		local sign = side == "Left" and -1 or 1
		local shoulder = (at.UpperTorso * joints[side .. "UpperArm"].c0).Position
		local function arm(name)
			if name == "fold" then
				-- folded arms (Alan 2026-11-22 on the first run: "they're just crossing their elbows and their arms are
				-- remaining straight ... not actually folding their arms under each other"): Skeet Shoot's way, the elbow
				-- placed (the upper arm down and forward, FOLD_UPPER) and the forearm folded straight across from it
				-- (FOLD_FORE); the right arm over and in front, the left tucked under it
				local over = sign > 0
				local elbowAt = (at[side .. "UpperArm"] * joints[side .. "LowerArm"].c0).Position
				local upper, lower = (elbowAt - shoulder).Magnitude, (at[side .. "Hand"].Position - elbowAt).Magnitude
				local u, f = FOLD_UPPER[over and "over" or "under"], FOLD_FORE[over and "over" or "under"]
				local elbow = shoulder + chest * V(sign * u.X, u.Y, u.Z).Unit * upper
				return elbow + chest * V(sign * f.X, f.Y, f.Z).Unit * lower, elbow
			end
			local p = ARM[name][side]
			local hand = mid + chest * p[1] * HEIGHT
			if side == "Right" and (name == "rub" or name == "palms") then hand += chest * V(0, keyed(name == "rub" and RUB or DUST, t), 0) * HEIGHT end
			if name == "scrunch" then hand += chest * V(math.cos(spin * sign), math.sin(spin * sign), 0) * SCRUNCH_R * HEIGHT end
			return hand, shoulder + chest * p[2] * body.arm
		end
		local hand0, elbow0 = arm(from[2])
		local hand1, elbow1 = arm(to[2])
		local v0, v1 = hand0 - shoulder, hand1 - shoulder
		local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
		local straight = side == "Right" and to[2] == "reach" and 0.99 or to[2] == "fold" and 1 or 0.97 -- the reach nearly straight: only the hand shows; folded exactly as placed
		reach(turn, side, shoulder + CFrame.fromAxisAngle(axis, angle * s) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * s), elbow0:Lerp(elbow1, s), false, straight)
	end
	-- the head: square to the camera, rolled and bowed by ROLL and DOWN, the chest's twist undone (it does not look round)
	at = build(turn)
	local neck = at.UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * CFrame.Angles(-math.rad(keyed(DOWN, t)), 0, -math.rad(keyed(ROLL, t))) * joints.Head.c1.Rotation
	for name, stand in body.feet do
		reach(turn, name, stand.ankle, stand.knee, true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * stand.foot * joints[name .. "Foot"].c1.Rotation
	end
	return turn
end
CUTS.FoldItUp = { length = FU.length, once = true, marks = FU.marks, clips = { fly = P.fly }, pose = FU.pose }
_G.FOLD_IT_UP = FU -- for the number checks (emote_preview.py --run)
