-- Desk landing pieces on this client only (tools/desk_pieces.py places them): the paper-chain rings turn slowly
-- about the runway line while hovering (bob, sway, slight jitter), and the runway light tips blink in a chase from the ring toward the hangar.
local RunService = game:GetService("RunService")

local RING_TURNS_PER_SECOND = 0.05
local HOVER_BOB, HOVER_SWAY, HOVER_JITTER, HOVER_TILT = 1.2, 0.6, 0.15, math.rad(2) -- studs, studs, studs, radians
local CHASE_STUDS_PER_SECOND = 120 -- how fast the blink runs down the runway
local CHASE_GAP = 1.2 -- seconds between chases

local DeskPieces = {}

function DeskPieces.start()
	local rings, tips = {}, {} -- part -> the CFrame it was placed at; tip -> its delay along the chase
	local function track(part)
		if not part:IsA("BasePart") then return end
		if part.Name == "landing-ring" then rings[part] = part.CFrame
		elseif part.Name == "runway-light-tip" then tips[part] = false end
	end
	for _, part in ipairs(workspace:GetDescendants()) do track(part) end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(part) rings[part], tips[part] = nil, nil end)
	-- A tip's delay is its distance from the nearest ring, so each runway's chase starts at its own ring.
	local function delayFor(tip)
		local best = math.huge
		for _, placed in pairs(rings) do best = math.min(best, (placed.Position - tip.Position).Magnitude) end
		return best / CHASE_STUDS_PER_SECOND
	end
	local refresh = 0
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		local turn = CFrame.Angles(0, 0, now * RING_TURNS_PER_SECOND * math.pi * 2)
		for part, placed in pairs(rings) do
			-- Hovering: a slow bob plus a small uneven sway and tilt, each ring out of step with the others.
			local t = now + placed.Position.X * 0.01 + placed.Position.Z * 0.017
			local drift = Vector3.new(math.sin(t * 1.3) * HOVER_SWAY + math.sin(t * 3.1) * HOVER_JITTER,
				math.sin(t * 0.9) * HOVER_BOB + math.sin(t * 2.7) * HOVER_JITTER, 0)
			local tilt = CFrame.Angles(math.sin(t * 0.7) * HOVER_TILT, math.sin(t * 1.1) * HOVER_TILT, 0)
			part.CFrame = placed * CFrame.new(drift) * tilt * turn
		end
		refresh += dt
		if refresh < 0.05 then return end
		refresh = 0
		for tip, delay in pairs(tips) do
			if not delay then delay = delayFor(tip); tips[tip] = delay end
			-- Lit for a short moment as the chase passes; dim (not gone) the rest of the time.
			local phase = (now - delay) % CHASE_GAP
			tip.Transparency = phase < 0.18 and 0 or 0.65
		end
	end)
end

return DeskPieces
