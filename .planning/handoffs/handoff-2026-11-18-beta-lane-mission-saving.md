# HANDOFF | 2026-11-18 | Mission saving ready for Claude's Studio check

**Labels:** kind=data+ui ? lane=beta-lane ? branch=main ? issues=none ? areas=src,tests,docs,state
**Time:** 2026-11-18 15:50 -05:00

START HERE: Review the uncommitted mission save changes on main, then try a free swap, a paid swap and all reward types on the Studio practice profile. The check passes when the displayed cards and Paper, XP and chest balances agree with the saved operation results.

> Read on demand: [AGENTS.md](../../AGENTS.md), [mission decision](../../docs/decisions/2026-11-18-daily-and-weekly-missions.md), [saving](../../docs/systems/saving.md#daily-and-weekly-missions).

## STATE
- Main started at 875d3ccc. Mission saving changes are in the working tree. GitHub's snapshot branch uses independent history.
- Docs checker passed. The new and updated mission tests were read against the code. Studio tests and screenshot checks are pending.
- Alan asked Codex to leave Studio, the place file and Git commits alone for this task.
- Cost: no subagents. Primary token count unavailable.

## NEXT ACTION + PLAN
- Verify the mission save and screens in Studio using [the test runner](../../docs/workshop/testing.md#rule-tests-automatic) and **Dev: finish missions**. Check the claim message, balances, both tabs and the note under Chests on desktop and phone.
- Connect the report card slip to the per-player `MissionsFinished` event for Claude's client work. Its argument is an array of newly finished generated card records. The fixed card becomes claimable in the profile view once the 15th daily finishes.
- Follow the project's review and publish gates.

## DECISIONS & WHY
- The save writes a rollover and its payouts together, including when the requested Claim is refused for the new period.
- Match statistics keep their own completion time. Stale, ineligible and malformed mission summaries skip progress while the remaining reward operations continue.
- Paper progress includes captured boosts when the reward is sent. The existing base-Paper fallback applies if boost capture is unavailable.

## CONSTRAINTS / PRINCIPLES
- [Project instructions](../../AGENTS.md) cover Studio review, saving safety and Alan's sign-off.

## CARRY NOTES / GOTCHAS
- A Studio-only finish preserves claimed flags. To see every Claim button, start a fresh practice profile.
- Studio visual checks still need to confirm that the feedback text fits the Missions sheet and the new Chests line is centered.

## WHAT SHIPPED / OTHER QUEUED
- Mission saving, claims, swaps, the server report card hook and the Studio button are uncommitted.
- The client report card slip is queued for Claude.

## KNOWLEDGE UPDATED
- [Saving](../../docs/systems/saving.md#daily-and-weekly-missions) covers the new save field and operations. [Economy and shop](../../docs/systems/economy-and-shop.md#classroom-treasure-chests) covers the chest mission change. [State](../../state/STATE.md) lists what Alan can try.
- `python tools/check_docs.py` passed. No new workshop lesson.

## POINTERS
- `src/server/ProfileService.luau` owns mission settlements. `src/server/ProfileRuntime.luau` and `src/server/RoundRuntime.luau` deliver the report card event.
- Mission regression tests are in `tests/unit/Missions.spec.luau`, `ProfileSchema.spec.luau`, `ProfileService.spec.luau`, `ProfileRuntime.spec.luau`, `RoundRuntime.spec.luau` and `ShopSave.spec.luau`.
