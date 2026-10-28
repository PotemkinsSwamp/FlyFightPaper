-- Screen fit (docs/plan/SCREEN-FIT-PLAN.md, Alan 2026-10-24): one size rule for every piece on every screen.
-- A piece is drawn for a 1080-point-tall screen; on another screen it grows or shrinks with the screen's short side,
-- but never past its least and most scale. The screen's kind (phone, tablet, PC) picks the least.
local Input = game:GetService("UserInputService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local ScreenFit = {}

ScreenFit.PHONE, ScreenFit.TABLET = 540, 900 -- the short side in points: under 540 a phone, under 900 a tablet
-- Least scales: the flying screen's pieces (0.4 of 1080p still reads at about 15 points on a phone) and the paper
-- notes over the game (lesson notes, tips, Range notes, score words).
ScreenFit.HUD = { phone = 0.4, tablet = 0.6, pc = 0.6 }
ScreenFit.NOTE = { phone = 0.5, tablet = 0.6, pc = 0.6 }

function ScreenFit.view()
	return workspace.CurrentCamera.ViewportSize
end

-- "phone", "tablet" or "pc", by size only (a small PC window gets tablet sizes, which is what fits it).
function ScreenFit.kind()
	local view = ScreenFit.view()
	local short = math.min(view.X, view.Y)
	if short < 2 then return "pc" end -- not drawn yet
	if Root:GetAttribute("DevPhone") and game:GetService("RunService"):IsStudio() then return "phone" end -- Studio test hook
	return short < ScreenFit.PHONE and "phone" or short < ScreenFit.TABLET and "tablet" or "pc"
end

-- The scale for a piece drawn for a 1920 x 1080 screen: how much of that fits (the height on wide phones, the width
-- on a squarer iPad), kept between least (a number, or one per kind like { phone = 0.4, tablet = 0.6, pc = 0.6 })
-- and most.
function ScreenFit.scale(least, most)
	local floor = type(least) == "table" and least[ScreenFit.kind()] or least or 0
	local view = ScreenFit.view()
	return math.clamp(math.min(view.X / 1920, view.Y / 1080), floor, most or math.huge)
end

-- The screen map's top middle (step 2): the top row (Roblox's bar, the Menu button, the match strip), the pieces up in
-- the top corners (a touch screen's Health and Lift on the left, the kill feed on the right), and a column of notes
-- in a fixed order under the row. A note stays where it was drawn (centred under the match strip) unless it would
-- touch a corner piece: then it slides into the gap between them and shrinks to fit (small phones, Alan 2026-10-24).
-- Each note sits under the shown pieces above it that it touches. Pieces live in different ScreenGuis, so each one
-- asks where it goes (ScreenFit.place) from the others' real edges (last frame's) and sets its own position.
local GuiService = game:GetService("GuiService")
local row, sides, column = {}, {}, {}
ScreenFit.GAP = 4 -- points between pieces
function ScreenFit.inRow(piece) table.insert(row, piece) end
-- when(): only while it is up top (Health and Lift sit at the bottom on a PC).
function ScreenFit.atSide(piece, when) table.insert(sides, { piece = piece, when = when }) end
-- order: smaller goes higher (capture 1, news 2, lesson or Range note 3, warning or lock 4, match tip 5).
-- covers: on a phone it stays up top over the other notes and the kill feed rather than dropping into the middle of
-- the view (the match tip, Alan 2026-10-24); it still keeps off Health and Lift.
-- high: on a phone it goes up into Roblox's top bar, right of the Menu button (the lesson note, Alan 2026-10-28).
function ScreenFit.inColumn(piece, order, covers, high)
	table.insert(column, { piece = piece, order = order, covers = covers, high = high })
	table.sort(column, function(a, b) return a.order < b.order end)
end
local function shown(piece)
	local at = piece
	while at and not at:IsA("ScreenGui") do
		if at:IsA("GuiObject") and not at.Visible then return false end
		at = at.Parent
	end
	return at ~= nil and at.Enabled
end
local function scaleOf(parent) -- how much the parent's own points are scaled on screen
	return parent:IsA("GuiObject") and parent.Size.X.Offset > 0 and parent.AbsoluteSize.X / parent.Size.X.Offset or 1
end

-- Where a column piece goes: x, y for UDim2.new(0.5, x, 0, y) in its parent's own points (AnchorPoint (0.5, 0)), and
-- fit (1 or less) to shrink it by. base: the piece's own scale before fitting (its UIScale's usual value). units: its
-- width at home, when it has another shape now (a phone's lesson note at a side).
function ScreenFit.place(piece, base, units)
	local entry
	for _, e in column do if e.piece == piece then entry = e end end
	local parent, view = piece.Parent, ScreenFit.view()
	local parentScale = scaleOf(parent)
	local width = (units or piece.Size.X.Offset) * parentScale * (base or 1)
	local home = parent.AbsolutePosition.X + parent.AbsoluteSize.X / 2
	local phoneCovers = entry.covers and ScreenFit.kind() == "phone"
	local bar, inset = GuiService.TopbarInset, GuiService:GetGuiInset().Y
	local phoneHigh = entry.high and ScreenFit.kind() == "phone" and bar.Width > 0
	-- The gap between the corner pieces (the kill feed doesn't count for a note that covers).
	local gapLeft, gapRight = ScreenFit.GAP * 2, view.X - ScreenFit.GAP * 2
	for _, side in sides do
		local other = side.piece
		if shown(other) and (not side.when or side.when()) then
			local low, high = other.AbsolutePosition.X, other.AbsolutePosition.X + other.AbsoluteSize.X
			if (low + high) / 2 < view.X / 2 then gapLeft = math.max(gapLeft, high + ScreenFit.GAP * 2)
			elseif not phoneCovers then gapRight = math.min(gapRight, low - ScreenFit.GAP * 2) end
		end
	end
	if phoneHigh then
		-- In the bar: clear of Roblox's own buttons and of the row's pieces on the left (the Menu button).
		gapRight = math.min(gapRight, bar.Max.X - ScreenFit.GAP * 2)
		for _, other in row do
			local high = other.AbsolutePosition.X + other.AbsoluteSize.X
			if shown(other) and (other.AbsolutePosition.X + high) / 2 < view.X / 2 then gapLeft = math.max(gapLeft, high + ScreenFit.GAP * 2) end
		end
	end
	local centre, fit = home, 1
	if home - width / 2 < gapLeft or home + width / 2 > gapRight then
		fit = math.min(1, (gapRight - gapLeft) / width)
		local half = width * fit / 2
		centre = math.clamp(home, gapLeft + half, math.max(gapLeft + half, gapRight - half))
	end
	local left, right = centre - width * fit / 2, centre + width * fit / 2
	local y = (phoneHigh and bar.Min.Y or bar.Max.Y) - inset -- the bar's bottom (or top) in AbsolutePosition space
	local function under(other)
		if shown(other) and other.AbsolutePosition.X < right and other.AbsolutePosition.X + other.AbsoluteSize.X > left then
			y = math.max(y, other.AbsolutePosition.Y + other.AbsoluteSize.Y)
		end
	end
	for _, other in row do under(other) end
	if not phoneCovers then
		for _, e in column do
			if e.piece == piece then break end
			under(e.piece)
		end
	end
	return (centre - home) / parentScale, (y + ScreenFit.GAP - parent.AbsolutePosition.Y) / parentScale, fit
end

-- Out of the way (Alan 2026-10-28: every note over the game, every screen): a note stays home unless it keeps covering
-- something that matters for 0.4 s; then it slides to the first free spot of: home, the right side, the left side
-- (each tilted a little) and the bottom middle. A spot is free when it clears the other pieces on the screen map,
-- the touch buttons and every box that matters; a side or the bottom may shrink the note to 75% to fit. A new key (the
-- next step or tip) sends it home. All in screen points (the notes' ScreenGuis ignore the inset).
-- dodge(home, size, key, boxes, homeTurn, dt) -> x, y (the note's top middle), rotation, spot, fit. size(spot) = the
-- note's size on screen there (a phone's lesson note changes shape at a side); boxes = { { low, high }, ... }.
local SPOTS = { "home", "right", "left", "bottom" }
local TURN = { right = 3, left = -3, bottom = 1 }
local function gapIn(from, to, blocks) -- the longest free stretch of from..to between the blocks ({ a, b } each)
	table.sort(blocks, function(a, b) return a[1] < b[1] end)
	local best, at = { from, from }, from
	for _, block in blocks do
		local stop = math.min(block[1], to)
		if stop - at > best[2] - best[1] then best = { at, stop } end
		at = math.max(at, block[2])
	end
	if to - at > best[2] - best[1] then best = { at, to } end
	return best[1], best[2]
end
function ScreenFit.dodger(piece)
	local spot, key, coveredFor, at, turn, lastAt = "home", nil, 0, nil, 0, 0
	return function(home, size, newKey, boxes, homeTurn, dt)
		if newKey ~= key then key, spot, coveredFor = newKey, "home", 0 end
		if os.clock() - lastAt > 0.5 then at = nil end -- shown again: no slide in from where it last was
		lastAt = os.clock()
		local view, m = ScreenFit.view(), ScreenFit.GAP * 4
		local keep = {}
		local function add(other)
			if other ~= piece and shown(other) then table.insert(keep, { other.AbsolutePosition, other.AbsolutePosition + other.AbsoluteSize }) end
		end
		for _, other in row do add(other) end
		for _, side in sides do add(side.piece) end
		for _, e in column do add(e.piece) end
		local touch = game.Players.LocalPlayer.PlayerGui:FindFirstChild("TouchControls")
		if touch and touch.Enabled then for _, other in touch:GetChildren() do if other:IsA("GuiObject") then add(other) end end end
		local function where(name)
			if name == "home" then return home, 1, homeTurn end
			local s = size(name)
			local blocks = {}
			if name == "bottom" then
				for _, k in keep do if k[2].Y > view.Y - m - s.Y and k[1].Y < view.Y - m then table.insert(blocks, { k[1].X - ScreenFit.GAP, k[2].X + ScreenFit.GAP }) end end
				local a, b = gapIn(m, view.X - m, blocks)
				if b - a < s.X * 0.75 then return nil end
				local fit = math.min(1, (b - a) / s.X)
				return Vector2.new(math.clamp(view.X / 2, a + s.X * fit / 2, b - s.X * fit / 2), view.Y - m - s.Y * fit), fit, TURN.bottom
			end
			local x = name == "right" and view.X - m - s.X / 2 or m + s.X / 2
			for _, k in keep do if k[2].X > x - s.X / 2 and k[1].X < x + s.X / 2 then table.insert(blocks, { k[1].Y - ScreenFit.GAP, k[2].Y + ScreenFit.GAP }) end end
			local a, b = gapIn(GuiService.TopbarInset.Max.Y - GuiService:GetGuiInset().Y + ScreenFit.GAP, view.Y - m, blocks)
			if b - a < s.Y * 0.75 then return nil end
			local fit = math.min(1, (b - a) / s.Y)
			x = name == "right" and view.X - m - s.X * fit / 2 or m + s.X * fit / 2
			return Vector2.new(x, math.clamp(view.Y * 0.42 - s.Y * fit / 2, a, b - s.Y * fit)), fit, TURN[name]
		end
		local function covered(p, s)
			local low, high = p - Vector2.new(s.X / 2, 0), p + Vector2.new(s.X / 2, s.Y)
			for _, box in boxes do
				if box[1] and box[2] and box[1].X < high.X + ScreenFit.GAP * 2 and box[2].X > low.X - ScreenFit.GAP * 2
					and box[1].Y < high.Y + ScreenFit.GAP * 2 and box[2].Y > low.Y - ScreenFit.GAP * 2 then return true end
			end
			return false
		end
		local p, fit, r = where(spot)
		if not p then spot, p, fit, r = "home", home, 1, homeTurn end
		coveredFor = covered(p, size(spot) * fit) and coveredFor + dt or 0
		if coveredFor >= 0.4 then
			for _, name in SPOTS do
				local q, g, t = nil, nil, nil
				if name ~= spot then q, g, t = where(name) end
				if q and not covered(q, size(name) * g) then spot, p, fit, r, coveredFor = name, q, g, t, 0; break end
			end
		end
		local ease = math.min(1, dt * 12)
		at = at and at:Lerp(p, ease) or p
		turn = turn + (r - turn) * ease
		return at.X, at.Y, turn, spot, fit
	end
end

-- What a note over the game must not cover in a fight (screen points): the aim circle, nose dot, lead rings, eraser
-- circle and lock, and every enemy plane within 300 studs.
local AIM = { "AimCircle", "NoseDot", "EraserSeeker", "LockBox", "TargetBracket", "LeadPipper", "LeadPipper2" }
function ScreenFit.matters(plane)
	local boxes = {}
	-- Studio test hook: DevCover (Rects) on ReplicatedStorage.FlyFightPaper counts as more things that matter.
	for _, rect in game:GetService("RunService"):IsStudio() and { Root:GetAttribute("DevCover"), Root:GetAttribute("DevCover2"), Root:GetAttribute("DevCover3") } or {} do
		if typeof(rect) == "Rect" then table.insert(boxes, { rect.Min, rect.Max }) end
	end
	local hud = game.Players.LocalPlayer.PlayerGui:FindFirstChild("FlightHUD")
	if hud and hud.Enabled then
		for _, name in AIM do
			local mark = hud:FindFirstChild(name)
			if mark and mark.Visible then table.insert(boxes, { mark.AbsolutePosition, mark.AbsolutePosition + mark.AbsoluteSize }) end
		end
	end
	local planes, camera = workspace:FindFirstChild("Planes"), workspace.CurrentCamera
	local team = plane and plane:GetAttribute("Team") or ""
	for _, other in planes and planes:GetChildren() or {} do
		local root = other:FindFirstChild("Root")
		if other ~= plane and root and other:GetAttribute("State") == "FLYING" and (team == "" or other:GetAttribute("Team") ~= team)
			and (root.Position - camera.CFrame.Position).Magnitude < 300 then
			local point, onScreen = camera:WorldToViewportPoint(root.Position)
			if onScreen then table.insert(boxes, { Vector2.new(point.X - 30, point.Y - 30), Vector2.new(point.X + 30, point.Y + 30) }) end
		end
	end
	return boxes
end

-- fn() now and whenever the screen changes size or the player switches between touch and mouse.
function ScreenFit.watch(fn)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fn)
	Input:GetPropertyChangedSignal("PreferredInput"):Connect(fn)
	Root:GetAttributeChangedSignal("DevTouch"):Connect(fn)
	Root:GetAttributeChangedSignal("DevPhone"):Connect(fn)
	fn()
end

return ScreenFit
