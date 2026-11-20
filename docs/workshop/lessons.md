# Lessons learned

Hard-won rules from building this game. Each one cost real time (or, once, Alan's account) to learn. Moved here from
Claude's private memory on 2026-10-15 so everyone working on the game can see them. Add a lesson when the same
mistake would be easy to make twice.

## Uploads and Roblox moderation
- A large sheet can load successfully in Studio while each animation frame has too few pixels for a close-up. Inspect the held prize pose at player size. Give that pose its own image. Warm the image before the lid opens because a fully hidden copy may report `IsLoaded=false`.

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
- **Built parts get the same gap fill** (Dragon, 2026-11-15): fill every texel no triangle uses from the nearest used one
  (`upload_prep.py`, with the Dragon's paint scripts under `.planning/skins/dragon/`). For two-value pictures (metal, roughness) count only texels inside a
  triangle, or stray edge texels grow into rays. One FBX with several meshes arrives as a Model of MeshParts that keep their names.
- **An automatic unwrap can lay a model's faces in a pinwheel** (Hot Rod, 2026-11-16): Blender's packer turned the four wing
  faces a quarter turn from each other round a middle. `tools/art/sheet_model.py`'s `uv.upright` turns every island the same
  way up and packs without turning any (the Hot Rod lost 16% of its texels per length; six player's views showed no change).
  The safety sheet for such a skin: `.planning/skins/safety/` (`uv_dump.py` in Blender, then `sheet.py`: the gap fill and a
  before/after sheet to look at). A glow picture is always bright shapes on black: look at it hardest.
- **"Same model, new layout" is proven with numbers, not eyes** (Hot Rod, 2026-11-16): a note typed after a `#` in the middle of a
  spec line switched off five settings (light, bump); six side-by-side views looked the same to me and the reviewer measured the
  underside 15% darker. After any change to a `make_spec.py`, compare the new `spec.json` key by key with the approved round's, and
  compare each view's mean colour over the model's pixels (within 1 of 255 when only the layout changed).
- **A model only for looking at:** `Archivable = false` keeps it out of saves, publishes and Play. SurfaceAppearance has a glow now
  (`EmissiveMaskContent`, `EmissiveStrength`, `EmissiveTint`).
- **A freshly uploaded mesh can look invisible for a few seconds** after a place rebuild. Look again before debugging.

- **Fixing made-up text in AI pictures** (rulers, 2026-10-17): erase each dark glyph plus 3 px around it (AI text
  carries a light halo that otherwise shows as a pale blob), fill from the surrounding pixels without wrapping round
  the picture's edges, then letter real numbers at the ruler's measured angle, tops toward the ticks. Compare
  before/after at 2x. Menu pictures of the town: Studio captures, then Codex draws from them (`codex exec` in a
  scratch folder, ~4 min for three pictures, free on Alan's plan); tell it "no text, letters or numbers anywhere".
- **A full menu-sheet build repacks every sheet of a group** (2026-11-18): adding one piece to a full build moved all
  seven menu sheets (seven re-uploads) and, with 8 pieces added since the last pack, made nine. To add a piece, use
  `tools/ui_sheets.py --add folder/name`: it goes into free space on a sheet already loaded and only that sheet changes.
  (The tool used to crash on the self-cut chest atlas after wiping its folder; fixed: it skips pictures with no
  `uploads/` record and deletes nothing until everything fits, and keeps the upload record of any unchanged file.) To show one packed piece at full size
  without a repack, drop its line from `src/first/UISheets.luau` (the original upload loads instead), but that loads the full original:
  more to download (Alan 2026-11-18: load time first; undone the same day).
- **`ui_sheets.py --upload` rewrites the whole "3d" list from today's `UIAssets`** (2026-11-18): after `--add`, it also
  switched 9 pictures added since the last pack (report card included) to the 3D drawing, a change nobody had checked
  in Play. Compare the `["3d"]` line in `git diff src/first/UISheets.luau` and keep only the intended change.
- **`TextScaled` with a `UITextSizeConstraint` caps in screen pixels, not sheet units** (2026-11-18): under the sheet's
  scaling a capped 52 drew as 70 sheet units on an 801-tall window and 52 on 1080p. Pick a fixed `TextSize` (sheet
  units) instead; the Missions goal picks 52 or 42 by length.
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

- **Merging a branch into main doesn't push to GitHub** (2026-11-11): git runs no post-commit hook for a merge, so
  run `python tools/push_github.py` by hand after `git merge`. A test of the menu ids with `PreloadAsync` on id
  text says "Failure" even for good pictures; check `IsLoaded` on a picture label instead.

## Making 3D models
- **Size a skin by what players see, then check it on the tall bodies** (2026-11-18): equal target size (outlines from
  above, side and behind added) let flat skins grow far wider than the Cardboard and Toilet Roll Gunships, whose deep
  fuselage is most of their target (Ninja 1.8x, Race Car 2.1x the plane's share of the chase view). Before proposing any
  size rule, measure plain vs skinned chase-view share on those two bodies and on Swift Fold with Swept Wings.
- **Hanging one model under another: trace the touching patch, don't box it** (2026-11-19, guns under big skins): a
  weapon's top is a cup, two hooks or a ring, and its bounding box touched the skin by corners the top never reaches
  (0.15-stud floats). Store the real outline as strips; touch by the crown (the top 1.5%), since rims sit lower; read a
  height grid by the highest of the four nearest cells (the nearest cell or a blend floated guns on slopes and walls);
  check hiding with a whole cell to spare; refuse spots with a wall or gap under the patch. Sweep every body x wings x
  weapon x slot with rays on the exact triangles (fine enough for thin clips: 40 rows missed the crayon's band).
- **Tripo's API** (2026-11-15): `tsk_` keys (`TRIPO_API` in `.env`) work only on `https://api.tripo3d.ai/v2/openapi`
  (balance: `GET /user/balance`); the v3 address `openapi.tripo3d.com` says "Invalid API key". Plain Python requests
  are blocked (Cloudflare 403, code 1010) until they send a `User-Agent`. API credits are bought separately from the
  website's free plan: the key had 0, so free tests run on the website. Its multi-view mode takes front, left, back
  and right only.
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
  concept wins over old in-game templates. The full method (read the camera, measure every part, surface, line and
  colour, show Alan the sheet, then build and lay the model over the picture) is the `concept-to-blender` skill
  (`.claude/skills/concept-to-blender/`), made after the Origami Crane took four passes (2026-11-13).
- **Meshy fuses thin parts.** It turns wires into flat blades and makes every model one fused shell. Anything
  thinner than about 2% of the model's length, or anything that must move, gets built in Blender instead.
- **Meshy melts railings, rulers, crayons and pencils.** Every building gets a close-up sheet
  (`tools/art/closeups.py`) and melted parts are replaced through `touchup.json` before anyone sees it.
- **Plain Blender vertex colours show correctly in Roblox.** Pieces built from plain shapes with per-face colours
  avoid texture smudges and moderation risk.
- **Concept pictures are game renders, never photos** (Alan, 2026-11-07, on the four new weapons): "they need to look
  like they are in a roblox game". Give Codex the approved reference picture as the style and show the piece in the
  game's scene (a gadget under a paper plane's wing over the toy city), stylized and chunky, not a product photo on a
  plain background.
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
- **Plane pieces collide as boxes** (2026-11-11): every `AircraftPieces` MeshPart has `CollisionFidelity` Box, so a
  raycast measures its bounding box, not the paper. For an exact fit check (guns against wings), build the planes in
  a scratch folder in Edit, set the copies to `PreciseConvexDecomposition` and `CanQuery`, wait a moment, then cast;
  delete the folder after. Require a fresh copy of a changed module (`Clone()` it beside the original) or Edit runs
  the cached old one.

- **Putting a whole plane together in Blender** (2026-11-13, skins tests): the `paper-set` FBX pieces import centred
  on zero at a hundredth of a stud. Place each one by the CFrame and Size `Aircraft.build` gives it in Studio Edit
  (read `Appearance`, then destroy the test model); no flip is needed (a nose narrows towards -z). Scripts:
  `.planning/skins/tests/` (`pieces.json` holds two builds).
- **Codex picture job with a reference picture** (2026-11-13): `codex exec -s workspace-write - -i ref.png < prompt.txt`,
  with `-i` last (it takes several files). About 45,000-80,000 Codex tokens for 2-5 pictures.
- **Matching views of one model: paint over renders, once** (2026-11-15, Dragon six views): render the Blender model
  straight on from each side and have Codex paint each render (one job, all views): the outline stays 95-99% the
  same, so the views agree. Painting a painting again blurs and "fries" it (Alan): the final pass starts from the
  render every time, and approved paintings go in only as guides ("copy the legs from this").
- **Tripo multi-view with a flat flyer: feed it nose-up** (2026-11-15, Dragon): its four views (front, left, back,
  right) are all level, so they see the wings edge-on and Tripo guesses the wing shape (narrow blades). Turn the
  pictures so the nose points up and give it top, right side, bottom, left side as front, left, back, right
  (`.planning/skins/dragon/six-views/tripo-noseup/`); the model comes out standing on its tail, turned back in Blender.
  In Tripo Studio the cube icon is "Multi-view Images to 3D"; the stacked-pictures icon is "Batch", one model each.
- **Judge a skin from the player's view first** (2026-11-15, Alan on the Tripo Dragon): behind and above the plane
  (`render-chase.png` in `tools/art/sheet_model.py`) is what players stare at; six straight-on views never show it, so
  a model that matches all six can still fail there. Paint a concept of that view too and compare it before the rest.
- **Projecting paintings onto a model: what breaks it** (2026-11-15, the Tripo Dragon). (1) A painting made over one
  model's renders does not fit another model: outlines a few percent apart smear every thin part; paint over renders of
  the very mesh being painted. (2) Even then the generator keeps outlines only 94-98%, so thin, slanted pieces (struts,
  fin rims, ribs) streak: paint those by code, piece by piece, and project only onto broad smooth pieces. (3) Never
  fill the holes in a painting's outline before projecting: sky seen through a gap (under a horn) lands on the model
  as paint. (4) A back-face twin that shares its other side's spot on the skin must not be painted again (it
  overwrote gold with cream). (5) Blender's Smart UV with a 0.004 gap used only 40% of the picture; a 0.0015 gap and
  undersides at 0.6 size gave 825 texels per length instead of 650.
- **Tripo Smart Mesh, as delivered** (2026-11-15): parts are separate shells (the Dragon: 63 pieces), wing skin is ONE
  sheet (same colour top and bottom unless it gets a twin), about a quarter of the faces are buried and never seen,
  some faces point the wrong way (its material is two-sided). Its own texture is soft but sits exactly on the mesh:
  good as a flat colour guide and as the start picture for painting. Export (GLB) is free on Pro; the first click on
  Export sometimes does nothing, the second starts a ~20 s "Exporting" bar.
- **AI 3D tools paint flat on purpose** (2026-11-15): Tripo's high-detail texture (with "Remove Lighting" on) is plain
  colour; its look comes from light on sculpted shape plus its bump and metal pictures. Copying only the colour onto a
  low-triangle mesh gives flat paint. The working route is the standard bake: bump picture from the high-detail shape,
  and crease darkening plus edge brightening (Blender's ambient occlusion and pointiness) baked into the colour.
- **Tripo multi-view: every view at ONE scale** (2026-11-15): four head views each scaled to fill its own frame came
  back 20% too wide and tall; size each direction to our piece's box afterwards, or better, render all views at one
  scale. "Generate in Parts" cannot be combined with texture. A 4K textured H3.1 model costs 55 credits.
- **Painted skins want a matte finish, and a preview light that shows the paint as painted** (2026-11-15, Alan on the
  Dragon: "wrapped in plastic"). A painting already has its highlights; shine on top doubles them. Measure a preview
  against the reference by mean colour of gold and green before showing it: ours was 2.3 times too bright. Light the
  preview evenly from all round plus a sun, or faces turned down go dark brown and look like a paint fault.
- **Parts that touch wear one skin and share one outline** (2026-11-15, the Dragon's body beside its head; Alan:
  "fully inconsistent", then "a huge visible seam", then "not seamless"). Matching average colour and scale size does
  not hide a join: two scale designs meeting in a straight cut read as a seam, and so do two tubes whose outlines
  differ (12 flat sides against a smooth oval change the light and the silhouette). What worked: take size, colour
  and bump depth from the accepted neighbour, not from the sheet; lay ONE pattern across both parts by a shared
  layout (how far along, how far round), written into each part's own pictures; make the new part's first ring a
  copy of the neighbour's outline, corner for corner, and ease to its own shape further on. Render the join close up
  from the side, above and below BEFORE showing anything.
- **Reading a back line under fins: the notches between fins are the fins' feet, not the back** (same day): that
  reading sat 0.011 too high and buried the fins. Read the scales' top edge on a ruled zoom.
- **A generated repeat pattern is cut from its middle** (same day): the swatch's first column at the picture's edge
  was incomplete, and a tile cut there gave every belly plate a blunt tip. Codex's second swatch run also cost 107,000
  tokens against 47,000 for the first: quote a range.
- **Tripo multi-view: a row of things seen from two sides becomes a block** (2026-11-15, the Dragon's leg): four
  views that each showed three claws came back as nine claws, 3 by 3. Level views 90 degrees apart cannot show a
  slanted row. Give Tripo the part without the repeated pieces (plain cones are quicker built by hand), or expect to
  keep one diagonal and paint the rest over. A 2K texture costs 45 credits instead of 55 and is plenty for a small part.
- **Roblox Studio's texture generator** (2026-11-15): Fast = 1K colour, pale; Quality = SurfaceAppearance with colour,
  roughness and metal, real detail but its own design (it ignored "gold"); the hint picture argument failed through the
  Studio tool. Good for generic props, not for an approved design.
- **"Photocraft" for texturing is a mix-up; the tool is Modddif** (2026-11-15, looked up for Alan): PhotoCraft
  (photocraft.tech) is a free flat-image editor with no AI and no 3D. Modddif (modddif.com, web app) is the AI tool the
  2026 tutorials use after Tripo: load the mesh (GLB), give reference pictures, it paints from 8 views onto the model's
  own unwrap and lets you repaint one bad area at a time; free tier 2K, 150,000 triangles, projects PUBLIC (paid 4K;
  prices not verified). Untested by us; it is the same idea as our projection, done by a tool built for it.
- **TextureCraft is a free hand-texturing app, not AI** (2026-11-15, Alan installed it; getartcraft.com, Learning
  Machines): like Substance Painter: bakes AO/curvature from a high-detail mesh (`bake.highPoly.add`), smart materials,
  edge-wear/dirt/curvature generators, fill by part, paint with symmetry, exports colour/normal/rough/metal. No
  auto-unwrap (UVs come from Blender). It has a command line and an MCP server (`texturecraft-cli commands`), so it
  can be scripted. Installed on D (Alan's C is full): program `D:\TextureCraft\app` (MSI with
  `INSTALLFOLDER=...`), data and exports in `D:\TextureCraft\data` and `\export` (its Preferences "Data folder").
- **Before building a part, find the LATEST approved picture of it** (2026-11-15, the Dragon's legs; Alan: "that's
  the wrong leg ... we redid the legs"). Claude measured the legs (and the tail fan) off
  `model-sheets/dragon-b8-legs.png` because a handoff named that file for the wing; the design had since moved to the
  six final views (`.planning/skins/dragon/six-views/final/`, folded legs). Check the decision page for the newest
  "picked" entry and the newest picture folder, lay the part's crop from every candidate side by side, and show Alan
  the reference crop before the build, not after.
- **Do not send a simple, flat part through an image-to-3D tool** (2026-11-15, the Dragon's wing; Alan: "why did you
  feed it back through Tripo?"). Tripo earns its credits on sculpted detail (horn steps, plates). On a wing (bars and
  a sheet) it only re-guesses a shape we already had, fuses neighbours and roughens edges, and the bake copies every
  flaw. Ask per part: does it need sculpting, or only a correct outline plus paint? Outline-plus-paint parts are built
  from the reference picture and textured on top (paintings projected onto flat faces, or TextureCraft).
- **Pale and cream paint is not gold**: a metal mask taken from colour must test for strong yellow (saturation), or
  cream skin turns into dark metal.
- **Cycles shows through twin faces lying on each other** (transparent back faces); preview one-sided meshes in Eevee
  with backface culling.
- **Creature skins: brief them in plane words** (2026-11-14): "deep belly", "chunky", "muscular" made Codex draw fat,
  living sharks and dragons (Alan: "they're paper airplanes"). For more body under the wings say "a barrel like a jet
  fighter's fuselage, straight bottom line, not fat". The same image tool refuses "violent" pictures at random (shark
  teeth): ask for "a fun cartoon grin of small simple white triangles" and let it retry.
- **A small change to an approved sheet: edit the pixels, don't redraw** (2026-11-14): a Codex redraw asked to change
  only the Dragon's legs changed their whole look ("looks worse"); cutting the legs out of the approved sheet and
  pasting them further back (patching the gap from the band beside it) kept every other pixel and was approved at once.
- **Painting a model from an AI model sheet** (2026-11-14, `tools/art/sheet_model.py`): the sheet's views never line
  up exactly, so blending two views on one spot (by its normal) turns teeth and belly into noise; paint each spot from
  one view and cross-fade only in a thin band where two tie (a hard per-triangle switch leaves a zig-zag). A depth test
  tighter than a few pixels fails in speckles on steep faces: test whole faces. **The real cause of the Shark's
  scrambled belly:** cream bellies and white teeth are nearly the sheet's background grey, so a colour-difference
  outline has holes there; fill holes (background = only what the box edge reaches). The sheets also draw a thin
  white halo round every shape: a model's outermost edge picks it up as a white rim unless edge colours come from a
  few pixels inside. A view that doesn't draw a part (horns seen from below) must not paint it. And `blender -b
  --factory-startup` keeps the 2-unit default cube: delete it, or it hides a model built at unit length.
- **Count a sheet's pieces where left and right don't overlap** (Alan, 2026-11-14, on the Dragon head): from above
  the sheet has 3 pieces a side; the build had 6, because blades were counted in the side view, where the far side's
  pieces peek over the near side's, and then mirrored. Number every piece in every view first (the
  `concept-to-blender` skill's piece map). Also: points read off a zoomed sheet by eye land 3-6 px off (snap them to
  the drawn edge), overlapping plates of one colour can't be split by colour, and blades made from a few numbers
  (base, tip, width) can only be straight daggers: trace the outline.
- **Judge a model's parts one at a time, in close-up; a whole-model picture hides wrong details** (Alan and Gemini's
  review, 2026-11-15, after 14 Dragon rounds): the outline scored 0.83-0.93 while legs, fins and wing ribs were plainly
  off, because at whole-sheet size a leg is 40 pixels. Build one module alone and compare it with the same crop of the
  sheet (`match_views.py`); check sizes, thickness and attachment by numbers off the mesh (`sheet_tools.py numbers`),
  never by eye; list the sheet's impossible drawings (a fin laid flat for show) before building; never add an extra
  piece to fake a view. Blender-only looks (Freestyle lines, shader nodes) don't reach Roblox: paint them into the
  texture. The `concept-to-blender` skill has the steps.
- **A model sheet's views can contradict each other: ask Alan which view wins before building that piece** (Dragon,
  2026-11-14/15). Horns: top and front views high and spread, three-quarter view low and swept back (he chose the
  three-quarter). Tail fan: upright in the side view, flat in the top and bottom views (he chose upright; "a drawing
  error"). Guessing cost two rebuilds.
- **Gold armour pieces are thick ridged tubes, not thin traced plates**: six sides with the corners turned 30 degrees
  (`phase`), a `roll` so the face lies on the sloped surface, across and up radii read from two views
  (`tools/art/sheet_model.py`). Thin plates read as petals; this won the blind comparison on the Dragon's head.
- **A strut thinner than half the skin it lies on disappears inside it.** Thickening the wing skin to 6.5 px swallowed
  the gold struts; keep a strut's height just proud of the skin all the way to its tip.
- **Read outlines in numbers, not off zoomed crops by eye.** `.planning/skins/dragon/body-fable/profile.py` prints the
  side outline, sheet against model; a crop read with the wrong origin put the Dragon's belly 8 px too high.
- **The independent reviewer is good on clutter and thickness, unreliable on angles and sizes.** It asked for horns
  less upright, then preferred the more upright round in a blind pair. It agrees with the outline scores on the scored
  views: check its other claims against them.
- **Look at the texture picture itself, not only the renders** (Dragon, 2026-11-15). Painted wing detail stayed
  invisible for 14 rounds because the unwrap cut every gold facet into its own island: the 1024 picture was mostly
  gaps and the wings got about one texel per sheet pixel. `sheet_model.py`: `uv {angle: 66, margin: 0.004}` makes
  fewer, bigger islands, and `texel: 1.6` on a part gives a surface the player looks at more of the picture.
- **Lines drawn on gold read as scratches; bake the shadow instead.** `sheet_model.py`'s `ao` has Blender bake how
  hidden each spot is and multiplies that into the colour picture, so plates that overlap, rings tucked into each
  other and gold meeting green all get a dark crevice that reaches Roblox. `facets.highlight` puts a light line on
  raised edges and keeps dark lines for inward creases only.
- **Find out what a "wrong piece" in a flat view really is before moving it** (Dragon, 2026-11-15). The spike between
  the horns in the front view was read as a back fin; `mesh.npz` showed the tallest thing on the middle line was the
  upright tail fan, 500 px behind the head. Print each part's highest point before changing any.
- **Pasted review lists can reverse each other; say so before building** (Dragon, 2026-11-15). Claws went back, down
  and back, hooked forward, then straight back again; wing veins in, out, in; fin caps wide, slim, wide. Each list
  goes in the decision note with what it replaces, and Alan's own typed words outrank a pasted list (he approved the
  tail while the pasted list asked to remove what the tail causes).
- **Painting a smooth model from its sheet: four traps** (Shark Jet, 2026-11-16, `tools/art/sheet_model.py`).
  (1) A piece one view does not draw (wings in a side view) must hide nothing in that view (`unseen`), or it cuts a
  jagged strip out of the paint behind it. (2) A flat fin or wing is told its views (`paint`): left to choose, triangles
  part-hidden behind the body took another view's picture, and near a swept edge the corners' blended normals picked
  the top view. (3) A piece standing where another view draws a flat copy of something (the fin's lens on the fold box)
  takes its paint from a view that is clean there. (4) Two views never give one colour the same tone: let the bottom
  view take the belly (`bias`), because the side picture's cream goes grey at its edge. Also: when two views disagree on
  how tall a strip looks, ask what shape under it makes both true (a sloped shoulder) before moving the strip.
- **A needle nose cannot show a face head-on; do not fake it with geometry** (Shark Jet's smile, 2026-11-16). The nose
  shows the front its skin at about 10 degrees, so a grin painted for the side is stripes head-on. I cut the head's
  sides into fine steps (forward faces for the front picture, side faces for the side grin): head-on it matched, but
  at every angle in between both pictures showed at once as lines, and Alan called it what it was, a visible break.
  What he accepted in the end: the smooth painted head, and the front picture's smile painted on the underside of
  the nose, each underside point given the colour the picture has where that point is seen from dead ahead
  (`.planning/skins/shark/build/front_face.py`). When Alan names the route (Codex redraws the view), take that route
  first, and when he calls something a defect do not offer it back as a trade-off.
- **In a picture brief the approved picture is the design, not a guide** (eight Legendary sheets, 2026-11-16). I sent
  Alan's two approved concept pictures along but described each skin in my own words and added my own shape rules;
  Codex drew the words (eight wrong sheets, about 470,000 tokens). Cut each item out on its own, say "draw this exact
  thing, unchanged", let the words only list what is in the picture, and look at the cut-outs before sending. The
  picture tool's filter refused "stealth", "fighter", "ninja" and weapon words, and a cut-out that still carried the
  written name: paint the name out.
- **A picture that must read from ahead needs a steep surface to sit on** (Shark Jet's chin, 2026-11-16). The smile on
  the needle's underside (above) read from ahead and was a smudge from below ("that's still mangled"): a surface seen
  at 9 degrees stretches its paint six times when you look from the other side. What worked, in the P-40's way: a chin
  under the snout with a steep front (about 75 degrees), the mouth's front third laid round it. Four things each cost
  a round: (1) a band that wraps a corner is painted along the surface (how far round, how far down), never from two
  projected pictures, which disagree at the corner; (2) the chin's front must be rounded like a boat's bow, because a
  flat front with square corners makes the teeth jump in size at the corners and looks like a plate from below; (3)
  teeth sampled from the sheet's soft pixels blur when seen large: draw them crisp (tooth white or mouth dark by
  brightness) and give that patch more of the picture; (4) a half-faded band is a grey smudge: fade it all or
  nothing. In `tools/art/sheet_model.py`: `extra_stations`, `bottom_exact`, `uv.focus`, `paint_script`.
- **Nothing goes to Alan before an independent reviewer has seen it** (same day: "are you even using a visual qa agent
  that looks horrible"). I showed a rough mock-up, a separate box laid over the model, that only I had looked at. An
  idea is shown built properly or not at all; the reviewer (an Opus subagent, the pictures and Alan's words only,
  never my opinion) runs on every preview, and its "no" is fixed first. It found the square chin and the tooth jump
  that I had passed twice.

## Studio and the place file
- **Edit-mode MCP `require` returns the module it loaded first**, even after Rojo synced new source. To test a fresh copy,
  clone the ModuleScript into the same folder under a new name, require that, destroy it (rewrite its own
  `WaitForChild` names if it requires a module that also changed).
- Rojo live sync brought the Ninja's bone names and part sizes into Edit with empty mesh IDs. A full Rojo build preserved those IDs. For a live-synced rig, load the configured mesh, copy its bind bones from the template, and check the equipped plane and its collision mesh in Play.
- In the Legendary trail FBX, Roblox put the glass wake's 13 independent bones under a separate root part. The uploaded mesh still retained its weights. Read the bone names and rest frames from the mesh, confirm each bone influences vertices, and attach those binds to the mesh template. `tools/art/fetch_trail_assets.py` does this for the wake.
- **Test players are plain tables** (2026-11-16): `player:GetAttribute` in a server path the unit tests reach errors there
  (FlightService.spec failed twice). Guard Studio-only player reads with `typeof(player)=="Instance"`.
- **Fresh code in Edit without a restart** (2026-11-16): Edit keeps old `require` results; clone the module under a
  new name in the same folder (and rename the generated modules it requires) to run the synced version, then delete the clones.
- **Runtime skin looks (2026-11-13):** `AssetService:CreateSurfaceAppearanceAsync` rejects uploaded pictures ("ColorMap
  value should be an EditableImage Content", NormalMap too), and an EditableImage is ~4 MB per 1024 picture. Make
  SurfaceAppearances ahead in an `.rbxmx` instead (Rojo live-syncs their maps, unlike MeshId). `AssetService:
  CreateMeshPartAsync(Content.fromUri(mesh))` does work on the client, and `MeshPart:ApplyMesh` swaps a mesh in place.
- **Open Cloud FBX uploads can take over 40 s** (2026-11-13): `tools/upload_texture.py` now polls 2 minutes. A run that
  stops on "still processing" saved the operation in `upload-tmp.json`: poll that operation for its asset id, never
  upload the file again.
- **A Play session whose window is behind others can sit on the loading screen** (2026-11-13): client modules started
  late in `Bootstrap.client.luau` (DevTools, PlaneLooks) have not run yet. Test a module by requiring it and calling it.
- **`ImageColor3` multiplies the picture (2026-11-12).** Setting the colour you want as the tint of a cream paper
  picture comes out darker and yellower: the shop's faded chalk green (104,133,118) showed as olive 98,117,96 in Play,
  and Alan disliked it. Tint = target / the picture's own colour x 255, then read the colour off a screenshot.
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
  a piece that fails goes in `WALLS` in `tools/town_toys.py` (see-through mesh + plain invisible walls). Again
  2026-11-12: the tape-roll tower's roll had its left half's hole filled (Alan folded in it every time); the walls
  are the good half measured with rays and mirrored. The porthole, binder rings and ruler stilts were checked open.
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
- **The MCP's `require` is its own copy (2026-10-28):** a module required from `execute_luau` in the Client VM is a
  separate instance from the game's, so patching it (e.g. `ScreenFit.kind`) changes nothing in the game. Test through
  attributes the game reads (`DevPhone`, `DevTouch`, `DevCover`, `DevScreen`, `DevLesson`).
- **AbsolutePosition and Position count from different tops (2026-10-28):** in a ScreenGui that ignores the inset,
  `Position` offsets count from the screen's top, but `AbsolutePosition` counts from under Roblox's top bar (the
  ScreenGui's own `AbsolutePosition` is (0, -58) on a phone). Subtract the ScreenGui's `AbsolutePosition` before mixing
  them; `WorldToViewportPoint` already counts from the top. Unsubtracted, a dodging note sat 58 points high over Health.
- **Right after Play starts, the viewport can read 1 x 1 with RenderStepped 0/s even with Studio in front**
  (2026-10-28): wait a few seconds and measure again before blaming the window (Alan: "studio is upfront").
- **Python heredocs turn `\n` into a real line break inside Luau strings** (twice, 2026-10-28: "Malformed string"):
  put `\n` escapes into Luau with the Edit tool, and loadstring-check every synced file.
- **Pressing keys in a Device Simulator Play switches it to keyboard** (PC words, no touch buttons): set `DevTouch`
  on ReplicatedStorage.FlyFightPaper in the Client VM before using `user_keyboard_input` (K skips lesson steps).
- **"The test tool's clicks stopped landing" was a real bug (2026-10-29):** the Hangar's Back and Customize ignored
  taps because the hover grow (1.05x) switched the phone tap area off mid-tap (fixed in `PaperUI.tapArea`). When a
  tap does nothing, log the button's `InputBegan`/`Activated` before blaming the tool. Device Simulator taps: a
  `user_mouse_input` click at (x, y) reaches GUI space at about (x - 62, y - 20) and `TouchTapInWorld` at (x - 62, y + 38).
- **No publishing while Alan is away from his PC (2026-10-29):** the desktop-control approval box shows only on the
  PC, and `FlyFightPaper-WORKING.rbxlx` lags Studio by days (art lives in the online copy), so an Open Cloud publish
  of the file would roll art back. Publishing waits for Alan at the PC (Publish As > Overwrite).
- **A ScreenGui made with `Instance.new` stacks by global layers (2026-10-29):** a button's word on layer 1 under a
  layer-6 button is hidden (the Tutorial's Close). Raise the word with the button, or set `ZIndexBehavior` Sibling.
- **A few files into Studio without Rojo (2026-10-28):** `python -m http.server 8765 --bind 127.0.0.1` in `src/`, then
  in Studio's Edit VM `script.Source = HttpService:GetAsync("http://127.0.0.1:8765/client/X.luau")` (works from the MCP;
  compare byte counts, check by requiring a clone). Stop the server after.
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
- **A 3D picture aimed at its box's middle still looks off-centre (2026-11-12):** perspective makes the near end
  bigger, so it pokes out of its circle. Centre the corners' on-screen spread instead (`UnlockMoment.view`'s `turn`).
- **Edit-mode `screen_capture` shows only the 3D world (2026-11-12):** no ScreenGuis (CoreGui ones neither) and no
  ViewportFrames, even inside a SurfaceGui (the SurfaceGui's own frames do show). To picture a part as a menu shows
  it without Play: build it in the world far from the map, camera at the picture's own angle (pass
  `camera_position`/`look_at_position`; a scripted roll is lost), post effects off, shoot it on a black then a white
  SurfaceGui sign (LightInfluence 0) and cut it out from the pair. The first shot after building can miss new pieces:
  take a throwaway shot first. White comes out 223 (tone curve: 0, 8, 31, 62, 97, 130, 158, 181, 199, 213, 223 for
  0 to 255 in tenths); undo it before cutting out. Put the camera, field of view and effects back after
  ([design examples](design-examples.md)).
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
  running; if Alan started it, read-only checks only. Even in a Play I started, he may join in and fly: before
  opening a test screen (`DevUnlock`) or sending mouse input, ask whether he is playing (2026-11-11: a test backpack
  popped over his match and a test drag went into his game).
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
- **Two children with the same name: `FindFirstChild` returns only one** (2026-11-14, the crane drew grey): giving the
  crane a printed sheet made `skin_looks.py` write a second `origami_crane` folder, and `SkinShapes` found the one without
  its `Shape` look. One folder per id; check a generated model's names are unique.
- **A picture drawn over a button does not stop its clicks** (2026-11-13, Customize tabs "click on and off"): the
  index tabs tuck under the binder page, and a click on the page beside the cards turned the tab hidden under it.
  `Active = true` on the ImageLabel did not help; a see-through `TextButton` over the page (drawn before the cards)
  takes those clicks. Find it by clicking the edges of tucked-under buttons in Play and logging which one fires.
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
- **Fitting a camera shot to the screen (2026-11-20, the winners' shot):** on a phone `Camera.ViewportSize` is only
  the notch-free middle (749 x 381 on an iPhone 17 Pro) while the 3D picture is drawn on the whole screen (873 x 401);
  an empty ScreenGui with `ScreenInsets = None` reads the whole size. `WorldToViewportPoint` counts from the
  notch-free middle's corner (negative x is in the strip), and a default ScreenGui cannot draw in the strips, so
  clamp anything pinned to a 3D point. Fit a shot both ways (width and height), never by width alone.
- **Alan's "laptop" view is not what most players see (2026-11-20):** the simulator's "Current device" is Studio's
  own pane, 2.55 times wider than tall here; a framing judged there is far looser on a 16:9 screen. Check HD 1080
  in the simulator's computer list too. Switching device works in the middle of a Play; a code change needs a new
  Play. Desktop control: ask for `robloxstudiobeta.exe` by name (the "Roblox Studio" entry alone shows no window),
  and the first screenshot minimises Alan's other windows and Studio itself (restore Studio with `ShowWindow`).
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

- **TextScaled turns off if TextWrapped is set false after it** (2026-10-29): `label.TextScaled, label.TextWrapped =
  true, false` leaves TextScaled false (words never shrink). Set `TextWrapped = false` first, then `TextScaled = true`.
- **Studio MCP `instance_path` clicks miss buttons in a frame with a UIScale and a centred AnchorPoint** (2026-10-29:
  the dev panel's "end" buttons). Fire the button's remote from the Client datamodel instead, or click real
  coordinates. A small Studio window counts as a phone (`ScreenFit`, under 540 points tall): PC layouts can't be seen
  in it.

- **Run the full tests in the background and poll** (2026-11-07): a long `TestRunner.run()` call through Studio MCP can
  fail with "Target is not reachable" though the tests are fine. Start it with `task.spawn`, write the result to a
  workspace attribute, then read that attribute in a second call. Check `get_studio_state` before any Edit call: Alan
  may be in Play, and a start-Play call then does nothing.
- **Unit tests in Edit, no Play (2026-11-11):** clone `ReplicatedStorage`/`ReplicatedFirst`/`ServerScriptService`
  `FlyFightPaper` and `ServerStorage.FlyFightPaperTests`, rename the real ones aside, run `TestRunner.run()` in a
  `task.spawn` that writes a workspace attribute, then restore the names. 35 of 39 suites run; ProfileRuntime,
  RewardQueue, RoundRuntime and ProfilePersistence fail to load in Edit (ProfileStore's `BindToClose` is server-only),
  so they still need Play. Saves grabbing Alan's mouse for a quick check.

- **Exact collision shapes cost phone load time** (2026-11-07): making 510 small rug toys solid with exact shapes took
  the phone's "town arrived" from ~10 s (v402) to ~40 s (v493); every part stores its own shape and phones download it
  with the town. Small toys collide as plain boxes (`ALSO_SOLID`). Read `LoadLog.recent()` after any change to the town.

- **Studio MCP drops the reply to long server calls** (2026-11-08): `execute_luau` on Server answered "Target is not
  reachable" for calls that waited (tests, a minute's sampling) though the code ran; short calls through
  `tools/studio_cli.py` kept working. Start long work with `task.spawn`, write the result to a workspace attribute and
  read it in a short call; for bot matches use `tools/run_bot_matches.py` in the background.
- **After any bot code change, fly a one-minute bot match and read the errors** (2026-11-08). The unit tests never run
  `BotService:steer`, and menus have no bots, so "471 passed, no errors" hid a brake check that errored every frame
  (`x and y and z` gives `false`, not `nil`, when `x` is false): every bot stopped steering and flew into walls.
  Alan saw it in the first veteran match. Check `kills`, `collision` and `LogService` errors after 60 s.
- **Attack a bot change before any match** (2026-11-08): list how each new rule misfires in real play first. The first
  Ace matches were wasted: all three Aces got the same build (the test hands builds out in a fixed order), the Crayon
  stand-off braked itself into easy prey, and "fire within the gun's range" loosened the old 450-stud limit. Ask what a
  real player would do (Alan: players shoot whenever they see the targeting ring). Per-bot hit rates in a one-minute
  match show a broken build fast: the Crayon Tank hit 2% while others hit 20-30%, which exposed that a bot's second gun
  had always aimed with the first gun's lead.

- **A pop-up's dim must cover the whole screen** (2026-11-12): a dim frame sized to the 1920x1080 sheet stops at the
  sheet's edge, so wide screens keep bright side borders (Alan spotted it). Make it 3x the sheet, offset one sheet up
  and left (`HangarCustomize` Not enough Paper note).
- **Studio dev switches must skip the unit tests' stand-in players** (2026-11-12): the `DevAccountLevel` switch also
  rewrote the test fixtures' profiles, so two ProfileRuntime tests failed until it checked `typeof(player)=="Instance"`.
  Run the tests after adding any Studio-only switch to profile loading.

- **"Owned" for a part means `Catalog:owns(ownership, id, level)`** (2026-11-12): free gear (0 Paper) is yours from
  its level and is never written into the save's `ownership`. The fold card checked `ownership` only and offered Alan
  the Thumbtack Shooter he had, for 49 R$. Any new "do you have it?" check goes through `Catalog:owns`.
- **`ImageColor3` multiplies the picture** (2026-11-12): tinting the cream circle with chalk green 104,133,118 came out
  olive 98,117,96 on screen. Pick the tint by the colour on a Play screenshot, not the number in the code.
- **Driving menus from `execute_luau`** (2026-11-13): the tool's code has its own module cache, so `require`ing
  MenuController gives a copy where `Menu.show` is nil; set the player attribute `DevScreen` ("shop", "home") instead.
  `VirtualInputManager` is refused there. `user_mouse_input` clicks work, but an `instance_path` click missed buttons
  inside a ScrollingFrame and a note: read the button's `AbsolutePosition + AbsoluteSize/2` and click those coordinates.
- **An overlay's darkening is its own Frame** (2026-11-13): the gift moment's `PaperUI.screen` cover colour at 0.5 didn't
  show over the main menu board in Play captures; a separate black "Dim" Frame (ZIndex 0, under the sheet) did.
- **Cutting a picture on a slant with no new upload** (2026-11-13, the gift box's lid): an `ImageLabel` showing a box
  of the picture (`ImageRectOffset/Size`) plus a `UIGradient` whose Transparency steps from 0 to 1 hides everything
  past a slanted line. Measured: the gradient's direction turns in screen pixels, and its 0..1 runs along the line
  through the label's middle in that direction, edge to edge (`min(w/|cos|, h/|sin|)` long). Its Color can shade the
  kept part along the same direction. Two such parts make a V cut (`GiftMoment.luau` `group`). Squashing the label
  unevenly moves the cut off the picture's line: grow such parts evenly.
- **Edit-mode captures show StarterGui screens, not CoreGui** (2026-11-13): a test ScreenGui in `StarterGui` appears in
  `screen_capture` without Play (good for layout and gradient tests; delete it after); one in `CoreGui` doesn't.
- **Studio captures are JPEG pictures** (2026-11-13): `screen_capture` hands back JPEG data; saved under a `.png` name,
  ffmpeg refuses the frames (PIL opens them anyway). Save frames as `.jpg` (`tools/film_gift.py`).
- **`PaperUI.fitWords` once per label** (2026-11-13): it hooks the label's Text changes itself; calling it again on
  every change stacks hooks. `say()` without `grow` already attaches it.

- **Placing a menu piece: measure it on the real art first** (2026-11-18, Missions strip under the plane): compose the
  screen from `assets/ui/*/ready/` pictures at the code's boxes (Fit inside the box, turned about its centre like
  `PaperUI.image`), then measure the gaps between the pictures' visible pixels, not the boxes. Never move a piece Alan
  approved to make room (the pinned plane's fly-in lands where it is).
- **Overlapping UI pieces need ZIndex set** (2026-11-18): Roblox draws siblings with equal ZIndex in no fixed order, so
  a card picture drew over its own words and squares in Play though it was made first. Paper 0, words 1, marks above.
- **Roblox shrinks and squashes pictures without smoothing** (2026-11-18): torn paper edges go jagged when a picture
  is drawn much smaller or squashed (an 866-wide tab drawn 220 wide; a 1000 x 236 strip drawn 1069 x 164). Draw
  pieces near the size they are stored at; a bigger master picture makes it worse.

## Working with Alan
- **A Codex "model is not supported with a ChatGPT account" error means an old Codex program, not his account**
  (2026-11-18, GPT-6.2 Sol): the Codex plugin runs the `codex` on PATH (`D:
pm-global`), which was 0.159.2 while his
  Codex app was newer. Fix: `npm i -g @openai/codex@latest`, then shut the plugin's running helper the plugin's own way
  (send `broker/shutdown` to its pipe, named in its `app-server-broker.mjs` command line) so the next job starts fresh.
- **A Play report: ask how he did it before diagnosing, and answer his own suspicion first** (2026-11-16, Dragon). He
  said shots that looked like misses hit him; Claude blamed the "Dev: skin" button ("I was equipping it in the hangar"),
  then asked about a side cause ("has nothing to do with what I said"). He suspected the collision: check that first,
  with evidence (the server's hit shape against the drawn one), then raise other causes in one sentence each.
- **Quote sizes from the shapes the game uses** (2026-11-16): plane outlines from default collision boxes told Alan the
  Dragon would be 1.3-1.45x the plane; on the exact hit shapes it was 0.96-1.48x. Measure on PreciseConvexDecomposition
  copies (as `tools/skin_sizes.lua` does) before giving a number.
- **No little cardboard tabs as buttons** (Alan, told twice; 2026-11-13 on the Skins tab's Cancel): buttons are paper
  and tape (`Art.buttonGreen`, `Art.buttonRed` and the main menu's taped strips), never `Art.tab`.
- **A row under a card stays inside the card's edges** (Alan 2026-11-12, report card jar row, four looks): line pieces
  up with the card's left edge, middle and right edge; a piece hanging past an edge reads as "uncentred". Measure it in
  page pixels before showing (card 0..680 wide; middle 340).
- **"Make the words bigger" means clearly bigger** (Alan 2026-11-12: "I just told you to make that text larger"):
  on a selling piece the main lines (heading, amounts, price, time left) at least 30 px at 1080p (Alan OK'd 32-44;
  21-26 was "too small to read"; the 18 px floor is for reading, not for selling), and
  grow the paper rather than shrink a line. Same for buttons: a buy button gets its own look and movement.
- **Screen grabs only when there is no other way** (Alan 2026-11-12): read layouts as numbers first (`AbsolutePosition`,
  `GetGuiObjectsAtPosition`, `ScreenCheck`), prints, rays. A grab is allowed only when it is truly blocking.
- **To catch something in Alan's own Play, put a temporary print in the code before he starts** (2026-11-12): Rojo
  syncs it, Studio's Output keeps the line after Play stops, and `studio_cli.py get_console_output` reads it from
  Edit. A watcher started by hand once Play is running misses moments (Alan: "You're not that fast"). Remove it after.
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
- **Play started right after a save can miss it (2026-11-06):** a run reported 454 tests when the new test made 455. Check the
  test count went up, or read the script's Source in Edit, before trusting a run started just after an edit.
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

- **Reading a live save (2026-11-05).** Studio in edit mode can list save stores but opening one says "Access forbidden". From a running Play server (`execute_luau` with `Server`) `GetAsync` on `Player_<id>` works, read-only; Play itself still uses the throwaway profile.
- **Before judging aim from hits, record whether the shot was on the ring (2026-11-06).** A hit count mixes the game's
  accuracy with the pilot's aim. `DevShotLog` now marks RING or free; only RING shots test the game. To measure screen
  delay, record server positions and compare them on the client against the drawn positions at each delay: it gave one
  clean answer (0.18 s) and no pilot was involved.
- **Edit-mode `require` keeps old code (2026-11-06).** Studio's Edit VM caches a module for good, so a fresh change looks
  missing. Clone the code and tests into a temp folder in ServerStorage, point their paths at it, run, delete it: most
  tests run with no Play and no mouse grab. Three suites need a real server and two need plane models.
- **Stacked see-through layers can make a hard edge (2026-11-07).** Same-width layers at 1-2% strength all round to
  nothing at the same spot. Give each a different width. A faint overlay also has to be judged over the bright town,
  not a dark road; `screen_capture` doesn't show a StarterGui overlay from a moved camera, so judge it in Play.

- **Words must sit inside what they're on** (2026-11-08, Alan, more than once): check text against the art under it, not
  just that it reads. Centre the letters, not the line: Kalam Bold's letters fill only 0.16-0.66 of a line (to 0.83
  with a p or g), and a torn-paper picture's visible part is smaller than the picture (the stat label's: 2-98% across,
  7-88% down; measure the PNG's alpha). The Hangar's stat names show the method (`LABEL_INK` in `Hangar.luau`). Then
  measure the gaps in a Play screenshot. Roblox caps TextSize at 100.
- **Never `git stash` while Rojo or Studio has the repo open (2026-11-08):** on Windows it stopped half-way ("unable to
  unlink ... Invalid argument"), leaving 4 files changed and 8 reverted. Recovered with `git checkout stash@{0} -- <files>`
  and `git diff stash@{0}` (empty = same). To see an old version use `git show HEAD:<path>` instead.
- **A quality fix keeps the pictures (2026-11-09, Alan rejected a try):** "make it crisp" means the same art, sharper.
  Scrubbing painted tacks/tape off a picture leaves marks and loses their shadows, and code-drawn replacements look
  generic. Fix how a picture is drawn (its box's shape), never what it shows; show one piece before changing many.
- **9-slice bends anything that crosses a slice line (2026-11-09):** a painted tack across the line became a teardrop at
  every SliceScale tried. SliceCenter counts from the ImageRect cut (works with the menu sheets). Under a UIScale the
  corners did not come out at the size SliceScale x pixels predicts, so check by eye.
- **Preview a picture in Studio without uploading (2026-11-09):** copy the PNG into the running Studio's
  `%LOCALAPPDATA%\Roblox\Versions\<version>\content\textures\<folder>\` and use `rbxasset://textures/<folder>/<file>.png`
  (loads in Play; Studio only; delete the folder after). Find the version from the RobloxStudioBeta process path.
- **Measure stretch (2026-11-09):** in Play, for every shown ImageLabel/ImageButton compare its AbsoluteSize shape with its
  ImageRectSize shape (the menu sheets set it): `(w/h) / (rectW/rectH)` off by more than 10% is a stretched picture.
  Open screens with the `DevScreen` player attribute. 2026-11-09 menus: 60 of 151 off; worst the Customize part cards
  (0.40), the Ask note's X (0.26), both Back strips (about 0.5), Customize stats paper, shop strips (1.6).
- **The crayon words draw copies, so a size cap must reach them (2026-11-09):** `PaperUI.crayon` hides a label's own
  letters and draws three copies. A `UITextSizeConstraint` on the label capped only the hidden letters, so every scaled
  label (stat numbers, cubby names, gear names) drew at its whole box's size. `crayon` now copies the cap. A cloned label
  (`card:Clone()`) loses the link to its copies and keeps showing its old words: draw the look again on the clone.
  The copies must take the label's ZIndex too: in a ScreenGui with `ZIndexBehavior` Global (TouchControls, FlightHUD)
  copies left at 1 draw under whatever the label sits over (FIRE's crayon fill on Alan's phone, 2026-11-11).
- **A picture at its own shape is smaller than its box (2026-11-09):** with `ScaleType.Fit` the paper no longer fills a
  box of another shape, so words placed in the box land off the paper. Give every box the picture's own shape and place
  words inside the paper's measured area (sticky notes: paper 16-95% down, tape 42-67% across down to 30%).
## Printed-sheet skins (2026-11-16, the eight Commons)
- **A steep face takes the SIDE picture, not TOP.** Every body's raised middle ridge (crest y 1.40, slim 1.24; side walls
  stop at 0.95 to 1.0) is painted from SIDE, so a stripe drawn only in TOP is cut in half by it (Racing Stripe). Anything
  that must cross the ridge is also painted in SIDE from y 0.97 up. Measure before guessing:
  `.planning/skins/tests/faces/faces.py` lists every sheet-copy face with its view and position.
- **FRONT is shared by the blunt nose's flat face and every back-facing edge** (nose_2: |x| < 1.3, y -0.85 to 1.4, 7 square
  studs; wing, booster and tail ends). A design's nose colour goes in that box only (Flame Decal's dark cap).
- **Preview a skin on the blunt nose and the tube body too**, not only the starter: `MORE=1 ONLY=starter,blunt,heavy2`
  with `tools/art/skin_preview.py`.
- **Random patterns: spread them evenly and count the share.** 8-Bit took three passes (39% bright in clumps: "too much
  purple", none on the nose; 75%: "like rainbow"; 50% in four colours: good). Offer two options side by side on the redo.
- **Random blocks get the hooked-cross scan** built into `skin_sheets.py` (`eight_bit`), as well as a look.
- **Changing the skin list touches five places:** `config/looks.json`, `config/commerce.json` (one `look_<id>` product
  each), the counts in `Looks.spec`, `Commerce.spec`, `CommerceService.spec`, `ProfileService.spec`, and the Skins tab's
  room (it scrolls from 11 skins up).

## Moving skin layers (2026-11-16, Studio Edit test on the Lava plane)
- **A Decal draws over a SurfaceAppearance on a MeshPart, but it ignores the mesh's own picture layout.** It stretches its
  picture over each piece's own box, seen from the Decal's `Face`, and only on the sides that face that way (`Top`: the
  up-facing sides; body sides and undersides show nothing). Seen from above with the piece unturned, the picture comes out
  half a turn round: its top-left corner is at the box's +X, +Z corner. I first read a tie-dye test as "it follows the
  sheet" and built the Rares' layers on that; on real planes Lava's cracks came out about four times too small. Put a
  picture with words on real pieces before trusting a layout. `SkinMotion.decal` corrects each piece from its template's
  place and size in `Assets.AircraftPieces`.
- **Where a Decal's picture lands:** turn(`UVScale` x (box spot - middle)) + `UVScale` x middle + `UVOffset`, the turn
  being `Rotation` degrees clockwise about the middle. The scale comes before the turn, so a turned picture keeps its
  shape only if its patch is square: pad placed pictures to squares.
- **Scripts can change a Decal while the game runs:** `UVOffset` (slide), `UVScale` (size), `Rotation` (turn),
  `Transparency`, `EmissiveStrength` and `EmissiveTint`, and the pictures themselves. A SurfaceAppearance only lets a
  script change `Color`, `EmissiveStrength` and `EmissiveTint`: its pictures cannot slide.
- **A Decal's picture does not repeat past its edge: the edge pixels smear.** To loop a slide, draw the pattern twice in
  the picture, zoom in (`UVScale` 0.5) and slide half a picture, then start again. A small picture with a see-through
  border can be placed anywhere (`UVScale` above 1): the smear is see-through.
- **Decals stack by `ZIndex`**, and a new Decal can take a few seconds to appear in Edit: wait before the screen grab.
- **A Decal's glow keeps the picture's own colours** (colour x glow picture x tint x strength), and see-through pixels in
  the picture work. With no glow picture, use the colour picture itself: it then glows by its red.
- **A layer Decal also sits on a shape skin** (Edit test on the Dragon's one mesh, 2026-11-16): `Face` Top covers every up-facing
  surface of the whole model's box, a second Decal with `Face` Bottom covers the underside, its glow works, upright sides keep the
  skin's own paint. So a Legendary can carry Rare-style moving layers. Not yet run as the game's own code in Play.
- **Movement on a Legendary, from five preview rounds** (2026-11-17, `.planning/skins/motion/preview.py`): at the chase camera's size a
  subtle change is invisible (thin pulses, blue-on-blue glints: make one big clear thing); paint that moves on flat wings is edge-on
  from behind, so give the back of the plane something (nozzle fire); a burst must go outward and back, never up into the view ahead;
  wet is darker, not paler; a shine that goes with spray moves at the spray's speed (Alan: "its lagging behind it"); uneven
  frame-to-frame change reads as a bug, steady drift reads as movement. Eevee's first frame differs: render one warm-up frame.
- **Movement that follows the paint is a flipbook** (2026-11-17, `.planning/skins/motion/layers.py`): a Decal cannot be masked by
  another picture, so "only the painted flames roll" or "a comet runs down the lines" cannot be one sliding picture. Draw 16 frames
  of the whole box seen from above in one 4 x 4 picture (4 px of see-through edge inside each 256 px cell); the Decal zooms to one
  cell and a second Decal fades the next frame in. Movement that ignores the paint (a shine streak, a water line) stays one sliding
  picture. Layer pictures are drawn tail at the top, nose at the bottom, wing tip to wing tip across: no quarter turn needed.
- **Check a rebuilt effect against the approved video frame by frame, same moment, side by side:** the Shark's water line came out
  twice as wide because the mock-up's line only fades behind itself (a wrapped "seconds since" is never negative).
- **Never type a `#` note in the middle of a line of several statements** (second time, 2026-11-17): everything after it on that
  line is switched off. Notes go on their own line.
- **Pure-logic tests run in Studio Edit without Play:** copy the spec into a fresh ModuleScript beside the others and
  `require` it from `execute_luau`; copy any module that changed since Studio last loaded it (an old copy stays cached).
- **Rojo's file watcher can hold a `src/` file for a moment:** a script's write fails with "Invalid argument"; retry.
- A `Texture` (the repeating kind) did not show on the same MeshPart.
- **Drawing for movement (the Rares' preview videos):** shapes in a sliding picture lie across the slide, not along it (a
  streak sliding along itself looks still: Lava's first flow). A round thing that crosses the body's step is cut in two
  (Galaxy's first big orbit): keep placed things on one wing. When the moving part is the skin's main look (Slime's goo),
  make that layer solid, paper included, so the still sheet under it never shows through as a second copy.
- **Stills say nothing about movement to Alan** ("I would need like a GIF or a video"): `tools/art/skin_motion.py` makes
  the video on real planes with no upload.
- Build a test plane in Edit from `Assets.AircraftPieces` (pieces sit in plane space), the sheet copies
  (`Generated.SkinPieces`, `CreateMeshPartAsync`) and `Assets.SkinLooks`; give the test folder `Archivable = false` so a
  save never keeps it, and delete it after.
- **Never `git add -A <folder>`**: it swept an old untracked file (`tools/art/hero.py.old`) into a pushed commit. Name the
  files.
- **A game script may not set a Decal's glow picture (found in Play 2026-11-16).** `Decal.EmissiveMaskContent` needs plugin
  rights; `ColorMapContent`, `UVOffset`, `UVScale`, `Rotation`, `EmissiveStrength` and `EmissiveTint` can be written, and a
  clone of a ready-made Decal keeps its glow picture. Every Edit test and preview ran with plugin rights (the Studio
  link's code does), so all eight Rares passed there and none moved in real Play. Anything a look sets that is new to
  Roblox gets proved from a real LocalScript in Play before it counts as working: the Studio link can make one
  (`Instance.new("LocalScript")`, set `Source`, parent it to `PlayerScripts`), and it runs with a game script's rights.

## Trails (2026-11-16, the first three as 3D videos)
- On Shark Jet, two rows of floating teeth were hard to read as a bite. Keep the teeth attached to upper and lower jaws with one hinge, and keep the closing motion inside the first part of the wake visible to the pilot.
- **Four rounds of videos for three trails; start the next ten where these ended.** Alan turned down, in order: flat
  pictures seen from above ("bad ... We need to make them 3D"), a turning ribbon ("a 2D banner that's rotating"), cotton
  balls ("purple bubbles"), wound cords ("a bunch of streamers attached to a plane") and thin scattered pieces ("more
  body"). He OK'd a dense cloud of 3D pieces with small filler round them (Gold Stars) and thick soft smoke (Storm
  Sparks, Holo Rainbow). Build each new trail as one thick body first.
- **Check the player's own seat before sending.** The chase camera sits 24 studs behind the plane and the trail is about
  105 studs long, so the player sees only the newest quarter. A colour change that runs once along the whole trail shows
  one colour from the seat (Holo Rainbow was all pink): repeat it (`rainbow`: 3 in `config/trails.json`).
- **More pieces do not make a body.** Foil crystals at 170 a second still read as scattered bits from alongside; soft
  smoke cards at 90 a second read as a solid plume.
- **Look for a picture Roblox already ships before drawing one.** The soft smoke and the sparkle glint are
  `rbxasset://textures/particles/smoke_main.dds` and `sparkles_main.dds` (the game already used both): no drawing, no
  safety sheet, no upload. A piece under half a stud (the foil flake) is a plain block. Three trails needed two uploads.
- **Desktop control hides Alan's other windows and cannot see Studio (2026-11-16).** The computer-use grant for "Roblox
  Studio" does not cover the running window (`robloxstudiobeta.exe` on D:), and its first screenshot hid every other
  open app. Alan declined the second request. When Studio will not draw (viewport 1 x 1, no frames), stop Play, clear
  DevMute and hand him a what-to-look-at list; do not reach for desktop control.
- **Judge a new trail against an approved one at the same moments.** Two stills (frames 36 and 126: your own seat, then
  alongside) of the new trail beside the same two of Gold Stars show at once whether it is as full; stills alone made
  the piece trails look too thin when they matched what Alan had OK'd. Ten trails' stills take about two minutes,
  three at a time; fix what they show before any full video.
- **A glow colour clips.** The glow look multiplies the colour by 9, so any channel over about 40 of 255 goes to full:
  a green needs its red and blue under 40 or it turns cyan.
- **Twinkling glints read as glitter, whatever their colour.** Dragon Embers with orange sparkle dust: "just looks like
  orange glitter". Fire is flame shapes that rise and taper (bright core, orange, red, then smoke) and embers are round
  dots that cool as they rise; keep star glints for stars and sparkle.
- **A cloud must not drown the theme.** Circuit Trace on a smoke core was "mainly cloud": when the idea is an object
  (a circuit, a flock), build the body out of that object and leave the smoke out or faint.
- **An almond shape with a crease can be misread as a body shape.** The first petal was one; it was reshaped as a
  teardrop before the safety sheet went to Alan. Look at every new model's flat view for this.
- **A dismissed question is not a yes.** Alan closed the upload question without answering: nothing was uploaded and
  the question went into the handoff.
- **Read a new model's way up from its vertices, not from a picture.** A model uploaded from these Blender tools arrives
  lying flat with Blender's up as +Z and Blender's +X as -X (`CreateEditableMeshAsync` on the note: its head, the heavy
  end, sat at -Z). `PlaneTrails.STAND` carries that for `upright` pieces; anything that must fly nose-first needs the
  same check.
- **A bare zigzag line can be read as a rune.** The circuit's bent trace (straight, a 45-degree step, straight) got a
  short branch and a third pad before upload, so its flat view is plainly a circuit.
- **A flat card in Blender needs Object coordinates** for a round fading patch (Generated gives nothing on a flat quad),
  and Eevee's "Shadow buffer full" lines are harmless: send the output to a log and read only the last lines.

## Scripted Play tests (2026-11-16, the skins and trails check)
- **A sleeping screen stops Studio drawing.** Alan's PC turns the screen off after 60 idle seconds: the view reads 1 x 1,
  `RenderStepped` gives 0 frames, and trails and skins freeze while the server plays on. Asking Windows to keep the
  screen on (`SetThreadExecutionState`) did not hold from a background PowerShell; a one-pixel mouse nudge every 20
  seconds did (user32 `mouse_event`, there and back). Alan, 2026-11-16: "you are going to have to keep it awake while you
  need the screen drawing": start the nudge before every Play that must draw, and stop it after.
  Count `RenderStepped` frames before every measurement, not only at the start.
- **The `loop` autopilot keeps its place in the route through a respawn**, so a new plane steers from its desk at a far
  corner and flies into the town two seconds after takeoff, every life. Clear `DevAutopilot` on TAKEOFF and set it again
  once flying (the looks check's client half does).
- **Compare looks inside one flight.** Where the plane happens to be moves the frame rate more than a trail does: one
  short run read 51 with Confetti and four later ones read 60. Switch the looks on and off every 13 seconds, several
  times round (`ClaudePart` = `ab`), and add the runs up.
- **The Studio link's own code keeps old copies of modules it has `require`d** for as long as Studio stays open: an Edit
  read showed 3 trails when the game had 13. Clone the module (and what it requires) and require the clone.
- **Looks forced through a plane's `Skin` and `Trail` attributes reach the drawing only**: the server's hit shapes for a
  shape skin follow its own record, and a respawn puts the plane's own looks back until they are set again.
- **One error printed hundreds of times fills the log the Studio link can read** (about 300 lines): quieter warnings
  behind it are lost. Fix the loud one, then read the log again.
- **Studio hands out frames of 0 seconds** (2026-11-18: four in 19 s with Studio behind other windows). Anything divided
  by `dt` turns infinite: every plane taking off got an infinite speed, Roblox deleted it, and the pilot left behind
  broke FlightService's loop every frame (bots vanished, the player's plane stuck on the runway). Every step loop
  skips `dt<=0`.
- **Getting a scripted plane through a speed pickup:** moving the plane trips the anti-teleport check ("came
  unfolded") or a crash; move the invisible pickup box onto the plane for a quarter second instead (server, on
  `Stepped`), then put it back. A bot-flown human plane rarely qualifies a match (2 minutes active and hits on 3
  planes), so end-of-match saving can't be checked that way.

## Cosmetic releases (2026-11-18)
- For a completed skin, check its card, the textured plane in Customize, the current acquisition path, Wear, and the plane after launch. Shark Jet had a working catalog row and could grant Water Spray before its body existed. For a trail, check its saved ID against the renderer and its route from a normal player account. The Studio selector draws effects that players can have no way to acquire.

- To check a reported menu flash, count removal of the book, stats sheet and card under the pointer while selecting. The previous Hangar destroyed all three on every click even when the camera's per-frame probe caught no empty frame. Hold a press across a profile refresh as well as checking quick clicks.

- Check preview orientation against the paper and the actual nose and exhaust on a screenshot. A camera looking downward verified the previous angle but missed that the plane pointed to the bottom of the page.

## Lighting one thing in a dark room (winners' spotlights, 2026-11-19)
- **Real lamps don't work at this game's size.** A Roblox light reaches 60 studs; a winner stands 140 tall and the group shot is hundreds of studs away. From there the lamps were not drawn at all, came on seconds late as the camera closed in, and burnt out white close up. Turning the room's 300 other lamps off changed nothing.
- **A dark overlay on the whole room (one Highlight on the Arena) looks muddy and cost a quarter of the frame rate.**
- **What works: darken the room with its own Lighting and draw the lit thing in its own layer.** A full-screen ViewportFrame whose camera copies the scene's camera each frame; avatars (layered clothing too) and their animations show in it, lit by the layer's own Ambient and LightColor. Dark-then-lit is the layer's ImageColor3 (dark Ambient alone left pale ghosts). A layer shows through everything, so fade it out before the camera turns away.
- **Put the avatar back to scale 1 inside the layer** and bring the layer's camera in by the same factor about the avatar's feet: the picture is the same and Roblox no longer doubles the hip movement of a scaled-up avatar (no per-frame hip fix needed).
- **Haze turns far dark walls into bright sky**, and `Options.applyQuality` puts the Atmosphere's density back every few seconds (the menu re-reads the profile). Take the Atmosphere out of Lighting while dark; put it back after.
- **A full-screen layer is pixelated (Alan in Play, 2026-11-20: "low resolution, pixely").** A ViewportFrame draws into its own picture, which developers report is capped at 1024 pixels on its longer side, drawn at the screen's logical size and smoothed only at the top graphics levels ([cap](https://devforum.roblox.com/t/viewportframe-rendering-shouldnt-have-a-resolution-limit-should-not-have-a-white-outline/305898), [quality](https://devforum.roblox.com/t/viewport-shows-low-quality/294154)); stretched over a 1920-wide screen, a winner gets about half the pixels across. **The way out (Alan's OK 2026-11-20; built, not yet run in Play): no layers.** The scale-1 winners, books and plane stand in the real room right in front of the camera, each point moved towards the camera by the avatar's scale: the same picture as the big ones far away, drawn at full sharpness, and lit by real spotlights, which do reach a 5-stud avatar. For a small winner standing at the big one's desk spot that move is one slide, `(camera - spot) * (1 - 1 / scale)`, done again every frame. **First Play run (2026-11-20): it works and is sharp** (real models, books, black shapes, the plane's flight; no errors), with one fault: **the real spotlights all came on together about 3.5 s after the camera arrived**, whatever their own time (3rd's 3 s late, 2nd's 2 s, 1st's 1 s; the shafts and name plates were on time). **Not fixed by `Camera.Focus` (same day).** The scene now sets the Focus to the winners' shot as the camera sets off (a scripted camera should; it was already following 20 studs ahead of the camera by itself). In the next Play session the FIRST winners' moment after joining was never seen (the recording caught another window) and the SECOND one was in sync, which I wrongly reported as the fix. **The first winners' moment of a fresh Play still lags** (run 3: 3rd black at their click, lit about a second later) and Alan saw the light **pulse between lit and too dim**; at brightness 5 he called them unlit, at 15 a pale avatar burns out and a black-clothed one stays dark. **Test the first moment after joining, never a later one.** **Alan's way out (2026-11-20): no real lights at all. It works** (first winners' moment after joining, muted Play run: each winner lit at their click by construction, steady, in their true colours, the black-clothed one readable; shaft and pool show in front of the sheet; the dark comes down and lifts smoothly; no errors). With 0.08 of the room showing the room was pitch black, so it is 0.15 now (not yet seen): a see-through GUI sheet darkens more than the same number in lighting. **Two follow-ups from Alan's look, both seen fixed in the next run:** (1) a black Highlight does not hide a model that is being faded in: half see-through, the winners showed lit for half a second (it only showed once the recording was brightened: brighten dark recordings before calling them clean); they now appear all at once as solid black shapes. (2) A flat Beam behind the winner read as a bad 2D strip; the spotlight is now a real cone: Roblox's classic cone mesh (asset 1033714, loaded on the client with `AssetService:CreateMeshPartAsync`, which works in a running Studio game; a live server is unproven), Neon, 24 nested layers from full width to nothing at 0.99 see-through each. One layer looks like a glass tube, four show stripes, 24 are smooth; no frame-rate cost seen. Options were built and pictured in Edit mode (temporary parts, `screen_capture` from the scene's own camera spot) before any Play. The haze also lay over the winner (milky; a white avatar glowed): see the next lines. The room's lighting is left alone; the dark is one nearly black, slightly see-through sheet (a SurfaceGui frame on an unseen part) that fills the view just behind the small winners, who stand in the room's ordinary light; unlit, each wears a solid black Highlight that comes off at their click; shaft and pool stand in the small winner's world, in front of the sheet. The lamps without shadows were never run.
- **To keep a see-through effect off a model, stand the effect further away, bigger (2026-11-20).** The winners are placed by scaling the real scene about the camera; the spotlight is the same scene scaled 1.8 times less, so it lands on the same pixels but behind the winner: no haze over them, and they hide it like a far wall would. Move the curtain back to make room.
- **Don't guess which way round a SurfaceGui lies on a part's top (2026-11-20).** A pool of light drawn on a copy of the desk top landed beside and behind the books: the picture ran a quarter-turn round from the guess. One Edit-mode picture would have settled it. Here the plain Neon disc, sized to fit the desk, was enough.
- **A cloned plane brings the HUD's outline Highlight with it,** and a Highlight on a part of a model beats the black cover on the whole model: strip Highlights from clones.
- **Judge only the first winners' moment after joining, and brighten dark recordings before calling them clean.** A second moment in one Play was in sync when the first was not; a half-second lit flash only showed once the frames were brightened (ffmpeg `eq=gamma=3.5`). Record with `-offset_x 0 -offset_y 0 -video_size 2560x1080` after bringing Studio to the front: the whole desktop is two screens and Chrome was on top.
- **A scripted cut from one marker to another can swallow code in between** (the scene's helper functions went missing and it still compiled: a missing local function is only a nil at run time). After a scripted cut, list the file's functions and compare.
