"""Photograph every model from 4 angles (roof + 3 around) through one Studio MCP connection; tile each into a sheet.
python tools/model_sheets.py MODELS.txt STUDIO_ID OUTDIR   (MODELS.txt lines: name kind cx cy cz sx sy sz). Studio must be the front window."""
import base64, io, json, math, os, subprocess, sys, threading, time
from PIL import Image, ImageDraw

models_file, studio, outdir = sys.argv[1:4]
os.makedirs(outdir, exist_ok=True)
d = os.path.expandvars(r"%LOCALAPPDATA%\Roblox")
p = subprocess.Popen(["python", "studio_mcp_proxy.py", "cmd", "/c", r".\mcp.bat"], cwd=d,
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
replies = {}
threading.Thread(target=lambda: [replies.__setitem__(m["id"], m) for m in (json.loads(l) for l in p.stdout) if "id" in m], daemon=True).start()
counter = [0]
def call(method, params, timeout=60):
    counter[0] += 1; i = counter[0]
    p.stdin.write((json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n").encode()); p.stdin.flush()
    t = time.time()
    while i not in replies:
        if time.time() - t > timeout: return None
        time.sleep(0.05)
    return replies.pop(i)
call("initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "inspect", "version": "1"}})
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush()

def shot(cam, look, n):
    r = call("tools/call", {"name": "screen_capture", "arguments": {"studio_id": studio, "capture_id": f"ScreenCapture_{n}",
             "camera_position": cam, "look_at_position": look}})
    for c in (r or {}).get("result", {}).get("content", []):
        if c.get("type") == "image": return Image.open(io.BytesIO(base64.b64decode(c["data"]))).convert("RGB")
    return Image.new("RGB", (1377, 775), (60, 0, 0))

n = 100
for line in open(models_file, encoding="utf-8"):
    parts = line.split()
    if len(parts) != 8: continue
    name, kind = parts[0], parts[1]
    cx, cy, cz, sx, sy, sz = map(float, parts[2:])
    E = max(sx, sz, sy)
    dist = 1.25 * E + 6
    top = cy + sy / 2
    views = []
    # 1: roof, looking down at the top from above and to the side
    views.append(([cx + 0.35 * E, top + 0.9 * E + 4, cz + 0.35 * E], [cx, top - 0.15 * sy, cz]))
    for ang, elev in ((45, 22), (225, 22), (135, 45)):
        a, e = math.radians(ang), math.radians(elev)
        cam = [cx + dist * math.cos(e) * math.cos(a), cy + dist * math.sin(e), cz + dist * math.cos(e) * math.sin(a)]
        views.append((cam, [cx, cy, cz]))
    sheet = Image.new("RGB", (1376, 774 + 30), (20, 20, 20))
    for k, (cam, look) in enumerate(views):
        n += 1
        im = shot(cam, look, n).resize((688, 387))
        sheet.paste(im, ((k % 2) * 688, 30 + (k // 2) * 387))
    ImageDraw.Draw(sheet).text((8, 8), f"{name} ({kind})  size {sx:.0f} x {sy:.0f} x {sz:.0f}  views: roof / 45 / 225 / 135 high", fill=(255, 255, 255))
    sheet.save(os.path.join(outdir, f"{name}.jpg"), quality=85)
    print("done", name, flush=True)
p.kill()
