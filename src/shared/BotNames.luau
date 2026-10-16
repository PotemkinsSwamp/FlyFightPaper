-- Made-up pilot names in the styles Roblox players use (word + word + digits, lowercase handles, a name and a
-- year, "its"/"im" tags, the odd xX..Xx). Never copied from real accounts (VISION: no forged Roblox accounts).
-- Every name follows Roblox's username rules: 3-20 letters/digits, at most one underscore, not at either end.
local BotNames = {}

local ADJECTIVES = { "Sneaky", "Fuzzy", "Frosty", "Crispy", "Sleepy", "Speedy", "Lucky", "Silly", "Mighty", "Tiny",
	"Cosmic", "Pixel", "Shadow", "Turbo", "Golden", "Hyper", "Epic", "Spicy", "Sunny", "Wobbly", "Chill", "Jolly",
	"Neon", "Lazy", "Swift", "Bouncy", "Crunchy", "Salty", "Mystic", "Royal", "Sparkly", "Stormy", "Icy", "Rusty",
	"Grumpy", "Happy", "Wild", "Dizzy", "Fluffy", "Sly" }
local NOUNS = { "Noodle", "Panda", "Taco", "Pickle", "Wolf", "Fox", "Dragon", "Ninja", "Cookie", "Potato", "Bean",
	"Toast", "Penguin", "Waffle", "Comet", "Rocket", "Blade", "Llama", "Gamer", "Pilot", "Muffin", "Burrito", "Frog",
	"Kitten", "Tiger", "Bunny", "Shark", "Ghost", "Knight", "Wizard", "Nugget", "Pancake", "Cactus", "Bear", "Raven",
	"Hawk", "Storm", "Spark", "Duck", "Owl", "Mango", "Kiwi", "Yeti", "Goose" }
local FIRST = { "Maya", "Jayden", "Luna", "Ethan", "Ava", "Liam", "Zoe", "Noah", "Mia", "Leo", "Ella", "Kai", "Lily",
	"Max", "Aria", "Owen", "Chloe", "Eli", "Nova", "Finn", "Ivy", "Theo", "Ruby", "Jack" }

-- pick(n) returns a whole number from 1 to n; the caller decides how it is seeded.
local function digits(pick)
	local style = pick(4)
	if style == 1 then return tostring(2007 + pick(12)) end -- a birth or join year
	if style == 2 then return tostring(pick(99)) end
	if style == 3 then return string.format("%02d", pick(99)) end
	return tostring(99 + pick(9900))
end

local function word(list, pick) return list[pick(#list)] end

local PATTERNS = {
	{ 30, function(p) return word(ADJECTIVES, p) .. word(NOUNS, p) .. digits(p) end },          -- SneakyNoodle482
	{ 14, function(p) return string.lower(word(ADJECTIVES, p) .. word(NOUNS, p)) .. (p(2) == 1 and digits(p) or "") end }, -- frostybanana
	{ 12, function(p) return string.lower(word(NOUNS, p) .. "_" .. word(NOUNS, p)) end },        -- toast_wizard
	{ 12, function(p)                                                                            -- maya2013, Jayden_09
		local name = word(FIRST, p)
		if p(2) == 1 then name = string.lower(name) end
		return name .. (p(3) == 1 and "_" or "") .. digits(p)
	end },
	{ 8, function(p) return (p(2) == 1 and "its" or "im") .. (p(2) == 1 and word(FIRST, p) or word(NOUNS, p)) end }, -- itsLuna
	{ 10, function(p) return word(ADJECTIVES, p) .. word(NOUNS, p) end },                        -- PixelPanda
	{ 9, function(p) return word(NOUNS, p) .. word(NOUNS, p) .. digits(p) end },                 -- BeanWolf77
	{ 5, function(p) return "xX" .. word(ADJECTIVES, p) .. word(NOUNS, p) .. "Xx" end },         -- xXShadowFoxXx
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
