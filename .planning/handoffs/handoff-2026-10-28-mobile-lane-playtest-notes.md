# HANDOFF — 2026-10-28 — mobile lane: Alan's phone run of the night's fixes; his notes are the next to-do list

**Labels:** kind=ui+product · lane=mobile-lane · branch=main · issues= · areas=docs/playtests, state, .planning/handoffs
**Time:** 2026-10-28 22:20 -04:00

★ START HERE: Goal (Alan): mobile works and looks good. First: fix the 7 items from Alan's phone run (`docs/playtests/2026-10-28-phone-tutorial-run.md`), each checked in Studio at phone size; done when every item is fixed and checked, then Alan's next phone run confirms.

> Read on demand: AGENTS.md → this file → the previous handoff `handoff-2026-10-28-mobile-lane-phone-run-fixes.md` (what the night's fixes changed, gotchas); `docs/decisions/2026-10-28-phone-steering-and-auto-fire.md`; `docs/workshop/lessons.md` (Studio tricks). Memories: studio-play-is-shared, alan-does-play-checks.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `d3779fc9`). Confirm: `git log --oneline -2`. The commit hook pushes to GitHub.
- Docs checker OK (136 pages): `python tools/check_docs.py`.
- Studio: open, Edit, holds the code Alan just published (= HEAD's `src/`), not Rojo-connected, not saved to file.
- Alan published that build and played it on his phone (this handoff records it). No code changed since.
- Cost since last handoff: none (notes only). Primary context ~47%.

## NEXT ACTION + PLAN (Alan's phone run, in his order of pain)
1. **Auto-fire (his ruling, not built):** phone Settings switch, on by default; FIRE fires while the dot is red; 2 stays manual. Same pass: the steering bar finer with 1 in the middle (ruling), and its top lower — Alan: "no reason why anybody's using 3" (saved range today 0.2-3, `ProfileSchema.luau:121`; keep old saves valid).
2. **Skip all → "Next: Hangar Tour" sent him into the real game** (Combat School; maybe every lesson's Skip all). Check: Skip all then Next opens the next lesson.
3. **Blank card button:** the card button that should say Close/Skip was blank paper and did nothing (suspect the new green Close on the end card, `Tutorial.luau` closeButton, or Next after Skip all).
4. **Slow Motion tag:** paper too small for its words now; make the paper slightly larger than the words, same place, words not smaller (`Tutorial.luau` slowTag, phone size 150x36).
5. **Range Hangar: still two Back buttons** — one Back above the purple "Range builds" note and one without words. One Back, where the main menu's Hangar has it (`Hangar.luau:73-83`, RangeNote ~:296).
6. **Range "Hangar" (and "Range Menu") 3D strips hidden under Roblox's top-left buttons on phones:** move to the right of the accuracy score card (`RangeStage.luau:109-124`; crosshair yaw clamp `TrainingCourse.RANGE.yaw` 50°).
7. Then: phone-check Range menu, round results, Training board, match desk, iPad; screen-fit steps 3-6.
- HOLDS (Alan's go): publish (he does it), Save to File, any upload, desktop control, Studio Play while he plays, anything paid.

## DECISIONS & WHY
- None new. Rulings in force: decision note 2026-10-28 (finer bar, speed unchanged; auto-fire FIRE only). Alan now also wants the bar's top lower.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories studio-play-is-shared, no-surprise-desktop-control, assembled-preview-before-upload.

## CARRY NOTES / GOTCHAS
- I told Alan last session the Range strip move and auto-fire were "next"; he expected them in this build. Say plainly what is built vs only recorded.
- All gotchas from the previous handoff still apply (DevTouch before key presses; 1x1 viewport right after Play; heredoc `\n` trap; PreloadAsync Failure from the MCP).
- Confirmed fixed by Alan: Flight School's earlier problems.

## WHAT SHIPPED / OTHER QUEUED
- This session's commits are listed in `handoff-2026-10-28-mobile-lane-phone-run-fixes.md` (b815bd80 … d3779fc9) + this handoff commit (playtest note, STATE).
- Queued: prices, drawing check, touch step 6 (STATE).

## KNOWLEDGE UPDATED
- docs/playtests/2026-10-28-phone-tutorial-run.md (new) + README line. state/STATE.md: findings list. Checker: OK (136 pages).

## POINTERS
- `src/client/SettingsScreen.luau:66` (slider), `src/client/Tutorial.luau` (slowTag, card buttons, Skip all), `src/client/Hangar.luau`, `src/server/RangeStage.luau`, `src/client/RangeBoard.luau`, `src/client/TouchControls.luau`, `src/client/CombatController.luau`.
