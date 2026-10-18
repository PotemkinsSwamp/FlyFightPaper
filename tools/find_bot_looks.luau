-- Finds outfits real Roblox players saved, for bots to wear (Alan 2026-10-18: bots look like real players, lots of
-- them, never their names). Run in Studio's Edit mode through the Studio link; it keeps going after the call returns
-- and writes the outfit ids it found, comma-separated, to the ServerStorage attribute "BotLookOutfits" (progress in
-- "BotLookScan"; set "BotLookStop" to stop early). Paste the ids into config/gameplay.json
-- avatar_display.bot_look_outfits, then delete the attributes.
-- A random outfit id is a saved outfit about 1 time in 9; it counts with layered clothing (2+) or 4+ accessories AND
-- at least one item a player-creator made (not Roblox), which leaves out Roblox's free starter looks: about 5 a
-- minute. (Random user ids were 10x slower: most accounts are quitters in starter clothes.)
local WANT, PER_SECOND = 150, 4
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local store = game:GetService("ServerStorage")
local rng = Random.new()
local byRoblox = {}
local function madeByRoblox(assetId)
	if byRoblox[assetId] == nil then
		local ok, info = pcall(Marketplace.GetProductInfoAsync, Marketplace, assetId, Enum.InfoType.Asset)
		byRoblox[assetId] = not ok or info.Creator.CreatorTargetId == 1
	end
	return byRoblox[assetId]
end
local function dressedUp(description)
	local items, layered = description:GetAccessories(true), 0
	for _, item in items do if item.IsLayered then layered += 1 end end
	if layered < 2 and #items < 4 then return false end
	for _, item in items do if not madeByRoblox(item.AssetId) then return true end end
	return false
end

local found, tries = {}, 0
store:SetAttribute("BotLookOutfits", "")
store:SetAttribute("BotLookStop", nil)
task.spawn(function()
	while #found < WANT and not store:GetAttribute("BotLookStop") do
		tries += 1
		local id = rng:NextInteger(1e8, 1.2e10)
		local ok, description = pcall(Players.GetHumanoidDescriptionFromOutfitIdAsync, Players, id)
		if ok and dressedUp(description) and not table.find(found, id) then
			table.insert(found, id)
			store:SetAttribute("BotLookOutfits", table.concat(found, ","))
		end
		store:SetAttribute("BotLookScan", ("%d found in %d tries"):format(#found, tries))
		task.wait(1 / PER_SECOND)
	end
end)
return "scanning"
