# HANDOFF — 2026-11-22 — Magician is done (look and sound, Alan: "alright its good"); next is the talk on how to build the rest of the emotes faster

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/Audio.luau, assets/audio/emotes, docs/workshop/emote-making.md, docs/workshop/lessons.md, docs/playtests, docs/decisions, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-22 21:33 -05:00

★ START HERE: Goal: the rest of the beta's emotes built much faster than this one (Alan: "we cant be doing 2 every 8 hours we need to figure out how to speed this up"). Opening action: the talk he asked for, before So Close is started: put to him, in plain words, where Magician's hours went and a short list of changes to how we work (my starting points are below, his to pick). Done when he has chosen the changes and they are written down where the next emote's session will read them (`docs/workshop/emote-making.md` or a decision note); then So Close, built that way.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; the Magician section at the end of `docs/workshop/emote-making.md` only for a fact you need. Memories: sound-from-current-recording, plan-before-building-features, alan-does-play-checks, studio-play-grabs-mouse, studio-not-drawing, mute-studio-tests, reference-videos-via-gemini, emotes-show-feeling-in-movement, playtest-notes-before-handoff.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `87f932eb`. Pushed. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (233 pages).
- Studio: "FlyFightPaper(First Fold)", id `c4bdbd91-d3ea-411c-a5ad-6f6134b87437` this session (it changes when Studio restarts), in Edit; `DevMute` and `DevFirstEmote` cleared; nothing saved by me. Rojo's server was started by me in the background (`rojo.exe serve serve.project.json`, port 34872) and the plugin was connected: Studio's scripts held the new code at each check. It may be gone after a restart.
- Seen and heard by Alan: the fly-over ("Okay, it's good"), four sound listens on recordings, then the sounds in the game ("alright its good"; how he listened is not said).
- Cost this session: two Gemini calls, $0.52 (a third was refused for a short clip, not charged); three free sound uploads; one muted Play run of about a minute (his "Go, bring Studio up"); no agents. About 5 hours of wall clock for the fly-over and the sound. Primary's context about 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The speed-up talk** (above). What the record shows for Magician, card to done: 3 shot cards, 3 builds, 4 Play recordings, 2 paid sound tries and 4 sound listens, about 12 rounds that each waited on Alan, across two sessions. My own misses cost about 4 of them: Curtsy picked from joint numbers (not a bow), a recording made with Studio minimised, sound made from the outdated recording, a video sent with a broken sound track.
   My starting points, none decided:
   - **Cards in one sitting:** write the shot cards for all the remaining emotes together and get his changes at once, sound included (which moments get a sound, what kind), since his taste is now on record (below).
   - **Bodies from what exists:** Magician's body was two of Roblox's own emotes played by id, with no clip of ours. Check Roblox's list first for every card.
   - **One recording, several emotes:** one Play run that ends the match once per emote, back to back, so he gives one go and one set of notes for a batch.
   - **Sound heard in the game, not on videos:** upload candidates early (free) and let a Dev button cycle them in the scene, against the music; the listen videos cost four rounds here and still could not show the mix.
   - **Work side by side:** each emote is its own functions inside one 1,900-line file, so two builders cannot work at once; splitting `WinnersCutscene.luau` into one module per emote would let side sessions or agents build cards in parallel (one writer per file).
   - **The maths model first** for anything flying near the lens (it found this build's limits before any Play).
2. **So Close** (2nd/3rd; Alan's card in `docs/plan/WINNERS-CIRCLE-PLAN.md`: sits on the books shaking their head, sad not to be 1st), built the agreed way. Later in the plan: Skeet Shoot, A+, Fold It Up.
3. Still open, his word: who gets which emote; Bubblegum heard in his own Play ("end: gum"); Toy Pilot seen from the upload; the report card loses 0.6 s under Bubblegum.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too; bringing Studio's window up counts), bot matches, every upload, every generator call (price first), any new mechanic or number.
- Stop rule: Magician is closed. Do not retune its curve, tremble or loudness unless he raises it.

## DECISIONS & WHY (this session)
- **A plane is six tenths of the picture wide going over, not the whole width** (my call inside the plan he OK'd; told to him; he then said "it's good"): wider or more central it covers the kid's head, and lower its fold sweeps down the picture as a white blade. Numbers in the emote log.
- **The planes do not shake with the camera:** their path is tied to the shaken camera, so the tremble never brings one nearer the lens.
- **Sound, his rulings:** no sparkle ("too much like fantasy magic"); a low bass, "like a subwoofer, like a sci-fi kind of sound", held while the kid floats and tapering as they land; the paper flutter of the first try while the planes circle, subtle; one whoosh only as the line goes over the camera ("you're from the camera's perspective"); everything quiet because the music plays under it.
- **The bass is made in Python, not by Gemini** (48 to 62 Hz with two overtones); the flutter is cut from the first Gemini try and the whoosh from the second.
- **One whoosh for the line, not six:** Gemini made one both times; he called it good.
- **Loudness in the game is my numbers** (whoosh 0.8, bass 0.35, flutter 0.1, in the proportions he heard); he accepted them.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Rulings: `docs/decisions/2026-11-22-magician.md`, `docs/playtests/2026-11-22-magician-sound-first-try.md`.

## CARRY NOTES / GOTCHAS
- **Never make or show a sound over a recording older than the build** (memory `sound-from-current-recording`): ask his go for a new muted recording first.
- **A listen video: build the sound track as a WAV first, join it, then check the sound stream's start and length with ffprobe and decode it once** (`docs/workshop/lessons.md`). A one-chain ffmpeg mix wrote a track players read as silent.
- **Gemini's video call wants the clip at exactly the whole seconds asked:** Studio's recordings have uneven frame times, so cut to a fixed 30 a second, then cut again with `-t 10`. No `--edit`; `--duration=10s`; 360p is the lowest size the tool knows.
- **Recording recipe that worked:** `DevMute` on in Edit in its own call; bring Studio up (his go); mouse nudge in the background; Play; the client fires `mapReady`, `join`, waits for 12 planes; count frames; capture on; `DevFirstEmote` then `endMatch`; 22 s; capture off; stop; clear both attributes. Studio kept drawing while he worked in Chrome on his other screen. 1st's light was 11.5 s into the capture.
- **The Edit check without Rojo:** take the text between `local MAGIC = {` and `-- The book podiums` from the script (or the repo file), give it stand-ins for `RunService`, `Root`, `Avatars`, `paper`, `Audio`, `ease` and the SHEET numbers, and step it. The scratch scripts of this session are gone with the temp folder.
- Python's `write_text` on this PC turns line ends into CRLF; git evens them out (the warnings are harmless).
- `.planning/emotes/*` are untracked working files. `tools/art/hero.py.old` is untracked and not ours.
- A running Play keeps its old code: say "restart Play" with every change.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`, pushed; the commit with this file comes after):
`87f932eb` Magician is done; next, how to build the rest faster · `e2eb5bf8` sounds uploaded and wired in · `137b91f4` the bass holds through the float · `72e6bdb2` his notes on try 2; two new listens · `687c9254` try 2's silent file rebuilt · `b4df92b5` the fly-over recorded; second sound try · `7142645c` his notes on try 1 · `8cd8306e` first Gemini try · `bafb9791` "it's good, it needs sound effects" · `3fb45d72` the fly-over built.
Queued, not started: the speed-up talk, So Close, who gets which emote, class reaction, the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: the fly-over's build and numbers, the fourth Play run, both sound tries, his notes each time, the listens, the uploads, the wiring, his "alright its good".
- `docs/playtests/2026-11-22-magician-sound-first-try.md` (new, with every later round added) and the README's line. `docs/decisions/2026-11-22-magician.md` (the fly-over built; my size call).
- `docs/workshop/lessons.md`: a video with sound must be checked to play, not only for loudness.
- `docs/systems/modes-and-scoring.md` (Magician where it stands). `state/STATE.md`. Checker: OK (233 pages).
- Memory: `sound-from-current-recording` (new).

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`MAGIC`, `MAGIC.trembling`, `MAGIC.sounds`, `magicProps`, `magicPlanes`; `holdAt`; `state.magicAt`). Sounds: `src/client/Audio.luau` (`magicBass`, `magicFlutter`, `magicWhoosh`); files and Roblox's answers in `assets/audio/emotes/`.
- Videos: `.planning/emotes/magician-third-run-cut.mp4` (the fly-over, muted), `magician-sound-try4.mp4` (the approved sound under it).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`. Tools: `tools/gemini_video.py`, `tools/upload_texture.py --audio`.
