-- "Waiting for a desk" on a sticky note over the dimmed classroom (no desk is free yet when you press Play).
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Art = require(Root.Shared.UIAssets)
local PaperUI = require(script.Parent.PaperUI)
local TweenService = game:GetService("TweenService")
local WaitScreen = {}

-- api = { cancel() }
function WaitScreen.new(playerGui, api)
	-- On the dimmed bulletin board (the camera only sees the floor before you have a desk).
	local cover, sheet = PaperUI.screen(playerGui, "WaitScreen", Art.mainmenu.bg)
	local dim = Instance.new("Frame")
	dim.Name, dim.Size, dim.BackgroundColor3, dim.BackgroundTransparency, dim.Parent = "Dim", UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 0.45, sheet
	local note = PaperUI.image(sheet, "Sticky", Art.ingame.stickyNote, 610, 200, 700, 640, -2)
	local title = PaperUI.words(note, "Title", "Waiting for a desk...", 60, 130, 580, 90, 60)
	title.TextXAlignment = Enum.TextXAlignment.Center
	local body = PaperUI.words(note, "Body", "Every desk is taken right now. Your plane appears as soon as a pilot lands or respawns.", 80, 230, 540, 190, 40)
	body.TextXAlignment, body.TextWrapped = Enum.TextXAlignment.Center, true
	PaperUI.button(note, "Cancel", Art.mainmenu.strip.red, "Back to menu", 160, 450, 380, 100, 2, api.cancel, 46)
	-- The paper plane circles above the note while you wait.
	local plane = PaperUI.image(sheet, "Plane", Art.mainmenu.plane, 820, 90, 280, 190, 0)
	TweenService:Create(plane, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = plane.Position + UDim2.fromOffset(60, -20), Rotation = 10,
	}):Play()

	local self = { frame = cover }
	function self.update() end
	return self
end

return WaitScreen
