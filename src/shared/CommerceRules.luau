-- Pure catalog and narrow display contract. No platform or persistence authority.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local JSON = require(Root.Generated.JSONTypes)
local EconomyConfig = require(Root.Generated.Economy)
local Looks = require(script.Parent.LooksRules)
local Rules = {}
local MAX = 9007199254740991
Rules.MATCH_DOUBLE_STEPS = table.freeze({10,15,25,35,49,69,99,149,199,249,299})
local expected = {}
for _, resource in ipairs({"xp", "paper"}) do
    for _, minutes in ipairs({15, 30, 60, 180, 300}) do
        expected[resource .. "_boost_" .. minutes .. "m"] = {kind="developer_product", benefit=resource .. "_seconds", amount=minutes*60}
    end
    expected["permanent_2x_" .. resource] = {kind="pass", benefit="permanent_" .. resource, amount=2}
end
for _, amount in ipairs({1500, 5000, 7500, 15000, 40000}) do -- docs/plan/SHOP-MONEY-PLAN.md
    expected["paper_pack_" .. amount] = {kind="developer_product", benefit="paper_balance", amount=amount}
end
expected.starter_pack = {kind="developer_product", benefit="starter_pack"} -- Bundle amounts live in economy.json.
expected.paper_jar = {kind="developer_product", benefit="paper_jar"}
local giftBases={}
for key,offer in pairs(expected) do
    if offer.benefit=="paper_balance" or offer.benefit=="xp_seconds" or offer.benefit=="paper_seconds" then giftBases["gift_"..key]=key end
end
for key in pairs(giftBases) do expected[key]={kind="developer_product",benefit="gift"} end
function Rules.giftBase(key) return type(key)=="string" and giftBases[key] or nil end
function Rules.giftable(key) return type(key)=="string" and giftBases["gift_"..key]~=nil or false end
function Rules.giftGrant(key)
    if not Rules.giftable(key) then return nil end
    local offer=expected[key]
    if offer.benefit=="paper_balance" then return {kind="purchasedPaper",wholePaper=offer.amount} end
    return {kind="boostIntent",resource=offer.benefit=="xp_seconds" and "xp" or "paper",action="duration",seconds=offer.amount}
end
for _, step in ipairs(Rules.MATCH_DOUBLE_STEPS) do
    expected["match_double_"..step] = {kind="developer_product", benefit="match_double", amount=step}
end
function Rules.paperPackAmount(key)
    local offer=type(key)=="string" and expected[key]
    return offer and offer.benefit=="paper_balance" and offer.amount or nil
end
function Rules.isMatchDoubleKey(key)
    local offer=type(key)=="string" and expected[key]
    return offer and offer.benefit=="match_double" or false
end
function Rules.starterPackEnds(profile,now)
    local pack=profile.starterPack
    if pack.offeredAt==0 or pack.bought or next(profile.receiptIds)~=nil
        or profile.boosts.permanentXP or profile.boosts.permanentPaper then return 0 end
    local ends=pack.offeredAt+EconomyConfig.starter_pack.offer_seconds
    return now<ends and ends or 0
end
function Rules.positiveInteger(n)
    return type(n)=="number" and n==n and n>0 and n<=MAX and n%1==0
end
function Rules.matchDoublePrice(paper)
    if not Rules.positiveInteger(paper) or paper<75 then return nil end
    local target=paper/10
    local price=Rules.MATCH_DOUBLE_STEPS[1]
    for _,step in ipairs(Rules.MATCH_DOUBLE_STEPS) do
        if math.abs(step-target)<math.abs(price-target) then price=step end
    end
    return price,math.round(2*paper/15)
end
function Rules.catalog(config)
    if type(config)~="table" or (config.mode~="mock" and config.mode~="live")
        or config.schema_version~=1 or type(config.live_sales_authorized)~="boolean"
        or config.allow_real_spend_tests~=false or config.offline_countdown~=false
        or config.loaded_online_menu_countdown~=true or config.multiplier_cap_per_resource~=2
        or config.permanent_hides_temporary_same_resource~=true or type(config.products)~="table"
        or type(config.mock_ui_label)~="string" or type(config.paper_pack_amounts_status)~="string"
        or type(config.source_of_live_display_price)~="string" then
        return nil,"invalid_commerce_config"
    end
    local allowedConfig={schema_version=true,mode=true,live_sales_authorized=true,allow_real_spend_tests=true,
        offline_countdown=true,loaded_online_menu_countdown=true,multiplier_cap_per_resource=true,
        permanent_hides_temporary_same_resource=true,products=true,paper_pack_amounts_status=true,
        mock_ui_label=true,source_of_live_display_price=true}
    for k in pairs(config) do if not allowedConfig[k] then return nil,"unknown_config_field" end end
    local byKey, byID, ordered, n = {}, {}, {}, 0
    for i in pairs(config.products) do
        if type(i)~="number" or i%1~=0 or i<1 then return nil,"invalid_offer_array" end
        n+=1
    end
    if n<45 then return nil,"offer_count" end
    local fields={key=true,kind=true,benefit=true,amount=true,roblox_product_id=true,approved_robux_price=true,enabled=true}
    local partFields={key=true,kind=true,benefit=true,catalog_id=true,roblox_product_id=true,approved_robux_price=true,enabled=true}
    local lookFields={key=true,kind=true,benefit=true,look_id=true,roblox_product_id=true,approved_robux_price=true,enabled=true}
    for i=1,n do
        local p=config.products[i]
        if type(p)~="table" then return nil,"malformed_offer" end
        local part=p.benefit=="part_unlock"
        local look=p.benefit=="look_unlock"
        local allowedFields=part and partFields or look and lookFields or fields
        for k in pairs(p) do if not allowedFields[k] then return nil,"unknown_offer_field" end end
        if part then
            if p.kind~="developer_product" or type(p.catalog_id)~="string" or #p.catalog_id==0
                or p.key~="part_"..p.catalog_id or type(p.enabled)~="boolean" then return nil,"invalid_part_offer" end
        elseif look then
            local item=Looks.item(p.look_id)
            if p.kind~="developer_product" or not item or not item.sold
                or p.key~="look_"..p.look_id or type(p.enabled)~="boolean" then return nil,"invalid_look_offer" end
        else
            local e=expected[p.key]
            if not e or p.kind~=e.kind or p.benefit~=e.benefit or p.amount~=e.amount or type(p.enabled)~="boolean" then
                return nil,"immutable_offer_mismatch"
            end
        end
        if byKey[p.key] then return nil,"duplicate_offer" end
        -- Nil, empty tables and arbitrary generated maps are NOT the JSON null sentinel.
        local idNull, priceNull = p.roblox_product_id==JSON.Null, p.approved_robux_price==JSON.Null
        if (not idNull and not Rules.positiveInteger(p.roblox_product_id))
            or (not priceNull and not Rules.positiveInteger(p.approved_robux_price))
            or (idNull~=priceNull and not (look and idNull and not priceNull and p.enabled==false))
            or (p.enabled and idNull) then return nil,"invalid_mapping" end
        local offer=table.freeze({key=p.key,kind=p.kind,benefit=p.benefit,amount=p.amount,catalogID=p.catalog_id,
            lookID=p.look_id,
            enabled=p.enabled,productID=not idNull and p.roblox_product_id or nil,
            approvedPrice=not priceNull and p.approved_robux_price or nil})
        if offer.productID then
            if byID[offer.productID] then return nil,"duplicate_mapping" end
            byID[offer.productID]=offer
        end
        byKey[p.key]=offer; ordered[i]=offer
    end
    for key in pairs(expected) do if not byKey[key] then return nil,"offer_count" end end
    return table.freeze({mode=config.mode,authorized=config.live_sales_authorized,
        byKey=table.freeze(byKey),byID=table.freeze(byID),offers=table.freeze(ordered)})
end
function Rules.resource(offer)
    if offer.benefit=="xp_seconds" or offer.benefit=="permanent_xp" then return "xp" end
    if offer.benefit=="paper_seconds" or offer.benefit=="permanent_paper" then return "paper" end
end
function Rules.owned(offer,boosts,profile)
    if offer.benefit=="look_unlock" then return Looks.owns(profile,offer.lookID) end
    if offer.benefit=="part_unlock" then return type(profile)=="table" and type(profile.ownership)=="table" and profile.ownership[offer.catalogID]==true or false end
    local resource=Rules.resource(offer)
    return resource and boosts[resource=="xp" and "permanentXP" or "permanentPaper"]==true or false
end
function Rules.operation(offer,source,version)
    if Rules.giftBase(offer.key) then return table.freeze({kind="giftSent"}) end
    if offer.benefit=="part_unlock" then return table.freeze({kind="partUnlock",catalogID=offer.catalogID}) end
    if offer.benefit=="look_unlock" then return table.freeze({kind="lookUnlock",lookID=offer.lookID}) end
    if offer.benefit=="starter_pack" then return table.freeze({kind="starterPack"}) end
    if offer.benefit=="paper_jar" then return table.freeze({kind="paperJar"}) end
    if offer.benefit=="match_double" then
        return table.freeze({kind="matchDouble",key=offer.key})
    end
    local op={sourceIdentity=source,expectedVersion=version}
    if offer.benefit=="paper_balance" then op.kind="purchasedPaper"; op.wholePaper=offer.amount; op.packKey=offer.key
    else
        op.kind="boostIntent"; op.resource=Rules.resource(offer)
        op.action=offer.kind=="pass" and "permanent" or "duration"
        if op.action=="duration" then op.seconds=offer.amount end
    end
    return table.freeze(op)
end
function Rules.preview(catalog,boosts,profile)
    local offers={}
    for i,p in ipairs(catalog.offers) do
        local owned=Rules.owned(p,boosts,profile)
        local unlock=p.benefit=="part_unlock" or p.benefit=="look_unlock"
        offers[i]=table.freeze({key=p.key,kind=p.kind,benefit=p.benefit,amount=p.amount,catalogID=p.catalogID,
            lookID=p.lookID,owned=owned,
            label=catalog.mode=="mock" and "DEVELOPMENT ONLY - no real purchase" or "Live checkout unavailable",
            available=catalog.mode=="mock" and not unlock and not owned,ownedPermanent=owned and not unlock,
            reason=owned and (unlock and "owned" or "permanent_owned") or (catalog.mode~="mock" and "live_request_unavailable" or nil),
            onlineTime=p.benefit=="xp_seconds" or p.benefit=="paper_seconds"})
    end
    return table.freeze({mode=catalog.mode,remainingTimeBasis="last_durable",label=catalog.mode=="mock" and "DEVELOPMENT ONLY - no real purchase" or "Live checkout unavailable",
        offers=table.freeze(offers),xp=table.freeze({remainingSeconds=boosts.xpSeconds,permanent=boosts.permanentXP,
            multiplier=(boosts.permanentXP or boosts.xpSeconds>0) and 2 or 1}),
        paper=table.freeze({remainingSeconds=boosts.paperSeconds,permanent=boosts.permanentPaper,
            multiplier=(boosts.permanentPaper or boosts.paperSeconds>0) and 2 or 1})})
end
return table.freeze(Rules)
