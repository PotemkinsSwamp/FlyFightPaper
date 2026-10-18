local Root=game.ReplicatedStorage.FlyFightPaper
local Server=game.ServerScriptService.FlyFightPaper
local Rules=require(Root.Shared.CombatRules)
local FlightRules=require(Root.Shared.FlightRules)
local Combat=require(Server.CombatService)
local Flight=require(Server.FlightService)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
	local result,test=Suite.new()
	local catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
	local function near(actual,expected) assert(math.abs(actual-expected)<1e-6,tostring(actual).." ~= "..tostring(expected)) end
	local function firingFixture(weapon)
		local catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
		local loadout=catalog:starterLoadout()
		if weapon then loadout.weapon_mounts={weapon,false,false,false} end
		local model=Instance.new("Model");model.Parent=game.ServerStorage;model:SetAttribute("State","FLYING")
		local body=Instance.new("Part");body.Anchored=true;body.CFrame=CFrame.identity;body.Parent=model
		local p={id="tap",kind="human",life=1,model=model,body=body,loadout=loadout,stats=catalog:deriveStats(loadout)}
		local service=setmetatable({shotCount=0,totalFired=0,serial=0,shots={},events={},cosmeticEvents={},info={},random=Random.new(),flight={catalog=catalog,records={}}},Combat)
		service:attach(p)
		return service,p,model
	end
	test("trigger groups follow the lowest filled mount and repeat by weapon type",function()
		for _,ids in ipairs({{"paperclip",false,"rubber","paperclip"},{false,"eraser","pellet","eraser"}}) do
			local loadout={weapon_mounts=ids};local before=table.clone(ids)
			local groups=assert(Rules.triggerGroups(loadout));local first=ids[1] or ids[2]
			for slot,id in ipairs(ids) do assert(groups[slot]==(id and (id==first and 1 or 2) or false) and ids[slot]==before[slot]) end
		end
		local groups=Rules.triggerGroups({weapon_mounts={"rubber",false,"paperclip"}})
		assert(groups[1]==1 and groups[2]==false and groups[3]==2)
	end)
	test("unarmed and single-type groups preserve empty slots including replicated empty strings",function()
		for _,ids in ipairs({{}, {false,false}, {"","",""}, {false,"pencil",false,"pencil"}, {"","eraser","","eraser"}}) do
			local groups=assert(Rules.triggerGroups({weapon_mounts=ids}));assert(#groups==#ids)
			for slot,id in ipairs(ids) do assert(groups[slot]==(id and id~="" and 1 or false)) end
		end
		local groups,reason=Rules.triggerGroups({weapon_mounts={"pellet","staple","rubber"}})
		assert(not groups and reason=="two weapon types per plane")
	end)
	test("paperclips keep their damage and capacity with the 1.5 s reload and fast projectile",function()
		local weapon=catalog:get("paperclip")
		assert(weapon.damage==24 and weapon.capacity==2 and weapon.shot_interval==1.5 and weapon.projectile_speed==1900)
	end)
	test("holding either automatic button does not block clicks on the other precision button",function()
		for _,ids in ipairs({{"paperclip",false,"rubber",false},{"rubber","paperclip",false,false}}) do
			local service,p,model=firingFixture();p.loadout.weapon_mounts=ids;service:attach(p)
			local info=service.info.tap;local precision,automatic
			for _,mount in ipairs(info.mounts) do if mount.weapon.id=="paperclip" then precision=mount else automatic=mount end end
			service:trigger(p,automatic.group,true);service:trigger(p,precision.group,true)
			assert(service.totalFired==2 and info.held[1] and info.held[2])
			service:trigger(p,precision.group,true);assert(service.totalFired==2)
			local ready=precision.readyAt;automatic.readyAt=0
			assert(service:fire(p,automatic,workspace:GetServerTimeNow()) and precision.readyAt==ready)
			service:trigger(p,precision.group,false);precision.readyAt=0;service:trigger(p,precision.group,true)
			assert(service.totalFired==4 and info.held[automatic.group]);model:Destroy()
		end
	end)
	test("simultaneous buttons keep separate aims, message limits and releases",function()
		local service,p,model=firingFixture();p.loadout.weapon_mounts={"paperclip",false,"pellet",false};service:attach(p)
		local now=workspace:GetServerTimeNow();local left=CFrame.Angles(0,math.rad(5),0).LookVector;local right=CFrame.Angles(0,math.rad(-5),0).LookVector
		local seq=0
		local function send(group,down,direction)
			seq+=1;return service:receive(p,{group=group,down=down,direction=direction,at=now,life=1,seq=seq},now)
		end
		for _=1,31 do assert(send(1,true,left) and send(2,true,right)) end
		local info=service.info.tap
		assert(service.totalFired==2 and info.aims[1]==left and info.aims[2]==right)
		assert(info.aimData[1].latency==0 and info.aimData[2].latency==0)
		info.mounts[2].readyAt=0;assert(service:fire(p,info.mounts[2],now))
		assert(service.shots[3].direction:Dot(right)>.999)
		assert(send(1,false) and info.held[2] and info.aims[2]==right)
		for _=32,60 do assert(send(2,true,right)) end
		assert(not send(2,true,right) and send(2,false) and not info.held[2]);model:Destroy()
	end)
	test("both buttons publish heat independently and refits remap retained mounts",function()
		local service,p,model=firingFixture();p.loadout.weapon_mounts={"pellet",false,"rubber",false};service:attach(p)
		local info=service.info.tap;info.mounts[1].heat=15;info.mounts[2].heat=40;info.mounts[2].cooling=true
		service:publishHeat(p,workspace:GetServerTimeNow())
		assert(model:GetAttribute("PrimaryHasHeat") and model:GetAttribute("AlternateHasHeat"))
		assert(model:GetAttribute("PrimaryHeat")==.5 and not model:GetAttribute("PrimaryCooling"))
		assert(model:GetAttribute("AlternateHeat")==1 and model:GetAttribute("AlternateCooling"))
		p.loadout.weapon_mounts[1]=false;service:refit(p)
		assert(info.mounts[1].slot==3 and info.mounts[1].group==1 and info.mounts[1].cooling)
		assert(model:GetAttribute("PrimaryHasHeat") and not model:GetAttribute("AlternateHasHeat"));model:Destroy()
	end)
	test("eraser speed follows distance flown at every slowdown boundary",function()
		local expected={200,200,155,110,110}
		for index,studs in ipairs({0,250,500,750,2000}) do near(Rules.eraserSpeed(200,studs),expected[index]) end
		assert(require(Root.Generated.Gameplay).combat.eraser_lock_seconds==1.5 and catalog:get("eraser").lifetime==8)
	end)
	test("eraser speed uses the supplied base speed and tuning without changing them",function()
		local config={eraser_slow_after_studs=100,eraser_slow_full_studs=300,eraser_min_speed_factor=.25}
		near(Rules.eraserSpeed(80,-10,config),80);near(Rules.eraserSpeed(80,200,config),50);near(Rules.eraserSpeed(80,900,config),20)
		assert(config.eraser_min_speed_factor==.25)
	end)
	for _,id in ipairs({"pellet","rubber"}) do
		local weapon=catalog:get(id)
		test(id.." adds one heat per shot and fires the limit shot before cooling",function()
			local heat,cooling,allowed=0,false,false
			for shot=1,weapon.shots_before_cooldown do
				heat,cooling,allowed=Rules.heatShot(heat,cooling,weapon)
				assert(allowed and heat==shot and cooling==(shot==weapon.shots_before_cooldown))
			end
			local nextHeat,nextCooling,fires=Rules.heatShot(heat,cooling,weapon)
			assert(not fires and nextHeat==heat and nextCooling)
			assert(weapon.shots_before_cooldown==(id=="pellet" and 30 or 40) and weapon.cooldown_seconds==1.5)
		end)
		test(id.." holds heat between shots and drains when released",function()
			local heat,cooling=Rules.heatStep(20,false,true,3,weapon)
			assert(heat==20 and not cooling)
			heat,cooling=Rules.heatStep(heat,cooling,false,.5,weapon)
			near(heat,20-weapon.shots_before_cooldown/weapon.cooldown_seconds*.5);assert(not cooling)
			heat,cooling=Rules.heatStep(heat,cooling,false,5,weapon);assert(heat==0 and not cooling)
		end)
		test(id.." stays blocked until fully cool even with the trigger held",function()
			local heat,cooling=Rules.heatStep(weapon.shots_before_cooldown,true,true,.75,weapon)
			near(heat,weapon.shots_before_cooldown/2);assert(cooling)
			local _,_,allowed=Rules.heatShot(heat,cooling,weapon);assert(not allowed)
			heat,cooling=Rules.heatStep(heat,cooling,true,.75,weapon);assert(heat==0 and not cooling)
			heat,cooling,allowed=Rules.heatShot(heat,cooling,weapon);assert(heat==1 and not cooling and allowed)
		end)
	end
	test("heat ignores negative elapsed time and guns without a cooldown",function()
		local heat,cooling=Rules.heatStep(10,false,false,-1,catalog:get("pellet"));assert(heat==10 and not cooling)
		heat,cooling=Rules.heatStep(30,true,true,0,catalog:get("pellet"));assert(heat==30 and cooling)
		for _,id in ipairs({"staple","paperclip","eraser","pencil"}) do
			local allowed
			heat,cooling,allowed=Rules.heatShot(0,false,catalog:get(id));assert(heat==0 and not cooling and allowed)
			heat,cooling=Rules.heatStep(heat,cooling,true,1,catalog:get(id));assert(heat==0 and not cooling)
		end
	end)
	test("automatic cooling is enforced per mount for human and bot triggers",function()
		for _,id in ipairs({"pellet","rubber"}) do for _,kind in ipairs({"human","bot"}) do
			local service,p,model=firingFixture(id);p.kind=kind
			service:trigger(p,1,true)
			local mount=service.info.tap.mounts[1];local now=mount.heatAt
			for _=2,mount.weapon.shots_before_cooldown do mount.readyAt=now;assert(service:fire(p,mount,now)) end
			assert(mount.cooling and service.totalFired==mount.weapon.shots_before_cooldown)
			mount.readyAt=now;assert(not service:fire(p,mount,now) and mount.readyAt==now)
			service:trigger(p,1,false);service:trigger(p,1,true)
			assert(service.totalFired==mount.weapon.shots_before_cooldown and mount.cooling)
			assert(model:GetAttribute("PrimaryCooling") and model:GetAttribute("PrimaryHeat")==1)
			assert(model:GetAttribute("MountCoolingUntil1")>now)
			service:coolMount(mount,true,mount.heatAt+1.5);assert(mount.heat==0 and not mount.cooling)
			assert(service:fire(p,mount,mount.heatAt) and mount.heat==1)
			model:Destroy()
		end end
	end)
	test("a hot mount does not block another gun and a refused launch adds no heat",function()
		local service,p,model=firingFixture();local info=service.info.tap
		local first,second=info.mounts[1],info.mounts[2];first.heat=30;first.cooling=true;info.held[1]=true
		local now=workspace:GetServerTimeNow();service:coolMount(first,true,now)
		assert(not service:fire(p,first,now) and service:fire(p,second,now) and second.heat==1)
		service.flight.inServiceZone=function()return true end
		second.readyAt=now;assert(not service:fire(p,second,now) and second.heat==1)
		model:Destroy()
	end)
	test("refitting keeps heat and replacing a cooling gun waits for its remaining cooldown",function()
		local service,p,model=firingFixture("pellet");local mount=service.info.tap.mounts[1]
		mount.heat=20;mount.cooling=true;mount.heatAt=workspace:GetServerTimeNow()
		service:refit(p);mount=service.info.tap.mounts[1]
		assert(mount.cooling and mount.heat>19 and mount.heat<=20)
		p.loadout.weapon_mounts[1]="rubber";local now=workspace:GetServerTimeNow();service:refit(p)
		mount=service.info.tap.mounts[1];assert(mount.heat==0 and not mount.cooling and mount.readyAt>=now+.9)
		model:Destroy()
	end)
	test("an eraser fires on any click: straight while the lock is still building, seeking once locked",function()
		local service,p,model=firingFixture("eraser");local mount=service.info.tap.mounts[1]
		local enemy={id="foe",life=1,model=model,body=p.body}
		service.targetable=function() return true end;service.visible=function() return true end
		local now=workspace:GetServerTimeNow()
		service.info.tap.lockPilot,service.info.tap.lockAt=enemy,now-.3
		assert(service:fire(p,mount,now),"a click halfway through the lock still fires")
		assert(service.shots[1].target==nil,"and that eraser flies straight")
		mount.readyAt=0;service.info.tap.activeErasers=0;service.info.tap.lockAt=now-10
		assert(service:fire(p,mount,now) and service.shots[2].target==enemy,"a finished lock makes it seek")
		model:Destroy()
	end)
	test("server erasers use distance flown for speed and send it with guidance updates",function()
		local service,p,model=firingFixture("eraser");assert(service:fire(p,service.info.tap.mounts[1],workspace:GetServerTimeNow()))
		service.clock=0;service.trackClock=0;service.flushClock=-1;service.flight.pilots={};service.flight.byId={[p.id]=p}
		service.worldCast=RaycastParams.new();service.worldCast.FilterType=Enum.RaycastFilterType.Include;service.worldCast.FilterDescendantsInstances={}
		local shot=service.shots[1];local expires=shot.expires
		local expected={20,20,15.5,11,11}
		for index,studs in ipairs({0,250,500,750,2000}) do
			shot.position=Vector3.zero;shot.direction=Vector3.zAxis;shot.flown=studs
			service:step(.1)
			near(shot.position.Z,expected[index]);near(shot.flown,studs+expected[index]);assert(shot.expires==expires)
			local event=service.cosmeticEvents[#service.cosmeticEvents]
			assert(event.kind=="update" and event.flown==shot.flown)
		end
		model:Destroy()
	end)
	test("with 100 ms round-trip lag, aimed pellets hit a straight-flying plane at 150 studs",function()
		local Config=require(Root.Generated.Gameplay).combat
		local function run(lagCompensation)
			local track={}
			local target={id="t",model=Instance.new("Folder"),body={Size=Vector3.new(14,2,15)}};target.model:SetAttribute("State","FLYING")
			local shooter={id="s"}
			local service=setmetatable({info={t={track=track}},flight={pilots={t=target,s=shooter},byId={t=target,s=shooter}}},Combat)
			local velocity=Vector3.new(107,0,0)
			local function at(time) return Vector3.new(-150,0,-150)+velocity*time end
			local oneWay,smoothing,speed=.05,Config.view_delay_seconds,900
			local random=Random.new(7);local hits,shots=0,0
			for clock=0,3,1/30 do table.insert(track,{at=clock,cf=CFrame.new(at(clock))}) end
			for click=.5,2.3,.1 do
				-- The shooter sees the target one trip plus smoothing late and leads it like the pipper does.
				local seen=at(click-oneWay-smoothing);local lead=seen
				for _=1,3 do lead=seen+velocity*(lead.Magnitude/speed) end
				local aim=(CFrame.lookAt(Vector3.zero,lead)*CFrame.Angles(math.rad(random:NextNumber(-.5,.5)),math.rad(random:NextNumber(-.5,.5)),0)).LookVector
				local shot={owner="s",weapon={},position=Vector3.zero,radius=.3,rewind=lagCompensation and math.min(Config.max_rewind_seconds,2*oneWay+smoothing) or 0}
				shots+=1
				for now=click+oneWay,click+oneWay+1,1/60 do
					local delta=aim*speed/60
					if service:planeHit(shot,delta,now) then hits+=1;break end
					shot.position+=delta
				end
			end
			target.model:Destroy()
			return hits/shots
		end
		local compensated,raw=run(true),run(false)
		assert(compensated>=.6,"hit rate "..compensated)
		assert(compensated>raw,"lag compensation should beat no compensation ("..compensated.." vs "..raw..")")
	end)
	test("an eraser only hits a pilot where they are on their own screen, not where the server last saw them",function()
		local function hits(x,kind)
			local target={id="t",kind=kind,model=Instance.new("Folder"),body={Size=Vector3.new(14,2,15),AssemblyLinearVelocity=Vector3.new(110,0,0)}}
			target.model:SetAttribute("State","FLYING")
			local shooter={id="s"}
			local service=setmetatable({info={t={track={{at=0,cf=CFrame.identity},{at=1,cf=CFrame.identity}}}},flight={pilots={t=target,s=shooter},byId={t=target,s=shooter}}},Combat)
			local shot={owner="s",weapon={homing=true},position=Vector3.new(x,0,-20),radius=.6,rewind=0}
			local hit=service:planeHit(shot,Vector3.new(0,0,40),.5)
			target.model:Destroy()
			return hit~=nil
		end
		assert(not hits(-2,"human"),"an eraser passing just behind a moving pilot must miss")
		assert(hits(5,"human"),"an eraser through where the pilot really is must hit")
		assert(hits(-2,"bot"),"bots have no screen to favour")
	end)
	test("hits follow the real model: through the wing hits, the empty corner beside it misses",function()
		local HitShapes=require(Server.HitShapes)
		local wings=Root.Assets.AircraftParts.wings_0
		local model=Instance.new("Model");local appearance=Instance.new("Model");appearance.Name="Appearance";appearance.Parent=model
		local part=wings:Clone();part.CFrame=CFrame.identity;part.Parent=appearance
		local p={id="shape-test",model=model,body={CFrame=CFrame.identity}}
		HitShapes.preload({Root.Assets.AircraftParts})
		local function down(x,z)
			HitShapes.forget(p)
			return HitShapes.cast(p,CFrame.identity,Vector3.new(x,10,z),Vector3.new(0,-20,0),Vector3.one*.2,CFrame.identity)
		end
		-- The precise shape loads in the background; until then the wing's own box stands in.
		for _=1,50 do if not down(wings.Size.X*.45,wings.Size.Z*.45) then break end;task.wait(.1) end
		assert(not down(wings.Size.X*.45,wings.Size.Z*.45),"a shot through the empty corner of the wing's box must miss")
		assert(down(wings.Size.X*.25,0),"a shot through the wing must hit")
		HitShapes.forget(p);model:Destroy()
	end)
	test("a quick pellet click fires even when released before the next server step",function()
		local service,p,model=firingFixture()
		service:trigger(p,1,true);service:trigger(p,1,false)
		assert(service.totalFired==2 and service.shotCount==2 and not service.info.tap.held[1])
		service:trigger(p,1,true);service:trigger(p,1,false)
		assert(service.totalFired==2,"another click cannot bypass reload")
		model:Destroy()
	end)
	test("a short staple press starts its burst immediately and preserves the remainder",function()
		local service,p,model=firingFixture("staple")
		service:trigger(p,1,true);service:trigger(p,1,false)
		local mount=service.info.tap.mounts[1]
		assert(service.totalFired==1 and mount.burstLeft==2 and mount.burstNext<mount.readyAt)
		model:Destroy()
	end)
	test("normal delayed turning input fires from a server mount; stale and backwards input fails",function()
		local service,p,model=firingFixture();local now=workspace:GetServerTimeNow()
		local direction=CFrame.Angles(0,math.rad(25),0).LookVector -- about what a starter turns in a delayed packet
		assert(service:receive(p,{group=1,down=true,life=1,seq=1,at=now-.25,direction=direction,muzzle=Vector3.new(9000,9000,9000)},now))
		assert(service.totalFired==2 and (service.shots[1].position-p.body.Position).Magnitude<20)
		assert(service.shots[1].direction:Dot(direction)>.999)
		assert(not service:receive(p,{group=1,down=true,life=1,seq=2,at=now-1,direction=direction},now))
		assert(not service:receive(p,{group=1,down=true,life=1,seq=3,at=now,direction=Vector3.zAxis},now))
		assert(not service:receive(p,{group=1,down=false,life=0,seq=4},now))
		assert(service:receive(p,{group=1,down=false,life=1,seq=5},now) and not service.info.tap.held[1])
		model:Destroy()
	end)
	test("expired desk protection permits targeting but never grounded firing",function()
		local model=Instance.new("Folder");model.Parent=game.ServerStorage;model:SetAttribute("State","DESK")
		local p={model=model};local protected=false
		local service=setmetatable({flight={protected=function()return protected end}},Combat)
		assert(service:targetable(p,1) and not service:eligible(p))
		protected=true;assert(not service:targetable(p,1))
		protected=false;model:SetAttribute("State","DESTROYED");assert(not service:targetable(p,1));model:Destroy()
	end)
	test("a flying plane cannot fire from any service zone or spend a reload",function()
		local model=Instance.new("Folder");model.Parent=game.ServerStorage;model:SetAttribute("State","FLYING")
		local body=Instance.new("Part");body.Anchored=true;body.Parent=model
		local p={id="test",model=model,body=body,loadout={body="body_standard"},spawnProtectionUntil=100}
		local service=setmetatable({shotCount=0,info={test={aim=Vector3.new(0,0,-1)}},flight={catalog={get=function()return {visual_scale=2}end},inServiceZone=function()return true end}},Combat)
		local mount={slot=1,readyAt=0,weapon={id="pellet",fire_mode="automatic",spread_deg=0,projectile_radius=.3}}
		assert(not service:fire(p,mount,1) and mount.readyAt==0 and p.spawnProtectionUntil==100)
		model:Destroy()
	end)
	test("refit retains hit history, eraser cap and later existing reloads",function()
		local now=workspace:GetServerTimeNow();local history={{attacker="other",at=now,damage=20}}
		local old={slot=1,weapon={id="pencil"},readyAt=now+6}
		local service=setmetatable({info={test={mounts={old},held={true,true},history=history,activeErasers=2}},flight={catalog={get=function(_,id)return {id=id,shot_interval=4,visual_scale=2}end}}},Combat)
		local model=Instance.new("Folder")
		service:refit({id="test",model=model,loadout={body="body_heavy",weapon_mounts={"pencil","pencil",false,false,false,false}}})
		assert(model:GetAttribute("Mounts")=="pencil,pencil,,,,","the shooter's client needs the new mounts")
		local info=service.info.test
		assert(info.history==history and info.activeErasers==2 and info.held[1]==false)
		assert(info.mounts[1].readyAt==now+6 and info.mounts[2].readyAt>=now+4)
		model:Destroy()
	end)
	test("last eligible weapon hit receives kill; other qualifying damage receives assist",function()
		local killer,assists,damage,total=Rules.credit({{attacker="a",at=1,damage=12},{attacker="b",at=2,damage=1}},3,120,"victim")
		assert(killer=="b" and #assists==1 and assists[1]=="a")
		assert(damage.a==12 and damage.b==1 and total==13)
	end)
	test("old, self and insufficient assist damage cannot earn credit",function()
		local killer,assists,damage,total=Rules.credit({{attacker="old",at=-1,damage=100},{attacker="tiny",at=12,damage=11},{attacker="victim",at=13,damage=200},{attacker="last",at=14,damage=1},{attacker="future",at=16,damage=999}},15,120,"victim")
		assert(killer=="last" and #assists==0)
		assert(total==12 and damage.tiny==11 and damage.last==1 and damage.old==nil and damage.victim==nil and damage.future==nil)
		assert(Rules.credit({},15,120,"victim")==nil)
	end)
	test("assist damage totals include all attackers and the exact fifteen-second boundary",function()
		local history={{attacker="z",at=0,damage=6},{attacker="z",at=6,damage=6},
			{attacker="a",at=10,damage=24},{attacker="small",at=11,damage=3},{attacker="last",at=15,damage=15}}
		local killer,assists,damage,total=Rules.credit(history,15,120,"victim")
		assert(killer=="last" and #assists==2 and assists[1]=="a" and assists[2]=="z")
		assert(damage.z==12 and damage.a==24 and damage.small==3 and damage.last==15 and total==54)
		assert(history[1].damage==6 and #history==5)
		local none,empty,amounts,sum=Rules.credit({},15,120,"victim")
		assert(none==nil and #empty==0 and next(amounts)==nil and sum==0)
	end)
	test("big damage wins the fold; the last hitter is the finisher (Alan 2026-10-17)",function()
		local killer,assists,_,_,finisher=Rules.credit({{attacker="big",at=1,damage=96},{attacker="last",at=9,damage=24}},10,120,"victim")
		assert(killer=="big" and finisher=="last" and #assists==1 and assists[1]=="last")
		local k2,_,_,_,f2=Rules.credit({{attacker="half",at=1,damage=59},{attacker="last",at=9,damage=61}},10,120,"victim")
		assert(k2=="last" and f2==nil,"under half the plane, or less than the finisher, keeps the last hit's fold")
		local k3,a3,_,_,f3=Rules.credit({{attacker="big",at=1,damage=96},{attacker="last",at=17,damage=24}},17,120,"victim")
		assert(k3=="last" and f3==nil and #a3==0,"damage older than 15 s counts for nothing")
	end)
	test("a repair wipes earlier damage from fold and assist credit",function()
		local killer,assists,_,_,finisher=Rules.credit({{attacker="big",at=1,damage=96},{attacker="last",at=9,damage=24}},10,120,"victim",5)
		assert(killer=="last" and #assists==0 and finisher==nil)
	end)
	test("authoritative order settles simultaneous last hits",function()
		local killer=Rules.credit({{attacker="a",at=1,damage=10},{attacker="b",at=1,damage=10}},1,120,"victim")
		assert(killer=="b")
	end)
	test("one pencil press selects one barrel; reloads stay independent",function()
		local weapon={fire_mode="semiautomatic",shot_interval=4}
		local mounts={{group=2,readyAt=0,weapon=weapon},{group=2,readyAt=0,weapon=weapon}}
		local index=Rules.readyMount(mounts,2,0,0);assert(index==1);Rules.consume(mounts[index],0)
		assert(mounts[1].readyAt==4 and mounts[2].readyAt==0)
		index=Rules.readyMount(mounts,2,2,index);assert(index==2);Rules.consume(mounts[index],2)
		assert(mounts[1].readyAt==4 and mounts[2].readyAt==6)
		assert(Rules.readyMount(mounts,2,3,index)==nil and Rules.readyMount(mounts,2,4,index)==1)
	end)
	test("an automatic button cannot swallow the other button's precision shot",function()
		local mounts={{group=1,readyAt=0,weapon={fire_mode="automatic"}},{group=2,readyAt=0,weapon={fire_mode="semiautomatic"}}}
		local fired={}
		local service=setmetatable({info={pilot={mounts=mounts,held={false,false},roundRobin={0,0}}}},Combat)
		function service:eligible() return true end
		function service:fire(_,mount) table.insert(fired,mount);return true end
		service:trigger({id="pilot",body={CFrame=CFrame.identity}},1,true)
		service:trigger({id="pilot",body={CFrame=CFrame.identity}},2,true)
  assert(#fired==2 and fired[1]==mounts[1] and fired[2]==mounts[2])
  service:trigger({id="pilot",body={CFrame=CFrame.identity}},2,true);assert(#fired==2)
		service:trigger({id="pilot",body={CFrame=CFrame.identity}},2,false)
  service:trigger({id="pilot",body={CFrame=CFrame.identity}},2,true);assert(#fired==3 and fired[3]==mounts[2])
		assert(service.info.pilot.held[1] and service.info.pilot.held[2])
	end)
	test("full eraser cap blocks without spending reload",function()
		local model=Instance.new("Folder");model.Parent=game.ServerStorage;model:SetAttribute("State","FLYING")
		local p={id="test",model=model}
		local service=setmetatable({shotCount=0,info={test={activeErasers=2}}},Combat)
		local mount={readyAt=0,weapon={id="eraser",homing=true,fire_mode="semiautomatic",shot_interval=4}}
		assert(not service:fire(p,mount,1));assert(mount.readyAt==0)
		model:Destroy()
	end)
	test("an eraser hits a plane flying straight; a hard turn timed as it closes in dodges it",function()
		local catalog=require(Root.Shared.Catalog).new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
		local eraser=catalog:get("eraser")
		local function chase(breakAt,range)
			local dt,plane,heading=1/60,Vector3.zero,Vector3.new(0,0,-1)
			local at=Vector3.new(30,0,range or 250);local direction,tracking,flown=(plane-at).Unit,true,0
			for _=1,eraser.lifetime*60 do
				local gap=(at-plane).Magnitude
				if gap<9 then return true end
				local speed=110
				if breakAt and gap<breakAt then heading=CFrame.fromAxisAngle(Vector3.yAxis,-math.rad(117)*dt):VectorToWorldSpace(heading);speed*=.75 end
				plane+=heading*speed*dt
				if tracking then
					local steered=Rules.eraserSteer(direction,(plane-at).Unit,dt)
					tracking=steered~=nil;direction=steered or direction
				end
				local travel=Rules.eraserSpeed(eraser.projectile_speed,flown)*dt
				at+=direction*travel;flown+=travel
			end
			return false
		end
		assert(chase(nil),"straight flight should be hit")
		assert(not chase(150),"a break turn at 150 studs should dodge")
		assert(chase(400),"breaking far too early should still be caught")
		assert(chase(50),"breaking too late should still be caught")
		assert(not chase(nil,500),"a long chase should lose closing speed before catching straight flight")
	end)
	test("eraser release is exactly once",function()
		local shot={id=1,owner="test",weapon={id="eraser",homing=true},position=Vector3.zero}
		local service=setmetatable({shots={[1]=shot},shotCount=1,info={test={activeErasers=2}},events={},cosmeticEvents={}},Combat)
		service:finish(shot);service:finish(shot)
		assert(service.shotCount==0 and service.info.test.activeErasers==1 and #service.cosmeticEvents==1 and #service.events==0)
	end)
	test("destruction ends a life only once",function()
		local model=Instance.new("Folder");model.Parent=game.ServerStorage;model:SetAttribute("State","FLYING")
		local body=Instance.new("Part");body.Anchored=true;body.Parent=model
		local deaths=0
		local service=setmetatable({records={test={deaths=0,weaponDeaths=0,collisionDeaths=0}},onDeath=function()deaths+=1 end},Flight)
		local p={id="test",model=model,body=body,drive={},orientation={}}
		service:destroy(p,{kind="weapon"},"weapon");service:destroy(p,{kind="weapon"},"weapon")
		assert(service.records.test.deaths==1 and service.records.test.weaponDeaths==1 and deaths==1)
		model:Destroy()
	end)
	test("removed pilots release their shots and combat state without affecting others",function()
		local own={id=1,owner="leaving",weapon={id="eraser",homing=true},position=Vector3.zero}
		local other={id=2,owner="staying",weapon={id="eraser",homing=true},position=Vector3.zero}
		local service=setmetatable({shots={[1]=own,[2]=other},shotCount=2,info={leaving={activeErasers=1},staying={activeErasers=1}},events={},cosmeticEvents={}},Combat)
		service:detach({id="leaving"});service:detach({id="leaving"})
		assert(service.info.leaving==nil and service.info.staying.activeErasers==1)
		assert(service.shots[2]==other and service.shots[1]==nil and service.shotCount==1 and #service.cosmeticEvents==1)
	end)
	test("mounted guns never touch each other, and the paperclip hangs clear of the wing root",function()
		local Aircraft=require(Root.Shared.Aircraft)
		local function across(loadout)
			local model=Instance.new("Model");Aircraft.build(model,loadout,catalog,true)
			local x={}
			for _,part in ipairs(model.Appearance:GetChildren()) do
				local slot=tonumber(part.Name:match("^Mount(%d+)%-"))
				if slot then
					local half=math.abs(part.CFrame:VectorToWorldSpace(part.Size*Vector3.new(.5,0,0)).X)
					x[slot]=x[slot] or {lo=math.huge,hi=-math.huge}
					x[slot].lo=math.min(x[slot].lo,part.Position.X-half);x[slot].hi=math.max(x[slot].hi,part.Position.X+half)
				end
			end
			model:Destroy()
			return x
		end
		local heavy=across({body="body_heavy",nose="nose_0",wings="wings_0",tail="tail_0",weapon_mounts={"eraser","eraser","eraser","eraser","eraser","eraser"}})
		assert(heavy[3].lo-heavy[5].hi>0 and heavy[6].lo-heavy[4].hi>0,"outer erasers overlap their neighbours")
		-- guns scale with the wing they hang from (the cardboard body fits Classic Wings at 83%)
		local missile=Root.Assets.AircraftPieces.launcher_eraser.missile.Size.X*catalog:get("body_heavy").visual_scale/2*Aircraft.wingFit("body_heavy","wings_0",0).scale
		assert(math.abs(heavy[1].hi-heavy[1].lo-missile)<.01,"guns with room keep their full size")
		assert(heavy[5].hi-heavy[5].lo<missile-.1,"the crowded outer gun is shrunk")
		local factor=catalog:get("body_standard").visual_scale/2
		near(Aircraft.mountOffset(1,factor,0,"paperclip").Y,Aircraft.mountOffset(1,factor,0,"pellet").Y-.5*factor)
		-- Wing attachment points: a wing's root front/back corners land on the body's wall front/back, evenly scaled,
		-- and the gun slots go with the wing.
		local pieces=Root.Assets.AircraftPieces
		local function at(model,name) local v=string.split(pieces[model]:GetAttribute(name),",") return Vector3.new(tonumber(v[1]),tonumber(v[2]),tonumber(v[3])) end
		for _,wings in ipairs({"wings_0","wings_2","wings_3"}) do
			local fit=Aircraft.wingFit("body_heavy",wings,0)
			for _,ends in ipairs({{"RootFront","WingFront"},{"RootBack","WingBack"}}) do
				local landed=Aircraft.fitPoint(fit,at(wings,ends[1]))
				assert((landed-at("body_heavy",ends[2])).Magnitude<1e-4,wings.." "..ends[1].." misses the wall")
			end
			local m=at(wings,"Mount1") -- slot 3: the left gun of the first under-wing pair, on the wing's own spot
			assert((Aircraft.mountOffset(3,1,fit,"pellet")-Aircraft.fitPoint(fit,Vector3.new(-m.X,m.Y,m.Z))).Magnitude<1e-4,wings.." gun is off its wing spot")
		end
		near(Aircraft.wingFit("body_standard","wings_0",0).scale,1)
	end)
	test("the chalk cloud blocks sight like a building, shrinking over the second half of its life",function()
		local chalk={radius=100,seconds=20}
		local eraser=Instance.new("Model")
		local west,east=Vector3.new(-400,60,0),Vector3.new(400,60,0)
		assert(not Rules.chalkBlocks(eraser,west,east,0,chalk),"no puff yet")
		eraser:SetAttribute("CloudAt",Vector3.new(0,60,0));eraser:SetAttribute("CloudUntil",20)
		assert(Rules.chalkBlocks(eraser,west,east,5,chalk),"through it, both outside")
		assert(Rules.chalkBlocks(eraser,west,Vector3.new(90,60,0),5,chalk),"into it")
		assert(Rules.chalkBlocks(eraser,Vector3.new(0,60,50),west,5,chalk),"out of it")
		assert(not Rules.chalkBlocks(eraser,west,Vector3.new(-200,60,0),5,chalk),"short of it")
		assert(not Rules.chalkBlocks(eraser,Vector3.new(-400,200,0),Vector3.new(400,200,0),5,chalk),"passes over")
		assert(Rules.chalkRadius(chalk,20,10)==100,"full size until half way")
		assert(math.abs(Rules.chalkRadius(chalk,20,15)-50)<1e-6,"half size with a quarter left")
		assert(not Rules.chalkBlocks(eraser,Vector3.new(-400,130,0),Vector3.new(400,130,0),15,chalk),"the edge has drawn in")
		assert(Rules.chalkRadius(chalk,20,19.9)==15,"never smaller than 15% while it lasts")
		assert(not Rules.chalkBlocks(eraser,west,east,20,chalk),"gone")
		assert(not Rules.chalkBlocks(nil,west,east,5,chalk),"no eraser in the place")
		eraser:Destroy()
	end)
	return result
end
return Spec
