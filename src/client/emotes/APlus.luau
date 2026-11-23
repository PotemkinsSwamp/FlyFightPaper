-- A+, a 1st-place emote (docs/workshop/emotes/a-plus.md; card OK'd by Alan 2026-11-22). A smug show-off: the kid
-- reads their report card, holds it up over the head, shows it to both sides, holds it beside the face, then slaps it
-- at the camera: it lands flat on the lens exactly where the real report card comes up, and the kid gloats beside it
-- until the camera leaves, when the real card takes its place in the same frame (Alan: "it should line up perfectly").
-- The body is the clip APlus (tools/emote_cuts/a-plus.lua). The card is a look-alike of the real one (Alan: "very
-- similar to the actual report card ... the text on it should be kind of blurry and hard to read"): a copy of the
-- real card's page as it is when the winners' moment starts, its printed words and pictures kept, every filled-in
-- word (names, numbers, grades, the note, the place, the pocket money, the level) hidden under a faint ink scribble
-- of its length. Its back is plain paper. It stands on the right hand (its bottom edge on the hand) until Release,
-- flies FLIGHT seconds at the lens and lands square on the real card's rectangle; worked out every frame from where
-- the real card sits on this screen, at the depth where the card's own size fills it, so it fits any screen.
local Players = game:GetService("Players")

local APlus = {}
local TALL = 0.35 -- the card's height, in winner heights (about a tenth of the picture)
local GRIP_LEFT = 0.06 -- held in both hands: the card's middle to the kid's left of the right hand, winner heights
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
		for _, item in copy:GetDescendants() do
			if item:IsA("UIScale") then item:Destroy()
			elseif item:IsA("TextLabel") and item.Text ~= "" and not PRINTED[item.Name] and not item.Name:match("^Head") then
				local real = page:FindFirstChild(item.Name, true)
				if real then scribble(item, real) end
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
	return st
end

-- Where the real card sits on the screen: its middle and height in pixels, its turn in degrees.
local function rectangle(screen)
	local page = realPage()
	if page and page.AbsoluteSize.Y > 0 then
		return page.AbsolutePosition + page.AbsoluteSize / 2, page.AbsoluteSize.Y, page.AbsoluteRotation
	end
	return Vector2.new(screen.X / 2 + 600 / 1080 * screen.Y, 490 / 1080 * screen.Y), 900 / 1080 * screen.Y, 0 -- no results card (a test in Edit): its spot on a sheet fitted to the height
end
-- The card on the lens, in the camera's own frame: square to it, its front to the camera, its height filling the
-- real card's at this frame's field of view.
local function onLens(st, fov)
	local camera = workspace.CurrentCamera
	local screen = camera.ViewportSize
	local middle, tall, turn = rectangle(screen)
	local tanHalf = math.tan(math.rad(fov / 2))
	local depth = st.height / (2 * tanHalf * tall / screen.Y)
	local x = (middle.X / screen.X * 2 - 1) * tanHalf * screen.X / screen.Y * depth
	local y = -(middle.Y / screen.Y * 2 - 1) * tanHalf * depth
	return CFrame.new(x, y, -depth) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.rad(turn))
end

-- In the hand: `t` seconds after 1st's light.
local function inHand(st, t)
	local model = st.who.model
	local hand, chest = model:FindFirstChild("RightHand"), model:FindFirstChild("UpperTorso")
	if not hand or not chest then return nil end
	local kid = st.kit.Avatars.standing_height_studs / st.who.scale
	local flip = 1 - st.kit.ease(math.clamp((t - st.marks.Snap) / 0.35, 0, 1)) -- 1: the front to the kid (reading)
	local tilt = math.rad(READ_TILT) * flip
	local up = chest.CFrame.UpVector * math.cos(tilt) + chest.CFrame.LookVector * math.sin(tilt)
	local look = CFrame.fromAxisAngle(up, math.pi * flip) * (chest.CFrame.LookVector * math.cos(tilt) - chest.CFrame.UpVector * math.sin(tilt))
	local two = 1 - st.kit.ease(math.clamp((t - 5.0) / 0.6, 0, 1)) -- both hands until the right one takes it beside the face
	local middle = hand.Position + up * (hand.Size.Y / 2 + st.height / 2) - chest.CFrame.RightVector * GRIP_LEFT * kid * two
	local at = CFrame.lookAt(middle, middle + look, up)
	-- Never through the head (bodies' heads and reaches differ): where the card's plane cuts the head, the card moves
	-- out sideways or up, whichever is less, by the overlap; it still sits on the hand up to half its width.
	local head = model:FindFirstChild("Head")
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
	local to = onLens(st, fov)
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
