-- ProfileStore owns persistence and session locking. Operations below never yield.
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Looks=require(Root.Shared.LooksRules)
local Emotes=require(Root.Shared.EmoteRules)
local Missions=require(Root.Shared.Missions)
local MissionConfig=require(Root.Generated.Missions)
local Commerce=require(Root.Shared.CommerceRules)
local EconomyConfig=require(Root.Generated.Economy)
local BoostClock=require(Root.Shared.BoostClock)
local Gameplay=require(Root.Generated.Gameplay)
local ServerConfig=require(Root.Generated.Server)
local Config=ServerConfig.profiles
local Service={};Service.__index=Service
local function outcome(status,code,value) return {status=status,code=code,value=value} end
local function count(t) local n=0;for _ in pairs(t) do n+=1 end;return n end
function Service.receiptKey(purchaseId)
 if type(purchaseId)~="string" then return nil end
 local key="r_"..purchaseId
 if Schema.id(key) then return key end
 -- FNV-1a 64-bit, non-cryptographic. Split the prime (2^40 + 435) into
 -- two 32-bit halves so every intermediate stays exact in Luau's doubles.
 local high,low=0xcbf29ce4,0x84222325
 for i=1,#purchaseId do
  low=bit32.bxor(low,string.byte(purchaseId,i))
  local product=low*435
  high=(high*435+math.floor(product/4294967296)+low*256)%4294967296
  low=product%4294967296
 end
 return "h_"..string.format("%08x%08x",high,low)
end
local function validReceiptGrant(grant)
 if type(grant)~="table" then return false end
 local fields
 if grant.kind=="purchasedPaper" then
  if not Schema.integer(grant.wholePaper) or grant.wholePaper<1 then return false end
  if grant.packKey~=nil and Commerce.paperPackAmount(grant.packKey)~=grant.wholePaper then return false end
  fields={kind=true,wholePaper=true,packKey=true}
 elseif grant.kind=="paidChest" then
  if type(grant.chest)~="string" or not Looks.chest(grant.chest) then return false end
  fields={kind=true,chest=true}
 elseif grant.kind=="starterPack" or grant.kind=="paperJar" or grant.kind=="giftSent" then
  fields={kind=true}
 elseif grant.kind=="matchDouble" then
  if not Commerce.isMatchDoubleKey(grant.key) then return false end
  fields={kind=true,key=true}
 elseif grant.kind=="boostIntent" then
  if (grant.resource~="xp" and grant.resource~="paper") or grant.action~="duration"
   or not Schema.integer(grant.seconds) or grant.seconds<1 then return false end
  fields={kind=true,resource=true,action=true,seconds=true}
 elseif grant.kind=="partUnlock" then
  if type(grant.catalogID)~="string" or #grant.catalogID==0 then return false end
  fields={kind=true,catalogID=true}
 elseif grant.kind=="lookUnlock" then
  if type(grant.lookID)~="string" or #grant.lookID==0 then return false end
  fields={kind=true,lookID=true}
 elseif grant.kind=="emoteUnlock" then
  if not Emotes.price(grant.emoteID) then return false end
  fields={kind=true,emoteID=true}
 else return false end
 for key in pairs(grant) do if not fields[key] then return false end end
 return true
end
function Service.new(options)
 return setmetatable({catalog=options.catalog,mono=options.monotonic or os.clock,unix=options.unix or os.time,
  policyInfo=options.policyInfo or function(player) return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player) end,
  random=options.random or math.random,missionWarnings={},mock=Run:IsStudio() and options.mock==true,sessions={}},Service)
end
function Service:operationID() return Http:GenerateGUID(false):gsub("%-",""):sub(1,24) end
function Service:attach(account,profile,availability)
 if self.sessions[account] then return outcome("error","already_loaded") end
 if not profile:IsActive() then return outcome("error","session_lost") end
 local data,why=Schema.migrate(profile.Data,self.catalog)
 if not data then return outcome("error",why) end
 if data.starterPack.offeredAt==0 then
  local now=self.unix()
  if not Schema.integer(now) or now==0 then return outcome("error","invalid_time") end
  data.starterPack.offeredAt=now
 end
 -- An old plane cannot survive a server hop. Reserved but unused Paper returns once.
 for _,intent in pairs(data.refolds or {}) do
  if intent.state=="reserved" or intent.state=="delivered" then
   if data.paperMilli>Economy.MAX_SAFE_INTEGER-intent.costMilli then return outcome("error","overflow") end
   data.paperMilli+=intent.costMilli
  end
 end
 if data.generation>=Economy.MAX_SAFE_INTEGER then return outcome("error","generation_overflow") end
 data.refolds={};data.generation+=1
 local token=self:operationID()
 table.insert(data.operationSessions,token);data.operationIds[token]=0
 if #data.operationSessions>Config.session_id_history then data.operationIds[table.remove(data.operationSessions,1)]=nil end
 local connected=availability.connected==true;local mapLoaded=availability.mapLoaded==true
 self.sessions[account]={profile=profile,token=token,sequence=0,connected=connected,mapLoaded=mapLoaded,
  clock=BoostClock.new(data.boosts,self.mono(),connected and mapLoaded,{historyLimit=Config.boost_history_limit}),results={},resultOrder={}}
 profile.Data=data
 return self:view(account)
end
function Service:_session(account)
 local s=self.sessions[account]
 if s and s.profile:IsActive() then return s end
 return nil
end
-- Resolve outside the transaction. Missing information keeps Paper purchases closed.
function Service:chestPaperAllowed(account,player)
 local s=self:_session(account)
 if not s then return false end
 if s.chestPaperAllowed~=nil then return s.chestPaperAllowed end
 if not s.checkingPolicy and self.mono()>=(s.retryPolicyAt or 0) then
  s.checkingPolicy=true
  task.spawn(function()
   local ok,policy=pcall(self.policyInfo,player)
   if self:_session(account)~=s then return end
   s.checkingPolicy=false
   if ok and type(policy)=="table" and type(policy.ArePaidRandomItemsRestricted)=="boolean" then
    s.chestPaperAllowed=not policy.ArePaidRandomItemsRestricted
   else
    s.retryPolicyAt=self.mono()+60
   end
  end)
 end
 return s.chestPaperAllowed==true
end
function Service:_advance(s)
 local ok,why=s.clock:advance(self.mono(),s.connected and s.mapLoaded)
 if not ok then return false,why end
 s.profile.Data.boosts=assert(Schema.copy(s.clock:snapshot()))
 return true
end
function Service:view(account,refreshMissions)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 if refreshMissions then
  local data=table.clone(s.profile.Data)
  local refreshed,err,_,changed=self:_refreshMissions(data,self.unix(),tonumber(account) or 0,"mission_refresh")
  if not refreshed then return outcome("error",err) end
  if changed then
   data.version+=1
   local valid,validation=Schema.validate(data,self.catalog)
   if not valid then return outcome("error",validation) end
   s.profile.Data=valid
  end
 end
 local data=assert(Schema.copy(s.profile.Data))
 -- Compatibility for desk life checks. This is a session token, not a storage lock.
 data.lease={nonce=s.token,generation=data.generation,expires=0}
 return outcome("ok",nil,Schema.freeze(data))
end
function Service:prepare(account,input)
 local s=self:_session(account);if not s then return nil end
 local op=Schema.copyOperation(input);if not op then return nil end
 s.sequence+=1;op.id=s.token..":"..s.sequence
 return op
end
function Service:setProducerConnected(account,connected)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 s.connected=connected==true;assert(s.clock:advance(self.mono(),s.connected and s.mapLoaded))
 return outcome("ok")
end
function Service:setProducerMapLoaded(account,loaded)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 s.mapLoaded=loaded==true;assert(s.clock:advance(self.mono(),s.connected and s.mapLoaded))
 return outcome("ok")
end
function Service:producerCapture(account,at)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 local capture,err
 if at and at<s.clock.now then capture,err=s.clock:multipliersAt(at)
 else
  local b=s.clock:snapshot()
  capture={paper=(b.permanentPaper or b.paperSeconds>0) and 2 or 1,xp=(b.permanentXP or b.xpSeconds>0) and 2 or 1,at=s.clock.now,revision=s.clock.revision}
 end
 return outcome(capture and "ok" or "error",err,capture)
end
function Service:liveBoostView(account)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 return outcome("ok",nil,{boosts=s.clock:snapshot()})
end
function Service:detach(account)
 local s=self:_session(account)
 if s then self:_advance(s) end
 self.sessions[account]=nil
end
local function safeAdd(a,b) if not Schema.integer(b) or a>Economy.MAX_SAFE_INTEGER-b then return nil end; return a+b end
local function giftReward(p,day)
 if not Schema.integer(day) then return nil,"invalid_daily_gift_day" end
 if day<=p.dailyGift.lastDay then return nil,"daily_gift_claimed" end
 local reward=Commerce.dailyGiftReward(Commerce.dailyGiftDay(p.dailyGift,day))
 if (reward.xp_seconds and p.boosts.permanentXP) or (reward.paper_seconds and p.boosts.permanentPaper) then
  return {paper=EconomyConfig.daily_gift.boost_covered_paper}
 end
 return reward
end
function Service:_recordBuy(p)
 local now=self.unix();if not Schema.integer(now) then return nil,"invalid_time" end
 local day=math.floor(now/86400)
 local value=safeAdd(p.buysToday.day==day and p.buysToday.count or 0,1)
 if not value then return nil,"overflow" end
 p.buysToday={day=day,count=value}
 return true
end
local function payMissionReward(p,reward,operationID)
 local paid
 if reward.paper or reward.xp then
  local rejected
  paid,rejected=Economy.applyFinalBonuses(Schema.economicView(p),
   {finalPaper=reward.paper or 0,finalXP=reward.xp or 0},{paper=1,xp=1},operationID)
  if not paid then return nil,rejected.code end
 end
 local stock=table.clone(p.chests.stock)
 for _,id in {"sticker","blue_ribbon"} do
  if reward[id] then
   local total=safeAdd(stock[id],reward[id])
   if not total then return nil,"overflow" end
   stock[id]=total
  end
 end
 if paid then Schema.mergeEconomic(p,paid.profile) end
 p.chests=table.clone(p.chests)
 p.chests.stock=stock
 return true
end

function Service:_refreshMissions(p,now,seed,operationID)
 local level=assert(Economy.levelForXP(p.xpMilli))
 local owned={}
 for id in pairs(self.catalog.byId) do
  if self.catalog:owns(p.ownership,id,level) then table.insert(owned,id) end
 end
 local state,rewards,changed=Missions.refresh(p.missions,now,owned,seed)
 if not state then
  if rewards=="stale_period" then return true,nil,owned,false end
  return nil,rewards
 end
 if changed then
  for _,reward in rewards do
   local paid,err=payMissionReward(p,reward,operationID)
   if not paid then return nil,err end
  end
  p.missions=state
 end
 return true,nil,owned,changed
end

function Service:_missionAction(p,op,seed)
 local refreshed,err,owned,changed=self:_refreshMissions(p,self.unix(),seed,op.id)
 if not refreshed then return nil,err end
 local function refuse(code,shortfall)
  -- A rollover can pay an old completed card even if the new card can't be claimed or swapped.
  if changed then return {type="MissionRefused",code=code,shortfall=shortfall} end
  return nil,code,shortfall and {shortfall=shortfall}
 end
 if op.kind=="missionClaim" then
  local claimed,reward=Missions.claim(p.missions,op.list,op.index)
  if not claimed then return refuse(reward) end
  local paid,why=payMissionReward(p,reward,op.id)
  if not paid then return refuse(why) end
  p.missions=claimed
  return {type="MissionClaimed",reward=reward}
 elseif op.kind=="missionSwap" then
  local price,why=Missions.swapPrice(p.missions,op.list,op.index)
  if price==nil then return refuse(why) end
  local cost=price*Economy.MILLI
  if not Schema.integer(cost) then return refuse("invalid_mission_price") end
  if p.paperMilli<cost then return refuse("not_enough_paper",math.ceil((cost-p.paperMilli)/Economy.MILLI)) end
  local swapped,reason=Missions.swap(p.missions,op.list,op.index,owned,seed)
  if not swapped then return refuse(reason) end
  p.missions=swapped
  p.paperMilli-=cost
  return {type="MissionSwapped",price=price}
 end
 local finished=table.clone(p.missions)
 for _,list in {"daily","weekly"} do
  finished[list]={}
  for index,mission in p.missions[list] do
   local copy=table.clone(mission)
   copy.progress=Missions.goal(copy)
   finished[list][index]=copy
  end
 end
 finished.dailiesDone=MissionConfig.fixed.target
 p.missions=finished
 return {type="DevMissionsFinished"}
end

function Service:_matchMissions(p,op,seed)
 local summary=op.missions
 if type(summary)~="table" or type(summary.eligible)~="boolean" then return nil,"invalid_match_summary" end
 local dev=op.devMission==true and self.mock -- Studio's "Dev: mission next match"
 if not summary.eligible and not dev then return nil,"ineligible_match" end
 local candidate=table.clone(p)
 local refreshed,err=self:_refreshMissions(candidate,summary.completedAt,seed,op.id)
 if not refreshed then return nil,err end
 local progressed,finished=Missions.applyMatch(candidate.missions,summary)
 if not progressed then return nil,finished end
 if dev then
  -- ponytail: finishes the first open mission (daily, else weekly) without the week calendar or the 15-dailies count;
  -- it only has to make the report card's tick slip show, so with every mission already done it reports the first daily.
  local open
  for _,list in {"daily","weekly"} do
   for _,mission in progressed[list] do
    if not open and mission.progress<Missions.goal(mission) then open=mission end
   end
  end
  if open then open.progress=Missions.goal(open) end
  open=open or progressed.daily[1]
  if open and #finished==0 then table.insert(finished,table.clone(open)) end
 end
 candidate.missions=progressed
 local valid,validation=Schema.validate(candidate,self.catalog)
 if not valid then return nil,validation end
 return valid,finished
end

function Service:_effect(p,op,boostState,seed)
	if op.kind=="receipt" then
		local key=Service.receiptKey(op.receiptId)
		if p.receiptIds[key]==true then return {type="ReceiptAlreadyGranted"} end
		local grant=table.clone(op.grant);grant.id=op.id
		local result,err=self:_effect(p,grant,boostState)
		if not result then return nil,err end
		p.receiptIds[key]=true
		return result
	elseif op.kind=="passGrant" then
		if p.boosts[op.resource=="xp" and "permanentXP" or "permanentPaper"] then return {type="PassAlreadyGranted"} end
		return self:_effect(p,{kind="boostIntent",resource=op.resource,action="permanent"},boostState)
	end
	if boostState then p.boosts=assert(Schema.copy(boostState)) end
	local v=Schema.economicView(p)
	local applied,err,result
	if op.kind=="giftSent" then result={type="GiftSent"}
	elseif op.kind=="giftReceived" then
		if table.find(p.giftIds,op.giftId) then return {type="GiftAlreadyReceived"} end
		local grant=Commerce.giftGrant(op.key);grant.id=op.id
		local granted,why=self:_effect(p,grant,boostState);if not granted then return nil,why end
		table.insert(p.giftIds,op.giftId);if #p.giftIds>200 then table.remove(p.giftIds,1) end
		result={type="GiftReceived",from=op.fromName,key=op.key}
	elseif op.kind=="contribution" then applied,err=Economy.applyContribution(v,op.points,op.multipliers,op.id)
	elseif op.kind=="finalBonus" then
		applied,err=Economy.applyFinalBonuses(v,{finalPaper=op.finalPaper,finalXP=op.finalXP},op.multipliers,op.id)
	elseif op.kind=="equipmentPurchase" then applied,err=Economy.validateEquipmentPurchase(v,self.catalog,op.catalogID,op.id)
	elseif op.kind=="partUnlock" then
		if not self.catalog:get(op.catalogID) then return nil,"unknown_part" end
		if p.ownership[op.catalogID]==true then result={type="PartAlreadyOwned"}
		else p.ownership[op.catalogID]=true;result={type="PartUnlocked",catalogID=op.catalogID} end
	elseif op.kind=="lookUnlock" then applied,err=Looks.grant(v,op.lookID,op.id)
	elseif op.kind=="lookPurchase" then applied,err=Looks.buyWithPaper(v,op.lookID,op.id)
	elseif op.kind=="emotePurchase" then
		local ok,reason,price=Emotes.buy(p.emotes,op.emoteID,math.floor(p.paperMilli/Economy.MILLI))
		if not ok then return nil,reason end
		local chargedMilli=price*Economy.MILLI
		p.paperMilli-=chargedMilli
		p.emotes.owned[op.emoteID]=true
		result={type="EmotePurchased",emoteID=op.emoteID,chargedMilli=chargedMilli}
	elseif op.kind=="emoteWear" then
		local ok,reason,slot=Emotes.wear(p.emotes,op.emoteID)
		if not ok then return nil,reason end
		p.emotes[slot]=op.emoteID
		result={type="EmoteWorn",emoteID=op.emoteID}
	elseif op.kind=="emoteUnlock" then
		if not Emotes.price(op.emoteID) then return nil,"invalid_emote_grant" end
		local alreadyOwned=Emotes.owns(p.emotes,op.emoteID)
		p.emotes.owned[op.emoteID]=true
		result={type="EmoteGranted",emoteID=op.emoteID,alreadyOwned=alreadyOwned}
	elseif op.kind=="openChest" then
		local chest=Looks.chest(op.chest)
		if not chest then return nil,"unknown_chest" end
		if p.chests.opened~=op.opened then return nil,"stale_chest" end
		local price=op.source=="paper" and chest.cost*Economy.MILLI or 0
		if p.paperMilli<price then return nil,"insufficient_paper" end
		local stock = if op.source=="earned" then p.chests.stock elseif op.source=="paidStock" then p.chests.paidStock else nil
		local stockKey = if op.source=="earned" then chest.base else chest.id
		if stock and stock[stockKey]<1 then return nil,op.source=="earned" and "no_earned_chest" or "no_paid_chest" end
		local opened=safeAdd(p.chests.opened,1)
		if not opened then return nil,"overflow" end
		local id=Looks.drawChest(chest,self.random)
		local refund=0
		if p.looks.owned[id] then
			refund=Looks.duplicateRefund(id)
		else
			local granted,rejected=Looks.grant(v,id,op.id)
			if not granted then return nil,rejected.code end
			Schema.mergeEconomic(p,granted.profile)
		end
		local balance=safeAdd(p.paperMilli-price,refund*Economy.MILLI)
		if not balance then return nil,"overflow" end
		p.paperMilli=balance
		if stock then stock[stockKey]-=1 end
		p.chests.opened,p.chests.lastSkin,p.chests.lastChest,p.chests.lastRefund=opened,id,chest.id,refund
		result={type="ChestOpened",skin=id,chest=chest.id,opened=opened,refund=refund,source=op.source}
	elseif op.kind=="lookWear" then
		local skinID,trailID=op.skinID,op.trailID
		if op.slot=="skin" then skinID,trailID=op.lookID,v.looks.trail
		elseif op.slot=="trail" then skinID,trailID=v.looks.skin,op.lookID end
		applied,err=Looks.wear(v,skinID,trailID,op.id)
	elseif op.kind=="prestige" then
		-- Keep unrelated save fields outside the economy rules' smaller copy bounds.
		local prestigeView=assert(Schema.copy(v))
		prestigeView.prestige=p.prestige;prestigeView.presets=p.presets;prestigeView.refolds=p.refolds
		applied,err=Economy.prestige(prestigeView,self.catalog,op.id)
		if applied then
			p.prestige=applied.profile.prestige;p.presets=assert(Schema.copy(applied.profile.presets))
			p.unlocksSeen=assert(Economy.levelForXP(applied.profile.xpMilli))
		end
	elseif op.kind=="purchasedPaper" then
		local amount=op.wholePaper
		if op.packKey~=nil then
			if Commerce.paperPackAmount(op.packKey)~=amount then return nil,"invalid_pack" end
			if not p.firstBuys[op.packKey] then amount*=2 end
		end
		applied,err=Economy.addPurchasedPaper(v,amount,op.id)
		if applied and op.packKey then p.firstBuys[op.packKey]=true end
	elseif op.kind=="doubleLock" then
		for field in pairs(op) do
			if field~="kind" and field~="id" and field~="key" and field~="matchId" and field~="paper" and field~="xp" then return nil,"invalid_double_lock" end
		end
		local lock={matchId=op.matchId,paper=op.paper,xp=op.xp}
		if not Schema.validDoubleLock(op.key,lock) then return nil,"invalid_double_lock" end
		p.doubleLocks[op.key]=lock
		result={type="DoubleLocked",key=op.key}
	elseif op.kind=="matchDouble" then
		if not Commerce.isMatchDoubleKey(op.key) then return nil,"invalid_double_key" end
		for field in pairs(op) do if field~="kind" and field~="key" and field~="id" then return nil,"invalid_double_grant" end end
		local lock=p.doubleLocks[op.key]
		local paper=lock and lock.paper or tonumber(op.key:match("^match_double_(%d+)$"))*10
		local amountXP=lock and lock.xp or math.round(paper*EconomyConfig.xp_per_point/EconomyConfig.paper_per_point)
		local paid,rejected=Economy.addPurchasedPaper(v,paper,op.id)
		if not paid then return nil,rejected.code end
		Schema.mergeEconomic(p,paid.profile)
		local xp=safeAdd(p.xpMilli,amountXP*Economy.MILLI);if not xp then return nil,"overflow" end
		p.xpMilli=xp
		p.doubleLocks[op.key]=nil
		result={type="MatchDoubled",paper=paper,xp=amountXP,matchId=lock and lock.matchId or nil}
	elseif op.kind=="dailyGift" then
		local reward,why=giftReward(p,op.day);if not reward then return nil,why end
		if reward.paper then
			local paid,rejected=Economy.applyFinalBonuses(v,{finalPaper=reward.paper,finalXP=0},{paper=1,xp=1},op.id)
			if not paid then return nil,rejected.code end
			Schema.mergeEconomic(p,paid.profile)
		end
		if reward.chest then
			local total=safeAdd(p.chests.stock[reward.chest],1)
			if not total then return nil,"overflow" end
			p.chests.stock[reward.chest]=total
		end
		p.dailyGift.next=Commerce.dailyGiftDay(p.dailyGift,op.day)%28+1
		p.dailyGift.lastDay=op.day
		result={type="DailyGiftClaimed",chest=reward.chest,paper=reward.paper,seconds=reward.xp_seconds or reward.paper_seconds,
			resource=reward.xp_seconds and "xp" or reward.paper_seconds and "paper" or nil}
	elseif op.kind=="paidChest" then
		local chest=Looks.chest(op.chest)
		if not chest then return nil,"unknown_chest" end
		local total=safeAdd(p.chests.paidStock[chest.id],1)
		if not total then return nil,"overflow" end
		p.chests.paidStock[chest.id]=total
		result={type="ChestDelivered",chest=chest.id}
	elseif op.kind=="starterPack" then
		local pack=EconomyConfig.starter_pack
		if not self.catalog:get(pack.part) then return nil,"unknown_part" end
		local paid,rejected=Economy.addPurchasedPaper(v,pack.paper,op.id)
		if not paid then return nil,rejected.code end
		Schema.mergeEconomic(p,paid.profile);p.ownership[pack.part]=true;p.starterPack.bought=true
		local delivered,err=self:_effect(p,{kind="paidChest",chest=pack.chest})
		if not delivered then return nil,err end
		result={type="StarterPackGranted"}
	elseif op.kind=="paperJar" then
		local paper=math.floor(p.paperJarMilli/Economy.MILLI)
		if paper>0 then
			local paid,rejected=Economy.addPurchasedPaper(v,paper,op.id)
			if not paid then return nil,rejected.code end
			Schema.mergeEconomic(p,paid.profile)
		end
		p.paperJarMilli%=Economy.MILLI
		result={type="PaperJarBroken",paper=paper}
	elseif op.kind=="preset" then
		if not Schema.integer(op.slot) or op.slot<1 or op.slot>Gameplay.menus.saved_loadouts then return nil,"invalid_slot" end
		p.presets[op.slot]={name=op.name,loadout=op.loadout}; result={type="PresetSaved",slot=op.slot}
	elseif op.kind=="rangePreset" then
		if not Schema.integer(op.slot) or op.slot<1 or op.slot>Gameplay.menus.saved_loadouts then return nil,"invalid_slot" end
		p.rangePresets[op.slot]={name=op.name,loadout=op.loadout}; result={type="RangePresetSaved",slot=op.slot}
	elseif op.kind=="rangeSlot" then
		if not Schema.integer(op.slot) or op.slot<1 or op.slot>Gameplay.menus.saved_loadouts then return nil,"invalid_slot" end
		p.rangeSlot=op.slot; result={type="RangeSlotSaved",slot=op.slot}
	elseif op.kind=="settings" then p.settings=op.settings; result={type="SettingsSaved"}
	elseif op.kind=="lessonDone" then
		if not Schema.LESSONS[op.lesson] then return nil,"invalid_lesson" end
		p.lessons[op.lesson]=true; result={type="LessonDone",lesson=op.lesson}
	elseif op.kind=="unlocksSeen" then
		if not Schema.integer(op.level) or op.level<1 then return nil,"invalid_level" end
		local currentLevel=assert(Economy.levelForXP(p.xpMilli))
		p.unlocksSeen=math.max(p.unlocksSeen,math.min(op.level,currentLevel)); result={type="UnlocksSeen",level=p.unlocksSeen}
	elseif op.kind=="qualification" then
		if not Schema.id(op.matchId) or type(op.activeSeconds)~="number" or op.activeSeconds<Gameplay.bots.qualification_active_seconds or not Schema.integer(op.events) or op.events<Gameplay.bots.qualification_combat_or_objective_events then return nil,"not_qualified" end
		local already=p.qualification.history[op.matchId]==true or p.qualification.count>=Gameplay.bots.rookie_qualifying_matches
		if not already then p.qualification.history[op.matchId]=true; p.qualification.count+=1 end
		result={type="QualificationRecorded",count=p.qualification.count,alreadyQualified=already}
	elseif op.kind=="boostIntent" then
		-- The preview from Shared.BoostClock has already settled time and applied this
		-- verified intent. No second consuming/granting authority lives in storage.
		if not boostState then return nil,"boost_preview_required" end
		result={type="BoostIntentApplied",resource=op.resource,action=op.action}
	elseif op.kind=="refoldIntent" then
		if not Schema.id(op.intentId) or type(op.fence)~="table" or type(op.loadout)~="table" then return nil,"invalid_refold_intent" end
		if op.fence.nonce~=p.lease.nonce or op.fence.generation~=p.generation then return nil,"refold_fence_lost" end
		local level=assert(Economy.levelForXP(p.xpMilli))
		if not self.catalog:validateLoadout(op.loadout,p.ownership,level) and not self.catalog:isClassLoadout(op.loadout,level) then return nil,"invalid_refold_build" end
		p.refolds=p.refolds or {}
		if p.refolds[op.intentId] then return nil,"intent_exists" end
		if count(p.refolds)>=Config.max_refolds then return nil,"refold_backpressure" end
		local cost=require(Root.Generated.Gameplay).service.full_refold_paper*1000
		if p.paperMilli<cost then return nil,"insufficient_paper" end
		p.paperMilli-=cost
		p.refolds[op.intentId]={state="reserved",costMilli=cost,fence=op.fence,loadout=op.loadout}
		result={type="RefoldReserved",intentId=op.intentId}
	elseif op.kind=="refoldDeliver" or op.kind=="refoldCancel" or op.kind=="refoldRetire" or op.kind=="refoldRefund" or op.kind=="refoldApplied" then
		local intent=p.refolds and p.refolds[op.intentId]
		if not intent then return nil,"missing_refold_intent" end
		if op.kind=="refoldApplied" then
			if intent.fence.nonce~=p.lease.nonce or intent.fence.generation~=p.generation then return nil,"refold_fence_lost" end
			if intent.state~="delivered" and intent.state~="applied" then return nil,"refold_not_delivered" end
			intent.state="applied";result={type="RefoldApplied",intentId=op.intentId}
		elseif op.kind=="refoldRetire" then
			if intent.state=="reserved" then return nil,"refold_not_terminal" end
			p.refolds[op.intentId]=nil; result={type="RefoldRetired",intentId=op.intentId}
		elseif op.kind=="refoldDeliver" then
			if intent.state=="cancelled" then return nil,"refold_cancelled" end
			if intent.state=="applied" then return nil,"refold_already_applied" end
			if intent.fence.nonce~=p.lease.nonce or intent.fence.generation~=p.generation then return nil,"refold_fence_lost" end
			intent.state="delivered"; result={type="RefoldDelivered",intentId=op.intentId}
		elseif op.kind=="refoldRefund" then
			-- Compensate when delivery finished after its life ended.
			-- The ordinary cancellation path still cannot undo an applied refold.
			if intent.fence.nonce~=p.lease.nonce or intent.fence.generation~=p.generation then return nil,"refold_fence_lost" end
			if intent.state=="reserved" then return nil,"refold_not_delivered" end
			if intent.state=="applied" then return nil,"refold_already_applied" end
			if intent.state=="delivered" then
				local refunded=safeAdd(p.paperMilli,intent.costMilli);if not refunded then return nil,"overflow" end
				p.paperMilli=refunded;intent.state="cancelled"
			end
			result={type="RefoldUndeliveredRefund",intentId=op.intentId}
		else
			if intent.state=="delivered" or intent.state=="applied" then return nil,"refold_already_delivered" end
			if intent.state=="reserved" then
				local refunded=safeAdd(p.paperMilli,intent.costMilli); if not refunded then return nil,"overflow" end
				p.paperMilli=refunded; intent.state="cancelled"
			end
			result={type="RefoldCancelled",intentId=op.intentId}
		end
	elseif op.kind=="missionClaim" or op.kind=="missionSwap" or op.kind=="devFinishMissions" then
		return self:_missionAction(p,op,seed)
	elseif op.kind=="statistics" then
		if type(op.deltas)~="table" then return nil,"invalid_statistics" end
		for k,n in pairs(op.deltas) do if p.statistics[k]==nil then return nil,"invalid_statistic" end; local value=safeAdd(p.statistics[k],n); if not value then return nil,"overflow" end; p.statistics[k]=value end
		result={type="StatisticsApplied"}
	end
	if err then return nil,err.code end
	if applied then
		Schema.mergeEconomic(p,applied.profile); result=applied.operation
		if op.kind=="contribution" or op.kind=="finalBonus" then
			local jar=EconomyConfig.paper_jar
			p.paperJarMilli=math.min(jar.cap_paper*Economy.MILLI,p.paperJarMilli+math.floor(result.paperMilli*jar.share))
		end
	end
	if not result then return nil,"unsupported_operation" end
	return assert(Schema.copy(result))
end
local allowed={paidChest=true,receipt=true,giftReceived=true,passGrant=true,dailyGift=true,starterPack=true,paperJar=true,doubleLock=true,matchDouble=true,contribution=true,finalBonus=true,equipmentPurchase=true,prestige=true,preset=true,rangePreset=true,rangeSlot=true,settings=true,lessonDone=true,unlocksSeen=true,
 qualification=true,purchasedPaper=true,boostIntent=true,statistics=true,missionClaim=true,missionSwap=true,devFinishMissions=true,refoldIntent=true,lookPurchase=true,lookWear=true,openChest=true,
 emotePurchase=true,emoteWear=true,emoteUnlock=true,
 refoldDeliver=true,refoldCancel=true,refoldRetire=true,refoldRefund=true,refoldApplied=true}
local function appliedOutcome(value,replayed)
 if value.type=="MissionRefused" then
  return outcome("error",value.code,value.shortfall and {shortfall=value.shortfall})
 end
 local applied=outcome("ok",nil,value)
 applied.replayed=replayed
 return applied
end
local rewardKinds={contribution=true,finalBonus=true,qualification=true,statistics=true}
function Service:apply(account,input)
 local s=self:_session(account);if not s then return outcome("retry","profile_unavailable") end
 local op=Schema.copyOperation(input)
 if not op or not allowed[op.kind] or not Schema.id(op.id) then return outcome("error","invalid_operation") end
 local token,sequence=op.id:match("^(%w+):(%d+)$");sequence=tonumber(sequence)
 local reward=token and token:match("^reward%w+$") and rewardKinds[op.kind] and type(op.rewardSource)=="string"
 if (token~=s.token and not reward) or not Schema.integer(sequence) or sequence<1 then return outcome("error","old_session_operation") end
 local identity=Schema.canonical(op)
 local cached=s.results[op.id]
 if cached and cached.identity~=identity then return outcome("error","operation_id_conflict") end
 if sequence<=(s.profile.Data.operationIds[token] or 0) then
  return appliedOutcome(cached and cached.value or {type="AlreadyApplied",operationID=op.id},true)
 end
 if op.kind=="missionClaim" or op.kind=="missionSwap" then
  if not Missions.validSlot(op.list,op.index) then return outcome("error","invalid_mission") end
  for key in pairs(op) do
   if key~="kind" and key~="id" and key~="list" and key~="index" then return outcome("error","invalid_operation") end
  end
 elseif op.kind=="devFinishMissions" and not self.mock then
  return outcome("error","studio_only")
 end
 local mockBuy=op.kind=="paidChest" or op.kind=="purchasedPaper" or op.kind=="boostIntent" or op.kind=="starterPack" or op.kind=="paperJar" or op.kind=="matchDouble" or op.kind=="emoteUnlock"
 if (op.kind=="paidChest" or op.kind=="starterPack") and self.mock and s.chestPaperAllowed~=true then return outcome("error","chest_paper_unavailable") end
 if mockBuy and not self.mock then return outcome("error","studio_only") end
 if mockBuy and count(s.profile.Data.receiptIds)>=ServerConfig.schema.max_receipts then return outcome("error","receipt_cap") end
 if op.kind=="starterPack" and Commerce.starterPackEnds(s.profile.Data,self.unix())==0 then return outcome("error","starter_pack_ended") end
 if op.kind=="paperJar" and s.profile.Data.paperJarMilli<EconomyConfig.paper_jar.min_break_paper*Economy.MILLI then return outcome("error","jar_low") end
 local intent=op
 if op.kind=="receipt" then
  if type(op.receiptId)~="string" or #op.receiptId==0 then return outcome("error","invalid_receipt") end
  if not validReceiptGrant(op.grant) then return outcome("error","invalid_receipt_grant") end
  local key=Service.receiptKey(op.receiptId)
  if s.profile.Data.receiptIds[key]==true then intent=nil
  elseif count(s.profile.Data.receiptIds)>=ServerConfig.schema.max_receipts then
   -- Ceiling: 1000 receipts per player. Upgrade path: ordered ring with
   -- oldest-acknowledged eviction; never evict a pending receipt to make room.
   return outcome("error","receipt_cap")
  else intent=op.grant end
 elseif op.kind=="giftReceived" then
  if not Schema.validGift(op) then return outcome("error","invalid_gift") end
  intent=not table.find(s.profile.Data.giftIds,op.giftId) and Commerce.giftGrant(op.key) or nil
 elseif op.kind=="passGrant" then
  if op.resource~="xp" and op.resource~="paper" then return outcome("error","invalid_resource") end
  if s.profile.Data.boosts[op.resource=="xp" and "permanentXP" or "permanentPaper"] then intent=nil
  else intent={kind="boostIntent",resource=op.resource,action="permanent"} end
 elseif op.kind=="openChest" then
  if type(op.chest)~="string" or not Schema.integer(op.opened) or (op.source~="earned" and op.source~="paper" and op.source~="paidStock") then return outcome("error","invalid_operation") end
  for key in pairs(op) do if key~="kind" and key~="id" and key~="opened" and key~="chest" and key~="source" then return outcome("error","invalid_operation") end end
  if op.source~="earned" and s.chestPaperAllowed~=true then return outcome("error","chest_paper_unavailable") end
 elseif op.kind=="lookPurchase" or op.kind=="lookWear" then
  local fields
  if op.kind=="lookPurchase" then
   if type(op.lookID)~="string" or #op.lookID==0 or #op.lookID>160 then return outcome("error","invalid_operation") end
   fields={kind=true,id=true,lookID=true}
  elseif op.slot~=nil then
   if (op.slot~="skin" and op.slot~="trail") or type(op.lookID)~="string" or #op.lookID>160 then return outcome("error","invalid_operation") end
   fields={kind=true,id=true,slot=true,lookID=true}
  else
   if type(op.skinID)~="string" or #op.skinID>160 or type(op.trailID)~="string" or #op.trailID>160 then return outcome("error","invalid_operation") end
   fields={kind=true,id=true,skinID=true,trailID=true}
  end
  for field in pairs(op) do if not fields[field] then return outcome("error","invalid_operation") end end
 elseif op.kind=="emotePurchase" or op.kind=="emoteWear" or op.kind=="emoteUnlock" then
  if type(op.emoteID)~="string" or #op.emoteID>128 then return outcome("error","invalid_operation") end
  for field in pairs(op) do
   if field~="kind" and field~="id" and field~="emoteID" then return outcome("error","invalid_operation") end
  end
  if op.kind=="emoteUnlock" and Emotes.owns(s.profile.Data.emotes,op.emoteID) then return outcome("error","owned") end
 end
 local advanced,why=self:_advance(s);if not advanced then return outcome("retry",why) end
 -- Composite rewards use the same clock preview as a paid timed boost. Nothing is
 -- installed until the entire profile (including money, ownership and IDs) validates.
 if intent and intent.kind=="dailyGift" then
  local reward,err=giftReward(s.profile.Data,op.day);if not reward then return outcome("error",err) end
  intent=reward.xp_seconds and {kind="boostIntent",resource="xp",action="duration",seconds=reward.xp_seconds}
   or reward.paper_seconds and {kind="boostIntent",resource="paper",action="duration",seconds=reward.paper_seconds} or nil
 elseif intent and intent.kind=="starterPack" then
  intent={kind="boostIntent",resource="xp",action="duration",seconds=EconomyConfig.starter_pack.xp_seconds}
 end
 local clock=s.clock
 if intent and intent.kind=="boostIntent" then
  clock=BoostClock.new(s.clock:snapshot(),s.clock.now,s.clock.eligible,{historyLimit=Config.boost_history_limit})
  clock.startedAt=s.clock.startedAt;clock.watermark=s.clock.watermark;clock.revision=s.clock.revision
  clock.intervals=assert(Schema.copy(s.clock.intervals));clock.changes=assert(Schema.copy(s.clock.changes))
  local ok,err
  if intent.action=="duration" then ok,err=clock:grantVerifiedTemporary(intent.resource,intent.seconds,self.mono())
  elseif intent.action=="permanent" then ok,err=clock:grantVerifiedPermanent(intent.resource,self.mono()) end
  if not ok then return outcome("error",err or "invalid_boost_intent") end
 end
 local data=assert(Schema.copy(s.profile.Data));data.lease={nonce=s.token,generation=data.generation,expires=0}
 local seed=tonumber(account) or 0
 local result,err,details=self:_effect(data,op,clock:snapshot(),seed)
 if not result then return outcome("error",err,details) end
 if mockBuy or (op.kind=="receipt" and result.type~="ReceiptAlreadyGranted") then
  local recorded,code=self:_recordBuy(data);if not recorded then return outcome("error",code) end
  -- Practice buys leave the same purchase history as receipts, in mock profiles only.
  if mockBuy then data.receiptIds[Service.receiptKey("mock:"..op.id)]=true end
 end
 -- Reward streams reuse the saved operation watermarks across receiving sessions.
 if data.operationIds[token]==nil then
  table.insert(data.operationSessions,token)
  if #data.operationSessions>Config.session_id_history then
   local oldest=data.operationSessions[1]==s.token and 2 or 1
   data.operationIds[table.remove(data.operationSessions,oldest)]=nil
  end
 end
 data.lease=nil;data.version+=1;data.operationIds[token]=sequence
 local valid,validation
 if op.kind=="statistics" then
  result.finishedMissions={}
  if op.missions~=nil then
   local ok,candidate,finished=pcall(self._matchMissions,self,data,op,seed)
   if ok and candidate then
    valid=candidate
    result.finishedMissions=finished
   else
    local code=if not ok then "mission_error" elseif finished=="refresh_required" then "stale_period" else finished or "mission_error"
    -- Delayed and ineligible matches are routine. Log each cause once per server.
    if not self.missionWarnings[code] then
     self.missionWarnings[code]=true
     warn("Skipped mission progress: "..tostring(code))
    end
   end
  end
 end
 if not valid then valid,validation=Schema.validate(data,self.catalog) end
 if not valid then return outcome("error",validation) end
 -- No yield between active-session check and replacing Data. One saved profile contains
 -- both the balance change and its operation ID, so retries cannot pay it twice.
 s.profile.Data=valid;s.clock=clock
 result.operationID=op.id;result.version=data.version
 s.results[op.id]={identity=identity,value=result};table.insert(s.resultOrder,op.id)
 if #s.resultOrder>Config.result_cache_limit then s.results[table.remove(s.resultOrder,1)]=nil end
 return appliedOutcome(result)
end
return Service
