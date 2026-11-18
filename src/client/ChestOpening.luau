-- Both the shop and the binder show the saved prize through this one opening.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Root = game.ReplicatedStorage:WaitForChild("FlyFightPaper")
local Assets = require(Root.Shared.UIAssets)
local Aircraft = require(Root.Shared.Aircraft)
local Catalog = require(Root.Shared.Catalog).new(require(Root.Generated.Catalog), require(Root.Generated.Gameplay))
local PaperUI = require(script.Parent.PaperUI)
local Audio = require(script.Parent.Audio)
local PlaneLooks = require(script.Parent.PlaneLooks)
local TrailPreview = require(script.Parent.HangarTrailPreview)
local Opening = {}

-- Pixel measurements on the closed 512-square prints. The cut follows the upper edge of the belt
-- and goes around the clasp, rosette or star so each stays attached to the front when the lid pops.
local pieces = {
	paper = {offset = Vector2.new(0, 0), corner = {138, 263}, rear = {350, 179}, edge = {
		{0, 213}, {138, 263}, {264, 253}, {268, 232}, {353, 226}, {365, 231}, {368, 246}, {512, 229}}},
	sticker = {offset = Vector2.new(512, 0), corner = {116, 261}, rear = {347, 178}, edge = {
		{0, 217}, {116, 261}, {245, 251}, {248, 238}, {329, 232}, {341, 237}, {344, 245}, {512, 229}}},
	blue_ribbon = {offset = Vector2.new(0, 512), corner = {143, 238}, rear = {353, 155}, edge = {
		{0, 187}, {143, 238}, {228, 229}, {237, 202}, {257, 178}, {287, 158}, {320, 153}, {348, 159}, {375, 177}, {398, 200}, {409, 215}, {512, 207}}},
	golden_star = {offset = Vector2.new(512, 512), corner = {126, 233}, rear = {344, 151}, edge = {
		{0, 191}, {126, 233}, {276, 221}, {300, 173}, {306, 167}, {312, 171}, {335, 215}, {512, 203}}},
}
local TIER = { common = "Common", rare = "Rare", legendary = "Legendary", mythical = "Mythical" }
local TINT = { common = Color3.fromRGB(222, 229, 217), rare = Color3.fromRGB(187, 219, 251),
	legendary = Color3.fromRGB(255, 218, 134), mythical = Color3.fromRGB(227, 193, 248) }
local SIZE = 760
local lastSequence, queue, active = 0, {}, false
local cover, sheet

local function atlas(chest)
	return chest.family == "trail" and Assets.hangarShelf.trailChestAtlas or Assets.hangarShelf.chestAtlas
end
function Opening.picture(image, chest)
	local shape = pieces[chest.base or chest.id]
	image.Image, image.ImageRectOffset, image.ImageRectSize = atlas(chest), shape.offset, Vector2.new(512, 512)
	image.ScaleType = Enum.ScaleType.Fit
	return image
end

local function frame(parent, name, z)
	local f = Instance.new("Frame")
	f.Name, f.BackgroundTransparency, f.BorderSizePixel, f.ZIndex = name, 1, 0, z
	f.Parent = parent
	return f
end

-- The two complimentary gradient masks share exactly the same print, as on the gift box.
local function cut(parent, texture, shape, above)
	for i = 2, #shape.edge do
		local a, b = shape.edge[i-1], shape.edge[i]
		local width, delta = b[1] - a[1], b[2] - a[2]
		local strip = Instance.new("ImageLabel")
		strip.Name, strip.BackgroundTransparency, strip.Image = "Fold", 1, texture
		strip.ScaleType = Enum.ScaleType.Stretch
		strip.ImageRectOffset = shape.offset + Vector2.new(a[1], 0)
		strip.ImageRectSize = Vector2.new(width, 512)
		strip.Position, strip.Size = UDim2.fromScale(a[1]/512, 0), UDim2.fromScale(width/512, 1)
		local gradient = Instance.new("UIGradient")
		local normal = Vector2.new(-delta, width).Unit
		local length = math.min(width / math.abs(normal.X), 512 / normal.Y)
		local at = math.clamp(0.5 + ((a[2] + b[2])/2 - 256) * normal.Y / length, 0.001, 0.998)
		gradient.Rotation = math.deg(math.atan2(normal.Y, normal.X))
		local first, last = if above then 0 else 1, if above then 1 else 0
		gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, first),
			NumberSequenceKeypoint.new(at, first), NumberSequenceKeypoint.new(at + 0.001, last), NumberSequenceKeypoint.new(1, last)})
		gradient.Parent, strip.Parent = strip, parent
	end
end

local function mouth(parent, shape)
	-- Draw the back wall of the open box in shadow using folded cardboard from the gift box art.
	-- Its front lies behind the real printed face, including the clasps that stick up over the rim.
	local left = shape.corner[1] < 130 and 22 or 35
	local right = shape.corner[1] < 130 and 465 or 480
	local frontX, frontY = shape.corner[1], shape.corner[2]
	local rearX, rearY = shape.rear[1], shape.rear[2]
	local leftY, rightY = frontY - 39, frontY - 23
	local function height(x, middleX, middleY)
		if x < middleX then return leftY + (middleY-leftY)*(x-left)/(middleX-left) end
		return middleY + (rightY-middleY)*(x-middleX)/(right-middleX)
	end
	for x = left, right - 1, 7 do
		local w = math.min(7, right-x)
		local y = height(x+w/2, rearX, rearY)
		local bottom = height(x+w/2, frontX, frontY)
		local inner = Instance.new("ImageLabel")
		inner.Name, inner.Image, inner.ScaleType = "Lining", Assets.shop.iconGiftBox, Enum.ScaleType.Stretch
		inner.BackgroundColor3, inner.BorderSizePixel = Color3.fromRGB(62, 44, 49), 0
		inner.ImageRectOffset, inner.ImageRectSize = Vector2.new(201+(x-left)%86, 406), Vector2.new(w, 96)
		inner.Position, inner.Size = UDim2.fromScale(x/512, y/512), UDim2.fromScale((w+0.4)/512, math.max(1,bottom-y+8)/512)
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(185, 156, 121)),
			ColorSequenceKeypoint.new(0.08,Color3.fromRGB(78, 65, 65)),ColorSequenceKeypoint.new(1,Color3.fromRGB(44, 37, 45))})
		gradient.Rotation, gradient.Parent, inner.Parent = 90, inner, parent
	end
end

local function makePreview(view, item)
	local world, camera = Instance.new("WorldModel"), Instance.new("Camera")
	world.Parent, camera.Parent, view.CurrentCamera = view, view, camera
	local model = Instance.new("Model")
	model.Name, model.Parent = "PrizePlane", world
	if not Aircraft.build(model, Catalog:starterLoadout(), Catalog, true) then return nil end
	if item.kind == "skin" and not PlaneLooks.dressPreview(model, item.id) then return nil end
	if not model.Parent then return nil end
	local box, size = model:GetBoundingBox()
	local trail = item.kind == "trail" and TrailPreview.new(world, model, item.id) or nil
	local look = box.Position
	if trail then look = look:Lerp(trail.tail + Vector3.new(0,0,trail.length), 0.48) end
	camera.FieldOfView = 30
	local reach = math.max(size.X, size.Z)
	local distance = trail and (size.Z + trail.length) * 1.55 or reach * 1.9
	local function aim(t)
		local yaw = trail and 0.55 or 0.74 + t * 0.3
		local pitch = trail and -0.71 or -0.49
		camera.CFrame = CFrame.new(look)*CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)*CFrame.new(0,0,distance)
	end
	aim(0)
	if trail then view.Destroying:Connect(function() trail:destroy() end) end
	ContentProvider:PreloadAsync({model})
	if not view.Parent then return nil end
	return function(dt,t)
		aim(t)
		if trail then trail:step(dt,camera) end
	end
end

local function ease(x)
	x=math.clamp(x,0,1)
	return x*x*(3-2*x)
end
local function centered(label)
	label.TextXAlignment = Enum.TextXAlignment.Center
	return label
end

local startNext
local function showPrize(request)
	local player = Players.LocalPlayer
	if not cover then
		cover, sheet = PaperUI.screen(player:WaitForChild("PlayerGui"), "ChestOpening", {})
		cover.Parent.DisplayOrder, cover.BackgroundTransparency, cover.Active = 28, 1, true
		local dim = Instance.new("TextButton")
		dim.Name, dim.Text, dim.AutoButtonColor, dim.BorderSizePixel = "Backdrop", "", false, 0
		dim.BackgroundColor3, dim.BackgroundTransparency = Color3.fromRGB(26,21,29), 0.28
		dim.Size, dim.ZIndex, dim.Parent, sheet.ZIndex = UDim2.fromScale(1,1), 0, cover, 1
	end
	local stage = frame(sheet,"OpeningStage",1)
	stage.Size, cover.Visible = UDim2.fromScale(1,1), true
	local chest, item = request.chest, request.item
	local shape, texture = pieces[chest.base or chest.id], atlas(chest)
	local closed = Opening.picture(PaperUI.image(stage,"ClosedChest",texture,0,0,SIZE,SIZE),chest)
	closed.ZIndex = 6
	local inside, lid, body = frame(stage,"Inside",2), frame(stage,"Lid",3), frame(stage,"Front",6)
	for _, group in {inside,lid,body} do group.AnchorPoint=Vector2.new(.5,.5); group.Size=UDim2.fromOffset(SIZE,SIZE); group.Visible=false end
	cut(lid,texture,shape,true)
	cut(body,texture,shape,false)
	mouth(inside,shape)

	local note = PaperUI.image(stage,"PrizeSheet",Assets.hangarShelf.statsWide,299,90,1322,590)
	note.ScaleType, note.Visible = Enum.ScaleType.Stretch, false
	local rarity = centered(PaperUI.loud(PaperUI.words(note,"Rarity",(TIER[item.tier] or item.tier).." "..item.kind,657,111,510,64,51)))
	rarity.TextColor3 = Color3.fromRGB(49,34,42)
	local tab = PaperUI.image(note,"RarityPaper",Assets.hangarShelf.shelfTab,676,103,469,82,-2)
	tab.ImageColor3, tab.ScaleType, tab.ZIndex, rarity.ZIndex = TINT[item.tier] or Color3.new(1,1,1), Enum.ScaleType.Stretch, 1, 2
	local title = centered(PaperUI.loud(PaperUI.words(note,"PrizeName",item.name,569,183,692,111,69)))
	PaperUI.fitWords(title,622)
	local owners = centered(PaperUI.words(note,"RecordedOwners","Counting owners",597,295,642,57,36))
	local refund = request.refund
	local message = if refund > 0 then "Duplicate  +"..PaperUI.commas(refund).." Paper" else "Added to your collection"
	local award = centered(PaperUI.words(note,"Award",message,586,351,666,66,43))
	PaperUI.fitWords(award,610)
	local function tally()
		local text = player:GetAttribute("CosmeticOwnerTally")
		local ok, value = pcall(function() return Http:JSONDecode(text or "") end)
		if ok and type(value) == "table" and value.item==item.id and value.opened==request.sequence and type(value.count)=="number" and value.count>0 then
			owners.Text = PaperUI.commas(value.count)..(value.count==1 and " recorded owner" or " recorded owners")
		end
	end
	local tallyConnection=player:GetAttributeChangedSignal("CosmeticOwnerTally"):Connect(tally)
	tally()
	local view = Instance.new("ViewportFrame")
	view.Name, view.AnchorPoint, view.BackgroundTransparency, view.ImageTransparency = "PrizePreview", Vector2.new(.5,.5), 1, 0.995
	view.Ambient,view.LightColor,view.LightDirection = Color3.fromRGB(145,144,151),Color3.fromRGB(255,247,232),Vector3.new(-.6,-1,-.4)
	view.ZIndex,view.Parent=4,stage
	local animate, failed
	task.defer(function()
		local ok, result=pcall(makePreview,view,item)
		if not stage.Parent then return end
		if ok and result then animate=result else failed=true; warn("Chest preview unavailable",item.id,result) end
	end)
	local previewMessage = centered(PaperUI.words(note,"PreviewStatus","",117,251,500,80,39))
	local clock, revealed, dismissed, soundPhase = 0,false,false,0
	local render
	local function close(wear)
		if not revealed or dismissed then return end
		dismissed=true
		render:Disconnect()
		tallyConnection:Disconnect()
		stage:Destroy()
		cover.Visible=false
		local callback=if wear then request.onWear else request.onClose
		if callback then task.spawn(callback,item) end
		active=false
		startNext()
	end
	PaperUI.button(note,"Wear",Assets.hangar.buttonGreen,"Wear",602,433,290,89,-1,function() close(true) end,52)
	PaperUI.button(note,"Done",Assets.hangar.buttonRed,"Done",909,433,282,89,1,function() close(false) end,52)
	local quiet = Root:GetAttribute("ReducedShake")
	render=Run.RenderStepped:Connect(function(dt)
		clock+=dt
		local rise=ease(clock/.62)
		local shake=math.clamp((clock-.6)/.76,0,1)
		local pop=math.clamp((clock-1.40)/.64,0,1)
		local prize=ease((clock-1.53)/.76)
		local unit=sheet.AbsoluteSize.Y/1080
		if unit<=0 then return end
		local bottom=(cover.AbsolutePosition.Y+cover.AbsoluteSize.Y-sheet.AbsolutePosition.Y)/unit
		local shakeAmount=math.sin(shake*math.pi)^1.5*(quiet and .18 or 1)
		local x=960+math.sin(shake*10*math.pi)*7*shakeAmount
		-- A quarter of the chest stays below the physical lower screen edge on every aspect ratio.
		local y=bottom-155+SIZE*(1-rise)+120*prize
		local tilt=math.sin(shake*9*math.pi)*5.3*shakeAmount
		local pos=UDim2.fromOffset(x,y)
		closed.Position,closed.Rotation,closed.Visible=pos,tilt,pop==0
		inside.Position,body.Position,body.Rotation=pos,pos,tilt
		inside.Visible,body.Visible,lid.Visible=pop>0,pop>0,pop>0 and pop<1
		if lid.Visible then
			local lift=1-(1-pop)^3
			lid.Position,lid.Rotation=UDim2.fromOffset(x-67*lift,y-265*math.sin(pop*1.85)), -25*lift
			local scale=1-.21*lift
			lid.Size=UDim2.fromOffset(SIZE*scale,SIZE*scale)
			local fade=ease((pop-.56)/.44)
			for _,part in lid:GetChildren() do part.ImageTransparency=fade end
		end
		local w=math.max(1,638*(.12+.88*prize))
		view.Size,view.Position=UDim2.fromOffset(w,w*.62),UDim2.fromOffset(960-298*prize,y-51+(361-y+51)*prize)
		if animate then animate(dt,clock); view.ImageTransparency=if prize>0 then 0 else .995 end
		if clock>=2.32 and not revealed then
			revealed,note.Visible=true,true
			stage:SetAttribute("Phase","Reward")
		elseif not revealed then
			local phase=if pop>0 then "Opening" elseif shake>0 then "Shake" else "Rise"
			if stage:GetAttribute("Phase")~=phase then stage:SetAttribute("Phase",phase) end
		end
		previewMessage.Text=if revealed and not animate then (failed and "Preview unavailable" or "Loading preview") else ""
		if soundPhase==0 and clock>=.62 then soundPhase=1;Audio.play("rustle") end
		if soundPhase==1 and pop>0 then soundPhase=2;Audio.play("pop") end
		if soundPhase==2 and revealed then soundPhase=3;Audio.play("shine") end
	end)
end

startNext=function()
	if active or #queue==0 then return end
	active=true
	showPrize(table.remove(queue,1))
end

function Opening.show(openedSequence,chest,item,refund,onWear,onClose)
	if type(openedSequence)~="number" or openedSequence<=lastSequence or not chest or not item then return end
	lastSequence=openedSequence
	table.insert(queue,{sequence=openedSequence,chest=chest,item=item,refund=refund or 0,onWear=onWear,onClose=onClose})
	startNext()
end

return Opening
