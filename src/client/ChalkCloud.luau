-- Chalk eraser cloud (MILESTONES D14, concept assets/references/mode-concepts/chalk-eraser.png): when the server
-- stamps CloudUntil on workspace.Arena.ChalkEraser, a thick chalk-dust cloud billows round it until then.
-- One sphere-volume particle emitter: a big puff at once, a steady top-up, nothing new in the last few seconds.
-- The top-up is launched by hand (Emit) because Roblox thins out an emitter's own Rate stream when the camera is
-- far away, and the cloud then barely showed from across the room.
-- Puffs are thick so planes inside are hard to see; their name tags are hidden (Alan 2026-10-14). With the camera
-- inside, the puffs are cleared and the room's haze turns chalk-white instead: big puffs filling the whole screen
-- were what cost frame rate.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Chalk = require(Root.Generated.Gameplay).world.chalk_eraser
local Rules = require(Root.Shared.CombatRules)

local ChalkCloud = {}
local eraser

local CHALK = Color3.fromRGB(246, 244, 238)
local PUFF = 0.72 -- largest puff, as a share of the cloud's current radius
local function live()
	local untilAt = eraser and eraser:GetAttribute("CloudUntil")
	return untilAt and untilAt - workspace:GetServerTimeNow() or 0
end

function ChalkCloud.start()
	eraser = workspace:WaitForChild("Arena"):WaitForChild("ChalkEraser", 30)
	if not eraser then return end
	local volume = Instance.new("Part")
	volume.Name, volume.Shape, volume.Transparency = "ChalkCloud", Enum.PartType.Ball, 1
	volume.Anchored, volume.CanCollide, volume.CanQuery, volume.CanTouch, volume.CastShadow = true, false, false, false, false
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Shape, dust.ShapeStyle, dust.ShapeInOut = Enum.ParticleEmitterShape.Sphere, Enum.ParticleEmitterShapeStyle.Volume, Enum.ParticleEmitterShapeInOut.Outward
	dust.Color = ColorSequence.new(CHALK)
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime, dust.Speed = NumberRange.new(5, 7), NumberRange.new(2, 8)
	dust.Rotation, dust.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-8, 8)
	dust.LightInfluence, dust.Enabled, dust.Parent = 0.4, false, volume
	volume.Parent = workspace
	-- Sized to the cloud's current radius: puffs start inside; their soft edges reach the radius.
	local function fit(radius)
		volume.Size = Vector3.one * math.max(1, radius * (1 - PUFF * 0.3) * 2)
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, radius * PUFF * 0.55), NumberSequenceKeypoint.new(1, radius * PUFF) })
	end
	fit(Chalk.radius)

	local inside = false
	local function puff()
		local left = live()
		if left > 0 then dust:Emit(math.floor(90 * math.min(1, left / Chalk.seconds))) end
	end
	local shown
	local function update()
		local untilAt, center = eraser:GetAttribute("CloudUntil"), eraser:GetAttribute("CloudAt")
		if live() <= 0 or not center or untilAt == shown then return end
		shown = untilAt
		volume.Position = center
		if not inside then puff() end
	end
	eraser:GetAttributeChangedSignal("CloudUntil"):Connect(update)
	update()

	-- Ready sign (Alan 2026-10-15): chalk blotches over the felt. Right after a puff the felt is clean (its own dark
	-- charcoal); over the cooldown the blotches slowly fade back in; lots of white with black showing through =
	-- ready to shoot again. The model's felt is its bottom 10.5 of 25 studs (assets/models/toys/chalk-eraser/checks.json).
	local body = eraser:FindFirstChildWhichIsA("BasePart")
	local coat = Instance.new("Part")
	coat.Name, coat.Transparency, coat.Size = "ChalkCoat", 1, Vector3.new(91.2, 11.2, 28.2) -- clear of the fuzzy felt
	coat.Anchored, coat.CanCollide, coat.CanQuery, coat.CanTouch, coat.CastShadow = true, false, false, false, false
	coat.CFrame = body.CFrame * CFrame.new(0, -body.Size.Y / 2 + 10.5 / 2, 0)
	local blotches = {} -- two layers of soft dust blobs on every face, at their loaded see-through amount
	for _, face in Enum.NormalId:GetEnumItems() do
		for _, layer in { { 14, 9, 0, 0, 0.15 }, { 9, 6, 4, 2, 0.35 } } do
			local blotch = Instance.new("Texture")
			blotch.Face, blotch.Texture, blotch.Color3 = face, "rbxasset://textures/particles/smoke_main.dds", CHALK
			blotch.StudsPerTileU, blotch.StudsPerTileV, blotch.OffsetStudsU, blotch.OffsetStudsV = layer[1], layer[2], layer[3], layer[4]
			blotch.Parent = coat
			blotches[blotch] = layer[5]
		end
	end
	coat.Parent = workspace
	local refills = {}
	local function chalkUp()
		for _, tween in refills do tween:Cancel() end
		table.clear(refills)
		local left = (eraser:GetAttribute("CloudReadyAt") or 0) - workspace:GetServerTimeNow()
		local share = 1 - math.clamp(left / Chalk.cooldown_seconds, 0, 1)
		for blotch, loaded in blotches do
			blotch.Transparency = 1 + (loaded - 1) * share
			if left > 0 then
				local tween = TweenService:Create(blotch, TweenInfo.new(left, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Transparency = loaded })
				tween:Play()
				table.insert(refills, tween)
			end
		end
	end
	eraser:GetAttributeChangedSignal("CloudReadyAt"):Connect(chalkUp)
	chalkUp()

	-- Ten times a second: the cloud shrinks with its radius; name tags of planes inside it are hidden (and shown again
	-- after); with the camera inside, the puffs give way to fog: clear up close, nothing past about 380 studs, like
	-- flying through real dust (Alan 2026-10-15). Classic fog only works with the room's Atmosphere set aside.
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local clearFog = { start = Lighting.FogStart, finish = Lighting.FogEnd, color = Lighting.FogColor }
	local function fog(on)
		if atmosphere then atmosphere.Parent = if on then nil else Lighting end
		Lighting.FogColor = if on then CHALK else clearFog.color
		Lighting.FogStart = if on then 40 else clearFog.start
		Lighting.FogEnd = if on then 380 else clearFog.finish
	end
	-- Plus a pale wash so it looks chalky.
	local wash = Instance.new("ColorCorrectionEffect")
	wash.Name, wash.TintColor, wash.Parent = "ChalkWash", Color3.new(1, 1, 1), Lighting
	local washed = { Brightness = 0.12, Contrast = -0.35, Saturation = -0.55, TintColor = Color3.fromRGB(255, 252, 245) }
	local plain = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }
	local tagsHidden, clock, topUp = false, 0, 0
	local planes = workspace:WaitForChild("Planes")
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock < 0.1 then return end
		clock = 0
		local cloudy = live() > 0
		local radius = Rules.chalkRadius(Chalk, eraser:GetAttribute("CloudUntil"), workspace:GetServerTimeNow())
		if cloudy then fit(radius) end
		if cloudy and not inside then -- 14 puffs a second at full size, fewer as it shrinks
			topUp += 1.4 * radius / Chalk.radius
			dust:Emit(math.floor(topUp)); topUp %= 1
		end
		if cloudy or tagsHidden then
			for _, plane in planes:GetChildren() do
				local body = plane:FindFirstChild("Root")
				local tag = body and body:FindFirstChild("PilotName")
				local text = tag and tag:FindFirstChildOfClass("TextLabel")
				if text then text.Visible = not (cloudy and ChalkCloud.blocks(workspace.CurrentCamera.CFrame.Position, body.Position)) end
			end
			tagsHidden = cloudy
		end
		local at = workspace.CurrentCamera.CFrame.Position
		local within = cloudy and ChalkCloud.blocks(at, at)
		if within == inside then return end
		inside = within
		if inside then dust:Clear() else puff() end
		fog(inside)
		TweenService:Create(wash, TweenInfo.new(0.4), inside and washed or plain):Play()
	end)
end

-- True while a live cloud lies on the line from `from` to `to`: name tags, outlines, screen markers, the lead marker
-- (aim assist) and edge arrows treat it like a wall.
function ChalkCloud.blocks(from, to)
	return Rules.chalkBlocks(eraser, from, to, workspace:GetServerTimeNow(), Chalk)
end

return ChalkCloud
