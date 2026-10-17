# Flight

## What the player sees
You point the mouse where you want to go and the plane flies itself there, banking into turns. Takeoff from your desk is automatic. Flying burns **Lift** (your paper plane's staying-up power); when it runs out you glide down but can still steer. Upward fans refill Lift and push you up; speed bolts and boost make you faster.

## Where it stands (2026-10-15)
Works and approved in play. Boost now pushes along the nose even with no Lift. Open: Toilet Roll body jitter Alan saw once (not reproduced; needs his description).

## Rules
- **Cheat checks (2026-10-17 audit):** the server compares each human plane's position and turn every 0.25 s and
  snaps it back if it moved too far; a booster's extra speed only counts while it fires; 6 snaps in a row (1.5 s)
  lose the plane like leaving the room. Every step, a jump faster than 2.5x cruise (+40) since the last position the
  server saw change runs that check at once, so a teleport and back inside 0.25 s is caught.
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

Primary mouse points the desired nose direction; automatic banking shows turns. Automatic forward speed
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

## Code
| File | What it does |
|---|---|
| `src/client/FlightController.luau` | Mouse-aim steering on your screen |
| `src/client/ChaseCamera.luau` | Chase camera: smoothing, speed zoom, shake, stays in the room |
| `src/server/FlightService.luau` | Server side of every plane: spawn at desk, takeoff, fans, speed pickups, death and landing hooks |
| `src/shared/FlightRules.luau` | Lift drain and flight limits |
| `src/client/SpeedPickups.luau` | Spinning speed-bolt markers |
| `src/client/FanSpin.luau, src/client/FanWind.luau` | Fan blades turning and wind swirls |

## Tuning numbers
`config/gameplay.json`: `flight` (speeds, turning, Lift, autopilot), `world.fans`, `world.speed_pickups`.

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
