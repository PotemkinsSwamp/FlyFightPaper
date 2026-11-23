# Emote pipeline

How every emote is made from 2026-11-22 on: six steps, several emotes at once, each in its own side session
([Alan's decision](../decisions/2026-11-22-emote-pipeline-in-parallel.md)). What was tried before, and every number
of the finished emotes, is in the [emote log](emote-making.md); the ideas are on the
[plan](../plan/WINNERS-CIRCLE-PLAN.md).

## Emotes in the pipeline
| Emote | Page | Step it is on |
|---|---|---|
| So Close | [so-close](emotes/so-close.md) | 1, card not written |
| Skeet Shoot | [skeet-shoot](emotes/skeet-shoot.md) | 1, card not written |
| A+ | [a-plus](emotes/a-plus.md) | 1, card not written |
| Fold It Up | [fold-it-up](emotes/fold-it-up.md) | 1, card not written |

The primary session keeps this table; a side session reports its step in its own page.

## The six steps
1. **Direction: the shot card.** The feeling first, in one line. Then one table: time, the kid, the props, what the
   camera sees, the sound at that moment. For anything that goes at or over the lens the card says how big it is on
   the screen, where, and for how long; when that is not obvious, two or three versions for Alan to pick from. The
   card also says: which of Roblox's own emotes could be the body (checked first, they are free), what is reused
   from finished emotes, and anything the scene cannot do or that is a new mechanic or number. Fixed by Alan
   already: the camera stays on all three winners, no zoom on 1st; the music plays under every sound, so sounds are
   few and quiet.
2. **Alan's OK on the card.** Nothing is made before it.
3. **Reference video with its sound: one Gemini call** (`tools/gemini_video.py`; the price told first, Alan's go).
   Lowest size (360p), as long as the emote in whole seconds, the movement spread over the whole length, the props
   and the lens moment shown, each sound asked for at its moment, no music. Alan watches and listens: his OK here
   settles the movement and the sound together.
4. **Build in Roblox.** The body (a Roblox emote by id, or a cut made from the video), the props and the camera
   part, in the emote's own files. Numbers check in Edit: no error, feet on the spot, hands out of the body, the
   key moments at their marks, how much of the picture a lens piece covers. Then the same on the bots' bodies.
5. **Sound applied.** The video's sounds are cut into one file per moment (`assets/audio/emotes/<name>-*.ogg`) and
   timed to the game's marks. A sound the video lacks: a licensed Creator Store one, or made in Python; a second
   Gemini call only on Alan's go.
6. **Final review.** The primary session records the emotes that are ready in one muted Play, back to back (Alan's
   go), lays each one's sounds under its recording and checks that the track plays. Alan watches each with its
   sound. On his OK: the uploads (free, his go), the sounds wired in, his own look in Play.

## Who does what
- **A side session, one per emote:** steps 1 to 5, stopping at "ready to record" with its marks and sound times
  written on its page. Alan gives his OKs in that session.
- **The primary session:** the shared files, Studio's Play, the recordings, the uploads, the wiring, step 6,
  `state/STATE.md` and the table above.

## One writer per file
A side session writes only its own files:
- `docs/workshop/emotes/<name>.md`: its page (card, prompt, numbers, Alan's words, its files).
- `src/client/emotes/<Name>.luau`: its props and camera part (see "The emote module").
- `tools/emote_cuts/<name>.lua`: its body cut, when the body is not a Roblox emote.
- `.planning/emotes/<name>-*` (working videos, untracked) and `assets/audio/emotes/<name>-*`.

It never edits `src/client/WinnersCutscene.luau`, `src/client/Audio.luau`, `tools/emote_clips.lua`, `config/`,
`state/STATE.md`, the [emote log](emote-making.md) or another emote's files. What it needs there, it asks the
primary session for in a message.

Commits: its own paths only (`git add` them by name, never `-A`), then push. A new code file and its line on the
emote's page go in the same commit. If the commit check stops on another session's half-written file, wait a
minute and try again; never skip the check.

## Studio is shared
One Studio for all sessions. A side session uses it in Edit only, in short single calls, and whatever it makes
there carries its emote's name and is removed in the same call. Never Play, never a save, never the camera or a
picture without Alan's go. Play and recordings are the primary session's.

## The emote module
Not ready: the primary session is adding the hook that lets `WinnersCutscene` run an emote from its own module.
A side session reaching step 4 reads this section again; if it still says "not ready", it messages the primary
session and waits.

## Alan's holds
His explicit go, each time: any Studio Play (tests included), place saves, publish (he does it), desktop control
or screen grabs (Edit pictures too), bot matches, every upload, every generator call (the price first), any new
mechanic or number.
