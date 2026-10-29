# HANDOFF — 2026-10-29 — mobile lane: Alan's 7 phone notes fixed + phone screens checked; waiting on his publish

**Labels:** kind=ui · lane=mobile-lane · branch=main · issues= · areas=src/client, src/first/MenuArt.luau, src/shared/ProfileSchema.luau, docs/systems, docs/workshop, state
**Time:** 2026-10-29 00:23 -04:00

★ START HERE: Goal (Alan): mobile works and looks good. First: Alan publishes (at his PC: File > Publish As > game tile > Overwrite, or he says "go" and approves the desktop-control box while there) and runs the phone list in STATE "Waiting on Alan"; fix what his run finds, each checked in Studio at phone size. Done when his phone run passes.

> Read on demand: AGENTS.md → this file. Then only what the step needs: `docs/playtests/2026-10-28-phone-tutorial-run.md` (his notes + outcome), `docs/workshop/lessons.md` (Device Simulator tap offsets, global-layer ScreenGuis, no remote publish). Memories: studio-play-is-shared, alan-does-play-checks, look-up-roblox-ui-steps.

## STATE (verify before acting)
- HEAD = this handoff's commit on main (after `f98962c1`); GitHub copy pushed by the commit hook (`python tools/push_github.py`; if it prints FAILED, `git push -q origin refs/heads/github-snapshot:refs/heads/main`).
- Tests: 426 passed, 0 failed (34 suites) in Studio Play this session. Re-run: in a Play server, `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Docs checker OK (136 pages): `python tools/check_docs.py`.
- Studio: Edit mode, place 132768925825316 (online copy), holds HEAD's `src/` (synced by script.Source, no Rojo), NOT saved, NOT published. Check: Edit VM `CombatController.Source:find("auto=nowAuto")`.
- `FlyFightPaper-WORKING.rbxlx` is from 2026-10-25: older than Studio; never rebuild/publish from it without Alan's Save to File.
- Cost this session: no agents, no Codex/Meshy, no uploads, nothing paid; primary context ~40% at handoff.

## NEXT ACTION + PLAN
1. Alan publishes + phone run (his items in STATE). Fix findings; each checked in Studio at phone size (Device Simulator 749x381).
2. iPad check: needs the Device Simulator switched to an iPad (desktop control → Alan's go, or he switches it).
3. Then: results card heads crowd on phones ("Folds Assists Crashes" touching); match tips moving on a phone; touch step 6 / prices / drawing pass stay queued (STATE).
- HOLDS (Alan's go, each): publish, Save to File, any upload, desktop control, Studio Play while he plays, anything paid.

## DECISIONS & WHY (this session; in STATE "Decisions to review")
- Auto-fire fires on red OR yellow dot (yellow = lands thanks to phone aim help); in the Range it fires on targets too, so phone accuracy reads high.
- Steering bar 0.2-1.8 for mouse too (one bar); saves above 1.8 fly at 1.8 (schema still accepts 0.2-3, so old saves stay valid).
- Range strips move on phones only, client-side (`RangeBoard.fitCorner`): taps and crosshair clicks are client raycasts, so the server copy needn't move; PC keeps Alan's 2026-10-20 spot.
- Range notes hide while the Range menu is down (a dodge box was tried: no free spot beside the menu on a phone).
- Did NOT publish remotely: approval box is PC-only, and an Open Cloud publish of the 4-day-old file would roll back art.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (hard limits, model router, docs rules); memories studio-play-is-shared, no-surprise-desktop-control, look-up-roblox-ui-steps (Publish As > Overwrite, never plain Publish).

## CARRY NOTES / GOTCHAS
- Device Simulator taps from `user_mouse_input`: GUI ≈ (x-62, y-20); `TouchTapInWorld` ≈ (x-62, y+38). Range strips at viewport y≈20 can't be clicked by MCP: move the part down client-side to test.
- A "tap did nothing" is likely real: log InputBegan/Activated first (the hover-grow tap bug looked like tool flakiness for a session).
- `endMatch` (RoundAction) in Studio: results card shows ~18-21 s later for ~10 s, then the vote (~20 s).
- Welcome question card pops up after every Play/match on the test account: hide `Tutorial.Ask` before screenshots.
- Lesson key for the tour is `hangar` (DevLesson "tour" falls back to Flight School).

## WHAT SHIPPED / OTHER QUEUED
- c52c0ed7 Phone run fixes: auto-fire switch, steering bar 0.2-1.8, Skip all then Next opens the next lesson, Close and Range tab show their words, Back taps no longer lost, Slow Motion paper fits its words, Range strips right of the score card on phones
- 726e33fd Range notes step aside while the Range menu is down
- 9bf67879 Phone vote: taller cards and bigger words (were about 13 points)
- 3299cc17 / f98962c1 State updates
- + this handoff commit (lessons line on remote publish, handoff, LATEST).
- Queued: prices, drawing check, touch step 6 (STATE).

## KNOWLEDGE UPDATED
- docs/systems/menus-and-hud.md: phone auto-fire, steering bar, MenuArt word lift, tap-area fix, phone screen check results.
- docs/systems/tutorial.md: Range strips on phones, skip-in-air holds still, Close word, notes hide under Range menu.
- docs/decisions/2026-10-28-phone-steering-and-auto-fire.md: built 2026-10-29 (+ yellow-dot choice).
- docs/playtests/2026-10-28-phone-tutorial-run.md: outcome line.
- docs/workshop/lessons.md: corrected the wrong "clicks stop landing" lesson; global-layer ScreenGuis; no remote publish.
- Checker: OK (136 pages).

## POINTERS
- `src/client/CombatController.luau` (auto-fire), `src/client/FlightHUD.luau` (`onTarget`), `src/client/SettingsScreen.luau`, `src/client/PaperUI.luau` (`tapArea`), `src/first/MenuArt.luau`, `src/client/Tutorial.luau` (`finish`, slowTag, closeButton), `src/client/RangeBoard.luau` (`fitCorner`), `src/client/RangeNotes.luau`, `src/client/RoundEnd.luau` (vote phone sizes).
