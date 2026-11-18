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
local Artwork = require(script.Parent.ChestArtwork)
local Opening = { picture = Artwork.picture, prepare = Artwork.prepare }

local TIER = { common = "Common", rare = "Rare", legendary = "Legendary", mythical = "Mythical" }
local TINT = { common = Color3.fromRGB(222, 229, 217), rare = Color3.fromRGB(187, 219, 251),
	legendary = Color3.fromRGB(255, 218, 134), mythical = Color3.fromRGB(227, 193, 248) }
local SIZE = 760
local lastSequence, queue, active = 0, {}, false
local cover, sheet

local function frame(parent, name, z)
	local f = Instance.new("Frame")
	f.Name, f.BackgroundTransparency, f.BorderSizePixel, f.ZIndex = name, 1, 0, z
	f.Parent = parent
	return f
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
	local art = Artwork.rig(stage, chest)
	local quiet = Root:GetAttribute("ReducedShake")
	local glints = {}
	for i = 1, quiet and 3 or 7 do
		local glint = PaperUI.image(stage,"Glint"..i,Assets.shop.sparkle,0,0,1,1)
		glint.ZIndex, glint.Visible = 3, false
		table.insert(glints,glint)
	end

	local note = PaperUI.image(stage,"PrizeSheet",Assets.hangarShelf.statsWide,299,10,1322,590)
	note.ScaleType, note.Visible = Enum.ScaleType.Stretch, false
	local cardScale = .86
	local cardCenterY = 258
	note.Position = UDim2.fromOffset(960, cardCenterY)
	local noteScale = Instance.new("UIScale")
	noteScale.Scale, noteScale.Parent = cardScale, note
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
	local loadWait = 0
	render=Run.RenderStepped:Connect(function(dt)
		-- If the network is still fetching the sheet, hold the closed pose briefly.
		-- The prize and its buttons remain reachable if an image request fails.
		if clock + dt >= 1.40 and clock < 1.40 and not art.open.IsLoaded and loadWait < 1.5 then
			clock = 1.39
			loadWait += dt
		else
			clock += dt
		end
		local rise=ease(clock/.62)
		local shake=math.clamp((clock-.6)/.76,0,1)
		local pop=math.clamp((clock-1.40)/.46,0,1)
		local prize=ease((clock-1.53)/.76)
		local unit=sheet.AbsoluteSize.Y/1080
		if unit<=0 then return end
		local bottom=(cover.AbsolutePosition.Y+cover.AbsoluteSize.Y-sheet.AbsolutePosition.Y)/unit
		local shakeAmount=math.sin(shake*math.pi)^1.5*(quiet and .18 or 1)
		local x=960+math.sin(shake*10*math.pi)*7*shakeAmount
		local startWidth = 640
		local prizeBottom = cardCenterY + 295*cardScale
		local heldWidth = math.clamp((bottom-prizeBottom-20)/(art.foot-art.top), 1, startWidth)
		local width = startWidth + (heldWidth-startWidth)*prize
		local startRail = bottom + 95 - art.closedFoot*startWidth
		local heldRail = bottom - 10 - art.foot*heldWidth
		local y = startRail + (heldRail-startRail)*prize + SIZE*(1-rise)
		local tilt = math.sin(shake*9*math.pi)*5.3*shakeAmount
		art.draw(x, y, width, tilt, ease(pop))
		local burst = math.clamp((clock-1.47)/.72,0,1)
		for i, glint in glints do
			glint.Visible = burst > 0 and burst < 1
			if glint.Visible then
				local a = math.rad(-148 + 116*(i-1)/(#glints-1))
				local distance = (95+155*burst)*(quiet and .60 or 1)
				local size = (i%2==0 and 45 or 32)*math.sin(burst*math.pi)^.65
				glint.Size = UDim2.fromOffset(size,size)
				glint.Position = UDim2.fromOffset(x+math.cos(a)*distance,y+math.sin(a)*distance)
				glint.ImageTransparency = burst*burst
			end
		end
		local w=math.max(1,638*cardScale*(.12+.88*prize))
		view.Size,view.Position=UDim2.fromOffset(w,w*.62),UDim2.fromOffset(960-298*cardScale*prize,y+(cardCenterY-24*cardScale-y)*prize)
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
		if soundPhase==1 and pop>0 then soundPhase=2;Audio.play("ding") end
		if soundPhase==2 and clock>=1.65 then soundPhase=3;Audio.play("purchase") end
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
