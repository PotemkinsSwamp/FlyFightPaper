"""Build, bake, export and check the town-rug toys in Blender.

PowerShell, from D:/FlyFightPaper:
& 'D:/Blender/blender.exe' -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/toys.py -- pencil-flagpole

Run with Blender's --factory-startup and --python-exit-code 1. Arguments after
-- are toy names. Only this script and the named toy output folders are used.
Use --preview before the names for 512px maps and an Eevee preview in temp.
Coordinates are studs, Z up, with the front facing -Y. Regenerate from this
script; the saved blend contains the actual FBX mesh and the baking materials.
"""

import json
import math
import tempfile
import struct
import sys
import traceback
import zlib
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets/models/toys"
RESOLUTION = 1024
BAKE_RESOLUTION = 1024
PADDING = 10 / RESOLUTION
SPECS = {
    "tree-lollipop": (800, (20.9, 20.9, 26)),
    "tree-bushy": (1500, (20, None, 26)),
    "tree-pine": (700, (18, 18, 30)),
    "bench": (1000, (10, 4, 4.5)),
    "flagpole": (600, (None, None, 32)),
    # All nine classroom.rbxmx rooftop poles are 2 x 42 x 2, measured from foot.
    "pencil-flagpole": (2200, (None, None, 42)),
    "car-hatchback": (2500, (7, 15, 6)),
    "car-sedan": (2500, (7, 15.5, 5.5)),
    "car-taxi": (2500, (7, 15.5, 6.5)),
    "car-van": (2500, (7.5, 16, 8)),
    "fire-truck": (3000, (8, 22, 10)),
    "crane": (6000, (None, 60.8, 80)),
    "monorail-pylon": (1500, (11.6, 11.6, 120)),
    "monorail-beam": (300, (6, 40, 5)),
    "monorail-car": (4000, (11, 34, 15)),
    "monorail-car-middle": (4000, (11, 33.2, 15)),
    "bus": (3500, (9.2, 26.6, 11.5)),
    "bus-stop": (3500, (14.2, 6.8, 11)),
    "tugboat": (4000, (12.4, 30, 16)),
    "cone": (900, (4.2, 4.2, 5.4)),
    "barrier": (1500, (11.2, 3.2, 5.6)),
    "paper-boat": (600, (6.2, 14.4, 8.2)),
    "rowing-boat": (3000, (None, 14.2, 4)),
    "dump-truck": (4000, (9.4, 22, 10)),
    "digger": (5000, (9.4, 22, 13.6)),
    "site-building": (9000, (36, 30.5, 45)),
    "site-fence": (900, (10.6, 1.8, 6.6)),
    "cement-mixer": (3000, (5.6, 7.4, 6.4)),
    "sand-pile": (1200, (12, 12, 4.6)),
    "gravel-pile": (3500, (12, 12, 4.2)),
    "plank-stack": (1500, (8.6, 5.4, 2.6)),
    "pipe-stack": (2500, (8.4, 5.0, 3.0)),
    "brick-stack": (3000, (7.6, 5.4, 3.6)),
    "site-cabin": (2500, (14.4, 8.4, 7.4)),
    "site-toilet": (1500, (4.6, 4.6, 7.6)),
    "street-lamp": (1500, (None, None, 36.4)),
    "fountain": (2000, (24, 24, 14)),
    "crop-row": (450, (20, 5, 4)),
    "stall": (1500, (22, 14, 16)),
    "house": (2500, (26, 22, 24)),
    "playground": (3500, (50, 30, 18)),
    "picnic": (800, (12, 10, 5)),
    "goal": (2000, (24, 8, 8)),
    "pool": (1500, (44, 44, 6)),
    "hay-bale": (800, (8, 8, 8)),
    "footbridge": (1500, (10, 34, 7)),
    "boathouse": (2500, (30, 24, 18)),
    "barn": (3000, (44, 34, 30)),
    "petrol-station": (3000, (60, 44, 18)),
    "fire-station": (3000, (50, 40, 30)),
    "plane": (2500, (26, 24, 9)),
    "hangar": (1500, (40, 30, 20)),
    "terminal": (3000, (40, 30, 36)),
    "ruler-bridge": (5999, (304, 45, 155)),
    "school-desk": (4000, (330, 210, 108)),
    "school-chair": (2500, (110, 100, 200)),
    "paper-bunting": (1500, (300, None, None)),
    "saturn": (2500, (140, None, None)),
    "jungle-gym": (6000, (800, 600, 500)),
    "swing-set": (6000, (700, 300, 480)),
    "slide": (6000, (800, 160, 440)),
    "basketball-hoop": (6000, (360, 200, 640)),
    "fence-panel": (900, (500, 10, 240)),
    "seesaw": (6000, (600, 80, 160)),
    "merry-go-round": (6000, (400, 400, 180)),
    "spring-rider": (3400, (120, 60, 170)),
    "monkey-bars": (6000, (600, 150, 420)),
    "tire-swing": (6000, (500, 300, 480)),
    "crawl-tunnel": (6000, (400, 160, 160)),
}
MORE_SCHOOLYARD_TOYS = {"seesaw", "merry-go-round", "spring-rider", "monkey-bars",
                       "tire-swing", "crawl-tunnel"}
SCHOOLYARD_TOYS = {"jungle-gym", "swing-set", "slide", "basketball-hoop", "fence-panel"} | MORE_SCHOOLYARD_TOYS
CLASSROOM_TOYS = {"school-desk", "school-chair", "paper-bunting", "saturn"} | SCHOOLYARD_TOYS
CONCEPTLESS_TOYS = {"crop-row", "pencil-flagpole"} | CLASSROOM_TOYS
SOURCE_REFERENCE_TOYS = {"pencil-flagpole"} | CLASSROOM_TOYS
METALNESS_TOYS = {"pencil-flagpole", "school-desk", "school-chair"} | SCHOOLYARD_TOYS
CLASSROOM_FIXTURE_SPECS = {
    "classroom-door": (2500, (190, 20, 370)),
    "floor-fan": (3500, (156, 156, 36)),
    "desk-hangar": (1500, (110, 70, 50)),
    "cubby-shelf": (5000, (600, 120, 300)),
    "backpack-cubby": (9000, (700, 60, 140)),
    "bulletin-board": (500, (360, 8, 260)),
    "classroom-bookshelf": (9000, (300, 85, 260)),
    "ceiling-light": (1500, (150, 40, 8)),
}
CLASSROOM_FIXTURE_TOYS = set(CLASSROOM_FIXTURE_SPECS)
SPECS.update(CLASSROOM_FIXTURE_SPECS)
CLASSROOM_TOYS.update(CLASSROOM_FIXTURE_TOYS)
CONCEPTLESS_TOYS.update(CLASSROOM_FIXTURE_TOYS)
SOURCE_REFERENCE_TOYS.update(CLASSROOM_FIXTURE_TOYS)
METALNESS_TOYS.update({"classroom-door", "floor-fan", "ceiling-light"})
CONNECTED_CITY_SPECS = {
    "ruler-section": (600, (60, 30, 6)),
    "ruler-tape": (300, (10, 32, 8)),
    "ceiling-ring": (2000, (80, 8, 86)),
    "cardboard-tube": (2500, (70, 200, 76)),
    "paper-chain": (6000, (220, 12, 176)),
}
CONNECTED_CITY_TOYS = set(CONNECTED_CITY_SPECS)
SPECS.update(CONNECTED_CITY_SPECS)
CLASSROOM_TOYS.update(CONNECTED_CITY_TOYS)
CONCEPTLESS_TOYS.update(CONNECTED_CITY_TOYS)
SOURCE_REFERENCE_TOYS.update(CONNECTED_CITY_TOYS)
DESK_PIECE_SPECS = {
    "landing-ring": (4500, (74, 8, 74)),
    "speed-bolt": (600, (9, 2.5, 16)),
    "runway-light": (300, (3, 3, 3.1)),
    "runway-light-tip": (100, (.675, .675, .9)),
    "desk-runway-droop": (2000, (100, 225, None)),
    "desk-runway-straight": (2000, (100, 251, None)),
}
DESK_PIECE_TOYS = set(DESK_PIECE_SPECS)
SPECS.update(DESK_PIECE_SPECS)
CLASSROOM_TOYS.update(DESK_PIECE_TOYS)
CONCEPTLESS_TOYS.update(DESK_PIECE_TOYS)
SPECS["chalk-eraser"] = (1500, (92, 29, 25))
CLASSROOM_TOYS.add("chalk-eraser")
CONCEPTLESS_TOYS.add("chalk-eraser")
SPECIAL_ORIGIN_TOYS = {"paper-bunting"} | DESK_PIECE_TOYS
PARTS = []
MATERIALS = {}
REVISED = {"petrol-station", "fire-station", "terminal", "hangar", "barn", "house",
           "boathouse", "stall", "pool", "hay-bale", "car-hatchback", "car-sedan",
           "car-taxi", "plane", "footbridge"}
PREVIEW = False
# Prop_Flag1-8 and Prop_Flag11, in Roblox X/Y/Z order. In Blender Y is depth
# and Z is height. Their upper edges are 41 studs above the 42-stud pole foot.
PENCIL_FLAG_SIZE = (15, 12, 1)
PENCIL_FLAG_FROM_FOOT = (8, 35, 0)


def triangle_cap(name):
    if name == "stall":
        return 2200
    return int(SPECS[name][0] * (1.5 if name in REVISED else 1))


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply(obj, modifier):
    active(obj)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def linear(color):
    def channel(value):
        value /= 255
        return value / 12.92 if value <= 0.04045 else ((value + .055) / 1.055) ** 2.4
    return tuple(channel(value) for value in color) + (1,)


def material(name, color, wood=False, roughness=.3, bevel=.07):
    key = (name, tuple(color), wood, roughness, bevel)
    if key in MATERIALS:
        return MATERIALS[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_fake_user = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = .13 if wood else .2
    bsdf.inputs["Coat Roughness"].default_value = .27
    rgb = nodes.new("ShaderNodeRGB")
    rgb.name = "Paint color"
    rgb.outputs[0].default_value = linear(color)
    coordinates = nodes.new("ShaderNodeTexCoord")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = (3.5, 3.5, .1) if wood else (35, 35, 35)
    links.new(coordinates.outputs["Object"], scale.inputs[0])
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 1
    noise.inputs["Detail"].default_value = 2.5 if wood else 1
    noise.inputs["Roughness"].default_value = .65
    links.new(scale.outputs[0], noise.inputs["Vector"])
    grain = nodes.new("ShaderNodeMapRange")
    grain.inputs["To Min"].default_value = .77 if wood else .985
    grain.inputs["To Max"].default_value = 1.14 if wood else 1.015
    links.new(noise.outputs["Fac"], grain.inputs["Value"])
    tint = nodes.new("ShaderNodeMixRGB")
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 1
    links.new(rgb.outputs[0], tint.inputs[1])
    links.new(grain.outputs[0], tint.inputs[2])
    ao = nodes.new("ShaderNodeAmbientOcclusion")
    ao.name = "Soft contact occlusion"
    ao.inputs["Distance"].default_value = 1
    ao.samples = 16
    ao_factor = nodes.new("ShaderNodeMapRange")
    # Linear .60 is about 20% darker after the sRGB colour map is saved.
    ao_factor.inputs["To Min"].default_value = .60
    ao_factor.inputs["To Max"].default_value = 1
    links.new(ao.outputs["AO"], ao_factor.inputs["Value"])
    contact = nodes.new("ShaderNodeMixRGB")
    contact.name, contact.blend_type = "Paint with soft contact shadows", "MULTIPLY"
    contact.inputs[0].default_value = 1
    links.new(tint.outputs[0], contact.inputs[1])
    links.new(ao_factor.outputs[0], contact.inputs[2])
    links.new(contact.outputs[0], bsdf.inputs["Base Color"])
    rough = nodes.new("ShaderNodeMapRange")
    rough.inputs["To Min"].default_value = roughness - .025
    rough.inputs["To Max"].default_value = roughness + .025
    links.new(noise.outputs["Fac"], rough.inputs["Value"])
    links.new(rough.outputs[0], bsdf.inputs["Roughness"])
    edge = nodes.new("ShaderNodeBevel")
    edge.samples = 6
    edge.inputs["Radius"].default_value = bevel
    geometry = nodes.new("ShaderNodeNewGeometry")
    links.new(geometry.outputs["Normal"], edge.inputs["Normal"])
    edge_weight = nodes.new("ShaderNodeVectorMath")
    edge_weight.operation = "SCALE"
    edge_weight.inputs[3].default_value = .35
    links.new(edge.outputs["Normal"], edge_weight.inputs[0])
    surface_weight = nodes.new("ShaderNodeVectorMath")
    surface_weight.operation = "SCALE"
    surface_weight.inputs[3].default_value = .65
    links.new(geometry.outputs["Normal"], surface_weight.inputs[0])
    blend = nodes.new("ShaderNodeVectorMath")
    blend.operation = "ADD"
    links.new(edge_weight.outputs[0], blend.inputs[0])
    links.new(surface_weight.outputs[0], blend.inputs[1])
    soften = nodes.new("ShaderNodeVectorMath")
    soften.operation = "NORMALIZE"
    links.new(blend.outputs[0], soften.inputs[0])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .2 if wood else .08
    bump.inputs["Distance"].default_value = .065 if wood else .007
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(soften.outputs[0], bump.inputs["Normal"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    MATERIALS[key] = mat
    return mat


def green(tone=0):
    colors = [(94, 153, 52), (103, 159, 56), (86, 145, 47)]
    return material("Canopy green " + str(tone), colors[tone], bevel=.11)


def timber(pale=False):
    return material("Pale polished wood" if pale else "Honey polished wood",
                    (231, 205, 164) if pale else (169, 105, 51),
                    wood=True, roughness=.36, bevel=.055)


def concept_color(name, point, radius=2):
    pixels = png_read(OUTPUT / name / "concept.png")
    x, y = round(point[0] * (pixels.shape[1] - 1)), round(point[1] * (pixels.shape[0] - 1))
    return tuple(int(value) for value in np.median(pixels[max(0, y - radius):y + radius + 1,
                                                        max(0, x - radius):x + radius + 1], axis=(0, 1)))


def arch_frame(name, width, height, thickness, trim, location, mat):
    radius = width / 2
    spring = height - radius
    outer = [(-radius, 0)] + [(radius * math.cos(t), spring + radius * math.sin(t))
                            for t in np.linspace(math.pi, 0, 17)] + [(radius, 0)]
    inner = [(radius - trim, 0)] + [((radius - trim) * math.cos(t),
                                   spring + (radius - trim) * math.sin(t))
                                  for t in np.linspace(0, math.pi, 17)] + [(-radius + trim, 0)]
    obj = extruded_profile(name, outer + inner, -thickness / 2, thickness / 2, mat, .07, 3)
    obj.rotation_euler.z = math.pi / 2
    obj.location = location
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def rounded_ring(name, outer, inner, depth, location, mat, axis="Z", radius=.25):
    """One closed frame, with three real segments on each rounded corner."""
    contours = []
    for w, h in (outer, inner):
        contour = []
        r = min(radius, w / 4, h / 4)
        for sx, sy, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
            for angle in np.linspace(start, start + 90, 4):
                t = math.radians(angle)
                contour.append((sx * (w / 2 - r) + r * math.cos(t),
                                sy * (h / 2 - r) + r * math.sin(t)))
        contours.append(contour)
    n = len(contours[0])
    vertices = [(x, y, z) for z in (-depth / 2, depth / 2) for contour in contours for x, y in contour]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces += [(i, j, j + 2 * n, i + 2 * n),
                  (i + n, i + 3 * n, j + 3 * n, j + n),
                  (i, i + n, j + n, j),
                  (i + 2 * n, j + 2 * n, j + 3 * n, i + 3 * n)]
    obj = mesh(name, vertices, faces)
    if axis == "Y": obj.rotation_euler.x = math.pi / 2
    if axis == "X": obj.rotation_euler = (math.pi / 2, 0, math.pi / 2)
    obj.location = location
    return finish(obj, mat, weighted=True)


def surface_grain(mat, scale, strength, distance, color_range=(.96, 1.04)):
    nodes = mat.node_tree.nodes
    next(n for n in nodes if n.type == "VECT_MATH" and n.operation == "MULTIPLY").inputs[1].default_value = scale
    bump = next(n for n in nodes if n.type == "BUMP")
    bump.inputs["Strength"].default_value = strength
    bump.inputs["Distance"].default_value = distance
    grain = next(n for n in nodes if n.type == "MAP_RANGE")
    grain.inputs["To Min"].default_value, grain.inputs["To Max"].default_value = color_range


def finish(obj, mat, smooth=True, uv="smart", weighted=False):
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = smooth
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    if weighted:
        mod = obj.modifiers.new("Broad faces stay flat", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        mod.weight = 50
        apply(obj, mod)
    if uv in ("smart", "strict"):
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(12 if uv == "strict" else 55), island_margin=0,
                                 area_weight=0, correct_aspect=True, scale_to_bounds=False)
        bpy.ops.object.mode_set(mode="OBJECT")
    elif uv == "unwrap":
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=0)
        bpy.ops.object.mode_set(mode="OBJECT")
    assert len(obj.data.uv_layers) == 1, (obj.name, "Part must have one UV map")
    obj.data.uv_layers.active.name = "ToyUV"
    piece = obj.data.attributes.new("toy_piece", "INT", "FACE")
    for value in piece.data:
        value.value = len(PARTS)
    PARTS.append(obj)
    return obj


def bevel(obj, width, segments=1):
    mod = obj.modifiers.new("Soft molded corners", "BEVEL")
    mod.width, mod.segments = width, segments
    apply(obj, mod)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-4)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()


def box(name, dimensions, location, mat, radius=.12, segments=1, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if radius:
        bevel(obj, radius, segments)
    obj.rotation_euler = rotation
    return finish(obj, mat, weighted=True)


def ball(name, center, radius, mat, segments=10, rings=5, scale=(1, 1, 1), budget=None, front_axis=False):
    if budget:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=4, radius=radius, location=center)
    else:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings,
                                           radius=radius, location=center)
    obj = bpy.context.object
    obj.name = name
    if budget:
        obj.data.calc_loop_triangles()
        mod = obj.modifiers.new("Evenly distributed sphere budget", "DECIMATE")
        mod.ratio = budget / len(obj.data.loop_triangles)
        mod.use_collapse_triangulate = True
        apply(obj, mod)
        for vertex in obj.data.vertices:
            vertex.co = vertex.co.normalized() * radius
        while obj.data.uv_layers:
            obj.data.uv_layers.remove(obj.data.uv_layers[0])
        uv = obj.data.uv_layers.new(name="SphereUV")
        for face in obj.data.polygons:
            coords = []
            for index in face.vertices:
                position = obj.data.vertices[index].co / radius
                coords.append([math.atan2(position.y, position.x) / (2 * math.pi) + .5,
                               math.asin(max(-1, min(1, position.z))) / math.pi + .5])
            if max(c[0] for c in coords) - min(c[0] for c in coords) > .5:
                for coordinate in coords:
                    if coordinate[0] < .5:
                        coordinate[0] += 1
            # A decimated triangle can span a pole without a vertex on it.
            # A spherical projection would fold that triangle over its
            # neighbors. Give that tiny cap its own planar UV island.
            if max(c[0] for c in coords) - min(c[0] for c in coords) > .5:
                coords = [[obj.data.vertices[index].co.x / radius + 3,
                           obj.data.vertices[index].co.y / radius + 3]
                          for index in face.vertices]
            for index, coordinate in zip(face.loop_indices, coords):
                uv.data[index].uv = coordinate
        edge_uv = {}
        seam_edges = set()
        for face in obj.data.polygons:
            loops = list(face.loop_indices)
            for a, b in zip(loops, loops[1:] + loops[:1]):
                va, vb = obj.data.loops[a].vertex_index, obj.data.loops[b].vertex_index
                ua, ub = tuple(uv.data[a].uv), tuple(uv.data[b].uv)
                key = tuple(sorted((va, vb)))
                coords = (ua, ub) if va < vb else (ub, ua)
                if key in edge_uv and edge_uv[key] != coords:
                    seam_edges.add(key)
                edge_uv[key] = coords
        for edge in obj.data.edges:
            edge.use_seam = tuple(sorted(edge.vertices)) in seam_edges
    obj.scale = scale
    if front_axis:
        obj.rotation_euler.x = math.pi / 2
    # Spherical UVs have a meridian seam. Packing separates the seam islands.
    obj = finish(obj, mat, uv="unwrap" if budget else "keep")
    # Analytic sphere normals keep the low-poly interior shading spherical.
    normal_scale = (scale[0], scale[2], scale[1]) if front_axis else scale
    normals = [Vector([v.co[i] / (normal_scale[i] * normal_scale[i]) for i in range(3)]).normalized()
               for v in obj.data.vertices]
    obj.data.normals_split_custom_set_from_vertices(normals)
    return obj


def mesh(name, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return obj


def lathe(name, profile, mat, sectors=12, center=(0, 0, 0), axis="Z", closed=False):
    """Profile is (radius, axial position). Close ring profiles for raised bands."""
    vertices = []
    for radius, position in profile:
        for j in range(sectors):
            angle = 2 * math.pi * j / sectors
            point = (radius * math.cos(angle), radius * math.sin(angle), position)
            if axis == "X":
                point = (point[2], point[0], point[1])
            vertices.append(tuple(point[i] + center[i] for i in range(3)))
    faces = []
    transitions = len(profile) if closed else len(profile) - 1
    for ring in range(transitions):
        next_ring = (ring + 1) % len(profile)
        for j in range(sectors):
            k = (j + 1) % sectors
            faces.append((ring * sectors + j, ring * sectors + k,
                          next_ring * sectors + k, next_ring * sectors + j))
    if not closed:
        faces += [tuple(reversed(range(sectors))),
                  tuple((len(profile) - 1) * sectors + j for j in range(sectors))]
    obj = mesh(name, vertices, faces)
    # Seam down the back and around end caps. ABF gives cone sectors and grain
    # an undistorted unwrap instead of stretching a cone into a rectangle.
    for edge in obj.data.edges:
        a, b = edge.vertices
        if a % sectors == b % sectors == 0 or (a // sectors == b // sectors and
                                               a // sectors in (0, len(profile) - 1)):
            edge.use_seam = True
    result = finish(obj, mat, uv="unwrap")
    if not closed:
        result.data.polygons[-1].use_smooth = False
        result.data.polygons[-2].use_smooth = False
    normals = []
    for face in result.data.polygons:
        for loop_index in face.loop_indices:
            index = result.data.loops[loop_index].vertex_index
            ring, sector = divmod(index, sectors)
            if not closed and face.index >= len(result.data.polygons) - 2:
                normals.append(face.normal)
                continue
            neighbors = []
            if ring or closed:
                previous = profile[(ring - 1) % len(profile)]
                neighbors.append(Vector((profile[ring][1] - previous[1],
                                         previous[0] - profile[ring][0])).normalized())
            if ring < len(profile) - 1 or closed:
                following = profile[(ring + 1) % len(profile)]
                neighbors.append(Vector((following[1] - profile[ring][1],
                                         profile[ring][0] - following[0])).normalized())
            n = sum(neighbors, Vector((0, 0))).normalized()
            angle = 2 * math.pi * sector / sectors
            normal = Vector((n.x * math.cos(angle), n.x * math.sin(angle), n.y))
            if name.startswith("Rounded cone tier") and ring == len(profile) - 1:
                normal = Vector((0, 0, 1))
            normals.append(Vector((normal.z, normal.x, normal.y)) if axis == "X" else normal)
    result.data.normals_split_custom_set(normals)
    return result


def tapered_branch(name, start, end, radii, mat):
    delta = Vector(end) - Vector(start)
    obj = lathe(name, [(radii[0], 0), (radii[1], delta.length)], mat, sectors=6)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    obj.location = start
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def lollipop():
    lathe("Short tapered trunk", [(2.5, 0), (1.8, 8.2)], timber(), sectors=16)
    ball("Round green canopy", (0, 0, 16.2), 9.8, green(), budget=528)
    lathe("Raised equatorial painted band",
          [(9.48, 15.35), (10.45, 15.65), (10.45, 17.25),
           (9.48, 17.55)], green(), sectors=24, closed=True)


def canopy_ball(name, center, radius, mat, ring_counts=(12, 36, 12)):
    # Dense equator for the visible outline, smaller hidden polar rings.
    profile = [(0, -1, 1), (math.sqrt(.5), -math.sqrt(.5), ring_counts[0]),
               (1, 0, ring_counts[1]), (math.sqrt(.5), math.sqrt(.5), ring_counts[2]), (0, 1, 1)]
    vertices, rings, faces = [], [], []
    for r, z, count in profile:
        rings.append(list(range(len(vertices), len(vertices) + count)))
        vertices += [(radius * r * math.cos(math.tau * j / count),
                      radius * r * math.sin(math.tau * j / count), radius * z) for j in range(count)]
    for low, high in zip(rings, rings[1:]):
        n, m = len(low), len(high)
        if n == 1:
            faces += [(low[0], high[(j + 1) % m], high[j]) for j in range(m)]
        elif m == 1:
            faces += [(low[j], low[(j + 1) % n], high[0]) for j in range(n)]
        else:
            j = k = 0
            while j < n or k < m:
                first, second = (j + 1) / n, (k + 1) / m
                if abs(first - second) < 1e-9:
                    faces.append((low[j % n], low[(j + 1) % n], high[(k + 1) % m], high[k % m]))
                    j += 1
                    k += 1
                elif first < second:
                    faces.append((low[j % n], low[(j + 1) % n], high[k % m]))
                    j += 1
                else:
                    faces.append((low[j % n], high[(k + 1) % m], high[k % m]))
                    k += 1
    obj = mesh(name, vertices, faces)
    obj.data.uv_layers.new(name="SphereUV")
    for edge in obj.data.edges:
        a, b = (obj.data.vertices[i].co for i in edge.vertices)
        edge.use_seam = abs(a.y) < 1e-5 and abs(b.y) < 1e-5 and a.x >= 0 and b.x >= 0
    obj.rotation_euler.x = math.pi / 2
    obj.location = center
    finish(obj, mat, uv="unwrap")
    obj.data.normals_split_custom_set_from_vertices([v.co.normalized() for v in obj.data.vertices])
    return obj


def bushy():
    wood = material("Dark brown tree trunk", (135, 76, 35), wood=True, roughness=.36)
    lathe("Flared tree trunk", [(3, 0), (2.35, 2.2), (1.85, 5.5), (2.55, 8.9)], wood, sectors=14)
    tapered_branch("Left fork", (0, 0, 6.6), (-3.8, .2, 10), (1.3, .9), wood)
    tapered_branch("Right fork", (0, 0, 6.6), (3.8, .2, 10), (1.3, .9), wood)
    tapered_branch("Back fork", (0, .3, 7), (0, 2.4, 11), (1.15, .75), wood)
    clusters = [
        ((0, .2, 22), 4, 0, 5),
        ((-4.2, 1, 20), 3.6, 1, 4), ((4.8, 1.2, 20.1), 3.5, 2, 4),
        ((-5, -2, 17.9), 3, 0, 4), ((5, -2.1, 17.8), 3.2, 1, 4),
        ((0, -3.3, 16.4), 3.6, 0, 5),
        ((-7.2, .7, 14.7), 2.75, 1, 4), ((7, 1.1, 15.4), 2.8, 2, 4),
        ((-4.8, -1.8, 11.7), 4.1, 0, 4), ((5, -1.4, 12.2), 4.1, 1, 4),
        ((.1, -3.3, 10.5), 2.6, 1, 4), ((0, 3, 15.4), 4.5, 2, 4),
    ]
    for i, (center, radius, tone, rings) in enumerate(clusters):
        if i == 11:
            continue
        canopy_ball("Canopy ball " + str(i + 1), center, radius, green(tone), (18, 24, 18))


def cone_tier(name, radius, bottom, top, mat, rounded_tip=False):
    """Spend vertices on the rounded lip, with a shared tip instead of tiny tip rings."""
    profile = [(radius * .90, bottom, 26), (radius, bottom + .32, 36),
               (radius * .965, bottom + .9, 36)]
    if rounded_tip:
        profile.append((.38, top - .28, 36))
    profile.append((0, top, 1))
    vertices, rings, normals, faces = [], [], [], []
    for i, (r, z, count) in enumerate(profile):
        ids = []
        neighbors = []
        if i:
            pr, pz, _ = profile[i - 1]
            neighbors.append(Vector((z - pz, pr - r)).normalized())
        if i < len(profile) - 1:
            nr, nz, _ = profile[i + 1]
            neighbors.append(Vector((nz - z, r - nr)).normalized())
        n = sum(neighbors, Vector((0, 0))).normalized()
        for j in range(count):
            t = math.tau * j / count
            ids.append(len(vertices))
            vertices.append((r * math.cos(t), r * math.sin(t), z))
            normals.append(Vector((n.x * math.cos(t), n.x * math.sin(t), n.y)) if count > 1 else Vector((0, 0, 1)))
        rings.append(ids)
    for low, high in zip(rings, rings[1:]):
        n, m = len(low), len(high)
        if m == 1:
            faces += [(low[j], low[(j + 1) % n], high[0]) for j in range(n)]
            continue
        j = k = 0
        while j < n or k < m:
            first, second = (j + 1) / n, (k + 1) / m
            if abs(first - second) < 1e-9:
                faces.append((low[j % n], low[(j + 1) % n], high[(k + 1) % m], high[k % m]))
                j += 1
                k += 1
            elif first < second:
                faces.append((low[j % n], low[(j + 1) % n], high[k % m]))
                j += 1
            else:
                faces.append((low[j % n], high[(k + 1) % m], high[k % m]))
                k += 1
    faces.append(tuple(reversed(rings[0])))
    obj = mesh(name, vertices, faces)
    for edge in obj.data.edges:
        a, b = edge.vertices
        va, vb = obj.data.vertices[a].co, obj.data.vertices[b].co
        edge.use_seam = ((abs(va.y) < 1e-6 and abs(vb.y) < 1e-6 and va.x >= 0 and vb.x >= 0) or
                         a in rings[0] and b in rings[0])
    obj = finish(obj, mat, uv="unwrap")
    obj.data.polygons[-1].use_smooth = False
    corner_normals = []
    for face in obj.data.polygons:
        angular = sum((normals[i] for i in face.vertices if i not in rings[-1]), Vector())
        angular.normalize()
        for loop in face.loop_indices:
            vertex = obj.data.loops[loop].vertex_index
            if face.index == len(faces) - 1:
                normal = Vector((0, 0, -1))
            elif vertex in rings[-1] and len(rings[-1]) == 1:
                normal = angular
            else:
                normal = normals[vertex]
            corner_normals.append(normal)
    obj.data.normals_split_custom_set(corner_normals)


def pine():
    lathe("Short pine trunk", [(2.2, 0), (1.9, 5.2)], timber(), sectors=12)
    for i, (radius, bottom, top) in enumerate([(9, 4.1, 17.1), (7.1, 12.2, 23.2), (5.3, 19.45, 30)]):
        mat = material("Pine tier " + str(i), [(61, 119, 43), (79, 137, 48), (98, 154, 57)][i], bevel=.07)
        cone_tier("Rounded cone tier " + str(i + 1), radius, bottom, top, mat, i == 2)
        # A cone has a circular normal field all the way to its tip. Bake that
        # field per texel instead of interpolating a fan of apex normals.
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        coords = next(n for n in nodes if n.type == "TEX_COORD")
        xyz = nodes.new("ShaderNodeSeparateXYZ")
        links.new(coords.outputs["Object"], xyz.inputs[0])
        radial = nodes.new("ShaderNodeCombineXYZ")
        links.new(xyz.outputs["X"], radial.inputs["X"])
        links.new(xyz.outputs["Y"], radial.inputs["Y"])
        normalized = nodes.new("ShaderNodeVectorMath")
        normalized.operation = "NORMALIZE"
        links.new(radial.outputs[0], normalized.inputs[0])
        slope = Vector((top - bottom - 1.18, radius * .965 - (.38 if i == 2 else 0))).normalized()
        scaled = nodes.new("ShaderNodeVectorMath")
        scaled.operation = "SCALE"
        scaled.inputs[3].default_value = slope.x
        links.new(normalized.outputs[0], scaled.inputs[0])
        raised = nodes.new("ShaderNodeVectorMath")
        raised.operation = "ADD"
        raised.inputs[1].default_value = (0, 0, slope.y)
        links.new(scaled.outputs[0], raised.inputs[0])
        world = nodes.new("ShaderNodeVectorTransform")
        world.vector_type, world.convert_from, world.convert_to = "NORMAL", "OBJECT", "WORLD"
        links.new(raised.outputs[0], world.inputs[0])
        lower = nodes.new("ShaderNodeMath")
        lower.operation = "GREATER_THAN"
        lower.inputs[1].default_value = bottom + .95
        links.new(xyz.outputs["Z"], lower.inputs[0])
        upper = nodes.new("ShaderNodeMath")
        upper.operation = "LESS_THAN"
        upper.inputs[1].default_value = top - .35
        links.new(xyz.outputs["Z"], upper.inputs[0])
        mask = nodes.new("ShaderNodeMath")
        mask.operation = "MULTIPLY"
        links.new(lower.outputs[0], mask.inputs[0])
        links.new(upper.outputs[0], mask.inputs[1])
        bump = next(n for n in nodes if n.type == "BUMP")
        original = bump.inputs["Normal"].links[0].from_socket
        mix = nodes.new("ShaderNodeMixRGB")
        links.new(mask.outputs[0], mix.inputs[0])
        links.new(original, mix.inputs[1])
        links.new(world.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], bump.inputs["Normal"])


def extruded_profile(name, profile, x0, x1, mat, radius=.1, segments=1):
    vertices = [(x, y, z) for x in (x0, x1) for y, z in profile]
    count = len(profile)
    faces = [tuple(reversed(range(count))), tuple(range(count, 2 * count))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count)
              for i in range(count)]
    obj = mesh(name, vertices, faces)
    if radius:
        bevel(obj, radius, segments)
    return finish(obj, mat, weighted=True)


def bench():
    yellow = material("Golden yellow painted slats", (255, 192, 36), bevel=.04)
    blue = material("Blue plastic side frames", (39, 125, 181), bevel=.04)
    frame = [(-1.94, 0), (-1.88, .64), (-1.67, 1.25), (-1.37, 1.71),
             (-.92, 2.01), (.62, 2.01), (1.0, 2.36), (1.18, 3.2),
             (1.29, 4.19), (1.4, 4.58), (1.7, 4.73), (2.02, 4.57),
             (2.13, 4.18), (1.99, 2.54), (1.89, 1.18), (2.08, 0),
             (1.36, 0), (1.14, 1.17), (.72, 1.55), (-.89, 1.55),
             (-1.13, 1.24), (-1.25, .62), (-1.24, 0)]
    for x in (-3.95, 3.95):
        extruded_profile("Curved blue side frame", frame, x - .39, x + .39, blue, .09)
    for y in (-1.13, .65):
        box("Yellow seat slat", (10, 1.65, .57), (0, y, 2.06), yellow, .21, 2)
    for z in (3.02, 4.04):
        box("Yellow back slat", (9.65, .5, .81), (0, .95 + (z - 3.02) * .08, z),
            yellow, .22, 2, rotation=(math.radians(-5), 0, 0))


def waving_flag(mat):
    columns, rows = 10, 3
    vertices = []
    top = [28.5 - .65 * math.sin(i / columns * math.pi * 2) - .3 * i / columns
           for i in range(columns + 1)]
    bottom = [z - 7 for z in top]
    for side in (-1, 1):
        for row in range(rows + 1):
            t = row / rows
            for col in range(columns + 1):
                u = col / columns
                # Concave fly edge is an actual waving closed slab, no open edges.
                x = .54 + u * 11 - 1.1 * math.sin(math.pi * t) ** 2 * u ** 4
                y = 1.05 * math.sin(u * math.pi * 2 - .1) + side * .045
                z = (1 - t) * top[col] + t * bottom[col]
                vertices.append((x, y, z))
    n = (columns + 1) * (rows + 1)
    faces = []
    for side in range(2):
        for row in range(rows):
            for col in range(columns):
                a = side * n + row * (columns + 1) + col
                face = (a, a + 1, a + columns + 2, a + columns + 1)
                faces.append(face if side else tuple(reversed(face)))
    perimeter = list(range(columns + 1))
    perimeter += [row * (columns + 1) + columns for row in range(1, rows + 1)]
    perimeter += [rows * (columns + 1) + col for col in reversed(range(columns))]
    perimeter += [row * (columns + 1) for row in reversed(range(1, rows))]
    for a, b in zip(perimeter, perimeter[1:] + perimeter[:1]):
        faces.append((a, b, b + n, a + n))
    obj = finish(mesh("Red waving flag", vertices, faces), mat)
    assert abs(max(v.co.x for v in obj.data.vertices) - min(v.co.x for v in obj.data.vertices) - 11) < .01
    assert max(v.co.z for v in obj.data.vertices) - min(v.co.z for v in obj.data.vertices) <= 8.5
    return obj


def flagpole():
    wood = timber(pale=True)
    base = material("Honey wood flag stand", (212, 159, 91), wood=True, roughness=.36)
    lathe("Round stepped base lower", [(2.85, 0), (3.1, .24), (3.1, 1.22), (2.85, 1.5)],
          base, sectors=20)
    lathe("Round stepped base upper", [(1.6, 1.42), (1.75, 1.63), (1.58, 2.65)],
          base, sectors=16)
    lathe("Pale wooden pole", [(.9, 2.3), (.9, 30.75)], wood, sectors=12)
    canopy_ball("Wood ball finial", (0, 0, 30.5), 1.5, base)
    waving_flag(material("Red plastic flag", (228, 40, 29), bevel=.025))


def pencil_paper_material():
    """Bake a slightly uneven crayon outline on both sides of the paper."""
    mat = material("Pencil pennant cardstock", (250, 239, 208), roughness=.84, bevel=.015)
    surface_grain(mat, (12, 12, 12), .14, .018, (.97, 1.025))
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], separate.inputs[0])

    def calculate(operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)):
                    node.inputs[index].default_value = value
                else:
                    links.new(value, node.inputs[index])
        return node.outputs[0]

    # Deliberately asymmetric, like a child tracing a star with a blue crayon.
    points = []
    for index in range(10):
        angle = math.pi / 2 + index * math.pi / 5
        radius = (2.45 if index % 2 == 0 else 1.10) * (1 + .045 * math.sin(index * 2.1))
        points.append((7.25 + radius * math.cos(angle),
                       PENCIL_FLAG_FROM_FOOT[1] + radius * math.sin(angle)))
    nearest = 100.0
    for a, b in zip(points, points[1:] + points[:1]):
        dx, dz = b[0] - a[0], b[1] - a[1]
        x = calculate("SUBTRACT", separate.outputs["X"], a[0])
        z = calculate("SUBTRACT", separate.outputs["Z"], a[1])
        t = calculate("DIVIDE", calculate("ADD", calculate("MULTIPLY", x, dx),
                                          calculate("MULTIPLY", z, dz)), dx * dx + dz * dz)
        t = calculate("MINIMUM", calculate("MAXIMUM", t, 0), 1)
        x = calculate("SUBTRACT", x, calculate("MULTIPLY", t, dx))
        z = calculate("SUBTRACT", z, calculate("MULTIPLY", t, dz))
        distance = calculate("SQRT", calculate("ADD", calculate("MULTIPLY", x, x),
                                               calculate("MULTIPLY", z, z)))
        nearest = calculate("MINIMUM", nearest, distance)
    wax = nodes.new("ShaderNodeTexNoise")
    wax.inputs["Scale"].default_value = 15
    wax.inputs["Detail"].default_value = 2
    links.new(coordinates.outputs["Object"], wax.inputs["Vector"])
    width = calculate("ADD", .16, calculate("MULTIPLY", wax.outputs["Fac"], .11))
    stroke = calculate("LESS_THAN", nearest, width)
    pigment = calculate("MULTIPLY", stroke, calculate("ADD", .62,
                                                      calculate("MULTIPLY", wax.outputs["Fac"], .38)))
    bsdf = nodes.get("Principled BSDF")
    original = bsdf.inputs["Base Color"].links[0].from_socket
    color = nodes.new("ShaderNodeMixRGB")
    color.name = "Blue crayon star"
    links.new(pigment, color.inputs[0])
    links.new(original, color.inputs[1])
    color.inputs[2].default_value = linear((30, 96, 190))
    links.new(color.outputs[0], bsdf.inputs["Base Color"])
    return mat


def pencil_pennant(mat):
    """Closed triangular paper slab with a folded hoist and a gentle wave."""
    width, height, _ = PENCIL_FLAG_SIZE
    center_x, center_z, center_y = PENCIL_FLAG_FROM_FOOT
    columns = (0, .07, .16, .30, .46, .63, .80, 1)
    rows = 4
    vertices = []
    for side in (-1, 1):
        for u in columns:
            for row in range(rows + 1):
                v = row / rows
                x = center_x - width / 2 + width * u
                top = center_z + height / 2 - (height / 2 - .2) * u - .18 * math.sin(math.pi * u)
                bottom = center_z - height / 2 + (height / 2 - .2) * u
                fold = .44 * max(0, 1 - abs(u - .07) / .07)
                y = center_y + .60 * math.sin(u * math.tau) + .18 * u * (v - .5) + fold
                vertices.append((x, y + side * .065, top * (1 - v) + bottom * v))
    n = len(columns) * (rows + 1)
    faces = []
    for side in range(2):
        for col in range(len(columns) - 1):
            for row in range(rows):
                a = side * n + col * (rows + 1) + row
                face = (a, a + rows + 1, a + rows + 2, a + 1)
                faces.append(face if side else tuple(reversed(face)))
    perimeter = [col * (rows + 1) for col in range(len(columns))]
    perimeter += [(len(columns) - 1) * (rows + 1) + row for row in range(1, rows + 1)]
    perimeter += [col * (rows + 1) + rows for col in reversed(range(len(columns) - 1))]
    perimeter += list(reversed(range(1, rows)))
    for a, b in zip(perimeter, perimeter[1:] + perimeter[:1]):
        faces.append((a, b, b + n, a + n))
    obj = finish(mesh("Folded paper star pennant", vertices, faces), mat, smooth=False, uv="strict")
    lo, hi, size = bounds(obj)
    assert abs(size.x - width) < .01 and abs(size.z - height) < .01, "Wrong rooftop flag size"
    assert abs((lo.x + hi.x) / 2 - center_x) < .01, "Wrong rooftop flag horizontal offset"
    assert abs((lo.z + hi.z) / 2 - center_z) < .01, "Wrong rooftop flag height above foot"
    return obj


def pencil_flagpole():
    """A 42-stud rooftop pencil, eraser down, on a chunky four-stud brick."""
    blue = material("Pencil base blue plastic", (42, 116, 193), roughness=.32, bevel=.10)
    pink = material("Pencil pink rubber eraser", (238, 116, 148), roughness=.78, bevel=.08)
    silver = material("Pencil silver ferrule", (184, 194, 205), roughness=.24, bevel=.025)
    silver.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .92
    yellow = material("Pencil yellow lacquer", (255, 193, 28), roughness=.37, bevel=.025)
    wood = material("Pencil sharpened cedar", (222, 174, 111), wood=True, roughness=.68, bevel=.025)
    surface_grain(wood, (7, 7, .35), .12, .025, (.94, 1.06))
    graphite = material("Pencil graphite", (52, 56, 67), roughness=.62, bevel=.015)
    clip = material("Pencil orange chunky clip", (239, 98, 35), roughness=.34, bevel=.055)
    box("Chunky blue four-stud brick base", (8, 6, 2.8), (0, 0, 1.4), blue, .45, 2)
    for x in (-2.6, 2.6):
        for y in (-1.55, 1.55):
            lathe("Blue brick stud", [(.72, 2.72), (.72, 3.25), (.65, 3.34)], blue,
                  sectors=12, center=(x, y, 0))
    lathe("Pink rounded eraser", [(1.60, 2.72), (1.90, 3.02), (1.90, 6.72)], pink, sectors=18)
    lathe("Silver crimped ferrule", [(1.92, 6.40), (2.06, 6.53), (2.06, 6.84),
                                     (1.94, 6.98), (1.94, 7.55), (2.04, 7.67),
                                     (2.04, 7.94), (1.94, 8.08), (1.94, 8.94),
                                     (2.06, 9.08), (2.06, 9.39), (1.88, 9.55)], silver, sectors=18)

    # Use flat face normals, never the lathe helper's rounded cylinder normals.
    def hexagonal(name, rings, mat):
        vertices = [(r * math.cos(i * math.tau / 6), r * math.sin(i * math.tau / 6), z)
                    for r, z in rings for i in range(6)]
        faces = [tuple(reversed(range(6))), tuple(range(6 * (len(rings) - 1), 6 * len(rings)))]
        for ring in range(len(rings) - 1):
            for i in range(6):
                j = (i + 1) % 6
                faces.append((ring * 6 + i, ring * 6 + j, (ring + 1) * 6 + j, (ring + 1) * 6 + i))
        return finish(mesh(name, vertices, faces), mat, smooth=False, uv="strict")

    hexagonal("Six flat yellow pencil facets", [(1.85, 9.32), (1.85, 36.7)], yellow)
    hexagonal("Six sharpened wood facets", [(1.85, 36.7), (.39, 40.75)], wood)
    hexagonal("Dark graphite point", [(.39, 40.73), (.025, 42)], graphite)
    pencil_pennant(pencil_paper_material())
    # The measured hoist starts inside the thicker pencil; its folded margin
    # emerges around the right facet. The jaws grip it beside the cedar tip.
    for y in (-.34, .34):
        box("Orange clip jaw", (2.60, .48, 2.50), (2.02, y, 38.0), clip, .18, 2)
    box("Orange clip hinge", (.85, 1.12, 2.50), (.96, 0, 38.0), clip, .18, 2)
    box("Orange clip lever", (1.05, .50, 1.38), (2.4, -.75, 39.8), clip, .18, 2)
    # A small silver pin makes the clip read as a clamp, without a fragile wire.
    pin = lathe("Silver clip pivot", [(.37, -.65), (.37, .65)], silver, sectors=12)
    pin.rotation_euler.x = math.pi / 2
    pin.location = (2.4, 0, 38.0)
    active(pin)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def panel(name, front, thickness, mat, radius=.055):
    """Closed glass or lamp insert. Front points follow the car's sloping shell."""
    normal = (Vector(front[1]) - Vector(front[0])).cross(Vector(front[2]) - Vector(front[0])).normalized()
    rounded = []
    for index, vertex in enumerate(front):
        if radius <= 0:
            rounded.append(vertex)
            continue
        vertex = Vector(vertex)
        before = Vector(front[index - 1]) - vertex
        after = Vector(front[(index + 1) % len(front)]) - vertex
        distance = min(radius * 2, before.length * .22, after.length * .22)
        first, last = vertex + before.normalized() * distance, vertex + after.normalized() * distance
        for t in (0, .5, 1):
            rounded.append(tuple((1 - t) ** 2 * first + 2 * (1 - t) * t * vertex + t ** 2 * last))
    front = rounded
    vertices = list(front) + [tuple(Vector(v) - normal * thickness) for v in front]
    count = len(front)
    faces = [tuple(range(count)), tuple(reversed(range(count, 2 * count)))]
    faces += [(i, i + count, (i + 1) % count + count, (i + 1) % count) for i in range(count)]
    obj = mesh(name, vertices, faces)
    # Rounded outline is real geometry. The tiny thickness bevel is baked,
    # avoiding the collapsed corners produced by beveling thin glass slabs.
    return finish(obj, mat, weighted=True)


def beam(name, start, end, width, mat, depth=None, radius=.06, segments=1):
    delta = Vector(end) - Vector(start)
    return box(name, (width, depth or width, delta.length), (Vector(start) + Vector(end)) / 2,
               mat, radius, segments, delta.to_track_quat("Z", "Y").to_euler())


def tube(name, points, radius, mat, sides=10):
    """Closed smooth swept tube, with a continuous parallel frame along its path."""
    vertices, faces = [], []
    previous = None
    for i, point in enumerate(points):
        tangent = Vector(points[min(i + 1, len(points) - 1)]) - Vector(points[max(i - 1, 0)])
        tangent.normalize()
        if previous is None:
            reference = Vector((1, 0, 0)) if abs(tangent.x) < .8 else Vector((0, 1, 0))
            normal = tangent.cross(reference).normalized()
        else:
            normal = (previous - tangent * previous.dot(tangent)).normalized()
        previous = normal
        second = tangent.cross(normal).normalized()
        for j in range(sides):
            angle = j * math.tau / sides
            vertices.append(Vector(point) + radius * (normal * math.cos(angle) + second * math.sin(angle)))
    for i in range(len(points) - 1):
        for j in range(sides):
            k = (j + 1) % sides
            faces.append((i * sides + j, i * sides + k, (i + 1) * sides + k, (i + 1) * sides + j))
    faces += [tuple(reversed(range(sides))), tuple((len(points) - 1) * sides + j for j in range(sides))]
    obj = mesh(name, vertices, faces)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % sides == b % sides == 0 or
                         a // sides == b // sides and a // sides in (0, len(points) - 1))
    obj = finish(obj, mat, uv="unwrap")
    obj.data.polygons[-1].use_smooth = obj.data.polygons[-2].use_smooth = False
    return obj


def cut_arches(obj, positions, radius, height, sectors=20):
    for y in positions:
        bpy.ops.mesh.primitive_cylinder_add(vertices=sectors, radius=radius, depth=30,
                                            location=(0, y, height), rotation=(0, math.pi / 2, 0))
        cutter = bpy.context.object
        mod = obj.modifiers.new("Open rounded wheel well", "BOOLEAN")
        mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
        apply(obj, mod)
        bpy.data.objects.remove(cutter, do_unlink=True)
    clean_mesh(obj)


def clean_mesh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-5)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()


def vehicle_wheels(width, positions, radius=1.7, height=1.7, tyre_sectors=24, hub_sectors=20):
    rubber = material("Black molded tyres", (27, 25, 23), roughness=.44, bevel=.035)
    ivory = material("Ivory wheel hubs", (238, 233, 216), bevel=.025)
    for side in (-1, 1):
        for y in positions:
            lathe("Rounded black tyre", [(radius * .88, -.40), (radius, -.22),
                                          (radius, .22), (radius * .88, .40)],
                  rubber, sectors=tyre_sectors, center=(side * (width / 2 - .40), y, height), axis="X")
            lathe("Ivory wheel hub", [(radius * .48, -.07), (radius * .52, .03)], ivory,
                  sectors=hub_sectors, center=(side * (width / 2 - .015), y, height), axis="X")


def rounded_shell(name, dimensions, location, mat, radius=.7, segments=4, arches=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name, obj.dimensions = name, dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(obj, radius, segments)
    if arches:
        cut_arches(obj, *arches)
    return finish(obj, mat, weighted=True)


def cabin_shell(outline, widths, paint):
    count = len(outline)
    vertices = [(side * width, y, z) for side in (-1, 1) for (y, z), width in zip(outline, widths)]
    faces = [tuple(reversed(range(count))), tuple(range(count, 2 * count))]
    crown = {}
    for i in (2, 3, 4, 5):
        crown[i] = len(vertices)
        vertices.append((0, outline[i][0], outline[i][1] + .34))
    for i in range(count):
        j = (i + 1) % count
        if i in (2, 3, 4):
            faces += [(i, j, crown[j], crown[i]), (crown[i], crown[j], j + count, i + count)]
        else:
            faces.append((i, j, j + count, i + count))
    faces += [(2, crown[2], 2 + count), (5, 5 + count, crown[5])]
    obj = mesh("Rounded molded roof and cabin", vertices, faces)
    bevel(obj, .48, 2)
    return finish(obj, paint, weighted=True)


def car_shell(sedan, paint, positions):
    # A continuous loft avoids the thin Boolean shoulder wedges produced by
    # overlapping a beveled box with a separate cabin.
    shape = [(-7.4, 3.75, .84), (-7.1, 4.0, .96), (-6.3, 4.40, 1.0),
             (-4.7, 4.45, 1.0), (-2.65, 4.55, 1.0), (-1.5, 5.6, 1.0),
             (-.35, 6.8, 1.0), (.6, 7.15, 1.0), (2.3, 7.25, 1.0),
             (3.3, 7.0, 1.0), (4.45, 6.0 if not sedan else 4.8, 1.0),
             (5.6, 4.7 if not sedan else 4.0, 1.0),
             (6.8, 3.58, .97), (7.4, 3.27, .85)]
    rings = []
    for y, top, width in shape:
        if sedan and -.35 <= y <= 3.3:
            top -= .10
        shoulder = min(4.0, top - .60)
        roof_width = 2.45 if top > 4.3 else 2.77
        right = [(0, 1.35), (2.72, 1.35), (3.10, 1.55), (3.23, 2.20),
                 (3.23, shoulder), (3.16, shoulder + .16), (3.02, shoulder + .25),
                 ((3.02 + roof_width) / 2, (shoulder + .25 + top - .24) / 2),
                 (roof_width, top - .24), (roof_width * .65, top),
                 (roof_width * .32, top + .09), (0, top + .13)]
        # Very low nose/tail sections must retain a monotonic side contour.
        right[3] = (3.23, min(2.20, shoulder - .12))
        ring = right + [(-x, z) for x, z in reversed(right[1:-1])]
        rings.append([(x * width * 1.10, y, z) for x, z in ring])
    n = len(rings[0])
    vertices = [point for ring in rings for point in ring]
    faces = [(i * n + j, i * n + (j + 1) % n,
              (i + 1) * n + (j + 1) % n, (i + 1) * n + j)
             for i in range(len(rings) - 1) for j in range(n)]
    faces += [tuple(reversed(range(n))), tuple((len(rings) - 1) * n + j for j in range(n))]
    obj = mesh("Continuous rounded car body", vertices, faces)
    clean_mesh(obj)
    # Capture the loft's smooth normals before the wheel wells are opened.
    obj.data.calc_loop_triangles()
    source_points = [v.co.copy() for v in obj.data.vertices]
    source_normals = [v.normal.copy() for v in obj.data.vertices]
    triangles = [tuple(t.vertices) for t in obj.data.loop_triangles]
    from mathutils.bvhtree import BVHTree
    from mathutils.geometry import barycentric_transform
    surface = BVHTree.FromPolygons(source_points, triangles, all_triangles=True)
    cut_arches(obj, positions, 2.0, 1.85, sectors=28)
    finish(obj, paint, uv="strict")
    normals = []
    for face in obj.data.polygons:
        middle = sum((obj.data.vertices[i].co for i in face.vertices), Vector()) / len(face.vertices)
        _, nearest_normal, _, distance = surface.find_nearest(middle)
        exterior = distance < .12 and face.normal.dot(nearest_normal) > .6
        for loop in face.loop_indices:
            p = obj.data.vertices[obj.data.loops[loop].vertex_index].co
            nearest, _, index, _ = surface.find_nearest(p)
            a, b, c = triangles[index]
            normal = barycentric_transform(nearest, source_points[a], source_points[b], source_points[c],
                                           source_normals[a], source_normals[b], source_normals[c]).normalized()
            normals.append(normal if exterior else face.normal)
    obj.data.normals_split_custom_set(normals)
    return obj


def glazing(surface, frame, glass, name, contour, direction):
    """Raised frame (`frame` paint) and a curved dark pane following `surface` (a BVHTree), seen along `direction`."""
    normal = Vector(direction).normalized()
    center = sum((Vector(p) for p in contour), Vector()) / len(contour)
    inner, outer = [], []
    for scale, result in ((1, inner), (1.08, outer)):
        for i, p in enumerate(contour):
            p = center + (Vector(p) - center) * scale
            previous = center + (Vector(contour[i - 1]) - center) * scale
            following = center + (Vector(contour[(i + 1) % len(contour)]) - center) * scale
            first, last = p.lerp(previous, .13), p.lerp(following, .13)
            for t in (0, .5, 1):
                rounded = (1 - t) ** 2 * first + 2 * (1 - t) * t * p + t ** 2 * last
                hit, _, _, _ = surface.ray_cast(rounded + normal * 20, -normal, 40)
                assert hit is not None, (name, "Glazing misses car shell", list(rounded))
                result.append(hit)
    n = len(inner)
    vertices = [p + normal * z for z in (.03, .18) for contour in (outer, inner) for p in contour]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces += [(i, j, j + 2 * n, i + 2 * n),
                  (i + n, i + 3 * n, j + 3 * n, j + n),
                  (i, i + n, j + n, j),
                  (i + 2 * n, j + 2 * n, j + 3 * n, i + 3 * n)]
    finish(mesh(name + " raised paint frame", vertices, faces), frame, uv="strict")
    # Subdivide the glazing over the convex shell. A single flat polygon
    # let the raised centre of the car cut through the windscreen.
    middle = []
    for p in inner:
        target = p.lerp(center, .55)
        hit, _, _, _ = surface.ray_cast(target + normal * 20, -normal, 40)
        assert hit is not None, (name, "Glazing centre misses body")
        middle.append(hit)
    hit, _, _, _ = surface.ray_cast(center + normal * 20, -normal, 40)
    assert hit is not None
    points = inner + middle + [hit]
    k = len(points)
    vertices = [p + normal * z for z in (.09, .13) for p in points]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        front = [(i, j, j + n, i + n), (i + n, j + n, 2 * n)]
        faces += front + [tuple(reversed(tuple(v + k for v in face))) for face in front]
        faces.append((i, i + k, j + k, j))
    finish(mesh(name + " curved recessed pane", vertices, faces), glass, uv="strict")


def car_windows(body, paint, sedan):
    from mathutils.bvhtree import BVHTree
    surface = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    glass = material("Car recessed dark glass", (40, 37, 32), roughness=.43, bevel=.015)

    glazing(surface, paint, glass, "Car windscreen", [(-2.45, -2.3, 5.05), (2.45, -2.3, 5.05),
                               (2.30, -.35, 6.7), (-2.30, -.35, 6.7)], (0, -1, .65))
    for side in (-1, 1):
        glazing(surface, paint, glass, "Front side window", [(0, -1.5, 4.75), (0, -.15, 6.60),
                                      (0, 1.60, 6.70), (0, 1.60, 4.75)], (side, 0, 0))
        glazing(surface, paint, glass, "Rear side window", [(0, 2.02, 4.75), (0, 2.02, 6.67),
                                     (0, 3.45, 6.36), (0, 4.05 if not sedan else 3.70, 4.75)], (side, 0, 0))

def paint_regions(mat, color, regions):
    """Bake rounded rectangular painted details directly on the curved shell.

    Each region is (two axes, centre, half-size, corner radius, facing axis,
    minimum coordinate). Absolute facing coordinates cover both side walls.
    """
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(n for n in nodes if n.type == "TEX_COORD")
    scale = nodes.get("Decal scale")
    if scale is None:
        scale = nodes.new("ShaderNodeVectorMath")
        scale.name, scale.operation = "Decal scale", "MULTIPLY"
        scale.inputs[1].default_value = (1, 1, 1)
        links.new(coordinates.outputs["Object"], scale.inputs[0])
        origin = nodes.new("ShaderNodeVectorMath")
        origin.name, origin.operation = "Decal origin", "ADD"
        links.new(scale.outputs[0], origin.inputs[0])
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nodes["Decal origin"].outputs[0], separate.inputs[0])

    def math_node(operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (float, int)):
                    node.inputs[index].default_value = value
                else:
                    links.new(value, node.inputs[index])
        return node.outputs[0]

    mask = 0.0
    for axes, center, half, radius, facing, minimum in regions:
        distances = []
        for axis, middle, extent in zip(axes, center, half):
            q = math_node("SUBTRACT", separate.outputs[axis], middle)
            q = math_node("ABSOLUTE", q)
            q = math_node("MAXIMUM", math_node("SUBTRACT", q, extent - radius), 0)
            distances.append(math_node("MULTIPLY", q, q))
        ramp = nodes.new("ShaderNodeMapRange")
        ramp.clamp = True
        feather = radius * min(.05, radius * .2)
        ramp.inputs["From Min"].default_value = radius * radius - feather
        ramp.inputs["From Max"].default_value = radius * radius + feather
        ramp.inputs["To Min"].default_value = 1
        ramp.inputs["To Max"].default_value = 0
        links.new(math_node("ADD", *distances), ramp.inputs["Value"])
        rounded = ramp.outputs["Result"]
        face = math_node("GREATER_THAN", math_node("ABSOLUTE", separate.outputs[facing]), minimum)
        mask = math_node("MAXIMUM", mask, math_node("MULTIPLY", rounded, face))
    bsdf = nodes.get("Principled BSDF")
    original = bsdf.inputs["Base Color"].links[0].from_socket
    mix = nodes.new("ShaderNodeMixRGB")
    links.new(mask, mix.inputs[0])
    links.new(original, mix.inputs[1])
    mix.inputs[2].default_value = linear(color)
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])


def car(kind="hatchback"):
    sedan = kind != "hatchback"
    taxi = kind == "taxi"
    color = concept_color("car-taxi", (.35, .60)) if taxi else concept_color("car-sedan", (.62, .26)) if sedan else concept_color("car-hatchback", (.35, .60))
    paint = material("Car body paint", color, bevel=.065)
    band = material("Darker lower bumper band", (205, 151, 23) if taxi else
                    (43, 65, 129) if sedan else (167, 37, 28), bevel=.04)
    ivory = material("Ivory round headlights", (247, 237, 206), bevel=.025)
    positions = (-4.65, 4.65)
    body = car_shell(sedan, paint, positions)
    rounded_shell("Continuous lower dark bumper band", (7.20, 15.0, .95), (0, 0, 1.65), band,
                  .35, 3, (positions, 2.0, 1.85))
    car_windows(body, paint, sedan)
    vehicle_wheels(7.6, positions, radius=1.85, height=1.85, tyre_sectors=24, hub_sectors=20)
    for x in (-2.55, 2.55):
        ball("Round ivory headlight", (x, -7.52, 2.77), .46, ivory,
             scale=(1, 1.1, .4), segments=24, rings=3, front_axis=True)
    if taxi:
        box("Yellow roof taxi sign", (2.05, 1.16, .78), (0, 1.25, 7.6), paint, .18, 3)
        paint_regions(paint, (28, 27, 23), [
            (("Y", "Z"), (-.6 + col * .5, 2.59 + row * .5), (.245, .245), .005, "X", 3.13)
            for row in range(2) for col in range(5) if (row + col) % 2 == 0])


def van():
    paint = material("Ivory delivery van", (244, 238, 225), bevel=.06)
    grey = material("Grey van bumpers", (98, 95, 84), bevel=.035)
    glass = material("Dark van glass", (66, 57, 40), roughness=.27, bevel=.03)
    cream = material("Van headlights", (255, 240, 191), bevel=.02)
    positions = (-4.8, 5.05)
    rounded_shell("Rounded delivery body", (6.9, 15.5, 3.3), (0, 0, 2.95), paint,
                  .8, 4, (positions, 1.87, 1.72))
    outline = [(-5.25, 3.52), (-4.66, 4.51), (-2.24, 7.45), (-1.37, 7.88),
               (6.03, 7.88), (7.22, 7.33), (7.5, 3.5)]
    cabin_shell(outline, [3.25, 3.2, 3.0, 2.98, 2.98, 3.1, 3.27], paint)
    panel("Van windscreen", [(-2.84, -4.77, 4.64), (2.84, -4.77, 4.64),
                              (2.62, -2.53, 7.34), (-2.62, -2.53, 7.34)], .08, glass, .15)
    for side in (-1, 1):
        front = [(side * 3.18, -4.03, 4.51), (side * 3.0, -1.87, 7.21),
                 (side * 3.0, -.19, 7.19), (side * 3.18, -.19, 4.55)]
        if side < 0:
            front.reverse()
        panel("Driver side glass", front, .08, glass, .14)
    vehicle_wheels(7.5, positions)
    for y in (-7.68, 7.61):
        box("Grey delivery bumper", (6.68, .58, .72), (0, y, 1.76), grey, .22, 2)
    for x in (-2.33, 2.33):
        ball("Van round headlight", (x, -7.71, 2.7), .46, cream,
             scale=(1, 1, .4), segments=24, rings=4, front_axis=True)
    red = material("Van rear red lamps", (208, 38, 27))
    for x in (-3.25, 3.25):
        box("Rear lamp", (.38, .16, .93), (x, 7.72, 3.1), red, .09, 2)


def fire_truck():
    red = material("Fire engine red", (219, 34, 27), bevel=.055)
    dark = material("Fire engine bumper", (170, 32, 25), bevel=.035)
    grey = material("Grey fire ladders", (225, 219, 204), bevel=.03)
    glass = material("Fire engine warm dark glass", (82, 67, 41), roughness=.25)
    windscreen = material("Fire engine golden windscreen", (171, 143, 85), roughness=.25)
    lamp = material("Cream fire engine lamps", (254, 241, 199))
    positions = (-6.7, 6.9)
    rounded_shell("Fire truck cab with arches", (7.25, 9, 5.7), (0, -5.8, 4.12), red,
                  .55, 3, (positions, 1.98, 1.82))
    rounded_shell("Fire truck equipment body", (7.32, 11.7, 5.9), (0, 4.7, 4.05), red,
                  .4, 2, (positions, 1.98, 1.82))
    panel("Fire truck front windscreen", [(-3.02, -10.35, 4.42), (3.02, -10.35, 4.42),
                                          (2.89, -10.35, 6.66), (-2.89, -10.35, 6.66)], .08, windscreen, .15)
    for side in (-1, 1):
        for y, length in [(-6.72, 2.45), (-4.63, 1.1)]:
            box("Fire truck side glass", (.09, length, 2.12), (side * 3.64, y, 5.51), glass, .06, 1)
        for z in (4.4, 5.82):
            beam("Stowed side ladder rail", (side * 3.72, .25, z), (side * 3.72, 9.78, z), .19, grey, radius=.06)
        for y in np.linspace(.65, 9.3, 7):
            beam("Stowed side ladder rung", (side * 3.75, y, 4.4), (side * 3.75, y, 5.82), .17, grey, radius=0)
    vehicle_wheels(8, positions, 1.8, 1.82)
    box("Front red bumper", (7.6, .65, .65), (0, -10.53, 1.65), dark, .23, 2)
    for x in (-2.62, 2.62):
        ball("Fire truck headlamp", (x, -10.31, 3.02), .49, lamp,
             scale=(1, 1, .45), segments=22, rings=3, front_axis=True)
    for x in (-1.63, 1.63):
        profile = [(2.9, 6.6), (5.55, 6.6)] + [
            (4.225 + 1.325 * math.cos(t), 7.4 + 1.325 * math.sin(t))
            for t in np.linspace(0, math.pi, 13)]
        extruded_profile("Round-topped ladder pivot bracket", profile, x - .24, x + .24,
                         red, radius=0)
    lathe("Ivory pivot axle", [(.42, -1.85), (.42, 1.85)], grey, sectors=12, center=(0, 4.2, 8.0), axis="X")
    for x in (-1.38, 1.38):
        beam("Raised aerial ladder rail", (x, -6.2, 10.05), (x, 5.78, 7.25), .24, grey, radius=.07)
        beam("Aerial ladder upper rail", (x, -6.2, 11.15), (x, 5.78, 8.35), .24, grey, radius=.07)
        for t in np.linspace(0, 1, 5):
            y, z = -6.2 + 11.98 * t, 10.05 - 2.8 * t
            beam("Ladder truss upright", (x, y, z), (x, y, z + 1.1), .15, grey, radius=0)
        for t in np.linspace(0, .75, 4):
            y, z = -6.2 + 11.98 * t, 10.05 - 2.8 * t
            beam("Ladder diagonal brace", (x, y, z), (x, y + 2.995, z + .4), .13, grey, radius=0)
    for t in np.linspace(0, 1, 9):
        y, z = -6.2 + 11.98 * t, 10.05 - 2.8 * t
        beam("Aerial ladder rung", (-1.38, y, z), (1.38, y, z), .19, grey, radius=0)


def bus():
    """Toy single-deck city bus from its concept: red body, cream roof and stripe, dark windows, door on the near
    (+X) side, round cream lamps, dark bumpers."""
    red = material("Toy bus red", (222, 30, 26), bevel=.06)
    cream = material("Toy bus cream roof", (244, 233, 205), bevel=.05)
    glass = material("Toy bus dark glass", (54, 54, 60), roughness=.22, bevel=.03)
    dark = material("Toy bus bumpers", (52, 52, 56), roughness=.4, bevel=.04)
    lamp = material("Toy bus cream lamps", (250, 238, 205), bevel=.02)
    wheels = (-6.3, 8.2)
    rounded_shell("Bus body", (9, 26, 8), (0, 0, 5.6), red, .9, 3, (wheels, 2.3, 2.1))
    rounded_shell("Bus cream roof", (9.1, 26.1, 1.6), (0, 0, 10.2), cream, .75, 3)
    box("Bus roof hatch", (5.2, 9.5, .7), (0, -1.5, 11.2), cream, .3, 2)
    for side in (-1, 1):
        x = side * 4.52
        y0 = -8.4 if side > 0 else -11.9                                  # stops at the door
        box("Bus side stripe", (.12, 12.9 - y0, .85), (x, (12.9 + y0) / 2, 4.9), cream, .05, 1)
        for k in range(5):
            box("Bus side window", (.12, 2.75, 2.9), (x, -2.6 + k * 3.05, 7.65), glass, .3, 2)
    for y in (-11.25, -9.95):                                          # double door on the near side, at the front
        box("Bus door glass", (.12, 1.05, 5.4), (4.52, y, 5.2), glass, .25, 2)
    box("Bus windscreen", (7.7, .12, 3.9), (0, -13.02, 7.3), glass, .5, 2)
    for x in (-3.0, 3.0):
        ball("Bus round headlight", (x, -13.0, 3.5), .62, lamp, scale=(1, 1, .4), segments=24, rings=4, front_axis=True)
    for y in (-13.15, 13.15):
        box("Bus bumper", (9.3, 1.1, 1.5), (0, y, 2.1), dark, .45, 2)
    vehicle_wheels(9, wheels, 2.1, 2.1)


def bus_stop():
    """Toy bus-stop shelter from its concept: cream base slab, yellow frames with pale blue glass, curved red roof,
    blue bench, a yellow pole with a blank round sign (no symbol). Open side to the front (-Y)."""
    cream = material("Bus stop cream slab", (240, 230, 206), roughness=.35, bevel=.06)
    yellow = material("Bus stop yellow frame", (247, 200, 24), bevel=.05)
    glass = material("Bus stop pale blue glass", (150, 200, 225), roughness=.18, bevel=.02)
    red = material("Bus stop red roof", (222, 32, 26), bevel=.06)
    blue = material("Bus stop blue bench", (30, 90, 200), bevel=.05)
    dark = material("Bus stop bench legs", (70, 72, 78), roughness=.4, bevel=.03)
    box("Bus stop base slab", (14, 6.6, .8), (1.6, 0, .4), cream, .35, 3)
    x0, x1, back = -3.6, 7.2, 2.3                                   # shelter: side frames at x0/x1, back wall at +Y
    for x in (x0, x1):                                              # side frames: rounded yellow loops with glass
        for y in (-2.4, back):
            beam("Bus stop frame post", (x, y, .8), (x, y, 8.4), .9, yellow, radius=.35)
        beam("Bus stop frame rail", (x, -2.4, 8.2), (x, back, 8.2), .9, yellow, radius=.35)
        beam("Bus stop frame rail", (x, -2.4, 1.2), (x, back, 1.2), .9, yellow, radius=.35)
        box("Bus stop side glass", (.15, 4.1, 6.4), (x, (back - 2.4) / 2, 4.7), glass, .1, 1)
    beam("Bus stop back rail", (x0, back, 8.2), (x1, back, 8.2), .9, yellow, radius=.35)
    box("Bus stop back glass", (x1 - x0 - .6, .15, 6.4), ((x0 + x1) / 2, back, 4.7), glass, .1, 1)
    arc = np.linspace(-math.pi / 2, math.pi / 2, 9)
    outer = [(math.sin(t) * 3.6, 8.3 + math.cos(t) * 1.5) for t in arc]
    inner = [(math.sin(t) * 3.2, 8.0 + math.cos(t) * 1.0) for t in arc[::-1]]
    extruded_profile("Bus stop curved roof", outer + inner, x0 - .7, x1 + .7, red, radius=.12)
    box("Bus stop bench seat", (7.8, 2.2, .7), ((x0 + x1) / 2, .9, 3.0), blue, .3, 2)
    box("Bus stop bench back", (7.8, .6, 2.4), ((x0 + x1) / 2, 1.9, 4.4), blue, .25, 2)
    for x in (x0 + 1.4, x1 - 1.4):
        box("Bus stop bench leg", (.9, 1.6, 1.9), (x, .9, 1.7), dark, .15, 1)
    lathe("Bus stop sign foot", [(1.0, .8), (1.0, 1.3), (.5, 1.7)], yellow, sectors=16, center=(-5.6, -1.4, 0))
    beam("Bus stop sign pole", (-5.6, -1.4, 1.5), (-5.6, -1.4, 8), .7, yellow, radius=.25)
    for name, radius, depth, mat in (("Bus stop sign ring", 1.9, .35, yellow), ("Bus stop blank sign", 1.45, .42, cream)):
        sign = lathe(name, [(radius, -depth), (radius, depth)], mat, sectors=24, axis="X")
        sign.rotation_euler.z = math.pi / 2                           # face the front, like the concept
        sign.location = (-5.6, -1.4, 9.2)


def tugboat():
    """Toy tugboat from its concept: round red hull, black bumper ring, cream deck and wheelhouse with dark windows,
    yellow funnel with a dark band, blue mast and winch, dark bollards. Bow to the front (-Y)."""
    red = material("Tugboat red hull", (222, 30, 24), bevel=.06)
    cream = material("Tugboat cream deck", (244, 234, 208), bevel=.06)
    black = material("Tugboat black bumper", (40, 40, 44), roughness=.45, bevel=.05)
    glass = material("Tugboat dark windows", (52, 54, 60), roughness=.22, bevel=.03)
    yellow = material("Tugboat yellow funnel", (247, 200, 24), bevel=.05)
    blue = material("Tugboat blue mast", (30, 100, 210), bevel=.05)
    def deck_outline(scale, z):                                  # a rounded oblong, fuller than an ellipse
        def bulge(v): return math.copysign(abs(v) ** .6, v)
        return [(bulge(math.cos(t)) * 5.6 * scale, bulge(math.sin(t)) * (13.2 if math.sin(t) > 0 else 14.2) * scale, z)
                for t in np.linspace(0, 2 * math.pi, 40, endpoint=False)]
    # hull: a lathe-like loft of rounded rings, narrowing to the keel
    rings = [(.62, 0), (.82, 1.2), (.95, 3.0), (1.0, 5.0)]
    verts, faces = [], []
    for scale, z in rings:
        verts += deck_outline(scale, z)
    n = 40
    for r in range(len(rings) - 1):
        for k in range(n):
            faces.append((r * n + k, r * n + (k + 1) % n, (r + 1) * n + (k + 1) % n, (r + 1) * n + k))
    faces += [tuple(reversed(range(n))), tuple(range((len(rings) - 1) * n, len(rings) * n))]
    hull = mesh("Tugboat round hull", verts, faces)
    bevel(hull, .3, 2)
    finish(hull, red)
    tube("Tugboat bumper ring", [p[:2] + (5.4,) for p in deck_outline(1.0, 0)] + [deck_outline(1.0, 0)[0][:2] + (5.4,)],
         1.0, black, sides=10)
    deck = deck_outline(.93, 4.7) + deck_outline(.93, 5.35)
    n = len(deck) // 2
    deck = mesh("Tugboat cream deck", deck, [tuple(reversed(range(n))), tuple(range(n, 2 * n))] +
                [(k, (k + 1) % n, (k + 1) % n + n, k + n) for k in range(n)])
    finish(deck, cream)
    rounded_shell("Tugboat cabin block", (6.4, 11, 2.6), (0, .8, 6.3), cream, .6, 3)
    rounded_shell("Tugboat wheelhouse", (5.8, 5.6, 3.6), (0, -1.4, 9.4), cream, .7, 3)
    for k, y in enumerate((-3.0, -1.4, .2)):
        box("Tugboat side window", (.12, 1.2, 1.7), (2.92, y - .05, 9.7), glass, .25, 2)
        box("Tugboat side window", (.12, 1.2, 1.7), (-2.92, y - .05, 9.7), glass, .25, 2)
    for x in (-1.5, 1.5):
        box("Tugboat front window", (1.9, .12, 1.7), (x, -4.22, 9.7), glass, .25, 2)
    lathe("Tugboat funnel", [(1.6, 7.5), (1.6, 11.5), (1.65, 13.2), (1.2, 13.3)], yellow, sectors=20, center=(0, 3.4, 0))
    lathe("Tugboat funnel band", [(1.68, 10.6), (1.68, 11.5)], black, sectors=20, center=(0, 3.4, 0))
    beam("Tugboat mast", (0, -1.4, 11.2), (0, -1.4, 15.4), .7, blue, radius=.25)
    beam("Tugboat mast arm", (-1.6, -1.4, 13.9), (1.6, -1.4, 13.9), .6, blue, radius=.2)
    ball("Tugboat mast cap", (0, -1.4, 15.6), .5, blue, segments=12, rings=6)
    lathe("Tugboat winch drum", [(.9, -1.2), (.9, 1.2)], black, sectors=16, center=(0, -7.6, 6.3), axis="X")
    for x in (-1.5, 1.5):
        lathe("Tugboat winch cheek", [(1.25, -.3), (1.25, .3)], blue, sectors=16, center=(x, -7.6, 6.3), axis="X")
    for x, y in ((-3.6, -9.5), (3.6, -9.5), (-3.8, 7.5), (3.8, 7.5), (3.2, 10.5)):
        lathe("Tugboat bollard", [(.6, 5.0), (.6, 6.4), (.45, 6.6)], black, sectors=14, center=(x, y, 0))


def cone():
    """Toy traffic cone from its concept: orange cone with two white bands on a rounded square base."""
    orange = material("Toy cone orange", (246, 108, 22), bevel=.04)
    white = material("Toy cone white bands", (246, 244, 238), bevel=.03)
    box("Cone base", (4.2, 4.2, .7), (0, 0, .35), orange, .35, 3)
    r = lambda z: 1.75 - 1.3 * (z - .7) / 4.5
    lathe("Cone body", [(r(.7), .7), (r(5.0), 5.0), (.3, 5.3)], orange, sectors=24)
    for z0, z1 in ((1.7, 2.5), (3.2, 3.9)):
        lathe("Cone white band", [(r(z0) + .06, z0), (r(z1) + .06, z1)], white, sectors=24)


def barrier():
    """Toy road-works water barrier from its concept: red flared block, two handle humps with holes, end lugs.
    Long along X; the game colours some copies white."""
    red = material("Toy barrier red", (222, 32, 26), bevel=.06)
    hole = material("Toy barrier hole shadow", (120, 16, 12), roughness=.5, bevel=.02)
    extruded_profile("Barrier block", [(-1.6, 0), (1.6, 0), (1.6, .9), (1.0, 1.8), (1.0, 4.4), (-1.0, 4.4),
                                       (-1.0, 1.8), (-1.6, .9)], -4.8, 4.8, red, radius=.3, segments=2)
    for x in (-2.6, 2.6):
        box("Barrier handle hump", (2.8, 2.0, 1.4), (x, 0, 4.75), red, .5, 3)
        for y in (-1.02, 1.02):
            ball("Barrier handle hole", (x, y, 4.85), .5, hole, scale=(1.5, .2, 1), segments=16, rings=6)
    for x in (-5.15, 5.15):
        box("Barrier end lug", (.9, 1.3, 2.6), (x, 0, 2.6), red, .25, 2)


def paper_boat():
    """Folded paper boat from its concept: a V hull of thick white paper open on top, and the tall middle fold."""
    paper = material("Folded white paper", (246, 246, 241), roughness=.5, bevel=.03)
    keel, rim, tip = 4.0, 3.2, 7.0
    v = [(0, -keel, 0), (0, keel, 0), (0, -tip, rim), (0, tip, rim),
         (-2.9, -3.4, rim), (-2.9, 3.4, rim), (2.9, -3.4, rim), (2.9, 3.4, rim)]
    hull = mesh("Paper boat hull", v, [(0, 1, 5, 4), (0, 4, 2), (1, 3, 5), (1, 0, 6, 7), (0, 2, 6), (1, 7, 3)])
    mod = hull.modifiers.new("Thick paper", "SOLIDIFY")
    mod.thickness, mod.offset = .3, 0
    apply(hull, mod)
    finish(hull, paper)
    sail = mesh("Paper boat middle fold", [(-.9, -3.4, 2.4), (.9, -3.4, 2.4), (.9, 3.4, 2.4), (-.9, 3.4, 2.4), (0, 0, 8.0)],
                [(3, 2, 1, 0), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)])
    finish(sail, paper)


def oblong(half_x, half_y, z, scale=1.0, n=40, power=.7):
    """Points round a rounded oblong (fuller than an ellipse) at height z."""
    def bulge(v): return math.copysign(abs(v) ** power, v)
    return [(bulge(math.cos(t)) * half_x * scale, bulge(math.sin(t)) * half_y * scale, z)
            for t in np.linspace(0, 2 * math.pi, n, endpoint=False)]


def loft(name, rings, mat):
    """Closed solid through rings of equal point count (first and last rings capped)."""
    n = len(rings[0])
    verts = [p for ring in rings for p in ring]
    faces = [(r * n + k, r * n + (k + 1) % n, (r + 1) * n + (k + 1) % n, (r + 1) * n + k)
             for r in range(len(rings) - 1) for k in range(n)]
    faces += [tuple(reversed(range(n))), tuple(range((len(rings) - 1) * n, len(rings) * n))]
    return finish(mesh(name, verts, faces), mat)


def rowing_boat():
    """Toy rowing boat from its concept: hollow blue hull, thick cream rim, two cream benches, yellow oars."""
    blue = material("Rowing boat blue hull", (30, 96, 205), bevel=.05)
    cream = material("Rowing boat cream rim", (244, 234, 208), bevel=.05)
    yellow = material("Rowing boat yellow oars", (247, 202, 24), bevel=.04)
    hx, hy = 3.0, 7.0
    loft("Rowing boat hollow hull", [oblong(hx, hy, 0, .55), oblong(hx, hy, 1.0, .86), oblong(hx, hy, 2.7, 1.0),
                                     oblong(hx, hy, 2.7, .86), oblong(hx, hy, 1.3, .76), oblong(hx, hy, .9, .5)], blue)
    rim = oblong(hx, hy, 2.75, .94)
    tube("Rowing boat cream rim", rim + [rim[0]], .4, cream, sides=10)
    for y in (-1.6, 2.4):
        box("Rowing boat bench", (4.6, 1.5, .45), (0, y, 2.1), cream, .2, 2)
    for side in (-1, 1):
        lathe("Rowing boat oarlock", [(.32, 2.9), (.32, 3.5)], cream, sectors=12, center=(side * 2.85, .4, 0))
        beam("Rowing boat oar shaft", (side * 1.4, -2.6, 3.4), (side * 5.6, 3.4, 2.5), .6, yellow, radius=.2)
        beam("Rowing boat oar blade", (side * 5.3, 3.0, 2.55), (side * 6.9, 5.4, 2.25), 1.6, yellow, depth=.4, radius=.18)


def dump_truck():
    """Toy dump truck from its concept: red cab, grey chassis, big yellow tipper bed, six black wheels."""
    red = material("Dump truck red cab", (222, 30, 26), bevel=.06)
    yellow = material("Dump truck yellow bed", (247, 200, 24), bevel=.06)
    grey = material("Dump truck grey chassis", (110, 112, 118), roughness=.4, bevel=.04)
    glass = material("Dump truck dark glass", (52, 54, 60), roughness=.22, bevel=.03)
    lamp = material("Dump truck cream lamps", (250, 238, 205), bevel=.02)
    axles = (-7.0, 2.6, 6.9)
    box("Dump truck chassis", (6.8, 19.6, 1.3), (0, -.2, 2.5), grey, .35, 2)
    rounded_shell("Dump truck cab", (8.4, 6.4, 6.4), (0, -7.4, 5.6), red, .9, 3, ((-7.0,), 2.2, 1.9))
    box("Dump truck windscreen", (6.6, .12, 2.6), (0, -10.62, 7.2), glass, .35, 2)
    for side in (-1, 1):
        box("Dump truck side window", (.12, 2.6, 2.3), (side * 4.22, -8.0, 7.2), glass, .3, 2)
        box("Dump truck rear fender", (1.2, 8.0, .7), (side * 3.9, 4.75, 4.1), red, .3, 2)
    for x in (-2.8, 2.8):
        ball("Dump truck headlight", (x, -10.6, 4.1), .6, lamp, scale=(1, 1, .4), segments=24, rings=4, front_axis=True)
    box("Dump truck bumper", (9.0, 1.1, 1.3), (0, -10.85, 2.4), grey, .4, 2)
    box("Dump truck bed floor", (8.6, 12.4, .9), (0, 3.9, 4.9), yellow, .35, 2)
    for side in (-1, 1):
        box("Dump truck bed side", (.8, 12.4, 3.6), (side * 3.9, 3.9, 7.0), yellow, .3, 2)
        for y in (0.4, 3.2, 6.0, 8.6):
            box("Dump truck bed rib", (.35, .7, 3.2), (side * 4.35, y, 7.0), yellow, .12, 1)
    box("Dump truck bed front", (8.6, .9, 5.2), (0, -2.0, 7.8), yellow, .35, 2)
    box("Dump truck cab guard", (8.6, 2.6, .7), (0, -3.3, 10.05), yellow, .3, 2)
    box("Dump truck tailgate", (8.6, .8, 3.6), (0, 9.7, 7.0), yellow, .3, 2)
    for x in (-4.4, 4.4):
        lathe("Dump truck tailgate pin", [(.55, -.3), (.55, .3)], lamp, sectors=14, center=(x, 9.5, 8.4), axis="X")
    vehicle_wheels(9, axles, 1.9, 1.9)


def digger():
    """Toy excavator from its concept: grey tracks with cream wheels, yellow body on a turntable, red cab,
    two-part yellow arm with cream pins, grey toothed bucket. Arm to the front (-Y), on the left (-X)."""
    yellow = material("Digger yellow body", (247, 200, 24), bevel=.06)
    red = material("Digger red cab", (222, 30, 26), bevel=.06)
    grey = material("Digger grey tracks", (70, 72, 78), roughness=.45, bevel=.04)
    cream = material("Digger cream wheels", (240, 228, 200), bevel=.03)
    glass = material("Digger dark glass", (52, 54, 60), roughness=.22, bevel=.03)
    for side in (-1, 1):
        rounded_shell("Digger track", (2.4, 11.6, 2.8), (side * 3.4, 1.6, 1.4), grey, 1.2, 4)
        for y, r in ((-3.2, 1.0), (-.6, .7), (1.6, .7), (3.8, .7), (6.4, 1.0)):
            lathe("Digger track wheel", [(r, -.15), (r, .15)], cream, sectors=16, center=(side * 4.62, y, 1.4), axis="X")
    lathe("Digger turntable", [(3.0, 2.8), (3.0, 3.6)], grey, sectors=24, center=(0, 1.6, 0))
    rounded_shell("Digger body", (7.4, 8.6, 3.0), (0, 2.4, 5.1), yellow, .8, 3)
    box("Digger engine cover", (3.2, 3.6, .9), (2.0, 4.6, 7.0), grey, .3, 2)
    rounded_shell("Digger cab", (3.9, 4.4, 4.8), (1.6, -.4, 8.9), red, .8, 3)
    box("Digger cab front glass", (3.0, .12, 2.2), (1.6, -2.62, 9.6), glass, .3, 2)
    box("Digger cab side glass", (.12, 2.8, 2.2), (3.57, -.4, 9.6), glass, .3, 2)
    box("Digger cab side glass", (.12, 2.8, 2.2), (-.37, -.4, 9.6), glass, .3, 2)
    ax, shoulder, elbow, wrist = -1.7, (-1.0, 6.4), (-7.4, 13.0), (-11.3, 6.6)
    beam("Digger boom", (ax, *shoulder), (ax, *elbow), 1.6, yellow, radius=.5)
    beam("Digger stick", (ax, *elbow), (ax, *wrist), 1.4, yellow, radius=.45)
    beam("Digger boom ram", (ax, -2.6, 5.6), (ax, -6.0, 11.2), .55, grey, radius=.15)
    for y, z in (shoulder, elbow, wrist):
        lathe("Digger arm pin", [(.6, -1.15), (.6, 1.15)], cream, sectors=14, center=(ax, y, z), axis="X")
    extruded_profile("Digger bucket", [(-10.4, 7.0), (-13.6, 6.4), (-14.2, 3.6), (-12.8, 1.6), (-10.8, 2.4)],
                     ax - 1.5, ax + 1.5, grey, radius=.3, segments=2)
    for k in range(4):
        x = ax - 1.1 + k * .73
        beam("Digger bucket tooth", (x, -12.6, 1.9), (x, -12.0, .9), .45, grey, radius=.12)


LAMP_BULB = (0, 4.0, 30.5), 1.6         # bulb centre (Blender studs, base centre at the origin) and radius


def street_lamp():
    """Toy street lamp: green base and pole hooking over to a green lamp head with a fat warm-yellow bulb. The arm
    reaches to +Y (the toy's back), over the road: lamp spots point their front away from the road. The bulb is
    where the game hangs a real light (Alan 2026-10-16: lamps light up in future dark events); its position is
    saved to light.json."""
    green = material("Street lamp green", (34, 122, 58), bevel=.04)
    bulb = material("Street lamp warm bulb", (255, 226, 140), roughness=.25, bevel=.02)
    lathe("Street lamp base", [(1.5, 0), (1.5, .6), (1.1, .9), (.7, 1.0), (.7, 1.6)], green, sectors=20)
    lathe("Street lamp pole", [(.4, 1.5), (.4, 34.5)], green, sectors=12)
    tube("Street lamp arm", [(0, 2 - 2 * math.cos(t), 34.5 + 2 * math.sin(t)) for t in np.linspace(0, math.pi, 12)], .4, green, sides=10)
    (cx, cy, cz), r = LAMP_BULB
    top = cz + 1.4                                                   # head sits on the bulb, not through it
    lathe("Street lamp head", [(1.95, top + .05), (1.95, top + .9), (1.6, top + 1.5), (.9, top + 2.2), (.45, top + 2.6)], green,
          sectors=20, center=(cx, cy, 0))
    ball("Street lamp bulb", (cx, cy, cz), r, bulb, segments=20, rings=10, scale=(1, 1, .85))
    (OUTPUT / "street-lamp").mkdir(exist_ok=True)
    (OUTPUT / "street-lamp" / "light.json").write_text(json.dumps({"bulb_blender_studs": [cx, cy, cz], "radius": r,
        "note": "Blender coords before export (Z up, front -Y); the toy's real size equals these studs"}, indent=1))


# ---- building-site set (Alan 2026-10-16: the site must look like one; assets/references/construction-site/)
def site_building():
    """Half-built tower: two finished cream block floors with dark windows, a bare red frame for two more with grey
    floor slabs, yellow scaffolding and a ladder on its +X side. 30 square, 45 tall."""
    cream = material("Site building cream blocks", (238, 228, 205), roughness=.38, bevel=.06)
    dark = material("Site building dark window holes", (58, 56, 54), roughness=.5, bevel=.03)
    red = material("Site building red frame", (222, 32, 26), bevel=.05)
    slab = material("Site building grey slabs", (150, 146, 140), roughness=.45, bevel=.04)
    yellow = material("Site scaffolding yellow", (247, 202, 22), bevel=.04)
    half, floor = 15, 10
    for k in range(2):
        z = k * floor
        rounded_shell("Site building block floor", (30, 30, floor - .3), (0, 0, z + floor / 2), cream, .7, 2)
        for w in (-9.5, 0, 9.5):                                     # three window holes on each face
            box("Site building window hole", (5, .3, 4.6), (w, -half - .05, z + 5), dark, .4, 2)
            box("Site building window hole", (5, .3, 4.6), (w, half + .05, z + 5), dark, .4, 2)
            box("Site building window hole", (.3, 5, 4.6), (-half - .05, w, z + 5), dark, .4, 2)
            box("Site building window hole", (.3, 5, 4.6), (half + .05, w, z + 5), dark, .4, 2)
    top, levels = 2 * floor, (2 * floor + 11, 2 * floor + 22)
    for z in (top, levels[0]):
        box("Site building floor slab", (29, 29, .9), (0, 0, z + .45), slab, .3, 2)
    grid = (-13.6, 0, 13.6)
    for x in grid:
        for y in grid:
            beam("Site building red column", (x, y, top), (x, y, levels[1]), 1.9, red, radius=.45)
    for z in levels:
        for c in grid:
            beam("Site building red beam", (-13.6, c, z - .7), (13.6, c, z - .7), 1.5, red, radius=.4)
            beam("Site building red beam", (c, -13.6, z - .7), (c, 13.6, z - .7), 1.5, red, radius=.4)
    xs, ys, height = (16.4, 20.0), (-5.0, 5.0), 34                  # scaffold tower on the +X side
    for x in xs:
        for y in ys:
            beam("Scaffold upright", (x, y, 0), (x, y, height), .7, yellow, radius=.2)
    for z in range(6, height + 1, 7):
        for x in xs:
            beam("Scaffold rail", (x, ys[0], z), (x, ys[1], z), .55, yellow, radius=0)
        for y in ys:
            beam("Scaffold rail", (xs[0], y, z), (xs[1], y, z), .55, yellow, radius=0)
        beam("Scaffold brace", (xs[1], ys[0], z - 7 if z > 6 else 0), (xs[1], ys[1], z), .5, yellow, radius=0)
        if z % 14 == 6:
            box("Scaffold plank deck", (3.4, 10, .45), ((xs[0] + xs[1]) / 2, 0, z + .3), yellow, .15, 1)
    for x in (16.9, 19.5):                                           # ladder up the scaffold front
        beam("Scaffold ladder rail", (x, -5.6, 0), (x, -5.6, height), .4, yellow, radius=0)
    for z in np.arange(1.5, height, 1.8):
        beam("Scaffold ladder rung", (16.9, -5.6, z), (19.5, -5.6, z), .3, yellow, radius=0)


def site_fence():
    """One site hoarding panel: white board in a grey frame on two grey posts with feet. Repeats along the fence."""
    white = material("Site fence white board", (242, 240, 234), roughness=.35, bevel=.04)
    grey = material("Site fence grey frame", (128, 130, 136), roughness=.4, bevel=.04)
    for x in (-4.9, 4.9):
        box("Site fence post", (1.1, 1.1, 6.4), (x, 0, 3.2), grey, .3, 2)
        box("Site fence foot", (1.8, 1.8, .6), (x, 0, .3), grey, .2, 2)
    box("Site fence board", (8.8, .45, 4.8), (0, 0, 3.4), white, .15, 1)
    for z in (.85, 5.95):
        box("Site fence rail", (9.0, .7, .6), (0, 0, z), grey, .2, 1)


def cement_mixer():
    """Toy cement mixer: tilted orange drum on a yellow frame with two black wheels and a push handle."""
    orange = material("Mixer orange drum", (247, 150, 26), bevel=.05)
    inner = material("Mixer drum mouth", (74, 38, 14), roughness=.55, bevel=.03)
    yellow = material("Mixer yellow frame", (247, 202, 22), bevel=.04)
    tyre = material("Mixer black tyres", (32, 32, 34), roughness=.45, bevel=.03)
    tilt = math.radians(55)
    drum = lathe("Mixer drum", [(1.0, -2.3), (1.7, -1.6), (2.1, -.4), (2.1, .5), (1.6, 1.6), (1.2, 2.1)], orange, sectors=24)
    drum.rotation_euler.x, drum.location = tilt, (0, -.4, 4.0)            # mouth up and to the front
    mouth = lathe("Mixer drum mouth ring", [(1.25, -.12), (1.25, .12)], inner, sectors=24)
    mouth.rotation_euler.x, mouth.location = tilt, (0, -.4 - 2.1 * math.sin(tilt), 4.0 + 2.1 * math.cos(tilt))
    for x in (-2.3, 2.3):
        beam("Mixer frame leg", (x, -.4, 4.0), (x, 1.2, 1.4), .6, yellow, radius=.2)
        beam("Mixer frame leg", (x, -.4, 4.0), (x, -2.4, 0), .6, yellow, radius=.2)
        lathe("Mixer frame hub", [(.55, -.3), (.55, .3)], yellow, sectors=14, center=(x, -.4, 4.0), axis="X")
    beam("Mixer axle", (-2.6, 1.2, 1.2), (2.6, 1.2, 1.2), .45, yellow, radius=0)
    beam("Mixer push handle", (0, 1.2, 1.4), (0, 3.4, 4.6), .5, yellow, radius=.15)
    beam("Mixer handle grip", (-1.0, 3.4, 4.6), (1.0, 3.4, 4.6), .5, yellow, radius=.15)
    for x in (-2.9, 2.9):
        lathe("Mixer tyre", [(1.0, -.35), (1.2, -.2), (1.2, .2), (1.0, .35)], tyre, sectors=20, center=(x, 1.2, 1.2), axis="X")
        lathe("Mixer hub", [(.5, -.4), (.5, .4)], yellow, sectors=14, center=(x, 1.2, 1.2), axis="X")


def material_pile(kind):
    """A heap of sand (smooth) or gravel (lumpy), about 12 across."""
    if kind == "sand":
        sand = material("Site sand", (222, 186, 120), roughness=.7, bevel=.03)
        lathe("Sand heap", [(6.0, 0), (5.6, .5), (4.4, 1.7), (2.7, 3.2), (1.1, 4.3), (.3, 4.6)], sand, sectors=32)
        return
    greys = [material(f"Site gravel {k}", c, roughness=.6, bevel=.02)
             for k, c in enumerate(((150, 150, 152), (118, 118, 122), (176, 174, 170)))]
    lathe("Gravel heap", [(6.0, 0), (5.5, .5), (4.2, 1.5), (2.5, 2.8), (1.0, 3.7), (.3, 3.9)], greys[0], sectors=28)
    rng = np.random.default_rng(5)
    for k in range(70):                                              # loose stones all over the heap
        a, d = rng.uniform(0, 2 * math.pi), rng.uniform(.2, 5.2)
        z = max(.3, 3.9 * (1 - d / 6.0) ** 1.1)
        ball("Gravel stone", (math.cos(a) * d, math.sin(a) * d, z), rng.uniform(.5, .8), greys[k % 3], segments=6, rings=3)


def pallet(wood, dark, width, depth):
    for y in (-depth / 2 + .5, 0, depth / 2 - .5):
        box("Pallet runner", (width, .9, .55), (0, y, .28), dark, .12, 1)
    for x in np.linspace(-width / 2 + .5, width / 2 - .5, 5):
        box("Pallet board", (.85, depth, .25), (x, 0, .68), wood, .08, 1)


def plank_stack():
    wood = material("Pale timber planks", (222, 184, 132), wood=True, roughness=.42, bevel=.04)
    dark = material("Pallet timber", (176, 128, 82), wood=True, roughness=.45, bevel=.03)
    pallet(wood, dark, 8.2, 5.0)
    for layer in range(3):
        for k in range(4):
            box("Timber plank", (8.4, 1.1, .5), (.15 * (layer % 2), -1.75 + k * 1.17, 1.1 + layer * .55), wood, .1, 1)


def pipe_stack():
    grey = material("Grey site pipes", (150, 152, 158), roughness=.35, bevel=.04)
    inside = material("Pipe inside shadow", (70, 72, 78), roughness=.5, bevel=.02)
    r = .8
    for row, count in ((0, 3), (1, 2)):
        for k in range(count):
            y, z = (k - (count - 1) / 2) * 1.62, r + row * 1.4
            lathe("Site pipe", [(r, -4.0), (r, 4.0), (r * .62, 4.0), (r * .62, -4.0)], grey, sectors=18,
                  center=(0, y, z), axis="X", closed=True)
            lathe("Pipe inside", [(r * .6, -3.9), (r * .6, 3.9)], inside, sectors=14, center=(0, y, z), axis="X")


def brick_stack():
    red = material("Toy red bricks", (214, 40, 32), bevel=.04)
    wood = material("Pallet light boards", (222, 184, 132), wood=True, roughness=.42, bevel=.03)
    dark = material("Pallet timber", (176, 128, 82), wood=True, roughness=.45, bevel=.03)
    pallet(wood, dark, 7.4, 5.2)
    for layer in range(3):
        for i in range(4):
            for j in range(4 - layer // 2):
                box("Toy brick", (1.7, 1.15, .8), (-2.6 + i * 1.75, -1.75 + j * 1.18, 1.25 + layer * .82), red, .12, 1)


def site_cabin():
    """Green site cabin (a container office) on skids: ribbed walls, a window and a door at the front (-Y)."""
    green = material("Site cabin green", (52, 140, 60), bevel=.05)
    dark = material("Site cabin window", (52, 54, 60), roughness=.22, bevel=.03)
    grey = material("Site cabin skids", (110, 112, 118), roughness=.4, bevel=.03)
    cream = material("Site cabin door knob", (240, 230, 206), bevel=.02)
    for y in (-3, 3):
        box("Site cabin skid", (14.2, 1.0, .6), (0, y, .3), grey, .2, 1)
    rounded_shell("Site cabin body", (14, 8, 6.4), (0, 0, 3.8), green, .6, 2)
    box("Site cabin roof lip", (14.4, 8.4, .5), (0, 0, 7.15), green, .2, 2)
    for x in np.arange(-6, 6.1, 1.5):
        for y in (-4.08, 4.08):
            box("Site cabin rib", (.4, .25, 5.6), (x, y, 3.8), green, .08, 1)
    box("Site cabin window", (3.2, .3, 2.2), (-3.6, -4.2, 4.6), dark, .25, 2)
    box("Site cabin door", (2.6, .32, 5.0), (3.6, -4.18, 3.4), green, .15, 1)
    ball("Site cabin door knob", (4.5, -4.4, 3.4), .25, cream, segments=10, rings=5)


def site_toilet():
    """Blue portable toilet with a cream roof, door on the front (-Y)."""
    blue = material("Site toilet blue", (30, 90, 205), bevel=.05)
    cream = material("Site toilet cream roof", (240, 230, 206), bevel=.05)
    box("Site toilet base", (4.4, 4.4, .4), (0, 0, .2), blue, .15, 1)
    rounded_shell("Site toilet cabin", (4, 4, 6.2), (0, 0, 3.5), blue, .5, 2)
    rounded_shell("Site toilet roof", (4.6, 4.6, 1.1), (0, 0, 7.05), cream, .5, 3)
    box("Site toilet door", (2.8, .25, 5.2), (0, -2.05, 3.5), blue, .3, 2)
    ball("Site toilet door knob", (.9, -2.25, 3.6), .22, cream, segments=10, rings=5)


def crane():
    """Toy tower crane for the building site (Alan 2026-10-16: at most 80 tall), from its concept: grey cross base on
    cream blocks, yellow lattice mast, red cab under a flat-sided truss jib, red counterweight, hook on a cable.
    Mast at the origin, jib to the front (-Y)."""
    first = len(PARTS)
    yellow = material("Toy crane yellow", (247, 202, 22), bevel=.05)
    red = material("Toy crane red", (222, 32, 26), bevel=.05)
    cream = material("Toy crane cream blocks", (228, 222, 208), roughness=.4, bevel=.06)
    grey = material("Toy crane grey base", (86, 88, 95), roughness=.38, bevel=.04)
    glass = material("Toy crane cab glass", (52, 54, 60), roughness=.22)

    def stud(x, y, z, r=.8, mat=yellow):
        lathe("Crane round stud", [(r, z), (r, z + .45), (r * .8, z + .6)], mat, sectors=16, center=(x, y, 0))

    # base: a grey cross on four cream blocks, a yellow stud on each pad
    box("Crane base plate", (9.5, 9.5, 2.4), (0, 0, 3.4), grey, .5, 2)
    for sx in (-1, 1):
        for sy in (-1, 1):
            beam("Crane base arm", (sx * 3.5, sy * 3.5, 3.6), (sx * 8.2, sy * 8.2, 3.6), 2.6, grey, depth=2, radius=.4)
            box("Crane base pad", (3.6, 3.6, 1.2), (sx * 8.6, sy * 8.6, 4.2), grey, .4, 2)
            box("Crane foot block", (4.6, 4.6, 3.6), (sx * 8.6, sy * 8.6, 1.8), cream, .55, 2)
            stud(sx * 8.6, sy * 8.6, 4.8)
    box("Crane mast collar", (7.4, 7.4, 1.4), (0, 0, 5.3), yellow, .4, 2)
    # mast: four posts, rungs and alternating braces, 6 across
    half, top, step = 2.9, 57.4, 6.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            beam("Crane mast post", (sx * half, sy * half, 5.6), (sx * half, sy * half, top), 1.3, yellow, radius=.35)
    for k, z in enumerate(np.arange(6, top - 1, step)):
        for a, b in (((-1, -1), (1, -1)), ((1, -1), (1, 1)), ((1, 1), (-1, 1)), ((-1, 1), (-1, -1))):
            beam("Crane mast rung", (a[0] * half, a[1] * half, z), (b[0] * half, b[1] * half, z), .9, yellow, radius=0)
            if z + step <= top:
                lo, hi = (a, b) if k % 2 == 0 else (b, a)
                beam("Crane mast brace", (lo[0] * half, lo[1] * half, z), (hi[0] * half, hi[1] * half, z + step), .8, yellow, radius=0)
    # cab on top of the mast, under the jib
    rounded_shell("Crane cab", (7.8, 7.8, 8.6), (0, 0, top + 4.3), red, .9, 3)
    box("Crane cab front window", (4.8, .12, 3.4), (-.6, -3.92, top + 5.2), glass, .3, 2)
    box("Crane cab side window", (.12, 2.6, 3.4), (3.92, -1.6, top + 5.2), glass, .3, 2)
    box("Crane cab side window", (.12, 2.0, 3.4), (3.92, 1.6, top + 5.2), glass, .3, 2)
    # jib: a flat-sided box truss, 44 to the front; short counter-jib to the back
    z0, h, w = top + 8.6, 5, 1.3
    box("Crane jib head", (6, 6, h), (0, 0, z0 + h / 2), yellow, .4, 2)

    def truss(name, y0, y1, height, bay):
        for x in (-w, w):
            for z in (z0 + .45, z0 + height - .45):
                beam(name + " chord", (x, y0, z), (x, y1, z), .9, yellow, radius=.25)
        ys = np.linspace(y0, y1, max(2, round(abs(y1 - y0) / bay)) + 1)
        for k, (a, b) in enumerate(zip(ys, ys[1:])):
            for x in (-w, w):
                za, zb = (z0 + .45, z0 + height - .45) if k % 2 == 0 else (z0 + height - .45, z0 + .45)
                beam(name + " web", (x, a, za), (x, b, zb), .75, yellow, radius=0)
            beam(name + " tie", (-w, b, z0 + .45), (w, b, z0 + .45), .6, yellow, radius=0)
            beam(name + " tie", (-w, b, z0 + height - .45), (w, b, z0 + height - .45), .6, yellow, radius=0)
    front, back = -44, 15
    truss("Crane jib", -3, front + 1.2, h, 4.6)
    box("Crane jib tip", (2 * w + .9, 1.6, h), (0, front + .6, z0 + h / 2), yellow, .6, 3)
    truss("Crane counter-jib", 3, back - 1.5, h - 1, 3.8)
    box("Crane counterweight", (5.6, 3.2, 7.4), (0, back, z0 + 1.8), red, .7, 3)
    # tower head with ties to the jib and the counter-jib
    apex = 80
    beam("Crane tower head post", (0, 0, z0 + h), (0, 0, apex - .6), 2.2, yellow, radius=.5)
    lathe("Crane tower head pin", [(.75, -1.2), (.75, 1.2)], cream, sectors=14, center=(0, 0, apex - 1.6), axis="X")
    beam("Crane jib tie bar", (0, -.6, apex - 1.4), (0, -22, z0 + h - .3), 1.0, yellow, radius=.3)
    beam("Crane counter-jib tie bar", (0, .6, apex - 1.4), (0, back - 1.5, z0 + h - 1.3), 1.0, yellow, radius=.3)
    # trolley, cable and hook block
    trolley, hook_z = -34, 47
    box("Crane trolley", (3.4, 3, 2.2), (0, trolley, z0 - 1.1), cream, .5, 2)
    for y in (trolley - .8, trolley + .8):
        lathe("Crane trolley wheel", [(.6, -1.9), (.6, 1.9)], grey, sectors=12, center=(0, y, z0 - .05), axis="X")
    beam("Crane hoist cable", (0, trolley, z0 - 2.2), (0, trolley, hook_z + 2), .2, grey, radius=0)
    box("Crane hook block", (2.8, 1.8, 3.6), (0, trolley, hook_z + .2), grey, .55, 2)
    lathe("Crane hook block pin", [(.6, -1.05), (.6, 1.05)], cream, sectors=12, center=(0, trolley, hook_z + .6), axis="X")
    arc = [(0, trolley + 1.3 * math.cos(t), hook_z - 3.2 + 1.3 * math.sin(t)) for t in np.linspace(-.3, math.pi * 1.35, 12)]
    tube("Crane hook", [(0, trolley + 1.25, hook_z - 1.5)] + arc[::-1], .42, grey, sides=8)
    # ~150 plain beams: smart projection cuts each into six islands and the padding then eats the atlas.
    # Unfold each one as a single strip instead (both end caps hang off one side).
    for part in PARTS[first:]:
        if len(part.data.vertices) != 8 or len(part.data.polygons) != 6:
            continue
        bm = bmesh.new()
        bm.from_mesh(part.data)
        caps = sorted(bm.faces, key=lambda f: f.calc_area())[:2]
        hinge = next(f for f in bm.faces if f not in caps)
        for edge in bm.edges:
            edge.seam = (any(c in edge.link_faces for c in caps) and hinge not in edge.link_faces) or (
                not any(c in edge.link_faces for c in caps) and hinge not in edge.link_faces)
        long_cuts = [e for e in bm.edges if e.seam and not any(c in e.link_faces for c in caps)]
        for edge in long_cuts[1:]:
            edge.seam = False                                     # one long cut opens the loop of sides
        bm.to_mesh(part.data)
        bm.free()
        active(part)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.unwrap(method="ANGLE_BASED", margin=0)
        bpy.ops.object.mode_set(mode="OBJECT")


# ---- toy monorail (Alan 2026-10-15: a loop with a solid train; pictures in assets/models/toys/monorail/)
# The track top is 125 studs (replan-v4.json monorail.track_top): a 120-tall pillar under a 5-tall beam.
MONORAIL_BEAM = (6, 40, 5)          # one straight beam piece; city-toys-v4 stretches it along each track segment


def monorail_pylon():
    """Round light-grey pillar on a round foot, a yellow T-cap on top that the beam sits in. The beam runs along Y."""
    grey = material("Monorail pillar light grey", (196, 197, 199), roughness=.36, bevel=.05)
    yellow = material("Monorail T-cap yellow", (247, 202, 22), bevel=.05)
    lathe("Monorail pillar foot", [(5.8, 0), (5.8, 1.4), (5.3, 2.2), (4.0, 2.8), (3.2, 3.4)], grey, sectors=28)
    lathe("Monorail pillar", [(3.1, 3.2), (3.1, 112.4)], grey, sectors=20)
    lathe("Monorail T-cap stem", [(3.5, 111.6), (3.5, 115.4), (3.9, 116.4)], yellow, sectors=24)
    box("Monorail T-cap", (8.4, 11.6, 3.8), (0, 0, 118.1), yellow, .7, 3)


def monorail_beam():
    """Plain grey beam with soft edges; its ends are cut square so stretched pieces meet end to end."""
    w, length, h = MONORAIL_BEAM
    box("Monorail beam", (w, length, h), (0, 0, h / 2), material("Monorail beam grey", (128, 130, 136), roughness=.35), .6, 3)


def monorail_car(nose):
    """One toy monorail car from the train picture: glossy cream body with a red stripe, framed dark windows, and a
    dark skirt that straddles the beam (skirt bottom is z 0, the beam top 4.5 above it, a 6.4-wide channel). The nose
    car's front is -Y: a rounded bullet nose with a curved windscreen and two yellow headlights; the train is nose car,
    middle car, nose car turned round. The middle car carries the dark gangway bellows at both ends."""
    from mathutils.bvhtree import BVHTree
    cream = material("Monorail cream body", (244, 236, 214), roughness=.22, bevel=.06)
    dark = material("Monorail dark skirt", (56, 56, 61), roughness=.38, bevel=.05)
    frame = material("Monorail dark window frame", (64, 64, 70), roughness=.3, bevel=.03)
    glass = material("Monorail dark glass", (34, 35, 40), roughness=.12, bevel=.015)
    lamp = material("Monorail yellow headlight", (255, 198, 18), roughness=.22, bevel=.02)
    half = 17 if nose else 15
    end = [(4.9, 5.3, 14.0, .45), (5.3, 5.0, 14.6, .38), (5.5, 4.8, 15.0, .35)]     # rounded square ends
    back = [(half - d, *ring) for d, ring in zip((0, .5, 1.4), end)]
    if nose:                                    # (y, half width, bottom, top, roundness): roof curves down to the nose
        front = [(-17, 3.0, 5.7, 7.9, .7), (-16.85, 3.9, 5.3, 8.9, .62), (-16.5, 4.6, 5.0, 9.9, .55),
                 (-15.9, 5.1, 4.85, 10.9, .48), (-15.0, 5.4, 4.8, 11.9, .42), (-13.8, 5.5, 4.8, 12.9, .38),
                 (-12.2, 5.5, 4.8, 13.8, .36), (-10.2, 5.5, 4.8, 14.5, .35), (-7.8, 5.5, 4.8, 14.9, .35),
                 (-5.6, 5.5, 4.8, 15.0, .35)]
    else:
        front = [(-y, *ring) for y, *ring in back]
    profile = front + back[::-1]

    def bulge(v, power): return math.copysign(abs(v) ** power, v)
    rings = [[(bulge(math.cos(t), p) * hw, y, (zb + zt) / 2 + bulge(math.sin(t), p) * (zt - zb) / 2)
              for t in np.linspace(0, 2 * math.pi, 48, endpoint=False)] for y, hw, zb, zt, p in profile]
    body = loft("Monorail car body", rings, cream)
    paint_regions(cream, (214, 36, 28), [((1, 2), (0, 7.3), (20, 1.1), .3, 2, -1)])   # red stripe all the way round
    surface = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    for side in (-1, 1):
        for y in ((-5.4, .4, 6.2) if nose else (-7.6, -1.9, 3.8, 9.5)):
            glazing(surface, frame, glass, "Monorail side window",
                    [(0, y - 2.0, 9.7), (0, y + 2.0, 9.7), (0, y + 2.0, 12.9), (0, y - 2.0, 12.9)], (side, 0, 0))
    if nose:
        # windscreen: painted on, so it follows the curved nose and wraps round the sides (a frame rim, then glass)
        paint_regions(cream, (64, 64, 70), [((1, 2), (-15.0, 11.0), (2.85, 2.15), 1.1, 2, -1)])
        paint_regions(cream, (34, 35, 40), [((1, 2), (-15.0, 11.0), (2.6, 1.9), .9, 2, -1)])
        for x in (-2.5, 2.5):
            ball("Monorail headlight", (x, -16.9, 6.9), .85, lamp, scale=(1, 1, .45), segments=24, rings=4, front_axis=True)
    # skirt: two side walls and a roof over the beam channel
    length = 31.6 if nose else 28.6
    middle = half - .7 - length / 2
    for x in (-4.2, 4.2):
        box("Monorail skirt side", (2.0, length, 5.8), (x, middle, 2.9), dark, .95, 4)
    box("Monorail skirt roof", (10.4, length, 1.6), (0, middle, 5.0), dark, .7, 3)
    if not nose:
        for y in (-15.6, 15.6):
            box("Monorail gangway bellows", (6, 2.0, 5.0), (0, y, 8.0), dark, .5, 2)


def fountain():
    def math_node(nodes, links, operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((a, b)):
            if value is None:
                continue
            if isinstance(value, (float, int)):
                node.inputs[index].default_value = value
            else:
                links.new(value, node.inputs[index])
        return node.outputs[0]

    def cylindrical(mat):
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        coords = next(n for n in nodes if n.type == "TEX_COORD")
        xyz = nodes.new("ShaderNodeSeparateXYZ")
        links.new(coords.outputs["Object"], xyz.inputs[0])
        xy = nodes.new("ShaderNodeCombineXYZ")
        links.new(xyz.outputs["X"], xy.inputs["X"])
        links.new(xyz.outputs["Y"], xy.inputs["Y"])
        radius = nodes.new("ShaderNodeVectorMath")
        radius.operation = "LENGTH"
        links.new(xy.outputs[0], radius.inputs[0])
        angle = math_node(nodes, links, "ARCTAN2", xyz.outputs["Y"], xyz.outputs["X"])
        return nodes, links, xyz.outputs["Z"], radius.outputs["Value"], angle

    def stone_blocks(label, color, block_count, courses=False):
        mat = material(label, color, roughness=.64, bevel=.10)
        surface_grain(mat, (4.2, 4.2, 4.2), .35, .065, (.70, 1.22))
        nodes, links, z, _, angle = cylindrical(mat)
        calc = lambda op, a, b=None: math_node(nodes, links, op, a, b)
        row = calc("DIVIDE", z, 1.65)
        course = calc("FLOOR", row)
        sector = calc("MULTIPLY", angle, block_count / (2 * math.pi))
        if courses:
            sector = calc("ADD", sector, calc("MULTIPLY", course, .5))
        along = calc("FRACT", sector)
        distance = calc("MINIMUM", along, calc("SUBTRACT", 1, along))
        # Irregular beveled joints remain wide enough to survive distant mipmaps.
        grain = next(n for n in nodes if n.type == "TEX_NOISE")
        distance = calc("SUBTRACT", distance, calc("MULTIPLY", grain.outputs["Fac"], .016))
        gap = nodes.new("ShaderNodeMapRange")
        gap.name = "Rounded chipped grout edges"
        gap.interpolation_type = "SMOOTHSTEP"
        gap.inputs["From Min"].default_value = .010
        gap.inputs["From Max"].default_value = .055
        gap.inputs["To Min"].default_value = 1
        gap.inputs["To Max"].default_value = 0
        links.new(distance, gap.inputs["Value"])
        joint = gap.outputs[0]
        if courses:
            across = calc("FRACT", row)
            across = calc("MINIMUM", across, calc("SUBTRACT", 1, across))
            horizontal = nodes.new("ShaderNodeMapRange")
            horizontal.interpolation_type = "SMOOTHSTEP"
            horizontal.inputs["From Min"].default_value = .022
            horizontal.inputs["From Max"].default_value = .085
            horizontal.inputs["To Min"].default_value = 1
            horizontal.inputs["To Max"].default_value = 0
            links.new(across, horizontal.inputs["Value"])
            joint = calc("MAXIMUM", joint, horizontal.outputs[0])
        block = nodes.new("ShaderNodeCombineXYZ")
        links.new(calc("FLOOR", sector), block.inputs["X"])
        links.new(course, block.inputs["Y"])
        variation = nodes.new("ShaderNodeTexWhiteNoise")
        links.new(block.outputs[0], variation.inputs["Vector"])
        tint = nodes.new("ShaderNodeMapRange")
        tint.inputs["To Min"].default_value = .84
        tint.inputs["To Max"].default_value = 1.12
        links.new(variation.outputs["Value"], tint.inputs["Value"])
        bsdf = nodes.get("Principled BSDF")
        original = bsdf.inputs["Base Color"].links[0].from_socket
        blocks = nodes.new("ShaderNodeMixRGB")
        blocks.blend_type = "MULTIPLY"
        blocks.inputs[0].default_value = 1
        links.new(original, blocks.inputs[1])
        links.new(tint.outputs[0], blocks.inputs[2])
        grout = nodes.new("ShaderNodeMixRGB")
        grout.name = "Visible grey cut stone and grout"
        links.new(joint, grout.inputs[0])
        links.new(blocks.outputs[0], grout.inputs[1])
        grout.inputs[2].default_value = linear((76, 86, 100))
        links.new(grout.outputs[0], bsdf.inputs["Base Color"])
        relief = nodes.new("ShaderNodeBump")
        relief.name = "Recessed grout in normal map"
        relief.inputs["Strength"].default_value = .7
        relief.inputs["Distance"].default_value = .15
        links.new(calc("SUBTRACT", 1, joint), relief.inputs["Height"])
        links.new(bsdf.inputs["Normal"].links[0].from_socket, relief.inputs["Normal"])
        links.new(relief.outputs["Normal"], bsdf.inputs["Normal"])
        return mat

    stone = stone_blocks("Cool grey fountain cut stone", (146, 157, 171), 12, courses=True)
    rim = stone_blocks("Lighter grey fountain rim blocks", (189, 198, 210), 12)
    pedestal = material("Speckled grey stone pedestals", (151, 162, 176), roughness=.64, bevel=.08)
    surface_grain(pedestal, (4.2, 4.2, 4.2), .35, .065, (.70, 1.22))
    water = material("Saturated blue fountain water", (24, 123, 222), roughness=.10, bevel=.035)
    surface_grain(water, (.65, .65, .35), .06, .025, (.98, 1.02))
    nodes, links, z, radius, _ = cylindrical(water)
    calc = lambda op, a, b=None: math_node(nodes, links, op, a, b)
    ripple = calc("SINE", calc("MULTIPLY", radius, 7.5))
    ripple = calc("ADD", calc("MULTIPLY", ripple, .5), .5)
    crest = calc("POWER", ripple, 7)
    # Each tier has its own lighter waterline, slightly inside the stone lip.
    middle = calc("GREATER_THAN", z, 5)
    upper = calc("GREATER_THAN", z, 10)
    pool_radius = calc("SUBTRACT", calc("SUBTRACT", 9.9,
                        calc("MULTIPLY", middle, 3.7)), calc("MULTIPLY", upper, 2.75))
    waterline = nodes.new("ShaderNodeMapRange")
    waterline.interpolation_type = "SMOOTHSTEP"
    waterline.inputs["From Min"].default_value = .06
    waterline.inputs["From Max"].default_value = .55
    waterline.inputs["To Min"].default_value = 1
    waterline.inputs["To Max"].default_value = 0
    links.new(calc("SUBTRACT", pool_radius, radius), waterline.inputs["Value"])
    highlights = calc("MAXIMUM", calc("MULTIPLY", crest, .38), waterline.outputs[0])
    bsdf = nodes.get("Principled BSDF")
    tint = nodes.new("ShaderNodeMixRGB")
    tint.name = "Blue concentric ripples and bright waterline"
    links.new(highlights, tint.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, tint.inputs[1])
    tint.inputs[2].default_value = linear((99, 211, 255))
    links.new(tint.outputs[0], bsdf.inputs["Base Color"])
    relief = nodes.new("ShaderNodeBump")
    relief.name = "Concentric water ripple normal"
    relief.inputs["Strength"].default_value = .45
    relief.inputs["Distance"].default_value = .095
    links.new(calc("ADD", calc("MULTIPLY", ripple, .5),
                   calc("MULTIPLY", waterline.outputs[0], .25)), relief.inputs["Height"])
    links.new(bsdf.inputs["Normal"].links[0].from_socket, relief.inputs["Normal"])
    links.new(relief.outputs["Normal"], bsdf.inputs["Normal"])

    def filled_bowl(name, profile, sectors):
        bowl = lathe(name, profile, stone, sectors=sectors, closed=True)
        bowl.data.materials.append(water)
        bowl.data.materials.append(rim)
        for face in bowl.data.polygons[sectors:4 * sectors]:
            face.material_index = 2
        # The water floor is part of the sealed bowl, so its circular outline
        # receives the same generous segment count as the stone rim.
        start = (len(profile) - 2) * sectors
        for face in bowl.data.polygons[start:start + sectors]:
            face.material_index = 1
        normals = [value.vector.copy() for value in bowl.data.corner_normals]
        for face in bowl.data.polygons[start:start + sectors]:
            for loop in face.loop_indices:
                normals[loop] = Vector((0, 0, 1))
        bowl.data.normals_split_custom_set(normals)
        return bowl
    filled_bowl("Deep round stone basin", [(11.6, 0), (12, 2.8), (11.65, 3.35),
                                           (10.35, 3.35), (9.9, 2.07), (.1, 2.07)], 52)
    lathe("Lower central pedestal", [(3.15, 1.4), (2.8, 6.4)], pedestal, sectors=16)
    filled_bowl("Lower rounded stone bowl", [(6.9, 6.1), (7.8, 7.2), (7.8, 8.1),
                                             (7.25, 8.45), (6.4, 8.35), (6.2, 7.59), (.1, 7.59)], 40)
    lathe("Upper central pedestal", [(2.3, 7.1), (1.95, 11.7)], pedestal, sectors=16)
    filled_bowl("Upper rounded stone bowl", [(4.05, 11.7), (4.6, 12.65), (4.6, 13.25),
                                             (4.15, 13.6), (3.55, 13.45), (3.45, 12.91), (.1, 12.91)], 36)
    lathe("Little bubbling blue water jet", [(.55, 12.8), (.75, 13.1), (.73, 13.65),
                                             (.48, 14.0), (.04, 14.15)], water, sectors=16)


def crop_row():
    soil = material("Rounded brown crop soil", (135, 96, 64), roughness=.78, bevel=.08)
    surface_grain(soil, (4, 4, 4), .25, .04, (.86, 1.08))
    head = material("Crop head paint", (34, 113, 40), roughness=.26, bevel=.09)
    leaf = material("Crop leaf paint", (43, 131, 45), roughness=.28, bevel=.09)
    stalk = material("Crop green stalk", (55, 119, 35), roughness=.3, bevel=.04)
    box("Low rounded soil mound", (20, 5, .65), (0, 0, .325), soil, radius=.32)
    for index, x in enumerate((-8, -4, 0, 4, 8)):
        ball("Chunky vegetable head " + str(index), (x, 0, 2.15), 1.35, head,
             scale=(1, 1, 1.03), budget=32)
        for angle in (30, 150, 270):
            t = math.radians(angle)
            ball("Rounded outer leaf", (x + 1.05 * math.cos(t), 1.05 * math.sin(t), 1.35), 1.0, leaf,
                 scale=(1, .9, 1), budget=12)
        lathe("Little green stalk", [(.22, 3.35), (.14, 4)], stalk, sectors=4, center=(x, 0, 0))


def striped_awning(width, path, colored, white):
    columns, rows = 12, len(path)
    vertices, faces, colors = [], [], []
    for layer in range(2):
        for x in np.linspace(-width / 2, width / 2, columns + 1):
            for y, z in path:
                vertices.append((x, y, z - layer * .27))
    layer_size = (columns + 1) * rows
    scallops = {}
    for layer in range(2):
        for col in range(columns):
            ids = []
            for t in (1 / 3, 2 / 3):
                ids.append(len(vertices))
                x = -width / 2 + width * (col + t) / columns
                vertices.append((x, path[-1][0], path[-1][1] - .70 * math.sin(math.pi * t) - layer * .27))
            scallops[layer, col] = ids
    for layer in range(2):
        for col in range(columns):
            for row in range(rows - 1):
                a = layer * layer_size + col * rows + row
                face = (a, a + rows, a + rows + 1, a + 1)
                if row == rows - 2:
                    first, second = scallops[layer, col]
                    face = (a, a + rows, a + rows + 1, second, first, a + 1)
                faces.append(face if layer else tuple(reversed(face)))
                colors.append(col % 2)
    for col in range(columns):
        for row in (0, rows - 1):
            a, b = col * rows + row, (col + 1) * rows + row
            if row == rows - 1:
                upper = [a] + scallops[0, col] + [b]
                lower = [a + layer_size] + scallops[1, col] + [b + layer_size]
                for i in range(3):
                    faces.append((upper[i], upper[i + 1], lower[i + 1], lower[i]))
                    colors.append(col % 2)
            else:
                faces.append((a, b, b + layer_size, a + layer_size))
                colors.append(col % 2)
    for col in (0, columns):
        for row in range(rows - 1):
            a = col * rows + row
            faces.append((a, a + 1, a + 1 + layer_size, a + layer_size))
            colors.append(col % 2)
    obj = finish(mesh("Curved striped market awning", vertices, faces), colored)
    obj.data.materials.append(white)
    for face, color in zip(obj.data.polygons, colors):
        face.material_index = color
    return obj


def stall():
    gold = material("Stall honey wood", concept_color("stall", (.54, .71)), wood=True, roughness=.36)
    surface_grain(gold, (.14, 7, 7), .22, .055, (.86, 1.08))
    boards = material("Vertical stall back planks", concept_color("stall", (.54, .71)),
                      wood=True, roughness=.36)
    surface_grain(boards, (7, 7, .14), .22, .055, (.84, 1.10))
    red = material("Variant paint", concept_color("stall", (.28, .32)), roughness=.32)
    white = material("Awning ivory stripes", (247, 239, 219), roughness=.39)
    for x in (-9.2, 9.2):
        for y in (-4.8, 4.8):
            height = 12.9 if y < 0 else 15.63
            box("Solid market stall post", (1.65, 1.65, height), (x, y, height / 2), gold, .28, 3)
    box("Rounded wooden counter", (21, 11.7, 1.65), (0, -.2, 5.15), gold, .72, 3)
    # The backing closes the small bevel grooves between the vertical boards.
    box("Closed wooden back wall", (18.4, .5, 15.65), (0, 5.05, 7.825), boards, radius=0)
    for index in range(7):
        box("Vertical back plank " + str(index), (2.4, .9, 15.65),
            ((index - 3) * 2.4, 5.0, 7.825), boards, .065)
    box("Inside toy goods shelf", (10, 2.65, .65), (-1.1, 3.25, 7.05), gold, .25)
    for index, color in enumerate(((226, 49, 35), (243, 144, 25), (88, 162, 45),
                                   (139, 66, 176), (248, 202, 36))):
        paint = material("Shelf fruit paint " + str(index), color, roughness=.26, bevel=.06)
        fruit = ball("Colourful shelf fruit " + str(index), (-4.7 + index * 1.8, 2.7, 8.08),
                     .72, paint, budget=24)
        fruit.location.z += 7.375 - bounds(fruit)[0].z
    # Keep the front and side stripes; the rear is plain wood.
    perimeter = ([(x, -5.55) for x in np.linspace(-10, 10, 12, endpoint=False)] +
                 [(10, y) for y in np.linspace(-5.55, 5.15, 6, endpoint=False)] +
                 [(x, 5.15) for x in np.linspace(10, -10, 12, endpoint=False)] +
                 [(-10, y) for y in np.linspace(5.15, -5.55, 6, endpoint=False)])
    n = len(perimeter)
    vertices = [(x, y, z) for z in (0, 4.4) for x, y in perimeter] + [(0, -.2, 0), (0, -.2, 4.4)]
    faces, colors = [], []
    for i in range(n):
        j = (i + 1) % n
        faces += [(i, j, j + n, i + n), (2 * n, j, i), (2 * n + 1, i + n, j + n)]
        color = 2 if 18 <= i < 30 else i % 2
        colors += [color, color, color]
    skirt = finish(mesh("Continuous striped market counter skirt", vertices, faces), red, smooth=False)
    skirt.data.materials.append(white)
    skirt.data.materials.append(boards)
    for face, color in zip(skirt.data.polygons, colors):
        face.material_index = color
    path = [(6.15, 15.95), (4.5, 15.88), (2.7, 15.7), (.5, 15.25),
            (-1.8, 14.5), (-3.9, 13.8), (-5.6, 13.22), (-6.35, 12.51),
            (-6.45, 11.97), (-6.21, 11.72)]
    striped_awning(22, path, red, white)


def pitched_roof(name, half_width, depth, eave, ridge, mat, thickness=.8, center=(0, 0, 0), radius=.15, segments=3):
    profile = [(-half_width, eave), (0, ridge), (half_width, eave),
               (half_width, eave - thickness), (0, ridge - thickness), (-half_width, eave - thickness)]
    # Build a cross-section in X/Z, extrude it in Y by rotating the profile helper.
    obj = extruded_profile(name, profile, -depth / 2, depth / 2, mat, radius, segments)
    obj.rotation_euler.z = math.pi / 2
    obj.location = center
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def gable_wall(name, width, depth, eave, ridge, mat, center=(0, 0, 0)):
    # A full solid gable building, with the roof ridge along Y.
    profile = [(-width / 2, 0), (width / 2, 0), (width / 2, eave), (0, ridge), (-width / 2, eave)]
    obj = extruded_profile(name, profile, -depth / 2, depth / 2, mat, .65, 3)
    obj.rotation_euler.z = math.pi / 2
    obj.location = center
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def arch_panel(name, width, height, thickness, location, mat, axis="Y", radius=.10):
    r = width / 2
    vertical_radius = min(r, height * .7)
    spring = height - vertical_radius
    contour = [(-r, 0), (r, 0), (r, spring)]
    contour += [(r * math.cos(t), spring + vertical_radius * math.sin(t)) for t in np.linspace(0, math.pi, 13)[1:]]
    obj = extruded_profile(name, contour, -thickness / 2, thickness / 2, mat, radius)
    obj.rotation_euler.z = math.pi / 2 if axis == "Y" else 0
    obj.location = location
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return obj


def round_window(name, center, radius, axis="Y"):
    frame = material("Honey wooden window trim", concept_color("house", (.38, .66)), wood=True, roughness=.35)
    glass = material("Light blue window glass", concept_color("house", (.31, .44), radius=0), roughness=.26)
    # Cylinder local axis X, optionally rotate to face the front.
    ring = lathe(name + " round frame", [(radius * .94, -.35), (radius, -.22), (radius, .22), (radius * .94, .35),
                                        (radius * .71, .35), (radius * .68, .20), (radius * .68, -.35)],
                 frame, sectors=20, axis="X", closed=True)
    pane = lathe(name + " blue pane", [(radius * .73, -.04), (radius * .73, .04)],
                 glass, sectors=24, axis="X")
    for obj in (ring, pane):
        if axis == "Y":
            obj.rotation_euler.z = math.pi / 2
        obj.location = center
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if axis == "Y":
        beam(name + " vertical muntin", (center[0], center[1] - .21, center[2] - radius * .71),
             (center[0], center[1] - .21, center[2] + radius * .71), .4, frame)
        beam(name + " horizontal muntin", (center[0] - radius * .71, center[1] - .21, center[2]),
             (center[0] + radius * .71, center[1] - .21, center[2]), .4, frame)
    else:
        beam(name + " vertical muntin", (center[0] + .21, center[1], center[2] - radius * .71),
             (center[0] + .21, center[1], center[2] + radius * .71), .4, frame)
        beam(name + " horizontal muntin", (center[0] + .21, center[1] - radius * .71, center[2]),
             (center[0] + .21, center[1] + radius * .71, center[2]), .4, frame)


def house():
    cream = material("Cream toy house walls", concept_color("house", (.46, .65)), roughness=.39)
    red = material("Variant paint", concept_color("house", (.57, .29)), roughness=.32)
    dark = material("Chimney hollow", (81, 43, 29), roughness=.62)
    wood = material("Arched house door wood", (179, 115, 56), wood=True, roughness=.36)
    box("Red house base", (25.5, 21.7, 2.0), (0, 0, 1.0), red, .50, 3)
    gable_wall("Cream gabled house", 22.1, 18.9, 14.8, 23.0, cream, (0, 0, 1.9))
    pitched_roof("Rounded red house roof", 13, 22, 16.8, 25.1, red, 1.65, radius=.65, segments=3)
    arch_frame("Door raised arched timber surround", 6.5, 10.2, 1.05, .65, (0, -9.95, 1.9), wood)
    arch_panel("Inset arched wooden door", 5.3, 9.5, .26, (0, -9.72, 1.9), timber())
    ball("Little golden doorknob", (1.45, -9.95, 5.7), .3,
         material("Golden house doorknob", (243, 177, 35)), budget=32)
    round_window("Gable round window", (0, -9.85, 17.8), 2.25)
    for y in (-4.5, 4.9):
        round_window("Side round window", (11.40, y, 9.9), 2.55, "X")
    box("Cream chimney", (3.3, 3.2, 7.0), (-6.3, 4.8, 19.5), cream, .15)
    for x in (-8.27, -4.33):
        box("Red chimney cap side", (.65, 4.4, 1.25), (x, 4.8, 23.35), red, .16, 2)
    for y in (2.93, 6.67):
        box("Red chimney cap end", (3.3, .65, 1.25), (-6.3, y, 23.35), red, .16, 2)
    box("Recessed dark chimney opening", (3.3, 3.15, .07), (-6.3, 4.8, 23.1), dark, .035)


def picnic():
    wood = timber(pale=True)
    gold = material("Picnic honey wood", (198, 142, 76), wood=True, roughness=.36)
    next(n for n in gold.node_tree.nodes if n.type == "VECT_MATH" and n.operation == "MULTIPLY").inputs[1].default_value = (7, .12, 7)
    for x in (-3.22, 0, 3.22):
        box("Thick picnic tabletop plank", (3.03, 12, .80), (x, 0, 4.64), gold, .22, 1)
    for x in (-6.55, 6.55):
        box("Attached bench plank", (2.25, 12, .80), (x, 0, 2.47), gold, .24, 2)
    for y in (-3.65, 3.65):
        for side in (-1, 1):
            beam("Splayed A-frame table leg", (side * 4.45, y, .25), (side * 2.8, y, 4.35),
                 1.0, gold, depth=1.1, radius=.10)
        box("Bench cross support", (14, .8, .64), (0, y, 1.89), gold, .08)
    # Concept has short outer bench feet under the seats.
    for x in (-6.55, 6.55):
        for y in (-3.65, 3.65):
            box("Bench short foot", (1.05, 1.05, 2.15), (x, y, 1.07), gold, .14)


def goal():
    white = material("Ivory goal and net", (241, 236, 220), roughness=.34, bevel=.02)
    red = material("Red goal corners", (211, 36, 26), bevel=.03)
    # Open front at -Y. Closed thin rods form the back, sides and roof of the net.
    tube("Goal rounded front frame", [(-11.6, -3.6, .3), (-11.6, -3.6, 7.1),
                                       (-11.4, -3.6, 7.55), (-10.95, -3.6, 7.7),
                                       (10.95, -3.6, 7.7), (11.4, -3.6, 7.55),
                                       (11.6, -3.6, 7.1), (11.6, -3.6, .3)], .30, white, sides=12)
    for side in (-1, 1):
        tube("Red top goal corner", [(side * 10.9, -3.6, 7.7), (side * 11.4, -3.6, 7.55),
                                      (side * 11.6, -3.6, 7.1), (side * 11.6, -3.6, 6.5)], .33, red, sides=10)
        tube("Red bottom goal corner", [(side * 11.6, -3.6, .33), (side * 11.6, -3.6, 1.15)], .33, red, sides=12)
        tube("Goal side support", [(side * 11.6, -3.6, .18), (side * 11.6, 3.65, .18),
                                    (side * 11.6, 3.65, 6.75), (side * 11.6, -3.6, 7.7)], .18, white, sides=6)
    for z in (.2, 6.75):
        tube("Back goal crossbar", [(-11.6, 3.65, z), (11.6, 3.65, z)], .18, white, sides=6)
    for x in np.linspace(-10.7, 10.7, 14):
        tube("Back net vertical strand", [(x, 3.62, .2), (x, 3.62, 6.75)], .085, white, sides=6)
        tube("Roof net strand", [(x, -3.6, 7.7), (x, 3.62, 6.75)], .085, white, sides=6)
    for z in np.linspace(1.25, 5.55, 5):
        tube("Back net horizontal strand", [(-11.6, 3.62, z), (11.6, 3.62, z)], .085, white, sides=6)
    for side in (-1, 1):
        for y in np.linspace(-2.4, 2.4, 5):
            top = 7.7 - (y + 3.6) / 7.25 * .95
            tube("Side net upright", [(side * 11.6, y, .2), (side * 11.6, y, top)], .085, white, sides=6)
        for z in np.linspace(1.25, 5.55, 5):
            tube("Side net horizontal strand", [(side * 11.6, -3.6, z), (side * 11.6, 3.65, z)], .085, white, sides=6)
    for y in np.linspace(-2.4, 2.4, 5):
        z = 7.7 - (y + 3.6) / 7.25 * .95
        tube("Roof net horizontal strand", [(-11.6, y, z), (11.6, y, z)], .085, white, sides=6)


def pool():
    blue = material("Deep blue pool wall", concept_color("pool", (.30, .72)), roughness=.28)
    light = material("Light blue rounded pool rim", concept_color("pool", (.50, .55)), roughness=.24)
    water = material("Clear blue paddling water", concept_color("pool", (.50, .40)), roughness=.18)
    surface_grain(water, (.19, .19, .08), .28, .11, (.85, 1.08))
    white = material("White pool ladder", (246, 238, 216), roughness=.28, bevel=.035)
    # Concept: the straight wall is about 45% of its 21.5-stud radius.
    lathe("Tall blue paddling pool shell", [(20.7, 0), (21.5, .6), (21.5, 9.5),
                                          (20.2, 10.1), (19.7, 9.1), (19.7, .45)],
          blue, sectors=48, closed=True)
    lathe("Thick soft rolled pool rim", [(21.0 + 1.25 * math.cos(t), 10.1 + 1.05 * math.sin(t))
                                       for t in np.linspace(0, math.tau, 8, endpoint=False)],
          light, sectors=48, closed=True)
    lathe("Recessed blue water", [(19.85, 8.35), (19.85, 8.5)], water, sectors=32)
    ladder_parts = len(PARTS)
    for x in (-4.7, 4.7):
        points = [(x, -25.4, .78), (x, -25.4, 10.2)]
        points += [(x, -22.8 + 2.6 * math.cos(t), 10.2 + 2.6 * math.sin(t))
                   for t in np.linspace(math.pi, 0, 9)[1:]]
        points += [(x, -20.2, 8.1)]
        tube("Big white curved ladder rail", points, .90, white, sides=10)
    for z in (2.0, 4.9, 7.8):
        beam("Wide white ladder tread", (-4.7, -25.4, z), (4.7, -25.4, z), .95, white, depth=1.35, radius=.22, segments=2)
    for obj in PARTS[ladder_parts:]:
        obj.matrix_world = Matrix.Rotation(1.10, 4, "Z") @ obj.matrix_world
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def straw_pigment(mat, radius, angle, axial, tone):
    """Broken, elongated golden flecks, affecting colour only."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    def op(kind, a, b):
        node = nodes.new("ShaderNodeMath")
        node.operation = kind
        for i, value in enumerate((a, b)):
            if isinstance(value, (int, float)): node.inputs[i].default_value = value
            else: links.new(value, node.inputs[i])
        return node.outputs[0]
    pigment_coords = nodes.new("ShaderNodeCombineXYZ")
    links.new(op("MULTIPLY", radius, 16), pigment_coords.inputs["X"])
    links.new(op("MULTIPLY", angle, 2.5), pigment_coords.inputs["Y"])
    links.new(op("MULTIPLY", axial, 14), pigment_coords.inputs["Z"])
    pigment = nodes.new("ShaderNodeTexNoise")
    pigment.name = "Broken golden straw pigments"
    pigment.inputs["Scale"].default_value = 1
    pigment.inputs["Detail"].default_value = 2
    links.new(pigment_coords.outputs[0], pigment.inputs["Vector"])
    pigment_tone = nodes.new("ShaderNodeMapRange")
    pigment_tone.inputs["From Min"].default_value = .32
    pigment_tone.inputs["From Max"].default_value = .68
    pigment_tone.inputs["To Min"].default_value = .68
    pigment_tone.inputs["To Max"].default_value = 1.30
    links.new(pigment.outputs["Fac"], pigment_tone.inputs["Value"])
    return op("MULTIPLY", tone, pigment_tone.outputs[0])


def hay_bale():
    straw = material("Golden dense straw", concept_color("hay-bale", (.30, .50)), roughness=.61, bevel=.008)
    surface_grain(straw, (24, 24, 24), .30, .018, (.91, 1.06))
    band = material("Thin honey brown bale bands", concept_color("hay-bale", (.70, .43)), roughness=.43)
    obj = lathe("Round straw bale", [(3.7, -4), (3.96, -3.65), (4, -3.2),
                                     (4, 3.2), (3.96, 3.65), (3.7, 4)], straw, sectors=26, axis="X")
    obj.rotation_euler.z = math.pi / 2
    obj.location.z = 4
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for y in (-2.6, 2.6):
        obj = lathe("Thin bale binding", [(4.0, -.13), (4.10, -.10), (4.10, .10), (4.0, .13)],
                    band, sectors=24, axis="X", closed=True)
        obj.rotation_euler.z = math.pi / 2
        obj.location = (0, y, 4)
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Closed tapered fibre bundles fray the rims without needle-like spikes.
    rng = np.random.default_rng(31)
    for side in (-1, 1):
        vertices, faces = [], []
        for index, t in enumerate(np.linspace(0, math.tau, 24, endpoint=False)):
            t += rng.uniform(-.07, .07)
            radius = 3.8 + rng.uniform(-.10, .10)
            x, z = radius * math.cos(t), 4 + radius * math.sin(t)
            y = side * (3.8 + rng.uniform(-.12, .10))
            radial = Vector((math.cos(t), 0, math.sin(t)))
            tangent = Vector((-math.sin(t), 0, math.cos(t)))
            center = Vector((x, y, z))
            base = len(vertices)
            root = center - radial * .10 - Vector((0, side * .25, 0))
            tip = center + radial * rng.uniform(.10, .26) + tangent * rng.uniform(-.15, .15)
            tip += Vector((0, side * rng.uniform(.20, .45), 0))
            vertices += [root + tangent * .13, root - tangent * .13, root + radial * .15,
                         tip + tangent * .045, tip - tangent * .045, tip + radial * .045]
            faces += [(base, base + 2, base + 1), (base + 3, base + 4, base + 5),
                      (base, base + 1, base + 4, base + 3),
                      (base + 1, base + 2, base + 5, base + 4),
                      (base + 2, base, base + 3, base + 5)]
        finish(mesh("Irregular straw rim tufts", vertices, faces), straw, smooth=False)
    vertices, faces = [], []
    # Small bundled fibres emerge alongside both binding bands too.
    for index in range(28):
        t = rng.uniform(.18, math.pi - .18)
        y = ((-2.6 if index % 2 else 2.6) + rng.choice((-1, 1)) * rng.uniform(.18, .40)
             if index < 20 else rng.uniform(-3.3, 3.3))
        radial = Vector((math.cos(t), 0, math.sin(t)))
        tangent = Vector((-math.sin(t), 0, math.cos(t)))
        center = Vector((3.98 * math.cos(t), y, 4 + 3.98 * math.sin(t)))
        base = len(vertices)
        vertices += [center - tangent * .28, center + tangent * .28,
                     center + Vector((0, .065, 0)) - radial * .035,
                     center + radial * rng.uniform(.10, .20) + tangent * .42]
        faces += [(base, base + 1, base + 2), (base, base + 3, base + 1),
                  (base + 1, base + 3, base + 2), (base + 2, base + 3, base)]
    finish(mesh("Loose raised straw strands", vertices, faces), straw, smooth=False)
    # Keep pattern coordinates in construction space after uniform sizing.
    nodes, links = straw.node_tree.nodes, straw.node_tree.links
    coords = next(n for n in nodes if n.type == "TEX_COORD")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.name, scale.operation = "Decal scale", "MULTIPLY"
    scale.inputs[1].default_value = (1, 1, 1)
    origin = nodes.new("ShaderNodeVectorMath")
    origin.name, origin.operation = "Decal origin", "ADD"
    links.new(coords.outputs["Object"], scale.inputs[0])
    links.new(scale.outputs[0], origin.inputs[0])
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(origin.outputs[0], sep.inputs[0])
    def op(kind, a, b=None):
        node = nodes.new("ShaderNodeMath"); node.operation = kind
        for i, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)): node.inputs[i].default_value = value
                else: links.new(value, node.inputs[i])
        return node.outputs[0]
    z = op("SUBTRACT", sep.outputs["Z"], 4)
    radius = op("SQRT", op("ADD", op("MULTIPLY", sep.outputs["X"], sep.outputs["X"]), op("MULTIPLY", z, z)))
    angle = op("ARCTAN2", z, sep.outputs["X"])
    fibre_coords = nodes.new("ShaderNodeCombineXYZ")
    links.new(op("MULTIPLY", radius, 9), fibre_coords.inputs["X"])
    links.new(op("MULTIPLY", angle, 18), fibre_coords.inputs["Y"])
    links.new(op("MULTIPLY", sep.outputs["Y"], 14), fibre_coords.inputs["Z"])
    fibres = nodes.new("ShaderNodeTexNoise")
    fibres.inputs["Scale"].default_value = 1
    fibres.inputs["Detail"].default_value = 3
    links.new(fibre_coords.outputs[0], fibres.inputs["Vector"])
    irregular = op("MULTIPLY", op("SUBTRACT", fibres.outputs["Fac"], .5), 2.2)
    phase = op("ADD", op("SUBTRACT", op("MULTIPLY", radius, 19), angle), irregular)
    spiral = op("POWER", op("MULTIPLY", op("ADD", op("SINE", phase), 1), .5), 5)
    fine_phase = op("ADD", op("SUBTRACT", op("MULTIPLY", radius, 82), op("MULTIPLY", angle, 3)),
                    op("MULTIPLY", irregular, 2.6))
    fine = op("SINE", fine_phase)
    # Circumferential fibres on the curved side, broken up by local noise.
    side_phase = op("ADD", op("MULTIPLY", sep.outputs["Y"], 70),
                    op("ADD", op("MULTIPLY", op("SINE", op("MULTIPLY", angle, 9)), .8), irregular))
    side_fibre = op("SINE", side_phase)
    geometry = nodes.new("ShaderNodeNewGeometry")
    normal = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geometry.outputs["Normal"], normal.inputs[0])
    mask = op("GREATER_THAN", op("ABSOLUTE", normal.outputs["Y"]), .65)
    end_height = op("ADD", op("MULTIPLY", spiral, .30), op("MULTIPLY", fine, .17))
    side_height = op("ADD", op("MULTIPLY", side_fibre, .38), op("MULTIPLY", fibres.outputs["Fac"], .4))
    height = op("ADD", op("MULTIPLY", mask, end_height),
                op("MULTIPLY", op("SUBTRACT", 1, mask), side_height))
    growth = nodes.new("ShaderNodeBump")
    growth.inputs["Strength"].default_value = .65
    growth.inputs["Distance"].default_value = .034
    links.new(height, growth.inputs["Height"])
    bump = next(n for n in nodes if n.type == "BUMP" and n != growth)
    links.new(bump.outputs["Normal"], growth.inputs["Normal"])
    links.new(growth.outputs["Normal"], nodes.get("Principled BSDF").inputs["Normal"])
    end_tone = op("ADD", .96, op("ADD", op("MULTIPLY", spiral, .13), op("MULTIPLY", fine, .08)))
    side_tone = op("ADD", .97, op("MULTIPLY", side_fibre, .10))
    tone = op("MULTIPLY", op("ADD", op("MULTIPLY", mask, end_tone),
                             op("MULTIPLY", op("SUBTRACT", 1, mask), side_tone)),
              op("ADD", .78, op("MULTIPLY", fibres.outputs["Fac"], .40)))
    tone = straw_pigment(straw, radius, angle, sep.outputs["Y"], tone)
    tint = nodes.new("ShaderNodeMixRGB"); tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 1
    bsdf = nodes.get("Principled BSDF")
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, tint.inputs[1])
    links.new(tone, tint.inputs[2]); links.new(tint.outputs[0], bsdf.inputs["Base Color"])


def footbridge():
    wood = timber(pale=True)
    red = material("Red footbridge rails", (200, 35, 27), roughness=.31)
    blue = material("Blue footbridge joints", (31, 125, 179), roughness=.31)
    path = [(y, 1.5 + 3.3 * math.sin((y + 14) / 28 * math.pi)) for y in np.linspace(-14, 14, 13)]
    contour = path + [(y, z - 1.5) for y, z in reversed(path)]
    extruded_profile("One arched pale wooden bridge deck", contour, -6.0, 6.0, wood, .22, 3)
    for x in (-5.6, 5.6):
        for y in (-12.2, 0, 12.2):
            base = 1.5 + 3.3 * math.sin((y + 14) / 28 * math.pi)
            box("Bridge red post" if y else "Bridge blue centre joint", (2.1, 2.4, 6.8),
                (x, y, base + 2.1), red if y else blue, .25, 3)
        tube("Smooth red arched handrail", [(x, y, z + 4.1) for y, z in path[1:-1]], .65, red, sides=10)


def shed_opening(width, depth, eave, ridge, wall, center, opening_width, opening_height):
    """Gabled shed with real empty front opening and a shallow interior."""
    cx, cy, cz = center
    side_width = (width - opening_width) / 2
    for side in (-1, 1):
        box("Shed front wall beside opening", (side_width, .85, eave),
            (cx + side * (opening_width + side_width) / 2, cy - depth / 2, cz + eave / 2), wall, .10)
        box("Shed side wall", (.85, depth, eave),
            (cx + side * width / 2, cy, cz + eave / 2), wall, .10)
    box("Shed front lintel", (opening_width, .85, eave - opening_height),
        (cx, cy - depth / 2, cz + (eave + opening_height) / 2), wall, .10)
    box("Shed solid back wall", (width, .85, eave), (cx, cy + depth / 2, cz + eave / 2), wall, .1)
    for y in (-depth / 2, depth / 2):
        obj = extruded_profile("Shed triangular gable", [(-width / 2, eave), (width / 2, eave), (0, ridge)],
                               -.44, .44, wall, .10)
        obj.rotation_euler.z = math.pi / 2
        obj.location = (cx, cy + y, cz)
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def boathouse():
    wood = material("Boathouse pale honey siding", concept_color("boathouse", (.39, .48)), wood=True, roughness=.4)
    surface_grain(wood, (7, 7, .14), .30, .045, (.90, 1.06))
    green_roof = material("Green boathouse roof", concept_color("boathouse", (.65, .27)), roughness=.32)
    blue = material("Blue wooden landing dock", concept_color("boathouse", (.27, .79)), wood=True, roughness=.35)
    surface_grain(blue, (.14, 9, 9), .25, .035, (.96, 1.04))
    dark = material("Dark shed interior windows", (68, 43, 24), roughness=.58)
    box("Thick rounded boathouse platform", (23, 21.0, 2.05), (0, 4, 2.45), wood, .65, 3)
    for x in (-8.9, 8.9):
        for y in (-3.9, 11.9):
            lathe("Platform round wooden post", [(1.1, 0), (1.25, .18), (1.25, 2.0), (1.1, 2.15)],
                  wood, sectors=16, center=(x, y, 0))
    # One continuous shell avoids a horizontal seam across the front gable.
    shell = gable_wall("Light wood planked boathouse shell", 19.0, 17.4, 10.7, 16.7, wood, (0, 4, 3.45))
    def subtract(cutter):
        mod = shell.modifiers.new("Real recessed boathouse opening", "BOOLEAN")
        mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
        apply(shell, mod)
        bpy.data.objects.remove(cutter, do_unlink=True)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 4, 9.1))
    cavity = bpy.context.object
    cavity.dimensions = (17.0, 15.4, 11.35)
    active(cavity)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    subtract(cavity)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -4.75, 7.30))
    doorway = bpy.context.object
    doorway.dimensions = (8.6, 3.2, 8.0)
    active(doorway)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(doorway, .35, 3)
    subtract(doorway)
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=1.45, depth=3.2,
                                      location=(0, -4.7, 16.35), rotation=(math.pi / 2, 0, 0))
    subtract(bpy.context.object)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(9.5, 1.6, 9.7))
    window = bpy.context.object
    window.dimensions = (3.2, 3.15, 3.5)
    active(window)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(window, .42, 3)
    subtract(window)
    clean_mesh(shell)
    shell.data.materials.clear()
    shell.data.materials.append(wood)
    for face in shell.data.polygons:
        face.material_index = 0
    for layer in list(shell.data.uv_layers):
        if layer.name != "ToyUV":
            shell.data.uv_layers.remove(layer)
    active(shell)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0)
    bpy.ops.object.mode_set(mode="OBJECT")
    mod = shell.modifiers.new("Flat plank faces and soft recesses", "WEIGHTED_NORMAL")
    mod.keep_sharp = True
    apply(shell, mod)
    # Dark panes sit behind the actual wall thickness, with a visible wood reveal.
    obj = lathe("Recessed round gable pane", [(1.45, -.045), (1.45, .045)], dark, sectors=28, axis="X")
    obj.rotation_euler.z = math.pi / 2
    obj.location = (0, -3.6, 16.35)
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box("Recessed square side pane", (.09, 3.15, 3.5), (8.4, 1.6, 9.7), dark, .04)
    pitched_roof("Green shed roof", 11.5, 20.0, 14.45, 21.15, green_roof, 1.35, (0, 4, 0), .45, 3)
    # Grain and narrow plank joints are shared by the continuous walls.
    nodes, links = wood.node_tree.nodes, wood.node_tree.links
    coords = next(n for n in nodes if n.type == "TEX_COORD")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.name, scale.operation = "Decal scale", "MULTIPLY"
    scale.inputs[1].default_value = (1, 1, 1)
    origin = nodes.new("ShaderNodeVectorMath")
    origin.name, origin.operation = "Decal origin", "ADD"
    links.new(coords.outputs["Object"], scale.inputs[0])
    links.new(scale.outputs[0], origin.inputs[0])
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(origin.outputs[0], sep.inputs[0])
    geometry = nodes.new("ShaderNodeNewGeometry")
    normal = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geometry.outputs["Normal"], normal.inputs[0])
    def op(kind, a, b=None):
        node = nodes.new("ShaderNodeMath"); node.operation = kind
        for i, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)): node.inputs[i].default_value = value
                else: links.new(value, node.inputs[i])
        return node.outputs[0]
    side = op("GREATER_THAN", op("ABSOLUTE", normal.outputs["X"]), .7)
    coordinate = op("ADD", op("MULTIPLY", side, sep.outputs["Y"]),
                    op("MULTIPLY", op("SUBTRACT", 1, side), sep.outputs["X"]))
    seam = op("GREATER_THAN", op("COSINE", op("MULTIPLY", coordinate, math.tau / 2.4)), .995)
    seam = op("MULTIPLY", seam, op("GREATER_THAN", sep.outputs["Z"], 3.50))
    seam = op("MULTIPLY", seam, op("LESS_THAN", op("ABSOLUTE", normal.outputs["Z"]), .4))
    tint = nodes.new("ShaderNodeMixRGB")
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 1
    bsdf = nodes.get("Principled BSDF")
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, tint.inputs[1])
    links.new(op("SUBTRACT", 1, op("MULTIPLY", seam, .28)), tint.inputs[2])
    links.new(tint.outputs[0], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .45
    bump.inputs["Distance"].default_value = .045
    links.new(op("SUBTRACT", 1, seam), bump.inputs["Height"])
    links.new(bsdf.inputs["Normal"].links[0].from_socket, bump.inputs["Normal"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    for y in np.linspace(-14.3, -5.95, 7):
        box("Blue dock plank", (14.5, 1.29, 1.15), (0, y, 2.45), blue, .15, 3)
    for x in (-7.9, 7.9):
        for y in (-14.0, -6.3):
            lathe("Dock round wood post", [(1.0, 0), (1.1, .18), (1.1, 4.5), (1.0, 4.7)],
                  wood, sectors=16, center=(x, y, 0))


def playground():
    blue = material("Playground blue posts", (34, 112, 159), roughness=.31)
    green_frame = material("Playground green frame", (52, 137, 39), roughness=.32)
    yellow = material("Golden yellow slide", (246, 188, 23), roughness=.28)
    red = material("Red playground ladder", (204, 43, 25))
    wood = timber(pale=True)
    white = material("Ivory swing ropes", (241, 233, 208), roughness=.5)
    for x in (-22, -14):
        for y in (1, 9):
            box("Blue slide tower upright", (1.2, 1.2, 15.6), (x, y, 7.8), blue, .4, 1 if x < -20 and y > 5 else 2)
    box("Slide tower wooden landing", (8.6, 8.6, .65), (-18, 5, 11.1), wood, .18, 2)
    for x in (-21.55, -14.45):
        beam("Landing wooden handrail", (x, 1.1, 14.2), (x, 8.9, 14.2), .55, wood, radius=.17, segments=1)
        for y in (2.1, 4.1, 6.1, 8.1):
            beam("Landing safety upright", (x, y, 11.3), (x, y, 14.2), .39, wood, radius=.10)
    # S-shaped slide has a continuous deck and raised rounded sides.
    path = [(1.0, 10.95), (-.5, 10.68), (-2.0, 9.85), (-3.6, 7.9), (-5.0, 5.5),
            (-6.6, 3.16), (-8.7, 1.35), (-10.7, .65), (-12.6, .56), (-13.3, .85)]
    contour = path + [(y, z - .45) for y, z in reversed(path)]
    extruded_profile("Wide yellow curved slide deck", contour, -21.4, -14.6, yellow, .10)
    for x in (-21.4, -14.6):
        edge = [(y, z + .9) for y, z in path] + [(y, z - .15) for y, z in reversed(path)]
        extruded_profile("Rounded raised slide side", edge, x - .28, x + .28, yellow, .15)
    for x in (-20.8, -15.2):
        beam("Rear red slide ladder rail", (x, 14, .3), (x, 8.7, 11.1), .55, red, radius=.16, segments=1)
    for t in np.linspace(.12, .88, 6):
        y, z = 14 - 5.3 * t, .3 + 10.8 * t
        beam("Red slide ladder tread", (-20.8, y, z), (-15.2, y, z), .52, red, radius=.12)
    beam("Blue swing overhead bar", (-14, 5, 13.9), (6.7, 5, 13.9), .75, blue, radius=.27, segments=1)
    for x in (-7.8, -2.2):
        tube("Ivory swing rope", [(x, 5, 13.7), (x, 4.25, 5.9)], .13, white, sides=8)
        tube("Rope loop around overhead bar", [(x, 5.36, 13.65), (x, 5.3, 14.2),
                                                (x, 4.75, 14.3), (x, 4.62, 13.65)], .13, white, sides=8)
    box("Golden swing seat", (6.2, 2.2, .50), (-5, 4.25, 5.77), yellow, .18, 2)
    for x in (6.7, 17):
        for y in (1, 9):
            height = 14.2 if x < 10 else 13.2
            box("Green climbing platform upright", (1.2, 1.2, height), (x, y, height / 2), green_frame, .4, 2)
    beam("Green support under swing beam", (6.7, 1, 13.8), (6.7, 9, 13.8), .85, green_frame, radius=.22)
    box("Wooden climbing platform", (11, 8.6, .6), (11.85, 5, 8.0), wood, .18, 2)
    for y in (1, 9):
        beam("Green platform upper rail", (6.7, y, 11.9), (17, y, 11.9), .55, green_frame, radius=.18, segments=1)
        for z in (2.0, 4.4):
            beam("Green climbing frame cross rung", (6.7, y, z), (17, y, z), .50, green_frame, radius=.14)
    beam("Green platform rear handrail", (6.7, 9, 11.9), (17, 9, 11.9), .5, green_frame, radius=.17)
    for y in (1.2, 7.9):
        beam("Sloping green ladder rail", (24, y, .2), (17, y, 10.8), .75, green_frame, radius=.22, segments=2)
    for t in np.linspace(.15, .86, 5):
        x, z = 24 - 7 * t, .2 + 10.6 * t
        beam("Climbing ladder tread", (x, 1.2, z), (x, 7.9, z), .62, green_frame, radius=.16)


def square_window(name, location, size, axis="Y", trim_color=(246, 235, 213)):
    frame = material("Window raised trim", trim_color, roughness=.36)
    glass = material("Dark recessed window", (23, 26, 21), roughness=.3)
    w, h = size
    cx, cy, cz = location
    rounded_ring(name + " open raised frame", (w + .55, h + .55), (w - .55, h - .55),
                 .75, (cx, cy - .28, cz) if axis == "Y" else (cx + .28, cy, cz),
                 frame, axis, radius=.18)
    box(name + " recessed pane", (w, .12, h) if axis == "Y" else (.12, w, h),
        location, glass, .055, 3)



def barn():
    red = material("Red painted barn siding", concept_color("barn", (.15, .60)), wood=True, roughness=.37)
    pale = timber(pale=True)
    white = material("Barn cream white door trim", (247, 242, 218), roughness=.38)
    dark = material("Dark barn door gaps", (101, 27, 16), roughness=.52)
    wood = material("Wooden silo staves", concept_color("barn", (.86, .69)), wood=True, roughness=.4)
    wall_profile = [(-14.5, 0), (14.5, 0), (14.5, 20.6), (10.85, 25.3),
                    (0, 31.0), (-10.85, 25.3), (-14.5, 20.6)]
    body = extruded_profile("Red barn gambrel walls", wall_profile, -15, 15, red, .15)
    body.rotation_euler.z = math.pi / 2
    body.location.x = -6
    active(body)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    surface_grain(pale, (7, .12, 7), .22, .055, (.84, 1.10))
    groove = material("Barn siding grooves", (140, 24, 17), roughness=.43)
    for x in np.linspace(-19.5, 7.5, 14):
        height = float(np.interp(abs(x + 6), (0, 10.85, 14.5), (31.0, 25.3, 20.6))) - .8
        box("Front barn plank joint", (.045, .04, height), (x, -15.15, height / 2), groove, 0)
    for y in np.linspace(-14, 14, 14):
        box("Side barn plank joint", (.04, .045, 19.5), (8.65, y, 9.75), groove, 0)
    roof_profile = [(-16.3, 19.7), (-11.4, 26.8), (0, 32.3), (11.4, 26.8), (16.3, 19.7),
                    (15.5, 19.3), (10.85, 25.3), (0, 31.0), (-10.85, 25.3), (-15.5, 19.3)]
    roof = extruded_profile("Pale wooden gambrel barn roof", roof_profile, -17, 17, pale, .28, 3)
    roof.rotation_euler.z = math.pi / 2
    roof.location.x = -6
    active(roof)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box("Barn paired red doors", (12.2, .28, 13), (-6, -15.22, 6.5), dark, .05)
    for x in (-9.2, -2.8):
        box("Red barn door leaf", (5.85, .35, 12.5), (x, -15.48, 6.25), red, .04)
        for side in (-1, 1):
            beam("Barn white door X", (x - 2.6, -15.72, 1 if side > 0 else 11.7),
                 (x + 2.6, -15.72, 11.7 if side > 0 else 1), .75, white, depth=.70, radius=.10, segments=3)
    for x in (-12.3, -6, .3):
        box("Barn door upright cream trim", (.85, 1.0, 13.7), (x, -15.66, 6.65), white, .04)
    box("Barn door cream header", (14.3, 1.05, 1.2), (-6, -15.67, 13.6), white, .06)
    square_window("Barn upper window", (-6, -15.45, 21.2), (4.0, 4.2))
    for y in (-5.4, 5.4):
        square_window("Barn side window", (8.65, y, 9.2), (3.1, 4.0), "X")
    lathe("Tall wooden silo", [(4.2, 0), (4.75, .4), (4.75, 30.0), (4.6, 30.4)],
          wood, sectors=32, center=(15.6, 10.5, 0))
    profile = [(4.75, 29.9)] + [(4.75 * math.cos(t), 30.0 + 4.65 * math.sin(t))
                                 for t in np.linspace(0, math.pi / 2 - .015, 7)]
    lathe("Rounded red silo cap", profile, red, sectors=32, center=(15.6, 10.5, 0))


def petrol_station():
    yellow = material("Yellow petrol station shop", concept_color("petrol-station", (.16, .60)), roughness=.34)
    blue = material("Petrol station blue trim", concept_color("petrol-station", (.27, .26)), roughness=.31)
    red = material("Red petrol canopy and pumps", concept_color("petrol-station", (.55, .49)), roughness=.30)
    grey = material("Petrol station grey base", (165, 150, 125), roughness=.47)
    glass = material("Pale blue shop glass", concept_color("petrol-station", (.19, .52)), roughness=.25)
    black = material("Black petrol hoses", (26, 26, 23), roughness=.46)
    wood = material("Canopy honey timber", concept_color("petrol-station", (.58, .66)), wood=True, roughness=.36)
    # Measured roof widths in the concept: blue/red about .79. The small shop
    # sits behind the canopy, with its door on the right side facing the pumps.
    box("Grey shop plinth", (21, 22.0, 1.65), (-16.0, 6.5, .825), grey, .55, 3)
    box("Small chunky yellow petrol shop", (18.5, 18.5, 12.8), (-16.0, 6.5, 8.0), yellow, .75, 3)
    box("Thick blue shop roof", (23.0, 21.5, 1.8), (-16.0, 6.5, 15.25), blue, .60, 3)
    rounded_ring("Raised blue shop roof lip", (22.8, 21.4), (21.2, 19.8), .85,
                 (-16.0, 6.5, 16.3), blue, radius=.55)
    box("Shop recessed front glass", (12.7, .20, 6.9), (-16.0, -2.87, 8.7), glass, .4, 3)
    rounded_ring("Chunky yellow shop window frame", (13.8, 8.0), (12.4, 6.6), .70,
                 (-16.0, -3.15, 8.7), yellow, "Y", .45)
    box("Recessed blue shop side door", (.22, 4.2, 10.5), (-6.65, 10.3, 6.9), blue, .24, 3)
    for y in (7.95, 12.65):
        box("Yellow door jamb", (.80, .55, 11.0), (-6.55, y, 7.0), yellow, .12, 3)
    box("Yellow door header", (.80, 5.3, .60), (-6.55, 10.3, 12.2), yellow, .12, 3)
    box("Shop side recessed blue pane", (.20, 5.0, 6.7), (-6.62, 1.5, 8.7), blue, .3, 3)
    box("Blue pump island", (11.5, 24, 1.65), (15.7, -7.0, .825), blue, .55, 3)
    for x, y in ((11.0, -18.0), (20.25, 3.5)):
        lathe("Thick round canopy wood post", [(1.0, 1.5), (1.2, 1.75), (1.2, 17.4), (1.0, 17.6)],
              wood, sectors=16, center=(x, y, 0))
    box("Big thick red pump canopy", (32, 24.5, 2.15), (12.8, -8.0, 18.4), red, .75, 3)
    rounded_ring("Raised red canopy rim", (31.8, 24.4), (30.0, 22.6), .8,
                 (12.8, -8, 19.8), red, radius=.65)
    for x, y in ((16.8, -12.3), (16.8, -2.0)):
        box("Chunky red petrol pump", (5.4, 5.2, 8.8), (x, y, 6.0), red, .65, 3)
        box("Recessed blue pump display", (3.0, .20, 3.1), (x, y - 2.62, 8.0), glass, .24, 3)
        tube("Looped black pump hose", [(x - 2.75, y - .8, 8.8), (x - 3.4, y - 2.0, 7.2),
                                       (x - 3.6, y - 2.2, 3.8), (x - 3.0, y - 2.2, 2.8),
                                       (x - 2.3, y - 2.2, 3.3), (x - 2.3, y - 2.1, 6.5)], .22, black, sides=8)
        beam("Black pump nozzle", (x - 2.3, y - 2.6, 6.7), (x - 2.5, y - 2.6, 8.1), .34, black, radius=.07, segments=3)


def fire_station():
    red = material("Red toy fire station", concept_color("fire-station", (.30, .38)), roughness=.34)
    yellow = material("Fire station golden garage door", (251, 206, 24), roughness=.32)
    grey = material("Grey station base and roof", (167, 163, 150), roughness=.46)
    white = material("Cream station door surround", (245, 234, 202), roughness=.38)
    dark = material("Garage handle and gaps", (98, 85, 55), roughness=.45)
    box("Grey fire station foundation", (50, 34, 1.2), (0, 0, .6), grey, .25, 2)
    box("Main red fire station", (32, 29, 21.0), (-7.5, 0, 11.7), red, .7, 3)
    box("Flat grey garage roof", (31, 28, .6), (-7.5, 0, 22.5), grey, .2)
    for x in (-23.5, 8.5):
        box("Red station roof side parapet", (.65, 29.6, 1.3), (x, 0, 23.0), red, .14)
    box("Red station back parapet", (32, .65, 1.3), (-7.5, 14.5, 23.0), red, .14)
    frame_profile = [(-10.4, 0), (-10.4, 17.2), (10.4, 17.2), (10.4, 0),
                     (9.2, 0), (9.2, 16), (-9.2, 16), (-9.2, 0)]
    garage_frame = extruded_profile("Continuous deep white garage frame", frame_profile,
                                   -.75, .75, white, .18, 3)
    garage_frame.rotation_euler.z = math.pi / 2
    garage_frame.location = (-11.6, -15.0, 1.2)
    active(garage_frame)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box("Golden garage door", (18.4, .24, 15.6), (-11.6, -14.9, 9.1), yellow, .14)
    for z in (3.5, 6.1, 8.7, 11.3, 13.9, 16.5):
        box("Garage shallow panel seam", (18.0, .08, .09), (-11.6, -15.07, z),
            material("Golden garage seams", (211, 164, 24)), .025)
    box("Garage dark handle", (2.3, .12, .34), (-11.6, -15.12, 2.8), dark, .1)
    # Curved front badge pediment.
    profile = [(-11.4, 15), (11.4, 15), (11.4, 18.8), (8, 20.4), (3.5, 21.5),
               (0, 21.8), (-3.5, 21.5), (-8, 20.4), (-11.4, 18.8)]
    pediment = extruded_profile("Curved red fire badge pediment", [(x, z + 3.5) for x, z in profile], -.65, .65, red, .18, 3)
    pediment.rotation_euler.z = math.pi / 2
    pediment.location = (-11.6, -14.82, 0)
    active(pediment)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    flame_profile = [(-1.2, 0), (1.25, 0), (2.1, 1.1), (1.8, 2.6), (.55, 4.1),
                     (.35, 2.05), (-.3, 3.3), (-1.2, 2.15), (-1.65, .9)]
    flame = extruded_profile("Golden flame badge", flame_profile, -.15, .15, yellow, .18, 3)
    flame.rotation_euler.z = math.pi / 2
    flame.location = (-11.6, -15.6, 20.4)
    active(flame)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    PARTS.remove(flame)
    finish(flame, yellow, uv="strict", weighted=True)
    for y in (-9.0, -3.0):
        square_window("Station side window", (8.62, y, 9.8), (3.6, 4.1), "X")
    box("Tall red lookout tower", (12.2, 14.2, 27), (16.4, 7.8, 14.7), red, .45, 3)
    # One continuous lookout shell avoids coincident faces between bands and piers.
    cab = rounded_shell("Continuous red tower lookout", (12.3, 14.3, 6.3),
                        (16.4, 7.8, 31.15), red, .35, 3)
    for dimensions in ((4.2, 24, 4.2), (24, 4.2, 4.2)):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(16.4, 7.8, 31.15))
        cutter = bpy.context.object
        cutter.dimensions = dimensions
        while cutter.data.uv_layers:
            cutter.data.uv_layers.remove(cutter.data.uv_layers[0])
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        mod = cab.modifiers.new("Real square lookout openings", "BOOLEAN")
        mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
        apply(cab, mod)
        bpy.data.objects.remove(cutter, do_unlink=True)
    clean_mesh(cab)
    bevel(cab, .10, 3)
    PARTS.remove(cab)
    finish(cab, red, uv="strict", weighted=True)
    roof = mesh("Grey tower hipped roof", [(9.2, -.15, 28.7), (23.6, -.15, 28.7),
                                          (23.6, 15.75, 28.7), (9.2, 15.75, 28.7),
                                          (16.4, 7.8, 32.3), (9.2, -.15, 28.2),
                                          (23.6, -.15, 28.2), (23.6, 15.75, 28.2), (9.2, 15.75, 28.2)],
                [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (5, 8, 7, 6),
                 (0, 5, 6, 1), (1, 6, 7, 2), (2, 7, 8, 3), (3, 8, 5, 0)])
    for vertex in roof.data.vertices:
        vertex.co.z += 6
    bevel(roof, .25, 3)
    finish(roof, grey, smooth=False)
    arch_panel("Golden tower door", 4.5, 9.2, .23, (16.4, .55, 1.2), yellow)
    ball("Tower dark door handle", (17.7, .32, 5.3), .18, dark, budget=24)


def plane():
    white = material("Ivory toy aircraft", (244, 239, 222), roughness=.29)
    blue = material("Blue toy aircraft", concept_color("plane", (.71, .64)), roughness=.28)
    red = material("Red propeller", (224, 37, 26), roughness=.27)
    rubber = material("Plane black rubber wheels", (26, 25, 22), roughness=.44)
    hub = material("Plane ivory wheel hubs", (218, 205, 168))
    sections = [(-10.3, .65, .7, 4.3), (-9.7, 1.7, 1.6, 4.6), (-8, 2.5, 2.2, 4.8),
                (-5.4, 2.65, 2.6, 5.0), (-2.8, 2.6, 2.65, 5.05), (0, 2.38, 2.55, 5.0),
                (3.3, 1.92, 1.9, 5.02), (6.1, 1.24, 1.18, 5.2), (8.7, .67, .62, 5.42),
                (10.0, .18, .21, 5.5)]
    sectors = 24
    vertices = [(rx * 1.18 * math.cos(t), y, cz + rz * 1.18 * math.sin(t))
                for y, rx, rz, cz in sections for t in np.linspace(0, math.tau, sectors, endpoint=False)]
    faces = [(i * sectors + j, i * sectors + (j + 1) % sectors,
              (i + 1) * sectors + (j + 1) % sectors, (i + 1) * sectors + j)
             for i in range(len(sections) - 1) for j in range(sectors)]
    faces += [tuple(reversed(range(sectors))), tuple((len(sections) - 1) * sectors + j for j in range(sectors))]
    fuselage = finish(mesh("Smooth tapered toy fuselage", vertices, faces), white)
    fuselage.data.materials.append(blue)
    # The blue underside is a smooth baked colour boundary, not stepped face paint.
    # Rounded planform tips and a thick blue molded wing section.
    for side in (-1, 1):
        outline = [(1.65, -3.7), (11.4, -3.3), (12.5, -2.8), (13, -1.8),
                   (13, .8), (12.55, 1.7), (11.4, 2.1), (1.65, 2.6)]
        vertices = [(side * x, y, z) for z in (3.35, 4.55) for x, y in outline]
        n = len(outline)
        faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
        obj = mesh("Blue main wing with rounded tip", vertices, faces)
        bevel(obj, .38, 3)
        finish(obj, blue, weighted=True)
    box("Ivory tail stabilizer", (9.7, 3.9, .65), (0, 8.1, 5.3), white, .3, 3)
    fin = extruded_profile("Rounded ivory vertical tail", [(5.1, 5.7), (7.8, 10.0),
                                                            (8.8, 10.4), (9.3, 10.0),
                                                            (9.7, 5.9)], -.45, .45, white, .27)
    paint_regions(white, (113, 172, 191), [
        (("X", "Y"), (0, -7.1), (2.02, 1.34), .32, "Z", 5.85)] + [
        (("Y", "Z"), (yc, 6.15), (.55, .70), .22, "X", 1.5)
        for yc in (-3.8, -1.6, .5)])
    nodes, links = white.node_tree.nodes, white.node_tree.links
    split = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nodes["Decal origin"].outputs[0], split.inputs[0])
    below = nodes.new("ShaderNodeMath"); below.operation = "LESS_THAN"
    below.inputs[1].default_value = 4.25
    links.new(split.outputs["Z"], below.inputs[0])
    underside = nodes.new("ShaderNodeMixRGB")
    links.new(below.outputs[0], underside.inputs[0])
    bsdf = nodes.get("Principled BSDF")
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, underside.inputs[1])
    underside.inputs[2].default_value = linear(concept_color("plane", (.71, .64)))
    links.new(underside.outputs[0], bsdf.inputs["Base Color"])
    for x in (-3.1, 3.1):
        beam("Plane wheel strut", (x, -1.3, 1.0), (x, -1.3, 4.0), .4, blue, radius=.12)
        lathe("Rounded plane tyre", [(1.45, -.5), (1.65, -.28), (1.65, .28), (1.45, .5)],
              rubber, sectors=24, center=(x, -1.3, 1.65), axis="X")
        lathe("Plane ivory hub", [(.50, -.08), (.55, .05)], hub, sectors=20,
              center=(x + (.55 if x > 0 else -.55), -1.3, 1.65), axis="X")
    # Capsule-ended blades, broad and rounded like the concept's toy propeller.
    profile = [(-.27, .1), (.27, .1), (.58, 2.6)]
    profile += [(.60 * math.cos(t), 2.65 + .60 * math.sin(t)) for t in np.linspace(0, math.pi, 13)]
    profile += [(-.58, 1.0)]
    for i in range(3):
        obj = extruded_profile("Rounded red propeller blade", profile, -.19, .19, red, 0)
        obj.rotation_euler.z = math.pi / 2
        active(obj)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        obj.rotation_euler.y = math.tau * i / 3
        obj.scale = (1.18, 1.18, 1.18)
        obj.location = (0, -10.5, 4.4)
    ball("Red propeller hub", (0, -10.85, 4.4), .85, red, scale=(1, .8, 1), budget=128)


def hangar():
    wood = material("Pale curved hangar wood", concept_color("hangar", (.56, .25)), wood=True, roughness=.39)
    surface_grain(wood, (7, .10, 7), .35, .09, (.69, 1.14))
    red = material("Hangar red door header", (202, 36, 24), roughness=.31)
    glass = material("Hangar small blue window", (110, 170, 187), roughness=.27)
    angles = np.linspace(0, math.pi, 33)
    profile = [(20 * math.cos(t), 20 * math.sin(t)) for t in angles]
    profile += [(17.5 * math.cos(t), 17.5 * math.sin(t)) for t in reversed(angles)]
    # A thick barrel vault, continuously open underneath and through its front.
    obj = extruded_profile("Curved pale wood hangar shell", profile, -15, 15, wood, 0)
    obj.rotation_euler.z = math.pi / 2
    active(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Smooth just the cylindrical vault, leaving end grain faces flat.
    for f in obj.data.polygons:
        f.use_smooth = f.index > 1
    # One front wall keeps the wooden face continuous around the opening.
    contour = [(18.8 * math.cos(t), 18.8 * math.sin(t)) for t in angles]
    front = extruded_profile("Continuous arched hangar front", contour, -.5, .5, wood, 0)
    front.rotation_euler.z = math.pi / 2
    front.location.y = -15.3
    active(front)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -15.3, 5.3))
    cutter = bpy.context.object
    cutter.dimensions = (19.2, 5, 11.4)
    while cutter.data.uv_layers:
        cutter.data.uv_layers.remove(cutter.data.uv_layers[0])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mod = front.modifiers.new("Real open hangar entrance", "BOOLEAN")
    mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
    apply(front, mod)
    bpy.data.objects.remove(cutter, do_unlink=True)
    clean_mesh(front)
    bevel(front, .08, 2)
    PARTS.remove(front)
    finish(front, wood, weighted=True)
    frame_profile = [(20.4 * math.cos(t), 20.4 * math.sin(t)) for t in np.linspace(0, math.pi, 21)]
    frame_profile += [(18.1 * math.cos(t), 18.1 * math.sin(t)) for t in np.linspace(math.pi, 0, 21)]
    frame = extruded_profile("Deep raised wooden hangar arch", frame_profile, -1.0, 1.0, wood, .10, 3)
    frame.rotation_euler.z = math.pi / 2
    frame.location.y = -15.2
    active(frame)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box("Red strip above open hangar door", (20.5, 1.1, 1.3), (0, -16.1, 11.15), red, .3, 3)
    arch_panel("Small arched blue hangar window", 5.8, 2.5, .15, (0, -15.95, 13.6), glass, radius=.05)
    # A solid curved back wall closes the shed.
    back_contour = [(18.7, 0)] + [(17.5 * math.cos(t), 17.5 * math.sin(t)) for t in angles[1:]]
    back = extruded_profile("Hangar closed curved rear wall", back_contour, -.45, .45, wood, 0)
    back.rotation_euler.z = math.pi / 2
    back.location.y = 14.5
    active(back)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def terminal():
    wood = material("Terminal honey wood", concept_color("terminal", (.20, .59)), wood=True, roughness=.36)
    blue = material("Terminal blue decks and trim", concept_color("terminal", (.53, .73)), roughness=.31)
    red = material("Terminal red roofs", concept_color("terminal", (.44, .54)), roughness=.31)
    grey = material("Grey terminal foundation", (180, 171, 151), roughness=.48)
    glass = material("Blue glass tower cab", (118, 176, 188), roughness=.21)
    ivory = material("Ivory control cab posts", (242, 231, 206))
    yellow = material("Golden tower beacon", (252, 212, 22), roughness=.27)
    box("Terminal grey foundation", (40, 28.5, 1.7), (0, 0, .85), grey, .28, 2)
    lathe("Round wood control tower", [(4.5, 1.5), (4.8, 1.8), (4.8, 30.5), (4.5, 31.0)], wood, sectors=28, center=(-11, 4.5, 0))
    box("Control tower red entrance door", (2.5, .17, 6.2), (-11, -.45, 4.7), red, .32, 2)
    box("Terminal lower blue deck", (37, 26, 1.8), (0, 0, 13.6), blue, .45, 3)
    for x in (-1.8, 17.0):
        for y in (-11, 11):
            lathe("Terminal long round timber post", [(1.15, 1.5), (1.35, 1.8), (1.35, 24.0)], wood, sectors=20, center=(x, y, 0))
    for bottom, top in ((1.2, 13.1), (14.1, 24.0)):
        middle, height = (bottom + top) / 2, top - bottom
        cabin = rounded_shell("Terminal solid wooden cabin", (13.1, 14.4, height), (7.6, -1.8, middle),
                              wood, .12, 1)
        for x in (4.72, 10.48):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -3.4, middle))
            cutter = bpy.context.object
            cutter.dimensions = (5.0, 13.8, height - 3.5)
            while cutter.data.uv_layers:
                cutter.data.uv_layers.remove(cutter.data.uv_layers[0])
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            bevel(cutter, .18, 2)
            mod = cabin.modifiers.new("Real terminal cabin window", "BOOLEAN")
            mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
            apply(cabin, mod)
            bpy.data.objects.remove(cutter, do_unlink=True)
        clean_mesh(cabin)
        PARTS.remove(cabin)
        finish(cabin, wood, weighted=True)
    # Low crowned red canopy, with its peak softened in actual geometry.
    crest = [(x, 24.0 + 3.2 * math.cos(x / 13.8 * math.pi / 2)) for x in np.linspace(-13.8, 13.8, 17)]
    roof = extruded_profile("Curved terminal red canopy", crest + [(x, z - 1.8) for x, z in reversed(crest)],
                            -14, 14, red, .40, segments=3)
    roof.rotation_euler.z = math.pi / 2
    roof.location.x = 7
    active(roof)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    box("Blue cab lower balcony", (12.2, 12.2, 1.65), (-11, 4.5, 30.7), blue, .25, 2)
    vertices = [(-11 + sx * r, 4.5 + sy * r, z) for r, z in ((4.5, 31.1), (5.2, 38.0))
                for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    cab = mesh("Tapered blue glass control cab", vertices,
               [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5),
                (2, 3, 7, 6), (3, 0, 4, 7)])
    bevel(cab, .14, 2)
    finish(cab, glass, weighted=True)
    side_glass = material("Control cab darker blue side glass", (91, 130, 164), roughness=.21)
    cab.data.materials.append(side_glass)
    for face in cab.data.polygons:
        if face.center.x > -7.1:
            face.material_index = 1
    for sx in (-1, 1):
        for sy in (-1, 1):
            beam("Bold ivory sloping cab frame", (-11 + sx * 4.55, 4.5 + sy * 4.55, 31.1),
                 (-11 + sx * 5.25, 4.5 + sy * 5.25, 38.0), .65, ivory, radius=.08)
    for r, z in ((4.55, 31.2), (5.25, 37.9)):
        box("Ivory cab front rail", (2 * r + .6, .65, .65), (-11, 4.5 - r, z), ivory, .09)
        box("Ivory cab visible side rail", (.65, 2 * r + .6, .65), (-11 + r, 4.5, z), ivory, .09)
    box("Red control cab roof", (13.0, 13.0, 1.7), (-11, 4.5, 38.8), red, .40, 3)
    ball("Round yellow tower beacon", (-11, 4.5, 40.5), 2.2, yellow, segments=24, rings=6, front_axis=True)


def ruler_bridge():
    """A 300-stud ruler on two six-brick columns, matching its studio concept."""
    wood = material("Ruler deck wood", (238, 211, 155), wood=True, roughness=.38, bevel=.12)
    surface_grain(wood, (.018, 2.8, 2.8), .10, .04, (.90, 1.08))
    nodes, links = wood.node_tree.nodes, wood.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], separate.inputs[0])

    def calculate(operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)):
                    node.inputs[index].default_value = value
                else:
                    links.new(value, node.inputs[index])
        return node.outputs[0]

    # 30 centimetres across 300 studs. Four subdivisions per centimetre keep
    # the small ticks at least 1.5 texture pixels wide on the dedicated top UV.
    x = calculate("ADD", separate.outputs["X"], 140)
    distances = [calculate("ABSOLUTE", calculate("PINGPONG", x, period))
                 for period in (1.25, 2.5, 5)]
    tick = calculate("LESS_THAN", distances[0], .48)
    medium = calculate("MULTIPLY", calculate("LESS_THAN", distances[1], .48), 1.5)
    major = calculate("MULTIPLY", calculate("LESS_THAN", distances[2], .48), 3.5)
    length = calculate("ADD", calculate("MAXIMUM", medium, major), 2.2)
    y = calculate("ABSOLUTE", separate.outputs["Y"])
    edge = calculate("GREATER_THAN", y, calculate("SUBTRACT", 19.2, length))
    edge = calculate("MULTIPLY", edge, calculate("LESS_THAN", y, 19.2))
    top = calculate("MULTIPLY", edge, calculate("GREATER_THAN", separate.outputs["Z"], 154.8))
    side = calculate("MULTIPLY", calculate("GREATER_THAN", y, 19.8),
                     calculate("GREATER_THAN", separate.outputs["Z"], 146.6))
    side = calculate("MULTIPLY", side, calculate("LESS_THAN", separate.outputs["Z"], 150.2))
    ends = calculate("LESS_THAN", calculate("ABSOLUTE", separate.outputs["X"]), 141)
    mask = calculate("MULTIPLY", calculate("MULTIPLY", tick, ends), calculate("MAXIMUM", top, side))
    bsdf = nodes.get("Principled BSDF")
    pigment = nodes.new("ShaderNodeMixRGB")
    pigment.name = "Black ruler ticks, no lettering"
    links.new(mask, pigment.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, pigment.inputs[1])
    pigment.inputs[2].default_value = linear((24, 22, 18))
    links.new(pigment.outputs[0], bsdf.inputs["Base Color"])

    # Rounded plan outline, then a smaller real bevel around the upper rim.
    outline = []
    for sx, sy, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for angle in np.linspace(start, start + 90, 7):
            t = math.radians(angle)
            outline.append((sx * 142 + 8 * math.cos(t), sy * 12 + 8 * math.sin(t)))
    count = len(outline)
    vertices = [(x, y, z) for z in (145, 155) for x, y in outline]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    deck = mesh("Rounded wooden ruler deck", vertices, faces)
    bevel(deck, .6, 2)
    finish(deck, wood, weighted=True)
    assert (bounds(deck)[2] - Vector((300, 40, 10))).length < .01, "Wrong ruler deck size"
    assert abs(bounds(deck)[0].z - 145) < .01, "Wrong deck underside height"

    metal = material("Ruler silver metal edge", (218, 223, 230), roughness=.16, bevel=.05)
    # Follow the rounded ruler ends instead of leaving a straight strip in air
    # beyond the wood. The silver rim is one closed, beveled solid.
    rim = []
    for radius, reverse in ((8.9, False), (7.1, True)):
        edge = []
        for middle, start in ((-142, 180), (142, 270)):
            for angle in np.linspace(start, start + 90, 7):
                t = math.radians(angle)
                edge.append((middle + radius * math.cos(t), -12 + radius * math.sin(t)))
        rim.extend(reversed(edge) if reverse else edge)
    count = len(rim)
    vertices = [(x, y, z) for z in (149.5, 153.7) for x, y in rim]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    strip = mesh("Metal strip wrapped around rounded ruler ends", vertices, faces)
    bevel(strip, .4, 2)
    finish(strip, metal, weighted=True)

    cardboard = material("Ruler corrugated cardboard caps", (186, 146, 91),
                         wood=True, roughness=.72, bevel=.08)
    surface_grain(cardboard, (.4, .4, .4), .12, .035, (.97, 1.03))
    cap_nodes, cap_links = cardboard.node_tree.nodes, cardboard.node_tree.links
    cap_coordinates = next(node for node in cap_nodes if node.type == "TEX_COORD")
    wave = cap_nodes.new("ShaderNodeTexWave")
    wave.wave_type, wave.bands_direction = "BANDS", "X"
    wave.inputs["Scale"].default_value = .28
    wave.inputs["Distortion"].default_value = .3
    cap_links.new(cap_coordinates.outputs["Object"], wave.inputs["Vector"])
    normal = cap_nodes.new("ShaderNodeSeparateXYZ")
    cap_links.new(next(node for node in cap_nodes if node.type == "NEW_GEOMETRY").outputs["Normal"],
                  normal.inputs[0])
    absolute = cap_nodes.new("ShaderNodeMath")
    absolute.operation = "ABSOLUTE"
    cap_links.new(normal.outputs["Z"], absolute.inputs[0])
    wall = cap_nodes.new("ShaderNodeMath")
    wall.operation = "LESS_THAN"
    wall.inputs[1].default_value = .5
    cap_links.new(absolute.outputs[0], wall.inputs[0])
    holes = cap_nodes.new("ShaderNodeMath")
    holes.operation = "GREATER_THAN"
    holes.inputs[1].default_value = .7
    cap_links.new(wave.outputs["Fac"], holes.inputs[0])
    wall_mask = cap_nodes.new("ShaderNodeMath")
    wall_mask.operation = "MULTIPLY"
    cap_links.new(wall.outputs[0], wall_mask.inputs[0])
    cap_links.new(holes.outputs[0], wall_mask.inputs[1])
    cap_bsdf = cap_nodes.get("Principled BSDF")
    cap_paint = cap_nodes.new("ShaderNodeMixRGB")
    cap_paint.name = "Small corrugation marks on cap edges"
    cap_links.new(wall_mask.outputs[0], cap_paint.inputs[0])
    cap_links.new(cap_bsdf.inputs["Base Color"].links[0].from_socket, cap_paint.inputs[1])
    cap_paint.inputs[2].default_value = linear((94, 65, 35))
    cap_links.new(cap_paint.outputs[0], cap_bsdf.inputs["Base Color"])

    colors = [(236, 38, 28), (10, 101, 233), (255, 212, 29)]
    bricks = [material("Ruler toy brick " + color, rgb, roughness=.28, bevel=.12)
              for color, rgb in zip(("red", "blue", "yellow"), colors)]
    for pillar_x in (-140, 140):
        for level in range(6):
            bottom = level * 23.6
            paint = bricks[level % 3]
            box("Stacked toy brick", (24, 45, 22.2), (pillar_x, 0, bottom + 11.1),
                paint, 1.3, 2)
            for stud_x in (-6, 6):
                for stud_y in (-19, 19):
                    top = bottom + 22.2
                    lathe("Molded brick stud", [(3.25, top - .15), (3.25, top + 1.45),
                                                (2.9, top + 1.8)], paint, sectors=12,
                          center=(pillar_x + stud_x, stud_y, 0))
        box("Cardboard bearing cap", (24, 45, 3.4), (pillar_x, 0, 143.3),
            cardboard, .25, 2)


def ruler_bridge_uv(obj):
    """Reserve most of the atlas for the marked deck, with full-width tick UVs."""
    active(obj)
    deck_slot = next(i for i, mat in enumerate(obj.data.materials) if mat.name == "Ruler deck wood")
    cap_slot = next(i for i, mat in enumerate(obj.data.materials)
                    if mat.name == "Ruler corrugated cardboard caps")
    dedicated = {}
    for face in obj.data.polygons:
        if face.material_index == cap_slot:
            if abs(face.normal.x) > .999 or abs(face.normal.y) > .999:
                dedicated[face.index] = "cap"
            continue
        if face.material_index != deck_slot:
            continue
        if face.normal.z > .999:
            dedicated[face.index] = "top"
        elif face.normal.y < -.999:
            dedicated[face.index] = "front"
        elif face.normal.y > .999:
            dedicated[face.index] = "back"
    # Pack the other closed pieces directly into a rectangular lower region.
    # Packing into that actual rectangle keeps a full 10px gutter in both axes.
    bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)
    bpy.context.scene.tool_settings.use_uv_select_sync = False
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for face in obj.data.polygons:
        face.select = face.index not in dedicated
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.average_islands_scale()
    bpy.ops.object.mode_set(mode="OBJECT")
    uv = obj.data.uv_layers.active.data
    other_loops = [index for face in obj.data.polygons if face.index not in dedicated
                   for index in face.loop_indices]
    positions = np.array([uv[index].uv[:] for index in other_loops])
    low, high = positions.min(axis=0), positions.max(axis=0)
    for index in other_loops:
        point = (np.array(uv[index].uv[:]) - low) / (high - low)
        uv[index].uv = (.02 + point[0] * .96, .08 + point[1] * .27)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.pack_islands(udim_source="ORIGINAL_AABB", rotate=True, margin_method="FRACTION", margin=PADDING,
                           shape_method="CONVEX", scale=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    uv = obj.data.uv_layers.active.data
    cap_index = 0
    for face in obj.data.polygons:
        region = dedicated.get(face.index)
        for index in face.loop_indices:
            if region:
                point = obj.data.vertices[obj.data.loops[index].vertex_index].co
                u = .02 + (point.x + 150) / 300 * .96
                if region == "cap":
                    horizontal = (point.y + 22.5) / 45 if abs(face.normal.x) > .999 else \
                        (point.x - (-140 if point.x < 0 else 140) + 12) / 24
                    u = .025 + cap_index * .12 + horizontal * .10
                    v = .02 + (point.z - 141.6) / 3.4 * .035
                elif region == "top":
                    v = .57 + (point.y + 20) / 40 * .41
                else:
                    v = (.37 if region == "front" else .47) + (point.z - 145) / 10 * .08
                uv[index].uv = (u, v)
        if region == "cap":
            cap_index += 1
    assert cap_index == 8, "Need four sharp cardboard sides per pillar"
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.object.mode_set(mode="OBJECT")


def school_book(name, width, depth, height, location, color):
    """Closed page block, two rounded covers and a spine facing the pupil."""
    x, y, z = location
    cover = material(name + " cloth cover", color, roughness=.66, bevel=.08)
    pages = material("School book ivory pages", (247, 242, 220), roughness=.86, bevel=.04)
    surface_grain(pages, (.25, .25, 5), .12, .018, (.97, 1.025))
    box(name + " page block", (width - 3, depth - 2, height - 1.8),
        (x, y - .5, z + height / 2), pages, .45, 2)
    for level in (.45, height - .45):
        box(name + " cover", (width, depth, .9), (x, y, z + level), cover, .35, 2)
    box(name + " spine", (width, 1.4, height - .8),
        (x, y + depth / 2 - .7, z + height / 2), cover, .35, 2)


def school_desk():
    """Exact landing slab, open metal frame and a rear-facing book cubby."""
    wood = material("School desk light maple", (227, 197, 148), wood=True, roughness=.42, bevel=.22)
    surface_grain(wood, (.025, .16, .02), .13, .055, (.91, 1.07))
    metal = material("School furniture grey enamel steel", (132, 145, 157), roughness=.36, bevel=.10)
    metal.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .65
    rubber = material("School furniture dark foot caps", (56, 65, 74), roughness=.76, bevel=.08)
    tray = material("School desk light grey cubby", (166, 178, 185), roughness=.48, bevel=.12)
    tray.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .35

    # Cut an actual shallow capsule groove. It never rises above the slab.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 102))
    top = bpy.context.object
    top.name = "Maple landing top 330 x 210 x 12"
    top.dimensions = (330, 210, 12)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(top, 4, 3)
    profile = [(-121, .04), (-120, 2.55), (-118, 3.6),
               (118, 3.6), (120, 2.55), (121, .04)]
    sectors = 16
    vertices = [(x, -82 + r * math.cos(j * math.tau / sectors),
                 108.6 + r * math.sin(j * math.tau / sectors))
                for x, r in profile for j in range(sectors)]
    faces = [tuple(reversed(range(sectors))),
             tuple((len(profile) - 1) * sectors + j for j in range(sectors))]
    for row in range(len(profile) - 1):
        for j in range(sectors):
            k = (j + 1) % sectors
            faces.append((row * sectors + j, row * sectors + k,
                          (row + 1) * sectors + k, (row + 1) * sectors + j))
    cutter = mesh("Temporary pencil groove cutter", vertices, faces)
    clean_mesh(cutter)
    mod = top.modifiers.new("Recessed pencil groove", "BOOLEAN")
    mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter
    apply(top, mod)
    bpy.data.objects.remove(cutter, do_unlink=True)
    clean_mesh(top)
    finish(top, wood, weighted=True)
    lo, hi, size = bounds(top)
    assert (size - Vector((330, 210, 12))).length < .001 and abs(hi.z - 108) < .001

    for x in (-150, 150):
        for y in (-90, 90):
            lathe("Grey steel desk leg", [(3.8, 2), (3.8, 96)], metal,
                  sectors=12, center=(x, y, 0))
            lathe("Rounded desk foot cap", [(4.8, 0), (5.5, .7), (5.5, 2.8), (4.9, 3.4)],
                  rubber, sectors=12, center=(x, y, 0))
    for y in (-90, 90):
        tube("Desk width support tube", [(-150, y, 91), (150, y, 91)], 4, metal, sides=12)
    for x in (-150, 150):
        tube("Desk side support tube", [(x, -90, 91), (x, 90, 91)], 4, metal, sides=12)

    box("Open cubby bottom", (248, 78, 3), (0, 44, 67), tray, .7, 2)
    box("Cubby closed back toward -Y", (248, 3, 28), (0, 6.5, 81), tray, .7, 2)
    for x in (-122.5, 122.5):
        box("Cubby side", (3, 78, 28), (x, 44, 81), tray, .7, 2)
    for index, color in enumerate(((208, 57, 51), (64, 149, 79), (42, 113, 194))):
        school_book("Cubby book " + str(index + 1), 112 - index * 3, 65 - index * 2,
                    7, (-58 + index * 2, 44, 68.5 + index * 7), color)

    paper = material("School notebook cream paper", (251, 244, 218), roughness=.86, bevel=.04)
    orange = material("School notebook orange cover", (242, 156, 45), roughness=.65, bevel=.06)
    blue = material("School notebook blue ruling", (107, 153, 189), roughness=.86, bevel=.01)
    wire = material("School notebook binding wire", (84, 98, 109), roughness=.38, bevel=.02)
    box("Notebook orange backing", (92, 64, 1), (67, 44, 69), orange, .4, 2)
    box("Notebook page block", (89, 62, 4), (67, 44, 71.5), paper, .4, 2)
    for y in (24, 33, 42, 51, 60):
        box("Notebook blue line", (69, .28, .08), (71, y, 73.54), blue, 0)
        points = [(24.5 + 2.1 * math.cos(t), y, 72 + 2.1 * math.sin(t))
                  for t in np.linspace(0, math.tau * .92, 10)]
        tube("Notebook spiral", points, .42, wire, sides=6)


def school_chair():
    """Bright moulded seat and back, on four steel legs with floor caps."""
    blue = material("School chair bright blue moulded plastic", (24, 126, 219), roughness=.36, bevel=.18)
    surface_grain(blue, (.7, .7, .7), .06, .012, (.985, 1.015))
    metal = material("School furniture grey enamel steel", (132, 145, 157), roughness=.36, bevel=.10)
    metal.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = .65
    rubber = material("School furniture dark foot caps", (56, 65, 74), roughness=.76, bevel=.08)
    contour = []
    for sx, sy, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for angle in np.linspace(start, start + 90, 5):
            t = math.radians(angle)
            contour.append((sx * 45 + 10 * math.cos(t), sy * 40 + 10 * math.sin(t)))
    n = len(contour)
    # Rolled perimeter, with a broad level sitting surface at exactly Z=90.
    rings = ((.94, 80), (1, 84), (1, 87), (.96, 89.5), (.86, 90))
    vertices = [(x * scale, y * scale, z) for scale, z in rings for x, y in contour]
    faces = [tuple(reversed(range(n))), tuple((len(rings) - 1) * n + j for j in range(n))]
    for row in range(len(rings) - 1):
        for j in range(n):
            k = (j + 1) % n
            faces.append((row * n + j, row * n + k, (row + 1) * n + k, (row + 1) * n + j))
    seat = finish(mesh("Moulded blue seat 110 x 100", vertices, faces), blue, weighted=True)
    assert (bounds(seat)[2] - Vector((110, 100, 10))).length < .001
    back = [(-46, 44, 114), (-51, 49, 153), (-48, 55, 194), (-40, 56, 200),
            (40, 56, 200), (48, 55, 194), (51, 49, 153), (46, 44, 114)]
    backrest = panel("Rounded blue school chair backrest", back, 5, blue, radius=4)
    backrest.location.z = 200 - bounds(backrest)[1].z
    for x in (-43, 43):
        for y in (-39, 39):
            tube("School chair steel leg", [(x, y, 2.5), (x * .93, y * .87, 83)],
                 3.2, metal, sides=12)
            lathe("School chair foot cap", [(3.8, 0), (4.6, .8), (4.6, 2.7), (3.8, 3.4)],
                  rubber, sectors=12, center=(x, y, 0))
        tube("Chair backrest steel support", [(x * .93, 33.9, 81), (x * .93, 49, 109),
                                              (x * .93, 61.5, 188)], 3.2, metal, sides=12)
        tube("Chair seat side rail", [(x * .93, -34, 81), (x * .93, 34, 81)],
             3.2, metal, sides=12)
    tube("Chair front seat rail", [(-40, -34, 81), (40, -34, 81)], 3.2, metal, sides=12)
    tube("Chair rear seat rail", [(-40, 34, 81), (40, 34, 81)], 3.2, metal, sides=12)


def schoolyard_steel(name, color, metallic=.35):
    """Quiet powder-coat grain at classroom scale, with a baked metalness map."""
    mat = material(name, color, roughness=.4, bevel=.28)
    surface_grain(mat, (.22, .22, .22), .055, .018, (.985, 1.015))
    mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = metallic
    return mat


def schoolyard_loop(name, points, radius, mat, sides=6):
    """Closed swept cord/link/rim; both UV seams keep the torus unwrap open."""
    points = [Vector(point) for point in points]
    count = len(points)
    vertices, faces = [], []
    for i, point in enumerate(points):
        tangent = (points[(i + 1) % count] - points[i - 1]).normalized()
        # Every supplied loop is planar. Its plane normal is the stable frame.
        plane = (points[1] - points[0]).cross(points[2] - points[1]).normalized()
        outward = tangent.cross(plane).normalized()
        for j in range(sides):
            angle = math.tau * j / sides
            vertices.append(point + radius * (outward * math.cos(angle) + plane * math.sin(angle)))
    for i in range(count):
        for j in range(sides):
            faces.append((i * sides + j, i * sides + (j + 1) % sides,
                          ((i + 1) % count) * sides + (j + 1) % sides,
                          ((i + 1) % count) * sides + j))
    obj = mesh(name, vertices, faces)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % sides == b % sides == 0 or a // sides == b // sides == 0)
    return finish(obj, mat, uv="unwrap")


def schoolyard_foot(name, x, y, mat, width=50):
    return box(name, (width, width, 10), (x, y, 5), mat, 3, 2)


def jungle_gym():
    """Roofed deck, open monkey bars, short ladder and a real side rope grid."""
    red = schoolyard_steel("Schoolyard red powder coat", (226, 58, 48))
    blue = schoolyard_steel("Schoolyard blue powder coat", (29, 121, 207))
    green_roof = material("Jungle gym green moulded roof", (64, 159, 77), roughness=.46, bevel=.3)
    yellow = material("Jungle gym yellow moulded deck", (252, 196, 40), roughness=.43, bevel=.3)
    rope = material("Jungle gym warm rope", (233, 212, 162), roughness=.85, bevel=.04)
    surface_grain(rope, (.7, .7, .7), .12, .035, (.97, 1.03))
    dark = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    posts = [(-375, -275, 302), (-375, 275, 302),
             (95, -150, 446), (95, 275, 446), (375, -150, 446), (375, 275, 446)]
    for index, (x, y, top) in enumerate(posts):
        paint = red if index % 2 else blue
        schoolyard_foot("Jungle gym anchored foot", x, y, dark)
        tube("Jungle gym round upright", [(x, y, 6), (x, y, top)], 12, paint, sides=16)
        lathe("Jungle gym upper joint collar", [(12.3, top - 24), (15, top - 22), (15, top - 7)],
              blue, sectors=12, center=(x, y, 0))
    box("Jungle gym yellow deck", (310, 440, 14), (235, 60, 263), yellow, 5, 2)
    pitched_roof("Jungle gym small green roof", 170, 470, 448, 500, green_roof,
                 thickness=12, center=(230, 65, 0), radius=2, segments=2)
    for y in (-275, 275):
        tube("Monkey bar long blue rail", [(-375, y, 292), (95, y, 292)], 10, blue, sides=16)
    tube("Monkey bar front deck connection", [(95, -275, 292), (95, -150, 292)],
         10, blue, sides=16)
    for x in np.linspace(-335, 55, 6):
        tube("Monkey bar red cross rung", [(x, -275, 292), (x, 275, 292)], 9, red, sides=16)
    tube("Monkey bar end cross rail", [(-375, -275, 292), (-375, 275, 292)], 10, blue, sides=16)
    for x in (95, 375):
        tube("Tower blue side guardrail", [(x, -150, 365), (x, 275, 365)], 9, blue, sides=16)
        for y in (-75, 35, 145, 240):
            tube("Tower blue guard upright", [(x, y, 269), (x, y, 365)], 6, blue, sides=12)
    tube("Tower rear red guardrail", [(95, 275, 365), (375, 275, 365)], 9, red, sides=16)
    for x in (165, 235, 305):
        tube("Tower rear blue guard upright", [(x, 275, 269), (x, 275, 365)], 6, blue, sides=12)
    # Entrance is open between the two bent handrails, with six broad treads.
    for x in (155, 315):
        schoolyard_foot("Jungle gym ladder foot", x, -275, dark, width=30)
        tube("Jungle gym red ladder and grab rail",
             [(x, -275, 12), (x, -152, 264), (x, -150, 343), (x, -112, 355)],
             9, red, sides=16)
    for t in np.linspace(.12, .94, 6):
        box("Jungle gym yellow ladder tread", (158, 30, 10),
            (235, -275 + 123 * t, 12 + 252 * t), yellow, 3, 2)
    tube("Rope net lower frame", [(-375, -275, 34), (-375, 275, 34)], 9, red, sides=16)
    # Slight bow puts the crossing ropes on distinct planes, without a solid wall.
    for y in np.linspace(-250, 250, 7):
        points = [(-373 + 3 * math.sin(math.pi * t), y, 40 + 242 * t)
                  for t in np.linspace(0, 1, 5)]
        tube("Jungle gym vertical climbing rope", points, 3, rope, sides=6)
    for z in np.linspace(40, 282, 5):
        points = [(-369, -260 + 520 * t, z - 3 * math.sin(math.pi * t))
                  for t in np.linspace(0, 1, 5)]
        tube("Jungle gym horizontal climbing rope", points, 3, rope, sides=6)


def swing_set():
    """Braced green A-frames, two rubber seats and four alternating link chains."""
    green_frame = schoolyard_steel("Swing green powder coat", (53, 151, 75))
    steel = schoolyard_steel("Swing galvanized chains", (185, 194, 199), metallic=.82)
    rubber = material("Swing charcoal rubber seats", (44, 51, 55), roughness=.8, bevel=.12)
    foot = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    for side in (-1, 1):
        for y in (-125, 125):
            schoolyard_foot("Swing anchored foot", side * 325, y, foot)
            tube("Swing green A-frame leg", [(side * 325, y, 10), (side * 298, 0, 461)],
                 14, green_frame, sides=20)
        tube("Swing A-frame cross brace", [(side * 317, -87, 147), (side * 317, 87, 147)],
             9, green_frame, sides=16)
        tube("Swing top diagonal stabilizer", [(side * 298, 0, 371), (side * 225, 0, 462)],
             9, green_frame, sides=16)
    tube("Swing continuous overhead bar", [(-336, 0, 466), (336, 0, 466)],
         14, green_frame, sides=20)
    for center_x in (-140, 140):
        box("Swing rounded rubber seat", (136, 64, 12), (center_x, 0, 106), rubber, 5, 3)
        for x in (center_x - 53, center_x + 53):
            hanger = [(x, 19 * math.cos(t), 462 + 19 * math.sin(t))
                      for t in np.linspace(0, math.tau, 10, endpoint=False)]
            schoolyard_loop("Swing bar hanger", hanger, 3, steel, sides=6)
            for index in range(12):
                angle = ((index + 1) % 2) * math.pi / 2
                z = 122 + index * 28.5
                points = [(x + 8 * math.cos(t) * math.cos(angle),
                           8 * math.cos(t) * math.sin(angle), z + 18 * math.sin(t))
                          for t in np.linspace(0, math.tau, 10, endpoint=False)]
                schoolyard_loop("Swing alternating steel chain link", points, 2.4, steel, sides=4)
            for y in (-17, 17):
                lathe("Swing seat fixing bolt", [(3, 111), (3, 115)], steel, sectors=8,
                      center=(x, y, 0))


def seesaw():
    """Level red rocker, yellow triangular fulcrum, two seats and rounded grips."""
    red = material("Seesaw red moulded plank", (226, 58, 48), roughness=.4, bevel=.25)
    yellow = schoolyard_steel("Seesaw yellow powder coat", (252, 196, 40))
    blue = material("Seesaw blue moulded seats", (29, 121, 207), roughness=.43, bevel=.25)
    steel = schoolyard_steel("Seesaw galvanized axle", (185, 194, 199), metallic=.82)
    rubber = material("Seesaw soft rubber bumpers", (44, 51, 55), roughness=.8, bevel=.1)
    box("Seesaw yellow anchored base", (140, 80, 10), (0, 0, 5), yellow, 4, 3)
    for y in (-23, 23):
        pivot = extruded_profile("Seesaw yellow triangular pivot",
                                 [(-57, 10), (57, 10), (0, 100)], -5, 5, yellow, 4, 3)
        pivot.rotation_euler.z = math.pi / 2
        pivot.location.y = y
    tube("Seesaw transverse steel pivot axle", [(0, -36, 93), (0, 36, 93)], 12, steel, sides=32)
    for side in (-1, 1):
        tube("Seesaw blue pivot bearing", [(0, side * 28, 93), (0, side * 34, 93)],
             16, blue, sides=32)
    box("Seesaw long red rounded plank", (600, 64, 14), (0, 0, 102), red, 6, 4)
    for side in (-1, 1):
        box("Seesaw rounded blue seat", (60, 72, 9), (side * 264, 0, 113.5), blue, 4, 4)
        ball("Seesaw rubber landing bumper", (side * 264, 0, 77), 20, rubber,
             segments=16, rings=8, scale=(1, 1, .85))
        x = side * 215
        grab = [(x, -23, 109), (x, -23, 131)]
        grab += [(x, 23 * math.cos(t), 131 + 23 * math.sin(t))
                 for t in np.linspace(math.pi, 0, 13)[1:]]
        grab.append((x, 23, 109))
        tube("Seesaw yellow rounded seat handle", grab, 6, yellow, sides=20)
        for y in (-21, 21):
            lathe("Seesaw inset seat fastening", [(3, 118), (3, 120)], steel,
                  sectors=20, center=(side * 267, y, 0))


def merry_go_round():
    """Blue spinning deck with bright sector inserts and three curved grab rails."""
    blue = schoolyard_steel("Roundabout blue powder coat", (29, 121, 207))
    yellow = schoolyard_steel("Roundabout yellow powder coat", (252, 196, 40))
    red = schoolyard_steel("Roundabout red powder coat", (226, 58, 48))
    steel = schoolyard_steel("Roundabout galvanized hub", (185, 194, 199), metallic=.82)
    lathe("Roundabout anchored bearing pedestal", [(54, 0), (54, 8), (42, 12), (34, 32)],
          steel, sectors=32)
    lathe("Roundabout thick blue round platform",
          [(188, 25), (198, 28), (200, 33), (200, 39), (196, 44), (188, 45)], blue, sectors=64)
    for index in range(6):
        start, end = index * math.pi / 3 + .035, (index + 1) * math.pi / 3 - .035
        outline = [(r * math.cos(t), r * math.sin(t), 46)
                   for r, angles in ((32, np.linspace(end, start, 11)),
                                     (187, np.linspace(start, end, 11))) for t in angles]
        panel("Roundabout flush coloured deck segment", outline, 1,
              (yellow, red, blue)[index % 3], radius=0)
    lathe("Roundabout blue centre post", [(12, 44), (12, 173), (10, 177)], blue, sectors=24)
    lathe("Roundabout rounded yellow centre cap",
          [(10, 166), (15, 168), (16, 172), (14, 178), (9, 180)], yellow, sectors=24)
    for index in range(3):
        center_angle = index * math.tau / 3
        first, last = center_angle - .54, center_angle + .54
        points = [(145 * math.cos(first), 145 * math.sin(first), 46),
                  (145 * math.cos(first), 145 * math.sin(first), 119)]
        points += [(145 * math.cos(first + .1 * (1 - math.cos(t))),
                    145 * math.sin(first + .1 * (1 - math.cos(t))), 119 + 27 * math.sin(t))
                   for t in np.linspace(0, math.pi / 2, 5)[1:]]
        points += [(145 * math.cos(t), 145 * math.sin(t), 146)
                   for t in np.linspace(first + .1, last - .1, 16)[1:]]
        points += [(145 * math.cos(last - .1 + .1 * math.sin(t)),
                    145 * math.sin(last - .1 + .1 * math.sin(t)), 119 + 27 * math.cos(t))
                   for t in np.linspace(0, math.pi / 2, 5)[1:]]
        points.append((145 * math.cos(last), 145 * math.sin(last), 46))
        tube("Roundabout curved outer hand rail", points, 7, (yellow, red, yellow)[index], sides=12)
        # A radial stay joins each outer rail to the actual centre post.
        tube("Roundabout blue radial rail stay",
             [(12 * math.cos(center_angle), 12 * math.sin(center_angle), 146),
              (145 * math.cos(center_angle), 145 * math.sin(center_angle), 146)], 5, blue, sides=12)
        for t in (first, last):
            x, y = 145 * math.cos(t), 145 * math.sin(t)
            lathe("Roundabout rail mounting socket", [(10, 45), (11, 48), (11, 55), (7, 58)],
                  blue, sectors=12, center=(x, y, 0))


def spring_rider():
    """Friendly side-profile duck, broad seat, real steel helix and anchored plate."""
    green_duck = material("Spring duck cheerful green plastic", (64, 159, 77), roughness=.43, bevel=.2)
    wing = material("Spring duck lighter green wings", (102, 184, 80), roughness=.44, bevel=.18)
    yellow = material("Spring duck yellow saddle", (252, 196, 40), roughness=.43, bevel=.2)
    orange = material("Spring duck orange beak", (241, 111, 36), roughness=.43, bevel=.15)
    blue = schoolyard_steel("Spring rider blue spring steel", (29, 121, 207), metallic=.55)
    steel = schoolyard_steel("Spring rider galvanized fixings", (185, 194, 199), metallic=.82)
    white = material("Spring duck cream eyes", (249, 247, 232), roughness=.46, bevel=.08)
    black = material("Spring duck black pupils and grips", (36, 42, 43), roughness=.7, bevel=.06)
    box("Spring rider flat anchored base plate", (88, 60, 8), (0, 0, 4), blue, 3, 2)
    box("Spring rider upper mounting plate", (40, 34, 6), (0, 0, 83), blue, 2, 2)
    coil = [(16 * math.cos(t), 16 * math.sin(t), 14 + 65 * t / (math.tau * 5))
            for t in np.linspace(0, math.tau * 5, 81)]
    tube("Spring rider thick five-turn coil", coil, 4.5, blue, sides=6)
    tube("Spring rider lower spring clamp", [(16, 0, 8), (16, 0, 14)], 4.5, blue, sides=8)
    tube("Spring rider upper spring clamp", [(16, 0, 79), (16, 0, 85)], 4.5, blue, sides=8)
    ball("Spring duck rounded green body", (10, 0, 111), 42, green_duck,
         segments=16, rings=10, scale=(1, .49, .62))
    ball("Spring duck rounded green head", (-29, 0, 147), 23, green_duck,
         segments=16, rings=10, scale=(1, .65, 1))
    ball("Spring duck orange broad beak", (-49, 0, 143), 11, orange,
         segments=12, rings=6, scale=(1, 1.05, .45))
    ball("Spring duck raised green tail", (45, 0, 120), 15, green_duck,
         segments=12, rings=6, scale=(1, .7, .6))
    for side in (-1, 1):
        ball("Spring duck moulded wing", (14, side * 18, 111), 17, wing,
             segments=12, rings=6, scale=(1, .23, .6))
        ball("Spring duck large cream eye", (-34, side * 13.8, 153), 6, white,
             segments=12, rings=6, scale=(1, .35, 1))
        ball("Spring duck cheerful eye pupil", (-35.5, side * 15.7, 153), 3, black,
             segments=10, rings=5, scale=(1, .35, 1))
    box("Spring duck broad yellow seat", (39, 52, 7), (13, 0, 134), yellow, 3, 3)
    tube("Spring duck transverse grab handle", [(-18, -26, 134), (-18, 26, 134)],
         3.5, steel, sides=12)
    tube("Spring duck transverse foot bar", [(0, -26, 91), (0, 26, 91)], 4, steel, sides=12)
    for side in (-1, 1):
        tube("Spring duck rubber handle grip", [(-18, side * 19, 134), (-18, side * 26, 134)],
             4.5, black, sides=12)
        tube("Spring duck rubber foot rest", [(0, side * 19, 91), (0, side * 26, 91)],
             5, black, sides=12)


def monkey_bars():
    """Two open end ladders joined by a nine-rung horizontal ladder."""
    blue = schoolyard_steel("Monkey bars blue powder coat", (29, 121, 207))
    yellow = schoolyard_steel("Monkey bars yellow powder coat", (252, 196, 40))
    dark = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    for x in (-280, 280):
        for y in (-55, 55):
            schoolyard_foot("Monkey bars anchored foot", x, y, dark, width=40)
            tube("Monkey bars blue ladder upright", [(x, y, 10), (x, y, 408)],
                 12, blue, sides=24)
            lathe("Monkey bars rounded top joint collar",
                  [(12, 383), (15, 386), (15, 400), (12, 404)],
                  blue, sectors=24, center=(x, y, 0))
        for z in np.linspace(60, 390, 7):
            tube("Monkey bars yellow end ladder rung", [(x, -55, z), (x, 55, z)],
                 8, yellow, sides=20)
    for y in (-55, 55):
        tube("Monkey bars long blue upper rail", [(-280, y, 408), (280, y, 408)],
             12, blue, sides=24)
    for x in np.linspace(-224, 224, 9):
        tube("Monkey bars yellow overhead cross rung", [(x, -55, 408), (x, 55, 408)],
             8, yellow, sides=20)


def schoolyard_chain(name, start, end, links, mat):
    """Alternating closed steel links along a straight, possibly slanted chain."""
    start, end = Vector(start), Vector(end)
    delta = end - start
    axis = delta.normalized()
    across = axis.cross(Vector((0, 1, 0))).normalized()
    other = axis.cross(across).normalized()
    step = delta.length / links
    for index in range(links):
        center = start + delta * ((index + .5) / links)
        transverse = across if index % 2 else other
        points = [center + transverse * (7 * math.cos(t)) + axis * (step * .64 * math.sin(t))
                  for t in np.linspace(0, math.tau, 10, endpoint=False)]
        schoolyard_loop(name, points, 2.4, mat, sides=4)


def tire_swing():
    """Orange braced A-frame and three slanted link chains holding a flat tyre."""
    orange = schoolyard_steel("Tire swing orange powder coat", (241, 111, 36))
    steel = schoolyard_steel("Tire swing galvanized chains", (185, 194, 199), metallic=.82)
    rubber = material("Tire swing charcoal tyre rubber", (36, 42, 43), roughness=.85, bevel=.1)
    surface_grain(rubber, (.5, .5, .5), .12, .045, (.95, 1.05))
    foot = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    for side in (-1, 1):
        for y in (-125, 125):
            schoolyard_foot("Tire swing anchored foot", side * 225, y, foot)
            tube("Tire swing orange A-frame leg", [(side * 225, y, 10), (side * 214, 0, 461)],
                 14, orange, sides=20)
        tube("Tire swing A-frame cross brace", [(side * 222, -85, 156), (side * 222, 85, 156)],
             9, orange, sides=16)
        tube("Tire swing upper diagonal stabilizer", [(side * 214, 0, 367), (side * 170, 0, 462)],
             9, orange, sides=16)
    tube("Tire swing continuous overhead bar", [(-236, 0, 466), (236, 0, 466)],
         14, orange, sides=20)
    lathe("Tire swing hollow flat tyre",
          [(50, 100), (53, 93), (63, 89), (92, 89), (103, 96), (105, 101),
           (102, 105), (105, 109), (103, 121), (92, 130), (63, 130), (53, 125), (50, 117)],
          rubber, sectors=48, closed=True)
    for angle in (-math.pi / 2, math.pi / 6, 5 * math.pi / 6):
        x, y = 82 * math.cos(angle), 82 * math.sin(angle)
        hanger = [(x, 19 * math.cos(t), 462 + 19 * math.sin(t))
                  for t in np.linspace(0, math.tau, 10, endpoint=False)]
        schoolyard_loop("Tire swing overhead chain hanger", hanger, 3, steel, sides=6)
        eye = [(x + 7 * math.cos(t) * math.cos(angle),
                y + 7 * math.cos(t) * math.sin(angle), 133 + 10 * math.sin(t))
               for t in np.linspace(0, math.tau, 10, endpoint=False)]
        schoolyard_loop("Tire swing tyre attachment eye", eye, 3, steel, sides=6)
        schoolyard_chain("Tire swing alternating steel chain link", (x, y, 136), (x, 0, 447), 12, steel)


def crawl_tunnel():
    """Open red plastic barrel, two thick yellow entry rings and low blue cradle."""
    red = material("Tunnel red moulded plastic", (226, 58, 48), roughness=.43, bevel=.25)
    yellow = material("Tunnel yellow moulded entry rings", (252, 196, 40), roughness=.43, bevel=.25)
    blue = schoolyard_steel("Tunnel blue powder coat", (29, 121, 207))
    dark = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    lathe("Tunnel continuous open red barrel",
          [(68, -192), (70, -189), (70, 189), (68, 192), (64, 192),
           (62, 189), (62, -189), (64, -192)], red,
          sectors=64, center=(0, 0, 85), axis="X", closed=True)
    rim = [(70, -200), (74, -198), (75, -195), (74, -190), (70, -187),
           (62, -187), (60, -190), (60, -197), (62, -200)]
    for side in (-1, 1):
        # Reflecting a profile also reverses its analytic shading normals.
        # Reverse its traversal to keep both yellow rims shaded outward.
        profile = [(r, side * x) for r, x in (reversed(rim) if side < 0 else rim)]
        lathe("Tunnel thick yellow open entry ring", profile,
              yellow, sectors=48, center=(0, 0, 85), axis="X", closed=True)
    for x in (-125, 125):
        for y in (-60, 60):
            schoolyard_foot("Tunnel anchored frame foot", x, y, dark, width=40)
            tube("Tunnel short blue cradle upright", [(x, y, 8), (x, y, 44)], 8, blue, sides=16)
        tube("Tunnel blue low cross brace", [(x, -60, 15), (x, 60, 15)], 6, blue, sides=16)
        saddle = [(x, 72 * math.sin(t), 85 - 72 * math.cos(t))
                  for t in np.linspace(-.98, .98, 15)]
        tube("Tunnel curved blue supporting cradle", saddle, 4, blue, sides=8)


def schoolyard_slide_chute(mat):
    """A sealed U-shaped plastic chute with smooth level entry and run-out."""
    controls = [Vector((-230, 0, 332)), Vector((-95, 0, 332)),
                Vector((100, 0, 18)), Vector((400, 0, 18))]
    section = [(-80, 36), (-78, 43), (-69, 46), (-61, 40), (-56, 17), (-48, 9),
               (-30, 4), (0, 2), (30, 4), (48, 9), (56, 17), (61, 40),
               (69, 46), (78, 43), (80, 36), (74, 30), (71, 10), (62, -1),
               (40, -6), (0, -8), (-40, -6), (-62, -1), (-71, 10), (-74, 30)]
    vertices, faces = [], []
    rows, count = 44, len(section)
    for t in np.linspace(0, 1, rows):
        t = float(t)
        a, b, c, d = controls
        point = (1 - t) ** 3 * a + 3 * (1 - t) ** 2 * t * b + 3 * (1 - t) * t ** 2 * c + t ** 3 * d
        tangent = (3 * (1 - t) ** 2 * (b - a) + 6 * (1 - t) * t * (c - b) +
                   3 * t ** 2 * (d - c)).normalized()
        normal = Vector((-tangent.z, 0, tangent.x))
        vertices += [point + Vector((0, y, 0)) + normal * z for y, z in section]
    for row in range(rows - 1):
        for j in range(count):
            k = (j + 1) % count
            faces.append((row * count + j, row * count + k,
                          (row + 1) * count + k, (row + 1) * count + j))
    faces += [tuple(reversed(range(count))), tuple((rows - 1) * count + j for j in range(count))]
    obj = mesh("Slide continuous yellow U-shaped chute", vertices, faces)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % count == b % count == 0 or
                         a // count == b // count and a // count in (0, rows - 1))
    return finish(obj, mat, uv="unwrap")


def slide():
    """X-length slide, chunky yellow chute, eight ladder treads and blue rails."""
    blue = schoolyard_steel("Slide blue powder coat", (31, 127, 207))
    red = schoolyard_steel("Slide red ladder powder coat", (222, 65, 49))
    yellow = material("Slide golden yellow moulded plastic", (252, 195, 33), roughness=.32, bevel=.25)
    dark = material("Schoolyard dark rubber feet", (58, 68, 67), roughness=.8, bevel=.1)
    schoolyard_slide_chute(yellow)
    box("Slide small yellow entry platform", (66, 146, 12), (-263, 0, 328), yellow, 4, 2)
    for x in (-378, 378):
        for y in (-58, 58):
            schoolyard_foot("Slide floor anchor", x, y, dark, width=44)
    for y in (-58, 58):
        schoolyard_foot("Slide platform foot", -285, y, dark, width=30)
        tube("Slide platform upright", [(-285, y, 10), (-285, y, 334)], 9, blue, sides=16)
        tube("Slide low exit support", [(378, y, 8), (378, y, 20)], 7, blue, sides=16)
        tube("Slide red ladder rail", [(-378, y, 12), (-290, y, 330)], 10, red, sides=16)
        grab = [(-328, y, 193), (-304, y, 360), (-304, y, 398)]
        grab += [(-276 + 28 * math.cos(t), y, 398 + 28 * math.sin(t))
                 for t in np.linspace(math.pi, math.pi / 2, 5)[1:]]
        grab.append((-250, y, 426))
        grab += [(-250 + 28 * math.cos(t), y, 398 + 28 * math.sin(t))
                 for t in np.linspace(math.pi / 2, 0, 5)[1:]]
        tube("Slide blue rounded continuous handrail", grab, 13, blue, sides=16)
        for x in (-281, -258, -236):
            tube("Slide platform guard upright", [(x, y, 334), (x, y, 414)], 5, blue, sides=12)
    for t in np.linspace(.1, .96, 8):
        box("Slide broad red ladder tread", (29, 116, 10),
            (-378 + 88 * t, 0, 12 + 318 * t), red, 3, 2)
    tube("Slide platform rear safety rail", [(-294, -58, 370), (-294, 58, 370)],
         8, blue, sides=16)


def basketball_hoop():
    """Weighted base, supported white board, painted target and an open net."""
    grey = schoolyard_steel("Basketball grey galvanized pole", (150, 163, 174), metallic=.65)
    orange = schoolyard_steel("Basketball orange coated rim", (241, 111, 36), metallic=.25)
    white = material("Basketball white backboard", (245, 244, 232), roughness=.48, bevel=.18)
    # Flat painted target survives the bake without tiny raised decal geometry.
    paint_regions(white, (214, 58, 47), [(("X", "Z"), (0, 485), (57, 45), 4, "Y", 40)])
    paint_regions(white, (245, 244, 232), [(("X", "Z"), (0, 485), (50, 38), 2, "Y", 40)])
    rope = material("Basketball white net cord", (247, 243, 224), roughness=.87, bevel=.035)
    surface_grain(rope, (.9, .9, .9), .08, .025, (.98, 1.02))
    base = material("Basketball dark weighted base", (76, 89, 98), roughness=.63, bevel=.16)
    box("Basketball broad weighted base", (174, 200, 18), (0, 0, 9), base, 5, 2)
    box("Basketball pole socket", (48, 48, 30), (0, 60, 29), grey, 5, 2)
    lathe("Basketball upright grey pole", [(12, 18), (14, 22), (14, 42), (11, 49), (11, 547)],
          grey, sectors=20, center=(0, 60, 0))
    box("Basketball rounded white backboard", (360, 12, 220), (0, 50, 530), white, 8, 3)
    for x in (-55, 55):
        tube("Basketball backboard diagonal bracket", [(0, 60, 450), (x, 57, 525)], 6, grey, sides=16)
    box("Basketball orange rim mounting plate", (28, 16, 20), (0, 36, 432), orange, 3, 2)
    points = [(65 * math.cos(t), -35 + 65 * math.sin(t), 432)
              for t in np.linspace(0, math.tau, 40, endpoint=False)]
    schoolyard_loop("Basketball full orange rim", points, 4, orange, sides=10)
    for direction in (-1, 1):
        for index in range(12):
            theta = index * math.tau / 12
            points = []
            for t in np.linspace(0, 1, 8):
                angle = theta + direction * t * math.tau / 6
                radius = 60 - 24 * t
                points.append((radius * math.cos(angle), -35 + radius * math.sin(angle), 428 - 88 * t))
            tube("Basketball diagonal white net strand", points, 1.8, rope, sides=6)
    for radius, z in ((60, 428), (36, 340)):
        points = [(radius * math.cos(t), -35 + radius * math.sin(t), z)
                  for t in np.linspace(0, math.tau, 24, endpoint=False)]
        schoolyard_loop("Basketball white net binding", points, 1.8, rope, sides=6)
    for x in (-154, 154):
        for z in (438, 622):
            ball("Basketball orange board fastener", (x, 43, z), 3, orange,
                 segments=8, rings=4, scale=(1, .45, 1), front_axis=False)
    for x in (-58, 58):
        for y in (-68, 68):
            lathe("Basketball base fixing bolt", [(4, 17), (4, 21)], grey, sectors=12, center=(x, y, 0))


def fence_wire_material():
    """Opaque pale green panel with baked diagonal wire pigment and relief."""
    mat = material("Fence opaque green diamond mesh paint", (147, 190, 144), roughness=.64, bevel=.02)
    surface_grain(mat, (.2, .2, .2), .04, .015, (.99, 1.01))
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], xyz.inputs[0])

    def calculate(operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)):
                    node.inputs[index].default_value = value
                else:
                    links.new(value, node.inputs[index])
        return node.outputs[0]

    wires = []
    for operation in ("ADD", "SUBTRACT"):
        diagonal = calculate(operation, xyz.outputs["X"], xyz.outputs["Z"])
        sine = calculate("SINE", calculate("MULTIPLY", diagonal, math.tau / 38))
        wires.append(calculate("LESS_THAN", calculate("ABSOLUTE", sine), .19))
    mask = calculate("MAXIMUM", *wires)
    bsdf = nodes.get("Principled BSDF")
    mix = nodes.new("ShaderNodeMixRGB")
    mix.name = "Green chain-link diamonds baked into the opaque panel"
    links.new(mask, mix.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
    mix.inputs[2].default_value = linear((39, 109, 61))
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    relief = nodes.new("ShaderNodeBump")
    relief.inputs["Strength"].default_value = .22
    relief.inputs["Distance"].default_value = .2
    links.new(mask, relief.inputs["Height"])
    links.new(bsdf.inputs["Normal"].links[0].from_socket, relief.inputs["Normal"])
    links.new(relief.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def fence_panel():
    """Exact 500-stud repeat; posts and rails stay inside the 10-stud depth."""
    green_frame = schoolyard_steel("Fence green powder coat", (41, 130, 66))
    for x in (-245, 245):
        lathe("Fence rounded end post", [(4, 0), (5, 1), (5, 236), (4, 240)],
              green_frame, sectors=16, center=(x, 0, 0))
        for z in (12, 229):
            lathe("Fence thin rail fixing collar", [(4.7, z - 3), (5, z - 2), (5, z + 3)],
                  green_frame, sectors=16, center=(x, 0, 0))
    tube("Fence continuous green top rail", [(-245, 0, 233), (245, 0, 233)],
         5, green_frame, sides=16)
    tube("Fence green bottom tension rail", [(-245, 0, 12), (245, 0, 12)],
         3, green_frame, sides=16)
    box("Fence thin opaque wire-pattern panel", (484, 2, 216), (0, 0, 121), fence_wire_material(), 0)
    for x in (-243, 243):
        box("Fence panel edge fastening strip", (2, 2.8, 215), (x, 0, 121), green_frame, 0)


def bunting_paper_material(index, color):
    """Same cardstock grain as the pencil pennant, coloured through both faces."""
    mat = material("Bunting cardstock " + str(index), color, roughness=.84, bevel=.015)
    surface_grain(mat, (12, 12, 12), .14, .018, (.97, 1.025))
    mat.node_tree.nodes["Principled BSDF"].inputs["Coat Weight"].default_value = .025
    return mat


def bunting_pennant(center_x, mat):
    rows = 4
    vertices, ids = [], {}
    for side in (-1, 1):
        for row in range(rows + 1):
            for col in range(rows - row + 1):
                t = row / rows
                x = center_x + (col / rows - (1 - t) / 2) * 26
                z = -30 * (1 - (x / 150) ** 2) - 32 * t
                fold = .85 * max(0, 1 - abs(t - .25) / .25)
                y = .6 * math.sin((x - center_x) / 26 * math.pi) * (1 - t) + fold
                ids[side, row, col] = len(vertices)
                vertices.append((x, y + side * .12, z))
    faces = []
    for side in (-1, 1):
        for row in range(rows):
            for col in range(rows - row):
                a, b, c = (ids[side, row, col], ids[side, row, col + 1], ids[side, row + 1, col])
                faces.append((a, b, c) if side == -1 else (a, c, b))
                if col < rows - row - 1:
                    d = ids[side, row + 1, col + 1]
                    faces.append((b, d, c) if side == -1 else (b, c, d))
    perimeter = [(0, j) for j in range(rows + 1)]
    perimeter += [(r, rows - r) for r in range(1, rows + 1)]
    perimeter += [(r, 0) for r in reversed(range(1, rows))]
    for a, b in zip(perimeter, perimeter[1:] + perimeter[:1]):
        faces.append((ids[-1, *a], ids[1, *a], ids[1, *b], ids[-1, *b]))
    return finish(mesh("Folded triangle paper pennant", vertices, faces), mat, smooth=False, uv="strict")


def paper_bunting():
    """Two attachment points at Z=0, a 30-stud sag and nine paper flags."""
    string = material("Bunting cream cotton string", (231, 216, 176), roughness=.89, bevel=.025)
    points = [(float(x), 0, -30 * (1 - (x / 150) ** 2)) for x in np.linspace(-150, 150, 33)]
    tube("Bunting string with thirty-stud sag", points, .6, string, sides=8)
    colors = ((223, 64, 53), (252, 199, 44), (48, 132, 208), (77, 162, 86))
    paper = [bunting_paper_material(i, color) for i, color in enumerate(colors)]
    for index, x in enumerate(np.linspace(-126, 126, 9)):
        bunting_pennant(float(x), paper[index % 4])


def saturn_paint_material(ring=False):
    """Banded toy paint, in planet latitude or the tilted ring's true radius."""
    mat = material("Saturn ring cream and tan paint" if ring else "Saturn pale yellow banded paint",
                   (235, 211, 157), roughness=.62 if ring else .53, bevel=.035)
    surface_grain(mat, (.6, .6, .6), .09, .025, (.98, 1.02))
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    vector = coordinates.outputs["Object"]

    def calculate(operation, a, b=None):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for i, value in enumerate((a, b)):
            if value is not None:
                if isinstance(value, (int, float)):
                    node.inputs[i].default_value = value
                else:
                    links.new(value, node.inputs[i])
        return node.outputs[0]

    # Planet stripes and annulus share the same tilted equatorial plane.
    rotate = nodes.new("ShaderNodeVectorRotate")
    rotate.rotation_type = "AXIS_ANGLE"
    rotate.inputs["Center"].default_value = (0, 0, 30)
    rotate.inputs["Axis"].default_value = (1, 0, 0)
    rotate.inputs["Angle"].default_value = math.radians(-20)
    links.new(vector, rotate.inputs["Vector"])
    vector = rotate.outputs["Vector"]
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(vector, separate.inputs[0])
    if ring:
        radius = calculate("SQRT", calculate("ADD", calculate("MULTIPLY", separate.outputs["X"],
                                                                               separate.outputs["X"]),
                                                      calculate("MULTIPLY", separate.outputs["Y"],
                                                                               separate.outputs["Y"])))
        value = calculate("DIVIDE", calculate("SUBTRACT", radius, 28), 42)
        bands = [(0, (211, 183, 132)), (.12, (239, 223, 179)), (.24, (225, 200, 149)),
                 (.30, (249, 236, 198)), (.55, (244, 227, 181)), (.62, (196, 159, 106)),
                 (.68, (229, 207, 160)), (.84, (246, 232, 196)), (1, (218, 189, 139))]
    else:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = .12
        noise.inputs["Detail"].default_value = 2
        links.new(vector, noise.inputs["Vector"])
        value = calculate("DIVIDE", calculate("ADD", separate.outputs["Z"],
                                              calculate("MULTIPLY", noise.outputs["Fac"], 1.4)), 60)
        bands = [(0, (218, 187, 126)), (.12, (244, 225, 176)), (.23, (237, 215, 162)),
                 (.27, (201, 166, 109)), (.31, (246, 227, 176)), (.43, (231, 206, 149)),
                 (.49, (249, 233, 187)), (.57, (213, 178, 115)), (.62, (238, 215, 161)),
                 (.74, (248, 233, 189)), (.80, (220, 190, 132)), (.87, (245, 227, 179)),
                 (1, (233, 209, 156))]
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.name = "Painted ring bands" if ring else "Painted planet latitude bands"
    ramp.color_ramp.interpolation = "CONSTANT"
    for index, (position, color) in enumerate(bands):
        element = ramp.color_ramp.elements[index] if index < 2 else ramp.color_ramp.elements.new(position)
        element.position, element.color = position, linear(color)
    links.new(value, ramp.inputs[0])
    tint = next(node for node in nodes if node.type == "MIX_RGB" and node.blend_type == "MULTIPLY")
    links.new(ramp.outputs["Color"], tint.inputs[1])
    return mat


def saturn_thread_loop(mat):
    sectors, sides, radius = 24, 8, .55
    vertices, faces = [], []
    for i in range(sectors):
        angle = i * math.tau / sectors
        center = Vector((4 * math.cos(angle), 0, 65 + 5 * math.sin(angle)))
        outward = Vector((5 * math.cos(angle), 0, 4 * math.sin(angle))).normalized()
        for j in range(sides):
            t = j * math.tau / sides
            vertices.append(center + radius * (outward * math.cos(t) + Vector((0, math.sin(t), 0))))
    for i in range(sectors):
        for j in range(sides):
            faces.append((i * sides + j, i * sides + (j + 1) % sides,
                          ((i + 1) % sectors) * sides + (j + 1) % sides,
                          ((i + 1) % sectors) * sides + j))
    obj = mesh("Saturn short hanging thread loop", vertices, faces)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % sides == b % sides == 0 or a // sides == b // sides == 0)
    finish(obj, mat, uv="unwrap")


def saturn():
    """Sixty-stud painted planet, 140-stud tilted annulus and a thread loop."""
    ball("Saturn sixty-stud planet", (0, 0, 30), 30, saturn_paint_material(), segments=32, rings=20)
    ring = lathe("Saturn flat twenty-degree ring",
                 [(28, -.6), (29, -1.1), (69, -1.1), (70, -.5),
                  (70, .5), (69, 1.1), (29, 1.1), (28, .6)],
                 saturn_paint_material(ring=True), sectors=56, closed=True)
    # The lathe's rounded profile normals suit poles and tyres, but would make
    # this thin painted annulus shade like an inflated bowl. Keep its two broad
    # faces truly flat, while retaining smooth normals around the rim bevels.
    normals = [normal.vector.copy() for normal in ring.data.corner_normals]
    for face in ring.data.polygons:
        if abs(face.normal.z) > .999:
            face.use_smooth = False
            for index in face.loop_indices:
                normals[index] = face.normal.copy()
    ring.data.normals_split_custom_set(normals)
    ring.rotation_euler.x = math.radians(20)
    ring.location.z = 30
    active(ring)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    thread = material("Saturn cream hanging thread", (232, 220, 187), roughness=.9, bevel=.025)
    saturn_thread_loop(thread)


def classroom_fixture_material(name, color, wood=False, metallic=0, roughness=.48):
    """Furniture-scale grain, using the same bakeable nodes as desk and chair."""
    mat = material(name, color, wood=wood, roughness=roughness, bevel=.12)
    surface_grain(mat, (.025, .12, .018) if wood else (.35, .35, .35),
                  .13 if wood else .06, .045 if wood else .015,
                  (.91, 1.07) if wood else (.985, 1.015))
    mat.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = metallic
    return mat


def classroom_fixture_math(mat, operation, a, b=None):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    node = nodes.new("ShaderNodeMath")
    node.operation = operation
    for index, value in enumerate((a, b)):
        if value is not None:
            if isinstance(value, (int, float)):
                node.inputs[index].default_value = value
            else:
                links.new(value, node.inputs[index])
    return node.outputs[0]


def classroom_fixture_letters(mat, label, color, area):
    """Paint a crisp little sign into the atlas, without text mesh slivers."""
    glyphs = {
        "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
        "o": ("00000", "00000", "01110", "10001", "10001", "10001", "01110"),
        "m": ("00000", "00000", "11010", "10101", "10101", "10101", "10101"),
        "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
        "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
        " ": ("00000",) * 7,
    }
    mask = np.zeros((RESOLUTION, RESOLUTION, 4), dtype=np.float32)
    mask[:, :, 3] = 1
    cells = len(label) * 6 - 1
    for index, letter in enumerate(label):
        for row, bits in enumerate(glyphs[letter]):
            for column, bit in enumerate(bits):
                if bit == "1":
                    x0, x1 = [round((index * 6 + column + offset) / cells * RESOLUTION)
                              for offset in (0, 1)]
                    y0, y1 = [round((6 - row + offset) / 7 * RESOLUTION) for offset in (0, 1)]
                    mask[y0:y1, x0:x1, :3] = 1
    image = bpy.data.images.new(mat.name + " painted letters", width=RESOLUTION, height=RESOLUTION)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(mask.ravel())
    image.update()
    image.use_fake_user = True
    image.pack()
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], xyz.inputs[0])
    x0, x1, z0, z1 = area
    vector = nodes.new("ShaderNodeCombineXYZ")
    links.new(classroom_fixture_math(mat, "DIVIDE",
              classroom_fixture_math(mat, "SUBTRACT", xyz.outputs["X"], x0), x1 - x0), vector.inputs["X"])
    links.new(classroom_fixture_math(mat, "DIVIDE",
              classroom_fixture_math(mat, "SUBTRACT", xyz.outputs["Z"], z0), z1 - z0), vector.inputs["Y"])
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = "Source painted sign"
    texture.image, texture.extension = image, "CLIP"
    links.new(vector.outputs[0], texture.inputs["Vector"])
    bsdf = nodes.get("Principled BSDF")
    mix = nodes.new("ShaderNodeMixRGB")
    links.new(texture.outputs["Color"], mix.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
    mix.inputs[2].default_value = linear(color)
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])


def classroom_fixture_wired_glass():
    """Pale wired safety-glass pigment and relief, supported by the opaque bake."""
    mat = classroom_fixture_material("Door pale blue wired safety glass", (164, 201, 211), roughness=.27)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(next(node for node in nodes if node.type == "TEX_COORD").outputs["Object"], xyz.inputs[0])
    wires = []
    for operation in ("ADD", "SUBTRACT"):
        diagonal = classroom_fixture_math(mat, operation, xyz.outputs["X"], xyz.outputs["Z"])
        sine = classroom_fixture_math(mat, "SINE", classroom_fixture_math(mat, "MULTIPLY", diagonal, math.tau / 19))
        wires.append(classroom_fixture_math(mat, "LESS_THAN", classroom_fixture_math(mat, "ABSOLUTE", sine), .09))
    mask = classroom_fixture_math(mat, "MAXIMUM", *wires)
    bsdf = nodes.get("Principled BSDF")
    mix = nodes.new("ShaderNodeMixRGB")
    links.new(mask, mix.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
    mix.inputs[2].default_value = linear((83, 126, 137))
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    return mat


def classroom_door():
    """A flush-backed maple leaf in a teal frame, with recessed wired glass."""
    wood = classroom_fixture_material("Classroom door warm maple", (213, 163, 100), wood=True)
    frame = classroom_fixture_material("Classroom door painted teal frame", (77, 153, 164))
    trim = classroom_fixture_material("Classroom door pale window bead", (239, 212, 166), wood=True)
    steel = classroom_fixture_material("Classroom door brushed hardware", (188, 199, 204), metallic=.82, roughness=.31)
    for x in (-86.5, 86.5):
        box("Painted full-depth door jamb", (17, 20, 358), (x, 0, 179), frame, 1.2, 2)
    box("Painted door frame lintel", (190, 20, 12), (0, 0, 364), frame, 1.2, 2)
    # Four timber pieces form a real rectangular window recess.
    box("Door left window stile", (28, 9, 354), (-64, 4.5, 181), wood, .6, 1)
    box("Door wide handle stile", (90, 9, 354), (33, 4.5, 181), wood, .6, 1)
    box("Door timber below window", (38, 9, 194), (-31, 4.5, 101), wood, .5, 1)
    box("Door timber above window", (38, 9, 34), (-31, 4.5, 341), wood, .5, 1)
    box("Flat flush rear veneer", (156, .6, 354), (0, 9.7, 181), wood, .15, 1)
    box("Recessed wired glass pane", (38, 1, 126), (-31, 2.5, 261), classroom_fixture_wired_glass(), .3, 1)
    rounded_ring("Maple safety-window bead", (46, 134), (38, 126), 2, (-31, 0, 261), trim, axis="Y", radius=2)
    box("Brushed metal kick plate", (135, 1.2, 34), (0, -.6, 29), steel, .5, 2)
    for x in (-61, 61):
        for z in (17, 41):
            ball("Kick plate screw", (x, -1.3, z), .65, steel, segments=6, rings=3, scale=(1, .35, 1))
    rose = lathe("Lever handle round rose", [(5.5, -1.5), (5.5, 1.5)], steel, sectors=16)
    rose.rotation_euler.x = math.pi / 2
    rose.location = (55, -1.5, 166)
    tube("Classroom door lever handle", [(55, -3, 166), (55, -7.8, 166),
                                        (36, -8.4, 166), (31, -7.8, 166)], 1.6, steel, sides=8)
    for z in (55, 175, 307):
        lathe("Door hinge knuckle", [(2, z - 9), (2, z + 9)], steel, sectors=10, center=(-78, 0, 0))
    sign = classroom_fixture_material("Room 12 cream sign", (252, 240, 200), roughness=.68)
    classroom_fixture_letters(sign, "Room 12", (40, 84, 96), (-39, 39, 331, 345))
    box("Room 12 sign above the glass", (85, 1.2, 18), (-0.5, -.6, 338), sign, .6, 2)


def floor_fan():
    """A round face-up fan, with only the rotor wholly inside the split band."""
    blue = classroom_fixture_material("Floor fan bright blue plastic", (29, 127, 211), roughness=.34)
    dark = classroom_fixture_material("Floor fan dark interior", (49, 65, 80), roughness=.7)
    white = classroom_fixture_material("Floor fan ivory blades", (247, 245, 231), roughness=.39)
    chrome = classroom_fixture_material("Floor fan chrome grille", (198, 211, 221), metallic=.92, roughness=.24)
    orange = classroom_fixture_material("Floor fan orange power switch", (243, 156, 43))
    lathe("Chunky circular blue fan rim",
          [(71 + 7 * math.cos(t), 18 + 14 * math.sin(t))
           for t in np.linspace(0, math.tau, 8, endpoint=False)],
          blue, sectors=40, closed=True)
    lathe("Fan recessed round rear tray", [(67, 5), (67, 8)], dark, sectors=32)
    for angle in np.linspace(math.pi / 4, math.tau + math.pi / 4, 4, endpoint=False):
        lathe("Small round floor fan rubber foot", [(7, 0), (8, 1), (8, 4)], dark,
              sectors=8, center=(64 * math.cos(angle), 64 * math.sin(angle), 0))
    lathe("Fan motor behind blades", [(19, 8), (21, 10), (21, 16.8)], dark, sectors=16)
    for index in range(5):
        angle = index * math.tau / 5
        outline = []
        for r, a in ((11, -.16), (28, -.10), (49, .10), (58, .30),
                     (56, .67), (47, .78), (26, .44), (11, .31)):
            outline.append((r * math.cos(a + angle), r * math.sin(a + angle), 22))
        panel("White swept fan blade", outline, 2.2, white, radius=1)
    lathe("White fan centre cap", [(10, 19), (13, 21), (13, 24), (10, 26), (4, 27)], white, sectors=16)
    for radius, samples in ((65.5, 40), (40, 24), (19, 16)):
        points = [(radius * math.cos(t), radius * math.sin(t), 34.8)
                  for t in np.linspace(0, math.tau, samples, endpoint=False)]
        schoolyard_loop("Chrome concentric safety grille", points, 1.2, chrome, sides=8)
    for axis in (0, 1):
        for offset in range(-49, 50, 14):
            extent = math.sqrt(64 ** 2 - offset ** 2)
            points = [(side * extent, offset, 34.2) if axis == 0 else (offset, side * extent, 34.2)
                      for side in (-1, 1)]
            tube("Chrome straight grille wire", points, .6, chrome, sides=6)
    for axis in (0, 1):
        for side in (-1, 1):
            points = [(side * 65.5, 0, 34.8), (side * 68, 0, 34.2)] if axis == 0 else [
                (0, side * 65.5, 34.8), (0, side * 68, 34.2)]
            tube("Chrome grille frame attachment", points, .6, chrome, sides=6)
            lathe("Fan grille retaining screw", [(1.6, 31.4), (1.6, 34.2)], chrome,
                  sectors=8, center=(side * 68 if axis == 0 else 0, side * 68 if axis == 1 else 0, 0))
    box("Orange fan on switch", (10, 7, 2), (0, -73.4, 31), orange, 1, 1)


def hangar_number_image(number):
    """Rounded marker paths, with mild wobble and a thin cream keyline."""
    # Cubic curves and round-ended strokes, not a grid or a pixel font.
    strokes = {
        "0": [((.30, .98), (.04, .98), (.03, .74), (.03, .50)),
              ((.03, .50), (.03, .22), (.06, .02), (.30, .02)),
              ((.30, .02), (.56, .02), (.57, .27), (.57, .50)),
              ((.57, .50), (.57, .77), (.55, .98), (.30, .98))],
        "1": [((.10, .77), (.31, .98)), ((.31, .98), (.31, .02)),
              ((.12, .02), (.50, .02))],
        "2": [((.04, .77), (.10, 1.07), (.55, 1.06), (.57, .80)),
              ((.57, .80), (.63, .55), (.18, .38), (.03, .05)),
              ((.03, .05), (.24, .01), (.42, .02), (.58, .03))],
        "3": [((.05, .88), (.26, 1.08), (.64, .98), (.52, .69)),
              ((.52, .69), (.45, .57), (.29, .53), (.22, .53)),
              ((.22, .53), (.66, .60), (.69, .05), (.33, .02)),
              ((.33, .02), (.22, -.01), (.08, .04), (.03, .15))],
        "4": [((.43, .98), (.02, .35)), ((.02, .35), (.59, .35)),
              ((.43, .98), (.43, .02))],
        "5": [((.57, .97), (.08, .97)), ((.08, .97), (.06, .55)),
              ((.06, .55), (.62, .77), (.72, .03), (.32, .02)),
              ((.32, .02), (.21, -.01), (.08, .04), (.03, .13))],
        "6": [((.52, .93), (.15, 1.16), (-.07, .54), (.05, .19)),
              ((.05, .19), (.16, -.08), (.59, -.02), (.57, .28)),
              ((.57, .28), (.55, .61), (.15, .66), (.04, .38))],
        "7": [((.03, .96), (.58, .96)),
              ((.58, .96), (.42, .69), (.20, .24), (.17, .02))],
        "8": [((.30, .52), (-.08, .67), (.02, 1.01), (.30, .98)),
              ((.30, .98), (.66, 1.02), (.65, .66), (.30, .52)),
              ((.30, .52), (-.12, .40), (-.01, -.01), (.30, .02)),
              ((.30, .02), (.72, -.02), (.72, .42), (.30, .52))],
        "9": [((.55, .62), (.56, 1.07), (.04, 1.12), (.03, .72)),
              ((.03, .72), (.01, .40), (.44, .39), (.55, .62)),
              ((.55, .62), (.60, .31), (.37, -.04), (.12, .06))],
    }
    side = 512
    x, y = np.meshgrid((np.arange(side, dtype=np.float32) + .5) / side * (44 / 30) - 22 / 30,
                       (np.arange(side, dtype=np.float32) + .5) / side * 1.2 - .1)
    distance = np.full((side, side), 10, dtype=np.float32)
    label = str(number)
    for digit_index, digit in enumerate(label):
        offset = (digit_index - (len(label) - 1) / 2) * .68 - .30
        for stroke in strokes[digit]:
            controls = np.array(stroke, dtype=np.float32)
            t = np.linspace(0, 1, 25 if len(stroke) == 4 else 9)[:, None]
            points = ((1 - t) ** 3 * controls[0] + 3 * (1 - t) ** 2 * t * controls[1]
                      + 3 * (1 - t) * t ** 2 * controls[2] + t ** 3 * controls[3]
                      if len(stroke) == 4 else (1 - t) * controls[0] + t * controls[1])
            points[:, 0] += offset + .004 * np.sin(points[:, 1] * 17 + digit_index)
            for a, b in zip(points, points[1:]):
                delta = b - a
                along = np.clip(((x - a[0]) * delta[0] + (y - a[1]) * delta[1])
                                / np.dot(delta, delta), 0, 1)
                segment_distance = np.hypot(x - a[0] - along * delta[0], y - a[1] - along * delta[1])
                distance = np.minimum(distance, segment_distance)
    radius = .052 + .003 * np.sin(y * 23 + x * 11)
    antialias = 1.2 / side
    ink = np.clip((radius - distance) / antialias + .5, 0, 1)
    alpha = np.clip((radius + .014 - distance) / antialias + .5, 0, 1)
    cream, red = np.array(linear((255, 247, 225))[:3]), np.array(linear((214, 57, 45))[:3])
    pixels = np.empty((side, side, 4), dtype=np.float32)
    pixels[:, :, :3] = cream + (red - cream) * ink[:, :, None]
    pixels[:, :, 3] = alpha
    image = bpy.data.images.new("Hangar painted number " + label, width=side, height=side, alpha=True)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(pixels.ravel())
    image.update()
    image.use_fake_user = True
    image.pack()
    return image


def hangar_painted_numbers(mat, xyz):
    """Project upright ink onto the crown without changing the card shell."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    image = hangar_number_image(1)
    normal = nodes.new("ShaderNodeSeparateXYZ")
    links.new(next(node for node in nodes if node.type == "NEW_GEOMETRY").outputs["Normal"], normal.inputs[0])
    crown = classroom_fixture_math(mat, "MULTIPLY",
                                   classroom_fixture_math(mat, "GREATER_THAN", normal.outputs["Z"], .1),
                                   classroom_fixture_math(mat, "GREATER_THAN", xyz.outputs["Z"], 35))
    # One big copy centred on the crown, clear of the striped entrance edge (Alan: a second small copy read as a mistake).
    for label, width, height, center_y in (("roof", 56, 46, 0),):
        vector = nodes.new("ShaderNodeCombineXYZ")
        links.new(classroom_fixture_math(mat, "ADD",
                  classroom_fixture_math(mat, "DIVIDE", xyz.outputs["X"], width), .5), vector.inputs["X"])
        links.new(classroom_fixture_math(mat, "ADD", classroom_fixture_math(mat, "DIVIDE",
                  classroom_fixture_math(mat, "SUBTRACT", xyz.outputs["Y"], center_y), height), .5), vector.inputs["Y"])
        texture = nodes.new("ShaderNodeTexImage")
        texture.name = "Hangar number " + label
        texture.image, texture.extension = image, "CLIP"
        links.new(vector.outputs[0], texture.inputs["Vector"])
        bsdf = nodes.get("Principled BSDF")
        mix = nodes.new("ShaderNodeMixRGB")
        links.new(classroom_fixture_math(mat, "MULTIPLY", texture.outputs["Alpha"], crown), mix.inputs[0])
        links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
        links.new(texture.outputs["Color"], mix.inputs[2])
        links.new(mix.outputs[0], bsdf.inputs["Base Color"])


def desk_hangar():
    """Thin faceted cardstock vault, with an open entrance and painted edging."""
    card = classroom_fixture_material("Desk hangar warm ivory cardstock", (247, 232, 200), roughness=.82)
    surface_grain(card, (1.7, 1.7, 1.7), .12, .025, (.97, 1.025))
    nodes, links = card.node_tree.nodes, card.node_tree.links
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(next(node for node in nodes if node.type == "TEX_COORD").outputs["Object"], xyz.inputs[0])
    diagonal = classroom_fixture_math(card, "ADD", xyz.outputs["X"], xyz.outputs["Z"])
    wave = classroom_fixture_math(card, "SINE", classroom_fixture_math(card, "MULTIPLY", diagonal, math.tau / 16))
    stripe = classroom_fixture_math(card, "GREATER_THAN", wave, 0)
    front = classroom_fixture_math(card, "LESS_THAN", xyz.outputs["Y"], -27)
    bsdf = nodes.get("Principled BSDF")
    mix = nodes.new("ShaderNodeMixRGB")
    links.new(classroom_fixture_math(card, "MULTIPLY", stripe, front), mix.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
    mix.inputs[2].default_value = linear((214, 57, 45))
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    hangar_painted_numbers(card, xyz)
    angles = np.linspace(math.pi, 0, 17)
    outer = [(-55, 1)] + [(55 * math.cos(t), 14 + 36 * math.sin(t)) for t in angles] + [(55, 1)]
    inner = [(53.5, 1)] + [(53.5 * math.cos(t), 14 + 34.5 * math.sin(t))
                          for t in reversed(angles)] + [(-53.5, 1)]
    roof = extruded_profile("Folded cardstock arched shell", outer + inner, -35, 35, card, 0)
    roof.rotation_euler.z = math.pi / 2
    for face in roof.data.polygons:
        face.use_smooth = False
    for x in (-49, 49):
        box("Cardstock folded glue foot", (12, 70, 1), (x, 0, .5), card, 0)
    rear_profile = [(-53.5, 1)] + [(53.5 * math.cos(t), 14 + 34.5 * math.sin(t))
                                  for t in angles] + [(53.5, 1)]
    rear = extruded_profile("Cardstock closed rear wall", rear_profile, -.6, .6, card, 0)
    rear.rotation_euler.z = math.pi / 2
    rear.location.y = 34.4


def classroom_fixture_bin(name, location, color):
    """Open storage tub with a real rectangular finger hole in its front."""
    x, y, z = location
    mat = classroom_fixture_material(name + " plastic", color, roughness=.48)
    box(name + " bottom", (143, 80, 4), (x, y, z + 2), mat, .7, 1)
    for side in (-1, 1):
        box(name + " side", (4, 72, 70), (x + side * 69.5, y, z + 39), mat, .7, 1)
    box(name + " back", (135, 4, 70), (x, y + 38, z + 39), mat, .7, 1)
    # One continuous front face around an off-centre hole. No overlapping
    # coplanar panels, which would leave black seams in the exported bake.
    outer = [(-71.5, 4), (71.5, 4), (71.5, 74), (-71.5, 74)]
    inner = [(-22, 52), (22, 52), (22, 62), (-22, 62)]
    vertices = [(x + px, y + py, z + pz) for py in (-40, -36)
                for contour in (outer, inner) for px, pz in contour]
    faces = []
    for i in range(4):
        j = (i + 1) % 4
        faces += [(i, j, j + 4, i + 4), (i + 8, i + 12, j + 12, j + 8),
                  (i, i + 8, j + 8, j), (i + 4, j + 4, j + 12, i + 12)]
    front = mesh(name + " continuous finger-hole front", vertices, faces)
    bevel(front, .5, 1)
    finish(front, mat, weighted=True)
    rounded_ring(name + " thick top lip", (146, 83), (135, 72), 4, (x, y, z + 75), mat, radius=4)


def classroom_fixture_upright_book(name, x, y, z, height, color):
    cover = classroom_fixture_material(name + " cover", color, roughness=.75)
    pages = classroom_fixture_material("Cubby shelf warm book pages", (250, 240, 213), roughness=.86)
    box(name + " page block", (17, 63, height - 4), (x, y - 1, z + height / 2), pages, .5, 1)
    for side in (-1, 1):
        box(name + " cover", (1.5, 67, height), (x + side * 9.25, y, z + height / 2), cover, .4, 1)
    box(name + " spine facing room", (20, 3, height), (x, y - 32, z + height / 2), cover, .6, 1)


def classroom_fixture_backpack(x, y, z):
    red = classroom_fixture_material("Cubby backpack coral canvas", (211, 70, 64), roughness=.83)
    gold = classroom_fixture_material("Cubby backpack golden zip", (238, 183, 77), roughness=.53)
    dark = classroom_fixture_material("Cubby backpack dark straps", (88, 72, 79), roughness=.9)
    box("Rounded coral school backpack", (106, 52, 108), (x, y, z + 54), red, 13, 3)
    box("Backpack front pocket", (83, 13, 43), (x, y - 28, z + 32), red, 7, 2)
    tube("Backpack pocket golden zipper", [(x - 32, y - 35, z + 45), (x + 32, y - 35, z + 45)],
         .7, gold, sides=6)
    for side in (-1, 1):
        tube("Backpack shoulder strap", [(x + side * 31, y + 25, z + 16),
                                         (x + side * 38, y + 31, z + 58),
                                         (x + side * 29, y + 26, z + 96)], 3, dark, sides=6)
    tube("Backpack carry loop", [(x - 15, y, z + 102), (x - 13, y, z + 113),
                                 (x - 8, y, z + 117), (x + 8, y, z + 117),
                                 (x + 13, y, z + 113), (x + 15, y, z + 102)], 2, dark, sides=6)


def cubby_shelf():
    """Six open maple cubbies, all occupied, in a low three-by-two cabinet."""
    wood = classroom_fixture_material("Cubby shelf warm maple", (222, 183, 126), wood=True, roughness=.5)
    backing = classroom_fixture_material("Cubby shelf pale plywood back", (233, 207, 160), wood=True, roughness=.63)
    for z in (5, 295):
        box("Cubby shelf full-width board", (600, 120, 10), (0, 0, z), wood, 1.5, 2)
    for x in (-291, 291):
        box("Cubby shelf outer side", (18, 120, 280), (x, 0, 150), wood, 1.5, 2)
    box("Cubby shelf full plywood back", (564, 8, 280), (0, 56, 150), backing, 1, 1)
    box("Cubby shelf middle shelf", (564, 112, 12), (0, -4, 150), wood, 1, 1)
    for x in (-97, 97):
        for z in (77, 223):
            box("Cubby shelf fitted vertical divider", (12, 112, 134), (x, -4, z), wood, 1, 1)
    classroom_fixture_bin("Blue upper left storage bin", (-193, -4, 157), (39, 139, 206))
    classroom_fixture_bin("Yellow upper right storage bin", (193, -4, 157), (242, 182, 47))
    classroom_fixture_bin("Green lower centre storage bin", (0, -4, 11), (80, 159, 104))
    for index, color in enumerate(((197, 65, 57), (49, 129, 188), (229, 165, 43))):
        school_book("Lower left classroom book " + str(index + 1), 137 - index * 5, 81 - index * 3,
                    14, (-193 + index * 2, -4, 11 + index * 14), color)
        classroom_fixture_upright_book("Upper middle classroom book " + str(index + 1), -27 + index * 25,
                                       -4, 157, 99 + index * 8, color)
    classroom_fixture_backpack(193, -1, 11)


def backpack_cubby_backpack(name, x, z, color, variant):
    """Small canvas backpack, with its handle and pocket inside one cubby."""
    cloth = classroom_fixture_material(name + " canvas", color, roughness=.84)
    pocket_color = tuple(min(255, round(channel * .85 + 29)) for channel in color)
    pocket = classroom_fixture_material(name + " pocket canvas", pocket_color, roughness=.86)
    straps = classroom_fixture_material("Backpack cubby charcoal webbing", (65, 69, 81), roughness=.9)
    zip_mat = classroom_fixture_material("Backpack cubby warm cream zips", (244, 212, 139), roughness=.58)
    width, height = (54, 58, 56)[variant % 3], (47, 49, 46)[variant % 3]
    box(name + " rounded body", (width, 30, height), (x, -3, z + height / 2), cloth, 8, 3)
    tube(name + " main zip line",
         [(x - width / 2 + 5, -18.6, z + 29), (x - width / 2 + 6, -18.6, z + height - 13),
          (x - width / 2 + 13, -18.6, z + height - 7),
          (x + width / 2 - 13, -18.6, z + height - 7),
          (x + width / 2 - 6, -18.6, z + height - 13), (x + width / 2 - 5, -18.6, z + 29)],
         .65, zip_mat, sides=6)
    if variant % 4 != 3:
        box(name + " front pocket", (width - 10, 8, 21), (x, -19, z + 16), pocket, 4, 2)
        tube(name + " pocket zip", [(x - width / 2 + 11, -23.5, z + 22),
                                    (x + width / 2 - 11, -23.5, z + 22)], .65, zip_mat, sides=6)
        box(name + " pocket zip pull", (2.5, 1.4, 4), (x + width / 2 - 11, -24, z + 20),
            zip_mat, .5)
    for side in (-1, 1):
        tube(name + " padded shoulder strap", [(x + side * 15, 11, z + 6),
                                                (x + side * 19, 17, z + 25),
                                                (x + side * 15, 11, z + height - 6)],
             1.8, straps, sides=6)
    tube(name + " carry loop", [(x - 9, -1, z + height - 2), (x - 9, -1, z + height + 2),
                                (x - 5, -1, z + height + 5), (x + 5, -1, z + height + 5),
                                (x + 9, -1, z + height + 2), (x + 9, -1, z + height - 2)],
         1.3, straps, sides=6)
    if variant % 4 == 1:
        # The little star hangs beside the pocket, still well within its opening.
        rounded_ring(name + " toy keyring", (5, 6), (3, 4), .8, (x + 24, -20, z + 30),
                     zip_mat, axis="Y", radius=.8)
        charm = classroom_fixture_material("Backpack cubby yellow star toys", (255, 192, 57), roughness=.5)
        outline = []
        for index in range(10):
            angle = math.pi / 2 + index * math.pi / 5
            radius = 5 if index % 2 == 0 else 2.6
            outline.append((x + 24 + radius * math.cos(angle), -21, z + 22 + radius * math.sin(angle)))
        panel(name + " dangling star toy", outline, 2, charm, radius=.15)


def backpack_cubby_lunchbox(name, x, z, color):
    plastic = classroom_fixture_material(name + " bright plastic", color, roughness=.53)
    lid_color = tuple(min(255, round(channel * .7 + 70)) for channel in color)
    lid = classroom_fixture_material(name + " lighter lid", lid_color, roughness=.49)
    cream = classroom_fixture_material("Backpack cubby lunchbox cream clasps", (247, 232, 193), roughness=.56)
    dark = classroom_fixture_material("Backpack cubby lunchbox handles", (62, 87, 92), roughness=.68)
    box(name + " rounded box", (58, 32, 25), (x, -1, z + 12.5), plastic, 5, 3)
    box(name + " overhanging lid", (60, 34, 4), (x, -1, z + 25), lid, 1.8, 2)
    box(name + " front clasp", (9, 2.5, 7), (x, -18, z + 20), cream, .8)
    tube(name + " carry handle", [(x - 10, -1, z + 26), (x - 10, -1, z + 31),
                                  (x + 10, -1, z + 31), (x + 10, -1, z + 26)],
         1.4, dark, sides=6)


def backpack_cubby_jacket(x, z):
    """A rolled lavender jacket, with bound sleeves and a visible spiral end."""
    cloth = classroom_fixture_material("Backpack cubby lavender rolled jacket", (151, 127, 189), roughness=.92)
    fold = classroom_fixture_material("Backpack cubby jacket dark folds", (110, 86, 146), roughness=.94)
    rib = classroom_fixture_material("Backpack cubby jacket cuff ribbing", (183, 159, 211), roughness=.9)
    lathe("Backpack cubby rolled jacket body", [(10, -30), (13, -26), (13, 26), (10, 30)],
          cloth, sectors=16, center=(x, -4, z + 13), axis="X")
    lathe("Backpack cubby jacket folded cuff", [(13.1, -4), (14, -3), (14, 3), (13.1, 4)],
          rib, sectors=16, center=(x, -4, z + 13), axis="X")
    box("Backpack cubby jacket folded sleeves", (38, 21, 10), (x - 3, -3, z + 29), cloth, 4, 2)
    tube("Backpack cubby jacket sleeve seam", [(x - 16, -14, z + 29), (x + 9, -14, z + 29)],
         .65, fold, sides=6)
    spiral = []
    for index in range(22):
        angle, radius = index * math.pi / 7, 1.5 + index * .36
        spiral.append((x + 30.3, -4 + radius * math.cos(angle), z + 13 + radius * math.sin(angle)))
    tube("Backpack cubby jacket rolled spiral", spiral, .6, fold, sides=6)


def backpack_cubby():
    """Fourteen open maple compartments, nine backpacks and varied lunch things."""
    wood = classroom_fixture_material("Backpack cubby warm light maple", (225, 186, 133), wood=True, roughness=.51)
    backing = classroom_fixture_material("Backpack cubby pale plywood back", (237, 211, 168),
                                         wood=True, roughness=.66)
    for z in (4, 136):
        box("Backpack cubby full-width board", (700, 60, 8), (0, 0, z), wood, 1.2, 2)
    for x in (-344, 344):
        box("Backpack cubby outer side", (12, 60, 124), (x, 0, 70), wood, 1.2, 2)
    box("Backpack cubby closed plywood back", (676, 5, 124), (0, 27.5, 70), backing, .6)
    # Recess the middle shelf's front just enough to fit its name tags inside Y=-30.
    box("Backpack cubby middle shelf", (676, 53, 8), (0, -1.5, 70), wood, .8)
    pitch = (676 + 8) / 7
    centres = [(index - 3) * pitch for index in range(7)]
    for index in range(6):
        for z in (37, 103):
            box("Backpack cubby fitted vertical divider", (8, 55, 58),
                ((index - 2.5) * pitch, -2.5, z), wood, .8)
    palette = ((222, 68, 61), (48, 132, 207), (72, 170, 106), (248, 195, 54),
               (151, 92, 183), (242, 136, 51), (227, 110, 165))
    for index, x in enumerate(centres):
        tag = classroom_fixture_material("Backpack cubby blank name tag " + str(index + 1),
                                         palette[index], roughness=.82)
        box("Backpack cubby blank name strip", (42, 1.4, 5), (x, -28.3, 70), tag, .55)
    # Top middle and lower sixth are intentionally empty. All other cells have
    # independent contents, so the finished asset still reads as a working classroom.
    backpacks = [(1, 0, 0), (1, 1, 1), (1, 2, 2), (1, 4, 3), (1, 5, 4),
                 (0, 1, 5), (0, 2, 6), (0, 3, 1), (0, 6, 0)]
    for variant, (row, column, color) in enumerate(backpacks):
        backpack_cubby_backpack("Cubby %d-%d backpack" % (row + 1, column + 1),
                                 centres[column], 9 + row * 66, palette[color], variant)
    backpack_cubby_lunchbox("Upper right coral lunchbox", centres[6], 75, (225, 103, 80))
    backpack_cubby_lunchbox("Lower fifth turquoise lunchbox", centres[4], 9, (52, 168, 170))
    backpack_cubby_jacket(centres[0], 9)


def bulletin_board():
    """Empty warm speckled cork, inside a shallow maple frame."""
    wood = classroom_fixture_material("Bulletin board honey maple frame", (210, 156, 91), wood=True, roughness=.51)
    cork = classroom_fixture_material("Bulletin board natural cork", (183, 127, 73), roughness=.94)
    surface_grain(cork, (.7, .7, .7), .5, .22, (.68, 1.23))
    backing = classroom_fixture_material("Bulletin board fibre backing", (156, 113, 76), roughness=.93)
    rounded_ring("Rounded maple bulletin frame", (360, 260), (332, 232), 8,
                 (0, 0, 130), wood, axis="Y", radius=5)
    box("Flat bulletin board rear backing", (332, 5, 232), (0, 1.5, 130), backing, .3, 1)
    box("Empty recessed cork face", (332, 2, 232), (0, -2, 130), cork, .3, 1)


def bookshelf_book(name, width, depth, height, location, color, lean=0, flat=False, label=False):
    """One closed bound book, with raised covers and three connected UV islands."""
    x, y, z = location
    cover = classroom_fixture_material("Bookshelf cloth " + str(color), color, roughness=.73)
    pages = classroom_fixture_material("Bookshelf warm ivory pages", (246, 236, 207), roughness=.88)
    surface_grain(pages, (.2, .2, 3), .12, .025, (.96, 1.025))
    first = len(PARTS)
    thickness, length = (height, width) if flat else (width, height)
    outer, inner = thickness / 2, thickness / 2 - .8
    # Concave end profile: both covers project one stud past the page block.
    profile = [(-outer, 0), (-inner, 0), (-inner, 1), (inner, 1),
               (inner, 0), (outer, 0), (outer, length), (inner, length),
               (inner, length - 1), (-inner, length - 1), (-inner, length), (-outer, length)]
    count = len(profile)
    vertices = []
    for end in (-depth / 2, depth / 2):
        for px, pz in profile:
            point = (pz - length / 2, end, thickness / 2 - px) if flat else (px, end, pz)
            vertices.append((point[0] + x, point[1] + y, point[2] + z))
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    book = mesh(name + " raised covers and recessed pages", vertices, faces)
    for edge in book.data.edges:
        a, b = edge.vertices
        # Two end caps and one continuous binding strip, rather than separate
        # islands for every tiny cover edge. Keep the standard eight-pixel gutter.
        edge.use_seam = a // count == b // count or a % count == b % count == 0
    finish(book, cover, uv="unwrap", weighted=True)
    book.data.materials.append(pages)
    for index in (1, 4, 10):
        book.data.polygons[index].material_index = 1
    if label and not flat:
        box(name + " small cream spine label", (width * .65, .25, height * .16),
            (x, y - depth / 2 - .12, z + height * .66), pages, 0)
    if lean:
        pivot = Vector(location)
        rotation = Matrix.Rotation(math.radians(lean), 3, "Y")
        pieces = PARTS[first:]
        # Apply in world space so pages, labels and both covers rotate together.
        for part in pieces:
            for vertex in part.data.vertices:
                point = part.matrix_world @ vertex.co
                vertex.co = rotation @ (point - pivot) + pivot
            part.matrix_world.identity()
        low = min(vertex.co.z for part in pieces for vertex in part.data.vertices)
        for part in pieces:
            for vertex in part.data.vertices:
                vertex.co.z += z - low
            # Rotate the old weighted corner normals along with the mesh.
            normals = [rotation @ normal.vector for normal in part.data.corner_normals]
            part.data.normals_split_custom_set(normals)


def bookshelf_globe(x, y, z):
    """Small blue-and-green school globe on a chunky mustard stand."""
    brass = classroom_fixture_material("Bookshelf globe mustard stand", (209, 156, 61), roughness=.43)
    ocean = classroom_fixture_material("Bookshelf globe blue ocean", (68, 155, 192), roughness=.58)
    nodes, links = ocean.node_tree.nodes, ocean.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = .14
    noise.inputs["Detail"].default_value = 2
    links.new(coordinates.outputs["Object"], noise.inputs["Vector"])
    continents = nodes.new("ShaderNodeValToRGB")
    continents.color_ramp.interpolation = "CONSTANT"
    continents.color_ramp.elements[0].position = .47
    continents.color_ramp.elements[0].color = linear((65, 149, 193))
    continents.color_ramp.elements[1].position = .53
    continents.color_ramp.elements[1].color = linear((127, 178, 83))
    links.new(noise.outputs["Fac"], continents.inputs[0])
    tint = next(node for node in nodes if node.type == "MIX_RGB" and node != nodes["Paint with soft contact shadows"])
    links.new(continents.outputs[0], tint.inputs[1])
    lathe("Globe round pedestal", [(12, 0), (12, 1.5), (8, 3), (3, 4)], brass,
          sectors=12, center=(x, y, z))
    lathe("Globe short stem", [(2, 3), (2, 8)], brass, sectors=8, center=(x, y, z))
    ball("Classroom globe", (x, y, z + 21), 13, ocean, segments=16, rings=8)
    points = [(x + 15 * math.cos(t), y, z + 21 + 15 * math.sin(t))
              for t in np.linspace(-math.pi / 2, math.pi / 2, 13)]
    tube("Globe curved meridian cradle", points, .8, brass, sides=6)


def bookshelf_pencil_pot(x, y, z):
    blue = classroom_fixture_material("Bookshelf blue pencil pot", (55, 135, 182), roughness=.51)
    wood = classroom_fixture_material("Bookshelf pencil exposed wood", (229, 193, 136), roughness=.72)
    graphite = classroom_fixture_material("Bookshelf pencil graphite", (66, 70, 76), roughness=.72)
    # Closed cup wall with a real open rim and visible bottom inside it.
    rounded_ring("Open blue pencil pot", (20, 20), (17, 17), 18,
                 (x, y, z + 9), blue, radius=4)
    box("Pencil pot interior bottom", (17, 17, 2), (x, y, z + 1), blue, 0)
    for index, (dx, dy, length, color) in enumerate((
            (-4, -2, 29, (216, 71, 57)), (4, 0, 33, (239, 182, 45)),
            (0, 4, 31, (82, 155, 99)))):
        paint = classroom_fixture_material("Bookshelf pencil " + str(index), color, roughness=.57)
        lathe("Pencil painted hexagonal barrel", [(1.4, 2), (1.4, length - 4)], paint,
              sectors=6, center=(x + dx, y + dy, z))
        lathe("Pencil sharpened wood", [(1.4, length - 4), (.4, length - 1)], wood,
              sectors=6, center=(x + dx, y + dy, z))
        lathe("Pencil dark point", [(.4, length - 1), (.08, length)], graphite,
              sectors=6, center=(x + dx, y + dy, z))


def bookshelf_dinosaur(x, y, z):
    green = classroom_fixture_material("Bookshelf little green dinosaur", (100, 167, 95), roughness=.57)
    gold = classroom_fixture_material("Bookshelf dinosaur golden plates", (230, 176, 66), roughness=.63)
    eyes = classroom_fixture_material("Bookshelf dinosaur dark eyes", (43, 57, 48), roughness=.48)
    for dx in (-9, 8):
        for dy in (-6, 6):
            box("Dinosaur chunky foot", (7, 6, 8), (x + dx, y + dy, z + 4), green, 1.4)
    ball("Dinosaur rounded body", (x, y, z + 12), 10, green, segments=10, rings=5, scale=(1.6, .8, .85))
    tapered_branch("Dinosaur raised neck", (x + 10, y, z + 13), (x + 17, y, z + 26), (5, 4), green)
    ball("Dinosaur friendly head", (x + 18, y, z + 28), 5.5, green,
         segments=10, rings=5, scale=(1.35, .85, .9))
    tapered_branch("Dinosaur long tail", (x - 12, y, z + 12), (x - 25, y, z + 7), (5, .7), green)
    for dx in (-8, 0, 7):
        ball("Dinosaur small back plate", (x + dx, y, z + 21), 3, gold,
             segments=6, rings=4, scale=(1, .4, 1.25))
    for dy in (-4.25, 4.25):
        ball("Dinosaur dot eye", (x + 21, y + dy, z + 29), .7, eyes, segments=6, rings=4)


def classroom_bookshelf():
    """Five filled maple shelves inside the exact 300 x 85 x 260 cabinet."""
    wood = classroom_fixture_material("Bookshelf warm light maple", (222, 184, 130), wood=True, roughness=.51)
    backing = classroom_fixture_material("Bookshelf pale plywood back", (235, 208, 163), wood=True, roughness=.66)
    for x in (-144, 144):
        box("Bookshelf full-height side", (12, 85, 252), (x, 0, 126), wood, 1.4, 2)
    box("Bookshelf full-width top", (300, 85, 8), (0, 0, 256), wood, 1.4, 2)
    box("Bookshelf closed plywood back", (276, 5, 242), (0, 40, 131), backing, .5)
    box("Bookshelf recessed lower plinth", (276, 7, 10), (0, -32, 5), wood, .5)
    palette = ((201, 69, 58), (55, 129, 184), (232, 177, 55), (85, 153, 103),
               (161, 102, 171), (226, 130, 69), (53, 154, 164))
    for shelf in range(5):
        base = 16 + shelf * 48
        box("Bookshelf raised shelf " + str(shelf + 1), (276, 80, 6),
            (0, -2.5, base - 3), wood, .8)
        cursor = -132
        for index, slot in enumerate((14, 17, 23, 13, 19, 22)):
            lean = -10 if index == 2 else 9 if index == 5 else 0
            width = (9, 13, 10, 10, 15, 11)[index]
            height = 28 + (index * 7 + shelf * 5) % 11
            depth = 35 + (index + shelf) % 4 * 3
            bookshelf_book("Shelf %d left book %d" % (shelf + 1, index + 1), width, depth, height,
                           (cursor + slot / 2, -9 + (index % 2) * 2, base),
                           palette[(index + shelf * 2) % len(palette)], lean, label=index % 3 == 0)
            cursor += slot
        for index in range(3):
            bookshelf_book("Shelf %d right book %d" % (shelf + 1, index + 1),
                           12 + index * 2, 39 - index * 3, 35 - index * 4 + shelf % 3,
                           (39 + index * 18, -7 + index, base), palette[(shelf + index + 3) % len(palette)],
                           label=index == 1)
        for index in range(2):
            bookshelf_book("Shelf %d flat book %d" % (shelf + 1, index + 1),
                           48 - index * 5, 38 - index * 2, 5,
                           (-5 + index * 2, -8 + index, base + index * 5),
                           palette[(shelf + index + 1) % len(palette)], flat=True)
        if shelf == 0:
            bookshelf_dinosaur(110, -8, base)
        elif shelf == 2:
            bookshelf_pencil_pot(110, -7, base)
        elif shelf == 4:
            bookshelf_globe(110, -5, base)
        else:
            for index in range(2):
                bookshelf_book("Shelf %d end book %d" % (shelf + 1, index + 1),
                               14, 38, 30 + index * 6, (100 + index * 19, -8, base),
                               palette[(index + shelf + 5) % len(palette)])


def ceiling_light():
    """White fluorescent fixture, flat ceiling back and recessed egg-crate face."""
    white = classroom_fixture_material("Ceiling light painted metal frame", (237, 239, 234),
                                       metallic=.15, roughness=.44)
    louvre = classroom_fixture_material("Ceiling light white egg-crate louvre", (210, 217, 211),
                                        metallic=.1, roughness=.56)
    glow = classroom_fixture_material("Ceiling light frosted diffuser source", (250, 249, 232), roughness=.8)
    surface_grain(glow, (2, 2, 2), .1, .012, (.985, 1.015))
    rounded_ring("Ceiling light three-stud white frame", (150, 40), (144, 34), 8,
                 (0, 0, 4), white, radius=.8)
    box("Ceiling light flush flat top", (144, 34, 1), (0, 0, 7.5), white, 0)
    box("Ceiling light milky recessed diffuser", (144, 34, 1), (0, 0, 2.8), glow, 0)
    for index in range(1, 36):
        box("Ceiling light lengthwise grid divider", (.35, 34, 1.4),
            (-72 + index * 4, 0, 2.7), louvre, 0)
    for index in range(8):
        box("Ceiling light crosswise grid divider", (144, .35, 1.4),
            (0, -14 + index * 4, 2.7), louvre, 0)


def connected_city_coordinates(mat):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinates = next(node for node in nodes if node.type == "TEX_COORD")
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], xyz.inputs[0])
    return xyz.outputs


def connected_city_paint(mat, mask, color, label):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    mix = nodes.new("ShaderNodeMixRGB")
    mix.name = label
    links.new(mask, mix.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, mix.inputs[1])
    if isinstance(color, tuple):
        mix.inputs[2].default_value = linear(color)
    else:
        links.new(color, mix.inputs[2])
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])


def ruler_section():
    """Flat joining ends, rounded longitudinal edges, repeatable printed faces."""
    wood = material("Connected ruler yellow wood", (225, 184, 114), wood=True,
                    roughness=.53, bevel=.035)
    surface_grain(wood, (.025, 1.4, 1.4), .10, .024, (.95, 1.04))
    xyz = connected_city_coordinates(wood)
    calc = lambda operation, a, b=None: classroom_fixture_math(wood, operation, a, b)
    x = calc("ADD", xyz["X"], 30)
    minor = calc("LESS_THAN", calc("PINGPONG", x, .5), .23)
    medium = calc("LESS_THAN", calc("PINGPONG", x, 2.5), .23)
    major = calc("LESS_THAN", calc("PINGPONG", x, 5), .23)
    length = calc("ADD", 1.8, calc("MAXIMUM", calc("MULTIPLY", medium, 1.2),
                                                   calc("MULTIPLY", major, 3)))
    y = calc("ABSOLUTE", xyz["Y"])
    edge = calc("MULTIPLY", calc("LESS_THAN", y, 13.9),
                calc("GREATER_THAN", y, calc("SUBTRACT", 13.9, length)))
    faces = calc("MAXIMUM", calc("LESS_THAN", xyz["Z"], .01),
                 calc("GREATER_THAN", xyz["Z"], 5.99))
    connected_city_paint(wood, calc("MULTIPLY", faces, calc("MULTIPLY", edge, minor)),
                         (45, 36, 25), "Ten-stud repeating ruler ticks on both faces")

    # Printed numbers are pigment, never extra polygons or raised lettering.
    glyphs = [("010", "110", "010", "010", "111"),
              ("110", "001", "010", "100", "111"),
              ("110", "001", "010", "001", "110"),
              ("101", "101", "111", "001", "001"),
              ("111", "100", "110", "001", "110")]
    pixels = np.zeros((RESOLUTION, RESOLUTION, 4), dtype=np.float32)
    pixels[:, :, 3] = 1
    for index, glyph in enumerate(glyphs):
        center_x = -20 + 10 * index
        for side in (-1, 1):
            for row, bits in enumerate(glyph):
                for column, bit in enumerate(bits):
                    if bit == "1":
                        xs = [round((center_x - 1.05 + (column + offset) * .7 + 30) / 60 * RESOLUTION)
                              for offset in (0, 1)]
                        ys = [round((side * 6.4 + (2 - row + offset) * .65 + 15) / 30 * RESOLUTION)
                              for offset in (0, 1)]
                        pixels[ys[0]:ys[1], xs[0]:xs[1], :3] = 1
    image = bpy.data.images.new("Connected ruler printed numbers", width=RESOLUTION, height=RESOLUTION)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(pixels.ravel())
    image.update()
    image.use_fake_user = True
    image.pack()
    nodes, links = wood.node_tree.nodes, wood.node_tree.links
    vector = nodes.new("ShaderNodeCombineXYZ")
    # Mirror X only on the underside so its numbers read correctly from below.
    bottom = calc("LESS_THAN", xyz["Z"], .01)
    printed_x = calc("MULTIPLY", xyz["X"], calc("SUBTRACT", 1, calc("MULTIPLY", bottom, 2)))
    links.new(calc("DIVIDE", calc("ADD", printed_x, 30), 60), vector.inputs["X"])
    links.new(calc("DIVIDE", calc("ADD", xyz["Y"], 15), 30), vector.inputs["Y"])
    numbers = nodes.new("ShaderNodeTexImage")
    numbers.image, numbers.extension = image, "CLIP"
    links.new(vector.outputs[0], numbers.inputs["Vector"])
    connected_city_paint(wood, calc("MULTIPLY", faces, numbers.outputs["Color"]),
                         (45, 36, 25), "Printed ruler numbers top and bottom")
    outline = []
    for sy, sz, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for angle in np.linspace(start, start + 90, 5):
            t = math.radians(angle)
            outline.append((sy * 14 + math.cos(t), 3 + sz * 2 + math.sin(t)))
    n = len(outline)
    vertices = [(x, y, z) for x in (-30, 30) for y, z in outline]
    polygons = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    polygons += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    finish(mesh("Ruler section with truly flat mating ends", vertices, polygons), wood, weighted=True)


def ruler_tape():
    """One-stud sleeve: unobstructed 30 x 6 cavity, gently uneven cut ends."""
    tape = material("Connected cream masking tape", (231, 209, 172), roughness=.81, bevel=.018)
    surface_grain(tape, (.75, .35, 1.3), .16, .05, (.97, 1.02))
    tape.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = .94
    contours = []
    for half_y, half_z in ((16, 4), (15, 3)):
        contours.append([(half_y, 0), (half_y, half_z), (half_y / 3, half_z),
                         (-half_y / 3, half_z), (-half_y, half_z), (-half_y, 0),
                         (-half_y, -half_z), (-half_y / 3, -half_z),
                         (half_y / 3, -half_z), (half_y, -half_z)])
    n, stations = len(contours[0]), (-5, -3.7, 3.7, 5)
    vertices, polygons = [], []
    for station in stations:
        for contour in contours:
            for i, (y, z) in enumerate(contour):
                wrinkle = .28 * math.sin(math.pi * i / n) ** 2 if abs(station) == 5 else 0
                vertices.append((station - math.copysign(wrinkle, station), y, z + 4))
    for layer in range(len(stations) - 1):
        for contour in range(2):
            for i in range(n):
                a, b = layer * 2 * n + contour * n + i, layer * 2 * n + contour * n + (i + 1) % n
                polygons.append((a, b, b + 2 * n, a + 2 * n))
    for layer in (0, len(stations) - 1):
        offset = layer * 2 * n
        for i in range(n):
            j = (i + 1) % n
            polygons.append((offset + i, offset + j, offset + n + j, offset + n + i))
    finish(mesh("Hollow joint tape with wrinkled cut ends", vertices, polygons), tape,
           smooth=False, weighted=True)


def connected_city_annulus(name, outer, inner, depth, center, mat, sectors=64, soften=.45):
    """Closed rounded wall of an open hoop/tunnel, with no disk across its bore."""
    profile = [(outer - soften, -depth / 2), (outer, -depth / 2 + soften),
               (outer, depth / 2 - soften), (outer - soften, depth / 2),
               (inner + soften, depth / 2), (inner, depth / 2 - soften),
               (inner, -depth / 2 + soften), (inner + soften, -depth / 2)]
    vertices = [(center[0] + radius * math.cos(j * math.tau / sectors),
                 center[1] + axial, center[2] + radius * math.sin(j * math.tau / sectors))
                for radius, axial in profile for j in range(sectors)]
    polygons = []
    for ring in range(8):
        following = (ring + 1) % 8
        for j in range(sectors):
            k = (j + 1) % sectors
            polygons.append((ring * sectors + j, ring * sectors + k,
                             following * sectors + k, following * sectors + j))
    obj = mesh(name, vertices, polygons)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % sectors == b % sectors == 0 or
                         a // sectors == b // sectors and a // sectors in (0, 3, 4, 7))
    finish(obj, mat, uv="unwrap")
    for face in obj.data.polygons:
        if abs(face.normal.y) > .999:
            face.use_smooth = False
    return obj


def connected_city_hanger(label, y, z, mat):
    return connected_city_annulus(label, 3, 1.7, 1.3, (0, y, z + 3), mat,
                                  sectors=24, soften=.15)


def ceiling_ring():
    """Embroidery hoop with spiral paper wraps, tape joins and a tie-on loop."""
    wood = material("Craft hoop exposed honey wood", (225, 184, 114), wood=True,
                    roughness=.62, bevel=.035)
    surface_grain(wood, (.16, .8, .16), .12, .025, (.95, 1.05))
    xyz = connected_city_coordinates(wood)
    calc = lambda operation, a, b=None: classroom_fixture_math(wood, operation, a, b)
    z = calc("SUBTRACT", xyz["Z"], 40)
    angle = calc("ARCTAN2", z, xyz["X"])
    radius = calc("SQRT", calc("ADD", calc("MULTIPLY", z, z),
                              calc("MULTIPLY", xyz["X"], xyz["X"])))
    cross_angle = calc("ARCTAN2", xyz["Y"], calc("SUBTRACT", radius, 35))
    winding = calc("ADD", calc("DIVIDE", calc("MULTIPLY", angle, 18), math.tau),
                    calc("DIVIDE", cross_angle, math.tau))
    fraction = calc("FRACT", winding)
    wrapped = calc("LESS_THAN", fraction, .77)
    palette = wood.node_tree.nodes.new("ShaderNodeValToRGB")
    palette.name = "Six construction paper colours around the hoop"
    palette.color_ramp.interpolation = "CONSTANT"
    colors = [(224, 52, 38), (246, 195, 34), (36, 115, 202),
              (67, 154, 74), (239, 133, 40), (141, 80, 181)]
    for i, color in enumerate(colors):
        element = palette.color_ramp.elements[i] if i < 2 else palette.color_ramp.elements.new(i / 6)
        element.position, element.color = i / 6, linear(color)
    wood.node_tree.links.new(calc("DIVIDE", calc("ADD",
                                  calc("FLOORED_MODULO", calc("FLOOR", winding), 6), .5), 6),
                             palette.inputs[0])
    connected_city_paint(wood, wrapped, palette.outputs["Color"], "Spiralling coloured paper wraps")
    tape = calc("MULTIPLY", calc("GREATER_THAN", fraction, .81),
                calc("LESS_THAN", fraction, .94))
    every_third = calc("LESS_THAN", calc("FLOORED_MODULO", calc("FLOOR", winding), 3), .5)
    connected_city_paint(wood, calc("MULTIPLY", tape, every_third), (231, 209, 172),
                         "Cream tape across a few paper joins")
    connected_city_annulus("Open eighty-stud wrapped embroidery hoop", 40, 30, 8, (0, 0, 40), wood)
    tie = material("Hoop cream cord tie loop", (231, 209, 172), roughness=.88, bevel=.015)
    connected_city_hanger("Hoop top tie loop", 0, 80, tie)


def cardboard_tube():
    """Open kraft tube, darker visible bore, spiral seam and children's paint."""
    kraft = material("Hanging tube warm kraft cardboard", (188, 143, 88), roughness=.84, bevel=.035)
    surface_grain(kraft, (.7, .7, .7), .12, .028, (.96, 1.04))
    xyz = connected_city_coordinates(kraft)
    calc = lambda operation, a, b=None: classroom_fixture_math(kraft, operation, a, b)
    angle = calc("ARCTAN2", calc("SUBTRACT", xyz["Z"], 35), xyz["X"])
    spiral = calc("FRACT", calc("ADD", calc("DIVIDE", angle, math.tau),
                               calc("DIVIDE", calc("ADD", xyz["Y"], 100), 52)))
    seam = calc("LESS_THAN", calc("MINIMUM", spiral, calc("SUBTRACT", 1, spiral)), .014)
    connected_city_paint(kraft, seam, (139, 99, 58), "Rolled cardboard spiral seam")
    wobble = calc("MULTIPLY", calc("SINE", calc("MULTIPLY", angle, 5)), 1.2)
    for position, width, color in ((-63, 5, (224, 52, 38)), (-12, 5.5, (36, 115, 202)),
                                    (58, 4.5, (246, 195, 34))):
        stripe = calc("LESS_THAN", calc("ABSOLUTE", calc("SUBTRACT",
                      calc("ADD", xyz["Y"], wobble), position)), width)
        connected_city_paint(kraft, stripe, color, "Wobbly kid-painted stripe " + str(position))
    for position, azimuth in ((-37, -1.3), (31, -2.45), (78, .25)):
        torn = calc("MULTIPLY", calc("SINE", calc("MULTIPLY", angle, 31)), .8)
        patch = calc("MULTIPLY", calc("LESS_THAN", calc("ABSOLUTE", calc("SUBTRACT",
                     xyz["Y"], calc("ADD", position, torn))), 7),
                     calc("LESS_THAN", calc("ABSOLUTE", calc("SUBTRACT", angle, azimuth)), .20))
        connected_city_paint(kraft, patch, (219, 196, 156), "Torn masking tape patch " + str(position))
    barrel = connected_city_annulus("Two-hundred-stud open cardboard barrel", 35, 31, 200,
                                    (0, 0, 35), kraft)
    inner = material("Hanging tube darker inside kraft", (158, 117, 72), roughness=.90, bevel=.025)
    surface_grain(inner, (.7, .7, .7), .1, .022, (.96, 1.04))
    rim = material("Hanging tube cut cardboard wall", (210, 170, 113), roughness=.86, bevel=.02)
    barrel.data.materials.append(inner)
    barrel.data.materials.append(rim)
    for face in barrel.data.polygons:
        ring = face.index // 64
        face.material_index = 1 if ring in (4, 5, 6) else 2 if ring in (3, 7) else 0
    tie = material("Tube cream hanger loops", (231, 209, 172), roughness=.88, bevel=.015)
    for y in (-70, 70):
        connected_city_hanger("Tube top tie loop " + str(y), y, 70, tie)


def paper_chain_strip_geometry():
    """One 14 x 9 oval, made from a 4-wide, .5-thick curled paper strip."""
    sectors, vertices, polygons = 16, [], []
    radials = []
    for j in range(sectors):
        angle = j * math.tau / sectors
        radials.append(Vector((math.cos(angle) / 6.75, math.sin(angle) / 4.25, 0)).normalized())
    for wall, depth in ((.25, -2), (.25, 2), (-.25, 2), (-.25, -2)):
        for j in range(sectors):
            angle = j * math.tau / sectors
            vertices.append(Vector((6.75 * math.cos(angle), 4.25 * math.sin(angle), depth)) +
                            radials[j] * wall)
    for ring in range(4):
        for j in range(sectors):
            k, following = (j + 1) % sectors, (ring + 1) % 4
            polygons.append((ring * sectors + j, ring * sectors + k,
                             following * sectors + k, following * sectors + j))
    # The strip's end is glued against its inside face. A second paper layer
    # makes a real transverse lip, while the outside oval keeps the same shape.
    overlap = polygons[2 * sectors + 4]
    raised = tuple(range(len(vertices), len(vertices) + 4))
    vertices.extend(vertices[i] - radials[i % sectors] * .5 for i in overlap)
    polygons[2 * sectors + 4] = raised
    for j in range(4):
        k = (j + 1) % 4
        polygons.append((overlap[j], overlap[k], raised[k], raised[j]))
    return vertices, polygons, radials


def connected_city_chain_link(index, center, tangent, face_on, mat):
    tangent = Vector(tangent).normalized()
    upright = Vector((-tangent.z, 0, tangent.x))
    # Rotate both alternating planes away from the viewing plane. The paper
    # faces remain visible even in the straight side view, rather than becoming
    # wire outlines on every other link. Adjacent loops differ by 90 degrees.
    across = (upright + Vector((0, 1 if face_on else -1, 0))).normalized()
    normal = tangent.cross(across).normalized()
    local, polygons, radials = paper_chain_strip_geometry()
    vertices = [Vector(center) + tangent * p.x + across * p.y + normal * p.z for p in local]
    obj = mesh("Construction paper interlocking link " + str(index + 1), vertices, polygons)
    for edge in obj.data.edges:
        a, b = edge.vertices
        edge.use_seam = (a % 16 == b % 16 == 0 or a // 16 == b // 16 == 0 or a >= 64 or b >= 64)
    finish(obj, mat, uv="unwrap")
    normals = []
    for face in obj.data.polygons:
        ring = face.index // 16
        face.use_smooth = ring in (0, 2)
        for loop_index in face.loop_indices:
            vertex = obj.data.loops[loop_index].vertex_index
            if ring in (0, 2):
                original = vertex if vertex < 64 else polygons[2 * 16 + 4].index(vertex)
                sector = original % 16 if vertex < 64 else (4, 5, 5, 4)[original]
                radial = radials[sector]
                n = (tangent * radial.x + across * radial.y) * (1 if ring == 0 else -1)
            else:
                n = normal if ring == 1 else -normal if ring == 3 else face.normal
            normals.append(n)
    obj.data.normals_split_custom_set(normals)
    return obj, [list(Vector(center)), list(tangent), list(across), list(normal)]


def paper_chain():
    """Identical curled paper strips, threaded along the original garland sag."""
    colors = [(224, 52, 38), (246, 195, 34), (36, 115, 202),
              (67, 154, 74), (239, 133, 40), (141, 80, 181)]
    paints = [material("Paper chain construction paper " + label, color, roughness=.90, bevel=.004)
              for label, color in zip(("red", "yellow", "blue", "green", "orange", "purple"), colors)]
    for paint in paints:
        surface_grain(paint, (2, 2, 2), .10, .015, (.985, 1.015))
        bsdf = paint.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Coat Weight"].default_value = 0
        bsdf.inputs["Specular IOR Level"].default_value = .18
    # Smaller loops need more links to cover the same span and drop. Fit their
    # positions, never stretch the strips or make special oversized end loops.
    count = 43
    local = np.array([tuple(p) for p in paper_chain_strip_geometry()[0]])
    signs = np.where(np.arange(count) % 2 == 0, 1, -1)

    def layout(a, span, depth=0):
        arcs = np.linspace(-1, 1, count) * a * math.sinh(span / a)
        xs = a * np.arcsinh(arcs / a)
        tangents = np.stack((np.ones(count), np.zeros(count), np.sinh(xs / a)), axis=1)
        tangents /= np.linalg.norm(tangents, axis=1)[:, None]
        across = np.stack((-tangents[:, 2], signs, tangents[:, 0]), axis=1) / math.sqrt(2)
        normals = np.cross(tangents, across)
        centers = np.stack((xs, depth * np.sin(math.pi * xs / span) ** 3,
                            a * (np.cosh(xs / a) - 1)), axis=1)
        points = (centers[:, None, :] + tangents[:, None, :] * local[None, :, 0:1] +
                  across[:, None, :] * local[None, :, 1:2] + normals[:, None, :] * local[None, :, 2:3])
        return points, centers, tangents

    def fit_span(a):
        low, high = 90., 110.
        for _ in range(32):
            span = (low + high) / 2
            if np.ptp(layout(a, span)[0][:, :, 0]) < 220:
                low = span
            else:
                high = span
        return span

    low, high = 25., 100.
    for _ in range(32):
        a = (low + high) / 2
        span = fit_span(a)
        if np.ptp(layout(a, span)[0][:, :, 2]) > 176:
            low = a
        else:
            high = a
    # A slight natural depth drape keeps the exact 12-stud envelope without
    # inflating the 4-stud paper width or the 9-stud loop diameter.
    low, high = 0., 3.
    for _ in range(32):
        depth = (low + high) / 2
        if np.ptp(layout(a, span, depth)[0][:, :, 1]) < 12:
            low = depth
        else:
            high = depth
    points, centers, tangents = layout(a, span, depth)
    bottom = points.reshape((-1, 3))
    bottom = bottom[bottom[:, 2] <= bottom[:, 2].min() + .005]
    origin = (bottom.min(axis=0) + bottom.max(axis=0)) / 2
    centers -= origin
    frames = []
    for index, (center, tangent) in enumerate(zip(centers, tangents)):
        _, frame = connected_city_chain_link(index, center, tangent, index % 2 == 0, paints[index % 6])
        frames.append(frame)
    PARTS[0]["paper_chain_frames"] = json.dumps(frames)
    PARTS[0]["paper_chain_catenary"] = json.dumps([a, span, depth, list(origin)])


def chalk_eraser_sheet_surface(mat, sheet, crops, bottom, dimensions):
    """Sample only flat interiors, excluding photographed edges/highlights.

    The approved sheet supplies the natural grain/fibre detail. Roundovers,
    lighting and fine bump are supplied by the actual mesh and material.
    Internal source images are packed in the blend, never linked elsewhere.
    """
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    geometry = nodes.new("ShaderNodeNewGeometry")
    position, normal = nodes.new("ShaderNodeSeparateXYZ"), nodes.new("ShaderNodeSeparateXYZ")
    links.new(geometry.outputs["Position"], position.inputs[0])
    links.new(geometry.outputs["Normal"], normal.inputs[0])
    axes = []
    for i, offset in enumerate((dimensions[0] / 2, dimensions[1] / 2, -bottom)):
        add = nodes.new("ShaderNodeMath")
        add.operation = "ADD"
        links.new(position.outputs[i], add.inputs[0])
        add.inputs[1].default_value = offset
        divide = nodes.new("ShaderNodeMath")
        divide.operation = "DIVIDE"
        links.new(add.outputs[0], divide.inputs[0])
        divide.inputs[1].default_value = dimensions[i]
        axes.append(divide.outputs[0])
    surfaces = []
    for label, crop, uv_axes in zip(("front", "top", "end"), crops, ((0, 2), (0, 1), (1, 2))):
        h, w = sheet.shape[:2]
        x0, y0, x1, y1 = [round(v * s) for v, s in zip(crop, (w, h, w, h))]
        pixels = sheet[y0:y1, x0:x1][::-1].astype(np.float32) / 255
        # Decode explicitly and mark the generated source as Non-Color so
        # an image texture never decodes these linear values a second time.
        pixels = np.where(pixels <= .04045, pixels / 12.92, ((pixels + .055) / 1.055) ** 2.4)
        values = np.ones((*pixels.shape[:2], 4), dtype=np.float32)
        values[:, :, :3] = pixels
        image = bpy.data.images.new(mat.name + " approved " + label + " detail", width=x1 - x0, height=y1 - y0,
                                    float_buffer=True)
        image.colorspace_settings.name = "Non-Color"
        image.file_format = "OPEN_EXR"
        image.pixels.foreach_set(values.ravel())
        image.pack()
        image.use_fake_user = True
        tex = nodes.new("ShaderNodeTexImage")
        tex.image, tex.extension = image, "EXTEND"
        uv = nodes.new("ShaderNodeCombineXYZ")
        for i, axis in enumerate(uv_axes):
            links.new(axes[axis], uv.inputs[i])
        links.new(uv.outputs[0], tex.inputs["Vector"])
        surfaces.append(tex.outputs["Color"])
    color = surfaces[0]
    for other, axis in ((surfaces[1], 2), (surfaces[2], 0)):
        absolute = nodes.new("ShaderNodeMath")
        absolute.operation = "ABSOLUTE"
        links.new(normal.outputs[axis], absolute.inputs[0])
        weight = nodes.new("ShaderNodeMath")
        weight.operation = "POWER"
        weight.inputs[1].default_value = 4
        links.new(absolute.outputs[0], weight.inputs[0])
        blend = nodes.new("ShaderNodeMixRGB")
        links.new(weight.outputs[0], blend.inputs[0])
        links.new(color, blend.inputs[1])
        links.new(other, blend.inputs[2])
        color = blend.outputs[0]
    paint = next(n for n in nodes if n.type == "MIX_RGB" and n.blend_type == "MULTIPLY")
    links.new(color, paint.inputs[1])
    links.new(color, next(n for n in nodes if n.type == "BUMP").inputs["Height"])


def chalk_eraser():
    """Approved model-sheet.png only; Blender XYZ becomes Roblox XZY."""
    oak = material("Chalk eraser honey golden oak", (190, 129, 66),
                   wood=True, roughness=.29, bevel=.035)
    # Object-space grain continues around the real roundovers. X is the long
    # direction, including on the top; the YZ end faces expose the grain ends.
    surface_grain(oak, (.045, 2.6, 2.6), .28, .12, (.96, 1.04))
    sheet = png_read(OUTPUT / "chalk-eraser/model-sheet.png")
    chalk_eraser_sheet_surface(oak, sheet,
                             ((.065, .214, .538, .293), (.069, .573, .535, .778),
                              (.723, .214, .849, .293)), 10.5, (92, 29, 14.5))
    box("Rounded golden oak block", (92, 29, 14.5), (0, 0, 17.75), oak,
        radius=2.4, segments=6)

    felt = material("Chalk eraser charcoal felt", (32, 33, 34),
                    roughness=.94, bevel=.015)
    surface_grain(felt, (3.8, 3.8, 3.8), .55, .24, (.90, 1.10))
    chalk_eraser_sheet_surface(felt, sheet,
                             ((.068, .316, .536, .383), (.068, .316, .536, .383),
                              (.726, .318, .844, .376)), 0, (89.6, 26.6, 10.5))
    nodes, links = felt.node_tree.nodes, felt.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Coat Weight"].default_value = 0
    bsdf.inputs["Specular IOR Level"].default_value = .16
    coordinates = next(n for n in nodes if n.type == "TEX_COORD")
    stretch = nodes.new("ShaderNodeVectorMath")
    stretch.operation = "MULTIPLY"
    stretch.inputs[1].default_value = (1.2, 8, 12)
    links.new(coordinates.outputs["Object"], stretch.inputs[0])
    fibres = nodes.new("ShaderNodeTexNoise")
    fibres.inputs["Scale"].default_value = 1
    fibres.inputs["Detail"].default_value = 2.5
    fibres.inputs["Roughness"].default_value = .7
    links.new(stretch.outputs[0], fibres.inputs["Vector"])
    fuzz = nodes.new("ShaderNodeMapRange")
    fuzz.clamp = True
    fuzz.inputs["From Min"].default_value = .52
    fuzz.inputs["From Max"].default_value = .68
    fuzz.inputs["To Max"].default_value = .17
    links.new(fibres.outputs["Fac"], fuzz.inputs["Value"])
    tint = nodes.new("ShaderNodeMixRGB")
    tint.name = "Loose pale grey felt fibres"
    links.new(fuzz.outputs[0], tint.inputs[0])
    links.new(bsdf.inputs["Base Color"].links[0].from_socket, tint.inputs[1])
    tint.inputs[2].default_value = linear((97, 100, 102))
    links.new(tint.outputs[0], bsdf.inputs["Base Color"])
    bump = next(n for n in nodes if n.type == "BUMP")
    fine_bump = nodes.new("ShaderNodeBump")
    fine_bump.inputs["Strength"].default_value = .25
    fine_bump.inputs["Distance"].default_value = .10
    links.new(bump.outputs["Normal"], fine_bump.inputs["Normal"])
    links.new(fibres.outputs["Fac"], fine_bump.inputs["Height"])
    links.new(fine_bump.outputs["Normal"], bsdf.inputs["Normal"])
    xyz = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coordinates.outputs["Object"], xyz.inputs[0])
    lower_edge = nodes.new("ShaderNodeMapRange")
    lower_edge.clamp = True
    lower_edge.inputs["From Max"].default_value = 2.7
    lower_edge.inputs["To Min"].default_value = .35
    lower_edge.inputs["To Max"].default_value = 0
    links.new(xyz.outputs["Z"], lower_edge.inputs["Value"])
    specks = nodes.new("ShaderNodeMath")
    specks.operation = "GREATER_THAN"
    specks.inputs[1].default_value = .62
    links.new(fibres.outputs["Fac"], specks.inputs[0])
    mask = nodes.new("ShaderNodeMath")
    mask.operation = "MULTIPLY"
    links.new(lower_edge.outputs[0], mask.inputs[0])
    links.new(specks.outputs[0], mask.inputs[1])
    dust = nodes.new("ShaderNodeMixRGB")
    dust.name = "A few chalk dust specks along the lower edge"
    links.new(mask.outputs[0], dust.inputs[0])
    links.new(tint.outputs[0], dust.inputs[1])
    dust.inputs[2].default_value = linear((177, 179, 177))
    links.new(dust.outputs[0], bsdf.inputs["Base Color"])
    box("Inset rounded felt pad", (89.6, 26.6, 10.5), (0, 0, 5.25), felt,
        radius=1, segments=6)


def chalk_eraser_uv(obj):
    """Two simple material bands, avoiding symbol-like atlas silhouettes."""
    settings = bpy.context.scene.tool_settings
    previous_sync, previous_mode = settings.use_uv_select_sync, tuple(settings.mesh_select_mode)
    settings.use_uv_select_sync = True
    settings.mesh_select_mode = (False, False, True)
    try:
        for piece_id, offset in ((0, .51), (1, .01)):
            bpy.ops.object.mode_set(mode="EDIT")
            bm = bmesh.from_edit_mesh(obj.data)
            piece = bm.faces.layers.int["toy_piece"]
            for face in bm.faces:
                face.select_set(face[piece] == piece_id)
            bmesh.update_edit_mesh(obj.data)
            bpy.ops.uv.average_islands_scale()
            bpy.ops.uv.pack_islands(rotate=True, margin_method="FRACTION", margin=PADDING * 2.2,
                                   shape_method="CONVEX", scale=True)
            bpy.ops.object.mode_set(mode="OBJECT")
            uv, pieces = obj.data.uv_layers.active.data, obj.data.attributes["toy_piece"].data
            for face in obj.data.polygons:
                if pieces[face.index].value == piece_id:
                    for index in face.loop_indices:
                        uv[index].uv = (.01 + uv[index].uv.x * .98, offset + uv[index].uv.y * .48)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.object.mode_set(mode="OBJECT")
    finally:
        if obj.mode != "OBJECT":
            bpy.ops.object.mode_set(mode="OBJECT")
        settings.use_uv_select_sync, settings.mesh_select_mode = previous_sync, previous_mode


def chalk_eraser_checks(obj):
    components = sorted(classroom_components(obj), key=lambda c: min(p.z for p in c))
    assert len(components) == 2, "Eraser must have only oak and felt in one mesh"
    report = {}
    for points, label, expected, bottom, radius in (
            (components[0], "felt", (89.6, 26.6, 10.5), 0, 1),
            (components[1], "wood", (92, 29, 14.5), 10.5, 2.4)):
        lo = Vector([min(p[i] for p in points) for i in range(3)])
        hi = Vector([max(p[i] for p in points) for i in range(3)])
        assert (hi - lo - Vector(expected)).length < .001, (label, "Wrong dimensions")
        assert abs(lo.z - bottom) < .001, (label, "Wrong layer height")
        assert abs(lo.x + hi.x) < .001 and abs(lo.y + hi.y) < .001, "Layers must be centered"
        # The flat cap ends one real bevel radius short of every outer edge.
        cap = [p for p in points if abs(p.z - hi.z) < .0001]
        radii = [expected[i] / 2 - max(abs(p[i]) for p in cap) for i in (0, 1)]
        assert all(abs(r - radius) < .001 for r in radii), (label, "Wrong rounded edges", radii)
        report[label + "_size_roblox_xyz_studs"] = [expected[0], expected[2], expected[1]]
        report[label + "_radius_studs"] = radius
    report["felt_inset_studs"] = 1.2
    size = bounds(obj)[2]
    report["size_roblox_xyz_studs"] = [round(size.x, 3), round(size.z, 3), round(size.y, 3)]
    return report


def chalk_eraser_render(obj, folder):
    """Four exported/baked views, laid out exactly like the approved sheet."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 64
    scene.render.resolution_x = scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    world = bpy.data.worlds.new("Neutral grey eraser studio")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = linear((235, 235, 235))
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = .76
    center, scale = Vector((0, 0, 12.5)), 92
    for label, direction, strength, size in (
            ("Eraser broad key", (-.6, -1, 1.1), 24, 1.3),
            ("Eraser end fill", (1, -.3, .8), 13, 1.4),
            ("Eraser upper rim", (.3, 1, 1.5), 8.5, 1.2)):
        data = bpy.data.lights.new(label, "AREA")
        light = bpy.data.objects.new(label, data)
        scene.collection.objects.link(light)
        light.location = center + Vector(direction) * scale * 1.6
        data.energy, data.shape, data.size = strength * scale ** 2, "DISK", size * scale
        point_at(light, center)
    camera = bpy.data.objects.new("Eraser sheet camera", bpy.data.cameras.new("Eraser camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type, camera.data.clip_end = "ORTHO", 1500
    reference = png_read(folder / "model-sheet.png")
    height, width = reference.shape[:2]
    background = (192, 192, 192)
    sheet = np.full_like(reference, background)
    # Bounds from this sheet, never a substitute eraser picture. Orthographic
    # cameras preserve the requested physical sizes when the drawing differs.
    views = [("front.png", (0, -1, 0), (.053, .185, .550, .388)),
             ("end.png", (1, 0, 0), (.714, .185, .860, .388)),
             ("top.png", (0, 0, 1), (.055, .551, .549, .802)),
             ("three-quarter.png", (.83, -1, .64), (.589, .515, .961, .882))]
    for filename, direction, rect in views:
        camera.location = center + Vector(direction).normalized() * scale * 4
        point_at(camera, center)
        view = camera.rotation_euler.to_matrix().transposed()
        cloud = [view @ (v.co - center) for v in obj.data.vertices]
        low = Vector((min(p.x for p in cloud), min(p.y for p in cloud), 0))
        high = Vector((max(p.x for p in cloud), max(p.y for p in cloud), 0))
        camera.data.ortho_scale = max(high.x - low.x, high.y - low.y) / .90
        camera.location += camera.rotation_euler.to_matrix() @ ((low + high) / 2)
        scene.render.filepath = str(folder / filename)
        print("RENDERING chalk-eraser", filename, "FBX mesh and baked maps", flush=True)
        bpy.ops.render.render(write_still=True)
        rgba = png_read(folder / filename, alpha=True).astype(np.float32)
        alpha = rgba[:, :, 3:4] / 255
        pixels = np.rint(rgba[:, :, :3] * alpha + np.array(background) * (1 - alpha)).astype(np.uint8)
        png_write(folder / filename, pixels)
        ys, xs = np.where(rgba[:, :, 3] > 0)
        crop = pixels[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        left, top, right, bottom = [round(v * s) for v, s in zip(rect, (width, height, width, height))]
        factor = min((right - left) / crop.shape[1], (bottom - top) / crop.shape[0])
        h, w = round(crop.shape[0] * factor), round(crop.shape[1] * factor)
        image = bpy.data.images.new("Temporary eraser view resize", width=crop.shape[1], height=crop.shape[0])
        values = np.ones((*crop.shape[:2], 4), dtype=np.float32)
        values[:, :, :3] = crop[::-1] / 255
        image.pixels.foreach_set(values.ravel())
        image.scale(w, h)
        resized = np.empty(w * h * 4, dtype=np.float32)
        image.pixels.foreach_get(resized)
        resized = np.clip(np.rint(resized.reshape(h, w, 4)[::-1, :, :3] * 255), 0, 255).astype(np.uint8)
        bpy.data.images.remove(image)
        x, y = (left + right - w) // 2, (top + bottom - h) // 2
        sheet[y:y + h, x:x + w] = resized
    png_write(folder / "renders-sheet.png", sheet)
    (folder / "render.png").write_bytes((folder / "three-quarter.png").read_bytes())
    active(obj)


def desk_piece_paper(label, color, grain=.012):
    mat = material(label, color, roughness=.88, bevel=.003)
    surface_grain(mat, (1.8, 1.8, 1.8), .12, grain, (.97, 1.03))
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Coat Weight"].default_value = 0
    bsdf.inputs["Specular IOR Level"].default_value = .18
    return mat


def landing_link_geometry(a=9.6, b=3.4, half_width=1.5):
    """A broad paper strip, including its doubled, glued end on the inside."""
    sectors, wall = 24, .16
    vertices, faces, radials = [], [], []
    for j in range(sectors):
        t = j * math.tau / sectors
        radials.append(Vector((math.cos(t) / a, math.sin(t) / b, 0)).normalized())
    for offset, width in ((wall / 2, -half_width), (wall / 2, half_width),
                          (-wall / 2, half_width), (-wall / 2, -half_width)):
        for j in range(sectors):
            t = j * math.tau / sectors
            vertices.append(Vector((a * math.cos(t), b * math.sin(t), width)) + radials[j] * offset)
    for ring in range(4):
        for j in range(sectors):
            k, following = (j + 1) % sectors, (ring + 1) % 4
            faces.append((ring * sectors + j, ring * sectors + k,
                          following * sectors + k, following * sectors + j))
    overlap = faces[2 * sectors + 6]
    raised = tuple(range(len(vertices), len(vertices) + 4))
    vertices.extend(vertices[i] - radials[i % sectors] * wall for i in overlap)
    faces[2 * sectors + 6] = raised
    for j in range(4):
        k = (j + 1) % 4
        faces.append((overlap[j], overlap[k], raised[k], raised[j]))
    return vertices, faces


def landing_ring():
    colors = [(224, 52, 38), (36, 115, 202), (246, 195, 34), (67, 154, 74)]
    paints = [desk_piece_paper("Landing ring " + label + " construction paper", color)
              for label, color in zip(("red", "blue", "yellow", "green"), colors)]
    local, faces = landing_link_geometry()
    layouts = []
    for i in range(14):
        angle = i * math.tau / 14
        radial = Vector((math.cos(angle), 0, math.sin(angle)))
        tangent = Vector((-math.sin(angle), 0, math.cos(angle)))
        across = (radial + Vector((0, 1 if i % 2 == 0 else -1, 0))).normalized()
        normal = tangent.cross(across).normalized()
        center = radial * 33.7
        layouts.append(([center + tangent * p.x + across * p.y + normal * p.z for p in local],
                        center, tangent, across, normal))
    cloud = np.array([tuple(p) for points, *_ in layouts for p in points])
    factors = Vector((74 / np.ptp(cloud[:, 0]), 8 / np.ptp(cloud[:, 1]), 74 / np.ptp(cloud[:, 2])))
    offset = Vector((float((cloud[:, 0].min() + cloud[:, 0].max()) / 2),
                     float((cloud[:, 1].min() + cloud[:, 1].max()) / 2),
                     float((cloud[:, 2].min() + cloud[:, 2].max()) / 2)))
    frames = []
    for i, (points, center, tangent, across, normal) in enumerate(layouts):
        obj = mesh("Landing paper link " + str(i + 1), [(p - offset) * factors for p in points], faces)
        for edge in obj.data.edges:
            a, b = edge.vertices
            edge.use_seam = (a % 24 == b % 24 == 0 or a // 24 == b // 24 == 0 or a >= 96 or b >= 96)
        finish(obj, paints[i % 4], uv="unwrap")
        for face in obj.data.polygons:
            face.use_smooth = face.index // 24 in (0, 2)
        frames.append([list(center), list(tangent), list(across), list(normal)])
    PARTS[0]["landing_frames"] = json.dumps(frames)
    PARTS[0]["landing_scale"] = list(factors)
    PARTS[0]["landing_offset"] = list(offset)


def speed_bolt():
    """A closed doubled paper silhouette with crisp, non-coplanar folded faces."""
    from mathutils.geometry import tessellate_polygon
    outline = [(-4.5, -1.5), (-1.2, 6.3), (4.2, 8), (1, 1.1),
               (4.5, 1.6), (-3.8, -8), (-1, -2)]
    folds = [.95, -1.25, .7, .25, 1.13, .35, -1.1]
    vertices = [(x, y + layer * .12, z) for layer in (0, 1) for (x, z), y in zip(outline, folds)]
    flat = [Vector((x, z, 0)) for x, z in outline]
    lookup = {tuple(p): i for i, p in enumerate(flat)}
    triangles = [tuple(p if isinstance(p, int) else lookup[tuple(p)] for p in face)
                 for face in tessellate_polygon([flat])]
    n = len(outline)
    faces = triangles + [tuple(i + n for i in reversed(face)) for face in triangles]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    obj = mesh("Folded doubled yellow lightning paper", vertices, faces)
    finish(obj, desk_piece_paper("Bright yellow folded paper", (255, 205, 36), .023), smooth=False)
    obj["paper_layer_thickness"] = .12


def runway_light_geometry(tip=False):
    perimeter = [(-1.5, -1.5), (0, -1.38), (1.5, -1.5), (1.38, 0),
                 (1.5, 1.5), (0, 1.38), (-1.5, 1.5), (-1.38, 0)]
    small = [(x * .225, y * .225, 3.1) for x, y in perimeter]
    if tip:
        vertices = small + [(0, 0, 4)]
        faces = [tuple(reversed(range(8)))] + [(i, (i + 1) % 8, 8) for i in range(8)]
    else:
        vertices = [(x, y, 0) for x, y in perimeter] + small
        faces = [tuple(reversed(range(8))), tuple(range(8, 16))]
        faces += [(i, (i + 1) % 8, (i + 1) % 8 + 8, i + 8) for i in range(8)]
    return vertices, faces


def runway_light():
    vertices, faces = runway_light_geometry()
    finish(mesh("Folded ivory landing light body", vertices, faces),
           desk_piece_paper("Ivory landing light paper", (241, 221, 172)), smooth=False)


def runway_light_tip():
    vertices, faces = runway_light_geometry(tip=True)
    finish(mesh("runway-light-tip", vertices, faces),
           desk_piece_paper("Pale warm separately lightable tip", (255, 242, 184)), smooth=False)


def desk_runway_paint():
    """Marker and crayon strokes in the sheet's unbent coordinates, never geometry."""
    mat = desk_piece_paper("Kraft cardboard with drawn runway", (191, 145, 93), .035)
    surface_grain(mat, (.6, .6, .6), .18, .035, (.93, 1.07))
    pixels = np.zeros((RESOLUTION, RESOLUTION, 4), dtype=np.float32)
    rng = np.random.default_rng(121026)
    grain = rng.uniform(.48, 1, (RESOLUTION, RESOLUTION))

    def stroke(a, b, width, color, crayon=False):
        ax, ay = (a[0] + 50) / 100 * RESOLUTION, a[1] / 256 * RESOLUTION
        bx, by = (b[0] + 50) / 100 * RESOLUTION, b[1] / 256 * RESOLUTION
        # Distance in studs keeps strokes round despite the non-square artwork.
        lo = np.maximum(np.floor((min(ax, bx) - width * RESOLUTION / 100,
                                  min(ay, by) - width * RESOLUTION / 256)).astype(int), 0)
        hi = np.minimum(np.ceil((max(ax, bx) + width * RESOLUTION / 100 + 1,
                                 max(ay, by) + width * RESOLUTION / 256 + 1)).astype(int), RESOLUTION)
        if np.any(hi <= lo):
            return
        xx, yy = np.meshgrid((np.arange(lo[0], hi[0]) + .5) / RESOLUTION * 100 - 50,
                             (np.arange(lo[1], hi[1]) + .5) / RESOLUTION * 256)
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = np.clip(((xx - a[0]) * dx + (yy - a[1]) * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
        distance = np.hypot(xx - a[0] - t * dx, yy - a[1] - t * dy)
        opacity = np.clip((width / 2 - distance) * 7, 0, 1)
        if crayon:
            opacity *= grain[lo[1]:hi[1], lo[0]:hi[0]]
        region = pixels[lo[1]:hi[1], lo[0]:hi[0]]
        hit = opacity > region[:, :, 3]
        region[hit, :3] = linear(color)[:3]
        region[hit, 3] = opacity[hit]

    for y in range(73, 256, 23):
        stroke((.12 * math.sin(y), y), (.2 * math.cos(y), min(y + 10, 256)), 3.4, (252, 193, 42), True)
    for sign in (-1, 1):
        for y in range(86, 256, 4):
            stroke((sign * 36 + .18 * math.sin(y * .2), y),
                   (sign * 36 + .18 * math.sin((y + 4) * .2), y + 4), 1.3, (33, 100, 183), True)
        for _ in range(66):
            x, y = sign * rng.uniform(38, 48), rng.uniform(10, 65)
            stroke((x, y), (x + rng.uniform(-3, 3), y + rng.uniform(3, 10)),
                   rng.uniform(.7, 1.4), (57, 141, 70), True)
        for y in (73, 78):
            stroke((sign * 39, y), (sign * 43, y + 3), 1.3, (213, 59, 43), True)
            stroke((sign * 43, y + 3), (sign * 47, y), 1.3, (213, 59, 43), True)
    image = bpy.data.images.new("Drawn runway pigment source", width=RESOLUTION, height=RESOLUTION, alpha=True)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(pixels.ravel())
    image.update()
    image.pack()
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coordinate = nodes.new("ShaderNodeAttribute")
    coordinate.attribute_name = "sheet_coordinates"
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.extension = "EXTEND"
    links.new(coordinate.outputs["Vector"], tex.inputs["Vector"])
    bsdf = nodes["Principled BSDF"]
    original = bsdf.inputs["Base Color"].links[0].from_socket
    mix = nodes.new("ShaderNodeMixRGB")
    links.new(tex.outputs["Alpha"], mix.inputs[0])
    links.new(original, mix.inputs[1])
    links.new(tex.outputs["Color"], mix.inputs[2])
    links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    return mat


def desk_runway_edge_material():
    mat = desk_piece_paper("Exposed corrugated kraft cut edge", (96, 65, 38), .009)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    attr = nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "sheet_coordinates"
    separate = nodes.new("ShaderNodeSeparateXYZ")
    links.new(attr.outputs["Vector"], separate.inputs[0])
    # Both end cuts and long sides reveal repeated flutes between two liners.
    u = classroom_fixture_math(mat, "MULTIPLY", separate.outputs["X"], 100)
    v = classroom_fixture_math(mat, "MULTIPLY", separate.outputs["Y"], 256)
    phase = classroom_fixture_math(mat, "MULTIPLY", classroom_fixture_math(mat, "ADD", u, v), math.tau / 2.6)
    wave = classroom_fixture_math(mat, "MULTIPLY", classroom_fixture_math(mat, "SINE", phase), .31)
    target = classroom_fixture_math(mat, "ADD", wave, .5)
    distance = classroom_fixture_math(mat, "ABSOLUTE", classroom_fixture_math(mat, "SUBTRACT", separate.outputs["Z"], target))
    flute = classroom_fixture_math(mat, "LESS_THAN", distance, .065)
    low = classroom_fixture_math(mat, "LESS_THAN", separate.outputs["Z"], .12)
    high = classroom_fixture_math(mat, "GREATER_THAN", separate.outputs["Z"], .88)
    mask = classroom_fixture_math(mat, "MAXIMUM", flute, classroom_fixture_math(mat, "MAXIMUM", low, high))
    connected_city_paint(mat, mask, (218, 174, 117), "Visible wavy flutes and paper liners")
    bump = next(node for node in nodes if node.type == "BUMP")
    bump.inputs["Strength"].default_value = .22
    bump.inputs["Distance"].default_value = .04
    links.new(mask, bump.inputs["Height"])
    return mat


def desk_runway(droop=True):
    top, edge = desk_runway_paint(), desk_runway_edge_material()
    underside = desk_piece_paper("Plain kraft cardboard underside", (177, 128, 76), .025)
    fractions = [-1, -.88, -.65, -.35, 0, .35, .65, .88, 1]
    shared = [0, 4, 18, 36, 54, 70, 85, 86, 86.6, 100, 120, 140, 160, 180, 200, 210, 216]
    rows = shared + ([217, 218, 220, 222, 224, 226, 227, 228, 232, 238, 246, 256]
                     if droop else [228, 240, 251])
    points, coordinates, normals = [], [], []
    for row, s in enumerate(rows):
        half_width = 50 if s <= 86 else 44
        if s <= 216 or not droop:
            y, z, angle = s, 0, 0
        else:
            length = s - 216
            bend = 7 * math.pi / 2
            angle = min(length / 7, math.pi / 2)
            y, z = 216 + 7 * math.sin(angle), 7 * (math.cos(angle) - 1)
            if length > bend:
                tail = length - bend
                # A loose hanging sheet, with a slight curl at the last few studs.
                y += 1.6 * (tail / (40 - bend)) ** 3
                z -= tail
                angle = math.pi / 2 - math.atan(4.8 * tail ** 2 / (40 - bend) ** 3)
        normal = Vector((0, math.sin(angle), math.cos(angle)))
        for column, fraction in enumerate(fractions):
            ragged = .28 * math.sin(row * 2.3 + column * 1.9) if abs(fraction) == 1 and row not in (0, 2, 9) else 0
            x = fraction * half_width + ragged
            if abs(fraction) == 1:
                x = max(-half_width, min(half_width, x))
            progress = min(max((s - 216) / 40, 0), 1) if droop else 0
            sag = -.85 * fraction ** 2 * progress
            warp = .12 * math.sin(x / 18) * math.sin(min(s, 216) / 24)
            dent = -.23 * math.exp(-((x + 18) / 12) ** 2 - ((s - 116) / 16) ** 2)
            dent -= .18 * math.exp(-((x - 23) / 10) ** 2 - ((s - 46) / 14) ** 2)
            points.append(Vector((x, y, z + sag)) + normal * (warp + dent))
            coordinates.append(((x + 50) / 100, s / 256, 1))
            normals.append(normal)
    n, columns = len(points), len(fractions)
    vertices = points + [p - normal * 1.2 for p, normal in zip(points, normals)]
    coordinates += [(u, v, 0) for u, v, _ in coordinates[:]]
    faces, assignments = [], []
    for row in range(len(rows) - 1):
        for column in range(columns - 1):
            a, b = row * columns + column, (row + 1) * columns + column
            faces += [(a, a + 1, b + 1, b), (a + n, b + n, b + 1 + n, a + 1 + n)]
            assignments += [0, 1]
    perimeter = (list(range(columns)) + [r * columns + columns - 1 for r in range(1, len(rows))] +
                 list(range(n - 2, n - columns - 1, -1)) + [r * columns for r in range(len(rows) - 2, 0, -1)])
    for i, a in enumerate(perimeter):
        b = perimeter[(i + 1) % len(perimeter)]
        faces.append((a, a + n, b + n, b))
        assignments.append(2)
    obj = mesh("One continuous cut and bent cardboard runway", vertices, faces)
    finish(obj, top, smooth=False)
    obj.data.materials.append(underside)
    obj.data.materials.append(edge)
    for face, slot in zip(obj.data.polygons, assignments):
        face.material_index = slot
    attr = obj.data.attributes.new("sheet_coordinates", "FLOAT_VECTOR", "POINT")
    for value, coordinate in zip(attr.data, coordinates):
        value.vector = coordinate
    obj["sheet_length"] = 256 if droop else 251
    obj["desk_front_y"] = 216


def desk_runway_droop():
    desk_runway(droop=True)


def desk_runway_straight():
    desk_runway(droop=False)


def desk_runway_uv(obj):
    """Stable sheet coordinates plus enlarged cut-edge strips for visible flutes.

    The shared pad/runway uses the same UVs on both variants. Each variant has
    its own bake, because its overhang casts different contact shadows.
    """
    uv = obj.data.uv_layers.active.data
    coordinates = obj.data.attributes["sheet_coordinates"].data
    for face in obj.data.polygons:
        values = [coordinates[i].vector for i in face.vertices]
        end = max(p.y for p in values) - min(p.y for p in values) < 1e-6
        front = sum(p.y for p in values) / len(values) > .5
        right = sum(p.x for p in values) / len(values) > .5
        for loop in face.loop_indices:
            point = coordinates[obj.data.loops[loop].vertex_index].vector
            if face.material_index == 0:
                value = (.02 + .59 * point.x, .02 + .76 * point.y)
            elif face.material_index == 1:
                value = (.64 + .29 * point.x, .02 + .76 * point.y)
            else:
                band = (.955 if front else .91) if end else (.865 if right else .82)
                value = (.02 + .91 * (point.x if end else point.y), band + .02 * point.z)
            uv[loop].uv = value


def desk_piece_checks(obj, name):
    lo, hi, size = bounds(obj)
    points = [v.co for v in obj.data.vertices]
    if name in ("landing-ring", "speed-bolt", "runway-light", "runway-light-tip"):
        assert (size - Vector(SPECS[name][1])).length < .01, ("Wrong desk piece size", name, list(size))
    if name in ("landing-ring", "speed-bolt"):
        assert ((lo + hi) / 2).length < .01, "Spinning toy must be centred on its origin"
    if name == "landing-ring":
        components = classroom_components(obj)
        assert len(components) == 14, "Landing ring needs fourteen paper loops"
        opening_radius = min(math.hypot(p.x, p.z) for p in points)
        for edge in obj.data.edges:
            a, b = [Vector((points[i].x, points[i].z)) for i in edge.vertices]
            delta = b - a
            t = min(1, max(0, -a.dot(delta) / max(delta.length_squared, 1e-12)))
            opening_radius = min(opening_radius, (a + delta * t).length)
        opening = 2 * opening_radius
        assert opening >= 58, ("Landing opening too small", opening)
        clear = 0
        for x in np.linspace(-29, 29, 25):
            for z in np.linspace(-29, 29, 25):
                if x * x + z * z < 29 ** 2:
                    assert not obj.ray_cast(Vector((x, -10, z)), Vector((0, 1, 0)), distance=20)[0], "Blocked hoop opening"
                    clear += 1
        from mathutils.bvhtree import BVHTree
        owner = {tuple(p): i for i, part in enumerate(components) for p in part}
        polygons = [[] for _ in components]
        for face in obj.data.polygons:
            polygons[owner[tuple(obj.data.vertices[face.vertices[0]].co)]].append(tuple(face.vertices))
        trees = [BVHTree.FromPolygons(points, faces) for faces in polygons]
        assert all(not trees[i].overlap(trees[j]) for i in range(14) for j in range(i + 1, 14)), "Paper links intersect"
        # Verify topology from each loop's centre curve, including the closing pair.
        # The frames can be reconstructed from the surviving mesh without FBX custom data.
        local, _ = landing_link_geometry()
        frames, cloud = [], []
        for i in range(14):
            angle = i * math.tau / 14
            radial = Vector((math.cos(angle), 0, math.sin(angle)))
            tangent = Vector((-math.sin(angle), 0, math.cos(angle)))
            across = (radial + Vector((0, 1 if i % 2 == 0 else -1, 0))).normalized()
            normal = tangent.cross(across)
            center = radial * 33.7
            frames.append((center, tangent, across, normal))
            cloud += [tuple(center + tangent * p.x + across * p.y + normal * p.z) for p in local]
        cloud = np.array(cloud)
        scale = Vector((74 / np.ptp(cloud[:, 0]), 8 / np.ptp(cloud[:, 1]), 74 / np.ptp(cloud[:, 2])))
        offset = Vector((cloud[:, 0].min() + cloud[:, 0].max(), cloud[:, 1].min() + cloud[:, 1].max(),
                         cloud[:, 2].min() + cloud[:, 2].max())) / 2
        unscaled_parts = [[Vector([p[i] / scale[i] for i in range(3)]) + offset for p in part]
                          for part in components]
        for first, second in zip(frames, frames[1:] + frames[:1]):
            center, tangent, across, normal = first
            other, ot, oa, _ = second
            part = min(unscaled_parts, key=lambda part: (sum(part, Vector()) / len(part) - center).length)
            assert len(part) == 100, "Missing loop's real doubled glue seam"
            basis = Matrix((tangent, across, normal))
            measured = sorted(tuple(round(value, 3) for value in basis @ (p - center)) for p in part)
            reference = sorted(tuple(round(value, 3) for value in p) for p in local)
            assert np.max(np.abs(np.array(measured) - reference)) < .003, "Paper loop or glue overlap changed shape"
            curve = [other + ot * (9.6 * math.cos(j * math.tau / 24)) + oa * (3.4 * math.sin(j * math.tau / 24))
                     for j in range(24)]
            piercings = 0
            for p, q in zip(curve, curve[1:] + curve[:1]):
                dp, dq = (p - center).dot(normal), (q - center).dot(normal)
                if dp * dq < 0:
                    hit = p + (q - p) * dp / (dp - dq) - center
                    if (hit.dot(tangent) / 9.6) ** 2 + (hit.dot(across) / 3.4) ** 2 < 1:
                        piercings += 1
            assert piercings == 1, "Adjacent landing links are not really interlocked"
        return {"origin": "ring centre", "paper_links": 14, "glued_overlap_seams": 14,
                "threaded_neighbor_pairs": 14, "interpenetrating_pairs": 0,
                "minimum_opening_diameter": round(opening, 3), "opening_rays_clear": clear,
                "colours": ["red", "blue", "yellow", "green"]}
    if name == "speed-bolt":
        assert len(classroom_components(obj)) == 1, "Bolt must be one closed folded paper sheet"
        assert len({round(p.y, 2) for p in points}) > 4, "Bolt has no real folds"
        return {"origin": "bolt centre", "doubled_paper_thickness": .12, "real_fold_geometry": True}
    if name in ("runway-light", "runway-light-tip"):
        assert abs(lo.z - (3.1 if name.endswith("-tip") else 0)) < .01, "Light parts lost their shared base origin"
        assert abs(lo.x + hi.x) < .01 and abs(lo.y + hi.y) < .01, "Light part off centre"
        return {"origin": "shared light base centre", "assembly_size_xyz": [3, 3, 4],
                "tip_z_range": [3.1, 4], "separate_tip_mesh": "runway-light-tip"}
    assert abs(lo.y) < .01 and abs(size.x - 100) < .01, "Runway back edge or pad width is wrong"
    back = [p for p in points if abs(p.y) < .001]
    assert abs(max(p.z for p in back)) < .001 and abs(min(p.z for p in back) + 1.2) < .001, "Wrong desk-height origin"
    assert len(classroom_components(obj)) == 1, "Pad and runway must be one continuous sheet"
    flat = [p for p in points if 90 < p.y < 215]
    assert max(abs(p.x) for p in flat) <= 44.01, "Runway must be 88 wide"
    assert all(-1.6 < p.z < .3 for p in flat), "Runway on desk is too warped"
    if name.endswith("droop"):
        assert lo.z < -35 and 223 < hi.y < 226, "Cardboard must hang limply below the desk edge"
        hanging = [p for p in points if p.z < -15]
        assert max(p.y for p in hanging) - min(p.y for p in hanging) < 4, "Overhang is a rigid ramp rather than a limp sheet"
    else:
        assert abs(hi.y - 251) < .01 and lo.z > -1.6, "Straight runway needs a flat 35-stud extension"
    return {"origin": "back edge centre at desk-top height", "pad_xy": [100, 86],
            "runway_xy": [88, 130], "desk_front_y": 216, "cardboard_thickness": 1.2,
            "overhang_sheet_length": 40 if name.endswith("droop") else 35,
            "continuous_cardboard_sheet": True, "drawn_markings_are_texture": True,
            "texture_set": "separate bake for this variant", "minimum_z": round(lo.z, 3)}


def connected_city_views(obj, name, folder, camera, center, scale, frame):
    """Extra inspection views of the actual exported mesh and its baked maps."""
    views = {"ruler-section": [("underside.png", (.15, -1, -.9), center)],
             "ruler-tape": [("opening.png", (-1, 0, 0), Vector((0, 0, 4)))],
             "ceiling-ring": [("opening.png", (0, -1, 0), Vector((0, 0, 40)))],
             "cardboard-tube": [("opening.png", (0, -1, 0), Vector((0, 0, 35)))],
             "paper-chain": [("side.png", (0, -1, 0), center)]}[name]
    primary = (folder / "render.png").read_bytes()
    position, rotation, ortho_scale = camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale
    floor = bpy.data.objects.get("Temporary studio backdrop")
    try:
        for filename, direction, target in views:
            if floor:
                floor.hide_render = name == "ruler-section"
            camera.location = target + Vector(direction).normalized() * scale * 3.5
            point_at(camera, target)
            view = camera.rotation_euler.to_matrix().transposed()
            projections = [view @ (obj.matrix_world @ v.co - target) for v in obj.data.vertices]
            width = max(v.x for v in projections) - min(v.x for v in projections)
            height = max(v.y for v in projections) - min(v.y for v in projections)
            camera.data.ortho_scale = max(width, height) / .86
            frame()
            (folder / "render.png").replace(folder / filename)
    finally:
        (folder / "render.png").write_bytes(primary)
        camera.location, camera.rotation_euler, camera.data.ortho_scale = position, rotation, ortho_scale
        if floor:
            floor.hide_render = False


def connected_city_joint_render():
    """Two exported sections butt together, with the exported tape over the join."""
    folder = OUTPUT / "ruler-section"
    bpy.ops.wm.open_mainfile(filepath=str(folder / "ruler-section.blend"))
    scene = bpy.context.scene
    section = next(obj for obj in scene.objects if obj.type == "MESH")
    section.location.x = -30
    second = section.copy()
    second.data = section.data.copy()
    scene.collection.objects.link(second)
    second.location.x = 30
    before = set(scene.objects)
    bpy.ops.import_scene.fbx(filepath=str(OUTPUT / "ruler-tape/ruler-tape.fbx"), use_custom_normals=True)
    tape = next(obj for obj in scene.objects if obj not in before and obj.type == "MESH")
    active(tape)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tape.location.z = -1
    # FBX imports its linked color map; retain the tape's subtle transparency.
    tape.data.materials[0].node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value = .94
    camera, target = scene.camera, Vector((0, 0, 3))
    camera.data.ortho_scale = 136
    for light in [obj for obj in scene.objects if obj.type == "LIGHT"]:
        light.location = target + (light.location - target) * 2
        light.data.energy *= 4
    bpy.ops.mesh.primitive_plane_add(size=1000, location=(0, 0, -1.02))
    floor = bpy.context.object
    mat = bpy.data.materials.new("Joined ruler cream backdrop")
    mat.use_nodes = True
    mat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = linear((246, 241, 228))
    floor.data.materials.append(mat)
    floor.is_shadow_catcher = True
    for filename, direction in (("joint.png", (.18, -1, .95)),
                                 ("joint-underside.png", (.18, -1, -.95))):
        floor.hide_render = direction[2] < 0
        camera.location = target + Vector(direction).normalized() * 420
        point_at(camera, target)
        scene.render.filepath = str(folder / filename)
        bpy.ops.render.render(write_still=True)
        rgba = png_read(folder / filename, alpha=True).astype(np.float32)
        opacity = rgba[:, :, 3:4] / 255
        pixels = np.clip(rgba[:, :, :3] * opacity + np.array([246, 241, 228]) * (1 - opacity), 0, 255)
        png_write(folder / filename, pixels.astype(np.uint8))


def connected_city_checks(obj, name):
    lo, hi, size = bounds(obj)
    assert (size - Vector(SPECS[name][1])).length < .01, ("Wrong connected-city size", name, list(size))
    report = {"exact_size": True}
    if name == "ruler-section":
        ends = [face for face in obj.data.polygons if abs(face.normal.x) > .999]
        assert ends and all(all(abs(abs(obj.data.vertices[i].co.x) - 30) < .01
                               for i in face.vertices) for face in ends), "Joining ends must stay flat"
        report.update(tick_period_studs=10, ticks_on_top_and_bottom=True)
    elif name == "ruler-tape":
        assert all(abs(mat.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value - .94) < 1e-5
                   for mat in obj.data.materials), "Tape lost its slight transparency"
        for y in (-14.99, 0, 14.99):
            for z in (1.01, 4, 6.99):
                assert not obj.ray_cast(Vector((-6, y, z)), Vector((1, 0, 0)), distance=12)[0], \
                    "Ruler tape sleeve cavity is blocked"
        assert abs(obj.ray_cast(Vector((0, 0, 4)), Vector((0, 1, 0)), distance=20)[1].y - 15) < .01
        assert abs(obj.ray_cast(Vector((0, 0, 4)), Vector((0, 0, 1)), distance=5)[1].z - 7) < .01
        report.update(sleeve_inside_yz=[30, 6], tape_wall_studs=1, sleeve_rays_clear=9,
                      tape_alpha=.94, deck_offset_z=1)
    elif name in ("ceiling-ring", "cardboard-tube"):
        radius, height = (30, 40) if name == "ceiling-ring" else (31, 35)
        clear = 0
        for x in np.linspace(-radius + .2, radius - .2, 15):
            for z in np.linspace(-radius + .2, radius - .2, 15):
                if x * x + z * z <= (radius - .2) ** 2:
                    for sign in (-1, 1):
                        assert not obj.ray_cast(Vector((x, sign * 110, height + z)),
                                                Vector((0, -sign, 0)), distance=220)[0], "Flight hole is blocked"
                        clear += 1
        components = classroom_components(obj)
        loops = [part for part in components if max(p.x for p in part) - min(p.x for p in part) < 7]
        assert len(loops) == (1 if name == "ceiling-ring" else 2), "Missing hanger loop"
        assert all(abs(min(p.z for p in part) - (80 if name == "ceiling-ring" else 70)) < .01 and
                   abs(max(p.z for p in part) - (86 if name == "ceiling-ring" else 76)) < .01
                   for part in loops), "Wrong hanger loop height"
        report.update(open_hole_diameter=radius * 2, opening_rays_clear=clear, hanger_loops=len(loops))
        if name == "cardboard-tube":
            inner = obj.ray_cast(Vector((0, 0, 35)), Vector((1, 0, 0)), distance=40)[1].x
            outer = obj.ray_cast(Vector((40, 0, 35)), Vector((-1, 0, 0)), distance=10)[1].x
            assert abs(inner - 31) < .01 and abs(outer - inner - 4) < .01, "Wrong tube wall"
            ys = sorted(round(sum(p.y for p in part) / len(part), 3) for part in loops)
            assert ys == [-70, 70], ("Wrong tube hanger positions", ys)
            report.update(tube_wall_studs=4, hanger_y=ys)
    else:
        parts = classroom_components(obj)
        assert len(parts) == 43, "Paper chain must have forty-three identical closed paper loops"
        frames = json.loads(obj["paper_chain_frames"])
        local = np.array([tuple(p) for p in paper_chain_strip_geometry()[0]])
        reference = sorted(tuple(round(value, 3) for value in p) for p in local)
        ordered = []
        for center, tangent, across, normal in frames:
            center = Vector(center)
            part = min(parts, key=lambda points: (sum(points, Vector()) / len(points) - center).length)
            basis = Matrix((tangent, across, normal))
            measured = sorted(tuple(round(value, 3) for value in basis @ (p - center)) for p in part)
            assert len(measured) == len(reference) and np.max(np.abs(np.array(measured) - reference)) < .003, \
                "A loop lost its identical 14 x 9 shape, 4-wide strip, .5 wall or glued overlap"
            ordered.append(part)
        assert len({id(part) for part in ordered}) == 43, "Loop frames do not match the actual mesh"
        from mathutils.bvhtree import BVHTree
        part_for_point = {tuple(p): index for index, part in enumerate(parts) for p in part}
        polygons = [[] for _ in parts]
        for face in obj.data.polygons:
            polygons[part_for_point[tuple(obj.data.vertices[face.vertices[0]].co)]].append(tuple(face.vertices))
        trees = [BVHTree.FromPolygons([v.co for v in obj.data.vertices], faces) for faces in polygons]
        assert all(not trees[i].overlap(trees[j]) for i in range(43) for j in range(i + 1, 43)), \
            "Paper chain links interpenetrate"
        # A neighboring loop must pierce the first loop's interior disk once.
        # Zero piercings would be separate rings merely overlapping in a photo.
        angle_errors = []
        for first, second in zip(frames, frames[1:]):
            center, tangent, across, normal = map(Vector, first)
            other, ot, oa, on = map(Vector, second)
            curve = [other + ot * (6.75 * math.cos(j * math.tau / 16)) +
                     oa * (4.25 * math.sin(j * math.tau / 16)) for j in range(16)]
            piercings = 0
            for p, q in zip(curve, curve[1:] + curve[:1]):
                dp, dq = (p - center).dot(normal), (q - center).dot(normal)
                if dp * dq < 0:
                    hit = p + (q - p) * dp / (dp - dq) - center
                    if (hit.dot(tangent) / 6.75) ** 2 + (hit.dot(across) / 4.25) ** 2 < 1:
                        piercings += 1
            assert piercings == 1, "Adjacent paper loops are not threaded through each other"
            error = math.degrees(math.asin(min(1, abs(normal.dot(on)))))
            assert error < 1, "Adjacent loop planes must remain at right angles along the sag"
            angle_errors.append(error)
        for part in (ordered[0], ordered[-1]):
            assert abs(max(p.z for p in part) - 176) < .01 and min(p.z for p in part) > 160, \
                "Both end loops must stay at the top"
        middle = ordered[21]
        assert abs(min(p.z for p in middle)) < .01, "The middle loop must stay at the bottom"
        report.update(paper_loops=43,
                      end_loop_z=[round(min(p.z for p in ordered[0]), 3), 176],
                      lowest_loop_z=[0, round(max(p.z for p in middle), 3)], catenary=True,
                      loop_outer_length=14, loop_outer_across=9, identical_loop_shapes=True,
                      paper_strip_width=4, paper_wall_thickness=.5, glued_overlaps=43,
                      overlap_total_thickness=1, threaded_neighbor_pairs=42,
                      max_right_angle_error_degrees=round(max(angle_errors), 3),
                      interpenetrating_loop_pairs=0)
    return report


def backpack_cubby_checks(obj):
    """Measure the cabinet, contents and open fronts again on the exported mesh."""
    lo, hi, _ = bounds(obj)
    assert (lo - Vector((-350, -30, 0))).length < .01, "Backpack cubby escaped its lower bounds"
    assert (hi - Vector((350, 30, 140))).length < .01, "Backpack cubby escaped its upper bounds"
    components = []
    for part in classroom_components(obj):
        low = Vector([min(p[i] for p in part) for i in range(3)])
        high = Vector([max(p[i] for p in part) for i in range(3)])
        components.append((low, high, high - low))
    def matching(size):
        return [(low, high) for low, high, dimensions in components
                if (dimensions - Vector(size)).length < .01]
    assert len(matching((700, 60, 8))) == 2, "Need the full-width top and bottom"
    assert len(matching((676, 53, 8))) == 1, "Need the middle shelf"
    dividers = matching((8, 55, 58))
    assert len(dividers) == 12, "Need six dividers in each of two rows"
    assert sorted(round(low.z, 3) for low, _ in dividers) == [8] * 6 + [74] * 6, "Wrong compartment rows"
    labels = matching((42, 1.4, 5))
    assert len(labels) == 7 and all(abs(low.z - 67.5) < .01 for low, _ in labels), \
        "Each upper compartment needs a blank label below it"
    backpacks = [(low, high) for low, high, size in components
                 if 53.9 <= size.x <= 58.1 and abs(size.y - 30) < .01 and 45.9 <= size.z <= 49.1]
    assert len(backpacks) == 9, "Most compartments must hold real backpacks"
    assert len(matching((58, 32, 25))) == 2, "Need two lunchboxes"
    assert len(matching((60, 26, 26))) == 1, "Need one rolled jacket"
    centres = [(index - 3) * (684 / 7) for index in range(7)]
    empty = {(1, 3), (0, 5)}
    for row in range(2):
        base = 9 + row * 66
        for column, x in enumerate(centres):
            hit, point, _, _ = obj.ray_cast(Vector((x + 39, -40, base + 35)),
                                           Vector((0, 1, 0)), distance=80)
            assert hit and abs(point.y - 25) < .01, "Every compartment must open to the real back panel"
            hit, point, _, _ = obj.ray_cast(Vector((x, -40, base + 12)),
                                           Vector((0, 1, 0)), distance=80)
            assert hit, "Missing compartment back"
            if (row, column) in empty:
                assert abs(point.y - 25) < .01, "The two empty compartments must really be empty"
            else:
                assert point.y < 20, "Missing backpack, lunchbox or jacket"
    for x in centres:
        hit, point, _, _ = obj.ray_cast(Vector((x, 0, 150)), Vector((0, 0, -1)), distance=20)
        assert hit and abs(point.z - 140) < .01, "Top surface must be continuous and flat"
    for index in range(6):
        for z in (37, 103):
            hit, point, _, _ = obj.ray_cast(Vector(((index - 2.5) * (684 / 7), -40, z)),
                                           Vector((0, 1, 0)), distance=80)
            assert hit and abs(point.y + 30) < .01, "Missing open-compartment divider"
    return {"cubby_columns": 7, "cubby_rows": 2, "backpacks": len(backpacks), "lunchboxes": 2,
            "rolled_jackets": 1, "empty_compartments": len(empty), "blank_name_labels": len(labels),
            "clear_open_front_rays": 14, "top_surface_z": 140,
            "bounds_min_xyz": [round(value, 3) for value in lo],
            "bounds_max_xyz": [round(value, 3) for value in hi]}


def classroom_fixture_checks(obj, name):
    """Dimensions and useful openings measured again on the imported FBX."""
    lo, hi, size = bounds(obj)
    assert (size - Vector(SPECS[name][1])).length < .01, ("Wrong fixture size", name, list(size))
    report = {"front": "-Y", "base_origin": [0, 0, 0]}
    if name == "backpack-cubby":
        report.update(backpack_cubby_checks(obj))
    if name == "classroom-door":
        for x, z in ((0, 80), (-31, 261), (40, 345)):
            hit, point, _, _ = obj.ray_cast(Vector((x, 30, z)), Vector((0, -1, 0)), distance=40)
            assert hit and abs(point.y - 10) < .01, "Door back must be flat and flush"
        report["flat_back_y"] = 10
    if name == "floor-fan":
        components = classroom_components(obj)
        assert abs(hi.z - 36) < .01 and len(components) >= 30, "Missing fan grille or blades"
        radius = max(math.hypot(p.x, p.y) for part in components for p in part)
        assert abs(radius - 78) < .01, "Every fan part must fit the 78-stud circular footprint"
        moving = [part for part in components if min(p.z for p in part) >= 18 and max(p.z for p in part) <= 28]
        assert len(moving) == 6, "Split band must contain exactly five blades and the centre cap"
        blade_radius = max(math.hypot(p.x, p.y) for part in moving for p in part)
        assert 5.9 <= 64 - blade_radius <= 7, "Blade tips need about six studs of rim clearance"
        motor = [part for part in components if 7.9 <= min(p.z for p in part) <= 8.1
                 and 16.79 <= max(p.z for p in part) <= 16.81]
        assert len(motor) == 1, "Motor must stay below the rotor split band"
        grille = [part for part in components if min(p.z for p in part) > 33]
        assert len(grille) == 23, "All grille rings, straight wires and attachments must be above Z=33"
        report["footprint_radius"] = round(radius, 3)
        report["rotor_loose_parts"] = len(moving)
        report["rotor_z_band"] = [18, 28]
        report["blade_rim_clearance"] = round(64 - blade_radius, 3)
        report["motor_top_z"] = round(max(p.z for p in motor[0]), 3)
        report["grille_top_z"] = round(hi.z, 3)
        report["blows_toward"] = "+Z"
    if name == "desk-hangar":
        for x, z in ((0, 20), (-24, 18), (24, 18)):
            hit, point, _, _ = obj.ray_cast(Vector((x, -40, z)), Vector((0, 1, 0)), distance=80)
            assert hit and 33 <= point.y <= 35, "Hangar entrance must stay open to its rear wall"
        report["clear_entrance_rays"] = 3
    if name == "cubby-shelf":
        for x in (-193, 0, 193):
            for z in (80, 218):
                assert obj.ray_cast(Vector((x, -70, z)), Vector((0, 1, 0)), distance=135)[0], "Missing cubby contents/back"
        report["cubby_columns"] = 3
        report["cubby_rows"] = 2
    if name == "bulletin-board":
        hit, point, _, _ = obj.ray_cast(Vector((0, -20, 130)), Vector((0, 1, 0)), distance=30)
        assert hit and abs(point.y + 3) < .01, "Cork face must be recessed inside frame"
        report["cork_face_y"] = round(point.y, 3)
    if name == "classroom-bookshelf":
        assert (lo - Vector((-150, -42.5, 0))).length < .01, "Bookshelf contents escaped the cabinet"
        assert (hi - Vector((150, 42.5, 260))).length < .01, "Bookshelf contents escaped the cabinet"
        shelves = []
        flat_books = []
        for component in classroom_components(obj):
            low = Vector([min(p[i] for p in component) for i in range(3)])
            high = Vector([max(p[i] for p in component) for i in range(3)])
            dimensions = high - low
            if (dimensions - Vector((276, 80, 6))).length < .01:
                shelves.append(round(high.z, 3))
            if 42 <= dimensions.x <= 49 and 35 <= dimensions.y <= 39 and abs(dimensions.z - 5) < .01:
                flat_books.append(round(low.z, 3))
        assert sorted(shelves) == [16, 64, 112, 160, 208], "Need all five raised shelves"
        assert sorted(flat_books) == sorted(base + offset for base in shelves for offset in (0, 5)), \
            "Each shelf needs its own stack of two flat books"
        for base in shelves:
            hit, point, _, _ = obj.ray_cast(Vector((137, -60, base + 24)), Vector((0, 1, 0)), distance=110)
            assert hit and abs(point.y - 37.5) < .01, "Open shelf front must lead to the real back panel"
        report.update({"shelf_top_z": sorted(shelves), "bottom_shelf_clearance": 10,
                       "flat_book_stacks": len(flat_books) // 2, "clear_open_front_rays": len(shelves)})
    if name == "ceiling-light":
        for x, y in ((0, 0), (-70, -15), (70, 15), (-74, 0), (0, 19)):
            hit, point, _, _ = obj.ray_cast(Vector((x, y, 12)), Vector((0, 0, -1)), distance=6)
            assert hit and abs(point.z - 8) < .01, "Ceiling light top must be flush and flat"
        hit, point, _, _ = obj.ray_cast(Vector((1, 1, -2)), Vector((0, 0, 1)), distance=6)
        assert hit and abs(point.z - 2.3) < .01, "Milky diffuser must be recessed inside the frame"
        face = obj.ray_cast(Vector((1, 1, -2)), Vector((0, 0, 1)), distance=6)[3]
        slot = obj.data.materials[obj.data.polygons[face].material_index].name
        assert slot in ("Glow", "Ceiling light frosted diffuser source"), "Diffuser lost its own material slot"
        for x in (-68, 0, 68):
            hit, point, _, _ = obj.ray_cast(Vector((x, 1, -2)), Vector((0, 0, 1)), distance=6)
            assert hit and abs(point.z - 2) < .01, "Louvre grid must be inset two studs"
        report.update({"flat_top_z": 8, "frame_width": 3, "diffuser_bottom_z": 2.3,
                       "louvre_inset": 2, "grid_spacing": 4, "glow_slot": "Glow"})
    return report


BUILDERS = {"tree-lollipop": lollipop, "tree-bushy": bushy, "tree-pine": pine,
            "bench": bench, "flagpole": flagpole, "car-hatchback": car,
            "pencil-flagpole": pencil_flagpole,
            "car-sedan": lambda: car("sedan"), "car-taxi": lambda: car("taxi"),
            "car-van": van, "fire-truck": fire_truck, "crane": crane,
            "monorail-pylon": monorail_pylon, "monorail-beam": monorail_beam,
            "monorail-car": lambda: monorail_car(True), "monorail-car-middle": lambda: monorail_car(False), "bus": bus, "bus-stop": bus_stop, "tugboat": tugboat,
            "cone": cone, "barrier": barrier, "paper-boat": paper_boat,
            "rowing-boat": rowing_boat, "dump-truck": dump_truck, "digger": digger, "fountain": fountain, "crop-row": crop_row,
            "site-building": site_building, "site-fence": site_fence, "cement-mixer": cement_mixer,
            "sand-pile": lambda: material_pile("sand"), "gravel-pile": lambda: material_pile("gravel"),
            "plank-stack": plank_stack, "pipe-stack": pipe_stack, "brick-stack": brick_stack,
            "site-cabin": site_cabin, "site-toilet": site_toilet, "street-lamp": street_lamp,
            "stall": stall, "house": house, "playground": playground,
            "picnic": picnic, "goal": goal, "pool": pool, "hay-bale": hay_bale,
            "footbridge": footbridge, "boathouse": boathouse, "barn": barn,
            "petrol-station": petrol_station, "fire-station": fire_station,
            "plane": plane, "hangar": hangar, "terminal": terminal, "ruler-bridge": ruler_bridge,
            "school-desk": school_desk, "school-chair": school_chair,
            "paper-bunting": paper_bunting, "saturn": saturn,
            "jungle-gym": jungle_gym, "swing-set": swing_set, "slide": slide,
            "basketball-hoop": basketball_hoop, "fence-panel": fence_panel,
            "seesaw": seesaw, "merry-go-round": merry_go_round,
            "spring-rider": spring_rider, "monkey-bars": monkey_bars,
            "tire-swing": tire_swing, "crawl-tunnel": crawl_tunnel}
BUILDERS.update({"classroom-door": classroom_door, "floor-fan": floor_fan,
                 "desk-hangar": desk_hangar, "cubby-shelf": cubby_shelf,
                 "backpack-cubby": backpack_cubby,
                 "bulletin-board": bulletin_board, "classroom-bookshelf": classroom_bookshelf,
                 "ceiling-light": ceiling_light})
BUILDERS.update({"ruler-section": ruler_section, "ruler-tape": ruler_tape,
                 "ceiling-ring": ceiling_ring, "cardboard-tube": cardboard_tube,
                 "paper-chain": paper_chain})
BUILDERS.update({"landing-ring": landing_ring, "speed-bolt": speed_bolt,
                 "runway-light": runway_light, "runway-light-tip": runway_light_tip,
                 "desk-runway-droop": desk_runway_droop, "desk-runway-straight": desk_runway_straight})
BUILDERS["chalk-eraser"] = chalk_eraser


def bounds(obj):
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    return lo, hi, hi - lo


def assemble(name):
    bpy.ops.object.select_all(action="DESELECT")
    for index, obj in enumerate(PARTS):
        for value in obj.data.attributes["toy_piece"].data:
            value.value = index
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    transform = obj.matrix_world.copy()
    for v in obj.data.vertices:
        v.co = transform @ v.co
    obj.matrix_world.identity()
    lo, hi, dimensions = bounds(obj)
    expected = SPECS[name][1]
    # Preserve concept proportions. Only the largest footprint controls uniform
    # game size, and the old height is deliberately not a normalization target.
    footprint = max(value for value in expected[:2] if value) if any(expected[:2]) else None
    factor = footprint / max(dimensions[:2]) if footprint else 1
    factors = [factor] * 3
    ground = [v.co for v in obj.data.vertices if v.co.z <= lo.z + .005]
    center = Vector([(min(v[i] for v in ground) + max(v[i] for v in ground)) / 2
                     for i in range(2)] + [0])
    if name in CLASSROOM_TOYS:
        # These builders already use gameplay studs. In particular, bunting
        # hangs below its two Z=0 attachment points; never ground or rescale it.
        factors = [1, 1, 1]
        center = Vector((0, 0, 0))
    base_z = 0 if name in CLASSROOM_TOYS else lo.z
    for mat in obj.data.materials:
        if mat.node_tree.nodes.get("Decal scale"):
            mat.node_tree.nodes["Decal scale"].inputs[1].default_value = tuple(1 / f for f in factors)
            mat.node_tree.nodes["Decal origin"].inputs[1].default_value = (center.x, center.y, lo.z)
    for v in obj.data.vertices:
        v.co = Vector([(v.co[i] - center[i] - (base_z if i == 2 else 0)) * factors[i]
                       for i in range(3)])
    # Store procedural assignments in the source even after the export gets its
    # single baked material. Baking can be resumed by restoring these slots.
    regions = obj.data.attributes.new("procedural_region", "INT", "FACE")
    for face in obj.data.polygons:
        regions.data[face.index].value = face.material_index
    obj["procedural_materials"] = [mat.name for mat in obj.data.materials]
    active(obj)
    if name == "ruler-bridge":
        ruler_bridge_uv(obj)
    elif name == "chalk-eraser":
        chalk_eraser_uv(obj)
    elif name.startswith("desk-runway"):
        desk_runway_uv(obj)
    else:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.average_islands_scale()
        bpy.ops.uv.pack_islands(rotate=True, margin_method="FRACTION", margin=PADDING,
                               shape_method="CONVEX", scale=True)
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.data.uv_layers.active.name = "ToyUV"
    mod = obj.modifiers.new("Export triangles", "TRIANGULATE")
    mod.keep_custom_normals = True
    apply(obj, mod)
    return obj


def geometry_checks(obj, name, baked=False):
    _, expected = SPECS[name]
    cap = triangle_cap(name)
    assert len(obj.data.polygons) <= cap, (name, "Triangle cap", len(obj.data.polygons), cap)
    assert all(len(face.vertices) == 3 for face in obj.data.polygons), "Untriangulated face"
    assert len(obj.data.uv_layers) == 1, "Exactly one UV map required"
    assert not obj.modifiers, "Unapplied modifier"
    assert obj.location.length < 1e-5, "Origin must be at ground/base center"
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(vertex.link_faces for vertex in bm.verts), "Loose vertex"
    assert all(edge.is_manifold for edge in bm.edges), "Non-manifold edge"
    assert all(face.calc_area() > 1e-9 for face in bm.faces), "Degenerate face"
    # Each closed component must have outward winding, including the thin flag.
    remaining = set(bm.faces)
    while remaining:
        seed = remaining.pop()
        component, pending = {seed}, [seed]
        while pending:
            face = pending.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        component.add(neighbor)
                        pending.append(neighbor)
        volume = sum(face.verts[0].co.dot(face.verts[1].co.cross(face.verts[2].co)) / 6
                     for face in component)
        assert volume > 1e-7, ("Inward normals or flat component", volume)
    bm.free()
    lo, hi, size = bounds(obj)
    if name not in SPECIAL_ORIGIN_TOYS:
        assert abs(lo.z) <= .01, ("Not grounded", lo.z)
    ground = [v.co for v in obj.data.vertices if v.co.z <= lo.z + .005]
    base_center = [(min(v[i] for v in ground) + max(v[i] for v in ground)) / 2 for i in range(2)]
    if name not in SPECIAL_ORIGIN_TOYS:
        assert max(abs(value) for value in base_center) < .01, ("Origin is not at base center", base_center)
    if any(expected[:2]):
        target = max(value for value in expected[:2] if value)
        assert abs(max(size[:2]) / target - 1) <= .25, ("Wrong footprint", list(size), target)
    if name in ("crop-row", "ruler-bridge"):
        assert all(abs(size[i] - expected[i]) < .01 for i in range(3)), ("Wrong exact size", name, list(size))
    pennant_density = []
    if name == "pencil-flagpole":
        assert abs(size.z - expected[2]) < .01, ("Wrong pencil pole height", size.z, expected[2])
        # The star must stay sharp on both paper faces at the normal 1024 bake.
        paper_faces = [face for face in obj.data.polygons if abs(face.normal.y) > .7 and
                       min(obj.data.vertices[i].co.x for i in face.vertices) > 3.35 and
                       min(obj.data.vertices[i].co.z for i in face.vertices) >= 29 - .01]
        assert paper_faces, "Missing broad pennant faces"
        for face in paper_faces:
            a, b, c = [obj.data.vertices[i].co for i in face.vertices]
            ab, ac = b - a, c - a
            basis = np.array([[ab.length, ac.dot(ab.normalized())],
                              [0, ac.cross(ab.normalized()).length]])
            ua, ub, uc = [obj.data.uv_layers.active.data[i].uv for i in face.loop_indices]
            texture = np.array([(ub - ua)[:], (uc - ua)[:]]).T * RESOLUTION
            density = np.linalg.svd(texture @ np.linalg.inv(basis), compute_uv=False)[-1]
            assert density >= 3, ("Pennant texture density below 3px/stud", density)
            pennant_density.append(float(density))
    if name == "ruler-bridge":
        assert all(abs(v.co.x) >= 128 - .01 for v in obj.data.vertices if v.co.z < 145 - .01), \
            "Ruler bridge flight opening must stay clear"
        deck_top = [face for face in obj.data.polygons if face.normal.z > .999 and
                    all(abs(obj.data.vertices[i].co.z - 155) < .01 for i in face.vertices)]
        assert deck_top, "Missing flat ruler top at Z=155"
        top_loops = [index for face in deck_top for index in face.loop_indices]
        top_uv = [obj.data.uv_layers.active.data[i].uv for i in top_loops]
        top_width = max(p.x for p in top_uv) - min(p.x for p in top_uv)
        assert top_width * RESOLUTION / 300 >= 3, "Ruler tick texture density below 3px/stud"
        long_sides = [face for face in obj.data.polygons if abs(face.normal.y) > .999 and
                      all(abs(abs(obj.data.vertices[i].co.y) - 20) < .01 and
                          145 <= obj.data.vertices[i].co.z <= 155 for i in face.vertices)]
        marked_area = 0
        for face in deck_top + long_sides:
            a, b, c = [obj.data.uv_layers.active.data[i].uv for i in face.loop_indices]
            ab, ac = b - a, c - a
            marked_area += abs(ab.x * ac.y - ab.y * ac.x) / 2
        assert marked_area > .5, "Deck top and sides need most of the atlas"
    if baked:
        expected_slots = 2 if name == "ceiling-light" else 1
        assert len(obj.data.materials) == expected_slots, ("Wrong baked material count", name, expected_slots)
        if name == "ceiling-light":
            glow = [index for index, mat in enumerate(obj.data.materials) if mat.name == "Glow"]
            assert len(glow) == 1, "Need one exported Glow slot"
            glow_faces = [face for face in obj.data.polygons if face.material_index == glow[0]]
            assert len(glow_faces) == 12, "Only the closed diffuser belongs to Glow"
            glow_points = [obj.data.vertices[i].co for face in glow_faces for i in face.vertices]
            assert abs(min(p.z for p in glow_points) - 2.3) < .01 and \
                abs(max(p.z for p in glow_points) - 3.3) < .01, "Glow contains frame or louvre geometry"
        assert sum(o.type == "MESH" for o in bpy.context.scene.objects) == 1, "Exactly one mesh required"
    report = {"toy": name, "triangles": len(obj.data.polygons),
              "size_xyz": [round(value, 3) for value in size], "lowest_z": round(lo.z, 5)}
    if pennant_density:
        report["pennant_min_px_per_stud"] = round(min(pennant_density), 2)
    if name in CLASSROOM_TOYS:
        report.update(classroom_toy_checks(obj, name))
    return report


def classroom_components(obj):
    """Return each disconnected closed part's actual vertex coordinates."""
    points = [v.co for v in obj.data.vertices]
    neighbors = {v.index: set() for v in obj.data.vertices}
    for edge in obj.data.edges:
        a, b = edge.vertices
        neighbors[a].add(b)
        neighbors[b].add(a)
    remaining, components = set(neighbors), []
    while remaining:
        seed = remaining.pop()
        ids, pending = {seed}, [seed]
        while pending:
            for other in neighbors[pending.pop()]:
                if other in remaining:
                    remaining.remove(other)
                    ids.add(other)
                    pending.append(other)
        components.append([points[i] for i in ids])
    return components


def schoolyard_toy_checks(obj, name):
    """Actual size, open equipment and playable surfaces, including the FBX."""
    lo, hi, size = bounds(obj)
    expected = SPECS[name][1]
    triangles = len(obj.data.polygons)
    if name == "fence-panel":
        assert (size - Vector(expected)).length < .01, "Fence repeat must be exactly 500 x 10 x 240"
        assert 700 <= triangles <= 900, "Fence should stay near 800 triangles"
        assert abs(lo.x + 250) < .01 and abs(hi.x - 250) < .01, "Fence endpoints must tile at X +/-250"
        for x in (-230, -115, 0, 115, 230):
            assert obj.ray_cast(Vector((x, -15, 120)), Vector((0, 1, 0)), distance=30)[0], \
                "Missing opaque fence panel"
        return {"tile_step_x": 500, "panel_is_opaque": True, "wire_pattern": "baked diamond pigment"}
    if name in MORE_SCHOOLYARD_TOYS:
        assert 3000 <= triangles <= triangle_cap(name), \
            ("New playground equipment must use its 3000-6000 triangle budget", name, triangles)
    else:
        assert 4000 <= triangles <= 6000, "Schoolyard equipment must use the 4000-6000 triangle budget"
    assert all(abs(size[i] / expected[i] - 1) <= .05 for i in range(3)), \
        ("Schoolyard size differs by more than five percent", name, list(size), expected)
    if name == "seesaw":
        seats = []
        for x in (-264, 264):
            hit, point, _, _ = obj.ray_cast(Vector((x, 0, 140)), Vector((0, 0, -1)), distance=40)
            assert hit and abs(point.z - 118) < .01, "Seesaw needs two level sitting surfaces"
            seats.append(round(point.z, 3))
        hit, point, _, _ = obj.ray_cast(Vector((100, 0, 140)), Vector((0, 0, -1)), distance=60)
        assert hit and abs(point.z - 109) < .01, "Missing continuous seesaw plank"
        return {"seat_top_z": seats, "plank_top_z": round(point.z, 3), "seat_handles": 2}
    if name == "merry-go-round":
        hit, point, _, _ = obj.ray_cast(Vector((90, 0, 70)), Vector((0, 0, -1)), distance=50)
        assert hit and 45 - .01 <= point.z <= 46 + .01, "Roundabout needs a solid flat platform"
        hit, hub, _, _ = obj.ray_cast(Vector((0, 0, 200)), Vector((0, 0, -1)), distance=50)
        assert hit and abs(hub.z - 180) < .01, "Missing roundabout centre post"
        return {"deck_top_z": round(point.z, 3), "hub_top_z": round(hub.z, 3),
                "coloured_deck_segments": 6, "curved_hand_rails": 3}
    if name == "spring-rider":
        hit, point, _, _ = obj.ray_cast(Vector((13, 0, 155)), Vector((0, 0, -1)), distance=30)
        assert hit and abs(point.z - 137.5) < .01, "Duck rider needs a broad flat seat"
        components = classroom_components(obj)
        coils = [part for part in components if 9 < min(p.z for p in part) < 11 and
                 82 < max(p.z for p in part) < 84 and
                 35 < max(p.x for p in part) - min(p.x for p in part) < 45]
        assert len(coils) == 1, "Missing separate thick spring coil"
        return {"seat_top_z": round(point.z, 3), "spring_turns": 5,
                "character": "green duck", "display_front": "-Y", "beak_direction": "-X"}
    if name == "monkey-bars":
        for x in (-140, 28, 140):
            assert not obj.ray_cast(Vector((x, 0, 30)), Vector((0, 0, 1)), distance=420)[0], \
                "Overhead monkey ladder must have real openings"
        for x in (-280, 280):
            for z in (60, 170, 280, 390):
                assert obj.ray_cast(Vector((x - 25, 0, z)), Vector((1, 0, 0)), distance=50)[0], \
                    "Monkey bars need both climbable end ladders"
        return {"end_ladders": 2, "rungs_per_end_ladder": 7, "overhead_rungs": 9,
                "overhead_openings_clear": True}
    if name == "tire-swing":
        assert not obj.ray_cast(Vector((0, 0, 70)), Vector((0, 0, 1)), distance=75)[0], \
            "Flat tyre must retain its central hole"
        hit, point, _, _ = obj.ray_cast(Vector((82, 0, 150)), Vector((0, 0, -1)), distance=70)
        assert hit and abs(point.z - 130) < .01, "Tyre must hang flat above the ground"
        return {"tyre_top_z": round(point.z, 3), "tyre_lowest_z": 89,
                "tyre_opening_clear": True, "chain_count": 3, "links_per_chain": 12}
    if name == "crawl-tunnel":
        for y, z in ((0, 85), (-25, 85), (25, 85), (0, 55), (0, 115)):
            assert not obj.ray_cast(Vector((-220, y, z)), Vector((1, 0, 0)), distance=440)[0], \
                "Crawl tunnel must stay open through both end rings"
        hit, point, _, _ = obj.ray_cast(Vector((0, 0, 85)), Vector((0, 1, 0)), distance=100)
        assert hit and abs(point.y - 62) < .01, "Missing solid tunnel wall"
        for x in (-125, 125):
            hit, floor, _, _ = obj.ray_cast(Vector((x, 0, 85)), Vector((0, 0, -1)), distance=85)
            assert hit and abs(floor.z - 23) < .01, "Tunnel frame must stay below the interior floor"
        return {"tunnel_direction": "X", "barrel_inside_diameter": 124,
                "entry_inside_diameter": 120, "interior_floor_z": round(floor.z, 3), "open_through_rays": 5}
    if name == "jungle-gym":
        hit, point, _, _ = obj.ray_cast(Vector((235, 60, 310)), Vector((0, 0, -1)), distance=50)
        assert hit and abs(point.z - 270) < .01, "Jungle gym needs a flat deck at Z=270"
        assert not obj.ray_cast(Vector((0, 0, 10)), Vector((0, 0, 1)), distance=500)[0], \
            "Monkey bars must keep real openings"
        return {"deck_top_z": round(point.z, 3), "rope_grid": [7, 5], "monkey_bar_opening_clear": True}
    if name == "swing-set":
        seats = []
        for x in (-140, 140):
            hit, point, _, _ = obj.ray_cast(Vector((x, 0, 160)), Vector((0, 0, -1)), distance=80)
            assert hit and abs(point.z - 112) < .01, "Swing seats must stay above the ground at Z=112"
            seats.append(round(point.z, 3))
        assert not obj.ray_cast(Vector((0, -200, 100)), Vector((0, 1, 0)), distance=400)[0], \
            "Two separate swings need open space between them"
        return {"seat_top_z": seats, "chain_count": 4, "links_per_chain": 12}
    if name == "slide":
        hit, point, _, _ = obj.ray_cast(Vector((-263, 0, 360)), Vector((0, 0, -1)), distance=40)
        assert hit and abs(point.z - 334) < .01, "Slide needs a flat entry platform"
        hit, exit_point, _, _ = obj.ray_cast(Vector((390, 0, 80)), Vector((0, 0, -1)), distance=80)
        assert hit and 15 < exit_point.z < 30, "Slide chute needs a low run-out"
        return {"platform_top_z": round(point.z, 3), "runout_top_z": round(exit_point.z, 3),
                "ladder_treads": 8, "slide_direction": "+X"}
    assert name == "basketball-hoop", ("Unknown schoolyard check", name)
    assert not obj.ray_cast(Vector((0, -35, 450)), Vector((0, 0, -1)), distance=140)[0], \
        "Basketball rim and net must have a real central opening"
    hit, point, _, _ = obj.ray_cast(Vector((0, -160, 550)), Vector((0, 1, 0)), distance=240)
    assert hit and abs(point.y - 44) < .01, "Backboard must face -Y"
    return {"rim_center": [0, -35, 432], "net_strands": 24, "rim_opening_clear": True,
            "backboard_faces": "-Y"}


def classroom_toy_checks(obj, name):
    """Measure the actual mesh after assembly and again after the FBX import."""
    if name == "chalk-eraser":
        return chalk_eraser_checks(obj)
    if name in DESK_PIECE_TOYS:
        return desk_piece_checks(obj, name)
    if name in CONNECTED_CITY_TOYS:
        return connected_city_checks(obj, name)
    if name in CLASSROOM_FIXTURE_TOYS:
        return classroom_fixture_checks(obj, name)
    lo, hi, size = bounds(obj)
    points = [v.co for v in obj.data.vertices]
    if name in SCHOOLYARD_TOYS:
        return schoolyard_toy_checks(obj, name)
    if name == "school-desk":
        assert (size - Vector((330, 210, 108))).length < .01, "Desk must be exactly 330 x 210 x 108"
        top = [p for p in points if p.z >= 96 - .001]
        top_size = [max(p[i] for p in top) - min(p[i] for p in top) for i in range(3)]
        assert (Vector(top_size) - Vector((330, 210, 12))).length < .01, "Wrong desk slab size"
        hit, point, _, _ = obj.ray_cast(Vector((0, 0, 130)), Vector((0, 0, -1)), distance=40)
        assert hit and abs(point.z - 108) < .01, "Landing surface is not flat at Z=108"
        hit, point, _, _ = obj.ray_cast(Vector((0, -82, 130)), Vector((0, 0, -1)), distance=40)
        assert hit and 104.8 < point.z < 106, "Pencil groove must be recessed"
        for x in (-110, 0, 110):
            for z in (20, 40, 60):
                assert not obj.ray_cast(Vector((x, -120, z)), Vector((0, 1, 0)), distance=240)[0], \
                    "Desk underpass is blocked below Z=60"
        # An open mouth at +Y, with real contents behind it.
        assert obj.ray_cast(Vector((-58, 100, 78)), Vector((0, -1, 0)), distance=100)[0], "Missing cubby books"
        return {"desk_top_xyz": [round(v, 3) for v in top_size], "desk_top_z": 108,
                "groove_floor_z": round(point.z, 3), "underpass_rays_clear": 9,
                "cubby_opens_toward": "+Y"}
    if name == "school-chair":
        # Only the seat is specified as 110 x 100; the reclined back adds depth.
        assert abs(size.x - 110) < .01 and abs(hi.z - 200) < .01, "Wrong chair width or back height"
        hit, point, _, _ = obj.ray_cast(Vector((0, 0, 105)), Vector((0, 0, -1)), distance=20)
        assert hit and abs(point.z - 90) < .01, "Chair seat must be at Z=90"
        seat = [p for p in points if 84.3 <= p.z <= 90.001]
        seat_size = [max(p[i] for p in seat) - min(p[i] for p in seat) for i in range(2)]
        assert max(abs(a - b) for a, b in zip(seat_size, (110, 100))) < .01, "Wrong chair seat footprint"
        return {"seat_xy": [round(v, 3) for v in seat_size], "seat_top_z": round(point.z, 3),
                "backrest_top_z": round(hi.z, 3)}
    if name == "paper-bunting":
        assert abs(size.x - 300) < 2 and hi.z < 1 and lo.z < -61, "Wrong suspended bunting dimensions"
        components = classroom_components(obj)
        assert len(components) == 10, "Bunting needs one string and nine closed paper pennants"
        string = max(components, key=lambda part: max(p.x for p in part) - min(p.x for p in part))
        attachments = []
        for x in (-150, 150):
            ends = [p for p in string if abs(p.x - x) < .7]
            assert ends and max(abs(p.z) for p in ends) < 1, "Bunting attachment must remain at Z=0"
            center = sum(ends, Vector()) / len(ends)
            assert (center - Vector((x, 0, 0))).length < .01, "Wrong attachment center"
            attachments.append([round(v, 3) for v in center])
        middle = [p for p in string if abs(p.x) < .01]
        sag = -sum(p.z for p in middle) / len(middle)
        assert abs(sag - 30) < .01, "String must sag thirty studs"
        flags = [part for part in components if part is not string]
        widths = [max(p.x for p in part) - min(p.x for p in part) for part in flags]
        heights = [max(p.z for p in part) - min(p.z for p in part) for part in flags]
        assert all(abs(w - 26) < .01 for w in widths), "Paper pennants must be 26 studs wide"
        assert all(32 - .01 <= h < 37 for h in heights), "Wrong paper pennant drop"
        return {"attachment_points": attachments, "string_sag": round(sag, 3), "pennants": len(flags),
                "pennant_width_range": [round(min(widths), 3), round(max(widths), 3)],
                "pennant_height_range": [round(min(heights), 3), round(max(heights), 3)]}
    # Connected components let these measurements survive the FBX round trip.
    components = classroom_components(obj)
    assert len(components) == 3, "Saturn needs planet, ring and thread loop"
    planet = min(components, key=lambda part: abs(max(p.z for p in part) - min(p.z for p in part) - 60))
    planet_size = [max(p[i] for p in planet) - min(p[i] for p in planet) for i in range(3)]
    assert max(abs(v - 60) for v in planet_size) < .01, "Planet must be sixty studs across"
    ring = max(components, key=lambda part: max(p.x for p in part) - min(p.x for p in part))
    ring_size = [max(p[i] for p in ring) - min(p[i] for p in ring) for i in range(3)]
    assert abs(ring_size[0] - 140) < .01, "Ring must be 140 studs across"
    plane_points = np.array([p[:] for p in ring])
    _, _, basis = np.linalg.svd(plane_points - plane_points.mean(axis=0), full_matrices=False)
    tilt = math.degrees(math.acos(abs(float(basis[-1, 2]))))
    assert abs(tilt - 20) < .01, "Ring must be tilted twenty degrees"
    return {"planet_xyz": [round(v, 3) for v in planet_size],
            "ring_xyz": [round(v, 3) for v in ring_size], "ring_tilt_degrees": round(tilt, 3)}


def uv_checks(obj):
    """Raster-check non-overlap, atlas boundaries and a full eight-pixel gutter."""
    uv = obj.data.uv_layers.active.data
    mesh_data = obj.data
    face_parent = list(range(len(mesh_data.polygons)))

    def find(i):
        while face_parent[i] != i:
            face_parent[i] = face_parent[face_parent[i]]
            i = face_parent[i]
        return i

    edges = {}
    for face in mesh_data.polygons:
        loops = list(face.loop_indices)
        for a, b in zip(loops, loops[1:] + loops[:1]):
            va, vb = mesh_data.loops[a].vertex_index, mesh_data.loops[b].vertex_index
            ua, ub = tuple(uv[a].uv), tuple(uv[b].uv)
            key = (va, vb, ua, ub) if va < vb else (vb, va, ub, ua)
            if key in edges:
                face_parent[find(face.index)] = find(edges[key])
            else:
                edges[key] = face.index
    coverage = np.zeros((RESOLUTION, RESOLUTION), dtype=np.int32)
    labels = {}
    for face in mesh_data.polygons:
        label = labels.setdefault(find(face.index), len(labels) + 1)
        triangle = np.array([uv[index].uv[:] for index in face.loop_indices]) * RESOLUTION
        assert np.min(triangle) >= -1e-4 and np.max(triangle) <= RESOLUTION + 1e-4, "UV outside atlas"
        low = np.maximum(np.floor(np.min(triangle, axis=0)).astype(int), 0)
        high = np.minimum(np.ceil(np.max(triangle, axis=0)).astype(int), RESOLUTION)
        if np.any(high <= low):
            continue
        x, y = np.meshgrid(np.arange(low[0], high[0]) + .5, np.arange(low[1], high[1]) + .5)
        def cross(a, b):
            return (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0])
        signs = [cross(triangle[i], triangle[(i + 1) % 3]) for i in range(3)]
        inside = np.logical_or(np.logical_and.reduce([s > 1e-4 for s in signs]),
                               np.logical_and.reduce([s < -1e-4 for s in signs]))
        tile = coverage[low[1]:high[1], low[0]:high[0]]
        assert not np.any(tile[inside]), (obj.name, "Overlapping UV triangles", face.index,
                                         mesh_data.attributes["toy_piece"].data[face.index].value
                                         if "toy_piece" in mesh_data.attributes else None)
        tile[inside] = label
    # Four pixels of dilation from either island require >=8px between them.
    grown = coverage.copy()
    for _ in range(4):
        update = grown.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            shifted = np.roll(grown, (dy, dx), axis=(0, 1))
            if dy > 0:
                shifted[:dy, :] = 0
            elif dy < 0:
                shifted[dy:, :] = 0
            if dx > 0:
                shifted[:, :dx] = 0
            elif dx < 0:
                shifted[:, dx:] = 0
            assert not np.any((update != 0) & (shifted != 0) & (update != shifted)), "UV padding below 8px"
            update[(update == 0) & (shifted != 0)] = shifted[(update == 0) & (shifted != 0)]
        grown = update
    assert np.count_nonzero(coverage) > RESOLUTION ** 2 * .15, "Atlas packing wasted too much space"


def configure_cycles(scene):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 4 if PREVIEW else 32
    scene.cycles.use_denoising = True
    preferences = bpy.context.preferences.addons["cycles"].preferences
    try:
        preferences.compute_device_type = "CUDA"
        preferences.get_devices()
        available = any(device.type == "CUDA" for device in preferences.devices)
        for device in preferences.devices:
            device.use = device.type == "CUDA"
        scene.cycles.device = "GPU" if available else "CPU"
    except (TypeError, RuntimeError):
        scene.cycles.device = "CPU"
    scene.render.bake.margin = 4
    scene.render.bake.margin_type = "EXTEND"
    scene.render.bake.use_selected_to_active = False
    scene.render.bake.normal_space = "TANGENT"
    scene.render.bake.normal_r, scene.render.bake.normal_g, scene.render.bake.normal_b = "POS_X", "POS_Y", "POS_Z"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1


def bake(obj, folder, filename, channel):
    active(obj)
    scene = bpy.context.scene
    image = bpy.data.images.new(filename, width=BAKE_RESOLUTION, height=BAKE_RESOLUTION,
                                 alpha=False, float_buffer=False)
    image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
    if channel == "normal":
        image.generated_color = (.5, .5, 1, 1)
    setups = []
    for mat in obj.data.materials:
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        texture = nodes.new("ShaderNodeTexImage")
        texture.image = image
        nodes.active = texture
        output = nodes.get("Material Output")
        original = output.inputs["Surface"].links[0].from_socket
        emission = None
        if channel != "normal":
            emission = nodes.new("ShaderNodeEmission")
            bsdf = nodes.get("Principled BSDF")
            socket = {"color": "Base Color", "roughness": "Roughness", "metalness": "Metallic"}[channel]
            source = bsdf.inputs[socket]
            if source.is_linked:
                links.new(source.links[0].from_socket, emission.inputs["Color"])
            else:
                emission.inputs["Color"].default_value = (source.default_value,) * 3 + (1,)
            links.new(emission.outputs[0], output.inputs["Surface"])
        setups.append((mat, original, texture, emission))
    scene.cycles.samples = (4 if PREVIEW else 32) if channel in ("normal", "color") else 1
    print("BAKING", folder.name, filename, flush=True)
    if channel == "normal":
        bake_piece_normals(obj)
        # Microscopic bevel/Boolean faces can occupy less than one texel.
        # Their bake dilation can inherit another face's tangent basis and
        # create flipped normals. Use the mesh's own smooth normal there.
        pixels = np.empty(BAKE_RESOLUTION * BAKE_RESOLUTION * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape(BAKE_RESOLUTION, BAKE_RESOLUTION, 4)
        unsafe = pixels[:, :, 2] < .7
        assert np.mean(unsafe) < .05, "Normal bake has too many extreme tangent normals"
        filtered = unsafe.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            filtered |= np.roll(unsafe, (dy, dx), axis=(0, 1))
        pixels[filtered, :3] = (.5, .5, 1)
        image.pixels.foreach_set(pixels.ravel())
        image.update()
    elif channel == "metalness":
        # Black is valid non-metal, not an unbaked texel. The color/roughness
        # hole filler would spread silver pigment onto neighboring materials.
        bpy.ops.object.bake(type="EMIT")
    else:
        bpy.ops.object.bake(type="EMIT")
        # Subpixel Boolean slivers can miss the bake raster entirely. Extend
        # neighboring baked texels into empty atlas space without changing
        # any texel that the bake already painted.
        pixels = np.empty(BAKE_RESOLUTION * BAKE_RESOLUTION * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape(BAKE_RESOLUTION, BAKE_RESOLUTION, 4)
        filled = np.max(pixels[:, :, :3], axis=2) > 1e-7
        uv = obj.data.uv_layers.active.data
        for face in obj.data.polygons:
            triangle = np.array([uv[i].uv[:] for i in face.loop_indices])
            mat = obj.data.materials[face.material_index]
            fallback = (mat.node_tree.nodes["Paint color"].outputs[0].default_value[:3]
                        if channel == "color" else
                        [mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value] * 3)
            for weights in ((1 / 3, 1 / 3, 1 / 3), (.8, .1, .1), (.1, .8, .1), (.1, .1, .8)):
                point = np.array(weights) @ triangle
                x, y = np.clip((point * BAKE_RESOLUTION).astype(int), 0, BAKE_RESOLUTION - 1)
                if not filled[y, x]:
                    pixels[y, x, :3] = fallback
                    pixels[y, x, 3] = 1
                    filled[y, x] = True
        for _ in range(16):
            pending = ~filled
            updated = filled.copy()
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                neighbor = np.roll(filled, (dy, dx), axis=(0, 1))
                valid = pending & neighbor
                if dy == 1:
                    valid[0, :] = False
                elif dy == -1:
                    valid[-1, :] = False
                elif dx == 1:
                    valid[:, 0] = False
                else:
                    valid[:, -1] = False
                shifted = np.roll(pixels, (dy, dx), axis=(0, 1))
                pixels[valid] = shifted[valid]
                pending[valid] = False
                updated |= valid
            filled = updated
        image.pixels.foreach_set(pixels.ravel())
        image.update()
    image.filepath_raw = str(folder / filename)
    image.file_format = "PNG"
    image.save()
    for mat, original, texture, emission in setups:
        mat.node_tree.links.new(original, mat.node_tree.nodes.get("Material Output").inputs["Surface"])
        mat.node_tree.nodes.remove(texture)
        if emission:
            mat.node_tree.nodes.remove(emission)
    assert tuple(image.size) == (BAKE_RESOLUTION, BAKE_RESOLUTION)
    return image


def bake_piece_normals(obj):
    """Bake each closed toy part in isolation into its already-packed UVs.

    Bevel rays must not hit neighboring balls, tyres or the cabin. Those hits
    produce dark flecks in the normal map where separate toy pieces intersect.
    The copies retain the exported corner normals, positions and UVs exactly.
    """
    scene = bpy.context.scene
    source = obj.data
    pieces = source.attributes["toy_piece"].data
    source_uv = source.uv_layers.active.data
    obj.hide_render = True
    try:
        for step, piece_id in enumerate(sorted({value.value for value in pieces})):
            faces = [face for face in source.polygons if pieces[face.index].value == piece_id]
            ids = sorted({index for face in faces for index in face.vertices})
            remap = {index: i for i, index in enumerate(ids)}
            data = bpy.data.meshes.new("Temporary isolated normal bake")
            data.from_pydata([source.vertices[index].co for index in ids], [],
                             [tuple(remap[index] for index in face.vertices) for face in faces])
            data.update()
            for mat in source.materials:
                data.materials.append(mat)
            uv = data.uv_layers.new(name="ToyUV")
            normals = []
            for face, original in zip(data.polygons, faces):
                face.use_smooth, face.material_index = original.use_smooth, original.material_index
                for new_loop, old_loop in zip(face.loop_indices, original.loop_indices):
                    uv.data[new_loop].uv = source_uv[old_loop].uv
                    normals.append(source.corner_normals[old_loop].vector.copy())
            data.normals_split_custom_set(normals)
            if "sheet_coordinates" in source.attributes:
                attr = data.attributes.new("sheet_coordinates", "FLOAT_VECTOR", "POINT")
                for item, index in zip(attr.data, ids):
                    item.vector = source.attributes["sheet_coordinates"].data[index].vector
            temporary = bpy.data.objects.new("Temporary isolated normal bake", data)
            bpy.context.collection.objects.link(temporary)
            active(temporary)
            scene.render.bake.use_clear = step == 0
            bpy.ops.object.bake(type="NORMAL")
            bpy.data.objects.remove(temporary, do_unlink=True)
            bpy.data.meshes.remove(data)
    finally:
        obj.hide_render = False
        scene.render.bake.use_clear = True
        active(obj)


def desk_piece_fill_maps(images):
    """Fill all atlas gaps with nearby baked colour, using one mask for all maps.

    A jump-flood nearest-texel search needs only numpy, so Blender can run this
    without installing scipy. Painted dark corrugation is valid, not a gap.
    """
    color = images["color"]
    pixels = np.empty(RESOLUTION * RESOLUTION * 4, dtype=np.float32)
    color.pixels.foreach_get(pixels)
    pixels = pixels.reshape(RESOLUTION, RESOLUTION, 4)
    filled = pixels[:, :, :3].max(axis=2) > 1e-7
    assert filled.any(), "Empty colour bake"
    yy, xx = np.indices(filled.shape, dtype=np.int32)
    nearest_y, nearest_x = np.where(filled, yy, -1), np.where(filled, xx, -1)
    distance = np.where(filled, 0, np.iinfo(np.int32).max)
    for step in [512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 1]:
        for dy, dx in ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)):
            ny = np.roll(nearest_y, (dy * step, dx * step), axis=(0, 1))
            nx = np.roll(nearest_x, (dy * step, dx * step), axis=(0, 1))
            valid = ny >= 0
            if dy > 0:
                valid[:step] = False
            elif dy < 0:
                valid[-step:] = False
            if dx > 0:
                valid[:, :step] = False
            elif dx < 0:
                valid[:, -step:] = False
            candidate = (ny - yy) ** 2 + (nx - xx) ** 2
            better = valid & (candidate < distance)
            nearest_y[better], nearest_x[better], distance[better] = ny[better], nx[better], candidate[better]
    assert np.all(nearest_y >= 0), "Gap fill left an empty texel"
    for image in images.values():
        image.pixels.foreach_get(pixels.ravel())
        pixels[~filled] = pixels[nearest_y[~filled], nearest_x[~filled]]
        pixels[:, :, 3] = 1
        image.pixels.foreach_set(pixels.ravel())
        image.update()
        image.save()
    return round(float((~filled).mean()) * 100, 3)


def desk_piece_contact_sheet(folder, filenames, output):
    """Labelled contact sheet; the individual maps keep their full 1024 size."""
    glyphs = {
        "A": [14, 17, 17, 31, 17, 17, 17], "C": [14, 17, 16, 16, 16, 17, 14],
        "D": [30, 17, 17, 17, 17, 17, 30], "E": [31, 16, 16, 30, 16, 16, 31],
        "F": [31, 16, 16, 30, 16, 16, 16], "G": [14, 17, 16, 23, 17, 17, 15],
        "H": [17, 17, 17, 31, 17, 17, 17], "I": [14, 4, 4, 4, 4, 4, 14],
        "L": [16, 16, 16, 16, 16, 16, 31], "M": [17, 27, 21, 21, 17, 17, 17],
        "N": [17, 25, 21, 19, 17, 17, 17], "O": [14, 17, 17, 17, 17, 17, 14],
        "P": [30, 17, 17, 30, 16, 16, 16], "Q": [14, 17, 17, 17, 21, 18, 13],
        "R": [30, 17, 17, 30, 20, 18, 17], "S": [15, 16, 16, 14, 1, 1, 30],
        "T": [31, 4, 4, 4, 4, 4, 4], "U": [17, 17, 17, 17, 17, 17, 14],
        "V": [17, 17, 17, 17, 17, 10, 4], "W": [17, 17, 17, 21, 21, 21, 10],
        "Y": [17, 17, 10, 4, 4, 4, 4], "-": [0, 0, 0, 31, 0, 0, 0],
    }
    panels = []
    for filename in filenames:
        pixels = png_read(folder / filename)
        side = 512 if output == "maps-sheet.png" else 400
        factor = pixels.shape[0] // side
        resized = np.rint(pixels.reshape(side, factor, side, factor, 3).mean(axis=(1, 3))).astype(np.uint8)
        panel = np.full((side + 32, side, 3), (246, 241, 228), dtype=np.uint8)
        panel[32:] = resized
        for i, letter in enumerate(Path(filename).stem.upper()):
            for y, row in enumerate(glyphs.get(letter, [0] * 7)):
                for x in range(5):
                    if row & (1 << (4 - x)):
                        panel[8 + y * 2:10 + y * 2, 10 + i * 12 + x * 2:12 + i * 12 + x * 2] = (71, 58, 42)
        panels.append(panel)
    png_write(folder / output, np.concatenate(panels, axis=1))


def desk_piece_reference(folder, name):
    filename = "rings.png" if name == "landing-ring" else "powerup.png" if name == "speed-bolt" else "pad-runway.png"
    pixels = png_read(ROOT / "assets/references/world-pieces" / filename)
    if name == "landing-ring":
        pixels = pixels[:, :pixels.shape[1] // 3]
    elif name == "speed-bolt":
        pixels = pixels[:round(pixels.shape[0] * .435), :pixels.shape[1] // 3]
    png_write(folder / "concept.png", pixels)


def desk_piece_views(obj, name, folder, camera, center, scale, frame):
    primary = (folder / "render.png").read_bytes()
    (folder / "three-quarter.png").write_bytes(primary)
    position, rotation, ortho_scale = camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale
    directions = [("front.png", (0, -1, 0)), ("side.png", (1, 0, 0))]
    if name.startswith("desk-runway"):
        directions.append(("top.png", (0, 0, 1)))
    floor = bpy.data.objects.get("Temporary studio backdrop")
    try:
        for filename, direction in directions:
            target = center
            camera.location = target + Vector(direction).normalized() * scale * 3.5
            point_at(camera, target)
            view = camera.rotation_euler.to_matrix().transposed()
            cloud = [view @ (obj.matrix_world @ v.co - target) for v in obj.data.vertices]
            if name == "runway-light":
                cloud += [view @ (Vector(p) - target) for p in runway_light_geometry(tip=True)[0]]
            width = max(p.x for p in cloud) - min(p.x for p in cloud)
            height = max(p.y for p in cloud) - min(p.y for p in cloud)
            camera.data.ortho_scale = max(width, height) / .86
            shift = Vector(((max(p.x for p in cloud) + min(p.x for p in cloud)) / 2,
                            (max(p.y for p in cloud) + min(p.y for p in cloud)) / 2, 0))
            camera.location += camera.rotation_euler.to_matrix() @ shift
            if floor:
                floor.hide_render = name.startswith("desk-runway")
            frame()
            (folder / "render.png").replace(folder / filename)
    finally:
        (folder / "render.png").write_bytes(primary)
        camera.location, camera.rotation_euler, camera.data.ortho_scale = position, rotation, ortho_scale
        if floor:
            floor.hide_render = False
    desk_piece_contact_sheet(folder, ["front.png", "side.png", "three-quarter.png"] +
                             (["top.png"] if name.startswith("desk-runway") else []), "renders-sheet.png")


def baked_material(images):
    mat = bpy.data.materials.new("Toy baked color normal roughness")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Coat Weight"].default_value = .16
    bsdf.inputs["Coat Roughness"].default_value = .27
    for channel, image in images.items():
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = channel.capitalize() + " map"
        tex.image = image
        tex.interpolation = "Linear"
        if channel == "normal":
            normal = nodes.new("ShaderNodeNormalMap")
            normal.space, normal.uv_map = "TANGENT", "ToyUV"
            links.new(tex.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
        else:
            socket = {"color": "Base Color", "roughness": "Roughness", "metalness": "Metallic"}[channel]
            links.new(tex.outputs["Color"], bsdf.inputs[socket])
    return mat


def export_and_reload(obj, name, folder, mat):
    materials = [mat]
    assignments = [0] * len(obj.data.polygons)
    if name == "ceiling-light":
        diffuser = next(i for i, source in enumerate(obj.data.materials)
                        if source.name == "Ceiling light frosted diffuser source")
        assignments = [int(face.material_index == diffuser) for face in obj.data.polygons]
        glow = mat.copy()
        glow.name = "Glow"
        materials.append(glow)
    obj.data.materials.clear()
    for exported in materials:
        obj.data.materials.append(exported)
    for face, assignment in zip(obj.data.polygons, assignments):
        face.material_index = assignment
    metadata = {key: obj[key] for key in obj.keys()}
    regions = [item.value for item in obj.data.attributes["procedural_region"].data]
    geometry_checks(obj, name, baked=True)
    active(obj)
    bpy.ops.export_scene.fbx(filepath=str(folder / (name + ".fbx")), use_selection=True,
                             object_types={"MESH"}, apply_unit_scale=False, global_scale=1,
                             axis_forward="-Z", axis_up="Y", bake_space_transform=False,
                             use_custom_props=name == "paper-chain",
                             mesh_smooth_type="OFF", path_mode="AUTO", embed_textures=False,
                             add_leaf_bones=False)
    triangle_count = len(obj.data.polygons)
    before = bounds(obj)[2]
    bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.import_scene.fbx(filepath=str(folder / (name + ".fbx")), use_custom_normals=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(meshes) == 1, "FBX did not round-trip as one mesh"
    obj = meshes[0]
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.name = name
    # Read the round-trip face assignments before restoring Blender's richer
    # baked nodes. FBX retains the separate diffuser slot, including its name.
    if name == "ceiling-light":
        imported_slots = [slot.name.split(".")[0] for slot in obj.data.materials]
        assert "Glow" in imported_slots, "FBX lost the Glow material"
        imported_glow = imported_slots.index("Glow")
        assignments = [int(face.material_index == imported_glow) for face in obj.data.polygons]
    obj.data.materials.clear()
    for exported in materials:
        obj.data.materials.append(exported)
    obj.data.uv_layers.active.name = "ToyUV"
    for face, assignment in zip(obj.data.polygons, assignments):
        face.material_index = assignment
    for key, value in metadata.items():
        obj[key] = value
    attr = obj.data.attributes.new("procedural_region", "INT", "FACE")
    for index, value in enumerate(regions):
        attr.data[index].value = value
    assert len(obj.data.polygons) == triangle_count, "FBX changed triangle count"
    assert (bounds(obj)[2] - before).length < .01, "FBX changed dimensions"
    geometry_checks(obj, name, baked=True)
    return obj


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render(obj, name, folder, source=False):
    if name == "chalk-eraser":
        chalk_eraser_render(obj, folder)
        return
    scene = bpy.context.scene
    tip_helper = None
    if name == "runway-light":
        tip_folder = OUTPUT / "runway-light-tip"
        assert (tip_folder / "runway-light-tip.fbx").is_file(), "Build runway-light-tip before runway-light"
        bpy.ops.import_scene.fbx(filepath=str(tip_folder / "runway-light-tip.fbx"))
        tip_helper = next(o for o in scene.objects if o.type == "MESH" and o != obj)
        active(tip_helper)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        tip_images = {}
        for channel in ("color", "normal", "roughness"):
            image = bpy.data.images.load(str(tip_folder / (channel + ".png")), check_existing=False)
            image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
            tip_images[channel] = image
        tip_mat = baked_material(tip_images)
        tip_mat.node_tree.nodes["Principled BSDF"].inputs["Coat Weight"].default_value = 0
        tip_helper.data.materials.clear()
        tip_helper.data.materials.append(tip_mat)
    obj.cycles.shadow_terminator_offset = .15
    obj.cycles.shadow_terminator_geometry_offset = .25
    scene.cycles.samples = 64
    scene.render.engine = "BLENDER_EEVEE" if PREVIEW else "CYCLES"
    scene.render.resolution_x = scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    if name == "ruler-bridge":
        scene.view_settings.exposure = .35
    world = bpy.data.worlds.new("Cream studio")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = linear((250, 246, 238))
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = .6
    lo, hi, dimensions = bounds(obj)
    if tip_helper:
        hi.z = 4
        dimensions = hi - lo
    scale = max(dimensions)
    center = (lo + hi) / 2
    # The flag is seen almost straight on. Trees need very little yaw because
    # their front cluster should remain central like the supplied drawing.
    direction = {"flagpole": (.26, -1, .38), "pencil-flagpole": (.24, -1, .20),
                 "classroom-door": (.18, -1, .16), "floor-fan": (.55, -1, 1.6),
                 "desk-hangar": (.55, -1, .62), "cubby-shelf": (.42, -1, .38),
                 "backpack-cubby": (.28, -1, .34),
                 "bulletin-board": (.18, -1, .15),
                 "classroom-bookshelf": (.42, -1, .32), "ceiling-light": (.15, -.5, -1),
                 "school-desk": (.65, 1, .60), "school-chair": (.8, -1, .56),
                 "jungle-gym": (-.8, -1, .60), "swing-set": (.50, -1, .38),
                 "slide": (.45, -1, .48), "basketball-hoop": (.45, -1, .24),
                 "fence-panel": (.16, -1, .24),
                 "seesaw": (.35, -1, .48), "merry-go-round": (.65, -1, .82),
                 "spring-rider": (.28, -1, .42), "monkey-bars": (.55, -1, .42),
                 "tire-swing": (.45, -1, .38), "crawl-tunnel": (-1, -1, .48),
                 "paper-bunting": (.10, -1, .22), "saturn": (.55, -1, .02),
                 "ruler-section": (.24, -1, .95), "ruler-tape": (.75, -1, .45),
                 "ceiling-ring": (.18, -1, .10), "cardboard-tube": (.8, -1, .30),
                 "paper-chain": (.32, -1, .04),
                 "landing-ring": (.30, -1, .16), "speed-bolt": (.65, -1, .15),
                 "runway-light": (.65, -1, .42), "runway-light-tip": (.65, -1, .42),
                 "desk-runway-droop": (.65, 1, .80), "desk-runway-straight": (.65, 1, .80),
                 "tree-bushy": (.12, -1, .3),
                 "tree-lollipop": (.25, -1, .25), "tree-pine": (.3, -1, .32),
                 "bench": (.7, -1, .55), "car-hatchback": (.8, -1, .63),
                 "car-sedan": (.8, -1, .63), "car-taxi": (.8, -1, .63),
                 "car-van": (.8, -1, .58), "fire-truck": (.8, -1, .58),
                 "fountain": (.6, -1, .55), "stall": (.7, -1, .30),
                 "house": (.8, -1, .63), "picnic": (.8, -1, .68),
                 "plane": (.8, -1, .36), "pool": (.5, -1, .60),
                 "petrol-station": (.75, -1, .48), "fire-station": (.8, -1, .58),
                 "terminal": (.7, -1, .55), "hangar": (.8, -1, .56),
                 "barn": (.8, -1, .60), "boathouse": (.8, -1, .58),
                 "hay-bale": (.8, -1, .50), "footbridge": (.8, -1, .62),
                 "ruler-bridge": (.38, -1, .62)}.get(name, (.8, -1, .62))
    camera = bpy.data.objects.new("Concept three-quarter camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type = "ORTHO"
    camera.data.clip_end = max(1000, scale * 8)
    camera.location = center + Vector(direction).normalized() * scale * 3.5
    point_at(camera, center)
    view = camera.rotation_euler.to_matrix().transposed()
    projections = [view @ (obj.matrix_world @ v.co - center) for v in obj.data.vertices]
    if tip_helper:
        projections += [view @ (tip_helper.matrix_world @ v.co - center) for v in tip_helper.data.vertices]
    width = max(v.x for v in projections) - min(v.x for v in projections)
    height = max(v.y for v in projections) - min(v.y for v in projections)
    # Match the concept's occupied fraction after fitting it to an 800px square.
    occupied = .9
    if name not in CONCEPTLESS_TOYS:
        concept = png_read(OUTPUT / name / "concept.png").astype(float)
        saturation = concept.max(axis=2) - concept.min(axis=2)
        foreground = (saturation > 42) | (concept.mean(axis=2) < 175)
        ys, xs = np.where(foreground)
        occupied = max(xs.max() - xs.min(), ys.max() - ys.min()) / max(concept.shape[:2])
        occupied = min(.93, max(.78, occupied))
    camera.data.ortho_scale = max(width, height) / occupied
    projected_center = Vector(((max(v.x for v in projections) + min(v.x for v in projections)) / 2,
                               (max(v.y for v in projections) + min(v.y for v in projections)) / 2, 0))
    camera.location += camera.rotation_euler.to_matrix() @ projected_center
    for label, direction, strength, tint, size in [
        ("Warm softbox", (-.75, -1, 1.2), 23, (255, 247, 232), 1.1),
        ("Cool soft fill", (1, -.35, .7), 6, (241, 246, 255), 1.3),
        ("Soft rim", (.4, 1, 1.3), 8, (255, 250, 239), 1.1),
    ]:
        data = bpy.data.lights.new(label, "AREA")
        light = bpy.data.objects.new(label, data)
        scene.collection.objects.link(light)
        if name == "ceiling-light":
            direction = (direction[0], direction[1], -direction[2])
        light.location = center + Vector(direction) * scale * 1.6
        data.energy = strength * scale ** 2
        if PREVIEW:
            data.energy *= 2.2
        data.color = linear(tint)[:3]
        data.shape, data.size = "DISK", size * scale
        point_at(light, center)
    # Temporary cream floor is the photo backdrop, never part of the toy or FBX.
    floor_z = lo.z - .015 if name in SPECIAL_ORIGIN_TOYS else -.015
    bpy.ops.mesh.primitive_plane_add(size=scale * 200, location=(0, 0, floor_z))
    floor = bpy.context.object
    floor.name = "Temporary studio backdrop"
    floor_mat = bpy.data.materials.new("Cream backdrop")
    floor_mat.use_nodes = True
    floor_bsdf = floor_mat.node_tree.nodes.get("Principled BSDF")
    floor_bsdf.inputs["Base Color"].default_value = linear((247, 243, 231))
    floor_bsdf.inputs["Roughness"].default_value = .85
    if PREVIEW:
        floor_bsdf.inputs["Emission Color"].default_value = linear((246, 241, 228))
        floor_bsdf.inputs["Emission Strength"].default_value = .6
    floor.data.materials.append(floor_mat)
    floor.is_shadow_catcher = True
    if name == "ceiling-light":
        floor.hide_render = True
    if name == "ruler-bridge":
        world.node_tree.nodes["Background"].inputs["Color"].default_value = linear((224, 224, 224))
        floor_bsdf.inputs["Base Color"].default_value = linear((190, 190, 190))
    scene.render.film_transparent = True
    scene.render.filepath = str(folder / "render.png")
    print("RENDERING", name, "procedural source materials" if source else "quick preview" if PREVIEW else
          "FBX round-trip mesh and baked maps only", flush=True)
    def frame():
        bpy.ops.render.render(write_still=True)
        rgba = png_read(folder / "render.png", alpha=True).astype(np.float32)
        opacity = rgba[:, :, 3:4] / 255
        cream = np.array([190, 190, 190] if name == "ruler-bridge" else [246, 241, 228], dtype=np.float32)
        pixels = np.clip(rgba[:, :, :3] * opacity + cream * (1 - opacity), 0, 255).astype(np.uint8)
        png_write(folder / "render.png", pixels)
        return pixels

    rendered = frame()
    if name in DESK_PIECE_TOYS and not source:
        desk_piece_views(obj, name, folder, camera, center, scale, frame)
    if name in CONNECTED_CITY_TOYS and not source:
        connected_city_views(obj, name, folder, camera, center, scale, frame)
    if name in ("classroom-bookshelf", "backpack-cubby", "ceiling-light") and not source:
        primary = (folder / "render.png").read_bytes()
        position, rotation, ortho_scale = camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale
        views = [("front.png", (0, -1, 0))] if name != "ceiling-light" else [("below.png", (0, 0, -1))]
        (folder / ("three-quarter.png" if name != "ceiling-light" else "below-three-quarter.png")).write_bytes(primary)
        try:
            for filename, direction in views:
                camera.location = center + Vector(direction).normalized() * scale * 3.5
                point_at(camera, center)
                view = camera.rotation_euler.to_matrix().transposed()
                projections = [view @ (obj.matrix_world @ v.co - center) for v in obj.data.vertices]
                width = max(v.x for v in projections) - min(v.x for v in projections)
                height = max(v.y for v in projections) - min(v.y for v in projections)
                camera.data.ortho_scale = max(width, height) / occupied
                frame()
                (folder / "render.png").replace(folder / filename)
        finally:
            (folder / "render.png").write_bytes(primary)
            camera.location, camera.rotation_euler, camera.data.ortho_scale = position, rotation, ortho_scale
    if name in ("floor-fan", "desk-hangar") and not source:
        primary = (folder / "render.png").read_bytes()
        position, rotation, ortho_scale = camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale
        color_node = obj.data.materials[0].node_tree.nodes["Color map"]
        primary_image = color_node.image

        def detail_view(filename, direction, focus=None, zoom=None):
            target = center if focus is None else Vector(focus)
            camera.location = target + Vector(direction).normalized() * scale * 3.5
            point_at(camera, target)
            if zoom is None:
                view = camera.rotation_euler.to_matrix().transposed()
                projections = [view @ (obj.matrix_world @ v.co - center) for v in obj.data.vertices]
                width = max(v.x for v in projections) - min(v.x for v in projections)
                height = max(v.y for v in projections) - min(v.y for v in projections)
                camera.data.ortho_scale = max(width, height) / occupied
                shift = Vector(((max(v.x for v in projections) + min(v.x for v in projections)) / 2,
                                (max(v.y for v in projections) + min(v.y for v in projections)) / 2, 0))
                camera.location += camera.rotation_euler.to_matrix() @ shift
            else:
                camera.data.ortho_scale = zoom
            pixels = frame()
            (folder / "render.png").replace(folder / filename)
            return pixels

        try:
            if name == "floor-fan":
                detail_view("top.png", (0, 0, 1))
                detail_view("close-up.png", (0, -1, 1.4), (0, -43, 25), 85)
            else:
                panels = []
                for index in range(1, 13):
                    color_node.image = bpy.data.images.get("color-" + str(index) + ".png")
                    assert color_node.image, "Missing numbered hangar map"
                    pixels = detail_view("number-" + str(index) + "-45deg.png", (0, -1, 1))
                    panels.append(np.rint(pixels.reshape(400, 2, 400, 2, 3).mean(axis=(1, 3))).astype(np.uint8))
                rows = [np.concatenate(panels[start:start + 4], axis=1) for start in range(0, 12, 4)]
                png_write(folder / "numbers-contact-sheet.png", np.concatenate(rows, axis=0))
                detail_view("number-12-close-up.png", (0, -1, 1), (0, -5, 46), 60)
                color_node.image = primary_image
                detail_view("front.png", (0, -1, .35))
                detail_view("close-up.png", (0, -1, 1), (0, -5, 46), 60)
        finally:
            color_node.image = primary_image
            (folder / "render.png").write_bytes(primary)
            camera.location, camera.rotation_euler, camera.data.ortho_scale = position, rotation, ortho_scale
    if name == "crawl-tunnel" and not source:
        # The three-quarter photograph shows the whole barrel. This second
        # photograph looks through its real opening using the exported mesh.
        primary = (folder / "render.png").read_bytes()
        position, rotation, ortho_scale = camera.location.copy(), camera.rotation_euler.copy(), camera.data.ortho_scale
        try:
            camera.location = center + Vector((-1, -.10, .06)).normalized() * scale * 3.5
            point_at(camera, center)
            view = camera.rotation_euler.to_matrix().transposed()
            projections = [view @ (obj.matrix_world @ v.co - center) for v in obj.data.vertices]
            width = max(v.x for v in projections) - min(v.x for v in projections)
            height = max(v.y for v in projections) - min(v.y for v in projections)
            camera.data.ortho_scale = max(width, height) / occupied
            projected_center = Vector(((max(v.x for v in projections) + min(v.x for v in projections)) / 2,
                                       (max(v.y for v in projections) + min(v.y for v in projections)) / 2, 0))
            camera.location += camera.rotation_euler.to_matrix() @ projected_center
            frame()
            (folder / "render.png").replace(folder / "opening.png")
        finally:
            (folder / "render.png").write_bytes(primary)
            camera.location, camera.rotation_euler, camera.data.ortho_scale = position, rotation, ortho_scale
    if name == "crop-row" and not PREVIEW:
        primary = (folder / "render.png").read_bytes()
        color_node = obj.data.materials[0].node_tree.nodes["Color map"]
        primary_image = color_node.image
        panels = [rendered]
        try:
            for index in (1, 2):
                color_node.image = bpy.data.images.get("color-" + str(index) + ".png")
                assert color_node.image, "Missing crop variant map"
                panels.append(frame())
            png_write(folder / "compare.png", np.concatenate(panels, axis=1))
        finally:
            color_node.image = primary_image
            (folder / "render.png").write_bytes(primary)
    bpy.data.objects.remove(floor, do_unlink=True)
    if tip_helper:
        bpy.data.objects.remove(tip_helper, do_unlink=True)
    active(obj)


def png_read(path, alpha=False):
    """Small RGB/RGBA PNG reader for an unmodified side-by-side comparison."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    position, compressed = 8, bytearray()
    while position < len(data):
        length = struct.unpack_from(">I", data, position)[0]
        tag, payload = data[position + 4:position + 8], data[position + 8:position + 8 + length]
        if tag == b"IHDR":
            width, height, depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
            assert depth == 8 and color_type in (2, 6) and interlace == 0, "Unsupported PNG format"
        elif tag == b"IDAT":
            compressed.extend(payload)
        position += length + 12
    channels = 3 if color_type == 2 else 4
    raw = np.frombuffer(zlib.decompress(compressed), dtype=np.uint8).reshape(height, width * channels + 1)
    rows = np.zeros((height, width * channels), dtype=np.uint8)
    for y in range(height):
        kind, encoded = int(raw[y, 0]), raw[y, 1:]
        if kind == 0:
            rows[y] = encoded
            continue
        for x in range(width * channels):
            a = int(rows[y, x - channels]) if x >= channels else 0
            b = int(rows[y - 1, x]) if y else 0
            c = int(rows[y - 1, x - channels]) if y and x >= channels else 0
            if kind == 1:
                prediction = a
            elif kind == 2:
                prediction = b
            elif kind == 3:
                prediction = (a + b) // 2
            else:
                p = a + b - c
                errors = [abs(p - a), abs(p - b), abs(p - c)]
                prediction = (a, b, c)[errors.index(min(errors))]
            rows[y, x] = (int(encoded[x]) + prediction) & 255
    pixels = rows.reshape(height, width, channels)
    return pixels if alpha else pixels[:, :, :3]


def png_write(path, pixels):
    height, width, _ = pixels.shape
    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload +
                struct.pack(">I", zlib.crc32(tag + payload) & 0xffffffff))
    raw = b"".join(b"\0" + row.tobytes() for row in pixels)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" +
                     chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) +
                     chunk(b"IDAT", zlib.compress(raw, 8)) + chunk(b"IEND", b""))


def comparison(folder):
    if folder.name == "chalk-eraser":
        reference = png_read(folder / "model-sheet.png")
        rendered = png_read(folder / "renders-sheet.png")
        assert reference.shape == rendered.shape, "Need matching four-view sheets"
        png_write(folder / "compare.png", np.concatenate((reference, rendered), axis=1))
        return
    if folder.name == "crop-row":
        if PREVIEW:
            png_write(folder / "compare.png", png_read(folder / "render.png"))
        return
    concept = png_read(folder / "concept.png")
    rendered = png_read(folder / "render.png")
    side = rendered.shape[0]
    factor = side / max(concept.shape[:2])
    height, width = round(concept.shape[0] * factor), round(concept.shape[1] * factor)
    # Bilinear resize preserves the reference's aspect and colors.
    ys = np.linspace(0, concept.shape[0] - 1, height)
    xs = np.linspace(0, concept.shape[1] - 1, width)
    y0, x0 = ys.astype(int), xs.astype(int)
    y1, x1 = np.minimum(y0 + 1, concept.shape[0] - 1), np.minimum(x0 + 1, concept.shape[1] - 1)
    fy, fx = (ys - y0)[:, None, None], (xs - x0)[None, :, None]
    top = concept[y0[:, None], x0[None, :]] * (1 - fx) + concept[y0[:, None], x1[None, :]] * fx
    bottom = concept[y1[:, None], x0[None, :]] * (1 - fx) + concept[y1[:, None], x1[None, :]] * fx
    scaled = np.clip(top * (1 - fy) + bottom * fy, 0, 255).astype(np.uint8)
    reference = np.full_like(rendered, (190, 190, 190) if folder.name == "ruler-bridge" else (246, 241, 228))
    y, x = (side - height) // 2, (side - width) // 2
    reference[y:y + height, x:x + width] = scaled
    png_write(folder / "compare.png", np.concatenate((reference, rendered), axis=1))


def file_checks(folder, name):
    required = [name + ".fbx", name + ".blend", "color.png", "normal.png", "roughness.png",
                "render.png", "compare.png"]
    if name == "chalk-eraser":
        required += ["model-sheet.png", "front.png", "end.png", "top.png", "three-quarter.png",
                     "renders-sheet.png", "maps-sheet.png"]
        sheet = png_read(folder / "model-sheet.png")
        h, w = sheet.shape[:2]
        comparison_pixels = png_read(folder / "compare.png")
        assert comparison_pixels.shape[:2] == (h, w * 2), "Need four reference and four rendered views"
        assert np.array_equal(comparison_pixels[:, :w], sheet), "Approved reference must remain unchanged"
        assert png_read(folder / "renders-sheet.png").shape[:2] == (h, w)
        assert png_read(folder / "maps-sheet.png").shape[:2] == (544, 1536)
        assert not np.any(png_read(folder / "color.png").max(axis=2) == 0), "Black atlas gaps remain"
    if name in {"ruler-bridge"} | SOURCE_REFERENCE_TOYS:
        required.append("concept.png")
    if name in DESK_PIECE_TOYS:
        required += ["concept.png", "front.png", "side.png", "three-quarter.png", "renders-sheet.png", "maps-sheet.png"]
        if name.startswith("desk-runway"):
            required.append("top.png")
        assert not np.any(png_read(folder / "color.png").max(axis=2) == 0), "Black atlas gaps remain"
        assert png_read(folder / "maps-sheet.png").shape[:2] == (544, 1536), "Need every map on the contact sheet"
        assert png_read(folder / "renders-sheet.png").shape[:2] == (432, 1600 if name.startswith("desk-runway") else 1200)
    if name in METALNESS_TOYS:
        required.append("metalness.png")
    if name == "crawl-tunnel":
        required.append("opening.png")
    if name == "tree-lollipop":
        required.append("color-autumn.png")
    if name in ("stall", "house", "crop-row"):
        required += ["color-" + str(i) + ".png" for i in range(6 if name == "stall" else 3)]
        assert (folder / "color.png").read_bytes() == (folder / "color-0.png").read_bytes()
    if name == "floor-fan":
        required += ["top.png", "close-up.png"]
    if name in ("classroom-bookshelf", "backpack-cubby"):
        required += ["front.png", "three-quarter.png"]
    if name == "ceiling-light":
        required += ["below.png", "below-three-quarter.png"]
    if name in ("ruler-tape", "ceiling-ring", "cardboard-tube"):
        required.append("opening.png")
    if name == "ruler-section":
        required.append("underside.png")
    if name == "paper-chain":
        required.append("side.png")
    if name == "desk-hangar":
        required += ["color-" + str(i) + ".png" for i in range(1, 13)]
        required += ["number-" + str(i) + "-45deg.png" for i in range(1, 13)]
        required += ["numbers-contact-sheet.png", "number-12-close-up.png", "front.png", "close-up.png"]
        assert (folder / "color.png").read_bytes() == (folder / "color-1.png").read_bytes()
        assert len({(folder / ("color-" + str(i) + ".png")).read_bytes() for i in range(1, 13)}) == 12, \
            "Every hangar number needs a distinct map"
        assert png_read(folder / "numbers-contact-sheet.png").shape[:2] == (1200, 1600), "Need twelve 45-degree views"
    for filename in required:
        path = folder / filename
        assert path.is_file() and path.stat().st_size > 100, ("Missing output", path)
        if filename.startswith("color") or filename in ("normal.png", "roughness.png", "metalness.png"):
            header = path.read_bytes()[:24]
            assert struct.unpack(">II", header[16:24]) == (RESOLUTION, RESOLUTION), "Wrong map dimensions"
    for filename in required:
        if filename in ("render.png", "front.png", "three-quarter.png", "below.png", "below-three-quarter.png",
                        "opening.png", "underside.png", "side.png", "top.png", "end.png"):
            assert png_read(folder / filename).shape[:2] == (800, 800), ("Wrong render dimensions", filename)
    if name == "crawl-tunnel":
        assert png_read(folder / "opening.png").shape[:2] == (800, 800), "Need exported tunnel opening view"
    if name == "crop-row":
        assert png_read(folder / "compare.png").shape[:2] == (800, 2400), "Crop comparison needs three variants"
    if name in SOURCE_REFERENCE_TOYS:
        assert png_read(folder / "compare.png").shape[:2] == (800, 1600), "Need source and exported toy views"


def build(name):
    assert not (PREVIEW and name in CLASSROOM_TOYS), "Classroom toys require full 1024px bakes"
    if name == "runway-light" and not (OUTPUT / "runway-light-tip/runway-light-tip.fbx").is_file():
        build("runway-light-tip")
    PARTS.clear()
    MATERIALS.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1
    configure_cycles(scene)
    folder = OUTPUT / name
    if name in CONCEPTLESS_TOYS:
        if not PREVIEW:
            folder.mkdir(parents=True, exist_ok=True)
    else:
        assert (folder / "concept.png").is_file(), ("Missing concept", name)
    if PREVIEW:
        folder = Path(tempfile.gettempdir()) / "flyfight-toys-round3" / name
        folder.mkdir(parents=True, exist_ok=True)
        if name not in CONCEPTLESS_TOYS:
            (folder / "concept.png").write_bytes((OUTPUT / name / "concept.png").read_bytes())
    if name in DESK_PIECE_TOYS:
        desk_piece_reference(folder, name)
    BUILDERS[name]()
    for mat in MATERIALS.values():
        mat.node_tree.nodes["Soft contact occlusion"].inputs["Distance"].default_value = 3 if name == "ruler-bridge" else max(
            value for value in SPECS[name][1] if value) * .065
    for part in PARTS:
        part.data.calc_loop_triangles()
    count = sum(len(part.data.loop_triangles) for part in PARTS)
    assert count <= triangle_cap(name), (name, "Triangle cap before packing", count, triangle_cap(name))
    obj = assemble(name)
    report = geometry_checks(obj, name)
    uv_checks(obj)
    print("GEOMETRY", json.dumps(report), flush=True)
    if name in SOURCE_REFERENCE_TOYS:
        # No supplied image reference: compare actual procedural materials with
        # the exported mesh and maps, rather than inventing a concept drawing.
        render(obj, name, folder, source=True)
        (folder / "render.png").replace(folder / "concept.png")
        for helper in list(scene.objects):
            if helper.type in ("CAMERA", "LIGHT"):
                bpy.data.objects.remove(helper, do_unlink=True)
        configure_cycles(scene)
    images = {"color": bake(obj, folder, "color.png", "color"),
              "roughness": bake(obj, folder, "roughness.png", "roughness")}
    if PREVIEW:
        mat = baked_material(images)
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        for face in obj.data.polygons:
            face.material_index = 0
        render(obj, name, folder)
        comparison(folder)
        print("PREVIEW", json.dumps(report), flush=True)
        return report
    images["normal"] = bake(obj, folder, "normal.png", "normal")
    if name in METALNESS_TOYS:
        images["metalness"] = bake(obj, folder, "metalness.png", "metalness")
    if name in DESK_PIECE_TOYS or name == "chalk-eraser":
        desk_piece_fill_maps(images)
        desk_piece_contact_sheet(folder, ["color.png", "normal.png", "roughness.png"], "maps-sheet.png")
    if name == "desk-hangar":
        card = next(mat for mat in obj.data.materials if mat.name == "Desk hangar warm ivory cardstock")
        number_nodes = [card.node_tree.nodes["Hangar number " + label] for label in ("roof",)]
        (folder / "color-1.png").write_bytes((folder / "color.png").read_bytes())
        first = bpy.data.images.load(str(folder / "color-1.png"), check_existing=False)
        first.use_fake_user = True
        first.pack()
        first.filepath = "//color-1.png"
        original = number_nodes[0].image
        for index in range(2, 13):
            painted_number = hangar_number_image(index)
            for node in number_nodes:
                node.image = painted_number
            alternate = bake(obj, folder, "color-" + str(index) + ".png", "color")
            alternate.use_fake_user = True
            alternate.pack()
            alternate.filepath = "//color-" + str(index) + ".png"
        # Side-desk hangars are free to use, so they carry no number (Alan, 2026-10-11).
        blank = bpy.data.images.new("Hangar no number", width=4, height=4, alpha=True)
        blank.pixels.foreach_set([0.0] * 64)
        for node in number_nodes:
            node.image = blank
        alternate = bake(obj, folder, "color-blank.png", "color")
        alternate.use_fake_user = True
        alternate.pack()
        alternate.filepath = "//color-blank.png"
        for node in number_nodes:
            node.image = original
    if name == "crop-row":
        paint_nodes = [next(mat for mat in obj.data.materials if mat.name.startswith(label))
                       .node_tree.nodes["Paint color"].outputs[0]
                       for label in ("Crop head paint", "Crop leaf paint")]
        originals = [paint.default_value[:] for paint in paint_nodes]
        (folder / "color-0.png").write_bytes((folder / "color.png").read_bytes())
        palettes = [((173, 205, 64), (191, 219, 86)), ((236, 121, 22), (245, 143, 29))]
        for index, colors in enumerate(palettes, 1):
            for paint, color in zip(paint_nodes, colors):
                paint.default_value = linear(color)
            alternate = bake(obj, folder, "color-" + str(index) + ".png", "color")
            alternate.use_fake_user = True
            alternate.pack()
            alternate.filepath = "//color-" + str(index) + ".png"
        for paint, original in zip(paint_nodes, originals):
            paint.default_value = original
    if name in ("stall", "house"):
        palette = ([(217, 44, 37), (40, 113, 192), (59, 145, 53),
                    (247, 195, 24), (238, 127, 30), (137, 65, 175)] if name == "stall" else
                   [(201, 44, 35), (42, 112, 181), (54, 138, 50)])
        painted = [mat for mat in obj.data.materials if mat.name.startswith("Variant paint")]
        assert len(painted) == 1, "Color variants need exactly one shared paint region"
        paint = painted[0].node_tree.nodes["Paint color"].outputs[0]
        original = paint.default_value[:]
        (folder / "color-0.png").write_bytes((folder / "color.png").read_bytes())
        for index, color in enumerate(palette[1:], 1):
            paint.default_value = linear(color)
            alternate = bake(obj, folder, "color-" + str(index) + ".png", "color")
            alternate.use_fake_user = True
            alternate.pack()
            alternate.filepath = "//color-" + str(index) + ".png"
        paint.default_value = original
    if name == "tree-lollipop":
        for mat in obj.data.materials:
            if mat.name.startswith("Canopy green"):
                mat.node_tree.nodes["Paint color"].outputs[0].default_value = linear((236, 129, 34))
        autumn = bake(obj, folder, "color-autumn.png", "color")
        autumn.use_fake_user = True
        autumn.pack()
        for mat in obj.data.materials:
            if mat.name.startswith("Canopy green"):
                mat.node_tree.nodes["Paint color"].outputs[0].default_value = linear((94, 153, 52))
    mat = baked_material(images)
    if name == "chalk-eraser":
        # Felt stays matte. The baked roughness supplies the oak's satin sheen.
        mat.node_tree.nodes["Principled BSDF"].inputs["Coat Weight"].default_value = 0
    if name == "paper-chain" or name in DESK_PIECE_TOYS:
        # Construction paper must not inherit the toy-plastic clear coat.
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Coat Weight"].default_value = 0
        bsdf.inputs["Specular IOR Level"].default_value = .18
    if name == "ruler-tape":
        mat.node_tree.nodes.get("Principled BSDF").inputs["Alpha"].default_value = .94
    obj = export_and_reload(obj, name, folder, mat)
    uv_checks(obj)
    render(obj, name, folder)
    comparison(folder)
    report = geometry_checks(obj, name, baked=True)
    obj["checks"] = json.dumps(report)
    obj["source_script"] = "tools/art/toys.py"
    for image in images.values():
        image.pack()
        image.filepath = "//" + Path(image.filepath).name
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / (name + ".blend")))
    file_checks(folder, name)
    if name in CLASSROOM_TOYS:
        (folder / "checks.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("PASS", json.dumps(report), flush=True)
    return report


def main():
    global PREVIEW, BAKE_RESOLUTION
    names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(SPECS)
    if names and names[0] == "--preview":
        PREVIEW = True
        BAKE_RESOLUTION = 512
        names = names[1:]
    if names and names[0] == "--verify":
        reports = []
        for name in names[1:] or list(SPECS):
            folder = OUTPUT / name
            bpy.ops.wm.open_mainfile(filepath=str(folder / (name + ".blend")))
            obj = next(o for o in bpy.context.scene.objects if o.type == "MESH")
            report = geometry_checks(obj, name, baked=True)
            uv_checks(obj)
            file_checks(folder, name)
            packed_maps = ["color.png", "normal.png", "roughness.png"]
            if name in METALNESS_TOYS:
                packed_maps.append("metalness.png")
            for image_name in packed_maps:
                assert any(image.packed_file and tuple(image.size) == (RESOLUTION, RESOLUTION)
                           for image in bpy.data.images if image.name == image_name), "Missing packed map"
            if name == "crop-row":
                for image_name in ("color-1.png", "color-2.png"):
                    assert any(image.packed_file and tuple(image.size) == (RESOLUTION, RESOLUTION)
                               for image in bpy.data.images if image.name == image_name), "Missing packed crop variant"
            if name == "desk-hangar":
                for index in range(1, 13):
                    image_name = "color-" + str(index) + ".png"
                    assert any(image.packed_file and tuple(image.size) == (RESOLUTION, RESOLUTION)
                               for image in bpy.data.images if image.name == image_name), "Missing packed hangar variant"
            bpy.ops.wm.read_factory_settings(use_empty=True)
            bpy.ops.import_scene.fbx(filepath=str(folder / (name + ".fbx")))
            obj = next(o for o in bpy.context.scene.objects if o.type == "MESH")
            if name in CLASSROOM_TOYS:
                # Use the same axis-transform application as export_and_reload.
                # Leaving the FBX import's rotation unapplied produces tiny
                # floating-point floor offsets on these much larger props.
                active(obj)
                bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            imported = geometry_checks(obj, name, baked=True)
            assert imported == report, ("Saved blend and FBX disagree", report, imported)
            uv_checks(obj)
            reports.append(report)
            print("VERIFIED", json.dumps(report), flush=True)
        print("ALL SAVED TOYS VERIFIED", json.dumps(reports), flush=True)
        return
    if names and names[0] == "--geometry-only":
        for name in names[1:]:
            PARTS.clear()
            MATERIALS.clear()
            bpy.ops.wm.read_factory_settings(use_empty=True)
            BUILDERS[name]()
            for part in PARTS:
                part.data.calc_loop_triangles()
            count = sum(len(part.data.loop_triangles) for part in PARTS)
            print("BUDGET", name, count, triangle_cap(name), flush=True)
            if name in DESK_PIECE_TOYS or name == "chalk-eraser":
                obj = assemble(name)
                report = geometry_checks(obj, name)
                uv_checks(obj)
                print("GEOMETRY", json.dumps(report), flush=True)
        return
    assert names and len(set(names)) == len(names), "Supply distinct toy names"
    assert all(name in SPECS for name in names), ("Unknown toy", names)
    reports, failures = [], []
    for name in names:
        try:
            reports.append(build(name))
        except Exception as error:
            traceback.print_exc()
            failures.append((name, str(error)))
    assert not failures, ("TOY BUILD FAILED", failures)
    if not PREVIEW and {"ruler-section", "ruler-tape"}.issubset(names):
        connected_city_joint_render()
        for filename in ("joint.png", "joint-underside.png"):
            assert png_read(OUTPUT / "ruler-section" / filename).shape[:2] == (800, 800), "Wrong ruler joint render"
    print("ALL TOYS PASSED", json.dumps(reports), flush=True)


if __name__ == "__main__":
    main()
