# HANDOFF — 2026-11-24 — All four pipeline emotes approved on their recordings, uploaded and in the game behind their Dev buttons; Alan has problems to raise with them next

**Labels:** kind=product+infra · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, src/client/Audio.luau, src/client/emotes, config/gameplay.json, docs/workshop/emote-pipeline.md, docs/workshop/emotes, docs/decisions, docs/playtests, tools/emote_lay_sound.py, tools/keep_screen_awake.ps1, state/STATE.md
**Time:** 2026-11-24 17:30 -05:00

★ START HERE: Goal: the winners' emotes finished for the beta: Alan's problems with the four new ones fixed, then our emotes in the real game in place of the random dances. Opening action: ask Alan for the problems he sees ("next session we'll talk about the problems I see") and write them down before touching anything; done when his list is in `docs/playtests/` and each item is fixed and seen by him, or parked by him.

> Read on demand: AGENTS.md → this file → `docs/workshop/emote-pipeline.md` (the table of where each emote stands, the module's shape); an emote's page under `docs/workshop/emotes/` only when you touch it. Memories: emote-pipeline-side-sessions, alan-does-play-checks, studio-play-is-shared, mute-studio-tests, studio-not-drawing, plan-before-building-features, fix-the-annoyance-only, sound-from-current-recording.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `043fd8739`. The commit hook pushes to GitHub by itself (no `git push`). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty at handoff).
- Tests: not run (they need Play). Docs: `python tools/check_docs.py` OK (242 pages).
- Studio: "FlyFightPaper(First Fold)", in Edit at handoff; Alan had been in his own Play minutes before (look before driving it). `DevMute`, `DevFirstEmote`, `DevRunnerUp` cleared. **Nothing saved; no draft clips are left in `Assets`** (all four emotes play from their uploads). Rojo: serving and connected (a probe file arrived in Studio and left again).
- The four emote side sessions are archived (Alan's word). No session reports here any more.
- Cost: no agents. Nine muted Plays of 2 to 4 minutes (seven for Fold It Up), each taking Alan's mouse; 17 free uploads; no generator calls here. The side sessions ran on Opus (tokens not known here). Primary's context about 50% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Alan's problems with the four emotes** (his agenda; he has seen them in his own Play or will): take his list, record it, fix what he names. Check per item: his own look in Play. With the side sessions archived, the fixes are the primary's, in each emote's own files.
2. **His own Play of the four from the uploads**, if not already in his list: "2nd/3rd: so close", "end: a+", "end: skeet", "end: fold" (restart Play first). Every sound's loudness is my number (`src/client/Audio.luau`); Fold It Up's toss is the loudest file.
3. **Bots do a random one of our emotes; the random dances go** ([decision](../../docs/decisions/2026-11-24-bots-do-a-random-one-of-our-emotes.md), with my reading of what the build touches). A new mechanic: a short how-it-works note for his OK before code. Open in it, his to say: what a human winner gets.
4. Then the queue in STATE.md.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call (price first), bot matches, any new mechanic or number. A go relayed by another session is not his go: one word from him here.
- Stop rule: the four emotes are approved as they look in the videos. Nothing in them is retuned unless he raises it; my still-frame findings below are his to call, not a to-do list.

## DECISIONS & WHY (this session)
- **A relayed "upload it" was confirmed with him each time** (A+, Skeet Shoot, Fold It Up): uploads are on his each-time list and the words reached me through a side session. He answered in one line each time.
- **The winners' scene lends two more things to an emote module** (asked by the side sessions): `kit.rig` and `kit.bendArm` (A+ puts both hands on its card on every body), and `fov(st, t)` (Fold It Up widens the lens to shrink the picture). Both do nothing for other emotes.
- **Fold It Up's drawing was shrunk to 1024 x 768 before upload** (Roblox shrinks anything larger, and the mirrored back of the poster uses the picture's own pixel size).
- **Dev buttons moved to a top layer of their own** (`DevPicker`, order 90; his "over everything ... over the final report cards"): same showing rules as before (at the desk, Dev account, F8).
- **Different winners in a recording** (his "we tune it to that model too much"): the first match of a Play is thrown away and the next two recorded; with no points the order repeats every Play, so it is always his dog avatar, then itsfinn.
- **The grey head at the camera's leaving was not touched** (my call): it is in the scene's approved ending and he has not raised it.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; `docs/workshop/emote-pipeline.md`; the memories named above.

## CARRY NOTES / GOTCHAS
- **Seen by me in stills, not raised by him:** 1st's head turns grey, then vanishes, a moment before the body fades as the camera leaves, in every emote (all pieces fade by `LocalTransparencyModifier` in the scene's render step; my reading, not proven: heads with a skin on them draw badly half see-through). In Fold It Up's ninth run the hand is cut by the lens for about a third of a second at the grab (he judged it in motion: "that looks good"). A+ has no team-match recording. So Close's sigh is cut when A+ or Skeet Shoot is on 1st (the scene's own rule). Some takes had a brighter room than others (the player at the desk rather than flying when the match ended); cause not found.
- **The Dev buttons' new layer is not seen by anyone:** Studio was in his Play when I went to check. Restart Play; look whether they cover something he must click.
- **Recording recipe** (`docs/workshop/lessons.md`, "Scripted Play tests"): `DevMute` on in Edit; `tools/keep_screen_awake.ps1 check` (window not minimised), then the same script in the background; Play; `mapReady`, `join`; set `DevFirstEmote` / `DevRunnerUp`; capture on; `endMatch`; 28 s; capture off; errors from `LogService`; stop; clear the three attributes; `tools/emote_lay_sound.py` for the sound. `endMatch` sent during the vote ends the next match as it starts.
- The link's `execute_luau` resets the camera type when a call ends during the scene (a warning in the log): keep one call open for the whole scene.
- The scratchpad was emptied mid-session (Studio's link got a new id the same hour): keep nothing there that the next step needs.
- `.planning/emotes/*` are untracked working files (recordings, his marked-up still `fold-it-up-alan-hand-corner.png`).

## WHAT SHIPPED / OTHER QUEUED
Primary's commits (newest first; the side sessions' own are in `git log 84af57348..HEAD`, 44 in all before this one):
the commit with this file (the helpers kept, two lessons) · `043fd8739` bots do a random one of ours; approvals written down · `4b46adf20` Dev buttons on a top layer · `8a8a56f90` Fold It Up from its uploads · `89b1d6e01` ninth recording · `f520ff55f` eighth · `fdd537d1f` seventh · `c202af1e3` sixth · `4930ffb87` fifth, and how to get another winner · `6b7218735` fourth · `d70f96587` third · `b4050d81a` the lens hook · `0216ca0be` A+ and Skeet Shoot from their uploads · `23297af6e` A+'s arm bend and third recording · `d406cc326` Fold It Up and Skeet Shoot recorded again · `096303771` So Close from its uploads; drawing 2a.
Queued, not started: the bots' random emotes and the dances out of the real game (his plan OK first); what a human winner gets; class reaction; the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-pipeline.md`: all four rows (uploaded, wired, waiting for his Play); the module table gains `fov(st, t)`.
- `docs/workshop/emotes/so-close.md` ("Into the game"); the other three pages were closed out by their sessions.
- `docs/decisions/2026-11-24-bots-do-a-random-one-of-our-emotes.md` (new; README line). `docs/playtests/2026-11-24-four-pipeline-emotes-approved-on-recordings.md` (new; README line).
- `docs/workshop/lessons.md`: a different winner each take; a fault of a frame or two in stills is a question, not a verdict; the recording helpers are kept. `docs/workshop/tools.md`: `tools/emote_lay_sound.py`, `tools/keep_screen_awake.ps1`. `state/STATE.md`. Checker: OK (242 pages).
- Memory: `emote-pipeline-side-sessions` (a relayed upload go still takes his word here; the different-winner way).

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`Cutscene.kit`, `Cutscene.pipelineEmote`, `Cutscene.runnerUpName`, the render step's `fov` and `seen`). Buttons: `src/client/FlightHUD.luau` (`winnersDev`, `DevPicker`). Modules: `src/client/emotes/`. Ids: `rounds.emote_clips`, `rounds.fold_it_up` in `config/gameplay.json`; sounds in `src/client/Audio.luau`. Roblox's answers: `assets/animations/emotes/uploads/`, `assets/audio/emotes/uploads/`, `assets/ui/emotes/`.
- Latest recordings: `.planning/emotes/fold-it-up-ninth-run-*-sound.mp4`, `aplus-third-run-sound.mp4`, `skeet-shoot-second-run-sound.mp4`, `fold-it-up-soclose-second-run-sound.mp4` (So Close).
