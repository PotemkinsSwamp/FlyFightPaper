"""Bots-only measuring matches in Alan's open Studio, muted: python tools/run_bot_matches.py [count=3] [report_at=462]
[tier=ace_mix]. Sets DevMute and DevBotTier, joins Alan's plane at the desk, samples each bot's state every second, and
prints per bot: skill, plane, shots, hits, folds, assists, deaths, points, seconds in each state; then script errors.
Run it in the background: it costs almost no tokens (short Studio calls through tools/studio_cli.py; long calls drop
their replies). Needs Alan's go (a bot match takes over Studio Play)."""
import json, os, subprocess, sys, time
COUNT = int(sys.argv[1]) if len(sys.argv) > 1 else 3
REPORT_AT = float(sys.argv[2]) if len(sys.argv) > 2 else 462
TIER = sys.argv[3] if len(sys.argv) > 3 else "ace_mix"
HERE = os.path.dirname(os.path.abspath(__file__))
CLI = os.path.join(HERE, "studio_cli.py")
ROOT = os.path.dirname(HERE)
SID = None

def call(tool, args, timeout=60):
    if SID: args = dict(args, studio_id=SID)
    r = subprocess.run(["python", CLI, tool, json.dumps(args)], capture_output=True, text=True,
                       env=dict(os.environ, T=str(timeout), FULL="1"), cwd=ROOT)
    return r.stdout.strip()

def lua(dm, code, timeout=60):
    return call("execute_luau", {"datamodel_type": dm, "code": code}, timeout)

SAMPLER = r"""
local H=game:GetService("HttpService")
workspace:SetAttribute("ClaudeModes","{}")
workspace:SetAttribute("ClaudeTown","{}")
task.spawn(function()
 -- modes: seconds in each intent. town: seconds flying over the town mat low (under 100 studs, among the buildings),
 -- mid (100-270, beside the towers) and high (above them), and scrapes (separate touches of a wall, 0.25 s apart).
 local modes,town,watched={},{},{}
 local ms={sum=0,n=0,peak=0}
 -- crashes: where each crashing bot was a second before (what it was doing, x,y,z).
 local last,seen,crashes={},{},{}
 while workspace:GetAttribute("ClaudeSampling") do
  local _,_,_,info=game.ServerStorage.MatchStatus:Invoke()
  for id,r in pairs(info.records) do
   local c=r.collisionDeaths or 0
   if seen[id] and c>seen[id] and last[id] then table.insert(crashes,last[id]) end
   seen[id]=c
  end
  workspace:SetAttribute("ClaudeCrashes",table.concat(crashes,"; "))
  local work=info.botMs or 0
  ms.sum+=work;ms.n+=1;ms.peak=math.max(ms.peak,work)
  workspace:SetAttribute("ClaudeBotMs",("%.2f avg, %.2f peak"):format(ms.sum/ms.n,ms.peak))
  for _,m in ipairs(workspace:GetDescendants()) do
   if m:IsA("Model") and m:GetAttribute("BotStyle") then
    local x=(m:GetAttribute("BotIntent") or "none"):match("^%a+") or "none"
    if m:GetAttribute("State")~="FLYING" then x="down" end
    modes[m.Name]=modes[m.Name] or {}
    modes[m.Name][x]=(modes[m.Name][x] or 0)+1
    local t=town[m.Name] or {low=0,mid=0,high=0,scrapes=0}
    town[m.Name]=t
    if not watched[m] then
     watched[m]=m:GetAttribute("DeflectUntil") or 0
     m:GetAttributeChangedSignal("DeflectUntil"):Connect(function()
      local v=m:GetAttribute("DeflectUntil") or 0
      if v-watched[m]>.6 then t.scrapes+=1 end
      watched[m]=v
     end)
    end
    local at=m:GetPivot().Position
    if x~="down" then last[m.Name]=("%s %s %.0f,%.0f,%.0f"):format(m.Name,x,at.X,at.Y,at.Z) end
    if x~="down" and math.abs(at.X)<1014 and math.abs(at.Z)<714 then
     local band=at.Y<100 and "low" or at.Y<270 and "mid" or "high"
     t[band]+=1
    end
   end
  end
  workspace:SetAttribute("ClaudeModes",H:JSONEncode(modes))
  workspace:SetAttribute("ClaudeTown",H:JSONEncode(town))
  task.wait(1)
 end
end)
return "sampling"
"""
REPORT = r"""
local H=game:GetService("HttpService")
local modes=H:JSONDecode(workspace:GetAttribute("ClaudeModes") or "{}")
local town=H:JSONDecode(workspace:GetAttribute("ClaudeTown") or "{}")
local s,_,_,info=game.ServerStorage.MatchStatus:Invoke()
local rows,sum={},{deaths=0,crashes=0,scrapes=0,low=0,mid=0,high=0}
for id,r in pairs(info.records) do
 local m=workspace:FindFirstChild(id,true)
 local ms={} for k,v in pairs(modes[id] or {}) do table.insert(ms,k..v) end table.sort(ms)
 local t=town[id] or {low=0,mid=0,high=0,scrapes=0}
 if r.kind=="bot" or modes[id] then
  sum.deaths+=r.deaths;sum.crashes+=r.collisionDeaths;sum.scrapes+=t.scrapes;sum.low+=t.low;sum.mid+=t.mid;sum.high+=t.high
 end
 table.insert(rows,("%s | %s | %s | shots %d hits %d (%.0f%%) kills %d assists %d deaths %d (w%d c%d) points %d | town low %d mid %d high %d scrapes %d | %s"):format(
  r.name,m and tostring(m:GetAttribute("BotStyle") or r.tier) or tostring(r.tier),m and tostring(m:GetAttribute("Loadout")) or "-",r.shots,r.hits,r.shots>0 and 100*r.hits/r.shots or 0,
  r.kills,r.assists or 0,r.deaths,r.weaponDeaths,r.collisionDeaths,r.points or 0,t.low,t.mid,t.high,t.scrapes,table.concat(ms," ")))
end
table.sort(rows)
local over=math.max(1,sum.low+sum.mid+sum.high)
return ("phase %s mode %s elapsed %d fired %d hits %d live %s peak %s refused %s botMs %.2f\n"):format(tostring(s.phase),tostring(s.mode),info.elapsed or -1,
 info.fired,info.hits,tostring(info.liveShots),tostring(info.peakShots),tostring(info.refusedShots),info.botMs or -1)
 ..("botMs each second: %s\n"):format(tostring(workspace:GetAttribute("ClaudeBotMs")))
 ..("CRASHES (a second before): %s\n"):format(tostring(workspace:GetAttribute("ClaudeCrashes")))
 ..("BOTS: deaths %d, crashes %d, scrapes %d; over the town: low %d%% mid %d%% high %d%%\n"):format(sum.deaths,sum.crashes,sum.scrapes,
 100*sum.low/over,100*sum.mid/over,100*sum.high/over)..table.concat(rows,"\n")
"""
NOISE = ("Asset type does not match", "is not approved for the requester", "changed camera type")

def match(n):
    print(f"=== match {n} ===", flush=True)
    lua("Edit", 'workspace:SetAttribute("DevMute",true) workspace:SetAttribute("DevBotTier","' + TIER + '") return "set"')
    print(call("start_stop_play", {"is_start": True}), flush=True)
    time.sleep(6)
    print(lua("Client", 'local r=game.ReplicatedStorage.FlyFightPaper:WaitForChild("RoundAction",30) task.wait(5) '
              'r:FireServer("mapReady") task.wait(2) r:FireServer("join") task.wait(6) return "joined"', 90), flush=True)
    phase = ""
    for _ in range(6):
        phase = lua("Server", 'local s=game.ServerStorage.MatchStatus:Invoke() return tostring(s.phase)')
        if phase == "ACTIVE": break
        time.sleep(5)
    print("phase", phase, flush=True)
    if phase == "ACTIVE":
        print(lua("Server", 'workspace:SetAttribute("ClaudeSampling",true)' + SAMPLER), flush=True)
        report = ""
        for _ in range(40):  # up to ~10 min
            time.sleep(15)
            e = lua("Server", 'local _,_,_,i=game.ServerStorage.MatchStatus:Invoke() local s=game.ServerStorage.MatchStatus:Invoke() return tostring(s.phase).." "..tostring(i.elapsed)')
            parts = e.split()
            if len(parts) == 2 and parts[0] == "ACTIVE" and parts[1].replace(".", "").isdigit() and float(parts[1]) >= REPORT_AT:
                break
            if len(parts) == 2 and parts[0] != "ACTIVE":
                print("left ACTIVE early:", e, flush=True); break
        report = lua("Server", REPORT, 60)
        lua("Server", 'workspace:SetAttribute("ClaudeSampling",nil) return "ok"')
        print(report, flush=True)
    log = call("get_console_output", {}, 60)
    errs = [l for l in log.splitlines() if ("error" in l.lower() or "stack" in l.lower() or "Script '" in l) and not any(x in l for x in NOISE)]
    print("ERRORS:" if errs else "no errors", flush=True)
    for l in errs[:30]: print("  " + l, flush=True)
    print(call("start_stop_play", {"is_start": False}), flush=True)
    time.sleep(4)

SID = next(x["id"] for x in json.loads(call("list_roblox_studios", {}).splitlines()[-1])["studios"] if "FlyFightPaper" in x["name"])
try:
    for n in range(1, COUNT + 1): match(n)
finally:
    print(lua("Edit", 'workspace:SetAttribute("DevMute",nil) workspace:SetAttribute("DevBotTier",nil) return "cleared"'), flush=True)
