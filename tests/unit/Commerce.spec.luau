local Root=game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local Rules=require(Root.Shared.CommerceRules)
local JSON=require(Root.Generated.JSONTypes)
local Config=require(Root.Generated.Commerce)
local Catalog=require(Root.Shared.Catalog)
local Economy=require(Root.Shared.EconomyRules)
local Suite=require(script.Parent.Parent.fixtures.Suite)
local Spec={}
local function copy(v)
    if v==JSON.Null or type(v)~="table" then return v end
    local t={}; for k,x in pairs(v) do t[k]=copy(x) end; return t
end
local function boosts() return {xpSeconds=1800,paperSeconds=900,permanentXP=false,permanentPaper=false} end
function Spec.run()
    local result,test=Suite.new()
    test("all fifteen immutable configured offers and generated null sentinel",function()
        local c=assert(Rules.catalog(Config)); assert(#c.offers==#Config.products and #c.offers>15)
        assert(c.mode=="mock" and not c.authorized)
        for _,p in ipairs(Config.products) do assert(not p.enabled and p.roblox_product_id==JSON.Null and p.approved_robux_price==JSON.Null) end
        for _,r in ipairs({"xp","paper"}) do
            for _,m in ipairs({15,30,60,180,300}) do assert(c.byKey[r.."_boost_"..m.."m"].amount==m*60) end
        end
        for _,n in ipairs({1000,3500,10000}) do assert(c.byKey["paper_pack_"..n].amount==n) end
        assert(c.byKey.permanent_2x_xp.kind=="pass" and c.byKey.permanent_2x_paper.amount==2)
    end)
    test("part offers cover exactly the nonstarter catalog parts above level one",function()
        local parts=Catalog.new(require(Root.Generated.Catalog));local starter=assert(Economy.starterOwnership(parts))
        local c=assert(Rules.catalog(Config));local count=0
        for id,definition in pairs(parts.byId) do
            local offer=c.byKey["part_"..id]
            if not starter[id] and definition.min_level>1 then
                count+=1
                assert(offer and offer.catalogID==id and offer.kind=="developer_product" and offer.benefit=="part_unlock")
                assert(offer.amount==nil and table.isfrozen(offer))
            else assert(offer==nil) end
        end
        assert(#c.offers==15+count)
        for i,offer in ipairs(c.offers) do assert((offer.benefit=="part_unlock")== (i>15)) end
    end)
    test("zero or additional part offers are accepted without a Catalog dependency",function()
        local raw=copy(Config)
        while #raw.products>15 do table.remove(raw.products) end
        assert(#assert(Rules.catalog(raw)).offers==15)
        table.insert(raw.products,{key="part_future_part",kind="developer_product",benefit="part_unlock",catalog_id="future_part",
            roblox_product_id=JSON.Null,approved_robux_price=JSON.Null,enabled=false})
        local offer=assert(Rules.catalog(raw)).byKey.part_future_part
        local op=Rules.operation(offer,"unused",7);local fields=0
        for _ in pairs(op) do fields+=1 end
        assert(op.kind=="partUnlock" and op.catalogID=="future_part" and fields==2 and table.isfrozen(op))
    end)
    test("every fixed offer is still required even when the array contains part offers",function()
        for i=1,15 do
            local raw=copy(Config);table.remove(raw.products,i)
            assert(Rules.catalog(raw)==nil)
        end
        local raw=copy(Config);raw.products[#raw.products+2]=copy(raw.products[16]);assert(Rules.catalog(raw)==nil)
        raw=copy(Config);raw.products[0]=copy(raw.products[16]);assert(Rules.catalog(raw)==nil)
    end)
    test("part keys ids kinds amounts and unknown fields are validated strictly",function()
        local changes={function(p)p.key="part_wrong"end,function(p)p.catalog_id=""end,function(p)p.catalog_id=7 end,
            function(p)p.catalog_id=nil end,function(p)p.kind="pass"end,function(p)p.amount=1 end,
            function(p)p.amount=JSON.Null end,function(p)p.enabled="false"end,function(p)p.extra=true end}
        for _,change in ipairs(changes) do
            local raw=copy(Config);change(raw.products[16]);assert(Rules.catalog(raw)==nil)
        end
        local raw=copy(Config);raw.products[1].catalog_id="staple";assert(Rules.catalog(raw)==nil)
        raw=copy(Config);table.insert(raw.products,copy(raw.products[16]));assert(Rules.catalog(raw)==nil)
    end)
    test("part offers share the fixed offers' mapping price enabled and duplicate id rules",function()
        for _,field in ipairs({"roblox_product_id","approved_robux_price"}) do
            for _,value in ipairs({0,-1,1.5,"12",{}}) do
                local raw=copy(Config);raw.products[16][field]=value;assert(Rules.catalog(raw)==nil)
            end
            local raw=copy(Config);raw.products[16][field]=nil;assert(Rules.catalog(raw)==nil)
        end
        local raw=copy(Config);raw.products[16].enabled=true;assert(Rules.catalog(raw)==nil)
        raw=copy(Config);raw.products[16].roblox_product_id=99;assert(Rules.catalog(raw)==nil)
        for _,other in ipairs({1,17}) do
            raw=copy(Config)
            for _,i in ipairs({16,other}) do raw.products[i].roblox_product_id=99;raw.products[i].approved_robux_price=10 end
            assert(Rules.catalog(raw)==nil)
        end
    end)
    test("mock disabled offers preview without a real price or fabricated entitlement",function()
        local dto=Rules.preview(assert(Rules.catalog(Config)),boosts())
        assert(dto.label=="DEVELOPMENT ONLY - no real purchase" and dto.remainingTimeBasis=="last_durable")
        assert(#dto.offers==#Config.products)
        for _,p in ipairs(dto.offers) do
            assert(p.available==(p.benefit~="part_unlock") and p.robuxPrice==nil and p.productID==nil and p.label==dto.label)
            if p.benefit=="part_unlock" then assert(p.key=="part_"..p.catalogID and not p.onlineTime and not p.ownedPermanent) end
        end
        assert(dto.xp.remainingSeconds==1800 and dto.paper.remainingSeconds==900)
    end)
    test("permanent disables redundant resource offers while preserving dormant indicators and two cap",function()
        local b=boosts(); b.permanentXP=true
        local dto=Rules.preview(assert(Rules.catalog(Config)),b)
        assert(dto.xp.multiplier==2 and dto.paper.multiplier==2 and dto.xp.remainingSeconds==1800)
        for _,p in ipairs(dto.offers) do
            if p.benefit=="xp_seconds" or p.benefit=="permanent_xp" then assert(not p.available and p.reason=="permanent_owned")
            else assert(p.available==(p.benefit~="part_unlock")) end
        end
    end)
    test("nil and arbitrary empty tables do not impersonate generated JSON null",function()
        for _,field in ipairs({"roblox_product_id","approved_robux_price"}) do
            local c=copy(Config); c.products[1][field]=nil; assert(Rules.catalog(c)==nil)
            c=copy(Config); c.products[1][field]={}; assert(Rules.catalog(c)==nil)
        end
    end)
    test("unknown malformed duplicate keys and immutable changes fail closed",function()
        local changes={function(c) c.products[1].key="unknown" end,
            function(c) c.products[1].amount=901 end,function(c) c.products[1].kind="pass" end,
            function(c) c.products[1].benefit="paper_seconds" end,function(c) c.products[1].enabled="false" end,
            function(c) c.products[2]=copy(c.products[1]) end,function(c) c.products[1].extra=true end,
            function(c) c.products[16]=copy(c.products[1]) end,function(c) c.products[1]=false end,
            function(c) c.unknown=true end,function(c) c.multiplier_cap_per_resource=4 end}
        for _,change in ipairs(changes) do local c=copy(Config); change(c); assert(Rules.catalog(c)==nil) end
    end)
    test("bad partial enabled and duplicate platform mappings fail closed",function()
        for _,id in ipairs({0,-1,1.5,math.huge,0/0,"12",{}}) do
            local c=copy(Config); c.products[1].roblox_product_id=id; c.products[1].approved_robux_price=10
            assert(Rules.catalog(c)==nil)
        end
        local c=copy(Config); c.products[1].enabled=true; assert(Rules.catalog(c)==nil)
        c=copy(Config); c.products[1].roblox_product_id=12; assert(Rules.catalog(c)==nil)
        c=copy(Config)
        for i=1,2 do c.products[i].roblox_product_id=12; c.products[i].approved_robux_price=10 end
        assert(Rules.catalog(c)==nil)
    end)
    test("catalog detaches mutable configuration and freezes identities",function()
        local raw=copy(Config); local c=assert(Rules.catalog(raw)); raw.products[1].amount=1
        assert(c.offers[1].amount==900 and table.isfrozen(c) and table.isfrozen(c.offers[1]))
        assert(not pcall(function() c.offers[1].amount=1 end))
    end)
    test("typed semantic operations contain no XP for purchased Paper and no client CAS or amount path",function()
        local c=assert(Rules.catalog(Config))
        local paper=Rules.operation(c.byKey.paper_pack_3500,"mock-purchase:abc",7)
        assert(paper.kind=="purchasedPaper" and paper.wholePaper==3500 and paper.points==nil and paper.multipliers==nil)
        local duration=Rules.operation(c.byKey.xp_boost_300m,"mock-purchase:def",8)
        assert(duration.kind=="boostIntent" and duration.resource=="xp" and duration.seconds==18000)
        local pass=Rules.operation(c.byKey.permanent_2x_paper,"mock-purchase:ghi",9)
        assert(pass.action=="permanent" and pass.seconds==nil and table.isfrozen(pass))
    end)
    test("live DTO cannot initiate checkout or display fixture prices",function()
        local c=copy(Config); c.mode="live"; c.live_sales_authorized=true
        for i,p in ipairs(c.products) do p.roblox_product_id=100+i; p.approved_robux_price=10; p.enabled=true end
        local dto=Rules.preview(assert(Rules.catalog(c)),boosts())
        for _,p in ipairs(dto.offers) do assert(not p.available and p.robuxPrice==nil) end
    end)
    return result
end
return Spec
