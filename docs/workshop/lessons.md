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
- **An FBX uploaded with `--model` is a Model asset, not a mesh.** Its id as a MeshId fails to load (invisible
  parts; the Classic paper sample, 2026-10-18). Read the inner MeshPart's MeshId in Studio with `LoadAsset`
  (`tools/art/upload_paper.py lua`, `tools/town_toys.py`) and use that.
- **Roblox asset names are at most 50 characters** ("Asset name length is invalid", HTTP 400). Keep upload names
  short (`tools/art/upload_paper.py` uses "FFP plane <piece> <map>").
- **Every FBX uploaded through Open Cloud arrives turned 180 degrees** (front and back swapped). Model templates
  must carry the turn (like `assets/models/aircraft/aircraft.rbxmx`).
- **Open Cloud can stay "processing" past the uploader's 40 s.** Check the saved operation in
  `assets/ui/<screen>/uploads/` before re-running an upload.
- **"Roblox rejected this upload" can be Roblox's own hiccup, not moderation.** Read the saved operation
  (`parts/upload-tmp.json`): `"internal error"` is a server fault; delete that file and re-run `town_toys.py hero` (it
  resumes). Three buildings uploading side by side worked fine (2026-10-16, ~1,000 files in ~40 min).
- **"Reviewing" is not the verdict, and plain pictures can still be rejected (2026-10-25).** Of 1,187 bump/shine
  re-uploads, 1,186 came back Approved and one plain grey roughness map (ring-binder roof) Rejected. Read each new
  id's final `moderationResult` (Assets API GET, read only) before using any; never re-send a rejected picture,
  keep the piece's earlier accepted one.
- **A freshly uploaded mesh can look invisible for a few seconds** after a place rebuild. Look again before debugging.

- **Fixing made-up text in AI pictures** (rulers, 2026-10-17): erase each dark glyph plus 3 px around it (AI text
  carries a light halo that otherwise shows as a pale blob), fill from the surrounding pixels without wrapping round
  the picture's edges, then letter real numbers at the ruler's measured angle, tops toward the ticks. Compare
  before/after at 2x. Menu pictures of the town: Studio captures, then Codex draws from them (`codex exec` in a
  scratch folder, ~4 min for three pictures, free on Alan's plan); tell it "no text, letters or numbers anywhere".
- **Changing an uploaded menu piece** (2026-10-19): `tools/ui_pieces.py` reuses an existing `uploads/<piece>.json` and
  never re-uploads; delete that record (git keeps it) before the upload run, then put the new id in UIAssets.

- **Studio reads online pictures at 1024 at most** (2026-10-27): `CreateEditableImageAsync` of a 2048 sheet returns
  1024 x 1024 (an EditableImage limit; Roblox itself keeps textures up to 4096). Compare such reads at 1024, or sample
  by UV, never by pixel position.
- **A piece's `ready/` file can differ from what Roblox has** (2026-10-25): `ui_pieces.py` reuses old upload records,
  so a later re-cut never went up (7 results pieces: other sizes, other crops). Before building anything from `ready/`
  files, read the online pixels in Studio (`AssetService:CreateEditableImageAsync` + `ReadPixelsBuffer`; return them
  in ~66 KB chunks with `EncodingService:Base64Encode`, the MCP cuts replies near 100 KB) and compare.
- **`ui_pieces.py` trims every piece to its visible pixels**, so a 9-slice `SliceCenter` must be measured on the
  trimmed `ready/` file, not the brief's size (Hangar outline: 512 drawn, 480 trimmed, band in the outer 48 px).
- **Menu previews before upload: draw them at the game's real sheet coordinates** (a PIL script using the same numbers
  as the Luau). Alan caught a flat shelf (no top board), empty space and a stretched photo paper this way, before any
  upload (2026-10-21). Landscape paper art stretched into a tall box looks bad: drop it or get a piece in that shape.

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
- **Compare looks in the same spot.** Copies of a building 300 studs apart, high above the map, drew visibly darker
  in one place than another (2026-10-25): move both to one spot (or swap them) before blaming the pictures.
- **Roblox keeps pictures up to 2048 (tested 2026-10-25), but `EditableImage` reads at most 1024**, so a readback can't
  tell you an upload's size; draw it up close in a drawing Studio instead.
- **The server deletes unknown things at the top of `workspace` on start** (`src/server/Bootstrap.server.luau`):
  world props go inside `workspace.Arena` (in `default.project.json` under `Arena`).
- **An uploaded mesh can carry a big PivotOffset** (the chalk eraser's was 1,250 studs down, so its cloud spawned
  underground). Place things from `GetBoundingBox()`, not `GetPivot()`, or zero the part's `PivotOffset`.
- **Anything turned by server time must wrap the angle first.** `GetServerTimeNow()` is about 1.8 billion seconds and
  `CFrame.Angles` uses 32-bit floats, so `now * speed` stops the part dead (duct fans, 2026-10-15). Use
  `(now * turns % 1) * 2 * math.pi` (`src/shared/DuctRules.luau` `fanAngle`).
- **One error in a client module's `start()` stops every module after it in `Bootstrap.client.luau`**: no flight
  controller, no camera, the plane flies straight. After renaming or removing a config key, grep `src/` for it.
  A compile check (`loadstring`) can't see it: on 2026-10-19 a value read above the line that loads it crashed the HUD
  and every menu after it (Tutorial and Play did nothing). After any client edit, start Play and read the console.
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
- **Game scripts can't read a SurfaceAppearance's maps (2026-10-25).** `ColorMap` and the other maps need plugin
  rights: reading one in a LocalScript errors, and it kept a published build on the loading screen for good. Hand
  PreloadAsync the SurfaceAppearance itself. Loading is wrapped so any error still lets the player in.
- **A phone downloads the whole map when streaming is off (2026-10-25).** ~4,500 assets made Alan's phone wait
  minutes, and the menus' pictures queued behind the town's. Preload the menu art first (`Loading.luau`), and count
  every texture map (SurfaceAppearance ones too) when judging a map's weight.
- **Fewer files is not faster by itself (2026-10-28).** Merging the town's pictures into 2048 sheets cut its files
  ~3,000 -> ~2,100, but the phone took longer per file (all 58.9 s vs 59.3) and its picture memory went ~70 -> ~575 MB.
  Measure a picture change with a phone join (time and `LoadLog` texture MB) before shipping it.
  Change one thing per phone test: v390 also carried a loading change, so the memory jump has two suspects. Studio on
  a PC can't show phone picture memory (it keeps everything full size).
- **Rojo serve can switch settings in the place, and publishing ships them (2026-10-28).** `serve.project.json` set
  `StreamingEnabled` false, so streaming was off in published builds for days (phones got ~2,800 town files at join;
  the loading screen stayed blurry 35 s). Serve now sets it true; `LoadLog.recent()` flags "STREAMING OFF" joins.
- **New models need texture packs.** After placing new models, Play gets slow (over a minute) until Alan presses
  Ctrl+S and `python tools/town_toys.py packs FlyFightPaper-WORKING.rbxlx` then `build` harvest the packs.
- **New maps on many pieces at once: Studio re-makes their texture packs and gets throttled (2026-10-25).** Swapping
  ~2,000 SurfaceAppearances made Studio ask for ~2,000 packs; most failed with HTTP 429 ("PBR textures may not be
  visible"). A piece without its pack draws a little differently (the notebook tower's walls looked brighter), and
  players see the pack. Re-make the missing ones slowly (new SurfaceAppearance, 10 every 25 s). Scripts can't read
  `TexturePack`, but `SerializationService:SerializeInstancesAsync` of the SurfaceAppearance shows it
  ("TexturePack" then the id), so packs can be checked and collected without saving the place.
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
- **Locking the mouse reads as a mouse move.** Switching `MouseBehavior` to `LockCenter` pulls the cursor to the
  middle, and the next `GetMouseDelta` reports that jump: the plane's aim jolted left after every LAUNCH click or
  lesson pause (2026-10-19). Ignore the mouse for 0.1 s after locking (FlightController).
- **Tests in Edit mode lie** (2026-10-19): the MCP Edit VM keeps old copies of required modules, so the suite showed 15
  failures in code nobody touched. Run the tests in Play on the server VM (no mouse needed while Alan plays).
- **Studio MCP clicks (2026-10-21):** `user_mouse_input` x/y are in the same space as `AbsolutePosition` (below the
  top bar), not window pixels; a rotated button (the Hangar's pencil) can be missed by `instance_path`, so click its
  `AbsolutePosition + AbsoluteSize/2`. A running Play never picks up Rojo edits: stop and start Play after each change.
- **A Lua value can't be stored on an Instance** (`board.before=fn` errors: "not a valid member"): keep it in a local.
  It made the Tutorial button do nothing (2026-10-19).
- **Stopping a background Codex job** (TaskStop) leaves `codex.exe` running and it can still write files; stop the
  codex.exe started at that time too.

- **Flat 2D scenery needs a still camera (Hangar Range, 2026-10-19):** a chase camera swinging round the plane made the
  painted flats slide past each other and showed their edges. A still camera with a moving crosshair keeps them flat;
  the plane must then point at what the crosshair is on (raycast plates and cut-outs, else the aim-help target), or
  shots land below the crosshair. Check reach in Play: plates 54° off the plane were outside a 30° aim limit.
- **Hook up a replicated model's parts as they arrive:** a client script that walked `RangeStage:GetChildren()` on
  the model's `ChildAdded` found none of its plates; listen to the model's own `ChildAdded` too.
- **`TextScaled` stops at 100 px:** on a big SurfaceGui canvas words stay small; lower `PixelsPerStud` so the box is
  under 100 px tall. Kalam pads its letters, so text boxes need to be bigger than the words look.
- **Edit-mode previews of new modules:** Edit caches `require`, so clone the module and point its requires at clones
  (UIAssets, TrainingCourse) to preview a builder without Play.
- **A drawn stand-in needs a matching hitbox (2026-10-19):** the Range draws each target as a flat card, but hits were
  tested against the hidden plane under it (HitShapes), seen side-on as a thin edge, so long shots never landed. If
  the picture isn't the model, give the hit test the picture's shape.
- **Welding new parts onto a flying plane can drop network ownership (2026-10-19):** after `FlightService:refold` in the
  Range the server took the plane and flew it off with its own velocity. Give ownership back after any rebuild.
- **Measure the play area before laying out controls over a game view (2026-10-19):** the Range side-board preview was
  rejected partly because the targets' sweeps covered only about a quarter of the screen width; project each sweep's
  ends onto the capture first, then fit controls into what's left.
- **Overlapping see-through SurfaceGui flats sort badly:** a backing board drawn 1 stud behind its strips hid them;
  keep 3+ studs between layers, or don't overlap them. Never 9-slice a painted piece with folds across its middle.
- **Moving a model with a TweenService tween on a CFrameValue stuck halfway (2026-10-19, 3-4 times in Alan's Play):**
  a per-frame spring toward a goal can't stall and takes a click mid-move. Gemini CLI's free personal sign-in stopped
  working (Google says move to Antigravity); Codex is the second opinion for now.

- **A click on an empty spot of a menu is NOT "processed"** (`InputBegan`'s flag is false unless a button took it), so
  world click handlers must also check `Root:GetAttribute("OverlayOpen")`: the Range turned such clicks into shots and
  closed Customize (2026-10-21).
- **Sounds in Edit mode (2026-10-23):** `Sound:Play()` does nothing in Edit (TimePosition stays 0), but the newer
  `AudioPlayer` wired (`Wire`) to an `AudioDeviceOutput` plays, fades and reports TimePosition in Edit, so a timed mix
  (WinnersSound) can be heard and checked without Play.
- **Edit-mode `require` is cached (2026-10-24):** after Rojo syncs new code, a command-bar `require` in Edit still
  returns the old module (new config keys came back nil). To test fresh code in Edit, clone the package
  (`ReplicatedStorage.FlyFightPaper`), rename the real one aside, require from the clone, then restore the name.
  Pure-math checks (unit specs, the fake-pilot aim test) run this way with no Play at all.
- **Phone view in Studio (2026-10-24):** with Studio's Device Simulator (File > Beta Features > New Device Simulator,
  Alan turned it on), Play's viewport is a phone (749 x 381), PreferredInput is Touch and MCP screenshots show the
  phone screen. Without it, the `DevTouch` attribute on ReplicatedStorage.FlyFightPaper shows the touch layout on a PC.
- **Driving the phone view from MCP (2026-10-24):** 749 x 381 is the notch-free safe area; the screenshot also shows
  the notch strips at the sides (a default ScreenGui never draws there, so full-screen art needs `ScreenInsets = None`).
  MCP mouse clicks land in the wrong place under the simulator, and any MCP key press flips PreferredInput to keyboard
  (set `DevTouch` to keep the touch layout). Open screens with the `DevScreen` player attribute ("hangar:customize"
  opens the binder). Kalam reads small: aim for about 14+ points on screen, not 12. A click at (x, y) arrives as a touch
  at (x - 62, y) in GUI space, so tap a button at its AbsolutePosition centre + (62, 0).
- **`TouchTapInWorld` counts the top bar (2026-10-24):** its position is 58 points lower than GUI/InputObject space,
  so turn it into a ray with `ViewportPointToRay`, not `ScreenPointToRay` (the Range's strips missed by 28 studs).
- **PreloadAsync doesn't fetch pictures given as id text** (2026-10-25): every `rbxassetid://` string reported
  Failure in 0.1 s in Studio and stalled 15 s on a client, so the loading screen and menus showed only words on a
  phone. Hand it the things that draw them (an `ImageLabel` with `.Image` set, a MeshPart, a SurfaceAppearance).
- **PreloadAsync fetches a list one file after another** (2026-10-25): 28 menu pictures in one call took over 15 s on
  a phone. Ask for each file on its own, many side by side. Some MeshParts kept in ReplicatedStorage (plane pieces)
  never report back, so give each request a time limit or they hold a slot for good.
- **The engine throws away preloaded pictures that nothing draws** (Roblox staff, 2026-02, won't fix): keep them drawn
  (almost see-through) until their screen is up; first/LoadingFirst's `KeepDrawn` does this for the first screens.
- **A phone fetches a picture only as sharp as it is drawn** (2026-10-25): preload labels drawn at 8 x 8 px "loaded"
  the loading screen's art in 0.5 s on a phone, as postage stamps; the screen showed them stretched (blurry) for 30 s
  until the full ones came. Draw preload labels near their real size (almost see-through); PC shows no difference.
- **Cold-load timing** (2026-10-25): `tools/cold_cache.py aside` empties Roblox's download cache (Studio and the
  Roblox app closed). Studio Play waits ~5-6 s before the first picture of a join arrives (even one 34 px pin); the
  real Roblox app gets it in under 1 s, so judge the first seconds on the real app. Studio Edit renders the town and
  warms its files, so a Studio cold test only measures menus and pictures fairly.
  A Studio cold test refills the cache for the real app too: clear it again right before Alan's join (2026-10-25:
  one join timed warm by mistake, menus 2.8 s).
- **Menu pictures download as PNG, 3D pictures compressed** (2026-10-27, PC cache `rbx-storage.db` + `rbx-storage/`):
  the same uploaded picture comes as PNG for an ImageLabel but as KTX2 BC1/BC3 + zstd (~7x smaller) for a Decal, even
  one inside a ViewportFrame. A Decal's height came back 540 -> 512.
- **Phones load menu pictures slower 8 at a time than 3** (2026-10-27): phone v361 at 8: menus 50 s, all 81 s; v358
  at 3: menus 35.5 s, all 58.6 s (a phone unpacks each PNG itself). A PC cold test can't show this: judge download
  counts per device on the phone. Same as the town's groups (6 beat 12).
- **Anything drawn is fetched at once, outside our queue** (2026-10-28): a label or 3D card put on screen, even 0.99
  see-through, is downloaded by the engine straight away; 18 such at the start of phone v364 jumped the 3-at-a-time
  line (all 91 s). Put a preload's picture on screen only when its turn in the queue comes. The same goes for the town:
  once it streams in, the engine fetches what it draws. A PC shrugs this off, so only a phone join shows it.
- **A ViewportFrame with a lower ZIndex than its parent isn't drawn at all** (2026-10-27): give it the parent's ZIndex
  and make it the parent's first child so the label's words stay on top (`first/MenuArt`).
- **Smaller picture files don't shrink the download** (2026-10-25): Roblox stores every uploaded picture as its own
  PNG (a 255 KB JPG came back as 975 KB; a 281 KB 256-colour PNG as 650 KB). Only fewer or smaller pictures help.

## Working with Alan
- **A behaviour fix isn't fixed until it's seen in Play** (2026-10-19): three Combat School fixes made by reading the
  code alone (the red dot, the eraser during the freeze, step 8's Pal) were wrong, and each cost Alan a playtest.
  One logged Play run found each real cause in minutes (BotIntent, Held, distances each second). For aim, read where
  the shots went (`DevShotLog`), not just which way the guns pointed.
- **Scripted doc edits: never `replace` a slice cut between two markers without checking it** (2026-10-18): if the
  end marker sits before the start marker the slice is empty, and `s.replace("", text)` puts the text between every
  character (the shop plan note went out garbled and pushed). Assert the old text is non-empty and found exactly once.
- **Plane meshes before the paper retexture have no UV layout** (2026-10-18): no material, texture or skin can show on
  them; a textured part means a new mesh upload (with UVs) plus its maps, swapped in by MeshId.
- **No desktop control** (mouse and keyboard) unless truly necessary or Alan asks; say why first. Anything that
  needs a real click (Rojo Connect, Ctrl+S) goes to Alan as a request.
- **Commands for Alan are PowerShell:** `cd D:\FlyFightPaper; ...` with `;`, never `&&`.
- **Show layouts before uploading.** Town layouts get a preview picture and Alan's OK first
  ([decision](../decisions/2026-10-09-town-planning-rules.md)).
- **Touch up before showing.** Nothing is shown to Alan until its close-ups are clean.
- **Roblox's own emotes are free to play in any game** (2026-10-18): search the catalog by script
  (`AvatarEditorService:SearchCatalog`, asset type EmoteAnimation, creator "Roblox"), then
  `game:GetObjects("rbxassetid://<catalog id>")` gives the Animation inside with its real animation id. All 24 tried
  played on our big avatars; Hero Landing and Break Dance dip below the desk.
- **Rojo can die with a Studio reconnect** (2026-10-18): when the Studio tools come back under a new id, check that
  `rojo serve` still answers on port 34872 before trusting a test; Alan reconnects the plugin.
- **Check a collision change by outcome before Alan plays it** (2026-10-18): the first train fix made wing touches
  kill (cars' joints counted as the next car's front). Run the scenarios (alongside, at a joint, roof, nose-first,
  in front of the train) with a real plane's `Colliders` corners through the hit rule and `Rules.collisionDamage`,
  and read off scrape or crash, before handing it over.
- **Wide shots in a tall room:** a 16:9 shot wide enough for three desks is very tall at their depth; pick where the
  spare height goes (wall above or floor below) and fade what hangs from the ceiling in front of the lens.
- **Emotes on scaled-up avatars** (2026-10-17): Roblox scales an animation's hip ("Root" joint) movement twice on an
  avatar made big with `ScaleTo` (27 x 27 instead of 27), so emotes throw the body far from its root; other joints
  are fine. Fix: each `PreSimulation`, divide that joint's `Transform.Position` by the model's scale
  (`src/client/WinnersCutscene.luau`). Test a new animation on a big avatar by measuring head-to-root drift.
- **Animations without Studio clicks (2026-10-18):** build a KeyframeSequence by script, preview it in Play with
  `AnimationClipProvider:RegisterAnimationClip` (a temporary id, Studio only, register it on the client for client-side
  playback), export it with `SerializationService:SerializeInstancesAsync` + `EncodingService:Base64Encode`, then upload
  the .rbxm through Open Cloud as assetType Animation (`tools/upload_texture.py --animation`). Free.
- **Focus blur range (2026-10-18):** `DepthOfFieldEffect.FocusDistance` and `InFocusRadius` clamp at 500 studs; our
  room is huge, so a shot that uses the blur keeps the camera within ~480 studs of its subject (wider lens if needed).
- **Fading town pieces for a camera shot:** fade a whole building (all CityToys "name/piece" pieces) when any piece
  blocks; fading only the blocking pieces shows the building's dark inside.
- **Starting a round in place:** planes carried over keep their old team; clear it and join them to the new round
  before bots fill desks, or the roster rejects them (`invalid_actor_team` / `unexpected_actor_team`).
- **Codex picture jobs in a scratch folder** need `codex exec --skip-git-repo-check`, or Codex refuses to run outside a git folder.
- **Real-player looks for bots (2026-10-18):** `GetHumanoidDescriptionFromUserIdAsync` allows 300 lookups a minute per
  server, so never search at runtime. Random user ids are mostly quitters in Roblox's free starter outfits (layered,
  so a "2+ layered items" filter lets them through and bots look alike); require one item not made by Roblox
  (`GetProductInfoAsync` creator id 1). Random saved-outfit ids (`GetHumanoidDescriptionFromOutfitIdAsync`, 1e8-1.2e10)
  find about 10x more good looks than user ids.
- **Meshy text-to-motion clips (2026-10-18):** standalone FBX on an SMPL skeleton (T-pose rest, 30 fps, 2-10 s, 10
  credits). `tools/meshy_to_r15.py` maps them onto R15 by world-space bone turns; check by comparing knee/elbow bend
  angles before and after (they matched to 0.1°). `AnimationClipProvider:RegisterAnimationClip` returns a plain hash
  string that works as an AnimationId as is (`rbxtemp://` in front is refused).
- **A Sound inside an Attachment plays at that attachment's place, even outside the room** (2026-10-18: "flat" UI
  sounds sat in an attachment under SoundService, so they played from the room's middle and faded with distance).
  Sounds meant to be heard the same everywhere go straight in SoundService.
- **Moving a GUI piece to another ScreenGui breaks every `FindFirstChild` path to it** (2026-10-22: the kill feed moved to
  FlightHUD's MatchInfo layer and CombatEffects, which looked in FlightHUD, stopped filling it). Grep the piece's name
  across `src/` before moving it.
- **The Range runs as the tutorial's "range" room** (`TutorialOpen` true, `TutorialLesson` "range"): "not in a lesson"
  checks must exclude it, or they also hide things in the Range (2026-10-22 sticky notes). And `x ~= nil` is true for
  `false`: write `if show then f() else nil`, not `show and f()`, when nil means "hide".
- **`Sound:Play()` inside that sound's own `Ended` is ignored** (2026-10-22: the playlist stopped after one song; the
  next id loaded but stayed at 0:00). Start the next track a moment later (`task.delay(.3, ...)`); tested both ways.
- **A comment in a packed Luau line switches off everything after it** (2026-10-18: `-- note` in the middle of a
  `;`-joined line hid the tutorial note for a whole playtest). Comments go at the end of the line or above it.
- **Tutorial UI traps (2026-10-18):** the Kalam font has no arrow or tick signs (▼ ➤ ✓ draw as empty boxes): use
  the crayon arrow picture (`UIAssets.hud.arrow`, points right). ScreenGuis report `AbsolutePosition` (0,-58) under the
  top bar: to place one GUI over another, subtract this layer's `gui.AbsolutePosition`. Screen captures drop
  see-through frames (dims look missing): check by making them solid for one capture. `execute_luau` gets its own
  copy of a ModuleScript, so it can't read or change a running module's state; drive the game through remotes and
  attributes instead. Loading changed modules with `require` in Edit catches typing mistakes without starting Play.
- **A lead ring can't guess a curving path (2026-10-20):** speed + turn (second-order) prediction misses by tens of
  studs once a shot flies over ~1 s at a target that swoops (pencil, Range Veteran long: 0% hits even with exact
  motion). Simulate the miss before blaming the guns; for scripted targets read the real path instead.
- **Same path, same clock (2026-10-20):** a scripted target drawn "a smoothing delay ago" but judged with the
  general rewind (two trips + smoothing) is off by the difference, about 150 studs/s x a few hundredths of a second:
  enough to miss a 13-stud card going up. Draw it on `GetServerTimeNow()` and rewind only the message's own trip.
- **A shapecast never hits a part it starts touching (2026-10-20):** a moving target can step onto a shot between
  server steps, and Blockcast/Spherecast then skip it. For a plain box use `CombatRules.segmentBox`, which counts a
  start inside. For mesh shapes check `GetPartsInPart` with the shot's box at the start first (HitShapes does).
- **GUI positions start below the top bar:** compare a crosshair's viewport point with a button's
  `AbsolutePosition` minus its ScreenGui's `AbsolutePosition` (an IgnoreGuiInset gui's corner is the window's).
- **Studio Play takes Alan's mouse (2026-10-18):** a flying plane locks the mouse to the centre. Run Play only when
  Alan says go or is away, in one short batch, and stop it right after.
Back to [HOME](../HOME.md)
- **An "on target" sign must use what the shot uses (2026-10-21):** the Range's green dot showed the nose and turned
  red by the nose, but shots went to the crosshair, which the nose trails by 1-2 degrees while tracking. Close targets
  hid it; the long row hit 2%. A test that fires from the ideal aim can't see this: simulate the player's real loop
  (aim, turning, what the client sends) when an indicator and the shots could disagree.
- **A shooting test must aim like a good player, or it measures the test (Alan, 2026-10-21):** a plane steered at the
  ring chased bots through buildings and its dot trailed the ring, so 21-30% hits said nothing about the game. Fire
  only while the HUD's own "on target" test passes and keep clear air (DevAimLead), or better, record real flight and
  fire simulated shots at it offline with the real hit shapes (thousands of shots, no aiming noise).
- **Esc belongs to Roblox first (2026-10-22):** every Esc opens or closes Roblox's own menu, and the press that closes
  it never reaches `InputBegan`. So "Esc again goes back" needs a third press; give the screen a button for it.
- **A shot with a target is an eraser (2026-10-22):** CombatService steers any shot that has `target` and raises
  INCOMING! on it. Placed pellets (step 8's ambush) pass the target only for aiming, and need a lead to hit.
- **Count the trigger's travel time once (2026-10-21):** the screen showing bots 0.19 s late looked like a gap against
  the server's 0.1 s rewind, but the rewind also adds twice the trigger message's age; end-to-end shots showed no lag.
- **Adding a part to a flying plane takes it off its pilot (2026-10-23):** welding the team stickers on (Aircraft.paint,
  when a team round starts) reset the plane's network owner to the server. The pilot's mouse still turned the aim but
  nothing moved the plane: it flew straight into a wall until it folded (no pointer, control back only on a new life).
  After changing a client-flown plane's parts on the server, call `SetNetworkOwner(pilot)` again.
