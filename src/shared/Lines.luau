-- Rotating event lines (Alan 2026-10-17, docs/decisions/2026-10-17-fresh-rotating-lines.md): every message about
-- something happening in the game has a few short paper lines, and one is picked at random, never the same one twice
-- in a row. Waits are described, not counted. Lines with %s take names (kill feed, next mode).
local Lines = {}

Lines.sets = {
	-- Your plane goes down (the wait for the next one is described, not counted).
	shotDown = {
		"Shot down! A fresh plane is being folded.",
		"Torn to bits! Folding you a new plane.",
		"Your plane got crumpled. A new one is on the way.",
		"Paper scraps everywhere! Your next plane is being folded.",
		"Down you go! Folding a fresh plane for you.",
	},
	crashed = {
		"Crash! Folding you a new plane.",
		"Bonk! A new plane is on the way.",
		"Splat! Smoothing out a fresh sheet for you.",
		"Nose first! Your next plane is being folded.",
		"Crumpled! A fresh plane is coming.",
	},
	leftRoom = {
		"You flew out of the room! Folding a new plane.",
		"Out the window! A fresh plane is being folded.",
		"Too far away! Your next plane is being folded.",
	},
	wobbleDown = {
		"Your plane went all wobbly! Folding a new one.",
		"Wobble, wobble, flop! A fresh plane is coming.",
	},
	freshPlane = {
		"Folding a fresh plane...",
		"New sheet, new plane! Folding now.",
		"A crisp new plane is coming up.",
	},
	-- Flying.
	takeoff = { "Taking off!", "Up, up and away!", "Wheee! Off the desk!", "Launch! Off you fly." },
	scraping = { "Scraping! Turn away!", "Ouch! Steer off the wall!", "Scritch-scratch! Pull away!" },
	fanClip = { "Clipped by a fan!", "Whack! The fan got you.", "Fan blade! Ouch!" },
	updraft = { "Updraft! Lift going up.", "Whoosh! The fan fills your Lift.", "Riding the breeze! Lift rising." },
	tailwind = { "Tailwind! Zoom!", "Wind at your back! Speeding up.", "Whoosh! Free speed!" },
	headwind = { "Headwind! Slowing down.", "Wind in your face! You're slower here.", "Pushing into the breeze..." },
	speedPickup = { "Speed boost!", "Zoom! Speed up!", "Super speedy!" },
	turnBack = { "Turn back! You're leaving the room.", "Come back inside, quick!", "Too far! Head back to the room." },
	wobble = { "Whoa! Your plane got put back on course.", "Wobble! Back on course." },
	-- Landing at your desk.
	deskBusy = {
		"Desk busy! Wait at the marker for your turn.",
		"Someone's landing. Circle the marker and wait your turn.",
		"Your pad is busy. Hang by the marker.",
	},
	padFree = { "Your pad is free! Fly through the ring.", "Clear to land! Aim for the ring.", "Your turn! Fly through the ring to land." },
	padWait = { "Waiting for your desk to clear...", "Your desk is busy. Your new plane is waiting to launch." },
	atDesk = { "Ready at your desk!", "Your plane is ready. Launch when you are!", "Fresh plane, all folded and ready." },
	landing = { "Coming in to land...", "Gliding down to your desk.", "Landing gently..." },
	landed = { "Landed! Topping up your Lift.", "Touchdown! Filling your Lift back up.", "Safe at your desk. Lift is filling up." },
	-- Desk service.
	refilling = { "Filling your Lift...", "Topping up your Lift...", "Refilling your Lift..." },
	repairing = { "Taping up your plane. Each patch adds wear.", "Patching the holes. Patches add wear.", "Fixing your plane. Fixes add wear." },
	serviceDone = { "All set! Ready to launch.", "Done! Your plane is ready.", "Fixed up and ready to fly!" },
	refolding = { "Refolding your plane...", "Folding your new build...", "Crease, fold, fold... building your plane." },
	refoldDone = { "Refold done! Streak kept.", "Fresh folds, same streak!", "New build ready. Your streak is safe!" },
	-- Kill feed (the victim's name comes last, or first in a crash, so "You"/"you" lines get the blue pin).
	fold = { "%s folded %s", "%s knocked down %s", "%s crumpled %s", "%s shredded %s", "%s tore up %s", "%s grounded %s" },
	crash = { "%s crashed", "%s went splat", "%s took a nosedive", "%s got crumpled" },
	-- Between rounds (results sheet).
	vote = { "Pick the next mode!", "Vote for the next round!", "What's next? You choose!" },
	nextRound = { "Next up: %s!", "Get ready: %s!", "Next round: %s" },
	voteSoon = { "Voting opens soon.", "Scores are in! Voting starts soon.", "Catch your breath. Voting is coming." },
}

local last = {}
local function fill(line, ...)
	return select("#", ...) > 0 and string.format(line, ...) or line
end

function Lines.pick(name, ...)
	local set = assert(Lines.sets[name], name)
	local i = math.random(#set)
	if #set > 1 and i == last[name] then i = i % #set + 1 end
	last[name] = i
	return fill(set[i], ...)
end

-- The same line for the same seed, for screens that redraw often (a fresh pick each redraw would flicker).
function Lines.stable(name, seed, ...)
	local set = assert(Lines.sets[name], name)
	return fill(set[math.floor(seed) % #set + 1], ...)
end

-- Whether `text` is one of a set's lines (no %s sets), e.g. to play the "service done" sound.
function Lines.is(name, text)
	return table.find(assert(Lines.sets[name], name), text) ~= nil
end

return Lines
