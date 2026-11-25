# Bots are a fixed cast: each name has one character model, and no new names

**Decided:** 2026-11-24 (Alan, after asking whether the bots' names and looks were random)
**Status:** Decided, not built. It is the next thing to build, before any more emotes ("the only problem is this problem ... once we fix that problem, we will then move on to doing the rest of the emotes").

## Decision
- **Each bot name is tied to one character model, and only that one** ("we need to have each name have a character model with it and is tied to that character model only"; "the names do need to match with their character models").
- **No more names** ("We don't need 157 bots. That's insane. We only need the cast we have now, the names that exist ... we don't need to add any more names"). Claude's plan of a cast of 157, one name a saved look, is refused.
- **Make more character models only if the names we have need them** ("if we need to make more to fill up the bot names that we have, then we need to do so").

## Why
- Bots are stand-ins: "once the game has players, you'll rarely see bots. And they get replaced when a player comes in. So the amount of bots that we have now is fine."

## How it works today (read from the code, 2026-11-24)
- There is no saved list of names. A bot's name is made from word parts by its number on the server (`newIdentity` in `src/shared/BotRosterRules.luau`, the fixed seed in `config/server.json`). The numbers start again on every server, so the first bots of every server are always the same names: the ones Alan knows from Studio. A bot that fills in later (a player came and left) gets the next number and a name nobody has seen.
- A bot's look comes from its name by a sum (`Service:look` in `src/server/AvatarService.luau`) into 157 saved outfits (`bot_look_outfits` in `config/gameplay.json`). If another bot in the server already wears that outfit it takes the next free one, so the same name can wear another look.

## To build it (Claude's reading, his to correct)
- "The cast we have now" = the names the game makes today for the first bots of a server, as many as one match can hold. They are written down once, each beside the outfit it wears in Studio today, in a config list.
- A bot that fills in later takes a cast name that is not in the match, never a new name.
- A cast bot always wears its own outfit. The 157 saved outfits are more than enough: no new character models are needed.
