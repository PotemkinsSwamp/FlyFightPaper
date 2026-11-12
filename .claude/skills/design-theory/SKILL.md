---
name: design-theory
description: Design and colour theory for Fly Fight Paper's screens. Use BEFORE building, changing or showing Alan any UI, menu, card, note, button, HUD piece, shop or hangar screen, icon, picture backing, concept art, colour or layout choice in this Roblox game, and run its checklist on a screenshot before anything visual goes to Alan.
---

# Design theory for Fly Fight Paper

Alan (2026-11-12): screens need real design and colour theory, not guesses. Two picks failed that day: brown kraft
circles behind shop pictures ("looked very bad") and an off-white circle on the blue fold card ("just doesn't look
good"). Both broke rules below. Worked examples: [design examples](../../../docs/workshop/design-examples.md).

House rules this skill sits on top of (read them, don't restate them):
- Hand-made, kid-made crayon and paper beats clean generic Roblox polish; fix readability, keep the look
  ([text style decision](../../../docs/decisions/2026-11-08-text-style-crayon.md), [art direction](../../../docs/vision/ART_DIRECTION.md#menu-and-ui-look-alan-2026-10-08)).
- Words sit inside their paper, centred, even gaps; paper grows to fit its content
  ([lessons: Working with Alan](../../../docs/workshop/lessons.md#working-with-alan), [menus and HUD](../../../docs/systems/menus-and-hud.md)).
- Everyday screens (shop first) use the layout real Roblox games use, dressed in our materials.
- In-game menus reuse the main menu's art ([decision](../../../docs/decisions/2026-10-11-in-game-menus-match-main-menus.md)).
- Art target: `assets/references/classroom-city-approved-v1.png` (warm daylight, cardboard tan, school primaries,
  white paper planes as the brightest thing).

## 1. Colour

**Value before hue.** Value = how light or dark a colour is. The eye separates shapes by value first; hue (red vs
blue) comes second. Two colours of the same value blur together even if their hues differ. Test: look at the
screenshot in greyscale (`contrast.py shot.png`). If a thing disappears in grey, it is weak in colour too.

**Making a subject pop.** A subject reads when it differs from its backing in value (best), then saturation, then
hue. White and pale things need a DARK backing; dark things need a light one. A mid-value backing (kraft brown, sky
blue, grey) contrasts with nothing. Aim for at least 3:1 between a picture's main colour and its backing.

**Harmony schemes** (for picking a backing or accent):
- Analogous: neighbours on the colour wheel (blue, indigo, violet). Calm; good for a backing that should belong to
  its card. Separate the subject by value.
- Complementary: opposites (blue/orange, red/green, violet/yellow). Loudest pairing; use for the one thing that must
  pop (our yellow part names on the blue Featured card).
- Split complementary: a colour plus the two neighbours of its opposite. Lively but safer than straight opposites.

**Saturation hierarchy: one loud thing per card.** The most saturated, highest-contrast spot wins the eye. Decide
what that is (usually the buy button or the item) and keep everything else quieter. Two loud things fight.

**60-30-10.** About 60% a dominant colour (the board, the card), 30% a secondary (papers, panels), 10% accent (the
button, the name). On busy crayon art the card is the 60; don't add a third loud colour on top.

**Warm vs cool.** Warm colours (red, orange, yellow, cream) come forward; cool ones (blue, green, violet) sit back.
A warm off-white disc on a cool blue card jumps forward as a flat sticker. Backings should usually be cooler or
darker than what sits on them.

**Why a pale flat shape on a saturated multi-hue background looks wrong.** It is the lightest, largest, flattest
thing on the card, so it wins figure-ground: the eye reads it as a hole cut in the card or a sticker stuck on it, and
the item on it becomes a detail of that hole. It also steals the "one loud thing". Pale backings only work on pale
paper (and then white items vanish on them).

**Tinting existing art.** Roblox `ImageColor3` multiplies an image's colours, so a pale paper picture can become any
darker colour and keep its torn edge and texture. Value to set per channel = target / picture's own colour x 255.
Prefer this over new art for a colour change.

## 2. Layout (Gestalt laws and friends)

- **Figure-ground:** every screen has one clear figure (what you act on) and a quiet ground. A backing that matches
  the board behind its frame reads as a hole through the paper, not a mat.
- **Proximity:** things that belong together sit closer to each other than to anything else. Two dark shapes that
  nearly touch (a dark mat right above a dark price label) merge into one blob; leave a clear gap.
- **Similarity:** same job, same look. Every picture backing in the shop and on the fold card is the same colour and
  shape; every buy button is the same green; labels don't borrow button art.
- **Alignment:** edges and centres line up on a few lines. Centre things that are centred; left-align lists.
- **Hierarchy:** size, contrast, then position. The title is biggest, the action is loudest, the details are small
  and quiet. Squint at the screenshot: the order you see things in is the hierarchy.
- **Reading order:** text-heavy screens are read in an F (top line, then down the left); sparse cards in a Z (top
  left, top right, across, bottom right). Put the item where the eye starts and the button where it ends.
- **Fitts's law:** the bigger and nearer a target, the faster it's hit. The main action is big and sits on the eye's
  path (middle or end of the Z), never a small thing in a corner. Close/X is small and in a corner on purpose.
- **Buttons look pressable, labels don't.** A button: its own paper strip with a clear edge or shadow, loud colour,
  a verb ("Buy", "Claim"). A label: words on the card or a dark flat pill, no edge, no verb. If something looks like
  a button it must do something.

## 3. Readability

- Contrast ratio (WCAG): body words need 4.5:1 against what's directly behind each letter; big words (about 24 px+
  or bold 19 px+) and icons need 3:1. Measure with `contrast.py`, on the darkest and lightest spots behind the words.
- Busy art (crayon streaks, chalkboard dust, cork) changes from letter to letter, so a single ratio lies. Give words a
  solid edge (our ink outline, `PaperUI.loud`), or put them on a backing plate (a paper slip, the dark label pill).
- White or yellow words on colour get the ink edge; ink words go on light paper. Never thin grey words on texture.
- On phones everything is smaller; check small words at phone size too ([screen fit plan](../../../docs/plan/SCREEN-FIT-PLAN.md)).

## 4. Our palette (measured from the art)

| Piece | RGB | Notes |
|---|---|---|
| Ink (words) | 40, 30, 24 | `PaperUI.INK`, warm black |
| Shop chalkboard | about 10, 55, 30 | dark green; the shop window's ground |
| Cream paper (item square, pale circle, tabs) | about 240, 225, 208 | value nearly equal to white (1.1:1) |
| Featured card crayon | about 36, 79, 230 to 101, 40, 236 | blue to violet with magenta, orange, cyan streaks |
| Card colours | orange 248,140,4; sky 7,199,247; green 63,201,33; purple 165,49,226 | the shop's loud papers |
| Part names | 255, 222, 40 | yellow with an ink edge |
| Shop picture circle (recommended, not yet approved) | 104, 133, 118 | faded chalk green at middle brightness; fold card has no circle (soft shadow); see design examples |

## 5. Checklist (run on a real screenshot before Alan sees anything)

1. Take the screenshot at 1280x720 or larger (Play, not a mock) and crop each card at full size.
2. **Squint test:** `python .claude/skills/design-theory/contrast.py shot.png`; look at `-squint`. Is the first thing
   you see the thing that matters (the item or the main button)? Is there only one loud thing per card?
3. **Grey test:** in `-grey`, does every item still stand off its backing? White or pale items on pale paper fail.
4. **Measure:** `contrast.py shot.png x,y x,y` for each word on its darkest/lightest backing spot (4.5:1 body, 3:1
   big) and each item on its backing (3:1).
5. **Figure-ground:** does any backing read as a hole or a sticker? Does it match the board behind its frame?
6. **Harmony:** name the scheme (analogous, complementary, split). Count the loud colours on each card (aim: one
   accent). Warm things forward, cool things back?
7. **Layout:** alignment lines, gaps (no dark shapes touching), reading order Z/F ends on the action, main button big
   and on the path, buttons look like buttons and labels don't.
8. **House rules:** words inside their paper, paper fits content, familiar layout, matches the main menu, still
   hand-made (would a kid have made this with crayons, paper and tape?).
9. Fix, re-shoot, re-check. Show Alan the before and after side by side and say which rule each change follows.
