local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)


aom_util = {}
aom_util.player = {}


minetest.register_on_joinplayer(function(ObjectRef, last_login)
    aom_util.player[ObjectRef] = {}
end)
minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
    aom_util.player[ObjectRef] = nil
end)


dofile(mod_path .. "/scripts" .. "/math.lua")
dofile(mod_path .. "/scripts" .. "/time.lua")
dofile(mod_path .. "/scripts" .. "/on_look.lua")
dofile(mod_path .. "/scripts" .. "/tools_and_hand_range.lua")
dofile(mod_path .. "/scripts" .. "/rotate_node.lua")
dofile(mod_path .. "/scripts" .. "/only_place_on.lua")
dofile(mod_path .. "/scripts" .. "/itemdrop.lua")
dofile(mod_path .. "/scripts" .. "/has_adjacent.lua")
dofile(mod_path .. "/scripts" .. "/give_to.lua")
dofile(mod_path .. "/scripts" .. "/make_shapes.lua")
dofile(mod_path .. "/scripts" .. "/output_node_list.lua")
dofile(mod_path .. "/scripts" .. "/on_change_wielditem.lua")
dofile(mod_path .. "/scripts" .. "/set_fov.lua")
dofile(mod_path .. "/scripts" .. "/prevent_digging.lua")
dofile(mod_path .. "/scripts" .. "/server_info.lua")
dofile(mod_path .. "/scripts" .. "/abm_tracker.lua")
dofile(mod_path .. "/scripts" .. "/textures.lua")
dofile(mod_path .. "/scripts" .. "/manual_wield_image.lua")
dofile(mod_path .. "/scripts" .. "/item_use.lua")
dofile(mod_path .. "/scripts" .. "/formspec_actions.lua")
dofile(mod_path .. "/scripts" .. "/try_rightclick.lua")
dofile(mod_path .. "/scripts" .. "/find_biome.lua")
dofile(mod_path .. "/scripts" .. "/item_display.lua")
dofile(mod_path .. "/scripts" .. "/player_force_set_velocity.lua")
dofile(mod_path .. "/scripts" .. "/player_force_move_pos.lua")
dofile(mod_path .. "/scripts" .. "/collision_box_to_vertex.lua")

-- nodes
dofile(mod_path .. "/nodes" .. "/air_lights.lua")
dofile(mod_path .. "/nodes" .. "/various.lua")
