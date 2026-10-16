# HANDOFF — 2026-10-15 — ducts built as a dark maze; design pass next

★ START HERE: Goal: finish Stage 9 so Alan approves it. Opening action: the ducts' design pass (Alan, 2026-10-15):
make them look like real HVAC ducts (look at HVAC duct/fan/pipe references; metal textures on the walls, fans that
look mounted and real, the pipe as plain HVAC plumbing, not rusted) and add cobwebs, plastic toy spiders, lost toys and
tools. Done when Alan looks in Play and says it no longer looks boring/"really bad"; then veteran bots in the ducts.

> Read on demand: AGENTS.md → THIS → state/STATE.md → docs/systems/escapes.md →
> docs/decisions/2026-10-15-ducts-maze-rulings.md. docs/workshop/lessons.md "Studio and the place file" (3 new
> lessons). Memories: creator-store-first, look-at-textures-before-upload, studio-play-is-shared, no-surprise-desktop-control.

## STATE (verify before acting)
- HEAD `4e9c8be3` + this handoff commit, on main, local only (never pushed). Confirm: `git log --oneline -3`.
- Tests 291/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio WORKING open in Edit, Rojo syncing code. The current ducts were loaded into Edit by a script (not saved):
  the place file still has the old 4-slab ceiling unless Alan pressed Ctrl+S. `save_place.py` builds them from
  `default.project.json` (Arena.Ducts = `assets/models/ducts.model.json`; classroom.rbxmx has no ceiling now).
- Reload ducts into Edit after `python tools/ducts.py`: scratchpad loader is gone with the session; rebuild one
  (decode the model.json with HttpService:JSONDecode, make parts, replace `workspace.Arena.Ducts`; it handled
  CFrame rows, Size, Color, Material, Shape, Face, attributes, children) or rebuild the place.
- Cost this session: no subagents, no Codex, no Meshy, no uploads. Primary context ~45% at handoff.

## NEXT ACTION + PLAN
1. Design pass (above). Creator Store first for HVAC pieces, cobwebs, spiders, toys, tools (read any scripts); built-in
   materials/MaterialVariants before new textures; any upload = Alan runs it, after a contact-sheet look at the
   pictures (moderation). Keep fan geometry matching the rule: blades within `reach` 58 of the hub, round housing
   `opening` 120, plate on the air's upstream side. Check: Play screenshots inside a duct, at a fan, the pipe mouth,
   a vent from below; Alan's look.
2. Veteran bots use the ducts; others never. Draft planner was set aside (in-session only, gone): plan = graph from
   `world.ducts.rooms/links`, skip fan links and the pipe; enter only where 400 studs of open room lie behind the vent
   along the first duct; dive out of the exit room then turn back into the room; skip the "above 540 push down" and
   wall pushes while in the duct; needs Lift > ~50% (Lift drains; 45-125 s full).
3. Unseen Stage 9 checks: a paper target hit, a full TDM match, the mode vote screen, bots in every mode.
4. Stage 9 "what to try" in STATE → Alan's approval (his gate; never mark it done).
HOLDS (Alan's go each): uploads (he runs them), private publish, Studio-settings changes, Meshy spend, anything paid,
desktop control, closing Studio. Don't steer his plane while he plays (check get_studio_state first).

## DECISIONS & WHY (this session)
- Alan's duct rulings: docs/decisions/2026-10-15-ducts-maze-rulings.md (maze, 4 irregular vents, round pipe the whole
  way, dark with light from below, fans blow air, faster/harsher fans then slightly slower, gentler headwind).
- Light from below read as: grilles only where ducts pass over the classroom's ceiling lights (in STATE "Decisions to
  review"; Alan didn't answer the question).
- No duct part casts shadows (the old ceiling didn't; roof shadows would stripe the room below), so the inside is dark
  by dark colours, not shadow.
- Pipe 25 across: heavy gunship is 26.1 wide; widest other body 18.5. Brushing = scrape, hitting at >12 studs/s = crash.
- Fan clip and wind are judged on the server from shared pure rules (`src/shared/DuctRules.luau`); the client spins
  blades from server time so they match.
- Test autopilot routes `duct`, `pipe`, `fan` (DevAutopilot) follow the rooms; its dives often came down a few studs
  short of a hole — the route's waypoints, not the vents.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, Creator Store first, one writer per file, docs check-up each handoff, hard limits).
- Commit with explicit pathspecs (another session works in this repo).

## CARRY NOTES / GOTCHAS
- A hanging decoration under vent J's south side (Model/Part ~(1050,438,-400)) is in the climb path from the south.
- Long duct trips can run out of Lift; the plane then sinks to the duct floor (normal rule).
- Toilet Roll body jitter still unreproduced; wait for Alan's description.

## WHAT SHIPPED / OTHER QUEUED
- 9ff766c0 Ceiling ducts: vents, loop and cross · a5efa0d5 fans, blower, narrow branch · 64e59b96 fans spin again
  (angle wrap) · 7ab93bf0 rebuilt as a dark maze · 905dcf26 fans 1 turn/s, 75% · 4e9c8be3 slower, round housing,
  gentler headwind · this handoff commit.
- Queued: design pass → veteran bots → Stage 9 checks → Stage 9 approval (gated on Alan).

## KNOWLEDGE UPDATED
- docs/systems/escapes.md: ducts current truth + Code table (DuctRules, FanSpin, FanWind, FlightController, FlightService, tools/ducts.py).
- docs/decisions/2026-10-15-ducts-maze-rulings.md (new) + README line.
- docs/world/classroom.md, docs/workshop/tools.md, docs/systems/performance.md: ducts model, builder, test routes.
- docs/workshop/lessons.md: server-time angles, one client module error stops the rest, Rojo model.json CFrame format.
- state/STATE.md rewritten top + duct playtest under Waiting on Alan. Checker: OK.

## POINTERS
- Code: tools/ducts.py, src/shared/DuctRules.luau, src/server/FlightService.luau (headroom, fanHit, wind),
  src/client/FanSpin.luau, FanWind.luau, DevTools.luau (routes). Config: config/gameplay.json `world.ducts`.
- Concepts: assets/references/mode-concepts/hvac-ducts.png, hvac-vents.png.
