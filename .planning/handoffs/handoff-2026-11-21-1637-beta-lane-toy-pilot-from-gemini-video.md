# HANDOFF — 2026-11-21 — Toy Pilot is on its fourth version, built from Alan's Gemini video; he has seen three ("better, still off") and not the fourth

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=tools/emote_clips.lua, tools/emote_trace.py, src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, assets/animations/emotes/toy-pilot.rbxm, docs/workshop/emote-making.md, docs/playtests, docs/systems/modes-and-scoring.md, state/STATE.md
**Time:** 2026-11-21 16:37 -05:00

★ START HERE: Goal: a Toy Pilot (the free 1st-place emote) that Alan says looks right in Play: a kid lost in flying their plane, ending in a victory pose. The fourth version is baked and waits behind Dev "end: pilot"; nobody has seen it move. Opening action: get his look at it (or his go for one muted Play recording of mine first, laid beside his video). Done when he says the raised arm and the ending read right, or names what is still off.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Toy Pilot: the cut from a reference video" and `docs/playtests/2026-11-21-toy-pilot-first-cut.md` (all three looks, in his words). Memories: reference-videos-via-gemini, emotes-show-feeling-in-movement, alan-does-play-checks, mute-studio-tests, studio-not-drawing, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `24c4e7d6`. Pushed (the hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (they need Play: his go). Docs: `python tools/check_docs.py` OK (220 pages).
- Studio: place "FlyFightPaper(First Fold)", in Edit, camera Fixed, `DevMute` cleared, `DevFirstEmote` cleared. **Nothing saved by me.** The draft `ToyPilotClip` (fourth version, 391 keys) is in the open place's `Assets`, unsaved; the same clip is `assets/animations/emotes/toy-pilot.rbxm`. After a close without a save: `_G.EMOTE_CLIPS = { "cut:ToyPilot" }` in Edit, then `python tools/emote_preview.py STUDIO_ID x.mp4 --lua=emote_clips.lua "--bake=ToyPilot:ToyPilotClip:assets/animations/emotes/toy-pilot.rbxm"`.
- Rojo: I started `rojo serve` in the background this session (port 34872); Studio had the new `WinnersCutscene` and `FlightHUD` and they compiled. It dies with the session: start it again if Studio's code looks old.
- The mouse nudge that keeps the screen awake is stopped.
- Seen by Alan in Play: versions 1, 2 and 3. Seen by Claude: versions 2 and 3 in two muted Play recordings (his go, given for that comparison). Version 4: numbers only.
- Cost this session: no agents, no uploads, no generator calls. Two Play runs of mine (about 40 s each, recorded with the Studio link's `video_capture`), one Edit render, about a dozen number runs in Edit. Alan made one Gemini video. Primary's context about 50% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **His look at version 4** (restart Play; Dev: hangar, F8, "end: pilot"), or first one muted Play recording of mine beside his video if he gives the go. What he faulted in version 3 and version 4 is meant to fix: the raised arm cramped (bent, short, plane close to the head) and the ending ("not extending their arm up enough. It doesn't look like a victory ... just holding the paper airplane").
2. If still off: his words decide. Known and not yet solved: Roblox arms are short against the head, so even a straight arm ends near the top of the head; the plane (1.3 head widths long, held by its tail, nose up) is what reaches above it.
3. Then, each on his word: Toy Pilot's two whooshes and whether the start stays at 2 quiet seconds (the video's) or stretches to 4 for the runner-ups' sounds; the upload and its id in `rounds.emote_clips` and `rounds.winner_plane_emote`; a plan in words for who gets which emote; the next emotes (Book Kicker, Bubblegum, Magician, So Close), each starting with a Gemini prompt for a reference video.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit pictures too), bot matches, every upload and every generator call, any new mechanic or number. His go for my two Play runs today was for that comparison only.
- Stop rule: Good Game, Nap, Next One, Camera Flick, the framing, the lighting and the sound pass are approved; leave them. In Toy Pilot he did not fault the calm start, the lean to the left or the timing: change only what he names.

## DECISIONS & WHY (this session)
- **Reference videos come from Gemini** (Alan: "from this point on"): I write the prompt, he runs it. His video for Toy Pilot: "this should actually be perfect". It is the target; the file is in his Downloads ("Generated Video November 21, 2026 - 3_57PM.mp4"), not in the repo.
- **The cut is posed by numbers from the video** (`tools/emote_trace.py` → rows in `CUTS.ToyPilot`), not cut from generated clips. Version 1, from generated clips, put the hand in the face.
- **Not a copy of the mannequin.** Roblox bodies have short arms and big heads: the hand is kept out to the side, a raised arm is a wide V, and where the video folds the arm over the head the body leans left under the plane instead. My calls, from the Play recording.
- **The ending closes the V to the video's high arm** after a pull-in and a push straight up, so the plane ends nose up (version 4; his "not a victory").
- **`reach` held every arm to 0.95 of its length: an elbow bent 36 degrees.** That was the "bent, short" raised arm. A raised arm now goes to 0.995. Nap and Next One still use 0.95 (approved; untouched).
- **A plane emote stands in its first pose from the dark on** (`held` in `WinnersCutscene`): starting at the light, the arm snapped up in 0.2 s ("extremely rushed").
- **One Dev switch for 1st's emote**: `DevFirstEmote` = "ToyPilot" or "CameraFlick" (was `DevCameraFlick`); the song "end:" buttons clear it.
- Timing is the video's, one to one: flying starts 2 s after 1st's light, not the 4 s planned for the runner-ups' sounds. Told to him twice; no answer yet.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above.

## CARRY NOTES / GOTCHAS
- **Numbers on the blocky test kid do not show a real avatar.** In Play the same clip put the hand 0.8 to 0.9 head widths from the head's middle where the test kid has 1.8. Record the scene in Play and lay it beside the reference before he looks (recipe: emote-making, step 5).
- A scripted winners' moment in my own Play: mute in Edit first (its own call), start Play, client `RoundAction:FireServer("mapReady")` and `("join")`, wait for 12 models with `PilotId` in `workspace.Arena`, set `DevFirstEmote`, fire `"endMatch")`; 1st's light is about 6.8 s later. Winner at `workspace.WinnerStage...Winner1`. Clear `DevMute` after the stop.
- `emote_trace.py` expects a grey mannequin on a lighter room holding something white in its right hand; its shoulder offsets were measured on this video. Keep the next prompts to that look, and check its six pictures.
- The emote-making page's table and "third version" numbers are from before version 4; its header says so.
- A running Play keeps its old code and the old draft: say "restart Play" with every change.
- Bash heredocs with an apostrophe fail here: write patch scripts with the Write tool, then run them.
- `tools/art/hero.py.old` is untracked and not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`24c4e7d6` Toy Pilot, fourth version (straight raised arm, high ending) · `246afd84` his verdict on the third · `055168b6` third version, after the Play recording · `4a9ecd00` second cut, traced from the Gemini video; `emote_trace.py` · `bce6c3c1` his playtest: first cut rejected · `add2e351` first cut and the Dev button "end: pilot"; the held plane fades with the kid.
Queued, not started: Toy Pilot's sounds and upload; who gets which emote; the next emotes; class reaction; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: "Toy Pilot: the cut from a reference video" (the Gemini way, video to cut in five steps, the Play recording recipe, what is still weak).
- `docs/playtests/2026-11-21-toy-pilot-first-cut.md`: all three looks in his words, what the recording showed, causes and fixes.
- `docs/systems/modes-and-scoring.md`: Toy Pilot behind "end: pilot"; first pose held from the dark.
- `docs/workshop/tools.md`: `emote_trace.py`; `emote_clips.lua` row. `docs/workshop/lessons.md`: one line pointing to the emote page's lessons.
- `state/STATE.md`. Memory: `reference-videos-via-gemini` (new). Checker: OK.

## POINTERS
- Cut: `tools/emote_clips.lua` (`CUTS.ToyPilot`, `reach`, the TOY constants and their comment). Trace: `tools/emote_trace.py`. Scene: `src/client/WinnersCutscene.luau` (`holdPlane`, `flyPlane`, `held`, `ourClip`). Dev buttons: `src/client/FlightHUD.luau`.
- Picture of the comparison (reference, version 2, version 3): `.planning/emotes/toy-pilot-play-vs-reference.jpg`.
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
