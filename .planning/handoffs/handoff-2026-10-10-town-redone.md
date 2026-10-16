# HANDOFF — 2026-10-10 — Every town structure redone with Meshy; materials pass on all; not yet seen in game

★ START HERE: Goal: the redone toy town looks right and runs at 60 FPS in real Play. Opening action: with FlightTestG
visible (ask Alan to bring the window forward, or do it yourself while he is away), take the fixed-viewpoint screenshots
of the town at 1280x720+ and measure FPS in a 12-plane match. Done when Alan has seen the screenshots and FPS is known.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: touch-up-before-showing, codex-bake-tests-on-copies,
> parallel-art-batches, codex-for-pictures-and-blender, reference-not-current-buildings.

## STATE (verify before acting)
- HEAD `c2b10391` (main), local only (no upstream). Confirm: `git rev-parse --short HEAD`.
- Tests: not re-run (no rules logic changed); last 220/0. Uncommitted on purpose: FlyFightPaper-WORKING.rbxlx.
- Studio: FlightTestG test copy has every new building placed by Luau (CityToys) and classroom.rbxmx drops synced by
  Rojo; UNSAVED. Everything is also in files: `python tools/town_toys.py build` writes city-toys.rbxmx (1,099 toys,
  "not made yet: none"), which is how WORKING gets them. Nothing running (no Blender, no servers).
- Cost this session: Meshy 700 credits (20 jobs; 1,803 left, floor 300). Codex 8 jobs (concepts x2, bake robustness,
  materials pass, flagpole x2, clock shards; ChatGPT plan). Claude: 1 Sonnet research agent (~115k tokens). ~16 h wall
  clock. Primary context ~85% at handoff.

## NEXT ACTION + PLAN
1. In-game look + FPS (above). Screen capture (Roblox_Studio screen_capture) times out whenever FlightTestG is hidden;
   Alan declined computer-use control while he was at the PC, so ask or wait until he is away.
2. Fix what the screenshots show, worst first. Known: Gateway back-ruler notch + one see-through window (re-bake with
   `"delete_rule": "all"` in assets/models/gateway-towers/touchup.json); crayon tips/roof dark in Blender previews
   (judge in Roblox light); faint dark streaks on the pencil-case top. One fix round per building, then show Alan.
3. If FPS is short: re-bake the heaviest at lower `--detail` (Gateway 88k, Lookout 65k, Paint Palette 65k, Clock 63k).
4. Then Alan's FPS check of WORKING, then 4c, 4e-4g.
- HOLDS (Alan's go, each): Stage 3 gate; private publish; Studio-settings changes; anything after the ★ gate; Meshy
  top-ups; Meshy spend on kit props. Building redo itself is approved.
- Stop rule: a building is done when its close-up sheet is clean and Alan has seen it in game; no re-review without
  his comment.

## DECISIONS & WHY (this session)
- Bake at `--detail 2.5` (~40k triangles a building): Book Apartments at 2.5x looked almost like raw Meshy
  (assets/models/book-apartments/detail-compare.jpg); the old setting smeared ground floors. Alan asked how to keep
  Meshy quality; raw Meshy (650k-965k tris, one 1024 map) is impossible in Roblox, so pieces + bake stays.
- Materials pass (tools/art/materials.py, Alan picked "stronger"): per-material roughness/metal/micro-normal from the
  colour map; Meshy's own roughness was near-uniform, so everything read flat.
- Touch-ups (touchup.json): delete boxes + clean boxes/cylinders/cones/lathe shapes + paint-only decals. Default cut
  rule "center"; "all" for cuts against a wall (clock). Coordinates are studs at the baked height: rescale if the
  height changes (gateway bug).
- Gateway baked 265 tall (not 319) so it fits its plot; pencil case is a small prop on its bridge (150 long, detail 1).
- Flagpoles: floating ones re-seated, 3 removed (gateway/spire have own flags; pencil cup; ruler bridge spot); the rest
  are Codex's Blender pencil-flagpole toy. Freed plots and facings are in STATE "Decisions to review".

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE <=60 lines, hard limits), CLAUDE.md (plain English, handoff last).
- Memories listed above.

## CARRY NOTES / GOTCHAS
- The per-building upload/place helpers lived in the scratchpad (up.sh, fin.sh, check.sh, serve.py on :8766 that
  accepted Studio POSTs): gone. Steps: `materials.py FOLDER` → `town_toys.py hero FOLDER` → `readlua` in Studio →
  `meshes` → `stand X Z ANGLE` → `drop X Z R NAMES` → `placelua` in Studio → `build`. Worth one `town_toys.py place`.
- After a re-bake, delete the folder's parts/*.upload.json before uploading (hero.py reuses stale records).
- Running `tools/rug.py` rewrites fill-plan.png, preview.png, toy-spots.json: `git checkout` those afterwards.
- Your C: drive 98% full (5 GB): a bake once failed to save a file; ask Alan, don't clean his disk.
- Big bakes run out of memory beside another; run tall buildings one at a time.

## WHAT SHIPPED / OTHER QUEUED
- 39 commits `28addd18..c2b10391` (git log). Highlights: c04c7714/bf773ae0 ruler bridge; 5ec2251e touch-ups + closeups.py;
  ae1ab3fe, a0258b13 (Codex) bake robustness + clock shards fix; d7049e83/7ad6d88d materials pass; 717b9631 pencil
  flagpoles; f07830ce clock tower; 01b02b08/f146870d/ffe94345 book stacks; 8332a745 open book; a9f2daf2 pencil case.
- Queued: in-game check + FPS; known flaws above; FPS check by Alan; 4c, 4e-4g. Codex Track C saving untouched.

## POINTERS
- tools/art/hero.py, tools/art/closeups.py, tools/art/materials.py, tools/art/toys.py, tools/town_toys.py, tools/meshy.py,
  assets/MESHY_LOG.md (research tips at top), assets/models/*/touchup.json, assets/rug/toy-placements.json.

## AAR
- Planned: Meshy the 14 concept sets, place each, show Alan; then pencil cup, FPS, 4c-4g. Actual: all 22 town
  structures + flagpoles redone and placed, materials pass added; nothing seen in game; FPS not measured.
- Why: Alan's three notes (melted railing, quality loss, flat materials) each exposed a pipeline bug (over-decimation,
  per-band cap, hole repair) that took several 1-1.5 h bake cycles; Studio capture blocked all session.
- Next time: get Studio visible first; brief Codex regression bakes onto copies (memory written); keep the helper
  scripts in the repo, not the scratchpad.
