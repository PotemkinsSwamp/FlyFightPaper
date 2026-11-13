"""Films a friend's gift arriving, frame by frame, in Studio Play: python tools/film_gift.py OUT.mp4 [KEYS] [FPS=15]
KEYS: product keys with commas between (default xp_boost_60m,paper_pack_5000,paper_boost_30m: three gifts, so two Thanks
bring the next one out of the box). Studio captures only ~1 frame a second, so the moment's clock is held (workspace
DevGiftTime) at each step and the taps happen by themselves (src/client/GiftMoment.luau).
Before running: workspace DevMute set in Edit, Play started and the main menu showing. Alan's OK first if he's at the PC."""
import base64, json, os, subprocess, sys, tempfile, threading, time
out = sys.argv[1]
keys = sys.argv[2] if len(sys.argv) > 2 else "xp_boost_60m,paper_pack_5000,paper_boost_30m"
fps = int(sys.argv[3]) if len(sys.argv) > 3 else 15
d = os.path.expandvars(r"%LOCALAPPDATA%\Roblox")
p = subprocess.Popen(["python", "studio_mcp_proxy.py", "cmd", "/c", r".\mcp.bat"], cwd=d,
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
replies, n = {}, [0]
def reader():
    for l in p.stdout:
        try:
            m = json.loads(l)
            if "id" in m: replies[m["id"]] = m
        except Exception: pass
threading.Thread(target=reader, daemon=True).start()
def send(m): p.stdin.write((json.dumps(m) + "\n").encode()); p.stdin.flush()
def call(method, params, timeout=60):
    n[0] += 1; i = n[0]
    send({"jsonrpc": "2.0", "id": i, "method": method, "params": params})
    t = time.time()
    while i not in replies:
        if time.time() - t > timeout: return None
        time.sleep(0.01)
    return replies.pop(i)
call("initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "film", "version": "1"}})
send({"jsonrpc": "2.0", "method": "notifications/initialized"})
sid = json.loads(call("tools/call", {"name": "list_roblox_studios", "arguments": {}})["result"]["content"][0]["text"])["studios"][0]["id"]
def lua(code, timeout=60): # (keep each call short: long calls lose their replies)
    r = call("tools/call", {"name": "execute_luau", "arguments": {"studio_id": sid, "datamodel_type": "Client", "code": code}}, timeout)
    return " ".join(c.get("text", "") for c in (r or {}).get("result", {}).get("content", [])) or "TIMEOUT"
# Hold the clock at 0, start the pretend gifts, wait for the moment to begin (it waits for the board's plane to be pinned).
# (A filmed moment still up from an earlier shoot is run to its end first; the waits let each change be seen.)
ends = lua(r"""
workspace:SetAttribute("DevGiftTime", 999); task.wait(0.3)
workspace:SetAttribute("DevGiftEnds", nil); workspace:SetAttribute("DevGiftMoment", nil); task.wait(0.3)
workspace:SetAttribute("DevGiftTime", 0); workspace:SetAttribute("DevGiftMoment", "KEYS")
local t0 = os.clock()
while not workspace:GetAttribute("DevGiftEnds") and os.clock() - t0 < 20 do task.wait(0.2) end
return tostring(workspace:GetAttribute("DevGiftEnds"))
""".replace("KEYS", keys), 40)
print("ends at", ends)
if "nil" in ends or "TIMEOUT" in ends: p.kill(); sys.exit("the gift moment didn't start: is Play running with the main menu showing?")
total = int((float(ends.split()[-1]) + 0.5) * fps)
frames = tempfile.mkdtemp()
for k in range(total):
    lua(f'workspace:SetAttribute("DevGiftTime", {k / fps:.3f}); task.wait(0.12); return 1')
    r = call("tools/call", {"name": "screen_capture", "arguments": {"studio_id": sid, "capture_id": f"ScreenCapture_{k}"}})
    for c in (r or {}).get("result", {}).get("content", []):
        if c.get("type") == "image": open(os.path.join(frames, f"f_{k:03d}.jpg"), "wb").write(base64.b64decode(c["data"]))
lua('workspace:SetAttribute("DevGiftTime", nil); workspace:SetAttribute("DevGiftMoment", nil); workspace:SetAttribute("DevGiftEnds", nil); return 1')
p.kill()
print("frames in", frames)
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i", os.path.join(frames, "f_%03d.jpg"),
                "-vf", "crop=trunc(iw/2)*2:trunc(ih/2)*2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", out], check=True)
print("wrote", out)
