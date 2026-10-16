# HANDOFF — 2026-10-14 — playtest fixes, points system and escape design done; build the escapes next

★ START HERE: Goal: finish Stage 9 so Alan approves it. Opening action: build the approved escapes (MILESTONES D14), starting
with the dropped chalk eraser and its cloud, then the drop ceiling + HVAC ducts. Done when Alan plays them and approves Stage 9.

> Read on demand: AGENTS.md → THIS → state/STATE.md → docs/MILESTONES.md row D14 (the escape design, Alan's words) →
> concepts in assets/references/mode-concepts/ (hvac-vents.png, hvac-ducts.png, chalk-eraser.png).
> Memories: codex-steals-studio-link, studio-play-is-shared, studio-test-copy, no-quality-cuts-for-fps, creator-store-first.

## STATE (verify before acting)
- HEAD `b4cab829` on main, local only (never pushed). Confirm: `git log --oneline -3`.
- Tests 283/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio WORKING open in Edit, Rojo syncing. Place NOT re-saved (Alan's Ctrl+S).
- Studio MCP: this session's link died (see GOTCHAS). A new session gets a fresh link; check with list_roblox_studios first.
- Codex's own Studio access is now OFF (`enabled = false` under [mcp_servers.Roblox_Studio] in ~/.codex/config.toml).
- Cost this session: 2 codex-rescue agents (scoring: ~56k subagent tokens + 12 min Codex; pictures: hung 37 min at
  "starting", killed), 1 direct `codex exec` (3 pictures, 68k Codex tokens). Primary context ~45% at handoff. No uploads, no spend.

## NEXT ACTION + PLAN
1. Chalk eraser easter egg (D14): an oversized felt chalkboard eraser lying askew on the floor near the city middle (Creator
   Store first, else Codex Blender); shoot it → chalk cloud ~250 studs, 20 s, hides planes, name tags and lock-ons inside;
   back after 3 min. Check: in Play, shoot it, cloud appears, a plane inside loses its name tag/lock; 60 FPS.
2. HVAC (D14): drop ceiling stays at y=620; a ~120-stud plenum above it; ducts = big loop round the room + a cross through
   the middle, ~6 square vents in the ceiling (open grilles), 10-15 s to cross; inside dim with light through floor slots,
   2-3 spinning fans you time through (clip = ~40% damage + knock), main blower at the middle junction (wind push), one
   narrow branch heavy planes can't fit. Room bounds, camera, bots' bounds check (`flight.boundsSize`) must allow the plenum.
   Check: fly in a vent, out another, in Play; camera never clips outside; FPS 60.
3. Veteran bots only use the ducts (to escape a chaser); others avoid them.
4. Then the unseen Stage 9 checks: a paper target hit, a full TDM match, the mode vote screen, bots in every mode.
5. Stage 9 "what to try" list in STATE.md → Alan's approval.
HOLDS (Alan's go each): uploads to his Roblox account (he runs them), private publish, Studio-settings changes, Meshy
spend, anything paid, desktop control (only if truly necessary), closing Studio. Don't steer his plane while he plays.

## DECISIONS & WHY (this session)
- Ceiling zone moved to (425,480,0) r475, 340-620 up: over the east ceiling obstacles Alan circled, under the rings.
- Bots play the zone by skill (objective_drive 30/60/85%); read "noobs should be as good" as "should NOT" (in STATE).
- Boost drives along the nose even with no Lift; server climb check allows it (0.6 s grace after boosting).
- Points (GAME_SPEC "Personal points"): fold 100, assist by damage share 10-80, Airspace zone 20/5 s and outside-zone folds
  40%, streak/revenge +25, first fold +100, targets 50. Paper/XP per point 0.363/0.68 so a reference match pays the same.
- Escapes: open-air obstacles rejected by Alan ("they just fly around them"); ducts + chalk cloud chosen; no points for escaping.
- Eraser lies on the floor near the middle (Alan), not on the chalkboard tray.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md rules (model router, one writer per file, Codex changes reviewed + tested before commit). Memories listed above.

## CARRY NOTES / GOTCHAS
- Never stop this session's own Studio MCP proxy (python studio_mcp_proxy.py): the app keeps showing "connected" with 0
  tools and no Reconnect button; only a new session fixes it. If the ChatGPT app's codex.exe still spawns StudioMCP.exe
  links (it may until restarted), stop only those (parent codex.exe).
- Codex picture jobs hung via the plugin; `codex exec -s workspace-write -c mcp_servers.Roblox_Studio.enabled=false - < prompt.txt` works.
- Toilet Roll body jitter: not reproduced on autopilot (motion, model pieces, bank/pitch, lift-out all steady). Wait for
  Alan to say when it happens (plane vs whole view; turning/climbing/out of Lift/straight).
- Real "+N" pop-ups for a human not yet seen in a real match (bots scored fine; test events rendered; RoundRuntime tests cover the send).
- A pilot with no position sample counts as outside the zone for the 40% rule (in STATE "Decisions to review").

## WHAT SHIPPED / OTHER QUEUED
- 891c22df ceiling zone, bots by skill, targets +20%, green zone-moved arrow · 9da82bda STATE · f08211a3 boost without Lift +
  "mode: ceiling" button · 40cab604 STATE · 853d98b6 crash ball bounces 3x, no clipping · 5732b3dd points rules in spec ·
  54c35762 score pop-ups · 96e5a447 new points (Codex, reviewed) · fa230bf7 STATE · 0448570d escapes workshop ·
  904189a6 concept pictures · b4cab829 concepts approved · this handoff commit.
- Queued: Stage 9 approval; then whatever MILESTONES lists after Stage 9 (gated on Alan).

## POINTERS
- Points: docs/GAME_SPEC.md "Personal points"; src/server/MatchService.luau (consumeCombat, _activeInterval, propContribution);
  src/client/ScorePopups.luau. Zone: config/gameplay.json rounds.control_zones; src/client/ControlZone.luau; BotService objectiveZone.
- Escapes: docs/MILESTONES.md D14 + the three concept PNGs.
