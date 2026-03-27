local S = minetest.get_translator(core.get_current_modname())

br_creative_helpers.tcraft = {}

local has_aom_settings = minetest.get_modpath("aom_settings") ~= nil
local function get_setting(player, name, default)
	if has_aom_settings then return aom_settings.get_setting(player, name) or default
	else return default end
end

if has_aom_settings then
	aom_settings.register_setting("crafting_show_noncraftable", true, S("Show non-craftable recipes"))
end

local _pl = {}
local function pl(player)
	local pi = _pl[player]
	if not pi then pi = {scroll = 0}; _pl[player] = pi end
	return pi
end

local _offset = {x=0, y=0}
local function p(x,y)
	return tostring(x+_offset.x) .. "," .. tostring(y + _offset.y)
end


function br_creative_helpers.tcraft.force_update_formspec(player)
	local f = {}
	local C
	function C(t)
		table.insert(f, t)
		return C
	end
	C"formspec_version[6]""size[24,12]""no_prepend[]"
	C"style_type[item_image_button;bgcolor=#fff;bgcolor_hovered=#fff;bgcolor_pressed=#fff]"
	C"style_type[item_image_button;textcolor=#8c3f5d;border=false]"
	C"style_type[item_image_button;bgimg=blank.png^[noalpha^[colorize:#f0f:255;bgimg_hovered=blank.png^[noalpha^[colorize:#f0f:255]"
    C"style_type[list;spacing="(0.1)";size="(0.9)"]"
	C"list[current_player;main;10.05,0.05;12,10;12]"
	C"list[current_player;main;10.05,11.05;12,1;0]"
	C"list[current_player;trash;10.55,10.05;2,1;0]"
	C"listring[current_player;main]"
	C"listring[current_player;trash]"
	C(br_creative_helpers.tcraft_get_formspec(player, "normal"))
	player:set_inventory_formspec(table.concat(f))
end


core.register_on_joinplayer(function(player, last_login)
	br_creative_helpers.tcraft.force_update_formspec(player)
end)

br_creative_helpers.tcraft.tabs_index = {
	{"blocks", "bhk_inv_tblocks.png"},
	{"shapes", "bhk_inv_tshapes.png"},
	{"furniture", "bhk_inv_tfurniture.png"},
	{"food", "bhk_inv_tfood.png"},
	{"tools", "bhk_inv_ttools.png"},
	{"mechanisms", "bhk_inv_tmech.png"},
	{"goods", "bhk_inv_tgoods.png"},
	{"decor", "bhk_inv_tdecor.png"},
	{"misc", "bhk_inv_tmisc.png"},
}

local recipes_per_row = 5
local recipe_scale = 1
local recipe_spacing_y = 1.1 -- extra dist per row
local recipe_spacing_x = 1.1 -- extra dist per column
local scroll_per_formspec_unit = 10 -- magic number
local scroll_per_index = (scroll_per_formspec_unit * recipe_spacing_y) / recipes_per_row
local spacing_right = 2

local on_globalstep = function(dtime)
	for i, player in ipairs(minetest.get_connected_players()) do
		if not _pl[player] then _pl[player] = {scroll = 0, stash = {}} end
		local pi = _pl[player]
		if pi.refresh_grace then
			pi.refresh_grace = pi.refresh_grace - dtime
			if pi.refresh_grace < 0 then pi.refresh_grace = nil end
		end
		for k, methodstash in pairs(pi.stash) do
			pi.stash[k].time = methodstash.time - dtime
		end
	end
end
minetest.register_globalstep(on_globalstep)

local function index_to_pos(c)
	return (c / recipes_per_row) * recipe_spacing_y
end

local function index_to_recipe_uid(player, method, index)
	return ((_pl[player].craftable[method] or {})[index] or {}).uid
end

local function scroll_position_to_index(scroll)
	local index = scroll / (recipe_spacing_y * scroll_per_formspec_unit)
	return math.floor((index + 5) * recipes_per_row)
end

local function index_to_scroll_position(i)
	local scroll = math.floor(i / recipes_per_row) - 5 -- center the scroll
	return scroll * (recipe_spacing_y * scroll_per_formspec_unit)
end

local function scroll_position_to_uid(player, method, scroll)
	local index = math.floor(scroll_position_to_index(scroll) / recipes_per_row) * recipes_per_row
	return index_to_recipe_uid(player, method, index)
end

local function leftpad(str, len, char)
	if string.len(str) >= len then return str end
	local t = {}
	for i = 1, len - string.len(str) do
		t[#t+1] = char
	end
	return table.concat(t, "") .. str
end

local function craft_index_to_fsu_y(k)
	return (
		math.floor((k-1) / recipes_per_row) * (recipe_spacing_y) + 0.1
	)
end
local function craft_index_to_fsu_x(k)
	return (
		((k-1) % recipes_per_row) * (recipe_spacing_x)
	)
end

local has_aom_tcraft = core.get_modpath("aom_tcraft") ~= nil

if has_aom_tcraft then
	aom_tcraft.register_on_craftable(function(player, recipe, is_craftable)
		local pi = _pl[player]
		if not pi then return end
		local uid = recipe.uid
		for method, recipe_list in pairs(pi.craftable) do
			if ((recipe_list[uid] or {}).is_craftable ~= is_craftable) then
				pi.stash[method].time = -1
			end
		end
	end)
end

local function sort(a, b)
	return (a.recipe.output < b.recipe.output)
end

function br_creative_helpers.tcraft_get_formspec(player, method, flags)
	if not has_aom_tcraft then return end
	if not method then method = "normal" end
	if not flags then flags = {} end
	if not flags.color then flags.color = "#907f71" end
	if not flags.color_middle then flags.color_middle = "#463f4f" end
	if not flags.color_right then flags.color_right = "#6d6265" end
	if not _pl[player] then _pl[player] = {scroll = 0, stash = {}, craftable = {}} end
	local pi = _pl[player]

	if not pi.tab then pi.tab = "blocks" end
	if not pi.stash[method] then
		pi.stash[method] = {time = 10}
	end

	if pi.stash[method].has_creative_fs then
		return pi.stash[method].last_formspec
	end

	if pi.stash[method].time > 0 and pi.stash[method].last_formspec ~= nil then
		return pi.stash[method].last_formspec
	else
		pi.stash[method].time = 10 + math.random()
	end

	local is_creative = core.is_creative_enabled(player:get_player_name())

	local scroll = pi.scroll

	local pli = aom_tcraft.get_player_craftable(player)
	pi.craftable[method] = {}
	local recipe_list = pi.craftable[method]
	-- put non craftable recipes in another table to be appended after all the craftable ones
	local non_craftable = {}
	local i = 0

	local show_non_craftable
	if has_aom_settings then
		show_non_craftable = aom_settings.get_setting(player, "crafting_show_noncraftable", true)
	else
		show_non_craftable = true
	end

	-- collect all recipes in order of craftable first
	for __, def in ipairs(pli.all_recipes) do repeat
		if not def.is_craftable then
			if not show_non_craftable then break end
			if def.recipe.hide_if_not_craftable then break end
			if def.recipe.items.unobtainable then break end
		end
		if core.get_item_group(def.recipe.output, "not_in_creative_inventory") > 0 then break end
		if table.indexof(def.recipe.method, method) <= 0 then break end
		if table.indexof(def.recipe.tags, pi.tab) <= 0 then break end
		table.insert((def.is_craftable and recipe_list) or non_craftable, {
			is_craftable = is_creative or def.is_craftable,
			recipe = def.recipe,
		})
		i = i + 1
		-- this scrolls to the last item you were looking at if it's available
		if pi.last_viewed_uid == def.recipe.uid then
			scroll = index_to_scroll_position(i) + (pi.scroll_offset or 0)
		end
	until true end

	-- table.sort(recipe_list, sort)
	-- table.sort(non_craftable, sort)

---@diagnostic disable-next-line: undefined-field
	table.insert_all(recipe_list, non_craftable)

	-- so that the scroll doesn't affect the formspec refresh
	-- #TODO: stop doing hacky stuff like this
	scroll = leftpad(tostring(math.floor(scroll)), 16, " ")
	local maxscroll = (math.ceil((#recipe_list / recipes_per_row)) - 9.8) * (recipe_spacing_y) * scroll_per_formspec_unit
	maxscroll = math.max(maxscroll, 0)

	local scrollcontwidth = (craft_index_to_fsu_x(recipes_per_row)) + recipe_spacing_x + 0.3 + spacing_right
	local scrollcontheight = 11
	local scrollcontx = 0.5

	local t = {}
	local W; W = function(a) table.insert(t, a) return W end

	-- background
	W "background9[" (scrollcontx-0.1) "," (0.0) ";" (scrollcontwidth) "," (12)
	W ";bhk_tcraft_panel.png^[multiply:" (flags.color or "#458") "^bhk_tcraft_panel_overlay.png;false;20]"
	-- global styles
	W "style_type[item_image_button;bgcolor=#fff;bgcolor_hovered=#fff;bgcolor_pressed=#fff]"
	W "style_type[item_image_button;textcolor=#8c3f5d;border=false]"
	W "scrollbaroptions[arrows=hide;smallstep=" (math.round(scroll_per_index * recipes_per_row) * 2)
	W ";thumbsize=" (maxscroll/4 + 5) ";max=" (maxscroll) "]"
	W "scrollbar[" (scrollcontx - 0.5) ", " (0.5) ";0.5,10.5;vertical;tcraft_scroll;" (scroll) "]"
	-- middle, darker background
	W "background9["
	W (scrollcontx-0.1) "," (0.5) ";" (scrollcontwidth) ",11;"
	W "bhk_tcraft_panel_middle.png^[multiply:" (flags.color_middle or "#236")
	W "^bhk_tcraft_panel_overlay_middle.png;false;20]"

	-- scroll container
	W "scroll_container[" (scrollcontx + 0.2) ", " (0.5) ";" (scrollcontwidth) "," (scrollcontheight)
	W ";tcraft_scroll;vertical;0.1]"

	-- style for non craftable
	W "style_type[item_image_button;bgimg=bhk_inv_itemslot_bg.png^[multiply:#622"
	W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#622"
	W ";bgimg_pressed=bhk_inv_itemslot_bg.png^[multiply:#522]"

	local last_selected_recipe

	-- non craftable
	for k, def in ipairs(recipe_list) do
		if pi.last_selected_id and def.recipe.uid == pi.last_selected_id then
			last_selected_recipe = def
			W "style[" "tcraftid_" (pi.last_selected_id) "_1" ";bgimg=bhk_inv_itemslot_bg.png^[multiply:#e94"
			W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#a73]"
		end
		if not def.is_craftable then
		local spl = string.split(def.recipe.output, " ", true, 2)
		W "item_image_button["
		W (craft_index_to_fsu_x(k)) ","
		W (craft_index_to_fsu_y(k)) ";" (recipe_scale) "," (recipe_scale) ";"
		W (spl[1]) ";" "tcraftid_" (def.recipe.uid) "_1" "; ]"
		if spl[2] and spl[2] ~= "" and spl[2] ~= "1" then
			W "label["
			W (0.1 + craft_index_to_fsu_x(k)) ","
			W (1 - 0.2 + craft_index_to_fsu_y(k)) ";"
			W (spl[2]) "]"
		end
	end end

	-- styles bhk_inv_itemslot_bg for craftable
	W "style_type[item_image_button;bgimg=bhk_inv_itemslot_bg.png^[multiply:#334"
	W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#445"
	W ";bgimg_pressed=bhk_inv_itemslot_bg.png^[multiply:#334]"

	-- visual for item output
	-- craftable
	W "style_type[label;font_size=*1;textcolor=#fff;font=normal]"
	for k, def in ipairs(recipe_list) do if def.is_craftable then
		local spl = string.split(def.recipe.output, " ", true, 2)
			W "item_image_button["
			W (craft_index_to_fsu_x(k)) ","
			W (craft_index_to_fsu_y(k)) ";" (recipe_scale) "," (recipe_scale) ";"
			W (spl[1]) ";" "tcraftid_" (def.recipe.uid) "_1" "; ]"
		if spl[2] and spl[2] ~= "" and spl[2] ~= "1" then
			W "label["
			W (0.1 + craft_index_to_fsu_x(k)) ","
			W (1 - 0.2 + craft_index_to_fsu_y(k)) ";"
			W (spl[2]) "]"
		end
	end end

	for k, def in ipairs(recipe_list) do
	if not def.is_craftable then
		-- cover to mark it as noncraftable
		W "image[" (craft_index_to_fsu_x(k)-0.1) "," (craft_index_to_fsu_y(k)-0.1)
		W ";" (recipe_spacing_x) "," (recipe_spacing_y) ";[fill:1x1:0,0:" (flags.color_middle or "#236") "^[opacity:60]"
	end end

	W "scroll_container_end[]"

	do
		local ox = scrollcontx + craft_index_to_fsu_x(recipes_per_row) + recipe_spacing_x + 0.2
		local oy = 0.5
		W "background9["
		W (ox)","(oy) ";" (spacing_right) ",11;"
		W "bhk_tcraft_panel_right.png^[multiply:" (flags.color_right or "#348")
		W "^bhk_tcraft_panel_overlay_right.png;false;20]"
		-- tiny shadow bit
		W "image[" (ox-0.05) "," (oy) ";" (0.05) ",11"
		W ";[fill:1x1:0,0:" ("#000") "^[opacity:60]"
		W "image[" (ox) "," (oy) ";" (0.05) ",11"
		W ";[fill:1x1:0,0:" ("#fea") "^[opacity:60]"
	end

	if last_selected_recipe then
		local def = last_selected_recipe or {
			recipe = {output = "", items = {}},
			is_craftable = true,
		}
		local spl = string.split(def.recipe.output, " ", true, 2)
		local ox = scrollcontx + craft_index_to_fsu_x(recipes_per_row) + recipe_spacing_x + 0.3
		local oy = 0.6
		-- scale of ingredients
		local iscale = 1
		local ispacing = 1.1

		local scale = recipe_scale * 1.6
		W "container["(ox)","(oy)"]"

		if not def.is_craftable then
			W "style_type[item_image_button;bgimg=bhk_inv_itemslot_bg.png^[multiply:#622"
			W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#622"
			W ";bgimg_pressed=bhk_inv_itemslot_bg.png^[multiply:#622]"
		end

		W "container["(0)","(2)"]"

		-- panel for ingredients
		local recipe_ingredient_count = 0

		for name, count in pairs(def.recipe.items) do if name ~= "unobtainable" then
			recipe_ingredient_count = recipe_ingredient_count + 1
		end end

		do
			-- background for ingredients
			local pw = scale-0.3
			local ilen = ispacing * recipe_ingredient_count
			local col = flags.color_middle or "#334"
			if not def.is_craftable then
				col = "#322"
			end
			W "container["(scale*0.5 - pw*0.5)","(scale*0.5)"]"
			W "image[" (0) "," (-scale - pw + 0.05) ";" (pw) "," (pw)
			W ";bhk_inv_panel_end.png^[transformFY^[multiply:" (col) "]"
			W "image[" (0) "," (-scale) ";" (pw) "," (ilen + scale)
			W ";[fill:1x1:0,0:" (col) "]"
			W "image[" (0) "," (ilen-0.1) ";" (pw) "," (pw)
			W ";bhk_inv_panel_end.png^[multiply:" (col) "]"
			W "container_end[]"
		end

		-- style x10 and x100 craft button
		W "style_type[image_button;"
		W "font_size=*1;textcolor=#ddd;bgimg_middle=10;border=false;"
		if def.is_craftable then
			W "bgimg=bhk_inv_btn.png^[multiply:" (flags.color_right or "#556") ";"
			W "bgimg_hovered=bhk_inv_btn.png^[multiply:" (flags.color or "#556") ";"
			W "bgimg_pressed=bhk_inv_btn_press.png^[multiply:" (flags.color_middle or "#556") "]"
		else
			W "bgimg=bhk_inv_btn.png^[multiply:#622;"
			W "bgimg_hovered=bhk_inv_btn.png^[multiply:#622;"
			W "bgimg_pressed=bhk_inv_btn_press.png^[multiply:#622]"
		end
		-- add x10 and x100 buttons
		W "image_button["
		W (scale/2 - 1.2/2) "," (-1-0.9) ";"
		W "1.2,0.9;" "blank.png;" "confirmcraft" "_10" ";10]"
		W "image_button["
		W (scale/2 - 1.2/2) "," (-1) ";"
		W "1.2,0.9;" "blank.png;" "confirmcraft" "_100" ";100]"
		W "style_type[image_button;bgimg_middle=]"


		W "item_image_button["(0) ","(0) ";"
		W (scale) "," (scale) ";"
		W (spl[1]) ";" "confirmcraft" "_1" "; ]"
		if spl[2] and spl[2] ~= "" and spl[2] ~= "1" then
			W "label["
			W (0.1*scale) ","
			W (0.8*scale) ";"
			W (spl[2]) "]"
		end

		if def.is_craftable then
			W "style_type[item_image_button;bgimg=bhk_inv_itemslot_bg.png^[multiply:#393948"
			W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#393948"
			W ";bgimg_pressed=bhk_inv_itemslot_bg.png^[multiply:#393948]"
		else
			W "style_type[item_image_button;bgimg=bhk_inv_itemslot_bg.png^[multiply:#533"
			W ";bgimg_hovered=bhk_inv_itemslot_bg.png^[multiply:#533"
			W ";bgimg_pressed=bhk_inv_itemslot_bg.png^[multiply:#533]"
		end

		-- ingredients
		local id = 0
		local k = 0
		local ow = (math.abs(iscale - scale) * 0.5)
		for name, count in pairs(def.recipe.items) do if name ~= "unobtainable" then
			local ix, iy = 0, k*(ispacing) + 0.25
			k = k + 1
			W "item_image_button["
			W (ix + ow) ","
			W (iy + scale) ";" (iscale) "," (iscale) ";"
			W (name) ";tcinf_" (id) "; " --tostring(count > 1 and count or ""),
			W "]"

			W "label["
			W (ix + ow + iscale * 0.1) ","
			W (iy + scale + iscale * 0.8 + 0.1) ";"
			W (tostring(count > 1 and count or "")) "]"
			id = id + 1
		end end
		W "container_end[]"
		if not def.is_craftable then
			W "image[" (-0.1)","(-0.05) ";" (spacing_right-0.2) "," (11-0.1)
			W ";[fill:1x1:0,0:" (flags.color_right or "#2d334a") "^[opacity:60" "]"
		end
		W "container_end[]"
	end

	W "style_type[image_button;"
	W "font_size=;textcolor=;bgimg_middle=;"
	W "bgimg=;"
	W "bgimg_hovered=;"
	W "bgimg_pressed=;border=false]"

	-- tabs
	if (method == "normal") then
		W "style_type[image_button;bgimg=bhk_inv_tagbg.png"
		W ";bgimg_hovered=bhk_inv_tagbg_hover.png;bgimg_pressed=bhk_inv_tagbg_hover.png]"
		W "style_type[image_button;bgcolor=#fff;bgcolor_hovered=#fff;bgcolor_pressed=#fff]"
		local tab_pos_y = 0.3
		for k, tex in ipairs(br_creative_helpers.tcraft.tabs_index) do
			local tabname = tex[1]
			local is_selected = (pi.tab == tabname)
			local size = tostring((is_selected and 1) or 0.9)
			local texture = tex[2]
			if not is_selected then
				texture = texture.."^[colorize:#322947:255"
			else
				texture = "bhk_inv_tagbg_sel.png^"..texture
			end
			W "image_button[" (p(scrollcontx + scrollcontwidth - 0.2, tab_pos_y))
			W ";" (size) "," (size) ";"
			W (texture) ";tab_" (tabname) "; ;false;false;" "]"
			if is_selected then
				tab_pos_y = tab_pos_y + 1.0-0.05
			else
				tab_pos_y = tab_pos_y + 0.9-0.05
			end
		end
	end

	local fs = table.concat(t, "")
	local len = string.len(fs)
	if len ~= pi.stash[method].last_length then
		pi.refresh_grace = 0.5
	end
	pi.stash[method].last_formspec = fs
	pi.stash[method].last_length = len
	if core.is_creative_enabled(player:get_player_name()) and (#recipe_list > 0) then
		pi.stash[method].has_creative_fs = true
	end
	return fs
end

local function force_recalc(pi)
	pi.stash["normal"].last_length = 0
	pi.stash["normal"].time = 0
	pi.stash["normal"].has_creative_fs = false
	pi.stash["normal"].last_formspec = nil
end

function br_creative_helpers.tcraft.on_fields(player, formname, fields)
	local pi = pl(player)
	for field, val in pairs(fields) do
		local _split = string.split(field, "_", false, 3)
		if not _split then
		elseif _split[1] == "tab" then
			local tab = _split[2]
			if pi.tab ~= tab then
				pi.tab = tab
				force_recalc(pi)
				pi.last_viewed_uid = -1
				pi.scroll = 0
				br_creative_helpers.tcraft.force_update_formspec(player)
				core.sound_play("aom_igm_click", {
					gain = 1 * get_setting(player, "sound_menu_volume", 1),
					to_player = player:get_player_name(),
				})
			end
		elseif _split[1] == "tcraftid" then
			local uid = tonumber(_split[2] or "-1")
			-- local count = tonumber(_split[3] or "1")
			pi.last_selected_id = uid
			force_recalc(pi)
			br_creative_helpers.tcraft.force_update_formspec(player)
			core.sound_play("aom_igm_click", {
				gain = 1 * get_setting(player, "sound_menu_volume", 1),
				to_player = player:get_player_name(),
			})
		elseif _split[1] == "confirmcraft" and (pi.last_selected_id ~= nil) then
			local count = tonumber(_split[2] or "1") or 1
			local success = aom_tcraft.try_to_craft_uid(player, pi.last_selected_id, count)
			aom_tcraft.delay_recalc(player)
			if success then
				minetest.sound_play("aom_pickup_item", {
					gain = (0.3 + math.random() * 0.1) * get_setting(player, "sound_menu_volume", 1),
					to_player = player:get_player_name(),
					pitch = 0.8 + math.random() * 0.2
				})
			else
				minetest.sound_play("aom_not_allowed", {
					gain = 0.5 * get_setting(player, "sound_menu_volume", 1),
					to_player = player:get_player_name(),
				})
			end
		end
	end
	if fields.tcraft_scroll then
		local scroll_event = minetest.explode_scrollbar_event(fields.tcraft_scroll)
		if scroll_event.type == "CHG" then
			pi.scroll = scroll_event.value
			local method = (formname == "" and "normal") or string.split(formname, ":")[2]
			if not method then
				pi.scroll_offset = 0
				pi.last_viewed_uid = -1
				return
			end
			pi.last_viewed_uid = scroll_position_to_uid(player, method, scroll_event.value)
			-- wizardry
			local si = scroll_position_to_index(scroll_event.value)
			local sp2 = index_to_scroll_position(si + 1)
			pi.scroll_offset = scroll_event.value - sp2
			if pi.stash[method] then pi.stash[method].time = 1 end
			aom_tcraft.delay_recalc(player, 0.1)
		end
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then return end
	br_creative_helpers.tcraft.on_fields(player, formname, fields)
end)

