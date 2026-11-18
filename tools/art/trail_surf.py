"""Breaking water, foam and a hinged shark bite for the Legendary trail review."""
import math
import bpy
from mathutils import Matrix, Quaternion, Vector


def wavelet(bm):
    """A short spill of water. The crest folds over the trough and the ends taper into adjacent spills."""
    rows = []
    foam = bm.verts.layers.float.new("foam")
    surface = [(-0.42,-0.07,0.03),(-0.54,0.01,0.15),(-0.43,0.12,0.22),(-0.27,0.09,0.25),
               (-0.08,0.025,0.20),(0.12,0.04,0.17),(0.28,0.16,0.30),(0.33,0.31,0.75),
               (0.25,0.38,1.0),(0.13,0.34,1.0),(0.10,0.27,0.73),(0.18,0.29,0.42),
               (0.22,0.22,0.24),(0.15,0.13,0.12),(-0.10,-0.07,0.03)]
    for i in range(13):
        u = i/12
        envelope = 0.06 + 0.94 * math.sin(math.pi*u)**0.54
        row = []
        for x,z,white in surface:
            sway = 0.08 * math.sin(8*u + x*2)
            ridge = 0.10 * math.sin(9*u+4*x) * (0.25 + white)
            v = bm.verts.new(((x+sway)*envelope, (u-0.5)*1.75, (z+ridge)*envelope))
            v[foam] = white
            row.append(v)
        rows.append(row)
    for a,b in zip(rows, rows[1:]):
        for j in range(len(surface)):
            k = (j+1) % len(surface)
            bm.faces.new((a[j],b[j],b[k],a[k]))
    bm.faces.new(rows[0]); bm.faces.new(rows[-1])


def tooth(bm, anchor, tangent, outward, width, height, sign):
    """A rounded raised root, curved ridged crown and fine fluting from root to tip."""
    rings = []
    enamel = bm.verts.layers.float.get("enamel_tip") or bm.verts.layers.float.new("enamel_tip")
    flute = bm.verts.layers.float.get("enamel_ridge") or bm.verts.layers.float.new("enamel_ridge")
    for k,(depth,half_width,thickness) in enumerate(((-0.08,0.72,0.23),(0.08,1,0.29),
            (0.22,0.92,0.31),(0.43,0.67,0.27),(0.66,0.45,0.19),(0.85,0.24,0.10),(1,0.025,0.018))):
        row=[]
        for j in range(12):
            a=j*math.tau/12
            ridge=1.28 if j in (3,9) else 1.0
            d = tangent*(math.cos(a)*width*half_width + depth**2*width*0.37)
            d += outward*(math.sin(a)*thickness*width*ridge - depth**2*height*0.21)
            point=anchor+d+Vector((0,0,-sign*height*depth))
            v=bm.verts.new(point)
            v[enamel]=max(0,depth)
            v[flute]=0.5+0.5*math.cos(3*a)
            row.append(v)
        rings.append(row)
    for k,(a,b) in enumerate(zip(rings,rings[1:])):
        for j in range(12):
            face=bm.faces.new((a[j],a[(j+1)%12],b[(j+1)%12],b[j]))
            face.material_index=3 if k==0 else 2
            face.smooth=True
    bm.faces.new(rings[0]).material_index=3
    bm.faces.new(rings[-1]).material_index=2


def jaw_mesh(bm, upper):
    sign=1 if upper else -1
    width=0.51 if upper else 0.46
    reach=0.91 if upper else 0.76
    def gum(a):
        return Vector((width*math.sin(a),-reach*math.cos(a),sign*(0.037+0.072*max(0,math.cos(a)))))
    rows=[]
    for i in range(31):
        a=-1.61+3.22*i/30
        mid=gum(a)
        outward=Vector((math.sin(a),-math.cos(a),0))
        row=[]
        profile=((0.09,-0.018),(0.12,0.070),(0.058,0.135),(-0.063,0.097),(-0.077,0.020),(-0.044,-0.022))
        for dx,dz in profile:
            row.append(bm.verts.new(mid+outward*dx+Vector((0,0,sign*dz))))
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for j in range(6):
            face=bm.faces.new((a[j],b[j],b[(j+1)%6],a[(j+1)%6]))
            face.material_index=0 if j in (0,1,2) else 1
            face.smooth=True
    bm.faces.new(rows[0]); bm.faces.new(rows[-1])
    # Recess the palate behind the gum so the enamel reads against a dark mouth.
    palate=bm.verts.new((0,-0.28,sign*0.15))
    for a,b in zip(rows,rows[1:]):
        bm.faces.new((a[4],palate,b[4])).material_index=4
    for j in range(13):
        a=-1.37+j*2.74/12 + (0 if upper else 0.055)
        tip_scale=0.59+0.41*math.cos(a)
        point=gum(a)
        tangent=Vector((width*math.cos(a),reach*math.sin(a),0)).normalized()
        outward=Vector((tangent.y,-tangent.x,0))
        tooth(bm,point,tangent,outward,0.069*tip_scale,(0.21+0.027*math.cos(2.5*j))*tip_scale,sign)


def smooth(x):
    x=min(1,max(0,x))
    return x*x*(3-2*x)


def pose_jaw(obj, upper, t, past, style):
    """Both halves rotate about the same hinge. The shot is held near enough for the pilot to see it close."""
    phase=(t+0.56) % 2.36
    duration=0.85
    obj.hide_render=phase>=duration
    if obj.hide_render:
        return
    delay=0.024+0.026*phase + 0.024*smooth((phase-0.68)/0.17)
    _,tail,right,up,growth=past(t-delay)
    nose=up.cross(right).normalized()
    basis=Matrix((right,nose,up)).transposed().to_quaternion()
    angle=0.12+0.65*smooth(phase/0.18)-0.59*smooth((phase-0.39)/0.13)
    angle *= -1 if upper else 0.80
    # A three-quarter turn exposes the shared hinge and the depth of the mouth.
    yaw=0.41 if style=="breakers" else -0.56
    turn=basis @ Quaternion((0,0,1),yaw) @ Quaternion((1,0,0),angle)
    size=3.0*growth*smooth(phase/0.12)*(1-smooth((phase-0.66)/0.19))
    center=tail+up*(0.22+0.88*math.sin(phase/duration*math.pi))+right*0.42
    obj.matrix_world=Matrix.Translation(center) @ turn.to_matrix().to_4x4() @ Matrix.Scale(size,4)
