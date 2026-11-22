# HANDOFF — 2026-11-22 — Bubblegum is approved by eye and ear, uploaded and wired in (not yet heard in Play); Magician's card is OK'd, nothing of it built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/Audio.luau, config/gameplay.json, assets/audio/emotes, assets/animations/emotes/uploads, docs/workshop/emote-making.md, docs/playtests, docs/decisions, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-22 03:05 -05:00

★ START HERE: Goal: Magician, the next 1st-place winners' emote, built so Alan says it is right. Opening action: build it to the card he OK'd (`docs/decisions/2026-11-22-magician.md`; the card and where it plugs in are the last section of `docs/workshop/emote-making.md`): Roblox's Godlike emote for the float, paper planes from above circling the kid, a bow as they come down, the planes scattering with one passing close by the lens. Done when the scene's code runs in Edit with no error and the numbers say the kid and the ring stay in the picture; then ask his go for a muted recording.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then the Magician section at the end of `docs/workshop/emote-making.md`. Memories: emotes-show-feeling-in-movement, emotes-on-odd-avatar-bodies, plan-before-building-features, alan-does-play-checks, mute-studio-tests, studio-not-drawing, scripts-through-the-write-tool, fix-the-annoyance-only, visual-qa-before-showing.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `d80a33d9`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (230 pages).
- Studio: place "FlyFightPaper(First Fold)", id `3b7ccacd-5c24-4664-8e17-d8ff569d33d8` this session, in Edit; `DevMute` and `DevFirstEmote` cleared. **Nothing saved by me.** Rojo's plugin was connected all session (Studio's scripts took each repo change by themselves; check a script's `Source` length against the file before trusting it). The draft `BubblegumClip` is deleted from the open place: Studio plays the upload.
- Seen by Alan: Bubblegum's second and third muted recordings and the recording with sound B. Not seen or heard by him in his own Play.
- Cost this session: three muted Play runs of about a minute each; one Sonnet reviewer agent (116k tokens, 34 s); Gemini $0.26 (one call; one refused call cost nothing); four free uploads. Primary's context about 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Build Magician** (above). The body: `rbxassetid://10714347256` (Godlike; 7.13 s, loops, read in Edit) at seven tenths speed. The bow is not in that clip: look for one of Roblox's own first; if none, a short clip of ours (a paid reference video is his go, price first). The planes and the extra lift are the scene's own code. Behind a Dev button like "end: gum".
2. **A muted recording**, his go; look at stills (and a slow clip) before he sees it; then his notes.
3. **Sound**, his go and a price first; then uploads, his go each.
4. **Bubblegum, his action:** restart Play, press "end: gum", listen. The three loudness numbers are mine (snap 1, pop 1.6, peel 1.2). Roblox was still reviewing the three sounds at 03:00; they loaded in Studio.
5. After Magician: So Close. Still open, his word: who gets which emote; Toy Pilot from the upload; the report card loses 0.6 s under Bubblegum.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too), bot matches, every upload, every generator call (price first), any new mechanic or number.
- Stop rule: Bubblegum's look and sound are approved ("I think it looks good", "That works"): change nothing in it unless he names it after hearing it in Play. A reviewer's objections to it are not a reason.

## DECISIONS & WHY (this session)
- **Bubblegum's tear:** his "it just comes out as a flat sheet ... very asymmetric, very broken up ... scrape it off"; the plan he said "Yes" to is in `docs/playtests/2026-11-22-bubblegum-second-run.md`; how it is built is in the emote log.
- **The bubble stays 0.1 see-through:** I had made it 0.05 from stills (the face showed faintly); he then called what he saw fine, so it went back.
- **The reviewer's verdict was not acted on:** blind, on stills, it read the tear as a tent or curtain edge; Alan, told that first, on the video: "I think it looks good". His eye at speed decides.
- **Sound B (Gemini) over A (the reference video's own):** his "That works", confirmed as the last video sent. There is no separate smack on the lens: the pop's tail stands in for it.
- **Magician:** his words and my defaults (speed, lift, white planes, six of them, no lens hit) in `docs/decisions/2026-11-22-magician.md`. Godlike costs 64 Robux in the avatar shop; the game plays its animation by id as it plays Applaud's: nothing bought.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Rulings: `docs/decisions/2026-11-22-magician.md`, `2026-11-22-bubblegum.md`, `2026-11-20-camera-flick-and-real-winners.md` (no zoom on 1st).

## CARRY NOTES / GOTCHAS
- Recording recipe (worked three times): `DevMute` true in Edit; a background PowerShell mouse nudge (one pixel there and back every 15 s, 4 minutes, then stop it); start Play; client `RoundAction:FireServer("mapReady")`, then `"join"`; wait for 12 in `workspace.Planes`; `video_capture` on; set `DevFirstEmote` on `ReplicatedStorage.FlyFightPaper` and fire `"endMatch"`; 23 s; capture off; read the Play's output before stopping; stop; clear both attributes in Edit. The pop was 17.2 to 17.4 s into the capture.
- Edit check of a scene function: `loadstring` the text from the script's `Source` with stand-ins, parts in a Folder outside the place, step it by time. Drawing the outline from the same numbers with PIL caught two flaws before a Play run.
- `tools/gemini_video.py`: `--edit` is refused together with a length; call it without `--edit`, `--duration` equal to the clip's whole seconds, the clip at a fixed 30 frames a second. Gemini does not place sounds on our moments: cut and place by hand.
- An ffmpeg mix of several delayed sounds needs `asetpts=N/SR/TB` at the end, or the file's sound timing is broken.
- Four "Gameplay:2 ... JSONTypes" lines in Edit's log are from an Edit-time check, not from Play.
- `.planning/emotes/*` are untracked working files. `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).
- A running Play keeps its old code: say "restart Play" with every change.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`; the commit with this file comes after):
`d80a33d9` Bubblegum uploaded and wired in · `2889f606` Magician's card OK'd · `39c8c290` Magician: his change, second card · `291db51d` sound is B · `fc34573f` STATE tidied · `be8d81d9` sound approved, three files; Magician's first card · `7a27fcb8` first Gemini sound try · `21915791` "it looks good, it needs sfx"; free listen A · `7ac99349` third muted run · `ac78b081` the tear rebuilt · `6148a2d1` his notes on the second run · `c11d1fe2` second muted run, three flaws fixed · `8aa59c75` the two fixes built.
Queued, not started: Magician's build, So Close; who gets which emote; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Bubblegum's second and third builds, all three runs, his notes, the sound (A, B, the files, the uploads, the wiring); Magician's card, his change, his OK and where it plugs in.
- `docs/playtests/2026-11-22-bubblegum-second-run.md` and `-third-run.md` (new) and the README. `docs/decisions/2026-11-22-magician.md` (new) and the README.
- `docs/workshop/lessons.md` ("Emotes on real bodies"): a stills reviewer and a fast effect; drawing the outline before a Play run.
- `docs/systems/modes-and-scoring.md` (Bubblegum where it stands). `state/STATE.md`. Checker: OK (230 pages).

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`GUM`, `gumClip`, `gumProps`, `gumBubble`; `copyWinner`; `leaving()`; the render step's call per emote). Sounds: `src/client/Audio.luau`. Ids: `config/gameplay.json` (`rounds.emote_clips`, `rounds.bubblegum`), then `python tools/generate_config.py`. Dev panel: `src/client/FlightHUD.luau` (the list with "gum").
- Videos: `.planning/emotes/bubblegum-third-run-cut.mp4`, `bubblegum-third-run-tear-slow.mp4`, `bubblegum-sound-try1.mp4` (the approved sound on the picture).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
