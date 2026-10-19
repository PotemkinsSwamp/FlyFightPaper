-- Bounded JSON persistence contract. No load failure is interpreted as a new account.
local Economy = require(script.Parent.EconomyRules)
local EconomyConfig = require(script.Parent.Parent.Generated.Economy)
local Config = require(script.Parent.Parent.Generated.Server)
local Gameplay = require(script.Parent.Parent.Generated.Gameplay)
local Schema = { VERSION = 5, MAX_BYTES = Config.schema.max_bytes, MAX_ENTRIES = Config.schema.max_entries,
	MAX_DEPTH = Config.schema.max_depth, MAX_OPERATION_ID = Config.schema.max_id_bytes }
local function integer(n) return type(n) == "number" and n == n and n >= 0 and n <= Economy.MAX_SAFE_INTEGER and n % 1 == 0 end
Schema.integer = integer
function Schema.id(s) return type(s) == "string" and #s > 0 and #s <= Schema.MAX_OPERATION_ID and s:match("^[%w_%-:]+$") ~= nil end
function Schema.nonce(s) return type(s)=="string" and #s>0 and #s<=64 and s:match("^[%w_%-:]+$")~=nil end
local function freeze(v)
	if type(v) == "table" and not table.isfrozen(v) then for _, c in pairs(v) do freeze(c) end; table.freeze(v) end
	return v
end
Schema.freeze = freeze
-- Canonical identity encoding includes types, lengths, and every key/value, not a hash.
function Schema.copy(value)
	local seen, entries, bytes = {}, 0, 0
	local function visit(v, depth)
		local t = type(v)
		if t == "number" then assert(v == v and math.abs(v) <= Economy.MAX_SAFE_INTEGER, "invalid_number"); bytes += 24; return v
		elseif t == "string" then assert(#v <= 4096 and utf8.len(v)~=nil, "string_cap_or_utf8"); bytes += #v * 6 + 8; return v
		elseif t == "boolean" then bytes += 5; return v
		end
		assert(t == "table" and getmetatable(v) == nil, "invalid_value")
		assert(depth < Schema.MAX_DEPTH and not seen[v], "depth_or_cycle")
		bytes += 2
		seen[v] = true
		local out, numeric, strings, count, maximum = {}, false, false, 0, 0
		for k, c in pairs(v) do
			entries += 1; assert(entries <= Schema.MAX_ENTRIES, "entry_cap")
			assert(type(k) == "string" or (integer(k) and k >= 1), "invalid_key")
			if type(k) == "number" then numeric = true; maximum = math.max(maximum, k); bytes += 24 else strings = true; assert(#k <= 128 and utf8.len(k)~=nil, "key_cap_or_utf8"); bytes += #k * 6 + 16 end
			count += 1; out[k] = visit(c, depth + 1); assert(bytes <= Schema.MAX_BYTES, "byte_cap")
		end
		assert(not (numeric and strings) and (not numeric or maximum == count), "mixed_or_sparse_keys")
		seen[v] = nil; return out
	end
	local ok, out = pcall(visit, value, 0)
	if not ok then return nil, tostring(out) end
	return out
end
function Schema.canonical(value)
	local copy, err = Schema.copy(value); if not copy then return nil, err end
	local function encode(v)
		local kind = type(v)
		if kind == "string" then return "s" .. #v .. ":" .. v end
		if kind == "number" then return "n" .. string.format("%.17g", v) .. ";" end
		if kind == "boolean" then return v and "t" or "f" end
		local keys = {}; for k in pairs(v) do table.insert(keys, k) end
		table.sort(keys, function(a,b) return a < b end)
		local result = { "{" }; for _, k in ipairs(keys) do table.insert(result, encode(k)); table.insert(result, encode(v[k])) end
		table.insert(result, "}"); return table.concat(result)
	end
	return encode(copy)
end
local function exact(t, fields)
	assert(type(t) == "table", "missing_table")
	for k in pairs(t) do assert(fields[k], "unknown_field:" .. tostring(k)) end
	for k, required in pairs(fields) do if required == 1 then assert(t[k] ~= nil, "missing_field:" .. k) end end
end
local moneyFields = { "paperMilli", "earnedPaperMilli", "purchasedPaperMilli", "xpMilli" }
function Schema.economicView(p)
	local v = { ownership = assert(Schema.copy(p.ownership)) }
	for _, k in ipairs(moneyFields) do v[k] = p[k] end
	return freeze(v)
end
function Schema.mergeEconomic(p, v)
	for _, k in ipairs(moneyFields) do p[k] = v[k] end
	p.ownership = assert(Schema.copy(v.ownership))
end
function Schema.defaults(catalog)
	local paper, xp = EconomyConfig.initial_paper*1000, EconomyConfig.initial_total_xp*1000
	assert(integer(paper) and integer(xp),"invalid_initial_economy")
	local p = { schemaVersion = Schema.VERSION, version = 0, generation = 0, paperMilli = paper, earnedPaperMilli = 0,
		purchasedPaperMilli = 0, xpMilli = xp, prestige = 0, ownership = assert(Schema.copy(assert(Economy.starterOwnership(catalog)))),
		presets = {}, settings = { music = 1, sound = 1, sensitivity = 1, reducedShake = false, quality = "High", crosshairColor = "blue", crosshairSize = "Medium" },
		qualification = { count = 0, history = {} }, boosts = { paperSeconds = 0, xpSeconds = 0, permanentPaper = false, permanentXP = false },
		statistics = { matches = 0, wins = 0, eliminations = 0, deaths = 0 }, operationIds = {}, operationSessions = {}, receiptIds = {} }
	for i = 1, Gameplay.menus.saved_loadouts do p.presets[i] = { name = "Preset " .. i, loadout = catalog:starterLoadout() } end
	return p
end
function Schema.validate(record, catalog)
	local p, err = Schema.copy(record); if not p then return nil, err end
	local ok, message = pcall(function()
		exact(p, { schemaVersion=1, version=1, generation=1, lease=0, paperMilli=1, earnedPaperMilli=1, purchasedPaperMilli=1,
			xpMilli=1, prestige=1, ownership=1, presets=1, settings=1, qualification=1, boosts=1, statistics=1, operationIds=1, operationSessions=1, receiptIds=1, extensions=0, refolds=0 })
		assert(p.schemaVersion == Schema.VERSION, "unsupported_schema")
		assert(integer(p.version) and integer(p.generation), "invalid_version")
		assert(integer(p.prestige) and p.prestige<=EconomyConfig.prestige_max, "invalid_prestige")
		for _, k in ipairs(moneyFields) do assert(integer(p[k]), "invalid_money") end
		for id, owned in pairs(p.ownership) do assert(type(id)=="string" and catalog:get(id) and owned==true, "invalid_ownership") end
		local level = assert(Economy.levelForXP(p.xpMilli))
		assert(#p.presets == Gameplay.menus.saved_loadouts, "five_presets_required")
		for _, preset in ipairs(p.presets) do
			exact(preset, {name=1,loadout=1}); assert(type(preset.name)=="string" and #preset.name<=48 and #preset.name>0 and utf8.len(preset.name)~=nil and not preset.name:find("%c"), "invalid_preset_name")
			assert(catalog:validateLoadout(preset.loadout, p.ownership, level))
		end
		exact(p.settings, {music=1,sound=1,sensitivity=1,reducedShake=1,quality=1,crosshairColor=1,crosshairSize=1})
		for _, k in ipairs({"music","sound"}) do assert(type(p.settings[k])=="number" and p.settings[k]>=0 and p.settings[k]<=1, "invalid_volume") end
		assert(type(p.settings.sensitivity)=="number" and p.settings.sensitivity>=0.2 and p.settings.sensitivity<=3 and type(p.settings.reducedShake)=="boolean", "invalid_settings")
		assert(p.settings.quality=="Low" or p.settings.quality=="Medium" or p.settings.quality=="High", "invalid_quality")
		assert(p.settings.crosshairColor=="green" or p.settings.crosshairColor=="red" or p.settings.crosshairColor=="blue" or p.settings.crosshairColor=="yellow" or p.settings.crosshairColor=="purple" or p.settings.crosshairColor=="white", "invalid_crosshair_color")
		assert(p.settings.crosshairSize=="Small" or p.settings.crosshairSize=="Medium" or p.settings.crosshairSize=="Large", "invalid_crosshair_size")
		exact(p.boosts, {paperSeconds=1,xpSeconds=1,permanentPaper=1,permanentXP=1})
		for _, k in ipairs({"paperSeconds","xpSeconds"}) do assert(type(p.boosts[k])=="number" and p.boosts[k]>=0, "invalid_seconds") end
		assert(type(p.boosts.permanentPaper)=="boolean" and type(p.boosts.permanentXP)=="boolean", "invalid_flags")
		exact(p.qualification, {count=1,history=1}); assert(integer(p.qualification.count) and p.qualification.count<=Gameplay.bots.rookie_qualifying_matches, "qualification_cap")
		local historyCount=0; for id, yes in pairs(p.qualification.history) do assert(Schema.id(id) and yes==true, "invalid_history"); historyCount+=1 end
		assert(historyCount==p.qualification.count, "qualification_count_mismatch")
		exact(p.statistics, {matches=1,wins=1,eliminations=1,deaths=1}); for _, n in pairs(p.statistics) do assert(integer(n), "invalid_statistic") end
		if p.lease then exact(p.lease,{nonce=1,generation=1,expires=1}); assert(Schema.nonce(p.lease.nonce) and integer(p.lease.generation) and p.lease.generation>0 and p.lease.generation==p.generation and type(p.lease.expires)=="number" and p.lease.expires>=0, "invalid_lease") end
		assert(#p.operationSessions<=Config.profiles.session_id_history,"operation_session_cap")
		local sessions={}
		for _, token in ipairs(p.operationSessions) do
			assert(Schema.nonce(token) and not sessions[token],"invalid_operation_session")
			sessions[token]=true
			assert(integer(p.operationIds[token]),"invalid_operation_sequence")
		end
		for token in pairs(p.operationIds) do assert(sessions[token],"unknown_operation_session") end
		local count=0
		for receipt, granted in pairs(p.receiptIds) do
			count+=1;assert(Schema.id(receipt) and granted==true,"invalid_receipt")
		end
		assert(count<=Config.schema.max_receipts,"receipt_cap")
		count=0
		for id,intent in pairs(p.refolds or {}) do
			count+=1; assert(Schema.id(id),"invalid_refold_id")
			exact(intent,{state=1,costMilli=1,fence=1,loadout=1})
			assert(intent.state=="reserved" or intent.state=="delivered" or intent.state=="applied" or intent.state=="cancelled","invalid_refold_state")
			assert(integer(intent.costMilli) and intent.costMilli==require(script.Parent.Parent.Generated.Gameplay).service.full_refold_paper*1000,"invalid_refold_cost")
			exact(intent.fence,{nonce=1,generation=1,actorId=1,lifeId=1,matchId=1,participationId=1,padId=1,sessionGeneration=1})
			assert(Schema.nonce(intent.fence.nonce) and integer(intent.fence.generation) and integer(intent.fence.sessionGeneration),"invalid_refold_fence")
			for _,key in ipairs({"actorId","lifeId","matchId","participationId","padId"}) do assert(type(intent.fence[key])=="string" and #intent.fence[key]>0 and #intent.fence[key]<=256,"invalid_refold_fence") end
			assert(catalog:validateLoadout(intent.loadout,p.ownership,level))
		end
		assert(count<=Config.profiles.max_refolds,"refold_cap")
	end)
	if not ok then return nil, tostring(message) end
	return p
end
-- Older profiles retain their balances, owned parts and interrupted refolds.
function Schema.migrate(record, catalog)
	local p, err = Schema.copy(record); if not p then return nil, err end
	if p.schemaVersion==1 or p.schemaVersion==2 then
		if p.schemaVersion==1 and p.streams~=nil then return nil,"ambiguous_v1_streams" end
		-- Never discard an unresolved legacy write. This store has a separate namespace.
		if type(p.journal)~="table" or next(p.journal)~=nil then return nil,"legacy_operations_need_recovery" end
		p.journal=nil;p.streams=nil;p.lease=nil
		p.schemaVersion=3;p.operationIds={};p.operationSessions={};p.receiptIds={}
	end
	if p.schemaVersion==3 then
		if type(p.settings)~="table" then return nil,"missing_table" end
		p.settings.crosshairColor="blue";p.settings.crosshairSize="Medium"
		p.schemaVersion=4
	end
	if p.schemaVersion==4 then
		p.prestige=0
		p.schemaVersion=5
	end
	-- Loadout tuning can invalidate an otherwise readable save. Keep its account and preset names intact.
	local level=Economy.levelForXP(p.xpMilli)
	local function recover(entry)
		if type(entry)~="table" then return end
		local _,reason=catalog:validateLoadout(entry.loadout,p.ownership,level)
		if reason=="weapon capacity exceeds body capacity" or reason=="two weapon types per plane" then entry.loadout=catalog:starterLoadout() end
	end
	if type(p.presets)=="table" then for _,preset in ipairs(p.presets) do recover(preset) end end
	-- Pending refolds still pass validation so the normal join recovery can refund reserved Paper.
	if type(p.refolds)=="table" then for _,intent in pairs(p.refolds) do recover(intent) end end
	return Schema.validate(p, catalog)
end
return table.freeze(Schema)
