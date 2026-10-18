-- The winners' stand-up-and-hop animation (Alan 2026-10-17: smoother than the code-moved pivots), as R15 keyframes.
-- Run in Studio through the Studio link: it builds the KeyframeSequence and returns it. WinnersCutscene moves the
-- body from the chair onto the desk itself (0.6 s standing, 0.7 s jump); this gives the body its motion on top:
-- push up out of the seat, crouch, spring, tuck in the air, reach, land with a squash, settle.
-- Angles are degrees about each joint's X (forward swing), Y (twist), Z (sideways); legs and arms swing forward
-- with +X, the waist leans forward with -X. "drop" lowers the hips (studs at normal avatar size) so feet stay down.
local FRAMES = {
	{ t = 0.00, drop = 0, waist = 0, hip = 90, knee = -90, ankle = 0, shoulder = 15, elbow = 20, spread = 0 }, -- seated
	{ t = 0.30, drop = -0.2, waist = -30, hip = 70, knee = -75, ankle = 5, shoulder = 45, elbow = 35, spread = 0 }, -- push up
	{ t = 0.55, drop = -0.45, waist = -15, hip = 45, knee = -85, ankle = 40, shoulder = -45, elbow = 15, spread = 0 }, -- crouch
	{ t = 0.72, drop = 0.1, waist = 5, hip = -5, knee = 0, ankle = -25, shoulder = 160, elbow = 10, spread = 10 }, -- spring
	{ t = 0.95, drop = 0, waist = -10, hip = 75, knee = -105, ankle = 10, shoulder = 100, elbow = 30, spread = 30 }, -- tuck
	{ t = 1.18, drop = 0, waist = -5, hip = 25, knee = -25, ankle = -10, shoulder = 70, elbow = 20, spread = 25 }, -- reach
	{ t = 1.32, drop = -0.6, waist = -25, hip = 70, knee = -110, ankle = 40, shoulder = 35, elbow = 40, spread = 10 }, -- land
	{ t = 1.65, drop = 0, waist = 0, hip = 0, knee = 0, ankle = 0, shoulder = 0, elbow = 0, spread = 0 }, -- settle
}

local function build()
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name, sequence.Loop, sequence.Priority = "WinnerHop", false, Enum.AnimationPriority.Action
	for _, f in FRAMES do
		local keyframe = Instance.new("Keyframe")
		keyframe.Time, keyframe.Parent = f.t, sequence
		local function pose(name, parent, x, z, offset)
			local p = Instance.new("Pose")
			p.Name, p.Weight = name, 1
			p.EasingStyle, p.EasingDirection = Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.InOut
			p.CFrame = CFrame.new(offset or Vector3.zero) * CFrame.Angles(math.rad(x or 0), 0, math.rad(z or 0))
			p.Parent = parent
			return p
		end
		local root = pose("HumanoidRootPart", keyframe)
		local lower = pose("LowerTorso", root, 0, 0, Vector3.new(0, f.drop, 0))
		local upper = pose("UpperTorso", lower, f.waist)
		pose("Head", upper, -f.waist * 0.5) -- keeps looking ahead while the body leans
		for side, sign in { Left = 1, Right = -1 } do
			local arm = pose(side .. "UpperArm", upper, f.shoulder, sign * -f.spread)
			pose(side .. "Hand", pose(side .. "LowerArm", arm, f.elbow))
			local leg = pose(side .. "UpperLeg", lower, f.hip)
			pose(side .. "Foot", pose(side .. "LowerLeg", leg, f.knee), f.ankle)
		end
	end
	return sequence
end

return build()
