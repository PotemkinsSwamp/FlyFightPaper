-- Moves the new town's toy monorail train on this client only (no network traffic): its three cars
-- (workspace ...MonorailTrain, parts car-1..car-3, from tools/town_toys.py build v4) follow MonorailRules on server
-- time, the same clock the server judges hits with.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local MonorailRules = require(Root.Shared.MonorailRules)
local Mono = require(Root.Generated.Gameplay).world.monorail

-- The uploaded car meshes should face +Z in Roblox (every Open Cloud FBX arrives turned 180 degrees,
-- docs/workshop/lessons.md; check the nose leads when the new town is in Studio); a CFrame looks along -Z, so turn
-- them. The back nose car is left unturned, so it faces backwards.
local MESH_TURN = CFrame.Angles(0, math.pi, 0)

local TrainMotion = {}

function TrainMotion.start()
	if not Mono.enabled then return end
	local parts
	RunService.RenderStepped:Connect(function()
		if not parts then
			local train = workspace:FindFirstChild("MonorailTrain", true)
			if not train then return end
			parts = {}
			for i = 1, #Mono.cars do parts[i] = train:FindFirstChild("car-" .. i) end
		end
		for i, car in ipairs(MonorailRules.cars(workspace:GetServerTimeNow())) do
			local part = parts[i]
			if part then part.CFrame = car.cframe * (car.turned and CFrame.identity or MESH_TURN) end
		end
	end)
end

return TrainMotion
