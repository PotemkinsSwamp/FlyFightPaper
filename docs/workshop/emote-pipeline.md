# Emote pipeline

How every emote is made from 2026-11-22 on: six steps, several emotes at once, each in its own side session
([Alan's decision](../decisions/2026-11-22-emote-pipeline-in-parallel.md)). What was tried before, and every number
of the finished emotes, is in the [emote log](emote-making.md); the ideas are on the
[plan](../plan/WINNERS-CIRCLE-PLAN.md).

## Emotes in the pipeline
| Emote | Page | Step it is on |
|---|---|---|
| So Close | [so-close](emotes/so-close.md) | 6, approved by Alan on the recording (2026-11-22: the sigh was "way too loud", then with the quieter file "its good"); uploaded and wired in on his go (2026-11-22); waits for his own Play |
| Skeet Shoot | [skeet-shoot](emotes/skeet-shoot.md) | 6, approved by Alan on the second recording (2026-11-24: "its good upload it"); three clips and the shot sound uploaded and wired in on his go ("go both"); the drafts are out of the open place; waits for his own Play ("end:" button for Skeet Shoot) |
| A+ | [a-plus](emotes/a-plus.md) | 6, approved by Alan on the third recording (2026-11-24: "its good upload it"); the clip and two sounds uploaded and wired in on his go ("go both"); the draft is out of the open place; a team match not yet recorded; waits for his own Play |
| Fold It Up | [fold-it-up](emotes/fold-it-up.md) | 6, eighth build (the hand itself covers the lens, then pulls back to the top left corner over 0.4 s); ninth muted recording 2026-11-24 on Alan's dog avatar and a blocky bot (`.planning/emotes/fold-it-up-ninth-run-a-sound.mp4`, `-b-sound.mp4`, no game error): **the cover is broken** (the hand comes so near that the camera cuts through it: slivers and ribbons of it across the picture, never a covered screen); the pull-back to the corner reads on the bot; back with its session; its body clip is not uploaded (Studio plays the draft) |

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

## The Dev buttons (Alan 2026-11-22)
In Studio no winners' Dev button shows today's random dances any more ("we're going away with that"). A button for a
1st-place emote ("end: ...") puts two different runner-up emotes on 2nd and 3rd, the next pair at each press, so he
sees them all. A button for a runner-up emote ("2nd/3rd: ...", one each: Good Game, Nap, Next One, So Close) puts it
on both and a random one of our 1st-place emotes on 1st. The song buttons do both. Code: `src/client/FlightHUD.luau`
(`winnersDev`); `DevRunnerUp` as "A,B" is 2nd's and 3rd's (`Cutscene.runnerUpName` in
`src/client/WinnersCutscene.luau`). Compiles in Edit; not yet pressed in Play. A new emote is added to
`winnersDev.firsts` or `winnersDev.ups` and gets its button there.

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

Commits: its own paths only: `git add` them by name (never `-A`), then `git commit -m "..." -- <those paths>`, so a file another session added at the same moment stays out of it; the commit pushes to GitHub by itself. A new code file and its line on the
emote's page go in the same commit. If the commit check stops on another session's half-written file, wait a
minute and try again; never skip the check.

## Studio is shared
One Studio for all sessions. A side session uses it in Edit only, in short single calls, and whatever it makes
there carries its emote's name and is removed in the same call. Never Play, never a save, never the camera or a
picture without Alan's go. Play and recordings are the primary session's.

## The emote module
Ready (added 2026-11-22; ran in Play the same day with A+ on 1st and So Close on 2nd and 3rd, no error). `src/client/WinnersCutscene.luau` runs a pipeline emote from `src/client/emotes/<Name>.luau`. In Studio the
attribute `DevFirstEmote` (1st) or `DevRunnerUp` (2nd and 3rd) on `ReplicatedStorage.FlyFightPaper`, set to
`<Name>`, picks it. The module returns a table:

| Field | What it is |
|---|---|
| `start(kit, who)` | Needed. Called once in the dark, when the winner's copy is put on its books. Loads the body, makes the props (unseen until their moment) and returns the emote's own table `st`. `st.track` is needed: the body's AnimationTrack, or anything with `Play` and `AdjustSpeed`. The scene calls `st.track:Play(0.3)` at this winner's light. With `st.held = true` the module has already started it frozen on its first pose (`track:Play(0, 1, 0)`) and the scene calls `AdjustSpeed(1)` at the light instead. |
| `step(st, since, shot, steady, winners, fov)` | Every frame. `since`: seconds after this winner's light (below zero before it). `shot`: the camera this frame. `steady`: the camera without any shake. `winners`: the scene's three winners by place, for an emote that uses the others; all three are already placed for this frame. Each has `model`, `animator`, `actorId`, `emote`, `extra`, `place`, `scale`, `spot`, `shift` (this frame's slide towards the camera), `world` (its model; `world.Cast` holds the kid, books and props), `desk`, `lit`, `since` (seconds after its own light) and `fading` (the parts that fade out with it on the way home: add a prop made after `start` to it). 2nd and 3rd are stood up after 1st's `start` runs, so anything of theirs is made on the first `step` in which they exist. To hold a runner-up's emote still (Skeet Shoot, Alan's OK): set every track of `animator:GetPlayingAnimationTracks()` to speed 0, keeping each one's `Speed`, and put the speeds back afterwards; that works for the dances, Good Game, Nap and Next One alike (Nap's Z's and bubble run on the clock and carry on; Good Game moves to its next clip by itself after 12 s without progress). |
| `camera(st, steady, t, height)` | 1st only. Returns the camera for this frame, to shake or move it; `t`: seconds after 1st's light. |
| `fov(st, t)` | 1st only. Returns the lens angle in degrees for this frame (the scene's own is 50), on `camera`'s clock; it also reaches the curtain's size and `step`'s `fov`. Back at 50 before the camera leaves. |
| `leave` | 1st only. Seconds after 1st's light at which the camera leaves for the report card, when the scene's own time is wrong for it. The report card must keep its 10 seconds: ask Alan before using it. |
| `covered(st, t)` | 1st only. True while the emote has the lens: the name plates and the Menu tag are put away. |
| `firstSound` | 1st only. Seconds after 1st's light of its first sound; the runner-ups' sounds stop before it. |
| `stop(st)` | Clean-up for anything not under `who.cast`. |

`who`: `model` (the winner's copy, already scaled small and standing on the books), `humanoid`, `animator`, `cast`
(parent for every prop: it is removed with the scene), `stack` and `rise` (the books and their height), `legs` (leg
length against a standard kid's), `scale`, `place`, `actorId`, `desk` (where they stand, as a CFrame), `top` (the
top of the books under them).

`kit`, lent by the scene: `paper(parent, color, shape)`, `ease`, `flat`, `sit` and `seatOn` (Nap's and Next One's
seat on the books), `holdPlane` (a paper plane in the hand), `jolted` (Book Kicker's camera jolt), `ourClip(name)`
(the id of an uploaded clip, or of the draft `<Name>Clip` in the place's `Assets`), `runnerSound`, `Audio`,
`Rounds`, `Avatars`. For the meaning and arguments of each, read its function in `WinnersCutscene.luau`.

Sounds: until the uploads (step 6) there is no id to play, so the module keeps its sound times in a table of its
own and step 6 wires them to `Audio`.

A body cut goes in `tools/emote_cuts/<name>.lua`: a piece of Luau that adds `CUTS.<Name> = { ... }` as the cuts in
`tools/emote_clips.lua` do. `tools/emote_preview.py` puts every cut file into `emote_clips.lua` before it runs
(where that file says `EMOTE_CUTS_HERE`), each inside its own `do ... end`, so the file sees every helper there.

What the module cannot do with this, it asks the primary session for.

## Alan's holds
His explicit go, each time: any Studio Play (tests included), place saves, publish (he does it), desktop control
or screen grabs (Edit pictures too), bot matches, every upload, every generator call (the price first), any new
mechanic or number.

**A go he gives in a side session counts here too** (Alan 2026-11-22: "the go came from the other sessions you
dont need to ask for a go seperatly"): when a side session reports ready to record, the primary session records
without asking him again. First recording, A+ with So Close: `.planning/emotes/aplus-soclose-first-run-raw.mp4`;
it was also the first run of the scene's hook in Play, which worked.
