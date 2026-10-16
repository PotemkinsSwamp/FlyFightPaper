# HANDOFF — 2026-10-09 — Kit sweet shop built and shown; sharper-Meshy shop half done (stopped for Alan)

★ START HERE: Goal: pick the method for city buildings that match assets/references/classroom-city-approved-v1.png. Opening action: finish the SHARPER Meshy sweet shop (8 pieces already in assets/models/sweet-shop/parts, unverified) and stand it at its old spot in the test copy. Done when Alan sees close-ups of the kit shop and the sharp Meshy shop side by side and picks one.

> Read on demand: AGENTS.md → state/STATE.md → THIS → docs/KIT.md. Memories: codex-for-pictures-and-blender, reference-not-current-buildings, studio-test-copy.

## STATE (verify before acting)
- HEAD `2481e9da` (main), local only (no remote). Confirm: `git rev-parse --short HEAD`.
- UNCOMMITTED, half-finished Codex work (job stopped at Alan's request): `tools/art/hero.py` edits; assets/models/sweet-shop: old 4 pieces + their `.upload.json` deleted, 8 new pieces written (parts.json says UV coverage 0.76-0.87, ~28.6k tris), but Codex's last log line said a compact unwrap reached only 56% and it was still editing hero.py. Check: `git diff --stat tools/art/hero.py assets/models/sweet-shop`; undo everything with `git checkout -- tools/art/hero.py assets/models/sweet-shop`.
- BROKEN until fixed: `python tools/town_toys.py build` fails (toy-placements.json still names `sweet-shop/1-ground-floor` etc., whose records are gone). WORKING still shows the old Meshy shop (already synced earlier).
- Tests: not re-run (no rules logic changed). Last 220/0.
- Studio: FlightTestG test copy (UNSAVED changes): Model `Workspace.KitSweetShop` (242 parts) on the parking lot at x 350, z 405; the lot's 8 cars parented to nil. WORKING untouched. No servers (8765 stopped).
- Cost this session: Meshy 0 credits (2,608 left). Codex 3 jobs (kit build 28 min, kit fix-up ~25 min, Meshy sharpen ~70 min stopped). ~210 free Roblox uploads (kit pieces). ~4 h wall clock.

## NEXT ACTION + PLAN
1. Sharp Meshy shop: decide keep-or-redo of the 8 pieces (look at a ground-floor close-up render; measure texture pixels per stud on the front vs old ≥ 3x). Then `town_toys.py hero assets/models/sweet-shop` (retry on HTTP 500; it skips done keys), read MeshId + InitialSize in Studio via InsertService:LoadAsset, write `mesh`/`initial` into each record, `town_toys.py stand assets/models/sweet-shop 203 405 -1.5708`, `build`. Commit.
2. Three-way look for Alan in the test copy: kit shop (lot) vs sharp Meshy (old plot); close-up from (395,45,315)→(350,32,395) and (248,45,315)→(203,32,395), air from (276,230,210)→(276,30,405). Alan picks.
3. Winner → redo city buildings (Stage 4d) one by one, Alan sees each. If kit wins: window displays need Meshy props (cupcakes, lollipops, jars, ~30 credits each, docs/KIT.md) — ask Alan before spending. Kit shop into the real town = `town_toys.py kit sweet-shop X Z ANGLE` + `build`.
4. Then Alan's FPS check of the toy town, then 4c–4g.
- HOLDS (Alan's go, each): Stage 3 gate; private publish; Studio-settings changes; anything after the ★ gate; Meshy top-ups; Meshy spend on kit props.
- Stop rule: no more kit fix-up rounds before Alan picks (one build + one correction done).

## DECISIONS & WHY (this session)
- Alan's verdict on kit round 1: "less detail, just sharper". Response: kit fix-up round (seams, tape, tints, quoin columns, bunting, chimney, roof clutter) AND a parallel free option: same Meshy model with tighter UV packing + more pieces, since Meshy has the detail and blur comes from 20% texture use under Roblox's 1024 cap.
- Kit shop kept OUT of toy-placements.json until Alan picks (placements restored after generating the loader), so WORKING is unchanged.
- Kit colour variants are extra `<piece>-color-<variant>.png` maps uploaded as record keys `color-<variant>` (town_toys.py `hero` change) instead of duplicate meshes.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look-at-the-game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last). Meshy floor 300.

## CARRY NOTES / GOTCHAS
- Test-copy loader (throwaway, was in the scratchpad, may be gone): Python reads toy-placements rows (filter `building == NAME`, or toy prefix without `building`), writes Luau that makes MeshParts with `AssetService:CreateMeshPartAsync` + SurfaceAppearance; serve on 127.0.0.1:8765, `HttpService:GetAsync` + `loadstring` in execute_luau. For the kit: run `kit` on the real placements, generate, then restore the placements file.
- New uploads show GREY in Studio for a few minutes while Roblox reviews them ("Reviewing"); wait, then reload.
- Open Cloud gave one HTTP 500 mid-batch; re-running `hero` resumes.
- Codex job status/cancel via `node ~/.claude/plugins/cache/openai-codex/codex/1.0.6/scripts/codex-companion.mjs status|result|cancel <id>`; `cancel` breaks under Git Bash (path mangling), use PowerShell `taskkill /PID <pid> /T /F`.
- screen_capture sometimes times out; a retry works.

## WHAT SHIPPED / OTHER QUEUED
- 32f622b9 Remove old one-off art scripts (only toys.py and hero.py are still used)
- b0691810 Classroom building kit (Codex, Blender): 35 pieces uploaded, kit sweet shop recipe, town_toys kit command
- 55407ec6 Kit sweet shop, fix-up round: seams, tape, brick corners, bunting, chimney, roof clutter, side awning
- 2481e9da STATE: kit test status, sharper Meshy shop half done
- Queued: method pick → 4d building redo → FPS check → 4c, 4e–4g. Codex Track C saving untouched.

## POINTERS
- docs/KIT.md; tools/art/kit.py (`pieces`, `shop RECIPE`, `verify`); assets/models/kit/buildings/ (recipe, renders, in-game-*.jpg comparison shots); tools/art/hero.py; assets/models/sweet-shop/parts.json; tools/town_toys.py (`hero`, `stand`, `kit`, `build`, `pull`).

## AAR
- Planned: kit + shop, show Alan, he picks. Actual: kit + one fix-up shown; Alan judged it less detailed; a third option (sharp Meshy) started and was cut off when Alan had to leave. Why: the kit has only as much detail as the pieces we model; Meshy's detail was the strength we under-weighed. Same next time: put both candidates in the game early so Alan judges the real thing; give long Codex jobs a time box (an hour+ with no report is a sign to stop and test what exists).
