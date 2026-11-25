-- Test Flight (docs/workshop/emotes/test-flight.md; card OK'd by Alan 2026-11-24: "they should be sitting"; the
-- reference video .planning/emotes/test-flight-gemini-api-1.mp4 OK'd with the glance at 1st added: "you're going to
-- have to add the glance"). A runner-up, "Whatever. I've still got the best plane": sitting cross-legged, a lazy
-- flick sends a tiny plane out to the side away from 1st; it loops and glides back to the waiting hand; three flights,
-- the last a slow circle round the back of the head; then the plane held up. Loose and unhurried: the head follows
-- the plane the whole way, the catch takes no effort, a small nod after each.
-- Two clips, mirror images: TestFlightLeft throws with the left hand out to the kid's own left (1st on their right,
-- the picture's left), TestFlightRight the other way. Played once, 12 s; clip second 1.0 is 1st's light (the module,
-- src/client/emotes/TestFlight.luau, sets the clip's time each frame).
-- The body is generated clip Nap B sitting still (Nap's N.rest, cross-legged, hands on the knees); the throwing arm
-- and the head are by numbers below. Places are in body heights from the root, as { out (to the throwing side), up,
-- fwd (towards the camera) }.
-- The plane is the module's: TF.FLIGHTS (the same numbers as the module's FLIGHTS) are its three paths, here only for
-- the head to follow. Each flight: { release, catch, keys }, keys { seconds after the release, place }, a smooth line
-- through them (keyed's Catmull-Rom); the first place is the hand at the toss, the last the waiting hand.
local TF = { length = 12 }
TF.HOLD, TF.COCK, TF.TOSS, TF.WAIT, TF.SHOW = V(0.18, -0.22, 0.18), V(0.30, -0.34, 0.13), V(0.42, -0.20, 0.08), V(0.36, -0.30, 0.10), V(0.30, -0.02, 0.12)
local LOOP = { { 0, TF.TOSS }, { 0.22, V(0.44, -0.03, 0.04) }, { 0.45, V(0.45, 0.13, 0.00) }, { 0.675, V(0.64, 0.32, -0.02) },
	{ 0.9, V(0.45, 0.51, -0.02) }, { 1.125, V(0.26, 0.32, -0.02) }, { 1.35, V(0.45, 0.13, -0.03) }, { 1.6, V(0.63, 0.02, -0.12) },
	{ 1.85, V(0.54, -0.16, -0.06) }, { 2.1, TF.WAIT } }
-- The ring round the head: RING_R across, centred RING_UP over the root and RING_BACK behind; tilted RING_TILT, low
-- behind the head and high over the front of it (it passes over the forehead, never in front of the face).
local RING_R, RING_UP, RING_BACK, RING_TILT = 0.38, 0.16, 0.03, 0.08
local RING = { { 0, TF.TOSS }, { 0.35, V(0.48, 0.06, 0.00) } }
for k = 0, 8 do
	local a = k / 8 * 2 * math.pi
	table.insert(RING, { 0.55 + k * 0.18, V(RING_R * math.cos(a), RING_UP - RING_TILT * math.sin(a), -RING_BACK - RING_R * math.sin(a)) })
end
table.insert(RING, { 2.2, V(0.46, -0.10, 0.02) })
table.insert(RING, { 2.4, TF.WAIT })
TF.FLIGHTS = { { 2.2, 4.3, LOOP }, { 5.3, 7.4, LOOP }, { 8.1, 10.5, RING } }
TF.marks = { Glance = 1.0, Release1 = 2.2, Catch1 = 4.3, Release2 = 5.3, Catch2 = 7.4, Release3 = 8.1, Catch3 = 10.5, Show = 11.0 }
-- The throwing hand: looked over (a small rock), a lazy flick (cocked in, tossed out), waiting open beside the body,
-- held up at the end.
TF.HAND = { { 0, TF.HOLD }, { 1.7, TF.HOLD }, { 1.95, TF.COCK }, { 2.2, TF.TOSS }, { 2.5, TF.WAIT }, { 4.85, TF.WAIT }, { 5.05, TF.COCK },
	{ 5.3, TF.TOSS }, { 5.6, TF.WAIT }, { 7.6, TF.WAIT }, { 7.85, TF.COCK }, { 8.1, TF.TOSS }, { 8.4, TF.WAIT }, { 10.5, TF.WAIT },
	{ 11.0, TF.SHOW }, { 12, TF.SHOW } }
TF.ELBOW = V(0.25, -0.25, -0.05) -- where the elbow points, from the shoulder
-- The head: FOLLOW of the way to looking at the plane (no more than LOOK_TURN to the side, LOOK_DOWN down, LOOK_UP up;
-- a plane behind the head is looked at as if LOOK_NEAR in front: the head swings across as it passes); the glance at
-- 1st (GLANCE degrees, from 1st's light); a NOD after each catch; the chest turns CHEST of the head's turn.
local FOLLOW, LOOK_TURN, LOOK_DOWN, LOOK_UP, LOOK_NEAR, GLANCE, NOD, CHEST = 0.85, 75, 35, 40, 0.4, 50, 12, 0.2
local GLANCE_KEYS = { { 1.0, 0 }, { 1.4, 1 }, { 1.6, 1 }, { 2.0, 0 } }

-- A place { out, up, fwd } in the root's frame (forwards -Z, the kid's right +X); `s` 1 throws to the kid's left.
local function place(s, o) return V(-s * o.X, o.Y, -o.Z) * HEIGHT end
-- Where the plane is at `t` (clip seconds): in a flight, on its path; else in the hand (nil).
function TF.plane(t, s)
	for _, f in TF.FLIGHTS do
		if t >= f[1] and t < f[2] then return place(s, keyed(f[3], t - f[1], true)) end
	end
	return nil
end
local tf -- this body's numbers, worked out once
function TF.reset() tf = nil end
local function look(turn, dir, nod)
	local neck = build(turn).UpperTorso * joints.Head.c0
	turn.Head = neck.Rotation:Inverse() * (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(-math.rad(nod), 0, 0)).Rotation * joints.Head.c1.Rotation
end
function TF.pose(t, c, s)
	tf = tf or { base = c.nap(N.rest) }
	local side = s == 1 and "Left" or "Right"
	local turn = table.clone(tf.base)
	local at = build(turn)
	local hand = place(s, keyed(TF.HAND, t))
	if t < 1.7 then hand += place(s, V(0.015 * math.sin(t / 1.3 * 2 * math.pi), 0.01 * math.sin(t / 0.9 * 2 * math.pi), 0)) end
	-- what the head follows: the plane in flight, else the hand that holds it
	local d = (TF.plane(t, s) or hand) - at.Head.Position
	local ahead = math.max(-d.Z, LOOK_NEAR * HEIGHT)
	local yaw = math.clamp(math.deg(math.atan2(d.X, ahead)), -LOOK_TURN, LOOK_TURN) * FOLLOW
	local pitch = math.clamp(math.deg(math.atan2(d.Y, math.sqrt(d.X * d.X + ahead * ahead))), -LOOK_DOWN, LOOK_UP) * FOLLOW
	local g = keyed(GLANCE_KEYS, t)
	yaw, pitch = yaw * (1 - g) + s * GLANCE * g, pitch * (1 - g)
	local nod = 0
	for _, f in TF.FLIGHTS do
		local u = t - f[2] - 0.05
		if u > 0 and u < 0.5 then nod = NOD * math.sin(u / 0.5 * math.pi) end
	end
	turn.UpperTorso = tf.base.UpperTorso * CFrame.Angles(0, -math.rad(CHEST * yaw), 0)
	local shoulder = (build(turn).UpperTorso * joints[side .. "UpperArm"].c0).Position
	reach(turn, side, hand, shoulder + place(s, TF.ELBOW))
	local y, p = math.rad(yaw), math.rad(pitch)
	look(turn, V(math.sin(y) * math.cos(p), math.sin(p), -math.cos(y) * math.cos(p)), nod)
	return turn
end
CUTS.TestFlightLeft = { length = TF.length, once = true, marks = TF.marks, clips = { nap = N.clip }, pose = function(t, c) return TF.pose(t, c, 1) end }
CUTS.TestFlightRight = { length = TF.length, once = true, marks = TF.marks, clips = { nap = N.clip }, pose = function(t, c) return TF.pose(t, c, -1) end }
_G.TEST_FLIGHT = TF -- for the number checks (emote_preview.py --run)
