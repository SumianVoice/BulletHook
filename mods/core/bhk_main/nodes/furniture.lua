
local catwalk_box = {
    type = "fixed",
    fixed = {
        {
            (-8)/16, ( 6)/16, (-8)/16,
            ( 8)/16, ( 8)/16, ( 8)/16,
        },
    },
}
core.register_node("bhk_main:catwalk", {
    description = "bhk_main:catwalk",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 1, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = {{
        name = "bhk_meta_catwalk.png^[multiply:".."#7e7d7d".."^(bhk_meta_overlay_dirt_0.png^[multiply:#766353^[opacity:50)",
        align_style = "world",
        scale = 16,
    }},
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    node_box = catwalk_box,
    _sounds = bhk_sounds.steel(),
})

local catwalk_box_low = {
    type = "fixed",
    fixed = {
        {
            (-8)/16, (-10)/16, (-8)/16,
            ( 8)/16, (-7.99)/16, ( 8)/16,
        },
    },
}
core.register_node("bhk_main:catwalk_low", {
    description = "bhk_main:catwalk_low",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 1, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = {{
        name = "bhk_meta_catwalk.png^[multiply:".."#7e7d7d".."^(bhk_meta_overlay_dirt_0.png^[multiply:#766353^[opacity:50)",
        align_style = "world",
        scale = 16,
    }},
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    node_box = catwalk_box_low,
    _sounds = bhk_sounds.steel(),
})

local catwalk_stair_box = {
    type = "fixed",
    fixed = {
        {
            (-8)/16, ( 6)/16, (-4)/16,
            ( 8)/16, ( 8-0.1)/16, ( 8)/16,
        },
        {
            (-8)/16, ( 6-8)/16, (-12+.1)/16,
            ( 8)/16, ( 8-8-0.1)/16, (  0.1)/16,
        },
        -- join
        {
            (-6)/16, ( 0)/16, (-1)/16,
            (-4)/16, ( 6)/16, ( 0)/16,
        },
        {
            ( 4)/16, ( 0)/16, (-1)/16,
            ( 6)/16, ( 6)/16, ( 0)/16,
        },
        -- join to below
        {
            (-6)/16, (-8)/16, (-9)/16,
            (-4)/16, (-2)/16,  (-8)/16,
        },
        {
            ( 4)/16, (-8)/16, (-9)/16,
            ( 6)/16, (-2)/16,  (-8)/16,
        },
    },
}

core.register_node("bhk_main:catwalk_stair", {
    description = "bhk_main:catwalk_stair",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 1, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = {{
        name = "bhk_meta_catwalk.png^[multiply:".."#7e7d7d".."^(bhk_meta_overlay_dirt_0.png^[multiply:#766353^[opacity:50)",
        align_style = "world",
        scale = 16,
    }},
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    node_box = catwalk_stair_box,
    paramtype2 = "facedir",
    _sounds = bhk_sounds.steel(),
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})

for variant, color in pairs(bhk_main.node_colors) do
    core.register_node("bhk_main:catwalk_stair_" .. variant .. "_0", {
        description = "bhk_main:catwalk_stair_" .. variant .. "_0",
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 1, oddly_breakable_by_hand = 2, cracky = 1 },
        tiles = {{
            name = "bhk_meta_catwalk.png^[multiply:"..color.main.."^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:50)",
            align_style = "world",
            scale = 16,
        }},
        drawtype = "nodebox",
        paramtype = "light",
        sunlight_propagates = true,
        node_box = catwalk_stair_box,
        paramtype2 = "facedir",
        _sounds = bhk_sounds.steel(),
        on_place = function(itemstack, placer, pointed_thing)
            return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
        end,
    })
    aom_tcraft.register_craft({
        output = "bhk_main:catwalk_stair_" .. variant .. "_0",
        items = {unobtainable = 1}
    })
    core.register_node("bhk_main:catwalk_" .. variant .. "_0", {
        description = "bhk_main:catwalk_" .. variant .. "_0",
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 1, oddly_breakable_by_hand = 2, cracky = 1 },
        tiles = {{
            name = "bhk_meta_catwalk.png^[multiply:"..color.main.."^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:50)",
            align_style = "world",
            scale = 16,
        }},
        drawtype = "nodebox",
        paramtype = "light",
        sunlight_propagates = true,
        node_box = catwalk_box,
        _sounds = bhk_sounds.steel(),
    })
    aom_tcraft.register_craft({
        output = "bhk_main:catwalk_" .. variant .. "_0",
        items = {unobtainable = 1}
    })
end

local handrail_box = {
    type = "fixed",
    fixed = {
        {
            (-8)/16, ( 6)/16, ( 7)/16,
            ( 8)/16, ( 8)/16, ( 9)/16,
        },
        {
            (-8)/16, ( 2)/16, ( 7)/16,
            ( 8)/16, ( 0)/16, ( 9)/16,
        },
        {
            (-1)/16, (-10)/16, ( 6)/16,
            ( 1)/16, (  7)/16, ( 8.1)/16,
        },
    },
}
for i, o in pairs(handrail_box.fixed) do
    for k, p in pairs(o) do
        handrail_box.fixed[i][k] = handrail_box.fixed[i][k] - 0.001
    end
end
local handrail_box_simple = {
    type = "fixed",
    fixed = {
        {
            (-8)/16, (-8)/16, ( 7)/16,
            ( 8)/16, ( 8)/16, ( 8)/16,
        },
    },
}
core.register_node("bhk_main:handrail", {
    description = "bhk_main:handrail",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = {{
        name = "(bhk_meta_blank.png^[multiply:".."#7e7d7d".."^[transformFXR270)^(bhk_meta_overlay_dirt_0.png^[multiply:#766353^[opacity:50)",
        align_style = "world",
        scale = 16,
    }},
    drawtype = "nodebox",
    node_box = handrail_box,
    collision_box = handrail_box_simple,
    selection_box = handrail_box_simple,
    paramtype2 = "facedir",
    paramtype = "light",
    sunlight_propagates = true,
    _sounds = bhk_sounds.steel(),
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})
local handrail_end_box = {
    type = "fixed",
    fixed = {
        {
            ( 7)/16, (-10)/16, ( 7)/16,
            ( 9)/16, (  8)/16, ( 9)/16,
        },
    },
}
core.register_node("bhk_main:handrail_end", {
    description = "bhk_main:handrail_end",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = {{
        name = "(bhk_meta_blank.png^[multiply:".."#7e7d7d".."^[transformFXR270)^(bhk_meta_overlay_dirt_0.png^[multiply:#766353^[opacity:50)",
        align_style = "world",
        scale = 16,
    }},
    drawtype = "nodebox",
    node_box = handrail_end_box,
    walkable = false,
    paramtype2 = "facedir",
    paramtype = "light",
    sunlight_propagates = true,
    _sounds = bhk_sounds.steel(),
    on_place = function(itemstack, placer, pointed_thing)
        return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
    end,
})

for i, k in pairs({"right", "left"}) do
    core.register_node("bhk_main:handrail_diagonal_"..k, {
        description = "bhk_main:handrail_diagonal_"..k,
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, cracky = 1 },
        tiles = {
            {
                name = "[combine:16x16:-126,-126=" ..
                "(bhk_meta_blank.png\\^\\[multiply\\:".."#7e7d7d"..
                "\\^\\[transformFXR270)\\^(bhk_meta_overlay_dirt_0.png\\^\\[multiply\\:#766353\\^\\[opacity\\:50)",
                align_style = "world",
                scale = 16,
                backface_culling = true,
            },
            {
                name = "[combine:16x16:-126,-126=" ..
                "(bhk_meta_blank.png\\^\\[multiply\\:".."#7e7d7d"..
                "\\^\\[transformFXR270)\\^(bhk_meta_overlay_dirt_0.png\\^\\[multiply\\:#766353\\^\\[opacity\\:50)",
                align_style = "world",
                scale = 16,
                backface_culling = true,
            },
        },
        drawtype = "mesh",
        mesh = "bhk_handrail_diagonal_"..k..".obj",
        collision_box = handrail_box_simple,
        selection_box = handrail_box_simple,
        paramtype2 = "facedir",
        paramtype = "light",
        sunlight_propagates = true,
        node_box = handrail_box,
        _sounds = bhk_sounds.steel(),
        on_place = function(itemstack, placer, pointed_thing)
            return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
        end,
    })
end

for variant, color in pairs(bhk_main.node_colors) do
    local name

    name = "bhk_main:handrail_end_"..variant
    core.register_node(name, {
        description = name,
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, furniture = 1 },
        tiles = {{
            name = "(bhk_meta_blank.png^[multiply:"..color.main..--"^[hsl:0:-30:0"..
            "^[transformFXR270)^(bhk_meta_overlay_dirt_0.png^[multiply:#111^[opacity:40)",
            align_style = "world",
            scale = 16,
        }},
        drawtype = "nodebox",
        node_box = handrail_end_box,
        walkable = false,
        paramtype2 = "facedir",
        paramtype = "light",
        sunlight_propagates = true,
        _sounds = bhk_sounds.steel(),
        on_place = function(itemstack, placer, pointed_thing)
            return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
        end,
    })
    aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})

    name = "bhk_main:handrail_"..variant
    core.register_node(name, {
        description = name,
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, furniture = 1 },
        tiles = {{
            name = "(bhk_meta_blank.png^[multiply:"..color.main..--"^[hsl:0:-30:0"..
            "^[transformFXR270)^(bhk_meta_overlay_dirt_0.png^[multiply:#111^[opacity:40)",
            align_style = "world",
            scale = 16,
        }},
        drawtype = "nodebox",
        node_box = handrail_box,
        collision_box = handrail_box_simple,
        selection_box = handrail_box_simple,
        paramtype2 = "facedir",
        paramtype = "light",
        sunlight_propagates = true,
        _sounds = bhk_sounds.steel(),
        on_place = function(itemstack, placer, pointed_thing)
            return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
        end,
    })
    aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})

    for i, k in pairs({"right", "left"}) do
        name = "bhk_main:handrail_diagonal_"..k.."_"..variant
        local tile = {
            name = "[combine:16x16:-126,-126=" ..
            "(bhk_meta_blank.png\\^\\[multiply\\:"..color.main..--"\\^\\[hsl\\:0\\:-30\\:0"..
            "\\^\\[transformFXR270)\\^(bhk_meta_overlay_dirt_0.png\\^\\[multiply\\:#111\\^\\[opacity\\:40)",
            align_style = "world",
            scale = 16,
            backface_culling = true,
        }
        core.register_node(name, {
            description = name,
            pointable = bhk_main.nodes_pointable or false,
            groups = { solid = 1, full_solid = 0, oddly_breakable_by_hand = 2, furniture = 1 },
            tiles = {
                tile, tile,
            },
            drawtype = "mesh",
            mesh = "bhk_handrail_diagonal_"..k..".obj",
            collision_box = handrail_box_simple,
            selection_box = handrail_box_simple,
            paramtype2 = "facedir",
            paramtype = "light",
            sunlight_propagates = true,
            node_box = handrail_box,
            _sounds = bhk_sounds.steel(),
            on_place = function(itemstack, placer, pointed_thing)
                return core.rotate_and_place(itemstack, placer, pointed_thing, nil, {})
            end,
        })
        aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
    end
end
