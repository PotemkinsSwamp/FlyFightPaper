# HANDOFF — 2026-10-25 — Fresh phone join measured (45 s blank + 62 s); Alan's plan: menus first via per-player streaming, load recorder, repack town sheets

**Labels:** kind=infra+docs · lane=load · branch=main · issues= · areas=docs/plan/LOAD-PLAN.md, docs/playtests, docs/decisions, state/STATE.md
**Time:** 2026-10-25 03:51 -04:00

★ START HERE: Goal (Alan): a phone joins in under a minute (seconds ideally) and looks the same. Opening action:
build load plan step 1 (menus first: StreamingEnabled with the town `PersistentPerPlayer`, sent to each player once
their menu pictures are in; Play waits for the town). Then steps 2 (load recorder) and 3 (repack the town's picture
sheets), in order, until all are done (Alan). Done when Alan's fresh phone join shows the menus in seconds and the
whole load is under a minute, with the same look.

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` ("Next three steps"); the previous handoff
> `handoff-2026-10-25-load-smaller-maps.md` (packs, gotchas); `docs/playtests/2026-10-25-phone-fresh-join.md`.
> Memories: alan-does-play-checks, studio-play-is-shared, look-at-textures-before-upload, exact-collision-baked.

## STATE (verify before acting)
- HEAD `7573d200` + this handoff's commit on main; commit hook pushes to GitHub. `git log --oneline -3`.
- Docs checker OK (133): `python tools/check_docs.py`. Unit suite 425/0 (2026-10-24), not re-run since (no game code
  changed): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` in the Server VM.
- Published game = smaller maps + fresh packs + Skip (Alan published from the cloud copy). Studio has that cloud copy
  open; local `FlyFightPaper-WORKING.rbxlx` rebuilt to match (`save_place.py`). Rojo serve on 34872 (check).
- Cost this session: see the previous handoff (1 Explore Sonnet ~135k; 1,220 free uploads; ~2.5 h). This part: docs only.

## NEXT ACTION + PLAN
1. **Step 1, menus first.** StreamingEnabled on; town + heavy room pieces `ModelStreamingMode.PersistentPerPlayer`;
   server calls `AddPersistentPlayer` when the client reports its menu pictures loaded; nothing streams out (flight
   contact runs on the phone, `FlightRules.contact`). Fix the audit's spots (listed in LOAD-PLAN step 1; re-run a
   quick search for others). Check: Studio Play in the Device Simulator (phone) with the
   loading timings; unit suite 425/0; then Alan publishes and does a fresh join (delete + reinstall Roblox).
2. **Step 2, load recorder** (DataStore, read in Studio). Check: Alan's join shows up with numbers.
3. **Step 3, repack picture sheets** (46 buildings, Codex + Blender, ~600 uploads with contact sheets, saved
   collision + packs redone). Check: close-ups same look; fewer, smaller files; fresh join under a minute.
4. Then the UI lane: small iPhone + iPad re-check (Alan switches devices), screen fit steps 3-6.
Stop rule: each step done when its check passes and Alan has seen it on his phone; no review rounds.
HOLDS (Alan's go, each): publish (he does it), Save to File, closing Studio, desktop control, Meshy, anything paid,
real product IDs/prices, sales on, Studio Play while he plays. Step 3 uploads: **go given** ("continuing to work until
all steps are done", 2026-10-25, choosing Repack); any other upload needs his go.

## DECISIONS & WHY (this session)
- Streaming reversed from "skip": it can't shrink the download, but it is the only Roblox tool that controls the
  order; PersistentPerPlayer gives per-player timing and keeps the town loaded once sent.
- Step 3 = Repack (Alan), not half-size colour: same look, his standing rule.
- Alan judged the town after smaller maps + fresh packs: "everything looks the same".

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps, 2026-10-25-fast-phone-loading; lessons.md upload section.

## CARRY NOTES / GOTCHAS
- Rojo live-syncs edits into the open Studio copy, which Alan publishes from: test each edit in Play right away.
- Streaming changes when `game.Loaded`/replication finish; `NativeAssets.ready` counts tagged town parts and would
  hang under streaming (no timeout).
- Estimates (our source files, not Roblox's delivered bytes): colour PNGs ~470 MB, bump/shine ~170 MB, FBX ~90 MB.
  ROBLOX_API has no asset-delivery scope (403), so delivered sizes can't be read; the recorder gives real times.
- Packs: re-make slowly after map changes (lessons.md); read via `SerializationService`.

## WHAT SHIPPED / OTHER QUEUED
- 15b600ba Uploads: bump and shine maps go up at half size; flat ones share one tiny map per value
- d2a0e5bb Town bump and shine maps at half size, flat ones shared; every piece gets a fresh texture pack
- 7573d200 Handoff: town bump/shine maps half size with fresh packs; streaming proposed skipped
- + this handoff (playtest note, decision update, LOAD-PLAN next three steps, STATE).
- Queued (Alan's): stick tuning; winners' sound check; prices; drawing pass; touch step 6 publish.

## KNOWLEDGE UPDATED
- playtests: new 2026-10-25-phone-fresh-join (+README). decisions/2026-10-25-fast-phone-loading: the three steps.
  plan/LOAD-PLAN: "Next three steps" replaces "Step 3 looked at closely". STATE rewritten top. Checker OK (133).

## AAR
Supposed: smaller maps make the phone clearly faster. Actual: 1 min 47 s on a fresh phone; 45 s of it before any menu
art. Why: I treated it as a size problem; the first half is ordering (one download line for everything sent at join).
Next time: measure a fresh join (app reinstalled) before choosing fixes; ask the phone for timings split by phase.

## POINTERS
- `src/client/Loading.luau`, `src/first/LoadingFirst.client.luau`, `src/shared/NativeAssets.luau`,
  `src/server/FlightService.luau` (tags, ownership), `src/shared/FlightRules.luau` (`contact`).
