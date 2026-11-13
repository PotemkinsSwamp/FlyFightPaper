# Skins and trails plan

**Status:** talking it through with Alan (2026-11-13). Nothing gets made until the ideas, tiers and how they work are
settled. His rules so far: [skin rules](../decisions/2026-11-13-skin-rules.md) (same hitbox, four tiers, team outline,
bots wear them), on top of the [shop plan decision](../decisions/2026-10-18-shop-plan.md) (Paper or Robux, kept
through prestige). Serves [the beta has to feel finished](../decisions/2026-11-06-beta-feels-finished.md).

## The order (Alan, 2026-11-13)
1. A list of ideas for skins and trails, sorted into tiers.
2. Talk through how they work (team games, hitboxes, part mixes).
3. Concept pictures of the picked ideas (Codex).
4. Build them in Blender and texture them.
5. Only then prices, uploads (Alan's go) and the code.

## The hitbox today, and how skins keep it
- **Today the hitbox is the plane's own visible pieces, exactly.** The server copies every visible piece (body, nose,
  wings, tail, weapons, booster) and tests shots against their real mesh shapes (`src/server/HitShapes.luau`).
- **Danger:** a skin added as extra visible pieces would join that copy and grow the hitbox. So the server's copy must
  always come from the plain pieces, never from a skin.
- **Paint skins (lower tiers):** the same pieces with a new picture on them. The shape can't change, so the hitbox is
  identical. One design is turned into a picture for every piece by a Blender script.
- **Shape skins (top tiers):** in Blender, each piece of the design starts from the real part's own shape and is
  wrapped onto it. A measuring script checks every skin piece against its part before anything is uploaded: nothing
  may stick out past the part or leave a gap bigger than a set amount (a first guess: a tenth of a stud). A dev
  button in Studio shows the hitbox over the skin.
- **Part mixes:** 6 bodies, 6 noses, 6 wings and 6 tails, so a shape skin needs 24 shaped pieces to fit every plane.
  The Blender script makes them from one design. If a design can't fit a part well, that skin is tied to a body.
- **Visibility:** no skin may be see-through or blend into the town (that is an advantage too). Names and team marks
  show over every plane.

## Tiers (classroom names to pick)
| Tier | What it changes | How you get it |
|---|---|---|
| 1 | one simple print on the plane's own shape | earn or Paper |
| 2 | detailed art on the plane's own shape | earn or Paper |
| 3 | small shape changes inside the hitbox, plus a matching trail | Robux (later: pass, top players) |
| 4 | the whole plane's form, plus a matching trail (and maybe a fold effect) | Robux (later: pass, top players) |

Name ideas: **C, B, A, A+** (the report card's grades) · **Sticker, Silver Star, Gold Star, Gold Apple** ·
**Homework, Honor Roll, Principal's List, Hall of Fame**.

## Ideas (✓ = Alan kept; the rest are new, for him to keep or drop)
**Tier 1, simple print:** ✓ newspaper glider · graph paper · notebook lines · construction paper (a colour) · sticky
note · brown paper bag · polka dots · checkerboard · cardboard box · ruler marks.
**Tier 2, detailed art:** ✓ gold foil · ✓ homework A+ · ✓ comic book · ✓ candy wrapper · ✓ old treasure map ·
✓ sticker bomb · sheet music · spelling test · math worksheet · birthday card · fridge drawing (crayon art) ·
permission slip · baseball card.
**Tier 3, small shape change:** ✓ shark jet · swordfish · bumblebee · dragonfly · hawk · goldfish.
**Tier 4, whole new form:** ✓ dragon · ✓ bat · ✓ origami crane (if its shape can match the hitbox) · phoenix · moth.
**Trails:** chalk dust · pencil shavings · eraser crumbs · paper confetti · rainbow marker · glitter · bubbles · music
notes · ink splats · paper hearts · gold stars · crayon scribble. Matching trails for tiers 3-4: dragon embers, little
paper bats, falling folded petals for the crane, sparks for the phoenix.

## Still to settle
- Tier names; which new ideas stay; which tier each sits in.
- Trails in team games: their own colours or the team's.
- How much a shape skin may differ from the hitbox (the tenth of a stud above is a guess).
- Prices and earn rules per tier (after the list).

Back to [HOME](../HOME.md)
