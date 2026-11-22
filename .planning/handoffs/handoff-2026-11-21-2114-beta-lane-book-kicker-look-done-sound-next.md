# HANDOFF — 2026-11-21 — Book Kicker's look is built to Alan's notes and he moved on to sound; his go for up to three Gemini tries is given, none made

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/MenuController.luau, tools/emote_clips.lua, tools/studio_push.py, assets/animations/emotes, docs/workshop/emote-making.md, docs/playtests, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-21 21:14 -05:00

★ START HERE: Goal: Book Kicker (1st jumps off their book stack, lands beside it and kicks it; the books fly at the camera, one opens, lands tilted and out of focus on the lens) with its sound, that Alan says is right. The look is built and he said "yes do the sound next". Opening action: the first of up to three Gemini calls he has OK'd (about 25 to 35 cents each, about $1 at most) that adds sound to the finished recording; keep only the sound, lay it under our recording, send him the MP4 to listen. Done when he says the sound is right, or names what is off.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Gemini by API, how it works" and from "Sound: the plan and the price". Memories: reference-videos-via-gemini, audio-picks-links-and-studio, send-videos-not-gifs, alan-does-play-checks, mute-studio-tests, studio-not-drawing, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `29e12d83`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (223 pages).
- Studio: place "FlyFightPaper(First Fold)", in Edit, `DevMute` and `DevFirstEmote` cleared. **Nothing saved by me.** Unsaved in the open place: the re-baked `BookKickerClip` in `Assets` (the same clip is `assets/animations/emotes/book-kicker.rbxm`) and the new `WinnersCutscene` and `MenuController` sources, copied in by hand. After a close without a save: `_G.EMOTE_CLIPS = { "cut:BookKicker" }` in Edit, `python tools/emote_preview.py STUDIO_ID x.mp4 --lua=emote_clips.lua "--bake=BookKicker:BookKickerClip:assets/animations/emotes/book-kicker.rbxm"`, and `python tools/studio_push.py STUDIO_ID src/client/<file>.luau "<its Luau path>"` for both scripts.
- **Rojo's Studio plugin is still disconnected** (the server runs; Alan has not clicked Connect). Check a script's `Source` in Edit before trusting Studio has new code.
- Seen by Alan: the second recording ("the dismount looks good, where they land looks good ... the kick looks good"), the third (tilt; blur failed), three blur strengths as a picture. On the fourth recording (blur growing to strength C, Menu tag hidden) he answered "yes do the sound next": my reading is that the lens moment is accepted; he did not say so in those words.
- Cost this session: one read-only docs agent (web-fetch, 97k tokens); three muted Play runs of mine, about a minute each; no money, no uploads, no generator calls. Primary's context about 42% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The sound, by Gemini** (his go: "go for up to three tries"; the price he was told: about 25 to 35 cents a try, about $1 at most). Send `.planning/emotes/book-kicker-fourth-run-cut.mp4` (9.3 s) as the input video and ask for the kick, the books flying, the books hitting the ground and a smack on the lens, at the smallest picture size (360p: about 23 cents for 10 s; the input's cost is not published, my worst case 9 cents). The model always returns a video; only its sound is kept and laid under our recording at our own moments (kick 5.62 s after 1st's light, the book on the lens 0.45 s later). Tell him what each try cost. If the model refuses a video as input, or three tries do not give usable sounds: the free fallback is cutting the kick and book sounds out of `.planning/emotes/book-kicker-gemini-api-1.mp4`. Done when he has listened to an MP4 with sound and says it is right, or what is off.
2. Then, each on his word: the sounds into the game (Roblox uploads; a quiet level like Toy Pilot's whoosh is the precedent), the clip's upload with its id in `rounds.emote_clips` and its marks in the config (an uploaded clip carries no attributes); a plan in words for who gets which emote; the next emotes (Bubblegum, Magician, So Close).
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too), bot matches, every upload, every generator call beyond the three OK'd tries (tell him the price first), any new mechanic or number.
- Stop rule: the dismount, the landing, the kick, the tilt, the blur growing to strength C and the hidden Menu tag are his words: leave them unless he names something. Toy Pilot, Camera Flick, Good Game, Nap, Next One, the framing, the lighting and the winners' sound are approved.

## DECISIONS & WHY (this session)
- **The scene moves the kid, not the clip** (`kickLanding` in `WinnersCutscene`): Roblox shrinks a clip's moves with the body while the stack and the beam keep their size, which is why a short winner "kicked the air". The landing is worked out from each avatar's hip height; the clip stands on one spot.
- **The kid stands at the beam's edge, not its middle**: closer would hide them behind the stack. Alan called where they land good. A lamp that follows the jump was offered and not asked for.
- **Pages are drawn by code** (Path2D strokes on a SurfaceGui): no picture, no upload. The same from both ends, so a page's canvas direction does not matter.
- **Blur is a `BlurEffect` on the whole picture**, not the focus effect: `DepthOfFieldEffect`'s near blur left the book sharp in Play. It follows the book's nearness by 1 / distance (Alan: "it should get blurrier as it gets closer ... ends in C when its on the camera").
- **The Menu tag hides through the attribute `LensCovered`** that `MenuController` reads, so its own show and hide logic is not fought.
- **`tools/studio_push.py` replaces the http.server recipe**: the Assistant's HTTP allowlist now refuses `127.0.0.1`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above.

## CARRY NOTES / GOTCHAS
- `KICK_BLUR` (0.025 of the screen's height) was matched to his "C" by eye on one 2046 x 801 Studio window; other screen shapes are not checked.
- Roblox says a `BlurEffect` may render differently on low-end devices: there the book may be tilted but sharp.
- The recording recipe that worked three times: mute in Edit (own call), start the mouse nudge (a background PowerShell, one pixel every 15 s), start Play, client `mapReady` and `join`, wait for 12 in `workspace.Planes`, `video_capture` on, set `DevFirstEmote` and fire `endMatch`, 19 s, capture off, stop, clear `DevMute` and `DevFirstEmote`, stop the nudge. The kick is about 12.4 s after `endMatch`.
- In every run the winner was the same short bot girl; Alan's dog and a tall avatar have not been seen with the new landing.
- Draw a new pattern offline at its screen size before a Play (the first scribbles were three times too coarse and ran the wrong way).
- `.planning/emotes/*.mp4` and pictures are untracked working files. `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).
- A running Play keeps its old code: say "restart Play" with every change.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`29e12d83` the book gets blurrier the closer it comes, ends at C; the Menu tag hides; fourth recording · `57bf08df` third recording: tilt works, the focus blur failed, swapped for a whole-picture blur · `ac6864cc` Alan calls the jump, landing and kick good; tilt and a first blur · `bbeae422` second recording: the leg goes behind the stack; scribbles redrawn as handwriting · `e3cb1bc1` second build: landing by the kid's own legs, no name plates on the lens, scribbled pages; `tools/studio_push.py`.
Queued, not started: Book Kicker's sound and upload; who gets which emote; Bubblegum, Magician, So Close; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: second build, second to fourth runs, the book on the lens (tilt, blur, Menu tag), "Sound: the plan and the price".
- `docs/playtests/2026-11-21-book-kicker-second-run.md` (new; his notes through the sound go) and the README; `docs/playtests/2026-11-21-book-kicker-first-run.md` (what got built).
- `docs/workshop/lessons.md`: the dead http.server recipe, a SurfaceGui's x on top and bottom faces, the focus effect's near blur. `docs/workshop/tools.md`: `tools/studio_push.py`.
- `docs/systems/modes-and-scoring.md` (Book Kicker where it stands). `state/STATE.md`. Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`kickLanding`, `scribbled`, `kickProps`, `kickBooks`, `KICK_*`, the `WinnersLens` blur and `LensCovered` in the render step). Cut: `tools/emote_clips.lua` (`CUTS.BookKicker`).
- Recordings: `.planning/emotes/book-kicker-fourth-run-cut.mp4` (the finished look), `book-kicker-fourth-run-lens-slow.mp4`, `book-kicker-blur-options.jpg`. Gemini reference with sound: `.planning/emotes/book-kicker-gemini-api-1.mp4`.
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
