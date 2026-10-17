# How new art gets made

The steps for any new model, prop or menu art, in order. Each step exists because skipping it once cost real time;
the reasons are in [Lessons learned](../workshop/lessons.md).

## 1. Look for a free one
Search Roblox's free Creator Store first. Use a match if it fits the look of the
[reference picture](references.md). Read or delete every script inside a free model before using it.
([decision](../decisions/2026-10-12-creator-store-first.md))

## 2. Picture first
If nothing fits, Codex draws a concept picture (free on Alan's ChatGPT plan; no Meshy credits). Style it on the
approved reference picture only, never on buildings already in the game. Alan OKs the picture. If Alan sends real
photos of the object, use those instead.

## 3. Build it
- **Simple or exact-fitting things** (benches, trees, cars, launchers, kit pieces): Codex builds them in Blender from
  a written spec. Measure sizes from the approved picture and check the sums first.
- **Organic or very detailed things**: Meshy image-to-3D, about 30 credits each. Stop at 300 credits left, never top
  up ([decision](../decisions/2026-10-07-meshy-credit-budget.md)). Log every job in `assets/MESHY_LOG.md`.
- **Thin or moving parts** (wires, railings, blades) always in Blender; Meshy melts them.
- Big jobs go out in batches so pictures and models are made side by side.

## 4. Check it
- Close-up sheet (`tools/art/closeups.py`); fix melted or torn parts through `touchup.json`. A torn window with a
  clean twin on the same round body: copy the twin over it (`copies`: a thin slab of its shape and paint). Cutting
  the torn faces out first left holes after simplifying (paint-jar tower, 2026-10-16).
- Contact sheet of every texture; look for anything that could read as a symbol, hand sign, text or body shape. Run
  `tools/art/fill_gaps.py` on hero pieces. This is what got Alan's account banned twice.

## 5. Upload and place
Upload through Open Cloud (`tools/upload_texture.py`, `tools/town_toys.py`). Remember models arrive turned 180
degrees. Town layouts get a preview picture and Alan's OK before upload
([decision](../decisions/2026-10-09-town-planning-rules.md)).

## 6. Save
Alan presses Ctrl+S in Studio once shapes are computed, then texture packs are harvested and the place rebuilt
(`tools/save_place.py`). Then look at it in Play at 1280x720 or larger.

## Related
- [Model catalog](models.md) · [Building kit](building-kit.md) · [Reference pictures](references.md) · [Tools](../workshop/tools.md)
- [Pictures from Codex, models in Blender](../decisions/2026-10-09-pictures-by-codex-models-in-blender.md)

Back to [HOME](../HOME.md)
