# A held plane stays in the hand; odd bodies are an accepted loss

**Decided:** 2026-11-21 (Alan, after seeing the other way in Play)
**Status:** in force. The sliding-plane rule built the same day is taken out again; the code is as it was before it.

## Decision
- **The plane touches the hand, always**: "It has to be touching the hand. It has to be."
- **On oddly shaped avatars the plane may be hard to see, and that is accepted**: "we're just gonna have to take the L ... for character models that are oddly shaped ... it might just be hard to see the paper airplane ... I think we just have to take a loss here".
- **No neutral body on the podium**: "people won't like it, because then people won't see their character model".
- **No characters to buy that come with a benefit**: "I don't like that idea either. That's another system. That's scope creep."

## Why it came up
Alan played Toy Pilot's fourth version as 1st on his own avatar, a stout little dog in a superhero costume: "you couldn't see the paper airplane because the model was too wide ... you could barely see any of the emote because the arm is so small ... I'm worried about character models and how this can work".

Measured in Edit on his account's avatar against a plain blocky kid:

| | Plain kid | His avatar |
|---|---|---|
| Body height | 5.5 studs | 3.5 studs |
| Arm, shoulder to grip | 2.0 studs | 0.65 studs |
| Hand out sideways, past the body's edge | 2.0 studs | 0.3 studs |
| Hand straight up | 0.6 studs above the head | stops half-way up the head |

The shoulder sits inside the head's width and the plane (1.5 studs) is more than twice the arm: no arm pose carries it clear of that body.

## Tried and rejected
- **The plane slides clear of the body** (Claude's recommendation, built on his go, commit `f1abdbb4`): seen from the camera, a plane over the body or over what is worn on the head slid out to the edge, so on a short-armed body it glided beyond the hand. His look in Play: "No, I don't think so ... It has to be touching the hand."
- **A bigger plane on small bodies:** not built; its tail would still be inside the head.

## What follows
- Emotes are judged on normally shaped avatars. Nothing is reworked for a short-armed body; the same limit holds for the runner-up emotes.
