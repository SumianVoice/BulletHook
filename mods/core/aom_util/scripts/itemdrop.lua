local S = core.get_translator(core.get_current_modname())

aom_util.itemdrop_nodes = {}

local has_aom_settings

-- avoid optional_depends:
core.register_on_mods_loaded(function()
    has_aom_settings = (core.get_modpath("aom_settings") ~= nil)
    if has_aom_settings then
        local is_aom = (core.get_modpath("age_of_mending") ~= nil)
        aom_settings.register_setting(
            "gameplay_force_node_drop", is_aom and true, -- only use default drop if AoM
            -- TL: setting description
            S("Force nodes to drop items in world"), "server"
        )
        aom_settings.register_setting(
            "gameplay_use_max_drop_level", is_aom and true,
            -- TL: setting description
            S("No drops when using wrong tool"), "server"
        )
        aom_settings.register_setting(
            "gameplay_node_drop", false,
            -- TL: setting description
            S("Prefer nodes drop items in world")
        )
    end
end)

local function get_setting(player, settingname, default)
    if has_aom_settings then
        return aom_settings.get_setting(player, settingname, default)
    else
        return default
    end
end

function aom_util.register_tool_cap(name, param)
    return param
end

function aom_util.get_tool_caps(name)
    return (core.registered_items[name] or {}).tool_capabilities
end

function aom_util.register_node_drop(name, param)
    aom_util.itemdrop_nodes[name] = table.copy(param)
    return param
end

function aom_util.get_node_drop(name)
    if aom_util.itemdrop_nodes[name] then
        return aom_util.itemdrop_nodes[name]
    end
    return nil
end

function aom_util.drop_items(pos, items)
    for _, item in ipairs(items) do
        local obj = core.add_item(pos, item)
        if obj then
            obj:set_velocity(vector.new(
                (math.random()*2-1),
                2,
                (math.random()*2-1)
            ))
        end
    end
end

core.register_tool("aom_util:dig_anything", {
    description = "",
    inventory_image = "white.png",
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            oddly_breakable_by_hand = {
                times = { 0.1, 0.1, 0.1, 0.1 },
            },
            cracky = {
                times = { 0.1, 0.1, 0.1, 0.1 },
            },
        },
    },
    groups = { not_in_creative_inventory = 1, unobtainable = 1 },
})

local function test_tcaps(icaps, node)
    local can_drop = false
    for group, def in pairs(icaps.groupcaps or {}) do
        -- if icaps and icaps[group] then def = icaps[group] end
        local gval = core.get_item_group(node.name, group)
        if gval > 0 then
            if not get_setting(nil, "gameplay_use_max_drop_level", false) then
                return #(def.times or {}) >= gval
            end
            can_drop = false
            if ((not def.max_drop_level)
            or (def.max_drop_level and def.max_drop_level >= gval)) then
                can_drop = true
                break
            end
        end
    end
    return can_drop
end

function core.handle_node_drops(pos, drops, digger)
    local node = core.get_node(pos)
    local tool
    local tname
    if digger and core.is_player(digger) then
        tool = digger:get_wielded_item()
        tname = tool:get_name()
    else
        tname = "aom_util:dig_anything"
        tool = ItemStack(tname)
    end

    local tool_caps = aom_util.get_tool_caps(tname)

    local can_drop = false
    local hand_caps = aom_util.get_tool_caps("")

    local cap_drops = nil

    if tool_caps then
        can_drop = test_tcaps(tool_caps, node)
    end
    if not can_drop and hand_caps then
        can_drop = test_tcaps(hand_caps, node)
        cap_drops = (tool_caps and tool_caps._on_get_drops and tool_caps._on_get_drops(tool, node, drops, digger)) or nil
    end

    if (not can_drop) and (not cap_drops) then
        drops = {}
        -- core.log("NO DROPS")
    elseif can_drop and cap_drops ~= nil then
        drops = cap_drops
        -- core.log("ICAP DROPS")
    else
        -- core.log("DEFAULT DROPS")
    end

    local inv = digger and digger:get_inventory()
    if not inv then
        aom_util.drop_items(pos, drops)
        -- core.log("no inventory, dropping on ground")
        return
    end

    -- drop if set by server or by player
    local drop_enabled
    if has_aom_settings then
        drop_enabled = (
            aom_settings.get_setting(digger, "gameplay_force_node_drop", true) or
            aom_settings.get_setting(digger, "gameplay_node_drop", true))
    else
        drop_enabled = core.settings:get_bool("aom_node_drops", false)
    end

    if drop_enabled then
        aom_util.drop_items(pos, drops)
        -- core.log("can drop")
    elseif inv then
        local idef = core.registered_nodes[node.name]
        local on_pickup = idef and idef.on_pickup or core.item_pickup
        for _, item in ipairs(drops) do
            drops[_] = on_pickup(ItemStack(item), digger, nil, nil)
        end
        aom_util.drop_items(pos, drops)
        -- core.log("given to player")
    else
        aom_util.drop_items(pos, drops)
        -- core.log("gave up and dropped")
    end
end

function aom_util.get_drops_from_drop_table(drop_table)
    local max_items = drop_table.max_items
    local total_items = 0 -- counter for items
    local item_result = {}
    for _, drop in ipairs(drop_table.items) do
        if drop.chance == 1 or math.random(1, drop.rarity or 1) == 1 then
            for i, item in ipairs(drop.items) do
                local stack = ItemStack(item)
                local count = stack:get_count()
                total_items = total_items + count
                table.insert(item_result, stack)
                if total_items >= max_items then
                    stack:set_count(count - (total_items - max_items))
                    return true -- don't add more stacks if reached max
                end
            end
        end
    end
    return item_result
end

--[[
    Get a result from a list of items with proportional chances. Example:

    local itemlist = {
        {item = "my_mod:my_item", chance = 1},
        {item = "my_mod:my_other_item", chance = 8},
        {item = "my_mod:my_other_other_item", chance = 3},
    }
    local stack = ItemStack(aom_util.get_droptable_item(itemlist))
    core.log(dump(aom_util.get_droptable_item(itemlist)))
]]
function aom_util.get_droptable_item(def, randfunc)
    randfunc = randfunc or math.random
    if def.max_chance == nil then
        def.max_chance = 0
        for i, entry in ipairs(def) do
            def.max_chance = def.max_chance + (entry.chance or 1)
        end
    end

    local rand_index = randfunc(1, def.max_chance)
    for i, entry in ipairs(def) do
        rand_index = rand_index - entry.chance
        if rand_index <= 0 then -- stop on the item which hits the index we wanted
            return entry.item
        end
    end
end
