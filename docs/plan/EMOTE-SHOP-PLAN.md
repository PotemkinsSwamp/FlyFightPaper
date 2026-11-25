# Emote shop plan

**Status:** how it works approved by Alan 2026-11-24 ("As far as everything you wrote, yeah, that looks good";
[decision](../decisions/2026-11-24-emote-shop.md)). Prices wait for his ranking of the emotes. Nothing built yet.

One menu where you buy the emotes and put them on. The emotes themselves:
[modes and scoring](../systems/modes-and-scoring.md).

## What the player sees
- **One menu, two jobs.** The Emotes menu is the shop and the place you equip. It opens from an Emotes tab in the
  Shop; a door in the Customize binder opens the same screen.
- **Two kinds**, one scrolling list with two headings: **Leader emotes** (8, "Plays when you finish 1st.") and
  **Runner-up emotes** (8, "Plays when you finish 2nd or 3rd.").
- **Cards (left, scroll):** your own character frozen in the emote's signature pose, the name, and the Paper price,
  "Free", "Owned" or a "Using" mark.
- **The TV (right, never scrolls):** a black school box TV on a rolling cart, late 90s / early 2000s
  (Alan's four photos: `.planning/emote-shop/tv-cart-reference-*.jpg`). The TV is the picture; only the top edge
  of the cart shows under it, dark and quiet. Under it: the emote's name and its buttons.
  - The menu opens with the TV off.
  - Tap a card: a click, the picture snaps on the way a box TV did (a bright line that opens into the picture) and
    your character does the emote once, alone, in front of a chalkboard wall. Then the TV switches off.
  - Tap the same card: it flicks on and replays. Tap another: it flicks to that one.
  - Things thrown at the camera (the book, the gum, the plane) hit the TV glass from the inside.
  - The emote's own sounds play quietly under the menu music.
- **Buttons under the TV.** Not owned: the brown Paper price and the green Robux price, the pair the chests use
  (not enough Paper opens the Hangar's "Not enough Paper" note). Owned: **Use**. The one you have on: **Using**.

## Rules
- You wear one Leader emote and one Runner-up emote; you start with Toy Pilot and Good Game, both free.
- When you place in a match you do the one you have on. Bots still do a random one.
- No level lock. A prestige does not take emotes back.
- The Robux button is practice-only in Studio until go-live, like the rest of the shop; live, each paid emote needs
  its own Roblox product (14).

## Prices (not set)
Alan: comparable to a skin's value, the best ones really expensive so the Robux button tempts, and a straight Robux
buy a little cheaper than buying the Paper for it. He ranks the 14; the tiers offered to him, from the skins' own
values (`config/looks.json`):

| Tier | Paper | Robux | Same as |
|---|---:|---:|---|
| Good | 2,800 | 149 (135 with the chests' 10% off) | Common skin |
| Cool | 5,600 | 299 (269 with 10% off) | Rare skin |
| Best | 30,000 | 599 | Legendary skin |

A step between Cool and Best, if he wants one: 12,000 Paper / 399 R$.

## Claude's calls, his to reverse
- The TV is off when the menu opens and switches off after each emote (no frozen last pose).
- The black school TV of his photos 1, 2 and 4, not the wood one.
- The card poses are the player's own character, live, not uploaded pictures.

## How the TV picture is made (Claude's method, 2026-11-24)
- **Not a menu 3D window** (Roblox's ViewportFrame, what the Hangar shows the plane in). Tested in Studio's Edit:
  paper drawn in code (a SurfaceGui) stays blank in one, and Roblox's docs say it has no blur either. That would
  blank A+'s report card, Doodler's drawing, Fold It Up's picture and Book Kicker's pages.
- **Instead the TV's glass is a hole in the menu** and the real scene plays behind it, small and right at the
  camera, the way the winners already stand in the winners' moment. Everything an emote has draws, because it is
  the real game picture. Costs: the Emotes menu is a full page of its own (nothing see-through around the TV), the
  camera's lens is narrowed while it is open so the kid is not stretched off to the side, and it never opens
  mid-flight (the Shop's rule already). Not proven until it runs in Play.

## Build order
1. ~~A free test of the TV picture~~ done in Edit (above). Next: a Dev button on the main menu that opens a bare
   page with the hole and plays Good Game, then Book Kicker, on your own kid: Alan's look in Play.
2. The TV picture: Codex draws it, Alan sees it assembled in the menu, one upload on his go.
3. Saving what you own and your two picks (Codex, unit tests).
4. The menu, then the winners' scene using the picks.
5. The TV's switch-on sound: three licensed candidates on a Dev button, his pick by ear.
6. His look in Play.

Back to [HOME](../HOME.md)
