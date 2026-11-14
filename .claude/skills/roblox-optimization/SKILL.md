---
name: roblox-optimization
description: Research-backed ways to make a Roblox game run faster without losing detail (often gaining it): rendering, memory, streaming, physics, networking, Luau, loading, phones, and how to measure each. Use BEFORE any performance, frame-rate, lag, memory, loading-time, crash-on-phone or "too many parts/textures" work in any Roblox game, before adding lots of new art, and run its before/after checklist on every speed change.
---

# Roblox optimization: faster without losing detail

Researched 2026-11-13 from Roblox's docs, staff posts and measured community work. Detail files:
[rendering](reference/rendering.md) · [memory, streaming, loading](reference/memory-and-streaming.md) ·
[physics and networking](reference/physics-and-networking.md) · [Luau](reference/luau.md) ·
[measuring and phones](reference/measuring.md) · [costs detail: needs the owner's OK](reference/costs-detail.md) ·
[sources](SOURCES.md). Each tip there has why, how to measure, source, date and confidence (**high** = Roblox docs,
staff or measured; **medium** = experienced developers; **low** = folklore). Roblox changes fast: anything marked
"in flux" gets its source re-read before use.

**The rule:** the look stays identical. Use the techniques below that keep or add detail; anything that can change
the look goes in [costs-detail.md](reference/costs-detail.md) and to the owner as a choice with screenshots.
**Fix what the profiler names**, not what a forum post fears.

## Checklist for every performance change
Before:
1. Say what's slow and where: frame rate (which spot, how many players), memory/crashes (which device), loading
   (first or later join), or server lag.
2. Measure with the [fair-test protocol](reference/measuring.md#a-fair-test-our-protocol): fixed camera spots, window
   in front, graphics Manual at max, warmed up, 10+ s average plus slowest 5% of frames. Record FPS, frame ms, draw
   calls, triangles, shadow draw calls, memory, and a screenshot per spot.
3. Read the MicroProfiler frame colour to pick the area: **orange** = scripts/physics ([luau](reference/luau.md),
   [physics](reference/physics-and-networking.md)); **blue** = render thread (too many objects/draw calls);
   **red** = GPU (triangles, textures, shadows, overdraw) ([rendering](reference/rendering.md)); memory or crashes
   ([memory](reference/memory-and-streaming.md)).
4. Pick the highest technique below that fits. Check the tip's date and confidence; re-read "in flux" sources.

After:
5. Same measurements, same spots. Keep the change only if the number moved.
6. Compare screenshots side by side at the same spots: no visible difference, or it's a detail cost and needs the
   owner's OK.
7. Phones: big memory or rendering changes get checked on a real phone (Studio and its emulator lie about speed and
   memory). Server changes: Server Jobs steps/s near 60, memory flat over a long session.
8. Write down the before/after numbers where the project keeps its performance notes.

## Top techniques that keep or add detail (try in this order)
1. **Reuse instead of unique** (adds): one mesh + one SurfaceAppearance drawn many times is about one draw call;
   vary with tint (`SurfaceAppearance.Color`), size and rotation. Upload a mesh once, duplicate in Studio; one
   asset id per real asset. Fewer ids also load faster and use less memory. [rendering §1](reference/rendering.md#1-instancing-the-biggest-free-lever-keeps--adds)
2. **Let the engine's 2025-26 systems carry the load:** texture streaming is automatic (sharp up close, cheap far,
   4K allowed); occlusion culling is automatic (make big walls/floors plain opaque so they hide what's behind);
   SLIM merges far static models (needs published place + Team Create); mesh streaming + cloud LODs (opt-in, buggy
   in 2026-08: test first). [rendering §2-5](reference/rendering.md#2-mesh-detail-by-distance-keeps--maybe)
3. **Instance streaming set up right:** on, Opportunistic, Improved, PauseOutsideLoadedArea, almost nothing
   Persistent. A bigger, more detailed world fits on phones. [streaming](reference/memory-and-streaming.md#instance-streaming-lets-a-bigger-more-detailed-world-fit-on-a-phone)
4. **Invisible savings:** decor gets CanCollide/CanTouch/CanQuery off and Box collision; exact shapes computed once
   in Studio, never at runtime; anchor what doesn't move. [physics](reference/physics-and-networking.md#collisions)
5. **Detail in textures, not geometry or lights:** alpha cut-outs for thin or lacy things, shading baked into the
   colour map, decals baked in, trim sheets, vertex colours. [rendering §5](reference/rendering.md#5-textures-and-surfaceappearance-keeps--adds)
6. **Cheaper ways to the same picture:** shadows off only where no shadow is visible, many unshadowed accent
   lights, fewer-but-fuller particles, transparency 0 or 1, one Highlight per model. [rendering §6-7](reference/rendering.md#6-lights-and-shadows)
7. **Client draws, server decides:** visuals, tweens and projectiles on clients; the server checks hits; the pilot's
   client owns their vehicle; batched `UnreliableRemoteEvent` updates (1,000-byte limit) for constant data.
   [networking](reference/physics-and-networking.md#remotes-and-bandwidth)
8. **Script time only where profiled:** spread work over frames, `task.*`, cache references, pool shots,
   `@native` on hot server maths, Parallel Luau for heavy independent work, no leaks. [luau](reference/luau.md)
9. **Loading:** preload only the first screen; keep ReplicatedFirst/ReplicatedStorage lean; reuse ids. [loading](reference/memory-and-streaming.md#loading-time)

## Common folklore (don't act on it)
"Roblox has no occlusion culling" · "max texture 1024" · "shrink every texture" · "localise globals for speed" ·
"`--!strict` is faster" · "`--!native` everywhere / on all clients" · "Persistent fixes streaming" · "hollow your
terrain" · "unions never instance" · "UnreliableRemoteEvent max 900 bytes" · "anti-lag scripts". Each is
explained, with dates, in its reference file.

## Fly Fight Paper
Ideas only; nothing here is decided. Alan's rule: [never trade looks for frame rate](../../../docs/decisions/2026-10-10-no-quality-cuts-for-fps.md).
Targets and history: [performance page](../../../docs/systems/performance.md), [lessons](../../../docs/workshop/lessons.md),
[optimization research 2026-11-13](../../../docs/research/OPTIMIZATION-RESEARCH-2026-11-13.md) (the ten best fits,
explained for Alan).
- **Already right (keep):** client shot visuals, `UnreliableRemoteEvent` for combat cosmetics, decor flags off on
  effects, exact collision baked in Studio, StreamingEnabled with the town `PersistentPerPlayer` and menus first,
  Future lighting.
- **Biggest structural cost:** almost nothing is reused (924 of 983 colour maps and 814 of 921 meshes used once):
  every piece is its own draw call and download. Reuse is the detail-keeping fix; new art should come as kits.
- **Repacked atlases were worse (2026-10-25: ~8× picture memory):** texture streaming likely explains it; a shared atlas
  stays at the sharpest level any user needs. Keep per-piece textures; share only true duplicates.
- **Settings to test first (cheap):** `StreamOutBehavior` Opportunistic, `ModelStreamingBehavior` Improved,
  `StreamingIntegrityMode` PauseOutsideLoadedArea (place currently on defaults). Measure phone memory before/after.
- **Phones:** measure on Alan's phone, not Studio; Android 2-4 GB is the common player device.
- Planes use one `Highlight` per other plane (max 11 with 12 planes, under the 31 cap); on phones their cost grows
  with screen area: measure in a full match.
- Studio Play is shared with Alan and grabs his mouse: ask before Play-based measuring when he's working.
