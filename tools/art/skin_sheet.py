"""Local printed-sheet copies. Blender 5.1, bundled Python and NumPy only.

Run from the repository root:
  D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 --python tools/art/skin_sheet.py

No source, place, upload, git or Studio operations. The numerical normal bake
uses Blender's own MikkTSpace loop tangents, transports sampled old-UV normals
through object space, then solves for the new tangent coordinates. Overlapping
projections use an explicit facing/depth buffer, rather than bake draw order.
"""

import ast
import hashlib
import itertools
import json
import math
import os
from pathlib import Path
import struct
import sys
import time
import xml.etree.ElementTree as ET
import zlib

import bpy
import numpy as np
from mathutils import Matrix, Vector
from io_scene_fbx import parse_fbx, encode_bin


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets/models/planes"
OUT = BASE / "skin-sheet"
REVIEW = ROOT / ".planning/skins/sheet"
N = 1024
MARGIN = GAP = 16
PAD = .25
TOL = 1e-4
STARTERS = {"body_standard", "nose_0", "wings_0", "tail_0"}
BUILDS = {"starter": ["body_standard", "nose_0", "wings_0", "tail_0"],
          "heavy": ["body_heavy", "nose_3", "wings_4", "tail_3"]}
VIEWS = ["three-quarter", "top", "side", "front", "bottom"]
SLOTS = {"body": (60, 100, 175), "nose": (195, 80, 65),
         "wings": (45, 140, 100), "tail": (140, 75, 165),
         "boost": (215, 150, 40)}
# Blender Z-up to the prototype's right/up/nose-minus-Z frame.
B2R = np.array(((1., 0, 0), (0, 0, 1.), (0, -1., 0)))
R2B = B2R.T
RY180 = np.diag((-1., 1., -1.))
NEW_FILES = set()
INITIAL_FILES = set()
IMAGE_CACHE = {}
RESUME_RENDERS = False
BUILD_STATE = {}


def log(message):
    print("SKIN_SHEET " + str(message), flush=True)


def check(condition, message):
    if not condition:
        raise RuntimeError(message)


def relative(path):
    return Path(path).relative_to(ROOT).as_posix()


def destination(path):
    path = Path(path).resolve()
    check(path.is_relative_to(OUT) or path.is_relative_to(REVIEW),
          "Output escaped the two authorized directories: " + str(path))
    check(path not in INITIAL_FILES or path in NEW_FILES,
          "Refusing to overwrite a pre-existing file: " + str(path))
    path.parent.mkdir(parents=True, exist_ok=True)
    NEW_FILES.add(path)
    return str(path)


def write_json(path, data):
    def numpy_value(value):
        if isinstance(value, np.generic):
            return value.item()
        if isinstance(value, np.ndarray):
            return value.tolist()
        raise TypeError("Unsupported JSON value: " + type(value).__name__)
    Path(destination(path)).write_text(json.dumps(data, indent=2, default=numpy_value) + "\n", encoding="utf-8")


def checkpoint():
    BUILD_STATE["generated_files"] = sorted(relative(path) for path in NEW_FILES | {(OUT/"manifest.json").resolve()})
    write_json(OUT/"manifest.json", BUILD_STATE)


def png(path, values):
    """Exact bytes, rows top to bottom; no display transform on normal data."""
    values = np.ascontiguousarray(values, dtype=np.uint8)
    h, w, channels = values.shape
    check(channels in (3, 4), "PNG channels")

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))

    rows = b"".join(b"\0" + row.tobytes() for row in values)
    Path(destination(path)).write_bytes(b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2 if channels == 3 else 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))


def image_pixels(path, noncolor=True):
    image = bpy.data.images.load(str(path), check_existing=False)
    image.colorspace_settings.name = "Non-Color" if noncolor else "sRGB"
    values = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
    image.pixels.foreach_get(values)
    values = values.reshape(image.size[1], image.size[0], 4).copy()
    bpy.data.images.remove(image)
    return values


def import_mesh(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path), global_scale=100, use_custom_normals=True)
    added = set(bpy.data.objects) - before
    meshes = [o for o in added if o.type == "MESH"]
    check(len(meshes) == 1, str(path) + ": expected one mesh")
    obj = meshes[0]
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    for other in added - {obj}:
        bpy.data.objects.remove(other, do_unlink=True)
    obj.data.update()
    obj.data.calc_loop_triangles()
    return obj


def positions(mesh):
    return np.array([v.co[:] for v in mesh.vertices], dtype=np.float64)


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def inventory():
    tree = ET.parse(BASE / "pieces.rbxmx")
    folder = next(item for item in tree.getroot().findall("Item")
                  if item.findtext("Properties/string[@name='Name']") == "AircraftPieces")
    uploads = {name: json.loads((BASE / name / "uploads.json").read_text())
               for name in ("paper-set", "paper-sample")}
    records = []
    for model in folder.findall("Item"):
        part = model.findtext("Properties/string[@name='Name']", "")
        if model.get("class") != "Model" or not part.startswith(("body_", "nose_", "wings_", "tail_", "boost_")):
            continue
        for item in model.findall("Item"):
            if item.get("class") != "MeshPart":
                continue
            props = item.find("Properties")
            name = props.findtext("string[@name='Name']")
            size = props.find("Vector3[@name='size']")
            cf = props.find("CoordinateFrame[@name='CFrame']")
            size = np.array([float(size.findtext(axis)) for axis in ("X", "Y", "Z")])
            centre = np.array([float(cf.findtext(axis)) for axis in ("X", "Y", "Z")])
            rotation = np.array([[float(cf.findtext("R%d%d" % (i, j))) for j in range(3)] for i in range(3)])
            mesh_id = props.findtext("Content[@name='MeshId']/url", "")
            source_dir = "paper-sample" if part in STARTERS else "paper-set"
            source_name = name
            if "-sticker-" in name:
                source_dir = "paper-sample"
                source_name = "wings-sticker-" + name.rsplit("-", 1)[-1]
            path = BASE / source_dir / (source_name + ".fbx")
            expected = str(uploads[source_dir].get(name, {}).get("mesh", "MISSING"))
            records.append(dict(part=part, slot=part.split("_")[0], name=name,
                centre=centre, size=size, rotation=rotation, source=path, mesh_id=mesh_id,
                source_name=source_name,
                upload_mesh_id=expected, mesh_id_match=mesh_id.split("//")[-1] == expected,
                scope=any(tag in name for tag in ("-paper-", "-cardboard-", "-tube-", "-accent"))))
    records.sort(key=lambda r: (r["part"], r["name"]))
    check(sum(r["scope"] for r in records) == 98, "Scope must be exactly 98 pieces")
    check(len({r["name"] for r in records if r["scope"]}) == 98, "Duplicate output piece names")
    for r in records:
        check(r["source"].is_file(), "Missing FBX: " + str(r["source"]))
        for kind in ("color", "normal", "roughness"):
            check(r["source"].with_name(r["source_name"] + "-" + kind + ".png").is_file(),
                  "Missing source map: " + r["name"] + "/" + kind)
        check(np.max(np.abs(r["rotation"] - RY180)) < 1e-6,
              "Unexpected MeshPart rotation: " + r["name"])
    return records


def detect_import_basis():
    """Calibrate the FBX forward basis against the nose's tapered end.

    Roblox's imported local forward basis and the prototype's Blender conversion
    differ by Y180. Apply that correction before the XML CFrame, not after it.
    This keeps the actual narrow end at plane -Z while honoring the XML rotation.
    """
    obj = import_mesh(BASE / "paper-set/nose_1-paper-L.fbx")
    raw = positions(obj.data) @ B2R.T
    lo, hi = raw[:, 2].min(), raw[:, 2].max()
    front = raw[raw[:, 2] < lo + .15 * (hi - lo)]
    back = raw[raw[:, 2] > hi - .15 * (hi - lo)]
    widths = [float(np.ptp(p[:, 1])) for p in (front, back)]
    check(abs(widths[0] - widths[1]) > 1e-6, "Cannot detect tapered nose end")
    # The shape in prototype coordinates already narrows toward -Z unless flipped.
    prototype_flip = widths[0] > widths[1]
    correction = np.eye(3) if prototype_flip else RY180.copy()
    bpy.data.objects.remove(obj, do_unlink=True)
    return correction, dict(nose_y_spread_at_raw_minus_z=widths[0],
                           nose_y_spread_at_raw_plus_z=widths[1],
                           prototype_flip=prototype_flip,
                           blender_to_roblox_import_correction=correction.tolist())


def assembled_positions(obj, record, correction):
    raw = positions(obj.data) @ B2R.T
    lo, hi = raw.min(0), raw.max(0)
    check(np.all(hi - lo > 1e-9), "Zero source bounds: " + record["name"])
    local = (raw - (lo + hi) / 2) @ correction.T
    # Rotation is applied after local per-axis box scaling, exactly like MeshPart.
    return (local * (record["size"] / (hi - lo))) @ record["rotation"].T + record["centre"]


def make_layout(records):
    corners = []
    for r in records:
        if r["scope"]:
            box = np.array(list(itertools.product((-1., 1.), repeat=3))) * r["size"] / 2
            corners.extend(box @ r["rotation"].T + r["centre"])
    bounds = np.array((np.min(corners, axis=0) - PAD, np.max(corners, axis=0) + PAD))
    dx, dy, dz = bounds[1] - bounds[0]
    k = min((N - 2 * MARGIN - GAP) / (dx + dy),
            (N - 2 * MARGIN - GAP) / (dz + dy))
    rectangles = {"TOP": [MARGIN, MARGIN, dx * k, dz * k],
                  "SIDE": [2 * MARGIN + dx * k, MARGIN, dy * k, dz * k],
                  "FRONT": [MARGIN, 2 * MARGIN + dz * k, dx * k, dy * k]}
    for x, y, w, h in rectangles.values():
        check(x >= MARGIN and y >= MARGIN and x + w <= N - MARGIN + 1e-8
              and y + h <= N - MARGIN + 1e-8, "Layout overflow")
    for first, second in itertools.combinations(rectangles.values(), 2):
        ax,ay,aw,ah = first
        bx,by,bw,bh = second
        check(ax+aw <= bx or bx+bw <= ax or ay+ah <= by or by+bh <= ay, "Overlapping sheet regions")
    check(rectangles["TOP"][1] == rectangles["SIDE"][1]
          and rectangles["TOP"][3] == rectangles["SIDE"][3], "Nose/tail rows differ")
    check(rectangles["TOP"][0] == rectangles["FRONT"][0]
          and rectangles["TOP"][2] == rectangles["FRONT"][2], "Top/front X columns differ")
    check((k+1e-6)*(dx+dy)+2*MARGIN+GAP > N
          or (k+1e-6)*(dz+dy)+2*MARGIN+GAP > N, "Common scale is not maximal")
    return dict(resolution=[N, N], k=k, padding_studs=PAD,
                margin_pixels=MARGIN, gap_pixels=GAP,
                bounds=dict(min=bounds[0].tolist(), max=bounds[1].tolist()),
                pixel_origin="top-left; x right, y down; rectangles are [x,y,width,height]",
                regions={name: dict(rect_pixels=rect) for name, rect in rectangles.items()},
                axes="Roblox plane frame: x right, y up, nose -z",
                uv_origin="bottom-left; u=px/1024, v=1-py/1024",
                selection="dominant absolute triangle geometric normal after placement; tie order Y,X,Z",
                formulas={"TOP": "px=16+k*(x-xmin); py=16+k*(z-zmin)",
                          "SIDE": "px=32+k*(xmax-xmin)+k*(y-ymin); py=16+k*(z-zmin)",
                          "FRONT": "px=16+k*(x-xmin); py=32+k*(zmax-zmin)+k*(ymax-y)"},
                normal_convention="MikkTSpace, OpenGL +Y", checks=dict(fits=True, regions_disjoint=True))


def project(points, region, layout):
    lo, hi = np.array(layout["bounds"]["min"]), np.array(layout["bounds"]["max"])
    x, y, w, h = layout["regions"][region]["rect_pixels"]
    k = layout["k"]
    if region == "TOP":
        px, py = x + k * (points[:, 0] - lo[0]), y + k * (points[:, 2] - lo[2])
    elif region == "SIDE":
        px, py = x + k * (points[:, 1] - lo[1]), y + k * (points[:, 2] - lo[2])
    else:
        px, py = x + k * (points[:, 0] - lo[0]), y + k * (hi[1] - points[:, 1])
    return np.column_stack((px / N, 1 - py / N))


def tangent_data(mesh, uv_name):
    mesh.calc_tangents(uvmap=uv_name)
    return (np.array([loop.tangent[:] for loop in mesh.loops]),
            np.array([loop.bitangent_sign for loop in mesh.loops]),
            np.array([normal.vector[:] for normal in mesh.corner_normals]))


def assign_uv(obj, record, correction, layout):
    mesh = obj.data
    check(len(mesh.uv_layers) == 1, record["name"] + ": expected one source UV")
    record["old_uv_name"] = mesh.uv_layers[0].name
    record["old_uv"] = np.array([loop.uv[:] for loop in mesh.uv_layers[0].data])
    record["old_tbn"] = tangent_data(mesh, record["old_uv_name"])
    world = assembled_positions(obj, record, correction)
    uv = mesh.uv_layers.new(name="SheetUV")
    mesh.uv_layers.active = uv
    uv.active_render = True
    regions, facing, normals = [], [], []
    # Source files are triangulated. Do not retriangulate or change shading flags.
    check(all(len(p.vertices) == 3 for p in mesh.polygons), record["name"] + ": non-triangle source")
    for poly in mesh.polygons:
        xyz = world[list(poly.vertices)]
        n = np.cross(xyz[1] - xyz[0], xyz[2] - xyz[0])
        check(np.linalg.norm(n) > 1e-12, record["name"] + ": degenerate source face")
        n /= np.linalg.norm(n)
        axis = (1, 0, 2)[int(np.argmax(np.abs(n[[1, 0, 2]])))]
        region = {1: "TOP", 0: "SIDE", 2: "FRONT"}[axis]
        face = n[1] > 0 if region == "TOP" else (n[2] < 0 if region == "FRONT" else n[0] * xyz[:, 0].mean() > 0)
        for li in poly.loop_indices:
            point = world[mesh.loops[li].vertex_index][None, :]
            uv.data[li].uv = project(point, region, layout)[0]
        regions.append(region)
        facing.append(bool(face))
        normals.append(n)
    record["plane_positions"] = world
    record["face_regions"] = regions
    record["face_facing"] = np.array(facing)
    record["plane_normals"] = np.array(normals)
    record["new_uv"] = np.array([loop.uv[:] for loop in uv.data])
    record["new_tbn"] = tangent_data(mesh, "SheetUV")
    check(np.isfinite(record["new_uv"]).all() and record["new_uv"].min() >= 0
          and record["new_uv"].max() <= 1, record["name"] + ": invalid UV bounds")


def raster_triangle(uv):
    a, b, c = uv * N - .5
    den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(den) <= 1e-12:
        # Retain source needle faces. Their exact projection may collapse at
        # Blender's float32 UV precision; inflating it would violate the formula.
        return np.empty(0,dtype=int), np.empty(0,dtype=int), np.empty((0,3)), 0.
    lo = np.maximum(np.floor(np.min((a, b, c), axis=0)).astype(int), 0)
    hi = np.minimum(np.ceil(np.max((a, b, c), axis=0)).astype(int) + 1, N)
    yy, xx = np.mgrid[lo[1]:hi[1], lo[0]:hi[0]]
    wa = ((b[1] - c[1]) * (xx - c[0]) + (c[0] - b[0]) * (yy - c[1])) / den
    wb = ((c[1] - a[1]) * (xx - c[0]) + (a[0] - c[0]) * (yy - c[1])) / den
    wc = 1 - wa - wb
    hit = (wa >= -1e-8) & (wb >= -1e-8) & (wc >= -1e-8)
    return yy[hit], xx[hit], np.column_stack((wa[hit], wb[hit], wc[hit])), abs(den) / 2


def normalize(values):
    lengths = np.linalg.norm(values, axis=-1, keepdims=True)
    check(np.all(lengths > 1e-12), "Zero normal or tangent frame")
    return values / lengths


def bilinear(image, uv):
    h, w = image.shape[:2]
    xy = uv * (w, h) - .5
    first = np.floor(xy).astype(int)
    frac = xy - first
    x0, y0 = first[:, 0] % w, first[:, 1] % h
    x1, y1 = (x0 + 1) % w, (y0 + 1) % h
    fx, fy = frac[:, 0, None], frac[:, 1, None]
    return ((1-fy) * ((1-fx) * image[y0, x0, :3] + fx * image[y0, x1, :3])
            + fy * ((1-fx) * image[y1, x0, :3] + fx * image[y1, x1, :3]))


def interpolated_frame(tbn, loops, weights):
    """Match Mikk's pixel-reconstructed bitangent, including mirrored signs.

    Keep interpolated attributes unnormalized. The inverse below uses the same
    basis as the forward shader, rather than assuming an orthonormal matrix.
    """
    tangents, signs, normals = tbn
    t = weights @ tangents[loops]
    n = weights @ normals[loops]
    sign = np.where(weights @ signs[loops] < 0, -1., 1.)
    b = np.cross(n, t) * sign[:, None]
    return np.stack((t, b, n), axis=2)


def transport(record, loops, weights, normal_image):
    old_uv = weights @ record["old_uv"][loops]
    old_normal = normalize(bilinear(normal_image, old_uv) * 2 - 1)
    old_basis = interpolated_frame(record["old_tbn"], loops, weights)
    new_basis = interpolated_frame(record["new_tbn"], loops, weights)
    object_normal = normalize(np.einsum("nij,nj->ni", old_basis, old_normal))
    # Invert the actual interpolated Mikk basis. A transpose alone is incorrect
    # when its interpolated axes aren't unit length or mutually perpendicular.
    converted = normalize(np.linalg.solve(new_basis, object_normal[..., None])[..., 0])
    reconstructed = normalize(np.einsum("nij,nj->ni", new_basis, converted))
    error = np.max(np.linalg.norm(object_normal - reconstructed, axis=1)) if len(weights) else 0
    check(error < 1e-8, record["name"] + ": object-space transport failed")
    return converted, object_normal, new_basis, float(error)


def dilate_region(values, covered, region, layout, written):
    """Nearest-source extension for an 8px Euclidean radius, empty stays flat."""
    x, y, w, h = layout["regions"][region]["rect_pixels"]
    # Bake arrays have bottom-left origin. Region gaps provide independent gutters.
    x0, x1 = max(0, int(math.floor(x))-8), min(N, int(math.ceil(x+w))+8)
    y0, y1 = max(0, int(math.floor(N-y-h))-8), min(N, int(math.ceil(N-y))+8)
    mask = covered[y0:y1, x0:x1]
    if not mask.any():
        return 0
    yy, xx = np.indices(mask.shape)
    ox = np.where(mask, xx, -10000).astype(np.int32)
    oy = np.where(mask, yy, -10000).astype(np.int32)
    dist = np.where(mask, 0., 1e20)
    for iteration in range(8):
        oldx, oldy = ox.copy(), oy.copy()
        for dy, dx in itertools.product((-1, 0, 1), repeat=2):
            if not (dy or dx):
                continue
            cx, cy = np.roll(oldx, (dy, dx), (0, 1)), np.roll(oldy, (dy, dx), (0, 1))
            candidate = (cx - xx)**2 + (cy - yy)**2
            good = (candidate < dist) & (candidate <= 64) & (cx >= 0) & (cy >= 0)
            if dy > 0: good[:dy] = False
            if dy < 0: good[dy:] = False
            if dx > 0: good[:, :dx] = False
            if dx < 0: good[:, dx:] = False
            ox[good], oy[good], dist[good] = cx[good], cy[good], candidate[good]
    fill = (~mask) & (dist <= 64)
    fill &= ~written[y0:y1, x0:x1]
    target = values[y0:y1, x0:x1]
    target[fill] = target[oy[fill], ox[fill]]
    written[y0:y1, x0:x1] |= fill
    return int(fill.sum())


def bake_normal(obj, record, layout):
    normal_image = image_pixels(record["source"].with_name(record["source_name"] + "-normal.png"))
    values = np.zeros((N, N, 3), dtype=np.float64)
    values[:] = (.5, .5, 1.)
    owner = np.full((N, N), -1, dtype=np.int32)
    priority = np.full((N, N), -1, dtype=np.int8)
    depth = np.full((N, N), -1e30)
    facing_coverage = np.zeros((N, N), dtype=bool)
    regions_coverage = {name: np.zeros((N, N), dtype=bool) for name in ("TOP", "SIDE", "FRONT")}
    samples, subpixel, collapsed, max_error, max_angle = 0, 0, 0, 0., 0.
    triangle_samples = {}
    mesh = obj.data
    for tri in mesh.loop_triangles:
        loops = np.array(tri.loops)
        yy, xx, weights, area = raster_triangle(record["new_uv"][loops])
        subpixel += int(len(yy) == 0)
        collapsed += int(area == 0)
        triangle_samples[str(tri.index)] = len(yy)
        if not len(yy):
            continue
        region = record["face_regions"][tri.polygon_index]
        face = int(record["face_facing"][tri.polygon_index])
        regions_coverage[region][yy, xx] = True
        if face:
            facing_coverage[yy, xx] = True
        world = weights @ record["plane_positions"][list(tri.vertices)]
        # Closest visible surface resolves same-facing folds and nested panels.
        d = world[:, 1] if region == "TOP" else (-world[:, 2] if region == "FRONT" else np.abs(world[:, 0]))
        choose = (face > priority[yy, xx]) | ((face == priority[yy, xx]) & (d > depth[yy, xx] + 1e-10))
        yy, xx, weights, d = yy[choose], xx[choose], weights[choose], d[choose]
        if not len(yy):
            continue
        converted, reference, basis, error = transport(record, loops, weights, normal_image)
        quantized = np.rint(np.clip(converted * .5 + .5, 0, 1) * 255) / 127.5 - 1
        decoded = normalize(np.einsum("nij,nj->ni", basis, quantized))
        angle = np.degrees(np.arccos(np.clip(np.sum(decoded * reference, axis=1), -1, 1)))
        max_angle = max(max_angle, float(angle.max()))
        check(angle.max() < 1., record["name"] + ": quantized normal transport exceeds one degree")
        values[yy, xx] = converted * .5 + .5
        owner[yy, xx], priority[yy, xx], depth[yy, xx] = tri.index, face, d
        samples += len(yy)
        max_error = max(max_error, error)
    covered = owner >= 0
    check(covered.any(), record["name"] + ": no normal-map coverage")
    # Verify priority independently, across all pixel candidates, after resolving.
    check(np.all(priority[facing_coverage] == 1), record["name"] + ": opposite face overwrote facing face")
    fallback = int(((priority == 0) & covered).sum())
    written = covered.copy()
    padding = sum(dilate_region(values, regions_coverage[name], name, layout, written)
                  for name in ("TOP", "SIDE", "FRONT"))
    bytes_out = np.rint(np.clip(values, 0, 1) * 255).astype(np.uint8)
    path = OUT / (record["name"] + "-normal.png")
    png(path, bytes_out[::-1])
    saved = image_pixels(path)
    expected = bytes_out.astype(float) / 255
    check(saved.shape == (N, N, 4) and np.max(np.abs(saved[:, :, :3] - expected)) < 1e-6,
          record["name"] + ": saved PNG bytes or dimensions")
    length_error = float(np.abs(np.linalg.norm(saved[covered, :3] * 2 - 1, axis=1) - 1).max())
    check(length_error < .014, record["name"] + ": saved normal not unit length")
    flat = np.array((128, 128, 255)) / 255
    unchanged_background = np.all(bytes_out == (128, 128, 255), axis=2)
    check(np.all(unchanged_background[~written]) and np.max(np.abs(saved[0, 0, :3] - flat)) < 1e-6,
          record["name"] + ": empty background not flat")
    return dict(result="PASS", method="NumPy raster bake, Blender MikkTSpace loop tangents; old UV -> object -> SheetUV",
        resolution=[N, N], old_map=relative(record["source"].with_name(record["source_name"] + "-normal.png")),
        covered_texels=int(covered.sum()), facing_texels=int((priority == 1).sum()),
        opposite_only_texels=fallback, facing_priority_checked=True,
        dilation_pixels=8, dilation_metric="Euclidean", dilated_texels=padding,
        empty_rgb=[128, 128, 255], saved_bytes_checked=True,
        all_empty_background_texels_checked=True, empty_background_texels=int((~written).sum()),
        unit_length_error_max=length_error, transport_object_space_error_max=max_error,
        quantized_transport_angle_degrees_max=max_angle, subpixel_triangles_without_pixel_centres=subpixel,
        projected_triangles_below_uv_float_precision=collapsed,
        limitation="Opposing surfaces share one normal texel; priority surface wins. Subpixel faces receive neighboring gutter samples.")


def canonical_geometry(mesh):
    coords = positions(mesh)
    mesh.calc_loop_triangles()
    normals = np.array([n.vector[:] for n in mesh.corner_normals])
    triangles, corners = [], []
    for tri in mesh.loop_triangles:
        xyz = coords[list(tri.vertices)]
        order = np.lexsort(tuple(np.round(xyz[:, i], 5) for i in (2, 1, 0)))
        triangles.append(xyz[order].reshape(-1))
        for vi, li in zip(tri.vertices, tri.loops):
            corners.append(np.concatenate((coords[vi], normals[li])))

    def sorted_rows(rows, places=5):
        rows = np.array(rows)
        return rows[np.lexsort(tuple(np.round(rows[:, i], places) for i in range(rows.shape[1]-1, -1, -1))) ]

    return sorted_rows(coords), sorted_rows(triangles), sorted_rows(corners)


def raw_fbx(path):
    tree, version = parse_fbx.parse(str(path))
    objects = next(e for e in tree.elems if e.id == b"Objects")
    geometry = next(e for e in objects.elems if e.id == b"Geometry")
    vertices = np.array(next(e.props[0] for e in geometry.elems if e.id == b"Vertices")).reshape(-1, 3)
    settings = next(e for e in tree.elems if e.id == b"GlobalSettings")
    props = next(e for e in settings.elems if e.id == b"Properties70")
    unit = next(e.props[-1] for e in props.elems if e.props[0] == b"UnitScaleFactor")
    return vertices, unit


def fbx_preserved_record_hash(path):
    """Fingerprint all geometry except UV, and the complete axis/unit block."""
    tree, version = parse_fbx.parse(str(path))
    geometry = next(e for e in next(e for e in tree.elems if e.id == b"Objects").elems if e.id == b"Geometry")
    settings = next(e for e in tree.elems if e.id == b"GlobalSettings")
    digest = hashlib.sha256()
    def visit(node):
        digest.update(node.id)
        digest.update(node.props_type)
        for value in node.props:
            if isinstance(value, bytes):
                digest.update(value)
            elif isinstance(value, (np.ndarray,)) or hasattr(value, "tobytes"):
                digest.update(value.tobytes())
            else:
                digest.update(repr(value).encode("ascii"))
        for child in node.elems:
            if child.id != b"LayerElementUV":
                visit(child)
    visit(geometry)
    visit(settings)
    return digest.hexdigest()


def multiset_error(source, target, tolerance, triangles=False):
    """Match multiplicities without unstable float-rounded sorting at ties."""
    available = np.ones(len(target), dtype=bool)
    max_error = 0.
    if triangles:
        permutations = np.array(list(itertools.permutations(range(3))))
        target_permuted = target.reshape(-1,3,3)[:,permutations,:]
    for row in source:
        if triangles:
            error = np.max(np.abs(target_permuted-row.reshape(1,1,3,3)), axis=(2,3)).min(axis=1)
        else:
            error = np.max(np.abs(target-row), axis=1)
        error[~available] = np.inf
        index = int(error.argmin())
        if error[index] >= tolerance:
            log("unmatched source="+str(row.tolist())+" target="+str(target[index].tolist()))
        check(error[index] < tolerance, "Roundtrip has an unmatched geometry/normal row: " + str(float(error[index])))
        max_error = max(max_error, float(error[index]))
        available[index] = False
    check(not available.any(), "Roundtrip multiset multiplicity changed")
    return max_error


def export_and_check(obj, record):
    path = OUT / (record["name"] + ".fbx")
    # Re-encoding ONLY the source UV element preserves exact raw vertex numbers,
    # triangle indices, smoothing and normal records, units and axis settings.
    # An ordinary Blender geometry export rounds some needle faces enough to
    # rotate their flat normals. A custom-normal workaround also quantizes them.
    # Blender's bundled FBX reader/writer avoids both losses without changing any
    # source file. The source already carries the required paper-set contract.
    tree, version = parse_fbx.parse(str(record["source"]))
    objects = next(e for e in tree.elems if e.id == b"Objects")
    geometry = next(e for e in objects.elems if e.id == b"Geometry")
    layers = [e for e in geometry.elems if e.id == b"LayerElementUV"]
    check(len(layers) == 1, record["name"] + ": expected one raw FBX UV element")
    layer = layers[0]
    element = {e.id: e for e in layer.elems}
    check(element[b"MappingInformationType"].props[0] == b"ByPolygonVertex", "Unexpected raw UV mapping")
    raw_uv = np.array(element[b"UV"].props[0]).reshape(-1,2)
    if element[b"ReferenceInformationType"].props[0] == b"IndexToDirect":
        raw_uv = raw_uv[np.array(element[b"UVIndex"].props[0])]
    check(raw_uv.shape == record["old_uv"].shape and np.max(np.abs(raw_uv-record["old_uv"])) < 1e-6,
          record["name"] + ": source raw/imported UV loop order differs")
    element[b"Name"].props[0] = b"SheetUV"
    element[b"ReferenceInformationType"].props[0] = b"IndexToDirect"
    element[b"UV"].props[0] = record["new_uv"].astype(np.float64).ravel()
    element[b"UVIndex"].props[0] = np.arange(len(record["new_uv"]), dtype=np.int32)
    methods = {"B":"bool", "C":"char", "Z":"int8", "Y":"int16", "I":"int32", "L":"int64",
               "F":"float32", "D":"float64", "R":"bytes", "S":"string",
               "i":"int32_array", "l":"int64_array", "f":"float32_array", "d":"float64_array",
               "b":"bool_array", "c":"byte_array"}

    def encoded(node):
        result = encode_bin.FBXElem(node.id)
        for kind, value in zip(node.props_type, node.props):
            getattr(result, "add_"+methods[chr(kind)])(value)
        result.elems = [encoded(child) for child in node.elems]
        return result

    encode_bin.write(destination(path), encoded(tree), version)
    check(fbx_preserved_record_hash(record["source"]) == fbx_preserved_record_hash(path),
          record["name"]+": raw geometry, shading or axis/unit records changed")
    imported = import_mesh(path)
    src = canonical_geometry(obj.data)
    dst = canonical_geometry(imported.data)
    check(all(a.shape == b.shape for a, b in zip(src, dst)), record["name"] + ": changed vertex/triangle/corner count")
    errors = [multiset_error(src[0], dst[0], TOL), multiset_error(src[1], dst[1], TOL, triangles=True),
              multiset_error(src[2], dst[2], 1e-5)]
    check(max(errors[:2]) < TOL, record["name"] + ": changed geometry")
    check(errors[2] < 1e-5, record["name"] + ": changed shading normals")
    before, after = positions(obj.data), positions(imported.data)
    bbox_error = float(np.max(np.abs(np.array((before.min(0), before.max(0))) - np.array((after.min(0), after.max(0))))))
    check(bbox_error < TOL, record["name"] + ": changed bounds")
    raw_before, source_unit = raw_fbx(record["source"])
    raw_after, unit = raw_fbx(path)
    raw_error = float(np.max(np.abs(np.array((raw_before.min(0), raw_before.max(0))) - np.array((raw_after.min(0), raw_after.max(0))))))
    check(unit == 1 and raw_error < TOL, record["name"] + ": raw stud coordinates / units")
    check(len(imported.data.loop_triangles) == len(obj.data.loop_triangles), record["name"] + ": triangle count")
    check(len(imported.data.uv_layers) == 1 and imported.data.uv_layers[0].name == "SheetUV", record["name"] + ": UV layers")
    uv = np.array([loop.uv[:] for loop in imported.data.uv_layers[0].data])
    check(np.isfinite(uv).all() and uv.min() >= 0 and uv.max() <= 1, record["name"] + ": roundtrip UV bounds")
    formula_error = float(np.max(np.abs(uv-record["new_uv"])))
    check(formula_error < 1e-6, record["name"]+": exported UVs differ from the sheet formulas")
    uv_areas = [raster_triangle(uv[list(tri.loops)])[3] for tri in imported.data.loop_triangles]
    uv_area_min = min(uv_areas)
    record["new"] = imported
    imported.hide_render = True
    imported.hide_set(True)
    return dict(result="PASS", bounds_error_max_studs=bbox_error, raw_fbx_bounds_error_max_studs=raw_error,
        vertex_position_error_max_studs=errors[0], triangle_position_error_max_studs=errors[1],
        corner_position_and_shading_normal_error_max=errors[2], same_vertex_count=True,
        same_triangle_count=True, same_shading_normals=True, unit_scale_factor=unit,
        raw_geometry_normals_axes_units_records_identical=True, coordinate_formula_uv_error_max=formula_error,
        export_method="Source FBX re-encoded by Blender FBX writer with ONLY its UV element replaced; raw geometry/normal records retained",
        exactly_one_uv_layer=True, uv_layer="SheetUV", uv_min=float(uv.min()), uv_max=float(uv.max()),
        all_uv_in_0_1=True, minimum_projected_triangle_area_pixels=uv_area_min,
        projected_triangles_below_uv_float_precision=int(sum(area == 0 for area in uv_areas)),
        tolerance_studs=TOL, overlap_policy="Shared projected texels intentional within a region; regions disjoint.")


# Small deterministic bitmap lettering avoids external fonts and Python packages.
FONT_ROWS = {
    "A":"01110/10001/10001/11111/10001/10001/10001", "B":"11110/10001/10001/11110/10001/10001/11110",
    "C":"01111/10000/10000/10000/10000/10000/01111", "D":"11110/10001/10001/10001/10001/10001/11110",
    "E":"11111/10000/10000/11110/10000/10000/11111", "F":"11111/10000/10000/11110/10000/10000/10000",
    "G":"01111/10000/10000/10111/10001/10001/01111", "H":"10001/10001/10001/11111/10001/10001/10001",
    "I":"11111/00100/00100/00100/00100/00100/11111", "J":"00111/00010/00010/00010/00010/10010/01100",
    "K":"10001/10010/10100/11000/10100/10010/10001", "L":"10000/10000/10000/10000/10000/10000/11111",
    "M":"10001/11011/10101/10101/10001/10001/10001", "N":"10001/11001/10101/10011/10001/10001/10001",
    "O":"01110/10001/10001/10001/10001/10001/01110", "P":"11110/10001/10001/11110/10000/10000/10000",
    "Q":"01110/10001/10001/10001/10101/10010/01101", "R":"11110/10001/10001/11110/10100/10010/10001",
    "S":"01111/10000/10000/01110/00001/00001/11110", "T":"11111/00100/00100/00100/00100/00100/00100",
    "U":"10001/10001/10001/10001/10001/10001/01110", "V":"10001/10001/10001/10001/10001/01010/00100",
    "W":"10001/10001/10001/10101/10101/10101/01010", "X":"10001/10001/01010/00100/01010/10001/10001",
    "Y":"10001/10001/01010/00100/00100/00100/00100", "Z":"11111/00001/00010/00100/01000/10000/11111",
    "-":"00000/00000/00000/11111/00000/00000/00000", ">":"10000/01000/00100/00010/00100/01000/10000",
    "/":"00001/00010/00010/00100/01000/01000/10000", " ":"00000/00000/00000/00000/00000/00000/00000"}


def text(image, label, x, y, scale=1, colour=(30, 32, 36), backing=False):
    label = label.upper()
    width, height = max(1, len(label)*6-1)*scale, 7*scale
    check(x >= 0 and y >= 0 and x+width < image.shape[1] and y+height < image.shape[0], "Label does not fit: " + label)
    if backing:
        image[max(0, y-4):y+height+4, max(0, x-4):x+width+4] = (250, 250, 248)
    for index, letter in enumerate(label):
        check(letter in FONT_ROWS, "Missing bitmap letter: " + letter)
        bitmap = np.array([[int(c) for c in row] for row in FONT_ROWS[letter].split("/")], dtype=bool)
        bitmap = np.repeat(np.repeat(bitmap, scale, axis=0), scale, axis=1)
        patch = image[y:y+height, x+index*6*scale:x+index*6*scale+5*scale]
        patch[bitmap] = colour


def line(image, start, end, colour):
    delta = np.array(end) - np.array(start)
    steps = max(1, int(np.max(np.abs(delta))) + 1)
    points = np.rint(np.array(start) + np.linspace(0, 1, steps)[:, None]*delta).astype(int)
    points[:, 0] = np.clip(points[:, 0], 0, image.shape[1]-1)
    points[:, 1] = np.clip(points[:, 1], 0, image.shape[0]-1)
    image[points[:, 1], points[:, 0]] = colour


def make_template(records, layout):
    image = np.full((N, N, 3), 255, dtype=np.uint8)
    for record in records:
        if not record["scope"]:
            continue
        uv = record["new_uv"].copy() * (N, -N) + (0, N)
        for face in record["old"].data.polygons:
            points = uv[list(face.loop_indices)]
            for a, b in zip(points, np.roll(points, -1, axis=0)):
                line(image, a, b, SLOTS[record["slot"]])
    for name, data in layout["regions"].items():
        x, y, w, h = data["rect_pixels"]
        box = [(x,y), (x+w,y), (x+w,y+h), (x,y+h)]
        for a, b in zip(box, box[1:]+box[:1]):
            line(image, a, b, (45, 48, 52))
        text(image, name, int(x)+5, int(y)+2, backing=True)
        if name != "FRONT":
            # The literal NOSE -> rotated counterclockwise points up the sheet.
            label = np.full((11, 48, 3), 255, dtype=np.uint8)
            text(label, "NOSE ->", 2, 2)
            label = np.rot90(label)
            lx, ly = int(x+w)-label.shape[1]-3, int(y)+4
            image[ly:ly+label.shape[0], lx:lx+label.shape[1]] = label
    # Legend goes in the unused bottom-right, away from projected outlines.
    x = int(layout["regions"]["SIDE"]["rect_pixels"][0])+6
    y = int(layout["regions"]["FRONT"]["rect_pixels"][1])+12
    for index, (slot, colour) in enumerate(SLOTS.items()):
        text(image, slot, x, y+index*20, scale=2, colour=colour)
    png(OUT / "sheet-template.png", image)


def make_skins(layout):
    yy, xx = np.mgrid[:N, :N]
    phase = (xx+.5 + yy+.5) / (layout["k"] * math.sqrt(2))
    hazard = np.where(((np.floor(phase/1.2).astype(int) % 2) == 0)[..., None],
                      np.array((250, 200, 30)), np.array((20, 21, 23))).astype(np.uint8)
    png(REVIEW / "test-skin-hazard.png", hazard)
    a, b = (xx+.5) / layout["k"], (yy+.5) / layout["k"]
    a = a + .19*np.sin(b*1.31) + .07*np.sin(b*4.73+a*.62)
    b = b + .17*np.sin(a*1.73) + .06*np.cos(a*4.13-b*.71)
    rng = np.random.default_rng(60113)
    first, second = np.full((N,N), 1e9), np.full((N,N), 1e9)
    for seed in rng.uniform(-2, N/layout["k"]+2, (85, 2)):
        distance = (a-seed[0])**2 + (b-seed[1])**2
        second = np.minimum(second, np.maximum(first, distance))
        first = np.minimum(first, distance)
    crack = np.sqrt(second) - np.sqrt(first)
    rock = np.array((45., 35., 35.))[None,None,:] + (3*np.sin(a*14+b*9)+2*np.sin(a*33-b*19))[...,None]
    glow = np.exp(-crack/.085)[...,None]
    hot = np.exp(-crack/.018)[...,None]
    lava = rock*(1-glow) + np.array((248, 82, 12))*glow
    lava = lava*(1-hot) + np.array((255, 222, 75))*hot
    png(REVIEW / "test-skin-lava.png", np.clip(lava, 0, 255).astype(np.uint8))


def linear(rgb):
    c = np.array(rgb, dtype=float)/255
    return np.where(c <= .04045, c/12.92, ((c+.055)/1.055)**2.4)


def load_texture(path, noncolor):
    key = (str(path), noncolor)
    if key not in IMAGE_CACHE:
        image = bpy.data.images.load(str(path), check_existing=False)
        image.colorspace_settings.name = "Non-Color" if noncolor else "sRGB"
        IMAGE_CACHE[key] = image
    return IMAGE_CACHE[key]


def make_material(record, mode):
    mat = bpy.data.materials.new(record["name"] + "/" + mode)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    scope = record["scope"]
    fresh = scope and mode in ("crease", "hazard", "lava")
    grey = scope and mode in ("creaseold", "crease")
    uv = nodes.new("ShaderNodeUVMap")
    uv.uv_map = "SheetUV" if fresh else record["old_uv_name"]

    def texture(path, noncolor):
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = load_texture(path, noncolor)
        tex.interpolation = "Linear"
        links.new(uv.outputs["UV"], tex.inputs["Vector"])
        return tex.outputs["Color"]

    if grey:
        bsdf.inputs["Base Color"].default_value = (.6, .6, .6, 1)
    elif fresh:
        links.new(texture(REVIEW / ("test-skin-" + mode + ".png"), False), bsdf.inputs["Base Color"])
    else:
        name = record["name"]
        rgb = ((255, 212, 20) if "tape" in name or "elastic" in name else
               ((255,255,255) if "accent" in name or "sticker" in name else
                ((165,55,50) if "cardboard" in name or "tube" in name else (214,78,72))))
        tint = nodes.new("ShaderNodeMixRGB")
        tint.blend_type, tint.inputs[0].default_value = "MULTIPLY", 1.
        tint.inputs[2].default_value = (*linear(rgb), 1)
        links.new(texture(record["source"].with_name(record["source_name"]+"-color.png"), False), tint.inputs[1])
        links.new(tint.outputs[0], bsdf.inputs["Base Color"])
    normal = nodes.new("ShaderNodeNormalMap")
    normal.space, normal.uv_map = "TANGENT", uv.uv_map
    path = (OUT / (record["name"]+"-normal.png") if fresh else
            record["source"].with_name(record["source_name"]+"-normal.png"))
    links.new(texture(path, True), normal.inputs["Color"])
    links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    if scope and mode != "today":
        bsdf.inputs["Roughness"].default_value = .7
    else:
        links.new(texture(record["source"].with_name(record["source_name"]+"-roughness.png"), True), bsdf.inputs["Roughness"])
    return mat


def review_matrix(record, correction):
    raw = positions(record["old"].data) @ B2R.T
    lo, hi = raw.min(0), raw.max(0)
    size_scale = np.diag(record["size"] / (hi-lo))
    transform = record["rotation"] @ size_scale @ correction
    m = np.eye(4)
    m[:3,:3] = R2B @ transform @ B2R
    m[:3,3] = R2B @ (record["centre"] - transform @ ((lo+hi)/2))
    return Matrix(m.tolist())


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.cycles.seed = 60113
    scene.render.threads_mode, scene.render.threads = "FIXED", min(12, os.cpu_count() or 4)
    scene.render.resolution_x, scene.render.resolution_y = 1600, 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.world = bpy.data.worlds.new("Prototype blue-grey studio")
    scene.world.use_nodes = True
    bg = scene.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (.62, .74, .82, 1)
    bg.inputs["Strength"].default_value = .9
    sun = bpy.data.objects.new("Prototype Sun", bpy.data.lights.new("Prototype Sun", "SUN"))
    scene.collection.objects.link(sun)
    sun.data.energy = 3.5
    sun.data.angle = math.radians(8)
    sun.rotation_euler = (math.radians(40), math.radians(-20), math.radians(30))
    cam = bpy.data.objects.new("Review Camera", bpy.data.cameras.new("Review Camera"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene


def frame_camera(scene, points, view):
    cam = scene.camera
    points = points @ R2B.T
    centre = (points.min(0)+points.max(0))/2
    directions = {"three-quarter": (-1.1, 1.55, 1.25), "top": (0, 0, 1),
                  "side": (-1, 0, 0), "front": (0, 1, 0), "bottom": (0, 0, -1)}
    direction = Vector(directions[view]).normalized()
    quat = (-direction).to_track_quat("-Z", "Y")
    rotation = np.array(quat.to_matrix())
    local = (points-centre) @ rotation
    aspect = scene.render.resolution_x/scene.render.resolution_y
    cam.rotation_euler = quat.to_euler()
    if view == "three-quarter":
        cam.data.type, cam.data.lens = "PERSP", 35
        tan_h = cam.data.sensor_width / (2*cam.data.lens)
        distance = float(max(np.max(np.abs(local[:,0])/tan_h+local[:,2]),
                             np.max(np.abs(local[:,1])*aspect/tan_h+local[:,2])))*1.16
    else:
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = max(np.ptp(local[:,0]), np.ptp(local[:,1])*aspect)*1.14
        distance = 60
    cam.location = Vector(centre) + direction*distance
    cam.data.clip_end = 500
    return dict(position=list(cam.location), rotation=list(cam.rotation_euler),
                type=cam.data.type, lens=cam.data.lens, ortho_scale=cam.data.ortho_scale)


def save_jpeg(path, values):
    h, w = values.shape[:2]
    image = bpy.data.images.new("Contact sheet", width=w, height=h, alpha=False)
    image.colorspace_settings.name = "sRGB"
    rgba = np.ones((h,w,4), dtype=np.float32)
    rgba[:,:,:3] = values[::-1].astype(np.float32)/255
    image.pixels.foreach_set(rgba.ravel())
    image.file_format = "JPEG"
    image.filepath_raw = destination(path)
    image.save()
    bpy.data.images.remove(image)
    saved = image_pixels(path)[:,:,:3][::-1]
    check(saved.shape == values.shape, "Contact-sheet dimensions: "+str(path))
    error = float(np.abs(saved-values.astype(float)/255).mean())
    check(error < .025, "Contact-sheet colour transform error: "+str(path))
    return dict(dimensions=[w,h], mean_jpeg_rgb_error=error, result="PASS")


def downsample(values, width, height):
    # Area average with exact fractional box weights, 1600x900 -> 480x270.
    def resize_axis(data, length, axis):
        old = data.shape[axis]
        edges = np.arange(length+1, dtype=float)*(old/length)
        index = np.floor(edges).astype(int)
        fraction = edges-index
        zero_shape = list(data.shape)
        zero_shape[axis] = 1
        integral = np.concatenate((np.zeros(zero_shape), np.cumsum(data, axis=axis, dtype=np.float64)), axis=axis)
        frac_shape = [1]*data.ndim
        frac_shape[axis] = length+1
        sample = (np.take(integral, np.minimum(index,old), axis=axis)
                  + np.take(data, np.minimum(index,old-1), axis=axis)*fraction.reshape(frac_shape))
        return np.diff(sample, axis=axis)/(old/length)
    return resize_axis(resize_axis(values,width,1),height,0)


def render_reviews(records, correction):
    scene = setup_scene()
    reports, sheets = {}, []
    for plane, parts in BUILDS.items():
        selected = [r for r in records if r["part"] in parts]
        display = []
        for r in selected:
            o = r["old"].copy()
            o.data = r["old"].data.copy()
            o.name = "Review/"+r["name"]
            scene.collection.objects.link(o)
            o.hide_render = False
            o.hide_set(False)
            o.matrix_world = review_matrix(r, correction)
            display.append((r,o))
        points = np.concatenate([r["plane_positions"] for r in selected])
        cameras = {view: frame_camera(scene, points, view) for view in VIEWS}
        renders = {}
        reused_count = 0
        for mode in ("today", "creaseold", "crease", "hazard", "lava"):
            for r, o in display:
                source = r["new"] if r["scope"] and mode in ("crease", "hazard", "lava") else r["old"]
                previous = o.data
                o.data = source.data.copy()
                if previous.users == 0:
                    bpy.data.meshes.remove(previous)
                o.data.materials.clear()
                o.data.materials.append(make_material(r, mode))
            for view in VIEWS:
                frame_camera(scene, points, view)
                stem = ("skin-"+mode if mode in ("hazard", "lava") else mode)
                path = REVIEW / (stem+"-"+plane+"-"+view+".png")
                begin = time.perf_counter()
                cached = RESUME_RENDERS and path.is_file() and path.resolve() in NEW_FILES
                reused_count += int(cached)
                if not cached:
                    scene.render.filepath = destination(path)
                    bpy.ops.render.render(write_still=True)
                im = image_pixels(path)
                check(im.shape == (900,1600,4) and np.isfinite(im).all(), "Render dimensions/data: "+str(path))
                check(np.ptp(im[:,:,:3]) > .05, "Empty render: "+str(path))
                renders[(mode,view)] = path
                checkpoint()
                log(("reused checked render " if cached else "render ") + path.name + " %.1fs" % (time.perf_counter()-begin))
        sheet = np.full((5*270, 5*480, 3), 244, dtype=np.uint8)
        for row, view in enumerate(VIEWS):
            for col, mode in enumerate(("today", "creaseold", "crease", "hazard", "lava")):
                pixels = image_pixels(renders[(mode,view)])[:,:,:3][::-1]
                cell = np.rint(downsample(pixels,480,270)*255).clip(0,255).astype(np.uint8)
                text(cell, plane+" / "+view+" / "+mode, 8, 8, backing=True)
                sheet[row*270:(row+1)*270,col*480:(col+1)*480] = cell
        sheet_check = save_jpeg(REVIEW / plane / "review.jpg", sheet)
        sheets.append(sheet)
        reports[plane] = dict(parts=parts, pieces=[r["name"] for r in selected], render_count=25,
            checked_renders_reused=reused_count,
            render_dimensions=[1600,900], engine="Cycles CPU", samples=32,
            views=VIEWS, cameras=cameras, contact_sheet=relative(REVIEW / plane / "review.jpg"),
            contact_cell_dimensions=[480,270], dimension_and_nonempty_checks="PASS",
            contact_sheet_check=sheet_check,
            crease_comparison="Both grey versions use Base Color=(0.6,0.6,0.6), roughness=0.7; excluded pieces keep current maps.")
        for r,o in display:
            mesh = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if not mesh.users:
                bpy.data.meshes.remove(mesh)
    save_jpeg(REVIEW / "review.jpg", np.concatenate(sheets, axis=0))
    return reports


def preexisting_snapshot():
    # Read-only inventory; no git command, archive read, or source mutation.
    result = {}
    for folder, dirs, files in os.walk(ROOT):
        dirs[:] = [name for name in dirs if name != ".git"]
        for name in files:
            path = (Path(folder)/name).resolve()
            if path in NEW_FILES:
                continue
            stat = path.stat()
            result[path] = (stat.st_size, stat.st_mtime_ns)
    return result


def source_hashes(records):
    paths = {BASE/"pieces.rbxmx", BASE/"paper-set/uploads.json", BASE/"paper-sample/uploads.json"}
    for r in records:
        paths.add(r["source"])
        for kind in ("color", "normal", "roughness"):
            paths.add(r["source"].with_name(r["source_name"]+"-"+kind+".png"))
    return {relative(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(paths)}


def readme(manifest, layout):
    rows = ["# Printed-sheet plane pieces", "", "Local copies only. No uploads, Studio use or changes to today's pieces.", "",
        "## Rebuild", "", "```powershell",
        "& D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 --python tools/art/skin_sheet.py", "```", "",
        "Blender 5.1 + its bundled Python and NumPy only. Deterministic numerical normal bakes and 32-sample Cycles CPU renders.",
        "The tool refuses to overwrite files that predate its first run. To rebuild its own outputs explicitly, append -- --rebuild. After an interrupted run, -- --resume reuses completed renders only if all FBX/normal/test-skin bytes remain identical.", "",
        "## Review", "", "../../../.. is the repository root. Reviews are in .planning/skins/sheet/: 50 PNGs at 1600 x 900, two test-skin PNGs, starter/review.jpg and heavy/review.jpg, plus the combined review.jpg.",
        "Rows: three-quarter, top, side, front, bottom. Columns: today / creaseold / crease / hazard / lava. Each cell is 480 x 270.", "",
        "## Layout", "", "One 1024 x 1024 skin picture, shared across all 98 copies. SheetUV is derived from each piece's unscaled template placement in pieces.rbxmx.",
        "TOP uses x/z, SIDE uses y/z, FRONT uses x/y. Nose is up in TOP and SIDE; FRONT has up at the top. Both sides share the same print. Regional seams are intentional.",
        "Bounds are the union of all in-scope XML boxes, including CFrame rotation, padded 0.25 stud. There are 16 pixel outer margins and 16 pixel gaps. All regions share k=%.12f pixels/stud." % layout["k"],
        "See layout.json for exact bounds, floating-point rectangles, dominant-normal selection and coordinate-to-UV formulas. Rectangles use top-left pixel coordinates, [x,y,width,height]; UV origin is bottom-left.", "",
        "sheet-template.png has white backing, slot-coloured triangle outlines, regional guides, nose arrows and a word legend. Keep guide lines off a finished skin picture.", "",
        "## Normal transfer", "", "For each destination texel, bilinearly sample the old normal map using its old UV, decode through Blender's old MikkTSpace tangent frame into object space, then solve the exact inverse of the SheetUV tangent frame. This is a normal bake, not a colour-channel copy.",
        "The old and new frames use unnormalized interpolated Mikk attributes and a pixel-reconstructed signed bitangent. Reference: https://github.com/mmikk/MikkTSpace/blob/master/mikktspace.h and https://docs.blender.org/api/current/bpy.types.Mesh.html#bpy.types.Mesh.calc_tangents.",
        "Facing surfaces have priority: TOP +y, SIDE away from x=0, FRONT -z. Opposite faces only fill uncovered texels. Same-facing overlap chooses the nearest projected surface. There is an 8px Euclidean normal gutter; empty pixels are (128,128,255).",
        "Opposing faces cannot retain independent crease details when they share one texel. Thin triangles below one pixel also cannot retain all source detail. Per-piece coverage and subpixel counts are reported in manifest.json. The reduced shared-sheet texel density is visible in close views; the geometry itself is unchanged.", "",
        "## Import contract", "", "Y up, -Z forward, global_scale=.01, UnitScaleFactor=1, raw coordinates in studs. Do not recenter or change MeshPart placement/size. These are replacement MeshIds for skins, not new hitboxes. Blender's bundled FBX writer re-encodes the source with only its UV element replaced. Exact raw geometry, normal, smoothing and axis/unit records are fingerprint-checked. This avoids roundtrip geometric-normal drift on source needle faces.",
        "Exactly one UV layer, SheetUV. Normal maps are 1024 x 1024, MikkTSpace tangent-space, OpenGL +Y. Normal data is non-colour. No geometry or image data is stored in game code.", "",
        "## Using a skin", "", "When a skin is worn, select the same-named sheet copy for each structural paper/cardboard/tube piece. SurfaceAppearance.ColorMap = that skin's shared picture; NormalMap = the piece's own <piece>-normal.png. Colour pictures are sRGB, normals non-colour; use roughness 0.7 (a constant roughness image in Roblox). Keep the colour tint white so it does not alter the skin picture. Accents, tape, elastic and stickers keep their current meshes/maps.", "",
        "## Checks", "", "Every output FBX is reimported. Bounds/raw FBX units, vertex positions/count, triangle surfaces/count, shading-normal corners, a single named UV layer, finite UVs in [0,1] and agreement with the coordinate formulas are checked. Source needle faces are retained; projected areas and faces below UV float precision are counted, without inflating their projection. Required-check failures raise an error and exit Blender with status 1.",
        "Normal checks: facing priority over all raster candidates, object-space reconstruction, under 1 degree quantization error at selected texel centres, unit normals, saved PNG bytes/resolution and every empty background texel. Render dimensions/nonempty contents, JPEG dimensions/colour agreement and pre-existing file metadata are checked. Input FBX/map/XML/upload files also receive before/after SHA-256 checks. No Studio or engine integration check was performed.",
        "All 98 in-scope MeshIds match their folder's uploads.json. Review-only sticker placeholders reuse the existing paper-sample wings-sticker-left/right geometry/maps; they have no uploads.json entry and are excluded from the 98-source comparison.", "",
        "## Meshes", "", "| Part | Piece | Triangles | Regions |", "|---|---|---:|---|"]
    rows.extend("| %s | %s | %d | %s |" % (entry["part_id"], entry["piece_name"], entry["triangle_count"], ", ".join(entry["regions_used"])) for entry in manifest["pieces"])
    if manifest.get("existing_files_changed"):
        rows.extend(["", "## Concurrent file changes", "",
            "The metadata watch found changes outside this tool's output paths. They were left alone. This is not an unchanged-repository result; source FBX/map/XML/upload SHA-256 checks still passed."])
        rows.extend("- "+name for name in manifest["existing_files_changed"])
    rows.extend(["", "Build wall time: %.1f seconds. No uploads or Studio review." % manifest["wall_time_seconds"], ""])
    Path(destination(OUT/"README.md")).write_text("\n".join(rows), encoding="utf-8")


def main():
    global RESUME_RENDERS
    begin = time.perf_counter()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    previous_report = (json.loads((OUT/"manifest.json").read_text(encoding="utf-8"))
                       if (OUT/"manifest.json").is_file() else {})
    prior_changes = previous_report.get("existing_files_changed", [])
    if previous_report.get("error", "").startswith("Pre-existing files changed during run: "):
        prior_changes = ast.literal_eval(previous_report["error"].split(": ", 1)[1])
    existing = preexisting_snapshot()
    INITIAL_FILES.update(existing)
    if "--rebuild" in sys.argv:
        # Only outputs owned by a prior successful manifest may be replaced.
        previous = json.loads((OUT/"manifest.json").read_text(encoding="utf-8"))
        NEW_FILES.update((ROOT/name).resolve() for name in previous["generated_files"])
        NEW_FILES.update({(OUT/"manifest.json").resolve(), (OUT/"README.md").resolve()})
        existing = {p: stat for p, stat in existing.items() if p not in NEW_FILES}
    if "--resume" in sys.argv:
        # Recovery of this job's first interrupted run, before manifest creation.
        # A matching layout is the ownership marker; unrelated review files are
        # never adopted. A completed run uses the manifest's explicit allowlist.
        prior_layout = json.loads((OUT/"layout.json").read_text(encoding="utf-8"))
        check(prior_layout == dict(make_layout(inventory()), import_basis_calibration=detect_import_basis()[1]),
              "Cannot resume an unrelated layout")
        allowed = {"layout.json"}
        for r in inventory():
            if r["scope"]:
                allowed.update({r["name"]+".fbx", r["name"]+"-normal.png"})
        allowed.update({"manifest.json", "README.md", "sheet-template.png"})
        NEW_FILES.update(path.resolve() for path in OUT.iterdir() if path.name in allowed)
        render_paths = {REVIEW/("test-skin-"+skin+".png") for skin in ("hazard","lava")}
        for plane in BUILDS:
            render_paths.add(REVIEW/plane/"review.jpg")
            for view in VIEWS:
                for mode in ("today","creaseold","crease","skin-hazard","skin-lava"):
                    render_paths.add(REVIEW/(mode+"-"+plane+"-"+view+".png"))
        render_paths.add(REVIEW/"review.jpg")
        NEW_FILES.update(path.resolve() for path in render_paths if path.is_file())
        existing = {p: stat for p, stat in existing.items() if p not in NEW_FILES}
    records = inventory()
    hashes = source_hashes(records)
    if "--resume" in sys.argv and (OUT/"manifest.json").is_file():
        prior = json.loads((OUT/"manifest.json").read_text(encoding="utf-8"))
        check(not prior.get("input_sha256") or prior["input_sha256"] == hashes,
              "Inputs changed since interrupted run; use -- --rebuild")
    render_inputs = [OUT/(r["name"]+suffix) for r in records if r["scope"] for suffix in (".fbx","-normal.png")]
    render_inputs.extend(REVIEW/("test-skin-"+skin+".png") for skin in ("hazard","lava"))
    render_hashes_before = {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in render_inputs if p.is_file()}
    BUILD_STATE.update(status="BUILDING", generator="tools/art/skin_sheet.py", input_sha256=hashes, pieces=[],
                       existing_files_changed=prior_changes)
    checkpoint()
    correction, basis = detect_import_basis()
    layout = make_layout(records)
    layout["import_basis_calibration"] = basis
    write_json(OUT/"layout.json", layout)
    mismatches = [dict(piece=r["name"], MeshId=r["mesh_id"], uploads_mesh=r["upload_mesh_id"])
                  for r in records if r["upload_mesh_id"] != "MISSING" and not r["mesh_id_match"]]
    for item in mismatches:
        log("MESH ID MISMATCH " + json.dumps(item))
    entries = []
    for index, r in enumerate(records):
        obj = import_mesh(r["source"])
        r["old"] = obj
        obj.hide_render = True
        r["plane_positions"] = assembled_positions(obj, r, correction)
        if not r["scope"]:
            r["old_uv_name"] = obj.data.uv_layers[0].name
            obj.hide_set(True)
            continue
        assign_uv(obj, r, correction, layout)
        bake = bake_normal(obj, r, layout)
        validation = export_and_check(obj, r)
        entry = dict(part_id=r["part"], piece_name=r["name"], source_fbx=relative(r["source"]),
            MeshId=r["mesh_id"], uploads_mesh_id=r["upload_mesh_id"], MeshId_matches_upload=r["mesh_id_match"],
            triangle_count=len(obj.data.loop_triangles), regions_used=sorted(set(r["face_regions"])),
            uv_checks_passed=True, checks=validation, normal_bake=bake)
        entries.append(entry)
        BUILD_STATE["pieces"] = entries
        checkpoint()
        obj.hide_set(True)
        log("piece %d/98 %s: geometry/UV/normal PASS (%d triangles, %d subpixel)" %
            (len(entries), r["name"], entry["triangle_count"], bake["subpixel_triangles_without_pixel_centres"]))
    make_template(records, layout)
    make_skins(layout)
    render_hashes_after = {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in render_inputs}
    RESUME_RENDERS = "--resume" in sys.argv and render_hashes_before == render_hashes_after
    if "--resume" in sys.argv:
        log("Completed renders may be reused: " + str(RESUME_RENDERS) + "; all 110 render-asset hashes compared")
    log("All 98 FBX roundtrips and normal transfers checked; rendering 50 review images")
    reviews = render_reviews(records, correction)
    changed = [relative(path) for path, stat in existing.items()
               if not path.is_file() or (path.stat().st_size, path.stat().st_mtime_ns) != stat]
    # This is a read-only concurrency watch, not permission to revert somebody
    # else's work. Required asset checks still fail loudly. Report this watch as
    # FAIL when it changes; never silently relabel it as an unchanged repo.
    observed_changes = sorted(set(changed+prior_changes))
    if observed_changes:
        log("EXISTING FILE WATCH FAIL (outside this tool's write paths): " + str(observed_changes))
    check(hashes == source_hashes(records), "Input FBX/maps/XML/uploads changed during run")
    manifest = dict(status="COMPLETE_WITH_CONCURRENT_CHANGES" if observed_changes else "COMPLETE",
        generator="tools/art/skin_sheet.py", piece_count=len(entries), pieces=entries, MeshId_mismatches=mismatches,
        known_source_mesh_ids_checked=sum(r["upload_mesh_id"] != "MISSING" for r in records),
        existing_files_changed=observed_changes,
        layout="layout.json", review=reviews, wall_time_seconds=time.perf_counter()-begin,
        checks=dict(all_98_roundtrips="PASS", all_98_normal_transfers="PASS", layout="PASS",
                    render_dimensions_and_nonempty="PASS", existing_files_metadata_unchanged="FAIL" if observed_changes else "PASS",
                    existing_files_checked=len(existing), input_hashes_unchanged="PASS", input_files_hashed=len(hashes)),
        input_sha256=hashes,
        limitations=["Shared opposing normal texels cannot preserve independently authored details on both surfaces.",
                     "Shared sheet density is lower than the original per-piece atlas; subpixel details may be lost.",
                     "Review-only sticker placeholders reuse sample sticker maps, with no uploads.json entry.",
                     "No upload or Roblox Studio check performed."])
    readme(manifest, layout)
    NEW_FILES.add((OUT/"manifest.json").resolve())
    manifest["generated_files"] = sorted(relative(path) for path in NEW_FILES)
    write_json(OUT/"manifest.json", manifest)
    log("COMPLETE " + json.dumps(dict(pieces=len(entries), triangles=sum(e["triangle_count"] for e in entries),
        seconds=manifest["wall_time_seconds"], MeshId_mismatches=mismatches,
        k=layout["k"], regions=layout["regions"], checks=manifest["checks"])))


if __name__ == "__main__":
    if "--diagnose" in sys.argv:
        source = import_mesh(BASE/"paper-set/body_heavy-cardboard-L.fbx")
        target = import_mesh(OUT/"body_heavy-cardboard-L.fbx")
        for obj in (source,target):
            log(str(dict(name=obj.name, smooth=sum(p.use_smooth for p in obj.data.polygons),
                faces=len(obj.data.polygons), custom=obj.data.has_custom_normals,
                normal0=[n.vector[:] for n in obj.data.corner_normals][:4])))
        src,dst = canonical_geometry(source.data),canonical_geometry(target.data)
        log("position error "+str(multiset_error(src[0],dst[0],TOL)))
        log("normal error "+str(multiset_error(src[2],dst[2],1e-5)))
    elif "--inspect" in sys.argv:
        records = inventory()
        correction, basis = detect_import_basis()
        log(json.dumps(dict(pieces=[r["name"] for r in records if r["scope"]], basis=basis,
            layout=make_layout(records), mismatches=[r["name"] for r in records if r["scope"] and not r["mesh_id_match"]]), indent=2))
    else:
        # Resume this job's fully rendered batch after an external-file watch
        # stopped final reporting. Exact command remains usable for recovery;
        # render input hashes must match before any cached image is accepted.
        report_path = OUT/"manifest.json"
        if report_path.is_file() and "--resume" not in sys.argv and "--rebuild" not in sys.argv:
            previous = json.loads(report_path.read_text(encoding="utf-8"))
            if (previous.get("generator") == "tools/art/skin_sheet.py" and previous.get("status") == "FAILED"
                    and previous.get("error", "").startswith("Pre-existing files changed during run: ")):
                sys.argv.append("--resume")
        try:
            main()
        except Exception as error:
            if NEW_FILES:
                NEW_FILES.add((OUT/"manifest.json").resolve())
                BUILD_STATE.update(status="FAILED", error=str(error))
                checkpoint()
            raise
