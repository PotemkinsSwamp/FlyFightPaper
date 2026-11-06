local Root=game.ReplicatedStorage.FlyFightPaper
local KeyBinds=require(Root.Shared.KeyBinds)
local Options={}
Options.keys={} -- the player's keys as KeyCodes (settings.keys; Settings > Controls)
local function applyKeys(saved)
 for action,key in KeyBinds.current(saved) do Options.keys[action]=Enum.KeyCode[key];Root:SetAttribute("Key_"..action,key) end
end
applyKeys(nil)
-- How the game writes the player's key for `action`.
function Options.keyName(action) return KeyBinds.name(Options.keys[action].Name) end
-- A button's word with your Got it key after it; stays right if the key changes.
function Options.gotItLabel(label,word)
 local function show() label.Text=word.."  ["..Options.keyName("gotIt").."]" end
 Root:GetAttributeChangedSignal("Key_gotIt"):Connect(show);show()
end
-- Graphics quality: the game can't move the player's own Roblox graphics slider, so it turns its own heavier
-- lighting off instead (these Lighting changes stay on this player's screen). Effects counts read the attribute.
local Lighting=game:GetService("Lighting")
local function applyQuality(quality)
 Lighting.GlobalShadows=quality~="Low"
 for _,name in ipairs({"SunRays","Bloom"}) do local effect=Lighting:FindFirstChild(name);if effect then effect.Enabled=quality=="High" end end
 local air=Lighting:FindFirstChildOfClass("Atmosphere");if air then air.Density=quality=="Low" and 0 or 0.06 end
end
function Options.apply(settings)
 applyQuality(settings.quality)
 Root:SetAttribute("Sensitivity",math.min(settings.sensitivity,1.8));Root:SetAttribute("SoundVolume",settings.sound);Root:SetAttribute("MusicVolume",settings.music)
 Root:SetAttribute("ReducedShake",settings.reducedShake);Root:SetAttribute("Quality",settings.quality);Root:SetAttribute("CrosshairColor",settings.crosshairColor);Root:SetAttribute("CrosshairSize",settings.crosshairSize)
 Root:SetAttribute("MatchTips",settings.matchTips~=false)
 Root:SetAttribute("AutoFire",settings.autoFire~=false) -- phones: FIRE shoots by itself on target (CombatController)
 applyKeys(settings.keys)
 Root:SetAttribute("SpeedMatch",settings.speedMatch~=false) -- phones: slow to the enemy you tail (FlightController)
 -- phones: where the player moved their buttons (TouchControls; nil = the game's layout)
 Root:SetAttribute("TouchLayout",settings.touchLayout and game:GetService("HttpService"):JSONEncode(settings.touchLayout) or nil)
end
return Options
