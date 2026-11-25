# HANDOFF — 2026-11-25 — The Emotes page runs (your own kid on a box TV, buy, Use); prices set; 3D jackets come off; next the page's classroom pictures

**Labels:** kind=product+ui · lane=beta · branch=main · issues=none · areas=src/client/EmoteShop.luau, src/client/WinnersCutscene.luau, src/client/MenuBoard.luau, src/client/MenuController.luau, src/shared/EmoteRules.luau, src/shared/AvatarLook.luau, src/shared/ProfileSchema.luau, src/server/AvatarService.luau, src/server/HangarService.luau, src/server/ProfileService.luau, config/emotes.json, config/commerce.json, docs/plan/EMOTE-SHOP-PLAN.md, docs/decisions, docs/playtests, docs/workshop/lessons.md, state/STATE.md
**Time:** 2026-11-25 00:30 -05:00

★ START HERE: Goal: the Emotes page looks like a classroom the box TV was rolled into, instead of flat shapes (Alan: "very, very boring"; "dont resue the menu background we need a new background ... a classroom like the reference images i gave you it looks like the tv was rolled in the classroom"; "go for codex"). Opening action: have Codex draw the page's pictures from his four photos (`.planning/emote-shop/tv-cart-reference-*.jpg`) in our paper and crayon look, put them together in the page with the glass cut out exactly in the middle, and show him that assembled picture. Done when he has OK'd it; the upload is a separate go.

> Read on demand: AGENTS.md → this file. For the pictures: `docs/plan/EMOTE-SHOP-PLAN.md` ("How the TV picture is made", "As built", "Build order"), the top of `src/client/EmoteShop.luau` (the sheet's numbers), the `design-theory` skill. Memories: assembled-preview-before-upload, visual-qa-before-showing, look-at-textures-before-upload, hand-made-not-generic-roblox, tacks-and-tape-fixed-size, paper-fits-its-content, text-fits-its-box, codex-for-pictures-and-blender, commit-codex-output-first, codex-steals-studio-link, prices-need-other-games-first.

## STATE (verify before acting)
- HEAD: the commit that adds this file, on `main`; before it `fa82817f2`. The commit hook pushes to GitHub by itself. Confirm: `git rev-parse --short HEAD`, `git status --short | grep -v '^??'` (empty at handoff).
- Tests: the suite was not run (it needs Play). New and changed specs, none run in Studio: `Emotes`, `AvatarLook`, and Codex's additions to `HangarService`, `ProfileService`, `ProfileSchema`, `ShopSave`, `MockShop`, `Commerce`, `CommerceService`. Codex says 34 selected tests passed outside Studio with made-up services: its claim, not checked. Docs: `python tools/check_docs.py` OK (258 pages).
- Studio: "FlyFightPaper(First Fold)" in Edit at 00:28; Alan goes in and out of his own Play. Rojo serving. **Place not saved.** Nothing of mine left in the place. No Dev attribute set by me.
- At 00:28 every changed script compiles in Edit (`loadstring` on the synced source: WinnersCutscene, EmoteShop, MenuBoard, MenuController, ShopScreen, AvatarService, AvatarLook, EmoteRules, Emotes) and `AvatarLook.trim` kept Hair and Hat and dropped the Jacket on a made-up list. No Play run of mine.
- **Seen by Alan:** the first build of the page (`dc74aebb3`): it opened, the TV played emotes. **Not seen by anyone:** the door on the main menu, the new TV framing, the prices in the page, buying and Use, a winner doing a bought emote, the real winners' moment after its code was reshuffled, the jacket coming off (he never said).
- Cost: one Codex job (saving and buying rules; his ChatGPT plan; the wrapper agent 42k tokens, 13 minutes). Six web searches. No uploads, no generator calls, no Play runs of mine. Primary's context about 57% at handoff, no compaction.

## NEXT ACTION + PLAN
1. **The page's pictures** (his go for Codex is given; cost: his ChatGPT plan only). What must hold: the glass is a see-through hole 640 x 480 exactly in the middle of the 1920 x 1080 sheet, on any screen; the TV is the main thing and the cart "very subtle"; a late 90s / early 2000s black school box TV. Check: the assembled page on a real screenshot, through the design-theory checklist and an independent reviewer, then Alan's OK. **One thing to ask him with the picture, not before:** whether the two chalkboards the cards hang on are part of the new drawing or the Shop's loaded chalkboard.
2. His OK → the upload (his go) → wired in → his look in Play.
3. His second look at what is built and unseen (list in STATE.md, "Waiting on Alan").
4. Then: the TV's switch-on sound (three licensed candidates on a Dev button), the emote's sounds quieter in the page, the card stills (props, the sixteen moments in `TV.POSE`).
- HOLDS (his explicit go, each): every upload, place saves, publish (he does it), every generator call other than the Codex pictures he already OK'd (price first), any Play run of mine, bot matches, any new mechanic or number.
- Stop rule: the sixteen emotes are approved as they play in the winners' moment. Nothing in them is retuned for the TV unless he raises it.

## DECISIONS & WHY (this session)
- **Alan's, each in `docs/decisions/` or the playtest note:** one menu to buy and equip; your own character on a box TV on a cart; Leader and Runner-up emotes; Paper and Robux buttons; the ranking (camera emotes are the coolest); the prices (Leader 599 / 449 / 299 R$, Runner-up 249 / 149 R$, Paper = Robux x 20) after he turned down two lower and one higher offer; the door on the main menu under Shop and Missions, both made smaller; every avatar's 3D body clothing comes off, everywhere we show the kid, step 1 only; a new classroom background, not the menu's.
- **Mine, his to reverse:** the TV is in the middle of the page (forced: the hole shows the middle of the game's picture) with a board each side and nothing scrolling; the TV is off when the page opens and after each emote; hair and shoes stay on although Roblox files them as 3D clothing; bots lose their 3D clothing too; every player's copy is built on R15; no door in the Customize binder (its tabs are full).
- **Why the TV is a hole and not a menu 3D window:** tested in Edit, a ViewportFrame draws no SurfaceGui and Roblox's page says no blur; four emotes' paper would be blank. Lesson and plan page have it.
- **Five small pieces of `Cutscene.play` were pulled out into shared local functions** (`clockIn`, `leaveAt`, `shaken`, `stepEmote`, `kickSoft`) so the TV runs an emote exactly as the scene does. Read as the same logic; the real winners' moment has not been run since.

## CONSTRAINTS / PRINCIPLES
- AGENTS.md; the memories named above; `docs/workshop/lessons.md`, "A 3D picture inside a menu".

## CARRY NOTES / GOTCHAS
- **The winners' moment needs one real run** after the reshuffle (any "end:" Dev button): it should play as before.
- Alan's notes came from the first build. He has not said whether Book Kicker's book reaches the glass, how A+ and Fold It Up look (their paper is placed by the whole screen's shape and will be cut by the TV's edge), or whether the jacket rule looks right on him.
- The TV takes the camera while an emote plays and gives it back; opened over a running match this is untested.
- The three main-menu strips are 200 x 54 on the 1080 sheet: small on a phone, not checked there.
- A save that holds an emote later removed from `config/emotes.json` fails the schema's check: do not delete an emote id once anyone can own it.
- Schema is now 17 (emotes). The 14 Robux products `emote_<id>` are disabled and unmapped; the page's Robux button shows in Studio only.
- Codex's StudioMCP may have taken the Studio link; it answered at 00:28.
- `.planning/emote-shop/` is untracked (his four photos).

## WHAT SHIPPED / OTHER QUEUED
`git log --oneline e0cc123bf..HEAD`:
- `96e417da3` the how-it-works note, approved · `d561acc11` the TV is a hole in the menu
- `106295728` owning and putting on emotes: saving, Paper buys, practice Robux (Codex)
- `f2b1adb72` the Emotes page, the TV, a winner does the emote they have on
- `dc74aebb3` 3D body clothing comes off every avatar
- `6e4b77e8d` his ranking, the door on the main menu, more headroom on the TV
- `5a05d6fcc` what other games charge · `fa82817f2` the approved prices, his go for the pictures
- plus the commit with this file (lessons, LATEST).
Queued, not started: the page's pictures; Airspace Control's zones (his: "aren't constructed properly"); class reaction; his looks at the four new runner-up emotes from their uploads and at the bots' cast; the backlog in STATE.md.

## KNOWLEDGE UPDATED
- `docs/plan/EMOTE-SHOP-PLAN.md` (new): how it works, the method, as built, prices and other games' prices, build order.
- `docs/decisions/`: the emote shop (new, then his prices, door and background); 3D clothing comes off (new). README lines.
- `docs/playtests/2026-11-25-emotes-page-first-look.md` (new): his seven notes and what was done. README line.
- `docs/systems/economy-and-shop.md` (Emotes paragraph and Code rows, Codex and mine); `docs/systems/saving.md` (the saved fields, Codex); `docs/systems/bots.md` (AvatarLook row); `docs/HOME.md` (plan link).
- `docs/workshop/lessons.md`: "A 3D picture inside a menu" (four lessons). `state/STATE.md`.
- Memory: `prices-need-other-games-first` (new). Checker: OK (258 pages).

## POINTERS
- The page: `src/client/EmoteShop.luau` (sheet numbers at the top: `GLASS_W`, `GLASS_H`, `BEZEL`, `CARD`; the flat pieces to replace are under "The TV on its cart" and "The two boards").
- The TV: `Cutscene.tv` at the end of `src/client/WinnersCutscene.luau` (`TV.TALL`, `TV.MID`, `TV.room` the classroom set behind the kid, `TV.POSE`); who does which emote: `Cutscene.choose`.
- Rules and prices: `src/shared/EmoteRules.luau`, `config/emotes.json` (then `python tools/generate_config.py`); server: `buyEmote`, `wearEmote` in `src/server/HangarService.luau`; attributes `EmotesOwned`, `EmoteLeader`, `EmoteRunnerUp`.
- The slimming: `src/shared/AvatarLook.luau`. The main menu's strips: `src/client/MenuBoard.luau`.
- Art already loaded, by name: `src/first/UIAssets.luau`; how pictures are packed and uploaded: `docs/workshop/` and `tools/ui_sheets.py`.
