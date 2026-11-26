-- Follow camera for bot videos (2026-11-25): paste into execute_luau on the Play CLIENT during a bots-only match.
-- Waits for a healthy bot to start WANT fresh (from chase, patrol, evade...; not resuming after unstuck/hole/fan),
-- above 150 studs, then follows it from behind for 28 s with a label (its intent in plain words and its height) and
-- hides the other ScreenGuis. Sets workspace ClaudeFollowAt when it starts (start video_capture then; it stops by
-- itself at 30 s) and ClaudeFollowLog (time, intent, height every 0.5 s) at the end. Needs DevTools' DevCamera.
local WANT = "run"
local FRESH = {chase=true, evade=true, patrol=true, search=true, extend=true, ram=true, objective=true, celebrate=true}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local me = Players.LocalPlayer
local WORDS = {run="street run (running away low)", hole="flying through a hole", hide="diving low to hide", chase="chasing",
	evade="dodging", patrol="cruising", search="searching", unstuck="climbing clear", fan="flying to a fan", repair="flying to repair",
	ram="ramming", extend="extending", celebrate="celebrating", objective="holding the zone", down="shot down"}
for _, g in ipairs(me.PlayerGui:GetChildren()) do
	if g:IsA("ScreenGui") and g.Enabled then g:SetAttribute("ClaudeHid", true); g.Enabled = false end
end
local gui = Instance.new("ScreenGui"); gui.Name = "ClaudeLabel"; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100
local label = Instance.new("TextLabel"); label.Size = UDim2.fromOffset(640, 40); label.Position = UDim2.new(.5, -320, 0, 20)
label.BackgroundColor3 = Color3.new(0, 0, 0); label.BackgroundTransparency = .35; label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true; label.Font = Enum.Font.GothamBold; label.Text = ""; label.Parent = gui; gui.Parent = me.PlayerGui
workspace:SetAttribute("ClaudeFollowAt", nil); workspace:SetAttribute("ClaudeFollowLog", "")
task.spawn(function()
	local planes = workspace:WaitForChild("Planes")
	local last, watched = {}, nil
	local t0 = os.clock()
	while not watched and os.clock() - t0 < 300 do
		for _, m in ipairs(planes:GetChildren()) do
			local intent = (m:GetAttribute("BotIntent") or ""):match("^%a+") or ""
			local root = m:FindFirstChild("Root")
			if intent == WANT and FRESH[last[m] or ""] and root and root.Position.Y > 150 and (m:GetAttribute("Health") or 0) > (m:GetAttribute("MaxHealth") or 1) * .8 then watched = m end
			last[m] = intent
		end
		task.wait(.1)
	end
	if not watched then workspace:SetAttribute("ClaudeFollowAt", -1); return end
	local start = os.clock()
	workspace:SetAttribute("ClaudeFollowAt", start)
	local log, nextLog = {}, 0
	local cam
	while os.clock() - start < 28 do
		local root = watched:FindFirstChild("Root")
		if root then
			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z); flat = flat.Magnitude > .05 and flat.Unit or Vector3.zAxis
			local want = CFrame.lookAt(root.Position - flat * 60 + Vector3.yAxis * 18, root.Position + look * 70)
			cam = cam and cam:Lerp(want, .18) or want
			me:SetAttribute("DevCamera", cam)
			local intent = (watched:GetAttribute("BotIntent") or ""):match("^%a+") or "?"
			if watched:GetAttribute("State") ~= "FLYING" then intent = "down" end
			label.Text = string.format("%s:  %s   (height %d)", watched:GetAttribute("DisplayName") or watched.Name, WORDS[intent] or intent, root.Position.Y)
			if os.clock() >= nextLog then
				nextLog = os.clock() + .5
				table.insert(log, string.format("%.1f %s %d", os.clock() - start, intent, root.Position.Y))
			end
		end
		RunService.RenderStepped:Wait()
	end
	workspace:SetAttribute("ClaudeFollowLog", table.concat(log, ";"))
	me:SetAttribute("DevCamera", nil)
	gui:Destroy()
	for _, g in ipairs(me.PlayerGui:GetChildren()) do
		if g:GetAttribute("ClaudeHid") then g.Enabled = true; g:SetAttribute("ClaudeHid", nil) end
	end
end)
return "following " .. WANT
