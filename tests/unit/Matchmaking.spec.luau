local Matching=require(game.ServerScriptService.FlyFightPaper.Matchmaking)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
 local result,test=Suite.new()
 local function player(count)
  local p=Instance.new("Folder");p.Parent=game.ServerStorage
  return p,{qualification={count=count}}
 end
 test("only five qualifying matches graduate; XP and client flags do not",function()
  assert(Matching.classFor({qualification={count=4},xpMilli=999999999})=="rookie")
  assert(Matching.classFor({qualification={count=5}})=="regular")
 end)
 test("the tutorial is needed only before both the first match and first qualification",function()
  local newProfile={statistics={matches=0},qualification={count=0}}
  assert(Matching.needsTutorial(newProfile)==true and Matching.classFor(newProfile)=="rookie")
  assert(Matching.needsTutorial(nil)==false)
  for _,profile in ipairs({{},
   {statistics={matches=1},qualification={count=0}},
   {statistics={matches=0},qualification={count=1}},
   {statistics={matches=5},qualification={count=5}},
   {statistics={matches=0}},
   {qualification={count=0}},
   {statistics={},qualification={}},
  }) do assert(Matching.needsTutorial(profile)==false) end
 end)
 test("only a tutorial server identifies itself as a tutorial room",function()
  local rooms=Matching.new({},{mock=true})
  assert(not rooms:isTutorialRoom())
  for _,class in ipairs({"rookie","regular","tutorial"}) do
   rooms.class=class;assert(rooms:isTutorialRoom()==(class=="tutorial"))
  end
 end)
 test("tutorial routing refuses mock, loading, unavailable, transferring and tutorial rooms or missing profiles",function()
  local p,profile=player(0)
  local profiles={view=function()return profile end,release=function()error("refused routing released a profile")end}
  local platform={destination=function()error("refused routing requested a destination")end,send=function()error("refused routing sent a player")end}
  for _,state in ipairs({{mock=true},{loading=true},{unavailable=true},{transferring=true},{class="tutorial"},{noProfile=true}}) do
   local transfer=state.transferring and {} or nil
   local rooms=setmetatable({profiles=profiles,platform=platform,mock=state.mock or false,loading=state.loading,
    unavailable=state.unavailable,class=state.class or "rookie",transfers={[p]=transfer}},Matching)
   profiles.view=function()return not state.noProfile and profile or nil end
   assert(rooms:routeTutorial(p)==false and rooms.transfers[p]==transfer)
   assert(p:GetAttribute("Routing")==nil and p:GetAttribute("MenuMessage")==nil)
  end
  p:Destroy()
 end)
 test("Studio isolates a trusted beginner room from graduated profiles",function()
  local a,pa=player(0);local b,pb=player(5)
  b:SetAttribute("Graduated",false)
  local profiles={view=function(_,p)return p==a and pa or pb end}
  local rooms=Matching.new(profiles,{mock=true})
  assert(rooms:admit(a) and rooms.class=="rookie")
  assert(not rooms:admit(b) and rooms.class=="rookie")
  a:Destroy();b:Destroy()
 end)
 test("graduated solo players get a regular room",function()
  local p,profile=player(5)
  local rooms=Matching.new({view=function()return profile end},{mock=true})
  assert(rooms:admit(p) and rooms.class=="regular");p:Destroy()
 end)
 test("a beginner joins a friend's regular room only after one qualifying match",function()
  local a,pa=player(5);local b,pb=player(0);local c,pc=player(1);local d,pd=player(1)
  local view={[a]=pa,[b]=pb,[c]=pc,[d]=pd}
  local rooms=Matching.new({view=function(_,p)return view[p] end},{mock=true,friendHere=function(p)return p~=d end})
  assert(rooms:admit(a) and rooms.class=="regular")
  assert(not rooms:admit(b),"a brand-new friend still starts in a beginners' room")
  assert(rooms:admit(c),"one finished match lets the friend in")
  assert(not rooms:admit(d),"no friend here: beginners stay apart")
  assert(Matching.friendCanStay(pc,true) and not Matching.friendCanStay(pa,true))
  a:Destroy();b:Destroy();c:Destroy();d:Destroy()
 end)
 test("a second Play press during the friend lookup can't start a second transfer",function()
  local a,pa=player(5);local b,pb=player(0);local view={[a]=pa,[b]=pb};local release=false
  local rooms=Matching.new({view=function(_,p)return view[p] end},{mock=true,friendHere=function()while not release do task.wait() end return false end})
  assert(rooms:admit(a) and rooms.class=="regular")
  task.spawn(function()rooms:admit(b)end);task.wait()
  assert(not rooms:admit(b),"the overlapping press is refused while the first is still checking")
  release=true;task.wait();a:Destroy();b:Destroy()
 end)
 test("unloaded profiles cannot choose a room",function()
  local p=player(0);p:SetAttribute("Graduated",true)
  local rooms=Matching.new({view=function()return nil end},{mock=true})
  assert(not rooms:admit(p) and rooms.class==nil);p:Destroy()
 end)
 test("live transfer releases the profile before sending and blocks repeat joins",function()
  local p,profile=player(5);local disconnected=false;local sent=false;local order={}
  local entry={account="test"};local profiles={entries={[p]=entry},view=function()return profile end,
   release=function(_,who)assert(who==p);entry.leaving=true;entry.releaseAt=0;disconnected=true;table.insert(order,"pause")end}
  local platform={destination=function()return {class="regular"}end,send=function()
   assert(profiles.entries[p]==nil and disconnected);sent=true;table.insert(order,"send")
  end}
  local rooms=setmetatable({profiles=profiles,platform=platform,mock=false,class="rookie",transfers={}},Matching)
  assert(not rooms:admit(p));assert(not rooms:admit(p))
  task.wait(.05);assert(entry.leaving and entry.releaseAt==0 and disconnected and not sent)
  profiles.entries[p]=nil;task.wait(.15)
  assert(sent and order[1]=="pause" and order[2]=="send");p:Destroy()
 end)
 test("live tutorial routing waits for the final save and transfers only once, including replay",function()
  for _,count in ipairs({0,5}) do
   local p,profile=player(count);local entry={};local destinations=0;local released=0;local sent=0;local order={}
   local destination={class="tutorial",accessCode="private-tutorial",roomId="private-room"}
   local profiles={entries={[p]=entry},view=function()return profile end,release=function(_,who)
    assert(who==p);released+=1;entry.leaving=true;table.insert(order,"release")
   end}
   local platform={destination=function(_,class)
    assert(class=="tutorial");destinations+=1;table.insert(order,"destination");return destination
   end,send=function(_,who,row,canSend)
    assert(who==p and row==destination and profiles.entries[p]==nil and released==1 and canSend())
    sent+=1;table.insert(order,"send")
   end}
   local rooms=setmetatable({profiles=profiles,platform=platform,mock=false,class=Matching.classFor(profile),transfers={}},Matching)
   assert(rooms:routeTutorial(p)==true and rooms:routeTutorial(p)==false and not rooms:admit(p))
   assert(p:GetAttribute("Routing")==true and p:GetAttribute("MenuMessage")=="Opening your practice room. Saving first.")
   task.wait(.05);assert(destinations==1 and released==1 and entry.leaving and sent==0)
   profiles.entries[p]=nil;task.wait(.15)
   assert(sent==1 and destinations==1 and released==1 and order[1]=="destination" and order[2]=="release" and order[3]=="send")
   assert(not rooms:routeTutorial(p));p:Destroy()
  end
 end)
 test("admission leaves a tutorial room for the player's experience class without checking friends",function()
  for _,count in ipairs({0,1,5}) do
   local p,profile=player(count);local requested;local sent=0;local released=0
   local profiles={entries={[p]={}},view=function()return profile end}
   profiles.release=function()released+=1;profiles.entries[p]=nil end
   local platform={destination=function(_,class)requested=class;return {class=class}end,
    send=function(_,who,row,canSend)assert(who==p and row.class==Matching.classFor(profile) and canSend());sent+=1 end}
   local rooms=setmetatable({profiles=profiles,platform=platform,mock=false,class="tutorial",transfers={},
    friendHere=function()error("tutorial rooms cannot keep friends")end},Matching)
   assert(not rooms:admit(p));task.wait()
   assert(requested==Matching.classFor(profile) and sent==1 and released==1 and rooms:isTutorialRoom())
   p:Destroy()
  end
 end)
 test("a failed destination keeps the loaded profile and permits retry",function()
  for _,tutorial in ipairs({false,true}) do
   local p,profile=player(5);local entry={account="test"};local attempts=0
   local profiles={entries={[p]=entry},view=function()return profile end}
   local rooms=setmetatable({profiles=profiles,mock=false,class="rookie",transfers={},platform={destination=function()attempts+=1;error("unavailable")end}},Matching)
   for attempt=1,2 do
    if tutorial then assert(rooms:routeTutorial(p)) else assert(not rooms:admit(p)) end;task.wait()
    assert(attempts==attempt and not rooms.transfers[p] and not entry.leaving and profiles.entries[p]==entry and not p:GetAttribute("Routing"))
   end
   p:Destroy()
  end
 end)
 test("a failed send reloads the released profile instead of creating defaults",function()
  local p=player(5);local reloaded=false
  local profiles={entries={},load=function(_,who)assert(who==p);reloaded=true end}
  local rooms=setmetatable({profiles=profiles,transfers={[p]=true}},Matching)
  rooms:failed(p);assert(reloaded and not p:GetAttribute("Routing"));p:Destroy()
 end)
 test("a save timeout clears routing, waits to reload, and never sends a late transfer",function()
  for _,tutorial in ipairs({false,true}) do
   for _,savedAtDeadline in ipairs({false,true}) do
    local p,profile=player(5);local now=100;local sent=0;local loads=0;local entry={}
    local profiles={entries={[p]=entry},view=function()return profile end,release=function()entry.leaving=true end}
    profiles.load=function(_,who)loads+=1;profiles.entries[who]={loaded=true}end
    local rooms=setmetatable({profiles=profiles,mock=false,class="rookie",transfers={},now=function()return now end,
     platform={destination=function(_,class)return {class=class}end,send=function()sent+=1 end}},Matching)
    if tutorial then assert(rooms:routeTutorial(p)) else assert(not rooms:admit(p)) end
    task.wait(.05);now=159.9;task.wait(.15)
    assert(rooms.transfers[p] and sent==0 and loads==0)
    now=160;if savedAtDeadline then profiles.entries[p]=nil end;task.wait(.15)
    local timedOut=not rooms.transfers[p] and p:GetAttribute("Routing")==false and p:GetAttribute("MenuMessage")=="Room transfer timed out. Your progress is safe. Try Play again."
    local held=savedAtDeadline or (profiles.entries[p]==entry and loads==0)
    profiles.entries[p]=nil;task.wait(.15);p:Destroy()
    assert(timedOut and held and sent==0 and loads==1)
   end
  end
 end)
 test("a deadline crossed while refreshing the room prevents the actual send",function()
  local p,profile=player(5);local now=0;local sent=false;local loaded=false
  local profiles={entries={[p]={}},view=function()return profile end,load=function()loaded=true end}
  profiles.release=function()profiles.entries[p]=nil end
  local rooms=setmetatable({profiles=profiles,mock=false,class="rookie",transfers={},now=function()return now end,
   platform={destination=function()return {class="regular"}end,send=function(_,_,_,canSend)
    now=60;assert(canSend and canSend());sent=true
   end}},Matching)
  rooms:admit(p);task.wait()
  assert(not sent and loaded and not rooms.transfers[p] and not p:GetAttribute("Routing"))
  assert(p:GetAttribute("MenuMessage")=="Room transfer timed out. Your progress is safe. Try Play again.");p:Destroy()
 end)
 return result
end
return Spec
