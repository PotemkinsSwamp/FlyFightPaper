# Skins: same hitbox, one design per skin, four tiers, team outline

**Decided:** 2026-11-13 (Alan)  
**Status:** in force; the idea list is still being talked through on the
[skins plan](../plan/SKINS-PLAN.md). Nothing is made yet.

## Decision
- **A skin never changes the hitbox.** Your hitbox is always the parts you fly, inside the skin. A skin is only a
  look with no hitbox of its own, so wearing one is never an advantage or a disadvantage. It may be bigger or smaller
  than the plane to keep its look (an origami crane's head won't fit on a plane), so a shot can hit where no skin
  shows; the game tells players a skin changes only the look, not the hitbox. This replaces "the skin draws over the
  whole plane" in the [shop plan](2026-10-18-shop-plan.md).
- **One design per skin, fitted by the game** (Alan, same day): never a hand-built version for every part. Lower
  tiers are a design the game wraps round whatever parts you fly, automatically when you switch; top tiers are one
  general shape the game scales to your plane.
- **Four tiers: Common, Rare, Legendary, Mythical.** The tier sets the price, the effort to earn it, and where it
  can be a reward. Legendary and Mythical change the plane's form (dragon, bat, origami crane) and come with a
  matching trail; Common and Rare only change the look.
- **Cool first:** skins don't have to be school or animal themed. They should be things players really want.
- **No very white skins:** white is hard to see against the town.
- **Earning:** the lower two tiers can be earned. The top two are bought (Robux, or a very high Paper price: see
  Prices below), except later through things that keep players coming back: a pass like Fortnite's, the playtime calendar, weekly missions, or being among the top
  players.
- **Team games: no team colours on skins.** A team shows through three signs: a faint red or blue outline on the
  plane, the name in team colour, and the square or circle under the name (made easier to see from far away). Aim
  help already never locks onto a teammate.
- **One skin for all your planes:** the game fits it to whatever parts you fly (tied to a body only if fitting
  fails).
- **Bots wear skins,** so players see them in matches and want them. **All of them, by difficulty** (Alan, same day):
  aces Mythical, veterans Legendary, and so on down.
- **Prices** (Alan, same day): the drafted Robux prices are OK for the first build and will be adjusted later
  ([skins plan](../plan/SKINS-PLAN.md)). Legendary and Mythical can also be bought with Paper, but extremely
  expensive (Legendary 30,000, Mythical 60,000 Paper), so players would rather use Robux. **No free skins.**
- **Skin boxes, maybe** (Alan, same day): a cheap box (Paper or Robux) with a small chance of a Mythical, like CS:GO
  crates, while every skin can still be bought outright. A free box of mostly Commons (Rares very rare) as the reward
  for the first weekly mission. Not decided yet. Roblox's rule to show every prize's odds is fine with Alan ("we can show percentages").
- **Legendary and Mythical hide the plane** (the parts they cover): the hidden parts stay the hitbox, the skin has no
  collision, and the red or blue outline goes round the skin. They must still look good on every part mix, so no
  plain stretching: the way they fit is to be worked out.
- **Only Mythicals change weapons,** to give them a real effect. Their shots may look different (a dragon fires
  embers) but never change size or speed, so no skin makes anyone easier or harder to hit or dodge.
- **Trails keep their own colours** in team games.
- **No skin needs animation** (Alan, after the concepts): shine and sparkle are in the pictures, not moving effects.
- **Skins must not cost frame rate or server work:** drawn only on players' screens; at most about **4,000 triangles**
  and one 1024 picture set per Legendary or Mythical (Alan OK'd the budget); detail baked into the pictures. The
  Ghost Ship is built last, to that budget.
- **A Mythical's head and neck never stretch** (Alan, same day, after the crane's third pass): they keep the
  concept's proportions and only scale evenly with the plane, bigger or smaller. So on a long-nosed plane the beak
  may stop short of the nose tip (hitbox there with no skin over it).
- **A Mythical must look like its concept** (Alan, same day): layers on layers, the concept's shapes (the crane's
  Z-shaped neck, big folded head), judged from above and behind as well as from the side. Measure the concept first.
- **The crane's lines are bright white, not metal** (Alan, same day, after the fourth pass): deep blues and bright
  whites like the concept; the metal look came out "almost purple" and "takes away from the detail". White stays in
  lines, waves and petals only, so the skin is still not a very white one.
- **Guns go under a Mythical, never on top** (Alan, same day): "we don't want the weapons blocking the skin". Where
  shots then leave from (Alan, same evening): the game's real shot spot stays, so a skin never changes play; only
  the drawn bullet starts from the gun you see. Skinning the weapons to match a Mythical is a maybe for later, not now.
- **A shape skin may tilt the wing hitbox to match its wings, never resize it** (Alan, same evening, after flying the
  crane: "you'll hit things and not realize ... because you don't know where the actual wing is"; a general rule, not
  crane-only). The server tilts the real wings' hit and crash shapes up to the skin's angle (the crane: 32 degrees at the
  root), same size, so shots hit the wing you see and you crash only where it really is. It replaces the earlier
  "V wings over a flat hitbox". **Build it, and the gun hit spots move to where the skin draws the guns** (Alan
  2026-11-14, after reading the how-it-works note).
- **A Mythical gets a matching printed sheet** (Alan, same evening): the crane's blue wave-and-blossom paper as a
  printed-sheet picture, so boosters (and later maybe guns) wear it like a Common or Rare.
- **First build batch** (Alan's pick): Hazard Stripes, Tiger Stripes, Flame Decals; Gold Foil, Lava, Galaxy; Shark
  Jet; Dragon; trails Confetti, Rainbow Marker, Gold Stars.
- **After the first Studio look** (Alan, same day, [playtest](../playtests/2026-11-13-printed-sheet-skins.md)): the printed sheet works for Commons and Rares. **Boosters wear the skin too** (they carry the team colour, so they are part of the plane). A **Skins tab and a Trails tab** in the customization menu show your pick on your plane. **The first Mythical is the Origami Crane** (blue and silver; "push the boundaries"), built in Blender by Fable itself next session.
- **Concept changes:** the Origami Crane turns blue and silver (it looked too like the Phoenix); Chrome keeps white
  only as small reflection glints. The Mech stays as drawn.
- **Ideas:** every skin and trail on the [skins plan](../plan/SKINS-PLAN.md) list (Alan approved the whole list).

## Why
Alan: skins that change hitboxes are a big problem in many games and must not be one here. Tiers let prices and
effort be set fairly and let skins be rewards. Names, the dot and aim help already tell teams apart, and some skins
change the whole plane, so team paint isn't needed.

## Affects
[Skins plan](../plan/SKINS-PLAN.md), [Economy and shop](../systems/economy-and-shop.md),
[Planes and hangar](../systems/planes-and-hangar.md), [Damage and deaths](../systems/damage-and-deaths.md) (hit shapes).

All decisions: [decisions](README.md)
