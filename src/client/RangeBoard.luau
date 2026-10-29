-- The Hangar Range's controls (RangeStage; docs/plan/TUTORIAL-PLAN.md "The Hangar Range"). In the Range the crosshair
-- is the cursor (Alan 2026-10-19): a click on a row plate or a board strip does what it says while the guns fire as
-- usual, and on the game's own Menu button too. Also here: the menu dropping on its strings with a little bounce and
-- pulling back up, the score card, the red rings on the picked loadout and difficulty, the loadout names, keys 1-5.
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local FlightState = require(script.Parent.FlightController).state
local PaperUI = require(script.Parent.PaperUI)
local Board = {}

local LIFT = 90 -- studs the folded menu hangs above the view (RangeStage MENU_LIFT)
-- The menu rides a spring toward open or folded: it drops, overshoots a little on its strings and settles. A spring
-- (not a tween) so clicks mid-move just change where it heads (Alan 2026-10-19: tweens left it stuck halfway).
local SPRING, DAMP = 81, 11 -- 9 rad/s, damping 0.6: one small bounce, settled in under a second
local KEYS = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5 }

function Board.start()
	local player = game:GetService("Players").LocalPlayer
	local action = Root:WaitForChild("RoundAction")
	local cast = RaycastParams.new()
	cast.FilterType = Enum.RaycastFilterType.Include
	local stage, sheet, up, isOpen = nil, nil, nil, false
	local height, speed = LIFT, 0 -- how far above its open spot the menu hangs, and how fast that is changing
	local presets = {}
	local notes = require(script.Parent.RangeNotes).new(function() return stage and stage.Parent and stage or nil end,
		function() return isOpen end)

	local function strip(what)
		for _, p in (sheet and sheet:GetChildren() or {}) do
			if p:GetAttribute("RangeBoard") == what then return p end
		end
	end
	-- The red rings follow the picked loadout and difficulty; the strips show the Range builds' names.
	local function refresh()
		if not sheet then return end
		for i, what in { "load" .. (player:GetAttribute("RangeSlot") or 1), player:GetAttribute("RangeDifficulty") or "noob" } do
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
		isOpen = on
		if on then refresh() end
	end
	RunService.RenderStepped:Connect(function(dt)
		local goal = isOpen and 0 or LIFT
		if not sheet or not sheet.Parent or (height == goal and speed == 0) then return end
		dt = math.min(dt, 1 / 30)
		speed += (SPRING * (goal - height) - DAMP * speed) * dt
		height += speed * dt
		if math.abs(goal - height) < 0.05 and math.abs(speed) < 0.1 then height, speed = goal, 0 end
		sheet:PivotTo(up - Vector3.new(0, LIFT - height, 0))
	end)
	-- Phones: the Range Menu and Hangar strips (top left) sat under Roblox's own buttons, so they hang just right of the
	-- score card there instead (Alan 2026-10-28). Moved on this screen only: a phone taps them (TouchTapInWorld), and the
	-- taps and crosshair clicks are this screen's own raycasts.
	local corner = {} -- part -> where the server hung it
	local function fitCorner()
		local card, tab = stage and stage:FindFirstChild("ScoreCard"), nil
		for _, p in (stage and stage:GetChildren() or {}) do if p:GetAttribute("RangeBoard") == "menu" then tab = p end end
		if not card or not tab then return end
		if not next(corner) then
			for _, p in stage:GetChildren() do
				if not p:IsA("BasePart") then continue end
				local what = p:GetAttribute("RangeBoard")
				local along = (p.Position - tab.Position):Dot(card.CFrame.RightVector)
				if what == "menu" or what == "hangar" or p.Name == "String" and math.abs(along) < tab.Size.X then corner[p] = p.CFrame end
			end
		end
		local home = corner[tab]
		local axis = card.CFrame.RightVector * math.sign((card.Position - home.Position):Dot(card.CFrame.RightVector))
		local shift = PaperUI.isPhone() and axis * ((card.Position - home.Position):Dot(axis) + card.Size.X / 2 + 3 + tab.Size.X / 2) or Vector3.zero
		for p, at in corner do p.CFrame = at + shift end
	end
	PaperUI.onPhone(function() fitCorner() end)
	local function hook(model)
		stage = model
		table.clear(corner)
		cast.FilterDescendantsInstances = { stage }
		sheet = stage:WaitForChild("RangeMenu", 10)
		if not sheet then return end
		fitCorner()
		up, isOpen, height, speed = sheet:GetPivot(), false, LIFT, 0
		refresh()
		score()
	end
	workspace.ChildAdded:Connect(function(child) if child.Name == "RangeStage" then hook(child) end end)
	if workspace:FindFirstChild("RangeStage") then task.spawn(hook, workspace.RangeStage) end

	for _, key in { "RangeShots", "RangeHits" } do player:GetAttributeChangedSignal(key):Connect(score) end
	for _, key in { "RangeSlot", "RangeDifficulty" } do player:GetAttributeChangedSignal(key):Connect(refresh) end
	Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
		presets = profile.rangePresets or {}
		refresh()
	end)

	-- A click (either button) on whatever the crosshair is over; FlightState.aimPoint is only set in the Range.
	local function click(what)
		notes.used(what)
		if what == "menu" then open(not isOpen)
		elseif what == "close-menu" then open(false)
		elseif what == "hangar" then open(false); require(script.Parent.MenuController).show("hangar", true)
		else action:FireServer("range", what) end
	end
	-- What the crosshair is on when a shot is fired: the game's Menu button, a strip or a row plate.
	local function pick()
		local eye = workspace.CurrentCamera.CFrame.Position
		-- The game's Menu button (top left) under the crosshair opens the game menu, like Esc.
		local spot = workspace.CurrentCamera:WorldToViewportPoint(eye + FlightState.aim * 1000)
		local menu = player.PlayerGui:FindFirstChild("GameMenu")
		local button = menu and menu:FindFirstChild("OpenMenu")
		-- Measured from the menu's own top-left (the window's corner: it ignores the top bar inset). GUI positions start
		-- below the top bar, so in the top bar a button's raw position never matched the crosshair (Alan 2026-10-20).
		local low, size = button and button.AbsolutePosition - menu.AbsolutePosition, button and button.AbsoluteSize
		if button and button.Visible and spot.X >= low.X and spot.X <= low.X + size.X and spot.Y >= low.Y and spot.Y <= low.Y + size.Y then
			require(script.Parent.MenuController).pause()
			return
		end
		local hit = workspace:Raycast(eye, FlightState.aim * 1000, cast)
		local part = hit and hit.Instance
		local what = part and (part:GetAttribute("RangeBoard") or part:GetAttribute("RangePick"))
		if part and part:GetAttribute("RangePick") then notes.used("pick") end
		if what then click(what) end
	end
	local function ready() return not Root:GetAttribute("OverlayOpen") and FlightState.aimPoint ~= nil and stage ~= nil and stage.Parent ~= nil end
	Input.InputBegan:Connect(function(input, processed)
		-- A menu (the Hangar, the game menu) open over the Range takes the clicks: an empty spot on it is not a shot.
		if processed or not ready() then return end
		if KEYS[input.KeyCode] then click("load" .. KEYS[input.KeyCode]) return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
		pick()
	end)
	-- Phones: FIRE or 2 shoots strips and plates the same way (Alan 2026-10-28: shooting Reset did nothing).
	require(script.Parent.TouchControls).onShot = function() if ready() then pick() end end
	-- Phones: tap a strip on the stage itself (Reset, Hangar, a loadout, a difficulty); the plates are still shot.
	Input.TouchTapInWorld:Connect(function(position, processed)
		if processed or Root:GetAttribute("OverlayOpen") or not FlightState.aimPoint or not stage or not stage.Parent then return end
		-- The tap's position counts Roblox's top bar (measured in the Device Simulator: ScreenPointToRay missed 58 points low).
		local ray = workspace.CurrentCamera:ViewportPointToRay(position.X, position.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, cast)
		local what = hit and hit.Instance:GetAttribute("RangeBoard")
		if what then click(what) end
	end)
end

return Board
