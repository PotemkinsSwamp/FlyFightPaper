-- Fold It Up, a 1st-place emote (docs/workshop/emotes/fold-it-up.md; Alan's OK 2026-11-22). Smug: the kid sizes you
-- up, rubs their hands, reaches straight at the camera and pinches the picture off the lens. It peels away into their
-- hand, they turn it round, and it is only a crayon drawing of the winners (stick figures, a crown on 1st). They
-- crumple it and toss it over the shoulder without looking. The body is the clip FoldItUp (tools/emote_cuts/fold-it-up.lua).
-- The hand at the lens (Alan: "you should really only see the hand coming towards you ... fast"): forced perspective.
-- The real right hand is hidden and a copy of it slides along the line from the lens to the real wrist: on the screen it
-- never leaves the wrist, only grows as it nears the camera, and slides back. No arm is stretched, so sleeves and 3D
-- clothes never move; it works on any R15 body.
-- The sheet: at the pinch a milky sheet fills the picture just in front of the lens, drawn into a tent whose point is
-- the hand behind it (four triangles from its corners to the hand). As the hand goes back the sheet's corners close in
-- on the poster's place at the kid's chest, whiter as it goes, and it lies flat in their hands: the poster, its back to
-- us (the crayon showing through, mirrored), turned round, held up, crumpled into a ball that flies off behind them.
local FoldItUp = {}
local MARKS = { Pinch = 3.3, Back = 3.8, Show = 4.5, Crumple = 6.6, Ball = 7.6, Release = 8.15 } -- the clip's own (its draft's attributes win)
local TAKE, FLIP = 4.1, 0.35 -- both hands on the poster; seconds it takes to turn round (it ends at Show)
local REACH_FROM = 3.05 -- the copy hand leaves the wrist (the reach is under way), reaches the lens at Pinch, back at Back
local GROW = 12 -- the hand's size on the screen at the pinch, against its own
local NEAREST = 0.3 -- the copy hand never comes nearer the lens than this many studs (the camera's near plane is 0.1)
local POSTER_TALL, POSTER_WIDE = 0.5, 0.5 * 4 / 3 -- winner heights (Alan: "poster size, about half")
local MILKY = 0.35 -- the sheet's see-through at the pinch; solid paper by Back
local OVER = 1.15 -- the sheet at the lens: this much bigger than the picture, so no edge shows
local BALL = 0.11 -- the ball's size, winner heights
local TOSS = Vector3.new(0.4, 2.2, 1.6) -- the ball's start speed, winner heights a second: { to the kid's right, up, back }
local FALL, GONE = 4, 1.1 -- winner heights a second each second; seconds after Release it is gone (into the dark)
local PAPER = Color3.fromRGB(246, 244, 238)
local CREASE = Color3.fromRGB(214, 212, 205)
local DRAWING = "" -- the crayon drawing (.planning/emotes/fold-it-up-drawing-a.png until uploaded, step 6): plain paper till then
local DRAWING_SIZE = Vector2.new(1200, 900)
-- The sounds, cut from Alan's reference video (.planning/emotes/fold-it-up-gemini-api-2.mp4) into
-- assets/audio/emotes/fold-it-up-*.ogg, each starting 0.025 s before its first sound and raised 5 dB; the figure's own
-- "hmmm" (13.8 to 14.5 s of the video) left out (Alan). Seconds after 1st's light; until step 6 has uploaded them,
-- Audio does not know the names and plays nothing.
local LEAD = 0.025
FoldItUp.sounds = {
	{ "foldPeel", MARKS.Pinch - LEAD }, -- the sheet: crinkle and peel (the video's 5.52 to 6.67 s)
	{ "foldFlap", MARKS.Show - FLIP - LEAD }, -- the poster turned round (6.78 s)
	{ "foldScrunch", MARKS.Crumple - LEAD }, -- crumpled (9.51 to 10.58 s)
	{ "foldToss", MARKS.Release - LEAD }, -- the toss (11.24 s)
	{ "foldDust", 8.95 - LEAD }, { "foldDust", 9.25 - LEAD }, -- the hands dusted, one tap each (12.12 s)
}
FoldItUp.firstSound = MARKS.Pinch - LEAD

local function unseen(part) part.Transparency = 1; return part end

-- A triangle a, b, c from two wedges (the usual split at the foot of the height on the longest side).
local function triangle(w1, w2, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-6 then w1.Transparency, w2.Transparency = 1, 1; return false end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	w1.Size = Vector3.new(0.002, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w2.Size = Vector3.new(0.002, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
	return true
end

-- One face of the poster: the drawing, or (`mirrored`) the drawing faint and flipped, as seen through the paper.
local function face(part, side, mirrored)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.LightInfluence = side, Enum.SurfaceGuiSizingMode.FixedSize, DRAWING_SIZE, 0.6
	local back = Instance.new("Frame")
	back.Size, back.BackgroundColor3, back.BorderSizePixel, back.Parent = UDim2.fromScale(1, 1), PAPER, 0, gui
	if DRAWING ~= "" then
		local image = Instance.new("ImageLabel")
		image.Size, image.BackgroundTransparency, image.Image, image.Parent = UDim2.fromScale(1, 1), 1, DRAWING, back
		if mirrored then
			image.ImageRectOffset, image.ImageRectSize, image.ImageTransparency = Vector2.new(DRAWING_SIZE.X, 0), Vector2.new(-DRAWING_SIZE.X, DRAWING_SIZE.Y), 0.82
		end
	end
	gui.Parent = part
	return gui
end

function FoldItUp.start(kit, who)
	local id, draft = kit.ourClip("FoldItUp")
	local marks = draft and draft:GetAttributes() or kit.Rounds.fold_it_up or MARKS
	local st = { kit = kit, who = who, marks = {} }
	for name, at in MARKS do st.marks[name] = marks[name] or at end
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
	-- the sheet: four triangles, two wedges each; one Highlight keeps it paper-white near the dark lens
	local tent = Instance.new("Model")
	tent.Name, tent.Parent = "FoldItUpSheet", cast
	st.tent = {}
	for i = 1, 4 do
		local color = i % 2 == 0 and CREASE or PAPER -- every other side a little greyer: the creases read
		st.tent[i] = { unseen(kit.paper(tent, color, "WedgePart")), unseen(kit.paper(tent, color, "WedgePart")) }
	end
	local glow = Instance.new("Highlight")
	glow.FillColor, glow.FillTransparency, glow.OutlineTransparency, glow.DepthMode, glow.Enabled = PAPER, 0.55, 1, Enum.HighlightDepthMode.Occluded, false
	glow.Parent = tent
	st.glow = glow
	-- the poster: its front (the drawing) faces the kid until it is turned round
	local poster = unseen(kit.paper(cast, PAPER))
	poster.Name, poster.Size = "FoldItUpPoster", Vector3.new(POSTER_WIDE * st.kid, POSTER_TALL * st.kid, 0.004 * st.kid)
	st.poster, st.front, st.back = poster, face(poster, Enum.NormalId.Front, false), face(poster, Enum.NormalId.Back, true)
	st.front.Enabled, st.back.Enabled = false, false
	-- the ball: three lumps, so it is not a perfect sphere
	st.ball = {}
	for i = 1, 3 do st.ball[i] = unseen(kit.paper(cast, i == 2 and CREASE or PAPER, Enum.PartType.Ball)) end
	return st
end

-- The picture's rectangle `depth` studs in front of the lens, OVER times as big: its middle and half sizes.
local function view(shot, fov, depth)
	local screen = workspace.CurrentCamera.ViewportSize
	local half = math.tan(math.rad(fov / 2)) * depth * OVER
	return shot.Position + shot.LookVector * depth, half * screen.X / math.max(screen.Y, 1), half
end

-- Where the poster is at `t`: both hands' middle at the chest, square to the kid, its drawing turned to the kid before
-- Show (0 of the turn) and to the camera after it (1).
local function posterAt(st, t)
	local model = st.who.model
	local right, left, chest = model:FindFirstChild("RightHand"), model:FindFirstChild("LeftHand"), model:FindFirstChild("UpperTorso")
	if not right or not left or not chest then return nil end
	local both = st.kit.ease(math.clamp((t - st.marks.Back) / (TAKE - st.marks.Back), 0, 1)) -- from the right hand alone to both
	local middle = right.Position:Lerp((right.Position + left.Position) / 2, both)
	local facing = st.who.desk.LookVector
	local turned = st.kit.ease(math.clamp((t - (st.marks.Show - FLIP)) / FLIP, 0, 1))
	local look = CFrame.fromAxisAngle(Vector3.yAxis, math.pi * (1 - turned)) * facing -- the drawing's side
	return CFrame.lookAt(middle, middle + look, Vector3.yAxis)
end

local function hideTent(st)
	for _, pair in st.tent do pair[1].Transparency, pair[2].Transparency = 1, 1 end
	st.glow.Enabled = false
end

function FoldItUp.step(st, since, shot, _steady, _winners, fov)
	if since < 0 then return end
	local marks, kid = st.marks, st.kid
	-- the hand at the lens
	if st.hand then
		local out = since >= REACH_FROM and since < marks.Back
		st.realHand.LocalTransparencyModifier = out and 1 or 0
		if out then
			local near = since < marks.Pinch and st.kit.ease((since - REACH_FROM) / (marks.Pinch - REACH_FROM)) ^ 1.5 -- speeding up
				or 1 - st.kit.ease((since - marks.Pinch) / (marks.Back - marks.Pinch))
			local wrist = st.realHand.Position
			local far = (wrist - shot.Position).Magnitude
			local share = math.max(1 / GROW, NEAREST / far) -- of the way from the lens: never nearer than NEAREST
			local d = 1 + (share - 1) * near
			local grow = 1 + (GROW * share - 1) * near -- its own size: the rest of GROW
			st.hand.Size = st.handSize * grow
			st.hand.CFrame = st.realHand.CFrame.Rotation + shot.Position + (wrist - shot.Position) * d
			st.hand.Transparency = 0
			st.handAt = st.hand.Position
		else
			st.hand.Transparency = 1
		end
	end
	-- the sheet: from the pinch to Back a tent at the lens closing in on the poster's place
	local pulled = since - marks.Pinch
	if pulled >= 0 and since < marks.Back then
		local u = st.kit.ease(pulled / (marks.Back - marks.Pinch))
		local tip = st.handAt or st.realHand.Position
		local depth = math.max(0.12, ((tip - shot.Position).Magnitude) * 0.5)
		local middle, hx, hy = view(shot, fov, depth)
		local to = posterAt(st, since)
		local corners = {}
		for i, c in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(1, 1), Vector2.new(-1, 1) } do
			local atLens = middle + shot.RightVector * c.X * hx + shot.UpVector * c.Y * hy
			local onPoster = to and to * Vector3.new(c.X * POSTER_WIDE / 2 * kid, c.Y * POSTER_TALL / 2 * kid, 0) or atLens
			corners[i] = atLens:Lerp(onPoster, u)
		end
		local point = tip:Lerp((corners[1] + corners[3]) / 2, u) -- the tent flattens as it comes in
		for i, pair in st.tent do
			if triangle(pair[1], pair[2], corners[i], corners[i % 4 + 1], point) then
				pair[1].Transparency, pair[2].Transparency = MILKY * (1 - u), MILKY * (1 - u)
			end
		end
		st.glow.Enabled = true
		st.glow.FillTransparency = 0.55 + 0.4 * u -- near the lens it glows white; in the spotlight the light does it
		st.poster.Transparency, st.front.Enabled, st.back.Enabled = 1, false, false
		return
	end
	hideTent(st)
	-- the poster, from Back until it is crumpled away
	local crumpled = (since - marks.Crumple) / (marks.Ball - marks.Crumple)
	if since >= marks.Back and crumpled < 1 then
		local at = posterAt(st, since)
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
	local right = st.who.model:FindFirstChild("RightHand")
	local where
	if flown < 0 then
		if right and since >= marks.Crumple then
			local left = st.who.model:FindFirstChild("LeftHand")
			local both = since < marks.Ball and left and (right.Position + left.Position) / 2 or right.Position
			where = both
			st.thrown = right.Position
		end
	elseif flown < GONE and st.thrown then
		local d = st.who.desk
		local v = (d.RightVector * TOSS.X + Vector3.yAxis * TOSS.Y - d.LookVector * TOSS.Z) * kid
		where = st.thrown + v * flown - Vector3.yAxis * FALL * kid * flown * flown / 2
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

-- The lens is the sheet's from the pinch until it has drawn in towards the hand: the name plates and the Menu tag go.
function FoldItUp.covered(st, t)
	return t >= st.marks.Pinch and t < st.marks.Pinch + 0.3
end

function FoldItUp.stop(st)
	if st.realHand and st.realHand.Parent then st.realHand.LocalTransparencyModifier = 0 end
end

return FoldItUp
