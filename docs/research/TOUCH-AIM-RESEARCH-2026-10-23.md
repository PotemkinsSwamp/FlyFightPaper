# Aim Help for Touch and Controller Players: how other games do it

Search quality was patchy. Studios almost never publish their real tuning numbers, and I found nothing public about aim help in mobile dogfight games. Where a claim comes only from a forum, a fan wiki or one news site, I say so. Where a number is our own guess, I say that too.

## The standard tools, in plain words

An "aim assist" is any code that quietly makes aiming easier. A "cone" here means an invisible wedge in front of your gun; help only works when an enemy is inside it.

- **Slowdown (also called friction or sticky targets).** Your turning gets slower while an enemy is near your crosshair, so small corrections are easier. Halopedia (a fan wiki) describes it as turn speed dropping when an enemy is within a radius of the reticle, and says it is for controllers only. https://www.halopedia.org/Aim_assist A 2025 research review says it can feel like a "sticky" patch, and can cause a sudden speed-up when you leave the target. https://bisec.metropolitan.ac.rs/wp-content/uploads/2026/04/Rad-19-Aim-Assistance-in-Video-Games.pdf
- **Pull (also called magnetism or target gravity).** The crosshair is gently dragged toward a nearby enemy. The same review says a strong pull makes players feel they are not the one aiming. (Review link above.)
- **Bullet magnetism (bent shots).** The crosshair does not move. Only the shot bends toward an enemy that is close to where you aimed. Destiny's wiki describes it as the cone-based part that works for both mouse and controller. https://d2.destinygamewiki.com/wiki/Aim_Assistance This is the same idea as our current "gun assist".
- **Bigger hit area (area cursor).** The shot counts as a hit if any part of a wider circle touches the enemy. (Review link above.)
- **Snap or lock-on.** A button or stick direction jumps the aim straight onto an enemy. The review calls this too obvious and powerful for competitive shooters. Halo's phone and tablet spin-offs used snap-to-target for touch and controller. (Halopedia and review links above.)
- **Auto-fire.** The gun fires by itself when the crosshair is on an enemy. Fortnite added it as an option on mobile in Season 5, so one thumb does not have to both aim and tap. https://www.gamespot.com/articles/fortnite-season-5-mobile-update-adds-autofire-here/1100-6460356/ A Roblox DevForum reply also suggested "aim-to-fire" for mobile. https://devforum.roblox.com/t/how-to-make-aim-assist/842957
- **Rotational (tracking) help.** A modern idea: the crosshair is nudged along with a moving enemy, so you do not have to chase it. Fortnite and Apex players call it "rotational aim assist". Treyarch said it is looking at making it start only when the stick is already moving toward the enemy (BO7, below). Fortnite detail comes from fan blogs, so treat it as anecdotal.

## Which ones are considered fair

- A set of university studies tested five tools in a 3D shooter. Bullet magnetism and the bigger hit area worked best across situations. Players barely noticed them. Target lock was too noticeable. The assists worked well on a plain shooting range but lost strength once real game clutter was added. https://scholar2.islandarchives.ca/islandora/object/ir%3A8974 (taken from a search summary; the page timed out) and the review above.
- The same research group made a game where help goes to whoever is behind, using bent shots and the wider hit area. Matches got closer and more fun. (Review link above.)
- Training with help did not stop people improving once it was removed, in one study. (Review link above.)
- Bent shots have a downside: they can hit the wrong enemy in a crowd. (Review link above.)

## How studios tune it (and what is public)

Almost nothing numeric is public. What I could confirm:

- **Apex Legends.** The controller strength was 0.6 in console-only lobbies. In PC lobbies it was cut from 0.4 to 0.3, about 25%. A Respawn designer said aim assist "is just too strong in these PC lobbies." Respawn says it will never remove it, because controller players need it. One outlet reports these numbers, so treat them as single-sourced. https://beebom.com/apex-legends-aim-assist-nerfed/amp/ Another Respawn developer said it is impossible to keep both inputs in perfect parity. https://ggrecon.com/articles/apex-legends-devs-are-investigating-potential-aim-assist-changes
- **Apex, how it works (fan analysis, not official).** A popular forum post says it mainly lowers turn speed when an enemy is near the crosshair, and that a close fast enemy can outrun your aim. https://forums.ea.com/discussions/apex-legends-feedback-en/2024-nerf-aim-assistrespawn/8719175/replies/8719184
- **Paladins (Hi-Rez).** Cut the minimum bullet magnetism by 25%, and lowered the maximum for fast-firing close-range heroes. https://www.gamersunchained.com/news/hirez-studios-is-making-big-changes-with-aim-assist-and-bullet-magnetism-in-paladins The common step size in real nerfs is therefore about 25% per change.
- **Overwatch (Blizzard, 2018).** Console help now looks at how you move the stick, and switches itself off if you are already tracking a target perfectly. It prefers the enemy you are already following, so a stranger crossing your path pulls less. A new "ease-in" slider, 0 to 1, ramps strength up over time (default 0.5). Blizzard suggested less ease-in for slow projectiles and more for instant-hit guns. https://eu.forums.blizzard.com/en/overwatch/t/console-aim-assist-updates/8697 No strength numbers were given.
- **Destiny 2.** The help is an invisible cone. A weapon stat widens its angle, another sets its depth, and during long bursts the cone shrinks toward a floor. No numbers. (Destiny wiki link above; it is a fan wiki and an older revision.)
- **Research defaults.** In the studies, the bigger hit circle grew with a "level" (radius = 10 px + 5 px per level) and bullet magnetism reached further per level (160 units per level). These are lab settings for pixel games, not shipping values. (Review link above.)
- **Touch shooter patent (Garena).** The helper checks if the crosshair is in a "targeting area" when you press fire, or up to 0.5 seconds earlier, then moves the aim to a set point on the enemy. Strength is highest on the first shot and falls the longer you hold fire. No angles are given. https://patents.google.com/patent/US12151161
- **A mobile shooter (War Robots).** Its first system used screen zones, which the team found subjective and hard to tune. It was replaced by a score per target that multiplies distance, health, how close to the crosshair, whether the target is behind cover, and shots already fired (which makes it "sticky"). Players can switch each factor on or off. Only 18% opted in, and about 80% of those who tried it kept it. No factor values are published. https://gamedeveloper.com/design/how-to-create-a-fair-auto-aiming-system-in-a-robot-shooter-
- **General advice (a blog, not a study).** Give more help to far or small targets and less to near, big ones, and always let the player's own input win, so help is a nudge and never a lock. https://bugnet.io/blog/how-to-fix-aim-assist-over-or-under-correcting
- **Where the GDC talk is.** Insomniac's 2013 talk on magnetism, centering and friction exists, but only the abstract is public. https://www.gdcvault.com/play/1017942/Techniques-for-Building-Aim-Assist

### How they measure it

- Treyarch (Black Ops 7 beta) said their match data showed controller players winning slightly more close-range fights and mouse players slightly more long-range fights. They plan to look at help strength across all ranges. No sample sizes or method were published. https://www.dexerto.com/call-of-duty/black-ops-7-warzone-aim-assist-changes-3272835 So the measure is wins by distance band, per input.
- War Robots used internal playtests until most testers were happy, then shipped as opt-in and watched which settings players kept. (War Robots link above.)
- The university studies measured the score gap between strong and weak players, with and without help. (Review link above.)
- I found no public hit-rate or time-to-kill parity targets from any studio.

## Flight and air-combat games

Thin evidence. I could not confirm aim-assist details for Ace Combat, Star Wars Squadrons, War Thunder Mobile or Roblox dogfight games.

- **War Thunder, mouse aim.** The mouse sets where you want to point and an "instructor" flies the plane there and keeps it level. This is the same family as our flight. It is described in player forums, not by Gaijin. https://forum.warthunder.com/t/can-we-talk-about-aircraft-coordination-in-wt-on-mouse-aim/69953 A player thread says the console ground-to-air assist only tracks a target; the player still has to lead it. https://forum.warthunder.com/t/if-console-players-are-going-to-get-ground-to-air-aim-assist-in-ground-rb-the-pc-players-should-get-it-too/45997 A TapTap review of War Thunder Mobile says aiming is workable and that there is aim assist, with no detail. https://www.taptap.io/es/post/6154400
- **Ace Combat 7.** A preview says missiles lock on by holding them near the middle of the view for a few seconds. The reviewer wanted a gun lead box and did not see one in that build. https://www.thesixthaxis.com/2017/02/13/taking-virtual-flight-in-ace-combat-7-skies-unknown-on-psvr/ We already have the lead marker.
- **Star Wars Squadrons.** Players report that only the lowest difficulty gives extra "gimbal" aim help (guns that swivel a little), and an EA rep said so on the forum. EA also asked for video evidence of a claimed bug. https://devtrackers.gg/sw-squadrons/p/2fefc249-multiplayer-aim-hacks-bug-not-really-hacks
- **Phone flight games.** Reviews of Sky Gamblers, Sky Warriors and Squadron 303 mention thumb sticks or tilt steering and self-levelling. I found no auto-aim details. https://strategywiki.org/wiki/Sky_Warriors/Controls and https://www.pocketgamer.com/sky-gamblers-rise-of-glory/review
- **Roblox.** The only DevForum thread I found is old, and its replies are speculative: nudge the camera toward a player under the crosshair, and fire automatically for mobile players. It also warns that exploiters can abuse any code that talks to the server. https://devforum.roblox.com/t/how-to-make-aim-assist/842957 I found no built-in Roblox aim-assist feature and no official aim-assist page.

## Fairness in mixed lobbies

- **Strength per input.** Apex runs a different strength by lobby type (0.6 console-only, 0.3 when PC players are present; Beebom link above). That is the clearest example of "less help when mouse players share the match".
- **Separate pools.** Fortnite announced input-based matchmaking in 2018: controller players against controller players, mouse against mouse, with party rules. https://www.legitreviews.com/?p=207508 That needs a big player base. A private Roblox game with 12 per match cannot do it, so strength has to be the fairness tool.
- **Help should shrink as you get better.** Blizzard (no help if you already track perfectly) and Treyarch (help only when the stick is already moving toward the enemy) both mean help reduces error and never beats a precise player. (Links above.)
- **Walls.** I found no official rule, but players complained loudly when help worked through walls, for example in Vanguard. https://www.charlieintel.com/call-of-duty-warzone/warzone-player-questions-aim-assist-through-walls-156688/ (player reports). War Robots counts "behind cover" as part of its target score. (Link above.)
- **Touch can be weaker than controller.** One Warzone Mobile clip test found controller aim assist stayed on target much better than touch aim assist. It is one player's test, and shows how hard it is to give touch enough help. https://www.ggrecon.com/articles/warzone-mobile-aim-assist-is-stronger-if-you-use-a-controller
- **Gentle strength is accepted.** The research says low to moderate help often goes unnoticed, and noticeable help is what feels like cheating. (Review link above.)

## Roblox: telling touch, mouse and gamepad apart

- Use `UserInputService.PreferredInput`. It has three values (Touch, KeyboardAndMouse, Gamepad) and changes during play with the player's latest actions. Read it once at start, then listen for changes. https://create.roblox.com/docs/input
- Do not use `TouchEnabled` to mean "phone". It is true on touch-screen laptops. The Roblox page says so. https://create.roblox.com/docs/input and the announcement https://devforum.roblox.com/t/full-release-introducing-preferredinput-and-improved-touch-capabilities/3750890
- Roblox says touch is the fallback. A phone with a Bluetooth mouse or gamepad should switch to that input. (Input page above.)
- The input page does not mention aim assist. The assist must be our own code.

## Recommendation for this game

Evidence is strongest for bent shots (our gun assist), so that leads. Slowdown is the most-copied helper for sticks. Tracking help is a reserve.

Start by fixing the base controls (`touch_stick_deg_per_s` = 110, `touch_stick_curve` = 1.5, `touch_stick_radius` = 0.13 already exist). Help that covers for a clumsy stick feels worse than a stick that is good by itself. This is our own judgment, not from a source.

All values are starting guesses. No studio publishes cone angles, so the "range to try" is our own. Step size is 25% per change, the size real nerfs used (Apex, Paladins).

**1. Wider bent-shot cone with a soft edge (use first).** Today's mouse cone is `gun_assist_deg` = 3 and snaps shots fully to the marker with a hard edge. For touch, widen it and fade the edge so there is no "6.1 degrees misses, 5.9 hits" cliff.

| Setting | Start | Try |
|---|---:|---|
| `touch_gun_assist_deg` | 6 | 4 to 9 |
| `controller_gun_assist_deg` | 4.5 | 3.5 to 7 |
| `touch_assist_inner_fraction` (full pull inside this share of the cone, fading to zero at the edge) | 0.5 | 0.3 to 0.7 |
| `touch_assist_max_range_studs` (no help beyond this) | 600 | 400 to 900 |
| `touch_assist_target_hold_s` (stay on the same enemy, no mid-burst switch) | 0.5 | 0.3 to 1.0 |

**2. Slowdown near an enemy (use second).** While the stick is pushed and the nose is near an enemy, the aim point turns slower, so small thumb corrections work. It never moves the aim on its own.

| Setting | Start | Try |
|---|---:|---|
| `touch_slowdown_cone_deg` | 8 | 5 to 12 |
| `touch_slowdown_scale` (1 = no slowdown) | 0.65 | 0.45 to 0.85 |
| `touch_slowdown_ease_in_s` (ramps in, from Blizzard's ease-in idea) | 0.25 | 0.1 to 0.5 |

Apply it to the aim point only, never to the plane's real turn rate, or players cannot escape. Skip it when the stick is pushed clearly away from the enemy (the player is choosing another target).

**3. Tracking help (build only if 1 and 2 miss the target in "How we'll tune it").** When the stick is pushed toward the enemy, the aim point follows a small share of the enemy's sideways motion.

| Setting | Start | Try |
|---|---:|---|
| `touch_track_pull` (share of enemy's apparent sideways speed) | 0.25 | 0 to 0.4 |
| `touch_track_stick_cone_deg` (stick must point within this of the enemy) | 45 | 30 to 70 |

Controller later uses the same three settings with its own `controller_*` values, as the approved plan says the stick input is shared.

**Optional, off by default:** an "auto-fire when the ring is on an enemy" toggle (Fortnite mobile has one). Do not turn it on for everyone. Skip snap/lock-on; research calls it too obvious.

**Choose the level from `PreferredInput`, not from a client claim alone.** Re-check on changes. A phone with a gamepad gets the controller level; a tablet with a mouse gets the mouse level. The server should cap any shot correction at the biggest cone we allow, so a PC player cannot get touch-sized help by saying they are on touch. I did not read how the server checks shots. The config has `input_aim_slack_deg` = 12; confirm it is larger than the biggest cone and that it is the actual ceiling.

**What must never happen**
- Help pulls or bends a shot to an enemy behind a building or wall. Use the same line-of-sight check as a normal shot, from the nose to the enemy.
- Help steers the plane itself, or leads it into a wall. It may only touch the aim point or the shot.
- Help beats a good mouse player. Touch with help must not out-hit a skilled mouse player at any distance band (the target numbers are below).
- Help is the same for everyone. Mouse players keep today's `gun_assist_deg` = 3 and get no slowdown.
- Help makes pencils (one-shot kills, 260 damage) nearly free at long range. Watch their numbers separately; if they run high, add `touch_assist_pencil_scale` (start 0.5).
- The HUD lies about the help. The red ring means "would hit without help" today. With a bigger cone, decide with Alan whether touch shows a second ring colour for "hit with help" so players learn what the game is doing.

## How we'll tune it

Our own method, built from how Treyarch (win rate by distance band) and Apex/Paladins (25% steps) tune. No source gives a ready recipe.

**Measures**
- **Hit rate** = hits divided by shots. **Time-to-fold** = seconds from first shot at a target until it folds (dies). Both split by distance band (150, 300 and 450 studs; the baselines in `docs/systems/weapons.md` show pellets hit 99%, 88% and 61% with a perfect dot, so a band already has a ceiling) and by target type (straight, circling, jinking from the Range's Maneuvers preset).
- **Help share** = of all hits, the share that would have been misses without the help. This shows how much of the result is the help and not the player.

**Step 1: noisy proxy pilots (fast, rough).** In Studio, script two fake pilots that aim at the same Range targets: a "mouse-like" one with small aim jitter and a "stick-like" one with larger jitter and a little delay. Sweep the touch settings until the stick-like pilot's hit rate falls between the mouse-like pilot's average and its best. Use 20 runs of at least 50 shots per cell. That is about 1,000 shots, so results are good to roughly plus or minus 3 points. This only picks the starting values; fake pilots are not people.

**Step 2: real people, same drills.** Alan or other testers fly a fixed drill (the Range with assist turned on for the test, then bots in a 12-plane match) on a phone with the stick and on PC with the mouse, 20 runs each. Log hit rate and time-to-fold per band. Change one setting at a time, by 25%.

**Targets (starting guesses, ours)**
- Touch with help: hit rate 80% to 100% of the average mouse player's, in every distance band, and time-to-fold no more than 1.25 times the mouse's.
- Never above 100% of a skilled mouse player's in any band.
- Help share for touch at most about 40% in the mid band.
- If touch beats mouse close and loses far (or the reverse), as Treyarch saw, tune that band with its own setting, not the whole cone. The cone is mostly a close-range lever; `touch_assist_max_range_studs` is the far-range lever.

**In live play.** Log hit rate and folds per input type (from `PreferredInput`) in real matches. Compare each input's result to the targets weekly. Small sample sizes in a private game, so a gap of a few points is noise.

**First fake-pilot test (2026-10-24, Studio Edit, pure math).** The game's own shot motion and Range target paths (as
`tests/unit/RangeAccuracy.spec.luau`), every steady weapon, Challenge and Maneuvers, about 1,300-1,400 shots per pilot
and row. A pilot's nose sits off the lead ring by a random amount: "mouse" typically 1.5 degrees, "thumb" 3.5 (both our
guesses). The slowdown is modelled as cutting the thumb's error by its scale (0.65): a guess too. Hits, close / medium /
long row:

| Pilot | Close | Medium | Long |
|---|---:|---:|---:|
| Mouse (3 degree assist) | 90% | 87% | 86% |
| Thumb, mouse help only | 37% | 31% | 32% |
| Thumb + bend (cone 6, to 800 studs) | 65% | 46% | 44% |
| Thumb + bend + slowdown (cone 6, to 600) | 89% | 78% | 60% |
| **Thumb + bend + slowdown (cone 6, to 800): chosen** | **90%** | **78%** | **71%** |
| Thumb + bend + slowdown (cone 9, to 800) | 98% | 96% | 90% |

- Found and fixed a bug: past the far limit touch got no help at all, less than the mouse (5% on the long row); touch
  help is now never less than the mouse's (unit test).
- Cone 6 to 800 studs puts the thumb at 100% / 90% / 83% of the mouse: inside the 80-100% target in every row. Cone 9
  beats the mouse (too much). At 600 studs the long row (620-645 away) got no touch help: 70% of the mouse.
- The bend alone isn't enough (46-65%); the result leans on the slowdown, whose effect here is a guess. Alan's phone
  test is what settles it.

**What Alan judges by feel on his phone**
1. Does the plane feel like it fights me, or does it feel like it is helping? (Aim for "I can't tell, I just hit more".)
2. Can I land shots on a bot flying straight at medium range most of the time?
3. When a bot jinks, can I stay on it with my thumb?
4. Do I ever see a shot curve toward an enemy when I clearly missed by a lot? (Should be rare.)
5. Does a friend on PC get easily beaten, or easily beat me? Ask them as well.
6. Does the help ever turn on near a building, through a wall, or when I'm aiming at something else?

Alan's word is final on fun and fairness. The numbers only tell us when to stop adjusting.

## Sources

- Review: Aim Assistance in Video Games (BISEC 2025) https://bisec.metropolitan.ac.rs/wp-content/uploads/2026/04/Rad-19-Aim-Assistance-in-Video-Games.pdf
- CHI 2014, effectiveness of aim-assist techniques in shooters (summary) https://scholar2.islandarchives.ca/islandora/object/ir%3A8974
- Apex aim assist cut, Beebom https://beebom.com/apex-legends-aim-assist-nerfed/amp/
- Apex developers on parity, GGRecon https://ggrecon.com/articles/apex-legends-devs-are-investigating-potential-aim-assist-changes
- Apex mechanics, fan forum post https://forums.ea.com/discussions/apex-legends-feedback-en/2024-nerf-aim-assistrespawn/8719175/replies/8719184
- Paladins bullet magnetism change https://www.gamersunchained.com/news/hirez-studios-is-making-big-changes-with-aim-assist-and-bullet-magnetism-in-paladins
- Overwatch console aim assist changes (Blizzard) https://eu.forums.blizzard.com/en/overwatch/t/console-aim-assist-updates/8697
- Black Ops 7 aim assist data (Treyarch) https://www.dexerto.com/call-of-duty/black-ops-7-warzone-aim-assist-changes-3272835
- Destiny 2 aim assistance wiki https://d2.destinygamewiki.com/wiki/Aim_Assistance
- Halopedia aim assist https://www.halopedia.org/Aim_assist
- War Robots auto-aim design, Game Developer https://gamedeveloper.com/design/how-to-create-a-fair-auto-aiming-system-in-a-robot-shooter-
- Garena touch aim assist patent https://patents.google.com/patent/US12151161
- Bugnet aim assist tuning blog https://bugnet.io/blog/how-to-fix-aim-assist-over-or-under-correcting
- GDC 2013, Techniques for Building Aim Assist (abstract only) https://www.gdcvault.com/play/1017942/Techniques-for-Building-Aim-Assist
- Fortnite mobile auto-fire https://www.gamespot.com/articles/fortnite-season-5-mobile-update-adds-autofire-here/1100-6460356/
- Fortnite input-based matchmaking https://www.legitreviews.com/?p=207508
- Warzone Mobile touch vs controller assist https://www.ggrecon.com/articles/warzone-mobile-aim-assist-is-stronger-if-you-use-a-controller
- Aim assist through walls, player reports https://www.charlieintel.com/call-of-duty-warzone/warzone-player-questions-aim-assist-through-walls-156688/
- War Thunder mouse aim (forum) https://forum.warthunder.com/t/can-we-talk-about-aircraft-coordination-in-wt-on-mouse-aim/69953
- War Thunder console assist (forum) https://forum.warthunder.com/t/if-console-players-are-going-to-get-ground-to-air-aim-assist-in-ground-rb-the-pc-players-should-get-it-too/45997
- War Thunder Mobile review roundup https://www.taptap.io/es/post/6154400
- Ace Combat 7 preview https://www.thesixthaxis.com/2017/02/13/taking-virtual-flight-in-ace-combat-7-skies-unknown-on-psvr/
- Star Wars Squadrons difficulty and aim assist thread https://devtrackers.gg/sw-squadrons/p/2fefc249-multiplayer-aim-hacks-bug-not-really-hacks
- Phone flight controls (Sky Warriors) https://strategywiki.org/wiki/Sky_Warriors/Controls
- Roblox input guide, PreferredInput https://create.roblox.com/docs/input
- Roblox DevForum, PreferredInput release https://devforum.roblox.com/t/full-release-introducing-preferredinput-and-improved-touch-capabilities/3750890
- Roblox DevForum, "How To Make Aim Assist?" https://devforum.roblox.com/t/how-to-make-aim-assist/842957

Back to [HOME](../HOME.md)
