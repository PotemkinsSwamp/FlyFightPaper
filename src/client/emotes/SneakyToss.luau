-- Sneaky Toss, a runner-up emote (docs/workshop/emotes/sneaky-toss.md; card OK'd by Alan 2026-11-24, no whistling;
-- the throw from his second reference video, the innocence built by hand). Hands behind the back, a sly look at 1st,
-- a crumpled paper ball bounced once in the palm, one overarm throw: the ball misses, passing BEHIND 1st (never in
-- front of them, never towards the lens) and on out of the light on the far side; then a show of innocence: rocking on
-- the heels, looking away, the head tilting, shifty glances, one peek with a snigger.
-- The body is one of two clips (tools/emote_cuts/sneaky-toss.lua), mirror images: SneakyTossLeft throws towards the
-- kid's own left (1st on the picture's right), SneakyTossRight to their right. Its time is set here every frame from
-- 1st's light: clip second LIGHT is 1st's light; 3rd runs DELAY_3RD behind, so two kids playing it are out of step.
-- The ball: on the throwing hand from Out (a bounce from Toss to Catch), then from Release a thrown ball's path through
-- a point behind 1st's head (whatever 1st is doing then: behind the back of 1st's whole box, as the camera sees it) and
-- on, falling. Each small winner stands in their own world, slid towards the camera by their scale; the flight is
-- worked out in the big room and drawn in the world of the winner it is nearest across the picture, so it hides
-- behind that one correctly. It is gone once it leaves the side of the picture, drops through the desk top, or after
-- GONE seconds. No sound (Alan: none
-- picked).
local SneakyToss = {}
local LENGTH, LIGHT, DELAY_3RD = 12, 1, 0.6
local MARKS = { Out = 2.0, Toss = 2.62, Catch = 2.9, Release = 3.44 } -- the clip's own (its draft's attributes win)
local TOSS_UP = 0.13 -- the bounce: the ball's rise over the hand (winner heights)
local BALL, BALL_MIN, BALL_MAX = 0.5, 0.06, 0.11 -- the ball's size: of the thrower's head, kept between these (winner heights)
local TO_BEHIND, MARGIN, BELOW_TOP = 0.35, 0.15, 0.2 -- seconds from the hand to behind 1st; how far behind 1st's box, below its top (winner heights)
local FALL, GONE = 3, 2.0 -- heights a second squared down (a light paper ball: it carries past the far runner-up and drops
-- to the desk tops at about the far desk's outer edge); seconds until hidden at the latest
local WHITE = Color3.fromRGB(244, 242, 234)
SneakyToss.marks = MARKS

local function big(w, p) return w.spot + (p - w.spot - w.shift) * w.scale end
local function small(w, b) return w.spot + w.shift + (b - w.spot) / w.scale end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function track(who, kit, side)
	local id = (kit.ourClip("SneakyToss" .. side))
	if not id then return nil end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local made = who.animator:LoadAnimation(animation)
	made.Looped, made.Priority = false, Enum.AnimationPriority.Action
	return made
end

function SneakyToss.start(kit, who)
	local _, draft = kit.ourClip("SneakyTossLeft")
	local st = { kit = kit, who = who, marks = {}, tall = kit.Avatars.standing_height_studs, clip = track(who, kit, "Left") }
	for name, at in MARKS do st.marks[name] = draft and draft:GetAttribute(name) or at end
	if st.clip then st.clip:Play(0, 1, 0) end -- its first pose from the dark on (both clips start the same)
	-- the scene's start at this kid's light is not used: the time is set every frame below
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true
	local head = who.model:FindFirstChild("Head")
	local h = st.tall / who.scale -- a winner height in this kid's world
	st.size = math.clamp(BALL * (head and head.Size.Y or 0.2 * h), BALL_MIN * h, BALL_MAX * h) * who.scale -- in the big room
	st.ball = kit.paper(who.cast, WHITE, Enum.PartType.Ball)
	st.ball.Name, st.ball.Size, st.ball.Transparency = "SneakyTossBall", Vector3.one * st.size / who.scale, 1
	return st
end

-- Where the ball flies (big room): from `from` through a point behind 1st's head TO_BEHIND later, then on, falling.
local function aim(st, from, top, steady)
	local tall = st.tall
	local look, far, highest = steady.LookVector, -math.huge, -math.huge
	local over
	if top.model then
		local box, size = top.model:GetBoundingBox()
		for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
			local corner = big(top, box * (size / 2 * Vector3.new(x, y, z)))
			far, highest = math.max(far, (corner - steady.Position):Dot(look)), math.max(highest, corner.Y)
		end end end
		local head = top.model:FindFirstChild("Head")
		over = head and big(top, head.Position) or big(top, box.Position)
	else
		-- The emote shop's TV: 1st is not there (only where they would stand). The ball flies where the head of a kid
		-- standing there would be, and on out of the picture (Alan 2026-11-25: with no 1st to aim at, this stopped
		-- with an error every frame and the ball hung in the air where the hand let go).
		over = top.spot + Vector3.yAxis * 1.2 * tall
		far, highest = (over - steady.Position):Dot(look) + 0.3 * tall, over.Y + BELOW_TOP * tall
	end
	over = Vector3.new(over.X, math.min(over.Y, highest - BELOW_TOP * tall), over.Z)
	local away = flat(look).Unit
	local deeper = far + (MARGIN * tall + st.size / 2) - (over - steady.Position):Dot(look)
	local behind = over + away * math.max(deeper, 0) / away:Dot(look)
	local g = FALL * tall
	return { from = from, g = g, v = (behind - from + Vector3.yAxis * 0.5 * g * TO_BEHIND ^ 2) / TO_BEHIND, behind = behind, deskTop = top.spot.Y }
end
SneakyToss.aim = aim -- for the number checks
local function flown(path, s) return path.from + path.v * s - Vector3.yAxis * 0.5 * path.g * s * s end
SneakyToss.flown = flown

function SneakyToss.step(st, since, _shot, steady, winners, fov)
	local who, m = st.who, st.marks
	local me, top = winners[who.place], winners[1]
	if not st.side then
		st.side = (me and top and me ~= top and (top.spot - me.spot):Dot(steady.RightVector) < 0) and "Right" or "Left"
		if st.side == "Right" then
			local right = track(who, st.kit, "Right")
			if right then
				if st.clip then st.clip:Stop(0) end
				st.clip = right
				right:Play(0, 1, 0)
			end
		end
	end
	local first = top and top.since or since - (who.place - 1)
	local t = math.clamp(first + LIGHT - (who.place == 3 and DELAY_3RD or 0), 0, LENGTH - 0.01)
	if st.clip then st.clip.TimePosition = t end
	-- the ball
	local ball = st.ball
	local hand = who.model:FindFirstChild(st.side .. "Hand")
	if t < m.Out or not hand or not me or not top or me == top then ball.Transparency = 1; return end
	if t < m.Release then -- on the hand (on top of it, so it rests in the palm whichever way the hand turns)
		local up = st.size / who.scale * 0.5 + hand.Size.Y * 0.35
		local u = math.clamp((t - m.Toss) / (m.Catch - m.Toss), 0, 1)
		up += 4 * TOSS_UP * st.tall / who.scale * u * (1 - u)
		ball.Parent, ball.Size, ball.Transparency = who.cast, Vector3.one * st.size / who.scale, 0
		ball.Position = hand.Position + Vector3.yAxis * up
		st.lastBall = ball.Position
		return
	end
	if not st.path then st.path = aim(st, big(me, st.lastBall or hand.Position), top, steady) end
	local s = t - m.Release
	local b = flown(st.path, s)
	local l = steady:PointToObjectSpace(b)
	local camera = workspace.CurrentCamera
	local wide = math.tan(math.rad((fov or 50) / 2)) * camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1) * -l.Z
	if s > GONE or b.Y < st.path.deskTop or math.abs(l.X) > wide + st.size then ball.Transparency = 1; return end
	-- drawn in the world of the winner nearest it across the picture
	local near, gap = me, math.huge
	for _, w in winners do
		local d = math.abs((b - w.spot):Dot(steady.RightVector))
		if d < gap then near, gap = w, d end
	end
	local parent = near.world and (near.world:FindFirstChild("Cast") or near.world) or who.cast
	ball.Parent, ball.Size, ball.Transparency = parent, Vector3.one * st.size / near.scale, 0
	ball.Position = small(near, b)
end

function SneakyToss.stop(st)
	if st.ball then st.ball:Destroy() end
end

return SneakyToss
