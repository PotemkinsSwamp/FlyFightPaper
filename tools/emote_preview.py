"""Renders a winner emote's preview video from Studio's Edit, no Play and no upload (docs/workshop/emote-making.md):

  python tools/emote_preview.py STUDIO_ID OUT.mp4 [SECONDS=2.7] [FPS=24] [--keep] [--lua=emote_clips.lua] [--bake=CUT:ClipName:FILE]

Runs tools/emote_preview.lua in Studio (it stands a test kid on 1st's desk and holds the emote's recipe), then for
every frame poses the scene (_G.EMOTE.frame(t)) and saves Studio's own viewport capture, joins the frames with
ffmpeg and removes the kid and plane again (--keep leaves them and the frames for another look).
"""
import base64, json, os, subprocess, sys, tempfile, threading, time

studio, out = sys.argv[1], sys.argv[2]
rest = [a for a in sys.argv[3:] if not a.startswith("--")]
seconds = float(rest[0]) if rest else 2.7
fps = int(rest[1]) if len(rest) > 1 else 24
proxy = subprocess.Popen(["python", "studio_mcp_proxy.py", "cmd", "/c", r".\mcp.bat"],
                         cwd=os.path.expandvars(r"%LOCALAPPDATA%\Roblox"),
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
replies, count = {}, [0]


def reader():
    for line in proxy.stdout:
        try:
            message = json.loads(line)
            if "id" in message: replies[message["id"]] = message
        except Exception: pass


threading.Thread(target=reader, daemon=True).start()


def send(message): proxy.stdin.write((json.dumps(message) + "\n").encode()); proxy.stdin.flush()


def call(method, params, timeout=120):
    count[0] += 1
    i = count[0]
    send({"jsonrpc": "2.0", "id": i, "method": method, "params": params})
    start = time.time()
    while i not in replies:
        if time.time() - start > timeout: raise SystemExit(f"timeout on {method}")
        time.sleep(0.02)
    reply = replies.pop(i)
    if "error" in reply: raise SystemExit(json.dumps(reply["error"])[:600])
    return reply["result"]


def tool(name, **args):
    return call("tools/call", {"name": name, "arguments": {"studio_id": studio, **args}}).get("content", [])


def text(code): return "".join(c.get("text", "") for c in tool("execute_luau", code=code, datamodel_type="Edit")).strip()


def luau(code):
    reply = text(code)
    if "ok" not in reply and "ready" not in reply: raise SystemExit(reply[:600])
    return reply


call("initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "c", "version": "1"}}, 20)
send({"jsonrpc": "2.0", "method": "notifications/initialized"})
here = os.path.dirname(os.path.abspath(__file__))
script = next((a[6:] for a in sys.argv if a.startswith("--lua=")), "emote_preview.lua")  # another scene with the same _G.EMOTE.frame / clean
print(luau(open(os.path.join(here, script), encoding="utf-8").read()))
bake = next((a[7:] for a in sys.argv if a.startswith("--bake=")), None)  # CUT:ClipName:FILE (emote_clips.lua): no video
if bake:  # the cut goes into the place's Assets as ClipName and from there into FILE (.rbxm), fetched in slices
    cut, name, path = bake.split(":", 2)
    clip = f'game.ReplicatedStorage.FlyFightPaper.Assets["{name}"]'
    print(luau(f'return _G.EMOTE.bake("{cut}", game.ReplicatedStorage.FlyFightPaper.Assets, "{name}")'))
    size = int(text(f'_G.EMOTE_B64 = buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({{ {clip} }}))) return #_G.EMOTE_B64'))
    data = "".join(text(f"return _G.EMOTE_B64:sub({i + 1}, {i + 60000})") for i in range(0, size, 60000))
    open(path, "wb").write(base64.b64decode(data))
    luau("_G.EMOTE_B64 = nil _G.EMOTE.clean() return 'ok'")
    proxy.kill()
    raise SystemExit(f"{name} -> {path}, {len(data) * 3 // 4} bytes")
frames = tempfile.mkdtemp(prefix="emote_frames_")
total = int(seconds * fps) + 1
for _ in range(4):  # let the room's pictures load and the first pose draw before frame 0 is taken
    luau("return _G.EMOTE.frame(0)"); tool("screen_capture", capture_id="ScreenCapture_50"); time.sleep(0.5)
for n in range(total):
    luau(f"return _G.EMOTE.frame({n / fps:.4f})")
    for c in tool("screen_capture", capture_id=f"ScreenCapture_{n % 50 + 1}"):
        if c.get("type") == "image":
            open(os.path.join(frames, f"f{n:04d}.jpg"), "wb").write(base64.b64decode(c["data"]))
if "--keep" not in sys.argv: luau("_G.EMOTE.clean() return 'ok'")
proxy.kill()
subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps), "-i", os.path.join(frames, "f%04d.jpg"),
                "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", out], check=True)
print("frames in", frames, "->", out, total, "frames")
