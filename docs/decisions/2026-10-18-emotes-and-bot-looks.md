# Emotes with the paper plane; bots that look like real players

**Decided:** 2026-10-18 (Alan)  
**Status:** in force; order of work agreed, nothing built yet

## Decision
- **Order:** bots first, emotes next. Next: modern-looking bot avatars so the winners' cutscene can be judged with
  real-looking players. Then one prototype prop emote (the plane flying around the head) to prove the workflow.
  The emote shop itself waits for the shop stage.
- **Bot looks:** bots should be impossible to tell from real players. Today's look (classic shirt and pants) is
  years out of date. Dress them in today's styles from Roblox catalog items (newer heads with moving faces, 3D
  layered jackets and hoodies, popular hair); NPCs may wear any catalog item without buying it. Never copy a real
  player's avatar or name (VISION: no forged accounts). Bot names already follow real player styles; keep them.
- **Emote ideas (Alan's, to sell later):** the kid jumps on the desk holding the plane they used most that match and
  flies it around their head like a kid would; slams the plane down and leaps like a football touchdown; throws the
  plane and it circles them; throws it and it flies off, comes straight at the camera and "crashes" into it as the
  camera pulls back; plus ordinary dances. They should look cool enough that players want to buy them.
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
