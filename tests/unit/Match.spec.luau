local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Server = game:GetService("ServerScriptService"):WaitForChild("FlyFightPaper")
local Match, Rules = require(Server.MatchService), require(Root.Shared.MatchRules)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Clock = require(script.Parent.Parent.fixtures.FakeClock)
local gameplay, economy = require(Root.Generated.Gameplay), require(Root.Generated.Economy)
local Spec = {}
local zoneCenter = Vector3.new(table.unpack(gameplay.rounds.control_zones[1].center))
local outsideZone = Vector3.new(0, 0, 0)
local function near(a, b) assert(math.abs(a-b) < 1e-6, tostring(a) .. " != " .. tostring(b)) end
Spec.near = near
function Spec.fixture(mode, startedAt)
    local clock = Clock.new(startedAt or 0)
    local gate = { through = nil }
    local m = Match.new({ config = gameplay, economy = economy, clock = clock, sessionId = "unit", seed = 17029,
        combatDrainState = function() return { through = gate.through or clock:now(), blocked = gate.through ~= nil } end })
    local _, matchId = m:startRound(mode or "FFA")
    local f = { m = m, clock = clock, matchId = matchId, sequence = 0, life = 0, humans = 0, gate = gate }
    function f:identity(key)
        local p = self.m:snapshot().participants[key]
        return { actorId = p.actorId, lifeId = p.lifeId, participationId = p.participationId,
            matchId = self.matchId, teamId = p.teamId }
    end
    function f:newLife(key)
        local p = self.m:snapshot().participants[key]
        self.life += 1
        assert(self.m:lifeStarted({ actorId = p.actorId, lifeId = "life:" .. self.life,
            participationId = "participant:" .. p.actorId, matchId = self.matchId }))
        assert(self.m:observe(key, { state = "FLYING", protected = false, eligible = true, position = outsideZone }))
    end
    function f:join(key, bot, prior, actorId)
        self.humans += 1
        local ok, facts = self.m:join({ key = key, actorId = actorId or "actor:" .. key, controllerType = bot and "bot" or "human",
            userId = not bot and self.humans or nil, priorQualifyingMatches = prior or 0 })
        assert(ok, facts); self:newLife(key)
        return self:identity(key)
    end
    function f:sample(key, position, state, protected, overlay, practice)
        local zone = self.m:_zone()
        local center = zone and Vector3.new(table.unpack(zone.center)) or zoneCenter
        assert(self.m:observe(key, { position = position or center, state = state or "FLYING",
            protected = protected == true, overlay = overlay == true, practice = practice == true, eligible = true }))
    end
    function f:event(kind, owner, victim, extra)
        self.sequence += 1
        local e = { eventId = "combat:" .. self.sequence, serverSequence = self.sequence, at = self.clock:now(),
            kind = kind, victim = self:identity(victim) }
        if kind == "weaponDamage" then e.attacker, e.amount = self:identity(owner), 2
        else e.killer, e.assists, e.reason = owner and self:identity(owner), {}, "weapon" end
        for key, value in pairs(extra or {}) do e[key] = value end
        assert(self.m:consumeCombat(e))
        return e
    end
    function f:advance(seconds) self.clock:advance(seconds); self.m:tick() end
    -- Explicitly move these pilots with the zone; advance alone keeps their old samples.
    function f:captureFor(seconds, keys)
        while seconds > 0 do
            for _, key in ipairs(keys) do self:sample(key) end
            local _, _, _, moveAt = self.m:_zone()
            local step = math.min(seconds, moveAt - self.clock:now())
            assert(step > 0)
            self:advance(step); seconds -= step
        end
    end
    function f:assist(key, share)
        local identity = self:identity(key)
        identity.share = share
        return identity
    end
    function f:seal() assert(self.m:sealCombatDrain(self.matchId, self.m.round.lastSequence)) end
    function f:timer() self:advance(self.m.round.endsAt-self.clock:now()); self:seal() end
    return f
end
local function row(f, key)
    for _, p in ipairs(f.m:snapshot().result.participants) do if p.key == key then return p end end
    error("missing row")
end
Spec.row = row
local function earnings(f, key, kind)
    local rows = {}
    for _, earned in ipairs(f.m.round.earnings) do
        if earned.participantKey == key and earned.kind == kind then table.insert(rows, earned) end
    end
    return rows
end
function Spec.run()
    local result, test = Suite.new()
    test("fold assists use rounded damage share with a ten-point floor and eighty-point ceiling", function()
        for _, case in ipairs({{0.5,50}, {0.05,10}, {0.95,80}, {0.375,40}}) do
            local f=Spec.fixture(); f:join("folder"); f:join("victim"); f:join("helper",true)
            local assist=f:assist("helper",case[1])
            local event=f:event("lifeEnded","folder","victim",{assists={assist,assist}})
            assert(f.m:consumeCombat(event))
            local earned=earnings(f,"helper","fold_assist")
            assert(#earned==1 and earned[1].points==case[2])
            assert(f.m.round.participants.helper.contribution==case[2] and f.m.round.participants.helper.assists==1)
            assert(f.m.round.participants.helper.qualifyingEvents==1)
        end
    end)
    test("missing nonfinite and out-of-range assist shares reject the whole event", function()
        local f=Spec.fixture(); f:join("folder"); f:join("victim"); f:join("helper")
        local function reject(identity)
            local ok,reason=f.m:consumeCombat({eventId="invalid:share",serverSequence=1,at=0,kind="lifeEnded",
                victim=f:identity("victim"),killer=f:identity("folder"),assists={identity},reason="weapon"})
            assert(not ok and reason=="invalid_assist_share")
            assert(f.m.round.participants.folder.kills==0 and #f.m.round.earnings==0 and not f.m.round.firstFoldAwarded)
            assert(f.m.round.participants.victim.deaths==0 and f.m.round.lastSequence==0 and f.m.round.eventCount==0)
        end
        reject(f:identity("helper"))
        for _,share in ipairs({0/0,math.huge,-math.huge,-0.01,1.01,"0.4",false}) do reject(f:assist("helper",share)) end
        local ok,reason=f.m:consumeCombat({eventId="invalid:list",serverSequence=1,at=0,kind="lifeEnded",
            victim=f:identity("victim"),killer=f:identity("folder"),assists="invalid",reason="weapon"})
        assert(not ok and reason=="invalid_assists")
        f:event("lifeEnded","folder","victim",{assists={f:assist("helper",0.5)}})
        assert(f.m.round.participants.helper.contribution==50)
    end)
    test("Airspace folds pay forty outside and one hundred when either pilot is inside", function()
        for _, case in ipairs({{false,false,40}, {true,false,100}, {false,true,100}, {true,true,100}}) do
            local f=Spec.fixture("CONTROL"); f:join("folder"); f:join("victim")
            if case[1] then f:sample("folder") end
            if case[2] then f:sample("victim") end
            f:event("lifeEnded","folder","victim")
            local folds,first=earnings(f,"folder","fold"),earnings(f,"folder","first_fold")
            assert(#folds==1 and folds[1].points==case[3] and #first==1 and first[1].points==100)
            assert(f.m.round.participants.folder.contribution==case[3]+100)
            assert(f.m.round.participants.victim.sample==nil)
        end
        local f=Spec.fixture("TDM"); f:join("folder"); f:join("victim")
        f:event("lifeEnded","folder","victim"); assert(earnings(f,"folder","fold")[1].points==100)
    end)
    test("Airspace assist reduction uses that helper's position and rounds to five with a five-point floor", function()
        for _, case in ipairs({{0.5,20}, {0.35,15}, {0.05,5}, {0.95,30}}) do
            local f=Spec.fixture("CONTROL"); f:join("folder"); f:join("victim"); f:join("helper",true)
            f:sample("folder")
            f:event("lifeEnded","folder","victim",{assists={f:assist("helper",case[1])}})
            assert(earnings(f,"helper","fold_assist")[1].points==case[2])
        end
        for _, inside in ipairs({"helper","victim"}) do
            local f=Spec.fixture("CONTROL"); f:join("folder"); f:join("victim"); f:join("helper",true)
            f:sample(inside)
            f:event("lifeEnded","folder","victim",{assists={f:assist("helper",0.5)}})
            assert(earnings(f,"helper","fold_assist")[1].points==50)
        end
    end)
    test("streak bonuses start on the third fold, repeat on the fourth and reset with the life", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        for i=1,4 do
            if i>1 then f:newLife("b") end
            f:event("lifeEnded","a","b")
            assert(#earnings(f,"a","streak")==math.max(0,i-2))
            assert(f.m.round.participants.a.streak==i)
            assert(f.m:lifeStarted(f:identity("a")))
            assert(f.m.round.participants.a.streak==i)
        end
        assert(f.m.round.participants.a.contribution==550)
        f:newLife("b"); f:event("lifeEnded","b","a"); f:newLife("a")
        f:event("lifeEnded","a","b")
        assert(f.m.round.participants.a.streak==1 and f.m.round.participants.a.bestStreak==4)
        local bonuses=earnings(f,"a","streak")
        assert(#bonuses==2 and bonuses[1].points==25 and bonuses[2].points==25)
    end)
    test("revenge pays once until another fold and remembers the latest folder across lives", function()
        local f=Spec.fixture(); f:join("a"); f:join("b"); f:join("c")
        f:event("lifeEnded","b","a"); f:newLife("a")
        f:event("lifeEnded","c","a"); f:newLife("a")
        assert(f.m.round.participants.a.lastFolderKey=="c")
        f:event("lifeEnded","a","b"); assert(#earnings(f,"a","revenge")==0)
        f:event("lifeEnded","a","c")
        assert(f.m.round.participants.a.lastFolderKey==nil)
        f:newLife("c"); f:event("lifeEnded","a","c")
        local revenge=earnings(f,"a","revenge"); assert(#revenge==1 and revenge[1].points==25)
        f:newLife("c"); f:event("lifeEnded","c","a"); f:newLife("a")
        f:event("lifeEnded","a","c"); assert(#earnings(f,"a","revenge")==2)
    end)
    test("first fold is awarded once per round and a crash without credit cannot claim it", function()
        local f=Spec.fixture(); f:join("a"); f:join("b")
        f:event("lifeEnded",nil,"b",{reason="world_collision"}); f:newLife("b")
        assert(not f.m.round.firstFoldAwarded)
        local event=f:event("lifeEnded","a","b"); assert(f.m:consumeCombat(event))
        f:newLife("b"); f:event("lifeEnded","b","a")
        assert(#earnings(f,"a","first_fold")==1 and #earnings(f,"b","first_fold")==0)
        f:timer(); f:advance(23)
        local ok,matchId=f.m:startRound("FFA"); assert(ok); f.matchId=matchId
        f:join("a"); f:join("b"); f:event("lifeEnded","b","a")
        local first=earnings(f,"b","first_fold"); assert(#first==1 and first[1].points==100)
    end)
    test("Airspace keeps all bonuses at full value with separate earning identities", function()
        local f=Spec.fixture("CONTROL"); f:join("a"); f:join("b")
        f:event("lifeEnded","b","a"); f:newLife("a")
        for i=1,3 do
            if i>1 then f:newLife("b") end
            f:event("lifeEnded","a","b")
        end
        assert(f.m.round.participants.a.contribution==170)
        assert(earnings(f,"b","first_fold")[1].points==100)
        assert(earnings(f,"a","revenge")[1].points==25 and earnings(f,"a","streak")[1].points==25)
        assert(f.m.round.participants.a.qualifyingEvents==3)
        local seen={}
        for _,earned in ipairs(f.m.round.earnings) do assert(not seen[earned.factId]); seen[earned.factId]=true end
    end)
    test("zone pays twenty every five eligible seconds and qualification still uses ten", function()
        local f=Spec.fixture("CONTROL"); f:join("a"); f:join("b")
        f:sample("a"); f:advance(4.9)
        assert(f.m.round.participants.a.contribution==0 and #f.m.round.earnings==0)
        f:advance(0.1)
        local p=f.m.round.participants.a
        assert(p.contribution==20 and p.qualifyingEvents==0 and p.objectiveEvents==0)
        near(earnings(f,"a","zone")[1].at,5)
        f:advance(5); assert(p.contribution==40 and p.qualifyingEvents==1)
        f:sample("b"); f:advance(5); assert(p.contribution==40 and p.qualifyingEvents==1)
        f:sample("b",outsideZone); f:advance(10)
        assert(p.contribution==80 and p.qualifyingEvents==2 and p.zoneEvents==4)
        local zones=earnings(f,"a","zone"); assert(#zones==4)
        near(zones[3].at,20); near(zones[4].at,25)
        f:sample("a",nil,"FLYING",true); f:advance(5)
        assert(p.contribution==80 and p.qualifyingEvents==2)
        f:sample("a"); f:advance(5)
        assert(p.contribution==100 and p.qualifyingEvents==2)
        near(earnings(f,"a","zone")[5].at,35)
    end)
    test("zone cap permits all ninety-six five-second awards in a full round", function()
        local f=Spec.fixture("CONTROL"); f:join("a"); f:join("b")
        local config=table.clone(gameplay); config.rounds=table.clone(gameplay.rounds)
        config.rounds.control_target=1000; f.m.context.config=config
        assert(economy.control_personal_points_max_per_match>=1920)
        f:captureFor(480,{"a"}); f:seal()
        local p=row(f,"a")
        assert(p.contribution==1920 and p.objectiveSeconds==480 and p.qualifyingEvents==48)
        local zones=earnings(f,"a","zone"); assert(#zones==96)
        for i,earned in ipairs(zones) do assert(earned.points==20); near(earned.at,i*5) end
    end)
    test("paper targets pay fifty up to five hundred independently of the twenty-point prop cap", function()
        local f=Spec.fixture(); f:join("a"); f:join("b")
        for i=1,15 do
            local targetId="target:"..i..":a"
            assert(f.m:propContribution(targetId,"a")); assert(f.m:propContribution(targetId,"a"))
            assert(f.m:propContribution("prop:"..i,"a"))
        end
        local p=f.m.round.participants.a
        assert(p.targetPoints==500 and p.propPoints==20 and p.contribution==520 and p.qualifyingEvents==0)
        local targets,props=earnings(f,"a","target"),earnings(f,"a","prop")
        assert(#targets==10 and #props==10)
        for _,earned in ipairs(targets) do assert(earned.points==50) end
        for _,earned in ipairs(props) do assert(earned.points==2) end
        assert(f.m:propContribution("target:1:b","b") and f.m.round.participants.b.targetPoints==50)
        assert(f.m:withdraw("a")); assert(f.m:join({key="a",actorId="actor:new",controllerType="human",userId=1}))
        f:newLife("a"); assert(f.m:propContribution("target:16:a","a"))
        assert(f.m:propContribution("prop:16","a"))
        assert(p.targetPoints==500 and p.contribution==520 and #earnings(f,"a","target")==10)
    end)
    test("Control uses the configured cylinder including its boundary", function()
        local zone=gameplay.rounds.control_zones[1]
        assert(Rules.inZone(zoneCenter+Vector3.new(zone.radius,zone.half_height,0),zone))
        assert(not Rules.inZone(zoneCenter+Vector3.new(zone.radius+.01,0,0),zone))
        assert(not Rules.inZone(zoneCenter+Vector3.new(0,zone.half_height+.01,0),zone))
        assert(not Rules.inZone(zoneCenter+Vector3.new(zone.radius,0,zone.radius),zone))
    end)
    test("Ceiling cylinder includes its wide flat edge and excludes just outside", function()
        local zone=gameplay.rounds.control_zones[6]
        local center=Vector3.new(table.unpack(zone.center))
        assert(Rules.inZone(center+Vector3.new(zone.radius,zone.half_height,0),zone))
        assert(not Rules.inZone(center+Vector3.new(zone.radius+.01,0,0),zone))
        assert(not Rules.inZone(center+Vector3.new(0,zone.half_height+.01,0),zone))
    end)
    test("Control zones never repeat across 20 slots for three seeds", function()
        local rounds=gameplay.rounds
        for _,seed in ipairs({1,17029,4294967295}) do
            local previous, expected
            for slot=0,19 do
                local index,nextIndex=Rules.zoneAt(slot*rounds.control_move_seconds,rounds,seed)
                assert(index>=1 and index<=#rounds.control_zones)
                assert(nextIndex>=1 and nextIndex<=#rounds.control_zones)
                assert(index~=previous and index~=nextIndex)
                assert(expected==nil or index==expected)
                previous,expected=index,nextIndex
            end
        end
    end)
    test("Control zone selection is deterministic for the same seed", function()
        for _,elapsed in ipairs({0,37.5,90,275,479}) do
            local index,nextIndex,remaining=Rules.zoneAt(elapsed,gameplay.rounds,17029)
            local again,nextAgain,remainingAgain=Rules.zoneAt(elapsed,gameplay.rounds,17029)
            assert(index==again and nextIndex==nextAgain and remaining==remainingAgain)
        end
    end)
    test("Control move countdown decreases within a slot and resets at the move", function()
        local rounds=gameplay.rounds
        local index,nextIndex,remaining=Rules.zoneAt(10,rounds,7)
        local later,nextLater,remainingLater=Rules.zoneAt(17.5,rounds,7)
        assert(index==later and nextIndex==nextLater)
        near(remaining,80); near(remainingLater,72.5)
        local moved,_,reset=Rules.zoneAt(90,rounds,7)
        assert(moved==nextIndex); near(reset,90)
    end)
    test("Control zone selection bounds negative nonfinite and huge elapsed values", function()
        local rounds=gameplay.rounds
        local first=Rules.zoneAt(0,rounds,7)
        for _,elapsed in ipairs({-1,math.huge,0/0}) do
            local index,_,remaining=Rules.zoneAt(elapsed,rounds,7)
            assert(index==first); near(remaining,rounds.control_move_seconds)
        end
        local index,nextIndex,remaining=Rules.zoneAt(1e20,rounds,7)
        assert(index>=1 and index<=#rounds.control_zones and index~=nextIndex)
        near(remaining,rounds.control_move_seconds)
    end)
    test("Control scoring splits a catchup tick at the move on the round clock", function()
        local f=Spec.fixture("CONTROL",1000.01); f:join("a"); f:join("b")
        local zone,index,nextIndex,moveAt=f.m:_zone()
        near(moveAt,f.m.round.startedAt+90)
        assert(f.m.round.zoneSeed==f.m.seed+f.m.serial)
        f:sample("a",Vector3.new(table.unpack(zone.center)))
        f:sample("b",Vector3.new(table.unpack(gameplay.rounds.control_zones[nextIndex].center)))
        f:advance(100)
        local snapshot=f.m:snapshot()
        near(snapshot.teams[f:identity("a").teamId],90)
        near(snapshot.teams[f:identity("b").teamId],10)
        near(snapshot.participants.a.objectiveSeconds,90)
        near(snapshot.participants.b.objectiveSeconds,10)
        assert(snapshot.phase=="ACTIVE" and snapshot.zone.index==nextIndex and snapshot.zone.index~=index)
        assert(snapshot.zone.holder==f:identity("b").teamId)
        near(snapshot.zone.moveAt,f.m.round.startedAt+180)
        local public=f.m:publicSnapshot()
        assert(public.zone.index==snapshot.zone.index and public.zone.nextIndex==snapshot.zone.nextIndex)
        assert(public.zone.holder==snapshot.zone.holder); near(public.zone.moveAt,snapshot.zone.moveAt)
    end)
    test("MT01 timer cutoff excludes exact480 hit and closes before snapshot", function()
        local f = Spec.fixture(); f:join("a"); f:join("b")
        f:advance(479); f:event("weaponDamage", "a", "b")
        f:advance(1)
        assert(f.m:snapshot().phase == "ENDING" and f.m:snapshot().result == nil)
        f:event("lifeEnded", "a", "b"); f:seal()
        assert(row(f,"a").kills == 0 and row(f,"a").damage == 2)
        local before = f.m:snapshot().result
        f:event("lifeEnded", "a", "b")
        assert(row(f,"a").kills == 0 and before.endedAt == 480)
        assert(f.m.round.result and f.m.round.settlementId==f.matchId..":final")
    end)
    test("MT01 target20 exact once event and end, target event includes assists", function()
        local f = Spec.fixture(); f:join("a"); f:join("b"); f:join("c",true)
        for i = 1,20 do
            if i > 1 then f:newLife("b") end
            local e = f:event("lifeEnded","a","b", { assists = { f:assist("c", 0.4) } })
            assert(f.m:consumeCombat(e))
        end
        assert(f.m:snapshot().phase == "ENDING")
        f:seal(); f:seal()
        assert(row(f,"a").kills == 20 and row(f,"c").assists == 20 and row(f,"b").deaths == 20)
        assert(row(f,"a").contribution == 2550 and row(f,"c").contribution == 800)
        assert(f.m.round.result and f.m.round.settlementId==f.matchId..":final")
    end)
    test("MT02 TDM60 and history team stability, no friendly damage", function()
        local f = Spec.fixture("TDM"); f:join("a"); f:join("b",true)
        local team = f:identity("a").teamId
        for i = 1,60 do if i>1 then f:newLife("b") end; f:event("lifeEnded","a","b") end
        f:seal(); assert(f.m:snapshot().result.teams[team] == 60 and f.m:snapshot().result.winningTeam == team)
        local g = Spec.fixture("TDM"); g:join("x"); g:join("y"); g:join("z")
        assert(g:identity("x").teamId == g:identity("z").teamId)
        local e = { eventId="bad",serverSequence=1,at=0,kind="weaponDamage",amount=4,attacker=g:identity("x"),victim=g:identity("z") }
        assert(not g.m:consumeCombat(e)); assert(g.m:snapshot().participants.x.damage == 0)
    end)
    test("MT03 Control rate1 despite teammate count and240 target", function()
        local f = Spec.fixture("CONTROL"); f:join("a"); f:join("enemy"); f:join("mate",true)
        f:sample("a"); f:sample("mate")
        f:advance(10); near(f.m:snapshot().teams[f:identity("a").teamId],10)
        near(f.m:snapshot().participants.a.contribution,40); near(f.m:snapshot().participants.mate.contribution,40)
        f:captureFor(230,{"a","mate"}); assert(f.m:snapshot().phase == "ENDING"); f:seal()
        assert(f.m:snapshot().result.endedAt == 240)
        near(row(f,"a").objectiveSeconds,240); near(row(f,"a").activeSeconds,240)
        assert(row(f,"a").qualified and not row(f,"mate").qualified)
    end)
    test("MT03 contested protected grounded practice absent; overlay still captures", function()
        local f = Spec.fixture("CONTROL"); f:join("a"); f:join("b")
        assert(f.m:zoneHolder()==nil)
        f:sample("a"); assert(f.m:zoneHolder()==f:identity("a").teamId)
        f:sample("b"); assert(f.m:zoneHolder()=="contested")
        local team,occupants,contested=f.m:_occupants()
        assert(team==nil and #occupants==0 and contested)
        assert(f.m:snapshot().zone.holder=="contested" and f.m:publicSnapshot().zone.holder=="contested")
        f:advance(10)
        near(f.m:snapshot().teams[f:identity("a").teamId],0)
        f:sample("b",nil,"FLYING",true); f:advance(10)
        near(f.m:snapshot().teams[f:identity("a").teamId],10)
        f:sample("a",nil,"SERVICING"); f:advance(10)
        near(f.m:snapshot().teams[f:identity("a").teamId],10)
        f:sample("a",nil,"FLYING",false,true); assert(not f.m:controlActivity("a")); f:advance(10)
        near(f.m:snapshot().teams[f:identity("a").teamId],20)
        f:sample("a",nil,"FLYING",false,false,true); f:advance(10)
        near(f.m:snapshot().teams[f:identity("a").teamId],20)
    end)
    test("MT03 Control timer480 draw with alternating eligible occupancy", function()
        local f = Spec.fixture("CONTROL"); f:join("a"); f:join("b")
        f:captureFor(220,{"a"})
        f:sample("a",outsideZone); f:captureFor(220,{"b"})
        f:captureFor(40,{"a","b"}); f:seal()
        assert(f.m:snapshot().result.draw and f.m:snapshot().result.endedAt == 480)
        assert(row(f,"a").contribution == 880)
    end)
    test("MT05 timer shared FFA leaders; team draw completion only", function()
        local f = Spec.fixture(); f:join("a"); f:join("b",true); f:join("victim",true)
        f:event("lifeEnded","a","victim"); f:newLife("victim"); f:event("lifeEnded","b","victim"); f:timer()
        assert(row(f,"a").victory and row(f,"b").victory and not row(f,"victim").victory)
        local g = Spec.fixture("CONTROL"); g:join("a"); g:join("b")
        g:captureFor(120,{"a"}); g:sample("a",outsideZone); g:captureFor(120,{"b"})
        g:sample("b",outsideZone); g:timer()
        assert(g.m:snapshot().result.draw)
        assert(row(g,"a").completion and row(g,"a").finalPaper == 90 and row(g,"a").finalXP == 120)
        assert(not row(g,"a").victory and row(g,"a").place == nil)
    end)
    test("MT02 MT05 TDM480 tied teams finalize once with completion and no podium", function()
        local f=Spec.fixture("TDM"); f:join("a"); f:join("b")
        for i=1,12 do
            assert(f.m:controlActivity("a"))
            if i<=3 then f:event("weaponDamage","a","b",{amount=30}); if i<3 then f:advance(5) end end
            f:advance(10)
        end
        assert(f.m:snapshot().participants.a.qualified)
        local team=f:identity("a").teamId
        local bad={eventId="friendly:lethal",serverSequence=f.sequence+1,at=f.clock:now(),kind="lifeEnded",
            killer=f:identity("a"),victim=f:identity("a"),assists={},reason="weapon"}
        assert(not f.m:consumeCombat(bad)); assert(f.m:snapshot().teams[team]==0)
        f:timer(); f:seal()
        local result=f.m:snapshot().result
        assert(result.endedAt==480 and result.reason=="timer" and result.draw and result.winningTeam==nil)
        assert(result.teams["team:1"]==0 and result.teams["team:2"]==0)
        local a=row(f,"a")
        assert(a.completion and not a.victory and a.place==nil and a.finalPaper==90 and a.finalXP==120)
        assert(f.m.round.settlementId==f.matchId..":final")
    end)
    test("MT04 all modes seed tie no-vote least recent; current human vote only", function()
        local last = { FFA=3,TDM=1,CONTROL=2 }
        assert(Rules.chooseMode({},last,12)=="TDM")
        assert(Rules.chooseMode({a="FFA",b="CONTROL"},last,12)=="CONTROL")
        local choices, firsts = {}, {}
        local tied = { a={key="participant:1",contribution=0,kills=0,assists=0,deaths=0},
            b={key="participant:2",contribution=0,kills=0,assists=0,deaths=0} }
        for seed = 1,100 do
            local choice=Rules.chooseMode({}, {}, seed)
            assert(choice==Rules.chooseMode({}, {}, seed)); choices[choice]=true
            local order=Rules.podium(tied,seed); firsts[order[1].key]=true
            assert(order[1].key==Rules.podium(tied,seed)[1].key)
        end
        assert(choices.FFA and choices.TDM and choices.CONTROL and firsts["participant:1"] and firsts["participant:2"])
        local f=Spec.fixture(); f:join("a"); f:join("bot",true); f:timer(); f:advance(8)
        assert(f.m:snapshot().phase=="VOTE")
        assert(f.m:vote("a","FFA")); assert(f.m:vote("a","CONTROL")); assert(not f.m:vote("bot","TDM"))
        f:advance(12); assert(f.m:snapshot().nextMode=="CONTROL" and f.m:snapshot().phase=="COUNTDOWN")
        f:advance(3); assert(f.m:snapshot().phase=="READY")
    end)
    test("MT lifecycle catchup crossing8/12/3 no fabricated next round", function()
        local f=Spec.fixture(); f:join("a"); f:timer(); f:advance(23)
        assert(f.m:snapshot().phase=="READY" and f.m.serial==1)
        local old=f.matchId
        local ok, newId=f.m:startRound(); assert(ok and old~=newId and f.m:snapshot().phase=="ACTIVE")
        assert(next(f.m:snapshot().participants)==nil)
    end)
    test("qualification AFK props menu overlay and practice never manufacture activity", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        for i=1,30 do assert(f.m:propContribution("prop:"..i,"a")) end
        f:advance(120); assert(f.m:snapshot().participants.a.activeSeconds==0)
        assert(f.m:snapshot().participants.a.propPoints==20 and not f.m:snapshot().participants.a.qualified)
        f:sample("a",nil,"MENU"); f:event("weaponDamage","a","b"); f:advance(20)
        near(f.m:snapshot().participants.a.activeSeconds,0)
        f:sample("a",nil,"FLYING",false,false,true); assert(not f.m:controlActivity("a")); f:advance(20)
        near(f.m:snapshot().participants.a.activeSeconds,0)
        f:sample("a",nil,"FLYING",false,true); assert(not f.m:controlActivity("a")); f:advance(20)
        near(f.m:snapshot().participants.a.activeSeconds,0)
    end)
    test("qualification genuine control expires10; overlay keeps combat and existing window", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        assert(f.m:controlActivity("a")); f:advance(2); f:sample("a",nil,"FLYING",false,true); f:advance(18)
        near(f.m:snapshot().participants.a.activeSeconds,10)
        f:event("weaponDamage","a","b"); f:advance(20)
        near(f.m:snapshot().participants.a.activeSeconds,20)
    end)
    test("qualification once at120 and3 real events, prior4 emits graduation, withdraw retains fact", function()
        local f=Spec.fixture(); f:join("a",false,4); f:join("b",true)
        for i=1,12 do
            assert(f.m:controlActivity("a"))
            if i<=3 then f:event("weaponDamage","a","b",{amount=30}) end
            f:advance(10)
        end
        local p=f.m:snapshot().participants.a
        near(p.activeSeconds,120); assert(p.qualified and p.qualifyingEvents==3)
        assert(f.m.round.participants.a.qualified and f.m.round.participants.a.priorQualifyingMatches==4)
        assert(f.m:withdraw("a")); assert(f.m.round.participants.a.qualified)
        f:timer(); assert(row(f,"a").qualified and row(f,"a").finalPaper==0 and row(f,"a").damage==90)
    end)
    test("withdraw rejoin same and new actor retains history and permanent forfeiture, never bot history", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        f:event("lifeEnded","a","b"); f:newLife("b")
        assert(f.m:withdraw("a"))
        assert(f.m:join({key="a",actorId="actor:a",controllerType="human",userId=1}))
        f:newLife("a"); assert(f.m:snapshot().participants.a.kills==1 and f.m:snapshot().participants.a.forfeited)
        assert(f.m:disconnect("a"))
        assert(f.m:join({key="a",actorId="actor:new",controllerType="human",userId=1})); f:newLife("a")
        assert(f.m:snapshot().participants.a.kills==1 and f.m:snapshot().participants.a.streak==0)
        assert(not f.m:join({key="b",actorId="actor:swap",controllerType="human",userId=3}))
        f:timer(); assert(not row(f,"a").victory and row(f,"a").finalPaper==0)
    end)
    test("true fresh life resets streak while the continuing life preserves it", function()
        local f=Spec.fixture("TDM"); f:join("a"); f:join("b")
        f:event("lifeEnded","a","b")
        f:advance(1); assert(f.m:snapshot().participants.a.streak==1)
        f:newLife("a"); assert(f.m:snapshot().participants.a.streak==0 and f.m:snapshot().participants.a.kills==1)
    end)
    test("fresh life and rejoin cannot make parked time inherit prior control window", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        assert(f.m:controlActivity("a")); f:advance(2); f:newLife("a"); f:advance(8)
        near(f.m:snapshot().participants.a.activeSeconds,2)
        assert(f.m:controlActivity("a")); f:advance(2); assert(f.m:withdraw("a"))
        assert(f.m:join({key="a",actorId="actor:new",controllerType="human",userId=1})); f:newLife("a"); f:advance(8)
        near(f.m:snapshot().participants.a.activeSeconds,4)
    end)
    test("fresh plane is not a combat death; recent credit cannot revive a dead life streak", function()
        local f=Spec.fixture(); f:join("a"); f:join("b",true)
        f:event("lifeEnded",nil,"a",{reason="fresh_plane"})
        assert(f.m:snapshot().participants.a.deaths==0)
        f:newLife("a"); f:event("lifeEnded",nil,"a",{reason="world_collision"})
        f:event("lifeEnded","a","b",{reason="world_collision"})
        local p=f.m:snapshot().participants.a
        assert(p.deaths==1 and p.kills==1 and p.streak==0)
    end)
    test("MT06 max12 and stable balanced team boundaries without controller preference", function()
        local f=Spec.fixture("TDM"); local counts={}
        for i=1,12 do f:join("p"..i,i%2==0); local t=f:identity("p"..i).teamId; counts[t]=(counts[t] or 0)+1 end
        assert(counts["team:1"]==6 and counts["team:2"]==6)
        assert(not f.m:join({key="extra",actorId="actor:extra",controllerType="bot"}))
        local team=f:identity("p1").teamId; assert(f.m:withdraw("p1"))
        assert(f.m:join({key="p1",actorId="actor:again",controllerType="human",userId=1}))
        assert(f.m:snapshot().participants.p1.teamId==team)
    end)
    test("MT05 bot podium position is real; humans do not shift up", function()
        local records={ bot={key="bot",contribution=100,kills=1,assists=0,deaths=0},
            human={key="human",contribution=40,kills=0,assists=1,deaths=0},
            other={key="other",contribution=40,kills=0,assists=1,deaths=1} }
        local order=Rules.podium(records,17)
        assert(order[1].key=="bot" and order[2].key=="human" and order[3].key=="other")
        local f=Spec.fixture("CONTROL"); f:join("bot",true); f:join("enemy",true); f:join("human")
        f:sample("bot"); f:advance(10); f:captureFor(230,{"bot","human"}); f:seal()
        assert(row(f,"bot").place==1 and row(f,"human").place==2)
        assert(row(f,"human").finalPaper==90+40+20)
    end)
    test("settlement handoff is required before round cleanup", function()
        local f=Spec.fixture();f:join("a");f:timer();f:advance(23)
        assert(not f.m:cleanup(f.matchId,{upstreamDrained=true,livesEnded=true,replayBarrier=true}))
        assert(not f.m:acknowledgeSettlement(f.matchId,"wrong"))
        assert(f.m:acknowledgeSettlement(f.matchId,f.m.round.settlementId))
        assert(not f.m:cleanup(f.matchId,{}))
        assert(f.m:cleanup(f.matchId,{upstreamDrained=true,livesEnded=true,replayBarrier=true}))
        assert(f.m.retainedCount==0 and f.m:snapshot().matchId==nil)
    end)
    test("bounded pending rounds backpressure never evicts settlement or creates tombstones", function()
        local f=Spec.fixture()
        for i=1,Match.MAX_RETAINED_ROUNDS do
            f.matchId=f.m:snapshot().matchId
            f:advance(480); f:seal(); f:advance(23)
            if i<Match.MAX_RETAINED_ROUNDS then assert(f.m:startRound("FFA")) end
        end
        assert(not f.m:startRound("FFA") and f.m.retainedCount==Match.MAX_RETAINED_ROUNDS)
        for matchId,r in pairs(f.m.retained) do
            assert(f.m:acknowledgeSettlement(matchId,r.settlementId))
            assert(f.m:cleanup(matchId,{upstreamDrained=true,livesEnded=true,replayBarrier=true}))
        end
        assert(f.m.retainedCount==0 and f.m:startRound("FFA"))
    end)
    test("mock Studio identities explicit gate, never forge positive ID", function()
        local f=Spec.fixture()
        assert(not f.m:join({key="studio",actorId="actor:studio",controllerType="human",userId=-1}))
        f.m.context.allowStudioTestUsers=true
        local ok=f.m:join({key="studio",actorId="actor:studio",controllerType="human",userId=-1})
        assert(ok==game:GetService("RunService"):IsStudio())
        if ok then assert(f.m:snapshot().participants.studio.userId==-1 and f.m:snapshot().participants.studio.mockOnly) end
    end)
    test("public snapshot allowlist excludes controller account qualification and departed history", function()
        local f=Spec.fixture(); f:join("a"); f:join("bot",true); f:join("gone")
        assert(f.m:withdraw("gone"))
        local public=f.m:publicSnapshot()
        assert(public.zone==nil and f.m:snapshot().zone==nil and f.m:zoneHolder()==nil)
        assert(#public.pilots==2 and public.participants==nil and public.votes==nil)
        for _,p in ipairs(public.pilots) do
            assert(p.controllerType==nil and p.userId==nil and p.key==nil and p.qualified==nil
                and p.activityIntervals==nil and p.mockOnly==nil)
        end
        f:timer(); assert(#f.m:publicSnapshot().result.participants==2)
    end)
    test("advancing clock reads with empty outbox allow start join vote; blocked flag rejects", function()
        local time, blocked = 0, false
        local clock = {now=function() time+=0.0001; return time end}
        local m=Match.new({clock=clock,config=gameplay,economy=economy,sessionId="moving-clock",seed=7,
            combatDrainState=function() return {through=clock:now(),blocked=blocked} end})
        local ok,matchId=m:startRound("FFA"); assert(ok)
        assert(m:join({key="a",actorId="actor:a",controllerType="human",userId=1}))
        time+=480; m:tick(); assert(m:snapshot().phase=="ENDING")
        assert(m:sealCombatDrain(matchId,0))
        time+=8; m:tick(); assert(m:snapshot().phase=="VOTE")
        assert(m:vote("a","TDM"))
        blocked=true; assert(not m:vote("a","FFA"))
    end)
    return result
end
return Spec
