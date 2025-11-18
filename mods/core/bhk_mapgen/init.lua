local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_mapgen = {}
bhk_mapgen.generators = {}

dofile(mod_path .. "/mapgen" .. "/mg_main.lua")

if bhk_main.mg_name == "flat" then
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:placeholder",
		wherein        = {"air", "group:liquid"},
		y_min = -32,
		y_max = 0,
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
else
	core.register_on_generated(bhk_mapgen.generators.main)
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:black",
		wherein        = {"air", "group:liquid"},
		y_min = bhk_main.get_game_area_floor() - 1,
		y_max = bhk_main.get_game_area_floor(),
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
end

local nullfunc = function() end

local function test_on_emerge_callback(calls_remaining, callback)
    if calls_remaining == 0 and callback then
        callback()
    end
end

function bhk_mapgen.regenerate(minp, maxp, callback)
    core.log("action", "regenerating for static mapgen")
    core.delete_area(minp, maxp)
    core.emerge_area(minp, maxp, function(blockpos, action, calls_remaining, param)
        -- if action == core.EMERGE_ERRORED or action == core.EMERGE_CANCELLED then end
        test_on_emerge_callback(calls_remaining, callback)
    end)
end

function bhk_mapgen.generate_map(seed, callback)
    bhk_mapgen.regenerate(bhk_main.gamearea_min, bhk_main.gamearea_max, callback or nullfunc)
end

