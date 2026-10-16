local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Root=RS:WaitForChild("FlyFightPaper")
local Controller={}
function Controller.start(getPlane,effects)
 local remote=Root:WaitForChild("CombatInput")
 local held={false,false};local seq,life,clock=0,nil,0
 local function groupFor(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then return 1 end
  if input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2 then return 2 end
 end
 local function send(which)
  local p=getPlane();if not p or not p.Parent or p:GetAttribute("State")~="FLYING" then return end
  if life~=p:GetAttribute("Life") then life=p:GetAttribute("Life");seq=0 end
  local body=p:FindFirstChild("Root");if not body then return end
  seq+=1
  remote:FireServer({group=which,down=held[which] and not Root:GetAttribute("OverlayOpen"),direction=effects.aim(body,which),at=workspace:GetServerTimeNow(),life=life,seq=seq})
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
 -- While firing, refresh the aim 30 times a second: the server fires each round along the latest aim it has,
 -- and a 0.1 s old aim misses a turning plane at range. Idle triggers resync 10 times a second.
 Run.Heartbeat:Connect(function(dt)
  clock+=dt
  local firing=held[1] or held[2]
  if clock>=(firing and 1/30 or .1) then
   clock=0
   for which=1,2 do if held[which] or not firing then send(which) end end
  end
 end)
end
return Controller
