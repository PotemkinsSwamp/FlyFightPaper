-- Skeet Shoot, a 1st-place emote using all three winners (docs/workshop/emotes/skeet-shoot.md; card OK'd by Alan
-- 2026-11-22, both new mechanics too: the runner-ups' emotes pause while they throw, and the scene's planes are theirs).
-- 1st pulls a green soda straw from behind the back; the runner-up on 1st's own left (the picture's right) freezes, pulls
-- their own paper plane from behind their back and throws it up and across; 1st puffs a spitball at it; it sticks, the
-- plane tips over and spirals down out of the bottom of the picture; the same with the other runner-up, 1st not even
-- looking; the straw twirls, is tucked behind the back, the arms cross. The camera is not touched.
-- Bodies: 1st's clip SkeetShoot and the runner-ups' SkeetThrowRight / SkeetThrowLeft (tools/emote_cuts/skeet-shoot.lua),
-- the throw played over their own emote, which is held still (every playing track at speed 0, its speed kept and put
-- back at the throw's End): only the chest, head and left arm move, so a sitting kid throws sitting.
-- Places: each small winner stands in its own world, slid towards the camera by its own scale. A plane flies between
-- them, so its path is worked out in the big room (`big`) and drawn in its thrower's world (`small`): it looks the same
-- from the camera. The hit points are HIT_A / HIT_B (1st's frame, from the head, in winner heights: the cut's own).
-- Sounds (step 6 uploads them; until then Audio does not know the names and plays nothing): a puff and a tick on each
-- shot, cut from the reference video.
local SkeetShoot = {}
local MARKS = { Grab = 0.5, Mouth = 1.1, Shot1 = 2.7, Shot2 = 4.7, Off = 5.5, Twirl = 6.0, Twirled = 7.4, Tucked = 8.25 } -- the clip's own (its draft's attributes win)
local THROW = { Grab = 0.4, Release = 0.7, End = 1.05 } -- the throw clip's
local FIRST_AT, SECOND_AT = 1.5, 3.5 -- the runner-ups' throws start (seconds after 1st's light)
local HIT_A, HIT_B = Vector3.new(0.4, 0.3, -0.55), Vector3.new(-0.4, 0.3, -0.55)
local REST = Vector3.new(0.12, -0.3, -1) -- where the straw points while nothing is flying (1st's frame, from the head; the cut's)
local STRAW, GRIP, THICK, BALL = 0.3, 0.55, 0.022, 0.035 -- straw length, how far along it the hand holds it (at the mouth), width, spitball size (winner heights)
local AIM_RATE = 30 -- how fast the straw swings to a new target (a share a second, smoothed)
local FLY = 0.15 -- puff to hit
local TURNS = 3 -- the twirl, slowing to a stop at Twirled
local FALL, DRIFT, SPIN, NOSE_DOWN, GONE = 5, 0.3, 2, 70, 1.3 -- after a hit: heights a second squared down, heights a second on, turns a second, degrees, seconds until hidden
local GREEN, WHITE = Color3.fromRGB(60, 190, 80), Color3.new(1, 1, 1)
SkeetShoot.firstSound = FIRST_AT
SkeetShoot.sounds = { { "skeetShot", MARKS.Shot1 }, { "skeetShot", MARKS.Shot2 } }

local function big(w, p) return w.spot + (p - w.spot - w.shift) * w.scale end
local function small(w, b) return w.spot + w.shift + (b - w.spot) / w.scale end
local function load(animator, id, priority)
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	track.Looped, track.Priority = false, priority
	return track
end
local function shown(parts, on)
	for part, was in parts do part.Transparency = on and was or 1 end
end

function SkeetShoot.start(kit, who)
	local id, draft = kit.ourClip("SkeetShoot")
	local st = { kit = kit, who = who, marks = {}, h = kit.Avatars.standing_height_studs / who.scale, heard = {} }
	for name, at in MARKS do st.marks[name] = draft and draft:GetAttribute(name) or at end
	if id then
		st.track = load(who.animator, id, Enum.AnimationPriority.Action)
		st.track:Play(0, 1, 0) -- its first pose from the dark on; the scene sets it going at the light
	else
		st.track = { Play = function() end, AdjustSpeed = function() end }
	end
	st.held = true
	st.straw = kit.paper(who.cast, GREEN, Enum.PartType.Cylinder)
	st.straw.Name, st.straw.Size, st.straw.Transparency = "SkeetStraw", Vector3.new(STRAW, THICK, THICK) * st.h, 1
	return st
end

-- The runner-ups, once they stand: who throws first (the one on 1st's own left), their throw clip, their plane, hidden.
local function setUp(st, winners, steady)
	st.throws = {}
	local me = winners[1]
	for place = 2, 3 do
		local w = winners[place]
		if not (w and me and w.animator) then continue end
		local first = (me.spot - w.spot):Dot(steady.RightVector) < 0 -- 1st is on their picture-left: they are on the right
		local id = st.kit.ourClip(first and "SkeetThrowRight" or "SkeetThrowLeft")
		local r = { w = w, at = first and FIRST_AT or SECOND_AT, hit = first and HIT_A or HIT_B, shot = first and st.marks.Shot1 or st.marks.Shot2,
			track = id and load(w.animator, id, Enum.AnimationPriority.Action2), parts = {} }
		r.prop = st.kit.holdPlane(w.model, w.actorId)
		if r.prop then
			r.prop.plane.Parent = w.world:FindFirstChild("Cast") or w.world
			for _, part in r.prop.plane:GetDescendants() do
				if part:IsA("BasePart") and part.Transparency < 1 then
					r.parts[part] = part.Transparency
					table.insert(w.fading, part)
				end
			end
			shown(r.parts, false)
		end
		r.ball = st.kit.paper(st.who.cast, WHITE, Enum.PartType.Ball)
		r.ball.Name, r.ball.Size, r.ball.Transparency = "SkeetSpitball", Vector3.one * BALL * st.h, 1
		table.insert(st.throws, r)
	end
end

-- 1st's straw this frame; returns its tip. At the mouth it points along `aim` with the hand GRIP of the way from its near
-- end (on a plain kid that end is at the mouth); else it stands up out of the fist (spun about the forearm for the twirl).
local function placeStraw(st, since, aim)
	local m, model = st.marks, st.who.model
	local hand, arm = model:FindFirstChild("RightHand"), model:FindFirstChild("RightLowerArm")
	st.straw.Transparency = (since >= m.Grab and since < m.Tucked) and 0 or 1
	if not (hand and arm) then return nil end
	local length = STRAW * st.h
	local f = (hand.Position - arm.Position).Unit
	local up = Vector3.yAxis - f * f.Y
	up = up.Magnitude > 0.1 and up.Unit or hand.CFrame.LookVector
	local spun = st.kit.ease((since - m.Twirl) / (m.Twirled - m.Twirl))
	up = CFrame.fromAxisAngle(f, TURNS * 2 * math.pi * (1 - (1 - spun) ^ 2)) * up
	local w = math.clamp((since - (m.Mouth - 0.25)) / 0.25, 0, 1) * (1 - math.clamp((since - m.Off) / 0.3, 0, 1))
	local axis = up:Lerp(aim, w).Unit
	local middle = hand.Position + axis * (0.5 - GRIP) * length * w
	st.straw.CFrame = CFrame.lookAt(middle, middle + axis) * CFrame.Angles(0, math.pi / 2, 0) -- a cylinder lies along its X
	return middle + axis * length / 2
end

-- A runner-up's throw this frame: their emote held, the throw clip, their plane in the hand, flying, hit and falling.
local function throwStep(st, r, since, me, head, root)
	local w, t = r.w, since - r.at
	local tall = st.kit.Avatars.standing_height_studs -- one winner height, in the big room
	if t >= 0 and not r.frozen then
		r.frozen = {}
		for _, track in w.animator:GetPlayingAnimationTracks() do r.frozen[track] = track.Speed; track:AdjustSpeed(0) end
		if r.track then r.track:Play(0.2) end
	end
	if t >= THROW.End and r.frozen and not r.done then
		r.done = true
		if r.track then r.track:Stop(0.3) end
		for track, speed in r.frozen do track:AdjustSpeed(speed) end
	end
	-- the hit point, from 1st's head, taken once at the release (the head moves while aiming)
	local hit = r.hitPoint or big(me, head.Position + root.CFrame:VectorToWorldSpace(r.hit) * st.h)
	r.hitNow = hit
	local hitAt = r.shot + FLY
	local prop = r.prop
	if not prop or t < THROW.Grab or r.gone then return end
	local hand = prop.hand.Position
	local cf
	if t < THROW.Release then
		local heading = (hit - big(w, hand)).Unit
		local at = hand + heading * prop.length * 0.3 -- held by the tail
		cf = CFrame.lookAt(at, at + heading)
		r.now = big(w, at)
	else
		r.hitPoint = hit
		r.from = r.from or big(w, hand + (hit - big(w, hand)).Unit * prop.length * 0.3)
		local u = math.clamp((t - THROW.Release) / math.max(hitAt - r.at - THROW.Release, 0.05), 0, 1)
		local function path(v)
			local p = r.from:Lerp(hit, v)
			return Vector3.new(p.X, r.from.Y + (hit.Y - r.from.Y) * (2 * v - v * v), p.Z)
		end
		local b = path(u)
		local heading = (path(math.min(u + 0.05, 1)) - path(math.max(u - 0.05, 0))).Unit
		local fell = since - hitAt
		local turn = nil
		if fell > 0 then -- tipped over, spiralling down, carried on a little along its way
			local along = Vector3.new(heading.X, 0, heading.Z).Unit
			local spin = CFrame.fromAxisAngle(Vector3.yAxis, SPIN * 2 * math.pi * fell)
			turn = spin * CFrame.lookAt(Vector3.zero, along) * CFrame.Angles(-math.rad(NOSE_DOWN) * math.min(fell / 0.25, 1), 0, 0)
			b = hit + along * DRIFT * tall * fell - Vector3.yAxis * 0.5 * FALL * tall * fell * fell
				+ spin * (Vector3.xAxis * 0.06 * tall * math.min(fell / 0.3, 1))
			r.gone = fell > GONE
		end
		r.now = b
		local at = small(w, b)
		cf = turn and CFrame.new(at) * turn or CFrame.lookAt(at, at + heading)
	end
	prop.plane:PivotTo(cf)
	shown(r.parts, not r.gone)
end

function SkeetShoot.step(st, since, _shot, steady, winners)
	if not st.throws and winners[1] then setUp(st, winners, steady) end
	for i, s in SkeetShoot.sounds do
		if not st.heard[i] and since >= s[2] then
			st.heard[i] = true
			if since < s[2] + 0.3 then st.kit.Audio.play(s[1]) end
		end
	end
	local me = winners[1]
	local root, head, hand = st.who.model:FindFirstChild("HumanoidRootPart"), st.who.model:FindFirstChild("Head"), st.who.model:FindFirstChild("RightHand")
	if not (me and root and head and hand) then placeStraw(st, since, Vector3.zAxis); return end
	-- what the straw points at: ahead, or the plane being aimed at (the first from when its thrower reaches for it, the
	-- second only once it flies: no look), leading it to its hit point at the puff
	local target = head.Position + root.CFrame:VectorToWorldSpace(REST) * st.h
	for _, r in st.throws or {} do
		throwStep(st, r, since, me, head, root)
		local from = r.at + (r.hit == HIT_A and THROW.Grab or THROW.Release)
		if since >= from and since < r.shot + FLY + 0.25 and (r.now or r.hitNow) then
			target = small(me, since >= r.shot - 0.25 and r.hitNow or r.now or r.hitNow)
		end
	end
	local want = (target - hand.Position).Unit
	local dt = math.clamp(since - (st.last or since), 0, 0.1)
	st.last = since
	st.aim = st.aim and st.aim:Lerp(want, 1 - math.exp(-AIM_RATE * dt)).Unit or want
	local tip = placeStraw(st, since, st.aim)
	-- the spitballs: from the straw's tip at the puff to the plane, then stuck on it
	for _, r in st.throws or {} do
		local flown = since - r.shot
		local on = flown >= 0 and not r.gone and tip ~= nil and (r.prop ~= nil or flown < FLY) -- no plane: it just flies
		r.ball.Transparency = on and 0 or 1
		if on then
			r.ball.Position = flown < FLY and tip:Lerp(small(me, r.hitNow), flown / FLY) or small(me, r.now or r.hitNow)
		end
	end
end

function SkeetShoot.stop(st)
	for _, r in st.throws or {} do
		if r.frozen and not r.done then
			if r.track then r.track:Stop(0) end
			for track, speed in r.frozen do track:AdjustSpeed(speed) end
		end
	end
end

return SkeetShoot
