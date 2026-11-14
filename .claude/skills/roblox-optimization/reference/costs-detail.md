# Costs detail: needs the owner's OK first

Everything here can make the game look worse. In Alan's games the rule is
[never trade looks for frame rate](../../../../docs/decisions/2026-10-10-no-quality-cuts-for-fps.md): exhaust the
detail-keeping techniques in [SKILL.md](../SKILL.md) first, then bring one of these to Alan as a choice with a
before/after screenshot pair and the measured gain. Never apply one quietly.

| Technique | What you lose | Gain | Note |
|---|---|---|---|
| Lower a texture's resolution (below what it covers on screen) | Sharpness up close | GPU memory (4× per halving of each side) | Texture streaming already shrinks far textures for free; only shrink by hand for UI/Sky/Terrain (not streamed) |
| `CastShadow = false` on parts whose shadow is visible | Grounding, depth | Shadow-pass draw calls | Fine without asking on parts whose shadow can't be seen: prove with screenshots |
| `Light.Shadows = false` on visible key lights | Shadows from that light | Big GPU saving per light | |
| `RenderFidelity = Performance` | Mesh detail when FPS drops; UV damage seen on some meshes | Triangles | Automatic is the safe default |
| Mesh streaming / cloud LODs (`MeshStreamingAndImprovedLoDs`) | Usually none; 2026 bugs left meshes stuck at lowest detail | ~60% fewer triangles (Roblox example) | Test in a published client, compare screenshots |
| SLIM on buildings | Far buildings become merged stand-ins; unions, coplanar faces, UVs can go wrong | Far draw calls, triangles, memory | Needs published place + Team Create |
| Smaller `StreamingTargetRadius` | Far scenery disappears (unless SLIM/imposters) | Memory, join time | |
| Fewer / smaller / shorter-lived particles | Effect density | Overdraw | Often a redesign keeps the look: try that first |
| Partial transparency → 0 or 1 | Soft see-through looks | Overdraw, batching | Alpha cut-out textures often keep the look |
| Remove post effects (Bloom, DoF, SunRays) | Mood | GPU | |
| Built-in material instead of a custom texture | Hand-made texture | Memory | Only if it truly looks the same |
| Reduce Highlight outlines | Readability of targets | Per-object redraw | Readability is gameplay: owner decides |
| A game-made "low detail" mode keyed to device | Detail on weak devices | Frame rate on phones | Roblox already scales; don't key to `SavedQualityLevel` |
