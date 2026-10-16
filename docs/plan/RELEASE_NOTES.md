# Private development build

October 7 playtest update: this build failed Alan's flight, combat and art review. Work is back at M2, with M1 steering reopened and later milestones paused. The first repair pass corrects mouse offset and missed quick clicks, tightens shared turning, and adds clearer, faster shots. Its 232 rule tests pass; human acceptance and full-match performance are still outstanding. City clipping and quality are not repaired in this pass.

October 7, 2026. This is ready for further playtesting, not approved for release. It remains private. Alan has not yet signed off flight feel, combat or the classroom art.

## Connected features

Native client-owned flight, Lift and fans, collision damage, landing and four-second respawn. All six weapon families use server hits and ordinary reloads. Eleven scripted pilots fill a solo match. Free-for-all, Team Dogfight and Airspace Control connect through results and human voting.

Desk refill, worn repair, free fresh planes and a 120-Paper full refold are connected. Refolds preserve life and recover unconfirmed charges after a session failure. Protection is per pilot and cumulative. Occupied pads now have ordered holding approaches.

The expanded native classroom reuses retained cardboard and book assets. Nine building families have Blender and FBX sources, fitted box collisions and open routes. Six buildings use five smaller shared textures. The approved chalkboard replaces the older drawing; its opaque text cover is removed. The unused old editor city has been removed from the working place. Perimeter desks have enlarged seated avatars, including the human's equipped Roblox appearance. Aircraft have native modular parts and mounted equipment. The hangar has five presets, ownership checks and final build stats. Tutorial, settings, audio, pooled effects and the clearly labelled development shop are connected.

## Checked

227 tests in 18 suites pass, including profile failures, retry safety, refold recovery, weapon timing, legal build arrangements, match rules and partial map loading. All Luau compiles. Earlier one-plane flying averaged 59.98 FPS. An earlier grey-box twelve-plane match averaged 59.70 FPS while flying, with one 442ms stall. These measurements do not prove steady city performance.

The final navigation build completed three successive eight-minute city rounds normally: FFA, Team Dogfight and Airspace Control. They had 18/2, 15/3 and 12/2 scripted-pilot weapon/collision deaths. The human was parked; these rounds do not establish human combat quality. Changing a human mode vote replaced the previous vote and selected the requested next mode. The city navigation graph has 103 connected nodes and a route from every desk. Seven ground, bridge and upper openings passed native clearance sweeps. All 29 authored mesh assets are readable, with a maximum of 9,508 triangles per mesh.

A 432-second native server sample recorded physics at 1.16ms average, 2.00ms for 95% of frames and 4.95ms worst; scheduled server work was 1.20ms average and 3.76ms worst. These Roblox engine measurements do not measure client rendering or city FPS.

Returning to menu and rejoining now creates a new valid combat life without restoring forfeited bonuses. Loading distinguishes real map parts from arriving avatars and waits for the aircraft library too. The hangar keeps its scroll position during profile updates; purchase controls no longer overlap mount buttons. Desk controls fit above the lower HUD at 720 pixels high. The tutorial requires landing the same life rather than counting a crash respawn as landing. These interface changes still need rendered play.

Boost timers now pause while a profile is loading, including when the player leaves before that load finishes. Tests also prevent clock initialization from refunding time already spent online. A final native twelve-participant join completed with no Output messages. The working place is saved and Studio is stopped.

## Known problems and unverified work

- Bots still sometimes hit scenery. The final route repair prevents an unreachable target inside a building from becoming a flight destination; all three full-mode regressions completed. Human combat and avoidance feel remain untested.
- Studio's background viewport is 1 by 1 and has no usable rendered frames. Current city FPS, pop-in, camera behavior, UI at both target sizes, audio and the new-player flow remain unverified.
- The classroom has not received Alan's visual approval. Every fly-through, avatar collision proxy, aircraft silhouette and weapon mount still needs rendered flight inspection. The remaining material and texture-family polish is not fully audited.
- Studio profiles last only for the current Play session. Private live saving, leave/rejoin, shutdown recovery and beginner/established room transfers still need an accessible private experience. A server crash before an earning reaches durable storage can lose that uncommitted earning.
- Bots getting kills does not establish fair or enjoyable human fights. Loadout balance, fan routes, control-zone tactics and progression pacing need human play.
- Twelve real human clients, real latency, mobile and controller support are untested. Mobile/controller remain later scope.
- The fifteen shop products are simulations. No real product IDs, prices, checkout or sales are enabled. Live purchases require approved products and genuine receipt/entitlement testing later, without real spending in this task.

## What to try

Open `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx`, reconnect Rojo and press Play. Try flight first, then fight, land and use the free desk options. Compare a slim and heavy build; test twin pencils. Stay through results and voting. Check the classroom, avatars and openings while watching FPS. Try the tutorial, settings and mock shop. Detailed status and outstanding playtests are in `state/STATE.md`; the two requirement reviews are in [QA review 2026-10-07](../research/QA-2026-10-07.md).

Build and source instructions are in [Studio and Rojo](../workshop/studio-and-rojo.md). Nothing was published publicly, no account settings changed, and no money or Meshy credits were spent. Desktop control stopped after Escape and remains stopped; subsequent checks use the Studio API.
