-- Loaded-online time only. Pure state/history, never a receipt verifier or durable store.
local Clock = {}
Clock.__index = Clock
local MAX = 9007199254740991
local fields = { paperSeconds = true, xpSeconds = true, permanentPaper = true, permanentXP = true }
local function finite(n) return type(n) == "number" and n == n and n >= 0 and n <= MAX end
local function copyState(s)
    assert(type(s) == "table" and getmetatable(s) == nil, "invalid_boost_state")
    for k in pairs(s) do assert(fields[k], "unknown_boost_field") end
    assert(finite(s.paperSeconds) and finite(s.xpSeconds), "invalid_remaining_seconds")
    assert(type(s.permanentPaper) == "boolean" and type(s.permanentXP) == "boolean", "invalid_permanent_flags")
    return table.clone(s)
end
local function multipliers(s)
    return (s.permanentPaper or s.paperSeconds > 0) and 2 or 1,
        (s.permanentXP or s.xpSeconds > 0) and 2 or 1
end
local function result(p, x, at, revision)
    return table.freeze({ paper = p, xp = x, at = at, revision = revision })
end
function Clock.new(state, now, eligible, options)
    assert(finite(now) and type(eligible) == "boolean", "invalid_clock_start")
    local limit = options and options.historyLimit or 256
    assert(finite(limit) and limit % 1 == 0 and limit >= 3 and limit <= 4096, "invalid_history_limit")
    return setmetatable({ state = copyState(state), now = now, eligible = eligible,
        startedAt = now, watermark = -1, revision = 0, intervals = {}, changes = {}, limit = limit }, Clock)
end
function Clock:snapshot() return table.freeze(copyState(self.state)) end
function Clock:capture()
    if not self.eligible then return nil, "ineligible_interval" end
    local p, x = multipliers(self.state)
    return result(p, x, self.now, self.revision)
end
-- Advance before changing loaded/available status, using the old status for elapsed time.
-- A newly restored clock starts at the current monotonic time; offline time is never subtracted.
function Clock:advance(now, eligible)
    if not finite(now) or now < self.now or type(eligible) ~= "boolean" then return false, "invalid_clock" end
    local state, intervals, at = copyState(self.state), {}, self.now
    for _, old in ipairs(self.intervals) do table.insert(intervals, table.clone(old)) end
    while at < now do
        local finish, paperEnd, xpEnd = now, nil, nil
        if self.eligible then
            if not state.permanentPaper and state.paperSeconds > 0 then paperEnd = at + state.paperSeconds; finish = math.min(finish, paperEnd) end
            if not state.permanentXP and state.xpSeconds > 0 then xpEnd = at + state.xpSeconds; finish = math.min(finish, xpEnd) end
        end
        if finish <= at then return false, "clock_precision" end
        local p, x = multipliers(state)
        local last = intervals[#intervals]
        if last and last.finish == at and last.paper == p and last.xp == x and last.eligible == self.eligible then
            last.finish = finish
        else
            if #intervals >= self.limit then return false, "history_backpressure" end
            table.insert(intervals, { start = at, finish = finish, paper = p, xp = x, eligible = self.eligible })
        end
        if self.eligible then
            local elapsed = finish - at
            -- A selected expiry consumes that duration exactly. Subtracting the
            -- rounded timestamp difference can otherwise leave a positive residue
            -- too small to advance the next timestamp. The guard above still
            -- rejects durations whose initial endpoint cannot be represented.
            if not state.permanentPaper then state.paperSeconds = finish == paperEnd and 0 or math.max(0, state.paperSeconds - elapsed) end
            if not state.permanentXP then state.xpSeconds = finish == xpEnd and 0 or math.max(0, state.xpSeconds - elapsed) end
        end
        at = finish
    end
    self.state, self.intervals, self.now, self.eligible = state, intervals, now, eligible
    return true
end
function Clock:canOfferTemporary(resource)
    if resource == "paper" then return not self.state.permanentPaper end
    if resource == "xp" then return not self.state.permanentXP end
    return false
end
-- Caller has already verified/journaled the grant. An in-flight receipt can add dormant
-- time after a permanent upgrade. Never call this from a purchase-prompt callback.
function Clock:grantVerifiedTemporary(resource, seconds, now)
    local field = resource == "paper" and "paperSeconds" or resource == "xp" and "xpSeconds" or nil
    if not field or not finite(seconds) or seconds <= 0 or seconds % 1 ~= 0 then return false, "invalid_grant" end
    if self.state[field] > MAX - seconds then return false, "overflow" end
    if #self.changes >= self.limit then return false, "history_backpressure" end
    local ok, why = self:advance(now, self.eligible)
    if not ok then return false, why end
    self.state[field] += seconds
    self.revision += 1
    table.insert(self.changes, now)
    return true
end
function Clock:grantVerifiedPermanent(resource, now)
    local field = resource == "paper" and "permanentPaper" or resource == "xp" and "permanentXP" or nil
    if not field then return false, "invalid_resource" end
    if self.state[field] then return self:advance(now, self.eligible) end
    if #self.changes >= self.limit then return false, "history_backpressure" end
    local ok, why = self:advance(now, self.eligible)
    if not ok then return false, why end
    self.state[field], self.revision = true, self.revision + 1
    table.insert(self.changes, now)
    return true
end
function Clock:multipliersAt(at)
    if not finite(at) or at < self.startedAt or at <= self.watermark or at > self.now then return nil, "history_unavailable" end
    -- A timestamp alone cannot order a grant and reward at the same instant. Producers
    -- should capture() at occurrence; delayed timestamp-only events fail closed here.
    for _, changedAt in ipairs(self.changes) do if changedAt == at then return nil, "ambiguous_event_order" end end
    if at == self.now then return self:capture() end
    for _, span in ipairs(self.intervals) do
        if at >= span.start and at < span.finish then
            if not span.eligible then return nil, "ineligible_interval" end
            return result(span.paper, span.xp, at, nil)
        end
    end
    return nil, "history_unavailable"
end
-- Only call after the downstream durable earning/replay watermark proves older events
-- no longer need this history. History pressure must block earning, never assume 1x/2x.
function Clock:pruneThrough(at)
    if not finite(at) or at < self.watermark or at > self.now then return false, "invalid_watermark" end
    local intervals, changes = {}, {}
    for _, span in ipairs(self.intervals) do if span.finish > at then table.insert(intervals, span) end end
    for _, changedAt in ipairs(self.changes) do if changedAt > at then table.insert(changes, changedAt) end end
    self.intervals, self.changes, self.watermark = intervals, changes, at
    return true
end
return Clock
