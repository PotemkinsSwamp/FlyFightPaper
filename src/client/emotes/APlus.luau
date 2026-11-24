-- A+, a 1st-place emote (docs/workshop/emotes/a-plus.md; card OK'd by Alan 2026-11-22, made the real card
-- 2026-11-24). A smug show-off: the kid reads their report card, holds it up over the head, shows it to both sides,
-- shows it at the chest, then slaps it at the camera: it lands flat on the lens exactly where the real report card
-- comes up, and the kid gloats beside it until the camera leaves, when the real card takes its place in the same
-- frame (Alan: "it should line up perfectly"). The body is the clip APlus (tools/emote_cuts/a-plus.lua). The card is
-- the match's real report card (`front`): a copy of the real page, in a team round the winners' (1st's own team's),
-- so it is the same card before and after the swap. Its back, seen while the kid reads, is a red-pen "A+" and a
-- smug winking smiley (`back`). It is held in both hands, one on each side edge (the arms are bent onto it
-- on every body), then stands on the right hand (its bottom edge on the hand) until Release, flies FLIGHT seconds at
-- the lens and lands square on the real card's rectangle; worked out every frame from where
-- the real card sits on this screen, at the depth where the card's own size fills it, so it fits any screen.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local APlus = {}
local TALL = 0.35 -- the card's height, in winner heights (about a tenth of the picture)
local GRIP = { read = 0.45, high = 0.12, show = 0.3 } -- held in both hands: how far up its side edges the hands are (share of its height): reading, held up, shown at the chest
-- The clip's own seconds after 1st's light: the card comes down to the chest (down to shown); the right hand draws it
-- back for the throw (take), and it stands on that hand (taken); the left hand has let go LET_GO after take.
local SHOW, LET_GO = { down = 5.0, shown = 5.5, take = 6.3, taken = 6.75 }, 0.25
local bend -- (below)
local READ_TILT = 25 -- reading: the top leans this many degrees away from the kid
local FLIGHT = 0.4 -- release to the lens
local MARKS = { Snap = 2.0, Release = 7.4 } -- the clip's own (its draft's attributes win)
local PAPER = Color3.fromRGB(240, 228, 206) -- the card picture's paper, for its back and edge
local RED_PEN = Color3.fromRGB(200, 38, 38) -- the real card's (RoundEnd)
local RING = require(game.ReplicatedStorage:WaitForChild("FlyFightPaper").Shared.UIAssets).results.redRing
-- The sounds, cut from Alan's reference video (assets/audio/emotes/a-plus-flap.ogg and a-plus-slap.ogg, each starting
-- 0.025 to 0.035 s before its hit): the flap FLAP after Snap, so its crack falls as the card reaches the top; the slap
-- on the landing. Seconds after 1st's light; until step 6 has uploaded them, Audio does not know the names and plays nothing.
local FLAP = 0.2
APlus.sounds = { { "aPlusFlap", MARKS.Snap + FLAP }, { "aPlusSlap", MARKS.Release + FLIGHT } }
APlus.firstSound = MARKS.Snap + FLAP

-- The real card's page: the visible one with the gold star (the winners' card in a team round), else Page1.
local function realPage()
	local player = Players.LocalPlayer
	local gui = player and player:FindFirstChild("PlayerGui")
	local results = gui and gui:FindFirstChild("RoundEnd") and gui.RoundEnd:FindFirstChild("Results", true)
	if not results then return nil end
	local one, two = results:FindFirstChild("Page1"), results:FindFirstChild("Page2")
	local starred = two and two.Visible and two:FindFirstChild("Star") and two.Star.Visible and not (one and one:FindFirstChild("Star") and one.Star.Visible)
	return starred and two or one
end
local function shown(item)
	while item and item:IsA("GuiObject") do
		if not item.Visible then return false end
		item = item.Parent
	end
	return item ~= nil and (not item:IsA("ScreenGui") or item.Enabled)
end

-- The card's front: the real page as it stands, copied whole (Alan 2026-11-24: "can't the one they're throwing up be
-- the actual ending report card?"; the look-alike with its words scribbled over was seen "for too long and too close
-- up"). The page is filled in when the winners' moment starts (RoundEnd), long before this. Left off: what pops in on
-- the real card once it is up (the Double button, the mission slip and its star). Your level bar is hidden while the
-- real card is: it is shown here as RoundEnd keeps it meanwhile, where it will start from.
local POPS_IN = { PaperOffer = true, MissionSlip = true, MissionStar = true }
local LEVEL_BAR = { "Level", "XPCount", "NextUnlock", "XPFrame", "XPFill" }
local function front(part)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.Enabled, gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 900), false, 1
	local page = realPage()
	if page then
		local copy = page:Clone()
		for _, item in copy:GetChildren() do
			if item:IsA("UIScale") or POPS_IN[item.Name] then item:Destroy() end
		end
		local pocket = copy:FindFirstChild("PocketLabel")
		if pocket and pocket.Visible then -- your own card: the one with your level bar
			for _, name in LEVEL_BAR do
				local piece = copy:FindFirstChild(name)
				if piece then piece.Visible = true end
			end
			local star = copy:FindFirstChild("PrestigeStar")
			local rank = star and star:FindFirstChild("Rank")
			if rank then star.Visible = (tonumber(rank.Text) or 0) > 0 end
		end
		copy.AnchorPoint, copy.Position, copy.Size, copy.Rotation, copy.Visible = Vector2.zero, UDim2.new(), UDim2.fromScale(1, 1), 0, true
		copy.Parent = gui
	end
	gui.Parent = part
	return gui
end

-- The card's back, seen while the kid reads it: the teacher's red pen, a big ringed "A+" (the ring the real card
-- draws round an A+) over a smug smiley, one eye winking, one brow up (Alan 2026-11-24: "A+ and like a smiley face,
-- but kind of like a winking smiley face, so it's like smug"). All pen strokes, no picture and no letters (a letter is
-- drawn at 100 points at most, a third of the size needed, and a UIScale does not grow it on a part: Edit preview,
-- 2026-11-24): `pen` draws one stroke through points given in the sheet's own pixels (680 by 900).
local function back(part)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.Enabled, gui.LightInfluence = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 900), false, 1
	local sheet = Instance.new("Frame")
	sheet.Size, sheet.BackgroundColor3, sheet.BorderSizePixel, sheet.Parent = UDim2.fromScale(1, 1), PAPER, 0, gui
	local ring = Instance.new("ImageLabel")
	ring.Image, ring.BackgroundTransparency, ring.ScaleType, ring.Rotation = RING, 1, Enum.ScaleType.Stretch, -6
	ring.AnchorPoint, ring.Position, ring.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(340, 270), UDim2.fromOffset(600, 400)
	ring.Parent = sheet
	local V = Vector2.new
	local function pen(points, closed, thick)
		local path = Instance.new("Path2D")
		path.Color3, path.Thickness, path.Closed, path.Parent = RED_PEN, thick or 14, closed or false, sheet
		local list = {}
		for i, p in points do
			-- rounded: each point's tangents run along the line between its neighbours
			local a, b = points[i - 1] or (closed and points[#points]) or p, points[i + 1] or (closed and points[1]) or p
			local along = (b - a) / 6
			list[i] = Path2DControlPoint.new(UDim2.fromOffset(p.X, p.Y), UDim2.fromOffset(-along.X, -along.Y), UDim2.fromOffset(along.X, along.Y))
		end
		path:SetControlPoints(list)
	end
	pen({ V(196, 372), V(238, 250), V(282, 158), V(300, 168), V(330, 262), V(352, 360) }, false, 18) -- A: up one leg and down the other
	pen({ V(226, 296), V(280, 286), V(338, 282) }, false, 18) -- its bar
	pen({ V(388, 272), V(440, 264), V(492, 262) }, false, 18) -- +
	pen({ V(444, 206), V(440, 266), V(440, 326) }, false, 18)
	local mid, r = V(340, 670), 160
	local face = {}
	for i = 1, 12 do -- the face: a round, a little uneven, as drawn by hand
		local turn = (i - 1) / 12 * 2 * math.pi
		face[i] = mid + V(math.cos(turn), math.sin(turn)) * r * (1 + 0.04 * math.sin(i * 2.3))
	end
	pen(face, true)
	pen({ mid + V(-62, -50), mid + V(-58, -18) }) -- the open eye: a short stroke
	pen({ mid + V(-100, -78), mid + V(-68, -100), mid + V(-32, -92) }) -- its brow, up
	pen({ mid + V(28, -28), mid + V(58, -46), mid + V(88, -28) }) -- the wink: an arch
	pen({ mid + V(-78, 58), mid + V(-20, 72), mid + V(42, 58), mid + V(92, 10) }) -- the smirk: up to the winking side
	pen({ mid + V(78, -6), mid + V(106, 12) }) -- and the tuck at its corner
	gui.Parent = part
	return gui
end

function APlus.start(kit, who)
	local id, draft = kit.ourClip("APlus")
	local marks = draft and draft:GetAttributes() or kit.Rounds.a_plus or MARKS
	local st = { kit = kit, who = who, marks = { Snap = marks.Snap or MARKS.Snap, Release = marks.Release or MARKS.Release } }
	if id then
		local animation = Instance.new("Animation"); animation.AnimationId = id
		st.track = who.animator:LoadAnimation(animation)
		st.track.Looped, st.track.Priority = false, Enum.AnimationPriority.Action
		st.track:Play(0, 1, 0) -- its first pose from the dark on: reading the card
		st.held = true
	else
		st.track = { Play = function() end, AdjustSpeed = function() end }
	end
	st.height = TALL * kit.Avatars.standing_height_studs / who.scale -- in the small winner's studs
	local card = Instance.new("Part")
	card.Name, card.Anchored, card.CanCollide, card.CanQuery, card.CanTouch, card.CastShadow = "APlusCard", true, false, false, false, false
	card.Size, card.Color, card.Material = Vector3.new(st.height * 680 / 900, st.height, st.height * 0.01), PAPER, Enum.Material.SmoothPlastic
	card.Parent = who.cast
	st.card, st.face, st.back = card, front(card), back(card)
	-- Both hands on the card on this body: the arms are bent again after the clip has posed them (the scene's own
	-- bendArm, as Nap's hand and Good Game's clap).
	local model = who.model
	st.kid, st.chest, st.head = kit.Avatars.standing_height_studs / who.scale, model:FindFirstChild("UpperTorso"), model:FindFirstChild("Head")
	st.arms = {}
	for side, sign in { Right = 1, Left = -1 } do
		local upper, lower, hand = model:FindFirstChild(side .. "UpperArm"), model:FindFirstChild(side .. "LowerArm"), model:FindFirstChild(side .. "Hand")
		if upper and lower and hand then st.arms[side] = { upper = upper, lower = lower, hand = hand, sign = sign } end
	end
	if kit.rig and kit.bendArm and st.chest and st.head then
		local joints, at = kit.rig(model)
		st.bend = function() bend(st, joints, at) end
		st.bent = RunService.PreSimulation:Connect(st.bend)
	end
	return st
end
function APlus.stop(st)
	if st.bent then st.bent:Disconnect() end
end

-- Where the real card sits on the screen: its middle and height in pixels from the screen's top left corner, its
-- turn in degrees, and the screen's size. Worked out from the page's own place on its sheet (1920 by 1080 page
-- pixels) and the sheet's place on its full-screen layer: the sheet is shown through the whole winners' moment, the
-- hidden card is not, and a hidden card's own AbsolutePosition and AbsoluteSize were stale (the first recording,
-- 2026-11-22). Measured from the layer's own corner: Roblox counts AbsolutePosition from under its top bar (58 px
-- down), so the sheet's own number put the copy that much too high (both recordings).
local function rectangle()
	local page = realPage()
	local results = page and page.Parent
	local sheet = results and results.Parent
	local layer = sheet and sheet:FindFirstAncestorWhichIsA("LayerCollector")
	if layer and sheet:IsA("GuiObject") and sheet.AbsoluteSize.X > 0 then
		local scale = sheet.AbsoluteSize.X / sheet.Size.X.Offset
		local fit = page:FindFirstChild("Fit")
		local size = Vector2.new(page.Size.X.Offset, page.Size.Y.Offset) * (fit and fit.Scale or 1)
		local at = Vector2.new(results.Position.X.Offset + page.Position.X.Offset, results.Position.Y.Offset + page.Position.Y.Offset)
			+ (Vector2.new(0.5, 0.5) - page.AnchorPoint) * size
		return sheet.AbsolutePosition - layer.AbsolutePosition + at * scale, size.Y * scale, page.Rotation, layer.AbsoluteSize
	end
	local screen = workspace.CurrentCamera.ViewportSize -- no results card (a test in Edit): its spot on a sheet fitted to the height
	return Vector2.new(screen.X / 2 + 600 / 1080 * screen.Y, 490 / 1080 * screen.Y), 900 / 1080 * screen.Y, 0, screen
end
-- The card on the lens, in the camera's own frame: square to it, its front to the camera, its height filling the
-- real card's. `fov`: this frame's field of view, from the scene: the scene writes the camera after this step, so
-- the camera itself still holds the flying camera's wider lens here (the second recording, 2026-11-22: the copy
-- landed 1.5 times too big, 70 degrees against the scene's 50).
local function onLens(st, fov)
	local middle, tall, turn, screen = rectangle()
	local tanHalf = math.tan(math.rad(fov / 2))
	local function along(pixel) -- the direction through a pixel, at a depth of 1
		return Vector3.new((pixel.X / screen.X * 2 - 1) * tanHalf * screen.X / screen.Y, -(pixel.Y / screen.Y * 2 - 1) * tanHalf, -1)
	end
	local up = Vector2.new(math.sin(math.rad(turn)), -math.cos(math.rad(turn))) * tall / 2 -- to the card's top edge on screen
	local depth = st.height / (along(middle + up) - along(middle - up)).Magnitude
	return CFrame.new(along(middle) * depth) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.rad(turn))
end

-- How much the card is in both hands `t` seconds after 1st's light: 1 until the right hand draws it back for the throw
-- (SHOW.take), 0 once it stands on that hand (SHOW.taken).
local function both(st, t)
	return 1 - st.kit.ease(math.clamp((t - SHOW.take) / (SHOW.taken - SHOW.take), 0, 1))
end
-- The card in both hands (Alan on the first recording: "not holding it symmetrically with both hands placed on
-- either side"). Its place comes from the body alone, so it is the same on every body: read at the belly, its top
-- leaning READ_TILT away; up in front of the face over the snap; over the head, its bottom edge clear of it; then
-- (SHOW.down to SHOW.shown) down in front of the face again to the chest, its top edge under the chin, where it is
-- shown until the throw (Alan's pick, 2026-11-22: both hands until the throw). `chest`, `head`: where those two
-- parts are. Returns the card and the point half way between the two hands' grips (GRIP of its height up its side
-- edges).
local function held(st, chest, head, t)
	local kid, h, torso, skull = st.kid, st.height, st.chest.Size, st.head.Size
	local snap = st.kit.ease(math.clamp((t - st.marks.Snap) / 0.4, 0, 1)) -- 0: reading, 1: held up
	local down = st.kit.ease(math.clamp((t - SHOW.down) / (SHOW.shown - SHOW.down), 0, 1)) -- 1: shown at the chest
	local flip = 1 - st.kit.ease(math.clamp((t - st.marks.Snap) / 0.35, 0, 1)) -- 1: the front to the kid (reading)
	local tilt = math.rad(READ_TILT) * flip
	local up = chest.UpVector * math.cos(tilt) + chest.LookVector * math.sin(tilt)
	local look = CFrame.fromAxisAngle(up, math.pi * flip) * (chest.LookVector * math.cos(tilt) - chest.UpVector * math.sin(tilt))
	local top = chest:PointToObjectSpace(head.Position).Y + skull.Y / 2 -- the top of the head, above the chest's middle
	local read = chest * Vector3.new(0, -0.26 * torso.Y, -torso.Z / 2 - 0.1 * kid)
	local lift = chest * Vector3.new(0, top - 0.3 * skull.Y, -skull.Z / 2 - 0.2 * kid)
	local high = chest * Vector3.new(0, top + 0.01 * kid + GRIP.high * h, -0.03 * kid)
	local show = chest * Vector3.new(0, top - skull.Y - 0.01 * kid - (1 - GRIP.show) * h, -torso.Z / 2 - 0.08 * kid)
	local grip, share -- one smooth curve through three points each way
	if down > 0 then
		grip, share = high:Lerp(lift, down):Lerp(lift:Lerp(show, down), down), GRIP.high + (GRIP.show - GRIP.high) * down
	else
		grip, share = read:Lerp(lift, snap):Lerp(lift:Lerp(high, snap), snap), GRIP.read + (GRIP.high - GRIP.read) * snap
	end
	local middle = grip + up * (0.5 - share) * h
	return CFrame.lookAt(middle, middle + look, up), grip
end
-- Each hand onto its side edge of the card, level with the other (from RunService.PreSimulation: the clip has posed
-- the body for this frame; `at`: where a part is by that pose). The hand's middle sits a little outside the edge.
-- From SHOW.take the right arm is let back to the clip, which draws it back for the throw, and the left hand follows
-- the card's edge for LET_GO seconds as it lets go.
function bend(st, joints, at)
	if not st.who.model:IsDescendantOf(game) then
		if st.bent then st.bent:Disconnect() end
		return
	end
	local t = math.max(st.since or 0, 0)
	local two = both(st, t)
	if two <= 0 then return end
	local chest = at(st.chest)
	local _, grip = held(st, chest, at(st.head), t)
	for side, arm in st.arms do
		local target = grip + chest.RightVector * arm.sign * (st.height * 340 / 900 + arm.hand.Size.X * 0.2)
		local weight = two
		if side == "Left" and t > SHOW.take and st.gripAt then
			target = st.card.CFrame * Vector3.new(-st.gripAt.X, st.gripAt.Y, 0)
			weight = 1 - st.kit.ease(math.clamp((t - SHOW.take) / LET_GO, 0, 1))
		end
		st.kit.bendArm(joints, at, arm.upper, arm.lower, arm.hand, target, (at(arm.upper) * joints[arm.lower].c0).Position, weight)
	end
end
-- In the hand `t` seconds after 1st's light. In both hands: `held`. From SHOW.take it goes with the right hand,
-- which holds its side edge at first and has it standing on the hand (its bottom edge on the hand, as in the throw
-- Alan called fine) by SHOW.taken: the hand's place on the card glides from the one to the other while the arm
-- sweeps back, so the card is on the hand all the way. Never through the head (bodies' heads and reaches differ):
-- where the card's plane cuts the head, the card moves out sideways or up, whichever is less, by the overlap.
local function inHand(st, t)
	local hand, chest, head = st.arms.Right and st.arms.Right.hand, st.chest, st.head
	if not hand or not chest then return nil end
	local two = both(st, t)
	if two >= 1 and head then
		local card = held(st, chest.CFrame, head.CFrame, t)
		st.gripAt = card:PointToObjectSpace(hand.Position) -- the right hand on the card, for the take
		return card
	end
	local stand = Vector3.new(0, -(st.height / 2 + hand.Size.Y / 2), 0)
	local turn = CFrame.lookAt(Vector3.zero, chest.CFrame.LookVector, chest.CFrame.UpVector)
	local at = turn + (hand.Position - turn * stand:Lerp(st.gripAt or stand, two))
	if head then
		local c = at:PointToObjectSpace(head.Position)
		local r = math.max(head.Size.X, head.Size.Y) * 0.55 -- a little past its box
		local cut = r * r - c.Z * c.Z
		if cut > 0 then
			cut = math.sqrt(cut)
			local w, h = st.height * 340 / 900, st.height / 2
			local side, rise = w + cut - math.abs(c.X), h + cut - math.abs(c.Y)
			if side > 0 and rise > 0 then
				at *= side < rise and CFrame.new(c.X > 0 and -side or side, 0, 0) or CFrame.new(0, c.Y > 0 and -rise or rise, 0)
			end
		end
	end
	return at
end

function APlus.step(st, since, shot, _steady, _winners, fov)
	local card = st.card
	st.since = since -- for `bend`
	if since < 0 or st.swapped then return end
	st.face.Enabled, st.back.Enabled = true, true
	if not st.flapped and since >= st.marks.Snap + FLAP then
		st.flapped = true
		if since < st.marks.Snap + FLAP + 0.3 then st.kit.Audio.play("aPlusFlap") end
	end
	local flown = since - st.marks.Release
	if flown < 0 then
		local at = inHand(st, since)
		if at then card.CFrame = at end
		return
	end
	st.from = st.from or shot:ToObjectSpace(card.CFrame) -- where it left the hand, from the lens
	local to = onLens(st, fov or workspace.CurrentCamera.FieldOfView)
	if flown < FLIGHT then
		local s = flown / FLIGHT
		card.CFrame = shot * (st.from.Rotation:Lerp(to.Rotation, st.kit.ease(math.min(s * 1.4, 1))) + st.from.Position:Lerp(to.Position, s))
		st.face.LightInfluence = 1 - s
		return
	end
	card.CFrame, st.face.LightInfluence = shot * to, 0
	if not st.landed then
		st.landed = true
		if flown < 0.3 then st.kit.Audio.play("aPlusSlap") end
	end
	-- the real card is up: it takes over (the copy stays one frame under it, so nothing blinks)
	local page = realPage()
	if page and shown(page) then
		if st.seenReal then
			st.swapped = true
			card.Transparency, st.face.Enabled, st.back.Enabled = 1, false, false
		end
		st.seenReal = true
	end
end

function APlus.camera(st, steady, t, height)
	return st.kit.jolted(steady, t - st.marks.Release - FLIGHT, height)
end

-- The lens is the card's from the landing until the real card has taken over: the name plates and the Menu tag go.
function APlus.covered(st, t)
	return t >= st.marks.Release + FLIGHT and not st.swapped
end

return APlus
