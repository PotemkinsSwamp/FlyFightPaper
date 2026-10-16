# Tutorial

## What the player sees
A new player's first join goes straight into a guided lesson in an empty copy of the classroom: flying (steer, Lift,
fans, landing), shooting paper targets, then a fight with one enemy, then what every part of the HUD means, the
hangar, each weapon, and how building a plane works. It can be skipped and replayed, and never pays rewards.

## Where it stands (2026-10-15)
Deliberately built last (before Stage 11), once planes, weapons, hangar and HUD stop changing. A starting point
exists: practice pilots nobody can hurt, a placed paper target, a sticky-note step guide and a landing guide
("Line up here"). In the live room the practice target was hard to find.

## Rules
See "Tutorial (built last)" in [Milestones](../plan/MILESTONES.md). Practice is never reward-eligible.

## Code
| File | What it does |
|---|---|
| `src/client/Tutorial.luau` | Sticky-note step guide for the first flight |
| `src/shared/CombatRules.luau` | `practiceTargetPose`: where the practice target goes |
| `src/server/CombatService.luau` | Practice pilots are nobody's enemy |

## Tuning numbers
None yet.

## Related
- [The tutorial is built last](../decisions/2026-10-13-tutorial-built-last.md)
- [Menus and HUD](menus-and-hud.md)

Back to [HOME](../HOME.md)
