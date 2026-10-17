# HANDOFF — 2026-10-17 — game published privately; join-in, security and safe server moves done, re-publish next

**Labels:** kind=product+infra · lane=multiplayer · branch=main · issues= · areas=src/server (RoundRuntime, FlightService, CombatService, DeskService, HangarService, Matchmaking, MatchmakingAdapter, ProfileRuntime), src/shared/BotRosterRules.luau, tools/art/blocks.py, tools/town_toys.py, assets/models/monorail-station-*, docs

★ START HERE: Goal: the game working for real players on Alan's private server, then his Stage 9 sign-off. Opening
action: ask Alan's go to re-publish (Studio **File > Publish As** > "FlyFightPaper(First Fold)" > start place >
**Overwrite**; never File > Publish, which releases publicly). Done when the live game has today's security and
saving fixes, and Alan has played it live: joins straight in, keeps Paper/XP after leaving and rejoining.

> Read on demand: AGENTS.md → THIS; docs/decisions/2026-10-17-real-players-join-instantly.md,
> docs/decisions/2026-10-07-private-publish.md (IDs, safe publish), docs/systems/saving.md (open live risks),
> docs/workshop/lessons.md (Save to File after Publish As). Memories: look-up-roblox-ui-steps, studio-play-is-shared,
> studio-not-drawing, no-surprise-desktop-control.

## STATE (verify before acting)
- HEAD `690ecc32` (main), auto-pushed to GitHub by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests: 306 passed / 0 failed, 26 suites, at 3860eb87. Re-run in Play, server:
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: open on the **online copy** (MCP name "FlyFightPaper(First Fold) (placeId: 132768925825316)"), Rojo serving.
  Its Ctrl+S saves to Roblox; the working file `FlyFightPaper-WORKING.rbxlx` was last written 02:27 (stations,
  shapes and tin walls are in it). Backup: `D:\FlyFightPaper-snapshots\FlyFightPaper-WORKING-2026-10-17-pre-stations.rbxlx`.
- Live game: game 10771424231 / place 132768925825316, private (unreleased), server size 12, social slots Roblox
  optimized. Online version = before the security pass (32b06951) and server-move fixes (3860eb87).
- Cost: 1 upload (57 station pieces + maps, free, Alan's go); agents: roblox-reviewer audit (~102k tokens),
  web-fetch docs (~26k), Codex review (~34k) + Codex fix (~26k); Blender ~2 min. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. **Re-publish** (Alan's go) with Publish As > Overwrite. Check: in Studio, `game.PlaceId` is 132768925825316 and
   the server code has `corrections>=6` (FlightService) and `TRANSFER_TIMEOUT` (Matchmaking).
2. **Alan's live checks** (on Roblox, not Studio): straight into a match; one round, leave, rejoin → same Paper/XP;
   F9 > Memory server number at start and after 20–30 min (the 1.7 MB/min creep seen in Studio).
3. **Open live risks** (docs/systems/saving.md): rewards earned after a player left live only in server memory; two
   players can claim the same last seat; friend check before the transfer guard; stale room rows hide open rooms.
   Codex's lane; check every diff and re-run tests before committing.
4. **Still-open cheat gap:** a teleport-and-back inside 0.25 s isn't seen (needs a per-frame check; careful of lag).
5. **Alan's Stage 9 playtest**, then the Tutorial (he says not ready for it yet), then Stage 11.
HOLDS (Alan's go each): uploads, private publish / re-publish, Studio-settings changes, Meshy, anything paid,
desktop control, closing Studio. Don't steer his plane in Play. Rebuilds need his **File > Save to File** first.

## DECISIONS & WHY (this session)
- Stations: both 170 tall via `STATION_LIFT = 20` in blocks.py (they were already equal at 150; the train floated
  20 studs above the tunnel floor). Alan chose the remade models over stretching the old ones.
- South tin flies as 14 invisible walls (`WALLS` in town_toys.py); its exact shape filled a wedge of the tunnel.
- Alan: 12 per server; join instantly, no lobby/wait (a bot leaves: dead > parked > unengaged > any); a beginner may
  join a friend's regular room after 1 qualifying match (`bots.friend_join_matches`). Main menu kept (read "no lobby"
  as "no waiting room"; ask Alan if he meant the menu too).
- Trigger releases stay uncapped (capping them can leave a trigger stuck; the audit's item 7 was rejected).
- Final-save confirmation fails open on a read error (no later save would retry it; a stuck session is worse).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (holds, model router, docs rules); memories look-up-roblox-ui-steps, no-surprise-desktop-control,
  studio-play-is-shared. Commit explicit paths (bell-tower WIP and closeups.png edits aren't ours).

## CARRY NOTES / GOTCHAS
- Computer-use: the running Studio is `D:\RobloxInstalls\...\robloxstudiobeta.exe`; granting "Roblox Studio" grants
  an old copy. Alan denied the second request; don't retry without his ask.
- Studio behind other windows: RenderStepped 0/s, train frozen, no autopilot flight checks; use numbers.
- Texture packs for the new station pieces: harvest after Alan's Save to File (`town_toys.py packs` then `build v4`).
- STATE.md is at 59 lines.

## WHAT SHIPPED / OTHER QUEUED
e5ef0549 stations 20 taller + schoolyard kept · 652f5c28 state · 1a211273 stations uploaded + town build ·
e658f72d texture packs · 6748ea94 tin invisible walls · 28aeebe7 playtest note · 0f4a9330 join straight in + friend
rule · 15bbe5e5 / c58864f9 / 9a16da24 state · 1d41dd57 publish IDs + safe steps · e05ca931 Save to File lesson ·
a777ec20 endurance run · 32b06951 security pass · 0680b3b5 saving risks · 3860eb87 safe server moves (Codex,
reviewed) · 690ecc32 state · this handoff.
Queued: re-publish (go), open live risks, per-frame cheat check, Stage 9 playtest.

## KNOWLEDGE UPDATED
- docs/decisions: real-players-join-instantly (new), private-publish (IDs, safe publish). docs/systems: bots (join +
  friend), flight (cheat checks), saving (published, risks), performance (endurance run), monorail (stations),
  menus-and-hud (wait screen). docs/playtests/2026-10-16 (notes 5–6). docs/workshop/lessons (tin shape, Save to
  File). Memory: look-up-roblox-ui-steps. Checker: OK (85 pages).

## POINTERS
- src/shared/BotRosterRules.luau (`releaseRank`), src/server/Matchmaking.luau (`friendCanStay`, `TRANSFER_TIMEOUT`),
  src/server/ProfileRuntime.luau (OnAfterSave confirmation), tools/town_toys.py (`WALLS`, `buildings_v4` outside()).
