# Plan to reach the vision

Written 2026-10-07 after Alan's playtest and a full audit ([Audit 2026-10-07](../research/AUDIT-2026-10-07.md), which has file:line
detail for everything below). This replaces the earlier M0–M8 list.

## Where the game really is

- **The rules are good.** Stats, loadouts, economy, rewards, repair math, kill credit, protection, voting and
  bot roster rules match the spec and are tested (89 of 144 requirements are solid).
- **Everything the player feels is thin or wrong:**
  - Steering is a rate joystick, not "point the nose where you want to fly".
  - Shots miss because there is no lag compensation, and tracers show up late.
  - Bots have a one-function brain.
  - UI is plain debug text.
  - Audio is re-pitched footstep sounds.
  - The city is 9 buildings in a room that grew 3×, with flat lighting.
- **The art got worse because content was deleted, not because the models got worse.** About 40 structures and
  a 326-piece detail layer were removed. About 154 uploaded meshes sit unused in ServerStorage. Lighting has no
  shadows, haze or warmth. Meshy's normal and roughness maps were thrown away.
- **Saving is not safe to publish.** The DataStore budget is blown, one failure stalls a whole server, and the
  mock shop would hand out free Paper on a published server.

## Why it went wrong, and the rules that stop it happening again

1. **Nobody looked at the game.** Studio's viewport was 1×1 pixels and no screenshot was ever reviewed. From
   now on, every change to feel or visuals is checked in real Play at 1280×720 or larger, with screenshots.
   Compare them to `assets/references/classroom-city-approved-v1.png` and to the previous screenshots.
2. **Breadth beat depth.** Six milestones were sketched in one night. From now on: one stage at a time per
   track. Overnight work goes **deeper** on the current stage (polish, tuning, content), never into the next gated stage.
3. **Tests were treated as proof of quality.** 232 rule tests passed while the game was unplayable. A stage is
   done only when its quality bar below is met in Play **and** Alan approves at the marked gates.
4. **Effort went to bookkeeping.** Spend effort where the player feels it. Don't add ledgers, journals or
   abstractions the game doesn't need.

## Alan's decisions

Each decision has its own note in [decisions](../decisions/README.md) with what was decided and why. The D
numbers stay so older notes that say "D13" still make sense.

- **D1** [Control scheme](../decisions/2026-10-07-mouse-aim-controls.md)
- **D2** [Room size](../decisions/2026-10-07-keep-big-room.md)
- **D3** [Saving library](../decisions/2026-10-07-profilestore-saving.md)
- **D4** [Private publish](../decisions/2026-10-07-private-publish.md)
- **D5** [Meshy credits](../decisions/2026-10-07-meshy-credit-budget.md)
- **D6** [Stage 2 combat](../decisions/2026-10-07-combat-approved.md)
- **D7** [Stage 3 scope](../decisions/2026-10-07-bot-scope.md)
- **D8** [Bot builds](../decisions/2026-10-07-balanced-bot-builds.md)
- **D9** [Human-like bots](../decisions/2026-10-07-human-like-bot-quirks.md)
- **D10** [Order after the gate (2026-10-13)](../decisions/2026-10-13-build-order-after-gate.md)
- **D11** [Takeoff (2026-10-13)](../decisions/2026-10-13-automatic-takeoff.md)
- **D12** [Tutorial moves to the end (2026-10-13)](../decisions/2026-10-13-tutorial-built-last.md)
- **D13** [Stage 9 workshop (2026-10-13)](../decisions/2026-10-13-stage-9-modes-workshop.md)
- **D14** [Escapes workshop (2026-10-14)](../decisions/2026-10-14-escapes-hvac-ducts.md)
- Later decisions (points, plane colours, chalk eraser and more): [decisions](../decisions/README.md)

---

## Tracks and order

```
Track A (gameplay):  Stage 0 → Stage 1 Flight → Stage 2 Combat → Stage 3 Bots → ★ GATE: vertical slice
Track B (world):     Stage 0 → Stage 4 Art and world (4a lighting can start right away)
Track C (server):    Stage 5 Saving and server robustness (any time)
After the ★ gate:    Stage 6 UI/UX → Stage 7 Audio/FX → Stage 8 Aircraft art → Stage 9 Modes/content
Last:                Stage 10 Commerce wiring → Stage 11 Multiplayer, QA, release candidate
```

Tracks touch different files, so separate workers can run them at the same time (at most one worker per track).
★ means Alan must play it and approve it before anything after it starts.

Rough size (working sessions, not calendar days; uncertain): Stage 0 ½, Stage 1 1–2, Stage 2 2–3, Stage 3 2–4,
Stage 4 6–10, Stage 5 2–3, Stage 6 4–6, Stage 7 2, Stage 8 3–5, Stage 9 3–5, Stage 10 1, Stage 11 3+ plus human
testers. **Expect several weeks, not one night.**

---

## Stage 0 — Eyes on the game (do first)
- Make in-game screenshots work at 1280×720 or larger: Studio MCP if it can capture, otherwise desktop capture of
  the Studio window. A 1×1 viewport is not a check.
- Add a dev-only "photo mode" key that cycles **8 fixed viewpoints**:
  1. spawn desk
  2. city overview from high
  3. low avenue
  4. through a fly-through hole
  5. window side
  6. chalkboard wall
  7. chase cam in a dogfight
  8. hangar
  Keep only the latest set, in a git-ignored `captures/` folder (overwrite; no history piles).
- Add a dev-only performance overlay that logs average FPS, p95 frame time and server frame time over a
  60-second window.
- Put Lighting settings under Rojo (`default.project.json`) so they can't silently drift in the place file.
- **Done when:** the 8 viewpoints and a perf readout can be produced on demand, and Alan has been shown them once.

## Stage 1 — Flight that feels good (Track A)
Rewrite client steering and camera; keep client network ownership and the server's Lift/health rules.
- **Mouse-aim:**
  - Lock the mouse to the centre and accumulate mouse movement into a free aim direction.
  - Draw two reticles: the aim circle and a dot where the nose points.
  - The autopilot turns the plane toward the aim point at the loadout's turn rate. It banks into turns
    (aggressive roll beyond about 10° off target) and levels its wings when the aim is close to the nose.
  - Smooth with `AlignOrientation` (finite torque) plus `LinearVelocity` (finite force). Pitch limit 80°.
- **Camera:**
  - Scriptable chase camera. It looks between the plane and the aim point.
  - Spring-smoothed, with position lagging a little more than rotation.
  - Spherecast pull-in so it never leaves the room.
  - FOV widens with speed and on boost.
  - Small shake on hits and near-misses. Subtle speed lines at high speed.
- **Forgiveness:** grazing contacts (under 15 studs/s into the surface) do no damage and slide the plane along the
  surface. Out-of-bounds: warn about 60 studs before the edge, nudge the aim back inside, and destroy only after
  a short grace period outside.
- **Validation:** replace "kill on invalid movement" with "snap back to the last valid position". Validate turn rate
  and the empty-Lift descent on the server. Stop writing Lift every frame: replicate the time draining started
  plus the rate, or throttle to about 5 Hz.
- **Fans:** horizontal fans push in the **fan's** direction. Read fan definitions from `config.world.fans`.
- Bots will use this same autopilot (Stage 3), so it must take an aim point from either a mouse or an AI.
- **Quality bar:**
  - Starter reverses direction (180°) in about 2–2.5 s; heavy is clearly slower (about 3.5 s+).
  - Plane follows the reticle with no wobble or overshoot.
  - No camera clipping in 5 minutes of deliberately hugging walls and the ceiling.
  - A scripted test autopilot flies a 2-minute loop of the room without crashing.
  - 60 FPS, p95 frame under 20 ms.
  - ★ **Alan flies it for 5 minutes and says it feels good.**

## Stage 2 — Combat that feels good (Track A)
- **Instant feedback:** the shooter's client draws tracers and muzzle flashes on the click frame, one per mount.
  The server confirms hits; the client shows a hit marker plus a tick sound on confirmation, and a bigger
  kill-confirm sound and visual.
- **Lag compensation:**
  - The server keeps a position history (about 1 s at 20–30 Hz) for every plane, humans and bots.
  - Hits are tested against where the target was in the shooter's view (rewind capped at about 250 ms).
  - Includes a line-of-sight check.
  - Hitboxes about 1.3× the visual size.
- **Projectile system:**
  - One stepped-Spherecast system with a **per-weapon behaviour table** instead of ID checks.
  - Cosmetics relayed to other clients in batches on an `UnreliableRemoteEvent`.
  - Impact effects on walls and planes.
- **Weapon identity:** each of the six must look, sound and play differently. Tune for that, then for balance.
  - Pellets: steady stream.
  - Staples: punchy 3-round burst.
  - Rubber bands: clearly faster fire, wobbly flight.
  - Paperclips: fast precise single shot with a sharp crack.
  - Erasers: slow, visible, avoidable homing, with a loud lock-on.
  - Pencils: huge, slow, devastating, with a big wind-up.
- **Aim help:** a lead pipper on the locked or nearest target in the aim cone.
- **Readability:** damage direction indicator, low-health warning, paper-shred hit and death effects, and damage
  states on planes (torn and crumpled at low health).
- **Quality bar:**
  - The tracer appears on the same frame as the click.
  - With 100 ms of simulated latency, at least 60% of pellets hit a bot flying straight at 150 studs when aimed
    with the pipper (automated test).
  - All six weapons distinct.
  - Alan says shooting "feels reliable and satisfying".

## Stage 3 — Bots that fight like people (Track A)
- **Brain:** an explicit state machine with these states:
  - Patrol
  - Pick target, spreading targets so not everyone chases the human
  - Chase (lead, pure or lag pursuit)
  - Attack: bursts in the aim cone
  - Evade: enemy within 30° of the tail; break turn, dive behind cover, jink
  - Extend/reposition
  - Seek fan when Lift is low
  - Return to desk to repair
  - Search the last-known position
  - Recover when stuck
  - Avoid: an override state, highest priority
- **Steering:** bots produce an aim point and fly with the **same autopilot as players**.
- **Navigation:**
  - Bake the waypoint graph from the real room geometry: a free-air node grid, with edges validated by spherecast.
  - A* routing and a spatial lookup for the nearest node.
  - Whisker spherecasts: forward about speed × 1.3 s, plus four at ±30°.
- **Skill vs. personality:**
  - Skill tiers set reaction time (200–450 ms), aim cone (2–6°), lead accuracy (0.7–1.0) and decision quality.
  - Personality (aggressive, cautious, objective-focused, opportunist) is chosen independently of skill.
  - Bots perceive within 120° plus line of sight. Decisions at about 10 Hz; steering every frame.
- **Looks:** real avatar presets for bots (varied outfits), varied names, and loadouts that fit their tier.
- **Quality bar:**
  - In an 8-minute 12-bot match, at least 80% of bot deaths come from weapons, and on average less than 1 wall
    death per bot.
  - Rookies hit about 10–20% of shots; Experienced about 35–50%.
  - A new player against Rookies gets a first hit within 30 s and a first kill within 90 s.
  - Bots don't all swarm the player.
- ★ **VERTICAL SLICE GATE:** Alan plays three full FFA matches against bots. Flying and fighting must be fun
  enough that he'd play another. **Nothing in Stages 6–9 starts before this passes.** PASSED 2026-10-11 (Alan: "the bots pass, it is fun"); art first by his choice.

## Stage 4 — Art and world (Track B)
**4a Lighting (start now):**
- Future lighting with `GlobalShadows` on.
- Sun angled through the windows (ClockTime about 9–10).
- Environment diffuse about 1, specular about 0.5.
- Warm Atmosphere (density about 0.3, haze 1–2).
- A real Sky or skybox outside the windows, replacing the grey `OutsideSky` part.
- ColorCorrection (warm tint, saturation +0.1).
- Bloom 0.3–0.5.
- Subtle SunRays.
- SpotLights or SurfaceLights in the ceiling fixtures.
- No DepthOfField or Blur in gameplay.

**4b Layout and the city play rug:**
- Keep the big room. Block out the city with plain parts first.
- **Giant city play rug** under the central city. It is like the classic classroom car rug: grey roads with
  dashed lines, crosswalks, a roundabout, curvy and straight streets, green grass blocks with painted trees,
  ponds, a playground, parking lots, and little flat painted houses.
  - Make our **own original design** in that style; don't copy a specific store-bought rug's artwork.
  - Build it from modular 1024 rug tiles (straight road, curve, T, cross, roundabout, crosswalk, several grass
    blocks with painted details) laid on a grid of flat parts, so it stays sharp at this size. One giant image
    would be blurry.
  - Add a soft carpet-fibre feel (fabric MaterialVariant or a subtle normal map) and a stitched border.
  - Optionally add one or two smaller rug variants elsewhere in the room so the floor isn't uniform.
- **Buildings sit on the grass blocks, never on a road.** The rug's roads become the city's avenues and flight
  lanes. Lay the rug out first, then place buildings to match it.
- **Ground-level clutter so nothing looks blank:** toy cars and buses on the roads, traffic cones, little
  trees, a toy fire truck, a toy plane on the rug's airport, building blocks, crayons, pencils, erasers.
  Small things can be breakable props (capped points).
- Perimeter desks with seated avatars, two neutral desks, three height layers, fly-through holes at ground, mid
  and roof level, under-bridge routes, open belfry tops, looping routes wide enough for heavy planes.
- Named landmarks: Pencil-Case Bridge, Cardboard Square, Book Towers, Window Run, Fan Alley (several fans).
- Review a top-down capture and fly it before placing final art.

**4c Bring back what exists:**
- Restore the deleted detail layer from commit `c46a7e7` (`Workspace/FlyFightPaperEditorPreview`) as static
  models. Static placement does not bring back the old slowness, which came from building meshes at runtime.
- Use the ~154 dormant meshes in ServerStorage (perimeter boards, ceiling light, oak tree, belfry, gallery,
  city bank, chalkboard).
- Replace primitive desks, chairs, trees, shelves and lights with the existing mesh versions
  (`assets/models/classroom-desk`, `classroom-chair327`, …).

**4d Material quality:**
- Every building gets a SurfaceAppearance with Color, Normal and Roughness. Re-bake in Blender onto clean UVs at 1024.
- Use the Meshy 2048 normal maps for the Meshy buildings.
- Large flat cardboard, paper and book surfaces use tiled MaterialVariants (corrugated cardboard, notebook paper,
  book cloth) instead of blurry unique atlases.
- Replace the flat `craft` and `toy-bricks` atlases.
- Texture all chalkboard pieces.
- Replace the 192 Neon landing strips with painted or taped desk markings.
- **A bit more Roblox-like:** cleaner shapes, chunkier proportions, bolder and more saturated colours, less noisy
  photo-real texture, soft bevels. Don't regenerate everything. For existing models use Meshy **retexture**
  (10 credits, keeps the geometry, `remove_lighting` on) with a stylized prompt, plus Blender colour and texture
  clean-up. Regenerate only the big hero models that still look bad.

**4e Fill the city:**
- The room is staying big, so aim for about 70–90 structures on and around the rug.
- Use instanced copies of each family with rotation, scale and colour variation, so the same MeshId repeats cheaply.
- New models via Meshy where nothing fits (budget below). Polish each one in Blender: clean geometry under 10k
  triangles, fixed normals, openings that are really open, collision boxes that match what you see.

**4f Room finish:**
- Bright windows with an outside view.
- Chalkboard reading "FOLD / FLY / FIGHT".
- Posters, bookshelves with mesh books, cubbies, backpacks.
- Hanging planets and paper cranes, with navigable air above.
- Giant seated player avatars at the perimeter desks.

**4g Performance pass:**
- 12 planes flying through the densest area: 60 FPS, p95 under 20 ms, under 1M triangles, under 1,000 draw calls.
- `RenderFidelity` Precise only on hero landmarks.
- `CastShadow=false` and collision/query off on decor.
- Whole map visible at spawn; no pop-in.

**Meshy shopping list (D5, budget about 2,400 of 2,700 credits):**
| Group | Items | About |
|---|---|---|
| Hero models, highest quality (2K/4K PBR, higher polycount split into ≤20k-triangle parts) | 8–10 big landmarks: twin towers, clock tower, pencil-cup skyscraper, book tower, belfry, gateway, Cardboard Square centrepiece, Pencil-Case Bridge | 300–450 |
| Retexture existing models | the 13 existing Meshy models (stylized, Roblox-like) | 130–200 |
| New city buildings | crayon-box building, glue-bottle tower, ruler bridge, water tower, 3 toy-brick buildings, eraser-block building, tape-dispenser hangar, pencil sharpener, stapler bridge | 400–500 |
| Ground clutter for the rug | toy cars ×3, toy bus, toy fire truck, toy plane, traffic cone, building blocks, crayons | 300 |
| Room finish | globe, desk lamp, backpack, hanging planet set, origami crane set, book-stack variants | 250–300 |
| Retries and fixes | | about 500 |
- Make a clean reference image first, then image-to-3D with PBR, then Blender polish.
- Check the live balance before each batch. Log every job in `assets/MESHY_LOG.md` (date, item, credits, kept or rejected).

**Quality bar:**
- The 8 viewpoints read like the reference: dense, warm, sunlit, cardboard-and-books city with shadows and depth.
- No primitive-looking furniture.
- No clipping, floating objects or invisible blockers.
- Performance numbers above are met.
- ★ **Alan approves the look.**

## Stage 5 — Saving and server robustness (Track C)
- Replace ProfileService/ProfileRuntime with **ProfileStore**:
  - session lock with stealing
  - autosave about every 60 s
  - save on leave and in BindToClose
  - receipt/operation IDs kept inside the profile for idempotency
  - stays well under the DataStore budget
- Rewards: a failed reward for one player is logged and retried, and must **never** stall the round loop for everyone.
- Gate the mock shop and the dev loadout picker to `RunService:IsStudio()`. Mock purchases can never reach a real profile.
- Delete unused MatchService/Profile APIs and dead code (see the audit). Move magic numbers into config.
- **Alan step (D4):** publish privately once. Then test real saving, rejoin, a quick server hop, a failed save
  (simulated), and 2–4 local players (Studio Test → Clients and Servers).
- **Done when:** real-DataStore tests pass on the private place, and no single failure can block a round.

## Stage 6 — UI, HUD and the first 60 seconds (after ★)
- **One visual style:** notebook-paper panels, tape corners, hand-drawn icons, one readable font.
  Use scale-based layouts with UIScale, tested at 1280×720 and 1920×1080.
- **HUD:**
  - Aim reticle and nose dot.
  - Health with worn maximum.
  - Lift and boost as clear bars.
  - Per-group reload/lock with two pencil pips.
  - Hit markers and kill feed.
  - Mode score and timer.
  - Enemy markers drawn on top at any range, plus **off-screen indicators**.
  - Team shape and colour markers.
  - Objective marker and capture bar for Airspace Control.
  - No dev FPS counter or help bar in normal play.
- **Menus:** main menu, hangar, shop (mock label), settings (sensitivity, sound and music separate, crosshair color and size (Alan), reduced shake,
  real graphics quality), results with an XP bar, Paper earned and **next unlock preview**, confirmation dialogs
  for spending Paper.
- **First 60 seconds:** moved to "Tutorial (built last)" (D12, Alan 2026-10-13).
- **Done when:** the HUD and menus read at a glance at 1280×720 and 1920×1080, and Alan approves.

## Stage 7 — Audio and effects (after ★)
- Licensed sounds only, from Roblox's free audio library or Creator Store audio.
- Distinct short sounds for each weapon.
- Hit tick and kill confirm.
- Lock-on and incoming warnings.
- Wind and engine-free "paper whoosh" that rises with speed.
- Fan rush, landing, service, low Lift, death crumple, round start/end, purchase.
- Positional 3D sound on planes and projectiles.
- Real classroom ambience and a music track with its own slider.
- Effects: impact puffs, paper-shred deaths, boost trail, protection dome, fan wind lines, damage smoke/tatters.
  All pooled.

## Stage 8 — Aircraft and builder visuals (after ★)
- Polish all 24 structural parts and 6 weapon mounts (existing Meshy/Blender plus new Meshy where needed).
- Clear silhouettes: slim (sharp and narrow), standard (classic folded), heavy (wide and reinforced).
- Plane colours stand out from the classroom's colours, every part, so planes read at a glance (Alan 2026-10-07).
- Per-body **hardpoints**, so weapons sit on the wings or body and never clip.
- The collider matches the actual fitted parts.
- Hangar presentation: large rotating preview, good lighting, a mount diagram with light/medium/heavy labels,
  stat bars, compare, five editable presets.

## Stage 9 — Modes and content completion (after ★) (workshopped with Alan 2026-10-13, D13)
**Approved by Alan 2026-10-18** ([decision](../decisions/2026-10-18-stage-9-approved.md)).
- **Airspace Control:** a moving field (see D13): crayon/chalk circle on what is under it plus a drifting loop of
  paper bits around its edges; white when nobody holds it, team colour when held, both colours when contested.
  Crayon capture bar under the round strip; edge arrow to the zone (and to the next spot during the warning).
- **TDM:** team colours on planes, outlines, names and the round strip.
- **Hidden paper targets** (D13): kid-drawn cut-outs on buildings, client-side, fall flat, server-checked points.
- **Escapes** to lose a chaser (D14: HVAC ducts above a drop ceiling + chalk-eraser cloud; concepts approved, build next).
- Round end ([decision 2026-10-17](../decisions/2026-10-17-rounds-never-stop.md)): "Pencils down!", winners' moment on the
  desks with the results, a safe vote lap through mode rings (keys as backup), next round where everyone is.
- Bot avatars, personalities and tier loadouts verified in every mode (bots chase the zone, never teammates).
- Rookie graduation flow verified.

## Tutorial (built last, before Stage 11) (Alan, 2026-10-13)
- **Its own empty room:** the same classroom map, but a private copy with nobody else in it, so the tutorial can
  place things exactly when it needs them.
- **Teaches, step by step:** flying (steer, Lift, fans, landing); paper targets to shoot; then an enemy spawned at a
  set point to fight; what each part of the HUD means (bars, weapon pips, heat, lock warnings, the edge arrows,
  score/place); the hangar menu; how each weapon works; how weapon customization (mounts, building a plane) works.
- First join goes straight into it; skippable and replayable, never rewarded (practice is not reward-eligible).
- Starting point already in code (2026-10-13): practice pilots are nobody's enemy (CombatService:enemy), a paper
  target placed from shared numbers (CombatRules.practiceTargetPose, server hits it), a sticky-note step guide
  (src/client/Tutorial.luau), and a landing guide ("Line up here"). In the live room the target was hard to find.
- **Done when:** a new player understands the game without reading anything long, and Alan approves.

## Stage 10 — Commerce wiring (stays off)
- Real `MarketplaceService` adapter: `ProcessReceipt` with idempotency through ProfileStore, plus game-pass ownership checks.
- Keep everything **disabled** until Alan approves product IDs and prices. No real Robux tests.

## Stage 11 — Multiplayer, QA and private release candidate
- Studio multi-client tests (4+ clients).
- A private-place playtest with as many real people as Alan can gather, aiming for 12.
- A 30-minute soak test with 12 planes: memory and FPS stable.
- Two independent requirement-by-requirement QA passes against VISION and the rules on the [system pages](../HOME.md#the-game-system-by-system), written to `docs/research/` (last one: [QA review 2026-10-07](../research/QA-2026-10-07.md))
  as PASS / FAIL / NOT TESTED.
- [Release notes](RELEASE_NOTES.md): what works, known bugs, what still needs real-world proof (mobile, controller,
  live purchases). The game stays private until Alan decides.
