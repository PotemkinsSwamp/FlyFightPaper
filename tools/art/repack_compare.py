"""Render source pieces against repacked atlases, without changing either.

D:/Blender/blender.exe -b --python tools/art/repack_compare.py -- assets/models/notebook-tower
D:/Blender/blender.exe -b --python tools/art/repack_compare.py -- assets/models --all --resume
Requires numpy in Blender and a system Python with numpy, Pillow and scipy
(override with --image-python). Five deterministic, perspective PBR views use
all four maps: front (-Y), back (+Y), left (-X), right (+X), closer oblique.
PNG pairs, annotated contact JPGs, per-view JSON and summary.txt are written
only below .planning/repack-check/ by default. "Old" means today's parts/,
not the previously uploaded/saved Roblox textures. Skipped pieces retain their
original FBX/maps in the new assembly. An empty repacked/ is reported explicitly.

Differences are measured BEFORE JPEG encoding or annotation, in display sRGB
bytes: per pixel = largest absolute RGB channel difference. Max and mean use
all pixels across all five views, including the identical background. A region
is an 8-connected component of pixels above --threshold (12/255 by default).
Only components larger than --min-region (20 pixels) count towards DIFFERENT.
SAME means no such component in these views, not proof of identical mipmaps or
Roblox's texture compression. Red outlines mark qualifying regions in both rows.
--notebook-probe adds matched close views and ray/UV/texel evidence for the bar.
"""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

import numpy as np

CHANNELS = ("color", "normal", "roughness", "metalness")
VIEWS = (("front", (0, -1, .12)), ("back", (0, 1, .12)),
         ("left", (-1, 0, .12)), ("right", (1, 0, .12)),
         ("oblique", (.7, -1, .25)))


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def log(message):
    print("COMPARE " + message, flush=True)


def source_maps(parts, stem):
    maps = {c: parts / f"{stem}-{c}.png" for c in CHANNELS}
    if not maps["color"].is_file():
        variants = sorted(parts.glob(stem + "-color-*.png"))
        require(variants, f"{stem}: missing color map")
        maps["color"] = variants[0]
    for channel in CHANNELS[:3]:
        require(maps[channel].is_file(), f"Missing {maps[channel]}")
    return {c: p for c, p in maps.items() if p.is_file()}


def manifest(folder):
    path = folder / "repacked/repack.json"
    if path.is_file():
        report = json.loads(path.read_text(encoding="utf-8"))
    else:
        require(not list((folder / "repacked").iterdir()),
                f"{folder.name}: nonempty repacked/ has no manifest")
        report = {"sheets": [], "skipped": [], "note": "Empty repacked/; no repacked assets exist. Original assembly retained."}
    by_piece = {}
    for sheet in report["sheets"]:
        for piece in sheet["pieces"]:
            require(piece not in by_piece, f"{piece}: assigned to multiple sheets")
            by_piece[piece] = sheet
    sources = sorted((folder / "parts").glob("*.fbx"),
                     key=lambda p: (int(p.stem.split("-", 1)[0]), p.name))
    require(sources, f"{folder.name}: no source pieces")
    require(set(by_piece) <= {s.stem for s in sources}, "Manifest names unknown pieces")
    if path.is_file():
        retained = {s["piece"] for s in report.get("skipped", [])}
        require({s.stem for s in sources} == set(by_piece) | retained,
                "Every source piece must be packed or explicitly retained")
    return report, by_piece, sources


def clear_scene():
    import bpy
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for collection in (bpy.data.meshes, bpy.data.materials, bpy.data.images,
                       bpy.data.lights, bpy.data.cameras):
        for block in list(collection):
            if not block.users:
                collection.remove(block)


def make_material(maps, cache):
    import bpy
    key = tuple(str(maps.get(c, "")) for c in CHANNELS)
    if key in cache:
        return cache[key]
    mat = bpy.data.materials.new(maps["color"].stem)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Metallic"].default_value = 0
    bsdf.inputs["Specular IOR Level"].default_value = .25
    for channel, path in maps.items():
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = channel
        tex.image = bpy.data.images.load(str(path), check_existing=True)
        tex.image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
        tex.interpolation = "Linear"
        tex.extension = "EXTEND"
        if channel == "normal":
            normal = nodes.new("ShaderNodeNormalMap")
            links.new(tex.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
        else:
            socket = {"color": "Base Color", "roughness": "Roughness", "metalness": "Metallic"}[channel]
            links.new(tex.outputs["Color"], bsdf.inputs[socket])
    cache[key] = mat
    return mat


def import_assembly(folder, sources, by_piece, repacked):
    import bpy
    from mathutils import Vector
    cache, objects, provenance = {}, [], []
    for source in sources:
        sheet = by_piece.get(source.stem) if repacked else None
        path = folder / "repacked" / source.name if sheet else source
        require(path.is_file(), f"Missing {path}")
        before = set(bpy.data.objects)
        # Same import settings as repack.py; preserve every piece's transform.
        bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
        added = set(bpy.data.objects) - before
        meshes = [o for o in added if o.type == "MESH"]
        require(len(meshes) == 1, f"{path}: expected one mesh")
        obj = meshes[0]
        obj.name = source.stem
        require(len(obj.data.uv_layers) == 1, f"{path}: expected one UV layer")
        maps = ({c: folder / "repacked" / f"{sheet['name']}-{c}.png" for c in sheet["maps"]}
                if sheet else source_maps(folder / "parts", source.stem))
        require(all(p.is_file() for p in maps.values()), f"{path}: missing atlas map")
        obj.data.materials.clear()
        obj.data.materials.append(make_material(maps, cache))
        for poly in obj.data.polygons:
            poly.material_index = 0
        objects.append(obj)
        provenance.append({"piece": source.stem, "fbx": str(path),
                           "maps": {c: str(p) for c, p in maps.items()}})
        for other in added - {obj}:
            bpy.data.objects.remove(other, do_unlink=True)
    # Imported FBX dummy materials are not part of the comparison.
    for mat in list(bpy.data.materials):
        if not mat.users:
            bpy.data.materials.remove(mat)
    points = np.array([obj.matrix_world @ Vector(c) for obj in objects for c in obj.bound_box])
    return objects, points.min(0), points.max(0), provenance


def setup_scene(size, samples, low, high):
    import bpy
    from mathutils import Vector
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = samples
    scene.eevee.use_shadow_jitter_viewport = False
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.dither_intensity = 0
    scene.render.use_file_extension = True
    scene.render.use_compositing = False
    scene.render.use_sequencer = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.16, .19, .23, 1)
    scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = .7
    center = Vector((low + high) / 2)
    for name, direction, energy, color in (
            ("Key", (-3, -4, 6), 2.2, (1, .93, .84)),
            ("Fill", (4, 2, 3), 1.2, (.83, .91, 1)),
            ("Backfill", (-2, 4, 2), .7, (1, 1, 1))):
        data = bpy.data.lights.new(name, "SUN")
        data.energy, data.color, data.angle = energy, color, .08
        data.use_shadow = False  # avoids stochastic shadow noise in the diff
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.rotation_euler = (-Vector(direction)).to_track_quat("-Z", "Y").to_euler()
    data = bpy.data.cameras.new("Compare camera")
    data.lens = 50
    data.clip_start = max(float((high - low).max()) / 10000, .0001)
    data.clip_end = max(float((high - low).max()) * 30, 1000)
    camera = bpy.data.objects.new("Compare camera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, camera, center


def position_camera(camera, low, high, direction, close=False, target=None, distance=None):
    from mathutils import Vector
    center = Vector((low + high) / 2) if target is None else Vector(target)
    extent = high - low
    if close and target is None:
        center.z += float(extent[2]) * .08
    direction = Vector(direction).normalized()
    rotation = (-direction).to_track_quat("-Z", "Y")
    camera.rotation_euler = rotation.to_euler()
    if distance is None:
        inverse = rotation.inverted()
        corners = [inverse @ (Vector((x, y, z)) - center)
                   for x in (low[0], high[0]) for y in (low[1], high[1]) for z in (low[2], high[2])]
        # 36 mm sensor, square output, 50 mm lens. Fit every corner, with margin.
        tangent = 36 / (2 * camera.data.lens)
        distance = max(max(abs(c.x), abs(c.y)) / tangent + c.z for c in corners) * 1.12
        if close:
            distance *= .68
    camera.location = center + direction * distance
    return {"location": list(camera.location), "target": list(center), "lens_mm": camera.data.lens,
            "direction": list(direction), "distance": distance}


def render(scene, path):
    import bpy
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def ray_evidence(camera, objects, image_size, pixels):
    """Trace selected screen pixels to polygon/triangle UVs, in Blender axes."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    trees = []
    for obj in objects:
        mesh = obj.data
        mesh.calc_loop_triangles()
        vertices = [obj.matrix_world @ v.co for v in mesh.vertices]
        tris = list(mesh.loop_triangles)
        trees.append((obj, tris, BVHTree.FromPolygons(vertices, [t.vertices[:] for t in tris], all_triangles=True)))
    frame = camera.data.view_frame(scene=__import__("bpy").context.scene)
    # view_frame corners: top-right, bottom-right, bottom-left, top-left.
    results = []
    for x, y in pixels:
        u, v = (x + .5) / image_size, (y + .5) / image_size
        local = frame[3].lerp(frame[0], u).lerp(frame[2].lerp(frame[1], u), v)
        ray = (camera.matrix_world.to_quaternion() @ local).normalized()
        origin = camera.matrix_world.translation
        nearest = None
        for obj, tris, tree in trees:
            location, normal, index, dist = tree.ray_cast(origin, ray)
            if location is not None and (nearest is None or dist < nearest[0]):
                nearest = (dist, obj, tris[index], location, normal)
        if nearest is None:
            results.append({"pixel": [x, y], "hit": None})
            continue
        _, obj, tri, location, normal = nearest
        xyz = np.array([obj.matrix_world @ obj.data.vertices[i].co for i in tri.vertices])
        bary12 = np.linalg.lstsq((xyz[1:] - xyz[0]).T, np.array(location) - xyz[0], rcond=None)[0]
        bary = np.array([1 - bary12.sum(), *bary12])
        uv = bary @ np.array([obj.data.uv_layers.active.data[i].uv[:] for i in tri.loops])
        record = {"pixel": [x, y], "piece": obj.name, "polygon": tri.polygon_index,
                  "triangle": tri.index, "loops": list(tri.loops), "barycentric": bary.tolist(),
                  "world": list(location), "normal": list(normal), "uv": uv.tolist(), "maps": {}}
        for node in obj.data.materials[0].node_tree.nodes:
            if node.type == "TEX_IMAGE":
                record["maps"][node.name] = {"path": node.image.filepath,
                                             "texel": [float(uv[0] * node.image.size[0]), float(uv[1] * node.image.size[1])]}
        results.append(record)
    return results


def compare_folder(folder, args):
    import bpy
    started = time.monotonic()
    report, by_piece, sources = manifest(folder)
    output = args.out / folder.name
    output.mkdir(parents=True, exist_ok=True)
    metadata = {"building": folder.name, "size": args.size, "samples": args.samples,
                "threshold": args.threshold, "min_region": args.min_region,
                "packed_pieces": len(by_piece), "retained_pieces": len(sources) - len(by_piece),
                "note": report.get("note", ""), "views": {}, "assemblies": {}}
    reference_bounds = None
    for variant in ("old", "new"):
        clear_scene()
        objects, low, high, provenance = import_assembly(folder, sources, by_piece, variant == "new")
        metadata["assemblies"][variant] = provenance
        if reference_bounds is None:
            reference_bounds = (low.copy(), high.copy())
        else:
            require(np.array_equal(low, reference_bounds[0]) and np.array_equal(high, reference_bounds[1]),
                    f"{folder.name}: assembly bounds changed")
        scene, camera, center = setup_scene(args.size, args.samples, *reference_bounds)
        for name, direction in VIEWS:
            info = position_camera(camera, *reference_bounds, direction, close=name == "oblique")
            metadata["views"][name] = info
            render(scene, output / f"{variant}-{name}.png")
        if args.notebook_probe and folder.name == "notebook-tower":
            for name, direction in VIEWS[:4]:
                info = position_camera(camera, *reference_bounds, direction, close=True)
                metadata["views"]["close-" + name] = info
                render(scene, output / f"{variant}-close-{name}.png")
        if args.probe_camera:
            config = json.loads(args.probe_camera.read_text())
            for name, specification in config.items():
                metadata["views"][name] = position_camera(camera, *reference_bounds,
                                                        specification["direction"], target=specification["target"],
                                                        distance=specification["distance"])
                render(scene, output / f"{variant}-{name}.png")
                bpy.context.view_layer.update()
                metadata.setdefault("rays", {})[variant + "-" + name] = ray_evidence(
                    camera, objects, args.size, specification.get("pixels", []))
    metadata["bounds"] = [x.tolist() for x in reference_bounds]
    metadata["render_seconds"] = round(time.monotonic() - started, 2)
    (output / "render.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    result = subprocess.run([args.image_python, str(Path(__file__).resolve()), "--diff-worker", str(output)],
                            env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
    require(result.returncode == 0, f"{folder.name}: diff worker failed")
    clear_scene()
    return json.loads((output / "metrics.json").read_text())


def diff_worker(output):
    from PIL import Image, ImageDraw, ImageFont
    from scipy import ndimage
    metadata = json.loads((output / "render.json").read_text())
    size = metadata["size"]
    view_names = [name for name, _ in VIEWS]
    tile = min(size, 640)
    header, label = 56, 26
    contact = Image.new("RGB", (tile * 5, header + 2 * (tile + label)), (28, 32, 39))
    draw = ImageDraw.Draw(contact)
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)
    draw.text((10, 5), metadata["building"] + " | top: today's parts | bottom: repacked + retained", font=font, fill="white")
    metrics = {"building": metadata["building"], "views": {}, "note": metadata["note"],
               "packed_pieces": metadata["packed_pieces"], "retained_pieces": metadata["retained_pieces"],
               "threshold": metadata["threshold"], "min_region": metadata["min_region"]}
    all_diffs = []
    for column, name in enumerate(view_names):
        old = np.array(Image.open(output / f"old-{name}.png").convert("RGB"))
        new = np.array(Image.open(output / f"new-{name}.png").convert("RGB"))
        diff = np.abs(old.astype(np.int16) - new.astype(np.int16)).max(2)
        labels, _ = ndimage.label(diff > metadata["threshold"], structure=np.ones((3, 3)))
        areas = np.bincount(labels.ravel())
        kept = np.flatnonzero(areas > metadata["min_region"])
        kept = kept[kept != 0]
        mask = np.isin(labels, kept)
        outline = ndimage.binary_dilation(mask, iterations=2) & ~ndimage.binary_erosion(mask)
        regions = []
        slices = ndimage.find_objects(labels)
        for region in kept:
            sy, sx = slices[region - 1]
            regions.append({"pixels": int(areas[region]), "box": [sx.start, sy.start, sx.stop, sy.stop]})
        metrics["views"][name] = {"max": int(diff.max()), "mean": float(diff.mean()), "regions": regions}
        all_diffs.append(diff)
        for row, pixels in enumerate((old, new)):
            annotated = pixels.copy()
            annotated[outline] = (255, 20, 20)
            im = Image.fromarray(annotated)
            if tile != size:
                im = im.resize((tile, tile), Image.Resampling.LANCZOS)
            x, y = column * tile, header + row * (tile + label)
            contact.paste(im, (x, y + label))
            draw.text((x + 8, y + 4), name + (" | source" if row == 0 else " | repacked"), font=small, fill="white")
    combined = np.stack(all_diffs)
    metrics.update(max=int(combined.max()), mean=float(combined.mean()),
                   regions=sum(len(v["regions"]) for v in metrics["views"].values()))
    metrics["verdict"] = "DIFFERENT" if metrics["regions"] else "SAME"
    draw.text((10, 31), f"{metrics['verdict']} | max {metrics['max']}/255 | mean {metrics['mean']:.4f}/255 | "
              f"{metrics['regions']} regions > {metrics['min_region']} pixels at delta > {metrics['threshold']}",
              font=small, fill=(255, 160, 140) if metrics["regions"] else (140, 235, 170))
    contact.save(output.parent / f"{metadata['building']}.jpg", quality=92, subsampling=0)
    (output / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    # Resolve probe sample bytes in system Python, not color-managed Blender RAM.
    if metadata.get("rays"):
        for records in metadata["rays"].values():
            for record in records:
                for info in record.get("maps", {}).values():
                    image = Image.open(info["path"])
                    x, y = np.floor(info["texel"]).astype(int)
                    x, y = int(np.clip(x, 0, image.width - 1)), int(np.clip(y, 0, image.height - 1))
                    info["byte_value"] = image.getpixel((x, image.height - 1 - y))
        (output / "ray-evidence.json").write_text(json.dumps(metadata["rays"], indent=2), encoding="utf-8")
    log(summary_line(metrics))


def summary_line(metrics):
    return (f"{metrics['building']}\tmax={metrics['max']}\tmean={metrics['mean']:.6f}"
            f"\tregions={metrics['regions']}\t{metrics['verdict']}")


def write_summary(output):
    results = [json.loads(p.read_text()) for p in sorted(output.glob("*/metrics.json"))]
    (output / "summary.txt").write_text("\n".join(summary_line(m) for m in results) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--all", action="store_true", help="Every child folder with repacked/, including empty ones")
    parser.add_argument("--resume", action="store_true", help="Skip existing metrics at the same settings and unchanged inputs")
    parser.add_argument("--size", type=int, default=640)
    parser.add_argument("--samples", type=int, default=16)
    parser.add_argument("--threshold", type=int, default=12)
    parser.add_argument("--min-region", type=int, default=20)
    parser.add_argument("--out", type=Path, default=Path(".planning/repack-check"))
    parser.add_argument("--image-python", default=shutil.which("python"))
    parser.add_argument("--notebook-probe", action="store_true")
    parser.add_argument("--probe-camera", type=Path, help="JSON of named custom directions/targets/distances and screen pixels")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    require(args.image_python, "Need system Python with numpy/Pillow/scipy")
    require(args.size >= 128 and args.samples > 0, "Invalid render size or sample count")
    require(0 <= args.threshold < 255 and args.min_region >= 0, "Invalid comparison thresholds")
    args.folder, args.out = args.folder.resolve(), args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    folders = (sorted(p for p in args.folder.iterdir() if p.is_dir() and (p / "repacked").is_dir())
               if args.all else [args.folder])
    require(folders, "No repacked folders found")
    failures = []
    for number, folder in enumerate(folders, 1):
        log(f"{number}/{len(folders)} {folder.name}")
        inputs = sorted(p for directory in (folder / "parts", folder / "repacked")
                        for p in directory.glob("*") if p.suffix in (".fbx", ".png", ".json")
                        and not p.name.endswith(".upload.json"))
        signature = hashlib.sha256((Path(__file__).read_text() + repr(
            [(str(p), p.stat().st_size, p.stat().st_mtime_ns) for p in inputs]) + repr(
            (args.size, args.samples, args.threshold, args.min_region))).encode()).hexdigest()
        existing = args.out / folder.name / "metrics.json"
        if args.resume and existing.exists() and not args.notebook_probe and not args.probe_camera:
            if json.loads(existing.read_text()).get("input_signature") == signature:
                log("RESUME " + summary_line(json.loads(existing.read_text())))
                continue
        try:
            metrics = compare_folder(folder, args)
            metrics["input_signature"] = signature
            existing.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
            write_summary(args.out)
        except Exception as exc:
            log(f"FAIL {folder.name}: {exc}")
            failures.append({"building": folder.name, "error": str(exc)})
            clear_scene()
            if not args.all:
                raise
    write_summary(args.out)
    (args.out / "failures.json").write_text(json.dumps(failures, indent=2), encoding="utf-8")
    require(not failures, f"{len(failures)} buildings failed; see failures.json")
    log(f"DONE {len(folders)} buildings; {args.out / 'summary.txt'}")


if __name__ == "__main__":
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "--diff-worker":
            diff_worker(Path(sys.argv[2]))
        else:
            main()
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
