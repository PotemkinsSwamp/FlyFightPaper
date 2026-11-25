-- Doodler, a runner-up emote (docs/workshop/emotes/doodler.md; card and reference video OK'd by Alan 2026-11-24;
-- remade after his first look in Play the same day). "In my head, I won": sitting cross-legged on the books, hunched
-- over a notebook on the lap, the kid draws in short bursts; when 1st's light clicks on they look up at 1st, as
-- someone drawing checks their model; head down, one more burst (the arrow and "me"); then they sit up tall, lift the
-- notebook up facing themselves, turn it round to us (edge over edge, as a sign is turned round, about its upright middle
-- line, so the drawing faces us right way up: Alan, "they turn it on the wrong side") and hold it at the chest, head
-- tipped, tilting it once each way to show it off.
-- The drawing (Alan: "it should show it like they're in first place, and there should be an arrow drawn to it that
-- says me"): a child's thick crayon stick kid on a stack of books, arms up, a big "1" over the head, and an arrow
-- pointing at the kid from the word "me". Drawn by the pencil stroke by stroke as pen strokes in code (as A+'s card
-- back), no picture. One pencil, in the right hand (Alan). Silent.
-- Timing (Alan: "They spend too much time drawing ... not enough time where it turns it around"): everything is in
-- seconds after 1st's light (`first`), worked out once per kid by `plan`: shown at the chest LOOK + BURST + the turn
-- after 1st's light and held to the end. When 1st's emote takes the lens early (`kit.seenFor()`, Alan: "if the first
-- place is one that shortens it, then the doodler needs to be shortened as well"), it is shortened so the drawing is
-- held up at least HOLD_MIN seconds before then: first the burst after the look goes, then the turn goes FAST times
-- quicker, then the look at 1st goes. Drawing not yet done is finished while the notebook faces the kid.
-- The body: the clip Doodler (tools/emote_cuts/doodler.lua: Nap's cross-legged seat, still) held on its pose; the
-- chest and the head are turned here every frame (hunched, the look, sitting up, the head tip) and the arms bent onto
-- the notebook and the pencil on every body (the scene's bendArm, as A+), after the clip has posed them; the notebook
-- and the pencil are placed from the body by the same numbers, so they touch the hands. 3rd holds the look 0.5 s
-- longer than 2nd, so the two are out of step after it.
local RunService = game:GetService("RunService")

local Doodler = {}
-- The look at 1st, from 1st's light: up over UP, held HOLD (3rd: + LATE_3RD), back down over DOWN.
local LOOK = { UP = 0.5, HOLD = 0.5, DOWN = 0.35, TURN = 45, CHEST = 8, HUNCH = 8, HEAD = -4 }
local LATE_3RD = 0.5
local BURST = 0.95 -- the burst after the look
-- The turn, in seconds at full speed: lifted up facing the kid (READ); the left hand to the spiral and the right lets
-- go (TAKE); a breath (GAP); turned half round (SPIN); in close to the chest (CLOSE). FAST: how much quicker it may go.
local TURN = { READ = 0.5, TAKE = 0.2, GAP = 0.05, SPIN = 0.8, CLOSE = 0.3 }
local FAST, HOLD_MIN = 1.3, 1.6
-- The body by numbers: hunched over the lap the chest HUNCH degrees forward and the head DOWN more; sat up, the chest
-- TALL (a little back) and the head TALL_DOWN; the head tips TIP degrees away from 1st over TIP_IN, TIP_AFTER seconds
-- after the drawing is shown; a breath every BREATH_EVERY seconds (the chest BREATH degrees).
local BODY = { HUNCH = 22, DOWN = 32, TALL = -3, TALL_DOWN = 6, TIP = 18, TIP_IN = 0.7, TIP_AFTER = 0.15, BREATH_EVERY = 4, BREATH = 1.5 }
-- The show-off tilt, from when the drawing is shown: { seconds, degrees }.
local TILTS = { { 0.85, 0 }, { 1.85, 14 }, { 2.95, -14 }, { 3.85, 0 } }
-- Sizes in the kid's heights: the page (big enough for "me" to read: 0.4 tall), its thickness with the cover, the
-- pencil; how far the notebook's far edge is tipped up on the lap (degrees); how far the pencil's point is lifted
-- between strokes (pencil lengths).
local TALL, THIN, PENCIL, LEAD_THICK, LAP_TILT, LIFT = 0.4, 0.01, 0.1, 0.012, 25, 0.12
local WIDE = TALL * 680 / 900
local TURN_ROOM, READ_LOW = 0.02, 0.05 -- the turn: its room before the chest, its top edge under the chin (kid heights)
-- Held up for the turn and shown: its lowest corner (at the biggest tilt) at least LEG_CLEAR over the top of this
-- body's own crossed legs, lifted higher than READ_LOW if it must (Alan in Play: "the drawing when they turn it around
-- is in their legs"; measured on all twelve bots' bodies, 0.13 to 0.21 of the kid's height into them), and shown
-- SHOW_OUT before the chest or the face and hair (kid heights).
local LEG_CLEAR, SHOW_OUT, HAIR = 0.03, 0.05, 0.04
local PAPER, COVER, SPIRAL = Color3.fromRGB(252, 250, 242), Color3.fromRGB(70, 110, 200), Color3.fromRGB(90, 90, 96)
local WOOD, POINT, RUBBER = Color3.fromRGB(245, 196, 40), Color3.fromRGB(60, 52, 48), Color3.fromRGB(240, 140, 150)
-- The drawing, in the page's own pixels (680 by 900, its top left corner first), stroke by stroke in the order drawn:
-- { colour, closed, points }. Thick crayon (STROKE pixels) so it reads from far off. Against the paper: black 14.9 to 1,
-- blue 5.9, red 4.8 (words need 4.5), green 3.6, gold 3.2 (pictures need 3: design-theory rule 1.2).
local STROKE = 36
local BLACK, RED, BLUE, GREEN, GOLD = Color3.fromRGB(35, 35, 45), Color3.fromRGB(210, 50, 40), Color3.fromRGB(40, 90, 200), Color3.fromRGB(40, 150, 60), Color3.fromRGB(210, 115, 10)
local V = Vector2.new
local function ring(mid, r, n, wobble)
	local out = {}
	for i = 1, n do
		local turn = (i - 1) / n * 2 * math.pi - math.pi / 2
		out[i] = mid + V(math.cos(turn), math.sin(turn)) * r * (1 + wobble * math.sin(i * 2.3))
	end
	return out
end
local DRAWING = {
	books = { { RED, true, { V(370, 860), V(660, 855), V(662, 772), V(366, 776) } },
		{ BLUE, true, { V(390, 776), V(640, 773), V(643, 690), V(386, 693) } },
		{ GREEN, true, { V(410, 692), V(620, 689), V(623, 606), V(406, 609) } } },
	kid = { { BLACK, true, ring(V(515, 335), 56, 12, 0.05) },
		{ BLACK, false, { V(515, 392), V(514, 446), V(513, 500) } },
		{ BLACK, false, { V(513, 500), V(498, 553), V(484, 606) } },
		{ BLACK, false, { V(513, 500), V(530, 553), V(546, 606) } },
		{ BLACK, false, { V(514, 425), V(477, 365), V(440, 300) } },
		{ BLACK, false, { V(514, 425), V(551, 365), V(590, 300) } },
		{ GOLD, false, { V(475, 105), V(497, 80), V(518, 58), V(519, 150), V(520, 240) } },
		{ GOLD, false, { V(474, 242), V(520, 240), V(566, 238) } } },
	me = { { RED, false, { V(120, 430), V(220, 400), V(330, 395), V(440, 415) } },
		{ RED, false, { V(440, 415), V(419, 394), V(398, 372) } },
		{ RED, false, { V(440, 415), V(412, 428), V(385, 440) } },
		{ RED, false, { V(30, 690), V(30, 590), V(31, 500) } },
		{ RED, false, { V(31, 515), V(52, 484), V(72, 474), V(93, 484), V(108, 515), V(110, 600), V(111, 690) } },
		{ RED, false, { V(111, 515), V(132, 484), V(152, 474), V(173, 484), V(188, 515), V(190, 600), V(191, 690) } },
		{ RED, false, { V(225, 585), V(285, 585), V(340, 585), V(333, 530), V(285, 502), V(238, 526), V(222, 585), V(234, 655), V(284, 692), V(336, 672) } } },
}
-- Before 1st's light, in seconds after it: the books, then the kid and the "1". The arrow and "me" come after the look.
local BEFORE = { { -1.9, -1.15, "books" }, { -0.95, -0.1, "kid" } }

local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function keyed(keys, t)
	if t <= keys[1][1] then return keys[1][2] end
	for i = 2, #keys do
		if t < keys[i][1] then
			local a, b = keys[i - 1], keys[i]
			return a[2] + (b[2] - a[2]) * ease((t - a[1]) / (b[1] - a[1]))
		end
	end
	return keys[#keys][2]
end
-- The point `share` of the way along a stroke (by length), in page pixels.
local function along(stroke, share)
	local pts = table.clone(stroke.points)
	if stroke.closed then table.insert(pts, stroke.points[1]) end
	local total = 0
	for i = 2, #pts do total += (pts[i] - pts[i - 1]).Magnitude end
	local left = math.clamp(share, 0, 1) * total
	for i = 2, #pts do
		local piece = (pts[i] - pts[i - 1]).Magnitude
		if left <= piece then return pts[i - 1]:Lerp(pts[i], piece > 0 and left / piece or 0) end
		left -= piece
	end
	return pts[#pts]
end

-- This kid's timing, from how long the runner-ups can be seen (`seen`, seconds after 1st's light) and their place.
-- Returns: whether they look at 1st and how long they hold it, when the turn starts, how fast it goes, when the
-- drawing is shown, and every stroke with its seconds (the ones with no time to be drawn on screen are finished
-- while the notebook faces the kid, `hidden`).
local function plan(seen, place)
	local p = { look = true, hold = LOOK.HOLD + (place == 3 and LATE_3RD or 0), speed = 1 }
	local lookEnd = LOOK.UP + p.hold + LOOK.DOWN
	local length = TURN.READ + TURN.TAKE + TURN.GAP + TURN.SPIN + TURN.CLOSE
	local last = seen - HOLD_MIN -- the drawing shown still by then
	p.turn = lookEnd + BURST
	if p.turn + length > last then p.turn = math.max(lookEnd, last - length) end
	if p.turn + length > last then p.speed = FAST; p.turn = math.max(lookEnd, last - length / FAST) end
	if p.turn + length / p.speed > last then p.look = false; p.turn = math.max(0.3 - (place - 1), last - length / FAST) end
	local s = p.speed
	p.read, p.take = p.turn + TURN.READ / s, p.turn + (TURN.READ + TURN.TAKE) / s
	p.spin = p.take + TURN.GAP / s
	p.spun = p.spin + TURN.SPIN / s
	p.shown = p.spun + TURN.CLOSE / s
	p.hidden = p.turn + TURN.READ / s * 0.6 -- the page faces the kid, away from us
	p.strokes = {}
	local function add(name, from, to)
		local list = DRAWING[name]
		for i, stroke in list do
			local span = (to - from) / #list
			table.insert(p.strokes, { color = stroke[1], closed = stroke[2], points = stroke[3], from = from + (i - 1) * span, to = from + i * span })
		end
	end
	for _, burst in BEFORE do add(burst[3], burst[1], burst[2]) end
	local after = p.look and lookEnd or BEFORE[#BEFORE][2]
	if p.turn - 0.05 - after >= 0.3 then add("me", after, math.min(after + BURST, p.turn - 0.05))
	else add("me", p.hidden, p.hidden) end
	return p
end
-- Where the pencil's point is at `first`, in page pixels, and whether it is on the paper.
local function pencilPoint(p, first)
	local last = p.strokes[1].points[1]
	for _, stroke in p.strokes do
		if first < stroke.from then return last, false end
		if first < stroke.to then return along(stroke, (first - stroke.from) / (stroke.to - stroke.from)), true end
		last = along(stroke, 1)
	end
	return last, false
end
-- How far into the look, sitting up and the head tip the body is at `first`.
local function body(p, first)
	local look = p.look and ease(first / LOOK.UP) * (1 - ease((first - LOOK.UP - p.hold) / LOOK.DOWN)) or 0
	return look, ease((first - p.turn) / (TURN.READ / p.speed)), ease((first - p.shown - BODY.TIP_AFTER) / BODY.TIP_IN)
end

-- The notebook's page at `first`, from the body: `get(part)` is where a part is (its CFrame now, or by this
-- frame's pose). Its CFrame faces out of the drawing (LookVector) with the drawing's top up (UpVector), at the page's
-- middle. On the lap: resting on the crossed legs in front of the belly, the far edge tipped LAP_TILT up, the
-- drawing's top away from the kid (they read it). From the turn: lifted before the chest, facing the kid, top up, far
-- enough out to turn; turned half round about its upright middle line; in, close to the chest, below the chin. Then
-- the tilts, about its own middle.
local LAP = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" } -- the crossed legs
local function page(st, get, first)
	local p = st.plan
	local root, chest, head = get(st.parts.HumanoidRootPart), get(st.parts.UpperTorso), get(st.parts.Head)
	local U, F = root.UpVector, root.LookVector
	local kid, torso = st.kid, st.parts.UpperTorso.Size
	local legsTop = -math.huge
	for _, name in LAP do
		local part = st.parts[name] or st.feet[name]
		if part then
			local at, half = get(part), part.Size / 2
			legsTop = math.max(legsTop, at.Position:Dot(U) + math.sqrt((at.XVector:Dot(U) * half.X) ^ 2 + (at.YVector:Dot(U) * half.Y) ^ 2 + (at.ZVector:Dot(U) * half.Z) ^ 2))
		end
	end
	-- in front of the belly and of the hunched chest's lowest front (on two small bots' bodies the chest dipped into it)
	local front = -math.huge
	for _, name in { "LowerTorso", "UpperTorso" } do
		local part, at = st.parts[name], get(st.parts[name])
		local half = part.Size / 2
		front = math.max(front, at.Position:Dot(F) + math.sqrt((at.XVector:Dot(F) * half.X) ^ 2 + (at.YVector:Dot(F) * half.Y) ^ 2 + (at.ZVector:Dot(F) * half.Z) ^ 2))
	end
	local hips = get(st.parts.LowerTorso)
	local tilt = math.rad(LAP_TILT)
	local lapTop = F * math.cos(tilt) + U * math.sin(tilt)
	local near = hips.Position + F * (front - hips.Position:Dot(F) + 0.02 * kid) + U * (legsTop - hips.Position:Dot(U) + THIN * kid)
	local lap = near + lapTop * TALL * kid / 2
	local lapRot = CFrame.lookAt(Vector3.zero, U * math.cos(tilt) - F * math.sin(tilt), lapTop)
	local chin = head.Position - U * st.parts.Head.Size.Y * 0.5
	-- room to turn clear of the chest; low and close enough for the hands (the 0.4-tall notebook, held its height
	-- under the chin, was 0.04 of the kid's height out of the hands' reach as it turned)
	-- in front of the chest and of the face (lifted clear of the legs its top half turns at face height: it went
	-- through the head on two bots' bodies and through hair on most), HAIR more for what hangs off the head
	local skull = st.parts.Head.Size / 2
	local face = (head.Position - chest.Position):Dot(F) + math.sqrt((head.XVector:Dot(F) * skull.X) ^ 2 + (head.YVector:Dot(F) * skull.Y) ^ 2 + (head.ZVector:Dot(F) * skull.Z) ^ 2)
	local front = math.max(torso.Z / 2, face + HAIR * kid)
	-- out only as far as the turn needs: its near edge comes WIDE / 2 times the sine of the turn towards the kid
	-- (held that far out all through, its side edges were up to 0.06 of the kid's height out of the hands' reach)
	local spin = ease((first - p.spin) / (p.spun - p.spin))
	local out = F * (front + TURN_ROOM * kid + WIDE * kid / 2 * math.sin(math.pi * spin))
	local most = math.rad(math.max(math.abs(TILTS[2][2]), math.abs(TILTS[3][2])))
	local drop = TALL * kid / 2 * math.cos(most) + WIDE * kid / 2 * math.sin(most) -- the middle down to its lowest corner
	local height = math.max((chin - chest.Position):Dot(U) - READ_LOW * kid - TALL * kid / 2, legsTop + LEG_CLEAR * kid + drop - chest.Position:Dot(U))
	local read = chest.Position + U * height + out
	local shown = read - out + F * (front + SHOW_OUT * kid)
	local readRot = CFrame.lookAt(Vector3.zero, -F, U)
	local _, up = body(p, first)
	local closer = ease((first - p.spun) / (p.shown - p.spun))
	local rot = CFrame.fromAxisAngle(U, math.pi * spin) * lapRot:Lerp(readRot, up)
	rot = CFrame.fromAxisAngle(rot.LookVector, math.rad(keyed(TILTS, first - p.shown))) * rot
	return rot + lap:Lerp(read, up):Lerp(shown, closer)
end
-- A point on the drawing (page pixels) on its surface, `rise` studs out of it.
local function onPage(st, cf, pixel, rise)
	local w, h = WIDE * st.kid, TALL * st.kid
	return cf * Vector3.new(-(pixel.X / 680 - 0.5) * w, (0.5 - pixel.Y / 900) * h, -THIN * st.kid / 2 - (rise or 0))
end
-- Where the hands' middles go at `first` on the page `cf`, and the pencil (its point and the way to its end) while
-- it draws. `sizes`: a hand's size.
local function hands(st, cf, first, sizes)
	local p, kid, w, h = st.plan, st.kid, WIDE * st.kid, TALL * st.kid
	local side = cf.RightVector -- the page's sideways line, pointed to the kid's right
	if side:Dot(st.right) < 0 then side = -side end
	local function edge(sign, height) return cf.Position + side * sign * (w / 2 + sizes.X * 0.2) + cf.UpVector * height * h end
	-- up its side edges: nearer the kid on the lap, above the middle once lifted (nearer the shoulders: at the middle
	-- the hands were 0.03 of the kid's height short as it came up)
	local grip = -0.1 + 0.25 * ease((first - p.turn) / (p.read - p.turn))
	-- The turn, as a kid turns a sign round (lifted clear of the legs it turns too far out to be held by its middle:
	-- 0.36 of the kid's height from the shoulder, against an arm of about 0.25): the left hand keeps the edge it has
	-- and pulls it in past the chest (A); the right hand, let go at the start, takes that edge as it comes round to
	-- the right; the left hand waits where the other edge (B) will end and catches it as it arrives. Each hand only
	-- ever holds an edge on its own side. Up to the turn the page's own +X edge is the kid's left (it faces them).
	local edgeX = w / 2 + sizes.X * 0.2
	local A, B = cf * Vector3.new(edgeX, grip * h, 0), cf * Vector3.new(-edgeX, grip * h, 0)
	local turned = math.clamp((first - p.spin) / (p.spun - p.spin), 0, 1)
	local left = edge(-1, grip)
	if first >= p.spin and first < p.spun then
		local still = CFrame.fromAxisAngle(cf.UpVector, math.pi * (1 - ease(turned))) -- the rest of the turn
		local ends = cf.Position + still * (B - cf.Position) -- where B will be at its end
		if turned < 0.5 then left = A
		else left = A:Lerp(ends, ease((turned - 0.5) / 0.15)):Lerp(B, ease((turned - 0.65) / 0.35)) end
	end
	-- the right hand: drawing until the turn (the pencil's point on the page, the hand up the pencil); then on its
	-- side edge; let go at the chest at the start of the turn, then on edge A as it comes round
	local pixel, drawing = pencilPoint(p, first)
	local tip = onPage(st, cf, pixel, drawing and 0 or LIFT * PENCIL * kid)
	local slope = (cf.LookVector * 0.75 - cf.UpVector * 0.45 + st.right * 0.35).Unit -- from the point up to the hand
	local writing = tip + slope * 0.65 * PENCIL * kid
	local rest = st.chestAt + st.right * 0.12 * kid - st.up * 0.05 * kid + st.forward * 0.12 * kid
	local right = writing:Lerp(edge(1, grip), ease((first - p.turn) / (p.read - p.turn)))
	if first >= p.read and first < p.spun then
		right = right:Lerp(rest, ease((first - p.read) / (p.take - p.read))):Lerp(A, ease((turned - 0.4) / 0.2))
	end
	return left, right, tip, slope
end

function Doodler.start(kit, who)
	local st = { kit = kit, who = who, seat = kit.seatOn(who.cast, who.top) }
	local id = (kit.ourClip("Doodler"))
	if id then
		local animation = Instance.new("Animation"); animation.AnimationId = id
		st.clip = who.animator:LoadAnimation(animation)
		st.clip.Looped, st.clip.Priority = true, Enum.AnimationPriority.Action
		st.clip:Play(0, 1, 0) -- its pose from the dark on; the chest and head are turned below
	end
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true -- the time is worked out every frame below
	local model = who.model
	st.kid = kit.Avatars.standing_height_studs / who.scale -- the small winner's own studs
	st.parts = {}
	for _, name in { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Head", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" } do
		st.parts[name] = model:FindFirstChild(name)
		if not st.parts[name] then return st end -- an odd body: it only sits
	end
	st.feet = { LeftFoot = model:FindFirstChild("LeftFoot"), RightFoot = model:FindFirstChild("RightFoot") } -- (a body may have none)
	local kid = st.kid
	local function part(name, size, color)
		local made = kit.paper(who.cast, color)
		made.Name, made.Size = name, size
		return made
	end
	st.page = part("DoodlerPage", Vector3.new(WIDE, TALL, THIN * 0.4) * kid, PAPER)
	st.cover = part("DoodlerCover", Vector3.new(WIDE * 1.04, TALL * 1.02, THIN * 0.6) * kid, COVER)
	st.spiral = part("DoodlerSpiral", Vector3.new(WIDE * 0.96, THIN * 1.6, THIN * 1.6) * kid, SPIRAL)
	st.pencil = part("DoodlerPencil", Vector3.new(LEAD_THICK, LEAD_THICK, PENCIL * 0.82) * kid, WOOD)
	st.point = part("DoodlerPoint", Vector3.new(LEAD_THICK * 0.6, LEAD_THICK * 0.6, PENCIL * 0.1) * kid, POINT)
	st.rubber = part("DoodlerRubber", Vector3.new(LEAD_THICK, LEAD_THICK, PENCIL * 0.08) * kid, RUBBER)
	st.gui = Instance.new("SurfaceGui")
	st.gui.Face, st.gui.SizingMode, st.gui.CanvasSize, st.gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 900), 1
	st.gui.Parent = st.page
	if kit.rig and kit.bendArm then
		local joints, at = kit.rig(model)
		st.bend = function() -- after the clip has posed the body (an Edit check calls it by hand)
			if not model:IsDescendantOf(game) then st.bent:Disconnect(); return end
			local p, first = st.plan, st.first
			if not p or not first then return end
			-- the chest and the head (Transform on top of the clip's own, as bendArm does)
			local look, up, tip = body(p, first)
			local hunch = BODY.HUNCH + (LOOK.HUNCH - BODY.HUNCH) * look
			local down = BODY.DOWN + (LOOK.HEAD - BODY.DOWN) * look
			hunch, down = hunch + (BODY.TALL - hunch) * up, down + (BODY.TALL_DOWN - down) * up
			local breath = BODY.BREATH * math.sin(first / BODY.BREATH_EVERY * 2 * math.pi)
			local waist, neck = joints[st.parts.UpperTorso], joints[st.parts.Head]
			if waist and neck then
				-- from the clip's own pose: a held clip may not write it again each frame, and these turns must not
				-- pile up on last frame's
				if waist.joint.Transform ~= st.wrote then st.waist, st.neck = waist.joint.Transform, neck.joint.Transform end
				local w, n = st.waist, st.neck
				waist.joint.Transform = w * CFrame.Angles(-math.rad(hunch + breath), math.rad(st.side * LOOK.CHEST * look), 0)
				neck.joint.Transform = CFrame.fromOrientation(-math.rad(down), math.rad(st.side * LOOK.TURN * look), -math.rad(st.side * BODY.TIP * tip)) * n.Rotation + n.Position
				st.wrote = waist.joint.Transform
			end
			local cf = page(st, at, first)
			local root = at(st.parts.HumanoidRootPart)
			st.up, st.right, st.forward, st.chestAt = root.UpVector, root.RightVector, root.LookVector, at(st.parts.UpperTorso).Position
			local left, right = hands(st, cf, first, st.parts.RightHand.Size)
			st.targets = { Left = left, Right = right } -- (for the Edit checks)
			for side, target in { Left = left, Right = right } do
				local upper, lower, hand = st.parts[side .. "UpperArm"], st.parts[side .. "LowerArm"], st.parts[side .. "Hand"]
				local elbow = (at(upper) * joints[lower].c0).Position + root.RightVector * (side == "Right" and 1 or -1) * 0.3 * st.parts.UpperTorso.Size.X
				kit.bendArm(joints, at, upper, lower, hand, target, elbow, 1)
			end
		end
		st.bent = RunService.PreSimulation:Connect(st.bend)
	end
	return st
end
function Doodler.stop(st)
	if st.bent then st.bent:Disconnect() end
end

function Doodler.step(st, since, _shot, steady, winners)
	local who = st.who
	if not st.plan then -- known once all three stand (1st's emote and how long it lets us be seen)
		local me, top = winners[who.place], winners[1]
		-- 1 looks to the kid's own left (1st on the picture's right), -1 to their right
		st.side = (me and top and me ~= top and (top.spot - me.spot):Dot(steady.RightVector) < 0) and -1 or 1
		st.plan = plan(st.kit.seenFor and st.kit.seenFor() or 10.4, who.place)
		if st.gui then
			st.strokes = {}
			for i, stroke in st.plan.strokes do
				local path = Instance.new("Path2D")
				path.Color3, path.Thickness, path.Closed, path.Visible = stroke.color, STROKE, stroke.closed, false
				local list, pts = {}, stroke.points
				for j, pt in pts do -- rounded: each point's tangents along the line between its neighbours (A+'s pen)
					local a = pts[j - 1] or (stroke.closed and pts[#pts]) or pt
					local b = pts[j + 1] or (stroke.closed and pts[1]) or pt
					local tangent = (b - a) / 6
					list[j] = Path2DControlPoint.new(UDim2.fromOffset(pt.X, pt.Y), UDim2.fromOffset(-tangent.X, -tangent.Y), UDim2.fromOffset(tangent.X, tangent.Y))
				end
				path:SetControlPoints(list)
				path.Parent = st.gui
				st.strokes[i] = path
			end
		end
	end
	local first = winners[1] and winners[1].since or since - (who.place - 1)
	st.first = first
	if st.clip then st.clip.TimePosition = 0 end
	st.kit.sit(who.model, st.seat)
	if not st.page then return end
	local p = st.plan
	local cf = page(st, function(part) return part.CFrame end, first)
	local root = st.parts.HumanoidRootPart.CFrame
	st.up, st.right, st.forward, st.chestAt = root.UpVector, root.RightVector, root.LookVector, st.parts.UpperTorso.Position
	local kid = st.kid
	st.page.CFrame = cf
	st.cover.CFrame = cf * CFrame.new(0, 0, THIN * kid / 2)
	st.spiral.CFrame = cf * CFrame.new(0, TALL * kid / 2, THIN * kid * 0.2) -- along the top edge
	for i, path in st.strokes do path.Visible = first >= p.strokes[i].from end
	-- the pencil: from its point up through the drawing hand while it draws; from the turn on fixed in the right hand
	-- as it was then
	local hand = st.parts.RightHand.CFrame
	local long = PENCIL * kid
	local pencil
	if first < p.turn or not st.grip then
		local _, _, tip, slope = hands(st, cf, first, st.parts.RightHand.Size)
		pencil = CFrame.lookAt(tip + slope * long / 2, tip + slope * long)
		if first >= p.turn then st.grip = hand:ToObjectSpace(pencil) end
	else
		pencil = hand * st.grip
	end
	st.pencil.CFrame = pencil * CFrame.new(0, 0, long * 0.04)
	st.point.CFrame = pencil * CFrame.new(0, 0, long * 0.45)
	st.rubber.CFrame = pencil * CFrame.new(0, 0, -long * 0.46)
end

Doodler.plan = plan -- (for the Edit checks: the timing under each 1st)
return Doodler
