local Adapter=require(game.ServerScriptService.FlyFightPaper.MatchmakingAdapter)
local Config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Server).routing
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture(entries)
 local f={entries=entries or {},writes={},rows={index={},class={}},sent=0,reserved=0,scans=0,reads=0}
 local function map(name)
  return {GetAsync=function(_,key)f.reads+=1;return f.rows[name][key]end,
   GetRangeAsync=function()f.scans+=1;return f.entries end,SetAsync=function(_,key,row,ttl,sortKey)
   if f.fail==name then error("injected room refresh failure") end
   table.insert(f.writes,{name=name,key=key,ttl=ttl,sortKey=sortKey});f.rows[name][key]=table.clone(row)
   if f.onWrite then f.onWrite(name) end
  end}
 end
 local teleport={ReserveServerAsync=function(_,placeId)
  assert(placeId==game.PlaceId);f.reserved+=1
  local suffix=f.reserved==1 and "" or "-"..f.reserved
  return "test-code"..suffix,"test-reserved-room"..suffix
 end,TeleportAsync=function(_,_,players,options)
  f.sent+=1;f.players=players;f.options=options;table.insert(f.writes,{name="teleport"})
 end}
 f.adapter=setmetatable({index=map("index"),maps={regular=map("class"),rookie=map("class")},teleport=teleport},Adapter)
 return f
end
function Spec.run()
 local result,test=Suite.new()
 test("tutorial destinations always reserve fresh rooms and write only the index",function()
  local f=fixture({{key="existing-tutorial",value={class="tutorial",accessCode="old-code",count=0,updatedAt=os.time()}}})
  f.adapter.maps={};local before=os.time()
  local first=f.adapter:destination("tutorial");local second=f.adapter:destination("tutorial")
  assert(f.reserved==2 and f.scans==0 and #f.writes==2 and next(f.rows.class)==nil)
  assert(first.roomId~=second.roomId and first.accessCode~=second.accessCode)
  for i,row in ipairs({first,second}) do
   local write=f.writes[i];local saved=f.rows.index[row.roomId]
   assert(write.name=="index" and write.key==row.roomId and write.ttl==Config.entry_ttl_seconds and write.sortKey==0)
   assert(saved.class=="tutorial" and saved.accessCode==row.accessCode and saved.roomId==row.roomId and saved.count==0 and saved.updatedAt>=before)
  end
 end)
 test("reserved rooms read their tutorial class from the index",function()
  local f=fixture();f.adapter.privateServerId="test-reserved-room"
  local row={class="tutorial",accessCode="test-code",roomId="test-reserved-room",count=0,updatedAt=os.time()}
  f.rows.index["test-reserved-room"]=row
  assert(f.adapter:currentClass()=="tutorial" and f.adapter.row==row and f.reads==1)
 end)
 test("advertising a tutorial room does not touch its row or any map",function()
  local f=fixture();local row={class="tutorial",count=0,updatedAt=1}
  f.adapter.row=row;f.adapter.maps={}
  f.adapter:advertise("tutorial")
  assert(#f.writes==0 and f.scans==0 and f.reads==0 and row.count==0 and row.updatedAt==1)
 end)
 test("sending to a tutorial refreshes only its index before teleport",function()
  local f=fixture();f.adapter.maps={}
  local row=f.adapter:destination("tutorial");row.updatedAt=1
  f.writes={};local player={};local before=os.time();local checked=false
  f.adapter:send(player,row,function()checked=true;return true end)
  assert(f.sent==1 and checked and f.players[1]==player and f.options.ReservedServerAccessCode==row.accessCode)
  assert(#f.writes==2 and f.writes[1].name=="index" and f.writes[2].name=="teleport" and next(f.rows.class)==nil)
  local saved=f.rows.index[row.roomId]
  assert(saved.class=="tutorial" and saved.updatedAt>=before and saved.accessCode==row.accessCode and saved.count==0)
  assert(f.writes[1].ttl==Config.entry_ttl_seconds and f.writes[1].sortKey==0 and row.updatedAt==1)
 end)
 test("new and discovered reserved rooms refresh both expired class records before teleport",function()
  for _,discovered in ipairs({false,true}) do
   local f=fixture(discovered and {{key="test-reserved-room",value={class="regular",accessCode="test-code",count=2,updatedAt=os.time()}}} or nil)
   local row=f.adapter:destination("regular");row.updatedAt=1
   f.rows={index={},class={}};f.writes={};local player={};local before=os.time()
   f.adapter:send(player,row)
   assert(f.sent==1 and f.players[1]==player and f.options.ReservedServerAccessCode=="test-code")
   assert(#f.writes==3 and f.writes[1].name=="index" and f.writes[2].name=="class" and f.writes[3].name=="teleport")
   for _,name in ipairs({"index","class"}) do
    local saved=f.rows[name]["test-reserved-room"];assert(saved.class=="regular" and saved.updatedAt>=before and saved.accessCode=="test-code")
   end
   for i=1,2 do assert(f.writes[i].ttl==Config.entry_ttl_seconds and f.writes[i].sortKey==row.count) end
  end
 end)
 test("a failed class-record refresh raises to the routing pcall without teleporting",function()
  for _,name in ipairs({"index","class"}) do
   local f=fixture();local row=f.adapter:destination("regular");f.fail=name
   assert(not pcall(function()f.adapter:send({},row)end) and f.sent==0)
  end
 end)
 test("the send deadline is checked after the yielding record refreshes",function()
  for _,class in ipairs({"regular","tutorial"}) do
   local f=fixture();local row=f.adapter:destination(class);local expired=false
   f.onWrite=function(name)if name==(class=="tutorial" and "index" or "class") then expired=true end end
   assert(not pcall(function()f.adapter:send({},row,function()return not expired end)end))
   assert(expired and f.sent==0)
  end
 end)
 return result
end
return Spec
