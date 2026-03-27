
local window_1x1_box = {
    type = "fixed", fixed = {
        -8/16, -8/16, -2/16,
         8/16,  8/16,  2/16,
    }
}

for variant, color in pairs(bhk_main.node_colors) do
    local name = "bhk_main:window_" .. variant .. "_0"
    core.register_node(name, {
        description = "",
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
        drawtype = "mesh",
        mesh = "bhk_window_0.obj",
        tiles = {{
            name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
            "^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
            backface_culling = true,
        }},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        collision_box = window_1x1_box,
        selection_box = window_1x1_box,
        sounds = bhk_sounds.concrete(),
    })
	aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
end

local multinode_2x2 = {
    nodes = {
        {vector.new(1, 0, 0), {name="bhk_main:blocker"}},
        {vector.new(1, 1, 0), {name="bhk_main:blocker"}},
        {vector.new(0, 1, 0), {name="bhk_main:blocker"}},
    },
    no_dig_if_missing_nodes = true,
    no_rotation = false,
}

local window_2x2_box = {
    type = "fixed", fixed = {
        -8/16, -8/16, -2/16,
        24/16, 24/16,  2/16,
    }
}

for variant, color in pairs(bhk_main.node_colors) do
    local name = "bhk_main:window_2x2_" .. variant .. "_0"
    core.register_node(name, {
        description = "",
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
        drawtype = "mesh",
        mesh = "bhk_window_2x2_0.obj",
        tiles = {{
            name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
            "^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
            backface_culling = true,
        }},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        collision_box = window_2x2_box,
        selection_box = window_2x2_box,
        sounds = bhk_sounds.concrete(),
        _multinode = multinode_2x2,
    })
	aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
end

for variant, color in pairs(bhk_main.node_colors) do
    local name = "bhk_main:blinds_2x2_" .. variant .. "_0"
    core.register_node(name, {
        description = "",
        pointable = bhk_main.dev_mode or false,
        groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
        drawtype = "mesh",
        mesh = "bhk_blinds_2x2_0.obj",
        tiles = {{
            name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
            "^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
            backface_culling = true,
        }},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        selection_box = window_1x1_box,
        sounds = bhk_sounds.concrete(),
        walkable = false,
    })
	aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
end

for variant, color in pairs(bhk_main.node_colors) do
    local name = "bhk_main:blinds_2x1_" .. variant .. "_0"
    core.register_node(name, {
        description = "",
        pointable = bhk_main.dev_mode or false,
        groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
        drawtype = "mesh",
        mesh = "bhk_blinds_2x1_0.obj",
        tiles = {{
            name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
            "^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
            backface_culling = true,
        }},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        selection_box = window_1x1_box,
        sounds = bhk_sounds.concrete(),
        walkable = false,
    })
	aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
end

for variant, color in pairs(bhk_main.node_colors) do
    local name = "bhk_main:blinds_1x1_" .. variant .. "_0"
    core.register_node(name, {
        description = "",
        pointable = bhk_main.dev_mode or false,
        groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
        drawtype = "mesh",
        mesh = "bhk_blinds_1x1_0.obj",
        tiles = {{
            name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
            "^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
            backface_culling = true,
        }},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        selection_box = window_1x1_box,
        sounds = bhk_sounds.concrete(),
        walkable = false,
    })
	aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
end


for variant, color in pairs(bhk_main.node_colors) do
	for i = 0, 2 do
		local name = "bhk_main:blinds_2x2_" .. variant .. "_0_broken_"..i
		core.register_node(name, {
			description = "",
			pointable = bhk_main.dev_mode or false,
			groups = { solid = 1, oddly_breakable_by_hand = 2, furniture = 1, },
			drawtype = "mesh",
			mesh = "bhk_blinds_2x2_0_broken_"..i..".obj",
			tiles = {{
				name = "[fill:32x32:#fff^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
				"^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:60)",
				backface_culling = true,
			}},
			paramtype = "light",
			paramtype2 = "facedir",
			sunlight_propagates = true,
			selection_box = window_1x1_box,
			sounds = bhk_sounds.concrete(),
			walkable = false,
		})
		aom_tcraft.register_craft({output = name, items = {unobtainable = 1}})
	end
end
