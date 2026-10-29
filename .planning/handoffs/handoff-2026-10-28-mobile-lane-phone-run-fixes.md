# HANDOFF — 2026-10-28 — mobile lane: two phone runs' fixes in, sticker buttons in; Alan's next phone run checks them

**Labels:** kind=ui+product · lane=mobile-lane · branch=main · issues= · areas=src/client (Tutorial, TutorialLessons, TouchControls, ScreenFit, MenuController, MenuBoard, RangeNotes, RangeBoard, PauseScreen, Hangar, SettingsScreen), src/server (Matchmaking, MatchmakingAdapter, FlightService), src/shared (FlightRules, TouchWords), src/first/UIAssets, assets/ui/touch, docs
**Time:** 2026-10-28 21:55 -04:00

★ START HERE: Goal (Alan): mobile works and looks good. First: Alan publishes and runs the phone list in STATE "Waiting on you"; turn what he reports into fixes (each checked in Studio at phone size). Then build his two rulings (decision note 2026-10-28: finer steering bar, phone auto-fire on FIRE), then move the Range's "Range Menu"/"Hangar" 3D strips out from under Roblox's top-left icons on phones.

> Read on demand: AGENTS.md → this file; `state/STATE.md`; `docs/systems/tutorial.md` ("Where it stands"); `docs/decisions/2026-10-28-phone-steering-and-auto-fire.md`; `docs/workshop/lessons.md` (Studio tricks: DevTouch before key presses, 1x1 viewport right after Play, Rojo-less sync). Memories: studio-play-is-shared, alan-does-play-checks, assembled-preview-before-upload, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `f2db81c0` + this handoff (main). The commit hook copies to GitHub ("github: pushed"); never `git push origin main` by hand. Confirm: `git log --oneline -1`.
- Docs checker OK (135 pages): `python tools/check_docs.py`. Unit tests not run this session (`docs/workshop/testing.md`, in Play).
- Studio: open, Edit mode, holds HEAD's code (synced file by file through `python -m http.server 8765` in `src/` + `HttpService:GetAsync`, byte counts matched, all loadstring-OK), NOT Rojo-connected, NOT saved to file. Device Simulator on a notched small phone (749 x 381).
- Last published: v413 (Alan's phone runs). Everything since b815bd80 is unpublished.
- Cost: 1 Explore agent (~179k tokens, Opus) for code tracing; 4 Codex picture jobs (Alan's ChatGPT plan); 4 image uploads (free, approved); ~12 Studio Plays (Alan's go). $0. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Alan's phone run (he publishes): tutorial from the menu starts the lesson at once (no menu/song); slide along a wall in Flight School (stays inside; outside → back to desk in 2 s); Range: shoot row plates and Reset with FIRE, notes advance, Menu shows the "Leave Range" note; sticker buttons + stick pad under the thumb; Play says "Starting..."; tutorial exit → match room. Fix what he finds.
2. Build the rulings: steering slider non-linear with 1 in the middle (speed unchanged, saved range 0.2-3); phone Settings with an Auto-fire switch (on by default) — FIRE fires while the dot is red; 2 stays manual.
3. Range strips "Range Menu"/"Hangar" (3D, `RangeStage.luau:119-124`) sit under Roblox's icons on phones: move on phones (crosshair yaw clamp `TrainingCourse.RANGE.yaw` 50° limits how far right; or under Reset).
4. Then the old list: phone-check Range menu, round results, Training board, match desk, iPad; screen-fit steps 3-6.
- HOLDS (Alan's go): publish (he does it), Save to File, any upload, desktop control, Studio Play while he plays, anything paid.

## DECISIONS & WHY
- Tutorial room bug was NOT the room's label (log: rooms say "tutorial"); it was the exit move picking the closed public room from a still-fresh list entry ("GameEnded"). Fix: BindToClose removes the room's row.
- Arriving lesson read from `TeleportService:GetLocalPlayerTeleportData()` on the client (table without `tutorialSeen`) so no menu flash; menu shows after 20 s if the lesson never starts.
- Wall push-through: `FlightRules.contact` accepted a face whose normal pointed away from the plane (look-back ray started beyond a thin wall). Now: face must face the plane's middle, else a ray from the middle toward the piece.
- Touch buttons: lesson HUD names map to touch buttons (`PHONE_NAMES`), round ring for round buttons; touch notes dodge only home/right (Alan: thumbs bottom-left, buttons bottom-right).
- Sticker art: one blank sticker + white crayon disc tinted in code (`ImageColor3`), fill = bottom-anchored clip; pieces 512/256 px for phone memory.
- Range Leave note: added back as "Leave Range takes you back... Keep flying stays here" (2026-10-23 a bare "Menu, then Leave" note made people leave).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (plain English, one fact one page, commit + push often, model router, Codex for pictures). Memories: assembled-preview-before-upload, look-at-textures-before-upload, studio-play-is-shared, no-surprise-desktop-control.

## CARRY NOTES / GOTCHAS
- In Device Simulator Play, set `DevTouch` (Client VM) before `user_keyboard_input` — a key press flips PreferredInput to keyboard.
- Right after Play starts, ViewportSize may read 1x1 / RenderStepped 0: wait and re-measure; Studio was in front (I wrongly asked Alan twice).
- Python heredoc edits turned `\n` into real newlines in Luau strings 3 times: use Edit for escapes; loadstring-check synced files.
- `ContentProvider:PreloadAsync` from the MCP returns Failure even for working ids: judge pictures by screenshot.
- Open Cloud asset status: `.env` key line is `ROBLOX_API ` (space before `=`); strip names when parsing.
- Not seen in Studio: stick pad/knob (needs a real touch), Range touch-FIRE pick, Leave Range note, wall fix in a real slide, Hangar "Range builds" note at y 390 on a phone. Alan's run covers them.
- Phone notes now never dodge to bottom/left: if home and right are both covered the note stays home.

## WHAT SHIPPED / OTHER QUEUED
- b815bd80 Closing rooms cross themselves off the room list
- 9ef41df0 Phones: lessons frame the round buttons, note waits for the room move, bigger Hangar mount numbers
- 2a7e9cf9 Phones: FIRE and 2 framed on first use, two-line Skip, no LAUNCH badge on naming step
- 99ade1df Phone button concepts A/B/C (Codex)
- d5eb13e7 Phones: round ring on round buttons; dodging notes no longer over Health and Lift
- 386adfd0 State: phone run fixes, sticker buttons picked
- 30522062 Sticker button preview (C)
- 89bb1999 Phones: peel sticker buttons with crayon fill
- 76fec4f7 Phone run fixes batch 1 (lesson at once, red Back, desk services, Slow Motion tag, touch dodge spots, tour split, Close)
- 56e8125b Phone run fixes batch 2 (walls, Range touch FIRE, Leave Range note, Play feedback, Range builds note)
- f2db81c0 Decision: phone steering bar finer, auto-fire on FIRE; state
- + this handoff commit (lessons, LATEST).
- Queued (STATE): prices, drawing check, touch step 6.

## KNOWLEDGE UPDATED
- docs/systems/tutorial.md: room-move cause + fix; phone fixes from both runs (Where it stands).
- docs/systems/flight.md: TouchControls row (stickers, crayon fill, shown in read pauses).
- docs/decisions/2026-10-28-phone-steering-and-auto-fire.md (+ README line).
- docs/workshop/lessons.md: AbsolutePosition vs Position tops; DevTouch before key presses; 1x1 viewport after Play; heredoc `\n` trap.
- state/STATE.md rewritten top. Checker: OK (135 pages).

## POINTERS
- Concepts/previews: `assets/references/ui-concepts/touch-buttons-*.png`, `touch-stickers-*.jpg`; pieces `assets/ui/touch/`.
- Code: `src/shared/FlightRules.luau` (contact), `src/client/TouchControls.luau`, `src/client/ScreenFit.luau` (dodger), `src/client/RangeNotes.luau`, `src/client/RangeBoard.luau`, `src/client/SettingsScreen.luau:66` (slider), `config/gameplay.json` flight.touch_*.
