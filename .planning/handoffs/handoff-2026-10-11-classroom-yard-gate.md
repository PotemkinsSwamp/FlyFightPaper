# HANDOFF — 2026-10-11 — Gate passed; models fixed; classroom + schoolyard in; 11 new models and 10 pictures ready to place

★ START HERE: Goal: make the classroom match `assets/references/classroom-city-approved-v1.png` and fill every missing
model. Opening action: place the 11 uploaded toys and the 10 pictures (door, floor fans over the two updraft vents,
desk hangar + taped runway on each desk pad, cubby shelf, bulletin board with bulletin-papers, posters on the walls,
alphabet banner over the chalkboard, chalk art on the chalkboard, kids' world map replacing the photo map, six
playground pieces tidied into Alan's half-size playground). Done when each is seen in Studio and shown to Alan.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: no-quality-cuts-for-fps, codex-for-pictures-and-blender,
> touch-up-before-showing, studio-test-copy.

## STATE (verify before acting)
- HEAD `3b68b1fc` (main), local only (no upstream). Confirm: `git rev-parse --short HEAD`.
- Tests: not re-run (no rules logic changed); last 220/0.
- Studio: WORKING open in Edit, Rojo serving serve.project.json (code only). Live Studio matches the repo files
  (decor, yard, toys) EXCEPT: Banner Tower still old; the 11 new toys not yet placed. Alan has NOT Ctrl+S'd.
- Studio 3D view freezes unless it has focus (and when the monitor sleeps). Ask Alan to click inside the 3D view,
  then shoot with `bash tools/studio_shot.sh NAME x,y,z lx,ly,lz` (refuses unless Studio is the top window).
- Cost: ~10 Codex jobs (Sol, Alan's ChatGPT plan) via codex-rescue forwarders (~20–45k Claude tokens each); no
  Meshy; ~11 h wall clock; primary context ~75%.

## NEXT ACTION + PLAN
1. Upload records exist for all 11 toys; read their MeshId/size in Studio (LoadAsset Luau as done for the desks:
   `studs` = checks.json size_xyz reordered to [x, z, y]), add placement rows, place live
   (`tools/toy_place_lua.py`), `town_toys.py build`, commit.
   - Facing: Blender front -Y shows up as Roblox -Z at identity rotation (verified on desks/chairs).
   - Desk hangar: behind each pad on the pupil side; runway = thin non-colliding tape parts from the desk edge to the
     pad (approach comes from the room side). Never change desk/pad/landing geometry.
   - Floor fans replace FanBase/FanVent visuals only (hide them; Updraft zones stay).
2. Pictures: upload `assets/textures/classroom/*.png` with tools/upload_texture.py, put Decals on thin framed parts
   (or the bulletin board), add to `tools/classroom_trim.lua`-style script, re-export ClassroomDecor with
   tools/studio_export.lua. Replace WorldMap (photo) with world-map-kids.
3. Banner Tower: `_rebake/banner-tower` is done (roof slots closed). Copy over the original, `town_toys.py hero`,
   readlua/meshes, `stand assets/models/banner-tower -124 401 -1.57079633`, placelua, build. Check its flag height
   (raycast; Garden's flag was buried 29 studs).
4. Show Alan: Gateway, Crayon Box, Garden, Banner close-ups in Studio + the classroom + playground. One fix round each.
5. Then: missing-model sweep remainder (bookshelves of plain parts, ceiling lights, see-through wind boxes),
   90 unpacked texture sets (`town_toys.py packs`), final 8-viewpoint pass for Alan's Stage 4 sign-off.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.
- Stop rule: a piece is done when it is seen in Studio and Alan has seen it.

## DECISIONS & WHY (this session)
- ★ Vertical-slice gate PASSED (Alan: "the bots pass, it is fun"). Art first by his choice; Stages 6–9 now allowed.
- Desks keep gameplay size (330x210, top 108): old box desks stay as invisible landing surfaces; mesh desks have legs
  you can fly under. Chairs/bases non-solid boxes hidden.
- Schoolyard at kid scale 1 ft = 50 studs (Alan: "think about the scale of the players"); ground level = classroom
  floor; full 60x40 ft court; chalk games drawn ON the court (Alan); playground cut to half by Alan in Studio, sand
  volleyball in the other half (Alan's idea). Builder: tools/schoolyard.lua → assets/models/schoolyard.rbxm.
- Anything outside `Arena` is deleted by Bootstrap, so decor/yard live under Arena as rbxm files in default.project.json.
- 9 free store models had hidden backdoor scripts (TextureConfig/CoreSystem/Package ~9–14k chars): deleted unrun. All
  kept store models had every script stripped. Prefer Codex Blender models over store models.
- "Hangar" = the desk launch pads (Alan, asked).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits), CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Screen grabs read Alan's real screen: only via tools/studio_shot.sh (Studio-on-top check skips cloaked windows).
  One grab caught his browser this session; deleted at once.
- Execute_luau results cap at ~100k chars: export in chunks (tools/studio_export.lua).
- Model:GetBoundingBox() is oriented to the primary part: seat wall pieces by part corners (see toWall in classroom
  decor history) — store models came rotated ~34°.
- Codex's playground job (task-mv3cdthv-s7kht5) never sent its final report; its six toys passed checks.json and look
  right in renders.
- Gateway: tiny dark notches at ruler joins remain; Crayon: some uneven studs; Banner: small dark patches at joins.

## WHAT SHIPPED / OTHER QUEUED
- 38c500cd classroom toys + flags + roof views · 610ca669 classroom desks/decor · d37ce71b tree line · f0639da4 yard
  toys · 3a22b516 schoolyard · cd194efc STATE · 23a18d44 real-size yard · b87c862d kid scale · 2a2ab31f yard file ·
  f95f1b1b half playground + volleyball · f7534c45 Gateway + Crayon re-baked · 2c570653 Garden re-baked · 7497b30d gate
  passed + briefs · 23bf6da0 wall trim + planet skins · 79f26c32 pictures + 11 toys · 6ad1ae1e STATE · 32d7bd01 upload
  records · 3b68b1fc Studio helpers.
- Queued: plan items 1–5; Codex Track C saving untouched.

## POINTERS
- Briefs: .planning/briefs/2026-10-11-{classroom-models,classroom-pictures,playground-more,schoolyard-toys}.md,
  2026-10-10-rebake-three.md; Codex report assets/models/_rebake/rebake-report.json.
- tools/schoolyard.lua, tools/classroom_trim.lua, tools/town_toys.py, tools/art/toys.py, tools/art/closeups.py.
