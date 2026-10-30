-- Phone speed matching (Alan 2026-10-29, docs/plan/PHONE-AIM-OPTIONS.md): close behind an enemy, a phone plane eases
-- its speed down to the enemy's so it stops overshooting; no button (PC players brake with Space instead). Pure
-- numbers, so the unit tests can check the picking: FlightController feeds it the planes it can see.
-- The plane it follows is the one you are really tailing: close, near your nose AND flying your way (a plane
-- crossing in front, or coming head-on, never counts). Once following, it keeps that plane while it stays in a wider
-- cone (so a second plane passing in front doesn't steal it), and lets go after `lost_seconds` out of it.
local SpeedMatch = {}

local function degreesOff(a, b) return math.deg(math.acos(math.clamp(a:Dot(b), -1, 1))) end

-- `me`/`other`: {position, look (unit), velocity}. Inside a cone of `cone` degrees and `range` studs, flying our way.
local function tailing(me, other, cone, range, cfg)
	local offset = other.position - me.position
	local distance = offset.Magnitude
	if distance > range or distance < 1 or other.velocity.Magnitude < 1 then return false end
	return degreesOff(me.look, offset.Unit) <= cone and degreesOff(me.look, other.velocity.Unit) <= cfg.same_way_deg
end

-- Updates `memory` ({id, lostAt}) and returns the id of the plane to follow, or nil. `others`: id -> plane.
function SpeedMatch.pick(memory, me, others, now, cfg)
	local current = memory.id and others[memory.id]
	if current and tailing(me, current, cfg.keep_cone_deg, cfg.keep_range_studs, cfg) then
		memory.lostAt = nil
		return memory.id
	end
	if current and memory.lostAt == nil then memory.lostAt = now end
	if current and now - memory.lostAt < cfg.lost_seconds then return memory.id end
	memory.id, memory.lostAt = nil, nil
	local best, bestDistance = nil, math.huge
	for id, other in others do
		local distance = (other.position - me.position).Magnitude
		if distance < bestDistance and tailing(me, other, cfg.pick_cone_deg, cfg.pick_range_studs, cfg) then
			best, bestDistance = id, distance
		end
	end
	memory.id = best
	return best
end

-- The share of cruise speed to fly at behind `other`: its speed, plus a little while further back than
-- `follow_studs` so you still close in; never faster than cruise, never below `floor_factor`.
function SpeedMatch.factor(me, other, cruise, cfg)
	local distance = (other.position - me.position).Magnitude
	local wanted = other.velocity.Magnitude + math.max(0, distance - cfg.follow_studs) * cfg.close_per_stud
	return math.clamp(wanted / cruise, cfg.floor_factor, 1)
end

return SpeedMatch
