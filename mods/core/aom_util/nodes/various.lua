local S = minetest.get_translator(minetest.get_current_modname())

local mg_name = minetest.get_mapgen_setting("mg_name")
local is_flat_creative = mg_name and ((mg_name == "flat") or (mg_name == "singlenode")) and minetest.is_creative_enabled()

minetest.register_node("aom_util:barrier", {
    description = S("Barrier"),
    groups = { solid = 1, blast_resistance = -1, unobtainable = 1, not_in_creative_inventory = 1, },
    paramtype = 'light',
    drawtype = "airlike",
    sunlight_propagates = true,
    floodable = false,
    pointable = false,
    walkable = true,
    buildable_to = false,
    diggable = false,
    drop = "",
})


local function destroy_near(pos)
    minetest.set_node(pos, {name="air"})
    local size = 4
    local near = minetest.find_nodes_in_area(
        vector.offset(pos, -size, -size, -size),
        vector.offset(pos,  size,  size,  size),
        {"aom_util:temp_air"}, true
    )
    for i, p in ipairs((near and near["aom_util:temp_air"]) or {}) do
        minetest.set_node(p, {name="air"})
    end
end

local cid_air = minetest.get_content_id("air")
minetest.register_node("aom_util:temp_air", {
    description = S("Air equivalent for schematics"),
    groups = { blast_resistance = -1, dig_immediate = 3, no_mapgen = 1, unobtainable = 1, },
    paramtype = 'light',
    drawtype = (is_flat_creative and "nodebox") or "airlike",
    use_texture_alpha = "blend",
    node_box = {
        type = "fixed",
        fixed = {
            -4/16, -4/16, -4/16,
             4/16,  4/16,  4/16,
        },
    },
    tiles = {"blank.png^[noalpha^[colorize:#ffeeaae0:255"},
    sunlight_propagates = true,
    floodable = false,
    pointable = is_flat_creative,
    _on_node_update = (not is_flat_creative) and function(pos, ...)
        destroy_near(pos)
    end,
    walkable = false,
    buildable_to = true,
    diggable = true,
    drop = "",
})

if not is_flat_creative then
    minetest.register_abm({
        label = "REMOVE_aom_util:temp_air",
        nodenames = {"aom_util:temp_air"},
        interval = 10,
        chance = 10,
        action = function(pos, node, active_object_count, active_object_count_wider)
            destroy_near(pos)
        end
    })
end
