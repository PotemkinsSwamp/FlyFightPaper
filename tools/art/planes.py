"""Build the texture-free Classic Dart in Blender background mode.

PowerShell, from the repository root:
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/planes.py

Only this script and assets/models/planes/ are written. No network,
uploads, Studio changes, external packages, or texture images are used.
Coordinates in construction functions are Roblox studs: X right, Y up,
-Z forward. Conversion to Blender (X, -Z, Y) occurs at mesh creation.
"""

import hashlib
import json
import math
import struct
import zlib
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from io_scene_fbx import parse_fbx


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/models/planes/classic"
STICKERS_OUT = ROOT / "assets/models/planes/stickers"
REFERENCE = ROOT / "assets/models/planes/concepts/pilot/option-a.png"
LENGTH = 15.3
TOP_LENGTH_PX = 452
SCALE = LENGTH / TOP_LENGTH_PX
SIDE_NORMALIZATION = TOP_LENGTH_PX / 575
PAPER = (238, 230, 212)
RED = (206, 48, 43)
BLUE = (40, 91, 172)
TAPE = (214, 200, 160)
WHITE = (250, 250, 247)
STICKER_THICKNESS = .04
STICKER_TOP_OFFSET = .06
STICKER_SHAPES = ("sticker-square", "sticker-circle")
OBJECTS = []
MATS = {}
FBX_NAMES = ("body-paper", "nose-paper", "nose-accent", "wings-paper", "wings-accent",
             "wings-sticker-left", "wings-sticker-right", "tail-paper", "tail-accent",
             "pellet-tube", "pellet-band")
DISPLAY_NAMES = {"body":"Classic Fold", "nose":"Classic Nose", "wings":"Classic Wings",
                 "tail":"Classic Tail", "pellet":"Paper Pellet Gun"}
NOSE_TIP = -LENGTH / 2
NOSE_BACK = NOSE_TIP + 149 * SCALE
BODY_BACK = NOSE_BACK + 237 * SCALE
TAIL_BACK = LENGTH / 2
SPAN = 402 * SCALE
BODY_HALF_WIDTH = 1.30
BODY_BOTTOM = -.85
BODY_SHOULDER = .95
BODY_SPINE = 1.40
FIN_TOP = BODY_BOTTOM + 141 * LENGTH / 575
GUN_X, GUN_Y = 1.76, .08
GUN_LENGTH, GUN_DIAMETER = 117 * LENGTH / 575, 31 * LENGTH / 575
GUN_FRONT = -2.87
GUN_CENTER_Z = GUN_FRONT + GUN_LENGTH / 2
THREEQUARTER_CAMERA = (-10.584213, 21.518354, 13.784560)
THREEQUARTER_TARGET = (0, 0, .5)
THREEQUARTER_SCALE = 28.546875
THREEQUARTER_ROLL = .214796
THREEQUARTER_LENS = 34.905698

# Hand-read silhouette landmarks in the original 1600 x 1001 reference.
# The artwork is not an engineering drawing. Side pixels are normalized
# to the top-view length BEFORE using the single stud-per-pixel scale.
MEASUREMENTS = [
    ("Overall length, top", "y=493 to 945", 452, 452, LENGTH),
    ("Visible nose allocation", "y=493 to 642", 149, 149, 149 * SCALE),
    ("Visible body allocation", "y=642 to 879", 237, 237, 237 * SCALE),
    ("Visible tail allocation", "y=879 to 945", 66, 66, 66 * SCALE),
    ("Wing span, top", "x=600 to 1002", 402, 402, 402 * SCALE),
    ("Wing fore/aft extent, top", "y=642 to 879", 237, 237, 237 * SCALE),
    ("Sticker diameter, top", "x=680 to 735 (left)", 55, 55, 55 * SCALE),
    ("Wing tip stripe width", "x=624 to 652 (left)", 28, 28, 28 * SCALE),
    ("Tail base span, top", "x=778 to 825", 47, 47, 47 * SCALE),
    ("Overall length, side", "x=24 to 599", 575, 575 * SIDE_NORMALIZATION, LENGTH),
    ("Overall height, side", "y=669 to 810", 141, 141 * SIDE_NORMALIZATION, 141 * SIDE_NORMALIZATION * SCALE),
    ("Fin rise, side", "y=669 to 729", 60, 60 * SIDE_NORMALIZATION, 60 * SIDE_NORMALIZATION * SCALE),
    ("Tube length, side", "x=184 to 301", 117, 117 * SIDE_NORMALIZATION, 117 * SIDE_NORMALIZATION * SCALE),
    ("Tube diameter, side", "y=763 to 794", 31, 31 * SIDE_NORMALIZATION, 31 * SIDE_NORMALIZATION * SCALE),
    ("Body shoulders at wing root", "about 1/5 of measured span; brief", 77, 77, 2.60),
    ("Body depth, shoulder to V keel", "round-2 brief, 1.6-1.9", "brief", 1.80 / SCALE, 1.80),
    ("Body depth including raised spine", "side front, y=721 to 805; folded ridge included", 84, 84*SIDE_NORMALIZATION, 84*LENGTH/575),
]


def log(message):
    print("CLASSIC " + message, flush=True)


def to_blender(p):
    return Vector((p[0], -p[2], p[1]))


def to_roblox(p):
    return (p[0], p[2], -p[1])


def rounded(p):
    return [round(float(v), 6) for v in p]


def measurements_text():
    assert sum(row[4] for row in MEASUREMENTS[1:4]) == LENGTH
    assert abs(MEASUREMENTS[4][4] - 13.6075221239) < 1e-8
    lines = ["| Measure | Reference landmarks | Raw pixels | Normalized pixels | Studs |",
             "|---|---|---:|---:|---:|"]
    lines += [f"| {name} | {landmark} | {raw} | {normalized:.3f} | {studs:.4f} |"
              for name, landmark, raw, normalized, studs in MEASUREMENTS]
    return "\n".join(lines)


def write_measurement_plan():
    # Written and checked before the first vertex is created.
    text = "# Classic Dart measurement plan\n\n" + measurements_text()
    text += f"\n\nOne scale: 15.3 / 452 = {SCALE:.9f} studs per normalized pixel. "
    text += "Side-view normalization: 452 / 575.\n"
    text += "Visible allocation check: 149 + 237 + 66 = 452 pixels; nose + body + tail = 15.3000 studs.\n"
    text += "Measured wing span: 402 pixels = 13.6075 studs.\n"
    text += "\nRound 2 uses the concept and brief alone. No legacy template bounds, centres or rotations constrain the model.\n"
    (OUT / "README.md").write_text(text, encoding="utf-8")
    log("Measured proportions checked and written before modeling")


def material(name, rgb):
    mat = bpy.data.materials.new(name)
    linear = lambda v: v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    mat.diffuse_color = tuple(linear(v/255) for v in rgb) + (1,)
    # No shader nodes, images, UV layers, or texture slots. Roblox Color3
    # recommendations are the unambiguous colour source in parts.json.
    mat.use_nodes = False
    MATS[name] = mat
    return mat


def mesh(name, verts, faces, mat, part, region):
    data = bpy.data.meshes.new(name)
    data.from_pydata([to_blender(v) for v in verts], [], faces)
    data.update()
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-7)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(MATS[mat])
    for face in data.polygons:
        face.use_smooth = False
    obj["part"], obj["region"] = part, region
    OBJECTS.append(obj)
    return obj


def merge(objects, name, union=False):
    base = objects[0]
    if union:
        for other in objects[1:]:
            bpy.ops.object.select_all(action="DESELECT")
            base.select_set(True)
            bpy.context.view_layer.objects.active = base
            mod = base.modifiers.new("Connected paper folds", "BOOLEAN")
            mod.operation, mod.solver, mod.object = "UNION", "EXACT", other
            bpy.ops.object.modifier_apply(modifier=mod.name)
            OBJECTS.remove(other)
            bpy.data.objects.remove(other, do_unlink=True)
    else:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = base
        bpy.ops.object.join()
        for obj in objects[1:]:
            OBJECTS.remove(obj)
    base.name, base.data.name = name, name
    return base


def inset_polygon(points, thickness):
    """Parallel inset of a convex XY polygon, independent of winding."""
    pts = [np.array(p, dtype=float) for p in points]
    area = sum(pts[(i+1)%len(pts)][0]*pts[i][1]-pts[(i+1)%len(pts)][1]*pts[i][0] for i in range(len(pts)))
    winding = -1 if area > 0 else 1
    lines = []
    for a, b in zip(pts, pts[1:] + pts[:1]):
        edge = b - a
        normal = winding * np.array([-edge[1], edge[0]]) / np.linalg.norm(edge)
        lines.append((a + normal * thickness, edge))
    result = []
    for i, (p, d) in enumerate(lines):
        q, e = lines[i - 1]
        u = np.linalg.solve(np.column_stack((d, -e)), q - p)[0]
        result.append(tuple(p + u * d))
    return result


def shell_sections(name, sections, thickness, mat, part, region):
    """Sealed annular paper shell along Z, including both end rims."""
    n = len(sections[0][1])
    verts = []
    for z, profile in sections:
        inner = inset_polygon(profile, thickness)
        verts += [(x, y, z) for x, y in profile + inner]
    faces = []
    for k in range(len(sections) - 1):
        a, b = k * 2 * n, (k + 1) * 2 * n
        for j in range(n):
            t = (j + 1) % n
            faces += [(a+j, a+t, b+t, b+j), (a+n+j, b+n+j, b+n+t, a+n+t)]
    for k in (0, len(sections) - 1):
        a = k * 2 * n
        faces += [(a+j, a+n+j, a+n+(j+1)%n, a+(j+1)%n) for j in range(n)]
    return mesh(name, verts, faces, mat, part, region)


def sealed_tip_shell(name, sections, inner_start, thickness, mat, part, region):
    """A solid front transitioning into a hollow rear, one closed topology."""
    n=len(sections[0][1]); outer_count=len(sections)
    verts=[(x,y,z) for z,profile in sections for x,y in profile]
    faces=[tuple(reversed(range(n)))]
    for k in range(outer_count-1):
        faces += [(k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j) for j in range(n)]
    for z,profile in sections[inner_start:]:
        verts += [(x,y,z) for x,y in inset_polygon(profile,thickness)]
    first=outer_count*n
    for k in range(outer_count-inner_start-1):
        a,b=first+k*n,first+(k+1)*n
        faces += [(a+j,b+j,b+(j+1)%n,a+(j+1)%n) for j in range(n)]
    faces.append(tuple(range(first,first+n)))
    outer_back=(outer_count-1)*n
    inner_back=(outer_count+outer_count-inner_start-1)*n
    faces += [(outer_back+j,outer_back+(j+1)%n,inner_back+(j+1)%n,inner_back+j) for j in range(n)]
    return mesh(name,verts,faces,mat,part,region)


def clip(poly, axis, limit, above):
    result = []
    for a, b in zip(poly, poly[1:] + poly[:1]):
        a_in = (a[axis] >= limit - 1e-9) if above else (a[axis] <= limit + 1e-9)
        b_in = (b[axis] >= limit - 1e-9) if above else (b[axis] <= limit + 1e-9)
        if a_in:
            result.append(a)
        if a_in != b_in:
            ratio = (limit - a[axis]) / (b[axis] - a[axis])
            result.append(tuple(a[j] + ratio * (b[j] - a[j]) for j in range(2)))
    dedup = []
    for p in result:
        if not dedup or np.linalg.norm(np.array(p) - dedup[-1]) > 1e-7:
            dedup.append(p)
    if len(dedup) > 1 and np.linalg.norm(np.array(dedup[0]) - dedup[-1]) < 1e-7:
        dedup.pop()
    return dedup


WING_LEVELS = [(-SPAN/2, .97), (-5.94, .95), (-1.30, .88),
               (-1.00, .95), (0, .95), (1.00, .95), (1.30, .88),
               (5.94, .95), (SPAN/2, .97)]


def wing_height(x, z):
    return float(np.interp(x, [p[0] for p in WING_LEVELS], [p[1] for p in WING_LEVELS]))


def slab(name, polygon, height, thickness, mat, part, region, splits=()):
    """Closed paper sheet with shared crease vertices, no zero-thickness faces."""
    xs = sorted(set([min(p[0] for p in polygon), max(p[0] for p in polygon)] + list(splits)))
    pieces = []
    for left, right in zip(xs, xs[1:]):
        poly = clip(clip(polygon, 0, left, True), 0, right, False)
        if len(poly) >= 3:
            pieces.append(poly)
    verts, top, bottom = [], [], []
    for poly in pieces:
        top_ids, bottom_ids = [], []
        for x, z in poly:
            top_ids.append(len(verts)); verts.append((x, height(x, z), z))
            bottom_ids.append(len(verts)); verts.append((x, height(x, z) - thickness, z))
        top.append(tuple(top_ids)); bottom.append(tuple(reversed(bottom_ids)))
    # Every exterior edge is split at exactly the same crease X coordinates.
    boundary = []
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        boundary.append(a)
        ts = [(x-a[0])/(b[0]-a[0]) for x in xs if abs(b[0]-a[0]) > 1e-9]
        boundary += [tuple(a[j]+t*(b[j]-a[j]) for j in range(2)) for t in sorted(ts) if 1e-8 < t < 1-1e-8]
    sides = []
    for a, b in zip(boundary, boundary[1:] + boundary[:1]):
        i = len(verts)
        verts += [(a[0], height(*a), a[1]), (b[0], height(*b), b[1]),
                  (b[0], height(*b)-thickness, b[1]), (a[0], height(*a)-thickness, a[1])]
        sides.append((i, i+1, i+2, i+3))
    return mesh(name, verts, top + bottom + sides, mat, part, region)


def profile_x(name, points, width, mat, part, region, center=0):
    n = len(points)
    verts = [(center+side*width/2, y, z) for side in (-1, 1) for z, y in points]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    return mesh(name, verts, faces, mat, part, region)


def rounded_square(cx, cz, width, radius=.23):
    points = []
    for xsign, zsign, angle in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        x, z = cx+xsign*(width/2-radius), cz+zsign*(width/2-radius)
        for degree in (angle, angle+30, angle+60, angle+90):
            a = math.radians(degree)
            points.append((x+radius*math.cos(a), z+radius*math.sin(a)))
    return points


def body_cross(w=BODY_HALF_WIDTH, bottom=BODY_BOTTOM, front=False):
    # Broad flat shoulders, a raised folded spine, and a deep V underneath.
    # The shoulder/spine corners are deliberately concave paper folds.
    shoulder_inner = (BODY_SHOULDER+(BODY_SPINE-BODY_SHOULDER)*.64/.90
                      if front else BODY_SHOULDER)
    return [(0, bottom), (-w*.82, bottom+.28), (-w, BODY_SHOULDER),
            (-w*.36, shoulder_inner), (-w*.10, BODY_SPINE), (w*.10, BODY_SPINE),
            (w*.36, shoulder_inner), (w, BODY_SHOULDER), (w*.82, bottom+.28)]


def build_body():
    sections = [(NOSE_BACK, body_cross(front=True)),
                (NOSE_BACK+.35, body_cross()),
                (4.50, body_cross(1.17, -.12)),
                (BODY_BACK, body_cross(.795, .04))]
    shell_sections("body-paper", sections, .085, "paper", "body", "paper")


def nose_cross(z):
    t = max(.008, (z-NOSE_TIP) / (NOSE_BACK-NOSE_TIP))
    return [(x*t, -.20+(y+.20)*t) for x,y in body_cross(front=True)]


def build_nose():
    join = NOSE_TIP + .40 * (NOSE_BACK-NOSE_TIP)
    # Colour changes at a shared section instead of floating above the cone.
    # Each colour region is independently watertight. The rear rim matches
    # the body's full cross-section, including the shoulders and spine.
    shell_sections("nose-paper", [(join,nose_cross(join)), (NOSE_BACK,nose_cross(NOSE_BACK))],
                   .085, "paper", "nose", "paper")
    sealed_tip_shell("nose-accent", [(z,nose_cross(z)) for z in
                     (NOSE_TIP, NOSE_TIP+.25*(NOSE_BACK-NOSE_TIP), join)],
                     1, .045, "accent", "nose", "accent")


def build_wings():
    half = SPAN/2
    tip_front = NOSE_TIP + (836-493)*SCALE - .45
    root_front = NOSE_BACK + .40
    inner_back = NOSE_TIP + (853-493)*SCALE
    polygon = [(0, NOSE_BACK), (BODY_HALF_WIDTH, root_front),
               (half, tip_front), (half, BODY_BACK),
               (1.12, inner_back), (0, inner_back+.12),
               (-1.12, inner_back), (-half, BODY_BACK),
               (-half, tip_front), (-BODY_HALF_WIDTH, root_front)]
    cuts = [p[0] for p in WING_LEVELS[1:-1]]
    slab("wings-paper", polygon, wing_height, .10, "paper", "wings", "paper", cuts)
    stripes = []
    for sign, side in ((-1, "left"), (1, "right")):
        lo, hi = sorted((sign*(half-.78), sign*(half-1.73)))
        stripe = clip(clip(polygon, 0, lo, True), 0, hi, False)
        stripes.append(slab("stripe-"+side, stripe, lambda x,z: wing_height(x,z)+.06,
                            .04, "accent", "wings", "accent", cuts))
        patch = rounded_square(sign*3.16, NOSE_TIP+(795-493)*SCALE, 1.85)
        slab("wings-sticker-"+side, patch, lambda x,z: wing_height(x,z)+STICKER_TOP_OFFSET,
             STICKER_THICKNESS, "sticker", "wings", "sticker")
    merge(stripes, "wings-accent")


def build_tail():
    def block(w, bottom, top):
        return [(-w+.10,bottom), (-w,bottom+.10), (-w,top-.10), (-w+.10,top),
                (w-.10,top), (w,top-.10), (w,bottom+.10), (w-.10,bottom)]
    # This is the rear fuselage block, not a horizontal stabiliser.
    base = shell_sections("tail-block", [(BODY_BACK-.12,block(.795,.48,1.15)),
                          (TAIL_BACK,block(.57,.65,1.17))], .085, "paper", "tail", "paper")
    fin = [(5.18,1.03), (6.47,FIN_TOP-.04), (7.47,FIN_TOP), (7.48,1.03)]
    cream = profile_x("tail-folded-fin", fin, .11, "paper", "tail", "paper")
    merge([base, cream], "tail-paper", union=True)
    overlays = []
    red_fin = [(5.76,1.18),(6.67,FIN_TOP-.032),(7.445,FIN_TOP-.002),(7.453,1.18)]
    for sign in (-1,1):
        overlays.append(profile_x("fin-colour", red_fin, .035, "accent", "tail", "accent", center=sign*.0745))
    merge(overlays, "tail-accent")


def build_pellet():
    x, y = -GUN_X, GUN_Y
    radius = GUN_DIAMETER/2
    profile = [(x+radius*math.cos(i*math.tau/24), y+radius*math.sin(i*math.tau/24)) for i in range(24)]
    shell_sections("pellet-tube", [(GUN_FRONT,profile), (GUN_FRONT+GUN_LENGTH,profile)],
                   .085, "paper", "pellet", "paper")
    # A flat-topped folded tape cradle, rather than intersecting loose strips.
    # The top tucks into the wing root; chamfers show real folds in the strap.
    collar=[(x+a,b) for a,b in [(-.37,-.505),(.37,-.505),(.50,-.375),(.50,.710),
                               (.39,.815),(-.39,.815),(-.50,.710),(-.50,-.375)]]
    shell_sections("pellet-band", [(-1.16,collar), (-.46,collar)], .085, "tape", "pellet", "band")


def bounds(obj):
    coords = np.array([to_roblox(obj.matrix_world @ v.co) for v in obj.data.vertices])
    return coords.min(0), coords.max(0)


def self_intersections(data):
    """Check nonadjacent triangle crossings as well as manifold topology."""
    coordinates=[v.co.copy() for v in data.vertices]
    indices=[tuple(t.vertices) for t in data.loop_triangles]
    tree=BVHTree.FromPolygons(coordinates,indices,all_triangles=True,epsilon=1e-7)

    def segment_hit(a,b,tri):
        edge1,edge2=tri[1]-tri[0],tri[2]-tri[0]
        direction=b-a;cross=direction.cross(edge2);det=edge1.dot(cross)
        if abs(det)<1e-9:return False
        delta=a-tri[0];u=delta.dot(cross)/det
        q=delta.cross(edge1);v=direction.dot(q)/det;t=edge2.dot(q)/det
        return 1e-6<t<1-1e-6 and u>=-1e-7 and v>=-1e-7 and u+v<=1+1e-7

    def planar_hit(first,second,normal):
        axis=max(range(3),key=lambda i:abs(normal[i]))
        keep=[i for i in range(3) if i!=axis]
        a=np.array([[p[i] for i in keep] for p in first])
        b=np.array([[p[i] for i in keep] for p in second])
        cross=lambda u,v:u[0]*v[1]-u[1]*v[0]
        def strictly_inside(p,tri):
            signs=[cross(tri[(i+1)%3]-tri[i],p-tri[i]) for i in range(3)]
            return min(signs)>1e-7 or max(signs)<-1e-7
        if any(strictly_inside(p,b) for p in a) or any(strictly_inside(p,a) for p in b):return True
        for i in range(3):
            for j in range(3):
                d=a[(i+1)%3]-a[i];e=b[(j+1)%3]-b[j];det=cross(d,e)
                if abs(det)<1e-9:continue
                delta=b[j]-a[i];t=cross(delta,e)/det;u=cross(delta,d)/det
                if 1e-6<t<1-1e-6 and 1e-6<u<1-1e-6:return True
        return False

    crossings=[]
    for i,j in tree.overlap(tree):
        if i>=j or set(indices[i]) & set(indices[j]):continue
        a=[coordinates[k] for k in indices[i]];b=[coordinates[k] for k in indices[j]]
        normal=(a[1]-a[0]).cross(a[2]-a[0]).normalized()
        coplanar=max(abs(normal.dot(p-a[0])) for p in b)<1e-7
        hit=planar_hit(a,b,normal) if coplanar else (
            any(segment_hit(a[k],a[(k+1)%3],b) for k in range(3)) or
            any(segment_hit(b[k],b[(k+1)%3],a) for k in range(3)))
        if hit:crossings.append((i,j))
    return crossings


def validate(obj):
    bm = bmesh.new(); bm.from_mesh(obj.data)
    boundary = sum(e.is_boundary for e in bm.edges)
    nonmanifold = sum(not e.is_manifold for e in bm.edges)
    wire = sum(e.is_wire for e in bm.edges)
    inconsistent = sum(not e.is_contiguous for e in bm.edges)
    loose = sum(not v.link_faces for v in bm.verts)
    volume = bm.calc_volume(signed=True)
    components = []
    remaining = set(bm.verts)
    while remaining:
        stack = [remaining.pop()]; group = set(stack)
        while stack:
            v = stack.pop()
            for e in v.link_edges:
                neighbor = e.other_vert(v)
                if neighbor in remaining:
                    remaining.remove(neighbor); group.add(neighbor); stack.append(neighbor)
        components.append(len(group))
    bm.free()
    obj.data.calc_loop_triangles()
    triangles = len(obj.data.loop_triangles)
    areas = []
    for tri in obj.data.loop_triangles:
        a,b,c = [obj.data.vertices[i].co for i in tri.vertices]
        areas.append((b-a).cross(c-a).length/2)
    assert not any((boundary,nonmanifold,wire,inconsistent,loose)), f"{obj.name}: mesh topology failure"
    assert volume > 0, f"{obj.name}: inverted or zero volume"
    assert min(areas) > 1e-8, f"{obj.name}: degenerate triangle"
    crossings=self_intersections(obj.data)
    assert not crossings, f"{obj.name}: self-intersecting triangles {crossings[:6]}"
    assert triangles < 1500, f"{obj.name}: triangle budget"
    assert not obj.data.uv_layers, f"{obj.name}: unexpected UV map"
    return {"triangles":triangles, "boundary_edges":boundary, "nonmanifold_edges":nonmanifold,
            "wire_edges":wire, "inconsistent_edges":inconsistent, "loose_vertices":loose,
            "closed_components":len(components), "component_vertex_counts":sorted(components),"self_intersections":len(crossings),
            "signed_volume":round(volume,8), "minimum_triangle_area":round(min(areas),10)}


def export_all():
    entries = []
    checks = {}
    anchors = {}
    for part in DISPLAY_NAMES:
        group = [bounds(obj) for obj in OBJECTS if obj['part'] == part]
        anchors[part] = (np.min([b[0] for b in group], axis=0) +
                         np.max([b[1] for b in group], axis=0))/2
    anchors['pellet'] = np.array((-GUN_X, GUN_Y, GUN_CENTER_Z))
    for obj in OBJECTS:
        checks[obj.name] = validate(obj)
        lo,hi = bounds(obj); center=(lo+hi)/2; size=hi-lo
        part,region=obj["part"],obj["region"]
        anchor = anchors[part]
        rgb = WHITE if region=="sticker" else TAPE if region=="band" else RED if region=="accent" else PAPER
        # Keep geometry relative to the logical slot pivot in the FBX.
        # File transforms carry one stud per source unit without a scale modifier.
        for vertex in obj.data.vertices:
            vertex.co -= to_blender(anchor)
        obj.location = to_blender(anchor)
        obj.data.update()
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        saved_location=obj.location.copy(); obj.location=(0,0,0)
        bpy.ops.export_scene.fbx(filepath=str(OUT/(obj.name+".fbx")), use_selection=True,
            object_types={"MESH"}, global_scale=.01, apply_unit_scale=False,
            apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y",
            bake_space_transform=True, use_mesh_modifiers=False,
            use_triangles=True, mesh_smooth_type="FACE", add_leaf_bones=False,
            bake_anim=False, path_mode="STRIP", embed_textures=False,
            use_custom_props=False)
        obj.location=saved_location
        local_lo,local_hi=lo-anchor,hi-anchor
        fbx_lo,fbx_hi=local_lo,local_hi
        entries.append({"file":obj.name+".fbx", "object":obj.name, "part":part,"region":region,
            "display_name":DISPLAY_NAMES[part],
            "bbox_min":rounded(lo), "bbox_max":rounded(hi), "bbox_center":rounded(center),
            "size":rounded(size), "triangles":checks[obj.name]["triangles"],
            "suggested_color3_255":list(rgb), "suggested_color3":[round(v/255,6) for v in rgb],
            "team_color_at_runtime":region=="accent", "slot_pivot":rounded(anchor),
            "center_offset_from_slot":rounded(center-anchor),
            "slot_local_bbox_min":rounded(local_lo), "slot_local_bbox_max":rounded(local_hi),
            "fbx_local_bbox_min":rounded(fbx_lo), "fbx_local_bbox_max":rounded(fbx_hi),
            "assembly_rotation":"identity; no legacy yaw compensation"})
        log(f"{obj.name}: {checks[obj.name]['triangles']} triangles, closed")
    # New bounds come from the concept. The legacy dimensions are not read.
    aggregate = {}
    for part in ("body", "nose", "wings", "tail"):
        group=[e for e in entries if e["part"]==part]
        lo=np.min([e["bbox_min"] for e in group],axis=0); hi=np.max([e["bbox_max"] for e in group],axis=0)
        size=hi-lo;center=(hi+lo)/2
        count=sum(e["triangles"] for e in group)
        assert count<1500, f"{part}: combined triangle budget failed"
        aggregate[part]={"bbox_min":rounded(lo),"bbox_max":rounded(hi),"center":rounded(center),
                         "size":rounded(size),"triangles":count,"slot_pivot":rounded(anchors[part])}
    plane_lo=np.min([e['bbox_min'] for e in entries],axis=0)
    plane_hi=np.max([e['bbox_max'] for e in entries],axis=0)
    assert abs(plane_hi[2]-plane_lo[2]-LENGTH)<1e-5, 'Overall length must be 15.3'
    assert abs(plane_hi[0]-plane_lo[0]-SPAN)<1e-5, 'Overall span must follow the concept'
    assert abs(plane_hi[1]-plane_lo[1]-MEASUREMENTS[10][4])<1e-5, 'Overall concept height'
    assert abs(BODY_SHOULDER-BODY_BOTTOM-1.8)<1e-5, 'Body core depth from round-2 brief'
    assert abs(aggregate['body']['size'][1]-2.25)<1e-5, 'Body core plus raised spine'
    leading_at_gun=NOSE_BACK+.40+(GUN_X-BODY_HALF_WIDTH)/(SPAN/2-BODY_HALF_WIDTH)*(NOSE_TIP+(836-493)*SCALE-.45-NOSE_BACK-.40)
    exposed_fraction=(leading_at_gun-GUN_FRONT)/GUN_LENGTH
    assert .30<exposed_fraction<.40, 'About the front third of each tube ahead of the wing'
    mounts={side:{"tube_center":[sign*GUN_X,GUN_Y,GUN_CENTER_Z],
                  "muzzle":[sign*GUN_X,GUN_Y,GUN_FRONT],"forward":[0,0,-1]}
            for side,sign in (("left",-1),("right",1))}
    payload={"schema_version":2,"units":"studs","axes":"X right, Y up, -Z forward",
        "source":"option-a.png","texture_images":[],"exports":entries,"assembled_parts":aggregate,
        "proportions":{"length":LENGTH,"span":SPAN,"height":FIN_TOP-BODY_BOTTOM,
                "shoulder_width":2*BODY_HALF_WIDTH,"body_depth_shoulder_to_keel":BODY_SHOULDER-BODY_BOTTOM,
                "raised_spine_height_above_shoulders":BODY_SPINE-BODY_SHOULDER,
                "body_depth_including_spine":BODY_SPINE-BODY_BOTTOM,
                "nose_length":NOSE_BACK-NOSE_TIP,"nose_accent_fraction":.40,"sticker_width":1.85,
                "wing_outer_leading_offset_from_top_trace":-.45,"wing_root_leading_offset_from_top_trace":.40},
        "review_camera":{"projection":"perspective","location_blender":THREEQUARTER_CAMERA,
                "target_blender":THREEQUARTER_TARGET,"lens_mm":THREEQUARTER_LENS,
                "sensor_width_mm":36,"roll_radians":THREEQUARTER_ROLL,
                "comparison_uniform_reduction":.88},
        "overall_bounds":{"min":rounded(plane_lo),"max":rounded(plane_hi),"size":rounded(plane_hi-plane_lo)},
        "mounts":mounts,"weapon":{"tube_length":GUN_LENGTH,"tube_diameter":GUN_DIAMETER,
                "muzzle_offset_from_center":[0,0,-GUN_LENGTH/2],
                "right_instance_translation":[2*GUN_X,0,0],
                "front_fraction_ahead_of_wing_leading_edge":exposed_fraction},
        "fbx_contract":{"source_unit_studs":1,"global_scale":.01,"apply_unit_scale":False,
            "apply_scale_options":"FBX_SCALE_NONE","bake_space_transform":True,"fbx_unit_scale_factor":1,
            "scale_explanation":"0.01 cancels Blender's implicit 100x centimeter conversion. Saved vertex coordinates are in studs, matching the legacy FBX unit tag.",
            "axis_forward":"-Z","axis_up":"Y","structural_yaw_compensation_degrees":0,
            "import_instruction":"Set mesh sizes and centers from this manifest. Preserve the slot-relative vertex offsets when composing regions.",
            "limitation":"New sizes, centers, identity rotations and tube-center/muzzle mounts require later game integration. These files do not preserve the old template dimensions or yaw."}}
    assert sum(e["triangles"] for e in entries if e["part"]=="pellet")<1500, "Combined weapon triangle budget"
    bpy.context.view_layer.update()
    (OUT/"parts.json").write_text(json.dumps(payload,indent=2)+"\n",encoding="utf-8")
    return payload,checks


def verify_fbx_roundtrip(payload, directory=OUT):
    records=[]
    for entry in payload["exports"]:
        existing=set(bpy.data.objects)
        raw,version=parse_fbx.parse(str(directory/entry["file"]))
        settings=next(e for e in raw.elems if e.id==b"GlobalSettings")
        properties=next(e for e in settings.elems if e.id==b"Properties70")
        unit=next(e.props[-1] for e in properties.elems if e.props[0]==b"UnitScaleFactor")
        assert unit==1, "Match the existing aircraft FBX centimeter/stud convention"
        blocks=next(e for e in raw.elems if e.id==b"Objects")
        assert not any(e.id in (b"Texture",b"Video") for e in blocks.elems), "FBX may not contain any texture records"
        geometry=next(e for e in blocks.elems if e.id==b"Geometry")
        raw_coords=np.array(next(e.props[0] for e in geometry.elems if e.id==b"Vertices")).reshape(-1,3)
        assert np.max(np.abs(raw_coords.min(0)-entry["fbx_local_bbox_min"]))<1e-4, "Raw FBX minimum is not in studs"
        assert np.max(np.abs(raw_coords.max(0)-entry["fbx_local_bbox_max"]))<1e-4, "Raw FBX maximum is not in studs"
        # Blender treats UnitScaleFactor=1 as centimetres and source units as
        # metres. Roblox's legacy importer treats the same vertex numbers as
        # studs. Cancel ONLY the Blender importer centimetre conversion.
        bpy.ops.import_scene.fbx(filepath=str(directory/entry["file"]),global_scale=100,use_custom_normals=False)
        imported=[o for o in bpy.data.objects if o not in existing]
        meshes=[o for o in imported if o.type=="MESH"]
        assert len(meshes)==1, entry["file"]+": not exactly one FBX mesh"
        obj=meshes[0]
        obj.location+=to_blender(entry["slot_pivot"])
        bpy.context.view_layer.update()
        lo,hi=bounds(obj)
        assert np.max(np.abs(lo-entry["bbox_min"]))<1e-4, entry["file"]+": lower bounds changed in FBX"
        assert np.max(np.abs(hi-entry["bbox_max"]))<1e-4, entry["file"]+": upper bounds changed in FBX"
        record=validate(obj)
        assert record["triangles"]==entry["triangles"], entry["file"]+": triangle count changed"
        records.append({"file":entry["file"],"bounds_error_max":float(max(np.max(np.abs(lo-entry["bbox_min"])),np.max(np.abs(hi-entry["bbox_max"])))),
                        "raw_fbx_bounds_in_studs_verified":True,"fbx_unit_scale_factor":unit,"fbx_texture_records":0,"validation":record})
        for o in imported:bpy.data.objects.remove(o,do_unlink=True)
    log("All FBX files re-imported: scale, placement, triangles and watertightness verified")
    return records


def export_stickers(plane_payload):
    """Origin-centred flat meshes, plus spots measured from the assembled placeholders."""
    spots = {}
    for side in ("left", "right"):
        placeholder = next(o for o in OBJECTS if o.name == "wings-sticker-"+side)
        lo, hi = bounds(placeholder)
        center = (lo+hi)/2
        top = max((p for p in placeholder.data.polygons if p.normal.z > .99),
                  key=lambda p: p.area)
        up = Vector(to_roblox(placeholder.matrix_world.to_3x3() @ top.normal)).normalized()
        back = Vector((0, 0, 1))
        right = up.cross(back).normalized()
        spots[side] = {"placeholder": placeholder.name, "center": rounded(center),
                       "up_normal": rounded(up), "right": rounded(right), "back": rounded(back),
                       "center_offset_from_wings_slot": rounded(center-np.array(
                           plane_payload["assembled_parts"]["wings"]["slot_pivot"]))}

    circle_segments = 64
    polygons = {"sticker-square": rounded_square(0, 0, 1.7, radius=.10),
                "sticker-circle": [(.9*math.cos(i*math.tau/circle_segments),
                                    .9*math.sin(i*math.tau/circle_segments))
                                   for i in range(circle_segments)]}
    sources, entries, checks = {}, [], {}
    for name, polygon in polygons.items():
        obj = slab(name, polygon, lambda x,z: STICKER_THICKNESS/2,
                   STICKER_THICKNESS, "sticker", "sticker", "sticker")
        OBJECTS.remove(obj)  # Standalone assets do not alter the classic assembly or its pivots.
        checks[name] = validate(obj)
        lo, hi = bounds(obj)
        assert np.max(np.abs(lo+hi)) < 1e-7, name+": must be centred on its own origin"
        assert abs((hi-lo)[1]-STICKER_THICKNESS) < 1e-7
        # Check the actual placed vertices fit inside each existing placeholder
        # and keep its .02-stud underside gap and .06-stud top offset.
        for spot in spots.values():
            rotation = Vector((0,0,1)).rotation_difference(to_blender(spot["up_normal"]).normalized())
            footprint = rounded_square(spot["center"][0], spot["center"][2], 1.85)
            for vertex in obj.data.vertices:
                p = to_roblox(rotation @ vertex.co + to_blender(spot["center"]))
                for a,b in zip(footprint, footprint[1:]+footprint[:1]):
                    assert (b[0]-a[0])*(p[2]-a[1])-(b[1]-a[1])*(p[0]-a[0]) >= -1e-6, name+": exceeds placeholder"
                gap = p[1]-wing_height(p[0],p[2])
                assert STICKER_TOP_OFFSET-STICKER_THICKNESS-1e-5 <= gap <= STICKER_TOP_OFFSET+1e-5, name+": not flush"
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.export_scene.fbx(filepath=str(STICKERS_OUT/(name+".fbx")), use_selection=True,
            object_types={"MESH"}, global_scale=.01, apply_unit_scale=False,
            apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y",
            bake_space_transform=True, use_mesh_modifiers=False,
            use_triangles=True, mesh_smooth_type="FACE", add_leaf_bones=False,
            bake_anim=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
        entries.append({"file":name+".fbx", "object":name, "part":"sticker", "region":"sticker",
                        "bbox_min":rounded(lo), "bbox_max":rounded(hi), "size":rounded(hi-lo),
                        "fbx_local_bbox_min":rounded(lo), "fbx_local_bbox_max":rounded(hi),
                        "slot_pivot":[0,0,0], "triangles":checks[name]["triangles"],
                        "team_color_at_runtime":True, "default_color3_255":list(WHITE),
                        "outline_segments":len(polygon),
                        **({"corner_radius":.10} if name=="sticker-square" else {"diameter":1.8})})
        obj.hide_render = True
        obj.hide_viewport = True
        sources[name] = obj
        log(f"{name}: {checks[name]['triangles']} triangles, centred, closed, fits both wing spots")
    payload = {"schema_version":1, "units":"studs", "axes":"X right, Y up, -Z forward",
               "local_plane":"X-Z", "local_up_normal":[0,1,0], "local_origin":"mesh centre",
               "thickness":STICKER_THICKNESS, "top_offset_above_wing":STICKER_TOP_OFFSET,
               "midplane_offset_above_wing":STICKER_TOP_OFFSET-STICKER_THICKNESS/2,
               "wing_sticker_spots":spots,
               "wings_slot_pivot":plane_payload["assembled_parts"]["wings"]["slot_pivot"],
               "placement":"Use center in assembled plane coordinates, or center_offset_from_wings_slot in the wing slot. CFrame.fromMatrix(center, right, up_normal, back) orients either shape. Replace, rather than overlay, the white placeholder.",
               "teams":{"red":{"shape":"sticker-square", "color3_255":list(RED)},
                        "blue":{"shape":"sticker-circle", "color3_255":list(BLUE)},
                        "free_for_all":{"shape":"existing wings-sticker-left/right placeholders",
                                        "color3_255":list(WHITE)}},
               "exports":entries, "fbx_contract":plane_payload["fbx_contract"]}
    roundtrip = verify_fbx_roundtrip(payload, STICKERS_OUT)
    (STICKERS_OUT/"stickers.json").write_text(json.dumps(payload,indent=2)+"\n",encoding="utf-8")
    return sources, payload, checks, roundtrip


def camera(location,target,up="Z",scale=20,roll=0):
    obj=bpy.data.objects.new("Review camera",bpy.data.cameras.new("Review camera"))
    bpy.context.collection.objects.link(obj)
    obj.location=Vector(location)
    direction=(Vector(target)-obj.location).normalized()
    world_up=Vector((0,1,0) if up=="Y" else (0,0,1))
    right=direction.cross(world_up).normalized()
    camera_up=right.cross(direction).normalized()
    rotation=Matrix((right,camera_up,-direction)).transposed()
    obj.rotation_euler=(rotation @ Matrix.Rotation(roll,3,"Z")).to_euler()
    obj.data.type="ORTHO";obj.data.ortho_scale=scale
    bpy.context.scene.camera=obj
    return obj


def setup_render():
    scene=bpy.context.scene
    scene.render.engine="BLENDER_WORKBENCH"
    scene.render.resolution_x=1600;scene.render.resolution_y=1200
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.render.image_settings.color_mode="RGBA"
    scene.render.film_transparent=True
    scene.world.color=(.88,.87,.84)
    shade=scene.display.shading
    shade.light="STUDIO";shade.studiolight_rotate_z=.5
    shade.studio_light="paint.sl";shade.color_type="MATERIAL"
    shade.show_shadows=True;shade.show_cavity=True;shade.cavity_type="BOTH"
    shade.cavity_ridge_factor=1.0;shade.cavity_valley_factor=1.0
    shade.curvature_ridge_factor=1.0;shade.curvature_valley_factor=1.0
    shade.show_specular_highlight=False;shade.show_object_outline=False
    shade.background_type="WORLD"
    scene.view_settings.view_transform="Standard"
    scene.view_settings.look="None"
    scene.view_settings.exposure=0;scene.view_settings.gamma=1
    # The right weapon is a linked review instance, never a duplicate export.
    copies=[]
    for obj in [o for o in OBJECTS if o["part"]=="pellet"]:
        duplicate=obj.copy();duplicate.data=obj.data
        duplicate.name=obj.name+"-right-preview"
        duplicate.location.x+=2*GUN_X
        bpy.context.collection.objects.link(duplicate);copies.append(duplicate)
    return copies


def render(name,location,target=(0,0,.3),up="Z",scale=20,roll=0):
    cam=camera(location,target,up,scale,roll)
    if name.startswith(("render-threequarter", "render-team-")):
        cam.data.type="PERSP";cam.data.lens=THREEQUARTER_LENS;cam.data.sensor_width=36
    bpy.context.scene.render.filepath=str(OUT/name)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam,do_unlink=True)


def render_team(name, source, spots):
    placeholders = [o for o in OBJECTS if o["region"] == "sticker"]
    saved_visibility = {o:o.hide_render for o in placeholders}
    previews = []
    # Use the exported shape, with the same centres and normals as the manifest.
    preview_mesh = source.data.copy()
    preview_mesh.materials.clear(); preview_mesh.materials.append(MATS["accent"])
    try:
        for obj in placeholders: obj.hide_render = True
        for side, spot in spots.items():
            obj = bpy.data.objects.new(source.name+"-"+side+"-preview", preview_mesh)
            bpy.context.collection.objects.link(obj)
            obj.location = to_blender(spot["center"])
            obj.rotation_mode = "QUATERNION"
            obj.rotation_quaternion = Vector((0,0,1)).rotation_difference(to_blender(spot["up_normal"]).normalized())
            previews.append(obj)
        render(name,THREEQUARTER_CAMERA,target=THREEQUARTER_TARGET,scale=THREEQUARTER_SCALE,roll=THREEQUARTER_ROLL)
    finally:
        for obj, hidden in saved_visibility.items(): obj.hide_render = hidden
        for obj in previews: bpy.data.objects.remove(obj,do_unlink=True)
        bpy.data.meshes.remove(preview_mesh)


def render_all(copies, sticker_sources, sticker_payload):
    render("render-threequarter.png",THREEQUARTER_CAMERA,target=THREEQUARTER_TARGET,scale=THREEQUARTER_SCALE,roll=THREEQUARTER_ROLL)
    render_team("render-team-red.png",sticker_sources["sticker-square"],sticker_payload["wing_sticker_spots"])
    red=MATS["accent"].diffuse_color[:]
    linear=lambda v:v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    MATS["accent"].diffuse_color=tuple(linear(v/255) for v in BLUE)+(1,)
    render("render-threequarter-blue.png",THREEQUARTER_CAMERA,target=THREEQUARTER_TARGET,scale=THREEQUARTER_SCALE,roll=THREEQUARTER_ROLL)
    render_team("render-team-blue.png",sticker_sources["sticker-circle"],sticker_payload["wing_sticker_spots"])
    MATS["accent"].diffuse_color=red
    render("render-top.png",(0,0,35),target=(0,0,.3),up="Y",scale=23.4)
    render("render-side.png",(-35,0,.3),scale=19.2)
    render("render-front.png",(0,35,1.4),scale=16.8)
    saved={obj:obj.location.copy() for obj in OBJECTS+copies}
    shifts={"nose":(0,0,-3.2),"body":(0,0,0),"wings":(0,3.5,0),
            "tail":(0,1,3.4),"pellet":(0,-2.3,-.6)}
    for obj in OBJECTS+copies:obj.location+=to_blender(shifts[obj["part"]])
    render("render-exploded.png",(-22,30,22),scale=27)
    for obj,position in saved.items():obj.location=position


def load_png(path):
    img=bpy.data.images.load(str(path),check_existing=False)
    img.colorspace_settings.name="Non-Color"
    width,height=img.size
    pixels=np.empty(width*height*4,dtype=np.float32)
    img.pixels.foreach_get(pixels)
    result=np.round(np.clip(pixels.reshape(height,width,4)[::-1],0,1)*255).astype(np.uint8)
    bpy.data.images.remove(img)
    return result


def resize(img,width,height):
    # Review sheet only. This raster is never referenced by an exported mesh.
    xs=np.linspace(0,img.shape[1]-1,width);ys=np.linspace(0,img.shape[0]-1,height)
    xi=np.floor(xs).astype(int);yi=np.floor(ys).astype(int)
    xj=np.minimum(xi+1,img.shape[1]-1);yj=np.minimum(yi+1,img.shape[0]-1)
    tx=(xs-xi)[None,:,None];ty=(ys-yi)[:,None,None]
    a=img[yi[:,None],xi[None,:]]*(1-tx)+img[yi[:,None],xj[None,:]]*tx
    b=img[yj[:,None],xi[None,:]]*(1-tx)+img[yj[:,None],xj[None,:]]*tx
    return np.round(a*(1-ty)+b*ty).astype(np.uint8)


# A small review-sheet lettering font, avoiding a dependency on Pillow.
FONT={
    "A":[14,17,17,31,17,17,17],"B":[30,17,17,30,17,17,30],"C":[14,17,16,16,16,17,14],
    "D":[30,17,17,17,17,17,30],"E":[31,16,16,30,16,16,31],"F":[31,16,16,30,16,16,16],
    "G":[14,17,16,23,17,17,14],"H":[17,17,17,31,17,17,17],"I":[31,4,4,4,4,4,31],
    "J":[7,2,2,2,18,18,12],"K":[17,18,20,24,20,18,17],"L":[16,16,16,16,16,16,31],
    "M":[17,27,21,21,17,17,17],"N":[17,25,21,19,17,17,17],"O":[14,17,17,17,17,17,14],
    "P":[30,17,17,30,16,16,16],"Q":[14,17,17,17,21,18,13],"R":[30,17,17,30,20,18,17],
    "S":[15,16,16,14,1,1,30],"T":[31,4,4,4,4,4,4],"U":[17,17,17,17,17,17,14],
    "V":[17,17,17,17,17,10,4],"W":[17,17,17,21,21,21,10],"X":[17,17,10,4,10,17,17],
    "Y":[17,17,10,4,4,4,4],"Z":[31,1,2,4,8,16,31],"0":[14,17,19,21,25,17,14],
    "1":[4,12,4,4,4,4,14],"2":[14,17,1,2,4,8,31],"3":[30,1,1,14,1,1,30],
    "4":[2,6,10,18,31,2,2],"5":[31,16,16,30,1,1,30],"6":[14,16,16,30,17,17,14],
    "7":[31,1,2,4,8,8,8],"8":[14,17,17,14,17,17,14],"9":[14,17,17,15,1,1,14],
    ".":[0,0,0,0,0,12,12],"/": [1,2,2,4,8,8,16],"-": [0,0,0,31,0,0,0],
    ":":[0,12,12,0,12,12,0],"+": [0,4,4,31,4,4,0],"=": [0,31,0,31,0,0,0]}


def lettering(img,text,x,y,scale=3,color=(63,62,59,255)):
    for character in text.upper():
        for row,bits in enumerate(FONT.get(character,[0]*7)):
            for col in range(5):
                if bits & (1<<(4-col)):
                    img[y+row*scale:y+(row+1)*scale,x+col*scale:x+(col+1)*scale]=color
        x+=6*scale


def save_png(path,rgba):
    def chunk(tag,data):
        return struct.pack(">I",len(data))+tag+data+struct.pack(">I",zlib.crc32(tag+data)&0xffffffff)
    h,w=rgba.shape[:2]
    rows=b"".join(b"\x00"+rgba[row].tobytes() for row in range(h))
    path.write_bytes(b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0))
                     +chunk(b"IDAT",zlib.compress(rows,8))+chunk(b"IEND",b""))


def crop_render(img):
    mask = img[:,:,3] > 128
    ys,xs = np.where(mask)
    return img[ys.min():ys.max()+1,xs.min():xs.max()+1]


def paste_center(sheet, img, cx, cy):
    h,w = img.shape[:2]
    x,y = round(cx-w/2),round(cy-h/2)
    assert x>=0 and y>=0 and x+w<=sheet.shape[1] and y+h<=sheet.shape[0]
    alpha = img[:,:,3:4].astype(float)/255
    region = sheet[y:y+h,x:x+w]
    region[:,:,:3] = np.round(img[:,:,:3]*alpha+region[:,:,:3]*(1-alpha)).astype(np.uint8)


def compare():
    source = load_png(REFERENCE)
    sheet = np.full((1730,1600,4),(246,244,237,255),dtype=np.uint8)
    lettering(sheet,"OPTION A / CLASSIC DART - ROUND 2",60,30,4)
    lettering(sheet,"APPROVED CONCEPT",130,90,3)
    lettering(sheet,"CONCEPT-PROPORTIONED MODEL",865,90,3)
    lettering(sheet,"TOP / 452 PX = 15.3 STUDS",60,143,3)
    # Exclude the neighbouring side drawing; retain the full top silhouette.
    ref_top = source[481:954,600:1004]
    paste_center(sheet,ref_top,400,430)
    top = crop_render(load_png(OUT/"render-top.png"))
    ratio = (TOP_LENGTH_PX/LENGTH)/(1600/23.4)
    top = resize(top,round(top.shape[1]*ratio),round(top.shape[0]*ratio))
    paste_center(sheet,top,1200,430)
    lettering(sheet,"SIDE / SAME LENGTH-NORMALIZED SCALE",60,734,3)
    ref_side = source[650:830,12:612]
    ref_side = resize(ref_side,round(600*SIDE_NORMALIZATION),round(180*SIDE_NORMALIZATION))
    paste_center(sheet,ref_side,400,887)
    side = crop_render(load_png(OUT/"render-side.png"))
    ratio = (TOP_LENGTH_PX/LENGTH)/(1600/19.2)
    side = resize(side,round(side.shape[1]*ratio),round(side.shape[0]*ratio))
    # Align silhouette centres vertically: equal total heights can be assessed.
    paste_center(sheet,side,1200,887)
    lettering(sheet,"THREE-QUARTER / MATCHED CAMERA AND UNIFORM SCALE",60,1042,3)
    ref_tq = source[15:485,48:824]
    ref_ratio = .88
    ref_tq = resize(ref_tq,round(ref_tq.shape[1]*ref_ratio),round(ref_tq.shape[0]*ref_ratio))
    paste_center(sheet,ref_tq,400,1325)
    tq = crop_render(load_png(OUT/"render-threequarter.png"))
    # Camera orientation, roll and px/stud were fitted to the nose, four wing
    # corners and two fin-top corners. Both columns get the same reduction.
    ratio = ref_ratio
    tq = resize(tq,round(tq.shape[1]*ratio),round(tq.shape[0]*ratio))
    paste_center(sheet,tq,1200,1325)
    lettering(sheet,"15.3 LENGTH / 13.6075 SPAN / 3.7518 HEIGHT",60,1590,3)
    lettering(sheet,"NO LEGACY TEMPLATE FIT LIMIT / PLAIN COLOUR MESHES",60,1632,3)
    lettering(sheet,"WHITE PATCHES = SWAPPABLE STICKER PLACEHOLDERS",60,1674,3)
    save_png(OUT/"compare.png",sheet)


def write_readme(payload,checks,sticker_payload):
    text = """# Classic Dart / Option A, round 2

The model follows the approved concept's proportions. The old template-size
restriction has been removed, including its centres and 180-degree rotations.
Only tools/art/planes.py and assets/models/planes/ were changed. No uploads or commits.
Game integration is later work; this is an asset build and visual comparison.

## Rebuild

From D:/FlyFightPaper in PowerShell:

```powershell
& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/planes.py
```

This rebuilds the Blender source, all 11 individual colour-region FBX files,
parts.json, validation.json, eight model renders and the three-view compare.png.
It also builds ../stickers/sticker-square.fbx, sticker-circle.fbx and stickers.json.
Every saved FBX is parsed and re-imported to verify scale, topology and placement.
Only Blender's built-in Python, NumPy and FBX exporter are needed.

## Measured reference and round-2 choices

The source is 1600 x 1001. Landmarks have about 1-3 pixels of reading uncertainty.
The top and side drawings have different printed scales: normalize the side by
452/575, then apply 15.3/452 studs per normalized pixel. The original measured
allocations remain the source of the longitudinal layout and wing silhouette.
The two brief rows below are explicit modeling choices, not pixel measurements.

""" + measurements_text()
    text += f"\nScale = {SCALE:.9f}. Nose/body/rear allocations sum to 15.3000 studs.\n"
    text += "\nThe body is 2.60 wide at the root and 1.80 deep from the wide flat shoulders\nto the V keel. The raised folded spine adds .45, giving 2.25 total including\nthe ridge, close to the side drawing's 2.2351. The total is above the brief's\napproximate 1.6-1.9 estimate; the drawn silhouette was given priority because\nonly overall length and span were fixed. The nose continues the body's exact\nfront section, tapers over 5.0436 studs, and changes to red over its front 40%.\nIts roof facets are planar, without extra grooves. The wings use the full\n8.0223-stud fore/aft envelope. The rear has one swept vertical fin and a\n1.590-wide fuselage block, with no horizontal tail wings.\n"
    text += "\n## Actual assembled bounds\n\n| Part | Size X/Y/Z | Centre X/Y/Z | Triangles, all regions |\n|---|---|---|---:|\n"
    fmt = lambda xyz: " / ".join(f"{v:.4f}" for v in xyz)
    for part,value in payload['assembled_parts'].items():
        text += f"| {part} | {fmt(value['size'])} | {fmt(value['center'])} | {value['triangles']} |\n"
    text += f"\nOverall size: {fmt(payload['overall_bounds']['size'])} studs.\n"
    text += "\n## Mounts, in assembled Roblox studs\n\nAxes: X right, Y up, -Z forward. The muzzle is the centre of the front opening,\nnot an old logical offset. Both tubes point along (0,0,-1).\n\n| Gun | Tube centre X/Y/Z | Muzzle X/Y/Z |\n|---|---|---|\n"
    for side,mount in payload['mounts'].items():
        text += f"| {side} | {fmt(mount['tube_center'])} | {fmt(mount['muzzle'])} |\n"
    weapon = payload['weapon']
    text += f"\nTube length {weapon['tube_length']:.6f}, diameter {weapon['tube_diameter']:.6f}; wall .085.\n"
    text += f"Only {weapon['front_fraction_ahead_of_wing_leading_edge']*100:.1f}% of each tube axis is ahead of the wing leading edge.\n"
    text += f"The right instance is translated +{2*GUN_X:.2f} in X from the exported left gun.\n"
    text += """
Each tube sits just outside the body under the wing-root shoulder. A chamfered
closed tape band wraps around it and reaches the underside of the paper wing.
Use parts.json's mounts directly for the later weapon assembly and firing code.

## Mesh and FBX assembly contract

One Blender unit is one stud. Construction uses Roblox X/Y/Z and converts to
Blender X/-Z/Y. All new FBXs use Y up, -Z forward and identity assembly rotation.
The source and manifest describe the final assembled Roblox coordinates.
Each logical part has one common pivot shared by all its colour regions.
The pellet pivot is its tube centre; the separate tape band retains its offset.
Keep every region's center_offset_from_slot when assembling imported MeshParts.
Do not independently recenter or resize small accents to the whole part's bounds.

FBX global_scale=.01, apply_unit_scale=False and FBX_SCALE_NONE cancel Blender's
implicit 100x centimetre conversion. Raw saved vertex numbers are in studs and
UnitScaleFactor=1. The verifier checks raw FBX bounds to .0001 stud, then imports
with global_scale=100 solely to undo Blender's centimetre interpretation.
Roblox import scale is 1. Use the new sizes, pivots and mounts in parts.json;
these are not drop-in replacements for the old templates or their rotations.
No src/, config/, template, place file or upload has been changed.

Each file contains one mesh with one plain colour material. There are no texture
images, UV layers, shader image nodes or embedded textures. Accent meshes can
receive team colour; sticker meshes are separate 1.85-stud white placeholders.
Paper thickness is .085-.11 stud, stickers and colour overlays .035-.04.
The sealed red cone has a .045 rear wall and a locally solid front point.
The very front of the cone is sealed. All planar paper faces use flat normals,
so coplanar triangles shade alike and folds cannot be blurred across creases.
The hollow tubes have genuinely open mouths and watertight wall/rim topology.
The stripe and fin colour exports each contain two closed components.

## Visual comparison and remaining differences

compare.png includes top, side and three-quarter concept/model pairs. Top and
side use 452 pixels per 15.3 studs after uniform side normalization. The
three-quarter perspective camera is fitted to the nose, wing corners, body ridge
and fin top. Its actual lens, location and roll are in parts.json. The reference
crop and fitted render receive the same uniform .88 reduction in the comparison.
No image is stretched independently in X or Y to hide shape differences.

- The concept is a painted perspective sheet. Its top/side/three-quarter views
  disagree slightly at the nose root, wing rake and fin lean. The build uses
  the measured allocations and one consistent 3D shape. The top and side silhouettes
  are close; the three-quarter left leading edge remains a little steeper and the
  fin is more foreshortened than the painted view.
- The wing outer leading corners are .45 stud (13.3 normalized pixels) forward of
  the top tracing, and shoulder leading corners are .40 stud (11.8 pixels) aft.
  This reduces the three-quarter disagreement without changing span or the full
  8.0223 fore/aft envelope. It leaves a slightly shallower sweep in the top view.
- The core is 1.80 deep; including the raised ridge, the body/nose bounds are 2.25.
  That follows the drawn side silhouette, rather than treating 1.9 as a limit on
  the whole folded assembly. The overall plane height is still 3.7518.
- The barrels expose about one third of their length, as requested. The drawing
  shows more barrel ahead of the wing in its top view, so these mounts are farther aft.
- The red cone covers 40% as in the top view. The side painting shows a somewhat
  longer red area; one physical colour split cannot reproduce both percentages.
- White rounded-square placeholders remain for free-for-all. Team renders
  replace them with red squares or blue circles.
- Paper, red accents and tape are clean flat colours. Paper grain, pencilled
  lines, crayon variation and the reference's ground shadow are intentionally absent.
- The folded rear block and fin are geometrically sharp. The concept has a few
  softer/irregular paper corners that are not reproduced as surface noise.

## Saved-file verification

| FBX | Region | Triangles | Closed components |
|---|---|---:|---:|
"""
    for entry in payload['exports']:
        text += f"| {entry['file']} | {entry['region']} | {entry['triangles']} | {checks[entry['object']]['closed_components']} |\n"
    text += "\nEvery source and saved FBX is checked for closed manifold topology, consistent\nnormals, positive volume, no degenerate triangles, no self intersections, no UVs,\nand fewer than 1500 triangles per export and per whole logical part. The full\nlength, span, height, body depth and barrel exposure are also checked.\n"
    text += "\n## Team sticker shapes and placement\n\nRed uses a 1.7 x 1.7 square with .10-stud corner radius. Blue uses a 1.8-diameter\ncircle with 64 outline segments. Both are .04 stud thick, centred on their own\norigin, in local Roblox X-Z with +Y up. Free-for-all keeps the white placeholders.\nThe shapes export white so the game can set their team colour. No other symbols.\n\n../stickers/stickers.json records the spot centres and orientation axes measured\nfrom the existing wing placeholders. Centres use assembled Roblox studs; it also\nrecords wing-slot-relative centres. Replace each placeholder with one shape copy.\nUse CFrame.fromMatrix(center, right, up_normal, back). The midpoint remains .04\nstud above the wing, matching the placeholder's .06 top offset and .02 bottom gap.\n\n| Wing | Centre X/Y/Z | Up normal X/Y/Z |\n|---|---|---|\n"
    for side,spot in sticker_payload["wing_sticker_spots"].items():
        text += f"| {side} | {fmt(spot['center'])} | {fmt(spot['up_normal'])} |\n"
    text += "\nBoth saved sticker FBXs are parsed and re-imported through the same checks as\nthe plane. Every placed shape vertex is checked against the placeholder footprint\nand the existing wing clearance. Hidden sticker source objects are in classic.blend.\n"
    text += "\nReview files: render-threequarter.png, render-threequarter-blue.png, render-top.png,\nrender-side.png, render-front.png, render-exploded.png and compare.png.\nclassic.blend includes a linked right-gun preview, without duplicate FBX files.\n"
    text += "Team review files: render-team-red.png (red accents and squares) and\nrender-team-blue.png (blue accents and circles), using the same three-quarter camera.\n"
    (OUT/'README.md').write_text(text,encoding='utf-8')


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    STICKERS_OUT.mkdir(parents=True,exist_ok=True)
    # Clean only this command's named outputs. A failed rebuild must never
    # leave an old PASS report or older renders looking like new evidence.
    owned=[name+".fbx" for name in FBX_NAMES]+[
        "classic.blend","classic.blend1","README.md","parts.json","validation.json",
        "render-threequarter.png","render-threequarter-blue.png","render-top.png",
        "render-side.png","render-front.png","render-exploded.png","compare.png",
        "render-team-red.png","render-team-blue.png"]
    for filename in owned:
        path=OUT/filename
        assert path.resolve().parent==OUT.resolve(), "Output cleanup must stay in classic/"
        if path.exists():path.unlink()
    for filename in [name+".fbx" for name in STICKER_SHAPES]+["stickers.json"]:
        path=STICKERS_OUT/filename
        assert path.resolve().parent==STICKERS_OUT.resolve(), "Output cleanup must stay in stickers/"
        if path.exists():path.unlink()
    write_measurement_plan()
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    for image in list(bpy.data.images):bpy.data.images.remove(image)
    scene=bpy.context.scene
    scene.unit_settings.system="NONE";scene.unit_settings.scale_length=1
    material("paper",PAPER);material("accent",RED);material("tape",TAPE);material("sticker",WHITE)
    build_body();build_nose();build_wings();build_tail();build_pellet()
    payload,checks=export_all()
    roundtrip=verify_fbx_roundtrip(payload)
    sticker_sources,sticker_payload,sticker_checks,sticker_roundtrip=export_stickers(payload)
    assert not bpy.data.images, "No texture images may be in the Blender file"
    bpy.data.orphans_purge(do_recursive=True)
    copies=setup_render()
    # Save the assembled source before transient camera/exploded manipulations.
    review_camera=camera(THREEQUARTER_CAMERA,THREEQUARTER_TARGET,scale=THREEQUARTER_SCALE,roll=THREEQUARTER_ROLL)
    review_camera.data.type="PERSP";review_camera.data.lens=THREEQUARTER_LENS;review_camera.data.sensor_width=36
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=="VIEW_3D":
                view=area.spaces.active
                view.shading.color_type="MATERIAL"
                view.region_3d.view_location=Vector((0,0,.3))
                view.region_3d.view_distance=23
                view.region_3d.view_rotation=review_camera.rotation_euler.to_quaternion()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"classic.blend"),check_existing=False)
    render_all(copies,sticker_sources,sticker_payload)
    compare()
    write_readme(payload,checks,sticker_payload)
    report={"result":"PASS","source_checks":checks,"fbx_roundtrip":roundtrip,
        "sticker_source_checks":sticker_checks,"sticker_fbx_roundtrip":sticker_roundtrip,
        "sticker_manifest":"../stickers/stickers.json",
        "reference_sha256":hashlib.sha256(REFERENCE.read_bytes()).hexdigest(),
        "script_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "export_sha256":{entry["file"]:hashlib.sha256((OUT/entry["file"]).read_bytes()).hexdigest() for entry in payload["exports"]},
        "sticker_export_sha256":{entry["file"]:hashlib.sha256((STICKERS_OUT/entry["file"]).read_bytes()).hexdigest() for entry in sticker_payload["exports"]},
        "texture_images":[],"uv_layers":0,"max_triangles_per_export":max(e["triangles"] for e in payload["exports"]),
        "dimensions_checked":True,"render_files":[p.name for p in sorted(OUT.glob("*.png"))]}
    (OUT/"validation.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    # Blender's backup only occurs inside the authorized output directory.
    backup=OUT/"classic.blend1"
    if backup.exists():backup.unlink()
    log("Build complete; all files are local and texture-free")


if __name__=="__main__":
    main()
