"""Meshy jobs for the rug toys. The key stays in memory and goes only to api.meshy.ai.

  python tools/meshy.py balance
  python tools/meshy.py image NAME "prompt" [model] [aspect]   reference picture -> assets/models/toys/NAME/ref.png
  python tools/meshy.py model NAME [polycount]                  ref.png -> textured PBR model in the same folder
  python tools/meshy.py views FOLDER FRONT.png OTHER.png...      hero model from up to 4 views (front first), finest
                                                                 geometry, 4K PBR, no remesh -> FOLDER/meshy.glb
                                                                 (add --raw to stop Meshy redrawing the views first)

Every paid job is logged in assets/MESHY_LOG.md. Jobs are never retried automatically.
"""
import base64, json, sys, time, urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOYS = ROOT / "assets/models/toys"
LOG = ROOT / "assets/MESHY_LOG.md"
FLOOR = 300                                      # never spend below this (MILESTONES D5)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a):              # the key must never follow a redirect off api.meshy.ai
        return None


def key():
    for line in (ROOT / ".env").read_text(encoding="utf-8-sig").splitlines():
        k, _, v = line.partition("=")
        if k.strip() == "MESHY_API": return v.strip().strip("\"'")
    raise RuntimeError("MESHY_API missing from .env")


def api(path, payload=None):
    req = urllib.request.Request("https://api.meshy.ai/openapi/" + path,
                                 data=json.dumps(payload).encode() if payload is not None else None,
                                 headers={"Authorization": "Bearer " + key(), "Content-Type": "application/json"})
    with urllib.request.build_opener(NoRedirect()).open(req, timeout=90) as r:
        return json.load(r)


def balance(): return api("v1/balance")["balance"]


def run(kind, payload, cost, name, note):
    left = balance()
    if left - cost < FLOOR: sys.exit(f"stop: {left} credits left, job costs {cost}, floor is {FLOOR}")
    task = api(f"v1/{kind}", payload)["result"]
    while (t := api(f"v1/{kind}/{task}"))["status"] in ("PENDING", "IN_PROGRESS"): time.sleep(10)
    if not LOG.exists(): LOG.write_text("# Meshy log\n\n| Date | Item | Job | Credits | Result |\n|---|---|---|---|---|\n")
    with LOG.open("a", encoding="utf-8") as f:
        f.write(f"| {date.today()} | {name} | {note} | {t.get('consumed_credits', cost)} | {t['status'].lower()}, kept? tbd |\n")
    if t["status"] != "SUCCEEDED": sys.exit(f"{name}: {t['status']} {t.get('task_error')}")
    return t


def fetch(url, path):
    assert url.startswith("https://")
    with urllib.request.urlopen(url, timeout=120) as r: path.write_bytes(r.read())


def image(name, prompt, model="nano-banana-2", aspect="1:1"):
    out = TOYS / name; out.mkdir(parents=True, exist_ok=True)
    cost = {"nano-banana": 3, "nano-banana-2": 6}.get(model, 9)
    t = run("text-to-image", dict(ai_model=model, prompt=prompt, aspect_ratio=aspect), cost, name, f"picture ({model})")
    fetch(t["image_urls"][0], out / "ref.png")
    (out / "ref.json").write_text(json.dumps(dict(prompt=prompt, model=model, task=t["id"]), indent=2) + "\n")
    print(out / "ref.png", "credits left", balance())


def uri(path): return "data:image/png;base64," + base64.b64encode(Path(path).read_bytes()).decode()


def save_model(t, out):
    fetch(t["model_urls"]["glb"], out / "meshy.glb")
    for maps in t.get("texture_urls", [])[:1]:
        for kind, url in maps.items():
            if url: fetch(url, out / f"meshy-{kind}.png")
    (out / "meshy.json").write_text(json.dumps(dict(task=t["id"], credits=t.get("consumed_credits")), indent=2) + "\n")
    print(out, "credits left", balance())


def model(name, polycount=3000):
    t = run("image-to-3d", dict(image_url=uri(TOYS / name / "ref.png"), ai_model="meshy-7.1", should_texture=True,
                                enable_pbr=True, texture_resolution="2k", should_remesh=True, topology="triangle",
                                target_polycount=int(polycount)), 30, name, f"3D model, PBR, {polycount} tris")
    save_model(t, TOYS / name)


def views(folder, *images):
    out = ROOT / folder
    raw = "--raw" in images                      # Meshy leaves our drawings as they are (no "image enhancement")
    images = [i for i in images if i != "--raw"]
    t = run("multi-image-to-3d", dict(image_urls=[uri(out / i) for i in images], ai_model="meshy-7.1",
                                      geometry_resolution="2k", should_texture=True, enable_pbr=True,
                                      texture_resolution="4k", should_remesh=False, target_formats=["glb"],
                                      image_enhancement=not raw),
            35, out.name, f"hero model from {len(images)} views, 2k geometry, 4K PBR" + (", no image enhancement" if raw else ""))
    save_model(t, out)


def motion(name, seconds, prompt):
    out = ROOT / "assets/animations/meshy"; out.mkdir(parents=True, exist_ok=True)
    t = run("text-to-motion", dict(prompt=prompt, mode="prime", duration=float(seconds)), 10, name, f"motion {seconds} s")
    fetch(t["result"]["motion_url"], out / f"{name}.fbx")
    (out / f"{name}.json").write_text(json.dumps(dict(prompt=prompt, seconds=seconds, task=t["id"]), indent=2) + "\n")
    print(out / f"{name}.fbx", "credits left", balance())


if __name__ == "__main__":
    cmd, *args = sys.argv[1:] or ["balance"]
    print(balance()) if cmd == "balance" else {"image": image, "model": model, "views": views, "motion": motion}[cmd](*args)
