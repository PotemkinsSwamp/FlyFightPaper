# Bots do a random one of our emotes; the random dances are retired

**Decided:** 2026-11-24 (Alan, with all four pipeline emotes uploaded and behind their Dev buttons)
**Status:** Decided, not built. Today the real game still plays the random dances; our emotes show only through the Dev buttons in Studio.

## Decision
- **The random dancing emotes are retired** ("Since we're retiring the random dancing emotes").
- **A bot that places does a random one of ours, in rotation:** a runner-up (2nd, 3rd) does any runner-up emote, 1st does any 1st-place emote ("if they're the runner-up, it doesn't matter which one they're doing. They're rotating. They're doing a random one. If they're first place, it doesn't matter. Again, they're doing a random one").
- **Not decided:** what a human player who places gets (who owns or picks which emote).

## Why
- The emotes are finished pieces and the dances are stand-ins; a bot has no taste to honour, so any of ours will do.

## To build it (Claude's reading, for his OK before code)
- The lists exist: 1st-place and runner-up names in `winnersDev` in `src/client/FlightHUD.luau`; the pick is made in `Cutscene.pipelineEmote` and `Cutscene.runnerUpName` in `src/client/WinnersCutscene.luau`, today only from Studio's Dev attributes.
- The older emotes (Camera Flick, Book Kicker, Bubblegum, Magician, Toy Pilot) are each switched on by a Studio-only check of their own; those checks go too.
- Known clashes to settle with it: a runner-up's sound is cut when 1st's first sound comes early (So Close's sigh under A+ or Skeet Shoot); 2nd and 3rd on the same emote or two different ones.
