-- A failing profile only holds up that player's rewards. Round state never waits here.
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Config=require(Root.Generated.Server).rewards
local Queue={};Queue.__index=Queue
local queues=setmetatable({},{__mode="k"})
-- Loaded before ProfileStore so pending offline sends can start before it stops accepting messages.
game:BindToClose(function()
 local deadline=os.clock()+require(Root.Generated.Server).profiles.shutdown_seconds
 for queue in pairs(queues) do task.spawn(function()queue:flushOffline(deadline)end) end
 while os.clock()<deadline do
  local pending=false;for queue in pairs(queues) do if queue:hasOffline() then pending=true;break end end
  if not pending then break end;task.wait(.1)
 end
end)
function Queue.new(profiles,clock,log)
 local self=setmetatable({profiles=profiles,clock=clock or os.clock,log=log or warn,players={},seen={},sequence=0,token="reward"..(game:GetService("HttpService"):GenerateGUID(false):gsub("%W",""))},Queue)
 queues[self]=true;return self
end
function Queue:add(userId,source,input,at,accepted)
 local seen=self.seen[userId];if not seen then seen={};self.seen[userId]=seen end
 if seen[source] then return end
 local bucket=self.players[userId]
 if not bucket then bucket={items={},order={}};self.players[userId]=bucket end
 local item={source=source,input=assert(Schema.copy(input)),at=at,accepted=accepted,nextTry=0,nextWarning=0}
 self.sequence+=1;item.input.id=self.token..":"..self.sequence;item.input.rewardSource=source;seen[source]=true
 bucket.items[source]=item;table.insert(bucket.order,source)
 if #bucket.order==Config.pending_per_player then self.log("Many rewards pending for player "..userId) end
end
function Queue:hasOffline()
 for userId in pairs(self.players) do if not self.profiles:hasPlayer(userId) then return true end end
 return false
end
function Queue:flushOffline(deadline)
 self.closing=true
 for _,bucket in pairs(self.players) do for _,item in pairs(bucket.items) do item.nextTry=0 end end
 while self:hasOffline() and os.clock()<deadline do self:step(true,deadline);task.wait(.1) end
end
function Queue:step(offlineOnly,deadline)
 offlineOnly=offlineOnly or self.closing
 local now=self.clock()
 for userId,bucket in pairs(self.players) do
  if bucket.busy or (offlineOnly and self.profiles:hasPlayer(userId)) then continue end
  bucket.busy=true
  task.spawn(function()
  -- Each player has independent retries. Other players always get their turn.
  local i=1
  local attempted=0
  while i<=#bucket.order and attempted<Config.attempts_per_player do
   attempted+=1
   local source=bucket.order[i];local item=bucket.items[source]
   if now<item.nextTry or (deadline and os.clock()>=deadline) then break end
   local ok,accepted=pcall(function()
    local player=self.profiles:playerForUserId(userId)
    if not player or offlineOnly then
     if self.profiles:hasPlayer(userId) then return false end
     return self.profiles:messageReward(userId,item.input,item.source)
    end
    if (item.input.kind=="contribution" or item.input.kind=="finalBonus") and not item.input.multipliers then
     local entry=self.profiles.entries[player]
     if not entry then return false end
     local capture=self.profiles.service:producerCapture(entry.account,item.at)
     if capture.status~="ok" then return false end
     item.input.multipliers=assert(Schema.copy(capture.value))
    end
    return self.profiles:enqueue(player,item.input,item.source)
   end)
   if ok and accepted then
    bucket.items[source]=nil;table.remove(bucket.order,i)
    if item.accepted and ((item.input.kind~="contribution" and item.input.kind~="finalBonus") or item.input.multipliers) then
     local notified,err=pcall(item.accepted,item.input)
     if not notified then self.log("Reward display update failed: "..tostring(err)) end
    end
   else
    item.nextTry=now+Config.retry_seconds
    if now>=item.nextWarning then
     self.log("Reward delayed for player "..userId.."; retrying without blocking the round")
     item.nextWarning=now+Config.warning_seconds
    end
    break
   end
  end
  if #bucket.order==0 then self.players[userId]=nil end
  bucket.busy=false
  end)
 end
end
return Queue
