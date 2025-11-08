local S = minetest.get_translator(minetest.get_current_modname())
local save_path = minetest.get_worldpath()


local function compare(a,b)
    return a < b
end

local nodecount = 0
local fullnodecount = 0
local itemcount = 0

local function is_full_node(def)
    if (def.groups.shape or 0) > 0 then return false end
    return true
end

function aom_util.output_item_list(player_name)
    local mod = {}
    local file = io.open(save_path.."/item_list.txt", "w")
    if not file then return end
    file:write("") -- flush the file
    file:close()
    file = io.open(save_path.."/item_list.txt", "a")
    if not file then return end
    local c = 0
    for iname, idef in pairs(minetest.registered_items) do
        local tmpmod = string.split(iname, ":")[1]
        if tmpmod ~= nil then
            if not mod[tmpmod] then mod[tmpmod] = {} end
            local m = mod[tmpmod]
            m[#m+1] = iname
            itemcount = itemcount + 1
            if minetest.registered_nodes[iname] and is_full_node(idef) then fullnodecount = fullnodecount + 1 end
            if minetest.registered_nodes[iname] then nodecount = nodecount + 1 end
        end
    end
    for modname, list in pairs(mod) do
        table.sort(list, compare)
        file:write("\n\n\n"..
        "      "..modname.."\n"..
        "===============================\n")
        for i, item_name in pairs(list) do
            file:write(item_name.."\n")
        end
    end
    file:write("\n\nTotal nodes: "..(nodecount).."\nTotal unique nodes: "..(fullnodecount).."\nTotal items: "..(itemcount-nodecount))
    file:close()
    -- TL: @1 is a filepath ("minetest/worlds/worldname/item_list.txt")
    core.chat_send_player(player_name, S("Finished compiling a list of all items. Output to @1", save_path.."/item_list.txt"))
end

minetest.register_chatcommand("get_item_list", {
    params = "",
    description = S("Outputs list of all items"),
    privs = { server = 1 },
    func = function(name, param)
        aom_util.output_item_list(name)
    end
})
