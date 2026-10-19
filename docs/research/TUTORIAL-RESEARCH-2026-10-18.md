# Tutorial research 2026-10-18

How most games teach new players, so ours feels familiar. Written for the [tutorial plan](../plan/TUTORIAL-PLAN.md).
Caveat: the Roblox docs and Microsoft Flight Simulator are solid sources; the rest are practitioner blogs that agree
with each other but aren't hard data. Nothing reliable was found on War Thunder's, Call of Duty's Create-a-Class or
Roblox plane games' tutorials.

## What most games do
- **A short first lesson, then separate optional ones.** The first one gets you doing the core thing (fly, shoot)
  right away. Everything else is split by topic (controls, combat, loadout) and can be replayed from a menu.
  Flight Simulator has 22 training flights, one skill each; Star Wars Squadrons keeps practice in its menu.
- **One thing per step, done, not read.** Each step asks for one action and waits until you do it, in a safe place
  (harmless targets before real danger).
- **The goal stays on screen until it's done**, often with a count ("Hit the targets 1/3"), and you get an instant
  tick, sound or effect when it's done. Steps move on by themselves when the action is done; a Continue button only
  on pure "look at this" steps.
- **Point at things in the world**: a big marker or arrow on the target, a trail to follow. Players notice these more
  than text. Show the key or button as a picture with a tiny word (works for kids who read slowly).
- **Menus are taught with a spotlight** ("coach marks"): everything dims except one button, an arrow points at it,
  one short line says what it does, and the step waits until you click it. Keep each run short; always show Skip.
- **Hint when stuck**: if most players find something in 10 seconds, light it up at 11.
- **Skip for experienced players; replay any time from the menu.** Each hint shown once, only to those who need it.
- **Teach late things later**: secondary systems are taught the first time the player meets them (in the match, the
  first time they open a menu), not all up front.

## Common mistakes
- Walls of text; a list of every control up front; teaching everything before the player has tried anything.
- A long forced tutorial before the fun; no skip.
- Telling the player to do something that isn't on screen yet (our "shoot the paper target" note with no target
  in view is exactly this).
- Several things at once; no feedback after the action.
- Steps that can get stuck if the player does things out of order (every new player hits a tutorial bug).
- Evasion is the part flight games teach worst (Ace Combat players complain); worth its own short step.

## Roblox specifics
- Roblox's onboarding guide: visual pointers, tutorials triggered by normal play, timed hints.
- A private tutorial server is normal: reserve a server and teleport the player there; teleports can fail, so retry
  and have a fallback. Teleporting doesn't work in Studio Play, so the real move is only testable after a publish.

## Sources
- https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques
- https://create.roblox.com/docs/en-us/projects/teleport.md
- https://gdevelop.io/blog/improve-game-tutorials
- https://chameleon.io/patterns/coachmarks
- https://www.wayline.io/blog/designing-effective-game-tutorials-and-onboarding
- https://www.wayline.io/blog/tutorial-ux-design-tips
- https://www.wayline.io/blog/tutorial-trap-overly-long-intros-ruining-games
- https://bugnet.io/blog/common-tutorial-design-mistakes
- https://forums.flightsimulator.com/t/425795
- https://pcgamesn.com/star-wars-squadrons/tips-guide

Back to [HOME](../HOME.md)
