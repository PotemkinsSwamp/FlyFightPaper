"""Run the shared hero baker with strict closure and triangle limits before UVs.

All shared bake settings stay unchanged. This local adapter repairs cut-piece
topology and finishes collapsed-UV repairs. Exact shared UV checks still apply.
Meshy art changes still come from each touchup.json.
"""
import sys, importlib.util
sys.dont_write_bytecode=True
from pathlib import Path
import bpy,bmesh
spec=importlib.util.spec_from_file_location('hero',str(Path('tools/art/hero.py').resolve()))
hero=importlib.util.module_from_spec(spec); spec.loader.exec_module(hero)
original_close=hero.close_holes
original_checks=hero.geometry_checks
original_split=hero.split_vertical
original_unwrap=hero.unwrap

def strict_close(obj):
    original_close(obj)
    original=len(obj.data.polygons)
    bm=bmesh.new(); bm.from_mesh(obj.data)
    needs_repair=any(not e.is_manifold for e in bm.edges); bm.free()
    if needs_repair:
        # Blender's native volume repair resolves overlapping/internal fins.
        # A 0.2-stud cell is smaller than the source-to-bake projection cage.
        lo,hi=hero.bounds(obj)
        hero.active(obj); obj.data.remesh_voxel_size=.2
        obj.data.use_remesh_preserve_volume=True
        bpy.ops.object.voxel_remesh()
        co=hero.coordinates(obj.data); new_lo=co.min(0); new_hi=co.max(0)
        co=(co-new_lo)/(new_hi-new_lo)*(hi-lo)+lo
        obj.data.vertices.foreach_set('co',co.ravel()); obj.data.update()
        bm=bmesh.new(); bm.from_mesh(obj.data)
        cap=bm.faces.layers.int.get('hero_cap') or bm.faces.layers.int.new('hero_cap')
        for f in bm.faces:
            if any(abs(f.normal[a])>.95 and all(abs(v.co[a])<.12 for v in f.verts) for a in [0,1]): f[cap]=2
            elif abs(f.normal.z)>.95 and (all(abs(v.co.z-lo[2])<.12 for v in f.verts) or
                    (obj.name.startswith(('ground-floor','upper-walls')) and all(abs(v.co.z-hi[2])<.12 for v in f.verts))): f[cap]=1
        groups=hero.components(bm)
        areas=[sum(f.calc_area() for f in {f for v in group for f in v.link_faces}) for group in groups]
        cutoff=max(.3,max(areas)*.00001)
        tiny=[v for group,area in zip(groups,areas) if area<cutoff for v in group]
        if tiny: bmesh.ops.delete(bm,geom=tiny,context='VERTS')
        bm.to_mesh(obj.data); bm.free()
        target=min(original,11500)
        hero.active(obj); modifier=obj.modifiers.new('Keep repaired surface in budget','DECIMATE')
        modifier.ratio=min(1,target*.97/max(1,len(hero.triangles(obj.data))))
        modifier.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        hero.log(f'{obj.name}: native volume repair leaves {len(obj.data.polygons)} faces (target {target}, removed {len(tiny)} dust vertices)')
        obj['closure_repair']='Blender voxel repair, 0.2 studs, restored original bounds'
    for iteration in range(8):
        bm=bmesh.new(); bm.from_mesh(obj.data)
        # Remove surplus faces at tangled cut caps. Prefer small, planar caps.
        for step in range(200):
            bad=[e for e in bm.edges if len(e.link_faces)>2]
            if not bad: break
            edge=bad[0]
            face=min(edge.link_faces,key=lambda f: (not any(all(abs(v.co[a])<1e-4 for v in f.verts) for a in [0,1]),f.calc_area()))
            bmesh.ops.delete(bm,geom=[face],context='FACES_ONLY')
        loose=[e for e in bm.edges if not e.link_faces]
        if loose: bmesh.ops.delete(bm,geom=loose,context='EDGES')
        loose=[v for v in bm.verts if not v.link_faces]
        if loose: bmesh.ops.delete(bm,geom=loose,context='VERTS')
        holes=[e for e in bm.edges if e.is_boundary]
        if holes:
            bmesh.ops.holes_fill(bm,edges=holes,sides=0)
            remaining={e for e in bm.edges if e.is_boundary}
            while remaining:
                first=remaining.pop(); group={first}; stack=[first]
                while stack:
                    e=stack.pop()
                    for v in e.verts:
                        for neighbor in v.link_edges:
                            if neighbor in remaining:
                                remaining.remove(neighbor); group.add(neighbor); stack.append(neighbor)
                if all(sum(e in group for e in v.link_edges)==2 for v in {v for e in group for v in e.verts}):
                    bmesh.ops.triangle_fill(bm,edges=list(group),use_beauty=True,use_dissolve=False)
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        boundary=sum(e.is_boundary for e in bm.edges)
        nonmanifold=sum(not e.is_manifold for e in bm.edges)
        bm.to_mesh(obj.data); bm.free(); obj.data.update()
        hero.drop_duplicate_faces(obj)
        if len(obj.data.polygons)>hero.LIMIT:
            hero.active(obj)
            modifier=obj.modifiers.new('Hard exported piece budget','DECIMATE')
            before_count=len(obj.data.polygons)
            modifier.ratio=(11500*.95 if needs_repair else 11900*.995)/before_count
            modifier.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            hero.log(f'{obj.name}: hard budget {before_count} -> {len(obj.data.polygons)} faces')
            continue
        bm=bmesh.new(); bm.from_mesh(obj.data)
        debris=[]
        for group in hero.components(bm):
            faces={f for v in group for f in v.link_faces}
            if len(faces)<=6 and any(e.is_boundary for v in group for e in v.link_edges): debris.extend(group)
        if debris:
            bmesh.ops.delete(bm,geom=debris,context='VERTS')
            bm.to_mesh(obj.data); obj.data.update()
            hero.log(f'{obj.name}: removed {len(debris)} isolated closure debris vertices')
        boundary=sum(e.is_boundary for e in bm.edges); nonmanifold=sum(not e.is_manifold for e in bm.edges); bm.free()
        if not boundary and not nonmanifold:
            if original!=len(obj.data.polygons): hero.log(f'{obj.name}: strict closure {original} -> {len(obj.data.polygons)} triangles, zero open/nonmanifold edges')
            return
    raise AssertionError((obj.name,'Strict closure/budget failed',boundary,nonmanifold,len(obj.data.polygons)))

def strict_checks(obj):
    report=original_checks(obj)
    bm=bmesh.new(); bm.from_mesh(obj.data)
    assert all(e.is_manifold for e in bm.edges), (obj.name,'Piece must be fully closed')
    bm.free()
    return report

hero.close_holes=strict_close
hero.geometry_checks=strict_checks
def closed_split(objects, specification, height):
    objects=original_split(objects,specification,height)
    for obj in objects: strict_close(obj)
    return objects
hero.split_vertical=closed_split

def strict_unwrap(obj, angle_limit=80):
    original_unwrap(obj, angle_limit)
    # The shared repair stops after six passes and can leave a newly collapsed
    # sliver. Continue only when the exact UV checks would still fail.
    np=hero.np
    for attempt in range(12):
        overlaps=hero.overlapping_uv_faces(obj.data)
        values=np.empty(len(obj.data.loops)*2,dtype=np.float64)
        obj.data.uv_layers.active.data.foreach_get('uv',values)
        values=values.reshape(-1,3,2)
        a,b=values[:,1]-values[:,0],values[:,2]-values[:,0]
        signed=a[:,0]*b[:,1]-a[:,1]*b[:,0]
        thin=np.flatnonzero(np.abs(signed)<1e-11)
        if not len(overlaps) and not len(thin): return
        detach=np.unique(np.concatenate((overlaps[:,1],thin)))
        for order,index in enumerate(detach):
            if index in thin:
                values[index]=np.array(((0,0),(.012,0),(.006,.0104)))
            values[index]+=(.031+order*.000137,.043+order*.000193)
        obj.data.uv_layers.active.data.foreach_set('uv',values.ravel())
        hero.log(f'{obj.name}: continuing exact UV repair for {len(detach)} faces')
        hero.pack_uvs(obj)
    raise AssertionError((obj.name,'UV repair did not converge'))

hero.unwrap=strict_unwrap
hero.main()
