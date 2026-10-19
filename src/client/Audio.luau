local Root=game.ReplicatedStorage.FlyFightPaper
local Lines=require(Root:WaitForChild("Shared"):WaitForChild("Lines"))
local Sounds=game:GetService("SoundService")
local Audio={}
-- {sound, playback speed, volume, seconds to play (default .22)}. A number is a Creator Store sound, mostly Pro
-- Sound Effects (licensed for Roblox): paperclip "Key Dings Metal Clinking 11", staple "Air Stapler Gun 2", pellet
-- "Blowgun Chuff", eraser "Magic Zoom Up Sharp Tubular Whoosh 8", near miss "Whooshes Fast Wipes 3", death "Paper
-- Packet Unfolding Crumpled Sheets 4", start a school bell, purchase "Coin Collect 2", finish "Pealess Whistle Fox 40 4",
-- fan "Drone And Whir Unbalanced Fan 1", land "Box Grab 25"; rubber and the lock beeps are Roblox's own classic
-- "Rubber band sling shot" and "electronicpingshort". Text = Roblox's built-in sounds. Added 2026-10-13 (Alan's
-- notes 8-13): paperclip charge "Electric Arcing 6", torn paper "Paper Tear Fast Harsh Rip 1", shots in flight
-- "Zip Bys Airy Rips 26". `after` = {sound, seconds later} plays a second sound (pencil: band thwap, then the pencil).
-- Weapons share one loudness (WEAPON); missiles (eraser, pencil) are louder (MISSILE); the stapler a touch quieter.
local WEAPON,MISSILE=.4,.7
local WEAPON_HEARING_STUDS=250 -- other planes' weapons are heard only this close (Alan's note 12)
local definitions={
 pellet={110204084658828,1.3,WEAPON},staple={9113075143,1,WEAPON*.85},rubber={12222103,1.1,WEAPON},
 paperclip={9114237705,1.4,WEAPON*.6,.2,after={"paperclipting",.15}},paperclipting={9116163687,1.25,WEAPON,.6},
 eraser={9125648149,1,MISSILE,.7},pencil={12222103,.75,WEAPON,.25,after={"pencilflight",.06}},pencilflight={"impact_explosion_03.mp3",1.8,MISSILE},
 flight={9120989898,1,.3,1},tear={9125724621,1.2,.25,.35},
 lock={12221990,1.3,.5},lockbeep={12221990,1.8,.25},incoming={12221990,.8,.5},empty={"action_falling.ogg",1.4,.15},
 fan={9114185133,1.2,.35,1},land={9113563828,1,.5,.6},service={"volume_slider.ogg",1.9,.2},
 death={9125723704,1.1,.6,1},hit={"volume_slider.ogg",3,.35},kill={"impact_explosion_03.mp3",2.4,.3},start={105176025193207,1,.35,3},finish={9117261163,1,.4,.8},purchase={1169806635,1,.4,.8},
 -- A tutorial step done: the coin sound as a rising two-note chime, louder than a hoop's ding (Alan: hear every step).
 stepDone={1169806635,1.2,.6,.8,after={"stepDone2",.12}},stepDone2={1169806635,1.6,.55,.8},
}
-- Sounds with a position are heard from that spot in the room (3D: louder and on that side when it's near you);
-- the rest sit straight in SoundService, heard the same anywhere. (Until 2026-10-18 those sat in an attachment
-- outside the room, which put them at the room's middle: far away they faded out, e.g. the tutorial's chimes.)
local pool,available,busy,spots={},{},{},{}
local function id(definition)
 return type(definition[1])=="number" and "rbxassetid://"..definition[1] or "rbxasset://sounds/"..definition[1]
end
function Audio.play(name,position,reach)
 local definition=definitions[name];if not definition then return end
 if definition.after then task.delay(definition.after[2],Audio.play,definition.after[1],position,reach) end
 local sound=table.remove(available)
 if not sound then
  if #pool>=24 then return end
  sound=Instance.new("Sound");sound.RollOffMinDistance=40
  spots[sound]=Instance.new("Attachment");spots[sound].Name="SoundSpot";table.insert(pool,sound)
 end
 sound.RollOffMaxDistance=reach or 450
 local spot=spots[sound]
 if position then spot.WorldPosition=position;spot.Parent=workspace.Terrain;sound.Parent=spot else sound.Parent=Sounds end
 sound.SoundId=id(definition);sound.PlaybackSpeed=definition[2];sound.Volume=definition[3]*(Root:GetAttribute("SoundVolume") or 1)
 local token={};busy[sound]=token;sound:Play()
 task.delay(definition[4] or .22,function()if busy[sound]==token then sound:Stop();busy[sound]=nil;table.insert(available,sound) end end)
end
-- A shot heard as it flies: the sound rides on its visual, so it passes you (missiles louder).
function Audio.flight(part,weapon)
 local sound=part:FindFirstChild("Flight")
 if not sound then
  local definition=definitions.flight
  sound=Instance.new("Sound");sound.Name="Flight";sound.SoundId=id(definition);sound.PlaybackSpeed=definition[2]
  sound.RollOffMinDistance,sound.RollOffMaxDistance=15,WEAPON_HEARING_STUDS;sound.Parent=part
 end
 local missile=weapon=="eraser" or weapon=="pencil"
 sound.Volume=definitions.flight[3]*(missile and MISSILE/WEAPON or 1)*(Root:GetAttribute("SoundVolume") or 1)
 sound.TimePosition=0;sound:Play()
end
Audio.WEAPON_HEARING_STUDS=WEAPON_HEARING_STUDS
function Audio.start(getPlane)
 -- Classroom ambience: Pro Sound Effects "Kids Walla 2" (children in a school room), kept far in the background.
 local ambience=Instance.new("Sound");ambience.Name="ClassroomAmbience";ambience.SoundId="rbxassetid://9112811182";ambience.Looped=true;ambience.Parent=Sounds;ambience:Play()
 -- Paper whoosh: airy wind (Pro Sound Effects "Plasma Trails Constant Airy Whooshing 2") that rises with speed.
 local whoosh=Instance.new("Sound");whoosh.Name="PaperWhoosh";whoosh.SoundId="rbxassetid://9125742262";whoosh.Looped=true;whoosh.Volume=0;whoosh.Parent=Sounds;whoosh:Play()
 -- Background music: a shuffled playlist of free APM tracks licensed for Roblox games (Alan: faster, playful, a
 -- playlist). Add or remove ids here. The Music slider sets it; the classroom hum follows the Sound slider.
 local playlist={1844592742,1836626222,1842246698,1842172723} -- Action Kids, Frisky, Funky Thing, Disguise
 for i=#playlist,2,-1 do local j=math.random(i);playlist[i],playlist[j]=playlist[j],playlist[i] end
 -- Every sound loads now, so the first play of each isn't cut short while it loads.
 task.spawn(function() local ids={};for _,definition in definitions do table.insert(ids,id(definition)) end;game:GetService("ContentProvider"):PreloadAsync(ids) end)
 -- Lessons have one calm song of their own (Alan: peaceful, focusing, playful, subtle, maybe classical; one song,
 -- not a playlist), looped, quiet, and no classroom chatter, so the step chimes stand out.
 -- ponytail: APM "Pure Innocence" until Alan picks the song by ear (choices in docs/systems/sound-and-effects.md).
 local LESSON_SONG=1847585588
 local function inLesson() return Root:GetAttribute("TutorialOpen")==true end
 local music=Instance.new("Sound");music.Name="Music";music.Parent=Sounds
 local track=0
 local function nextTrack()
  music.Looped=inLesson()
  if inLesson() then music.SoundId="rbxassetid://"..LESSON_SONG
  else track=track%#playlist+1;music.SoundId="rbxassetid://"..playlist[track] end
  music:Play()
 end
 music.Ended:Connect(nextTrack)
 -- Volume glides to the slider's value (a quarter second), so a jump from 0 to 100% fades instead of blasting.
 local glide=TweenInfo.new(.25)
 local function volumes()
  game:GetService("TweenService"):Create(ambience,glide,{Volume=(inLesson() and 0 or .04)*(Root:GetAttribute("SoundVolume") or 1)}):Play()
  game:GetService("TweenService"):Create(music,glide,{Volume=(inLesson() and .084 or .2)*(Root:GetAttribute("MusicVolume") or 1)}):Play()
 end
 Root:GetAttributeChangedSignal("MusicVolume"):Connect(volumes);Root:GetAttributeChangedSignal("SoundVolume"):Connect(volumes)
 Root:GetAttributeChangedSignal("TutorialOpen"):Connect(function() nextTrack();volumes() end)
 volumes();nextTrack()
 local lastPhase
 local Players=game:GetService("Players")
 Players.LocalPlayer:GetAttributeChangedSignal("MenuMessage"):Connect(function()
  local value=Players.LocalPlayer:GetAttribute("MenuMessage") or ""
  if value:find("Purchased") or value:find("simulation complete") or value:find("Part unlocked") then Audio.play("purchase") end
 end)
 Root:WaitForChild("RoundView").OnClientEvent:Connect(function(s)
  if s.phase~=lastPhase then if s.phase=="ACTIVE" then Audio.play("start") elseif s.phase=="RESULTS" then Audio.play("finish") end;lastPhase=s.phase end
 end)
 local function combat(events)
  for _,event in ipairs(events) do
   -- Own shots already played on the click frame (except erasers, which wait for the server).
   local own=event.owner==tostring(Players.LocalPlayer.UserId) and event.weapon~="eraser"
   if event.kind=="shot" and not own and (event.position-workspace.CurrentCamera.CFrame.Position).Magnitude<WEAPON_HEARING_STUDS then Audio.play(event.weapon,event.position,WEAPON_HEARING_STUDS)
   elseif event.kind=="death" and (event.position-workspace.CurrentCamera.CFrame.Position).Magnitude<450 then Audio.play("death",event.position) end
  end
 end
 Root:WaitForChild("CombatEvents").OnClientEvent:Connect(combat)
 Root:WaitForChild("CombatCosmetics").OnClientEvent:Connect(combat)
 -- Being shot at: a soft paper tear when a shot passes close or hits you (Alan's note 13); at most one at a time,
 -- so a long scrape or a stream of pellets doesn't stack them.
 local tearAt=0
 local function tear() if os.clock()-tearAt>.3 then tearAt=os.clock();Audio.play("tear") end end
 Players.LocalPlayer:GetAttributeChangedSignal("NearMissAt"):Connect(tear)
 local state,life,lift,lock,incoming,message,beepAt,lockBeepAt,health,updraft
 game:GetService("RunService").Heartbeat:Connect(function()
  local p=getPlane()
  local body=p and p.Parent and p:FindFirstChild("Root")
  -- Whoosh only above the plane's own normal speed (dives, power-ups, boost), growing with how far above:
  -- normal flight is silent, and a slow plane's top dive whooshes less than a fast plane's (Alan's note 7).
  local phase=p and p:GetAttribute("State")
  local speed=body and (phase=="FLYING" or phase=="TAKEOFF") and body.AssemblyLinearVelocity.Magnitude or 0
  local rush=math.clamp((speed-(p and p:GetAttribute("Speed") or math.huge)-3)/80,0,1)
  whoosh.Volume=whoosh.Volume+(rush*.35*(Root:GetAttribute("SoundVolume") or 1)-whoosh.Volume)*.1;whoosh.PlaybackSpeed=.8+rush*.6
  if not body then return end
  local nextState=p:GetAttribute("State");local nextLift=p:GetAttribute("Lift");local nextLock=p:GetAttribute("LockProgress");local nextIncoming=math.max(p:GetAttribute("IncomingLockUntil") or 0,p:GetAttribute("EraserIncomingUntil") or 0)>workspace:GetServerTimeNow()
  if life==p:GetAttribute("Life") then
   local nextUpdraft=(p:GetAttribute("Updraft") or 0)>0
   if nextState=="FLYING" and nextUpdraft and not updraft then Audio.play("fan") elseif lift and lift>0 and nextLift<=0 then Audio.play("empty") end
   updraft=nextUpdraft
   if health and (p:GetAttribute("Health") or 0)<health and nextState=="FLYING" then tear() end
   if state=="LANDING" and nextState=="DESK" then Audio.play("land") end
   if lock and lock<1 and nextLock and nextLock>=1 then Audio.play("lock") end
   -- Beeps while the eraser is locking, faster as it gets closer.
   if nextLock and nextLock>0 and nextLock<1 and os.clock()-(lockBeepAt or 0)>.3-.2*nextLock then Audio.play("lockbeep");lockBeepAt=os.clock() end
   -- A locked-on eraser warns with a repeating beep until the lock breaks.
   if nextIncoming and (not incoming or os.clock()-beepAt>.35) then Audio.play("incoming");beepAt=os.clock() end
   local nextMessage=p:GetAttribute("Message")
   if message~=nextMessage and nextMessage and (Lines.is("serviceDone",nextMessage) or Lines.is("refoldDone",nextMessage)) then Audio.play("service") end
   message=nextMessage
  end
  state,life,lift,lock,incoming,health=nextState,p:GetAttribute("Life"),nextLift,nextLock,nextIncoming,p:GetAttribute("Health")
 end)
end
return Audio
