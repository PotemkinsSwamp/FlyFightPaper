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
- **Alan on the admire cut, in Play (2026-11-19):** looking down is fine, but (1) the hand stayed still while the
  plane turned by itself in it: the plane has to be fixed in the hand and the hand and arm turn it over; (2) the
  throw was a baseball throw, not how a paper plane is held and thrown.
- **The plane fixed in the hand.** While it is admired the plane is fixed to the hand part, along the forearm (its
  grip is worked out once from the pose at the start and written on the clip, "Grip"), and the bake adds a forearm
  roll (45 degrees: a little one way, well over the other, back) and a wrist tip (14) on top of the generated move,
  so the arm turns the plane over. As the head comes up, the plane comes round to how a paper plane is held
  ("Hold": the hand under it, nose towards the camera, a little up, askew and banked: pointed straight at the lens
  it is a dot; 30 degrees askew read as pointing sideways).
- **The throw: two poses from version A (dart), upper body only.** Version B's overarm throw is out. A's last second
  has a level push (the hand stays at shoulder height and goes 1.7 studs forward), but the clip crouches wide and
  steps for it, and on the way it cocks the arm up behind the head: played as made, a reviewer still read an overarm
  throw. So the bake takes two of its poses, the hand pulled back beside the shoulder (2.0 s) and the arm stretched
  at the camera (2.5 s), and goes from the held-up plane to the first in 0.35 s and on to the second in 0.16 s
  (fast, then slowing), then lets the clip's own held point carry on. Only the chest's direction, arms and head are
  taken; hips and legs stay as the admire left them, so the feet never move on the books. Timeline now: look down
  to 1.95 s, head up and plane held up to 2.95 s, pull back, push, release at 3.40 s; the clip is 3.9 s.
- Lesson: a clip's legs and upper body can be taken apart. Joint turns make it one line each way; the chest's own
  direction has to be carried over as a direction (not as its turn against the clip's hips, which turn too).
- Looked at as contact sheets from the no-Play preview (three cuts; a reviewer on the second); not seen moving by
  Alan then. Still weak in the stills: the pull-back goes out to the side more than back, and on the blocky test
  body the fist hides part of the plane. Video: `.planning/emotes/camera-flick-admire-push.mp4`.
- **Alan on the turning-over, in Play (2026-11-20): "that does not give off smug. It gives off rushed, hurried."**
  A 45-degree back-and-forth in 1.5 s read as flailing. Smug is slow, with stops. His order: they start looking at
  the plane's bottom; the forearm slowly rolls it over to its top while the arm comes in closer; it stops there a
  second and they look; it rolls back; the head comes up to the camera; the arm winds back and throws.
- **Built to that order** (`TURNS` in `tools/emote_preview.lua`, the emote's seconds): bottom held to 1.0; rolled
  over to the top by 2.5 (a full half turn of the forearm, the elbow bending 16 degrees more to bring it in, the
  head tipping 6 with it); held to 3.5; rolled back by 4.7; held to 5.0; head up and plane raised to 5.7; wind back
  0.55 s; push; release at 6.65 s; the clip is 7.2 s. The admire clip gives the look down in its first 0.9 s, then
  is slowed almost to standing while the arm does the turning, then plays its look up at its own speed. A
  150-degree roll left the plane edge-on to the camera at the bottom view; the full 180 shows it.
- Lesson: **a mood is a tempo.** "Smug" was not in the pose, it was in the speed and the stops: one slow move, a
  full stop, one slow move back. Three quick swings of the same size read as the opposite mood.
- **Alan on the slow cut, in Play (2026-11-20): the arm is wrong, and words are not getting it across.** The hand
  starts too low (belly height) and the head looks too far down; the elbow should be at the side with the hand and
  plane up in front, the head only slightly down; the forearm starts twisted the wrong way round. Next: he shows
  the move on video. Roblox's video-to-animation tool (Studio beta "Live Animation Creator": Avatar tab > Clip
  Editor > the three-dot button > Import > Live Animation Creator; one person, one steady shot under 15 s, .mp4 or
  .mov; [docs](https://create.roblox.com/docs/animation/capture)) can turn that video straight into the body move.
- **No video or photos of Alan, for an AI or for Roblox (his word, 2026-11-20).** So the video-to-animation tool is
  out with him as the subject. What worked instead: **numbered stills to point at.** `_G.EMOTE.try` in
  `tools/emote_preview.lua` poses the test kid with chosen joint turns and plane; six stills of the starting pose
  (hand low, middle, high; the plane's top or bottom towards the kid's eyes;
  `.planning/emotes/flick-start-pose-choices.jpg`) got an answer in one message: number 2's hand height, but
  starting on the bottom, "his elbow tucked inwards into his side ... then he turns his elbow outwards, then
  forward, and now he's looking at the top of the plane. Then he looks at the camera, winds back, and throws it."
  No roll back.
- **Built to that** (the emote's seconds): elbow tucked, hand and plane in front of the chest, head 14 degrees
  down, bottom view to 1.2; elbow out then forward while the forearm rolls right over, to 2.8; top view held to
  4.0; head up to the camera by 4.6; wind back 0.6 s; push; release at 5.30 s; the clip is 5.8 s. The right arm and
  the head are now posed by numbers in the tool (the generated admire clip only gives the rest of the body, almost
  standing still): a directed move with stops is what Alan asked for, and the generator could not be steered to
  it. The plane lies level at both ends of the turn; for that its grip shifts 51 degrees in the fingers on the way
  (a single fixed grip pointed it up at the chin at the start).
- Lesson: **when words fail, show choices of the real model, numbered.** One sheet of stills settled what three
  rounds of description had not.
- **Alan on the picked arm, in Play (2026-11-20): "now he's holding it correctly and throwing it correctly"**, but
  the plane sinks into the hand and arm, on other avatars too.
- **The plane rests on the hand, on any avatar.** It was placed from the hand's middle, so it sat inside the hand.
  Now it is lifted along its own up direction until its underside clears every corner of that avatar's own hand
  and wrist that lies under it (`flickPlane` in `WinnersCutscene`, `held` in the preview tool), so thick or thin
  hands both get a plane that touches and never enters. Two things had to give or it floated: only the hand and
  the wrist end of the forearm count (with the whole forearm the plane hovered away from the fist), and the
  underside is 0.6 of the way to the plane's lowest point (what hangs under the wings may touch the fingers). It is
  held by its back half, 0.3 of its length ahead of the hand, so it reaches out past the fingers. Not handled: the
  plane's tip against the chest or chin.
- **Alan in Play on a real avatar (2026-11-20, picture in chat): the plane floats under the hand.** On a thin-armed
  avatar the plane sat well clear of the raised hand: my offsets were shares of the plane's length, tuned by eye on
  the thick blocky test kid. His rule: the hand's own turn need not be right, but the plane must sit snugly in the
  hand on every body, with no per-body tuning. Proposed, waiting for his OK: hold it the way Roblox holds a tool,
  by each avatar's own right-hand grip point (`RightGripAttachment`), one fixed grip for every body.
- He also asked why the winners and books look low-resolution: they are drawn in overlay layers (ViewportFrames),
  which Roblox draws without edge smoothing and at reduced quality. To look into.
- **Built (Alan's OK, 2026-11-20): the plane is held like a Roblox tool.** It is fixed to the hand's own grip point
  (`RightGripAttachment`) with one grip for every avatar (written on the clip, "Grip"), its middle 0.05 of its
  length ahead of the fingers, lifted until its underside touches that avatar's hand box. All the by-eye offsets
  and the blending of where it points are gone from the game: the plane only ever moves with the hand, and the bake
  turns the wrist so it shows its bottom, rolls to its top, then aims at the camera (the wrist turns up to 119
  degrees for that; Alan: the hand's own turn need not look right).
- Why the grip point and not the hand part: on a mesh-handed avatar the hand part's own axes were turned every
  which way (its grip point read -53, -117, 122 degrees against the part), yet the plane came out facing the same
  way as on the blocky body, because Roblox makes the grip point's direction the standard thing, not the part's.
- Checked by numbers on three bodies (the blocky test kid, a mesh-handed avatar with big accessories, a classic
  avatar): the plane's middle stays 0.4 to 0.5 of a hand's length from the hand's middle at every moment, its
  underside touching the hand; bottom to the eyes at the start (-0.97 to -0.99), top after the turn (0.63 to 0.78).
  **Not seen:** the screen was asleep, Studio drew blank frames, and the keep-awake mouse nudge was refused, so
  there is no picture of this cut. `_G.EMOTE_BODY = <user id>` before running the preview tool stands that user's
  avatar on the desk instead of the blocky kid (sized head to feet: hats and wings made the first try tiny).

## Runner-up emotes: shot cards (step 1, 2026-11-20; Alan: "yes to all")
Alan passed Camera Flick's animation and the framing (2026-11-20) and asked for the runner-up emotes next: Good
Game (free), Nap, Next One. What all three share:
- They play for 2nd and 3rd from the moment their light clicks on until the camera leaves: 8 to 9 seconds beside
  Camera Flick, up to 13 beside a dance. So each is a short opening and then a quiet loop that can run on.
- Small and calm, so the eye stays on 1st; nothing touches the camera.
- **Already in their starting pose in the dark** (Alan's OK): the light finds a kid who is already sitting, instead of
  a standing black shape dropping into a sit at the click.
- Sitting is cross-legged on top of the stack, so it looks the same on 2nd's four books and 3rd's two.
- Today 2nd and 3rd each get a random Roblox dance (`EMOTES` in `WinnersCutscene`); these replace it.

| Emote | Opening | Loop | Prop | New for the code |
|---|---|---|---|---|
| **Good Game** (free) | Standing. Three small claps at chest height towards 1st's side | A one-handed wave at the camera, hand back down, a nod; then the claps again (about 5 s round) | none | a clip per place instead of a random dance |
| **Nap** | Sitting cross-legged, hands in the lap, chin sunk on the chest | Slow breathing; every 5 s the head nods lower, jerks up, sinks again | Three paper Z's (each three thin white strips, no picture) rise from the head, sway, grow and fade | sitting; the Z's |
| **Next One** | Sitting cross-legged, a sheet of paper lying on the right hand | The left hand folds it in three moves (about 5 s); the sheet becomes a half-folded sheet, then a plain white plane; then the kid holds it up and turns it, looking at it, until the scene ends | The sheet and the plane ride on the right hand's grip point, like Camera Flick's plane; they swap at marks in the clip | sitting; a prop that changes at marks |

Body-move wordings for the generator (three each, 4 s asked, to be written on the day from the wording lessons
above: say where the head and hands go, not the mood). Numbers each must pass: Good Game, hips within 0.3 studs and
both hands above the waist during the claps; Nap and Next One, the hips at least a third of a leg lower than
standing and within 0.2 studs of still, the head at least 25 degrees down for Nap, and the last pose within 0.1
studs of the first where it loops.

Risks, said before building:
- **Sitting height on different bodies.** A clip lowers the hips by a set distance; a long-legged or short-legged
  avatar could hover over the books or sink into them. Fix if seen: lower the kid until their lowest point touches
  the top book (the same idea as the plane resting on the hand). The body sweep decides.
- **Hands that should meet** (the claps, the folding hand) will not meet exactly on every body. The claps are small
  and the folding hand only works near the sheet, so a miss reads as a mime, not a mistake.
- Sounds (clap, snore, paper) wait for the sound pass.

Order: Good Game first (standing, no prop: only the body move is new), then Nap (adds sitting and the Z's), then
Next One (adds the changing prop).

## Runner-up emotes: the nine raw body moves (steps 2 and 3, 2026-11-20)
Alan's go for nine uploads. One try failed with no reason given and was sent again reworded. Two tries whose
wording begins with the same 20 letters get the same clip name in `ServerStorage.RBX_ASSISTANT_ANIMGEN`: start
each wording differently, or rename the clip before the next try.

| Clip | Uploaded id | What came back (numbers, then stills) |
|---|---|---|
| Good Game A | `rbxassetid://137019856768402` | hands held 0.7 apart for half a second (no clap); arm out sideways; loops cleanly (0.23) |
| Good Game B | `rbxassetid://104564586758486` | two real claps but the arms fly 4 studs apart: too big |
| Good Game C | `rbxassetid://80526406281018` | three small claps at 0.2, 0.75 and 1.25 s by the numbers, but the forearms cross: a reviewer read crossed arms |
| Nap A | `rbxassetid://70405992022713` | sits cross-legged, head only 26 degrees down, elbows wide: reads awake |
| **Nap B (to use)** | `rbxassetid://103826141789730` | sits upright, the head and chest drop hard at 1.5-2.0 s (75 degrees), come back up: nodding off in class |
| Nap C | `rbxassetid://105590529956729` | slumped right over the whole time (head 55-87 degrees): a ball, the face never shows |
| **Next One A (to use, first 3.5 s)** | `rbxassetid://98981684256935` | sits cross-legged with both hands in front; the hands do not move; kneels up at 4 s |
| Next One B | `rbxassetid://127250147720216` | never sits; hands held still at the chest, then the right hand raised and looked at (usable for the ending) |
| Next One C | `rbxassetid://114191402119300` | sits with legs forward, kneels up at 2.5 s |

- All six sitting tries really sit on the floor (hips 0.9 of a leg lower) and stay on the spot.
- **The generator gives postures, not handwork.** "Folds a sheet of paper with three careful movements" came back as
  two still hands, "waves" as an arm held out, and its small claps as crossed forearms. Sitting and a nodding head
  it does well. So: take the posture from a clip and pose the hands' work by numbers.
- Wording that worked: "sits on the ground with legs crossed"; "head bowed down low ... nods down further, snaps
  upright for a moment, then droops down again".
- Looking at raw clips: `tools/emote_clips.lua` stands one test kid per clip side by side on 1st's desk
  (`python tools/emote_preview.py STUDIO_ID OUT.mp4 SECONDS FPS --keep --lua=emote_clips.lua` after setting
  `_G.EMOTE_CLIPS`); the frames go into one contact sheet with ffmpeg's `tile` (stamp each with its time). Stills
  at 2 or 3 a second miss a clap: print the distance between the hands every 0.1 s as well.
- The raw clips are not kept as files: the tool loads them by their ids above.

## Good Game: the cut (step 4, 2026-11-20)
(Rejected and deleted the same day; kept here for what it taught. The remake is the next section.)
`CUTS.GoodGame` in `tools/emote_clips.lua`, a 4.5 s loop. First cut: version C's claps with a wave posed by
numbers. A reviewer failed it: the claps read as crossed arms or a self-hug, the hips sat differently at the
loop's two ends, and hands cut into the torso on the way down. Second cut, now in: **only the arms and the head
are posed, all by numbers; the clip leaves every other part alone** (poses with weight 0), so Roblox's standing
idle keeps the body alive underneath and the loop cannot jump.
- Claps (0 to 1.5 s, shut at 0.25, 0.75 and 1.25): upper arms 10 degrees forward and turned in 28 (open) to 62
  (shut), elbows bent 70, so the hands meet in front of the lower chest without crossing. Wave (1.95 to 2.95): the
  left arm hangs; the right hand comes up beside the face with the elbow kept in front of the body (upper arm 55
  forward, elbow bent 125) and the upper arm turns out and in three times. Arm down, a 26-degree nod (3.4 to
  4.0), hands back up.
- A second reviewer pass (on the cut before this one) passed it with fixes: the wave arm, then held out level
  with the forearm upright, stuck out sideways on its way up and crowded the head; the claps sat at chin height.
  Both are changed as above and not reviewed again. Left as they are: the arms hang still during the nod, and
  the chin dips into the collar on the blocky test body.
- Arm by numbers, in joint turns: `Angles(forward, 0, 0) * Angles(0, turnedIn, 0)` for the upper arm and
  `Angles(bend, 0, 0)` for the forearm (positive bends the forearm forward and up; a negative turn-in turns the
  arm out). The left arm is the mirror: the Y and Z angles change sign. Work the hand's place out by numbers
  first (a few lines over the rig's joints) and pick the angles from that, before rendering anything.
- The plan says never to type in a body move (October's arm-only test looked lifeless). This is arms over a live
  idle, not a whole body; whether it looks alive is for Alan's eye in Play.
- Baking a cut and saving it in one go (for any cut): `python tools/emote_preview.py STUDIO_ID x
  --lua=emote_clips.lua "--bake=<Cut>:<Cut>Clip:<file.rbxm>"` puts the clip in the place's `Assets` and writes the
  file (fetched in slices by the tool, so nothing big passes through the chat).
- In the scene: Dev panel "2nd/3rd: dances" steps to "2nd/3rd: GoodGame" (`DevRunnerUp`); `WinnersCutscene`
  registered the baked clip for 2nd and 3rd.
- Seen as a contact sheet and video from Edit on the blocky test kid (`.planning/emotes/good-game-cut-sheet.jpg`,
  `good-game-cut.mp4`).
- Not done: turning a little towards 1st for the claps (it faces the camera), and the sound.
- **Alan in Play (2026-11-20): "it looks stiff and the movements are too fast making it look unnatural."** Not
  accepted. What that rules out: arms posed by numbers at this tempo (a clap every half second, three waves a
  second) over the standing idle. The plan's own rule held: a typed-in move looks lifeless. Two reviewer passes on
  stills (about 230,000 tokens) found pose faults and missed both things he saw in one look: **stills cannot
  judge tempo or stiffness; for a body move, his Play look comes before any reviewer.**
- Open for the next try (his OK on a plan in words first): motion from a real source with the whole body in it
  (a generated clip used as made and slowed, Roblox's own wave or applaud, or a video capture of someone else),
  and a calmer tempo.

## Good Game remade from Roblox's own moves (2026-11-20; Alan: "yes, build it")
The plan he passed in words: Roblox's own hand-made clap and wave, played in turn by the scene. No upload, no
generator try, no clip of ours; the typed-in cut, its file and its code are deleted (git has them).
- **The round** (`GOOD_GAME` in `src/client/WinnersCutscene.luau`): Roblox's Applaud emote for 3 s
  (`rbxassetid://10713966026`), a half-second cross-fade into its built-in wave (`rbxassetid://507770239`, 1.75 s,
  fading out over its last half second), then the standing idle alone for about 2.5 s; about 7 s a round.
- **The nod is dropped**: Roblox has none, and a typed-in one is what he rejected.
- What the two clips hold (read from their keyframes in Edit): both move the whole body. Applaud: a clap every
  0.5 s, chest 5 degrees, head 8, knees up to 9. Wave: the **left** arm, the chest leaning 14 degrees, the hips
  shifting a quarter of a stud, back in its first pose for the last 0.2 s.
- **Applaud claps at the same rate as the rejected cut** (two a second), so the Dev button had two choices for his
  eye, Roblox's speed and three quarters. Alan in Play: **"the slow is better"** (replaced the same day by the
  slow clap below).
- **"The hands dont connect when they clap"** (Alan, same look). Measured on six real avatars from his Play: at the
  closest moment the hands' middles stay 0.4 to 1.2 studs apart (at normal avatar size), different on every body;
  on a narrow body the hand boxes pass through each other instead. One set of joint turns cannot fit every body.
  The fix (`clapHands`): Roblox's `IKControl` (it bends an arm so a hand reaches a point; it works on the new
  AnimationConstraint avatars too, says its page) pulls the **left** hand to a point that rides on the right hand,
  fully at each clap and not at all while the hands are open (weight = the clap's rhythm read from the clip's
  time). The point is on the line between the two hands, as far out as the two hand boxes are thick along that line
  times `CLAP_PRESS` (0.8). **A hand's own axes are no guide in this pose**: the right hand's "inner side" pointed
  70 degrees away from the left hand, found by working it out before anyone looked. Only the left arm reaches
  (0.1 to 0.6 studs more than Roblox's move); both hands meeting in the middle is the next step if that looks
  lopsided. Not yet run in Play by anyone.
- Checking that a Roblox animation exists and what is in it, without Play: `MarketplaceService:GetProductInfo(id)`
  (type 24 is an animation; a catalogue emote's own id is type 61 and holds no keyframes) and
  `KeyframeSequenceProvider:GetKeyframeSequenceAsync`.
- Alan in Play on the hand fix: **"yea that works"**.
- **Feelings through movement** (Alan, same look: "the clap should be more like a slow clap and the wave should be
  kind of slow and unenthusiastic. we need to portray emotions through their movements because we cannot control
  their face"). A runner-up's Good Game is grudging, not cheerful. Built, not yet seen:
  - **Slow clap by retiming, not slow motion.** Slowing the whole clip makes the strike float. Instead the clip's
    speed changes inside each clap (`clapSpeed`, set every frame from the clip's time).
  - **First timing, wrong** (hands hung apart for 1.2 s, then struck; 1.58 s a clap). Alan: "they pick their hands
    up and wait then clap at full speed then wait again, thats not how a slow clap looks", and gave a reference:
    Fortnite's Slow Clap (youtu.be/YuWIvsHrZAU side view, youtu.be/2o21CtktcDY front view). **I guessed what a
    slow clap is instead of asking for or finding a reference first.**
  - **What the reference does** (stills every 0.1 s, read off both videos): a clap every 0.63 to 0.65 s, not
    slower; the hands rest **together** for over half of it and come apart and back in one quick, loose swing of
    about a quarter second. The feeling is in the body: weight on one hip, a slouch, one arm swinging out wide with
    an open palm while the other hand stays at the chest. It claps without stopping.
  - **Second timing, from those numbers**: the clip runs at 0.25 of Roblox's speed near hands-together and 1.4
    through the swing: 0.65 s a clap, together for 0.38 s of it; five claps a round. Roblox's clip gives the
    rhythm only: its arc is small and even and its stance upright. The wide one-arm swing and the slouch need
    another body move (a generator try with the hands joined by `clapHands`: his go).
  - **Generator try for the whole slow clap** (Alan's go for one, 2026-11-20; `rbxassetid://89941391724814`, 4 s
    asked, 3.97 s back). Wording: weight on the left leg, right hip out, shoulders slumped, head tilted; left hand
    still at the chest palm up, right hand swinging out wide and clapping down onto it six times. **Not usable.**
    By the numbers: three two-handed near-claps in 4 s (hands 0.9, 1.3 and 1.0 studs apart at 0.47, 1.93 and
    3.53 s), with both arms dropped to the sides for about a second between them; no one-arm swing (both hands
    mirror each other); hips never more than 0.11 studs off centre; the head tilted 19 degrees only for the first
    half second. The same finding as before: postures, not handwork, and a list of body details in one long
    wording mostly gets lost. Dummy and clip folder deleted from the place.
  - **Generator try for the stance alone** (Alan's go, 2026-11-20; `rbxassetid://98222857059913`, 3.97 s): "stance
    only, no steps: ... weight on the left leg, the left hip pushed out, the right knee slightly bent, shoulders
    slumped forward, head tilted ... staying in this same slouched pose". Half right. 0 to 1.7 s: the left foot
    under the body, the right knee bent 66 degrees with the foot 0.27 studs up (on its toes), the hips tilted 5 to
    6 degrees, held dead still (nothing moves more than 0.02 studs: no breathing). From 2 s the foot steps back
    and the head hangs 35 degrees forward for the rest. No slumped shoulders and no side tilt of the head anywhere.
    **A held pose it can do; "the whole time" it does not keep.**
  - **The stance cut** (`CUTS.GoodGameStance`, baked to `assets/animations/emotes/good-game-stance.rbxm` and into
    the place's `Assets.GoodGameStanceClip`, unsaved): only the hips and the legs from the first 1.6 s. The scene
    plays it looped from the dark on at priority Action2, one above the clap and wave (Action), which keep the
    chest, head and arms; the upper body leans with the tilted hips. **Layering by priority needs no weights**: a
    clip that holds only some parts, played one priority higher, takes just those parts. Not yet run in Play.
  - **Alan in Play on all of it (2026-11-20), his shot card in his own words:**
    - Stance: "it's still like the rested leg ... instead ... they're kind of just shifting their body weight on
      one side ... leaned a little bit back into like maybe the right, and they're putting all their body weight
      on one leg, kind of slouched." The bent-knee cut and its file are deleted.
    - Clap: "still too fast. Even that animation from Fortnite was still too fast ... It's the clapping that's
      supposed to show dramatism ... It should be like 1, 2, 3 ... a second between each clap ... the arms and
      hands should move accordingly ... They should never be waiting. It's one smooth rhythm." **Built:** Applaud
      at a steady half speed (a clap a second, no speed changes inside the clap), three claps, then the arms drop
      (0.7 s blend) and the kid stands 2.5 s. `clapSpeed` is gone.
    - Wave: "too enthusiastic. They're moving their whole arm above their head ... they put their hands back down
      after the clap, drop it to their sides ... Their shoulders drop with them ... weight kind of shift, and then
      they raise one of their hands, probably their right ... not all the way up, just forming a slight L shape
      ... hand in line with the head, and then wave it back and forth, kind of slow, like they're uninterested."
      Roblox's wave is out of the round; this needs a body move of its own.
  - Roblox clips looked at for this, by numbers (none fits as it is): **Hello** (10714359093, 1.77 s) waves the
    left hand over the head top with the chest leaning 15 degrees: as enthusiastic as the built-in wave.
    **Bored** (10713992055, 12.6 s) stands for its first 8 s close to the stance he describes (hips 0.1 studs to
    the right and tilted 6 to 7 degrees, chest leaning back 9 to 11, head tipped back 26 and turned 12, arms
    hanging), but a Roblox clip holds every part, so it cannot sit under the clap. **Tilt** (10714338461): hips
    half a stud over, a hand on the hip. **Correction:** the ids named "... Face" (Hello Face, Sad Face, Shrug
    Face) are the whole emote, body included, not a face half: `InsertService:LoadAsset(<catalogue emote id>)`
    returns the emote's Animation with that id.
  - **Alan in Play on the steady clap: "The slow clap is good now."** (He also said he had not really looked at the
    bent-knee stance before judging it.) His go for a stance try and a wave try:
    - **Stance** (`rbxassetid://106864956338262`, 2 s asked): "leaning stance held still ... weight shifted onto
      the right leg, the hips pushed out to the right, the upper body leaning slightly back, shoulders slumped,
      both feet flat". Came back subtle: for the first 0.6 s the right foot under the body (0.39 studs out), the
      left out at 0.85, both flat, hips tilted 5 to 6 degrees, knees bent 15 to 21, chest 4 degrees **forward**
      (no lean back, no slump); then it shuffles its feet. Cut `CUTS.GoodGameStance`: hips and legs, first 0.5 s.
    - **Wave** (`rbxassetid://72977568176735`, 4 s): "uninterested small wave: ... raises the right forearm so
      the elbow is bent in an L ... tilts the right hand and forearm side to side twice ... drops". Came back with
      the hand work this time: arms hang to 1.2 s; the forearm comes up (elbow 130 degrees) to 1.87 s with the hand
      in front of the shoulder (about a stud under the chin, not beside the head); two small side-to-side tips to
      2.93 s with the head tilting 15 degrees and the chest leaning back 7; **then it throws the arm over the head
      (3.07 to 3.33 s)**; then drops it. Cut `CUTS.GoodGameWave`: 0.67 to 2.93 s, a 0.3 s blend over the thrown
      arm, then the clip's own drop (3.57 to 3.97): 2.96 s, the whole body. **Short, plain wordings of one action
      in order ("starts ... then ... then ...") gave hand work the long lists did not.**
    - In the scene: clap (three), a 0.7 s blend into the wave at 0.65 speed (about 4.5 s), stand 2 s; the stance
      holds the hips and legs throughout. Both clips are in the place's `Assets` (unsaved) and as files beside
      the Camera Flick ones. Not yet run in Play.
  - **Alan in Play: "The stance is good. The clap is good. It's just now the wave is messed up."** The wave: "they're
    putting their hand in front of them ... not to the side, parallel with their head ... a low V L shape, hand in
    line with their head, elbow pointing downwards, and just a slow wave ... 1, 2, 3. About maybe like 0.8 seconds
    between each wave. But maybe do like 5 waves ... kind of lazy and kind of like their hand flows a little bit."
    His go for up to three wave tries (6 s asked each); **none is right, the old wave is still in the game**:
    - A ("Lazy side wave: ... raises the right hand up beside the right side of the head with the elbow bent and
      pointing down ..."): the generator failed, no reason, no upload.
    - B (`rbxassetid://98868591718671`, "Bored greeting wave: ... upper arm low and the forearm pointing straight
      up, making an L shape, so the open right hand is next to the right ear ... rocks slowly side to side five
      times"): arms hang to 1.5 s; at 1.9 to 2.8 s the elbow is out high (0.6 studs up) with the hand at chin
      height 0.75 in front; **from 3.1 to 4.3 s the elbow is down at the side (the low V)** with the forearm up
      but leaning 27 degrees forward and 30 to 38 inward, so the hand is at shoulder height, 0.46 in front; it
      sways only 0.08 studs each way, about twice, 0.6 s a sway; the head tilts 28 degrees; the arm drops at 5 s.
      The nearest of all, still not his pose.
    - C (`rbxassetid://98917973290984`, "Right hand raised next to the head: ... elbow tucked low and pointing at
      the floor, never in front of the chest ..."): the hand goes in front of the chest (up to 1.2 studs forward)
      for two seconds, then the elbow goes up to head height with the hand at the ear, held, no waving.
    - Worked out from the rig: with the elbow pointing down the hand can reach about chin to mouth height beside
      the head (1.0 to 1.25 studs up, head centre 1.56), not higher: "in line with the head" is its lower half.
    - Idea not yet tried (the fourth call was refused: three were allowed): a short plain caption, the way such
      generators are trained ("a person raises their right hand next to their head and waves slowly ..."),
      instead of a list of body parts.
  - **Alan's ruling on the pose:** "As long as the elbow has a lower V ... it doesn't matter if the hand comes up
    directly in line with the head ... If the hand comes down to the chin, that's fine too." (Arms differ in
    length between avatars.) That makes try B usable. **The wave cut, second version, no new upload**
    (`CUTS.GoodGameWave`, 5.7 s, the whole body from B): arms hanging 0.6 s, B's own raise, a 0.2 s join over the
    second it holds with the elbow out high, the elbow settling at the side, B's one sway (0.6 s) five times, a
    join, B's own arm drop, the last 0.3 s eased back to the first pose. Two changes by numbers, both a constant
    applied to the generated motion, not typed-in poses: the upper arm turned out 30 degrees about its own length
    while it is up (the hand, half a stud in front, now stands over the elbow), and the sway of the arm's three
    joints made 2.5 times bigger (0.16 studs at the hand was too small to see). Checked on the baked clip: the
    elbow stays at 1.5 studs out and 0.2 below the hip line of the shoulder while the hand sways 0.34 studs
    between over the elbow and in towards the head, 0.5 to 0.7 studs up (between shoulder and chin); the wrist
    bends 29 to 63 degrees as it goes (the "flow" is B's own); the head tilts 28 degrees; no key moves the head
    more than 3 degrees. Scene: played at 0.75 (0.8 s a wave), about 7.5 s; a round is now about 13 s, longer
    than the 8 to 9 s the runner-ups have beside Camera Flick. **Alan in Play: "The wave is fine."** Good
    Game is approved as it stands (he left the length alone).
  - If the place is closed without a save, the two clips are gone from `Assets`: bake them again (each loads its
    generated clip by id): set `_G.EMOTE_CLIPS = { "cut:GoodGameStance" }` in Edit, then `python
    tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=GoodGameStance:GoodGameStanceClip:assets/animations/emotes/good-game-stance.rbxm"`
    and the same with `GoodGameWave` / `good-game-wave.rbxm`; then delete any `EmoteClipKid` left in the
    workspace and check the camera is back to Fixed.
  - Looking at a web video frame by frame without downloading it: in Chrome, a script seeks the page's own video
    and draws each moment into a grid laid over the page (cropped to the character, time stamped), and one
    screenshot shows 30 moments.
  - **Half-hearted wave by weight.** The wave plays at 0.6 speed and 0.65 weight: an Action clip under full weight
    lets the standing idle show through, so the arm only comes part of the way up and the lean is smaller.
  - Steps now end on the clip's own time (five claps = 2.5 clip seconds), not on a clock.
- Roblox-made mood clips that exist, for posture if the retiming alone does not carry the feeling (ids checked in
  Edit, not yet looked at): `Emote_Bored` 10713992055 (a candidate for the standing rest), `Emote_Agree`
  10713954623 (a nod), `Emote_Beckon` 10713984554 (what they hold: below).

## Nap: approved by Alan in Play, the arm fix too (2026-11-20)
The feeling: bored and done ("I didn't win, wake me when it's over"), the kid asleep at the back of the class.
**Alan's own version** (his "yes, build it"): "sitting crisscross applesauce, elbow on the knee, holding their head
up ... the bubble ... the Z's ... they jolt up, and then they look around like side to side. 1, 2, 3. Then they look
forward, and then they kind of just fall back to sleep" (onto the hand; his other ending, the arm and then the head
falling, is not built: it needs a second sleeping pose and more time than the 8 to 9 s beside Camera Flick). Before
that he asked for legs dangling off the books instead of crossed, then dropped it for this version.
- **Alan's first look in Play:** "It looks all right, except the models are not always sitting on the books. They're
  kind of floating ... their head needs to be more down ... fully, like, limp down, resting on the hand ... it makes
  them look awake, if you can see their faces"; the elbow need not be on the knee, only on that leg; the hand may
  hold the head anywhere. Both changed the same day; **his second look: "Yeah, I think that's good. I think we move
  on"**, with one fault: one kid's arm was "moving back and forth ... glitching out" in that look (found and fixed, below):
  - **Head down:** it hangs 70 degrees down (84 in a nod), rolled 15 onto the hand, which holds it by the right side
    of the brow; the chest slumps 15 to 17 degrees forward (the tool picks the lean nearest 25 that keeps the elbow
    on the thigh: it lands 0.67 studs over the thigh's line, 0.88 of the way to the knee). The camera looks down on
    the kids from 1.6 heights up, so it sees the top of the head. Numbers below this point are from the first pose.
  - **Seated on the books** (`sit` in `WinnersCutscene`, every frame): the kid is moved up or down until the lowest
    point of their hips and legs, taken as rounded limbs, is on the top of their stack. A clip drops every body's
    hips the same distance: in the dry run a tall slim body floated 0.34 studs, the standard one was 0.23 and a
    short one 0.38 into the book. With the shins and feet on the book the thighs are about 0.25 studs over it.
  - The bubble now leaves the mouth towards the camera and the kid's left, so it shows under the lowered face.
- **The arm glitch, measured in a Play run of mine** (his go; muted, numbers only: the right arm's turn against the
  chest every frame, both runner-ups, four winners' moments in one Play):
  - It was Roblox's IKControl while the kid was **awake**: on one body (3rd place, 6.2 studs tall) the right upper
    and lower arm flipped up to 178 degrees in a frame, five or six times a second, through the look-around. The
    other body only jumped once (35 degrees) in the sink.
  - Asleep, the clip alone left the hand 0.5 to 0.7 studs off the brow on real avatars (far more than the 0.04 to
    0.12 on my Edit test bodies), and IKControl closed that on one (to 0.09) and not on another (0.75).
  - **Fix: no IKControl.** `bendArm` in `WinnersCutscene` bends the arm itself, after the animation and from its
    pose, on `RunService.PreSimulation` (shoulder so the elbow is where a two-bone arm needs it, on the knee's side;
    elbow so the hand's middle is on the point), with a weight: 1 asleep, let go over 0.15 s at the jolt (awake the
    clip alone leaves the hand in the air), back over the last 0.4 s as the head lands. The same math run from
    outside in that Play on four bodies: hand 0.00 studs off the brow every sleeping second, at most 0.6 degrees a
    frame asleep, 18 to 21 at the jolt, no flipping. The version in the file ran in Edit (0.12 off becomes
    0.001) and then in his Play: **"arms look fine now".** The pose is read from the joints' own `Transform` (`rig`): a part's CFrame is
    a frame old when PreSimulation runs, which gave two small back-and-forth frames in the nod's catch.
  - In the same Play, `sit` held: lowest point 0.000 over the book top on both kids; thighs 0.00 and 0.18 over it.
  - How to run such a check without clicking: in the Client, `Root.RoundAction:FireServer("join")`, set
    `DevRunnerUp` on `ReplicatedStorage.FlyFightPaper`, `FireServer("endMatch")` (again after each moment for
    another, with other winners); the winners are `workspace.WinnerStage.Winner<place>Stage.Cast.Winner<place>`.
- **Two clips**, both cuts in `tools/emote_clips.lua`, in the open place's `Assets` (unsaved) and as files:
  `NapSleepClip` (`CUTS.NapSleep`, `assets/animations/emotes/nap-sleep.rbxm`, an 8 s loop: a breath every 4 s, one
  small nod at 5 s) and `NapWakeClip` (`CUTS.NapWake`, `nap-wake.rbxm`, 5.1 s, once: jolt 0.2 s, sitting stiff,
  looks right, left, right and forward from 0.45 to 2.6 s, then 2.5 s of sinking back: a dip, a catch, the sink).
  The scene (`nap` in `WinnersCutscene`) plays the loop from the dark and the wake clip over it when 1st's light
  clicks on. So a nod comes 5 s after dozing off and then every 8 s (two breaths), not every 5.
- **Where each part comes from.** The body: Nap B sitting still (its 3.0 s) and sitting up (its 3.9 s; at 3.5 to
  3.8 s it startles by itself: leans back, looks up, lifts its hands). The looks: Roblox's own, cut from its
  standing idle (`rbxassetid://507766666`: head to 47 degrees right at 0.15 to 0.55 s, across to 68 left with a dip
  of the head at 1.8 to 2.45 s), as the head's and chest's turns away from facing forward. By numbers: the lean that
  puts the elbow on the knee (worked out by the tool for the test body: 6 degrees forward, 18 to the right; a small
  lean is enough because an R15 body is short), the head held 12 degrees down and rolled 16 onto the hand, both
  arms bent to reach (right hand under the jaw, left on the left knee), the breath (2.5 degrees of the chest; Nap B
  has none), the nod and the timing.
- **Checked by numbers in Edit** (baked clips, standard body): hand to jaw 0.00 studs asleep; the hand does not move
  at all through the wake clip (the head leaves it by 0.6 studs and comes back); elbow 0.76 over the thigh's knee
  end; loop ends meet exactly; biggest turn in one key 25 degrees (the left forearm in the jolt's first frame).
  Two faults the numbers found first: the looks barely turned (Roblox's idle has keys in between whose poses have
  Weight 0; the tool now skips them), and the jolt did 47 degrees in its first frame (it now eases out over the
  0.2 s and goes 8% past upright).
- **A dry run of the real scene code in Edit** (the `nap` function lifted out of the script, a test body stepped
  with `Animator:StepAnimations`): no errors; the bubble pops at the jolt, five bits fly, no Z's while awake, a new
  small bubble once asleep again. On a tall slim body the clip alone leaves the hand 0.16 studs off the jaw; the
  IKControl meant to close that does nothing in Edit, so it is unproven until Play.
- **Not known until Alan's Play look:** how any of it looks (nobody has seen it), the IKControl arm on real bodies,
  whether the crossed shins sink visibly into the top book (on the test body the legs' boxes go up to 0.4 studs
  under the feet's level; the thighs rest about level), the props' sizes and colours under the spotlight.
- **The props** are plain parts made by the scene, sizes in head heights: Z's 0.3 growing to 0.9, one every 1.33 s,
  4 s each, from the head on the kid's right; bubble 0.06 to 0.25 across-half (radius) over 6 s at the mouth on the
  kid's left, pale blue, 0.45 see-through, one white glint; the pop 0.1 s, bits 0.3 s.
- If the place is closed without a save: `_G.EMOTE_CLIPS = { "cut:NapSleep" }` in Edit, then the two
  `--bake=NapSleep:NapSleepClip:assets/animations/emotes/nap-sleep.rbxm` and `NapWake` / `nap-wake.rbxm` runs (as
  for Good Game above); then set the camera back to Fixed from a delayed line (`task.delay(1, ...)`: Studio's
  assistant puts the camera type back when a command ends).

## Next One: approved by Alan in Play (2026-11-20)
- **His second look, at the four runs: "it looks good move on".** Approved as it stands; Studio only until its
  clip is uploaded on his go.
- **Alan's first look in Play:** "It's fine. It just looks like they're fiddling with this flat piece of paper until it opens up. Because they run their hands over it more than the paper changes ... run their hand over it, it's flat, then they run their hand over again, then there's a fold, then it runs their hand over it again, there's another fold, and then they run their hand over again, and then it's done, and they pick it up". The first build moved the hand eight times for three changes (an arc,
  a run along the crease and a trip to the next flap for every fold). **Changed the same day (what he approved):**
  four runs, a still moment after each, one change each: at 0.15 to 0.7 s the hand crosses the flat sheet from
  its far side to the near edge (nothing changes); 1.2 to 1.75 s the fold in half; 2.25 to 2.8 s the nose; 3.3 to
  3.85 s the wings; at 4.3 s the plane is picked up. The crease runs are gone; before the nose and the wings the
  hand hops a quarter of a stud to the flap's edge in the last 0.25 s of the still moment. Dry run on the three
  test bodies: hand 0.00 off on two, reach at most 0.88; short and wide 0.105 studs short once.
- What follows describes the first build where it differs (the fold times and the crease runs).
The feeling (Alan's "yes, build it" to the plan in words): already over it and planning the rematch ("fine, you got
this one, the next one is mine"); not sulking, not watching 1st, busy. Sighting along the plane at the end: "leave
the sighting out".
- **What it does.** In the dark the kid already sits cross-legged, hunched a little, head 29 degrees down, a white
  sheet lying on the right hand in front of the belly and the left hand on its near edge. At their light: three
  folds (in half, away from them, done at 0.75 s; the nose, the far front corner, at 2.15 s; the wings, the upper
  layer back towards them, at 3.6 s), each one the hand over the top in an arc, a run along the new crease towards
  the nose, and a still moment. At 4.3 s the left hand lets go and sinks to the lap, the kid sits up and the right
  hand lifts the plane to eye level in 0.9 s (the keel drops and the wings tip up 10 degrees on the way), then
  rocks it 35 degrees either way about its length, once every 3 s, the head on it, until the scene ends.
- **The paper really folds** (`nextOne` in `WinnersCutscene`): ten thin white pieces (four strips, six triangles:
  each half of the sheet cut along its own folds) swung about the fold lines, the same pieces from flat sheet to
  finished plane. The folded-over nose corners stop being drawn once flat (white on white). The paper is fixed to
  the right hand like a tool: on its thumb side, nose along the fingers.
- **The left hand** is put on the paper by `bendArm` every frame: on the edge of the flap it folds, so its path is
  the fold's arc (plus a lift at the top, 0.6 of the hand's half-thickness: the arc alone is under half a stud),
  then along the crease. It lets go over 0.6 s.
- **The body** is one clip, `CUTS.NextOne` in `tools/emote_clips.lua` (`Assets.NextOneClip` in the open place,
  unsaved, and `assets/animations/emotes/next-one.rbxm`; 8.4 s, played once, held on its first pose in the dark,
  going round its last 3 s after the raise; `Raise`, `Raised` and `Turn` are attributes on it). Next One A gives the
  sitting legs and hips (one still pose, its 1.0 s). By numbers: the hunch (10 degrees), the right hand's place at
  work and its level thumb side, the head (half way from straight ahead to looking at the right hand), and the
  raise: one move between two solved poses, quick off the lap and slower as it arrives. **The raise is typed in,
  the kind of arm move Alan found stiff in the first clap**; if he does, Next One B's own raise is the fallback (it
  stops at chest height).
- **Avatars' arms are short, which set the size.** Shoulder joints are about half a body height apart and an arm
  reaches about a quarter of a height, so the two hands only meet close in front of the chest. A sheet as long as
  the forearm and hand (1.4 studs) could not be folded: its far edge was up to 1.6 arm's reaches away. So the sheet
  is 0.9 of the forearm part long (1.0 stud on the standard body, 18% of its height; Camera Flick's plane is 30%),
  held across the body with its nose to the kid's left, the folds going away from and towards them.
- **Checked by numbers in Edit, no pictures** (the real scene code lifted out of the script and stepped on three
  test bodies): standard and tall slim, the left hand 0.00 studs off its point on the paper the whole time, never
  further than 0.91 of the arm's reach, the paper never inside the body; **short and wide (the worst case), the
  arm runs out twice, at the far edge, by 0.17 studs** (it stops nearly straight just short of the paper), and a
  flap's tip touches the head's box by 0.04. The clip: biggest turn in one key 4.0 degrees, the loop's ends meet
  exactly. Both scripts compile; Studio has them (Rojo).
- **Still not known:** the hands on real avatars (Edit test
  bodies understate, see Nap); whether the left hand hides the paper while it presses (a blocky hand is as big as
  the half sheet).
- **Dry-run traps in Edit.** The first run after a bake poses nobody (the new clip is not loaded yet: run it
  twice). A part does not move when a joint's turn is written (new avatars' joints are AnimationConstraints):
  read a part's place from `rig`'s `at`, not from the part. `emote_preview.py --run=FILE.lua` runs a Luau file
  after the scene script and prints its answer, with no pictures taken.
- If the place is closed without a save: `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua
  "--bake=NextOne:NextOneClip:assets/animations/emotes/next-one.rbxm"` (with any `_G.EMOTE_CLIPS` set).
- **To look at it:** Dev: hangar, F8, "2nd/3rd" stepped to NextOne, then "end: flick".

## The six clips uploaded (2026-11-21, Alan: "go to upload")
All three runner-up emotes and Camera Flick are approved, so their clips went up as private animations on Alan's
account, each from its file in `assets/animations/emotes/` (first written out again from the open place and compared:
the same bytes as what he saw in Play). `python tools/upload_texture.py FILE.rbxm --animation --creator 52064999
--name "..." --output assets/animations/emotes/uploads/NAME.json`; all six passed moderation at once.

| Clip | File | Id |
|---|---|---|
| Camera Flick | `camera-flick.rbxm` | `rbxassetid://92727749892782` |
| Good Game's stance | `good-game-stance.rbxm` | `rbxassetid://105243837282624` |
| Good Game's wave | `good-game-wave.rbxm` | `rbxassetid://85227875188355` |
| Nap asleep | `nap-sleep.rbxm` | `rbxassetid://87423606831743` |
| Nap waking | `nap-wake.rbxm` | `rbxassetid://130303608450334` |
| Next One | `next-one.rbxm` | `rbxassetid://77528904973973` |
| Toy Pilot (same day, later; Alan: "fine, go to upload") | `toy-pilot.rbxm` | `rbxassetid://135069682151169` |
| Book Kicker (same day, later; Alan: "go 1") | `book-kicker.rbxm` | `rbxassetid://73358935726911` |

- **The ids are in the config** (`rounds.emote_clips` in `config/gameplay.json`), and so are the moments an uploaded
  clip can no longer carry as attributes: `camera_flick_release`, `camera_flick_grip`, `next_one` (raise, raised,
  turn). `ourClip` in `WinnersCutscene` plays the id.
- **A draft wins in Studio.** A clip named `<Name>Clip` in the place's `Assets` (what `--bake` writes) is played
  instead of the uploaded one, with its own attributes: that is how a cut is worked on without an upload. The six
  drafts are deleted from the open place, so Studio now plays the uploads. A changed cut needs a new upload (his
  go) and its new id in the config.
- **Checked in Edit, numbers only:** all six load from Roblox with their files' key counts and lengths; Next One's
  dry run on the uploaded clip gives the same numbers as on the draft. **Alan in Play from the uploads, 2026-11-21: "they play the same".**
- **Still Studio only**, behind the Dev buttons: who gets which emote (one free, the rest sold) is not decided or
  built.

## Toy Pilot: shot card and the three raw body moves (2026-11-21)
The free 1st-place emote. Alan's "go for the three tries" to the plan in words (he did not answer its three
questions, so my picks stand until he says otherwise: the feeling, the quiet start, the held ending).
- **The feeling:** the happy winner, lost in playing with their plane, then proud. Smooth swooping moves, head and
  body following the plane, a chest-out finish. (Camera Flick is the cocky one.)
- **Shot card** (seconds after 1st's light; the camera leaves at about 10): 0 to 4 looks down at the plane in the
  right hand, turns it over, lifts it to eye level (no sound: the runner-ups' sounds live here, see
  [sound and effects](../systems/sound-and-effects.md)); 4 to 6 one big swoop across overhead, leaning into it; 6 to
  7.5 a dive in front and a pull-up, knees bending; then thrust up high and held, other fist on the hip, a small sway.
  Sounds: a soft whoosh on the swoop and on the dive. The plane is the scene's own `holdPlane` and `flyPlane` (the
  nose follows the hand): no new prop code.
- **The three tries** (each an upload to Alan's account; all came back first time; the dummy and the clips folder
  were deleted from the place after; numbers from the clips' keyframes, hand heights against the head on the
  generator's 5-stud dummy, nobody has seen them move):

| Try | Uploaded id | Asked | What came back |
|---|---|---|---|
| A, whole card in one | `rbxassetid://112258133635270` | 10 s | The hand hangs at the side for 4 s (no admiring), one raise to head height at 5.5 s, then the kid walks off (hips 1.9 studs, a foot 2.1) and ends moving. **Not usable.** |
| **B, the flying (to use)** | `rbxassetid://93519745518213` | 6 s | **A real swoop:** the right hand goes over the head from the right side to the left between 0.3 and 1.3 s (0.7 studs above the head). Hand at the side with the head bowed 1.5 to 3.5 s. **The ending:** the arm goes straight up from 4 s and holds (0.07 studs of movement in the last second). Left hand by the hip throughout. Hips wander 0.47, a foot 0.50: to be locked. |
| **C, playful (its start to use)** | `rbxassetid://100781595643396` | 8 s | **The admiring:** 0 to 2 s the hand holds something in front of the face, the head bowed 40 to 46 degrees. Arm overhead 4 to 5.5 s, then lowered, looking 90 degrees to the side; ends moving. Hips 0.33, a foot 0.88 (it bounces). |

- **No try has a dive.** "Dives the hand down in front and pulls it back up" came back as nothing (A) or a bowed
  head with the hand at the side (B). The generator again gives postures and big arm arcs, not a path for the hand.
- **The cut, ruled by Alan ("go with option 1"):** C's admiring stretched to 4 s, B's swoop over, B's
  swoop played backwards as the way back (in place of the dive), B's raise and hold. Built and rejected: below.

## Toy Pilot: the cut from a reference video (2026-11-21; fourth version approved: Alan "it looks fine")
**Approved by Alan in Play, the fourth version as built** ("it looks fine, lets move on"), after his own avatar hid the plane and he [took that loss](../decisions/2026-11-21-plane-stays-in-the-hand.md). **Its sound, his pick by ear:** one quiet whoosh ("a subtle sound ... if it's loud, that's going to be stupid"), played at 3.0 s (the swoop down and out) and 4.5 s (back up), "timing is fine"; nothing else ("this is practically it"). Which sound and how loud: [sound and effects](../systems/sound-and-effects.md). The runner-ups' sounds stop before the first whoosh, as with Camera Flick. The start stays at 2 quiet seconds.
**Uploaded** (his go; the file first compared with the draft he approved in Play: the same 139,949 bytes; passed moderation at once): the id is in `rounds.emote_clips` and the draft is deleted from the open place, so "end: pilot" now plays the upload. Checked in Edit, numbers only: it loads from Roblox with 391 keys and 13 s. Not yet seen by Alan from the upload. `rounds.winner_plane_emote` stays empty: like the other six, Toy Pilot plays in Studio only until who gets which emote is decided.

**Alan on the third version: better, still off: the raised arm is cramped and the ending pose is not right**: "not
extending their arm up enough. It doesn't look like a victory ... just holding the paper airplane" (the lean to the
left and the timing he did not fault). **Fourth version (built and measured, seen by nobody):** `reach` held every
arm to 0.95 of its length, an elbow bent 36 degrees: a raised arm now goes to 0.995; the ending closes from the wide
V to the video's high arm, pulled in and punched straight up so the plane ends nose up. The table and the third
version's numbers below are from before this change. Next: one Play recording beside the video (his go), then his look.

**The first cut, from the generated clips B and C, Alan rejected in Play**: "it doesn't work at all for the models
... bringing their hand into like their face ... very awkward" ([playtest](../playtests/2026-11-21-toy-pilot-first-cut.md)).
**The second, traced from his Gemini video, too**: "it still looks very much off ... it kind of struggles with every
character ... in the first second, it's extremely rushed". He asked for a Play of mine laid frame by frame beside the
video; what that showed and what changed is in the same playtest note. Lessons: measure a hand path at 20 samples
a second before describing it; do not build a body move blind; and **numbers on the blocky test kid do not show a
real avatar** (short arms, big head and hair): record the scene in Play and lay it beside the reference before
Alan looks.

**Reference videos come from Gemini (Alan, 2026-11-21: "from this point on").** Claude writes the prompt, Alan runs
it and attaches the MP4. The prompt that gave a usable video first time: one continuous 10 s shot, fixed camera
straight on, the whole figure with space overhead, plain light grey room, a simple grey mannequin, feet on one
spot, one hard rule for the hands, then what happens second by second. His verdict on the video: "this should
actually be perfect".

**From video to cut** (`CUTS.ToyPilot` in `tools/emote_clips.lua`; baked to `assets/animations/emotes/toy-pilot.rbxm`
and into the open place's `Assets` as the draft `ToyPilotClip`, unsaved: bake again after a close without a save,
`--bake=ToyPilot:ToyPilotClip:assets/animations/emotes/toy-pilot.rbxm`):
1. `python tools/emote_trace.py VIDEO.mp4 --check=DIR` finds, in every frame, the head, the hips, the right hand
   and the left arm's end, and prints a row of numbers every 0.2 s: the right hand from its shoulder in arm
   lengths, the trunk's lean, the hips' shift, the left arm's angle. Look at the six check pictures first.
2. The cut poses the test kid from those rows with a smooth line through them, in the video's own seconds: both
   arms bent to their targets (`reach`), the trunk leaned, the head turned half-way to the hand.
3. The stance and the planted feet are generated clip B's standing pose (its 5.5 s).
4. **Made for Roblox bodies, not the mannequin's** (the comment over the cut has every number): the hand is kept
   out to the side of the trunk (0.45 arm lengths at least; a raised arm 0.64: a wide V at full length); where the
   video folds the arm across over the head, the trunk leans after the plane instead (12 degrees more at most);
   an arm the picture shows short is mostly bent, not pointed at the camera (0.6 of the missing length forwards);
   the left fist goes to the side of the hips with the elbow straight out.
5. **Record it in Play and lay it beside the video** (needs Alan's go): mute, start Play, client `mapReady` and
   `join`, wait for 12 pilots, the Studio link's `video_capture` on, set `DevFirstEmote` and fire `endMatch`, 22 s,
   capture off, stop, un-mute. Then `ffmpeg -ss LIGHT -i PLAY.mp4 -vf "fps=2.5,crop=380:380:810:120,scale=300:300,tile=9x3"`
   for the winner and the same `fps` and `tile` on the reference. The mouse nudge keeps the screen drawing.
   [Reference, second version and third version](../../.planning/emotes/toy-pilot-play-vs-reference.jpg).

| Seconds after 1st's light | What the kid does (third version) |
|---|---|
| before the light | Already stands in the first pose, in the dark |
| 0 to 2 | Holds the plane up beside the head, a head's width out to the side, side on to the room, and looks at it |
| 2 to 3 | Lifts it up and out to the right; the left arm starts to float out |
| 3 to 4.5 | Swoops it out wide and low to the right, the trunk leaning 25 degrees after it, the left arm out |
| 4.5 to 5.5 | Back up into the wide V |
| 5.5 to 6.8 | The trunk leans 21 degrees left under the plane (in place of the video's fold over the head) |
| 6.8 to 7.5 | Back upright; the left fist goes to the hip, elbow out |
| 7.5 on | Held up and out, looking up at it; a sway of 1.5 degrees every 3 s (13 s in all; the camera leaves at 10.4) |

- **Third version, measured on the 5-stud test body (391 frames):** the hand never nearer the head's middle than
  1.87 studs (head 1.12 wide; second version 1.56, first 0.87); seen from the front, hand and forearm never in
  front of the head, not even a head half as big again; feet move 0.06 studs at most; fastest joint 9 degrees a
  frame, fastest hand 6.6 studs a second.
- **Third version, in my Play recording on one real avatar (a small girl with big hair buns):** the start is calm
  and the plane is beside the face, never over it; the swoop to the right and the fist on the hip read like the
  video. **Still weaker than the video:** the raised arm looks bent and short, so the plane stays close to the hair
  (hand 0.8 to 0.9 head widths from the head's middle where the test kid has 1.8); in the lean to the left the
  plane touches the hair for about a second; in the ending the plane points out sideways, not up. Why the same
  joint turns give a shorter, more bent arm on that avatar than on the test kid is **not known** (next: read the
  avatar's own arm lengths and elbow angle in Play against `build`).
- **Timing is the video's, one to one.** The flying starts 2 s after 1st's light, not 4: with sounds, the
  runner-ups would get 2 quiet seconds, not 4. The start can be stretched if Alan wants (his call, with the sounds).
- **In the scene:** the Dev panel's "end: pilot" button (Studio only; `DevFirstEmote`, which "end: flick" now sets
  too) ends the match with it as 1st's emote, from the draft. A plane emote's first pose is held from the dark on
  (`held` in `WinnersCutscene`), the light sets it going; the plane starts side on to the room; it is in the hand
  from the dark on and fades with the kid; only the hand's own movement turns its nose (all seen in my recordings).
- **Not in yet:** its two whooshes (`firstSoundAt`, as Camera Flick), the upload and its id in the config.
- **To look at it:** restart Play; Dev: hangar, F8, "end: pilot".

Back to [HOME](../HOME.md).

## Book Kicker: shot card and Gemini prompts (2026-11-21; second prompt with Alan)
The next emote after Toy Pilot; a 1st-place emote that covers the camera ([plan](../plan/WINNERS-CIRCLE-PLAN.md)). Nothing built.
- **First try, my idea, dropped by Alan:** a drop kick of a book held in the hands. His Gemini video did what the prompt asked (book at the waist, head tilt, kick at 5.5 to 6 s, fists on hips), but: "what I was thinking more was the character standing on the books, and then kicking one that they're standing on ... they jumped off the pedestal, then kicked the books, and most of them fly off to the side, but one flies towards the camera ... as it's flying towards the camera, it opens and smacks the camera and slides and then transitions". Seen in that video and kept as a lesson: a kick aimed at the camera points the leg at the lens, so it looks short; a kick reads from the side.
- **The feeling (my pick, not yet answered):** the cheeky kid who is done with schoolwork: unbothered, then one sudden hard kick.
- **Second prompt, my staging, rejected by Alan:** I had the kid turn side-on to the stack and kick the books off to the side (a kick reads best from the side). His look at that video: "what I wanted instead was for them to jump a little bit to the side of the books, still looking at the camera, and kick them so that they fly towards the camera and not off to the side". The kid faces the camera throughout.
- **Shot card, his staging** (seconds after 1st's light; my timings): 0 to 2 stands on the stack, fists on hips, looking down at the books (quiet: the runner-ups' sounds); 2 to 3 looks up at the camera; 3 to 4 hops down, landing a little to the side of the stack and just behind it, still facing the camera; 4 to 5 settles, weight onto the far foot; 5 to 5.5 draws the leg back; 5.5 to 6 kicks the stack at the camera: the books fly toward it, one opens, slaps flat on the lens and slides down, and what it uncovers is your desk.
- **The third Gemini prompt** (given to Alan): the mannequin on a stack of four dark books, one white shoe on the kicking foot, facing the camera for the whole shot.
- **The third prompt's video came through Alan's Gemini API key** (his go for one try; `GEMINI_API` in `.env`): `.planning/emotes/book-kicker-gemini-api-1.mp4`, 10 s, 1280x720, with sound. What my stills show: fists on hips on the stack, the head tilt, a crouch, then it gets down just behind the stack (more a step down than a hop to the side), kicks at about 5.5 to 6 s with the books flying at the camera, follow-through, fists on hips; it faces the camera throughout. Waits for his look.
- **Gemini by API, how it works** (looked up 2026-11-21, not from memory): the model is `gemini-omni-1.2-flash` (the key's own model list names it) and video is made through the Interactions API, `POST https://generativelanguage.googleapis.com/v1beta/interactions`, the key in the `x-goog-api-key` header, body `model`, `input` (the prompt) and `response_format` (`type` video, `duration` "3s" to "15s", `resolution` 360p to 4k, `aspect_ratio`); the MP4 comes back as base64 in a `video` part. One 10 s 720p video took about a minute and used 57,920 video tokens: about $0.70 at the listed $12 per million. Every call is Alan's go. No tool in the repo yet: one is worth adding when he asks for the second call.
- **Alan on that video: "good enough, build from it but you will have to make a better dismount".**
- **First build (2026-11-21; numbers only, nobody has seen it move, never run in Play).** Behind the Dev button "end: kicker" (`DevFirstEmote` = "BookKicker"), from the draft `BookKickerClip` in the open place's `Assets` (unsaved; the same clip is `assets/animations/emotes/book-kicker.rbxm`; bake again after a close without a save: `--bake=BookKicker:BookKickerClip:assets/animations/emotes/book-kicker.rbxm`).
  - **The video's stage was wrong, my mistake:** my prompts asked for a shin-high stack. 1st's real stack is six books, 0.77 of a winner's height tall and 0.56 wide: a tower up to the kid's shoulders. So the video gives the timing and the feeling; the poses are by numbers (`CUTS.BookKicker` in `tools/emote_clips.lua`; its comment has every moment). Check the stage's real sizes before writing a reference prompt.
  - **The body** (seconds after 1st's light): fists on hips, head bowed at the books; looks up, head tilted (2 to 2.9); crouches (3.0); jumps (3.35 to 3.85) 0.65 heights to the kid's left and 0.3 back, knees tucked; lands deep, stands up (4.6), glances at the tower; draws the right leg back (5.0 to 5.5) and kicks forwards and in (the foot reaches the tower at 5.62); leg held high to 6.6; fists on hips, chest out from 7.8. Faces the camera throughout.
  - **The scene** (`kickClip`, `kickProps`, `kickBooks`, `jolted` in `src/client/WinnersCutscene.luau`): the clip keeps the kid at one height; the scene drops them by their own stack's height during the jump (the clip's marks `HopFrom`, `HopTo`, `HopUp`). At the mark `Kick` all the books leave: five tumble past the lens on both sides; the top one is swapped for a book made of four plain blocks (covers in the top book's colour, cream pages), which opens on the way, lies flat on the lens after 0.45 s with a camera jolt, covers the picture for 0.45 s and slides down while the camera sets off home 0.95 s after the kick. No sounds yet.
  - **Measured on the test kid:** the standing foot does not move after landing; fastest joint 44 degrees a frame (the kick itself); the right arm stays 0.02 heights clear of the tower's side until the kick; both changed scripts compile in Studio.
  - **Not known, only Play shows:** whether the jump and landing read; whether the kid ends up half out of the spotlight (the cone is 0.76 heights to each side at the desk, the kid lands 0.65 out); how the kick looks from the front (the foot goes behind the tower's near corner); whether the swap to the block book shows; whether the pages fill the picture on every screen shape; real avatars' hop distance (Roblox scales it with the body).
  - **First run in Play (my muted recording, Alan's go; `.planning/emotes/book-kicker-first-run-cut.mp4`):** it runs end to end with no script error, on a bot's avatar (a small girl). Seen in stills: fists on hips on the tower; the jump and the landing beside it, facing the camera; the kick towards the tower; the books burst and the top one opens in flight, fills the picture with cream pages and a wide spine band, the report card appears over it and it slides away onto the camera's glide home. **Flaws seen:** the tower is taller than that kid (books are sized for a full-height winner; she is short), so it reads as kicking a tower, not a pile; she lands outside the spotlight's beam (still lit, but standing in the dark beside it); the three name plates stay drawn over the book on the lens; the open book is plain; the five other books are on screen only for a few frames. Not judged from stills: how the jump and the kick feel in motion. **Alan's notes** ([playtest](../playtests/2026-11-21-book-kicker-first-run.md)): the tall tower and the five quick books are fine; she must land closer, in the light, with the foot's tip going behind the stack ("it looks like she's kicking the air"); no name plates over the book; scribbled pages; sound once the look is right.
  - **The open book is plain blocks** because nothing better is loaded; a proper open-book model or page picture is a later choice of Alan's.
- **Second build (2026-11-21): his three fixes; numbers only, nobody has seen it move.**
  - **Why the first landing failed** (frames of the first recording): the clip moved the kid 0.65 heights sideways and the short winner still landed about 0.59 out (Roblox shrinks a clip's moves with the body, by less than her legs were shorter), while the stack and the beam keep their size: her foot stopped short of the stack. The beam's bright part is only about 0.45 heights to each side (the cone fades to its edge at 0.76).
  - **The scene now moves the kid, the clip does not** (`kickLanding` in `WinnersCutscene`; the clip stands on one spot): to their left by 0.14 + 0.43 x legs, at most 0.45, and back by 0.3 + 0.17 x legs, in winner heights from the stack's middle; legs = the avatar's hip height against the test kid's (0.423 heights). From the clip's own numbers: at the kick the foot's tip is 0.43 to the right of the kid's middle and 0.25 in front; the stack's side is 0.26 out, its back 0.28 behind. So the tip ends at least 0.12 behind the stack's side and reaches its back as the books go; the trunk stays behind the stack's back. They move out fast and then drop (sideways eased out, cubed), so the legs pass the stack's back corner above it.
  - **Checked by numbers on the test kid** (`--run`, no pictures): the foot is 0.08 behind the stack's side while standing, 0.22 at 5.60 s and touches its back at 5.63 s (the books go at 5.62); before the kick nothing goes into the stack except a shin's box corner for one frame of the jump (0.07 on a loose box). The landing arm now swings back (forwards it went 0.19 into the tower). Standing, the trunk is 0.25 to 0.65 out: at the edge of the bright part, not in its middle; closer would hide the kid behind the stack. If Alan wants them in the middle of the light, the lamp has to follow the jump (a new mechanic: his OK).
  - **Name plates:** hidden from 0.6 of the open book's flight to the lens (0.27 s after the kick) until the scene leaves; Book Kicker only.
  - **Pages:** rows of joined-up handwriting that says nothing (`scribbled`): Path2D strokes on a SurfaceGui on each page, about 170 strokes in 23 rows a page (strokes up from the line and back, a tall or hanging one now and then, a row left empty here and there), the same every time; switched on at the kick. No picture, no upload. The same from both ends, so which way up a page's canvas lies does not matter.
  - **Second run in Play (my muted recording, Alan's go; `.planning/emotes/book-kicker-second-run-cut.mp4`, the kick slowed four times in `book-kicker-second-run-kick-slow.mp4`, its frames in `book-kicker-second-run-kick-frames.jpg`):** no script error; the winner was the same short bot. Seen in the frames: she lands right beside the stack's corner, her near arm behind it, standing on the pool of light at the beam's edge; the kicking leg swings behind the stack and is hidden by it for about four frames before the books burst; no name plate over the book on the lens. **Flaws seen:** the first scribbles ran up the page instead of across it (on a top or bottom face a SurfaceGui's x runs along the part's z) and were about three times too big, reading as zigzags; rewritten the same hour (above; an offline drawing of the new rules: `.planning/emotes/book-kicker-pages-preview.png`), and those have not been seen in Play. The HUD's yellow "Menu" tag stays drawn over the book (and over the whole winners' moment): not changed, asked.
  - **Alan on the second run** ([playtest](../playtests/2026-11-21-book-kicker-second-run.md)): the dismount, the landing and the kick are good. The book on the lens is not: "lands perfectly in line ... should be kind of tilted ... kind of blurry ... out of focus".
  - **The book on the lens, third version (same day):** it ends turned 11 degrees in the picture, one side 5 degrees nearer, its spine 0.09 of its width and 0.05 of its height off the middle (`KICK_ROLL`, `KICK_LEAN`, `KICK_OFF`), and nearer the lens (`KICK_FILL` 0.68 of the just-filling distance, was 0.9) so that turned it still covers the whole picture: worked out for 4:3, 16:9, a phone and Alan's wide Studio window.
  - **Third run in Play (my muted recording, Alan's go; `.planning/emotes/book-kicker-third-run-cut.mp4`):** no script error. The book lands tilted and off the middle and covers the picture; the pages read as rows of handwriting across the page. **The blur failed:** a first try used the scene's `DepthOfFieldEffect` near blur (0 to 1 over the flight, the sharp range drawn in to 4.9 studs around winners 19 studs away, the book 1.8 studs from the lens): the values were set and the pages stayed perfectly sharp. Taken out again.
  - **Out of focus, second try:** a `BlurEffect` on the camera (`WinnersLens`) blurs the whole picture; name plates and other screen pieces are not blurred by it. Strength options for Alan, drawn on the third run's real frame with a plain Gaussian blur: `.planning/emotes/book-kicker-blur-options.jpg` (A light, B medium, C heavy). **Alan: "it should get blurrier as it gets closer to the camera so starts with now then ends in C when its on the camera".** So the blur follows the book's nearness as a lens would (by 1 / distance; the book ends at `KICK_NEAR` 0.1 of the winners' distance): 7% of full a quarter of the way through the flight, 23% at half, 50% at 0.7, 81% at 0.85, full on the lens (`KICK_BLUR` 0.025 of the screen's height: 20 px on an 800 px tall window, which in the recording looks like the picture's C), and it clears over 0.45 s as the book slides off.
  - **The "Menu" tag** (Alan: "yes hide the menu"): hidden with the name plates, from 0.6 of the book's flight until it has slid off, through the attribute `LensCovered` on `ReplicatedStorage.FlyFightPaper`, which `MenuController` reads.
  - **Fourth run in Play (my muted recording, Alan's go; `.planning/emotes/book-kicker-fourth-run-cut.mp4`):** no script error. Sharp at the kick, softer as the book comes, heavily blurred and tilted on the lens with no Menu tag and no name plate; it clears as the book slides off and the report card over it is sharp. Waits for Alan's look.
  - **Alan on the fourth run: "yes do the sound next, tell me the price"** (he named nothing still off in the look).
  - **Sound: the plan and the price** (Google's pages read 2026-11-21, not from memory): `gemini-omni-1.2-flash` takes a video as input ("up to 15s for editing"; attached through the Files API or as inline base64 `video/mp4`: check the live page for the exact field names) and always returns a video with its own sound; there is no sound-only output and no sound-effects model on the list (only Lyria, music). So: send the fourth run's 9.3 s cut, ask for the kick, the books flying, the books hitting the ground and a smack on the lens, keep only the returned sound and lay it under our recording. Price: output video $12 per million tokens, 1,931 tokens a second at 360p (about 23 cents for 10 s; 720p is 5,792 a second, about 70 cents); input video $1.50 per million, its token count per second not published (my worst case 9 cents); no free tier. **Alan: "go for up to three tries"** at about 25 to 35 cents each, about $1 at most. No call made yet. Free fallback: the sounds in `.planning/emotes/book-kicker-gemini-api-1.mp4`.
  - **Sound, first try (2026-11-21; `tools/gemini_video.py`, about $0.29: 52,128 input video tokens, 17,379 output):** the model refuses a clip whose length is not the whole number of seconds asked for ("Edited video duration (9.208s) does not match config duration (9s)"; two refused calls, nothing made), so the cut goes in trimmed to exactly 9.0 s at a fixed 30 frames a second (`-vf fps=30 -t 9`). It kept our picture's timing (cropped to 16:9, 640x360) and returned sound at our moments, measured by loudness, not heard by me: the landing at 2.75 s (very quiet), the kick and flutter from 4.30 s, the loudest of them at 4.75 s as the book reaches the lens, two smaller sounds at 5.55 and 6.1 s. It also added a loud sound at 7.1 s that nobody asked for (the menu's Launch button pops in there): cut. The whole track was very quiet (peak -26 dB), so it is raised by 22 dB. Laid under our recording: `.planning/emotes/book-kicker-sound-try1.mp4` (Gemini's own file: `book-kicker-sound-try1-gemini-raw.mp4`). Waits for Alan's ears.
  - **Alan on the first try:** "the sound at the end become jumbled together. There's like a really high pitched sound ... I can't hear ... the actual sound of the foot connecting with the book. That's the most important sound ... it ends up just sounding like rustled leaves ... when the foot connects to the books, I should hear a thud." What the sound's pitch picture shows: no sharp hit at the kick (4.25 s), only a long paper rustle from 4.35 s; the high sound is a steady tone at about 2.5 kHz from 5.65 to 6.1 s, the "rubbery paper squeak" my prompt asked for. **Lessons:** ask for few, short, separate sounds and name the one that matters most; never ask for a squeak or a flutter; check the pitch picture (`showspectrumpic`) for a sharp bright line at the hit before sending.
  - **Second try (about $0.29; prompt: four sounds only, the kick thud the loudest) and a free version, both waiting for Alan's ears.** Gemini made a clean deep thud but put it at 5.65 s, 1.4 s after the kick, with a landing thump at 2.8 s and two flat hits at 4.7 and 4.8 s: it does not place sounds on our moments, so the sounds are cut out and placed by hand (the kick at 4.25 s of the cut, the book on the lens at 4.58 s, the landing at 2.73 s). **B** `.planning/emotes/book-kicker-sound-B-gemini-try2.mp4`: try 2's landing, thud and two hits, moved. **A** `.planning/emotes/book-kicker-sound-A-from-reference.mp4`: the same three moments from the first reference video's sound (`book-kicker-gemini-api-1.mp4`: thud at 5.93 s, hits at 6.42 and 6.54 s, a step at 4.67 s), free. Gemini's spend so far: about $0.58 of the $1; one try left.
  - **Alan on A and B: "B is closer".** A is dropped. "Closer" is not "right": what is still off in B is asked, not guessed.
  - **Alan, asked what is still off in B: "Nothing, B is right".** The sound is approved: a soft landing thump, the kick thud on the frame the foot meets the books, the book hitting the lens 0.33 s after it (two flat hits 0.1 s apart), then silence. Cut from try 2 into two files, not uploaded, not in the game: `assets/audio/emotes/book-kicker-landing.ogg` (0.25 s; the thump starts 0.025 s in) and `assets/audio/emotes/book-kicker-kick.ogg` (0.65 s; the thud starts 0.025 s in, the lens hits follow in the same file, so one play at the mark `Kick` keeps the gap he approved). In the recording he heard, the landing thump is 1.52 s before the kick. The third Gemini try was not used.
  - **Into the game (2026-11-21; Alan: "go 1"): three free uploads and the sounds wired in; not yet heard or seen in Play.**
    - **The clip:** `rbxassetid://73358935726911` (approved at once), in `rounds.emote_clips`; its marks in `rounds.book_kicker` (HopFrom 3.35, HopTo 3.85, HopUp 0.1, Kick 5.62: the draft's own). Checked in Edit: the upload loads with the draft's 301 keys, 4,816 poses and 10 s, and the same pose sums. The draft is deleted from the open place, so Studio plays the upload.
    - **The sounds:** `tools/upload_texture.py --audio` (new), Roblox's answers in `assets/audio/emotes/uploads/`: the landing `rbxassetid://111776144912962`, the kick with the lens hit `rbxassetid://122025266957849`. Both came back "Reviewing" (the animations were approved at once; a sound waits for Roblox's review and may be silent until it passes). In `src/client/Audio.luau` as `kickLand` (volume 0.6, Toy Pilot's quiet level) and `kickThud` (1.6, as loud as Camera Flick's smack: it has to stand over the winners' music, and Alan called it the most important sound; **my number, not his: he was told "a quiet level" before the go**).
    - **When they play** (`kickBooks`): `kickLand` when the jump ends (the feet reach the floor, the mark `HopTo`); `kickThud` at the mark `Kick`. The runner-ups' sounds stop before the landing's thump (`firstSoundAt`, the same rule as the other 1st-place emotes).
    - **The landing was late in the MP4 Alan approved, my mistake:** the feet touch the floor at 2.50 s of the cut (frames) and I had laid the thump at 2.73 s. In the game it is on the feet. If he liked it late: one delay to add.
    - **Studio:** Rojo's plugin is still disconnected, so `Audio`, `WinnersCutscene` and `Generated.Gameplay` were copied in with `tools/studio_push.py`; the place is not saved.
  - **Studio without Rojo:** the Assistant's HTTP allowlist now refuses `127.0.0.1`, so the http.server recipe is dead; `tools/studio_push.py` copies a script through Studio's MCP instead.
