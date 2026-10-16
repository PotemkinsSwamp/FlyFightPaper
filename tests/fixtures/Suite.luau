-- TestRunner-compatible named assertions, kept outside discovered unit suites.
local Suite = {}
function Suite.new()
    local result = { passed = 0, failed = 0, results = {} }
    local function test(name, callback)
        local ok, message = pcall(callback)
        if ok then result.passed += 1 else result.failed += 1 end
        table.insert(result.results, { name = name, passed = ok, message = not ok and tostring(message) or nil })
    end
    return result, test
end
return Suite
