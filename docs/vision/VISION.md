# Product vision — current execution edition
**Working title:** Paper Plane Dogfight. **Owner:** Alan. Source: approved vision v0.6 and final budget decision.
This is the current creative brief. Full decision history is in `D:/FlyFightPaper-ARCHIVE-2026-10-06/reference/history` (read only if needed).

## Promise
A competitive, cartoony paper-airplane dogfight game in a giant classroom. Point the nose where you want to
fly, fight around cardboard cities and school supplies, return to a desk for service, and spend earned Paper
on different builds. A player can learn the controls quickly while continuing to improve at aiming, evasion,
route selection, teamwork, and modular equipment choices. Broad Roblox appeal: accessible to younger players
without baby talk or a children-only presentation. The classroom is an imaginative battlefield, not homework.

Commercial success is an explicit goal, alongside repeat voluntary play. Purchasable Paper and progression
boosts are included. Their actual profitability is unknown. No claim that spending has zero gameplay effect:
Paper can fund full refolds that preserve a streak. Keep clear free repair/fresh-plane alternatives.

## Required first candidate
One coherent finished classroom; PC mouse/keyboard controls; finite Lift; upward/horizontal fans; assisted
landing; desk repair/refold/protection; predefined modular builds; six weapon families; optional boost modules;
three voted modes; human multiplayer plus tiered scripted fill pilots; main menu/hangar; saved loadouts;
tutorial, HUD, results/settings; Paper and XP with level gates; persistent profiles; commerce infrastructure;
small destructibles; giant seated avatars; audio/effects; source/build instructions; documented verification.

Target twelve combatants per match, including fill pilots where needed. Bots do not prove twelve-human-client
network performance. The working catalog has 24 structural choices across four slots, six weapons, and
three boost modules. Five free loadout presets. These counts are bounded implementation defaults, not an
unlimited content promise. Numeric prices/stats are delegated tuning, not reasons to ask for every value.

## Controls and flight — locked
Third-person chase camera. Automatic forward movement and aim-direction/nose-follow steering with automatic
banking. No required separate yaw/roll/throttle controls. Forward weapon aim; at most two weapon trigger
controls and one optional boost control. PC first. Design input/UI for later touch; do not claim touch or
controller support is finished before it exists.

The player-facing reserve is **Lift**, not engine fuel. Starter reference endurance about 90 seconds; very
heavy builds around 60 seconds. Exhaustion causes steerable descent, not instant destruction. Weight costs
endurance/handling/speed, never grants health. Fans replenish Lift or give directional speed. Starter has no
boost. Optional boost parts use a separate meter initially refilled at desks.

## Classroom and service — locked
Owner visual direction approved2026-10-01: use assets/references/classroom-city-approved-v1.png as the art target. Expand the classroom substantially. Place student desks and their actual player avatars around the perimeter, with a large central city of many book stacks, cardboard skyscrapers, toy bricks, pencils and classroom objects. Include real fly-through openings, under-bridge routes, wide avenues, varied building heights and sparse ceiling decorations with navigable upper airspace. Detailed windows with exterior scenery, chalkboards and classroom finishes are required visual work. Preserve aircraft visibility and give the arena more breathing room than the concept image. Build order is in [MILESTONES](../plan/MILESTONES.md): gameplay feel first, then the city art. Skill-route rewards and pickups remain ideas pending design; they are not silently added to currency or flight rules.

Launch from a personal student desk. Books, pencil cases, handmade cities and large seated avatars are
obstacles. Avatar collisions can damage the plane; humans/giant figures cannot be injured or attacked for points.
Human desk occupants are the actual Roblox players' avatars, enlarged and seated while preserving their
equipped body, clothing and accessories. Do not substitute custom modeled people or force their bodies into
a different rig. Scripted fill pilots retain fictional presets; unavailable human appearances use an honest fallback.
All avatars use visually aligned, fair collision proxies. Small props can break and grant modest capped points;
large buildings remain stable in this release.

Glancing impacts are forgiving, major impacts can destroy. Respawn about four seconds. Death does not remove
owned equipment or Paper. Fly into an approach zone for assisted landing. Use your own/neutral desk in FFA;
friendly/neutral desks in teams. Hostile private desks are not service stations.

Free reserve refill causes no wear. Free ordinary repair preserves streak but accumulates life-specific
maximum-health wear. A Paper-funded full refold restores full durability and can change to a legal owned
loadout while preserving streak. A free fresh plane restores fully but ends streak. No midair purchase rescue,
teleport to safety, paid resurrection, or paid ammo. Desk upgrades are later scope.

Protection is 120 cumulative seconds at eligible desks per life during active rounds. No forced relaunch.
Re-entry, menus, desk changes, paid refolds, or preset changes do not replenish it. Expiry affects that plane,
not its teammates. Grounded aircraft cannot shoot. Fresh-spawn outside protection is brief and ends before
firing. A leader can shelter late in a timed match; this accepted tactic must not be secretly redesigned.

## Builder and weapons — locked
Nose, wings, body/chassis, tail are predefined parts, not user-constructed geometry. Aerodynamic speed costs
durability; bulky structural durability costs mobility. Chassis controls compatible mounts and carrying capacity.
Initial slim: 3 mounts / 5 capacity / no heavy; standard: 4 / 6 / one heavy; heavy: 6 / 10 / two heavy.
Light/medium/heavy costs begin at 1/3/5. One unlock permits multiple legal mounts. Added weapons do not add health.

Paper pellets are baseline guns. Staples are conventional/burst guns. Rubber bands are rapid unguided guns.
Paperclips are fast-projectile precision weapons, not homing. Erasers are slower guided shots, around one-fifth
of pencil damage, with finite life and two active shots per pilot as the initial cap. Pencils are very heavy,
slow unguided projectiles with huge damage; most planes die to one, exceptionally tough builds can survive.

Pencil launchers each reload in about four seconds, independently. A@0 is ready@4; B@2 is ready@6. Identical
launchers use one firing group and do not require separate keys. No forced twin volley or shared timer reset.
Balance complete loadouts, not each gun independently to a three-second kill target.

## Modes, menus, rewards — locked
FFA: eight minutes or twenty eliminations. TDM: eight minutes or sixty team eliminations. Airspace Control:
distinct team objective victory. Human mode voting, not forced alternation; bots do not vote.
Contribution points, economic rewards, and mode victory scores are separate. Pay eliminations, valid assists,
objectives, modest prop contributions, completion, winning, and appropriate top-three bonuses. Losing active
players progress. Earned valid contribution remains on early departure; final completion/placement benefits do not.

The true main menu is outside combat with no active aircraft. Shop, compare, save presets, and choose to join.
An in-match overlay leaves the aircraft moving, draining Lift, and vulnerable under existing rules. Applying
a preset requires respawn/fresh plane or legal paid refold, not an airborne transformation. Explicitly returning
to main menu ends life/streak, preserves earned contributions, forfeits final bonuses, and respects recent-attacker
credit. A withdrawn FFA pilot cannot win. No free escape/rejoin resetting novice progress or reward ledgers.

Paper and XP are separate. Buying Paper cannot buy the required level. No direct level purchases. A useful
purchase after roughly two or three ordinary matches; a 10–15-hour unboosted collection is a provisional
modeling target, not proven retention. The code must support central tuning without rewriting every module.

## Computer-controlled pilots — locked
No AI/BOT/Training Pilot labels in ordinary nameplates, custom combat roster, kill feed, or results. Use the
same visual treatment and varied fictional pilot identities, without forged Roblox accounts, fake purchases,
chat impersonation, or invented human connection counts. No public claim that every opponent is human.
Developer tools retain accurate actor type; they are not the ordinary UI.

Most beginner bots are below average but navigate and compete coherently. Regular vacancies use average and
occasional moderately stronger pilots. Personality varies independently of skill. Same flight, health, Lift,
reload, protection, and projectile limits as humans. No infinite resources or perfect sight through cover.
Tune to avoid routine leaderboard dominance, not a hidden guarantee of never finishing first. Real scores
remain real; do not force a crash or subtract points to protect a human's placement.

Graduate beginners after actual qualifying experience independently of paid XP. Persist graduation across
rejoins. Use humans when available and tier-appropriate bots for empty positions, including regular lobbies.
Solo standard play remains possible. No repeat return to weak rookie opposition after graduation.
Equivalent valid AI and human contributions award exactly the same base Paper/XP and boost eligibility.

## Commerce — locked
Paper packs; separate 2× XP and 2× earned-Paper temporary products of 15/30/60/180/300 minutes; premium
permanent 2× XP and permanent 2× earned-Paper passes. No 10-hour/24-hour standalone products. Five hours
is the largest pack, not a truncation limit on purchased accumulated time. Bonuses extend time, never reach
4× for the same resource. XP and Paper may coexist. Purchased Paper itself is not doubled.

Both timers pause offline. The retained implementation default counts loaded connected menus, desks,
intermissions and spectating; do not call these combat-only minutes. Loading/recovery/transfer gaps do not
consume unavailable value. Permanent ownership disables new same-resource temporary offers. Preserve dormant
remaining time on a permanent upgrade with clear terms, no invented refund. Live prices/IDs are not approved.

## Later scope and delivery boundary
Later: cosmetics, more maps, full touch then controller, improved desk equipment, collapsing cities, capture/
payload and escort modes, advanced ranked systems. Do not build these instead of the required game.
Deliver a complete private candidate and honest evidence. No public launch, real spending, account changes,
or claims of tested enjoyment, indistinguishability, or profitability without evidence.
