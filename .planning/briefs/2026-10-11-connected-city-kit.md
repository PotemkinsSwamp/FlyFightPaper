# Connected city: kit pieces, ruler bridges, fly-through ceiling, big bell tower (Alan, 2026-10-11)

Why: Alan played it ("it plays good") but the city feels spread out and lost the fly-through buildings that let you
shake a chaser or an eraser (only the Gateway arch is flyable now). Mood boards: `assets/references/connected-city/
concept-*.png` (NOT a plan: they put buildings in streets and connect things that can't connect).

## Alan's rulings (final)
1. **Bell tower: yes, very large.** Claude proposes its spot in the layout preview (may move one building aside).
   About 430 tall (tallest building now 265; ceiling 620), ground arch ~110 wide and open belfry with a bell ~90
   wide, both flyable. One hero model (Codex, Blender, house toy style), exact collision.
2. **Ceiling: every ceiling decoration must be fly-through** (a utility, not just decoration): hoops/rings, hanging
   tube tunnels, paper-chain arches you fly under/through, lanterns only as part of a fly-through piece. Keep lanes.
3. **Buildings stay where they are;** connect neighbours that are already close (bridges, tubes). No sliding blocks.
4. **Make once, place many.** No new asset per bridge. Reuse the 50-piece kit (`assets/models/kit/pieces.json`:
   bricks 1x1/2x2/2x4, ruler-cornice, pencil-column, book-slab, tape) and add: ruler-bridge SECTION (repeats end to
   end, a tape strip hides each joint, so any length = N sections), pencil stilts (legs), cardboard tube tunnel,
   ceiling hoop/ring, hanging tube. Bricks may scale uniformly; rulers never stretch.
5. **Tight collision:** every piece exact (PreciseConvexDecomposition, baked once and saved; save_place keeps it).

## Placement rules (Claude)
- Read real building footprints and roof heights from the place. A bridge joins two buildings at matching heights;
  legs stand on roofs or grass, never in streets; nothing overlaps; keep flight lanes.
- Show Alan a top-down layout preview (rug-layout-review memory) before placing anything.
