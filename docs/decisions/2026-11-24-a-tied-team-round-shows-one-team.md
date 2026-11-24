# A tied team round shows one team on the stand, never a mix

**Decided:** 2026-11-24 (Alan, after a 0 to 0 team round put both teams on the stand in his own Play)
**Status:** Built the same day; the rule passes its check in Studio (Edit); not seen in Play.

## Decision
- **The three on the stand are always teammates** ("all three are teammates so they should be shown together, never a mix match").
- **In a tied team round** the stand shows the best three of the team that has the best pilot (Claude's suggestion, his "yes"). "Best" is the results order: points, then folds, assists, fewest crashes, then a draw of lots.
- Nothing else about a tie changes: no winning team, no places paid, the note still says "A tie! Well flown, everyone."

## Why
- A tie has no winning team, so the stand took the best three of everybody. In his match nobody had scored, the order was a draw of lots, and he stood 3rd beside players from the other team while his own card had him 5th ([his notes](../playtests/2026-11-24-alans-second-look-at-the-emote-fixes.md)).

## Where
- `Rules.winners` in `src/shared/MatchRules.luau`; its test in `tests/unit/Match.spec.luau`. The stand and the emotes: [modes and scoring](../systems/modes-and-scoring.md).
