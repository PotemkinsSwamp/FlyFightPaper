"""Temporary geometry and straight-through checks for the Part 2 models."""
import json
import math
import sys
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

folder = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
report = json.loads((folder / 'parts.json').read_text())
objects = [bpy.data.objects[p['label']] for p in report['pieces']]
assert len(objects) == report['piece_count'] == sum(o.type == 'MESH' for o in bpy.context.scene.objects)
checks = []
verts, faces = [], []
for piece, obj in zip(report['pieces'], objects):
    obj.data.calc_loop_triangles()
    assert all(len(p.vertices) == 3 for p in obj.data.polygons), obj.name
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    counts = {'prefix': piece['prefix'], 'triangles': len(obj.data.loop_triangles),
              'boundary_edges': sum(e.is_boundary for e in bm.edges),
              'nonmanifold_edges': sum(not e.is_manifold for e in bm.edges)}
    bm.free()
    assert counts['triangles'] == piece['triangles'] <= 12000, counts
    assert counts['boundary_edges'] == counts['nonmanifold_edges'] == 0, counts
    checks.append(counts)
    offset = len(verts)
    verts.extend([obj.matrix_world @ v.co for v in obj.data.vertices])
    faces.extend([tuple(offset + i for i in p.vertices) for p in obj.data.polygons])
result = {'pieces': checks, 'total_triangles': sum(p['triangles'] for p in checks),
          'lowest_front_pixels_per_stud': min(p['front_pixels_per_stud'] for p in report['pieces']
                                             if p['front_pixels_per_stud'] is not None)}
assert result['total_triangles'] == report['total_triangles']

if folder.name == 'pencil-case-bridge':
    tree = BVHTree.FromPolygons(verts, faces, all_triangles=True)
    blocked = []
    for sign in (-1, 1):
        for ix in range(100):
            for iz in range(95):
                x, z = -49.5 + ix, .5 + iz
                hit = tree.ray_cast(Vector((x, sign * 600, z)), Vector((0, -sign, 0)), 1200)[0]
                if hit is not None:
                    blocked.append([sign, x, z, list(hit)])
    result['road_gap'] = {'width': 100, 'height': 95, 'spacing': 1, 'rays': 19000,
                          'blocked': len(blocked), 'first_blocked': blocked[:20]}
    # Also test projected triangles, so a thin fin between ray samples cannot pass.
    intrusions = []
    for index, face in enumerate(faces):
        polygon = [(verts[i].x, verts[i].z) for i in face]
        if (max(p[0] for p in polygon) <= -49.9999 or min(p[0] for p in polygon) >= 49.9999
                or max(p[1] for p in polygon) <= .0001 or min(p[1] for p in polygon) >= 94.9999):
            continue
        for axis, boundary, greater in [(0, -49.9999, True), (0, 49.9999, False),
                                         (1, .0001, True), (1, 94.9999, False)]:
            clipped = []
            for a, b in zip(polygon, polygon[1:] + polygon[:1]):
                inside_a = a[axis] >= boundary if greater else a[axis] <= boundary
                inside_b = b[axis] >= boundary if greater else b[axis] <= boundary
                if inside_a:
                    clipped.append(a)
                if inside_a != inside_b:
                    t = (boundary - a[axis]) / (b[axis] - a[axis])
                    clipped.append(tuple(a[i] + t * (b[i] - a[i]) for i in (0, 1)))
            polygon = clipped
            if not polygon:
                break
        if polygon:
            intrusions.append(index)
    result['road_gap']['projected_intruding_triangles'] = len(intrusions)
    result['road_gap']['first_intruding_triangle_indices'] = intrusions[:20]
    (folder / 'renders/part2-geometry.json').write_text(json.dumps(result, indent=2) + '\n')
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x, scene.render.resolution_y = 1400, 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.film_transparent = False
    materials = []
    for name, color in [('Proof cyan', (.05, .65, .85, 1)), ('Proof white', (.85, .9, .95, 1))]:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        mat.node_tree.nodes.clear()
        emission = mat.node_tree.nodes.new('ShaderNodeEmission')
        emission.inputs['Color'].default_value = color
        output = mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
        mat.node_tree.links.new(emission.outputs[0], output.inputs['Surface'])
        materials.append(mat)
    for side, sign in [('front', -1), ('back', 1)]:
        panels = []
        for ix in range(12):
            for iz in range(10):
                bpy.ops.mesh.primitive_plane_add(size=20, location=(-110 + ix * 20, -sign * 280, -20 + iz * 20),
                                                rotation=(math.pi / 2, 0, 0))
                panel = bpy.context.object
                panel.data.materials.append(materials[(ix + iz) % 2])
                panels.append(panel)
        camera = scene.camera
        camera.data.type = 'ORTHO'
        camera.data.ortho_scale = 220
        camera.data.clip_end = 2800
        camera.location = (0, sign * 420, 70)
        camera.rotation_euler = (Vector((0, 0, 70)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(folder / 'renders' / f'flythrough-{side}.png')
        bpy.ops.render.render(write_still=True)
        for panel in panels:
            bpy.data.objects.remove(panel, do_unlink=True)
    assert not blocked, ('Bridge gap obstructed', blocked[:10])
    assert not intrusions, ('Thin geometry enters the road gap', intrusions[:20])

(folder / 'renders/part2-geometry.json').write_text(json.dumps(result, indent=2) + '\n')
print('PART2 CHECK PASS', folder.name, json.dumps(result), flush=True)
