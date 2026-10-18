local Root=game.ReplicatedStorage.FlyFightPaper
local Rules=require(Root.Shared.ServiceRules)
local Config=require(Root.Generated.Gameplay).service
local Builder=require(Root.Shared.BuilderModel)
local Lines=require(Root.Shared.Lines)
local Service={};Service.__index=Service
function Service.new(flight,profiles)
 local self=setmetatable({flight=flight,profiles=profiles},Service)
 flight.onService=function(p,action) self:perform(p,action) end
 return self
end
function Service:valid(p,life)
 return self.flight.byId[p.id]==p and p.life==life and p.model:GetAttribute("State")=="DESK"
end
function Service:enqueue(p,input,callback)
 if self.profiles:enqueue(p.player,input,nil,callback) then return end
 task.spawn(function()
  while self.profiles.entries[p.player] do
   if self.profiles:enqueue(p.player,input,nil,callback) then return end
   task.wait(.25)
  end
  if callback then callback(false,"profile_unavailable") end
 end)
end
function Service:settle(p,intent,kind)
 self:enqueue(p,{kind=kind,intentId=intent},function(ok)
  if ok then self:enqueue(p,{kind="refoldRetire",intentId=intent}) end
 end)
end
function Service:perform(p,action)
 if p.serviceBusy or p.model:GetAttribute("State")~="DESK" then return end
 local life=p.life
 if action=="fresh" then self.flight:destroy(p,{kind="fresh"},"fresh");return end
 if action=="refill" or action=="repair" then
  p.serviceBusy=true;p.model:SetAttribute("ServiceBusy",true)
  p.model:SetAttribute("Message",Lines.pick(action=="refill" and "refilling" or "repairing"))
  task.delay(action=="refill" and Config.refill_seconds or Config.repair_seconds,function()
   if self:valid(p,life) then
    if action=="refill" then p.model:SetAttribute("Lift",p.stats.lift);p.model:SetAttribute("Boost",p.model:GetAttribute("BoostMax") or 0)
    else
     local repaired=assert(Rules.repair(p.stats.health,p.model:GetAttribute("MaxHealth"),p.model:GetAttribute("Health")))
     p.model:SetAttribute("Health",repaired.health);p.model:SetAttribute("MaxHealth",repaired.lifeMaxHealth)
     p.repairedAt=workspace:GetServerTimeNow() -- earlier damage no longer counts toward a fold or assist (Alan 2026-10-17)
    end
    p.model:SetAttribute("Message",Lines.pick("serviceDone"));p.model:SetAttribute("ServiceBusy",false)
   end
   p.serviceBusy=false
  end)
 elseif action=="refold" and p.player and p.identity then
  local profile=self.profiles:view(p.player)
  if not profile then return end
  local intent=self.profiles.service:operationID()
  local loadout=self.flight.selectedLoadout and self.flight.selectedLoadout(p.player) or p.loadout
  if Builder.equal(loadout,p.loadout) then p.model:SetAttribute("Message","You already fly this build. Pick another one, or Edit it first.");return end
  p.serviceBusy=true;p.model:SetAttribute("ServiceBusy",true);p.model:SetAttribute("Message",Lines.pick("refolding"))
  local fence={nonce=profile.lease.nonce,generation=profile.generation,actorId=p.id,lifeId=tostring(life),matchId=p.identity.matchId,
   participationId=p.id,padId=p.padKey or tostring(p.seat),sessionGeneration=profile.generation}
  local accepted=self.profiles:enqueue(p.player,{kind="refoldIntent",intentId=intent,fence=fence,loadout=loadout},nil,function(ok,reason)
   if not ok then
    if self:valid(p,life) then p.model:SetAttribute("Message",reason=="insufficient_paper" and "You need 120 Paper. Repair and fresh planes are free." or "Refold unavailable");p.model:SetAttribute("ServiceBusy",false) end
    p.serviceBusy=false;return
   end
   task.delay(Config.refold_seconds,function()
    if not self:valid(p,life) then
     self:settle(p,intent,"refoldCancel");p.serviceBusy=false;return
    end
    self:enqueue(p,{kind="refoldDeliver",intentId=intent},function(delivered)
     local applied=false
     if delivered and self:valid(p,life) then
      self.flight:refold(p,loadout)
      applied=true
      p.model:SetAttribute("Message",Lines.pick("refoldDone"))
     end
     if self:valid(p,life) then p.model:SetAttribute("ServiceBusy",false) end
     p.serviceBusy=false
     if delivered then
      self:settle(p,intent,applied and "refoldApplied" or "refoldRefund")
     end
    end)
   end)
  end)
  if not accepted then p.serviceBusy=false;p.model:SetAttribute("ServiceBusy",false);p.model:SetAttribute("Message","Saving is busy. Try refold again shortly; nothing was charged.") end
 end
end
return Service
