-- The winners' cutscene (Alan 2026-10-17, docs/decisions/2026-10-17-rounds-never-stop.md, "Revised"): the camera
-- glides from wherever you are (your plane or the hangar) to the winner desks by the chalkboard. Local copies of the
-- top 3 take the place of the students sitting there, stand up on their chairs, jump onto the desks and emote, then
-- the camera glides back. It all happens on this screen only: the server's seated avatars are just hidden here.
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rounds = require(Root.Generated.Gameplay).rounds

local PLACES = { "1st", "2nd", "3rd" }
local COLORS = { Color3.fromRGB(255, 205, 40), Color3.fromRGB(220, 225, 235), Color3.fromRGB(230, 140, 70) }
local EMOTES = { "rbxassetid://507771019", "rbxassetid://507770677", "rbxassetid://507770239" } -- Roblox R15 dance, cheer, wave
local SEATED = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" }
local BANNER, GLIDE, STAND, JUMP, STAGGER = 1.2, 2.0, 0.6, 0.7, 0.3 -- seconds; 3rd moves first, then 2nd, then 1st
local ARC = 250 -- studs the camera rises mid-glide, so it sweeps over the room instead of skimming through it
-- The shot, from the room side of the desks, above the town's roofs (tried in Studio 2026-10-17): distance back,
-- height, the height it looks at, how far it looks right of the winners so they stand clear of the results card
-- on the right of the screen, a slightly wide lens so all three desks fit, and a slow push in while it holds.
local SHOT_BACK, SHOT_UP, SHOT_AIM_Y, SHOT_SHIFT, SHOT_FOV, PUSH_IN = 600, 340, 150, 350, 80, 0.08

local Cutscene = {}
local active

local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function setHidden(model, hidden)
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("Decal") then item.LocalTransparencyModifier = hidden and 1 or 0 end
	end
end

-- The chair nearest a point, and a frame at it that faces away from its desk (seats are the same in both rows).
local function chairAt(room, position)
	local best, distance = nil, 200
	for _, chair in room:GetChildren() do
		if chair.Name:match("^Chair") and chair:IsA("BasePart") and flat(chair.Position - position).Magnitude < distance then
			best, distance = chair, flat(chair.Position - position).Magnitude
		end
	end
	return best
end
local function seatFrame(room, chair)
	local desk = room:FindFirstChild("Desk" .. chair.Name:sub(6))
	return CFrame.lookAt(chair.Position, chair.Position + flat(chair.Position - desk.Position))
end

local function play(track) track:Play(0); track.TimePosition = math.min(0.2, track.Length * 0.5); track:AdjustSpeed(0) end

-- A local copy of a winner's seated avatar, moved to sit in the chair at `desk`.
local function copyWinner(room, source, desk, place, name)
	local fromChair, toChair = chairAt(room, source:GetPivot().Position), room:FindFirstChild("Chair" .. desk.Name:sub(5))
	if not fromChair or not toChair then return nil end
	source.Archivable = true
	local model = source:Clone()
	for _, item in model:GetDescendants() do
		if item.Name == "Collision" or item:IsA("BillboardGui") or item:IsA("Animation") then item:Destroy()
		elseif item:IsA("BasePart") or item:IsA("Decal") then item.LocalTransparencyModifier = 0 end
	end
	local humanoid, rootPart = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or not rootPart then model:Destroy(); return nil end
	model.Name = "Winner" .. place
	model:PivotTo(seatFrame(room, toChair) * seatFrame(room, fromChair):ToObjectSpace(source:GetPivot()))
	model.Parent = workspace
	local function load(id)
		local animation = Instance.new("Animation"); animation.AnimationId = id
		return animator:LoadAnimation(animation)
	end
	local seated = load(SEATED[humanoid.RigType] or SEATED[Enum.HumanoidRigType.R15])
	seated.Priority = Enum.AnimationPriority.Action
	play(seated)
	task.spawn(function() -- the pose needs the animation loaded to hold still on the right frame
		local deadline = os.clock() + 5
		repeat RunService.Heartbeat:Wait() until seated.Length > 0 or os.clock() > deadline
		if seated.IsPlaying and seated.Speed == 0 then play(seated) end
	end)
	local emote = load(EMOTES[place]); emote.Looped, emote.Priority = true, Enum.AnimationPriority.Action
	-- Feet sit this far below the root: hip height plus half the root for R15, the legs for R6.
	local leg = model:FindFirstChild("Left Leg")
	local feet = humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.HipHeight + rootPart.Size.Y / 2 or rootPart.Size.Y / 2 + (leg and leg.Size.Y or 2)
	local middle = Vector3.new(0, 0, 0)
	local facing = flat(middle - desk.Position).Unit
	local onChair = toChair.Position + Vector3.new(0, toChair.Size.Y / 2 + feet, 0)
	local onDesk = desk.Position + Vector3.new(0, desk.Size.Y / 2 + feet, 0) + facing * desk.Size.Z * 0.15
	local tag = Instance.new("BillboardGui")
	local head = model:FindFirstChild("Head")
	local above = head and rootPart.CFrame:PointToObjectSpace(head.Position).Y + head.Size.Y / 2 + 15 or feet
	tag.Size, tag.StudsOffsetWorldSpace, tag.LightInfluence, tag.Parent = UDim2.fromOffset(320, 64), Vector3.new(0, above, 0), 0, model
	tag.Adornee = rootPart
	local words = Instance.new("TextLabel")
	words.Size, words.BackgroundTransparency, words.TextScaled = UDim2.fromScale(1, 1), 1, true
	words.FontFace, words.TextColor3, words.Text = Font.fromEnum(Enum.Font.PermanentMarker), COLORS[place], PLACES[place] .. "  " .. name
	local stroke = Instance.new("UIStroke"); stroke.Thickness, stroke.Parent = 3, words
	words.Parent = tag
	local hips
	for _, joint in model:GetDescendants() do
		if joint.Name == "Root" and (joint:IsA("AnimationConstraint") or joint:IsA("Motor6D")) then hips = joint end
	end
	return { model = model, seated = seated, emote = emote, from = model:GetPivot(), place = place, hips = hips, scale = model:GetScale(),
		chair = CFrame.lookAt(onChair, onChair + facing), desk = CFrame.lookAt(onDesk, onDesk + facing), stood = false, landed = false }
end

-- Where each winner is at `t` seconds after the camera arrived: standing up on the chair, then hopping onto the desk.
local function moveWinner(w, t)
	t -= (3 - w.place) * STAGGER
	if t < 0 then return end
	if not w.stood then w.stood = true; w.seated:Stop(STAND) end
	if t < STAND then
		w.model:PivotTo(w.from:Lerp(w.chair, ease(t / STAND)))
	elseif t < STAND + JUMP then
		local a = (t - STAND) / JUMP
		w.model:PivotTo(w.chair:Lerp(w.desk, a) + Vector3.new(0, math.sin(a * math.pi) * 70, 0))
	elseif not w.landed then
		w.landed = true; w.model:PivotTo(w.desk); w.emote:Play(0.2)
	end
end

-- winners: { { actorId, displayName }, ... } in place order. onStage("banner" | "card" | "back") as it moves on.
function Cutscene.play(winners, onStage)
	Cutscene.stop()
	local room = workspace:FindFirstChild("Arena")
	local desks = {}
	for i, name in Rounds.winner_desks do desks[i] = room and room:FindFirstChild(name) end
	if not room or #desks < 3 then return end
	local camera = workspace.CurrentCamera
	local center = (desks[1].Position + desks[2].Position + desks[3].Position) / 3
	local back = flat(-center).Unit
	local right = Vector3.yAxis:Cross(back) -- screen right when looking at the desks from the room side
	local aim = Vector3.new(center.X, SHOT_AIM_Y, center.Z) + right * SHOT_SHIFT
	local eye = center + back * SHOT_BACK + Vector3.new(0, SHOT_UP, 0) + right * SHOT_SHIFT
	local shot = CFrame.lookAt(eye, aim)
	local closer = CFrame.lookAt(eye:Lerp(aim, PUSH_IN), aim)
	local state = { start = os.clock(), winners = {}, hidden = {}, stage = "banner", cameraType = camera.CameraType, fov = camera.FieldOfView, written = nil, home = camera.CFrame }
	active = state
	Root:SetAttribute("Cutscene", true)
	onStage("banner")

	-- Students at the winner desks step out of sight on this screen; copies of the winners take their seats.
	local function seatWinners()
		for place, desk in desks do
			local row = winners[place]
			if row and not state.winners[place] then
				for _, source in room:GetChildren() do
					if source:IsA("Model") and source:GetAttribute("PilotId") == row.actorId then
						state.winners[place] = copyWinner(room, source, desk, place, row.displayName)
						break
					end
				end
				local chair = state.winners[place] and room:FindFirstChild("Chair" .. desk.Name:sub(5))
				for _, model in room:GetChildren() do
					if chair and model:GetAttribute("SeatedAvatar") and flat(model:GetPivot().Position - chair.Position).Magnitude < 120 then
						state.hidden[model] = true; setHidden(model, true)
					end
				end
			end
		end
	end
	seatWinners()

	-- Roblox scales an animation's hip movement twice on a scaled-up avatar (27 x 27 instead of 27, measured
	-- 2026-10-17), which throws the body far off its root. Once standing, take the extra scale back out each step.
	state.fixHips = RunService.PreSimulation:Connect(function()
		for _, w in state.winners do
			if w.stood and w.hips then w.hips.Transform = w.hips.Transform.Rotation + w.hips.Transform.Position / w.scale end
		end
	end)

	local arrive = BANNER + GLIDE
	local leave = Rounds.results_seconds - GLIDE - 0.3
	RunService:BindToRenderStep("WinnersCutscene", Enum.RenderPriority.Camera.Value + 3, function()
		local t = os.clock() - state.start
		-- The camera as the game would show it this frame (your plane or hangar view); if nothing moved it, where it was.
		local live = camera.CFrame ~= state.written and camera.CFrame or state.home
		local liveFov = camera.CFrame ~= state.written and camera.FieldOfView or state.fov
		state.home, state.fov = live, liveFov
		local hold = closer:Lerp(shot, 1 - ease((t - arrive) / (leave - arrive)))
		local view, fov
		if t < BANNER then view, fov = live, liveFov
		elseif t < arrive then
			local a = ease((t - BANNER) / GLIDE)
			view, fov = live:Lerp(shot, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), liveFov + (SHOT_FOV - liveFov) * a
		elseif t < leave then view, fov = hold, SHOT_FOV
		else
			local a = ease((t - leave) / GLIDE)
			view, fov = hold:Lerp(live, a) + Vector3.new(0, math.sin(a * math.pi) * ARC, 0), SHOT_FOV + (liveFov - SHOT_FOV) * a
		end
		if t < arrive then seatWinners() end
		for _, w in state.winners do moveWinner(w, t - arrive) end
		local stage = t < arrive and "banner" or t < leave and "card" or "back"
		if stage ~= state.stage then state.stage = stage; onStage(stage) end
		if t >= leave + GLIDE then Cutscene.stop(); return end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame, camera.FieldOfView = view, fov
		state.written = view
	end)
end

function Cutscene.stop()
	if not active then return end
	local state = active
	active = nil
	RunService:UnbindFromRenderStep("WinnersCutscene")
	if state.fixHips then state.fixHips:Disconnect() end
	for _, w in state.winners do w.model:Destroy() end
	for model in state.hidden do if model.Parent then setHidden(model, false) end end
	workspace.CurrentCamera.CameraType, workspace.CurrentCamera.FieldOfView = state.cameraType, state.fov
	Root:SetAttribute("Cutscene", false)
end

return Cutscene
