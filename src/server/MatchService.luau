local Shared = game:GetService("ReplicatedStorage"):WaitForChild("FlyFightPaper").Shared
local Rules = require(Shared.MatchRules)
local MathUtil = require(Shared.MathUtil)
local Limits = require(Shared.Parent.Generated.Server).match_limits
local Match = {}
Match.__index = Match
-- Backpressure limits, not gameplay tuning. Never evict unacknowledged value.
Match.MAX_RETAINED_ROUNDS = Limits.retained_rounds
Match.MAX_PARTICIPANTS = Limits.participants
Match.MAX_BINDINGS = Limits.bindings
Match.MAX_EVENTS = Limits.events
Match.MAX_ACTIVITY_INTERVALS = Limits.activity_intervals
local function id(value) return type(value) == "string" and #value > 0 and #value <= 160 end
local function binding(identity)
    return #identity.actorId .. ":" .. identity.actorId .. #identity.participationId .. ":"
        .. identity.participationId .. #identity.lifeId .. ":" .. identity.lifeId
end
local function freeze(value)
    if type(value) == "table" and not table.isfrozen(value) then
        for _, child in pairs(value) do freeze(child) end
        table.freeze(value)
    end
    return value
end
local function detached(value) return freeze(MathUtil.copy(value)) end
function Match.new(context)
    assert(context.clock and context.config and context.economy and id(context.sessionId)
        and #context.sessionId <= 96, "match context missing or session namespace too long")
    assert(type(context.combatDrainState) == "function", "trusted atomic combat drain state required")
    assert(Rules.finite(context.seed or 0) and (context.seed or 0) % 1 == 0, "invalid seed")
    assert(Rules.finite(context.economy.damage_engagement_min_actual_damage)
        and context.economy.damage_engagement_min_actual_damage > 0, "invalid damage engagement threshold")
    assert(Rules.finite(context.economy.damage_engagement_idle_seconds)
        and context.economy.damage_engagement_idle_seconds > 0, "invalid damage engagement idle time")
    local now = context.clock:now()
    assert(Rules.finite(now) and now >= 0, "invalid clock")
    return setmetatable({ context = context, seed = context.seed or 0, serial = 0, now = now,
        phase = "READY", round = nil, retained = {}, retainedCount = 0, lastPlayed = {},
        diagnostics = { ignoredEvents = 0 } }, Match)
end
function Match:_safeNow()
    local drain = self.context.combatDrainState()
    assert(type(drain) == "table" and type(drain.blocked) == "boolean", "invalid combat drain state")
    local wall = self:_clock()
    local watermark = drain.through
    self.deliveryBlocked = drain.blocked
    assert(Rules.finite(watermark) and watermark >= (self.lastWatermark or 0) and watermark <= wall,
        "combat drain watermark must be monotonic and no later than clock")
    self.lastWatermark = watermark
    return math.max(self.now, watermark)
end
function Match:_clock()
    local now = self.context.clock:now()
    assert(Rules.finite(now) and now >= self.now, "match clock must be monotonic")
    return now
end
function Match:startRound(mode)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    if self.phase ~= "READY" then return false, "not_ready" end
    mode = mode or self.nextMode or "FFA"
    if not Rules.mode(mode) then return false, "invalid_mode" end
    if self.retainedCount >= Match.MAX_RETAINED_ROUNDS then return false, "cleanup_required" end
    self.serial += 1
    local matchId = "match:" .. self.context.sessionId .. ":" .. self.serial
    local r = { id = matchId, mode = mode, startedAt = self.now, zoneSeed = self.seed + self.serial,
        endsAt = self.now + self.context.config.rounds.duration_seconds, participants = {}, bindings = {}, lifeBounds = {},
        actorKeys = {}, participantsCount = 0, bindingsCount = 0, events = {}, eventCount = 0,
        lastSequence = 0, lastEventAt = self.now, teams = { ["team:1"] = 0, ["team:2"] = 0 },
        votes = {}, earnings = {}, damageEngagements = {}, firstFoldAwarded = false, ended = false, acknowledged = false }
    self.round, self.phase, self.nextMode = r, "ACTIVE", nil
    self.retained[matchId], self.retainedCount = r, self.retainedCount + 1
    self.lastPlayed[mode] = self.serial
    return true, matchId
end
function Match:_earned(p, points, kind, sourceId, at, identity)
    if points <= 0 then return end
    table.insert(self.round.earnings, detached({ factId = self.round.id .. ":earned:" .. sourceId .. ":" .. p.key,
        matchId = self.round.id, participantKey = p.key, actorId = identity and identity.actorId or p.actorId,
        lifeId = identity and identity.lifeId or p.lifeId,
        participationId = identity and identity.participationId or p.participationId, userId = p.userId,
        controllerType = p.controllerType, mockOnly = p.mockOnly, kind = kind, points = points, at = at }))
end
function Match:_qualify(p)
    local r, bots = self.round, self.context.config.bots
    if p.controllerType ~= "human" or p.qualified then return end
    if Rules.qualified(p, bots.qualification_active_seconds, bots.qualification_combat_or_objective_events) then
        p.qualified = true

    end
end
function Match:_team()
    local counts = { ["team:1"] = 0, ["team:2"] = 0 }
    for _, p in pairs(self.round.participants) do if p.present and p.teamId then counts[p.teamId] += 1 end end
    if counts["team:1"] == counts["team:2"] then
        return Rules.seedOrder(self.seed + self.serial, "team") % 2 == 0 and "team:1" or "team:2"
    end
    return counts["team:1"] < counts["team:2"] and "team:1" or "team:2"
end
-- Trusted parent only. key is persistent human identity, NOT ActorService participationId.
-- Bot keys must be distinct and never become human keys. No safe bot replacement is performed here.
function Match:join(options)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local r = self.round
    if self.phase ~= "ACTIVE" or not r then return false, "not_active" end
    if type(options) ~= "table" or not id(options.key) or not id(options.actorId)
        or (options.controllerType ~= "human" and options.controllerType ~= "bot") then return false, "invalid_identity" end
    if options.displayName ~= nil and (type(options.displayName) ~= "string" or #options.displayName > 48) then return false, "invalid_display_name" end
    local studioMock = self.context.allowStudioTestUsers == true and game:GetService("RunService"):IsStudio()
        and Rules.finite(options.userId) and options.userId >= -10000 and options.userId <= 0 and options.userId % 1 == 0
    if options.controllerType == "human" and (not Rules.finite(options.userId) or options.userId % 1 ~= 0
        or options.userId <= 0 and not studioMock)
        or options.controllerType == "bot" and options.userId ~= nil then return false, "invalid_account" end
    local prior = options.priorQualifyingMatches or 0
    if not Rules.finite(prior) or prior < 0 or prior % 1 ~= 0 then return false, "invalid_qualification_baseline" end
    local p, count = r.participants[options.key], 0
    for _, other in pairs(r.participants) do
        if other.present then count += 1 end
        if options.controllerType == "human" and other.userId == options.userId and other.key ~= options.key then
            return false, "account_key_changed"
        end
    end
    if p and (p.controllerType ~= options.controllerType or p.userId ~= options.userId) then return false, "key_identity_changed" end
    if p and p.present then return false, "already_present" end
    if count >= self.context.config.world.maximum_actors then return false, "roster_full" end
    if r.actorKeys[options.actorId] and r.actorKeys[options.actorId] ~= options.key then return false, "actor_already_bound" end
    if not p then
        if r.participantsCount >= Match.MAX_PARTICIPANTS then return false, "history_full" end
        p = { key = options.key, userId = options.userId, controllerType = options.controllerType, mockOnly = studioMock,
            displayName = options.displayName or "Pilot",
            priorQualifyingMatches = prior, kills = 0, assists = 0, deaths = 0, streak = 0, bestStreak = 0,
            damage = 0, contribution = 0, propPoints = 0, targetPoints = 0,
            objectiveSeconds = 0, objectiveEvents = 0, zoneEvents = 0,
            activeSeconds = 0, qualifyingEvents = 0, qualified = false, forfeited = false,
            eligibleIntervals = {}, activityIntervals = {},
            teamId = r.mode ~= "FFA" and self:_team() or nil }
        r.participants[options.key], r.participantsCount = p, r.participantsCount + 1
    end
    p.actorId, p.present, p.connected, p.sample, p.activityUntil = options.actorId, true, true, nil, self.now
    r.actorKeys[options.actorId] = p.key
    return true, detached({ matchId = r.id, participantKey = p.key, teamId = p.teamId })
end
-- Maps immutable damage identities, including prior actors/lives, back to retained participant history.
-- Composition-only synchronous reservation. Validation runs on a private admission draft,
-- never on the real participant. The integrator holds exclusive nonyielding ownership
-- between reserve and commit/rollback; arbitrary external callbacks are not transactional.
function Match:lifeStarted(facts)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local r = self.round
    if self.phase ~= "ACTIVE" or type(facts) ~= "table" or facts.matchId ~= r.id then return false, "wrong_match" end
    local p = r.participants[r.actorKeys[facts.actorId]]
    if not p or not p.present or p.actorId ~= facts.actorId or not id(facts.lifeId) or not id(facts.participationId) then return false, "unknown_identity" end
    local bindingKey = binding(facts)
    if r.bindings[bindingKey] then return true end
    if r.bindingsCount >= Match.MAX_BINDINGS then return false, "bindings_full" end
    r.bindings[bindingKey], r.bindingsCount = p.key, r.bindingsCount + 1
    r.lifeBounds[bindingKey] = { startedAt = self.now }
    if p.lifeId ~= facts.lifeId then
        self:_stopActivity(p)
        p.streak, p.activityUntil, p.sample = 0, self.now, nil
    end
    p.lifeId, p.participationId = facts.lifeId, facts.participationId
    return true
end
function Match:_identity(identity)
    local r = self.round
    if type(identity) ~= "table" or identity.matchId ~= r.id or not id(identity.actorId)
        or not id(identity.participationId) or not id(identity.lifeId) then return nil end
    local key = r.bindings[binding(identity)]
    local p = key and r.participants[key]
    if p and p.teamId == identity.teamId then return p end
    return nil
end
-- Refold is a SAME-life delivery, including a legal loadout change. It never resets streak.
function Match:_hookIdentity(facts)
    local r = self.round
    if not r or type(facts) ~= "table" or facts.matchId ~= r.id or not id(facts.actorId)
        or not id(facts.participationId) or not id(facts.lifeId) then return nil end
    return r.participants[r.bindings[binding(facts)]]
end
function Match:_stopActivity(p)
    if p.lifeId then
        local key = binding({actorId=p.actorId,participationId=p.participationId,lifeId=p.lifeId})
        local bounds = self.round.lifeBounds[key]
        if bounds then bounds.endedAt = self.now end
    end
    for i = #p.activityIntervals, 1, -1 do
        local span = p.activityIntervals[i]
        span[2] = math.min(span[2], self.now)
        if span[2] <= span[1] then table.remove(p.activityIntervals, i) end
    end
end
-- Non-crediting ActorService hook. DamageService lifeEnded must be delivered separately.
function Match:lifeEnded(facts)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local p = self:_hookIdentity(facts)
    if not p then return false, "unknown_identity" end
    if p.lifeId == facts.lifeId then
        self:_stopActivity(p)
        p.streak, p.sample, p.activityUntil = 0, nil, self.now
    end
    return true
end
function Match:_depart(key)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    if self.phase == "ENDING" then return false, "awaiting_results" end
    local r = self.round
    local p = r and r.participants[key]
    if not p then return false, "unknown_participant" end
    self:_stopActivity(p)
    p.present, p.connected, p.forfeited, p.streak, p.sample = false, false, true, 0, nil
    p.activityUntil = self.now
    r.votes[key] = nil
    return true
end
function Match:withdraw(key) return self:_depart(key) end
function Match:disconnect(key) return self:_depart(key) end
-- Parent samples authoritative state at transitions and BEFORE advancing simulation time.
-- Samples are held piecewise constant; tick never guesses historical positions from a current pose.
function Match:observe(key, sample)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local p = self.round and self.round.participants[key]
    if self.phase ~= "ACTIVE" or not p or not p.present or not p.lifeId then return false, "not_active" end
    if type(sample) ~= "table" or type(sample.eligible) ~= "boolean" or type(sample.protected) ~= "boolean"
        or type(sample.state) ~= "string" then return false, "invalid_sample" end
    p.sample = MathUtil.copy(sample)
    return true
end
-- Validated, materially changed aim/boost/control action, not repeated packets or menu toggles.
function Match:controlActivity(key)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local p = self.round and self.round.participants[key]
    if self.phase ~= "ACTIVE" or not p or not p.present or not Rules.activeEligible(p.sample)
        or p.sample.overlay == true then return false end
    self:_activity(p, self.now)
    return true
end
local function interval(list, first, last)
    if last <= first then return end
    table.insert(list, { first, last })
    table.sort(list, function(a, b) return a[1] < b[1] end)
    local merged = {}
    for _, span in ipairs(list) do
        local previous = merged[#merged]
        if previous and previous[2] >= span[1] then previous[2] = math.max(previous[2], span[2])
        else table.insert(merged, span) end
    end
    assert(#merged <= Match.MAX_ACTIVITY_INTERVALS, "activity history full; parent must stop dispatch")
    table.clear(list)
    for _, span in ipairs(merged) do table.insert(list, span) end
end
function Match:_activeSeconds(p, horizon)
    local i, j, seconds = 1, 1, 0
    local cutoff = self.round.cutoffAt or horizon or self.now
    while i <= #p.eligibleIntervals and j <= #p.activityIntervals do
        local a, b = p.eligibleIntervals[i], p.activityIntervals[j]
        seconds += math.max(0, math.min(a[2], b[2], cutoff) - math.max(a[1], b[1]))
        if a[2] <= b[2] then i += 1 else j += 1 end
    end
    p.activeSeconds = seconds
end
function Match:_activity(p, at, identity)
    -- Retained eligible intervals make delayed authoritative activity count only where the
    -- participant was actually eligible, even after withdrawal. No retroactive menu credit.
    identity = identity or {actorId=p.actorId,participationId=p.participationId,lifeId=p.lifeId}
    local bounds = self.round.lifeBounds[binding(identity)]
    local last = math.min(at + Rules.ACTIVITY_WINDOW_SECONDS, bounds and bounds.endedAt or math.huge)
    interval(p.activityIntervals, at, last)
    p.activityUntil = math.max(p.activityUntil, last)
    self:_activeSeconds(p)
end
-- One directed engagement per immutable pair of life bindings.
function Match:_damageEngagement(event)
    local r, e = self.round, self.context.economy
    local attackerKey, victimKey = binding(event.attacker), binding(event.victim)
    local pair = #attackerKey .. ":" .. attackerKey .. victimKey
    local engagement = r.damageEngagements[pair]
    if not engagement or event.at - engagement.lastHitAt >= e.damage_engagement_idle_seconds then
        engagement = { damage = 0, lastHitAt = event.at, qualified = false }
        r.damageEngagements[pair] = engagement
    end
    engagement.lastHitAt = event.at
    -- Saturate after reaching the threshold. Held fire refreshes the gap without
    -- adding another qualification or growing a damage accumulator indefinitely.
    engagement.damage = math.min(e.damage_engagement_min_actual_damage, engagement.damage + event.amount)
    if not engagement.qualified and engagement.damage >= e.damage_engagement_min_actual_damage then
        engagement.qualified = true
        return true
    end
    return false
end
-- Sole combat sink: detached, trusted DamageService facts. Never connect this method to a RemoteEvent.
function Match:consumeCombat(event)
    local r = self.round
    if type(event) ~= "table" or not id(event.eventId) then return false, "invalid_event" end
    if not r then return true, "retired_match" end
    if not event.victim or event.victim.matchId ~= r.id then return true, "foreign_or_retired_match" end
    if r.events[event.eventId] then return true, "duplicate" end
    if not Rules.finite(event.serverSequence) or event.serverSequence < 1 or event.serverSequence % 1 ~= 0
        or not Rules.finite(event.at) or event.at < r.startedAt or event.at > self:_clock() then return false, "invalid_order" end
    if event.serverSequence <= r.lastSequence then return true, "sequence_replay" end
    if event.at < r.lastEventAt then return false, "out_of_order" end
    if event.kind ~= "weaponDamage" and event.kind ~= "lifeEnded" then return false, "unsupported_event" end
    if r.eventCount >= Match.MAX_EVENTS then return false, "event_history_full" end
    local victim = self:_identity(event.victim)
    local attacker = event.kind == "weaponDamage" and self:_identity(event.attacker) or nil
    local killer = event.killer and self:_identity(event.killer) or nil
    if not victim or event.kind == "weaponDamage" and (not attacker or attacker == victim
        or attacker.teamId ~= nil and attacker.teamId == victim.teamId or not Rules.finite(event.amount) or event.amount <= 0)
        or event.killer and not killer then return false, "unbound_identity" end
    if killer and (killer == victim or killer.teamId ~= nil and killer.teamId == victim.teamId) then return false, "friendly_credit" end
    if event.kind == "weaponDamage" then
        for _, identity in ipairs({ event.attacker, event.victim }) do
            local bounds = r.lifeBounds[binding(identity)]
            if not bounds or event.at < bounds.startedAt or bounds.endedAt and event.at > bounds.endedAt
                or bounds.combatEnded then return false, "outside_damage_life:"..identity.actorId..":"..identity.lifeId end
        end
    end
    local assists, assistIdentities = {}, {}
    if event.assists ~= nil and type(event.assists) ~= "table" then return false, "invalid_assists" end
    for _, identity in ipairs(event.assists or {}) do
        local p = self:_identity(identity)
        if not p then return false, "unbound_assist" end
        if not Rules.finite(identity.share) or identity.share < 0 or identity.share > 1 then return false, "invalid_assist_share" end
        if p.teamId ~= nil and p.teamId == victim.teamId then return false, "friendly_assist" end
        if p ~= killer and p ~= victim then assists[p.key], assistIdentities[p.key] = p, identity end
    end
    -- Never score at the exact timer boundary. Advance time before applying ordered event.
    self:_advance(math.max(self.now, event.at))
    r.events[event.eventId], r.eventCount = true, r.eventCount + 1
    r.lastSequence, r.lastEventAt = event.serverSequence, event.at
    if r.ended or r.cutoffAt and (event.at >= r.cutoffAt and r.endReason == "timer"
        or r.cutoffSequence and event.serverSequence > r.cutoffSequence) then
        self.diagnostics.ignoredEvents += 1; return true, "scoring_closed"
    end
    if event.kind == "weaponDamage" then
        attacker.damage += event.amount
        -- Each new pair consumes an accepted event, so MAX_EVENTS bounds this
        -- round-local map. Retained-round cleanup releases it with the history.
        if self:_damageEngagement(event) then attacker.qualifyingEvents += 1 end
        self:_activity(attacker, event.at, event.attacker); self:_qualify(attacker)
    else
        local points = self.context.economy.points
        local zone = self:_zone()
        local victimInZone = zone and Rules.inZone(victim.sample and victim.sample.position, zone)
        local function foldPoints(p, amount, assist)
            if zone and not victimInZone and not Rules.inZone(p.sample and p.sample.position, zone) then
                amount *= points.airspace_outside_zone_factor
                if assist then amount = math.max(5, 5 * math.round(amount / 5)) end
            end
            return amount
        end
        local function earn(p, amount, kind, sourceId, identity)
            p.contribution += amount
            self:_earned(p, amount, kind, sourceId, event.at, identity)
        end
        r.lifeBounds[binding(event.victim)].combatEnded = true
        if event.reason ~= "fresh_plane" and event.reason ~= "round_end" then victim.deaths += 1 end
        if victim.lifeId == event.victim.lifeId then
            self:_stopActivity(victim)
            victim.streak, victim.sample = 0, nil
        end
        if killer and killer ~= victim then
            killer.kills += 1
            earn(killer, foldPoints(killer, points.fold, false), "fold", event.eventId, event.killer)
            local killerBounds = r.lifeBounds[binding(event.killer)]
            if killer.present and killer.lifeId == event.killer.lifeId and killerBounds and killerBounds.endedAt == nil then
                killer.streak += 1; killer.bestStreak = math.max(killer.bestStreak, killer.streak)
                if killer.streak >= points.streak_from then
                    earn(killer, points.streak_bonus, "streak", event.eventId .. ":streak", event.killer)
                end
            end
            if killer.lastFolderKey == victim.key then
                earn(killer, points.revenge, "revenge", event.eventId .. ":revenge", event.killer)
                killer.lastFolderKey = nil
            end
            victim.lastFolderKey = killer.key
            if not r.firstFoldAwarded then
                earn(killer, points.first_fold, "first_fold", event.eventId .. ":first_fold", event.killer)
                r.firstFoldAwarded = true
            end
            killer.qualifyingEvents += 1; self:_activity(killer, event.at, event.killer); self:_qualify(killer)
            if r.mode == "TDM" then r.teams[killer.teamId] += 1 end
        end
        for _, p in pairs(assists) do
            local identity = assistIdentities[p.key]
            local amount = math.clamp(5 * math.round(100 * identity.share / 5), points.fold_assist_min, points.fold_assist_max)
            p.assists += 1
            earn(p, foldPoints(p, amount, true), "fold_assist", event.eventId, identity)
            -- The last shot on a plane someone else mostly shot down (Alan 2026-10-17): an assist plus this bonus.
            if identity.finisher == true then earn(p, points.finishing_shot, "finishing_shot", event.eventId .. ":finish", identity) end
            p.qualifyingEvents += 1; self:_activity(p, event.at, assistIdentities[p.key]); self:_qualify(p)
        end
        local target = r.mode == "FFA" and self.context.config.rounds.ffa_elimination_target
            or r.mode == "TDM" and self.context.config.rounds.tdm_elimination_target or math.huge
        local score = r.mode == "FFA" and killer and killer.kills or r.mode == "TDM" and killer and r.teams[killer.teamId] or 0
        if score >= target then self:_close(event.at, "target", event.serverSequence) end
    end
    return true
end
-- Trusted world prop facts are score only; never qualify activity or rookie participation.
function Match:propContribution(eventId, key, occurrence)
    -- The trusted prop outbox bypasses tick/backpressure, just like consumeCombat.
    -- Parent holds the watermark and departure/settlement until BOTH outboxes drain.
    if not occurrence then
        self:tick()
        if self.deliveryBlocked then return false, "combat_backlog" end
    end
    local r, e = self.round, self.context.economy
    local p = r and r.participants[key]
    if not p or not id(eventId) then return false end
    local kind = eventId:sub(1, 7) == "target:" and "target" or "prop"
    local pointsField = kind == "target" and "targetPoints" or "propPoints"
    local cap = kind == "target" and e.points.target_points_max_per_participation or e.points.prop_points_max_per_participation
    if r.events[eventId] then return true end
    local at, identity = self.now, nil
    if occurrence then
        if type(occurrence) ~= "table" or not table.isfrozen(occurrence) or occurrence.eventId ~= eventId
            or occurrence.participantKey ~= key or occurrence.kind ~= "small_prop"
            or not Rules.finite(occurrence.at) or occurrence.at < r.startedAt or occurrence.at > self:_clock()
            or not Rules.finite(occurrence.afterCombatSequence) or occurrence.afterCombatSequence < 0
            or occurrence.afterCombatSequence % 1 ~= 0 or self:_identity(occurrence) ~= p then return false, "invalid_occurrence" end
        local bounds = r.lifeBounds[binding(occurrence)]
        if not bounds or occurrence.at < bounds.startedAt
            or bounds.endedAt and occurrence.at > bounds.endedAt then return false, "outside_life" end
        if r.ended then return false, "settlement_already_sealed" end
        at, identity = occurrence.at, occurrence
    elseif self.phase ~= "ACTIVE" or not p.present then return false end
    if r.eventCount >= Match.MAX_EVENTS then return false, "event_history_full" end
    if occurrence and (at >= r.endsAt or r.cutoffAt and (at > r.cutoffAt or at == r.cutoffAt
        and (r.endReason == "timer" or occurrence.afterCombatSequence >= (r.cutoffSequence or 0)))) then
        r.events[eventId], r.eventCount = true, r.eventCount + 1
        return true, "scoring_closed"
    end
    -- Stage one earning before committing score/dedupe. A sink wrapper may throw either
    -- before or after _earned inserts. Keep the original receipt and never insert twice.
    local receipt = r.propDelivery
    if receipt and (receipt.eventId ~= eventId or receipt.key ~= key) then return false, "prop_backlog" end
    if not receipt then
        receipt = {eventId=eventId,key=key,at=at,identity=identity,earningIndex=#r.earnings+1,
            points=math.max(0,math.min(e.points[kind],cap-p[pointsField]))}
        r.propDelivery = receipt
    end
    local points, earned = receipt.points, false
    local factId = r.id .. ":earned:" .. eventId .. ":" .. p.key
    for i=receipt.earningIndex,#r.earnings do
        if r.earnings[i].factId == factId then earned = true; break end
    end
    if points > 0 and not earned then self:_earned(p,points,kind,eventId,receipt.at,receipt.identity) end
    p[pointsField] += points; p.contribution += points
    r.events[eventId], r.eventCount = true, r.eventCount + 1
    r.propDelivery = nil
    return true
end
function Match:_zone()
    local r, rounds = self.round, self.context.config.rounds
    if not r or r.mode ~= "CONTROL" then return nil end
    -- Studio test mode "next spot" (Alan 2026-10-16): the zone stays on the picked spot until the next click.
    if self.devZone then return rounds.control_zones[self.devZone], self.devZone, self.devZone % #rounds.control_zones + 1, math.huge end
    local elapsed = math.max(0, self.now - r.startedAt)
    local boundary = (math.floor(elapsed / rounds.control_move_seconds) + 1) * rounds.control_move_seconds
    -- Subtracting a fractional start clock can round just below an exact move time.
    if self.now >= r.startedAt + boundary then elapsed = boundary end
    local index, nextIndex, remaining = Rules.zoneAt(elapsed, rounds, r.zoneSeed)
    return rounds.control_zones[index], index, nextIndex, r.startedAt + (elapsed + remaining)
end
function Match:_occupants()
    local teams, occupants = {}, {}
    local zone = self:_zone()
    if not zone then return nil, occupants, false end
    for _, p in pairs(self.round.participants) do
        if p.present and p.connected and p.lifeId and Rules.captureEligible(p.sample, zone) then
            teams[p.teamId] = true; table.insert(occupants, p)
        end
    end
    if teams["team:1"] and teams["team:2"] then return nil, {}, true end
    return teams["team:1"] and "team:1" or teams["team:2"] and "team:2" or nil, occupants, false
end
function Match:zoneHolder()
    local team, _, contested = self:_occupants()
    return contested and "contested" or team
end
function Match:_zoneSnapshot()
    local _, index, nextIndex, moveAt = self:_zone()
    if not index then return nil end
    return { index = index, nextIndex = nextIndex, moveAt = moveAt, holder = self:zoneHolder() }
end
function Match:_activeInterval(untilAt)
    local r, config, e = self.round, self.context.config, self.context.economy
    local team, occupants = self:_occupants()
    local finish = math.min(untilAt, r.endsAt)
    local _, _, _, moveAt = self:_zone()
    if moveAt then finish = math.min(finish, moveAt) end
    if team then
        finish = math.min(finish, self.now + (config.rounds.control_target - r.teams[team]) / config.rounds.control_points_per_second)
    end
    local dt = math.max(0, finish - self.now)
    for _, p in pairs(r.participants) do
        if p.present and p.connected and Rules.activeEligible(p.sample) then
            interval(p.eligibleIntervals, self.now, finish)
        end
    end
    if team then
        r.teams[team] = math.min(config.rounds.control_target, r.teams[team] + dt * config.rounds.control_points_per_second)
        for _, p in ipairs(occupants) do
            local before = p.objectiveEvents
            local beforeZone = p.zoneEvents
            p.objectiveSeconds += dt
            -- Rookie and completion qualification still count one event per ten seconds.
            p.objectiveEvents = math.floor((p.objectiveSeconds + 1e-8) / 10)
            local events = p.objectiveEvents - before
            p.qualifyingEvents += events
            p.zoneEvents = math.floor((p.objectiveSeconds + 1e-8) / 5)
            for i = beforeZone + 1, p.zoneEvents do
                local earned = math.min(e.points.zone_per_5_eligible_seconds,
                    math.max(0, e.control_personal_points_max_per_match - (i-1) * e.points.zone_per_5_eligible_seconds))
                local at = finish - (p.objectiveSeconds - i * 5)
                p.contribution += earned
                self:_earned(p, earned, "zone", "zone:" .. i, at)
            end
            interval(p.activityIntervals, self.now, finish)
        end
    end
    for _, p in pairs(r.participants) do
        self:_activeSeconds(p, finish)
        self:_qualify(p)
    end
    self.now = finish
    if team and r.teams[team] >= config.rounds.control_target then self:_close(finish, "target", r.lastSequence)
    elseif finish >= r.endsAt then self:_close(finish, "timer") end
end
function Match:_close(at, reason, sequence)
    local r = self.round
    if r.ended or r.cutoffAt and at >= r.cutoffAt then return end
    r.cutoffAt, r.endReason, r.cutoffSequence, self.phase = at, reason, sequence, "ENDING"
    -- A delayed target may move a timer cutoff earlier. Recompute active time against it.
    for _, p in pairs(r.participants) do self:_activeSeconds(p) end
end
-- Parent must flush the complete ordered DamageService outbox, stop old combat dispatch and
-- call this with the last delivered sequence. No economic result exists before this barrier.
function Match:sealCombatDrain(matchId, lastDeliveredSequence)
    local r = self.round
    if not r or r.id ~= matchId then return false, "wrong_match" end
    if r.ended then return true end
    if self.phase ~= "ENDING" or lastDeliveredSequence ~= r.lastSequence then return false, "drain_not_confirmed" end
    self:_safeNow()
    if self.deliveryBlocked then return false, "combat_backlog" end
    self:_end(r.cutoffAt, r.endReason)
    self:_advance(self:_clock())
    return true
end
function Match:_end(at, reason)
    local r, e = self.round, self.context.economy
    if r.ended then return end
    r.ended, r.endedAt, self.phase = true, at, "RESULTS" -- Close scoring BEFORE snapshot or external sink.
    self.phaseEndsAt = self:_clock() + self.context.config.rounds.results_seconds
    local winners, winningTeam, draw = {}, nil, false
    if r.mode == "FFA" then
        local best = -1
        for _, p in pairs(r.participants) do if p.present and not p.forfeited then best = math.max(best, p.kills) end end
        for _, p in pairs(r.participants) do if p.present and not p.forfeited and p.kills == best then winners[p.key] = true end end
    elseif r.teams["team:1"] == r.teams["team:2"] then draw = true
    else winningTeam = r.teams["team:1"] > r.teams["team:2"] and "team:1" or "team:2" end
    local podiumRecords = {}
    for key, p in pairs(r.participants) do
        if p.present and (r.mode == "FFA" or p.teamId == winningTeam) then podiumRecords[key] = p end
        if p.present and p.teamId ~= nil and p.teamId == winningTeam then winners[key] = true end
    end
    local order, places = Rules.podium(podiumRecords, self.seed + self.serial), {}
    for place, p in ipairs(order) do places[p.key] = place end
    local rows = {}
    for _, p in ipairs(Rules.podium(r.participants, self.seed + self.serial)) do
        local row = MathUtil.copy(p)
        row.sample, row.activityUntil, row.eligibleIntervals, row.activityIntervals = nil, nil, nil, nil
        local eligible = p.present and not p.forfeited
            and Rules.qualified(p, e.completion_min_active_seconds, e.completion_min_qualifying_events)
        local win, place = eligible and winners[p.key] == true, places[p.key]
        local podium = eligible and not draw and place and place <= 3
        row.place, row.victory, row.completion = place, winners[p.key] == true, eligible
        row.finalPaper = (eligible and e.completion_paper or 0) + (win and e.win_paper or 0)
            + (podium and e.podium_paper_by_place[place] or 0)
        row.finalXP = (eligible and e.completion_xp or 0) + (win and e.win_xp or 0)
            + (podium and e.podium_xp_by_place[place] or 0)
        -- Bots occupy real places and receive the same calculated rates; bots never get persistent wallets.
        table.insert(rows, row)
    end
    r.result = detached({ matchId = r.id, mode = r.mode, reason = reason, endedAt = at,
        teams = r.teams, draw = draw, winningTeam = winningTeam, participants = rows })
    r.settlementId = r.id .. ":final"
end
function Match:_advance(untilAt)
    while self.now < untilAt do
        if self.phase == "ACTIVE" then self:_activeInterval(untilAt)
        elseif self.phase == "RESULTS" or self.phase == "VOTE" or self.phase == "COUNTDOWN" then
            self.now = math.min(untilAt, self.phaseEndsAt)
            if self.now >= self.phaseEndsAt then
                if self.phase == "RESULTS" then
                    self.phase = "VOTE"; self.phaseEndsAt += self.context.config.rounds.vote_seconds
                elseif self.phase == "VOTE" then
                    self.nextMode = Rules.chooseMode(self.round.votes, self.lastPlayed, self.seed + self.serial)
                    self.phase = "COUNTDOWN"; self.phaseEndsAt += self.context.config.rounds.launch_countdown_seconds
                else self.phase, self.phaseEndsAt = "READY", nil end
            end
        else self.now = untilAt end
    end
end
function Match:tick() self:_advance(self:_safeNow()); return self.phase end
function Match:vote(key, mode)
    self:tick()
    if self.deliveryBlocked then return false, "combat_backlog" end
    local p = self.round and self.round.participants[key]
    if self.phase ~= "VOTE" or not p or not p.present or not p.connected or p.controllerType ~= "human"
        or not Rules.mode(mode) then return false, "ineligible_vote" end
    self.round.votes[key] = mode
    return true
end
-- SERVER-INTERNAL ONLY: account linkage, controller type and activity evidence are private.
function Match:snapshot()
    local r = self.round
    return detached({ phase = self.phase, now = self.now, phaseEndsAt = self.phaseEndsAt,
        nextMode = self.nextMode, matchId = r and r.id, mode = r and r.mode, teams = r and r.teams,
        participants = r and r.participants, votes = r and r.votes, result = r and r.result, zone = self:_zoneSnapshot() })
end
local function publicPilot(p)
    return { actorId = p.actorId, displayName = p.displayName, teamId = p.teamId,
        kills = p.kills, assists = p.assists, deaths = p.deaths, contribution = p.contribution,
        place = p.place, victory = p.victory, completion = p.completion }
end
function Match:publicSnapshot()
    local r, pilots, votes, results = self.round, {}, { FFA = 0, TDM = 0, CONTROL = 0 }, nil
    if r then
        for _, p in pairs(r.participants) do if p.present then table.insert(pilots, publicPilot(p)) end end
        table.sort(pilots, function(a, b) return a.actorId < b.actorId end)
        assert(#pilots <= self.context.config.world.maximum_actors, "public roster overflow")
        for _, mode in pairs(r.votes) do votes[mode] += 1 end
        if r.result then
            local rows = {}
            for _, p in ipairs(r.result.participants) do if p.present then table.insert(rows, publicPilot(p)) end end
            assert(#rows <= self.context.config.world.maximum_actors, "public results overflow")
            results = { participants = rows, draw = r.result.draw, winningTeam = r.result.winningTeam,
                endedAt = r.result.endedAt, reason = r.result.reason }
        end
    end
    return detached({ matchId = r and r.id, mode = r and r.mode, phase = self.phase,
        phaseEndsAt = self.phaseEndsAt, nextMode = self.nextMode, pilots = pilots,
        voteTotals = votes, teams = r and r.teams, result = results, zone = self:_zoneSnapshot() })
end
function Match:acknowledgeSettlement(matchId, settlementId)
    local r = self.retained[matchId]
    if not r or settlementId ~= r.settlementId then return false, "wrong_settlement" end
    r.acknowledged = true
    return true
end
-- Round cleanup follows reward handoff and the end of all lives and shots.
function Match:cleanup(matchId, prerequisites)
    local r = self.retained[matchId]
    if not r or not r.ended or not r.acknowledged then return false, "unsettled" end
    if r == self.round and self.phase ~= "READY" then return false, "lifecycle_in_use" end
    if type(prerequisites) ~= "table" or prerequisites.upstreamDrained ~= true
        or prerequisites.livesEnded ~= true or prerequisites.replayBarrier ~= true then return false, "cleanup_prerequisites" end
    self.retained[matchId], self.retainedCount = nil, self.retainedCount - 1
    if r == self.round then self.round = nil end
    return true
end
return Match
