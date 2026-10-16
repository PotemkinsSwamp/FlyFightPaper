-- Moves the bell tower clocks' hands to the real time on this client only (no network traffic). Each hand is
-- placed pointing at 12; PIVOT is the clock centre measured from the hand's box centre
-- (assets/models/bell-tower/clock/checks.json "pivot_offset_xyz": Blender x, y, z -> Roblox -x, z, y).
local RunService = game:GetService("RunService")

local PIVOT = { ["clock-hour"] = CFrame.new(0, -7.3, 1.42), ["clock-minute"] = CFrame.new(0, -9.3, 1.87) }

local TowerClock = {}

local function angle(name)
	local now = os.date("*t")
	local minutes = now.min + now.sec / 60
	if name == "clock-minute" then return minutes / 60 * math.pi * 2 end
	return ((now.hour % 12) + minutes / 60) / 12 * math.pi * 2
end

function TowerClock.start()
	local hands = {} -- part -> the CFrame it was placed at (pointing at 12)
	local function track(part)
		if PIVOT[part.Name] and part:IsA("BasePart") then hands[part] = part.CFrame end
	end
	for _, part in ipairs(workspace:GetDescendants()) do track(part) end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(part) hands[part] = nil end)
	local shown = -1
	RunService.Heartbeat:Connect(function()
		local second = os.time()
		if second == shown then return end -- ponytail: hands tick once a second, nothing to do in between
		shown = second
		for part, placed in pairs(hands) do
			local pivot = placed * PIVOT[part.Name]
			-- The face looks out along the hand's -Z, so someone in front looks along +Z: a positive turn is clockwise.
			part.CFrame = pivot * CFrame.Angles(0, 0, angle(part.Name)) * pivot:ToObjectSpace(placed)
		end
	end)
end

return TowerClock
