-- PC keys a player can change (docs/plan/CONTROLS-PLAN.md part 2; Settings > Controls). Saved with their settings as
-- `keys`: Enum.KeyCode names, missing = the game's keys. Pure, so the unit tests can check the rules.
local KeyBinds = {}

KeyBinds.DEFAULTS = { boost = "LeftShift", brake = "Space", gotIt = "Space" }
-- The keys on offer and how the game writes them. Letters except K (skip a lesson) and R (start fresh); digits, Enter,
-- Tab and Esc all have jobs of their own.
local NAMES = { LeftShift = "Shift", RightShift = "Right Shift", LeftControl = "Ctrl", RightControl = "Right Ctrl",
	LeftAlt = "Alt", RightAlt = "Right Alt", Space = "Space" }
for letter in ("ABCDEFGHIJLMNOPQSTUVWXYZ"):gmatch(".") do NAMES[letter] = letter end

-- How the game writes a key (nil = a key players can't choose).
function KeyBinds.name(key) return NAMES[key] end

-- Every action's key, from the saved `keys` (or nil).
function KeyBinds.current(saved)
	local keys = table.clone(KeyBinds.DEFAULTS)
	for action, key in saved or {} do keys[action] = key end
	return keys
end

-- The keys after giving `action` a new key. Boost and Brake are held together in flight, so taking the other's key
-- swaps the two; Got it only works on a note and can share (Space, with Brake, is the game's own choice).
function KeyBinds.set(saved, action, key)
	local keys = KeyBinds.current(saved)
	local other = action == "boost" and "brake" or action == "brake" and "boost" or nil
	if other and keys[other] == key then keys[other] = keys[action] end
	keys[action] = key
	return keys
end

-- The save check (ProfileSchema): nil, or only these actions with keys on offer, Boost and Brake apart.
function KeyBinds.valid(saved)
	if saved == nil then return true end
	if type(saved) ~= "table" then return false end
	for action, key in saved do
		if not KeyBinds.DEFAULTS[action] or not NAMES[key] then return false end
	end
	local keys = KeyBinds.current(saved)
	return keys.boost ~= keys.brake
end

return KeyBinds
