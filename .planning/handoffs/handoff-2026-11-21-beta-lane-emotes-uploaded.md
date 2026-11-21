# HANDOFF — 2026-11-21 — Next One approved; the six emote clips uploaded and wired in, not yet seen in Play from the uploads

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, config/gameplay.json, tools/emote_clips.lua, tools/emote_preview.py, assets/animations/emotes, docs/workshop/emote-making.md, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, docs/decisions, docs/playtests
**Time:** 2026-11-21 00:33 -05:00

★ START HERE: All three runner-up emotes (Good Game, Nap, Next One) and Camera Flick are approved by Alan in Play, and their six clips are uploaded ("go to upload") and played from ids in the config. Nobody has seen them in Play from the uploads. Opening action: ask Alan to look once (or for his go for a muted Play run of mine): Dev: hangar, F8, "2nd/3rd" stepped through GoodGame, Nap, NextOne, each with "end: flick". Done when he says all four play as he approved them, or names what differs.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Next One: approved by Alan in Play" down. Memories: emotes-show-feeling-in-movement, alan-does-play-checks, plan-before-building-features, explain-plans-in-text, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `a654d4cd`. Pushed (the commit hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run this session or last (they need Play: his go). Docs: `python tools/check_docs.py` OK.
- Studio: place "FlyFightPaper(First Fold)", in Edit, camera Fixed, no test bodies left. **Nothing saved by me.** Rojo serving: Studio's `WinnersCutscene`, `FlightHUD` and `Generated.Gameplay` had the new code at the last check; both scripts compile.
- **The draft clips are deleted from the open place's `Assets`** (all six), so Studio plays the uploads. If a place opens with a `<Name>Clip` in `Assets`, that draft wins over the upload (see emote-making, "A draft wins in Studio").
- Seen by Alan in Play: Next One twice (first build: "fiddling"; four runs: "it looks good move on"). Seen by Claude: numbers only, never a picture.
- Cost this session: no agents, no generator calls, no pictures, no desktop control, no Play runs of mine. Six upload calls (his go), all accepted first time. Primary's context about 47% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **A Play look at the four emotes from their uploads** (above). All six ids load in Edit with their files' key counts, and Next One's dry run on the upload matches the draft; this only confirms it in Play.
2. Then, each on his word: the spotlight's switch sound and the emotes' sounds (clap, snore and pop, paper); **a plan in words for who gets which emote** (one free, the rest sold: a new mechanic, his OK before any code; until then everything stays behind the Dev buttons); the body sweep on extreme avatars; Toy Pilot; `emote-making.md` into a skill; remove `winner_hop_animation`.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit-mode pictures too), bot matches, every upload and every generator call (a failed call counts), any new mechanic or number.
- Stop rule: Good Game, Nap, Next One, Camera Flick, the framing and the lighting are approved; do not rework them unless Alan names a fault.

## DECISIONS & WHY (this session)
- **Next One's plane is 1 stud long, not a forearm and hand** (told to Alan; he approved what he saw). An avatar's arm reaches about a quarter of its height and the shoulders are half a height apart: the left hand could not reach across a bigger sheet. The sheet lies across the body, nose to the kid's left.
- **Four runs of the hand, one change each** (his words after the first look): flat, in half, the nose, the wings, then the pick-up. The crease runs are gone. Two quarter-stud hops remain before runs 3 and 4 (both folds start on the far side); he did not object.
- **The raise is typed in** (two solved poses), the kind of move he found stiff in the first clap; he passed it. Next One B's raise was not used (it stops at chest height).
- **A draft clip in `Assets` wins over the uploaded id, Studio only**: a cut can be worked on without an upload. A changed cut needs a new upload and id.
- **Uploaded clips lose their attributes**, so Camera Flick's release and grip and Next One's raise times are in the config (`rounds.camera_flick_release`, `camera_flick_grip`, `next_one`).
- **The emotes stay behind the Dev buttons**: turning them on for players is the ownership mechanic, not part of the upload.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above.

## CARRY NOTES / GOTCHAS
- **On a short, wide body the left arm runs out once in Next One** (0.105 studs short at the wings' start; a flap's tip 0.04 into the head's box). Edit test bodies understate; the body sweep decides.
- Not checked: whether the left hand hides the paper on blocky hands (he did not mention it); Next One on a phone.
- **Edit dry runs:** the first run after a bake poses nobody (run twice); a part does not move when a joint's turn is written (read `rig`'s `at`); `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua --run=FILE.lua` runs a Luau file and prints numbers, no pictures. The dry-run harness itself was a scratch file and is gone: the recipe is on the emote-making page.
- Bash heredocs with an apostrophe in them fail to parse here (hit three times): write scripts and commit messages with the Write tool.
- Scripted winners' moment for a Play run of mine (his go): previous handoff, same lane (`handoff-2026-11-20-1900-beta-lane-nap-approved.md`, carry notes).
- From before, still true: judge only the first winners' moment after joining; untracked `tools/art/hero.py.old` is not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`a654d4cd` six clips uploaded, ids and moments in the config, scene plays from them · `b4bb708f` Next One approved · `d46aef32` four runs of the hand after his first look · `7adfbabf` Next One built (paper as ten hinged pieces, `--run` for number checks, cuts marked `once`).
Queued, not started: the sounds; who gets which emote; class reaction (paper balls); round length against the shorter scene; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Next One from build to approval (what it does, the numbers, the dry-run traps, how to re-bake); the six uploads (ids, how, drafts win in Studio).
- `docs/workshop/lessons.md`: an avatar's two hands only meet close to the chest; a hand move that changes nothing reads as fiddling.
- `docs/systems/modes-and-scoring.md`: Next One as approved; the uploads.
- `docs/decisions/2026-11-20-runner-up-emotes.md`: his rulings on Next One and the upload go.
- `docs/playtests/2026-11-20-phone-framing-and-good-game.md`: Next One's two looks.
- `docs/workshop/tools.md`, `state/STATE.md`, `config/gameplay.json` (the comment). Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`ourClip`, `flickClip`, `goodGame`, `nap`, `nextOne`, `bendArm`, `rig`, `sit`). Dev button: `src/client/FlightHUD.luau` ("RunnerUp").
- Cuts and baking: `tools/emote_clips.lua` (`CUTS`), `tools/emote_preview.py`. Uploading: `tools/upload_texture.py --animation`.
- Clips and Roblox's answers: `assets/animations/emotes/`, `assets/animations/emotes/uploads/`. Ids: `rounds.emote_clips` in `config/gameplay.json` (then `python tools/generate_config.py`).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md` (the emote list, "one free emote in each slot; the rest are sold").
