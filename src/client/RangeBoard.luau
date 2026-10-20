-- The Hangar Range's controls (RangeStage; docs/plan/TUTORIAL-PLAN.md "The Hangar Range"). In the Range the crosshair
-- is the cursor (Alan 2026-10-20): a click on a row plate or a board strip does what it says while the guns fire as
-- usual. Also here: the menu dropping on its strings with a little bounce and pulling back up, the score card, the red
-- rings on the picked loadout and difficulty, the loadout names, and keys 1-5 for the loadouts.
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local FlightState = require(script.Parent.FlightController).state
local Board = {}

local LIFT = 90 -- studs the folded menu hangs above the view (RangeStage MENU_LIFT)
local DROP = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- falls, overshoots, settles on its strings
local PULL = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5 }

function Board.start()
	local player = game:GetService("Players").LocalPlayer
	local action = Root:WaitForChild("RoundAction")
	local cast = RaycastParams.new()
	cast.FilterType = Enum.RaycastFilterType.Include
	local stage, sheet, up, isOpen, slide = nil, nil, nil, false, nil
	local presets = {}

	local function strip(what)
		for _, p in (sheet and sheet:GetChildren() or {}) do
			if p:GetAttribute("RangeBoard") == what then return p end
		end
	end
	-- The red rings follow the picked loadout and difficulty; the strips show the saved builds' names.
	local function refresh()
		if not sheet then return end
		for i, what in { "load" .. (player:GetAttribute("SelectedPreset") or 1), player:GetAttribute("RangeDifficulty") or "noob" } do
			local ring, on = sheet:FindFirstChild("Ring" .. i), strip(what)
			if ring and on then ring.CFrame = on.CFrame * CFrame.new(0, 0, 1) end
		end
		for slot = 1, 5 do
			local word = strip("load" .. slot) and strip("load" .. slot).SurfaceGui:FindFirstChildOfClass("TextLabel")
			local preset = presets[slot]
			if word then word.Text = slot .. "   " .. (preset and (preset.name ~= "" and preset.name or "Build " .. slot) or "(empty)") end
		end
	end
	local function score()
		local card = stage and stage:FindFirstChild("ScoreCard")
		if not card then return end
		local shots, hits = player:GetAttribute("RangeShots") or 0, player:GetAttribute("RangeHits") or 0
		local lines = { "Hits  " .. hits, "Shots  " .. shots, (shots > 0 and math.floor(hits / shots * 100 + 0.5) or 0) .. "%" }
		for i, text in lines do
			local line = card.SurfaceGui:FindFirstChild("Line" .. i)
			if line then line.Text = text end
		end
	end
	local function open(on)
		if not sheet or on == isOpen then return end
		isOpen = on
		if slide then slide:Cancel() end
		local pivot = Instance.new("CFrameValue")
		pivot.Value = sheet:GetPivot()
		pivot.Changed:Connect(function(cf) sheet:PivotTo(cf) end)
		slide = TweenService:Create(pivot, on and DROP or PULL, { Value = on and up - Vector3.new(0, LIFT, 0) or up })
		slide:Play()
		if on then refresh() end
	end
	local function hook(model)
		stage = model
		cast.FilterDescendantsInstances = { stage }
		sheet = stage:WaitForChild("RangeMenu", 10)
		if not sheet then return end
		up, isOpen = sheet:GetPivot(), false
		refresh()
		score()
	end
	workspace.ChildAdded:Connect(function(child) if child.Name == "RangeStage" then hook(child) end end)
	if workspace:FindFirstChild("RangeStage") then task.spawn(hook, workspace.RangeStage) end

	for _, key in { "RangeShots", "RangeHits" } do player:GetAttributeChangedSignal(key):Connect(score) end
	for _, key in { "SelectedPreset", "RangeDifficulty" } do player:GetAttributeChangedSignal(key):Connect(refresh) end
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		presets = profile.presets or {}
		refresh()
	end)

	-- A click (either button) on whatever the crosshair is over; FlightState.aimPoint is only set in the Range.
	local function click(what)
		if what == "menu" then open(not isOpen)
		elseif what == "close-menu" then open(false)
		elseif what == "hangar" then require(script.Parent.MenuController).show("hangar", true)
		else action:FireServer("range", what) end
	end
	Input.InputBegan:Connect(function(input, processed)
		if processed or not FlightState.aimPoint or not stage or not stage.Parent then return end
		if KEYS[input.KeyCode] then click("load" .. KEYS[input.KeyCode]) return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
		local hit = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, FlightState.aim * 1000, cast)
		local part = hit and hit.Instance
		local what = part and (part:GetAttribute("RangeBoard") or part:GetAttribute("RangePick"))
		if what then click(what) end
	end)
end

return Board
