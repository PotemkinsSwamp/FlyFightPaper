# HANDOFF — 2026-11-13 — Skins and trails designed with Alan, both fitting methods proved in Blender, concepts made; first batch next

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues= · areas=docs/{plan/SKINS-PLAN.md,decisions,workshop/lessons.md}, state, .planning/skins
**Time:** 2026-11-13 17:24 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money; skins and trails are the build. Next:
build the first batch he picked (Hazard Stripes, Tiger Stripes, Flame Decals, Gold Foil, Lava, Galaxy, Shark Jet,
Dragon; trails Confetti, Rainbow Marker, Gold Stars). Done when Alan plays them in Studio and OKs them.

> Read on demand: AGENTS.md → this file; then `docs/plan/SKINS-PLAN.md` (how it works, budget, batch) and
> `docs/decisions/2026-11-13-skin-rules.md` (his rules). Memories: plan-before-building-features (updated today),
> assembled-preview-before-upload, look-at-textures-before-upload, creator-store-first, codex-for-pictures-and-blender,
> exact-collision-baked, no-quality-cuts-for-fps.

## STATE (verify before acting)
- HEAD `ec14b514` + this handoff (main), pushed by the commit hook. Confirm: `git rev-parse --short HEAD`.
- Tests: 599/0 on 2026-11-13 (before the gift sound changes); no game code changed this session. Re-run in Studio
  Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Docs checker OK (188 pages): `python tools/check_docs.py`.
- Rojo: `rojo serve` restarted (`& "$env:LOCALAPPDATA\Rojo\bin\rojo.exe" serve serve.project.json --address 127.0.0.1
  --port 34872`); Alan was asked to click Connect in Studio's Rojo plugin; not confirmed. Studio in Edit; my test
  models were deleted. Nothing published, uploaded or Saved to File.
- Cost this session (~2 h wall clock): main session Opus only, no subagents; ~40% of its context at handoff. Codex:
  4 picture jobs on Alan's ChatGPT plan (79k, 56k, 53k, 44k Codex tokens). Blender: 7 local renders. 2 web searches.

## NEXT ACTION + PLAN
1. **Numbers note for Alan** (his rule: any new number first): prices per tier (Paper and Robux, same rate as parts),
   what can be earned and how, the Looks tab and shop section. Check: his OK, recorded in the decision note.
2. **One-time re-layout of the plane pieces** (Blender script, Codex or Opus): every piece gets the printed-sheet
   layout (top, side and a front-on view; the test smeared forward/back faces) and today's paper creases moved onto
   it. Check: renders of plain planes look as today, side by side, before anything uploads.
3. **Upload batch** of the re-laid pieces and the batch's pictures: Alan's go; contact sheet first (moderation).
4. **Code, client-only:** server saves the chosen skin and trail; each client hides the real parts and draws the skin,
   team outline (Highlight, hidden behind walls), trails (own colours). Save and buy rules with unit tests (Codex lane).
5. **Shark Jet add-ons and Dragon with joints**, ≤ 4,000 triangles, detail baked into pictures; assembled preview
   in the scene and close up for Alan before upload.
6. Studio check, then Alan plays it. Bots wear skins (about 1 in 3 was the lean; confirm in the numbers note).
- HOLDS (his explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs,
  Studio Play while he's playing, any bot match, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- All of Alan's rulings are in the [skin rules](../../docs/decisions/2026-11-13-skin-rules.md): hitbox is always the
  real parts; one design per skin fitted by the game (never one model per part); Common/Rare/Legendary/Mythical;
  team outline + coloured name + square/circle, no team colours; only Mythicals change weapons and their shots never
  change size or speed; no animations; trails keep their colours; bots wear skins; budget ~4,000 triangles.
- **Box-projected Texture overlay is out:** tested first with the gold star picture; Alan: "looks like shit".
- **Printed sheet** (Common/Rare): UVs from where each piece sits on the plane → one picture per skin. Proved in
  Blender on a standard and the heavy plane (`.planning/skins/printed-sheet-test.jpg`).
- **Joints** (Legendary/Mythical): even scale to plane length, joints on the real wing and tail corners, scallops
  redrawn between. Proved with a rough bat (`.planning/skins/joints-test-bat.jpg`); Alan: works, but that bat's art
  is not to be used.
- **Client-only drawing** removes the HitShapes change: the server never sees a skin, so its hitbox copy stays the
  real parts. This is Claude's design; Alan OK'd the budget it sits in.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits); memories above; `docs/workshop/lessons.md` (2 new lines);
  design-theory skill before showing any picture.

## CARRY NOTES / GOTCHAS
- Test scripts and data: `.planning/skins/tests/` (`sheet_test.py`, `joints_test.py`, `pieces.json`, run with
  `D:/Blender/blender.exe -b --factory-startup --python <script>`; env BUILDS/SKINS/VIEWS). Untracked, like the
  concepts in `.planning/skins/concepts/` (prompts `prompt-*.txt`, reference `our-plane.png`).
- Shine (Gold Foil) and glow (Lava): check what SurfaceAppearance can do in Studio before promising either.
- The Ghost Ship is built last, to the budget (painted ropes, flat torn sails with see-through edges).
- Alan wants the square/circle team dot easier to see from far away (part of the team signs).
- Mythical weapon looks are not designed yet (only the rule).
- Shell: long `python - <<'EOF'` blocks with apostrophes failed again; write long text with the Write tool.
- Carried: phone sizes of the gift note/arrival and report card row; a real gift through the shop; the unlock
  backpack's music dip; starter pack card gap; `assets/ui/shop/raw` and `source` untracked; `mock_ui_label` dash.

## WHAT SHIPPED / OTHER QUEUED
- 47d35fa1 Goals review: Alan picked paper skins and trails as the next build
- 294a3008 Skins and trails plan drafted for Alan's OK: whole-plane skins, as he decided
- 08d42570 Skins plan: ideas and how they work get talked through before anything is made (Alan)
- e5fe9230 Skin rules from Alan: same hitbox, four tiers, team outline, bots wear them; idea list sorted by tier
- c8e17668 Skins: one design per skin fitted by the game, hitbox always the parts, Common/Rare/Legendary/Mythical; cooler idea list
- 38dc9b4c Skins: Alan approved the idea list; Mythicals only change weapons; trails keep their colours; top tiers hide the parts
- cde34dd4 Skins: printed-sheet test in Blender works on two different planes
- 1d024d66 Skins: Mythical shots may look different but never change size or speed (Alan)
- a554b9e8 Skins: joints test in Blender fits one bat onto two different planes
- bbd9e96b Skins: concept pictures for every approved skin and trail, waiting on Alan's picks
- 1c249ff2 Skins: no animations, client-only drawing and a detail budget proposal; crane goes blue and silver
- 61c413c2 Skins: Alan OK'd the 4,000-triangle budget and picked the first build batch; STATE rewritten
- 47cb7114 STATE trimmed · ec14b514 STATE under 60 lines · (+ this handoff: lessons, plan wording, LATEST)
- Queued after skins: daily/weekly missions, playtime calendar, bots that use the town, treasure chest for buyers,
  skill bonuses, part model redo ([ideas](../../docs/plan/IDEAS.md)).

## KNOWLEDGE UPDATED
- Decisions: `2026-11-13-skin-rules.md` (new, in README); shop-plan decision points its old hitbox rule at it.
- Plans: `SKINS-PLAN.md` (new, linked from HOME and IDEAS). Lessons: Blender plane assembly, Codex `-i` order.
- STATE rewritten (59 lines). Memory: plan-before-building-features (cosmetics: ideas → talk → concepts → Blender;
  read the topic's decisions first). No systems page changed (no game code). Checker: OK (188 pages).

## AAR
- Planned: goals review, his pick in STATE, then build. Actual: pick made (skins); I tested a pattern overlay against
  his 2026-10-18 whole-plane rule and drafted prices before any talk; he redirected twice. Design then settled in
  rounds and both fitting methods were proved cheaply in Blender. Lesson routed to memory (above). Cost matched
  output: tests were small and decisive; concepts cost Codex tokens, not Claude usage.

## POINTERS
- `docs/plan/SKINS-PLAN.md` · `docs/decisions/2026-11-13-skin-rules.md` · `src/shared/Aircraft.luau` (build, paint)
  · `src/server/HitShapes.luau` · `assets/models/planes/paper-set/README.md` (pieces, maps, triangles)
  · `.planning/skins/` (tests, concepts, test pictures)
