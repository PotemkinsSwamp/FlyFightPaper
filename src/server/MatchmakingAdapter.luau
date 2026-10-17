-- Roblox supplies server discovery and transfers. Access codes remain server-only.
local Players=game:GetService("Players")
local Memory=game:GetService("MemoryStoreService")
local Teleport=game:GetService("TeleportService")
local Config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Server).routing
local Gameplay=require(game.ReplicatedStorage.FlyFightPaper.Generated.Gameplay)
local Adapter={};Adapter.__index=Adapter
function Adapter.new()
 return setmetatable({index=Memory:GetSortedMap("PPD_DEV_room_index"),maps={rookie=Memory:GetSortedMap("PPD_DEV_rookie_rooms"),regular=Memory:GetSortedMap("PPD_DEV_regular_rooms")}},Adapter)
end
function Adapter:currentClass()
 if game.PrivateServerId=="" then return nil end
 local row=self.index:GetAsync(game.PrivateServerId)
 assert(row and (row.class=="rookie" or row.class=="regular"),"Reserved room class unavailable")
 self.row=row;return row.class
end
function Adapter:advertise(class)
 local row=self.row or {jobId=game.JobId}
 row.class=class;row.count=#Players:GetPlayers();row.updatedAt=os.time()
 local key=game.PrivateServerId~="" and game.PrivateServerId or game.JobId
 self.maps[class]:SetAsync(key,row,Config.entry_ttl_seconds,row.count)
 if game.PrivateServerId~="" then self.index:SetAsync(key,row,Config.entry_ttl_seconds,row.count) end
end
function Adapter:destination(class)
 for _,entry in ipairs(self.maps[class]:GetRangeAsync(Enum.SortDirection.Ascending,Config.destination_scan_limit)) do
  local row=entry.value
  if type(row)=="table" and row.class==class and type(row.count)=="number" and row.count<Gameplay.world.maximum_actors and type(row.updatedAt)=="number" and os.time()-row.updatedAt<Config.entry_fresh_seconds then
   if entry.key~=game.PrivateServerId and ((type(row.accessCode)=="string" and #row.accessCode>0) or (type(row.jobId)=="string" and #row.jobId>0 and row.jobId~=game.JobId)) then row.roomId=entry.key;return row end
  end
 end
 local teleport=self.teleport or Teleport;local code,id=teleport:ReserveServerAsync(game.PlaceId)
 local row={class=class,accessCode=code,roomId=id,count=0,updatedAt=os.time()}
 self.index:SetAsync(id,row,Config.entry_ttl_seconds,0);self.maps[class]:SetAsync(id,row,Config.entry_ttl_seconds,0)
 return row
end
function Adapter:send(player,destination,canSend)
 local row=table.clone(destination);row.updatedAt=os.time()
 local key=row.roomId or row.jobId
 if row.accessCode then self.index:SetAsync(key,row,Config.entry_ttl_seconds,row.count) end
 self.maps[row.class]:SetAsync(key,row,Config.entry_ttl_seconds,row.count)
 local options=Instance.new("TeleportOptions")
 if destination.accessCode then options.ReservedServerAccessCode=destination.accessCode else options.ServerInstanceId=destination.jobId end
 assert(not canSend or canSend(),"Room transfer cancelled or timed out")
 local teleport=self.teleport or Teleport;teleport:TeleportAsync(game.PlaceId,{player},options)
end
function Adapter:onFailure(callback)
 return Teleport.TeleportInitFailed:Connect(function(player)callback(player)end)
end
return Adapter
