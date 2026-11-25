# Every avatar's 3D body clothing comes off, so the emotes can be seen

**Decided:** 2026-11-25 (Alan, before his first look at the Emotes page)
**Status:** Built the same day; the rule checked on his own avatar's list in his running Play (the jacket goes, the hair
and shoes stay); not yet seen by him (it needs a Play restart). The unit test was not run (it needs Play).

## Decision
- **The game slims the character and keeps who they are** ("The clothing I wear adds so much bulk that it makes it
  hard to see the emotes. When I join some games, it removes that and makes my character kind of skinny, but still
  maintains what my character looks like. Our game could do that as well").
- **Everywhere we show the kid** ("It should be everywhere where we show the kid"): at the desk, on the winners'
  stand and on the emote shop's TV.
- **Step 1 only** ("I think we stop at step 1"): the 3D clothing comes off. Not chosen: swapping the body for
  Roblox's plain one (step 2) and trimming big accessories (step 3).
- **Before the Emotes page look**, with his own avatar as the test ("I can't check the emotes because my character's
  body is too large").

## What it means in the game
- Off: the 3D ("layered") clothing that wraps the body: jackets, sweaters, shirts, T-shirts, pants, shorts, skirts.
- Kept: the body itself, head, face, hair, shoes, hats and other accessories, skin colours, painted-on shirts and
  pants.
- His avatar, measured 2026-11-25: one 3D jacket 5.4 studs wide on a torso 1.1 studs wide; a slim body with arms
  of normal length under it.

## Claude's calls, his to reverse
- **Hair and shoes stay** although Roblox files them as 3D clothing too: his hair is one, and without it he would
  not look like himself.
- **Bots too**: a cast bot in a big jacket would hide its emote the same way.
- **Every player's copy is now built on the standard R15 skeleton**, also for the few who wear the old R6 body: the
  slimming works on the avatar's list, and building from a list needs the skeleton named. Our emotes only play on
  R15, so those players now get our emotes instead of Roblox's dances.

## Where
`AvatarLook.trim` in `src/shared/AvatarLook.luau`, used by `src/server/AvatarService.luau` (the kid at the desk, which
the winners' stand copies) and `Cutscene.tv.avatar` in `src/client/WinnersCutscene.luau` (the TV). How other games do
it: Roblox's own [Avatar Settings](https://create.roblox.com/docs/studio/avatar-settings) window.
