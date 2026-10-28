-- Phones say touch words (Alan 2026-10-23, docs/plan/TOUCH-PLAN.md): the game's texts are written for a PC (keys and
-- clicks); on a touch screen each one is rewritten with these swaps, in order. The touch buttons are FIRE (weapon 1),
-- 2 (weapon 2) and BOOST (TouchControls); the steering stick is "the stick".
local TouchWords = {}

local KEYS
local SWAPS = {
	{ "Skip  %[K%]", "Skip\n(hold: all)" }, -- the lesson's Skip button: held, it skips the whole lesson (Tutorial); two lines fit a phone
	{ "%s*%[Space%]", "" }, { "%s*%[K%]", "" },
	{ "Move the mouse to steer", "Push the stick to steer" },
	{ "Hold Shift to boost", "Hold BOOST to go faster" },
	{ "Press K to skip this step", "Tap Skip to skip this step" },
	{ "press Enter", "tap Done" },
	{ "Click or press Space to close", "Tap to close" },
	{ "or press 1, 2 or 3", "or tap a card" },
	{ "one gear type on left click, the other on right", "one gear type on FIRE, the other on 2" },
	{ "one for left click, one for right click", "one for FIRE, one for 2" },
	{ "the right%-click row", "the 2 button" },
	{ "Mouse sensitivity", "Steering speed" },
	{ "([Hh])old left[ %-]click", "%1old FIRE" }, { "([Hh])old right[ %-]click", "%1old 2" },
	{ "left[ %-]click", "FIRE" }, { "right[ %-]click", "the 2 button" },
	{ "%f[%a]Click", "Tap" }, { "%f[%a]click", "tap" },
	{ "the mouse", "the stick" },
}
-- The key badge on a lesson's sticky note (and any label that is just a key's name).
KEYS = { Enter = "LAUNCH", Mouse = "Stick", Shift = "BOOST", ["Left click"] = "FIRE", ["Right click"] = "2" }

-- `text` as a phone player should read it (unchanged on a PC: `touch` false).
function TouchWords.say(text, touch)
	if not touch or type(text) ~= "string" then return text end
	if KEYS[text] then return KEYS[text] end
	for _, swap in SWAPS do text = text:gsub(swap[1], swap[2]) end
	return text
end

function TouchWords.key(key, touch)
	return touch and KEYS[key] or key
end

-- Words a phone player should never see (the unit test checks every lesson's text).
TouchWords.PC_ONLY = { "%f[%a]click", "%f[%a]mouse", "%f[%a]space%f[%A]", "%f[%a]shift%f[%A]", "%f[%a]enter%f[%A]", "%[k%]", "press k" }

return TouchWords
