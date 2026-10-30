-- Phone button layouts (docs/plan/CONTROLS-PLAN.md, Alan 2026-10-30): players drag FIRE, 2, BOOST and BRAKE where they
-- like (TouchControls' editor) and the spots save with their settings as shares of the screen (0-1), so a layout fits
-- any phone or tablet. Pure numbers, so the unit tests can check the rules; buttons are circles (`sizes` = diameter).
local TouchLayout = {}

TouchLayout.BUTTONS = { "Fire", "Fire2", "Boost", "Brake" }
TouchLayout.GAP = 8 -- points kept clear between two buttons (the closest the game's own layout puts them)

-- Whether button `name` with its middle at `at` (points) is allowed: whole on the screen's right half (the left half
-- is the steering stick's), below Roblox's top bar (`top` points), and clear of every other button in `spots`.
function TouchLayout.fits(name, at, spots, sizes, view, top)
	local r = sizes[name] / 2
	if at.X - r < view.X / 2 or at.X + r > view.X or at.Y - r < top or at.Y + r > view.Y then return false end
	for other, spot in spots do
		if other ~= name and (spot - at).Magnitude < r + sizes[other] / 2 + TouchLayout.GAP then return false end
	end
	return true
end

-- Pulled back onto the allowed area (the right half, below the top bar) if the screen's shape put it outside.
function TouchLayout.clamp(name, at, sizes, view, top)
	local r = sizes[name] / 2
	return Vector2.new(math.clamp(at.X, view.X / 2 + r, math.max(view.X / 2 + r, view.X - r)), math.clamp(at.Y, top + r, math.max(top + r, view.Y - r)))
end

-- Where each button goes: the saved shares (`saved[name] = {x, y}`) where they fit, else the game's spot
-- (`defaults[name]`, points). A saved spot that clashes with another button goes back to its default, one at a time,
-- until nothing clashes (the defaults never clash with each other).
function TouchLayout.place(saved, defaults, sizes, view, top)
	local spots, moved = {}, {}
	for _, name in TouchLayout.BUTTONS do
		local share = saved and saved[name]
		if share then
			spots[name], moved[name] = TouchLayout.clamp(name, Vector2.new(share.x * view.X, share.y * view.Y), sizes, view, top), true
		else
			spots[name] = defaults[name]
		end
	end
	local clash = true
	while clash do
		clash = false
		for _, name in TouchLayout.BUTTONS do
			if moved[name] and not TouchLayout.fits(name, spots[name], spots, sizes, view, top) then
				spots[name], moved[name], clash = defaults[name], nil, true
				break
			end
		end
	end
	return spots
end

-- The shares to save for the buttons the player moved (`spots` in points), rounded to keep the save small.
function TouchLayout.shares(spots, view)
	local saved = {}
	for name, at in spots do
		saved[name] = { x = math.round(at.X / view.X * 1000) / 1000, y = math.round(at.Y / view.Y * 1000) / 1000 }
	end
	return saved
end

-- The save check (ProfileSchema): nil, or only the four buttons, each {x, y} with numbers from 0 to 1.
function TouchLayout.valid(saved)
	if saved == nil then return true end
	if type(saved) ~= "table" then return false end
	for name, share in saved do
		if not table.find(TouchLayout.BUTTONS, name) or type(share) ~= "table" then return false end
		for key, value in share do
			if (key ~= "x" and key ~= "y") or type(value) ~= "number" or value ~= value or value < 0 or value > 1 then return false end
		end
		if share.x == nil or share.y == nil then return false end
	end
	return true
end

return TouchLayout
