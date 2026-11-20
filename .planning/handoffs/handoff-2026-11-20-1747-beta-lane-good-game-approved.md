# HANDOFF — 2026-11-20 — Good Game approved (slow clap, stance, wave); Nap is next

**Labels:** kind=product · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/FlightHUD.luau, tools/emote_clips.lua, assets/animations/emotes, docs/workshop/emote-making.md, docs/workshop/lessons.md, docs/systems/modes-and-scoring.md, docs/decisions, docs/playtests
**Time:** 2026-11-20 17:47 -05:00

★ START HERE: Good Game, the first runner-up emote, is approved by Alan in Play ("the slow clap is good now", "the stance is good", "the wave is fine"). He wants Nap next. Opening action: tell him in words how Nap will be made, naming the napper's feeling first (his rule: feelings must show in the movement, the face can't), and get his OK. Done when he has said yes or what to change. Nothing of Nap is built.

> Read on demand: AGENTS.md → `state/STATE.md` → this file; then `docs/workshop/emote-making.md` from "Runner-up emotes: shot cards" down (Nap's card, the Nap clips already generated, and everything learned making Good Game). Memories: emotes-show-feeling-in-movement, plan-before-building-features, alan-does-play-checks, explain-plans-in-text, no-video-of-alan, look-before-explaining.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `f74a5878`. Pushed (the commit hook prints "github: pushed"). Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: not run (client scene work and tools only). Docs: `python tools/check_docs.py` OK.
- Studio: place "FlyFightPaper(First Fold)", last seen in Edit; Alan starts and stops Play himself. **Nothing saved by me.** Rojo serving: Studio's `WinnersCutscene` and `FlightHUD` matched the files at the last check.
- **Unsaved in the open place:** `Assets.GoodGameStanceClip`, `Assets.GoodGameWaveClip` (and `CameraFlickClip` from before). If the place was closed without a save, Good Game plays its clap only: bake the two clips again (commands on the emote-making page, "If the place is closed without a save").
- Seen by Alan in Play: every step of Good Game. Seen by Claude: nothing in Play (no Play runs of mine); numbers in Edit only.
- Cost this session: no agents. Six generator uploads (private, free) plus one failed call and one refused call. No Play starts of mine, no desktop control, no screen grabs. One read-only measurement inside Alan's running Play. Two YouTube videos read in Chrome (not downloaded). Primary's context about 45% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **Nap, in words, for his OK** (above). What stands already (his rulings, `docs/decisions/2026-11-20-runner-up-emotes.md`): sitting cross-legged on the stack; already asleep in the dark; startles awake when 1st's light clicks on, then dozes off again; three paper Z's from the head. Raw clip chosen last session: Nap B (`rbxassetid://103826141789730`). Check: his yes.
2. Build Nap; his Play look (Dev: hangar, F8, "2nd/3rd" steps to the emote, then "end: flick").
3. Next One, the same way.
4. Then, each on his word: the uploads of the final clips (Camera Flick, Good Game's stance and wave, Nap, Next One), ids into config, Studio-only branches out; the switch sound and the emotes' sounds; the body sweep on extreme avatars; Toy Pilot; `emote-making.md` into a skill; remove `winner_hop_animation`.
- HOLDS (his explicit go, each): any Studio Play (tests included), place saves, publish (he does it), desktop control or screen grabs (Edit-mode pictures too), bot matches, every upload and every generator call (each call uploads; a failed call counts against a number he allowed), any new mechanic or number.
- Stop rule: Good Game, the framing and the lighting are approved; do not rework them unless Alan names a fault. For a body move, no reviewer pass on stills before his Play look.

## DECISIONS & WHY (this session)
- **Good Game as approved** (all in `WinnersCutscene`, `GOOD_GAME`): Roblox's Applaud at half speed for three claps (a clap a second, one smooth rhythm); the left hand pulled onto the right at each clap by Roblox's IKControl (`clapHands`); a 0.7 s blend; our wave clip at 0.75 speed (low V, elbow down, five sways 0.8 s apart); stand 2 s; our stance clip (hips and legs only) one priority higher the whole time. No nod.
- **Why Roblox's clap and not a clip of ours:** the generator gives postures, not hand work; a typed-in clap was what he first rejected.
- **The wave and the stance are cuts from generated clips with small changes by numbers** (arm turned out 30 degrees, sway made 2.5 times bigger, one sway repeated five times). Constants applied to generated motion, not typed-in poses; he passed the result.
- **The round is about 13 s, longer than the 8 to 9 s runner-ups have beside Camera Flick.** I raised it; he said the wave is fine and moved on. Left as it is.
- **The Fortnite Slow Clap videos were a timing reference only**, and he then called even that too fast. Its animation is Epic's: never capture or copy it.
- His words for every step: `docs/playtests/2026-11-20-phone-framing-and-good-game.md`.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md and the memories named above. New memory this session: emotes-show-feeling-in-movement (name the kid's feeling first; for a named move get a reference before building).

## CARRY NOTES / GOTCHAS
- **Generator wording:** one action after another in plain order ("starts ... then ... then ...") gave hand work; long lists of body details get lost; a held pose is not kept "the whole time" (use the first half second); it failed once with no reason. Ask 2 s for a pose. A short plain caption ("a person raises their right hand next to their head and waves slowly ...") is untried.
- Each generator call leaves `Workspace.Rig` and `ServerStorage.RBX_ASSISTANT_ANIMGEN` in the place: measure, then delete both. The raw clips load again by id (ids in the emote-making page).
- `tools/emote_preview.py ... --bake=` needs `_G.EMOTE_CLIPS = { "cut:<name>" }` set in Edit first; afterwards check no `EmoteClipKid` is left and the camera is Fixed.
- Roblox emote ids named "... Face" are the whole emote. `Emote_Bored` (10713992055) stands close to a slouch for its first 8 s but a Roblox clip holds every part, so it cannot sit under another clip.
- Edit-mode numbers found real faults before he looked (the hand's own axes pointing 70 degrees off; a head jerk at a loop's end): work the pose out by numbers before handing over.
- Studio's Edit tools fail while he is in Play ("Edit datamodel is not available"); the Server one works then, read-only.
- From before, still true: judge only the first winners' moment after joining; untracked `tools/art/hero.py.old` is not ours (never `git add -A tools`).

## WHAT SHIPPED / OTHER QUEUED
Shipped (newest first, all on `main`):
`f74a5878` Good Game approved, how to re-bake its clips · `15d44286` wave, second version (low V, five waves) · `12175eb7` notes: three wave tries not right · `4cc377af` first small wave and the weight-on-one-leg stance · `40a2630d` steady slow clap, one a second · `6f404509` bent-knee stance (rejected, removed in `40a2630d`) · `d8415269` notes: whole-slow-clap try not usable · `9bb54e7b` clap timed from the Fortnite reference (rejected) · `87b84cf8` first slow clap, hands hung apart (rejected) · `8754efff` notes · `aa463c6e` hands meet at each clap · `47274eff` Good Game remade from Roblox's clap and wave, typed-in clip deleted.
Queued, not started: Nap, Next One; the sounds; class reaction (paper balls); round length 27 s against the shorter scene; the other backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/workshop/emote-making.md`: Good Game's whole path (what was tried, his words, the numbers, the cuts), the generator findings, how to re-bake, how to read a web video frame by frame.
- `docs/workshop/lessons.md`: a named move needs a reference first; hands that meet by IKControl and a stance by priority; a counted allowance counts failed calls.
- `docs/systems/modes-and-scoring.md`: Good Game as it stands, approved.
- `docs/decisions/2026-11-20-runner-up-emotes.md`: feelings through movement; Good Game as approved.
- `docs/playtests/2026-11-20-phone-framing-and-good-game.md`: every look and his words.
- `state/STATE.md`. Checker: OK.

## POINTERS
- Scene: `src/client/WinnersCutscene.luau` (`GOOD_GAME`, `clapHands`, `goodGame`, `ourClip`, `runnerUpClip`). Dev button: `src/client/FlightHUD.luau` ("RunnerUp").
- Cuts and baking: `tools/emote_clips.lua` (`CUTS.GoodGameStance`, `CUTS.GoodGameWave`, `E.bake`), `tools/emote_preview.py`.
- Clips: `assets/animations/emotes/good-game-stance.rbxm`, `good-game-wave.rbxm`.
- Plan: `docs/plan/WINNERS-CIRCLE-PLAN.md`.
