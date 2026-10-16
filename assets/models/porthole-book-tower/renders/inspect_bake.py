"""Local inspection only. Does not modify Meshy inputs or shared tools."""
import sys, json, math
from pathlib import Path
import bpy, bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

folder = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
if (folder / 'parts.json').exists():
    report = json.loads((folder / 'parts.json').read_text())
else:
    report = {'height': float(sys.argv[sys.argv.index('--')+2]), 'pieces': [
        {'label': p['piece']} for p in json.loads((folder/'renders'/'preflight.json').read_text())]}
scene = bpy.context.scene
objects = [bpy.data.objects[p['label']] for p in report['pieces']]
checks = []
for obj in objects:
    bm = bmesh.new(); bm.from_mesh(obj.data)
    edges = [e for e in bm.edges if e.is_boundary]
    checks.append({'piece': obj.name, 'boundary_edges': len(edges),
                   'nonmanifold_edges': sum(not e.is_manifold for e in bm.edges),
                   'boundary_coordinates': [[list(v.co) for v in e.verts] for e in edges]})
    bm.free()
(folder / 'renders' / 'geometry-inspection.json').write_text(json.dumps(checks, indent=2)+'\n')
print('CHECK boundaries', [(p['piece'], p['boundary_edges']) for p in checks if p['boundary_edges']], flush=True)

verts, faces = [], []
for obj in objects:
    offset = len(verts)
    verts.extend([obj.matrix_world @ v.co for v in obj.data.vertices])
    faces.extend([tuple(offset+i for i in p.vertices) for p in obj.data.polygons])
tree = BVHTree.FromPolygons(verts, faces, all_triangles=True)
height = report['height']
holes = {'porthole-book-tower': (0, 182.5, 80), 'tape-roll-tower': (0, 220, 80)}
if folder.name in holes:
    cx, cz, size = holes[folder.name]
    coords = np.linspace(-size/2, size/2, 161)
    clear = np.zeros((len(coords), len(coords)), dtype=bool)
    for iz, dz in enumerate(coords):
        for ix, dx in enumerate(coords):
            hit = tree.ray_cast(Vector((cx+dx, -height*4, cz+dz)), Vector((0,1,0)), height*8)[0]
            clear[iz, ix] = hit is None
    (folder / 'renders' / 'hole-rays.json').write_text(json.dumps({'center':[cx,cz], 'sample_spacing':size/160,
        'clear_center_ray': bool(clear[80,80]), 'clear_pixels': int(clear.sum()),
        'grid': clear.astype(int).tolist()})+'\n')
    def emission(name, color):
        mat=bpy.data.materials.new(name); mat.use_nodes=True
        nodes=mat.node_tree.nodes; nodes.clear()
        em=nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value=(*color,1)
        out=nodes.new('ShaderNodeOutputMaterial'); mat.node_tree.links.new(em.outputs[0], out.inputs['Surface'])
        return mat
    mats=[emission('Proof cyan',(.05,.65,.85)), emission('Proof white',(.85,.9,.95))]
    for side, sign in [('front',-1),('back',1)]:
        created=[]
        for ix in range(8):
            for iz in range(8):
                bpy.ops.mesh.primitive_plane_add(size=size/8, location=(cx-size/2+(ix+.5)*size/8,
                    -sign*height*2, cz-size/2+(iz+.5)*size/8), rotation=(math.pi/2,0,0))
                panel=bpy.context.object; panel.data.materials.append(mats[(ix+iz)%2]); created.append(panel)
        camera=scene.camera; camera.data.type='ORTHO'; camera.data.ortho_scale=size
        camera.data.clip_end=height*20
        camera.location=(cx,sign*height*3,cz)
        camera.rotation_euler=(Vector((cx,0,cz))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.engine='BLENDER_EEVEE'; scene.render.resolution_x=1200; scene.render.resolution_y=1200
        scene.render.resolution_percentage=100; scene.render.image_settings.file_format='PNG'
        scene.render.filepath=str(folder/'renders'/f'flythrough-{side}.png')
        bpy.ops.render.render(write_still=True)
        for obj in created: bpy.data.objects.remove(obj,do_unlink=True)
print('CHECK done', folder.name, flush=True)
