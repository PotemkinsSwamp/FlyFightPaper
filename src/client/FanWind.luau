-- Visible air over the two floor fans, on this client only: white wind swirls and paper bits rising through each
-- updraft column (Alan picked the swirls, assets/references/world-pieces/fan-wind.png). The column sizes come from
-- config; the pictures are drawn by tools/art/wind_sprites.py.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Gameplay = require(Root.Generated.Gameplay)

local SWIRL = "rbxassetid://85637394548007"
local PAPER = "rbxassetid://136515946422329"

local FanWind = {}

local function emitter(texture, rate, speed, size)
	local e = Instance.new("ParticleEmitter")
	e.Texture, e.Rate, e.LightInfluence = texture, rate, 0.1
	e.EmissionDirection = Enum.NormalId.Top
	e.Speed = speed
	e.SpreadAngle = Vector2.new(8, 8)
	e.Size = size
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 1) })
	return e
end

function FanWind.start()
	local folder = Instance.new("Folder")
	folder.Name = "FanWind"
	for _, fan in ipairs(Gameplay.world.fans) do
		if fan.kind == "upward" then
			local c, h = fan.center, fan.halfsize
			-- An emitter part as wide as the column, at its floor; particles live long enough to reach the top.
			local base = Instance.new("Part")
			base.Name, base.Anchored, base.CanCollide, base.CanQuery, base.CanTouch, base.Transparency = fan.id, true, false, false, false, 1
			base.Size = Vector3.new(h[1] * 1.4, 1, h[3] * 1.4)
			base.Position = Vector3.new(c[1], c[2] - h[2] + 10, c[3])
			local height = h[2] * 2
			local swirl = emitter(SWIRL, 9, NumberRange.new(85, 110), NumberSequence.new({ NumberSequenceKeypoint.new(0, 18), NumberSequenceKeypoint.new(1, 30) }))
			swirl.Lifetime = NumberRange.new(height / 110, height / 85)
			swirl.Rotation = NumberRange.new(-8, 8) -- facing the camera, upright: the line reads as rising air
			swirl.Parent = base
			local paper = emitter(PAPER, 12, NumberRange.new(70, 100), NumberSequence.new(4))
			paper.Lifetime = NumberRange.new(height / 100, height / 70)
			paper.Rotation, paper.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-180, 180)
			paper.Drag = 0.2
			paper.Acceleration = Vector3.new(0, 8, 0)
			paper.Parent = base
			base.Parent = folder
		end
	end
	-- Moving air in the ducts (fans, the blower): swirls and paper bits streaming the way the air blows.
	local DuctRules = require(Root.Shared.DuctRules)
	for _, wind in ipairs(DuctRules.winds()) do
		local length = math.abs(wind.size:Dot(wind.flow))
		local base = Instance.new("Part")
		base.Name, base.Anchored, base.CanCollide, base.CanQuery, base.CanTouch, base.Transparency = "DuctWind", true, false, false, false, 1
		base.Size = Vector3.new(Gameplay.world.ducts.width * 0.8, 1, Gameplay.world.ducts.height * 0.8)
		local at = wind.center - wind.flow * length / 2
		base.CFrame = CFrame.lookAt(at, at + wind.flow) * CFrame.Angles(-math.pi / 2, 0, 0) -- top face points downwind
		local speed = 60 + 200 * wind.strength
		local life = length / speed
		local swirl = emitter(SWIRL, 2 + 8 * wind.strength, NumberRange.new(speed * 0.9, speed), NumberSequence.new({ NumberSequenceKeypoint.new(0, 16), NumberSequenceKeypoint.new(1, 28) }))
		swirl.Lifetime, swirl.Rotation = NumberRange.new(life * 0.8, life), NumberRange.new(0, 360)
		swirl.Parent = base
		local paper = emitter(PAPER, 2 + 8 * wind.strength, NumberRange.new(speed * 0.8, speed * 1.1), NumberSequence.new(4))
		paper.Lifetime, paper.Rotation, paper.RotSpeed = NumberRange.new(life * 0.8, life), NumberRange.new(0, 360), NumberRange.new(-180, 180)
		paper.Parent = base
		base.Parent = folder
	end
	folder.Parent = workspace
end

return FanWind
