# HANDOFF — 2026-11-18 — Missions decided (two changes after the 14:01 handoff); build next

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=docs/decisions, .planning/handoffs
**Time:** 2026-11-18 14:15 -05:00

★ START HERE: Goal (Alan 2026-11-18): build daily and weekly missions exactly as decided in `docs/decisions/2026-11-18-daily-and-weekly-missions.md`. Opening action: measure what an average player does per match for each mission action; then a short numbers note to Alan before code. Nothing about missions is built yet.

> Read on demand: AGENTS.md → THIS → [the 14:01 handoff](handoff-2026-11-18-1401-beta-lane-missions-decided-dev-unlock-skins.md) (full plan, pointers, holds) → the missions decision. Memories: explain-plans-in-text (new), plan-before-building-features.

## STATE (verify before acting — state drifts between sessions)
- HEAD after this handoff's commit, pushed. Confirm: `git rev-parse --short HEAD`. Docs: `python tools/check_docs.py` OK.
- Everything else as in the 14:01 handoff (Studio save 820 from Codex, 719 tests, dev unlock not yet tried in Play).
- Cost since 14:01: none (two doc edits). Main session context ≈ 43%.

## NEXT ACTION + PLAN
- Unchanged from the 14:01 handoff, steps 1 to 4, with the two changes below. Holds and the review stop rule are there too.

## DECISIONS & WHY (after the 14:01 handoff; in the decision page in his words)
- **A swap never gives back the same shape:** the replacement has a different action from the mission swapped out, daily and weekly.
- **The fixed weekly card is now "Finish 15 daily missions"** (Blue Ribbon chest, not swappable), replacing "all 3 dailies on 5 days", which left "not much wiggle room". 21 dailies come each week, so six can be missed. It keeps the week calendar: a day is ticked when at least one daily mission was finished that day.

## CONSTRAINTS / PRINCIPLES
- As in the 14:01 handoff.

## CARRY NOTES / GOTCHAS
- The 14:01 handoff's DECISIONS line "all dailies on 5 days" is superseded by this one; the decision page is current.

## WHAT SHIPPED / OTHER QUEUED
- This handoff's commit: the decision page's two changes and this record. Queued: as in the 14:01 handoff.

## KNOWLEDGE UPDATED
- `docs/decisions/2026-11-18-daily-and-weekly-missions.md`: swap rule and the 15-dailies card. Checker OK.

## POINTERS
- As in the 14:01 handoff.
