-- A friend's gift arrives (docs/plan/GIFT-PLAN.md; look: Alan picked "plane delivery", 2026-11-13). Over the main menu
-- a paper plane swoops in from the left with the wrapped box hanging under it, lets go in the middle and climbs away;
-- the box drops and bounces, wiggles, bursts, and the gift pops out on rays; a sticky note slides up: who sent it, what
-- it is, and Thanks!. One gift at a time.
-- The server lists unseen gifts in the player's GiftInbox attribute (JSON [{from, key}]) and drops them on "giftSeen".
-- Studio: workspace DevGiftMoment = a product key plays a pretend gift; DevGiftTime holds the moment at that many
-- seconds (frame-by-frame filming).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local ShopScreen = require(script.Parent.ShopScreen)
local GiftMoment = {}

local function lerp(a, b, u) return a + (b - a) * u end
local function smooth(u) u = math.clamp(u, 0, 1); return u * u * (3 - 2 * u) end
local function back(u) u = math.clamp(u, 0, 1) - 1; return 1 + u * u * (2.70158 * u + 1.70158) end -- overshoots, settles
local function bounce(u) -- falls and bounces twice
	u = math.clamp(u, 0, 1)
	if u < 0.55 then return (u / 0.55) ^ 2 end
	if u < 0.85 then local v = (u - 0.7) / 0.15; return 1 - 0.12 * (1 - v * v) end
	local v = (u - 0.925) / 0.075; return 1 - 0.04 * (1 - v * v)
end

function GiftMoment.start(api)
	local player = Players.LocalPlayer
	local cover, sheet = PaperUI.screen(player:WaitForChild("PlayerGui"), "GiftMoment", {})
	-- Over the menus, under the unlock backpack (25); the menu underneath can't be clicked.
	cover.Parent.DisplayOrder, cover.Active, cover.BackgroundTransparency = 24, true, 1
	-- The darkening is its own layer (the cover's own colour didn't show over the menu board in Play, 2026-11-13).
	local dim = Instance.new("Frame")
	dim.Name, dim.Size, dim.BackgroundColor3, dim.BorderSizePixel, dim.ZIndex = "Dim", UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 0, 0
	dim.Parent, sheet.ZIndex = cover, 1
	local image, words = PaperUI.image, PaperUI.words
	local shop = Assets.shop
	-- Sheet units (1920 x 1080). The gift lands and opens at (960, 400).
	local rays = image(sheet, "Rays", shop.rays, 660, 100, 600, 600)
	local item = image(sheet, "Item", shop.iconGiftBox, 800, 240, 320, 320)
	local sparkles = { image(sheet, "Sparkle1", shop.sparkle, 1150, 170, 80, 80), image(sheet, "Sparkle2", shop.sparkle, 730, 500, 60, 60) }
	local string_ = Instance.new("Frame") -- the string the box hangs from
	string_.Name, string_.BackgroundColor3, string_.BorderSizePixel, string_.AnchorPoint = "String", PaperUI.INK, 0, Vector2.new(0.5, 0)
	string_.Parent = sheet
	local box = image(sheet, "Box", shop.iconGiftBox, 0, 0, 210, 201)
	local plane = image(sheet, "Plane", Assets.mainmenu.plane, 0, 0, 300, 260)
	-- The note: 1100 x 388 (the sticky's own shape); its tape covers the top ~118, its peeled corner the bottom right.
	-- Big words: a reward moment is read at a glance (lessons: 30 px+ on selling pieces).
	local note = image(sheet, "Note", Assets.ingame.stickyWide, 410, 662, 1100, 388)
	local title = words(note, "Title", "", 60, 112, 980, 68, 62)
	title.TextXAlignment = Enum.TextXAlignment.Center
	PaperUI.loud(title)
	PaperUI.fitWords(title, 980 * 0.96) -- (only a very long name gets smaller)
	local amount = words(note, "Amount", "", 60, 178, 980, 58, 50)
	amount.TextXAlignment = Enum.TextXAlignment.Center
	local playing, started, entry, pretended, seenHere = false, 0, nil, false, 0
	PaperUI.button(note, "Thanks", Assets.mainmenu.strip.green, "Thanks!", 400, 244, 300, 92, -1, function()
		if not playing or os.clock() - started < 3.3 then return end
		playing, cover.Visible = false, false
		if entry and not entry.pretend then seenHere += 1; api.seen(1) end
		GiftMoment.offer()
	end, 50)

	local function place(inst, x, y, w, h, rot)
		inst.Position, inst.Rotation = UDim2.fromOffset(x, y), rot or 0
		if w then inst.Size = UDim2.fromOffset(w, h) end
	end
	local function draw(t)
		dim.BackgroundTransparency = 1 - 0.72 * smooth(t / 0.3) -- (dark enough that the busy menu board stays quiet)
		-- The plane: in from the left to the middle, then away up and to the right.
		local px, py, pr
		if t < 1.4 then local u = smooth(t / 1.4); px, py, pr = lerp(-260, 960, u), lerp(120, 170, u), 0
		else local u = math.clamp((t - 1.4) / 0.9, 0, 1); px, py, pr = lerp(960, 2300, u * u), lerp(170, -220, u), -14 * u end
		place(plane, px, py, nil, nil, pr)
		-- The box hangs under it, swinging, until 1.4 s; then it drops to the middle and bounces.
		local bx, by, br, bs, fade = px, py + 195, 7 * math.sin(t * 5), 1, 0
		string_.Visible = t < 1.4
		if t >= 1.4 then
			bx, br = 960, 0
			by = lerp(365, 420, bounce((t - 1.4) / 0.7))
			if t > 2.15 then local u = math.clamp((t - 2.15) / 0.45, 0, 1); br, bs = 14 * u * math.sin(t * 42), 1 + 0.1 * u end -- wiggles...
			if t > 2.6 then local u = math.clamp((t - 2.6) / 0.25, 0, 1); bs, fade = 1.1 + 0.7 * u, u end -- ...and bursts
		else
			place(string_, px, py + 40, 4, 60)
		end
		place(box, bx, by, 210 * bs, 201 * bs, br)
		box.ImageTransparency = fade
		-- The gift pops out on its rays.
		local open = t > 2.6
		rays.Visible, item.Visible = open, open
		if open then
			local u = (t - 2.6) / 0.4
			local s = back(u)
			place(item, 960, 400 + 8 * math.sin(t * 2.6) * smooth(u), 320 * s, 320 * s)
			local r = 600 * (1 + 0.05 * math.sin(t * 2))
			place(rays, 960, 400, r * smooth(u), r * smooth(u), t * 25)
			rays.ImageTransparency = 0.15
		end
		for i, sparkle in sparkles do
			sparkle.Visible = t > 2.75
			sparkle.ImageTransparency = 1 - math.abs(math.sin(t * 1.7 + i * 1.3))
			sparkle.Rotation = 18 * math.sin(t * 1.3 + i)
		end
		-- The note slides up under it.
		place(note, 960, lerp(1320, 856, back((t - 2.85) / 0.45)))
	end
	RunService.RenderStepped:Connect(function()
		if not playing then return end
		local hold = RunService:IsStudio() and workspace:GetAttribute("DevGiftTime")
		draw(type(hold) == "number" and hold or os.clock() - started)
	end)

	local function play(gift)
		entry, playing, started = gift, true, os.clock()
		local icon, what = ShopScreen.itemLook(gift.key)
		item.Image = icon
		title.Text = "A gift from " .. tostring(gift.from) .. "!"
		amount.Text = what
		draw(0)
		cover.Visible = true
	end
	-- Plays the next unseen gift, if any (MenuController calls this when the main menu shows).
	function GiftMoment.offer()
		if playing then return end
		local fake = RunService:IsStudio() and workspace:GetAttribute("DevGiftMoment")
		if type(fake) == "string" and fake ~= "" and not pretended then
			pretended = true
			play({ from = "Test Friend", key = fake, pretend = true })
			return
		end
		local ok, inbox = pcall(function() return Http:JSONDecode(player:GetAttribute("GiftInbox") or "[]") end)
		-- seenHere: thanked here, not yet dropped by the server (its new list resets it). ponytail: a new gift arriving
		-- before the server drops a thanked one replays that one once; a gift id in the inbox fixes it if that ever matters.
		local gift = ok and type(inbox) == "table" and inbox[seenHere + 1]
		if type(gift) == "table" and type(gift.key) == "string" then play(gift) end
	end
	player:GetAttributeChangedSignal("GiftInbox"):Connect(function() seenHere = 0 end)
	workspace:GetAttributeChangedSignal("DevGiftMoment"):Connect(function() pretended = false end)
	function GiftMoment.playing() return playing end
end

return GiftMoment
