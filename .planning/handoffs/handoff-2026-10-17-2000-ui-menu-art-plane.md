# HANDOFF — 2026-10-17 20:00 — Alan re-publishing; next: a clean 2D menu plane, then the rest of the menu art

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/Loading.luau, src/client/MenuBoard.luau, src/client/ScorePopups.luau, assets/ui, docs/playtests/2026-10-17.md

★ START HERE: Goal: menus that show today's game and don't read as AI art, then Alan's Stage 9 sign-off. Alan is
re-publishing (Publish As > Overwrite) before this session, so start working right away: make a proper 2D paper-plane
asset for the loading/menu animation (clean plane, full nose, no pin, no trail; the pushpin a separate piece). Done
when it flies across the loading screen, flies to its menu spot and gets pinned, checked in Studio, with Alan's OK on
the picture and his go for the upload.

> Read on demand: AGENTS.md → THIS; docs/playtests/2026-10-17.md (notes 1–3: plane asset, old-town pictures, ruler
> numbers); docs/art/pipeline.md (pictures by Codex, look at textures before upload). Previous handoffs:
> handoff-2026-10-17-1800-multiplayer-fold-credit-loading.md (multiplayer state, IDs, holds). Memories:
> look-at-textures-before-upload, codex-for-pictures-and-blender, look-up-roblox-ui-steps, studio-not-drawing.

## STATE (verify before acting)
- HEAD: this handoff's commit on main (`git rev-parse --short HEAD`), auto-pushed. Tests 321/0 (re-run in Play,
  server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Live: Alan says he will Publish As > Overwrite before this session. Confirm with him once; the Studio copy (MCP name
  "FlyFightPaper(First Fold) (placeId: 132768925825316)") is what he publishes, Rojo serving current code.
- Current plane: `Art.plane` (assets/ui/mainmenu/ready/plane.png, pin and trail painted in) cropped with
  ImageRectOffset (0,58) / Size (630,531) in Loading.luau and MenuBoard.luau; pin = `UIAssets.hud.pinRed`. Flaws
  Alan saw: a stray blue trail mark at the bottom right, and the nose tip cut off.

## NEXT ACTION + PLAN
1. **2D plane asset** (above). Picture via Codex (free) styled on the reference picture, or drawn cleanly; transparent
   background; nose pointing right so rotation maths is simple. Contact sheet → Alan's OK → upload (his go) → swap the
   id into UIAssets, remove the crop, re-check the pin spot on the nose.
2. **Ruler numbers** in 5 backgrounds (main menu right edge, desk hangar + hangar bottom left, results bottom right,
   settings top left): retouch to clean 1, 2, 3… so nothing reads as AI gibberish.
3. **Old-town pictures** on the main menu (`photo-1`, `drawing-1`, `drawing-2`): replace with the current town (real
   Studio capture for the photo; crayon drawings traced from captures).
4. One contact sheet for 2–3, Alan's OK, one upload with his go, publish (Alan clicks Publish As).
5. Then Alan's Stage 9 playtest. Tutorial only when he says.
HOLDS (Alan's go each): uploads, publish, Studio-settings changes, Meshy, anything paid, desktop control (the access
box needs him at the PC), closing Studio.

## DECISIONS & WHY (this stretch)
- Finishing-shot popup reads **FINAL TEAR** (Alan; "LAST SHRED" was his alternative).
- Loading plane loops across the screen; on the menu it flies in to its spot and the pin pops in on arrival (Alan;
  a version that landed on the loading screen looked bad). Pinned plane doesn't bob.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories look-at-textures-before-upload (contact sheet before any upload), touch-up-before-showing,
  in-game-menus-match-main-menus.

## CARRY NOTES / GOTCHAS
- Studio behind other windows: preview GUIs in Edit by requiring the client module into a StarterGui folder (or
  building labels there) + screen_capture; delete the preview after.
- Open Cloud publishing is blocked by the permission checker; Alan publishes from Studio.

## WHAT SHIPPED / OTHER QUEUED
928e7114 fly-in pin (superseded) · 857cf91d loading loops again, menu fly-in + pin · this handoff (with the plane-asset
note). Earlier today: see handoff-2026-10-17-1800-multiplayer-fold-credit-loading.md.

## KNOWLEDGE UPDATED
- docs/playtests/2026-10-17.md (plane asset task, FINAL TEAR), decision fold-credit (FINAL TEAR). Checker: OK.

## POINTERS
- src/client/Loading.luau, src/client/MenuBoard.luau, src/shared/UIAssets.luau, assets/ui/mainmenu/ready/,
  tools/upload_texture.py.
