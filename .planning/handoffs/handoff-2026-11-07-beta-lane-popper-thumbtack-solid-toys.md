# HANDOFF — 2026-11-07 — Point Popper and Thumbtack in; shots fall; solid toys waiting on Save to File

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=src/shared/CombatRules.luau, src/server/CombatService.luau, src/server/FlightService.luau, src/client/CombatEffects.luau, config/catalog.json, tools/town_toys.py
**Time:** 2026-11-07 18:23 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. First ask Alan whether he did File > Save to File (the 510 newly solid toys' exact shapes live only in his open Studio); once saved, check whether the place file grew enough to slow phone loading. Then build the Stubby Crayon (rules + tests first, stand-in model) — done when its tests pass in Play and Alan tries it.

> Read on demand: AGENTS.md → this file; then docs/decisions/2026-11-07-four-new-weapons-and-falling-shots.md (all four weapons' numbers) and docs/systems/weapons.md. Memories: weapons-need-no-explaining, mute-studio-tests, studio-play-is-shared, exact-collision-baked.

## STATE (verify before acting — state drifts between sessions)
- HEAD `0690a4d6` (main), local == remote (post-commit hook pushes to GitHub `github-snapshot`). Confirm: `git rev-parse --short HEAD`.
- Tests: 467 passed / 0 failed in Play at `3948b949`; later commits are docs, tools and the place-only toy change. Re-run in Play (muted): set `workspace:SetAttribute("DevMute",true)` in Edit, start Play, `task.spawn` `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` writing to a workspace attribute, poll it; stop Play, clear DevMute.
- Studio: Rojo `serve.project.json` on port 34872, connected. The open place is the online copy; Edit has 510 toys + 3 Earths set solid with exact shapes, NOT saved to file. `python tools/check_docs.py` OK.
- Nothing from the last three sessions is published.
- Cost: no subagents; all work in the main Opus session; context about 45% at handoff.

## NEXT ACTION + PLAN
1. Ask Alan: did he do File > Save to File? If yes, compare the place file size and phone load (Device Simulator) to before; if it grew a lot, give the small rug toys Box collision (cheap, same look). Done when we know the cost.
2. **Stubby Crayon** (level 6): medium, capacity 3, 40 damage, 2 s reload, one shot per click, slow heavy shot (~850 studs/s), falls past ~600 studs. Stand-in model via `Aircraft.STAND_IN` (pencil looks right). Checks: tests in Play; Alan tries it.
3. **Spitball** (level 9): light, capacity 2, 1 damage, 2/s, slow, falls past ~350; up to 5 stick and show on the plane, each burns Lift faster and slows it (full load ~2.5x Lift burn, 20% slower); none fall off for 6 s after the last hit, then one per 3 s; a fan blows all off; the desk clears them. Needs a plan Alan OKs first (memory plan-before-building-features).
4. Real models for all four: Codex reference picture → Codex Blender; no Meshy; Alan sees them assembled before any upload. Sounds, hangar cards.
5. Then CLASSES-PLAN steps 4-5 (unlock ladder, mastery), bots following the lobby, later a range/balance review of every weapon.
- HOLDS (Alan's explicit go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while he's playing (check `get_studio_state` first), a bot match, anything paid.

## DECISIONS & WHY (this session; full list in the decision note above)
- No hidden abilities: a weapon does what the real object would. Scatter items must not remove material.
- Every shot flies to its range, then slows and arcs down (`CombatRules.shotOffset`); a fold by a falling shot pays +50 ("FOLD AT A DISTANCE", not "long shot").
- Point Popper went flat fan → round spray → bundle 30 → bundle 50 + steady narrow ring (3 studs at 100) by Alan's feel tests. A plane from behind is a thin T (~8 wide, ~1.2 tall), which is why any spread misses vertically first.
- One shot per click on PC for every non-automatic weapon (Paperclip too); phones keep hold-to-fire via the `repeating` flag (Alan confirmed).
- Cardboard Gunship mounts: heavy, heavy, medium, medium, medium, light.
- A pilot's felt crash is sent to the server (`FlightService:crashed`), which agrees within 40 studs of that solid part: fixes the rail fold-then-come-back.
- Every real object in the room is solid (`ALSO_SOLID` in tools/town_toys.py); see-through on purpose: landing rings, threads, desk hangars, runway lights, wall pictures. Alan's own HorseDragoon, meme toy and ungroup pibble stay non-colliding (his call).
- Landing catch box 90 x 90 x 70, dives/climbs up to 60 degrees.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (hard limits, model router, docs rules). Memories: weapons-need-no-explaining, mute-studio-tests, alan-does-play-checks, studio-play-grabs-mouse, exact-collision-baked, creator-store-first (but Alan said: no Meshy now; Codex picture + Blender, else he finds a modeler).

## CARRY NOTES / GOTCHAS
- Edit-mode test runs use stale cached modules: only Play results count. Long runs through MCP can return "Target is not reachable": run in the background and poll (docs/workshop/lessons.md).
- Rojo never reaches a running Play: stop and restart Play to test new code.
- `FlyFightPaper-WORKING.rbxlx` is dated 2026-10-25; Studio edits the online copy, so a file-size comparison needs Alan's Save to File first (and a fair baseline).
- The kickoff's question ("did 'looks good' cover the paperclip, Tab, desk column, notes 1, 6, 8") was never answered; later playtests covered most of it.
- STATE.md "Decisions to review" lists the Popper/Thumbtack/falling numbers for Alan.

## WHAT SHIPPED / OTHER QUEUED
- d49b42e0 Bot match measured: about 340 XP a match, no folds from ramming
- 63551f58 Staying to the end of a match always pays at least 60 XP
- e6aa7b8d Phone Tab keeps Health and Lift in view and long names readable
- f2f2269d Shots fall in an arc past their range; a falling shot's fold pays 50 more
- 58d60309 Studio test runs can be muted with DevMute
- fecf1a63 Point Popper: five pencil leads in a bundle that fans out past 20 studs
- 68d4e82b Point Popper sprays 7 leads in a circle instead of a flat fan
- b62a959b Note why the Point Popper keeps seven leads
- 2ca1b746 Point Popper holds its bundle to 30 studs, then opens gradually
- b7d14a1a Point Popper: bundle to 50 studs, then a narrow spray at a steady rate
- e069dc4f Desk landing ring catches planes at its edge and on steep dives
- 080d5c50 Thumbtack: steady shots that weaken with distance
- 3948b949 One shot per click for non-automatic weapons; Cardboard Gunship gets a third medium mount; a felt crash always folds
- 24068dae Note Alan's click-per-shot and Cardboard Gunship decisions
- e515cd09 The Earth and the rug's small toys are solid: planes no longer fly through them
- a475985d Alan confirms phones keep hold-to-fire for single-shot weapons
- b6edb59b State: new weapons, fixes, solid toys; Save to File waiting
- 0690a4d6 Lesson: run long Studio test runs in the background
- Queued: Crayon, Spitball, real models, ladder, mastery; publish + real-phone check (Alan).

## KNOWLEDGE UPDATED
- New decision docs/decisions/2026-11-07-four-new-weapons-and-falling-shots.md (+ README line); classes-and-mastery note points to it.
- docs/systems: weapons (falling shots, leads/spray, Thumbtack, click-per-shot), economy-and-shop (fold at a distance, stayed XP), desks-and-service (landing box), damage-and-deaths (felt crash, what planes hit), planes-and-hangar (Gunship mounts), core (DevMute), menus-and-hud (phone Tab).
- docs/plan/CLASSES-PLAN.md ladder renamed; docs/playtests/2026-11-07-bot-match-xp-and-rams.md; lessons.md (background test runs). Checker: docs OK.

## POINTERS
- Spray/fall maths: src/shared/CombatRules.luau (`shotOffset`, `leadFans`, `fanRadius`, `shotLife`, `eraserFall`). Stand-ins: `Aircraft.STAND_IN`.
- Tests: tests/unit/CombatRules.spec.luau, Match.spec.luau, Service.spec.luau, FlightService.spec.luau.
- Stud ruler picture for Alan: .planning/stud-ruler-top-down.jpg (untracked).
