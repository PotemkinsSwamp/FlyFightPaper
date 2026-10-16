"""Tiny Studio MCP client (works even when the session has no Studio tools): python tools/studio_cli.py TOOL '{json args}' [out.png]  |  --schema [TOOL]. A code file path in "code" is read in. FULL=1 prints long results whole."""
import base64, json, os, subprocess, sys, threading, time
d = os.path.expandvars(r"%LOCALAPPDATA%\Roblox")
p = subprocess.Popen(["python", "studio_mcp_proxy.py", "cmd", "/c", r".\mcp.bat"], cwd=d,
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
replies = {}
def reader():
    for l in p.stdout:
        try:
            m = json.loads(l)
            if "id" in m: replies[m["id"]] = m
        except Exception: pass
threading.Thread(target=reader, daemon=True).start()
def send(m): p.stdin.write((json.dumps(m) + "\n").encode()); p.stdin.flush()
def call(i, method, params, timeout):
    send({"jsonrpc": "2.0", "id": i, "method": method, "params": params})
    t = time.time()
    while i not in replies:
        if time.time() - t > timeout: return None
        time.sleep(0.05)
    return replies[i]
call(1, "initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "c", "version": "1"}}, 20)
send({"jsonrpc": "2.0", "method": "notifications/initialized"})
if sys.argv[1] == "--schema":
    tools = call(2, "tools/list", {}, 20)["result"]["tools"]
    for t in tools:
        if len(sys.argv) < 3 or t["name"] == sys.argv[2]:
            print(t["name"], json.dumps(t.get("inputSchema", {}).get("properties", {}))[:800] if len(sys.argv) > 2 else "", t["description"][:300 if len(sys.argv) < 3 else 3000])
else:
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    if os.path.isfile(str(args.get("code", ""))): args["code"] = open(args["code"], encoding="utf-8").read()
    r = call(2, "tools/call", {"name": sys.argv[1], "arguments": args}, float(os.environ.get("T", 180)))
    if r is None: print("TIMEOUT")
    elif "error" in r: print("ERROR", json.dumps(r["error"])[:2000])
    else:
        n = 0
        for c in r["result"].get("content", []):
            if c.get("type") == "image":
                out = sys.argv[3] if len(sys.argv) > 3 else "shot.png"
                if n: out = out.replace(".", f"_{n}.")
                open(out, "wb").write(base64.b64decode(c["data"])); print("IMAGE ->", out); n += 1
            else: print(c.get("text", c)[:None if os.environ.get("FULL") else 20000])
p.kill()
