# HANDOFF — 2026-11-11 — Clear all made red and taped (after the 17:07 handoff); unlock moment next

**Labels:** kind=ui · lane=beta-lane · branch=main · issues= · areas=src/client/HangarCustomize.luau, src/first/UIAssets.luau, assets/ui/hangar, docs
**Time:** 2026-11-11 17:25 -05:00

★ START HERE: Goal (Alan): the beta feels finished. Everything Alan asked for is done and on main. Next is **the unlock
moment**: a short how-it-works note (concept frames in `.planning/unlock-concept2/`) for Alan's OK BEFORE any code
(memory plan-before-building-features). Done when he approves the note; then build it and he checks it in Play.

> Read on demand: AGENTS.md → this file → the earlier handoff of today
> (`handoff-2026-11-11-1707-beta-lane-menus-live-guns-attached-unlock-next.md`: the session's guns / phone / Clear all
> decisions) → `state/STATE.md`. Memories: plan-before-building-features, alan-does-play-checks, mute-studio-tests,
> assembled-preview-before-upload.

## STATE (verify before acting)
- HEAD `d011a435` on `main` (+ this handoff), pushed. Confirm: `git log --oneline -3`.
- Tests: 477 passed / 0 failed at 59fff697; since then only Clear all's picture changed (no rules). Re-run in Studio Play,
  server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (spawn + poll, lessons.md). Docs OK.
- Studio: Alan was in Play at handoff (started before the red Clear all synced: a fresh Play shows it). Rojo connected.
- Not yet published: SPEED MATCH without paper (b5fcdc91), Clear all (59fff697, d011a435). Save to File not done.
- Cost this session (both handoffs): Opus main only, no subagents, no Codex, nothing paid (8 free picture uploads, all
  Approved); ~1.75 h; context ~42%.

## NEXT ACTION + PLAN
1. Unlock moment: how-it-works note → Alan's OK → build → his Play check. Stop rule: one note, one round of his notes, then build.
2. Alan: look at Clear all (fresh Play, Hangar → Customize → Gear); publish when he likes; in-flight checks in STATE.
3. Queued: report card, winners' circle, skins, shop step, balance pass.
- HOLDS (Alan's go, each): any upload, publish (he does it), Save to File, desktop control, Studio Play while he plays,
  a bot match, anything paid, any new mechanic or number (the unlock moment is one: plan first).

## DECISIONS & WHY (this session, after 17:07)
- Clear all = Clear spot's own taped paper recoloured red (green pixels → the desk menu strip's red with the paper's own
  light and shade; tape untouched), same size, same tilt (-1), same word size (Alan: identical except words and colour,
  tape not a pin). Preview `.planning/menu-fit/10-clear-all-red-preview.jpg`, Alan OK'd, uploaded 106732498442644
  (Approved; online pixels match the file). `UIAssets.hangar.buttonRed`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (words and papers fit; look at the game; plan before features); memories above.

## CARRY NOTES / GOTCHAS
- The recolour was a one-off scratch script (not kept): the source PNG `assets/ui/hangar/source/button-red.png` is the
  record. Redo the same way if another colour is wanted (green-dominant pixels only, keep tape).
- Clear all not yet seen in a screenshot (Studio was behind Alan's window); the preview matches the game's numbers.

## WHAT SHIPPED / OTHER QUEUED
- d011a435 Clear all: Clear spot's taped paper in red, same size and tilt
- (earlier today, see the 17:07 handoff) 82bacbad, bbdf213d, 9d983c73, e075de2f, 57f24cc6, d12a8fd9, b5fcdc91, 59fff697, ae79fcd3
- Queued: unlock moment (next), report card, winners' circle, skins, shop step, balance pass.

## KNOWLEDGE UPDATED
- docs/systems/planes-and-hangar.md (Clear all's paper), docs/playtests/2026-11-11-menus-ok-weapons-float-phone.md (Alan's
  ask + what was made), STATE. Checker: OK.

## POINTERS
- `src/client/HangarCustomize.luau` (`ClearMount`, `ClearAll`), `src/first/UIAssets.luau` (`hangar.buttonRed`),
  `.planning/unlock-concept2/`.
