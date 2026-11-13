# Paper jar rules: breaks at 3,000 Paper with a "wait for more" warning; 2x fills it too; Today's parts as built

**Decided:** 2026-11-12 (Alan, after the money plan's jar was built)
**Status:** decided. The save rules are built (`paper_jar` in `config/economy.json`). The shop card and the warning are
built in Studio (2026-11-12, preview `.planning/paper-jar-preview.jpg`); the two jar pictures uploaded and approved
(Alan's go). The report card's jar line (below) is next.

## Decision
- **The jar breaks from 3,000 Paper**, just under what 199 R$ buys in the small Paper packs (99 R$ gives 15.2 Paper per
  Robux, so 199 R$ is about 3,000). Breaking it early is the player's choice.
- **A warning before breaking:** "Are you sure? The jar always costs 199 R$, and it keeps filling up to 10,000
  Paper." with Break it now / Keep filling (Alan 2026-11-12, after the preview: drop "Wait and you get more Paper for
  the same price").
- **2x Paper fills the jar twice as fast** (the jar takes 25% of the Paper you actually earn). OK as built.
- **The fill rate stays the same after a break** (Alan 2026-11-12, after the numbers: an average player needs about
  61 matches, roughly 9 hours, to fill it, so it can't replace the packs; "the point is to give them a deal and make
  them want to buy it for what they earned"). A slower refill (a tenth after the first break) was weighed and dropped.
- **The report card says what went into the jar** (Alan 2026-11-12): at the end of every match, how much Paper went
  into your jar this match, with a small button ("See your jar") that opens the shop at the jar. Not built yet. Plan:
  the amount is the jar's change since the round started (the `PaperJar` attribute; the final bonus can land after
  the card shows, so it updates); the button calls `Menu.show("shop")` and scrolls to the Paper section; shown only
  where the shop is (Studio until go-live, like the menu's Shop button). Place it on a real card screenshot (the dev
  `endMatch` action ends a round at once; the card shows about 8 s after the winners' moment).
- **Today's parts:** 3 picked from the 6 parts nearest your level that you don't own. OK as built. Later, when a player
  owns every part, the row can rotate skins instead (once skins exist; see [ideas](../plan/IDEAS.md)).

## Why
Alan: a low price for a nearly empty jar would feel like a trick; with the minimum and the warning, an early break is
the player's own call, and the warning sells waiting (more Paper for the same 199 R$).

Back to [decisions](README.md)
