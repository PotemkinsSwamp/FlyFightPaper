# HANDOFF — 2026-10-13 — Takeoff, crashes, glide, paper deaths, moving guns, gun fit done; plane colours next

★ START HERE: Goal: finish Stage 8 (planes) so Alan can sign it off. Next: **plane colours that stand out from the
classroom** (MILESTONES Stage 8: every part reads at a glance against the room). Done when Play screenshots at
1280×720+ of planes over the city, the desks and the walls show them clearly apart from the room, and Alan agrees.
Screenshots need Studio drawing (front window): if Studio is behind other windows, ask Alan to bring it forward (or
for his OK on desktop control) first.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: studio-play-is-shared, studio-not-drawing,
> no-surprise-desktop-control, creator-store-first, look-at-textures-before-upload.

## STATE (verify before acting)
- HEAD `3caaf3b8` + this handoff's commit, main, not pushed (never pushed this project). `git rev-parse --short HEAD`.
- Tests 257/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Rojo-synced (Alan connected it this session); place file not rebuilt (code only).
  Edit has no leftover test parts (ClipCheck/ExactTmp/ClipWorld/PaperBallCandidate removed).
- Cost: 0 Codex, 0 sub-agents, 0 Meshy, 0 uploads; primary ~45% context.

## NEXT ACTION + PLAN
1. Plane colours (Stage 8). Today: `Aircraft.paint` sets accent pieces red/blue by team, stickers by team; bodies are
   paper-white/cream, close to the room's cream walls and desks. Pick colours from the reference image's palette that
   contrast with the room (desks, rug, walls), keep team red/blue readable, check in Play screenshots.
2. Stage 8 leftovers in MILESTONES (collider matches fitted parts; hangar presentation items) — check which are
   already met before doing work.
3. Then Stage 7 sounds/effects → Stage 6 first 60 seconds → Stage 9 modes (Alan's order, D10).
- HOLDS (Alan's go, each): private publish (Track C saving waits on it); Studio-settings changes; Meshy spend;
  anything paid; desktop control (only if truly necessary or he asks). Ask before closing Studio; don't drive the
  human plane while Alan is in Play.

## DECISIONS & WHY (this session)
- Takeoff: physics carries the plane (server-owned LinearVelocity tracking the path), not anchored tweens: tweens
  reached the player at half the frame rate (juddered). Lift-off 60 out, straight climb through the ring centre,
  control 25 past it. Planes can't be hurt during TAKEOFF.
- Room-edge "turning you back" aim nudge deleted (Alan: walls/roof repelled like a magnet). Wall/ceiling crashes
  ignore the 3 s launch protection (it still blocks shots and rams).
- Crash threshold into-speed 35 → 12 (Alan: crashes must be instant). Pilot's client predicts its own crash and
  crumples at once (PlaneDeaths.predict); un-hides if the server disagrees within 1.2 s.
- Empty-Lift glide = momentum (glide gravity 60, dive up to 1.5× cruise; hard turns slow you only while turning).
  Server check: never higher than speed-at-empty could buy, minus 6 studs/s, counted from the moment Lift ran out
  (per-check speed readings jittered and wrongly corrected pull-ups).
- Paper ball = 7 turned cubes made in code: the free store "paper ball" (130571371556211) was exactly that plus a
  suspect LightConfig script; deleted unrun.
- Weapon motion: welded original hidden on the client, a local copy drawn moved (no weld edits); shot events now
  carry `slot`.
- Gun fit measured on real triangles (EditableMesh), not convex hulls (hulls said 0.91 where the truth was 0.10).
  Only fixes: paperclip −0.5 at body slots; neighbouring guns shrink to keep a 0.1 gap (heavy-body erasers). Pellet
  tubes through the wing root kept (plane A's design). Shrunk guns' muzzles stay at full-size spots (ponytail note).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Not seen as pictures yet (Studio wasn't drawing): guns firing (drum spin, lever, band) and a real in-flight
  crumple; numbers say they work. Alan's "Watch" item 2 in STATE covers it.
- Studio behind other windows: captures time out, RenderStepped = 0/s (memory studio-not-drawing).
- MCP client attribute switches on the Player don't reach the server; hold test values from a Server call.
- Bell-tower re-export files + closeups.png in the working tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- 080fda60 Automatic takeoff down the runway and through the hoop; walls and ceiling crash you (no more push-back)
- 5db63cc3 STATE: takeoff, wall crashes, Alan's backlog
- 17f08502 Out of Lift the plane glides on momentum: dive for speed, zoom back up
- 72625280 Planes die as paper (crumple into a ball, or tear apart), crashes are instant, weapons move when they fire
- 3caaf3b8 Guns never clip: paperclip hangs clear of the wing root, crowded erasers shrink to fit
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams never land.

## POINTERS
- src/server/FlightService.luau (launch/takeoffStep/fly, impact, step checks), src/shared/ServiceRules.luau (takeoff),
  src/shared/FlightRules.luau (glide, climbAllowed), src/client/PlaneDeaths.luau, src/client/WeaponMotion.luau,
  src/shared/Aircraft.luau (paint, build, BODY_SLOT_DROP, neighbour shrink), config/gameplay.json (service, flight).
- Previous: `.planning/handoffs/handoff-2026-10-13-takeoff-next.md`.
