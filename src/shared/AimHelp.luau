-- Aim help for phone players (Alan 2026-10-23; docs/research/TOUCH-AIM-RESEARCH-2026-10-23.md). Mouse players keep
-- the plain gun assist (combat.gun_assist_deg, a hard edge: inside it shots go to the lead marker). Touch gets a wider
-- one that fades out towards its edge, and the aim slows down a little while it passes over an enemy's lead.
-- Pure numbers, so the unit tests can check them; the game reads them in CombatEffects, FlightHUD and FlightController.
local AimHelp = {}

-- How much of a shot bends from the nose to the lead marker (0 none, 1 all the way), `angle` degrees off it at
-- `range` studs. Mouse: `touch` is nil.
function AimHelp.bend(combat, angle, range, touch)
	if not touch then return angle <= combat.gun_assist_deg and 1 or 0 end
	local cone = combat.touch_gun_assist_deg
	if range > combat.touch_assist_max_range_studs or angle >= cone then return 0 end
	local inner = cone * combat.touch_assist_inner_fraction
	if angle <= inner then return 1 end
	return 1 - (angle - inner) / (cone - inner)
end

-- The share of the stick's turn that is kept (1 = full speed) with the aim `angle` degrees off an enemy's lead,
-- `inside` seconds after it came within the slowdown cone. `away`: the stick is taking the aim further off it, so past
-- the middle of the cone the pilot is choosing to leave and nothing holds them back.
function AimHelp.slowdown(combat, angle, inside, away)
	local cone = combat.touch_slowdown_cone_deg
	if angle >= cone or (away and angle > cone * 0.5) then return 1 end
	local ease = math.clamp(inside / combat.touch_slowdown_ease_in_s, 0, 1)
	return 1 - (1 - combat.touch_slowdown_scale) * ease
end

return AimHelp
