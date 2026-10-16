local Run=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Commerce=require(Root.Generated.Commerce)
local PresetCount=require(Root.Generated.Gameplay).menus.saved_loadouts
local Service={};Service.__index=Service
function Service.new(flight,profiles)
 return setmetatable({flight=flight,profiles=profiles,catalog=flight.catalog},Service)
end
function Service:message(player,text) player:SetAttribute("MenuMessage",text) end
function Service:enqueue(player,input,callback)
 if not self.profiles:enqueue(player,input,nil,callback) then self:message(player,"Saving is busy. Try again shortly.") end
end
function Service:handle(player,action,value)
 local profile=self.profiles:view(player);if not profile then return end
 if action=="selectPreset" then
  if type(value)~="number" or value%1~=0 or value<1 or value>PresetCount then return end
  player:SetAttribute("SelectedPreset",value)
  local p=self.flight.pilots[player]
  if p then p.testLoadout=nil end
  self:message(player,p and "Preset selected. Use a fresh plane or full refold to apply it." or "Preset selected for your next launch.")
 elseif action=="savePreset" then
  if type(value)~="table" or type(value.slot)~="number" or value.slot%1~=0 or value.slot<1 or value.slot>PresetCount then return end
  local candidate=Schema.copy(profile);local preset=Schema.copy({name=value.name,loadout=value.loadout})
  if not candidate or not preset then return end
  candidate.presets[value.slot]=preset
  local _,reason=self.catalog:validateLoadout(preset.loadout,profile.ownership,Economy.levelForXP(profile.xpMilli))
  if reason=="two weapon types per plane" then self:message(player,"Two weapon types per plane: one for left click, one for right click.");return end
  if not Schema.validate(candidate,self.catalog) then self:message(player,Run:IsStudio() and "Not saved: saving keeps only parts you own at your level. Use Fly this build to test any parts." or "Build refused. Check ownership, level, capacity and mount types.");return end
  self:enqueue(player,{kind="preset",slot=value.slot,name=preset.name,loadout=preset.loadout},function(ok)
   self:message(player,ok and "Preset saved. Apply it with a fresh plane or full refold." or "Preset could not be saved.")
  end)
 elseif action=="purchasePart" then
  if type(value)~="string" or not self.catalog:get(value) then return end
  local legal,reason=Economy.validateEquipmentPurchase(Schema.economicView(profile),self.catalog,value,"preview")
  if not legal then self:message(player,reason.code=="level_locked" and "Reach the required level first." or "You need more Paper.");return end
  self:enqueue(player,{kind="equipmentPurchase",catalogID=value},function(ok)
   self:message(player,ok and "Part unlocked. You can use it on every legal mount." or "Part purchase was not completed.")
  end)
 elseif action=="settings" then
  local settings=Schema.copy(value);local candidate=Schema.copy(profile)
  if not settings or not candidate then return end
  candidate.settings=settings
  if not Schema.validate(candidate,self.catalog) then return end
  self:enqueue(player,{kind="settings",settings=settings})
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
