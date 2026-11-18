-- The shelf, the moving lid and the held prize pose all use the same chest prints.
local Assets = require(game.ReplicatedStorage.FlyFightPaper.Shared.UIAssets)
local Content = game:GetService("ContentProvider")
local Artwork = {}
local icons = {
	paper=Vector2.new(0,0), sticker=Vector2.new(512,0),
	blue_ribbon=Vector2.new(0,512), golden_star=Vector2.new(512,512),
}

local function apply(image, print, base)
	image.Image = print.image or Assets.hangarShelf.chestAtlas
	image.ImageRectOffset = if print.image then Vector2.zero else icons[base]
	image.ImageRectSize = if print.image then Vector2.zero else Vector2.new(512,512)
end

function Artwork.picture(image, chest)
	local prints = Assets.hangarShelf.chestPrints[chest.id]
	apply(image, prints.closed, chest.base or chest.id)
	image.ScaleType = Enum.ScaleType.Fit
	return image
end

local warmed = {}
function Artwork.prepare(chest)
	local prints = Assets.hangarShelf.chestPrints[chest.id]
	if warmed[prints] then return end
	warmed[prints] = true
	task.spawn(function()
		local ids = {prints.closed.image or Assets.hangarShelf.chestAtlas, prints.half.image, prints.open.image}
		local images = {}
		for _, id in ids do
			local image = Instance.new("ImageLabel")
			image.Image = id
			table.insert(images, image)
		end
		local ok = pcall(function()
			Content:PreloadAsync(images, function(_, status)
				if status ~= Enum.AssetFetchStatus.Success then warmed[prints] = nil end
			end)
		end)
		for _, image in images do image:Destroy() end
		if not ok then warmed[prints] = nil end
	end)
end

local function holder(parent, name, order)
	local f = Instance.new("Frame")
	f.Name, f.BorderSizePixel, f.BackgroundTransparency = name, 0, 1
	f.ZIndex, f.Parent = order, parent
	return f
end

local function printImage(parent, name, print, base)
	local image = Instance.new("ImageLabel")
	image.Name, image.BackgroundTransparency, image.ScaleType = name, 1, Enum.ScaleType.Stretch
	apply(image, print, base)
	image.Parent = parent
	return image
end

-- Each standalone print is 1024 square. The original closed prints occupy 512px
-- tiles. Sample the band directly so rotated parents never disable GUI clipping.
local function band(parent, name, print, base, first, last)
	local image = printImage(parent, name, print, base)
	local side = if print.image then 1024 else 512
	local offset = if print.image then Vector2.zero else icons[base]
	local y0, y1 = math.round(first*side), math.round(last*side)
	image.ImageRectOffset = offset + Vector2.new(0, y0)
	image.ImageRectSize = Vector2.new(side, math.max(1, y1-y0))
	return image
end

local function pose(parent, name, print, base, fold, order)
	-- Dimensions are in body widths. The back rim is y=0, the body centre is x=0.
	local width = 1/(print.right-print.left)
	local x = -.5-print.left*width
	local top = (print.top-print.hinge)*width
	local crease = print.top + fold*(print.hinge-print.top)
	local full = printImage(parent, name, print, base)
	full.ZIndex = order
	full.Position = UDim2.fromScale(x, -print.hinge*width)
	full.Size = UDim2.fromScale(width,width)
	full.ImageTransparency = .995

	local moving = holder(parent,name.."Panels",order)
	moving.Size, moving.Visible = UDim2.fromScale(1,1), false
	return {full=full, moving=moving, x=x, width=width, top=top,
		seam=(crease-print.hinge)*width, depth=(1-print.hinge)*width,
		foot=(print.foot-print.hinge)*width,
		crown=band(moving,"Outside",print,base,print.top,crease),
		lining=band(moving,"Inside",print,base,crease,print.hinge),
		body=band(moving,"Box",print,base,print.hinge,1)}
end

local function placeBand(part, x, y, w, h, transparency)
	part.Position = UDim2.fromScale(x,y)
	part.Size = UDim2.fromScale(w,h)
	part.ImageTransparency = transparency
end

local function drawPanels(p, top, seam, transparency)
	p.moving.Visible = true
	placeBand(p.crown,p.x,top,p.width,seam-top,transparency)
	placeBand(p.lining,p.x,seam,p.width,-seam,transparency)
	placeBand(p.body,p.x,0,p.width,p.depth,transparency)
end

-- The front stays anchored while the exterior turns away and the real inner lining
-- comes into view. The middle drawing supplies the side profile and first view into the box.
function Artwork.rig(stage, chest)
	local prints, base = Assets.hangarShelf.chestPrints[chest.id], chest.base or chest.id
	local pivot = holder(stage,"HingedChest",2)
	pivot.AnchorPoint = Vector2.new(.5,.5)
	local origin = holder(pivot,"RearRail",1)
	origin.Size, origin.Position = UDim2.fromScale(1,1), UDim2.fromScale(.5,.5)
	local closed = pose(origin,"ClosedChest",prints.closed,base,.86,1)
	local half = pose(origin,"HalfOpenChest",prints.half,base,.53,2)
	local open = pose(origin,"OpenChest",prints.open,base,.15,3)
	local poses = {closed,half,open}
	local rig = {open=open.full,top=open.top,foot=open.foot,closedFoot=closed.foot}
	local held
	local openReady, halfReady = false, false
	function rig.draw(x, y, width, tilt, progress)
		pivot.Size, pivot.Position = UDim2.fromOffset(width,width), UDim2.fromOffset(x,y)
		pivot.Rotation = tilt
		openReady = openReady or open.full.IsLoaded
		halfReady = halfReady or half.full.IsLoaded
		local still = if progress<=0 or not openReady then closed elseif progress>=1 then open else nil
		if still then
			if still ~= held then
				for _,p in poses do
					p.moving.Visible = false
					-- Keep the next full texture drawable while Roblox fetches it.
					p.full.Visible = still==closed or p==still
					p.full.ImageTransparency = if p==still then 0 else .995
				end
				held=still
			end
			return
		end
		held=nil
		local first, second, u = closed, open, progress
		if halfReady then
			if progress < .5 then first,second,u=closed,half,progress*2
			else first,second,u=half,open,(progress-.5)*2 end
		end
		local top=first.top+(second.top-first.top)*u
		local seam=first.seam+(second.seam-first.seam)*u
		for _,p in poses do
			p.full.Visible=false
			if p~=first and p~=second then p.moving.Visible=false end
		end
		-- Change print as the lid passes the middle of this arc. A short overlap
		-- keeps the solid paper edge from looking like two translucent lids.
		local exposure = math.clamp((u - .40) / .20, 0, 1)
		if exposure < 1 then
			drawPanels(first, top, seam, 0)
		else
			first.moving.Visible = false
		end
		if exposure > 0 then
			drawPanels(second, top, seam, 1 - exposure)
		else
			second.moving.Visible = false
		end
	end
	return rig
end

return Artwork
