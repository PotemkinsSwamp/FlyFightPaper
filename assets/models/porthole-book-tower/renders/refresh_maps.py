"""Use filled on-disk maps in the reusable Blend and final inspection renders."""
import sys, json, importlib.util
sys.dont_write_bytecode=True
from pathlib import Path
import bpy, bmesh
folder=Path(sys.argv[sys.argv.index('--')+1]).resolve()
report=json.loads((folder/'parts.json').read_text())
objects=[bpy.data.objects[p['label']] for p in report['pieces']]
for p,obj in zip(report['pieces'],objects):
    bm=bmesh.new(); bm.from_mesh(obj.data)
    boundary=sum(e.is_boundary for e in bm.edges); bm.free()
    print('FINAL boundary',obj.name,boundary,flush=True)
    nodes=obj.data.materials[0].node_tree.nodes
    for channel in ['color','normal','roughness']:
        image=bpy.data.images.load(str(folder/'parts'/(p['prefix']+'-'+channel+'.png')),check_existing=False)
        image.colorspace_settings.name='sRGB' if channel=='color' else 'Non-Color'
        image.pack(); nodes[channel].image=image
        image.filepath='//parts/'+p['prefix']+'-'+channel+'.png'
for im in list(bpy.data.images):
    if im.users==0: bpy.data.images.remove(im)
spec=importlib.util.spec_from_file_location('hero',str(Path('tools/art/hero.py').resolve()))
hero=importlib.util.module_from_spec(spec); spec.loader.exec_module(hero)
for obj in list(bpy.context.scene.objects):
    if obj.type in ['LIGHT','CAMERA']: bpy.data.objects.remove(obj,do_unlink=True)
hero.render_views(objects,folder,report['requested_height'])
hero.comparison(folder)
hero.render_closeup(objects,folder/'renders'/'ground-floor-after.png',report['requested_height'])
(folder/'renders'/'compare.png').write_bytes((folder/'compare.png').read_bytes())
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(folder/'hero.blend'))
print('FINAL maps refreshed', folder.name, flush=True)
