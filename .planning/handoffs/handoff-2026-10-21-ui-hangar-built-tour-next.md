# HANDOFF — 2026-10-21 — New Hangar built and OK'd; Hangar Tour (lesson 3) planned and OK'd, build next

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Hangar.luau, src/client/BuildShelf.luau, src/client/HangarCustomize.luau, src/client/RangeBoard.luau, src/shared/UIAssets.luau, assets/ui/hangarshelf, assets/references/ui-concepts, docs
**Time:** 2026-10-21 19:13 -04:00

★ START HERE: Goal: build the **Hangar Tour** (Training board lesson 3) exactly as planned in
`docs/plan/TUTORIAL-PLAN.md` → "Lesson 3: Hangar Tour" (14 steps + end card, OK'd by Alan with his answers). Opening
action: read that section and how Flight School / Combat School drive the step engine (`src/client/Tutorial.luau`),
then build. Done when Alan plays it from the Training board and says it works.

> Read on demand: AGENTS.md → THIS → TUTORIAL-PLAN Lesson 3 → `docs/systems/tutorial.md` (step engine, spotlight,
> Range) → `docs/systems/planes-and-hangar.md`. Memories: plan-before-building-features, alan-does-play-checks,
> studio-play-is-shared, studio-not-drawing, assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `2da3c9fa`); the commit hook pushes to GitHub. `git log --oneline -3`.
- Tests: no rules changed in the ui lane; the Range session ran RangeAccuracy, HitShapes, CombatRules 44/44,
  RangeCourse in Edit (pass). Full suite needs Play: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Code compiles: Hangar, BuildShelf, HangarCustomize, RangeBoard required from fresh clones in Edit (Studio caches modules).
- Studio: Edit, Rojo serving, Play stopped. Place file not re-saved (Ctrl+S = Alan's go).
- Cost this session: Codex 3 picture jobs on Alan's ChatGPT plan (70k / 135k / 128k Codex tokens, ~6-10 min each);
  1 child session (Range targets, its own report); 0 Claude subagents; 0 Claude Play runs; 18 images uploaded
  (Alan's go, permission rule added); primary context ~50% at handoff.

## NEXT ACTION + PLAN
1. Build the Hangar Tour on the shared step engine: Training board's Hangar Tour → move to the Range → open the Range
   Hangar → steps 1-14 (spotlight + note + tick; "do" steps advance on the action, "look" steps on a **Got it** strip;
   during "do" steps only the spotlighted thing is clickable) → end card with the locked-parts line → lesson tick
   saved (`lessonDone`) → Range sticky notes take over. The Hangar needs hooks for the tour (which button is where,
   events: cubby picked, renamed, page opened, tab, part equipped, mount picked, gear placed, saved, Test in Range).
2. Alan's Play check with a what-to-look-at list (his go for any Play run of mine; he does Play checks).
3. Then (queued, in order): the Range's first-visit sticky notes if not covered; the desk's quick-menu concept
   (condensed, NOT cubbies — Alan); a Match Tip for refolding at the desk; swap fly-off/slide-in; Match Tips; Stage 11.
HOLDS (Alan's go, each): Studio Play runs, publish, Meshy, anything paid, desktop control, closing Studio, Save to File,
real product IDs/prices, turning sales on. Uploads: Alan allowed `python tools/ui_pieces.py * --upload`
(`.claude/settings.local.json`), still show an assembled preview first.

## DECISIONS & WHY (this session)
- Hangar = shelf screen (concept `hangar-shelf-screen.png`) + Customize **binder** (`hangar-customize-b.png`); weapons
  are called **Gear** in the tabs. Categories are a list (`HangarCustomize.TABS`): skins/trails = one row + a page.
- Shelf needs depth (top board in perspective, tabs stand on it); stat sheet like the concept; less empty space; the
  3D plane sits bare on the binder page (stretched landscape paper looked bad); tab switch turns the page.
- Range shows only Range builds; Range Hangar is pink ("Range Customize", pink tab/photo, "practice only" note).
- Rename from the tape on both screens (pencil = `UIAssets.settings.pencil`).
- Desk quick menu does NOT get cubbies; its own condensed concept after the Hangar (Alan).
- Hangar Tour uses the Range builds; locked parts = one end-card line; refold = a desk Match Tip; only the spotlighted
  thing clickable during "do" steps (Alan: "yes to all your picks").
- Range targets are the cards (child session, Alan's OK; decision `2026-10-21-range-targets-are-the-cards`).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; `docs/workshop/lessons.md` (+3 lines this session: trimmed 9-slice, real-coordinate
  previews, menu clicks aren't "processed").

## CARRY NOTES / GOTCHAS
- `ui_pieces.py` trims pieces: measure 9-slice on `ready/` files. Re-uploading a piece = delete its `uploads/*.json` first.
- World click handlers must also check `Root:GetAttribute("OverlayOpen")`.
- Studio screen_capture times out when Studio's window is behind (no desktop control): use numeric checks or Alan.
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private publish,
  fan sound, live tutorial-room move untested, Hangar save messages in the Range still mention the desk.

## WHAT SHIPPED / OTHER QUEUED
- 45bd6a3f concepts · d0144744 picks + plan · 14a4bdd5 plan OK'd · 9682024d Hangar split into shelf + binder ·
  b0e3d06b Codex pieces · d79c26f1 previews · 0144efea bigger layout + new stat sheet · efef9920 deeper shelf pieces ·
  999b83fc tab on top board · f0f8b360 bare plane + page turn · 0762b9c3 art uploaded · a391bfe6 docs ·
  ea078cf2 rename + pencil, Range click fix · 1b580cca Range pink look · 91800b9c decision · (child session:
  954f1777 cards are targets, 4499e3cc long row, 425596f3 match aim measured) · d181710f Hangar OK'd + tour draft ·
  2da3c9fa tour OK'd · + this handoff (STATE, playtest, lessons).
- Queued: see NEXT ACTION 3; VIP perks, cosmetics (skins/trails into the binder), special planes, prices (Alan's).

## KNOWLEDGE UPDATED
- systems: planes-and-hangar (Where it stands 2026-10-21, Code table +BuildShelf, +HangarCustomize);
  decisions: hangar-build-shelf (picks, preview rulings, Range look, status OK'd); plan: new HANGAR-PLAN (built, OK'd),
  TUTORIAL-PLAN Lesson 3 rewritten + Alan's answers; playtests: new 2026-10-21-new-hangar (+README); lessons +3;
  STATE rewritten (58 lines). Checker: OK (121 pages).

## POINTERS
- Hangar: `src/client/Hangar.luau` (render, shelf page, statSheet, nameTag, preview, save), `BuildShelf.luau`,
  `HangarCustomize.luau`; art `assets/ui/hangarshelf/` (previews, source, ready, uploads), ids `UIAssets.hangarShelf`.
- Tour engine: `src/client/Tutorial.luau`, `src/shared/TrainingCourse.luau`; Range: `RoundRuntime.rangeAction`, `RangeBoard.luau`.
