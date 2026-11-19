-- The desk's quick look at missions (Alan 2026-11-18): the Missions strip under "Switch to presets" drops down a sheet of
-- tracing paper (the runway shows through) listing your missions and progress, with a Daily/Weekly switch; tap the strip
-- again to fold it. Only at the desk (never mid-flight). View only: Claim and Swap are on the Missions sheet.
local TweenService = game:GetService("TweenService")
local PaperUI = require(script.Parent.PaperUI)
local Widgets = require(script.Parent.HangarWidgets)
local Assets = require(game.ReplicatedStorage.FlyFightPaper.Shared.UIAssets)
local MissionsScreen = require(script.Parent.MissionsScreen)
local Dropdown = {}

-- Tracing paper: the Shop's white torn paper drawn see-through, at its own shape (1024 x 870, never stretched).
local SEE_THROUGH = 0.15 -- the runway shows through (Alan 2026-11-18: a little more solid than 0.3); the words still sit on a calm patch (design-theory 3.2: check on a screenshot)
local PAPER = 870 / 1024
-- Sheet pixels. A phone draws the desk's left group at about a third, so its words are bigger, the paper runs wider over
-- the runway, and it scrolls (paper and all) when it is taller than the room under the strip.
local SIZES = {
	pc = { w = 560, head = 86, text = 30, tab = { 200, 58, 34 } },
	phone = { w = 1000, head = 122, text = 44, tab = { 280, 84, 48 } },
}

local function goal(m) return m.action == "minutes" and m.kind == "total" and m.count * 60 or m.count end
local function ready(missions)
	if not missions or not missions.daily then return false end
	for _, list in { missions.daily, missions.weekly or {} } do
		for _, m in list do if not m.claimed and m.progress >= goal(m) then return true end end
	end
	return (missions.dailiesDone or 0) >= 15 and not missions.fixedClaimed
end

-- parent: the desk's left group (sheet pixels); strip: the Missions button; x, top: the paper's top left; bottom: the
-- lowest it may reach; refresh(): asks the server for the latest progress.
function Dropdown.new(parent, strip, x, top, bottom, refresh)
	local ui = Widgets.new()
	local open, tab, missions = false, "daily", nil
	local panel = Instance.new("ScrollingFrame")
	panel.Name, panel.Position, panel.Size, panel.Active = "MissionsDropdown", UDim2.fromOffset(x, top), UDim2.fromOffset(SIZES.pc.w, 0), true
	panel.BackgroundTransparency, panel.BorderSizePixel = 1, 0
	panel.ScrollBarThickness, panel.ScrollingDirection = 0, Enum.ScrollingDirection.Y -- no scroll bar (Alan 2026-11-18); a phone still drags it
	panel.ElasticBehavior, panel.Visible, panel.ZIndex, panel.Parent = Enum.ElasticBehavior.Never, false, 5, parent
	-- A red "!" on the strip's corner while a mission is waiting to be claimed (a shape and a word, not colour alone).
	local flag = Instance.new("Frame")
	flag.Name, flag.Size, flag.Position, flag.AnchorPoint = "Ready", UDim2.fromOffset(44, 44), UDim2.new(1, -6, 0, 6), Vector2.new(0.5, 0.5)
	flag.BackgroundColor3, flag.BorderSizePixel, flag.Visible, flag.ZIndex, flag.Parent = Color3.fromRGB(214, 60, 52), 0, false, 4, strip
	Instance.new("UICorner", flag).CornerRadius = UDim.new(0.5, 0)
	local flagEdge = Instance.new("UIStroke"); flagEdge.Color, flagEdge.Thickness, flagEdge.Parent = Color3.fromRGB(255, 244, 228), 3, flag
	local bang = PaperUI.words(flag, "Bang", "!", 0, -2, 44, 44, 36)
	bang.TextXAlignment, bang.TextColor3 = Enum.TextXAlignment.Center, Color3.fromRGB(255, 255, 255)
	PaperUI.phone(flag, { Size = UDim2.fromOffset(64, 64) })
	PaperUI.phone(bang, { Size = UDim2.fromOffset(64, 64), TextSize = 52 })

	local S = SIZES.pc
	local function tall() return math.floor(S.w * PAPER) end
	local function shown() return math.min(tall(), bottom - panel.Position.Y.Offset) end
	-- One mission: its goal (up to two lines) sitting right on the level bar, with its count beside the bar; the room
	-- left over goes between missions, not inside them (Alan 2026-11-18).
	local function row(name, y, h, text, fraction, words)
		local barW = math.floor(S.w * 0.6)
		local barH = math.floor(barW * 79 / 799 + 0.5)
		local barY = y + h - barH - 10
		local goalText = ui.words(panel, name .. "Goal", text, 24, y, S.w - 48, barY - y - 2, S.text)
		goalText.TextWrapped, goalText.TextYAlignment, goalText.LineHeight = true, Enum.TextYAlignment.Bottom, 1
		MissionsScreen.bar(ui, panel, name, 24, barY, barW, fraction)
		ui.words(panel, name .. "Count", fraction >= 1 and "Done!" or words, 24 + barW + 14, barY - 10, S.w - barW - 62, barH + 20, S.text)
	end
	local function draw()
		S = PaperUI.isPhone() and SIZES.phone or SIZES.pc
		ui.begin()
		flag.Visible = ready(missions)
		local paper = ui.image(panel, "Paper", Assets.shop.tabCream, 0, 0, S.w, tall())
		paper.ImageTransparency, paper.ZIndex = SEE_THROUGH, 0
		for i, name in { "daily", "weekly" } do
			local on = tab == name
			ui.button(panel, name .. "Tab", on and Assets.hangar.buttonGreen or Assets.unlock.buttonCream, name == "daily" and "Daily" or "Weekly",
				24 + (i - 1) * (S.tab[1] + 10), 14, S.tab[1], S.tab[2], 0, function()
					tab = name; draw()
					if open then panel.Size = UDim2.fromOffset(S.w, shown()) end
				end, S.tab[3])
		end
		if not missions or not missions.daily or #missions.daily == 0 then
			ui.words(panel, "Waiting", "Missions are loading...", 24, S.head + 10, S.w - 48, S.text + 14, S.text)
		else
			local list = tab == "daily" and missions.daily or missions.weekly
			-- The rows share the paper inside its torn bottom edge.
			local h = math.floor((tall() * 0.94 - S.head) / (#list + (tab == "weekly" and 1 or 0)))
			for i, m in list do
				local now, target, fraction = MissionsScreen.counts(m)
				row("Row" .. i, S.head + (i - 1) * h, h, MissionsScreen.describe(m), fraction, PaperUI.commas(now) .. " / " .. PaperUI.commas(target))
			end
			if tab == "weekly" then
				local done = missions.dailiesDone or 0
				row("Fixed", S.head + #list * h, h, "Finish 15 daily missions", done / 15, math.min(done, 15) .. " / 15")
			end
		end
		panel.CanvasSize = UDim2.fromOffset(0, tall())
		ui.finish()
	end

	local self = { panel = panel }
	function self.toggle()
		open = not open
		if open then
			refresh()
			draw()
			panel.Size, panel.Visible = UDim2.fromOffset(S.w, 0), true
			TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(S.w, shown()) }):Play()
		else
			local shut = TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(S.w, 0) })
			shut:Play()
			shut.Completed:Connect(function() if not open then panel.Visible = false end end)
		end
	end
	function self.close() if open then self.toggle() end end
	function self.update(newMissions)
		missions = newMissions
		draw()
		if open then panel.Size = UDim2.fromOffset(S.w, shown()) end
	end
	draw()
	return self
end

return Dropdown
