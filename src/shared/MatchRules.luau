-- Pure match decisions. No account, wallet, actor mutation or engine queries.
local Rules = {}
Rules.MODES = table.freeze({ "FFA", "TDM", "CONTROL" })
Rules.ACTIVITY_WINDOW_SECONDS = 10
function Rules.finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
function Rules.mode(mode)
    return mode == "FFA" or mode == "TDM" or mode == "CONTROL"
end
function Rules.seedOrder(seed, key)
    local n = 2166136261
    for i = 1, #key do
        n = bit32.bxor(n, string.byte(key, i))
        -- Exact uint32 multiply via 16-bit limbs, safe in a double.
        n = ((n % 65536) * 403 + (math.floor(n / 65536) * 403 + (n % 65536) * 256) * 65536) % 4294967296
    end
    n = bit32.bxor(n, seed % 4294967296)
    for _ = 1, 3 do
        n = bit32.bxor(n, bit32.lshift(n, 13))
        n = bit32.bxor(n, bit32.rshift(n, 17))
        n = bit32.bxor(n, bit32.lshift(n, 5))
    end
    return n
end
function Rules.chooseMode(votes, lastPlayed, seed)
    local counts, highest = {}, 0
    for _, mode in ipairs(Rules.MODES) do counts[mode] = 0 end
    for _, mode in pairs(votes) do
        if counts[mode] then counts[mode] += 1; highest = math.max(highest, counts[mode]) end
    end
    local candidates, oldest = {}, math.huge
    for _, mode in ipairs(Rules.MODES) do
        local last = lastPlayed[mode] or 0
        if counts[mode] == highest then
            if last < oldest then candidates, oldest = {}, last end
            if last == oldest then table.insert(candidates, mode) end
        end
    end
    table.sort(candidates)
    return candidates[Rules.seedOrder(seed, "mode-vote") % #candidates + 1]
end
function Rules.zoneAt(elapsed, rounds, seed)
    local seconds, count = rounds.control_move_seconds, #rounds.control_zones
    assert(Rules.finite(seconds) and seconds > 0 and count >= 2, "control needs a positive move interval and at least two zones")
    -- Bound bad input; real rounds need only a handful of slots.
    elapsed = Rules.finite(elapsed) and math.clamp(elapsed, 0, seconds * 1000) or 0
    local k = math.floor(elapsed / seconds)
    local previous, index, nextIndex
    for slot = 0, k + 1 do
        local choices = previous and count - 1 or count
        local selected = Rules.seedOrder(seed, "control-zone:" .. slot) % choices + 1
        if previous and selected >= previous then selected += 1 end
        if slot == k then index = selected end
        if slot == k + 1 then nextIndex = selected end
        previous = selected
    end
    return index, nextIndex, (k + 1) * seconds - elapsed
end
function Rules.inZone(position, zone)
    if typeof(position) ~= "Vector3" then return false end
    if not Rules.finite(position.X) or not Rules.finite(position.Y) or not Rules.finite(position.Z) then return false end
    local c = zone.center
    return math.abs(position.Y - c[2]) <= zone.half_height
        and (position.X - c[1])^2 + (position.Z - c[3])^2 <= zone.radius^2
end
function Rules.captureEligible(sample, zone)
    return sample ~= nil and sample.state == "FLYING" and sample.protected == false
        and sample.eligible == true and sample.practice ~= true
        and Rules.inZone(sample.position, zone)
end
function Rules.activeEligible(sample)
    return sample ~= nil and sample.eligible == true and sample.practice ~= true
        and (sample.state == "FLYING" or sample.state == "TAKEOFF" or sample.state == "LANDING" or sample.state == "SERVICING")
end
function Rules.qualified(p, seconds, events)
    return p.activeSeconds >= seconds and p.qualifyingEvents >= events
end
function Rules.podium(records, seed)
    local ordered = {}
    for _, p in pairs(records) do table.insert(ordered, p) end
    table.sort(ordered, function(a, b)
        for _, field in ipairs({ "contribution", "kills", "assists" }) do
            if a[field] ~= b[field] then return a[field] > b[field] end
        end
        if a.deaths ~= b.deaths then return a.deaths < b.deaths end
        local x, y = Rules.seedOrder(seed, a.key), Rules.seedOrder(seed, b.key)
        return x < y or x == y and a.key < b.key
    end)
    return ordered
end
return table.freeze(Rules)
