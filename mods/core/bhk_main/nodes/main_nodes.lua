local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main.node_tile = {}


local function register_shapes(...)
    return aom_util.register_all_shapes(...)
end

local has_aom_tcraft = core.get_modpath("aom_tcraft") ~= nil
local function register_craft(...)
    if has_aom_tcraft then
        return aom_tcraft.register_craft(...)
    end
end

if bhk_main.fullbright then
	core.register_on_mods_loaded(function()
		for iname, idef in pairs(core.registered_nodes) do
			local split = string.split(iname, ":")
			if #split == 2 then
				core.override_item(iname, {
					sunlight_propagates = true,
					paramtype = "light",
				})
			end
		end
	end)
end

core.register_node("bhk_main:placeholder", {
	description = S("Placeholder Node"),
	groups = { solid = 1, unbreakable = 1, },
	tiles = {
		{
			name = "bhk_main_placeholder_16x.png^[multiply:#888",
			align_style = "world", scale = 16,
		},
	},
	sunlight_propagates = false,
})

core.register_alias("placeholder", "bhk_main:placeholder")
core.register_alias("mapgen_stone", "air")
core.register_alias("mapgen_water_source", "air")
core.register_alias("mapgen_river_water_source", "air")

core.register_node("bhk_main:light_blocker", {
    description = "blocks light",
    pointable = bhk_main.dev_mode or false,
    groups = { dig_immediate = 3 },
    drawtype = (bhk_main.dev_mode and "glasslike") or "airlike",
    tiles = { "bhk_barrier.png^[colorize:#000:255" },
    use_texture_alpha = "clip",
    sounds = {},
    -- paramtype = "light",
    sunlight_propagates = false,
    walkable = false,
})

-- blocks other nodes from being placed
core.register_node("bhk_main:blocker", {
	description = "",
	buildable_to = bhk_main.dev_mode,
	pointable = false, floodable = false, walkable = false,
	groups = { not_in_creative_inventory = 1, obstacle = 1, },
	drawtype = bhk_main.dev_mode and "glasslike" or "airlike",
	sunlight_propagates = true, paramtype = "light",
	tiles = {
		"[combine:64x64:0,0=blank.png" ..
		"^[fill:64x1:0,0:#fff" ..
		"^[fill:64x1:0,63:#fff" ..
		"^[fill:1x64:0,0:#fff" ..
		"^[fill:1x64:63,0:#fff"
	},
})

-- not actually white, but close
core.register_node('bhk_main:white', {
    description = 'bhk_main:white',
    pointable = bhk_main.nodes_pointable or false,
    groups = { oddly_breakable_by_hand = 2 },
    tiles = { '(bhk_white.png)'..(bhk_main.dev_mode and '^(bhk_barrier.png^[colorize:#aaa:255)' or "")},
    sunlight_propagates = true,
    sounds = bhk_sounds.carpet(),
    paramtype = "light",
    light_source = 14,
}) register_shapes("bhk_main:white")
core.register_node('bhk_main:black', {
    description = 'bhk_main:black',
    pointable = bhk_main.nodes_pointable or false,
    groups = { oddly_breakable_by_hand = 2 },
    tiles = { '(bhk_white.png^[colorize:#000:255)'..(bhk_main.dev_mode and '^(bhk_barrier.png^[colorize:#aaa:255)' or "")},
    sunlight_propagates = false,
    sounds = bhk_sounds.carpet(),
    paramtype = "light",
}) register_shapes("bhk_main:black")

core.register_node('bhk_main:barrier', {
    description = 'barrier',
    pointable = bhk_main.dev_mode or false,
    groups = { oddly_breakable_by_hand = 2 },
    drawtype = (bhk_main.dev_mode and "glasslike") or "airlike",
    tiles = { (bhk_main.dev_mode and 'bhk_barrier.png') or "blank.png" },
    use_texture_alpha = "clip",
    sunlight_propagates = true,
    paramtype = "light",
}) register_shapes("bhk_main:barrier")

core.register_node('bhk_main:light_diffuse', {
    description = 'barrier',
    pointable = bhk_main.dev_mode or false,
    groups = { oddly_breakable_by_hand = 2 },
    drawtype = (bhk_main.dev_mode and "glasslike") or "airlike",
    tiles = { 'bhk_barrier.png^[colorize:#339:255' },
    use_texture_alpha = "clip",
    walkable = false,
    paramtype = "light",
})

--[[
core.register_node("bhk_main:duct_0", {
    description = "bhk_main:duct_0",
    pointable = bhk_main.nodes_pointable or false,
    groups = { solid = 1, full_solid = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1 },
    tiles = { "bhk_".."duct_0.png" },
    sounds = bhk_sounds.concrete(),
}) register_shapes("bhk_main:duct_0")
register_craft({output = "bhk_main:duct_0", items = {unobtainable = 1}})
--]]

function bhk_main.node_tile.concrete(color, flags)
    return {
        name = "bhk_meta_blank.png^[multiply:"..(color.main)..
        "^(bhk_meta_overlay_dirt_0.png^[multiply:#000005^[opacity:30)",
        align_style = "world",
        scale = 16,
    }
end

-- make nodes
for i, color in ipairs(bhk_main.node_colors_list) do
    core.register_node("bhk_main:concrete_"..color.name, {
        description = "",
        pointable = bhk_main.nodes_pointable or false,
        groups = { solid = 1, full_solid = 1, suffocates = 2, oddly_breakable_by_hand = 2, cracky = 1 },
        tiles = {bhk_main.node_tile.concrete(color, nil)},
        _sounds = "concrete",
    }) register_shapes("bhk_main:concrete_"..color.name)
    register_craft({output = "bhk_main:concrete_"..color.name, items = {unobtainable = 1}})
end
