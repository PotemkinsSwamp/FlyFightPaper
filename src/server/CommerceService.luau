-- Only server receipts grant products; only Roblox ownership grants passes.
-- Mock/unauthorized catalogs never even acquire MarketplaceService or bind events.
local Root=game.ReplicatedStorage.FlyFightPaper
local Rules=require(Root.Shared.CommerceRules)
local Profile=require(script.Parent.ProfileService)
local Service={};Service.__index=Service
local Decisions=Enum.ProductPurchaseDecision
local POLL_SECONDS=0.1
local SAVE_SECONDS=2

function Service.new(profiles,deps)
 deps=deps or {}
 local catalog,why=Rules.catalog(deps.config or require(Root.Generated.Commerce))
 local self=setmetatable({profiles=profiles,catalog=catalog,live=catalog~=nil and catalog.mode=="live" and catalog.authorized==true,
  wait=deps.wait or task.wait,now=deps.now or os.clock,timeoutSeconds=deps.timeoutSeconds or 20},Service)
 if not catalog then warn("Commerce disabled: "..tostring(why)) end
 if not self.live then return self end
 local parts=profiles.catalog or deps.catalog
 for _,offer in ipairs(catalog.offers) do
  if offer.benefit=="part_unlock" and (type(parts)~="table" or type(parts.get)~="function" or not parts:get(offer.catalogID)) then
   warn("Commerce disabled: unknown part "..tostring(offer.catalogID));self.live=false
   return self
  end
 end
 self.saveAfter=setmetatable({},{__mode="k"})
 self.marketplace=deps.marketplace or game:GetService("MarketplaceService")
 self.players=deps.players or game:GetService("Players")
 self.marketplace.ProcessReceipt=function(info)return self:processReceipt(info)end
 self.marketplace.PromptGamePassPurchaseFinished:Connect(function(player,_,purchased)
  if purchased then self:checkPasses(player) end
 end)
 local function joined(player)
  task.spawn(function()
   if self:_waitProfile(player) then self:checkPasses(player) end
  end)
 end
 self.players.PlayerAdded:Connect(joined)
 for _,player in ipairs(self.players:GetPlayers()) do joined(player) end
 return self
end

function Service:_waitProfile(player)
 local deadline=self.now()+self.timeoutSeconds
 while player.Parent do
  local view=self.profiles:view(player)
  if view then return view end
  if self.now()>=deadline then break end
  self.wait(POLL_SECONDS)
 end
 return nil
end

function Service:_processReceipt(info)
 local offer=self.catalog.byID[info.ProductId]
 if not offer or offer.kind~="developer_product" then
  warn("Receipt has an unknown developer product: "..tostring(info.ProductId))
  return Decisions.NotProcessedYet
 end
 -- Disabled offers still deliver payments that were already made.
 local player=self.players:GetPlayerByUserId(info.PlayerId)
 if not player or not self:_waitProfile(player) then return Decisions.NotProcessedYet end
 if type(info.PurchaseId)~="string" or #info.PurchaseId==0 then return Decisions.NotProcessedYet end
 local key=Profile.receiptKey(info.PurchaseId)
 local completed,granted,code=false,false,nil
 -- No source dedupe: ProfileRuntime suppresses callbacks for seen sources.
 -- Receipt IDs inside Profile.Data provide the durable dedupe instead.
 local queued=self.profiles:enqueue(player,{kind="receipt",receiptId=info.PurchaseId,grant=Rules.operation(offer)},nil,function(ok,value)
  granted=ok;code=value;completed=true
 end)
 if not queued then return Decisions.NotProcessedYet end
 local deadline=self.now()+self.timeoutSeconds
 while not completed and player.Parent and self.now()<deadline do self.wait(POLL_SECONDS) end
 if not completed then return Decisions.NotProcessedYet end
 if not granted then
  warn("Receipt grant refused: "..tostring(code))
  return Decisions.NotProcessedYet
 end
 local entry=self.profiles.entries[player]
 local profile=entry and entry.profile
 if not profile then return Decisions.NotProcessedYet end
 deadline=self.now()+self.timeoutSeconds
 while true do
  local saved=profile.LastSavedData
  if saved and saved.receiptIds and saved.receiptIds[key]==true then return Decisions.PurchaseGranted end
  if not profile:IsActive() or self.profiles.entries[player]~=entry or self.now()>=deadline then return Decisions.NotProcessedYet end
  -- Concurrent receipts share this cooldown for the same ProfileStore session.
  if self.now()>=(self.saveAfter[profile] or 0) then
   self.saveAfter[profile]=self.now()+SAVE_SECONDS
   profile:Save()
  end
  self.wait(POLL_SECONDS)
 end
end

function Service:processReceipt(info)
 if not self.live then return Decisions.NotProcessedYet end
 local ok,decision=pcall(self._processReceipt,self,info)
 if not ok then
  warn("Receipt processing failed: "..tostring(decision))
  return Decisions.NotProcessedYet
 end
 return decision
end

function Service:checkPasses(player)
 if not self.live then return false,"off" end
 if not player.Parent or not self.profiles:view(player) then return false,"profile_unavailable" end
 local allChecked=true
 for _,offer in ipairs(self.catalog.offers) do
  if offer.kind=="pass" and offer.productID then
   local ok,owned=pcall(function()return self.marketplace:UserOwnsGamePassAsync(player.UserId,offer.productID)end)
   if not ok then
    allChecked=false;warn("Pass ownership check failed: "..tostring(offer.key))
   elseif owned==true then
    -- The ownership call yields. Read again in case this session ended or another check granted it.
    local view=player.Parent and self.profiles:view(player)
    if view and not Rules.owned(offer,view.boosts) then
     if not self.profiles:enqueue(player,{kind="passGrant",resource=Rules.resource(offer)}) then
      allChecked=false;warn("Pass grant could not be queued: "..tostring(offer.key))
     end
    elseif not view then allChecked=false end
   end
  end
 end
 return allChecked,allChecked and "checked" or "pass_unavailable"
end

function Service:prompt(player,key)
 if not self.live then return false,"off" end
 local offer=type(key)=="string" and self.catalog.byKey[key]
 if not offer then return false,"unknown_offer" end
 if not offer.enabled then return false,"disabled" end
 if not offer.productID then return false,"unmapped" end
 local view=player.Parent and self.profiles:view(player)
 if not view then return false,"profile_unavailable" end
 if offer.benefit=="part_unlock" and view.ownership[offer.catalogID]==true then return false,"owned" end
 if Rules.owned(offer,view.boosts) then return false,offer.kind=="pass" and "owned" or "permanent_owned" end
 local ok=pcall(function()
  if offer.kind=="pass" then self.marketplace:PromptGamePassPurchase(player,offer.productID)
  else self.marketplace:PromptProductPurchase(player,offer.productID) end
 end)
 return ok,ok and "prompted" or "marketplace_error"
end
return Service
