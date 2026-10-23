-- Synced from src/client by default.project.json.
local Players = game:GetService("Players")
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
require(script.Parent.Loading).show()
local loadingEvents={Root:WaitForChild("RoundView").OnClientEvent:Connect(function()end),Root:WaitForChild("CombatEvents").OnClientEvent:Connect(function()end),Root:WaitForChild("CombatCosmetics").OnClientEvent:Connect(function()end)}
require(script.Parent.Loading).run()
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
local Flight = require(script.Parent.FlightController)
local Camera = require(script.Parent.ChaseCamera)
local HUD = require(script.Parent.FlightHUD)
local planes = workspace:WaitForChild("Planes")
local Menu=require(script.Parent.MenuController)
Menu.start()
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
require(script.Parent.CombatController).start(function() return plane end,effects)
require(script.Parent.Audio).start(function()return plane end)
require(script.Parent.Tutorial).start(function()return plane end)
require(script.Parent.MatchTips).start(function()return plane end)
require(script.Parent.DevTools).start(Menu)
for _,connection in ipairs(loadingEvents) do connection:Disconnect() end
