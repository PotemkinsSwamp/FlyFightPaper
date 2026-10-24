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

-- The screen map's top middle (step 2): the top row (Roblox's bar, the Menu button, the match strip, and the pieces up
-- in the corners: kill feed, a touch screen's Health and Lift), then a column of notes in a fixed order. Each note sits
-- under the real bottom (last frame's) of every shown piece above it that it would touch side to side: on a small
-- phone the match strip's notes slide right, under the kill feed. Pieces live in different ScreenGuis, so each one
-- asks where it goes and sets its own position.
local GuiService = game:GetService("GuiService")
local row, column = {}, {}
ScreenFit.GAP = 4 -- points between pieces
-- when(): only while it is up top (Health and Lift sit at the bottom on a PC).
function ScreenFit.inRow(piece, when) table.insert(row, { piece = piece, when = when }) end
-- order: smaller goes higher (capture 1, news 2, lesson or Range note 3, warning or lock 4, match tip 5).
function ScreenFit.inColumn(piece, order)
	table.insert(column, { piece = piece, order = order })
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
-- The top for `piece` (in the column) in its parent's own points (UIScale undone).
function ScreenFit.below(piece)
	local y = GuiService.TopbarInset.Max.Y - GuiService:GetGuiInset().Y -- the bar's bottom in AbsolutePosition space
	local left, right = piece.AbsolutePosition.X, piece.AbsolutePosition.X + piece.AbsoluteSize.X
	local function under(other)
		if shown(other) and other.AbsolutePosition.X < right and other.AbsolutePosition.X + other.AbsoluteSize.X > left then
			y = math.max(y, other.AbsolutePosition.Y + other.AbsoluteSize.Y)
		end
	end
	for _, entry in row do if not entry.when or entry.when() then under(entry.piece) end end
	for _, entry in column do
		if entry.piece == piece then break end
		under(entry.piece)
	end
	local parent = piece.Parent
	local size = parent:IsA("GuiObject") and parent.Size.Y.Offset > 0 and parent.AbsoluteSize.Y / parent.Size.Y.Offset or 1
	return (y + ScreenFit.GAP - parent.AbsolutePosition.Y) / size
end

-- fn() now and whenever the screen changes size or the player switches between touch and mouse.
function ScreenFit.watch(fn)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fn)
	Input:GetPropertyChangedSignal("PreferredInput"):Connect(fn)
	Root:GetAttributeChangedSignal("DevTouch"):Connect(fn)
	fn()
end

return ScreenFit
