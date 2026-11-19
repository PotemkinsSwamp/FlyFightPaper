# Emote making

How a winners' circle emote gets made, written down while the first one (Camera Flick) is made. The steps and the
motion sources are on the [winners' circle and emotes plan](../plan/WINNERS-CIRCLE-PLAN.md); this page is the log of
what was tried, what worked and the numbers, so it can become a skill.

## Log
- 2026-11-19: plan written; nothing made yet. Already in the repo from October: animations built and previewed by
  script and uploaded through Open Cloud ([lessons](lessons.md), "Animations without Studio clicks"), an FBX-to-R15
  fitting tool (`tools/meshy_to_r15.py`, `tools/r15_keyframes.luau`), and a plane that rides in the winner's hand
  (`src/client/WinnersCutscene.luau`).

## Camera Flick: shot card (step 1, 2026-11-19)
A winner emote, about 2.5 s of action. Proven in today's scene first (Alan).

| Time | The kid | The plane | The camera |
|---|---|---|---|
| 0.0-0.8 s | Standing on the desk, looks at the camera, raises the plane beside the ear and leans back | In the right hand | Steady, close on 1st |
| 0.8-1.0 s | Flicks it forward, sharp, like a dart | Leaves the hand at the **Release** mark (about 0.95 s) | Steady |
| 1.0-1.35 s | Arm stays pointing at the camera | Flies nose-first at the lens, growing until it fills the screen | Steady |
| 1.35 s | Left hand to the hip, proud | Hits the lens | Jolts back, then tips over forward in about half a second |
| to 2.5 s | Holds the proud pose | Lies over the lens | On its side, covered; the scene cuts on from here |

Body-move wordings for Roblox's Prompt to Animation (three versions, each 3 s):
- **A, dart:** "Standing with feet planted, the character raises the right hand beside the ear holding a paper
  airplane, leans back to wind up, then throws it straight forward like a dart with a quick sharp flick, then keeps
  the right arm pointing forward while the left hand goes to the hip, ending in a proud pose pointing forward."
- **B, big throw:** "A playful kid winds up and throws a paper airplane forward with the right hand, fast, then
  pumps both fists in the air, ending standing with both arms raised in a victory pose."
- **C, cool:** "Standing still with feet planted, raise the right hand beside the ear, aim forward for a moment,
  then flick the wrist forward sharply, then cross the arms and nod once, ending with arms crossed."

Numbers each version must pass before anyone looks (step 3): 2-3.5 s long; the hips stay within 0.3 studs of the
start sideways and front to back; the right hand's top speed in the flick is at least three times its average speed
in the wind-up, and comes between 0.5 and 1.5 s; the last 0.5 s moves less than 0.1 studs at the hand (the pose
holds).

- 2026-11-19: first call to the generator failed because Studio was in Play (Alan playing); it needs Edit.
- 2026-11-19, version A made (wording A, 3 s asked). What the generator does: it adds a grey test dummy
  (`Workspace.Rig`), leaves the clip in `ServerStorage.RBX_ASSISTANT_ANIMGEN` (a KeyframeSequence: 90 keys, 30 a
  second, looped, Action priority) **and publishes it to the Roblox account by itself** (`rbxassetid://87115043025421`):
  every try is an upload, so every try needs Alan's go. Saved as `assets/animations/emotes/camera-flick-a.rbxm`; the
  dummy, the clip folder and the picture strip were deleted from the place afterwards.
- The clips carry more bones than a plain R15 avatar has (Spine, Chest, two clavicles, two toes, under UpperTorso):
  how Roblox fits them to a real avatar is only proven in Play. Playing a clip in Edit by script did not work (the
  track's length stayed 0), so `tools/emote_check.lua` works each part's place out from the keyframes and the rig's
  joints, passing the extra bones' turns down to the next real part.
- Version A's numbers: 2.97 s; hips wander 0.60 studs and a foot 0.93 (a small step: over the 0.3 limit, to be locked
  in clean-up); the arm goes out straight ahead (2.3 studs in front of the hips, top forward speed 15 studs a
  second) and holds pointing; it ends hands on hips, still within 0.11 studs. The hand's fastest moment (22 studs a
  second at 1.2 s) is the arm dropping in the wind-up, not the throw: **"fastest hand moment" alone picks the wrong
  beat; look for the fastest forward moment.** The timing is later than the shot card (the point is held from about
  1.6 to 2.3 s); a speed-over-time profile is needed to place the Release mark.
- Looking: pose strips of the dummy (eight moments in a row, a red ball on the right hand, Studio's own viewport
  capture) show an intact, human-looking body, but a strip can miss the key beat between its samples; the numbers
  found the throw the first strip skipped. Whether it reads as a flick needs it seen moving.

Back to [HOME](../HOME.md).
