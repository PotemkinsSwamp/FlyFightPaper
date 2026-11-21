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
-- The spotlights' switch (all Pro Sound Effects, licensed): four to pick from by ear. Studio's "click" button (hangar
-- dev row) steps through them; the ones Alan does not pick, and the stepping, go once he has chosen.
WinnersSound.CLICKS = { 9119727134, 9120098454, 9125665485, 9120089728 } -- Switch Impact On Flip Up Large Metal 2, Toggle Switch Metal Industrial Equipment 66, Metal Clunk Moviola Device Framing Plate Lever, Toggle Switches Moviola Editing Machine 17
local FIRST_LIGHT = 6.6
local MUSIC_AFTER = 0.5 -- the last spotlight's click lands in the quiet, then the music

-- Each cue: a sound, then its volume at points in time (straight lines between them). It starts at the first point
-- and stops at the last.
local function cues(track, click)
	local list = { { track, { FIRST_LIGHT + MUSIC_AFTER, 0.5 }, { 17, 0.5 }, { 18, 0.35 }, { 23.5, 0.35 }, { 26, 0 } } }
	-- A switch for each spotlight, a second apart, 1st's the loudest.
	for place, volume in { 0.9, 0.75, 0.6 } do
		local at = FIRST_LIGHT - (place - 1)
		table.insert(list, { click, { at, volume }, { at + 1.5, volume } })
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
	local live = {}
	for _, keys in cues(track, WinnersSound.CLICKS[Root:GetAttribute("DevSpotClick") or 1]) do
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
