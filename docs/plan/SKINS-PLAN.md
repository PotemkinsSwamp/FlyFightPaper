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
  Today it copies every *visible* piece, so skin pieces must be left out of that copy and hidden parts kept in it.
- **Common and Rare: a printed sheet.** Think of drawing on the paper before folding the plane. Each skin is one
  picture laid out like a flat plane seen from above (nose area, body stripe, wing areas, tail area). Every part's
  pieces get their picture position from where they sit on the plane, so any wings show the sheet's wing art and any
  nose shows its nose art. Switching parts needs nothing new: the game puts the same picture on the new pieces. Cost,
  once: a Blender script re-lays every part's picture layout this way (about 98 pieces, one upload batch with Alan's
  go). After that, each Common or Rare skin is one picture.
- **Legendary: your plane plus add-ons.** The printed sheet plus a few pieces (a shark's fin and jaw, a bee's stinger
  and wings) the game places on the body and nose and scales with the plane.
- **Mythical: a whole new shape.** One model the game stretches to your plane's length, span and height, shown
  instead of the parts. Weapons and boosters stay visible so everyone can still read what you carry.
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

## Still to settle
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
- Prices and earn rules per tier.

Back to [HOME](../HOME.md)
