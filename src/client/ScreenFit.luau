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

-- fn() now and whenever the screen changes size or the player switches between touch and mouse.
function ScreenFit.watch(fn)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fn)
	Input:GetPropertyChangedSignal("PreferredInput"):Connect(fn)
	Root:GetAttributeChangedSignal("DevTouch"):Connect(fn)
	fn()
end

return ScreenFit
