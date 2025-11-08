local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

br_creative_helpers = {}

dofile(mod_path .. "/inventory/tcraft_interface.lua")

core.register_on_joinplayer(function(player, last_login)
	local inv = player:get_inventory()
	bhk_main.safe_set_inventory_list_size(player, "craft", 0)
	bhk_main.safe_set_inventory_list_size(player, "craftpreview", 0)
	bhk_main.safe_set_inventory_list_size(player, "craftresult", 0)
	if bhk_main.dev_mode then
		bhk_main.safe_set_inventory_list_size(player, "trash", 2)
	else
		bhk_main.safe_set_inventory_list_size(player, "trash", 0)
	end
end)

if core.get_modpath("itemextensions") ~= nil then
	itemextensions.register_on_move_any_item(function(itemstack, player, info)
		if info.to_list == "trash" and info.to_index == 2 then
			local inv = player:get_inventory()
			local stack = inv:get_stack("trash", 2)
			if not stack:is_empty() then
				inv:set_stack("trash", 1, itemstack)
				inv:set_stack("trash", 2, ItemStack(""))
				return ItemStack("")
			end
		end
	end)
end