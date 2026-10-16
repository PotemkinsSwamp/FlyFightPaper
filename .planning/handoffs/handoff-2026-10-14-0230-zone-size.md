# HANDOFF — 2026-10-14 — zone resized and test-mode buttons moved (follows handoff-2026-10-14-stage-9-zone.md)

★ START HERE: Goal: finish Stage 9 so Alan approves it. Opening action: get Alan's playtest notes on the moving
Airspace zone (now 600 across), hidden paper targets and the hangar "mode: …" buttons; fix what he finds.
Done when Alan approves Stage 9.

> Read on demand: AGENTS.md → THIS → handoff-2026-10-14-stage-9-zone.md (plan, decisions, gotchas) → state/STATE.md.

## STATE (verify before acting)
- HEAD: this handoff's commit on main, local only. Confirm: `git log --oneline -3`.
- Tests 267/0 (Play, Server): `require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`.
- Studio WORKING open in Edit, Rojo syncing. Place NOT re-saved (Alan's Ctrl+S).
- Cost since the last handoff: 0 agents, 0 uploads; 1 Play check (zone at 3x: 59 FPS).

## NEXT ACTION + PLAN
- Same plan as handoff-2026-10-14-stage-9-zone.md "NEXT ACTION + PLAN" (playtest fixes → unseen checks →
  bots in Airspace → obstacle workshop with Alan → bots per mode → Stage 9 approval). Holds unchanged.

## DECISIONS & WHY (since the last handoff)
- Test-mode buttons live on the hangar dev row (Alan: "this is our dev env buttons"); the main-menu one is gone.
- Zone radius: 200 → 600 (Alan: "3x bigger") → 300 (Alan: "too large, reduce by 50%"). Ceiling spot recentred to
  (-300, 545, -100), radius 475, so it stays inside the room.

## WHAT SHIPPED
- 7e00d64a zones 3x + mode buttons moved · 4e31dd1a zones halved to 300 radius · this handoff commit.
