-- The winners' moment's sound (Alan 2026-10-23): everything builds to 1st's landing. The crowd cheers and claps a
-- little as 3rd and 2nd hop up, then 1st lands, the kids yell "Yeah!", the cheering peaks and the winners' track
-- kicks in under the dancing; it steps down for the results card and is gone before the vote lap. Times are seconds
-- from "Pencils down!" and match WinnersCutscene's own (banner 1.2, glide 2.0, hops TURN 1.8 apart, each landing
-- 1.3 s after its stand: 3rd 4.5, 2nd 6.3, 1st 8.1; card 17-27).
-- Uses Roblox's newer audio objects (AudioPlayer wired to the speakers): they also play in Studio's Edit mode, so
-- the same mix can be heard there (`WinnersSound.play(id)` from the command bar).
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local WinnersSound = {}
-- Alan's three finalists (all APM, licensed for Roblox games); he picks one by ear.
WinnersSound.TRACKS = { parade = 1838686578, carnival = 9041955420, show = 1835278359 } -- Parade March (30s), Nawlins Carnival Kids (a) (30), On With The Show 30C
local CHEER, CLAP, YEAH = 9120973900, 9113138035, 1841221347 -- PSE crowd cheers and whistles, PSE small-room applause, APM kids "Yeah!"
local FIRST_LANDS = 8.1

-- Each cue: a sound, then its volume at points in time (straight lines between them). It starts at the first point
-- and stops at the last.
local function cues(track)
	local L = FIRST_LANDS
	return {
		{ CHEER, { 3.2, 0 }, { 6, 0.2 }, { L, 0.3 }, { L + 0.3, 0.6 }, { L + 2, 0.4 }, { 13, 0 } },
		{ CLAP, { 4.5, 0.12 }, { 6.3, 0.2 }, { L, 0.25 }, { L + 0.3, 0.45 }, { L + 2, 0.3 }, { 13, 0 } },
		{ YEAH, { L, 0.5 }, { L + 3, 0.5 } },
		{ track, { L, 0.5 }, { 17, 0.5 }, { 18, 0.35 }, { 23.5, 0.35 }, { 26, 0 } },
	}
end

local function volumeAt(keys, t)
	for i = 3, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b[1] then return a[2] + (b[2] - a[2]) * math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1) end
	end
	return 0
end

-- Plays the whole mix with `track` as the winners' music; `loudness()` (optional) scales it, e.g. the Sound slider.
-- Returns a function that stops it early.
function WinnersSound.play(track, loudness)
	local folder = Instance.new("Folder")
	folder.Name = "WinnersSound"
	local speakers = Instance.new("AudioDeviceOutput")
	speakers.Parent = folder
	local live = {}
	for _, keys in cues(track) do
		local player = Instance.new("AudioPlayer")
		player.Asset = "rbxassetid://" .. keys[1]
		player.Volume = 0
		player.Parent = folder
		local wire = Instance.new("Wire")
		wire.SourceInstance, wire.TargetInstance = player, speakers
		wire.Parent = player
		table.insert(live, { player = player, keys = keys })
	end
	folder.Parent = SoundService
	local start, connection = os.clock(), nil
	local function stop()
		connection:Disconnect()
		folder:Destroy()
	end
	connection = RunService.Heartbeat:Connect(function()
		local t, scale, left = os.clock() - start, loudness and loudness() or 1, false
		for _, cue in live do
			local first, last = cue.keys[2][1], cue.keys[#cue.keys][1]
			if t < last then left = true end
			if t >= first and t < last and not cue.started then
				cue.started = true
				cue.player:Play()
			end
			cue.player.Volume = volumeAt(cue.keys, t) * scale
			if t >= last and cue.player.IsPlaying then cue.player:Stop() end
		end
		if not left then stop() end
	end)
	return stop
end

return WinnersSound
