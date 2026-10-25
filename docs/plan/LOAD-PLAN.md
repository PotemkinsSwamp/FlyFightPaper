# Load plan: fast joins on a phone, same look

Draft for Alan's OK (2026-10-25). Alan published privately and played on his phone: the menus showed their words but
no paper art, and the town took minutes to appear. "I've seen mobile games with more advanced maps and menu UI and
theirs loads no problem." Measured cause: [performance](../systems/performance.md) ("Phones").

## What the player sees
On a phone, first join: the loading screen, then whole paper menus within about 10 seconds; the town drawn and
sharp by the time they reach their desk (about 30 seconds on Wi-Fi); a second join faster (the phone keeps what it
downloaded). Nothing pops in while flying. The town looks exactly as it does today, on PC and phone.

## Why it's slow (numbers)
- The place asks for about 4,500 separate files: ~900 shapes and ~3,500 pictures. Fast mobile games reuse a small
  kit of pieces and shared pictures, so they ask for a few hundred.
- Almost nothing is reused: each building is one big model cut into 16 pieces (Meshy) or 5-43 (Blender), and every
  piece has its own shape and its own 3-4 pictures (colour, bumps, roughness, sometimes metal) at 1024 x 1024.
- About 340 of those building pictures are one flat colour (169 bump, 81 roughness, 59 metal, 32 colour maps).
- 136 of 2,079 town parts have no texture pack, so they fetch 3-4 pictures each instead of one pack.
- Streaming is off: a phone gets the whole town at once, and the menu pictures wait in the same line.

## How it works (four steps, cheapest first)
1. **Load before you get in.** The loading screen downloads the menus' ~176 pictures first, then every shape and
   picture of the town (up to 3 minutes on a slow first join, with a real progress bar), and only then lets you in.
   It prints how long each step took (phone: type /console in chat), a bonus, not a test: what Alan sees counts
   (Alan 2026-10-25).
2. **Same-look trims (no new art).** Flat pictures become one tiny shared picture per value, or none (a flat bump
   map draws the same as no bump map): ~340 fewer downloads. Every part gets its texture pack (after a Ctrl+S, the
   pack harvest `town_toys.py packs`). Checked with side-by-side close-ups before and after.
3. **Streaming on, without pop-in.** Roblox sends what's near you first. Each building and toy arrives whole
   (Atomic); the classroom, desks and the big landmarks are always loaded (Persistent); the radius covers the whole
   town you can see from the air, so it fills in while you're in the menu and at your desk, not while flying. The
   loading screen waits only for the room. Checked on PC and phone for anything popping in.
4. **One picture set per building band, if step 1's numbers still say pictures.** Re-bake each building with its
   pieces sharing bigger sheets (16 x 1024 becomes 4 x 2048: the same pixels, so the same sharpness) and tighter
   packing (today ~45% of each sheet is padding), and merge pieces where the shape limit allows (20,000 triangles a
   shape): about 4x fewer picture files and fewer shapes. This is the big one: re-bake 46 buildings (Codex, Blender),
   re-upload ~600 files (each checked on a contact sheet first), redo the saved collision (~40 min) and the packs.

## Next three steps (Alan 2026-10-25, after the fresh-join phone test; do them in order, until all are done)
The test: 44.9 s with no paper art (the menu's pictures queue behind the ~1,600 town files sent at join), then
1 min 2 s more for the town ([playtest](../playtests/2026-10-25-phone-fresh-join.md)).
1. **Menus first, for real.** StreamingEnabled on. The town (and other heavy room pieces) is
   `ModelStreamingMode.PersistentPerPlayer`: a player gets it only after the server adds them
   (`Model:AddPersistentPlayer`), which the server does once that player's menu pictures are in; then it stays on
   their phone (no streaming out, so the phone's crash checks always see every wall). Play waits for the town if it
   isn't there yet ("Unfolding the town..."). The Explore audit's spots get fixed: the loading count in
   `NativeAssets.ready` (would hang), `Tutorial.airRoutes` cache, `TrainMotion` and `ChalkCloud` cached parts, winner
   desks, `SpeedPickups`, Planes models. Check: Studio Play (Device Simulator phone), then Alan's fresh join: menus in
   seconds.
2. **Load recorder.** Each join saves its times (room, menu pictures, town, done) and device kind to a DataStore;
   read in Studio. Check: Alan's next join appears with its numbers.
3. **Repack the town's picture sheets** (was step 4): each building's pieces share tighter-packed sheets (today ~45%
   of each sheet is padding), same pixels per stud so the same sharpness; colour, bump and shine. Re-bake 46 buildings
   (Codex, Blender), contact sheets, upload (Alan's go: "until all steps are done"), redo saved collision and packs.
   Check: close-ups before/after (same look), fewer and smaller files, Alan's fresh join under a minute.
Streaming first looked like no gain (the whole town must be on the phone); it is kept for one thing: the order.

## Build order after Alan's OK
Step 1 now (code only; Alan's go 2026-10-25). Step 2 next (no uploads except the tiny shared pictures). Step 3 after Alan OKs the pop-in
test plan. Step 4 only if Alan's phone numbers after steps 1-3 still show pictures as the wait; its own short plan
first.

## Checks
- Alan's phone: the /console load times after each step (first join and second join), and whether menus show whole.
- Studio: same viewpoints before and after (close-ups of 3 buildings), FPS, nothing missing; `GraphicsTexture` memory.
- Done when a first join on Alan's phone shows whole menus within ~10 s and the town drawn by desk time.

## Alan's answers
2026-10-25: load before you get in, but only the menu has to wait (then Skip); target under a minute for everything,
seconds ideally. Smaller building pictures OK where no difference shows, with before/after close-ups first.
Close-ups shown (3 buildings, bump/shine maps at half size): Alan said go, whole town
([decision](../decisions/2026-10-25-fast-phone-loading.md)).

## Progress
- 2026-10-25: step 1 built: a ReplicatedFirst script asks for the loading screen's art and font, then the menus',
  before the game arrives; the loading screen waits for the menus' pictures and the town (batches of 40, the bar is
  the true share finished, 3 minutes at most) and always lets the player in. Studio: 6.4 s to get in, 425 / 0 tests.
  The first build Alan published read SurfaceAppearance maps (not allowed) and stuck on the loading screen.
- 2026-10-25: Alan's phone (some files already on it): about 2 minutes; ~1 minute at 5% (the menu pictures), then
  75%, then the big building pictures. Alan: wait only for the menu, then Skip and the rest loads later; but
  everything should load in under a minute, seconds ideally. Built: the main menu's pictures first, then a Skip
  button (the loading carries on behind the menu). Alan OK'd smaller building pictures where no difference shows,
  before/after close-ups first (step 2).

- 2026-10-25 (load step 1, menus first): built. Streaming on; room + rug `PersistentPerPlayer`, sent when the
  player's menu pictures are in (30 s fallback); menus start before the town, the rest of the game once its parts are
  in; Play/Fly/Training wait for it. Studio Play: main menu 2.7 s, town parts in 4.0 s, all pictures 14.2 s; no
  errors; joined a match with 12 planes, the town drawn; 425 / 0 tests. Next: Alan publishes, fresh phone join.
- 2026-10-25 (load step 2, load recorder): built. Times now count from the first script on the phone (ReplicatedFirst);
  each join sends them with its device kind and screen size, the server keeps the newest 50 (`LoadLog`). Studio test:
  the join appeared with its numbers. Check left: Alan's published join shows up.
- 2026-10-25 (load step 3, repack): method chosen so the look can't change: each building's UV islands are only
  moved by whole pixels (no scaling, no turning) onto shared sheets, so every pixel copies byte for byte (Codex script
  `tools/art/repack.py`, checked by sampling old vs new). Open question: does Roblox keep a 2048 picture at 2048? Its
  docs say both "up to 4096" and "1024 x 1024"; a 2048 stripe test (id 112459253586917) reads back as 1024, but
  EditableImage itself stops at 1024, so a close-up in a drawing Studio decides. If 2048 shrinks, sheets stay 1024
  (fewer gains: tighter packing only).
  Pilot: the clock tower's 16 pieces on 4 shared 2048 sheets, uploaded (all approved; records in
  `clock-tower/repacked/`, not yet in the game). Tighter packing gave no pixel savings (the old packing was already
  as tight as the 4 px padding allows), so the gain is files. All 45 buildings planned (`*/repacked/repack.json`, every
  check PASS): picture files 1,893 -> 732, pixels 4.8% fewer (each building's last sheet sized to fit; 111 pieces keep
  their own maps where sharing would add pixels or a piece is too big). Left out on purpose: bell tower and sweet shop
  (moderation caution, as with the smaller maps). Contact sheets of all 107 new colour sheets looked at: nothing
  symbol-like (big black areas are hidden undersides, already approved before). Next: close-up of old vs repacked
  clock tower in a drawing Studio (script ready); if the same, upload the rest (~800 files), read MeshIds, swap in
  the Studio copy after Alan's step-1 test, redo exact collision and packs.

## Cost
Steps 1-3: $0 (code, place settings, a few tiny uploads). Step 4: Codex on Alan's ChatGPT plan, free uploads, about
3-4 sessions; the upload risk is managed by the contact-sheet check. Each phone test needs Alan to republish.
- 2026-10-25 later: step 2's pictures done. Every town bump/shine map (normal, roughness, metalness) re-uploaded at half
  size (1,154 files) and flat ones share 33 tiny pictures (`assets/models/flat-maps.json`); colour maps untouched. The
  bell tower and the sweet shop's swirl roof kept theirs (moderation caution). The town's picture pixels: 2,749M ->
  1,488M (46% less); separate town pictures 2,263 -> 1,963. Every piece now has a texture pack (the 136 that had none
  too). Studio check: old and new pictures drawn the same way differ by 0.5/255. But the old saved packs on a few
  buildings were stale (they still drew the materials from before the 2026-10-10 "stronger materials" pass), so the
  fresh packs show the cereal-box tower grainier and darker, the notebook and clock towers paler, the ceiling moon
  darker: `.planning/load-maps-town-before-after.jpg`, for Alan. Uploads: Approved 1,186, Rejected 1 (a plain grey
  map; those 4 ring-binder pieces keep their old one).
