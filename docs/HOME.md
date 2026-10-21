# Fly Fight Paper: start here

A competitive paper-airplane dogfight game in a giant classroom, built in Roblox. Private until Alan decides
otherwise.

**Where we are right now:** [STATE](../state/STATE.md) (current stage, what works, what's broken, what's waiting on Alan).

## How these docs work
- Every fact lives in **one** page. Other pages link to it instead of copying it.
- Each game system has one page with the same headings: what the player sees, where it stands, rules, code, tuning
  numbers, related.
- Every choice Alan makes gets a [decision](decisions/README.md) note; every playtest gets a [playtest](playtests/README.md) note.
- `python tools/check_docs.py` checks every link works and every page is reachable from here.

## What the game must be
- [Vision](vision/VISION.md): the product brief. Alan's word is final.
- [Art direction](vision/ART_DIRECTION.md): look, menus, sound, map layout.

## The plan
- [Milestones](plan/MILESTONES.md): stages, quality bars and Alan's ★ gates.
- [Ideas not yet planned](plan/IDEAS.md)
- [Tutorial plan](plan/TUTORIAL-PLAN.md) (draft, waiting on Alan)
- [Hangar plan](plan/HANGAR-PLAN.md) (draft, waiting on Alan)
- [Release notes](plan/RELEASE_NOTES.md) (2026-10-07 build)

## The game, system by system
| Page | In one line |
|---|---|
| [Flight](systems/flight.md) | Mouse-aim steering, Lift, fans, boost, automatic takeoff |
| [Weapons](systems/weapons.md) | Six school-supply weapons and how they fire |
| [Damage and deaths](systems/damage-and-deaths.md) | Hits, crashes, folds and assists, paper-ball and shred deaths |
| [Desks and service](systems/desks-and-service.md) | Landing, refill, repair, refold, protection |
| [Planes and hangar](systems/planes-and-hangar.md) | Plane parts, mounts, stats, saved builds, colours |
| [Bots](systems/bots.md) | Computer pilots, skill levels, matchmaking, rookie graduation |
| [Modes and scoring](systems/modes-and-scoring.md) | Free-for-all, team deathmatch, Airspace Control, points |
| [Escapes](systems/escapes.md) | Chalk-eraser cloud, ceiling ducts |
| [Monorail](systems/monorail.md) | The new town's toy train: route, speed, it kills on contact |
| [Economy and shop](systems/economy-and-shop.md) | Paper, XP, levels, prices, the (switched-off) shop |
| [Saving](systems/saving.md) | Keeping player progress safely |
| [Menus and HUD](systems/menus-and-hud.md) | Every screen and what's on it while flying |
| [Sound and effects](systems/sound-and-effects.md) | Weapon sounds, whoosh, music, visual effects |
| [Performance](systems/performance.md) | 60 FPS with 12 planes, fast Play starts |
| [Tutorial](systems/tutorial.md) | The first-join lesson (built last) |
| [Core](systems/core.md) | Start-up code and shared helpers every system uses |

## The world
- [The classroom](world/classroom.md): room, desks, avatars, lighting, decor.
- [The town and the play rug](world/town.md): rug, buildings, bridges, layout rules.

## Art
- [How new art gets made](art/pipeline.md)
- [Model catalog](art/models.md): which models are in the game and which are old.
- [Reference pictures](art/references.md): the approved look and concepts.
- [Building kit](art/building-kit.md)

## History
- [Decisions](decisions/README.md): every choice Alan made, and why.
- [Playtests](playtests/README.md): every time Alan played, and what changed.
- Session diaries: `.planning/handoffs/` (one per work session; the newest is the next session's starting point).

## Workshop: how the work gets done
- [Studio and Rojo](workshop/studio-and-rojo.md): opening, playing and rebuilding the game.
- [Tools](workshop/tools.md): every script in `tools/`.
- [Testing](workshop/testing.md): rule tests and checking by eye.
- [Lessons learned](workshop/lessons.md): hard-won rules (uploads, models, Studio).
- Who does what (Claude, Codex, helper models): [AGENTS.md](../AGENTS.md).

## Research
- [Audit 2026-10-07](research/AUDIT-2026-10-07.md): every problem found after the failed overnight build.
- [Tutorial research 2026-10-18](research/TUTORIAL-RESEARCH-2026-10-18.md): how most games teach new players.
- [Range and hangar research 2026-10-19](research/RANGE-HANGAR-RESEARCH-2026-10-19.md): how other games do practice ranges, moving targets, difficulty and hangar onboarding.
- [Pricing research 2026-10-18](research/PRICING-RESEARCH-2026-10-18.md): what Roblox games charge, and our draft price ladder.
- [Performance research 2026-10-11](research/PERFORMANCE-RESEARCH-2026-10-11.md): why Play was slow, and the fixes.
- [QA review 2026-10-07](research/QA-2026-10-07.md): requirement-by-requirement check.

[Glossary](GLOSSARY.md): plain meanings for the words used here.
