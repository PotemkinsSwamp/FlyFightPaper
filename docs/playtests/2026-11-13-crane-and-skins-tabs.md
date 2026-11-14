# 2026-11-13: Origami Crane in the game, Skins and Trails tabs, booster skins

## What Alan did
Played in Studio after the crane went in (commit a1779992): the new Skins and Trails tabs in Customize, the Origami
Crane on his own plane, Hazard Stripes on a plane with a booster, deaths with a skin on, and the build shelf.

## What he saw
- **The tabs click unreliably** ("clicks on and off"). After his playtest Claude is to click through them in Studio and
  watch (his go for that Play and its screen grabs).
- **The booster didn't take the crane** (it did take Hazard Stripes). Boosters must wear a Mythical too.
- **"Try on" confuses:** for a skin you don't own, the button should say **Buy**, not "Try on".
- **No little cardboard tabs as buttons** (the Cancel button's art, his screenshot): "use paper and tape". Said before.
- **Deaths:** torn apart carries the skin (good); **crumpled into a ball** (hitting a wall) **doesn't** and must.
- **The crane's guns don't touch the crane:** they hang where the skin isn't.
- **Wing hitbox for the crane:** the raised V wings over flat real wings make it hard to fly ("you'll hit things and not
  realize ... because you don't know where the actual wing is"). He asked whether the crane's wings can tilt up so
  the hitbox matches the V: same size, only a different angle, so no advantage. An exception for the crane.
- **Build shelf:** the big photo shows a mix of the skin and the real parts, and the loadout cards don't show the skin.

## What changed
Next session (2026-11-13, late), checked by clicking through in Studio Play:
- **Tabs:** the page beside the cards let clicks through to the tab tucked under it, so a click there flipped tabs.
  The page now takes those clicks (8 of 8 tab clicks land, 4 of 4 page-edge clicks do nothing). Lesson in
  [lessons](../workshop/lessons.md).
- **Buy, not Try on:** a skin you don't own shows Buy or Unlock now; the "Dev: skin" button lists the crane too.
- **Paper and tape:** Cancel, Take off and No booster use the red taped paper (Clear all's), never the cardboard tab.
- **Crumpled ball wears the skin:** its pieces are the skin's printed pieces squashed into the ball.
- **Crane guns:** each gun's whole length hangs under the wing (the front half stuck out ahead of it).
- **Build shelf:** the big photo and the five cubbies wear your skin.
- **Booster under the crane:** needs the crane's printed sheet (next step; its upload is Alan's go).
The wing-hitbox tilt: Alan's ruling is in the [skin rules](../decisions/2026-11-13-skin-rules.md); how-it-works note next.

## Replay (2026-11-14)
Alan replayed the fixes. Good: the crumpled ball wears the skin ("it actually looks good"). Still wrong:
- **The crane's body is a little wide** and **the wings don't fully join the body** (his top-view screenshot).
- **The booster still wore team paper:** the crane's printed sheet wasn't uploaded yet (waiting on his go).
- **The hangar feels rigid:** every click visibly reloaded the whole screen; after Buy, Buy stayed up, then a moment
  later the screen redrew ("like two UIs on top").
- **Toilet Roll still jitters** (only that body).

What changed the same day:
- **Crane body:** Alan meant **tall**, not wide (he corrected it the same night; the narrowing was undone). The belly
  now stops at the real body's bottom (it reached down to the booster) and the roof is lower: about a quarter shorter.
  The wings, neck and tail now join the body's side edge wherever the stretch puts it (they hung at the real wing's
  height, which on most bodies left a gap). **The crane drew grey** after the sheet went in: two look folders of the
  same name hid its own look; `skin_looks.py` now writes one folder per skin.
- **Hangar:** the plane photo now stays put between clicks; a new plane loads behind the old one and swaps in when
  ready (checked in Play: no blank frame). After any buy the server sends the fresh profile at once, instead of the
  next 3-second refresh.
- **Booster under the crane:** with Alan's go the crane's printed sheet was uploaded; boosters under the crane now wear
  its blue paper (checked in Play on a Band booster; tape and elastic keep their own look).
- Alan's answers: build the wing-hitbox tilt with the guns' hit spots moving too; the Toilet Roll shake is the whole
  plane, in a match (next session's job).

Back to [playtests](README.md)
