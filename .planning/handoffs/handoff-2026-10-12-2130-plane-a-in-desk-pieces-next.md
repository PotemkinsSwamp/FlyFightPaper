# HANDOFF — 2026-10-12 — Plane A in the game; weapons drop-off, power-ups, fan wind done; desk pieces uploaded, not placed

★ START HERE: Goal: Alan approves plane A, the power-ups and the desk/landing look. First fix what Alan's playtest
found (section ALAN'S PLAYTEST NOTES below): power-ups that don't trigger, the bolt look (no bright neon), additive
speed stacking, and 3 missing bell-tower brick boxes. Ask whether he Ctrl+S'd; after his save, rebuild the place
(save_place.py) so plane A keeps its meshes. Then place the desk pieces. Done when Alan flies plane A off the new
runway through the new ring, stacks bolts, and approves.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: roblox-mesh-import-gotchas, look-at-textures-before-upload,
> exact-collision-baked, commit-codex-output-first, codex-for-pictures-and-blender, texture-packs-after-new-models.

## STATE (verify before acting)
- HEAD `500b9e12` (main), never pushed. `git rev-parse --short HEAD`.
- Tests 254/0 (Play server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open (studio_id 61964466-…), last saved by Alan 19:42 (committed 736c5818). Live, UNSAVED in Studio:
  AircraftPieces meshes swapped in by hand (CreateMeshPartAsync), Tailwind deleted, Updraft boxes hidden (last two are
  also in classroom.rbxmx). Rojo serving on 34872 (`C:/Users/gutie/AppData/Local/Rojo/bin/rojo.exe serve serve.project.json`).
- Cost this session: Codex ×6 (Sol: world concepts, plane part sheets, launcher+body redo, desk models; ~20-30k tokens
  each in the relay), Sonnet ×2 (ballistics ~120k, plane assembly ~100k), ~35 free uploads, 0 Meshy, ~3 h; primary ~50%.

## NEXT ACTION + PLAN
1. Ask Alan the two questions above + playtest feel (shot ranges/drop, stapler + paperclip sound, power-ups, swirls).
2. After his Ctrl+S: save_place rebuild, reopen, check plane A pieces render (then `town_toys.py packs` + build if
   packs changed). Check = screenshot of plane A on its pad in Play, red and blue.
3. Place desk pieces (all uploaded + approved; records in `assets/models/toys/<name>/upload.json`; read MeshIds in
   Studio with `town_toys.py readlua`/`meshes`): desk-runway-droop replaces PadSouth/North* + RunwayTape on all 12
   desks and the 4 neutral slots (runway along the landing line; fallback desk-runway-straight); landing-ring replaces
   the 12 `Landing*Segment` parts per ring (spin slowly about its axis); runway-light + glowing tip blink in sequence
   toward the runway; speed-bolt replaces the placeholder token in `src/client/SpeedPickups.luau`. Note: hangar is 110
   wide, pad 100 (5 studs overhang each side; fine or widen). Check = Alan's look at 1280x720 shots of a desk.
4. Other 23 plane parts + 6 weapons + 3 boosters from `assets/models/planes/concepts/parts/` (bodies.png redone:
   clear slim/standard/heavy). Weapons have NO concept sheet (image tool refuses): Blender from written specs.
   Each new part = pieces in pieces.rbxmx via `tools/art/plane_pieces.py` (generalise it beyond plane A).
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.

## DECISIONS & WHY (this session)
- Ballistics: exponential drag (speed falls linearly per stud) + gravity drop, closed form in CombatRules
  (`shotDistance/travelTime/shotOffset`); lifetime = time to reach range at 55% speed (pencil 70%). Leads aim above by drop.
- Power-ups (+25%/5 s/1 s respawn) at 7 ceiling rings, 3 tubes, bell-tower arch, gateway arch (paper chains are
  garlands, not loops); multiplied into BoostSpeedFactor so client, bots and the speed check all see it. Side fan removed.
- team:1 = RED squares, team:2 = BLUE circles (matches the score card); FFA red accent + white stickers. In STATE review.
- Pad: Alan wants the overhang to flop limply over the desk edge; keep the straight variant as his fallback.
- Fan wind sprites drawn in code (`tools/art/wind_sprites.py`), not generated: nothing for moderation to misread.
- Bookshelf grey = Studio refused the old picture ids (approved, loadable) → fresh uploads; bricks grey = 12 paints piled
  on one brick in the saved place (cause unknown; checker found no other toy affected).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Uploaded FBX import 180° turned; `rojo serve` can't set MeshId (memory roblox-mesh-import-gotchas).
- Codex image tool refuses weapon sheets ("illicit"): don't retry.
- Studio MCP camera in Play: use the `DevCamera` attribute (CFrame); a RenderStepped loop from execute_luau doesn't stick.
- Uncommitted bell-tower re-export files (10:30-11:00 today) + closeups.png still in the working tree: not ours, leave.
- Sticker placeholders have a ~0.9° baked tilt; team stickers use the placeholder CFrame (check they don't sink in).
- FlightService colliders include hidden placeholder stickers; team stickers get none (wing-flat, untested).

## WHAT SHIPPED / OTHER QUEUED
- c11b9349 Bookshelves painted again; brick stacks fixed live · 736c5818 Alan's save 19:42 + packs
- 2b9884e9 Shots slow down and drop; paperclip/staple speed, reload, sounds; speed power-ups replace the side fan
- 1dda4a2a World-piece concepts · 8b205842 Plane part concept sheets · 0e2510a6 Fan wind swirls
- 72f5faf3 Body sheet redone; plane A pieces uploaded · e2a00c7f STATE · c5bc8c30 Plane A in the game
- 85d3536f Desk pieces modelled (Codex) · 114054f6 Desk pieces uploaded · 500b9e12 STATE
- Queued: menu stage gaps (tutorial practice area, shop outside Studio); Track C saving (needs private publish).

## POINTERS
- Briefs: `.planning/briefs/2026-10-12-*.md` (shot-ballistics, plane-a-assembly, desk-pieces-models, concepts).
- Code: `src/shared/Aircraft.luau`, `src/shared/CombatRules.luau`, `src/server/FlightService.luau` (pickups),
  `src/client/SpeedPickups.luau`, `src/client/FanWind.luau`, `tools/art/plane_pieces.py`, `tools/art/toys.py`.
- Art: `assets/references/world-pieces/`, `assets/models/planes/concepts/parts/`, `assets/models/planes/uploads.json`.
- Previous: `.planning/handoffs/handoff-2026-10-12-1920-tower-done-planes-next.md`.

## ALAN'S PLAYTEST NOTES (2026-10-12 ~21:45, after this handoff was first written)
- Not all power-ups work: in some loops they do nothing. Check every one of the 12 spots in Play (fly the line through
  each, read PickupUntil); suspects: spot off the hole's real centre/height, radius 26 vs plane path, or the bonus too
  small to notice. Fix by measuring each hole, not by widening blindly.
- Bolt look: the placeholder reads as two triangles and is too bright. Use the uploaded Codex `speed-bolt` model
  (assets/models/toys/speed-bolt, a real zigzag) or a free Creator Store bolt; paper yellow, no Neon.
- Stacking (Alan's rule): each bolt ADDS speed (additive, e.g. +25% per bolt) and resets the 5 s timer; the time does
  not add up. Hit them all = a lot faster. Pick a sane cap and note it in STATE 'Decisions to review'. The server speed
  check (`movementAllowed` in FlightService) must use the stacked factor.
- Spots Alan expects (verify they exist and show): one under the bell tower, about halfway between the arch's
  underside and the fountain (today (0,100,0)); one in the arch building (gateway towers, today (-630,86,-412)).
- Bell tower: on 3 of the 4 corners the red-and-blue brick box under the belfry didn't render (his screenshot shows
  only one). Lead: 3 MeshParts named `bell-tower/32-upper-bricks-back-left` sit at the Workspace ROOT (not in
  Arena.CityToys), at (37,328,38), (38,328,-37), (-37,328,-38): left over from his hand arrangement; likely missing
  paint/pack or streamed oddly, and NOT in toy-placements.json, so a save_place rebuild would drop them. Move them
  into CityToys (or re-stand from placements with the right piece names), `pull`, rebuild, check all 4 corners.
- Weapons sheet: Alan asks whether better wording gets the image tool to draw them (they're paper toys). Worth ONE
  cheap try that names only the objects and materials (straw, binder clip, craft stick, clothespin, cardboard tube,
  eraser box; no fire/launch/shoot/weapon/projectile/rocket words), one item per image. If refused, Blender from specs.