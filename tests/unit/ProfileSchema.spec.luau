local Root=game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Schema=require(Root.Shared.ProfileSchema)
local Economy=require(Root.Shared.EconomyRules)
local Catalog=require(Root.Shared.Catalog)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
function Spec.run()
	local result,test=Suite.new()
	local catalog=Catalog.new(require(Root.Generated.Catalog),require(Root.Generated.Gameplay))
	local function fresh() return Schema.defaults(catalog) end
	test("explicit defaults grant only catalog starter ownership and five legal presets",function()
		local p=assert(Schema.validate(fresh(),catalog)); local starter=assert(Economy.starterOwnership(catalog))
		assert(Schema.canonical(p.ownership)==Schema.canonical(starter) and #p.presets==5)
		assert(p.paperMilli==require(Root.Generated.Economy).initial_paper*1000)
		assert(p.xpMilli==require(Root.Generated.Economy).initial_total_xp*1000)
	end)
	test("new profiles have valid default crosshair settings",function()
		local p=fresh()
		assert(p.settings.crosshairColor=="blue" and p.settings.crosshairSize=="Medium")
		assert(Schema.validate(p,catalog))
	end)
	test("every allowed crosshair color and size validates",function()
		for _,color in ipairs({"green","red","blue","yellow","purple","white"}) do
			local p=fresh(); p.settings.crosshairColor=color; assert(Schema.validate(p,catalog))
		end
		for _,size in ipairs({"Small","Medium","Large"}) do
			local p=fresh(); p.settings.crosshairSize=size; assert(Schema.validate(p,catalog))
		end
	end)
	test("invalid or missing crosshair settings reject",function()
		for _,color in ipairs({"orange",1}) do
			local p=fresh(); p.settings.crosshairColor=color
			local valid,err=Schema.validate(p,catalog); assert(not valid and err:find("invalid_crosshair_color",1,true))
		end
		for _,size in ipairs({"Huge",1}) do
			local p=fresh(); p.settings.crosshairSize=size
			local valid,err=Schema.validate(p,catalog); assert(not valid and err:find("invalid_crosshair_size",1,true))
		end
		local p=fresh(); p.settings.crosshairColor=nil; assert(not Schema.validate(p,catalog))
		p=fresh(); p.settings.crosshairSize=nil; assert(not Schema.validate(p,catalog))
	end)
	test("previous schema migration adds only crosshair defaults without mutating input",function()
		local p=fresh(); p.schemaVersion=Schema.VERSION-1; p.settings.crosshairColor=nil; p.settings.crosshairSize=nil
		p.paperMilli=1234567; p.settings.music=0.25; p.settings.quality="Low"; p.extensions={custom={kept=true}}
		local original=Schema.canonical(p)
		local migrated=assert(Schema.migrate(p,catalog))
		assert(migrated.schemaVersion==Schema.VERSION and migrated.settings.crosshairColor=="blue" and migrated.settings.crosshairSize=="Medium")
		assert(Schema.validate(migrated,catalog))
		assert(Schema.canonical(p)==original,"migration mutated input")
		local expected=assert(Schema.copy(p)); expected.schemaVersion=Schema.VERSION
		expected.settings.crosshairColor="blue"; expected.settings.crosshairSize="Medium"
		assert(Schema.canonical(migrated)==Schema.canonical(expected),"migration changed unrelated fields")
	end)
	test("v1 migration preserves exact value and unrelated fields",function()
		local p=fresh(); p.schemaVersion=1; p.streams=nil; p.journal={}; p.operationIds=nil; p.operationSessions=nil; p.receiptIds=nil; p.paperMilli=1234567; p.xpMilli=98765
		p.settings.crosshairColor=nil; p.settings.crosshairSize=nil
		p.boosts.xpSeconds=10.25; p.extensions={custom={kept=true}}
		assert(catalog:get("pencil") and not p.ownership.pencil); p.ownership.pencil=true
		local ownership=Schema.canonical(p.ownership)
		local migrated=assert(Schema.migrate(p,catalog))
		assert(migrated.schemaVersion==Schema.VERSION and migrated.paperMilli==1234567 and migrated.xpMilli==98765)
		assert(migrated.boosts.xpSeconds==10.25 and migrated.extensions.custom.kept and p.schemaVersion==1)
		assert(migrated.ownership.pencil and Schema.canonical(migrated.ownership)==ownership)
		assert(Schema.canonical(p.ownership)==ownership,"migration mutated input ownership")
		assert(migrated.settings.crosshairColor=="blue" and migrated.settings.crosshairSize=="Medium" and Schema.validate(migrated,catalog))
		p.ownership=nil; assert(not Schema.migrate(p,catalog))
	end)
	test("v2 migration continues through crosshair defaults",function()
		local p=fresh(); p.schemaVersion=2; p.journal={}; p.streams={}; p.operationIds=nil; p.operationSessions=nil; p.receiptIds=nil
		p.settings.crosshairColor=nil; p.settings.crosshairSize=nil
		local migrated=assert(Schema.migrate(p,catalog))
		assert(migrated.schemaVersion==Schema.VERSION and migrated.settings.crosshairColor=="blue" and migrated.settings.crosshairSize=="Medium")
		assert(migrated.journal==nil and migrated.streams==nil and Schema.validate(migrated,catalog))
	end)
	test("malformed and future versions fail closed",function()
		local p=fresh(); p.schemaVersion=Schema.VERSION+1; assert(not Schema.migrate(p,catalog))
		p=fresh(); p.schemaVersion=Schema.VERSION-1; p.settings=nil; assert(not Schema.migrate(p,catalog))
		p=fresh(); p.paperMilli=-1; assert(not Schema.validate(p,catalog))
		p=fresh(); p.presets[5]=nil; assert(not Schema.validate(p,catalog))
		p=fresh(); p.injected=true; assert(not Schema.validate(p,catalog))
	end)
	test("nonfinite money, unsafe integers, keys, cycles, functions, Instances and metatables reject",function()
		for _,n in ipairs({0/0,math.huge,-math.huge,9007199254740992}) do local p=fresh(); p.xpMilli=n; assert(not Schema.validate(p,catalog)) end
		local cycle={}; cycle.self=cycle; assert(not Schema.copy(cycle))
		assert(not Schema.copy({[false]=true})); assert(not Schema.copy({[1.5]=true}))
		assert(not Schema.copy({[1]="x",[3]="z"})); assert(not Schema.copy({[1]="x",name="z"}))
		assert(not Schema.copy({callback=function() end})); assert(not Schema.copy(setmetatable({},{__index={}})))
		local object=Instance.new("Folder"); local copied=Schema.copy({object=object}); object:Destroy(); assert(not copied)
	end)
	test("depth, entries, bytes, strings and operation IDs are bounded",function()
		local root={}; local p=root; for _=1,Schema.MAX_DEPTH do p.next={}; p=p.next end; assert(not Schema.copy(root))
		local entries={}; for i=1,Schema.MAX_ENTRIES+1 do entries[i]=true end; assert(not Schema.copy(entries))
		local bytes={}; for i=1,30 do bytes[i]=string.rep("x",4000) end; assert(not Schema.copy(bytes))
		assert(not Schema.copy({value=string.rep("x",4097)}))
		p=fresh(); for i=1,require(Root.Generated.Server).profiles.session_id_history+1 do local token="session"..i;table.insert(p.operationSessions,token);p.operationIds[token]=1 end; assert(not Schema.validate(p,catalog))
	end)
	test("ownership and level gates validate every saved loadout with exact mount order",function()
		local p=fresh(); p.presets[1].loadout.weapon_mounts[1]="pencil"; assert(not Schema.validate(p,catalog))
		p=fresh(); table.insert(p.presets[1].loadout.weapon_mounts,false); assert(not Schema.validate(p,catalog))
		p=fresh(); p.ownership.invented=true; assert(not Schema.validate(p,catalog))
		local expensive
		for _,item in ipairs(catalog.weapons) do if item.min_level>1 then expensive=item; break end end
		assert(expensive); p=fresh(); p.ownership[expensive.id]=true; p.presets[1].loadout.weapon_mounts[1]=expensive.id
		assert(not Schema.validate(p,catalog))
	end)
	test("capacity tuning recovers only the affected preset and preserves the account",function()
		local p=fresh();p.xpMilli=60000000;p.paperMilli=1234567;p.ownership.eraser=true;p.ownership.rubber=true
		p.presets[2].name="Guided build";p.presets[2].loadout.weapon_mounts={"eraser",false,"rubber","rubber"}
		p.settings.music=.25;p.extensions={custom={kept=true}}
		local original=Schema.canonical(p)
		assert(not Schema.validate(p,catalog),"ordinary validation must still reject an over-capacity build")
		local recovered=assert(Schema.migrate(p,catalog));local expected=assert(Schema.copy(p))
		expected.presets[2].loadout=catalog:starterLoadout()
		assert(Schema.canonical(recovered)==Schema.canonical(expected),"recovery changed unrelated progress")
		assert(Schema.canonical(p)==original,"recovery mutated the saved input")
		assert(Schema.canonical(assert(Schema.migrate(recovered,catalog)))==Schema.canonical(recovered),"recovery must be idempotent")
	end)
	test("a saved third weapon type recovers only its preset and pending refold",function()
		local p=fresh();p.xpMilli=60000000;p.paperMilli=1234567;p.ownership.staple=true;p.ownership.rubber=true
		p.presets[2].name="Three old guns";p.presets[2].loadout.weapon_mounts={"pellet","staple","rubber",false}
		p.presets[3].loadout.weapon_mounts={"staple","pellet",false,false}
		p.qualification.count=2;p.qualification.history={first=true,second=true};p.statistics.matches=3;p.settings.music=.25;p.extensions={custom={kept=true}}
		p.refolds={pending={state="reserved",costMilli=require(Root.Generated.Gameplay).service.full_refold_paper*1000,
			loadout=assert(Schema.copy(p.presets[2].loadout)),fence={nonce="old",generation=1,sessionGeneration=1,actorId="pilot",lifeId="1",matchId="match",participationId="pilot",padId="desk"}}}
		local original=Schema.canonical(p);assert(not Schema.validate(p,catalog))
		local migrated=assert(Schema.migrate(p,catalog));local expected=assert(Schema.copy(p))
		expected.presets[2].loadout=catalog:starterLoadout();expected.refolds.pending.loadout=catalog:starterLoadout()
		assert(Schema.canonical(migrated)==Schema.canonical(expected) and Schema.canonical(p)==original)
		assert(Schema.canonical(Schema.migrate(migrated,catalog))==Schema.canonical(migrated))
	end)
	test("capacity recovery still rejects unknown parts, wrong mounts and unowned or locked presets",function()
		local p=fresh();p.presets[1].loadout.weapon_mounts[1]="invented";assert(not Schema.migrate(p,catalog))
		p=fresh();p.presets[1].loadout.weapon_mounts[3]="pencil";assert(not Schema.migrate(p,catalog))
		p=fresh();p.xpMilli=60000000;p.presets[1].loadout.weapon_mounts[1]="rubber";assert(not Schema.migrate(p,catalog))
		p=fresh();p.ownership.rubber=true;p.presets[1].loadout.weapon_mounts[1]="rubber";assert(not Schema.migrate(p,catalog))
	end)
	test("settings agree with SessionProtocol and names reject invalid UTF8/control bytes",function()
		local p=fresh(); p.settings={sensitivity=0.2,sound=0,music=0.5,reducedShake=true,quality="Low",crosshairColor="blue",crosshairSize="Medium"}; assert(Schema.validate(p,catalog))
		p.settings.sensitivity=0.1; assert(not Schema.validate(p,catalog))
		p=fresh(); p.presets[1].name="bad\nname"; assert(not Schema.validate(p,catalog))
		p.presets[1].name=string.char(255); assert(not Schema.validate(p,catalog))
	end)
	test("economic view is narrow immutable and merges without changing unrelated state",function()
		local p=fresh(); p.extensions={nested={journal={inner={value=true}}}}
		p.version=1; p.operationIds.old=1;p.operationSessions={"old"}
		local view=Schema.economicView(p); assert(view.journal==nil and view.boosts==nil)
		assert(not pcall(function() view.ownership.fake=true end))
		local earned=assert(Economy.applyContribution(view,1,{paper=1,xp=2},"immutable"))
		Schema.mergeEconomic(p,earned.profile)
		assert(p.paperMilli==363 and p.xpMilli==1360 and p.operationIds.old==1 and p.extensions.nested.journal.inner.value)
	end)
	test("canonical identities distinguish types, payloads and delimiter-containing strings",function()
		assert(Schema.canonical({a="1"})~=Schema.canonical({a=1}))
		assert(Schema.canonical({a="b:c",d="e"})~=Schema.canonical({a="b",c="d:e"}))
		assert(Schema.canonical({a=1,b=2})==Schema.canonical({b=2,a=1}))
	end)
	return result
end
return Spec
