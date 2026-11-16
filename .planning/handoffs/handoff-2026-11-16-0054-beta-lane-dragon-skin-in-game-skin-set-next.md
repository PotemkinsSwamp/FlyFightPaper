# HANDOFF — 2026-11-16 — Dragon is in the game as a skin and the hitbox (Alan: "looks good now"); next: its boosters, then 8 Commons + 8 animated Rares

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=src/shared/SkinFit.luau, src/server/HitShapes.luau, src/client/CombatEffects.luau, config/skin-shapes.json, config/plane-areas.json, tools/plane_areas.lua, docs/decisions/, .planning/skins/dragon/
**Time:** 2026-11-16 00:54 -05:00

★ START HERE: Goal (Alan 2026-11-16, [first skin set](../../docs/decisions/2026-11-16-first-skin-set.md)): finish the skins for the beta. Opening action: make the boosters under the Dragon wear the Dragon ("the boosters don't match the dragon skin"). The crane's boosters wear its printed sheet (a `picture` in `config/looks.json`); the Dragon has none. Done when Alan sees a booster under the Dragon and OKs it.

> Read on demand: AGENTS.md → this file → the [first skin set](../../docs/decisions/2026-11-16-first-skin-set.md) decision → [planes page](../../docs/systems/planes-and-hangar.md) (shape skins paragraph) → `.planning/skins/dragon/paint/tools/README.md` (last two sections). Memories: `look-at-textures-before-upload`, `plan-before-building-features`, `offer-pieces-catch-the-eye`, `hand-made-not-generic-roblox`, `alan-does-play-checks`, `mute-studio-tests`.

## STATE (verify before acting)
- HEAD = this handoff's commit on `f2d14232`; main; GitHub copy pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests 665/0 (2026-11-16, Studio Play with Alan's go). Re-run: Play, then on the server `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. Docs: `python tools/check_docs.py` OK (195 pages).
- Studio: Edit, code synced by Alan's own `rojo serve` (port 34872, already running; mine failed because his was up). Place NOT saved. The two look-only models (`DragonLook`, `DragonFitTest`) are removed.
- Uploads: 28 free files, all Approved (22 per-part look files `.planning/skins/dragon/roblox/uploads.json`; 6 game files `roblox/game/uploads.json`). Tripo credits 5,820 (none spent).
- Cost: main session only (Fable, then Opus 5.5 from mid-session), no helper agents, no Codex; ~60% context at handoff. No money.

## NEXT ACTION + PLAN
1. Dragon's boosters wear the Dragon (above). Look at how the crane's booster sheet was made (`tools/art/crane_skin.py` booster dressing, `skin_looks.py`) before choosing. Check: Alan's OK on a booster under the Dragon.
2. The comparison test (Alan): ONE test skin made two ways, Fable with its usual tools vs TextureCraft (`docs/workshop/lessons.md` "TextureCraft"), shown side by side; Alan picks the way.
3. The 8 Commons (Hazard Stripes exists; Carbon Fiber, 8-Bit, Neon Grid, Flame Decal, Tie-Dye, Racing Stripe, Jungle Camo), then the 8 Rares (Galaxy, Lava, Slime, Holographic, Glitch, Thunderstorm, Circuit Board, Comic Book). Rares MOVE: a how-it-works note for Alan's OK before any animation code. `config/looks.json` to match his lists (Gold Foil, Tiger Stripes, Frozen: "not including them yet").
4. Dragon leftovers: printed sheet for the crash ball and the shop card; the jaw chevron; the frame-rate check with 12 Dragons (Play: his go).
- HOLDS (Alan's explicit go, each): Studio Play (tests count; he OK'd each run so far), place saves, publish (he does it), desktop control or screen grabs, Tripo credits (count first), bot matches, any new mechanic or number (the Rares' movement is one). Uploads of skin pictures follow the safety check (contact sheet, gap fill, LOOK) every time.
- Stop rule: nothing is "done" without Alan's look; show each new skin assembled on a plane in Studio before uploading more than the test.

## DECISIONS & WHY (this session; all in the [shape-skin decision](../../docs/decisions/2026-11-14-shape-skin-model-sheets.md))
- Wings 0.69 studs forward (on the 8.4-stud model), both sides: Alan moved them in Studio (0.67 / 0.71), "make them like the same number".
- One mesh + one 1024 picture set (budget rule); compare picture `.planning/skins/dragon/roblox/game/compare-one-set.jpg`.
- The Dragon IS the plane's hit and crash shape (Alan's idea, after invisible heavy-plane parts): as big a target as the plane (outlines from above + side + behind, added; `config/plane-areas.json`) and never shorter or narrower than the plane ("a little too small" on the fast frame). This replaces "a skin never changes the hitbox" for the Dragon only. The earlier 1.25x cap is gone.
- Shots from a shape-skin's moved gun were drawn 1-3 studs off the real shot the whole way; they now slide onto the real path within 15 studs. "Dev: skin" now tells the server (Studio only).
- My own calls (STATE "Decisions to review"): Dragon centred lengthwise, guns under a triangle outline of its wing, the 15 studs, each part's share of the 1024 set.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md hard limits and docs rules; Blender only for 3D (no Meshy); Codex paints (`codex exec -s workspace-write - < prompt.txt`, never `--model`). Alan wants this work on the Fable model.

## CARRY NOTES / GOTCHAS
- `tools/plane_areas.lua` must be re-run (and `config/plane-areas.json` updated) when plane parts change; a build missing from it gets only the never-smaller floor.
- The monorail train tests the corners of each crash shape's BOX; for the Dragon those reach past its wings (a train can hit near a wingtip with a gap showing).
- The Dragon pipeline scripts are untracked under `.planning/skins/dragon/` (new: `upload_prep.py`, `roblox_fbx.py`, `roblox_upload.py`, `atlas_bake.py`); promote to `tools/art/` with a docs entry if reused for other skins.
- Edit-mode `require` is cached: run synced code via renamed clones (lessons.md).
- Older carries: stray `C:\parts` folder (Alan may delete); backlog: desk photos under the crane, crane gun pieces while firing, Toilet Roll shake recorder.

## WHAT SHIPPED / OTHER QUEUED
- `eda61171` Dragon is in Studio for Alan to look at (22 free uploads, all approved)
- `743946db` Dragon becomes a shape skin that keeps its proportions (wings forward, cap 1.25x the plane)
- `9ea41efe` Dragon is the hitbox: as big a target as the plane it is on, centred
- `e509d90c` Tests 665/0 with the Dragon skin
- `6377ab1a` Dev skin button now tells the server, so a tried-on Dragon is the hitbox in Studio too
- `34513243` Dragon is never shorter or narrower than the plane it replaces (Alan: too small on the fast frame)
- `9f44e8ed` Shots from a shape-skin gun slide onto their real path, so hits no longer look like misses
- `df0511d6` Dev skin check skips the tests' pretend players (tests 665/0)
- `f2d14232` Dragon flown and approved (looks good now); first skin set planned: 8 Commons, 8 animated Rares
- This handoff's commit: handoff, LATEST, the comparison-test line in the skin-set decision, lessons.
- Queued after skins: Shark Jet, trails, missions, playtime calendar, bots that use the town.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-16-first-skin-set.md` (new, in README): Alan's lists, Rares move, TextureCraft comparison first.
- `docs/decisions/2026-11-14-shape-skin-model-sheets.md`: verdict, wings, fit, hitbox, never-smaller, "looks good now".
- `docs/decisions/2026-11-13-skin-rules.md`: the Dragon exception to "a skin never changes the hitbox".
- `docs/playtests/2026-11-16-dragon-skin.md` (new, in README). `docs/systems/planes-and-hangar.md`: Dragon paragraph, Dev skin, shots slide, Code table. `docs/plan/SKINS-PLAN.md`: status. `docs/workshop/tools.md`: `plane_areas.lua`. `docs/workshop/testing.md`: 665/44. `docs/workshop/lessons.md`: 4 lessons (ask how before diagnosing, answer his suspicion first, sizes from exact shapes, test players are tables, fresh code in Edit).
- `state/STATE.md` rewritten top (58 lines). Checker: OK (195 pages).

## POINTERS
- Fit code: `src/shared/SkinFit.luau` (`evenFit`), `src/server/HitShapes.luau` (`covers`), tests `tests/unit/SkinFit.spec.luau`.
- Dragon game files: `.planning/skins/dragon/roblox/game/` (atlas, whole.npz, dragon.fbx, uploads.json); mesh 110832316998528.
