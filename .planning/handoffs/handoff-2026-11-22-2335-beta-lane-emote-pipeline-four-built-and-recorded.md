# HANDOFF — 2026-11-22 — The emote pipeline runs: four emotes built and recorded in one evening in side sessions; So Close approved, its uploads wait for Alan's go

**Labels:** kind=product+infra · lane=beta · branch=main · issues=none · areas=docs/workshop/emote-pipeline.md, docs/workshop/emotes, src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, src/client/emotes, tools/check_docs.py, tools/emote_preview.py, tools/emote_clips.lua, state/STATE.md
**Time:** 2026-11-22 23:35 -05:00

★ START HERE: Goal: the four pipeline emotes (So Close, Skeet Shoot, Fold It Up, A+) approved by Alan and in the game. Opening action: ask Alan's go to upload So Close (two clips, one sound, free), then wire it in; done when "2nd/3rd: so close" plays from the uploads with its sigh in his own Play. In the same sitting: one muted Play that re-records whatever the side sessions report ready (Skeet Shoot's crossed arms, Fold It Up's folding arms, A+ when its new session says so).

> Read on demand: AGENTS.md → this file → `docs/workshop/emote-pipeline.md` (the rules, the module's shape, the table of where each emote stands); an emote's own page under `docs/workshop/emotes/` only when you touch it. Memories: emote-pipeline-side-sessions, sound-from-current-recording, studio-not-drawing, mute-studio-tests, scripts-through-the-write-tool, side-session-pricier-model, alan-does-play-checks.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `1867f046e` (a side session's). The commit hook pushes to GitHub by itself (`git push` has no upstream: do not run it). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (the side sessions may have staged their own pages: leave those).
- Tests: not run (they need Play). Docs: `python tools/check_docs.py` OK (240 pages).
- Studio: "FlyFightPaper(First Fold)", id `c4bdbd91-d3ea-411c-a5ad-6f6134b87437` this session, in Edit; `DevMute`, `DevFirstEmote`, `DevRunnerUp` cleared; nothing saved. Rojo was connected all session (edits reached Studio within 2 s). **Seven unsaved draft clips sit in the place's `Assets`** (SoCloseLeft/Right, APlus, FoldItUp, SkeetShoot, SkeetThrowLeft/Right `...Clip`): a Studio restart without a save loses them; each emote's page has its bake command.
- Side sessions (started here, on Opus, sharing this checkout): so-close `local_52d88833-f2e6-4296-b144-83f5b280d830` (done, waits for the uploads), skeet-shoot `local_5899bbe8-dba2-422d-abb1-109232e6295f`, fold-it-up `local_aadd559e-bc63-499f-a78a-5a44a3b3f025`, a-plus `local_6254a0ab-5d74-423e-9069-9f5da3214f80` (ended by Alan; he restarted A+ in a session of his own on Fable, which does not report here). They message the primary session by its id; the next primary session should tell the three live ones its own id.
- Cost: four side sessions on Opus (tokens not known here); the Gemini calls were asked and paid in the side sessions (prices on each emote's page); three muted Play runs of about two minutes each, five takes; no agents. About two hours of wall clock from the first card to the first recording. Primary's context about 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **So Close into the game** (Alan's go for the uploads first): `assets/animations/emotes/so-close-left.rbxm`, `so-close-right.rbxm`, `assets/audio/emotes/so-close-sigh.ogg` (`tools/upload_texture.py --audio` for the sound; the clips as Bubblegum's were: see the emote log's "Into the game"); ids into `rounds.emote_clips` as `SoCloseLeft` and `SoCloseRight`; `soCloseSigh` into `src/client/Audio.luau` at volume 1 (the quiet is in the file); delete the two drafts from `Assets` so Studio plays the uploads. Check: the module's `runnerSound("soCloseSigh")` plays once per kid at clip second 2.5.
2. **Re-record what is ready**, one muted Play, one capture per take: Skeet Shoot (new crossed arms), Fold It Up (arms that fold; the drawing once Alan has picked and it is uploaded), A+ when its session reports. Send each video with its sounds, faults first. Recipe: `docs/workshop/lessons.md` ("Scripted Play tests") and below.
3. Then each emote's own step 6 as So Close's: his OK, uploads on his go, wiring, his own Play.
4. Not started, his word: who gets which emote; the random dances leaving the real game (he said they are going away; only the Dev buttons are changed).
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call (price first), bot matches, any new mechanic or number, desktop control outside a recording. **A recording of an emote a side session reports ready needs no new go** (his rule, 2026-11-22).
- Stop rule: So Close is closed. Its sigh, timing and slump are not retuned unless he raises it.

## DECISIONS & WHY (this session)
- **Alan's system:** six steps per emote, several emotes at once in side sessions, the sound made with the reference video ([decision](../../docs/decisions/2026-11-22-emote-pipeline-in-parallel.md)).
- **One writer per file, so each emote lives in its own files** (my call): a small hook in `WinnersCutscene` runs `src/client/emotes/<Name>.luau`; a cut file in `tools/emote_cuts/` is put into `emote_clips.lua` by `emote_preview.py`. The side sessions never edit the shared files; they ask the primary.
- **No pause API for runner-up emotes** (for Skeet Shoot): its module freezes the runner-up's playing tracks and restores their speeds. Add a real pause only if a recording shows one misbehaving.
- **The docs check only looks at files git knows:** otherwise one session's unfinished file stops every commit.
- **Dev buttons, his rule:** a 1st-place button rotates two different runner-up emotes onto 2nd and 3rd; one "2nd/3rd:" button per runner-up emote puts a random one of ours on 1st; song buttons do both. The old cycling "2nd/3rd" button is gone. `DevRunnerUp` may be "A,B".
- **I held A+'s first re-record for a batch** so Studio took his mouse once; my reading of his rule, his to change.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; `docs/workshop/emote-pipeline.md`; the memories named above.

## CARRY NOTES / GOTCHAS
- **A+ lands its card at the wrong size:** a little big in free-for-all (first take), about 1.6 times too big and over 1st in a team match (second take, after a fix). Measurements are on `docs/workshop/emotes/a-plus.md` ("Hand-over"). Both report card layouts must hold; a match's mode is whatever comes up.
- **With A+ on 1st, So Close's sigh is cut** (1st's first sound at 2.2 s; the sigh would still be playing). With Fold It Up it plays.
- **Skeet Shoot's planes are about 2% of the screen wide;** Alan finds the size fine. In the dances take 2nd's kid was well above the books in most stills: the dance's own jumps or the pause, not checked.
- **Recording recipe that worked three times:** `DevMute` on in Edit (own call); Studio's window up and not minimised (`IsIconic`); mouse nudge in the background; Play; client `mapReady`, `join`, 12 planes, wait until `RenderStepped` gives over 40 frames a second (the first seconds gave 4); capture on; set `DevFirstEmote` / `DevRunnerUp`, `endMatch`, 25 s; capture off (it stops itself at 30 s); read errors from `LogService`; stop; clear the three attributes. The scratch scripts (window, nudge, sound laying) are gone with the temp folder; the sound-laying way is in `lessons.md`.
- The new Dev button rows (y -120 and -160 in `FlightHUD.luau`) compile and are not yet seen on screen by anyone.
- A script with a backslash goes through the Write tool, never a heredoc (memory `scripts-through-the-write-tool`).
- `.planning/emotes/*` are untracked working files.

## WHAT SHIPPED / OTHER QUEUED
Primary's commits (newest first; the side sessions' own are in `git log 8b71d7d7..HEAD`, 48 in all):
`5807d0e93` Dev buttons show our emotes only · `8725f9f17` So Close approved · `7317d69fe` Skeet Shoot recorded · `6c3dae78a` A+ back at the build · `26b513e2c` Fold It Up recorded; A+'s second take · `bc9a5d888` docs check looks at files git knows; A+ and So Close recorded · `4595bfaf0` A+ ready · `9f0d143ae` Dev buttons for the pipeline emotes · `e799a07b9` So Close ready · `3cb124b51` docs check: a tool named by its whole path · `9955d3082` all three winners for a pipeline emote · `86e37eb97` four cards wait; the hook compiles · `6fd7c6776` the hook and the cut loader · `2673a0bda` the pipeline written down; the commit with this file comes after.
Queued, not started: who gets which emote, the dances out of the real game, class reaction, the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-pipeline.md` (new: the six steps, who does what, file rules, the module, the Dev buttons, the table of the four emotes). `docs/workshop/emotes/*.md` (four pages, kept by their sessions).
- `docs/decisions/2026-11-22-emote-pipeline-in-parallel.md` (new; README line). `docs/playtests/2026-11-22-pipeline-first-recordings.md` (new; README line).
- `docs/workshop/lessons.md`: capture stops at 30 s; errors from `LogService`; 1st's light by brightness; several sessions in one folder; backslashes and heredocs. `docs/workshop/tools.md`, `docs/systems/modes-and-scoring.md`, `docs/plan/WINNERS-CIRCLE-PLAN.md`, `docs/HOME.md`, `state/STATE.md`. Checker: OK (240 pages).
- Memory: `emote-pipeline-side-sessions` (new), `scripts-through-the-write-tool` (the backslash case).

## POINTERS
- Hook: `src/client/WinnersCutscene.luau` (`Cutscene.kit`, `Cutscene.pipelineEmote`, `Cutscene.runnerUpName`, `state.extra`). Buttons: `src/client/FlightHUD.luau` (`winnersDev`). Modules: `src/client/emotes/`. Cuts: `tools/emote_cuts/`.
- Recordings: `.planning/emotes/aplus-soclose-first-run-*.mp4`, `aplus-second-run-raw.mp4`, `fold-it-up-first-run-*.mp4`, `skeet-shoot-first-run-*.mp4`.
