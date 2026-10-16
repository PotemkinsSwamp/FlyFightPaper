# HANDOFF — 2026-10-14 — Stage 6 approved; Stage 9 moving zone, paper targets and test-mode button built

★ START HERE: Goal: finish Stage 9 (game modes) so Alan can approve it. Opening action: ask Alan for his playtest
notes on the moving Airspace zone, the hidden paper targets and the "Mode: …" test button (STATE "Waiting on
Alan" #1), then fix what he finds. Done when Alan approves Stage 9.

> Read on demand: AGENTS.md → THIS → state/STATE.md → docs/MILESTONES.md (D13 + Stage 9 section).
> Memories: powershell-commands-for-alan, studio-play-is-shared, codex-for-pictures-and-blender,
> look-at-textures-before-upload, studio-not-drawing.

## STATE (verify before acting)
- HEAD `3dd99bff` (main), no remote tracking (local only, as before). Confirm: `git rev-parse --short HEAD`.
- Tests 267/0 in Play (Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
  The 6 new zone tests are Codex's (reviewed). Not re-run after the last RoundRuntime edit (dev-mode hook only).
- Studio: WORKING open in Edit, Rojo serve syncing (`curl -s http://localhost:34872/api/rojo`). Place NOT re-saved
  (Alan's Ctrl+S). Rojo can lag a few seconds: check a script's Source in Edit before starting Play after an edit.
- Cost this session: 9 codex-rescue subagents (~20k Claude tokens each; Codex work on Alan's ChatGPT plan),
  0 Meshy, 28 image uploads (all run by Alan himself), 0 desktop control. Primary ~50% context at handoff.

## NEXT ACTION + PLAN
1. Alan's playtest notes → fixes (zone size/look, target size/points/places, mode button).
2. Look at what is still unseen: the ceiling zone spot, a paper target being hit (server "paperTarget" event + fall),
   TDM in a full match (team colours, scores), the end-of-round mode vote screen.
3. Bots in Airspace: only `personality=="objective"` bots fly to the zone (BotService ~line 256); decide with
   Alan's notes whether more should.
4. Fly-through obstacles to lose a chaser: WORKSHOP with Alan first (D13); build nothing before his design OK.
5. Bots verified in every mode; rookie graduation check. Then Alan's Stage 9 approval.
- HOLDS (Alan's go, each): uploads to his Roblox account (he runs them: `cd D:\FlyFightPaper; python
  tools/ui_pieces.py <screen> --upload`), private publish, Studio-settings changes, Meshy spend, anything paid,
  desktop control (only if necessary or asked), closing Studio. Don't steer his plane while he is in Play.

## DECISIONS & WHY (this session)
- Stage 6 approved by Alan after the restyle (concepts in assets/references/ui-concepts/; his mix: concept 1 for
  bars/weapons/round strip/kill feed/aim marks, concept 2 for edge arrows and the INCOMING note).
- News note = yellow-tinted crumpled tape label + two separate red pins: 9-slicing the pinned menu strip shrank the
  pins and showed seams (Alan rejected both stretched and 9-sliced). Layer separate pieces instead.
- White crayon art for aim marks/arrows/key boxes, tinted in game (keeps the crosshair colour setting).
- Zone (D13): a field, not a prop; 400 across × 200 tall, ceiling spot 700 × 100; moves every 90 s, 15 s warning,
  never the same spot twice. Open zone is YELLOW (white vanished against the city). First pass sizes were 2-3×
  too small to read across the room: judge world effects from a far camera, not up close.
- Paper targets are server-checked (CombatService tests each shooter's own signs on the shot path), not
  client-reported as Alan first suggested: same look for him, cheat-proof. 2 points each, 10 signs = prop cap 20.
- "Mode: …" button is Studio-only; mid-round it calls `engine:_close` so the next round starts in that mode.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (plain English, look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md.

## CARRY NOTES / GOTCHAS
- Claude Code's auto-mode check blocks Open Cloud uploads from Claude and blocked joining a match once; Alan runs
  uploads. Open Cloud can stay "processing" > 40 s: the uploader now moves on; poll the saved operation JSON.
- The city street map sits above the floor and is not raycastable: ControlZone lifts ground strokes to y ≥ 2.
- Screen captures time out when Studio is behind other windows (memory studio-not-drawing); DevCamera/DevView
  attributes on the local player give a photo camera without steering the plane.
- Paper target signs are 12 × 14 studs; some art is not that shape (vacuum tall, spider wide) — slight stretch.
- Two target spots share a roof ((650,224,150) and (650,224,300)); fine as a first pass, move if Alan wants.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: 936e6a36 HUD concepts · 5ebb18d0 HUD pieces · 3703a36a two-sheet note, slips, pins · 0aaf943f on-brand
  HUD · 37e5a049 / fe678853 / de23d988 / 9a579dc8 news note fixes · 463c4539 STATE Stage 6 approved · 3ff586fe
  MILESTONES D13 · 2953e15f team scores in colours · 30feb539 Stage 9 concepts · bf455995 moving zone + paper
  targets · 412a4387 test-mode button + target art ids · 3dd99bff STATE.
- Queued: Track C saving (needs private publish); bot-vs-bot rams never land; last stand-in sounds; full tutorial
  (last, D12); HUD photographed at 1918×1080 by Claude (Alan has played it at his size).

## POINTERS
- src/client/ControlZone.luau, src/client/PaperTargets.luau, src/client/FlightHUD.luau (capture bar, zone arrow),
  src/server/MatchService.luau (_zone, zoneHolder), src/shared/MatchRules.luau (zoneAt), src/server/CombatService.luau
  (paper targets), config/gameplay.json (rounds.control_zones, world.paper_targets), assets/references/mode-concepts/.
