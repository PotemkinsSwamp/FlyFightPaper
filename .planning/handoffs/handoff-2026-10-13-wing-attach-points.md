# HANDOFF — 2026-10-13 — FFA split, stickers on every wing, new Feather Folds, wing attachment points: all in

★ START HERE: Goal: Alan playtests everything (21 playtest notes + this session's plane work). Opening action: ask
Alan to Ctrl+S, then playtest; done when he has played and given rulings. Then Stage 6 (first 60 seconds), then
Stage 9 modes.

> Read on demand: AGENTS.md → THIS → state/STATE.md ("Waiting on Alan"). Memories: roblox-mesh-import-gotchas
> (sync delay), exact-collision-baked, studio-play-is-shared, no-surprise-desktop-control, measure-concept-before-brief.

## STATE (verify before acting)
- HEAD `711addbc` (main), NOT pushed. Confirm: `git rev-parse --short HEAD`.
- Tests 261/0 in Play (Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio: WORKING open in Edit, Play stopped, Rojo serve syncing (`curl -s http://localhost:34872/api/rojo`).
  Place NOT re-saved (needs Alan's Ctrl+S). The new pieces reached Studio through the Rojo sync with MeshIds; no
  save_place rebuild was needed.
- Cost this session: 3 Codex jobs (Sol, Alan's ChatGPT plan; Claude wrappers ~19k/33k/25k tokens): concept pictures,
  Feather Folds build, Feather Folds rework. 56 Open Cloud uploads (free, all Approved). 0 Meshy, 0 desktop control.
  Primary ~45% context.

## NEXT ACTION + PLAN
1. Alan: Ctrl+S, then playtest ("what to try" in state/STATE.md). Rulings → docs/PLAYTEST-NOTES or STATE decisions.
2. Then Stage 6 first 60 seconds → Stage 9 modes (Alan's order).
- HOLDS (Alan's go, each): private publish; Studio-settings changes; Meshy spend; anything paid; desktop control
  (only if necessary or asked); closing Studio. Uploads to his Roblox account also need his OK (the auto-mode
  classifier blocks them otherwise). Don't steer his plane while he's in Play.

## DECISIONS & WHY (this session)
- FFA split: body/nose/tail/booster paper+cardboard+tube cut at x=0 (tools/art/split_halves.py, renamed from
  split_wings.py; halves.json renamed from wing_halves.json). Closed pieces get their cut face filled (solid hit shapes);
  wings stay open (already uploaded). Accent/tape stay whole.
- Stickers: placeholder spots per wing found by ray search in Blender (STICKER_SPOTS in plane_pieces.py); Swept 75%.
  Aircraft.paint sizes stickers by placeholder width (STICKER_SPOT 1.85).
- Wing attachment points (Alan's design, his marked picture): body_heavy has WingFront/WingBack (flat side wall ends,
  x 2.6, y .62, z -1.92/3.68); every wing has RootFront/RootBack (x 1.32, y .83). Aircraft.wingFit scales the wing
  evenly so root lands on wall; bodies without points fall back to catalog wing_shift (toilet roll 1.35). Swept's
  RootBack is custom (3.42) so it stays 100%. Model attributes WingScale/From/To/Mount1/Mount2 carry the fit to
  clients (Aircraft.fitOf). Replaced the short-lived wing_drop (b709815d) — Alan wanted a system, not a number.
- Gun spots per wing (Alan): Mount1/Mount2 = 0.8 behind each wing's own leading edge at x 3.7/5.2 (EDGES table);
  old fixed spot left swept/delta guns in mid-air. Guns scale with the wing (fit.scale). Classic guns moved ~1.7 back.
- Cardboard body: smaller wings/guns there = slightly smaller target (noted in STATE decisions).
- Feather Folds: concept A (feather-a.png) chosen; rebuilt twice by Codex; Alan approved the second (round tips).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (look at the game, model router, STATE ≤60 lines, hard limits); CLAUDE.md (plain English, handoff last).

## CARRY NOTES / GOTCHAS
- Rojo sync of a rewritten pieces.rbxmx takes a few seconds: re-check every MeshPart.MeshId before judging.
- plane_set.py rebuilds EVERY set FBX (byte churn): keep only the changed part's files, `git checkout` the rest
  (after backing up Codex output). Only body_heavy has wall points; add WING_WALLS for new boxy bodies.
- plane_set.py's mount-clearance check still uses catalog wing_shift and the old fixed gun spots (not the new ones).
- Bell-tower + closeups.png + WORKING.rbxlx diffs in the tree are not ours: leave.

## WHAT SHIPPED / OTHER QUEUED
- Shipped: 711addbc STATE · e02a1719 Feather Folds in game · fc5a6174 Feather Folds closer to A · d3efb61e wing
  attachment points + per-wing gun spots · 065132ad Feather Folds A build · b709815d cardboard wing drop (superseded) ·
  6caed1c4 STATE · 7370bea1 feather concepts · 4ccbed57 stickers on all wings · e54623d8 FFA split live ·
  07a1899a halves cut.
- Queued: Track C saving (needs private publish); menu stage gaps; bot-vs-bot rams never land; last stand-in sounds.

## POINTERS
- src/shared/Aircraft.luau (wingFit/fitPoint/mountOffset/paint), tools/art/plane_pieces.py (STICKER_SPOTS, WING_WALLS,
  ROOTS, EDGES), tools/art/split_halves.py, assets/models/planes/set/renders/wings_5-compare.png,
  assets/models/planes/concepts/parts/feather-a.png. Previous: handoff-2026-10-13-ffa-body-split-next.md.
