-- Bot tactics (Alan 2026-11-08): each build's trick, where a bot brakes or holds off, and when it leaves its target
-- for a damaged one. Pure rules; BotService flies them. Skill numbers: config/gameplay.json bots.profiles
-- (trick_reliability, trick_error, switch_judgment; see bots.tricks_comment).
local Tactics = {}

Tactics.BRAKE_STUDS = 80 -- where a perfect pilot starts braking behind its target
Tactics.HOLD_STUDS = 300 -- a Crayon stand-off's distance (Alan: 200-400)
Tactics.DAMAGED = 0.5 -- health share at which a plane is worth stealing
Tactics.DART_BLAST = 1.5 -- seconds a Popper dart fires before it boosts out
Tactics.SPIT_WANT = 2 -- spitballs stuck on the target before the other gun takes over

-- The trick comes from the build's guns: a Popper darts in and out, a Crayon stands off, a Spitball goes first;
-- anything else turn-fights with the brake.
function Tactics.trick(weaponIds)
	local has = {}
	for _, id in ipairs(weaponIds) do
		if id then has[id] = true end
	end
	return has.popper and "dart" or has.crayon and "standoff" or has.spitball and "spitball" or "turnfight"
end

-- One approach on a target. roll(a, b) gives a number between a and b. Returns where this approach brakes (0: the
-- pilot fumbles the trick this time) and the stand-off distance. A sloppy pilot mostly brakes too early, sometimes late.
function Tactics.approach(profile, roll)
	local hold = Tactics.HOLD_STUDS + roll(-1, 1) * 100 * profile.trick_error
	if roll(0, 1) >= profile.trick_reliability then return 0, hold end
	local spread = Tactics.BRAKE_STUDS * profile.trick_error
	return Tactics.BRAKE_STUDS + roll(-0.3 * spread, spread), hold
end

-- Leave the current target (health share, nil = none in sight) for a damaged one in view? Judged well (smart): finish
-- the plane you're about to fold, and never hop from one damaged plane to another (Alan: fewer points over time).
-- Judged badly: go for whichever looks weaker.
function Tactics.shouldSteal(current, candidate, smart)
	if candidate > Tactics.DAMAGED then return false end
	if current == nil then return true end
	if smart then return current > Tactics.DAMAGED end
	return candidate < current
end

return Tactics
