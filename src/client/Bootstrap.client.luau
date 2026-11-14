-- Synced from src/client by default.project.json.
local Players = game:GetService("Players")
-- Tab is the game's own live standings (RoundEnd), so Roblox's player list stays off.
task.spawn(function()
 for _ = 1, 20 do
  if pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end) then return end
  task.wait(0.5)
 end
end)
-- Claude's Studio test runs (Alan 2026-11-07): the workspace attribute DevMute, set in Edit before Play, silences
-- every sound so a test doesn't play over Alan's work. Studio only; cleared again after the run.
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevMute") then
 local quiet=Instance.new("SoundGroup");quiet.Name="DevMute";quiet.Volume=0;quiet.Parent=game:GetService("SoundService")
 local function hush(d) if d:IsA("Sound") then d.SoundGroup=quiet end end
 for _,place in ipairs({workspace,game:GetService("SoundService"),game:GetService("ReplicatedStorage"),Players.LocalPlayer}) do
  for _,d in ipairs(place:GetDescendants()) do hush(d) end
 end
 game.DescendantAdded:Connect(function(d) pcall(hush,d) end)
end
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
require(script.Parent.Loading).show()
local loadingEvents={Root:WaitForChild("RoundView").OnClientEvent:Connect(function()end),Root:WaitForChild("CombatEvents").OnClientEvent:Connect(function()end),Root:WaitForChild("CombatCosmetics").OnClientEvent:Connect(function()end)}
local Loading = require(script.Parent.Loading)
Loading.run()
-- Menus first (docs/plan/LOAD-PLAN.md step 1): the menus work while the town is still arriving; everything below
-- them needs the town's parts, so it starts once they're in (Play waits for that: Loading.town).
local Menu=require(script.Parent.MenuController)
Menu.start()
Loading.waitTown()
require(script.Parent.FanSpin).start()
require(script.Parent.DeskPieces).start()
require(script.Parent.TowerClock).start()
require(script.Parent.TrainMotion).start()
task.spawn(require(script.Parent.SpeedPickups).start)
require(script.Parent.FanWind).start()
require(script.Parent.PlaneDeaths).start()
require(script.Parent.WeaponMotion).start()
require(script.Parent.ControlZone).start()
require(script.Parent.PaperTargets).start()
require(script.Parent.RangeTargets).start()
require(script.Parent.RangeBoard).start()
task.spawn(require(script.Parent.ChalkCloud).start)
require(script.Parent.ScorePopups).start()
require(script.Parent.PlaneLooks).start()
local Flight = require(script.Parent.FlightController)
local Camera = require(script.Parent.ChaseCamera)
local HUD = require(script.Parent.FlightHUD)
local planes = workspace:WaitForChild("Planes")
require(script.Parent.RoundEnd).start()
local action = Root:WaitForChild("FlightAction")
local plane, stopFlight
local function attach(model)
 if model.Name ~= tostring(Players.LocalPlayer.UserId) then return end
 if stopFlight then stopFlight() end
 plane = model
 model:WaitForChild("Root")
 stopFlight = Flight.start(model)
end
planes.ChildAdded:Connect(attach)
for _, model in ipairs(planes:GetChildren()) do attach(model) end
Camera.start(function() return plane end)
HUD.start(function() return plane end, function(name,value) action:FireServer(name,value) end)
local effects=require(script.Parent.CombatEffects).start(function() return plane end)
require(script.Parent.Spitballs).start(function() return plane end)
require(script.Parent.CombatController).start(function() return plane end,effects)
require(script.Parent.TouchControls).start(function() return plane end)
require(script.Parent.Audio).start(function()return plane end)
require(script.Parent.Tutorial).start(function()return plane end)
require(script.Parent.MatchTips).start(function()return plane end)
require(script.Parent.DevTools).start(Menu)
Root.RoundAction:FireServer("mapReady")
Loading.ready()
for _,connection in ipairs(loadingEvents) do connection:Disconnect() end
