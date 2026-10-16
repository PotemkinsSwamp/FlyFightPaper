"""Local classroom building kit. Studs, Z up, front -Y; no uploads.

Blender -b --factory-startup --threads 4 --python-exit-code 1 --python
    tools/art/kit.py -- pieces | shop RECIPE.json | verify

Walls use a 14-stud horizontal grid (28-stud bays) and 28-stud floors.
Pieces are never scaled. A recipe may select 14/28-stud bays, window counts
by floor/side, storefront, door, awnings, trims, roof dressing and extras.
The supplied shop has a purpose-sized 95x63 base, an 84x42 shell, and a
68-stud parapet. Other footprints use the 14-stud floor tiles.

Small mesh/export/material helpers follow toys.py; this file imports none
of the other art scripts. Materials are authored directly into PNG tiles
and palette atlases, rather than baking lighting into the cardboard.
"""

import argparse
import json
import math
import struct
import sys
import zlib
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/kit"
PARTS = OUT / "parts"
BUILDINGS = OUT / "buildings"
COLORS = {
    "card": (185, 139, 88), "edge": (219, 178, 119),
    "cut": (106, 71, 38), "tape": (231, 209, 172),
    "red": (214, 43, 35), "blue": (29, 111, 178),
    "green": (57, 145, 56), "yellow": (246, 187, 29),
    "cream": (249, 229, 191), "ink": (54, 47, 38),
    "wood": (198, 148, 76), "pages": (239, 222, 186),
    "glass": (85, 121, 130), "interior": (101, 63, 35),
    "pink": (239, 129, 140), "brown": (130, 72, 37),
    "leaf": (59, 124, 48), "white": (255, 247, 220),
    "metal": (155, 156, 145), "ruler": (225, 184, 114),
    "card-light": (199, 156, 105), "card-warm": (176, 127, 78),
}
COMPONENTS = []
MATERIALS = {}


def log(message):
    print("KIT " + message, flush=True)


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def linear(color):
    def channel(v):
        v /= 255
        return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
    return tuple(channel(v) for v in color) + (1,)


def material(key):
    if key not in MATERIALS:
        mat = bpy.data.materials.new(key)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = linear(COLORS[key])
        bsdf.inputs["Roughness"].default_value = .8 if key in ("card", "cut", "pages") else .38
        MATERIALS[key] = mat
    return MATERIALS[key]


def finish(obj, key):
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(material(key))
    COMPONENTS.append(obj)
    return obj


def box(size, pos=(0, 0, 0), key="card", bevel=0, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Crisp molded edge", "BEVEL")
        mod.width, mod.segments = bevel, 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.rotation_euler = rotation
    return finish(obj, key)


def mesh(vertices, faces, key):
    data = bpy.data.meshes.new(key)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(key, data)
    bpy.context.collection.objects.link(obj)
    return finish(obj, key)


def profile(points, depth, key, y=0):
    """Closed polygon in XZ extruded along Y, as in toys.py's profile helper."""
    n = len(points)
    vertices = [(x, y + side * depth / 2, z) for side in (-1, 1) for x, z in points]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    return mesh(vertices, faces, key)


def ring(outer, inner, depth, key, y=0):
    n = len(outer)
    assert n == len(inner)
    vertices = [(x, y + side * depth / 2, z) for side in (-1, 1)
                for contour in (outer, inner) for x, z in contour]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces += [(i, j, j + 2 * n, i + 2 * n),
                  (i + n, i + 3 * n, j + 3 * n, j + n),
                  (i, i + n, j + n, j),
                  (i + 2 * n, j + 2 * n, j + 3 * n, i + 3 * n)]
    return mesh(vertices, faces, key)


def cylinder(radius, depth, pos, key, axis="Z", sectors=8, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=sectors, radius1=radius,
                                  radius2=radius if top is None else top,
                                  depth=depth, location=pos)
    obj = bpy.context.object
    if axis == "Y": obj.rotation_euler.x = math.pi / 2
    if axis == "X": obj.rotation_euler.y = math.pi / 2
    return finish(obj, key)


def stem(a, b, radius, key="wood", sectors=6):
    a, b = Vector(a), Vector(b)
    obj = cylinder(radius, (b - a).length, (a + b) / 2, key, sectors=sectors)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def arch(w=14, h=20, bottom=-10, steps=10):
    r = w / 2
    spring = bottom + h - r
    return [(-r, bottom), (r, bottom)] + [
        (r * math.cos(t), spring + r * math.sin(t))
        for t in np.linspace(0, math.pi, steps + 1)]


def rectangle(w, h, bottom):
    return [(-w / 2, bottom), (w / 2, bottom), (w / 2, bottom + h), (-w / 2, bottom + h)]


def wall(width=28, hole=None):
    if not hole:
        box((width, 1.2, 28))
        return
    w, h, bottom = {"square": (14, 20, -10), "arch": (14, 20, -10),
                    "shop": (50, 22, -11), "door": (14, 26, -14)}[hole]
    for side in (-1, 1):
        box(((width - w) / 2, 1.2, 28), (side * (width + w) / 4, 0, 0))
    if bottom > -14:
        box((w, 1.2, bottom + 14), (0, 0, (bottom - 14) / 2))
    if hole == "arch":
        spring = bottom + h - w / 2
        points = [(-w / 2, 14), (w / 2, 14)] + [
            (w / 2 * math.cos(t), spring + w / 2 * math.sin(t))
            for t in np.linspace(0, math.pi, 11)]
        profile(points, 1.2, "card")
    else:
        top = bottom + h
        box((w, 1.2, 14 - top), (0, 0, (14 + top) / 2))


def flutes(length, cycles=None):
    # A thin, closed zigzag web between two liners. The triangular spaces
    # really are empty, including after FBX import; no painted fake flutes.
    for z in (-.56, .56): box((length, 1.2, .12), (0, 0, z), "edge")
    cycles = cycles or max(3, round(length * 8 / 14))
    xs = np.linspace(-length / 2, length / 2, cycles * 2 + 1)
    upper = [(float(x), .46 if i % 2 else -.38) for i, x in enumerate(xs)]
    lower = [(x, z - .10) for x, z in reversed(upper)]
    profile(upper + lower, 1.08, "edge")


def brick(nx, ny):
    w, d = nx * 3.5, ny * 3.5
    box((w, d, 3), key="red", bevel=.12)
    for x in range(nx):
        for y in range(ny):
            cylinder(1.08, .8, ((x + .5) * 3.5 - w / 2,
                               (y + .5) * 3.5 - d / 2, 1.9), "red")


def plant(x, z, flowers=True):
    box((.5, .5, 2.4), (x, -1.6, z + 1.2), "leaf")
    for side in (-1, 1):
        profile([(x, z + .7), (x + side * 1.2, z + 1.3),
                 (x + side * 1.3, z + 2.5), (x + side * .3, z + 2.1)], .3, "leaf", -1.6)
    if flowers:
        cylinder(1, .55, (x, -1.65, z + 2.8), "yellow", "Y", sectors=6)
        cylinder(.4, .6, (x, -1.75, z + 2.8), "pink", "Y", sectors=6)


def window(style):
    inner = arch() if style == "arch" else rectangle(14, 20, -10)
    outer = arch(16, 22, -11) if style == "arch" else rectangle(16, 22, -11)
    ring(outer, inner, 1.05, "cream", -.65)
    profile(inner, .18, "interior", .44)
    # Chunky books and a cut-paper lampshade behind the frame, as in the concept.
    for i, key in enumerate(("blue", "red", "green")):
        box((3.2, .55, 1.65), (3.3, .02, -7 + i * 1.7), key)
        box((2.9, .12, .45), (3.3, -.31, -6.9 + i * 1.7), "pages")
    box((2, .6, .55), (-3.3, .02, -7.5), "yellow")
    box((.45, .45, 7), (-3.3, .02, -4), "yellow")
    profile([(-5.5, -.5), (-1.1, -.5), (-2.2, 2.5), (-4.4, 2.5)], .6, "red", -.05)
    box((.65, .75, 19.5), (0, -.65, -.25), "cream")
    box((14, .75, .65), (0, -.65, 3), "cream")
    box((18, 3.6, 1.25), (0, -1, -10.6), "red", .08)
    # Open flower box with a dark soil floor, three flowers and cut-paper leaves.
    for x in (-7.7, 7.7): box((.6, 2.8, 2.4), (x, -1.7, -9.6), "red")
    for y in (-3.1, -.3): box((16, .5, 2.4), (0, y, -9.6), "red")
    box((15, 2.4, .25), (0, -1.7, -9.65), "brown")
    for x in (-4.8, 0, 4.8): plant(x, -8.4)


def shop_window():
    ring(rectangle(52, 24, -12), rectangle(50, 22, -11), 1.1, "cream", -.6)
    # Clear aperture; the separate display supplies the recessed back wall.
    for x in (-8.3, 8.3): box((.65, .9, 22), (x, -.65, 0), "cream")
    box((50, .85, .7), (0, -.65, 7), "cream")
    box((54, 3.4, 1.1), (0, -1, -11.8), "cream", .07)


def door():
    ring(rectangle(16, 27, -13.5), rectangle(14, 26, -13.5), 1.2, "cream", -.5)
    # A real aperture, rather than a glass rectangle buried in a solid door.
    for x in (-5.5, 5.5): box((2.4, .7, 25.5), (x, .1, -.5), "red")
    box((8.6, .7, .95), (0, .1, 11.775), "red")
    box((8.6, .7, 12.95), (0, .1, -6.775), "red")
    ring(rectangle(10, 13, -1), rectangle(8.6, 11.6, -.3), .6, "cream", -.52)
    box((8.6, .15, 11.6), (0, .4, 5.5), "interior")
    for x, z, key in ((-2, 1.6, "blue"), (2, 1.6, "yellow"), (2, 4.3, "pink")):
        box((2.7, .5, 2.4), (x, .05, z), key)
        box((.4, .12, 2.5), (x, -.26, z), "cream")
    box((.55, .6, 11.6), (0, -.55, 5.5), "cream")
    box((8.6, .6, .55), (0, -.55, 5.5), "cream")
    box((10.5, .2, 7), (0, -.38, -7.7), "red", .07)
    cylinder(.95, .85, (4.8, -.95, -3), "yellow", "Y", sectors=10)
    box((17, 3.8, .8), (0, -1, -13.1), "cream")


def awning():
    # One repeatable 14-stud stripe pair, including its actual scallops.
    for i, key in enumerate(("red", "cream")):
        x = -3.5 + i * 7
        # Slope in YZ, extruded along X, then turn the profile helper's axes.
        points = [(0, 0), (-7, -3.5), (-7, -4.05), (0, -.55)]
        obj = profile(points, 7, key)
        obj.rotation_euler.z = math.pi / 2
        obj.location.x = x
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        scallop = [(x - 3.5, -3.5), (x + 3.5, -3.5), (x + 3.5, -5)]
        scallop += [(x + 3.5 * math.cos(t), -5 - .8 * math.sin(t))
                    for t in np.linspace(0, math.pi, 7)]
        profile(scallop, .65, key, -7)
    stem((-6, -.2, -4.8), (-6, -6, -3.4), .35, "wood")
    stem((6, -.2, -4.8), (6, -6, -3.4), .35, "wood")


def book_slab(width=28):
    box((width, 14, 2.2), key="pages")
    for z in (-1.3, 1.3): box((width, 14, .4), (0, 0, z), "blue")
    box((width, .6, 2.6), (0, -6.7, 0), "blue", .05)
    for x in (-width / 2 + 2.3, width / 2 - 2.3): box((.65, .08, 2.1), (x, -7.03, 0), "yellow")


def side_awning():
    # Shorter projection keeps the right window canopy inside the shop base.
    for i in range(4):
        x = (i - 1.5) * 4.5
        key = "red" if i % 2 == 0 else "cream"
        obj = profile([(0, 0), (-4, -2), (-4, -2.5), (0, -.5)], 4.5, key)
        obj.rotation_euler.z = math.pi / 2
        obj.location.x = x
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        points = [(x - 2.25, -2), (x + 2.25, -2), (x + 2.25, -3.1)]
        points += [(x + 2.25 * math.cos(t), -3.1 - .6 * math.sin(t))
                   for t in np.linspace(0, math.pi, 7)]
        profile(points, .5, key, -4)
    for x in (-7.5, 7.5): stem((x, -.2, -3.3), (x, -3.7, -1.9), .3, "wood")


def cardboard_floor(width, depth):
    # Full footprint skins, inset core. Perimeter flute webs sit in the actual
    # open channel, so a solid board cannot obscure the cut-edge holes.
    for z in (-.875, .875): box((width, depth, .25), (0, 0, z))
    box((width - 2.4, depth - 2.4, 1.5))


def pencil():
    cylinder(1.25, 20, (0, 0, 0), "yellow", sectors=6)
    cylinder(1.25, 3, (0, 0, 11.5), "wood", sectors=6, top=.18)
    cylinder(.25, 1.1, (0, 0, 13.25), "ink", sectors=6, top=0)
    cylinder(1.28, 1.8, (0, 0, -10.9), "metal", sectors=6)
    for z in (-10.4, -11.4): cylinder(1.35, .25, (0, 0, z), "metal", sectors=6)
    cylinder(1.26, 2, (0, 0, -12.8), "pink", sectors=6)


def bunting(length=28):
    box((length, .2, .22), (0, 0, 2.3), "ink")
    count = round(length / 4)
    for i in range(count):
        x = (i - (count - 1) / 2) * length / count
        profile([(x - 1.85, 2.3), (x + 1.85, 2.3), (x, -2.3)], .12,
                "red" if i % 2 == 0 else "cream")


def chimney():
    # Separate blue toy blocks leave real shadow joints, with a grey vent cap.
    for z in (-3.4, 0, 3.4):
        for x in (-2.05, 2.05):
            box((3.9, 8, 3.2), (x, 0, z), "blue")
    box((10, 10, 1), (0, 0, 5.5), "metal")
    for x in (-2.4, 2.4): box((1.3, 5, 2), (x, 0, 7), "ink")
    box((10, 10, 1.4), (0, 0, 8.7), "metal", .05)


def cupcake(x, y, z, flavor="white", scale=1):
    cylinder(1.2 * scale, 1.6 * scale, (x, y, z + .8 * scale), "yellow", top=1.55 * scale)
    cylinder(1.65 * scale, .8 * scale, (x, y, z + 2 * scale), flavor, top=1.1 * scale)
    cylinder(1.1 * scale, .9 * scale, (x, y, z + 2.8 * scale), flavor, top=.3 * scale)
    cylinder(.45 * scale, .5 * scale, (x, y, z + 3.5 * scale), "red", sectors=6)


def display():
    box((49, .6, 21), (0, 3.3, 0), "interior")
    for z in (-9.5, -3, 4): box((48, 4.2, .7), (0, 1.4, z), "wood", .08)
    for x in (-17, -9, 0, 9, 18):
        cupcake(x, .6, 4.4, "pink" if x % 2 else "white")
        if x: cupcake(x, .5, -2.6, "brown" if x < 0 else "white")
    cylinder(4.3, 2, (0, .6, -1.6), "white", sectors=12)
    cylinder(3.5, 1.8, (0, .6, .3), "white", sectors=12)
    for x in (-2, 0, 2): cylinder(.65, .7, (x, .6, 1.55), "red")
    for x, key in ((-18, "yellow"), (-10, "blue"), (1, "pink"), (9, "green"), (18, "red")):
        box((5, 3.2, 3), (x, .8, -7.6), key, .1)
        box((.65, 3.25, 3.2), (x, .8, -7.6), "cream")


def cupcake_sign():
    # Right-hand hanging medallion, facing the front; all ornament is raised geometry.
    cylinder(6.8, 1.4, (0, 0, 0), "red", "Y", sectors=24)
    cylinder(5.7, 1.52, (0, -.05, 0), "cream", "Y", sectors=24)
    profile([(-2.7, -1), (2.7, -1), (1.9, -4), (-1.9, -4)], .6, "red", -1)
    for x in (-1.2, 0, 1.2): box((.18, .72, 2.4), (x, -1.12, -2.6), "brown")
    for x, z, r in ((-2.2, -.2, 1.3), (0, .7, 1.8), (2.2, -.2, 1.3)):
        cylinder(r, .7, (x, -1, z), "white", "Y", sectors=10)
    cylinder(.8, .8, (.3, -1.1, 2.65), "red", "Y", sectors=10)
    for x in (-3.5, 3.5): stem((x, 0, 5.8), (x, 0, 9), .3, "metal")
    stem((-5.5, 0, 9), (5.5, 0, 9), .55, "ink")
    stem((-5.5, 0, 9), (-5.5, 0, 4.8), .55, "ink")
    cylinder(.8, 1, (5.6, 0, 9), "yellow", "X")


def brick_band():
    box((14, 1.2, 2.4), key="blue")
    box((.12, .04, 2.4), (0, -.62, 0), "ink")
    for x in (-3.5, 3.5): cylinder(.7, .45, (x, -.75, 0), "blue", "Y", sectors=6)


def quoin_column():
    # One complete L-shaped column, instead of dozens of placed toy bricks.
    for i in range(18):
        z = (i + .5) * 60 / 18
        key = ("blue", "green", "yellow", "red")[i % 4]
        box((3.5, 1.5, 3.15), (1.75, -.15, z), key)
        box((1.5, 3.5, 3.15), (-.15, 1.75, z), key)
        if i % 4 == 0:
            cylinder(.65, .4, (1.75, -1.05, z), key, "Y", sectors=6)
            cylinder(.65, .4, (-1.05, 1.75, z), key, "X", sectors=6)


def corner_flutes():
    # Wide enough to read beside the brick clips; open webs on both faces.
    for side in range(2):
        start = len(COMPONENTS)
        flutes(60, cycles=16)
        for obj in COMPONENTS[start:]:
            rotation = Euler((0, -math.pi / 2, side * -math.pi / 2))
            offset = (4.15, -.7, 30) if side == 0 else (-.7, 4.15, 30)
            obj.location = rotation.to_matrix() @ obj.location + Vector(offset)
            obj.rotation_euler = rotation
            active(obj)
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def tape_cluster():
    # Off-centre, torn-looking tape in three sizes and angles, clear of windows.
    for size, x, z, tilt in (((4.4, .15, 2.6), -10.5, -7, -.18),
                             ((2, .15, 6), 10.5, 5, .24),
                             ((6.8, .15, 2.2), -4, 11.7, -.08),
                             ((3.4, .15, 1.4), 8, -11.8, .12)):
        box(size, (x, -.03, z), "tape", rotation=(0, tilt, 0))


def shop_plinth():
    for i in range(8):
        box((6.6, 1.7, 3.6), ((i - 3.5) * 6.75, 0, 0), "red")


def roof_box():
    box((9, 7, 4), (0, 0, 2))
    box((9.2, 7.2, .3), (0, 0, 4.15), "card-light")
    box((1.5, 7.3, .12), (1.5, 0, 4.36), "tape")
    box((1.5, .15, 2.3), (1.5, -3.58, 3.2), "tape")
    for x in (-2.5, 0, 2.5): box((.8, .1, 1.8), (x, -3.56, 1.5), "cut")


def tape_roll():
    # A real hollow cardboard core, lying flat on the roof.
    outer = [(3.6 * math.cos(t), 3.6 * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 17)[:-1]]
    inner = [(2.1 * math.cos(t), 2.1 * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 17)[:-1]]
    obj = ring(outer, inner, 2.4, "tape")
    obj.rotation_euler.x = math.pi / 2
    obj.location.z = 1.2
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box((3.8, 2, .1), (3.8, 0, .12), "tape", rotation=(0, 0, -.15))


def drainpipe():
    cylinder(.55, 57, (0, 0, 28.5), "ink", sectors=8)
    for z in (5, 25, 45, 55):
        cylinder(.72, .7, (0, 0, z), "metal", sectors=8)
        box((1.8, .3, .6), (0, .4, z), "ink")
    stem((0, 0, 1), (0, -1.8, .5), .55, "ink", sectors=8)


def doormat():
    box((13, 5, .3), key="red")
    box((11.6, 3.7, .08), (0, 0, .18), "brown")
    for x in range(-5, 6): box((.13, 3.4, .07), (x, 0, .24), "wood")


def bunting_post():
    box((.8, .8, 9), (0, 0, 4.5), "wood")
    box((1.5, 1.5, .7), (0, 0, 8.8), "brown")


def piece_specs():
    return {
        "wall-plain": (lambda: wall(), 600, True, "card"),
        "wall-half": (lambda: wall(14), 600, True, "card"),
        "wall-narrow": (lambda: wall(7), 600, True, "card"),
        "wall-square": (lambda: wall(hole="square"), 600, True, "card"),
        "wall-arch": (lambda: wall(hole="arch"), 600, True, "card"),
        "wall-shop": (lambda: wall(56, "shop"), 600, True, "card"),
        "wall-door": (lambda: wall(hole="door"), 600, True, "card"),
        "wall-corner": (lambda: (box((2.4, 1.2, 28), (0, -.6, 0)),
                                  box((1.2, 1.2, 28), (-.6, .6, 0))), 600, True, None),
        **{f"fluted-edge{suffix}": (lambda n=n: flutes(n), 600, False, None)
           for suffix, n in (("", 14), ("-half", 7), ("-cap", 5.5))},
        "tape-patch": (lambda: box((6, .12, 3.6), key="tape"), 100, False, None),
        "tape-strip": (lambda: box((2, .12, 9), key="tape", rotation=(0, .12, 0)), 100, False, None),
        **{f"brick-{name}": (lambda x=x, y=y: brick(x, y), 299, False, "red")
           for name, x, y in (("1x1", 1, 1), ("2x2", 2, 2), ("2x4", 4, 2))},
        "brick-band": (brick_band, 300, False, "blue"),
        "window-arch": (lambda: window("arch"), 800, False, "red"),
        "window-square": (lambda: window("square"), 800, False, "red"),
        "shop-window": (shop_window, 400, False, None),
        "door": (door, 600, False, "red"),
        "awning": (awning, 500, False, "red"),
        "side-awning": (side_awning, 300, False, "red"),
        "ruler-cornice": (lambda: box((28, 2.2, 1.2), key="ruler", bevel=.05), 100, False, None),
        "book-slab": (book_slab, 200, False, "blue"),
        "book-slab-half": (lambda: book_slab(14), 200, False, "blue"),
        "pencil-column": (pencil, 250, False, "yellow"),
        "paper-bunting": (bunting, 100, False, "red"),
        "roof-parapet": (lambda: box((28, 1.2, 5)), 600, True, None),
        "roof-parapet-half": (lambda: box((14, 1.2, 5)), 600, True, None),
        "cardboard-floor": (lambda: cardboard_floor(28, 14), 600, True, None),
        "cardboard-floor-half": (lambda: cardboard_floor(14, 14), 600, True, None),
        "cardboard-base": (lambda: cardboard_floor(95, 63), 600, True, None),
        "rooftop-chimney": (chimney, 500, False, "blue"),
        "sweet-display": (display, 2600, False, None),
        "cupcake-sign": (cupcake_sign, 900, False, None),
        "quoin-column": (quoin_column, 700, False, None),
        "corner-flutes": (corner_flutes, 600, False, None),
        "fluted-run": (lambda: flutes(84, cycles=24), 650, False, None),
        "fluted-run-half": (lambda: flutes(42, cycles=12), 350, False, None),
        "panel-seam": (lambda: box((.18, .14, 28), key="cut"), 100, False, None),
        "tape-cluster": (tape_cluster, 100, False, None),
        "shop-plinth": (shop_plinth, 200, False, None),
        "topper-plinth": (lambda: box((16, 11, 6.5), (0, 0, 3.25)), 100, True, None),
        "roof-box": (roof_box, 200, False, None),
        "tape-roll": (tape_roll, 200, False, None),
        "bunting-post": (bunting_post, 100, False, None),
        "paper-bunting-half": (lambda: bunting(14), 100, False, "red"),
        "drainpipe": (drainpipe, 300, False, None),
        "doormat": (doormat, 200, False, None),
    }


def bounds(obj):
    points = np.array([tuple(obj.matrix_world @ v.co) for v in obj.data.vertices])
    return points.min(axis=0), points.max(axis=0)


def triangles(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def topology(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    # FBX can split UV/normal seams. Weld only for the topology check.
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.00001)
    boundary = sum(e.is_boundary for e in bm.edges)
    loose = sum(not e.link_faces for e in bm.edges)
    bm.free()
    return boundary, loose


def png_write(path, pixels):
    """The small dependency-free PNG writer from toys.py."""
    height, width, _ = pixels.shape
    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload +
                struct.pack(">I", zlib.crc32(tag + payload) & 0xffffffff))
    raw = b"".join(b"\0" + row.tobytes() for row in pixels)
    data = (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))
    changed = path.exists() and path.read_bytes() != data
    if not path.exists() or changed: path.write_bytes(data)
    return changed


def tile(key, side, variant=None, replace=None):
    """Seamless, restrained paper fibres; striped ruler/page detail is real texel art."""
    key_color = variant if key == replace and variant else key
    yy, xx = np.mgrid[0:side, 0:side] / side
    grain = (np.sin(xx * 2 * math.pi * 63) * np.sin(yy * 2 * math.pi * 97) +
             .45 * np.sin((xx * 41 + yy * 89) * 2 * math.pi))
    height = .001 * grain
    factor = 1 + .008 * grain
    if key == "card":
        # Tile is exactly eight studs: 512/8 = 64 pixels per stud.
        factor += .025 * np.cos(xx * 2 * math.pi * 24)
        height += .014 * np.cos(xx * 2 * math.pi * 24)
    if key == "pages":
        factor -= .10 * (np.mod(yy * 48, 1) < .15)
    if key == "tape":
        factor += .025 * np.cos((xx + yy) * 2 * math.pi * 12)
    color = np.clip(np.array(COLORS[key_color])[None, None, :] * factor[:, :, None], 0, 255).astype(np.uint8)
    if key == "ruler":
        ticks = np.mod(xx * 28, 1) < .10
        major = np.mod(xx * 7, 1) < .035
        mask = (ticks & (yy < .23)) | (major & (yy < .43)) | (yy < .035)
        color[mask] = COLORS["ink"]
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * side / 16
    dy = (np.roll(height, 1, axis=0) - np.roll(height, -1, axis=0)) * side / 16
    normal = np.stack((-dx, -dy, np.ones_like(dx)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    normal = np.clip((normal * .5 + .5) * 255, 0, 255).astype(np.uint8)
    rough = .82 if key in ("card", "edge", "cut", "pages") else .42
    roughness = np.repeat(np.clip((rough + .012 * grain) * 255, 0, 255).astype(np.uint8)[:, :, None], 3, axis=2)
    return color, normal, roughness


def author_maps(obj, name, tiled, replace):
    keys = [m.name for m in obj.data.materials]
    # Blender may suffix materials on reruns, but generation keeps one material per palette key.
    assert all(k in COLORS for k in keys), keys
    grid = 1 if tiled else math.ceil(math.sqrt(len(keys)))
    cell = 512 if tiled else 1024 // (2 ** math.ceil(math.log2(grid)))
    grid = 1 if tiled else 1024 // cell
    side = cell * grid
    while obj.data.uv_layers: obj.data.uv_layers.remove(obj.data.uv_layers[0])
    uv = obj.data.uv_layers.new(name="KitUV")
    uv.active_render = True
    for face in obj.data.polygons:
        axes = {0: (1, 2), 1: (0, 2), 2: (0, 1)}[int(np.argmax(np.abs(face.normal)))]
        coords = np.array([[obj.data.vertices[v].co[a] for a in axes] for v in face.vertices])
        if tiled:
            coords /= 8
        else:
            low, high = coords.min(axis=0), coords.max(axis=0)
            coords = (coords - low) / np.maximum(high - low, 1e-7)
            ix, iy = face.material_index % grid, face.material_index // grid
            coords = (coords * (cell - 16) + np.array([ix * cell + 8, iy * cell + 8])) / side
        for loop, coordinate in zip(face.loop_indices, coords): uv.data[loop].uv = coordinate
    palette = ("card-light", "card-warm") if replace == "card" else ("red", "blue", "green", "yellow")
    variants = [None] + ([v for v in palette if v != replace] if replace else [])
    changed_maps = False
    for variant in variants:
        maps = [np.zeros((side, side, 3), dtype=np.uint8) for _ in range(3)]
        for i, key in enumerate(keys):
            x, y = i % grid * cell, i // grid * cell
            for array, pixels in zip(maps, tile(key, cell, variant, replace)):
                # PNG is top-down, UV V is bottom-up.
                array[side - y - cell:side - y, x:x + cell] = pixels
        for channel, pixels in zip(("color", "normal", "roughness"), maps):
            if variant and channel != "color": continue
            suffix = channel + ("-" + variant if variant else "")
            changed_maps |= png_write(PARTS / f"{name}-{suffix}.png", pixels)
    return ["color"] + ["color-" + v for v in variants if v], changed_maps


def baked_material(name, folder, color="color", uv_name="KitUV"):
    """The same three-map shader/export contract as toys.py and hero.py."""
    mat = bpy.data.materials.new(name + " " + color)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Specular IOR Level"].default_value = .27
    for channel in ("color", "normal", "roughness"):
        tex = nodes.new("ShaderNodeTexImage")
        key = color if channel == "color" else channel
        tex.image = bpy.data.images.load(str(folder / f"{name}-{key}.png"), check_existing=True)
        tex.image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
        tex.extension = "REPEAT"
        if channel == "normal":
            normal = nodes.new("ShaderNodeNormalMap")
            normal.uv_map = uv_name
            links.new(tex.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
        else:
            links.new(tex.outputs["Color"], bsdf.inputs["Base Color" if channel == "color" else "Roughness"])
    return mat


def one_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for face in obj.data.polygons: face.material_index = 0


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    COMPONENTS.clear()


def mesh_signature(obj):
    """Compare export geometry and UVs without FBX timestamps or vertex ordering."""
    obj.data.calc_loop_triangles()
    uv = obj.data.uv_layers[0].data
    faces = []
    for tri in obj.data.loop_triangles:
        corners = [tuple(round(float(v), 3) for v in (*obj.data.vertices[vertex].co, *uv[loop].uv))
                   for vertex, loop in zip(tri.vertices, tri.loops)]
        faces.append(tuple(sorted(corners)))
    return tuple(sorted(faces))


def make_pieces():
    PARTS.mkdir(parents=True, exist_ok=True)
    catalog = {}
    for name, (builder, limit, tiled, replace) in piece_specs().items():
        clear()
        builder()
        bpy.ops.object.select_all(action="DESELECT")
        for obj in COMPONENTS: obj.select_set(True)
        bpy.context.view_layer.objects.active = COMPONENTS[0]
        if len(COMPONENTS) > 1: bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = name
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data)
        bm.free()
        low, high = bounds(obj)
        center = (low + high) / 2
        for v in obj.data.vertices: v.co -= Vector(center)
        obj.data.update()
        colors, changed_maps = author_maps(obj, name, tiled, replace)
        one_material(obj, baked_material(name, PARTS))
        mod = obj.modifiers.new("Export actual triangles", "TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=mod.name)
        count = triangles(obj)
        assert count <= limit, (name, count, limit)
        assert topology(obj) == (0, 0), (name, topology(obj))
        target = PARTS / f"{name}.fbx"
        changed_mesh = not target.exists()
        if target.exists():
            existing = load_fbx(target)
            changed_mesh = mesh_signature(existing) != mesh_signature(obj)
            bpy.data.objects.remove(existing, do_unlink=True)
        if changed_mesh:
            active(obj)
            bpy.ops.export_scene.fbx(filepath=str(target), use_selection=True,
                                     object_types={"MESH"}, apply_unit_scale=False, global_scale=1,
                                     axis_forward="-Z", axis_up="Y", bake_space_transform=False,
                                     mesh_smooth_type="OFF", path_mode="AUTO", embed_textures=False,
                                     add_leaf_bones=False)
        record = PARTS / f"{name}.upload.json"
        if record.exists() and (changed_mesh or changed_maps):
            record.unlink()
            log(f"deleted upload record: {name}")
        catalog[name] = {"size": (high - low).round(5).tolist(),
                         "center": center.round(5).tolist(), "triangles": count,
                         "limit": limit, "closed": True, "colors": colors,
                         "tile_studs": 8 if tiled else None,
                         "pixels_per_stud": 64 if tiled else None}
        log(f"{name}: {count} triangles; {', '.join(colors)}")
    (OUT / "pieces.json").write_text(json.dumps(catalog, indent=2) + "\n")
    log(f"pieces PASS: {len(catalog)} meshes")


def load_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
    imported = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in imported if o.type == "MESH"]
    assert len(meshes) == 1, (path, "expected one mesh", len(meshes))
    obj = meshes[0]
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def recipe_rows(recipe, catalog):
    rows = []
    width, depth = float(recipe["width"]), float(recipe["depth"])
    w, d = recipe.get("shell", [84, 42] if (width, depth) == (95, 63) else [width - 14, depth - 14])
    w, d = float(w), float(d)
    floors = recipe.get("floors", 2)
    assert isinstance(floors, int) and 1 <= floors <= 6, "floors must be 1..6"
    assert all(v > 0 and abs(v / 14 - round(v / 14)) < 1e-5 for v in (w, d)), "shell uses the 14-stud grid"
    assert width >= w and depth >= d, "footprint must contain the shell"
    assert recipe.get("floor_height", 28) == 28, "wall pieces have a fixed 28-stud floor height"
    assert width > 0 and depth > 0

    def add(name, pos, yaw=0, color="color"):
        rec = catalog[name]
        assert color in rec["colors"], (name, color)
        c, s = math.cos(yaw), math.sin(yaw)
        x, y, z = rec["center"]
        center = [pos[0] + c * x - s * y, pos[1] + s * x + c * y, pos[2] + z]
        rows.append({"piece": "kit/" + name, "color": color,
                     "offset": [round(v, 6) for v in center], "yaw": yaw,
                     "size": rec["size"]})

    sides = {"front": ((0, -d / 2), 0, w), "back": ((0, d / 2), math.pi, w),
             "left": ((-w / 2, 0), -math.pi / 2, d), "right": ((w / 2, 0), math.pi / 2, d)}

    def on_side(name, side, u, z, out=0, color="color"):
        (x, y), yaw, _ = sides[side]
        c, s = math.cos(yaw), math.sin(yaw)
        if name.startswith("wall-") and recipe.get("panel_details", False):
            index = (round(u / 7) + round((z - 16) / 31) + list(sides).index(side)) % 3
            color = ("color", "color-card-light", "color-card-warm")[index]
        add(name, (x + c * u + s * out, y + s * u - c * out, z), yaw, color)
        if name.startswith("wall-") and recipe.get("panel_details", False):
            # A recessed-looking dark join at every panel boundary.
            half = catalog[name]["size"][0] / 2
            on_side("panel-seam", side, u - half + .1, z, .64)
            if name in ("wall-arch", "wall-square", "wall-plain", "wall-half"):
                on_side("tape-cluster", side, u, z, .73)

    def plain(side, a, b, z):
        cursor = a
        for length, name in ((28, "wall-plain"), (14, "wall-half"), (7, "wall-narrow")):
            while b - cursor >= length - 1e-5:
                on_side(name, side, cursor + length / 2, z)
                cursor += length
        assert abs(b - cursor) < .001, "wall gaps must be multiples of 7 studs"

    def bays(side, count, style, z, door_here=False):
        length = sides[side][2]
        if door_here:
            assert length >= 28
            plain(side, -length / 2, -14, z)
            on_side("wall-door", side, 0, z)
            on_side("door", side, 0, z - .5)
            plain(side, 14, length / 2, z)
            return
        assert isinstance(count, int) and count >= 0
        assert style in ("arch", "square"), style
        if not count:
            plain(side, -length / 2, length / 2, z)
            return
        assert count * 28 <= length, "each window needs a 28-stud bay"
        cursor = -length / 2
        units = round((length - count * 28) / 7)
        boundaries = [round(i * units / (count + 1)) for i in range(count + 2)]
        for i in range(count):
            u = cursor + (boundaries[i + 1] - boundaries[i]) * 7 + 14
            plain(side, cursor, u - 14, z)
            on_side("wall-" + style, side, u, z)
            on_side("window-" + style, side, u, z)
            cursor = u + 14
        plain(side, cursor, length / 2, z)

    def floor_tiles(z, book=False, fw=None, fd=None):
        fw, fd = w if fw is None else fw, d if fd is None else fd
        for j in range(round(fd / 14)):
            x = -fw / 2
            while x < fw / 2 - .01:
                length = min(28, fw / 2 - x)
                name = ("book-slab" if book else "cardboard-floor") + ("-half" if length == 14 else "")
                add(name, (x + length / 2, -fd / 2 + j * 14 + 7, z))
                x += length

    def edge_loop(ew, ed, z):
        if recipe.get("panel_details", False) and (ew, ed) == (84, 42):
            for side in sides:
                on_side("fluted-run" if sides[side][2] == 84 else "fluted-run-half",
                        side, 0, z, .65)
            return
        for side, length, cross in (("front", ew, ed), ("back", ew, ed),
                                    ("left", ed, ew), ("right", ed, ew)):
            yaw = sides[side][1]
            c, s = math.cos(yaw), math.sin(yaw)
            # Centre both unequal end caps, without stretching a trim piece.
            remainder = length % 14
            segments = []
            if abs(remainder - 11) < .001: segments = [(5.5, "fluted-edge-cap")]
            segments += [(14, "fluted-edge")] * int(length // 14)
            if abs(remainder - 11) < .001: segments += [(5.5, "fluted-edge-cap")]
            elif abs(remainder - 7) < .001: segments += [(7, "fluted-edge-half")]
            else: assert remainder < .001, "unsupported fixed edge length"
            u = -length / 2
            for size, name in segments:
                mid = u + size / 2
                add(name, (c * mid + s * (cross / 2 - .6),
                           s * mid - c * (cross / 2 - .6), z), yaw)
                u += size

    if (width, depth) == (95, 63):
        add("cardboard-base", (0, 0, 1))
    else:
        assert all(v > 0 and abs(v / 14 - round(v / 14)) < 1e-5 for v in (width, depth)), "other footprints use the 14-stud grid"
        floor_tiles(1, fw=width, fd=depth)
    if recipe.get("trims", True): edge_loop(width, depth, 1)
    windows = recipe.get("windows", [])
    for level in range(floors):
        z = 16 + level * 31
        rule = windows[level] if level < len(windows) else {"front": 0, "back": 0, "left": 0, "right": 0}
        style = rule.get("style", recipe.get("window_style", "arch"))
        for side in sides:
            if level == 0 and side == "front" and recipe.get("shop_front", False):
                assert w >= 84, "shopfront needs 56 studs plus one 28-stud door bay"
                on_side("wall-shop", side, -w / 2 + 28, z)
                on_side("shop-window", side, -w / 2 + 28, z)
                on_side("sweet-display", side, -w / 2 + 28, z)
                if recipe.get("door", True):
                    on_side("wall-door", side, -w / 2 + 70, z)
                    on_side("door", side, -w / 2 + 70, z - .5)
                else:
                    plain(side, -w / 2 + 56, -w / 2 + 84, z)
                plain(side, -w / 2 + 84, w / 2, z)
                if recipe.get("awning_color"):
                    color = "color" if recipe["awning_color"] == "red" else "color-" + recipe["awning_color"]
                    for u in np.arange(-w / 2 + 7, -w / 2 + 84, 14):
                        on_side("awning", side, float(u), z + 14.5, .3, color)
                    for u in np.arange(-w / 2 + 14, -w / 2 + 84, 28):
                        on_side("ruler-cornice", side, float(u), z + 15.4, 1)
            else:
                bays(side, rule.get(side, 0), style, z,
                     level == 0 and recipe.get("back_door", False) and side == "back")
        if level:
            floor_tiles(31.5 + (level - 1) * 31, book=True)
        if recipe.get("trims", True):
            for side in sides:
                length = sides[side][2]
                if level == 0 and side == "front" and recipe.get("panel_details", False):
                    on_side("shop-plinth", side, -w / 2 + 28, 3.9, .8)
                    continue
                for u in np.arange(-length / 2 + 7, length / 2, 14):
                    on_side("brick-band", side, float(u), 3.2 if level == 0 else 32.15 + (level - 1) * 31, .7,
                            "color-red" if level == 0 else "color")
            if level and recipe.get("panel_details", False): edge_loop(w, d, 30.6 + (level - 1) * 31)
        if recipe.get("tape", True):
            for side in sides:
                length = sides[side][2]
                for i, u in enumerate((-length / 2 + 4, length / 2 - 4)):
                    on_side("tape-patch", side, u, z + (8 if i else -4), .69)
        if recipe.get("quoins", True):
            for i, (x, y) in enumerate(((-w / 2, -d / 2), (w / 2, -d / 2),
                                       (-w / 2, d / 2), (w / 2, d / 2))):
                if i < 2 and recipe.get("full_height_quoins", False):
                    if level == 0: add("quoin-column", (x, y, 2), i * math.pi / 2)
                    continue
                # Studs remain upward; a quoin overlaps the shell's corner like a toy clip.
                key = ("blue", "green", "yellow", "red")[(i + level) % 4]
                add("brick-2x2", (x, y, 4 if level == 0 else z - 13),
                    color="color" if key == "red" else "color-" + key)
    if recipe.get("panel_details", False):
        assert floors == 2, "full-height corner webs are made for the two-floor shop"
        for x, y, yaw in ((-w / 2, -d / 2, 0), (w / 2, -d / 2, math.pi / 2),
                          (w / 2, d / 2, math.pi), (-w / 2, d / 2, -math.pi / 2)):
            add("corner-flutes", (x, y, 2), yaw)
    roof_top = 2 + floors * 28 + (floors - 1) * 3 + 2
    floor_tiles(roof_top - 1)
    if recipe.get("trims", True): edge_loop(w, d, roof_top - 1)
    dressing = recipe.get("roof", {})
    if dressing.get("parapet", True):
        for side in sides:
            length = sides[side][2]
            cursor = -length / 2
            while cursor < length / 2 - .01:
                size = min(28, length / 2 - cursor)
                on_side("roof-parapet" + ("-half" if size == 14 else ""), side,
                        cursor + size / 2, roof_top + 2.5)
                cursor += size
        if recipe.get("panel_details", False):
            for u in (-23, 8, 33): on_side("tape-patch", "front", u, roof_top + 2.5, .68)
            on_side("tape-patch", "right", 0, roof_top + 2.5, .68)
    if dressing.get("bunting", False):
        for side in (sides if dressing.get("bunting_all_sides", False) else ("back",)):
            length = sides[side][2]
            cursor = -length / 2
            while cursor < length / 2 - .01:
                size = min(28, length / 2 - cursor)
                on_side("paper-bunting" + ("-half" if size == 14 else ""), side,
                        cursor + size / 2, roof_top + 6.5, -.2)
                cursor += size
        if dressing.get("bunting_all_sides", False):
            for x in (-w / 2 + .1, w / 2 - .1):
                for y in (-d / 2 + .1, d / 2 - .1): add("bunting-post", (x, y, roof_top))
    if dressing.get("chimney", False): add("rooftop-chimney", (-w / 2 + 13, d / 2 - 12, roof_top + 5))
    if dressing.get("corner_bricks", False):
        for x in (-w / 2 + 2.5, w / 2 - 2.5):
            for y in (-d / 2 + 2.5, d / 2 - 2.5):
                add("brick-2x2", (x, y, roof_top + 1.5), color="color-green")
                add("brick-1x1", (x, y, roof_top + 5.3), color="color" if x > 0 else "color-yellow")
    if recipe.get("cupcake_sign", False): add("cupcake-sign", (w / 2 + 2.2, -d / 2 + 8, 19), math.pi / 2)
    if recipe.get("pencil_columns", False):
        for x in (-w / 2 - 1.25, w / 2 + 1.25):
            for y in (-d / 2 - 1.25, d / 2 + 1.25):
                if y < 0 and recipe.get("full_height_quoins", False): continue
                add("pencil-column", (x, y, 16))
    if dressing.get("clutter", False):
        add("roof-box", (-w / 2 + 15, -d / 2 + 12, roof_top))
        add("roof-box", (w / 2 - 13, d / 2 - 12, roof_top), math.pi / 2)
        add("tape-roll", (w / 2 - 14, -d / 2 + 12, roof_top), -.25)
    if dressing.get("topper_plinth", False):
        add("topper-plinth", (6, -6, roof_top))
    if recipe.get("side_details", False):
        on_side("side-awning", "right", 0, 30.5, .4)
        add("drainpipe", (w / 2 + 1.3, d / 2 - 1.4, 2))
        add("doormat", (-w / 2 + 70, -d / 2 - 4.7, 2.2))
    for extra in recipe.get("extras", []):
        if extra["piece"].startswith("kit/"):
            rec = catalog[extra["piece"].split("/")[1]]
            assert extra.get("color", "color") in rec["colors"]
            rows.append({"piece": extra["piece"], "color": extra.get("color", "color"),
                         "offset": extra["offset"], "yaw": extra.get("yaw", 0), "size": rec["size"]})
            continue
        folder, name = extra["piece"].split("/")
        source = json.loads((ROOT / "assets/models" / folder / "parts.json").read_text())
        rec = next(p for p in source["pieces"] if p["prefix"] == name)
        lo, hi = np.array(rec["bounding_box"]["min"]), np.array(rec["bounding_box"]["max"])
        rows.append({"piece": extra["piece"], "color": extra.get("color", "color"),
                     "offset": extra.get("offset", ((lo + hi) / 2).tolist()),
                     "yaw": extra.get("yaw", 0), "size": (hi - lo).tolist()})
    assert len(rows) <= 250, f"{len(rows)} parts exceeds 250"
    return rows, roof_top


def piece_source(piece, catalog):
    folder, name = piece.split("/")
    if folder == "kit": return PARTS, name, catalog[name]["triangles"]
    root = ROOT / "assets/models" / folder
    data = json.loads((root / "parts.json").read_text())
    rec = next(p for p in data["pieces"] if p["prefix"] == name)
    return root / "parts", name, rec["triangles"]


def assemble(rows, catalog):
    clear()
    templates, materials, objects = {}, {}, []
    for row in rows:
        piece, color = row["piece"], row["color"]
        folder, name, _ = piece_source(piece, catalog)
        if piece not in templates:
            template = load_fbx(folder / f"{name}.fbx")
            low, high = bounds(template)
            center = (low + high) / 2
            # hero pieces have a shared origin; kit pieces are already centred.
            for v in template.data.vertices: v.co -= Vector(center)
            template.data.update()
            templates[piece] = template
        template = templates[piece]
        obj = template.copy()
        obj.data = template.data.copy()
        bpy.context.collection.objects.link(obj)
        obj.name = piece + " " + str(len(objects) + 1)
        obj["kit_piece"] = piece
        obj["kit_color"] = color
        obj.location = row["offset"]
        obj.rotation_euler.z = row["yaw"]
        key = (piece, color)
        if key not in materials:
            materials[key] = baked_material(name, folder, color, template.data.uv_layers[0].name)
        one_material(obj, materials[key])
        assert np.max(np.abs(np.array(obj.dimensions) - np.array(row["size"]))) < .02, (piece, "size mismatch")
        objects.append(obj)
    for obj in templates.values(): bpy.data.objects.remove(obj, do_unlink=True)
    bpy.context.view_layer.update()
    return objects


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_shop(objects, name):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 128
    scene.eevee.use_raytracing = True
    scene.eevee.fast_gi_method = "AMBIENT_OCCLUSION_ONLY"
    scene.eevee.fast_gi_distance = 8
    scene.eevee.fast_gi_quality = .75
    scene.eevee.fast_gi_ray_count = 8
    scene.eevee.fast_gi_step_count = 16
    scene.eevee.shadow_ray_count = 4
    scene.render.resolution_x = scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.47, .49, .52, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .8
    bpy.ops.mesh.primitive_plane_add(size=2000, location=(0, 0, -.05))
    ground = bpy.context.object
    ground.name = "Render ground (not a placed piece)"
    backdrop = bpy.data.materials.new("Neutral render backdrop")
    backdrop.use_nodes = True
    backdrop.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = linear((185, 187, 189))
    backdrop.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .9
    ground.data.materials.append(backdrop)
    low = np.min([bounds(o)[0] for o in objects], axis=0)
    high = np.max([bounds(o)[1] for o in objects], axis=0)
    center, extent = Vector((low + high) / 2), float(max(high - low))
    for label, direction, power, size in (
            ("Warm key", (-1.1, -1.5, 2.1), 38, .65),
            ("Cool fill", (1.5, -.5, 1), 14, 1.3),
            ("Roof rim", (.5, 1.5, 2), 18, .9)):
        bpy.ops.object.light_add(type="AREA", location=center + Vector(direction) * extent)
        light = bpy.context.object
        light.name = label
        light.data.energy = power * extent ** 2
        light.data.size = size * extent
        light.data.color = {"Warm key": (1, .96, .87), "Cool fill": (.88, .94, 1),
                            "Roof rim": (1, .98, .93)}[label]
        point_at(light, center)
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Shop inspection camera"
    camera.data.type = "ORTHO"
    camera.data.clip_end = 5000
    scene.camera = camera
    front_camera = None
    for label, direction in (("front", (.55, -1, .22)), ("air", (.65, -1, 1.2))):
        camera.location = center + Vector(direction).normalized() * extent * 4
        point_at(camera, center)
        view = camera.rotation_euler.to_matrix().transposed()
        points = np.array([tuple(view @ (o.matrix_world @ v.co - center))
                           for o in objects for v in o.data.vertices])
        lo, hi = points.min(axis=0), points.max(axis=0)
        camera.data.ortho_scale = max(hi[0] - lo[0], hi[1] - lo[1]) / .87
        camera.location += camera.rotation_euler.to_matrix() @ Vector(((hi[0] + lo[0]) / 2, (hi[1] + lo[1]) / 2, 0))
        if label == "front": front_camera = (camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale)
        scene.render.filepath = str(BUILDINGS / f"{name}-{label}.png")
        bpy.ops.render.render(write_still=True)
    # Save with the same front view used in the comparison.
    camera.location, camera.rotation_euler, camera.data.ortho_scale = front_camera


def comparison(name):
    # Blender image I/O, copied from hero.py; preserves aspect and source colours.
    concept = bpy.data.images.load(str(ROOT / "assets/models/sweet-shop/concept-front.png"), check_existing=False)
    rendered = bpy.data.images.load(str(BUILDINGS / f"{name}-front.png"), check_existing=False)
    width = round(concept.size[0] * 1024 / concept.size[1])
    concept.scale(width, 1024)
    left, right = np.empty(width * 1024 * 4, dtype=np.float32), np.empty(1024 * 1024 * 4, dtype=np.float32)
    concept.pixels.foreach_get(left)
    rendered.pixels.foreach_get(right)
    pixels = np.concatenate((left.reshape(1024, width, 4), right.reshape(1024, 1024, 4)), axis=1)
    image = bpy.data.images.new("Concept beside kit shop", width=width + 1024, height=1024, alpha=True)
    image.pixels.foreach_set(pixels.ravel())
    image.filepath_raw = str(BUILDINGS / f"{name}-compare.png")
    image.file_format = "PNG"
    image.save()


def make_shop(path):
    recipe = json.loads(path.read_text())
    name = recipe["name"]
    assert name and all(c.isalnum() or c in "-_" for c in name), "name must be a file-safe slug"
    catalog = json.loads((OUT / "pieces.json").read_text())
    rows, roof_top = recipe_rows(recipe, catalog)
    count = sum(piece_source(row["piece"], catalog)[2] for row in rows)
    assert count <= 32000, f"{count} triangles exceeds 32000"
    objects = assemble(rows, catalog)
    low = np.min([bounds(o)[0] for o in objects], axis=0)
    high = np.max([bounds(o)[1] for o in objects], axis=0)
    BUILDINGS.mkdir(parents=True, exist_ok=True)
    report = {"pieces": rows, "footprint": [recipe["width"], recipe["depth"]],
              "height": round(float(high[2] - low[2]), 5), "triangles": count,
              "roof_height": roof_top + 5 if recipe.get("roof", {}).get("parapet", True) else roof_top,
              "bounding_box": {"min": low.round(5).tolist(), "max": high.round(5).tolist()},
              "recipe": name + ".recipe.json"}
    (BUILDINGS / f"{name}.json").write_text(json.dumps(report, indent=2) + "\n")
    # Keep each building's short source recipe next to its output, even for temp inputs.
    target = BUILDINGS / f"{name}.recipe.json"
    if path.resolve() != target.resolve(): target.write_text(json.dumps(recipe, indent=2) + "\n")
    render_shop(objects, name)
    comparison(name)
    for image in bpy.data.images:
        if image.source == "FILE": image.pack()
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(BUILDINGS / f"{name}.blend"))
    log(f"shop PASS: {name}, {len(rows)} parts, {count} triangles, "
        f"footprint {report['footprint']}, height {report['height']}, roof {report['roof_height']}")


def png_size(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", str(path)
    return struct.unpack(">II", data[16:24])


def verify():
    catalog = json.loads((OUT / "pieces.json").read_text())
    assert set(catalog) == set(piece_specs()), "catalog missing kit pieces"
    maps, total = 0, 0
    for name, rec in catalog.items():
        path = PARTS / f"{name}.fbx"
        assert path.is_file(), str(path)
        for key in rec["colors"] + ["normal", "roughness"]:
            path = PARTS / f"{name}-{key}.png"
            assert path.is_file(), str(path)
            size = png_size(path)
            assert all(0 < n <= 1024 and n & (n - 1) == 0 for n in size), (path, size)
            maps += 1
        clear()
        obj = load_fbx(PARTS / f"{name}.fbx")
        count = triangles(obj)
        assert count == rec["triangles"] and count <= piece_specs()[name][1], (name, count)
        assert len(obj.data.materials) == len(obj.data.uv_layers) == 1, name
        assert topology(obj) == (0, 0), (name, "FBX boundary/loose edges", topology(obj))
        low, high = bounds(obj)
        assert np.max(np.abs(high - low - np.array(rec["size"]))) < .01, name
        assert np.max(np.abs(low + high)) < .01, (name, "not centred")
        if rec["tile_studs"]:
            uv = np.array([tuple(v.uv) for v in obj.data.uv_layers[0].data])
            assert uv.max() > 1 or uv.min() < 0, (name, "UVs must repeat")
            assert png_size(PARTS / f"{name}-color.png")[0] / rec["tile_studs"] >= 40
        total += count
    buildings = sorted(BUILDINGS.glob("*.recipe.json"))
    assert buildings, "no building recipes"
    summaries = []
    for path in buildings:
        recipe = json.loads(path.read_text())
        name = recipe["name"]
        for suffix in (".json", ".blend", "-front.png", "-air.png", "-compare.png"):
            output = BUILDINGS / (name + suffix)
            assert output.is_file() and output.stat().st_size > 100, str(output)
        for label in ("front", "air"): assert png_size(BUILDINGS / f"{name}-{label}.png") == (1024, 1024)
        report = json.loads((BUILDINGS / f"{name}.json").read_text())
        expected_rows, roof_top = recipe_rows(recipe, catalog)
        assert report["pieces"] == expected_rows, "building does not match current recipe"
        assert len(expected_rows) <= 250
        counts = sum(piece_source(r["piece"], catalog)[2] for r in expected_rows)
        assert report["triangles"] == counts <= 32000
        # Reimport every referenced mesh, and measure the assembly rather than trusting its JSON boxes.
        objects = assemble(expected_rows, catalog)
        actual_counts = sum(triangles(o) for o in objects)
        assert actual_counts == counts, (name, actual_counts, counts)
        assert all(topology(o) == (0, 0) for o in objects), "building includes an unclosed mesh"
        low = np.min([bounds(o)[0] for o in objects], axis=0)
        high = np.max([bounds(o)[1] for o in objects], axis=0)
        dressing = recipe.get("roof", {})
        roof_height = roof_top + (5 if dressing.get("parapet", True) else 0)
        expected_height = max(roof_height, roof_top + (14.4 if dressing.get("chimney") else 0),
                              roof_top + (8.8 if dressing.get("bunting") else 0),
                              roof_top + (7.6 if dressing.get("corner_bricks") else 0))
        expected_height = max([expected_height] + [r["offset"][2] + r["size"][2] / 2 for r in expected_rows
                                                  if any(e["piece"] == r["piece"] for e in recipe.get("extras", []))])
        expected = np.array(recipe.get("expected_size", [recipe["width"], recipe["depth"], expected_height]))
        assert np.max(np.abs(high - low - expected)) <= 1, (name, "bounds", high - low, expected)
        assert np.max(np.abs(low - np.array(recipe.get("expected_min", [-recipe["width"] / 2, -recipe["depth"] / 2, 0])))) <= 1
        assert abs(report["height"] - (high[2] - low[2])) < .02
        assert abs(report["roof_height"] - recipe.get("roof_height", roof_height)) <= 1
        summaries.append(f"{name}: {len(expected_rows)} parts, {counts} triangles; "
                         f"bounds {(high - low).round(3).tolist()}; roof {report['roof_height']}")
    log(f"verify PASS: {len(catalog)} FBX pieces, {total} unique triangles, {maps} PNG maps; "
        "all closed pieces have 0 boundary edges after FBX reimport; PNGs power-of-two <=1024; cardboard 64 px/stud")
    for summary in summaries: log("verify PASS: " + summary + "; recipe bounds within 1 stud")


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("pieces")
    shop = commands.add_parser("shop")
    shop.add_argument("recipe", type=Path)
    commands.add_parser("verify")
    options = parser.parse_args(args)
    if options.command == "pieces": make_pieces()
    elif options.command == "shop": make_shop(options.recipe)
    else: verify()


if __name__ == "__main__":
    main()
