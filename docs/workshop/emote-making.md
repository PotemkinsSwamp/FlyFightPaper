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
- 2026-11-19, versions B and C made (Alan's go for the two uploads; he doesn't mind them, they aren't public).
  The dummy and the clip folder were deleted from the place again.

| Version | Uploaded id | File | Throw (forward speed, reach, when) | Stays on the spot (hips / a foot) | End pose holds |
|---|---|---|---|---|---|
| A, dart | `rbxassetid://87115043025421` | `camera-flick-a.rbxm` | 15 studs/s, 2.3 studs, late (pointing held 1.6-2.3 s) | 0.60 / 0.93: steps | yes (0.11), hands on hips |
| B, big throw | `rbxassetid://115470516293954` | `camera-flick-b.rbxm` | **18 studs/s, 2.4 studs, at 0.83-0.90 s** (the shot card's time) | **0.25 / 0.33** | no (1.19: the fists keep pumping) |
| C, cool | `rbxassetid://139618321795363` | `camera-flick-c.rbxm` | 4.5 studs/s, 0.95 studs: a small wrist flick, not a throw | 0.12 / 0.43 | yes (0.03), arms crossed |

  By the numbers **B leads**: a fast forward throw at the right moment, on the spot; clean-up has to give it a held
  end pose. A is second (trim its start, lock its step). C is too small to read as a throw; its ending is solid.
  Not yet seen moving by anyone.
- Getting a clip out of Studio: `SerializationService:SerializeInstancesAsync` + `EncodingService:Base64Encode`
  returns about 100-120 thousand characters a clip, and a Studio-link result is cut at 100,000: fetch it in slices of
  60,000 characters and join them (B and C came back cut when fetched whole).
- Wording lessons so far: "throws ... forward, fast" gave a real throw at once (B); "flick the wrist" gave only a
  wrist move (C); "like a dart ... then keeps the arm pointing" gave a slow thrust and a held point (A). "Feet
  planted" did not stop A's step. Every clip came back 2.97 s for "3 seconds", 30 keys a second.

## Preview video without Play (2026-11-19)
`python tools/emote_preview.py STUDIO_ID OUT.mp4` (with `tools/emote_preview.lua`): a plain blocky test kid, scaled
to the room's 140 studs, stands on 1st's desk in the real classroom in Studio's Edit and is posed frame by frame
from the clip's keyframes; the plane and the camera follow the emote's recipe; every frame is Studio's own viewport
capture, joined by ffmpeg. 70 frames take about a minute and a half. No Play, no upload, nothing left in the place.
- The clip comes straight from its uploaded id (`KeyframeSequenceProvider:GetKeyframeSequenceAsync`), so nothing
  big has to be sent into Studio.
- Clean-up done inside the preview so far: the hips are kept over the spot (no step off the desk); the kid faces
  the camera (below). Both still have to be baked into the clip itself before the real build.
- **Facing the camera (Alan, 2026-11-19: "make the kid face the camera for the throw").** Measured first: version
  B's hips swing 60 degrees away at 0.4 s, are square at 0.7 s, 20 degrees past at the release and 40 past at 1.1 s;
  chest and head go with them, the feet stay planted. Fix: feet and hips stay as made (the wind-up survives), the
  chest keeps 0.35 of its turn (untwisted at the waist) and the head's left-right turn is taken out, so the eyes
  stay on the lens (`FACING` in the preview tool). A reviewer found no frame turned away and no broken waist or neck.
- **Camera Flick's recipe as previewed** (version B): the plane rides in the right hand, nose at the camera, tipped
  up and askew so its shape shows; it leaves the hand at 0.87 s, flies 0.42 s straight to the lens (fast off the hand, slower as it
  fills the picture) and turns flat as it arrives, so its wings fill the picture; at 1.29 s the camera is knocked back
  and shaken, then tips 68 degrees forward and drops with a bounce (0.65 s); the plane slides down the lens from 1.74 s. Camera: 225 studs out, a
  little below chest height, 50 degree lens.
- What it can't show: how Roblox fits the clip to a real avatar (extra bones), real avatars' shapes, the room's
  Play lighting. Those are still Play's job.
- Gotchas: the first captures come before the room's pictures load (take four warm-up captures); spatial queries
  miss decorations with CanQuery off, so blockers between lens and kid are found by walking the room's parts (here
  the landing ring and two runway lights on 1st's desk), hidden for the render and put back; hide per piece, never a
  whole folder (one try hid the whole toy town); Studio's camera stays Scriptable unless Fixed is set last, after a short wait.
- An independent look at the first cut (a reviewer agent on a contact sheet) found: the plane rose away on its arc
  and then popped onto the lens (fixed: straight path, eased so the approach shows), a long still hold on the floor
  (cut to 2.2 s) and too much camera roll (24 to 10 degrees). Left for Alan's eye: the body turns side-on in the
  wind-up (fixed, above), and the blocky test body's arm looks huge when it points at the lens.
- Alan on the first cut: "this is what I imagined", apart from the facing.
- Videos: `.planning/emotes/camera-flick-preview.mp4` (first cut), `camera-flick-preview-facing.mp4` (facing the camera).

## Camera Flick in the real scene (2026-11-19)
- **The clean clip.** `_G.EMOTE.bake(parent, name)` in `tools/emote_preview.lua` writes the clip exactly as the
  preview poses the kid: a plain R15 animation (the generator's extra bones folded into the real parts, so nothing
  depends on how Roblox fits them), hips locked, facing fixed, one-shot. Saved as
  `assets/animations/emotes/camera-flick.rbxm`; this is the file to upload.
- **No upload needed to look at it in Studio.** `KeyframeSequenceProvider:RegisterKeyframeSequence` gives a clip in
  the place a temporary id that plays in Studio only. The clip sits in `Assets.CameraFlickClip`
  (`default.project.json`); `WinnersCutscene` registers it when the Dev panel's "end: flick" button asked for it.
  After the upload: the id goes in the config and the clip leaves the place.
- **In the scene** (`WinnersCutscene`, "Camera Flick"): the preview's recipe with sizes in winner heights, from the
  group shot (about twice as far as the preview's camera, same 0.42 s flight). The plane is 1st's own, full size, in
  a layer of its own over the winners and their name plates (in 1st's small-scale layer it would end 0.6 studs from
  the lens and be cut off on devices that cut at 0.5). The scene leaves 2.6 s after 1st's light.
- Alan ran it in Play (2026-11-19): **the throw comes too soon.** Something has to happen first: the kid looks down
  and smugly admires the plane, then looks at the camera and throws. Next: an "admire" body move in front of the
  approved throw (the throw itself stays as it is), three generator wordings, on his go for the uploads.
- **The admire move (2026-11-19, Alan's go for three uploads).** Wordings, 3 s each, and what came back (head pitch
  from the keyframes; the right hand against the chest):

| Version | Uploaded id | Wording | Looks down | Hand | Feet |
|---|---|---|---|---|---|
| **A (picked)** | `rbxassetid://95093448348238` | "Standing still, the character holds a paper airplane in the right hand in front of the chest and looks down at it, admiring it with a slow proud nod, then lifts the head and looks straight ahead with the chest out, still holding the hand up." | **45 degrees, towards the hand, until 1.3 s; level by 1.8 s** | at the chest, then raised beside the shoulder and held | 0.35 |
| B | `rbxassetid://93644793034896` | "A smug kid holds up a small toy in the right hand at chest height, looks down at it and turns it slowly from side to side to admire it, then looks up straight ahead with a confident tilt of the head." | 8 degrees: not a look | at the chest, still | 0.16 |
| C | `rbxassetid://97937045114234` | "Standing with the left hand on the hip, the character raises the right hand to chest height holding a small object, tilts the head down to look at it smugly for a moment, nods once, then raises the head to look straight forward." | 5 degrees | up for half a second, then back at the side | 0.74 |

  Wording lesson: "holds ... in front of the chest and looks down at it" gave a real look; "a smug kid", "smugly"
  and "turns it slowly" gave almost nothing. Describe where the head and hand go, not the mood.
- **Joining two clips** (`tools/emote_preview.lua`): each pose is kept as every joint's own turn, so the blend
  cannot pull the body apart. The admire's look down plays 1.5 times slower (1.95 s), its look up and raised hand
  follow (to 2.95 s), then the throw blends in over 0.25 s from its own start (its first pose has the hand out at
  chest height, close to the admire's last). The plane leaves the hand at 3.82 s; the clip is 5.9 s. The bake writes
  that moment on the clip ("Release") and the scene reads it, so the plane and camera follow whatever the clip is.
  The plane turns over a little in the hand while it is admired. Numbers of the joined clip: head 45 degrees down
  until 2.0 s, level at 2.3 s; hips wander 0.06, a foot 0.44. Not yet seen moving by anyone.

Back to [HOME](../HOME.md).
