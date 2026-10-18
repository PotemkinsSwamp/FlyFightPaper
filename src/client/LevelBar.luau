-- Your level, a crayon XP bar filled to how far you are into it, and the next part you unlock. Used on the results
-- card, the main menu board and the hangar (Alan 2026-10-17). `t` is the text size; stacked it is about t * 4.4 tall
-- (level and XP count, the bar, then the next unlock); inline it is one row t * 1.6 tall.
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets).results
local Economy = require(Root.Shared.EconomyRules)
local LEVEL_CAP = require(Root.Generated.Economy).level_cap
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local PaperUI = require(script.Parent.PaperUI)

local LevelBar = {}

-- The cheapest part unlocked at the next level above yours.
local function nextUnlock(level)
	local best
	local function consider(part)
		if part.min_level > level and (not best or part.min_level < best.min_level or part.min_level == best.min_level and part.paper_price < best.paper_price) then best = part end
	end
	for _, list in { Catalog.weapons, Catalog.utilities } do for _, part in list do consider(part) end end
	for _, list in Catalog.structuresBySlot do for _, part in list do consider(part) end end
	return best
end

function LevelBar.new(parent, x, y, w, t, inline)
	local words = PaperUI.words
	local barX, barY, barW, barH = x, y + t * 1.3, w, t * 1.7
	local level = words(parent, "Level", "", x, y, w * 0.45, t * 1.2, t * 1.1)
	local count = words(parent, "XPCount", "", x + w * 0.4, y, w * 0.6, t * 1.2, t * 0.85)
	local unlock = words(parent, "NextUnlock", "", x, y + t * 3.2, w, t * 1.2, t * 0.85)
	if inline then
		barX, barY, barW, barH = x + t * 4.4, y, w * 0.35, t * 1.6
		level.Size = UDim2.fromOffset(t * 4.4, barH)
		count.Visible = false
		unlock.Position, unlock.Size = UDim2.fromOffset(barX + barW + t * 0.6, y), UDim2.fromOffset(w - barW - t * 5, barH)
	end
	count.TextXAlignment, unlock.TextTruncate = Enum.TextXAlignment.Right, Enum.TextTruncate.AtEnd
	local frame = PaperUI.image(parent, "XPFrame", Art.xpFrame, barX, barY, barW, barH)
	frame.ScaleType = Enum.ScaleType.Stretch
	local fillW, fillH = barW - barW * 0.04, barH * 0.66
	local fill = PaperUI.image(parent, "XPFill", Art.xpFill, barX + barW * 0.02, barY + barH * 0.17, fillW, fillH)
	fill.ScaleType, fill.AnchorPoint = Enum.ScaleType.Stretch, Vector2.new(0, 0.5) -- drawn over the frame (made after it), inside its rim
	fill.Position = UDim2.fromOffset(barX + barW * 0.02, barY + barH / 2)

	local self = { pieces = { level, count, unlock, frame, fill } }
	-- xp: whole XP points (the profile's `xp`).
	function self.set(xp)
		local at, into, need = Economy.levelForXP(math.max(0, math.floor(xp * 1000)))
		at = at or 1
		local capped = at == LEVEL_CAP
		level.Text = "Level " .. at
		count.Text = capped and "max level" or string.format("%d / %d XP", (into or 0) // 1000, (need or 0) // 1000)
		fill.Size = UDim2.fromOffset(fillW * (capped and 1 or need and need > 0 and math.clamp(into / need, 0, 1) or 0), fillH)
		local part = nextUnlock(at)
		unlock.Text = part and string.format("Next: %s at level %d", part.name, part.min_level) or "Everything unlocked!"
	end
	function self.show(on) for _, piece in self.pieces do piece.Visible = on and (piece ~= count or not inline) end end
	return self
end

return LevelBar
