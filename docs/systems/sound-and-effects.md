# Sound and effects

## What the player sees
Each weapon has its own short sound (a rubber-band thwap for the pencil launcher, an electric zzz and metal ting for
the paperclip). Sounds come from where they happen in 3D, and you only hear other planes' weapons within a set
range. A paper whoosh rises only when you go faster than your plane's normal speed. Classroom chatter, fan whir,
landing, lock-on pings, an end-of-round whistle and a music track (with its own slider) fill out the rest. Effects:
tracers, impact puffs, paper-shred deaths, fan wind swirls, damage smoke.

## Where it stands (2026-11-21)
**The winners' moment has its new sound, heard by Alan in Play ("all fine", [playtest](../playtests/2026-11-21-winners-sound.md)):** quiet in the dark, an echoing switch for each spotlight, then one of four upbeat songs in the background with the emotes' own sounds over it; the party crowd is gone. Details in the Code table's `WinnersSound` row.
Older, from 2026-10-22:
The match playlist now moves on to the next song (it went silent after the first one), and the classroom children are
twice as loud so they still show under the music (Alan's note 2026-10-22; not yet heard by him).
The children are heard only while you're out flying in a match: not at the desk, in menus, the Range or lessons
(Alan 2026-10-23: they're the classroom's own sound).
Stage 7 sounds are in, including every sound note from the 2026-10-13 playtest. Waiting on Alan's ears for the
final loudness balance. Death looks wait on his eyes.

## Rules
The sound brief is in [Art direction](../vision/ART_DIRECTION.md) ("Audio and effects"). Only licensed sounds from
Roblox's free audio library or the Creator Store. Music: a shuffled playlist of free APM tracks in menus and matches
(ids in `Audio.luau`; Alan added Sprint, Comedy Clip (a), Tough Guys (A) and Silly Chase by ear, 2026-10-18).
Each tutorial lesson has one song of its own, looped and quiet, no classroom chatter, and a
rising two-note chime for every finished step (Alan, 2026-10-18). Lesson songs (Alan's picks by ear, 2026-10-18): Flight School APM "Daisy Fresh"
(1839864816); Combat Training APM "Liberty Bell (a) 60" (105397100521450).
**Music turns down to a tenth under a moment over the menu** (a gift arriving, the unlock backpack), like the dimmed
board behind it, and comes back after (Alan 2026-11-13: a fifth was still too loud). The moment sets the Root
attribute `MusicQuiet`; `Audio.luau` does the fade.
Sounds without a place play straight in SoundService (before 2026-10-18 they sat at the room's middle and faded with
distance); every sound is loaded when the game starts.
The paperclip fires with two sounds at once (Alan 2026-10-19): the metal ting ("Key Dings Metal Clinking 11", louder than
the other guns) and a soft railgun zap under it ("Electric Arcing 6").

## Code
| File | What it does |
|---|---|
| `src/client/Audio.luau` | Every sound: weapons, events, 3D positioning, whoosh, ambience, music, lock beeps |
| `src/client/WinnersSound.luau` | The winners' moment's sound ([decision 2026-11-21](../decisions/2026-11-21-winners-sound-dramatic.md)): quiet in the dark and through the three spotlights, then one of four songs from half a second after 1st's light, through the results card; started by `RoundEnd` with the cutscene while the match music fades out (`WinnersMoment`); plays in Studio Edit too. Studio's "end: depth / step / hyped / relent" buttons (hangar dev row) end the round with that song once; otherwise a random one of the four each round, never twice in a row. Each spotlight has a switch sound, a metal lever clunk, louder towards 1st (Alan's pick of four, 2026-11-21: "the closest"), played lower and through a hall's echo (his "add room echo and lower the pitch"; Roblox's own reverb, no new file). Camera Flick has its own sounds, played by `WinnersCutscene` at the moments themselves (the throw, a hand-slap smack on the lens, the camera hitting the ground as a briefcase falling; Alan's picks by ear in Play 2026-11-21, ids in `Audio.luau`), louder than the music. The runner-up emotes have theirs too: Good Game a clap as the hands meet, Nap a comic snore on each breath and a pop as the bubble bursts, Next One a paper-bag rustle as each fold begins (the snore and the fold are Alan's picks by ear in Play, 2026-11-21). **1st's emote owns the sound**: a runner-up's sound plays only if it will be over before 1st's first effect, and never after it (`runnerSound` in `WinnersCutscene`; his rule after hearing a snore over the fallen camera) **Toy Pilot's whoosh, not picked yet (2026-11-21):** three Pro Sound Effects candidates in `src/client/Audio.luau` (`pilotWhoosh1` to `3`: [Synth Air Whoosh Cheesy Karate Style Swishes 1](https://create.roblox.com/store/asset/9126047023), [Airy Pass By Windy Whoosh Howling And Whistling 4](https://create.roblox.com/store/asset/9125356690), [Air Fingers Short Swooshing Bursts Sucking 1](https://create.roblox.com/store/asset/9113069659)), played at `PILOT_SOUNDS` in `src/client/WinnersCutscene.luau`; the Dev "end: pilot" button steps `DevPilotWhoosh`. The two not picked and the stepping go once Alan has chosen. |
| `src/client/CombatEffects.luau` | Tracers, impacts, hit markers, smoke |
| `src/client/PlaneDeaths.luau` | Paper ball and shred deaths |
| `src/client/FanWind.luau` | Wind swirls over fans |
| `src/client/ChalkCloud.luau` | Chalk-dust cloud |

## Tuning numbers
Volumes and ranges live in `src/client/Audio.luau`. Wind sprite pictures: `assets/fx/` (drawn by `tools/art/wind_sprites.py`).

## Related
- [Playtest 2026-10-13](../playtests/2026-10-13.md) (notes 7-13)
- [Weapons](weapons.md)
- [Milestones, Stage 7](../plan/MILESTONES.md)

Back to [HOME](../HOME.md)
