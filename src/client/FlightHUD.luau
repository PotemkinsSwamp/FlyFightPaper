local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Course = require(game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared.TrainingCourse)
local HUD = {}

function HUD.start(getPlane, action)
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlightHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ChalkCloud = require(script.Parent.ChalkCloud)
	local Crayon = require(game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared.UIAssets).hud
	-- Two reticles: the aim circle (where you want to go) and the nose dot (where the plane and its guns point).
	-- Hollow marks are drawn with a white crayon piece tinted to their colour (the plain outline until it is uploaded).
	local function reticle(name, size, filled, piece)
		local frame = Instance.new("Frame")
		frame.Name, frame.AnchorPoint, frame.Size = name, Vector2.new(0.5, 0.5), UDim2.fromOffset(size, size)
		frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = Color3.fromRGB(235, 245, 250), filled and 0 or 1, 0
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0.5, 0)
		-- Filled dots get a dark outline so they stand out against the pale room.
		local ring = Instance.new("UIStroke")
		ring.Color, ring.Thickness, ring.Transparency = filled and Color3.fromRGB(10, 20, 15) or Color3.fromRGB(255, 240, 170), 2, filled and 0.2 or 0.1
		ring.Parent = frame
		if piece and piece ~= "" then
			local art = Instance.new("ImageLabel")
			art.Name, art.Image, art.BackgroundTransparency = "Crayon", piece, 1
			art.AnchorPoint, art.Position, art.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1)
			art.Parent, ring.Enabled = frame, false
		end
		frame.Visible = false
		frame.Parent = gui
		return frame
	end
	local function tint(frame, color, transparency)
		frame.UIStroke.Color = color
		local art = frame:FindFirstChild("Crayon")
		if art then art.ImageColor3, art.ImageTransparency = color, transparency or 0 end
	end
	local aimCircle = reticle("AimCircle", 30, false, Crayon.ring)
	aimCircle.UIStroke.Thickness = 3
	-- Settings screen: crosshair colour tints the aim circle; size scales both reticles (nose dot keeps green/red).
	local CROSSHAIR_COLORS = { green = Color3.fromRGB(60, 255, 90), red = Color3.fromRGB(255, 60, 70), blue = Color3.fromRGB(0, 235, 255),
		yellow = Color3.fromRGB(255, 225, 40), purple = Color3.fromRGB(190, 110, 255), white = Color3.fromRGB(250, 250, 250) }
	local CROSSHAIR_SIZES = { Small = 0.75, Medium = 1, Large = 1.4 }
	local Settings = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
	local crosshairScale = 1
	local function applyCrosshair()
		tint(aimCircle, CROSSHAIR_COLORS[Settings:GetAttribute("CrosshairColor")] or CROSSHAIR_COLORS.blue)
		crosshairScale = CROSSHAIR_SIZES[Settings:GetAttribute("CrosshairSize")] or 1
		aimCircle.Size = UDim2.fromOffset(30 * crosshairScale, 30 * crosshairScale)
	end
	Settings:GetAttributeChangedSignal("CrosshairColor"):Connect(applyCrosshair)
	Settings:GetAttributeChangedSignal("CrosshairSize"):Connect(applyCrosshair)
	applyCrosshair()
	-- Bright green; turns red and grows a little only while it sits on an orange lead ring with the target in range.
	local NOSE, NOSE_ON = Color3.fromRGB(60, 255, 90), Color3.fromRGB(255, 40, 60)
	local noseDot = reticle("NoseDot", 10, true)
	noseDot.BackgroundColor3 = NOSE
	-- Eraser seeker: any enemy inside this circle (and in range) starts locking; a box on it shrinks and turns red.
	local seeker = reticle("EraserSeeker", 100, false, Crayon.ring)
	seeker.UIStroke.Transparency, seeker.UIStroke.Thickness = 0.55, 1.5
	tint(seeker, Color3.fromRGB(255, 140, 170), 0.6)
	local lockBox = reticle("LockBox", 60, false, Crayon.bracket)
	lockBox.UICorner:Destroy()
	local FlightState = require(script.Parent.FlightController).state
	-- Aim help: a lead marker for the enemy nearest the nose, with a bracket on that enemy.
	local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
	local Gameplay = require(Root.Generated.Gameplay)
	local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), Gameplay)
	local CombatRules = require(Root.Shared.CombatRules)
	-- The lead marker is the "second crosshair": put the nose dot on it and the shots meet the enemy.
	-- One lead marker per weapon type (Alan): left-click weapon = orange ring, right-click weapon = cyan diamond.
	-- Each fills in when its own shots would hit now.
	local LEAD_LOOKS = {
		{ name = "LeadPipper", size = 26, color = Color3.fromRGB(255, 150, 60), round = true },
		{ name = "LeadPipper2", size = 22, color = Color3.fromRGB(70, 225, 255), round = false },
	}
	local pippers, leadLines = {}, {}
	for group, look in ipairs(LEAD_LOOKS) do
		local pipper = reticle(look.name, look.size, false, look.round and Crayon.ring or Crayon.keyBox)
		pipper.UIStroke.Thickness, pipper.BackgroundColor3 = 3, look.color
		tint(pipper, look.color)
		if not look.round then pipper.UICorner:Destroy(); pipper.Rotation = 45 end
		local line = Instance.new("Frame")
		line.Name, line.AnchorPoint, line.BorderSizePixel = "LeadLine" .. group, Vector2.new(0.5, 0.5), 0
		line.BackgroundColor3, line.BackgroundTransparency, line.Visible = look.color, 0.45, false
		line.Parent = gui
		pippers[group], leadLines[group] = pipper, line
	end
	local motion = {}
	local bracket = reticle("TargetBracket", 34, false, Crayon.bracket)
	bracket.UICorner:Destroy()
	bracket.UIStroke.Transparency = 0.3
	tint(bracket, Color3.fromRGB(255, 150, 60), 0.1)
	local planes = workspace:WaitForChild("Planes")
	local function enemy(me, other)
		local team = me:GetAttribute("Team") or ""
		return other ~= me and (team == "" or other:GetAttribute("Team") ~= team)
	end
	-- A small diamond over every enemy on screen, at any range, so distant planes can be found.
	-- Low health: a pulsing red border around the screen.
	-- Screen-edge warnings are a red crayon scribble around the edges (low health pulses, a lock on you flashes).
	local function scribble(name, color)
		local frame = Instance.new("ImageLabel")
		frame.Name, frame.Image, frame.ImageColor3, frame.BackgroundTransparency = name, Crayon.scribble, color, 1
		frame.Size, frame.ScaleType, frame.Visible, frame.Parent = UDim2.fromScale(1, 1), Enum.ScaleType.Stretch, false, gui
		return frame
	end
	local danger = scribble("LowHealth", Color3.fromRGB(200, 40, 30))
	local markers = {}
	local function markerFor(index)
		local marker = markers[index]
		if not marker then
			marker = Instance.new("Frame")
			marker.Name, marker.AnchorPoint, marker.Size, marker.Rotation = "EnemyMarker", Vector2.new(0.5, 1), UDim2.fromOffset(9, 9), 45
			marker.BackgroundColor3, marker.BackgroundTransparency, marker.BorderSizePixel = Color3.fromRGB(255, 120, 80), 0.15, 0
			marker.Parent = gui
			markers[index] = marker
		end
		return marker
	end
	-- Off-screen arrows: a crayon double chevron (pointing right, turned to aim) at the screen edge pointing at an
	-- enemy behind or beside you.
	local arrows = {}
	local Zone = require(script.Parent.ControlZone)
	local zoneArrow
	local function makeArrow(name)
		local arrow = Instance.new("ImageLabel")
		arrow.Name, arrow.AnchorPoint, arrow.Size, arrow.BackgroundTransparency = name, Vector2.new(0.5, 0.5), UDim2.fromOffset(40, 40), 1
		arrow.Image, arrow.ScaleType, arrow.Visible = Crayon.arrow, Enum.ScaleType.Fit, false
		Instance.new("UIScale").Parent = arrow
		arrow.Parent = gui
		return arrow
	end
	zoneArrow = makeArrow("ZoneArrow")
	local zoneMoveArrow, lastZone, zoneMovedUntil = makeArrow("ZoneMoveArrow"), nil, 0
	local voteArrow, votePhase = makeArrow("VoteArrow"), false
	local function arrowFor(index)
		local arrow = arrows[index]
		if not arrow then
			arrow = makeArrow("OffscreenArrow")
			arrows[index] = arrow
		end
		return arrow
	end
	-- The aimed (non-homing) weapon on each trigger: { [1] = left-click weapon, [2] = right-click weapon }.
	local function gunWeapons(plane)
		local found = {}
		local ids=string.split(plane:GetAttribute("Mounts") or "", ",")
		local groups=assert(CombatRules.triggerGroups({weapon_mounts=ids}))
		for slot, id in ipairs(ids) do
			local weapon = id ~= "" and Catalog:get(id)
			if weapon and not weapon.homing then found[groups[slot]] = found[groups[slot]] or weapon end
		end
		return found
	end
	-- Words on paper (Alan, 2026-10-13: notebook strips and big crayon-marker words, like the menus). Panels are
	-- laid out for 1080p and scaled to the screen height, so the HUD keeps the same share of any screen.
	local PaperUI = require(script.Parent.PaperUI)
	local UIArt = require(Root.Shared.UIAssets)
	local function panel(name, anchor, position, size)
		local frame = Instance.new("Frame")
		frame.Name, frame.AnchorPoint, frame.BackgroundTransparency = name, anchor, 1
		frame.Position, frame.Size, frame.Parent = position, size, gui
		local scale = Instance.new("UIScale")
		scale.Parent = frame
		local function fit() scale.Scale = math.max(0.6, workspace.CurrentCamera.ViewportSize.Y / 1080) end
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		fit()
		return frame
	end
	-- A paper piece with centred words that shrink to fit and keep clear of the torn ends.
	local function note(parent, name, id, w, h, y, textSize)
		local paper = Instance.new("ImageLabel")
		paper.Name, paper.Image, paper.BackgroundTransparency, paper.ScaleType = name, id, 1, Enum.ScaleType.Stretch
		paper.AnchorPoint, paper.Position, paper.Size, paper.Visible = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, y), UDim2.fromOffset(w, h), false
		local words = PaperUI.words(paper, "Words", "", 0, 0, 0, 0, textSize)
		words.Size, words.TextXAlignment, words.TextScaled, words.RichText = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center, true, true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = textSize, words
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0.07, 0), UDim.new(0.07, 0), UDim.new(0.16, 0), UDim.new(0.1, 0)
		pad.Parent, paper.Parent = words, parent
		return paper
	end
	-- Top middle: round strip, news note, then either a warning (someone is after you) or your own eraser's lock.
	local top = panel("Top", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8), UDim2.fromOffset(900, 340))
	local round = note(top, "Round", UIArt.hud.notebook, 640, 76, 0, 44)
	local star = PaperUI.image(round, "Star", UIArt.results.goldStar, 0, 0, 52, 52)
	star.AnchorPoint, star.Position, star.Visible = Vector2.new(0.5, 0.5), UDim2.new(1, -40, 0.5, 2), false
	-- News note: the crumpled tape label tinted yellow (Alan's pick), kept at the label's own shape (7.3:1) so
	-- nothing stretches (Alan: the stretched pinned menu strip looked bad).
	local status = note(top, "Status", UIArt.ingame.tapeLabel, 560, 76, 84, 32)
	status.ImageColor3 = Color3.fromRGB(255, 215, 80)
	-- Pinned at both ends with the kill feed's push pins (separate pieces, so they keep their own shape).
	for _, x in { 0.07, 0.93 } do
		local pin = PaperUI.image(status, "Pin", UIArt.hud.pinRed, 0, 0, 30, 30)
		pin.Position = UDim2.new(x, 0, 0.5, -2)
	end
	status.Words.UIPadding.PaddingLeft, status.Words.UIPadding.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0) -- words stay clear of the pins
	local threat = note(top, "Threat", UIArt.hud.incoming, 600, 198, 150, 56)
	threat.Words.Size, threat.Words.UIPadding.PaddingTop = UDim2.fromScale(1, 0.66), UDim.new(0.2, 0)
	threat.Words.FontFace = Font.fromEnum(Enum.Font.PermanentMarker) -- the heavy marker of concept 2's INCOMING!
	local sub = PaperUI.words(threat, "Sub", "", 0, 0, 0, 0, 28)
	local threatTop = 150 -- below the round strip; lower in Airspace Control, under the lesson note in a lesson
	sub.Position, sub.Size, sub.TextXAlignment, sub.TextScaled = UDim2.new(0.12, 0, 0.58, 0), UDim2.fromScale(0.76, 0.26), Enum.TextXAlignment.Center, true
	local subCap = Instance.new("UITextSizeConstraint")
	subCap.MaxTextSize, subCap.Parent = 28, sub
	local lockInfo = note(top, "LockInfo", UIArt.hud.notebook, 640, 62, 158, 32)
	-- Airspace Control: a notebook strip under the round strip: red cells | who holds the zone | blue cells, each
	-- side filling toward the control target (whole cells). The notes below it move down to make room.
	local capture = note(top, "Capture", UIArt.hud.notebook, 640, 70, 84, 30)
	capture.Words.Position, capture.Words.Size = UDim2.fromScale(0.35, 0), UDim2.fromScale(0.3, 1)
	capture.Words.UIPadding.PaddingLeft, capture.Words.UIPadding.PaddingRight = UDim.new(0, 0), UDim.new(0, 0)
	local captureCells = { {}, {} }
	for side, colour in { "red", "blue" } do
		for k = 1, 10 do
			local x = side == 1 and 44 + (k - 1) * 18 or 640 - 44 - 16 - (k - 1) * 18 -- both fill from the outside in
			PaperUI.image(capture, "Empty", UIArt.hangar.bar.empty, x, 26, 16, 18)
			captureCells[side][k] = PaperUI.image(capture, "Fill", UIArt.hangar.bar[colour], x, 26, 16, 18)
		end
	end
	local teams = { ["team:1"] = 0, ["team:2"] = 0 }
	-- Top right: the last four knock-downs, one torn notebook slip each (CombatEffects fills them), pinned with a
	-- blue pin when the line is about you and a red one otherwise.
	local feed = panel("KillFeed", Vector2.new(1, 0), UDim2.new(1, -16, 0, 10), UDim2.fromOffset(450, 240))
	for i = 1, 4 do
		local slip = note(feed, "Slip" .. i, UIArt.hud.slip, 450, 54, (i - 1) * 58, 26)
		slip.Words.UIPadding.PaddingLeft = UDim.new(0.11, 0)
		local pin = PaperUI.image(slip, "Pin", UIArt.hud.pinRed, 14, -6, 30, 30)
		slip.Words:GetPropertyChangedSignal("Text"):Connect(function()
			local mine = slip.Words.Text:find("%f[%a][Yy]ou%f[%A]") or slip.Words.Text:find("%f[%a][Yy]our%f[%A]")
			pin.Image = mine and UIArt.hud.pinBlue or UIArt.hud.pinRed
		end)
	end
	-- Over the landing pad while you wait for it.
	local holding = note(gui, "WaitingApproach", UIArt.hud.notebook, 230, 84, 0, 28)
	holding.AnchorPoint = Vector2.new(0.5, 0.5)
	local alarm = scribble("LockAlarm", Color3.fromRGB(255, 60, 40))
	local picker = Instance.new("Frame")
	picker.Name="WeaponPicker";picker.Size=UDim2.fromOffset(880,80);picker.Position=UDim2.new(.5,-440,.5,64);picker.BackgroundTransparency=1;picker.Parent=gui
	for index, choice in ipairs({"pellet","staple","rubber","paperclip","eraser","pencil","twin_pencils"}) do
		local button=Instance.new("TextButton");button.Size=UDim2.fromOffset(104,34);button.Position=UDim2.fromOffset((index-1)*110,0)
		button.Name=choice
		button.BackgroundColor3=Color3.fromRGB(45,55,66);button.TextColor3=Color3.new(1,1,1);button.Font=Enum.Font.GothamMedium;button.TextSize=13
		button.Text=choice:gsub("_"," ");button.Parent=picker;button.Activated:Connect(function()action("loadout",choice)end)
	end
	-- Dodge practice: one bot with only an eraser hunts you.
	local eraserBots=picker.pellet:Clone();eraserBots.Name="EraserBots";eraserBots.Text="eraser hunter";eraserBots.Position=UDim2.fromOffset(770,0)
	eraserBots.BackgroundColor3=Color3.fromRGB(120,45,70);eraserBots.Parent=picker;eraserBots.Activated:Connect(function()action("eraserBots")end)
	-- Every bot build, skill, personality and quirk at once (F10 shows which is which).
	local mixedBots=eraserBots:Clone();mixedBots.Name="MixedBots";mixedBots.Text="mixed bots";mixedBots.Position=UDim2.fromOffset(770,-40)
	mixedBots.BackgroundColor3=Color3.fromRGB(45,95,70);mixedBots.Parent=picker;mixedBots.Activated:Connect(function()action("mixedBots")end)
	-- Test mode (Alan, 2026-10-14): end this round and start the next one in the picked mode.
	for index, mode in ipairs({ { "FFA", "free-for-all" }, { "TDM", "team DM" }, { "CONTROL", "airspace" }, { "NEXTSPOT", "next spot" } }) do
		local button=eraserBots:Clone();button.Name="Mode"..mode[1];button.Text="mode: "..mode[2];button.Position=UDim2.fromOffset((index-1)*110,-40)
		button.BackgroundColor3=Color3.fromRGB(70,60,120);button.Parent=picker
		button.Activated:Connect(function()Root.RoundAction:FireServer("devMode",mode[1])end)
	end
	-- Test buttons (Alan 2026-10-17, 2026-10-23): end this round now to see the round end, with each finalist winners'
	-- song (WinnersSound.TRACKS) to compare them in the real moment.
	for index, song in ipairs({ "parade", "carnival", "show" }) do
		local endMatch=eraserBots:Clone();endMatch.Name="EndMatch"..index;endMatch.Text="end: "..song;endMatch.Position=UDim2.fromOffset(330+index*110,-40)
		endMatch.BackgroundColor3=Color3.fromRGB(150,40,40);endMatch.Parent=picker
		endMatch.Activated:Connect(function()Root:SetAttribute("DevWinnersSong",song);Root.RoundAction:FireServer("endMatch")end)
	end
	-- Crayon colours for the round strip's words.
	local function crayon(text, hex) return string.format('<font color="#%s">%s</font>', hex, text) end
	game.ReplicatedStorage.FlyFightPaper:WaitForChild("RoundView").OnClientEvent:Connect(function(snapshot)
		votePhase = snapshot.phase == "VOTE"
		local remaining=snapshot.endsAt and math.max(0,math.ceil(snapshot.endsAt-snapshot.serverTime)) or 0
		local text=crayon(({CONTROL="AIRSPACE"})[snapshot.mode] or snapshot.mode or "","D7282F").."   "..crayon(string.format("%d:%02d",math.floor(remaining/60),remaining%60),"1F5BC8")
		local first=false
		if snapshot.mode~="FFA" and snapshot.teams then
			text..="   "..crayon(string.format("Red %.0f",snapshot.teams["team:1"]),"D22828").." - "..crayon(string.format("Blue %.0f",snapshot.teams["team:2"]),"2850D2")
		elseif snapshot.pilots then
			-- Free-for-all: your points and place (pilots matched by name, like the results sheet).
			local me=Players.LocalPlayer;local mine
			for _,pilot in snapshot.pilots do if pilot.displayName==me.DisplayName or pilot.displayName==me.Name then mine=pilot end end
			if mine then
				local place=1
				for _,pilot in snapshot.pilots do if (pilot.contribution or 0)>(mine.contribution or 0) then place+=1 end end
				local suffix=({"st","nd","rd"})[place] or "th"
				text..="   "..crayon(string.format("%d pts",mine.contribution or 0),"D7282F").."   "..crayon(place..suffix,"7B3FB8")
				first=place==1
			end
		end
		-- Between rounds the strip shows the break's own clock (it showed the old round's mode at 0:00): the vote lap's,
		-- then the next mode's countdown. The winners' moment hides it.
		if snapshot.phase ~= "ACTIVE" and snapshot.phase ~= "ENDING" then
			local label = snapshot.phase == "VOTE" and "VOTE" or snapshot.phase == "COUNTDOWN" and (({CONTROL="AIRSPACE"})[Root:GetAttribute("DevMode") or snapshot.nextMode] or Root:GetAttribute("DevMode") or snapshot.nextMode) -- DevMode: Studio's mode buttons win over the vote or nil
			local left = snapshot.phaseEndsAt and math.max(0, math.ceil(snapshot.phaseEndsAt - snapshot.serverTime))
			text = label and left and crayon(label, "D7282F") .. "   " .. crayon(string.format("%d:%02d", math.floor(left / 60), left % 60), "1F5BC8") or nil
			first = false
		end
		-- The gold star sits at the strip's right end, so 1st-place words make room for it.
		-- No round running (the Range, the tutorial's own room): no clock, mode or place.
		local match = text ~= nil and snapshot.endsAt ~= nil and FlightState.aimPoint == nil and not game.ReplicatedStorage.FlyFightPaper:GetAttribute("TutorialRoom")
		round.Words.Text, round.Visible, star.Visible = text or "", match, first and match
		local control = snapshot.mode == "CONTROL"
		teams = snapshot.teams or teams
		capture.Visible = control
		status.Position, threat.Position = UDim2.new(0.5, 0, 0, control and 160 or 84), UDim2.new(0.5, 0, 0, control and 226 or 150)
		threatTop = control and 226 or 150
		lockInfo.Position = UDim2.new(0.5, 0, 0, control and 234 or 158)
		round.Words.UIPadding.PaddingRight = UDim.new(first and 0.14 or 0.07, 0)
	end)
	-- In the hangar: the crayon hangar menu (service, builds, LAUNCH). Studio's dev picker rides on its sheet.
	local desk = require(script.Parent.DeskHangar).new(gui.Parent, { flight = action, round = game.ReplicatedStorage.FlyFightPaper.RoundAction })
	picker.Position, picker.Parent = UDim2.new(0.5, -440, 0.6, 0), desk.sheet
	-- The match strip and the kill feed stay up at the desk too (Alan 2026-10-22: the quick menu leaves them in
	-- view), so they live on their own layer that hides only with the rest of the game's HUD.
	local matchInfo = Instance.new("ScreenGui")
	matchInfo.Name, matchInfo.ResetOnSpawn, matchInfo.IgnoreGuiInset, matchInfo.Parent = "MatchInfo", false, true, gui.Parent
	top.Parent, feed.Parent = matchInfo, matchInfo
	Input.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Return then action("launch")
		elseif input.KeyCode == Enum.KeyCode.R then action("fresh") end
	end)
	-- Crayon bars (Alan, 2026-10-13: hangar crayon cells on notebook strips). Each bar is a paper strip with ten cells;
	-- the last cell fills part-way. Bottom-left: Health, Lift, Boost. Bottom-right: one row per trigger with a pip
	-- per weapon (fills while reloading, or while the eraser locks) or, for guns that overheat, ten heat cells.
	-- Panels are laid out for 1080p and scaled to the screen height.
	local HangarArt = UIArt.hangar
	local function corner(name, anchor, width)
		return panel(name, anchor, UDim2.new(anchor.X, anchor.X == 0 and 20 or -20, 1, -16), UDim2.fromOffset(width, 230))
	end
	-- Ten cells holding `value` out of `max`.
	local function tenths(value, max)
		local fills = {}
		for k = 1, 10 do fills[k] = max > 0 and value / max * 10 - (k - 1) or 0 end
		return fills
	end
	-- Words and cells keep about 30 pixels clear of the strip's torn ends (Alan: no text on the edge of the paper).
	-- Trigger rows (`key` = "L" or "R") show the mouse button in a crayon box before the weapon's name.
	local function bar(panel, name, y, cellsAt, width, key)
		local row = { strip = PaperUI.image(panel, name .. "Strip", UIArt.hud.notebook, 0, y, width, 70) }
		row.strip.ScaleType = Enum.ScaleType.Stretch
		local nameAt = key and 92 or 42
		if key then
			local box = PaperUI.image(panel, name .. "Key", UIArt.hud.keyBox, 36, y + 11, 48, 48)
			box.ImageColor3 = PaperUI.INK
			local letter = PaperUI.words(box, name .. "Letter", key, 0, 2, 48, 46, 38)
			letter.TextXAlignment, letter.TextScaled = Enum.TextXAlignment.Center, true
		end
		row.name = PaperUI.words(panel, name .. "Name", key and "" or name:upper(), nameAt, y + 5, cellsAt - nameAt - 10, 60, 38)
		row.name.TextScaled = true
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize, cap.Parent = 38, row.name
		row.value = PaperUI.words(panel, name .. "Value", "", width - 128, y + 8, 82, 56, 36)
		row.value.TextXAlignment, row.value.TextScaled = Enum.TextXAlignment.Right, true
		local valueCap = Instance.new("UITextSizeConstraint")
		valueCap.MaxTextSize, valueCap.Parent = 36, row.value
		row.cells = {}
		for k = 1, 10 do
			local x = cellsAt + (k - 1) * 33
			local empty = PaperUI.image(panel, name .. "Cell" .. k, HangarArt.bar.empty, x, y + 19, 31, 32)
			local clip = Instance.new("Frame")
			clip.Name, clip.BackgroundTransparency, clip.ClipsDescendants = "Fill", 1, true
			clip.Position, clip.Size, clip.Parent = UDim2.fromOffset(x, y + 19), UDim2.fromOffset(31, 32), panel
			local fill = Instance.new("ImageLabel")
			fill.Name, fill.BackgroundTransparency, fill.Size, fill.Parent = "Crayon", 1, UDim2.fromOffset(31, 32), clip
			row.cells[k] = { empty = empty, clip = clip, fill = fill }
		end
		-- fills[k] = how full cell k is (0..1); missing cells are hidden. Cells from `worn` on are faded out.
		function row.show(fills, color, worn)
			for k, cell in row.cells do
				local on = row.on ~= false and fills[k] ~= nil
				cell.empty.Visible, cell.clip.Visible = on, on
				cell.fill.Image = HangarArt.bar[color]
				cell.clip.Size = UDim2.fromOffset(31 * math.clamp(fills[k] or 0, 0, 1), 32)
				cell.empty.ImageTransparency = worn and k > worn and 0.75 or 0
			end
		end
		function row.visible(on)
			row.on = on
			for _, item in panel:GetChildren() do if item.Name:sub(1, #name) == name then item.Visible = on end end
		end
		return row
	end
	local left = corner("Bars", Vector2.new(0, 1), 630)
	local healthRow = bar(left, "Health", 160, 178, 630)
	local liftRow = bar(left, "Lift", 85, 178, 630)
	local boostRow = bar(left, "Boost", 10, 178, 630)
	local right = corner("Weapons", Vector2.new(1, 1), 700)
	local triggerRows = { bar(right, "Left", 85, 308, 700, "L"), bar(right, "Right", 160, 308, 700, "R") }

	local sight = RaycastParams.new()
	sight.FilterType = Enum.RaycastFilterType.Include
	sight.FilterDescendantsInstances = { workspace:FindFirstChild("Arena") or workspace:WaitForChild("GreyboxRoom") }
	-- Where a shot of `weapon` fired now meets `root`, following its current turn (`m`: its tracked motion).
	-- Practice targets fly a set path (TrainingCourse.pathOf), so their lead is exact, read on the synced server
	-- clock (the server judges at the moment you aimed). Guessing from the turn misses them: over a pencil's 1.3 s
	-- flight the Range's swoops beat it every time (measured 2026-10-20).
	local function leadOf(root, m, weapon, body)
		local path, now = Course.pathOf(root.Parent), workspace:GetServerTimeNow()
		return CombatRules.lead(weapon, body.Position, function(t)
			return path and Course.pathAt(path, now + t).Position or root.Position + m.velocity * t + m.acceleration * (0.5 * t * t)
		end)
	end
	local STICKY, picked = math.rad(3), nil -- how much closer another enemy's lead must be to take the marker
	-- Reticles move every frame, after the camera.
	RunService:BindToRenderStep("FlightReticles", Enum.RenderPriority.Camera.Value + 3, function()
		local plane = getPlane()
		local body = plane and plane.Parent and plane:FindFirstChild("Root")
		local flying = body and gui.Enabled and plane:GetAttribute("State") == "FLYING"
		local camera = workspace.CurrentCamera
		local function place(frame, world)
			local point, visible = camera:WorldToViewportPoint(world)
			frame.Position, frame.Visible = UDim2.fromOffset(point.X, point.Y), visible
		end
		if flying and FlightState.aim then place(aimCircle, camera.CFrame.Position + FlightState.aim * 1000) else aimCircle.Visible = false end
		-- Only planes the pilot can actually see get markers: nothing shows through books or buildings.
		local sightline = {}
		local function seen(root)
			if sightline[root] == nil then
				local from = camera.CFrame.Position
				local hit = workspace:Raycast(from, root.Position - from, sight)
				sightline[root] = not ChalkCloud.blocks(from, root.Position)
					and (not hit or (hit.Instance.Transparency > 0.5 and not hit.Instance:GetAttribute("Solid")))
			end
			return sightline[root]
		end
		-- Pick the enemy whose lead (where you'd shoot to hit it) is closest to where the pilot is aiming, not the plane
		-- itself: a far plane is aimed at well ahead of it, so a near one crossing the sight mustn't steal the marker
		-- (Alan 2026-10-19). The current pick holds until another is clearly closer. Track each plane's turning so the
		-- lead curves with it.
		local now = os.clock()
		local target, guns, best = nil, flying and gunWeapons(plane) or {}, math.rad(35)
		local look = FlightState.aim or (body and body.CFrame.LookVector)
		local gun = guns[1] or guns[2]
		-- The Range's card targets (CombatService:addCard) are picked like planes but get no diamond or arrow
		-- (Alan 2026-10-21: the whole stage is in view).
		local candidates = planes:GetChildren()
		local cards = workspace:FindFirstChild("RangeCards")
		for _, card in cards and cards:GetChildren() or {} do
			if card:GetAttribute("DrillOf") == Players.LocalPlayer.UserId then table.insert(candidates, card) end
		end
		for _, other in ipairs(candidates) do
			local root = other:FindFirstChild("Root")
			if root and other ~= plane then
				local m = motion[root]
				local velocity = root.AssemblyLinearVelocity
				if not m then m = { velocity = velocity, acceleration = Vector3.zero, at = now }; motion[root] = m end
				local dt = now - m.at
				if dt > 0 then
					local raw = (velocity - m.velocity) / dt
					if raw.Magnitude > 400 then raw = raw.Unit * 400 end
					m.acceleration = m.acceleration:Lerp(raw, 1 - math.exp(-6 * dt))
					m.velocity, m.at = velocity, now
				end
				if next(guns) and other:GetAttribute("State") == "FLYING" and enemy(plane, other) and seen(root) then
					local offset = (gun and leadOf(root, m, gun, body) or root.Position) - body.Position
					local angle = (root.Position - body.Position).Magnitude < 1000 and math.acos(math.clamp(look:Dot(offset.Unit), -1, 1)) or math.pi
					if root == picked then angle -= STICKY end
					if angle < best then target, best = root, angle end
				end
			end
		end
		for root in pairs(motion) do if not root.Parent then motion[root] = nil end end
		picked, FlightState.target = target, target
		local shown = 0
		for _, other in ipairs(flying and planes:GetChildren() or {}) do
			local root = other:FindFirstChild("Root")
			if root and other:GetAttribute("State") == "FLYING" and enemy(plane, other) then
				local point, visible = camera:WorldToViewportPoint(root.Position)
				if visible and seen(root) then
					shown += 1
					local marker = markerFor(shown)
					marker.Position, marker.Visible = UDim2.fromOffset(point.X, point.Y - 14), true
				end
			end
		end
		for index = shown + 1, #markers do markers[index].Visible = false end
		-- Off-screen arrows: the nearest enemies within 800 studs that are behind or beside you and not hidden behind
		-- the city (up to 4), plus always the plane locking on to you, in red.
		local behind = {}
		for _, other in ipairs(flying and planes:GetChildren() or {}) do
			local root = other:FindFirstChild("Root")
			if root and other:GetAttribute("State") == "FLYING" and enemy(plane, other) then
				local point, visible = camera:WorldToViewportPoint(root.Position)
				local size = camera.ViewportSize
				local onScreen = visible and point.X >= 0 and point.X <= size.X and point.Y >= 0 and point.Y <= size.Y
				local locker = other:GetAttribute("LockTarget") == plane.Name
				local distance = (root.Position - body.Position).Magnitude
				if not onScreen and (locker or distance < 800 and seen(root)) then
					table.insert(behind, { root = root, locker = locker, rank = locker and -1 or distance })
				end
			end
		end
		table.sort(behind, function(a, b) return a.rank < b.rank end)
		-- Puts an edge arrow on the screen's rim pointing at `world`.
		local function pointAt(arrow, world, color)
			-- Direction on screen (x right, y down); straight behind points down.
			local relative = camera.CFrame:PointToObjectSpace(world)
			local direction = Vector2.new(relative.X, -relative.Y)
			direction = direction.Magnitude > 0.01 and direction.Unit or Vector2.new(0, 1)
			-- Ride a box inset from the edges, kept above the bottom bars.
			local size, scale = camera.ViewportSize, math.max(0.6, camera.ViewportSize.Y / 1080)
			local function edge(down)
				local halfX, up = size.X / 2 - 70 * scale, size.Y / 2 - 190 * scale -- below the top strips
				return size / 2 + direction * math.min(halfX / math.max(math.abs(direction.X), 1e-3), (direction.Y < 0 and up or down) / math.max(math.abs(direction.Y), 1e-3))
			end
			-- Bottom edge between the bar panels; if that lands on a panel, stop above it.
			local at = edge(size.Y / 2 - 100 * scale)
			if at.Y > size.Y - 250 * scale and (at.X < 640 * scale or at.X > size.X - 740 * scale) then at = edge(size.Y / 2 - 280 * scale) end
			arrow.Position, arrow.Rotation = UDim2.fromOffset(at.X, at.Y), math.deg(math.atan2(direction.Y, direction.X))
			arrow.UIScale.Scale = scale * 1.7
			arrow.ImageColor3 = color
		end
		for index = 1, math.max(#arrows, math.min(#behind, 4)) do
			local entry = index <= 4 and behind[index]
			local arrow = entry and arrowFor(index) or arrows[index]
			arrow.Visible = entry ~= nil and entry ~= false
			if arrow.Visible then
				pointAt(arrow, entry.root.Position, entry.locker and Color3.fromRGB(255, 50, 40) or Color3.fromRGB(255, 120, 80))
			end
		end
		-- Airspace Control: a yellow arrow to the zone while it is off screen (to the next spot once it is about to move).
		local zoneState = Zone.state
		local goal = zoneState.zone and (zoneState.moveIn <= Gameplay.rounds.control_warning_seconds and zoneState.nextZone or zoneState.zone)
		local goalAt = goal and Vector3.new(table.unpack(goal.center))
		local _, goalSeen = goalAt and camera:WorldToViewportPoint(goalAt)
		-- When the zone moves, a bigger green arrow flashes toward the new spot for a moment, on screen or not, so the
		-- player can turn toward it (Alan 2026-10-14).
		if zoneState.zone ~= lastZone then
			if lastZone and zoneState.zone then zoneMovedUntil = os.clock() + 2.5 end
			lastZone = zoneState.zone
		end
		zoneMoveArrow.Visible = flying and goalAt ~= nil and os.clock() < zoneMovedUntil
		if zoneMoveArrow.Visible then
			pointAt(zoneMoveArrow, goalAt, Color3.fromRGB(60, 220, 90))
			zoneMoveArrow.UIScale.Scale *= 1.4
		end
		zoneArrow.Visible = flying and goalAt ~= nil and not goalSeen and not zoneMoveArrow.Visible
		if zoneArrow.Visible then pointAt(zoneArrow, goalAt, Color3.fromRGB(255, 205, 40)) end
		-- The vote lap: a white arrow to the nearest vote ring while none is on screen.
		local nearest, anySeen
		if flying and votePhase then
			for _, ring in Gameplay.rounds.vote_rings do
				local at = Vector3.new(table.unpack(ring.center))
				local _, seen = camera:WorldToViewportPoint(at)
				anySeen = anySeen or seen
				if not nearest or (at - body.Position).Magnitude < (nearest - body.Position).Magnitude then nearest = at end
			end
		end
		voteArrow.Visible = nearest ~= nil and not anySeen
		if voteArrow.Visible then pointAt(voteArrow, nearest, Color3.fromRGB(255, 255, 255)) end
		local noseRange = 300
		if target then
			-- Where the target will be when a shot fired now reaches it, following its current turn.
			local m = motion[target]
			-- Shared with the gun assist, which leads each weapon by its own speed, drag and drop.
			FlightState.leadFor = function(weapon) return leadOf(target, m, weapon, body) end
			local path = Course.pathOf(target.Parent)
			place(bracket, path and Course.pathAt(path, workspace:GetServerTimeNow()).Position or target.Position)
			-- The nose dot sits at the left-click lead's range, so dot-on-marker means the guns really point there.
			local anyHit, b = false, bracket.Position
			for group, pipper in ipairs(pippers) do
				local weapon, line = guns[group], leadLines[group]
				if weapon then
					local lead = FlightState.leadFor(weapon)
					place(pipper, lead)
					if group == 1 or not guns[1] then noseRange, FlightState.leadPoint = (lead - body.Position).Magnitude, lead end
					-- Red = the shots land if fired now without any aim help (Alan 2026-10-19: red only if you'd hit without the
					-- assist): the nose line passes within 2 studs of the ring's point, where the guns meet.
					local offset = lead - body.Position
					local look = body.CFrame.LookVector
					local lands = (body.Position + look * offset.Magnitude - lead).Magnitude <= 2
					local onTarget = pipper.Visible and lands and CombatRules.travelTime(weapon, offset.Magnitude) < math.huge
					anyHit = anyHit or onTarget
					pipper.BackgroundTransparency = onTarget and 0.35 or 1
					local a = pipper.Position
					local dx, dy = a.X.Offset - b.X.Offset, a.Y.Offset - b.Y.Offset
					line.Position = UDim2.fromOffset((a.X.Offset + b.X.Offset) / 2, (a.Y.Offset + b.Y.Offset) / 2)
					line.Size, line.Rotation = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 2), math.deg(math.atan2(dy, dx))
					line.Visible = pipper.Visible and bracket.Visible
				else
					pipper.Visible, line.Visible = false, false
				end
			end
			noseDot.BackgroundColor3, noseDot.Size = anyHit and NOSE_ON or NOSE, UDim2.fromOffset((anyHit and 11 or 10) * crosshairScale, (anyHit and 11 or 10) * crosshairScale)
		else
			FlightState.leadFor, FlightState.leadPoint = nil, nil
			noseDot.BackgroundColor3, noseDot.Size = NOSE, UDim2.fromOffset(10 * crosshairScale, 10 * crosshairScale)
			bracket.Visible = false
			for group, pipper in ipairs(pippers) do pipper.Visible, leadLines[group].Visible = false, false end
		end
		-- The Range: the plane points at the spot under the aim circle (FlightController), so the dot goes at that spot's
		-- range and sits on the circle once the plane has turned (Alan 2026-10-19: they didn't line up and it drifted).
		if FlightState.aimPoint then noseRange = (FlightState.aimPoint - body.Position).Magnitude end
		if flying then place(noseDot, body.Position + body.CFrame.LookVector * noseRange) else noseDot.Visible = false end
		local carriesEraser = flying and string.find(plane:GetAttribute("Mounts") or "", "eraser") ~= nil
		if carriesEraser then
			-- Circle radius on screen for the lock cone around the nose.
			local Combat = Gameplay.combat
			local radius = math.tan(math.rad(Combat.eraser_lock_cone_deg)) / math.tan(math.rad(camera.FieldOfView / 2)) * camera.ViewportSize.Y / 2
			place(seeker, body.Position + body.CFrame.LookVector * 300)
			seeker.Size = UDim2.fromOffset(radius * 2, radius * 2)
		else
			seeker.Visible = false
		end
		local lockId = plane and plane:GetAttribute("LockTarget") or ""
		local locked = carriesEraser and (planes:FindFirstChild(lockId) or workspace:FindFirstChild("RangeCards") and workspace.RangeCards:FindFirstChild(lockId))
		local progress = plane and plane:GetAttribute("LockProgress") or 0
		if locked and locked:FindFirstChild("Root") and progress > 0 then
			local path = Course.pathOf(locked) -- a Range card: where it's drawn
			place(lockBox, path and Course.pathAt(path, workspace:GetServerTimeNow()).Position or locked.Root.Position)
			local size = 70 - 30 * progress
			lockBox.Size = UDim2.fromOffset(size, size)
			tint(lockBox, progress >= 1 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 220, 90))
			lockBox.UIStroke.Thickness = progress >= 1 and 3 or 2
		else
			lockBox.Visible = false
		end
	end)
	local update, noteAt = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		update += dt
		if update < 0.1 then return end
		update = 0
		local plane = getPlane()
		local shown=plane~=nil and plane.Parent~=nil and not Root:GetAttribute("OverlayOpen") and not Root:GetAttribute("PhotoMode") and not Root:GetAttribute("Cutscene")
		-- In the hangar the hangar menu shows Lift, health, score and buttons, so the flight HUD steps aside.
		local inHangar=shown and plane:GetAttribute("State")=="DESK"
		desk.update(plane,inHangar)
		picker.Visible=inHangar and RunService:IsStudio()
		gui.Enabled=shown and not inHangar
		matchInfo.Enabled=shown
		-- At the desk only the match strip shows up top: the desk's own note carries the news.
		if inHangar then status.Visible, threat.Visible, lockInfo.Visible = false, false, false end
		if not gui.Enabled then return end
		-- Outline other planes so they read at range: orange for enemies, blue for teammates.
		for _, other in ipairs(planes:GetChildren()) do
			if other ~= plane then
				local outline = other:FindFirstChild("Outline") or Instance.new("Highlight")
				outline.Name, outline.FillTransparency, outline.OutlineTransparency = "Outline", 1, 0.15
				outline.DepthMode = Enum.HighlightDepthMode.Occluded
				outline.OutlineColor = enemy(plane, other) and Color3.fromRGB(255, 120, 80) or Color3.fromRGB(110, 190, 255)
				local root = other:FindFirstChild("Root")
				-- The chalk cloud hides outlines like a wall (Alan 2026-10-15); outlines only stop at real walls.
				outline.Enabled = other:GetAttribute("State") == "FLYING"
					and not (root and ChalkCloud.blocks(workspace.CurrentCamera.CFrame.Position, root.Position))
				outline.Parent = other
			end
		end
		local state = plane:GetAttribute("State")
		danger.Visible = state == "FLYING" and (plane:GetAttribute("Health") or 0) < (plane:GetAttribute("MaxHealth") or 1) * 0.3
		danger.ImageTransparency = 0.35 + 0.25 * math.sin(os.clock() * 8)
		local waitPosition=plane:GetAttribute("HoldingPosition")
		holding.Visible=waitPosition~=nil and state=="FLYING"
		if holding.Visible then
			local camera=workspace.CurrentCamera;local point,visible=camera:WorldToViewportPoint(waitPosition);local size=camera.ViewportSize
			if visible then holding.Position=UDim2.fromOffset(math.clamp(point.X,75,math.max(75,size.X-75)),math.clamp(point.Y,165,math.max(165,size.Y-175)))
			else holding.Position=UDim2.new(.5,camera.CFrame:PointToObjectSpace(waitPosition).X<0 and -290 or 290,.5,0) end
			holding.Words.Text=plane:GetAttribute("DeskAvailable") and "PAD OPEN\nApproach ring" or "WAIT HERE\nPosition "..tostring(plane:GetAttribute("DeskQueuePosition") or 1)
		end
		-- The top note shows only real news (the controls are taught by the tutorial, not a standing note).
		-- In flight a note fades after 4 seconds; at the desk or when shot down it stays.
		local message = plane:GetAttribute("Message") or ""
		if message ~= status.Words.Text then status.Words.Text, noteAt = message, os.clock() end
		-- During a lesson the news note and the kill feed stay hidden: the lesson's own note is the only text (Alan).
		local lesson = Root:GetAttribute("TutorialOpen") == true
		status.Visible = message ~= "" and (state ~= "FLYING" or os.clock() - noteAt < 4) and not lesson
		feed.Visible = not lesson
		if capture.Visible then
			local target, zone = Gameplay.rounds.control_target, Zone.state
			for side, team in { "team:1", "team:2" } do
				for k, cell in captureCells[side] do cell.Visible = (teams[team] or 0) >= target * k / 10 end
			end
			local words = { ["team:1"] = { "RED HOLDS", "D22828" }, ["team:2"] = { "BLUE HOLDS", "2850D2" }, contested = { "CONTESTED!", "7B3FB8" } }
			local holder = words[zone.holder] or { "ZONE OPEN", "1C1A1E" }
			capture.Words.Text = zone.zone and zone.moveIn <= Gameplay.rounds.control_warning_seconds
				and string.format("MOVING IN %d", math.ceil(zone.moveIn)) or crayon(holder[1], holder[2])
		end
		local health, cap, full = plane:GetAttribute("Health") or 0, plane:GetAttribute("MaxHealth") or 120, plane:GetAttribute("OriginalHealth") or 120
		-- Worn maximum: repairs can't reach the faded cells.
		healthRow.show(tenths(health, full), "red", cap < full and cap / full * 10 or nil)
		healthRow.value.Text = tostring(math.max(0, math.ceil(health)))
		local lift, liftMax = plane:GetAttribute("Lift") or 0, plane:GetAttribute("LiftMax") or 90
		liftRow.show(tenths(lift, liftMax), "orange")
		liftRow.value.Text = string.format("%ds", math.ceil(lift))
		liftRow.name.TextColor3 = lift <= 0 and Color3.fromRGB(200, 40, 20) or PaperUI.INK -- out of Lift
		local boostMax = plane:GetAttribute("BoostMax") or 0
		boostRow.visible(boostMax > 0)
		boostRow.show(tenths(plane:GetAttribute("Boost") or 0, boostMax), "blue")
		boostRow.value.Text = string.format("%.1fs", plane:GetAttribute("Boost") or 0)
		left.Visible = not plane:GetAttribute("Pinned") -- the Range: nothing hurts you and Lift never runs out
		local ids=string.split(plane:GetAttribute("Mounts") or "",",")
		local groups=assert(CombatRules.triggerGroups({weapon_mounts=ids}));local eraserButton="right-click"
		for slot,id in ipairs(ids) do if id=="eraser" then eraserButton=(groups[slot]==1 and "left" or "right").."-click" end end
		local progress=plane:GetAttribute("LockProgress") or 0
		for group, row in triggerRows do
			local name = group == 1 and "Primary" or "Alternate"
			local weapon = plane:GetAttribute(name .. "Name") or "None"
			row.visible(weapon ~= "None")
			row.name.Text = weapon
			if plane:GetAttribute(name .. "HasHeat") then
				-- Guns that overheat: ten green cells while cool, emptying as the gun heats; red while it cools down.
				row.show(tenths(1 - (plane:GetAttribute(name .. "Heat") or 0), 1), plane:GetAttribute(name .. "Cooling") and "red" or "green")
			else
				-- One pip per weapon on this trigger: orange while reloading, green when ready; a ready eraser's pip
				-- fills blue while it locks and turns red once locked.
				local fills, color = {}, "green"
				for slot, id in ids do
					if groups[slot] ~= group or id == "" then continue end
					local ready = plane:GetAttribute("MountReady" .. slot) or 1
					if ready < 1 then color = "orange" elseif id == "eraser" and progress > 0 then ready, color = progress, progress >= 1 and "red" or "blue" end
					table.insert(fills, ready)
				end
				row.show(fills, color)
			end
		end
		-- Threats to you: once locked on or an eraser is coming, the screen edge flashes red.
		local serverNow=workspace:GetServerTimeNow()
		local incoming=serverNow<(plane:GetAttribute("EraserIncomingUntil") or 0)
		local lockedOn=serverNow<(plane:GetAttribute("IncomingLockUntil") or 0)
		local locking=serverNow<(plane:GetAttribute("LockingUntil") or 0)
		local loud=incoming or lockedOn
		alarm.Visible=loud and state=="FLYING"
		alarm.ImageTransparency=math.floor(os.clock()*6)%2==0 and 0 or .6
		-- Someone after you: the yellow INCOMING note (Alan's pick), small while they lock, big and shaking once
		-- locked or an eraser is coming. Otherwise your own eraser's lock shows on a notebook strip.
		local gap=plane:GetAttribute("EraserDistance") or 0
		local headline, line
		if incoming and gap<Gameplay.combat.eraser_break_studs then headline, line = "BREAK NOW!", "Turn hard!"
		elseif incoming then headline, line = "INCOMING!", string.format("Eraser %d studs away: break hard when it's close", gap)
		elseif lockedOn then headline, line = "LOCKED ON!", "Shake them off!"
		elseif locking then headline, line = "WATCH OUT!", "Someone is locking on to you" end
		threat.Visible, threat.Words.Text, sub.Text = headline ~= nil, headline or "", line or ""
		threat.Size = loud and UDim2.fromOffset(600, 198) or UDim2.fromOffset(450, 149)
		threat.Rotation = loud and (math.floor(os.clock()*8)%2==0 and -3 or 2) or -2
		-- In a lesson its note covers this spot: drop it just under the note, a size smaller (Alan 2026-10-19: INCOMING
		-- and BREAK NOW! were hidden behind it).
		threat.Position = UDim2.new(0.5, 0, 0, lesson and 300 or threatTop)
		if lesson then threat.Size = UDim2.fromOffset(450, 149) end
		local target=plane:GetAttribute("LockName") or ""
		local mine=os.clock()-(Players.LocalPlayer:GetAttribute("EraserAwayAt") or -9)<1.2 and "ERASER AWAY"
			or progress>=1 and string.format("LOCKED: %s  (%s)",target,eraserButton)
			or progress>0 and string.format("Locking %d%%: %s  (hold %s)",math.floor(progress*100),target,eraserButton) or nil
		lockInfo.Visible, lockInfo.Words.Text = headline==nil and mine~=nil, mine or ""
		lockInfo.Words.TextColor3 = progress>=1 and Color3.fromRGB(200, 40, 20) or PaperUI.INK
	end)
end
return HUD
