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
function ScreenFit.inColumn(piece, order, covers)
	table.insert(column, { piece = piece, order = order, covers = covers })
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
-- fit (1 or less) to shrink it by. base: the piece's own scale before fitting (its UIScale's usual value).
function ScreenFit.place(piece, base)
	local entry
	for _, e in column do if e.piece == piece then entry = e end end
	local parent, view = piece.Parent, ScreenFit.view()
	local parentScale = scaleOf(parent)
	local width = piece.Size.X.Offset * parentScale * (base or 1)
	local home = parent.AbsolutePosition.X + parent.AbsoluteSize.X / 2
	local phoneCovers = entry.covers and ScreenFit.kind() == "phone"
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
	local centre, fit = home, 1
	if home - width / 2 < gapLeft or home + width / 2 > gapRight then
		fit = math.min(1, (gapRight - gapLeft) / width)
		local half = width * fit / 2
		centre = math.clamp(home, gapLeft + half, math.max(gapLeft + half, gapRight - half))
	end
	local left, right = centre - width * fit / 2, centre + width * fit / 2
	local y = GuiService.TopbarInset.Max.Y - GuiService:GetGuiInset().Y -- the bar's bottom in AbsolutePosition space
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

-- fn() now and whenever the screen changes size or the player switches between touch and mouse.
function ScreenFit.watch(fn)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fn)
	Input:GetPropertyChangedSignal("PreferredInput"):Connect(fn)
	Root:GetAttributeChangedSignal("DevTouch"):Connect(fn)
	fn()
end

return ScreenFit
