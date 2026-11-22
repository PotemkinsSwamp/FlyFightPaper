# HANDOFF — 2026-11-21 — Toy Pilot is done and uploaded; Book Kicker has a first build that runs, and Alan's notes on it wait to be built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=tools/emote_clips.lua, src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, src/client/Audio.luau, config/gameplay.json, assets/animations/emotes, docs/workshop/emote-making.md, docs/playtests, docs/decisions, state/STATE.md
**Time:** 2026-11-21 20:00 -05:00

★ START HERE: Goal: a Book Kicker (a 1st-place emote: the kid jumps off their book stack, lands beside it facing the camera and kicks it; the books fly at the camera, one opens and smacks the lens) that Alan says looks right in Play. The first build runs end to end; he has given notes on a recording of it. Opening action: build his three fixes (land closer and inside the spotlight so the foot's tip goes behind the stack; no name plates over the book on the lens; scribbled, illegible pages). Done when he says the kick no longer looks like "kicking the air" and the lens moment is right, or names what is still off.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/playtests/2026-11-21-book-kicker-first-run.md` (his notes, in his words) and `docs/workshop/emote-making.md` from "Book Kicker: shot card and Gemini prompts". Memories: emotes-on-odd-avatar-bodies, reference-videos-via-gemini, alan-does-play-checks, mute-studio-tests, studio-not-drawing, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `cf160597`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run all session (they need Play: his go). Docs: `python tools/check_docs.py` OK (222 pages).
- Studio: place "FlyFightPaper(First Fold)", in Edit, `DevMute` cleared, `DevFirstEmote` cleared. **Nothing saved by me.** Unsaved in the open place: the draft `BookKickerClip` in `Assets` (301 keys; the same clip is `assets/animations/emotes/book-kicker.rbxm`), and no `ToyPilotClip` (deleted on purpose: "end: pilot" plays the upload). After a close without a save: `_G.EMOTE_CLIPS = { "cut:BookKicker" }` in Edit, then `python tools/emote_preview.py STUDIO_ID x.mp4 --lua=emote_clips.lua "--bake=BookKicker:BookKickerClip:assets/animations/emotes/book-kicker.rbxm"`.
- **Rojo's Studio plugin is disconnected.** The server died mid-session; I restarted it (it dies with the session) and copied `WinnersCutscene` and `FlightHUD` into Studio by hand from the repo files, byte for byte. Alan was asked twice to click Connect; not confirmed. Check a script's `Source` in Edit before trusting Studio has new code.
- Seen by Alan: Toy Pilot's fourth version in Play ("it looks fine"), its whoosh at the quiet level ("fine"); Book Kicker only as my recording. Not seen by him: Toy Pilot played from the upload.
- Cost this session: one read-only docs agent (web-fetch, 74k tokens); one Gemini video call (about $0.70 of Alan's credits); one Roblox upload (Toy Pilot); one muted Play run of mine (about a minute). Primary's context past 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Build his three fixes**, then get his look (or, on his go, one muted Play recording of mine first):
   - Landing: closer to the stack and inside the beam, so that from the camera the kicking foot's tip goes behind the stack. Today `KICK_SIDE`, `KICK_BACK` = -0.65, 0.3 winner heights in `tools/emote_clips.lua`; the beam is 0.76 heights to each side at the desk; the stack is 0.56 wide. The right arm must still clear the stack (the number check is described in emote-making).
   - Name plates: not drawn while the book covers the lens (`state.plates` in `WinnersCutscene`; Camera Flick's plane has the same overlap and is approved: change only Book Kicker unless he says otherwise).
   - Pages: scribbles that look like writing and say nothing. The method is open; a new picture is an upload (his go).
2. **Ask at that look** what he has not said: does the dismount read as a jump, is the kick itself right.
3. **Sound, after the look is right** (his order): Gemini adds audio to a recording of the finished emote, or the kick, the flying books, the books hitting the ground and a smack are taken from a Gemini video's sound. Then the upload of the clip, its id in `rounds.emote_clips` and its marks in the config (an uploaded clip carries no attributes).
4. Then, each on his word: a plan in words for who gets which emote (my recommendation, not yet answered: do it before more emotes, since no player can see any of them until then); the next emotes (Bubblegum, Magician, So Close).
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too), bot matches, every upload, every generator call (every Gemini API call costs money: tell him the price first), any new mechanic or number.
- Stop rule: Toy Pilot, Camera Flick, Good Game, Nap, Next One, the framing, the lighting and the winners' sound are approved; leave them. In Book Kicker he called the tall stack and the five quick books fine: do not change them.

## DECISIONS & WHY (this session)
- **A held plane always touches the hand; odd bodies are an accepted loss** (Alan, after seeing my sliding-plane rule in Play: "It has to be touching the hand"). No neutral body on the podium, no buyable characters. The rule was built (`f1abdbb4`) and taken out (`ddca5aba`). `docs/decisions/2026-11-21-plane-stays-in-the-hand.md`.
- **Toy Pilot's only sound is one quiet whoosh, twice** (his pick 2 of 3; "a subtle sound ... this is practically it"), at 3.0 s and 4.5 s after the light; volume 0.6 where other emote sounds are 1.4 to 2. The start stays at 2 quiet seconds.
- **Toy Pilot is uploaded but `rounds.winner_plane_emote` stays empty**: like the other six it plays in Studio only until who gets which emote is decided.
- **Book Kicker's staging is Alan's, word for word**: jump off the stack, land a little to its side still facing the camera, kick the books at the camera. Two prompts of mine missed it (a drop kick from the hands; a side-on kick). I do not change his staging on my own again; a concern goes to him in words.
- **The Gemini video gives timing only.** My prompts asked for a shin-high stack; the real one reaches the kid's shoulders. The body is posed by numbers (`CUTS.BookKicker`).
- **The clip keeps the kid at one height; the scene does the drop** (each winner's stack height differs), from the clip's marks `HopFrom`, `HopTo`, `HopUp`; the books leave at `Kick`.
- **The open book is four plain blocks** swapped in for the top book at the kick: nothing better is loaded. He wants scribbles on it.
- **Gemini through Alan's API key works** (`GEMINI_API` in `.env`; model `gemini-omni-1.2-flash`, the Interactions API; recipe and price in emote-making). No tool in the repo yet: add one at the second call.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above.

## CARRY NOTES / GOTCHAS
- Rojo is not on the shell's path: `"C:/Users/gutie/AppData/Local/Rojo/bin/rojo.exe" serve serve.project.json` (lessons.md).
- A file can be compile-checked without Play by sending its text to `loadstring` in Edit (lessons.md).
- In my Play run a bot won (a short girl); Alan wins as his dog when he plays, whose short legs will make the kick small (accepted).
- The recording recipe that worked: mute in Edit (own call), start the mouse nudge, start Play, client `mapReady` and `join`, wait for 12 pilots, `video_capture` on, set `DevFirstEmote` and fire `endMatch`, about 19 s, capture off, stop, clear `DevMute` and `DevFirstEmote`. 1st's light is about 6.6 s after `endMatch`; the kick 5.62 s after that.
- `.planning/emotes/*.mp4` are untracked working files (the Gemini video and my recording are there).
- A running Play keeps its old code and the old draft: say "restart Play" with every change.
- `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`cf160597` Alan's notes on Book Kicker's first run · `89007d6d` it ran end to end in one muted Play recording · `46ff6018` Book Kicker, first build, behind "end: kicker" · `8aaff48d` reference video through Alan's Gemini key; the API route written down · `c6c6df22` the kid faces the camera and kicks the books at it · `03947644` Book Kicker is Alan's version · `6256280b` shot card proposed (a drop kick; dropped) · `34adefcb` Toy Pilot uploaded · `392cbab4` its whoosh is his pick, turned down · `0df05224` Toy Pilot's look approved; three whoosh candidates · `ddca5aba` the sliding-plane rule taken out · `f1abdbb4` the sliding-plane rule.
Queued, not started: Book Kicker's fixes, sound and upload; who gets which emote; Bubblegum, Magician, So Close; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-21-plane-stays-in-the-hand.md` (new) and its README line.
- `docs/playtests/2026-11-21-toy-pilot-first-cut.md` (his fourth to sixth looks, the whoosh, the upload); `docs/playtests/2026-11-21-book-kicker-first-run.md` (new) and the README.
- `docs/workshop/emote-making.md`: Toy Pilot approved, its sound and upload; "Book Kicker: shot card and Gemini prompts" (three prompts, the Gemini API recipe, the first build, the first run, his notes).
- `docs/systems/modes-and-scoring.md` (the plane in the hand; Book Kicker behind "end: kicker"); `docs/systems/sound-and-effects.md` (Toy Pilot's whoosh); `docs/plan/WINNERS-CIRCLE-PLAN.md` (Book Kicker's row in his wording); `docs/workshop/tools.md`; `docs/workshop/lessons.md` (Rojo's path, the compile check).
- `state/STATE.md`. Memories: `emotes-on-odd-avatar-bodies` (new), `reference-videos-via-gemini` (the API key, his staging is the spec, real sizes before a prompt). Checker: OK.

## POINTERS
- Cut: `tools/emote_clips.lua` (`CUTS.BookKicker`, the `KICK` tables and their comment). Scene: `src/client/WinnersCutscene.luau` (`kickClip`, `kickProps`, `kickBooks`, `jolted`, `stackBooks`). Dev buttons: `src/client/FlightHUD.luau`.
- Recording: `.planning/emotes/book-kicker-first-run-cut.mp4`. Reference: `.planning/emotes/book-kicker-gemini-api-1.mp4`.
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
