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
		-- A big body for health with speed parts around it, so it can carry better guns; still slowish (Alan's way).
		{name="Crayon Tank",loadout={
			body="body_heavy_mk2",nose="nose_1",wings="wings_1",tail="tail_1",
			weapon_mounts={"crayon",false,false,false,"rubber","rubber"},
		}},
		-- A fast plane on a moderate body with the Popper: zip in, brake, fire, zip out (Alan's way).
		{name="Popper Dart",loadout={
			body="body_standard",nose="nose_1",wings="wings_1",tail="tail_1",
			weapon_mounts={false,"popper","staple","staple"},
		}},
		-- Rubber bands to hurt, spitballs to slow the target down for them.
		{name="Spitball Hunter",loadout={
			body="body_standard_mk2",nose="nose_2",wings="wings_2",tail="tail_2",
			weapon_mounts={"rubber","rubber","spitball",false},
		}},
		-- Steady tacks close in, staple bursts further out; good turning.
		{name="Tack Skirmisher",loadout={
			body="body_standard_mk2",nose="nose_3",wings="wings_3",tail="tail_3",
			weapon_mounts={"thumbtack","thumbtack","staple","staple"},
		}},
	},
}
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
