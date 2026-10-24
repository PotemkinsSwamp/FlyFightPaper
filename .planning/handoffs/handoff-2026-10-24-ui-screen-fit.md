# HANDOFF — 2026-10-24 — Phone screens readable; screen fit plan approved, step 1 (one size rule + check) built

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/PaperUI.luau, src/client/ScreenFit.luau, src/client/ScreenCheck.luau, src/client/DeskHangar.luau, src/client/FlightHUD.luau, src/client/Tutorial.luau, src/client/RoundEnd.luau, src/client/SettingsScreen.luau, src/client/Hangar.luau, src/client/HangarCustomize.luau, src/client/MenuBoard.luau, src/client/PauseScreen.luau, src/client/MatchTips.luau, src/client/RangeNotes.luau, src/client/RangeBoard.luau, src/client/TouchControls.luau, src/client/ScorePopups.luau, src/client/DevTools.luau, docs
**Time:** 2026-10-24 03:07 -04:00

★ START HERE: Goal (Alan): every UI piece in its place and well sized on ANY screen (small phone, big phone, iPad, PC,
wide monitor), never overlapping. Opening action: in Play (Device Simulator on), run the check
`require(game.Players.LocalPlayer.PlayerScripts.FlyFightPaper.ScreenCheck).run()` on the flying screen, the desk, a
lesson and the round end, then do screen fit step 2 (the top row and the notes under it). Done when the check is clean
on every device Alan switches to and the screenshots look right.

> Read on demand: AGENTS.md → THIS → `docs/plan/SCREEN-FIT-PLAN.md` (Progress) → `docs/workshop/lessons.md` (end of
> "Studio and the place file": driving the phone view from MCP, TouchTapInWorld). Memories: studio-not-drawing,
> alan-does-play-checks, studio-play-is-shared, plan-before-building-features.

## STATE (verify before acting)
- HEAD `31c907ec` + this handoff's commit on main; the commit hook copies to GitHub and pushes. `git log --oneline -3`.
- Unit suite 425 / 0 in Play this session (server VM: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`).
- Docs checker OK (130 pages): `python tools/check_docs.py`.
- Studio: Edit, Device Simulator ON (Alan switched to a bigger phone, ~831 x 439), Rojo serving on 34872. At the end
  Studio was NOT drawing in Play (0 frames/s, viewport 1 x 1: window behind something); the ScreenFit refactor loads
  with no errors and tests pass, but it was never seen drawn. First Play: check frames, else ask Alan to bring Studio
  forward.
- Cost: 0 subagents, 0 Codex, 0 uploads, $0; ~15 Claude Play runs (phone screenshots, tap tests). Context ~41%.

## NEXT ACTION + PLAN
1. Run ScreenCheck on each screen (phone) to list today's problems; screenshot. The check skips menu backgrounds and
   Studio's test buttons; it was only run once (main menu, before the Backdrop skip), so expect some false positives
   to tune (design overlaps inside one group are ignored by design).
2. Screen fit step 2, the top row on phones (Alan saw Menu, match strip, kill feed jumbled): place the match strip
   right of the Menu button's real edge inside the top bar's free room (measure with a probe ScreenGui using
   `ScreenInsets.TopbarSafeInsets`; it exists in this Studio), scaled down if it doesn't fit; the news / lock /
   capture notes just under the top bar; threat, lesson note and match tip stacked under each other from their real
   edges (a small shared "lowest bottom of these pieces" helper in ScreenFit is the idea; other modules find the Menu
   via GameMenu.OpenMenu, keep that path); kill feed 2 slips on a phone (Slip1 is newest); the desk's right strips
   start under the feed's real bottom. Phone = `ScreenFit.kind() == "phone"` (size), not touch.
3. Then plan steps 3-6 (desk, notes/round end/plates/pop-ups, menus' minimums, per-device screenshots for Alan).
4. After screen fit: stick tuning with Alan, then touch step 6 (private publish, his go).
Stop rule: a step is done when ScreenCheck is clean and screenshots read on each device Alan switches to; no reviews.
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control (incl. switching the simulator's device:
Alan does it), closing Studio, Save to File, real product IDs/prices, turning sales on, Studio Play while he plays.

## DECISIONS & WHY (this session)
- Phone = screen under 540 points tall (later: short side, ScreenFit), not touch input: layout is about room.
- `PaperUI.phone(piece, props)`: phone values swap in, PC values restored exactly; PC look unchanged by design (not
  re-screenshotted on PC: the simulator was on). Redrawn screens (the binder) read `isPhone()` at draw time instead
  (a watcher per redraw would leak connections).
- Menu layers use `ScreenInsets.None` (art reaches past the notch); the sheet fits the safe area (SafeArea probe);
  on phones the background is pinned to the top (titles drawn in the art stay whole).
- Results card: 6 bigger rows on a phone (the last is you when you're not in them); round banner and vote drop below
  the top bar on phones.
- Alan approved the screen fit plan: small PC moves OK with before/after pictures; kill feed 2 lines on a phone; he
  switches simulator devices (decision 2026-10-24-screen-fit).
- ScreenFit scale = min(width/1920, height/1080) with a least per kind (HUD phone 0.4, notes phone 0.5, else 0.6),
  no most yet (keeps PC identical); touch buttons clamped to thumb sizes in points.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons.md (+3 this session).

## CARRY NOTES / GOTCHAS
- MCP clicks under the simulator: a click at (x, y) lands at GUI (x - 62, y); tap a button at its AbsolutePosition
  centre + (62, 0). An MCP key press flips PreferredInput to keyboard: set `DevTouch` to keep the touch layout.
- `DevScreen` player attribute opens a screen ("hangar:customize" = the binder).
- Studio's weapon/mode test buttons (WeaponPicker) are 880 wide over a phone: Studio only; reparent it out of the way
  for screenshots.
- Lesson end card buttons' words ~15 points ("Next: Combat School" fills its strip); results card can cover the desk's
  right strips at round end (same on PC; pre-existing).
- Not done from the touch plan: "Drag to aim" option; controller.

## WHAT SHIPPED / OTHER QUEUED
- 45248d58 Phones: every menu screen readable (bigger words and taps on a small screen, PC unchanged); backgrounds reach past the notch; desk, notes, tips and round end clear of the Menu button
- c61145c0 Phones: tapping a Range strip hits the strip you tapped (the tap was read 58 points too low); taps checked in the simulator
- 85790469 State: phone screens done in the simulator; stick tuning next
- 742ec307 Plan: screen fit (one size rule, a screen map, an automatic overlap check) for Alan's OK
- e550a21e Screen fit plan approved (Alan): decision note
- 31c907ec Screen fit step 1: one shared size rule (ScreenFit) for the flying screen, desk strips, notes, tips and touch buttons; a Studio check that lists overlaps and small words or taps
- + this handoff (STATE update).
- Queued (Alan's): stick tuning; winners' sound Play check; Save to File; prices; private publish; drawing pass.

## KNOWLEDGE UPDATED
- plan/SCREEN-FIT-PLAN (new, approved, Progress); decisions/2026-10-24-screen-fit (+README); plan/TOUCH-PLAN
  (step 4 done, taps checked); systems/menus-and-hud (phones line, PaperUI/ScreenFit/ScreenCheck rows); workshop/
  lessons (+MCP phone driving, +TouchTapInWorld); HOME (screen fit plan); STATE updated. Checker: OK (130 pages).

## AAR
Supposed: phone screens readable, taps checked, stick tuning with Alan. Actual: screens and taps done (one real tap
bug found), then Alan widened the goal to every piece fitting every screen; plan approved, step 1 built. Why: the
first pass fixed sizes screen by screen; Alan saw pieces still colliding (the top row), which needs placement from
real neighbours, not bigger numbers. Next: measure before fixing (the check first), and place pieces from each
other's real edges. Cost matched output: everything was Claude Play runs, $0.

## POINTERS
- `src/client/ScreenFit.luau`, `src/client/ScreenCheck.luau`, `src/client/PaperUI.luau` (phone helpers, screen()).
- Top row today: `src/client/FlightHUD.luau` (the touch placement block right after `matchInfo.Enabled=shown`;
  threat/lesson stacking near "threat.Position"), `src/client/MenuController.luau` (Menu button docking),
  `src/client/MatchTips.luau`, `src/client/Tutorial.luau` (noteTop, placeNote), `src/client/DeskHangar.luau` fit().
