-- The winners' moment's sound (Alan 2026-11-21, docs/decisions/2026-11-21-winners-sound-dramatic.md): dramatic, not a
-- party. The room is nearly silent in the dark and while the three spotlights come on; the music only arrives once
-- all three are on, plays under the emotes, steps down for the results card and is gone before the vote lap. Times
-- are seconds from "Pencils down!" and match WinnersCutscene's own (banner 0.5, lights out 1.5, glide 2.0, then the
-- spotlights: 3rd 4.6, 2nd 5.6, 1st 6.6; card 17-27).
-- Uses Roblox's newer audio objects (AudioPlayer wired to the speakers): they also play in Studio's Edit mode, so
-- the same mix can be heard there (`WinnersSound.play(id)` from the command bar).
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local WinnersSound = {}
-- The winners' songs (all APM, licensed for Roblox games). Alan's picks by ear 2026-11-21: all four, a random one each round.
WinnersSound.TRACKS = { depth = 1836652816, step = 1836098839, hyped = 1838051027, relent = 9043799922 } -- Depth Charge 30, Anthemic Step Music, How Hyped How Hot (a) (30), Relentless (b) 30
local lastSong
-- A random song, never the same one twice in a row.
function WinnersSound.pick()
	local songs = {}
	for name in WinnersSound.TRACKS do
		if name ~= lastSong then table.insert(songs, name) end
	end
	lastSong = songs[math.random(#songs)]
	return lastSong
end
local CLICK = 9125665485 -- the spotlights' switch: PSE "Metal Clunk Moviola Device Framing Plate Lever" (Alan's pick of four, 2026-11-21: "the closest")
-- Alan 2026-11-21: "add room echo and lower the pitch". Played slower, so lower and heavier; and the ring of a dark
-- hall after it: the seconds it rings and how loud the ring is beside the switch itself (dB).
local CLICK_SPEED, HALL_DECAY, HALL_WET = 0.75, 2.2, -4
local FIRST_LIGHT = 6.6
local MUSIC_AFTER = 0.5 -- the last spotlight's click lands in the quiet, then the music

-- Each cue: a sound, then its volume at points in time (straight lines between them). It starts at the first point
-- and stops at the last.
local function cues(track)
	-- The music sits in the background, under the emotes' sounds (Alan 2026-11-21: at 0.5 it drowned them).
	local list = { { track, { FIRST_LIGHT + MUSIC_AFTER, 0.2 }, { 17, 0.2 }, { 18, 0.14 }, { 23.5, 0.14 }, { 26, 0 } } }
	-- A switch for each spotlight, a second apart, 1st's the loudest.
	for place, volume in { 0.9, 0.75, 0.6 } do
		local at = FIRST_LIGHT - (place - 1)
		table.insert(list, { CLICK, { at, volume }, { at + 1.5, volume } })
	end
	return list
end

local function volumeAt(keys, t)
	for i = 3, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b[1] then return a[2] + (b[2] - a[2]) * math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1) end
	end
	return 0
end

-- Plays the whole mix with `track` as the winners' music: the song follows the Music slider, the crowd the Sound
-- slider. Returns a function that stops it early.
function WinnersSound.play(track)
	local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
	local folder = Instance.new("Folder")
	folder.Name = "WinnersSound"
	local speakers = Instance.new("AudioDeviceOutput")
	speakers.Parent = folder
	local hall = Instance.new("AudioReverb") -- the switches go through it; the music does not
	hall.DecayTime, hall.WetLevel = HALL_DECAY, HALL_WET
	hall.Parent = folder
	local out = Instance.new("Wire")
	out.SourceInstance, out.TargetInstance = hall, speakers
	out.Parent = hall
	local live = {}
	for _, keys in cues(track) do
		local player = Instance.new("AudioPlayer")
		player.Asset = "rbxassetid://" .. keys[1]
		player.Volume = 0
		if keys[1] == CLICK then player.PlaybackSpeed = CLICK_SPEED end
		player.Parent = folder
		local wire = Instance.new("Wire")
		wire.SourceInstance, wire.TargetInstance = player, keys[1] == CLICK and hall or speakers
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
		local t, left = os.clock() - start, false
		for _, cue in live do
			local scale = Root:GetAttribute(cue.keys[1] == track and "MusicVolume" or "SoundVolume") or 1
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
