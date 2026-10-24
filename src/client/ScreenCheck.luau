-- Screen fit check (Studio tool, docs/plan/SCREEN-FIT-PLAN.md): lists what doesn't fit on the current screen.
-- Run from the Studio MCP in Play: require(<PlayerScripts>.FlyFightPaper.ScreenCheck).run() returns lines:
--   OVERLAP a <-> b (share of the smaller one covered), UNDER ROBLOX a, OFF SCREEN a, SMALL TEXT a (points),
--   SMALL TAP a (points).
-- Pieces are the top-most drawn things (an image, words, a coloured frame, a 3D view); pieces drawn as one group
-- (the same panel, or the same full-screen menu sheet) may overlap by design, so only separate groups are compared.
-- A visible full-screen cover (a menu, a dim) hides what's under it, so lower layers are skipped.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local ScreenCheck = {}

local SKIP_GUIS = { Chat = true, BubbleChat = true, Freecam = true, SafeArea = true, TouchGui = true, ScreenCheckProbe = true }
-- Markers that follow things in the 3D world (aim, enemies, edge arrows) slide over everything by design: not pieces.
local MOVING = { "^AimCircle", "^NoseDot", "^LeadPipper", "^LeadLine", "^TargetBracket", "^EnemyMarker", "Arrow$", "^WaitingApproach" }
-- So do a lesson's spotlight pieces, drawn around what they point at.
local SPOTLIGHT = { Frame = true, Burst = true, BarFrame = true, TargetRing = true, Tag = true }
local function moving(object)
	for _, pattern in MOVING do if object.Name:find(pattern) then return true end end
	local gui = object:FindFirstAncestorWhichIsA("ScreenGui")
	return gui ~= nil and gui.Name == "Tutorial" and object.Parent == gui and SPOTLIGHT[object.Name] == true
end
local MIN_TEXT_PHONE, MIN_TEXT, MIN_TAP, OVERLAP_SHARE = 14, 12, 44, 0.15

local function shown(object)
	while object and not object:IsA("ScreenGui") do
		if object:IsA("GuiObject") and not object.Visible then return false end
		object = object.Parent
	end
	return object ~= nil and object.Enabled
end

local function draws(object)
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then return object.Image ~= "" and object.ImageTransparency < 0.95 end
	if object:IsA("TextLabel") or object:IsA("TextButton") then return object.Text ~= "" and object.TextTransparency < 0.95 or object.BackgroundTransparency < 0.95 end
	if object:IsA("ViewportFrame") then return true end
	return object:IsA("Frame") and object.BackgroundTransparency < 0.95
end

local function rect(object) return object.AbsolutePosition, object.AbsolutePosition + object.AbsoluteSize end
local function area(low, high) return math.max(0, high.X - low.X) * math.max(0, high.Y - low.Y) end
local function name(object)
	local gui = object:FindFirstAncestorWhichIsA("ScreenGui")
	return string.format("%s/%s/%s", gui and gui.Name or "?", object.Parent and object.Parent.Name or "?", object.Name)
end

function ScreenCheck.run()
	local playerGui = Players.LocalPlayer.PlayerGui
	local probe = Instance.new("ScreenGui") -- measures the whole screen (notch included) in GUI space
	probe.Name, probe.IgnoreGuiInset, probe.ScreenInsets, probe.Parent = "ScreenCheckProbe", true, Enum.ScreenInsets.None, playerGui
	local safe = Instance.new("ScreenGui") -- and the safe area (clear of the notch)
	safe.Name, safe.IgnoreGuiInset, safe.Parent = "ScreenCheckProbe", true, playerGui
	task.wait()
	local screenLow, screenHigh = rect(probe)
	if workspace.CurrentCamera.ViewportSize.X < 2 then probe:Destroy(); safe:Destroy(); return { "Studio isn't drawing (screen size 1 x 1): bring its window to the front" } end
	local safeLow, safeHigh = rect(safe)
	local screenArea = area(screenLow, screenHigh)
	local bar = GuiService.TopbarInset
	local robloxLow, robloxHigh = safeLow, Vector2.new(safeLow.X + bar.Min.X, safeLow.Y + bar.Height) -- Roblox's own buttons
	probe:Destroy(); safe:Destroy()
	local phone = screenHigh.Y - screenLow.Y < 540
	local touch = Input.PreferredInput == Enum.PreferredInput.Touch or game.ReplicatedStorage.FlyFightPaper:GetAttribute("DevTouch") == true

	-- Layers from the top down; a visible full-screen cover stops the walk.
	local guis = {}
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Enabled and not SKIP_GUIS[gui.Name] and not gui.Name:find("^Dev") then table.insert(guis, gui) end
	end
	table.sort(guis, function(a, b) return a.DisplayOrder > b.DisplayOrder end)
	local pieces, lines = {}, {}
	local function report(line) if not table.find(lines, line) then table.insert(lines, line) end end
	local covered = false
	for _, gui in guis do
		if covered then break end
		local cover = gui:FindFirstChild("Cover")
		for _, object in gui:GetDescendants() do
			-- (A menu's background picture and Studio's test buttons aren't pieces.)
			if object:IsA("GuiObject") and object.Name ~= "WeaponPicker" and not object:FindFirstAncestor("WeaponPicker")
				and object.Name ~= "Backdrop" and not object:FindFirstAncestor("Backdrop") and shown(object) then
				local low, high = rect(object)
				local big = area(low, high) > screenArea * 0.5
				local marker = moving(object) or (object.Parent and moving(object.Parent))
				if draws(object) and not big and not marker then
					-- Only the top-most drawn thing in its chain is a piece.
					local parent, top = object.Parent, true
					while parent and parent ~= gui do
						if parent:IsA("GuiObject") and draws(parent) and area(rect(parent)) <= screenArea * 0.5 then top = false; break end
						parent = parent.Parent
					end
					if top then
						-- Its group: a full-screen sheet, or the first child of the layer (or of its cover).
						local group, step = object, object
						while step.Parent and step.Parent ~= gui and step.Parent ~= cover do
							step = step.Parent
							if step.Name == "Sheet" then group = step; break end
							group = step
						end
						table.insert(pieces, { object = object, low = low, high = high, group = group, gui = gui })
					end
				end
				-- Words and taps, on everything shown.
				if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text ~= "" and object.TextTransparency < 0.95 then
					local points
					if object.TextScaled then
						points = not object.TextWrapped and object.TextBounds.Y or nil
					elseif object.Size.Y.Scale == 0 and object.Size.Y.Offset > 0 then
						points = object.TextSize * object.AbsoluteSize.Y / object.Size.Y.Offset
					end
					local least = phone and MIN_TEXT_PHONE or MIN_TEXT
					if points and points > 0 and points < least then report(string.format("SMALL TEXT %s %q %.0f pt", name(object), object.Text:sub(1, 24), points)) end
				end
				if touch and object:IsA("GuiButton") and math.min(object.AbsoluteSize.X, object.AbsoluteSize.Y) < MIN_TAP then
					report(string.format("SMALL TAP %s %.0f x %.0f pt", name(object), object.AbsoluteSize.X, object.AbsoluteSize.Y))
				end
			end
		end
		if cover and cover:IsA("GuiObject") and cover.Visible and cover.BackgroundTransparency < 1 and area(rect(cover)) >= screenArea * 0.9 then covered = true end
	end
	for i, a in pieces do
		if area(Vector2.new(math.max(a.low.X, screenLow.X), math.max(a.low.Y, screenLow.Y)), Vector2.new(math.min(a.high.X, screenHigh.X), math.min(a.high.Y, screenHigh.Y))) < area(a.low, a.high) * 0.9 then
			report("OFF SCREEN " .. name(a.object))
		end
		local under = area(Vector2.new(math.max(a.low.X, robloxLow.X), math.max(a.low.Y, robloxLow.Y)), Vector2.new(math.min(a.high.X, robloxHigh.X), math.min(a.high.Y, robloxHigh.Y)))
		if under > 4 then report("UNDER ROBLOX " .. name(a.object)) end
		for j = i + 1, #pieces do
			local b = pieces[j]
			-- (On a phone the match tip may cover the news note and the kill feed: Alan 2026-10-24.)
			local tipOver = phone and (a.gui.Name == "MatchTips" and b.gui.Name == "MatchInfo" or b.gui.Name == "MatchTips" and a.gui.Name == "MatchInfo")
			if a.group ~= b.group and not tipOver then
				local shared = area(Vector2.new(math.max(a.low.X, b.low.X), math.max(a.low.Y, b.low.Y)), Vector2.new(math.min(a.high.X, b.high.X), math.min(a.high.Y, b.high.Y)))
				local smaller = math.min(area(a.low, a.high), area(b.low, b.high))
				if smaller > 0 and shared / smaller > OVERLAP_SHARE then
					report(string.format("OVERLAP %s <-> %s (%.0f%%)", name(a.object), name(b.object), shared / smaller * 100))
				end
			end
		end
	end
	table.sort(lines)
	table.insert(lines, 1, string.format("screen %.0f x %.0f, safe %.0f x %.0f, %s%s: %d problems", screenHigh.X - screenLow.X, screenHigh.Y - screenLow.Y,
		safeHigh.X - safeLow.X, safeHigh.Y - safeLow.Y, phone and "phone" or "not phone", touch and ", touch" or "", #lines))
	return lines
end

return ScreenCheck
