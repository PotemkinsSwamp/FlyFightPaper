local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Root=game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Hangar=require(script.Parent.Hangar)
local Options=require(script.Parent.Options)
local Tutorial=require(script.Parent.Tutorial)
local Board=require(script.Parent.MenuBoard)
local SettingsScreen=require(script.Parent.SettingsScreen)
local PauseScreen=require(script.Parent.PauseScreen)
local ShopScreen=require(script.Parent.ShopScreen)
local WaitScreen=require(script.Parent.WaitScreen)
local PaperUI=require(script.Parent.PaperUI)
local Menu={}
function Menu.start()
 local player=Players.LocalPlayer
 local action=Root:WaitForChild("RoundAction")
 local gui=Instance.new("ScreenGui");gui.Name="GameMenu";gui.DisplayOrder=6;gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
 local openButton=PaperUI.button(gui,"OpenMenu",require(Root.Shared.UIAssets).mainmenu.strip.yellow,"Menu",16,64,150,52,-2,function()end,30)
 openButton.Label.TextColor3=PaperUI.INK
 local state={screen="home",snapshot=nil,profile=nil,overlay=false,lastPhase=nil}
 local render
 local function overlay(open)
  state.overlay=open
  Root:SetAttribute("OverlayOpen",open);action:FireServer("overlay",open)
  if render then render() end
 end
 local function home()
  state.screen="home";state.fromDesk=false;render()
 end
 local board=Board.new(gui.Parent,{
  play=function()action:FireServer("join")end,
  hangar=function()Menu.show("hangar")end,
  settings=function()state.screen="settings";render()end,
  tutorial=function()Tutorial.choose(function()overlay(false)end)end, -- the Training board
  prestige=function()action:FireServer("prestige")end,
  -- The mock shop is Studio-only; the server also refuses it on real profiles.
  shop=game:GetService("RunService"):IsStudio() and function()state.screen="shop";render()end or nil,
 })
 local settingsScreen=SettingsScreen.new(gui.Parent,{
  save=function(settings)action:FireServer("settings",settings);Options.apply(settings)end,
  back=function()home()end,
 })
 local hangarScreen
 hangarScreen=Hangar.new(gui.Parent,{
  action=action,
  -- Opened with Edit at the desk, Back (and Save & fly) go straight back to the desk.
  back=function()if state.fromDesk then home();overlay(false) else home() end end,
  flown=function()home();overlay(false)end,
  fly=function()
   local draft=hangarScreen.draft();home();overlay(false)
   -- From the main menu, join first; the build is fitted once our plane is waiting at a desk.
   if not player:GetAttribute("InMatch") then action:FireServer("join") end
   task.spawn(function()
    for _=1,40 do
     local plane=workspace:FindFirstChild("Planes") and workspace.Planes:FindFirstChild(tostring(player.UserId))
     if plane and plane:GetAttribute("State")=="DESK" then Root.FlightAction:FireServer("loadout",draft);return end
     task.wait(.25)
    end
   end)
  end,
 })
 -- Paper screens drawn full-screen; anything not listed still uses the dark panel.
 local pauseScreen=PauseScreen.new(gui.Parent,{
  resume=function()overlay(false)end,
  hangar=function()Menu.show("hangar")end,
  settings=function()state.screen="settings";render()end,
  tutorial=function()Tutorial.choose(function()overlay(false)end)end, -- the Training board
  leave=function()if not Tutorial.quit() then action:FireServer("withdraw",true) end;overlay(false);home()end,
 })
 local shopScreen=ShopScreen.new(gui.Parent,{buy=function(key)action:FireServer("mockProduct",key)end,back=function()home()end})
 local waitScreen=WaitScreen.new(gui.Parent,{cancel=function()action:FireServer("withdraw",true)end})
 local paper={home=board,settings=settingsScreen,hangar=hangarScreen,pause=pauseScreen,shop=shopScreen,queued=waitScreen}
 -- Open a menu screen directly (the desk's Edit button, the menu buttons, Studio photo mode).
 function Menu.show(screen,fromDesk)
  if player:GetAttribute("InMatch") and not state.overlay then overlay(true) end
  if screen=="hangar" then hangarScreen.open() end
  state.screen=screen;state.fromDesk=fromDesk==true;action:FireServer("profile");render()
 end
-- Rounds never stop (Alan 2026-10-17): the round end plays out in the room (RoundEnd), so no menu opens by itself.
render=function()
  local inMatch=player:GetAttribute("InMatch")==true
  local snap=state.snapshot
  local queued=player:GetAttribute("JoinQueued")==true
  local open=not inMatch or state.overlay or queued
  openButton.Visible=inMatch and not open
  -- Which paper screen shows: waiting for a desk, round results, the in-match clipboard, or the chosen screen.
  local key=queued and "queued" or state.screen=="home" and (inMatch and "pause") or state.screen
  local current=open and paper[key]
  for _,screen in pairs(paper) do if screen~=current then screen.frame.Visible=false end end
  if current then current.update(player,state.profile,snap);current.frame.Visible=true end
 end
 -- Menu.pause: the Menu button's job, also for the Range's crosshair-as-cursor (RangeBoard).
 function Menu.pause() state.screen="home";overlay(true) end
 openButton.Activated:Connect(Menu.pause)
 Input.InputBegan:Connect(function(input,processed)
  if input.KeyCode==Enum.KeyCode.Tab and not Input:GetFocusedTextBox() and player:GetAttribute("InMatch") then state.screen="home";overlay(not state.overlay)
  elseif input.KeyCode==Enum.KeyCode.Escape and player:GetAttribute("InMatch") then state.screen="home";overlay(true) end
 end)
 GuiService.MenuOpened:Connect(function()if player:GetAttribute("InMatch") then overlay(true) end end)
 Root:WaitForChild("RoundView").OnClientEvent:Connect(function(snap)
  state.snapshot=snap
 end)
 Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
  state.profile=profile;Options.apply(profile.settings)
  render() -- screens skip the redraw themselves when nothing they show changed
 end)
 player:GetAttributeChangedSignal("InMatch"):Connect(function()state.screen="home";state.overlay=false;Root:SetAttribute("OverlayOpen",false);render()end)
 player:GetAttributeChangedSignal("ProfileStatus"):Connect(render)
 player:GetAttributeChangedSignal("JoinQueued"):Connect(render)
 player:GetAttributeChangedSignal("MenuMessage"):Connect(render)
 render();action:FireServer("profile")
 task.spawn(function()while gui.Parent do task.wait(3);action:FireServer("profile") end end)
end
return Menu
