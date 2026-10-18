# Emotes with the paper plane; bots that look like real players

**Decided:** 2026-10-18 (Alan)  
**Status:** in force; bot looks built 2026-10-18, emotes next

## Decision
- **Order:** bots first, emotes next. Next: modern-looking bot avatars so the winners' cutscene can be judged with
  real-looking players. Then one prototype prop emote (the plane flying around the head) to prove the workflow.
  The emote shop itself waits for the shop stage.
- **Bot looks:** bots should be impossible to tell from real players. Today's look (classic shirt and pants) is
  years out of date. Not by hand-dressing them (Alan: too slow, won't look real): first research how Roblox devs
  give NPCs real-player looks (plugins, Creator Store kits, whole catalog looks), bring Alan 2-3 options, he picks.
  **Picked (Alan, same day):** copy the look of random real players (lots of variety, nobody notices recycled
  bots). VISION only forbids forged accounts, so bots keep their own made-up names; only the outfit is borrowed.
  Rejected: catalog style sets and live bestseller mixes (random mixes looked messy in a test).
- **Emote ideas (Alan's, to sell later):** the kid jumps on the desk holding the plane they used most that match and
  flies it around their head like a kid would; slams the plane down and leaps like a football touchdown; throws the
  plane and it circles them; throws it and it flies off, comes straight at the camera and "crashes" into it as the
  camera pulls back; plus ordinary dances. They should look cool enough that players want to buy them.
- **Prototype verdict (Alan, 2026-10-18):** the arm-only plane emote (arm IK chasing a circle) looked lifeless;
  taken out. A kid moves the whole body: head and eyes follow the plane, hips twist, legs turn with it, the plane
  swoops in circles or S-shapes. No hand-keyed or arm-only emotes. Look first at animation tools that are not Adobe
  (Alan: too expensive, predatory contracts): Meshy text-to-motion (his existing credits), Uthana, DeepMotion
  SayMotion; Roblox video capture later. The scripted plane-in-hand part can be reused on a real animation.
- **How they get made:** body motion from a short video of a real person (Roblox's Animation capture) or free
  sources where Roblox lets us use them; hand-made keyframes only for simple moves. The plane is a prop attached to
  the hand; throws, circles and camera moves are scripted. Each animation is previewed in Studio with a temporary id,
  then uploaded through Open Cloud on Alan's go (free).

## Why
Alan: the cutscene looks good now, but it can only be judged with avatars that look like today's players, and the
point is that players can't tell bots apart. Plane-themed emotes fit the game and are something players would buy.

## Affects
- [Bots](../systems/bots.md) (looks) · [Modes and scoring](../systems/modes-and-scoring.md) (winners' cutscene) ·
  the shop stage in [MILESTONES](../plan/MILESTONES.md)

All decisions: [decisions](README.md)
