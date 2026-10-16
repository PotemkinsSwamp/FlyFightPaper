-- Resource and validation rules. Roblox owns movement and collision geometry.
local Rules = {}
local Config = require(script.Parent.Parent.Generated.Gameplay).flight

function Rules.finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Rules.vector(value)
	return typeof(value) == "Vector3" and Rules.finite(value.X) and Rules.finite(value.Y) and Rules.finite(value.Z)
end
function Rules.lift(current, maximum, dt)
	return math.clamp(current - math.max(0, dt), 0, maximum)
end
-- An upward fan adds Lift for as long as the plane stays in its gust, every pass (Alan, 2026-10-13).
function Rules.fanLift(current, maximum, dt)
	return math.min(maximum, current + Config.fan_lift_per_second * dt)
end
function Rules.limitPitch(direction)
 local limit=math.sin(math.rad(Config.pitch_limit_deg))
 if math.abs(direction.Y)<=limit then return direction end
 local flat=Vector3.new(direction.X,0,direction.Z)
 if flat.Magnitude<.001 then flat=Vector3.new(0,0,-1) end
 return flat.Unit*math.cos(math.rad(Config.pitch_limit_deg))+Vector3.yAxis*math.sign(direction.Y)*limit
end
function Rules.turnDirection(current, desired, radians)
 local angle=math.acos(math.clamp(current:Dot(desired),-1,1))
 if angle<=radians or angle<.0001 then return desired end
 -- Rotate along the shortest arc; a straight reversal turns flat rather than looping.
 local axis=current:Cross(desired)
 if axis.Magnitude<1e-4 then axis=Vector3.yAxis end
 return CFrame.fromAxisAngle(axis.Unit,radians):VectorToWorldSpace(current).Unit
end
-- Mouse-aim autopilot shared by players and scripted pilots: steer the nose toward an aim
-- direction at the loadout's turn rate, easing in near the target so it never overshoots.
-- Banks hard into big turns and levels the wings when the aim sits near the nose.
-- `up` is the pilot's sky direction. Players pass their aim's up, so loops and inverted flight work;
-- without it (bots for now) the world is up and pitch stays within the limit.
-- `yaw` (wings) limits left/right turning and `pitch` (tail) up/down; diagonal turns blend the two.
function Rules.autopilot(heading, bank, aim, yaw, pitch, dt, up)
 if not up then aim=Rules.limitPitch(aim) end
 local sky=up or Vector3.yAxis
 local function frameFor(look)
  local flatUp=sky-look*look:Dot(sky)
  if flatUp.Magnitude<1e-3 then flatUp=look:Cross(math.abs(look.X)<.9 and Vector3.xAxis or Vector3.zAxis):Cross(look) end
  return CFrame.lookAt(Vector3.zero,look,flatUp.Unit)
 end
 local before=frameFor(heading):VectorToObjectSpace(aim)
 local side=math.abs(before.X)/math.max(1e-6,math.sqrt(before.X^2+before.Y^2))
 local turn=math.sqrt((yaw*side)^2+(pitch*math.sqrt(1-side^2))^2)
 local angle=math.acos(math.clamp(heading:Dot(aim),-1,1))
 local step=math.min(math.rad(turn)*dt,angle*(1-math.exp(-Config.autopilot_settle_per_s*dt)))
 heading=Rules.turnDirection(heading,aim,step)
 if not up then heading=Rules.limitPitch(heading) end
 local frame=frameFor(heading)
 local around=frame:VectorToObjectSpace(aim)
 local lateral=around.X/math.max(1e-3,math.sqrt(around.X^2+around.Y^2))
 local target=-lateral*math.clamp(angle/math.rad(Config.autopilot_full_bank_deg),0,1)*math.rad(Config.bank_visual_limit_deg)
 bank+=(target-bank)*(1-math.exp(-Config.bank_response*dt))
 return heading,bank,frame*CFrame.Angles(0,0,bank)
end
-- When the pilot stops steering, roll the aim back toward the sky so diagonal mouse moves don't leave the
-- view tilted. Skipped near straight up or down, where "sky" has no direction.
function Rules.levelAim(frame, dt)
 local look=frame.LookVector
 if math.abs(look.Y)>.95 then return frame end
 local target=(Vector3.yAxis-look*look.Y).Unit
 local up=frame.UpVector
 local angle=math.atan2(up:Cross(target):Dot(look),up:Dot(target))
 local limit=Config.aim_auto_level_per_s*dt
 return CFrame.fromAxisAngle(look,math.clamp(angle,-limit,limit))*frame
end
-- Hard turns cost speed: turning at the full rate keeps (1 - turn_speed_bleed) of cruise.
function Rules.turnSpeedFactor(before, after, dt, turn)
 local used=math.acos(math.clamp(before:Dot(after),-1,1))/math.max(1e-6,math.rad(turn)*dt)
 return 1-Config.turn_speed_bleed*math.clamp(used,0,1)
end
-- Out of Lift the plane glides on its momentum (Alan, 2026-10-13): diving speeds it up (past cruise, up to
-- `glide_max_speed_factor` times it), flying level or climbing slows it, so a dive can be traded for a climb. `glide` is the speed so far (nil = just ran out, at cruise).
-- The steady glide angle (the old fixed glide) neither gains nor loses; at stall speed the plane can only sink.
function Rules.glide(glide, direction, cruise, dt)
	local stall = cruise * Config.empty_lift_speed_factor
	local slope = Config.empty_lift_descent_studs_s / stall
	return math.clamp((glide or cruise) + Config.glide_gravity_studs_s2 * (-direction.Unit.Y - slope) * dt, stall, cruise * Config.glide_max_speed_factor)
end
-- Out of Lift the plane flies along its nose at the glide speed. Nearing stall, the climb part fades out and a
-- sink fades in, reaching a flat sink-only glide at stall. It changes smoothly with speed: an on/off switch here
-- flipped every frame during turns (no sink, then sink), the server read the no-sink frames as an illegal climb
-- and snapped the plane back 4 times a second (Alan's camera jitter, worst on slow heavy planes).
-- With Lift left, diving still builds speed and pulling up spends it (Alan's note 5: it's physics), but bounded:
-- never more than `lift_dive_max_speed_factor` times cruise, never below cruise, and level flight eases back to
-- cruise. `momentum` is the speed so far (nil = at cruise).
function Rules.dive(momentum, direction, cruise, dt)
	momentum = momentum or cruise
	local change = Config.glide_gravity_studs_s2 * -direction.Unit.Y - Config.lift_dive_return_per_s * (momentum - cruise)
	return math.clamp(momentum + change * dt, cruise, cruise * Config.lift_dive_max_speed_factor)
end
function Rules.velocity(direction, speed, lift, updraft, glide, cruise)
	if lift > 0 then return direction * speed + Vector3.new(0, updraft, 0) end
	cruise = cruise or speed
	local stall = cruise * Config.empty_lift_speed_factor
	glide = math.clamp(glide or stall, stall, cruise * Config.glide_max_speed_factor)
	local above = math.clamp((glide - stall) / (cruise - stall), 0, 1)
	local velocity = direction * glide
	if velocity.Y > 0 then
		local flat = Vector3.new(direction.X, 0, direction.Z)
		velocity = (flat.Magnitude < 0.01 and Vector3.new(0, 0, -1) or flat.Unit):Lerp(direction, above).Unit * glide
	end
	return velocity + Vector3.new(0, updraft - Config.empty_lift_descent_studs_s * (1 - above), 0)
end
-- Does the straight path a->b cross the world-axis box (centre, size)? Speed power-up holes are boxes measured
-- around each opening, so a plane passing between server checks still counts (slab test).
function Rules.segmentHitsBox(centre, size, a, b)
	local lo, hi, d = 0, 1, b - a
	for _, axis in ipairs({ "X", "Y", "Z" }) do
		local min, max = centre[axis] - size[axis] / 2, centre[axis] + size[axis] / 2
		if math.abs(d[axis]) < 1e-6 then
			if a[axis] < min or a[axis] > max then return false end
		else
			local t1, t2 = (min - a[axis]) / d[axis], (max - a[axis]) / d[axis]
			lo, hi = math.max(lo, math.min(t1, t2)), math.min(hi, math.max(t1, t2))
			if lo > hi then return false end
		end
	end
	return true
end
-- Alan's rule: each power-up adds its bonus and restarts the timer; the time itself never adds up.
function Rules.stackPickup(bonus, untilTime, now, pickups)
	local live = now < untilTime and bonus or 0
	return math.min(live + pickups.speed_bonus, pickups.max_bonus), now + pickups.seconds
end
function Rules.movementAllowed(previous, position, velocity, elapsed, speed)
	if not Rules.vector(position) or not Rules.vector(velocity) then return false end
	local limit = speed * Config.horizontal_fan_speed_factor + 28
	return velocity.Magnitude <= limit * 1.6 and (position - previous).Magnitude <= limit * elapsed + 16
end
function Rules.turnAllowed(previousLook, look, elapsed, turn)
	local angle = math.acos(math.clamp(previousLook:Dot(look), -1, 1))
	return angle <= math.rad(turn) * Config.orientation_angular_headroom * elapsed + math.rad(25)
end
-- Empty Lift: never higher than the fastest speed Lift allows (a dive with Lift: lift_dive_max_speed_factor x cruise)
-- could carry the plane when Lift ran out (v^2 / 2g above stall),
-- less half the glide's sink for every second since, plus fan updrafts. Counted from that moment, not per check,
-- so a jittery speed reading can't trip it.
function Rules.climbAllowed(y, emptyY, cruise, seconds, updraftGain)
	local stall = cruise * Config.empty_lift_speed_factor
	local held = cruise * Config.lift_dive_max_speed_factor
	return y <= emptyY + (held ^ 2 - stall ^ 2) / (2 * Config.glide_gravity_studs_s2)
		- Config.empty_lift_descent_studs_s * 0.5 * seconds + updraftGain + 10
end
-- Flying into a surface faster than the crash speed (nose-first, side-on) destroys the plane. A shallow
-- scrape or belly slide costs health that grows the longer contact lasts (doubling every few tenths of a second):
-- a quick touch is cheap, a long slide is deadly, and pulling up in time saves the plane.
-- `normalSpeed` is how fast the plane was moving into the surface; `touching` is how long contact has lasted.
function Rules.collisionDamage(normalSpeed, emptyOnFloor, maximum, dt, touching)
	local combat = require(script.Parent.Parent.Generated.Gameplay).combat
	if emptyOnFloor or normalSpeed >= combat.collision_crash_speed then return maximum end
	return maximum * combat.collision_scrape_health_per_second * 2 ^ ((touching or 0) / combat.collision_scrape_doubling_seconds) * dt
end
-- Which solid part a plane's exact-shape Colliders touch, and that surface's outward normal. Shared by the
-- server (damage) and the pilot's client (stops the plane at the surface at once instead of a moment later).
function Rules.contact(model, travel, overlap, single)
	local colliders = model:FindFirstChild("Colliders")
	local body = model:FindFirstChild("Root")
	if not colliders or not body then return nil end
	-- Cheap gate first: anything solid near the flight body at all?
	if #workspace:GetPartBoundsInBox(body.CFrame, (model:GetAttribute("ContactSize") or body.Size) * 1.5, overlap) == 0 then return nil end
	for _, piece in ipairs(colliders:GetChildren()) do
		local touching = workspace:GetPartsInPart(piece, overlap)[1]
		if touching then
			-- The face it entered: look back along the flight path; a side scrape falls back to the nearest surface.
			single.FilterDescendantsInstances = { touching }
			local reach = piece.Size.Magnitude + 10
			local face = workspace:Raycast(piece.Position - travel * reach, travel * reach * 2, single)
			if face then return touching, face.Normal end
			local offset = piece.Position - touching:GetClosestPointOnSurface(piece.Position)
			return touching, offset.Magnitude > .01 and offset.Unit or -travel
		end
	end
	return nil
end
return table.freeze(Rules)
