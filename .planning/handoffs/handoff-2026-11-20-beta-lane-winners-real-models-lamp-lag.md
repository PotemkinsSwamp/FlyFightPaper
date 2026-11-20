# HANDOFF — 2026-11-20 — Winners are real models now and sharp; their own lamps light up late; Camera Flick is built behind a Dev button

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, tools/emote_preview.lua, assets/animations/emotes, docs/workshop, docs/systems/modes-and-scoring.md
**Time:** 2026-11-20 02:40 -05:00

★ START HERE: make each winner light up at their own spotlight's moment. In `src/client/WinnersCutscene.luau` the three winners' SpotLights all take effect together about 3.5 s after the camera arrives (3rd 3 s late, 2nd 2 s, 1st 1 s). Done when a muted Play run (Dev: hangar, F8, "end: flick") shows each kid going from a black shape to lit within a blink of their shaft and name plate, on 3rd, 2nd and 1st, and Alan has looked. Play needs his go.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/lessons.md` ("Lighting one thing in a dark room") and `docs/workshop/emote-making.md` (the try-by-try log) only for the step in hand. Memories: no-video-of-alan, studio-not-drawing, mute-studio-tests, alan-does-play-checks, plan-before-building-features, visual-qa-before-showing.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `1e0e7d7b`. Pushed (the commit hook copies to GitHub and prints "github: pushed"; `git push` itself has no upstream). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run this session (no rules logic changed; the work is client scene and tools). Docs: `python tools/check_docs.py` OK.
- Studio: place "FlyFightPaper(First Fold)" open in Edit, DevMute off. The place holds `Assets.WinnerBooks` and `Assets.CameraFlickClip` (also in `default.project.json`). **Whether the place is saved is unknown**: Studio closed mid-test when C: hit 0 bytes free, and both were still there on reopen. Studio's id changes on every reopen: `list_roblox_studios`.
- Disk: C: had 9 GB free after Alan cleared space; D: 24 GB. Captures and frames go to D: (`D:/Temp/ffp-run`), never the C: temp folder.
- Cost last session: one very long session (primary's context about 62% of the window at handoff, after one earlier compaction). Agents this window: one Sonnet picture reviewer (about 109k tokens for one image: too dear for what it found), one web-fetch (19k). Eleven muted Play runs earlier, one today.

## NEXT ACTION + PLAN
1. **The lamp lag** (above). What was seen: `.planning/emotes/winners-real-models-first-run.jpg`. Two untested ideas, both in lessons.md: keep the lamps on from the start and hide each winner under a solid black Highlight until their click; darken the room without touching its 307 lamps. Brightness of the lit winners is untuned (`LAMP_BRIGHT`).
2. **Alan's look** at the whole moment with "end: flick": the lighting, and the grip-point hold up close (nobody has seen it in Play; measured only).
3. Then, each on his word: the spotlight switch sound and the flick's sounds (three licensed candidates each); the upload of `assets/animations/emotes/camera-flick.rbxm` (his go), its id into config, the clip and the Studio-only branch out of the game; the body sweep on extreme avatars.
4. After Camera Flick is approved: Toy Pilot, Good Game, Next One, Nap; then turn `docs/workshop/emote-making.md` into a skill. Remove `winner_hop_animation` (config and `tools/winner_hop_animation.luau`) once he approves the new scene.
- HOLDS (his explicit go, each): any Studio Play, place saves, publish, desktop control or screen grabs, bot matches, every upload, any new mechanic or number. The harness refuses `start_stop_play` unless his latest message says so in words.

## DECISIONS & WHY (this session)
- **Winners are small real models in front of the camera**, each slid by `(camera - spot) * (1 - 1 / scale)` every frame. Layers (ViewportFrames) are capped at about 1024 px and looked pixelated; big models can't be lit (lights reach 60 studs).
- **The plane is fixed to `RightGripAttachment` with one grip for all avatars**; the bake turns the wrist to aim it. Offsets tuned on the blocky test kid floated on a thin-armed avatar. The hand part's own axes differ per avatar; the grip point's direction does not.
- **The right arm and head in the admire are posed by numbers**, not generated: Alan directed an exact slow move; the generator could not be steered to it. The rest of the body is generated clip A, almost still.
- **The throw is two poses from the old "dart" clip, upper body only**; legs stay planted (the clip steps; the kid stands on books).
- **Studio plays the clip with no upload** (`RegisterKeyframeSequence` on `Assets.CameraFlickClip`, only when the Dev button asked). The real game needs one upload.
- **With Camera Flick the scene leaves early** (about 13.6 s, not 17 s); the report card is up about 13 s. Alan has not ruled on that.
- All of Alan's choices: `docs/decisions/2026-11-20-camera-flick-and-real-winners.md`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. New this session: **no-video-of-alan** (never propose filming or photographing him; use numbered stills of the real model).

## CARRY NOTES / GOTCHAS
- `state.stage` in `WinnersCutscene` is the stage NAME (a string); the winners' folder is `state.set`. Mixing them crashed the scene every frame.
- An avatar must be in the game before `LoadAnimation`; the winner's model is parented first.
- A crash inside `Cutscene.stop` leaves the room dark: the clean-up has no guard.
- Screen asleep = Studio draws blank frames. The keep-awake mouse nudge is refused by the harness (PowerShell); Alan has to keep the screen on, or allow it in his Claude settings.
- `tools/emote_preview.py` leaves its frame folders in the C: temp folder; 12 of them filled the disk. Delete them after each look.
- The preview tool's close camera sits below the hand; the game's camera is far and above. The preview shows the body and the hold, not the scene.
- `_G.EMOTE_BODY = <user id>` stands that user's avatar in the preview; clear it before baking (the clip is baked on the blocky body).
- Six private animation uploads sit on Alan's account from the generator (ids in emote-making.md).
- Untracked `tools/art/hero.py.old` is someone else's backup: never `git add -A tools`.

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first; all on `main`):
`1e0e7d7b` first Play run notes · `e47c2ee4` fix name clash and load order · `2a096fb6` winners as real models · `1dc70a7c` pixelation lesson · `b474ee0e` grip-point hold · `212cf8cd` log: floating plane · `697af376` plane rests on the hand · `e678699f` arm to Alan's order · `ce3a748b` log: arm pose · `838721b6` slow turn-over · `7df1c82e` plane fixed in hand, push throw · `f2f3d382` admire before the throw · `ac86c15b` log: too soon · `b3b040ac` untrack stray file · `308de81d` confetti out, Camera Flick behind Dev button · `ccb1e7fc` podium steps · `260b5ff9` book podiums, no zoom · `a84938b0` darker room · `c5a63ed8` lighting lessons · `ab71766e` winners in lit layers · `7ab6f0b0` restaged moment · `3c0c021d` preview faces camera · `1f359e5f` preview videos from Edit · `e54748c0` versions B and C · `f5e8d092` version A · `442b6708` shot card · `a4276620` `227eacb2` `782d2745` `0a6708e3` `cf8504f9` winners plan · `c48ebe63` decision: winners redo · `23e0a4cd` plane emote ideas · `6cbb8c02` `c5f908fc` `f24facd4` guns under big skins (done, Alan: "looks good").
Queued, not started: class reaction (paper balls); round length 27 s against the shorter scene; windows' brightness in the dark; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/systems/modes-and-scoring.md`: the winners' moment as it stands (real models, lamp fault, Camera Flick's timings).
- `docs/workshop/emote-making.md`: the full Camera Flick log (admire versions, joining clips, grip, numbered stills, grip point).
- `docs/workshop/lessons.md`: layers are pixelated; the real-model method; the lamp lag as seen.
- `docs/decisions/2026-11-20-camera-flick-and-real-winners.md` and `docs/playtests/2026-11-20-camera-flick-and-winners-staging.md`: new, listed in their READMEs.
- `docs/plan/WINNERS-CIRCLE-PLAN.md` status line; `state/STATE.md` (59 lines). Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` ("The winners in the dark", `flickPlane`, `standWinners`). Dev button: `src/client/FlightHUD.luau` ("EndFlick").
- Clip recipe and bake: `tools/emote_preview.lua` (`_G.EMOTE.bake`, `_G.EMOTE.try`), run by `tools/emote_preview.py`.
- Pictures: `.planning/emotes/` (first-run sheet, pose choices, preview video).
