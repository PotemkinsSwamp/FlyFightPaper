local Run=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Commerce=require(Root.Generated.Commerce)
local PresetCount=require(Root.Generated.Gameplay).menus.saved_loadouts
local Service={};Service.__index=Service
function Service.new(flight,profiles,commerce)
 return setmetatable({flight=flight,profiles=profiles,commerce=commerce,catalog=flight.catalog},Service)
end
function Service:message(player,text) player:SetAttribute("MenuMessage",text) end
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
 player:SetAttribute("SelectedPreset",slot)
 local p=self.flight.pilots[player]
 if p then p.testLoadout=nil end
end
function Service:enqueue(player,input,callback)
 if not self.profiles:enqueue(player,input,nil,callback) then self:message(player,"Saving is busy. Try again shortly.") end
end
function Service:handle(player,action,value)
 local profile=self.profiles:view(player);if not profile then return end
 if action=="selectPreset" then
  if type(value)~="number" or value%1~=0 or value<1 or value>PresetCount then return end
  self:select(player,value)
  self:message(player,self.flight.pilots[player] and ("Build "..value.." picked. Full refold at your desk flies it.") or ("Build "..value.." picked for your next flight."))
 elseif action=="savePreset" then
  if not slotOf(value) then return end
  local candidate=Schema.copy(profile);local preset=Schema.copy({name=profile.presets[value.slot].name,loadout=value.loadout}) -- renaming is its own action
  if not candidate or not preset then return end
  candidate.presets[value.slot]=preset
  local _,reason=self.catalog:validateLoadout(preset.loadout,profile.ownership,Economy.levelForXP(profile.xpMilli))
  if reason=="two weapon types per plane" then self:message(player,"Two weapon types per plane: one for left click, one for right click.");return end
  if not Schema.validate(candidate,self.catalog) then self:message(player,Run:IsStudio() and "Not saved: saving keeps only parts you own at your level. Use Fly this build to test any parts." or "Build refused. Check ownership, level, capacity and mount types.");return end
  self:enqueue(player,{kind="preset",slot=value.slot,name=preset.name,loadout=preset.loadout},function(ok)
   if not ok then self:message(player,"Build could not be saved.");return end
   self:select(player,value.slot)
   local p=self.flight.pilots[player]
   local atDesk=p and p.model and p.model:GetAttribute("State")=="DESK"
   if value.fly==true and atDesk and self.flight.onService then self:message(player,"Saved. Refolding it at your desk.");self.flight.onService(p,"refold")
   else self:message(player,not p and "Saved. You fly this build next." or atDesk and "Saved. Full refold at your desk flies it." or "Saved. Land at your desk to fly it.") end
  end)
 elseif action=="saveRangePreset" then
  -- The Range's own builds (TUTORIAL-PLAN "Range loadouts"): any part, still a legal plane; saving swaps your plane
  -- there at once.
  if not slotOf(value) or not profile.rangePresets then return end
  local loadout=Schema.copy(value.loadout)
  local ok,reason=loadout and self.catalog:validateLoadout(loadout,nil,1000000000)
  if not ok then self:message(player,reason=="two weapon types per plane" and "Two weapon types per plane: one for left click, one for right click." or "That plane can't be built. Check capacity and mount types.");return end
  self:enqueue(player,{kind="rangePreset",slot=value.slot,name=profile.rangePresets[value.slot].name,loadout=loadout},function(saved)
   if not saved then self:message(player,"Build could not be saved.");return end
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
  local settings=Schema.copy(value);local candidate=Schema.copy(profile)
  if not settings or not candidate then return end
  candidate.settings=settings
  if not Schema.validate(candidate,self.catalog) then return end
  self:enqueue(player,{kind="settings",settings=settings})
 elseif action=="buyProduct" and type(value)=="string" then
  if self.commerce then
   local ok=self.commerce:prompt(player,value)
   if not ok then self:message(player,"Shop is closed for now.") end
  end
 elseif action=="mockProduct" and Run:IsStudio() and self.profiles.mock==true and Commerce.mode=="mock" and Commerce.live_sales_authorized==false then
  if type(value)~="string" then return end
  local product
  for _,item in ipairs(Commerce.products) do if item.key==value then product=item;break end end
  if not product then return end
  local input
  if product.benefit=="paper_balance" then input={kind="purchasedPaper",wholePaper=product.amount}
  else
   local resource=product.benefit:find("xp") and "xp" or "paper"
   local permanent=product.benefit:find("permanent")~=nil
   local view=self.profiles.service:liveBoostView(self.profiles.entries[player].account)
   local boosts=view.status=="ok" and view.value.boosts or profile.boosts
   if not permanent and boosts[resource=="xp" and "permanentXP" or "permanentPaper"] then self:message(player,"Permanent 2x already covers this resource. Remaining temporary time is preserved.");return end
   input={kind="boostIntent",resource=resource,action=permanent and "permanent" or "duration"}
   if not permanent then input.seconds=product.amount end
  end
  self:enqueue(player,input,function(ok)self:message(player,ok and "Development simulation complete. No real purchase." or "Development simulation failed.")end)
 end
end
return Service
