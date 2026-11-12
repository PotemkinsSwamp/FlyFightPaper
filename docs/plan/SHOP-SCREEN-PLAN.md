# Shop screen plan

**Status:** waiting for Alan's OK (2026-11-11). Look approved: "this could work... as close to this as possible,
proportions and all", plus movement. Concept: `.planning/shop-concept/shop2-a.png` (top) and `shop2-b.png`
(scrolled), from the [shop direction](../decisions/2026-11-11-shop-direction.md). Replaces the Studio practice shop.

## What the player sees
- **Opening it:** the main menu's "Shop (dev)" note becomes a "Shop" button in the same spot; the Hangar gets one
  too. Never mid-flight. The window pops open with a springy grow; the menu behind darkens.
- **The window:** exactly the concept's layout and proportions (measured from the picture): yellow torn-paper title
  bar with "Shop", "Gift a friend" and the red X; chalkboard body in a wooden frame that scrolls; chalk headings
  FEATURED, FREE GIFT, PASSES, PAPER, BOOSTS; four big tabs on the right (Featured, Passes, Boosts, Paper) that
  scroll to their section and light up yellow for the section you're in.
- **Cards** as in the concept: the starter pack's wide Featured card, the Free gift card, the two Forever passes, the
  three Paper packs ("Good Value", "Most Value"), and the boost rows (2x Paper green, 2x XP blue, 5 times each,
  "Good Value" on 3 hours, "Most Value" on 5 hours). Every card: picture, what you get, Robux price on a green button.
- **States:** a pass you own says "OWNED"; a running boost shows "32 min left" on its row; when you can't buy right
  now (live sales off) the button reads "Soon" in grey.
- **All words are game text** (sharp at any size, change without uploads); the pictures are paper, icons, stickers.

## Movement (all gentle, all the time, like the games Alan showed)
- **Rays** behind every icon turn slowly (one turn in about 12 s) and breathe in size (about 5%).
- **Icons** bob up and down a few pixels, each card a little out of step with its neighbours.
- **"Most Value"** stickers: the rainbow colours slide across the sticker without stopping.
- **Sparkle stars** on the Featured card twinkle (grow, twist, fade) at different times.
- **Featured card:** a shine sweeps across it every 4 s; the "New!" burst wobbles; the timer counts down live.
- **Buttons:** grow a little under the mouse, squish and spring back when pressed, with a paper tap sound; the Claim!
  button pulses while today's gift is waiting.
- Phones: same layout scaled to fit (the concept's words stay readable at phone size: checked on the concept).

## How it's built (cheap)
1. **Pieces:** Codex redraws every piece of the concept on its own with no words (card papers, rays, icons, stickers,
   buttons, tabs, title bar, chalkboard, frame), bigger than needed; I cut them out with a small script and
   check a contact sheet (nothing that could read as a symbol).
2. **Assembled preview for your OK:** the two concept screens rebuilt from the cut pieces plus game text, next to the
   concept, at PC and phone size.
3. **Upload (your go):** about 35 pictures through Open Cloud (free).
4. **Code:** `src/client/ShopScreen.luau` rebuilt to the measured layout, cards filled from `config/commerce.json`;
   buying goes through the existing purchase code (switched off until go-live). Tests for anything new.
5. **Check in Studio** at PC and phone size against the concept, screenshots for you.
- Built after their own notes for your OK: the starter pack (contents, price, timer), the daily gift (amount), gift
  a friend (how it works). Until then their cards show only in Studio with example numbers, and gift buttons stay off.

## Cost
Codex pictures on Alan's ChatGPT plan; uploads free; Opus builds and checks (about one session). Nothing paid.

Back to [HOME](../HOME.md)
