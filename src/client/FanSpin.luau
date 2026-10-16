-- Turns the floor fans' blades on this client only (no network traffic). The blades are their own mesh
-- (tools/art/split_parts.py); AXIS is where they turn, from the mesh's bounding-box centre
-- (assets/models/toys/floor-fan-blades/checks.json "axis": Blender x, y -> Roblox x, z).
-- Also the ceiling ducts' fans (on server time, so the blades match the server's clip check) and the blower.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local DuctRules = require(Root.Shared.DuctRules)
local Ducts = require(Root.Generated.Gameplay).world.ducts

local AXIS = CFrame.new(0.477, 0, -2.05)
local TURNS_PER_SECOND = 1.5 -- ponytail: slow enough to read as spinning at 60 FPS; a real fan would just blur

local FanSpin = {}

function FanSpin.start()
	local blades = {} -- part -> the CFrame it was placed at
	local ductBlades = {} -- part -> { placed CFrame, fan frame, fan index (nil for the blower) }
	local blower = DuctRules.blowerFrame()
	local function track(part)
		if part.Name == "floor-fan-blades" and part:IsA("BasePart") then blades[part] = part.CFrame end
		if part.Name == "DuctFanBlade" then
			local index = part:GetAttribute("DuctFan")
			ductBlades[part] = { part.CFrame, index and DuctRules.fanFrame(Ducts.fans.spots[index]) or blower, index }
		end
	end
	for _, part in ipairs(workspace:GetDescendants()) do track(part) end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(part) blades[part] = nil; ductBlades[part] = nil end)
	RunService.RenderStepped:Connect(function()
		local turn = CFrame.Angles(0, os.clock() * TURNS_PER_SECOND * math.pi * 2, 0)
		for part, placed in pairs(blades) do
			local axis = placed * AXIS
			part.CFrame = axis * turn * axis:ToObjectSpace(placed)
		end
		local now = workspace:GetServerTimeNow()
		for part, entry in pairs(ductBlades) do
			local placed, frame, index = entry[1], entry[2], entry[3]
			local spin = index and CFrame.Angles(0, 0, DuctRules.fanAngle(now, index)) or CFrame.Angles(0, 0, (now % math.pi) * 2) -- wrapped: see DuctRules.fanAngle
			part.CFrame = frame * spin * frame:ToObjectSpace(placed)
		end
	end)
end

return FanSpin
