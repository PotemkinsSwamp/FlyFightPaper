-- A Hangar redraw describes the current page. Keep the same GUI instances, input handlers
-- and text styling until an item actually leaves that page.
local PaperUI = require(script.Parent.PaperUI)
local Widgets = {}

function Widgets.new()
	local byParent, generation = {}, 0
	local ui = {}
	local function entry(parent, name, kind)
		local siblings = byParent[parent]
		if not siblings then siblings = {}; byParent[parent] = siblings end
		local e = siblings[name]
		if e and (e.kind ~= kind or not e.node.Parent) then
			e.node:Destroy()
			e = nil
		end
		if not e then e = {kind = kind}; siblings[name] = e end
		e.seen = generation
		return e
	end

	function ui.begin() generation += 1 end
	function ui.finish()
		for parent, siblings in byParent do
			for name, e in siblings do
				if e.seen ~= generation then
					e.node:Destroy()
					siblings[name] = nil
				end
			end
			if not next(siblings) then byParent[parent] = nil end
		end
	end

	function ui.instance(parent, name, kind)
		local e = entry(parent, name, kind)
		if e.node then return e.node, false end
		e.node = Instance.new(kind)
		e.node.Name, e.node.Parent = name, parent
		return e.node, true
	end

	function ui.image(parent, name, id, x, y, w, h, rotation)
		local e = entry(parent, name, "image")
		if not e.node then
			e.node = PaperUI.image(parent, name, id, x, y, w, h, rotation)
		else
			e.node.Image = id
			e.node.Position, e.node.Size = UDim2.fromOffset(x+w/2, y+h/2), UDim2.fromOffset(w,h)
			e.node.Rotation = rotation or 0
		end
		return e.node
	end

	function ui.words(parent, name, value, x, y, w, h, size)
		local e = entry(parent, name, "words")
		if not e.node then
			e.node = PaperUI.words(parent, name, value, x, y, w, h, size)
		else
			e.node.Text = value
			e.node.Position, e.node.Size = UDim2.fromOffset(x,y), UDim2.fromOffset(w,h)
			if e.fontSize ~= size then e.node.TextSize = size end
		end
		e.fontSize = size
		return e.node
	end

	function ui.button(parent, name, id, label, x, y, w, h, rotation, callback, size)
		local e = entry(parent, name, "button")
		e.action = callback
		local bounds = UDim2.fromOffset(w,h)
		if not e.node then
			e.node = PaperUI.button(parent, name, id, label, x,y,w,h,rotation, function() e.action() end, size, true)
		else
			e.node.Image, e.node.Label.Text = id, label
			e.node.Position = UDim2.fromOffset(x+w/2,y+h/2)
			-- Leave the button's hover/press tween alone during profile refreshes.
			if e.bounds ~= bounds or e.rotation ~= rotation then
				PaperUI.set(e.node, {Size = bounds, Rotation = rotation or 0})
			end
			if e.fontSize ~= size then e.node.Label.TextSize = size or 80 end
		end
		e.bounds, e.rotation, e.fontSize = bounds, rotation, size
		return e.node
	end

	function ui.robuxButton(parent, name, x,y,w,h,label,price,size,callback)
		local e = entry(parent, name, "robux")
		e.action = callback
		if not e.node then
			e.node = PaperUI.robuxButton(parent, name,x,y,w,h,label,price,size,function() e.action() end)
		end
		e.node.Price.Word3.Text = tostring(price)
		return e.node
	end
	return ui
end

return Widgets
