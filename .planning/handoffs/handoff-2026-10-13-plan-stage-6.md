# HANDOFF — 2026-10-13 — Plane work done; next session PLANS Stage 6 with Alan (playtest skipped)

★ START HERE: Goal: plan Stage 6 (UI, HUD and the first 60 seconds) together with Alan, then build it. Opening
action: show Alan what Stage 6 asks for (docs/MILESTONES.md "Stage 6") next to what already exists in the game, in
plain words, and agree the order with him. Done when he has approved a short Stage 6 plan (what first, what "done"
looks like for each piece); then build the first piece.

> Read on demand: AGENTS.md → THIS → docs/MILESTONES.md (Stage 6, Stage 9) → state/STATE.md. Supersedes
> handoff-2026-10-13-wing-attach-points.md (same work, but Alan skipped the playtest). Memories: in-game-menus-match-
> main-menus, studio-play-is-shared, no-surprise-desktop-control, roblox-mesh-import-gotchas.

## STATE (verify before acting)
- HEAD `46cd2dc6` + this handoff commit (main), NOT pushed. Confirm: `git rev-parse --short HEAD`.
- Tests 261/0 in Play (Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Rojo serve syncing (`curl -s http://localhost:34872/api/rojo`). Place NOT re-saved
  (needs Alan's Ctrl+S).
- Cost this session: 3 Codex jobs (Alan's ChatGPT plan), 56 free uploads, 0 Meshy, 0 desktop control. Primary ~46%.

## NEXT ACTION + PLAN
1. Plan Stage 6 with Alan. Stage 6 has three parts (MILESTONES): HUD (reticle, health, Lift/boost bars, reload/lock
   pips, hit markers, kill feed, score/timer, enemy markers + OFF-SCREEN indicators, team markers, capture bar, no dev
   overlays); menus (main, hangar, shop mock, settings incl. crosshair colour/size, results with XP bar + next-unlock
   preview, Paper-spend confirms); first 60 seconds (guided practice flight: steer, fire, Lift/fans prompts, a weak
   target, a landing, then into a Rookie match; skippable, replayable, no repeat reward).
   Rough code search (unverified quality): off-screen indicators have NO code yet; practice/tutorial, kill feed,
   crosshair, sensitivity, music, capture and shake settings have some. Check each in Play before telling Alan.
2. Build the agreed Stage 6 pieces, each checked in Play at 1280x720+ with screenshots; Alan approves Stage 6.
3. Then Stage 9 modes (Airspace Control, TDM visuals, practice mode, props, fans, bots per mode, Rookie graduation).
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid; uploads to his
  Roblox account; desktop control (only if necessary or asked); closing Studio. Don't steer his plane in Play.

## DECISIONS & WHY (this session)
- Alan skipped the playtest of the 21 notes + plane work (2026-10-13): "I don't need to playtest it". Don't block on it.
- Wing attachment points (Alan's design): body WingFront/WingBack + wing RootFront/RootBack; wing scales evenly to fit
  (Aircraft.wingFit, only body_heavy has wall points). Per-wing gun spots Mount1/Mount2 (0.8 behind each wing's
  leading edge); guns scale with the wing. Swept Wings custom points keep it 100%.
- FFA planes split red/blue through body/nose/tail/booster; stickers on every wing; Feather Folds = concept A.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (plain English to Alan, look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md.

## CARRY NOTES / GOTCHAS
- Rojo sync of a rewritten pieces.rbxmx takes seconds: re-check MeshIds before judging. plane_set.py rebuilds every
  set FBX: keep only the changed part. Bell-tower/closeups/WORKING.rbxlx diffs in the tree are not ours.
- state/STATE.md still lists the playtest under "Waiting on Alan": rewrite that when Stage 6 starts.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: see handoff-2026-10-13-wing-attach-points.md (07a1899a … 711addbc) + 46cd2dc6 that handoff.
- Queued: Track C saving (needs private publish); bot-vs-bot rams never land; last stand-in sounds.

## POINTERS
- docs/MILESTONES.md (Stage 6/9), docs/AUDIT-2026-10-07.md, src/client/FlightHUD.luau, src/client/Hangar.luau,
  src/client/DeskHangar.luau, assets/references/ui-concepts/.
