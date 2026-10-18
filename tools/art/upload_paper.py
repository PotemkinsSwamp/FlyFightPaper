"""Upload paper plane pieces (meshes + their colour/normal/roughness maps) through Roblox Open Cloud.

Run from D:/FlyFightPaper:  python tools/art/upload_paper.py         (Classic, paper-sample/: 12 pieces)
                            python tools/art/upload_paper.py set     (the other parts, paper-set/: every manifest entry)
Then read each uploaded Model's inner MeshId in Studio (the FBX uploads as a Model wrapping a MeshPart; the game
needs the mesh id): `python tools/art/upload_paper.py [set] lua` prints Luau for Studio's execute_luau (Server);
save its JSON output to a file and run `python tools/art/upload_paper.py [set] meshes <file>` to add "mesh" ids.
Resumable: asset ids go into assets/models/planes/<folder>/uploads.json as each one finishes; re-running skips
what is already there. One file at a time (Roblox moderation: upload slowly). Never prints credentials.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
args = sys.argv[1:]
SET = args[:1] == ["set"]
args = args[1:] if SET else args
D = ROOT / "assets/models/planes" / ("paper-set" if SET else "paper-sample")
RECORD = D / "uploads.json"
# The Classic pieces the game shows (AircraftPieces body_standard, nose_0, wings_0, tail_0); stickers are swapped for
# team stickers in game, so they are not needed.
NAMES = ["body-paper-L", "body-paper-R", "nose-paper-L", "nose-paper-R", "nose-accent", "wings-paper-L",
         "wings-paper-R", "wings-accent-L", "wings-accent-R", "tail-paper-L", "tail-paper-R", "tail-accent"]
if SET:
    NAMES = [e["object"] for e in json.loads((D / "manifest.json").read_text())["exports"]]

rec = json.loads(RECORD.read_text()) if RECORD.exists() else {}
if args[:1] == ["lua"]:
    ids = json.dumps({k: v["model"] for k, v in rec.items() if "mesh" not in v})
    sys.exit(print("local H,I,o=game:GetService('HttpService'),game:GetService('InsertService'),{} for k,id in pairs(H:JSONDecode('"
                   + ids + "')) do local m=I:LoadAsset(tonumber(id)) o[k]={mesh=m:FindFirstChildWhichIsA('MeshPart',true)"
                   ".MeshId:match('%d+')} m:Destroy() task.wait() end return H:JSONEncode(o)"))
if args[:1] == ["meshes"]:
    for k, v in json.loads(Path(args[1]).read_text()).items():
        rec[k]["mesh"] = v["mesh"]
    RECORD.write_text(json.dumps(rec, indent=2) + "\n")
    sys.exit(print("Mesh ids added:", sum("mesh" in v for v in rec.values()), "of", len(rec)))
for name in NAMES:
    files = [(D / f"{name}.fbx", "model")] + [(D / f"{name}-{k}.png", k) for k in ("color", "normal", "roughness")]
    for path, key in files:
        rec.setdefault(name, {})
        if key in rec[name]:
            continue
        out = D / "upload-tmp.json"
        out.unlink(missing_ok=True)
        done = subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(path), "--creator", "52064999",
                               "--name", f"FFP plane {name} {key}"[:50], "--output", str(out)]
                              + (["--model"] if key == "model" else []))
        if done.returncode:
            sys.exit(f"Stopped at {name} {key}; see {out}. Re-run to continue.")
        rec[name][key] = json.loads(out.read_text())["response"]["assetId"]
        out.unlink()
        RECORD.write_text(json.dumps(rec, indent=2) + "\n")
        time.sleep(1)
print("All done:", sum(len(v) for v in rec.values()), "uploads")
