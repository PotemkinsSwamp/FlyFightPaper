"""Fill space between a hero piece's texture islands with the nearest island's colour.

  python tools/art/fill_gaps.py PARTS_DIR PREFIX...   e.g. assets/models/bell-tower/parts 1 2 3
  python tools/art/fill_gaps.py PARTS_DIR --uv --all --blender D:/Blender/blender.exe

Why: Roblox's image moderation looks at the flat texture, not the model. Small bent pieces laid flat on black
(the bell tower's leg braces) read as hooked crosses; an upload got the account banned for "discriminatory
content" (2026-10-12). Filling the gaps merges same-coloured islands into plain patches. The model only samples
inside its islands, so it looks the same in game. Normal/roughness/metalness maps get the same fill too.

The original default mode uses "empty" = max channel < 90 on the colour map, dilated by three pixels.
Only use that mode on selected bright pieces: it can erase legitimate dark detail.
--uv instead reads each piece's real loop-triangle UVs from ../hero.blend, rasterises them separately at
each map's resolution, preserves a three-pixel bleed, and fills every other texel. Dark island pixels stay
unchanged. --blend overrides the saved scene; --bleed controls the protected margin. Only external maps
are changed, not geometry, UVs, source images, or the scene's packed copies.
"""
import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


CHANNELS = ("color", "normal", "roughness", "metalness", "metallic")


def color_map(parts, prefix):
    exact = Path(parts) / f"{prefix}-color.png"
    matches = [exact] if exact.is_file() else sorted(Path(parts).glob(f"{prefix}-*-color.png"))
    if len(matches) != 1:
        raise ValueError(f"Expected one colour map for {prefix!r}, found {len(matches)}")
    return matches[0]


def read_uvs(parts, prefixes, blend, blender):
    """Ask Blender for the saved mesh UVs without changing or saving its scene."""
    report = json.loads((Path(parts).parent / "parts.json").read_text(encoding="utf-8"))
    labels = {p["prefix"]: p["label"] for p in report["pieces"]}
    requested = {p: labels[p] for p in prefixes}
    script = """
import bpy, json
requested = REQUESTED
result = {}
for prefix, label in requested.items():
    mesh = bpy.data.objects[label].data
    assert mesh.uv_layers.active, 'Missing UVs: ' + label
    mesh.calc_loop_triangles()
    uv = mesh.uv_layers.active.data
    result[prefix] = [[[float(c) for c in uv[i].uv] for i in t.loops] for t in mesh.loop_triangles]
print('FILL_GAPS_UVS=' + json.dumps(result, separators=(',', ':')), flush=True)
""".replace("REQUESTED", repr(requested))
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
    process = subprocess.run(
        [str(blender), "-b", str(blend), "-t", "1", "--python-exit-code", "1", "--python-expr", script],
        capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, check=True)
    line = next((s for s in process.stdout.splitlines() if s.startswith("FILL_GAPS_UVS=")), None)
    if line is None:
        raise RuntimeError("Blender did not return the UVs")
    return json.loads(line.split("=", 1)[1])


def island_mask(triangles, size, bleed=3):
    """Conservative triangle coverage in PNG coordinates (UV V points upward)."""
    if bleed < 0:
        raise ValueError("Bleed must not be negative")
    uv = np.asarray(triangles, dtype=np.float64)
    if uv.ndim != 3 or uv.shape[1:] != (3, 2) or not len(uv) or not np.isfinite(uv).all():
        raise ValueError("Expected finite UV triangles")
    if (uv < 0).any() or (uv > 1).any():
        raise ValueError("UVs must lie inside the 0-1 atlas")
    width, height = size
    image = Image.new("1", size)
    draw = ImageDraw.Draw(image)
    # Round down to texel cells and include boundary cells. The bleed also protects
    # bilinear samples at island edges; no colour threshold is involved.
    for triangle in uv:
        points = [(min(width - 1, int(u * width)), min(height - 1, int((1 - v) * height)))
                  for u, v in triangle]
        draw.polygon(points, fill=1)
    mask = np.asarray(image, dtype=bool)
    if bleed:
        mask = ndimage.binary_dilation(mask, iterations=bleed)
    if not mask.any():
        raise ValueError("UV mask contains no texels")
    return mask


def fill(parts, prefix, uv_triangles=None, bleed=3):
    color = color_map(parts, prefix)
    stem = color.name[:-len("-color.png")]
    if uv_triangles is None:
        with Image.open(color) as im:
            empty = ndimage.binary_dilation(np.asarray(im.convert("RGB")).max(axis=2) < 90, iterations=3)
    indices = {}
    paths = ([Path(parts) / f"{stem}-{channel}.png" for channel in CHANNELS] if uv_triangles is not None
             else sorted(Path(parts).glob(f"{stem}-*.png")))
    for path in paths:
        if not path.is_file() or path.stem.endswith("-review"):
            continue
        with Image.open(path) as im:
            mode, size = im.mode, im.size
            a = np.asarray(im).copy()
        if size not in indices:
            if uv_triangles is not None:
                mask = ~island_mask(uv_triangles, size, bleed)
            else:
                mask = empty if a.shape[:2] == empty.shape else np.asarray(
                    Image.fromarray(empty).resize(size, Image.Resampling.NEAREST))
            if mask.all():
                raise ValueError(f"No island pixels to fill from: {path.name}")
            iy, ix = ndimage.distance_transform_edt(mask, return_distances=False, return_indices=True)
            indices[size] = (mask, iy, ix)
        mask, iy, ix = indices[size]
        result = a[iy, ix]
        assert np.array_equal(result[~mask], a[~mask]), "Protected island pixels changed"
        try:
            Image.fromarray(result).convert(mode).save(path)
        except OSError:      # Windows: something has the old file mapped, so it can't be overwritten, only moved aside
            os.replace(path, path.with_suffix(".old"))
            Image.fromarray(result).convert(mode).save(path)
            try: os.remove(path.with_suffix(".old"))
            except OSError: pass
        print("filled", path.name, f"{mask.mean():.0%} empty", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("parts", type=Path)
    parser.add_argument("prefixes", nargs="*")
    parser.add_argument("--uv", action="store_true", help="Use actual saved UV islands rather than dark pixels")
    parser.add_argument("--all", action="store_true", help="Process every piece colour map in PARTS_DIR")
    parser.add_argument("--blend", type=Path, help="Saved scene (default: PARTS_DIR/../hero.blend)")
    parser.add_argument("--blender", default=shutil.which("blender"), help="Blender executable for --uv")
    parser.add_argument("--bleed", type=int, default=3, help="Protected UV bleed in pixels (default: 3)")
    args = parser.parse_args()
    if args.bleed < 0:
        parser.error("--bleed must not be negative")
    if args.all and args.prefixes:
        parser.error("Use either --all or explicit prefixes")
    prefixes = ([p.name[:-len("-color.png")] for p in sorted(args.parts.glob("*-color.png"))]
                if args.all else [color_map(args.parts, p).name[:-len("-color.png")] for p in args.prefixes])
    if not prefixes:
        parser.error("No pieces selected; pass prefixes or --all")
    uvs = {}
    if args.uv:
        if not args.blender:
            parser.error("--uv needs --blender or Blender on PATH")
        uvs = read_uvs(args.parts.resolve(), prefixes, (args.blend or args.parts.parent / "hero.blend").resolve(),
                       args.blender)
    for prefix in prefixes:
        fill(args.parts, prefix, uvs[prefix] if args.uv else None, args.bleed)


if __name__ == "__main__":
    main()
