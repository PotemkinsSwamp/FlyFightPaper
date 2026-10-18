"""Local Classic paper sample. Blender Python and NumPy only; never uploads.

& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_paper.py

Source FBXs are authoritative, including the separately centred half meshes.
All generated files live in assets/models/planes/paper-sample/.
"""

import argparse
import hashlib
import json
import math
import struct
import sys
import zlib
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from io_scene_fbx import parse_fbx


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/models/planes/classic"
OUT = ROOT / "assets/models/planes/paper-sample"
COMMAND = "& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_paper.py"
RENDERS = ["compare-threequarter.png", "team-red.png", "team-blue.png",
           "closeup-wing.png", "closeup-nose.png", "maps-contact-sheet.png", "game-distance.png"]
PAPER, RED, BLUE = (238, 230, 212), (206, 48, 43), (40, 91, 172)
TEAM_RED, TEAM_BLUE, WHITE = (235, 40, 50), (25, 115, 255), (252, 252, 255)
TOLERANCE = 0.00002
FEATURES = {}


def log(message):
    print("PAPER_SAMPLE " + message, flush=True)


def bvec(p):
    return Vector((p[0], -p[2], p[1]))


def rvec(p):
    return [float(p[0]), float(p[2]), float(-p[1])]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def png(path, values):
    """Write exact 8-bit channel values, without view transforms or dependencies."""
    values = np.ascontiguousarray(values, dtype=np.uint8)
    h, w, channels = values.shape
    assert channels in (3, 4)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))

    rows = b"".join(b"\0" + row.tobytes() for row in values)
    path.write_bytes(b"\x89PNG\r\n\x1a\n"
                     + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2 if channels == 3 else 6, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows, 7)) + chunk(b"IEND", b""))


def pixels(path):
    im = bpy.data.images.load(str(path), check_existing=False)
    values = np.empty(im.size[0] * im.size[1] * 4, dtype=np.float32)
    im.pixels.foreach_get(values)
    values = values.reshape(im.size[1], im.size[0], 4)[::-1].copy()
    bpy.data.images.remove(im)
    return values


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path), global_scale=100,
                             use_custom_normals=False)
    added = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in added if o.type == "MESH"]
    assert len(meshes) == 1, str(path)
    obj = meshes[0]
    # This is the same unit/axis normalization used by split_halves.py.
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    for other in added:
        if other != obj:
            bpy.data.objects.remove(other, do_unlink=True)
    obj.data.update()
    return obj


def coordinates(obj):
    return np.array([v.co[:] for v in obj.data.vertices], dtype=np.float64)


def rendering_surfaces(obj):
    """Canonical per-triangle coordinate rows, excluding invisible source junk."""
    obj.data.calc_loop_triangles()
    verts = coordinates(obj)
    rows = []
    for triangle in obj.data.loop_triangles:
        if triangle.area < 1e-10:
            continue
        xyz = verts[list(triangle.vertices)]
        xyz = xyz[np.lexsort(tuple(np.round(xyz[:, i], 4) for i in (2, 1, 0)))]
        rows.append(xyz.reshape(-1))
    rows = np.array(rows)
    return rows[np.lexsort(tuple(np.round(rows[:, i], 4) for i in range(8, -1, -1)))]


def bounds(obj):
    p = coordinates(obj)
    return np.array([p.min(0), p.max(0)])


def raw_fbx(path):
    tree, _ = parse_fbx.parse(str(path))
    blocks = next(x for x in tree.elems if x.id == b"Objects")
    geometry = next(x for x in blocks.elems if x.id == b"Geometry")
    verts = np.array(next(x.props[0] for x in geometry.elems if x.id == b"Vertices")).reshape(-1, 3)
    settings = next(x for x in tree.elems if x.id == b"GlobalSettings")
    props = next(x for x in settings.elems if x.id == b"Properties70")
    unit = next(x.props[-1] for x in props.elems if x.props[0] == b"UnitScaleFactor")
    return verts, unit


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def unwrap(obj, resolution):
    active(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(28), island_margin=0.018,
                             area_weight=0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(rotate=True, scale=True, margin_method="FRACTION",
                            margin=12 / resolution, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.data.uv_layers.active.name = "PaperUV"
    obj.data.calc_loop_triangles()
    obj.data.calc_tangents(uvmap="PaperUV")


def remove_invisible_faces(obj):
    """Keep source coordinates and real surfaces, discard inherited zero-area faces."""
    obj.data.calc_loop_triangles()
    source_count = len(obj.data.loop_triangles)
    bad = {tri.polygon_index for tri in obj.data.loop_triangles if tri.area < 1e-10}
    if bad:
        old = obj.data
        data = bpy.data.meshes.new(old.name + " paper surfaces")
        data.from_pydata(coordinates(obj).tolist(), [],
                         [tuple(face.vertices) for face in old.polygons if face.index not in bad])
        data.update()
        obj.data = data
    obj.data.calc_loop_triangles()
    return source_count, source_count - len(obj.data.loop_triangles)


def atlas(obj, resolution):
    """Rasterize the UVs once; retain positions, face normals and tangent frames.

    Strict interior tests check overlaps independently of Blender's packer.
    Exact tangent frames follow Blender's MikkTSpace UV handedness, including
    mirrored islands. PNG row flipping is handled only when writing the maps.
    """
    mesh = obj.data
    uv = np.array([loop.uv[:] for loop in mesh.uv_layers.active.data])
    pos = np.zeros((resolution, resolution, 3), dtype=np.float64)
    normal = np.zeros_like(pos)
    tangent = np.zeros_like(pos)
    bitangent = np.zeros_like(pos)
    face_id = np.full((resolution, resolution), -1, dtype=np.int32)
    interior = np.zeros((resolution, resolution), dtype=np.int16)
    density, uv_area, surface_area = [], 0.0, 0.0
    verts = coordinates(obj) + np.array(obj.location)
    for tri in mesh.loop_triangles:
        tuv = uv[list(tri.loops)]
        a, b, c = tuv * resolution - 0.5
        denominator = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        assert abs(denominator) > 1e-12, obj.name + ": zero-area UV"
        lo = np.maximum(np.floor(np.min([a, b, c], axis=0)).astype(int), 0)
        hi = np.minimum(np.ceil(np.max([a, b, c], axis=0)).astype(int) + 1, resolution)
        y, x = np.mgrid[lo[1]:hi[1], lo[0]:hi[0]]
        u = ((b[1] - c[1]) * (x - c[0]) + (c[0] - b[0]) * (y - c[1])) / denominator
        v = ((c[1] - a[1]) * (x - c[0]) + (a[0] - c[0]) * (y - c[1])) / denominator
        w = 1 - u - v
        hit = (u >= -1e-7) & (v >= -1e-7) & (w >= -1e-7)
        strict = (u > 1e-5) & (v > 1e-5) & (w > 1e-5)
        interior[y[strict], x[strict]] += 1
        yy, xx = y[hit], x[hit]
        xyz = verts[list(tri.vertices)]
        pos[yy, xx] = u[hit, None] * xyz[0] + v[hit, None] * xyz[1] + w[hit, None] * xyz[2]
        n = np.array(tri.normal[:])
        t = np.array(mesh.loops[tri.loops[0]].tangent[:])
        bit = mesh.loops[tri.loops[0]].bitangent_sign * np.cross(n, t)
        normal[yy, xx], tangent[yy, xx], bitangent[yy, xx] = n, t, bit
        face_id[yy, xx] = tri.polygon_index
        area = abs(denominator) / resolution ** 2 / 2
        world_area = np.linalg.norm(np.cross(xyz[1] - xyz[0], xyz[2] - xyz[0])) / 2
        density.append(math.sqrt(area / world_area) * resolution)
        uv_area += area
        surface_area += world_area
    assert interior.max() == 1, obj.name + ": overlapping UV interiors"
    assert uv.min() >= -1e-6 and uv.max() <= 1.000001
    return (pos, normal, tangent, bitangent, face_id), {
        "layer": "PaperUV", "overlap_interior_pixels": int((interior > 1).sum()),
        "uv_bounds": [float(uv.min()), float(uv.max())],
        "coverage_percent": round(uv_area * 100, 3), "gutter_pixels": 12,
        "texels_per_stud": round(math.sqrt(uv_area / surface_area) * resolution, 2),
        "triangle_density_min_max": [round(min(density), 2), round(max(density), 2)],
        "validation": "UV triangle interior raster test, plus bounds and positive-area checks"}


def exact_uv_overlap(obj):
    """Triangle clipping also catches overlaps smaller than a texture pixel."""
    obj.data.calc_loop_triangles()
    uv = np.array([x.uv[:] for x in obj.data.uv_layers.active.data])
    triangles = np.array([uv[list(t.loops)] for t in obj.data.loop_triangles])
    lo, hi = triangles.min(1), triangles.max(1)
    largest = 0.0

    def cross(a, b):
        return float(a[0] * b[1] - a[1] * b[0])

    for i, first in enumerate(triangles):
        candidates = np.flatnonzero(np.all(hi[i] > lo[i + 1:] + 1e-10, axis=1)
                                    & np.all(hi[i + 1:] > lo[i] + 1e-10, axis=1)) + i + 1
        for j in candidates:
            clip = triangles[j]
            sign = 1 if cross(clip[1] - clip[0], clip[2] - clip[0]) > 0 else -1
            poly = list(first)
            for a, b in zip(clip, np.roll(clip, -1, axis=0)):
                result = []
                for p, q in zip(poly, poly[1:] + poly[:1]):
                    cp, cq = sign * cross(b - a, p - a), sign * cross(b - a, q - a)
                    if cp >= -1e-12:
                        result.append(p)
                    if (cp >= -1e-12) != (cq >= -1e-12):
                        result.append(p + (q - p) * (cp / (cp - cq)))
                poly = result
                if not poly:
                    break
            if len(poly) >= 3:
                area = abs(sum(cross(poly[k] - poly[0], poly[k + 1] - poly[0])
                               for k in range(1, len(poly) - 1))) / 2
                largest = max(largest, area)
    assert largest < 1e-10, obj.name + ": analytical UV overlap"
    return {"analytical_triangle_overlap": "PASS", "maximum_intersection_uv_area": largest,
            "intersection_area_tolerance": 1e-10}


def noise(p, scale, seed):
    """Continuous deterministic value noise, with no external image input."""
    q = p * np.array(scale) + np.array((11.37, 31.81, 57.29))
    cell = np.floor(q).astype(np.int64)
    f = q - cell
    f = f * f * (3 - 2 * f)
    result = np.zeros(len(p), dtype=np.float64)
    for x in (0, 1):
        for y in (0, 1):
            for z in (0, 1):
                k = (cell[:, 0] + x) * 73856093 ^ (cell[:, 1] + y) * 19349663 ^ (cell[:, 2] + z) * 83492791 ^ seed
                k = (k ^ (k >> 13)) * 1274126177
                value = ((k ^ (k >> 16)) & 0xffff) / 32767.5 - 1
                weight = ((f[:, 0] if x else 1 - f[:, 0])
                          * (f[:, 1] if y else 1 - f[:, 1])
                          * (f[:, 2] if z else 1 - f[:, 2]))
                result += weight * value
    return result


def paper_height(p):
    """Fine isotropic tooth, plus a few large, extremely shallow handling marks.

    Equal noise frequencies on all three axes prevent brushed streaks. The
    broad field is smooth analytical curvature, never coarse random dimples.
    World positions keep the field continuous across pigment and split seams.
    """
    q = p @ np.array(((.36, -.80, .48), (.80, .52, .30), (-.48, .30, .82)))
    tooth = .00065 * noise(q, (28, 28, 28), 147)
    tooth += .00022 * noise(q, (43, 43, 43), 419)
    wave = .007 * np.sin(p @ np.array((.61, .37, .21)))
    wave += .003 * np.sin(p @ np.array((-.49, .73, .32)) + 1.4)
    for centre, radius, depth in (((-3.8, -2.1, .95), 1.25, -.009),
                                  ((3.7, -3.0, .95), 1.5, -.007),
                                  ((.6, -.8, .4), 1.7, -.005)):
        wave += depth * np.exp(-np.sum((p - centre) ** 2, axis=1) / radius ** 2)
    return tooth + wave


def feature_edges(obj):
    """Classify existing folds and cut rims without changing the source mesh.

    Use whole-mesh references for both halves. A centre-cut cap is never a
    paper edge, and true folds at that cut must survive on both alternatives.
    Opposing surfaces and coplanar triangulation diagonals are excluded.
    """
    verts = coordinates(obj) + np.array(obj.location)
    edges = {}
    for face in obj.data.polygons:
        for a, b in face.edge_keys:
            edges.setdefault(tuple(sorted((a, b))), []).append(face)
    result = []
    for (ai, bi), faces in edges.items():
        if len(faces) != 2:
            continue
        f1, f2 = faces
        n1, n2 = np.array(f1.normal[:]), np.array(f2.normal[:])
        dot = float(n1 @ n2)
        shallow_wing = obj["part"] == "wings" and obj["region"] != "sticker" and dot > .97
        if dot > (.999999 if shallow_wing else .9998) or dot < -.98:
            continue
        a, b = verts[ai], verts[bi]
        length = np.linalg.norm(b - a)
        if length < .06:
            continue
        if obj.name == "pellet-tube" and abs((b - a)[1]) / length > .999:
            continue  # Cylinder facets are not longitudinal paper creases.
        if obj["part"] != "pellet" and any(
                max(abs(a[1] - seam), abs(b[1] - seam)) < 1e-4
                for seam in (2.606416, 5.632566, -5.415929)):
            continue  # Assembly joints and pigment changes are not cut rims.
        # The thin sidewall of a sheet is a rim. Two substantial adjoining
        # panels form a fold, even at Classic's shallow wing-root angles.
        altitude = min(2 * f.area / length for f in faces)
        kind = "fold" if altitude > .14 or shallow_wing else "rim"
        if obj["region"] == "sticker":
            kind = "sticker"
        result.append((a, b, n1, n2, kind))
    return result


def edge_details(obj, p, n, face_ids):
    """Crisp valley/ridge pairs, thin bright rims and a soft sticker edge lift.

    Apply on the supporting plane, across coplanar triangle boundaries. This
    avoids clipped crease segments and preserves the whole/half appearance.
    """
    del face_ids
    result = n.copy()
    dark, bright = np.zeros(len(p)), np.zeros(len(p))
    whole_name = obj.name[:-2] if obj.get("side") else obj.name
    features = FEATURES[whole_name]
    for a, b, n1, n2, kind in features:
        e = b - a
        length = np.linalg.norm(e)
        e /= length
        for face_normal, other in ((n1, n2), (n2, n1)):
            ids = np.flatnonzero((n @ face_normal > .999)
                                 & (np.abs((p - a) @ face_normal) < .0001))
            if not len(ids):
                continue
            v = p[ids] - a
            along = np.clip(v @ e, 0, length)
            delta = v - along[:, None] * e
            distance = np.linalg.norm(delta, axis=1)
            near = distance < (.7 if kind == "fold" else .35)
            ids, distance, delta = ids[near], distance[near], delta[near]
            outward = delta / np.maximum(distance[:, None], 1e-12)
            if kind == "fold":
                valley = np.exp(-(distance / .043) ** 2)
                ridge = np.exp(-((distance - .082) / .037) ** 2)
                shoulder = np.exp(-(distance / .24) ** 2)
                dark[ids] = np.maximum(dark[ids], .095 * valley + .022 * shoulder)
                bright[ids] = np.maximum(bright[ids], .028 * ridge)
                # Derivative of a narrow pressed valley beside a raised ridge.
                slope = .012 * distance / .043 ** 2 * valley
                slope -= .007 * (distance - .082) / .037 ** 2 * ridge
                slope += .035 * shoulder
                result[ids] -= slope[:, None] * outward
            else:
                rim = np.exp(-(distance / .038) ** 2)
                bright[ids] = np.maximum(bright[ids], .040 * rim)
                if kind == "sticker":
                    lift = np.exp(-(distance / .075) ** 2)
                    result[ids] += (.006 * distance / .075 ** 2 * lift)[:, None] * outward
                    dark[ids] = np.maximum(dark[ids], .012 * np.exp(-((distance - .065) / .04) ** 2))
            # A shading-only edge roll catches light on the retained thickness.
            midpoint = face_normal + other
            midpoint /= np.linalg.norm(midpoint)
            slope_to_midpoint = midpoint / max(midpoint.dot(face_normal), .1) - face_normal
            roll_strength = .25 if kind == "fold" else .22 if kind == "sticker" else .55
            roll = roll_strength * np.exp(-(distance / .025) ** 2)
            result[ids] += roll[:, None] * slope_to_midpoint
    result /= np.maximum(np.linalg.norm(result, axis=1)[:, None], 1e-12)
    return result, bright - dark, {kind: sum(f[-1] == kind for f in features)
                                   for kind in ("fold", "rim", "sticker")}


def dilate(data, valid, iterations=12):
    """Extend island pixels into neutral gutters without wrapping image edges."""
    mask = valid.copy()
    for _ in range(iterations):
        total = np.zeros_like(data)
        count = np.zeros(mask.shape, dtype=np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            src_y, dst_y = (slice(0, -1), slice(1, None)) if dy == 1 else ((slice(1, None), slice(0, -1)) if dy == -1 else (slice(None), slice(None)))
            src_x, dst_x = (slice(0, -1), slice(1, None)) if dx == 1 else ((slice(1, None), slice(0, -1)) if dx == -1 else (slice(None), slice(None)))
            m = mask[src_y, src_x]
            total[dst_y, dst_x] += data[src_y, src_x] * m[..., None]
            count[dst_y, dst_x] += m
        fill = ~mask & (count > 0)
        data[fill] = total[fill] / count[fill, None]
        mask[fill] = True
    return data


def bake_ao(obj, resolution):
    """Actual Cycles hemisphere AO from the complete assembly, local radius .45."""
    mat = bpy.data.materials.new("AO bake temporary")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    emit = nodes.new("ShaderNodeEmission")
    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.samples = 24
    ao.inputs["Distance"].default_value = .45
    links.new(ao.outputs["AO"], emit.inputs["Color"])
    links.new(emit.outputs[0], out.inputs["Surface"])
    image = bpy.data.images.new("AO temporary", width=resolution, height=resolution, float_buffer=True)
    target = nodes.new("ShaderNodeTexImage")
    target.image = image
    nodes.active = target
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    active(obj)
    bpy.context.scene.render.bake.use_clear = True
    bpy.context.scene.render.bake.margin = 12
    # Team stickers change shape at runtime. Baking the placeholder square's
    # footprint would stamp a permanent square shadow under a circular marker.
    # Keep all structural occlusion, but let removable stickers cast their own
    # correctly shaped render/runtime shadows instead of drawing them in maps.
    markers = [o for o in bpy.context.scene.objects
               if o != obj and o.get("region") == "sticker" and not o.hide_render]
    try:
        for marker in markers:
            marker.hide_render = True
        bpy.ops.object.bake(type="EMIT")
    finally:
        for marker in markers:
            marker.hide_render = False
    values = np.empty(resolution * resolution * 4, dtype=np.float32)
    image.pixels.foreach_get(values)
    values = values.reshape(resolution, resolution, 4)[:, :, 0].copy()
    obj.data.materials.clear()
    bpy.data.materials.remove(mat)
    bpy.data.images.remove(image)
    return np.clip(values, 0, 1)


def make_maps(obj, resolution):
    unwrap(obj, resolution)
    buffers, uv_report = atlas(obj, resolution)
    uv_report.update(exact_uv_overlap(obj))
    pos, n, t, bit, face = buffers
    valid = face >= 0
    p, normals = pos[valid], n[valid]
    ao = bake_ao(obj, resolution)
    softened, edge_tone, features = edge_details(obj, p, normals, face[valid])
    if obj["part"] == "wings" and obj["region"] == "accent":
        assert features["fold"] > 0, "Wing-tip fold must continue through coloured paper"
    shade_normals = normals.copy()
    if obj.name == "pellet-tube":
        # Smooth a rolled sheet in the normal map, retaining every low-poly
        # vertex and the original hollow opening. Its flat source facets must
        # not introduce long stripes that could be mistaken for fibre grain.
        v = coordinates(obj) + np.array(obj.location)
        centre = (v.min(0) + v.max(0)) / 2
        radial = (p - centre) * np.array((1, 0, 1))
        radial /= np.maximum(np.linalg.norm(radial, axis=1)[:, None], 1e-12)
        radial *= np.where(np.sum(radial * normals, axis=1) < 0, -1, 1)[:, None]
        sides = np.abs(normals[:, 1]) < .01
        softened[sides] += radial[sides] - normals[sides]
        shade_normals[sides] = radial[sides]
    epsilon = .0025
    gradient = np.column_stack([(paper_height(p + np.eye(3)[i] * epsilon)
                                  - paper_height(p - np.eye(3)[i] * epsilon)) / (2 * epsilon)
                                 for i in range(3)])
    gradient -= normals * np.sum(gradient * normals, axis=1)[:, None]
    if obj["region"] == "sticker":
        gradient *= .45
    final = softened - gradient
    final /= np.linalg.norm(final, axis=1)[:, None]
    tangent_normal = np.column_stack((np.sum(final * t[valid], axis=1),
                                      np.sum(final * bit[valid], axis=1),
                                      np.sum(final * normals, axis=1)))
    assert np.min(tangent_normal[:, 2]) > 0
    grain = noise(p, (28, 28, 28), 147)
    # Low-amplitude, constant panel tone reinforces how real adjoining facets
    # catch light. Grain stays out of the broad colour field entirely.
    panel_tone = .020 * (shade_normals @ np.array((-.48, .16, .86)))
    luminance = np.clip(.962 + .002 * grain + panel_tone
                        - .12 * (1 - ao[valid]) + edge_tone, .85, .995)
    sticker = obj["region"] == "sticker"
    rough_base = .56 if sticker else .84
    roughness = np.clip(rough_base + .012 * grain, rough_base - .015, rough_base + .015)
    arrays = {}
    for kind, background, data in (
            ("color", [.978] * 3, np.repeat(luminance[:, None], 3, axis=1)),
            ("normal", [.5, .5, 1], tangent_normal * .5 + .5),
            ("roughness", [rough_base] * 3, np.repeat(roughness[:, None], 3, axis=1))):
        array = np.empty((resolution, resolution, 3), dtype=np.float32)
        array[:] = background
        array[valid] = data
        dilate(array, valid)
        if kind == "normal":
            decoded = array * 2 - 1
            decoded /= np.maximum(np.linalg.norm(decoded, axis=2)[:, :, None], 1e-12)
            array = decoded * .5 + .5
        arrays[kind] = np.round(np.clip(array[::-1], 0, 1) * 255).astype(np.uint8)
        png(OUT / (obj.name + "-" + kind + ".png"), arrays[kind])
    return uv_report, {
        "resolution": [resolution, resolution], "color_rgb_min_max": [int(arrays["color"].min()), int(arrays["color"].max())],
        "color_channels_identical": True, "roughness_min_max": [float(roughness.min()), float(roughness.max())],
        "ao_method": "Cycles Ambient Occlusion shader, 24 hemisphere samples, .45-stud radius, emission bake",
        "ao_luminance_weight": .12, "fold_edges": features["fold"], "edge_features": features,
        "ao_removable_marker_footprints": False,
        "normal_convention": "MikkTSpace tangent, OpenGL +Y green up; no green-channel inversion",
        "detail": "Fine isotropic tooth; shallow broad handling wave; real fold valley/ridge pairs; thin bright cut rims; softer glossier sticker paper with shading-only edge lift",
        "fold_valley_width_studs": .043, "fold_ridge_offset_studs": .082,
        "grain_directionality": "Equal frequency on every axis, no stretched noise",
        "feature_reference": obj.name[:-2] if obj.get("side") else obj.name,
        "rolled_tube_smoothing": obj.name == "pellet-tube",
        "geometry_displacement": 0, "padding": "12 pixels, neutral opaque backgrounds; no black silhouettes"}


def linear(rgb):
    return tuple(v / 255 / 12.92 if v / 255 <= .04045 else ((v / 255 + .055) / 1.055) ** 2.4 for v in rgb)


def paper_material(obj, region):
    mat = bpy.data.materials.new(obj.name + " paper")
    mat.use_nodes = True
    mat["region"] = region
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Specular IOR Level"].default_value = .32 if region == "sticker" else .22
    bsdf.inputs["Roughness"].default_value = .56 if region == "sticker" else .84
    tint = nodes.new("ShaderNodeMixRGB")
    tint.name = "Runtime tint"
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 1
    tint.inputs[2].default_value = (1, 1, 1, 1)
    for kind in ("color", "normal", "roughness"):
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = kind
        tex.image = bpy.data.images.load(str(OUT / (obj.name + "-" + kind + ".png")), check_existing=True)
        tex.image.colorspace_settings.name = "sRGB" if kind == "color" else "Non-Color"
        if kind == "color":
            links.new(tex.outputs["Color"], tint.inputs[1])
            links.new(tint.outputs[0], bsdf.inputs["Base Color"])
        elif kind == "roughness":
            links.new(tex.outputs["Color"], bsdf.inputs["Roughness"])
        else:
            normal = nodes.new("ShaderNodeNormalMap")
            normal.uv_map = "PaperUV"
            links.new(tex.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def set_tint(mat, rgb):
    mat.node_tree.nodes["Runtime tint"].inputs[2].default_value = (*linear(rgb), 1)


def export_check(obj, entry, original_coords, original_raw, original_surfaces):
    active(obj)
    saved_location = obj.location.copy()
    obj.location = (0, 0, 0)
    filename = obj.name + ".fbx"
    # Texture paths remain sidecar references; nothing is embedded or copied.
    bpy.ops.export_scene.fbx(filepath=str(OUT / filename), use_selection=True,
        object_types={"MESH"}, global_scale=.01, apply_unit_scale=False,
        apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y",
        bake_space_transform=True, use_mesh_modifiers=False, use_triangles=True,
        mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False,
        path_mode="STRIP", embed_textures=False, use_custom_props=False)
    obj.location = saved_location
    raw, unit = raw_fbx(OUT / filename)
    raw_error = float(np.max(np.abs(np.array([raw.min(0), raw.max(0)])
                                    - np.array([original_raw.min(0), original_raw.max(0)]))))
    assert unit == 1 and raw_error < TOLERANCE, filename + ": raw bounds/units"
    imported = import_fbx(OUT / filename)
    source_bounds = np.array([original_coords.min(0), original_coords.max(0)])
    imported_coords = coordinates(imported)
    imported_bbox = bounds(imported)
    bbox_error = float(np.max(np.abs(bounds(imported) - source_bounds)))
    assert bbox_error < TOLERANCE, filename + ": imported bounds"
    # Export can reorder corners, so compare the sorted coordinate multisets.
    def ordered(a):
        return a[np.lexsort((np.round(a[:, 2], 5), np.round(a[:, 1], 5), np.round(a[:, 0], 5)))]
    assert len(imported_coords) == len(original_coords)
    vertex_error = float(np.max(np.abs(ordered(imported_coords) - ordered(original_coords))))
    assert vertex_error < TOLERANCE, filename + ": vertex positions"
    surfaces = rendering_surfaces(imported)
    assert surfaces.shape == original_surfaces.shape, filename + ": real surface count"
    surface_error = float(np.max(np.abs(surfaces - original_surfaces)))
    assert surface_error < TOLERANCE, filename + ": rendering surfaces"
    imported.data.calc_loop_triangles()
    assert len(imported.data.loop_triangles) == entry["triangles"]
    assert len(imported.data.uv_layers) == 1
    # Recheck UV overlap after export/import, not just the in-memory source.
    imported.data.calc_tangents(uvmap=imported.data.uv_layers.active.name)
    _, roundtrip_uv = atlas(imported, entry["texture_checks"]["resolution"][0])
    exact_uv_overlap(imported)
    bpy.data.objects.remove(imported, do_unlink=True)
    return {"result": "PASS", "classic_import_bbox_blender": source_bounds.tolist(),
            "sample_import_bbox_blender": imported_bbox.tolist(),
            "bbox_error_max_studs": bbox_error, "raw_fbx_bbox_error_max_studs": raw_error,
            "vertex_position_error_max_studs": vertex_error, "fbx_unit_scale_factor": unit,
            "rendering_surface_position_error_max_studs": surface_error,
            "same_vertex_count": True, "same_rendering_surfaces": True,
            "removed_source_zero_area_triangles": entry["removed_source_zero_area_triangles"],
            "roundtrip_uv_overlap_interior_pixels": roundtrip_uv["overlap_interior_pixels"],
            "tolerance_studs": TOLERANCE}


def camera(location, target, scale):
    scene = bpy.context.scene
    cam = scene.camera
    if cam is None:
        cam = bpy.data.objects.new("Sample review camera", bpy.data.cameras.new("Sample review camera"))
        scene.collection.objects.link(cam)
        scene.camera = cam
    cam.location = location
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    cam.data.lens = 50
    return cam


def light(name, location, energy, size, target=(0, 0, 0)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.shape, data.size = energy, "DISK", size
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.seed = 1701
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.world = bpy.data.worlds.new("Neutral light grey review studio")
    scene.world.use_nodes = True
    bg = scene.world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (.72, .73, .75, 1)
    bg.inputs["Strength"].default_value = .4
    light("Large soft key", (-8, 3, 14), 1000, 7)
    light("Soft fill", (10, 5, 8), 350, 9)
    light("Fold rim light", (1, -10, 10), 650, 6)
    # A large matte ground gives a light grey background and soft contact shadows.
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -1.05))
    floor = bpy.context.object
    floor.name = "Review ground"
    mat = bpy.data.materials.new("Light grey ground")
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*linear((217, 219, 222)), 1)
    shader.inputs["Roughness"].default_value = 1
    floor.data.materials.append(mat)


def render_file(name, location, target, scale, width=1600, height=900):
    camera(location, target, scale)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.filepath = str(OUT / name)
    bpy.ops.render.render(write_still=True)


def preview_tint(objects, mode):
    for obj in objects:
        region = obj["region"]
        if mode == "classic":
            rgb = WHITE if region == "sticker" else (214, 200, 160) if region == "band" else RED if region == "accent" else PAPER
        else:
            rgb = WHITE if region in ("accent", "sticker") else (255, 212, 20) if region == "band" else TEAM_RED if mode == "red" else TEAM_BLUE
        set_tint(obj.data.materials[0], rgb)


def right_instances(objects):
    result = []
    for obj in objects:
        if obj["part"] == "pellet":
            name = obj.name + " right review instance"
            dup = bpy.data.objects.get(name)
            if dup is None:
                dup = obj.copy()
                dup.data = obj.data.copy()
                dup.name = name
                dup.location.x += 3.52
                dup["review_instance"] = True
                bpy.context.scene.collection.objects.link(dup)
            result.append(dup)
    return result


def _review_renders(objects, source_blend):
    """Render actual sidecar-map materials, with no extra procedural shading."""
    preview_tint(objects, "classic")
    whole = [o for o in objects if not o.get("side")]
    for obj in objects:
        obj.hide_render = bool(obj.get("side"))
    # Show both paper tubes, as in the old Classic renders.
    existing = set(bpy.data.objects)
    copies = right_instances(whole)
    display = whole + copies
    # Identical framing and physical lighting in the two halves of the compare.
    render_file("compare-threequarter.png", (-17, 24, 20), (0, 0, .45), 23, 800, 900)
    new_image = pixels(OUT / "compare-threequarter.png")
    # Fit the longest projected mesh span to exactly 250 pixels per plane.
    cam = camera((-17, 24, 20), (0, 0, .45), 26)
    bpy.context.view_layer.update()
    view_points = np.array([cam.matrix_world.inverted() @ (obj.matrix_world @ v.co)
                            for obj in display for v in obj.data.vertices])[:, :2]
    projected_span = max(np.linalg.norm(view_points - v, axis=1).max() for v in view_points)
    game_scale = float(projected_span * 500 / 250)
    render_file("game-distance.png", (-17, 24, 20), (0, 0, .45), game_scale, 500, 400)
    game_new = pixels(OUT / "game-distance.png")
    temporary_materials = []
    saved = {}
    for obj in display:
        saved[obj] = obj.data.materials[0]
        mat = bpy.data.materials.new("Old Classic flat " + obj.name)
        mat.use_nodes = True
        rgb = WHITE if obj["region"] == "sticker" else (214, 200, 160) if obj["region"] == "band" else RED if obj["region"] == "accent" else PAPER
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*linear(rgb), 1)
        bsdf.inputs["Roughness"].default_value = .855
        bsdf.inputs["Specular IOR Level"].default_value = .22
        obj.data.materials[0] = mat
        temporary_materials.append(mat)
    render_file("compare-threequarter.png", (-17, 24, 20), (0, 0, .45), 23, 800, 900)
    old_image = pixels(OUT / "compare-threequarter.png")
    render_file("game-distance.png", (-17, 24, 20), (0, 0, .45), game_scale, 500, 400)
    game_old = pixels(OUT / "game-distance.png")
    for obj, mat in saved.items():
        obj.data.materials[0] = mat
    for mat in temporary_materials:
        if mat.users == 0:
            bpy.data.materials.remove(mat)
    sheet = np.round(np.clip(np.concatenate((old_image, new_image), axis=1), 0, 1) * 255).astype(np.uint8)
    png(OUT / "compare-threequarter.png", sheet)
    sheet = np.round(np.clip(np.concatenate((game_old, game_new), axis=1), 0, 1) * 255).astype(np.uint8)
    png(OUT / "game-distance.png", sheet)

    # Existing team marker shapes are geometry, never symbols drawn in maps.
    shapes = {}
    with bpy.data.libraries.load(str(source_blend), link=False) as (src, dst):
        dst.objects = [name for name in src.objects if name in ("sticker-square", "sticker-circle")]
    for obj in dst.objects:
        shapes[obj.name] = obj
    for mode, shape in (("red", "sticker-square"), ("blue", "sticker-circle")):
        preview_tint(objects, mode)
        markers = []
        for obj in whole:
            if obj["region"] != "sticker":
                continue
            obj.hide_render = True
            marker = bpy.data.objects.new(mode + " white geometric marker", shapes[shape].data.copy())
            bpy.context.scene.collection.objects.link(marker)
            world_points = np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
            marker.location = (world_points.min(0) + world_points.max(0)) / 2
            marker.hide_render = False
            marker.data.uv_layers.new(name="PaperUV")
            # Project the placeholder atlas onto its replacement team shape.
            active(marker)
            transfer = marker.modifiers.new("Existing sticker UV projection", "DATA_TRANSFER")
            transfer.object = obj
            transfer.use_loop_data = True
            transfer.data_types_loops = {"UV"}
            transfer.loop_mapping = "POLYINTERP_NEAREST"
            bpy.ops.object.modifier_apply(modifier=transfer.name)
            marker.data.materials.clear()
            marker.data.materials.append(obj.data.materials[0])
            markers.append(marker)
        render_file("team-" + mode + ".png", (-17, 24, 20), (0, 0, .45), 20)
        for marker in markers:
            bpy.data.objects.remove(marker, do_unlink=True)
        for obj in whole:
            obj.hide_render = False
    for obj in shapes.values():
        bpy.data.objects.remove(obj, do_unlink=True)
    preview_tint(objects, "classic")
    render_file("closeup-wing.png", (-9, 6, 9), (-3.7, -1.1, .91), 7.5)
    render_file("closeup-nose.png", (-5.6, 10.8, 5.4), (0, 4.6, .35), 6.5)
    for dup in copies:
        if dup not in existing:
            bpy.data.objects.remove(dup, do_unlink=True)


def review_renders(objects, source_blend):
    # Classic's wing and body shoulders contain coincident faces. Their shadow
    # rays otherwise randomly hit the other surface, producing dark triangles.
    # This tiny temporary transform is equivalent to a review polygon offset.
    # Never apply it to the vertex data, FBXs, saved blend, or validation bounds.
    positions = {obj: obj.location.copy() for obj in objects if obj["part"] == "wings"}
    try:
        for obj in positions:
            obj.location.z -= .0003
        bpy.context.view_layer.update()
        _review_renders(objects, source_blend)
    finally:
        for obj, position in positions.items():
            obj.location = position
        bpy.context.view_layer.update()


def contact_sheet(entries):
    # One row per exported mesh, in manifest/README order. No drawn characters.
    cell, gutter = 256, 12
    sheet = np.full((len(entries) * (cell + gutter) + gutter, 3 * (cell + gutter) + gutter, 3), 224, dtype=np.uint8)
    for row, entry in enumerate(entries):
        for col, kind in enumerate(("color", "normal", "roughness")):
            a = pixels(OUT / entry["maps"][kind])[:, :, :3]
            yi = np.minimum((np.arange(cell) * a.shape[0] / cell).astype(int), a.shape[0] - 1)
            xi = np.minimum((np.arange(cell) * a.shape[1] / cell).astype(int), a.shape[1] - 1)
            thumb = np.round(np.clip(a[yi[:, None], xi[None, :]], 0, 1) * 255).astype(np.uint8)
            y, x = gutter + row * (cell + gutter), gutter + col * (cell + gutter)
            sheet[y:y + cell, x:x + cell] = thumb
    png(OUT / "maps-contact-sheet.png", sheet)


def readme(report):
    lines = ["# Classic folded-paper sample", "",
        "Local sample only. Original assets, code, config and place files are untouched. No uploads or commits.", "",
        "## Rebuild", "", "From D:/FlyFightPaper in PowerShell:", "", "```powershell", COMMAND, "```", "",
        "Only Blender 5.1 and its included NumPy are required. CPU rendering is deterministic. All outputs stay in this folder.", "",
        "## Review", "",
        "- compare-threequarter.png: OLD left, NEW right, 1600 x 900. Identical camera, scale and lights; old uses the exact original geometry and round-1 flat materials. Warm-white paper (238,230,212), red details (206,48,43).",
        "- game-distance.png: OLD left, NEW right, 1000 x 400. Each plane's longest projected mesh span is 250 pixels. Identical three-quarter camera and lights. Rendered at delivery size, never sharpened or enlarged.",
        "- team-red.png / team-blue.png: the exported maps multiplied by actual Aircraft.luau paper tints (235,40,50) / (25,115,255), with white accents and existing white square/circle geometry. Tape is yellow, matching the game.",
        "- closeup-wing.png / closeup-nose.png: actual exported maps on unchanged geometry, 1600 x 900.",
        "- maps-contact-sheet.png: every map, no drawn labels. Each row is listed below; columns are colour, normal, roughness.", "",
        "## Round 2 response to review", "",
        "1. Too similar at a distance: increased clean fold valley/ridge contrast, added bright thin outer rims and slight facet tone changes. The game-distance comparison is the small-scale check.",
        "2. Wood streaks and hammered nose: removed stretched fibre noise, coarse pulp and random broad bump noise. Replaced them with much finer equal-frequency tooth and a few smooth, extremely shallow handling marks. Broad panels stay clean.",
        "3. Missing folds: baked straight dark valleys with adjacent light ridges and paired normal slopes at the actual spine, body/wing folds, nose facets and tail folds. Whole-mesh feature references keep real folds across the split alternatives and prevent fake half-cut outlines. Coplanar diagonals and assembly/pigment boundaries are excluded.",
        "4. Plastic accents/stickers: accents now share the same tooth, fold and edge treatment as plain paper, including the shallow bend through each wing stripe. Stickers have finer tooth, lower roughness and a thin shading-only soft edge lift on their existing thickness. Rolled tube sides use continuous radial shading instead of long facet bands.", "",
        "## Material and geometry choices", "",
        "All colour maps have identical R/G/B channels: light neutral paper, subtle fibres, gentle real baked ambient occlusion. No prepainted team colour, text, logos or authored symbols. Atlas gutters have neutral opaque backgrounds, never black cut-out silhouettes.", "",
        "Removable sticker shapes are excluded from structural AO bakes. Their existing geometry casts its own matching shadow in review images, so the blue circle does not retain a square placeholder footprint in the wing map.", "",
        "Normals use Blender MikkTSpace tangents and the UV handedness, OpenGL +Y green up. Fine isotropic tooth has no preferred fibre direction. Clean valley/ridge pairs follow existing geometric folds, with a little matching colour contrast and broad facet tone. Cut edges get thin bright rims. Broad waves and a few soft dents are shallow, smooth and confined to shading. No displacement, added geometry or silhouette changes. Matte plain/coloured paper roughness is about 0.83-0.85; sticker paper about 0.55-0.57. Metalness should be 0.", "",
        "The edge-softening compromise is deliberate: normal-map shading instead of geometric bevels preserves every source vertex, seam and bounding box. It cannot round an outline or make a zero-angle grazing silhouette look curved. Existing paper thickness is retained.", "",
        "Some original half FBXs contain zero-area triangles from their centre cuts. Only those invisible faces are removed in the sample; their count is recorded per file. All original vertex coordinates and all real surface faces are retained.", "",
        "Classic also has coincident body/wing shoulder faces. Review images temporarily lower the wing regions by 0.0003 stud to stop Cycles shadow-ray interference. Both OLD and NEW receive the same subpixel separation. The saved Blender model, FBXs, UVs, pivots and verification bounds retain the exact original positions. Existing coplanarity remains an integration consideration.", "",
        "Whole and split meshes are alternative exports. Do not display both simultaneously. Every FBX in classic/ has a same-named sample. The two pellet files are included for completeness. Half-mesh local centring is preserved from the actual half FBXs, with assembly placement recorded from halves.json.", "",
        "Each mesh has its own non-overlapping PaperUV atlas, no mirrored/stacked charts. Large whole meshes use 1024; small and half meshes use 512 unless their surface area needs 1024. Gutters are 12 pixels. Tiny thin rim triangles naturally receive fewer pixels than the main paper surfaces.", "",
        "## Import contract", "",
        "FBX settings match Classic: Y up, -Z forward, global_scale=.01, UnitScaleFactor=1, raw vertex numbers in studs. Reimport with global_scale=100 only to cancel Blender's centimetre interpretation. Do not recenter the mesh or scale an accent to the whole slot. Copy slot_pivot and center_offset_from_slot from manifest.json; these are unchanged from the source records.", "",
        "Use each entry's color, normal and roughness PNG in SurfaceAppearance.ColorMap, NormalMap and RoughnessMap. Set SurfaceAppearance.Color to the desired runtime tint. Colour is sRGB; normal/roughness are non-colour data. Export materials are neutral. Blender review tints are preview settings only. Game tint integration and Studio review are outside this sample.", "",
        "## Meshes and contact-sheet rows", "",
        "| Row | FBX / map prefix | Region | Triangles | Texture size |", "|---:|---|---|---:|---:|"]
    for index, entry in enumerate(report["exports"], 1):
        lines.append(f"| {index} | {Path(entry['file']).stem} | {entry['region']} | {entry['triangles']} | {entry['texture_checks']['resolution'][0]} |")
    lines += ["", "Every row corresponds to <prefix>-color.png, <prefix>-normal.png, <prefix>-roughness.png, left to right.", "",
        "## Verification", "",
        f"All {len(report['exports'])} FBXs were re-imported. Local raw FBX bounds, imported bounds, vertex positions, vertex counts, rendering surfaces, units and UVs were compared with their actual Classic twins. Zero-area source faces are excluded. Tolerance {TOLERANCE} stud. Individual results are in manifest.json.", "",
        "UV validation includes positive UV triangle area, atlas bounds, independent strict-interior raster overlap checks and analytical triangle clipping to catch subpixel overlaps, repeated after FBX reimport. Source-file SHA-256 values are checked again after the build. No source is opened for writing.", "",
        "paper-sample.blend opens on the new assembled Classic with the same external maps used by the FBXs. Split alternatives are hidden. Images are also packed for portability, while the PNG sidecars remain the Roblox inputs.", ""]
    (OUT / "README.md").write_text("\n".join(lines), encoding="utf-8")


def verify_saved(report):
    """Independent checks of the on-disk exports and PNGs after a build."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for entry in report["exports"]:
        source = import_fbx(SOURCE / entry["file"])
        source_coords = coordinates(source)
        source_bbox = bounds(source)
        source_surfaces = rendering_surfaces(source)
        source_raw, source_unit = raw_fbx(SOURCE / entry["file"])
        bpy.data.objects.remove(source, do_unlink=True)
        sample = import_fbx(OUT / entry["file"])
        sample_surfaces = rendering_surfaces(sample)
        assert source_surfaces.shape == sample_surfaces.shape
        surface_error = float(np.max(np.abs(source_surfaces - sample_surfaces)))
        assert surface_error < TOLERANCE, entry["file"] + ": visible surface mismatch"
        assert len(source_coords) == len(sample.data.vertices)
        actual_bbox = bounds(sample)
        bbox_error = float(np.max(np.abs(actual_bbox - source_bbox)))
        assert bbox_error < TOLERANCE
        sample_raw, sample_unit = raw_fbx(OUT / entry["file"])
        assert source_unit == sample_unit == 1
        raw_error = float(np.max(np.abs(np.array([source_raw.min(0), source_raw.max(0)])
                                        - np.array([sample_raw.min(0), sample_raw.max(0)]))))
        assert raw_error < TOLERANCE
        uv_report = exact_uv_overlap(sample)
        entry["uv_checks"].update(uv_report)
        entry["fbx_roundtrip"].update({"classic_import_bbox_blender": source_bbox.tolist(),
            "sample_import_bbox_blender": actual_bbox.tolist(), "bbox_error_max_studs": bbox_error,
            "raw_fbx_bbox_error_max_studs": raw_error,
            "rendering_surface_position_error_max_studs": surface_error,
            "analytical_roundtrip_uv_overlap": "PASS"})
        bpy.data.objects.remove(sample, do_unlink=True)
        for kind, filename in entry["maps"].items():
            data = pixels(OUT / filename)[:, :, :3]
            assert list(data.shape[:2]) == entry["texture_checks"]["resolution"]
            if kind == "color":
                assert np.max(np.abs(data[:, :, 0] - data[:, :, 1])) < 1e-7
                assert np.max(np.abs(data[:, :, 0] - data[:, :, 2])) < 1e-7
                assert data.min() >= .84 and data.max() <= 1
            elif kind == "normal":
                decoded = data * 2 - 1
                error = float(np.max(np.abs(np.linalg.norm(decoded, axis=2) - 1)))
                assert error < .014, filename + ": non-unit tangent normal"
                assert decoded[:, :, 2].min() > 0
                entry["texture_checks"]["saved_normal_unit_length_error_max"] = error
            else:
                low, high = (.54, .58) if entry["region"] == "sticker" else (.82, .86)
                assert data.min() >= low and data.max() <= high
        log(entry["file"] + ": independent saved-file checks PASS")
    for filename in RENDERS:
        data = (OUT / filename).read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        width, height = struct.unpack(">II", data[16:24])
        if filename == "game-distance.png":
            assert (width, height) == (1000, 400)
        elif filename != "maps-contact-sheet.png":
            assert (width, height) == (1600, 900)
    for relative, expected in report["source_hashes"].items():
        assert sha(ROOT / relative) == expected, "Source changed: " + relative
    report["independent_saved_file_verification"] = "PASS"
    report["script_sha256"] = sha(Path(__file__))
    report["result"] = "PASS"
    readme(report)
    (OUT / "manifest.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--renders-only", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    if args.verify_only:
        verify_saved(json.loads((OUT / "manifest.json").read_text()))
        return
    if args.renders_only:
        bpy.ops.wm.open_mainfile(filepath=str(OUT / "paper-sample.blend"))
        report = json.loads((OUT / "manifest.json").read_text())
        objects = [bpy.data.objects[e["object"]] for e in report["exports"]]
        review_renders(objects, SOURCE / "classic.blend")
        contact_sheet(report["exports"])
        report["render_only_coplanar_separation_studs"] = .0003
        verify_saved(report)
        return
    # The manifest is written only after the new build has actually passed.
    manifest_path = OUT / "manifest.json"
    if manifest_path.exists():
        manifest_path.unlink()
    contract = json.loads((SOURCE / "parts.json").read_text())
    entries_by_file = {e["file"]: e for e in contract["exports"]}
    halves_path = ROOT / "assets/models/planes/halves.json"
    for entry in json.loads(halves_path.read_text())["exports"]:
        if (SOURCE / entry["file"]).exists():
            entries_by_file[entry["file"]] = entry
    source_files = sorted(SOURCE.glob("*.fbx"))
    assert set(p.name for p in source_files) == set(entries_by_file), "Classic file/region contract mismatch"
    immutable_paths = source_files + [SOURCE / "parts.json", SOURCE / "classic.blend", halves_path,
                                      ROOT / "tools/art/planes.py", ROOT / "src/shared/Aircraft.luau"]
    before_hashes = {str(p.relative_to(ROOT)).replace("\\", "/"): sha(p) for p in immutable_paths}
    # Inspect the blend source as well as the FBXs, without running its builder.
    with bpy.data.libraries.load(str(SOURCE / "classic.blend"), link=False) as (src, dst):
        blend_mesh_names = list(src.meshes)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1  # AO node itself samples 24 rays per surface texel.
    scene.cycles.seed = 1701
    scene.world = bpy.data.worlds.new("Bake world")
    scene.render.bake.use_selected_to_active = False
    objects, originals = [], {}
    for path in source_files:
        obj = import_fbx(path)
        obj.name = path.stem
        entry = entries_by_file[path.name]
        obj["part"], obj["region"] = entry["part"], entry["region"]
        obj["side"] = entry.get("side", "")
        original_coords = coordinates(obj)
        original_raw, unit = raw_fbx(path)
        original_surfaces = rendering_surfaces(obj)
        source_count, removed_count = remove_invisible_faces(obj)
        obj["source_triangles"] = source_count
        obj["removed_source_zero_area_triangles"] = removed_count
        assert unit == 1
        offset = np.array(entry["slot_pivot"], dtype=float)
        if entry.get("side"):
            # split_halves recentres X only; Y/Z remain relative to the slot.
            offset[0] = entry["bbox_center"][0]
        obj.location = bvec(offset)
        for face in obj.data.polygons:
            face.use_smooth = False
        objects.append(obj)
        originals[obj.name] = (original_coords, original_raw, original_surfaces)
    bpy.context.view_layer.update()
    FEATURES.clear()
    FEATURES.update({obj.name: feature_edges(obj) for obj in objects if not obj.get("side")})
    bake_instances = right_instances(objects)
    exports = []
    for obj in objects:
        entry = dict(entries_by_file[obj.name + ".fbx"])
        whole_name = obj.name[:-2] if obj.get("side") else obj.name
        for other in objects:
            other.hide_render = bool(other.get("side"))
            if obj.get("side") and other.name == whole_name:
                other.hide_render = True
        obj.hide_render = False
        obj.data.calc_loop_triangles()
        entry["triangles"] = len(obj.data.loop_triangles)
        entry["source_triangles"] = obj["source_triangles"]
        entry["removed_source_zero_area_triangles"] = obj["removed_source_zero_area_triangles"]
        assert entry["triangles"] < 1500
        area = sum(face.area for face in obj.data.polygons)
        resolution = 1024 if area > 48 else 512
        log(f"Baking {obj.name}: {entry['triangles']} triangles, {resolution}px")
        uv_report, texture_report = make_maps(obj, resolution)
        mat = paper_material(obj, entry["region"])
        set_tint(mat, (255, 255, 255))
        entry.update({"object": obj.name, "maps": {k: obj.name + "-" + k + ".png" for k in ("color", "normal", "roughness")},
                      "uv_checks": uv_report, "texture_checks": texture_report,
                      "assembly_location_blender": list(obj.location), "surface_appearance_tintable": True,
                      "classic_source": "../classic/" + entry["file"]})
        entry["fbx_roundtrip"] = export_check(obj, entry, *originals[obj.name])
        exports.append(entry)
        log(obj.name + ": maps and FBX roundtrip PASS")
    for obj in objects:
        obj.hide_render = bool(obj.get("side"))
        obj.hide_set(bool(obj.get("side")))
    for dup in bake_instances:
        source = next(obj for obj in objects if dup.name == obj.name + " right review instance")
        dup.data = source.data.copy()
    setup_render()
    preview_tint(objects, "classic")
    camera((-17, 24, 20), (0, 0, .45), 20)
    scene.render.resolution_x, scene.render.resolution_y = 1600, 900
    # Pack copies of the exact sidecars, and retain simple local relative paths.
    for im in bpy.data.images:
        if im.source == "FILE" and not im.packed_file:
            im.pack()
            im.filepath = "//" + Path(im.filepath).name
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_location = (0, 0, .3)
                area.spaces.active.region_3d.view_distance = 24
                area.spaces.active.shading.type = "MATERIAL"
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "paper-sample.blend"), check_existing=False)
    backup = OUT / "paper-sample.blend1"
    if backup.exists():
        backup.unlink()
    review_renders(objects, SOURCE / "classic.blend")
    contact_sheet(exports)
    for path in immutable_paths:
        assert sha(path) == before_hashes[str(path.relative_to(ROOT)).replace("\\", "/")], "Source changed: " + str(path)
    report = {"schema_version": 2, "result": "PASS", "sample": "Classic folded paper, round 2",
        "rebuild_command": COMMAND, "blender_version": bpy.app.version_string,
        "units": contract["units"], "axes": contract["axes"], "source_hashes": before_hashes,
        "classic_blend_meshes_read": blend_mesh_names, "fbx_contract": contract["fbx_contract"],
        "exports": exports, "max_triangles": max(e["triangles"] for e in exports),
        "geometry": "Unchanged source vertices and flat mesh normals; softened edges and grain baked into tangent maps",
        "source_files_unchanged": True, "render_files": RENDERS,
        "game_distance": {"resolution": [1000, 400], "layout": "OLD left, NEW right",
                          "plane_projected_longest_span_pixels": 250},
        "render_only_coplanar_separation_studs": .0003,
        "review_tints": {"comparison_paper": PAPER, "comparison_accent": RED,
                         "team_red_paper": TEAM_RED, "team_blue_paper": TEAM_BLUE, "team_accents": WHITE},
        "network_uploads_studio": "Not used"}
    for name in RENDERS:
        assert (OUT / name).exists()
    readme(report)
    manifest_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    verify_saved(report)
    log(f"COMPLETE: {len(exports)} FBXs, {len(exports) * 3} maps, blend, README and seven review images")


if __name__ == "__main__":
    main()
    bpy.data.orphans_purge(do_recursive=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
