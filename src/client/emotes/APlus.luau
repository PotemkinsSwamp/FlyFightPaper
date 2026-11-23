-- A+, a 1st-place emote (docs/workshop/emotes/a-plus.md; card OK'd by Alan 2026-11-22). A smug show-off: the kid
-- reads their report card, holds it up over the head, shows it to both sides, holds it beside the face, then slaps it
-- at the camera: it lands flat on the lens exactly where the real report card comes up, and the kid gloats beside it
-- until the camera leaves, when the real card takes its place in the same frame (Alan: "it should line up perfectly").
-- The body is the clip APlus (tools/emote_cuts/a-plus.lua). The card is a look-alike of the real one (Alan: "very
-- similar to the actual report card ... the text on it should be kind of blurry and hard to read"): a copy of the
-- real card's page as it is when the winners' moment starts, its printed words and pictures kept, every filled-in
-- word (names, numbers, grades, the note, the place, the pocket money, the level) hidden under a faint ink scribble
-- of its length. Its back is plain paper. It is held in both hands, one on each side edge (the arms are bent onto it
-- on every body), then stands on the right hand (its bottom edge on the hand) until Release, flies FLIGHT seconds at
-- the lens and lands square on the real card's rectangle; worked out every frame from where
-- the real card sits on this screen, at the depth where the card's own size fills it, so it fits any screen.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local APlus = {}
local TALL = 0.35 -- the card's height, in winner heights (about a tenth of the picture)
local GRIP = { read = 0.45, high = 0.12 } -- held in both hands: how far up its side edges the hands are (share of its height), reading and held up
local bend -- (below)
local READ_TILT = 25 -- reading: the top leans this many degrees away from the kid
local FLIGHT = 0.4 -- release to the lens
local MARKS = { Snap = 2.0, Release = 7.4 } -- the clip's own (its draft's attributes win)
local PAPER = Color3.fromRGB(240, 228, 206) -- the card picture's paper, for its back and edge
local PRINTED = { School = true, Title = true, NoteLabel = true, PocketLabel = true, BoxLabel = true }
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

-- A faint ink scribble over a filled-in word, as long as its words were (`real`: the same label on the real card,
-- which has been laid out): a zig-zag along the middle of its box.
local function scribble(label, real)
	local box = real.Size.X.Offset
	local h = real.Size.Y.Offset
	local w = math.min(real.TextBounds.X > 0 and real.TextBounds.X or #real.Text * h * 0.45, box)
	if w < 2 or h < 2 then return end
	local x0 = label.TextXAlignment == Enum.TextXAlignment.Center and (box - w) / 2 or label.TextXAlignment == Enum.TextXAlignment.Right and box - w or 0
	local points, step, up = {}, math.max(h * 0.18, 3), false
	for x = x0, x0 + w, step do
		table.insert(points, Path2DControlPoint.new(UDim2.fromOffset(x, h * (up and 0.32 or 0.62))))
		up = not up
	end
	local path = Instance.new("Path2D")
	path.Color3, path.Thickness, path.Parent = label.TextColor3, math.max(h * 0.07, 1.5), label
	path:SetControlPoints(points)
	label.TextTransparency = 1
end
-- The look-alike's face: the real page copied, filled-in words scribbled over.
local function lookAlike(part)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.CanvasSize, gui.Enabled, gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 900), false, 1
	local page = realPage()
	if page then
		local copy = page:Clone()
		-- (a word's crayon look is three child copies of it, which draw its letters: they are emptied with it)
		for _, item in copy:GetDescendants() do
			if item:IsA("UIScale") then item:Destroy()
			elseif item:IsA("TextLabel") and not item.Parent:IsA("TextLabel") and item.Text ~= "" and not PRINTED[item.Name] and not item.Name:match("^Head") then
				local real = page:FindFirstChild(item.Name, true)
				if real then scribble(item, real) end
				item.Text = ""
				for _, inner in item:GetDescendants() do if inner:IsA("TextLabel") then inner.Text = "" end end
			end
		end
		copy.AnchorPoint, copy.Position, copy.Size, copy.Rotation, copy.Visible = Vector2.zero, UDim2.new(), UDim2.fromScale(1, 1), 0, true
		copy.Parent = gui
	end
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
	st.card, st.face = card, lookAlike(card)
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

-- How much the card is in both hands `t` seconds after 1st's light: 1 until the right hand takes it alone.
local function both(st, t)
	return 1 - st.kit.ease(math.clamp((t - 5.0) / 0.6, 0, 1))
end
-- The card in both hands (Alan on the first recording: "not holding it symmetrically with both hands placed on
-- either side"). Its place comes from the body alone, so it is the same on every body: read at the belly, its top
-- leaning READ_TILT away; up in front of the face over the snap; then over the head, its bottom edge clear of it.
-- `chest`, `head`: where those two parts are. Returns the card, the point half way between the two hands' grips
-- (GRIP of its height up its side edges) and the card's up direction.
local function held(st, chest, head, t)
	local kid, h, torso, skull = st.kid, st.height, st.chest.Size, st.head.Size
	local snap = st.kit.ease(math.clamp((t - st.marks.Snap) / 0.4, 0, 1)) -- 0: reading, 1: held up
	local flip = 1 - st.kit.ease(math.clamp((t - st.marks.Snap) / 0.35, 0, 1)) -- 1: the front to the kid (reading)
	local tilt = math.rad(READ_TILT) * flip
	local up = chest.UpVector * math.cos(tilt) + chest.LookVector * math.sin(tilt)
	local look = CFrame.fromAxisAngle(up, math.pi * flip) * (chest.LookVector * math.cos(tilt) - chest.UpVector * math.sin(tilt))
	local top = chest:PointToObjectSpace(head.Position).Y + skull.Y / 2 -- the top of the head, above the chest's middle
	local read = chest * Vector3.new(0, -0.26 * torso.Y, -torso.Z / 2 - 0.1 * kid)
	local lift = chest * Vector3.new(0, top - 0.3 * skull.Y, -skull.Z / 2 - 0.2 * kid)
	local high = chest * Vector3.new(0, top + 0.01 * kid + GRIP.high * h, -0.03 * kid)
	local grip = read:Lerp(lift, snap):Lerp(lift:Lerp(high, snap), snap) -- one smooth curve through the three
	local middle = grip + up * (0.5 - (GRIP.read + (GRIP.high - GRIP.read) * snap)) * h
	return CFrame.lookAt(middle, middle + look, up), grip, up
end
-- Each hand onto its side edge of the card, level with the other (from RunService.PreSimulation: the clip has posed
-- the body for this frame; `at`: where a part is by that pose). The hand's middle sits a little outside the edge.
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
	for _, arm in st.arms do
		local target = grip + chest.RightVector * arm.sign * (st.height * 340 / 900 + arm.hand.Size.X * 0.2)
		st.kit.bendArm(joints, at, arm.upper, arm.lower, arm.hand, target, (at(arm.upper) * joints[arm.lower].c0).Position, two)
	end
end
-- In the right hand alone (the throw, which Alan called fine): its bottom edge stands on the hand, turning with the
-- chest. Never through the head (bodies' heads and reaches differ): where the card's plane cuts the head, the card
-- moves out sideways or up, whichever is less, by the overlap; it still sits on the hand up to half its width.
local function onHand(st)
	local hand, chest, head = st.arms.Right and st.arms.Right.hand, st.chest, st.head
	if not hand or not chest then return nil end
	local up = chest.CFrame.UpVector
	local middle = hand.Position + up * (hand.Size.Y / 2 + st.height / 2)
	local at = CFrame.lookAt(middle, middle + chest.CFrame.LookVector, up)
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
-- In the hand `t` seconds after 1st's light: in both, in the right one, or on the way from the one to the other.
local function inHand(st, t)
	local two = both(st, t)
	local one = two < 1 and onHand(st) or nil
	if two <= 0 or not (st.chest and st.head) then return one end
	local card = held(st, st.chest.CFrame, st.head.CFrame, t)
	return one and one:Lerp(card, two) or card
end

function APlus.step(st, since, shot, _steady, _winners, fov)
	local card = st.card
	st.since = since -- for `bend`
	if since < 0 or st.swapped then return end
	st.face.Enabled = true
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
			card.Transparency, st.face.Enabled = 1, false
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
