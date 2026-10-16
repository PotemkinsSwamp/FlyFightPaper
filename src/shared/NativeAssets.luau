-- Runtime avatars and aircraft must not stand in for missing authored map assets.
local Tags=game:GetService("CollectionService")
local Assets={}
local TAG="FlyFightPreload"
function Assets.mark(root)
 local descendants=root:GetDescendants()
 for _,item in ipairs(descendants) do Tags:AddTag(item,TAG) end
 root:SetAttribute("StaticDescendantCount",#descendants)
end
function Assets.ready(root)
 local expected=root:GetAttribute("StaticDescendantCount")
 if type(expected)~="number" then return false end
 local count=0
 for _,item in ipairs(Tags:GetTagged(TAG)) do if item:IsDescendantOf(root) then count+=1 end end
 return count>=expected
end
return Assets
