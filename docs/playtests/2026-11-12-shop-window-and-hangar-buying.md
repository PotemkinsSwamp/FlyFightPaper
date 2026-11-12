# 2026-11-12: the new shop window, and buying in the Hangar as a fresh player

## What Alan did
Opened the new shop window in Studio Play (practice-bought "2x Paper Forever"), then played as a fresh test account
(`DevAccountLevel` 12, 3,000 Paper: [testing](../workshop/testing.md)) and tried buying parts in the Hangar's Customize binder.

## What he saw
- **Shop window:** "it works". Chalk headings were hard to read (fixed: crisp white with a dark outline). The starter
  pack's part turned in circles and was tiny: parts now sit still at their best angle and bob. Starter pack: 1 hour of
  2x XP instead of 2x Paper. No "Every part can be earned by playing" line (boosts can't be earned).
- **Hangar buying (to fix next, with a picture for his OK first):**
  - Nothing tells you at a glance that a part is locked: no lock look, no "Level 20" on its face.
  - A part above your level should not show a Paper buy button; that's where **"Unlock now" for Robux** goes (skips
    the level and the Paper).
  - Failing to buy only shows a small line at the bottom ("You need more Paper.", "Reach the required level first.").
    He wants a **pop-up** instead: under the level, "buy with Robux"; at the level but short of Paper, "buy more Paper"
    or "buy the part with Robux".
  - The words under each card's name ("Equipped", "Owned", "18500 Paper, lvl 28") are far too small, worse on phones,
    with empty room to make them bigger. All binder words are hard to read.
  - The "You need more Paper." line stayed on screen while he looked at the Paper Pellet Gun (free, owned), so it read
    as if the pellet needed Paper. It is the last buy's reply, not about the part shown (it should clear or move into
    the pop-up).
- **Next big step he asked for:** a personalised shop ("an algorithm": the shop changes with the player looking at it);
  research first ([shop direction](../decisions/2026-11-11-shop-direction.md)).

## What changed
Shop: [shop screen plan](../plan/SHOP-SCREEN-PLAN.md). Studio: the test account no longer opens a 34-item backpack every
Play; the fresh-account switch (`DevAccountLevel`, `DevAccountPaper`) also turns off the Hangar's Studio "own
everything" mode. Hangar buying: not changed yet.

Back to [playtests](README.md)
