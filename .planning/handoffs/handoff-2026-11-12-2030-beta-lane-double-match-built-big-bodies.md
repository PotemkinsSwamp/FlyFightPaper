# HANDOFF — 2026-11-12 — Double this match built and working (exact, saved lock); big bodies 3 mounts; Alan's shop notes queued

**Labels:** kind=product+ui · lane=beta-lane · branch=main · issues= · areas=src/client/RoundEnd.luau, src/client/FoldOffer.luau, src/client/ShopScreen.luau, src/client/PaperUI.luau, src/server/{HangarService,CommerceService,ProfileService,ProfileRuntime,RoundRuntime}.luau, src/shared/{CommerceRules,ProfileSchema,Catalog,BotBuilds}.luau, config/{commerce,catalog}.json, tests/unit, docs/
**Time:** 2026-11-12 20:30 -05:00

★ START HERE: Goal (Alan): the beta feels finished and the shop makes money. First run a bot match on the new 3-mount big bodies (Alan's go given: "next session, first"; when he isn't playing) and report whether the Cardboard/Toilet Roll tanks still win too often. Then build his three playtest notes (below). Done = bot numbers reported to Alan in plain words; each note built and seen in his Studio Play.

> Read on demand: AGENTS.md → this file; then [playtest note](../../docs/playtests/2026-11-12-double-this-match-and-shop.md) (his notes, pictures in `.planning/`), [big bodies decision](../../docs/decisions/2026-11-12-big-bodies-three-mounts.md), `docs/workshop/testing.md` (bot matches, test runner). Skill: `design-theory` before any screen. Memories: alan-does-play-checks, studio-play-grabs-mouse, mute-studio-tests, bots-are-the-balance-test, plan-before-building-features, text-fits-its-box, fix-the-annoyance-only.

## STATE (verify before acting)
- HEAD `1521476d` + this handoff (main), pushed by the commit hook ("github: pushed"). Confirm: `git rev-parse --short HEAD`.
- Tests: 559 pass / 0 fail, 40 suites (2026-11-12, after the big-body change). Re-run: Studio Play, then on the server `task.spawn` the runner in `docs/workshop/testing.md`, write the result to a workspace attribute, read it in a short call (long server calls drop their reply).
- Studio: open on the place, Edit mode, DevMute off; `rojo serve serve.project.json` running (port 34872, Studio linked; Alan thought it wasn't, it was). Nothing published, nothing Saved to File.
- Cost this session: main Opus (long, ~400k context at wrap); 2 Codex jobs on Alan's ChatGPT plan (~7 min server half of Double this match; ~10 min saved lock), each wrapped by a codex-rescue agent (~36k tokens); 1 message to the design-theory side session (it ran its own turn: why the green looked wrong); 4 short muted Studio test runs; no bot matches, no uploads, nothing paid.

## NEXT ACTION + PLAN
1. **Bot match** on the 3-mount big bodies (go given): `python tools/run_bot_matches.py` in the background, muted, only while Alan isn't playing. Report kills/deaths for the two tank builds vs the rest; if a big body still dominates, propose numbers (his go before changing any).
2. **Studio-only dev toggle** (Alan): a button always on screen (bottom right, not at the desk), only for him and only in Studio (`RunService:IsStudio()` + his account / `Dev` attribute), switching his profile between real (level 12, free gear at its level) and everything unlocked, so he can look at the big bodies in the Hangar. Never reachable outside Studio. Existing pieces: workspace `DevAccountLevel`/`DevAccountPaper` (set before Play, `ProfileRuntime.luau`, `Hangar.luau`). Done = he flips it in Play and the Hangar follows.
3. **Centre the shop's models** on their true (bounding-box) middle: Long Point and Spool Booster poke out of their circles (`.planning/shop-off-centre-models-alan-2026-11-12.webp`). Probably the shared part view (`UnlockMoment.view` / `partView`), so the fold card and Hangar get it too. Check on a screenshot.
4. **Starter pack items** (and cards of that design): no cream square, no circle; the model floats on `PaperUI.shadow`, its words on a small dark plate (`.planning/starter-pack-items-alan-2026-11-12.webp`). Assembled preview before showing him.
5. Then: Paper jar shop card + its "wait for more" warning (new art: assembled preview, his upload go), Gift a friend how-it-works note, goals review with Alan.
- HOLDS (his explicit go, each): any upload, publish (he does it), Save to File, desktop control or screen grabs (only when truly blocking), Studio Play while he plays, a bot match beyond step 1, anything paid, any new mechanic or number.

## DECISIONS & WHY (this session)
- Double this match locks are **saved in the profile** (`doubleLocks`, schema 11), not server memory (Alan): a receipt re-sent to another server still pays exactly. The lock pays nothing; the buy window opens only once the lock is confirmed stored; one lock per price. The leftover edge needs a save outage through a whole match: accepted.
- 75-Paper minimum kept (below it the cheapest price is worth more than the payout).
- Big bodies 3 mounts (heavy, heavy, medium); Cardboard 10, Toilet Roll 8 (Alan leaned 8 over 9 "might be fair"): [decision](../../docs/decisions/2026-11-12-big-bodies-three-mounts.md). Tank bots chosen by me as strongest reasonable: Toilet Roll 3 Pellets, Cardboard 2 Crayons + Pellet.
- Shop circles mint green (tint 96,170,153; the chalk green came out olive because the tint multiplies the cream); coloured cards (passes, Your next part) use a soft shadow, circles only on white cards (Alan).
- Fold card: free gear never offered; red "Not now" replaces the X when you can already buy.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md (docs rules, model router, hard limits). Memories listed above. `docs/workshop/lessons.md` (new: "owned" = `Catalog:owns`; `ImageColor3` multiplies).

## CARRY NOTES / GOTCHAS
- Alan hasn't yet commented on: the mint green itself, the shadows, the fold card fixes, big bodies in the Hangar (locked for him until the toggle).
- The design-theory skill tool may serve an old copy; read `.claude/skills/design-theory/SKILL.md` from disk.
- Output warning `UIStroke is not a valid member of TextLabel "CrayonInk"` (PaperUI refresh) still not looked into.
- In practice buys `MatchDoubled` is set at press, so Studio never shows "One moment..."; live shows it until the receipt.
- Gun crowding shrink code in `Aircraft.luau` may now be unused (no body has crowded wing mounts); its test assertion was removed with the 6-mount body.

## WHAT SHIPPED / OTHER QUEUED
- 2c7126d3 Report card: Double this match; 2x boosts 10/15/25/69/99 R$
- 61ea43a7 Double this match: the locked amounts live in the save, so the receipt pays exactly on any server (Alan)
- 1c9b7a9b Fold card: never for free gear; red "Not now" button instead of the X (Alan)
- 1b4b8166 Shop: no circle behind the 2x Forever pass pictures, a soft shadow instead (Alan)
- 2600dc63 Why the shop's green looks wrong in Play (design-theory side session)
- f5b85bb8 Big bodies: 3 mounts; Cardboard carries 10, Toilet Roll 8 (Alan)
- e7f46966 Shop: mint green circles; Today's parts circles clear of the price label
- 29115e4e Shop: Your next part card soft shadow; Double this match keeps its 75 minimum
- 1521476d Playtest note: off-centre models, starter pack items, dev toggle (Alan)
- Queued: steps 1-5 above; XP line on the report card, bots that use the town, skill bonuses, part model redo (`docs/plan/IDEAS.md`).

## KNOWLEDGE UPDATED
- Systems: economy-and-shop (Double this match products and saved lock, `doubleLocks` field, boost prices, circles/shadows, 30 offers); menus-and-hud (report card button, fold card buttons, free gear); planes-and-hangar (3-mount big bodies, `Catalog:fitMounts`). Plan: SHOP-PRICES-PLAN boost prices.
- Decisions: double-this-match (built, seen working, 75 kept), big-bodies-three-mounts (new), fold-card-and-shop-mats (mint pick). Playtest: 2026-11-12-double-this-match-and-shop (new). Lessons: two lines. testing.md count 559. Design-theory SKILL.md palette row.
- `state/STATE.md` rewritten (58 lines). Checker: `python tools/check_docs.py` OK (182 pages).

## POINTERS
- `docs/plan/SHOP-MONEY-PLAN.md` · `docs/workshop/design-examples.md` (fourth study: the green) · `src/server/ProfileRuntime.luau` (`confirmDoubleLock`) · `tools/run_bot_matches.py` · `tools/studio_cli.py`
