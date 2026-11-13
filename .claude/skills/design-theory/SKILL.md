---
name: design-theory
description: Research-backed design and colour rules for Fly Fight Paper's screens. Use BEFORE building, changing or showing Alan any UI, menu, card, note, button, HUD piece, shop or hangar screen, icon, picture backing, concept art, colour or layout choice in this Roblox game, and run its checklist on a screenshot before anything visual goes to Alan.
---

# Design theory for Fly Fight Paper

Every rule below names the research it rests on: the codes (C colour, L layout and reading, G games) are findings on
[design research 2026-11-12](../../../docs/research/DESIGN-RESEARCH-2026-11-12.md), each with its source, what was
tested and how strong it is. Strength words: **strong**, **medium**, **standard** (platform or accessibility
standard), **practice** (studio practice). If a rule you want isn't here, check that page; if it isn't there either,
it's an opinion: say so to Alan instead of calling it a rule. Worked examples:
[design examples](../../../docs/workshop/design-examples.md).

House rules this sits on (read them, don't restate them): hand-made crayon and paper beats generic Roblox polish
([text style decision](../../../docs/decisions/2026-11-08-text-style-crayon.md),
[art direction](../../../docs/vision/ART_DIRECTION.md#menu-and-ui-look-alan-2026-10-08)); words fit their paper and
paper grows to fit ([lessons](../../../docs/workshop/lessons.md#working-with-alan),
[menus and HUD](../../../docs/systems/menus-and-hud.md)); familiar Roblox layouts in our materials; in-game menus reuse
the main menu's art ([decision](../../../docs/decisions/2026-10-11-in-game-menus-match-main-menus.md)).

Who we design for: Roblox players, about a third under 13 (G8), many on phones (G7). Older kids find plain primary,
plastic-looking things "babyish" (C6): our real paper, cardboard and crayon materials are the age-right choice.

## 1. Colour
1. **Light and dark first.** Edges and shapes are carried by brightness; equal-brightness colours look flat (C7,
   medium). Check every screen in greyscale: if something disappears, fix its brightness, not its hue.
2. **A picture needs 3:1 against its backing** (L9, G5, standard). When a picture has both white and black pieces, the
   backing that keeps both visible is middle brightness (relative luminance about 0.21: 3.8:1 to each). That's why
   the shop uses faded chalk green; dark backings hide dark pieces, light ones hide white.
3. **Muted ground, saturated focus.** Keep backgrounds and panels muted and calm; put the strong colour on the one
   thing that matters (G1, practice; L11, strong: one strong peak stands out, many equal peaks cancel).
4. **Panels in one colour family, with a clear light/dark step.** People like pairs of similar hue with a big
   lightness difference; opposite colours (red on green, blue on orange) are not liked more (C2, strong, adults).
   Warm, saturated things on cool, muted grounds work (C2). Use a different hue to draw the eye (L11), not to build
   a panel.
5. **Calm screens light, exciting moments saturated.** Brightness drives pleasure, saturation drives excitement (C3,
   medium-strong): menus soft and light; the loudest colour for rewards, kills and warnings.
6. **No muddy browns or olives; no big dark panels for good news.** Browns and olives are the least-liked colours,
   and liking dips at yellow-green (C1, strong): a greyed green leaning yellow reads as mould, as the shop circle did
   in Play; lean greens toward blue instead. Children link brown, black and grey with bad feelings (C4, medium). Cardboard stays light and warm;
   dark paper is for small plates (price labels, word backings), losing or locked states.
7. **Crayon-bright, not neon.** Older kids lean to less saturated colours than young ones (C5, weak-medium).
8. **Objects keep their real-world colours** (C8, strong): a pencil is yellow, an eraser pink.
9. **Never colour alone.** About 1 boy in 12 is red-green colour-blind (C9, strong); every colour-coded thing also
   gets a shape, icon or word: locked = grey + padlock, can't afford = red + "need N more", teams = colour + sticker
   shape (C10, G7, standard).

## 2. Layout
1. **Grouping:** the gap between cards is clearly bigger than any gap inside a card; one sheet of paper = one thing;
   same job, same look (L1, strong). Dark shapes that nearly touch merge into one.
2. **Plan the read order** for every card: what kind of thing (colour), which one (picture), then the decision (price
   and button) with the strongest contrast (G2, practice; L11).
3. **Keep places fixed.** Players learn where things are; experience steers the eye more than contrast (L11). The
   close X in the same corner on every screen, Buy in the same spot on every card.
4. **Main action big and close** (L2, strong). Kids miss more taps (L4: 23% vs 17%) and slip off near the end (L3):
   make the hit area bigger than the drawn paper. Phone buttons at least about 10 mm with gaps (L5: research 9.6 mm;
   Apple 44 pt, Google 48 dp).
5. **Edge buttons touch the edge** or their hit area reaches it: a small gap nearly doubled kids' misses (L4).
6. **After a screen changes, don't put a new button where the last tap was** (or ignore taps for a moment): kids'
   repeat taps land there (L4).
7. **Buttons look like buttons:** closed, convex, small paper shapes stand out as objects (L1); a button has its own
   strip with an edge and a verb; labels are flat words or a dark plate with no verb.
8. **Choice:** don't just cut items; group them and mark one recommended pick, biggest (L13, medium; G7). No fake
   timers, a clear "no thanks", purchases plainly labelled (G13, strong for young children).
9. **HUD:** during play eyes stay near the centre and miss corners (G9, medium): urgent alerts near the aim point or
   moving; counts as numbers near the plane, health on the HUD (G11, medium). Keep the HUD for our young, mixed-skill
   players (G12).

## 3. Words
1. **Contrast 4.5:1 for words, 3:1 for big titles (about 24 px, or 19 px bold) and greyed items**, measured against
   the least-contrast patch of the paper or crayon behind the letters (L9, G5, standard).
2. **Calm patch under words.** Busy texture slows reading more than weak contrast (L10, medium; G10, strong): words go
   on plain paper, a label plate, or with our ink edge over busy art.
3. **Size:** at least 18 px body height at 1080p on PC; on phones 18 px at 100 DPI scaled up with density (about
   4.5 mm on the glass) (G4, standard). Small text adds errors for kids at every age (L6, medium): **never shrink words
   to fit; grow the paper** (this is why Alan's rule is right).
4. **Crayon lettering is fine, kept short.** Friendly fonts read as well as plain ones for 9-11 year olds (L7), but
   handwriting-style words are slower, more so for rare words (L7, strong in adults): short, common words, not joined
   up; prices and numbers in the clearest lettering.
5. **Don't cram letters:** wider spacing helps dyslexic kids (L8, medium).
6. **Outlines:** use the ink edge for words floating over the moving game (Xbox practice, G6); on plain paper the
   paper itself is the contrast. The guides disagree here (G6), so judge on the screenshot.
7. Roblox's own text-size setting is ignored by `TextScaled` (G7): a known gap in our menus, not a reason to break
   the fit rules.

## 4. Not backed by research (don't call these rules)
- The 60-30-10 colour split (C11: folklore).
- Complementary colours as a harmony recipe (C2: no preference gain).
- F and Z reading patterns for game screens (L12: web text only).
- "Kids love primaries" (C6: toy colour is mostly marketing; older kids find it babyish).

## 5. Our palette (measured from the art)
| Piece | RGB | Notes |
|---|---|---|
| Ink (words) | 40, 30, 24 | `PaperUI.INK`, warm black |
| Shop chalkboard | about 10, 55, 30 | dark green; the shop window's ground |
| Cream paper (item square, pale circle, tabs) | about 240, 225, 208 | nearly the same brightness as white (1.1:1) |
| Featured card crayon | about 36, 79, 230 to 101, 40, 236 | blue to violet with magenta, orange, cyan streaks |
| Card colours | orange 248,140,4; sky 7,199,247; green 63,201,33; purple 165,49,226 | the shop's loud papers |
| Part names | 255, 222, 40 | yellow with an ink edge |
| Shop picture circle | 98, 117, 96 on screen | meant as faded chalk green 104,133,118 but tinted wrong, came out olive; Alan doesn't like it in Play; options in [design examples](../../../docs/workshop/design-examples.md#why-the-green-looks-wrong-in-play-fourth-study-2026-11-12) |
| Team paper | red 214,78,72; blue 70,128,214 | middle brightness: on a middle backing they stand out by colour, not brightness |

## 6. Checklist (on a real screenshot, before Alan sees anything)
1. Screenshot at 1280x720 or larger, and on a phone size; crop each card at full size.
2. `python .claude/skills/design-theory/contrast.py shot.png` makes `-grey` and `-squint` copies.
3. **Squint:** is the first thing you see the thing that matters? One loud thing per card? (rules 1.3, 2.2)
4. **Grey:** does every picture and word still stand off its backing? White on cream and black on dark fail. (1.1, 1.2)
5. **Measure:** `contrast.py shot.png x,y x,y` for words on their worst patch (4.5:1, titles 3:1) and pictures on
   their backing (3:1). (1.2, 3.1) Read the colours off the screenshot, not the code: `ImageColor3` multiplies the
   picture, so a tint on cream paper comes out darker and yellower (set target / picture colour x 255).
6. **Colour:** muted ground, saturated focus; panel in one hue family; no muddy brown or olive; nothing colour-only.
   (1.3-1.9)
7. **Layout:** gaps between cards bigger than inside; read order ends on the button; buttons in their usual places,
   big, at least about 10 mm on a phone, edge buttons touching the edge. (2.1-2.7)
8. **Words:** body height at least 18 px at 1080p; nothing shrunk to fit; short common words. (3.3-3.5)
9. **House rules:** words inside their paper, paper fits its content, familiar layout, matches the main menu, still
   hand-made.
10. Show Alan before and after side by side, and name the rule (and its research code) behind each change.
