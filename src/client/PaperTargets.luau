-- Hidden paper targets (Alan 2026-10-13, assets/references/mode-concepts/paper-targets.png): kid-drawn signs of
-- things kids dislike, standing on rooftops. Nothing points them out. Each player has their own set, drawn only on
-- their screen; the server checks the shots (CombatService, "paperTarget" events) and gives the points. A sign that
-- is hit tips over flat on its back and stays down until the next round.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules = require(Root.Shared.CombatRules)
local Art = require(Root.Shared.UIAssets).targets
local Signs = require(Root.Generated.Gameplay).world.paper_targets

local PaperTargets = {}

function PaperTargets.start()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "PaperTargets", workspace
	local half = Rules.PAPER_TARGET_HALF
	local signs = {}
	for index, row in ipairs(Signs) do
		local part = Instance.new("Part")
		part.Name, part.Size, part.Transparency = "PaperTarget", Vector3.new(half.X * 2, half.Y * 2, 0.2), 1
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local decal = Instance.new("Decal")
			decal.Texture, decal.Face, decal.Parent = Art[row.design] or "", face, part
		end
		local hinge = Rules.paperTargetPose(row) * CFrame.new(0, -half.Y, 0) -- bottom edge, on the roof
		local tilt = Instance.new("NumberValue")
		tilt:GetPropertyChangedSignal("Value"):Connect(function()
			part.CFrame = hinge * CFrame.Angles(math.rad(tilt.Value), 0, 0) * CFrame.new(0, half.Y, 0)
		end)
		part.CFrame, part.Parent = hinge * CFrame.new(0, half.Y, 0), folder
		signs[index] = tilt
	end
	local myId = tostring(Players.LocalPlayer.UserId)
	Root:WaitForChild("CombatEvents").OnClientEvent:Connect(function(events)
		for _, event in events do
			local tilt = event.kind == "paperTarget" and event.owner == myId and signs[event.index]
			if tilt then TweenService:Create(tilt, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), { Value = -90 }):Play() end
		end
	end)
	-- A new round stands them all back up.
	local round
	Root:WaitForChild("RoundView").OnClientEvent:Connect(function(snapshot)
		if snapshot.matchId == round then return end
		round = snapshot.matchId
		for _, tilt in signs do tilt.Value = 0 end
	end)
end

return PaperTargets
