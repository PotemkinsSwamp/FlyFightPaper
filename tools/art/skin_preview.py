"""A printed-sheet skin (Common or Rare) on real planes, before any upload:
    blender -b --factory-startup --python tools/art/skin_preview.py -- OUT_DIR SHEET.png [SHEET2.png ...]
Each sheet (one 1024 picture in the assets/models/planes/skin-sheet layout) is worn by every piece that has a
printed-sheet copy (its SheetUV plus its own creases), on two builds put together the way the game builds them
(plane_assembly.py); tape, elastic and weapons keep their own look, team stickers are left off. Six views a build (VIEWS=front,chase renders only those),
lit like the Dragon's previews. Writes OUT_DIR/<sheet name>-<build>-<view>.png. Nothing is uploaded."""
import sys, os, json, bpy
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import plane_assembly as pa
a = sys.argv[sys.argv.index("--") + 1:]; OUT = os.path.abspath(a[0]); SHEETS = [os.path.abspath(p) for p in a[1:]]; os.makedirs(OUT, exist_ok=True)
pa.FBX_DIRS = [pa.PLANES / "skin-sheet"] + pa.FBX_DIRS                       # the printed-sheet copies where a piece has one
COPIES = json.load(open(pa.ROOT / "config" / "skin-pieces.json"))["pieces"]
BUILDS = {"starter": dict(body="body_standard", nose="nose_0", wings="wings_0", tail="tail_0", weapon_mounts=["pellet", "thumbtack"], utility="boost_band"),
          "heavy": dict(body="body_heavy", nose="nose_3", wings="wings_4", tail="tail_3", weapon_mounts=["pellet", "pellet", "eraser", "eraser"], utility="boost_twin")}
if os.environ.get("MORE"):                                                  # MORE=1: also the mk2 bodies and the twin-fin tail
    BUILDS.update(swept=dict(body="body_standard_mk2", nose="nose_1", wings="wings_1", tail="tail_1", weapon_mounts=["staple", "staple"], utility="boost_twin"),
                  heavy2=dict(body="body_heavy_mk2", nose="nose_3", wings="wings_4", tail="tail_4", weapon_mounts=["pellet", "pellet"], utility="boost_spool"),
                  slim=dict(body="body_slim", nose="nose_5", wings="wings_2", tail="tail_2", weapon_mounts=["pellet", "pellet"]))
GAP = 80.0
def to_bl(p, dx=0.0): return Vector((p[0] + dx, -p[2], p[1]))                # Roblox (x right, y up, nose -z) -> Blender
bpy.ops.wm.read_factory_settings(use_empty=True); sc = bpy.context.scene

def tex(nt, path, data):
    x = nt.nodes.new("ShaderNodeTexImage"); x.image = bpy.data.images.load(str(path), check_existing=True); x.image.colorspace_settings.name = "Non-Color" if data else "sRGB"; return x
def material(name, color=None, normal=None, rough=0.7, tint=None, rgb=(0.7, 0.7, 0.7)):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = rough
    if color and os.path.exists(color):
        out = tex(nt, color, False).outputs[0]
        if tint:
            mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 1.0
            nt.links.new(out, mix.inputs["A"]); mix.inputs["B"].default_value = (*tint, 1); out = mix.outputs["Result"]
        nt.links.new(out, b.inputs["Base Color"])
    else: b.inputs["Base Color"].default_value = (*rgb, 1)
    if normal and os.path.exists(normal):
        nm = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(tex(nt, normal, True).outputs[0], nm.inputs["Color"]); nt.links.new(nm.outputs[0], b.inputs["Normal"])
    return m

def import_piece(piece, dx):                                                 # as crane_skin.py: the FBX fitted to its box on the plane
    before = set(bpy.data.objects); bpy.ops.import_scene.fbx(filepath=piece["fbx"])
    new = [o for o in bpy.data.objects if o not in before]; meshes = [o for o in new if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o in meshes)
    bpy.context.view_layer.objects.active = meshes[0]; bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for o in new:
        if o.type != "MESH": bpy.data.objects.remove(o)
    if len(meshes) > 1: bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active; bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    raw = np.array([(v.co.x, v.co.z, -v.co.y) for v in ob.data.vertices]); lo, hi = raw.min(0), raw.max(0)
    world = np.array(piece["centre"]) + (raw - (lo + hi) / 2) * np.array(piece["size"]) / np.maximum(hi - lo, 1e-6)
    for v, w in zip(ob.data.vertices, world): v.co = to_bl(w, dx)
    ob.name = piece["name"]; return ob, world

scenes, skinned = {}, []                                                     # skinned: the materials whose picture is the sheet
for i, (name, lo) in enumerate(BUILDS.items()):
    dx, obs, pts = i * GAP, [], []
    for p in pa.assemble(lo):
        if not p["fbx"] or not os.path.exists(p["fbx"]) or "sticker" in p["name"]: continue
        ob, world = import_piece(p, dx); ob.data.materials.clear()
        if p["name"] in COPIES:
            m = material("S-" + name + p["name"], SHEETS[0], str(pa.PLANES / "skin-sheet" / (p["name"] + "-normal.png"))); skinned.append(m)
        elif p["slot"] == "weapon":
            folder = os.path.dirname(os.path.dirname(p["fbx"]))
            img = next((os.path.join(folder, f) for f in ("color.png", "meshy-base_color.png") if os.path.exists(os.path.join(folder, f))), None)
            m = material("W-" + name + p["name"], img if ob.data.uv_layers else None, rough=0.5)
        else:
            m = material("B-" + name + p["name"], str(pa.PLANES / "paper-set" / (p["name"] + "-color.png")), tint=(1, 0.66, 0.007) if "tape" in p["name"] else None)
        ob.data.materials.append(m); obs.append(ob)
        if p["slot"] in ("body", "nose", "wings", "tail"): pts.append(world)
    P = np.concatenate(pts); lo3, hi3 = P.min(0), P.max(0)
    scenes[name] = dict(obs=obs, mid=to_bl((lo3 + hi3) / 2, dx), L=hi3[2] - lo3[2], span=hi3[0] - lo3[0])
    print("BUILD %s: %d pieces, %d wear the sheet" % (name, len(obs), sum(o.name in COPIES for o in obs)))

sc.render.engine = "BLENDER_EEVEE"; sc.view_settings.view_transform = "Standard"; sc.render.resolution_x, sc.render.resolution_y = 1280, 720
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; wn = w.node_tree; bg = wn.nodes["Background"]; bg.inputs[0].default_value = (0.72, 0.76, 0.84, 1)
s2 = wn.nodes.new("ShaderNodeBackground"); s2.inputs[1].default_value = 0.55; s2.inputs[0].default_value = (1, 1, 1, 1)   # even light from all round, as Roblox's ambient
lp = wn.nodes.new("ShaderNodeLightPath"); wm = wn.nodes.new("ShaderNodeMixShader"); wn.links.new(lp.outputs["Is Camera Ray"], wm.inputs[0]); wn.links.new(s2.outputs[0], wm.inputs[1]); wn.links.new(bg.outputs[0], wm.inputs[2]); wn.links.new(wm.outputs[0], wn.nodes["World Output"].inputs[0])
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 1.4; sun.rotation_euler = (0.70, 0, 0.44); sc.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.clip_end = 500
tg = bpy.data.objects.new("T", None); sc.collection.objects.link(tg); con = cam.constraints.new("TRACK_TO"); con.target = tg; con.track_axis = "TRACK_NEGATIVE_Z"; con.up_axis = "UP_Y"
for sheet in SHEETS:
    img = bpy.data.images.load(sheet, check_existing=True); tag = os.path.splitext(os.path.basename(sheet))[0]
    for m in skinned: next(n for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image.colorspace_settings.name == "sRGB").image = img
    for name, s in scenes.items():
        for n2, other in scenes.items():
            for ob in other["obs"]: ob.hide_render = n2 != name
        L, mid, E = s["L"], s["mid"], max(s["L"], s["span"])
        for view, off, look, lens in (("front", (-0.62, 0.66, 0.42), (0, 0, 0), 50), ("chase", (0.25, -1.0, 0.42), (0, 0, 0), 50), ("top", (0, -0.01, 1.3), (0, 0, 0), 50),
                                      ("side", (-1.2, 0, 0.08), (0, 0, 0), 50), ("close", (-0.35, 0.05, 0.35), (-0.08, 0.1, 0), 50), ("under", (0.4, -0.7, -0.6), (0, 0, 0), 50)):
            if os.environ.get("VIEWS") and view not in os.environ["VIEWS"].split(","): continue
            cam.location, tg.location, cam.data.lens = mid + Vector(off) * E * 1.5, mid + Vector(look) * E, lens
            sc.render.filepath = os.path.join(OUT, "%s-%s-%s.png" % (tag, name, view)); bpy.ops.render.render(write_still=True)
print("done")
