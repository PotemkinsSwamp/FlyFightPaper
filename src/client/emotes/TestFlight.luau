-- Test Flight, a runner-up emote (docs/workshop/emotes/test-flight.md; card and reference video OK'd by Alan
-- 2026-11-24): sitting cross-legged on the books, the kid looks over their paper plane, glances at 1st when 1st's light
-- clicks on, and flicks the plane out to the side away from 1st; it loops and glides back to the waiting hand, twice;
-- the third time it circles round the head; then the plane is held up.
-- The body is one of two clips (tools/emote_cuts/test-flight.lua), mirror images: TestFlightLeft throws with the left
-- hand to the kid's own left (1st on the picture's left), TestFlightRight the other way. Its time is set here every
-- frame, so clip second 1.0 (the glance) is 1st's light; 3rd holds the glance HOLD_3RD longer, so if 2nd and 3rd both
-- play it they are out of step.
-- The plane: their own plane at the size of every other emote's (holdPlane's own: Alan in Play 2026-11-24, a tenth of
-- the height was "extremely small"). Held, it is fixed to the hand: the tail at the grip point (RightGripAttachment /
-- LeftGripAttachment), nose along the forearm (Alan 2026-11-21: "It has to be touching the hand"). In flight it follows
-- FLIGHTS, the clip's own paths (the same numbers as TF.FLIGHTS in the cut: change both), in the kid's own frame and
-- height; it leaves from where the hand let go of it and, over the last HOME seconds, steers to where this body's hand
-- really holds it, so it lands in the hand on every body. The circle round the head is centred on this body's own head.
-- One rigid paper plane: the nose follows the path and the top is carried along with the nose from frame to frame,
-- turned only as much as the nose turns (no roll of its own: Alan in Play 2026-11-24 saw it "flap its wings like it was
-- a butterfly", when its top was aimed by the path's bends, which jump at every key). So it goes over on its back
-- through a loop and stays level round a flat turn; in the hand its top is drawn back up a little each frame (LEVEL).
-- The sound: the reference video's plane whoosh (Alan: "you can use the little whooshing sound of the plane"), quietly
-- at each release, as a runner-up's sound (cut if 1st's own sounds come first). It plays once "testFlightWhoosh" is
-- in Audio.
local TestFlight = {}
local LENGTH, GLANCE, HOLD_3RD = 12, 1.0, 0.3
local HOME, LEAVE, SETTLE, LEVEL = 0.7, 0.4, 0.25, 0.06 -- seconds to steer home, to leave the toss's line, to turn into the hand; a share a frame
local V = Vector3.new
-- { release, catch, keys }: keys { seconds after the release, { out (to the throwing side), up, fwd (to the camera) } }
-- in standing heights from the root; the first is the toss, the last the waiting hand.
local TOSS, WAIT = V(0.42, -0.20, 0.08), V(0.36, -0.30, 0.10)
local LOOP = { { 0, TOSS }, { 0.22, V(0.44, -0.03, 0.04) }, { 0.45, V(0.45, 0.13, 0.00) }, { 0.675, V(0.64, 0.32, -0.02) },
	{ 0.9, V(0.45, 0.51, -0.02) }, { 1.125, V(0.26, 0.32, -0.02) }, { 1.35, V(0.45, 0.13, -0.03) }, { 1.6, V(0.63, 0.02, -0.12) },
	{ 1.85, V(0.54, -0.16, -0.06) }, { 2.1, WAIT } }
local RING_R, RING_UP, RING_BACK, RING_TILT = 0.38, 0.16, 0.03, 0.08
local HEAD = V(0, -0.043, -0.018) -- the test kid's head from the root, sitting (the ring is moved by this body's own)
local RING = { { 0, TOSS }, { 0.35, V(0.48, 0.06, 0.00) } }
for k = 0, 8 do
	local a = k / 8 * 2 * math.pi
	table.insert(RING, { 0.55 + k * 0.18, V(RING_R * math.cos(a), RING_UP - RING_TILT * math.sin(a), -RING_BACK - RING_R * math.sin(a)), true })
end
table.insert(RING, { 2.2, V(0.46, -0.10, 0.02) })
table.insert(RING, { 2.4, WAIT })
local FLIGHTS = { { 2.2, 4.3, LOOP }, { 5.3, 7.4, LOOP }, { 8.1, 10.5, RING } }
TestFlight.sounds = { { "testFlightWhoosh", FLIGHTS[1][1] }, { "testFlightWhoosh", FLIGHTS[2][1] }, { "testFlightWhoosh", FLIGHTS[3][1] } } -- clip seconds

local function eased(v) v = math.clamp(v, 0, 1); return v * v * (3 - 2 * v) end
-- The smooth line through a flight's keys at `u` seconds (Catmull-Rom, as the cut's `keyed`).
local function along(keys, u)
	local i = 1
	while i < #keys - 1 and keys[i + 1][1] <= u do i += 1 end
	local function row(k) return keys[math.clamp(k, 1, #keys)][2] end
	local b, c = keys[i], keys[i + 1]
	local s = math.clamp((u - b[1]) / (c[1] - b[1]), 0, 1)
	local a, d = row(i - 1), row(i + 2)
	return b[2] + 0.5 * s * (c[2] - a + s * (2 * a - 5 * b[2] + 4 * c[2] - d + s * (3 * (b[2] - c[2]) + d - a)))
end

local function track(who, kit, side)
	local id = (kit.ourClip("TestFlight" .. side))
	if not id then return nil end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local made = who.animator:LoadAnimation(animation)
	made.Looped, made.Priority = false, Enum.AnimationPriority.Action
	return made
end

function TestFlight.start(kit, who)
	local st = { kit = kit, who = who, seat = kit.seatOn(who.cast, who.top), clip = track(who, kit, "Left"), heard = {},
		h = kit.Avatars.standing_height_studs / who.scale }
	if st.clip then st.clip:Play(0, 1, 0) end -- the clip's first pose from the dark on; which side is known at the first step
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true -- the time is set every frame below
	local prop = kit.holdPlane(who.model, who.actorId) -- the size every emote's plane is
	if prop then
		st.plane, st.length = prop.plane, prop.length
		st.plane.Name = "TestFlightPlane"
		st.plane:PivotTo(who.model:GetPivot()) -- out of the room until the first step puts it in the hand
		st.plane.Parent = who.cast
	end
	return st
end

-- This kid's clip time `first` seconds after 1st's light.
local function clipTime(place, first)
	if place == 3 then
		local after = first - 0.6 -- the glance has landed (clip 1.6)
		return after < 0 and first + 1 or after < HOLD_3RD and 1.6 or 1.6 + after - HOLD_3RD
	end
	return first + 1
end

-- The shortest turn that takes one direction to another.
local function arc(from, to)
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-6 then -- the same way, or straight back: about any side
		return from:Dot(to) > 0 and CFrame.identity or CFrame.fromAxisAngle((math.abs(from.Y) < 0.9 and Vector3.yAxis or Vector3.xAxis):Cross(from).Unit, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.atan2(axis.Magnitude, from:Dot(to)))
end

-- Where the hand holds it: the forearm's way, and the middle of the plane (held by the tail, as Toy Pilot's).
local function held(st)
	local nose = (st.grip.WorldPosition - st.arm.Position).Unit
	return st.grip.WorldPosition + nose * st.length * 0.3, nose
end

-- A flight's place at `u` seconds after its release, in the world: the clip's path in this kid's frame, from where it
-- left the hand and steered home to where the hand holds it now.
local function flown(st, f, u, hand)
	local root, s = st.root.CFrame, st.out
	local function world(o) return root.Position + (s * o.X + Vector3.yAxis * o.Y + root.LookVector * o.Z) * st.h end
	local keys = f[3]
	local o = along(keys, u)
	if keys == RING then -- round this body's own head
		local head = root:PointToObjectSpace(st.head.Position) / st.h
		local mine = V(s:Dot(root.RightVector) * head.X, head.Y, -head.Z)
		o += (mine - HEAD) * eased(u / keys[3][1]) * (1 - eased((u - keys[#keys - 2][1]) / (keys[#keys][1] - keys[#keys - 2][1])))
	end
	local p = world(o)
	p += (st.from - world(keys[1][2])) * (1 - eased(u / LEAVE))
	local last = f[2] - f[1]
	return p + (hand - world(keys[#keys][2])) * eased((u - (last - HOME)) / HOME)
end

function TestFlight.step(st, since, _shot, steady, winners)
	local who = st.who
	local model = who.model
	if not st.side then
		local me, top = winners[who.place], winners[1]
		-- away from 1st: 1st on the picture's left, so out to the picture's right, the kid's own left
		st.side = (me and top and me ~= top and (top.spot - me.spot):Dot(steady.RightVector) > 0) and "Right" or "Left"
		if st.side == "Right" then
			local right = track(who, st.kit, "Right")
			if right then
				if st.clip then st.clip:Stop(0) end
				st.clip = right
				right:Play(0, 1, 0)
			end
		end
		local hand = model:FindFirstChild(st.side .. "Hand")
		st.grip, st.arm = hand and hand:FindFirstChild(st.side .. "GripAttachment"), model:FindFirstChild(st.side .. "LowerArm")
		st.root, st.head = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChild("Head")
	end
	local first = winners[1] and winners[1].since or since - (who.place - 1)
	local t = math.clamp(clipTime(who.place, first), 0, LENGTH - 0.01)
	st.t = t
	if st.clip then st.clip.TimePosition = t end
	st.kit.sit(model, st.seat)
	for i, s in TestFlight.sounds do
		if not st.heard[i] and t >= s[2] then
			st.heard[i] = true
			if t < s[2] + 0.3 then st.kit.runnerSound(s[1]) end
		end
	end
	if not (st.plane and st.grip and st.arm and st.root and st.head) then return end
	st.out = st.root.CFrame.RightVector * (st.side == "Left" and -1 or 1)
	local at, nose = held(st)
	local flying = false
	for _, f in FLIGHTS do
		local u = t - f[1]
		if u >= 0 and t < f[2] then
			if st.flying ~= f then st.flying, st.from = f, at end -- it leaves from where the hand let go
			local p = flown(st, f, u, at)
			local d = 0.03
			local ahead, behind = flown(st, f, math.min(u + d, f[2] - f[1]), at), flown(st, f, math.max(u - d, 0), at)
			local heading = (ahead - behind).Magnitude > 1e-4 and (ahead - behind).Unit or nose
			-- out of the hand's line, and back into it at the catch
			local w = math.min(eased(u / 0.1), 1 - eased((u - (f[2] - f[1] - SETTLE)) / SETTLE))
			local axis, angle = arc(nose, heading):ToAxisAngle() -- turned round, never through a straight mix (which can flip)
			nose = CFrame.fromAxisAngle(axis, angle * w) * nose
			at, flying = p, true
			break
		end
	end
	-- the top carried along with the nose (no roll of its own); in the hand, drawn back up
	local up = st.nose and arc(st.nose, nose) * st.up or Vector3.yAxis
	if not flying then
		local level = Vector3.yAxis - nose * nose.Y
		if level.Magnitude > 0.05 then up = up:Lerp(level.Unit, st.nose and LEVEL or 1) end -- the first frame: level at once
	end
	up -= nose * up:Dot(nose)
	up = up.Magnitude > 1e-4 and up.Unit or (st.up or Vector3.yAxis)
	st.nose, st.up = nose, up
	st.plane:PivotTo(CFrame.lookAt(at, at + nose, up))
end

return TestFlight
