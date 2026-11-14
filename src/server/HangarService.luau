local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Looks=require(Root.Shared.LooksRules)
local Commerce=require(Root.Generated.Commerce)
local EconomyConfig=require(Root.Generated.Economy)
local CommerceRules=require(Root.Shared.CommerceRules)
local PresetCount=require(Root.Generated.Gameplay).menus.saved_loadouts
local Service={};Service.__index=Service
function Service.new(flight,profiles,commerce,deps)
 deps=deps or {}
 return setmetatable({flight=flight,profiles=profiles,commerce=commerce,catalog=flight.catalog,unix=deps.unix or os.time,
  now=deps.now or os.clock,users=deps.users or game:GetService("UserService"),giftChecks=setmetatable({},{__mode="k"})},Service)
end
function Service:message(player,text) player:SetAttribute("MenuMessage",text) end
function Service:giftSelf()
 return Run:IsStudio() and self.profiles.mock==true and workspace:GetAttribute("DevGiftSelf")==true
end
function Service:giftCheck(player,friend)
 if not CommerceRules.positiveInteger(friend) then return nil end
 local state=self.giftChecks[player]
 if not state then state={results={}};self.giftChecks[player]=state end
 local now=self.now()
 for id,check in pairs(state.results) do if now-check.at>120 then state.results[id]=nil end end
 local result={id=friend,status="error",waiting=0,ownsXP=false,ownsPaper=false}
 local function finish(status)
  -- n: a new answer always changes the attribute (the client waits for that change). A busy answer never replaces a good one.
  state.n=(state.n or 0)+1;result.status,result.n=status,state.n
  if status~="busy" then state.results[friend]={at=self.now(),result=result} end
  player:SetAttribute("GiftCheck",Http:JSONEncode(result));return result
 end
 if state.checking or (state.at and now-state.at<2) then return finish("busy") end
 state.at=now
 state.checking=true
 local ok,status=pcall(function()
  if not self.profiles:view(player) or not self.profiles.store or (self.profiles.giftsReady and not self.profiles:giftsReady()) then return "busy" end
  if player.UserId==friend and not self:giftSelf() then return "self" end
  if not (player.UserId==friend and self:giftSelf()) and not player:IsFriendsWith(friend) then return "not_friend" end
  local view=self.profiles.store:GetAsync("Player_"..friend)
  if not view then return "not_played" end
  result.ownsXP=view.Data.boosts.permanentXP==true;result.ownsPaper=view.Data.boosts.permanentPaper==true
  for _,update in ipairs(view.global_updates) do
   local message=type(update)=="table" and update[#update]
   if type(message)=="table" and message.kind=="gift" then result.waiting+=1 end
  end
  return result.waiting>=10 and "full" or "ok"
 end)
 state.checking=false
 return finish(ok and status or "error")
end
function Service:giftName(friend)
 local ok,infos=pcall(function()return self.users:GetUserInfosByUserIdsAsync({friend})end)
 local name=ok and type(infos)=="table" and infos[1] and infos[1].DisplayName
 return type(name)=="string" and #name>0 and name or "Your friend"
end
function Service:buyGift(player,value)
 if type(value)~="table" or not CommerceRules.giftable(value.key) then self:message(player,"That can't be gifted.");return end
 local friend,key=value.friend,value.key
 if not CommerceRules.positiveInteger(friend) then self:message(player,"Gifts are busy. Try again shortly.");return end
 local state=self.giftChecks[player];local check=state and state.results[friend]
 local result=check and self.now()-check.at<=120 and check.result or self:giftCheck(player,friend)
 local status=result and result.status or "error"
 if friend==player.UserId and not self:giftSelf() then status="self" end
 local name=self:giftName(friend)
 if status~="ok" then
  self:message(player,status=="not_played" and name.." hasn't played yet. Invite them first!"
   or status=="full" and name.." has 10 gifts waiting! Try again after they play."
   or (status=="not_friend" or status=="self") and "You can only send gifts to friends."
   or "Gifts are busy. Try again shortly.");return
 end
 local grant=CommerceRules.giftGrant(key)
 if grant.kind=="boostIntent" and (grant.resource=="xp" and result.ownsXP or grant.resource=="paper" and result.ownsPaper) then
  self:message(player,name.." already has 2x "..(grant.resource=="xp" and "XP" or "Paper").." forever.");return
 end
 if not self.profiles:view(player) or (self.profiles.giftsReady and not self.profiles:giftsReady()) then self:message(player,"Gifts are busy. Try again shortly.");return end
 if Run:IsStudio() and self.profiles.mock==true and Commerce.mode=="mock" and Commerce.live_sales_authorized==false then
  local id="mock:"..Http:GenerateGUID(false)
  local ok,sent=pcall(function()return self.profiles.store:MessageAsync("Player_"..friend,{kind="gift",giftId=id,from=player.UserId,fromName=player.DisplayName,key=key})end)
  if not ok or not sent then self:message(player,"Gifts are busy. Try again shortly.");return end
  if not self.profiles:enqueue(player,{kind="receipt",receiptId=id,grant={kind="giftSent"}},nil,function(applied)
   self:message(player,applied and "Sent! (practice gift, no real purchase)" or "Gifts are busy. Try again shortly.")
  end) then self:message(player,"Gifts are busy. Try again shortly.") end
 elseif self.commerce then
  self.commerce:rememberGift(player,friend,name,key)
  if not self.commerce:prompt(player,"gift_"..key) then self:message(player,"Shop is closed for now.") end
 else self:message(player,"Shop is closed for now.") end
end
-- Player-typed names go through Roblox's text filter (shown only to their owner); a failed filter keeps the fallback.
local NAME_MAX=20
local function filtered(player,name,fallback)
 if type(name)~="string" or name=="" or not utf8.len(name) or utf8.len(name)>NAME_MAX or name:find("%c") then return fallback end
 local ok,text=pcall(function() return game:GetService("TextService"):FilterStringAsync(name,player.UserId):GetNonChatStringForUserAsync(player.UserId) end)
 return ok and text~="" and text or fallback
end
local function slotOf(value) return type(value)=="table" and type(value.slot)=="number" and value.slot%1==0 and value.slot>=1 and value.slot<=PresetCount end
-- The picked build is the one the next refold or fresh plane flies; picking one ends a Studio test build.
function Service:select(player,slot)
 player:SetAttribute("SelectedPreset",slot);player:SetAttribute("SelectedClass",nil)
 local p=self.flight.pilots[player]
 if p then p.testLoadout=nil end
end
-- Says what happens to the plane just picked, swapping it onto the desk when that's free.
function Service:picked(player,name)
 local p=self.flight.pilots[player]
 if p and self.flight:swapAtDesk(p) then self:message(player,name.." is on your desk.")
 elseif p then self:message(player,name.." picked. Fresh plane or Full refold flies it.")
 else self:message(player,name.." picked for your next flight.") end
end
function Service:enqueue(player,input,callback)
 if not self.profiles:enqueue(player,input,nil,callback) then self:message(player,"Saving is busy. Try again shortly.") end
end
function Service:doubleMatch(player,match)
 if player:GetAttribute("MatchDoubled")==match.matchId then self:message(player,"You already doubled this match.");return end
 local price=CommerceRules.matchDoublePrice(match.paper);if not price then return end
 local key="match_double_"..price
 local lock={kind="doubleLock",key=key,matchId=match.matchId,paper=match.paper,xp=match.xp}
 if Run:IsStudio() and self.profiles.mock==true and Commerce.mode=="mock" and Commerce.live_sales_authorized==false then
  player:SetAttribute("MatchDoubled",match.matchId)
  local function completed(ok)
   if not ok then player:SetAttribute("MatchDoubled",nil) end
   self:message(player,ok and "Development simulation complete. No real purchase." or "Development simulation failed.")
  end
  if not self.profiles:enqueue(player,lock,nil,function(ok)
   if not ok then completed(false);return end
   if not self.profiles:enqueue(player,{kind="matchDouble",key=key},nil,completed) then completed(false) end
  end) then completed(false) end
 elseif self.commerce then
  local function locked(ok)
   if not ok then self:message(player,"Saving is busy. Try again shortly.");return end
   if not self.commerce:prompt(player,key) then self:message(player,"Shop is closed for now.") end
  end
  if not self.profiles:enqueue(player,lock,nil,locked) then locked(false) end
 else self:message(player,"Shop is closed for now.") end
end
function Service:handle(player,action,value)
 if action=="giftCheck" then self:giftCheck(player,value);return end
 if action=="buyGift" then self:buyGift(player,value);return end
 if action=="giftSeen" then self.profiles:giftSeen(player,value);return end
 local profile=self.profiles:view(player);if not profile then return end
 if action=="selectPreset" then
  if type(value)~="number" or value%1~=0 or value<1 or value>PresetCount then return end
  self:select(player,value)
  self:picked(player,"Loadout "..value)
 elseif action=="selectClass" then
  local class=self.catalog:classById(value)
  if not class then return end
  if not self.catalog:classLoadout(value,Economy.levelForXP(profile.xpMilli)) then self:message(player,class.name.." opens at level "..class.min_level..".");return end
  player:SetAttribute("SelectedClass",value)
  local p=self.flight.pilots[player]
  if p then p.testLoadout=nil end
  self:picked(player,class.name)
 elseif action=="savePreset" then
  if not slotOf(value) then return end
  local candidate=Schema.copy(profile);local preset=Schema.copy({name=profile.presets[value.slot].name,loadout=value.loadout}) -- renaming is its own action
  if not candidate or not preset then return end
  candidate.presets[value.slot]=preset
  local _,reason=self.catalog:validateLoadout(preset.loadout,profile.ownership,Economy.levelForXP(profile.xpMilli))
  if reason=="two weapon types per plane" then self:message(player,"Two weapon types per plane: one for left click, one for right click.");return end
  if not Schema.validate(candidate,self.catalog) then self:message(player,Run:IsStudio() and "Not saved: saving keeps only parts you own at your level. Use Fly this build to test any parts." or "Build refused. Check ownership, level, capacity and mount types.");return end
  self:enqueue(player,{kind="preset",slot=value.slot,name=preset.name,loadout=preset.loadout},function(ok)
   if not ok then self:message(player,"Loadout could not be saved.");return end
   self:select(player,value.slot)
   local p=self.flight.pilots[player]
   local atDesk=p and p.model and p.model:GetAttribute("State")=="DESK"
   if p and self.flight:swapAtDesk(p) then self:message(player,"Saved. It's on your desk.")
   elseif value.fly==true and atDesk and self.flight.onService then self:message(player,"Saved. Refolding it at your desk.");self.flight.onService(p,"refold")
   else self:message(player,not p and "Saved. You fly this loadout next." or atDesk and "Saved. Fresh plane or Full refold flies it." or "Saved. Land at your desk to fly it.") end
  end)
 elseif action=="saveRangePreset" then
  -- The Range's own builds (TUTORIAL-PLAN "Range loadouts"): any part, still a legal plane; saving swaps your plane
  -- there at once.
  if not slotOf(value) or not profile.rangePresets then return end
  local loadout=Schema.copy(value.loadout)
  local ok,reason=loadout and self.catalog:validateLoadout(loadout,nil,1000000000)
  if not ok then self:message(player,reason=="two weapon types per plane" and "Two weapon types per plane: one for left click, one for right click." or "That plane can't be built. Check capacity and mount types.");return end
  self:enqueue(player,{kind="rangePreset",slot=value.slot,name=profile.rangePresets[value.slot].name,loadout=loadout},function(saved)
   if not saved then self:message(player,"Loadout could not be saved.");return end
   local p=self.flight.pilots[player]
   if p and p.pin then
    player:SetAttribute("RangeSlot",value.slot);self.flight:refold(p,loadout)
    self:enqueue(player,{kind="rangeSlot",slot=value.slot})
    self:message(player,"Saved. You're flying it now.")
   else self:message(player,"Saved.") end
  end)
 elseif action=="renamePreset" then
  if not slotOf(value) then return end
  local list=value.range==true and profile.rangePresets or profile.presets
  local entry=list and list[value.slot]
  local name=entry and filtered(player,value.name,nil)
  if not name then self:message(player,"Names are 1 to "..NAME_MAX.." letters.");return end
  self:enqueue(player,{kind=value.range==true and "rangePreset" or "preset",slot=value.slot,name=name,loadout=entry.loadout},function(saved)
   self:message(player,saved and ("Renamed to "..name..".") or "Name could not be saved.")
  end)
 elseif action=="purchasePart" then
  if type(value)~="string" or not self.catalog:get(value) then return end
  local legal,reason=Economy.validateEquipmentPurchase(Schema.economicView(profile),self.catalog,value,"preview")
  if not legal then self:message(player,reason.code=="level_locked" and "Reach the required level first." or "You need more Paper.");return end
  self:enqueue(player,{kind="equipmentPurchase",catalogID=value},function(ok)
   self:message(player,ok and "Part unlocked. You can use it on every legal mount." or "Part purchase was not completed.")
  end)
 elseif action=="buyLook" then
  if type(value)~="string" or #value>160 then return end
  local legal,reason=Looks.buyWithPaper(Schema.economicView(profile),value,"preview")
  if legal and legal.operation.alreadyOwned then self:message(player,"You already own it.");return end
  if not legal then
   self:message(player,reason.code=="insufficient_paper" and "You need more Paper." or reason.code=="not_sold" and "That trail comes with its skin." or "That can't be bought.")
   return
  end
  local item=Looks.item(value)
  self:enqueue(player,{kind="lookPurchase",lookID=value},function(ok)
   self:message(player,ok and item.name.." is yours! Wear it from the Skins tab." or "The buy was not completed. Nothing changed.")
  end)
 elseif action=="wearLook" then
  if type(value)~="table" or getmetatable(value)~=nil or type(value.skin)~="string" or #value.skin>160 or type(value.trail)~="string" or #value.trail>160 then return end
  for field in pairs(value) do if field~="skin" and field~="trail" then return end end
  local skinID,trailID=value.skin,value.trail
  if not Looks.wear(Schema.economicView(profile),skinID,trailID,"preview") then self:message(player,"You don't own that yet.");return end
  self:enqueue(player,{kind="lookWear",skinID=skinID,trailID=trailID},function(ok)
   if not ok then return end
   local p=self.flight.pilots[player]
   if p then
    p.skin,p.trail=skinID~="" and skinID or nil,trailID~="" and trailID or nil
    if p.model then p.model:SetAttribute("Skin",p.skin);p.model:SetAttribute("Trail",p.trail) end
   end
  end)
 elseif action=="prestige" then
  -- From the menus only (docs/systems/economy-and-shop.md "Prestige"); the save rules re-check everything.
  if player:GetAttribute("InMatch") then self:message(player,"Prestige from the main menu.");return end
  local view=assert(Schema.copy(Schema.economicView(profile)))
  view.prestige,view.presets,view.refolds=profile.prestige,profile.presets,profile.refolds
  local legal,reason=Economy.prestige(view,self.catalog,"preview")
  if not legal then
   self:message(player,reason.code=="refold_pending" and "Finish your refold first." or reason.code=="prestige_max" and "You're at the top prestige rank." or "Reach the top level first.")
   return
  end
  self:enqueue(player,{kind="prestige"},function(ok)
   self:message(player,ok and "Prestige! Your new rank star is on your level bar." or "Prestige was not completed. Nothing changed.")
  end)
 elseif action=="settings" then
  local settings,why=Schema.copy(value);local candidate=Schema.copy(profile);local valid=settings and candidate
  if valid then candidate.settings=settings;valid,why=Schema.validate(candidate,self.catalog) end
  if not valid then warn("Settings refused for player "..player.UserId..": "..tostring(why));self:message(player,"Settings could not be saved.");return end
  self:enqueue(player,{kind="settings",settings=settings},function(saved) if not saved then self:message(player,"Settings could not be saved.") end end)
 elseif action=="claimDailyGift" then
  -- The client supplies no date or reward. Queued claims re-check the saved day.
  self:enqueue(player,{kind="dailyGift",day=math.floor(self.unix()/86400)},function(ok,result)
   if not ok then
    self:message(player,result=="daily_gift_claimed" and "Already claimed today. Come back tomorrow." or "Gift could not be claimed. Try again shortly.")
   elseif result.paper then self:message(player,"Gift claimed: +"..result.paper.." Paper.")
   else self:message(player,"Gift claimed: "..string.format("%d",result.seconds/60).." minutes of 2x "..(result.resource=="xp" and "XP" or "Paper")..".") end
  end)
 elseif action=="buyProduct" and type(value)=="string" then
  if CommerceRules.giftBase(value) then self:message(player,"That can't be gifted.");return end
  if value=="starter_pack" and CommerceRules.starterPackEnds(profile,self.unix())==0 then self:message(player,"The starter pack has ended.");return end
  if value=="paper_jar" and profile.paperJarMilli<EconomyConfig.paper_jar.min_break_paper*Economy.MILLI then self:message(player,"Your Paper jar breaks at 3,000 Paper. Play a match to fill it.");return end
  if self.commerce then
   local ok,why=self.commerce:prompt(player,value)
   if not ok then self:message(player,why=="starter_pack_ended" and "The starter pack has ended." or why=="jar_low" and "Your Paper jar breaks at 3,000 Paper. Play a match to fill it." or "Shop is closed for now.") end
  end
 elseif action=="devAll" and Run:IsStudio() and self.profiles.mock==true and player:GetAttribute("Dev")==true then
  self.profiles:devSwitch(player) -- Alan's Studio-only button: his level account <-> everything unlocked
 elseif action=="mockProduct" and Run:IsStudio() and self.profiles.mock==true and Commerce.mode=="mock" and Commerce.live_sales_authorized==false then
  if type(value)~="string" or value:match("^match_double_") or CommerceRules.giftBase(value) then return end
  local product
  for _,item in ipairs(Commerce.products) do if item.key==value then product=item;break end end
  if not product then return end
  local input
  if product.benefit=="paper_balance" then input={kind="purchasedPaper",wholePaper=product.amount,packKey=product.key}
  elseif product.benefit=="starter_pack" then
   if CommerceRules.starterPackEnds(profile,self.unix())==0 then self:message(player,"The starter pack has ended.");return end
   input={kind="starterPack"}
  elseif product.benefit=="paper_jar" then
   if profile.paperJarMilli<EconomyConfig.paper_jar.min_break_paper*Economy.MILLI then self:message(player,"Your Paper jar breaks at 3,000 Paper. Play a match to fill it.");return end
   input={kind="paperJar"}
  elseif product.benefit=="part_unlock" then
   self:message(player,"Part checkout is unavailable in the practice shop.");return
  elseif product.benefit=="look_unlock" then
   self:message(player,"Skin and trail checkout is unavailable in the practice shop.");return
  else
   local resource=product.benefit:find("xp") and "xp" or "paper"
   local permanent=product.benefit:find("permanent")~=nil
   local view=self.profiles.service:liveBoostView(self.profiles.entries[player].account)
   local boosts=view.status=="ok" and view.value.boosts or profile.boosts
   if boosts[resource=="xp" and "permanentXP" or "permanentPaper"] then self:message(player,"Permanent 2x already covers this resource. Remaining temporary time is preserved.");return end
   input={kind="boostIntent",resource=resource,action=permanent and "permanent" or "duration"}
   if not permanent then input.seconds=product.amount end
  end
  self:enqueue(player,input,function(ok,result)self:message(player,ok and "Development simulation complete. No real purchase." or result=="jar_low" and "Your Paper jar breaks at 3,000 Paper. Play a match to fill it." or "Development simulation failed.")end)
 end
end
return Service
