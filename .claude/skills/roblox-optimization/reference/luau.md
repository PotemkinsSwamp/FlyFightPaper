# Luau script speed

Script work shows in the MicroProfiler as orange frames (worker threads slower than rendering), `Heartbeat`,
`gameStepped` and `GC` bars, and in the Script Profiler. None of these tips changes the look. Fix only what the
profiler names: a script that takes 0.2 ms a frame is not the problem, however ugly it is.

Format: **tip**. Why. *Measure.* Source (date). Confidence.

## Frame budget first
- **Keep each frame's script work small and spread big jobs over frames.** 60 FPS = 16.67 ms per frame for
  everything; a 100 ms job in one frame means a 10 FPS hitch. Split loops with `task.wait()` or do N items per
  frame. *MicroProfiler: wrap suspects in `debug.profilebegin("Name")` / `debug.profileend()` (same thread).*
  [Improve](https://create.roblox.com/docs/performance-optimization/improve), [Design](https://create.roblox.com/docs/performance-optimization/design) (current). High.
- **Pick the right frame event.** `PreRender` (old `RenderStepped`) runs before drawing: camera only, it delays the
  frame. `PreSimulation` (old `Stepped`): set physics state, Motor6D transforms. `PostSimulation` / `Heartbeat`: read
  physics results, general game logic. `BindToRenderStep` when order matters.
  [Task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler) (current). High.
  Folklore: "PreRender is fastest" (a 2024 forum test of event *latency*) is not a reason to put work there.
- **One script loops over many objects** (all lamps, all pickups) instead of one script per object, and react to
  events instead of `while true do` polling. Hitchhiker's Guide thread (2025-01). Medium.
- **`task.wait/spawn/defer/delay`, never `wait/spawn/delay`.** The old ones run on a throttled legacy path.
  [Task library](https://devforum.roblox.com/t/task-library-now-available/1387845) (staff, 2021). High.

## Native code generation (`--!native`, `@native`)
- **Put `@native` on hot number-crunching functions, not on everything.** Compiles Luau to machine code: big wins
  on maths, loops, tables and `buffer` work; no win on engine calls (Raycast, property reads, FindFirstChild), which
  already run in C++. Costs memory and server start time; a game-wide cap stops compiling once reached; a block over
  64K instructions, a function over 32K blocks or a module over 1M instructions fails.
  *Script Profiler with and without (native functions show `<native>`); `debug.dumpcodesize()` in the server command
  bar.* [Native code gen](https://create.roblox.com/docs/luau/native-code-gen) (current);
  [staff update](https://devforum.roblox.com/t/luau-native-code-generation-preview-update/2961746) (2024-05-08). High.
- **Where it runs (check again, it changes):** servers and Studio since 2024-05-08; the docs say clients only on
  Android. PC/Mac/iOS clients run the plain version, and a 2026-08 bug report says you can't tell from a live client
  whether it compiled. So it is a **server** tool (bots, hit checks) unless the docs say otherwise. High (docs).
- **Annotate argument types correctly, especially `Vector3`.** Native code specialises on annotations; a *wrong*
  annotation is slower than none (one 2026-01 benchmark: wrong type 4x slower).
  [Type hints benchmark](https://devforum.roblox.com/t/optimizing-native-code-performance-with-type-hints-and-magic/4247690) (2026-01-12). Medium (one author).
- Breakpoints switch native off for that function: profile without them. High.

## Language-level (Luau's own guide, [luau.org/performance](https://luau.org/performance))
- Call builtins directly: `math.max(x, 1)`, `string.byte(s)` (fast path) rather than `s:byte()`. High.
- Keep table shapes stable, use constant field names, point `__index` straight at a table. Field lookups are
  cached. High.
- `table.create(n)` when the size is known; fill by index into a pre-sized table; `table.insert` when size is
  unknown. Avoid making temporary tables, closures or Vector3s inside hot loops (garbage = `GC` bars). High.
- `for k, v in t do` (generalised iteration) is as fast as `pairs`/`ipairs`. High.
- Avoid `getfenv`, `setfenv`, `loadstring`: they switch off optimisations for the whole script. High.
- `--!strict` finds bugs; it does **not** make code faster by itself (only the annotations it encourages help native
  code). [Luau type checking release](https://luau.org/news/2020-11-19-luau-type-checking-release/). High.

## Parallel Luau (Actors)
- **Use it for heavy, independent work** (many bots' decisions, server hit validation, generation): compute in
  parallel, then `task.synchronize()` and write results. More Actors than cores (docs example 64 on 4 cores);
  `require` before desynchronising; most instance writes are not allowed in parallel (check each API's safety tag).
  [Multithreading](https://create.roblox.com/docs/scripting/multithreading) (current). High.
- **Overhead is real; measure the real workload.** One test: 20 Actors 4x *slower* than serial on small jobs.
  [Forum test](https://devforum.roblox.com/t/using-parallel-lua-to-speed-up-computations/3238248) (2024). Medium.
- **`SharedTable` is ~10x slower than a plain table** (staff measurement): pass instructions in and results out in
  bulk, never chat through it. [SharedTable best practices](https://devforum.roblox.com/t/sharedtable-best-practices/2574316) (staff, 2023). High.

## Leaks (memory that grows over a long server)
- **Disconnect connections, destroy what you create, clean per-player tables on `PlayerRemoving`.** Turn on
  `Workspace.PlayerCharacterDestroyBehavior`. Use weak tables (`__mode = "k"`) for caches keyed by instances.
  Maid/Trove/Janitor are community helpers for the same thing.
  *Developer Console: `LuaHeap`, `InstanceCount`, `PlaceScriptMemory`, `Signals` trending up over a long session;
  Luau Heap tab: take two snapshots and compare; "Unparented Instances" finds leaked parts.*
  [Improve](https://create.roblox.com/docs/performance-optimization/improve), [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage). High.

## Engine boundary
- **Find once, keep the reference.** No `FindFirstChild`/`WaitForChild`/`GetService`/`GetDescendants` inside
  per-frame loops; keep sets in a table or use CollectionService tags. Indexing vs FindFirstChild speed is argued
  both ways (a 2025 benchmark: indexing faster under ~100 children); caching beats both. Medium.
- **Procedural animation: write `Motor6D.Transform` in `PreSimulation`**, not `C0`/`C1` (Transform is the per-frame
  channel animators use). [Task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler). Medium-high.
- **No `print`/`warn` spam in live builds:** output in a hot loop costs time. Medium.
- **Write one `CFrame`, not Position then Orientation** (each write is a separate engine call). Medium-low (2022
  benchmark, disputed).
- **Many non-physics parts moving each frame: `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)`**
  (one engine call). Anecdotal gains only; measure first.
  [RTS case](https://devforum.roblox.com/t/how-we-are-developing-an-rts-game-with-good-performance-for-more-than-200-units/3281168) (2024). Medium-low.
- **Pool short-lived parts** (shots, sparks) instead of `Instance.new`/`Destroy` per use. Widely recommended, never
  rigorously measured; the quoted "10-50x" numbers are self-reported. Measure at your real shot rate. Medium.
- **`buffer` for big numeric data and network packing.** Flat memory, native-friendly; the docs make no speed claim,
  and a staff note says copying in and out of tables can cost more than it saves. Use it when the whole pipeline
  stays in buffers. [Buffer beta](https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894) (2023-24). Medium.

## Folklore and outdated (don't follow)
| Claim | Truth |
|---|---|
| "Localise globals (`local floor = math.floor`) for speed" | Obsolete since Luau imports/fastcalls (2019-20); readability only. |
| "`ipairs` is slower" | Generalised iteration ≈ pairs ≈ ipairs. |
| "`--!strict` makes code faster" | Only via annotations under `--!native`. |
| "`--!native` everywhere" / "native speeds up API calls" | Use selectively; engine calls don't change. |
| "Native runs on all clients" | Docs: server, Studio, Android clients. |
| "Parallel Luau is always a win" | Can be slower on small or uneven jobs. |
| "Anti-lag scripts help" | They usually add work; fix the real cost. |
