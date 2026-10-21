# HANDOFF — 2026-10-20 — Range aim proven and Range builds done; Hangar rework approved, concepts next

**Labels:** kind=ui+product · lane=ui · branch=main · issues= · areas=src/client/Hangar.luau, src/client/FlightHUD.luau, src/client/RangeTargets.luau, src/client/RangeBoard.luau, src/client/MenuController.luau, src/client/CombatEffects.luau, src/server/HangarService.luau, src/server/RoundRuntime.luau, src/server/CombatService.luau, src/server/HitShapes.luau, src/server/RangeStage.luau, src/server/FlightService.luau, src/shared/ProfileSchema.luau, src/shared/TrainingCourse.luau, src/shared/CombatRules.luau, tests/unit, docs
**Time:** 2026-10-20 23:21 -04:00

★ START HERE: Goal: rework the Hangar into a **cubby-shelf build picker + a separate Customize screen** that can grow
(skins, trails, per-part and weapon skins later) — [decision](../../docs/decisions/2026-10-20-hangar-build-shelf.md).
First: concept pictures for BOTH screens (Codex), shown to Alan; then the build plan for his OK (the shelf plan below
is approved; the Customize screen's layout is not yet designed). Done when Alan plays the new Hangar and says it works.

> Read on demand: AGENTS.md → THIS → the decision note → `docs/systems/planes-and-hangar.md`. Concepts:
> `assets/references/ui-concepts/hangar-shelf-cubbies-b.png` (chosen), `hangar-name-tape-a.png`. Memories:
> plan-before-building-features, assembled-preview-before-upload, look-at-textures-before-upload, alan-does-play-checks,
> codex-for-pictures-and-blender, studio-play-is-shared.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `2194165b`); the commit hook copies to GitHub. `git log --oneline -3`.
- Tests: full suite NOT run this session (needs Play = Alan's go). Run in Edit from fresh clones (Studio caches
  modules): HangarService 4, ProfileSchema 28, ProfileService 21, RangeCourse 2, CombatRules 44, Service 6,
  FlightService 4, RangeAccuracy 1 (3,709/3,709 shots), HitShapes 3 (fails without the fix) — all pass.
  Full: in Play from the server, `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: Edit at handoff, Rojo serving. Alan played everything below in Play; "the targeting is now good".
- Cost: Codex 1 save job (schema 7, ~29k subagent tokens + Codex on Alan's plan), 2 Codex picture jobs (~65k each,
  ~4-5 min); 0 Claude Play runs; 2 web searches; primary context ~41% at handoff.

## NEXT ACTION + PLAN
1. **Concepts (Codex, `codex exec --skip-git-repo-check -s workspace-write -i <ref> - < prompt.txt` in a scratch
   folder):** (a) the shelf screen as one whole screen (big taped photo + tape name label + stats + Customize button +
   cubby shelf with My builds / Range / Special tabs), (b) the Customize screen with a category list that can grow
   (parts now; skins, trails, per-part skins later). No weapon words in prompts or references (Codex refuses them).
   Show Alan; he picks.
2. Plan for Alan's OK (memory plan-before-building-features), then: art pieces (cubby front, back wall, tabs) shown
   assembled in a real Hangar capture → Alan's upload → code: shelf module (one still ViewportFrame per cubby, redrawn
   only when that build changes; tap = pick, in the Range = swap), Hangar split into shelf + Customize, tape name label
   (`UIAssets.ingame.tapeLabel` exists), mount line onto the photo, "Saved" as a fading note, centred layout. Range
   tab only in the Range (opens first there); Special hidden until special planes exist.
3. Then: swap fly-off/slide-in, first-visit sticky notes, Hangar Tour (lesson 3, in the Range), Match Tips, Stage 11.
HOLDS (Alan's go, each): Studio Play runs (he does Play checks; give a what-to-look-at list), uploads (he runs them),
publish (schema 7: shut down old servers first, docs/systems/saving.md), Meshy, anything paid, desktop control,
closing Studio, Save to File, real product IDs/prices, turning sales on.

## DECISIONS & WHY (this session)
- Range keeps its own five builds (`rangePresets`, any part, never in matches) + `rangeSlot` remembered (Alan's pick).
- Practice targets publish their path (`DrillPath`): the lead ring, the drawn card and the server's hit check all read
  it; client draws on `GetServerTimeNow()`, server rewinds only the trigger message's trip (`pathRewind`). A speed+turn
  guess hit 0% (pencil, Veteran, long). The plane under the card now only holds health (Alan asked to drop it; not
  needed, as the timing was the cause; do it only if misses come back).
- No aim help in the Range: shots go where the crosshair points (Alan: shots near the ring were landing).
- Card hit = whole picture 26 x 13.6, box maths (`CombatRules.segmentBox`), tilted like the drawing.
- Menu button lives in Roblox's top bar (`GuiService.TopbarInset`), permanent (Alan OK'd); Range aim reaches 31.5° up.
- Hangar: two screens, cubbies (Alan); pencil = rename only; Customize = part editor; build it to grow.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories above; lessons.md (3 new lines: curving lead, same path same clock, shapecast start overlap,
  GUI top-bar inset).

## CARRY NOTES / GOTCHAS
- Studio Edit caches required modules: clone a changed module (or a folder copy) before requiring it in Edit tests.
- Codex can't see weapon names in pictures: blur them out of references.
- Old carries: match bots' guns converge at 150 (Alan's call), vote-lap strip, cutscene hitch, Track C private publish,
  fan sound, live tutorial-room move untested, Hangar save messages in the Range still mention the desk.

## WHAT SHIPPED / OTHER QUEUED
- 72fe23f5 Range keeps its own five builds; renaming · 2ecac092 exact lead on practice targets, strips up top, Hangar
  name tag, Test in Range, Training button · 46464b18 one shared path, no Range aim help, Menu button in the top bar ·
  7b0b9704 same moment on screen and server, whole-picture hits, crosshair clicks Menu · a74b07f0 Range accuracy test,
  card box maths · 82eacc18 shots starting inside a plane hit · 2194165b decision: cubby shelf + Customize · + this
  handoff (STATE, playtest note, concepts, decision update).
- Queued (Alan's): VIP perks/private servers, cosmetics (skins/trails: design the Customize screen for them), special
  planes, drawing pass (paid), prices.

## KNOWLEDGE UPDATED
- systems: tutorial (Range builds, strips, Training button), planes-and-hangar (renaming), menus-and-hud (exact lead,
  same clock, no Range aim help, Menu button), saving (schema 7, by Codex), damage-and-deaths (start-overlap fix);
  decisions: range-controls-and-menu (2026-10-20 lines), new hangar-build-shelf (+README); playtests: new
  2026-10-20-range-aim-and-hangar (+README); lessons: +4; STATE rewritten (58 lines). Checker: OK (117 pages).

## POINTERS
- Hangar UI: `src/client/Hangar.luau` (render, name box, slots, Test in Range), `src/client/PaperUI.luau`;
  server: `src/server/HangarService.luau` (savePreset, saveRangePreset, renamePreset); Range: `RoundRuntime.rangeAction`.
- Aim: `CombatRules.lead`, `TrainingCourse.pathOf/pathAt`, `FlightHUD` leadOf, `CombatService` planeHit/pathRewind.
