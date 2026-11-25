# Emote shop plan

**Status:** how it works approved by Alan 2026-11-24 ("As far as everything you wrote, yeah, that looks good";
[decision](../decisions/2026-11-24-emote-shop.md)). **First build written the same day on his "go ahead and build the
menu without my list" (see "As built"). He looked at it in Play on 2026-11-25
([his notes](../playtests/2026-11-25-emotes-page-first-look.md)): it runs; the ranking is in, the door moved to the
main menu and the TV's framing is changed, none of that seen yet; the page's pictures are the big open piece, and
the price numbers wait for his OK.**

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

## Prices
Alan's ranking and limits ([his look](../playtests/2026-11-25-emotes-page-first-look.md)): the emotes that do
something to the camera are the coolest; 30,000 Paper is too much; the coolest is worth about $5 of Paper, "maybe
between 5 and 10", going down from there; the cheapest Leader emote costs more than the cheapest Runner-up emote; a
straight Robux buy is a little cheaper than buying the Paper for it. **The numbers are Claude's, in the game's config
(`config/emotes.json`), waiting for his OK:**

| Group | Emotes | Paper | Robux | Matches to earn (about 660 Paper each) |
|---|---|---:|---:|---:|
| Leader, coolest | Camera Flick, Magician, Fold It Up | 8,000 | 399 (about $5) | 12 |
| Leader, middle | Bubblegum, Book Kicker, Skeet Shoot | 5,600 | 299 | 8 |
| Leader, plain | A+ | 4,000 | 199 | 6 |
| Runner-up, coolest | Nap, Doodler, Test Flight | 2,800 | 149 | 4 |
| Runner-up, the rest | Sneaky Toss, Sore Loser, So Close, Next One | 1,800 | 89 | 3 |

All 14: 53,200 Paper, about 81 matches. Each Robux price is at or just under what its Paper costs in the biggest
pack (18.75 Paper a Robux). Free: Toy Pilot, Good Game.

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

## As built (2026-11-24; changed after his look, 2026-11-25)
- **The TV is in the middle of the page, not on the right** (Claude's change, forced by the method above): the hole
  shows the middle of the game's picture, so it has to sit in the middle of the screen. Leader emotes hang on a
  chalkboard on its left, Runner-up emotes on one on its right, eight cards each, all on screen at once: nothing
  scrolls yet. The name and the buttons are under the TV.
- **The door is an "Emotes" strip on the main menu, under Shop and Missions** (Alan 2026-11-25: "the emotes
  shouldn't be in the shop"); those two were made smaller to fit it. The page's X goes back to the main menu. No door
  in the Customize binder: its index tabs are full.
- **The wall, the two boards, the TV and its cart are flat colours**, which Alan found boring: "It needs work",
  drawn 2D pictures preferred. Next: the pictures (see "Build order").
- **A card's still is your own character held at one moment of the emote's body clip, without props** (no plane,
  bubble or book): `TV.POSE` in `src/client/WinnersCutscene.luau`, sixteen guessed moments to tune by eye.
- **On the TV** a Leader emote plays as 1st alone; a Runner-up emote as 2nd alone, with a 1st that is not there;
  Skeet Shoot's two throwers stand unseen so only their planes fly in. For a Leader emote the picture is 3.1 kid
  heights tall and reaches 2.75 over the desk top, about the winners' moment's own headroom (Alan 2026-11-25: at 2.7
  the Magician floated out of the top); a Runner-up emote keeps 2.7. The set is a plain classroom
  corner: a green board, a wooden desk top, cream walls.
- **Known before any look:** anything an emote places by the whole screen's shape (A+'s card flying to where the
  report card is, Fold It Up's picture) is cut by the TV's 4:3 edge; the emote's sounds play at their normal
  loudness, not quieter; the TV has no switch-on sound yet.
- Code: the page `src/client/EmoteShop.luau`; the TV `Cutscene.tv` in `src/client/WinnersCutscene.luau`; who does
  which emote `Cutscene.choose`; rules and saving on [economy and shop](../systems/economy-and-shop.md).

## Build order
1. ~~A free test of the TV picture~~, ~~saving~~, ~~the page~~, ~~his first look~~: done.
2. **The page's pictures** (his notes 4 and 5). Claude's proposal, not yet put to him: the wall is the main menu's
   own background, already loaded, cut round the glass; the two boards are the Shop's chalkboard in its wooden frame,
   already loaded; **one new picture, the box TV on its cart** (Codex draws it from his four photos, on his ChatGPT
   plan), with the glass cut out. He sees it assembled in the page first; one upload on his go.
3. His OK on the price numbers; his look at the framing and the new door.
4. The TV's switch-on sound: three licensed candidates on a Dev button, his pick by ear. The emote's sounds quieter.
5. The card stills (props, the sixteen moments).

Back to [HOME](../HOME.md)
