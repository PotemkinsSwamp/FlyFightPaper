"""Copies one repo script's text into the open Studio place (Edit), byte for byte, through Studio's own MCP
(docs/workshop/tools.md; for when Rojo's Studio plugin is disconnected):
  python tools/studio_push.py STUDIO_ID FILE "Luau path of the script"
Compile-checked (loadstring) before it is set."""
import base64, json, os, subprocess, sys, threading, time

studio, path, target = sys.argv[1], sys.argv[2], sys.argv[3]
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


def luau(code):
    content = call("tools/call", {"name": "execute_luau", "arguments": {"studio_id": studio, "code": code, "datamodel_type": "Edit"}}).get("content", [])
    return "".join(c.get("text", "") for c in content).strip()


call("initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "c", "version": "1"}}, 20)
send({"jsonrpc": "2.0", "method": "notifications/initialized"})
data = open(path, "rb").read()
encoded = base64.b64encode(data).decode()
print(luau("_G.PUSH = {} return 'ok'"))
for i in range(0, len(encoded), 48000):
    luau(f'table.insert(_G.PUSH, "{encoded[i:i + 48000]}") return "ok"')
print(luau(f'''
local text = buffer.tostring(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(table.concat(_G.PUSH))))
_G.PUSH = nil
local f, err = loadstring(text)
if not f then return "NOT COPIED, does not compile: " .. tostring(err) end
local target = {target}
target.Source = text
return string.format("copied %d bytes (file %d), same %s", #target.Source, {len(data)}, tostring(target.Source == text))
'''))
proxy.kill()
