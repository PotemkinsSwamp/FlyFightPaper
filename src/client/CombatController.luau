local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Root=RS:WaitForChild("FlyFightPaper")
local Controller={}
function Controller.start(getPlane,effects)
 local remote=Root:WaitForChild("CombatInput")
 local held={false,false};local seq,life,clock=0,nil,0
 local Touch=require(script.Parent.TouchControls)
 local FlightState=require(script.Parent.FlightController).state
 -- Phone auto-fire (Alan 2026-10-28, Settings): FIRE (weapon 1) shoots by itself while its ring says the shots land.
 -- The 2 weapon stays hold-to-use.
 local auto=false
 local function down(which) return held[which] or which==1 and auto end
 local function groupFor(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then return 1 end
  if input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2 then return 2 end
 end
 local function send(which)
  local p=getPlane();if not p or not p.Parent or p:GetAttribute("State")~="FLYING" then return end
  if life~=p:GetAttribute("Life") then life=p:GetAttribute("Life");seq=0 end
  local body=p:FindFirstChild("Root");if not body then return end
  seq+=1
  local direction,range=effects.aim(body,which)
  remote:FireServer({group=which,down=down(which) and not Root:GetAttribute("OverlayOpen"),direction=direction,range=range,at=workspace:GetServerTimeNow(),life=life,seq=seq})
 end
 Input.InputBegan:Connect(function(input,processed)
  if processed or Input:GetFocusedTextBox() or Root:GetAttribute("OverlayOpen") then return end
  local which=groupFor(input)
  if which then held[which]=true;effects.press(which,true);send(which) end
 end)
 Input.InputEnded:Connect(function(input)
  local which=groupFor(input)
  if which then held[which]=false;effects.press(which,false);send(which) end
 end)
 Input.WindowFocusReleased:Connect(function()held={false,false};effects.press(1,false);effects.press(2,false);send(1);send(2)end)
 -- Phones: the Fire buttons (TouchControls) hold the triggers like the mouse buttons.
 Touch.onFire=function(which,isDown) if Root:GetAttribute("OverlayOpen") then isDown=false end;held[which]=isDown;effects.press(which,down(which));send(which) end
 -- Studio test hook: the player attribute DevFire holds the left trigger (Studio MCP can't press the game's mouse).
 if Run:IsStudio() then
  local player=Players.LocalPlayer
  player:GetAttributeChangedSignal("DevFire"):Connect(function() held[1]=player:GetAttribute("DevFire")==true;effects.press(1,held[1]);send(1) end)
 end
 -- While firing, refresh the aim 30 times a second: the server fires each round along the latest aim it has,
 -- and a 0.1 s old aim misses a turning plane at range. Idle triggers resync 10 times a second.
 Run.Heartbeat:Connect(function(dt)
  clock+=dt
  local nowAuto=Touch.active() and Root:GetAttribute("AutoFire")~=false and FlightState.onTarget==true and not Root:GetAttribute("OverlayOpen")
  if nowAuto~=auto then auto=nowAuto;effects.press(1,down(1));send(1) end
  local firing=down(1) or held[2]
  if clock>=(firing and 1/30 or .1) then
   clock=0
   for which=1,2 do if down(which) or not firing then send(which) end end
  end
 end)
end
return Controller
