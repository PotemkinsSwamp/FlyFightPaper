-- A friend's gift arrives (docs/plan/GIFT-PLAN.md; Alan's story, docs/playtests/2026-11-13-gift-a-friend.md). Over the
-- main menu the board's own pinned plane pops its pin, flies right, turns round and comes at you getting bigger, then
-- away over the top; the wrapped box falls in and bounces; a sticky note slides up: who sent it and Open it!. Opening
-- pops the lid off and the gift rises out of the box on its rays (each ray its own piece: every other one moves out
-- while its neighbours move in, with a bounce, as the ring turns). Thanks! brings the next gift out of the open box;
-- after the last one the plane flies back to its pin.
-- The server lists unseen gifts in the player's GiftInbox attribute (JSON [{from, key}]) and drops one on "giftSeen".
-- Everything drawn is worked out from the time and from when the taps happened, so a held time shows a still.
-- Studio: the "Dev: send me a gift" button (DevTools), or workspace DevGiftMoment = product keys with commas between
-- ("xp_boost_60m,paper_pack_5000"), plays pretend gifts (GiftMoment.pretend); DevGiftTime holds the moment at that many
-- seconds and does the taps by itself (tools/film_gift.py).
-- Sounds are ones the game already has: the paper whoosh as the plane passes over you and comes back, the box thump
-- as it lands, the backpack's ding and coin as it opens, the coin again as each later gift comes out; and a shine as
-- each gift rises onto its rays. The music is turned right down while the moment is up (Root MusicQuiet, Audio).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local ShopScreen = require(script.Parent.ShopScreen)
local Audio = require(script.Parent.Audio)
local GiftMoment = {}

-- Seconds. The plane wiggles off its pin until LIFT and is over the top by AWAY. The box leaves the top at DROP and
-- has bounced to rest by LAND. After the Open tap the lid comes off at LID; after any tap the next gift starts rising
-- at RISE. After the last Thanks the plane starts back at BACK, is home at HOME, and the moment ends at DONE.
local LIFT, AWAY, DROP, LAND, LID, RISE = 0.45, 2.9, 2.75, 3.45, 0.22, 0.25
local BACK, HOME, DONE = 0.35, 1.6, 2
local SWAP = 1 -- seconds between the rays trading places
-- Sheet units (1920 x 1080): where a gift floats on its rays; the box at rest (middle and size); the note's middle.
local SPOT_X, SPOT_Y, ITEM = 960, 312, 280
local BOX_X, BOX_Y, BOX_W, BOX_H = 960, 520, 300, 287
local NOTE_Y = 870
local PIC_W, PIC_H = 644, 617 -- the gift box picture's own pixels (assets/ui/shop/source/icon-gift-box.png)
local K = BOX_W / PIC_W -- sheet units per picture pixel
local NOSE = 40 -- the plane picture's nose points this many degrees above "to the right"
-- Two of the rays picture's sixteen strokes (its top and bottom ones): x, y, width, height in its pixels.
local STROKES = { { 479, 0, 49, 150 }, { 475, 864, 54, 152 } }

local function lerp(a, b, u) return a + (b - a) * u end
local function unit(u) return math.clamp(u, 0, 1) end
local function smooth(u) u = unit(u); return u * u * (3 - 2 * u) end
local function back(u) u = unit(u) - 1; return 1 + u * u * (2.70158 * u + 1.70158) end -- overshoots, settles
local function pop(u) u = unit(u); return (1 - u) * (1 + 2.2 * u) end -- swells, then shrinks to nothing
local function spring(v) return v >= 0 and math.exp(-9 * v) * math.cos(22 * v) or 0 end -- a kick that rings out
local function bounce(u) -- falls and bounces twice
	u = unit(u)
	if u < 0.55 then return (u / 0.55) ^ 2 end
	if u < 0.85 then local v = (u - 0.7) / 0.15; return 1 - 0.12 * (1 - v * v) end
	local v = (u - 0.925) / 0.075; return 1 - 0.04 * (1 - v * v)
end
-- -1..1: the two sets of rays trade places every SWAP seconds, overshooting and bouncing as they arrive.
local function swap(t)
	local f = t / SWAP % 1
	return (math.floor(t / SWAP) % 2 == 0 and 1 or -1) * (2 * math.exp(-6 * f) * math.cos(11 * f) - 1)
end
-- A smooth curve through a path's points { x, y, size } (Catmull-Rom); q runs from 0 to #path - 1.
local function along(path, q)
	q = math.clamp(q, 0, #path - 1.0001)
	local i = math.floor(q) + 1
	local f, b, c, a, d = q - (i - 1), path[i], path[i + 1], path[i - 1], path[i + 2]
	local out = {}
	for k = 1, 3 do
		local p0, p3 = a and a[k] or 2 * b[k] - c[k], d and d[k] or 2 * c[k] - b[k]
		out[k] = 0.5 * (2 * b[k] + (c[k] - p0) * f + (2 * p0 - 5 * b[k] + 4 * c[k] - p3) * f * f + (3 * b[k] - p0 - 3 * c[k] + p3) * f * f * f)
	end
	return out[1], out[2], out[3]
end
local function place(inst, x, y, w, h, rot)
	inst.Position, inst.Rotation = UDim2.fromOffset(x, y), rot or 0
	if w then inst.Size = UDim2.fromOffset(w, h) end
end

-- api = { seen = function(n), board = the menu board (its .plane and .pin) }
function GiftMoment.start(api)
	local player = Players.LocalPlayer
	local board = api.board
	local cover, sheet = PaperUI.screen(player:WaitForChild("PlayerGui"), "GiftMoment", {})
	-- Over the menus, under the unlock backpack (25); the menu underneath can't be clicked.
	cover.Parent.DisplayOrder, cover.Active, cover.BackgroundTransparency = 24, true, 1
	-- The darkening is its own layer (the cover's own colour didn't show over the menu board in Play, 2026-11-13).
	local dim = Instance.new("Frame")
	dim.Name, dim.Size, dim.BackgroundColor3, dim.BorderSizePixel, dim.ZIndex = "Dim", UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 0, 0
	dim.Parent, sheet.ZIndex = cover, 1
	local image, words = PaperUI.image, PaperUI.words
	local shop = Assets.shop

	-- Back to front: rays, the box's dark inside, the gift, the box, its lid, the note, the plane and its pin.
	local rays = {}
	for i = 1, 16 do
		local stroke = STROKES[i % 2 + 1]
		local ray = image(sheet, "Ray" .. i, shop.rays, 0, 0, stroke[3], stroke[4])
		ray.ImageRectOffset, ray.ImageRectSize, ray.ImageTransparency = Vector2.new(stroke[1], stroke[2]), Vector2.new(stroke[3], stroke[4]), 0.1
		rays[i] = ray
	end
	-- The open box is the box picture in parts: `group` is a box x0,y0..x1,y1 of the picture (its pixels) that moves
	-- as one; each part is a piece of that, minus everything to the right of its line a -> b ("right" as you walk
	-- from a to b: left-to-right hides what's below). A see-through gradient with a hard step makes the slanted cut:
	-- its direction turns in screen pixels and its 0..1 runs along the line through the part's middle (measured in
	-- Studio, 2026-11-13).
	local function group(name, z, gx0, gy0, gx1, gy1, parts)
		local frame = Instance.new("Frame")
		frame.Name, frame.BackgroundTransparency, frame.AnchorPoint, frame.ZIndex, frame.Parent = name, 1, Vector2.new(0.5, 0.5), z, sheet
		for i, p in parts do
			local x0, y0, x1, y1, ax, ay, bx, by = table.unpack(p)
			local w, h = x1 - x0, y1 - y0
			local part = Instance.new("ImageLabel")
			part.Name, part.Image, part.BackgroundTransparency, part.ScaleType = name .. i, shop.iconGiftBox, 1, Enum.ScaleType.Stretch
			-- (p[9..12]: show this other box of the picture there instead; p[13], p[14]: shade it, far side to cut edge)
			part.ImageRectOffset = Vector2.new(p[9] or x0, p[10] or y0)
			part.ImageRectSize = p[9] and Vector2.new(p[11] - p[9], p[12] - p[10]) or Vector2.new(w, h)
			part.Position = UDim2.fromScale((x0 - gx0) / (gx1 - gx0), (y0 - gy0) / (gy1 - gy0))
			part.Size, part.Parent = UDim2.fromScale(w / (gx1 - gx0), h / (gy1 - gy0)), frame
			local length = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
			local dx, dy = -(by - ay) / length, (bx - ax) / length -- across the line, towards the hidden side
			local at = ((ax - x0 - w / 2) * dx + (ay - y0 - h / 2) * dy) / math.min(w / math.abs(dx), h / math.abs(dy)) + 0.5
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = math.deg(math.atan2(dy, dx))
			gradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(at, 0),
				NumberSequenceKeypoint.new(at + 0.004, 1), NumberSequenceKeypoint.new(1, 1) })
			if p[13] then gradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, p[13]), ColorSequenceKeypoint.new(at, p[14]), ColorSequenceKeypoint.new(1, p[14]) }) end
			gradient.Parent = part
		end
		return frame
	end
	-- The lid's lower edge runs (0,286) -> (312,373) -> (644,277); its top face is (5,175) (333,87) (640,170) (312,258).
	-- The inside is the shape of the lid's top face, set down where the lid sat and a little narrower (the body is):
	-- its two far walls, plain cardboard off the box's sides, in shadow and darker the deeper you look.
	local grey = Color3.fromRGB
	local inside = group("Inside", 2, 0, 80, 644, 262, {
		{ 0, 80, 334, 262, 333, 87, 5, 175, 200, 390, 305, 560, grey(70, 70, 76), grey(170, 170, 170) },
		{ 332, 80, 644, 262, 640, 170, 333, 87, 325, 390, 440, 560, grey(52, 52, 58), grey(128, 128, 128) } })
	local item = image(sheet, "Item", shop.iconGiftBox, 0, 0, ITEM, ITEM)
	local body = group("Body", 4, 0, 270, 644, 617, { { 0, 270, 313, 617, 312, 373, 0, 286 }, { 311, 270, 644, 617, 644, 277, 312, 373 } })
	local lid = group("Lid", 5, 0, 0, 644, 374, { { 0, 0, 313, 374, 0, 286, 312, 373 }, { 311, 0, 644, 374, 312, 373, 644, 277 } })
	local box = image(sheet, "Box", shop.iconGiftBox, 0, 0, BOX_W, BOX_H) -- the whole box, while it's shut
	box.ScaleType = Enum.ScaleType.Stretch -- (it squashes as it lands)
	-- A part of the open box at the box's size k (1 = at rest), standing on the same floor: its middle px,py and
	-- size pw,ph in picture pixels.
	local function part(frame, px, py, pw, ph, k, dx, dy, rot)
		place(frame, BOX_X + (px - PIC_W / 2) * K * k + (dx or 0), BOX_Y + BOX_H / 2 * (1 - k) + (py - PIC_H / 2) * K * k + (dy or 0), pw * K * k, ph * K * k, rot)
	end
	-- The note: 1100 x 388 (the sticky's own shape); its tape covers the top ~118, its peeled corner the bottom right.
	-- Big words: a reward moment is read at a glance (lessons: 30 px+ on selling pieces).
	local note = image(sheet, "Note", Assets.ingame.stickyWide, 410, 676, 1100, 388)
	local title = words(note, "Title", "", 60, 112, 980, 68, 62)
	title.TextXAlignment = Enum.TextXAlignment.Center
	PaperUI.loud(title)
	PaperUI.fitWords(title, 980 * 0.96) -- (only a very long name gets smaller)
	local amount = words(note, "Amount", "", 60, 178, 980, 58, 50)
	amount.TextXAlignment = Enum.TextXAlignment.Center
	local shadow = image(sheet, "PlaneShadow", Assets.mainmenu.plane, 0, 0, 226, 195)
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	local plane = image(sheet, "Plane", Assets.mainmenu.plane, 0, 0, 226, 195)
	local pin = image(sheet, "PlanePin", Assets.hud.pinRed, 0, 0, 34, 34)
	item.ZIndex, box.ZIndex, note.ZIndex, shadow.ZIndex, plane.ZIndex, pin.ZIndex = 3, 4, 6, 7, 8, 9

	-- gifts: the ones shown so far, in order. taps: when Open and each Thanks happened (bye: the last Thanks).
	local playing, asked, started, filming, heard, shine = false, 0, nil, false, 0, "shine1"
	local gifts, taps = {}, { thanks = {} }
	local said, shownItem, seenHere = nil, nil, 0
	local fakes, fakeCount = {}, 0
	local home, pinHome, planeSize, pathOut, pathBack

	-- The next gift waiting: Studio's pretend ones first, then the inbox.
	local function nextGift()
		local key = table.remove(fakes, 1)
		if key and key ~= "" then
			fakeCount += 1
			return { from = "Test Friend" .. (fakeCount > 1 and " " .. fakeCount or ""), key = key, pretend = true }
		end
		if filming then return nil end
		local ok, inbox = pcall(function() return Http:JSONDecode(player:GetAttribute("GiftInbox") or "[]") end)
		-- seenHere: thanked here, not yet dropped by the server (its new list resets it). ponytail: a new gift arriving
		-- before the server drops a thanked one replays that one once; a gift id in the inbox fixes it if that ever matters.
		local gift = ok and type(inbox) == "table" and inbox[seenHere + 1]
		return type(gift) == "table" and type(gift.key) == "string" and gift or nil
	end
	local function now()
		local hold = RunService:IsStudio() and workspace:GetAttribute("DevGiftTime")
		return type(hold) == "number" and hold or os.clock() - started
	end

	-- Open it! (the note's button or the box itself), then Thanks! for each gift. A tap soon after the last one is
	-- ignored (a child's second tap lands on the same spot: design-theory 2.6).
	local function press()
		if not playing or not started or filming or taps.bye then return end
		local t = now()
		if not taps.open then
			if t > LAND + 0.4 then taps.open = t end
		elseif t > (taps.thanks[#taps.thanks] or taps.open) + 1 then
			if not gifts[#gifts].pretend then seenHere += 1; api.seen(1) end
			local more = nextGift()
			if more then table.insert(gifts, more); table.insert(taps.thanks, t) else taps.bye = t end
		end
	end
	local button = PaperUI.button(note, "Thanks", Assets.mainmenu.strip.green, "Thanks!", 400, 244, 300, 92, -1, press, 50)
	local openHit = Instance.new("TextButton")
	openHit.Name, openHit.Text, openHit.BackgroundTransparency, openHit.AnchorPoint = "OpenHit", "", 1, Vector2.new(0.5, 0.5)
	openHit.Position, openHit.Size = UDim2.fromOffset(BOX_X, BOX_Y), UDim2.fromOffset(BOX_W + 120, BOX_H + 20)
	openHit.ZIndex, openHit.Parent = 5, sheet
	openHit.Activated:Connect(function() if not taps.open then press() end end)

	local function draw(t)
		local bye = taps.bye and t >= taps.bye and t - taps.bye or nil -- seconds since the last Thanks
		local opened = taps.open ~= nil and t >= taps.open + LID
		local n = 0 -- Thanks so far
		for _, at in taps.thanks do if t >= at then n += 1 end end
		local tapped = n > 0 and taps.thanks[n] or taps.open -- the tap that brings the newest gift out
		local rising = tapped and t - tapped - RISE or -1 -- seconds since that gift started up
		dim.BackgroundTransparency = 1 - 0.72 * smooth(t / 0.7) * (bye and 1 - smooth((bye - 0.8) / 0.8) or 1)

		-- The plane: wiggles free as its pin pops off, flies its loop and away; at the end flies back and is pinned.
		local path, q
		if bye and bye >= BACK then
			path, q = pathBack, (#pathBack - 1) * (1 - (1 - unit((bye - BACK) / (HOME - BACK))) ^ 2)
		elseif t >= LIFT then
			path, q = pathOut, (#pathOut - 1) * unit((t - LIFT) / (AWAY - LIFT)) ^ 1.5
		end
		local x, y, s, turn = home.X, home.Y, 1 + 0.06 * smooth(t / LIFT), 6 * math.sin(unit(t / LIFT) * math.pi) * math.sin(t * 34)
		if path then
			x, y, s = along(path, q)
			local x1, y1 = along(path, math.max(q - 0.02, 0))
			local x2, y2 = along(path, math.min(q + 0.02, #path - 1))
			turn = math.deg(math.atan2(y2 - y1, x2 - x1)) + NOSE
		end
		plane.Visible = t < AWAY or path == pathBack
		shadow.Visible = plane.Visible
		place(plane, x, y, planeSize.X * s, planeSize.Y * s, turn)
		-- Its shadow falls further away the nearer it is to you (the bigger it is); none while it's pinned.
		local air = path == pathBack and 1 - smooth(q - (#path - 2)) or smooth(t / LIFT)
		local fall = math.max(75 * (s - 1), 10) * air
		place(shadow, x + fall * 0.5, y + fall * 0.8, planeSize.X * s, planeSize.Y * s, turn)
		shadow.ImageTransparency = math.min(0.5 + 0.07 * (s - 1), 0.9)
		local pinned = bye and back((bye - HOME) / 0.25) or pop(t / 0.3)
		pin.Visible = pinned > 0.01
		place(pin, pinHome.X, pinHome.Y - (bye and 0 or 26 * unit(t / 0.3)), 34 * pinned, 34 * pinned)

		-- The box, shut: falls in, squashes and bounces; waits with a shake and a hop now and then; squashes as you open it.
		box.Visible = t >= DROP and not opened
		openHit.Visible = t >= LAND and not taps.open
		if box.Visible then
			local u = (t - DROP) / (LAND - DROP)
			local by, rot = lerp(-180, BOX_Y, bounce(u)), -10 * (1 - unit(u / 0.55))
			local squash = 0.16 * math.exp(-((u - 0.55) / 0.07) ^ 2) + 0.07 * math.exp(-((u - 0.85) / 0.05) ^ 2)
			local idle = (t - LAND - 0.9) % 1.8
			if taps.open and t >= taps.open then
				squash, rot = 0.16 * math.sin((t - taps.open) / LID * math.pi), 5 * math.sin(t * 60)
			elseif t > LAND + 0.9 and idle < 0.5 then
				rot, by = 7 * math.sin(idle * 40) * (1 - idle / 0.5), by - 12 * math.sin(idle / 0.5 * math.pi)
			end
			place(box, BOX_X, by + BOX_H * squash / 2, BOX_W * (1 + squash), BOX_H * (1 - squash), rot)
		end
		-- Open: the lid flies off spinning; the box kicks as each gift comes out, and pops away after the last Thanks.
		body.Visible, inside.Visible = opened, opened
		local off = opened and t - taps.open - LID or -1
		lid.Visible = opened and off < 0.6
		if opened then
			local k = 1 + 0.08 * spring(n > 0 and rising or off)
			if bye then local u = unit((bye - 0.15) / 0.3); k *= (1 - u) * (1 + 0.8 * u) end
			body.Visible, inside.Visible = k > 0.01, k > 0.01
			part(body, 322, 443.5, 644, 347, k)
			part(inside, 322, 289, 644 * 0.91, 182, k)
			if lid.Visible then
				part(lid, 322, 187, 644, 374, 1, 420 * off, -1500 * off + 900 * off * off, 300 * off)
				for _, piece in lid:GetChildren() do piece.ImageTransparency = smooth((off - 0.3) / 0.3) end
			end
		end

		-- The gift: rises out of the box; at Thanks it comes at you and is gone, and the next one rises.
		local index, leave = 0, nil
		if rising >= 0 then index = n + 1 elseif n > 0 then index, leave = n, (t - taps.thanks[n]) / RISE end
		if bye then leave = bye / RISE end
		local gift = gifts[index]
		item.Visible = gift ~= nil and (leave or 0) < 1
		if item.Visible then
			if shownItem ~= index then shownItem = index; item.Image = (ShopScreen.itemLook(gift.key)) end
			local up = leave and 1 or back(rising / 0.5)
			local size = ITEM * lerp(0.25, 1, up) * (1 + 0.6 * (leave or 0))
			place(item, SPOT_X, lerp(BOX_Y - 10, SPOT_Y, up) + 8 * math.sin(t * 2.6) * (rising >= 0 and smooth(rising) or 1), size, size)
			item.ImageTransparency = unit(leave or 0)
		end
		-- Its rays: the ring turns; every other ray moves out and grows while its neighbours move in and shrink, then
		-- they trade, with a bounce; the ring dips as one gift goes and springs back with the next.
		local grow = taps.open and back((t - taps.open - RISE) / 0.5) or 0
		if n > 0 then grow *= 1 - 0.35 * math.sin(unit((t - taps.thanks[n]) / 0.6) * math.pi) end
		if bye then grow *= 1 - smooth(bye / 0.3) end
		local trade = swap(t)
		for i, ray in rays do
			ray.Visible = grow > 0.02
			local side = i % 2 == 0 and 1 or -1
			local angle = math.rad(i * 22.5 + t * 22)
			local far = (226 + side * 20 * trade + 5 * math.sin(t * 1.7 + i * 2.4)) * grow
			local k = 0.546 * (1 + 0.16 * side * trade) * grow
			place(ray, SPOT_X + math.sin(angle) * far, SPOT_Y - math.cos(angle) * far, ray.ImageRectSize.X * k, ray.ImageRectSize.Y * k, math.deg(angle))
		end

		-- The note: slides up once the box has landed; hops as its words change; slides away at the end.
		local ny = lerp(1320, NOTE_Y, back((t - LAND - 0.1) / 0.45))
		if n > 0 then ny -= 12 * math.sin(unit(rising / 0.3) * math.pi) end
		if bye then ny = lerp(NOTE_Y, 1320, smooth(bye / 0.35)) end
		place(note, 960, ny)
		local says = bye and said or index -- (0: not opened yet)
		if says ~= said then
			said = says
			local shown = gifts[math.max(says, 1)]
			local _, what = ShopScreen.itemLook(shown.key)
			title.Text = "A gift from " .. tostring(shown.from) .. "!"
			amount.Text = says == 0 and "What's inside?" or what
			button.Label.Text = says == 0 and "Open it!" or "Thanks!"
		end
	end

	-- Plays the sounds whose moments fall between the last frame's time and this one's.
	-- (The shine rings for seconds: it fades out when the next gift's starts and at the last Thanks.)
	local ringing, ringId
	local function hush()
		if ringing and ringing.IsPlaying and ringing.SoundId == ringId then
			game:GetService("TweenService"):Create(ringing, TweenInfo.new(0.4), { Volume = 0 }):Play()
		end
		ringing = nil
	end
	local function sounds(t)
		local function at(when, name)
			if not when or heard >= when or t < when then return end
			if name == "hush" or name == shine then hush() end
			local sound = name ~= "hush" and Audio.play(name)
			if name == shine and sound then ringing, ringId = sound, sound.SoundId end
		end
		at(taps.bye, "hush")
		at(2, "flight"); at(DROP + 0.55 * (LAND - DROP), "land")
		at(taps.open and taps.open + LID, "ding"); at(taps.open and taps.open + LID + 0.25, "purchase")
		at(taps.open and taps.open + RISE + 0.1, shine)
		for _, thanks in taps.thanks do at(thanks + RISE, "purchase"); at(thanks + RISE + 0.1, shine) end
		at(taps.bye and taps.bye + BACK, "flight")
		heard = t
	end

	-- The board's plane is pinned: ours takes its place (same spot, same size) and the moment starts.
	local function begin()
		started, heard = os.clock(), 0
		Root:SetAttribute("MusicQuiet", true)
		local at, size, pinAt = board.plane.Position, board.plane.Size, board.pin.Position
		home, planeSize, pinHome = Vector2.new(at.X.Offset, at.Y.Offset), Vector2.new(size.X.Offset, size.Y.Offset), Vector2.new(pinAt.X.Offset, pinAt.Y.Offset)
		-- { x, y, size }: off the pin the way its nose points, right, round the top of a loop, at you, up and away.
		pathOut = { { home.X, home.Y, 1.06 }, { home.X + 146, home.Y - 122, 1 }, { 1680, 340, 0.95 }, { 1790, 235, 0.95 }, { 1700, 140, 1.05 },
			{ 1470, 210, 1.5 }, { 1160, 430, 2.6 }, { 940, 540, 3.7 }, { 880, 260, 4.9 }, { 960, -700, 6.2 } }
		pathBack = { { 960, -700, 6.2 }, { 1010, 200, 4.2 }, { 1060, 540, 2.6 }, { 1130, 700, 1.7 }, { home.X - 115, home.Y + 96, 1.2 }, { home.X, home.Y, 1 } }
		board.plane.Visible, board.pin.Visible = false, false
		filming = RunService:IsStudio() and type(workspace:GetAttribute("DevGiftTime")) == "number"
		if filming then -- the taps happen by themselves, every pretend gift in turn
			taps.open = LAND + 1.4
			local at = taps.open + 2.3
			for more in nextGift do table.insert(gifts, more); table.insert(taps.thanks, at); at += 2.3 end
			taps.bye = at
			workspace:SetAttribute("DevGiftEnds", at + DONE)
		end
		sheet.Visible = true
	end
	local function finish()
		playing, filming, cover.Visible = false, false, false
		Root:SetAttribute("MusicQuiet", false)
		board.plane.Visible, board.pin.Visible = true, true
		GiftMoment.offer()
	end
	RunService.RenderStepped:Connect(function()
		if not playing then return end
		if not started then -- (the board's plane flies in and is pinned each time the board shows: wait for its pin)
			if os.clock() - asked < 0.5 or board.pin.Size.X.Offset < 33 then return end
			begin()
		end
		local t = now()
		draw(t)
		if taps.bye and t - taps.bye >= DONE then finish() elseif not filming then sounds(t) end
	end)

	-- Plays the gifts waiting, if any (MenuController calls this when the main menu shows).
	function GiftMoment.offer()
		if playing then return end
		local gift = nextGift()
		if not gift then return end
		gifts, taps, said, shownItem = { gift }, { thanks = {} }, nil, nil
		playing, asked, started = true, os.clock(), nil
		dim.BackgroundTransparency, sheet.Visible, cover.Visible = 1, false, true
	end
	player:GetAttributeChangedSignal("GiftInbox"):Connect(function() seenHere = 0 end)
	-- Studio: lines up pretend gifts (product keys with commas between). They play now if the main menu is showing,
	-- otherwise when it next shows; says which.
	function GiftMoment.pretend(keys, sound) -- (sound: which shine to try, 1-3, while Alan picks one)
		fakes, fakeCount, shine = keys:split(","), 0, "shine" .. (sound or 1)
		if board.frame.Visible then GiftMoment.offer() end
		return board.frame.Visible
	end
	if RunService:IsStudio() then
		local function read()
			local keys = workspace:GetAttribute("DevGiftMoment")
			if type(keys) == "string" then GiftMoment.pretend(keys) end
		end
		workspace:GetAttributeChangedSignal("DevGiftMoment"):Connect(read)
		read()
	end
	function GiftMoment.playing() return playing end
end

return GiftMoment
