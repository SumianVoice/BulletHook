

core.register_node("bhk_main:ceiling_light_0", {
    description = "bhk_main:ceiling_light_0",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, light = 2, light_on = 1, full_solid = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    tiles = { "bhk_ceiling_light_0.png" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    light_source = 14,
    drawtype = "normal",
})
core.register_node("bhk_main:ceiling_light_0_off", {
    description = "bhk_main:ceiling_light_0_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, light = 1, full_solid = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    tiles = { "bhk_ceiling_light_0.png^[multiply:#cfcecf" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    light_source = 0,
    drawtype = "normal",
})

local selectionbox = {
    type = "fixed",
    fixed = {
        {
            -5/16, -8/16, -8/16,
             5/16, -4/16,  8/16,
        },
    },
}
local nodebox = {
    type = "fixed",
    fixed = {
        {
            -2/16, -8/16, -8/16,
            -1/16, -7/16,  8/16,
        },
        {
            1/16, -8/16, -8/16,
            2/16, -7/16,  8/16,
        },
    },
}
core.register_node("bhk_main:ceiling_light_1", {
    description = "bhk_main:ceiling_light_1",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 2, light_on = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png" },
    sounds = bhk_sounds.default(),
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_node("bhk_main:ceiling_light_1_off", {
    description = "bhk_main:ceiling_light_1_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png^[multiply:#cfcecf" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    light_source = 0,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})


selectionbox = {
    type = "fixed",
    fixed = {
        {
            -5/16, -8/16, -8/16,
             5/16, -4/16,  8/16,
        },
    },
}
nodebox = {
    type = "fixed",
    fixed = {
        {
            -3/16, -8/16, -8/16,
             3/16, -5/16,  8/16,
        },
    },
}
core.register_node("bhk_main:ceiling_light_2", {
    description = "bhk_main:ceiling_light_2",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 2, light_on = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png" },
    sounds = bhk_sounds.default(),
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_node("bhk_main:ceiling_light_2_off", {
    description = "bhk_main:ceiling_light_2_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png^[multiply:#cfcecf" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    -- light_source = 0,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})

selectionbox = {
    type = "fixed",
    fixed = {
        {
            -5/16, -8/16, -8/16,
             5/16, -4/16,  8/16,
        },
    },
}
nodebox = {
    type = "fixed",
    fixed = {
        {
            -7/16, -8/16, -8/16,
             7/16, -7/16,  8/16,
        },
    },
}
core.register_node("bhk_main:ceiling_light_3", {
    description = "bhk_main:ceiling_light_3",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 2, light_on = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png" },
    sounds = bhk_sounds.default(),
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_node("bhk_main:ceiling_light_3_off", {
    description = "bhk_main:ceiling_light_3_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png^[multiply:#cfcecf" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    -- light_source = 0,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})

selectionbox = {
    type = "fixed",
    fixed = {
        {
            -5/16, -8/16, -8/16,
             5/16, -4/16,  8/16,
        },
    },
}
nodebox = {
    type = "fixed",
    fixed = {
        {
            -1/16, -7/16, -8/16,
             1/16, -6/16,  8/16,
        },
        {
            -2/16, -8/16, -8/16,
             2/16, -7/16,  8/16,
        },
    },
}
core.register_node("bhk_main:emergency_light_0", {
    description = "bhk_main:emergency_light_0",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 2, light_on = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = {
        "bhk_emergency_light_0.png",
        "bhk_emergency_light_0.png",
        "bhk_emergency_light_0_side.png",
    },
    sounds = bhk_sounds.default(),
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    paramtype = "light",
    light_source = 8,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_node("bhk_main:emergency_light_0_off", {
    description = "bhk_main:emergency_light_0_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_emergency_light_0.png" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    -- light_source = 0,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_alias("bhk_main:emergency_light_off", "bhk_main:emergency_light_0_off")

selectionbox = {
    type = "fixed",
    fixed = {
        {
            -4/16, -8/16, -4/16,
             4/16, -4/16,  4/16,
        },
    },
}
nodebox = {
    type = "fixed",
    fixed = {
        {
            -2/16, -8/16, -2/16,
             2/16, -7.5/16,  2/16,
        },
    },
}
core.register_node("bhk_main:emergency_light_1", {
    description = "bhk_main:emergency_light_1",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 2, light_on = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = {
        "bhk_ceiling_light_1.png",
    },
    sounds = bhk_sounds.default(),
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    paramtype = "light",
    light_source = 10,
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
core.register_node("bhk_main:emergency_light_1_off", {
    description = "bhk_main:emergency_light_1_off",
    pointable = bhk_main.nodes_pointable or false,
    groups = { light = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1, dig_immediate = (bhk_main.dev_mode and 3) or 0, },
    drawtype = "nodebox",
    tiles = { "bhk_ceiling_light_1.png^[multiply:#cfcecf" },
    sounds = bhk_sounds.default(),
    paramtype = "light",
    node_box = nodebox,
    selection_box = selectionbox,
    paramtype2 = "facedir",
    walkable = false,
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
