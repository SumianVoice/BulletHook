local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main = {
    fullbright = false, --debug
    generator = "main",
	mg_name = nil,
    dev_mode = false,
    nodes_pointable = true,
}

bhk_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
bhk_main.dev_mode = (bhk_main.mg_name == "flat") or core.is_creative_enabled()

if bhk_main.mg_name == "flat" then
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:placeholder",
		wherein        = {"air", "group:liquid"},
		y_min = -32,
		y_max = -1,
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
else
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,biomes,ores", true)
end

dofile(mod_path .. "/scripts" .. "/creative.lua")
dofile(mod_path .. "/scripts" .. "/inventory.lua")
dofile(mod_path .. "/nodes" .. "/nodes_system.lua")
dofile(mod_path .. "/nodes" .. "/main_nodes.lua")

local _t = 0
core.register_globalstep(function(dtime)
	_t = _t + dtime; if _t > 1 then _t = _t - 1 else return end
	for i, player in ipairs(core.get_connected_players()) do
		local pos1 = vector.offset(player:get_pos(), -10, -10, -10)
		local pos2 = pos1 + vector.new(20, 20, 20)
		core.fix_light(pos1, pos2)
	end
end)
