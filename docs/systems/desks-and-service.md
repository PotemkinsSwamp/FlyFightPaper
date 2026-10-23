# Desks and service

## What the player sees
Every pilot has a desk. You launch from it and can fly back to land: refill Lift for free, repair for free (each repair wears your maximum health down a little), pay 120 Paper for a full refold that keeps your streak, or take a free fresh plane that ends it. While parked you get up to 120 seconds of protection per life. The desk's hangar shows your five builds: pick one and
the preview shows it; **Edit build** opens the full hangar on it; a full refold flies it.

## Where it stands (2026-10-22)
**New quick menu built; Alan OK'd its assembled preview, not yet played** ([decision](../decisions/2026-10-22-desk-quick-menu.md)):
photo, name and a four-row stat sheet top left, the five builds as small turned photos on a cork strip down the left,
pinned service strips and Customize (opens the Hangar's binder) down the right, the note and LAUNCH! bottom middle; the
match strip and kill feed stay up (`FlightHUD`'s MatchInfo layer). New art in `assets/ui/deskmenu/` (`UIAssets.deskMenu`,
uploaded 2026-10-22); the rest reuses Hangar and HUD pieces.

Works (connected since Oct 7). Landing guide ("Line up here") is in. Builds change only at the desk
([decision](../decisions/2026-10-17-builds-change-at-the-desk.md)): Edit button, picked-build preview, and a refold
into the build you already fly is refused without charge.

## Rules
*Moved word for word from the old rulebook (GAME_SPEC.md, version 1.0). Starting tuning, not tested balance.*

| State | Body in arena? | Weapons | Damage/protection | Permitted transitions |
|---|---|---|---|---|
| MENU | No | None | Not a combat target | Queue, practice, shop/edit presets |
| QUEUED | No | None | None | Cancel to menu; join next available legal slot |
| SPAWN_READY | Yes at desk | Disabled | Desk allowance during active match | Launch, configure fresh plane |
| FLYING | Yes | Valid triggers | Normal except fresh-spawn protection | Landing approach, destroyed, withdraw |
| LANDING | Yes | Disabled | Vulnerable until eligible zone entered | Service or cancelled approach |
| SERVICING | Yes on pad | Disabled | Own remaining desk allowance only | Refill/repair/refold/fresh plane/launch |
| DESTROYED | No live target | None | No double kill | Respawn, menu |
| RESULTS | No active combat | None | None | Vote/menu/next round |

A menu overlay is a UI flag on an existing state, not an invulnerable state. During overlay keep last heading,
normal movement/Lift and damage; stop accepting new firing input. Saved presets can be edited but not applied
to a flying actor. No auto-return to safety.

Landing approach accepts eligible direction/speed inside a marked ring and reserves a free pad atomically.
Initial guided final approach lasts 1.5 seconds; no hard landing minigame. Invalid/enemy desks reject service.
For team mates/neutral pads provide small queued holding approaches rather than stacking planes. Pad capacity
and visual slots must match; each personal desk starts with one service pad, each neutral desk with two.
Desks remain static through a round even if owner leaves; reassign at a boundary without moving scenery into
planes. Neutral pads remain available to both teams under the same per-pilot protection rules.

### Protection
120 seconds accumulated per life ONLY while in an eligible service zone during an active round. Warn at
30 and 10 seconds. Outside pauses; paid refold/menu/re-entry do not reset. Spawn-ready preparation during an
active match counts; out-of-match menu/results do not. Only actual new life/new round restores the allowance.
Spawn outside shield starts at three seconds and ends before a shot resolves. Repaired relaunch grants no new
outside shield. Desks are not destructible scoring targets.

Dome visuals are not a shared impenetrable physical shell: use per-target protection in hit validation, so a
plane whose allowance expired can actually be shot. All weapon origins within service zones are disabled,
even after protection expires. A protected pilot cannot fire out; an attacker cannot damage a protected pilot.
Do not let one plane's expiry remove a teammate's protection. Document this as the implementation of the
owner's per-pilot timeout, not a universal glass wall that accidentally protects everyone forever.

### Repair math (delegated starting resolution)
Track original maximum H, current life maximum M, and health h. Free refill restores Lift/boost after two
seconds and never changes M. Free health repair after three seconds increases health but accumulates wear
proportional to health actually restored. Initial equation:

```
newM = max(0.60 * H, (M + 0.20 * h) / 1.20)
if newM <= h: no health repair is needed; never reduce h
otherwise: health = newM; lifeMaximum = newM
```

This solves a 20%-of-restored-health wear rate without charging a full wear step for a tiny scratch. Clamp
and verify 0 <= health <= lifeMaximum <= H. At the floor, repair to the floor without further decay. Preview
before accepting. Initial values supersede earlier illustrative 100→90 examples, which were not fixed math.

Full refold costs 120 Paper initially, takes three seconds, restores selected eligible build's original health
and reserves, and can change loadout while preserving life/streak/protection allowance. Validate affordability,
ownership and capacity before debit. Complete once per server-issued service transaction; a replay cannot
charge again or apply twice. Reserve/commit/cancel behavior must be defined when damage or departure interrupts
service: no delivery means no final debit (or a recoverable matching credit); no generic client-side refund.
A free fresh plane ends the life/streak and respawns normally. Streak has no escalating damage/earnings bonus.

## Code
| File | What it does |
|---|---|
| `src/server/DeskService.luau` | Refill, repair, refold, fresh plane |
| `src/shared/ServiceRules.luau` | Repair math, protection, landing ring and takeoff path |
| `src/client/DeskHangar.luau` | The desk quick menu (pieces round the screen edges) |
| `src/client/DeskPieces.luau` | Landing rings and runway lights |

## Tuning numbers
`config/gameplay.json` `service`; refold price in `config/economy.json` `full_refold_cost_paper`.

## Related
- [Takeoff is automatic](../decisions/2026-10-13-automatic-takeoff.md)
- [Flight](flight.md)
- [Economy and shop](economy-and-shop.md)
- [Classroom (where the desks are)](../world/classroom.md)
- [Glossary](../GLOSSARY.md)

Back to [HOME](../HOME.md)
