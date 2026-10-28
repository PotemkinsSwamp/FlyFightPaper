# HANDOFF — 2026-10-28 — mobile lane: notes move out of the way, finger-sized taps; tutorial room bug waits on Alan's phone run

**Labels:** kind=ui+product · lane=mobile-lane · branch=main · issues= · areas=src/client (ScreenFit, PaperUI, Tutorial, MatchTips, RangeNotes, MenuBoard, Hangar, SettingsScreen, ScreenCheck, Loading), src/server (LoadLog, Matchmaking, MatchmakingAdapter), docs
**Time:** 2026-10-28 17:30 -04:00

★ START HERE: Goal (Alan): mobile works and looks good. First: once Alan has published and run the tutorial on his phone, read the join log (Studio Edit: `GetDataStore("LoadTimes"):GetAsync("recent")`, newest first; entries now carry `room` and `note` rows) and find why the private tutorial room doesn't know it is one. Done when the cause is named and fixed in code. Then the screens not yet checked on a phone.

> Read on demand: AGENTS.md → this file; then `docs/systems/tutorial.md` (bug + notes), `docs/plan/SCREEN-FIT-PLAN.md` (progress), `docs/workshop/lessons.md` (Studio test tricks). Memories: studio-play-is-shared, alan-does-play-checks, studio-not-drawing.

## STATE (verify before acting)
- HEAD `82d8de11` + this handoff (main). The commit hook copies to GitHub; main has no upstream, so never `git push origin main` by hand (rejected; the hook's copy is the push). Confirm: `git log --oneline -1`.
- Docs checker: OK (134 pages). Re-run: `python tools/check_docs.py`. Unit tests not run this session (`docs/workshop/testing.md`, in Play).
- Studio: open, Edit mode, holds HEAD's code (pushed in with `HttpService:GetAsync` from a local server, now stopped), not Rojo-connected, not saved to file. Device Simulator is on a notched small phone (873 x 401, safe 749 x 381).
- Load lane: DONE (Alan): phone first join 48.8 s (v402), Skip 10 s, picture memory 49 MB.
- Cost: no agents; ~10 Studio Plays (Alan's yes), many short Studio reads; 0 uploads, $0. Primary context ~40% at handoff.

## NEXT ACTION + PLAN
1. Tutorial room bug: Alan publishes + runs the tutorial on his phone → read the log rows (`room`: public / tutorial / error text; `note`: "moving to tutorial", "move failed: ...", "no room for ...", "send failed: ..."). Theory: the private room's `Matchmaking:currentClass()` ends with class nil or an error, so `TutorialRoom` stays false (menu shows, Play starts a match in that room, no third join). Fix the cause; his next phone run checks it.
2. Screens not yet phone-checked: Range menu, round results, Training board, desk quick menu in a match, match tips and Range notes moving (an account that saw them all never gets them: fresh profile or a Studio hook), iPad. Tool: `ScreenCheck.run()` in the Client VM with `DevPhone` / `DevScreen`.
3. Then screen-fit steps 3-6 as listed in the plan.
- HOLDS (Alan's go): publish (he does it), Save to File, any upload, desktop control, Studio Play while he plays, anything paid.

## DECISIONS & WHY
- Load lane closed at 48.8 s first join (Alan: only the first join is slow; the loading bar now says so). `docs/decisions/2026-10-25-fast-phone-loading.md`.
- Notes dodge only after covering what matters for 0.4 s, stay put until the step/tip changes, never at the desk (they landed on the desk's buttons). Spots: home, right, left (3 degree tilt), bottom (Alan: "left or right slightly turned", all platforms, tips too).
- Phone lesson note 860 x 200 at home (fits right of Health/Lift; the first 1200-wide shape shrank to 40%), 560 x 400 at a side.
- Phone taps: an invisible `Hit` child (`PaperUI.tapArea`, 46 points) instead of resizing every drawn button; holds and drags listen to `Hit` too. Settings colour stickers grow only taller (the row is too tight to widen).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (plain English to Alan, one fact one page, commit + push often, model router); memories studio-play-is-shared, no-surprise-desktop-control, alan-does-play-checks.

## CARRY NOTES / GOTCHAS
- Python file writes on this PC sometimes fail with `OSError: [Errno 22]`: retry in a short loop (cause unknown).
- Set `DevPhone` / `DevTouch` / `DevCover` in the Client VM only, never on the Edit place (they'd be saved and published).
- Studio test tricks (the MCP's require is a separate copy; simulated clicks can stop landing; Rojo-less sync): `docs/workshop/lessons.md`.
- Roblox chat's "/help" hint shows over Health/Lift on a phone at join (Roblox's own, fades).

## WHAT SHIPPED / OTHER QUEUED
- 40ad8be8 Load notes: repack memory dig
- be9d6126 Phone join v402: 48.8 s, 49 MB, the sheets were the memory
- 638503d7 Loading screen: first-load note under the bar, rotates with the grey-buildings note
- 0b8dfe6c Room moves recorded in the join log
- 7686e0e6 Load lane done (Alan)
- 3e3fd396 Tutorial note on phones: wide and short, bigger words
- cef1be9f Lesson: syncing a few files into Studio without Rojo
- 87b404c2 Tutorial note on phones sits up in the top bar
- db80d3d9 Notes keep out of the way (lesson notes, tips, Range notes)
- 97b9f901 Paper screens: no error on resize after a screen closed
- 2b80858c Phones: 44+ point taps on welcome question, cards, note, menu
- 522ac3d6 Phones: every paper button gets a 46-point tap area
- 82d8de11 State: mobile lane progress
- Queued: prices, drawing check, touch step 6 (STATE "Waiting on Alan").

## KNOWLEDGE UPDATED
- docs/systems/tutorial.md: room bug + recorder; phone note shapes; out-of-the-way rule.
- docs/systems/menus-and-hud.md: ScreenFit row (dodger, Studio hooks). docs/systems/performance.md: loading note, LoadLog rooms.
- docs/plan/LOAD-PLAN.md: v402 result, lane done. docs/plan/SCREEN-FIT-PLAN.md: 2026-10-28 phone check.
- docs/decisions/2026-10-25-fast-phone-loading.md: lane-done line. docs/playtests/2026-10-28-phone-joins.md: v402 row.
- docs/workshop/lessons.md: Rojo-less sync, the MCP's require is a copy, clicks can stop landing. Checker: OK.

## POINTERS
- `src/client/ScreenFit.luau` (dodger, matters, DevPhone/DevCover), `src/client/PaperUI.luau` (tapArea), `src/server/Matchmaking.luau` + `MatchmakingAdapter.luau` (tutorial room), `src/client/ScreenCheck.luau`.
