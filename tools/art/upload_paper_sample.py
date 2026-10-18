"""Upload the paper-sample Classic plane (12 meshes + their colour/normal/roughness maps) through Roblox Open Cloud.

Run from D:/FlyFightPaper:  python tools/art/upload_paper_sample.py
Resumable: asset ids go into assets/models/planes/paper-sample/uploads.json as each one finishes; re-running skips
what is already there. One file at a time (Roblox moderation: upload slowly). Never prints credentials.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "assets/models/planes/paper-sample"
RECORD = D / "uploads.json"
# The Classic pieces the game shows (AircraftPieces body_standard, nose_0, wings_0, tail_0); stickers are swapped for
# team stickers in game, so they are not needed.
NAMES = ["body-paper-L", "body-paper-R", "nose-paper-L", "nose-paper-R", "nose-accent", "wings-paper-L",
         "wings-paper-R", "wings-accent-L", "wings-accent-R", "tail-paper-L", "tail-paper-R", "tail-accent"]

rec = json.loads(RECORD.read_text()) if RECORD.exists() else {}
for name in NAMES:
    files = [(D / f"{name}.fbx", "model")] + [(D / f"{name}-{k}.png", k) for k in ("color", "normal", "roughness")]
    for path, key in files:
        rec.setdefault(name, {})
        if key in rec[name]:
            continue
        out = D / "upload-tmp.json"
        out.unlink(missing_ok=True)
        done = subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(path), "--creator", "52064999",
                               "--name", f"FlyFightPaper plane {name} {key}", "--output", str(out)]
                              + (["--model"] if key == "model" else []))
        if done.returncode:
            sys.exit(f"Stopped at {name} {key}; see {out}. Re-run to continue.")
        rec[name][key] = json.loads(out.read_text())["response"]["assetId"]
        out.unlink()
        RECORD.write_text(json.dumps(rec, indent=2) + "\n")
        time.sleep(1)
print("All done:", sum(len(v) for v in rec.values()), "uploads")
