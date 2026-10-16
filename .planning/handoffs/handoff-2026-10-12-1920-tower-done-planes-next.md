# HANDOFF — 2026-10-12 — Bell tower finished and saved; combat reworked; starter plane A approved, assembly code next

★ START HERE: Goal: get the approved starter plane (concept A, round-2 Blender model) flying in the game. First,
ask Alan how the grey bricks/bookshelves and the weapon changes looked on his last Play (he hadn't played since the
save). Then: upload plane A's meshes (look at every render first; no texture images exist), change
`src/shared/Aircraft.luau` to assemble multi-mesh parts (paper/accent/sticker, team colour + red square / blue circle
stickers at the spots in `assets/models/planes/stickers/stickers.json`, plain white in FFA) and the new gun mounts.
Done when Alan flies plane A in Studio and approves it.

> Read on demand: AGENTS.md → state/STATE.md → THIS. Memories: look-at-textures-before-upload,
> measure-concept-before-brief, commit-codex-output-first, creator-store-first, exact-collision-baked.

## STATE (verify before acting)
- HEAD `3b776ca5` (main), never pushed. `git rev-parse --short HEAD`.
- Tests 250/0 (after combat rework). Re-run in a Play server: `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open as "FlyFightPaper-WORKING_AutoRecovery_0" window (studio_id 61964466-…), saved by Alan 19:14 →
  committed. Rojo: `C:/Users/gutie/AppData/Local/Rojo/bin/rojo.exe serve serve.project.json` (not on PATH), port 34872.
- Roblox account: ban lifted (appeal accepted). Texture packs harvested: 1,353/1,360 painted toys packed.
- Cost this session: ~10 Codex jobs (Sol: weapons ×2, plane concepts, plane A ×2, clock body, stickers), 4 Sonnet
  Explore agents (~100k tokens each), ~70 uploads (free), 0 Meshy; ~9.5 h wall clock; primary context ~80%.

## NEXT ACTION + PLAN
1. Ask Alan: grey bricks/bookshelves gone after Play? weapon feel (left+right fire, heat bar, paperclip, eraser)?
2. Plane A into the game (see START HERE). Old templates live in `assets/models/aircraft/aircraft.rbxmx`; muzzle =
   mount + 3 studs forward (CombatService/FlightHUD/CombatEffects use it). Hitbox = the mesh (HitShapes.luau).
3. After Alan's OK: the other 23 parts + 5 weapons + 3 boosters in the same style (heavy bodies in concept B's chunky
   style, slim in C's; concept sheets in `assets/models/planes/concepts/pilot/`). Batch the briefs to Codex.
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid.

## DECISIONS & WHY (this session)
- Ban cause = bell tower leg texture maps (flat braces read as swastikas), not names. `tools/art/fill_gaps.py` fills
  black UV gaps; every map gets looked at before upload. Planes get NO texture images (plain-colour meshes).
- Uploads use neutral names ("FFP tower part N key", file "asset.fbx").
- Bell tower = Alan's hand arrangement: two cardboard tiers (new clock body without the round seat), clocks on the
  upper tier, belfry ×1.1; tip ~529; Airspace Control zone moved to y 572.
- Water tower ↔ car park swapped (bell tower stays the focus): only 8 rug tiles re-cut by hand (t11–14 × 05–06).
- Combat (Alan): two weapon TYPES per plane, first filled slot's type = left click/R2, other = right/L2; pellet 30 /
  rubber 40 shots then 1.5 s cool; eraser lock 1.5 s and slows after 250 studs (0.55× at 750); paperclip reload
  1.8 s, speed 1500; rubber & paperclip take 2 slots; over-limit saved presets fall back to the starter build.
- Bots: only veterans lose a plane outside their 120° view (`tracks_in_view`); rookies/regulars unchanged.
- Music: 4 APM tracks shuffled (ids in `src/client/Audio.luau`); paperclip = soft metal ting; sliders apply live.
- Team stickers: red = square, blue = circle (no stars/red discs: war-insignia look); FFA plain white.
- Stage 8 (planes) started before the vertical-slice gate on Alan's explicit go.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (model router, look at the game, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Never run `city_links.py place` (resets Alan's bridge edits); `city_links.py clocks` adds clock rows only.
- `tools/rug.py` can no longer redraw the whole rug safely: Sweet Shop and Pencil Case Hall stand on old pool-deck /
  house plots (it now reports these clashes). Edit tiles by hand; `rug.upload`/`rug.build` can be called directly.
  `assets/rug/tiles/` is git-ignored: the 8 edited tiles live only on disk + as uploaded ids in `assets/rug/uploads/`.
- Open Cloud can't archive images; old banned-era leg images stay online unused.
- `tools/art/bell_tower.py` has `--export-piece <prefix>`; an unexplained re-export happened 10:30–10:52 (Alan never
  answered whether he ran Codex then) — harmless, but ask if it recurs.
- Older "back"-named assets were never renamed (429 rate limit); low value, skip unless asked.
- Plane A meshes: paper/accent/sticker FBXs in `assets/models/planes/classic/`, mounts in its parts.json.
- `studio_cli.py execute_luau` with a file path runs big Luau without pasting it (FULL=1 for long output).

## WHAT SHIPPED / OTHER QUEUED
- Shipped (29 commits, 58554c4f..3b776ca5): neutral upload names; ruler edits kept + clock uploaded; leg maps gap-
  filled; tower + clocks placed; veteran bot ease-off; refold confirm + tutorial-only help line; music + live sliders;
  combat rework (4e9b3978); plane concepts + model A r1/r2 + stickers; tower reshapes (8ec0df75, dd7446c2, c32c84e5,
  cd96b0d6); water tower/car park swap (e3ec2a3e); Alan's save + packs (3b776ca5); STATE updates.
- Queued: menu stage gaps (tutorial in a practice area, shop outside Studio); Track C saving (needs private publish).

## POINTERS
- `state/STATE.md`, `tools/art/planes.py`, `assets/models/planes/`, `src/shared/Aircraft.luau`, `src/shared/CombatRules.luau`,
  `docs/GAME_SPEC.md` (weapon table), `.planning/handoffs/handoff-2026-10-12-0420-bell-tower-blocked.md` (previous).
