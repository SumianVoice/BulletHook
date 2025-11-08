local mod_name = core.get_current_modname()

aom_tcraft = {}

aom_tcraft.active_lists = {main=true}

local global_recipe_count = 0
-- {[itemindex] = {recipe, recipe, ...}}
local recipes_by_item_index = {}
local recipes_by_ingredient = {}
local all_recipes = {}
-- {[name] = 1, [name] = 2, ...}
-- index to put into recipes_by_item_index[index] to get recipes for that item
local index_of_item = {}
local all_recipes_by_method = {}

local _playerdata = {}

function aom_tcraft.collect_all_craftables(player, pi)
	pi.all_recipes = {}
	for i, recipe in ipairs(all_recipes) do
		table.insert(pi.all_recipes, {
			recipe = recipe,
			is_craftable = false,
		})
	end
end

function aom_tcraft.pi(player)
	if not core.is_player(player) then return end
	local pi = _playerdata[player]
	if not pi then
		pi = {
			craftable = {},
			all_recipes = {},
			item_quantity = {},
			cur_item_i = 1,
			cur_able_i = 1,
			timer = 1,
			changes_made = true,
		}
		aom_tcraft.collect_all_craftables(player, pi)
		_playerdata[player] = pi
	end
	return pi
end

aom_tcraft.checks_per_step = 100

aom_tcraft.registered_on_craftable = {}

--[[

	aom_tcraft.register_on_craftable(function(player, recipe, is_craftable) return nil end)
--]]
function aom_tcraft.register_on_craftable(func)
	table.insert(aom_tcraft.registered_on_craftable, func)
end

local function on_craftable(player, recipe, is_craftable)
	for i, func in ipairs(aom_tcraft.registered_on_craftable) do
		func(player, recipe, is_craftable)
	end
end

---updates whether this player is tagged as being able to craft this recipe
---@param player table | any
---@param pi table
---@param recipe table
---@return boolean -- is_craftable
function aom_tcraft.process_recipe_is_craftable(player, pi, recipe)
	local rdata = pi.all_recipes[recipe.uid]
	local already_craftable = (rdata and rdata.is_craftable == true)
	local is_craftable = aom_tcraft.player_has_items(player, recipe.items)
	if already_craftable ~= is_craftable then
		rdata.is_craftable = is_craftable
		on_craftable(player, recipe, is_craftable)
	end
	return is_craftable
end

---updates whether the player is tagged as being able to craft every recipe that contains this item
---@param player any
---@param pi any
---@param stack any
---@return nil
function aom_tcraft.process_all_recipes_with_ingredient(player, pi, stack)
	aom_tcraft.get_item_quantities(player)
	local name = stack:get_name()
	local list = recipes_by_ingredient[name]
	if not list then return end
	for i, recipe in ipairs(list) do
		local is_craftable = aom_tcraft.process_recipe_is_craftable(player, pi, recipe)
	end
end

function aom_tcraft.get_all_recipes_for_item(name)
	if not index_of_item[name] then return nil end
	return (recipes_by_item_index[index_of_item[name]])
end
-- table with {[itemname] = {recipe, recipe, ...}}
function aom_tcraft.get_recipes_by_item_index()
	return recipes_by_item_index
end
-- table with [method] = {recipe, recipe, ...}
function aom_tcraft.get_all_recipes_by_method()
	return all_recipes_by_method
end

function aom_tcraft.get_item_quantities(player)
	local inv = player:get_inventory()
	local pi = aom_tcraft.pi(player) or {}
	pi.item_quantity = {}
	for listname, list in pairs(inv:get_lists()) do
		if aom_tcraft.active_lists[listname] then
			for i, itemstack in pairs(list) do
				local name = itemstack:get_name()
				pi.item_quantity[name] = (pi.item_quantity[name] or 0) + itemstack:get_count()
			end
		end
	end
end

-- check things you think you can craft to make sure you still can craft them
function aom_tcraft.player_has_items(player, items)
	local pi = aom_tcraft.pi(player) or {}
	if core.is_creative_enabled(player:get_player_name()) then return true end
	local has = pi.item_quantity
	for name, count in pairs(items) do
		if (not has[name]) or has[name] < count then
			return false
		end
	end
	return true
end
-- allow this to be called externally
local player_has_items = aom_tcraft.player_has_items

-- check new things from the list of recipes to see if there are any new items you can craft
local function iterate_all_registered_crafts(player, force_all)
	local pi = aom_tcraft.pi(player)
	if not pi then return end
    if core.get_modpath("aom_gamemodes") and not aom_gamemodes.player_has_tag(player, "crafting") then
        pi.craftable = {}
        return
    end
    if force_all then
        pi.craftable = {}
    end

	for k, recipe in pairs(all_recipes) do
		aom_tcraft.process_recipe_is_craftable(player, pi, recipe)
	end
end

-- every step
local function on_step(dtime)
	for _, player in ipairs(core.get_connected_players()) do
		local pi = aom_tcraft.pi(player) or {}
		pi.timer = (pi.timer or 0.2) - dtime
		if (pi.timer <= 0 and pi.changes_made) or (pi.timer < -10) then
			pi.timer = (math.random() * 0.1 + 1)
			aom_tcraft.get_item_quantities(player)
			iterate_all_registered_crafts(player, true)
			pi.changes_made = false
		end
	end
end

core.register_globalstep(on_step)

function aom_tcraft.delay_recalc(player, amount)
	local pi = aom_tcraft.pi(player) or {}
	pi.timer = amount or 1
end

-- for a recipe in core's format, return the list of items and their quantity needed to craft it
local function get_ingedients_from_recipe(recipe)
	local list = {}
	for i, itemstring in pairs(recipe.items or {}) do
		if string.find(itemstring, "group:") then return nil end
		list[itemstring] = (list[itemstring] or 0) + 1
	end
	return list
end

--[[
recipes_by_item_index[7] = {
	{ -- way to craft this
		output = "aom_tools:iron_pickaxe",
		items = {
			["aom_items:iron_bar"] = 3,
			["aom_items:stick"] = 2
		}
	},
	{ -- another way to craft this
		--blah
	}
}

recipes_by_item_index
	index
		ways to craft this item
			output = output from crafting
			items = items needed for crafting

recipes_by_item_index[i][1].output
recipes_by_item_index[i][1].items
]]

local craft_process_callbacks = {}
function aom_tcraft.register_craft_process(callback)
	craft_process_callbacks[#craft_process_callbacks+1] = callback
end

local function do_all_craft_processes(def, item_name)
	for i, callback in ipairs(craft_process_callbacks) do
		callback(def, item_name)
	end
end

aom_tcraft.register_craft_process(function (def, item_name)

	if core.get_item_group(item_name, "mechanisms") > 0 then
		if table.indexof(def.tags, "mechanisms") <= 0 then
			table.insert(def.tags, "mechanisms")
		end
		return
	end
	if core.get_item_group(item_name, "decoration") > 0 then
		if table.indexof(def.tags, "decor") <= 0 then
			table.insert(def.tags, "decor")
		end
		return
	end
	if core.get_item_group(item_name, "furniture") > 0 then
		if table.indexof(def.tags, "furniture") <= 0 then
			table.insert(def.tags, "furniture")
		end
		return
	end
	if core.get_item_group(item_name, "food") > 0 then
		if table.indexof(def.tags, "food") <= 0 then
			table.insert(def.tags, "food")
		end
		return
	end

	local tdef = core.registered_tools[item_name]
	if tdef or (core.get_item_group(item_name, "tool") > 0) then
		if table.indexof(def.tags, "tools") <= 0 then
			table.insert(def.tags, "tools")
		end
		return
	end

	local idef = core.registered_items[item_name]
	if idef and (idef.type ~= "node")
	and (table.indexof(def.tags, "goods") <= 0) then
		table.insert(def.tags, "goods")
	end

	local ndef = core.registered_nodes[item_name]
	if ndef and core.get_item_group(item_name, "full_solid") > 0 then
		if table.indexof(def.tags, "blocks") <= 0 then
			table.insert(def.tags, "blocks")
		end
		return
	elseif core.get_item_group(item_name, "shape") > 0 then
		if table.indexof(def.tags, "shapes") <= 0 then
			table.insert(def.tags, "shapes")
		end
		return
	end
end)

-- iterates when recipes are registered, so that it can be looked up and iterated fast later
local cur_uid = 0
-- Example
--[[

	aom_tcraft.register_craft({
		output = "aom_stone:cobble_moss_2 10",
		extra_items = {"aom_items:wooden_cup"},
		items = {
			["aom_stone:cobble_moss_1"] = 10,
		},
	})
--]]
---@param _def table
function aom_tcraft.register_craft(_def)
	local def = table.copy(_def)
	local item_name = ItemStack(def.output):get_name()
	-- set the uid so you can find it later
	cur_uid = cur_uid + 1
	def.uid = cur_uid

	if not def.tags then
		def.tags = {}
		do_all_craft_processes(def, item_name)
	end

	if #def.tags == 0 then def.tags = {"misc"} end

	if not def.method then
		def.method = {"normal"}
	elseif type(def.method) ~= "table" then
		core.log("warning", def.output .. " def.method is not a table, ignoring and setting to \"normal\"")
		def.method = {"normal"}
	end

	-- add to method recipe list
	for i, methodname in ipairs(def.method) do
		if not all_recipes_by_method[methodname] then
			all_recipes_by_method[methodname] = {}
		end
		table.insert(all_recipes_by_method[methodname], def)
	end

	-- actually adding the recipe to the lists
	-- _item_index tells you where in recipes_by_item_index
	local _item_index = index_of_item[item_name]
	-- if there is no list for this item, make one
	if _item_index == nil then
		_item_index = #recipes_by_item_index+1
		recipes_by_item_index[_item_index] = {}
		index_of_item[item_name] = _item_index
		global_recipe_count = global_recipe_count + 1
	end

	for iname, count in pairs(def.items) do
		local per_ingredient = recipes_by_ingredient[iname]
		if not per_ingredient then
			per_ingredient = {}
			recipes_by_ingredient[iname] = per_ingredient
		end
		table.insert(per_ingredient, def)
	end

	-- add them to the list of recipes per item index
	table.insert(recipes_by_item_index[_item_index], def)
	all_recipes[def.uid] = def
end

local _group_crafts = {}
local _tracked_groups = {}
-- use SPARINGLY
-- can cause HUGE amounts of registrations
-- limited to 20, because NO.
function aom_tcraft.register_group_craft(_def)
	if _group_crafts == nil then
		core.log("error", "You may not register tcraft recipes after mods are loaded! Dump:\n"..dump(_def))
	end
	_group_crafts[#_group_crafts+1] = _def
end

local function do_all_group_crafts()
	local group_items = {}
	-- group_items is a list of [name] = {all items in this group}
	for l, def in pairs(_group_crafts) do
		_tracked_groups[def.group] = {}
	end
	for name, idef in pairs(core.registered_items) do
		for group, val in pairs(idef.groups or {}) do
			if _tracked_groups[group] then
				_tracked_groups[group][#_tracked_groups[group]+1] = name
			end
		end
	end

	-- finally, we can actually do the recipes
	for l, def in pairs(_group_crafts) do
		for i, item_alt in ipairs(_tracked_groups[def.group] or {}) do
			local items = table.copy(def.items)
			items[item_alt] = def.group_count
			aom_tcraft.register_craft({
				output = def.output,
				items = items,
			})
		end
	end
	_group_crafts = nil
	_tracked_groups = nil
end

local function is_item_craftable(itemname)
	for i, recipe in pairs(all_recipes) do
		if ItemStack(recipe.output):get_name() == itemname then
			return true
		end
	end
	return false
end

core.register_node("aom_tcraft:unobtainium", {
	description = "unobtainium",
	groups = { not_in_creative_inventory = 1, blast_resistance = -1 },
	paramtype = 'light',
	drawtype = "glasslike",
	tiles = {"blank.png"},
	sunlight_propagates = true,
	floodable = false,
	pointable = false,
	walkable = true,
	buildable_to = false,
	diggable = false,
	_on_node_update = function(pos, cause, user, data)
		core.set_node(pos, {name="air"})
	end,
	drop = "",
})

local function stack_max(itemdef)
	return itemdef.stack_max or (tonumber(core.settings:get("default_stack_max")) or 1000)
end

local function add_crafts_for_noncraftable_nodes()
	for itemname, itemdef in pairs(core.registered_items) do
		if (core.get_item_group(itemname, "not_in_creative_inventory") == 0)
		and (not is_item_craftable(itemname)) then
			aom_tcraft.register_craft({
				output = itemname .. (" " .. math.min(10, stack_max(itemdef))),
				items = {
					["unobtainable"] = 1
				},
				hide_if_not_craftable = true,
			})
		end
	end
end

core.register_on_mods_loaded(function()
	local _start = os.clock()

	for item_name, def in pairs(core.registered_items) do

		local all_recipes_for_this_item = core.get_all_craft_recipes(item_name)
		-- if item_name == "aom_items:stick" then core.log(dump(all_recipes_for_this_item)) end

		if all_recipes_for_this_item then
			for k, recipe in pairs(all_recipes_for_this_item) do
				if recipe.method == "normal" then
					local ingreds = get_ingedients_from_recipe(recipe)
					if ingreds then
						aom_tcraft.register_craft({
							output = recipe.output,
							items = ingreds,
							method = recipe._tcraft_method,
							builtin = true,
						})
					end
				end
			end
		end
	end
	-- core.log("warning", "[aom_tcraft] getting all crafting recipes took: " .. tostring(os.clock() - _start))
	-- core.log(dump(recipes_by_item_index))


	do_all_group_crafts()
	add_crafts_for_noncraftable_nodes()
	-- sort_crafts()
end)

function aom_tcraft.get_player_craftable(player)
	return core.is_player(player) and aom_tcraft.pi(player) or {}
end

function aom_tcraft.get_recipe_from_index(index)
	return all_recipes[index]
end

function aom_tcraft.try_to_craft_uid(player, uid, count)
	local pi = aom_tcraft.pi(player) or {}
	local is_creative = core.is_creative_enabled(player:get_player_name())
	local recipe = all_recipes[uid]
	if not recipe then core.log("no recipe "..tostring(uid))
		return false end
	local to_take = table.copy(recipe.items)
	local give_list = {ItemStack(recipe.output)}
	for i, itemstring in ipairs((not is_creative) and recipe.extra_items or {}) do
		give_list[#give_list+1] = ItemStack(itemstring)
	end
	-- allow for a custom number of crafts
	if count and count > 1 then
		for i,v in pairs(to_take) do to_take[i] = v * count end
		for i,v in pairs(give_list) do
			v:set_count(v:get_count() * count)
			give_list[i] = v
		end
	end

	if (not is_creative) and not player_has_items(player, to_take) then return false end
	-- hardcore make certain it's not created but at cost of cpu:
	if not is_creative then aom_tcraft.get_item_quantities(player) end
	if (not is_creative) and not player_has_items(player, to_take) then return false end

	-- we can be sure the player can craft this now, so we just need to subtract the items and add the crafted ones
	local inv = player:get_inventory()
	if not is_creative then
		for listname, list in pairs(inv:get_lists()) do
			if aom_tcraft.active_lists[listname] then
				for i, stack in ipairs(list) do
					local old_name = stack:get_name()
					local name = ItemStack(old_name):get_name()
					if to_take[name] and to_take[name] > 0 then
						local tmp_count = to_take[name]
						to_take[name] = to_take[name] - stack:get_count()
						stack:take_item(tmp_count)
						-- fix any old stacks
						if old_name ~= name then
							core.log("warning", "Old stack found: " .. old_name .. " --> " .. name)
							stack:set_name(name)
						end
						inv:set_stack(listname, i, stack)
					elseif to_take[name] then
						to_take[name] = nil
					end
				end
			end
		end
	end

	-- JUST IN CASE
	local items_left = 0
	if not is_creative then
		for name, left_count in pairs(to_take) do
			items_left = items_left + left_count
		end
	end
	if items_left > 0 then
		core.log(
			"error", "Something went catastrophically wrong and we avoided (probably) "..
			"a duplication glitch, but items were potentially deleted. Dump:"
		)
		core.log(dump(items_left) .. dump(recipe))
		return
	end

	for i, stack in pairs(give_list) do
		stack = inv:add_item("main", stack)
		if stack:get_count() > 0 then
			core.add_item(player:get_pos(), stack)
		end
		pi.changes_made = true
	end
	return true
end


-- fix all itemstacks in inventory on join
core.register_on_joinplayer(function(player, last_login)
	local inv = player:get_inventory()
	local is_changes = false
	local lists = inv:get_lists()
	for lname, list in pairs(lists) do for i, stack in pairs(list) do
		local old_name = stack:get_name()
		local name = ItemStack(old_name):get_name()
		if old_name ~= name then
			stack:set_name(name)
			core.log("warning", "Old stack found: " .. old_name .. " --> " .. name)
			is_changes = true
		end
	end end

	if is_changes then
		inv:set_lists(lists)
	end
	iterate_all_registered_crafts(player, true)
end)


local function on_any_item_changeed(itemstack, player, listname, listindex, oldstack)
	-- #FIXME dehardcode
	if not aom_tcraft.active_lists[listname] then return end
	local pi = aom_tcraft.pi(player) or {}
	if itemstack:get_name() ~= oldstack:get_name() then
		aom_tcraft.process_all_recipes_with_ingredient(player, pi, oldstack)
	end
	aom_tcraft.process_all_recipes_with_ingredient(player, pi, itemstack)
end


if core.get_modpath("itemextensions") ~= nil then
	itemextensions.register_on_any_item_changed(function(itemstack, player, listname, listindex, oldstack)
		if (itemstack:get_count() == oldstack:get_count()
		and itemstack:get_name() == oldstack:get_name()) then return end
		on_any_item_changeed(itemstack, player, listname, listindex, oldstack)
	end)
else
	local _i = 0
	core.register_globalstep(function(dtime)
		local playerlist = core.get_connected_players()
		local count = #playerlist
		for k = 1, 10 do
			_i = _i + 1
			if _i > count then _i = 0; break end
			local player = playerlist[_i]
			local pi = aom_tcraft.pi(player) or {}
			local inv = player:get_inventory()
			if not pi.last_lists then pi.last_lists = inv:get_lists() end
			for listname, list in pairs(inv:get_lists()) do
				for i, itemstack in ipairs(list) do
					local oldstack = (pi.last_lists[listname] or {})[i] or ItemStack("")
					if (itemstack:get_count() == oldstack:get_count()
					and itemstack:get_name() == oldstack:get_name()) then return end
					on_any_item_changeed(itemstack, player, listname, i, oldstack)
				end
			end
			local new_lists = inv:get_lists()
			pi.last_lists = new_lists
		end
	end)
end
