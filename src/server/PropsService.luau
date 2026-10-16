-- Only authored small flags can break. They reset once per round.
local Service={};Service.__index=Service
function Service.new(room)
 local self=setmetatable({parts={}},Service)
 for _,part in ipairs(room:GetDescendants()) do
  if part:IsA("BasePart") and part.Name:match("^Prop_Flag%d+$") then self.parts[part]={transparency=part.Transparency,query=part.CanQuery,collide=part.CanCollide} end
 end
 return self
end
function Service:breakPart(part)
 if not self.parts[part] or part:GetAttribute("Broken") then return false end
 part:SetAttribute("Broken",true);part.Transparency=1;part.CanQuery=false;part.CanCollide=false;return true
end
function Service:reset()
 for part,original in pairs(self.parts) do
  part:SetAttribute("Broken",false);part.Transparency=original.transparency;part.CanQuery=original.query;part.CanCollide=original.collide
 end
end
return Service
