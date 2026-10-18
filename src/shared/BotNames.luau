-- Made-up pilot names in the styles kids use on Roblox today (Alan 2026-10-18: the old word+word+digits names read
-- like 2018): lowercase "aesthetic" handles, stretched names (lunaaa), letters swapped for x (sxphie, kxng), cute
-- nonsense words (beabagooby), ALL-CAPS jokes (RAWR), "not"/"its"/"real" tags, short years and the odd xX..Xx.
-- Never copied from real accounts (VISION: no forged Roblox accounts).
-- Every name follows Roblox's username rules: 3-20 letters/digits, at most one underscore, not at either end.
local BotNames = {}

local FIRST = { "luna", "zoey", "kai", "mia", "jayden", "ava", "eli", "nova", "ivy", "theo", "ruby", "jack", "sophie",
	"bri", "maya", "leo", "chloe", "finn", "aria", "max", "emma", "noah", "lily", "jake", "nia", "zane", "ella", "milo" }
local SOFT = { "strawberry", "cloudy", "angel", "bunny", "kitty", "honey", "cherry", "peachy", "sleepy", "starry",
	"moon", "bubble", "cocoa", "mochi", "boba", "sugar", "velvet", "lavender", "fairy", "sunny" }
local EDGY = { "vamp", "ghost", "void", "toxic", "shadow", "crimson", "frost", "neon", "glitch", "chaos", "hex",
	"venom", "doom", "nightmare", "savage", "rogue", "phantom", "static" }
local THINGS = { "milk", "kitty", "bunny", "bat", "fox", "frog", "rat", "bear", "slime", "noodle", "bean", "duck",
	"goose", "wolf", "cat", "toast", "pickle", "gremlin", "cookie", "potato", "moth", "pigeon" }
local CAPS = { "RAWR", "BRUH", "GOOBER", "ZOOMIES", "SILLY", "CHUNGUS", "YIPPEE", "SKIBIDI", "GRRR", "BONK", "MEOW",
	"LOWTAPER", "OOGA", "BOOBOO", "WHOMP" }
local SYLLABLES = { "be", "ba", "goo", "by", "we", "mi", "ky", "zo", "ru", "pi", "lo", "nu", "fe", "so", "xi", "go",
	"ro", "nix", "ki", "mo", "la", "wi", "bo", "tu" }

local function word(list, pick) return list[pick(#list)] end
local function stretch(name, pick) return name .. string.rep(name:sub(-1), pick(3)) end -- lunaaa, kaiii
local function xswap(name) -- sophie -> sxphie, king -> kxng: the first vowel after the first letter becomes x
	return (name:gsub("^(%a)[aeiou]", "%1x", 1))
end
local function year(pick) return tostring(pick(2) == 1 and (8 + pick(9)) or (2008 + pick(10))) end -- 09..17 or 2009..2018
local function nonsense(pick)
	local out = ""
	for _ = 1, 2 + pick(2) do out ..= word(SYLLABLES, pick) end
	return out
end

local PATTERNS = {
	{ 12, function(p) return stretch(word(FIRST, p), p) end },                                  -- lunaaa
	{ 10, function(p) return xswap(word(FIRST, p)) .. (p(2) == 1 and "_" .. year(p) or "") end }, -- sxphie_12
	{ 12, function(p) return word(SOFT, p) .. word(THINGS, p) end },                           -- strawberrymilk
	{ 10, function(p) return word(EDGY, p) .. (p(2) == 1 and "_" or "") .. word(THINGS, p) end }, -- vamp_kitty
	{ 10, function(p) return nonsense(p) end },                                                 -- beabagooby
	{ 6, function(p) return word(CAPS, p) .. (p(2) == 1 and string.upper(word(THINGS, p)) or "") end }, -- RAWR, SILLYRAT
	{ 8, function(p) return ({ "not", "its", "real", "lil" })[p(4)] .. word(FIRST, p) .. (p(3) == 1 and year(p) or "") end }, -- notjake
	{ 8, function(p) local f = word(FIRST, p); return f:sub(1, 1):upper() .. f:sub(2) .. "_" .. word(SOFT, p) end }, -- Bri_starry
	{ 6, function(p) return word(FIRST, p) .. word(SOFT, p) .. year(p) end },                  -- mayacocoa12
	{ 6, function(p) return "xx" .. string.upper(word(FIRST, p)) .. "xx" end },                -- xxJAKExx
	{ 6, function(p) return word(THINGS, p) .. ({ "lover", "enjoyer", "gang", "core", "_alt" })[p(5)] end }, -- ratlover
	{ 6, function(p) return stretch(nonsense(p), p) end },                                      -- wemikyyy
}
local TOTAL = 0
for _, pattern in ipairs(PATTERNS) do TOTAL += pattern[1] end

function BotNames.valid(name)
	return type(name) == "string" and #name >= 3 and #name <= 20 and name:match("^[%w]+_?[%w]+$") ~= nil
end

-- One candidate name. Callers retry with a fresh pick on a clash or an invalid result.
function BotNames.make(pick)
	local roll = pick(TOTAL)
	for _, pattern in ipairs(PATTERNS) do
		roll -= pattern[1]
		if roll <= 0 then return pattern[2](pick) end
	end
	return PATTERNS[1][2](pick)
end

return BotNames
