"""Render a build from cameras matched to the sheet's own views, so sheet and model line up pixel for pixel: the whole
model, and each module alone in close-up beside the same crop of the sheet. Part of the concept-to-blender skill.

    python match_views.py MAP.json ROUND_FOLDER [OUT_FOLDER]

ROUND_FOLDER holds model.blend and mesh.npz (tools/art/sheet_model.py writes both). Writes into OUT (default: ROUND):
  check.jpg           every view: sheet | model, same crop, same scale
  close-<module>.jpg  one module alone on the body (the other pieces taken off), every view cropped tight round it
                      (15% margin), at least 768 px: sheet | model. A part is judged here, never on the whole sheet.

MAP.json (the piece map, see sheet_tools.py) needs:
  cameras {view: {at: [px, py], px: pixels per model unit, right: [x, y, z], up: [x, y, z]}}
    `at` = where the model's origin (the nose tip) is drawn in that view; `px` = the whole length in pixels there.
    right / up (model axes along the picture's right and up) default by name for top, side, front and bottom; a
    three-quarter view gives its own: fit them to two far-apart landmarks (nose and wing tips).
  crops {view: [x0, y0, x1, y1]}
  modules {name: {pieces: [map ids], views: [views that show it]}}   (views optional: default every camera)
"""
import json, math, os, subprocess, sys
BLENDER = "D:/Blender/blender.exe"; HERE = os.path.abspath(__file__)
AXES = {"top": ((1, 0, 0), (0, 1, 0)), "side": ((1, 0, 0), (0, 0, 1)), "front": ((0, -1, 0), (0, 0, 1)), "bottom": ((1, 0, 0), (0, -1, 0))}


def cam_of(spec, v):
    c = spec["cameras"][v]; r, u = c.get("right", AXES.get(v, (None,))[0]), c.get("up", AXES.get(v, (None, None))[1])
    return c["at"], float(c["px"]), r, u


try:
    import bpy
except ImportError:                                     # ------------------------------ plain Python: plan, run, compose
    import numpy as np
    from PIL import Image, ImageDraw
    sys.path.insert(0, os.path.dirname(HERE)); import sheet_tools
    mp_path, rd = sys.argv[1], sys.argv[2]; out = sys.argv[3] if len(sys.argv) > 3 else rd; os.makedirs(out, exist_ok=True)
    spec = json.load(open(mp_path, encoding="utf-8")); m = np.load(os.path.join(rd, "mesh.npz")); V, T, part, mp = m["V"], m["T"], m["part"], m["map"]
    shell = sheet_tools._shells(T, len(V)); tmap = np.where(part == 0, -1, mp[part])
    near = 0.0                                          # which side of the model a three-quarter view looks at
    for v in spec["cameras"]:
        if v not in AXES: _, _, r, u = cam_of(spec, v); near = float(np.sign(np.cross(r, u)[1]))
    jobs = [dict(name="view-" + v, view=v, box=spec["crops"][v], zoom=2, keep=None) for v in spec["cameras"]]
    for name, mod in spec.get("modules", {}).items():
        tri = T[np.isin(tmap, mod["pieces"])]
        if not len(tri): print("module %s: none of its pieces are built" % name); continue
        ks = [k for k in np.unique(shell[tri[:, 0]]) if V[shell == k][:, 1].mean() * near >= -1e-4]     # the near side's copies
        P, Pall = V[np.isin(shell, ks)], V[np.unique(tri)]
        for v in mod.get("views", list(spec["cameras"])):
            at, k, r, u = cam_of(spec, v); xy = lambda Q: (at[0] + Q @ np.array(r, float) * k, at[1] - Q @ np.array(u, float) * k)
            x, y = xy(P); xa, ya = xy(Pall)             # both sides when that hardly costs zoom (a head), else the near side (a wing)
            if max(np.ptp(xa), np.ptp(ya)) <= 1.5 * max(np.ptp(x), np.ptp(y)): x, y = xa, ya
            pad = max(0.15 * max(np.ptp(x), np.ptp(y)), 6); c = spec["crops"][v]
            box = [int(max(x.min() - pad, c[0])), int(max(y.min() - pad, c[1])), int(math.ceil(min(x.max() + pad, c[2]))), int(math.ceil(min(y.max() + pad, c[3])))]
            if box[2] - box[0] < 4 or box[3] - box[1] < 4: continue
            z = min(max(2, math.ceil(768 / max(box[2] - box[0], box[3] - box[1]))), 10)
            jobs.append(dict(name="close-%s-%s" % (name, v), module=name, view=v, box=box, zoom=z, keep=mod["pieces"]))
    plan = os.path.join(out, "_match.json"); json.dump(dict(map=os.path.abspath(mp_path), mesh=os.path.abspath(os.path.join(rd, "mesh.npz")), out=os.path.abspath(out), jobs=jobs), open(plan, "w"))
    subprocess.run([BLENDER, "-b", os.path.join(rd, "model.blend"), "--python", HERE, "--", plan], check=True, stdout=subprocess.DEVNULL)
    sheet = Image.open(spec["sheet"]).convert("RGB"); F = sheet_tools._font(26)

    def page(js, path):
        rows = []
        for j in js:
            b = j["box"]; a = sheet.crop(b).resize(((b[2] - b[0]) * j["zoom"], (b[3] - b[1]) * j["zoom"]), Image.LANCZOS)
            f = os.path.join(out, j["name"] + ".png"); rows.append((j["view"], a, Image.open(f).convert("RGB")))
            if j["keep"]: os.remove(f)                   # close-ups live on their page; view-*.png stay for other checks
        W = max(a.width + r.width for _, a, r in rows) + 30; H = sum(a.height + 50 for _, a, _ in rows) + 10
        im = Image.new("RGB", (W, H), (238, 233, 221)); d = ImageDraw.Draw(im); y = 8
        for v, a, r in rows:
            d.text((10, y), "%s: sheet (left), model (right)" % v.replace("_", "-"), font=F, fill=(30, 30, 34))
            im.paste(a, (10, y + 38)); im.paste(r, (a.width + 20, y + 38)); y += a.height + 50
        im.save(path, quality=92); print(path, im.size)

    page([j for j in jobs if not j["keep"]], os.path.join(out, "check.jpg"))
    for name in spec.get("modules", {}):
        js = [j for j in jobs if j.get("module") == name]
        if js: page(js, os.path.join(out, "close-%s.jpg" % name))
    os.remove(plan); sys.exit(0)

# ---------------------------------------------------------------------------------------------- inside Blender
import bmesh
import numpy as np
from mathutils import Matrix, Vector
plan = json.load(open(sys.argv[sys.argv.index("--") + 1])); spec = json.load(open(plan["map"], encoding="utf-8"))
m = np.load(plan["mesh"]); tmap = np.where(m["part"] == 0, -1, m["map"][m["part"]])
sc = bpy.context.scene; cam = sc.camera; cam.data.type = "ORTHO"; cam.data.clip_end = 10; sun = bpy.data.objects.get("sun")
ob = next(o for o in sc.objects if o.type == "MESH")
assert len(ob.data.polygons) == len(tmap), "model.blend and mesh.npz are not the same build"
alone = {}


def only(keep):
    """A copy of the model with every piece taken off except the body and the module's own."""
    key = tuple(keep)
    if key not in alone:
        o = ob.copy(); o.data = ob.data.copy(); sc.collection.objects.link(o); bm = bmesh.new(); bm.from_mesh(o.data)
        bm.faces.ensure_lookup_table(); ok = (tmap == -1) | np.isin(tmap, keep)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if not ok[f.index]], context="FACES"); bm.to_mesh(o.data); bm.free(); alone[key] = o
    return alone[key]


for j in plan["jobs"]:
    at, k, r, u = cam_of(spec, j["view"]); r, u = Vector(r).normalized(), Vector(u).normalized(); b = r.cross(u)   # b: towards the camera
    x0, y0, x1, y1 = j["box"]; w, h = x1 - x0, y1 - y0; cx, cy = (x0 + x1) / 2 - at[0], at[1] - (y0 + y1) / 2
    cam.matrix_world = Matrix.Translation(r * cx / k + u * cy / k + b * 3) @ Matrix((r, u, b)).transposed().to_4x4()
    cam.data.ortho_scale = max(w, h) / k
    sc.render.resolution_x, sc.render.resolution_y = w * j["zoom"], h * j["zoom"]; sc.render.resolution_percentage = 100
    show = only(j["keep"]) if j["keep"] else ob
    for o in [ob] + list(alone.values()): o.hide_render = o is not show
    keep_sun = tuple(sun.rotation_euler) if sun else None
    if sun and b.z < -0.5: sun.rotation_euler = (2.53, 0, 0.52)                  # from below: lit from below, as sheets draw undersides
    sc.render.filepath = os.path.join(plan["out"], j["name"] + ".png"); bpy.ops.render.render(write_still=True)
    if sun: sun.rotation_euler = keep_sun
