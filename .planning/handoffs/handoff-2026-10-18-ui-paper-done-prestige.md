# HANDOFF — 2026-10-18 — Paper look on every plane part approved; prestige built and parked

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=tools/art/plane_paper.py, tools/art/upload_paper.py, tools/art/plane_pieces.py, assets/models/planes/paper-set, src/shared/EconomyRules.luau, src/shared/ProfileSchema.luau, src/server/ProfileService.luau, src/server/HangarService.luau, src/client/MenuBoard.luau, src/client/LevelBar.luau, docs

★ START HERE: Goal: Stage 10 commerce wiring (MILESTONES): the real MarketplaceService adapter (ProcessReceipt with
ProfileStore idempotency, game-pass ownership checks) for what the shop plan sells, everything switched OFF. First
action: read MILESTONES Stage 10 + the shop plan and list what Stage 10 needs that the mock shop doesn't have. Done =
real adapter behind the existing mock, live sales still off, tests green, nothing purchasable until Alan OKs prices.

> Read on demand: AGENTS.md → THIS → [shop plan](../../docs/decisions/2026-10-18-shop-plan.md) →
> [economy and shop](../../docs/systems/economy-and-shop.md) → [saving](../../docs/systems/saving.md). Draft prices:
> `docs/research/PRICING-RESEARCH-2026-10-18.md`. Memories: powershell-commands-for-alan, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `3d839229` + this handoff on main; post-commit hook pushes to GitHub. `git status -sb`.
- Tests 340/0 (2026-10-18). Re-run in Play (server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio open in Edit (Play stopped), Rojo serving. `FlyFightPaper-WORKING.rbxlx` shows modified in git (not
  committed by me); ask Alan whether he did File > Save to File before any `save_place.py` rebuild.
- Cost this session: 2 Codex jobs via codex-rescue (paper set ~76 min Codex / 25 min build; prestige save rules
  ~10 min), each ~30k Claude tokens; Alan ran 1 upload (380 files). Primary context ~41% at handoff.

## NEXT ACTION + PLAN
1. Stage 10 commerce wiring, switched off (see START HERE). Codex lane for receipts/saving; Claude reviews diffs and
   runs tests in Studio.
2. Then the tutorial, then Stage 11 (multiplayer, QA, private release candidate).
HOLDS (Alan's go each): uploads (he runs them), publish, Studio-settings changes, Meshy, anything paid (incl. the
drawing pass's outside AI check), desktop control, closing Studio, Save to File, real product IDs/prices, turning
sales on. Don't steer his plane in his Play.
Parked by Alan: prestige (built; details kept for now, "they will change later"; don't go deeper).

## DECISIONS & WHY (this session)
- Paper look approved by Alan after trying it in game ([decision](../../docs/decisions/2026-10-18-paper-look.md)).
- FBXs uploaded with `--model` are Model wrappers: the game must use the inner MeshId (read in Studio via
  `upload_paper.py [set] lua` → `meshes <file>`). This is why last session's Classic sample was invisible in game.
- Paper-set review images (contact sheets, renders) are git-ignored (114 MB, rebuildable); only game-distance.png kept.
- Prestige details (Claude's, Alan: keep for now): 10 ranks, gold star with rank on the level bar, hold 2 s to
  confirm on the main menu stats card, XP past 50 not carried, qualification kept so bots stay tough, one
  prestige-only cosmetic per rank later. Rules: economy-and-shop.md "Prestige".

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, holds, no runtime AI). Lessons: uploads/moderation, Model-wrapper mesh ids,
  50-character asset names.

## CARRY NOTES / GOTCHAS
- Prestige badge is only on your own level bar; others see it once name tags come with Stage 10 cosmetics.
- Prestige confirm sheet's dim background doesn't show in captures (Frame at ZIndex 5, transparency .45); the
  sheet itself reads fine. Cosmetic only.
- Some paper meshes share a mesh id (identical geometry, e.g. body_slim / body_slim_mk2 halves): expected.
- Still open from before: cutscene-start hitch; vote-lap strip shows the old round; Track C live saving tests need a
  private publish (Alan's go).

## WHAT SHIPPED / OTHER QUEUED
- aee46f65 Paper UVs and maps for every other plane part and booster (Codex)
- 6f3eae14 Classic plane shows its paper texture in game (real mesh ids, not the upload wrappers)
- 743ec0c6 State: Classic paper look in game; other parts' maps ready for upload
- 2b196a52 Paper uploader: shorter asset names (Roblox caps names at 50 characters)
- f6bdb519 Every plane part and booster shows its paper texture in game
- 99a9210a Paper look approved by Alan
- cbcaaee7 Prestige rules written down
- cab1191a Prestige in the save: rank, reset level and parts, keep Paper (Codex)
- b89c4f6c Prestige button, hold-to-confirm sheet and rank star on the level bar
- 90d0c84e State: prestige built · 3d839229 Prestige details kept for now; parked (Alan)
- Queued: plane emotes for the shop (Meshy/uploads need go); desk decorating, season sticker book (later).

## KNOWLEDGE UPDATED
- decisions: paper-look (approved). playtests: 2026-10-18 item 4 (paper look OK).
- systems: planes-and-hangar (paper textures on all 107 pieces), economy-and-shop (Prestige section, where it
  stands), saving (schema 5 prestige). workshop: tools (upload_paper.py), lessons (Model wrapper ids, 50-char names).
- STATE rewritten (paper look done, prestige built/parked, Now: Stage 10). Checker: OK (99 pages).

## POINTERS
- `assets/models/planes/paper-set/` (README, manifest, uploads.json), `tools/art/plane_paper.py -- --set`,
  `tools/art/upload_paper.py`, `tools/art/plane_pieces.py`, `src/shared/EconomyRules.luau` (prestige),
  `src/client/MenuBoard.luau` (prestige UI), `src/shared/CommerceRules.luau`, `config/commerce.json`.
