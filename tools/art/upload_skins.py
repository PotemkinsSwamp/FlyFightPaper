"""Upload a skin's pictures (its still sheet and, for a Rare, its moving layers and glow pictures), one at a time:
    python tools/art/upload_skins.py <id> [<id> ...]    only after Alan's OK on the preview and the safety look (lessons.md)
    python tools/art/upload_skins.py check              every recorded picture's moderation result (read only)
Ids go into assets/models/planes/skins/uploads.json under the file's name ("lava", "lava-flow", "lava-glow"); a re-run
skips what is already there. Never prints credentials."""
import json, subprocess, sys, time
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]; D = ROOT / "assets/models/planes/skins"; RECORD = D / "uploads.json"
rec = json.loads(RECORD.read_text())
if sys.argv[1:] == ["check"]:
    key = next(l.partition("=")[2].strip().strip("\"'") for l in (ROOT / ".env").read_text().splitlines() if l.startswith("ROBLOX_API"))
    bad = 0
    for name, asset in rec.items():
        r = requests.get(f"https://apis.roblox.com/assets/v1/assets/{asset}", headers={"x-api-key": key}, timeout=30)
        state = r.json().get("moderationResult", {}).get("moderationState") if r.ok else f"HTTP {r.status_code}"
        if state != "Approved": bad += 1; print(name, asset, state)
        time.sleep(0.3)
    sys.exit(print(len(rec) - bad, "of", len(rec), "Approved"))
for skin in sys.argv[1:]:
    for path in [D / (skin + ".png")] + sorted(D.glob(skin + "-*.png")):
        if path.stem in rec: continue
        out = D / "upload-tmp.json"; out.unlink(missing_ok=True)
        done = subprocess.run([sys.executable, str(ROOT / "tools/upload_texture.py"), str(path), "--creator", "52064999", "--name", ("FFP skin " + path.stem)[:50], "--output", str(out)])
        if done.returncode: sys.exit(f"Stopped at {path.name}; see {out}. Re-run to continue.")
        rec[path.stem] = int(json.loads(out.read_text())["response"]["assetId"]); out.unlink()
        RECORD.write_text(json.dumps(rec, indent=1) + "\n"); time.sleep(2)
# The game finds a Rare's layer and glow pictures by file name (src/client/PlaneLooks.luau); run tools/generate_config.py after.
(ROOT / "config/skin-pictures.json").write_text(json.dumps({"_comment": "Skin pictures by file name (still sheets, a Rare's moving "
    "layers '<skin>-<layer>' and glow pictures '...-glow'), written by tools/art/upload_skins.py.", "pictures": dict(sorted(rec.items()))}, indent=1) + "\n")
print("recorded:", len(rec))
