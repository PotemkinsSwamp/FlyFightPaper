# HANDOFF — 2026-11-08 — weapon weights and tank bodies decided; build, re-make the bots, test

**Labels:** kind=product · lane=beta-lane · branch=main · issues= · areas=config/catalog.json, config/gameplay.json, src/shared/Catalog.luau, src/shared/BotBuilds.luau, tests/unit, docs/decisions, state/STATE.md
**Time:** 2026-11-08 22:26 -05:00

★ START HERE: Goal (Alan): the beta feels like a finished game, one map, a strong first-session hook. Supersedes
handoff-2026-11-08-2144 (same session, kept as the record; its STATE, shipped list and gotchas still hold). Next: build
the weapon weights and tank bodies Alan locked (decision note, "Weapon weights and the tank bodies"), re-make the bot
builds and presets that no longer fit and show Alan the bot builds with their numbers BEFORE coding them, then a bot
test (his go). Done when tests pass and the test shows no errors and no plane far off the rest. Then prices.

> Read on demand: AGENTS.md → this file → handoff-2026-11-08-2144-beta-lane-bots-fixed-weapon-sizes-then-prices.md
> (state, gotchas); docs/decisions/2026-11-08-unlock-ladder-and-bot-builds.md (all of Alan's calls, newest last);
> docs/systems/planes-and-hangar.md, weapons.md, bots.md. Memories: plan-before-building-features,
> bots-are-the-balance-test, attack-own-work-first, mute-studio-tests.

## STATE (verify before acting)
- HEAD = this handoff's commit on `main`; the commit hook copies each commit to GitHub. Confirm: `git log --oneline -3`.
- Tests 476/0 in Play (21:3x); docs OK (158 pages). Nothing built since the 2144 handoff: only decisions and docs.
- Studio: Edit mode, DevMute/DevBotTier cleared, Rojo connected (34872). Published v495; nothing saved/published.
- Cost this session: Opus main only, ~49% context at handoff, ~5h wall clock; no subagents, no Codex, nothing paid.

## NEXT ACTION + PLAN
1. Build (all decided by Alan, numbers in the decision note):
   - Staple weighs 2 (stays light); Crayon heavy; Spitball weighs 1.
   - One weight per gun: capacity both fills the plane and slows it (drop the separate `mass` in `Catalog:deriveStats`
     or set it equal to capacity); 2 studs/s of speed per weight point (`flight.speed_equipment_penalty_per_mass` was
     1.2); turn and Lift costs unchanged.
   - Cardboard Gunship (`body_heavy`): capacity 8, health 220. Toilet Roll Gunship (`body_heavy_mk2`): health 180,
     speed 87, turn 135, Lift 92, 5 gun slots (pick the mount types, e.g. heavy, heavy, medium, light, light), capacity 7.
   - Re-make what breaks: Popper Dart, Tack Skirmisher and Staple Tank bots; Bomber preset (Toilet Roll loses a slot).
     Bot builds = the strongest reasonable loadouts a player would make (try all-Pellets tanks too); show Alan first.
   - Check the hangar shows the right weight/speed (a plane-art slot removed? `Aircraft.mountOffset` is per slot).
2. Bot test (Alan's go): `python tools/run_bot_matches.py 1 75`, then full matches in the background.
3. Prices and unlocks from the 12 / 25 folds table (Alan's OK). 4. Text style C. 5. The unlock moment.
- Balance pass later: Spitball planes weakest; a 4-Paperclip Cardboard (bots never carry Paperclips).
- HOLDS (Alan's explicit go, each): publish (he does it), Save to File, any upload, desktop control, Studio Play while
  he's playing, a bot match, anything paid; any new mechanic or number before it's built.

## DECISIONS & WHY (since the 2144 handoff)
- Why the tanks dominated: health and guns multiply in a straight fight; being slower doesn't pay for it in a
  room-sized arena with 750-800-stud guns. Less Lift was rejected: it pushes tanks to camp the fans.
- Pellets weigh 1, so gun slots, not weight, cap a body's damage; hence the Toilet Roll drops to 5 slots.
- Toilet Roll = midpoint of Courier Fold and Cardboard on every stat (Alan).

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; memories above; lessons.md bot entries.

## CARRY NOTES / GOTCHAS
- See the 2144 handoff (Edit-VM `require` cache, Roblox ChatScript error, long Server calls drop replies).

## WHAT SHIPPED / OTHER QUEUED
- Since the 2144 handoff: 165a7c4b handoff · (this commit: decision note + STATE + this handoff).
- Queued: Save to File + publish (Alan's go); results card → report card (must do); winners' circle, skins, shop.

## KNOWLEDGE UPDATED
- decisions/2026-11-08-unlock-ladder-and-bot-builds.md: "Weapon weights and the tank bodies" replaces "Weapon sizes".
  STATE.md updated. Checker: OK.

## POINTERS
- src/shared/Catalog.luau (`deriveStats` mass/speed, `COMPATIBLE`), config/catalog.json (structures, weapons,
  classes), config/gameplay.json `flight.*_equipment_penalty_per_mass`, src/shared/BotBuilds.luau.
