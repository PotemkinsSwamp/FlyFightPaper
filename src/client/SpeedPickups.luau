-- Shows the speed power-ups at the fly-throughs on this client only. The server owns pick-up and respawn
-- (FlightService: each marker's "ReadyAt"); here each marker gets a spinning, bobbing folded-paper bolt
-- (Assets.SpeedBolt, assets/models/toys/speed-bolt) that hides while it's taken.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")

local SPIN_PER_SECOND = 0.6
local BOB_STUDS = 2

local SpeedPickups = {}

local function token(marker)
	local bolt = Root.Assets:WaitForChild("SpeedBolt"):Clone()
	bolt.CastShadow = false
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture, sparkle.Rate, sparkle.Lifetime = "rbxasset://textures/particles/sparkles_main.dds", 4, NumberRange.new(0.6, 1)
	sparkle.Speed, sparkle.SpreadAngle = NumberRange.new(2, 5), Vector2.new(180, 180)
	sparkle.Color, sparkle.LightEmission = ColorSequence.new(Color3.fromRGB(255, 225, 140)), 0.2
	sparkle.Size = NumberSequence.new(0.8, 0)
	sparkle.Name = "Sparkle"
	sparkle.Parent = bolt
	bolt.Parent = marker
	return bolt
end

function SpeedPickups.start()
	local folder = workspace:WaitForChild("SpeedPickups")
	local tokens = {} -- marker -> bolt
	local function track(marker)
		if marker:IsA("BasePart") then tokens[marker] = token(marker) end
	end
	for _, marker in ipairs(folder:GetChildren()) do track(marker) end
	folder.ChildAdded:Connect(track)
	RunService.RenderStepped:Connect(function()
		local clock, now = os.clock(), workspace:GetServerTimeNow()
		for marker, bolt in pairs(tokens) do
			local ready = now >= (marker:GetAttribute("ReadyAt") or 0)
			bolt.Transparency = ready and 0 or 1
			bolt.CFrame = CFrame.new(marker.Position) * CFrame.new(0, math.sin(clock * 2) * BOB_STUDS, 0) * CFrame.Angles(0, clock * SPIN_PER_SECOND * math.pi * 2, 0)
			bolt.Sparkle.Enabled = ready
		end
	end)
end

return SpeedPickups
