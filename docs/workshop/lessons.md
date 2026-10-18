# Lessons learned

Hard-won rules from building this game. Each one cost real time (or, once, Alan's account) to learn. Moved here from
Claude's private memory on 2026-10-15 so everyone working on the game can see them. Add a lesson when the same
mistake would be easy to make twice.

## Uploads and Roblox moderation
- **Look at every texture before uploading.** Alan's account was banned twice on 2026-10-12 ("Discriminatory
  Content") because a bell-tower texture sheet had small bent leg braces laid flat as red hooks on black, which
  Roblox's image checker read as swastikas. The appeal was accepted the same day. A third strike likely means a longer
  ban, and Alan's account is the only upload route (no alt accounts: that would be ban evasion). Before ANY upload,
  make a contact sheet of every colour, normal and roughness map and look for symbols, hand signs, text or body
  shapes. Run `tools/art/fill_gaps.py` on hero pieces with shapes on black. Upload slowly.
- **Every FBX uploaded through Open Cloud arrives turned 180 degrees** (front and back swapped). Model templates
  must carry the turn (like `assets/models/aircraft/aircraft.rbxmx`).
- **Open Cloud can stay "processing" past the uploader's 40 s.** Check the saved operation in
  `assets/ui/<screen>/uploads/` before re-running an upload.
- **"Roblox rejected this upload" can be Roblox's own hiccup, not moderation.** Read the saved operation
  (`parts/upload-tmp.json`): `"internal error"` is a server fault; delete that file and re-run `town_toys.py hero` (it
  resumes). Three buildings uploading side by side worked fine (2026-10-16, ~1,000 files in ~40 min).
- **A freshly uploaded mesh can look invisible for a few seconds** after a place rebuild. Look again before debugging.

- **Fixing made-up text in AI pictures** (rulers, 2026-10-17): erase each dark glyph plus 3 px around it (AI text
  carries a light halo that otherwise shows as a pale blob), fill from the surrounding pixels without wrapping round
  the picture's edges, then letter real numbers at the ruler's measured angle, tops toward the ticks. Compare
  before/after at 2x. Menu pictures of the town: Studio captures, then Codex draws from them (`codex exec` in a
  scratch folder, ~4 min for three pictures, free on Alan's plan); tell it "no text, letters or numbers anywhere".

## Making 3D models
- **`toys.py` bakes go black in two cases** (2026-10-16): a `lathe()` profile listed top-to-bottom (list it bottom-
  to-top: its custom normals assume that), and beams split into overlapping pieces (coplanar overlaps). Look at
  `render.png` after every build. Many thin beams fail the atlas check: unfold each plain box as one strip (`crane()`).
- **Search the free Creator Store first**, then Codex in Blender, then Meshy last ([decision](../decisions/2026-10-12-creator-store-first.md)).
- **Free models can hide traps.** On 2026-10-15 a "Lego brick" (creator name "Roblox" plus invisible characters) held a
  script that ran only in Studio and built a pop-up window; many emoji-named near-identical uploads ("🪖 Army Man ...")
  follow the same pattern. Insert into a scratch folder, list every script and read it, keep only the mesh ids, delete
  the rest. `InsertService:LoadAsset` can't load other people's models; the Studio MCP `insert_asset` can.
  Again 2026-10-16: "Paper Boat Origami" 74278913481202 hides a "QualityEnhancer" script that fakes an "Error 501"
  and asks the developer to paste text into the command bar. Never use it; 9061318246 is the same boat, script-free.
- **A free mesh used as Part + SpecialMesh:** see-through textures that came from a SurfaceAppearance render as solid
  white sheets (three cobweb models); one with its own TextureId alpha worked. Read the mesh's size with
  `AssetService:CreateMeshPartAsync(...).MeshSize`; scale = wanted size / that. Rojo writes SpecialMesh ids as
  MeshContent/TextureContent, which Studio reads as MeshId/TextureId.
- **A SpotLight reaches 60 studs at most**, whatever Range says; it shows in Play, barely in Edit captures.
- **Style on the reference picture only**, never on buildings already in the game ([decision](../decisions/2026-10-01-art-target-reference-image.md)).
- **Blender buildings: build the objects the picture shows, separately** (Alan, 2026-10-15, on 13 Blender
  buildings): stacked boxes sit on each other with lips, overhangs and tape, blocks keep gaps, never one merged block;
  cut cardboard shows its corrugated flute edge; wood, cardboard and metal get real texture and baked shading; parts
  face the way the picture shows. Match the concept picture, measured into `sizes.md` first.
- **Check block depth against building footprints before drawing a street layout.** Layout D's blocks came out
  ~140-230 deep after roads, pavements and setbacks; our big buildings are 125-195 deep, so most never fit. Size the
  blocks from the buildings (two back-to-back rows plus a lot) first (2026-10-15).
- **Door knobs sit at half the door's height**, set in from the opening edge by about a fifth of the door's width, on
  the door itself (never on the frame, never low or at the very edge). Alan caught knobs off-centre on several models
  (2026-10-15); put it in every model brief and check it in close-ups.
- **Measure the concept picture before writing a model brief.** The bell tower took 4 rounds because the sizes in
  the brief didn't match the approved picture. Measure each part in pixels, convert with one scale, write a size
  table, then check the sums (posts x2 + opening = outer width; parts stack to the total height). The approved
  concept wins over old in-game templates.
- **Meshy fuses thin parts.** It turns wires into flat blades and makes every model one fused shell. Anything
  thinner than about 2% of the model's length, or anything that must move, gets built in Blender instead.
- **Meshy melts railings, rulers, crayons and pencils.** Every building gets a close-up sheet
  (`tools/art/closeups.py`) and melted parts are replaced through `touchup.json` before anyone sees it.
- **Plain Blender vertex colours show correctly in Roblox.** Pieces built from plain shapes with per-face colours
  avoid texture smudges and moderation risk.
- **Codex's picture tool refuses weapon words** ("illicit"), even for office-supply launchers, and once refused an
  empty cardboard tube with plugs. Keep weapon words out of picture briefs; model launchers straight from a written
  spec. When Alan sends real photos, model from the photos and get his OK on the render.
- **Batch art work.** Once the pipeline works on one model, send all concept briefs to Codex in one or two batches
  and run Meshy jobs side by side. Don't do one building at a time.
- **Codex test bakes go in a scratch copy.** `hero.py` treats its output folder as disposable and deletes the upload
  records of a placed building. Copy the inputs to a scratch folder and bake there.
- **Commit Codex's output before touching it.** Git only knows committed versions; `git checkout` on a fresh
  Codex export brings back the old file (cost a 20-minute re-export).

- **Rebaking a Meshy building:** use its original settings, including `--detail 2.5 --min-coverage 0.33` (the
  hero buildings' standard; parts.json records `detail` since 2026-10-16, older ones don't). A default-detail rebake
  of the paint-jar tower came out at half the triangles and had to be redone. A rebake drops every upload record,
  so all its pieces upload again.
- **Windows sometimes holds just-written files** (Errno 22 on overwrite, 2026-10-16; probably a scanner): they can be
  moved aside but not overwritten. `hero.py` and `fill_gaps.py` move old files aside before writing.

## Studio and the place file
- **The server deletes unknown things at the top of `workspace` on start** (`src/server/Bootstrap.server.luau`):
  world props go inside `workspace.Arena` (in `default.project.json` under `Arena`).
- **An uploaded mesh can carry a big PivotOffset** (the chalk eraser's was 1,250 studs down, so its cloud spawned
  underground). Place things from `GetBoundingBox()`, not `GetPivot()`, or zero the part's `PivotOffset`.
- **Anything turned by server time must wrap the angle first.** `GetServerTimeNow()` is about 1.8 billion seconds and
  `CFrame.Angles` uses 32-bit floats, so `now * speed` stops the part dead (duct fans, 2026-10-15). Use
  `(now * turns % 1) * 2 * math.pi` (`src/shared/DuctRules.luau` `fanAngle`).
- **One error in a client module's `start()` stops every module after it in `Bootstrap.client.luau`**: no flight
  controller, no camera, the plane flies straight. After renaming or removing a config key, grep `src/` for it.
- **Rojo `.model.json` parts:** CFrame must be written `{"CFrame": {"position": [x,y,z], "orientation": [[row],[row],[row]]}}`
  (rows of the rotation); Enums as names, Color3 as 0-1 floats. `tools/ducts.py` builds the duct model this way, no
  Studio export needed.
- **A ParticleEmitter's own `Rate` is thinned out when the camera is far away**; an effect that must show from across
  the room launches its particles with `:Emit()` on a timer (`src/client/ChalkCloud.luau`).
- **Testing from Studio MCP:** threads started with `task.spawn` die when the command ends (use a real `Script`
  instance for a helper that must keep running); HUD markers follow the chase camera, not a `DevCamera` view; Studio
  throttles to ~12 frames a second in the background, so frame rate can't be judged there (Alan checks it).
- **`city-toys.rbxmx` is not only the town** (2026-10-16): it also carries the classroom's own pieces from
  `toy-placements.json` (desk hangars, runway lights, landing rings, ceiling rings, tubes, threads, the bell tower's
  clock hands, the floor fans, the schoolyard set). A town swap keeps them (`CLASSROOM_PIECES` in
  `tools/town_toys.py`).
- **After editing `config/*.json`, run `python tools/generate_config.py` before Play** (2026-10-16): a key the code
  reads but the generated module lacks errors the server's flight step every frame.
- **Exact building collision is computed once and saved in the place.** Alan presses Ctrl+S after new buildings
  are placed and their shapes are computed, BEFORE any `tools/save_place.py` rebuild, or about 40 minutes of
  computing is thrown away. `save_place.py` copies saved shapes onto rebuilt parts by MeshId; check with its
  `PRECISE_HEADER` test. A mesh with no saved shape loads as a solid **box** (planes hit the gaps; 2026-10-16, 453
  parts): run `tools/exact_collision.lua` in Studio after every rebuild with new meshes, wait while Studio is busy,
  then Ctrl+S.
- **After Publish As, Studio is editing the online copy, not `FlyFightPaper-WORKING.rbxlx`** (2026-10-17). Ctrl+S then
  saves to Roblox; the working file only changes with **File > Save to File**. Rebuilds (`save_place.py`) read the
  working file, so ask for Save to File (not just Ctrl+S) before any rebuild, and re-publish with Publish As after.
- **Exact collision can fill a hollow piece's opening.** The south station's lunch tin got a shape that blocked a
  wedge of its own track tunnel (2026-10-17). Check tunnels with a grid of raycasts after new shapes are computed;
  a piece that fails goes in `WALLS` in `tools/town_toys.py` (see-through mesh + plain invisible walls).
- **New models need texture packs.** After placing new models, Play gets slow (over a minute) until Alan presses
  Ctrl+S and `python tools/town_toys.py packs FlyFightPaper-WORKING.rbxlx` then `build` harvest the packs.
- **Rojo live sync sometimes can't set MeshIds.** After syncing new mesh parts, check each `MeshId` is not empty
  in Studio before judging; rebuild with `save_place.py` only if they arrive empty. The sync can take a few seconds.
- **Studio only draws when it is in front.** Behind other windows, screenshots time out, frame code
  (`RenderStepped`) stops running, and FPS reads about 15. Check the `RenderStepped` count first. Test frame code
  with a Play-client clone of the module that uses `Heartbeat` instead. Prove fit with numbers: EditableMesh
  triangles give exact overlap (convex-hull checks overstated thin-wing clipping about 8x). Even in front, the 3D
  view only redraws while the mouse moves over it. Point the Play camera with the player attribute `DevCamera`
  (setting the camera directly gets overwritten). Judge sun shadows only with Studio in front at graphics level 21;
  Play quality resets to Automatic each start. For screenshots, hide every PlayerGui ScreenGui, then set `DevView`.
- **Getting pictures when Studio won't draw** (2026-10-15): a PowerShell `AppActivate` isn't enough, and
  `screen_capture` still timed out even with Studio in front. What worked (desktop control, Alan's OK): click Studio's
  title bar so it draws, point the Edit camera by script (`workspace.CurrentCamera`, Scriptable, CFrame), then
  computer-use `zoom` on the viewport with `save_to_disk`. Tweens and animations freeze too while Studio isn't drawing,
  so a client effect (a paper target falling) can't be judged then.
- **Firing from a test script:** `CombatInput` packets need `seq` above the server's last one for that life (the real
  controls send their own); stepping `seq` by 500 always lands inside the accepted window (2000).
- **Undoing a commit when someone else has staged changes:** `git revert` refuses; restore the files instead with
  `git checkout <commit>~1 -- <paths>` and commit that.
- **Alan plays in the same Play session.** Before driving the plane from tools, check whether Play is already
  running; if Alan started it, read-only checks only.
- **Claude's test copy.** For tests that need their own Play, build a copy of the place in the session scratchpad
  (`FlightTest.rbxlx`) and push code into it; details in [Studio and Rojo](studio-and-rojo.md).
- **After Codex jobs, Studio tools can vanish** because Codex starts its own Studio link. Codex's Studio link is now
  disabled in `~/.codex/config.toml`; if tools vanish again, stop only the StudioMCP processes whose parent is
  `codex.exe`, never this session's own proxy (stopping that kills the link until a new session). Codex picture jobs
  that hang at "starting" through the plugin work with `codex exec -s workspace-write - < prompt.txt`.
- **Studio link "connected, 0 tools" with no Codex running** (2026-10-17): nothing to stop and no restart needed:
  `python tools/studio_cli.py TOOL '{json}'` drives Studio directly (Play, execute_luau with `datamodel_type`,
  screen_capture, user_mouse_input with `mouse_button`). Check `tools/` before writing a helper.
- **Closing and reopening Studio** without desktop control: `Stop-Process -Name RobloxStudioBeta`, then
  `tools/save_place.py` if needed, then `Start-Process <place>.rbxlx`; ask first if Alan may be using Studio.
  Opening Studio through desktop control's `open_application` starts a second empty Studio.
- **Previewing a generated model without saving:** write it into a gitignored ModuleScript under a folder `rojo serve`
  syncs (`src/generated/`), then in Edit `require(module:Clone())` to rebuild the parts (2026-10-15: the 1 MB duct
  model reloaded in seconds). Delete the file afterwards so a Ctrl+S or rebuild can't keep it. Writing
  `assets/models/ducts.model.json` sometimes fails with `Errno 22` for a moment after the last write: retry.
- **Test-copy details:** set HttpEnabled; fetch files from the local file server with `nocache=true` (otherwise
  Studio serves old cached files); click real buttons with `user_mouse_input` `instance_path`; check a file exists
  before closing its Studio (on 2026-10-08 a restart deleted the only copy).

## Working with Alan
- **No desktop control** (mouse and keyboard) unless truly necessary or Alan asks; say why first. Anything that
  needs a real click (Rojo Connect, Ctrl+S) goes to Alan as a request.
- **Commands for Alan are PowerShell:** `cd D:\FlyFightPaper; ...` with `;`, never `&&`.
- **Show layouts before uploading.** Town layouts get a preview picture and Alan's OK first
  ([decision](../decisions/2026-10-09-town-planning-rules.md)).
- **Touch up before showing.** Nothing is shown to Alan until its close-ups are clean.

Back to [HOME](../HOME.md)
- **Emotes on scaled-up avatars** (2026-10-17): Roblox scales an animation's hip ("Root" joint) movement twice on an
  avatar made big with `ScaleTo` (27 x 27 instead of 27), so emotes throw the body far from its root; other joints
  are fine. Fix: each `PreSimulation`, divide that joint's `Transform.Position` by the model's scale
  (`src/client/WinnersCutscene.luau`). Test a new animation on a big avatar by measuring head-to-root drift.
- **Starting a round in place:** planes carried over keep their old team; clear it and join them to the new round
  before bots fill desks, or the roster rejects them (`invalid_actor_team` / `unexpected_actor_team`).
