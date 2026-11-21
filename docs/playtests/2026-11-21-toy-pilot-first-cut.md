# Toy Pilot: the first two cuts rejected, the third from a Play recording

**When:** 2026-11-21, Alan in Studio Play (Dev: hangar, F8, "end: pilot"), right after [the cut](../workshop/emote-making.md) was built

## What he said, and what changed
| Alan | What changed |
|---|---|
| "it doesn't work at all for the models ... it ends up bringing their hand into like their face in an awkward position ... it just looks very awkward" | The cut is rejected as a whole; nothing changed yet. It stays behind "end: pilot" until its replacement is built. |
| He looked for a concept video and attached one (a boy running across a field with a toy plane); offered to make a reference video with Gemini from a prompt of mine: "something basic, just like a skeleton model or like a child playing with the paper airplane" | A prompt written for him. The next cut is built from that reference, not from another blind try. |

## What the attached video shows (Claude's reading, from 16 stills)
The arm is stretched out to the side the whole time and the plane stays a full arm away from the head, at shoulder
to head height; the wrist banks the plane; the body leans and turns with it; the other arm swings loose; it ends
with the plane pushed up overhead at full stretch. The hand never comes near the face. He runs; our winner stands
on a desk.

## Why the first cut failed (Claude's reading)
Both parts I chose put the hand at the head: the admiring holds it at chest height under a bowed head, and the swoop
turns round in front of the face (my pick, the "widest" point). On the 5-stud test body the numbers looked clear; on
real avatars, with their bigger heads, the hand lands in the face. Numbers on one test body do not show this.

## Second look, the same day: the cut traced from his Gemini video
| Alan | What changed |
|---|---|
| Of the video Gemini made from the prompt: "this should actually be perfect"; "from this point on, if we need like reference videos, let's just go through Gemini Omni" | The cut rebuilt from the video's traced hand path (`tools/emote_trace.py`). Reference videos by Gemini is the standing way. |
| Of that cut in Play: "it still looks very much off ... it looks very different ... it kind of struggles with every character ... in the first second, it's extremely rushed. It doesn't seem very like calm, collected" | He asked for a Play of mine compared frame by frame with the video. Done (two muted runs, recorded with the Studio link's video capture). |

## What the recording showed (Claude, [picture](../../.planning/emotes/toy-pilot-play-vs-reference.jpg))
| In the video | In Play, second version | Cause | Third version |
|---|---|---|---|
| Stands holding the plane up beside the head, calm, for 2 s | At the light the arm snaps up from the side in 0.2 s; then hand and plane sit in front of the face | The emote started at the light with a 0.3 s blend; an arm that looks short in the picture was pointed at the camera | The first pose is held from the dark on; a short-looking arm is bent, and the hand is kept out to the side |
| Long straight arm, plane far from the head | Hand and plane at the hair whenever the arm is up | Roblox arms are short and heads big; I had allowed the arm almost straight up beside the head | A raised arm is a wide V (40 degrees out at least) |
| Folds the arm over the head to fly the plane across | Arm stuck to the side of the head, over part of the face | A blocky arm cannot fold over a head | The arm stays in the V; the trunk leans left under the plane |
| Ends arm high, fist on the hip, elbow out | Plane lying on top of the head; left hand in front of the hips | As above; the "fist on the hip" was a generated clip's pose | V again; the fist put at the side of the hips by numbers, elbow straight out |

Still weaker than the video after the fixes, on the one avatar recorded (a small girl with big hair buns): the raised
arm looks bent and short, so the plane stays close to the hair; it touches the hair for about a second in the lean
to the left; in the ending the plane points sideways, not up.

## Third look, the same day
| Alan | What changed |
|---|---|
| Of the third version in Play: "better, still off" (picked from four answers); what is still off: the **raised arm is cramped** (bent and short, the plane close to the head instead of high and far) and the **ending pose** (arm not high enough, plane pointing sideways). Not picked: the lean to the left, the timing. | The calm start, the lean to the left and the timing stand. |
| "when they put their arm up ... they're not extending their arm up enough. It doesn't look like a victory like thing. It looks like they're just holding the paper airplane. Their arm is not extended high enough." | Cause found in the cut, not in Play: the arm-bending step never let an arm past 0.95 of its length, which leaves the elbow bent 36 degrees, and my wide V held the ending 40 degrees out to the side. Fourth version: a raised arm is really straight; the ending closes to the video's high arm (about 18 degrees off straight up) after a short pull-in and a push straight up, so the plane ends nose up. Measured only (hand 1.0 studs over the head's middle on the test body, was 0.7); **not seen in Play by anyone**. |

Back to [HOME](../HOME.md).

## Fourth and fifth looks: his own avatar hides the plane; he takes the loss (same day)
- **Fourth version, as 1st on his own avatar** (a stout little dog in a superhero costume): "you couldn't see the paper airplane because the model was too wide ... you could barely see any of the emote because the arm is so small ... I'm worried about character models and how this can work".
- **With the plane slid clear of the body** (built on his go): "No, I don't think so ... It has to be touching the hand ... we're just gonna have to take the L". Taken out again.
- No verdict yet on the raised arm or the ending on a normally shaped body.
- Measurements and what he decided: [a held plane stays in the hand](../decisions/2026-11-21-plane-stays-in-the-hand.md).

## Sixth look: "it looks fine, lets move on" (same day)
The fourth version, with the plane back in the hand: approved as it is. Next, on his word: its sounds.

## The whoosh: his pick by ear (same day)
"whoosh 2, timing is fine" (Airy Pass By Windy Whoosh 4, at 3.0 s and 4.5 s after the light). And: "This is going to be a subtle sound. Because if it's loud, that's going to be stupid ... timed with them actually whooshing it down ... It's got to be timed with that perfectly ... this emote isn't going to have much like sound effects. This is practically it, and that's it." Changed: the other two candidates and the stepping button deleted; the whoosh turned down from 1.4 to 0.6 (my number, not yet heard by him); no third sound.
