# Bots do a random one of our emotes; the random dances are retired

**Decided:** 2026-11-24 (Alan, with all four pipeline emotes uploaded and behind their Dev buttons)
**Status:** Built 2026-11-24 on Alan's OK of the plan ("yes, okay on the bots, the random emotes plan"); compiles, not run in Play. A human who places does [the free emote](2026-11-24-a-human-winner-does-the-free-emote.md) (decided later the same day).

## Decision
- **The random dancing emotes are retired** ("Since we're retiring the random dancing emotes").
- **A bot that places does a random one of ours, in rotation:** a runner-up (2nd, 3rd) does any runner-up emote, 1st does any 1st-place emote ("if they're the runner-up, it doesn't matter which one they're doing. They're rotating. They're doing a random one. If they're first place, it doesn't matter. Again, they're doing a random one").
- **Not decided:** what a human player who places gets (who owns or picks which emote).

## Why
- The emotes are finished pieces and the dances are stand-ins; a bot has no taste to honour, so any of ours will do.

## How it was built (the plan he OK'd)
- A bot in 1st does a random one of the eight 1st-place emotes; a bot in 2nd or 3rd a random one of the four runner-up emotes; 2nd and 3rd never the same one (Claude's choice).
- The dice are the match's id, so every player in the server sees the same emotes (a dice roll on each screen would differ; the dances always did).
- A winner is a bot when no player in the server has their id. `Cutscene.choose` and `Cutscene.emoteName` in `src/client/WinnersCutscene.luau`; the match's id comes from `src/client/RoundEnd.luau`.
- In Studio the Dev buttons still name the emotes for everyone; the new "end: real" button (`src/client/FlightHUD.luau`) ends a match with no names, as a live server shows it.
- Left as it was: So Close's sigh is cut when A+ or Skeet Shoot is on 1st.

## Before the build (Claude's reading at the time)
- The lists exist: 1st-place and runner-up names in `winnersDev` in `src/client/FlightHUD.luau`; the pick is made in `Cutscene.pipelineEmote` and `Cutscene.runnerUpName` in `src/client/WinnersCutscene.luau`, today only from Studio's Dev attributes.
- The older emotes (Camera Flick, Book Kicker, Bubblegum, Magician, Toy Pilot) are each switched on by a Studio-only check of their own; those checks go too.
- Known clashes to settle with it: a runner-up's sound is cut when 1st's first sound comes early (So Close's sigh under A+ or Skeet Shoot); 2nd and 3rd on the same emote or two different ones.
