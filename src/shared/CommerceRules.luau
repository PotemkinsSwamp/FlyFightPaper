-- Pure catalog and narrow display contract. No platform or persistence authority.
local Root = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper")
local JSON = require(Root.Generated.JSONTypes)
local Rules = {}
local MAX = 9007199254740991
local expected = {}
for _, resource in ipairs({"xp", "paper"}) do
    for _, minutes in ipairs({15, 30, 60, 180, 300}) do
        expected[resource .. "_boost_" .. minutes .. "m"] = {kind="developer_product", benefit=resource .. "_seconds", amount=minutes*60}
    end
    expected["permanent_2x_" .. resource] = {kind="pass", benefit="permanent_" .. resource, amount=2}
end
for _, amount in ipairs({1000, 3500, 10000}) do
    expected["paper_pack_" .. amount] = {kind="developer_product", benefit="paper_balance", amount=amount}
end
function Rules.positiveInteger(n)
    return type(n)=="number" and n==n and n>0 and n<=MAX and n%1==0
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
        if type(i)~="number" or i%1~=0 or i<1 or i>15 then return nil,"invalid_offer_array" end
        n+=1
    end
    if n~=15 then return nil,"offer_count" end
    local fields={key=true,kind=true,benefit=true,amount=true,roblox_product_id=true,approved_robux_price=true,enabled=true}
    for i=1,15 do
        local p=config.products[i]
        if type(p)~="table" then return nil,"malformed_offer" end
        for k in pairs(p) do if not fields[k] then return nil,"unknown_offer_field" end end
        local e=expected[p.key]
        if not e or p.kind~=e.kind or p.benefit~=e.benefit or p.amount~=e.amount or type(p.enabled)~="boolean" then
            return nil,"immutable_offer_mismatch"
        end
        if byKey[p.key] then return nil,"duplicate_offer" end
        -- Nil, empty tables and arbitrary generated maps are NOT the JSON null sentinel.
        local idNull, priceNull = p.roblox_product_id==JSON.Null, p.approved_robux_price==JSON.Null
        if (not idNull and not Rules.positiveInteger(p.roblox_product_id))
            or (not priceNull and not Rules.positiveInteger(p.approved_robux_price))
            or idNull~=priceNull or (p.enabled and idNull) then return nil,"invalid_mapping" end
        local offer=table.freeze({key=p.key,kind=p.kind,benefit=p.benefit,amount=p.amount,
            enabled=p.enabled,productID=not idNull and p.roblox_product_id or nil,
            approvedPrice=not priceNull and p.approved_robux_price or nil})
        if offer.productID then
            if byID[offer.productID] then return nil,"duplicate_mapping" end
            byID[offer.productID]=offer
        end
        byKey[p.key]=offer; ordered[i]=offer
    end
    return table.freeze({mode=config.mode,authorized=config.live_sales_authorized,
        byKey=table.freeze(byKey),byID=table.freeze(byID),offers=table.freeze(ordered)})
end
function Rules.resource(offer)
    if offer.benefit=="xp_seconds" or offer.benefit=="permanent_xp" then return "xp" end
    if offer.benefit=="paper_seconds" or offer.benefit=="permanent_paper" then return "paper" end
end
function Rules.owned(offer,boosts)
    local resource=Rules.resource(offer)
    return resource and boosts[resource=="xp" and "permanentXP" or "permanentPaper"]==true or false
end
function Rules.operation(offer,source,version)
    local op={sourceIdentity=source,expectedVersion=version}
    if offer.benefit=="paper_balance" then op.kind="purchasedPaper"; op.wholePaper=offer.amount
    else
        op.kind="boostIntent"; op.resource=Rules.resource(offer)
        op.action=offer.kind=="pass" and "permanent" or "duration"
        if op.action=="duration" then op.seconds=offer.amount end
    end
    return table.freeze(op)
end
function Rules.preview(catalog,boosts)
    local offers={}
    for i,p in ipairs(catalog.offers) do
        local owned=Rules.owned(p,boosts)
        offers[i]=table.freeze({key=p.key,kind=p.kind,benefit=p.benefit,amount=p.amount,
            label=catalog.mode=="mock" and "DEVELOPMENT ONLY - no real purchase" or "Live checkout unavailable",
            available=catalog.mode=="mock" and not owned,ownedPermanent=owned,
            reason=owned and "permanent_owned" or (catalog.mode~="mock" and "live_request_unavailable" or nil),
            onlineTime=p.benefit=="xp_seconds" or p.benefit=="paper_seconds"})
    end
    return table.freeze({mode=catalog.mode,remainingTimeBasis="last_durable",label=catalog.mode=="mock" and "DEVELOPMENT ONLY - no real purchase" or "Live checkout unavailable",
        offers=table.freeze(offers),xp=table.freeze({remainingSeconds=boosts.xpSeconds,permanent=boosts.permanentXP,
            multiplier=(boosts.permanentXP or boosts.xpSeconds>0) and 2 or 1}),
        paper=table.freeze({remainingSeconds=boosts.paperSeconds,permanent=boosts.permanentPaper,
            multiplier=(boosts.permanentPaper or boosts.paperSeconds>0) and 2 or 1})})
end
return table.freeze(Rules)
