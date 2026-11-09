local Config=require(script.Parent.Parent.Generated.Gameplay)
local Rules=require(script.Parent.CombatRules)
local BotBuilds={}

local catalog=require(script.Parent.Catalog).new(require(script.Parent.Parent.Generated.Catalog),Config)
-- Rookies fly the presets a new player has (level 1), regulars every preset but the Marksman, veterans their own builds
-- made the way a player builds (Alan 2026-11-08). No bot carries a Paperclip, Eraser or Pencil.
local function presets(maxLevel)
	local list={}
	for _,class in ipairs(catalog:classes()) do
		if class.id~="marksman" and class.min_level<=maxLevel then
			table.insert(list,{name=class.name,loadout=catalog:classLoadout(class.id,50)})
		end
	end
	return list
end
BotBuilds.TIERS={
	rookie=presets(1),
	regular=presets(math.huge),
	experienced={
		-- Tanks: a big body with speed parts and a Pellet in every slot, the strongest reasonable tank once Staples weighed 2
		-- (Alan 2026-11-08; replaced the Staple Tank). The Cardboard one checks whether that body still dominates.
		{name="Pellet Tank",loadout={
			body="body_heavy_mk2",nose="nose_3",wings="wings_3",tail="tail_3",
			weapon_mounts={"pellet","pellet","pellet","pellet","pellet"},
		}},
		{name="Cardboard Tank",loadout={
			body="body_heavy",nose="nose_3",wings="wings_3",tail="tail_3",
			weapon_mounts={"pellet","pellet","pellet","pellet","pellet","pellet"},
		}},
		-- A fast plane on a moderate body with the Popper: zip in, brake, fire, zip out (Alan's way).
		-- (a booster to zip in and out: BotTactics' dart, Alan 2026-11-08).
		{name="Popper Dart",loadout={
			body="body_standard",nose="nose_1",wings="wings_1",tail="tail_1",utility="boost_band",
			weapon_mounts={false,"popper","pellet","pellet"},
		}},
		-- Spitballs on a medium plane (Alan 2026-11-08): too fast and it just catches up and brakes; a medium plane
		-- sometimes can't catch small ones, so it slows them or makes them fall. Two ways to finish them: Rubber Bands at
		-- medium range, or the Point Popper up close. Both: Mk2 body, Nose 1, Wings 3, Tail 3 (105 studs/s, tight turns).
		{name="Spitball Hunter",loadout={
			body="body_standard_mk2",nose="nose_1",wings="wings_3",tail="tail_3",
			weapon_mounts={"rubber","rubber","spitball",false},
		}},
		{name="Spitball Popper",loadout={
			body="body_standard_mk2",nose="nose_1",wings="wings_3",tail="tail_3",
			weapon_mounts={"spitball","popper",false,false},
		}},
		-- Steady tacks close in, Pellets further out; good turning.
		{name="Tack Skirmisher",loadout={
			body="body_standard_mk2",nose="nose_3",wings="wings_3",tail="tail_3",
			weapon_mounts={"thumbtack","thumbtack","pellet","pellet"},
		}},
	},
}
-- Aces (Alan 2026-11-08) fly the veterans' builds, better.
BotBuilds.TIERS.ace=BotBuilds.TIERS.experienced
function BotBuilds.weapon(catalog,weaponId,range)
	local weapon=catalog:get(weaponId)
	assert(weapon and weapon.class,"Unknown weapon: "..tostring(weaponId))
	local dps
	if weapon.fire_mode=="burst" then dps=weapon.damage*weapon.burst_count/weapon.burst_period
	else dps=weapon.damage*(weapon.leads or 1)/weapon.shot_interval end
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
	local speed=stats.speed
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
