"""Repack hero/blocks FBXs by integer texel translations, without rebaking.

D:/Blender/blender.exe -b --python tools/art/repack.py -- assets/models/clock-tower --sheet 2048 --check
Use --out repacked-1024 for a second pilot. Requires numpy in Blender and a
system Python with numpy, Pillow and scipy (override with --image-python).
--sheet is the maximum dimension; each atlas uses the smallest fitting format.
Only the chosen building's repacked* output directory is written.
"""

import argparse
import array
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

import numpy as np

OLD_SIZE = 1024
PAD = 4
CHANNELS = ("color", "normal", "roughness", "metalness")
FORMATS = ((512, 512), (1024, 512), (1024, 1024), (2048, 1024), (2048, 2048))


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def log(message):
    print("REPACK " + message, flush=True)


def mesh_data(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    return {
        "positions": np.array([v.co[:] for v in mesh.vertices]),
        "normals": np.array([n.vector[:] for n in mesh.corner_normals]),
        "matrix": np.array(obj.matrix_world),
        "triangles": np.array([t.vertices[:] for t in mesh.loop_triangles]),
        "loops": np.array([t.loops[:] for t in mesh.loop_triangles]),
        "uv": np.array([v.uv[:] for v in mesh.uv_layers.active.data]),
    }


def islands(obj, uv):
    """Connected faces with matching UVs on both ends of an edge."""
    mesh = obj.data
    parent = list(range(len(mesh.polygons)))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    edges = {}
    for face in mesh.polygons:
        ls = list(face.loop_indices)
        for a, b in zip(ls, ls[1:] + ls[:1]):
            va, vb = mesh.loops[a].vertex_index, mesh.loops[b].vertex_index
            ua, ub = tuple(uv[a]), tuple(uv[b])
            key = (va, vb, ua, ub) if va < vb else (vb, va, ub, ua)
            if key in edges:
                parent[root(face.index)] = root(edges[key])
            else:
                edges[key] = face.index
    labels = {}
    ids = np.empty(len(mesh.loops), dtype=np.int32)
    for face in mesh.polygons:
        ids[list(face.loop_indices)] = labels.setdefault(root(face.index), len(labels))
    return ids


def import_piece(path):
    import bpy
    # Delete objects, not files. Never load/save a .blend or run model scripts.
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if not mesh.users:
            bpy.data.meshes.remove(mesh)
    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    require(len(meshes) == 1, f"{path.name}: expected one mesh")
    obj = meshes[0]
    require(len(obj.data.uv_layers) == 1, f"{path.name}: expected one UV layer")
    for other in bpy.context.selected_objects:
        other.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    return obj


def children(node, name):
    return [e for e in node.elems if e.id == name]


def geometry(tree):
    objects = children(tree, b"Objects")[0]
    meshes = [e for e in children(objects, b"Geometry") if e.props[-1] == b"Mesh"]
    require(len(meshes) == 1, "FBX must contain one mesh geometry")
    return meshes[0]


def file_uv(path):
    """FBX stores doubles; Blender's float32 loop UVs lose low bits on moves."""
    from io_scene_fbx import parse_fbx
    tree, _ = parse_fbx.parse(str(path))
    layer = children(geometry(tree), b"LayerElementUV")[0]
    require(children(layer, b"MappingInformationType")[0].props == [b"ByPolygonVertex"] and
            children(layer, b"ReferenceInformationType")[0].props == [b"IndexToDirect"],
            f"{path.name}: unsupported FBX UV mapping")
    uv = np.array(children(layer, b"UV")[0].props[0]).reshape(-1, 2)
    return uv[np.array(children(layer, b"UVIndex")[0].props[0])]


def fbx_signature(node):
    """Decoded FBX values, excluding only the UV payload."""
    if node.id == b"LayerElementUV":
        return (node.id,)
    props = tuple((v.typecode, v.tobytes()) if isinstance(v, array.array) else v for v in node.props)
    return node.id, bytes(node.props_type), props, tuple(fbx_signature(e) for e in node.elems)


def export_uv_only(obj, source, destination, scratch, precise_uv):
    import bpy
    from io_scene_fbx import encode_bin, parse_fbx
    staged = scratch / "export.fbx"
    report_path = source.parent.parent / "parts.json"
    blocks = report_path.exists() and json.loads(report_path.read_text(encoding="utf-8")).get("source") == "tools/art/blocks.py"
    bpy.context.scene.unit_settings.system = "NONE"
    bpy.context.scene.unit_settings.scale_length = 1
    # Exactly hero.py's settings; blocks.py additionally disables animation.
    bpy.ops.export_scene.fbx(
        filepath=str(staged), use_selection=True, object_types={"MESH"},
        apply_unit_scale=False, global_scale=1, axis_forward="-Z", axis_up="Y",
        bake_space_transform=False, mesh_smooth_type="OFF", path_mode="AUTO",
        embed_textures=False, add_leaf_bones=False, **({"bake_anim": False} if blocks else {}))
    original, version = parse_fbx.parse(str(source))
    exported, _ = parse_fbx.parse(str(staged))
    old_geo, new_geo = geometry(original), geometry(exported)
    require(children(old_geo, b"PolygonVertexIndex")[0].props ==
            children(new_geo, b"PolygonVertexIndex")[0].props, "Exporter changed polygon order")
    uv_layer = children(new_geo, b"LayerElementUV")
    require(len(uv_layer) == 1, "Exporter changed UV layer count")
    # Use one double-precision UV per polygon corner. Do not let Blender's
    # float32 UV editor round the exact integer-texel translation in the file.
    uv_values = children(uv_layer[0], b"UV")[0].props
    uv_indices = children(uv_layer[0], b"UVIndex")[0].props
    uv_values[0] = array.array(uv_values[0].typecode, precise_uv.ravel())
    uv_indices[0] = array.array(uv_indices[0].typecode, range(len(precise_uv)))
    # Blender's normal import/export normalizes values and introduces a tiny
    # axis rotation. Keep EVERY original FBX value except the new UV layer.
    setters = dict(zip("BZYCIFDLRSbcildf", (
        "bool", "int8", "int16", "char", "int32", "float32", "float64", "int64",
        "bytes", "string", "bool_array", "byte_array", "int32_array", "int64_array",
        "float64_array", "float32_array")))

    def encode(node):
        if node.id == b"LayerElementUV":
            node = uv_layer[0]
        result = encode_bin.FBXElem(node.id)
        for kind, value in zip(node.props_type, node.props):
            getattr(result, "add_" + setters[chr(kind)])(value)
        result.elems = [encode(e) for e in node.elems]
        return result

    encode_bin.write(str(destination), encode(original), version)
    written, _ = parse_fbx.parse(str(destination))
    require(fbx_signature(original) == fbx_signature(written),
            f"{source.name}: a non-UV FBX value changed")


def raster_island(triangles):
    """All texel cells touched by a triangle, plus a full 4 px square bleed."""
    from scipy import ndimage
    px = triangles * OLD_SIZE
    low = np.floor(px.min(axis=(0, 1))).astype(int) - PAD
    high = np.floor(px.max(axis=(0, 1))).astype(int) + PAD + 1
    mask = np.zeros(tuple((high - low)[::-1]), dtype=bool)
    for tri in px:
        lo = np.floor(tri.min(0)).astype(int)
        hi = np.floor(tri.max(0)).astype(int) + 1
        x, y = np.meshgrid(np.arange(lo[0], hi[0]) + .5, np.arange(lo[1], hi[1]) + .5)
        edges = np.roll(tri, -1, axis=0) - tri
        cross = edges[0, 0] * edges[1, 1] - edges[0, 1] * edges[1, 0]
        sign = 1 if cross >= 0 else -1
        inside = np.ones(x.shape, dtype=bool)
        for point, edge in zip(tri, edges):
            inside &= sign * (edge[0] * (y - point[1]) - edge[1] * (x - point[0])) >= (
                -.5 * (abs(edge[0]) + abs(edge[1])) - 1e-10)
        mask[lo[1] - low[1]:hi[1] - low[1], lo[0] - low[0]:hi[0] - low[0]] |= inside
    padded = ndimage.binary_dilation(mask, structure=np.ones((9, 9), dtype=bool))
    return {"low": low, "mask": mask, "padded": padded,
            "area": int(mask.sum()), "padded_area": int(padded.sum()),
            "w": mask.shape[1], "h": mask.shape[0]}


def carve(free, x, y, w, h):
    kept, split = [], []
    for fx, fy, fw, fh in free:
        right, top = fx + fw, fy + fh
        if x >= right or x + w <= fx or y >= top or y + h <= fy:
            kept.append((fx, fy, fw, fh))
            continue
        if fx < x:
            split.append((fx, fy, x - fx, fh))
        if right > x + w:
            split.append((x + w, fy, right - x - w, fh))
        if fy < y:
            split.append((fx, fy, fw, y - fy))
        if top > y + h:
            split.append((fx, y + h, fw, top - y - h))
    # MaxRects free rectangles overlap; remove contained ones, never occupied ones.
    split = list(set(split))
    free[:] = kept + [r for r in split if not any(
        q != r and q[0] <= r[0] and q[1] <= r[1] and
        q[0] + q[2] >= r[0] + r[2] and q[1] + q[3] >= r[1] + r[3] for q in kept + split)]


def shape_place(board, mask):
    """Filter candidate origins with scattered mask pixels, then test exactly.

    This nests small islands into concave gaps that rectangles cannot use.
    All candidate filtering runs in numpy, rather than scanning in Python.
    """
    h, w = mask.shape
    height, width = board.shape[0] - h + 1, board.shape[1] - w + 1
    if min(height, width) <= 0:
        return None
    my, mx = np.nonzero(mask)
    samples = np.unique(np.linspace(0, len(mx) - 1, min(64, len(mx))).astype(int))
    # Search short row bands, stopping at the first exact fit. Filtering the
    # entire sheet for every tiny island wastes most of the packing time.
    for start in range(0, height, 32):
        rows = min(32, height - start)
        possible = np.ones((rows, width), dtype=bool)
        for sample in samples:
            py, px = my[sample], mx[sample]
            possible &= ~board[start + py:start + py + rows, px:px + width]
            if not possible.any():
                break
        yy, xx = np.nonzero(possible)
        for y, x in zip(yy + start, xx):
            if not (board[y:y + h, x:x + w] & mask).any():
                return [int(x), int(y)]
    return None


def rectangle_place(free, island):
    w, h = island["w"], island["h"]
    choices = [(min(fw - w, fh - h), max(fw - w, fh - h), y, x)
               for x, y, fw, fh in free if w <= fw and h <= fh]
    if not choices:
        return None
    _, _, y, x = min(choices)
    carve(free, x, y, w, h)
    return [x, y]


def pack(pieces, size):
    """Fill large sheets first, then minimize texels, with originals as a fallback.

    Trials never move committed islands. Cached trials let shrinking, splitting
    and regrouping use the same exact padding tests without repeating work.
    """
    formats = [d for d in FORMATS if max(d) <= size]
    cache, best_cache = {}, {}

    def layout(group, dimensions):
        group = sorted(group, key=lambda p: p["stem"])
        key = (tuple(p["stem"] for p in group), dimensions)
        if key in cache:
            return cache[key]
        width, height = dimensions
        ordered = sorted([i for p in group for i in p["islands"]],
                         key=lambda i: (-max(i["w"], i["h"]), -i["w"] * i["h"], i["id"]))
        cache[key] = None
        if (sum(i["padded_area"] for i in ordered) > width * height or
                any(i["w"] > width or i["h"] > height for i in ordered)):
            return None
        free = [(0, 0, width, height)]
        board = np.zeros((height, width), dtype=bool)
        placements = []
        for island in ordered:
            where = rectangle_place(free, island)
            if where is None:
                where = shape_place(board, island["padded"])
                if where is None:
                    break
                carve(free, *where, island["w"], island["h"])
            x, y = where
            board[y:y + island["h"], x:x + island["w"]] |= island["padded"]
            placements.append((island, where))
        else:
            cache[key] = {"pieces": group, "width": width, "height": height, "placements": placements}
        # A regular grid is a useful fallback for a pair/four of already fitting
        # pieces. It also avoids blaming a greedy packing failure on geometry.
        if cache[key] is None and len(group) > 1:
            for cell in (512, 1024):
                columns, rows = width // cell, height // cell
                if not columns or len(group) > columns * rows or (cell, cell) == dimensions:
                    continue
                tiles = [layout([p], (cell, cell)) for p in group]
                if all(t is not None for t in tiles):
                    placements = [(island, [x + n % columns * cell, y + n // columns * cell])
                                  for n, tile in enumerate(tiles) for island, (x, y) in tile["placements"]]
                    cache[key] = {"pieces": group, "width": width, "height": height, "placements": placements}
                    break
        return cache[key]

    def best(group):
        key = tuple(sorted(p["stem"] for p in group))
        if key not in best_cache:
            best_cache[key] = next((s for d in formats if (s := layout(group, d)) is not None), None)
        return best_cache[key]

    def score(sheets, kept=()):
        # Count per-map texels, including a metalness sheet when ANY member has
        # one. Retained pieces keep paying for their original 1024 maps.
        return (sum(s["width"] * s["height"] * (3 + any(p["metal"] for p in s["pieces"])) for s in sheets)
                + sum(OLD_SIZE ** 2 * (3 + p["metal"]) for p in kept),
                sum(3 + any(p["metal"] for p in s["pieces"]) for s in sheets)
                + sum(3 + p["metal"] for p in kept), len(kept))

    initial, skipped = [], []
    for piece in sorted(pieces, key=lambda p: (-sum(i["padded_area"] for i in p["islands"]), p["stem"])):
        for index in range(len(initial) + 1):
            group = initial[index]["pieces"] + [piece] if index < len(initial) else [piece]
            sheet = layout(group, (size, size))
            if sheet is not None:
                if index == len(initial):
                    initial.append(sheet)
                else:
                    initial[index] = sheet
                break
        else:
            smaller = best([piece])
            if smaller is not None:
                initial.append(smaller)
                continue
            skipped.append({"piece": piece["stem"], "reason":
                            f"Packing search could not fit this piece on any allowed sheet up to {size}x{size} with unchanged pixels and 4 px padding"})
            log("SKIP " + piece["stem"] + ": cannot fit with unchanged pixels/padding")

    sheets, retained = [], []
    for full in initial:
        group = sorted(full["pieces"], key=lambda p: (-sum(i["padded_area"] for i in p["islands"]), p["stem"]))
        # Minimum-cost contiguous partitions of this greedy group. Keeping one
        # piece's originals is always available, so memory can never grow.
        plans = [([], [])]
        for end in range(1, len(group) + 1):
            prev, kept = plans[end - 1]
            options = [(prev, kept + [group[end - 1]])]
            for start in range(end):
                candidate = best(group[start:end])
                if candidate is not None:
                    before, originals = plans[start]
                    options.append((before + [candidate], originals))
            plans.append(min(options, key=lambda plan: score(*plan)))
        chosen, originals = plans[-1]
        sheets.extend(chosen)
        retained.extend(originals)

    # Cross former sheet boundaries when a merge saves memory or texture files.
    # A strictly improving score makes the loop finite and prevents shuffling.
    while True:
        improvement = None
        for a in range(len(sheets)):
            for b in range(a + 1, len(sheets)):
                combined = best(sheets[a]["pieces"] + sheets[b]["pieces"])
                if combined is not None and score([combined]) < score([sheets[a], sheets[b]]):
                    improvement = (a, b, combined)
                    break
            if improvement:
                break
        if improvement is None:
            for piece in list(retained):
                for index, sheet in enumerate(sheets):
                    combined = best(sheet["pieces"] + [piece])
                    if combined is not None and score([combined]) < score([sheet], [piece]):
                        sheets[index] = combined
                        retained.remove(piece)
                        improvement = "absorbed"
                        break
                if improvement:
                    break
        if improvement is None:
            break
        if improvement == "absorbed":
            continue
        a, b, combined = improvement
        sheets[a] = combined
        del sheets[b]
    for piece in retained:
        skipped.append({"piece": piece["stem"], "reason":
                        "Kept original maps to keep this building within its original texel budget"})
        log("SKIP " + piece["stem"] + ": keeping originals avoids extra texels")
    # Large sheets first leaves the smallest sheet at the end of the building.
    sheets.sort(key=lambda s: (-s["width"] * s["height"], tuple(p["stem"] for p in s["pieces"])))
    for index, sheet in enumerate(sheets):
        for piece in sheet["pieces"]:
            piece["sheet"] = index
        for island, where in sheet["placements"]:
            island["where"] = where
        log(f"Packed {len(sheet['pieces'])} pieces on sheet-{index + 1} ({sheet['width']}x{sheet['height']})")
    return sheets, skipped


def read_map(path):
    from PIL import Image
    with Image.open(path) as im:
        require(im.size == (OLD_SIZE, OLD_SIZE), f"{path.name}: expected 1024 x 1024")
        require(im.mode in ("RGB", "RGBA", "L", "LA"), f"Unsupported byte format: {path.name} ({im.mode})")
        return np.array(im)[::-1].copy(), im.mode


def make_sheets(sheets, parts, output):
    from PIL import Image
    from scipy import ndimage
    report, thumbs = [], []
    for number, sheet in enumerate(sheets, 1):
        name = f"sheet-{number}"
        width, height = sheet["width"], sheet["height"]
        occupied = np.zeros((height, width), dtype=bool)
        surface = np.zeros_like(occupied)
        maps = {c: [] for c in CHANNELS}
        for piece in sheet["pieces"]:
            for channel in CHANNELS:
                path = parts / f"{piece['stem']}-{channel}.png"
                maps[channel].append(read_map(path) if path.exists() else None)
            for island in piece["islands"]:
                x, y = island["where"]
                w, h = island["w"], island["h"]
                require(0 <= x <= width - w and 0 <= y <= height - h, "Padding outside sheet")
                region = occupied[y:y + h, x:x + w]
                require(not (region & island["padded"]).any(), "Padded masks overlap")
                region |= island["padded"]
                surface[y:y + h, x:x + w] |= island["mask"]
        # Same nearest protected-texel fill as fill_gaps.py's UV mode.
        nearest = ndimage.distance_transform_edt(~occupied, return_distances=False, return_indices=True)
        written = []
        for channel in CHANNELS:
            present = [m for m in maps[channel] if m is not None]
            if not present:
                require(channel == "metalness", f"Missing {channel} map")
                continue
            alpha = any(m[1] in ("RGBA", "LA") for m in present)
            rgb = any(m[1] in ("RGB", "RGBA") for m in present) or channel in ("color", "normal")
            mode = ("RGBA" if alpha else "RGB") if rgb else ("LA" if alpha else "L")
            channels = len(mode) if mode != "L" else 1
            canvas = np.zeros((height, width, channels), dtype=np.uint8)
            for piece, data in zip(sheet["pieces"], maps[channel]):
                if data is None:
                    # Absent SurfaceAppearance MetalnessMap means non-metal.
                    source = np.zeros((OLD_SIZE, OLD_SIZE, channels), dtype=np.uint8)
                    if alpha:
                        source[:, :, -1] = 255
                else:
                    pixels, old_mode = data
                    source = np.array(Image.fromarray(pixels).convert(mode))
                    if source.ndim == 2:
                        source = source[:, :, None]
                for island in piece["islands"]:
                    x, y = island["where"]
                    sx, sy = island["low"]
                    w, h = island["w"], island["h"]
                    original = source[np.arange(sy, sy + h).clip(0, OLD_SIZE - 1)[:, None],
                                      np.arange(sx, sx + w).clip(0, OLD_SIZE - 1)]
                    canvas[y:y + h, x:x + w][island["padded"]] = original[island["padded"]]
            if channel == "normal":
                require(rgb, "Normal map must be RGB")
                canvas[~occupied, :3] = (128, 128, 255)
                if alpha:
                    canvas[~occupied, -1] = 255
            elif channel == "color":
                # fill_gaps.py's dark-pixel cutoff prevents black bake borders
                # from spreading across the empty sheet. Keep EVERY protected
                # pixel, including legitimate dark detail and black padding.
                seeds = surface & (canvas[:, :, :3].max(axis=2) >= 90)
                if seeds.any():
                    color_nearest = ndimage.distance_transform_edt(
                        ~seeds, return_distances=False, return_indices=True)
                    canvas[~occupied] = canvas[color_nearest[0][~occupied], color_nearest[1][~occupied]]
                    require((canvas[~occupied, :3].max(axis=1) >= 90).all(), "Black color gaps remain")
                else:
                    canvas = canvas[nearest[0], nearest[1]]
            else:
                canvas = canvas[nearest[0], nearest[1]]
            pixels = canvas[:, :, 0] if mode == "L" else canvas
            path = output / f"{name}-{channel}.png"
            Image.fromarray(pixels[::-1]).save(path)
            written.append(channel)
            if channel == "color":
                thumb = Image.open(path).convert("RGB")
                thumb.thumbnail((512, 512), Image.Resampling.LANCZOS)
                thumbs.append(thumb.copy())
                thumb.close()
        report.append({"name": name, "pieces": [p["stem"] for p in sheet["pieces"]],
                       "width": width, "height": height,
                       "coverage": round(float(surface.mean()), 6),
                       "padded_coverage": round(float(occupied.mean()), 6),
                       "maps": written, "metalness": "present" if "metalness" in written else "absent"})
        log(f"{name}: {surface.mean():.1%} surface, {occupied.mean():.1%} including padding")
    contact = Image.new("RGB", (512 * max(1, len(thumbs)), 512), (128, 128, 128))
    for i, thumb in enumerate(thumbs):
        contact.paste(thumb, (i * 512, 0))
    contact.save(output / "contact.png")
    return report


def image_worker(job_path):
    job = json.loads(job_path.read_text())
    scratch, parts, output = (Path(job[k]) for k in ("scratch", "parts", "output"))
    pieces = []
    for stem in job["pieces"]:
        with np.load(scratch / f"{stem}.npz") as data:
            uv, loops, ids = data["uv"], data["loops"], data["islands"]
        piece = {"stem": stem, "islands": [], "metal": (parts / f"{stem}-metalness.png").exists()}
        tri_ids = ids[loops[:, 0]]
        for i in range(int(ids.max()) + 1):
            island = raster_island(uv[loops[tri_ids == i]])
            island["id"] = i
            piece["islands"].append(island)
        log(f"Read {stem}: {len(piece['islands'])} islands, "
            f"{sum(i['padded_area'] for i in piece['islands']) / OLD_SIZE ** 2:.1%} padded area")
        pieces.append(piece)
    sheets, skipped = pack(pieces, job["size"])
    report = make_sheets(sheets, parts, output)
    included = [p for s in sheets for p in s["pieces"]]
    placements = {p["stem"]: {"sheet": p["sheet"], "offsets": [
        (np.asarray(i["where"]) - i["low"]).tolist() for i in sorted(p["islands"], key=lambda i: i["id"])],
        "width": sheets[p["sheet"]]["width"], "height": sheets[p["sheet"]]["height"]}
        for p in included}
    (scratch / "packing.json").write_text(json.dumps({"placements": placements, "sheets": report, "skipped": skipped}))


def compare_piece(old, new, ids, offsets, dimensions, stem):
    for key in ("triangles", "loops"):
        require(np.array_equal(old[key], new[key]), f"{stem}: changed triangle/loop order")
    for key in ("positions", "normals", "matrix"):
        require(old[key].shape == new[key].shape and np.array_equal(old[key], new[key]),
                f"{stem}: changed {key}")
    require(np.isfinite(new["uv"]).all() and (new["uv"] >= 0).all() and (new["uv"] <= 1).all(),
            f"{stem}: new UV outside [0,1]")
    delta = new["uv"] * dimensions - old["uv"] * OLD_SIZE
    require(np.max(abs(delta - np.asarray(offsets)[ids])) < .0003,
            f"{stem}: UV change is not the planned integer translation")


def pixel_checks(job_path):
    from PIL import Image
    job = json.loads(job_path.read_text())
    scratch, parts, output = (Path(job[k]) for k in ("scratch", "parts", "output"))
    plan = json.loads((scratch / "packing.json").read_text())
    rng = np.random.default_rng(20261025)
    count = 0
    for stem, placement in plan["placements"].items():
        dimensions = np.array([placement["width"], placement["height"]])
        with np.load(scratch / f"{stem}.npz") as data:
            uv, loops, ids, vertices, triangles = [data[k] for k in ("uv", "loops", "islands", "positions", "triangles")]
        with np.load(scratch / f"{stem}-checked.npz") as data:
            new_uv = data["uv"]
        xyz = vertices[triangles]
        area = np.linalg.norm(np.cross(xyz[:, 1] - xyz[:, 0], xyz[:, 2] - xyz[:, 0]), axis=1)
        require(area.sum() > 0, f"{stem}: zero surface area")
        chosen = rng.choice(len(loops), 5000, p=area / area.sum())
        a = np.sqrt(rng.random(5000))
        b = rng.random(5000)
        bary = np.stack((1 - a, a * (1 - b), a * b), axis=1)
        old_points = np.einsum("ij,ijk->ik", bary, uv[loops[chosen]])
        new_points = np.einsum("ij,ijk->ik", bary, new_uv[loops[chosen]])
        ox, oy = np.floor(old_points * OLD_SIZE).astype(int).clip(0, OLD_SIZE - 1).T
        nx, ny = np.minimum(np.maximum(np.floor(new_points * dimensions).astype(int), 0), dimensions - 1).T
        tri_ids = ids[loops[:, 0]]
        masks = [raster_island(uv[loops[tri_ids == i]]) for i in range(len(placement["offsets"]))]
        for channel in CHANNELS:
            source_path = parts / f"{stem}-{channel}.png"
            sheet_path = output / f"sheet-{placement['sheet'] + 1}-{channel}.png"
            source, mode = read_map(source_path) if source_path.exists() else (None, None)
            if not sheet_path.exists():
                require(source is None and channel == "metalness", "Missing output map")
                continue
            with Image.open(sheet_path) as im:
                require(im.size == tuple(dimensions), f"{stem}: incorrect sheet dimensions")
                target_mode = im.mode
                target = np.array(im)[::-1]
            if source is not None:
                source = np.array(Image.fromarray(source).convert(target_mode))
                require(np.array_equal(source[oy, ox], target[ny, nx]), f"{stem}: {channel} random samples differ")
            else:
                expected_zero = np.zeros_like(target[ny, nx])
                if target_mode in ("RGBA", "LA"):
                    expected_zero[:, -1] = 255
                require(np.array_equal(target[ny, nx], expected_zero), f"{stem}: absent metalness is not zero")
            # Stronger than random samples: every island and padding byte.
            for island, offset in zip(masks, placement["offsets"]):
                yy, xx = np.nonzero(island["padded"])
                sx, sy = (np.stack((xx, yy), 1) + island["low"]).T
                tx, ty = sx + offset[0], sy + offset[1]
                expected = source[sy.clip(0, OLD_SIZE - 1), sx.clip(0, OLD_SIZE - 1)] if source is not None else np.zeros_like(target[ty, tx])
                if source is None and target_mode in ("RGBA", "LA"):
                    expected[:, -1] = 255
                require(np.all(target[ty, tx] == expected), f"{stem}: {channel} protected pixels differ")
        count += 1
        log(f"PASS {stem}: geometry/UVs, 5000 saved-FBX surface samples, all padded bytes")
    log(f"PASS {count} pieces / {count * 5000} saved-FBX surface points / all four map types")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--sheet", type=int, choices=(1024, 2048), default=2048)
    parser.add_argument("--out", type=Path, default=Path("repacked"), help="Building-local repacked* directory")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--image-python", default=shutil.which("python"), help="Python with Pillow/scipy/numpy")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    folder = args.folder.resolve()
    parts = folder / "parts"
    output = (folder / args.out).resolve()
    require(output.parent == folder and output.name.startswith("repacked"),
            "--out must be a repacked* directory directly inside the building folder")
    require(args.image_python, "Need system Python with numpy, Pillow, scipy; pass --image-python")
    require(not output.is_symlink(), "Output cannot be a symlink")
    # Refuse unknown files instead of clearing a user's existing directory.
    if output.exists():
        require(all(p.is_file() and not p.is_symlink() and (p.name in ("contact.png", "repack.json") or
                    p.name.startswith("sheet-") and p.suffix == ".png" or
                    p.suffix == ".fbx" and (parts / p.name).is_file()) for p in output.iterdir()),
                "Output contains unrelated files; choose a different --out directory")
    sources = sorted(parts.glob("*.fbx"), key=lambda p: (int(p.stem.split("-", 1)[0]), p.name))
    require(sources, "No numbered piece FBXs in parts/")
    originals = list(sources)
    skipped = [{"piece": p.stem, "reason": "Color variant files; original maps retained"}
               for p in sources if list(parts.glob(p.stem + "-color-*.png"))]
    sources = [p for p in sources if p.stem not in {s["piece"] for s in skipped}]
    if skipped:
        log("Skipped color variants: " + ", ".join(s["piece"] for s in skipped))
    for source in sources:
        for channel in CHANNELS[:3]:
            require((parts / f"{source.stem}-{channel}.png").is_file(), f"Missing {source.stem}-{channel}.png")
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="ffp-repack-") as temp:
        scratch = Path(temp)
        job = {"scratch": temp, "parts": str(parts), "output": str(output), "size": args.sheet,
               "pieces": [p.stem for p in sources]}
        job_path = scratch / "job.json"
        job_path.write_text(json.dumps(job))
        for source in sources:
            obj = import_piece(source)
            data = mesh_data(obj)
            precise = file_uv(source)
            require(precise.shape == data["uv"].shape and np.max(abs(precise - data["uv"])) < 1e-7,
                    f"{source.name}: imported UV order differs from FBX")
            data["uv"] = precise
            require(np.isfinite(data["uv"]).all() and (data["uv"] >= 0).all() and (data["uv"] <= 1).all(),
                    f"{source.name}: source UVs outside [0,1]")
            np.savez(scratch / f"{source.stem}.npz", **data, islands=islands(obj, data["uv"]))
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")

        def worker(mode):
            result = subprocess.run([args.image_python, str(Path(__file__).resolve()), mode, str(job_path)], env=env)
            require(result.returncode == 0, "Image/check worker failed; see FAIL above")

        worker("--pack-worker")
        packing = json.loads((scratch / "packing.json").read_text())
        skipped.extend(packing["skipped"])
        sources = [p for p in sources if p.stem in packing["placements"]]
        for source in sources:
            obj = import_piece(source)
            with np.load(scratch / f"{source.stem}.npz") as data:
                placement = packing["placements"][source.stem]
                dimensions = np.array([placement["width"], placement["height"]])
                uv = (data["uv"] * OLD_SIZE + np.asarray(placement["offsets"])[data["islands"]]) / dimensions
            obj.data.uv_layers.active.data.foreach_set("uv", uv.ravel())
            export_uv_only(obj, source, output / source.name, scratch, uv)
        if args.check:
            for source in sources:
                old = mesh_data(import_piece(source))
                new = mesh_data(import_piece(output / source.name))
                with np.load(scratch / f"{source.stem}.npz") as data:
                    ids = data["islands"]
                placement = packing["placements"][source.stem]
                dimensions = np.array([placement["width"], placement["height"]])
                compare_piece(old, new, ids, placement["offsets"], dimensions, source.stem)
                old_uv, new_uv = file_uv(source), file_uv(output / source.name)
                delta = new_uv * dimensions - old_uv * OLD_SIZE
                require(np.max(abs(delta - np.asarray(packing["placements"][source.stem]["offsets"])[ids])) < 1e-10,
                        f"{source.name}: saved UVs lost integer-texel precision")
                np.savez(scratch / f"{source.stem}-checked.npz", uv=new_uv)
            worker("--check-worker")
        def map_count(paths):
            return sum((parts / f"{p.stem}-{c}.png").is_file() or
                       c == "color" and bool(list(parts.glob(p.stem + "-color-*.png")))
                       for p in paths for c in CHANNELS)

        old_files = map_count(originals)
        retained = [p for p in originals if p.stem not in packing["placements"]]
        retained_files = map_count(retained)
        new_files = sum(len(s["maps"]) for s in packing["sheets"])
        new_pixels = sum(len(s["maps"]) * s["width"] * s["height"] for s in packing["sheets"])
        report = {"sheet_size": args.sheet, "sheets": packing["sheets"], "skipped": skipped,
                  "old": {"sheets": len(originals), "files": old_files, "pixels": old_files * OLD_SIZE ** 2},
                  "new": {"sheets": len(packing["sheets"]) + len(retained), "files": new_files + retained_files,
                          "pixels": new_pixels + retained_files * OLD_SIZE ** 2},
                  "repacked": {"sheets": len(packing["sheets"]), "files": new_files, "pixels": new_pixels},
                  "retained": {"sheets": len(retained), "files": retained_files, "pixels": retained_files * OLD_SIZE ** 2},
                  "counts_note": "Texture files/texels only. Old/new include unchanged skipped pieces; repacked counts generated PNGs only. FBXs and contact preview excluded.",
                  "uv_precision_note": "Saved FBX doubles checked exactly; Blender float32 re-import checked within 0.0003 texel. Samples use the saved FBX UVs.",
                  "check": "PASS" if args.check else "not run"}
        report["texel_increase"] = max(0, report["new"]["pixels"] - report["old"]["pixels"])
        if report["texel_increase"]:
            log(f"WARNING: {folder.name} exceeds its old texel total by {report['texel_increase']}")
        (output / "repack.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        expected = {"contact.png", "repack.json"} | {p.name for p in sources} | {
            f"{s['name']}-{c}.png" for s in packing["sheets"] for c in s["maps"]}
        for path in output.iterdir():
            if path.name not in expected:
                path.unlink()  # Remove only stale generated files in this verified directory.
        log(json.dumps({k: report[k] for k in ("sheet_size", "old", "new", "skipped", "check")}))


if __name__ == "__main__":
    try:
        if len(sys.argv) > 1 and sys.argv[1] in ("--pack-worker", "--check-worker"):
            (image_worker if sys.argv[1] == "--pack-worker" else pixel_checks)(Path(sys.argv[2]))
        else:
            main()
    except Exception as exc:
        log(f"FAIL: {exc or type(exc).__name__}")
        # Blender otherwise exits zero after a Python exception without the CLI
        # --python-exit-code switch. Make the advertised invocation reliable.
        if os.environ.get("FFP_REPACK_DEBUG"):
            import traceback
            traceback.print_exc()
        sys.stdout.flush()
        sys.stderr.flush()
        os._exit(1)
