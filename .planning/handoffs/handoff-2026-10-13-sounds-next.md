# HANDOFF — 2026-10-13 — Plane colours, crash fit, hangar diagram, first sound + effects pass done; Stage 7 continues

★ START HERE: Goal: finish Stage 7 (sounds and effects) while Stage 8 waits on Alan's playtest OK. Next: replace the
last stand-in sounds (pencil launcher, hit tick, kill confirm, service done, gatling windup) with licensed Creator
Store sounds — done when each loads in Play (`Sound.IsLoaded`, a TimeLength) and plays from its event with no
console errors. Then see the boost streak on a real boosting plane, then Stage 6 first 60 seconds → Stage 9 modes.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: studio-not-drawing (updated: how to make Studio
> draw), studio-play-is-shared, no-surprise-desktop-control, creator-store-first.

## STATE (verify before acting)
- HEAD `bc4aef33` + this handoff's commit, main, not pushed (never pushed). `git rev-parse --short HEAD`.
- Tests 257/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Rojo-synced, place saved 16:38 (Ctrl+S). No test parts left in Edit.
- Cost: 0 sub-agents, 0 Codex, 0 Meshy, 0 uploads; desktop control used (Alan OK'd it: away from home);
  primary ~41% context.

## NEXT ACTION + PLAN
1. Stage 7 sounds still on stand-ins in `src/client/Audio.luau` definitions: pencil, hit, kill, service, windup,
   empty. Pro Sound Effects (creator "ProSoundEffects") and Roblox's own classic sounds (creator "Roblox") are the
   licensed sources; search with `search_asset` (assetType Audio, free). Load-check each in Play.
2. Boost streak (`CombatEffects` BoostTrail) untested on a flying booster: no bot carries a booster; give the human
   plane a booster build, fly, hold Shift, look.
3. Then Stage 6 first 60 seconds → Stage 9 modes (Alan's order, D10).
- Waiting on Alan (STATE "Waiting on Alan" 5–7): plane colours OK? hangar diagram clear? which sounds sound wrong?
  Stage 8 is not done until he approves.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid; desktop control
  (only if necessary or asked — today's OK was for while he's away). Ask before closing Studio; don't drive his plane.

## DECISIONS & WHY (this session)
- Planes: team colour on the PAPER, white stripes/stickers (inverted from white paper + coloured stripes). Play
  photos: white paper vanished against the cream walls/desks; the city is LEGO red/blue/yellow/green so colour alone
  isn't unique, the white stripes carry it. FFA = all red. Easy to flip in `Aircraft.paint`.
- Crash pre-check box now = fitted parts' extent (`ContactSize` attribute); Root size left at 14x2x15 so flight mass
  and turning are unchanged. Old box missed a fin-top touch (tested both ways).
- Hangar weapons tab: still top-down view with clickable numbered tags at each mount (green light, yellow medium,
  purple heavy) replaces the mount cards that covered the photo; spin/drag off on that tab so tags stay put.
- Sounds picked by description (can't hear): Alan judges by ear. 3D only for other planes' shots and deaths.
- Protection bubble = anchored ForceField ball moved each frame (no client welds onto server-simulated planes).

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
- 6325b310 Planes wear their team colour all over with white stripes, so they stand out from the cream room
- 0cf0323b STATE: shorter
- f6923309 Crash check covers every fitted part, so tall tail fins can hit ceilings and roofs
- 826e936b STATE: shorter
- 6b64d50d Hangar preview turns slowly by itself and shows shading on the folds
- 08aa5826 Hangar weapons tab shows a mount diagram: numbered tags on the plane, coloured by size
- 54b81c49 Sounds: speed whoosh, 3D shots and crashes, licensed sounds for pellets, eraser, near miss, death, bell, coin, classroom chatter
- f4508836 STATE: shorter
- 2a1af70a Sounds: rubber band slingshot, lock pings, fan whir, cardboard landing, end whistle
- 956c9074 Protection bubble during takeoff and launch protection; white streak while boosting
- bc4aef33 STATE: shorter
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams never land.

## POINTERS
- Colour sheet sent to Alan: `.planning/plane-colours-2026-10-13.jpg`.
- src/shared/Aircraft.luau (paint, ContactSize), src/shared/FlightRules.luau (contact), src/client/Hangar.luau
  (preview, mount diagram), src/client/Audio.luau (definitions, whoosh, 3D pool), src/client/CombatEffects.luau
  (damage loop: trail, domes).
- Previous: `.planning/handoffs/handoff-2026-10-13-colours-next.md`.
