local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)

local node_funcs = {}
local node_list = {}

function bhk_main.on_generate_node(node_name, pos)
    if node_funcs[node_name] then
        for i, func in pairs(node_funcs[node_name]) do
            func(pos)
        end
    end
end

function bhk_main.register_on_generate_node(node_name, func)
    if not node_funcs[node_name] then
        node_funcs[node_name] = {}
        node_list[node_name] = true
    end
    node_funcs[node_name][#node_funcs[node_name]+1] = func
end

function bhk_main.get_on_generate_node_list()
    return node_list
end
