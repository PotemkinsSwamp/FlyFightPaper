-- ProfileStore-shaped sessions with controllable save failure and takeover.
local Schema=require(game.ReplicatedStorage.FlyFightPaper.Shared.ProfileSchema)
local Fake={};Fake.__index=Fake
function Fake.new(data)
 return setmetatable({Data=assert(Schema.copy(data)),LastSavedData=assert(Schema.copy(data)),global_updates={},active=true,writes=0,failSave=false},Fake)
end
function Fake:IsActive() return self.active end
function Fake:Save()
 self.writes+=1
 if self.failSave then return false end
 self.LastSavedData=assert(Schema.copy(self.Data));return true
end
function Fake:EndSession()
 local saved=self:Save();if saved then self.active=false end;return saved
end
function Fake:takeover() self.active=false;return Fake.new(self.LastSavedData) end
function Fake.store(records)
 local store={records=records or {},messages={},reads=0,sends=0}
 function store:GetAsync(key)
  self.reads+=1
  if self.readError then error("fake gift read failure") end
  local profile=self.records[key]
  return profile and {Data=assert(Schema.copy(profile.LastSavedData)),global_updates=assert(Schema.copy(profile.global_updates))} or nil
 end
 function store:MessageAsync(key,message)
  self.sends+=1
  if self.sendError then error("fake gift send failure") end
  if self.failSend then return false end
  local copy=assert(Schema.copy(message));table.insert(self.messages,{key=key,message=copy})
  local profile=self.records[key]
  if profile then table.insert(profile.global_updates,{self.sends,copy}) end
  if self.deliver then self.deliver(key,copy) end
  return true
 end
 return store
end
return Fake
