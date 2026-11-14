# Physics, collisions, networking and the server

None of these change the look: collision shapes are invisible, and moving visuals to the client keeps them identical.
Physics shows in the MicroProfiler as `physicsStepped`, `worldStep`, `stepContacts`, `Simulation/assemble`;
`stepWorldThrottled` means the engine is overloaded. Network: Developer Console (F9) Server Stats "Total Data KB/s",
the Network debug overlay (Shift+F3), MicroProfiler dumps' X-Ray > Network view.

Format: **tip**. Why. *Measure.* Source (date). Confidence.

## Collisions
- **Decorative parts: `CanCollide`, `CanTouch`, `CanQuery` all false, and `CollisionFidelity = Box`.** All three off
  takes a part out of collision work; the collision *shape* still sits in memory, so also pick Box. Cost order
  Box < Hull < Default < PreciseConvexDecomposition (slowest to compute, most memory). `CanQuery` only takes effect
  when `CanCollide` is false. Never strip a part that something hits or touches.
  *Explorer filter `CollisionFidelity=PreciseConvexDecomposition`; Visualization Options > collision fidelity;
  Memory tab `PhysicsCollision`.* [Collisions](https://create.roblox.com/docs/workspace/collisions),
  [Improve](https://create.roblox.com/docs/performance-optimization/improve) (current);
  [CanQuery release, staff](https://devforum.roblox.com/t/new-part-collision-property-canquery-now-available/1452707) (2022-01). High.
- **Hit shapes don't need to match the picture.** A detailed mesh can collide as a Box/Hull, or as a few invisible
  boxes. When exact shapes are needed, compute them once in Studio and save them in the place (never at runtime:
  precise decomposition at start-up froze Fly Fight Paper's Play for minutes, 2026-10-11). High.
- **Collision groups:** put shots, planes, scenery, pickups in groups and switch off pairs that never meet; use the
  same groups in query params. Non-colliding pairs skip contact work. High.
- **Touched vs queries.** `Touched` is cheap for big trigger zones but fires repeatedly: debounce, and set
  `CanTouch = false` everywhere else (cost grows with parts that listen). For fast things (shots, planes) cast from
  last position to new position each frame instead: no tunnelling. High/medium.
- **Reuse one `RaycastParams`/`OverlapParams`.** New (2026): `IncludeInstances`/`ExcludeInstances` are "much faster"
  than `FilterDescendantsInstances`, which gets no more optimisation.
  [New spatial query filters](https://devforum.roblox.com/t/new-spatial-query-filters/4563575) (2026-04/06). Medium-high.
- Folklore: "`CanQuery = false` speeds up raycasts" is weak; staff only promised a win with all three off.

## Simulation
- **Anchor everything that doesn't need physics; fewer moving assemblies and joints = less physics time.** Anchored
  scenery also streams part by part; big moving assemblies stream whole. High.
- **`PhysicsSteppingMethod`:** Adaptive steps each mechanism at 60/120/240 Hz; Fixed runs everything at 240 Hz
  (much costlier). Adaptive became default and was reverted the same day (2023-07-06): check your place's value,
  and test that fast thin things don't tunnel. [Thread](https://devforum.roblox.com/t/physicssteppingmethod-now-set-to-adaptive-as-default/2455212). High.
- **Constraints, not legacy BodyMovers** (`LinearVelocity`, `AlignOrientation`, `VectorForce`). Legacy movers are
  deprecated and misbehave under Adaptive. Medium.
- **Humanoids are expensive:** disable unused states, `AnimationController` for NPCs that don't walk, spawn NPCs
  near players only. Vehicles and bots shouldn't be Humanoids. High.
- **Don't tween or set properties on the server every frame.** Every changed property replicates to every client;
  tween on the client instead. High.

## Network ownership
- **The pilot's client owns their own vehicle** (`SetNetworkOwner(player)`): it simulates locally (responsive, no
  round trip) and the server does less work. The server can't verify client-owned physics: check speed, position
  and hit claims on the server with a fair tolerance. Anchoring returns ownership to the server; avoid frequent
  ownership swaps (2026 reports of ~1 s freezes during transfers).
  *Visualization Options > "Network owners".* [Network ownership](https://create.roblox.com/docs/physics/network-ownership) (current). High.
- **Projectiles aren't server parts.** Clients draw them; the server gets "fired at (origin, direction, time)" and
  checks the hit with its own raycast. Server-side parts would replicate their movement to everyone. High (principle).

## Remotes and bandwidth
- **`UnreliableRemoteEvent` for constant, skippable updates** (positions, aim, sparks, engine-sound state); normal
  `RemoteEvent` for things that must arrive (kills, scores, purchases). No ordering, dropped under load, dropped if
  no listener yet: put a sequence number or time in each message. Payload limit **1,000 bytes** (was 900 until
  2025-03-12; tutorials saying 900 are out of date).
  [Remote events](https://create.roblox.com/docs/scripting/events/remote);
  [announcement](https://devforum.roblox.com/t/introducing-unreliableremoteevents/2724155) (2023-11-29). High.
- **Batch:** one message per tick (20-30 Hz) carrying every entity's change, not one per entity per frame; send only
  what changed. Each call has ~9 bytes overhead plus per-argument headers (community table: number 9 B, Vector3
  13 B, CFrame 14-20 B, bool 2 B). High (principle), low (byte table).
- **Pack high-rate data** (quantised 16-bit numbers or a `buffer`) to fit many entities under the 1,000-byte limit.
  Saving is real but unmeasured publicly; too coarse a quantisation shows as snapping. Medium.
- **Don't send what clients can work out themselves** (the big "60x" RTS saving came mostly from this). Medium.
- **Create and destroy big instance trees in chunks;** parent a model after filling it; destroy the parent, not
  each child. Medium.
- **Budget:** no official per-player number. Community guides: under ~50 KB/s received per client (2021, dated),
  investigate if server "Total Data KB/s" is over ~100. An empty baseplate already shows ~30 KB/s per player
  (2025). Treat as rough. Low-medium.

## Replication changes in 2026 (check status before relying on old numbers)
- `Workspace.ImprovedPhysicsReplication` rolled out 2026-06 ("eventual consistency"; Disabled kept as an escape
  hatch while bugs are fixed: false "flying" kicks, stutter, ownership-transfer freezes, fix 2026-08-14). Old "physics
  sent at 15-20 Hz" numbers no longer apply cleanly; physics network stats read 0 with it on.
  [Upcoming improvements](https://devforum.roblox.com/t/upcoming-improvements-to-physics-replication/4675512) (staff, 2026-06 to 08). High (that it's in flux).
- Server Authority / NextGenerationReplication (2026) costs more bandwidth and server CPU by design; only for games
  that need rollback-fair physics. [Server authority](https://create.roblox.com/docs/projects/server-authority). High.

## Server budget
- **Server heartbeat is capped at 60.** Developer Console > Server Jobs > Heartbeat "Steps Per Sec" should sit near
  60; lower = server overloaded (adds lag for everyone).
  [Identify](https://create.roblox.com/docs/performance-optimization/identify) (current). High.
- **Server memory:** 6.25 GiB + 100 MiB per peak player (12 players ≈ 7.4 GiB); stay under half. Memory isn't given
  back when players leave: growth over server age = leak. High.
- **Server CPU now scales with connected players** (2025-11-10 rollout, up to ~30% less throttling in Roblox's
  tests); tuning Max Players for CPU is outdated.
  [Launching even more server CPU](https://devforum.roblox.com/t/launching-even-more-server-cpu/4044040). High (change), medium (benefit).
- Studio: Test > "Server & Clients" with several clients for load; Alt+S network simulator for lag/loss; Settings >
  Network > "Print Join Size Breakdown" lists the 20 biggest instances sent at join. High.
