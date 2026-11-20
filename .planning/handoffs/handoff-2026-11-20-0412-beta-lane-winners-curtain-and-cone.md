# HANDOFF — 2026-11-20 — Winners' lighting done Alan's way (curtain, black covers, cone for show); he says "it's good now"

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, docs/systems/modes-and-scoring.md, docs/workshop/lessons.md, docs/decisions, docs/playtests
**Time:** 2026-11-20 04:12 -05:00

★ START HERE: the winners' moment now lights each winner at their own click and Alan has passed the look and the framing. Next is his verdict on the plane in 1st's hand up close (the grip-point hold), which nobody has judged yet: ask him to run Dev: hangar, F8, "end: flick" and say yes or what is wrong. Done when he has said it. Two things from this session are also still unconfirmed and can be checked in that same run (below).

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/lessons.md` ("Lighting one thing in a dark room") only if the scene's lighting is touched again. Memories: alan-does-play-checks, studio-not-drawing, mute-studio-tests, plan-before-building-features, no-video-of-alan.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `2d89ba69`. Pushed (the commit hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (client scene work only, no rules logic). Docs: `python tools/check_docs.py` OK (214 pages).
- Studio: place "FlyFightPaper(First Fold)" in Edit, DevMute off, nothing of mine left in the workspace, **nothing saved by me**. Rojo is serving: the Studio copy of `WinnersCutscene` matched the file at every check.
- Seen by Claude in its own muted runs: the curtain, black covers and the cone around the winner (commit `1d5a5f64`). **Seen only by Alan** (he ran them himself): the cone behind the winner, winners mid-desk and in place before the glide, the desk-sized pool, the further-back camera.
- Cost this session: no agents. Five muted Play starts of mine (one held two winners' moments), three Edit-mode pictures, about ten screen recordings to `D:/Temp/ffp-run/run13..16` (small JPG frames; safe to delete). Primary's context about 47% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Alan's look at the grip-point hold** (above). In the same run, check: (a) a tall avatar (the bear-headed one stood about 1.5 times taller than the others) gets a wider cone and reads as "in" it; (b) no coloured outline on 1st's plane when 1st's real plane had one (it happens when 1st is another flying plane).
2. Then, each on his word: the spotlight switch sound and the flick's sounds (three licensed candidates each, links + a Dev button to cycle them); the upload of `assets/animations/emotes/camera-flick.rbxm`, its id into config, the clip and the Studio-only branch out of the game; the body sweep on extreme avatars.
3. After Camera Flick is approved: Toy Pilot, Good Game, Next One, Nap; then turn `docs/workshop/emote-making.md` into a skill. Remove `winner_hop_animation` (config and `tools/winner_hop_animation.luau`) once he approves the scene as a whole.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit-mode pictures too), bot matches, every upload, any new mechanic or number.
- Stop rule: the lighting is approved. Do not rework it unless Alan names a fault; a number he asks for (darker, closer, wider) is a one-line change, no new method.

## DECISIONS & WHY (this session)
- **No real lights on the winners.** Three tries with real SpotLights (as built, brighter, a `Camera.Focus` fix) all came on late in the first winners' moment after joining, and pulsed. Alan's idea replaced them: fake the spotlight, light the models by other means.
- **The dark is a curtain** (a black SurfaceGui frame on an unseen part, 0.15 of the room showing), at the lens during the dim and glide, 60 studs away during the hold. The room's lighting, its 307 lamps and the haze are no longer touched.
- **"Unlit" is a solid black Highlight** on each winner's `Cast` model (avatar, books, plane); the click takes it off. Winners are never faded in (half see-through, the cover leaked a lit flash); they are there, solid, from just before the camera sets off.
- **The spotlight stands behind its winner**: the same scene scaled 1.8 times less about the camera (`LIGHT_BACK`), so it lands on the same pixels with no haze over the kid. This looks odd in code; it is deliberate.
- **The cone is 24 nested faint Neon cones** of Roblox's classic cone mesh (asset 1033714), loaded on the client with `AssetService:CreateMeshPartAsync`. Alan picked the strength ("A") from an Edit-mode picture of three.
- **The pool is a plain Neon disc sized to the desk's depth.** A pool drawn on a copy of the desk top (to clip it) landed in the wrong place; dropped.
- **Winners stand mid-desk** (`FIRST_FORWARD, SIDE_FORWARD = 0.06, 0`); camera room beside the outside two is 1.7 heights (`SIDE_ROOM`).
- All of Alan's choices in his words: `docs/decisions/2026-11-20-winners-curtain-and-cone.md`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Nothing new this session.

## CARRY NOTES / GOTCHAS
- **Judge only the FIRST winners' moment after joining.** A second one in the same Play was in sync when the first was not; I reported a fix from it and was wrong.
- A fresh Play starts on the menu with no pilots. From the Client: `Root.RoundAction:FireServer("join")`, wait for the plane's State "DESK" and 12 models with `PilotId`, then `Root:SetAttribute("DevCameraFlick", true)` and `FireServer("endMatch")`.
- Screen recording: Chrome sat in front of Studio and the desktop is two screens. Bring Studio forward (`WScript.Shell.AppActivate`) and record only the main screen (`ffmpeg -f gdigrab -offset_x 0 -offset_y 0 -video_size 2560x1080`). Brighten dark frames before calling them clean (`eq=gamma=3.5`).
- The keep-awake mouse nudge (background PowerShell) was NOT refused this session; it worked every time.
- `CreateMeshPartAsync` on the client is proven in a running Studio game only. On a live server it is unproven; if it fails there the scene plays with the disc and no cone (a warning is printed).
- The taller-avatar cone measures the avatar when it is copied; if Roblox reports the sitting pose then, the cone stays normal width.
- Black shapes during the glide are drawn in front of everything; one may show over something it should be behind.
- The comment on `CURTAIN_CLEAR` is current; Alan has seen 0.15 and did not ask for a change.
- From before, still true: `state.stage` is the stage NAME; a crash inside `Cutscene.stop` leaves the scene's parts behind (no guard); untracked `tools/art/hero.py.old` is not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`2d89ba69` camera further back · `4c74377a` mid-desk, in place before the glide, disc fits the desk, wider cone for tall avatars · `37d8e2e5` spotlight behind the winner, outline fix (its clipped pool was replaced in `4c74377a`) · `5611b6bf` notes · `1d5a5f64` cone spotlight · `fe8643d2` solid black shapes · `5b3a823c` curtain works, 0.15 · `5dd14e2c` curtain and black covers · `a96a4718` lamps brighter, no shadows (never run; replaced) · `564837d3` notes (the wrong "fixed") · `024ffa7f` Camera.Focus (removed again in `5dd14e2c`).
Queued, not started: class reaction (paper balls); round length 27 s against the shorter scene (with Camera Flick it leaves at about 13.6 s); the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/systems/modes-and-scoring.md`: the winners' moment rewritten to how it stands (curtain, covers, cone behind, mid-desk, camera).
- `docs/workshop/lessons.md` ("Lighting one thing in a dark room"): the lamp tries and why they failed; the further-away trick; SurfaceGui top-face guess; cloned outline; first-moment and brighten-the-frames rules.
- New: `docs/decisions/2026-11-20-winners-curtain-and-cone.md`, `docs/playtests/2026-11-20-winners-curtain-and-cone.md`, listed in their READMEs; the earlier decision note's status line points to the new one.
- `state/STATE.md` (59 lines). Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (constants and their reasons at the top; `makeSpotlight`, `shine`, `standWinners`, the render step). Dev button: `src/client/FlightHUD.luau` ("EndFlick").
- Pictures: `.planning/emotes/` (`winners-cone-options.jpg` Alan's pick, `winners-cone-first-run.jpg`, `winners-curtain-first-run.jpg`).
- Emote recipe and log: `docs/workshop/emote-making.md`; plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
