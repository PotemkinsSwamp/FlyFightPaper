-- Sneaky Toss, a runner-up emote (docs/workshop/emotes/sneaky-toss.md; card OK'd by Alan 2026-11-24 with no whistling,
-- neither sound nor look; the second reference video .planning/emotes/sneaky-toss-gemini-api-2.mp4 "good enough to
-- work with" for the throw, the innocence built by hand: "There's no rocking on the heels or quick shifty glancing ...
-- that's something that you are going to have to fix"). The feeling: "Heh. Wasn't me." Sly and slow before, one
-- snappy overarm throw, then a show of innocence with the whole body that fools nobody.
-- Two clips, mirror images: SneakyTossLeft throws towards the kid's own left (1st on the picture's right),
-- SneakyTossRight towards their right, with the hand on 1st's side. Played once, 12 s, in the video's seconds: clip
-- second 1 is 1st's light (src/client/emotes/SneakyToss.luau sets the time every frame). The ball is the module's
-- (on the hand until Release, then its own flight behind 1st).
-- The body is Toy Pilot's standing pose (`standing`: P.fly at P.held, feet apart). By numbers, in clip seconds:
-- * hands clasped behind the back from the dark on, both (the throwing hand comes out from Out to Back);
-- * Look: a slow sly look at 1st (LOOK), the chest a little forward (HUNCH);
-- * Out: the throwing hand round the side to in front of the belly, the ball on it; Toss to Catch one bounce
--   (the hand flicks up, the ball's flight is the module's, the hand gives on the catch);
-- * the throw (Alan: "an actual throw", the video's overarm): the hand cocked up beside the head with the elbow high
--   and the chest wound away (to Cock), whipped forward and up towards 1st (Release), followed through down and
--   across, then straight back behind the back (Back);
-- * Away: the face up and away from 1st; from there to the end the innocence: ROCK (onto the toes, the heels up,
--   then back onto the heels, the toes up; the hips ride up with the ankles, the body leans a little with it; every
--   ROCK_EVERY seconds) and the head tilting slowly side to side (TILT every TILT_EVERY seconds), both faded down
--   while it looks at 1st;
-- * Glance and Glance2: quick shifty head snaps to 1st and back (SNAP seconds each way, held HOLD); Peek: one longer
--   look, the shoulders shaking once (a held-back snigger: SNIGGER), then innocent again.
-- Places are in the root's frame (forwards -Z, the kid's right +X), `dir` 1 towards the kid's own right.
local ST = { length = 12, ROCK_EVERY = 1.1, TOE = 25, HEEL = 15, LEAN = 4, TILT = 11, TILT_EVERY = 2.6, HUNCH = 5, SNAP = 0.12, HOLD = 0.25 }
ST.marks = { Look = 1.0, Out = 2.0, Toss = 2.62, Catch = 2.9, Cock = 3.32, Release = 3.44, Back = 4.05, Away = 3.85, Glance = 7.1, Glance2 = 7.85, Peek = 8.5, Peeked = 9.7 }
local M = ST.marks
-- The throwing arm: which pose when, eased from one to the next round the shoulder.
local ARMS = { { 0, "back" }, { M.Out, "back" }, { 2.2, "side" }, { 2.45, "palm" }, { 2.55, "palm" }, { M.Toss, "toss" }, { 2.72, "palm" },
	{ M.Catch, "palm" }, { 2.95, "dip" }, { 3.0, "palm" }, { M.Cock, "cock" }, { M.Release, "throw" }, { 3.62, "follow" }, { 3.84, "side" }, { M.Back, "back" } }
-- The chest: turned towards 1st (degrees, + towards 1st) and pitched forward, on the throw.
local YAW = { { 3.0, 0 }, { M.Cock, -14 }, { M.Release, 14 }, { 3.7, 6 }, { 4.2, 0 } }
local PITCH = { { 1.0, 0 }, { 1.6, ST.HUNCH }, { 3.0, ST.HUNCH }, { M.Cock, -4 }, { M.Release, 7 }, { 3.8, 1 }, { 4.3, 0 } }
-- Where the head looks: ahead, at 1st (sly: a little down), after the ball, away (up and to the other side), and the
-- shifty snaps (level, at 1st). Vectors with x towards 1st.
local F, AT, SNAPPED, BALL, AWAY = V(0, 0, -1), V(0.64, -0.08, -0.77), V(0.72, 0, -0.7), V(0.75, 0.3, -0.6), V(-0.5, 0.32, -0.8)
local S, H = ST.SNAP, ST.HOLD
local LOOK = { { 0, F }, { M.Look, F }, { 1.6, AT }, { 3.36, AT }, { 3.5, BALL }, { 3.6, BALL }, { M.Away, AWAY },
	{ M.Glance, AWAY }, { M.Glance + S, SNAPPED }, { M.Glance + S + H, SNAPPED }, { M.Glance + 2 * S + H, AWAY },
	{ M.Glance2, AWAY }, { M.Glance2 + S, SNAPPED }, { M.Glance2 + S + H, SNAPPED }, { M.Glance2 + 2 * S + H, AWAY },
	{ M.Peek, AWAY }, { M.Peek + 0.25, AT }, { M.Peeked - 0.3, AT }, { M.Peeked, AWAY }, { ST.length, AWAY } }
-- How much of the rocking and the tilting shows (0 to 1).
local ROCKING = { { 4.2, 0 }, { 4.8, 1 }, { 6.9, 1 }, { 7.1, 0.35 }, { 8.3, 0.35 }, { M.Peek, 0 }, { M.Peeked - 0.1, 0 }, { 10.2, 1 } }
local TILTING = { { 4.2, 0 }, { 4.8, 1 }, { 6.95, 1 }, { 7.08, 0 }, { 8.4, 0 }, { M.Peeked - 0.1, 0 }, { 10.2, 1 } }
-- The snigger: the chest's extra pitch (degrees), three quick shakes, the head nodding with them.
local SNIGGER = { { 8.95, 0 }, { 9.02, 4 }, { 9.1, 0 }, { 9.17, 3.5 }, { 9.25, 0 }, { 9.32, 2.5 }, { 9.42, 0 } }

local function looked(turn, dir, nod, tilt)
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(-math.rad(nod), 0, math.rad(tilt))).Rotation * joints.Head.c1.Rotation
end
local function between(list, t)
	local i = 1
	while i < #list - 1 and list[i + 1][1] <= t do i += 1 end
	local from, to = list[i], list[math.min(i + 1, #list)]
	return from[2], to[2], to[1] > from[1] and eased((t - from[1]) / (to[1] - from[1])) or 0
end
-- One arm's hand and elbow pole for a named pose (`s` -1 left, 1 right).
local function stArm(name, s, at, body)
	local shoulder = (at.UpperTorso * joints[(s < 0 and "Left" or "Right") .. "UpperArm"].c0).Position
	local hips, hand = first.LowerTorso.Size, first.RightHand.Size
	local function out(x, y, z) return shoulder + V(s * x, y, z) * body.arm end
	if name == "back" then -- clasped behind the back: the hands meet just off the middle, behind the hips
		return at.LowerTorso * V(s * 0.12 * hips.X, 0.45 * hips.Y, 0.5 * hips.Z + 0.75 * hand.Z), out(1, -0.4, 0.9)
	elseif name == "side" then return out(0.45, -0.75, 0.05), out(1, -0.3, 0.4)
	elseif name == "palm" then return out(0.2, -0.72, -0.5), out(1, -0.7, 0.2)
	elseif name == "toss" then return out(0.2, -0.6, -0.55), out(1, -0.7, 0.2)
	elseif name == "dip" then return out(0.2, -0.8, -0.48), out(1, -0.7, 0.2)
	elseif name == "cock" then return out(0.35, 0.45, 0.45), out(1, 0.25, 0.5) -- beside the head, the elbow high
	elseif name == "throw" then return out(0.55, 0.5, -0.3), out(1, 0, -0.1) -- out towards 1st, not at the lens
	end
	return out(0.45, -0.3, -0.55), out(1, -0.6, 0.2) -- follow through
end
local function moveArm(turn, s, list, t, body)
	local at = build(turn)
	local shoulder = (at.UpperTorso * joints[(s < 0 and "Left" or "Right") .. "UpperArm"].c0).Position
	local a, b, k = between(list, t)
	local hand0, elbow0 = stArm(a, s, at, body)
	local hand1, elbow1 = stArm(b, s, at, body)
	local v0, v1 = hand0 - shoulder, hand1 - shoulder
	local axis, angle = arc(v0.Unit, v1.Unit):ToAxisAngle()
	-- the forearm starts bent forward, not straight on (with the elbow up high a straight forearm points almost the
	-- opposite way to the bent one wanted, and the forearm spun 85 degrees in a frame on the way to the cock)
	turn[(s < 0 and "Left" or "Right") .. "LowerArm"] = CFrame.Angles(math.rad(90), 0, 0)
	reach(turn, s < 0 and "Left" or "Right", shoulder + CFrame.fromAxisAngle(axis, angle * k) * v0.Unit * (v0.Magnitude + (v1.Magnitude - v0.Magnitude) * k), elbow0:Lerp(elbow1, k), false, 0.96)
end
-- A turn about the root frame's point `p` laid onto the hips' joint turn.
local function aboutPoint(turn, p, by)
	local c0 = joints.LowerTorso.c0
	turn.LowerTorso = c0:Inverse() * (CFrame.new(p) * by * CFrame.new(-p)) * c0 * turn.LowerTorso
end
function ST.pose(t, c, dir)
	local body = standing(c)
	if not body.boxes then
		local at = build(body.base)
		for name, stand in body.feet do stand.box = at[name .. "Foot"] end -- where each foot stands at rest
		body.boxes = true
	end
	local turn = table.clone(body.base)
	for _, side in { "Left", "Right" } do
		for _, part in { "UpperArm", "LowerArm", "Hand" } do turn[side .. part] = CFrame.identity end
	end
	-- the rock: + onto the toes (each foot turns about its toe, heel up), - back onto the heels (toes up)
	local wave = math.sin((t - 4.6) / ST.ROCK_EVERY * 2 * math.pi) * keyed(ROCKING, t)
	local tip = -math.rad(wave > 0 and ST.TOE * wave or ST.HEEL * wave) -- (about +X a turn the other way lifts what is behind)
	local footLong = first.LeftFoot.Size.Z
	local ankles, feet = {}, {}
	local rise = Vector3.zero
	for name, stand in body.feet do
		local pivot = stand.box * V(0, -0.5 * first.LeftFoot.Size.Y, (wave > 0 and -0.5 or 0.5) * footLong) -- the sole's toe or heel edge, on the book
		local spin = CFrame.fromAxisAngle(stand.box.RightVector, tip) -- about the foot's own across (the feet turn out a little)
		ankles[name] = pivot + spin * (stand.ankle - pivot)
		feet[name] = spin * stand.foot
		rise += (ankles[name] - stand.ankle) / 2
	end
	turn.LowerTorso = joints.LowerTorso.c0:Inverse() * CFrame.new(rise) * joints.LowerTorso.c0 * turn.LowerTorso
	local middle = (ankles.Left + ankles.Right) / 2
	aboutPoint(turn, middle, CFrame.fromAxisAngle(Vector3.xAxis, -math.rad(ST.LEAN) * wave))
	-- the chest: the hunch, the throw's wind and turn, the snigger, a slow breath
	turn.UpperTorso *= CFrame.Angles(-math.rad(keyed(PITCH, t) + keyed(SNIGGER, t) + 0.7 * math.sin(t / 3.3 * 2 * math.pi)), math.rad(dir * keyed(YAW, t)), 0)
	-- the head: where it looks, the tilt side to side, nodding with the snigger
	local look = keyed(LOOK, t)
	looked(turn, V(dir * look.X, look.Y, look.Z).Unit, keyed(SNIGGER, t) * 0.8, ST.TILT * math.sin((t - 4.3) / ST.TILT_EVERY * 2 * math.pi) * keyed(TILTING, t))
	-- the arms: the far one stays behind the back, the near one throws
	moveArm(turn, -dir, { { 0, "back" } }, t, body)
	moveArm(turn, dir, ARMS, t, body)
	for name, stand in body.feet do
		reach(turn, name, ankles[name], stand.knee + (ankles[name] - stand.ankle), true)
		local ankle = build(turn)[name .. "LowerLeg"] * joints[name .. "Foot"].c0
		turn[name .. "Foot"] = ankle.Rotation:Inverse() * feet[name] * joints[name .. "Foot"].c1.Rotation
	end
	return turn
end
CUTS.SneakyTossLeft = { length = ST.length, once = true, marks = ST.marks, clips = { fly = P.fly }, pose = function(t, c) return ST.pose(t, c, -1) end }
CUTS.SneakyTossRight = { length = ST.length, once = true, marks = ST.marks, clips = { fly = P.fly }, pose = function(t, c) return ST.pose(t, c, 1) end }
_G.SNEAKY = ST -- for the number checks (emote_preview.py --run)
