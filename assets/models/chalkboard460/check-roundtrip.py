import bpy,json,math,itertools,struct,hashlib
from pathlib import Path
from mathutils import Vector
root=Path('D:/FlyFightPaper/assets/models/chalkboard460');d=json.loads((root/'chalkboard460-geometry.json').read_text())
def rb(v):return [float(v.x),float(v.z),float(-v.y)]
def sig(points):return tuple(sorted(tuple(round(n,3) for n in p) for p in points))
buckets={}
for i,f in enumerate(d['triangles']):buckets.setdefault(sig([d['verticesRobloxXYZ'][j-1] for j in f]),[]).append(i)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(root/'chalkboard460.glb'),import_shading='NORMALS',merge_vertices=True)
used=set();maximum=[0.,0.,0.];unmatched=[];art_uv=[]
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
 me=o.data;me.calc_loop_triangles();matrix=o.matrix_world.to_3x3().inverted().transposed()
 for t in me.loop_triangles:
  points=[rb(o.matrix_world@me.vertices[i].co) for i in t.vertices];normals=[rb((matrix@me.corner_normals[i].vector).normalized()) for i in t.loops]
  uv=[list(me.uv_layers.active.data[i].uv) for i in t.loops] if me.uv_layers else [[0,0]]*3
  candidates=[]
  for face in buckets.get(sig(points),[]):
   if face in used:continue
   expected=[d['verticesRobloxXYZ'][j-1] for j in d['triangles'][face]]
   for perm in itertools.permutations(range(3)):
    pe=max(max(abs(points[k][a]-expected[perm[k]][a]) for a in range(3)) for k in range(3))
    if pe>.0001:continue
    ne=max(math.dist(normals[k],d['faceCornerNormalsRobloxXYZ'][face][perm[k]]) for k in range(3));ue=max(max(abs(uv[k][a]-d['faceCornerUVs'][face][perm[k]][a]) for a in range(2)) for k in range(3))
    candidates.append((pe,ne,ue,face,perm))
  if not candidates:unmatched.append({'object':o.name,'face':t.index});continue
  pe,ne,ue,face,perm=min(candidates,key=lambda c:(c[0],c[1],c[2],c[3]));used.add(face);maximum=[max(maximum[0],pe),max(maximum[1],ue),max(maximum[2],ne)]
  if d['faceMaterials'][face]=='BoardArtwork':art_uv.extend(uv)
report={'status':'PASS' if len(used)==d['triangleCount'] and not unmatched and maximum[0]<=.0001 and maximum[1]<=.00001 and maximum[2]<=.0001 else 'FAIL','matched':len(used),'unmatchedNative':unmatched,'unmatchedCanonical':sorted(set(range(d['triangleCount']))-used),'maximumPositionError':maximum[0],'maximumUVError':maximum[1],'maximumNormalError':maximum[2],'thresholds':{'position':.0001,'UV':.00001,'normal':.0001},'method':'Triangle position signatures and corner permutations, no face-index assumptions; NORMALS+merge_vertices=True import','artworkUVExtrema':{'min':[min(p[a] for p in art_uv) for a in range(2)],'max':[max(p[a] for p in art_uv) for a in range(2)]}}
blob=(root/'chalkboard460.glb').read_bytes();offset=12;chunks={}
while offset<len(blob):
 size,kind=struct.unpack_from('<II',blob,offset);chunks[kind]=blob[offset+8:offset+8+size];offset+=8+size
meta=json.loads(chunks[0x4e4f534a]);binary=chunks[0x004e4942];image=meta['images'][0];view=meta['bufferViews'][image['bufferView']];start=view.get('byteOffset',0);pixels=binary[start:start+view['byteLength']]
report['embeddedPNGExact']=pixels==(root/'chalkboard460-artwork.png').read_bytes();assert report['embeddedPNGExact']
(root/'roundtrip-report.json').write_text(json.dumps(report,indent=2)+'\n');print('CHALKBOARD460_ROUNDTRIP',json.dumps(report));assert report['status']=='PASS'
# Independent color fallback has no textures, images, or per-material texture binding.
blob=(root/'chalkboard460-colors.glb').read_bytes();size,kind=struct.unpack_from('<II',blob,12);meta=json.loads(blob[20:20+size]);assert not meta.get('images') and not meta.get('textures');print('COLOR_ONLY_GLB PASS')
