local Root=game.ReplicatedStorage.FlyFightPaper
local Options={}
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
 Root:SetAttribute("SpeedMatch",settings.speedMatch~=false) -- phones: slow to the enemy you tail (FlightController)
end
return Options
