local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main = {
    fullbright = false, --debug
    generator = "main",
	mg_name = nil,
    dev_mode = false,
    nodes_pointable = true,
	generators = {},
}

bhk_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
bhk_main.dev_mode = (bhk_main.mg_name == "flat") or core.is_creative_enabled()

dofile(mod_path .. "/scripts" .. "/creative.lua")
dofile(mod_path .. "/scripts" .. "/inventory.lua")
dofile(mod_path .. "/scripts" .. "/on_generate.lua")
dofile(mod_path .. "/nodes" .. "/nodes_system.lua")
dofile(mod_path .. "/nodes" .. "/main_nodes.lua")
dofile(mod_path .. "/nodes" .. "/decoration.lua")
dofile(mod_path .. "/nodes" .. "/furniture.lua")
dofile(mod_path .. "/nodes" .. "/lights.lua")
dofile(mod_path .. "/mapgen" .. "/mg_main.lua")

local _t = 0
core.register_globalstep(function(dtime)
	_t = _t + dtime; if _t > 1 then _t = _t - 1 else return end
	for i, player in ipairs(core.get_connected_players()) do
		local pos1 = vector.offset(player:get_pos(), -10, -10, -10)
		local pos2 = pos1 + vector.new(20, 20, 20)
		core.fix_light(pos1, pos2)
	end
end)

if bhk_main.dev_mode then
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:placeholder",
		wherein        = {"air", "group:liquid"},
		y_min = -32,
		y_max = 0,
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
else
	core.register_on_generated(bhk_main.generators.main)
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,biomes,ores", true)
end

core.register_on_joinplayer(function(player, last_login)
	if not bhk_main.dev_mode then
		-- player:set_fov(60, false, 0)
		-- player:set_camera({
		-- 	mode = "third",
		-- })
		-- player:set_eye_offset(
		-- 	vector.new(0,0,0),
		-- 	vector.new(0,15,-5),
		-- 	vector.new(0,0,0)
		-- )
		-- player:set_properties({
		-- 	collisionbox = {
		-- 		-0.3, -7, -0.3,
		-- 		0.3, -6, 0.3,
		-- 	},
		-- })
	end
end)
