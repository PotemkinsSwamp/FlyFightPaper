local Rules = {}
local Config = require(script.Parent.Parent.Generated.Gameplay).combat
-- The first filled mount's type goes on left click; every mount of the other type goes on right click.
function Rules.triggerGroups(loadout)
	local groups,types,count={},{},0
	for slot,id in ipairs(loadout.weapon_mounts) do
		groups[slot]=false
		if id and id~="" then
			if not types[id] then
				count+=1;if count>2 then return nil,"two weapon types per plane" end
				types[id]=count
			end
			groups[slot]=types[id]
		end
	end
	return groups
end
-- Fold credit (Alan 2026-10-17): only damage in the last assist_window_seconds, and none from before the victim's last
-- repair (`since`), counts. The last hit gets the fold, unless another pilot did at least fold_majority_fraction of
-- the plane's health and more than the last hitter: then that pilot gets it, and the last hitter is the `finisher`
-- (always an assist, plus a finishing bonus). No stealing a fold with one shot; finishing still pays.
function Rules.credit(history, now, maximum, victim, since)
	local damage, total, last, latest = {}, 0, nil, -math.huge
	for _, hit in ipairs(history) do
		if hit.attacker ~= victim and hit.at <= now and now-hit.at <= Config.assist_window_seconds and hit.at >= (since or -math.huge) then
			damage[hit.attacker] = (damage[hit.attacker] or 0)+hit.damage
			total += hit.damage
			if hit.at >= latest then last, latest = hit.attacker, hit.at end
		end
	end
	local killer, finisher = last, nil
	for attacker, amount in pairs(damage) do
		if attacker ~= last and amount >= maximum*Config.fold_majority_fraction and amount > (damage[killer] or 0) then killer = attacker end
	end
	if killer ~= last then finisher = last end
	local assists = {}
	for attacker, amount in pairs(damage) do
		if attacker ~= killer and (attacker == finisher or amount >= maximum*Config.assist_min_fraction_original_health) then table.insert(assists,attacker) end
	end
	table.sort(assists)
	return killer, assists, damage, total, finisher
end
function Rules.readyMount(mounts, group, now, after, fireMode)
	for offset=1,#mounts do
		local index = ((after or 0)+offset-1)%#mounts+1
		local mount = mounts[index]
		if mount.group == group and mount.readyAt <= now and (not fireMode or mount.weapon.fire_mode==fireMode) then return index end
	end
	return nil
end
-- Like a real seeker: a target that gets too far off the eraser's nose is lost (nil) for good.
-- A hard break turn timed as the eraser closes in is how you dodge.
function Rules.eraserSteer(direction, toTarget, dt)
	if direction:Dot(toTarget) < math.cos(math.rad(Config.eraser_seeker_deg)) then return nil end
	return Rules.turnDirection(direction, toTarget, math.rad(Config.eraser_turn_deg_s)*dt)
end
function Rules.canEraser(active)
	return active < Config.eraser_max_active_per_pilot
end
function Rules.eraserSpeed(baseSpeed, flownStuds, config)
	config = config or Config
	local slow = math.clamp((flownStuds-config.eraser_slow_after_studs)/(config.eraser_slow_full_studs-config.eraser_slow_after_studs),0,1)
	return baseSpeed*(1-slow*(1-config.eraser_min_speed_factor))
end
-- Unguided shots start fast, lose speed to drag (k, 1/s) and fall (g, studs/s^2). Never used for homing weapons.
function Rules.shotDistance(weapon, t)
	local v,k=weapon.projectile_speed,weapon.drag or 0
	return k>0 and v/k*(1-math.exp(-k*t)) or v*t
end
function Rules.shotSpeed(weapon, t)
	return weapon.projectile_speed*math.exp(-(weapon.drag or 0)*t)
end
-- Seconds to cover d studs along the aim line; math.huge when out of range.
function Rules.travelTime(weapon, d)
	local v,k=weapon.projectile_speed,weapon.drag or 0
	local t=d/v
	if k>0 then
		local x=k*d/v
		if x>=1 then return math.huge end
		t=-math.log(1-x)/k
	end
	return t>weapon.lifetime+1e-9 and math.huge or t
end
-- Where to aim a shot of `weapon` fired from `from` now, at a target that will be at `ahead(t)` t seconds from now
-- (the lead ring, FlightHUD): the travel time is found by a few rounds of guessing, and the aim rises by the drop.
function Rules.lead(weapon, from, ahead)
	local lead=ahead(0)
	for _=1,4 do
		local t=Rules.travelTime(weapon,(lead-from).Magnitude)
		if t==math.huge then t=weapon.lifetime end
		lead=ahead(t)+Vector3.yAxis*(0.5*(weapon.drop or 0)*t*t)
	end
	return lead
end
function Rules.shotOffset(weapon, direction, t)
	return direction*Rules.shotDistance(weapon,t)-Vector3.yAxis*(0.5*(weapon.drop or 0)*t*t)
end
function Rules.shotRange(weapon)
	return Rules.shotDistance(weapon,weapon.lifetime)
end
-- A held trigger keeps its heat between shots. Cooling drains even while held, and stays latched until empty.
function Rules.heatStep(heat, cooling, firing, dt, weapon)
	if not weapon.shots_before_cooldown then return 0,false end
	if cooling or not firing then heat=math.max(0,heat-weapon.shots_before_cooldown/weapon.cooldown_seconds*math.max(0,dt)) end
	if heat<1e-9 then return 0,false end
	return heat,cooling
end
-- The shot reaching the limit still fires; subsequent shots wait for a complete cooldown.
function Rules.heatShot(heat, cooling, weapon)
	local limit=weapon.shots_before_cooldown
	if not limit then return 0,false,true end
	if cooling or heat>=limit then return heat,true,false end
	heat=math.min(limit,heat+1)
	return heat,heat>=limit,true
end
function Rules.consume(mount, now)
	if mount.weapon.fire_mode~="burst" then mount.readyAt=now+mount.weapon.shot_interval end
end
Rules.turnDirection = require(script.Parent.FlightRules).turnDirection
-- Lag compensation: where a plane was at time `at`, from its recent {at, cf} samples (oldest first).
function Rules.sample(track, at)
	local count = #track
	if count == 0 then return nil end
	if at >= track[count].at then return track[count].cf end
	for i = count-1, 1, -1 do
		local a = track[i]
		if a.at <= at then
			local b = track[i+1]
			return a.cf:Lerp(b.cf, (at-a.at)/(b.at-a.at))
		end
	end
	return track[1].cf
end
-- Earliest fraction (0 to 1) of a shot's path that enters a plane's box, or nil if it misses.
function Rules.segmentBox(origin, delta, cf, half)
	local start, step = cf:PointToObjectSpace(origin), cf:VectorToObjectSpace(delta)
	local enter, exit = 0, 1
	for _, axis in ipairs({"X", "Y", "Z"}) do
		local p, v, h = start[axis], step[axis], half[axis]
		if math.abs(v) < 1e-9 then
			if math.abs(p) > h then return nil end
		else
			local a, b = (-h-p)/v, (h-p)/v
			if a > b then a, b = b, a end
			enter, exit = math.max(enter, a), math.min(exit, b)
			if enter > exit then return nil end
		end
	end
	return enter
end

-- Hidden paper targets (Alan 2026-10-13): a kid-drawn sign standing on a rooftop. `row` = world.paper_targets entry
-- ({ at = roof point, yaw = degrees }); the pose is the sign's centre, facing along its look vector.
Rules.PAPER_TARGET_HALF = Vector3.new(7.2, 8.4, 0.6) -- 20% larger (Alan 2026-10-14)
function Rules.paperTargetPose(row)
	return CFrame.new(row.at[1], row.at[2] + Rules.PAPER_TARGET_HALF.Y, row.at[3]) * CFrame.Angles(0, math.rad(row.yaw or 0), 0)
end
-- Chalk eraser cloud (MILESTONES D14): the server stamps CloudAt/CloudUntil on workspace.Arena.ChalkEraser when it is
-- shot. A live cloud blocks sight like a building (Alan 2026-10-15): no lock-on, aim assist, bot sighting, screen
-- marker, outline or name tag on a line that passes through it, into it or out of it.
-- `chalk` = world.chalk_eraser. The cloud keeps its full radius for the first half of its life, then shrinks as it
-- thins out (Alan 2026-10-15) down to 15%, and is gone at the end.
function Rules.chalkRadius(chalk, untilAt, now)
	local left = untilAt and untilAt - now or 0
	return left > 0 and chalk.radius * math.clamp(left / (chalk.seconds * 0.5), 0.15, 1) or 0
end
function Rules.chalkBlocks(eraser, from, to, now, chalk)
	local center = eraser and eraser:GetAttribute("CloudAt")
	if not center then return false end
	local line = to - from
	local along = line:Dot(line) > 1e-6 and math.clamp((center - from):Dot(line) / line:Dot(line), 0, 1) or 0
	return (from + line * along - center).Magnitude < Rules.chalkRadius(chalk, eraser:GetAttribute("CloudUntil"), now)
end
return table.freeze(Rules)
