local Root=game.ReplicatedStorage.FlyFightPaper
local BotBuilds=require(Root.Shared.BotBuilds)
local Rules=require(Root.Shared.CombatRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Config=require(Root.Generated.Gameplay)
local Spec={}
local function near(actual,expected)
	assert(math.abs(actual-expected)<1e-6,tostring(actual).." ~= "..tostring(expected))
end
-- Time for a dragged shot to cover d studs, from the closed form (not the helper under test).
local function flight(weapon,d)
	return -math.log(1-weapon.drag*d/weapon.projectile_speed)/weapon.drag
end

function Spec.run()
	local result,test=Suite.new()
	local catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
	test("weapon presets stay legal after the paperclip and rubber capacity changes",function()
		local Loadouts=require(Root.Shared.WeaponLoadouts)
		assert(catalog:get("paperclip").capacity==2 and catalog:get("rubber").capacity==2)
		for _,choice in ipairs({"pellet","staple","rubber","paperclip","eraser","eraser_only","pencil","twin_pencils"}) do
			assert(catalog:validateLoadout(Loadouts.make(catalog,choice),nil,50),choice)
		end
		local escort=BotBuilds.TIERS.regular[2].loadout
		assert(escort.weapon_mounts[3]=="staple" and escort.weapon_mounts[4]=="staple")
	end)
	test("pellets and staple bursts have the catalog sustained damage",function()
		assert(BotBuilds.weapon(catalog,"pellet",300).dps==20)
		assert(math.abs(BotBuilds.weapon(catalog,"staple",300).dps-17.5)<1e-6)
		near(BotBuilds.weapon(catalog,"rubber",300).dps,1.6/.06)
		near(BotBuilds.weapon(catalog,"paperclip",300).dps,24/1.5)
		near(BotBuilds.weapon(catalog,"paperclip",300).timeToTarget,flight(catalog:get("paperclip"),300))
		assert(BotBuilds.weapon(catalog,"pencil",300).dps==65)
		assert(BotBuilds.weapon(catalog,"eraser",300).dps==7.5)
	end)
	test("pencil fires on the click: reaction time and lead are just its flight",function()
		local gun=BotBuilds.weapon(catalog,"pencil",300)
		near(gun.timeToTarget,flight(catalog:get("pencil"),300))
		near(gun.leadStuds,110*flight(catalog:get("pencil"),300))
		near(BotBuilds.weapon(catalog,"pellet",300).timeToTarget,flight(catalog:get("pellet"),300))
	end)
	test("rubber spread includes its angle and wobble",function()
		near(BotBuilds.weapon(catalog,"rubber",300).spreadStuds,300*math.tan(math.rad(2.5))+.8)
		near(BotBuilds.weapon(catalog,"rubber",0).spreadStuds,.8)
		assert(BotBuilds.weapon(catalog,"pellet",300).spreadStuds==0)
	end)
	test("erasers are homing and the other guns are not",function()
		assert(BotBuilds.weapon(catalog,"eraser",300).homing==true)
		for _,id in ipairs({"pellet","staple","rubber","paperclip","pencil"}) do
			assert(BotBuilds.weapon(catalog,id,300).homing==false)
		end
	end)
	test("projectile lifetime includes the reach boundary but nothing beyond it",function()
		for _,weapon in ipairs(catalog.weapons) do
			local reach=Rules.shotRange(weapon)
			near(BotBuilds.weapon(catalog,weapon.id,reach).timeToTarget,weapon.lifetime)
			local beyond=BotBuilds.weapon(catalog,weapon.id,reach+.001)
			assert(beyond.timeToTarget==math.huge and beyond.leadStuds==math.huge)
		end
	end)
	test("measure uses derived health and each tier's speed and turn factors",function()
		local loadout=catalog:starterLoadout()
		loadout.wings="wings_2";loadout.tail="tail_1"
		local stats=catalog:deriveStats(loadout)
		for tier,profile in pairs(Config.bots.profiles) do
			local measured=BotBuilds.measure(catalog,loadout,tier)
			assert(measured.health==stats.health)
			near(measured.speed,stats.speed*profile.speed_factor)
			near(measured.pitch,stats.pitch*profile.turn_factor)
			near(measured.yaw,stats.yaw*profile.turn_factor)
			near(measured.turnRadius,measured.speed/math.rad(math.min(measured.pitch,measured.yaw)))
		end
	end)
	test("measure sums duplicate guns and guns after an empty mount",function()
		local loadout=catalog:starterLoadout()
		loadout.weapon_mounts={"staple",false,"pellet","staple"}
		local measured=BotBuilds.measure(catalog,loadout,"regular")
		assert(math.abs(measured.dps-55)<1e-6 and measured.erasers==0 and measured.pencils==0)
		near(measured.ttk,Config.combat.reference_health/55)
		near(measured.dodge,flight(catalog:get("pellet"),300))
	end)
	test("measure counts erasers and pencils and gives homing zero dodge time",function()
		local loadout=catalog:starterLoadout()
		loadout.body="body_heavy"
		loadout.weapon_mounts={"pencil",false,"eraser",false,false,false}
		local measured=BotBuilds.measure(catalog,loadout,"experienced")
		assert(measured.dps==72.5 and measured.erasers==1 and measured.pencils==1)
		assert(measured.dodge==0)
		near(measured.ttk,Config.combat.reference_health/72.5)
	end)
	test("an unarmed plane has infinite kill and dodge times",function()
		local loadout=catalog:starterLoadout()
		loadout.weapon_mounts={false,false,false,false}
		local measured=BotBuilds.measure(catalog,loadout,"rookie")
		assert(measured.dps==0 and measured.ttk==math.huge and measured.dodge==math.huge)
	end)
	for _,tier in ipairs({"rookie","regular","experienced"}) do
		local builds=BotBuilds.TIERS[tier]
		test(tier.." has three or four named legal level-50 builds",function()
			assert(#builds>=3 and #builds<=4)
			local names={}
			for _,build in ipairs(builds) do
				assert(type(build.name)=="string" and #build.name>0 and not names[build.name])
				names[build.name]=true
				local valid,reason=catalog:validateLoadout(build.loadout,nil,50)
				assert(valid,build.name..": "..tostring(reason))
			end
		end)
		test(tier.." picks cycle in order and return independent loadouts",function()
			for serial=1,#builds*3 do
				local build=builds[((serial-1)%#builds)+1]
				local loadout,name=BotBuilds.pick(tier,serial)
				assert(name==build.name and loadout~=build.loadout)
				for _,slot in ipairs({"body","nose","wings","tail","utility"}) do
					assert(loadout[slot]==build.loadout[slot])
					loadout[slot]="changed"
				end
				assert(loadout.weapon_mounts~=build.loadout.weapon_mounts)
				assert(#loadout.weapon_mounts==#build.loadout.weapon_mounts)
				for index,id in ipairs(build.loadout.weapon_mounts) do
					assert(loadout.weapon_mounts[index]==id)
					loadout.weapon_mounts[index]="changed"
				end
				local again=BotBuilds.pick(tier,serial)
				assert(again.body==build.loadout.body and again.utility==build.loadout.utility)
				assert(again.weapon_mounts[1]~="changed" and build.loadout.weapon_mounts[1]~="changed")
				assert(catalog:validateLoadout(build.loadout,nil,50))
			end
		end)
		test(tier.." kill times stay within 35 percent of their median",function()
			local times={}
			for _,build in ipairs(builds) do table.insert(times,BotBuilds.measure(catalog,build.loadout,tier).ttk) end
			table.sort(times)
			local middle=(#times+1)/2
			local median=(times[math.floor(middle)]+times[math.ceil(middle)])/2
			assert(median>0 and median<math.huge)
			for _,time in ipairs(times) do
				assert(time>=median*.65 and time<=median*1.35,tostring(time).." outside median "..tostring(median))
			end
		end)
	end
	test("rookies use forgiving light guns and take at least three seconds to kill",function()
		for _,build in ipairs(BotBuilds.TIERS.rookie) do
			assert(build.loadout.body=="body_standard" or build.loadout.body=="body_slim")
			for _,id in ipairs(build.loadout.weapon_mounts) do
				if id~=false then
					assert(id~="eraser" and id~="pencil" and catalog:get(id).class=="light")
				end
			end
			assert(BotBuilds.measure(catalog,build.loadout,"rookie").ttk>=3,build.name)
		end
	end)
	test("regulars have at most one paperclip or eraser and experienced have at most one pencil build",function()
		for _,build in ipairs(BotBuilds.TIERS.regular) do
			local medium=0
			for _,id in ipairs(build.loadout.weapon_mounts) do
				assert(id~="pencil")
				if id=="paperclip" or id=="eraser" then medium+=1 end
			end
			assert(medium<=1,build.name)
		end
		local pencils=0
		for _,build in ipairs(BotBuilds.TIERS.experienced) do
			if BotBuilds.measure(catalog,build.loadout,"experienced").pencils>0 then pencils+=1 end
		end
		assert(pencils<=1)
	end)
	test("D8 tier averages increase damage and turn while reducing non-homing dodge time",function()
		local previous
		for _,tier in ipairs({"rookie","regular","experienced"}) do
			local builds=BotBuilds.TIERS[tier]
			local average={dps=0,turn=0,dodge=0,unguided=0}
			for _,build in ipairs(builds) do
				local measured=BotBuilds.measure(catalog,build.loadout,tier)
				local unguided=math.huge
				-- Ignore homing's zero so guided guns cannot hide slower ordinary shots.
				for _,id in ipairs(build.loadout.weapon_mounts) do
					if id~=false then
						local gun=BotBuilds.weapon(catalog,id,300)
						if not gun.homing then unguided=math.min(unguided,gun.timeToTarget) end
					end
				end
				assert(unguided<math.huge,build.name.." needs a non-homing gun")
				average.dps+=measured.dps/#builds
				average.turn+=math.min(measured.pitch,measured.yaw)/#builds
				average.dodge+=measured.dodge/#builds
				average.unguided+=unguided/#builds
			end
			if previous then
				assert(average.dps>previous.dps,tier.." damage must increase")
				assert(average.turn>previous.turn,tier.." turn must increase")
				assert(average.dodge<previous.dodge,tier.." dodge time must decrease")
				assert(average.unguided<previous.unguided,tier.." non-homing dodge time must decrease")
			end
			previous=average
		end
	end)
	return result
end
return Spec
