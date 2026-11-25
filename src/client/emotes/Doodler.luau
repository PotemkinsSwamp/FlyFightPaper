-- Doodler, a runner-up emote (docs/workshop/emotes/doodler.md; card and reference video OK'd by Alan 2026-11-24).
-- "In my head, I won": sitting cross-legged on the books, hunched over a notebook on the lap, the kid draws in short
-- bursts; when 1st's light clicks on they look up at 1st, as someone drawing checks their model; head down, two more
-- bursts and one big last stroke; then they sit up tall, lift the notebook up facing themselves, turn it round to us
-- (held by the middle of its spiral, about its upright middle line, so the drawing faces us right way up: Alan,
-- "they turn it on the wrong side") and hold it at the chest, head tipped, tilting it once each way to show it off.
-- The drawing: a child's thick crayon stick kid on a stack of books, arms up, a big "1" and a star over the head,
-- drawn by the pencil stroke by stroke (each burst draws one part) as pen strokes in code (as A+'s card back), no
-- picture. One pencil, in the right hand (Alan). Silent.
-- The body is one of two clips (tools/emote_cuts/doodler.lua), the chest and the head only, the same but for the side
-- the head turns to: DoodlerLeft to the kid's own left (1st on the picture's right), DoodlerRight to their right.
-- Its time is set here every frame, so the look lands on 1st's light whatever this kid's place: clip second LEAD is
-- 1st's light. 3rd holds the look HOLD_3RD seconds longer and then runs at SPEED_3RD (So Close's rule), so 2nd and
-- 3rd look together and are out of step after. The arms are bent here onto the notebook and the pencil's point on
-- every body (the scene's bendArm, as A+), after the clip has posed them; the notebook and the pencil are placed from
-- the body every frame by the same numbers, so they touch the hands.
local RunService = game:GetService("RunService")

local Doodler = {}
local LENGTH, LEAD, HOLD_3RD, SPEED_3RD = 13, 2.0, 0.5, 0.92
-- Clip seconds (the cut's own: tools/emote_cuts/doodler.lua): it sits up at UP, the notebook is up facing the kid by
-- READ, turned round SPIN to SPUN, held at the chest by SHOWN; TILTS: { seconds, degrees } of its show-off tilt.
local M = { UP = 6.0, READ = 6.6, TAKE = 6.85, SPIN = 6.9, SPUN = 7.8, SHOWN = 8.15 }
local TILTS = { { 8.9, 0 }, { 9.9, 14 }, { 11.0, -14 }, { 11.9, 0 } }
-- Sizes in the kid's heights: the page (as A+'s card, held the same way on every body), its thickness with the cover,
-- the pencil; how far the notebook's far edge is tipped up on the lap (degrees); how far the pencil's point is lifted
-- between strokes (pencil lengths).
local WIDE, TALL, THIN, PENCIL, LEAD_THICK, LAP_TILT, LIFT = 0.26, 0.33, 0.01, 0.1, 0.012, 25, 0.12
local PAPER, COVER, SPIRAL = Color3.fromRGB(252, 250, 242), Color3.fromRGB(70, 110, 200), Color3.fromRGB(90, 90, 96)
local WOOD, POINT, RUBBER = Color3.fromRGB(245, 196, 40), Color3.fromRGB(60, 52, 48), Color3.fromRGB(240, 140, 150)
-- The drawing, in the page's own pixels (680 by 900, its top left corner first), stroke by stroke in the order drawn:
-- { colour, closed, points }. Thick crayon (STROKE pixels: about a twenty-fifth of the page) so it reads from far off.
local STROKE = 36
local BLACK, RED, BLUE, GREEN, GOLD = Color3.fromRGB(35, 35, 45), Color3.fromRGB(210, 50, 40), Color3.fromRGB(40, 90, 200), Color3.fromRGB(40, 150, 60), Color3.fromRGB(245, 165, 20)
local V = Vector2.new
local function ring(mid, r, n, wobble, inner)
	local out = {}
	for i = 1, n do
		local turn = (i - 1) / n * 2 * math.pi - math.pi / 2
		local radius = inner and i % 2 == 0 and inner or r
		out[i] = mid + V(math.cos(turn), math.sin(turn)) * radius * (1 + wobble * math.sin(i * 2.3))
	end
	return out
end
local DRAWING = {
	books = { { RED, true, { V(190, 850), V(490, 845), V(495, 770), V(185, 775) } },
		{ BLUE, true, { V(215, 770), V(465, 767), V(470, 700), V(210, 703) } },
		{ GREEN, true, { V(240, 700), V(440, 697), V(443, 630), V(237, 633) } } },
	kid = { { BLACK, true, ring(V(340, 372), 50, 12, 0.05) },
		{ BLACK, false, { V(340, 422), V(339, 470), V(338, 525) } },
		{ BLACK, false, { V(338, 525), V(316, 578), V(295, 628) } },
		{ BLACK, false, { V(338, 525), V(362, 578), V(385, 628) } } },
	arms = { { BLACK, false, { V(339, 452), V(302, 400), V(266, 342) } },
		{ BLACK, false, { V(339, 452), V(376, 400), V(412, 342) } } },
	one = { { RED, false, { V(232, 140), V(262, 112), V(284, 88), V(285, 180), V(286, 272) } },
		{ RED, false, { V(244, 274), V(286, 272), V(328, 270) } } },
	star = { { GOLD, true, ring(V(450, 175), 88, 10, 0.03, 36) } },
}
-- Clip seconds of each burst of drawing: { start, end, the part it draws }. Two before 1st's light (LEAD), two after
-- the look and the big last stroke (the star in one sweep); still between them.
local BURSTS = { { 0.15, 0.65, "books" }, { 1.05, 1.55, "kid" }, { 3.75, 4.25, "arms" }, { 4.65, 5.15, "one" }, { 5.4, 5.95, "star" } }
local STROKES = {} -- every stroke in order, with its clip seconds
for _, burst in BURSTS do
	local list = DRAWING[burst[3]]
	for i, stroke in list do
		local span = (burst[2] - burst[1]) / #list
		table.insert(STROKES, { color = stroke[1], closed = stroke[2], points = stroke[3], from = burst[1] + (i - 1) * span, to = burst[1] + i * span })
	end
end

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
	local pts = stroke.closed and { table.unpack(stroke.points) } or stroke.points
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
-- Where the pencil's point is at clip second `t`, in page pixels, and whether it is on the paper.
local function pencilPoint(t)
	local last = STROKES[1].points[1]
	for _, stroke in STROKES do
		if t < stroke.from then return last, false end
		if t < stroke.to then return along(stroke, (t - stroke.from) / (stroke.to - stroke.from)), true end
		last = along(stroke, 1)
	end
	return last, false
end

local LAP = { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } -- what the notebook rests on

local function track(who, kit, side)
	local id = (kit.ourClip("Doodler" .. side))
	if not id then return nil end
	local animation = Instance.new("Animation"); animation.AnimationId = id
	local made = who.animator:LoadAnimation(animation)
	made.Looped, made.Priority = false, Enum.AnimationPriority.Action
	return made
end

-- The notebook's page at clip second `t`, from the body: `get(part)` is where a part is (its CFrame now, or by this
-- frame's pose). Its CFrame faces out of the drawing (LookVector) with the drawing's top up (UpVector), at the page's
-- middle. On the lap: resting on the crossed shins, the far edge tipped LAP_TILT up, the drawing's top away from the
-- kid (they read it). From UP to READ: lifted before the chest, facing the kid, top up, far enough out to turn. From
-- SPIN to SPUN: turned half round about its upright middle line. To SHOWN: in, close to the chest, below the chin.
-- Then the tilts, about its own middle.
local function page(st, get, t)
	local root, chest, head = get(st.parts.HumanoidRootPart), get(st.parts.UpperTorso), get(st.parts.Head)
	local U, F = root.UpVector, root.LookVector
	local kid, torso = st.kid, st.parts.UpperTorso.Size
	-- on the lap: its near edge just before the belly, resting on the top of the crossed legs
	local legsTop = -math.huge
	for _, name in LAP do
		local part, at = st.parts[name], get(st.parts[name])
		local half = part.Size / 2
		legsTop = math.max(legsTop, at.Position:Dot(U) + math.sqrt((at.XVector:Dot(U) * half.X) ^ 2 + (at.YVector:Dot(U) * half.Y) ^ 2 + (at.ZVector:Dot(U) * half.Z) ^ 2))
	end
	local hips = get(st.parts.LowerTorso)
	local tilt = math.rad(LAP_TILT)
	local lapTop = F * math.cos(tilt) + U * math.sin(tilt)
	local near = hips.Position + F * (st.parts.LowerTorso.Size.Z / 2 + 0.02 * kid) + U * (legsTop - hips.Position:Dot(U) + THIN * kid)
	local lap = near + lapTop * TALL * kid / 2
	local lapRot = CFrame.lookAt(Vector3.zero, U * math.cos(tilt) - F * math.sin(tilt), lapTop)
	local chin = head.Position - U * st.parts.Head.Size.Y * 0.5
	local out = F * (torso.Z / 2 + WIDE * kid / 2 + 0.03 * kid)
	local read = chest.Position + U * ((chin - chest.Position):Dot(U) - 0.01 * kid - TALL * kid / 2) + out
	local shown = read - out + F * (torso.Z / 2 + 0.05 * kid)
	local readRot = CFrame.lookAt(Vector3.zero, -F, U)
	local up = ease((t - M.UP) / (M.READ - M.UP))
	local spin = ease((t - M.SPIN) / (M.SPUN - M.SPIN))
	local closer = ease((t - M.SPUN) / (M.SHOWN - M.SPUN))
	local rot = CFrame.fromAxisAngle(U, math.pi * spin) * lapRot:Lerp(readRot, up)
	rot = CFrame.fromAxisAngle(rot.LookVector, math.rad(keyed(TILTS, t))) * rot
	return rot + lap:Lerp(read, up):Lerp(shown, closer)
end
-- A point on the drawing (page pixels) on its surface, `rise` studs out of it.
local function onPage(st, cf, pixel, rise)
	local w, h = WIDE * st.kid, TALL * st.kid
	return cf * Vector3.new(-(pixel.X / 680 - 0.5) * w, (0.5 - pixel.Y / 900) * h, -THIN * st.kid / 2 - (rise or 0))
end
-- Where the hands' middles go at clip second `t` on the page `cf`, and the pencil (its point and the way to its end)
-- while it draws.
local function hands(st, cf, t, sizes)
	local kid, w, h = st.kid, WIDE * st.kid, TALL * st.kid
	local U = st.up
	local side = cf.RightVector -- the page's sideways line, pointed to the kid's right
	if side:Dot(st.right) < 0 then side = -side end
	local function edge(sign, height) return cf.Position + side * sign * (w / 2 + sizes.X * 0.2) + cf.UpVector * height * h end
	local spiral = cf.Position + cf.UpVector * (h / 2 + sizes.Y * 0.3)
	-- the left hand: on its side edge, nearer the kid on the lap; to the spiral's middle for the turn and back (the
	-- bottom edge's middle was a tenth of the kid's height out of reach)
	local take = ease((t - M.READ) / (M.TAKE - M.READ)) * (1 - ease((t - M.SPUN) / (M.SHOWN - M.SPUN)))
	local left = edge(-1, -0.1):Lerp(spiral, take)
	-- the right hand: drawing until UP (the pencil's point on the page, the hand up the pencil); then on its side
	-- edge; let go at the chest for the turn
	local pixel, drawing = pencilPoint(t)
	local tip = onPage(st, cf, pixel, drawing and 0 or LIFT * PENCIL * kid)
	local slope = (cf.LookVector * 0.75 - cf.UpVector * 0.45 + st.right * 0.35).Unit -- from the point up to the hand
	local writing = tip + slope * 0.65 * PENCIL * kid
	local onEdge = edge(1, -0.1)
	local rest = st.chestAt + st.right * 0.12 * kid - U * 0.05 * kid + st.forward * 0.12 * kid
	local right = writing:Lerp(onEdge, ease((t - M.UP) / (M.READ - M.UP)))
	right = right:Lerp(rest, take)
	return left, right, tip, slope
end

function Doodler.start(kit, who)
	local st = { kit = kit, who = who, seat = kit.seatOn(who.cast, who.top), clip = track(who, kit, "Left") }
	if st.clip then st.clip:Play(0, 1, 0) end -- its first pose from the dark on (both clips start the same)
	st.track, st.held = { Play = function() end, AdjustSpeed = function() end }, true -- the time is set every frame below
	local model = who.model
	st.kid = kit.Avatars.standing_height_studs / who.scale -- the small winner's own studs
	st.parts = {}
	for _, name in { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Head", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" } do
		st.parts[name] = model:FindFirstChild(name)
		if not st.parts[name] then return st end -- an odd body: the clip plays, no props
	end
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
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 900), 1
	st.strokes = {}
	for i, stroke in STROKES do
		local path = Instance.new("Path2D")
		path.Color3, path.Thickness, path.Closed, path.Visible = stroke.color, STROKE, stroke.closed, false
		local list, pts = {}, stroke.points
		for j, p in pts do -- rounded: each point's tangents along the line between its neighbours (A+'s pen)
			local a = pts[j - 1] or (stroke.closed and pts[#pts]) or p
			local b = pts[j + 1] or (stroke.closed and pts[1]) or p
			local tangent = (b - a) / 6
			list[j] = Path2DControlPoint.new(UDim2.fromOffset(p.X, p.Y), UDim2.fromOffset(-tangent.X, -tangent.Y), UDim2.fromOffset(tangent.X, tangent.Y))
		end
		path:SetControlPoints(list)
		path.Parent = gui
		st.strokes[i] = path
	end
	gui.Parent = st.page
	st.gui = gui
	if kit.rig and kit.bendArm then
		local joints, at = kit.rig(model)
		st.bend = function() -- after the clip has posed the body (an Edit check calls it by hand)
			if not model:IsDescendantOf(game) then st.bent:Disconnect(); return end
			if not st.t then return end
			local cf = page(st, at, st.t)
			local root = at(st.parts.HumanoidRootPart)
			st.up, st.right, st.forward, st.chestAt = root.UpVector, root.RightVector, root.LookVector, at(st.parts.UpperTorso).Position
			local left, right = hands(st, cf, st.t, st.parts.RightHand.Size)
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

-- This kid's clip time `first` seconds after 1st's light (So Close's rule).
local function clipTime(place, first)
	if place == 3 then
		local held = first - 0.5 -- after the look has landed (clip LEAD + 0.5)
		return first < 0.5 and first + LEAD or held < HOLD_3RD and LEAD + 0.5 or LEAD + 0.5 + (held - HOLD_3RD) * SPEED_3RD
	end
	return first + LEAD
end

function Doodler.step(st, since, _shot, steady, winners)
	local who = st.who
	if not st.side then
		local me, top = winners[who.place], winners[1]
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
	local first = winners[1] and winners[1].since or since - (who.place - 1)
	local t = math.clamp(clipTime(who.place, first), 0, LENGTH - 0.01)
	if st.clip then st.clip.TimePosition = t end
	st.kit.sit(who.model, st.seat)
	st.t = t
	if not st.page then return end
	local get = function(part) return part.CFrame end
	local cf = page(st, get, t)
	local root = st.parts.HumanoidRootPart.CFrame
	st.up, st.right, st.forward, st.chestAt = root.UpVector, root.RightVector, root.LookVector, st.parts.UpperTorso.Position
	local kid = st.kid
	st.page.CFrame = cf
	st.cover.CFrame = cf * CFrame.new(0, 0, THIN * kid / 2)
	st.spiral.CFrame = cf * CFrame.new(0, TALL * kid / 2, THIN * kid * 0.2) -- along the top edge
	for i, path in st.strokes do path.Visible = t >= STROKES[i].from end
	-- the pencil: from its point up through the drawing hand while it draws; from UP on fixed in the right hand as it
	-- was then
	local hand = st.parts.RightHand.CFrame
	local pencil
	if t < M.UP or not st.grip then
		local _, _, tip, slope = hands(st, cf, t, st.parts.RightHand.Size)
		local long = PENCIL * kid
		pencil = CFrame.lookAt(tip + slope * long / 2, tip + slope * long)
		if t >= M.UP then st.grip = hand:ToObjectSpace(pencil) end
	else
		pencil = hand * st.grip
	end
	local long = PENCIL * kid
	st.pencil.CFrame = pencil * CFrame.new(0, 0, long * 0.04)
	st.point.CFrame = pencil * CFrame.new(0, 0, long * 0.45)
	st.rubber.CFrame = pencil * CFrame.new(0, 0, -long * 0.46)
end

return Doodler
