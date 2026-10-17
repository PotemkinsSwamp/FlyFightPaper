# HANDOFF — 2026-10-17 18:00 — fold credit, loading screen, offline rewards done; re-publish and menu art next

**Labels:** kind=product+ui · lane=multiplayer · branch=main · issues= · areas=src/shared/CombatRules.luau, src/server (CombatService, MatchService, RoundRuntime, DeskService, RewardQueue, ProfileRuntime, ProfileService, Matchmaking, FlightService), src/client (Loading, ScorePopups), config, docs

★ START HERE: Goal: the game working for real players on Alan's private server, then his Stage 9 sign-off. Opening
action: ask Alan's go to re-publish (he clicks Studio **File > Publish As** > "FlyFightPaper(First Fold)" > Overwrite;
never File > Publish). Done when the live game has today's later fixes (offline rewards, blink check, matchmaking
guards, fold credit, loading screen) and Alan has done his live checks.

> Read on demand: AGENTS.md → THIS; previous handoff `handoff-2026-10-17-multiplayer-published-security.md` (IDs,
> holds, earlier decisions); docs/playtests/2026-10-17.md (Alan's notes + menu art plan);
> docs/decisions/2026-10-17-fold-credit-big-damage-wins.md. Memories: look-up-roblox-ui-steps, studio-not-drawing.

## STATE (verify before acting)
- HEAD: see `git rev-parse --short HEAD` (this handoff's commit), main, auto-pushed.
- Tests: 321 / 0, 26 suites. Re-run in Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: open on the online copy (MCP name "FlyFightPaper(First Fold) (placeId: 132768925825316)"), Rojo serving
  the current code. Working file rebuilt 16:32 with save_place.py (backup `...-2026-10-17-pre-republish.rbxlx`).
- Live: Alan re-published once (security + server moves); everything from f60ccd17 on is NOT live yet.
- Cost this stretch: Codex x1 fix (offline rewards, ~26k tokens); 2 web searches; no uploads, no Meshy.

## NEXT ACTION + PLAN
1. Re-publish (Alan's click). Check: Studio copy has `fold_majority_fraction`, `finishing_shot`, `messageReward`, `p.blink`.
2. Alan's live checks: join straight in; Paper/XP kept after rejoin; F9 memory over 20–30 min; a fold steal now goes
   to the big-damage pilot with "FINISHING SHOT" for the finisher.
3. Menu art (Alan's notes 1–2, plan in docs/playtests/2026-10-17.md): retouch the 5 backgrounds' ruler numbers;
   replace `photo-1`, `drawing-1`, `drawing-2` with the current town. Contact sheet → Alan's OK → upload (his go).
4. Then Alan's Stage 9 playtest; Tutorial only when he says (he said not ready yet); Stage 11.
HOLDS (Alan's go each): uploads, publish/re-publish, Studio-settings changes, Meshy, anything paid, desktop control
(the PC access box needs him physically; the permission checker also blocks Open Cloud publishing), closing Studio.

## DECISIONS & WHY (this stretch)
- Fold credit (Alan): 15 s window; ≥50% of the plane's health and more than the last hitter wins the fold; the
  finisher gets an assist + 25; a desk repair wipes earlier damage (`p.repairedAt`); refold/fresh already start clean.
- Loading: plane turned 24° and cropped (trail was in front of the nose); 12 rotating lines every 2.5 s; the
  "pictures didn't load" note removed (Roblox reports some pictures as failed though they show).
- Offline rewards (Codex, reviewed): ProfileStore MessageAsync to absent players, applied once through the normal
  reward path. Known rare gap: rejoining the same server while an older reward message waits can skip it.
- Trigger releases stay uncapped; final-save confirmation fails open (from the previous handoff, still true).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories look-up-roblox-ui-steps, no-surprise-desktop-control, look-at-textures-before-upload (menu art).

## CARRY NOTES / GOTCHAS
- Open Cloud publish (`apis.roblox.com/universes/v1/10771424231/places/132768925825316/versions`) was refused by the
  permission checker as a production deploy; don't retry or wrap it in a tool. Alan publishes from Studio.
- Studio behind other windows: GUI previews still work in Edit via StarterGui + screen_capture (delete after).
- STATE.md at 60 lines.

## WHAT SHIPPED / OTHER QUEUED
f60ccd17 re-published note · b0eceb02 matchmaking guards · 5ecac2bd blink check · 6be1428d offline rewards ·
37ad193f / fe8df6e3 state · a49c6f15 Alan's notes · 7a1e661c fold credit · 7581051d loading screen · 19b7ac75 menu
art plan · this handoff. Queued: re-publish (go), menu art (go to upload), Stage 9 playtest.

## KNOWLEDGE UPDATED
- docs/decisions: fold-credit-big-damage-wins (new). docs/systems: damage-and-deaths (fold rule), saving (offline
  rewards, matchmaking fixes), flight (blink check). docs/playtests/2026-10-17 (new). Checker: OK (87 pages).

## POINTERS
- src/shared/CombatRules.luau `Rules.credit`; src/server/MatchService.luau finishing_shot; src/client/Loading.luau
  `LINES`; src/server/RewardQueue.luau `flushOffline`; assets/ui/*/ready (menu pictures).
