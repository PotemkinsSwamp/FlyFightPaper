# From a model sheet to a finished 3D skin: what works (research, 2026-11-14)

Asked by Alan after the Dragon-head tests ("we need to beef up our blender skill"). Sources are numbered at the
bottom; claims from vendor blogs or forums are marked as such. **Applied 2026-11-14 with Alan's OK** as the
[concept-to-blender skill](../../.claude/skills/concept-to-blender/SKILL.md), with its helper
[sheet_tools.py](../../.claude/skills/concept-to-blender/sheet_tools.py) (tested on its own and on the Dragon
sheet's pixels; no Blender build of the Dragon was run).

## Update 2026-11-15: rebuilt round the AI's weak spots (Alan, with a skill Gemini drafted)
After 14 Dragon rounds the structure was right and the details were not. The skill was restructured and re-applied
with Alan's OK. Demo on the Dragon's round 14: [close-up-demo/](close-up-demo/) (`close-legs.jpg` shows it best).
- **Taken from Gemini's draft:** each module built and passed alone in close-up beside the same crop of the sheet
  (`match_views.py`); the build's sizes, thickness and attachment checked by numbers off the mesh (`sheet_tools.py
  numbers`); the sheet's impossible drawings listed first and never marked down (`exceptions`: the Dragon's top-view
  score rises from 0.870 to 0.938 once the flat-drawn tail fan is left out); a card per piece with thickness and its
  size against its parent; reject rules (no plain primitives, no extra piece to fake a view); roots sunk in; one
  shared surface recipe per material.
- **Not taken:** Blender-only looks (Freestyle line art, shader nodes, displacement): Roblox gets one picture and
  4,000 triangles, so the look is painted into the texture. "Side and front views win" as a fixed rule: Alan ranks
  the views and rules on each clash. Shapes described in words ("cambered airfoil"): they are traced from the drawing.
- **Kept from before:** the piece map and count, tracing, the outline score, Roblox limits, Alan's OK before building.
- **Found while testing:** the Dragon's toes were built to a written rule (35% of the pod, curving down and back);
  the sheet's side view draws them about half the pod long (29 of 57 px), straight, lying along the body. The numbers
  check passes them on size; only the close-up shows the wrong shape and direction. Both checks are needed.
- Limits: `numbers` measures along each piece's own axes, so a strongly curved horn reads shorter than its drawn
  length; "attached" means some of the piece is inside another, not how deep; `match_views.py` needs a camera fitted
  per view, and a front view drawn at another scale (the Dragon's) lines up badly until its own scale is set.

## The short answer
0. **The biggest miss was not shape but pieces (Alan, on review).** From above, the sheet shows 3 pieces a side on
   top of the Dragon's head (two blades and the horn); the build had 6 a side (five blades and two horns), in the
   wrong places and pointing the wrong ways. Cause: the blades were counted in the side view, where the near side's
   and the far side's pieces stack on top of each other, and then mirrored, so they doubled. The method never made
   anyone find each piece in every view. **Fix, now step 2 of the skill for every model:** break the sheet
   into a numbered piece map, every piece marked with the same number in every view, counted per side in a view
   where left and right don't overlap (from above, or the front), with its direction and bend noted in two views;
   Alan OKs the map; one build part per map piece; a count check of the build against the map; a render with each
   piece in its own colour beside the map. Picture: [dragon-trace-demo/piece-map.png](dragon-trace-demo/piece-map.png).
1. **Split the work the way game artists do.** A smooth body is painted from the sheet (that already works: the
   Shark's nose). Anything that sticks out (blades, horns, fins, spines) is built as its own piece, and its shape is
   **traced from the sheet's drawing**, not made from a few numbers. Small flat-colour pieces get their colour from a
   tiny colour swatch picture, so the whole skin stays one mesh with one picture set.
2. **Why the Dragon's blades read as daggers:** our builder makes every blade from four numbers (base, tip, width,
   thickness), so it can only ever make a straight kite. The sheet's blades are curved leaves with hooked tips. No
   amount of tuning those four numbers gets a curve. The fix is to trace each blade's outline (below: tried today,
   it works) and build the plate to that exact outline, with a ridge down the middle so it shows a lit and a dark
   facet like the sheet's gold plates.
3. **Horns the same way:** trace the horn in the side view and in the top view; together they give its real 3D curve
   (rising tip and all), its thickness comes from the drawing, and each drawn segment line becomes a small step.
4. **Check with a number, not just the eye.** Lay the model's outline over the sheet's view and measure how much of
   it matches (a score from 0 to 1), with a picture showing where it is too big or too small. Research on AI
   agents that model in Blender agrees on one thing: they get good results only with a look-and-fix loop, and their
   own eyes miss small shape errors [1][2][3][4].
5. **Blender in a window (Alan's question):** yes, use it for the build-look-fix loop. It does not by itself make the
   same steps produce a better model, but each look takes seconds instead of a minute, the sheet's views can sit
   behind the model at the measured size (the overlay check becomes live), and some Blender tools only work with a
   viewport. The final build should still be the same script, so it can be re-run.
6. **AI image-to-3D generators** (TRELLIS, Hunyuan3D and others): not recommended as the main route. They make dense,
   messy meshes that melt thin parts (the same family as Meshy), and the good ones need more graphics memory than
   your PC has (a GTX 1080 Ti with 11 GB). At most an option for a rough proportions check; your call (table below).

## What I tried today
**Piece map** ([dragon-trace-demo/piece-map.png](dragon-trace-demo/piece-map.png), from the sheet's pixels): 8
pieces on the head, the same number in the top, side and front views. From above: 1, 2 and the horn 3 on each side.
From the side, one plate is the far side's piece 2 peeking over (2'), and a big plate 4 under the horn shows only
from the side and the three-quarter view, so the map asks: is 4 its own blade or the horn's base? That question is
exactly the kind the old method never asked.

The helper `sheet_tools.py` puts a labelled pixel grid on a zoomed crop, takes points read off it, **snaps each point
onto the nearest drawn edge** (like a magnetic lasso), draws a smooth curve through them and writes the shape in the
model's units. Result: [dragon-trace-demo/pieces-check.png](dragon-trace-demo/pieces-check.png) (top: side view,
bottom: top view). The horn's outline (blue) follows the drawn segments in both views, including the upturned tip;
the white line is its worked-out centre line. One crest blade (pink, right) is captured with its curve; the small
front blade came out too thin and needs its points moved, which is exactly the look-and-fix step the skill asks for.
Two findings:
- **Reading points off a grid by eye lands 3 to 6 pixels off.** On a 30-pixel blade that is the difference between
  a leaf and a dagger. Snapping fixed most of it; looking at the traced outline over the sheet catches the rest.
- **The gold plates can't be separated by colour automatically:** they overlap and share one gold, so a colour
  pick gives one big blob (tested). Each plate needs its points placed by hand, as an artist would trace it.
- The horn's side and top views disagree by 2.3% of the length along the body (the AI sheet; within the 3% we knew).
- **The outline score works on the earlier heads** (their side renders, read from disk): the hybrid head scores 0.87
  and the all-pieces head 0.87 (1.0 = identical outline). The picture
  ([dragon-trace-demo/score-hybrid-side.png](dragon-trace-demo/score-hybrid-side.png)) says where: the snout is
  drawn thinner than we built it (blue), and the crest's top edge and blade tips sit lower than the sheet's (red).
  It judges the outline only; inner lines and colours still need the eye and the reviewer.

## The recommended pipeline, step by step
1. **Sheet in good order.** Pick the master views: side for length and height, top for width. The front view only
   tells which way pieces face, never sizes (ours draws the head 1.6x too wide). For future sheets, ask for a flat
   background colour that appears nowhere in the design (bright magenta is the usual pick), so outlines come out
   clean; halos come from edge pixels that mix object and background, and the fix is to shrink the outline by a
   pixel or two [5]. Practitioners say the same about mismatched views: match the most finished view, use the others
   as guides, and check the result from in-between angles [6][7].
2. **Measure** (today's skill: camera, every part, shares of one length, Alan's OK on the measured sheet).
3. **Sort every part into one of three kinds:**
   | Kind | Examples | How it's made | Coloured by |
   |---|---|---|---|
   | Smooth body | head, neck, barrel, tail root | loft through the side and top outlines (`sheet_model.py`) | painting from the sheet's views |
   | Plate | crest blades, cheek guards, fins, wing panels | traced outline -> plate with a ridge (`sheet_tools.py plate`) | flat colours from a swatch picture, dark rim |
   | Tube | horns, spines, claws, tail spikes | side + top traced -> 3D centre line, width, joints -> tube with 5-6 flat sides | flat colours, joints darker |
   Blobby small parts (legs, paws) can use a "visual hull": extrude the side outline sideways and the top outline
   upward and keep only what both cover; it matches both drawings exactly but can't show dents the outlines don't
   show [8]. Blender 5's new Manifold boolean does that intersection quickly [9].
4. **Trace before building.** For every plate and tube: grid crop, points, snap, look at the check picture, fix,
   then show Alan the traced sheet with the measured one (the existing "no geometry before Alan's OK" rule).
5. **Build to the traced shapes.** One mesh, smooth shading on the body, flat shading on plates and tubes (facets
   are the look). Blender's own Curve-to-Mesh builds a tube with sharp facets automatically when its cross-section
   uses corner handles [10], an alternative to our hand-made tube.
6. **One picture set.** Body paint and plate colours share one 1024 picture: plates map their faces onto small
   colour squares in a corner of it (the "palette texture" trick from low-poly games [11][12]), so their colours stay
   crisp and use almost no picture space. The skin's bumps (scales) stay a normal map, as now.
7. **Fast look loop (Blender in a window):** reference pictures of each sheet view placed behind the model at the
   measured scale (Blender's own way of modelling from character sheets [13]); change a piece, render the viewport,
   compare. Full renders only at the end.
8. **Check:** outline score in the side and top views (aim: 0.9 or better on the part being built), the
   three-quarter overlay, the views from straight above and from behind (the game camera), colours, then the
   independent reviewer. Ask the reviewer short yes/no questions per part ("does the horn's tip curve up?"); a
   2025 study found that a vision model writing and answering check questions about the render corrected more
   mistakes than a general look [4]. Spend more on checking than on building: the BlenderGym study found extra
   effort pays off most when it goes to checking [2].
9. **Roblox check** (below), then show Alan.

## What to stop doing
- Making blades and horns from a handful of numbers (base, tip, width): it can only make straight daggers and cones.
- Painting by projection onto anything that sticks out. Blender's own bug tracker and forums confirm projection
  painting breaks down on faces turned away from the view [14]; the Dragon head showed it.
- Reading positions by eye without snapping and without looking at the traced outline over the sheet.
- Taking sizes from the front view.
- Judging only by eye. Our reviewers' size claims were off by up to 15% (lessons); the score is exact.

## What to try first on the Dragon head
1. Trace the five crest blades, the brow blade and the cheek blade in the side view, and both horns in the side and
   top views, with `sheet_tools.py`; fix the front blade's points; show Alan the traced sheet.
2. Each blade's tilt from the top view: how wide it looks from above compared with its traced width.
3. Build blades with `plate()` (about 60 triangles each) and horns as six-sided tubes with steps at the drawn
   segment lines (about 150 triangles each). The head comes to roughly 1,500 triangles with the body, inside the
   4,000 budget for the whole Dragon.
4. Keep the hybrid's painted skin (scales, eye, jaw): it was the closest face yet. Remove the stray drawn-gold
   scraps at the seams by also cutting out sheet pixels in the gold colour range (today only the built pieces'
   shapes are cut out).
5. Score side and top, overlay the three-quarter view, review, then show Alan beside the last three rounds.

## Blender in a window or headless scripts (Alan's question)
- **The same Blender does the same work either way:** quality comes from the method above, not from the window.
- **What the window adds:** the model stays loaded, so a change and a look take seconds instead of a fresh one-minute
  Blender start; the sheet can sit behind the model in the side and top views as a live overlay; tools that need a
  viewport (painting with stencils, knife-projecting an outline onto a surface) become available; you can watch or
  nudge it yourself.
- **How:** this session's Blender connection is Blender Lab's official MCP server (needs Blender 5.1; we have
  5.1.1) [15]. Blender must be open with its add-on running; today it was not, so I could not use it. Blender Lab
  warns the connection runs any code it is sent with no guard [15]: fine on your own PC for our scripts, worth
  knowing. The crane session found its window screenshots came back black; its render-to-file worked.
- **Keep the script as the record:** whatever is done live goes back into the build script, so the model can be
  rebuilt (AGENTS.md: one source of truth).

## Image-to-3D generators (for your decision only; nothing installed or run)
| Model | Licence | Graphics memory | On your 1080 Ti (11 GB) | Notes |
|---|---|---|---|---|
| TRELLIS (Microsoft) | MIT, free | 16 GB minimum [16] | No | strong general quality |
| TRELLIS.2 (Microsoft, Dec 2025) | MIT, free | 24 GB minimum [16] | No | newest, single picture only |
| Hunyuan3D 2.1 (Tencent) | Tencent community licence: not valid in the EU, UK or South Korea [17] | shape 10 GB, texture 21 GB [18] | Shape only, just | takes several views (2mv model: front, left, back [19]); can also texture a mesh we built |
| TripoSG (VAST) | MIT, free | over 8 GB [20] | Probably | shape only, no colours |
| Stable Fast 3D (Stability) | free under $1M yearly revenue [21] | about 6-7 GB (one source) | Probably | fast, textured, meant for background props |
What they give, from practitioners (several are vendors, so weigh them lightly): "generated" is not "game-ready";
expect messy, dense meshes, lighting painted into the colours, and invented details, then a full clean-up
(retopology, UVs, materials) [22][23]. For stylised hard-edged props with thin parts, parametric or hand building is
the usual advice [23]; our own Meshy lesson (thin parts fuse into blades) points the same way. **Where one could
help:** as a rough 3D proportions reference from all the sheet's views at once, or Hunyuan's painter colouring our
own clean mesh. Both would mean installing large free tools (several GB, Python and CUDA setup) that I have not
tested on your card; free online demos exist but send the sheet to a third party.

## Roblox limits that shape the method
- A mesh has **one material** and one set of pictures; every SurfaceAppearance map is 1024 at most; normal maps must
  be the OpenGL kind (Blender's kind) [24]. One mesh may have up to 20,000 triangles; our 4,000 per skin follows
  Roblox's limit for an avatar accessory [25][26].
- Meshes must be closed with real volume [25]: `plate()` makes closed plates with thickness (tested).
- **Flat facets in Roblox:** Roblox's docs don't say how it treats hard edges. Developers report the FBX importer
  keeps sharp edges while the glTF importer smoothed them (a forum bug report) [27]. Check one exported test piece
  in Studio before building on it (that is an upload: needs your go).
- Vertex colours already show correctly in Roblox (our lessons), so plain-colour pieces could use them instead of
  the swatch picture if that turns out simpler.

## How other AI agents model in Blender (the evidence behind the loop)
- **LL3M** (U. Chicago, 2025): a team of AI agents writes Blender Python; a critic looks at renders from several
  angles, a verifier checks fixes were applied, a library of Blender docs keeps the code correct. Code makes every
  part editable by name and number [1]. It still misses subtle spatial errors that a person points out [1].
- **BlenderGym** (Stanford, 2025): even the best vision models fail Blender edits a human finds easy; more effort on
  checking beats more effort on generating [2].
- **SceneCraft** (2024): builds a plan first, then refines from renders, and keeps a growing library of reusable
  functions [3] (our `sheet_model.py` plus `sheet_tools.py` are that library).
- **CADCodeVerify** (ICLR 2025): the model asks itself questions about the render and fixes what fails [4].
- **Reading shapes from views:** sketch-based modelling builds parts from outlines drawn in two or more straight-on
  views [8]; our tracing follows that idea per part.

## GitHub projects for AI-driven Blender (Alan asked: what's out there, read every file, copy what's good)
How they were read: four reader agents fetched every file as plain text through GitHub's website (nothing cloned,
installed or run) and listed every network call, code-running call and data upload. I checked the two most serious
safety claims in the files myself. **Honest limits:** in the most popular project the biggest file (the 334 KB
add-on) was searched for risky calls rather than read line by line, one packaged file there is a binary that can't be
read as text, and some long documentation files were skimmed. We install none of them, so that only matters if you
ever want to.

| Project | What it is | Results | Safety | Licence |
|---|---|---|---|---|
| ahujasid/blender-mcp (34k stars) [28] | the popular Claude-to-Blender connection: run code, screenshots, asset downloads | good look-and-fix loop; no modelling from pictures | runs any code sent to it (no password); sends usage data by default, switch-off setting exists (checked); can upload prompts, code and screenshots if you tick consent; self-updates without a signature | MIT |
| emeryporter/blender-mcp [29] | a separate rewrite with ~86 tools | weaker than its README claims | **dangerous: any web page you visit could run code on your PC through it** (open to all web origins and runs code; checked) | none |
| RobLe3/cc-blender-skill [30] | 30 Claude Code skills, tested on Blender 5.1.1 | modest (the author says so: "abstract avatar"); flat front-view tracing | clean: no network, no hooks | MIT |
| threedle/ll3m [31] | the LL3M paper's code | only a client for a server that has shut down; the real prompts were never published | sends your scene to their server and runs code it sends back | academic only |
| richard-guyunqi/BlenderGym-Open [32] | the BlenderGym benchmark | a test bench, not a modeller | runs model-written code; its setup clones a personal fork | none |
| kevinbadi/blender-skills [33] | product turntables, Meshy | nothing for concept-to-model | clean | none |
| Dev-GOM blender-toolkit [34] | Blender over a WebSocket, animation retargeting | basic shapes only | clean code, but installs software and changes Blender settings on its own when a session starts | Apache-2.0 |

**None of them does what our pipeline does** (piece map, tracing from several views, plates and tubes, an outline
score). Their good ideas, all rewritten in our own words in the skill (no code copied):
- Hard pass or fail gates in a fixed order: exact piece count, then outline score and named landmarks (tips, eyes),
  then other views, colours, reviewer [30].
- A clash check of the sizes two views share before building, with which view wins [30].
- Traced outlines are fixed: no bevel or smoothing may move them; points are true single points [30].
- The same failure twice means stop and rethink [30].
- One change per round: the single most visible difference, the script line that causes it, an edit in place [32].
- A before/after judge: two renders side by side in random order, "which is closer to the sheet?", logged against the
  scores so we know how far to trust the reviewer [32].
- Every round's script, renders and verdicts kept in its own folder [32].
- Contact sheets from cameras framed on the model's bounding box, all views in one picture [28].
- Live-window hygiene: read the returned render path, treat "Traceback" text as failure, look before retrying after a
  timeout, long renders in a background Blender from a saved copy so the window never freezes [28][30][31].
- A back and edge-on check of the painted skin, and a "does it face forward" check [30][33].
Rejected: installing any of them, their telemetry, their asset and AI-generator downloads, the 30-skill sprawl, flat
front-view tracing, and loose game budgets (they allow 10,000 triangles; we have 4,000).

## Where the strongest model fits
Most of the Dragon's shortfall came from the method (pieces never counted across views, a builder that can only make
daggers, projection on spikes, eyes reading pixels), and any model following the new steps gets that gain. The
independent reviewer stays another Opus agent (Alan, 2026-11-14).

## Uncertain
- The plate builder is tested for shape and closure, not yet seen rendered on the Dragon (that build was out of
  scope today). The traced front blade needs a second pass.
- How Roblox shows flat facets (above). The palette trick is standard in other engines; untested in our game.
- Blender in a window was not available today; it worked in the crane session.
- Image-to-3D quality claims come mostly from vendors; none tested here.

## Free tools worth installing (for your OK)
None needed for the recommended route: it uses Blender, Python, numpy, scipy and Pillow, all already here.
Optional later, only if you want the image-to-3D experiment: TripoSG or Stable Fast 3D (both fit your card on
paper). Not recommended now.

## Cost of this research
About two hours of one Opus session (about 450,000 tokens of context), plus four Sonnet reader agents for the
GitHub projects (about 800,000 tokens between them). No Codex, no credits, nothing uploaded or installed.

## Sources
1. LL3M: Large Language 3D Modelers (Lu, Chen et al., 2025): https://arxiv.org/abs/2508.08228 and https://threedle.github.io/ll3m (limitation on subtle spatial errors: summary at https://api.emergentmind.com/papers/2508.08228)
2. BlenderGym (Gu, Huang et al., Stanford, 2025): https://arxiv.org/html/2504.01786v1
3. SceneCraft (Hu et al., ICML 2024): https://arxiv.org/abs/2403.01248v1
4. CADCodeVerify, "Generating CAD Code with Vision-Language Models for 3D Designs" (ICLR 2025): https://arxiv.org/abs/2410.05340v1
5. Clean cutouts and halos (vendor blogs): https://rangy.ai/blog/ai-game-assets , https://www.promptzone.com/hyun_arellano/ai-background-removal-how-matting-models-work-and-fail-o85
6. Polycount discussion on matching the most finished view (forum): https://polycount.com/discussion/comment/1950703
7. CG Cookie, front and side views that don't match (forum): https://cgcookie.com/community/10090-knees-in-front-orthograhic-view-reference-image-lower-than-in-right-side-view
8. Rivers, Igarashi, Durand, "3D Modeling with Silhouettes" (SIGGRAPH 2010): https://www-ui.is.s.u-tokyo.ac.jp/~takeo/papers/alec_siggraph2010_silhouette.pdf
9. Blender 5.0 key features (Manifold boolean, SDF grid booleans): https://www.cgchannel.com/2025/11/blender-5-0-is-out-check-out-its-5-key-features and https://developer.blender.org/docs/release_notes/5.0/geometry_nodes/
10. Blender manual, Curve to Mesh node: https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/curve/operations/curve_to_mesh.html
11. Texturing low-poly art with colour palettes (Wintermute Digital): https://wintermutedigital.netlify.app/post/lowpoly-colour-palettes
12. One material per scene with a palette (indie devlog): https://papaya-games.itch.io/duck-in-town/devlog/73530/blazing-fast-rendering-with-a-single-material-per-scene
13. Blender manual, image empties as reference for character sheets: https://docs.blender.org/manual/en/latest/modeling/empties.html
14. Blender bug report on texture painting artifacts at grazing angles: https://projects.blender.org/blender/blender/issues/43735 ; forum on view-based streaks: https://blenderartists.org/t/texture-painting-based-on-normals-not-view-projection/1272609
15. Blender Lab MCP Server: https://www.blender.org/lab/mcp-server/
16. TRELLIS.2 model card (MIT; 24 GB): https://huggingface.co/microsoft/trellis.2-4b ; TRELLIS 16 GB (repo mirror): https://github.com/pb-coding/microsoft-trellis
17. Tencent Hunyuan 3D 2.0 community licence (territory): https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE
18. Hunyuan3D 2.1 memory figures (guide quoting the README): https://docs.clore.ai/guides/3d-generation/hunyuan3d
19. Hunyuan3D-2mv model card: https://huggingface.co/tencent/Hunyuan3D-2mv
20. TripoSG model card: https://huggingface.co/VAST-AI/TripoSG
21. Stable Fast 3D announcement: https://stability.ai/news/introducing-stable-fast-3d
22. "AI 3D game asset generator: what actually works in 2026" (vendor): https://www.summerengine.com/blog/ai-3d-game-asset-generator
23. "When image to 3D is not the right choice" (vendor): https://www.sloyd.ai/blog/when-image-to-3d-is-not-the-right-choice
24. Roblox texture specifications: https://create.roblox.com/docs/art/modeling/texture-specifications
25. Roblox general mesh specifications: https://create.roblox.com/docs/art/modeling/specifications
26. Roblox rigid accessory specifications (4k triangles): https://create.roblox.com/docs/avatar/rigid-accessories/specifications
27. Roblox DevForum, glTF importer smoothing sharp edges (bug report): https://devforum.roblox.com/t/gltf-importer-invalid-normals/2612421
28. https://github.com/ahujasid/blender-mcp
29. https://github.com/emeryporter/blender-mcp
30. https://github.com/RobLe3/cc-blender-skill
31. https://github.com/threedle/ll3m
32. https://github.com/richard-guyunqi/BlenderGym-Open
33. https://github.com/kevinbadi/blender-skills
34. https://github.com/Dev-GOM/claude-code-marketplace (plugins/blender-toolkit)
