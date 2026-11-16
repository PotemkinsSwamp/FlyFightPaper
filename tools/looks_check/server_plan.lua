-- Scripted looks check, server half (docs/workshop/tools.md, "looks_check"): run in the Play SERVER after the client
-- half. Workspace attribute ClaudePart picks the plan before it starts: "main" (nothing; all dressed; each trail on all
-- planes; each skin on all planes), "trails", or "ab" (nothing / Confetti / Circuit Trace / all dressed / Galaxy + Circuit
-- Trace, switched every 13 s, four times round: the fair frame-rate comparison). ClaudeBase offsets the step numbers.
-- Runs the timeline. Every plane's Skin and Trail attributes are forced per segment (test rigging only:
-- the server's own hit shapes do not follow), re-applied for respawned planes. Pauses outside the ACTIVE phase.
if workspace:GetAttribute("ClaudeRun") then return "already running" end
workspace:SetAttribute("ClaudeRun", true)
local planes = workspace:WaitForChild("Planes")
local status = game.ServerStorage.MatchStatus
local function phase() local ok, s = pcall(function() return status:Invoke() end) return ok and tostring(s.phase) or "?" end

local TRAILS = { "chalk_dust", "circuit_trace", "confetti", "dragon_embers", "folded_petals", "glitch_pixels", "gold_stars", "goo_bubbles", "holo_rainbow", "mini_planes", "music_notes", "stardust", "storm_sparks" }
local SKINS = { "hazard_stripes", "carbon_fiber", "racing_stripe", "eight_bit", "neon_grid", "flame_decals", "tie_dye", "jungle_camo", "lava", "galaxy", "slime", "holographic", "glitch", "thunderstorm", "circuit_board", "comic_book", "shark_jet", "dragon", "origami_crane" }
local MIX = { { "galaxy", "circuit_trace" }, { "dragon", "dragon_embers" }, { "origami_crane", "folded_petals" }, { "comic_book", "confetti" }, { "lava", "gold_stars" }, { "slime", "goo_bubbles" },
	{ "holographic", "holo_rainbow" }, { "glitch", "glitch_pixels" }, { "thunderstorm", "storm_sparks" }, { "circuit_board", "circuit_trace" }, { "tie_dye", "music_notes" }, { "neon_grid", "stardust" } }

local plan = {}
local function add(name, kind, settle, dur, view, pick) table.insert(plan, { name = name, kind = kind, settle = settle, dur = dur, view = view or "", pick = pick }) end
local none = function() return nil, nil end
local mix = function(i) local m = MIX[(i - 1) % #MIX + 1] return m[1], m[2] end
local PART = workspace:GetAttribute("ClaudePart") or "main"
if PART == "main" then
	add("bare", "bare", 5, 45, "", none)
	add("bare-overview", "bare", 3, 18, "over", none)
	add("all-dressed", "mixed", 10, 50, "", mix)
	add("all-dressed-overview", "mixed", 3, 18, "over", mix)
	for _, id in TRAILS do add("trail " .. id, "trail", 3, 14, "", function() return nil, id end) end
	for _, id in SKINS do add("skin " .. id, "skin", 6, 16, "", function() return id, nil end) end
	add("bare-end", "bare", 4, 16, "", none)
elseif PART == "trails" then
	for _, id in TRAILS do add("trail " .. id, "trail", 3, 16, "", function() return nil, id end) end
elseif PART == "ab" then -- same flight, looks switched every 13 s, four times round: cancels out where the plane happens to be
	for round = 1, 4 do
		add("AB bare", "bare", 3, 12.5, "", none)
		add("AB confetti x12", "trail", 3, 12.5, "", function() return nil, "confetti" end)
		add("AB circuit_trace x12", "trail", 3, 12.5, "", function() return nil, "circuit_trace" end)
		add("AB all-dressed", "mixed", 3, 12.5, "", mix)
		add("AB galaxy+circuit x12", "mixed", 3, 12.5, "", function() return "galaxy", "circuit_trace" end)
	end
end
local base = workspace:GetAttribute("ClaudeBase") or 0

local cur
local function apply(seg)
	local list = planes:GetChildren()
	table.sort(list, function(a, b)
		local ha, hb = a:GetAttribute("ControllerType") == "human", b:GetAttribute("ControllerType") == "human"
		if ha ~= hb then return ha end
		return a.Name < b.Name
	end)
	for i, plane in list do
		local skin, trail = seg.pick(i)
		if plane:GetAttribute("Skin") ~= skin then plane:SetAttribute("Skin", skin) end
		if plane:GetAttribute("Trail") ~= trail then plane:SetAttribute("Trail", trail) end
	end
end
task.spawn(function()
	while workspace:GetAttribute("ClaudeRun") do
		if cur then pcall(apply, cur) end
		task.wait(0.3)
	end
end)
task.spawn(function()
	local ok, err = pcall(function()
		local i = 1
		while i <= #plan and workspace:GetAttribute("ClaudeRun") do
			local seg = plan[i]
			local waited = false
			while phase() ~= "ACTIVE" do waited = true; workspace:SetAttribute("ClaudeSeg", "pause"); task.wait(1) end
			if waited then task.wait(10) end
			cur = seg
			apply(seg)
			workspace:SetAttribute("ClaudeSeg", table.concat({ base + i, seg.name, seg.kind, seg.settle, seg.dur, seg.view }, "|"))
			workspace:SetAttribute("ClaudeAt", (base + i) .. "/" .. (base + #plan) .. " " .. seg.name)
			local t0, broken = os.clock(), false
			while os.clock() - t0 < seg.dur + 1.5 do
				task.wait(0.5)
				if phase() ~= "ACTIVE" then broken = true; break end
			end
			if not broken then i += 1 end
		end
	end)
	cur = nil
	workspace:SetAttribute("ClaudeSeg", "done")
	workspace:SetAttribute("ClaudeAt", ok and "done" or ("ERROR " .. tostring(err)))
	workspace:SetAttribute("ClaudeRun", nil)
end)
return "plan started: " .. #plan .. " segments, part " .. PART
