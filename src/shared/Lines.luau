-- Event lines (Alan 2026-10-17, docs/decisions/2026-10-17-fresh-rotating-lines.md). Like Minecraft's death messages,
-- each line says how it happened (which weapon, what you hit, who rammed you), in the classroom / paper-plane /
-- school-supply theme. No sound words, nothing cheesy. Every event has a few lines, picked at random and never the
-- same twice in a row. Waits are described, not counted.
-- Tokens: {v} victim, {k} killer (or the other plane), {vp}/{kp} their possessive ("your", "Mia's"), {t} the thing
-- hit, {m} a mode name. Pass "you" as a name for the player reading it.
local Lines = {}

-- Simple events (the plane's top note, the desk, the results sheet).
Lines.sets = {
	atDesk = { "Your plane is folded and waiting on your desk.", "Fresh crease, sharp nose. Ready when you are.", "Your plane sits on your desk, ready to throw." },
	takeoff = { "Launched off your desk. Class is in session.", "Off the desk while the teacher isn't looking.", "Thrown clear of your desk. Good luck up there." },
	scraping = { "Your wing is scraping! Pull away.", "That surface is shaving your paper. Steer off it!", "Scraping paper off your belly. Pull up!" },
	fanClip = { "A fan blade clipped your wing.", "The duct fan took a bite out of your plane.", "A spinning blade nicked your paper." },
	updraft = { "The fan is pushing you up. Lift rising.", "Riding the fan's breeze. Lift filling up.", "Warm air from the fan is lifting you." },
	tailwind = { "Wind at your back. Free speed.", "The fan's breeze is pushing you along.", "Riding the breeze. You're flying faster here." },
	headwind = { "Flying into the breeze. You're slower here.", "Headwind. Your plane is fighting the fan's air.", "The breeze is pushing back on your nose." },
	speedPickup = { "Speed boost! Your plane is flying faster.", "You grabbed a speed boost.", "Extra speed for a little while." },
	turnBack = { "Turn back! That's outside the classroom.", "No hall pass for out there. Turn around!", "Back to class! You're leaving the room." },
	wobble = { "Your plane got put back on its flight path.", "Your plane wobbled and got straightened out." },
	deskBusy = { "Your runway is busy. Circle the marker until it's your turn.", "Wait at the marker, like the lunch line.", "Someone is on your runway. Hold at the marker." },
	padFree = { "Your runway is clear. Fly through the paper-chain ring.", "Your turn. Aim for the paper-chain ring.", "Clear to land. Thread the paper-chain ring." },
	padWait = { "Your new plane is waiting for your desk to clear.", "Your desk is busy. Your new plane is next in line." },
	landing = { "Lining up with your desk.", "Gliding home to your desk.", "Easing down onto your runway." },
	landed = { "Back at your desk. Lift is filling up.", "Touched down on your desk. Topping up Lift.", "Home safe. Your Lift is refilling." },
	refilling = { "Your desk is topping up your Lift.", "Filling your Lift at the desk.", "Refilling your Lift while you sit tight." },
	repairing = { "Taping up the holes. Tape adds wear.", "Patching your wings with tape. Each patch adds wear.", "Smoothing out the creases. Repairs add wear." },
	serviceDone = { "Service done. Your plane is ready to throw.", "All set. Ready to fly again.", "Your plane is good to go." },
	refolding = { "Unfolding your old plane and folding the new build.", "Folding your new build, crease by crease.", "Refolding along new lines." },
	refoldDone = { "Your new build is folded. Streak kept.", "New folds, same streak.", "Refold done. Your streak survived." },
	vote = { "What's the next lesson? Vote!", "Pick the next mode.", "Vote for the next round." },
	nextRound = { "Next lesson: {m}", "Up next: {m}", "Next round: {m}" },
	voteSoon = { "Grading the round. Voting opens soon.", "Adding up the scores. Voting is coming.", "The teacher is marking papers. Voting soon." },
}

-- How a plane went down. Weapon kills by weapon id; crashes by what was hit (see THINGS); then the other ways.
Lines.weapons = {
	pellet = { "{k} riddled {v} with paper pellets", "{k} turned {v} into a hole-punch sample", "{v} took one paper pellet too many from {k}", "{k} peppered {v} with spitballs" },
	staple = { "{k} stapled {v} to the homework pile", "{k} pinned {v} to the bulletin board", "{v} got stapled shut by {k}", "{v} got filed away by {kp} stapler" },
	rubber = { "{k} snapped {v} out of the air with a rubber band", "{k} flicked {v} across the classroom", "{k} showed {v} why rubber bands are banned in class" },
	paperclip = { "{k} clipped {v} together for good", "{kp} paperclip found the gap in {vp} wings", "{k} clipped {v} to the pile of finished work" },
	eraser = { "{k} erased {v} like a wrong answer", "{k} rubbed {v} out of the sky", "{v} could not outrun {kp} eraser", "{v} got erased by {k}. Not even a smudge left" },
	pencil = { "{k} drew a line through {v}", "{v} met the sharp end of {kp} pencil", "{k} crossed {v} off the list", "{k} poked a hole in {vp} plan" },
}
Lines.ways = {
	folded = { "{k} folded {v}", "{k} crumpled {v} into a paper ball", "{k} sent {v} to the recycling bin", "{k} grounded {v}" },
	shot = { "{v} got crumpled in the crossfire", "{v} got knocked out of the air" },
	crash = { "{v} flew straight into the {t}", "{v} didn't see the {t} coming", "{v} crashed into the {t}" },
	chased = { "{v} hit the {t} running from {k}", "{k} chased {v} into the {t}", "{v} kept an eye on {k} and not on the {t}" },
	outOfLift = { "{v} ran out of Lift and drifted down to the floor", "{v} forgot to visit a fan", "{v} ran out of Lift halfway home" },
	outOfLiftChased = { "{k} kept {v} busy until {vp} Lift ran out", "{v} ran out of Lift running from {k}" },
	ram = { "{v} and {k} tried to use the same bit of sky", "{v} bumped wings with {k}", "{v} had a head-on with {k}" },
	fan = { "{v} went through a duct fan and came out as snow", "A duct fan chopped {v} into confetti", "{v} got sliced into paper strips by a duct fan" },
	bounds = { "{v} left class without a hall pass", "{v} flew out of the classroom and got marked absent", "{v} skipped class" },
	boundsChased = { "{k} chased {v} out of the classroom", "{v} fled from {k} all the way out of class" },
	unfolded = { "{vp} plane came unfolded", "{vp} plane lost its creases" },
	fresh = { "{v} crumpled up {vp} plane and started a clean sheet", "{v} traded {vp} plane for a fresh sheet", "{v} folded a brand new plane" },
	left = { "{v} left the round", "{v} packed up and went home" },
}

-- What a crash hit, matched against the hit part's name (lower case), first match wins. name = {t}; lines are extra
-- lines for that thing on top of the general crash lines.
local THINGS = {
	{ "^floor$", "classroom floor", { "{v} made an emergency landing on the classroom floor", "{v} became litter on the classroom floor", "{v} will need picking up off the floor" } },
	{ "^rug", "town streets", { "{v} parked in the middle of the road, nose first", "{v} crash-landed in the middle of town", "{v} became a speed bump on the town rug" } },
	{ "window", "window", { "{v} thought the window was open", "{v} flew into the window like a lost fly", "{v} left a smudge on the window" } },
	{ "^wall", "classroom wall", { "{v} tried to fly through the classroom wall", "{v} found the edge of the classroom", "{v} got stuck to the wall like a drawing" } },
	{ "ceiling%-?light", "ceiling light", { "{v} flew into the ceiling light like a moth", "{v} got too close to the light" } },
	{ "ceiling%-ring", "ring on the ceiling", { "{v} missed the hoop on the ceiling" } },
	{ "ceiling", "ceiling", { "{v} tested how high the ceiling is", "{v} got stuck to the ceiling like an old spitball" } },
	{ "chalkboard", "chalkboard", { "{v} crashed into the chalkboard and left a mark", "{v} got written off on the chalkboard" } },
	{ "chalkeraser", "chalk eraser", { "{v} flew into the chalk eraser and came out as chalk dust" } },
	{ "landing%-ring", "landing ring", { "{v} flew into the landing ring instead of through it" } },
	{ "runway", "desk runway", { "{v} came in too low and hit the runway" } },
	{ "desk", "desk", { "{v} crash-landed on somebody's desk", "{v} landed on a desk the hard way", "{v} turned a desk into a crash site" } },
	{ "chair", "chair", { "{v} got stuck under a chair like old gum", "{v} flew into a chair. The chair was fine" } },
	{ "bookshelf", "bookshelf", { "{v} got shelved", "{v} flew into the bookshelf and stayed for story time" } },
	{ "bulletin", "bulletin board", { "{v} got pinned to the bulletin board" } },
	{ "classroom%-door", "classroom door", { "{v} tried to leave through the classroom door" } },
	{ "globe", "globe", { "{v} flew into the globe and fell off the world" } },
	{ "worldmap", "world map", { "{v} flew off the edge of the world map" } },
	{ "planet|saturn|jupiter|earth|starmobile|thread", "planet mobile", { "{v} got tangled in the planet mobile", "{v} crashed into a planet. Science class is over" } },
	{ "clock%-tower", "Clock Tower", { "{v} ran out of time at the Clock Tower" } },
	{ "clock", "wall clock", { "{v} ran out of time against the wall clock" } },
	{ "plant", "classroom plant", { "{v} got lost in the classroom plant", "{v} became mulch for the classroom plant" } },
	{ "pencilcup", "pencil cup", { "{v} got sorted into the pencil cup" } },
	{ "cubby", "cubbies", { "{v} got put away in the cubbies" } },
	{ "backpack", "backpack", { "{v} got packed into a backpack and sent home" } },
	{ "papercrane", "paper crane", { "{v} lost a fight with a paper crane" } },
	{ "paper%-?boat", "paper boat", { "{v} crashed into a paper boat and sank" } },
	{ "fanbase", "fan stand", { "{v} flew into the stand of a classroom fan" } },
	{ "floor%-fan", "floor fan", { "{v} got blown apart by the floor fan" } },
	{ "^duct|vent", "air ducts", { "{v} got lost in the air ducts", "{v} took a wrong turn in the air ducts" } },
	{ "monorailtrain", "monorail", { "{v} missed the train by not missing it", "{v} got run over by the monorail", "{v} tried to board the monorail through the front" } },
	{ "monorail%-station%-south", "South Station", { "{v} got packed for lunch at the South Station" } },
	{ "monorail%-station%-north", "North Station", { "{v} got boxed in at the North Station" } },
	{ "monorail", "monorail track", { "{v} tripped over the monorail track", "{v} flew into a monorail pillar" } },
	{ "milk%-carton", "Milk Carton Tower", { "{v} spilled all over the Milk Carton Tower" } },
	{ "juice%-carton", "Juice Carton Tower", { "{v} got squeezed by the Juice Carton Tower" } },
	{ "cereal%-box", "Cereal Box Tower", { "{v} became breakfast at the Cereal Box Tower" } },
	{ "crayon%-box", "Crayon Box Tower", { "{v} got colored in by the Crayon Box Tower" } },
	{ "tissue%-box", "Tissue Box Tower", { "{v} got sneezed on by the Tissue Box Tower" } },
	{ "tape%-roll", "Tape Roll Tower", { "{v} got stuck to the Tape Roll Tower" } },
	{ "tape%-dispenser", "Tape Dispenser Depot", { "{v} got taped up at the Tape Dispenser Depot" } },
	{ "glue", "Glue Tower", { "{v} got glued to the Glue Tower" } },
	{ "notebook", "Notebook Tower", { "{v} became a page in the Notebook Tower" } },
	{ "book%-apartments", "Book Apartments", { "{v} closed the book on {vp} flight at the Book Apartments" } },
	{ "book%-stack%-garden", "Book Stack Garden", { "{v} got checked out at the Book Stack Garden" } },
	{ "book%-stack%-lookout", "Book Stack Lookout", { "{v} got checked out at the Book Stack Lookout" } },
	{ "book%-stack%-spire", "Book Stack Spire", { "{v} closed the book on {vp} flight at the Book Stack Spire" } },
	{ "open%-book", "Open Book Hall", { "{v} got stuck between the pages of Open Book Hall" } },
	{ "porthole%-book", "Porthole Book Tower", { "{v} missed the porthole in the Porthole Book Tower" } },
	{ "ring%-binder", "Ring Binder Tower", { "{v} got filed away in the Ring Binder Tower" } },
	{ "sticky%-note", "Sticky Note Tower", { "{v} became a reminder on the Sticky Note Tower" } },
	{ "eraser%-hall", "Eraser Hall", { "{v} got rubbed out by Eraser Hall" } },
	{ "sharpener", "Sharpener Tower", { "{v} got sharpened at the Sharpener Tower" } },
	{ "stapler", "Stapler Offices", { "{v} got stapled to the Stapler Offices" } },
	{ "scissors", "Scissors Gate House", { "{v} got cut out by the Scissors Gate House" } },
	{ "pencil%-case%-hall", "Pencil Case Hall", { "{v} got zipped into Pencil Case Hall" } },
	{ "pencil%-case%-bridge", "Pencil Case Bridge", { "{v} got zipped into the Pencil Case Bridge" } },
	{ "pencil%-cup", "Pencil Cup Tower", { "{v} got pencilled in at the Pencil Cup Tower" } },
	{ "pencil%-pillar", "Pencil Pillar Tower", { "{v} got pencilled in at the Pencil Pillar Tower" } },
	{ "pencil%-tin", "Pencil Tin Tower", { "{v} got put away in the Pencil Tin Tower" } },
	{ "paint%-jar", "Paint Jar Tower", { "{v} got painted onto the Paint Jar Tower" } },
	{ "paint%-palette", "Paint Palette School", { "{v} added a new color to the Paint Palette School" } },
	{ "chalk%-box", "Chalk Box Depot", { "{v} turned to chalk dust at the Chalk Box Depot" } },
	{ "abacus", "Abacus Hall", { "{v} counted the beads at Abacus Hall, up close" } },
	{ "jenga", "Jenga Tower", { "{v} pulled the wrong block at the Jenga Tower" } },
	{ "log%-cabin", "Log Cabin Tower", { "{v} went camping at the Log Cabin Tower, nose first" } },
	{ "stacking%-cup", "Stacking Cup Tower", { "{v} got stacked at the Stacking Cup Tower" } },
	{ "egg%-carton", "Egg Carton Market", { "{v} got scrambled at the Egg Carton Market" } },
	{ "sweet%-shop", "Sweet Shop", { "{v} stopped at the Sweet Shop a bit too fast" } },
	{ "shoebox", "Shoebox Hall", { "{v} got boxed up at Shoebox Hall" } },
	{ "block%-arch", "Block Arch", { "{v} missed the hole in the Block Arch" } },
	{ "ruler%-stilt", "Ruler Stilt Tower", { "{v} got measured by the Ruler Stilt Tower and came up short" } },
	{ "bell%-tower", "Bell Tower", { "{v} rang the Bell Tower with {vp} nose" } },
	{ "banner%-tower", "Banner Tower", {} },
	{ "gateway", "Gateway Towers", {} },
	{ "water%-tower", "Brick Water Tower", {} },
	{ "tube%-tower", "Tube Tower", {} },
	{ "cardboard%-tube", "cardboard tube", { "{v} got stuck in a cardboard tube" } },
	{ "paper%-bunting|paper%-chain", "paper chain", { "{v} got tangled in the paper chain" } },
	{ "tree", "tree", { "{v} got stuck in a tree like a lost kite", "{v} became a new leaf on a tree" } },
	{ "street%-lamp", "street lamp", { "{v} hugged a street lamp", "{v} didn't see the street lamp" } },
	{ "bus", "toy bus", { "{v} missed the bus by hitting it" } },
	{ "car%-|truck|tugboat|rowing", "toy car", { "{v} got caught in traffic", "{v} got run over by a toy car" } },
	{ "basketball", "basketball hoop", { "{v} tried to dunk on the basketball hoop. The hoop won" } },
	{ "slide|swing|seesaw|jungle|monkey|merry|spring%-rider|playground|crawl", "playground", { "{v} crashed at the playground and has to sit out recess", "{v} took the playground too seriously" } },
	{ "fountain|ducks|boat", "fountain", { "{v} went for a swim in the fountain", "{v} scared the ducks and fell in" } },
	{ "^crane|digger|cement|site%-|gravel|sand%-pile|pipe%-stack|plank|brick%-stack|barrier|cone", "building site", { "{v} wandered into the building site without a hard hat" } },
	{ "court|grass|blacktop|mainbuilding|wing|mulch|sand|net|volleyball|chalk", "schoolyard", { "{v} went out for recess early", "{v} crash-landed on the schoolyard" } },
	{ "house|station|boathouse|bench|picnic|fence", "town", { "{v} crash-landed in the middle of town" } },
}

-- {t} and the extra lines for a hit part's name ("milk-carton-tower/3-ground-floor-back-left" -> Milk Carton Tower).
function Lines.thing(partName)
	local name = string.lower(partName or "")
	for _, entry in THINGS do
		for _, pattern in string.split(entry[1], "|") do
			if name:find(pattern) then return entry[2], entry[3] end
		end
	end
	return nil, {}
end

local last = {}
local function fill(line, v, k, t, m)
	local function possessive(name) return name == "you" and "your" or name .. "'s" end
	local text = line:gsub("{vp}", possessive(v or "")):gsub("{kp}", possessive(k or "")):gsub("{v}", v or "")
		:gsub("{k}", k or ""):gsub("{t}", t or ""):gsub("{m}", m or "")
	-- A line that starts with the reader's own name starts with a capital: "You ...", "Your ...".
	return (text:gsub("^you", "You"))
end
local function choose(key, set)
	local i = math.random(#set)
	if #set > 1 and i == last[key] then i = i % #set + 1 end
	last[key] = i
	return set[i]
end

function Lines.pick(name, m)
	return fill(choose(name, assert(Lines.sets[name], name)), nil, nil, nil, m)
end

-- The same line for the same seed, for screens that redraw often (a fresh pick each redraw would flicker).
function Lines.stable(name, seed, m)
	local set = assert(Lines.sets[name], name)
	return fill(set[math.floor(seed) % #set + 1], nil, nil, nil, m)
end

-- Whether `text` is one of a simple set's lines (to keep a line that is already showing, or play a sound).
function Lines.is(name, text)
	return table.find(assert(Lines.sets[name], name), text) ~= nil
end

-- Which death line fits. how = { kind = "weapon"|"crash"|"fan"|"ram"|"bounds"|"unfolded"|"fresh"|"left",
-- weapon = id, part = hit part name, outOfLift = bool, other = the rammed plane's name }; killer = the credited
-- folder's name (or nil). Returns the line with its tokens still in, and {t}.
function Lines.plan(how, killer)
	local kind = how and how.kind or "crash"
	local set, key, t = nil, kind, nil
	if kind == "weapon" then
		set = killer and (Lines.weapons[how.weapon or ""] or Lines.ways.folded) or Lines.ways.shot
		key = "weapon:" .. tostring(how.weapon)
	elseif kind == "crash" and how.outOfLift then
		set, key = killer and Lines.ways.outOfLiftChased or Lines.ways.outOfLift, killer and "outOfLiftChased" or "outOfLift"
	elseif kind == "crash" or kind == "fan" then
		local extra
		if kind == "fan" then t, extra = "duct fan", Lines.ways.fan else t, extra = Lines.thing(how.part) end
		if killer then
			set, key = Lines.ways.chased, "chased"
			t = t or "wall"
		else
			-- The thing's own lines, plus the general ones when we know its name.
			set = table.clone(extra)
			if t and kind == "crash" then table.move(Lines.ways.crash, 1, #Lines.ways.crash, #set + 1, set) end
			if #set == 0 then set = { "{v} flew into something solid" } end
			key = "crash:" .. tostring(t)
		end
	elseif kind == "ram" then
		set = Lines.ways.ram
	elseif kind == "bounds" and killer then
		set, key = Lines.ways.boundsChased, "boundsChased"
	else
		set = Lines.ways[kind] or Lines.ways.shot
	end
	return choose(key, set), t
end

-- The death line with names filled in. A `how` that already carries a plan (template, t) keeps it, so the
-- victim's top note and everyone's kill feed say the same thing.
function Lines.death(how, victim, killer)
	local template, t = how and how.template, how and how.t
	if not template then template, t = Lines.plan(how, killer) end
	local k = how and how.kind == "ram" and (how.other or killer or "another plane") or killer
	return fill(template, victim, k, t)
end

return Lines
