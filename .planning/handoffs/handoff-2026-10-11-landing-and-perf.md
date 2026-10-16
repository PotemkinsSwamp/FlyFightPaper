# HANDOFF — 2026-10-11 — Real landing in; slow Play solved (exact-collision switched off); hangar menu + proper collision fix next

★ START HERE: Goal: a fast, correct game Alan can play-test. Opening action: build the PROPER collision fix from
`docs/PERFORMANCE-RESEARCH-2026-10-11.md` (exact building shapes computed once in Studio and SAVED in the place, not
built at server start; save_place/town_toys must stop discarding them), then re-enable exact collision. Done when
Studio Play starts in under ~15 s (log `PlaySoloPlayableTotalTime`) AND planes collide with the real building shapes
(fly through the Gateway arch).

> Read on demand: AGENTS.md → state/STATE.md → THIS; briefs `.planning/briefs/2026-10-11-*`. Memories:
> texture-packs-after-new-models, studio-test-copy, no-quality-cuts-for-fps, touch-up-before-showing.

## STATE (verify before acting)
- HEAD `ab858f3d` (main), local only (no remote). Confirm: `git rev-parse --short HEAD`.
- Tests: 221/0 (Studio Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Studio: WORKING open in Edit (restarted 2026-10-11 ~19:00 UTC, new studio_id — `list_roblox_studios`), Rojo
  serving serve.project.json. **Live Studio has ALL town meshes set to CollisionFidelity Box (test; not in the repo
  build, which writes Hull for solid toys).** Alan may or may not have Ctrl+S'd after that.
- Play start: 3 s with `HitShapes.exactRoom` off (`FlightService.luau:23`), was 30-300 s. Proven by A/B.
- **Codex job still running at handoff:** task-mv453n15-y85iby (brief `2026-10-11-rebake-holes-flag.md`): Banner
  Tower flag removed (done), Gateway arch roof hole + side notch (in progress), Garden roof hole (next). Writes only
  to `assets/models/_rebake/`. Check: `node ~/.claude/plugins/cache/openai-codex/codex/1.0.6/scripts/codex-companion.mjs status task-mv453n15-y85iby`.
- This session's Studio MCP had 0 tools; drove Studio via a direct StudioMCP client (tools/studio_cli.py works too).
- Cost: Codex (Sol) 9 jobs (fixtures-free: 2 pictures, 2 fan/hangar incl. one failed-question restart, 1 menu refs,
  1 rebake running, 3 forwarders); 1 general-purpose research agent (~261k tokens, 13 min); ~140 free Roblox uploads;
  no Meshy; ~11 h wall clock; primary context ~82% at handoff.

## NEXT ACTION + PLAN
1. Proper collision fix (see START HERE). Keep building detail (Alan: "make the models work, don't reduce them").
   Also from the research: Loading.luau preloads mesh ids as strings (444 fail every join) — preload only UI images.
2. Collect the Codex re-bake: review close-ups (every roof from above), `town_toys.py hero`/readlua/meshes/stand/
   placelua/build for gateway-towers, book-stack-garden, banner-tower; stand the wooden `flagpole` toy at the Banner
   roof centre (Codex reports deck height/centre). Then ask Alan for Ctrl+S and harvest packs (memory).
3. In-game hangar menu (brief `2026-10-11-hangar-landing.md`: layout B, kid crayon drawing on journal paper, buttons
   drawn, REAL 3D plane in a ViewportFrame, 5 real build slots, score+timer, service buttons, LAUNCH). Replaces
   FlightHUD's DESK launch button/service row.
4. Then Track A leftovers: missing-model sweep, 90 texture sets, 8-viewpoint pass.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.

## DECISIONS & WHY (this session)
- exactRoom OFF (committed, marked in code): it built PreciseConvexDecomposition shapes for 357 meshes on every
  server start. Until the proper fix, planes collide with each part's own simpler shape. Reverse = uncomment line 23.
- Landing (Alan's design): ring 145 out / 15 up from the pad, 35° runway-aligned cone; touchdown 92 out, taxi into
  the hangar (69 back), turn to face out; spawn in the hangar. Numbers in config/gameplay.json `service`.
- Pads moved under hangars (z ±919); runways run desk edge → pad; side desks: 2 unnumbered hangars (85% size).
- Chairs 60 further back; avatars seated by the hips on the seat (AvatarService) — all 12 clear the desk by 11+.
- Clock on east wall; FanSpin turns blades client-side (AXIS from floor-fan-blades/checks.json).
- See-through toys write CollisionFidelity Box in town_toys build (harmless, cheaper).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).
- no-quality-cuts-for-fps: never lower building detail/texture for speed.

## CARRY NOTES / GOTCHAS
- After placing new models: Alan Ctrl+S → `town_toys.py packs FlyFightPaper-WORKING.rbxlx` → build (else Play re-packs).
- `town_toys.py pull` before any rebuild if Alan edited CityToys in Studio (he moved open-book-hall + 2 bushes today).
- Hero bakes: never pass --cuts/--parts; always `--detail 2.5` (forgetting it halved Banner triangles once).
- Studio camera: set both CFrame and Focus (edit camera keeps its own rotation otherwise); grabs need Studio in front.
- Banner roof: tape strip didn't render in the first taped bake; the Codex rebake carries the wider strip.

## WHAT SHIPPED / OTHER QUEUED
- 12c89fe4 mesh ids · 47776818 classroom fixtures · a54ac8fc playground + clock · b028cff0 east bunting · ebf9af7f east
  posters · f7ae9447 Banner re-baked · 1f3091e4 round fans + numbered hangars · 5092f59a/30baf150/ef86a817 hangar briefs
  · e7e7bd3c menu references · 070833a8 Alan's Studio edits kept · 98b57f0c rebake brief · e3b2e297 real landing ·
  655be0d7 side hangars · c7d52d4e/f6c26285/67530752/2bcb672f STATE · 8508bbca texture packs · 82942fc6 Box for
  see-through toys · ab858f3d exactRoom off + research doc.
- Queued: plan items 1-4; Codex Track C saving untouched.

## POINTERS
- docs/PERFORMANCE-RESEARCH-2026-10-11.md (causes, ranked fixes, measurement plan).
- .planning/briefs/2026-10-11-{hangar-landing,rebake-holes-flag,performance-research,round-fan-hangar-numbers}.md
- src/server/HitShapes.luau (exactRoom), src/shared/ServiceRules.luau (landing rules), tools/classroom_pictures.lua.
