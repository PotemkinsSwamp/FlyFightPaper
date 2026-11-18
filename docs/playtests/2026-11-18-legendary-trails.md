# Five Legendary trails in a Studio match, 2026-11-18

## What was run

In muted Studio Play, the trail selector put each approved trail on all 12 planes. Screenshots show the player's chase view and the view from alongside at a 2046 by 801 viewport. The test used the installed plane bodies. The four new skin models besides Ninja have a separate release.

## What it showed

- [Ninja's Smoke Bomb](../../.planning/skins/trails/legendary-review/studio/smoke_bomb.png) emitted spinning metal stars and dark smoke.
- [Hot Rod's Backfire](../../.planning/skins/trails/legendary-review/studio/backfire.png) showed a bright core and separate forked orange flames.
- [Race Car's Photo Finish](../../.planning/skins/trails/legendary-review/studio/photo_finish.png) left tread scraps in tire smoke and enabled individual spark streaks in short bursts.
- [Shark Jet's Water Spray](../../.planning/skins/trails/legendary-review/studio/water_spray.png) showed teal crests and foam. Both halves of the jaw appeared in flight.
- [Stealth's Cloaking Wake](../../.planning/skins/trails/legendary-review/studio/silver_chaff.png) bent the desk legs behind the plane. The client drew one glass mesh per wake with 13 moving bones and violet highlights. Roblox supports glass refraction on desktop. Mobile devices render glass without refraction. [Roblox materials](https://create.roblox.com/docs/parts/materials).

All 676 tests passed in Studio Play, including the ownership and equip checks. The flight check covered 12 planes in the match, generally 10 or 11 airborne at once. The original all-Shark run averaged 46.9 FPS. After the renderer skipped subpixel droplets on distant planes and reduced updates to distant crests, two ten-second measurements from the same fixed camera each averaged 59.9 FPS. The local plane keeps the full effect.

With the fixed camera and warmed assets, Smoke Bomb averaged 59.6 FPS and Cloaking Wake 59.8. The final two runs for Backfire averaged 58.6 and 59.3 FPS. Photo Finish averaged 58.8 and 59.7. The same match with trails switched off averaged 60.0 at the start and 58.9 at the end. These are desktop measurements. The final place was saved to Roblox Team Create as version 783 and to the local working file.
