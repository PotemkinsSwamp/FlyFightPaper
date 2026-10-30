# Phone aim options: staying on a plane's tail on a phone

Research for Alan's ruling (2026-10-29). Nothing gets built until he picks. Where this came from:
[playtest note 7](../playtests/2026-10-29-young-testers-tutorial.md) ("like catching a fly with chopsticks").

## What the player sees today
Planes fly at one speed (Boost is the only change). On a phone the screen is small, enemies look small and race
past, and with no way to slow down you overshoot a slower plane. Phones already get aim help (the touch aim help in `FlightController`). Alan says more
aim help is not the answer.

## What other games do
Sources marked (read) were opened; (lead) came from search results only. Mobile flight games' own control pages
could not be found, so those details come from reviews and guides.

| Idea | Who does it | Source |
|---|---|---|
| **Brake / throttle**: slow down to stay behind | Ace Combat 7 (L2 brake; brake while turning = tighter "high-G" turn); Galaxy on Fire 3 Manticore, mobile (stick down = brake); Sky Gamblers: Rise of Glory, mobile (speed pad); Sky Warriors, mobile (throttle slider) | [Push Square AC7 tips](https://www.pushsquare.com/news/2019/02/guide_ace_combat_7_skies_unknown_-_tips_and_tricks_for_beginners) (read); [Gamezebo GoF3](https://www.gamezebo.com/walkthroughs/galaxy-on-fire-3-manticore-tips-cheats-and-strategies/) (read); [Pocket Gamer Sky Gamblers](https://www.pocketgamer.com/sky-gamblers-rise-of-glory/review) (read); [StrategyWiki Sky Warriors](https://strategywiki.org/wiki/Sky_Warriors/Controls) (lead) |
| **Speed-matching behind a target**: the game sets your speed to the enemy's | Rebel Galaxy Outlaw "autopursuit": lock on and hold a trigger, your ship follows at a matching speed (an optional assist; the designers wrote that it stops players constantly losing targets) | [Game Developer, designing RGO's combat](https://gamedeveloper.com/design/designing-the-satisfying-space-combat-of-i-rebel-galaxy-outlaw-i-) (read); [Wikipedia](https://en.wikipedia.org/wiki/Rebel_Galaxy_Outlaw) (read) |
| **Tail mode**: get behind, press a button, the camera closes in and the game partly flies | Ace Combat: Assault Horizon "Dogfight Mode" (holds you within ~500 ft; you still aim); the 3DS version fills a meter, then a cut-scene puts you behind | [Ace Combat wiki](https://acecombat.wiki.gg/wiki/Dogfight_Mode) (read); [Nintendo Life](https://www.nintendolife.com/games/3ds/ace_combat_assault_horizon_legacy/review) (read) |
| **Target camera**: the camera keeps the enemy on screen | Ace Combat 7 (hold a button); War Thunder Mobile ("follow selected target" camera) | Push Square above; [War Thunder Mobile guide](https://warshipsgames.com/war-thunder-mobile-controls-guide/) (read, unofficial) |
| **Weapons that need less aim** | Auto-fire and auto-lock missiles: Galaxy on Fire 3, Sky Warriors; Modern Combat 5 (shooter) | Gamezebo above; [Game Developer, FPS on mobile](https://www.gamedeveloper.com/game-platforms/ux-deep-dive-painful-reality-of-building-fps-experiences-on-mobile---part-1) (read) |

Not found anywhere: zoom on target, or slow motion while tailing. A warning case: Star Fox Zero's lock-on camera
split the player's attention and reviewers hated it
([Nintendo Life](https://www.nintendolife.com/news/2016/04/talking_point_the_great_star_fox_zero_controls_debate_highlights_important_lessons), read).

## The options for us
1. **Brake (hold)**: a BRAKE button on phones (a key on PC, e.g. S or Ctrl), about 60% speed while held, turns a
   bit tighter, drains Lift faster (so it can't be held all match). The most common answer; it's player skill, not
   aim help. Cost: one more button on a small screen. Small build.
2. **Gentle speed-match**: close behind an enemy (say under 200 studs, it ahead of your nose), your speed eases down
   toward theirs; no button. The fix for exactly our problem (RGO), but the game decides for you, and it is an
   assist (RGO keeps it for easy settings). Small build.
3. **Tail mode** (Assault Horizon): a button when behind; close camera, the game helps fly. Big build, feels
   scripted; doesn't fit a quick paper-plane game.
4. **Target camera**: helps find a plane, not stay behind it; can confuse which way you're flying. Not recommended.
5. **Easier phone weapons** (auto-lock): this is more aim help, which Alan ruled out.

## Recommendation
**Option 1, the brake, on every device**, tested by Alan on his phone. If overshooting is still the problem after
that, add option 2 on top, phones only or as a setting. Both are small and can be undone easily.

## Alan's answers
Brake on PC (Space) and automatic speed matching on phones, both to try out: [decision](../decisions/2026-10-29-brake-and-phone-speed-match.md).
