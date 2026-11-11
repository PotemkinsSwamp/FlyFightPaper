# HANDOFF — 2026-11-11 — menus fit live; guns attached; phone words fixed; Clear all; unlock moment next

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/shared/Aircraft.luau, src/shared/BuilderModel.luau, src/client (FlightHUD, PaperUI, HangarCustomize), src/first/UIAssets.luau, tools/art/plane_pieces.py, assets/models/planes/pieces.rbxmx, assets/ui/*/uploads, tests/unit, docs
**Time:** 2026-11-11 17:07 -05:00

★ START HERE: Goal (Alan): the beta feels finished. Everything Alan asked for this session is done and on main. Next is
**the unlock moment**: write a short how-it-works note (what the player sees when a part/level unlocks, using the concept
frames in `.planning/unlock-concept2/`) for Alan's OK BEFORE any code (memory plan-before-building-features). Done when
Alan approves the note; then build it and he checks it in Play.

> Read on demand: AGENTS.md → this file → `state/STATE.md`; `.planning/unlock-concept2/` and `docs/plan/MILESTONES.md`
> when planning the unlock. Memories: plan-before-building-features, alan-does-play-checks, mute-studio-tests,
> studio-play-grabs-mouse, text-fits-its-box, paper-fits-its-content, hand-made-not-generic-roblox.

## STATE (verify before acting)
- HEAD `59fff697` on `main`, pushed (GitHub copy via `tools/push_github.py`). Confirm: `git log --oneline -3`.
- Tests: 477 passed / 0 failed at 59fff697 (Studio Play, server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`,
  spawn it and poll a workspace attribute — lessons.md). Docs checker OK (`python tools/check_docs.py`).
- Studio: open on the place, Edit mode, Rojo connected (`rojo serve serve.project.json` running; it also syncs
  `assets/models/planes/pieces.rbxmx`, so the new wing Mount1/Mount2 values are in the open place).
- Published: Alan published twice today (menus, guns, phone button fix are live). NOT yet published: b5fcdc91 (SPEED MATCH
  without paper) and 59fff697 (Clear all). Save to File not done (his go).
- Old branch `wip/stretch-fix-2026-11-09` is merged into main (bbdf213d); left in place, nothing pending on it.
- Cost this session: Opus main only, no subagents, no Codex, nothing paid (7 free picture uploads); ~1.5 h; context ~40% at handoff.

## NEXT ACTION + PLAN
1. Unlock moment: how-it-works note → Alan's OK → build → his Play check. Stop rule: one note, one round of his notes, then build.
2. Alan's open checks (STATE "Waiting on Alan"): Clear all on the Gear page; publish when he likes; in flight: Range notes +
   Range Menu strip, leaving the Range, FFA strip at a desk, a Match tip.
3. Queued (not started): report card, winners' circle, skins, shop step (Paper packs / Robux part prices), balance pass.
- HOLDS (Alan's go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while he plays,
  a bot match, anything paid, any new mechanic or number (the unlock moment is one: plan first).

## DECISIONS & WHY (this session)
- Every gun hangs by its highest point (`Aircraft` `topOf`): body pair from the wing root (`ROOT_UNDER` per wing set), wing
  spots from `Mount1/2` (now = lowest underside under a gun's footprint − 0.41; Swept Wings use the main underside, their
  trailing lip hangs lower and long guns tuck into it). Pellet keeps plane A's spot (tube through the root by design).
  Shrunk crowded guns shrink toward their top. Replaces `BODY_SLOT_DROP`. Alan: "looks good".
- Crayon word copies take the label's ZIndex (FIRE's crayon fill covered its words on phones; TouchControls/FlightHUD
  layer globally). Fixes every word.
- SPEED MATCH / BRAKE tag: crayon words, no paper (Alan disliked the notebook strip behind it).
- Clear all sits in the Buy/Cancel pair's places (Clear spot green left, Clear all tab right); `BuilderModel:clearMounts`.
- A git post-merge hook to auto-push was blocked (unrequested setup); a lesson says push by hand after merging instead.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (words and papers fit; look at the game; plan before features); memories listed above.

## CARRY NOTES / GOTCHAS
- Mute in its own call, wait, THEN start Play (sent together, Play started unmuted; memory updated).
- Exact fit checks on plane pieces: they collide as boxes; clone into a scratch folder with PreciseConvexDecomposition
  (lessons.md, 2026-11-11). Require a cloned copy of a changed module in Edit or the cached old one runs.
- Clear all's look not checked on a screenshot (Studio was behind Alan's window): same slots and sizes as Buy/Cancel,
  words fit by `fitWords`; Alan to look.
- `tools/art/hero.py.old` untracked leftover on disk (not ours).

## WHAT SHIPPED / OTHER QUEUED
- 82bacbad Menu pictures uploaded: the 7 new papers use their real ids
- bbdf213d Menus fit: every picture keeps its shape, every word and paper fits (Alan approved 2026-11-11) (merge)
- 9d983c73 Lesson: push by hand after merging into main
- e075de2f Guns hang by their top and touch the wing or wing root on every plane
- 57f24cc6 Notes: phone measuring found nothing off; waiting on Alan's screenshot
- d12a8fd9 Phone buttons' words draw over their crayon fill; Speed match tag on a notebook strip
- b5fcdc91 Speed match / Brake tag: crayon words without the paper behind them
- 59fff697 Gear page: Clear all empties every gear spot
- (this commit) handoff + LATEST.
- Queued: unlock moment (next), report card, winners' circle, skins, shop step, balance pass.

## KNOWLEDGE UPDATED
- docs/systems/planes-and-hangar.md: "Where it stands (2026-11-11)" guns touch; Clear all. docs/systems/menus-and-hud.md:
  uploads done/merged, crayon copies' ZIndex, SPEED MATCH tag. docs/playtests/2026-11-11-menus-ok-weapons-float-phone.md
  (+ README line). docs/workshop/lessons.md: push after merge, PreloadAsync id-text quirk, plane pieces collide as boxes,
  crayon copies need ZIndex. STATE rewritten. Memory: mute-studio-tests (mute before Play, never in parallel). Checker: OK.

## POINTERS
- Code: `src/shared/Aircraft.luau` (`ROOT_UNDER`, `topOf`, `mountOffset`, build shrink), `tools/art/plane_pieces.py`
  (`EDGES`), `src/client/PaperUI.luau` (`FOLLOW`), `src/client/FlightHUD.luau` (`slowTag`), `src/client/HangarCustomize.luau`
  (`ClearAll`), `src/shared/BuilderModel.luau` (`clearMounts`). Alan's screenshots: playtest note above.
