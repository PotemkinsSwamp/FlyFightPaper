-- Synced from src/server by default.project.json.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
Players.CharacterAutoLoads = false
-- Keep unused saved art out of the replicated game.
local archive = ServerStorage:FindFirstChild("DormantArt") or Instance.new("Folder")
archive.Name = "DormantArt"
archive.Parent = ServerStorage
local root = ReplicatedStorage:WaitForChild("FlyFightPaper")
for _, child in ipairs(root:GetChildren()) do
 if child.Name ~= "Shared" and child.Name ~= "Generated" and child.Name ~= "Assets" then child.Parent = archive end
end
for _, child in ipairs(workspace:GetChildren()) do
 if child.Name ~= (workspace:FindFirstChild("Arena") and "Arena" or "GreyboxRoom") and child.Name ~= "CityRug" and child.Name ~= "Camera" and child.Name ~= "Terrain" then
  if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then child:Destroy() end
 end
end
workspace.Gravity = 196.2
workspace:SetAttribute("Milestone", "M4")
local flight = require(script.Parent.FlightService).new()
flight.active=false
local combat = require(script.Parent.CombatService).new(flight)
local bots=require(script.Parent.BotService).new(flight, combat)
local profiles=require(script.Parent.ProfileRuntime).new(flight.catalog)
local desks=require(script.Parent.DeskService).new(flight,profiles)
local rounds=require(script.Parent.RoundRuntime).new(flight,combat,bots,profiles)
local props=require(script.Parent.PropsService).new(flight.room)
rounds.onBegin=function()props:reset();combat:resetPaperTargets()end
-- Hidden paper targets: one score per pilot per sign per round, with their own cap.
combat.onPaperTarget=function(p,index)
 if rounds.engine.phase=="ACTIVE" then rounds.engine:propContribution("target:"..index..":"..p.id,p.id);rounds:earnings() end
end
combat.onProp=function(p,part)
 if rounds.engine.phase=="ACTIVE" and props:breakPart(part) then
  rounds.engine:propContribution("prop:"..part.Name,p.id);rounds:earnings()
  combat:emit({kind="prop",position=part.Position})
 end
end
local avatars=require(script.Parent.AvatarService).new(flight)
-- Life changes are synchronous. A deferred signal must not reuse a newer plane's identity.
flight.onSpawn=function(p) combat:attach(p);if p.kind=="bot" then bots:reset(p) end;rounds:bind(p);avatars:assign(p) end
flight.onDeath=function(p,cause) combat:death(p,cause) end
flight.onRefold=function(p) combat:refit(p) end
flight.onLand=function(p) desks:perform(p,"refill") end
-- The winners' moment: the top 3 jump up on their desks; everyone sits back down for the vote lap.
rounds.onWinners=function(ids) avatars:celebrate(ids) end
rounds.onSitDown=function() avatars:sitDown() end
local removed=flight.onRemoved
flight.onRemoved=function(p) combat:detach(p);avatars:remove(p);if removed then removed(p) end end
-- Studio perf readout: server frame times over the last second, shown by the client dev overlay.
if game:GetService("RunService"):IsStudio() then
 local times,clock={},0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  table.insert(times,dt);clock+=dt
  if clock<1 then return end
  table.sort(times);local total=0;for _,t in ipairs(times) do total+=t end
  root:SetAttribute("ServerFrameMs",total/#times*1000);root:SetAttribute("ServerFrameP95Ms",times[math.ceil(#times*.95)]*1000)
  times,clock={},0
 end)
end
