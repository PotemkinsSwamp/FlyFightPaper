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
- [Touch plan](plan/TOUCH-PLAN.md): phones and tablets (approved 2026-10-23)
- [Screen fit plan](plan/SCREEN-FIT-PLAN.md): every piece in its place on any screen (approved 2026-10-24)
- [Classes plan](plan/CLASSES-PLAN.md): six class planes, new weapons and mastery (draft for Alan's OK)
- [Controls plan](plan/CONTROLS-PLAN.md): move your phone buttons, then change your PC keys (draft for Alan's OK)
- [Phone aim options](plan/PHONE-AIM-OPTIONS.md): staying on a tail on a phone (research, waiting on Alan)
- [Load plan](plan/LOAD-PLAN.md): fast joins on a phone, same look (draft for Alan's OK)
- [Unlock moment plan](plan/UNLOCK-PLAN.md): the backpack that opens when you level up (draft for Alan's OK)
- [Report card plan](plan/REPORT-CARD-PLAN.md): the round's results on a school report card (built 2026-11-11)
- [Gift a friend plan](plan/GIFT-PLAN.md): buy a shop item for a Roblox friend (draft for Alan's OK)
- [Shop prices plan](plan/SHOP-PRICES-PLAN.md): Paper packs and Robux part prices after the price rise (approved 2026-11-11)
- [Shop money plan](plan/SHOP-MONEY-PLAN.md): the buying funnel: daily gift, starter pack, first-buy double, decoy and anchor packs, Paper jar (approved 2026-11-12)
- [Shop screen plan](plan/SHOP-SCREEN-PLAN.md): the shop as a Roblox-style shop window in our materials, with movement (waiting for Alan's OK)
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
- [Design examples](workshop/design-examples.md): the design-theory skill applied (fold card circle, shop picture backings).
- Who does what (Claude, Codex, helper models): [AGENTS.md](../AGENTS.md).

## Research
- [Audit 2026-10-07](research/AUDIT-2026-10-07.md): every problem found after the failed overnight build.
- [Touch aim research 2026-10-23](research/TOUCH-AIM-RESEARCH-2026-10-23.md): how games give phone and controller players aim help, tuning numbers to start from, and how we'll measure it.
- [Tutorial research 2026-10-18](research/TUTORIAL-RESEARCH-2026-10-18.md): how most games teach new players.
- [Range and hangar research 2026-10-19](research/RANGE-HANGAR-RESEARCH-2026-10-19.md): how other games do practice ranges, moving targets, difficulty and hangar onboarding.
- [Pricing research 2026-10-18](research/PRICING-RESEARCH-2026-10-18.md): what Roblox games charge, and our draft price ladder.
- [Shop research 2026-11-11](research/SHOP-RESEARCH-2026-11-11.md): what makes Roblox players buy, the rules for kids, and a tempting shop in our classroom style.
- [Cosmetics research 2026-11-12](research/COSMETICS-RESEARCH-2026-11-12.md): skins, trails, fold effects, emotes for a paper plane, and playtime rewards; options for Alan.
- [Personal shop research 2026-11-12](research/PERSONAL-SHOP-RESEARCH-2026-11-12.md): a shop that changes with the player (spenders, timers, personal discounts, offers after a fold), the new EU law proposal, and options to pick from.
- [Design and colour research 2026-11-12](research/DESIGN-RESEARCH-2026-11-12.md): what studies on games, kids and toys say about colour, layout, reading and tapping; the evidence behind the `design-theory` skill.
- [Unlock pacing research 2026-11-08](research/UNLOCK-PACING-2026-11-08.md): how fast other games unlock things, and targets for our ladder.
- [Performance research 2026-10-11](research/PERFORMANCE-RESEARCH-2026-10-11.md): why Play was slow, and the fixes.
- [QA review 2026-10-07](research/QA-2026-10-07.md): requirement-by-requirement check.

[Glossary](GLOSSARY.md): plain meanings for the words used here.
