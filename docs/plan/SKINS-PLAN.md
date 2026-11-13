# Skins and trails plan

**Status:** draft for Alan's OK (2026-11-13). Alan picked skins and trails as the next build at the goals review. Built
to his rules in the [shop plan decision](../decisions/2026-10-18-shop-plan.md) (whole-plane skins, teams readable,
Paper or Robux, kept through prestige); serves [the beta has to feel finished](../decisions/2026-11-06-beta-feels-finished.md).

## What the player sees
- **A skin is a whole plane with its own look:** its own shape details and paint, made as one model. Your parts still
  decide the stats; the skin draws over body, nose, wings and tail and stretches to your build's real size, so what
  people see is what they can hit. Weapons and boosters stay where they are, on top.
- **Teams stay readable:** a skinned plane gets a thin outline in its team colour (Roblox's own `Highlight`, hidden
  behind walls so it gives nobody x-ray eyes).
- **A trail is a short ribbon from your wingtips while you fly** (crayon scribble, rainbow marker, confetti, pencil
  shavings). It hides while you boost, so the boost streak still shows who is boosting.
- **Everyone sees them:** in matches, on the desk, in the Hangar and in the winners' moment.
- **Picking:** a Looks tab in the Customize binder, with try-on like parts. **Getting them:** a Looks section in the
  shop; once you own every part, Today's parts shows looks instead (Alan 2026-11-12).
- **Bots wear them too** (about 1 bot in 3), so a new player sees them in the first match.

## First batch (ideas; concept pictures first, Alan picks)
- **4 skins,** e.g. a shark jet with a crayon mouth, a dragon with scalloped wings, a newspaper glider, a gold foil
  star fighter (the special one).
- **4 trails:** crayon scribble, pencil shavings, rainbow marker, confetti.

## Prices (numbers for Alan's OK)
Every look has a Robux price and a Paper price, linked by the big pack's rate (about 18.75 Paper a Robux, the same
rate as parts in the [shop prices plan](SHOP-PRICES-PLAN.md)). An average match pays about 660 Paper.

| Look | Robux | or Paper | About |
|---|---|---|---|
| Trail | 99 R$ | 1,850 | 3 matches |
| Skin | 249 R$ | 4,650 | 7 matches |
| Special skin (gold foil) | 499 R$ | 9,350 | 14 matches |

## How it's built
- **Models:** Creator Store first, then Codex Blender, Meshy last (house rule). Each skin is one mesh and one picture,
  so 2 uploads a skin. Every picture goes on a contact sheet before upload ([lessons](../workshop/lessons.md):
  "Uploads and Roblox moderation").
- **Stretching:** the skin model is sized to the built plane's length, span and height; the part pieces hide under it.
- **Trails:** Roblox's own `Trail` between two wingtip points, one picture each, like the boost streak.
- **Save and buying:** owned looks and the chosen skin and trail in the save; Paper buys use the parts' server check;
  Robux buys go through the receipt code already built (switched off until go-live).

## Steps
1. Alan's OK on this note.
2. Concept pictures for skins and trails (Codex); Alan picks.
3. Models for the picked skins; a preview of each on a plane in the scene, close up, for Alan's OK.
4. Alan's go: upload (about 12 pictures and meshes, free).
5. Build: save and buying rules with unit tests (Codex), Looks tab, shop section, trails, outlines, bots wearing them.
6. Studio check, then Alan plays it.

## Cost
Codex for concepts, Blender models and the save rules (Alan's ChatGPT plan, not Claude usage); Opus for the rest.
Meshy only if Blender can't (credits, stop at 300). One upload batch with Alan's go. No bot matches. About 3-4 sessions.

## Leans for Alan to confirm
- One skin and one trail for all your planes, not one per loadout.
- Team outline on skinned planes only.
- About 1 bot in 3 wears a look.

Back to [HOME](../HOME.md)
