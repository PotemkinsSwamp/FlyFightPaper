"""Cut the Meshy weapon models into the pieces the game animates, sized and turned like plane A.

Run: D:/Blender/blender.exe -b --factory-startup --python-exit-code 1 --python tools/art/weapons.py [-- NAME...]
Reads assets/models/toys/weapon-NAME/meshy.glb. Writes, per weapon, weapon-NAME/parts/<piece>.fbx,
weapon-NAME/pieces.json and weapon-NAME/pieces.png (assembled + exploded review render).

Meshy fuses everything into one shell, so each face goes to the first piece whose rule matches its centre (glb
frame: X long axis, Z up) or its texture colour; the rest is the static body. All pieces share the weapon's Meshy
maps. Axes in pieces.json are Roblox (X right, Y up, -Z forward = muzzle), studs, centred on the weapon's box;
"mount" is where it clips to the plane. Roles: static, fire (leaves when shot, comes back on reload), spin (about
"axis" through "pivot"), hinge (swings about "axis" through "pivot"), slide (moves along "axis"), snap (springs
forward), drop (falls, then flies).
"""
import json, math, sys
from pathlib import Path

import bmesh, bpy, numpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
TOYS = ROOT / "assets/models/toys"


def pink(c): return c[0] > c[1] + .12 and c[0] > c[2] + .04
def blue(c): return c[2] > c[0] + .05
def green(c): return c[1] > c[0] + .03 and c[1] > c[2]
def band(c): return c[0] > .35 and c[0] - c[2] > .25 and c[1] < c[0] * .62      # brown-red rubber
def in_ball(p, centre, r): return (p - Vector(centre)).length < r


# front = which glb X end the muzzle is at; length = studs along the barrel (tune in Studio).
WEAPONS = {
    "pellet": dict(front=-1, length=3.2, mount="bottom", pieces=[
        ("pellet", "fire", lambda p, c: in_ball(p, (.83, 0, .13), .155), None)]),
    "staple": dict(front=1, length=3.4, mount="top", pieces=[
        ("staple", "fire", lambda p, c: p.x > .76 and abs(p.y) < .08 and -.12 < p.z < -.03, None),
        ("strip", "slide", lambda p, c: p.x < -.62, dict(axis=(1, 0, 0))),
        ("lever", "hinge", lambda p, c: p.z > .15 and p.x < -.12, dict(pivot=(-.24, 0, .13), axis=(0, 1, 0)))]),
    "paperclip": dict(length=3.8, mount="bottom", build="railgun", pieces=[]),
    "gatling-b": dict(length=4.2, mount="top", build="gatling", pieces=[
        ("body", "static", None, None),
        ("drum", "spin", None, dict(pivot=(0, .57, 0), axis=(0, 1, 0))),
        ("crank", "spin", None, dict(pivot=(0, -1.27, 0), axis=(0, 1, 0))),
        ("band", "fire", None, None)]),
    "eraser": dict(length=4.0, mount="top", build="clip", pieces=[
        ("body", "static", None, None),
        ("missile", "drop", None, None)]),
    "pencil-b": dict(length=4.6, mount="top", build="slingshot", pieces=[
        ("body", "static", None, None),
        ("band", "snap", None, None),
        ("pencil", "fire", None, None)]),
}


def load(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(TOYS / f"weapon-{name}/meshy.glb"))
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    for o in list(bpy.context.scene.objects):
        if o is not obj: bpy.data.objects.remove(o)
    obj.data.transform(obj.matrix_world); obj.matrix_world = Matrix()
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(obj.data); bm.free()
    bsdf = next(n for n in obj.data.materials[0].node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    return obj, bsdf.inputs["Base Color"].links[0].from_node.image


def colours(obj, image):
    w, h = image.size; px = numpy.empty(w * h * 4, numpy.float32); image.pixels.foreach_get(px)
    uv = obj.data.uv_layers.active.data
    out = []
    for poly in obj.data.polygons:
        u = sum(uv[i].uv.x for i in poly.loop_indices) / poly.loop_total % 1
        v = sum(uv[i].uv.y for i in poly.loop_indices) / poly.loop_total % 1
        k = (int(v * (h - 1)) * w + int(u * (w - 1))) * 4
        out.append(px[k:k + 3])
    return out


def split(obj, image, spec):
    cols = colours(obj, image)
    owner = []
    for poly, col in zip(obj.data.polygons, cols):
        owner.append(next((name for name, _, rule, _ in spec["pieces"] if rule(Vector(poly.center), col)), "body"))
    pieces = {}
    for name in sorted(set(owner)):
        bm = bmesh.new(); bm.from_mesh(obj.data); bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if owner[f.index] != name], context="FACES")
        if name != "delete":
            mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh)
            mesh.materials.append(obj.data.materials[0])
            piece = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(piece)
            pieces[name] = piece
        bm.free()
    bpy.data.objects.remove(obj)
    return pieces


def box(bm, lo, hi):
    verts = bmesh.ops.create_cube(bm, size=1)["verts"]
    bmesh.ops.scale(bm, vec=Vector(hi) - Vector(lo), verts=verts)
    bmesh.ops.translate(bm, vec=(Vector(lo) + Vector(hi)) / 2, verts=verts)
    return bm


def tube(bm, pts, r, sides=8, tip=0):
    """Round tube along pts (closed at the end; a point of length `tip` at the start)."""
    pts = [Vector(q) for q in pts]; rings = []
    for i, q in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = d.cross(Vector((0, 0, 1))).normalized() if abs(d.z) < .9 else d.cross(Vector((1, 0, 0))).normalized()
        b = d.cross(a)
        rings.append([bm.verts.new(q + (a * math.cos(t) + b * math.sin(t)) * r) for t in (2 * math.pi * k / sides for k in range(sides))])
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(sides): bm.faces.new((r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]))
    if tip:
        point = bm.verts.new(pts[0] + (pts[0] - pts[1]).normalized() * tip)
        for k in range(sides): bm.faces.new((rings[0][(k + 1) % sides], rings[0][k], point))
    else: bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    return bm


def railgun():
    """The paperclip railgun from plain shapes, in studs, muzzle +Y, lying flat (Meshy fused the wire into a blade).
    Same look as the approved picture: grey base, two orange rails, copper coils, black battery, unbent clip."""
    parts = {}
    def add(name, bm, rgb, material="SmoothPlastic"):
        mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh); bm.free()
        obj = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(obj)
        parts[name] = (obj, rgb, material)
    add("body", box(bmesh.new(), (-.38, -1.9, 0), (.38, 1.75, .12)), [120, 122, 126])
    rails = box(box(bmesh.new(), (-.31, -1.4, .12), (-.17, 1.75, .28)), (.17, -1.4, .12), (.31, 1.75, .28))
    add("rails", rails, [232, 126, 52])
    coils = bmesh.new()
    for x in (-.24, .24):
        for y in (-.75, .85):
            turns = [(x + .13 * math.cos(t), y - .14 + .07 * t / (2 * math.pi), .2 + .13 * math.sin(t))
                     for t in (2 * math.pi * j / 7 for j in range(4 * 7 + 1))]   # 4 turns of wire round the rail
            tube(coils, turns, .024, sides=4)
    add("coils", coils, [196, 112, 62], "Metal")
    add("battery", box(bmesh.new(), (-.36, -1.9, .12), (.36, -1.45, .5)), [30, 30, 32])
    wire = [(0, -1.3, .17), (.025, -.8, .17), (-.02, -.3, .17), (.03, .25, .17), (-.012, .9, .17), (0, 1.75, .17)]
    add("wire", tube(bmesh.new(), wire[::-1], .035, tip=.22), [205, 205, 210], "Metal")
    return parts


def paint(bm, rgb, shape, *args, **kwargs):
    """Colour only the new shape's corners. FBX carries these flat colours without an image."""
    before = set(bm.faces)
    shape(bm, *args, **kwargs)
    layer = bm.loops.layers.float_color.get("Color") or bm.loops.layers.float_color.new("Color")
    rgba = (*[(v / 255) ** 2.2 for v in rgb], 1)
    for face in set(bm.faces) - before:
        for loop in face.loops: loop[layer] = rgba
    return bm


def plain_piece(name, bm, rgb, material="SmoothPlastic"):
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(obj)
    # White is the MeshPart tint for pieces whose individual shapes have vertex colours.
    return obj, rgb, material


def collar(bm, y0, y1, outer, inner, sides=8):
    """Open ring around the +Y barrel axis, rather than a solid cap."""
    rings = [[bm.verts.new((r * math.cos(t), y, r * math.sin(t)))
              for t in (2 * math.pi * k / sides for k in range(sides))]
             for y, r in ((y0, outer), (y1, outer), (y0, inner), (y1, inner))]
    for k in range(sides):
        j = (k + 1) % sides
        for a, b in ((0, 1), (1, 3), (3, 2), (2, 0)):
            bm.faces.new((rings[a][k], rings[a][j], rings[b][j], rings[b][k]))
    return bm


def ribbon(bm, pts, width, thickness):
    """One closed flat rubber loop. Points follow its centre, with no filled-in middle."""
    pts = [Vector(p) for p in pts]; rings = []
    for i, p in enumerate(pts):
        d = (pts[(i + 1) % len(pts)] - pts[i - 1]).normalized()
        across = Vector((-d.y, d.x, 0)).normalized() * width / 2
        up = Vector((0, 0, thickness / 2))
        rings.append([bm.verts.new(p + a * across + b * up) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    for i, ring in enumerate(rings):
        next_ring = rings[(i + 1) % len(rings)]
        for k in range(4):
            j = (k + 1) % 4
            bm.faces.new((ring[k], ring[j], next_ring[j], next_ring[k]))
    return bm


def gatling():
    """Rubber-band repeater, in studs, muzzle +Y; the drum stays concentric with its spin axis."""
    black, red, blue, green, yellow = [27, 29, 32], [220, 43, 42], [25, 139, 219], [36, 165, 83], [249, 200, 42]
    body = paint(bmesh.new(), black, box, (-.43, -1.64, -.43), (.43, -.90, .43))
    paint(body, black, collar, -.96, -.76, .65, .53)
    paint(body, blue, tube, [(.42, -1.26, 0), (.68, -1.26, 0)], .065)
    paint(body, blue, tube, [(.51, -1.26, -.03), (.51, -1.26, -.32)], .055)

    drum = bmesh.new()
    for k in range(8):
        t = 2 * math.pi * k / 8
        x, z = .47 * math.cos(t), .47 * math.sin(t)
        rgb = (red, blue, green, yellow)[k % 4]
        paint(drum, rgb, tube, [(x, -.88, z), (x, 1.80, z)], .10)
        paint(drum, rgb, tube, [(x, 1.84, z), (x, 2.02, z)], .105)
        # Each stretched band runs down the outside, then turns inward over its end anchors.
        band_pts = [(x, 1.98, z), (.605 * math.cos(t), 1.84, .605 * math.sin(t)),
                    (.605 * math.cos(t), -.78, .605 * math.sin(t)), (x, -.88, z)]
        paint(drum, (yellow, blue, red)[k % 3], tube, band_pts, .018, sides=6)
    paint(drum, red, tube, [(0, 1.72, 0), (0, 1.84, 0)], .60)
    paint(drum, green, collar, .44, .58, .58, .51)
    paint(drum, black, tube, [(0, -.88, 0), (0, 1.72, 0)], .07)

    crank = paint(bmesh.new(), [190, 196, 204], tube, [(0, -1.84, 0), (0, -1.64, 0)], .075)
    paint(crank, [190, 196, 204], box, (-.065, -1.88, -.07), (.065, -1.78, .55))
    paint(crank, red, tube, [(0, -2.10, .52), (0, -1.76, .52)], .105)

    # A separate stretched oval, not the drum's loaded strands: it must read by itself in flight.
    loop = [(.165 * math.cos(t), 1.745 + .33 * math.sin(t), .64)
            for t in (2 * math.pi * k / 16 for k in range(16))]
    return {"body": plain_piece("body", body, [255, 255, 255]),
            "drum": plain_piece("drum", drum, [255, 255, 255]),
            "crank": plain_piece("crank", crank, [255, 255, 255], "Metal"),
            "band": plain_piece("band", ribbon(bmesh.new(), loop, .05, .022), [246, 173, 43])}


def slingshot():
    """Symmetric ruler-and-clip pencil launcher, in studs, muzzle +Y, pencil on X=0."""
    wood, green, tape = [200, 163, 110], [37, 91, 63], [231, 218, 174]
    body = paint(bmesh.new(), wood, box, (-.35, -2.30, 0), (.35, 2.30, .16))
    # Geometric ruler ticks on both edges, kept clear of the central pencil and clip.
    for k in range(25):
        y = -2.16 + k * .18
        extent = .105 if k % 5 == 0 else .055
        for side in (-1, 1):
            x0, x1 = sorted((side * (.34 - extent), side * .34))
            paint(body, [92, 65, 37], box, (x0, y - .008, .16), (x1, y + .008, .168))
    paint(body, green, box, (-.29, -2.04, .16), (.29, .55, .38))
    for side in (-1, 1):
        x0, x1 = sorted((side * .20, side * .31))
        paint(body, green, box, (x0, -1.20, .38), (x1, .55, .58))
        for y in (-.53, .44):
            hook = [(side * .28, y - .08, .54), (side * .43, y - .08, .54),
                    (side * .47, y, .54), (side * .43, y + .10, .54), (side * .34, y + .10, .54)]
            paint(body, green, tube, hook, .038, sides=6)
    # Tape wraps completely around the ruler and rear clip; its top is behind the pencil's tail.
    for lo, hi in (((-.37, -1.85, -.018), (.37, -1.49, 0)),
                   ((-.37, -1.85, 0), (-.35, -1.49, .40)),
                   ((.35, -1.85, 0), (.37, -1.49, .40)),
                   ((-.37, -1.85, .38), (.37, -1.49, .40))):
        paint(body, tape, box, lo, hi)
    for lo, hi in (((-.22, -1.42, .38), (-.15, -1.10, .72)),
                   ((.15, -1.42, .38), (.22, -1.10, .72)),
                   ((-.22, -1.42, .72), (.22, -1.10, .81))):
        paint(body, green, box, lo, hi)

    band_pts = [(0, -1.10, .56), (-.16, -1.05, .56), (-.24, -.88, .56),
                (-.43, -.53, .56), (-.43, .44, .56), (-.24, .57, .74), (0, .58, .76),
                (.24, .57, .74), (.43, .44, .56), (.43, -.53, .56), (.24, -.88, .56), (.16, -1.05, .56)]
    rubber = ribbon(bmesh.new(), band_pts, .045, .025)
    pencil = paint(bmesh.new(), [238, 162, 37], tube, [(0, 1.67, .56), (0, -1.02, .56)], .175, sides=6)
    for rgb, y, depth, r0, r1 in (([219, 183, 129], 1.87, .40, .175, .035),
                                  ([43, 44, 46], 2.125, .11, .035, 0)):
        transform = (Matrix.Translation((0, y, .56)) @ Matrix.Rotation(-math.pi / 2, 4, "X")
                     @ Matrix.Rotation(math.pi / 6, 4, "Z"))
        paint(pencil, rgb, bmesh.ops.create_cone, cap_ends=True, cap_tris=False, segments=6,
              radius1=r0, radius2=r1, depth=depth, matrix=transform)
    return {"body": plain_piece("body", body, [255, 255, 255]),
            "band": plain_piece("band", rubber, [140, 81, 37]),
            "pencil": plain_piece("pencil", pencil, [255, 255, 255])}


def clip():
    """Binder clip above a pink eraser-cap rocket, in studs, muzzle +Y, barrel on X=Z=0."""
    black, silver, pink, navy = [25, 27, 30], [190, 196, 204], [232, 120, 130], [35, 45, 95]

    def slab(bm, pts, thickness):
        offset = Vector(thickness) / 2
        rings = [[bm.verts.new(Vector(p) + sign * offset) for p in pts] for sign in (-1, 1)]
        bm.faces.new(rings[0][::-1]); bm.faces.new(rings[1])
        for k in range(len(pts)):
            j = (k + 1) % len(pts)
            bm.faces.new((rings[0][k], rings[0][j], rings[1][j], rings[1][k]))
        return bm

    # A bent spring-steel sheet, open underneath: its sloping sides clear the round missile.
    profile = [(-.51, .24), (-.095, .80), (-.065, .815), (.065, .815), (.095, .80),
               (.51, .24), (.455, .22), (.055, .765), (-.055, .765), (-.455, .22)]
    body = paint(bmesh.new(), black, slab, [(x, 0, z) for x, z in profile], (0, 1.4, 0))
    for side in (-1, 1):
        for y0, y1 in ((-.70, -.42), (.42, .70)):
            paint(body, [31, 34, 38], tube, [(side * .50, y0, .24), (side * .50, y1, .24)], .072)
        # Each handle is one open wire loop with two ends seated in the rolled black jaws.
        outline = [(-.61, .24), (-.42, .79), (-.27, 1.28), (-.30, 1.47), (-.44, 1.70),
                   (-.43, 1.79), (-.32, 1.89), (-.16, 1.96), (0, 1.99), (.16, 1.96),
                   (.32, 1.89), (.43, 1.79), (.44, 1.70), (.30, 1.47), (.27, 1.28),
                   (.42, .79), (.61, .24)]
        handle = [(side * (.50 if z < .3 else .55), y, z) for y, z in outline]
        paint(body, silver, tube, handle, .033, sides=6)

    missile = paint(bmesh.new(), pink, collar, -1.91, 1.12, .45, .30)
    # The rear stays genuinely open, with a darker rim, inner wall and recessed end of the cavity.
    paint(missile, [208, 92, 106], collar, -2.0, -1.91, .45, .30)
    paint(missile, [150, 57, 73], collar, -1.995, -1.43, .301, .29)
    paint(missile, [112, 39, 53], tube, [(0, -1.44, 0), (0, -1.42, 0)], .30)
    nose = Matrix.Translation((0, 1.56, 0)) @ Matrix.Rotation(-math.pi / 2, 4, "X")
    paint(missile, pink, bmesh.ops.create_cone, cap_ends=True, cap_tris=False, segments=8,
          radius1=.45, radius2=0, depth=.88, matrix=nose)
    # Four thin paper fins form a + around the barrel, wholly behind the clip.
    for k in range(4):
        t = k * math.pi / 2
        pts = [(r * math.cos(t), y, r * math.sin(t))
               for r, y in ((.40, -1.90), (.84, -1.90), (.84, -1.37), (.40, -.91))]
        paint(missile, navy, slab, pts, (-.035 * math.sin(t), 0, .035 * math.cos(t)))
    return {"body": plain_piece("body", body, [255, 255, 255]),
            "missile": plain_piece("missile", missile, [255, 255, 255])}


def bounds(objs):
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
    return lo, hi


def to_roblox(p): return [round(p[0], 4), round(p[2], 4), round(-p[1], 4)]


def build(name):
    spec = WEAPONS[name]
    plain = {}
    if spec.get("build"):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        plain = {"railgun": railgun, "gatling": gatling, "slingshot": slingshot, "clip": clip}[spec["build"]]()
        pieces = {k: v[0] for k, v in plain.items()}
        lo, hi = bounds(pieces.values()); frame = Matrix.Translation(-(lo + hi) / 2)
    else:
        obj, image = load(name)
        glb_lo, glb_hi = bounds([obj])
        pieces = split(obj, image, spec)
        # glb frame -> Blender plane frame (muzzle along +Y, which is Roblox -Z), scaled to studs, centred on the box.
        turn = Matrix.Rotation(math.pi / 2 * spec["front"], 4, "Z")
        scale = spec["length"] / (glb_hi.x - glb_lo.x)
        frame = Matrix.Scale(scale, 4) @ turn @ Matrix.Translation(-(glb_lo + glb_hi) / 2)
    for o in pieces.values(): o.data.transform(frame)
    lo, hi = bounds(pieces.values())
    out = TOYS / f"weapon-{name}" / "parts"; out.mkdir(exist_ok=True)
    for old in out.glob("*.fbx"): old.unlink()
    rows = []
    for pname, o in pieces.items():
        plo, phi = bounds([o]); c = (plo + phi) / 2
        o.data.transform(Matrix.Translation(-c))
        bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.export_scene.fbx(filepath=str(out / f"{pname}.fbx"), use_selection=True, object_types={"MESH"},
                                 global_scale=.01, apply_unit_scale=False, apply_scale_options="FBX_SCALE_NONE",
                                 axis_forward="-Z", axis_up="Y", bake_space_transform=True, use_triangles=True,
                                 mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False, path_mode="STRIP",
                                 embed_textures=False)
        o.data.transform(Matrix.Translation(c))
        role, extra = next(((r, e) for n, r, _, e in spec["pieces"] if n == pname), ("fire" if pname == "wire" else "static", None))
        row = dict(piece=pname, file=f"parts/{pname}.fbx", role=role, centre=to_roblox(c),
                   size=[round(abs(v), 4) for v in to_roblox(phi - plo)], triangles=sum(len(p.vertices) - 2 for p in o.data.polygons),
                   textured=pname not in plain)
        if pname in plain: row.update(color=plain[pname][1], material=plain[pname][2])
        for key in ("pivot", "axis"):
            if extra and key in extra:
                v = frame @ Vector(extra[key]) if key == "pivot" else (frame.to_3x3() @ Vector(extra[key])).normalized()
                row[key] = to_roblox(v)
        rows.append(row)
    mount_y = hi.z if spec["mount"] == "top" else lo.z
    manifest = dict(weapon=name, length_studs=spec["length"], size=[round(abs(v), 4) for v in to_roblox(hi - lo)],
                    mount=dict(side=spec["mount"], point=to_roblox(Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, mount_y)))),
                    maps={} if plain else {k: f"meshy-{k}.png" for k in ("base_color", "normal", "roughness", "metallic")}, pieces=rows)
    (TOYS / f"weapon-{name}" / "pieces.json").write_text(json.dumps(manifest, indent=2) + "\n")
    review(name)
    print("WEAPON", name, {r["piece"]: r["triangles"] for r in rows})


def review(name):
    """Re-import the exported pieces at their manifest places and render them: left as fitted, right with the
    moving pieces lifted (FBX re-imports at 1/100 scale, hence the 100). This is exactly what Roblox gets."""
    D = f"{TOYS.as_posix()}/weapon-{name}/"
    man = json.load(open(D + "pieces.json"))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    tex = None
    if man["maps"]:
        img = bpy.data.images.load(D + "meshy-base_color.png"); tex = bpy.data.materials.new("tex"); tex.use_nodes = True
        t = tex.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img
        tex.node_tree.links.new(t.outputs[0], tex.node_tree.nodes["Principled BSDF"].inputs[0])
    objs = []
    for r in man["pieces"]:
        before = set(sc.objects); bpy.ops.import_scene.fbx(filepath=D + r["file"]); o = (set(sc.objects) - before).pop()
        c = r["centre"]; o.location = (c[0], -c[2], c[1]); o.scale = (100 * o.scale[0],) * 3 if o.scale[0] < .1 else o.scale
        o.data.materials.clear()
        if r.get("color"):
            m = bpy.data.materials.new(r["piece"]); m.use_nodes = True
            bsdf = m.node_tree.nodes["Principled BSDF"]
            bsdf.inputs[0].default_value = (*[(v / 255) ** 2.2 for v in r["color"]], 1)
            if o.data.color_attributes:
                vertex = m.node_tree.nodes.new("ShaderNodeVertexColor")
                vertex.layer_name = o.data.color_attributes[0].name
                m.node_tree.links.new(vertex.outputs["Color"], bsdf.inputs[0])
            bsdf.inputs["Metallic"].default_value = .7 if r.get("material") == "Metal" else 0
            o.data.materials.append(m)
        else: o.data.materials.append(tex)
        objs.append((o, r))
    sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1400, 700
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (.6, .6, .58, 1)
    sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN")); sun.data.energy = 4; sun.rotation_euler = (.6, .2, .8); sc.collection.objects.link(sun)
    L = man["length_studs"]
    # Show the eraser's open tail as well as its cone; other weapons keep their muzzle-side view.
    view = Vector((-4, -2.5, 3) if name == "eraser" else (-4, 2.5, 3))
    beside = Vector((-view.y, view.x, 0)).normalized() * L * 1.3
    for o, r in objs:   # second copy beside it with the moving pieces lifted
        t = o.copy(); sc.collection.objects.link(t)
        lift = 0 if r["role"] == "static" else L * {"fire": .5, "snap": .2}.get(r["role"], .3)
        if name == "eraser" and r["role"] == "drop": lift = man["size"][1] + .35
        t.location = o.location + beside + Vector((0, 0, lift))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); cam.data.type = "ORTHO"; cam.data.ortho_scale = L * (3 if name == "eraser" else 2.6)
    sc.collection.objects.link(cam); sc.camera = cam
    target = beside / 2 + Vector((0, 0, L * (.20 if name == "eraser" else .15))); cam.location = target + view.normalized() * 40; cam.data.clip_end = 200
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = D + "pieces.png"; bpy.ops.render.render(write_still=True)


names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(WEAPONS)
for n in names: build(n)
