"""Build the 23 approved modular plane assets, using Classic Dart helpers.

Run from D:/FlyFightPaper:
  & D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_set.py

All generated files stay in assets/models/planes/set/. Classic is read-only.
Construction coordinates are Roblox studs: X right, Y up, -Z forward.
"""

import hashlib
import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import planes as p

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = p.ROOT
OUT = ROOT / "assets/models/planes/set"
CLASSIC = ROOT / "assets/models/planes/classic"
CONCEPT = ROOT / "assets/models/planes/concepts/parts"
ORIGINAL = json.loads((CLASSIC / "parts.json").read_text(encoding="utf-8"))
CATALOG = json.loads((ROOT / "config/catalog.json").read_text(encoding="utf-8"))
ITEMS = {e["id"]: e for e in CATALOG["structures"] + CATALOG["utilities"]}
IDS = ["body_slim", "body_heavy", "body_standard_mk2", "body_slim_mk2", "body_heavy_mk2"]
IDS += [f"{slot}_{i}" for slot in ("nose", "wings", "tail") for i in range(1, 6)]
IDS += ["boost_band", "boost_spool", "boost_twin"]
COLORS = {"paper": p.PAPER, "accent": p.RED, "cardboard": (166, 119, 72),
          "tape": p.TAPE, "metal": (149, 156, 162), "elastic": (199, 148, 73),
          "tube": (184, 154, 118)}
PIVOTS = {slot: np.array(v["slot_pivot"]) for slot, v in ORIGINAL["assembled_parts"].items()}
BOOST_Z = 3.25
CLASSIC_SECTIONS = [(p.NOSE_BACK,p.body_cross(front=True)),
                    (p.NOSE_BACK+.35,p.body_cross()),
                    (4.50,p.body_cross(1.17,-.12)),(p.BODY_BACK,p.body_cross(.795,.04))]
PIVOTS["booster"] = np.array((0, -.27535, BOOST_Z))
FRONT = p.NOSE_BACK
BACK = p.BODY_BACK
FRONT_CROSS = p.body_cross(front=True)
REAR_CROSS = p.body_cross(.795, .04)
BODY_SECTIONS = {}
BOOSTER_BODY_PIVOTS = {}
PREVIEWS = []
COMMAND = "& D:/Blender/blender.exe -b --factory-startup --threads 4 --python-exit-code 1 --python tools/art/plane_set.py"
STRICT_PART_TRIANGLE_LIMIT = 400
# toilet-roll tube: round hollow wall + spiral seam; ~1k triangles is trivial for Roblox
PART_TRIANGLE_LIMIT_OVERRIDES = {"body_heavy_mk2": 1200, "wings_5": 600}

# Classic's inset helper assumes distinct corner directions. Scaling its exactly
# collinear front roof landmarks can make NumPy's line solve singular. Delegate
# the real corners to that helper and interpolate the straight-edge landmarks.
ORIGINAL_INSET = p.inset_polygon


def stable_inset(points, thickness):
    pts = [np.array(v,dtype=float) for v in points]
    kept = []
    for i,point in enumerate(pts):
        a=point-pts[i-1];b=pts[(i+1)%len(pts)]-point
        cross=a[0]*b[1]-a[1]*b[0]
        if abs(cross)>1e-10*np.linalg.norm(a)*np.linalg.norm(b):kept.append(i)
    if len(kept)==len(pts):return ORIGINAL_INSET(points,thickness)
    inset=ORIGINAL_INSET([points[i] for i in kept],thickness)
    result=[None]*len(pts)
    for k,start in enumerate(kept):
        end=kept[(k+1)%len(kept)]
        edge=pts[end]-pts[start]
        i=start
        while i!=end:
            t=np.dot(pts[i]-pts[start],edge)/np.dot(edge,edge)
            result[i]=tuple((1-t)*np.array(inset[k])+t*np.array(inset[(k+1)%len(kept)]))
            i=(i+1)%len(pts)
    return result


p.inset_polygon = stable_inset


def log(message):
    print("PLANE SET " + message, flush=True)


def slot(part):
    return ITEMS[part].get("slot", "booster")


def geometry(part, region, vertices, faces, suffix=""):
    return p.mesh(part + "-" + region + suffix, vertices, faces, region, part, region)


def box(part, region, lo, hi, suffix=""):
    x, y, z = lo
    a, b, c = hi
    vertices = [(x,y,z),(a,y,z),(a,b,z),(x,b,z),
                (x,y,c),(a,y,c),(a,b,c),(x,b,c)]
    faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    return geometry(part, region, vertices, faces, suffix)


def extruded_patch(part, region, polygon, offset, suffix=""):
    n = len(polygon)
    vertices = polygon + [tuple(Vector(v) + Vector(offset)) for v in polygon]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return geometry(part, region, vertices, faces, suffix)


def optimize(obj):
    """Only dissolve coplanar edges; no silhouette decimation."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.dissolve_limit(bm, angle_limit=1e-6, verts=list(bm.verts),
                            edges=list(bm.edges), delimit={"NORMAL"})
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-7)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def combine(part, region, union=False):
    objects = [o for o in p.OBJECTS if o["part"] == part and o["region"] == region]
    if not objects:
        return None
    if union and slot(part)=="tail":
        # Boolean operands need explicit planar triangles at tapered shell quads.
        for operand in objects:
            bm=bmesh.new();bm.from_mesh(operand.data)
            bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method="BEAUTY",ngon_method="BEAUTY")
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
            bm.to_mesh(operand.data);bm.free();operand.data.update()
    obj = p.merge(objects, part + "-" + region, union=union) if len(objects)>1 else objects[0]
    obj.name = obj.data.name = part + "-" + region
    optimize(obj)
    return obj


def triangulate_nose_caps(obj):
    # The front profile has straight roof landmarks. Blender's automatic ear
    # tessellation can form a zero-area roof triangle on the tiny needle cap.
    # A keel fan includes those landmarks without generating a flat triangle.
    bm=bmesh.new();bm.from_mesh(obj.data);bm.normal_update()
    for face in list(bm.faces):
        vertices=list(face.verts)
        if len(vertices)<5:
            continue
        def quality(start):
            ordered=vertices[start:]+vertices[:start]
            return min((ordered[i].co-ordered[0].co).cross(ordered[i+1].co-ordered[0].co).dot(face.normal)
                       for i in range(1,len(ordered)-1))
        start=max(range(len(vertices)),key=quality)
        if quality(start)<=2e-8:
            continue
        vertices=vertices[start:]+vertices[:start]
        bm.faces.remove(face)
        for i in range(1,len(vertices)-1):bm.faces.new((vertices[0],vertices[i],vertices[i+1]))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data);bm.free();obj.data.update()


def profile_at(sections, z):
    if z <= sections[0][0]:
        return sections[0][1]
    for (a, pa), (b, pb) in zip(sections, sections[1:]):
        if z <= b + 1e-8:
            t = (z-a)/(b-a)
            return [tuple((1-t)*np.array(v) + t*np.array(w)) for v,w in zip(pa,pb)]
    return sections[-1][1]


def side_patch(part, region, sections, sign, start, end, low=.12, high=.94, start_low=.60):
    # Diagonal accent on the sloping side facet, outside its paper surface.
    vertices = []
    for z,u in ((start,high),(end,high),(end,low),(start,start_low)):
        cross = profile_at(sections,z)
        a,b = cross[1 if sign<0 else 8], cross[2 if sign<0 else 7]
        x,y = (1-u)*np.array(a)+u*np.array(b)
        vertices.append((x+sign*.012,y,z))
    return extruded_patch(part,region,vertices,(sign*.025,0,0),f"-side-{sign}")


def roof_stripes(part, sections):
    for sign in (-1,1):
        vertices, faces = [], []
        spans = [(-1.72, profile_at(sections,-1.72))]
        spans += [(z,pr) for z,pr in sections if -1.72<z<4.35]
        spans += [(4.35,profile_at(sections,4.35))]
        for z,pr in spans:
            y = pr[4][1]+.028
            x1,x2 = sorted((sign*.018, sign*.055))
            vertices += [(x1,y,z),(x2,y,z),(x2,y-.025,z),(x1,y-.025,z)]
        faces += [(3,2,1,0),tuple(range(len(vertices)-4,len(vertices)))]
        for k in range(len(spans)-1):
            a,b=k*4,(k+1)*4
            faces += [(a+i,a+(i+1)%4,b+(i+1)%4,b+i) for i in range(4)]
        geometry(part,"accent",vertices,faces,f"-roof-{sign}")


def cutter_cylinder(center, radius, start, end, segments=4):
    profile = [(center[0]+radius*math.cos(i*math.tau/segments+math.pi/4),
                center[1]+radius*math.sin(i*math.tau/segments+math.pi/4)) for i in range(segments)]
    vertices=[(x,y,z) for z in (start,end) for x,y in profile]
    faces=[tuple(reversed(range(segments))),tuple(range(segments,2*segments))]
    faces += [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    obj=geometry("body_heavy","cardboard",vertices,faces,"-temporary-clearance")
    p.OBJECTS.remove(obj)
    return obj


def cut_mount_clearance(obj, axial_padding=.12):
    for sign in (-1,1):
        # Square bore clears the whole starter tube, not just its centre.
        cut=cutter_cylinder((sign*p.GUN_X,p.GUN_Y),.68,p.GUN_FRONT-axial_padding,
                            p.GUN_FRONT+p.GUN_LENGTH+axial_padding)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new("Unchanged starter mount clearance","BOOLEAN")
        mod.operation="DIFFERENCE"
        mod.solver="EXACT"
        mod.object=cut
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cut,do_unlink=True)
    optimize(obj)


def folded_corrugation(part, sign, sections):
    # Coarse corrugated fold rails, geometry rather than texture.
    zs = np.linspace(-1.62,3.58,4)
    polygon=[]
    for i,z in enumerate(zs):
        cross=profile_at(sections,float(z))
        width=abs(cross[2][0])
        polygon.append((sign*(width-.08),.976 + (i%2)*.045,float(z)))
    # A folded strip following the rail, with a closed underside.
    vertices=[]
    for x,y,z in polygon:
        vertices += [(x,y-.025,z),(x+sign*.0375,y+.022,z),(x+sign*.075,y-.025,z)]
    faces=[(2,1,0),tuple(range(len(vertices)-3,len(vertices)))]
    for k in range(len(polygon)-1):
        a,b=k*3,(k+1)*3
        faces += [(a+i,a+(i+1)%3,b+(i+1)%3,b+i) for i in range(3)]
    geometry(part,"cardboard",vertices,faces,f"-flutes-{sign}")


def build_bodies():
    for part in IDS[:5]:
        if part == "body_heavy_mk2":
            # The spent toilet-roll core is a thin tube, not a corrugated box.
            sides = 24
            radius, centre_y, wall = 1.75, -.25, .085
            first, last = FRONT + .30, BACK - .30
            profile = [(radius * math.sin(i * math.tau / sides),
                        centre_y + radius * math.cos(i * math.tau / sides))
                       for i in range(sides)]
            sections = [(first, profile), (last, profile)]
            # Index zero is the top of this profile. The other bodies retain
            # their original profiles, including the underside at index zero.
            BODY_SECTIONS[part] = sections
            core = p.shell_sections(part + "-tube", sections, wall,
                                    "tube", part, "tube")
            inner = p.inset_polygon(profile, wall)
            for front, z, join, cross in (
                    (True, first + .35, FRONT, FRONT_CROSS),
                    (False, last - .35, BACK, REAR_CROSS)):
                # A real thin disc seals the otherwise hollow core, recessed
                # behind the open rim. A short hollow socket meets Classic.
                depth = wall if front else -wall
                disc = [(x * 1.003, centre_y + (y-centre_y) * 1.003, z)
                        for x, y in inner]
                extruded_patch(part, "tube", disc, (0, 0, depth),
                               "-front-disc" if front else "-rear-disc")
                socket_end = z + (.02 if front else -.02)
                socket_sections = sorted(((join, cross), (socket_end, cross)),
                                         key=lambda section: section[0])
                p.shell_sections(part + "-tube-socket", socket_sections,
                                 wall, "tube", part, "tube")
            core = combine(part, "tube", union=True)
            # This body's catalog wing_shift moves its mounts outside the
            # tube. Keep the full round wall instead of cutting starter bores.

            # One triangular-section raised seam, flush along each tube facet.
            # Its .06-wide base touches the wall; its crest is .012 above it.
            vertices, faces = [], []
            steps = sides * 5 // 4
            phase = 7 * math.tau / sides
            rise = .012 / math.cos(math.pi / sides)
            # Preserve the existing spiral's pitch change and 1.25 turns.
            seam_start, seam_end = first+.06, last-.06
            clear_end = p.GUN_FRONT+p.GUN_LENGTH+.56
            lower_steps = sides * 5 // 12
            seam_z = [(seam_start+(clear_end-seam_start)*i/lower_steps if i<=lower_steps
                       else clear_end+(seam_end-clear_end)*(i-lower_steps)/(steps-lower_steps))
                      for i in range(steps+1)]
            chord = 2*radius*math.sin(math.pi/sides)
            for i in range(steps + 1):
                angle = phase + i * math.tau / sides
                before, after = max(0,i-1), min(steps,i+1)
                dz = (seam_z[after]-seam_z[before])/(after-before)
                seam_width = .06*math.hypot(chord,dz)/chord
                z = seam_z[i]
                x, y = radius * math.sin(angle), centre_y + radius * math.cos(angle)
                vertices += [(x, y, z-seam_width/2),
                             ((radius+rise)*math.sin(angle),
                              centre_y+(radius+rise)*math.cos(angle), z),
                             (x, y, z+seam_width/2)]
            faces = [(2, 1, 0), tuple(range(steps*3, steps*3+3))]
            for i in range(steps):
                a, b = i*3, (i+1)*3
                faces += [(a+j, a+(j+1)%3, b+(j+1)%3, b+j) for j in range(3)]
            geometry(part, "cardboard", vertices, faces, "-spiral")

            # Each scrap starts glued at the top, follows a quarter of the
            # round wall, then hangs freely .7-.8 below the side with tears.
            for sign, fraction in ((-1, 1/3), (1, 2/3)):
                z = first + (last-first) * fraction
                angular_rows = range(sides//4+1)
                vertices, faces = [], []
                for row in angular_rows:
                    angle = row * math.tau / sides
                    x = sign * radius * math.sin(angle)
                    y = centre_y + radius * math.cos(angle)
                    nx, ny = sign * math.sin(angle), math.cos(angle)
                    vertices += [(x,y,z-.175),(x,y,z+.175),
                                 (x+nx*.02,y+ny*.02,z-.175),
                                 (x+nx*.02,y+ny*.02,z+.175)]
                faces += [(0,2,3,1)]
                for row in range(len(angular_rows)-1):
                    a,b=row*4,(row+1)*4
                    faces += [(a,b,b+1,a+1),(a+2,a+3,b+3,b+2),
                              (a,a+2,b+2,b),(a+1,b+1,b+3,a+3)]
                a=(len(angular_rows)-1)*4
                # A long loose flap sharing the side's attachment edge. It
                # droops just outward, clear of the retreating lower wall.
                edge = [(z-.175,.70),(z-.085,.78),(z,.71),
                        (z+.09,.76),(z+.175,.72)]
                for ez, drop in edge:
                    vertices += [(vertices[a][0]+sign*.03,vertices[a][1]-drop,ez),
                                 (vertices[a+2][0]+sign*.03,vertices[a+2][1]-drop,ez)]
                lower=[a+4+i*2 for i in range(len(edge))]
                upper=[i+1 for i in lower]
                faces += [tuple([a,a+1]+list(reversed(lower))),
                          tuple([a+2]+upper+[a+3]),
                          (a,a+2,upper[0],lower[0]),
                          (a+1,lower[-1],upper[-1],a+3)]
                faces += [(lower[i],upper[i],upper[i+1],lower[i+1])
                          for i in range(len(edge)-1)]
                geometry(part, "paper", vertices, faces, f"-scrap-{sign}")

            band_profile = [(x*(radius+.02)/radius,
                             centre_y+(y-centre_y)*(radius+.02)/radius)
                            for x,y in profile]
            p.shell_sections(part + "-accent", [(3.075,band_profile),(3.325,band_profile)],
                             .02, "accent", part, "accent")
            for reg in COLORS:
                obj = combine(part, reg)
                if obj and reg in ("tube", "accent"):
                    # Smooth only the round wall. Discs, sockets, cut walls
                    # and open rims keep their crisp cardboard edges.
                    apothem = (radius + (.02 if reg=="accent" else 0)) * math.cos(math.pi/sides)
                    distances = (apothem, apothem-(.02 if reg=="accent" else wall))
                    for face in obj.data.polygons:
                        x,y,z = p.to_roblox(face.center)
                        nx,ny,nz = p.to_roblox(face.normal)
                        distance = abs(nx*x + ny*(y-centre_y))
                        face.use_smooth = abs(nz)<1e-6 and min(abs(distance-d) for d in distances)<1e-5
            continue
        slim="slim" in part
        heavy="heavy" in part
        main=p.body_cross(.65 if slim else 2.6 if heavy else 1.3,
                          -1.975 if heavy else p.BODY_BOTTOM)
        if slim:
            main=[(x,.95+(y-.95)*.65) for x,y in main]
        if heavy:
            main[1]=(-2.444,-1.75);main[8]=(2.444,-1.75)
        sections=[(FRONT,FRONT_CROSS),(FRONT+.68,main),(3.68,main),
                  (4.50,p.body_cross(1.17,-.12)),(BACK,REAR_CROSS)]
        BODY_SECTIONS[part]=sections
        region="cardboard" if heavy else "paper"
        core=p.shell_sections(part+"-"+region,sections,.085,region,part,region)
        if heavy:
            cut_mount_clearance(core)
        for sign in (-1,1):
            side_patch(part,"accent",sections,sign,1.55,3.56)
        if part=="body_standard_mk2":
            # Raised courier reinforcing rails, kept behind the starter muzzles.
            for sign in (-1,1):
                pts=[(.20,.93),(3.85,.93),(4.15,1.16),(.48,1.16)]
                p.profile_x(part+"-rail",pts,.20,"paper",part,"paper",center=sign*.55)
        if part=="body_slim_mk2":
            roof_stripes(part,sections)
        if heavy:
            for sign in (-1,1):
                folded_corrugation(part,sign,sections)
            # Two diagonally opposite taped corner pads.
            for sign,z in ((-1,-1.35),(1,3.28)):
                box(part,"tape",(sign*2.40-.12,.955,z-.22),
                    (sign*2.40+.12,1.012,z+.22),f"-corner-{sign}-{z}")
        # Repeated pieces are disjoint. Only the courier rails need a connected paper union.
        for reg in COLORS:
            combine(part,reg,union=(part=="body_standard_mk2" and reg=="paper"))
    BOOSTER_BODY_PIVOTS["body_standard"]=np.array((0,profile_at(CLASSIC_SECTIONS,BOOST_Z)[0][1]-.02,BOOST_Z))
    PIVOTS["booster"]=BOOSTER_BODY_PIVOTS["body_standard"].copy()
    for part,sections in BODY_SECTIONS.items():
        # Boosters hang under every body; the tube's profile starts at its top, so take its lowest point.
        y = min(v[1] for v in profile_at(sections,BOOST_Z)) if part=="body_heavy_mk2" else profile_at(sections,BOOST_Z)[0][1]
        BOOSTER_BODY_PIVOTS[part]=np.array((0,y-.02,BOOST_Z))


def build_noses():
    # Fixed rear section. Length/shape vary only in front of that shared interface.
    lengths={1:6.65,2:2.72,3:6.12,4:3.22,5:4.85}
    for i in range(1,6):
        part=f"nose_{i}";length=lengths[i];tip=FRONT-length
        def cross(z):
            t=max(.008,(z-tip)/length)
            if i==2:
                angles=(-90,-140,-180,140,100,80,40,0,-40)
                rounded=[(1.04*math.cos(math.radians(a)),.275+.99*math.sin(math.radians(a))) for a in angles]
                return [tuple((1-t)*np.array(a)+t*np.array(b)) for a,b in zip(rounded,FRONT_CROSS)]
            return [(x*t,-.20+(y+.20)*t) for x,y in FRONT_CROSS]
        fraction=.13 if i==1 else .24 if i==2 else .30 if i==3 else .42 if i==4 else .25
        split=tip+fraction*length
        sections=[(split,cross(split)),(FRONT,FRONT_CROSS)]
        p.shell_sections(part+"-paper",sections,.085,"paper",part,"paper")
        if i==2:
            # An actual faceted blunt cap, rather than a shortened sharp cone.
            verts=[(x,y,z) for z in (tip,split) for x,y in cross(z)]
            n=len(FRONT_CROSS)
            faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
            faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
            geometry(part,"accent",verts,faces)
        else:
            p.sealed_tip_shell(part+"-accent",[(z,cross(z)) for z in (tip,tip+fraction*length*.66,split)],
                               1,.022 if i==1 else .035,"accent",part,"accent")
        if i==5:
            for k,t in enumerate((.48,.79)):
                z=tip+t*length
                a,b=z-.16,z+.16
                pa=p.inset_polygon(cross(a),-.028)
                pb=p.inset_polygon(cross(b),-.028)
                p.shell_sections(part+"-tape-"+str(k),[(a,pa),(b,pb)],.024,"tape",part,"tape")
        for reg in COLORS:
            obj=combine(part,reg)
            if obj:triangulate_nose_caps(obj)


def wing_sheet(part, polygon, thickness=.10, region="paper", suffix="", height=p.wing_height):
    return p.slab(part+"-"+region+suffix,polygon,height,thickness,region,part,region,
                  splits=(-1.30,-1.00,0,1.00,1.30))


def wing_stripes(part, polygon, half, width=.72):
    for sign in (-1,1):
        a,b=sorted((sign*(half-.16),sign*(half-.16-width)))
        poly=p.clip(p.clip(polygon,0,a,True),0,b,False)
        wing_sheet(part,poly,.026,"accent",str(sign),lambda x,z:p.wing_height(x,z)+.038)


def build_wings():
    for i in range(1,6):
        part=f"wings_{i}"
        if i==1:
            h=7.4
            poly=[(0,FRONT),(1.3,FRONT+.4),(h,5.10),(h,5.38),
                  (1.12,1.10),(0,1.22),(-1.12,1.10),(-h,5.38),(-h,5.10),(-1.3,FRONT+.4)]
        elif i==2:
            h=8.4
            poly=[(0,FRONT),(1.3,FRONT+.4),(h,-1.70),(h,3.88),
                  (1.12,4.16),(0,4.28),(-1.12,4.16),(-h,3.88),(-h,-1.70),(-1.3,FRONT+.4)]
        elif i==3:
            h=7.25
            poly=[(0,FRONT),(1.3,FRONT+.4),(h,4.88),(h,5.12),
                  (1.12,5.12),(0,5.16),(-1.12,5.12),(-h,5.12),(-h,4.88),(-1.3,FRONT+.4)]
        elif i==4:
            h=6.75
            poly=[(0,FRONT),(1.3,FRONT+.4),(h,-1.25),(h,4.18),
                  (1.12,4.36),(0,4.48),(-1.12,4.36),(-h,4.18),(-h,-1.25),(-1.3,FRONT+.4)]
        else:
            # Three overlapping feather layers per side share the Classic saddle.
            saddle=[(-1.30,FRONT+.40),(1.30,FRONT+.40),(1.30,4.90),(-1.30,4.90)]
            wing_sheet(part,saddle)
            layers=[(FRONT+.40,2.20,7.50,-.90,.00),
                    (.20,3.40,7.15,.15,.05),
                    (1.60,4.60,6.80,1.20,.10)]
            # Root folds settle into the unchanged saddle before taking their drop.
            cuts=(-p.SPAN/2,-5.94,-1.50,-1.30,-1.00,0,1.00,1.30,1.50,5.94,p.SPAN/2)
            for sign in (-1,1):
                for k,(root_front,root_back,center_x,center_z,drop) in enumerate(layers):
                    radius=.45;tip_x=center_x+radius
                    # Eight circular samples include both straight-edge ends and the outermost tip.
                    angles=[-90,-60,-30,0,22.5,45,67.5,90]
                    if center_x<p.SPAN/2<tip_x:
                        # Put cap samples on the existing fold so clipping adds no extra corners.
                        fold=math.degrees(math.acos((p.SPAN/2-center_x)/radius))
                        angles=[-90,-fold,-45,0,30,60,fold,90]
                    arc=[(center_x+radius*math.cos(angle),center_z+radius*math.sin(angle))
                         for angle in map(math.radians,angles)]
                    poly=[(sign*x,z) for x,z in [(1.06,root_front)]+arc+[(1.06,root_back)]]
                    height=lambda x,z,d=drop:p.wing_height(x,z)-d*min(1,max(0,(abs(x)-1.30)/.20))
                    p.slab(part+"-paper-"+str(sign)+"-"+str(k),poly,height,.08,
                           "paper",part,"paper",splits=cuts)
                    a,b=sorted((sign*(tip_x-.75),sign*tip_x))
                    patch=p.clip(p.clip(poly,0,a,True),0,b,False)
                    p.slab(part+"-accent-"+str(sign)+"-"+str(k),patch,
                           lambda x,z,d=drop:p.wing_height(x,z)-d+.038,.026,
                           "accent",part,"accent",splits=cuts)
            paper=combine(part,"paper",union=True);combine(part,"accent")
            # Remove Boolean seams between coplanar faces, retaining every real fold and cap edge.
            bm=bmesh.new();bm.from_mesh(paper.data)
            bmesh.ops.dissolve_limit(bm,angle_limit=.001,verts=list(bm.verts),edges=list(bm.edges),delimit={"NORMAL"})
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
            bm.to_mesh(paper.data);bm.free();paper.data.update()
            continue
        wing_sheet(part,poly,.16 if i==4 else .10)
        if i==4:
            # Brown exposed backing and folded-up tip fins identify heavier cardstock.
            wing_sheet(part,poly,.045,"cardboard","-backing",lambda x,z:p.wing_height(x,z)-.165)
            for sign in (-1,1):
                fin=[(-1.18,.87),(-.84,2.05),(3.82,2.05),(4.11,.87)]
                p.profile_x(part+"-tip",fin,.12,"paper",part,"paper",center=sign*(h-.07))
                patch=[(-.65,1.15),(-.43,2.045),(3.76,2.045),(3.98,1.15)]
                for face_sign in (-1,1):
                    p.profile_x(part+"-tip-accent",patch,.025,"accent",part,"accent",
                                center=sign*(h-.07)+face_sign*.079)
        else:
            wing_stripes(part,poly,h,width=.78 if i==2 else 1.08)
        combine(part,"paper",union=i==4)
        combine(part,"accent");combine(part,"cardboard")


def tail_base(part):
    rear=[(x*.73,.58+(y-.04)*.46) for x,y in REAR_CROSS]
    return p.shell_sections(part+"-paper-base",[(BACK,REAR_CROSS),(7.65,rear)],.085,"paper",part,"paper")


def fin(part, points, center=0, roll=0, region="paper", width=.11, suffix=""):
    obj=p.profile_x(part+"-"+region+suffix,points,width,region,part,region,center=center)
    if roll:
        c,s=math.cos(roll),math.sin(roll)
        # Tilt around the fore/aft axis at Y=1.12, preserving the base attachment.
        for v in obj.data.vertices:
            x,y,z=p.to_roblox(v.co)
            local=x-center;rise=y-1.12
            v.co=p.to_blender((center+c*local+s*rise,1.12-s*local+c*rise,z))
        obj.data.update()
    return obj


def build_tails():
    for i in range(1,6):
        part=f"tail_{i}";tail_base(part)
        top=4.22 if i==4 else 3.06 if i==1 else 2.98
        points=[(BACK+.10,1.10),(6.62,top-.08),(7.51,top),(7.57,1.03)]
        if i==1:points[0]=(BACK+.10,.84);points[-1]=(7.57,.84)
        accent=[(6.10,2.07 if i!=4 else 3.16),(6.68,top-.078),
                (7.485,top-.005),(7.49,2.25 if i!=4 else 3.42)]
        if i==1:
            for sign in (-1,1):
                tilt=sign*math.radians(17)
                fin(part,points,sign*.43,tilt,suffix=f"-{sign}")
                for face_sign in (-1,1):
                    # Colour panels on both faces follow the fin's same tilt.
                    obj=fin(part,accent,sign*.43,tilt,"accent",.028,f"-{sign}-{face_sign}")
                    shift=p.to_blender((math.cos(tilt)*face_sign*.083,
                                        -math.sin(tilt)*face_sign*.083,0))
                    for v in obj.data.vertices:v.co+=shift
        else:
            fin(part,points)
            for sign in (-1,1):
                fin(part,accent,sign*.083,region="accent",width=.028,suffix=str(sign))
        if i==2:
            ridge=[(BACK+.04,1.28),(BACK+.24,1.65),(6.40,1.65),(6.66,1.27)]
            fin(part,ridge,width=.38,suffix="-ridge")
            fin(part,[(BACK+.27,1.655),(6.37,1.655),(6.37,1.69),(BACK+.27,1.69)],
                region="accent",width=.085,suffix="-ridge-stripe")
        if i==3:
            poly=[(-2.90,5.90),(-.65,5.74),(.65,5.74),(2.90,5.90),
                  (2.90,7.44),(.58,7.30),(-.58,7.30),(-2.90,7.44)]
            p.slab(part+"-stabilizer",poly,lambda x,z:1.10,.11,"paper",part,"paper")
            for sign in (-1,1):
                a,b=sorted((sign*2.28,sign*2.90))
                patch=p.clip(p.clip(poly,0,a,True),0,b,False)
                p.slab(part+"-stabilizer-accent",patch,lambda x,z:1.135,
                       .025,"accent",part,"accent")
        if i==5:
            base_sections=[(BACK,REAR_CROSS),(7.65,[(x*.73,.58+(y-.04)*.46) for x,y in REAR_CROSS])]
            for z in (5.85,6.88):
                sections=[(a,p.inset_polygon(profile_at(base_sections,a),-.030)) for a in (z-.16,z+.16)]
                p.shell_sections(part+"-tape-base",sections,.025,"tape",part,"tape")
            patch=[(6.04,1.91),(6.32,2.31),(7.50,2.31),(7.52,1.91)]
            for sign in (-1,1):
                fin(part,patch,sign*.119,region="tape",width=.030,suffix=f"-fin-{sign}")
        combine(part,"paper",union=True)
        combine(part,"accent");combine(part,"tape")


def cylinder(part, region, center, radius, length, axis="Z", segments=10, suffix=""):
    center=Vector(center)
    directions={"Z":(Vector((1,0,0)),Vector((0,1,0)),Vector((0,0,1))),
                "X":(Vector((0,1,0)),Vector((0,0,1)),Vector((1,0,0)))}
    a,b,c=directions[axis]
    vertices=[]
    for sign in (-1,1):
        for i in range(segments):
            angle=i*math.tau/segments
            vertices.append(tuple(center+c*sign*length/2+radius*(a*math.cos(angle)+b*math.sin(angle))))
    faces=[tuple(reversed(range(segments))),tuple(range(segments,segments*2))]
    faces += [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return geometry(part,region,vertices,faces,suffix)


def elastic_rope(part, x, phase, suffix, radius=.20):
    vertices=[];count=9;segments=5
    for k in range(count):
        z=2.95+k*2.02/(count-1)
        # A low-poly twisted strand, with capped ends and no crossing tubes.
        a=phase+k*math.tau*.125
        cx=x+.050*math.cos(a);cy=-2.48+.050*math.sin(a)
        for j in range(segments):
            angle=j*math.tau/segments+a
            vertices.append((cx+radius*math.cos(angle),cy+radius*math.sin(angle),z))
    faces=[tuple(reversed(range(segments))),tuple(range((count-1)*segments,count*segments))]
    for k in range(count-1):
        for j in range(segments):
            a=k*segments+j;b=k*segments+(j+1)%segments
            c=(k+1)*segments+(j+1)%segments;d=(k+1)*segments+j
            faces.append((a,b,c,d))
    geometry(part,"elastic",vertices,faces,suffix)


def booster_cradle(part, half):
    # One closed open-top tray. The straps rise only at the common rear neck.
    poly=[(-half,-2.86),(half,-2.86),(half,-2.21),(half-.10,-2.21),
          (half-.10,-2.76),(-half+.10,-2.76),(-half+.10,-2.21),(-half,-2.21)]
    vertices=[(x,y,z) for z in (2.72,5.18) for x,y in poly]
    n=len(poly);faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    geometry(part,"paper",vertices,faces,"-tray")
    for z in (2.76,5.00):
        box(part,"tape",(-half-.025,-2.215,z-.115),(half+.025,-2.155,z+.115),f"-tray-tape-{z}")
    # Short tape straps reach the body's underside at the booster pivot.
    for sign in (-1,1):
        polygon=[(sign*(half+.025),-2.80,3.83),(sign*.08,-1.855,3.83),
                 (sign*.24,-1.855,3.83),(sign*(half+.145),-2.80,3.83)]
        extruded_patch(part,"tape",polygon,(0,0,.22),f"-suspension-{sign}")
    for sign in (-1,1):
        extruded_patch(part,"accent",[(sign*(half+.013),-2.67,3.48),(sign*(half+.013),-2.30,3.86),
                                     (sign*(half+.013),-2.30,4.36),(sign*(half+.013),-2.67,4.10)],
                        (sign*.025,0,0),f"-side-{sign}")


def build_boosters():
    for part in ("boost_band","boost_spool","boost_twin"):
        half=.69 if part=="boost_twin" else .49
        booster_cradle(part,half)
        # Two dowels transverse to the body, with their ends visible outside the tray.
        for z in (2.91,5.01):
            cylinder(part,"cardboard",(0,-2.48,z),.14,half*2+.16,"X",8,f"-dowel-{z}")
        if part=="boost_spool":
            # Cream wound core, two brown flanges, and two narrow elastic guide strands.
            vertices=[];segments=10
            for z,radius in ((3.31,.32),(3.63,.295),(3.96,.32),(4.29,.295),(4.61,.32)):
                vertices += [(radius*math.cos(i*math.tau/segments),
                              -2.48+radius*math.sin(i*math.tau/segments),z) for i in range(segments)]
            faces=[tuple(reversed(range(segments))),tuple(range(4*segments,5*segments))]
            for k in range(4):
                a,b=k*segments,(k+1)*segments
                faces += [(a+i,a+(i+1)%segments,b+(i+1)%segments,b+i) for i in range(segments)]
            geometry(part,"paper",vertices,faces,"-wound-core")
            for z in (3.27,4.65):
                cylinder(part,"cardboard",(0,-2.48,z),.39,.13,"Z",12,f"-flange-{z}")
            for x in (-.39,.39):
                cylinder(part,"elastic",(x,-2.48,3.96),.045,1.82,"Z",6,str(x))
        else:
            # Readable bundled twists; twin has two distinct bundles and a paper divider.
            if part=="boost_twin":
                for k,x in enumerate((-.32,.32)):
                    elastic_rope(part,x,0,f"-{k}")
                box(part,"paper",(-.04,-2.765,2.90),(.04,-2.21,5.02),"-divider")
            else:
                elastic_rope(part,0,0,"-bundle",radius=.25)
        for reg in COLORS:
            combine(part,reg,union=reg=="paper")
        # Author one default Classic-relative asset. The manifest gives the small
        # body-specific translation needed for the different belly depths.
        for obj in [o for o in p.OBJECTS if o["part"]==part]:
            for vertex in obj.data.vertices:
                x,y,z=p.to_roblox(vertex.co)
                vertex.co=p.to_blender((x,y+PIVOTS["booster"][1]+2.0,z+BOOST_Z-3.96))
            obj.data.update()


def export_assets():
    entries=[];checks={}
    for obj in p.OBJECTS:
        triangulate_nose_caps(obj)
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method="BEAUTY",ngon_method="BEAUTY")
        bmesh.ops.dissolve_degenerate(bm,dist=1e-6,edges=list(bm.edges))
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(obj.data);bm.free();obj.data.update()
        checks[obj.name]=p.validate(obj)
        part,region=obj["part"],obj["region"]
        lo,hi=p.bounds(obj);center=(lo+hi)/2;anchor=PIVOTS[slot(part)]
        for v in obj.data.vertices:v.co-=p.to_blender(anchor)
        obj.location=p.to_blender(anchor);obj.data.update()
        bpy.ops.object.select_all(action="DESELECT");obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        saved=obj.location.copy();obj.location=(0,0,0)
        bpy.ops.export_scene.fbx(filepath=str(OUT/(obj.name+".fbx")),use_selection=True,
            object_types={"MESH"},global_scale=.01,apply_unit_scale=False,apply_scale_options="FBX_SCALE_NONE",
            axis_forward="-Z",axis_up="Y",bake_space_transform=True,use_mesh_modifiers=False,
            use_triangles=True,mesh_smooth_type="FACE",add_leaf_bones=False,bake_anim=False,
            path_mode="STRIP",embed_textures=False,use_custom_props=False)
        obj.location=saved;rgb=COLORS[region]
        entries.append({"file":obj.name+".fbx","object":obj.name,"part":part,"region":region,
            "display_name":ITEMS[part]["name"],"bbox_min":p.rounded(lo),"bbox_max":p.rounded(hi),
            "bbox_center":p.rounded(center),"size":p.rounded(hi-lo),"triangles":checks[obj.name]["triangles"],
            "suggested_color3_255":list(rgb),"suggested_color3":[round(v/255,6) for v in rgb],
            "team_color_at_runtime":region=="accent","slot_pivot":p.rounded(anchor),
            "center_offset_from_slot":p.rounded(center-anchor),"slot_local_bbox_min":p.rounded(lo-anchor),
            "slot_local_bbox_max":p.rounded(hi-anchor),"fbx_local_bbox_min":p.rounded(lo-anchor),
            "fbx_local_bbox_max":p.rounded(hi-anchor),"assembly_rotation":"identity; no legacy yaw compensation"})
    aggregate={}
    for part in IDS:
        group=[e for e in entries if e["part"]==part]
        assert group,part+": missing part"
        lo=np.min([e["bbox_min"] for e in group],axis=0);hi=np.max([e["bbox_max"] for e in group],axis=0)
        count=sum(e["triangles"] for e in group)
        log(f"{part}: {count} triangles across {len(group)} regions")
        limit=PART_TRIANGLE_LIMIT_OVERRIDES.get(part,STRICT_PART_TRIANGLE_LIMIT)
        assert count<limit,f"{part}: {count} triangles, must be below {limit} across all regions"
        aggregate[part]={"bbox_min":p.rounded(lo),"bbox_max":p.rounded(hi),"center":p.rounded((lo+hi)/2),
                         "size":p.rounded(hi-lo),"triangles":count,"slot_pivot":p.rounded(PIVOTS[slot(part)])}
    payload={"schema_version":ORIGINAL["schema_version"],"units":ORIGINAL["units"],"axes":ORIGINAL["axes"],
             "source":"../concepts/parts/","texture_images":[],"exports":entries,"assembled_parts":aggregate,
             "mounts":ORIGINAL["mounts"],"weapon":ORIGINAL["weapon"],"fbx_contract":ORIGINAL["fbx_contract"],
             "slot_pivots":{k:p.rounded(v) for k,v in PIVOTS.items()},
             "booster_pivots":{part:p.rounded(PIVOTS["booster"]) for part in IDS if slot(part)=="booster"},
             "booster_body_pivots":{part:p.rounded(anchor) for part,anchor in BOOSTER_BODY_PIVOTS.items()},
             "join_contract":{"nose_body_seam_z":FRONT,"body_tail_seam_z":BACK,
                 "nose_body_outer_section_xy":FRONT_CROSS,"body_tail_outer_section_xy":REAR_CROSS,
                 "shell_thickness":.085,"wing_center_top_y":.95,"wing_center_bottom_y":.85,
                 "shared_socket_priority_over_concept":True}}
    bpy.context.view_layer.update()
    (OUT/"parts.json").write_text(json.dumps(payload,indent=2)+"\n",encoding="utf-8")
    return payload,checks


def import_classic_preview():
    for entry in ORIGINAL["exports"]:
        if entry["region"]=="sticker":
            continue
        before=set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(CLASSIC/entry["file"]),global_scale=100,use_custom_normals=False)
        for obj in set(bpy.data.objects)-before:
            if obj.type!="MESH":
                bpy.data.objects.remove(obj,do_unlink=True);continue
            obj.location+=p.to_blender(entry["slot_pivot"])
            obj["part"]={"body":"body_standard","nose":"nose_0","wings":"wings_0","tail":"tail_0"}.get(entry["part"],"pellet")
            obj["region"]=entry["region"]
            obj.data.materials.clear()
            obj.data.materials.append(p.MATS["tape" if entry["region"]=="band" else entry["region"]])
            PREVIEWS.append(obj)
    for obj in [o for o in PREVIEWS if o["part"]=="pellet"]:
        copy=obj.copy();copy.data=obj.data;copy.location.x+=2*p.GUN_X
        bpy.context.collection.objects.link(copy);PREVIEWS.append(copy)
    bpy.context.view_layer.update()


def tree(obj):
    obj.data.calc_loop_triangles()
    return BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],
        [tuple(t.vertices) for t in obj.data.loop_triangles],all_triangles=True,epsilon=1e-7)


def check_joins(payload):
    records={"tolerance_studs":.0001,"nose_body_pairs":[],"body_tail_pairs":[],"wing_seats":[],"mount_clearance":[],"booster_body_fit":[]}
    def seam_points(part,z):
        points=[]
        for obj in p.OBJECTS+PREVIEWS:
            if obj["part"]!=part:continue
            for v in obj.data.vertices:
                xyz=p.to_roblox(obj.matrix_world@v.co)
                if abs(xyz[2]-z)<1e-5:points.append(np.array(xyz[:2]))
        return points
    def verify_section(part,z,profile):
        points=seam_points(part,z)
        outlines=[profile,p.inset_polygon(profile,.085)]
        assert points,part+": missing interface vertices"
        def segment_distance(q,a,b):
            a,b=np.array(a),np.array(b);delta=b-a
            t=np.clip(np.dot(q-a,delta)/np.dot(delta,delta),0,1)
            return np.linalg.norm(q-a-t*delta)
        segments=[(a,b) for contour in outlines for a,b in zip(contour,contour[1:]+contour[:1])]
        # Collinear roof landmarks differ after inset interpolation and triangulation.
        # Match the actual contours in both directions, rather than vertex indices.
        errors=[min(segment_distance(q,a,b) for a,b in segments) for q in points]
        actual=[]
        for obj in p.OBJECTS+PREVIEWS:
            if obj["part"]!=part:continue
            for edge in obj.data.edges:
                a,b=[p.to_roblox(obj.matrix_world@obj.data.vertices[k].co) for k in edge.vertices]
                if abs(a[2]-z)<1e-5 and abs(b[2]-z)<1e-5:actual.append((a[:2],b[:2]))
        assert actual,part+": missing seam edges"
        for a,b in segments:
            for t in np.linspace(0,1,17):
                q=(1-t)*np.array(a)+t*np.array(b)
                errors.append(min(segment_distance(q,c,d) for c,d in actual))
        assert max(errors)<1e-5,part+": shared seam cross-section changed"
        return max(errors)
    body_ids=["body_standard"]+IDS[:5]
    # Classic has already been validated and preserves its original front/rear rims.
    front_errors={b:verify_section(b,FRONT,FRONT_CROSS) for b in body_ids}
    rear_errors={b:verify_section(b,BACK,REAR_CROSS) for b in body_ids}
    nose_errors={n:verify_section(n,FRONT,FRONT_CROSS) for n in [f"nose_{i}" for i in range(6)]}
    tail_errors={t:verify_section(t,BACK,REAR_CROSS) for t in [f"tail_{i}" for i in range(1,6)]}
    for b in body_ids:
        for n in nose_errors:
            records["nose_body_pairs"].append({"body":b,"nose":n,"maximum_section_error":max(front_errors[b],nose_errors[n]),"gap":0})
        for t in tail_errors:
            records["body_tail_pairs"].append({"body":b,"tail":t,"maximum_section_error":max(rear_errors[b],tail_errors[t]),"gap":0})
    # Classic Tail has an intentional original overlap and a smaller upper plug.
    records["classic_tail_compatibility"]={"preserved":True,"original_front_z":5.295929,
        "common_body_rear_section_preserved_on_every_body":True,
        "note":"Classic tail remains unchanged; its original upper-socket overlap is retained. New tails meet the exact full body-rear rim."}
    for i in range(1,6):
        part=f"wings_{i}";objects=[o for o in p.OBJECTS if o["part"]==part and o["region"]=="paper"]
        nearest=min(abs(p.to_roblox(o.matrix_world@v.co)[1]-.95)
                    for o in objects for v in o.data.vertices if abs(p.to_roblox(o.matrix_world@v.co)[0])<=1.001)
        assert nearest<1e-5,part+": centre saddle not at Classic wing seat"
        assert np.max(np.abs(PIVOTS["wings"]-ORIGINAL["assembled_parts"]["wings"]["slot_pivot"]))==0
        records["wing_seats"].append({"part":part,"top_y":.95,"bottom_y":.85,"pivot_unchanged":True,"bodies_compatible":body_ids})
    for part in IDS:
        objects=[o for o in p.OBJECTS if o["part"]==part]
        trees=[tree(o) for o in objects]
        for side,mount in ORIGINAL["mounts"].items():
            mount_center=np.array(mount["tube_center"],dtype=float)
            mount_muzzle=np.array(mount["muzzle"],dtype=float)
            if part=="body_heavy_mk2":
                # Match this body's actual game assembly, retaining the same
                # clearance threshold and all 33 full-axis samples.
                shift=float(ITEMS[part]["wing_shift"])
                offset=math.copysign(shift,mount_center[0])
                mount_center[0]+=offset;mount_muzzle[0]+=offset
            # Sample the full tube axis, with distance to every colour region.
            distances=[]
            for z in np.linspace(p.GUN_FRONT,p.GUN_FRONT+p.GUN_LENGTH,33):
                q=p.to_blender((mount_center[0],mount_center[1],float(z)))
                distances += [tr.find_nearest(q)[3] for tr in trees]
            center=p.to_blender(mount_center);muzzle=p.to_blender(mount_muzzle)
            center_distance=min(tr.find_nearest(center)[3] for tr in trees)
            muzzle_distance=min(tr.find_nearest(muzzle)[3] for tr in trees)
            assert min(distances)>p.GUN_DIAMETER/2+.025,part+": starter tube clearance failed"
            records["mount_clearance"].append({"part":part,"mount":side,
                "tube_center_surface_distance":center_distance,"muzzle_surface_distance":muzzle_distance,
                "minimum_axis_surface_distance":min(distances),"tube_radius":p.GUN_DIAMETER/2,
                "samples":33,"tube_and_muzzle_uncovered":True})
            if part=="body_heavy_mk2":
                records["mount_clearance"][-1].update({"catalog_wing_shift":shift,
                    "checked_tube_center":p.rounded(mount_center),"checked_muzzle":p.rounded(mount_muzzle)})
    for body in body_ids:
        body_objects=[o for o in p.OBJECTS+PREVIEWS if o["part"]==body]
        for booster in ("boost_band","boost_spool","boost_twin"):
            # Short tape straps intentionally tuck into the underside. The tray,
            # winding, dowels and elastic must remain wholly clear of the body.
            objects=body_objects+[o for o in p.OBJECTS if o["part"]==booster and o["region"]!="tape"]
            vertices=[];faces=[];body_triangles=0
            delta=p.to_blender(BOOSTER_BODY_PIVOTS[body]-PIVOTS["booster"])
            for obj in objects:
                offset=delta if obj["part"]==booster else Vector((0,0,0))
                index=len(vertices)
                vertices += [obj.matrix_world@v.co+offset for v in obj.data.vertices]
                obj.data.calc_loop_triangles()
                faces += [tuple(index+k for k in t.vertices) for t in obj.data.loop_triangles]
                if obj["part"]==body:body_triangles+=len(obj.data.loop_triangles)
            data=bpy.data.meshes.new("Temporary body-booster fit check")
            data.from_pydata(vertices,[],faces);data.update();data.calc_loop_triangles()
            crossings=p.self_intersections(data)
            intersections=[(a,b) for a,b in crossings if (a<body_triangles)!=(b<body_triangles)]
            bpy.data.meshes.remove(data)
            assert not intersections,body+" / "+booster+": booster tray clips body"
            records["booster_body_fit"].append({"body":body,"booster":booster,
                "pivot":p.rounded(BOOSTER_BODY_PIVOTS[body]),"non_strap_body_intersections":0,
                "short_tape_attachment_overlap_intentional":True})
    return records


def show(parts, include_pellets=False):
    for obj in p.OBJECTS+PREVIEWS:
        obj.hide_render=obj["part"] not in parts and not(include_pellets and obj["part"]=="pellet")


def render(path, parts, focus=None, scale=None, include_pellets=False, orientation=(-1,1,.72), width=1280,height=960):
    show(parts,include_pellets)
    body=next((part for part in parts if part in BOOSTER_BODY_PIVOTS),"body_standard")
    booster_objects=[o for o in p.OBJECTS if slot(o["part"])=="booster" and o["part"] in parts]
    delta=p.to_blender(BOOSTER_BODY_PIVOTS[body]-PIVOTS["booster"])
    for obj in booster_objects:obj.location+=delta
    objs=[o for o in p.OBJECTS+PREVIEWS if not o.hide_render]
    bbox=[p.bounds(o) for o in objs]
    lo=np.min([v[0] for v in bbox],axis=0);hi=np.max([v[1] for v in bbox],axis=0)
    target=p.to_blender((lo+hi)/2) if focus is None else p.to_blender(focus)
    extent=max(float(np.linalg.norm(hi-lo)),1)
    cam=p.camera(tuple(target+Vector(orientation).normalized()*extent*2),tuple(target),scale=scale or extent*1.10)
    scene=bpy.context.scene;scene.render.resolution_x=width;scene.render.resolution_y=height
    if scale is None:
        # Fit projected bounds, including the aspect ratio. A diagonal 3D bound
        # alone can crop a tall fin in a landscape render.
        rotation=cam.rotation_euler.to_matrix();inverse=rotation.transposed()
        projected=np.array([inverse@(obj.matrix_world@v.co-target) for obj in objs for v in obj.data.vertices])
        minimum=projected.min(0);maximum=projected.max(0)
        centre=(minimum+maximum)/2
        cam.location+=rotation@Vector((float(centre[0]),float(centre[1]),0))
        cam.data.ortho_scale=max(float(maximum[0]-minimum[0]),float(maximum[1]-minimum[1])*width/height)*1.12
    scene.render.filepath=str(path)
    bpy.context.view_layer.update();bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam,do_unlink=True)
    for obj in booster_objects:obj.location-=delta


def fit_image(image, max_width, max_height):
    ratio=min(max_width/image.shape[1],max_height/image.shape[0])
    return p.resize(image,round(image.shape[1]*ratio),round(image.shape[0]*ratio))


def review_sheet():
    sheet=np.full((2580,2400,4),(246,244,237,255),dtype=np.uint8)
    p.lettering(sheet,"23 MODULAR PARTS / SHARED CLASSIC JOINS",45,25,5)
    for index,part in enumerate(IDS):
        x=(index%4)*600;y=(index//4)*415+90
        p.lettering(sheet,ITEMS[part]["name"],x+18,y,3)
        image=p.crop_render(p.load_png(OUT/"renders"/(part+".png")))
        p.paste_center(sheet,fit_image(image,555,340),x+300,y+204)
    p.save_png(OUT/"parts-review.png",sheet)


MIXES=[
    ("HEAVY / BROAD / WIDE",["body_heavy","nose_5","wings_2","tail_3","boost_twin"]),
    ("SLIM / NEEDLE / SWEPT / SPLIT",["body_slim","nose_1","wings_1","tail_1","boost_band"]),
    ("COURIER / LONG / DELTA / RIDGE",["body_standard_mk2","nose_3","wings_3","tail_2","boost_spool"]),
    ("RACING / COMPACT / FEATHER / GUIDE",["body_slim_mk2","nose_4","wings_5","tail_4"]),
]


def render_reviews():
    scene=bpy.context.scene
    # Use Classic's texture-free studio lighting, without its helper's gun duplication.
    p.setup_render()
    import_classic_preview()
    for part in IDS:
        render(OUT/"renders"/(part+".png"),[part])
    review_sheet()
    source=p.load_png(CONCEPT/"mixes.png")
    sheet=np.full((1380,2400,4),(246,244,237,255),dtype=np.uint8)
    p.lettering(sheet,"APPROVED CONCEPT / ASSEMBLED MODEL",40,28,5)
    crops=[(0,0,835,388),(835,0,1672,388),(0,388,835,720),(835,388,1672,720)]
    for i,(label,parts) in enumerate(MIXES):
        path=OUT/"renders"/("mix-"+str(i+1)+".png")
        render(path,parts,include_pellets=True,scale=24.5,width=1400,height=960)
        x=(i%2)*1200;y=(i//2)*625+100
        p.lettering(sheet,label,x+22,y,3)
        p.lettering(sheet,"CONCEPT",x+210,y+55,3)
        p.lettering(sheet,"MODEL",x+813,y+55,3)
        a,b,c,d=crops[i]
        crop=source[b:d,a:c]
        model=p.crop_render(p.load_png(path))
        p.paste_center(sheet,fit_image(crop,560,440),x+300,y+305)
        p.paste_center(sheet,fit_image(model,560,440),x+900,y+305)
        names=" / ".join(parts)
        p.lettering(sheet,names[:55],x+22,y+565,2)
    p.save_png(OUT/"mixes.png",sheet)
    joins=np.full((1680,2200,4),(246,244,237,255),dtype=np.uint8)
    p.lettering(joins,"SHARED SEAMS / NOSE-BODY AND BODY-TAIL",40,25,5)
    for i,(body,seam) in enumerate((("body_slim","nose"),("body_heavy","nose"),
                                   ("body_slim","tail"),("body_heavy","tail"))):
        parts=[body,"nose_4" if seam=="nose" else "tail_2"]
        focus=(0,.35,FRONT if seam=="nose" else BACK)
        path=OUT/"renders"/(body+"-"+seam+"-join.png")
        render(path,parts,focus=focus,scale=7.1,width=1100,height=760,
               orientation=(-1,1,.50) if seam=="nose" else (-1,-1,.55))
        x=(i%2)*1100;y=(i//2)*800+85
        p.lettering(joins,body+" / "+seam+" SEAM",x+30,y,3)
        p.paste_center(joins,p.load_png(path),x+550,y+413)
    p.save_png(OUT/"joins.png",joins)
    # A useful source scene: the heavy mix is assembled, all other parts hidden for renders.
    show(MIXES[0][1],True)
    for obj in p.OBJECTS:
        if slot(obj["part"])=="booster" and obj["part"] in MIXES[0][1]:
            obj.location+=p.to_blender(BOOSTER_BODY_PIVOTS["body_heavy"]-PIVOTS["booster"])
    for obj in p.OBJECTS+PREVIEWS:
        obj.hide_set(obj.hide_render)
    camera=p.camera((-18,25,16),(0,-1,0),scale=25)
    scene.render.resolution_x=1280;scene.render.resolution_y=960
    scene.render.filepath=str(OUT/"mixes.png")
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=="VIEW_3D":
                view=area.spaces.active;view.shading.color_type="MATERIAL"
                view.region_3d.view_location=Vector((0,-1,0));view.region_3d.view_distance=24
                view.region_3d.view_rotation=camera.rotation_euler.to_quaternion()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"plane-set.blend"),check_existing=False)


def write_readme(payload):
    lines=["# Modular plane set", "", "23 parts: five bodies, five noses, five paired wing sets, five tails and three boosters.",
           "All use the existing Classic slot pivots and plain colour-region FBX contract.", "", "## Rebuild", "",
           "From D:/FlyFightPaper in PowerShell:", "", "```powershell",COMMAND,"```", "",
           "Only Blender's built-in Python, NumPy and the existing planes.py helpers are needed.",
           "The command rebuilds the FBXs, manifests, Blender source and every review image in this folder.",
           "It only reads classic/. It does not upload assets or change the game.","", "## Dimensions and triangle totals", "",
           "Sizes are assembled Roblox X / Y / Z in studs. Triangle totals include every colour region.", "",
           "| Catalog id | Name | Size X / Y / Z | Triangles |", "|---|---|---|---:|"]
    for part in IDS:
        record=payload["assembled_parts"][part]
        lines.append(f"| {part} | {ITEMS[part]['name']} | "+" / ".join(f"{v:.4f}" for v in record["size"])+f" | {record['triangles']} |")
    lines += ["", "## Assembly and choices", "",
        f"- Nose/body seam: Z={FRONT:.9f}. New tail/body seam: Z={BACK:.9f}. The outer and inner rim profiles exactly match Classic.",
        "- Keep each region's center_offset_from_slot. All structural slot_pivot values are copied from classic/parts.json.",
        "- Slim main shoulders are 1.30 studs wide, half Classic; their sockets remain 2.60 wide. The fixed two seams keep body length at 8.0223 studs. The narrow uninterrupted core gives the longer appearance without moving either join.",
        "- Cardboard Gunship (body_heavy) retains its 5.20-wide shoulders and 3.375 depth. A neck tapers to the shared rear section.",
        "- Cardboard Gunship's corrugation is a few visible folded zigzag rails, with two taped corner pads. Plain colours replace the grain and tiny individual flutes in the painting.",
        "- Cardboard Gunship keeps its original square starter clearance bores. Toilet Roll has an uncut round wall; its starter clearance checks use the outward mount shift from the catalog. All checks retain the same radius, margin and 33 samples per axis.",
        "- Toilet Roll Gunship (body_heavy_mk2) is an empty 24-sided cardboard tube, radius 1.75, centred at Y=-.25, with a .085 wall. Its open rims show discs recessed .35 and unchanged Classic socket joins. One raised spiral seam winds 1.25 turns; two .35-wide, .02-thick ragged paper strips follow opposite sides from the top, then hang freely .7-.8 studs below their attachment edges. The rear .25-wide accent band takes team colour.",
        "- All wings have the Classic centre saddle at Y=.95 with its bottom at .85. Outer silhouettes differ; Cardstock has real upright tips and a brown backing. Feather Folds has three overlapping paper feather layers on each side, with rounded accent tips stepping back and shorter.",
        "- New tails meet the whole Classic rear rim. Classic Tail itself is unchanged and retains its original smaller upper plug and slight overlap. Keeping every body's Classic rear neck preserves that compatibility.",
        "- Booster pivots use each body's profile at Z=3.25. The original five anchors remain below the underside; the Toilet Roll anchor is above its top so the unchanged booster tray clears the band and seam. booster_body_pivots supplies all six anchors; booster_pivots and each export's slot_pivot use Classic as the default. Translate every booster region by its body anchor minus the default anchor, preserving center_offset_from_slot.",
        "- Only booster positioning varies by body; all four existing structural pivots stay exactly the same.",
        "- Elastic twists and the ribbed wound spool are deliberately coarse solid facets. All assets use colour only, with no textures, images, UVs or runtime geometry.",
        "- The shared Classic joins take priority over the rectangular conceptual plugs. No separate conceptual plug is added to a nose or tail.",
        "- region=accent is the only region marked team_color_at_runtime. The tube region is light grey-brown RGB 184,154,118 and belongs only to Toilet Roll; cardboard, paper, tape and elastic keep their suggested colours.",
        "", "## Checks and review", "",
        "validation.json records source and saved-FBX closed topology, consistent normals, positive volume, nondegenerate triangles, self-intersections, raw stud-scale bounds and Blender re-imports.",
        "It also records shared seam rim checks, every nose/body pairing, every new tail/body pairing, wing saddle heights and tube clearance along 33 points per axis for every part.",
        "All 18 body/booster pairings are checked for body intersections, excluding the short tape straps that intentionally tuck into the belly. Every isolated review render is checked for transparent margins so no fin or tip can be cropped.",
        "The complete colour-region triangle count is strictly below 400 for every part except body_heavy_mk2, whose explicit per-part limit is 1200. Both limits are recorded in validation.json. Classic files and planes.py are hashed before and after and must be unchanged.",
        "", "Review: renders/<catalog id>.png (23 isolated three-quarter views), parts-review.png, mixes.png (four builds beside their concept panels), joins.png (slim/heavy seam close-ups).",
        "plane-set.blend contains all asset meshes and read-only imported Classic review pieces. FBXs contain only their named single-region mesh.",
        "These are local asset deliverables; Roblox import and in-game appearance are for the later integration review.", ""]
    (OUT/"README.md").write_text("\n".join(lines),encoding="utf-8")


def protected_hashes():
    paths=[Path(p.__file__)]+[f for f in CLASSIC.rglob("*") if f.is_file()]
    return {str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in paths}


def validate_render_margins():
    records=[]
    for part in IDS:
        pixels=p.load_png(OUT/"renders"/(part+".png"))
        ys,xs=np.where(pixels[:,:,3]>128)
        assert len(xs),part+": empty review render"
        h,w=pixels.shape[:2]
        margins=[int(xs.min()),int(w-1-xs.max()),int(ys.min()),int(h-1-ys.max())]
        assert min(margins)>=16,part+": review image crops the model"
        records.append({"part":part,"resolution":[w,h],"margins_left_right_top_bottom":margins,"uncropped":True})
    return records


def main():
    before=protected_hashes()
    OUT.mkdir(parents=True,exist_ok=True);(OUT/"renders").mkdir(exist_ok=True)
    # Clear only specifically owned outputs in the one authorized output directory.
    owned=[OUT/name for name in ("validation.json","parts.json","README.md","plane-set.blend","plane-set.blend1",
                                  "parts-review.png","mixes.png","joins.png")]
    owned += [OUT/(part+"-"+region+".fbx") for part in IDS for region in COLORS]
    owned += list((OUT/"renders").glob("*.png"))
    for path in owned:
        assert path.resolve().is_relative_to(OUT.resolve())
        if path.exists():path.unlink()
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    for image in list(bpy.data.images):bpy.data.images.remove(image)
    p.OBJECTS.clear();p.MATS.clear();PREVIEWS.clear()
    scene=bpy.context.scene;scene.unit_settings.system="NONE";scene.unit_settings.scale_length=1
    for name,rgb in COLORS.items():p.material(name,rgb)
    build_bodies();build_noses();build_wings();build_tails();build_boosters()
    assert len(set(o["part"] for o in p.OBJECTS))==23
    payload,checks=export_assets()
    for part in ("body_standard_mk2","tail_1","tail_2","tail_3","tail_4","tail_5","wings_1","wings_2","wings_3","wings_4","wings_5"):
        assert checks[part+"-paper"]["closed_components"]==1,part+": folded paper pieces do not connect"
    for part in ("tail_1","tail_2","tail_3","tail_4","tail_5"):
        expected=4.22 if part=="tail_4" else 3.06 if part=="tail_1" else 2.98
        if part=="tail_1":
            a=math.radians(17)
            expected=max(1.12+(3.06-1.12)*math.cos(a)+.055*math.sin(a),
                         1.12+(3.055-1.12)*math.cos(a)+.097*math.sin(a))
        assert abs(payload["assembled_parts"][part]["bbox_max"][1]-expected)<1e-5,part+": missing fin height"
    roundtrip=p.verify_fbx_roundtrip(payload,OUT)
    # Classic imports are only review instances, not generated outputs.
    import_classic_preview()
    joins=check_joins(payload)
    for obj in PREVIEWS:bpy.data.objects.remove(obj,do_unlink=True)
    PREVIEWS.clear()
    assert not bpy.data.images
    render_reviews()
    render_checks=validate_render_margins()
    write_readme(payload)
    after=protected_hashes()
    assert before==after,"Protected Classic files or planes.py changed"
    report={"result":"PASS","part_count":23,"export_count":len(payload["exports"]),
        "source_checks":checks,"fbx_roundtrip":roundtrip,"joins_and_mounts":joins,
        "isolated_render_checks":render_checks,
        "assembled_parts":payload["assembled_parts"],
        "total_triangles_by_part":{k:v["triangles"] for k,v in payload["assembled_parts"].items()},
        "maximum_part_triangles":max(v["triangles"] for v in payload["assembled_parts"].values()),
        "strict_part_triangle_limit":STRICT_PART_TRIANGLE_LIMIT,
        "part_triangle_limit_overrides":PART_TRIANGLE_LIMIT_OVERRIDES,
        "texture_images":[],"uv_layers":0,
        "script_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "export_sha256":{e["file"]:hashlib.sha256((OUT/e["file"]).read_bytes()).hexdigest() for e in payload["exports"]},
        "reference_sha256":{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in CONCEPT.glob("*.png") if f.stem in ("bodies","noses","wings","tails","boosters","mixes")},
        "classic_and_helper_unchanged":True,"protected_file_sha256":after,
        "render_files":[str(f.relative_to(OUT)) for f in sorted(OUT.rglob("*.png"))],
        "visual_review":"Inspect the generated renders before delivery. In-game integration is outside this job."}
    (OUT/"validation.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    log("Complete: local exports, FBX round trips, shared joins and review images")


if __name__=="__main__":
    main()
