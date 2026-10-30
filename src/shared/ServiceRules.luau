-- Pure service arithmetic. No engine, wallet, clock, or persistence access.
local Rules = {}
function Rules.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Rules.copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = Rules.copy(item) end
    return out
end
function Rules.repair(H, M, h)
    if not Rules.finite(H) or not Rules.finite(M) or not Rules.finite(h)
        or H <= 0 or M < 0.6 * H or M > H or h < 0 or h > M then
        return nil, "invalid_health_bounds"
    end
    -- In exact arithmetic result never exceeds M. Clamp floating-point residue only.
    local result = math.min(M, math.max(0.6 * H, (M + 0.2 * h) / 1.2))
    if result <= h then return { health = h, lifeMaxHealth = M, restored = 0, wear = 0 } end
    return { health = result, lifeMaxHealth = result, restored = result - h, wear = M - result }
end
function Rules.protection(used, total)
    local remaining = math.max(0, total - used)
    return { remaining = remaining, warning = remaining <= 0 and "expired"
        or remaining <= 10 and "10_seconds" or remaining <= 30 and "30_seconds" or nil }
end
-- Hangar safety (Alan, 2026-10-11): `remaining` seconds of protection run down while you sit in your hangar. Once
-- you have been out of it for `refillAfter` seconds in a row it is full again (a kill also refills it, see
-- CombatService), so leaving and darting straight back in gains nothing. Returns remaining, seconds out.
function Rules.hangarSafety(remaining, outFor, inHangar, dt, full, refillAfter)
    if inHangar then return math.max(0, remaining - dt), 0 end
    outFor += dt
    return outFor >= refillAfter and full or remaining, outFor
end
-- Menu click budget: up to `burst` quick clicks land, then one per `interval` seconds.
-- Returns whether this click lands and the tokens left after it.
function Rules.clickBudget(tokens, last, now, burst, interval)
    tokens = math.min(burst, (tokens or burst) + (now - (last or now)) / interval)
    if tokens < 1 then return false, tokens end
    return true, tokens - 1
end
-- Landing (Alan, 2026-10-11): a desk slot's `home` sits on its pad facing the room (LookVector). The approach ring
-- hangs `approach_out_studs` out over the room and `approach_up_studs` up; the hangar is `hangar_back_studs` behind.
function Rules.approach(home, cfg)
    return home * CFrame.new(0, cfg.approach_up_studs, -cfg.approach_out_studs)
end
function Rules.hangar(home, cfg)
    return home * CFrame.new(0, 0, cfg.hangar_back_studs)
end
-- Takeoff (Alan, 2026-10-13): from the hangar the plane rolls level down the runway, speeding up from rest, lifts
-- off `takeoff_liftoff_out_studs` out from the pad and climbs in a straight line through the ring's centre, ending
-- `takeoff_exit_studs` past it at full `speed`. Returns {cframe, seconds} legs; the first leg is meant to ease in
-- (Quad In ends at twice its average speed, so its time is 2 * distance / speed).
function Rules.takeoff(home, cfg, speed)
    local hangar = Rules.hangar(home, cfg)
    local liftoff = home * CFrame.new(0, 0, -cfg.takeoff_liftoff_out_studs)
    local ring = Rules.approach(home, cfg).Position
    local climb = (ring - liftoff.Position).Unit
    local exit = ring + climb * cfg.takeoff_exit_studs
    return {
        { cframe = liftoff, seconds = 2 * (hangar.Position - liftoff.Position).Magnitude / speed },
        { cframe = CFrame.lookAt(exit, exit + climb, home.UpVector), seconds = (exit - liftoff.Position).Magnitude / speed },
    }
end
-- A plane may land only from inside the ring's box while flying down the runway line (toward the wall),
-- within `approach_max_angle_degrees` of it: never from the side.
function Rules.linedUp(home, position, look, cfg)
    local local_ = Rules.approach(home, cfg):PointToObjectSpace(position)
    local box = cfg.approach_box_studs
    if math.abs(local_.X) > box[1] / 2 or math.abs(local_.Y) > box[2] / 2 or math.abs(local_.Z) > box[3] / 2 then
        return false
    end
    return look.Unit:Dot(-home.LookVector) >= math.cos(math.rad(cfg.approach_max_angle_degrees))
end
-- Dev mode (Alan 2026-10-29): Studio, or the account that owns the game (a user, not a group) in live servers.
function Rules.devAllowed(userId, studio, creatorType, creatorId)
    return studio == true or creatorType == "User" and type(creatorId) == "number" and creatorId > 0 and userId == creatorId
end
return Rules
