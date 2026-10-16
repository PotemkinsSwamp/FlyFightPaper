"""Build design A in Blender, then use hero.py to cut, bake and export it.

D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 \
    --python tools/art/bell_tower.py -- --preview
Repeat with --export after inspecting the preview. --verify checks saved outputs.
Coordinates are studs, Z up, base centre (0, 0, 0), front -Y.
No downloads, credentials, uploads or Studio operations are involved.
"""

import argparse
import hashlib
import json
import math
import sys
import tempfile
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hero

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "assets/models/bell-tower"
HEIGHT = 430.0
CLOCK_FOLDER = FOLDER / "clock"
CLOCK_CENTRE_Z = 229.0
CLOCK_MOUNT_Y = -72.35
BELL_BOTTOM = 300.0
BELL_WIDTH = 46.0
BELL_HEIGHT = 48.0
BELL_METALLIC = .85
POST_CENTRE = 47.0
ARCH_HALF_WIDTH = 63.0
ARCH_SPRING = 110.0
ARCH_APEX = ARCH_SPRING + ARCH_HALF_WIDTH
CONE_HEIGHT = 30.0
CONE_WIDTH = 27.0
FINIAL_RADIUS = 2.2
FINIAL_CENTRE_Z = HEIGHT - FINIAL_RADIUS
GROUPS = {}
MATERIALS = {}
# Double the atlas dimensions, rather than reducing geometry or surface detail.
hero.SIZE = 2048
hero.BAKE_SIZE = 4096
GATEWAY = json.loads((ROOT / "assets/models/gateway-towers/parts.json").read_text())
DENSITY_FLOOR = max(p["front_pixels_per_stud"] for p in GATEWAY["pieces"])
UV_CACHE = Path(tempfile.gettempdir()) / "flyfightpaper-bell-tower-uv"


def log(message):
    print("BELL " + message, flush=True)


def linear(rgb):
    return [((c / 255 + .055) / 1.055) ** 2.4 if c > 10.31475 else c / 3294.6
            for c in rgb] + [1]


def material(name, rgb, roughness, paper=False, tape=False, metallic=0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = linear(rgb)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Specular IOR Level"].default_value = .35
    position = nodes.new("ShaderNodeNewGeometry").outputs["Position"]
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = .65 if paper or tape else 2.5
    noise.inputs["Detail"].default_value = 3
    noise.inputs["Roughness"].default_value = .7
    links.new(position, noise.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    color = linear(rgb)
    variation = .19 if paper else .035
    ramp.color_ramp.elements[0].position = .16
    ramp.color_ramp.elements[1].position = .84
    ramp.color_ramp.elements[0].color = [c * (1 - variation) for c in color[:3]] + [1]
    ramp.color_ramp.elements[1].color = [min(1, c * (1 + variation)) for c in color[:3]] + [1]
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    if paper or tape:
        creases = nodes.new("ShaderNodeTexVoronoi")
        creases.feature = "DISTANCE_TO_EDGE"
        crumpled = name in ("Kraft", "Blue paper", "Blue fold")
        crease_position = position
        if crumpled:
            warp = nodes.new("ShaderNodeTexNoise")
            warp.inputs["Scale"].default_value = .055
            warp.inputs["Detail"].default_value = 2
            links.new(position, warp.inputs["Vector"])
            offset = nodes.new("ShaderNodeVectorMath")
            offset.operation = "SCALE"
            offset.inputs["Scale"].default_value = 5
            links.new(warp.outputs["Color"], offset.inputs[0])
            warped = nodes.new("ShaderNodeVectorMath")
            warped.operation = "ADD"
            links.new(position, warped.inputs[0])
            links.new(offset.outputs[0], warped.inputs[1])
            crease_position = warped.outputs[0]
        creases.inputs["Scale"].default_value = .10 if crumpled else (.38 if tape else .20)
        links.new(crease_position, creases.inputs["Vector"])
        crease_ramp = nodes.new("ShaderNodeValToRGB")
        crease_ramp.color_ramp.elements[0].position = .015
        crease_ramp.color_ramp.elements[0].color = (.15, .15, .15, 1)
        crease_ramp.color_ramp.elements[1].position = .075
        crease_ramp.color_ramp.elements[1].color = (.65, .65, .65, 1)
        links.new(creases.outputs["Distance"], crease_ramp.inputs["Fac"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = .65 if crumpled else (.32 if tape else .24)
        bump.inputs["Distance"].default_value = 1.35 if crumpled else (.17 if tape else .22)
        links.new(crease_ramp.outputs["Color"], bump.inputs["Height"])
        if crumpled:
            mask_noise = nodes.new("ShaderNodeTexNoise")
            mask_noise.inputs["Scale"].default_value = .23
            mask_noise.inputs["Detail"].default_value = 2
            links.new(crease_position, mask_noise.inputs["Vector"])
            mask = nodes.new("ShaderNodeValToRGB")
            mask.color_ramp.elements[0].position = .30
            mask.color_ramp.elements[1].position = .70
            links.new(mask_noise.outputs["Fac"], mask.inputs[0])
            ridge = nodes.new("ShaderNodeMath")
            ridge.operation = "SUBTRACT"
            ridge.inputs[0].default_value = .65
            links.new(crease_ramp.outputs[0], ridge.inputs[1])
            fragments = nodes.new("ShaderNodeMath")
            fragments.operation = "MULTIPLY"
            links.new(ridge.outputs[0], fragments.inputs[0])
            links.new(mask.outputs[0], fragments.inputs[1])
            depth = nodes.new("ShaderNodeMath")
            depth.operation = "MULTIPLY"
            depth.inputs[1].default_value = .35
            links.new(fragments.outputs[0], depth.inputs[0])
            height = nodes.new("ShaderNodeMath")
            height.operation = "SUBTRACT"
            links.new(warp.outputs["Fac"], height.inputs[0])
            links.new(depth.outputs[0], height.inputs[1])
            links.new(height.outputs[0], bump.inputs["Height"])
            bump.inputs["Strength"].default_value = .62
            bump.inputs["Distance"].default_value = 2.4
        fiber = nodes.new("ShaderNodeTexNoise")
        fiber.inputs["Scale"].default_value = 3.8
        fiber.inputs["Detail"].default_value = 2
        links.new(position, fiber.inputs["Vector"])
        fine = nodes.new("ShaderNodeBump")
        fine.inputs["Strength"].default_value = .18
        fine.inputs["Distance"].default_value = .065
        links.new(fiber.outputs["Fac"], fine.inputs["Height"])
        links.new(bump.outputs["Normal"], fine.inputs["Normal"])
        links.new(fine.outputs["Normal"], bsdf.inputs["Normal"])
        if crumpled:
            tint = nodes.new("ShaderNodeValToRGB")
            tint.color_ramp.elements[0].position = 0
            tint.color_ramp.elements[0].color = (1, 1, 1, 1)
            tint.color_ramp.elements[1].position = .3
            tint.color_ramp.elements[1].color = (.975, .975, .975, 1)
            links.new(fragments.outputs[0], tint.inputs["Fac"])
            folds = nodes.new("ShaderNodeMixRGB")
            folds.blend_type = "MULTIPLY"
            folds.inputs[0].default_value = 1
            links.new(ramp.outputs["Color"], folds.inputs[1])
            links.new(tint.outputs["Color"], folds.inputs[2])
            links.new(folds.outputs[0], bsdf.inputs["Base Color"])
    MATERIALS[name] = mat
    return mat


def finish(obj, name, mat, group, bevel=0, smooth=False):
    obj.name = name
    obj.data.materials.append(MATERIALS[mat])
    hero.active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bevel:
        mod = obj.modifiers.new("Soft toy edges", "BEVEL")
        mod.width, mod.segments = bevel, 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if smooth:
        for face in obj.data.polygons:
            face.use_smooth = len(face.vertices) == 4
    # Weighted normals keep the broad toy faces flat, including stud end caps.
    if bevel:
        for face in obj.data.polygons:
            face.use_smooth = True
        mod = obj.modifiers.new("Broad face normals", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # The hero pipeline bakes paint/tape details onto the supporting surface.
    # Keep them in the editable high source, but do not spend exported triangles
    # on the edges of flat tape or the twelve painted clock ticks.
    bake_detail = name in ("Tape patch", "Tape overlap", "Tape fold", "Clock tick",
                           "Clock hand", "Folded roof edge", "Cardboard join", "Clock board seam")
    for attribute, value in (("bell_bake_detail", int(bake_detail)),
                             ("bell_top_stud", int(name == "Top stud")),
                             ("bell_leg_stud", int(name == "Round side stud")),
                             ("bell_leg_brick", 0),
                             ("bell_upper_red", int(group == "upper-bricks" and mat == "Red plastic")),
                             ("bell_lower_red", int(group == "lower-bricks" and mat == "Red plastic"))):
        attr = obj.data.attributes.new(attribute, "INT", "FACE")
        attr.data.foreach_set("value", np.full(len(obj.data.polygons), value, dtype=np.int32))
    GROUPS.setdefault(group, []).append(obj)
    return obj


def box(name, center, size, mat, group, bevel=.20, angle=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.scale = size
    obj.rotation_euler.z = angle
    return finish(obj, name, mat, group, bevel)


def cylinder(name, center, radius, depth, mat, group, direction=(0, 0, 1),
             segments=16, bevel=.15):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius, depth=depth,
                                       end_fill_type="NGON", location=center)
    obj = bpy.context.object
    obj.rotation_euler = Vector(direction).to_track_quat("Z", "Y").to_euler()
    return finish(obj, name, mat, group, bevel, True)


def mesh(name, vertices, faces, mat, group):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj, name, mat, group)


def rotate_xy(point, angle):
    x, y, z = point
    return (x * math.cos(angle) - y * math.sin(angle),
            x * math.sin(angle) + y * math.cos(angle), z)


def surface_box(name, x, y, z, width, depth, height, mat, group, side=0, bevel=.04):
    return box(name, rotate_xy((x, y, z), side), (width, depth, height), mat,
               group, bevel, side)


def tape_patch(group, x, y, z, width, height, side=0):
    # Unequal overlapping strips and folds, confined to the intended footprint.
    surface_box("Tape patch", x, y, z, width, .12, height, "Tape", group, side)
    surface_box("Tape overlap", x - width * .17, y - .035, z + height * .10,
                width * .55, .16, height * .93, "Tape light", group, side)
    # A pale diagonal fold is real, very shallow geometry and survives baking.
    obj = surface_box("Tape fold", x, y - .15, z, .22, .07, height * 1.02,
                      "Tape light", group, side, 0)
    hero.active(obj)
    # Rotate a folded line within the wall plane without changing its centre.
    center = Vector(rotate_xy((x, y - .15, z), side))
    axis = Vector(rotate_xy((0, -1, 0), side))
    from mathutils import Matrix
    rotation = Matrix.Rotation(.43, 4, axis)
    for vertex in obj.data.vertices:
        vertex.co = center + rotation.to_3x3() @ (vertex.co - center)


def build_legs():
    for x in (-83, 83):
        for y in (-83, 83):
            group = "legs"
            box("Green base plate", (x, y, 2.5), (40, 40, 5), "Green", group, .4)
            for row, (bottom, top) in enumerate(((5, 39.8), (40.2, 74.8), (75.2, 110))):
                z = (bottom + top) / 2
                mat = "Blue plastic" if row == 1 else "Red plastic"
                obj = box("Stacked brick", (x, y, z), (40, 40, top - bottom), mat, group, .55)
                obj.data.attributes["bell_leg_brick"].data.foreach_set(
                    "value", np.full(len(obj.data.polygons), row + 1, dtype=np.int32))
                for side in range(4):
                    a = side * math.pi / 2
                    direction = rotate_xy((0, -1, 0), a)
                    # Exposed outer faces carry the four large studs. The
                    # inner faces stay flush with the clear flight passage.
                    if direction[0] * x + direction[1] * y < 0:
                        continue
                    for offset in (-9, 9):
                        local = rotate_xy((offset, -20.7, 0), a)
                        for vertical in (-8.5, 8.5):
                            cylinder("Round side stud", (x + local[0], y + local[1], z + vertical),
                                     4.8, 2.4, mat, group, direction, bevel=.24)
                if row < 2:
                    for dx in (-10, 10):
                        for dy in (-10, 10):
                            cylinder("Top stud", (x + dx, y + dy, top + 1.2),
                                     5.4, 2.4, mat, group, bevel=.15)


def build_arches():
    group = "arches"
    for x in (-83, 83):
        for y in (-83, 83):
            box("Cardboard corner pier", (x, y, 149), (40, 40, 78),
                "Kraft", group, 0)
    # Four independent arched wall prisms. No central solid or ground slab.
    # Round 4: a radius-63 half-circle starts directly at the leg tops.
    for side in range(4):
        angle = side * math.pi / 2
        n = 48
        angles = np.linspace(math.pi, 0, n + 1)
        xs = ARCH_HALF_WIDTH * np.cos(angles)
        underside = ARCH_SPRING + ARCH_HALF_WIDTH * np.sin(angles)
        vertices = []
        for y in (-103, -85):
            for x, z in zip(xs, underside):
                vertices.extend((rotate_xy((float(x), y, float(z)), angle),
                                 rotate_xy((float(x), y, 188), angle)))
        stride = (n + 1) * 2
        faces = []
        for i in range(n):
            a = i * 2
            faces += [(a, a + 2, a + 3, a + 1),
                      (stride + a + 1, stride + a + 3, stride + a + 2, stride + a),
                      (a, stride + a, stride + a + 2, a + 2),
                      (a + 1, a + 3, stride + a + 3, stride + a + 1)]
        faces += [(0, 1, stride + 1, stride),
                  (2 * n, stride + 2 * n, stride + 2 * n + 1, 2 * n + 1)]
        obj = mesh("Cut cardboard arch", vertices, faces, "Kraft", group)
        obj.data.materials.append(MATERIALS["Cut edge"])
        for i in range(n):
            obj.data.polygons[i * 4 + 2].material_index = 1
        for x in (-83, 83):
            tape_patch(group, x, -103.10, 179.5, 34, 16, angle)
            tape_patch(group, x, -103.10, 116, 34, 12, angle)
        # Fine cut/fold lines make the big board read as cardboard panels.
        surface_box("Cardboard join", 0, -103.02, (ARCH_APEX + 188) / 2,
                    .22, .03, 188 - ARCH_APEX - .2,
                    "Card seam", group, angle, 0)


def top_brick(name, center, size, mat, group, studs=2, count_x=None, stud_radius=2.8):
    box(name, center, size, mat, group, .20)
    w, d, h = size
    count_x = max(1, round(w / 12)) if count_x is None else count_x
    count_y = studs
    for ix in range(count_x):
        for iy in range(count_y):
            x = center[0] + (ix - (count_x - 1) / 2) * w / count_x
            y = center[1] + (iy - (count_y - 1) / 2) * d / count_y
            cylinder("Top stud", (x, y, center[2] + h / 2 + .9), stud_radius, 1.8,
                     mat, group, bevel=.10)


def build_clock():
    group = "lower-bricks"
    # A kraft plinth, perimeter brick band and narrower clock box.
    box("Arch top board", (0, 0, 189), (206, 206, 2), "Cut edge", "arch-board", 0)
    box("Clock bottom board", (0, 0, 198), (160, 160, 4), "Cut edge", "clock-base", 0)
    for side in range(4):
        angle = side * math.pi / 2
        for index in range(4):
            c = rotate_xy((-47.25 + index * 31.5, -95, 191.1), angle)
            obj_start = len(GROUPS.get(group, []))
            top_brick("Blue lower band", c, (31.2, 16, 6.2), "Blue plastic", group, 1)
            # Square brick proportions allow rotation after construction.
            if side % 2:
                for obj in GROUPS[group][obj_start:]:
                    for vertex in obj.data.vertices:
                        p = vertex.co - Vector(c)
                        vertex.co = Vector(c) + Vector(rotate_xy(p, angle))
    for x in (-83, 83):
        for y in (-83, 83):
            top_brick("Red lower corner", (x, y, 193.1), (40, 40, 10.2),
                      "Red plastic", group, count_x=2, stud_radius=4.8)
    group = "clock-body"
    box("Clock cardboard body", (0, 0, 229), (142, 142, 58), "Kraft", group, .12)
    for side in range(4):
        angle = side * math.pi / 2
        for x in (-59, 59):
            tape_patch(group, x, -71.04, 250, 22, 15, angle)
            tape_patch(group, x, -71.04, 207, 22, 12, angle)
        surface_box("Clock board seam", 34, -71.16, 229, .14, .03, 56,
                    "Card seam", group, angle, 0)
    group = "upper-bricks"
    for side in range(4):
        angle = side * math.pi / 2
        for index in range(4):
            c = rotate_xy((-26.25 + index * 17.5, -53, 262.1), angle)
            start = len(GROUPS.get(group, []))
            top_brick("Blue upper band", c, (17.2, 12, 8.2), "Blue plastic", group, 1)
            if side % 2:
                for obj in GROUPS[group][start:]:
                    for vertex in obj.data.vertices:
                        p = vertex.co - Vector(c)
                        vertex.co = Vector(c) + Vector(rotate_xy(p, angle))
    for x in (-POST_CENTRE, POST_CENTRE):
        for y in (-POST_CENTRE, POST_CENTRE):
            top_brick("Red upper corner", (x, y, 267.1), (24, 24, 18.2),
                      "Red plastic", group, count_x=2, stud_radius=3.2)


def build_clock_source():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    GROUPS.clear()
    MATERIALS.clear()
    material("Clock rim", (169, 118, 63), .68, paper=True)
    material("Clock paper", (246, 225, 188), .80, paper=True)
    material("Ink", (27, 31, 28), .52)
    group = "clock-face"
    cylinder("Clock rim", (0, 0, 0), 25, 2, "Clock rim", group,
             (0, -1, 0), segments=64, bevel=0)
    cylinder("Cream clock face", (0, -1.02, 0), 23.65, .16, "Clock paper", group,
             (0, -1, 0), segments=64, bevel=0)
    from mathutils import Matrix
    for tick in range(12):
        angle = tick * math.tau / 12
        x, z = math.sin(angle) * 20.5, math.cos(angle) * 20.5
        obj = surface_box("Clock tick", x, -1.17, z, .85, .06, 3.8 if tick % 3 == 0 else 3.0,
                          "Ink", group, 0, .025)
        center = Vector((x, -1.17, z))
        rotation = Matrix.Rotation(-angle, 4, Vector((0, -1, 0))).to_3x3()
        for vertex in obj.data.vertices:
            vertex.co = center + rotation @ (vertex.co - center)
    cylinder("Clock centre cap", (0, -2.26, 0), 2.0, .42, "Ink", group,
             (0, -1, 0), segments=24, bevel=.08)
    for name, width, length, y, depth in (("clock-hour", 2.8, 16, -1.42, .35),
                                        ("clock-minute", 1.9, 20, -1.87, .32)):
        outline = [(-width / 2, -1.4), (width / 2, -1.4),
                   (width / 2, length - 2), (0, length), (-width / 2, length - 2)]
        vertices = [(x, yy, z) for yy in (y - depth / 2, y + depth / 2) for x, z in outline]
        n = len(outline)
        faces = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
        faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
        mesh(name, vertices, faces, "Ink", name)
    objects = [join_group(items, label) for label, items in GROUPS.items()]
    CLOCK_FOLDER.mkdir(exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(CLOCK_FOLDER / "clock-source.blend"))
    return objects


def build_belfry():
    for x in (-POST_CENTRE, POST_CENTRE):
        for y in (-POST_CENTRE, POST_CENTRE):
            for course in range(4):
                z = 278 + 7.75 + course * 15.5
                h = 15.3
                if course == 0:
                    z, h = z - .05, h + .10
                elif course == 3:
                    z, h = z + .05, h + .10
                box("Yellow belfry brick", (x, y, z), (24, 24, h), "Yellow", "posts", .45)
    # Bell shell: lip and hollow underside, not a capped cone.
    profile = [(16.3, 336), (18, 337), (18.2, 338.2), (17.4, 339.8),
               (15.0, 341.6), (13.2, 345), (12.0, 353), (10.7, 358),
               (8.3, 362), (5.0, 364), (0, 364.7),
               (0, 362.5), (4.3, 362.2), (6.8, 360.1), (9.0, 356),
               (10.2, 349), (11.5, 344), (14.5, 338), (15.1, 336)]
    count = 64
    vertices = [(r * (BELL_WIDTH / 2 / 18.2) * math.cos(k * math.tau / count),
                 r * (BELL_WIDTH / 2 / 18.2) * math.sin(k * math.tau / count),
                 307 + (z - 336) * 31 / 28.7)
                for r, z in profile for k in range(count)]
    faces = []
    for row in range(len(profile)):
        for k in range(count):
            nxt = (k + 1) % count
            a, b = row * count + k, row * count + nxt
            c = ((row + 1) % len(profile)) * count + nxt
            d = ((row + 1) % len(profile)) * count + k
            faces.append((a, b, c, d))
    obj = mesh("Hollow gold toy bell", vertices, faces, "Gold", "bell")
    # Weld the two polar rows to avoid zero-area triangles.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.0001)
    bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces], context="EDGES")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    for face in obj.data.polygons:
        face.use_smooth = True
    # The hanger reaches into the roof. The visible bell body stays below 338,
    # while the complete 48-tall asset extends from 300 to 348.
    cylinder("Bell hanger", (0, 0, 341), 2.4, 14, "Gold", "bell", segments=24)
    cylinder("Bell clapper stem", (0, 0, 311), 1.15, 12, "Gold", "bell", segments=16)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=4.5,
                                        location=(0, 0, 304.5))
    obj = finish(bpy.context.object, "Gold clapper", "Gold", "bell")
    for face in obj.data.polygons:
        face.use_smooth = True


def build_roof():
    # Four blue cardboard panels meet at the flat seat below the red cone.
    box("Belfry cardboard ceiling", (0, 0, 341), (128, 128, 2), "Cut edge", "roof", 0)
    vertices = [(-64, -64, 342), (64, -64, 342), (64, 64, 342), (-64, 64, 342),
                (-13.5, -13.5, 398), (13.5, -13.5, 398), (13.5, 13.5, 398), (-13.5, 13.5, 398)]
    obj = mesh("Blue cardboard pyramid", vertices,
               [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
                (4, 5, 6, 7), (3, 2, 1, 0)],
               "Blue paper", "roof")
    # Thin folded ridges follow the real edges instead of making roof tiles.
    for x, y in ((-64, -64), (64, -64), (64, 64), (-64, 64)):
        start = Vector((x, y, 342.02))
        end = Vector((math.copysign(13.5, x), math.copysign(13.5, y), 398))
        direction, center = end - start, (end + start) / 2
        obj = box("Folded roof edge", center, (.65, .65, direction.length),
                  "Blue fold", "roof", .08)
        from mathutils import Matrix
        rotation = direction.to_track_quat("Z", "Y").to_matrix()
        for vertex in obj.data.vertices:
            vertex.co = center + rotation @ (vertex.co - center)
    bpy.ops.mesh.primitive_cone_add(vertices=48, radius1=CONE_WIDTH / 2, radius2=0,
                                   depth=CONE_HEIGHT, location=(0, 0, 398 + CONE_HEIGHT / 2))
    finish(bpy.context.object, "Red cone tip", "Red paper", "topper")
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=FINIAL_RADIUS,
                                        location=(0, 0, FINIAL_CENTRE_Z))
    obj = finish(bpy.context.object, "Small gold finial", "Gold", "topper")
    for face in obj.data.polygons:
        face.use_smooth = True


def join_group(objects, name):
    hero.active(objects[0])
    for obj in objects[1:]:
        obj.select_set(True)
    if len(objects) > 1:
        bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.scene.unit_settings.system = "NONE"
    FOLDER.mkdir(parents=True, exist_ok=True)
    GROUPS.clear()
    MATERIALS.clear()
    material("Kraft", (193, 146, 93), .86, paper=True)
    material("Cut edge", (159, 111, 62), .9, paper=True)
    corrugation(MATERIALS["Cut edge"])
    material("Card seam", (163, 122, 78), .9)
    material("Tape", (218, 187, 144), .42, tape=True)
    material("Tape light", (227, 201, 164), .37, tape=True)
    material("Green", (18, 143, 65), .32)
    material("Red plastic", (223, 30, 28), .27)
    material("Blue plastic", (12, 105, 204), .28)
    material("Yellow", (248, 187, 19), .31)
    material("Clock paper", (241, 221, 181), .82, paper=True)
    material("Ink", (31, 35, 32), .58)
    material("Gold", (255, 204, 63), .14, metallic=BELL_METALLIC)
    material("Blue paper", (24, 87, 178), .73, paper=True)
    material("Blue fold", (19, 70, 147), .75, paper=True)
    material("Red paper", (224, 33, 30), .62, paper=True)
    build_legs()
    build_arches()
    build_clock()
    build_belfry()
    build_roof()
    objects = [join_group(items, label) for label, items in GROUPS.items()]
    for obj in objects:
        obj["hero_height"] = HEIGHT
        obj["hero_front"] = "-y"
    bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
    report = measure(objects)
    (FOLDER / "measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    build_clock_source()
    bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    render(objects)
    log("SOURCE " + json.dumps(report))


def corrugation(mat):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    geometry = nodes.new("ShaderNodeNewGeometry")
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geometry.outputs["Position"], separate.inputs[0])
    add = nodes.new("ShaderNodeMath")
    add.operation = "ADD"
    links.new(separate.outputs["X"], add.inputs[0])
    links.new(separate.outputs["Y"], add.inputs[1])
    frequency = nodes.new("ShaderNodeMath")
    frequency.operation = "MULTIPLY"
    frequency.inputs[1].default_value = math.tau / 2.1
    links.new(add.outputs[0], frequency.inputs[0])
    wave = nodes.new("ShaderNodeMath")
    wave.operation = "SINE"
    links.new(frequency.outputs[0], wave.inputs[0])
    def operation(kind, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = kind
        for index, value in enumerate((a, b)):
            if value is None:
                continue
            if isinstance(value, (int, float)):
                node.inputs[index].default_value = value
            else:
                links.new(value, node.inputs[index])
        return node.outputs[0]
    normal = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geometry.outputs["Normal"], normal.inputs[0])
    underside = operation("GREATER_THAN", operation("ABSOLUTE", normal.outputs["Z"]), .5)
    cross_section = operation("ADD", operation("MULTIPLY", separate.outputs["Y"], underside),
                              operation("MULTIPLY", separate.outputs["Z"], operation("SUBTRACT", 1, underside)))
    vertical = operation("MULTIPLY", operation("FRACT", operation("MULTIPLY", cross_section, .5)), 2)
    curve = operation("ADD", operation("MULTIPLY", wave.outputs[0], .56), 1)
    flute = operation("LESS_THAN", operation("ABSOLUTE", operation("SUBTRACT", vertical, curve)), .15)
    liner = operation("MAXIMUM", operation("LESS_THAN", vertical, .14),
                      operation("GREATER_THAN", vertical, 1.86))
    paper = operation("MAXIMUM", flute, liner)
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = linear((112, 74, 39))
    ramp.color_ramp.elements[1].color = linear((205, 168, 112))
    links.new(paper, ramp.inputs[0])
    bsdf = nodes["Principled BSDF"]
    links.new(ramp.outputs[0], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .38
    bump.inputs["Distance"].default_value = .18
    links.new(paper, bump.inputs["Height"])
    links.new(bump.outputs[0], bsdf.inputs["Normal"])


def clock_positions():
    return [{"side": label, "centre": [round(v, 5) for v in rotate_xy((0, CLOCK_MOUNT_Y, CLOCK_CENTRE_Z), a)],
             "outward": [round(v, 5) for v in rotate_xy((0, -1, 0), a)],
             "rotation_z_degrees": side * 90}
            for side, label in enumerate(("front", "right", "back", "left"))
            for a in (side * math.pi / 2,)]


def install_clocks(packed=False):
    path = CLOCK_FOLDER / ("clock.blend" if packed else "clock-source.blend")
    with bpy.data.libraries.load(str(path), link=False) as (available, loaded):
        loaded.objects = ["clock-face", "clock-hour", "clock-minute"]
    from mathutils import Matrix
    instances = []
    for placement in clock_positions():
        yaw = math.radians(placement["rotation_z_degrees"])
        for obj in loaded.objects:
            copy = obj.copy()
            copy.name = "Display " + placement["side"] + " " + obj.name
            bpy.context.scene.collection.objects.link(copy)
            hand_angle = {"clock-hour": -55, "clock-minute": 60}.get(obj.name, 0)
            matrix = Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(math.radians(hand_angle), 4, "Y")
            copy.rotation_euler = matrix.to_euler()
            copy.location = placement["centre"]
            copy["clock_display"] = True
            instances.append(copy)
    return instances, loaded.objects


def tree(objects):
    vertices, polygons = [], []
    for obj in objects:
        offset = len(vertices)
        vertices.extend(tuple(v.co) for v in obj.data.vertices)
        polygons.extend(tuple(v + offset for v in f.vertices) for f in obj.data.polygons)
    # Inflated triangle tests can report a false hit below a very steep arch
    # segment. Zero inflation agrees with Blender Object.ray_cast here.
    return BVHTree.FromPolygons(vertices, polygons, all_triangles=True, epsilon=0)


def clear_box(bvh, low, high, axes=(0, 1)):
    # Both flight directions are sampled throughout the entire required volume.
    # Width/height borders are inset only by 0.05 to avoid tangential contact.
    for axis in axes:
        other = [i for i in range(3) if i != axis]
        values = [np.linspace(low[i] + .05, high[i] - .05, 25) for i in other]
        for a in values[0]:
            for b in values[1]:
                origin = [0., 0., 0.]
                origin[axis] = low[axis] + .05
                origin[other[0]], origin[other[1]] = float(a), float(b)
                direction = [0., 0., 0.]
                direction[axis] = 1
                hit = bvh.ray_cast(Vector(origin), Vector(direction), high[axis] - low[axis] - .10)
                assert hit[0] is None, ("Obstructed opening", origin, axis, tuple(hit[0]))


def measure(objects):
    structural = []
    structural_by_name = {}
    for obj in objects:
        tri = hero.triangles(obj.data)
        keep = np.ones(len(tri), dtype=bool)
        if "bell_bake_detail" in obj.data.attributes:
            detail = np.empty(len(tri), dtype=np.int32)
            obj.data.attributes["bell_bake_detail"].data.foreach_get("value", detail)
            keep = detail == 0
        if "bell_leg_stud" in obj.data.attributes:
            decoration = np.empty(len(tri), dtype=np.int32)
            obj.data.attributes["bell_leg_stud"].data.foreach_get("value", decoration)
            keep &= decoration == 0
        values = hero.coordinates(obj.data)[np.unique(tri[keep])]
        structural.append(values)
        structural_by_name[obj.name] = values
    points = np.concatenate(structural)
    lo, hi = points.min(0), points.max(0)
    assert np.max(np.abs(lo - (-103, -103, 0))) < .001, (lo, hi)
    assert abs(hi[2] - 430) < .001
    assert abs(hi[0] + lo[0]) < .001 and abs(hi[1] + lo[1]) < .001
    def group_points(prefix):
        return np.concatenate([value for name, value in structural_by_name.items()
                               if name == prefix or name.startswith(prefix + "-")])
    for prefix, expected_low, expected_high in (
        ("arches", (-103, -103, 110), (103, 103, 188)),
        ("posts", (-59, -59, 278), (59, 59, 340)),
        ("roof", (-64, -64, 340), (64, 64, 398)),
        ("upper-bricks", (-59, -59, 258), (59, 59, 278)),
        ("lower-bricks", (-103, -103, 188), (103, 103, 200))):
        co = group_points(prefix)
        assert np.max(np.abs(co.min(0) - expected_low)) < .002, (prefix, co.min(0))
        assert np.max(np.abs(co.max(0) - expected_high)) < .002, (prefix, co.max(0))
    clock_co = group_points("clock-body")
    core = clock_co[(np.abs(clock_co[:, 0]) > 70.8) & (np.abs(clock_co[:, 1]) > 70.8)]
    assert np.max(np.abs(core.min(0) - (-71, -71, 200))) < .002
    assert np.max(np.abs(core.max(0) - (71, 71, 258))) < .002
    for prefix, attribute, centre, half_width in (
        ("upper-bricks", "bell_upper_red", 47, 12),
        ("lower-bricks", "bell_lower_red", 83, 20)):
        red_points = []
        for obj in objects:
            if not (obj.name == prefix or obj.name.startswith(prefix + "-")):
                continue
            values = np.empty(len(obj.data.polygons), dtype=np.int32)
            obj.data.attributes[attribute].data.foreach_get("value", values)
            co = hero.coordinates(obj.data)[hero.triangles(obj.data)]
            red_points.append(co[values == 1].reshape(-1, 3))
        points = np.concatenate(red_points)
        for x in (-centre, centre):
            for y in (-centre, centre):
                co = points[(points[:, 0] * x > 0) & (points[:, 1] * y > 0)]
                assert np.max(np.abs(co[:, :2].min(0) - (x - half_width, y - half_width))) < .002
                assert np.max(np.abs(co[:, :2].max(0) - (x + half_width, y + half_width))) < .002
    bvh = tree(objects)
    for axis in (0, 1):
        angles = np.linspace(math.pi, 0, 49)
        outline_x = ARCH_HALF_WIDTH * np.cos(angles)
        outline_z = ARCH_SPRING + ARCH_HALF_WIDTH * np.sin(angles)
        for u in np.linspace(-ARCH_HALF_WIDTH + .1, ARCH_HALF_WIDTH - .1, 25):
            clearance = float(np.interp(u, outline_x, outline_z))
            for z in np.linspace(.05, clearance - .12, 25):
                origin = [-104., -104., float(z)]
                origin[1 - axis] = float(u)
                direction = [0., 0., 0.]
                direction[axis] = 1
                hit = bvh.ray_cast(Vector(origin), Vector(direction), 208)
                if hit[0] is not None:
                    offset = 0
                    for candidate in objects:
                        if offset <= hit[2] < offset + len(candidate.data.polygons):
                            owner = candidate.name
                            polygon = candidate.data.polygons[hit[2] - offset]
                            witness = [tuple(candidate.data.vertices[v].co) for v in polygon.vertices]
                            break
                        offset += len(candidate.data.polygons)
                    raise AssertionError(("Arch blocked", origin, owner, tuple(hit[0]), tuple(hit[1]), witness))
    clear_box(bvh, (-34.9, -65, 278), (34.9, 65, 299.9), axes=(1,))
    clear_box(bvh, (-65, -34.9, 278), (65, 34.9, 299.9), axes=(0,))
    # Measure vertical headroom at the centre and on every facade, both axes.
    arches = []
    for axis in (0, 1):
        for sign in (-1, 1):
            origin = [0., 0., .01]
            origin[axis] = sign * 94
            hit = bvh.ray_cast(Vector(origin), Vector((0, 0, 1)), 300)
            assert hit[0] is not None and abs(hit[0].z - ARCH_APEX) < .01
            arches.append(round(hit[0].z, 3))
    arch_co = group_points("arches")
    for axis in (0, 1):
        for sign in (-1, 1):
            curve = arch_co[(np.abs(arch_co[:, axis] - sign * 103) < .001) &
                            (np.abs(arch_co[:, 1 - axis]) <= ARCH_HALF_WIDTH + .001) &
                            (arch_co[:, 2] >= ARCH_SPRING - .001) &
                            (arch_co[:, 2] <= ARCH_APEX + .001)]
            radii = np.linalg.norm(curve[:, [1 - axis, 2]] - (0, ARCH_SPRING), axis=1)
            assert len(curve) >= 25 and np.max(np.abs(radii - ARCH_HALF_WIDTH)) < .002
    bell = [o for o in objects if o.name == "bell"]
    assert len(bell) == 1, "Bell must remain an independent piece"
    bell_lo = float(hero.bounds(bell[0])[0][2])
    assert bell_lo >= BELL_BOTTOM - .001
    bell_span = hero.bounds(bell[0])[1] - hero.bounds(bell[0])[0]
    assert np.max(np.abs(bell_span - (BELL_WIDTH, BELL_WIDTH, BELL_HEIGHT))) < .001
    posts = [o for o in objects if o.name.startswith("posts")]
    post_bottom = min(float(hero.bounds(o)[0][2]) for o in posts)
    post_top = max(float(hero.bounds(o)[1][2]) for o in posts)
    assert abs(post_bottom - 278) < .001 and abs(post_top - 340) < .001
    post_co = np.concatenate([hero.coordinates(o.data) for o in posts])
    belfry_widths = [float(post_co[post_co[:, axis] > 0, axis].min() -
                          post_co[post_co[:, axis] < 0, axis].max()) for axis in (0, 1)]
    assert all(abs(width - 70) < .001 for width in belfry_widths)
    # Only the four green plates reach the ground; connected components prove it.
    ground_components = []
    leg_objects = [o for o in objects if o.name.startswith("legs")]
    for obj in leg_objects:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        for group in hero.components(bm):
            points = np.array([v.co[:] for v in group])
            if points[:, 2].min() < .001:
                a, b = points.min(0), points.max(0)
                ground_components.append({"centre": ((a[:2] + b[:2]) / 2).round(3).tolist(),
                                          "footprint": (b[:2] - a[:2]).round(3).tolist()})
        bm.free()
    ground_components.sort(key=lambda item: tuple(item["centre"]))
    assert len(ground_components) == 4
    assert all(g["footprint"] == [40., 40.] and all(abs(v) == 83 for v in g["centre"])
               for g in ground_components)
    assert all(hero.bounds(o)[0][2] > 0 for o in objects if not o.name.startswith("legs"))
    # Check all twelve complete brick bodies, independent of exposed studs.
    leg_triangles = {row: [] for row in (1, 2, 3)}
    for obj in leg_objects:
        values = np.empty(len(obj.data.polygons), dtype=np.int32)
        obj.data.attributes["bell_leg_brick"].data.foreach_get("value", values)
        co = hero.coordinates(obj.data)[hero.triangles(obj.data)]
        for row in leg_triangles:
            leg_triangles[row].append(co[values == row].reshape(-1, 3))
    measured_bricks = []
    for row, expected_z in enumerate(((5, 39.8), (40.2, 74.8), (75.2, 110)), 1):
        points = np.concatenate(leg_triangles[row])
        for x in (-83, 83):
            for y in (-83, 83):
                co = points[(points[:, 0] * x > 0) & (points[:, 1] * y > 0)]
                a, b = co.min(0), co.max(0)
                assert np.max(np.abs(a - (x - 20, y - 20, expected_z[0]))) < .002
                assert np.max(np.abs(b - (x + 20, y + 20, expected_z[1]))) < .002
                measured_bricks.append({"centre_xy": [x, y], "course": row,
                                        "size_xyz": (b - a).round(4).tolist(),
                                        "z": list(expected_z)})
    tip = group_points("topper")
    cone = tip[tip[:, 2] <= 428.001]
    base = cone[np.abs(cone[:, 2] - 398) < .001]
    assert abs(np.ptp(base[:, 0]) - CONE_WIDTH) < .002
    assert abs(np.ptp(base[:, 1]) - CONE_WIDTH) < .002
    return {"axes": "studs, Z up, front -Y, base centre at origin",
            "overall_bounds": {"min": lo.round(4).tolist(), "max": hi.round(4).tolist()},
            "outer_footprint": (hi[:2] - lo[:2]).round(4).tolist(),
            "legs": ground_components, "brick_leg_top": 110,
            "big_leg_bricks": measured_bricks, "bricks_per_leg": 3, "brick_sequence": ["red", "blue", "red"],
            "leg_brick_footprint": [40, 40], "arch_jambs_align_with_leg_inner_faces": True,
            "arch_opening_width": 2 * ARCH_HALF_WIDTH, "arch_centre_clear_height": ARCH_APEX,
            "arch_spring_height": ARCH_SPRING, "arch_straight_jamb_height_above_legs": ARCH_SPRING - 110,
            "arch_radius": ARCH_HALF_WIDTH, "arch_shape": "semicircle on all four sides",
            "cardboard_above_arch_apex": 188 - ARCH_APEX,
            "arch_crown_height_on_four_sides": arches,
            "arch_through_X_and_Y_clear": True,
            "belfry_post_bottom": round(post_bottom, 4), "belfry_ceiling": round(post_top, 4),
            "belfry_clear_width": round(min(belfry_widths), 4),
            "belfry_clear_height_below_bell": round(bell_lo - 278, 3),
            "belfry_through_X_and_Y_clear_below_bell": True,
            "bell_lowest_point": round(bell_lo, 4), "bell_size_xyz": bell_span.round(4).tolist(),
            "roof_base": 340, "roof_peak": 398, "roof_footprint": [128, 128],
            "clock_body_size_xyz": (core.max(0) - core.min(0)).round(4).tolist(), "clock_body_z": [200, 258],
            "clock_seat_diameter": 0, "clock_positions": clock_positions(),
            "arch_block_size_xyz": [206, 206, 78], "arch_block_z": [110, 188],
            "belfry_outer_footprint": [118, 118], "belfry_post_size_xy": [24, 24],
            "upper_band_footprint": [118, 118], "upper_red_corner_footprint": [24, 24],
            "upper_red_corner_centres_xy": [[x, y] for x in (-47, 47) for y in (-47, 47)],
            "lower_red_corner_footprint": [40, 40],
            "lower_red_corner_centres_xy": [[x, y] for x in (-83, 83) for y in (-83, 83)],
            "lower_blue_visible_span": 126, "clock_base_board_footprint": [160, 160],
            "cone_base_width": round(CONE_WIDTH, 5), "cone_z": [398, 428],
            "cone_height_width_ratio": round(CONE_HEIGHT / CONE_WIDTH, 5),
            "finial_radius": FINIAL_RADIUS, "bell_hanger_top": BELL_BOTTOM + BELL_HEIGHT,
            "total_height": round(float(hi[2] - lo[2]), 4),
            "flight_volume_ray_checks": 2500, "ground_touching_components": 4}


def render(objects, packed=False):
    scene = bpy.context.scene
    for obj in list(scene.objects):
        if obj.type in ("CAMERA", "LIGHT"):
            bpy.data.objects.remove(obj, do_unlink=True)
    hero.cycles_setup()
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 1600
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    world = bpy.data.worlds.new("Warm white studio")
    world.use_nodes = True
    nodes, links = world.node_tree.nodes, world.node_tree.links
    ambient = nodes["Background"]
    ambient.inputs["Color"].default_value = (.78, .80, .85, 1)
    ambient.inputs["Strength"].default_value = .38
    background = nodes.new("ShaderNodeBackground")
    background.inputs["Color"].default_value = (.96, .945, .92, 1)
    path = nodes.new("ShaderNodeLightPath")
    polished_environment = nodes.new("ShaderNodeBackground")
    polished_environment.inputs["Color"].default_value = (.96, .92, .82, 1)
    polished_environment.inputs["Strength"].default_value = 1.05
    reflected_light = nodes.new("ShaderNodeMixShader")
    links.new(path.outputs["Is Glossy Ray"], reflected_light.inputs[0])
    links.new(ambient.outputs[0], reflected_light.inputs[1])
    links.new(polished_environment.outputs[0], reflected_light.inputs[2])
    mix = nodes.new("ShaderNodeMixShader")
    links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    links.new(reflected_light.outputs[0], mix.inputs[1])
    links.new(background.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], nodes["World Output"].inputs[0])
    scene.world = world
    bpy.ops.mesh.primitive_plane_add(size=100000, location=(0, 0, -.05))
    floor = bpy.context.object
    floor.name = "Temporary warm studio floor"
    floor_material = bpy.data.materials.new("Warm white ground")
    floor_material.use_nodes = True
    floor_bsdf = floor_material.node_tree.nodes["Principled BSDF"]
    floor_bsdf.inputs["Base Color"].default_value = (.93, .91, .88, 1)
    floor_bsdf.inputs["Roughness"].default_value = .9
    # An infinity backdrop: retain real nearby contact shadows, then blend
    # distant ground into the same warm white as the camera background.
    floor_nodes, floor_links = floor_material.node_tree.nodes, floor_material.node_tree.links
    floor_position = floor_nodes.new("ShaderNodeNewGeometry")
    radius = floor_nodes.new("ShaderNodeVectorMath")
    radius.operation = "LENGTH"
    floor_links.new(floor_position.outputs["Position"], radius.inputs[0])
    fade = floor_nodes.new("ShaderNodeMapRange")
    fade.clamp = True
    fade.interpolation_type = "SMOOTHERSTEP"
    fade.inputs["From Min"].default_value = 400
    fade.inputs["From Max"].default_value = 1200
    floor_links.new(radius.outputs["Value"], fade.inputs["Value"])
    distant_white = floor_nodes.new("ShaderNodeEmission")
    distant_white.inputs["Color"].default_value = (.96, .945, .92, 1)
    distant_white.inputs["Strength"].default_value = 1
    floor_mix = floor_nodes.new("ShaderNodeMixShader")
    floor_links.new(fade.outputs["Result"], floor_mix.inputs[0])
    floor_links.new(floor_bsdf.outputs[0], floor_mix.inputs[1])
    floor_links.new(distant_white.outputs[0], floor_mix.inputs[2])
    floor_links.new(floor_mix.outputs[0], floor_nodes["Material Output"].inputs[0])
    floor.data.materials.append(floor_material)
    for name, direction, energy, size in (("Warm key", (-1.3, -2, 2.5), 95, 1.7),
                                           ("Soft fill", (1.5, -1, 1.5), 28, 2.2),
                                           ("Rim", (.7, 1.6, 2), 45, 1.6)):
        bpy.ops.object.light_add(type="AREA", location=Vector((0, 0, 200)) + Vector(direction) * HEIGHT)
        obj = bpy.context.object
        obj.name = name
        obj.data.energy = energy * HEIGHT ** 2
        obj.data.shape, obj.data.size = "DISK", size * HEIGHT
        hero.point_at(obj, (0, 0, 210))
    # Small studio reflection cards sit below the cardboard ceiling, where
    # the bell's curved shoulders can see them. They affect glossy rays only,
    # so bright gold highlights do not bleach the paper and plastic colours.
    reflection_material = bpy.data.materials.new("Warm gold studio reflection")
    reflection_material.use_nodes = True
    reflection_nodes = reflection_material.node_tree.nodes
    reflection_nodes.clear()
    reflection_emission = reflection_nodes.new("ShaderNodeEmission")
    reflection_emission.inputs["Color"].default_value = (.98, .97, .94, 1)
    reflection_emission.inputs["Strength"].default_value = 1.6
    reflection_output = reflection_nodes.new("ShaderNodeOutputMaterial")
    reflection_material.node_tree.links.new(reflection_emission.outputs[0], reflection_output.inputs[0])
    reflection_cards = []
    for position in ((0, -45, 319), (45, 0, 319), (0, 45, 319), (-45, 0, 319)):
        bpy.ops.mesh.primitive_plane_add(size=1, location=position)
        card = bpy.context.object
        card.name = "Temporary gold reflection card"
        card.dimensions = (28, 64, 0)
        direction = Vector((0, 0, 319)) - card.location
        card.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
        card.visible_camera = card.visible_diffuse = card.visible_shadow = False
        card.visible_transmission = card.visible_volume_scatter = False
        card.data.materials.append(reflection_material)
        reflection_cards.append(card)
    # The roof shades the bell from the main keys. Linked fills provide a
    # warm front reflection and diffuse light to the gold alone.
    bell_receivers = bpy.data.collections.new("Bell studio light receivers")
    bell_receivers.objects.link(next(obj for obj in objects if obj.name == "bell"))
    for position in ((0, -130, 315), (130, 0, 315), (0, 130, 315), (-130, 0, 315)):
        bpy.ops.object.light_add(type="AREA", location=position)
        fill = bpy.context.object
        fill.name = "Bell-only warm studio fill"
        fill.data.energy = .65 * HEIGHT ** 2
        fill.data.color = (1, .97, .90)
        fill.data.shape, fill.data.size = "DISK", 80
        fill.light_linking.receiver_collection = bell_receivers
        hero.point_at(fill, (0, 0, 320))
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    scene.camera = camera
    camera.data.type = "ORTHO"
    camera.data.clip_end = HEIGHT * 20
    displayed, templates = install_clocks(packed)
    reference = bpy.data.images.load(str(ROOT / "assets/references/bell-tower/front-a.png"), check_existing=False)
    reference_size = tuple(reference.size)
    bpy.data.images.remove(reference)
    cameras = {}
    views = [("front", (0, -1500, 215), (0, 0, 215), 478),
             ("side", (1850, 0, 320), (0, 0, 215), 478),
             ("threequarter", (700, -1800, 500), (0, 0, 215), 490),
             ("arch-through-y", (0, -850, 100), (0, 0, 100), 238),
             ("arch-through-x", (850, 0, 100), (0, 0, 100), 238),
             ("belfry-through-y", (0, -850, 309), (0, 0, 309), 150),
             ("belfry-through-x", (850, 0, 309), (0, 0, 309), 150)]
    for label, position, target, scale in views:
        scene.render.resolution_x, scene.render.resolution_y = reference_size if label == "front" else (1600, 1600)
        camera.location = position
        hero.point_at(camera, target)
        camera.data.shift_y = 0
        if label in ("front", "side", "threequarter"):
            camera.data.type = "PERSP"
            camera.data.sensor_fit = "HORIZONTAL"
            camera.data.sensor_width = 36
            aspect = scene.render.resolution_x / scene.render.resolution_y
            camera.data.lens = (Vector(position) - Vector(target)).length * 36 / (scale * aspect)
        else:
            camera.data.type = "ORTHO"
            camera.data.ortho_scale = scale
        if label == "front":
            from bpy_extras.object_utils import world_to_camera_view
            bpy.context.view_layer.update()
            tip, ground = Vector((0, 0, HEIGHT)), Vector((0, -103, 0))
            desired_tip = 1 - 17 / reference_size[1]
            desired_ground = 1 - 894 / reference_size[1]
            actual_tip = world_to_camera_view(scene, camera, tip).y
            actual_ground = world_to_camera_view(scene, camera, ground).y
            camera.data.lens *= (desired_tip - desired_ground) / (actual_tip - actual_ground)
            before = world_to_camera_view(scene, camera, tip).y
            camera.data.shift_y = .01
            derivative = (world_to_camera_view(scene, camera, tip).y - before) / .01
            camera.data.shift_y = (desired_tip - before) / derivative
            assert abs(world_to_camera_view(scene, camera, tip).y - desired_tip) < 1e-5
            assert abs(world_to_camera_view(scene, camera, ground).y - desired_ground) < 1e-5
        cameras[label] = {"position": list(position), "target": list(target),
                          "projection": camera.data.type, "lens_mm": round(camera.data.lens, 5),
                          "sensor_width_mm": camera.data.sensor_width,
                          "vertical_shift": round(camera.data.shift_y, 6),
                          "resolution": [scene.render.resolution_x, scene.render.resolution_y]}
        if label == "front":
            cameras[label].update({"reference": "assets/references/bell-tower/front-a.png",
                                  "match": "estimated frontal perspective; fitted reference tip and front-foot heights",
                                  "reference_has_camera_metadata": False,
                                  "reference_tip_y": 17, "reference_front_foot_y": 894})
            log("Front camera fitted: " + str(round(camera.data.lens, 3)) + " mm")
        scene.render.filepath = str(FOLDER / ("render-" + label + ".png"))
        bpy.ops.render.render(write_still=True)
    comparison()
    camera.location = views[2][1]
    hero.point_at(camera, views[2][2])
    camera.data.type = "PERSP"
    camera.data.lens = (Vector(views[2][1]) - Vector(views[2][2])).length * 36 / views[2][3]
    for obj in displayed + templates + [floor] + reflection_cards:
        bpy.data.objects.remove(obj, do_unlink=True)
    for data in list(bpy.data.meshes):
        if data.users == 0:
            bpy.data.meshes.remove(data)
    return cameras


def comparison():
    # Crop only empty side margins, using Blender image I/O. The original
    # reference file stays untouched and both towers retain their proportions.
    concept = bpy.data.images.load(str(ROOT / "assets/references/bell-tower/front-a.png"), check_existing=False)
    front = bpy.data.images.load(str(FOLDER / "render-front.png"), check_existing=False)
    h = 1600
    w = round(concept.size[0] * h / concept.size[1])
    concept.scale(w, h)
    front_width = round(front.size[0] * h / front.size[1])
    front.scale(front_width, h)
    left = np.empty(w * h * 4, dtype=np.float32)
    right = np.empty(front_width * h * 4, dtype=np.float32)
    concept.pixels.foreach_get(left)
    front.pixels.foreach_get(right)
    crop_width = 1050
    left_start, right_start = (w - crop_width) // 2, (front_width - crop_width) // 2
    left = left.reshape(h, w, 4)[:, left_start:left_start + crop_width]
    right = right.reshape(h, front_width, 4)[:, right_start:right_start + crop_width]
    pixels = np.concatenate((left, right), axis=1)
    combined = bpy.data.images.new("Design A and finished model", width=2 * crop_width, height=h, alpha=True)
    combined.pixels.foreach_set(pixels.ravel())
    combined.filepath_raw = str(FOLDER / "compare.png")
    combined.file_format = "PNG"
    combined.save()
    for img in (concept, front, combined):
        bpy.data.images.remove(img)


def render_saved():
    report = json.loads((FOLDER / "parts.json").read_text())
    bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "hero.blend"))
    bpy.context.preferences.filepaths.save_version = 0
    objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    assert len(objects) == report["piece_count"]
    assert measure(objects) == report["measurements"]
    report["render_cameras"] = render(objects, packed=True)
    (FOLDER / "parts.json").write_text(json.dumps(report, indent=2) + "\n")
    bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER / "hero.blend"))
    log("RERENDERED saved exported tower and four separate clocks")


def density(obj):
    result = hero.front_density(obj)
    if result["front_pixels_per_stud"] is not None:
        return result
    # hero.py's facade metric omits surfaces tilted more than 60 degrees
    # from a vertical wall. This short roof presents its sloping blue panel
    # to the front camera, so measure that actual panel, with the same units.
    assert obj.name.startswith("roof"), ("No outward density surface", obj.name)
    verts = hero.coordinates(obj.data)[hero.triangles(obj.data)]
    cross = np.cross(verts[:, 1] - verts[:, 0], verts[:, 2] - verts[:, 0])
    areas = np.linalg.norm(cross, axis=1) / 2
    sign = 1 if "-back" in obj.name else -1
    mask = (cross[:, 1] * sign > areas * 2 * .05) & (verts.mean(1)[:, 1] * sign > 1e-5)
    if "hero_cap" in obj.data.attributes:
        cap = np.empty(len(obj.data.polygons), dtype=np.int32)
        obj.data.attributes["hero_cap"].data.foreach_get("value", cap)
        mask &= cap == 0
    uv = np.empty(len(obj.data.loops) * 2, dtype=np.float64)
    obj.data.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 3, 2)
    a, b = uv[:, 1] - uv[:, 0], uv[:, 2] - uv[:, 0]
    pixels = np.abs(a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]) / 2 * hero.SIZE ** 2
    surface = float(areas[mask].sum())
    assert surface > 0
    return {"density_face": "back" if sign == 1 else "front",
            "density_method": "outward sloping roof panel, area-equivalent texels per stud",
            "front_surface_studs2": round(surface, 4),
            "front_pixels_per_stud": round(math.sqrt(float(pixels[mask].sum()) / surface), 3)}


def set_texture_budget(label):
    hero.SIZE = 4096 if label == "clock-body" or label == "arches" or label.startswith("arches-") else 2048
    hero.BAKE_SIZE = 2 * hero.SIZE


def unwrap(obj):
    key = hashlib.sha256(b"bell-uv-1" + str(hero.SIZE).encode() +
                         hero.coordinates(obj.data).tobytes() + hero.triangles(obj.data).tobytes()).hexdigest()
    cache = UV_CACHE / (obj.name + "-" + key + ".npz")
    if cache.is_file():
        with np.load(cache, allow_pickle=False) as data:
            while obj.data.uv_layers:
                obj.data.uv_layers.remove(obj.data.uv_layers[0])
            obj.data.uv_layers.new(name="HeroUV")
            obj.data.uv_layers.active.data.foreach_set("uv", data["uv"])
        obj["uv_cache_reused"] = True
        return hero.assert_uvs(obj)
    obj["uv_cache_reused"] = False
    for angle in (80, 60, 45):
        for margin in (.0027, .004, .006):
            hero.PACK_MARGIN[0] = margin
            hero.unwrap(obj, angle)
            try:
                report = hero.assert_uvs(obj)
                assert report["uv_coverage"] >= hero.MIN_COVERAGE
                sharpness = density(obj)["front_pixels_per_stud"]
                if sharpness < DENSITY_FLOOR:
                    log(obj.name + ": repacking for texture density " + str(sharpness))
                    break
                UV_CACHE.mkdir(exist_ok=True)
                uv = np.empty(len(obj.data.loops) * 2, dtype=np.float32)
                obj.data.uv_layers.active.data.foreach_get("uv", uv)
                np.savez_compressed(cache, uv=uv)
                return report
            except AssertionError as error:
                if "stretch" in str(error) and angle != 45:
                    break
                if "padding" not in str(error) or margin == .006:
                    raise
    raise AssertionError("Cannot unwrap without losing quality: " + obj.name)


def baked_working_geometry(obj):
    """Retain the source silhouette; carry subpixel stud fillets in the normal map.

    The large visible studs on the brick legs keep their complete bevel geometry.
    Only the tiny upward studs use closed round cylinders as bake targets. No
    decimation is used, and all source detail remains available to the bake.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    detail = bm.faces.layers.int["bell_bake_detail"]
    stud = bm.faces.layers.int["bell_top_stud"]
    stud_bounds = []
    for component in hero.components(bm):
        faces = {f for v in component for f in v.link_faces}
        points = np.array([v.co[:] for v in component])
        # Also accepts the already-saved source from the visual inspection.
        # Raised ink and folded paper lines retain colour and normal detail.
        materials = {obj.data.materials[f.material_index].name for f in faces}
        if materials == {"Blue fold"} or (materials == {"Ink"} and np.ptp(points, axis=0).max() > 5):
            for face in faces:
                face[detail] = 1
        if faces and all(f[stud] for f in faces):
            stud_bounds.append((points.min(0), points.max(0)))
    gone = [f for f in bm.faces if f[detail] or f[stud]]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    for low, high in stud_bounds:
        center, span = (low + high) / 2, high - low
        result = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=16,
                                      radius1=span[0] / 2, radius2=span[0] / 2,
                                      depth=span[2])
        for vertex in result["verts"]:
            vertex.co += Vector(center)
        new_faces = {f for v in result["verts"] for f in v.link_faces}
        for face in new_faces:
            face.smooth = len(face.verts) == 4
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()


def export_clock():
    bpy.ops.wm.open_mainfile(filepath=str(CLOCK_FOLDER / "clock-source.blend"))
    bpy.context.preferences.filepaths.save_version = 0
    names = ("clock-face", "clock-hour", "clock-minute")
    originals = [bpy.data.objects[name] for name in names]
    sources = []
    for index, obj in enumerate(originals):
        attribute = obj.data.attributes.new("clock_component", "INT", "FACE")
        attribute.data.foreach_set("value", np.full(len(obj.data.polygons), index, dtype=np.int32))
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.scene.collection.objects.link(copy)
        for vertex in copy.data.vertices:
            vertex.co.x += index * 100
        sources.append(copy)
        if index == 0:
            baked_working_geometry(obj)
        for vertex in obj.data.vertices:
            vertex.co.x += index * 100
    # Separating the bake targets prevents upright hands being painted onto
    # the dial. After the shared bake, each mesh returns to the clock pivot.
    source = join_group(sources, "Clock high source")
    atlas = join_group(originals, "clock-atlas")
    hero.cycles_setup()
    uv = unwrap(atlas)
    maps = hero.bake(source, atlas, CLOCK_FOLDER, "clock", 160)
    hero.destroy(source)
    pieces = []
    report = {"front": "-Y", "axes": "Blender studs: X right, Y depth, Z up",
              "pivot": [0, 0, 0], "rotation_axis": [0, 1, 0],
              "shared_texture_set": ["clock-color.png", "clock-normal.png", "clock-roughness.png"],
              "texture_size": hero.SIZE, "atlas_uv": uv, "clock_positions": clock_positions(),
              "exported_hand_pose": "both straight up at 12", "rendered_hand_pose": "10:10",
              "meshes": []}
    for index, name in enumerate(names):
        bm = bmesh.new()
        bm.from_mesh(atlas.data)
        component = bm.faces.layers.int["clock_component"]
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[component] != index], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        for vertex in bm.verts:
            vertex.co.x -= index * 100
        obj = hero.mesh_object(name, bm)
        bm.free()
        obj.data.materials.append(atlas.data.materials[0])
        for face in obj.data.polygons:
            face.material_index = 0
        piece = hero.geometry_checks(obj)
        piece.update(hero.assert_uvs(obj))
        piece.update(density(obj))
        low, high = hero.bounds(obj)
        centre = (low + high) / 2
        piece.update({"size_xyz": (high - low).round(5).tolist(),
                      "box_centre": centre.round(5).tolist(),
                      "pivot_offset_xyz": (-centre).round(5).tolist(),
                      "axis": [-round(float(centre[0]), 5), -round(float(centre[2]), 5)],
                      "axis_coordinates": "X,Z offset from mesh box centre to clock pivot",
                      "rotation_axis": [0, 1, 0]})
        assert piece["front_pixels_per_stud"] >= DENSITY_FLOOR
        hero.export_piece(obj, CLOCK_FOLDER, name)
        pieces.append(obj)
        report["meshes"].append(piece)
    hero.destroy(atlas)
    report["total_triangles"] = sum(p["triangles"] for p in report["meshes"])
    assert all(hero.bounds(o)[1][2] > 0 and abs(hero.bounds(o)[0][0] + hero.bounds(o)[1][0]) < .001
               for o in pieces[1:])
    for image in maps.values():
        image.filepath = "//" + Path(image.filepath).name
    (CLOCK_FOLDER / "checks.json").write_text(json.dumps(report, indent=2) + "\n")
    bpy.ops.wm.save_as_mainfile(filepath=str(CLOCK_FOLDER / "clock.blend"))
    return report


def clean_cut_edges(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    unused = [edge for edge in bm.edges if not edge.link_faces]
    isolated = [vertex for vertex in bm.verts if not vertex.link_faces]
    changed = bool(unused or isolated)
    if unused:
        bmesh.ops.delete(bm, geom=unused, context="EDGES")
    isolated = [vertex for vertex in bm.verts if not vertex.link_faces]
    if isolated:
        bmesh.ops.delete(bm, geom=isolated, context="VERTS")
    if changed:
        bm.to_mesh(obj.data)
        log("Removed unused cut edges from " + obj.name)
    bm.free()
    obj["cut_edges_repaired"] = changed


def preflight_geometry(obj):
    # Run hero's complete geometry checks before spending time on any bake.
    materials = list(obj.data.materials)
    slots = np.empty(len(obj.data.polygons), dtype=np.int32)
    obj.data.polygons.foreach_get("material_index", slots)
    obj.data.materials.clear()
    check_material = materials[0] if materials else bpy.data.materials.new("Temporary geometry check")
    obj.data.materials.append(check_material)
    obj.data.polygons.foreach_set("material_index", np.zeros_like(slots))
    try:
        return hero.geometry_checks(obj)
    finally:
        obj.data.materials.clear()
        for material in materials:
            obj.data.materials.append(material)
        obj.data.polygons.foreach_set("material_index", slots)
        if not materials:
            bpy.data.materials.remove(check_material)


def recover_completed_uv(obj, path):
    """Recover verified UVs independently of Blender's vertex ordering."""
    old = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path))
    imported = [o for o in bpy.data.objects if o not in old]
    copy = next(o for o in imported if o.type == "MESH")
    hero.active(copy)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    assert len(copy.data.polygons) == len(obj.data.polygons), "Resume FBX topology differs"
    def key(points):
        corners = [tuple(np.round(point, 3)) for point in points]
        rotations = [tuple(corners[i:] + corners[:i]) for i in range(3)]
        start = min(range(3), key=lambda i: rotations[i])
        return rotations[start], start
    faces = {}
    points = hero.coordinates(copy.data)[hero.triangles(copy.data)]
    uv = np.empty(len(copy.data.loops) * 2, dtype=np.float32)
    copy.data.uv_layers.active.data.foreach_get("uv", uv)
    for position, coords in zip(points, uv.reshape(-1, 3, 2)):
        identity, start = key(position)
        faces.setdefault(identity, []).append((np.roll(position, -start, axis=0),
                                               np.roll(coords, -start, axis=0)))
    restored = []
    for position in hero.coordinates(obj.data)[hero.triangles(obj.data)]:
        identity, start = key(position)
        assert identity in faces and faces[identity], "Resume FBX geometry differs"
        previous, coords = faces[identity].pop()
        assert np.max(np.abs(np.roll(position, -start, axis=0) - previous)) < .001
        restored.append(np.roll(coords, start, axis=0))
    assert not any(faces.values()), "Resume FBX has extra surfaces"
    while obj.data.uv_layers:
        obj.data.uv_layers.remove(obj.data.uv_layers[0])
    obj.data.uv_layers.new(name="HeroUV")
    obj.data.uv_layers.active.data.foreach_set("uv", np.array(restored, dtype=np.float32).ravel())
    for other in imported:
        bpy.data.objects.remove(other, do_unlink=True)
    obj["uv_cache_reused"] = True
    log("Recovered completed UVs " + obj.name)
    return hero.assert_uvs(obj)


def source_signature(obj):
    geometry = []
    positions = hero.coordinates(obj.data)[hero.triangles(obj.data)]
    used_materials = set()
    for points, face in zip(positions, obj.data.polygons):
        mat = obj.data.materials[face.material_index]
        used_materials.add(mat)
        corners = sorted(tuple(float(v) for v in p) for p in np.round(points, 4))
        geometry.append((corners, mat.name, face.use_smooth))
    materials = []
    for mat in sorted(used_materials, key=lambda m: m.name):
        nodes = []
        for node in sorted(mat.node_tree.nodes, key=lambda n: n.name):
            inputs = []
            for socket in node.inputs:
                if hasattr(socket, "default_value"):
                    value = socket.default_value
                    try:
                        value = list(value)
                    except TypeError:
                        pass
                    inputs.append((socket.identifier, value))
            ramp = [(element.position, list(element.color)) for element in node.color_ramp.elements] if hasattr(node, "color_ramp") else None
            nodes.append((node.name, node.bl_idname, inputs, ramp))
        links = sorted((link.from_node.name, link.from_socket.identifier,
                        link.to_node.name, link.to_socket.identifier) for link in mat.node_tree.links)
        materials.append((mat.name, nodes, links))
    return hashlib.sha256(json.dumps((sorted(geometry), materials), sort_keys=True).encode()).hexdigest()


def export_clock_body():
    """Rebake only piece 29, without writing the source, clocks or other pieces."""
    part_folder = FOLDER / "parts"
    prefix = "29-clock-body"
    report_path = FOLDER / "parts.json"
    report = json.loads(report_path.read_text())
    index = next(i for i, piece in enumerate(report["pieces"]) if piece["prefix"] == prefix)
    previous = report["pieces"][index]
    expected = [np.array(previous["bounding_box"][key]) for key in ("min", "max")]
    bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
    source = bpy.data.objects["clock-body"]
    for other in list(bpy.context.scene.objects):
        if other != source:
            bpy.data.objects.remove(other, do_unlink=True)
    # The saved approved source still has the old discs. Remove only those
    # four closed islands in memory; preserve the approved materials, tape
    # footprints and board seam rather than rebuilding the saved source.
    bm = bmesh.new()
    bm.from_mesh(source.data)
    discs = []
    for component in hero.components(bm):
        points = np.array([vertex.co[:] for vertex in component])
        span = np.ptp(points, axis=0)
        faces = {face for vertex in component for face in vertex.link_faces}
        materials = {source.data.materials[face.material_index].name for face in faces}
        if materials == {"Kraft"} and np.max(np.abs(np.sort(span) - (.5, 50, 50))) < .002:
            centre = (points.min(0) + points.max(0)) / 2
            assert abs(centre[2] - 229) < .002 and abs(np.linalg.norm(centre[:2]) - 71.1) < .002
            discs.append(component)
    assert len(discs) in (0, 4), ("Unexpected clock seats", len(discs))
    bmesh.ops.delete(bm, geom=[vertex for component in discs for vertex in component], context="VERTS")
    bm.to_mesh(source.data)
    bm.free()
    target = source.copy()
    target.data = source.data.copy()
    source.name = "Clock body high source (baking only)"
    target.name = "clock-body"
    bpy.context.scene.collection.objects.link(target)
    # The discs used to set the import bounds 0.35 studs outside the board.
    # Retain one existing lower tape fold on each face as a closed bake target
    # and extend only its outer depth by 0.125 studs. Its footprint, the kraft
    # board, source materials, tape footprints and seam remain unchanged.
    # Match that tiny depth extension in the bake source too, so rays from
    # the fold's narrow edge faces do not miss and leave black atlas pixels.
    bm = bmesh.new()
    bm.from_mesh(target.data)
    detail = bm.faces.layers.int["bell_bake_detail"]
    retained = 0
    for component in hero.components(bm):
        points = np.array([vertex.co[:] for vertex in component])
        faces = {face for vertex in component for face in vertex.link_faces}
        materials = {target.data.materials[face.material_index].name for face in faces}
        centre = (points.min(0) + points.max(0)) / 2
        if len(component) != 8 or materials != {"Tape light"} or abs(centre[2] - 207) > .002:
            continue
        axis = int(np.argmax(np.abs(centre[:2])))
        sign = 1 if centre[axis] > 0 else -1
        # Choose the clockwise lower corner, once per face.
        if centre[1 - axis] * sign * (1 if axis == 0 else -1) < 0:
            continue
        outer = points[:, axis].max() if sign > 0 else points[:, axis].min()
        boundary = expected[1 if sign > 0 else 0][axis]
        assert 0 <= (boundary - outer) * sign < .2, "Unexpected tape-fold bounds"
        for vertex in component:
            if abs(vertex.co[axis] - outer) < .001:
                vertex.co[axis] = float(boundary)
                source.data.vertices[vertex.index].co[axis] = float(boundary)
        for face in faces:
            face[detail] = 0
        retained += 1
    assert retained == 4, ("Expected four bounds-preserving tape folds", retained)
    bm.to_mesh(target.data)
    bm.free()
    source.data.update()
    baked_working_geometry(target)
    clean_cut_edges(target)
    for actual, old in zip(hero.bounds(target), expected):
        assert np.max(np.abs(actual - old)) < .01, "Clock body bounds changed"
    set_texture_budget(target.name)
    hero.cycles_setup()
    uv = unwrap(target)
    preflight_geometry(target)
    hero.bake(source, target, part_folder, prefix, 160)
    piece = hero.geometry_checks(target)
    piece.update(uv)
    piece.update(density(target))
    assert piece["front_pixels_per_stud"] >= DENSITY_FLOOR
    piece.update(prefix=prefix, texture_size=hero.SIZE, bake_size=hero.BAKE_SIZE)
    hero.export_piece(target, part_folder, prefix)
    report["pieces"][index] = piece
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    log("EXPORTED ONLY " + json.dumps(piece))


def export(resume=False, reuse_approved=False):
    source_stamp = (FOLDER / "bell-tower.blend").stat().st_mtime
    if resume:
        assert (CLOCK_FOLDER / "clock.blend").stat().st_mtime >= (CLOCK_FOLDER / "clock-source.blend").stat().st_mtime
        clock_report = json.loads((CLOCK_FOLDER / "checks.json").read_text())
    else:
        clock_report = export_clock()
    bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
    bpy.context.preferences.filepaths.save_version = 0
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    originals = list(bpy.context.scene.objects)
    signatures = {obj.name: source_signature(obj) for obj in originals}
    previous = json.loads((FOLDER / "parts.json").read_text()) if (FOLDER / "parts.json").is_file() else {}
    approved_groups = {"legs", "arch-board", "clock-base", "lower-bricks", "upper-bricks", "posts"}
    legacy_approved = previous.get("size_revision", "").startswith("Alan's four marked corrections:")
    previous_signatures = previous.get("source_signatures", {})
    reusable_groups = {name for name in approved_groups if reuse_approved and
                       (previous_signatures.get(name) == signatures[name] or
                        (legacy_approved and not previous_signatures))}
    for obj in originals:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces], context="EDGES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(obj.data)
        bm.free()
    if not resume:
        bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
    # hero.py does the same capped X/Y cuts used by the other hero buildings.
    # The bell and cone remain intact; the larger bands get four atlas budgets.
    source_copies = []
    for obj in originals:
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.scene.collection.objects.link(copy)
        source_copies.append(copy)
    source = join_group(source_copies, "High source (baking only)")
    # Store the unlit gold colour in the diffuse map. Metal response belongs
    # to the dedicated bell material, rather than darkening its colour atlas.
    for mat in source.data.materials:
        mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0
    for obj in originals:
        baked_working_geometry(obj)
    # Cut only at the two real brick joins. Each of the three large bricks
    # gets its own texture budget, with no altered exterior silhouette.
    leg = next(o for o in originals if o.name == "legs")
    bottom = hero.bisect(leg, 40, False, "legs-bottom", HEIGHT)
    remaining = hero.bisect(leg, 40, True, "legs-remaining", HEIGHT)
    middle = hero.bisect(remaining, 75, False, "legs-middle", HEIGHT)
    top = hero.bisect(remaining, 75, True, "legs-top", HEIGHT)
    originals = [bottom, middle, top] + [o for o in originals if o != leg]
    hero.destroy(leg)
    hero.destroy(remaining)
    splits = "legs-bottom:xy,legs-middle:xy,legs-top:xy,arches:xy,arch-board:xy,clock-base:xy,lower-bricks:xy,upper-bricks:xy,posts:xy,roof:xy"
    pieces = hero.split_vertical(originals, splits, HEIGHT)
    for obj in pieces:
        clean_cut_edges(obj)
    source.hide_render = True
    source.hide_set(True)
    source_count = len(source.data.polygons)
    log("GEOMETRY " + str(source_count) + " source; " +
        str(sum(len(o.data.polygons) for o in pieces)) + " exported triangles")
    assert sum(len(o.data.polygons) for o in pieces) + 4 * clock_report["total_triangles"] <= hero.TOTAL_LIMIT
    measure(pieces)
    part_folder = FOLDER / "parts"
    part_folder.mkdir(exist_ok=True)
    report = {"source": "bell-tower.blend", "pipeline": "hero.py capped cuts, UV checks, baking and FBX roundtrip",
              "source_triangles": source_count, "front": "-y", "requested_height": HEIGHT,
              "texture_size": hero.SIZE, "bake_size": hero.BAKE_SIZE,
              "arch_texture_size": 4096, "arch_bake_size": 8192,
              "clock_body_texture_size": 4096, "clock_body_bake_size": 8192,
              "piece_count": len(pieces), "vertical_splits": splits,
              "min_coverage": hero.MIN_COVERAGE, "density_floor_pixels_per_stud": DENSITY_FLOOR,
              "density_reference": "gateway-towers/parts.json: highest front_pixels_per_stud",
              "clock_positions": clock_positions(), "clocks_baked_onto_body": False,
              "clock_asset": "clock/checks.json", "clock_unique_triangles": clock_report["total_triangles"],
              "clock_instances": 4,
              "size_revision": "round 4: cone 27x30, radius-63 semicircle, polished 46x48 bell, crumpled paper",
              "source_signatures": signatures,
              "reference_overrides": {"cone_base_width": round(CONE_WIDTH, 5),
                                      "arch_opening_width": 126, "upper_band_footprint": [118, 118],
                                      "lower_blue_visible_span": 126, "arch_apex": ARCH_APEX,
                                      "bell_size_xyz": [BELL_WIDTH, BELL_WIDTH, BELL_HEIGHT]},
              "pieces": []}
    hero.cycles_setup()
    uv_reports = {}
    for index, obj in enumerate(pieces, 1):
        set_texture_budget(obj.name)
        prefix = str(index) + "-" + obj.name
        existing = [part_folder / (prefix + suffix)
                    for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png")]
        approved = any(obj.name == group or obj.name.startswith(group + "-") for group in reusable_groups)
        completed = (not obj["cut_edges_repaired"] and
                     ((approved and all(path.is_file() for path in existing)) or
                      (resume and all(path.is_file() and path.stat().st_mtime >= source_stamp for path in existing))))
        obj["reuse_completed_bake"] = completed
        uv_reports[obj.name] = recover_completed_uv(obj, existing[0]) if completed else unwrap(obj)
        preflight_geometry(obj)
        sharpness = density(obj)["front_pixels_per_stud"]
        assert sharpness is not None and sharpness >= DENSITY_FLOOR, (obj.name, sharpness, DENSITY_FLOOR)
        log("READY " + obj.name + ": " + str(len(obj.data.polygons)) +
            " triangles, " + str(sharpness) + " pixels/stud")
    for index, obj in enumerate(pieces, 1):
        set_texture_budget(obj.name)
        prefix = str(index) + "-" + obj.name
        uv = uv_reports[obj.name]
        # The projection cage includes raised paint and tape, with a smaller
        # reach than the default cage for a tower of this height.
        paths = {channel: part_folder / (prefix + "-" + channel + ".png")
                 for channel in ("color", "normal", "roughness")}
        reuse = (obj["reuse_completed_bake"] and obj["uv_cache_reused"] and not obj["cut_edges_repaired"] and
                 all(path.is_file() and
                     hero.png_size(path) == (hero.SIZE, hero.SIZE) for path in paths.values()))
        if reuse:
            maps = {}
            for channel, path in paths.items():
                image = bpy.data.images.load(str(path), check_existing=False)
                image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
                image.pack()
                maps[channel] = image
            hero.baked_material(obj, maps)
            log("Reused completed bake " + prefix)
        else:
            hero.bake(source, obj, part_folder, prefix, 160)
        if obj.name == "bell":
            obj.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = BELL_METALLIC
        piece = hero.geometry_checks(obj)
        piece.update(uv)
        piece.update(density(obj))
        sharpness = piece["front_pixels_per_stud"]
        assert sharpness is not None and sharpness >= DENSITY_FLOOR, (obj.name, sharpness, DENSITY_FLOOR)
        piece["prefix"] = prefix
        piece["texture_size"] = hero.SIZE
        piece["bake_size"] = hero.BAKE_SIZE
        if obj.name == "bell":
            piece["metallic"] = BELL_METALLIC
        hero.export_piece(obj, part_folder, prefix)
        report["pieces"].append(piece)
        log("EXPORTED " + json.dumps(piece))
    hero.destroy(source)
    report.update(hero.assembly_checks(pieces, HEIGHT))
    report["tower_triangles"] = sum(p["triangles"] for p in report["pieces"])
    report["total_triangles"] = report["tower_triangles"] + 4 * clock_report["total_triangles"]
    assert report["total_triangles"] <= hero.TOTAL_LIMIT
    report["measurements"] = measure(pieces)
    report["render_cameras"] = render(pieces, packed=True)
    for img in bpy.data.images:
        if img.packed_file:
            img.filepath = "//parts/" + Path(img.filepath).name
    (FOLDER / "parts.json").write_text(json.dumps(report, indent=2) + "\n")
    (FOLDER / "measurements.json").write_text(json.dumps(report["measurements"], indent=2) + "\n")
    wanted = {p["prefix"] + suffix for p in report["pieces"]
              for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png")}
    for path in part_folder.iterdir():
        if path.name not in wanted and path.suffix.lower() in (".fbx", ".png"):
            path.unlink()
    bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER / "hero.blend"))
    log("FINISHED " + str(report["total_triangles"]) + " triangles in " + str(len(pieces)) + " pieces")


def verify_clock():
    report = json.loads((CLOCK_FOLDER / "checks.json").read_text())
    bpy.ops.wm.open_mainfile(filepath=str(CLOCK_FOLDER / "clock.blend"))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert {o.name for o in objects} == {"clock-face", "clock-hour", "clock-minute"}
    assert report["clock_positions"] == clock_positions()
    assert len({o.data.materials[0] for o in objects}) == 1, "Clock meshes must share one material"
    for piece in report["meshes"]:
        obj = bpy.data.objects[piece["label"]]
        actual = hero.geometry_checks(obj)
        assert all(actual[key] == piece[key] for key in actual)
        assert density(obj)["front_pixels_per_stud"] == piece["front_pixels_per_stud"] >= DENSITY_FLOOR
        low, high = hero.bounds(obj)
        centre = (low + high) / 2
        assert (high - low).round(5).tolist() == piece["size_xyz"]
        assert (-centre).round(5).tolist() == piece["pivot_offset_xyz"]
        assert piece["axis"] == [-round(float(centre[0]), 5), -round(float(centre[2]), 5)]
        assert piece["rotation_axis"] == [0, 1, 0]
        if obj.name != "clock-face":
            assert abs(low[0] + high[0]) < .001 and low[2] < 0 < high[2]
            tip = hero.coordinates(obj.data)[np.argmax(hero.coordinates(obj.data)[:, 2])]
            assert abs(tip[0]) < .001, "Hand is not straight up at 12"
        for channel in ("color", "normal", "roughness"):
            image = obj.data.materials[0].node_tree.nodes[channel].image
            assert image.packed_file and tuple(image.size) == (hero.SIZE, hero.SIZE)
            assert hero.png_size(CLOCK_FOLDER / ("clock-" + channel + ".png")) == (hero.SIZE, hero.SIZE)
        old = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(CLOCK_FOLDER / (obj.name + ".fbx")))
        imported = [o for o in bpy.data.objects if o not in old]
        copy = next(o for o in imported if o.type == "MESH")
        assert copy.matrix_world.translation.length < .001, "Clock FBX pivot moved away from the dial centre"
        hero.active(copy)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        assert copy.location.length < .001
        assert len(copy.data.polygons) == piece["triangles"]
        assert all(np.max(np.abs(a - b)) < .01 for a, b in zip(hero.bounds(copy), hero.bounds(obj)))
        for other in imported:
            bpy.data.objects.remove(other, do_unlink=True)
    copies = []
    for obj in objects:
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.scene.collection.objects.link(copy)
        copies.append(copy)
    atlas = join_group(copies, "Clock shared UV check")
    assert hero.assert_uvs(atlas) == report["atlas_uv"]
    hero.destroy(atlas)
    assert sum(p["triangles"] for p in report["meshes"]) == report["total_triangles"]
    return report


def verify():
    clock_report = verify_clock()
    report = json.loads((FOLDER / "parts.json").read_text())
    bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "hero.blend"))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(objects) == report["piece_count"]
    assert measure(objects) == report["measurements"]
    for piece in report["pieces"]:
        obj = bpy.data.objects[piece["label"]]
        set_texture_budget(obj.name)
        assert piece["texture_size"] == hero.SIZE and piece["bake_size"] == hero.BAKE_SIZE
        actual = hero.geometry_checks(obj)
        assert all(actual[key] == piece[key] for key in actual)
        uv = hero.assert_uvs(obj)
        assert all(uv[key] == piece[key] for key in uv)
        assert density(obj)["front_pixels_per_stud"] == piece["front_pixels_per_stud"] >= DENSITY_FLOOR
        for channel in ("color", "normal", "roughness"):
            path = FOLDER / "parts" / (piece["prefix"] + "-" + channel + ".png")
            assert path.is_file() and hero.png_size(path) == (hero.SIZE, hero.SIZE)
            img = obj.data.materials[0].node_tree.nodes[channel].image
            assert img.packed_file and tuple(img.size) == (hero.SIZE, hero.SIZE)
        # Reimport existing FBX, without rewriting it, and independently compare.
        old = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(FOLDER / "parts" / (piece["prefix"] + ".fbx")))
        imported = [o for o in bpy.data.objects if o not in old]
        copy = next(o for o in imported if o.type == "MESH")
        hero.active(copy)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        assert len(copy.data.polygons) == piece["triangles"]
        assert all(np.max(np.abs(a - b)) < .01 for a, b in zip(hero.bounds(copy), hero.bounds(obj)))
        for other in imported:
            bpy.data.objects.remove(other, do_unlink=True)
    assert sum(p["triangles"] for p in report["pieces"]) == report["tower_triangles"]
    assert report["total_triangles"] == report["tower_triangles"] + 4 * clock_report["total_triangles"] <= 48000
    assert report["clock_positions"] == clock_positions() and report["clocks_baked_onto_body"] is False
    expected = {p["prefix"] + suffix for p in report["pieces"]
                for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png")}
    assert expected == {p.name for p in (FOLDER / "parts").iterdir()
                        if p.suffix.lower() in (".fbx", ".png")}
    for name in ("front", "side", "threequarter", "arch-through-x", "arch-through-y",
                 "belfry-through-x", "belfry-through-y"):
        expected_size = tuple(report["render_cameras"][name]["resolution"])
        assert hero.png_size(FOLDER / ("render-" + name + ".png")) == expected_size
    assert hero.png_size(FOLDER / "compare.png") == (2100, 1600)
    write_report(report)
    if UV_CACHE.is_dir():
        for path in UV_CACHE.glob("*.npz"):
            path.unlink()
        UV_CACHE.rmdir()
    log("VERIFY PASS: saved geometry, textures, UVs, all FBX files and flight openings")


def write_report(report):
    m = report["measurements"]
    clock = json.loads((CLOCK_FOLDER / "checks.json").read_text())
    lines = ["Bell tower design A: round 4, reference corrections and separate animated-clock asset", "",
             "TIP: red cone is 27 across and 30 tall, from 398 to 428.",
             "Small gold ball has radius 2.2, centre at 427.8 and top at 430.",
             "CORNERS: upper red bricks are 24 square, centred at (+/-47, +/-47), directly under the posts.",
             "The upper blue band is 118 square, with outer faces flush with those red corners.",
             "Lower red corners are 40 square, centred at (+/-83, +/-83), flush with the 206-square arch block.",
             "ARCH: 206 square, exactly aligned with the 40-wide brick bodies' outer faces.",
             "Opening is 126 wide: a true radius-63 semicircle springing at the leg tops, 110, with apex 173.",
             "No straight jambs above the legs. The 110-188 block leaves 15 of cardboard above the apex.",
             "The same curve is measured on all four sides. Corner tape retained.",
             "LEGS: three large 40-square bricks per leg, red/blue/red, about 35 tall, on a 5-tall green plate.",
             "Each exposed outer brick face has four large studs. The two joins also have four top studs.",
             "Clock body is 142 square at 200-258, with tape and board seams but no round seats.",
             "Belfry is 278-340 (62 tall), with 118 outer footprint and 70 opening, as Alan corrected.",
             "BELL: 46 across, 48 tall, low point 300, polished warm gold with roughness 0.14 and metallic 0.85.",
             "Its hanger reaches 348, inside the roof; the visible shell ends at 338, beneath the ceiling.",
             "Roof is 128 square, 340-398. Stronger irregular paper folds on the roof and kraft panels are baked into the maps.",
             "One separate clock has two independently turning hands. All four are displayed at 10:10.", "",
             "Size conflicts resolved using Alan's latest instruction:",
             "Cone base 9.33333 -> 27; cone height 28 -> 30, as Alan measured from front-a.png for round 4.",
             "Arch spring 124 -> 110; apex 155 -> 173; both radii are 63.",
             "Bell 36 x 36 x 40 -> 46 x 46 x 48, with its lowest point retained at 300.",
             "Upper band 150 -> 118, explicitly approved by Alan and updated in the brief.", "",
             "The lower visible blue run is 126 between the flush 40-wide corner bricks;",
             "its old 160-wide run overlapped those corners. The 160-square clock base board is retained.", "",
             "Files written:", "tools/art/bell_tower.py",
             "assets/models/bell-tower/bell-tower.blend (editable material source)",
             "assets/models/bell-tower/hero.blend (packed exported assembly)",
             "assets/models/bell-tower/parts.json", "assets/models/bell-tower/measurements.json",
             "assets/models/bell-tower/report.txt", "",
             "assets/models/bell-tower/clock/clock-source.blend",
             "assets/models/bell-tower/clock/clock.blend",
             "assets/models/bell-tower/clock/checks.json",
             "assets/models/bell-tower/clock/clock-face.fbx, clock-hour.fbx, clock-minute.fbx",
             "The three clock meshes share clock-color.png, clock-normal.png, clock-roughness.png.", "",
             "Each prefix below has parts/<prefix>.fbx, <prefix>-color.png,",
             "<prefix>-normal.png and <prefix>-roughness.png. Arch and clock-body maps are 4096 x 4096;",
             "all other tower and clock maps are 2048 x 2048.", "",
             "Piece list (triangles; front pixels per stud):"]
    lines.extend(p["prefix"] + ": " + str(p["triangles"]) + "; " +
                 str(p["front_pixels_per_stud"]) for p in report["pieces"])
    lines += ["Tower: " + str(report["tower_triangles"]) + " triangles, " + str(report["piece_count"]) + " pieces.",
              "Clock meshes (triangles, measured size XYZ, pivot offset XYZ from box centre):"]
    lines.extend(p["label"] + ": " + str(p["triangles"]) + "; " + str([round(v, 3) for v in p["size_xyz"]]) + "; " +
                 str(p["pivot_offset_xyz"]) for p in clock["meshes"])
    lines += ["Total with FOUR installed clocks: " + str(report["total_triangles"]) + " triangles.",
              "Limit: 12000 triangles per piece; 48000 total.",
              "Every piece exceeds Gateway's highest density (" + str(DENSITY_FLOOR) + " pixels/stud).", "",
              "Measured dimensions, studs (Z up, base centre at origin, front -Y):",
              "Four ground feet: 40 x 40, centred at (+/-83, +/-83). Only these touch ground.",
              "Structural footprint: 206 x 206. Brick leg tops: 110.",
              "Side stud ends project 1.9 beyond the brick bodies; the arch is flush with the bodies.",
              "Arches: 126 wide, radius 63, spring at 110, centre clearance 173 on every side.",
              "Straight flight through the middle in X and Y is clear.",
              "Clock body: 142 x 142 x 58, from 200 to 258. No round mounting seats.",
              "Four clock centre points and outward facings: " + str(clock_positions()),
              "Both exported hands point at 12; render instances show approximately 10:10.",
              "All origins are the dial centre; turn hands about the local Y axis.",
              "Belfry: yellow posts from " + str(m["belfry_post_bottom"]) + " to " + str(m["belfry_ceiling"]) + ".",
              "Belfry opening: " + str(m["belfry_clear_width"]) + " wide on every side; no glass or rails.",
              "Bell lowest point: " + str(m["bell_lowest_point"]) + ". Clear height below bell: " +
              str(m["belfry_clear_height_below_bell"]) + ". Bell is its own piece.",
              "Bell size: " + str(m["bell_size_xyz"]) + ".",
              "Roof seat: 340; blue roof peak: 398; base: 128 square; cone base: 27; cone top: 428; finial top: 430.", "",
              "Renders, all in assets/models/bell-tower/:",
              "render-front.png", "render-side.png", "render-threequarter.png",
              "render-arch-through-x.png", "render-arch-through-y.png",
              "render-belfry-through-x.png", "render-belfry-through-y.png",
              "compare.png (front-a.png beside the final front render)", "",
              "Verification: saved geometry/UVs/maps and every FBX reimport passed;",
              "2500 ray tests passed in the two required ground and belfry flight volumes.", "",
              "Reference check: final front comparison inspected side by side against front-a.png.",
              "Round-4 points checked: broad cone, semicircular arch, larger polished-gold bell and paper creases.",
              "Front camera uses the reference's 1672 x 941 frame and matches its tip and front-foot pixel heights.",
              "Front camera: " + str(report["render_cameras"]["front"]),
              "Lighting uses warm area lights, bell-only linked fills, glossy-only studio reflection cards and soft ground shadows.",
              "Remaining visual differences against front-a.png:",
              "The reference has no camera metadata, so its original lens cannot be recovered exactly; the recorded lens is a fitted estimate.",
              "At matched overall framing the requested 27-by-30 cone appears shorter, and the radius-63 arch crown higher, than drawn in the reference.",
              "The requested measured dimensions are retained; the comparison is not an exact silhouette match.",
              "The blue roof's paper wrinkles are subtler than the reference, although the baked side panel shows the irregular creases clearly.",
              "The bell has strong polished-gold highlights, with a darker reflection of the cardboard ceiling across its shoulder.",
              "Surface wrinkles and tape folds are procedurally made and do not trace every crease in the picture.",
              "Tape and small roof folds are baked surface detail. Clock hands remain separate geometry.",
              "Large side studs stay geometric; tiny top-stud fillets are in the normal maps.",
              "No Roblox import or in-game check was run, as instructed."]
    (FOLDER / "report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--export", action="store_true")
    parser.add_argument("--export-piece", choices=("29-clock-body",), help="Rebake only the clock body; leave saved sources, clocks and every other piece untouched")
    parser.add_argument("--resume", action="store_true", help="Resume unchanged source using matching cached UVs and completed maps")
    parser.add_argument("--reuse-approved", action="store_true", help="Reuse the accepted round-3 legs, bricks, posts and boards after source/FBX/UV checks")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--compare", action="store_true", help="Rebuild the side-by-side comparison from the final front render")
    parser.add_argument("--render-final", action="store_true", help="Rerender the verified packed export without rebaking unchanged maps")
    parser.add_argument("--render-preview", action="store_true", help="Check and render the saved source")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if args.export_piece:
        export_clock_body()
    elif args.verify:
        verify()
    elif args.compare:
        comparison()
    elif args.render_final:
        render_saved()
    elif args.render_preview:
        bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
        report = measure([o for o in bpy.context.scene.objects if o.type == "MESH"])
        (FOLDER / "measurements.json").write_text(json.dumps(report, indent=2) + "\n")
        build_clock_source()
        bpy.ops.wm.open_mainfile(filepath=str(FOLDER / "bell-tower.blend"))
        render([o for o in bpy.context.scene.objects if o.type == "MESH"])
        log("SOURCE CHECKS PASSED " + json.dumps(report))
    elif args.export or args.resume:
        export(resume=args.resume, reuse_approved=args.reuse_approved)
    else:
        build()
