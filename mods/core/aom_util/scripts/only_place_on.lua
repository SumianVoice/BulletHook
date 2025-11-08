
function aom_util.dig_and_collect_node(pos, digger)
    local node = minetest.get_node(pos)
    local ndef = minetest.registered_nodes[node.name]
    if not ndef.diggable then return end
    if not core.is_player(digger) then core.dig_node(pos); return end
    local drops = minetest.get_node_drops(node, digger:get_wielded_item():get_name())
    local inv = digger:get_inventory()
    -- use after since otherwise, itemstack will be overwritten by the return value from other functions
    -- #FIXME
    minetest.after(0.0001, function()
        for i, itemstring in ipairs(drops) do
            drops[i] = inv:add_item("main", ItemStack(itemstring))
            if drops[i] and drops[i]:get_count() > 0 then
                minetest.add_item(pos, drops[i])
            end
        end
    end)
end


function aom_util.get_place_pos_from_pointed_thing(pointed_thing)
    local to_node = minetest.get_node_or_nil(pointed_thing.under)
    local to_def = to_node and minetest.registered_nodes[to_node.name]
    if not to_def then return end

    if to_def.buildable_to then
        return pointed_thing.under, to_node, to_def
    else
        to_node = minetest.get_node_or_nil(pointed_thing.above)
        to_def = to_node and minetest.registered_nodes[to_node.name]
        if to_def and to_def.buildable_to then
            return pointed_thing.above, to_node, to_def
        else -- can't build here
            return nil, nil, nil
        end
    end
end

function aom_util.item_place_node(itemstack, placer, pointed_thing, param2, prevent_after_place)
    local idef = itemstack:get_definition()
    if not idef then return end
    local placed_pos
    if idef.on_place then
        -- local pos, node, ndef = aom_util.get_place_pos_from_pointed_thing(pointed_thing)
        itemstack = idef.on_place(ItemStack(itemstack), placer, pointed_thing) or itemstack
        -- if pos then placed_pos = pos end
    else
        local new_stack
        new_stack, placed_pos = core.item_place_node(ItemStack(itemstack), placer, pointed_thing, param2, prevent_after_place)
        if new_stack and placed_pos then
            itemstack = new_stack
        end
    end
    return itemstack, placed_pos
end

function aom_util.only_place_above(itemstack, placer, pointed_thing, groups)
    local ret = aom_util.try_rightclick(itemstack, placer, pointed_thing, false)
    if ret then return ret end
    local pos, node, ndef = aom_util.get_place_pos_from_pointed_thing(pointed_thing)
    if not pos then return end
    local on_node = core.get_node(vector.offset(pos, 0, -1, 0))
    for _, group in pairs(groups) do
        if core.get_item_group(on_node.name, group) ~= 0 then
            if node and node.name ~= "air" then
                aom_util.dig_and_collect_node(pos, placer)
            end
            return core.item_place(itemstack, placer, pointed_thing)
        end
    end
    return itemstack
end

-- deprecated
function aom_util.only_place_above_buildable_to(itemstack, placer, pointed_thing, groups)
    minetest.log("error", "aom_util.only_place_above_buildable_to is deprecated")
    return itemstack
end

function aom_util.has_pointable_node_at(pos, group)
    local ray = minetest.raycast(pos, pos, false, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            if group then
                return minetest.get_item_group(minetest.get_node(pos).name, group) > 0
            end
            return true
        end
    end
    return false
end

function aom_util.dig_not_under_pointable(pos)
    local p = vector.offset(pos, 0, 0.51, 0)
    if not aom_util.has_pointable_node_at(p) then
        minetest.dig_node(pos)
    end
end

function aom_util.dig_not_above_pointable(pos)
    local p = vector.offset(pos, 0, -0.51, 0)
    if not aom_util.has_pointable_node_at(p) then
        minetest.dig_node(pos)
    end
end
