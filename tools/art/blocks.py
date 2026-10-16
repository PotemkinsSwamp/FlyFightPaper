"""Build textured classroom buildings in Blender, in studs, Z up, front -Y.

Run from the repository root:
& 'D:/Blender/blender.exe' -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/blocks.py -- sticky-note-tower

Only this script's named building folder is written. No network, external
packages, credentials, Studio, or other building generators are used.
Pass one of the fourteen building names. Each requires its own measured sizes.md.
Repeated material faces share UV charts; selected broad fronts have separate cap
charts. Closed pieces split at atlas/triangle limits and retain the base origin.
"""

import hashlib
import json
import math
import struct
import sys
import time
import zlib
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


ROOT = Path(__file__).resolve().parents[2]
SIZE = 1024
LIMIT = 12000
PAD_WIDTH = 72.0
PAD_HEIGHT = 31.5
COLORS = ("F5D630", "F06FA6", "45A6E6", "7DC84A", "F7902F", "F5D630")
ANGLES = (0, 4, -3, 4, -4, 3)
# Pixel rectangles, measured from the lower left. All charts have solid-color
# gutters; empty atlas space is paper-colored, never a black silhouette.
PATCHES = {
    "paper-side": (8, 8, 504, 252),
    "paper-front": (520, 8, 504, 252),
    "paper-top": (8, 276, 504, 504),
    "cardboard": (520, 280, 288, 284),
    "glass": (832, 280, 112, 112),
    "door": (520, 584, 104, 192),
    "knob": (640, 584, 40, 40),
    "brick-blue": (696, 584, 96, 96),
    "brick-yellow": (808, 584, 96, 96),
    "brick-red": (696, 708, 144, 100),
    "glass-reveal": (920, 584, 96, 96),
    "door-reveal": (520, 792, 104, 216),
}


def log(message):
    print("BLOCKS " + message, flush=True)


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply(obj, modifier):
    active(obj)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def mesh(name, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    return obj


def soften(obj, radius=.10, segments=2):
    if radius<=0:
        return obj
    mod = obj.modifiers.new("Small real edge bevel", "BEVEL")
    mod.width, mod.segments = radius, 8 if radius>2 else segments
    apply(obj, mod)
    for face in obj.data.polygons:
        face.use_smooth = max(abs(v) for v in face.normal)<.99999
    return obj


def box(name, dimensions, center, radius=.10):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if radius:
        soften(obj, radius)
    return obj


def uv_project(obj, patch, density=8, paper=False):
    """Box charts with intentional reuse, including opposite uniform faces.

    Projection follows the dominant face normal. Bevels have at least 0.707
    of the planar scale, so their area-equivalent density is still above six.
    Paper side U follows the face tangent, V follows the actual sheet height.
    """
    for old in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(old)
    uv = obj.data.uv_layers.new(name="BlockUV")
    coords = np.array([vert.co[:] for vert in obj.data.vertices])
    center = (coords.min(0) + coords.max(0)) / 2
    for face in obj.data.polygons:
        axis = int(np.argmax(np.abs(face.normal)))
        if paper:
            key = "paper-top" if axis == 2 else (
                "paper-front" if axis == 1 and face.normal.y < 0 else "paper-side")
            x, y, width, height = PATCHES[key]
        else:
            x, y, width, height = PATCHES[patch]
        for loop in face.loop_indices:
            co = obj.data.vertices[obj.data.loops[loop].vertex_index].co
            if axis == 2:
                u, v = co.x, co.y
            elif axis == 1:
                u, v = co.x * (-1 if face.normal.y > 0 else 1), co.z
            else:
                u, v = co.y * (1 if face.normal.x > 0 else -1), co.z
            if paper:
                u += PAD_WIDTH / 2
                v += PAD_WIDTH / 2 if axis == 2 else 0
                px, py = x + u * 7, y + v * 7
            else:
                # Map relative to this component, rather than its position.
                uc = center[0] if axis != 0 else center[1]
                if axis == 1 and face.normal.y > 0:
                    uc *= -1
                if axis == 0 and face.normal.x < 0:
                    uc *= -1
                vc = center[1] if axis == 2 else center[2]
                px, py = x + width / 2 + (u - uc) * density, y + height / 2 + (v - vc) * density
            uv.data[loop].uv = (px / SIZE, py / SIZE)
    obj.data.update()
    return obj


def uv_smart(obj, patch):
    """Pack a fitting into its reusable material patch at uniform scale."""
    active(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.018,
                             area_weight=0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    layer = obj.data.uv_layers.active
    layer.name = "BlockUV"
    coords = np.array([loop.uv[:] for loop in layer.data])
    lo, hi = coords.min(0), coords.max(0)
    x, y, width, height = PATCHES[patch]
    scale = min((width - 8) / (hi[0] - lo[0]), (height - 8) / (hi[1] - lo[1]))
    coords = (coords - (lo + hi) / 2) * scale + (x + width / 2, y + height / 2)
    layer.data.foreach_set("uv", (coords / SIZE).astype(np.float32).ravel())
    return obj


def paint_reveals(body, openings):
    """Colour the closed recess walls to avoid a paper-coloured glass rim."""
    uv = body.data.uv_layers.active.data
    for x, z, width, height, side, patch in openings:
        inverse = Matrix.Rotation(-side * math.pi / 2, 4, "Z")
        px, py, chart_width, chart_height = PATCHES[patch]
        for face in body.data.polygons:
            center, normal = inverse @ face.center, inverse.to_3x3() @ face.normal
            if not (-PAD_WIDTH / 2 - .02 <= center.y <= -PAD_WIDTH / 2 + .67
                    and abs(center.x - x) <= width / 2 + .02
                    and abs(center.z - z) <= height / 2 + .02
                    and abs(normal.y) < .5):
                continue
            axis = int(np.argmax(np.abs(normal)))
            for loop in face.loop_indices:
                co = inverse @ body.data.vertices[body.data.loops[loop].vertex_index].co
                u = co.x - x if axis == 2 else co.y + PAD_WIDTH / 2
                v = co.y + PAD_WIDTH / 2 if axis == 2 else co.z - z
                uv[loop].uv = ((px + chart_width / 2 + u * 9) / SIZE,
                               (py + chart_height / 2 + v * 9) / SIZE)


def turn(obj, angle):
    obj.data.transform(Matrix.Rotation(angle, 4, "Z"))
    obj.data.update()
    return obj


def cut_pocket(body, x, z, width, height, side):
    """A genuine 0.65-stud recess, with closed back and reveal faces."""
    cutter = box("Temporary recess cutter", (width, 2.0, height), (x, -PAD_WIDTH / 2 - .35, z), 0)
    turn(cutter, side * math.pi / 2)
    mod = body.modifiers.new("Recessed glazing pocket", "BOOLEAN")
    mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
    apply(body, mod)
    bpy.data.objects.remove(cutter, do_unlink=True)


def paper_pad(seed):
    """105 sheets: slight real silhouette variation plus finer baked grooves."""
    vertices, faces = [], []
    levels = 105
    for index in range(levels + 1):
        z = index * .3
        offset = 0 if index in (0, levels) else .026 * math.sin(index * 2.173 + seed)
        half, corner = PAD_WIDTH / 2 + offset, .12
        ring = ((-half + corner, -half), (half - corner, -half),
                (half, -half + corner), (half, half - corner),
                (half - corner, half), (-half + corner, half),
                (-half, half - corner), (-half, -half + corner))
        vertices.extend((x, y, z) for x, y in ring)
        if index:
            for j in range(8):
                a, b = (index - 1) * 8 + j, (index - 1) * 8 + (j + 1) % 8
                faces.append((a, b, b + 8, a + 8))
    faces.extend((tuple(reversed(range(8))), tuple(levels * 8 + j for j in range(8))))
    return mesh("Sticky-note pad", vertices, faces)


def frame(name, width, height, inner_width, inner_height, center, door=False):
    """A closed, extruded cardboard ring, or a single closed U-shaped jamb."""
    x, y, z = center
    depth = 1.6
    if door:
        profile = ((-width / 2, 0), (-inner_width / 2, 0),
                   (-inner_width / 2, inner_height), (inner_width / 2, inner_height),
                   (inner_width / 2, 0), (width / 2, 0),
                   (width / 2, height), (-width / 2, height))
        vertices = [(x + u, y + d, z + v) for d in (-depth / 2, depth / 2) for u, v in profile]
        faces = [tuple(reversed(range(8))), tuple(range(8, 16))]
        faces.extend((j, (j + 1) % 8, (j + 1) % 8 + 8, j + 8) for j in range(8))
    else:
        outer = ((-width / 2, -height / 2), (width / 2, -height / 2),
                 (width / 2, height / 2), (-width / 2, height / 2))
        inner = ((-inner_width / 2, -inner_height / 2), (inner_width / 2, -inner_height / 2),
                 (inner_width / 2, inner_height / 2), (-inner_width / 2, inner_height / 2))
        vertices = [(x + u, y + d, z + v) for d in (-depth / 2, depth / 2)
                    for ring in (outer, inner) for u, v in ring]
        faces = []
        for j in range(4):
            k = (j + 1) % 4
            faces.extend(((j, k, k + 4, j + 4), (j + 8, j + 12, k + 12, k + 8),
                          (j, j + 8, k + 8, k), (j + 4, k + 4, k + 12, j + 12)))
    return uv_smart(soften(mesh(name, vertices, faces), .10), "cardboard")


def window(body, x, side):
    z = PAD_HEIGHT / 2
    cut_pocket(body, x, z, 10.02, 10.02, side)
    trim = frame("15 x 15 cardboard window", 15, 15, 10, 10, (x, -PAD_WIDTH / 2 - .7, z))
    glass = uv_project(box("9.5 x 9.5 recessed blue glass", (9.5, .18, 9.5),
                           (x, -PAD_WIDTH / 2 + .59, z), .035),
                       "glass", density=9)
    return [turn(obj, side * math.pi / 2) for obj in (trim, glass)]


def door(body, x=-3):
    # Keep the pocket's lower edge above the pad's bottom to retain a closed
    # paper shell. The red panel still measures exactly 11 x 23 from ground.
    cut_pocket(body, x, 11.51, 11.02, 22.98, 0)
    trim = frame("17 x 26 cardboard doorway", 17, 26, 11, 23,
                 (x, -PAD_WIDTH / 2 - .7, 0), door=True)
    panel = uv_project(box("11 x 23 red door", (11, .18, 23),
                           (x, -PAD_WIDTH / 2 + .59, 11.5), .06), "door")
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=.8,
                                       location=(x + 11 * .3, -PAD_WIDTH / 2 - .08, 11.5))
    knob = bpy.context.object
    knob.name = "1.6 yellow door knob"
    active(knob)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    uv_smart(knob, "knob")
    for face in knob.data.polygons:
        face.use_smooth = True
    return [trim, panel, knob]


def toy_brick(name, width, depth, center, color, columns=2, rows=2):
    x, y, z = center
    body = uv_project(box(name, (width, depth, 4), center, .13), "brick-" + color, 9)
    pieces = [body]
    for row in range(rows):
        for col in range(columns):
            sx = x + (col - (columns - 1) / 2) * (width / columns)
            sy = y + (row - (rows - 1) / 2) * (depth / rows)
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.18, depth=.78,
                                               location=(sx, sy, z + 2 + .39))
            stud = bpy.context.object
            stud.name = "Round toy-brick stud"
            active(stud)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            soften(stud, .07)
            uv_smart(stud, "brick-" + color)
            for face in stud.data.polygons:
                face.use_smooth = abs(face.normal.z) < .99
            pieces.append(stud)
    return pieces


def doorstep(x=-3):
    parts = []
    for index, color in enumerate(("blue", "yellow", "yellow", "blue")):
        parts.extend(toy_brick("10 x 7 bottom brick", 10, 7,
                               (x - 15 + index * 10, -PAD_WIDTH / 2 - 4.1, 2), color))
    parts.extend(toy_brick("14 x 5 upper red brick", 14, 5,
                           (x, -PAD_WIDTH / 2 - 3.1, 6.78), "red", columns=3, rows=1))
    return parts


def join_piece(parts, label, index):
    active(parts[0])
    for obj in parts:
        obj.select_set(True)
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = label
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    transform = Matrix.Translation((0, 0, index * PAD_HEIGHT)) @ Matrix.Rotation(math.radians(ANGLES[index]), 4, "Z")
    obj.data.transform(transform)
    obj.data.update()
    return obj


def sticky_note_tower():
    objects = []
    names = ("yellow-ground-pad", "pink-pad", "blue-pad", "green-pad", "orange-pad", "yellow-roof-pad")
    for index, label in enumerate(names):
        log("modeling " + label)
        body = paper_pad(index)
        fittings, openings = [], []
        for side in range(4):
            centers = (-21, 16) if index == 0 and side == 0 else (-15, 15)
            for x in centers:
                fittings.extend(window(body, x, side))
                openings.append((x, PAD_HEIGHT / 2, 10.02, 10.02, side, "glass-reveal"))
        if index == 0:
            fittings.extend(door(body))
            fittings.extend(doorstep())
            openings.append((-3, 11.51, 11.02, 22.98, 0, "door-reveal"))
        uv_project(body, "paper-side", paper=True)
        paint_reveals(body, openings)
        objects.append(join_piece([body] + fittings, label, index))
    return objects


def rgb(value):
    return np.array([int(value[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


def replace_output(pending, path):
    """Windows can briefly reject an overwrite just after another build."""
    for attempt in range(6):
        try:
            pending.replace(path)
            return
        except OSError:
            if attempt == 5:
                raise
            time.sleep(2)


def write_output(path, payload):
    pending = path.with_name("pending-" + path.name)
    for attempt in range(6):
        try:
            pending.write_bytes(payload)
            break
        except OSError:
            if attempt == 5:
                raise
            time.sleep(2)
    replace_output(pending, path)


def png_write(path, pixels):
    """Write exact 8-bit sRGB colors or raw OpenGL normal/roughness bytes."""
    height, width, channels = pixels.shape
    assert channels == 3
    def chunk(tag, payload):
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xffffffff)
    raw = b"".join(b"\0" + row.tobytes() for row in pixels)
    write_output(path, b"\x89PNG\r\n\x1a\n" +
                 chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) +
                 chunk(b"IDAT", zlib.compress(raw, 7)) + chunk(b"IEND", b""))


def png_read(path):
    """Read 8-bit RGB/RGBA PNG bytes without Blender's lazy image buffers."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "Expected PNG"
    offset, compressed = 8, []
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        tag = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        if tag == b"IHDR":
            width, height, bits, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
            assert bits == 8 and color_type in (2, 6) and compression == filtering == interlace == 0
        elif tag == b"IDAT":
            compressed.append(payload)
        elif tag == b"IEND":
            break
        offset += length + 12
    channels = 3 if color_type == 2 else 4
    stride = width * channels
    raw = zlib.decompress(b"".join(compressed))
    assert len(raw) == height * (stride + 1), "Incomplete PNG"
    pixels = np.empty((height, width, channels), dtype=np.uint8)
    previous = bytearray(stride)
    for row in range(height):
        offset = row * (stride + 1)
        kind, current = raw[offset], bytearray(raw[offset + 1:offset + 1 + stride])
        assert kind <= 4, "Unknown PNG filter"
        if kind:
            for index in range(stride):
                left = current[index - channels] if index >= channels else 0
                up = previous[index]
                upper_left = previous[index - channels] if index >= channels else 0
                if kind == 1:
                    predictor = left
                elif kind == 2:
                    predictor = up
                elif kind == 3:
                    predictor = (left + up) // 2
                else:
                    prediction = left + up - upper_left
                    a, b, c = abs(prediction - left), abs(prediction - up), abs(prediction - upper_left)
                    predictor = left if a <= b and a <= c else (up if b <= c else upper_left)
                current[index] = (current[index] + predictor) & 255
        pixels[row] = np.frombuffer(current, dtype=np.uint8).reshape(width, channels)
        previous = current
    return pixels[:, :, :3]


def paper_cardboard_materials(paper_color, seed):
    """Procedural paint recipes, evaluated in UV space for a stable bake.

    Height derivatives are in studs. The baker converts them to tangent-space
    OpenGL (+Y) normals. A separate geometry ray pass adds only soft contact
    occlusion, with no directional lighting burned into the color map.
    """
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    color = np.broadcast_to(rgb(paper_color), (SIZE, SIZE, 3)).copy()
    normal = np.zeros((SIZE, SIZE, 3), dtype=float)
    normal[:, :, 2] = 1
    roughness = np.full((SIZE, SIZE), .78)
    rng = np.random.default_rng(2700 + seed)
    grain = rng.normal(0, 1, (SIZE, SIZE))
    for name, (x, y, width, height) in PATCHES.items():
        mask = (xx >= x - 5) & (xx < x + width + 5) & (yy >= y - 5) & (yy < y + height + 5)
        recipe_scale = 7 if name.startswith("paper-") else 8
        u, v = (xx - x) / recipe_scale, (yy - y) / recipe_scale
        du, dv = np.zeros((SIZE, SIZE)), np.zeros((SIZE, SIZE))
        if name in ("paper-side", "paper-front"):
            # One line per 0.3-stud sheet, with a small horizontal wander.
            phase = 2 * math.pi * (v / .3 + .045 * np.sin(u * .91) + .018 * np.sin(u * 3.1))
            sheet = np.floor(v / .3)
            sheet_tint = np.sin(sheet * 12.9898 + seed * 1.31) * .018
            tint = .955 + .100 * np.cos(phase) + sheet_tint + grain * .008
            base, rough = rgb(paper_color), .79
            du = -.026 * np.cos(phase) * 2 * math.pi * (.045 * .91 * np.cos(u * .91) + .018 * 3.1 * np.cos(u * 3.1))
            dv = -.026 * np.cos(phase) * 2 * math.pi / .3
        elif name == "paper-top":
            base, rough = rgb(paper_color), .76
            tint = .999 + grain * .005 + .003 * np.sin(u * 7.1 + v * 11.3)
            du, dv = grain * .004, grain * .003
        elif name == "cardboard":
            base, rough = rgb("B99260"), .88
            fibers = np.sin(u * 33.1 + np.sin(v * 6)) * np.sin(v * 43.7)
            tint = 1 + grain * .025 + fibers * .019 + .022 * np.sin(u * .7) * np.sin(v * 1.3)
            du = .017 * np.sin(u * 33.1 + v * 2.4) + grain * .012
            dv = .024 * np.sin(v * 43.7) + grain * .012
        else:
            material_name = name.removesuffix("-reveal")
            base, rough = {
                "glass": (rgb("2F6FC8"), .46), "door": (rgb("D42A20"), .52),
                "knob": (rgb("FFD52A"), .30), "brick-blue": (rgb("087CCB"), .29),
                "brick-yellow": (rgb("FFD12D"), .30), "brick-red": (rgb("D42A20"), .30),
            }[material_name]
            tint = 1 + grain * (.009 if material_name == "door" else .003)
            if material_name == "door":
                tint += .011 * np.sin(v * 5.7 + u * .4)
                du, dv = grain * .006, grain * .009
            else:
                du, dv = grain * .002, grain * .002
        color[mask] = np.clip((tint[:, :, None] * base)[mask], 0, 255)
        roughness[mask] = (rough + grain * .008)[mask]
        normals = np.stack((-du, -dv, np.ones((SIZE, SIZE))), axis=-1)
        normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
        normal[mask] = normals[mask]
    return {
        "color": np.rint(color).astype(np.uint8),
        "normal": np.rint((normal * .5 + .5) * 255).astype(np.uint8),
        "roughness": np.repeat(np.rint(np.clip(roughness, 0, 1) * 255).astype(np.uint8)[:, :, None], 3, axis=2),
    }


def assembly_bvh(objects):
    """Ray-test the real closed meshes, including neighbouring pad contacts."""
    vertices, triangles = [], []
    for obj in objects:
        offset = len(vertices)
        vertices.extend(vertex.co[:] for vertex in obj.data.vertices)
        triangles.extend(tuple(offset + index for index in face.vertices) for face in obj.data.polygons)
    return BVHTree.FromPolygons(vertices, triangles, all_triangles=True)


def ambient_occlusion(obj, tree, resolution=256, samples=24, front_priority=False):
    """Bake cosine-weighted hemisphere visibility into the shared UV atlas.

    Soft contact shading needs fewer samples than the fine paper paint. A
    256-pixel ray pass is blurred and interpolated to the 1024-pixel atlas.
    Repeated fittings use a representative outward face. Top/bottom reuse
    always samples the top, so the roof cannot inherit a hidden underside.
    The front wall has its own chart for the ground floor's door arrangement.
    """
    distance, strength = 4.0, .24
    positions = np.zeros((resolution, resolution, 3), dtype=np.float32)
    normals = np.zeros_like(positions)
    priorities = np.full((resolution, resolution), -np.inf)
    uv = obj.data.uv_layers.active.data
    for face in obj.data.polygons:
        tex = np.array([uv[index].uv[:] for index in face.loop_indices]) * resolution
        low = np.maximum(np.floor(tex.min(0)).astype(int), 0)
        high = np.minimum(np.ceil(tex.max(0)).astype(int), resolution - 1)
        if np.any(high < low):
            continue
        a, b = tex[1] - tex[0], tex[2] - tex[0]
        determinant = a[0] * b[1] - a[1] * b[0]
        if abs(determinant) < 1e-9:
            continue
        yy, xx = np.mgrid[low[1]:high[1] + 1, low[0]:high[0] + 1]
        delta = np.stack((xx + .5, yy + .5), axis=-1) - tex[0]
        u = (delta[:, :, 0] * b[1] - delta[:, :, 1] * b[0]) / determinant
        v = (a[0] * delta[:, :, 1] - a[1] * delta[:, :, 0]) / determinant
        normal = np.array(face.normal[:])
        priority = (-normal[1]*4+normal[2]*.5+normal[0]*.25 if front_priority else
                    normal[2]*4-normal[1]*2+normal[0])
        target = np.s_[low[1]:high[1] + 1, low[0]:high[0] + 1]
        mask = (u >= -1e-6) & (v >= -1e-6) & (u + v <= 1 + 1e-6) & (priority > priorities[target])
        points = np.array([obj.data.vertices[index].co[:] for index in face.vertices])
        interpolated = points[0] + u[:, :, None] * (points[1] - points[0]) + v[:, :, None] * (points[2] - points[0])
        positions[target][mask] = interpolated[mask]
        normals[target][mask] = normal
        priorities[target][mask] = priority
    occupied = np.isfinite(priorities)
    values = np.ones((resolution, resolution), dtype=np.float32)
    directions = []
    for index in range(samples):
        radius = math.sqrt((index + .5) / samples)
        angle = index * math.pi * (3 - math.sqrt(5))
        directions.append((radius * math.cos(angle), radius * math.sin(angle), math.sqrt(1 - radius * radius)))
    log("ray baking soft ambient occlusion for " + obj.name)
    for y, x in zip(*np.nonzero(occupied)):
        normal = Vector(normals[y, x])
        tangent = normal.cross(Vector((0, 0, 1)) if abs(normal.z) < .9 else Vector((0, 1, 0))).normalized()
        bitangent = normal.cross(tangent)
        start = Vector(positions[y, x]) + normal * .055
        occlusion = 0
        for u, v, w in directions:
            hit, _, _, hit_distance = tree.ray_cast(start, tangent * u + bitangent * v + normal * w, distance)
            if hit is not None:
                occlusion += math.exp(-hit_distance / 1.6)
        values[y, x] = 1 - strength * occlusion / samples
    # Extend chart edges before the soft blur; unused paper-coloured gutters
    # stay light and cannot produce black seams under texture filtering.
    weight = occupied.astype(np.float32)
    weighted = values * weight
    for _ in range(3):
        weighted = (weighted * 4 + np.roll(weighted, 1, 0) + np.roll(weighted, -1, 0)
                    + np.roll(weighted, 1, 1) + np.roll(weighted, -1, 1)) / 8
        weight = (weight * 4 + np.roll(weight, 1, 0) + np.roll(weight, -1, 0)
                  + np.roll(weight, 1, 1) + np.roll(weight, -1, 1)) / 8
    values = np.divide(weighted, weight, out=np.ones_like(weighted), where=weight > 1e-6)
    coordinates = (np.arange(SIZE) + .5) * resolution / SIZE - .5
    values = np.array([np.interp(coordinates, np.arange(resolution), row) for row in values])
    values = np.array([np.interp(coordinates, np.arange(resolution), column) for column in values.T]).T
    return values


def bake(obj, folder, prefix, paper_color, seed, tree):
    """Bake the procedural paint and height recipes into a 1024 RGB atlas.

    Evaluation is deterministic inside Blender's Python runtime. UV reuse
    keeps repeated details sharp. A geometry ray bake adds light ambient
    occlusion around the pad seams, frames, door and toy-brick studs.
    PNG scanlines are top-down, while the recipe's UV coordinates are bottom-up.
    """
    maps = paper_cardboard_materials(paper_color, seed)
    occlusion = ambient_occlusion(obj, tree)
    maps["color"] = np.rint(maps["color"] * occlusion[:, :, None]).clip(0, 255).astype(np.uint8)
    obj["baked_ao_minimum"] = round(float(occlusion.min()), 4)
    material = bpy.data.materials.new(obj.name + " color normal roughness")
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Specular IOR Level"].default_value = .26
    shader.inputs["Metallic"].default_value = 0
    for channel, pixels in maps.items():
        path = folder / (prefix + "-" + channel + ".png")
        png_write(path, np.flipud(pixels).copy())
        image = bpy.data.images.load(str(path), check_existing=False)
        image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
        image.pack()
        texture = nodes.new("ShaderNodeTexImage")
        texture.name, texture.image = channel, image
        if channel == "normal":
            bump = nodes.new("ShaderNodeNormalMap")
            bump.space, bump.uv_map = "TANGENT", "BlockUV"
            links.new(texture.outputs["Color"], bump.inputs["Color"])
            links.new(bump.outputs["Normal"], shader.inputs["Normal"])
        else:
            links.new(texture.outputs["Color"], shader.inputs["Base Color" if channel == "color" else "Roughness"])
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for face in obj.data.polygons:
        face.material_index = 0
    return maps


def geometry_checks(obj):
    assert obj.type == "MESH" and len(obj.data.polygons), "Empty piece"
    assert len(obj.data.materials) == len(obj.data.uv_layers) == 1
    assert all(len(face.vertices) == 3 for face in obj.data.polygons), "Not triangulated"
    assert len(obj.data.polygons) <= LIMIT, (obj.name, "Triangle budget exceeded")
    assert obj.location.length < 1e-6 and obj.rotation_euler.to_matrix().is_identity
    assert all(abs(value - 1) < 1e-6 for value in obj.scale)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    boundary = sum(edge.is_boundary for edge in bm.edges)
    nonmanifold = sum(not edge.is_manifold for edge in bm.edges)
    loose = sum(not vert.link_faces for vert in bm.verts)
    volume = bm.calc_volume(signed=True)
    bm.free()
    assert boundary == nonmanifold == loose == 0, (obj.name, boundary, nonmanifold, loose)
    assert volume > 0
    co = np.array([vertex.co[:] for vertex in obj.data.vertices])
    triangles = np.array([face.vertices[:] for face in obj.data.polygons])
    assert len(np.unique(np.sort(triangles, axis=1), axis=0)) == len(triangles), "Duplicate triangles"
    return {"label": obj.name, "triangles": len(triangles),
            "bounding_box": {"min": co.min(0).round(5).tolist(), "max": co.max(0).round(5).tolist()},
            "boundary_edges": boundary, "nonmanifold_edges": nonmanifold, "origin": [0, 0, 0]}


def density(obj, axis=1, sign=-1):
    """The exact area-equivalent calculation in hero.py, extended to 6 sides."""
    data = obj.data
    vertices = np.array([v.co[:] for v in data.vertices])
    tri = vertices[np.array([face.vertices[:] for face in data.polygons])]
    cross = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    area = np.linalg.norm(cross, axis=1) / 2
    # hero.py excludes cut caps using the assembly center. For top/bottom use
    # orientation only, since every floor is above the assembly's Z origin.
    mask = cross[:, axis] * sign > area * 2 * .5
    if axis != 2:
        mask &= tri.mean(1)[:, axis] * sign > 1e-5
    uv = np.array([loop.uv[:] for loop in data.uv_layers.active.data]).reshape(-1, 3, 2)
    a, b = uv[:, 1] - uv[:, 0], uv[:, 2] - uv[:, 0]
    uv_area = np.abs(a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]) / 2 * SIZE ** 2
    surface = float(area[mask].sum())
    return (round(math.sqrt(float(uv_area[mask].sum()) / surface), 3) if surface else None), round(surface, 4)


def export_piece(obj, folder, prefix):
    active(obj)
    path = folder / (prefix + ".fbx")
    pending = path.with_name("pending-" + path.name)
    bpy.ops.export_scene.fbx(filepath=str(pending), use_selection=True, object_types={"MESH"},
                             apply_unit_scale=False, global_scale=1, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=False, mesh_smooth_type="OFF", path_mode="AUTO",
                             embed_textures=False, add_leaf_bones=False, bake_anim=False)
    replace_output(pending, path)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
    imported = [other for other in bpy.data.objects if other not in before]
    copies = [other for other in imported if other.type == "MESH"]
    assert len(copies) == 1, "FBX should contain exactly one mesh"
    copy = copies[0]
    assert len(copy.data.polygons) == len(obj.data.polygons), "FBX triangle count changed"
    active(copy)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    expected, actual = geometry_checks(obj), geometry_checks(copy)
    assert all(np.max(np.abs(np.array(actual["bounding_box"][key]) - expected["bounding_box"][key])) < .01
               for key in ("min", "max")), "FBX dimensions changed"
    assert density(copy)[0] is None if density(obj)[0] is None else abs(density(copy)[0] - density(obj)[0]) < .002, "FBX UV density changed"
    for other in imported:
        bpy.data.objects.remove(other, do_unlink=True)


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def save_render(scene, path):
    """Write beside the output, then replace it; retry temporary file locks."""
    pending = path.with_name("pending-" + path.name)
    for attempt in range(5):
        try:
            bpy.data.images["Render Result"].save_render(str(pending), scene=scene)
            replace_output(pending, path)
            return
        except (OSError, RuntimeError):
            if attempt == 4:
                raise
            time.sleep(1)


RENDER_CONFIG = None


def render_views(objects, folder):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 1254
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = -.35
    world = bpy.data.worlds.new("Neutral concept studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (.60, .60, .60, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = .7
    scene.world = world
    # Render-only floor is excluded from every export and the six-piece report.
    bpy.ops.mesh.primitive_plane_add(size=20000, location=(0, 0, -.04))
    ground = bpy.context.object
    ground.name = "Render-only neutral ground"
    mat = bpy.data.materials.new("Neutral gray studio floor")
    mat.diffuse_color = (.60, .60, .60, 1)
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (.60, .60, .60, 1)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .82
    # A neutral photographic sweep: retain soft contact shadows without the
    # far ground fading to dark gray under inverse-square studio lighting.
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (.85, .85, .85, 1)
    mix = nodes.new("ShaderNodeMixShader")
    # Input 1 is emission and input 2 is the lit floor: keep 92% of the real
    # floor shading so the contact and cast shadows remain visible.
    mix.inputs[0].default_value = .92
    links.new(emission.outputs[0], mix.inputs[1])
    links.new(nodes["Principled BSDF"].outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], nodes["Material Output"].inputs["Surface"])
    ground.data.materials.append(mat)
    target = Vector(RENDER_CONFIG[0] if RENDER_CONFIG else (0, 0, 94.5))
    stage_scale = max(RENDER_CONFIG[1]/216.5,.4) if RENDER_CONFIG else 1
    for label, position, energy, size in (
            ("Large soft key", (-210, -300, 390), 2700000, 160),
            ("Gentle front fill", (150, -260, 220), 420000, 180),
            ("Top rim", (30, 180, 330), 600000, 160)):
        bpy.ops.object.light_add(type="AREA", location=Vector(position)*stage_scale)
        lamp = bpy.context.object
        lamp.name, lamp.data.energy, lamp.data.size = label, energy*stage_scale**2, size*stage_scale
        point_at(lamp, target)
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Concept camera"
    camera.data.type, camera.data.clip_end = "ORTHO", 10000
    camera.data.ortho_scale = RENDER_CONFIG[1] if RENDER_CONFIG else 216.5
    scene.camera = camera
    renders = folder / "renders"
    renders.mkdir(exist_ok=True)
    # Both requested previews use the concept's three-quarter camera. Render
    # it once so the two filenames have identical lighting and framing.
    camera.location = target + Vector(RENDER_CONFIG[2] if RENDER_CONFIG else (.41, -1, .215)) * 600
    point_at(camera, target)
    log("rendering concept camera")
    bpy.ops.render.render()
    for label in ("front", "three-quarter"):
        save_render(scene, renders / (label + ".png"))
    ground.hide_set(True)
    # Keep the neutral stage visible on opening the saved scene or rerendering.


def comparison(folder):
    concept = png_read(folder / "concept-front.png")
    rendered = png_read(folder / "renders/three-quarter.png")
    assert concept.shape == rendered.shape, "Comparison must preserve the original concept pixels"
    png_write(folder / "compare.png", np.concatenate((concept, rendered), axis=1))


def file_checks(folder, report):
    for piece in report["pieces"]:
        for channel in ("color", "normal", "roughness"):
            path = folder / "parts" / (piece["prefix"] + "-" + channel + ".png")
            header = path.read_bytes()[:24]
            assert struct.unpack(">II", header[16:24]) == (SIZE, SIZE), "Wrong map resolution"
        assert (folder / "parts" / (piece["prefix"] + ".fbx")).stat().st_size > 10000
    for name in ("front.png", "three-quarter.png"):
        assert (folder / "renders" / name).is_file()
    assert (folder / "compare.png").is_file()
    concept = png_read(folder / "concept-front.png")
    compared = png_read(folder / "compare.png")
    rendered = png_read(folder / "renders/three-quarter.png")
    assert np.array_equal(compared[:, :concept.shape[1]], concept), "Comparison reference changed"
    assert np.array_equal(compared[:, concept.shape[1]:], rendered), "Comparison render changed"


def texture_contact_sheet(folder, report):
    """All eighteen maps, without lettering, for a quick visual inspection."""
    columns = min(6,len(report["pieces"]))
    sheet = np.zeros((math.ceil(len(report["pieces"])/columns)*3*256,columns*256,3),dtype=np.uint8)
    for column, piece in enumerate(report["pieces"]):
        for row, channel in enumerate(("color", "normal", "roughness")):
            path = folder / "parts" / (piece["prefix"] + "-" + channel + ".png")
            image = bpy.data.images.load(str(path), check_existing=False)
            image.scale(256, 256)
            pixels = np.empty(256 * 256 * 4, np.float32)
            image.pixels.foreach_get(pixels)
            sx,sy = column%columns*256,(column//columns*3+row)*256
            sheet[sy:sy+256,sx:sx+256] = np.flipud(
                np.rint(pixels.reshape(256, 256, 4)[:, :, :3] * 255).clip(0, 255).astype(np.uint8))
            bpy.data.images.remove(image)
    png_write(folder / "renders/textures.png", sheet)


def sticky_main():
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if names != ["sticky-note-tower"]:
        raise SystemExit("Usage: blender -b --python tools/art/blocks.py -- sticky-note-tower")
    folder = ROOT / "assets/models/sticky-note-tower"
    concept = folder / "concept-front.png"
    concept_hash = hashlib.sha256(concept.read_bytes()).hexdigest()
    parts_folder = folder / "parts"
    parts_folder.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.context.scene.unit_settings.system = "NONE"
    objects = sticky_note_tower()
    tree = assembly_bvh(objects)
    report = {"source": "tools/art/blocks.py", "front": "-y", "up": "z", "units": "studs",
              "piece_count": 6, "requested_height": 190, "height": 189,
              "pad_size": [PAD_WIDTH, PAD_WIDTH, PAD_HEIGHT], "pad_angles_degrees": list(ANGLES),
              "normal_convention": "OpenGL +Y", "map_size": [SIZE, SIZE],
              "uv_reuse": "Front paper chart is separate; other paper faces and repeated fittings share charts",
              "baked_ambient_occlusion": {"samples": 24, "distance_studs": 4, "maximum_darkening": .24,
                                          "method": "Cosine-weighted ray tests against all six closed pieces"},
              "pieces": []}
    for index, obj in enumerate(objects):
        prefix = str(index + 1) + "-" + obj.name
        log("baking " + prefix)
        bake(obj, parts_folder, prefix, COLORS[index], index, tree)
        piece = geometry_checks(obj)
        piece["prefix"] = prefix
        piece["density_face"] = "front"
        piece["baked_ao_minimum"] = obj["baked_ao_minimum"]
        piece["front_pixels_per_stud"], piece["front_surface_studs2"] = density(obj)
        piece["outer_face_pixels_per_stud"] = {
            side: density(obj, axis, sign)[0] for side, axis, sign in
            (("front", 1, -1), ("back", 1, 1), ("left", 0, -1), ("right", 0, 1), ("top", 2, 1), ("bottom", 2, -1))}
        assert min(piece["outer_face_pixels_per_stud"].values()) >= 6, (obj.name, "Insufficient density", piece)
        export_piece(obj, parts_folder, prefix)
        report["pieces"].append(piece)
        log(json.dumps(piece))
    assert len(objects) == 6
    for index, obj in enumerate(objects):
        low, high = (np.array(report["pieces"][index]["bounding_box"][key]) for key in ("min", "max"))
        assert abs(low[2] - index * 31.5) < .001 and abs(high[2] - (index + 1) * 31.5) < .001
        # The brief's footprint limit applies to the turned 72-stud pads.
        # The separately specified proud frames and front step extend beyond it.
        angle = abs(math.radians(ANGLES[index]))
        assert (PAD_WIDTH + .052) * (math.cos(angle) + math.sin(angle)) <= 90.0
    report["total_triangles"] = sum(piece["triangles"] for piece in report["pieces"])
    report["dimensions_note"] = "Six exact 31.5-stud pads total 189 studs; 90 x 90 is the rotated pad envelope, excluding proud window frames and the front doorstep."
    report["bounding_box"] = {
        "min": np.min([p["bounding_box"]["min"] for p in report["pieces"]], axis=0).tolist(),
        "max": np.max([p["bounding_box"]["max"] for p in report["pieces"]], axis=0).tolist()}
    render_views(objects, folder)
    comparison(folder)
    texture_contact_sheet(folder, report)
    write_output(folder / "parts.json", (json.dumps(report, indent=2) + "\n").encode("utf-8"))
    for image in bpy.data.images:
        if image.packed_file:
            image.filepath = "//parts/" + Path(image.filepath).name
    pending = folder / "pending-hero.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(pending))
    replace_output(pending, folder / "hero.blend")
    file_checks(folder, report)
    assert hashlib.sha256(concept.read_bytes()).hexdigest() == concept_hash, "Concept changed"
    log("PASS " + json.dumps(report))


PAINT = {
    "kraft": ("B88B56", "cardboard"), "cream": ("E9D8AF", "paper"),
    "blue": ("087BC2", "plastic"), "red": ("CF3025", "plastic"),
    "yellow": ("F4CB2C", "plastic"), "green": ("249860", "plastic"),
    "glass": ("286CB1", "glass"), "wood": ("CBA775", "wood"),
    "silver": ("AABBC2", "metal"), "dark": ("3D474C", "metal"),
    "white": ("ECE7D9", "chalk"), "orange": ("ED8D29", "plastic"),
}
BUILDERS = {}
OPENINGS = {}
CAMERAS = {}
HEIGHTS = {"shoebox-hall":55,"chalk-box-depot":60,"abacus-hall":75,"block-arch":160,
    "monorail-station-north":150,"monorail-station-south":150,"pencil-tin-tower":160,
    "ruler-stilt-tower":180,"log-cabin-tower":200,"stacking-cup-tower":230,
    "jenga-tower":240,"ring-binder-tower":300,"pencil-pillar-tower":345}


def paint(obj, name):
    """Store reusable planar charts in studs before any assembly rotation."""
    color, recipe = PAINT.get(name, (name, "plastic"))
    obj["paint"] = color + ":" + recipe
    for old in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(old)
    layer = obj.data.uv_layers.new(name="BlockUV")
    points = np.array([v.co[:] for v in obj.data.vertices])
    center = (points.min(0) + points.max(0)) / 2
    for face in obj.data.polygons:
        axis = int(np.argmax(np.abs(face.normal)))
        for loop in face.loop_indices:
            co = obj.data.vertices[obj.data.loops[loop].vertex_index].co - Vector(center)
            u, v = ((co.y, co.z) if axis == 0 else
                    ((co.x, co.z) if axis == 1 else (co.x, co.y)))
            layer.data[loop].uv = (u * (-1 if face.normal[axis] < 0 else 1), v)
            if color=="246BA7" and axis!=1:
                layer.data[loop].uv.y += 70
    return obj


def gb(name, size, at, color="kraft", bevel=.16):
    return paint(box(name, size, at, bevel), color)


def gc(name, radius, length, at, color="wood", axis="Z", vertices=24, tip=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
        radius2=radius if tip is None else tip, depth=length, location=at)
    obj = bpy.context.object
    obj.name = name
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    soften(obj, min(.12, radius * .08), 2)
    paint(obj, color)
    if axis != "Z":
        pivot = Vector(at)
        rotation = Matrix.Rotation(math.pi / 2, 4, "Y" if axis == "X" else "X")
        obj.data.transform(Matrix.Translation(pivot) @ rotation @ Matrix.Translation(-pivot))
        obj.data.update()
    for f in obj.data.polygons:
        f.use_smooth = vertices > 8 and abs(f.normal["XYZ".index(axis)]) < .99
    return obj


def rotate_about(obj, angle, axis="Z", pivot=(0, 0, 0)):
    obj.data.transform(Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(angle), 4, axis)
                       @ Matrix.Translation(-Vector(pivot)))
    obj.data.update()
    return obj


def ring_profile(name, profile, depth, y=0, color="kraft", bevel=.1):
    """Closed extrusion of a simple concave X/Z polygon."""
    n = len(profile)
    vertices = [(x, y + d, z) for d in (-depth / 2, depth / 2) for x, z in profile]
    faces = [tuple(reversed(range(n))), tuple(range(n, n * 2))]
    faces += [(j, (j + 1) % n, (j + 1) % n + n, j + n) for j in range(n)]
    return paint(soften(mesh(name, vertices, faces), bevel), color)


def gw(x, z, y, width=14, height=16, trim="cream", mullions=True, side=0):
    """Real projecting trim and divided recessed blue panes, all closed."""
    t = max(1, min(width, height) * .105)
    parts = [gb("Blue recessed window", (width - 2*t, .35, height - 2*t),
                (x, y - .17, z), "glass", .08)]
    for dx in (-1, 1):
        parts.append(gb("Window upright", (t, 1.5, height), (x+dx*(width-t)/2,y-.8,z),trim))
    for dz in (-1, 1):
        parts.append(gb("Window sill", (width-2*t, 1.5,t),(x,y-.8,z+dz*(height-t)/2),trim))
    if mullions:
        parts += [gb("Window vertical bar", (.65, .8, height-2*t), (x,y-.65,z),trim,.06),
                  gb("Window horizontal bar", (width-2*t,.8,.65),(x,y-.65,z),trim,.06)]
    if side:
        for obj in parts:
            rotate_about(obj, side)
    return parts


def gd(x, base, y, width=12, height=24, color="red", trim="cream", jamb=1.4):
    """Knob is exactly half-height and 20% of door width from latch edge."""
    parts = [gb("Door panel", (width,.65,height), (x,y-.25,base+height/2),color)]
    t = jamb
    parts += [gb("Door jamb",(t,1.8,height+t),(x+s*(width+t)/2,y-.7,base+(height+t)/2),trim)
              for s in (-1,1)]
    parts.append(gb("Door lintel",(width,1.8,t),(x,y-.7,base+height+t/2),trim))
    for zz, hh in ((height*.25,height*.31),(height*.72,height*.34)):
        parts.append(gb("Raised inset door panel",(width*.75,.35,hh),
                        (x,y-.72,base+zz),color,.15))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=max(.65,width*.065),
        location=(x+width*.3,y-1.3,base+height/2))
    obj = bpy.context.object
    obj.name = "Knob at half door height, inset one fifth"
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    paint(obj,"yellow")
    for f in obj.data.polygons:
        f.use_smooth = True
    parts.append(obj)
    return parts


def brick(size, at, color, studs=2):
    w,d,h = size
    result = [gb("Toy brick",size,at,color,.22)]
    for i in range(studs):
        result.append(gc("Round brick stud", min(d*.23,w/studs*.26), .8,
            (at[0]+(i-(studs-1)/2)*w/studs,at[1],at[2]+h/2+.4),color,vertices=16))
    return result


def corrugated_edge(width, y, z, thickness=1.2, side=0):
    """Two liners and an actual thin, wavy flute, with air between them.

    z is the board's centre. The dark recessed core is behind the flute,
    rather than filling the wave's cut profile with a solid bright strip.
    """
    PAINT["flute-liner"] = ("D2AE7C", "cardboard")
    PAINT["flute-core"] = ("725333", "cardboard")
    parts = []
    count = max(1, math.ceil(width/70))
    for i in range(count):
        w = width/count
        cx = -width/2+(i+.5)*w
        for sign in (-1, 1):
            parts.append(gb("Cut cardboard outer liner", (w,.38,.14),
                (cx,y,z+sign*(thickness-.14)/2), "flute-liner", .02))
        parts.append(gb("Recessed shadow behind cardboard flutes", (w,.08,thickness-.22),
            (cx,y+.22,z), "flute-core", .01))
        xs = np.linspace(cx-w/2,cx+w/2,max(9,int(w*5)+1))
        wave = [(x,z+(thickness/2-.17)*math.sin(x*math.pi*2/1.8)) for x in xs]
        profile = [(x,zz+.045) for x,zz in wave]+[(x,zz-.045) for x,zz in reversed(wave)]
        parts.append(ring_profile("Real corrugated wavy flute between liners",profile,.24,y-.12,
            "flute-liner",0))
    if side:
        for obj in parts:
            rotate_about(obj,side)
    return parts


def board_edges(width, depth, z, thickness=1.2):
    parts = []
    for side in (0,180):
        parts += corrugated_edge(width,-depth/2-.12,z,thickness,side)
    for side in (-90,90):
        parts += corrugated_edge(depth,-width/2-.12,z,thickness,side)
    return parts


def charts_for(objects):
    rects = {}
    for obj in objects:
        uv = np.array([p.uv[:] for p in obj.data.uv_layers.active.data])
        lo,hi = uv.min(0),uv.max(0)
        size = np.ceil((hi-lo)*8 + 16).astype(int)
        old = rects.get(obj["paint"], (0,0))
        rects[obj["paint"]] = tuple(np.maximum(old,size))
    return rects


def pack_charts(rects):
    """Guillotine pack with an eight-pixel painted gutter around each chart."""
    free, result = [(0,0,SIZE,SIZE)], {}
    for key,(w,h) in sorted(rects.items(), key=lambda kv: max(kv[1])*10000+min(kv[1]), reverse=True):
        choices = [(fw*fh-w*h,i) for i,(x,y,fw,fh) in enumerate(free) if w<=fw and h<=fh]
        if not choices:
            return None
        _,i = min(choices)
        x,y,fw,fh = free.pop(i)
        result[key] = (x,y,w,h)
        free += [(x+w,y,fw-w,h),(x,y+h,fw,fh-h)]
    return result


def generic_pieces(groups):
    """Split by actual atlas area or triangle count, preserving closed shells."""
    result, layouts = [], []
    for label,parts in groups:
        batches, current = [], []
        for obj in parts:
            candidate = current+[obj]
            triangles = sum(sum(len(f.vertices)-2 for f in p.data.polygons) for p in candidate)
            if current and (triangles>LIMIT or pack_charts(charts_for(candidate)) is None):
                batches.append(current)
                current = []
            assert pack_charts(charts_for([obj])) is not None, (obj.name,"Single primitive chart exceeds 1024")
            current.append(obj)
        if current:
            batches.append(current)
        for index, batch in enumerate(batches):
            layout = pack_charts(charts_for(batch))
            for obj in batch:
                x,y,w,h = layout[obj["paint"]]
                layer = obj.data.uv_layers.active
                uv = np.array([p.uv[:] for p in layer.data])
                uv = (uv-(uv.min(0)+uv.max(0))/2)*8 + (x+w/2,y+h/2)
                layer.data.foreach_set("uv",(uv/SIZE).astype(np.float32).ravel())
            active(batch[0])
            for obj in batch:
                obj.select_set(True)
            bpy.ops.object.join()
            obj = bpy.context.object
            obj.name = label if len(batches)==1 else label+"-"+str(index+1)
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            bmesh.ops.triangulate(bm,faces=list(bm.faces))
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
            bm.to_mesh(obj.data)
            bm.free()
            result.append(obj)
            layouts.append(layout)
    return result,layouts


def generic_maps(layout, seed):
    rng = np.random.default_rng(4400+seed)
    yy,xx = np.mgrid[0:SIZE,0:SIZE]
    grain = rng.normal(0,1,(SIZE,SIZE))
    color = np.full((SIZE,SIZE,3),185.,dtype=float)
    normal = np.zeros_like(color)
    normal[:,:,2] = 1
    roughness = np.full((SIZE,SIZE),.8)
    for key,(x,y,w,h) in layout.items():
        hexcolor,kind = key.split(":")
        u,v = (xx-x)/8,(yy-y)/8
        du,dv = np.zeros_like(grain),np.zeros_like(grain)
        wear = None
        if kind=="cardboard":
            fibers = np.sin(u*48+v*17+np.sin(v*9))*np.sin(v*39-u*11)
            mottling = np.sin(u*1.7+np.sin(v*2.1))*np.sin(v*2.8+u*.7)
            crease = np.exp(-((v-h/19-.12*np.sin(u*.3))/.08)**2)
            tint = 1+grain*.043+fibers*.034+mottling*.027-crease*.025
            du,dv = grain*.027+fibers*.017,grain*.025+fibers*.014
            rough = .88
        elif kind=="cardstock":
            tint = 1+grain*.026+.01*np.sin(u*2.3+np.sin(v*2.7))+.007*np.sin(u*31+v*12)
            du,dv = grain*.012,grain*.012
            rough = .88
        elif kind.startswith(("arch-grain","arch-painted")):
            if "@" in kind:
                anchor = [float(value) for value in kind.split("@")[1].split(",")]
                u,v = u-w/16+anchor[0],v-h/16+anchor[1]
            speck = np.sin(u*127.1+v*311.7)*43758.5453
            speck = (speck-np.floor(speck))*2-1
            wave = np.sin(v*1.4+.6*np.sin(u*.11)+.25*np.sin(u*.37+v*.4))
            broad = np.sin(u*.13+v*.8)*np.sin(u*.05+v*.29)
            amount = .55 if kind.startswith("arch-painted") else 1
            tint = 1+amount*(wave*.012+broad*.006)+speck*.03
            du,dv = speck*.001,wave*.001+speck*.001
            rough = .64
        elif kind in ("wood","woodgrain"):
            phase = v*5.1+.55*np.sin(u*.19)+.2*np.sin(u*.83+v*.5)
            wave = np.sin(phase)+.35*np.sin(phase*3.3)
            tint = 1+wave*.055+grain*.02+.018*np.sin(v*.9+u*.08)
            du,dv = grain*.008,wave*.024+grain*.01
            rough = .66
        elif kind=="cabin-wood":
            knot = np.arctan2(u-w/16-1.8,(v-h/16-4)*.18)
            influence = np.exp(-((v-h/16-4)/13)**2)
            phase = u*4.5+.35*np.sin(v*.13)+.18*np.sin(v*.53)+knot*influence*.7
            wave = np.sin(phase)+.3*np.sin(phase*3)
            tint = 1+wave*.028+.022*np.sin(u*.9+v*.05)+grain*.02
            du,dv = wave*.007+grain*.004,grain*.003
            rough = .68
        elif kind=="logs":
            wave = np.sin(u*9+.35*np.sin(v*.7)+.3*np.sin(u*2+v*.22))
            tint = 1+wave*.045+grain*.012
            du,dv = wave*.012,grain*.003
            rough = .68
        elif kind in ("endgrain","cabin-end"):
            rr = np.sqrt((u-w/16+(1.4 if kind=="cabin-end" else 0))**2+(.9*(v-h/16)-.8 if kind=="cabin-end" else v-h/16)**2)
            tint = 1+(.012 if kind=="cabin-end" else .055)*np.sin(rr*(3.8 if kind=="cabin-end" else 13)+.15*np.sin(u*2))+grain*(.025 if kind=="cabin-end" else .012)
            du,dv = grain*.004,grain*.004
            rough = .74
        elif kind=="pages":
            phase = u*2*math.pi/.35
            tint = .99+.025*np.cos(phase)+grain*.003
            du,dv = .07*np.cos(phase),np.zeros_like(grain)
            rough = .8
        elif kind in ("cloth","binder-cover"):
            weave = np.sin(u*29)*np.sin(v*31)
            tint = 1+grain*.025+(.01 if kind=="binder-cover" else .024)*weave+.008*np.sin(u*1.7+np.sin(v*1.4))
            du,dv = grain*.016+weave*.006,grain*.016+weave*.006
            rough = .52 if kind=="binder-cover" else .74
        elif kind=="jenga":
            knots = rng.normal(0,1,(256,16))
            field = np.array([np.interp(np.linspace(0,15,SIZE),np.arange(16),row) for row in knots])
            field = np.array([np.interp(np.linspace(0,255,SIZE),np.arange(256),column) for column in field.T]).T
            wave = np.sin(v*3.2+1.3*field+.4*np.sin(u*.15)+.2*np.sin(u*.6))
            tint = 1+.04*field+.018*wave+grain*.02
            du,dv = grain*.003,field*.006+wave*.003
            rough = .68
        elif kind=="jenga-end":
            rr = np.sqrt((u+14)**2+(v+9)**2)
            wave = np.sin(rr*2.7+.12*np.sin(u*.4+v*.3))
            tint = 1+.02*wave+grain*.028
            du,dv = grain*.003,wave*.004+grain*.003
            rough = .74
        elif kind in ("metal","enamel"):
            brushing = np.sin(u*57+np.sin(v*.2))
            scratch = np.maximum(0,np.sin(u*13.7+v*.13))**70
            tint = 1+grain*.012+.013*brushing+.025*scratch
            du,dv = grain*.003+brushing*.006,grain*.003
            rough = .30 if kind=="enamel" else .24
            if kind=="enamel":
                wear = np.maximum(0,np.sin(u*29.1+v*.51))**60 * np.maximum(0,np.sin(v*8.7+u*.13))**30
        elif kind=="chalk":
            low = rng.normal(0,1,(96,96))
            field = np.array([np.interp(np.linspace(0,95,SIZE),np.arange(96),row) for row in low])
            field = np.array([np.interp(np.linspace(0,95,SIZE),np.arange(96),row) for row in field.T]).T
            pits = np.minimum(0,grain+1.1)
            tint = 1+grain*.065+field*.018+pits*.055
            du,dv = grain*.018+field*.002,grain*.018-field*.002
            rough = .9
        elif kind=="cup-glass":
            tint = 1+grain*.003+.04*np.sin(u*.18+v*.07)
            rough = .26
        elif kind=="cup-plastic":
            tint = 1+grain*.003
            du,dv = grain*.001,grain*.001
            rough = .23
        elif kind=="pencil-wood":
            phase = u*2.4+.45*np.sin(v*.27)
            tint = 1+.028*np.sin(phase)+grain*.02
            du,dv = .007*np.sin(phase)+grain*.004,grain*.004
            rough = .68
        elif kind=="pencil-paint":
            stripe = np.sin(u*14+np.sin(v*.3))
            tint = 1+grain*.012+stripe*.014
            du,dv = grain*.004+stripe*.003,grain*.003
            rough = .38
        elif kind=="graphite":
            tint = 1+grain*.035
            du,dv = grain*.006,grain*.006
            rough = .45
        else:
            tint = 1+grain*(.005 if kind in ("paper","label-paper") else .002)
            rough = .45 if kind=="glass" else (.77 if kind in ("paper","label-paper") else .34)
        mask = (xx>=x)&(xx<x+w)&(yy>=y)&(yy<y+h)
        color[mask] = np.clip((rgb(hexcolor)*tint[:,:,None])[mask],0,255)
        if wear is not None:
            color[mask] = np.clip(color[mask]+wear[mask][:,None]*(rgb("C1C3BD")-rgb(hexcolor))*.55,0,255)
        nn = np.stack((-du,-dv,np.ones_like(grain)),axis=-1)
        nn /= np.linalg.norm(nn,axis=-1,keepdims=True)
        normal[mask] = nn[mask]
        roughness[mask] = np.clip(rough+grain[mask]*.014,.08,1)
    return {"color":np.rint(color).astype(np.uint8),
            "normal":np.rint((normal*.5+.5)*255).astype(np.uint8),
            "roughness":np.repeat(np.rint(roughness*255).astype(np.uint8)[:,:,None],3,axis=2)}


def generic_bake(obj, folder, prefix, layout, seed, tree):
    maps = generic_maps(layout,seed)
    occlusion = ambient_occlusion(obj,tree,resolution=96,samples=16,
        front_priority=obj.get("prefer_front_ao",False) or "246BA7:metal" in layout)
    for key,(x,y,w,h) in layout.items():
        if key.endswith(":label-paper"):
            # An exposed flat label has no occluder over its face. Reusing a
            # hidden back face's shading here would stamp a false bright patch.
            occlusion[y:y+h,x:x+w] = 1
    maps["color"] = np.rint(maps["color"]*occlusion[:,:,None]).clip(0,255).astype(np.uint8)
    material = bpy.data.materials.new(obj.name+" baked PBR")
    material.use_nodes = True
    nodes,links = material.node_tree.nodes,material.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Specular IOR Level"].default_value = .45 if any(k.endswith(":cup-plastic") for k in layout) else .3
    shader.inputs["Metallic"].default_value = .5 if all(k.endswith(":metal") for k in layout) else 0
    # The atlas can mix tin and cardboard. A packed material mask preserves
    # the real metal response in previews without adding an export channel.
    metallic = np.zeros((SIZE,SIZE,4),dtype=np.float32)
    metallic[:,:,3] = 1
    for key,(x,y,w,h) in layout.items():
        if key.endswith(":metal"):
            metallic[y:y+h,x:x+w,:3] = .8
        elif key.endswith(":enamel"):
            metallic[y:y+h,x:x+w,:3] = .25
    mask_image = bpy.data.images.new(obj.name+" metal regions",width=SIZE,height=SIZE)
    mask_image.colorspace_settings.name = "Non-Color"
    mask_image.pixels.foreach_set(metallic.ravel())
    mask_image.pack()
    mask_node = nodes.new("ShaderNodeTexImage")
    mask_node.image = mask_image
    links.new(mask_node.outputs["Color"],shader.inputs["Metallic"])
    for channel,pixels in maps.items():
        path = folder/(prefix+"-"+channel+".png")
        png_write(path,np.flipud(pixels).copy())
        im = bpy.data.images.load(str(path),check_existing=False)
        im.colorspace_settings.name = "sRGB" if channel=="color" else "Non-Color"
        im.pack()
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = im
        if channel=="normal":
            bump = nodes.new("ShaderNodeNormalMap")
            bump.uv_map = "BlockUV"
            links.new(tex.outputs["Color"],bump.inputs["Color"])
            links.new(bump.outputs["Normal"],shader.inputs["Normal"])
        else:
            links.new(tex.outputs["Color"],shader.inputs["Base Color" if channel=="color" else "Roughness"])
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for face in obj.data.polygons:
        face.material_index = 0
    obj["baked_ao_minimum"] = float(occlusion.min())


def opening_checks(tree, definitions):
    result = []
    for definition in definitions:
        label,x0,x1,z0,z1 = definition[:5]
        along_x = len(definition)>5 and isinstance(definition[5],dict) and definition[5].get("axis")=="x"
        count = 0
        for x in np.linspace(x0+.12,x1-.12,25):
            for z in np.linspace(z0+.12,z1-.12,25):
                if len(definition)>5:
                    shape = definition[5]
                    if shape=="arched" and z>70+16*math.sqrt(max(0,1-(x/80)**2))-.12:
                        continue
                    if isinstance(shape,dict) and ((x-shape["cx"])/shape["rx"])**2+((z-shape["cz"])/shape["rz"])**2>=.98:
                        continue
                for sign in (-1,1):
                    origin = Vector((sign*1000,x,z) if along_x else (x,sign*1000,z))
                    direction = Vector((-sign,0,0) if along_x else (0,-sign,0))
                    hit = tree.ray_cast(origin,direction,2000)[0]
                    assert hit is None,(label,"Blocked through opening",x,z)
                    count += 1
        result.append({"label":label,"through_axis":"x" if along_x else "y",
                       "y" if along_x else "x":[x0,x1],"z":[z0,z1],
                       "shape":definition[5] if len(definition)>5 else "rectangle",
                       "clear_front_and_back_rays":count})
    return result


def generic_render(objects,folder,name):
    """Use the concept's orthographic azimuth, elevation, framing and soft stage."""
    global RENDER_CONFIG
    RENDER_CONFIG = CAMERAS[name]
    render_views(objects,folder)
    if OPENINGS.get(name):
        scene = bpy.context.scene
        camera = scene.camera
        h = float(max(v.co.z for obj in objects for v in obj.data.vertices))
        saved_position,saved_rotation,saved_scale = camera.location.copy(),camera.rotation_euler.copy(),camera.data.ortho_scale
        scene.cycles.samples = 8
        along_x = any(len(d)>5 and isinstance(d[5],dict) and d[5].get("axis")=="x" for d in OPENINGS[name])
        for label,sign in (("opening-front",-1),("opening-back",1)):
            log("rendering "+label)
            camera.location = (sign*1000,0,h/2) if along_x else (0,sign*1000,h/2)
            camera.data.ortho_scale = max(RENDER_CONFIG[1],h*1.13)
            point_at(camera,(0,0,h/2))
            bpy.ops.render.render()
            save_render(scene,folder/"renders"/(label+".png"))
        camera.location,camera.rotation_euler,camera.data.ortho_scale = saved_position,saved_rotation,saved_scale


def generic_main(name):
    folder = ROOT/"assets/models"/name
    assert (folder/"sizes.md").is_file(),"Measure the approved concept before building"
    concept = folder/"concept-front.png"
    before_hash = hashlib.sha256(concept.read_bytes()).hexdigest()
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.context.scene.unit_settings.system = "NONE"
    parts_folder = folder/"parts"
    parts_folder.mkdir(exist_ok=True)
    objects,layouts = generic_pieces(BUILDERS[name]())
    tree = assembly_bvh(objects)
    report = {"source":"tools/art/blocks.py","front":"-y","up":"z","units":"studs",
        "piece_count":len(objects),"map_size":[1024,1024],"normal_convention":"OpenGL +Y",
        "uv_reuse":"Identical material faces share planar charts at eight pixels per stud",
        "opening_checks":opening_checks(tree,OPENINGS.get(name,[])),"pieces":[]}
    for index,(obj,layout) in enumerate(zip(objects,layouts)):
        prefix = str(index+1)+"-"+obj.name
        log("baking "+prefix)
        generic_bake(obj,parts_folder,prefix,layout,index,tree)
        piece = geometry_checks(obj)
        piece["prefix"] = prefix
        piece["front_pixels_per_stud"],piece["front_surface_studs2"] = density(obj)
        piece["outer_face_pixels_per_stud"] = {side:density(obj,axis,sign)[0]
            for side,axis,sign in (("front",1,-1),("back",1,1),("left",0,-1),("right",0,1),("top",2,1),("bottom",2,-1))}
        assert min(v for v in piece["outer_face_pixels_per_stud"].values() if v is not None)>=6,piece
        export_piece(obj,parts_folder,prefix)
        report["pieces"].append(piece)
    report["total_triangles"] = sum(p["triangles"] for p in report["pieces"])
    report["bounding_box"] = {"min":np.min([p["bounding_box"]["min"] for p in report["pieces"]],0).tolist(),
        "max":np.max([p["bounding_box"]["max"] for p in report["pieces"]],0).tolist()}
    report["height"] = report["bounding_box"]["max"][2]-report["bounding_box"]["min"][2]
    report["requested_height"] = HEIGHTS[name]
    assert abs(report["height"]-HEIGHTS[name])<.15,(name,"Height differs from measured brief",report["height"])
    generic_render(objects,folder,name)
    comparison(folder)
    texture_contact_sheet(folder,report)
    write_output(folder/"parts.json",(json.dumps(report,indent=2)+"\n").encode())
    for im in bpy.data.images:
        if im.packed_file and im.filepath:
            im.filepath = "//parts/"+Path(im.filepath).name
    pending = folder/"pending-hero.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(pending))
    replace_output(pending,folder/"hero.blend")
    file_checks(folder,report)
    assert hashlib.sha256(concept.read_bytes()).hexdigest()==before_hash
    # Keep the output layout exact after a rebuild changes the piece count.
    # Only obsolete generated exports in this named building are removed.
    expected = {p["prefix"]+suffix for p in report["pieces"]
        for suffix in (".fbx","-color.png","-normal.png","-roughness.png")}
    for path in parts_folder.iterdir():
        if path.is_file() and path.name not in expected and (
                path.suffix==".fbx" or path.name.endswith(("-color.png","-normal.png","-roughness.png"))):
            path.unlink()
    log("PASS "+name+" "+str(report["piece_count"])+" pieces, "+str(report["total_triangles"])+" triangles")


def shoebox_hall():
    PAINT["shoebox-lid"] = ("B98E5E","cardboard")
    body = [gb("Separate kraft shoebox",(116,62,36),(0,0,18))]
    body += board_edges(116,62,35.45,1.1)
    groups = [("cardboard-box",body)]
    fittings = []
    for x in (-43,-23,20,42):
        fittings += gw(x,18,-31,16.5,18)
    fittings += gd(-2,3,-31,12,25)
    groups.append(("windows-and-door",fittings))
    pivot = (0,-26,50.2)
    angle = math.degrees(math.atan(8/18))
    rear = gb("Rear plane of the separate shoebox lid",(120,math.hypot(52,6),1.2),
        (0,9,51.4),"shoebox-lid")
    lid = [rotate_about(rear,-math.degrees(math.atan(6/52)),"X",(0,9,51.4))]
    front = [gb("Long folded sloping awning",(120,math.hypot(18,8),1.2),pivot)]
    front += corrugated_edge(120,-26-math.hypot(18,8)/2-.12,50.2,1.2)
    for obj in front:
        rotate_about(obj,angle,"X",pivot)
    lid += front
    for x in (-59,59):
        # A deep side flap folds down at the rear, like the approved lid.
        flap = ring_profile("Folded triangular lid side flap",[(-35,45.7),(-17,53.8),(35,47.8),
            (35,40),(-17,36.5)],1.2,-x,"kraft",.06)
        rotate_about(flap,90)
        lid.append(flap)
        tape = gb("Cream tape on awning fold",(4.5,12,.15),(x*.94,-25,50.95),"cream",.02)
        lid.append(rotate_about(tape,angle,"X",pivot))
        lid.append(gb("Tape folded over awning side",(.2,4.5,9),(x+math.copysign(.75,x),-20,46.5),"cream",.02))
    lid.append(gb("Back folded lid flap",(118,1.2,8),(0,34.4,43.8)))
    groups.append(("propped-corrugated-awning",lid))
    trim = []
    for x in (-56,56):
        trim += [gc("Wood awning prop",1,38.2,(x,-37,27.1))]
        trim += brick((6,6,4),(x,-37,2),"yellow")+brick((6,6,4),(x,-37,6),"blue")
        trim += [gb("Cream corner tape",(2.5,.2,35),(x,-31.15,17.5),"cream",.02)]
        for z,col in ((5,"yellow"),(25,"blue"),(32,"red")):
            trim += [gb("Toy block corner",(4,4,7),(x+math.copysign(1,x),-29,z),col,.2)]
    trim += brick((22,8,3),(-2,-35.5,1.5),"green",4)
    trim += brick((14,5,3),(-2,-34,5.3),"red",3)
    groups.append(("toy-bricks-and-taped-props",trim))
    return groups


BUILDERS["shoebox-hall"] = shoebox_hall
CAMERAS["shoebox-hall"] = ((0,0,27),146,(.30,-1,.24))


def chalk_box_depot():
    for key,col in (("chalk-red","D96C70"),("chalk-blue","5DA6C9"),
                    ("chalk-yellow","E3C255"),("chalk-green","62A984")):
        PAINT[key] = (col,"chalk")
    groups = [("box-and-base",[gb("Cardboard plinth",(100,70,3),(0,0,1.5)),
        gb("Cardboard box wall",(94,54,44),(0,3,25))]+board_edges(100,70,1.5,1.4))]
    columns = []
    colors = ("white","chalk-red","chalk-blue","chalk-yellow","white","chalk-green")
    for x,col in zip((-43,-29,-15,14,29,43),colors):
        columns += [gc("Round chalk column",4,47,(x,-30,26.5),col,vertices=32)]
    groups.append(("six-round-chalk-columns",columns))
    roof = [gb("Roof tray floor",(100,70,2),(0,0,51))]
    roof += [gb("Broad front tray lip hiding chalk ends",(100,12,8),(0,-29,56)),
             gb("Back folded tray rim",(100,6,8),(0,32,56))]
    roof += [gb("Tray end rim",(6,52,8),(x,3,56)) for x in (-47,47)]
    for x,col in zip((-38,-23,-8,8,23,38),("white","chalk-red","chalk-blue","chalk-yellow","chalk-green","white")):
        roof += [gc("Loose chalk tucked behind front lip",4.5,36,(x,3,55),col,"Y",32)]
    roof += board_edges(100,70,59.35,1.3)
    for x in (-47.5,47.5):
        for y in (-32.5,32.5):
            roof += [gb("Tape over tray corner",(5.5,8,.15),(x,y,60),"cream",.02),
                     gb("Tape down folded rim",(5.5,.2,9),(x,y+math.copysign(2.55,y),55.5),"cream",.02)]
    groups.append(("open-chalk-roof-tray",roof))
    detail = []
    for x in (-35,-20,23,36):
        detail += gw(x,21,-24,13,24)
    detail += gw(0,36,-24,20,10,mullions=False)
    detail += [gb("Single transom divider",(1.1,1,7.7),(0,-24.9,36),"cream",.06)]
    for x in (-4.5,4.5):
        leaf = gd(x,5,-24,9,24,trim="red")
        for obj in list(leaf):
            if obj.name.startswith(("Door jamb","Door lintel","Raised inset door panel","Knob")):
                leaf.remove(obj)
                bpy.data.objects.remove(obj,do_unlink=True)
                continue
        detail += leaf
        detail += [gb("Dark upper door glazing",(4.5,.25,7),(x,-24.72,23),"3D5050",.08),
                   gb("Red projecting pull at half leaf height",(.9,.8,4.2),
                      (x-math.copysign(2.7,x),-25.1,17),"red",.13)]
    detail += [gb("Double door outer jamb",(1.4,1.8,25.4),(x,-24.7,17.7),"cream") for x in (-9.7,9.7)]
    detail += [gb("Double door outer lintel",(18,1.8,1.4),(0,-24.7,29.7),"cream")]
    for side in (-90,90):
        for x in (-13,13):
            detail += gw(x,24,-47,20,26,side=side)
    detail += [gb("Grey doorstep",(24,9,2),(0,-30,4),"silver")]
    detail += brick((18,6,3),(0,-30,6.5),"red",4)
    groups.append(("windows-double-door-and-step",detail))
    return groups


BUILDERS["chalk-box-depot"] = chalk_box_depot
CAMERAS["chalk-box-depot"] = ((0,0,30),140,(.34,-1,.24))


def gs(name, radius, at, color, vertical=1):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=radius,location=at)
    obj = bpy.context.object
    obj.name = name
    obj.scale.z = vertical
    active(obj)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    paint(obj,color)
    for f in obj.data.polygons:
        f.use_smooth = True
    return obj


def abacus_hall():
    PAINT["wood"] = ("CBA775","jenga")
    PAINT["abacus-rod"] = ("CBA775","pencil-wood")
    groups = []
    for x,col,label in ((-56,"red","left-house"),(56,"blue","right-house")):
        house = [gb("Cardboard end house",(28,54,62),(x,0,31)),
                 gb("Taped house plinth",(30,60,3),(x,0,1.5))]
        house += [ring_profile("Cardboard gable",[(x-14,62),(x+14,62),(x,71.8)],54,0)]
        roof = [(x-16,62),(x,73),(x+16,62),(x+16,60.8),(x,71.8),(x-16,60.8)]
        house += [ring_profile("Folded cardboard pitched roof",roof,60,0),
                  gb("Small cardboard chimney",(6,7,6),(x-5,13,72))]
        for sign in (-1,1):
            edge = corrugated_edge(math.hypot(16,11),-30.15,0,1.1)
            for obj in edge:
                rotate_about(obj,sign*math.degrees(math.atan(11/16)),"Y")
                obj.data.transform(Matrix.Translation((x+sign*8,0,66.9)))
            house += edge
        plinth_edges = board_edges(30,60,1.5,1.1)
        for obj in plinth_edges:
            obj.data.transform(Matrix.Translation((x,0,0)))
        house += plinth_edges
        house += gw(x,42,-27,15,15)+gd(x,3,-27,11,24,col)
        house += brick((16,7,3),(x,-31,1.5),col,3)
        for corner in (-1,1):
            for z in (4,23,46):
                house += [gb("House corner tape",(3.5,.2,4),(x+corner*12.25,-27.2,z),"cream",.02)]
        side = 90 if x>0 else -90
        house += gw(0,42,-70,13,16,side=side)
        for obj in house:
            if obj.name.startswith("Knob"):
                obj["paint"] = PAINT["wood"][0]+":"+PAINT["wood"][1]
        groups.append((label,house))
    frame_parts = [gb("Wood lower frame rail tenoned into houses",(100,10,10),(0,0,5),"wood",.35),
                   gb("Wood upper rail under roofs, tenoned into both walls",(100,12,4),(0,0,62),"wood",.25)]
    for x in (-35,-28,-21,21,28,35):
        frame_parts += [gc("Vertical wood bead rod",1.25,50,(x,0,35),"abacus-rod")]
    groups.append(("open-wood-abacus-frame",frame_parts))
    beads = []
    patterns = (("red",)*5,("blue",)*4,("yellow","yellow","green","green","yellow","yellow"),
                ("green",)*4,("yellow","yellow","blue","blue","yellow","yellow"),("red",)*5)
    heights = ((17,24,34,41,48),(17,24,44,51),(16,23,30,37,44,51),
               (16,23,44,51),(16,23,30,37,44,51),(17,24,36,43,50))
    for x,colors,zs in zip((-35,-28,-21,21,28,35),patterns,heights):
        for col,z in zip(colors,zs):
            beads += [gs("Rounded painted abacus bead",4.2,(x,0,z),col,.76)]
    groups.append(("painted-counting-beads",beads))
    return groups


BUILDERS["abacus-hall"] = abacus_hall
CAMERAS["abacus-hall"] = ((0,0,34.4),160,(.30,-1,.20))
OPENINGS["abacus-hall"] = [("between-rods",-15,15,10,60)]


def block_arch():
    PAINT["arch-wood"] = ("CBA775","arch-grain")
    PAINT["arch-blue"] = ("147DBA","arch-painted")
    PAINT["arch-red"] = ("C83A2B","arch-painted")
    PAINT["arch-trim"] = ("DDC49C","arch-grain")
    groups = []
    for x,col,label in ((-105,"blue","blue-block-pier"),(105,"red","red-block-pier")):
        parts = [gb("Separate painted wooden block pier",(50,30,96),(x,0,48),"arch-"+col,1.6)]
        if x<0:
            trim = box("Rounded projecting wooden window frame",(28,3.2,48),(x,-16.5,48),2.4)
            cutter = box("Temporary rounded window cut",(21.5,8,41.5),(x,-16.5,48),1.6)
            mod = trim.modifiers.new("Real rounded frame aperture","BOOLEAN")
            mod.operation,mod.solver,mod.object = "DIFFERENCE","EXACT",cutter
            apply(trim,mod)
            bpy.data.objects.remove(cutter,do_unlink=True)
            parts += [paint(trim,"arch-trim"),gb("Recessed blue block window",(22,.4,42),(x,-15.3,48),"glass",.1),
                      gb("Blue window mullion",(1.7,1.6,42),(x,-16.1,48),"arch-blue",.2),
                      gb("Blue window crossbar",(22,1.6,1.7),(x,-16.1,48),"arch-blue",.2)]
        else:
            parts += gd(x,6,-15,22,50,trim="arch-trim",jamb=2.7)
            for obj in list(parts):
                if obj.name.startswith("Raised inset door panel"):
                    parts.remove(obj)
                    bpy.data.objects.remove(obj,do_unlink=True)
            for dx in (-5.5,0,5.5):
                parts += [gb("Thin door plank seam",(.22,.12,49.5),(x+dx,-15.64,31),"9E2E20",.03)]
            parts += [gb("Wood lower step",(33,10,3),(x,-21,1.5),"wood",.65),
                      gb("Wood upper step",(29,8,3),(x,-19,4.5),"wood",.65)]
            for obj in parts:
                if obj.name.startswith("Knob"):
                    obj["paint"] = PAINT["wood"][0]+":wood"
        groups.append((label,parts))
    angles = np.linspace(0,math.pi,129)
    outer = [(130*math.cos(a),96+64*math.sin(a)) for a in angles]
    inner = [(80*math.cos(a),96+30*math.sin(a)) for a in reversed(angles)]
    whole = ring_profile("One genuinely curved wooden arch block",outer+inner,30,0,"arch-wood",.8)
    # The single arch is split only for sharp export maps, after rounding it.
    for index,obj in enumerate(closed_bands(whole,[-130,-65,0,65,130],"arch-wood",axis=0)):
        # Curved top/underside charts do not overlap the broad front chart.
        # This prevents contact shadows at an export seam painting an L on the face.
        layer = obj.data.uv_layers.active
        for face in obj.data.polygons:
            if abs(face.normal.y)<.5:
                for loop in face.loop_indices:
                    layer.data[loop].uv.y += 35
        points = np.array([vert.co[:] for vert in obj.data.vertices])
        coords = np.array([loop.uv[:] for loop in layer.data])
        origin = (points.min(0)+points.max(0))/2
        anchor = (coords.min(0)+coords.max(0))/2 + origin[[0,2]]
        obj["paint"] += "@"+",".join(str(float(v)) for v in anchor)
        obj["prefer_front_ao"] = True
        groups.append(("curved-wood-arch-sector-"+str(index+1),[obj]))
    return groups


BUILDERS["block-arch"] = block_arch
CAMERAS["block-arch"] = ((0,0,80),302,(-.24,-1,.18))
OPENINGS["block-arch"] = [("road-minimum-clearance",-80,80,0,86)]


def stud_band(width,x,y,z,color,height=4,spacing=5):
    parts = [gb("Toy brick face band",(width,1.1,height),(x,y,z),color,.15)]
    count = max(1,int(width/spacing))
    for j in range(count):
        parts += [gc("Round outward brick stud",min(1.25,height*.26),.65,
            (x+(j-(count-1)/2)*width/count,y-.8,z),color,"Y",16)]
    return parts


def bay_window(x,z,y,width=36,height=24,panes=3,side=0):
    parts = gw(x,z,y,width,height,mullions=False)
    border = max(1,min(width,height)*.105)
    for i in range(1,panes):
        parts.append(gb("Window bay vertical divider",(1.2,1.4,height-2*border),
            (x-width/2+i*width/panes,y-.85,z),"cream",.08))
    if side:
        for obj in parts:
            rotate_about(obj,side)
    return parts


def monorail_station_north():
    PAINT["glass"] = ("226398","glass")
    groups = []
    for x in (-64.5,64.5):
        outward = math.copysign(1,x)
        lid_x = x+outward
        parts = [gb("Separate cardboard stand box",(41,70,77),(x,0,38.5)),
                 gb("Stand box folded lid",(43,72,3),(lid_x,0,78.5))]
        for side in (0,180):
            edge = corrugated_edge(42,-36.1,78.5,1.2,side)
            for obj in edge:
                obj.data.transform(Matrix.Translation((lid_x,0,0)))
            parts += edge
        for z,col in ((2,"red"),(50,"red"),(46,"blue"),(42,"yellow")):
            parts += stud_band(40,x,-35.6,z,col)
            side_parts = stud_band(69,0,-85.6,z,col)
            for obj in side_parts:
                rotate_about(obj,-90 if x<0 else 90)
            parts += side_parts
        for xx in (x-18,x+18):
            parts.append(gb("Stand box corner tape",(4.5,.2,76),(xx,-35.2,39),"cream",.02))
        if x<0:
            parts += gd(x,4,-35,15,28)
            parts += [gb("Grey door step",(24,9,2),(x,-38,1),"silver")]
            parts += brick((21,7,3),(x,-38,3.5),"blue",4)
        else:
            parts += gw(x,23,-35,16,22,mullions=False)
        groups.append(("left-stand-box" if x<0 else "right-stand-box",parts))
    # A third box rests ON the stands. Its folded bottom and lid overhang.
    for x in (-45,45):
        groups.append(("top-box-bottom-left" if x<0 else "top-box-bottom-right",
            [gb("Top box overhanging bottom lip",(90,74,4),(x,0,82)),
             gb("Top box below track opening",(90,70,16),(x,0,92))]))
        groups.append(("top-box-lid-left" if x<0 else "top-box-lid-right",
            [gb("Top box roof above opening",(90,70,4),(x,0,144)),
             gb("Separate folded lid with overhang",(90,74,3.3),(x,0,147.65))]))
    for x in (-59.5,59.5):
        parts = [gb("Solid side of the third cardboard box",(57,70,42),(x,0,121))]
        parts += bay_window(x,120,-35,36,24)
        parts += bay_window(0,120,-88,32,24,side=-90 if x<0 else 90)
        groups.append(("top-box-left-wing" if x<0 else "top-box-right-wing",parts))
    trim = []
    for x in (-33,33):
        trim += [gb("Yellow track aperture jamb",(4,1.3,42),(x,-35.7,121),"yellow")]
        for z in np.arange(103,141,5):
            trim += [gc("Round aperture trim stud",1,.65,(x,-36.65,z),"yellow","Y",16)]
    trim += stud_band(70,0,-35.7,144,"blue")+stud_band(70,0,-35.7,98,"yellow")
    for x in (-85.5,85.5):
        trim += [gb("Blue toy brick corner trim",(4,1.2,60),(x,-35.7,115),"blue")]
        for z in np.arange(87,145,5):
            trim += [gc("Round corner trim stud",1,.65,(x,-36.7,z),"blue","Y",16)]
        for z in (83,147):
            trim += stud_band(7,x,-36,z,"red",6,3.5)
        xx = math.copysign(81,x)
        trim += [gb("Tape across upper box and stand join",(6,.2,8),(xx,-35.25,76),"cream",.02),
                 gb("Tape around projecting box lip",(6,.2,4),(xx,-37.25,82),"cream",.02),
                 gb("Folded tape under overhang",(6,2.2,.15),(xx,-36.2,80.1),"cream",.02),
                 gb("Tape on upper box wall",(6,.2,6),(xx,-35.25,87),"cream",.02),
                 gb("Tape over lid corner",(6,12,.15),(xx,-30,149.4),"cream",.02),
                 gb("Tape down lid front",(6,.2,8),(xx,-37.25,146),"cream",.02)]
    for x in (-85,85):
        for y in (-32,32):
            trim.append(gb("Red toy brick over lid corner",(8,8,.4),(x,y,149.5),"red",.1))
            for dx in (-2,2):
                for dy in (-2,2):
                    trim.append(gc("Real top stud on corner brick",1.1,.4,(x+dx,y+dy,149.8),"red",vertices=16))
    groups.append(("toy-brick-trims-and-join-tape",trim))
    groups.append(("corrugated-top-box-cut-edges",board_edges(180,74,82,1.4)+board_edges(180,74,148.5,1.4)))
    return same_both_sides(groups)


def same_both_sides(groups, front=-34):
    """Copy every front detail (centre in front of y=FRONT) round to the back, turned 180 degrees, so the building
    looks the same from both sides (Alan 2026-10-16). A copy lands in the left/right group its new place belongs to."""
    swap = lambda label: label.replace("left","@").replace("right","left").replace("@","right")
    out = {label: list(parts) for label,parts in groups}
    centre = lambda obj: np.mean([v.co[:] for v in obj.data.vertices],axis=0)
    have = [(centre(obj),len(obj.data.vertices)) for _,parts in groups for obj in parts]
    for label,parts in groups:
        for obj in parts:
            c = centre(obj)
            if c[1] >= front or any(n==len(obj.data.vertices) and np.allclose(o,(-c[0],-c[1],c[2]),atol=.3)
                                    for o,n in have):
                continue                                                     # not a front detail, or already twinned
            copy = obj.copy()
            copy.data = obj.data.copy()
            bpy.context.scene.collection.objects.link(copy)
            out[swap(label) if swap(label) in out else label].append(rotate_about(copy,180))
    return list(out.items())


BUILDERS["monorail-station-north"] = monorail_station_north
CAMERAS["monorail-station-north"] = ((0,0,75),208,(.32,-1,.18))
OPENINGS["monorail-station-north"] = [("road",-44,44,0,80),("monorail-tunnel",-31,31,100,142)]


def monorail_station_south():
    PAINT["tin-red"] = ("CD2E24","enamel")
    PAINT["tile-grey"] = ("A4A8AA","plastic")
    PAINT["glass"] = ("226398","glass")
    groups = []
    for x in (-64.5,64.5):
        for level,col in enumerate(("yellow","yellow","blue","yellow","blue")):
            parts = []
            for dx in (-41/3,0,41/3):
                parts.append(gb("Separate toy brick leg block",(41/3-.15,80,15.2),
                    (x+dx,0,level*15.4+7.6),col,.24))
                if level==4:
                    for y in (-31,-10,10,31):
                        parts.append(gc("Round brick stud supporting tin",3,3.4,(x+dx,y,78.3),col,vertices=24))
            if level==0:
                parts += gd(x,4,-40,14,26,"green") if x<0 else gw(x,20,-40,16,20,mullions=False)
                if x<0:
                    parts += brick((20,7,3),(x,-43,1.5),"green",3)
                # Grey tile base plate round the leg's foot, like a toy road plate (Alan 2026-10-16)
                # (outward only: the road opening between the legs stays clear)
                cx = x+math.copysign(1.5,x)
                parts.append(gb("Grey tile base plate under the leg",(44,92,1.2),(cx,0,.6),"tile-grey",.2))
                for i in (-1,1):
                    parts += [gb("Base plate tile seam",(44,.5,.1),(cx,i*23,1.22),"dark",.02),
                              gb("Base plate tile seam",(.5,92,.1),(cx+i*11,0,1.22),"dark",.02)]
            if level==3:
                parts += gw(x,60,-40,16,20,mullions=False)
            groups.append((("left" if x<0 else "right")+"-toy-leg-course-"+str(level+1),parts))
    def cut_opening(obj, size, at):
        cutter = box("Temporary station opening cutter",size,at,0)
        mod = obj.modifiers.new("Unobstructed station opening","BOOLEAN")
        mod.operation,mod.solver,mod.object = "DIFFERENCE","EXACT",cutter
        apply(obj,mod)
        bpy.data.objects.remove(cutter,do_unlink=True)

    window_centres = (-52,0,52)
    tin = box("Rounded enamelled red lunch tin",(170,80,64),(0,0,115),6)
    cut_opening(tin,(182,62.2,42.2),(0,0,121))
    for x in window_centres:
        # Reveal sleeves, rather than red cut faces, define the 46 x 30 clear hole.
        cut_opening(tin,(47.2,82,31.2),(x,0,120))
    for i,part in enumerate(closed_bands(tin,[-85,0,85],"tin-red",axis=0)):
        # Inner tunnel faces must not stamp their baked shadows onto the enamel.
        uv = part.data.uv_layers.active.data
        for face in part.data.polygons:
            if abs(face.normal.y)>.99 and abs(face.center.y)<32:
                for loop in face.loop_indices:
                    uv[loop].uv.y += 58
            elif face.normal.y>max(abs(face.normal.x),abs(face.normal.z)) and face.center.y>32:
                # Match front/back window coordinates so cut caps cannot shade the back.
                for loop in face.loop_indices:
                    uv[loop].uv.x *= -1
        part["prefer_front_ao"] = True
        groups.append(("rounded-red-lunch-tin-half-"+str(i+1),[part]))
    for label,z,height in (("rounded-bottom-tin-rim",81.5,3),("deep-lunch-tin-lid",146.15,6.3)):
        slab = box(label,(170,80,height),(0,0,z),1.2 if height==3 else 2.6)
        for i,part in enumerate(closed_bands(slab,[-85,0,85],"silver",axis=0)):
            groups.append((label+"-"+str(i+1),[part]))
    for z,radius in ((82,.7),(143.3,.7),(149.2,.8)):
        rim = tube_path("Continuous rolled lunch tin rim",rounded_plan_path(169,79,6,z),radius,"silver",sides=12)
        for i,part in enumerate(closed_bands(rim,[-86,0,86],"silver",axis=0)):
            groups.append(("rolled-tin-rim-"+str(z)+"-"+str(i+1),[part]))
    liner = []
    for y in (-31.25,31.25):
        wall = box("Silver inside tunnel wall with open windows",(170,.5,42),(0,y,121),.04)
        for x in window_centres:
            cut_opening(wall,(47.2,2,31.2),(x,y,120))
        liner += closed_bands(wall,[-85,0,85],"silver",axis=0)
    for label,z in (("Silver track tunnel floor",99.75),("Silver track tunnel ceiling",142.25)):
        slab = box(label,(170,62,.5),(0,0,z),.04)
        liner += closed_bands(slab,[-85,0,85],"silver",axis=0)
    for sign in (-1,1):
        aperture = tube_path("Rounded rolled end track aperture edge",
            rounded_front_path(66,46,2,-sign*85.5,121),.65,"silver",sides=12)
        liner.append(rotate_about(aperture,90))
    groups.append(("metal-lined-open-track-tunnel",liner))
    for sign in (-1,1):
        for x in window_centres:
            parts = []
            # All four silver reveal faces sit outside the clear rectangle.
            for dx in (-1,1):
                parts.append(gb("Silver long window reveal jamb",(.5,9.1,30),
                    (x+dx*23.25,sign*35.55,120),"silver",.04))
            for dz in (-1,1):
                parts.append(gb("Silver long window reveal sill",(47,9.1,.5),
                    (x,sign*35.55,120+dz*15.25),"silver",.04))
            for dx in (-1,1):
                parts.append(gb("Cream long window upright",(1.2,1.5,32.4),
                    (x+dx*23.6,sign*40.8,120),"cream",.16))
            for dz in (-1,1):
                parts.append(gb("Cream long window sill",(46,1.5,1.2),
                    (x,sign*40.8,120+dz*15.6),"cream",.16))
            groups.append((("front" if sign<0 else "back")+"-open-long-window-"+str(x),parts))
    catches = []
    for x in (-52,52):
        catches += [gb("Riveted lunch tin clasp base",(10,1,8),(x,-40.7,142.5),"silver",.7),
                    gb("Hinged clasp closing over lid",(8,.8,5),(x,-41.5,145),"silver",.5),
                    gc("Round clasp hinge barrel",1.1,10,(x,-41.6,146),"silver","X",24),
                    gb("Real rear lid hinge leaf",(10,1,8),(x,40.6,142.5),"silver",.4),
                    gc("Real rear lid hinge pin",1.1,11,(x,40.9,145.5),"silver","X",24)]
        for dx in (-3,3):
            catches += [gs("Round clasp rivet",.8,(x+dx,-41.4,140.5),"silver",.7)]
    groups.append(("real-hinges-and-closing-clasps",catches))
    return groups


BUILDERS["monorail-station-south"] = monorail_station_south
CAMERAS["monorail-station-south"] = ((0,0,75),218,(-.42,-1,.23))
OPENINGS["monorail-station-south"] = [("road",-44,44,0,80),
    # The axis-x form requires radii; these enclose every rectangular grid sample.
    ("monorail-tunnel",-31,31,100,142,{"axis":"x","cx":0,"cz":121,"rx":62,"rz":42}),
    ("long-window-left",-75,-29,105,135),("long-window-centre",-23,23,105,135),
    ("long-window-right",29,75,105,135)]


def closed_bands(obj,levels,color,axis=2):
    result = []
    for low,high in zip(levels,levels[1:]):
        data = obj.data.copy()
        part = bpy.data.objects.new(obj.name+" closed band",data)
        bpy.context.collection.objects.link(part)
        bm = bmesh.new()
        bm.from_mesh(data)
        for z,inside in ((low,True),(high,False)):
            co,no = [0,0,0],[0,0,0]
            co[axis],no[axis] = z,1
            bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-6,
                plane_co=co,plane_no=no,clear_inner=inside,clear_outer=not inside)
        edges = [e for e in bm.edges if e.is_boundary]
        if edges:
            caps = bmesh.ops.holes_fill(bm,edges=edges,sides=0)["faces"]
            for face in caps:
                face.smooth = False
                for edge in face.edges:
                    edge.smooth = False
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
        result.append(paint(part,color))
    bpy.data.objects.remove(obj,do_unlink=True)
    return result


def tube_path(name,points,radius,color,sides=8,cyclic=True):
    verts,faces = [],[]
    count = len(points)
    reference = Vector((0,0,1)) if max(p[2] for p in points)-min(p[2] for p in points)<1e-5 else Vector((0,1,0))
    for i,point in enumerate(points):
        p = Vector(point)
        previous = (i-1)%count if cyclic else max(0,i-1)
        following = (i+1)%count if cyclic else min(count-1,i+1)
        tangent = (Vector(points[following])-Vector(points[previous])).normalized()
        normal = tangent.cross(reference).normalized()
        if normal.length<.5:
            normal = tangent.cross(Vector((1,0,0))).normalized()
        binormal = tangent.cross(normal).normalized()
        for j in range(sides):
            a = j*2*math.pi/sides
            verts.append(p+radius*(math.cos(a)*normal+math.sin(a)*binormal))
    for i in range(count if cyclic else count-1):
        for j in range(sides):
            a,b = i*sides+j,i*sides+(j+1)%sides
            c,d = ((i+1)%count)*sides+(j+1)%sides,((i+1)%count)*sides+j
            faces.append((a,b,c,d))
    if not cyclic:
        faces += [tuple(reversed(range(sides))),tuple((count-1)*sides+j for j in range(sides))]
    obj = paint(mesh(name,verts,faces),color)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def rounded_front_path(width,height,r,y,zcenter):
    points = []
    for cx,cz,start in ((width/2-r,height/2-r,0),(-width/2+r,height/2-r,90),
                        (-width/2+r,-height/2+r,180),(width/2-r,-height/2+r,270)):
        for a in np.linspace(start,start+90,17,endpoint=False):
            points.append((cx+r*math.cos(math.radians(a)),y,zcenter+cz+r*math.sin(math.radians(a))))
    return points


def rounded_plan_path(width,depth,r,z):
    return [(x,zz,z) for x,y,zz in rounded_front_path(width,depth,r,0,0)]


def rounded_plate(name,width,depth,r,thickness,at,color):
    path = rounded_plan_path(width,depth,r,0)
    n = len(path)
    vertices = [(x+at[0],y+at[1],at[2]+dz) for dz in (-thickness/2,thickness/2) for x,y,z in path]
    faces = [tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    return paint(soften(mesh(name,vertices,faces),min(.12,thickness/4)),color)


def pencil_tin_tower():
    PAINT["tin-blue"] = ("246BA7","enamel")
    PAINT["tin-window"] = ("D5BF94","cardboard")
    PAINT["tin-inner"] = ("969C98","metal")
    body = box("One upright blue metal pencil tin",(100,42,160),(0,0,80),9)
    bands = closed_bands(body,[0,53.33333,106.66667,160],"tin-blue")
    rim = tube_path("Silver rolled tin rim",rounded_front_path(98.4,158.4,9,-21.7,80),.8,"silver")
    rims = closed_bands(rim,[0,53.33333,106.66667,160],"silver")
    seam = tube_path("Second fine rolled tin seam",rounded_front_path(96.2,156.2,8.2,-22.1,80),.35,"silver",sides=12)
    seams = closed_bands(seam,[0,53.33333,106.66667,160],"silver")
    groups = []
    for i,(body,rim) in enumerate(zip(bands,rims)):
        body["prefer_front_ao"] = True
        parts = [body,rim,seams[i]]
        if i:
            z = 102 if i==1 else 140
            for x in (-30,0,30):
                parts += gw(x,z,-21,24,28,trim="tin-window")
            for side in (-90,90):
                parts += gw(0,z,-50,18,26,trim="tin-window",side=side)
        else:
            for x in (-31,31):
                parts += gw(x,42,-21,20,25,trim="tin-window")
            parts += gd(0,14,-21,20,40,trim="tin-window")
            for x,col in ((-15,"yellow"),(-5,"red"),(5,"red"),(15,"yellow")):
                parts += brick((10,8,8.4),(x,-27,9),col,1)
                parts += brick((10,10,4),(x,-33,2),"blue",1)
        groups.append(("upright-tin-band-"+str(i+1),parts))
    canopy = []
    for obj in (rounded_plate("Rounded half-open blue tin lid",92,33.5,5,3,(0,-37.75,73),"tin-blue"),
                rounded_plate("Silver lid underside",90,31.5,4,.25,(0,-37.75,71.4),"tin-inner"),
                rounded_plate("Recessed silver inner lid face",86,27.5,3,.25,(0,-37.75,74.64),"tin-inner")):
        canopy.append(rotate_about(obj,35,"X",(0,-21,73)))
    lip = tube_path("Rounded rolled canopy lip",[(x,y-37.75,z) for x,y,z in rounded_plan_path(90.5,32,4.5,74.6)],.6,"silver",sides=12)
    canopy.append(rotate_about(lip,35,"X",(0,-21,73)))
    for x in np.linspace(-40,40,9):
        canopy += [gc("Thin articulated hinge barrel",1.1,9.8,(x,-22.5,75.8),"silver","X",24)]
    canopy += [gb("Thin metal hinge leaf",(90,.7,3.8),(0,-21.6,74.4),"silver",.1)]
    groups.append(("half-open-canopy-and-real-hinge",canopy))
    return groups


BUILDERS["pencil-tin-tower"] = pencil_tin_tower
CAMERAS["pencil-tin-tower"] = ((0,0,80),191,(.38,-1,.22))


def lid_tape(width,depth,z):
    parts = []
    for x in (-width/2+6,width/2-6):
        for y in (-depth/2,depth/2):
            parts += [gb("Lid corner tape",(4,.2,5),(x,y+math.copysign(.13,y),z-2.5),"cream",.02),
                      gb("Tape folded over lid",(4,6,.12),(x,y-math.copysign(3,y),z+.03),"cream",.02)]
    return parts


def ruler_stilt_tower():
    lower = [gb("Lower box room",(68,68,35),(0,0,25.5)),
             gb("Lower box lid",(76,76,5),(0,0,45.5))]+lid_tape(76,76,48)
    lower += board_edges(76,76,45.5,2)
    for x in (-24,24):
        lower += gw(x,27,-34,14,16,trim="wood")
    lower += gd(0,8,-34,18,28,trim="wood")
    for side in (-90,90):
        lower += gw(0,27,-34,16,16,trim="wood",side=side)
    for x in (-29,29):
        for y in (-28,28):
            lower += brick((8,8,4),(x,y,2),"red" if x<0 else "blue",1)
            lower += brick((8,8,4),(x,y,6),"yellow" if x<0 else "green",1)
    lower += brick((24,10,4),(0,-36,2),"red",4)
    lower += brick((24,8,4),(0,-36,6),"blue",4)
    groups = [("lower-cardboard-room-and-toy-feet",lower)]
    posts = []
    for x in (-32,32):
        for y in (-31,31):
            posts += [gb("Real wood ruler post",(7,4,72),(x,y,84),"wood",.15)]
            for z in (49.5,118.5):
                posts += [gb("Cardboard collar securing ruler into box",(8,7,3),(x,y,z))]
            for i in range(1,90):
                z = 48+i*.8
                length = 3 if i%5==0 else (2 if i%2==0 else 1.2)
                posts += [gb("Plain ruler tick",(length,.12,.15),(x-3+length/2,y-2.1,z),"594B36",0)]
    groups.append(("four-rulers-with-plain-ticks",posts))
    for i,base in enumerate((120,150)):
        parts = [gb("Upper cardboard box",(68,68,26),(0,0,base+13)),
                 gb("Upper box lid",(76,76,4),(0,0,base+28))]+lid_tape(76,76,base+30)
        parts += board_edges(76,76,base+28,2)
        for side in (0,180):
            for x in (-17,17):
                parts += gw(x,base+13,-34,16,18,trim="wood",side=side)
        for side in (-90,90):
            parts += gw(0,base+13,-34,16,18,trim="wood",side=side)
        groups.append(("upper-box-"+str(i+1),parts))
    return groups


BUILDERS["ruler-stilt-tower"] = ruler_stilt_tower
CAMERAS["ruler-stilt-tower"] = ((0,0,90),210,(.38,-1,.21))
OPENINGS["ruler-stilt-tower"] = [("required-between-posts",-28,28,70,120),("full-concept-gap",-28,28,48.1,120)]


def log_cabin_tower():
    PAINT["log-wood"] = ("D3A15F","cabin-wood")
    for i,col in enumerate(("D2A064","D5A66B","CFA064","D3A15F")):
        PAINT["cabin-log-"+str(i)] = (col,"cabin-wood")
    PAINT["end-wood"] = ("CE9F60","cabin-end")
    groups = []
    for first in range(0,14,4):
        parts = []
        for i in range(first,min(14,first+4)):
            for x in (-28.5,28.5):
                z = 5.5+i*11
                parts += [gc("Round lengthwise cabin log",5.5,60,(x,0,z),"cabin-log-"+str(i%4),"Y",24)]
                for y in (-30.12,30.12):
                    parts += [gc("Exposed circular log end grain",5.3,.18,(x,y,z),"end-wood","Y",24)]
            for y in (-23.5,23.5):
                parts += [gc("Cross laid round cabin log",5.5,70,(0,y,11+i*11),"cabin-log-"+str((i+1)%4),"X",24)]
        groups.append(("crossed-log-courses-"+str(first//4+1),parts))
    detail = []
    for z in (132,92,52):
        detail += gw(0,z,-30.35,22,24,mullions=False)
    for side in (-90,90):
        for z in (112,64):
            detail += gw(0,z,-34.1,18,22,mullions=False,side=side)
    door_parts = gd(0,2,-30.35,18,32)
    for obj in list(door_parts):
        if obj.name.startswith("Raised inset door panel"):
            door_parts.remove(obj)
            bpy.data.objects.remove(obj,do_unlink=True)
    detail += door_parts
    for x in (-4.5,0,4.5):
        detail += [gb("Red plank joint",(.18,.12,31.5),(x,-31,18),"A33321",0)]
    detail += [gb("Blue wood toy step",(24,10,4),(0,-33,2),"blue",.5),
               gb("Yellow wood toy step",(22,8,4),(0,-32,6),"yellow",.5)]
    groups.append(("framed-windows-door-and-steps",detail))
    gable = ring_profile("Temporary roof-shaped log trimming volume",[(-38.26087,154),(38.26087,154),(0,198)],70,0,"log-wood",0)
    logs = []
    for z in (165,176,187,198):
        for y in (-23.5,23.5):
            obj = gc("Individual round log filling roof gable",5.5,70,(0,y,z),"log-wood","X",24)
            mod = obj.modifiers.new("Log end cut tight to roof slope","BOOLEAN")
            mod.operation,mod.solver,mod.object = "INTERSECT","EXACT",gable
            apply(obj,mod)
            logs.append(obj)
    bpy.data.objects.remove(gable,do_unlink=True)
    groups.append(("individual-log-gable-courses",logs))
    roof = [ring_profile("Only the two roof slopes are cardboard",[(-40,154),(0,200),(40,154),(40,152),(0,198),(-40,152)],70,0,"kraft",.04)]
    for side in (0,180):
        for sign in (-1,1):
            edge = corrugated_edge(math.hypot(40,46),-35.12,0,1.4)
            for obj in edge:
                rotate_about(obj,sign*math.degrees(math.atan(46/40)),"Y")
                obj.data.transform(Matrix.Translation((sign*20,0,176)))
                if side:
                    rotate_about(obj,side)
            roof += edge
    groups.append(("two-cardboard-roof-slopes-and-cut-edges",roof))
    return groups


BUILDERS["log-cabin-tower"] = log_cabin_tower
CAMERAS["log-cabin-tower"] = ((0,0,96.5),226,(.42,-1,.20))


def lathe(name,profile,color,at=(0,0,0),steps=96):
    vertices,faces,rings = [],[],[]
    for radius,z in profile:
        if radius==0:
            rings.append([len(vertices)])
            vertices.append((at[0],at[1],at[2]+z))
        else:
            ring = []
            for i in range(steps):
                a = i*2*math.pi/steps
                ring.append(len(vertices))
                vertices.append((at[0]+radius*math.cos(a),at[1]+radius*math.sin(a),at[2]+z))
            rings.append(ring)
    for i,ring in enumerate(rings):
        other = rings[(i+1)%len(rings)]
        if len(ring)==len(other)==1:
            continue
        for j in range(steps):
            k = (j+1)%steps
            faces.append((ring[0],other[j],other[k]) if len(ring)==1 else
                ((ring[j],other[0],ring[k]) if len(other)==1 else (ring[j],other[j],other[k],ring[k])))
    obj = paint(mesh(name,vertices,faces),color)
    for face in obj.data.polygons:
        face.use_smooth = abs(face.normal.z)<.98
    return obj


def wrap_cup(parts,base,height,radius,top,angle=0):
    def r(z):
        return radius-1.6+(top+.3-radius+1.6)*min(1,max(0,(z-base-5.2)/(height-6.2)))
    for obj in parts:
        if obj.name.startswith(("Blue recessed window","Door panel","Raised inset door panel")):
            mod = obj.modifiers.new("Conform flat glazing to cup curve","SUBSURF")
            mod.subdivision_type,mod.levels = "SIMPLE",1
            apply(obj,mod)
        points = [v.co for v in obj.data.vertices]
        center_z = (min(v.z for v in points)+max(v.z for v in points))/2
        # All fittings were made on this local tangent plane.
        tangent_radius = obj.get("tangent_radius",r(center_z))
        for vertex in obj.data.vertices:
            co = vertex.co
            co.y = -math.sqrt(max(.01,r(co.z)**2-co.x**2)) + co.y+tangent_radius
        obj.data.update()
        if angle:
            rotate_about(obj,angle)
    return parts


def stacking_cup_tower():
    PAINT["glass"] = ("0C2E6D","cup-glass")
    for key,col in (("cup-blue","0F61CC"),("cup-green","26AD4B"),
                    ("cup-yellow","F5CB15"),("cup-red","E32B20")):
        PAINT[key] = (col,"cup-plastic")
    groups,base = [],0
    for i,(radius,top,height,col) in enumerate(((50,42,60,"cup-blue"),(43,36.5,50,"cup-green"),
            (37,30,46,"cup-yellow"),(31,24,40,"cup-red"),(25,19.5,34,"cup-blue"))):
        roll = [(radius-1+2.2*math.cos(a),2.7+2.2*math.sin(a)) for a in np.linspace(-math.pi/2,math.pi/2,13)]
        profile = [(radius-2.5,0),(radius-1,0)]+roll+[(radius-1.6,5.2),
            (top+.3,height-1),(top,height),(0,height),(0,height-1.5),
            (top-1.5,height-1.5),(radius-3.1,4),(radius-3.2,0)]
        parts = [lathe("Smooth inverted cup with closed top",profile,col,(0,0,base))]
        parts[0]["prefer_front_ao"] = True
        mid = base+height*.53
        rad = radius-1.6+(top+.3-radius+1.6)*(mid-base-5.2)/(height-6.2)
        for angle in ((-40,40,140,220) if i==0 else (0,90,180,270)):
            fittings = gw(0,mid,-rad-.15,22 if i==0 else 17,26 if i==0 else 21,mullions=False)
            for obj in fittings:
                obj["tangent_radius"] = rad
            parts += wrap_cup(fittings,base,height,radius,top,angle)
        if i==0:
            z = 4+30.5/2
            rr = radius-1.6+(top+.3-radius+1.6)*(z-5.2)/(height-6.2)
            fittings = gd(0,4,-rr-.15,17.5,30.5)
            for obj in list(fittings):
                if obj.name.startswith("Raised inset door panel"):
                    fittings.remove(obj)
                    bpy.data.objects.remove(obj,do_unlink=True)
            for obj in fittings:
                obj["tangent_radius"] = rr
            parts += wrap_cup(fittings,base,height,radius,top)
            parts += [gb("Yellow lower cup step",(26,10.4,4.2),(0,-51.5,2.1),"yellow",.5),
                      gb("Red upper cup step",(23,9,4.2),(0,-50.5,6.3),"red",.5)]
        groups.append(("inverted-cup-"+str(i+1),parts))
        base += height
    return groups


BUILDERS["stacking-cup-tower"] = stacking_cup_tower
CAMERAS["stacking-cup-tower"] = ((0,0,110),262,(.32,-1,.18))


def jenga_tower():
    PAINT["jenga-wood"] = ("D1AD7A","jenga")
    PAINT["wood"] = ("C6A680","jenga")
    PAINT["jenga-end"] = ("B18F69","jenga-end")
    for i,col in enumerate(("BFA07A","C8AA82","C3A37B","CDAF88","BA9972","C6A680")):
        PAINT["jenga-block-"+str(i)] = (col,"jenga")
    groups = []
    for first in range(0,15,3):
        parts = []
        for layer in range(first,first+3):
            z = layer*16+8
            along_y = layer%2==0
            for j in range(3):
                offset = (j-1)*55/3
                x,y = (offset,0) if along_y else (0,offset)
                length = 55
                if j==1 and along_y and layer in (8,12):
                    length,y = 53,1
                if j==1 and not along_y and layer in (3,7,13):
                    length,x = 53,-1
                if layer==6 and j==0:
                    y -= 15
                if layer==11 and j==2:
                    x += 15
                w,d = (55/3-1,length) if along_y else (length,55/3-1)
                parts += [gb("Separate long crossed wood block",(w,d,16),(x,y,z),"jenga-block-"+str((layer*3+j)%6),.65)]
                for sign in (-1,1):
                    size = (w-1.4,.12,14.6) if along_y else (.12,d-1.4,14.6)
                    at = (x,y+sign*(d/2+.015),z) if along_y else (x+sign*(w/2+.015),y,z)
                    parts += [gb("Visible cut block end grain",size,at,"jenga-end",.04)]
            if layer in (8,12):
                parts += gw(0,z,-27.55,15,14,trim="wood",mullions=False)
            if layer in (3,7,13):
                parts += gw(0,z,-27.55,15,14,trim="wood",mullions=False,side=90)
            if layer==0:
                parts += gd(0,4,-27.6,14,27,trim="wood")
                parts += [gb("Yellow lower Jenga step",(22,9,3),(0,-31,1.5),"yellow",.4),
                          gb("Blue upper Jenga step",(20,7,3),(0,-30,4.5),"blue",.4)]
        groups.append(("crossed-block-layers-"+str(first//3+1),parts))
    return groups


BUILDERS["jenga-tower"] = jenga_tower
CAMERAS["jenga-tower"] = ((0,0,111),286,(.53,-1,.22))


def ring_binder_tower():
    PAINT["binder-blue"] = ("0E5394","binder-cover")
    PAINT["binder-label"] = ("E4D6B6","label-paper")
    PAINT["binder-pages"] = ("EBDDAB","pages")
    PAINT["glass"] = ("62AAC9","glass")
    levels = [0,60,120,180,239]
    fronts,backs = [],[]
    for y,destination,label in ((-43,fronts,"front"),(43,backs,"back")):
        whole = box("One blue "+label+" binder cover",(130,4,239),(0,y,119.5),1.5)
        for half in closed_bands(whole,[-65,0,65],"binder-blue",axis=0):
            destination.append(closed_bands(half,levels,"binder-blue"))
    spines = closed_bands(box("Curved blue binder spine",(6,69,239),(-62.2,9.5,119.5),2.7),levels,"binder-blue")
    pages = closed_bands(box("Cream stacked paper block",(126,82,238),(0,0,120),.3),levels,"binder-pages")
    groups = []
    for i in range(4):
        parts = [fronts[0][i],fronts[1][i],spines[i],pages[i],backs[0][i],backs[1][i]]
        parts[0]["prefer_front_ao"] = True
        for z in (90,130,170,210):
            if i*60<=z<(i+1)*60:
                for x in (-43,-14,15,44):
                    parts += gw(x,z,-45,20,26,trim="binder-blue")
                    parts += [gb("Cream window sill",(21,2.5,2),(x,-46.5,z-13),"cream",.15)]
        for z in (65,105,145):
            if i*60<=z<(i+1)*60:
                fittings = gw(0,z,-65,18,22,trim="binder-blue",side=-90)
                sill = gb("Cream spine window sill",(19,2.5,2),(0,-66,z-11),"cream",.15)
                fittings += [rotate_about(sill,-90)]
                parts += fittings
        if i==3:
            for w,h,r,y,col in ((55,43,2.5,-65.4,"173F68"),(54,42,2,-65.6,"binder-label")):
                points = rounded_front_path(w,h,r,y,196)
                label = ring_profile("Blank rounded spine label",[(p[0],p[2]) for p in points],.15,y,col,.02)
                rotate_about(label,-90)
                label.data.transform(Matrix.Translation((0,7,0)))
                parts += [label]
        if i==0:
            for x in (-43,44):
                parts += gw(x,30,-45,20,30,trim="binder-blue")
                parts += [gb("Ground window sill",(21,2.5,2),(x,-46.5,15),"cream",.15)]
            door_parts = gd(0,10,-45,25,42)
            for obj in door_parts:
                if obj.name.startswith("Knob"):
                    obj.data.transform(Matrix.Translation((-15,0,0)))
            parts += door_parts
            parts += brick((42,14,4),(0,-50,2),"green",6)
            parts += brick((30,10,4),(0,-50,6),"yellow",5)
            for x in (-17,17):
                parts += brick((8,8,4),(x,-49,6),"blue",1)
                parts += brick((8,8,4),(x,-49,10),"red",1)
        groups.append(("standing-binder-band-"+str(i+1),parts))
    for x in (-32.5,32.5):
        groups.append(("binder-roof-left" if x<0 else "binder-roof-right",
            [gb("Blue binder top edge",(65,90,2),(x,0,239),"binder-blue",.3)]))
    for cx in (-30,30):
        end_angle = math.acos(17/42.5)
        path = [(cx+42.5*math.cos(a),0,270+27.5*math.sin(a))
                for a in np.linspace(-end_angle,math.pi+end_angle,129)]
        parts = [tube_path("Left round-wire binder ring half",path[:65],2.5,"silver",sides=12,cyclic=False),
                 tube_path("Right round-wire binder ring half",path[64:],2.5,"silver",sides=12,cyclic=False),
                 gc("Metal closing sleeve at ring split",2.5,5,(cx,0,297.5),"silver","X",24)]
        parts[0]["prefer_front_ao"] = True
        for dx in (-17,17):
            end_z = 270-27.5*math.sin(end_angle)
            parts += [gb("Metal ring mounting foot",(12,14,2),(cx+dx,0,241),"silver",.7),
                      gc("Metal ring stem into mounting foot",2.5,end_z-242,(cx+dx,0,(242+end_z)/2),"silver",vertices=24),
                      gs("Round mounting rivet",.8,(cx+dx,-3,242.4),"silver",.5),
                      gb("Hinged binder ring clasp leaf",(9,10,1),(cx+dx,0,242.5),"silver",.25),
                      gc("Binder clasp hinge pin",1.1,7,(cx+dx,0,243.1),"silver","Y",24)]
        parts += [gb("Binder clasp closing lever",(6,8,1.2),(cx+17,0,244),"silver",.3)]
        for obj in parts:
            rotate_about(obj,90,"Z",(cx,0,0))
        groups.append(("left-open-metal-ring" if cx<0 else "right-open-metal-ring",parts))
    for label,parts in groups:
        for obj in parts:
            obj["prefer_front_ao"] = True
    return groups


BUILDERS["ring-binder-tower"] = ring_binder_tower
CAMERAS["ring-binder-tower"] = ((0,0,136),336,(-.40,-1,.20))
OPENINGS["ring-binder-tower"] = [("through-both-turned-binder-rings",-22.5,22.5,245,295,
    {"axis":"x","cx":0,"cz":270,"rx":22.5,"rz":25})]


def pencil_pillar_tower():
    PAINT["tip-wood"] = ("DEBA80","pencil-wood")
    PAINT["pillar-kraft"] = ("BA9161","cardboard")
    PAINT["graphite"] = ("25282B","graphite")
    PAINT["pencil-frame-blue"] = ("087BC2","pencil-paint")
    for col in ("red","blue","green","yellow"):
        PAINT["pencil-"+col] = (PAINT[col][0],"pencil-paint")
    PAINT["glass"] = ("153F51","glass")
    groups = []
    for floor in range(7):
        base = floor*46.5
        parts = [gb("Stacked cardboard room",(56,56,42.5),(0,0,base+21.25),"pillar-kraft"),
                 gb("Corrugated cardboard square floor",(64,64,4),(0,0,base+44.5),"pillar-kraft")]
        parts[0]["prefer_front_ao"] = True
        for x,y,col in ((-29.5,-29.5,"red"),(29.5,-29.5,"blue"),
                        (-29.5,29.5,"green"),(29.5,29.5,"yellow")):
            if x>0 and y>0:
                col = ("yellow","green","yellow","green","yellow","yellow","yellow")[floor]
            parts += [gc("Real hexagonal painted pencil column",3.2,46.5,(x,y,base+23.25),"pencil-"+col,vertices=6),
                      gc("Unpainted hexagonal pencil bottom",3.22,5,(x,y,base+2.5),"tip-wood",vertices=6),
                      gb("Cream cardboard pencil collar",(8,8,7),(x,y,base+40),"cream",.2)]
        for side in (0,90,180,270):
            if floor==0 and side==0:
                parts += gd(0,11.4,-28,14,30,trim="wood")
            else:
                parts += gw(0,base+21.5,-28,18,22,trim="pencil-frame-blue",side=side)
        parts += board_edges(64,64,base+44.5,2)+lid_tape(64,64,base+46.5)
        if floor==0:
            parts += brick((20,11,3),(0,-33,1.5),"blue",4)
            parts += brick((18,8,3),(0,-32,5.3),"yellow",4)
            parts += brick((16,6,3),(0,-31,9.1),"green",3)
        groups.append(("pencil-supported-box-"+str(floor+1),parts))
    tips = []
    for x,y,col in ((-29.5,-29.5,"red"),(29.5,-29.5,"blue"),
                    (-29.5,29.5,"green"),(29.5,29.5,"yellow")):
        wood = lathe("Sharpened real hexagonal pencil wood",[(3.2,0),(1.1,15.7),(0,15.7),(0,0)],"tip-wood",(x,y,325.5),6)
        lead = lathe("Dark graphite point above sharpened wood",[(1.1,0),(0,3.8),(0,0)],"graphite",(x,y,341.2),6)
        for obj in (wood,lead):
            for face in obj.data.polygons:
                face.use_smooth = False
        tips += [wood,lead]
    groups.append(("four-sharpened-hex-pencil-tips",tips))
    return groups


BUILDERS["pencil-pillar-tower"] = pencil_pillar_tower
CAMERAS["pencil-pillar-tower"] = ((0,0,167),369,(.43,-1,.06))


def main():
    names = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    if names==["sticky-note-tower"]:
        sticky_main()
    elif len(names)==1 and names[0] in BUILDERS:
        generic_main(names[0])
    else:
        raise SystemExit("Pass one measured building name")


if __name__ == "__main__":
    main()
