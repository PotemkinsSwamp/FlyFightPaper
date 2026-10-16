# Shots slow down and drop with distance (Alan, 2026-10-12)

Today every non-homing shot flies in a straight line at a constant `projectile_speed` until `lifetime`. Change it so
shots start fast, slow down the further they fly (linear speed loss per stud = exponential drag) and fall a little.
The Guided Eraser (`homing = true`) keeps its own rule (`CombatRules.eraserSpeed`) and is NOT changed.

## Model (put these in `src/shared/CombatRules.luau`, next to `eraserSpeed`)
For a weapon with `v = projectile_speed`, `k = drag` (1/s, 0 or nil = no drag), `g = drop` (studs/s^2, nil = 0):
- `Rules.shotDistance(weapon, t)` = k>0 and v/k*(1-exp(-k*t)) or v*t
- `Rules.shotSpeed(weapon, t)` = v*exp(-k*t)
- `Rules.travelTime(weapon, d)` = time to cover d studs along the aim line: k>0: x=k*d/v; x>=1 -> math.huge; else
  -log(1-x)/k. k=0: d/v. Also math.huge when the result is > weapon.lifetime (out of range).
- `Rules.shotOffset(weapon, direction, t)` = direction*shotDistance(weapon,t) - Vector3.yAxis*(0.5*g*t*t)
- `Rules.shotRange(weapon)` = shotDistance(weapon, weapon.lifetime)
Homing weapons: these helpers are never called for them (callers keep the old eraser path).

## New numbers (`config/catalog.json`, weapons; then regenerate `src/generated/Catalog.luau` with
`python tools/generate_config.py`). Ranges, short to long: pellet < staple < rubber < paperclip < pencil.
| id | projectile_speed | drag | drop | lifetime | gives range (studs) |
|---|---|---|---|---|---|
| pellet | 1500 | 0.9 | 80 | 0.664 | 750 |
| staple | 1450 | 0.725 | 60 | 0.825 | 900 |
| rubber | 1400 | 0.6 | 50 | 0.996 | 1050 |
| paperclip | 1900 | 0.6107 | 15 | 0.979 | 1400 |
| pencil | 520 | 0.0867 | 3 | 4.11 | 1800 |
Paperclip `shot_interval` 1.8 -> 1.5 (Alan: reload slightly faster). Eraser row unchanged (no drag/drop keys).
If the catalog schema/validator or `tests/unit/Catalog.spec.luau` rejects unknown keys, allow `drag` and `drop`
(optional numbers >= 0). Update `docs/GAME_SPEC.md`'s weapon table to the new speeds, ranges and paperclip reload.

## Use it everywhere a shot's path or travel time is computed (non-homing only)
1. `src/server/CombatService.luau` shot step (~line 375): for non-homing shots keep `shot.origin` and `shot.born`
   (set both where the shot is created, ~line 231) and move to the exact point:
   `local age=now-shot.born; local new=shot.origin+Rules.shotOffset(weapon,shot.direction0,age); delta=new-shot.position`
   (store the initial direction as `shot.direction0`; keep `shot.direction` too). Keep the existing
   `math.min(dt,.5)` hitch guard by clamping age growth: if `dt>.5` advance `shot.born` by `dt-.5`. Everything after
   (`Spherecast`, `planeHit`, finish) stays the same and uses `delta`. Homing shots keep today's code exactly.
   The `"shot"` event already sends position/direction/speed/time: add `weapon` lookup on the client instead of
   relying on `speed` (it already sends `weapon=weapon.id`).
2. `src/client/CombatEffects.luau`:
   - tracer position (~line 193): for non-homing shots
     `shot.position+Rules.shotOffset(weaponTable,shot.direction,elapsed)` (look the weapon up once in `drawShot` via
     `Catalog:get(weapon)` and store it on the active entry). Homing and `follow` entries unchanged.
   - `shoot` (~line 301): wall raycast length `Rules.shotRange(weapon)`; wall hit delay and the tracer's `expires` use
     `Rules.travelTime(weapon, wall.Distance)` instead of `wall.Distance/weapon.projectile_speed` (if that returns
     math.huge use weapon.lifetime).
   - `Effects.aim(body, weapon)` and `aimFor`: pass the weapon table instead of a speed (see 3).
3. Lead solvers take a WEAPON instead of a speed, use `travelTime` for t, and aim above the target by the drop
   (`+ Vector3.yAxis*0.5*(weapon.drop or 0)*t*t`) so the falling shot lands on it:
   - `src/client/FlightHUD.luau` `FlightState.leadFor` (~line 377), `gunSpeed` -> return the weapon (rename
     `gunWeapon`), its callers, and `willHit` (~line 139): `arrive = Rules.travelTime(weapon, dist)`; the sweep points
     become `muzzle + Rules.shotOffset(weapon, direction, a) - moved(a)` (same for b). If travelTime is math.huge the
     shot can't reach: skip (same as today's `arrive > lifetime`). In the 4-step lead loop, if travelTime returns
     math.huge use weapon.lifetime for t.
   - `src/server/BotService.luau` `weaponSpeed` -> `weaponFor(p)` returning the mount's weapon (fallback: the pellet
     from the catalog), and the lead loop (~line 436): `t=age+math.min(2, travelTime or lifetime)` plus the drop lift
     on `predicted` (scaled by `accuracy` like the rest).
   - `src/shared/BotBuilds.luau` `weapon()`: `time = windup + Rules.travelTime(weapon, range)` (math.huge if out of
     range, as today).
   Grep `projectile_speed` and `lifetime` across `src/` afterwards: any other non-homing use must use these helpers.

## Tests (`tests/unit/`, existing Suite style; add to the CombatRules spec file or create `ShotBallistics.spec.luau`
and register it the way the others are registered)
- shotDistance(weapon, lifetime) matches each table range within 2%; ranges strictly increase pellet<staple<rubber<paperclip<pencil.
- travelTime(shotDistance(t)) == t (within 1e-6) for t in {0.1, 0.5}; travelTime beyond range == math.huge.
- shotSpeed at lifetime is between 0.5 and 0.75 of projectile_speed for every non-homing weapon.
- shotOffset drops by exactly 0.5*g*t^2 below the straight line.
- BotBuilds tests still pass (update expected numbers only where they come from speed/lifetime).
Run the whole suite in a Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`
is how the owner runs it; if you cannot reach Studio, say so and run `luau-analyze`/selene if present. Report pass/fail
counts. Do not commit.
