# HANDOFF - 2026-11-18 - Ninja installed and five Legendary trails saved in the game

**Labels:** kind=product+docs · lane=beta-lane · branch=main · issues=none · areas=assets/models,config,src/client,src/shared,tools/art,tests,docs,state
**Time:** 2026-11-18 01:07 -05:00

★ START HERE: The Ninja skin and all five matching Legendary trails are in the private Studio game. If Alan continues the skin rollout, open the four remaining skins' effect sheets and identify which are ready for a separate skin upload. This step is done when each sheet has a recorded verdict and any concern is shown on the matching plane.

> Read on demand: [project rules](../../AGENTS.md), [current state](../../state/STATE.md), then this dated record. The [previous beta handoff](handoff-2026-11-17-1951-beta-lane-ninja-safe-five-layer-pictures-made-videos-with-alan.md) identifies the approved model folders and moving-layer sheets.

## STATE (verify before acting)

- Gameplay checkpoint `7e488b7c` on local `main`. The GitHub snapshot matched remote `main` before this documentation commit. Check with `git rev-parse --short HEAD`, `git rev-parse github-snapshot` and `git ls-remote origin refs/heads/main`.
- Team Create saved version 783. The local working place was rebuilt and checked against source. FlyFightPaper was in Edit with Rojo connected on port 34872 at handoff. Check with `python tools/studio_cli.py list_roblox_studios` and `Get-NetTCPConnection -LocalPort 34872`. Another project also has a Studio window open.
- Last Studio result was 676 passed, 0 failed across 46 suites. To repeat in a Play server, run `return require(game.ServerStorage.FlyFightPaperTests.unit.TestRunner).run()`. [Flight results and five screenshots](../../docs/playtests/2026-11-18-legendary-trails.md).
- Cost evidence: about 4 h 57 min from the first Codex work commit to the saved place, including time between Alan's reviews. Three existing helpers worked on catalog, export and runtime for the upload. Per-agent token counts, model breakdown, primary context usage and active work time were unavailable.

## NEXT ACTION + PLAN

1. If Alan resumes the existing beta plan, check the remaining moving-layer pictures for Shark Jet, Stealth, Hot Rod and Race Car. Their rebuilt movement previews already have his approval. The four skins still need their own release.
2. Carry safe assets through the skin release when authorized, then check each moving skin with its matching trail in flight. The approved trail work is complete. A reproducible in-game difference or new feedback from Alan is the reason to revisit it.
3. The trail shop list, Hangar trail previews and Galaxy plus Circuit Trace performance remain queued in [STATE](../../state/STATE.md). Alan can pick a different next task.
- The last upload instruction covered the five trails. Public publishing stays with Alan. Apply the existing asset review and release rules to the four skin models.

## DECISIONS & WHY (this session)

- Ninja's scarf follows the plane's movement. Its wing metal catches the light. The rigid hull handles hits so the loose cloth remains cosmetic.
- Alan chose Ninja's brushed stars and smoke, Hot Rod's blue-core flame, Shark's rolling jet with an occasional hinged bite, Stealth's continuous background-bending wake, and Race Car's original tire smoke and tread scraps with intermittent sparks. The large skid marks were tried and dropped. Hot Rod's tube backfires belong to the skin. [Decision history](../../docs/decisions/2026-11-16-first-skin-set.md).
- Alan requested a dated handoff after every major Codex task so Claude can follow the work. Codex continues this chat with automatic compaction. [Project instructions](../../AGENTS.md#keeping-the-docs).

## CONSTRAINTS / PRINCIPLES

- The project's [art, Studio and release rules](../../AGENTS.md) apply. For authoring and upload details, use [workshop lessons](../../docs/workshop/lessons.md).

## CARRY NOTES / GOTCHAS

- Ninja grants Smoke Bomb, including to existing owners on load. Shark Jet grants Water Spray through its existing catalog entry. Its new body still awaits installation. Backfire, Cloaking Wake and Photo Finish work in the Studio trail selector while their respective skin ownership routes await release.
- Cloaking Wake retains the internal ID `silver_chaff`. Its native glass bends the scenery on supported desktop graphics. Mobile refraction is unavailable. The approved shared atlas and eight mesh IDs are already recorded in `config/trails.json`.
- Rojo can sync the cloak's 13 bind bones with an empty mesh ID. The renderer reconstructs the wake using the uploaded mesh and those bones. For asset loading checks, preload the real textured MeshPart. A bare-ID request reported failure in the same session where the actual piece and texture loaded successfully.

## WHAT SHIPPED / OTHER QUEUED

Commits since the previous beta handoff, oldest first:

- `148685ae` Record approval of the rebuilt skin animations
- `bf3ad5d5` Rig the Ninja scarf and animate its silver wing blades
- `c3db9bad` Add the Ninja skin with a flowing scarf and shining wing blades
- `163e7d77` Build five matching Legendary trail previews
- `0353d718` Optimization skill: what the Gemini answer adds, and its mistakes (separate Claude work in the same checkout)
- `fe48498e` Give each Legendary exhaust trail two new visual treatments
- `516673ad` Save the five side-by-side Legendary trail reviews
- `2beb8308` Keep the chosen trail looks and build the shark wake and racing sparks
- `9b396493` Save the shark bite and twin-track spark previews
- `354e5076` Add jumping steel sparks and the Stealth cloaking wake previews
- `efd9bdd6` Save the Cloaking Wake and racing spark flight clips
- `bb3c8013` Give Race Car grinding sparks and Stealth a continuous cloaking wake
- `220f5095` Give Race Car occasional sparks and broad skid marks
- `cf7dbd48` Restore Race Car tread scraps and space out the spark bursts
- `2006f3b4` Upload the approved Legendary trail art and retain the glass wake rig
- `6c2672dd` Equip and draw all five Legendary trails in flight
- `7e488b7c` Save the working place and verify the five trails in a match

## KNOWLEDGE UPDATED

- [Planes and hangar](../../docs/systems/planes-and-hangar.md) covers the renderer, selector and Ninja skin.
- [Saving](../../docs/systems/saving.md) records the bundled-trail backfill and preservation of equipped choices.
- [Skins plan](../../docs/plan/SKINS-PLAN.md#five-new-legendary-trails) names the five approved looks and their previews.
- [Decisions index](../../docs/decisions/README.md) points to Alan's trail choices. The [playtest index](../../docs/playtests/README.md) points to the Ninja and five-trail flight checks.
- [Workshop tools](../../docs/workshop/tools.md) lists the atlas, exporter and template recovery tools. [Lessons](../../docs/workshop/lessons.md) records the detached bone recovery.
- [STATE](../../state/STATE.md) carries the current beta queue. The docs check passed for 199 pages using `python tools/check_docs.py`.

## POINTERS

- Game save: `FlyFightPaper-WORKING.rbxlx`. Source: `src/client/PlaneTrails.luau`, `src/client/LegendaryTrailEffects.luau`, `src/client/NinjaMotion.luau`.
- Asset records: `assets/models/trails/legendary-uploaded.json` and `assets/models/trails/cloak-stream.rbxm`. Approved videos and Studio screenshots: `.planning/skins/trails/legendary-review/`.
- Remaining skin art: `.planning/skins/motion/<skin>/layers/`. The [November 17 handoff](handoff-2026-11-17-1951-beta-lane-ninja-safe-five-layer-pictures-made-videos-with-alan.md) names each sheet and the specific Stealth glow concern.
