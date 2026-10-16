"""Luau that (re)places toy-placements rows matching a Python filter live in CityToys: python tools/toy_place_lua.py "r[\x27cf\x27][0] < -1500" > out.lua"""
import json, sys
f = eval("lambda r: " + sys.argv[1])
rows = [r for r in json.load(open('assets/rug/toy-placements.json')) if f(r)]
recs = {n: json.load(open(f'assets/models/toys/{n}/upload.json')) for n in {r['toy'] for r in rows}}
out = [dict(n=r['toy'], m=recs[r['toy']]['mesh'], c=[recs[r['toy']].get(k, '') for k in (r['color'], 'normal', 'roughness', 'metalness')],
            cf=r['cf'], s=r['size'], solid=r['solid']) for r in rows]
key = sorted({(round(r['cf'][0]), round(r['cf'][2])) for r in rows})
print("""local H,A=game:GetService('HttpService'),game:GetService('AssetService')
local T=workspace.Arena.CityToys
local rows=H:JSONDecode('""" + json.dumps(out) + """')
local want={} for _,r in ipairs(rows) do want[math.floor(r.cf[1]+.5)..','..math.floor(r.cf[3]+.5)]=r.n end
for _,c in ipairs(T:GetChildren()) do local k=math.floor(c.Position.X+.5)..','..math.floor(c.Position.Z+.5) if want[k]==c.Name then c:Destroy() end end
for _,r in ipairs(rows) do
 local p=A:CreateMeshPartAsync('rbxassetid://'..r.m) p.Name=r.n p.Anchored=true p.CanTouch=false
 p.CanCollide=r.solid p.CanQuery=r.solid p.Size=Vector3.new(unpack(r.s)) p.CFrame=CFrame.new(unpack(r.cf))
 local s=Instance.new('SurfaceAppearance') s.Name='Paint' s.ColorMap='rbxassetid://'..r.c[1] s.NormalMap='rbxassetid://'..r.c[2] s.RoughnessMap='rbxassetid://'..r.c[3]
 if r.c[4]~='' then s.MetalnessMap='rbxassetid://'..r.c[4] end s.Parent=p p.Parent=T end
return #rows""")
