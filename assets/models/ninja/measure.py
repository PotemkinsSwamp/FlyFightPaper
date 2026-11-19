"""Measure the Ninja's rigid target and equipment support surfaces after export.py (ordinary Python)."""
import json
from pathlib import Path

import numpy as np
from shapely import LineString, MultiPoint, union_all

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / ".planning/skins/ninja/build/tail-10"
OUT = ROOT / ".planning/skins/ninja/roblox"
geometry = json.loads((OUT/"geometry.json").read_text())
mesh = np.load(BUILD / "mesh.npz")
length = 8.4
v = mesh["V"][:,[1,2,0]] * length
v[:,2] -= length/2
t = mesh["T"]
label = mesh["names"][mesh["part"]]
solid = v[t[~np.isin(label,["ribbon_lower","ribbon_upper"])]]
lo,hi = solid.min(axis=(0,1)), solid.max(axis=(0,1))

wing = v[np.unique(t[label=="wing"])]
right = wing[wing[:,0]>0]
root = right[np.isclose(right[:,0],right[:,0].min())]
tip = right[np.isclose(right[:,0],right[:,0].max())]
# Intersect each rigid triangle with the center plane; trace the underside down this section.
section = []
for tri in solid:
    points=[]
    for p,q in zip(tri,np.roll(tri,-1,axis=0)):
        if abs(p[0])<1e-8:
            points.append(p[[2,1]])
        if p[0]*q[0] < 0:
            points.append((p-p[0]/(q[0]-p[0])*(q-p))[[2,1]])
    if len(points)>=2:
        line=MultiPoint(points).convex_hull
        if line.geom_type!='Point':
            section.append(line)
cross = union_all(section)
# Include both sides of each abrupt step in the center section.
nodes = sorted({float(z) for shape in section for z,_ in
                (shape.exterior.coords if shape.geom_type=="Polygon" else shape.coords)})
sample_z = sorted({max(lo[2], min(hi[2], z+e)) for z in nodes for e in (-1e-5,0,1e-5)})
underside=[]
for z in sample_z:
    hits=cross.intersection(LineString([(z,lo[1]-.1),(z,hi[1]+.1)]))
    if not hits.is_empty:
        underside.append((z,hits.bounds[1]))
keel = [[round(y,6),round(z,6)] for z,y in LineString(underside).simplify(.0001).coords]
assert all(q[1]>p[1] for p,q in zip(keel,keel[1:]))
hull = v[np.unique(t[label=="body"])]
even = {
    "wing_y":right[:,1].mean(), "half_span":float(hi[0]),
    "body_x":float(hull[:,0].max()),
    "wing":{"root_x":root[0,0],"front_z":root[:,2].min(),"back_z":root[:,2].max(),
            "tip_x":tip[0,0],"tip_z":tip[:,2].mean(),"under_y":right[:,1].min()},
    "keel":keel
}
payload = {"hitPiece":"hullHit","even":even,"pieces":geometry["pieces"]}
(OUT/"fit.json").write_text(json.dumps(payload,indent=2)+"\n")
print("Ninja:",len(keel),"keel corners")
