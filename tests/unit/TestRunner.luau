-- Run manually in a Studio server. Nothing runs automatically in the game.
local Runner = {}
function Runner.run()
 local total = { passed = 0, failed = 0, suites = 0, failures = {} }
 local modules = {}
 for _, module in ipairs(script.Parent.Parent:GetDescendants()) do
  if module:IsA("ModuleScript") and module.Name:match("%.spec$") then table.insert(modules, module) end
 end
 table.sort(modules, function(a, b) return a:GetFullName() < b:GetFullName() end)
 for _, module in ipairs(modules) do
  total.suites += 1
  local ok, result = pcall(function() return require(module).run() end)
  if not ok then
   total.failed += 1
   table.insert(total.failures, module.Name .. ": " .. tostring(result))
  else
   total.passed += result.passed
   total.failed += result.failed
   for _, case in ipairs(result.results) do
    if not case.passed then table.insert(total.failures, module.Name .. "/" .. case.name .. ": " .. tostring(case.message)) end
   end
  end
 end
 return total
end
return Runner
