# Shape skins: model sheets first, Shark Jet A and Dragon B, a barrel body (not a belly)

**Decided:** 2026-11-14 (Alan)  
**Status:** in force. The redrawn sheets and the Dragon-head test are on the [skins plan](../plan/SKINS-PLAN.md).

## Decision
- **How shape skins are made** (Alan, 2026-11-14, after the Origami Crane came out "decent but not what I wanted"):
  a full model sheet first (Codex pictures: the design flat from the side, top, bottom and front at one scale, plus a
  three-quarter view), measured with the concept-to-blender skill; then simple shapes in Blender, coloured by
  projecting the sheet's own views onto them; fine detail as painted colour plus a baked bump picture (normal map);
  glow, smoke and embers from Roblox's own effects, not modelled. **Proved on the Dragon's head first**, judged by Alan
  beside the sheet, before any full build.
  **Changed the same day (Alan, on the projected Dragon head):** "atrocious ... just unusable"; projection does not
  work on a crest of blades. **Build each piece as its own measured piece** (every blade, horn, the eye), coloured
  plainly (gold facets, green scales); the sheet gives sizes, places and colours only. Projection may still suit a
  smooth body with its art on the sides (the Shark: "I could maybe see it working").
- **Picks:** Shark Jet **A** (blue-grey, white belly) and Dragon **B** (emerald and gold, crest of fins), from
  `.planning/skins/model-sheets/`. **The Shark Jet's sheet is `shark-jet-a4.png`** ("that version of the shark works
  well"): a round jet fuselage with a cream underside, tapering to a sharp nose. **The Dragon's shape is
  `dragon-b6.png`**, the Dragon on the shark's airframe (head as the nose cone, gold underside), picked over a
  paper-keel version (`dragon-b5.png`). But its details came out like a shark's (tall back fins, shark tail): "the shape
  is correct, but you made it look like the shark". It keeps Dragon B's own details (head crown and horns, dragon
  spines, fanned tail, scalloped wings) on that shape. **Dragons have legs** (Alan): four legs tucked up as in flight.
  **The Dragon's sheet is `dragon-b8-legs.png`** ("Dragon is good"): `dragon-b8.png` with its front legs moved back by
  hand about a tenth of the length, behind a neck ("that's not where its foot would be ... it has a neck"); a redraw
  with jointed legs (`dragon-b9.png`) "looks worse". Its three-quarter view still shows the old front-leg spot.
- **The Dragon measured, OK'd for the head test** (Alan, same day): `.planning/skins/dragon/dragon-measured.jpg`
  (shares of its length; on the starter: head 4.6 studs, horns 3.5, wings 12.8 across). The build follows the side and
  top views (the sheet's front view draws head and body 1.6x wider). The body follows your plane's width (wider than
  drawn on every plane); the head keeps its drawn size and the neck widens into the body (he did not want the head to
  grow on big planes).
  **Then, for the head built with the upgraded skill (Alan, same day):** the sheet's SIDE view is drawn unlike the
  others and is the least trusted; build from the top, three-quarter and front views and use the side only for support
  (heights). Read that way, each side of the head has an accent blade ahead of the eye, two small horns above the eye,
  one big horn at the back, plus the eye, the gold trim under the eye that runs to the mouth, a cheek guard and the
  snout's gold rim. The big plate the side view draws under the big horn is left out (no other view has it).
  **The head rebuilt from thick ridged plates (Alan, same day, on `.planning/skins/dragon/head-fable/`):** "definitely an
  improvement" on the earlier head. Its dark definition lines were too strong (softened in its round 12) and it "just
  needs an accent and design pass". **He is willing to let the whole body be tried the same way.** That head builds the
  plate under the big horn after all, as the second small horn (the three-quarter and top views show it too). **The big
  horns are the one thing really off** (Alan, same day): "they come too far up and at an angle". They follow the
  three-quarter view: lower and swept back along the neck, less spread. The rest of the head is good enough to build the
  whole body from, with a tweaking pass at the end.
  **The whole Dragon (same day):** first build `.planning/skins/dragon/body-fable/round-07/`. **Alan on it:** a lot of
  detail is missing; the back fins do not match the reference; the tail is a little too large; the legs are very off; the
  scales read as fish scales, not a dragon's layered scales; the eyes are too large and angled too much; the wings lack
  detail. He wants a correction pass for structure and fine details, then a detailed pass. **Correction pass done:**
  `body-fable/round-10/` (picture `body-fable/sheet-vs-model.jpg`): fins traced point by point from the side view (gold
  arc, hooked tip, web curving in), tail rays 0.88 of their length, legs as scaled teardrops with two jointed claws,
  eye smaller and level, layered pointed scales, belly plate lines, wing veins and bar joints. One closed mesh, 3,582
  triangles; outline top 0.92, side 0.84.
  **Alan's problem list on round 10 (2026-11-15) and what he asked for:** (1) front: remove the green fin or web between
  the brow horns; two separate outward-sweeping gold horns in an open V; (2) legs: one smooth, unsegmented dark-green
  teardrop pod with exactly 3 sharp, separate, conical gold claws pointing to the tail, flush against the lower body
  from the front; (3) belly: no cross bands; one smooth tan surface from behind the chin to the tail with 2 subtle
  lengthwise creases; wing undersides solid warm tan with smooth gold struts; no gold chin; (4) back fins: from above a
  thick overlapping gold-and-green braid, from the side a thick gold leading edge over recessed dark green; (5) wing
  spars smooth and tapered with no joints, crisp leaf veins, dark outlines round every scale and where gold meets green.
  Built as `body-fable/round-12/`, with the tail fan laid flat to clear the front view.
  **Alan's second list (2026-11-15):** (1) **the tail fan stands upright in one flat vertical plane**, as the side view
  draws it; the sheet's top and bottom views draw it lying flat by mistake and are ignored for the tail; its root is
  pushed forward into the body's rear tip; (2) no gold wave down the back: only the 5 raised hook fins, each with a thick
  gold cap and a slight sideways curve, alternating; (3) legs built by a `create_detailed_leg()` function: a pod with the
  body's own raised scales and 3 large thick gold talons (35% of the pod's length, bases touching across the foot,
  curving down and back so the knuckles show under the body from the front); (4) wings with real thickness; the 3 gold
  struts start from one shared point at the wing root, have a diamond section and taper evenly to a sharp point at the
  back edge; no gold trim on the scalloped back edge underneath.
  **Built as `body-fable/round-14/`** (picture `body-fable/sheet-vs-model.jpg`): one closed mesh, 3,334 triangles,
  counts match the piece map. Still open from his first list: dark outlines where gold trim meets green skin. Not seen
  by the reviewer. Nothing uploaded.
  **Alan's third list (2026-11-15): no more whole-body passes; four parts rebuilt one at a time**, each checked alone
  in close-up before the dragon is put back together. (1) **Wings, the hero part** (the player mostly sees their top):
  three gold bones (front bar and two ribs) from one heavy gold knuckle at the shoulder, diamond in section, at least
  1.8 times as thick as the membrane beside them so they never sink into it, tapering to sharp points; the membrane a
  taut hide that sags between the bones, with tension ripples, a fine grain and a dark band where hide meets bone; **no
  leaf veins** (this replaces the "crisp leaf veins" of his first list). (2) **Horns and head armour:** no lines drawn
  on gold at all; the lines on the sheet are gaps and shadow between separate overlapping plates; each big horn is a
  base block and four tapered rings, each tucked into the one before, in a clean outward V; the back fins lowered so
  they do not stand between the horns like a third horn from the front, and no wavy gold tube down the back from
  above. (3) **Tail:** no blunt stump; from behind the hind legs the body narrows smoothly to a sharp point inside the
  middle of the tail fan, and the five rays fan out of that end. (4) **Legs:** the three gold talons hook **down, the
  tips forward and a little inward**, like a bird of prey's clenched foot (this replaces "pointing to the tail" and
  "curving down and back" of his first two lists; the sheet draws them straight back).
  **Built as `body-fable/round-15/`** (pictures `round-15/check.jpg` and `close-*.jpg`): one closed mesh, 3,982
  triangles, counts match the map. What his list asked for as Blender shader effects (bump noise, an ambient-occlusion
  node, bevel modifiers) is painted or baked into the one texture instead, because Roblox receives only the mesh and
  its pictures; plate edges are the plates' own facets, since modifier bevels would break the 4,000-triangle budget.
  The independent reviewer (once, on this round): whole model "not yet"; wing and tail "close"; head, legs and back
  fins "not yet". On his four items it found the talons thin, the tail point low in the fan, the ribs thin and a square
  tab at the wing's back root: all four changed after its look, not re-reviewed. Outside his list it ranks: scales
  read as a woven zigzag, cheek blades spread flat, tail rays half the sheet's width, gold too lemon, back fins flat
  where the sheet's hook.
  **Open question for Alan:** from dead ahead a thin gold line still stands above the horns. It is the upright tail
  fan seen edge-on (102 px tall against the horn tips' 82), not a back fin (those now top out at 60). Removing it means
  a tail fan about 40% lower, which goes against the side view and his own tail ruling: his call.
  **Alan on round 15 (2026-11-15): "the tail looks good i like it the way it is."** The tail fan and its tapered root
  stay as built, so the thin line above the horns from dead ahead stays too: accepted.
  **Alan's fourth list (same day).** A new rule first: **the sheet's front view cheats the legs and claws; they follow
  the bottom, side and three-quarter views only**, and nothing is bent to show in the front view. (1) **Legs:** the
  down-hooks of the third list are gone; each leg is a sleek scaly pod against the belly with three subtle green toe
  bumps at its rear and three straight, level, bullet-shaped gold claws pointing straight back, their bases sunk a
  third into the toes, a dark shadow where gold leaves green. (2) **Wings:** the three bones leave one narrow point at
  the shoulder (the heavy knuckle of the third list is gone: it and the wide rib roots read as a yellow slab); the
  membrane gets veins again, branching off the bones at 35 degrees towards the back edge (the third list had removed
  the leaf veins), and each bay is folded once down its middle into two flat planes instead of sagging softly ("a
  green felt blanket"). (3) The spike in the front view: the list asks to find and remove it; it is the tail fan he
  approved, so nothing changed. (4) **Back fins from above:** heavy gold caps again, tips curving left and right in
  turn, locking into a bold gold-and-green chain (the third list had slimmed them because they read as a wavy tube).
  **Built as `body-fable/round-16/`** (`check.jpg`, `close-*.jpg`): one closed mesh, 3,926 triangles, counts match the
  map (which gains piece 22, the toes); outline top 0.88, side 0.85. The reviewer (once, on this round): legs and
  wing "close", back fins and the whole "not yet"; after its look the toes were made to show, the claws fattened, the
  veins run one way only (both ways made a net), the folds got a lit and a shaded plane, the fin caps widened. Still
  short: the back fins are flat caps on stalks from the side, where the sheet's are tall hooks (they were lowered to
  0.55 of their height in round 15, when the front-view spike was thought to be a fin). **Open for Alan:** put the
  fins back to their drawn height, now that the spike is known to be the tail he approved?
- **AI 3D test: Tripo, one picture (Alan, 2026-11-15).** Alan asked to try Tripo (an AI 3D maker) against the Blender
  Dragon, and maybe Forge GUI too. The sheet's three-quarter view draws a back leg on top of the near wing ("the leg is
  not supposed to be above the wing"); Codex repainted it without (`.planning/skins/dragon/tripo/input-three-quarter-fixed.png`).
  Alan ran it on Tripo's website (free plan): "it came out really inconsistent", no back legs. **Ruling (Alan, same
  day):** the AI tools need a **consistent concept set with every side**: (1) Codex draws **top, bottom, front, back,
  left and right** from the approved Dragon, each view checked against the others before use; (2) the set goes to
  **Tripo** (its multi-view takes front, left, back and right, all at level height) and **Forge GUI**, and the two
  models are compared; (3) Blender only on the winner: trimmed to the budget and cut into the five fit pieces. **The
  tools do the modelling**, and no tool gets the one-picture view again. **Then Alan's own idea, same day:** Codex can make the
  set from the Fable Blender Dragon: render it from each side and have Codex turn each render into a finished
  concept picture ("make it look better, like a finished product with each side"); the shape then agrees across views
  by construction. Try that first; drawing from the sheet is the fallback. Free-plan Tripo outputs belong to Tripo (its terms), so any
  model we ship is remade on a paid plan. **Forge GUI** (forgegui.com, key `FORGEGUI` in `.env`, an `fgmcp_` key for its
  "ForgeMCP" link to Studio): mostly 2D Roblox art (GUIs, icons, thumbnails), but lists "3D assets" with GLB export;
  free starter credits, assets yours to use commercially, and free-credit work may be shown in its public catalog
  (Alan doesn't mind). Its MCP setup and 3D details need a browser; not tried yet.
  **The six-view set (same day):** Alan chose **tall back fins again** (the sheet's drawn height; the low caps came from
  mistaking the front-view tail for a fin), built as `body-fable/round-17/` (one number, `FH = 1.0`). Its six straight-on
  renders went to Codex in one job (`.planning/skins/dragon/six-views/`: `renders/`, `painted/`, `prompt-paint.txt`,
  about 100,000 Codex tokens); each painting keeps 95-99% of its render's outline, so the views agree piece for piece.
  Tripo's multi-view takes `front`, `left`, `back`, `right` (front required); its docs don't say whose left.
  **Forge GUI, tried (same day):** its "Text to 3D Assets" runs other makers' models (Meshy 7.1, Tripo P1, v2.5, v3.1),
  from text or one reference picture; on the free plan pressing Create only shows "Upgrade to generate 3D assets"
  ($15.99 a month promo), so nothing was made and nothing spent. Paying is Alan's call. **Alan's next ask:** the
  six views first get "more anatomically a dragon, like a top-quality model, one consistent design", same painted
  finish (not realistic textures): three left-side options (A refined anatomy, B + folded real legs, C + one-creature
  body), his pick then guides the other five views. **Picked (Alan):** C's folded legs (thigh, folded shin, three
  toes, straight gold claws trailing back) and its overlapping cream belly plates; the eye stays the glowing gem with
  no pupil (A-C's slit pupils turned down). C itself looked "fried" from painting a painting, so the final six are
  painted once from the renders with C as a guide (`six-views/final/`, `prompt-final.txt`).
  **Tripo with the final six (Alan):** on the free website, six pictures made six separate one-picture models.
  Multi-view is not on the free plan ("Upgrade to unlock Smart Mesh & Multi-Views"): the cheapest plan with it is
  Pro, $20 a month ($156 a year), 3,000 credits, private models, commercial use. The API (our `TRIPO_API` key) does
  multi-view for 20-30 credits a model; credits are $0.01 each, bought from $1 (developers.tripo3d.ai/en/pricing),
  not refundable; its terms give paid users the rights to outputs, without saying API buyers count as "paid users".
  **Forge GUI's plans (checked same day):** Free = 10,000 credits, images only, no commercial rights; Creator $22 a
  month ($15 the first month), 150,000 credits, advanced and premium models, commercial licence; Pro $50; Studio $200.
  Its 3D reference box takes several pictures at once, but nothing on its site says whether they reach Tripo as one
  multi-view job or as separate references, and it shows no credit cost per 3D model.
  **Tripo Pro, first models (Alan bought Pro, same day):** HD Model (H3.1) from the level views: one model, 18,649
  triangles, wings wrong (narrow blades: every level view saw them edge-on). Smart Mesh (P2.0) from nose-up views,
  triangles, 4,000, private, 4 versions: wing outline right in all four (one had holes between the struts); the
  textured one has 3,844 triangles. Alan: "looks decent". Export offers GLB with a 512/1k/2k/4k texture and a
  "Send to Roblox" bridge. Credits used 165 of 6,200.
  **Then (Alan's go):** HD Model from the nose-up views (45 credits): right wings and glossier paint, 17,733
  triangles; Tripo's plain Retopo (5 credits) to 4,022 triangles kept the texture; downloaded as
  `.planning/skins/dragon/tripo/dragon-tripo-4k-tris.glb` (1024 colour, 512 normal, 1024 roughness-metal), turned
  nose-forward in Blender (`tripo/renders/`, `concept-vs-tripo.jpg`): the shape matches the concept closely, but Alan,
  from the player's view (behind and above): "a lot of problems, this view needs to be perfect"; Tripo's texturing
  "butchers" the structure Smart Mesh gets right. **Ruling (Alan): Tripo for the shape only, Blender for the paint.**
  Take the best untextured Smart Mesh version (about 4,000 triangles; three of the four have whole wings), unwrap it,
  project the six approved paintings onto it (each spot from the view facing it best, as `tools/art/sheet_model.py`
  does) plus a new seventh Codex painting of the player's behind-and-above view, flat gold, green or cream where no
  picture reaches, and check the player's view first. Credits left 5,985.
- **Dragon: paint the Tripo shape piece by piece** (2026-11-15, evening; Alan's two methods). Shape: the 3,844-triangle
  Smart Mesh version (best of three against the approved views: side 93%, top 96%), cleaned in Blender to 3,720
  triangles: wing skin given an underside, 693 never-seen faces removed. Putting the six approved paintings straight on
  smeared the thin parts, because their outlines are the old Blender model's, a few percent off Tripo's shape. So Codex
  repainted ten views (six flat, the player's view, three more angles) over flat-colour renders of the Tripo shape
  itself, the approved six as the look. Alan on the first result: artifacts, blur, "poor application". **His ruling on
  method:** (1) work piece by piece: the mesh is 63 separate pieces; gold pieces get colour and line work by code, the
  smooth pieces (body, wing skin, maybe horns, tail) get a painting, each on its own, then assemble; (2) if that fails,
  Claude paints everything by code in Blender and Roblox's surface pictures (bump, shine, metal) add the depth.
  Second pass (struts and tail ribs by code): clean and on-shape, but the code gold is one flat pale tone. Alan: gold
  needs shading, lighter and darker areas and light line work like the concept, and he would rather it not be code.
  Next: a painting per gold piece (alone, laid flat, filling the frame); fallback baked Blender light or richer code. Files and run order: `.planning/skins/dragon/paint/tools/README.md`. Tripo credits still 5,985.
- **Dragon: stop projecting paintings; build in parts and bake** (2026-11-15, late; Alan). A third pass (each wing's
  struts painted alone, then put back) still "looks bad" to Alan, so the projected-paintings method is stopped. What
  practitioners do (two research passes; sources thin, mostly single creators): one object per concept picture, split
  the model into parts, generate each part high-detail in the 3D tool, make the low-triangle version with a fresh
  unwrap, then bake the high-detail part onto it in Blender. Roblox's own texture generator was tried on our mesh:
  Fast mode is pale and soft, Quality mode ignored "gold" and made a teal leather dragon; it cannot follow a design.
  **Head test (55 Tripo credits):** four head-only paintings to Tripo H3.1 (4K texture) gave a well sculpted head whose
  colour is flat on purpose; the depth is in the shape. Baked onto our own low-triangle head pieces (bump picture,
  metal picture, colour with creases darkened and edges brightened from the shape) it reads as clean faceted gold.
  Alan on the high-detail version of that look: "looks decent, finish the test". Splitting rule he agreed to: cut only
  where two materials meet (gold pieces, wing, tail fan, leg, fin), never through the scaled body; one wing, one leg
  and one fin are made once and reused; colours are set to fixed numbers per part. Credits left 5,930.
  **Alan on the low-triangle result: "it definitely breaks at low triangle."** The look lives in the shape, and a bump
  picture cannot fix a blocky outline. Next: Tripo's own head cut down to 2,000, 4,000 and 8,000 triangles side by side
  (no credits) to find the lowest count that holds; raising the Dragon's 4,000-triangle budget is Alan's ruling.
- **Shape skins: the 4,000-triangle budget is lifted** (Alan, 2026-11-15, evening): "5,000 triangles is too low". Design
  quality comes first; performance is protected in other ways. Triangles are spent by part: the hard, outline-making
  pieces (horns, head plates, fins, tail) get many, smooth ones (belly, wing skin) get few. One wing is made and
  mirrored, one leg made and reused (same paint, less work, exact match; each copy is still drawn). The total is not
  fixed yet: find per part the lowest count that still holds, then MEASURE frame rate with 12 such planes in view
  (Studio Play: Alan's go) instead of guessing. Roblox's own levers stay on: automatic detail drop at distance
  (RenderFidelity Automatic), few parts and one picture set per plane, simple collision boxes. Roblox's per-mesh
  triangle cap is 20,000 ("Individual meshes can not exceed 20,000 triangles",
  [Roblox mesh specifications](https://create.roblox.com/docs/art/modeling/specifications), read 2026-11-15).
  **Head count test** (`.planning/skins/dragon/parts/head/head-triangle-counts.jpg`; the count-test script sits with the Dragon's pipeline scripts): Tripo's own
  head cut to 2,000, 4,000 and 8,000 triangles, each with a fresh unwrap and bake. The outline at 4,000 is close to the
  56,892 original and 8,000 is nearly the same; 2,000 is visibly simpler. Sent to Alan, no pick yet. The gold shows brown
  blotches at every count, the original included: Tripo's metal picture is patchy, so use one metal value per material.
  Alan also parked Modddif ("we will wait") in favour of this higher-triangle modular route.
- **Shape skins: triangles only where the outline needs them** (Alan, 2026-11-15, on the count test): "it's wasting
  triangles in places they don't need them"; "I just see a bunch of simple objects". Real shape for horns, head plates,
  fins and struts; the body under them is a smooth simple surface, and scales, the eye, horn rings and plate lines are
  pictures that give the illusion of depth (colour shading plus a bump picture baked from Tripo's sculpt). Never cut a
  sculpt down with an automatic reducer: it spends triangles on every sculpted scale, leaves dents when it runs out
  (the colour spots at 2,000) and moves the surface off the sculpt so the bake samples the wrong spot. Build clean
  simple shapes that hug the sculpt (Tripo's own low-triangle rebuild, about 5 credits, or by hand in Blender), smooth
  the body, then bake. One metal value per material.
  **Head rebuilt that way** (2026-11-15, late; `.planning/skins/dragon/parts/head/head-clean-on-dragon.jpg` and
  `head-clean-vs-tripo.jpg`, sent to Alan, no verdict yet): the sculpt is split along its inward creases into horn,
  four plates a side and the body; each hard piece becomes a few straight-sided rings along its own length (kept only
  where the outline bends), the body one smooth 12-sided tube, the right side's pieces mirrored to the left. 1,600
  triangles after dropping faces nobody can see (horns 352 each, plates 36 to 120, body 288). Gold and body are baked
  apart, each from its own share of the sculpt, so no green bleeds onto gold; gold is metal 0.6, roughness 0.4, the
  rest roughness 0.5 (Claude's numbers, for Alan to judge). Tripo's own rebuild for comparison (Retopo, four-sided,
  10 credits; its "Smart Mesh" switch costs 40): 2,352 triangles in one fused skin, horn steps and plate edges
  rounded off; with the same bake it reads close at the player's distance. Credits left 5,920.
- **Dragon head accepted; same method for the other parts; about 8,000 triangles** (Alan, 2026-11-15, night): "that
  worked pretty well for the head", "it looks pretty good, actually". Mine is kept (not Tripo's rebuild). The Dragon
  "does not need to be under 4,000 ... we're aiming for like 8,000"; parts that need more triangles get more. Next
  part: one wing.
- **The Dragon's eyes glow light emerald green, no pupil** (Alan, same message): "it just looks like a glowing
  gemstone". Done the standard Roblox way: a glow picture (white over each eye, black elsewhere) baked with the
  other pictures, for SurfaceAppearance's EmissiveMaskContent with EmissiveTint and EmissiveStrength
  ([Roblox reference](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance), read 2026-11-15;
  the mask is set when the model is built, not by a script at run time). The eye is an oval on each flank, light
  emerald in the colour picture too; preview `.planning/skins/dragon/parts/head/clean/blender-dragon-eye.png`. Glow
  strength and exact colour are Claude's preview numbers until Alan sees it in Roblox.
- **Wing through Tripo: rejected. Structure first, texture painted on top** (Alan, 2026-11-15, night, on
  `.planning/skins/dragon/parts/whole/dragon-head-and-wings.jpg`): "there's just very, very obvious problems in the
  wing"; "why did you feed it back through Tripo ... you had already recoloured it"; "the structure is the most
  important piece"; "if we can get the model's structure following the reference image, then we can paint the texture
  on top" (TextureCraft is installed for that). What went wrong: Claude repeated the head's recipe without asking
  whether a wing needs it. A wing is three bars and a flat sheet; Codex's top and underside paintings were already
  the finished look. Tripo's sculpt (55 credits; 5,865 left) fused the two front ribs near the shoulder and left a
  ragged skin edge beside them, and Claude's ring shapes and bake then added cracks where the ribs overlap and pale
  slivers where ribs meet skin. From the player's distance it passes; close up it does not. **Rule from here:** a part
  goes to Tripo only when it needs sculpted detail that pictures cannot give (the head's horns and plates did).
  Simple parts (wing, tail fan, fins) are built straight from the reference picture's outline and measurements, checked
  against that picture, and textured afterwards (the Codex paintings laid straight onto flat faces, or TextureCraft
  materials by part). The wing is redone that way next; no verdict on the tail, body or legs yet.
- **Wing built from the painting: accepted** (Alan, 2026-11-15, late night, on
  `.planning/skins/dragon/parts/wing/built/wing-close.jpg` and `parts/whole2/dragon-new-wings.jpg`): "the wings look
  good. I'd move on now." How: Codex's top painting is read column by column (the outline, each rib's two edges, the
  bright line down each rib, the tip caps); three ribs and one skin sheet are built to those numbers (outline match
  0.998) and the painting is laid straight on top; the skin's underside wears the underside painting with its gold
  painted out. No Tripo, no credits. 1,130 triangles a wing (Dragon so far: 3,860 with both wings and the head).
  Known and accepted as shown: ring joints are paint only, the skin is flat, small notches where the skin meets each
  rib tip. Rib height (a quarter of its width each side) and skin thickness are Claude's numbers. Script and run
  order: `.planning/skins/dragon/paint/tools/README.md`. Tail fan and back fins go the same way next.
- **Tail fan built from a fresh side painting: accepted** (Alan, 2026-11-15, late night, on
  `.planning/skins/dragon/parts/tail/built/tail-close.jpg`): "the tail looks great". Alan first flagged the old
  placeholder tail's render: "that tail model is broken ... huge gaps". So the old tail was not used at all: Codex
  painted a clean side view from the design sheet (one picture), and the wing's method measured it in rings round the
  hub: five ribs on ONE solid skin sheet, both faces alike, 840 triangles, 0 see-through gaps (the builders now count
  them). The fan is about 7% smaller than the sheet draws it so the Dragon keeps its length; hub position and rib
  height are Claude's numbers. Dragon so far: 4,700 triangles (head, two wings, tail). Leg next.
- **Legs: the pods were the wrong design; the folded leg is sculpted in Tripo** (Alan, 2026-11-15, late night). Claude
  built the legs as plain scaly pods with three talons, measured off `model-sheets/dragon-b8-legs.png`. Alan: "that's
  the wrong leg ... we redid the legs and they look like actual dragon legs now. Like an actual folded leg." The
  Dragon's reference is the final six views, `.planning/skins/dragon/six-views/final/` (thigh, shin folded back
  under it, three toes, three straight gold claws); the b8 sheet is older. The pods and their script are deleted;
  Codex's scale swatch stays (`parts/leg/painted/scales.png`). **Ruling (Alan, asked with the cost):** "Sculpt in
  Tripo": the head's recipe (Codex paints one leg's four views from the final views, Tripo sculpts, clean shapes,
  bake). His yes covers 55 credits (5,865 before), Claude driving Tripo Studio in his Chrome, and one model download.
- **Folded leg accepted** (Alan, 2026-11-15, night, shown the close-up with its flaws first: "those look fine I guess,
  let's move on to the back fins"). Codex painted the leg's side and underside from
  the final views (the other two Tripo views are their mirror images: those faces sit against the body); Tripo H3.1
  with a 2K texture cost 45 credits, not 55 (5,820 left). **Tripo made nine claws** (a 3 by 3 block): every view
  showed three across. Kept: the three on the slant (outer-top, middle, inner-bottom), which is the one layout that
  shows three claws from the side and from below as the final views do; the six others are painted over green. The
  leg is one tube of 357 triangles plus three six-sided claws, fattened 1.3 times to the picture's thickness; one leg
  is drawn four times (1,428 triangles; Dragon so far 6,128). Placing (box on the Dragon), the slant and the claw
  thickness are Claude's numbers. Known flaws, accepted: blank green patches on the toe ends, a blunter thigh
  and straighter outline than the picture, legs barely seen from the player's view
  (`.planning/skins/dragon/parts/leg/leg-close.jpg`, `parts/whole3/dragon-new-legs.jpg`).
- **Back fins: outline plus paint; accepted** (Alan picked the method, 2026-11-15, night, shown the final views' crop
  first; on the matte re-render: "ok it's good, let's move on to the body"). Codex painted fin 2 crisp from the final side view (one picture); the wing's method built
  one gold spine on a thin web from it, and that fin is drawn five times, each stretched to its own length and height
  from the side view and bowed sideways in turn as the top view draws them. 156 triangles a fin, 780 for five, no
  credits. Spine width seen from above (0.175 of a fin's length), the bow (0.13 of its length) and the root's depth
  are read off the views; all five being fin 2's shape is the "one fin reused" rule (fin 1 lacks its taller web).
- **The Dragon looked "wrapped in plastic" and too bright next to the reference** (Alan, on the fins' close-up; he also
  circled brown bands under the spines and orange specks at the fin roots). Measured: the previews were lit 2.3 times
  too bright and the gold mirrored the sky. Changed for every part: gold metal 0.6 to 0.15, gold roughness 0.4 to 0.6,
  everything else roughness 0.5 to 0.9 (the paintings already carry their highlights); the preview light now shows a
  sunlit face in its painted colour, with even light from all round so undersides are not dark (that was the brown
  band). Built and reference now agree within a few percent on gold and green. The orange specks are the old body's
  paint and go with the body rebuild. How it reads in Roblox's own light is unknown until a Studio check (Alan's go).
- **Body next: outline plus paint is the plan** (2026-11-15, night). Alan was shown the body's crop
  (`.planning/skins/dragon/parts/body/final-body.jpg`) and asked "sculpting, or outline plus paint?" twice with
  Claude's recommendation (one smooth tube read off the side, top and bottom views, Codex's scales and belly plates
  wrapped round it, no Tripo). **Ruling (Alan):** "we can go with your body recommendation." Any Tripo use still
  needs his go. About 1,100 triangles are left.
- **Body accepted, and one skin from nose to tail** (Alan, 2026-11-15, late). The body is one closed tube (1,056
  triangles; the Dragon is 7,964) wearing two swatches Codex painted, repeated along it by code
  (`body_build.py`, beside the other Dragon builders). Three rounds, each his words: a body painted to the final views' finer, flatter
  scales was "fully inconsistent with the head", so sizes, colours and bump depth were re-measured on the head; the
  straight cut where head met body was "a huge visible seam", so the body's skin was carried onto the head's neck in
  the head's own pictures; the cut that left behind the eye was still "not seamless", so the skin now covers the
  whole head tube and the body's first ring copies the head tube's 12-sided outline. **Ruling:** "its good enough".
  The accepted head's pictures are untouched; the repaint is a copy (`parts/head/reskin/`, `head_reskin.py`). Known
  and told: a hairline at the join at far zoom (the head side reads about 10% brighter, cause not found), a small
  leftover shape on the jaw, scales bigger and belly plates bolder than the final views draw. **Go given:** "lets
  load the model into the game and see what it looks like when its in roblox" (the upload; Play and place saves
  still need their own go).
- **In Studio for the look (2026-11-15, night):** 21 pictures and one mesh file uploaded (free, all Approved; empty texture
  space filled first, every picture looked at). The Dragon stands in Studio as `Workspace.DragonLook`, plane-sized (8.4 studs),
  not saved with the place. These uploads are for the look; the game gets the merged 1024 set.
- **Verdict and how it fits (Alan, same night):** "looks fine in roblox it needs to input as a plane skin though like we
  did for the crane". **Wings forward:** he moved them up the body in Studio ("more close to the plane proportions"):
  0.67 and 0.71 studs on the 8.4-stud model; "make them like the same number", so both 0.69 (about 8% of its length). His
  right wing also slid out sideways: "that was a slip". **Fit:** shown A (keeps its shape) against B (body stretched to
  cover): "it needs to maintain its proportions ... we can't stretch it and make it look odd", with a cap, because
  "we just don't want ... people hitting the sides of buildings and not knowing why they crashed". So: one size, as big
  as needed for its wingtips to reach the plane's, nose on the plane's nose; the cap, picked from a row of five planes
  in Studio, is **1.25 times the plane's length** (wingtips match on 19 of 36 builds; on the widest wings the plane's
  own tips stick out up to 3.1 studs each side). One mesh and one 1024 picture set (the budget rule): from the player's
  view it reads the same, close up the scales are a little softer (`roblox/game/compare-one-set.jpg`).
- **Then the Dragon became the hitbox (Alan, same night), replacing the 1.25 cap.** Seeing the row in Studio: "this is
  definitely a large enough gap that you will hit something and wonder why your plane crashed" (the heavy bodies hang
  2.2-2.6 studs below the Dragon's belly). His idea: "make the collision box still follow the skins, and we just scale
  them up or down depending on the size of the plane ... so that it's still the same hitbox". Asked which size to
  match, he took Claude's pick: the outlines from above, the side and behind, added. So the Dragon is the plane's hit and
  crash shape, as big a target as the plane, centred on it; this replaces "a skin never changes the hitbox"
  ([skin rules](2026-11-13-skin-rules.md)) for the Dragon. Measured on exact shapes it is 0.96 to 1.48 times the plane's
  length (I had first told him 1.3 to 1.45 from a rougher measure).
- **Never smaller than the plane (Alan, 2026-11-16).** Flying the fastest frame (slim body, narrow wings) he found the
  Dragon "a little too small, seemed like smaller than usually what a plane is" and suspected the collision. Checked: the
  server's hit shape is the Dragon's own outline. Equal total size had left it 11 studs wingtip to wingtip against the
  plane's 14 (the Dragon puts more of its size in its side view). Now it is also never shorter or narrower than the
  plane: as wide as the plane on narrow-wing builds, a bigger target there (about half again on the narrowest).
  Flown again with the shot-drawing fix: "Okay, it looks good now" ([playtest](../playtests/2026-11-16-dragon-skin.md)).
  **Dropped (Alan, 2026-11-18)** for the Dragon and all five Legendaries. Measured on the chase view (1280x720): on the
  Toilet Roll Gunship with Broad Wings the floor made the Race Car 39 studs long against the plane's 24, its back end 5
  studs from the camera, 34% of the screen against the plane's 8%, and 1.4 times the plane's target (2.4 from behind); on
  Swift Fold with Swept Wings skins were up to 2.2 times the plane's target. Alan: "the point is to negate advantage and
  disadvantage"; every whole-shape skin is now exactly as big a target as its plane, scaled evenly (never stretched).
  **Next, his rule for what counts (same day):** body, wings, nose and tail count; extras (the Hot Rod's spoiler, the
  Shark's top fin, fins far taller than a normal plane's) are trimmed on the hidden hit copy only (to about a normal tail
  fin's height), are never hit and pass through walls; the drawn skin keeps them in full. Marked pictures per skin first.
  **His OK on the marked picture (`.planning/skins/hit-trim-preview.jpg`, "Green looks right, go for the 5 uploads")**, cut
  where a normal tail fin ends above the body (about half of each tall fin). Built the same day as one FBX (one upload,
  approved; mesh ids in `config/skin-shapes.json`): every Legendary is exactly its plane's target on every build; the
  drawn skins grew 1-5%, the Ninja shrank 2%. The Dragon needed no trim.
  **Then size by length and wingspan, not target (Alan, same evening, after flying the Ninja on a Cardboard build: "the
  wingspan is way longer ... the wingspan should be the same").** Equal target made flat skins much wider and longer than
  tall-bodied planes (the Cardboard and Toilet Roll bodies' deep fuselage is most of their target). He ruled out the plane's
  own parts as a hidden hitbox under the skin ("if it can hit or crash where no skin shows, that's a problem"; players
  thread tight gaps) and took "keep the shape" over stretching the wings: one even size, as long or as wide as the plane,
  whichever comes first, never bigger. A thinner target from behind is accepted: "the actual mass ... will not be changing
  ... It's just a skin, it's just cosmetic." 
  **Then too small (Alan, 2026-11-19, flying a Race Car against the same plane without a skin: "now the planes are just
  too small ... there's got to be a middle ground").** Measured: under "length or wingspan, never bigger" skins cover
  2.4-5% of the chase view against the plane's 6.8-7.7%; under equal target 3.5-16%. **Ruling: size each whole skin by
  the screen**: for each skin and each body + wings mix, the one even size at which it covers the same share of the chase
  view as the plane without a skin, measured once and stored as a table the game reads (shape kept, never stretched,
  camera unchanged). **A project rule (AGENTS.md):** every new whole-shape skin gets its row measured before it ships.
  **Built 2026-11-19** (`config/skin-sizes.json`): body + wings alone missed by up to 45% once another nose or tail went
  on (the skin is centred halfway from nose to tail tip, so a long nose pushes it away from the camera; some parts also
  make the plain plane bigger on screen), so the table also holds what each nose and tail multiplies the size by. The
  size is stored against the wingspan (noses and tails don't change it; against "length or wingspan" a nose alone moved
  skins up to 19%). Result: every skin within 1% of the plain plane on the four check builds; on 36 builds with mixed
  noses and tails 207 of 216 within 5%, worst 11% (the small Swift Fold with nose and tail 3).
- **Guns under big skins (Alan, 2026-11-19):** guns touch the skin and tilt to its slope (Race Car's too). **Only the clip must hide from straight above**, not the whole gun ("of course, you're not gonna be able to hide the pencil launcher"). A small gun such as the spitball has no reason not to fit fully under the wing. A long gun may stick out, **as long as it is centred on the wing front to back where it hangs**, never half off one edge while the other half has room. The pellet gun hangs by its cradle's flat bottom on every plane (it hung by its straw).
- **Tail fan: kept as built, though it differs from the final view** (Alan, same answer). The accepted tail was also
  measured from the b8 sheet (five wide gold blades); the final LEFT view draws a bent bar along the top, a bar along
  the bottom and three thin ribs with knobs (`parts/tail/built/tail-final-vs-built.jpg`). Offered a redo; Alan:
  "Keep the one I built". The wing matches the final views (its paintings came from the model made from them).
- **Every shape skin has a body with a bottom, and its sheet shows the underside** (Alan, same day): "you don't know
  what the bottom looks like", and a flat-bottomed, slim design looks very odd stretched over our deep bodies ("imagine
  if that was on the Toilet Roll"; the Dragon was "incredibly slim"). He means **a barrel, like a plane's fuselage**:
  a long tube under the wings, still sleek. **Not a belly:** the first redraw was briefed with animal words ("deep
  belly", "chunky") and Codex drew fat creatures ("they're paper airplanes"). **Not a box either:** a square barrel
  made the Dragon "blocky", "not aerodynamic". **Not a sausage:** the round Dragon "looks like a balloon"; the shark
  works because its head is the nose cone and the body tapers all the way. A skin must look like a paper airplane
  and a cool fighter first, the creature second.
- **Shark Jet: a whole shape that is the hitbox, built without Tripo** (Alan, 2026-11-16, on a how-we-make-it plan
  with the sheet shown first). The skins plan said a Legendary is your plane plus add-on pieces; the approved sheet is
  a whole shark. Asked which: "Whole shape". Asked whether the Shark is the hitbox like the Dragon: "Yes" (same sizing
  rule: as big a target as the plane, never shorter or narrower; its tall back fin is hit and crashes too). **Changed 2026-11-18 (Alan): the top fin has no hitbox** ("If the top fin has a hitbox, then that's a disadvantage to the person wearing that skin"); not built yet, and whether it still crashes into walls is open. The other
  Legendaries are decided one by one. Method (Claude's; his "you choose the method; keep it cheap"): a measured piece
  map first; then Blender, one part at a time (body with face, one wing mirrored, back fin with the fold strips, tail),
  each shown alone in close-up beside the same crop of the sheet; painted from the sheet's own pixels, a Codex repaint
  only for a part that looks soft; no Tripo, because nothing on it needs sculpting.
  **Measured (same day), waiting on his OK:** `.planning/skins/shark/measure/piece-map.png` (13 pieces: 6 built, 7
  painted; scripts beside it). The three flat views agree on the length within 1%. Of a length of 545: body 68 wide and
  82 tall, wings 401 across with a straight back edge, back fin 107 tall, tail fin 150 tall. The front view draws the
  body 1.4 times too wide (top and bottom rule); the side view leaves the wings out (high on the shoulder, from the
  front and three-quarter views); the bottom view draws no teeth under the nose (teeth on the two sides only).
  **Map OK'd ("Ok all go ahead") and built the same day; the preview waits on his OK** (`.planning/skins/shark/build/`,
  `make_spec.py` holds every number; the last round is `whole-04/`): one mesh, 1,738 triangles, one 1024 picture set, no
  Tripo, no Codex. Body: a tube lofted through the side and top outlines, a folded-paper head (ridge, upright walls, flat
  floor) and a roof-shaped back (the side view shows the box 13 px and the rails 11 px tall, which only fits rails lying
  on a sloped shoulder). Wings, back fin and tail fin: outlines read row by row off the sheet, a crease down each face.
  Paint: the sheet's own pixels (flank from the side view, belly from the bottom view, wings from the top view on both
  faces, the fold box from the side view's strip). Outline match 0.95 from above, 0.97 from the side; every piece within
  20% of its card. Known and told: from dead ahead the face is stretched stripes (needle nose); the tips of the teeth
  show from below as a thin zigzag along the jaw; the cream changes tone where the side and bottom pictures meet.
  **The mouth carries under the nose (Alan, same day, on the preview):** "from the front, it looks pretty bad ... the
  concept picture is not correct ... you need to be able to see a full smile, like you're about to be eaten by a shark
  ... everywhere else is okay." This replaces "teeth on the two sides only". He gave two routes (continue the mouth
  without the picture, or have Codex redraw the front). Claude first painted it by code (`build/mouth.py`, round
  `whole-06/`): an open mouth in the sheet's bottom view, stretched along the nose so it reads from dead ahead. Alan:
  "that's not right, that's why I said get Codex to draw another concept image of the front and get it to match
  everything but change the mouth". **So the front view is redrawn by Codex** (`.planning/skins/shark/front/`: the
  sheet's own front view as the start, 55,327 tokens, one generation): everything kept, one full grin from cheek to
  cheek under the snout. `front-before-after.jpg` waits on his OK; then that mouth goes on the model (the head's
  underside and the ends of the side grin: on a needle nose only the underside is free to face forward).
  **He OK'd the picture ("Ok put that mouth on the model") and it is on the model** (`build/mouth.py`, round `whole-08/`,
  `mouth-views.jpg`): the grin is found in Codex's picture, unbent into a band low on the head's floor and copied into
  the sheet's bottom view. Fitting the whole grin made its 23 teeth 2.6 px each (a comb), so the floor shows the grin's
  middle 11 teeth at the side teeth's size and the grin's ends are the side rows on the walls. Waits on his OK. Short of
  the picture: the grin sits low and smaller (needle nose), and from straight underneath the teeth are long streaks.
  **"Definitely nowhere close, make it look like Codex's picture" (Alan, same day).** Claude cut the head's sides into
  fine steps so forward-facing faces could wear Codex's face (round `whole-11/`). Alan: "the smile looks fine now but
  ... why is it broken up into lines ... this is a visual discrepancy". Offered a blunter snout instead: **"no we cant
  change the head shape ... just paint it the same as you did before but add the smile to the bottom side of the point
  so it lines up."** So: the head's shape is fixed, no steps, the side grin as it was, and Codex's smile painted on the
  underside of the nose where his picture has it (`build/front_face.py`). Round `whole-12/` (`mouth-views.jpg`, 1,738
  triangles) waits on his OK. From straight underneath the smile is stretched along the nose.
  **"We need to figure something out" (Alan, same day, on `whole-12`):** he sees why the side mouth cannot wrap into a
  full smile. He wants "some sort of illusionary effect where from the front you see the full smile, but from under you
  don't really see anything ... or it's covered by something", like the P-40, whose mouth wraps round its air intake:
  "I'm not saying let's build an air intake into it ... something blocks the bottom part from showing the mangled smile
  underneath. We just can't have those visual discrepancies, which were those lines." A piece added in Blender is allowed.
  Claude's answer: a chin under the snout. A first rough mock-up (a separate box laid over the model) went to him
  unreviewed: "are you even using a visual qa agent that looks horrible." **Built properly since, with an independent
  reviewer on every round** (`build/make_spec.py`, `build/chin_paint.py`, `build/mouth_views.py`; rounds `chin-01/` to
  `chin-09/`): the chin is part of the body's own mesh. Under the needle the underside drops in a steep rounded front
  58 px behind the tip (the chin's lowest point 25.5 px below the tip's level; the belly is 29) and runs back into the
  belly. The mouth's front third leaves the side walls and wraps round that front as one band laid along the surface,
  made of the sheet's own side teeth (mirrored at a tooth's tip, so the side mouth behind it is untouched), smaller
  towards the middle, drawn crisp. Ahead of the chin the snout is skin all round, underside too, as in Codex's front
  view. Unchanged: the head above the mouth, the top view's outline, the mouth from the fifth tooth back. 2,186
  triangles, closed, every piece within its card. Three reviewers: the third said the front smile is there, underneath
  is clean, "close, one short pass away" (grey smudges under the teeth: fixed in `chin-09/`; still there: the sheet's
  dark lower lip at the mouth's corner reads as a wedge from below, the teeth change size near the corners from low
  angles, the chin is a small bump under the nose from the side).
  **"So close to being done ... airbrush the mouth a bit to make it look continuous and consistent and remove this
  stray mouth line on each side" (Alan, same day, circles on `chin-09`).** The stray line was the sheet's own lower
  lip, which thickens into a dark crescent drooping under the back teeth. Painted out: one thin even lip traced under
  the lower teeth up to the mouth's corner, the cheek's own cream below it. A first try filled the whole chin's
  underside with one plain cream and a reviewer rejected the flat "bib"; the underside keeps the bottom view's own
  fold lines again. Fifth reviewer: "yes with caveats" (up close the lip is thicker under the middle teeth than along
  the cheeks). **"Okay, see, now this looks good" (Alan, on `chin-11`),** with one more ask: "add a little bit of contrast, add shadows,
  make the colors less dull, darken the blacks, darken the colors a little bit, and then I think it's good." Done as
  paint only (`make_spec.py`: shadows baked where pieces meet or tuck under each other, then the whole picture graded:
  colour 1.28, contrast 1.16, blacks pulled down, 10% darker). A reviewer passed the first grade ("yes with caveats":
  shadows too weak, since strengthened and not re-reviewed). **OK'd: "looks good lets wait for the ninja then upload all at the same time" (Alan, same day, on `chin-13`).** The
  Shark Jet's model is `.planning/skins/shark/build/chin-13/` (2,186 triangles, one 1024 picture set). Not uploaded.
  The five Legendaries (Shark, Stealth, Race Car, Hot Rod, Ninja) go up together once the Ninja has his OK, each after
  the safety sheet of its pictures.
- **The other eight Legendaries get model sheets** (Alan, same day: "one image for each showing top bottom and sides
  make sure it keeps it consistent"): bumblebee, rocket, hot rod, stealth jet, mech, pirate, ninja, race car. Claude's
  first batch described the skins in words and called his approved pictures guides; Codex drew the words. Alan: "did
  you not send the reference photos????" Redone with each skin cut out of his approved pictures as the design
  (`.planning/skins/model-sheets/legendary/`, `make_briefs.py`, `template.txt`, `<id>/<id>-sheet.png`,
  `legendary-sheets.jpg`); the consistency rules come from what the Shark's sheet got wrong. All eight are in and wait
  on his look; none is measured yet. Before any upload: the ninja's silver wing plates are four-point stars.
- **Safety swaps (Claude's call, told to Alan before he picked):** Shark A's wing zigzags become soft rounded stripes, Dragon B's
  gold square spirals on the cheeks become plain gold bands. Bent or hooked shapes and paired lightning bolts are the
  kind of picture that got the account banned twice ([lessons](../workshop/lessons.md)).

- **Safety sheets, and Legendaries move** (Alan, 2026-11-16, on the four safety sheets): Race Car "it's fine"; Hot Rod's re-laid
  picture (`whole-06`, every piece the same way up) "that's fine". The Stealth keeps its glow: "It needs the glow. The glow is
  important", and it is to get "the same treatment as the rare skins, where we put something under it so it's like the glow is
  moving throughout the stealth plane". For all of them: "these legendaries need just a little more ... we try to introduce as
  many of these like little animations as we can" (flames that look like they move). A flat texture picture means nothing to
  him: show risks on the plane, not on the sheet. How the movement is made: not decided (plan to him first).
- **Movement previews** (Alan, 2026-11-17, on four 4-second videos made by `.planning/skins/motion/preview.py`): "everything is good
  except the shark". OK'd as shown: the Stealth's lines breathe and a comet of light runs down them; the Hot Rod's painted flames
  roll back, fire burns from its nozzle and pops from its pipes; the Race Car gets a shine streak every 2 s. The Shark's
  sun-on-water net "just looks bad": instead "some kind of water splash effect like a shark jumping out of water that happens
  periodically" (preview to him first). A Rare-style layer was proven to sit on a 3D skin in an Edit test on the Dragon.
- **Shark breach, OK'd** (Alan, 2026-11-17, "ok thats good", after three rounds): once every 4 s twin sheets of spray start at the
  nose and sweep back along the body, thrown outward and back, low. The first small version was "a little small" (now about one and a
  half times that) and "it should pair with a skin animation to enhance the look": a bright line of water runs down the skin and the
  skin behind it goes darker like wet paper, then dries. "The shine needs to follow the water ... its lagging behind it": the line
  now moves at the spray's speed, 0.12 s behind its start. Numbers: the `shark` branch of `.planning/skins/motion/preview.py`.
  A Blender mock-up; the game version is not built. The Ninja has his OK in its own session (`.planning/skins/ninja/build/tail-10/`).
- **Ninja safety: "its safe i looked at it"** (Alan, 2026-11-17, before the reviewer reported). The reviewer agreed: colour picture
  low risk (one curled red sash piece alone on black beside the wing; no pinwheel, no group of hooks), bump picture safe. My own
  first read ("risky": red bent pieces on black) was too strong. Sheet: `.planning/skins/safety/sheets/ninja-sheet.jpg`.
- **Rebuilt movement approved** (Alan, 2026-11-17, "they looked good"): Stealth, Hot Rod, Race Car and Shark Jet.
  These are the videos made from the five actual layer pictures, with the approved preview above and the rebuilt
  version below (`.planning/skins/motion/<skin>/real/`). Alan wants the Ninja's animation pass next and suggested
  making its scarf tails flow in flight. He then asked for the scarf to react to flight and for a shine to travel across the metal pieces on the wings. After seeing the movement preview, Alan approved putting the Ninja in the game on 2026-11-17.

## Why
Concept pictures from one angle left the crane's builder guessing, and guessing cost three passes. A sheet with every
view, measured, says what to build; projecting the sheet's own art keeps its look instead of repainting it by code.
The belly rule comes from how the game fits a skin: it stretches per axis to cover whichever body you fly, so a slim
design over the heavy bodies would be pulled into a box.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), [skin rules](2026-11-13-skin-rules.md).
