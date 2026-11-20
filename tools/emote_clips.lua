-- Body-move clips and the runner-up emotes cut from them, side by side, as stills or a video, without Play
-- (docs/workshop/emote-making.md): one plain R15 test kid per entry stands in a row on 1st's desk in the real
-- classroom and is posed from keyframes (the same walk as tools/emote_check.lua and tools/emote_preview.lua: extra
-- bones passed down to the next real part, hips kept over the spot). Run in Studio's Edit:
--   _G.EMOTE_CLIPS = { "NapB", "cut:Nap", ... }  -- clips in ServerStorage.RBX_ASSISTANT_ANIMGEN, asset
--                                                -- ids, or "cut:<name>" for one of the CUTS below
--   _G.EMOTE_VIEW = { out = 330, side = 0, up = 80, at = 60 }  -- optional: the camera, in studs from the desk's middle
-- then this file; tools/emote_preview.py --lua=emote_clips.lua renders it (it calls _G.EMOTE.frame(t)).
-- _G.EMOTE.bake("Nap", parent, "NapClip") writes a cut as a plain looping R15 animation: what the game
-- registers in Studio (WinnersCutscene) and what gets uploaded.
local CLIPS = assert(_G.EMOTE_CLIPS, "set _G.EMOTE_CLIPS first")
local VIEW = _G.EMOTE_VIEW or {}
local HEIGHT, FOV, GAP = 140, 50, 150 -- a kid's height in the room; the lens; studs between kids

local function eased(v) v = math.clamp(v, 0, 1); return v * v * (3 - 2 * v) end
local function mix(a, b, s)
	local out = {}
	for name, cf in b do out[name] = (a[name] or cf):Lerp(cf, s) end
	return out
end
-- The runner-up emotes (Alan's OK 2026-11-20): each a loop of `length` seconds; `pose(t, c)` gives the turn of
-- every joint the cut moves at `t` (a joint it leaves out is left to what plays underneath), where c.<key>(seconds)
-- is the named generated clip's pose at its own seconds. Ids: the generator's uploads.
-- (Good Game's arms are not a cut: a first one, posed by numbers, Alan found stiff and too fast; the scene plays
-- Roblox's own clap and wave, in WinnersCutscene.)
local CUTS = {}
-- A cut may hold only some parts (here: what a stance needs): played one priority above another clip, it takes
-- just those parts and the other clip keeps the rest. (Good Game's first stance, a bent knee on its toes from
-- rbxassetid://98222857059913, Alan rejected: "the rested leg"; its cut is gone, the next one goes here.)
local STANCE = { "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local function only(parts, all)
	local out = {}
	for _, part in parts do out[part] = all[part] end
	return out
end

local Players = game:GetService("Players")
if _G.EMOTE and _G.EMOTE.clean then _G.EMOTE.clean() end
local E = {}
_G.EMOTE = E
local camera = workspace.CurrentCamera
local home = { cf = camera.CFrame, fov = camera.FieldOfView }
local desk = workspace.Arena.DeskNorth3
local back, right = Vector3.zAxis, Vector3.xAxis -- the kids face out into the room; screen right seen from there
local middle = Vector3.new(desk.Position.X, desk.Position.Y + desk.Size.Y / 2, desk.Position.Z)

local look = Instance.new("HumanoidDescription")
local skin, shirt, legs = Color3.fromRGB(234, 184, 146), Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172)
look.HeadColor, look.LeftArmColor, look.RightArmColor, look.TorsoColor, look.LeftLegColor, look.RightLegColor = skin, skin, skin, shirt, legs, legs
local first = Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
first:ScaleTo(HEIGHT / (first.Head.Position.Y + first.Head.Size.Y / 2 - (first.LeftFoot.Position.Y - first.LeftFoot.Size.Y / 2)))
local scale = first:GetScale()
local joints = {} -- part name -> where it hangs on its parent
for _, j in first:GetDescendants() do
	if j:IsA("Motor6D") and j.Part1 then
		joints[j.Part1.Name] = { parent = j.Part0.Name, c0 = j.C0, c1 = j.C1 }
	elseif j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
		joints[j.Attachment1.Parent.Name] = { parent = j.Attachment0.Parent.Name, c0 = j.Attachment0.CFrame, c1 = j.Attachment1.CFrame }
	end
end
for _, d in first:GetDescendants() do
	if d:IsA("Motor6D") or d:IsA("Constraint") or d:IsA("LuaSourceContainer") then d:Destroy()
	elseif d:IsA("BasePart") then d.Anchored = true end
end
local order = {} -- the parts, parents first
do
	local seen, added = { HumanoidRootPart = true }, true
	while added do
		added = false
		for name, joint in joints do
			if not seen[name] and seen[joint.parent] then seen[name], added = true, true; table.insert(order, name) end
		end
	end
end
-- A pose as every joint's own turn (what an animation stores), and back to each part's place in the root's frame.
local function build(turn)
	local at = { HumanoidRootPart = CFrame.identity }
	for _, name in order do
		local joint = joints[name]
		if at[joint.parent] then at[name] = at[joint.parent] * joint.c0 * (turn[name] or CFrame.identity) * joint.c1:Inverse() end
	end
	return at
end
-- One keyframe as joint turns; `hips0`: where this clip's hips started (they stay over it: no stepping off the desk).
local function turnsOf(keyframe, hips0)
	local done, turn = { HumanoidRootPart = CFrame.identity }, {}
	local function walk(pose, carried)
		for _, child in pose:GetChildren() do
			if not child:IsA("Pose") then continue end
			local joint = joints[child.Name]
			if joint and done[joint.parent] then
				local at = child.CFrame.Position * scale
				if child.Name == "LowerTorso" then
					hips0.at = hips0.at or at
					at = Vector3.new(hips0.at.X, at.Y, hips0.at.Z)
				end
				done[child.Name] = done[joint.parent] * joint.c0 * carried * (CFrame.new(at) * child.CFrame.Rotation) * joint.c1:Inverse()
				turn[child.Name] = (done[joint.parent] * joint.c0):Inverse() * done[child.Name] * joint.c1
				walk(child, CFrame.identity)
			else
				walk(child, carried * child.CFrame.Rotation)
			end
		end
	end
	for _, top in keyframe:GetChildren() do if top:IsA("Pose") then walk(top, CFrame.identity) end end
	return turn
end
local folder = game.ServerStorage:FindFirstChild("RBX_ASSISTANT_ANIMGEN")
-- A clip as a function of its own seconds (held at its ends), and its length.
local function clip(name)
	local source = name:find("^rbxassetid") and game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(name) or assert(folder and folder:FindFirstChild(name), "no clip " .. name)
	local keys = source:GetKeyframes()
	table.sort(keys, function(a, b) return a.Time < b.Time end)
	local hips0, list = {}, {}
	for k, key in keys do list[k] = { t = key.Time, turn = turnsOf(key, hips0) } end
	return function(t)
		local i = 1
		while i < #list - 1 and list[i + 1].t <= t do i += 1 end
		local a, b = list[i], list[math.min(i + 1, #list)]
		return mix(a.turn, b.turn, b.t > a.t and math.clamp((t - a.t) / (b.t - a.t), 0, 1) or 0)
	end, list[#list].t
end
-- A cut as a function of seconds (it loops), and its length.
local function cut(name)
	local recipe, c = assert(CUTS[name], "no cut " .. name), {}
	for key, id in recipe.clips do c[key] = clip(id) end
	return function(t) return recipe.pose(t % recipe.length, c) end, recipe.length
end
-- Standing straight (no clip): the feet's height under the root, so a sitting clip sits on the desk, not in the air.
local low = math.huge
for name, cf in build({}) do
	local part = first:FindFirstChild(name)
	if part then low = math.min(low, cf.Position.Y - part.Size.Y / 2) end
end

local kids, longest = {}, 0
for i, name in CLIPS do
	local cutName = name:match("^cut:(.+)")
	local pose, length
	if cutName then pose, length = cut(cutName) else pose, length = clip(name) end
	local kid = i == 1 and first or first:Clone()
	kid.Name = "EmoteClipKid" .. i
	local spot = middle + right * (i - (#CLIPS + 1) / 2) * GAP - Vector3.yAxis * low
	kid.Parent = workspace
	kids[i] = { model = kid, pose = pose, root = CFrame.lookAt(spot, spot + back) }
	longest = math.max(longest, length)
end

-- Whatever stands between the lens and the kids is hidden and put back by clean() (emote_preview.lua's walk).
local eye = middle + back * (VIEW.out or 330) + right * (VIEW.side or 0) + Vector3.yAxis * (VIEW.up or 80)
local hidden = {}
local toEye = Vector3.new(eye.X - middle.X, 0, eye.Z - middle.Z)
local reach, along = toEye.Magnitude, toEye.Unit
for _, part in workspace.Arena:GetDescendants() do
	if not part:IsA("BasePart") or part == desk or hidden[part] ~= nil then continue end
	local offset = part.Position - middle
	local forward, sideways = offset:Dot(along), math.abs(offset:Dot(along:Cross(Vector3.yAxis)))
	if forward > -60 and forward < reach + 10 and sideways < GAP * #CLIPS / 2 + 60 and offset.Y > 2 and offset.Y < 170 and part.Size.Magnitude < 300 then
		local top = part
		while top.Parent and top.Parent ~= workspace.Arena and top.Parent.Name ~= "CityToys" do top = top.Parent end
		for _, piece in top:IsA("BasePart") and { top, table.unpack(top:GetDescendants()) } or top:GetDescendants() do
			if piece:IsA("BasePart") and hidden[piece] == nil then hidden[piece] = piece.Transparency; piece.Transparency = 1 end
		end
	end
end

-- Every kid at `t` seconds.
function E.frame(t)
	for _, kid in kids do
		for name, cf in build(kid.pose(t)) do
			local part = kid.model:FindFirstChild(name)
			if part then part.CFrame = kid.root * cf end
		end
	end
	camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, FOV
	camera.CFrame = CFrame.lookAt(eye, middle + Vector3.yAxis * (VIEW.at or 60))
	task.wait(0.05)
	return "ok"
end
-- A cut as a plain R15 animation named `name` under `parent`, looping, 30 keys a second, its last key the same as
-- its first. `marks`: attributes for the scene to read (seconds of the moments its props follow).
function E.bake(cutName, parent, name, marks)
	local pose, length = cut(cutName)
	local out = Instance.new("KeyframeSequence")
	out.Name, out.Loop, out.Priority = name, true, Enum.AnimationPriority.Action
	for key, value in marks or {} do out:SetAttribute(key, value) end
	local last = math.floor(length * 30 + 0.5)
	for n = 0, last do
		local frame = Instance.new("Keyframe")
		frame.Time = n / 30
		local turn = pose(n == last and 0 or n / 30)
		local poses = { HumanoidRootPart = Instance.new("Pose") }
		poses.HumanoidRootPart.Name, poses.HumanoidRootPart.Parent = "HumanoidRootPart", frame
		local function add(part)
			if poses[part] then return poses[part] end
			local made = Instance.new("Pose")
			made.Name, made.Parent = part, add(joints[part].parent)
			if turn[part] then made.CFrame = turn[part].Rotation + turn[part].Position / scale
			else made.Weight = 0 end -- a part the cut leaves alone: whatever plays underneath (the standing idle) shows
			poses[part] = made
			return made
		end
		for _, part in order do if turn[part] then add(part) end end
		frame.Parent = out
	end
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	out.Parent = parent
	return string.format("ok baked %s: %.2f s", name, length)
end
function E.clean()
	for _, kid in kids do kid.model:Destroy() end
	for part, was in hidden do part.Transparency = was end
	camera.CFrame, camera.FieldOfView = home.cf, home.fov
	_G.EMOTE = nil
	task.wait(0.2) -- set last and after a wait: set first, Studio's camera stayed Scriptable
	camera.CameraType = Enum.CameraType.Fixed
end
return string.format("ready: %d kids, longest %.2f s, kid scale %.1f", #kids, longest, scale)
