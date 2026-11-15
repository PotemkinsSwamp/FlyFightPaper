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
  Alan ran it on Tripo's website (free plan): "it came out really inconsistent", no back legs. **Ruling:** make
  views that agree with each other, by **painting over renders of the Blender Dragon** (the outline is one 3D shape in
  every view; Codex paints the sheet's look on it), in six views: **front, left, right, back** (Tripo's multi-view
  takes only those, all at level height) **plus top and bottom** for Blender. Round 16's shape mistakes (flat back
  fins) come with the renders unless fixed first. Free-plan Tripo outputs belong to Tripo (its terms), so any model we
  ship is remade on a paid plan. **Forge GUI** (forgegui.com, key `FORGEGUI` in `.env`, an `fgmcp_` key for its
  "ForgeMCP" link to Studio): mostly 2D Roblox art (GUIs, icons, thumbnails), but lists "3D assets" with GLB export;
  free starter credits, assets yours to use commercially, and free-credit work may be shown in its public catalog
  (Alan doesn't mind). Its MCP setup and 3D details need a browser; not tried yet.
- **Every shape skin has a body with a bottom, and its sheet shows the underside** (Alan, same day): "you don't know
  what the bottom looks like", and a flat-bottomed, slim design looks very odd stretched over our deep bodies ("imagine
  if that was on the Toilet Roll"; the Dragon was "incredibly slim"). He means **a barrel, like a plane's fuselage**:
  a long tube under the wings, still sleek. **Not a belly:** the first redraw was briefed with animal words ("deep
  belly", "chunky") and Codex drew fat creatures ("they're paper airplanes"). **Not a box either:** a square barrel
  made the Dragon "blocky", "not aerodynamic". **Not a sausage:** the round Dragon "looks like a balloon"; the shark
  works because its head is the nose cone and the body tapers all the way. A skin must look like a paper airplane
  and a cool fighter first, the creature second.
- **Safety swaps (Claude's call, told to Alan before he picked):** Shark A's wing zigzags become soft rounded stripes, Dragon B's
  gold square spirals on the cheeks become plain gold bands. Bent or hooked shapes and paired lightning bolts are the
  kind of picture that got the account banned twice ([lessons](../workshop/lessons.md)).

## Why
Concept pictures from one angle left the crane's builder guessing, and guessing cost three passes. A sheet with every
view, measured, says what to build; projecting the sheet's own art keeps its look instead of repainting it by code.
The belly rule comes from how the game fits a skin: it stretches per axis to cover whichever body you fly, so a slim
design over the heavy bodies would be pulled into a box.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), [skin rules](2026-11-13-skin-rules.md).
