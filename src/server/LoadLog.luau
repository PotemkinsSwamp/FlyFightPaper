-- Load recorder (docs/plan/LOAD-PLAN.md step 2): each join's loading times, saved so slow phone joins can be read in
-- Studio later: require(game.ServerScriptService.FlyFightPaper.LoadLog).recent() in the Server VM.
-- ponytail: one key holding the newest 50 joins; a store per day if we ever need more history.
local Store=game:GetService("DataStoreService"):GetDataStore("LoadTimes")
local KEEP=50
local LoadLog={}
local function add(entry)
 task.spawn(pcall,Store.UpdateAsync,Store,"recent",function(list)
  list=type(list)=="table" and list or {}
  table.insert(list,1,entry)
  while #list>KEEP do table.remove(list) end
  return list
 end)
end

-- From the client, once per player: {times=string, device=string, skipped=number?, failures=number?, health=string?}.
function LoadLog.save(player,report)
 if type(report)~="table" or player:GetAttribute("LoadLogged") then return end
 player:SetAttribute("LoadLogged",true)
 local entry={at=os.time(),user=player.UserId,place=game.PlaceVersion,
  room=game.ReplicatedStorage.FlyFightPaper:GetAttribute("RoomClass"), -- public / tutorial / rookie / regular (Matchmaking)
  noStreaming=not workspace.StreamingEnabled or nil, -- (v367: off by mistake, so phones got the whole town at once)
  times=type(report.times)=="string" and report.times:sub(1,300) or "?",
  device=type(report.device)=="string" and report.device:sub(1,40) or "?",
  health=type(report.health)=="string" and report.health:sub(1,500) or nil, -- "fps/texture MB/files waiting" every 2.5 s
  skipped=type(report.skipped)=="number" and math.floor(report.skipped*10)/10 or nil,
  failures=type(report.failures)=="number" and math.floor(report.failures) or nil}
 add(entry)
end

-- A room move (Matchmaking): where the player was sent, or why it failed. Not from Studio (its tests route fakes).
function LoadLog.note(player,text)
 if game:GetService("RunService"):IsStudio() then return end
 add({at=os.time(),user=player.UserId,place=game.PlaceVersion,room=game.ReplicatedStorage.FlyFightPaper:GetAttribute("RoomClass"),note=tostring(text):sub(1,300)})
end

-- Newest first, one line per join.
function LoadLog.recent()
 local list=Store:GetAsync("recent") or {}
 local lines={}
 for _,e in list do
  if e.note then table.insert(lines,string.format("%s v%s %s room user %d: %s",os.date("!%m-%d %H:%M",e.at),tostring(e.place),tostring(e.room),e.user,e.note));continue end
  table.insert(lines,string.format("%s v%s%s %s%s user %d%s: %s%s%s",os.date("!%m-%d %H:%M",e.at),tostring(e.place),e.noStreaming and " STREAMING OFF" or "",e.device,e.room and " ("..e.room.." room)" or "",e.user,
   e.skipped and string.format(" (skip %.1f)",e.skipped) or "",e.times,e.failures and e.failures>0 and string.format(" [%d failed]",e.failures) or "",
   e.health and "\n   fps/texture MB/waiting every 2.5 s: "..e.health or ""))
 end
 return table.concat(lines,"\n")
end

return LoadLog
