-- Fold It Up, a 1st-place emote (docs/workshop/emotes/fold-it-up.md; Alan's OK 2026-11-22, and his rework of
-- 2026-11-23: "it looked like it was actually taking the screen ... the screen goes dark as she's pulling the frame
-- ... zooming out ... then switch to a camera somewhere else ... she'll turn to that camera, crumple it up, and throw
-- it away"). Smug: the kid sizes you up, rubs their hands, reaches straight at the camera and pinches the picture.
-- The picture itself, still live, shrinks away into black; a beat of black; then the camera is round to the kid's
-- left, the kid holds a sheet, turns to this camera and shows it: only a crayon drawing of the winners. They crumple
-- it and toss it over the shoulder without looking. The body is the clip FoldItUp (tools/emote_cuts/fold-it-up.lua).
-- The hand at the lens (Alan: "you should really only see the hand coming towards you ... fast"): the real right hand
-- is hidden and a copy slides along the line from the lens to the real wrist: on the screen it never leaves the wrist,
-- only grows. No arm is stretched, so sleeves and 3D clothes never move; it works on any R15 body.
-- The picture shrinking, with no screenshot: a wider lens shows the old picture exactly, only smaller. From the pinch
-- the lens widens (`fov`, the scene's hook) while black bars at the lens, with a paper-white rim, cover everything
-- outside the old picture, and the camera rolls a little: a sheet pulled away, tilting. The big hand does not go back
-- with it: it holds the picture by its bottom edge, big, a part of it over the picture (Alan on the fourth run: "you
-- see her giant hand in the frame, but also wrapped around the frame", and no white rim: "it calls to the eye too
-- much"). Then that camera goes out: the black closes over it (FADE), stays (DARK) while the lens goes back to its own
-- angle and the camera swings SIDE degrees round 1st (`camera`), and lifts slowly on the new view (OPEN) (Alan: "a
-- smooth transition ... that camera went out, we're switching to this camera").
local FoldItUp = {}
local MARKS = { Pinch = 3.3, Back = 3.8, Show = 4.5, Crumple = 6.6, Ball = 7.6, Release = 8.15 } -- the clip's own (its draft's attributes win)
local TAKE = 4.1 -- both hands on the poster
local REACH_FROM = 3.05 -- the copy hand leaves the wrist (the reach is under way), reaches the lens at Pinch, back at Back
local GROW = 12 -- the hand's size on the screen at the pinch, against its own
local NEAREST = 0.3 -- the copy hand never comes nearer the lens than this many studs (the camera's near plane is 0.1)
local SHOT_FOV, WIDE = 50, 120 -- the scene's lens, and Roblox's widest: the picture a quarter of its size (0.27)
local SHRINK, FADE, DARK, OPEN = 0.6, 0.25, 0.35, 0.4 -- seconds: the picture shrinking; the black closing; all black; the black lifting on the new camera
local ROLL = 9 -- degrees the shrinking picture tilts
local HAND_AT = 2 -- studs from the lens where the hand holds the picture (in front of the black, MASK)
local HOLD_TALL = { 0.4, 0.26 } -- the holding hand's size, of the screen's height: at the pinch and when the picture is smallest
local GRIP_IN, GRIP_X, GRIP_OVER = 0.15, 0.3, 0.25 -- seconds to take hold; where on the bottom edge (of the half width, to the right); the share of the hand over the picture
local LAMP = 1 -- a small light at the lens while the hand is there (it is out of every spotlight)
local SIDE = 30 -- degrees the second camera is round 1st, to the kid's left (the toss goes off to the far side)
local BACK_AT, BACK_FOR = 9.4, 0.9 -- the camera swings back to the front, the kid turning with it: the scene's glide home starts from the front (from the side it went through furniture: the third run)
local TURN_BY, TURN_AFTER = 0.6, 0.1 -- the kid turns to the second camera: seconds it takes, and after the black starts lifting
local MASK = 3 -- studs in front of the lens where the black bars sit (behind the holding hand, far in front of the winners)
local POSTER_TALL, POSTER_WIDE = 0.5, 0.5 * 4 / 3 -- winner heights (Alan: "poster size, about half")
local IN_FRONT = 0.04 -- the poster this many winner heights in front of the hands holding it
local BALL = 0.11 -- the ball's size, winner heights
local TOSS = Vector3.new(0.1, 1.8, 2.0) -- the ball's start speed, winner heights a second: { to the kid's right, up, back }
local FALL, GONE = 4, 1.1 -- winner heights a second each second; seconds after Release it is gone (into the dark)
local PAPER = Color3.fromRGB(246, 244, 238)
local CREASE = Color3.fromRGB(214, 212, 205)
local DRAWING = "rbxassetid://114077761748868" -- the crayon drawing Alan picked (2a), uploaded 2026-11-22 at 1024 x 768 (assets/ui/emotes/fold-it-up-drawing.png)
local DRAWING_SIZE = Vector2.new(1024, 768)
-- The sounds, cut from Alan's reference video (.planning/emotes/fold-it-up-gemini-api-2.mp4) into
-- assets/audio/emotes/fold-it-up-*.ogg, each starting 0.025 s before its first sound and raised 5 dB; the figure's own
-- "hmmm" (13.8 to 14.5 s of the video) left out (Alan). Seconds after 1st's light.
local LEAD = 0.025
FoldItUp.sounds = {
	{ "foldPeel", MARKS.Pinch - LEAD }, -- the picture pulled away: crinkle and peel (the video's 5.52 to 6.67 s)
	{ "foldFlap", MARKS.Pinch + SHRINK + FADE + DARK - LEAD }, -- the black lifts: the sheet in the hands (6.78 s)
	{ "foldScrunch", MARKS.Crumple - LEAD }, -- crumpled (9.51 to 10.58 s)
	{ "foldToss", MARKS.Release - LEAD }, -- the toss (11.24 s)
	{ "foldDust", 8.95 - LEAD }, { "foldDust", 9.25 - LEAD }, -- the hands dusted, one tap each (12.12 s)
}
FoldItUp.firstSound = MARKS.Pinch - LEAD

local function unseen(part) part.Transparency = 1; return part end

-- A flat colour at the lens that no light touches: an unseen part with a filled SurfaceGui (the scene's curtain's way).
local function flat(parent, color, name)
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow, part.Transparency = name, true, false, false, false, false, 1
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.LightInfluence, gui.SizingMode, gui.CanvasSize, gui.Enabled = Enum.NormalId.Back, 0, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(50, 50), false
	local fill = Instance.new("Frame")
	fill.Size, fill.BorderSizePixel, fill.BackgroundColor3, fill.Parent = UDim2.fromScale(1, 1), 0, color, gui
	gui.Parent, part.Parent = part, parent
	return { part = part, gui = gui, fill = fill }
end

-- The poster's face: the drawing (plain paper if there is none).
local function face(part, side)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.LightInfluence = side, Enum.SurfaceGuiSizingMode.FixedSize, DRAWING_SIZE, 0.6
	local back = Instance.new("Frame")
	back.Size, back.BackgroundColor3, back.BorderSizePixel, back.Parent = UDim2.fromScale(1, 1), PAPER, 0, gui
	if DRAWING ~= "" and side == Enum.NormalId.Front then
		local image = Instance.new("ImageLabel")
		image.Size, image.BackgroundTransparency, image.Image, image.Parent = UDim2.fromScale(1, 1), 1, DRAWING, back
	end
	gui.Parent = part
	return gui
end

function FoldItUp.start(kit, who)
	local id, draft = kit.ourClip("FoldItUp")
	local marks = draft and draft:GetAttributes() or kit.Rounds.fold_it_up or MARKS
	local st = { kit = kit, who = who, marks = {} }
	for name, at in MARKS do st.marks[name] = marks[name] or at end
	st.cutAt = st.marks.Pinch + SHRINK -- the picture is at its smallest: the black starts closing
	st.darkAt = st.cutAt + FADE -- all black: the second camera from here
	st.openAt = st.darkAt + DARK -- the black starts lifting
	if id then
		local animation = Instance.new("Animation"); animation.AnimationId = id
		st.track = who.animator:LoadAnimation(animation)
		st.track.Looped, st.track.Priority = false, Enum.AnimationPriority.Action
		st.track:Play(0, 1, 0) -- its first pose from the dark on
		st.held = true
	else
		st.track = { Play = function() end, AdjustSpeed = function() end }
	end
	st.kid = kit.Avatars.standing_height_studs / who.scale -- a winner's height, in the small winner's studs
	local cast = who.cast
	-- the copy of the right hand that comes at the lens
	local hand = who.model:FindFirstChild("RightHand")
	if hand then
		local copy = hand:Clone()
		for _, item in copy:GetDescendants() do
			if not (item:IsA("SurfaceAppearance") or item:IsA("SpecialMesh") or item:IsA("Decal") or item:IsA("Texture")) then item:Destroy() end
		end
		copy.Name, copy.Anchored, copy.CanCollide, copy.CanQuery, copy.CanTouch, copy.CastShadow = "FoldItUpHand", true, false, false, false, false
		copy.LocalTransparencyModifier, copy.Transparency = 0, 1
		copy.Parent = cast
		st.hand, st.realHand, st.handSize = copy, hand, hand.Size
	end
	-- at the lens: four black bars round the old picture, one black over everything, and a small light for the hand
	st.bars = {}
	for i = 1, 4 do st.bars[i] = flat(cast, Color3.new(), "FoldItUpBar") end
	st.black = flat(cast, Color3.new(), "FoldItUpBlack")
	st.lamp = unseen(kit.paper(cast, PAPER))
	st.lamp.Name = "FoldItUpLamp"
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Shadows, light.Enabled, light.Parent = 8, LAMP, false, false, st.lamp
	st.light = light
	-- the poster: the drawing on its front, plain paper behind
	local poster = unseen(kit.paper(cast, PAPER))
	poster.Name, poster.Size = "FoldItUpPoster", Vector3.new(POSTER_WIDE * st.kid, POSTER_TALL * st.kid, 0.004 * st.kid)
	st.poster, st.front, st.back = poster, face(poster, Enum.NormalId.Front), face(poster, Enum.NormalId.Back)
	st.front.Enabled, st.back.Enabled = false, false
	-- the ball: three lumps, so it is not a perfect sphere
	st.ball = {}
	for i = 1, 3 do st.ball[i] = unseen(kit.paper(cast, i == 2 and CREASE or PAPER, Enum.PartType.Ball)) end
	return st
end

-- How small the old picture is on the screen `t` seconds after 1st's light (1: whole; fast at first: a yank).
local function shrunk(st, t)
	local s = math.clamp((t - st.marks.Pinch) / SHRINK, 0, 1)
	local least = math.tan(math.rad(SHOT_FOV / 2)) / math.tan(math.rad(WIDE / 2))
	return 1 - (1 - least) * (1 - (1 - s) ^ 2)
end

-- The lens angle (the scene's hook): wider while the picture shrinks, its own again from the black on.
function FoldItUp.fov(st, t)
	if t < st.marks.Pinch or t >= st.darkAt then return SHOT_FOV end
	return 2 * math.deg(math.atan(math.tan(math.rad(SHOT_FOV / 2)) / shrunk(st, t)))
end

-- How far round the camera is (1: the second camera's place; back to 0 before the scene leaves), and how far the kid
-- has turned to it.
local function round(st, t) return t < st.darkAt and 0 or 1 - st.kit.ease(math.clamp((t - BACK_AT) / BACK_FOR, 0, 1)) end
local function turned(st, t) return st.kit.ease(math.clamp((t - st.openAt - TURN_AFTER) / TURN_BY, 0, 1)) * round(st, t) end

-- The camera: the scene's own, rolling as the picture shrinks; from the black on, swung SIDE degrees round 1st.
function FoldItUp.camera(st, steady, t)
	if t < st.marks.Pinch then return steady end
	if t < st.darkAt then return steady * CFrame.Angles(0, 0, math.rad(ROLL) * (1 - shrunk(st, t)) / (1 - shrunk(st, st.cutAt))) end
	local spot = st.spot or st.who.desk.Position
	local view = CFrame.new(spot) * CFrame.Angles(0, math.rad(SIDE) * round(st, t), 0) * CFrame.new(-spot) * steady
	-- turned so 2nd and 3rd are as far from the picture's middle as each other (aimed at 1st, the near runner-up
	-- was out of the picture: the third run)
	if st.others then
		local function flatTo(point) local v = point - view.Position; return Vector3.new(v.X, 0, v.Z).Unit end
		local a, b, look = flatTo(st.others[1]), flatTo(st.others[2]), Vector3.new(view.LookVector.X, 0, view.LookVector.Z).Unit
		local mid = (a + b).Unit
		local by = math.atan2(look:Cross(mid).Y, look:Dot(mid))
		view = CFrame.new(view.Position) * CFrame.Angles(0, by, 0) * view.Rotation
	end
	return view
end

-- A flat colour's part put `depth` studs in front of `view`, its middle at (x, y) there, w by h.
local function put(piece, view, depth, x, y, w, h, clear)
	piece.part.Size, piece.part.CFrame = Vector3.new(w, h, 0.01), view * CFrame.new(x, y, -depth)
	piece.gui.Enabled, piece.fill.BackgroundTransparency = true, clear or 0
end

-- Where the poster is: both hands' middle, just in front of them, its drawing the way the kid faces.
local function posterAt(st, t, facing)
	local model = st.who.model
	local right, left = model:FindFirstChild("RightHand"), model:FindFirstChild("LeftHand")
	if not right or not left then return nil end
	local both = st.kit.ease(math.clamp((t - st.marks.Back) / (TAKE - st.marks.Back), 0, 1)) -- from the right hand alone to both
	local middle = right.Position:Lerp((right.Position + left.Position) / 2, both) + facing * IN_FRONT * st.kid * both
	return CFrame.lookAt(middle, middle + facing, Vector3.yAxis)
end

function FoldItUp.step(st, since, shot, steady, winners, fov)
	if since < 0 then return end
	local marks, kid, who = st.marks, st.kid, st.who
	local me = winners and winners[1]
	if me and me.spot then st.spot = me.spot end -- where 1st really stands: what the second camera swings round
	if winners and winners[2] and winners[3] and winners[2].spot and winners[3].spot then st.others = { winners[2].spot, winners[3].spot } end
	-- the kid turns to the second camera (the scene has just put them at their spot, facing the room)
	local turn = turned(st, since)
	local stand = who.desk * CFrame.Angles(0, math.rad(SIDE) * turn, 0)
	if me and me.shift and since >= st.darkAt then who.model:PivotTo(stand + me.shift) end
	local facing = stand.LookVector
	local screen = workspace.CurrentCamera.ViewportSize
	local aspect = screen.X / math.max(screen.Y, 1)
	-- the hand at the lens: out along the line to the wrist as it reaches (on the screen it stays on the wrist and
	-- grows); from the pinch it holds the picture's bottom edge, in the unrolled camera's frame like the picture, as
	-- it looked at the pinch, and stays big while the picture shrinks; gone with the black
	if st.hand then
		local out = since >= REACH_FROM and since < st.darkAt
		st.realHand.LocalTransparencyModifier = out and 1 or 0
		st.light.Enabled = out
		if out then
			local near = math.min(st.kit.ease((since - REACH_FROM) / (marks.Pinch - REACH_FROM)) ^ 1.5, 1) -- speeding up
			local wrist = st.realHand.Position
			local far = (wrist - shot.Position).Magnitude
			local share = math.max(1 / GROW, NEAREST / far) -- of the way from the lens: never nearer than NEAREST
			local size = st.handSize * (1 + (GROW * share - 1) * near) -- its own size: the rest of GROW
			local at = st.realHand.CFrame.Rotation + shot.Position + (wrist - shot.Position) * (1 + (share - 1) * near)
			if since < marks.Pinch then
				st.reached = { at = steady:ToObjectSpace(at), size = size } -- as it is at the pinch, from the lens
			elseif st.reached then
				local held = math.clamp((since - marks.Pinch) / SHRINK, 0, 1)
				local tall = (HOLD_TALL[1] + (HOLD_TALL[2] - HOLD_TALL[1]) * held) * 2 * HAND_AT * math.tan(math.rad((fov or SHOT_FOV) / 2))
				local hy = HAND_AT * math.tan(math.rad(SHOT_FOV / 2)) -- the old picture's bottom edge, HAND_AT from the lens
				local grip = CFrame.new(GRIP_X * hy * aspect, -hy - tall * (0.5 - GRIP_OVER), -HAND_AT) * st.reached.at.Rotation
				local g = st.kit.ease(math.clamp((since - marks.Pinch) / GRIP_IN, 0, 1))
				local big = math.max(st.handSize.X, st.handSize.Y, st.handSize.Z)
				at, size = steady * st.reached.at:Lerp(grip, g), st.reached.size:Lerp(st.handSize * tall / big, g)
			end
			st.hand.Size, st.hand.CFrame, st.hand.Transparency = size, at, 0
			st.lamp.CFrame = shot
		else
			st.hand.Transparency = 1
		end
	end
	-- the black bars round the old picture: it sits where the scene's own lens saw it, in the unrolled camera's frame
	if since >= marks.Pinch and since < st.darkAt then
		local hy = MASK * math.tan(math.rad(SHOT_FOV / 2))
		local hx, big = hy * aspect, MASK * 30
		for i, at in { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } } do
			local x, y = at[1], at[2]
			put(st.bars[i], steady, MASK, x * (hx + big / 2), y * (hy + big / 2), x ~= 0 and big or 3 * big, y ~= 0 and big or 3 * big)
		end
	else
		for i = 1, 4 do st.bars[i].gui.Enabled = false end
	end
	-- that camera goes out: the black closes over everything (the hand too), stays, and lifts on the second camera
	local dark = since < st.cutAt and 0 or since < st.darkAt and (since - st.cutAt) / FADE or since < st.openAt and 1 or 1 - (since - st.openAt) / OPEN
	if dark > 0 then
		local near = 0.15 -- studs: nearer than the hand
		local hy = near * math.tan(math.rad(math.max(fov or SHOT_FOV, SHOT_FOV) / 2)) * 1.3
		put(st.black, shot, near, 0, 0, 2 * hy * aspect, 2 * hy, 1 - st.kit.ease(dark))
	else
		st.black.gui.Enabled = false
	end
	-- the poster: in the hands from the black on, until it is crumpled away
	local crumpled = (since - marks.Crumple) / (marks.Ball - marks.Crumple)
	if since >= st.darkAt and crumpled < 1 then
		local at = posterAt(st, since, facing)
		if at then
			local squash = math.clamp(crumpled, 0, 1)
			local shrink = 1 - squash * 0.95
			local wobble = squash > 0 and CFrame.Angles(math.sin(since * 23) * 0.5 * squash, math.sin(since * 17) * 0.6 * squash, math.sin(since * 19) * 0.4 * squash) or CFrame.identity
			st.poster.Size = Vector3.new(POSTER_WIDE * kid * shrink, POSTER_TALL * kid * shrink, 0.004 * kid)
			st.poster.CFrame = at * wobble
			st.poster.Transparency, st.front.Enabled, st.back.Enabled = 0, true, true
		end
	else
		st.poster.Transparency, st.front.Enabled, st.back.Enabled = 1, false, false
	end
	-- the ball: grows in the hands as the poster goes, rides the right hand, flies back over the shoulder at Release
	local size = BALL * kid * st.kit.ease(math.clamp(crumpled * 1.4 - 0.4, 0, 1))
	local flown = since - marks.Release
	local right = who.model:FindFirstChild("RightHand")
	local where
	if flown < 0 then
		if right and since >= marks.Crumple then
			local left = who.model:FindFirstChild("LeftHand")
			where = since < marks.Ball and left and (right.Position + left.Position) / 2 or right.Position
			st.thrown, st.thrownShift = right.Position, me and me.shift or Vector3.zero
		end
	elseif flown < GONE and st.thrown then
		local v = (stand.RightVector * TOSS.X + Vector3.yAxis * TOSS.Y - facing * TOSS.Z) * kid
		-- from where it left the hand, carried with the kid's place this frame (the scene slides them with the camera)
		where = st.thrown + ((me and me.shift or Vector3.zero) - st.thrownShift) + v * flown - Vector3.yAxis * FALL * kid * flown * flown / 2
	end
	for i, lump in st.ball do
		if where and size > 0 then
			local off = Vector3.new(math.cos(i * 2.1), math.sin(i * 1.3), math.sin(i * 2.9)) * size * 0.18
			lump.Size = Vector3.one * size * (0.8 + i * 0.08)
			lump.CFrame = CFrame.new(where + off) * CFrame.Angles(i, since * 3 * i, 0)
			lump.Transparency = 0
		else
			lump.Transparency = 1
		end
	end
end

-- The name plates and the Menu tag are on the screen, not in the picture: they go from the pinch (they would not
-- shrink with it) until the black has lifted on the second camera.
function FoldItUp.covered(st, t)
	return t >= st.marks.Pinch and t < st.openAt + OPEN
end

function FoldItUp.stop(st)
	if st.realHand and st.realHand.Parent then st.realHand.LocalTransparencyModifier = 0 end
end

return FoldItUp
