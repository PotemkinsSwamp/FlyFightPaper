local Adapter=require(game.ServerScriptService.FlyFightPaper.MatchmakingAdapter)
local Config=require(game.ReplicatedStorage.FlyFightPaper.Generated.Server).routing
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function fixture(entries)
 local f={entries=entries or {},writes={},rows={index={},class={}},sent=0}
 local function map(name)
  return {GetRangeAsync=function()return f.entries end,SetAsync=function(_,key,row,ttl,sortKey)
   if f.fail==name then error("injected room refresh failure") end
   table.insert(f.writes,{name=name,key=key,ttl=ttl,sortKey=sortKey});f.rows[name][key]=table.clone(row)
   if f.onWrite then f.onWrite(name) end
  end}
 end
 local teleport={ReserveServerAsync=function()return "test-code","test-reserved-room" end,TeleportAsync=function(_,_,players,options)
  f.sent+=1;f.players=players;f.options=options;table.insert(f.writes,{name="teleport"})
 end}
 f.adapter=setmetatable({index=map("index"),maps={regular=map("class"),rookie=map("class")},teleport=teleport},Adapter)
 return f
end
function Spec.run()
 local result,test=Suite.new()
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
  local f=fixture();local row=f.adapter:destination("regular");local expired=false
  f.onWrite=function(name)if name=="class" then expired=true end end
  assert(not pcall(function()f.adapter:send({},row,function()return not expired end)end))
  assert(expired and f.sent==0)
 end)
 return result
end
return Spec
