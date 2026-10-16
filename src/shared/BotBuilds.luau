local Config=require(script.Parent.Parent.Generated.Gameplay)
local Rules=require(script.Parent.CombatRules)
local BotBuilds={}

BotBuilds.TIERS={
	rookie={
		{name="Starter Burst",loadout={
			body="body_standard",nose="nose_0",wings="wings_0",tail="tail_0",
			weapon_mounts={"staple","staple",false,false},
		}},
		-- The plane every new player starts with.
		{name="Classic Pellets",loadout={
			body="body_standard",nose="nose_0",wings="wings_0",tail="tail_0",
			weapon_mounts={"pellet","pellet",false,false},
		}},
		{name="Rubber Scout",loadout={
			body="body_slim",nose="nose_2",wings="wings_0",tail="tail_2",
			weapon_mounts={"rubber",false,false},
		}},
	},
	regular={
		{name="Clip Skirmisher",loadout={
			body="body_slim",nose="nose_4",wings="wings_2",tail="tail_3",
			weapon_mounts={"paperclip","pellet",false},
		}},
		{name="Guided Escort",loadout={
			body="body_standard",nose="nose_4",wings="wings_2",tail="tail_3",
			weapon_mounts={"eraser",false,"staple","staple"},
		}},
		{name="Burst Duelist",loadout={
			body="body_standard",nose="nose_4",wings="wings_3",tail="tail_1",
			weapon_mounts={"staple","staple","rubber",false},
		}},
	},
	experienced={
		{name="Clip Ace",loadout={
			body="body_slim",nose="nose_4",wings="wings_5",tail="tail_4",
			weapon_mounts={"paperclip","pellet","pellet"},
		}},
		{name="Guided Gunship",loadout={
			body="body_heavy",nose="nose_4",wings="wings_5",tail="tail_4",
			weapon_mounts={"eraser","pellet","pellet","pellet",false,false},
		}},
		{name="Pencil Interceptor",loadout={
			body="body_standard_mk2",nose="nose_4",wings="wings_5",tail="tail_4",
			weapon_mounts={"pencil",false,"pellet",false},
		}},
	},
}

function BotBuilds.weapon(catalog,weaponId,range)
	local weapon=catalog:get(weaponId)
	assert(weapon and weapon.class,"Unknown weapon: "..tostring(weaponId))
	local dps
	if weapon.fire_mode=="burst" then dps=weapon.damage*weapon.burst_count/weapon.burst_period
	else dps=weapon.damage/weapon.shot_interval end
	local time=Rules.travelTime(weapon,range) -- math.huge when out of range
	return {
		dps=dps,timeToTarget=time,leadStuds=110*time,
		spreadStuds=range*math.tan(math.rad(weapon.spread_deg))+weapon.wobble_studs,
		homing=weapon.homing,
	}
end

function BotBuilds.measure(catalog,loadout,tier)
	local profile=assert(Config.bots.profiles[tier],"Unknown bot tier: "..tostring(tier))
	local stats=assert(catalog:deriveStats(loadout))
	local speed=stats.speed*profile.speed_factor
	local pitch,yaw=stats.pitch*profile.turn_factor,stats.yaw*profile.turn_factor
	local dps,dodge,erasers,pencils=0,math.huge,0,0
	for _,id in ipairs(loadout.weapon_mounts) do
		if id~=false then
			local gun=BotBuilds.weapon(catalog,id,300)
			dps+=gun.dps
			dodge=math.min(dodge,gun.homing and 0 or gun.timeToTarget)
			if id=="eraser" then erasers+=1 end
			if id=="pencil" then pencils+=1 end
		end
	end
	return {
		health=stats.health,speed=speed,pitch=pitch,yaw=yaw,
		turnRadius=speed/math.rad(math.min(pitch,yaw)),
		dps=dps,ttk=dps>0 and Config.combat.reference_health/dps or math.huge,
		dodge=dodge,erasers=erasers,pencils=pencils,
	}
end

local function copy(value)
	if type(value)~="table" then return value end
	local result={}
	for key,item in pairs(value) do result[key]=copy(item) end
	return result
end

function BotBuilds.pick(tier,serial)
	local builds=assert(BotBuilds.TIERS[tier],"Unknown bot tier: "..tostring(tier))
	local build=builds[((serial-1)%#builds)+1]
	return copy(build.loadout),build.name
end

return BotBuilds
