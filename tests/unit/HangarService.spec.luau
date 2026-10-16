local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Catalog=require(Root.Shared.Catalog)
local Schema=require(Root.Shared.ProfileSchema)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
	local result,test=Suite.new()
	local function fixture()
		local catalog=Catalog.new(require(Root.Generated.Catalog))
		local profile=Schema.defaults(catalog);profile.xpMilli=60000000;profile.ownership.staple=true;profile.ownership.rubber=true
		local profiles={calls={}}
		function profiles:view() return profile end
		function profiles:enqueue(_,input,_,callback) table.insert(self.calls,input);callback(true);return true end
		local player={attributes={}}
		function player:SetAttribute(key,value) self.attributes[key]=value end
		return Hangar.new({catalog=catalog,pilots={}},profiles),player,profiles,catalog
	end
	test("saving a third type returns the hangar's button rule and never queues a save",function()
		local service,player,profiles,catalog=fixture();local loadout=catalog:starterLoadout()
		loadout.weapon_mounts={"pellet","staple","rubber",false}
		service:handle(player,"savePreset",{slot=1,name="Too many types",loadout=loadout})
		assert(player.attributes.MenuMessage=="Two weapon types per plane: one for left click, one for right click." and #profiles.calls==0)
	end)
	test("saving repeated mounts of two types still queues the normal preset operation",function()
		local service,player,profiles,catalog=fixture();local loadout=catalog:starterLoadout()
		loadout.weapon_mounts={"staple","pellet","staple","pellet"}
		service:handle(player,"savePreset",{slot=1,name="Two types",loadout=loadout})
		assert(#profiles.calls==1 and profiles.calls[1].kind=="preset")
		assert(Schema.canonical(profiles.calls[1].loadout)==Schema.canonical(loadout))
	end)
	return result
end
return Spec
