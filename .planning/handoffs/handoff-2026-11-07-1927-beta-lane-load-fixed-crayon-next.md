# HANDOFF — 2026-11-07 — Phone loading fixed (town ~4 s); Stubby Crayon next

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=tools/town_toys.py, tools/save_place.py, docs/systems
**Time:** 2026-11-07 19:27 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. Build the Stubby Crayon (rules + tests first, stand-in model): done when its tests pass in Play (muted) and Alan has tried it. Then the Spitball plan for his OK.

> Read on demand: AGENTS.md → this file → the previous handoff `.planning/handoffs/handoff-2026-11-07-beta-lane-popper-thumbtack-solid-toys.md` (weapon plan, decisions, gotchas) and docs/decisions/2026-11-07-four-new-weapons-and-falling-shots.md. Memories: weapons-need-no-explaining, mute-studio-tests.

## STATE (verify before acting)
- HEAD `79178c8d` (main), pushed. Confirm: `git rev-parse --short HEAD`.
- Tests 467/0 in Play at `3948b949`; everything since is build tools, docs and place-only collision. Re-run muted (lessons.md: background run + poll).
- Published v495 by Alan (includes all of today). Alan did Save to File after the box/fitted-block change.
- Phone joins v495: town arrived 3.8 s / 4.3 s (v493 was 38-41 s). Read joins: Play, Server VM, `require(game.ServerScriptService.FlyFightPaper.LoadLog).recent()`.
- Cost: no subagents; main Opus session only; context about 52% at handoff.

## NEXT ACTION + PLAN
1. Stubby Crayon (level 6): medium, capacity 3, 40 damage, 2 s reload, one shot per click, ~850 studs/s heavy shot, falls past ~600 studs; stand-in via `Aircraft.STAND_IN` (pencil). Add catalog row, commerce `part_` row, Catalog.spec weapon count, kill lines, colour, sound, dev picker button, tests.
2. Spitball: write a plan for Alan's OK first (sticking blobs, Lift burn, decay, fan and desk removal, visible on the plane).
3. Real models for all four (Codex picture → Codex Blender; no Meshy; Alan sees them assembled before upload). Then CLASSES-PLAN steps 4-5.
- HOLDS: publish (Alan), Save to File, any upload, desktop control, Studio Play while Alan plays (check `get_studio_state`), a bot match, anything paid.

## DECISIONS & WHY (since the previous handoff)
- Exact collision shapes cost phone load time: each part stores its own, so 510 copied toys added ~30 s. Small rug toys collide as plain boxes (`ALSO_SOLID`, no data); lamps and the crane by invisible fitted blocks (`SHAPED` in tools/town_toys.py) so flying under a lamp head or the crane arm is clear (Alan: "tight, not a straight box").
- Nothing outside the room is solid (planes can't get there). Alan's own HorseDragoon, meme toy, ungroup pibble: no collision, his call.
- save_place.py leaves `ALSO_SOLID` toys as boxes on rebuild.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above plus studio-play-is-shared, exact-collision-baked.

## CARRY NOTES / GOTCHAS
- A second phone join can wait ~25 s on Roblox's own town-picture download (cache miss); Skip works meanwhile. Not our code.
- After any change to the town, read `LoadLog.recent()` after Alan's phone join (lessons.md).

## WHAT SHIPPED
- e47ee254 Small solid toys collide as plain boxes: exact shapes slowed phone loading
- 52e3f4ca Nothing outside the room is solid
- 7ca37928 Lamps and the crane collide by fitted blocks, not one big box
- 79178c8d Phone load measured: town in about 4 s again on v495

## KNOWLEDGE UPDATED
- docs/systems/damage-and-deaths.md (what planes hit, boxes, fitted blocks), performance.md (v495 phone numbers), workshop/lessons.md (exact shapes cost load time). Checker: docs OK.

## POINTERS
- tools/town_toys.py (`ALSO_SOLID`, `SHAPED`, `part`), tools/save_place.py (`exact_shapes`), src/server/LoadLog.luau.
