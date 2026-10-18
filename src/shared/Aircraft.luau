-- Assemble uploaded modular assets. This module contains no mesh geometry.
local Root=script.Parent.Parent
local Aircraft={}
-- Plane A: slots 1/2 sit on the body at the pellet tubes' centres, 3/4 under the wings, 5/6 further out (odd = left).
-- `fit` (Aircraft.wingFit) moves every slot with the wings onto a wider body.
-- Hardpoints were checked on every body x wings x nose x weapon against the meshes' real triangles (2026-10-13):
-- only the paperclip railgun on the body slots rose into the wing root, so it hangs this much lower there (studs
-- before scale). Pellet tubes pass through the wing root on purpose (plane A's design).
local BODY_SLOT_DROP={paperclip=.5}
local NEIGHBOUR_GAP=.1 -- studs before scale between two guns under one wing
-- Wing attachment points (Alan, 2026-10-13). A body may carry WingFront/WingBack (the front and back ends of its flat
-- side wall, right side) and every wing set RootFront/RootBack (its root's front and back corners, or custom points
-- for a wing whose shape needs them); the wings are scaled evenly and moved so root front lands on wall front and
-- root back on wall back. Bodies without points just slide the wings out by their catalog wing_shift.
-- Each wing set also carries Mount1/Mount2: where its under-wing gun pairs hang (right side), so guns stay on the wing
-- whatever its shape, and move and scale with it.
local function point(model,name)
 local x,y,z=string.match(model and model:GetAttribute(name) or "","([^,]+),([^,]+),([^,]+)")
 return x and Vector3.new(tonumber(x),tonumber(y),tonumber(z))
end
function Aircraft.wingFit(bodyId,wingsId,shift)
 local pieces=Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("AircraftPieces")
 local body=pieces and bodyId and pieces:FindFirstChild(bodyId);local wings=pieces and wingsId and pieces:FindFirstChild(wingsId)
 local bf,bb,wf,wb=point(body,"WingFront"),point(body,"WingBack"),point(wings,"RootFront"),point(wings,"RootBack")
 local mounts={point(wings,"Mount1"),point(wings,"Mount2")}
 if bf and bb and wf and wb then return {scale=(bb-bf).Magnitude/(wb-wf).Magnitude,from=wf,to=bf,mounts=mounts} end
 return {scale=1,from=Vector3.zero,to=Vector3.new(shift or 0,0,0),mounts=mounts}
end
-- The same fit, as the built plane carries it for code that only has the model (muzzles, aim markers).
function Aircraft.fitOf(model)
 return {scale=model:GetAttribute("WingScale") or 1,from=model:GetAttribute("WingFrom") or Vector3.zero,to=model:GetAttribute("WingTo") or Vector3.zero,
  mounts={model:GetAttribute("WingMount1"),model:GetAttribute("WingMount2")}}
end
-- Where a point of the wings (or under them) goes on this body; points left of centre mirror the right side's fit.
function Aircraft.fitPoint(fit,p)
 local side=p.X<0 and -1 or 1
 local q=fit.to+(Vector3.new(side*p.X,p.Y,p.Z)-fit.from)*fit.scale
 return Vector3.new(side*q.X,q.Y,q.Z)
end
function Aircraft.mountOffset(slot,factor,fit,weaponId)
 local pair=math.floor((slot-1)/2)
 local side=slot%2==1 and -1 or 1
 if type(fit)~="table" then fit=Aircraft.wingFit(nil,nil,fit) end
 local wing=pair>0 and fit.mounts and fit.mounts[pair]
 local at=pair==0 and Vector3.new(side*1.76,.08-(BODY_SLOT_DROP[weaponId] or 0),-1.3134)
  or wing and Vector3.new(side*wing.X,wing.Y,wing.Z) or Vector3.new(side*(3.7+(pair-1)*1.5),.38,-.6)
 return Aircraft.fitPoint(fit,at)*factor
end
-- Where a shot leaves: the weapon model's "Muzzle" (front of what it fires, left-slot frame, mirrored on the right),
-- else half a pellet tube ahead of the slot.
function Aircraft.muzzleOffset(slot,factor,weaponId,fit)
 if type(fit)~="table" then fit=Aircraft.wingFit(nil,nil,fit) end
 local pieces=Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("AircraftPieces")
 local launcher=pieces and weaponId and pieces:FindFirstChild("launcher_"..weaponId)
 local muzzle=launcher and launcher:GetAttribute("Muzzle")
 if not muzzle then return Aircraft.mountOffset(slot,factor,fit,weaponId)+Vector3.new(0,0,-1.5566*factor*fit.scale) end
 local x,y,z=string.match(muzzle,"([^,]+),([^,]+),([^,]+)")
 local side=slot%2==1 and 1 or -1
 return Aircraft.mountOffset(slot,factor,fit,weaponId)+Vector3.new(side*tonumber(x),tonumber(y),tonumber(z))*factor*fit.scale
end
-- Team look: the paper is the team colour (red with squares for team 1, blue with circles for team 2) with white
-- stripes and white wing stickers. Free-for-all planes are split down the middle (Alan, 2026-10-13): left half red with
-- a square, right half blue with a circle, body, nose, tail and booster included (they come as -L/-R halves from
-- tools/art/split_halves.py; stripes and tape stay whole). Play screenshots
-- (2026-10-13): white paper vanished against the cream walls and desks, coloured paper stood out everywhere.
-- Cardboard parts take a darker shade (the city is cardboard), tape and rubber bands highlighter yellow.
-- Softer, coloured-paper team colours (Alan 2026-10-18: pure red and blue looked like plastic).
local RED={paper=Color3.fromRGB(214,78,72),dark=Color3.fromRGB(165,55,50),sticker="sticker-square"}
local BLUE={paper=Color3.fromRGB(70,128,214),dark=Color3.fromRGB(45,90,170),sticker="sticker-circle"}
local MIDDLE={paper=Color3.fromRGB(252,252,255),dark=Color3.fromRGB(80,80,90)}
local WHITE=Color3.fromRGB(252,252,255)
local STICKER_SPOT=1.85 -- a full-size sticker placeholder's width; smaller placeholders (Swept Wings) get smaller stickers
local YELLOW=Color3.fromRGB(255,212,20)
-- Which half of the plane a piece sits on, from its name (wings come as -L/-R and sticker-left/-right).
local function side(name)
 if name:match("%-L$") or name:match("%-left$") then return "left" end
 if name:match("%-R$") or name:match("%-right$") then return "right" end
 return "middle"
end
function Aircraft.colours(team,name)
 if team=="team:1" then return RED elseif team=="team:2" then return BLUE end
 local half=side(name)
 return half=="left" and RED or half=="right" and BLUE or MIDDLE
end
function Aircraft.paint(model)
 local appearance=model:FindFirstChild("Appearance");if not appearance then return end
 local team=model:GetAttribute("Team")
 local pieces=Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("AircraftPieces")
 local stickers=pieces and pieces:FindFirstChild("Stickers")
 local body=model:FindFirstChild("Root")
 local count=0
 for _,part in ipairs(appearance:GetChildren()) do
  local region=part:GetAttribute("Region")
  local colours=Aircraft.colours(team,part.Name)
  local fixed={paper=colours.paper,cardboard=colours.dark,tube=colours.dark,tape=YELLOW,elastic=YELLOW}
  if part:GetAttribute("TeamSticker") then part:Destroy()
  elseif region=="accent" then part.Color=WHITE
  elseif fixed[region] then part.Color=fixed[region]
  elseif region=="sticker" then
   local template=stickers and colours.sticker and stickers:FindFirstChild(colours.sticker)
   part.Transparency=template and 1 or 0
   if template then
    count+=1
    local sticker=template:Clone();sticker.Name=part.Name:match("^[^-]+").."-team-sticker"..count;sticker.Size=template.Size*part.Size.X/STICKER_SPOT;sticker.Color=WHITE
    sticker.CFrame=part.CFrame;sticker.Anchored=part.Anchored;sticker.Massless=true;sticker:SetAttribute("TeamSticker",true);sticker.Parent=appearance
    if body and not part.Anchored then local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=sticker;weld.Parent=sticker end
   end
  end
  -- A textured (paper) piece is tinted through its SurfaceAppearance; the part's own colour doesn't show.
  local look=part.Parent and part:FindFirstChildOfClass("SurfaceAppearance")
  if look then look.Color=part.Color end
 end
end
function Aircraft.build(model,loadout,catalog,preview)
 local assets=Root:FindFirstChild("Assets")
 local library=assets and assets:FindFirstChild("AircraftParts")
 local pieces=assets and assets:FindFirstChild("AircraftPieces")
 if not library and not pieces then return false end
 for _,slot in ipairs({"body","nose","wings","tail"}) do
  local template=library and library:FindFirstChild(loadout[slot])
  if not (pieces and pieces:FindFirstChild(loadout[slot])) and (not template or template.MeshId=="") then return false end
 end
 local body=model:FindFirstChild("Root")
 local old=model:FindFirstChild("Appearance");if old then old:Destroy() end
 local appearance=Instance.new("Model");appearance.Name="Appearance";appearance.Parent=model
 local factor=catalog:get(loadout.body).visual_scale/2
 local fit=Aircraft.wingFit(loadout.body,loadout.wings,catalog:get(loadout.body).wing_shift)
 appearance:SetAttribute("Factor",factor)
 model:SetAttribute("WingScale",fit.scale);model:SetAttribute("WingFrom",fit.from);model:SetAttribute("WingTo",fit.to)
 model:SetAttribute("WingMount1",fit.mounts[1]);model:SetAttribute("WingMount2",fit.mounts[2])
 local function put(template,name,offset,rotation,scale)
  local part=template:Clone();part.Name=name;part.Size*=factor*(scale or 1)
  part.CFrame=(body and body.CFrame or CFrame.identity)*CFrame.new(offset)*rotation
  part.Anchored=preview==true;part.Massless=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Parent=appearance
  if body and not preview then local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=part;weld.Parent=part end
 end
 for _,slot in ipairs({"body","nose","wings","tail"}) do
  local multi=pieces and pieces:FindFirstChild(loadout[slot])
  if multi then
   for _,child in ipairs(multi:GetChildren()) do if child:IsA("MeshPart") then
    -- Wing halves (and their stickers) fit onto the body's own sides.
    if slot=="wings" then put(child,slot.."-"..child.Name,Aircraft.fitPoint(fit,child.Position)*factor,child.CFrame.Rotation,fit.scale)
    else put(child,slot.."-"..child.Name,child.Position*factor,child.CFrame.Rotation) end
   end end
  else
   local template=library and library:FindFirstChild(loadout[slot])
   if template then put(template,slot,template.CFrame.Position*factor,template.CFrame.Rotation) end
  end
 end
 local equipment=assets:FindFirstChild("EquipmentParts")
 -- Neighbouring guns on one side must not touch (erasers on the heavy body's outer pairs did): a pair that would is
 -- shrunk just enough. Pieces sit at mount - side*X, so a launcher reaches -minX outward and maxX inward.
 -- ponytail: muzzles keep the full-size spot (a few tenths of a stud off on a shrunk gun).
 local reach={}
 local function extent(id)
  if reach[id]==nil then
   local launcher=pieces and id and pieces:FindFirstChild("launcher_"..id);local lo,hi=0,0
   for _,child in ipairs(launcher and launcher:GetChildren() or {}) do if child:IsA("MeshPart") then
    lo=math.min(lo,child.Position.X-child.Size.X/2);hi=math.max(hi,child.Position.X+child.Size.X/2)
   end end
   reach[id]={lo,hi}
  end
  return reach[id]
 end
 local scales={}
 for slot,id in ipairs(loadout.weapon_mounts) do
  local outer=loadout.weapon_mounts[slot+2]
  if id and outer then
   local spacing=math.abs(Aircraft.mountOffset(slot+2,1,fit).X-Aircraft.mountOffset(slot,1,fit).X)
   local need=(-extent(id)[1]+extent(outer)[2])*fit.scale
   local scale=math.min(1,(spacing-NEIGHBOUR_GAP)/math.max(need,1e-6))
   scales[slot]=math.min(scales[slot] or 1,scale);scales[slot+2]=math.min(scales[slot+2] or 1,scale)
  end
 end
 for slot,id in ipairs(loadout.weapon_mounts) do if id then
  local launcher=pieces and pieces:FindFirstChild("launcher_"..id)
  if launcher then
   -- Pieces are modelled on the left tube; the right side mirrors them in X (they are symmetric).
   -- Each piece carries the 180-degree turn every uploaded FBX needs (Roblox imports them facing backwards).
   local side=slot%2==1 and 1 or -1
   local scale=(scales[slot] or 1)*fit.scale -- guns scale with the wing they hang from
   for _,child in ipairs(launcher:GetChildren()) do if child:IsA("MeshPart") then
    local at=child.Position
    put(child,"Mount"..slot.."-"..child.Name,Aircraft.mountOffset(slot,factor,fit,id)+Vector3.new(side*at.X,at.Y,at.Z)*factor*scale,child.CFrame.Rotation,scale)
   end end
  elseif equipment and equipment:FindFirstChild("launcher_"..id) then
   local template=equipment["launcher_"..id]
   put(template,"Mount"..slot,Aircraft.mountOffset(slot,factor,fit,id),template.CFrame.Rotation,fit.scale)
  end
 end end
 local booster=loadout.utility and pieces and pieces:FindFirstChild(loadout.utility)
 if booster then
  -- Modelled under the standard body; other bodies say how much lower theirs hangs.
  local drop=tonumber(pieces[loadout.body]:GetAttribute("BoosterDrop") or 0) or 0
  for _,child in ipairs(booster:GetChildren()) do if child:IsA("MeshPart") then put(child,"Booster-"..child.Name,(child.Position+Vector3.new(0,drop,0))*factor,child.CFrame.Rotation) end end
 elseif equipment and loadout.utility and equipment:FindFirstChild(loadout.utility) then
  local template=equipment[loadout.utility]
  put(template,"Booster",Vector3.new(0,.9,2.4)*factor,template.CFrame.Rotation)
 end
 if body then body.Size=Vector3.new(14,2,15)*factor end
 -- The box the fitted parts fill around the flight body (tail fins rise up to 4 studs past the 14x2x15 box):
 -- FlightRules.contact gates its exact-shape test on it.
 local frame,reach=body and body.CFrame or CFrame.identity,Vector3.zero
 for _,part in ipairs(appearance:GetChildren()) do if part:IsA("BasePart") then
  for i=0,7 do
   local corner=part.Size/2*Vector3.new(i%2*2-1,math.floor(i/2)%2*2-1,math.floor(i/4)*2-1)
   reach=reach:Max(frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(corner)):Abs())
  end
 end end
 model:SetAttribute("ContactSize",reach*2)
 Aircraft.paint(model)
 if not model:GetAttribute("PaintBound") then
  model:SetAttribute("PaintBound",true)
  model:GetAttributeChangedSignal("Team"):Connect(function() Aircraft.paint(model) end)
 end
 return true
end
-- Guns on the wings are angled to meet `distance` studs ahead of the plane, like a real fighter's guns,
-- so both streams cross the aim point instead of flying past either side of it.
function Aircraft.converge(body,position,direction,distance)
 return (body.Position+direction*distance-position).Unit
end
-- Projectiles are drawn from their ammo model (erasers 2.5x so they read as missiles); hits use the same box.
function Aircraft.projectile(weaponId,homing)
 local equipment=Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("EquipmentParts")
 local template=equipment and weaponId and equipment:FindFirstChild("ammo_"..weaponId)
 if not template then return nil end
 return template.Size*(homing and 2.5 or 1),template.CFrame.Rotation
end
-- What a shot looks like (Alan): the launcher's own round (its "fire"/"drop" piece), scaled evenly to the length of
-- the ammo box the hits use, and slimmed only where it would be over 1.5x that box (a thin wire stays a wire).
-- Launchers without one (rubber band) keep the ammo model. Pieces turn by 90-degree steps, so axes map one to one.
function Aircraft.shotLook(weaponId)
 local pieces=Root:FindFirstChild("Assets") and Root.Assets:FindFirstChild("AircraftPieces")
 local launcher=pieces and weaponId and pieces:FindFirstChild("launcher_"..weaponId)
 if not launcher then return nil end
 for _,child in ipairs(launcher:GetChildren()) do
  local role=child:GetAttribute("Role")
  if child:IsA("MeshPart") and (role=="fire" or role=="drop") then return child end
 end
 return nil
end
function Aircraft.shotSize(weaponId,homing,look)
 local size,rotation=Aircraft.projectile(weaponId,homing)
 if not size or not look then return size end
 local abs=function(v) return Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) end
 local box=abs(rotation:VectorToWorldSpace(size))
 local own=abs(look.CFrame.Rotation:VectorToWorldSpace(look.Size))
 local even=own*(math.max(box.X,box.Y,box.Z)/math.max(own.X,own.Y,own.Z))
 return abs(look.CFrame.Rotation:VectorToObjectSpace(even:Min(box*1.5)))
end
return Aircraft
