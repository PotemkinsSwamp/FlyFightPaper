-- Points pop up just above your plane as you earn them (Alan's points workshop, 2026-10-14): number + word in
-- marker crayon, floating up and fading. Quick ones stack. The server sends one "score" event per earned row.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")

local WORDS = {
	fold = { "FOLD", Color3.fromRGB(255, 205, 40) },
	fold_assist = { "FOLD ASSIST", Color3.fromRGB(255, 240, 200) },
	first_fold = { "FIRST FOLD", Color3.fromRGB(255, 140, 50) },
	streak = { "STREAK", Color3.fromRGB(255, 140, 50) },
	revenge = { "REVENGE", Color3.fromRGB(255, 90, 80) },
	zone = { "ZONE", Color3.fromRGB(255, 225, 90) },
	target = { "TARGET", Color3.fromRGB(110, 225, 120) },
	prop = { "", Color3.fromRGB(235, 235, 235) },
}
local SECONDS, RISE, GAP = 1.3, 60, 48 -- how long one shows, how far it floats up, spacing between stacked ones (px at 1080p)

local ScorePopups = {}

function ScorePopups.start()
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "ScorePopups", false, true, 5
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local showing = {} -- labels still on screen, oldest first
	Root:WaitForChild("CombatEvents").OnClientEvent:Connect(function(events)
		for _, event in events do
			if event.kind ~= "score" or type(event.points) ~= "number" then continue end
			local word = WORDS[event.reason] or { "", Color3.new(1, 1, 1) }
			local scale = math.max(0.6, gui.AbsoluteSize.Y / 1080)
			-- Older pop-ups still showing move up a row so the new one has room. The holder
			-- carries that move; the label inside it does the float-up, so the two don't fight.
			for _, holder in showing do holder.Position -= UDim2.fromOffset(0, GAP * scale) end
			local holder = Instance.new("Frame")
			holder.AnchorPoint, holder.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
			holder.Position, holder.Size = UDim2.new(0.5, 0, 0.5, -90 * scale), UDim2.fromOffset(600 * scale, 56 * scale)
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency, label.Size = 1, UDim2.fromScale(1, 1)
			label.FontFace = Font.fromEnum(Enum.Font.PermanentMarker)
			label.TextSize, label.TextColor3 = 44 * scale, word[2]
			label.Text = string.format("+%d %s", event.points, word[1])
			local stroke = Instance.new("UIStroke")
			stroke.Thickness, stroke.Color = 3 * scale, Color3.fromRGB(28, 26, 30)
			stroke.Parent = label
			label.Parent = holder
			holder.Parent = gui
			table.insert(showing, holder)
			local info = TweenInfo.new(SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(label, info, { TextTransparency = 1, Position = UDim2.fromOffset(0, -RISE * scale) }):Play()
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
			task.delay(SECONDS, function()
				table.remove(showing, table.find(showing, holder))
				holder:Destroy()
			end)
		end
	end)
end

return ScorePopups
