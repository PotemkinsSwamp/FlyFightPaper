# Skins and trails plan

**Status:** building the first batch (2026-11-13). Printed-sheet Commons and Rares work in Studio (Alan OK'd, test
pictures; [playtest](../playtests/2026-11-13-printed-sheet-skins.md)); buying with Paper, wearing and the Skins and
Trails tabs built; boosters wear printed skins. The Origami Crane (first Mythical) is in the game as five fitted pieces
(`SkinShapes.luau`), with playtest bugs to fix and its printed sheet next; the wing-hitbox tilt is built
([playtest](../playtests/2026-11-13-crane-and-skins-tabs.md)). Still to make: real pictures, Shark Jet, Dragon,
trails. His rules: [skin rules](../decisions/2026-11-13-skin-rules.md) (hitbox is always your parts, one design per skin fitted by
the game, Common/Rare/Legendary/Mythical, team outline, bots wear them), on top of the
[shop plan decision](../decisions/2026-10-18-shop-plan.md) (Paper or Robux, kept through prestige). Serves
[the beta has to feel finished](../decisions/2026-11-06-beta-feels-finished.md).

## The order (Alan, 2026-11-13)
1. A list of ideas for skins and trails, sorted into tiers.
2. Talk through how they work.
3. Concept pictures of the picked ideas (Codex).
4. Build them in Blender and texture them.
5. Only then prices, uploads (Alan's go) and the code.

## How the game fits one design to any plane
- **Hitbox:** the server tests shots against the real shapes of your plane's parts (`src/server/HitShapes.luau`).
  It copies every visible piece, so skins are drawn (and the real parts hidden) only on players' screens; the
  server's copy never sees a skin (see "Keeping skins cheap"), except that a shape skin turns the wings and moves the
  guns (below).
- **Common and Rare: a printed sheet.** Think of drawing on the paper before folding the plane. Each skin is one
  picture laid out like a flat plane seen from above (nose area, body stripe, wing areas, tail area). Every part's
  pieces get their picture position from where they sit on the plane, so any wings show the sheet's wing art and any
  nose shows its nose art. Switching parts needs nothing new: the game puts the same picture on the new pieces. Cost,
  once: `tools/art/skin_sheet.py` makes a **copy** of each of the 54 paper, card and tube pieces with this layout and
  bakes the piece's creases into its own normal map (2026-11-13, Claude's method, cheapest and safest): today's pieces
  and the plain planes stay exactly as they are, and the copies replace them on screen only while a skin is worn. One
  upload batch (54 meshes, 54 crease pictures) with Alan's go. After that, each Common or Rare skin is one picture
  (plus a shine picture for Gold Foil, a glow mask for Lava). Accents and boosters wear the skin too (Alan); tape keeps its own look.
- **Drawing it at runtime:** a script can't set a SurfaceAppearance's pictures, but
  `AssetService:CreateSurfaceAppearanceAsync` builds one while the game runs from uploaded pictures (the docs' own
  example uses an asset ID), so each player's screen builds "skin picture + this piece's creases" when needed; no
  pre-made combinations. Shine (metalness map) and glow (`EmissiveMask`, `EmissiveStrength`) go the same way. Still
  to prove in a Studio Play test.
- **Legendary: your plane plus add-ons.** The printed sheet plus a few pieces (a shark's fin and jaw, a bee's stinger
  and wings) the game places on the body and nose and scales with the plane.
- **Mythical: a whole new shape.** One model scaled evenly to your plane's length, with joints moved onto the real
  wing and tail corners (tested below), shown instead of the parts. Weapons and boosters stay visible so everyone can still read what you carry.
- **Players are told:** "Skins change how you look, never your hitbox", on the shop card and the Looks tab.

## Wing-hitbox tilt: how it works (Alan OK'd it 2026-11-14, guns too)
**Built 2026-11-14** (`src/shared/SkinFit.luau`, guns included); the Studio flight past walls is still to do.
From his ruling in the [skin rules](../decisions/2026-11-13-skin-rules.md) (a shape skin may tilt the wing hitbox, never
resize it).
- **What changes:** when a plane wears a shape skin whose wings rise, the server turns each real wing's hit shape and
  crash shape up around the wing root by the skin's angle. Shots hit the wing you see; you crash where the wing you
  see is.
- **What stays:** the wings' size, the body, nose and tail shapes, speed, turning, health and weight. Planes without a
  shape skin are untouched.
- **Who:** everyone wearing one, players and bots alike.
- **Numbers:** the crane's 32 degrees, its own angle from `config/skin-shapes.json`; the hinge is where the crane's wing
  joins the body on screen, worked out by the same rule on the screen and the server, so they always agree.
- **Fair both ways:** seen from above, a 32-degree wing covers 85% of the width it did flat; seen from the side or the
  front it covers more. Nothing grows.
- **Guns under the wing (question):** the drawn guns hang under the tilted wing. Suggest their hit shapes move with
  them, same size, so hitting the gun you see counts; shots still leave from the real spot.
- **Checks:** a test that each tilted wing keeps its size and its root stays on the body; a Studio flight of the crane
  past walls and through gaps.

## Tiers
| Tier | What it changes | How you get it |
|---|---|---|
| Common | a simple printed sheet | earn or Paper |
| Rare | a detailed or shiny printed sheet | earn or Paper |
| Legendary | printed sheet + add-on pieces, matching trail | Robux (later: a pass, missions, top players) |
| Mythical | a whole new shape, matching trail | Robux (later: a pass, missions, top players) |

## Ideas (Alan approved the whole list, 2026-11-13)
**Common:** hazard stripes · racing stripes · checkered flag · tiger stripes · jungle camo · desert camo · carbon
fibre · tie-dye · 8-bit pixels · flame decals · lightning bolts · neon grid.
**Rare:** gold foil · galaxy · lava (glowing cracks) · frozen (deep blue ice) · toxic slime · graffiti · holographic
· chrome · glitch · glowing circuit board · thunderstorm · cherry blossom · diamond. From the first list, if still
wanted: comic book, treasure map, candy wrapper, sticker bomb.
**Legendary:** shark jet · bumblebee · rocket (fins and nozzles) · hot rod (chrome exhausts, flames) · stealth
fighter (dark angled plates) · mech (armour plates, glowing eye) · pirate (sails, skull flag) · ninja (scarf
streamers) · race car (spoiler, number).
**Mythical:** dragon · bat · origami crane · phoenix · thunderbird (lightning) · UFO · ghost pirate ship (dark
wood, green glow) · kraken.
**Trails (all):** chalk dust · pencil shavings · eraser crumbs · confetti · rainbow marker · glitter · bubbles ·
music notes · ink splats · paper hearts · gold stars · crayon scribble.
**Matching trails:** dragon embers · little paper bats · falling folded petals (crane) · fire feathers (phoenix) ·
water spray (shark) · tiny bees (bumblebee) · rocket smoke · exhaust flames (hot rod) · gold coins (pirate) ·
lightning (thunderbird).

## Concepts (2026-11-13)
Codex drew every approved skin and trail on our plane shape: 13 pictures in `.planning/skins/concepts/` (common-1/2,
rare-1/2/3, legendary-1/2, mythical-1..4, trails-1/2; briefs `prompt-*.txt`, reference `our-plane.png`). Waiting on
Alan's picks. Notes: the Mech's pistons look like gun barrels (weapons must read from the real object); Chrome is pale
against the sky; shine, glow and the slime's drips are more than one picture (shine and glow maps, to check in Studio).

## Model sheets and the Shark Jet and Dragon builds (2026-11-14)
How shape skins are made now, the picks and the belly rule: [shape-skin decision](../decisions/2026-11-14-shape-skin-model-sheets.md).
Sheets in `.planning/skins/model-sheets/` (briefs `prompt-model-sheets-*.txt`): **Shark Jet `shark-jet-a4.png`**,
**Dragon `dragon-b8-legs.png`** (both views from the side, top, bottom and front). The Dragon is measured
(`.planning/skins/dragon/dragon-measured.jpg`, spec `measure-spec.json`; Alan OK'd it). **Next: the Dragon's head
test** with `tools/art/sheet_model.py` (body lofted through the sheet's outlines, painted by projecting the sheet's own
views, bumps and glow from the art). **Tool fixed 2026-11-14:** the Shark's nose
(`.planning/skins/shark/test-nose/review.jpg`) is clean on a 3x crop, checked by Claude and an independent reviewer
(it was scrambled on the jaw and underside: cause and fix in [lessons](../workshop/lessons.md), "Painting a model from
an AI model sheet"). Still true of any long pointy nose: seen straight from the front, the side painting stretches
into stripes (teeth, ridges), and teeth drawn low on the side wrap under the chin (body `mid` lower would move them up).
**Dragon head, projected** (`.planning/skins/dragon/test-head/`): Alan, "atrocious ... unusable", so the Dragon is
**built from measured pieces** ([decision](../decisions/2026-11-14-shape-skin-model-sheets.md)).
**Dragon head, measured pieces** (`.planning/skins/dragon/test-head-pieces/for-alan.jpg`, spec beside it; waiting on
Alan): five crest blades a side (tips on the sheet's drawn outline, laid back), brow and cheek blades, eye and socket,
two horns, green scales and a gold jaw; 1,526 triangles. Clean from every side. Short of the sheet: the blades are
straight daggers (the sheet's are curved leaves), the horns straight cones, the face slimmer than the three-quarter
drawing, the gold flatter. Next if Alan agrees: leaf-shaped and curved blades and horns, a fuller face, then the rest.
Then the full Dragon and Shark Jet, each beside its sheet before any upload. Codex picture
jobs for the six printed sheets (Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy) come after.

## Keeping skins cheap (Alan OK'd the budget, 2026-11-13)
- **Drawn by each player's own computer only.** The server just saves which skin and trail a player wears. The skin
  pieces and the hiding of the real parts happen on each player's screen, so the server never loads a skin, never
  builds a collision shape for one, and its hitbox copy keeps using the real parts with no change.
- **Budget per Legendary or Mythical skin: about 4,000 triangles and one set of pictures (colour, bumps, shine) at
  1024.** That is Roblox's own limit for an avatar hat; mobile shooters give a whole character 5,000-8,000. Today's
  plane is about 500-700 triangles; 12 planes at 4,000 is under 5% of the town's ~1 million.
- **Detail lives in the pictures, not the shape** (normal-map baking, how other games do it): a detailed model in
  Blender, its bumps and edges baked into a picture laid on a simpler model. Ropes, railings and scales are painted;
  thin things like torn sails are flat sheets with see-through edges. Roblox also swaps in simpler versions of a
  mesh far away by itself.
- **Ghost Ship last:** built after the pipeline works on a simpler Mythical, to this budget.

## First build batch (Alan's pick, 2026-11-13)
Commons Hazard Stripes, Tiger Stripes, Flame Decals; Rares Gold Foil, Lava, Galaxy; Legendary Shark Jet; Mythical
Dragon; trails Confetti, Rainbow Marker, Gold Stars. It proves every piece (printed sheet, add-ons, joints, trails,
Looks tab, shop) before the rest is made. Redrawn concepts: `chrome-2.png`, `crane-2.png` (blue and silver).

## Tests done and still to settle
- The printed sheet: **tested in Blender 2026-11-13 (no upload), it works**: one picture each (hazard stripes, lava)
  wrapped itself onto a standard plane and the heavy plane, carrying on across nose, body, wings and tail
  (`.planning/skins/printed-sheet-test.jpg`). To fix in the real script: faces pointing forward or back smear (they
  need a third, front-on view), and the paper creases must be moved onto the new layout so plain planes look as now.
- How Legendary and Mythical shapes fit any part mix: **joints test in Blender 2026-11-13 (no upload)**
  (`.planning/skins/joints-test-bat.jpg`). A rough bat is scaled evenly to the plane's length (head and ears keep their
  shape), its body sides move out to the real body (at most 60%), and each point of its wing outline sits on a corner
  of the real wing seen from above, the scallops redrawn between them; the tail webbing spans the real tail. It
  covered the wings of a swept and a straight-winged plane; the standard plane's tail fins stay uncovered (hitbox
  without skin, as Alan accepted). In Roblox each point would be a Bone. Not yet tried: flapping, real art.
- **The Origami Crane, built in Blender 2026-11-13 (fourth pass: head and neck rebuilt; no upload, waiting on Alan's OK)**
  (`tools/art/crane_skin.py`, renders in `.planning/skins/crane/`): 396 triangles and one 1024 set (colour, bumps,
  shine). **Deep blue paper with bright white lines, waves and blossoms, no metal** (Alan, same day: the metal
  look hid the detail). **Head and neck are one fixed shape** (Alan's ruling: they never stretch), measured from the concept
  (`.planning/skins/crane/crane-concept-measured.jpg`, Alan OK'd) as shares of the crane's body length: head 0.25, beak
  0.21, neck's first stroke 0.36 (almost level, 0.26 deep at the breast, 0.16 at the fold), second stroke 0.34 (rising
  about 40 degrees), widths 0.14 narrowing to 0.10, whole reach about one body length. They scale only with the plane's
  length and hang on a tall breast fold, so **the beak ends past the real nose** (Alan chose the concept's size: 2.2
  studs past on the starter, 2.3 heavy, 1.2 swept; no hitbox there). Neck and head are folded strips with real width
  (a fold on top, a corner each side), a Z: out from the breast, back up, the flat-topped kite head folded down, one
  closed beak. Folded layers are stacked on the back, shoulders, flanks and tail; the neck folds over itself and the head over the neck (Alan: "layers on layers"). The tail tip sits over the real
  tail's top back corner, the body on the real body (width capped at 1.7 x the scale), its keel on the real body's
  bottom and back over the booster spot. The wings keep one shape on every plane (0.85-1.2 x, to suit the real wing)
  and rise 32 degrees from the body's sides, so the blossoms never stretch; the real wings stay flat underneath, so
  the hitbox and the skin differ most at the wings. **Guns hang under the skin** (Alan, same day: nothing on top of a
  Mythical): each keeps its spot seen from above where that is under the wing, tilts with the wing and hangs by its
  top. In the renders that moved guns up to 3.4 studs up and 3.1 back (heavy plane's outer pair); whether shots then
  leave from the moved gun or the old spot is a rule for Alan before any code. Tried on the starter, heavy and
  swept-wing builds. **Game files for the first test (no bones):** `crane_skin.py --export=DIR` cuts the crane into
  five rigid pieces (head with neck, body, tail, each wing) in `assets/models/planes/skins/crane/`, each FBX in its
  own frame so the game only places and scales it, with the three pictures, `crane-fit.json` (reference sizes and
  each piece's box) and `crane-pieces.jpg` (the pieces read back from the files). **Still short of the concept** (independent review, 2026-11-13): the wings are about two thirds of
  the concept's size against the body and rise more steeply (so the neck looks big beside them and the near wing shows
  edge-on from the concept's angle), the tail is shorter and thinner, and the body has fewer big
  layers.
- What a Mythical does to weapons.
- Prices and earn rules per tier: drafted below, waiting on Alan's OK.

## Prices, earning and bots (Alan, 2026-11-13; his rulings in the [skin rules](../decisions/2026-11-13-skin-rules.md))
Robux prices OK'd for the first build ("they need to be adjusted" later). Common and Rare Paper prices use the same
rate as early part unlocks (about 18.75 Paper per Robux, the big pack's rate); an average player earns about 660 Paper
a match (about 8.5 minutes). Legendary and Mythical can be bought with Paper but cost far more, so Robux is the
sensible way (Alan; he OK'd 30,000 and 60,000 the same day).
| What | Robux | Paper | Average matches to earn |
|---|---|---|---|
| Common skin (Hazard Stripes, Tiger Stripes, Flame Decals) | 149 | 2,800 | about 4 |
| Rare skin (Gold Foil, Lava, Galaxy) | 299 | 5,600 | about 8.5 |
| Legendary skin + its trail (Shark Jet + water spray) | 599 | 30,000 | about 45 (6.5 hours) |
| Mythical skin + its trail (Dragon + embers) | 999 | 60,000 | about 90 (13 hours) |
| Trail (Confetti, Rainbow Marker, Gold Stars) | 49 | 900 | about 1.5 |
Compared with Rivals (Roblox's big shooter): its shop sells 299 / 449 / 599. Ours start lower (a new game, kids' pocket
money) and meet it at Legendary. For scale: the Pencil, the dearest part, is 32,000 Paper.
- **No free skins** (Alan). Later rewards (missions, playtime calendar, a pass, top players) can give skins or boxes.
- **Kept through prestige** (cosmetics already are). One skin and one trail for all your planes.
- **Bots all wear skins, by difficulty** (Alan): aces Mythical, experienced (veteran) bots Legendary, regulars Rare,
  rookies Common, each a random skin of its tier, picked when the match starts. Bots wearing a Legendary or Mythical
  show its matching trail; the others get a random plain trail (Claude's pick). Drawn on players' screens like every
  skin, so no server cost. In this batch every veteran is a Shark Jet and every ace a Dragon (aces are Studio-only
  for now).
- **Skin boxes, maybe later (Alan's idea, not in this batch):** a cheap box (Paper, or Robux) rolls a random skin, with
  Mythicals very rare; every skin can still be bought outright. A free box of Commons and very rare Rares as the reward
  for a player's first weekly mission (his pick over the tutorial). Roblox's rules
  ([research](../research/PRICING-RESEARCH-2026-10-18.md), section 9): every prize and its exact odds shown before
  buying; boxes bought with Paper count as paid too, because Paper can be bought with Robux; players where paid random
  items are restricted (`PolicyService`) can't open paid boxes, so outright buying stays for them; free reward boxes
  need no odds. Odds, price and what happens with a skin you already own come as their own numbers note.
- **Looks tab (hangar):** a new tab beside the parts. Every skin and trail as a card (worn, owned, price, or how to
  get it), your plane turns in front of you wearing your pick, and the line "Skins change how you look, never your
  hitbox".
- **Shop:** a "Skins & Trails" row in the shop window, the same cards, buy with Robux or Paper; Legendary and Mythical
  cards show their trail. Sold the same way as part unlocks (one Roblox product each, switched off until your go).

Back to [HOME](../HOME.md)
