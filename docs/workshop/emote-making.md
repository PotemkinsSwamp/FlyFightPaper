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
  - Looking at a web video frame by frame without downloading it: in Chrome, a script seeks the page's own video
    and draws each moment into a grid laid over the page (cropped to the character, time stamped), and one
    screenshot shows 30 moments.
  - **Half-hearted wave by weight.** The wave plays at 0.6 speed and 0.65 weight: an Action clip under full weight
    lets the standing idle show through, so the arm only comes part of the way up and the lean is smaller.
  - Steps now end on the clip's own time (five claps = 2.5 clip seconds), not on a clock.
- Roblox-made mood clips that exist, for posture if the retiming alone does not carry the feeling (ids checked in
  Edit, not yet looked at): `Emote_Bored` 10713992055 (a candidate for the standing rest), `Emote_Agree`
  10713954623 (a nod), `Emote_Beckon` 10713984554 (what they hold: below).

## Nap and Next One: what is left (2026-11-20)
- **Nap**: a cut from Nap B retimed to a sleepy tempo (slow sink about 2.5 s, held asleep with breathing, a quick
  jerk up, a look around, sinking again), the jerk also fired by 1st's light; three paper Z's from the head; the
  kid posed in the clip's first frame while still dark; the sitting-height check on other bodies.
- **Next One**: Next One A's sitting posture, the head looking down about 25 degrees, the left hand's three folds
  posed by numbers, a sheet that becomes a half-folded sheet and then a plain white plane on the right hand's grip
  point (swapped at marks on the clip), then a raise-and-look as the ending.

Back to [HOME](../HOME.md).
