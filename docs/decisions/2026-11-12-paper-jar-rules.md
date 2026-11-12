# Paper jar rules: breaks at 3,000 Paper with a "wait for more" warning; 2x fills it too; Today's parts as built

**Decided:** 2026-11-12 (Alan, after the money plan's jar was built)
**Status:** decided. The save rules are built (`paper_jar` in `config/economy.json`); the jar's shop card and the warning
are not built yet.

## Decision
- **The jar breaks from 3,000 Paper**, just under what 199 R$ buys in the small Paper packs (99 R$ gives 15.2 Paper per
  Robux, so 199 R$ is about 3,000). Breaking it early is the player's choice.
- **A warning before breaking:** "Are you sure? The jar always costs 199 R$, and it keeps filling up to 10,000
  Paper. Wait and you get more Paper for the same price." with Break now / Keep filling.
- **2x Paper fills the jar twice as fast** (the jar takes 25% of the Paper you actually earn). OK as built.
- **Today's parts:** 3 picked from the 6 parts nearest your level that you don't own. OK as built. Later, when a player
  owns every part, the row can rotate skins instead (once skins exist; see [ideas](../plan/IDEAS.md)).

## Why
Alan: a low price for a nearly empty jar would feel like a trick; with the minimum and the warning, an early break is
the player's own call, and the warning sells waiting (more Paper for the same 199 R$).

Back to [decisions](README.md)
