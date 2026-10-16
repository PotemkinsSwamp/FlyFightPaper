# HANDOFF — 2026-10-13 — Alan's playtest: 21 notes to work through (deaths/camera, flight, sounds, weapons, bots, colours, hangar)

★ START HERE: Goal: make the game match Alan's 21 playtest notes in `docs/PLAYTEST-NOTES-2026-10-13.md` (his word is
final). Open with the bug and the feel items he'll notice first: camera jitter when Lift runs out (#4), weapons fire
on the click frame (#14, pencil is ~1 s late), camera follows your remains until respawn (#2). Each note carries its
own check; mark it ✅ in that file as it lands. Stage 8 and 7 approval waits on his next playtest.

> Read on demand: AGENTS.md → state/STATE.md → docs/PLAYTEST-NOTES-2026-10-13.md → THIS. Memories:
> studio-not-drawing (how to make Studio draw), studio-play-is-shared, no-surprise-desktop-control, creator-store-first.

## STATE (verify before acting)
- HEAD = this handoff's commit, main, not pushed (never pushed). `git rev-parse --short HEAD`.
- Tests 257/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Rojo-synced, place saved 16:38. No test parts left in Edit.
- Cost last session: 0 sub-agents, 0 Codex, 0 Meshy, 0 uploads; desktop control used (Alan OK'd it while away);
  primary ~42% context.

## NEXT ACTION + PLAN
1. Notes #4, #14, #2 first (bug + feel). Then in any sensible order: deaths #1 #3; flight #5 #6; sounds #7–#13;
   weapons #15 #16; bots #17; colours #18 #19; hangar #20 #21. Good Codex jobs (pure logic + tests): #20 smart
   weapon placing rules, #5 dive-momentum-with-Lift math, #6 continuous fan gust rule, #15 cooldown in config.
2. Still open from before: last stand-in sounds (hit, kill, service, windup); boost streak unseen on a boosting plane.
3. Then Stage 6 first 60 seconds → Stage 9 modes (Alan's order, D10).
- Done when: every note ✅ with its check met in Play (screenshots at 1280x720+ for visuals, numbers for feel), tests
  green, and Alan approves at his next playtest.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid; desktop control
  (only if necessary or asked). Ask before closing Studio; don't drive his plane while he's in Play.

## DECISIONS & WHY (this session)
- Planes: team colour on the PAPER, white stripes/stickers (inverted from white paper + coloured stripes). Play
  photos: white paper vanished against the cream walls/desks; the city is LEGO red/blue/yellow/green so colour alone
  isn't unique, the white stripes carry it. FFA is all red today; Alan's ruling below replaces that (split red/blue).
- Crash pre-check box now = fitted parts' extent (`ContactSize` attribute); Root size left at 14x2x15 so flight mass
  and turning are unchanged. Old box missed a fin-top touch (tested both ways).
- Hangar weapons tab: still top-down view with clickable numbered tags at each mount (green light, yellow medium,
  purple heavy) replaces the mount cards that covered the photo; spin/drag off on that tab so tags stay put.
- Sounds picked by description (can't hear): Alan judges by ear. 3D only for other planes' shots and deaths.
- Protection bubble = anchored ForceField ball moved each frame (no client welds onto server-simulated planes).

- Alan's rulings 2026-10-13 (all in the notes file): FFA planes split down the middle, left red + square, right blue +
  circle; FFA remains mix red, blue and white; TDM = team colour + team sticker. Whoosh only above a plane's own
  normal speed, scaled by speed. Stapler burst cooldown 0.8 s. Missiles (eraser, pencil) louder than other weapons,
  which share one loudness. Other planes' weapons heard only within a range.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Studio draws its 3D view only while the mouse moves over it, even in front: `mouse_move` wiggle then `zoom`.
  `screen_capture` timed out all session. Point the Play camera with Player attribute `DevCamera` (CFrame).
- `open_application "Roblox Studio"` started a second empty Studio (closed via its X); click the window instead.
- PowerShell process commands (Get-Process/Stop-Process) are denied by the auto-mode classifier.
- TweenService doesn't advance while Studio isn't drawing (volumes read 0.5 until the mouse moved): not a bug.
- Bell-tower re-export files + closeups.png in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- Shipped since the previous handoff (handoff-2026-10-13-sounds-next.md): its own commit, plus this session's notes
  file, STATE update and this handoff (one commit). Earlier today's commits are listed in that previous handoff.
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams never land.

## POINTERS
- docs/PLAYTEST-NOTES-2026-10-13.md (the work list), `.planning/plane-colours-2026-10-13.jpg`.
- src/client/PlaneDeaths.luau (deaths), src/client/ChaseCamera.luau (camera), src/shared/FlightRules.luau (glide,
  climb), src/server/FlightService.luau (fan/updraft, step checks), src/client/Audio.luau (sounds, whoosh, 3D pool),
  src/client/CombatEffects.luau (shots, windup, trails), src/server/BotService.luau (bot awareness),
  src/shared/Aircraft.luau (paint), src/client/Hangar.luau (+ src/shared/BuilderModel.luau for placing), config/gameplay.json.
- Previous: `.planning/handoffs/handoff-2026-10-13-sounds-next.md`.
