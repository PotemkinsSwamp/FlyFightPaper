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
1. **Menus first, and measure.** The loading screen downloads the menus' ~176 pictures before anything else, then
   prints how long each step took (phone: type /console in chat). Alan republishes and reads the numbers: they say
   whether the wait is the world arriving, the pictures, or the shapes.
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

## Build order after Alan's OK
Step 1 now (code only). Step 2 next (no uploads except the tiny shared pictures). Step 3 after Alan OKs the pop-in
test plan. Step 4 only if Alan's phone numbers after steps 1-3 still show pictures as the wait; its own short plan
first.

## Checks
- Alan's phone: the /console load times after each step (first join and second join), and whether menus show whole.
- Studio: same viewpoints before and after (close-ups of 3 buildings), FPS, nothing missing; `GraphicsTexture` memory.
- Done when a first join on Alan's phone shows whole menus within ~10 s and the town drawn by desk time.

## Alan's answers
(waiting)

## Progress
- 2026-10-25: step 1 written (menu pictures first, load times printed); not yet run (Studio had no place open).

## Cost
Steps 1-3: $0 (code, place settings, a few tiny uploads). Step 4: Codex on Alan's ChatGPT plan, free uploads, about
3-4 sessions; the upload risk is managed by the contact-sheet check. Each phone test needs Alan to republish.
