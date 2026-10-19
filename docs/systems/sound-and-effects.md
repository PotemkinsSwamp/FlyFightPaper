# Sound and effects

## What the player sees
Each weapon has its own short sound (a rubber-band thwap for the pencil launcher, an electric zzz and metal ting for
the paperclip). Sounds come from where they happen in 3D, and you only hear other planes' weapons within a set
range. A paper whoosh rises only when you go faster than your plane's normal speed. Classroom chatter, fan whir,
landing, lock-on pings, an end-of-round whistle and a music track (with its own slider) fill out the rest. Effects:
tracers, impact puffs, paper-shred deaths, fan wind swirls, damage smoke.

## Where it stands (2026-10-15)
Stage 7 sounds are in, including every sound note from the 2026-10-13 playtest. Waiting on Alan's ears for the
final loudness balance. Death looks wait on his eyes.

## Rules
The sound brief is in [Art direction](../vision/ART_DIRECTION.md) ("Audio and effects"). Only licensed sounds from
Roblox's free audio library or the Creator Store. Music: a shuffled playlist of free APM tracks in menus and matches
(ids in `Audio.luau`). Tutorial lessons have one calm song of their own, looped and quiet, no classroom chatter, and a
rising two-note chime for every finished step (Alan, 2026-10-18); Combat Training will get different music.
Lesson song choices for Alan (all free, licensed for Roblox; the Creator Store page plays them): Pure Innocence
(1847585588, the stand-in), Playground Idyll (1837587505), Daisy Fresh (1839864816), Music Box Lullaby (9047785119),
Hopeful Contemplation (1835322111), Young Pupils (1843045912), Soft Cloud Symphony (87683270918647), Calm Environment C
(1847544694). Not liked: Bamboo Dream Steps (101906137416418, the first one he heard).
Sounds without a place play straight in SoundService (before 2026-10-18 they sat at the room's middle and faded with
distance); every sound is loaded when the game starts.

## Code
| File | What it does |
|---|---|
| `src/client/Audio.luau` | Every sound: weapons, events, 3D positioning, whoosh, ambience, music, lock beeps |
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
