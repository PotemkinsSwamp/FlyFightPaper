-- One ProfileStore session per player. Rewards mutate its in-memory Data;
-- autosaves and final saves are the only normal DataStore writes.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Root=game.ReplicatedStorage.FlyFightPaper
require(script.Parent.RewardQueue) -- Register offline flushing before ProfileStore's close hook.
local ProfileStore=require(script.Parent.Packages.ProfileStore)
local Profile=require(script.Parent.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Gameplay=require(Root.Generated.Gameplay)
local Config=require(Root.Generated.Server).profiles
local Runtime={};Runtime.__index=Runtime
local rewardKinds={contribution=true,finalBonus=true,qualification=true,statistics=true}
function Runtime.new(catalog)
 ProfileStore.SetConstant("AUTO_SAVE_PERIOD",Config.auto_save_seconds)
 ProfileStore.SetConstant("START_SESSION_TIMEOUT",Config.load_timeout_seconds)
 ProfileStore.SetConstant("SESSION_STEAL",Config.session_steal_seconds)
 ProfileStore.SetConstant("LOAD_REPEAT_PERIOD",Config.load_repeat_seconds)
 ProfileStore.SetConstant("FIRST_LOAD_REPEAT",Config.first_load_repeat_seconds)
 local store=ProfileStore.New(Config.data_store,Schema.defaults(catalog))
 local mock=Run:IsStudio()
 local self=setmetatable({catalog=catalog,entries={},mock=mock,stopping=false,store=mock and store.Mock or store},Runtime)
 self.service=Profile.new({catalog=catalog,mock=mock})
 ProfileStore.OnError:Connect(function(_,storeName,key)
  if storeName~=Config.data_store then return end
  for player,e in pairs(self.entries) do
   if key=="Player_"..player.UserId then
    e.saveDelayed=true
    player:SetAttribute("ProfileStatus","Saving delayed. Progress is held in this server.")
   end
  end
 end)
 Players.PlayerAdded:Connect(function(player)self:load(player)end)
 Players.PlayerRemoving:Connect(function(player)
  -- Later removal callbacks may still award a valid contribution. Drain them before ending.
  local e=self.entries[player]
  if e then self:rememberRewardMultipliers(player,e);e.leaving=true;e.releaseAt=os.clock();self.service:setProducerConnected(e.account,false) end
 end)
 for _,player in Players:GetPlayers() do self:load(player) end
 game:BindToClose(function()
  self.stopping=true
  for player in pairs(self.entries) do self:release(player) end
  local deadline=os.clock()+Config.shutdown_seconds
  -- ProfileStore waits for its own final writes and refuses confirmation reads during shutdown.
  while next(self.entries) and not ProfileStore.IsClosing and os.clock()<deadline do task.wait(Config.worker_seconds) end
 end)
 return self
end
function Runtime:release(player)
 local e=self.entries[player]
 if e then self:rememberRewardMultipliers(player,e);e.leaving=true;e.releaseAt=0;self.service:setProducerConnected(e.account,false) end
end
function Runtime:rememberRewardMultipliers(player,e)
 local capture=self.service:producerCapture(e.account)
 if capture.status=="ok" then
  self.rewardMultipliers=self.rewardMultipliers or {};self.rewardMultipliers[player.UserId]=assert(Schema.copy(capture.value))
 end
end
function Runtime:hasPlayer(userId)
 return Players:GetPlayerByUserId(userId)~=nil
end
function Runtime:messageReward(userId,input,source)
 if self:hasPlayer(userId) or (not self.mock and ProfileStore.DataStoreState~="Access") then return false end
 if not input.multipliers and (input.kind=="contribution" or input.kind=="finalBonus") then
  local capture=self.rewardMultipliers and self.rewardMultipliers[userId]
  if capture then input.multipliers=assert(Schema.copy(capture)) end
 end
 return self.store:MessageAsync("Player_"..userId,{kind="reward",source=source,input=assert(Schema.copy(input))})
end
function Runtime:load(player)
 if self.entries[player] or self.stopping then return end
 local e={player=player,account=tostring(player.UserId),queue={},seen={},callbacks={},loaded=false,leaving=false,failures=0}
 self.entries[player]=e;player:SetAttribute("ProfileStatus","Loading")
 task.spawn(function()
  if not self.mock then
   local deadline=os.clock()+Config.access_wait_seconds
   while ProfileStore.DataStoreState=="NotReady" and os.clock()<deadline and not e.leaving and not self.stopping do task.wait(Config.worker_seconds) end
   -- ProfileStore can fall back to memory without API access. Never accept that as live saving.
   if ProfileStore.DataStoreState~="Access" then
    self.entries[player]=nil;player:SetAttribute("ProfileStatus","Saving unavailable")
    if player.Parent then player:Kick("Saving is unavailable. Please rejoin later; your existing progress has not been replaced.") end
    return
   end
  end
  local loadDeadline=os.clock()+Config.load_timeout_seconds
  local ok,profile=pcall(function()
   return self.store:StartSessionAsync("Player_"..player.UserId,{Cancel=function()
    return self.stopping or e.leaving or player.Parent~=Players or os.clock()>=loadDeadline
   end})
  end)
  if not ok or not profile then
   self.entries[player]=nil;player:SetAttribute("ProfileStatus","Progress unavailable. Rejoin to retry.")
   warn("Profile load failed for player "..player.UserId)
   if player.Parent and not e.leaving then player:Kick("Your saved progress could not be loaded. Please rejoin later.") end
   return
  end
  if e.leaving or self.stopping or player.Parent~=Players then profile:EndSession();self.entries[player]=nil;return end
  local attached=self.service:attach(e.account,profile,{connected=true,mapLoaded=player:GetAttribute("ClassroomLoaded")==true})
  if attached.status~="ok" then
   warn("Profile refused for player "..player.UserId..": "..tostring(attached.code))
   profile:EndSession();self.entries[player]=nil
   if player.Parent then player:Kick("Your progress needs recovery. It has not been reset.") end
   return
  end
  profile:AddUserId(player.UserId)
  -- Studio dev account (Alan, 2026-10-08): a real player in Studio owns every part at max level with plenty of
  -- Paper, so every build can be saved and tested. self.mock is only true in Studio; live saves never get this.
  if self.mock then
   local data=profile.Data
   for _,list in ipairs({self.catalog.weapons,self.catalog.utilities}) do for _,part in ipairs(list) do data.ownership[part.id]=true end end
   for _,list in pairs(self.catalog.structuresBySlot) do for _,part in ipairs(list) do data.ownership[part.id]=true end end
   data.xpMilli=math.max(data.xpMilli,60000000);data.paperMilli=math.max(data.paperMilli,100000000)
   attached=self.service:view(e.account)
  end
  e.profile=profile;e.loaded=true;e.snapshot=attached.value;e.lastSavedVersion=profile.LastSavedData and profile.LastSavedData.version or -1
  profile.OnSave:Connect(function()
   self:flush(e)
   local session=self.service.sessions[e.account]
   if session then self.service:_advance(session) end
  end)
  profile.OnAfterSave:Connect(function(data)
   e.lastSavedVersion=data.version;e.saveDelayed=false
   if e.closing and not profile:IsActive() and not ProfileStore.IsClosing then
    local version=not self.mock and profile.KeyInfo.Version or nil
    local ok,saved=pcall(function()return self.store:GetAsync("Player_"..player.UserId,version)end)
    -- Inactivity precedes the final write; only its saved version has a cleared session lock.
    -- A failed read doesn't block: worst case is the old race, never a session stuck open.
    if ok and saved and (saved.Session or saved.Data.generation~=profile.Data.generation or saved.Data.version<profile.Data.version) then return end
    if self.entries[player]==e then self.service:detach(e.account);self.entries[player]=nil end
   end
  end)
  profile.OnSessionEnd:Connect(function()
   if ProfileStore.IsClosing then e.closing=true;return end
   if e.closing or self.stopping then return end
   self.service:detach(e.account)
   if self.entries[player]==e then self.entries[player]=nil end
   player:SetAttribute("ProfileStatus","Session moved. Please rejoin.")
   if player.Parent then player:Kick("Your profile was opened in another server. Please rejoin to continue safely.") end
  end)
  profile:MessageHandler(function(message,processed)
   if type(message)~="table" or message.kind~="reward" then return end
   local input=Schema.copy(message.input)
   if type(input)~="table" or not rewardKinds[input.kind] or not Schema.id(input.id) or not input.id:match("^reward%w+:%d+$") or type(message.source)~="string" or input.rewardSource~=message.source then return end
   while self.entries[player]==e and not e.closing and profile:IsActive() do
    if self:enqueue(player,input,nil,function(ok)if ok then processed()end end) then return end
    task.wait(Config.worker_seconds)
   end
  end)
  self:update(e)
  local nextStatus=0;local processed=0
  while self.entries[player]==e and not e.closing do
   local op=e.queue[1]
   if op then
    processed+=1
    if processed>=Config.operations_per_tick then processed=0;task.wait(Config.worker_seconds) end
    if not self:process(e) then
     e.failures+=1
     warn("Profile operation delayed for player "..player.UserId.."; retrying this player's queue")
     player:SetAttribute("ProfileStatus","Rewards delayed. Retrying.")
     task.wait(math.min(Config.retry_max_seconds,2^math.min(e.failures,3)))
    end
   elseif e.leaving and os.clock()>=(e.releaseAt or 0) then
    e.closing=true
    self.service:setProducerConnected(e.account,false)
    profile:EndSession()
   else
    if os.clock()>=nextStatus then self:update(e);nextStatus=os.clock()+Config.status_seconds end
    task.wait(Config.worker_seconds)
   end
  end
 end)
end
function Runtime:process(e)
 local op=e.queue[1];if not op then return true end
 local success,result=pcall(function()return self.service:apply(e.account,op)end)
 if not success or (result.status~="ok" and result.status~="error") then return false end
 table.remove(e.queue,1);e.failures=0
 local done=e.callbacks[op.id];e.callbacks[op.id]=nil
 if done then task.defer(done,result.status=="ok",result.value or result.code) end
 if result.status=="error" then warn("Profile operation refused for player "..e.player.UserId..": "..tostring(result.code)) end
 self:update(e)
 return true
end
function Runtime:flush(e)
 while e.queue[1] do if not self:process(e) then return false end end
 return true
end
function Runtime:update(e)
 local view=self.service:view(e.account);if view.status~="ok" then return end
 e.snapshot=view.value
 e.player:SetAttribute("Paper",math.floor(e.snapshot.paperMilli/Economy.MILLI))
 e.player:SetAttribute("XP",math.floor(e.snapshot.xpMilli/Economy.MILLI))
 e.player:SetAttribute("Level",Economy.levelForXP(e.snapshot.xpMilli))
 e.player:SetAttribute("Prestige",e.snapshot.prestige or 0)
 e.player:SetAttribute("Graduated",e.snapshot.qualification.count>=Gameplay.bots.rookie_qualifying_matches)
 e.player:SetAttribute("ProfileStatus",self.mock and "Studio session only" or (e.saveDelayed and "Saving delayed. Progress is held in this server." or (e.lastSavedVersion>=e.snapshot.version and "Saved" or "Waiting to save")))
end
function Runtime:view(player)
 local e=self.entries[player];if not e or not e.loaded or e.leaving or e.closing then return nil end
 local current=self.service:view(e.account)
 return current.status=="ok" and current.value or nil
end
function Runtime:playerForUserId(id)
 for player,e in pairs(self.entries) do if player.UserId==id and e.loaded and not e.closing then return player end end
 return nil
end
function Runtime:enqueue(player,input,source,callback)
 local e=self.entries[player];if not e or not e.loaded or e.closing then return false end
 if source and e.seen[source] then return true end
 if #e.queue>=Config.queue_limit then return false end
 local copy=Schema.copy(input);if not copy then return false end
 if (copy.kind=="contribution" or copy.kind=="finalBonus") and not copy.multipliers then
  local capture=self.service:producerCapture(e.account)
  if capture.status~="ok" then return false end
  copy.multipliers=assert(Schema.copy(capture.value))
 end
 local reward=copy.rewardSource~=nil
 if reward and (not rewardKinds[copy.kind] or type(copy.rewardSource)~="string" or not Schema.id(copy.id) or not copy.id:match("^reward%w+:%d+$")) then return false end
 local op=reward and copy or self.service:prepare(e.account,copy);if not op then return false end
 if source then e.seen[source]=true end
 local previous=e.callbacks[op.id]
 table.insert(e.queue,op);e.callbacks[op.id]=previous and function(ok,value)previous(ok,value);if callback then callback(ok,value)end end or callback
 return true
end
return Runtime
