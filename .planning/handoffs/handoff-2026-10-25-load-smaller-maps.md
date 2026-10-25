# HANDOFF — 2026-10-25 — Town bump/shine maps half size + fresh texture packs (in Studio and local file); streaming proposed skipped

**Labels:** kind=infra · lane=load · branch=main · issues= · areas=tools/town_toys.py, assets/models/*/parts, assets/models/toys, assets/models/flat-maps.json, assets/models/texture-packs.json, assets/models/city-toys-v4.rbxmx, FlyFightPaper-WORKING.rbxlx, docs
**Time:** 2026-10-25 03:22 -04:00

★ START HERE: Goal (Alan): a phone joins in under a minute (seconds ideally) and the game looks the same. The smaller
maps are built and in the open Studio copy; the opening step is **Alan's** publish + phone join (his go). Done when
his phone loads clearly faster and he OKs the look (`.planning/load-maps-town-before-after.jpg`).

> Read on demand: AGENTS.md → THIS → `docs/plan/LOAD-PLAN.md` (Progress, "Step 3 looked at closely"); `state/STATE.md`;
> `docs/workshop/lessons.md` (two 2026-10-25 lines: packs throttled, "Reviewing" isn't the verdict). Memories:
> alan-does-play-checks, look-at-textures-before-upload, studio-play-is-shared.

## STATE (verify before acting)
- HEAD `d2a0e5bb` + this handoff's commit on main; the commit hook pushes to GitHub (`git log --oneline -3`).
- Docs checker OK (132): `python tools/check_docs.py`. Unit suite 425/0 last session, not re-run (no game code
  changed): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` in the Server VM.
- Studio: the cloud copy (placeId 132768925825316) is open, Edit mode, with every changed SurfaceAppearance swapped
  live and all 2,432 packed (not saved; Alan publishes from it). Local `FlyFightPaper-WORKING.rbxlx` rebuilt by
  `save_place.py` with the same ids + packs. Play check: in 7.1 s, no new errors.
- Cost: 1 Explore (Sonnet, ~135k tokens, streaming audit); 0 Codex; 1,187 image uploads (free) + 33 tiny; ~2 h wall
  clock mostly uploads; 1 Claude Play run.

## NEXT ACTION + PLAN
1. Alan publishes from the open Studio copy and joins on his phone (/console shows load times). Check: clearly faster,
   town looks right. He also judges the few buildings whose look changed (see DECISIONS).
2. Streaming (load step 3): proposed **skip** (LOAD-PLAN "Step 3 looked at closely"); needs Alan's OK.
3. If the phone still waits on pictures: load step 4 (fewer, bigger picture sheets), its own short plan first.
4. UI lane: small iPhone + iPad re-check (`ScreenCheck.run()` in Play; Alan switches devices), then screen fit
   steps 3-6 (`docs/plan/SCREEN-FIT-PLAN.md`).
Stop rule: a step is done when its check passes and Alan has seen it; no review rounds.
HOLDS (Alan's go, each): publish (he does it), Save to File, closing Studio, desktop control, Meshy, anything paid,
any upload, real product IDs/prices, sales on, Studio Play while he plays.

## DECISIONS & WHY (this session)
- Half-size rule lives in `town_toys.send` (both `hero` and `upload`), so every future upload follows it; flat maps
  (std < 3 on an 8x-reduced copy) share one 16x16 map per exact value (`assets/models/flat-maps.json`).
- Skipped on purpose: bell tower (its maps caused the 2026-10-12 bans) and sweet-shop `8-topper` (lollipop swirl):
  their accepted maps stay.
- One upload rejected: a uniform grey 16x16 roughness (`roughness 133,133,133`); removed from flat-maps.json; the 4
  ring-binder pieces using it keep their old ids. Never re-send it.
- Look change is from packs, not map size: old maps vs new maps drawn the same way differ 0.5/255. The old saved
  packs on some buildings were stale (pre-10-Oct materials pass); fresh packs show the current materials (cereal-box
  tower grainier, notebook/clock paler, ceiling moon darker). Kept the fresh look; Alan to judge.
- Streaming proposed skipped: the town is all in view and `FlightRules.contact` runs on the phone, so every solid piece
  would have to stay loaded anyway (Explore audit: ~10 places would need fixes).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; decisions 2026-10-10-no-quality-cuts-for-fps and 2026-10-25-fast-phone-loading; memories above.

## CARRY NOTES / GOTCHAS
- Studio copy ≠ saved: if Studio closes before Alan publishes, the cloud copy loses the swap. The local rbxlx has it.
- Packs: scripts can't read `TexturePack`; `SerializationService:SerializeInstancesAsync({sa})` shows it. Studio can
  POST/GET localhost from execute_luau (used a scratch receiver to collect packs; nothing left running).
- `save_place.py` still reports "1 left for Studio" exact-collision part (pre-existing, not from this session).
- Console "Asset type does not match" lines (ids 9114237705, 1169806635 …) at Play start: old non-town ids, not ours.

## WHAT SHIPPED / OTHER QUEUED
- 15b600ba Uploads: bump and shine maps go up at half size; flat ones share one tiny map per value
- d2a0e5bb Town bump and shine maps at half size, flat ones shared; every piece gets a fresh texture pack
- + this handoff (STATE, LOAD-PLAN step 3 proposal, lessons).
- Queued (Alan's): stick tuning; winners' sound check; prices; drawing pass; touch step 6 publish.

## KNOWLEDGE UPDATED
- plan/LOAD-PLAN: "Step 3 looked at closely" (skip proposal) + Progress line for the maps. systems/performance:
  Phones paragraph. workshop/tools: town_toys row. workshop/lessons: +2 (pack throttling + SerializationService
  read; "Reviewing" isn't the verdict). STATE rewritten top. Checker OK (132).

## AAR
Supposed: shrink maps, upload, swap, Studio same, phone faster. Actual: done, plus a pack detour: Studio re-made ~2,000
packs at once (429s), and stale old packs showed as a look change. Why: packs are invisible to scripts, and nobody
had checked old packs against their maps. Next time: before swapping maps on many pieces, plan to re-make packs in
slow batches and compare old maps without packs first. Cost matched output.

## POINTERS
- `tools/town_toys.py` (`send`, `packs`, `build v4`), `tools/save_place.py`, `.planning/load-maps-town-before-after.jpg`.
