# 2026-11-12: Double this match, the fold card's buttons, the shop's green

## What Alan did
Played Studio matches after Double this match was built (team dogfight among them), got folded by parts, opened the shop.

## What he saw
- **Double this match:** "Looks better. It works." In one team match it didn't show: he earned 36 Paper and it shows
  from 75 (as decided). He asked how a purchase could reach another server: only if the player leaves before the save
  confirms; he wanted the locked amounts in the save so it is exact anywhere (built the same session).
- **Fold card, Thumbtack Shooter:** offered for 49 R$ at "0 Paper" though he had it (free gear comes with its level and
  isn't written to the save; the card only checked the save). Fixed: free gear never gets the card. Live, no Robux
  product exists for free gear, so nobody could have paid.
- **Fold card, red X:** with the level and the Paper there is nothing to wait for, so the "Wait for" button became a red
  X. He wanted a red "Not now" there instead. Done.
- **Shop:** doesn't like the faded chalk green behind the pictures ("doesn't look right"); sent to the design-theory
  session for reasons and alternatives. The two 2x Forever pass cards: no circle (soft shadow instead), circles only on
  white cards. Done.
- **Balance:** the big planes are still too strong: [3 mounts on the big bodies](../decisions/2026-11-12-big-bodies-three-mounts.md).

## Second look (after mint green, shadows, 3-mount bodies)
- **Models aren't centred in their circles** (Today's parts: Long Point and Spool Booster poke out to the left; his
  pictures `.planning/shop-off-centre-models-alan-2026-11-12.webp`). The models turn around a point that isn't their
  true middle: centre each model on its bounding-box middle. This is the "a part revolves around a tip" note from the
  last handoff.
- **Starter pack items** (and any card of that design): no cream square and no mint circle; the models float free with a
  soft shadow under them, and the words sit on a small darker plate so they read, like the in-game version (picture
  `.planning/starter-pack-items-alan-2026-11-12.webp`).
- **Dev toggle he needs:** a button always on screen (bottom right, not at the desk), only for him and only in Studio,
  switching between his real profile (level 12, free gear unlocked at its level) and everything unlocked, so he can
  look at the big bodies in the Hangar. It must never exist outside Studio.
- Not commented on yet: the mint green itself, the big bodies in the Hangar (couldn't, locked), the fold card fixes.

## What changed
Commits 61ea43a7 (exact saved lock), 1c9b7a9b (fold card), 1b4b8166 (pass cards), and the big-bodies change.
Second look, built the next session: the dev switch (bottom right, Studio only), part pictures centred as seen (the near
end looked bigger; `.planning/shop-centred-models-before-after.jpg`), starter pack items floating on a shadow with dark
word plates (`.planning/starter-pack-floating-before-after.jpg`).

Back to [playtests](README.md)
