# HANDOFF — 2026-10-15 — chalk eraser done and approved in play; build the HVAC ducts next

★ START HERE: Goal: finish Stage 9 so Alan approves it. Opening action: build the drop-ceiling HVAC ducts (D14, see
docs/systems/escapes.md). Done when Alan can fly up into one ceiling vent, through the ducts and out of another in Play,
with the camera never leaving the duct and a steady frame rate; then fans, blower, narrow branch, veteran bots.

> Read on demand: AGENTS.md → THIS → state/STATE.md → docs/systems/escapes.md (ducts plan + eraser) →
> docs/decisions/2026-10-14-escapes-hvac-ducts.md → concepts assets/references/mode-concepts/hvac-vents.png, hvac-ducts.png.
> docs/workshop/lessons.md "Studio and the place file" (new lessons from this session).

## STATE (verify before acting)
- HEAD `077e8631` + this handoff commit, on main, local only (never pushed). Confirm: `git log --oneline -3`.
- Tests 284/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio WORKING open in Edit, Rojo syncing. Place NOT re-saved by me: Alan's Ctrl+S keeps the new eraser (pivot fixed).
- Docs check runs on every commit (`.githooks/pre-commit` → `python tools/check_docs.py`); new code files must be
  named on a docs/systems page in the same commit.
- Cost this session: 2 `codex exec` jobs (model sheet picture; eraser Blender build ~171k Codex tokens, ~20 min), one
  killed Codex job (first brief used the artistic concept; Alan stopped it). No Claude subagents. No Meshy spend.
  Alan ran one upload (eraser FBX + 3 maps). Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. HVAC ducts geometry. Facts measured this session: room x ±1400, z ±1100; ceiling = 4 slabs 1400x8x1100 at y 620-628
   (`workspace.Arena.Ceiling`, in assets/models/classroom.rbxmx); plenum 628-748. Turning circle ~50-60 studs
   (base_turn x turn_rate_scale 0.7, speeds 69-146) → main ducts ~120 wide with angled corners; vents (holes through
   ceiling + duct floor) at junctions only; avoid the ceiling lights, planets and east ring obstacles under vents.
   Server bounds kill planes above y 632 (FlightService bounds check, `world.height_studs` 620): allow the plenum
   there only (bots read `boundsSize.Y` as their ceiling; keep that at 620). Camera pulls in against Arena parts
   (ChaseCamera spherecast), so ducts go inside `workspace.Arena`. Geometry as an asset file (never Luau geometry);
   a builder tool in tools/ reading config is fine (tools/schoolyard.lua is precedent).
   Check: fly vent → duct → other vent in Play; camera stays inside; frame rate steady (Alan judges FPS).
2. 2-3 spinning fans (clip ≈ 40% damage + knock; pure rule + unit tests = good Codex job), blower at the middle
   junction (reuse `world.fans` push), one narrow branch heavy planes can't fit.
3. Veteran bots only use the ducts; others avoid them.
4. Unseen Stage 9 checks: a paper target hit, a full TDM match, the mode vote screen, bots in every mode.
5. Stage 9 "what to try" in STATE.md → Alan's approval.
HOLDS (Alan's go each): uploads to his Roblox account (he runs them), private publish, Studio-settings changes, Meshy
spend, anything paid, desktop control, closing Studio. Don't steer his plane while he plays (check get_studio_state).

## DECISIONS & WHY (this session)
- Eraser rulings (Alan, 4 playtest rounds): docs/decisions/2026-10-15-chalk-eraser-rulings.md. Final: 580 across,
  45 s, full size half the time then shrinks with its safe zone, fog inside (~380 studs), blocks targeting/outlines/
  tags like a building, 2 min cooldown, chalk on the black felt = ready.
- Models are built from a real model sheet (plain-background views), never from Codex's artistic concept pictures.
- Puffs launched with `:Emit()`, not emitter `Rate` (Rate is thinned when far away; cloud vanished from afar).
- Inside the cloud: Atmosphere set aside + classic fog (Atmosphere overrides FogEnd); particles cleared (frame rate).
- Bots can puff the eraser by accident (in STATE "Decisions to review").

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, one writer per file, Codex changes reviewed before commit, docs check-up each handoff).
- docs/workshop/lessons.md; memories: studio-play-is-shared, studio-not-drawing, codex-steals-studio-link, creator-store-first.

## CARRY NOTES / GOTCHAS
- `codex exec -s workspace-write -c mcp_servers.Roblox_Studio.enabled=false - < prompt.txt` works; commit Codex output first.
- Stopping a background `codex exec` shell leaves codex.exe running: stop the `exec -s workspace-write` process (not
  the ChatGPT app's `app-server`/`exec-server`).
- Commit with explicit pathspecs (`git commit -- paths`): another session (Obsidian docs) works in this repo too.
- Toilet Roll body jitter still unreproduced; wait for Alan's description.

## WHAT SHIPPED / OTHER QUEUED
- 7ffcad08 eraser easter egg · 78662138 cloud bigger/thicker · dc3896c2, 71aebf60, 2e22eaff STATE · 6c13995e eraser
  Blender model (Codex) · 4d74d893 new model swapped in · c6bb92b5 cloud at the eraser's real middle · 211e1e90 +30%,
  haze, 2 min, ready sign · 36597df9 fog, 30 s, shrinking · 1d9c02ab blocks like a building, 45 s, -20%, further fog ·
  077e8631 STATE · this handoff commit. (33fd2e46, 343e4e91, 968a6377, 34875c97, 4fa6bf43 are the docs session's.)
- Queued: ducts → Stage 9 checks → Stage 9 approval (gated on Alan).

## KNOWLEDGE UPDATED
- docs/systems/escapes.md: eraser current truth (45 s, shrink, fog, wall-like blocking, ready sign).
- docs/decisions/2026-10-15-chalk-eraser-rulings.md: all four playtest rounds.
- docs/playtests/2026-10-14.md: rounds 2-4, ✅ "it works now".
- docs/workshop/lessons.md: Arena-only props, mesh PivotOffset, Emit vs Rate, MCP testing traps.
- docs/art/models.md: eraser model line. Checker: OK.

## POINTERS
- Eraser code: src/client/ChalkCloud.luau, src/shared/CombatRules.luau (chalkRadius, chalkBlocks),
  src/server/CombatService.luau (chalkHit, visible), src/client/FlightHUD.luau (seen, outlines).
- Eraser art: assets/models/toys/chalk-eraser/ (model-sheet.png, compare.png, upload.json, chalk-eraser.rbxmx).
