-- Main menu as a classroom bulletin board (Alan's approved concept: assets/references/ui-concepts/main-menu.png).
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local UIAssets = require(Root.Shared.UIAssets)
local Art = UIAssets.mainmenu
local PaperUI = require(script.Parent.PaperUI)
local Economy = require(Root.Shared.EconomyRules)
local EconomyConfig = require(Root.Generated.Economy)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local HOLD_SECONDS = 2
local Board = {}

-- actions = { play, hangar, settings, tutorial, prestige, shop (Studio only, may be nil) }
function Board.new(playerGui, actions)
	local cover, sheet = PaperUI.screen(playerGui, "MenuBoard", Art.bg)
	local image, button = PaperUI.image, PaperUI.button
	local pieces = {
		image(sheet, "Drawing1", Art.drawing1, 105, 180, 390, 400, -4),
		image(sheet, "Drawing2", Art.drawing2, 165, 610, 450, 380, 3),
		image(sheet, "Photo", Art.photo, 1270, 610, 560, 420, 2),
		image(sheet, "Title", Art.title, 450, 105, 1010, 340, -1),
	}
	local card = image(sheet, "StatsCard", Art.card, 1480, 110, 370, 470, 3)
	local stats = PaperUI.words(card, "Stats", "", 70, 70, 290, 380, 44)
	stats.TextYAlignment, stats.LineHeight = Enum.TextYAlignment.Top, 1.15
	table.insert(pieces, card)
	local levelBar = require(script.Parent.LevelBar).new(card, 56, 282, 280, 27)
	-- Phones: the level words were 8-10 points.
	PaperUI.phone(card.Level, { TextSize = 38, Size = UDim2.fromOffset(160, 34) })
	PaperUI.phone(card.XPCount, { TextSize = 34 })
	PaperUI.phone(card.NextUnlock, { TextSize = 34 })

	local buttons = Instance.new("Frame")
	buttons.Name, buttons.BackgroundTransparency, buttons.Size = "Buttons", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H)
	buttons.Parent = sheet
	table.insert(pieces, button(buttons, "Play", Art.strip.yellow, "Play", 690, 445, 540, 140, -1, actions.play, 100))
	table.insert(pieces, button(buttons, "Hangar", Art.strip.blue, "Hangar", 710, 600, 500, 120, 1, actions.hangar))
	table.insert(pieces, button(buttons, "Settings", Art.strip.green, "Settings", 710, 735, 500, 120, -1, actions.settings))
	table.insert(pieces, button(buttons, "Tutorial", Art.strip.red, "Training", 715, 870, 490, 120, 0.5, actions.tutorial))
	if actions.shop then
		table.insert(pieces, button(buttons, "Shop", Art.strip.yellow, "Shop (dev)", 1580, 560, 250, 70, 4, actions.shop, 34))
	end
	-- Prestige (docs/systems/economy-and-shop.md): a button on the stats card at max level, then a confirm sheet that
	-- says what goes and what stays; holding the button for two seconds confirms, so it can't happen by accident.
	local prestigeButton = button(card, "Prestige", Art.strip.red, "Prestige", 60, 400, 250, 56, -2, function() end, 32)
	PaperUI.phone(prestigeButton, { Size = UDim2.fromOffset(280, 80) }) -- a finger-sized strip on a phone
	PaperUI.phone(prestigeButton.Label, { TextSize = 42 })
	local confirm = Instance.new("Frame")
	confirm.Name, confirm.BackgroundColor3, confirm.BackgroundTransparency = "PrestigeConfirm", Color3.fromRGB(20, 14, 8), 0.45
	confirm.Size, confirm.Visible, confirm.ZIndex, confirm.Parent = UDim2.fromOffset(PaperUI.W, PaperUI.H), false, 5, sheet
	local note = image(confirm, "Note", Art.card, 640, 120, 640, 813, 1) -- the stats card's paper, same shape
	local text = PaperUI.words(note, "Text", "", 125, 120, 470, 470, 34)
	text.TextWrapped, text.TextYAlignment, text.LineHeight = true, Enum.TextYAlignment.Top, 1.1
	local hold = button(note, "Hold", Art.strip.red, "Hold to prestige", 95, 620, 300, 90, -1, function() end, 34)
	local holdFill = Instance.new("Frame")
	holdFill.Name, holdFill.BackgroundColor3, holdFill.BackgroundTransparency, holdFill.BorderSizePixel = "Fill", Color3.fromRGB(255, 255, 255), 0.55, 0
	holdFill.Size, holdFill.Parent = UDim2.fromScale(0, 1), hold
	button(note, "Cancel", Art.strip.green, "Cancel", 410, 628, 170, 80, 2, function() confirm.Visible = false end, 32)
	local holding = 0
	hold.MouseButton1Down:Connect(function()
		holding += 1
		local mine, started = holding, os.clock()
		while holding == mine and confirm.Visible do
			local done = (os.clock() - started) / HOLD_SECONDS
			holdFill.Size = UDim2.fromScale(math.min(done, 1), 1)
			if done >= 1 then confirm.Visible = false; actions.prestige(); break end
			task.wait()
		end
		holdFill.Size = UDim2.fromScale(0, 1)
	end)
	local function release() holding += 1 end
	hold.MouseButton1Up:Connect(release)
	hold.MouseLeave:Connect(release)
	local shown = { profile = nil }
	prestigeButton.Activated:Connect(function()
		local profile = shown.profile; if not profile then return end
		local starter, lost = Economy.starterOwnership(Catalog), 0
		for id in pairs(profile.ownership or {}) do if not starter[id] then lost += 1 end end
		local next = (game.Players.LocalPlayer:GetAttribute("Prestige") or 0) + 1
		text.Text = string.format("Prestige to rank %d?\n\nGoes: your level (back to 1) and %d part%s you own. Earn or buy them again.\n\n"
			.. "Stays: your %d Paper, cosmetics, boosts and stats.\n\nYou get: a rank %d star and a prestige-only prize.",
			next, lost, lost == 1 and "" or "s", game.Players.LocalPlayer:GetAttribute("Paper") or 0, next)
		confirm.Visible = true
	end)

	PaperUI.popIn(cover, pieces)
	-- Each time the board shows, the plane flies in to its spot and only then is pinned (Alan 2026-10-17): a pushpin
	-- pops in on its nose (the plane picture has no pin of its own).
	local plane = image(sheet, "Plane", Art.plane, 1230, 443, 226, 195, 0)
	local pin = image(sheet, "PlanePin", UIAssets.hud.pinRed, 1415, 433, 34, 34, 0)
	local home, pinSize = plane.Position, pin.Size
	cover:GetPropertyChangedSignal("Visible"):Connect(function()
		if not cover.Visible then return end
		pin.Size, plane.Position, plane.Rotation = UDim2.fromOffset(0, 0), UDim2.fromOffset(-200, 760), 24
		local fly = TweenService:Create(plane, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = home, Rotation = 0 })
		fly.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				TweenService:Create(pin, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = pinSize }):Play()
			end
		end)
		fly:Play()
	end)

	local self = { frame = cover }
	function self.update(player, profile)
		local s = profile and profile.statistics or {}
		stats.Text = string.format("Paper %d\nPlanes downed %d\nWins %d\nMatches %d",
			player:GetAttribute("Paper") or 0, s.eliminations or 0, s.wins or 0, s.matches or 0)
		levelBar.set(profile and profile.xp or 0)
		shown.profile = profile
		local level = Economy.levelForXP(math.floor((profile and profile.xp or 0) * 1000))
		prestigeButton.Visible = level == EconomyConfig.level_cap
			and (player:GetAttribute("Prestige") or 0) < (EconomyConfig.prestige_max or 10)
		if not prestigeButton.Visible then confirm.Visible = false end
	end
	return self
end

return Board
