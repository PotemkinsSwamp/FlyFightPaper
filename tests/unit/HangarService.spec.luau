local Root=game.ReplicatedStorage.FlyFightPaper
local Hangar=require(game.ServerScriptService.FlyFightPaper.HangarService)
local Catalog=require(Root.Shared.Catalog)
local Schema=require(Root.Shared.ProfileSchema)
local Looks=require(Root.Shared.LooksRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
	local result,test=Suite.new()
	local function fixture()
		local catalog=Catalog.new(require(Root.Generated.Catalog))
		local profile=Schema.defaults(catalog);profile.xpMilli=60000000;profile.ownership.staple=true;profile.ownership.rubber=true
		local profiles={calls={}}
		function profiles:view() return profile end
		function profiles:enqueue(_,input,_,callback)
			if self.busy then return false end
			table.insert(self.calls,input)
			if self.defer then self.pending=callback else callback(self.ok~=false) end
			return true
		end
		local player={attributes={}}
		function player:SetAttribute(key,value) self.attributes[key]=value end
		return Hangar.new({catalog=catalog,pilots={}},profiles),player,profiles,catalog,profile
	end
	test("buying a look previews without changing the profile and queues only its server purchase fields",function()
		local service,player,profiles,_,profile=fixture();local item=Looks.item("shark_jet")
		profile.paperMilli=item.paper*1000;local before=Schema.canonical(profile)
		service:handle(player,"buyLook",item.id)
		assert(#profiles.calls==1 and Schema.canonical(profiles.calls[1])==Schema.canonical({kind="lookPurchase",lookID=item.id}))
		assert(player.attributes.MenuMessage==item.name.." is yours! Wear it from the Skins tab.")
		assert(Schema.canonical(profile)==before,"purchase preview changed saved progress")
	end)
	test("look buy refusals explain ownership, low Paper, bundled trails and unknown looks without queuing",function()
		for _,case in ipairs({{"hazard_stripes",false,"You need more Paper."},{"hazard_stripes",true,"You already own it."},
			{"water_spray",false,"That trail comes with its skin."},{"missing",false,"That can't be bought."}}) do
			local service,player,profiles,_,profile=fixture()
			if case[2] then profile.looks.owned[case[1]]=true end
			local before=Schema.canonical(profile)
			service:handle(player,"buyLook",case[1])
			assert(#profiles.calls==0 and player.attributes.MenuMessage==case[3],player.attributes.MenuMessage)
			assert(Schema.canonical(profile)==before)
		end
	end)
	test("a failed queued look buy gives the requested failure message and a busy queue refuses the request",function()
		local service,player,profiles,_,profile=fixture();profile.paperMilli=Looks.item("confetti").paper*1000
		local before=Schema.canonical(profile);profiles.ok=false
		service:handle(player,"buyLook","confetti")
		assert(#profiles.calls==1 and player.attributes.MenuMessage=="The buy was not completed. Nothing changed.")
		profiles.busy=true;service:handle(player,"buyLook","confetti")
		assert(#profiles.calls==1 and player.attributes.MenuMessage=="Saving is busy. Try again shortly.")
		assert(Schema.canonical(profile)==before)
	end)
	test("wearing owned looks waits for the save before changing the current pilot and model",function()
		local service,player,profiles,_,profile=fixture();profile.looks.owned={shark_jet=true,water_spray=true}
		local model=Instance.new("Folder");model:SetAttribute("Skin","hazard_stripes");model:SetAttribute("Trail","confetti")
		local p={model=model,skin="hazard_stripes",trail="confetti"};service.flight.pilots[player]=p
		profiles.defer=true;player.attributes.MenuMessage="Keep this message."
		local before=Schema.canonical(profile);local value={skin="shark_jet",trail="water_spray"}
		service:handle(player,"wearLook",value)
		assert(#profiles.calls==1 and Schema.canonical(profiles.calls[1])==Schema.canonical({kind="lookWear",skinID="shark_jet",trailID="water_spray"}))
		assert(p.skin=="hazard_stripes" and p.trail=="confetti" and model:GetAttribute("Skin")=="hazard_stripes" and model:GetAttribute("Trail")=="confetti")
		value.skin="dragon";value.trail="dragon_embers";profiles.pending(true)
		local ok=p.skin=="shark_jet" and p.trail=="water_spray" and model:GetAttribute("Skin")==p.skin and model:GetAttribute("Trail")==p.trail
		model:Destroy()
		assert(ok and player.attributes.MenuMessage=="Keep this message.")
		assert(Schema.canonical(profile)==before,"wear preview changed saved progress")
	end)
	test("taking looks off clears the current model attributes and pilot choices without a success message",function()
		local service,player,profiles,_,profile=fixture();profile.looks={owned={shark_jet=true,water_spray=true},skin="shark_jet",trail="water_spray"}
		local model=Instance.new("Folder");model:SetAttribute("Skin","shark_jet");model:SetAttribute("Trail","water_spray")
		local p={model=model,skin="shark_jet",trail="water_spray"};service.flight.pilots[player]=p
		service:handle(player,"wearLook",{skin="",trail=""})
		local ok=#profiles.calls==1 and p.skin==nil and p.trail==nil and model:GetAttribute("Skin")==nil and model:GetAttribute("Trail")==nil
		model:Destroy();assert(ok and player.attributes.MenuMessage==nil)
	end)
	test("an unowned skin or trail refuses the entire wear request",function()
		for _,value in ipairs({{skin="dragon",trail="water_spray"},{skin="shark_jet",trail="confetti"},{skin="water_spray",trail=""}}) do
			local service,player,profiles,_,profile=fixture();profile.looks.owned={shark_jet=true,water_spray=true}
			local before=Schema.canonical(profile)
			service:handle(player,"wearLook",value)
			assert(#profiles.calls==0 and player.attributes.MenuMessage=="You don't own that yet.")
			assert(Schema.canonical(profile)==before)
		end
	end)
	test("failed wear saves keep the old pilot and model looks",function()
		local service,player,profiles,_,profile=fixture();profile.looks.owned={shark_jet=true,water_spray=true}
		local model=Instance.new("Folder");model:SetAttribute("Skin","hazard_stripes");model:SetAttribute("Trail","confetti")
		local p={model=model,skin="hazard_stripes",trail="confetti"};service.flight.pilots[player]=p;profiles.ok=false
		service:handle(player,"wearLook",{skin="shark_jet",trail="water_spray"})
		local ok=#profiles.calls==1 and p.skin=="hazard_stripes" and p.trail=="confetti" and model:GetAttribute("Skin")==p.skin and model:GetAttribute("Trail")==p.trail
		model:Destroy();assert(ok)
	end)
	test("look wear saves work from the menus and keep choices on a pilot awaiting its next model",function()
		local service,player,profiles,_,profile=fixture();profile.looks.owned={shark_jet=true,water_spray=true}
		service:handle(player,"wearLook",{skin="shark_jet",trail="water_spray"})
		assert(#profiles.calls==1 and player.attributes.MenuMessage==nil)
		local p={};service.flight.pilots[player]=p
		service:handle(player,"wearLook",{skin="shark_jet",trail="water_spray"})
		assert(#profiles.calls==2 and p.skin=="shark_jet" and p.trail=="water_spray")
	end)
	test("look actions reject malformed request values and any extra wear fields",function()
		local service,player,profiles=fixture()
		for _,value in ipairs({false,1,{},string.rep("x",161)}) do service:handle(player,"buyLook",value) end
		for _,value in ipairs({false,"skin",{},{skin=""},{trail=""},{skin=1,trail=""},{skin="",trail=false},
			{skin=string.rep("x",161),trail=""},{skin="",trail=string.rep("x",161)},
			{skin="",trail="",extra=true},{skin="",trail="",[1]="extra"}}) do service:handle(player,"wearLook",value) end
		assert(#profiles.calls==0 and player.attributes.MenuMessage==nil)
	end)
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
	test("a Range build may use parts you don't own and queues the Range's own save",function()
		local service,player,profiles,catalog=fixture();local loadout=catalog:starterLoadout()
		loadout.nose="nose_5";loadout.utility="boost_twin"
		service:handle(player,"saveRangePreset",{slot=2,loadout=loadout})
		assert(#profiles.calls==1 and profiles.calls[1].kind=="rangePreset" and profiles.calls[1].slot==2 and profiles.calls[1].name=="Range 2")
		service:handle(player,"savePreset",{slot=2,loadout=loadout})
		assert(#profiles.calls==1,"match builds still need owned parts")
	end)
	test("a name over 20 letters is refused without a save",function()
		local service,player,profiles=fixture()
		service:handle(player,"renamePreset",{range=true,slot=1,name=string.rep("a",21)})
		assert(#profiles.calls==0 and player.attributes.MenuMessage=="Names are 1 to 20 letters.")
	end)
	return result
end
return Spec
