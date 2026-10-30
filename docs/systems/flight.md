# Flight

## What the player sees
You point the mouse where you want to go and the plane flies itself there, banking into turns. On a phone or tablet the left thumb pushes a steering stick instead and the right thumb holds Fire, 2 and Boost ([touch plan](../plan/TOUCH-PLAN.md)). Takeoff from your desk is automatic. Flying burns **Lift** (your paper plane's staying-up power); when it runs out you glide down but can still steer. Upward fans refill Lift and push you up; speed bolts and boost make you faster.

## Where it stands (2026-10-18)
Works and approved in play. A scrape knocks the nose and aim away from the surface and wobbles the plane (2026-10-18,
waits on Alan's feel check; rule in [damage and deaths](damage-and-deaths.md)). Boost now pushes along the nose even with no Lift. Open: Toilet Roll body jitter Alan saw once (not reproduced; needs his description).
Touch (2026-10-23): steering stick and Fire/2/Boost buttons built, not yet tried in the phone simulator or on a phone.
**Brake and phone speed matching (2026-10-29, Alan's pick from [phone aim options](../plan/PHONE-AIM-OPTIONS.md)):
built for testing, not yet felt by Alan.** PC: hold Space, "BRAKE" under the view. Phones: a BRAKE button (above Boost), and close
behind an enemy the speed eases down to its speed, "SPEED MATCH" under the view (Settings > Speed match, on by
default; Alan tried it on his phone 2026-10-29 and keeps it). Braking while speed matching doesn't stack: the
brake's speed wins. The paper-flaps look on the plane comes after Alan likes the feel.

## Rules
- **Cheat checks (2026-10-17 audit):** the server compares each human plane's position and turn every 0.25 s and
  snaps it back if it moved too far; a booster's extra speed only counts while it fires; 6 snaps in a row (1.5 s)
  lose the plane like leaving the room. Every step, a jump faster than 2.5x cruise (+40) since the last position the
  server saw change runs that check at once, so a teleport and back inside 0.25 s is caught.
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Primary mouse points the desired nose direction (the plane steers at the spot on the aim circle's line at the nose dot's range, so the dot settles on the circle even though the camera sits above and behind; Alan 2026-10-21); automatic banking shows turns. Automatic forward speed
uses derived stats. The weapon type in the lowest-numbered filled mount is primary: LMB or gamepad ButtonR2.
The other type is secondary: RMB or gamepad ButtonL2. These gamepad bindings cover firing. Every mount of a
type uses the same button. Either type can occupy either button, including erasers and pencils. Both buttons
fire independently and can be held together; automatic guns keep firing while a semiautomatic gun on the
other button fires once per click. Shift boosts if equipped; Escape opens overlay. GUI actions consume
pointer input and must not fire weapons. Use a center dead zone,
configurable sensitivity, and bounded look steering so crosshair/camera feedback does not produce runaway spin.
No manual yaw/roll requirement. Camera follows behind/above with collision correction and restrained shake.
Provide sensitivity, volume, reduced camera shake, and quality options from the main menu.

Use the same bounded movement step for humans and bots. Pitch limit starts at 80 degrees; no realistic stall
minigame. Minimum forward flight prevents hovering except the explicit landing state. Apply acceleration/
turn smoothing rather than instant orientation changes. Use fixed simulation time with bounded catch-up;
never let a low frame rate increase speed, recharge, damage, or elapsed-paid time. Local predicted rendering
must reconcile to authoritative state without accepting impossible client poses.

Lift drains one second per ordinary flight second from a loadout-dependent maximum. At zero, maintain
steering but reduce forward speed to 70% and enforce a descending component (initially 12 studs/s).
Fans can rescue before impact; no fixed time-to-death is promised. An upward fan adds 15 seconds of Lift for every
second you stay in its gust (clamped to maximum, every pass, no reuse timer) and pushes you up at 30 studs/s. Horizontal fan benefit is 1.15× for 2.5 seconds; refresh rather
than multiply overlapping copies. Fans do not refill optional boost. Boost drains its separate seconds while
held and augments speed by the equipped module; clamp stacked environmental speed to a safe validated limit.

- **Brake (Space, PC; Alan 2026-10-29):** while held (and not boosting) the plane flies at `brake_speed_factor` of
  its speed and turns `brake_turn_factor` tighter; the server drains Lift `brake_lift_drain_factor` times as fast
  (attribute `Braking`), so it can't be held all match. Speed changes ease at `speed_ease_per_s`.
- **Speed match (phones; `SpeedMatch`):** it follows only a plane you are really tailing: within `pick_range_studs`
  and `pick_cone_deg` of your nose, flying within `same_way_deg` of your heading (a plane crossing in front or coming
  head-on never counts; the nearest such plane is picked). It keeps that plane while it stays within
  `keep_range_studs`/`keep_cone_deg` (another plane passing in front can't steal it) and lets go `lost_seconds` after
  losing it, or at once when it folds. Your speed eases to the enemy's, a little faster while further back than
  `follow_studs` (so you close in), never faster than your own speed nor below `floor_factor`. Boost cancels it. No
  extra Lift cost (it only works while tailing). Off: Settings > Speed match (phones only).

## Code
| File | What it does |
|---|---|
| `src/client/FlightController.luau` | Mouse-aim steering on your screen (and the touch stick's turning) |
| `src/client/TouchControls.luau` | Phones and tablets: the floating steering stick (left half), Fire / 2 / Boost / Brake buttons, drawn as peel stickers with a tinted crayon fill rising inside (Alan 2026-10-28, `assets/ui/touch/`, concept `ui-concepts/touch-buttons-c.png`); only while flying on a touch screen (and in a lesson's read pause); turns off Roblox's own walk stick and jump button |
| `src/client/ChaseCamera.luau` | Chase camera: smoothing, speed zoom, shake, stays in the room |
| `src/server/FlightService.luau` | Server side of every plane: spawn at desk, takeoff, fans, speed pickups, death and landing hooks |
| `src/shared/FlightRules.luau` | Lift drain and flight limits |
| `src/shared/SpeedMatch.luau` | Phones: which enemy you are tailing and the share of speed that matches it (tests: `tests/unit/SpeedMatch.spec.luau`) |
| `src/client/SpeedPickups.luau` | Spinning speed-bolt markers |
| `src/client/FanSpin.luau, src/client/FanWind.luau` | Fan blades turning and wind swirls |

## Tuning numbers
`config/gameplay.json`: `flight` (speeds, turning, Lift, autopilot; touch stick: `touch_stick_deg_per_s` full-push turn rate, `touch_stick_curve` gentleness of small pushes, `touch_stick_radius` share of the screen's short side), `world.fans`, `world.speed_pickups`.

## Related
- [Mouse-aim flying](../decisions/2026-10-07-mouse-aim-controls.md)
- [Takeoff is automatic](../decisions/2026-10-13-automatic-takeoff.md)
- [Fans refill continuously](../decisions/2026-10-13-fans-refill-continuously.md)
- [Desks and service](desks-and-service.md)
- [Planes and hangar (speed, turn and Lift per build)](planes-and-hangar.md)
- [Playtest 2026-10-13](../playtests/2026-10-13.md)
- [Milestones](../plan/MILESTONES.md)
- [Glossary](../GLOSSARY.md)

Back to [HOME](../HOME.md)
