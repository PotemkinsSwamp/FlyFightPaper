# HANDOFF — 2026-11-22 — Magician is built and recorded twice (muted); Alan's fly-over with a slight camera shake is planned and OK'd, not built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, docs/workshop/emote-making.md, docs/workshop/lessons.md, docs/playtests, docs/decisions, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-22 04:29 -05:00

★ START HERE: Goal: Magician, the 1st-place winners' emote, so Alan says it is right. Opening action: build the fly-over he OK'd ("Ok"; the plan is the last bullet of `docs/workshop/emote-making.md` and row 2 of `docs/playtests/2026-11-22-magician-second-run.md`): the line of planes passes just over the lens, a little right of the middle, each plane about as wide as the picture for a moment, and the camera trembles slightly as each goes over. Done when the scene's code runs in Edit with no error, no plane crosses the lens's own line and the kid stays in the picture; then ask his go for a third muted recording.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then the Magician section at the end of `docs/workshop/emote-making.md`. Memories: studio-not-drawing, mute-studio-tests, alan-does-play-checks, plan-before-building-features, fix-the-annoyance-only, visual-qa-before-showing, emotes-show-feeling-in-movement, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `0714827c`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (232 pages).
- Studio: place "FlyFightPaper(First Fold)", id `3b7ccacd-5c24-4664-8e17-d8ff569d33d8` this session, in Edit; `DevMute` (on `workspace`) and `DevFirstEmote` cleared; **nothing saved by me.** Its window is up and maximised (I brought it up on his word; it had been minimised). Rojo's plugin connected all session: Studio's scripts took each change (check a marker string in the script's `Source` before trusting it).
- Seen by Alan: both recordings (`.planning/emotes/magician-first-run-cut.mp4`, `-ending-slow.mp4`; `magician-second-run-cut.mp4`, `-line-slow.mp4`). Not seen in his own Play.
- Cost this session: three muted Play runs of about a minute each (the first recorded nothing useful); two Sonnet reviewer agents (120k tokens, 21 s; 112k tokens, 11 s); nothing bought, nothing uploaded, no generator call. Primary's context about 50% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Build the fly-over** (above). In `MAGIC`: the curve's end (`pass`, and `last`/`to` in `magicPlanes`) goes over the lens; the shake goes where `holdAt` already applies `jolted` for Book Kicker and Bubblegum (its shake alone, about a seventh as strong, once per plane at `MAGIC.leaves(i) + passIn`). Check in Edit as before.
2. **A third muted recording**, his go; check Studio's window first (below); look at stills and a slow clip before he sees it; then his notes.
3. **Sound**, his go and a price first; then uploads, his go each. (Both body clips are Roblox's own, played by id: nothing of ours to upload but sounds.)
4. **Bubblegum, his action, still open:** restart Play, press "end: gum", listen.
5. After Magician: So Close. Still open, his word: who gets which emote; Toy Pilot from the upload; the report card loses 0.6 s under Bubblegum.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too; bringing Studio's window up counts), bot matches, every upload, every generator call (price first), any new mechanic or number.
- Stop rule: the float, the planes' look and size, the circling, the ring unwinding into a line and the curtsy are as he saw them and he raised nothing against them: change only the line's end and add the shake. If six big undersides in a row are too much on the recording, the fallback already told to him is fewer planes over the lens. A stills reviewer's doubts about a moving effect are not a reason to change it (Bubblegum's lesson).

## DECISIONS & WHY (this session)
- **The bow is Roblox's "Curtsy" and it stays:** I picked it from its joint numbers as a bow; on screen it is a curtsy. Told that, with three options, Alan: "Keep the curtsy". No bow clip, no generator call.
- **The scatter is gone:** his "cooler if they followed in a line and flew past the camera but otherwise good stuff". Built: the ring unwinds from 8 s, the planes leave 0.2 s apart from the ring's screen-right side (the one spot where none has to turn sharply towards the camera).
- **The line's end changes again:** his "flew over the camera becoming large on screen and shaking the camera slightly like if an actual plane flew over". My plan, his "Ok": over the lens, a little right of the middle (dead centre would cover the kid six times as they land; offered, not taken), a shake of about 1% of the picture's height, no knock back.
- **The scene's length is untouched** (it leaves 10.4 s after 1st's light): the report card keeps its 10 s.
- **Unwinding starts at 8.0 s** (the plan had said 8.3): a plane is at the leaving spot then, and the last clears the camera before the scene leaves. All six circle together for 1.8 s.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Rulings: `docs/decisions/2026-11-22-magician.md`, `2026-11-20-camera-flick-and-real-winners.md` (no zoom on 1st).

## CARRY NOTES / GOTCHAS
- **Before any recording ask Windows whether Studio's window is minimised** (user32 `IsIconic` on `RobloxStudioBeta`'s main window): minimised, the game runs at 60 frames and the video holds only the name plates. Look at the recording's first second before anything else. Lesson in `docs/workshop/lessons.md`.
- Recording recipe (worked twice this session): `DevMute` true on `workspace` in Edit, in its own call; background PowerShell nudge (user32 `mouse_event` one pixel there and back every 15 s; kill it after); start Play; client waits 6 s, `RoundAction:FireServer("mapReady")`, 2 s, `"join"`; wait for 12 in `workspace.Planes`; count `RenderStepped` frames; `video_capture` on; set `DevFirstEmote` to "Magician" on `ReplicatedStorage.FlyFightPaper`, fire `"endMatch"`; 22 s; capture off; read `LogService:GetLogHistory()` for anything but "ContentId" lines; stop; clear both attributes in Edit. 1st's light is about 7.8 s into the capture; the line runs from 15.8 to 17.7 s.
- The Studio tool resets the camera type when a Client `execute_luau` ends ("changed camera type" warning): harmless here, the scene sets it every frame.
- Edit check of the scene: `loadstring` the text between `local MAGIC = {` and `-- The book podiums` from the script's `Source`, with stand-ins for `RunService`, `Root`, `Avatars`, `paper`, `ease` and the SHEET numbers; a stand-in kid of two parts in a Model outside the place; the camera rebuilt from the desks' numbers (in the emote log's first-build bullet). Project each piece's corners to the picture and count.
- A flag stored on a list of pieces is read as one of its pieces by `for _, piece in pieces`: keep flags in their own table (`magic.shown`).
- `.planning/emotes/*` are untracked working files. `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).
- A running Play keeps its old code: say "restart Play" with every change.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`; the commit with this file comes after):
`0714827c` his OK on the fly-over plan · `9707a6c1` his notes on the second recording · `95611991` the line recorded muted · `711c65cd` the new ending built (the line; the curtsy stays) · `dc518f7f` his notes on the first recording · `e43f2ea7` first recording: Curtsy is a curtsy · `ae4e8ffe` first Play run recorded nothing (Studio minimised) · `5f71b7b0` Magician built to his card.
Queued, not started: the fly-over's build, Magician's sound, So Close; who gets which emote; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Magician's first build (the bow's source, the lift, the planes, the numbers), the three Play runs, both reviewers' verdicts, his notes twice, the second build (the line) and the fly-over's plan with where it plugs in.
- `docs/playtests/2026-11-22-magician-first-run.md` and `-second-run.md` (new) and the README. `docs/decisions/2026-11-22-magician.md` (the curtsy kept, the line, the fly-over) and the README's line.
- `docs/workshop/lessons.md`: a minimised Studio records only the flat layer; a clip's joint numbers do not say what the pose looks like.
- `docs/systems/modes-and-scoring.md` (Magician where it stands). `state/STATE.md`. Checker: OK (232 pages).
- Memory `studio-not-drawing`: the minimised-window check added.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`MAGIC`, `MAGIC.clock`, `MAGIC.path`, `MAGIC.leaves`, `magicProps`, `magicPlanes`; `copyWinner`; `holdAt` and `jolted` for the camera; the render step's call per emote). Dev panel: `src/client/FlightHUD.luau` (the list with "magic").
- Videos: `.planning/emotes/magician-second-run-cut.mp4`, `magician-second-run-line-slow.mp4` (what he last saw).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
