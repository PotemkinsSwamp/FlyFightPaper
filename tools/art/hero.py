"""Build independently textured Roblox pieces from a Meshy building.

Blender -b --factory-startup --python-exit-code 1 --python tools/art/hero.py --
    assets/models/sweet-shop --height 105
    --vertical-splits ground-floor:xy,upper-walls:y

The default split finds quiet floor boundaries and separates a tall roof
ornament. --cuts accepts explicit floor boundaries in studs when a different
building needs art direction. --front overrides the awning-based front guess.
All geometry remains in Blender axes, with a common base-centre origin.
"""

import argparse
import json
import math
import struct
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector

SIZE = 1024
BAKE_SIZE = 2048
LIMIT = 12000  # per piece; Roblox allows 20k. Some Meshy bands will not collapse below ~10.4k
TOTAL_LIMIT = 48000
SPLITS = {}  # band name -> pieces it is cut into later (from --vertical-splits)
DETAIL = [1.0]  # --detail: keep this many times more of Meshy's triangles (Alan's quality A/B, 2026-10-10)
PADDING = 4
DECALS = []  # touch-up boxes that only paint the bake
PACK_MARGIN = [.0027]  # widened per piece when concave packing leaves a gutter under 4 px
MIN_COVERAGE = .33  # old 4-piece shop used 20%; sharpness is checked by front_pixels_per_stud


def log(message):
    print("HERO " + message, flush=True)


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def coordinates(mesh):
    values = np.empty(len(mesh.vertices) * 3, dtype=np.float64)
    mesh.vertices.foreach_get("co", values)
    return values.reshape(-1, 3)


def triangles(mesh):
    mesh.calc_loop_triangles()
    values = np.empty(len(mesh.loop_triangles) * 3, dtype=np.int32)
    mesh.loop_triangles.foreach_get("vertices", values)
    return values.reshape(-1, 3)


def bounds(obj):
    co = coordinates(obj.data)
    return co.min(axis=0), co.max(axis=0)


def mesh_object(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def destroy(obj):
    mesh = obj.data
    bpy.data.objects.remove(obj, do_unlink=True)
    if mesh.users == 0:
        bpy.data.meshes.remove(mesh)


def automatic_front(obj):
    """An outward, sloping awning below the roof is a useful generic cue."""
    co = coordinates(obj.data)
    verts = co[triangles(obj.data)]
    normals = np.cross(verts[:, 1] - verts[:, 0], verts[:, 2] - verts[:, 0])
    area = np.linalg.norm(normals, axis=1)
    normals /= np.maximum(area[:, None], 1e-20)
    center = verts.mean(axis=1)
    lo, hi = co.min(0), co.max(0)
    span = hi[2] - lo[2]
    scores = {}
    for side, axis, sign in (("-y", 1, -1), ("+y", 1, 1), ("-x", 0, -1), ("+x", 0, 1)):
        wall = np.quantile((co[:, axis] - (lo[axis] + hi[axis]) / 2) * sign, .85)
        outward = (center[:, axis] - (lo[axis] + hi[axis]) / 2) * sign
        mask = ((outward > wall * .7) & (center[:, 2] > lo[2] + span * .15)
                & (center[:, 2] < lo[2] + span * .60)
                & (normals[:, 2] > .25) & (normals[:, 2] < .95)
                & (normals[:, axis] * sign > .2))
        scores[side] = float(area[mask].sum())
    ordered = sorted(scores, key=scores.get, reverse=True)
    assert scores[ordered[0]] > scores[ordered[1]] * 1.35, (
        "Front is ambiguous. Inspect the source and supply --front +x|-x|+y|-y", scores)
    log("front " + ordered[0] + "; awning scores " + json.dumps(scores))
    return ordered[0]


def import_source(folder, height, front):
    existing = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(folder / "meshy.glb"))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o not in existing]
    assert meshes, "meshy.glb contains no mesh"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    source = bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    source.name = "High source (baking only)"
    front = automatic_front(source) if front == "auto" else front
    source.rotation_euler.z = {"-y": 0, "+y": math.pi, "+x": -math.pi / 2, "-x": math.pi / 2}[front]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    lo, hi = bounds(source)
    scale = height / (hi[2] - lo[2])
    source.scale = (scale,) * 3
    source.location = (-scale * (lo[0] + hi[0]) / 2,
                       -scale * (lo[1] + hi[1]) / 2, -scale * lo[2])
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Use the local original maps, including normal and roughness, rather
    # than relying on whichever channels happened to be embedded in the GLB.
    maps = {}
    for channel, filename in (("color", "base_color"), ("normal", "normal"), ("roughness", "roughness")):
        image = bpy.data.images.load(str(folder / ("meshy-" + filename + ".png")), check_existing=True)
        assert tuple(image.size) == png_size(folder / ("meshy-" + filename + ".png")), "Original source map dimensions differ"
        image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
        maps[channel] = image
    source.data.uv_layers.active.name = "HeroUV"
    baked_material(source, maps)
    return source, front


def touch_up(source, folder):
    """FOLDER/touchup.json fixes Meshy's melted bits before anything is cut or baked (studs, Blender axes, front -Y):
    {"delete": [[x0, y0, z0, x1, y1, z1], ...], "boxes": [{"center": [x, y, z], "size": [w, d, h], "color": [r, g, b], "decal": false}]}
    A box may instead be {"shape": "lathe", "profile": [[r, z], ...] (z from "center", bottom to top)}, or
    {"shape": "cylinder" or "cone", "r": .., "r2": top radius, "h": .., "center": ..} (upright).
    Faces whose middle is inside a delete box go; each box becomes clean flat-coloured geometry that the bake picks up.
    Decal boxes (tick marks, small trim) stay out of the cut pieces and only paint the texture."""
    path = folder / "touchup.json"
    if not path.exists():
        return
    spec = json.loads(path.read_text())
    bm = bmesh.new()
    bm.from_mesh(source.data)
    # "center" (default): a face goes when its middle is inside (long faces of melted parts reach out of any box).
    # "all": only faces wholly inside go, for cuts that sit against a wall (center bites the wall and tears it).
    inside = lambda b, p: b[0] <= p.x <= b[3] and b[1] <= p.y <= b[4] and b[2] <= p.z <= b[5]
    whole = spec.get("delete_rule", "center") == "all"
    gone = [f for f in bm.faces for b in spec.get("delete", [])
            if (all(inside(b, v.co) for v in f.verts) if whole else inside(b, f.calc_center_median()))]
    bmesh.ops.delete(bm, geom=list(set(gone)), context="FACES")
    bm.to_mesh(source.data)
    bm.free()
    colors = {}
    for box in spec.get("boxes", []):
        key = tuple(box["color"])
        if key not in colors:
            mat = bpy.data.materials.new("Touch-up " + str(key))
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = [(c / 255) ** 2.2 for c in key] + [1]
            bsdf.inputs["Roughness"].default_value = box.get("roughness", .45)
            source.data.materials.append(mat)
            colors[key] = len(source.data.materials) - 1
        bm = bmesh.new()
        if box.get("shape") == "lathe":   # one closed turned solid from [[radius, height], ...] bottom to top
            ring = box.get("segments", 28)
            rows = [[bm.verts.new((box["center"][0] + r * math.cos(2 * math.pi * k / ring),
                                   box["center"][1] + r * math.sin(2 * math.pi * k / ring), box["center"][2] + z))
                     for k in range(ring)] for r, z in box["profile"]]
            for low, high in zip(rows, rows[1:]):
                for k in range(ring):
                    bm.faces.new((low[k], low[(k + 1) % ring], high[(k + 1) % ring], high[k]))
            bm.faces.new(list(reversed(rows[0])))
            bm.faces.new(rows[-1])
        elif box.get("shape") in ("cylinder", "cone"):   # upright, centred on "center"; cone narrows to "r2" at the top
            bmesh.ops.create_cone(bm, cap_ends=True, segments=box.get("segments", 24), radius1=box["r"],
                                  radius2=box.get("r2", box["r"]), depth=box["h"])
            for v in bm.verts:
                v.co += Vector(box["center"])
        else:
            bmesh.ops.create_cube(bm, size=1)
            for v in bm.verts:
                v.co = Vector([c + s * v.co[i] for i, (c, s) in enumerate(zip(box["center"], box["size"]))])
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))   # outward, or the bake sees the inside (black)
        for f in bm.faces:
            f.material_index = colors[key]
        start = len(source.data.polygons)
        temp = bpy.data.meshes.new("touch-up box")
        bm.to_mesh(temp)
        bm.free()
        piece = bpy.data.objects.new("touch-up box", temp)
        bpy.context.scene.collection.objects.link(piece)
        piece.data.materials.append(source.data.materials[colors[key]])
        if box.get("decal"):          # paint only: baked into the texture, never cut or simplified
            piece.name = "Touch-up decal (baking only)"
            piece.hide_render = True
            piece.hide_set(True)
            DECALS.append(piece)
            continue
        bpy.ops.object.select_all(action="DESELECT")
        piece.select_set(True)
        source.select_set(True)
        bpy.context.view_layer.objects.active = source
        bpy.ops.object.join()
        for f in source.data.polygons[start:]:
            f.material_index = colors[key]
    log(f"touch-up: removed {len(set(gone))} faces, added {len(spec.get('boxes', []))} clean boxes ({len(DECALS)} paint only)")


def quiet_cut(obj, lower, upper, prefer):
    co = coordinates(obj.data)
    v = co[triangles(obj.data)]
    cross = np.cross(v[:, 1] - v[:, 0], v[:, 2] - v[:, 0])
    area = np.linalg.norm(cross, axis=1)
    detail = np.abs(cross[:, 2]) > area * .15
    low, high = v[:, :, 2].min(1), v[:, :, 2].max(1)
    choices = np.linspace(lower, upper, 101)
    # Intersections with tilted trim, arches and awnings are expensive. Long,
    # flat vertical walls are cheap. A mild prior avoids accidental tiny gaps.
    scores = [float(area[(low < z) & (high > z) & detail].sum())
              + float(area.sum()) * .0002 * abs(z - prefer) / (upper - lower)
              for z in choices]
    return float(choices[int(np.argmin(scores))])


def bisect(obj, z, keep_above, name, height, axis=2):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    cap = (bm.faces.layers.int.get("hero_cap") or bm.faces.layers.int.new("hero_cap")) if axis != 2 else None
    plane_co, plane_no = [0, 0, 0], [0, 0, 0]
    plane_co[axis], plane_no[axis] = z, 1
    result = bmesh.ops.bisect_plane(
        bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        dist=height * 1e-7, plane_co=plane_co, plane_no=plane_no,
        clear_inner=keep_above, clear_outer=not keep_above)
    cut_edges = [e for e in bm.edges if e.is_boundary
                 and all(abs(v.co[axis] - z) < height * 1e-7 for v in e.verts)]
    if cut_edges:
        # A source hole intersecting the cut leaves an open cap outline. Close
        # it on the cut plane now, before hole repair can join it to a facade
        # rim and triangulate a large non-planar patch across windows.
        # Disconnected solids can share a cut plane without sharing a cap.
        # Preparing them together can bridge detached trim to the building.
        component = {v: i for i, group in enumerate(components(bm)) for v in group}
        networks = {}
        for edge in cut_edges:
            networks.setdefault(component[edge.verts[0]], []).append(edge)
        for edges in networks.values():
            cut_edges = list(set(cut_edges) | set(bmesh.ops.edgenet_prepare(bm, edges=edges)["edges"]))
        filled = (bmesh.ops.triangle_fill(bm, edges=cut_edges, use_beauty=True,
                                         use_dissolve=False, normal=Vector(plane_no)) if axis != 2
                  else bmesh.ops.holes_fill(bm, edges=cut_edges, sides=0))
        if cap:
            for face in filled.get("faces", [f for f in filled.get("geom", ()) if isinstance(f, bmesh.types.BMFace)]):
                face[cap] = 2
    if axis != 2:
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    if axis != 2:
        for face in bm.faces:
            if all(abs(v.co[axis] - z) < height * 1e-7 for v in face.verts):
                face[cap] = 2
        for edge in bm.edges:
            if len(edge.link_faces) == 2 and any(f[cap] == 2 for f in edge.link_faces):
                if edge.calc_face_angle() > math.radians(48):
                    edge.smooth = False
    result_obj = mesh_object(name, bm)
    bm.free()
    return result_obj


def split_vertical(objects, specification, height):
    """Cut the already simplified geometry so exterior shape does not change."""
    # Floor closures touch another band (or the ground), so they do not need
    # the same texel budget as storefronts. Mark without moving any vertices.
    for obj in objects:
        if obj.name not in ("ground-floor", "upper-walls", "roof", "topper"):
            continue
        lo, hi = bounds(obj)
        levels = [lo[2]] + ([hi[2]] if obj.name in ("ground-floor", "upper-walls") else [])
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        cap = bm.faces.layers.int.get("hero_cap") or bm.faces.layers.int.new("hero_cap")
        for face in bm.faces:
            if abs(face.normal.z) > .9 and any(all(abs(v.co.z - level) < height * .001 for v in face.verts) for level in levels):
                face[cap] = 1
        bm.to_mesh(obj.data)
        bm.free()
    plan = {}
    for entry in specification.split(",") if specification else []:
        label, axes = entry.split(":")
        assert axes and set(axes) <= {"x", "y"} and len(set(axes)) == len(axes), "Use label:x|y|xy"
        assert label not in plan, "Duplicate split label"
        plan[label] = axes
    assert set(plan) <= {o.name for o in objects}, "Unknown vertical split label"
    result = []
    for obj in objects:
        pieces = [obj]
        # Depth first keeps front/back names readable on a four-way split.
        for axis_name in sorted(plan.get(obj.name, ""), reverse=True):
            axis = "xyz".index(axis_name)
            next_pieces = []
            for piece in pieces:
                for positive, suffix in ((False, "front" if axis == 1 else "left"),
                                         (True, "back" if axis == 1 else "right")):
                    child = bisect(piece, 0, positive, piece.name + "-" + suffix, height, axis)
                    assert len(child.data.polygons), "Vertical cut made an empty piece"
                    next_pieces.append(child)
                destroy(piece)
            pieces = next_pieces
        result.extend(pieces)
    return result


def preserved_geometry(path, height, front):
    """An approved low-poly asset can be rebaked without rerunning decimation."""
    with bpy.data.libraries.load(str(path), link=False) as (available, loaded):
        loaded.objects = ["ground-floor", "upper-walls", "roof", "topper"]
        assert set(loaded.objects) <= set(available.objects), "Geometry asset must contain the four approved bands"
    objects = loaded.objects
    for obj in objects:
        bpy.context.scene.collection.objects.link(obj)
    base = objects[0]
    assert abs(base["hero_height"] - height) < 1e-6, "Geometry asset height differs"
    assert base["hero_front"] == front, "Geometry asset front differs"
    assembly_checks(objects, height)
    return objects, list(base["hero_floor_cuts"]), float(base["hero_topper_base"])


def components(bm):
    remaining = set(bm.verts)
    result = []
    while remaining:
        first = remaining.pop()
        group, stack = {first}, [first]
        while stack:
            current = stack.pop()
            for edge in current.link_edges:
                other = edge.other_vert(current)
                if other in remaining:
                    remaining.remove(other)
                    group.add(other)
                    stack.append(other)
        result.append(group)
    return result


def separate_topper(roof, roof_level, height):
    """Separate the tallest connected ornament above the roof parapet."""
    level = roof_level + height * .028
    above = bisect(roof, level, True, "Roof ornaments", height)
    bm = bmesh.new()
    bm.from_mesh(above.data)
    groups = components(bm)
    tall = [g for g in groups if max(v.co.z for v in g) > height * .88]
    if not tall:
        bm.free()
        destroy(above)
        return None
    keep = set().union(*tall)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v not in keep], context="VERTS")
    topper = mesh_object("topper", bm)
    bm.free()
    # Complement: the lower roof and every ornament not selected as the topper.
    bm = bmesh.new()
    bm.from_mesh(above.data)
    groups = components(bm)
    drop = set().union(*(g for g in groups if max(v.co.z for v in g) > height * .88))
    bmesh.ops.delete(bm, geom=list(drop), context="VERTS")
    other = mesh_object("Other roof ornaments", bm)
    bm.free()
    lower = bisect(roof, level, False, "roof", height)
    destroy(roof)
    destroy(above)
    active(lower)
    other.select_set(True)
    bpy.ops.object.join()
    return lower, topper, level


def split_source(source, count, height, explicit_cuts):
    work = source.copy()
    work.data = source.data.copy()
    bpy.context.scene.collection.objects.link(work)
    # Meshy separates vertices at UV seams. Weld only the working geometry;
    # leave the original material, UVs and shading untouched for projection.
    bm = bmesh.new()
    bm.from_mesh(work.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=height * .00001)
    bm.to_mesh(work.data)
    bm.free()
    if explicit_cuts:
        cuts = explicit_cuts
    elif count == 4:
        cuts = [quiet_cut(work, height * .38, height * .415, height * .40),
                quiet_cut(work, height * .607, height * .626, height * .62)]
    else:
        cuts = [quiet_cut(work, height * (k / count - .055), height * (k / count + .055),
                          height * k / count) for k in range(1, count)]
    assert all(0 < z < height for z in cuts) and cuts == sorted(set(cuts)), "Invalid --cuts"
    result = []
    for k, z in enumerate(cuts):
        piece = bisect(work, z, False, "band-" + str(k + 1), height)
        upper = bisect(work, z, True, "Unsplit upper", height)
        destroy(work)
        work = upper
        result.append(piece)
    result.append(work)
    topper_level = None
    if not explicit_cuts and count == 4:
        separated = separate_topper(result[-1], cuts[-1], height)
        if separated:
            result[-1], topper, topper_level = separated
            result.append(topper)
            labels = ["ground-floor", "upper-walls", "roof", "topper"]
        else:
            cut = quiet_cut(result[-1], height * .73, height * .85, height * .78)
            lower = bisect(result[-1], cut, False, "roof", height)
            upper = bisect(result[-1], cut, True, "upper-roof", height)
            destroy(result[-1])
            result[-1] = lower
            result.append(upper)
            cuts.append(cut)
            labels = ["ground-floor", "upper-walls", "roof", "upper-roof"]
    else:
        assert len(result) == count, "--cuts must contain --parts minus one boundaries"
        labels = ["band-" + str(k + 1) for k in range(count)]
    for obj, label in zip(result, labels):
        obj.name = label
        assert len(obj.data.polygons), "Empty piece: " + label
    log("floor cuts " + json.dumps(cuts) + "; topper base " + str(topper_level))
    return result, cuts, topper_level


def simplify(obj, height):
    active(obj)
    original_count = len(triangles(obj.data))
    # Dense sculpt triangulation is not useful detail on a flat facade. A
    # smaller target also leaves fewer UV seams competing for the 1024 atlas.
    target = min(8500, max(2500, round(math.sqrt(original_count) * 11)))  # later clean-up adds up to ~15%
    target = round(target * DETAIL[0])
    if obj.name.startswith("ground-floor"):
        # Steps, bushes and doors are what a plane sees up close; flattened, their colours smear onto flat walls.
        target = min(17000 * DETAIL[0], target * 2)
    modifier = obj.modifiers.new("Preserve silhouette", "DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = min(1.0, target / original_count)
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=height * 1e-7)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=height * 1e-8)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    # Broad nearly axial surfaces should stay flat. Only move vertices already
    # within 0.15% of the building height from a connected plane patch.
    for axis in range(3):
        candidates = {f for f in bm.faces if abs(f.normal[axis]) > .995}
        while candidates:
            first = candidates.pop()
            patch, stack = {first}, [first]
            while stack:
                face = stack.pop()
                for edge in face.edges:
                    for other in edge.link_faces:
                        if other in candidates and other.normal.dot(first.normal) > .998:
                            candidates.remove(other)
                            patch.add(other)
                            stack.append(other)
            if sum(f.calc_area() for f in patch) < height * height * .009:
                continue
            verts = set(v for f in patch for v in f.verts)
            values = np.array([v.co[axis] for v in verts])
            plane = float(np.median(values))
            if np.max(np.abs(values - plane)) < height * .0015:
                for vertex in verts:
                    vertex.co[axis] = plane
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    # Split shading only on actual corners, not on every triangulation edge.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for face in bm.faces:
        face.smooth = True
    for edge in bm.edges:
        edge.smooth = len(edge.link_faces) == 2 and edge.calc_face_angle() < math.radians(48)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.verts.index_update()
    seen, duplicates = set(), []
    for face in bm.faces:
        key = tuple(sorted(v.index for v in face.verts))
        if key in seen:
            duplicates.append(face)
        else:
            seen.add(key)
    if duplicates:
        bmesh.ops.delete(bm, geom=duplicates, context="FACES_ONLY")
    debris = set()
    for group in components(bm):
        faces = set(f for v in group for f in v.link_faces)
        low = np.min([v.co[:] for v in group], axis=0)
        high = np.max([v.co[:] for v in group], axis=0)
        if np.max(high - low) < height * .005 and sum(f.calc_area() for f in faces) < height ** 2 * 1e-5:
            debris.update(group)
    if debris:
        bmesh.ops.delete(bm, geom=list(debris), context="VERTS")
        log(obj.name + ": removed tiny disconnected decimation debris")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    # Last step, after every re-triangulation, so the piece really ends under the limit.
    # The per-piece limit applies after the vertical cuts, so a band may hold that many times more (with slack
    # for uneven cuts); capping the whole band at one piece's limit crushed and tore ground floors.
    cap = LIMIT if SPLITS.get(obj.name, 1) == 1 else round(LIMIT * SPLITS[obj.name] * .6)
    for attempt in range(4):
        if len(obj.data.polygons) <= cap:
            break
        before = len(obj.data.polygons)
        modifier = obj.modifiers.new("Final triangle limit", "DECIMATE")
        modifier.ratio = cap * .95 / before
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        log(obj.name + ": triangle limit " + str(before) + " -> " + str(len(obj.data.polygons)))
    log(obj.name + ": " + str(original_count) + " -> " + str(len(obj.data.polygons)) + " triangles")


def drop_duplicate_faces(obj):
    """Decimation can leave two faces on the same vertices; keep one (before UVs, so nothing baked changes)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    seen, extra = set(), []
    for f in bm.faces:
        key = tuple(sorted(v.index for v in f.verts))
        (extra.append(f) if key in seen else seen.add(key))
    if extra:
        bmesh.ops.delete(bm, geom=extra, context="FACES")   # also clears edges/points left with no face
        bm.to_mesh(obj.data)
        log(obj.name + ": dropped " + str(len(extra)) + " duplicate faces")
    loose = [e for e in bm.edges if not e.link_faces] + [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS" if not any(isinstance(g, bmesh.types.BMEdge) for g in loose) else "EDGES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(obj.data)
        log(obj.name + ": dropped " + str(len(loose)) + " loose edges/points")
    bm.free()


def close_holes(obj):
    """Some Meshy models arrive with small holes and some cut caps do not close; patch them so pieces stay closed."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    if any(e.is_boundary for e in bm.edges):
        # Hairline cracks: two edges a hair apart. Weld them first; fill what is left.
        size = max(obj.dimensions)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=size * 2e-4)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_area() < size ** 2 * 1e-12], context="FACES")
        # Welding can stack faces. Remove them before filling, otherwise the
        # final duplicate cleanup reopens edges that were just patched.
        bm.verts.index_update()
        seen, extra = set(), []
        for face in bm.faces:
            key = tuple(sorted(v.index for v in face.verts))
            if key in seen:
                extra.append(face)
            else:
                seen.add(key)
        if extra:
            bmesh.ops.delete(bm, geom=extra, context="FACES_ONLY")
    holes = [e for e in bm.edges if e.is_boundary]
    if holes:
        filled = bmesh.ops.holes_fill(bm, edges=holes, sides=0)["faces"]
        bmesh.ops.triangulate(bm, faces=filled)
        # holes_fill can skip a closed, non-planar rim. Triangulate each such
        # loop directly; never cap an open chain or join unrelated holes.
        remaining = {e for e in bm.edges if e.is_boundary}
        while remaining:
            first = remaining.pop()
            group, stack = {first}, [first]
            while stack:
                edge = stack.pop()
                for vertex in edge.verts:
                    for other in vertex.link_edges:
                        if other in remaining:
                            remaining.remove(other)
                            group.add(other)
                            stack.append(other)
            verts = {v for e in group for v in e.verts}
            if all(sum(e in group for e in v.link_edges) == 2 for v in verts):
                bmesh.ops.triangle_fill(bm, edges=list(group), use_beauty=True,
                                        use_dissolve=False)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data)
        obj.data.update()
        log(obj.name + ": filled holes along " + str(len(holes)) + " open edges, "
            + str(sum(e.is_boundary for e in bm.edges)) + " still open")
    bm.to_mesh(obj.data)
    obj.data.update()
    bm.free()


def pack_uvs(obj):
    pack_margin = PACK_MARGIN[0]
    # FRACTION is a fixed atlas fraction on each side, not relative to an
    # island's size. The independent raster check proves a four-pixel gutter.
    for margin in (pack_margin,):
        log(obj.name + ": packing charts")
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.select_all(action="SELECT")
        packed = bpy.ops.uv.pack_islands("EXEC_DEFAULT", udim_source="ACTIVE_UDIM", rotate=True,
                                         rotate_method="ANY",
                                         margin_method="FRACTION", margin=margin,
                                         shape_method="CONCAVE", merge_overlap=False)
        assert packed == {"FINISHED"}, "UV packing did not finish"
        bpy.ops.object.mode_set(mode="OBJECT")
        log(obj.name + ": packing finished")
        values = np.empty(len(obj.data.loops) * 2, dtype=np.float32)
        obj.data.uv_layers.active.data.foreach_get("uv", values)
        if values.min() >= -1e-5 and values.max() <= 1.00001:
            values = values.reshape(-1, 2) * (1 - 2 * PADDING / SIZE) + PADDING / SIZE
            obj.data.uv_layers.active.data.foreach_set("uv", values.ravel())
            return
    raise AssertionError("Too many UV islands to pack with a four-pixel gutter")


def project_charts(obj, angle_limit=80):
    """Project without non-linear UV warping; reserve pixels for the facade."""
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle_limit), island_margin=0,
                             margin_method="FRACTION", area_weight=.25,
                             correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.average_islands_scale(scale_uv=False, shear=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    if "hero_cap" in obj.data.attributes:
        cap = np.empty(len(obj.data.polygons), dtype=np.int32)
        obj.data.attributes["hero_cap"].data.foreach_get("value", cap)
        uv = np.empty(len(obj.data.loops) * 2, dtype=np.float32)
        obj.data.uv_layers.active.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 3, 2)
        uv[cap > 0] = uv[cap > 0] * .5 + (.137, .273)
        obj.data.uv_layers.active.data.foreach_set("uv", uv.ravel())
    merge_uv_islands(obj)


def merge_uv_islands(obj):
    """Stitch neighboring small charts with rigid transforms, never a UV warp."""
    mesh = obj.data
    uv = np.empty(len(mesh.loops) * 2, dtype=np.float64)
    mesh.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 3, 2)
    tri = triangles(mesh)
    cap = np.zeros(len(tri), dtype=np.int32)
    if "hero_cap" in mesh.attributes:
        mesh.attributes["hero_cap"].data.foreach_get("value", cap)
    parent = list(range(len(tri)))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    adjacent, edges = [], {}
    for i, face in enumerate(tri):
        for a, b in zip(face, np.roll(face, -1)):
            key = tuple(sorted((int(a), int(b))))
            if key in edges:
                j = edges[key]
                va = [int(np.flatnonzero(face == v)[0]) for v in key]
                vb = [int(np.flatnonzero(tri[j] == v)[0]) for v in key]
                if np.max(np.abs(uv[i, va] - uv[j, vb])) < 1e-7:
                    parent[root(i)] = root(j)
                elif not cap[i] and not cap[j]:
                    adjacent.append((i, j, va, vb))
            else:
                edges[key] = i
    groups = {}
    for i in range(len(tri)):
        groups.setdefault(root(i), set()).add(i)
    normals = np.array([f.normal[:] for f in mesh.polygons])
    merged = 0

    def intersects(a, b):
        lo_a, hi_a, lo_b, hi_b = a.min(1), a.max(1), b.min(1), b.max(1)
        pairs = np.argwhere(np.all(np.minimum(hi_a[:, None], hi_b[None])
                                   - np.maximum(lo_a[:, None], lo_b[None]) > 1e-10, axis=2))
        if not len(pairs):
            return False
        a, b = a[pairs[:, 0]], b[pairs[:, 1]]
        edge = np.concatenate((np.roll(a, -1, axis=1) - a, np.roll(b, -1, axis=1) - b), axis=1)
        axes = np.stack((-edge[:, :, 1], edge[:, :, 0]), axis=2)
        axes /= np.maximum(np.linalg.norm(axes, axis=2, keepdims=True), 1e-20)
        pa, pb = np.einsum("nvd,ned->nev", a, axes), np.einsum("nvd,ned->nev", b, axes)
        return np.any(np.all(np.minimum(pa.max(2), pb.max(2)) - np.maximum(pa.min(2), pb.min(2)) > 1e-9, axis=1))

    for _ in range(4):
        changed = False
        for i, j, va, vb in adjacent:
            ri, rj = root(i), root(j)
            if ri == rj or normals[i].dot(normals[j]) < .5:
                continue
            if len(groups[ri]) < len(groups[rj]):
                i, j, va, vb, ri, rj = j, i, vb, va, rj, ri
            fixed, moving = sorted(groups[ri]), sorted(groups[rj])
            if len(moving) > 100 or len(fixed) + len(moving) > 1200:
                continue
            a, b = uv[i, va], uv[j, vb]
            da, db = a[1] - a[0], b[1] - b[0]
            la, lb = np.linalg.norm(da), np.linalg.norm(db)
            if min(la, lb) < 1e-8 or not .8 < la / lb < 1.25:
                continue
            da, db = da / la, db / lb
            basis_a = np.array((da, (-da[1], da[0]))).T
            basis_b = np.array((db, (-db[1], db[0]))).T
            side_a = np.linalg.det(np.stack((da, uv[i, 3 - sum(va)] - a[0])))
            side_b = np.linalg.det(np.stack((db, uv[j, 3 - sum(vb)] - b[0])))
            reflect = -1 if side_a * side_b > 0 else 1
            matrix = la / lb * basis_a @ np.diag((1, reflect)) @ basis_b.T
            candidate = (uv[moving] - b[0]) @ matrix.T + a[0]
            before_area = np.prod(np.ptp(uv[fixed], axis=(0, 1))) + np.prod(np.ptp(candidate, axis=(0, 1)))
            combined = np.concatenate((uv[fixed], candidate))
            if np.prod(np.ptp(combined, axis=(0, 1))) > before_area * 1.25 or intersects(candidate, uv[fixed]):
                continue
            uv[moving] = candidate
            parent[rj] = ri
            groups[ri].update(groups.pop(rj))
            merged += 1
            changed = True
        if not changed:
            break
    mesh.uv_layers.active.data.foreach_set("uv", uv.ravel())
    log(obj.name + ": rigidly stitched " + str(merged) + " UV islands")


def unwrap(obj, angle_limit=80):
    active(obj)
    while obj.data.uv_layers:
        obj.data.uv_layers.remove(obj.data.uv_layers[0])
    obj.data.uv_layers.new(name="HeroUV")
    project_charts(obj, angle_limit)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pin(clear=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    pack_uvs(obj)
    # Float storage can collapse the smallest triangles on curved boundaries.
    # Repair only those slivers/folds, then repack with the same fixed gutter.
    for attempt in range(6):
        overlaps = overlapping_uv_faces(obj.data)
        values = np.empty(len(obj.data.loops) * 2, dtype=np.float32)
        obj.data.uv_layers.active.data.foreach_get("uv", values)
        values = values.reshape(-1, 3, 2)
        a, b = values[:, 1] - values[:, 0], values[:, 2] - values[:, 0]
        signed = a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]
        thin = np.flatnonzero(np.abs(signed) < 1e-11)
        if not len(overlaps) and not len(thin):
            return
        detach = np.unique(np.concatenate((overlaps[:, 1], thin)))
        log(obj.name + ": repairing " + str(len(overlaps)) + " folds and " + str(len(thin)) + " UV slivers")
        for order, index in enumerate(detach):
            # Matching edge coordinates define islands. A small unique offset
            # disconnects a face without losing float precision on thin trim.
            if index in thin:
                values[index] = np.array(((0, 0), (.003, 0), (.0015, .0026)))
            values[index] += (.02 + order * .000031, .017 + order * .000073)
        obj.data.uv_layers.active.data.foreach_set("uv", values.ravel())
        pack_uvs(obj)
        log(obj.name + ": repaired " + str(len(detach)) + " UV faces")
    assert not len(overlapping_uv_faces(obj.data)), "UV fold repair did not converge"


def overlapping_uv_faces(mesh):
    """Use separating axes to find positive-area triangle intersections."""
    uv = mesh.uv_layers.active.data
    values = np.empty(len(mesh.loops) * 2, dtype=np.float64)
    uv.foreach_get("uv", values)
    values = values.reshape(-1, 2)
    faces = values.reshape(-1, 3, 2)
    lo, hi = faces.min(1), faces.max(1)
    buckets = {}
    pairs = set()
    for i in range(len(faces)):
        lower = np.floor(lo[i] * 64).astype(int).clip(0, 63)
        upper = np.floor(hi[i] * 64).astype(int).clip(0, 63)
        seen = set()
        for y in range(lower[1], upper[1] + 1):
            for x in range(lower[0], upper[0] + 1):
                bucket = buckets.setdefault((x, y), [])
                seen.update(bucket)
                bucket.append(i)
        for j in seen:
            if np.all(np.minimum(hi[i], hi[j]) - np.maximum(lo[i], lo[j]) > 1e-10):
                pairs.add((j, i))
    candidates = list(pairs)
    result = []
    for start in range(0, len(candidates), 20000):
        ids = np.array(candidates[start:start + 20000])
        a, b = faces[ids[:, 0]], faces[ids[:, 1]]
        edges = np.concatenate((np.roll(a, -1, axis=1) - a,
                                np.roll(b, -1, axis=1) - b), axis=1)
        axes = np.stack((-edges[:, :, 1], edges[:, :, 0]), axis=2)
        axes /= np.maximum(np.linalg.norm(axes, axis=2, keepdims=True), 1e-20)
        pa, pb = np.einsum("nvd,ned->nev", a, axes), np.einsum("nvd,ned->nev", b, axes)
        overlap = np.minimum(pa.max(2), pb.max(2)) - np.maximum(pa.min(2), pb.min(2))
        bad = np.all(overlap > 1e-9, axis=1)
        result.extend(ids[bad].tolist())
    return np.array(result, dtype=np.int32).reshape(-1, 2)


def assert_uvs(obj):
    """Exact triangle intersection test plus a four-pixel island gutter test."""
    mesh = obj.data
    values = np.empty(len(mesh.loops) * 2, dtype=np.float64)
    mesh.uv_layers.active.data.foreach_get("uv", values)
    values = values.reshape(-1, 2)
    assert np.isfinite(values).all() and values.min() >= 0 and values.max() <= 1, (
        "UV outside atlas", float(values.min()), float(values.max()), int(np.count_nonzero(~np.isfinite(values))))
    faces = values.reshape(-1, 3, 2)
    a, b = faces[:, 1] - faces[:, 0], faces[:, 2] - faces[:, 0]
    signed = a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]
    assert (np.abs(signed) > 1e-14).all(), "Degenerate UV triangle"
    # A packed atlas can look full while its texture is smeared: reject any
    # chart that stretches the texture over 3x in one direction.
    p = coordinates(mesh)[triangles(mesh)]
    e1, e2 = p[:, 1] - p[:, 0], p[:, 2] - p[:, 0]
    n = np.cross(e1, e2)
    area = np.linalg.norm(n, axis=1) / 2
    ok = area > 1e-9
    x = e1[ok] / np.linalg.norm(e1[ok], axis=1, keepdims=True)
    y = np.cross(n[ok], x)
    y /= np.linalg.norm(y, axis=1, keepdims=True)
    flat = np.stack((np.stack((np.einsum("ij,ij->i", e1[ok], x), np.einsum("ij,ij->i", e2[ok], x)), 1),
                     np.stack((np.einsum("ij,ij->i", e1[ok], y), np.einsum("ij,ij->i", e2[ok], y)), 1)), 1)
    s = np.linalg.svd(np.stack((a[ok], b[ok]), 2) @ np.linalg.inv(flat), compute_uv=False)
    stretched = float(area[ok][s[:, 0] > 3 * s[:, 1]].sum() / area[ok].sum())
    assert stretched < .03, ("UV stretch over 3x on", round(stretched * 100, 1), "% of the surface")
    overlaps = overlapping_uv_faces(mesh)
    assert not len(overlaps), (obj.name, "Overlapping UV triangles", overlaps[:5].tolist())
    parent = list(range(len(faces)))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    edges = {}
    for face in mesh.polygons:
        loops = list(face.loop_indices)
        for a, b in zip(loops, loops[1:] + loops[:1]):
            va, vb = mesh.loops[a].vertex_index, mesh.loops[b].vertex_index
            ua, ub = tuple(np.round(values[a], 7)), tuple(np.round(values[b], 7))
            key = (va, vb, ua, ub) if va < vb else (vb, va, ub, ua)
            if key in edges:
                parent[root(face.index)] = root(edges[key])
            else:
                edges[key] = face.index
    coverage = np.zeros((SIZE, SIZE), dtype=np.int32)
    labels = {}
    for i, triangle in enumerate(faces * SIZE):
        label = labels.setdefault(root(i), len(labels) + 1)
        low = np.floor(triangle.min(0)).astype(int).clip(0, SIZE)
        high = np.ceil(triangle.max(0)).astype(int).clip(0, SIZE)
        if np.any(high <= low):
            continue
        x, y = np.meshgrid(np.arange(low[0], high[0]) + .5, np.arange(low[1], high[1]) + .5)
        signs = [(triangle[(k + 1) % 3, 0] - triangle[k, 0]) * (y - triangle[k, 1])
                 - (triangle[(k + 1) % 3, 1] - triangle[k, 1]) * (x - triangle[k, 0]) for k in range(3)]
        inside = np.logical_or(np.logical_and.reduce([s > 1e-7 for s in signs]),
                               np.logical_and.reduce([s < -1e-7 for s in signs]))
        tile = coverage[low[1]:high[1], low[0]:high[0]]
        assert not np.any(tile[inside]), "Raster UV overlap"
        tile[inside] = label
    grown = coverage.copy()
    for step in range(PADDING // 2):
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
            assert not np.any((update != 0) & (shifted != 0) & (update != shifted)), "UV padding below 4 pixels"
            update[(update == 0) & (shifted != 0)] = shifted[(update == 0) & (shifted != 0)]
        grown = update
    report = {"uv_islands": len(labels), "uv_coverage": round(np.count_nonzero(coverage) / SIZE ** 2, 4),
              "uv_overlap": False, "uv_padding_pixels": PADDING}
    log(obj.name + " UV " + json.dumps(report))
    return report


def cycles_setup():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    prefs = bpy.context.preferences.addons["cycles"].preferences
    try:
        prefs.compute_device_type = "CUDA"
        prefs.get_devices()
        gpu = any(d.type == "CUDA" for d in prefs.devices)
        for device in prefs.devices:
            device.use = device.type == "CUDA"
        scene.cycles.device = "GPU" if gpu else "CPU"
    except (TypeError, RuntimeError):
        scene.cycles.device = "CPU"
    scene.render.bake.use_selected_to_active = True
    scene.render.bake.margin = 12
    scene.render.bake.margin_type = "EXTEND"
    scene.render.bake.normal_space = "TANGENT"
    scene.render.bake.normal_r = "POS_X"
    scene.render.bake.normal_g = "POS_Y"
    scene.render.bake.normal_b = "POS_Z"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_depth = "8"


def baked_material(obj, maps):
    mat = bpy.data.materials.new(obj.name + " baked")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Metallic"].default_value = 0
    bsdf.inputs["Specular IOR Level"].default_value = .25
    for channel, image in maps.items():
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.name = channel
        if channel == "color":
            links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        elif channel == "roughness":
            links.new(tex.outputs["Color"], bsdf.inputs["Roughness"])
        else:
            normal = nodes.new("ShaderNodeNormalMap")
            normal.uv_map = "HeroUV"
            links.new(tex.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.material_index = 0
    return mat


def bake(source, obj, folder, prefix, height):
    mat = bpy.data.materials.new(obj.name + " bake target")
    mat.use_nodes = True
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.material_index = 0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    mat.node_tree.nodes.active = tex
    maps = {}
    for channel, kind in (("color", "DIFFUSE"), ("normal", "NORMAL"), ("roughness", "ROUGHNESS")):
        image = bpy.data.images.new(prefix + "-" + channel, width=BAKE_SIZE, height=BAKE_SIZE, alpha=False)
        image.colorspace_settings.name = "sRGB" if channel == "color" else "Non-Color"
        image.generated_color = (.5, .5, 1, 1) if channel == "normal" else (.5, .5, .5, 1)
        tex.image = image
        active(obj)
        source.hide_set(False)
        source.hide_render = False
        source.select_set(True)
        for decal in DECALS:
            decal.hide_set(False)
            decal.hide_render = False
            decal.select_set(True)
        log("baking " + prefix + " " + channel)
        bpy.ops.object.bake(type=kind, pass_filter={"COLOR"} if kind == "DIFFUSE" else set(),
                            use_selected_to_active=True, use_cage=True,
                            cage_extrusion=height * .004, max_ray_distance=height * .008,
                            margin=12, margin_type="EXTEND")
        pixels = np.empty(BAKE_SIZE * BAKE_SIZE * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape(BAKE_SIZE, BAKE_SIZE, 4).reshape(SIZE, 2, SIZE, 2, 4).mean(axis=(1, 3))
        if channel == "normal":
            normals = pixels[:, :, :3] * 2 - 1
            normals /= np.maximum(np.linalg.norm(normals, axis=2, keepdims=True), 1e-8)
            pixels[:, :, :3] = normals * .5 + .5
        image.scale(SIZE, SIZE)
        image.pixels.foreach_set(pixels.ravel())
        image.filepath_raw = str(folder / (prefix + "-" + channel + ".png"))
        image.file_format = "PNG"
        image.save()
        image.pack()
        maps[channel] = image
    baked_material(obj, maps)
    source.hide_render = True
    source.hide_set(True)
    for decal in DECALS:
        decal.hide_render = True
        decal.hide_set(True)
    bpy.data.materials.remove(mat)
    return maps


def geometry_checks(obj):
    assert obj.type == "MESH" and len(obj.data.polygons), "Empty/non-mesh piece"
    assert len(obj.data.materials) == 1 and all(p.material_index == 0 for p in obj.data.polygons), "Expected one material"
    assert len(obj.data.uv_layers) == 1, "Expected one UV map"
    assert all(len(p.vertices) == 3 for p in obj.data.polygons), "Mesh is not triangulated"
    assert len(obj.data.polygons) <= LIMIT, "Piece exceeds the triangle limit"
    tri = triangles(obj.data)
    assert len(np.unique(np.sort(tri, axis=1), axis=0)) == len(tri), "Duplicate triangles"
    assert obj.location.length < 1e-5 and all(abs(v - 1) < 1e-5 for v in obj.scale), "Origin/scale changed"
    assert all(abs(v) < 1e-5 for v in obj.rotation_euler), "Unapplied rotation"
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(v.link_faces for v in bm.verts), "Loose vertices"
    assert all(e.link_faces for e in bm.edges), "Loose edges"
    boundary, edges = sum(e.is_boundary for e in bm.edges), len(bm.edges)
    bm.free()
    # ponytail: a few open edges are tangles in Meshy's surface that hole filling cannot close; Roblox draws and
    # collides with them fine, so allow up to 1% and record the count.
    assert boundary <= edges * .01, (obj.name, "Too many open edges", boundary)
    low, high = bounds(obj)
    return {"label": obj.name, "triangles": len(obj.data.polygons),
            "bounding_box": {"min": low.round(5).tolist(), "max": high.round(5).tolist()},
            "boundary_edges": boundary, "origin": [0, 0, 0]}


def export_piece(obj, folder, prefix):
    active(obj)
    path = folder / (prefix + ".fbx")
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={"MESH"},
                             apply_unit_scale=False, global_scale=1, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=False, mesh_smooth_type="OFF", path_mode="AUTO",
                             embed_textures=False, add_leaf_bones=False)
    old = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
    imported = [o for o in bpy.data.objects if o not in old]
    meshes = [o for o in imported if o.type == "MESH"]
    assert len(meshes) == 1, "FBX does not contain exactly one mesh"
    copy = meshes[0]
    assert len(copy.data.materials) == len(copy.data.uv_layers) == 1, "FBX material/UV count changed"
    assert len(copy.data.polygons) == len(obj.data.polygons), (
        "FBX triangle count changed", len(obj.data.polygons), len(copy.data.polygons))
    assert copy.location.length < .001, "FBX origin changed"
    active(copy)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for actual, expected in zip(bounds(copy), bounds(obj)):
        assert np.max(np.abs(actual - expected)) < .01, "FBX bounding box changed"
    for other in imported:
        if other.type == "MESH":
            destroy(other)
        else:
            bpy.data.objects.remove(other, do_unlink=True)


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def front_density(obj, side=None):
    """Area-equivalent texels/stud on outward front/back surfaces, not cut caps.

    The front is Blender -Y. Back-only children are measured on +Y and named
    explicitly, rather than counting their invisible internal cut as a facade.
    """
    mesh = obj.data
    verts = coordinates(mesh)[triangles(mesh)]
    cross = np.cross(verts[:, 1] - verts[:, 0], verts[:, 2] - verts[:, 0])
    areas = np.linalg.norm(cross, axis=1) / 2
    sign = 1 if (side == "back" or (side is None and "-back" in obj.name)) else -1
    # Use the original assembly centre, not each child's box centre.
    mask = (cross[:, 1] * sign > areas * 2 * .5) & (verts.mean(1)[:, 1] * sign > 1e-5)
    if "hero_cap" in mesh.attributes:
        cap = np.empty(len(mesh.polygons), dtype=np.int32)
        mesh.attributes["hero_cap"].data.foreach_get("value", cap)
        mask &= cap == 0
    uv = np.empty(len(mesh.loops) * 2, dtype=np.float64)
    mesh.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 3, 2)
    a, b = uv[:, 1] - uv[:, 0], uv[:, 2] - uv[:, 0]
    texel_area = np.abs(a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]) / 2 * SIZE ** 2
    surface = float(areas[mask].sum())
    return {"density_face": "back" if sign == 1 else "front",
            "front_surface_studs2": round(surface, 4),
            "front_pixels_per_stud": round(math.sqrt(float(texel_area[mask].sum()) / surface), 3) if surface else None}


def render_closeup(objects, path, height):
    """The same camera and lights for old and new 1024 atlases."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0
    camera = scene.camera
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = height * .90
    camera.data.clip_end = height * 20
    target = Vector((0, -height * .21, height * .20))
    camera.location = target + Vector((.12, -3, .10)) * height
    point_at(camera, target)
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def capture_before(folder):
    """Read old packed maps before a rebuild; never rebake the baseline."""
    renders = folder / "renders"
    renders.mkdir(exist_ok=True)
    old = json.loads((folder / "parts.json").read_text(encoding="utf-8"))
    bpy.ops.wm.open_mainfile(filepath=str(folder / "hero.blend"))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for piece in old["pieces"]:
        obj = bpy.data.objects[piece["label"]]
        piece.update(front_density(obj))
        piece["back_pixels_per_stud"] = front_density(obj, "back")["front_pixels_per_stud"]
    (renders / "parts-before.json").write_text(json.dumps(old, indent=2) + "\n", encoding="utf-8")
    render_closeup(objects, renders / "ground-floor-before.png", old["height"])
    log("BEFORE " + json.dumps(old))


def render_views(objects, folder, height):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0
    world = bpy.data.worlds.new("Neutral studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (.46, .47, .49, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = .8
    scene.world = world
    lo = np.min([bounds(o)[0] for o in objects], axis=0)
    hi = np.max([bounds(o)[1] for o in objects], axis=0)
    center = Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, height * .45))
    for name, direction, power, size in (("Key", (-1.5, -2.5, 3), 100, 2.5),
                                          ("Fill", (2, 1.5, 2), 65, 3)):
        bpy.ops.object.light_add(type="AREA", location=center + Vector(direction) * height)
        lamp = bpy.context.object
        lamp.name = name
        lamp.data.energy = power * height ** 2
        lamp.data.shape = "DISK"
        lamp.data.size = size * height
        point_at(lamp, center)
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Inspection camera"
    scene.camera = camera
    camera.data.type = "ORTHO"
    camera.data.clip_end = height * 20
    camera.data.ortho_scale = max(height, float(np.max(hi - lo))) * 1.32
    for label, direction in (("front", (.45, -1, .18)), ("back", (-.45, 1, .18))):
        camera.location = center + Vector(direction) * height * 3
        point_at(camera, center)
        scene.render.filepath = str(folder / ("render-" + label + ".png"))
        bpy.ops.render.render(write_still=True)
    camera.location = center + Vector((.45, -1, .18)) * height * 3
    point_at(camera, center)


def comparison(folder):
    # Blender's own image I/O avoids an external Pillow dependency. Pixels are
    # scene-linear, so resizing and writing preserve the source colours.
    concept = bpy.data.images.load(str(folder / "concept-front.png"), check_existing=False)
    rendered = bpy.data.images.load(str(folder / "render-front.png"), check_existing=False)
    width = round(concept.size[0] * 1000 / concept.size[1])
    concept.scale(width, 1000)
    left = np.empty(width * 1000 * 4, dtype=np.float32)
    right = np.empty(1000 * 1000 * 4, dtype=np.float32)
    concept.pixels.foreach_get(left)
    rendered.pixels.foreach_get(right)
    pixels = np.concatenate((left.reshape(1000, width, 4), right.reshape(1000, 1000, 4)), axis=1)
    combined = bpy.data.images.new("Concept and low pieces", width=width + 1000, height=1000, alpha=True)
    combined.pixels.foreach_set(pixels.ravel())
    combined.filepath_raw = str(folder / "compare.png")
    combined.file_format = "PNG"
    combined.save()
    for image in (concept, rendered, combined):
        bpy.data.images.remove(image)


def png_size(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "Not a PNG: " + str(path)
    return struct.unpack(">II", data[16:24])


def file_checks(folder, report):
    for piece in report["pieces"]:
        prefix = piece["prefix"]
        for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png"):
            path = folder / "parts" / (prefix + suffix)
            assert path.is_file() and path.stat().st_size > 100, "Missing output: " + str(path)
            if suffix.endswith(".png"):
                assert png_size(path) == (SIZE, SIZE), "Texture is not 1024 square"
    for filename in ("hero.blend", "parts.json", "render-front.png", "render-back.png", "compare.png"):
        path = folder / filename
        assert path.is_file() and path.stat().st_size > 100, "Missing output: " + str(path)
    for filename in ("render-front.png", "render-back.png"):
        assert png_size(folder / filename) == (1000, 1000), "Wrong render dimensions"
    assert png_size(folder / "compare.png")[1] == 1000, "Comparison heights differ"
    assert png_size(folder / "renders" / "ground-floor-after.png") == (1600, 1000), "Wrong close-up dimensions"
    assert (folder / "renders" / "compare.png").read_bytes() == (folder / "compare.png").read_bytes(), "Comparison copy differs"
    expected = {p["prefix"] + suffix for p in report["pieces"]
                for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png")}
    actual = {p.name for p in (folder / "parts").iterdir()
              if p.suffix.lower() in (".fbx", ".png") or p.name.endswith(".upload.json")}
    assert actual == expected, "Stale/missing pieces, maps or upload records"


def assembly_checks(objects, height):
    lowest = min(bounds(o)[0][2] for o in objects)
    highest = max(bounds(o)[1][2] for o in objects)
    assert abs(lowest) < .01, "Lowest point is not z = 0"
    assert abs((highest - lowest) / height - 1) < .01, "Height differs by more than 1%"
    return {"lowest_z": round(float(lowest), 6), "height": round(float(highest - lowest), 6)}


def verify(folder, height):
    report = json.loads((folder / "parts.json").read_text(encoding="utf-8"))
    bpy.ops.wm.open_mainfile(filepath=str(folder / "hero.blend"))
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(objects) == report["piece_count"], "Blend contains extra or missing meshes"
    for piece in report["pieces"]:
        obj = bpy.data.objects[piece["label"]]
        actual = geometry_checks(obj)
        assert actual["triangles"] == piece["triangles"], "Saved triangle count differs"
        uv = assert_uvs(obj)
        assert uv == {key: piece[key] for key in uv}, "Saved UV measurements differ"
        assert uv["uv_coverage"] >= report.get("min_coverage", MIN_COVERAGE), "UV coverage below the floor"
        assert front_density(obj)["front_pixels_per_stud"] == piece["front_pixels_per_stud"], "Saved density differs"
        nodes = obj.data.materials[0].node_tree.nodes
        for channel in ("color", "normal", "roughness"):
            image = nodes[channel].image
            assert tuple(image.size) == (SIZE, SIZE) and image.packed_file, "Missing packed map"
    assembly_checks(objects, height)
    assert sum(p["triangles"] for p in report["pieces"]) == report["total_triangles"] <= TOTAL_LIMIT, "Wrong/over-budget triangle total"
    file_checks(folder, report)
    log("VERIFY PASS " + json.dumps(report))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--height", type=float, required=True)
    parser.add_argument("--parts", type=int, default=4)
    parser.add_argument("--front", choices=("auto", "+x", "-x", "+y", "-y"), default="auto")
    parser.add_argument("--cuts", help="Comma-separated horizontal cut heights in studs")
    parser.add_argument("--vertical-splits", default="", help="Extra capped cuts through x=0/y=0, e.g. ground-floor:xy,upper-walls:y")
    parser.add_argument("--geometry-source", type=Path, help="Approved four-band geometry.blend to keep the exterior exactly unchanged")
    parser.add_argument("--capture-before", action="store_true", help="Measure/render the current packed maps before replacement")
    parser.add_argument("--verify", action="store_true", help="Check existing outputs without rebuilding")
    parser.add_argument("--detail", type=float, default=1.0, help="Keep N times more triangles (total limit scales too)")
    parser.add_argument("--min-coverage", type=float, default=MIN_COVERAGE, help="UV use floor; round towers unwrap into many small charts")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "--front" in argv:
        index = argv.index("--front")
        if index + 1 < len(argv) and argv[index + 1] in ("+x", "-x", "+y", "-y", "auto"):
            argv = argv[:index] + ["--front=" + argv[index + 1]] + argv[index + 2:]
    args = parser.parse_args(argv)
    folder = args.folder.resolve()
    DETAIL[0] = args.detail
    for spec in filter(None, args.vertical_splits.split(",")):
        band, axes = spec.split(":")
        SPLITS[band] = 2 ** len(axes)
    global TOTAL_LIMIT
    TOTAL_LIMIT = round(48000 * args.detail)
    assert args.height > 0 and args.parts > 0, "Height and piece count must be positive"
    if args.verify:
        verify(folder, args.height)
        return
    if args.capture_before:
        capture_before(folder)
    assert (folder / "meshy.glb").is_file(), "Missing meshy.glb"
    assert (folder / "concept-front.png").is_file(), "Missing concept-front.png"
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.scene.unit_settings.system = "NONE"
    parts_folder = folder / "parts"
    parts_folder.mkdir(exist_ok=True)
    source, front = import_source(folder, args.height, args.front)
    touch_up(source, folder)
    source_count = len(triangles(source.data))
    cuts = [float(v) for v in args.cuts.split(",")] if args.cuts else None
    if cuts:
        assert len(cuts) == args.parts - 1, "--cuts needs --parts minus one heights"
    if args.geometry_source:
        assert args.parts == 4 and not cuts, "Preserved geometry already defines four bands and floor cuts"
        objects, cuts, topper_level = preserved_geometry(args.geometry_source.resolve(), args.height, front)
    else:
        objects, cuts, topper_level = split_source(source, args.parts, args.height, cuts)
        for obj in objects:
            simplify(obj, args.height)
    # Decimation may shift extreme vertices slightly. Restore the requested
    # assembly bounds uniformly before UVs/baking; source and low pieces remain
    # within the projection cage's tolerance.
    base = min(bounds(o)[0][2] for o in objects)
    top = max(bounds(o)[1][2] for o in objects)
    factor = args.height / (top - base)
    for obj in objects if not args.geometry_source else []:
        co = coordinates(obj.data)
        co[:, 2] -= base
        co *= factor
        obj.data.vertices.foreach_set("co", co.ravel())
        obj.data.update()
    objects = split_vertical(objects, args.vertical_splits, args.height)
    report = {"source": "meshy.glb", "source_triangles": source_count,
              "source_map_sizes": {name: list(png_size(folder / ("meshy-" + name + ".png")))
                                   for name in ("base_color", "normal", "roughness")},
              "front": front, "piece_count": len(objects), "requested_height": args.height,
              "floor_cuts": cuts, "topper_base": topper_level,
              "vertical_splits": args.vertical_splits, "min_coverage": args.min_coverage, "pieces": []}
    if args.geometry_source:
        report["geometry_source"] = str(args.geometry_source)
    cycles_setup()
    for k, obj in enumerate(objects, 1):
        close_holes(obj)
        drop_duplicate_faces(obj)   # hole patching welds points, which can stack two faces
        uv_report = None
        for angle in (80, 60, 45):
            for margin in (.0027, .004, .006):
                PACK_MARGIN[0] = margin
                unwrap(obj, angle)
                try:
                    uv_report = assert_uvs(obj)
                    break
                except AssertionError as error:
                    if "stretch" in str(error) and angle != 45:
                        log(obj.name + ": stretched projection, splitting charts at a tighter angle")
                        break
                    if "padding" not in str(error) or margin == .006:
                        raise
                    log(obj.name + ": gutter under 4 px, repacking wider")
            if uv_report is not None:
                break
        assert uv_report["uv_coverage"] >= args.min_coverage, (obj.name, "UV coverage below the floor", uv_report)
        prefix = str(k) + "-" + obj.name
        bake(source, obj, parts_folder, prefix, args.height)
        piece = geometry_checks(obj)
        piece.update(uv_report)
        piece.update(front_density(obj))
        piece["prefix"] = prefix
        export_piece(obj, parts_folder, prefix)
        report["pieces"].append(piece)
    destroy(source)
    report.update(assembly_checks(objects, args.height))
    report["total_triangles"] = sum(p["triangles"] for p in report["pieces"])
    assert report["total_triangles"] <= TOTAL_LIMIT, "Assembly exceeds the triangle limit"
    render_views(objects, folder, args.height)
    comparison(folder)
    renders = folder / "renders"
    renders.mkdir(exist_ok=True)
    render_closeup(objects, renders / "ground-floor-after.png", args.height)
    (renders / "compare.png").write_bytes((folder / "compare.png").read_bytes())
    # Remove every stale mesh, map and upload record, including records whose
    # prefix still exists but now refers to rebuilt geometry/UVs.
    wanted = {p["prefix"] + suffix for p in report["pieces"]
              for suffix in (".fbx", "-color.png", "-normal.png", "-roughness.png")}
    for path in parts_folder.iterdir():
        if (path.suffix.lower() in (".fbx", ".png") or path.name.endswith(".upload.json")) and path.name not in wanted:
            path.unlink()
    # Only the low pieces are saved/rendered; unused high-poly materials/maps
    # would otherwise bloat a reusable hero asset.
    for mat in list(bpy.data.materials):
        if mat.users == 0:
            bpy.data.materials.remove(mat)
    for image in list(bpy.data.images):
        if image.users == 0:
            bpy.data.images.remove(image)
    for image in bpy.data.images:
        if image.packed_file:
            image.filepath = "//parts/" + Path(image.filepath).name
    (folder / "parts.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / "hero.blend"))
    file_checks(folder, report)
    log("PASS " + json.dumps(report))


if __name__ == "__main__":
    main()
