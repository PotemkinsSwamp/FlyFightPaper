# Skins and trails plan

**Status:** building the first batch (2026-11-13). Printed-sheet Commons and Rares work in Studio (Alan OK'd, test
pictures; [playtest](../playtests/2026-11-13-printed-sheet-skins.md)); buying with Paper, wearing and the Skins and
Trails tabs built; boosters wear printed skins. The Origami Crane (first Mythical) is in the game as five fitted pieces
(`SkinShapes.luau`), with playtest bugs to fix and its printed sheet next; the wing-hitbox tilt is built
([playtest](../playtests/2026-11-13-crane-and-skins-tabs.md)). The Dragon (second Mythical) is built as a shape skin that
keeps its proportions and is the hitbox (Alan: "looks good now", 2026-11-16). **Done 2026-11-16 ([first skin set](../decisions/2026-11-16-first-skin-set.md)):** the Dragon's boosters wear its scales; the 8 Commons are drawn in code and in the game's list. **Next:**
the 8 animated Rares (how-it-works note OK'd by Alan 2026-11-16, "Moving Rares" below; preview videos being made). Later: Shark Jet, trails. His rules: [skin rules](../decisions/2026-11-13-skin-rules.md) (hitbox is always your parts, one design per skin fitted by
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

## Moving Rares: how it works (Alan OK'd it 2026-11-16)
**Alan: "Those rules or notes work. Go ahead and build them and then show me some videos"** (200 studs fine; glow up
close, not a beacon). **Built and in the game (2026-11-16):** he OK'd all eight on preview videos ("Put them in the
game"); 44 pictures uploaded and approved; `src/client/PlaneLooks.luau` draws the layers with `src/shared/SkinMotion.luau`'s
sums. Seen right on test planes in Studio Edit (`.planning/skins/rares/rares-in-studio.jpg`). **Still to do, each on Alan's
go:** see them move in Play, re-run the tests, the 12-plane frame-rate check. From the [first skin set](../decisions/2026-11-16-first-skin-set.md) (Rares move and glow; Alan's
answers from the talk are there).
- **What the player sees:** a Rare is a still skin picture, plus moving layers on top of it, plus a glow. Everything stays
  on the plane's surface and loops. Nothing reacts to boosting, shooting or damage, and nothing flies off the plane (that
  is the trails' job).
- **Who and where:** every plane that wears one, bots included, in matches and in the hangar; boosters move with the rest.
  Shop cards stay still pictures. Drawn on players' screens only: no change to hitboxes, speed or the server.
- **Up close only:** movement runs on planes within about 200 studs of your camera (12 plane lengths). Farther planes
  wear the same skin standing still (Alan: planes are too fast to read a skin from far away).
- **Glow:** bright up close, not a beacon. Glowing bits stay lit in shadow; the soft halo round them shows on High
  graphics only.

| Rare | Still picture | What moves | What glows |
|---|---|---|---|
| Galaxy | Blue and purple space clouds, a few still stars | Stars drift nose to tail (one pass in 20 s). One small solar system a wing, turning at two speeds: a sun with two planets (a lap in 9 s), a giant with two moons (14 s, the other way). First drawn as one big orbit round the plane's middle: every planet was cut in two where it crossed the body's step (2026-11-16). A comet with a tail crosses the plane in 1.5 s, one every 4 to 7 s | Stars twinkle in two groups, out of step (2 s each) |
| Lava | Black cracked rock | Molten orange creeps inside the cracks, nose to tail (one pass in 30 s; the first try at 6 s was "very, very fast") | Cracks breathe brighter and dimmer (4 s) |
| Slime | Bright green goo on dark paper | Two layers of thick goo slide to the tail at different speeds (one pass in 34 s and in 16 s), the quick one over the slow one, so lobes push out, merge and split. The first try slid one whole goo picture and did not read as oozing; still pools with thin drips under them hid the drips | Bubbles glow faint green (pulse 2.5 s) |
| Holographic | Silver foil | Rainbow bands sweep across at a slant (one pass in 4 s) | A glint line runs nose to tail every 5 s |
| Glitch | Dark, broken colour blocks | Blocks and scan lines snap to a new spot for 0.1 s, every 0.8 to 2 s | Bright blocks flicker on each snap |
| Thunderstorm | Dark storm clouds | Clouds roll back (one pass in 12 s) | A lightning bolt double-flashes every 3 to 6 s, in a new place each time |
| Circuit Board | Dark green board, copper lines | Pulses of light run along the lines (one pass in 3 s) | Lines glow; small lights blink (1 s) |
| Comic Book | Bold panels, dots, thick black outlines | Speed lines streak back from the nose (one pass in 1.5 s). "POW!", "SLAM!" and "ZAP!" take turns: each slams in big, shakes, holds 1.5 s and fades, one every 2.5 s | The word's burst flashes as it slams |

- **How it is drawn (Claude's method):** each moving layer is a see-through picture (a Roblox Decal) laid over the printed
  sheet; code slides it, turns it, sizes it and changes its glow. Lava and Circuit Board put the moving layer under a top
  picture with holes. A Decal stretches its picture over each piece's own box, so the code sets every piece's layers from
  where that piece sits on the sheet ([lessons](../workshop/lessons.md), "Moving skin layers").
- **Cost:** no money, no Tripo credits. 44 free pictures for the eight (3 to 8 a Rare; 5 more were re-sent as squares and
  their first copies are unused). Each moving layer draws a piece's top once more: Galaxy is heaviest (5 draws).
- **Known limits:** the layers draw on up-facing sides only, so **undersides and the body's sides wear the still sheet**
  (the preview videos moved there too; a second set of Decals facing down would move the undersides, at twice the layers).
  Planets, comets and words live on the wings and the top of the body.
- **Checks:** each Rare goes to Alan as a short video on real planes (starter, blunt nose, heavy) before any upload; a
  test that every loop ends where it starts (no jump); a frame-rate check with 12 planes all wearing Galaxy, which must
  hold 60 (if it dips, Galaxy's planets share one layer before anything else changes).

## Trails: how it works (Alan OK'd it 2026-11-16)
From the trails talk ([first skin set](../decisions/2026-11-16-first-skin-set.md), Alan's words there). He OK'd the length, the
growth when fast and the list; he changed the bots rule and parked the price ("we're not worried about price right now.
We're worried about just making them"). **Being built:** Holo Rainbow, Gold Stars and Storm Sparks first.
**The first videos were "bad" (Alan, 2026-11-16): flat pictures, seen from above, stars in an even line.** He wants 3D
depth and texture, pieces at random sizes "in almost a cloud formation", shown in a 3D scene ("We need to make them
3D"); the width is fine. **So the method below changed: pieces are small 3D models, not flat pictures**, and the
preview is a Blender scene from the game's own camera. Redone as 3D videos; waiting for his look. Not yet settled:
how the game draws 3D pieces (see "How it is drawn").
- **What the player sees:** a thin stream from the back of the body, between the boosters. It starts about 1.5 studs wide
  (the white boost streak's size) and narrows to a point; its pieces shrink and fade toward the end. Always on while the
  plane flies; it stops when the plane lands or crashes and what is in the air fades out.
- **Longer when faster, by itself:** every bit of trail lives **1 second**, so the stream is as long as the distance flown
  in that second: about 45 studs on the slowest plane, 105 on a typical one (6 plane lengths), 155 on the fastest. A boost,
  a dive that builds speed and a speed bolt all stretch it with no special rule.
- **A little bigger when faster than your build:** the trail reads your speed against your plane's normal speed and grows
  up to **1.3 times** wider and brighter (boost, dive, speed bolt alike). The white boost streak and the damage smoke
  stay as they are: both tell players something.
- **Your own view:** the camera sits 24 studs behind you, so you see the first 24 studs of your own trail. It is a thin
  line that passes under the camera: nothing drifts across your aim.
- **Who sees it:** everyone, on every plane that wears one, bots too. Trails keep their own colours in team games
  ([skin rules](../decisions/2026-11-13-skin-rules.md)). A trail makes a plane a little easier to spot; thin and one
  second long keeps that small.
- **Looks only:** no change to speed, hits or the hitbox. Drawn on each player's screen; the server only keeps the
  trail's name (it already does).
- **Hangar:** the plane stands still, so a short fixed version (about 2 plane lengths) blows gently back off it. Clicking
  a trail in the Trails tab shows it on your plane at once. Shop and tab cards get a still picture of each trail.

**The list (13 now, 1 later).** Cut by Alan: pencil shavings, eraser crumbs, ink splats, crayon scribble.

| Trail | Goes with | What you see | Made by |
|---|---|---|---|
| Chalk Dust | plain | Soft pastel dust puffs on a faint chalk smear | code-drawn |
| Confetti | plain | Paper strips and curls in five colours, tumbling | code-drawn |
| Music Notes | plain | Black and gold notes bobbing along the stream | generated cut-outs |
| Paper Hearts | plain | Folded red and pink paper hearts, shrinking to the tail | generated cut-out |
| Gold Stars | plain | Gold foil stars that twinkle | generated cut-out + code-drawn twinkle |
| Stardust (was Glitter) | Galaxy | Purple and blue dust with tiny white stars | code-drawn |
| Goo Bubbles (was Bubbles) | Slime | Green goo bubbles that wobble and pop, on a thin dribble | code-drawn |
| Holo Rainbow (was Rainbow Marker) | Holographic | A rainbow ribbon with a silver shine sliding along it | code-drawn |
| Glitch Pixels | Glitch | Square blocks in cyan, pink and white that jump sideways and blink | code-drawn |
| Storm Sparks | Thunderstorm | A grey cloud wisp with small lightning forks that flash | code-drawn |
| Circuit Trace | Circuit Board | A green line stepping back in right angles, a light running along it | code-drawn |
| Dragon Embers | Dragon (comes with it) | Orange and gold embers that flicker and rise, a thin smoke wisp | code-drawn |
| Folded Petals | Origami Crane (comes with it) | Blue and silver folded paper petals, turning as they fall | generated cut-out |
| Water Spray | Shark Jet (comes with it) | waits for the Shark Jet | later |

Lava and Comic Book have no matching trail. Names are Claude's picks.
- **How they are sold:** the five plain ones as today (49 Robux or 900 Paper). The six that match a Rare are sold **on
  their own** (Alan) and can be worn with any skin. **Price not set:** Alan: they "would probably be more expensive" than
  a plain trail; decided later. Until then the list carries a stand-in of 99 Robux or 1,900 Paper (live sales are off).
  Dragon Embers and Folded Petals come with their skin; anyone who already owns the crane gets its petals.
- **Bots (Alan, 2026-11-16; replaces "bots all wear skins"):** "Not every bot needs skins. Not every bot needs trails."
  "They also need a roll for having both." So each bot makes one roll with four results: skin and trail 35%, skin only
  35%, trail only 15%, neither 15% (Claude's numbers, the same as 70% a skin and 50% a trail; one line to change). A bot
  with a trail wears its skin's matching trail when the skin has one; otherwise a random one.
- **Looks OK'd by Alan (2026-11-16, 3D videos in `.planning/skins/trails/`, numbers in `config/trails.json`):** Gold Stars
  (foil stars, flakes, sparkle dust), Storm Sparks (thick soft smoke lit from inside by lightning), Holo Rainbow (thick
  soft rainbow smoke, the colours running through three times along the stream, foil flakes and sparkles). A trail must
  read as one thick body: a turning ribbon, wound cords, cotton balls and sparse crystals were all turned down.
- **How it is drawn (Claude's method, changed after the first videos):** every trail has the same bones. A **ribbon**
  (Roblox calls it a Trail) is a strip laid along the path just flown; it can be laid turning, like a streamer.
  **Pieces** are small 3D models (a folded foil star, a foil flake, a cotton puff, a lightning fork) dropped behind,
  scattered round the path at random sizes, tumbling, growing out of the tail and shrinking away. Roblox's own
  particles are flat pictures that always face you, so 3D pieces are real small parts moved by the player's own
  computer (no physics, nothing on the server): about 30 to 60 a plane, a few hundred in a 12-plane match. **Open:**
  the frame-rate check decides whether that holds 60; the fallback is flat particles showing a pre-rendered spinning
  3D model. Roblox's built-in Foil, Fabric and Neon materials give the texture with no picture to upload. Soft smoke (Storm
  Sparks, Holo Rainbow) is the exception that suits Roblox's own particles: soft flat cards that face you are exactly
  what they draw. **Built 2026-11-16 (`src/client/PlaneTrails.luau`, not yet seen in Play):** smoke and sparkle dust
  use the smoke and sparkle pictures Roblox ships (the game already used both), so no picture is uploaded; a foil
  flake (under half a stud) is a plain thin block; only the star and the lightning bolt are uploaded models
  (`tools/art/trail_pieces.py`, ids in `config/trails.json` `meshes`). Sparkle dust became particles too: 170 a second
  as parts was too many. Gold Stars is about 70 to 90 moving parts a plane, so the 12-plane frame-rate check is still
  open. One short piece of code reads each trail's row in `config/trails.json`; no trail gets code of its own.
- **How the pictures are made (written before the 3D change; now only ribbons and any flat glows use pictures):** most are drawn by code in PhotoCraft (free, on Alan's PC at
  `D:\ArtCraft\PhotoCraft`; a test streak drew fine, `.planning/skins/trails/photocraft-streak-test.png`), following the
  video Alan sent (YorusDevs, "How Opus 5.5 drew every visual effect in my Roblox game"): shapes in **white, in layers**,
  so the game colours each layer (one spark drawing serves several trails); a **frame sheet** (a 4 by 4 grid of frames
  Roblox plays in turn) where a piece must change as it flies (twinkle, flicker, pop); nothing within 4 pixels of a
  picture's edge (or a square shows); **red only as glow or flame, never drops** (reads as blood). Pieces that must look
  like folded paper (hearts, stars, notes, petals) are generated pictures, cut out: code-drawn glow shapes look like any
  Roblox game, and the hand-made look is the point.
- **Cost:** no money, no Tripo credits. About 30 small free pictures (256 or 512 across). Codex draws the four
  generated ones on Alan's ChatGPT plan; the rest is the main session.
- **Order:** three first, one of each kind, to prove the bones: Holo Rainbow (ribbon), Gold Stars (generated pieces),
  Storm Sparks (code-drawn frame sheet). Then the other ten.
- **Checks:** each trail goes to Alan as a short video (a plane at normal speed, then boosting) before any upload; the
  video is made by a script that imitates the game, so the real look is confirmed in Studio after upload. Then the
  safety look at every picture, then upload. A test that every trail on the list has its pictures and its price; a
  frame-rate check with 12 planes all wearing the heaviest trail, which must hold 60 (Alan's go). No distance cut-off to
  start: that check decides whether far planes need one.
- **Known limits:** on low graphics settings Roblox itself draws fewer pieces, so phones may show thinner trails.

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
**Trails (all; four cut and three renamed 2026-11-16, see "Trails: how it works"):** chalk dust · pencil shavings · eraser crumbs · confetti · rainbow marker · glitter · bubbles ·
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
drawing, the gold flatter.
**Dragon head, painted skin + built pieces** (Alan's idea; `.planning/skins/dragon/test-head-hybrid/for-alan.jpg`;
waiting on Alan): the skin (scales, eye, flat gold cheek plates, jaw) is painted from the sheet; the crest blades and
horns are built; where a view's picture shows a built piece in front of the skin, that view does not paint there
(`cut` in the spec) and skin no view shows gets matching scales. The face and eye are the closest to the sheet yet.
Short of it: the blades and horns are still straight daggers and cones; small scraps of drawn gold left at a few seams
(snout's lower edge, behind the crest from above); the chin smears when seen straight from the front.
**Dragon head with the upgraded skill, Opus run** (2026-11-14; `.planning/skins/dragon/head-skill/`, piece map
`piece-map.png`, rounds `round-01`..`round-07`, `round-07/for-alan.jpg`): built from the top, three-quarter and front views
([Alan's view ranking](../decisions/2026-11-14-shape-skin-model-sheets.md)); top outline 0.908, side 0.847; reviewer
"not yet" (front-view horns wide flat slabs, thin gold on the face, egg-shaped head from the front). Alan: "the skills
definitely helped, but I just don't think you have the capability"; a **Fable 5.2 run** of the same skill from scratch
(`.planning/skins/dragon/head-fable/`, `compare.jpg`) is the comparison. Then the full Dragon and Shark Jet, each beside its sheet before any upload. Codex picture
jobs for the six printed sheets (Hazard, Tiger, Flame, Gold Foil, Lava, Galaxy) come after.

**Whole Dragon, Fable run** (2026-11-14 and 15; `.planning/skins/dragon/body-fable/`, picture `sheet-vs-model.jpg`):
the rebuilt head won the blind comparison in three of four views and Alan called it "definitely an improvement"; the
whole dragon followed (round 14: one closed mesh, 3,334 triangles) and went through three correction passes on his
lists. He still saw "a lot of problems" and gave a third list: stop whole-body passes and rebuild the wings, head
armour, tail root and legs one part at a time, each checked alone in close-up (round 15). He approved the tail as
built and gave a fourth list (straight claws as the side and bottom views draw them, one narrow wing root, veins and
folded bays, heavy fin caps): round 16 (one closed mesh, 3,926 triangles; `round-16/check.jpg`, `close-*.jpg`),
waiting on his look. **Tripo test (2026-11-15):** a six-view set painted over Blender renders, fed to Tripo Pro nose-up,
gave the right shape at ~4,000 triangles; Tripo's own paint is too soft for the player's view, so (Alan) Tripo makes the
shape and Blender paints it from the approved views ([details](../decisions/2026-11-14-shape-skin-model-sheets.md)).
**Painting the Tripo shape (2026-11-15):** 3,720 triangles after clean-up; painted piece by piece (Alan): gold pieces
by code, smooth pieces from paintings made over renders of this shape; second pass shown, gold still too flat (same note).
**Parts and bake (2026-11-15, late):** projected paintings dropped (Alan); each part is made high-detail in Tripo and
baked onto our low-triangle mesh in Blender; the head test is done and shown (same note).
Rulings and all four lists:
[model-sheet decision](../decisions/2026-11-14-shape-skin-model-sheets.md).

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
