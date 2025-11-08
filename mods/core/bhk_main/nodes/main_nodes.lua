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
