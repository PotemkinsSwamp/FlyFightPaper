"""Films the report card frame by frame in Studio Play: python tools/film_report_card.py OUT.mp4 [JAR_BEFORE=2400] [ADDED=165]
Studio captures only ~1 frame a second, so the card's clock is held (workspace DevCardTime) at each 0.1 s step.
Before running, in Edit: workspace DevMute and DevMatchPaper (e.g. 660) set, results_seconds raised to 120 in
src/generated/Gameplay.luau (put it back after), then start Play. The script joins, hides one winners' desk on this
screen only (the winners' scene then skips and the card stays up the whole results time), launches, fakes the jar,
ends the match, films 4.5 s and joins the frames (crop of the card's side) with ffmpeg. Needs Alan's OK to run Play."""
import base64, json, os, subprocess, sys, tempfile, threading, time
out = sys.argv[1]
before = int(sys.argv[2]) if len(sys.argv) > 2 else 2400
added = int(sys.argv[3]) if len(sys.argv) > 3 else 165
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
print("setup:", lua(r"""
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local p = game.Players.LocalPlayer
local t0 = os.clock()
while not p.PlayerGui:FindFirstChild("RoundEnd") and os.clock() - t0 < 30 do task.wait(0.5) end
task.wait(4)
local desk = workspace.Arena:FindFirstChild(require(Root.Generated.Gameplay).rounds.winner_desks[3])
if desk then desk.Name = "FilmHidden_" .. desk.Name end
p:SetAttribute("PaperJar", BEFORE) -- (before joining: the first round starts on join and remembers it)
local phase
local c = Root.RoundView.OnClientEvent:Connect(function(s) phase = s.phase end)
Root.RoundAction:FireServer("join")
t0 = os.clock()
repeat task.wait(0.3) until phase == "ACTIVE" or os.clock() - t0 > 20
c:Disconnect()
task.wait(1)
Root.FlightAction:FireServer("launch")
task.wait(5)
p:SetAttribute("PaperJar", BEFORE + ADDED)
Root.RoundAction:FireServer("endMatch")
return tostring(phase)
""".replace("BEFORE", str(before)).replace("ADDED", str(added)), 90))
CHECK = 'local r = game.Players.LocalPlayer.PlayerGui.RoundEnd:FindFirstChild("Results", true); workspace:SetAttribute("DevCardTime", 0); return (r.Visible and r.JarRow.Visible) and "UP" or "no"'
t0 = time.time()
while "UP" not in lua(CHECK, 20) and time.time() - t0 < 200: time.sleep(1)
frames = tempfile.mkdtemp()
for k in range(46):
    lua(f'workspace:SetAttribute("DevCardTime", {k * 0.1:.2f}); task.wait(0.12); return 1')
    r = call("tools/call", {"name": "screen_capture", "arguments": {"studio_id": sid, "capture_id": f"ScreenCapture_{k}"}})
    for c in (r or {}).get("result", {}).get("content", []):
        if c.get("type") == "image": open(os.path.join(frames, f"f_{k:03d}.png"), "wb").write(base64.b64decode(c["data"]))
lua('workspace:SetAttribute("DevCardTime", nil); return 1')
p.kill()
from PIL import Image
seq = [0] * 5 + list(range(46)) + [45] * 15 # half a second still, the 4.5 s, then a hold
for k, i in enumerate(seq):
    im = Image.open(os.path.join(frames, f"f_{i:03d}.png")).convert("RGB")
    w, h = im.size
    im.crop((w - 1060, 0, w, h - h % 2)).save(os.path.join(frames, f"v_{k:03d}.png"))
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "10", "-i", os.path.join(frames, "v_%03d.png"),
                "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", out], check=True)
print("wrote", out)
