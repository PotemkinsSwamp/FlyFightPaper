# HANDOFF — 2026-10-24 — Winners' sound built; touch controls, phone aim help and the phone flight screen in; menus next

**Labels:** kind=ui · lane=ui · branch=main · issues= · areas=src/client/TouchControls.luau, src/client/WinnersSound.luau, src/shared/AimHelp.luau, src/shared/TouchWords.luau, src/client/FlightHUD.luau, src/client/FlightController.luau, src/client/CombatEffects.luau, src/client/PaperUI.luau, src/client/RoundEnd.luau, src/client/Audio.luau, src/client/Tutorial.luau, src/client/SettingsScreen.luau, src/client/Hangar.luau, src/client/RangeBoard.luau, config/gameplay.json, docs
**Time:** 2026-10-24 01:45 -04:00

★ START HERE: Goal: everything in the game usable AND good-looking on a phone (Alan: "make everything mobile
accessible, keep working ... not only accessible but look good"). Opening action: in Studio's Device Simulator (on,
749 x 381 phone), Play and screenshot each screen (main menu, Settings, Hangar shelf + binder, desk strips, lesson
note, Match Tip, Range notes, round end + vote, pause) and make the text readable (~12+ points) and taps big (~44 pt)
without breaking the PC look. Done when Alan plays a full session on his phone and says it works (touch plan step 6).

> Read on demand: AGENTS.md → THIS → `docs/plan/TOUCH-PLAN.md` (Progress) → `docs/workshop/lessons.md` (3 new
> Studio lessons at the end of "Studio and the place file"). Memories: alan-does-play-checks, studio-play-is-shared,
> plan-before-building-features, look-up-roblox-ui-steps.

## STATE (verify before acting)
- HEAD `9f802e31` + this handoff's commit on main; the commit hook copies to GitHub and pushes. `git log --oneline -3`.
- Unit suite: NOT run in full this session. New specs pass in Edit (AimHelp 5/0, TouchWords 2/0). Re-run in Play:
  server VM `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()` (was 418/0 + 7 new).
- Docs checker OK (128 pages): `python tools/check_docs.py`.
- Studio: Edit, Device Simulator ON (phone, landscape), Rojo serving on 34872, place not re-saved.
- Cost: 4 subagents (Sonnet aim research ~174k tokens, Sonnet Explore inventory ~197k, 2 tiny web-fetch), 0 Codex,
  0 uploads, $0. ~5 Claude Play runs (layout screenshots). Primary context ~41% at handoff.

## NEXT ACTION + PLAN
1. Phone screens (touch plan step 4), screen by screen in the simulator. Known: PaperUI sheets fit at ~0.35 scale on a
   phone, so 24-30 px design text is 8-11 pt; DeskHangar has one UIScale `min(X/1920,(Y-12)/1068)` for 3 panels;
   lesson/tip notes use `max(0.6, Y/1080)` (big on a phone; the HUD now uses 0.4 on touch). Fix by look, then
   screenshot PC (DevTouch off) to prove nothing changed there.
2. Check taps really work in the simulator: Range strips (TouchTapInWorld uses `ScreenPointToRay`: inset unverified),
   sliders, Hangar plane turning, held Skip, Prestige hold (MenuBoard MouseButton1Down/Up on a finger).
3. Tune stick feel/size with Alan (`flight.touch_stick_*`), then step 6: private publish (his go) and his phone.
Stop rule: a screen is done when its screenshot reads at phone size and the PC screenshot is unchanged; no reviews.
HOLDS (Alan's go, each): publish, Meshy, anything paid, desktop control, closing Studio, Save to File, real product
IDs/prices, turning sales on, Studio Play runs while he's playing. Uploads allowed after an assembled preview he OKs.

## DECISIONS & WHY (this session)
- Winners' sound: everything builds to 1st's landing (Alan's idea), so the song only needs ~18 s; all three finalists
  used at random (Alan). Built with AudioPlayer so the same code plays in Edit (preview) and in game.
- Touch before launch (Alan OK'd plan; decision 2026-10-23-touch-before-launch). Stick default, "Drag to aim" option
  later (not built yet). Aim help only after research (Alan), no auto-fire (Alan), yellow "helped" dot (Alan yes).
- Fake-pilot test found touch got NO help past 600 studs; now touch help is never less than the mouse's; range 800
  (the Range's long row is ~630 away). Cone 9 beat the mouse, so 6 stays. Slowdown's effect in the test is a guess.
- Phone wording via ONE watcher (TouchControls rewrites every TextLabel/TextButton with TouchWords on touch), not
  per-site edits: catches server messages and per-frame texts. TextBoxes untouched.
- PaperUI: backdrop covers, sheet fits (was: whole sheet covered and cropped ~9% top/bottom on wide screens).
  Identical on 16:9.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons.md (+3: Edit-mode sounds, Edit-mode require cache, phone view in Studio).

## CARRY NOTES / GOTCHAS
- Not done from the touch plan: "Drag to aim" Settings option; controller (after touch).
- Tutorial welcome card still says "(Later: Menu > Tutorial.)" (Tutorial.luau ~line 197): should be "Training".
- Per-frame text sets (e.g. lesson "Got it [Space]") are rewritten each frame on touch; watch for a flicker.
- `DevTouch` (ReplicatedStorage.FlyFightPaper attribute, Studio only) shows the touch layout on a PC.
- Studio's "end match" button is now three "end: <song>" buttons (one-shot song choice).
- Old carries: match bots' guns cross at 150 (Alan's call), cutscene hitch, Track C private publish, fan sound.

## WHAT SHIPPED / OTHER QUEUED
- 5d3281c8 Winners' moment sound mix built up to 1st's landing, three finalist tracks to hear in Studio
- e9ea6e79 Winners' moment plays its own sound in the game; Studio end-match buttons for each finalist song
- caeeec52 Winners' moment plays a random one of the three songs each round, never the same twice in a row
- 380dad9b Plan: touch controls for phones and tablets, for Alan's OK
- 22c67b60 Touch controls move ahead of launch (Alan OK'd the touch plan); aim help for touch after research
- ed23b3d8 Touch: a steering stick under the left thumb and Fire / 2 / Boost buttons under the right, while flying on a phone
- 1e56bca0 Research: aim help for touch and controller players, starting numbers and how we'll tune them
- f474406b Touch aim help: a wider gun assist that fades at its edge, the aim slows over an enemy, and a yellow dot when the help lands the shot
- 6ee655be Fake-pilot test: touch aim help never less than the mouse's (it vanished past 600 studs), reaches 800 studs; thumbs land 83-100% of a mouse's hits
- 74cb4d78 Touch: sliders, Hangar plane turning and Range strips take fingers; held Skip skips a lesson; every text says touch words on a phone
- 9f802e31 Phones: flight screen laid out for a small screen (paper FIRE buttons show their weapon, bars top-left, strip beside Menu); menu backgrounds cover while buttons always fit
- + this handoff (STATE rewrite, lessons).
- Queued (Alan's): his Play check of the winners' sound; stick feel in the simulator; Save to File; prices; private
  publish (touch step 6 + Track C); drawing pass; emotes with music.

## KNOWLEDGE UPDATED
- plan/TOUCH-PLAN (new, approved, Progress); decisions/2026-10-23-touch-before-launch (+README); VISION controls line;
  plan/MILESTONES (Touch stage before Stage 11); research/TOUCH-AIM-RESEARCH (+ fake-pilot results); systems/flight
  (touch, TouchControls row, stick numbers); systems/menus-and-hud (phone aim help, AimHelp + TouchWords rows);
  systems/sound-and-effects (WinnersSound row); systems/modes-and-scoring (end buttons); workshop/lessons +3;
  HOME (touch plan, research); STATE rewritten. Checker: OK (128 pages).

## AAR
Supposed: winners' track + cue sheet → build → Alan's OK. Actual: built and hooked in, Alan wanted to see it in the
game (dev buttons), then picked all three; his question on mobile turned into the touch plan and most of steps 1-3,5.
Why: Alan redirected twice; each redirect was small to serve. Next: a timed mix is easier to judge in the real moment
than as a sound-only preview, so offer the in-game test button first. Cost matched output: the Edit-mode fake-pilot
test (pure math, no Play) found a real bug for almost nothing.

## POINTERS
- Touch: `src/client/TouchControls.luau` (stick, buttons, gauges, wording watcher, DevTouch), `src/shared/AimHelp.luau`,
  `src/shared/TouchWords.luau`, `config/gameplay.json` flight.touch_stick_*, combat.touch_*.
- Phone layout: `src/client/FlightHUD.luau` (panel() floor, the touch block after the trigger rows), `src/client/PaperUI.luau` screen().
- Winners' sound: `src/client/WinnersSound.luau`, `src/client/RoundEnd.luau` (start/stop), `src/client/Audio.luau` (WinnersMoment fade).
