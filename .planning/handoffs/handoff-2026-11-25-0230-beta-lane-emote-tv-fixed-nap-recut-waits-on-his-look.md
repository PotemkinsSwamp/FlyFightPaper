# HANDOFF — 2026-11-25 — The emote TV's faults are fixed in code; Nap is re-cut as a real sit (Studio drafts) and waits on Alan's look

**Labels:** kind=product+ui · lane=beta · branch=main · issues=none · areas=src/client/WinnersCutscene.luau, src/client/EmoteShop.luau, src/client/Audio.luau, src/client/emotes/SneakyToss.luau, tools/emote_clips.lua, assets/animations/emotes, docs/plan/EMOTE-SHOP-PLAN.md, docs/playtests, docs/decisions, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-25 02:30 -05:00

★ START HERE: Goal: every emote on the Emotes page's TV plays whole and right on Alan's own avatar, and what plays inside the TV looks as good as the page. Opening action: Alan's look in his own Play at Nap re-cut as a real sit (bottom on the books, legs crossed in front), plus the night's other fixes (list in `state/STATE.md`, "Emotes, after the night's fixes"). Done when he says Nap sits right; then upload the two Nap clips (free; his "yes" covered the re-cut and upload, but confirm after his look) and point the config at them.

> Read on demand: AGENTS.md → this file. His words: `docs/playtests/2026-11-25-emotes-page-with-its-painting.md` (notes 1-9, each with what was done). The TV: `Cutscene.tv` at the end of `src/client/WinnersCutscene.luau`. The pose tool: `tools/emote_clips.lua` (`crossed`, `CUTS.NapSleep`, `CUTS.NapWake`) and `docs/workshop/emote-making.md` (bake commands). Memories: look-before-explaining, alan-does-play-checks, studio-not-drawing, edit-tests-have-plugin-rights, scripts-through-the-write-tool.

## STATE (verify before acting)
- HEAD: the commit adding this file on `main`; before it `8a2c06f06`. The commit hook pushes. Confirm `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty).
- Tests: suite not run (needs Play). Docs: `python tools/check_docs.py` OK (259 pages).
- Studio "FlyFightPaper(First Fold)" in Edit; **place NOT saved**. In its `Assets`: drafts `NapSleepClip` and `NapWakeClip` (Studio plays a draft over the upload). If the place is closed without a save, re-bake: `python tools/emote_preview.py STUDIO_ID x --lua=emote_clips.lua "--bake=NapSleep:NapSleepClip:assets/animations/emotes/nap-sleep.rbxm"` and the same for `NapWake` / `nap-wake.rbxm` (set `_G.EMOTE_CLIPS = { "cut:NapSleep" }` first). My temp folders are deleted; camera put back (Fixed, 70).
- Every change this session compiles in Edit (`loadstring` on the synced source). Only Alan's TV-sound pick was checked by him in Play. Cards and Nap seen only in Edit pictures (cards on his avatar; Nap on the test kid).
- Cost: no agents; no uploads; no Play run of mine (only read-only reads of his running Play); a background mouse nudge for 30 minutes. Model moved from Fable to Opus mid-session (his `/model`). Context ~40% at handoff.

## NEXT ACTION + PLAN
1. **His look** (Nap, cards, Bubblegum, sound cut-off, Sneaky Toss, Test Flight nose first). Done when he OKs Nap; then upload both Nap clips, ids into `rounds.emote_clips` in `config/gameplay.json`, delete the drafts.
2. **The other sitting emotes on his avatar** (So Close, Test Flight, Next One, Doodler): look from the side in Edit first (his avatar, ray map of the real bottom); re-cut any that tuck the feet under, the same way. His "yes" covers this.
3. If one body still floats after the re-cut: a per-body leg bend in the game (ankle to the bottom's height, two-bone like `bendArm`, from `PreSimulation`), checked in Play.
4. Note 8, the TV's own picture (plan OK'd; trial set not good enough to show): show him the picture first.
5. The emote's own sounds quieter in the page; card props.
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), generator calls other than Codex pictures (price first), any Play run of mine, bot matches, any new mechanic or number.

## DECISIONS & WHY (this session)
- **Alan's:** TV sound 3, one sound however fast you click; cards face you (not Sore Loser) and all the same size; a sitting kid sits on the bottom; "yes" to re-cut Nap, then the others. All in `docs/decisions/2026-11-24-emote-shop.md`.
- **Why Nap floated:** the old pose tucks the feet under the body on every body; on his costume the bottom is 0.45 studs below the shoes, so either the bottom or the shoes rested. Rules for `sit` could not fix it; the pose had to change. `sit` counts the bottom again (`SEAT` with LowerTorso).
- **Why Test Flight flew backwards:** the plane `EmoteShop` builds for the TV had its front half a circle round (`WorldPivot` from a piece); set to identity. The winners' moment uses the real plane and was never wrong.
- **Why Sneaky Toss hung:** `aim` needed 1st's model, absent on the TV; it now aims at where 1st's head would be.
- **Why emotes were cut short:** the winners' moment runs an emote `GLIDE` (2 s) past `leaveAt`; the TV now does too.
- **Mine, his to reverse:** a tap within 0.5 s of the last is ignored (`TAP_GAP`); `CROSS` numbers in `tools/emote_clips.lua`; the TV's sounds play at 0.6 / static 0.2 (not heard by me).
- **Tried and dropped:** a side camera on cards (he wants them facing); legs-only `sit` (sank his bottom); bending the hip 40° in code.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories above; `docs/workshop/lessons.md` "Emotes on real bodies" (three new lines this session).

## CARRY NOTES / GOTCHAS
- In Edit, a changed `Transform` does not move a body with AnimationConstraints; Edit pictures of code bends lie.
- `screen_capture` often times out or returns the last view on the first call after the camera moves: call it again.
- Studio was minimised early on (black pictures): check `IsIconic` first; bringing it up is his.
- Nap's card uses `NapWake` at 60% (a draft now); after the upload it reads the uploaded clip by the same name.
- On the test kid the re-cut's thighs sit 0.07 heights under the hips' bottom: on bodies with a thin bottom, the thighs carry the kid. Fine by the numbers; his eyes decide.
- `.planning/emote-shop/` is still untracked (pictures and scripts from the painting work).

## WHAT SHIPPED / OTHER QUEUED
- `717201b9a` emotes run to their end; old sound stops · `f0edd555e` Sneaky Toss ball, planes nose first
- `7d39aeeb9` three TV sounds on a Studio button · `a216eaaec` legs-only seat; side cards (both later reversed)
- `840789dea` his sound pick; button gone; double click counts once · `9faac8ecf` cards face you again
- `f09b2e39c` cards framed on the posed body; Nap and So Close moments · `8a2c06f06` Nap re-cut (drafts); bottom counts again
- plus the commit with this file.
- Queued: Airspace Control's zones; class reaction; his looks at the four new runner-up emotes from their uploads and at the bots' cast; backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/playtests/2026-11-25-emotes-page-with-its-painting.md`: notes 2-8 done or worked, new note 9 (cards).
- `docs/decisions/2026-11-24-emote-shop.md`: his four rulings of this night.
- `docs/plan/EMOTE-SHOP-PLAN.md`: "As built" (cards, TV sounds), build order 4-6.
- `docs/workshop/lessons.md`: look at a sit from the side on his avatar (ray map); Edit Transform trap; posed box trap.
- `state/STATE.md`: the Emotes line and "what to try"; trimmed to 59 lines. Checker: OK (259 pages).

## POINTERS
- The TV: `TV.play`, `TV.frame`, `TV.stop`, `TV.POSE` in `src/client/WinnersCutscene.luau`; `sit` and `SEAT` near `rig`.
- The page: `pose` (card framing) and `play` / `switchOff` / `select` in `src/client/EmoteShop.luau`.
- Sounds: `tvOn`, `tvOff`, `tvStatic`, `Audio.hush` in `src/client/Audio.luau`.
