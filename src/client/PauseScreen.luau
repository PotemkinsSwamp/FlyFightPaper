-- In-match quick menu: a clipboard over the dimmed game (the match keeps going behind it).
-- Leaving asks first on a sticky note, because it ends this life and streak.
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local PauseScreen = {}

-- api = { resume(), hangar(), settings(), tutorial(), leave() }
function PauseScreen.new(playerGui, api)
	local cover, sheet = PaperUI.screen(playerGui, "PauseScreen", {})
	local image, words, button = PaperUI.image, PaperUI.words, PaperUI.button
	local strip = Art.mainmenu.strip
	local board = image(sheet, "Clipboard", Art.ingame.clipboard, 610, 40, 700, 1000, 0)
	local title = words(sheet, "Title", "Still flying!", 700, 215, 520, 90, 70)
	title.TextXAlignment = Enum.TextXAlignment.Center
	local note = words(sheet, "Note", "Your plane keeps flying and can be hit while this is open.", 700, 300, 520, 80, 30)
	note.TextXAlignment, note.TextWrapped = Enum.TextXAlignment.Center, true
	local confirm = Instance.new("Frame")
	confirm.Name, confirm.BackgroundTransparency, confirm.Size, confirm.Visible = "Confirm", 1, UDim2.fromOffset(PaperUI.W, PaperUI.H), false
	confirm.ZIndex, confirm.Parent = 5, sheet
	local pieces = { board, title, note,
		button(sheet, "Resume", strip.yellow, "Keep flying", 700, 400, 520, 120, -1, api.resume, 72),
		button(sheet, "Hangar", strip.blue, "Hangar", 715, 530, 490, 100, 1, api.hangar),
		button(sheet, "Settings", strip.green, "Settings", 715, 640, 490, 100, -1, api.settings),
		button(sheet, "Tutorial", strip.yellow, "Training", 715, 750, 490, 100, 0.5, api.tutorial),
		button(sheet, "Leave", strip.red, "Leave match", 715, 860, 490, 100, -0.5, function() confirm.Visible = true end, 64),
	}
	-- The sticky note sits on top of the clipboard when you press Leave.
	image(confirm, "Sticky", Art.ingame.stickyNote, 660, 260, 600, 540, 3)
	local ask = words(confirm, "Ask", "Leave the match?\nYou keep what you earned, but this life and streak end.", 720, 350, 480, 230, 40)
	ask.TextXAlignment, ask.TextWrapped = Enum.TextXAlignment.Center, true
	button(confirm, "ConfirmLeave", strip.red, "Leave", 720, 610, 220, 100, -2, function() confirm.Visible = false; api.leave() end, 52)
	button(confirm, "CancelLeave", strip.green, "Stay", 980, 610, 220, 100, 2, function() confirm.Visible = false end, 52)
	PaperUI.popIn(cover, pieces)
	cover:GetPropertyChangedSignal("Visible"):Connect(function() if not cover.Visible then confirm.Visible = false end end)

	local self = { frame = cover }
	function self.update() end
	return self
end

return PauseScreen
