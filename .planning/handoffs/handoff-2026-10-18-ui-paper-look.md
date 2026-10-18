# HANDOFF — 2026-10-18 — Stage 9 approved; shop planned; planes start looking like paper

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/shared/Aircraft.luau, src/shared/FlightRules.luau, src/server/FlightService.luau, src/client/FlightController.luau, tools/ducts.py, tools/art/plane_paper.py, assets/models/planes/paper-sample, docs

★ START HERE: Goal: every plane part looks like paper in Roblox (UV layout + near-white paper colour/normal/
roughness maps tinted by team colour, like the Classic sample) so skins can work later. First action: extend the
Classic paper sample (`tools/art/plane_paper.py`) to the other 22 parts and boosters. Done = in Studio Play every
part shows its creases and paper edges, team tints right in TDM and FFA, sizes/pivots unchanged, tests 328/0, and
Alan OKs it.

> Read on demand: AGENTS.md → THIS → [paper look decision](../../docs/decisions/2026-10-18-paper-look.md) →
> [shop plan](../../docs/decisions/2026-10-18-shop-plan.md). Then only what the step touches: `docs/systems/
> planes-and-hangar.md`, `assets/models/planes/paper-sample/README.md`, `tools/art/plane_pieces.py`, lessons.md
> ("Uploads and Roblox moderation"). Memories: look-at-textures-before-upload, powershell-commands-for-alan.

## STATE (verify before acting)
- HEAD `04aa8069` + this handoff on main; post-commit hook pushes to GitHub ("github: pushed"). `git status -sb`.
- Tests 328/0 (2026-10-18, after the colour change). Re-run in Play (server):
  `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open in Edit (Play stopped), Rojo serving on 34872. Test planes removed. **The place file is not saved**:
  the duct fan fix lives in the open place (and in `tools/ducts.py` + `ducts.model.json`) until Alan does
  File > Save to File.
- Cost this session: 1 Sonnet research helper (~210k tokens, 10 min); 2 Codex rounds via codex-rescue (~35k Claude
  tokens each, ~28 min each, Codex on Alan's plan); 1 Open Cloud upload run by Alan (48 files); 2 web searches.
  Primary context ~42% at handoff.

## NEXT ACTION + PLAN
1. **Paper texture for all parts.** Codex extends `plane_paper.py` to the set (`assets/models/planes/set/`, five
   bodies, five noses, five wings, five tails, three boosters, with their -L/-R halves) at round-2 quality. Claude
   checks renders, then a contact sheet of every map (contrast-boosted AND real values) for symbol-like shapes.
   Upload: Alan runs it (auto mode blocks Open Cloud uploads); **needs his go**. Then wire it into the game:
   `plane_pieces.py` / AircraftPieces get the new MeshIds + a SurfaceAppearance per piece (MeshId can't be set by
   script or Rojo: build through `pieces.rbxmx`/`save_place.py`, or LoadAsset in Studio). `Aircraft.paint` already
   tints SurfaceAppearance. Check: Studio Play close-ups in both team modes, hangar preview, deaths (PlaneDeaths keeps
   SurfaceAppearance), tests.
2. Prestige design (rules in the shop plan), then Stage 10 shop (stays off until Alan OKs prices), tutorial,
   Stage 11.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid (incl. the drawing pass's
outside AI check), desktop control, closing Studio, Save to File is his. Don't steer his plane in his Play.
Stop rule for the texture work: if a round looks right at game distance in Studio Play, ship it; touch-ups only on
parts that clearly look wrong.

## DECISIONS & WHY (this session)
- **Walls by angle** (built, Alan re-checked, Stage 9 approved): under 25° = scrape + wobble (nose and aim knocked
  10° off, roll swing up to 30° over 0.9 s), steeper = crash; train front still kills ([decision](../../docs/decisions/2026-10-18-scrapes-wobble.md)).
- **Shop plan** (Alan): boosts, Paper, early part unlocks by level (never XP), body bundles (no unlock-all), emotes,
  trails, stickers + sticker editor, fold effects, paper types, VIP, private servers with match settings,
  whole-plane skins stretched to real size, special planes (Paper or Robux), freehand drawing pass (reports + an
  outside AI check off the game, fair to payers), prestige that takes parts back but keeps Paper and cosmetics.
  Draft prices: [pricing research](../../docs/research/PRICING-RESEARCH-2026-10-18.md) (2x XP 1,499 > 2x Paper 999).
- **Paper look** (Alan): keep the models; add UVs + paper maps; softer team colours red 214,78,72 / blue 70,128,214
  (live). He found "rebuild as thin sheets" too much.
- Duct fan rings trimmed top/bottom to the duct (plate fills above/below the blades); no see-through gaps.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds, no runtime AI). Lessons: texture checks before any upload.

## CARRY NOTES / GOTCHAS
- Round-2 maps are near-white (217-254), so faint shapes only show with contrast boosted; check both.
- Codex sample renders flatter than Roblox shows; judge in Studio, not in Blender.
- STATE "Waiting on Alan": Save to File; drawing-check cost go; prices OK.
- Still open from before: cutscene-start hitch; vote-lap strip shows the old round.

## WHAT SHIPPED / OTHER QUEUED
- 61680f93 Shallow wall and train grazes scrape and wobble you; head-on hits crash
- 7f5d64fa Stage 9 approved by Alan
- 90101b93 / e21cd76c / 5caad9f7 Shop plan: what we sell; special planes, drawing; drawing safeguards
- 7d8e7d6c Pricing research and a draft price ladder
- be89d645 / 7387f414 Price ladder changes with Alan; prestige takes parts back
- 2c45a25a Repair shop plan note (a bad edit had garbled it)
- c85c771e Duct fan housings no longer poke through the classroom ceiling
- e3844394 / 4e61d9d6 Paper retexture sample rounds 1-2 (Codex)
- c934becf Uploader for the paper-sample Classic plane · 8b5c08a9 sample uploaded (12 meshes, 36 maps)
- 6d8d2914 Softer coloured-paper team colours; textured pieces take the team tint
- 04aa8069 State: paper look started, shop planned
- Queued: plane emotes for the shop (Meshy/uploads need go); desk decorating, season sticker book (later).

## KNOWLEDGE UPDATED
- decisions: scrapes-wobble (built), stage-9-approved, shop-plan, paper-look (+ README). playtests: 2026-10-18.
- systems: damage-and-deaths, flight, monorail (angle rule), escapes (fans), planes-and-hangar (colours, sample).
- VISION (early part unlocks allowed, cosmetics planned), MILESTONES (Stage 9 approved, Stage 10 points to plan),
  research: PRICING-RESEARCH-2026-10-18 (+ HOME), workshop/tools (plane_paper, upload_paper_sample),
  lessons (scripted-edit slice trap; old plane meshes have no UVs). STATE rewritten. Checker: OK (98 pages).

## POINTERS
- `assets/models/planes/paper-sample/` (README, renders, uploads.json), `tools/art/plane_paper.py`,
  `tools/art/plane_pieces.py`, `src/shared/Aircraft.luau` (paint/build), `docs/research/PRICING-RESEARCH-2026-10-18.md`.
