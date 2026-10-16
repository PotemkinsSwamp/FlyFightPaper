-- A failing profile only holds up that player's rewards. Round state never waits here.
local Root=game.ReplicatedStorage.FlyFightPaper
local Schema=require(Root.Shared.ProfileSchema)
local Config=require(Root.Generated.Server).rewards
local Queue={};Queue.__index=Queue
function Queue.new(profiles,clock,log)
 return setmetatable({profiles=profiles,clock=clock or os.clock,log=log or warn,players={}},Queue)
end
function Queue:add(userId,source,input,at,accepted)
 local bucket=self.players[userId]
 if not bucket then bucket={items={},order={}};self.players[userId]=bucket end
 if bucket.items[source] then return end
 local item={source=source,input=assert(Schema.copy(input)),at=at,accepted=accepted,nextTry=0,nextWarning=0}
 bucket.items[source]=item;table.insert(bucket.order,source)
 if #bucket.order==Config.pending_per_player then self.log("Many rewards pending for player "..userId) end
end
function Queue:step()
 local now=self.clock()
 for userId,bucket in pairs(self.players) do
  -- Each player has independent retries. Other players always get their turn.
  local i=1
  local attempted=0
  while i<=#bucket.order and attempted<Config.attempts_per_player do
   attempted+=1
   local source=bucket.order[i];local item=bucket.items[source]
   if now<item.nextTry then break end
   local ok,accepted=pcall(function()
    local player=self.profiles:playerForUserId(userId)
    if not player then return false end
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
    if item.accepted then
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
 end
end
return Queue
