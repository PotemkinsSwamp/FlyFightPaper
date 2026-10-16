"""Asset-specific bridge source reshaping, followed by the existing strict hero bake.

The source opening is only about 79 studs wide. Compressing the book stacks toward
their outside edges keeps their doors, frames, page texture and UVs together while
opening the required 100 by 95 road. The case windows remain above the blend zone.
No shared art tool or original Meshy file is changed. Dimensions live in touchup.json.
"""
import json
import sys
from pathlib import Path
import bpy
import numpy as np

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
adapter = ROOT / 'assets/models/porthole-book-tower/renders/bake_closed.py'
# Reuse the existing stricter topology repair without starting its main routine.
exec(compile(adapter.read_text().rsplit('hero.main()', 1)[0], str(adapter), 'exec'), globals())
original_import = hero.import_source


def reshape_source(folder, height, front):
    source, chosen_front = original_import(folder, height, front)
    specification = json.loads((folder / 'touchup.json').read_text())['source_deformation']
    assert height == specification['height'] and chosen_front == specification['front']
    co = hero.coordinates(source.data)
    z = co[:, 2].copy()
    inner, target, outer = (specification[k] for k in ('old_inner_x', 'new_inner_x', 'outer_x'))
    start, end = (specification[k] for k in ('x_blend_start_z', 'x_blend_end_z'))
    assert 0 < inner < target < outer and start < end
    x = np.abs(co[:, 0])
    reshaped = np.where(x <= inner, x * target / inner,
                        target + (x - inner) * (outer - target) / (outer - inner))
    weight = np.clip((end - z) / (end - start), 0, 1)
    co[:, 0] = np.sign(co[:, 0]) * (x + weight * (reshaped - x))
    old, new = (specification[k] for k in ('old_height_break', 'new_height_break'))
    assert 0 < old < height and 0 < new < height
    co[:, 2] = np.where(z <= old, z * new / old,
                        new + (z - old) * (height - new) / (height - old))
    source.data.vertices.foreach_set('co', co.ravel())
    source.data.update()
    if source.data.has_custom_normals:
        hero.active(source)
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
    hero.log('bridge source reshaped with original faces and UVs retained')
    return source, chosen_front


hero.import_source = reshape_source


def finish_scene():
    """Remove the shared splitter's empty placeholder without changing game pieces."""
    folder = Path(bpy.data.filepath).parent
    labels = {p['label'] for p in json.loads((folder / 'parts.json').read_text())['pieces']}
    extra = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.name not in labels]
    assert all(o.name == 'Other roof ornaments' and not o.data.vertices and not o.data.polygons for o in extra)
    for obj in extra:
        mesh = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    if extra:
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'hero.blend'))


if __name__ == '__main__':
    hero.main()
    finish_scene()
