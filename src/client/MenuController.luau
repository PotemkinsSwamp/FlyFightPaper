local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Root=game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Hangar=require(script.Parent.Hangar)
local Options=require(script.Parent.Options)
local Tutorial=require(script.Parent.Tutorial)
local Loading=require(script.Parent.Loading)
local Board=require(script.Parent.MenuBoard)
local SettingsScreen=require(script.Parent.SettingsScreen)
local PauseScreen=require(script.Parent.PauseScreen)
local ShopScreen=require(script.Parent.ShopScreen)
local EmoteShop=require(script.Parent.EmoteShop)
local MissionsScreen=require(script.Parent.MissionsScreen)
local WaitScreen=require(script.Parent.WaitScreen)
local PaperUI=require(script.Parent.PaperUI)
local Unlock=require(script.Parent.UnlockMoment)
local GiftMoment=require(script.Parent.GiftMoment)
local ChestOpening=require(script.Parent.ChestOpening)
local Looks=require(Root.Shared.LooksRules)
local PlaneLooks=require(script.Parent.PlaneLooks)
local Menu={}
function Menu.start()
 local player=Players.LocalPlayer
 local action=Root:WaitForChild("RoundAction")
 local gui=Instance.new("ScreenGui");gui.Name="GameMenu";gui.DisplayOrder=6;gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
 local openButton=PaperUI.button(gui,"OpenMenu",require(Root.Shared.UIAssets).mainmenu.strip.yellow,"Menu",16,64,180,46,-2,function()end,28) -- 46 tall: a thumb-sized tap (44+); 180 wide: the strip's own shape
 openButton.Label.TextColor3=PaperUI.INK
 -- Up in Roblox's top bar, just right of Roblox's own buttons (Alan 2026-10-20: lower down it covered the Range Menu).
 local function dock()
  local bar=GuiService.TopbarInset
  if bar.Height>0 then openButton.Position=UDim2.fromOffset(bar.Min.X+10+openButton.Size.X.Offset/2,bar.Min.Y+bar.Height/2) end
 end
 dock();GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(dock)
 require(script.Parent.ScreenFit).inRow(openButton) -- the top row: notes stack under it
 local state={screen="home",snapshot=nil,profile=nil,overlay=false,lastPhase=nil}
 local render
 local function overlay(open)
  state.overlay=open
  if not open then state.under=nil end -- (Roblox's own menu also opens on Esc: that mustn't drop the Hangar underneath)
  Root:SetAttribute("OverlayOpen",open);action:FireServer("overlay",open)
  if render then render() end
 end
 local function home()
  state.screen,state.under="home",nil;state.fromDesk=false;render()
 end
 local board=Board.new(gui.Parent,{
  play=function()Loading.town(function()action:FireServer("join")end)end,
  hangar=function()Menu.show("hangar")end,
  settings=function()state.screen="settings";render()end,
  tutorial=function()Loading.town(function()Tutorial.choose(function()overlay(false)end)end)end, -- the Training board
  prestige=function()action:FireServer("prestige")end,
  shop=function()Menu.show("shop")end,
  missions=function()Menu.show("missions")end,
 })
 local settingsScreen=SettingsScreen.new(gui.Parent,{
  save=function(settings)action:FireServer("settings",settings);Options.apply(settings)end,
  back=function()home()end,
 })
 local hangarScreen
 hangarScreen=Hangar.new(gui.Parent,{
  action=action,
  shop=game:GetService("RunService"):IsStudio() and function()state.screen="shop";render()end or nil, -- "Get Paper" (Studio only, like the board's)
  -- Opened with Edit at the desk, Back (and Save & fly) go straight back to the desk.
  back=function()if state.fromDesk then home();overlay(false) else home() end end,
  flown=function()home();overlay(false)end,
  fly=function()Loading.town(function()
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
  end)end,
 })
 -- Paper screens drawn full-screen; anything not listed still uses the dark panel.
 -- Esc over the Hangar (Alan 2026-10-22): the pause menu opens on top of it (state.under), and Resume or Esc again
 -- goes back to the Hangar instead of the room.
 local function back() state.screen,state.under=state.under,nil;render() end
 local pauseScreen=PauseScreen.new(gui.Parent,{
  resume=function()if state.under then back() else overlay(false) end end,
  hangar=function()Menu.show("hangar")end,
  settings=function()state.screen="settings";render()end,
  tutorial=function()Tutorial.choose(function()overlay(false)end)end, -- the Training board
  leave=function()if not Tutorial.quit() then action:FireServer("withdraw",true) end;overlay(false);home()end,
 })
 local shopScreen=ShopScreen.new(gui.Parent,{action=action,buy=function(key)action:FireServer("mockProduct",key)end,claimGift=function()action:FireServer("claimDailyGift")end,
  emotes=function()state.screen="emotes";render()end, -- the Emotes page (docs/plan/EMOTE-SHOP-PLAN.md)
  back=function()home()end})
 -- Buying and putting on the winners' emotes; Back goes to the Shop it was opened from.
 local emoteScreen=EmoteShop.new(gui.Parent,{action=action,buy=function(key)action:FireServer("mockProduct",key)end,back=function()state.screen="shop";render()end})
 local waitScreen=WaitScreen.new(gui.Parent,{cancel=function()action:FireServer("withdraw",true)end})
 local missionsScreen=MissionsScreen.new(gui.Parent,{
  claim=function(list,index)action:FireServer("missionClaim",{list=list,index=index})end,
  swap=function(list,index)action:FireServer("missionSwap",{list=list,index=index})end,
  swapPrice=function(missions,list,index)return require(Root.Shared.Missions).swapPrice(missions,list,index)end,
  back=function()home()end})
 local paper={home=board,settings=settingsScreen,hangar=hangarScreen,pause=pauseScreen,shop=shopScreen,emotes=emoteScreen,queued=waitScreen,missions=missionsScreen}
 Unlock.start({
  seen=function(level)action:FireServer("unlocksSeen",level)end,
  seenLevel=function()return state.profile and state.profile.unlocksSeen or 0 end,
  open=function(slot)Menu.show("hangar",false,slot and "customize",slot)end, -- Put it on / See it: that part's tab
 })
 GiftMoment.start({seen=function(n)action:FireServer("giftSeen",n)end,board=board})
 -- Open a menu screen directly (the desk's Customize button, the menu buttons, Studio photo mode).
 -- page: which Hangar page to open on ("customize" = the binder).
 -- slot: a Customize tab to open on (the unlock card's Put it on / See it).
 function Menu.show(screen,fromDesk,page,slot)
  if player:GetAttribute("InMatch") and not state.overlay then overlay(true) end
  state.under=nil
  if screen=="hangar" then hangarScreen.open(page,slot) end
  if screen=="missions" and state.screen~="missions" then player:SetAttribute("MenuMessage",nil) end
  state.screen=screen;state.fromDesk=fromDesk==true;action:FireServer("profile");render()
  if screen=="shop" and page then shopScreen.jump(page) end -- page: a shop section ("Paper") or card ("PaperJar")
 end
-- Rounds never stop (Alan 2026-10-17): the round end plays out in the room (RoundEnd), so no menu opens by itself.
render=function()
  local inMatch=player:GetAttribute("InMatch")==true
  local snap=state.snapshot
  local queued=player:GetAttribute("JoinQueued")==true
  local open=(not inMatch and not Tutorial.arriving) or state.overlay or queued -- (arriving: the lesson opens instead)
  openButton.Visible=inMatch and not open and not Root:GetAttribute("LensCovered") -- (LensCovered: Book Kicker's book is on the lens, WinnersCutscene)
  -- Which paper screen shows: waiting for a desk, round results, the in-match clipboard, or the chosen screen.
  local key=queued and "queued" or state.screen=="home" and (inMatch and "pause") or state.screen
  local current=open and paper[key]
  local under=key=="pause" and state.under and paper[state.under] -- stays as it was, under the pause menu
  for _,screen in pairs(paper) do if screen~=current and screen~=under then screen.frame.Visible=false end end
  if current then current.update(player,state.profile,snap);current.frame.Visible=true end
  -- Things unlocked and not yet opened: the backpack when the main menu shows (Alan 2026-11-11: not the in-match menu).
  if current and key=="home" and #Unlock.waiting(state.profile)>0 and not Tutorial.arriving then Unlock.offer(state.profile) end
  -- A friend's gift: the plane brings it when the main menu shows (after the backpack).
  if current and key=="home" and not Tutorial.arriving and not Unlock.playing() then GiftMoment.offer() end
 end
 -- Menu.pause: the Menu button's job, also for the Range's crosshair-as-cursor (RangeBoard).
 function Menu.pause() state.screen="home";overlay(true) end
 local function escape()
  if state.under and state.screen=="home" then back()
  elseif state.overlay and state.screen=="hangar" then state.under,state.screen="hangar","home";render()
  else state.screen="home";overlay(true) end
 end
 openButton.Activated:Connect(Menu.pause)
 Input.InputBegan:Connect(function(input,processed)
  -- Tab shows the live standings over the game (RoundEnd); the Menu button and Esc open the menu (Alan 2026-11-06).
  if input.KeyCode==Enum.KeyCode.Tab and not Input:GetFocusedTextBox() and player:GetAttribute("InMatch") then
   if not state.overlay then Root:SetAttribute("StandingsOpen",not Root:GetAttribute("StandingsOpen") or nil) end
  elseif input.KeyCode==Enum.KeyCode.Escape and player:GetAttribute("InMatch") then escape() end
 end)
 GuiService.MenuOpened:Connect(function()if player:GetAttribute("InMatch") then overlay(true) end end)
 Root:WaitForChild("RoundView").OnClientEvent:Connect(function(snap)
  state.snapshot=snap
 end)
 Root:WaitForChild("ProfileView").OnClientEvent:Connect(function(profile)
  local previous=state.profile and state.profile.chests
  state.profile=profile;Options.apply(profile.settings)
  local wallet=profile.chests
  if previous and wallet and wallet.opened>previous.opened then
   local item,chest=Looks.item(wallet.lastSkin),Looks.chest(wallet.lastChest)
   if item and chest then
    ChestOpening.show(wallet.opened,chest,item,wallet.lastRefund,function(prize)
     if PlaneLooks.devSkin ~= nil then PlaneLooks.setDevSkin(nil) end
     if player:GetAttribute("DevTrail") ~= nil then player:SetAttribute("DevTrail", nil) end
     action:FireServer("wearLook",{kind=prize.kind,id=prize.id})
    end)
   end
  end
  render() -- screens skip the redraw themselves when nothing they show changed
 end)
 player:GetAttributeChangedSignal("InMatch"):Connect(function()if player:GetAttribute("InMatch") then Tutorial.arriving=false end;state.screen="home";state.overlay=false;Root:SetAttribute("OverlayOpen",false);render()end)
 -- (never stuck without a menu: if the lesson hasn't started in 20 s, the menu shows after all)
 if Tutorial.arriving then task.delay(20,function() if Tutorial.arriving then Tutorial.arriving=false;render() end end) end
 player:GetAttributeChangedSignal("ProfileStatus"):Connect(render)
 player:GetAttributeChangedSignal("JoinQueued"):Connect(render)
 player:GetAttributeChangedSignal("MenuMessage"):Connect(render)
 player:GetAttributeChangedSignal("Routing"):Connect(render)
 player:GetAttributeChangedSignal("GiftInbox"):Connect(render)
 Root:GetAttributeChangedSignal("LensCovered"):Connect(render)
 render();action:FireServer("profile")
 task.spawn(function()while gui.Parent do task.wait(3);action:FireServer("profile") end end)
end
return Menu
