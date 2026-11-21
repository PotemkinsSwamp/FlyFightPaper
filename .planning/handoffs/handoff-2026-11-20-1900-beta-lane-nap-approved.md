# HANDOFF — 2026-11-20 — Nap approved (seated, head down, arm fixed); Next One's plan approved, not built

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, tools/emote_clips.lua, assets/animations/emotes, docs/workshop/emote-making.md, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, docs/decisions, docs/playtests
**Time:** 2026-11-20 19:00 -05:00

★ START HERE: Nap, the second runner-up emote, is approved by Alan in Play ("I think that's good. I think we move on", then on the arm fix "arms look fine now"). Next One's plan is approved in words ("yes, build it"; "leave the sighting out"). Opening action: build Next One to that plan (emote-making page, "Next One: what is left"). Done when Alan has looked at it in Play and said yes or what to change. Nothing of Next One is built.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Nap: approved by Alan in Play" down (what Nap taught, the approved Next One plan). Memories: emotes-show-feeling-in-movement, alan-does-play-checks, plan-before-building-features, explain-plans-in-text, look-before-explaining, playtest-notes-before-handoff.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `d1b1bc21`. Pushed (the commit hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (client scene work and tools only). Docs: `python tools/check_docs.py` OK.
- Studio: place "FlyFightPaper(First Fold)", in Edit, camera Fixed, `DevMute` cleared. **Nothing saved by me.** Rojo serving: Studio's `WinnersCutscene` and `FlightHUD` matched the files at the last check.
- **Unsaved in the open place:** `Assets.NapSleepClip`, `NapWakeClip`, `GoodGameStanceClip`, `GoodGameWaveClip`, `CameraFlickClip`. If the place was closed without a save, bake them again (commands on the emote-making page; all are also files in `assets/animations/emotes/`).
- Seen by Alan in Play: Nap three times (first look, after the seat and head fixes, after the arm fix). Seen by Claude: numbers only.
- Cost this session: no agents, no generator calls, no uploads, no screen grabs, no desktop control except a one-pixel mouse nudge during my Play. One Play run of mine on his go (muted, about 4 minutes, four winners' moments). Primary's context about 43% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Build Next One** to the approved plan: the feeling is "already over it and planning the rematch"; head down on the work, three brisk folds in about 5 s (in half, the nose, the wings) with the paper really folding as hinged pieces, the left hand riding the flap, then the plane (about a forearm long) held up at eye level and slowly turned; body from generated clip Next One A, no generator call; no sighting along the plane. Check: Alan's Play look (Dev: hangar, F8, "2nd/3rd" stepped to it, "end: flick").
2. Then, each on his word: uploads of the final clips (Camera Flick, Good Game's two, Nap's two, Next One's), ids into config, the Studio-only branches out; the switch sound and the emotes' sounds (clap, snore and pop, paper); the body sweep on extreme avatars; Toy Pilot; `emote-making.md` into a skill; remove `winner_hop_animation`.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit-mode pictures too), bot matches, every upload and every generator call (a failed call counts), any new mechanic or number.
- Stop rule: Good Game, Nap, the framing and the lighting are approved; do not rework them unless Alan names a fault. For a body move, no reviewer pass on stills before his Play look.

## DECISIONS & WHY (this session)
- **Nap is Alan's own version**, not the shot card's: cross-legged, right elbow on the thigh, the head hanging 70 degrees down and held by the brow on the hand, a snore bubble at the mouth and paper Z's from the head; at 1st's light a jolt (the bubble pops), looks right, left, right, forward, and a sink back onto the hand. His reason for the head: a face that shows reads as awake, and we cannot close the eyes.
- **His other ending (arm falls, then head) is not built**, on my advice: it needs a second sleeping pose and more time than runner-ups get beside Camera Flick.
- **The look-around is Roblox's own**, cut from its standing idle's head and chest turns, so it is not typed-in motion (what he found stiff in the first clap).
- **Every sitting kid is moved each frame onto the top book** (`sit`): a clip drops every body's hips the same distance, so long legs floated and short ones sank. He saw the floating; in Play the lowest point then measured 0.000 over the book.
- **No IKControl in Nap.** Measured in Play it flipped one body's arm up to 178 degrees a frame while awake and left the hand up to 0.75 studs off the head asleep. `bendArm` bends the arm ourselves after the animation: 0.00 studs off on four avatars. Good Game's clap still uses IKControl and is approved: left alone.
- **The nod comes 5 s after dozing off, then every 8 s** (the loop is two 4 s breaths), not every 5 as first told; the wake-up is 5.1 s. Told to him.
- **Next One: the paper does the acting.** The generator cannot do hand work and typed-in hand moves read stiff, so the hand's path comes from the fold's own arc.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. Updated this session: alan-does-play-checks (joint work on bodies is a number: measure it in Play on real avatars, on his go, before his look).

## CARRY NOTES / GOTCHAS
- **Edit test bodies understate misses on real avatars** (0.04 to 0.12 studs against 0.5 to 0.7 in Play). Next One's hands on the paper will need the same care: `bendArm` and `rig` are ready to reuse; `sit` seats any sitting emote.
- A scripted winners' moment without clicking (in my own Play, on his go): Client `Root.RoundAction:FireServer("join")`, set `DevRunnerUp` on `ReplicatedStorage.FlyFightPaper`, `FireServer("endMatch")`; winners at `workspace.WinnerStage.Winner<place>Stage.Cast.Winner<place>`. Set `workspace:SetAttribute("DevMute", true)` in Edit first and clear it after; the mouse nudge keeps the screen drawing.
- `RunService.PreSimulation` does not fire in Edit: a dry run of scene code there needs a stand-in signal called by hand after `Animator:StepAnimations`. IKControl does nothing in Edit either.
- After a bake, Studio's assistant puts the camera type back when a command ends: set it to Fixed from `task.delay(1, ...)`.
- Roblox's own clips have keys in between whose poses have Weight 0; `tools/emote_clips.lua` now skips them.
- A bash heredoc followed by a commit message with apostrophes failed to parse here: put doc-edit scripts and commit messages in scratchpad files.
- Not checked: whether crossed shins look sunk on blocky avatars now that the lowest point rests on the book (thighs sit 0 to 0.25 studs over it); the props' look on phone sizes.
- From before, still true: judge only the first winners' moment after joining; untracked `tools/art/hero.py.old` is not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`d1b1bc21` Nap's arm fix passed by Alan; Next One: no sighting · `922acf04` arm glitch measured in Play, IKControl out, `bendArm` in; Next One's plan approved · `6b8f1536` Nap approved, arm glitch noted · `3d8f6c0a` every body rests on its books, head hangs face-down on the hand · `ebda3259` Nap, Alan's own version, first build.
Queued, not started: Next One; the uploads and sounds; class reaction (paper balls); round length against the shorter scene; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Nap from first build to approval (his words at each look, the numbers, the glitch measurement, how to re-bake, how to script a winners' moment); Next One's approved plan.
- `docs/workshop/lessons.md`: a sitting clip does not sit every body; a sleeping kid hides the face; IKControl is not safe for a hand on a moving body, and Edit test bodies understate.
- `docs/systems/modes-and-scoring.md`: Nap as it stands, approved.
- `docs/decisions/2026-11-20-runner-up-emotes.md`: Nap's version and his rulings; Next One's plan, no sighting.
- `docs/playtests/2026-11-20-phone-framing-and-good-game.md`: Nap's three looks.
- `state/STATE.md`. Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`nap`, `sit`, `rig`, `bendArm`, `paper`; `copyWinner` picks the emote). Dev button: `src/client/FlightHUD.luau` ("RunnerUp").
- Cuts and baking: `tools/emote_clips.lua` (`CUTS.NapSleep`, `CUTS.NapWake`, `reach`, `propped`), `tools/emote_preview.py`.
- Clips: `assets/animations/emotes/nap-sleep.rbxm`, `nap-wake.rbxm`. Next One's raw body move: `rbxassetid://98981684256935` (first 3.5 s).
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
