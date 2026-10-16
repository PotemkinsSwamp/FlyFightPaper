-- ProfileStore-shaped sessions with controllable save failure and takeover.
local Schema=require(game.ReplicatedStorage.FlyFightPaper.Shared.ProfileSchema)
local Fake={};Fake.__index=Fake
function Fake.new(data)
 return setmetatable({Data=assert(Schema.copy(data)),LastSavedData=assert(Schema.copy(data)),active=true,writes=0,failSave=false},Fake)
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
return Fake
