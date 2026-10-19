local Loadouts = {}
function Loadouts.make(catalog, choice)
	local loadout = catalog:starterLoadout()
	if choice == "staple" or choice == "rubber" then loadout.weapon_mounts={choice,choice,false,false}
	elseif choice == "paperclip" then loadout.weapon_mounts={"paperclip",false,"pellet",false}
	elseif choice == "eraser" then loadout.weapon_mounts={"eraser",false,"pellet",false}
	elseif choice == "eraser_only" then loadout.weapon_mounts={"eraser",false,false,false}
	elseif choice == "pencil" then loadout.weapon_mounts={"pencil",false,"pellet",false}
	-- The tutorial's fixed training plane (Alan 2026-10-18): pellets on left click, an eraser on right, a booster.
	elseif choice == "training" then loadout.weapon_mounts={"pellet","eraser",false,false};loadout.utility="boost_band"
	elseif choice == "twin_pencils" then loadout.body="body_heavy";loadout.weapon_mounts={"pencil","pencil",false,false,false,false}
	elseif choice ~= "pellet" then return nil end
	return assert(catalog:validateLoadout(loadout,nil,50)) and loadout
end
return Loadouts
