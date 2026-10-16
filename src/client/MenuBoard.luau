-- Main menu as a classroom bulletin board (Alan's approved concept: assets/references/ui-concepts/main-menu.png).
local TweenService = game:GetService("TweenService")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets).mainmenu
local PaperUI = require(script.Parent.PaperUI)
local Board = {}

-- actions = { play, hangar, settings, tutorial, shop (Studio only, may be nil) }
function Board.new(playerGui, actions)
	local cover, sheet = PaperUI.screen(playerGui, "MenuBoard", Art.bg)
	local image, button = PaperUI.image, PaperUI.button
	local pieces = {
		image(sheet, "Drawing1", Art.drawing1, 105, 180, 390, 400, -4),
		image(sheet, "Drawing2", Art.drawing2, 165, 610, 450, 380, 3),
		image(sheet, "Photo", Art.photo, 1270, 610, 560, 420, 2),
		image(sheet, "Plane", Art.plane, 1230, 440, 290, 200, 0),
		image(sheet, "Title", Art.title, 450, 105, 1010, 340, -1),
	}
	local card = image(sheet, "StatsCard", Art.card, 1480, 110, 370, 470, 3)
	local stats = PaperUI.words(card, "Stats", "", 70, 70, 290, 380, 44)
	stats.TextYAlignment, stats.LineHeight = Enum.TextYAlignment.Top, 1.15
	table.insert(pieces, card)

	local buttons = Instance.new("Frame")
	buttons.Name, buttons.BackgroundTransparency, buttons.Size = "Buttons", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H)
	buttons.Parent = sheet
	table.insert(pieces, button(buttons, "Play", Art.strip.yellow, "Play", 690, 445, 540, 140, -1, actions.play, 100))
	table.insert(pieces, button(buttons, "Hangar", Art.strip.blue, "Hangar", 710, 600, 500, 120, 1, actions.hangar))
	table.insert(pieces, button(buttons, "Settings", Art.strip.green, "Settings", 710, 735, 500, 120, -1, actions.settings))
	table.insert(pieces, button(buttons, "Tutorial", Art.strip.red, "Tutorial", 715, 870, 490, 120, 0.5, actions.tutorial))
	if actions.shop then
		table.insert(pieces, button(buttons, "Shop", Art.strip.yellow, "Shop (dev)", 1580, 560, 250, 70, 4, actions.shop, 34))
	end
	PaperUI.popIn(cover, pieces)
	local plane = sheet.Plane
	TweenService:Create(plane, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = plane.Position + UDim2.fromOffset(-14, -18), Rotation = -5,
	}):Play()

	local self = { frame = cover }
	function self.update(player, profile)
		local s = profile and profile.statistics or {}
		stats.Text = string.format("Level %d\nPaper %d\nPlanes downed %d\nWins %d\nMatches %d",
			player:GetAttribute("Level") or 1, player:GetAttribute("Paper") or 0, s.eliminations or 0, s.wins or 0, s.matches or 0)
	end
	return self
end

return Board
