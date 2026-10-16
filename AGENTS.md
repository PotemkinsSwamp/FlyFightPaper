# Paper Plane Dogfight — instructions for the coding agent

Owner: Alan. He is not an engineer. Talk to him in plain English: what changed, what it means, what he
should try. Never paste logs, hashes or jargon at him. Bad news first, plainly.

## The goal
A fun, finished, private Roblox paper-plane dogfight game that matches `docs/vision/VISION.md`.
**Playable beats proven.** Progress is measured by what Alan can do when he presses Play, nothing else.

## Read these (and only these) at the start of a session
1. This file.
2. `state/STATE.md`: where we are. Short, plain English.
3. `docs/plan/MILESTONES.md`: the plan: stages, tracks, quality bars and Alan's gates. Follow it.
4. `docs/vision/VISION.md`: what the game must be. Alan's word is final on product choices.
Read when relevant: `docs/HOME.md` is the map of every doc. Rule details for a system are on its page in
`docs/systems/`; Alan's choices in `docs/decisions/`; playtests in `docs/playtests/`; how-to and hard-won lessons in
`docs/workshop/` (read `docs/workshop/lessons.md` before uploads, model work or place rebuilds). Also
`config/*.json` (tuning numbers), `assets/references/classroom-city-approved-v1.png` (art target).

## Keeping the docs
- **Each fact lives in one page**; other pages link to it. Never copy text between pages.
- When a system changes, update its page in `docs/systems/` ("Where it stands", rules, code). When Alan decides
  something, add a note to `docs/decisions/` and list it in its README. After a playtest, add a note to
  `docs/playtests/`. New hard-won lesson: `docs/workshop/lessons.md`.
- New pages use the same headings as their neighbours and get linked from `docs/HOME.md` (directly or through an index).
- `python tools/check_docs.py` checks links, unlinked pages, and that every `src/` file and tool is named on a docs
  page (and every file named still exists). It runs automatically before every commit (`.githooks/pre-commit`,
  turned on with `git config core.hooksPath .githooks`); a stopped commit means fix the docs, never skip the check.
  New code file = add it to its system page's Code table in the same commit.
- **Every handoff does a docs check-up** (handoff skill step 4b): update the pages for what the session changed,
  add decision/playtest/lesson notes, run the checker. The commit hook catches broken structure; the handoff
  catches stale content.
- STATE.md stays the short "right now" page (rules below); details belong on the system pages.

Old process files live in `D:\FlyFightPaper-ARCHIVE-2026-10-06\`. Do not read them unless you need one
specific old fact. Never copy them back, and never recreate that evidence system.

## How to work
- **One source of truth:** Luau code lives in `src/` in THIS repo (`D:\FlyFightPaper`, branch `main`).
  Live-sync code into Studio with `rojo serve serve.project.json` (code only: the full town is too big for a live
  sync and hangs Studio). Art reaches the place file through `tools/save_place.py` (builds `default.project.json`).
  Do not hand-install scripts into the place file.
- **One place file:** `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx`. Save it after meaningful changes.
- **Use Roblox, don't rebuild it.** Prefer built-in physics, network ownership, collision queries
  (Raycast/Shapecast/GetPartsInPart), StreamingEnabled, TweenService, ProfileStore-style saving, etc.
  over hand-written replacements.
- **Replace, don't copy.** Never create numbered versions of files (`Thing477.luau`, `Thing500.luau`).
  Edit the file; git keeps history. Delete code that is no longer used.
- **3D models are assets, not code.** Reuse the models we already have in `assets/models/` (Meshy and
  Blender). For anything new, search Roblox's free Creator Store first and use it when it matches the look or works
  (Alan, 2026-10-12; strip/read its scripts); then Codex Blender; Meshy (`MESHY_API` in `.env`) last; see M4.
  Upload through Open Cloud (`ROBLOX_API`) or use free Creator Store models. Never store geometry or pixels
  in Luau files.
- **No probe sprawl.** Throwaway debug scripts go in your temp folder and get deleted. Nothing like
  `artifacts/` or `evidence/` gets recreated in this repo.
- **Commit small and often** with plain messages ("Bots now avoid walls"), not process notes.
  **Push after every commit** (Alan, 2026-10-16): small pushes all through the session, never one big push at the
  end. GitHub's copy starts from a snapshot of 2026-10-16 (branch `github-snapshot` -> GitHub `main`).
- **Claude drives; Codex helps (Alan, 2026-10-07).** Claude talks to Alan, tests in Studio, judges feel and fits
  pieces together. It hands well-defined, testable jobs to Codex through the Codex plugin (codex-rescue agent /
  `/codex:rescue`, `task --write`) and checks every Codex change
  (diff, tests, Studio) before committing. Codex works on files Claude is not editing. Good Codex jobs: pure logic
  with unit tests (routing, balance numbers, team rules), Blender scripts, second opinions on risky code (saving,
  purchases). Codex's standing lane: Track C saving. No other role-play teams or review chains.
- **Model router (Alan, 2026-10-08).** Give each job to the cheapest model that can do it, where a failure is
  easy to spot. Delegate only jobs whose instructions are complete; anything needing judgment stays with Opus.

  | Model | Gets | Never gets |
  |---|---|---|
  | **Opus 5.5** (main session) | Talking to Alan, product and design calls, feel and visual checks in Studio, debugging across systems, fitting pieces together, reviewing every delegated change, commits | — |
  | **Sonnet 5.5** (`luau-builder-sonnet`, `Explore`) | One fully specified edit in named files; code searches; drafting docs from facts given to it | Design choices, Studio feel checks, commits |
  | **Haiku**, newest (`match-runner-haiku`) | Mechanical runs with exact steps: timed bot matches and their numbers, the test suite, place rebuilds | Writing code, judging results |
  | **Codex GPT-6.1 Sol** (the only Codex model, fast mode on; Alan 2026-10-12) | Pure logic with unit tests, balance math, Blender scripts, pictures, second opinions, Track C saving. Runs on Alan's ChatGPT plan, not Claude usage | Studio feel, files Claude is editing |

  Step up one level after one clear failure on a complete spec (Haiku → Sonnet → Opus); never retry the same job
  on the same model. Codex is Sol only (never pass `--model`): after a clear Sol failure, fix the spec and retry
  once, or Opus does it. One writer per file at a time. Every delegated change gets the diff read, the tests
  re-run and, for gameplay, a Studio check by Opus before it is committed. Sol sometimes misreports its own work,
  so never trust a summary over the diff.

## How to check work
- Rules logic (damage, economy, rewards, loadout legality) gets normal unit tests in `tests/`.
- Gameplay gets checked by playing it in Studio (Roblox Studio MCP: start Play, look, measure FPS, stop).
- **Look at the game.** Every change to feel or visuals is checked in real Play at 1280×720 or larger, with
  screenshots of the fixed viewpoints compared against the reference image and the previous set. A 1×1 or
  missing viewport is not a check. Tests passing does not mean the game is good.
- Performance target: steady 60 FPS on Alan's PC in a 12-plane match, no buildings popping in.
- At the end of each milestone, put a short "what to try" list in STATE.md under "Waiting on Alan" and keep
  going. His playtest is the final sign-off. Never claim something is fun or balanced without him.

## Updating STATE.md
Rewrite it (don't append) after each milestone or big change. Keep it under 60 lines, plain English:
current milestone, what works, what's broken, next step, anything waiting on Alan.

## Working without supervision (overnight and whenever Alan is away)
Alan wants you to keep building without him. Treat that as standing permission:
- **Don't end your turn to ask questions or report progress.** Keep working on the current stage(s) until
  their quality bar is met. Put updates in STATE.md, not in chat.
- **Depth over breadth.** Never start a stage that sits behind a ★ gate Alan hasn't approved. When a stage
  is waiting on him, go deeper on it (polish, tuning, more content, more testing) or work on another track
  that isn't gated. Do not sketch future stages.
- **Make reasonable decisions yourself.** If the vision doesn't settle something, pick the option that best
  fits VISION, do it, and add one line under "Decisions to review" in STATE.md so Alan can reverse it.
- **Playtests:** add a short "what to try" list under "Waiting on Alan". A gated stage is not done until he
  approves it; never mark it done yourself.
- **When something fails, work around it.** Read the actual error, fix the cause, and if that doesn't
  work try a different approach (another API, another tool, a simpler design). After three genuinely
  different attempts, write a short "Stuck on" note in STATE.md, leave things in a working state, and move to
  other work that doesn't depend on it (art, tests, UI, another system, the next milestone's independent parts).
  Come back to it later with fresh eyes.
- **Common workarounds:** Studio crashed or froze → reopen `D:\FlyFightPaper\FlyFightPaper-WORKING.rbxlx` and
  reconnect Rojo. Studio MCP not responding → restart Studio. A dialog is blocking Studio → close or answer it
  only if truly necessary, and say why first (Alan 2026-10-13: no desktop control unless necessary or he asks). Open Cloud upload fails → check the error, retry later,
  or import through Studio's 3D importer. Meshy fails or credits hit the floor → use Blender or Creator Store.
- **Free official dev tools are OK to install** when needed (Blender add-ons, Python packages, Roblox CLI tools
  from official sources). Note them in STATE.md. Nothing paid, and no Windows/system setting changes.
- **Never fake progress.** If something doesn't work, say so in STATE.md. Don't weaken tests or delete a
  requirement to make a check pass.
- **Keep work safe.** Commit after every working step. Save the place (Ctrl+S) at least every hour and before
  risky changes. Never rewrite git history, force-push, or delete the archive folder.
- **Morning summary:** at the top of STATE.md keep a short "Since Alan last checked" list: what got done,
  what's broken, what needs him.

## When to ask Alan
Only for things only he can do (logins, account settings, spending decisions) or product choices that would be
expensive to undo. Leave the question in STATE.md under "Waiting on Alan" and keep working on something else.

## Hard limits (never)
- Buy anything, buy credits (Codex or Meshy), enable auto-reload, use real Robux, or buy paid assets.
  Using Alan's existing Meshy credits is allowed (see M4 rules: stop at 300 credits left).
- Publish the game publicly or change account settings.
- Show, log or commit the keys in `.env`. Use `ROBLOX_API` only with official Roblox endpoints and
  `MESHY_API` only with Meshy's official API.
- Run scripts from free models without reading them first.
- Add runtime AI/LLM calls to the game.
