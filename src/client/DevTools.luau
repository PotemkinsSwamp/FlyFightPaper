-- Studio-only checks. F8: photo mode (cycle 8 fixed viewpoints), F6: back to the live camera.
-- F9: performance overlay. F7: test autopilot that flies a loop of the room with no mouse.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local FlightState = require(script.Parent.FlightController).state
local DevTools = {}

-- Fixed viewpoints compared against the reference image between changes. No `from` = live chase camera.
-- Screenshots of the latest set live in the git-ignored captures/ folder (overwrite; keep no history).
DevTools.views = {
	{ name = "1-spawn-desk", from = Vector3.new(-160, 175, 640), to = Vector3.new(-225, 125, 880) },
	{ name = "2-city-overview", from = Vector3.new(0, 590, 1080), to = Vector3.new(0, 40, -150) },
	{ name = "3-low-avenue", from = Vector3.new(-20, 45, 620), to = Vector3.new(-20, 60, -350) },
	{ name = "4-fly-through-hole", from = Vector3.new(-120, 180, 560), to = Vector3.new(-120, 180, 250) },
	{ name = "5-window-side", from = Vector3.new(-950, 300, 950), to = Vector3.new(-1404, 330, -250) },
	{ name = "6-chalkboard-wall", from = Vector3.new(120, 380, -640), to = Vector3.new(0, 300, -1097) },
	{ name = "7-chase-dogfight" },
	{ name = "8-hangar", screen = "hangar" },
}
-- Test autopilot routes: a lap above the city, and a lap hugging the walls and ceiling (camera clipping check).
DevTools.routes = {
	loop = { Vector3.new(-1000, 320, -750), Vector3.new(1000, 320, -750), Vector3.new(1000, 320, 650), Vector3.new(-1000, 320, 650) },
	hug = { Vector3.new(-1300, 570, 1000), Vector3.new(-1300, 570, -1000), Vector3.new(1300, 570, -1000), Vector3.new(1300, 250, 1000) },
	-- through the ceiling ducts (config world.ducts rooms): up vent J heading south, west over two light grilles,
	-- north, east, down vent M
	duct = { reach = 70, Vector3.new(-200, 480, 400), Vector3.new(900, 450, 700), Vector3.new(1060, 380, 280), Vector3.new(1060, 560, 10),
		Vector3.new(1060, 700, -170), Vector3.new(1060, 698, -550), Vector3.new(260, 698, -550), Vector3.new(-460, 698, -550),
		Vector3.new(-460, 698, 160), Vector3.new(-460, 698, 740), Vector3.new(140, 698, 740), Vector3.new(380, 480, 740), Vector3.new(600, 350, 400) },
	-- up vent D heading east, south down the long duct and through the round pipe, east, down vent J
	pipe = { reach = 70, Vector3.new(-700, 480, 200), Vector3.new(-1000, 430, 600), Vector3.new(-840, 420, 740), Vector3.new(-660, 470, 740),
		Vector3.new(-480, 640, 740), Vector3.new(-350, 698, 740), Vector3.new(260, 698, 740), Vector3.new(260, 698, 300), Vector3.new(260, 698, 50),
		Vector3.new(260, 698, -300), Vector3.new(260, 698, -550), Vector3.new(700, 698, -550), Vector3.new(1060, 698, -550),
		Vector3.new(1060, 698, -220), Vector3.new(1060, 470, 10), Vector3.new(700, 350, 300) },
	-- up vent M heading east, south through the fan against its air, down vent J
	fan = { reach = 70, Vector3.new(-200, 480, 400), Vector3.new(-300, 430, 740), Vector3.new(80, 470, 740), Vector3.new(240, 640, 740),
		Vector3.new(380, 698, 740), Vector3.new(1060, 698, 740), Vector3.new(1060, 698, -20), Vector3.new(1060, 470, -200), Vector3.new(700, 350, -100) },
}

function DevTools.start(menu)
	if not RunService:IsStudio() then return end
	local camera = workspace.CurrentCamera
	local view = 0
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.Enabled, gui.DisplayOrder = "DevPerf", false, true, false, 50
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local text = Instance.new("TextLabel")
	text.Size, text.Position, text.BackgroundTransparency = UDim2.fromOffset(330, 74), UDim2.new(1, -350, 0, 60), 0.3
	text.BackgroundColor3, text.TextColor3, text.Font, text.TextSize = Color3.new(0, 0, 0), Color3.new(1, 1, 1), Enum.Font.Code, 14
	text.TextXAlignment, text.Parent = Enum.TextXAlignment.Left, gui

	function DevTools.setView(index)
		view = index
		local entry = DevTools.views[index]
		Root:SetAttribute("PhotoMode", entry ~= nil and entry.from ~= nil)
		Root:SetAttribute("PhotoView", entry and entry.name or nil)
		if entry and entry.screen and menu then menu.show(entry.screen) end
	end
	RunService:BindToRenderStep("PhotoMode", Enum.RenderPriority.Camera.Value + 2, function()
		local entry = DevTools.views[view]
		local custom = Players.LocalPlayer:GetAttribute("DevCamera")
		if custom or entry and entry.from then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = custom or CFrame.lookAt(entry.from, entry.to)
			camera.FieldOfView = 70
		end
	end)

	-- Rolling 60-second window of client frame times; server frame time comes from the server.
	local frames, window = {}, 60
	function DevTools.perf()
		local now, total, sorted = os.clock(), 0, {}
		while frames[1] and now - frames[1].at > window do table.remove(frames, 1) end
		for _, frame in ipairs(frames) do total += frame.dt; table.insert(sorted, frame.dt) end
		table.sort(sorted)
		local count = #sorted
		return {
			fps = count > 0 and count / total or 0,
			p95Ms = count > 0 and sorted[math.max(1, math.ceil(count * 0.95))] * 1000 or 0,
			seconds = total,
			serverMs = Root:GetAttribute("ServerFrameMs") or 0,
			serverP95Ms = Root:GetAttribute("ServerFrameP95Ms") or 0,
		}
	end
	local refresh, logged = 0, os.clock()
	RunService.RenderStepped:Connect(function(dt)
		table.insert(frames, { at = os.clock(), dt = dt })
		refresh += dt
		if refresh < 0.5 then return end
		refresh = 0
		local p = DevTools.perf()
		Players.LocalPlayer:SetAttribute("DevPerf", string.format("%.1f,%.2f,%.1f,%.2f,%.0f", p.fps, p.p95Ms, p.serverMs, p.serverP95Ms, p.seconds))
		text.Text = string.format(" FPS %.1f   p95 frame %.1f ms\n server frame %.1f ms  p95 %.1f\n window %.0fs   view %s", p.fps, p.p95Ms, p.serverMs, p.serverP95Ms, p.seconds, Root:GetAttribute("PhotoView") or "-")
		if gui.Enabled and os.clock() - logged >= window then
			logged = os.clock()
			print(string.format("[Perf] %ds: %.1f FPS, p95 %.1f ms, server %.1f ms (p95 %.1f)", window, p.fps, p.p95Ms, p.serverMs, p.serverP95Ms))
		end
	end)

	function DevTools.autopilot(route)
		local points, target = DevTools.routes[route], 1
		FlightState.aimOverride = points and function(body)
			if (points[target] - body.Position).Magnitude < (points.reach or 180) then target = target % #points + 1 end
			return (points[target] - body.Position).Unit
		end or nil
	end

	-- Studio MCP commands run in a separate Lua VM, so they drive these tools through player attributes.
	local player = Players.LocalPlayer
	player:GetAttributeChangedSignal("DevView"):Connect(function() DevTools.setView(player:GetAttribute("DevView") or 0) end)
	player:GetAttributeChangedSignal("DevScreen"):Connect(function() if menu then menu.show(player:GetAttribute("DevScreen")) end end)
	player:GetAttributeChangedSignal("DevPractice"):Connect(function() require(script.Parent.Tutorial).begin() end)
	player:GetAttributeChangedSignal("DevAutopilot"):Connect(function() DevTools.autopilot(player:GetAttribute("DevAutopilot")) end)
	player:GetAttributeChangedSignal("DevAim"):Connect(function()
		local aim = player:GetAttribute("DevAim")
		FlightState.aimOverride = aim and function() return aim end or nil
	end)
	Input.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.F8 then DevTools.setView(view % #DevTools.views + 1)
		elseif input.KeyCode == Enum.KeyCode.F6 then DevTools.setView(0)
		elseif input.KeyCode == Enum.KeyCode.F9 then gui.Enabled = not gui.Enabled; logged = os.clock()
		elseif input.KeyCode == Enum.KeyCode.F7 then DevTools.autopilot(FlightState.aimOverride == nil and "loop" or nil)
		elseif input.KeyCode == Enum.KeyCode.F10 then DevTools.spectateNext() end
	end)

	-- F10: follow the next bot from behind and show what its brain is doing. F10 past the last bot, F6, Esc,
	-- Tab or opening the menu stops (Alan got stuck with only F6 as the way out).
	local watched
	local label = text:Clone()
	label.Position, label.Size, label.Visible = UDim2.new(0.5, -230, 0, 170), UDim2.fromOffset(460, 96), false
	label.Parent = gui.Parent:FindFirstChild("DevSpectate") or Instance.new("ScreenGui", gui.Parent)
	label.Parent.Name, label.Parent.ResetOnSpawn = "DevSpectate", false
	function DevTools.spectateNext()
		local bots = {}
		for _, model in ipairs(workspace:GetDescendants()) do
			if model:IsA("Model") and model:GetAttribute("BotIntent") then table.insert(bots, model) end
		end
		table.sort(bots, function(a, b) return a.Name < b.Name end)
		local index = table.find(bots, watched) or 0
		watched = bots[index + 1] -- nil after the last bot: back to your own view
		if not watched then DevTools.stopSpectating() end
	end
	function DevTools.stopSpectating()
		watched = nil
		camera.CameraType = Enum.CameraType.Custom -- your plane's camera takes over again if you are flying
	end
	Input.InputBegan:Connect(function(input)
		if watched and (input.KeyCode == Enum.KeyCode.F6 or input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Tab) then
			DevTools.stopSpectating()
		end
	end)
	Root:GetAttributeChangedSignal("OverlayOpen"):Connect(function() if watched then DevTools.stopSpectating() end end)
	RunService:BindToRenderStep("DevSpectate", Enum.RenderPriority.Camera.Value + 3, function()
		local root = watched and watched.Parent and watched:FindFirstChild("Root")
		label.Visible = root ~= nil
		if not root then return end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(root.CFrame:PointToWorldSpace(Vector3.new(0, 12, 45)), root.Position + root.CFrame.LookVector * 80)
		label.Text = string.format(" %s  (%s)\n %s  [%s]\n health %d  %s\n F10 next bot   F6 or Esc: stop", watched:GetAttribute("DisplayName") or watched.Name,
			tostring(watched:GetAttribute("Loadout")), tostring(watched:GetAttribute("BotIntent")), tostring(watched:GetAttribute("BotStyle")),
			watched:GetAttribute("Health") or 0, tostring(watched:GetAttribute("State")))
	end)
end
return DevTools
