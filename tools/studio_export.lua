-- Exports workspace.Arena.ClassroomDecor as base64 rbxm, in 90k chunks (results cap at ~100k chars).
-- Replace __CHUNK__ with -1 for the total length, then 0..n; swap the instance path for other folders.
local b = game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Arena.ClassroomDecor})
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local n, out = buffer.len(b), table.create(math.ceil(buffer.len(b) / 3))
for i = 0, n - 1, 3 do
  local a, c2, c3 = buffer.readu8(b, i), i + 1 < n and buffer.readu8(b, i + 1) or 0, i + 2 < n and buffer.readu8(b, i + 2) or 0
  local v = a * 65536 + c2 * 256 + c3
  local s = chars:sub(bit32.rshift(v, 18) + 1, bit32.rshift(v, 18) + 1) .. chars:sub(bit32.band(bit32.rshift(v, 12), 63) + 1, bit32.band(bit32.rshift(v, 12), 63) + 1)
  s ..= i + 1 < n and chars:sub(bit32.band(bit32.rshift(v, 6), 63) + 1, bit32.band(bit32.rshift(v, 6), 63) + 1) or "="
  s ..= i + 2 < n and chars:sub(bit32.band(v, 63) + 1, bit32.band(v, 63) + 1) or "="
  table.insert(out, s)
end
local all = table.concat(out)
local K = __CHUNK__
if K < 0 then return #all end
return all:sub(K * 90000 + 1, (K + 1) * 90000)
