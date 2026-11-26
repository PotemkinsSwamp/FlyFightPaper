local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Profile=require(Server.ProfileService)
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Playtime=require(Root.Shared.PlaytimeRules)
local Catalog=require(Root.Shared.Catalog)
local Fake=require(script.Parent.Parent.fixtures.FakeProfiles)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local DAY=86400
local START_DAY=20000
local B=require(Root.Generated.Economy).playtime.box_seconds

local function fixture(options)
 options=options or {}
 local f={now=START_DAY*DAY+100,mono=100,rolls=0}
 f.catalog=Catalog.new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
 local data=Schema.defaults(f.catalog)
 if options.seconds then data.playtime={day=START_DAY,seconds=options.seconds,taken=0} end
 if options.setup then options.setup(data) end
 f.profile=Fake.new(data)
 f.service=Profile.new({catalog=f.catalog,unix=function()return f.now end,monotonic=function()return f.mono end,
  random=function(...)
   assert(select("#",...)==0 and options.roll~=nil,"expected a wheel roll")
   f.rolls+=1
   return options.roll
  end})
 local attached=f.service:attach("user",f.profile,{connected=true,mapLoaded=true})
 assert(attached.status=="ok",attached.code)
 function f:apply(input)
  local op=assert(self.service:prepare("user",input))
  return self.service:apply("user",op),op
 end
 function f:add(seconds,day)
  return self:apply({kind="playtimeAdd",day=day or START_DAY,seconds=seconds})
 end
 function f:claim(box,choice,day)
  return self:apply({kind="playtimeBox",day=day or START_DAY,box=box,choice=choice})
 end
 function f:rejoin()
  assert(self.profile:EndSession());self.service:detach("user")
  self.profile=Fake.new(self.profile.LastSavedData)
  local attached=self.service:attach("user",self.profile,{connected=true,mapLoaded=true})
  assert(attached.status=="ok",attached.code)
 end
 return f
end

function Spec.run()
 local result,test=Suite.new()
 test("counted seconds and earned boxes save without repeating time on replay",function()
  local f=fixture()
  local first=f:add(B-1)
  assert(first.status=="ok" and first.value.type=="PlaytimeAdded",first.code)
  assert(first.value.seconds==B-1 and #first.value.earned==0)
  local second,op=f:add(1)
  assert(second.status=="ok" and second.value.seconds==B and #second.value.earned==1 and second.value.earned[1]==1)
  local replay=f.service:apply("user",op)
  assert(replay.replayed and replay.value.seconds==B and replay.value.earned[1]==1)
  f:rejoin()
  local state=f.profile.Data.playtime
  assert(state.day==START_DAY and state.seconds==B and state.taken==0)
 end)
 test("stale days refuse both kinds of operation without changing the save",function()
  local f=fixture({seconds=Playtime.CAP})
  local before=Schema.canonical(f.profile.Data)
  local add=f:add(1,START_DAY-1)
  local claim=f:claim(16,"spin",START_DAY-1)
  assert(add.status=="error" and add.code=="stale_day")
  assert(claim.status=="error" and claim.code=="stale_day")
  assert(f.rolls==0 and Schema.canonical(f.profile.Data)==before)
 end)
 test("the supplied session day keeps its chart past midnight and a newer day starts fresh",function()
  local f=fixture({seconds=B})
  f.now=(START_DAY+1)*DAY
  assert(f:claim(1).status=="ok" and f.profile.Data.playtime.taken==1)
  assert(f:add(100).value.seconds==B+100 and f.profile.Data.playtime.day==START_DAY)
  assert(f:claim(1,nil,START_DAY+1).code=="not_earned")
  local nextDay=f:add(100,START_DAY+1)
  assert(nextDay.status=="ok" and nextDay.value.seconds==100 and #nextDay.value.earned==0)
  f:rejoin()
  local state=f.profile.Data.playtime
  assert(state.day==START_DAY+1 and state.seconds==100 and state.taken==0)
 end)
 test("a Paper box pays the fixed earned amount even with 2x Paper",function()
  local f=fixture({seconds=B,setup=function(p)p.boosts.permanentPaper=true end})
  local claimed=f:claim(1)
  assert(claimed.status=="ok" and claimed.value.type=="PlaytimeBoxTaken" and claimed.value.box==1,claimed.code)
  assert(claimed.value.paper==100 and claimed.value.choice==nil and claimed.value.wheelIndex==nil)
  local data=f.profile.Data
  assert(data.paperMilli==100000 and data.earnedPaperMilli==100000 and data.purchasedPaperMilli==0)
  assert(data.buysToday.count==0 and next(data.receiptIds)==nil)
  f:rejoin()
  assert(f.profile.Data.earnedPaperMilli==100000 and f.profile.Data.playtime.taken==1)
 end)
 test("a boost box extends the live balance and saves the remaining time",function()
  local f=fixture({seconds=2*B,setup=function(p)p.boosts.xpSeconds=25 end})
  local claimed=f:claim(2)
  assert(claimed.status=="ok" and claimed.value.xpSeconds==300 and claimed.value.paperSeconds==nil,claimed.code)
  assert(f.profile.Data.boosts.xpSeconds==325 and f.profile.Data.playtime.taken==2)
  f.mono+=10
  assert(f.service:liveBoostView("user").value.boosts.xpSeconds==315)
  f:rejoin()
  assert(f.profile.Data.boosts.xpSeconds==315)
 end)
 test("the chest's sure Paper choice pays 3000 earned Paper",function()
  local f=fixture({seconds=Playtime.CAP})
  local claimed=f:claim(16,"paper")
  assert(claimed.status=="ok" and claimed.value.choice=="paper" and claimed.value.paper==3000,claimed.code)
  assert(claimed.value.wheelIndex==nil and claimed.value.chest==nil and f.rolls==0)
  local data=f.profile.Data
  assert(data.paperMilli==3000000 and data.earnedPaperMilli==3000000 and data.purchasedPaperMilli==0)
  assert(data.playtime.taken==32768 and data.buysToday.count==0)
 end)
 test("the chest's boost pair extends both resources on the live and saved clock",function()
  local f=fixture({seconds=Playtime.CAP,setup=function(p)p.boosts.paperSeconds=10;p.boosts.xpSeconds=25 end})
  local claimed=f:claim(16,"boosts")
  assert(claimed.status=="ok" and claimed.value.choice=="boosts",claimed.code)
  assert(claimed.value.paperSeconds==3600 and claimed.value.xpSeconds==3600 and claimed.value.paper==nil)
  local live=f.service:liveBoostView("user").value.boosts
  assert(live.paperSeconds==3610 and live.xpSeconds==3625 and f.rolls==0)
  f:rejoin()
  local data=f.profile.Data
  assert(data.boosts.paperSeconds==3610 and data.boosts.xpSeconds==3625 and data.playtime.taken==32768)
 end)
 test("a spin into a chest adds earned stock and replays the same prize without rolling",function()
  local f=fixture({seconds=Playtime.CAP,roll=0.7})
  local claimed,op=f:claim(16,"spin")
  assert(claimed.status=="ok" and claimed.value.choice=="spin" and claimed.value.wheelIndex==3,claimed.code)
  assert(claimed.value.chest=="sticker" and claimed.value.paper==nil and f.rolls==1)
  local before=Schema.canonical(f.profile.Data)
  local replay=f.service:apply("user",op)
  assert(replay.replayed and replay.value.wheelIndex==3 and replay.value.chest=="sticker" and f.rolls==1)
  assert(Schema.canonical(f.profile.Data)==before)
  f:rejoin()
  local data=f.profile.Data
  assert(data.chests.stock.sticker==1 and data.chests.paidStock.trail_sticker==0)
  assert(data.playtime.taken==32768 and data.buysToday.count==0)
 end)
 test("a spin into 5000 Paper saves the amount earned",function()
  local f=fixture({seconds=Playtime.CAP,roll=0.85})
  local claimed=f:claim(16,"spin")
  assert(claimed.status=="ok" and claimed.value.wheelIndex==4 and claimed.value.paper==5000,claimed.code)
  assert(claimed.value.chest==nil and f.rolls==1)
  assert(f.profile.Data.earnedPaperMilli==5000000 and f.profile.Data.purchasedPaperMilli==0)
 end)
 test("a spin into boosts previews and saves both grants from a single roll",function()
  local f=fixture({seconds=Playtime.CAP,roll=0.4})
  local claimed=f:claim(16,"spin")
  assert(claimed.status=="ok" and claimed.value.wheelIndex==2 and f.rolls==1,claimed.code)
  assert(claimed.value.paperSeconds==3600 and claimed.value.xpSeconds==3600)
  assert(f.profile.Data.boosts.paperSeconds==3600 and f.profile.Data.boosts.xpSeconds==3600)
 end)
 test("an overflow on the second boost leaves the first boost and the claim untouched",function()
  local f=fixture({seconds=Playtime.CAP,roll=0.4,setup=function(p)p.boosts.xpSeconds=Economy.MAX_SAFE_INTEGER end})
  local before=Schema.canonical(f.profile.Data)
  local clock=f.service.sessions.user.clock
  local claimed=f:claim(16,"spin")
  assert(claimed.status=="error" and claimed.code=="overflow" and f.rolls==1)
  assert(f.service.sessions.user.clock==clock and clock.state.paperSeconds==0 and clock.revision==0)
  assert(Schema.canonical(f.profile.Data)==before)
 end)
 test("only box 16 can carry a choice and a client-supplied roll is refused",function()
  local f=fixture({seconds=Playtime.CAP})
  local before=Schema.canonical(f.profile.Data)
  for _,input in ipairs({{box=16},{box=16,choice="other"},{box=3,choice="paper"},{box=3,choice=false}}) do
   local claim=f:claim(input.box,input.choice)
   assert(claim.status=="error" and claim.code=="invalid_choice")
  end
  assert(f:apply({kind="playtimeBox",day=START_DAY,box=16,choice="spin",roll=0.85}).code=="invalid_operation")
  assert(f:apply({kind="playtimeAdd",day=START_DAY,seconds=1,box=1}).code=="invalid_operation")
  assert(f:add(-1).code=="invalid_seconds" and f:add(1,-1).code=="invalid_playtime_day")
  assert(f.rolls==0 and Schema.canonical(f.profile.Data)==before)
 end)
 test("a covered boost pays earned Paper and preserves dormant boost time",function()
  local f=fixture({seconds=3600,setup=function(p)p.boosts.permanentPaper=true;p.boosts.paperSeconds=25 end})
  local claimed=f:claim(4)
  assert(claimed.status=="ok" and claimed.value.paper==250 and claimed.value.paperSeconds==nil,claimed.code)
  local data=f.profile.Data
  assert(data.paperMilli==250000 and data.earnedPaperMilli==250000 and data.purchasedPaperMilli==0)
  assert(data.boosts.paperSeconds==25 and data.buysToday.count==0)
 end)
 test("a new attempt to take a claimed box is refused without changing the save",function()
  local f=fixture({seconds=B})
  assert(f:claim(1).status=="ok")
  local before=Schema.canonical(f.profile.Data)
  local claimed=f:claim(1)
  assert(claimed.status=="error" and claimed.code=="taken" and Schema.canonical(f.profile.Data)==before)
 end)
 test("schema 17 gains an empty chart and keeps the rest of the save",function()
  local f=fixture()
  local old=assert(Schema.copy(f.profile.Data))
  old.schemaVersion=17;old.playtime=nil;old.paperMilli=123456;old.dailyGift={next=7,lastDay=START_DAY}
  local before=Schema.canonical(old)
  local expected=assert(Schema.copy(old));expected.schemaVersion=18;expected.playtime={day=-1,seconds=0,taken=0}
  local migrated=assert(Schema.migrate(Schema.freeze(old),f.catalog))
  assert(Schema.canonical(migrated)==Schema.canonical(expected) and Schema.canonical(old)==before)
  assert(Schema.canonical(assert(Schema.migrate(migrated,f.catalog)))==Schema.canonical(migrated))
 end)
 return result
end

return Spec
