# HANDOFF — 2026-11-22 — Bubblegum is built and recorded once; Alan: the body is fine, the bubble and the gum on the lens are not; both fixes OK'd in words, not built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, tools/emote_clips.lua, assets/animations/emotes, docs/workshop/emote-making.md, docs/playtests, docs/decisions, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-22 01:35 -05:00

★ START HERE: Goal: Bubblegum, the winners' emote, so Alan says it is right. Opening action: build the two fixes he OK'd in words ("yes pulled down, and yes make it nearly solid"), in `gumBubble` / `gumProps` of `src/client/WinnersCutscene.luau`: (1) the bubble nearly solid pink, the kid only a darker shape behind it, never a face; (2) the lumps on the lens replaced by one flat smooth sheet of gum that sticks about a second and is then pulled off downward as one piece, its top edge stretching into a handful of uneven strands (fat at the sheet, thin at the top) that thin and snap one after another. Done when the scene's code runs in Edit with no error and the numbers say the lens is covered edge to edge; then ask his go for a second muted recording.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/playtests/2026-11-22-bubblegum-first-run.md` (his words) and the Bubblegum section at the end of `docs/workshop/emote-making.md`. Memories: emotes-show-feeling-in-movement, reference-videos-via-gemini, plan-before-building-features, alan-does-play-checks, mute-studio-tests, studio-not-drawing, scripts-through-the-write-tool, fix-the-annoyance-only.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `70cb39ad`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (227 pages).
- Studio: place "FlyFightPaper(First Fold)", id `3b7ccacd-5c24-4664-8e17-d8ff569d33d8` this session, in Edit; `DevMute` and `DevFirstEmote` cleared. **Nothing saved by me.** Unsaved in the open place: the draft `BubblegumClip` in `ReplicatedStorage.FlyFightPaper.Assets` (the same clip is `assets/animations/emotes/bubblegum.rbxm`) and the new `WinnersCutscene` and `FlightHUD` sources. After a close without a save: `_G.EMOTE_CLIPS = { "cut:Bubblegum" }` in Edit, `python tools/emote_preview.py STUDIO_ID x.mp4 --lua=emote_clips.lua "--bake=Bubblegum:BubblegumClip:assets/animations/emotes/bubblegum.rbxm"`, and `python tools/studio_push.py STUDIO_ID src/client/<file>.luau "game.StarterPlayer.StarterPlayerScripts.FlyFightPaper.<Name>"` for both scripts.
- Rojo: not known. Both scripts in Studio already had the repo files' sizes before I pushed them, so its plugin may be connected again. Check a script's `Source` in Edit for `gumBubble` before trusting Studio has new code.
- Seen by Alan: the first muted recording (`.planning/emotes/bubblegum-first-run-cut.mp4`), not in his own Play.
- Cost this session: no agents. Gemini about $0.58 (two videos through his API key: 10 s 360p about 23 cents, 15 s 360p about 35). One muted Play run of mine, about a minute. No uploads. Primary's context about 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The two fixes** (above). Check without Play: the Edit recipe in the carry notes; a sheet and its strands must cover the picture from the pop's first frames until the pull, and be gone about 2 s after the pop.
2. **A second muted recording**, his go; look at stills for the face behind the bubble and for the sheet reading as one layer before he sees it; then his notes.
3. **Sound**, his go and a price first: the big pop matters most; also the small snap and the gum hitting the lens. Then the uploads (the clip, the sounds), his go each.
4. Open, his word: the report card loses 0.6 s (Bubblegum leaves 11.0 s after 1st's light, the scene normally 10.4); an earlier pop fixes it. Still open from before: who gets which emote; Toy Pilot from the upload.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too), bot matches, every upload, every generator call (price first), any new mechanic or number.
- Stop rule: the body (stance, weight shift, lean, timing) has no complaint from him: "it's kind of just the bubblegum that's the problem". Leave it. Book Kicker, Good Game, Toy Pilot, Camera Flick, Nap, Next One, the framing, the lighting and the winners' sound stay approved.

## DECISIONS & WHY (this session)
- **Sassy from start to finish** (his correction of my first card, where the cool broke): `docs/decisions/2026-11-22-bubblegum.md`.
- **The camera does not creep in, against my own card:** his ruling of 2026-11-20 is "No zoom in on 1st". The bubble grows to kid size, then swells to the lens in its last second. He has seen it and said nothing against it; he has not been asked to approve it by name beyond my report.
- **Clip 13 s, pop at 10.0:** his "a little sped up" on a 10 s video; the second video (15 s) he built from.
- **The kid keeps facing the camera in the lean;** the video's mannequin turned side-on. Lean 22 degrees back, 9 to the weight side: my numbers.
- **Arms hang from the body's own rest pose**, pole outwards, 0.96 of joint-to-joint length (why: lessons.md).
- **The gum sheet's look is not designed yet:** "one flat smooth sheet, a soft shine" are my words, OK'd as a plan. The first try's lumps read as bright pink cushions with dark seams; the sheet should also not be far brighter than the dark room (my observation, not his).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Rulings: `docs/decisions/2026-11-22-bubblegum.md`, `docs/decisions/2026-11-20-camera-flick-and-real-winners.md`.

## CARRY NOTES / GOTCHAS
- Recording recipe that worked: `workspace:SetAttribute("DevMute", true)` in Edit (own call); a background PowerShell mouse nudge (user32 `mouse_event`, one pixel there and back every 15 s, ending itself after 4 minutes); start Play; client `RoundAction:FireServer("mapReady")` then `"join"`; wait for 12 in `workspace.Planes` and count `RenderStepped` (2 frames in the first second, about 50 a second after 4 s); `video_capture` on; set `DevFirstEmote` = "Bubblegum" on `ReplicatedStorage.FlyFightPaper` and fire `"endMatch"`; 23 s; capture off; stop; clear both attributes in Edit. 1st's light is 6.6 s after `endMatch`, the pop 16.6 s.
- Edit check of the scene's code: take the text from `local GUM = {` to `-- The book podiums` plus `paper` from the script's `Source`, `loadstring` it with stand-ins (`RunService`, `Root`, `ourClip`, `Rounds`, `ease`, `POP`, `POP_BITS`, `SHOT_FOV`), a stand-in head and root, a camera 19 studs away; step `gumBubble(w, t, view, 140)`.
- Body check on bots in Edit: `Players:GetHumanoidDescriptionFromOutfitIdAsync` over `avatar_display.bot_look_outfits`, register the draft clip, `Animator:StepAnimations(0)` at a few `TimePosition`s, parts' places from the joints' `Transform` (these bodies use `AnimationConstraint`). The first model's track had length 0: skip its row.
- The "Asset type does not match requested type" lines in the output are there in a muted Play; no script error was among them.
- The Dev button "end: gum" is at x 990 of the top row, a slot nobody else uses.
- `.planning/emotes/*` are untracked working files. `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).
- A running Play keeps its old code: say "restart Play" with every change.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`; the commit with this file comes after):
`70cb39ad` Alan OKs the two fixes in words · `df6110ab` his notes on the first run · `3e65f5a4` the first run in a muted Play · `5cee7a7a` Bubblegum built: body clip, bubbles, pop, gum on the lens · `b09f1f35` first video too fast; second at 15 s with the bubble · `54088cda` first Gemini reference video · `5e2e4fee` shot card OK'd and the Gemini prompt.
Queued, not started: Magician, So Close; who gets which emote; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Bubblegum's card, both prompts' results, the build, every numbers check, the first run, his notes and the OK'd plan.
- `docs/playtests/2026-11-22-bubblegum-first-run.md` (new) and the README. `docs/decisions/2026-11-22-bubblegum.md` (new) and the README.
- `docs/workshop/lessons.md` ("Emotes on real bodies"): the scene's real camera before a card; a reference video shows the whole act; `reach` on a hanging arm; `emote_trace.py`'s limit. `docs/workshop/tools.md`: Bubblegum in `CUTS`.
- `docs/systems/modes-and-scoring.md` (Bubblegum where it stands). `state/STATE.md`. Memory `reference-videos-via-gemini` (his "sped up" note). Checker: OK (227 pages).

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`GUM`, `gumClip`, `gumProps`, `gumBubble`; `state.gumAt` in `Cutscene.play`). Body: `CUTS.Bubblegum`, `gumTrunk` in `tools/emote_clips.lua`. Dev panel: `src/client/FlightHUD.luau`.
- Videos: `.planning/emotes/bubblegum-gemini-api-2.mp4` (the reference he built from), `bubblegum-first-run-cut.mp4` (the first run; 1st's light at 2 s, the pop at 12 s).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
