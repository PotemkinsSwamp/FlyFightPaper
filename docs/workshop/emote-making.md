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

Back to [HOME](../HOME.md).
