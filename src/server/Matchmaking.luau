local Run=game:GetService("RunService")
local Gameplay=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay)
local Config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Server).routing
local Service={};Service.__index=Service
function Service.classFor(profile)
 return profile and profile.qualification and profile.qualification.count>=Gameplay.bots.rookie_qualifying_matches and "regular" or "rookie"
end
function Service.new(profiles,options)
 options=options or {}
 local mock=options.mock;if mock==nil then mock=Run:IsStudio() or game.PlaceId==0 end
 local self=setmetatable({profiles=profiles,mock=mock,transfers={},loading=not mock},Service)
 if not mock then
  self.platform=options.platform or require(script.Parent.MatchmakingAdapter).new()
  self.platform:onFailure(function(player)self:failed(player)end)
  task.spawn(function()
   local attempt=0
   while self.loading or self.unavailable do
    attempt+=1
    local ok,class=pcall(function()return self.platform:currentClass()end)
    if ok then self.class=class;self.loading=false;self.unavailable=false;return end
    if attempt>=Config.discovery_failure_attempts then self.loading=false;self.unavailable=true end
    task.wait(math.min(Config.discovery_retry_max_seconds,2^math.min(attempt-1,Config.discovery_retry_exponent_cap)))
   end
  end)
  task.spawn(function()
   while true do
    if self.class then pcall(function()self.platform:advertise(self.class)end) end
    task.wait(Config.advertise_seconds)
   end
  end)
 end
 return self
end
function Service:failed(player)
 if not self.transfers[player] then return end
 self.transfers[player]=nil;player:SetAttribute("Routing",false)
 player:SetAttribute("MenuMessage","Room transfer failed. Your saved progress is safe. Try Play again.")
 if player.Parent and not self.profiles.entries[player] then self.profiles:load(player) end
end
function Service:admit(player)
 local profile=self.profiles:view(player);if not profile or self.transfers[player] then return false end
 if self.loading or self.unavailable then player:SetAttribute("MenuMessage","Room matching is unavailable. Stay in the menu and try Play again shortly.");return false end
 local class=Service.classFor(profile)
 if not self.class then self.class=class end
 if class==self.class then return true end
 if self.mock then player:SetAttribute("MenuMessage","Studio keeps beginner and established rooms separate. Start a new Play session to test the other room.");return false end
 self.transfers[player]=true;player:SetAttribute("Routing",true);player:SetAttribute("MenuMessage","Finding a room for your experience level. Saving before the transfer.")
 task.spawn(function()
  local ok,destination=pcall(function()return self.platform:destination(class)end)
  if not ok then self:failed(player);return end
  local e=self.profiles.entries[player]
  if not e then self:failed(player);return end
  self.profiles:release(player)
  -- Wait for ProfileStore to confirm the final save before transferring.
  while self.profiles.entries[player] and player.Parent do task.wait(Config.transfer_poll_seconds) end
  if not player.Parent then self.transfers[player]=nil;return end
  local sent=pcall(function()self.platform:send(player,destination)end)
  if not sent then self:failed(player) end
 end)
 return false
end
return Service
