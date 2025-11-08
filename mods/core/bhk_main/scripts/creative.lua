local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

local creative_setting = core.is_creative_enabled()
bhk_main.disable_take_item = false

bhk_main.hand_def = {}
bhk_main.hand_def.groupcaps_creative = {
    oddly_breakable_by_hand = {
        times = { 0.1, 0.3, 2 },
        uses = 0,
    },
    cracky = {
        times = { 0.5, 0.8, 2 },
        uses = 0,
    },
    dig_immediate = {
        times = { 0.5, 0.5, 0 },
        uses = 0,
    },
}
bhk_main.hand_def.groupcaps = {
    oddly_breakable_by_hand = {},
    cracky = {},
    dig_immediate = {},
}

core.override_item("", {
	wield_image = "blank.png",
	wield_scale = { x = 3, y = 3, z = 5 },
    range = (bhk_main.dev_mode and 10) or nil,
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level = 0,
		groupcaps = bhk_main.hand_def.groupcaps,
		damage_groups = { fleshy = 1 },
	}
})

core.register_tool("bhk_main:creative_hand", {
	wield_image = "blank.png",
	wield_scale = { x = 3, y = 3, z = 5 },
    range = 10,
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level = 0,
		groupcaps = bhk_main.hand_def.groupcaps_creative,
		damage_groups = { fleshy = 1 },
	}
})

function core.is_creative_enabled(name)
    if not name then return creative_setting or (bhk_main.dev_mode) end
    local player = core.get_player_by_name(name)
    return (bhk_main.dev_mode) or (player and player:get_meta():get_string("creative") == "true")
end

function bhk_main.set_creative_hand(player, bool)
    local inv = player:get_inventory()
    inv:set_size("hand", 1)
    if bool then
        inv:set_stack("hand", 1, ItemStack("bhk_main:creative_hand"))
    else
        inv:set_stack("hand", 1, ItemStack(""))
    end
end

function bhk_main.set_creative(player, bool, force)
    local name = player:get_player_name()
    bool = bool or false -- no nil
    local meta = player:get_meta()
    local is_creative = meta:get_string("creative") == "true"
    local changed = force or (is_creative ~= bool)
    if not changed then return end

    meta:set_string("creative", (bool and "true") or "")

    bhk_main.set_creative_hand(player, bool)

    -- bhk_main.update_player_formspec(player)
end

core.register_on_joinplayer(function(player, last_login)
    bhk_main.set_creative(player, core.is_creative_enabled(player:get_player_name()), true)
end)

core.register_privilege("creative", {
	description = S("Lets players change their creative status"),
	give_to_singleplayer = true
})

core.register_chatcommand("creative", {
	params = "/creative on|off",
	description = S("Turns on or off some features"),
	privs = {creative=true},
	func = function(name, param)
        local player = core.get_player_by_name(name)
        if param == "off" then
            bhk_main.set_creative(player, false)
            return true, "Set creative off for "..name.."."
        elseif param == "on" then
            bhk_main.set_creative(player, true)
            return true, "Set creative on for "..name.."."
        elseif param == "ignore" then
            player:get_meta():set_string("seen_creative_warning", "true")
            return true, "Never showing creative warning again."
        else
            return false, "Error: Please use [/creative on] or [/creative off]."
        end
	end
})

-- don't take items when in creative if it's the last item
local core_item_place = core.item_place_node
core.item_place_node = function(itemstack, placer, pointed_thing, param2, prevent_after_place, ...)
    local ret, pos = core_item_place(ItemStack(itemstack), placer, pointed_thing, param2, prevent_after_place, ...)
    local is_creative = core.is_player(placer) and core.is_creative_enabled(placer:get_player_name())
    -- don't take the last item in the stack
    if is_creative then
        return ((bhk_main.disable_take_item or ret:is_empty()) and itemstack or ret), pos
    else
        return ret, pos
    end
end
