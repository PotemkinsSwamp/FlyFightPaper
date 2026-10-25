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

## Step 3 looked at closely (2026-10-25, for Alan's OK): skip it
Streaming only saves time for what it leaves out, and this game can leave out almost nothing:
- **The whole town is in view.** From the air you see the room end to end, so "no pop-in" means a streaming radius
  covering the whole room: the phone would download the same files, just in a different order.
- **The plane checks its own crashes on the phone** (`FlightRules.contact`, the same check the server runs). A building
  not yet on the phone is air to the pilot but a wall to the server: invisible crashes. So every solid piece would have
  to stay loaded (Persistent), and the solid pieces are the heavy ones (unique building shapes and pictures).
- What could stay out (trees, cars, lamps) is already cheap: a few shapes and pictures used hundreds of times.
- Turning it on also needs fixes in ~10 places (the loading screen would hang counting town pieces, the tutorial's guide
  line would route through unloaded buildings, the train and winners' desks would freeze or vanish, no character so
  nothing tells Roblox where the player is).
The loading screen already lets players in after the menus (step 1, Skip), which is the one real gain streaming would
bring. **Proposal:** leave streaming off; after step 2, read the phone's times; if pictures are still the wait, step 4
(fewer, bigger files) is the change that actually shrinks the download.

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
