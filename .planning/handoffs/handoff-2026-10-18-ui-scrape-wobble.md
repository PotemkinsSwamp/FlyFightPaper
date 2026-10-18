# HANDOFF — 2026-10-18 — Winners' moment done and OK'd; train fixed; next: scrapes wobble you instead of killing

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/WinnersCutscene.luau, src/shared/MatchRules.luau, src/shared/MonorailRules.luau, src/server/FlightService.luau, config/gameplay.json, tests/unit, docs

★ START HERE: Goal: touching a wall (building or the train's side) at a shallow angle (under ~25°) is a SCRAPE: a
little damage plus a knock and a wobble the pilot has to correct; more head-on is a CRASH; the train's moving front
still kills at once ([decision](../../docs/decisions/2026-10-18-scrapes-wobble.md), Alan picked "by angle").
Today any wall crashes you above 12 studs/s into it (~8° at full speed), so a wing graze kills. Done = in Studio
Play a wing graze along a building and along the train wobbles you without killing, a head-on hit crashes, and
Alan re-checks and says "Stage 9 approved".

> Read on demand: AGENTS.md → THIS → the decision above. Then only what the step touches:
> `docs/systems/damage-and-deaths.md`, `docs/systems/flight.md`, `docs/systems/monorail.md`.
> Memories: studio-play-is-shared, studio-not-drawing, no-surprise-desktop-control, send-videos-not-gifs.

## STATE (verify before acting)
- HEAD `60f0b889` + this handoff on main; every commit is pushed to GitHub by the post-commit hook (it prints
  "github: pushed"; `origin/main` tracking is stale by design, GitHub gets the `github-snapshot` copy). `git status -sb`.
- Tests 328/0 (2026-10-18, after the train fix). Re-run in Play (server):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open, Play running (Alan was parked at his desk; check before restarting Play). Rojo serving on 127.0.0.1:34872,
  plugin reconnected by Alan this session. Place file not re-saved (Alan's Ctrl+S; code lives in src/).
- Cost last session: no subagents, no Codex, no Meshy, no uploads, no web searches; ~40% of primary context at handoff.

## NEXT ACTION + PLAN
1. **Scrape vs crash by angle** for buildings and train sides. Server judges in `Service:impact`
   (`src/server/FlightService.luau`) with `Rules.collisionDamage` (`src/shared/FlightRules.luau`) and config
   `combat.collision_*`; the pilot's client stops the plane at a surface and is pushed off by `CollisionNormal` /
   `DeflectUntil`, fan shoves by `Knock` (`src/client/FlightController.luau` ~line 80-96). The wobble (roll/swing away
   that needs correcting) is new client feel. Check: Studio Play, graze a building wall and the train side with a wing
   (wobble, survive), fly nose-first into a wall (crash), get T-boned by the train (dead). Unit tests for the angle rule.
   Bots must still survive the change (one timed bot match: deaths by cause shouldn't jump).
2. Alan's re-check of the train and buildings; then "Stage 9 approved" (MILESTONES D13) → update STATE/MILESTONES.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control, closing
Studio. Don't steer his plane while he's in Play (check State first; your own test Play is fine). If Studio stops
drawing (RenderStepped 0/s), ask Alan to click on Studio.

## DECISIONS & WHY (this session)
- **Winners' moment** (Alan OK'd the group shot): close-ups as 3rd, 2nd, 1st hop up, then one steady shot from a
  little above (GROUP_EYE 1.6 winner heights, 8° down) of all three dancing with Roblox's own emotes, plates once all
  three are in frame, confetti; results card the last 10 s (`rounds.results_seconds` 18 → 27).
- **Desks slide only in the shot** (Alan's pick): real desks can't move: towers stand beside the landing paths of
  the middle desk and desk 4 (only desk 2 could move). Outside desks slide to 50 studs from the middle one on each
  client, restored after.
- **Tied team rounds have no places** (tests pin it: no podium in a draw), so `MatchRules.winners` ranks a tie by
  results order instead of giving places on the server.
- **Train**: every corner of the plane's collider parts counts; joints between cars are never a face; the entry
  face is traced back along the plane's motion against the car; only the moving front (`nose_kill_speed` 10) kills.
- Ceiling decorations (planets, mobiles) between the group camera and the winners fade; monorail pillars and track
  always fade in the shot.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds). Memories named above. VISION: no forged accounts, no AI labels.

## CARRY NOTES / GOTCHAS
- When the Studio tools come back under a new studio id, check `rojo serve` still answers on 34872 before trusting a
  test (it had died this session); start it with the command in `docs/workshop/studio-and-rojo.md`.
- Screen grabs of Studio: `ffmpeg -f gdigrab -i title="FlyFightPaper(First Fold) - Roblox Studio"` works while Studio
  is in front (viewport crop 1376x775+330+198 at Alan's layout). Alan doesn't need MP4s of the winners' shot.
- Still open from earlier: one ~55-65 ms hitch at cutscene start; the vote-lap top strip shows the old round.
- `Cutscene.stop` on an error mid-`play` would fail on nil plate/confetti (no error seen).

## WHAT SHIPPED / OTHER QUEUED
- 80a5e5a9 Winners' moment like the big games: hops in close-up, group shot with Roblox emotes, plates, confetti, 10 s results card
- 5d02d73c Winners' shot looks down from higher, no pillars or hanging planets; tied team rounds still get a top 3
- 429be39d Winners' group shot a little lower; monorail pillars fade out of it
- 013f5e24 Docs and State: winners' moment rebuilt and OK'd; playtest list updated
- c7618686 State: playtest list names today's mode buttons
- 798df840 Train hits count wings, nose and tail, not just the plane's middle
- 98b2c1a0 State: Stage 9 playtest result, train fix waits on Alan's re-check
- 63964c84 Train acts like a building wall; only its moving front kills at once
- 60f0b889 Decision: scrapes wobble you, head-on hits crash (buildings and train)
- this handoff
- Queued: plane emotes for the shop stage (Alan's go for Meshy/uploads); Ctrl+S of the place (Alan).

## KNOWLEDGE UPDATED
- docs/systems/modes-and-scoring.md (winners' moment rebuilt, 27 s, ties), menus-and-hud.md (WinnersCutscene row),
  monorail.md (hit rules + checks), decisions: winners-shot-redesign status built, new scrapes-wobble (+ README),
  workshop/lessons.md (Roblox emotes free via catalog search + GetObjects; Rojo after Studio reconnect; wide shots in
  a tall room). STATE.md: since-last-checked, playtest result, next step. Checker: OK (93 pages).

## POINTERS
- `src/server/FlightService.luau` (`Service:impact`, train block in `Service:step`), `src/shared/FlightRules.luau`
  (`collisionDamage`, `contact`), `src/client/FlightController.luau`, `src/shared/MonorailRules.luau`,
  `config/gameplay.json` (`combat.collision_*`, `world.monorail`), `state/STATE.md`.
