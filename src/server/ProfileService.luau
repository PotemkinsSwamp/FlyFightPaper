-- ProfileStore owns persistence and session locking. Operations below never yield.
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local BoostClock=require(Root.Shared.BoostClock)
local Gameplay=require(Root.Generated.Gameplay)
local Config=require(Root.Generated.Server).profiles
local Service={};Service.__index=Service
local function outcome(status,code,value) return {status=status,code=code,value=value} end
local function count(t) local n=0;for _ in pairs(t) do n+=1 end;return n end
function Service.new(options)
 return setmetatable({catalog=options.catalog,mono=options.monotonic or os.clock,
  mock=Run:IsStudio() and options.mock==true,sessions={}},Service)
end
function Service:operationID() return Http:GenerateGUID(false):gsub("%-",""):sub(1,24) end
function Service:attach(account,profile,availability)
 if self.sessions[account] then return outcome("error","already_loaded") end
 if not profile:IsActive() then return outcome("error","session_lost") end
 local data,why=Schema.migrate(profile.Data,self.catalog)
 if not data then return outcome("error",why) end
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
function Service:_advance(s)
 local ok,why=s.clock:advance(self.mono(),s.connected and s.mapLoaded)
 if not ok then return false,why end
 s.profile.Data.boosts=assert(Schema.copy(s.clock:snapshot()))
 return true
end
function Service:view(account)
 local s=self:_session(account);if not s then return outcome("error","profile_unavailable") end
 local ok,why=self:_advance(s);if not ok then return outcome("error",why) end
 local data=assert(Schema.copy(s.profile.Data))
 -- Compatibility for desk life checks. This is a session token, not a storage lock.
 data.lease={nonce=s.token,generation=data.generation,expires=0}
 return outcome("ok",nil,Schema.freeze(data))
end
function Service:prepare(account,input)
 local s=self:_session(account);if not s then return nil end
 local op=Schema.copy(input);if not op then return nil end
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
function Service:_effect(p,op,boostState)
	if boostState then p.boosts=assert(Schema.copy(boostState)) end
	local v=Schema.economicView(p)
	local applied,err,result
	if op.kind=="contribution" then applied,err=Economy.applyContribution(v,op.points,op.multipliers,op.id)
	elseif op.kind=="finalBonus" then
		applied,err=Economy.applyFinalBonuses(v,{finalPaper=op.finalPaper,finalXP=op.finalXP},op.multipliers,op.id)
	elseif op.kind=="equipmentPurchase" then applied,err=Economy.validateEquipmentPurchase(v,self.catalog,op.catalogID,op.id)
	elseif op.kind=="purchasedPaper" then applied,err=Economy.addPurchasedPaper(v,op.wholePaper,op.id)
	elseif op.kind=="preset" then
		if not Schema.integer(op.slot) or op.slot<1 or op.slot>Gameplay.menus.saved_loadouts then return nil,"invalid_slot" end
		p.presets[op.slot]={name=op.name,loadout=op.loadout}; result={type="PresetSaved",slot=op.slot}
	elseif op.kind=="settings" then p.settings=op.settings; result={type="SettingsSaved"}
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
		if not self.catalog:validateLoadout(op.loadout,p.ownership,assert(Economy.levelForXP(p.xpMilli))) then return nil,"invalid_refold_build" end
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
	elseif op.kind=="statistics" then
		if type(op.deltas)~="table" then return nil,"invalid_statistics" end
		for k,n in pairs(op.deltas) do if p.statistics[k]==nil then return nil,"invalid_statistic" end; local value=safeAdd(p.statistics[k],n); if not value then return nil,"overflow" end; p.statistics[k]=value end
		result={type="StatisticsApplied"}
	end
	if err then return nil,err.code end
	if applied then Schema.mergeEconomic(p,applied.profile); result=applied.operation end
	if not result then return nil,"unsupported_operation" end
	return assert(Schema.copy(result))
end
local allowed={contribution=true,finalBonus=true,equipmentPurchase=true,preset=true,settings=true,
 qualification=true,purchasedPaper=true,boostIntent=true,statistics=true,refoldIntent=true,
 refoldDeliver=true,refoldCancel=true,refoldRetire=true,refoldRefund=true,refoldApplied=true}
function Service:apply(account,input)
 local s=self:_session(account);if not s then return outcome("retry","profile_unavailable") end
 local op=Schema.copy(input)
 if not op or not allowed[op.kind] or not Schema.id(op.id) then return outcome("error","invalid_operation") end
 local token,sequence=op.id:match("^(%w+):(%d+)$");sequence=tonumber(sequence)
 if token~=s.token or not Schema.integer(sequence) or sequence<1 then return outcome("error","old_session_operation") end
 local identity=Schema.canonical(op)
 local cached=s.results[op.id]
 if cached and cached.identity~=identity then return outcome("error","operation_id_conflict") end
 if sequence<=s.profile.Data.operationIds[token] then
  return outcome("ok",nil,cached and cached.value or {type="AlreadyApplied",operationID=op.id})
 end
 if (op.kind=="purchasedPaper" or op.kind=="boostIntent") and not self.mock then return outcome("error","studio_only") end
 local advanced,why=self:_advance(s);if not advanced then return outcome("retry",why) end
 local clock=s.clock
 if op.kind=="boostIntent" then
  clock=BoostClock.new(s.clock:snapshot(),s.clock.now,s.clock.eligible,{historyLimit=Config.boost_history_limit})
  clock.startedAt=s.clock.startedAt;clock.watermark=s.clock.watermark;clock.revision=s.clock.revision
  clock.intervals=assert(Schema.copy(s.clock.intervals));clock.changes=assert(Schema.copy(s.clock.changes))
  local ok,err
  if op.action=="duration" then ok,err=clock:grantVerifiedTemporary(op.resource,op.seconds,self.mono())
  elseif op.action=="permanent" then ok,err=clock:grantVerifiedPermanent(op.resource,self.mono()) end
  if not ok then return outcome("error",err or "invalid_boost_intent") end
 end
 local data=assert(Schema.copy(s.profile.Data));data.lease={nonce=s.token,generation=data.generation,expires=0}
 local result,err=self:_effect(data,op,clock:snapshot())
 if not result then return outcome("error",err) end
 data.lease=nil;data.version+=1;data.operationIds[token]=sequence
 local valid,validation=Schema.validate(data,self.catalog)
 if not valid then return outcome("error",validation) end
 -- No yield between active-session check and replacing Data. One saved profile contains
 -- both the balance change and its operation ID, so retries cannot pay it twice.
 s.profile.Data=valid;s.clock=clock
 result.operationID=op.id;result.version=data.version
 s.results[op.id]={identity=identity,value=result};table.insert(s.resultOrder,op.id)
 if #s.resultOrder>Config.result_cache_limit then s.results[table.remove(s.resultOrder,1)]=nil end
 return outcome("ok",nil,result)
end
return Service
