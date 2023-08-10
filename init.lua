

dofile(minetest.get_modpath("kpgmobs").."/horse.lua")
dofile(minetest.get_modpath("kpgmobs").."/jeraf.lua")
dofile(minetest.get_modpath("kpgmobs").."/medved.lua")
dofile(minetest.get_modpath("kpgmobs").."/deer.lua")

if minetest.setting_get("log_mods") then
	minetest.log("action", "kpgmobs loaded")
end
