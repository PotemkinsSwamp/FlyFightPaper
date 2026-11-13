# Paper jar rules: breaks at 3,000 Paper with a "wait for more" warning; 2x fills it too; Today's parts as built

**Decided:** 2026-11-12 (Alan, after the money plan's jar was built)
**Status:** decided. The save rules are built (`paper_jar` in `config/economy.json`). The shop card and the warning are
built in Studio (2026-11-12, preview `.planning/paper-jar-preview.jpg`); the two jar pictures uploaded and approved
(Alan's go). The report card's jar piece (below) is built and **OK'd by Alan** (2026-11-12, after four looks; Studio
only until go-live).

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
  into your jar this match, with a button that opens the shop at the jar. First try (2026-11-12, the shop's orange card pasted left of the report
  card with "See your jar") Alan disliked: "you didn't make it look different, add something distinctive... something
  to catch your eye"; it is switched off (`RoundEnd.luau` `showJar`). **His pick for the redo:** the jar sits at the
  end of the Double this match row under your card: the glass jar itself (no card behind it), paper scraps dropping
  into it as the card comes up, the level rising from before the match to now, a big crayon "+165!" popping out, and
  its own small yellow button beside it ("Break the jar!" from 3,000, "See your jar" before), gently pulsing. Shown
  every match where something went in or the jar is full, even when the Double button isn't there. The amount (the
  `PaperJar` change since the round started) and "See your jar" opening the shop on the jar card
  (`Menu.show("shop", false, "PaperJar")`) work. **Final layout, Alan's OK 2026-11-12** after four looks (videos
  `.planning/report-card-jar-redo.mp4`, still `.planning/report-card-jar-row-fit.png`): everything fits inside the
  card's edges ("uncentred" otherwise); the Double this match panel big on the left, on yellow paper (two greens
  clashed), with words big enough to read (heading, amounts, time left) and a distinct buy button with the price that
  bounces, the "Worth" sticker pulsing above it; the jar a little smaller on the right with a short "See your jar"
  button under it; both buttons on the old green paper (the lime buy button looked bad on yellow); "+165!" above the
  jar's right shoulder, turned 30 degrees, just under the level bar, never covering it.
- **Today's parts:** 3 picked from the 6 parts nearest your level that you don't own. OK as built. Later, when a player
  owns every part, the row can rotate skins instead (once skins exist; see [ideas](../plan/IDEAS.md)).

## Why
Alan: a low price for a nearly empty jar would feel like a trick; with the minimum and the warning, an early break is
the player's own call, and the warning sells waiting (more Paper for the same 199 R$).

Back to [decisions](README.md)
