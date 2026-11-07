-- A paperclip aimed at you glints (Alan 2026-11-06, like a sniper's scope). Every screen works this out for itself:
-- it already knows each enemy's nose and guns, so nothing extra is sent. In view: a bright flash on their plane, drawn
-- from plain frames so no picture is needed. Out of view: a very faint reddish glint spread along the bottom of the
-- screen, leaning towards their side. No sound. Buildings and the chalk cloud hide it (`seen`).
local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.CombatRules)
local Gameplay = require(Root.Generated.Gameplay)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), Gameplay)
local ClipGlint = {}

local WHITE, RED = Color3.fromRGB(255, 252, 240), Color3.fromRGB(255, 50, 40)
local BEHIND_PEAK = 0.45 -- how strong the bottom glint gets (0-1); Alan 2026-11-07: fainter was invisible over the town
local FLASH_EVERY = 1.2

local function fade(...)
	local points = {}
	for i, pair in { ... } do points[i] = NumberSequenceKeypoint.new(pair[1], pair[2]) end
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new(points)
	return gradient
end
-- A long thin streak, bright in the middle and gone at both ends.
local function streak(parent, length, thick, turn)
	local bar = Instance.new("Frame")
	bar.AnchorPoint, bar.Position, bar.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(length, thick)
	bar.BackgroundColor3, bar.BorderSizePixel, bar.Rotation = WHITE, 0, turn
	fade({ 0, 1 }, { 0.5, 0 }, { 1, 1 }).Parent = bar
	bar.Parent = parent
end
local function dot(parent, size, clear)
	local round = Instance.new("Frame")
	round.AnchorPoint, round.Position, round.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(size, size)
	round.BackgroundColor3, round.BackgroundTransparency, round.BorderSizePixel = WHITE, clear, 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0.5, 0), round
	round.Parent = parent
end
-- The flash itself: a star of streaks round a soft white core. Returns the piece that scales and turns.
function ClipGlint.flare(parent)
	local star = Instance.new("Frame")
	star.Name, star.AnchorPoint, star.Position, star.Size, star.BackgroundTransparency = "Star", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), 1
	Instance.new("UIScale").Parent = star
	streak(star, 200, 5, 0)
	streak(star, 200, 5, 90)
	streak(star, 96, 3, 45)
	streak(star, 96, 3, -45)
	dot(star, 54, 0.8)
	dot(star, 32, 0.5)
	dot(star, 14, 0)
	star.Parent = parent
	return star
end
-- The bottom-of-screen glint: a soft dome with one thin bright line low down, fading out at the sides and upward. It is
-- layers stacked from the bottom, each shorter one wider, so their fades end at different places (a CanvasGroup's fade
-- didn't draw, strips showed lines, and same-width layers all stepped to nothing at once: a hard side edge, Alan
-- 2026-11-06). Returns the band and paint(strength).
function ClipGlint.behind(parent)
	local band = Instance.new("Frame")
	band.Name, band.AnchorPoint, band.BackgroundTransparency = "Behind", Vector2.new(0.5, 1), 1
	band.Position, band.Size = UDim2.fromScale(0.5, 1), UDim2.fromScale(0.8, 0.26)
	local function layer(y, size, colour)
		local piece = Instance.new("Frame")
		piece.AnchorPoint, piece.Position, piece.Size = Vector2.new(0.5, 1), y, size
		piece.BackgroundColor3, piece.BorderSizePixel, piece.BackgroundTransparency = colour, 0, 1
		fade({ 0, 1 }, { 0.25, 0.5 }, { 0.5, 0 }, { 0.75, 0.5 }, { 1, 1 }).Parent = piece
		piece.Parent = band
		return piece
	end
	local layers, count = {}, 8
	for i = 1, count do layers[i] = layer(UDim2.fromScale(0.5, 1), UDim2.fromScale(1 - 0.55 * (i - 1) / (count - 1), i / count), RED) end
	local line = layer(UDim2.fromScale(0.5, 0.86), UDim2.new(0.7, 0, 0, 2), Color3.fromRGB(255, 190, 170))
	band.Parent = parent
	return band, function(strength)
		for _, piece in layers do piece.BackgroundTransparency = 1 - strength * 1.2 / count end
		line.BackgroundTransparency = 1 - strength
	end
end
-- How big the flash is, `t` seconds in: it bursts, settles, shimmers, and bursts again while the aim holds.
local function burst(t)
	local at = t % FLASH_EVERY
	if at < 0.1 then return at / 0.1 * 1.3 end
	if at < 0.35 then return 1.3 - (at - 0.1) / 0.25 * 0.65 end
	return 0.65 + 0.15 * math.sin(at * 12)
end

-- Returns step(plane, body, active, enemy, seen, camera), run once a frame by the HUD after the camera moves.
function ClipGlint.start()
	local weapon = Catalog:get("paperclip")
	local Combat = Gameplay.combat
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.IgnoreGuiInset, layer.ResetOnSpawn, layer.DisplayOrder, layer.Parent = "ClipGlint", true, false, 1, gui
	local behind, paint = ClipGlint.behind(layer)
	local watched, strength, last = {}, 0, os.clock() -- root -> { held = seconds aimed, t = seconds shown, gui = its flash }
	local planes = workspace:WaitForChild("Planes")
	return function(plane, body, active, enemy, seen, camera)
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		local reach = Rules.shotRange(weapon)
		local dev = Run:IsStudio() and Root:GetAttribute("DevGlint") -- every enemy glints, to judge the look in Studio
		local side, nearest, pulse = 0, math.huge, 0
		for _, other in planes:GetChildren() do
			local root = other:FindFirstChild("Root")
			if root and other ~= plane then
				local state = watched[root]
				if not state then state = { held = 0, t = 0 }; watched[root] = state end
				local distance = active and (root.Position - body.Position).Magnitude or 0
				local aimed = active and other:GetAttribute("State") == "FLYING" and enemy(plane, other)
					and (dev or string.find(other:GetAttribute("Mounts") or "", "paperclip", 1, true) ~= nil
						and distance > Combat.glint_min_studs and distance < reach
						and Rules.aimedAt(weapon, root.Position, root.CFrame.LookVector, body.Position, body.AssemblyLinearVelocity, Combat.gun_assist_deg))
					and seen(root)
				state.held = aimed and state.held + dt or 0
				local showing = state.held >= Combat.glint_hold_seconds
				local point, ahead = camera:WorldToViewportPoint(root.Position)
				local size = camera.ViewportSize
				local inView = ahead and point.X >= 0 and point.X <= size.X and point.Y >= 0 and point.Y <= size.Y
				state.t = showing and state.t + dt or 0
				if showing and inView and not state.gui then
					local board = Instance.new("BillboardGui")
					board.Name, board.Size, board.AlwaysOnTop, board.LightInfluence = "PaperclipGlint", UDim2.fromOffset(200, 200), true, 0
					board.Adornee, board.Brightness, board.Parent = root, 3, gui
					state.star, state.gui = ClipGlint.flare(board), board
				end
				if state.gui then
					state.gui.Enabled = showing and inView
					state.star.UIScale.Scale = burst(state.t)
					state.star.Rotation = state.t * 25
				end
				if showing and not inView and distance < nearest then
					nearest, pulse = distance, burst(state.t)
					side = (root.Position - camera.CFrame.Position).Unit:Dot(camera.CFrame.RightVector)
				end
			end
		end
		for root, state in watched do
			if not root.Parent then
				if state.gui then state.gui:Destroy() end
				watched[root] = nil
			end
		end
		strength += ((nearest < math.huge and 1 or 0) - strength) * math.min(1, dt * 6)
		paint(strength * (dev and Root:GetAttribute("DevGlintPeak") or BEHIND_PEAK) * (0.75 + pulse * 0.25))
		if nearest < math.huge then behind.Position = UDim2.fromScale(0.5 + side * 0.25, 1) end
	end
end

return ClipGlint
