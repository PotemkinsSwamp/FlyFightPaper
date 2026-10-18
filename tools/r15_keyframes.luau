-- Builds Roblox R15 KeyframeSequences from tools/meshy_to_r15.py output (NAME.r15.json) and, in Play, registers each
-- one under a temporary id for testing (AnimationClipProvider:RegisterAnimationClip, Studio only; run it on the Client
-- so the client can play it). Run through the Studio link with a table of clips put in front of this file:
--   local CLIPS = { ["plane-spin"] = [==[ ...json... ]==], ... }
-- e.g. python tools/studio_cli.py execute_luau with a code file that joins the two. Each temporary id is written to
-- the attribute "DevEmote_NAME" on ReplicatedStorage.FlyFightPaper; set "DevWinnerEmote" there to one of them to see
-- it as 1st place's emote in the winners' cutscene. Returns the ids.
local HttpService = game:GetService("HttpService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")

-- R15 joints, parent part first: each pose sits under its parent's pose in the KeyframeSequence.
local TREE = {
	HumanoidRootPart = { "LowerTorso" },
	LowerTorso = { "UpperTorso", "LeftUpperLeg", "RightUpperLeg" },
	UpperTorso = { "Head", "LeftUpperArm", "RightUpperArm" },
	LeftUpperArm = { "LeftLowerArm" }, LeftLowerArm = { "LeftHand" },
	RightUpperArm = { "RightLowerArm" }, RightLowerArm = { "RightHand" },
	LeftUpperLeg = { "LeftLowerLeg" }, LeftLowerLeg = { "LeftFoot" },
	RightUpperLeg = { "RightLowerLeg" }, RightLowerLeg = { "RightFoot" },
}

local function build(name, json)
	local clip = HttpService:JSONDecode(json)
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name, sequence.Loop, sequence.Priority = name, true, Enum.AnimationPriority.Action
	for _, frame in clip.frames do
		local keyframe = Instance.new("Keyframe")
		keyframe.Time, keyframe.Parent = frame.t, sequence
		local function add(partName, parent)
			local pose = Instance.new("Pose")
			pose.Name, pose.Weight = partName, 1
			pose.EasingStyle = Enum.PoseEasingStyle.Linear -- 15 keys a second already carry the motion's own curves
			local p = frame.poses[partName]
			if p then pose.CFrame = CFrame.new(p[1], p[2], p[3], p[4], p[5], p[6], p[7]) end
			pose.Parent = parent
			for _, child in TREE[partName] or {} do add(child, pose) end
		end
		add("HumanoidRootPart", keyframe)
	end
	return sequence
end

local ids = {}
for name, json in CLIPS do
	local sequence = build(name, json)
	local id = game:GetService("AnimationClipProvider"):RegisterAnimationClip(sequence)
	Root:SetAttribute("DevEmote_" .. name, id)
	ids[name] = id
end
return HttpService:JSONEncode(ids)
