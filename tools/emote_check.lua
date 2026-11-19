-- Numbers for emote body moves before anyone looks at them (docs/workshop/emote-making.md, step 3). Run in Studio's
-- Edit through the Studio link. Reads every KeyframeSequence under FOLDER (Roblox's Prompt to Animation leaves its
-- clips in ServerStorage.RBX_ASSISTANT_ANIMGEN) and works each part's place out from the R15 rig's own joints (no
-- playing needed): length; how far the hips and feet wander; the right hand's fastest moment (when, how fast against
-- the average before it, and which way: forward is -Z), its top forward speed and furthest reach; how much the hand still moves in the last half second.
-- Set RIG to an R15 model (the generator's own Workspace.Rig by default). Returns one line a clip.
local FOLDER = game.ServerStorage:FindFirstChild("RBX_ASSISTANT_ANIMGEN")
local RIG = workspace:FindFirstChild("Rig")
assert(FOLDER and RIG, "need the clips folder and an R15 rig")

-- Each rig part's joint: where it hangs on its parent (old rigs: Motor6D; new ones: AnimationConstraint).
local joints = {}
for _, j in RIG:GetDescendants() do
	if j:IsA("Motor6D") and j.Part1 then
		joints[j.Part1.Name] = { parent = j.Part0.Name, c0 = j.C0, c1 = j.C1 }
	elseif j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
		joints[j.Attachment1.Parent.Name] = { parent = j.Attachment0.Parent.Name, c0 = j.Attachment0.CFrame, c1 = j.Attachment1.CFrame }
	end
end
-- Each part's CFrame in the root's frame for one keyframe, walking the clip's own pose tree. The generator's clips
-- carry extra bones a plain R15 avatar doesn't have (Spine, Chest, clavicles, toes): their turns are passed down to
-- the next real part, which is close to what Roblox does when it fits the clip to an avatar (the real proof is Play).
local function placed(keyframe)
	local done = { HumanoidRootPart = CFrame.identity }
	local function walk(pose, parentPart, carried)
		for _, child in pose:GetChildren() do
			if not child:IsA("Pose") then continue end
			local joint = joints[child.Name]
			if joint and done[joint.parent] then
				done[child.Name] = done[joint.parent] * joint.c0 * carried * child.CFrame * joint.c1:Inverse()
				walk(child, child.Name, CFrame.identity)
			else
				walk(child, parentPart, carried * child.CFrame.Rotation)
			end
		end
	end
	for _, top in keyframe:GetChildren() do
		if top:IsA("Pose") then walk(top, "HumanoidRootPart", CFrame.identity) end
	end
	return done
end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local lines = {}
for _, clip in FOLDER:GetChildren() do
	if not clip:IsA("KeyframeSequence") then continue end
	local frames = clip:GetKeyframes()
	table.sort(frames, function(a, b) return a.Time < b.Time end)
	local track = {}
	for i, frame in frames do
		local at = placed(frame)
		track[i] = { t = frame.Time, hand = at.RightHand.Position, hips = at.LowerTorso.Position,
			footL = at.LeftFoot.Position, footR = at.RightFoot.Position }
	end
	local first, last = track[1], track[#track]
	local hips, feet, top, topAt, topDir = 0, 0, 0, 0, Vector3.zero
	local reach, reachAt, forward, forwardAt = 0, 0, 0, 0 -- the hand's furthest point forward of the hips; its top forward speed
	local speeds = {}
	for i, f in track do
		hips = math.max(hips, flat(f.hips - first.hips).Magnitude)
		feet = math.max(feet, flat(f.footL - first.footL).Magnitude, flat(f.footR - first.footR).Magnitude)
		if f.hips.Z - f.hand.Z > reach then reach, reachAt = f.hips.Z - f.hand.Z, f.t end
		if i > 1 then
			local step = f.hand - track[i - 1].hand
			local dt = math.max(f.t - track[i - 1].t, 1e-3)
			local speed = step.Magnitude / dt
			speeds[i] = speed
			if speed > top then top, topAt, topDir = speed, f.t, step.Unit end
			if -step.Z / dt > forward then forward, forwardAt = -step.Z / dt, f.t end
		end
	end
	local before, count, hold = 0, 0, 0
	for i, f in track do
		if i > 1 and f.t < topAt - 0.15 then before += speeds[i]; count += 1 end
		if f.t >= last.t - 0.5 then hold = math.max(hold, (f.hand - last.hand).Magnitude) end
	end
	local windUp = count > 0 and before / count or 0
	table.insert(lines, string.format(
		"%s: %.2f s, %d keys | hips wander %.2f, feet %.2f studs | hand top speed %.1f studs/s at %.2f s (%.1fx the wind-up), heading %.2f, %.2f, %.2f | top forward speed %.1f at %.2f s, furthest forward %.2f studs at %.2f s | last 0.5 s hand moves %.2f",
		clip.Name, last.t, #track, hips, feet, top, topAt, windUp > 0 and top / windUp or 0, topDir.X, topDir.Y, topDir.Z, forward, forwardAt, reach, reachAt, hold))
end
return table.concat(lines, "\n")
