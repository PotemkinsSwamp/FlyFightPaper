# A human winner does the free emote; the others are bought with Paper, later

**Decided:** 2026-11-24 (Alan, asked what a human who places gets)
**Status:** The free emotes are built in (read through by eye only: Studio was in his Play, so no compile check yet; not seen in Play). Buying and pricing are not started.

## Decision
- **Everyone starts with the free one in each slot, and only that** ("they get the free one. Everyone starts with the free one. That's the only one everyone gets ... that is like the default. Like you can't change them. Like that's just what you have").
- **The others are bought with Paper** ("They have to buy the others, with paper. So that's a whole different thing we'll do later. Once we have all the emotes, we'll go through and price them").
- The free ones are the two already agreed ([winners' circle plan](../plan/WINNERS-CIRCLE-PLAN.md), "Emotes: two slots"): **Toy Pilot** for 1st, **Good Game** for 2nd and 3rd.

## What it means in the game today
- A person in 1st does Toy Pilot; a person in 2nd or 3rd does Good Game. Bots still do [a random one of ours](2026-11-24-bots-do-a-random-one-of-our-emotes.md); a bot runner-up beside a person never does Good Game too (Claude's choice).
- Roblox's random dances are out of the real game. They are left only for a body our emotes cannot play on (not R15).
- Nobody can own or pick another emote yet: no shop, no prices, no saving.

## Where
- `Cutscene.FREE` and `Cutscene.choose` in `src/client/WinnersCutscene.luau`. The scene: [modes and scoring](../systems/modes-and-scoring.md).
