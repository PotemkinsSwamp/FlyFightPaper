# Skins and trails plan

**Status:** talking it through with Alan (2026-11-13). Nothing gets made until the ideas and tiers are settled. His
rules: [skin rules](../decisions/2026-11-13-skin-rules.md) (hitbox is always your parts, one design per skin fitted by
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
  server's copy never sees a skin (see "Keeping skins cheap").
- **Common and Rare: a printed sheet.** Think of drawing on the paper before folding the plane. Each skin is one
  picture laid out like a flat plane seen from above (nose area, body stripe, wing areas, tail area). Every part's
  pieces get their picture position from where they sit on the plane, so any wings show the sheet's wing art and any
  nose shows its nose art. Switching parts needs nothing new: the game puts the same picture on the new pieces. Cost,
  once: a Blender script re-lays every part's picture layout this way (about 98 pieces, one upload batch with Alan's
  go). After that, each Common or Rare skin is one picture.
- **Legendary: your plane plus add-ons.** The printed sheet plus a few pieces (a shark's fin and jaw, a bee's stinger
  and wings) the game places on the body and nose and scales with the plane.
- **Mythical: a whole new shape.** One model scaled evenly to your plane's length, with joints moved onto the real
  wing and tail corners (tested below), shown instead of the parts. Weapons and boosters stay visible so everyone can still read what you carry.
- **Players are told:** "Skins change how you look, never your hitbox", on the shop card and the Looks tab.

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
