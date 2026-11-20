# HANDOFF — 2026-11-20 — Winners' shot fits every screen (approved); first Good Game rejected as stiff and too fast

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, tools/emote_clips.lua, tools/emote_preview.py, assets/animations/emotes, docs/workshop/emote-making.md, docs/systems/modes-and-scoring.md, docs/decisions, docs/playtests
**Time:** 2026-11-20 16:00 -05:00

★ START HERE: the winners' shot now fits every screen (Alan: "ok its good") and Camera Flick's animation is approved. The first runner-up emote, Good Game, was built with arms posed by numbers and Alan rejected it in Play: "it looks stiff and the movements are too fast making it look unnatural". Next: tell him in words how Good Game will be remade so it moves naturally (a real motion source with the whole body in it, a calmer tempo) and get his OK. Done when he has said yes or what to change.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Runner-up emotes: shot cards" down (the shot cards, the nine raw clips, what was tried). Memories: plan-before-building-features, alan-does-play-checks, explain-plans-in-text, no-video-of-alan, studio-not-drawing, mute-studio-tests, look-before-explaining.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `527c3a81`. Pushed (the commit hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (client scene work and tools only). Docs: `python tools/check_docs.py` OK.
- Studio: place "FlyFightPaper(First Fold)" in Edit, DevMute off, the simulator's Play device last set to iPhone 17 Pro, nothing of mine in the workspace, **nothing saved by me**. Rojo serving: Studio's `WinnersCutscene` and `FlightHUD` matched the files at the last check. `Assets.GoodGameClip` sits in the open place (unsaved), next to `CameraFlickClip`.
- Seen by Claude in muted Play: the framing on iPhone 17 Pro, HD 1080 and Alan's pane. Seen by Alan: the same ("ok its good"); Good Game on 2nd and 3rd (rejected).
- Cost this session: two reviewer agents on Good Game's stills (110,000 and 119,000 tokens); four muted Play starts of mine (ten winners' moments); desktop control of Studio once (device switching, his ask); about fifteen Edit-mode render runs; nine generator uploads (private, free) plus one failed try. Primary's context about 48% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Good Game, remade** (above). Check: his OK on the plan in words; then build it; then his Play look (Dev: hangar, F8, tap "2nd/3rd" to "GoodGame", then "end: flick").
2. Then Nap, then Next One, each: build, his Play look. Their shot cards and chosen raw clips are on the emote-making page ("Nap and Next One: what is left"). Alan's three rulings stand: already in the starting pose in the dark; sitting cross-legged on the stack; Nap startles awake when 1st's light clicks on.
3. Then, each on his word: the spotlight switch sound and the emotes' sounds; the uploads of the final clips, ids into config, clips and Studio-only branches out of the game; the body sweep on extreme avatars; Toy Pilot; `docs/workshop/emote-making.md` into a skill; remove `winner_hop_animation`.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit-mode pictures too; this session's go was for this session), bot matches, every upload and every generator try (each one uploads), any new mechanic or number.
- Stop rule: the framing and the lighting are approved; do not rework them unless Alan names a fault. For a body move, no reviewer pass on stills before his Play look (it cost 230,000 tokens and missed what he saw at once).

## DECISIONS & WHY (this session)
- **The winners' camera fits the screen both ways** (`SIDE_ROOM` 1.25 winner heights across, `FRAME_TALL` 3.45 up and down, the tighter one wins), measured on the whole screen, a phone's notch strips included (an empty ScreenGui with `ScreenInsets = None`; `Camera.ViewportSize` leaves the strips out). On Alan's own Studio pane this gives exactly the view he approved before.
- **Outside name plates slide in** to stay whole on a phone (a default ScreenGui cannot draw in the notch strips).
- **Ordinary 16:9 screens also came closer.** His Studio pane is 2.55 times wider than tall, so the old width-only rule was never seen on a normal screen. He has seen and passed the result.
- **Good Game was posed by numbers, against the plan's own rule,** because the generator's claps read as crossed arms and its wave as an arm held out. Alan's verdict says the rule was right. The tool and the scene hookup stay; the cut's content is what gets replaced.
- **A cut may leave parts alone** (poses with weight 0 in the baked clip), so whatever plays underneath shows. Kept: useful for any emote that only moves part of the body.
- Alan's rulings in his words: `docs/decisions/2026-11-20-runner-up-emotes.md`; playtest: `docs/playtests/2026-11-20-phone-framing-and-good-game.md`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. New memory this session: look-before-explaining.

## CARRY NOTES / GOTCHAS
- **The generator gives postures, not handwork.** Sitting and a nodding head it does well; folding, waving and small claps it does not. Ids and findings for all nine clips are in the emote-making table; the raw clips load by id, no files kept.
- Each generator try names its clip from the first 20 letters of the wording: start each wording differently.
- `tools/emote_clips.lua` leaves Studio's camera Scriptable if a render ran with `--keep` and the tool was then cleaned by a reload: set `CameraType` to Fixed after a short wait and check it.
- Desktop control: ask for `robloxstudiobeta.exe` by name; the first screenshot minimises Alan's other windows and Studio itself (restore Studio with `ShowWindow`). Switching device works in the middle of a Play; a code change needs a new Play.
- Left alone on phones by Alan's word (the zoom was the only problem): the big Menu button over 2nd's light, name plates about 10 points tall, the report card covering the Menu button and hangar papers. An outside winner's stretched-out arm can reach the phone's camera island.
- Not done on Good Game: turning towards 1st for the claps; the sound.
- From before, still true: judge only the first winners' moment after joining; `CreateMeshPartAsync` on a live server is unproven (the scene then plays with the disc and no cone); untracked `tools/art/hero.py.old` is not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`527c3a81` Good Game: claps lower and wider, compact wave · `46db4240` Good Game built behind a Dev button, nine raw moves logged, clip tool · `56da37c1` framing approved, runner-up shot cards · `5bc910c9` winners' shot scales to the screen · `785f4b39` Dev panel line break · `7a301900` fitted to the whole screen, zoom button removed · `d6f1c2c3` Dev zoom button (removed again in `7a301900`) · `fa674595` notes corrected after looking · `268bca1b` first phone fix (replaced in `5bc910c9`).
Queued, not started: the sounds; class reaction (paper balls); round length 27 s against the shorter scene; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/systems/modes-and-scoring.md`: the camera rule as it stands; Good Game's state.
- `docs/workshop/emote-making.md`: runner-up shot cards, the nine raw clips, Good Game's two cuts and Alan's verdict, what is left for Nap and Next One.
- `docs/workshop/lessons.md`: fitting a camera shot to the screen; Alan's "laptop" view is Studio's pane.
- `docs/workshop/tools.md`: `tools/emote_clips.lua`.
- New: `docs/decisions/2026-11-20-runner-up-emotes.md`, `docs/playtests/2026-11-20-phone-framing-and-good-game.md`, listed in their READMEs.
- `state/STATE.md`. Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`SIDE_ROOM`, `FRAME_TALL`, `wholeScreen`, `runnerUpClip`). Dev buttons: `src/client/FlightHUD.luau` ("EndFlick", "RunnerUp").
- Emote tools: `tools/emote_clips.lua` (`CUTS`, `E.bake`), `tools/emote_preview.py` (`--lua=`, `--bake=`), `tools/emote_check.lua`.
- Pictures and video: `.planning/emotes/` (`winners-phone-shot.jpg`, `winners-hd1080-shot.jpg`, `winners-laptop-shot.jpg`, `good-game-cut.mp4`, `good-game-cut-sheet.jpg`).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
