
bhk_main.inventory = {
    width = 12,
    height = 12,
}
bhk_main.inventory.size = bhk_main.inventory.width * bhk_main.inventory.height

local function get_formspec(offset, size)
    if offset==nil then offset = {x=0,y=0} end
    if size==nil then size = {x=10,y=4} end
    return (
        "bgcolor[#ffffff90]"..
        "list[current_player;main;"..tostring(offset.x)..","..tostring(offset.y)..     ";"..(bhk_main.inventory.width)..","..(bhk_main.inventory.height-1)..";"..bhk_main.inventory.width.."]"..
        "list[current_player;main;"..tostring(offset.x)..","..tostring(0.3+offset.y+bhk_main.inventory.height-1)..";"..(bhk_main.inventory.width)..","..(1)..";]"..
        "listcolors[#66504f60;#554a6440]"
    )
end

local function get_craft_menu(inv)
    return (
        "size["..inv.width..","..(inv.height+5).."]"..
        "list[current_player;craft;4,0.5;3,3;]"..
        "list[current_player;craftpreview;8,1.5;1,1;]"..
        get_formspec({x=0,y=4.5})..
        "style_type[image_button;bgcolor=#99eeff00;border=false]"..
        "image_button[14,2.5;1.5,1.5;br_achievement_button.png;openachievements; ]"
    )
end

local function get_hotbar_bg(inv)
    local w = inv.width
    local pw = 57
    local o = 4
    local ret = "[combine:"..math.ceil(w*pw+o).."x60"
    for i = 1, inv.width do
        ret = ret..":"..math.floor((i-1)*pw+o-2)..",0=br_inv_hotbar_bg.png\\^\\[opacity\\:50"
    end
    return ret
end

function bhk_main.update_player_formspec(player)
    local inv = table.copy(bhk_main.inventory)
    if not minetest.is_creative_enabled(player:get_player_name()) then
        inv.width = 6
        inv.height = 1
        inv.size = inv.width * inv.height
    end

    local formspec = get_craft_menu(inv)
    player:set_inventory_formspec(formspec)

    bhk_main.safe_set_inventory_list_size(player, "main", inv.size)

    player:hud_set_hotbar_itemcount(inv.width)
    player:hud_set_hotbar_selected_image("br_inv_itemslot_bg.png^[opacity:90")
    player:hud_set_hotbar_image(get_hotbar_bg(inv))

    player:set_nametag_attributes({
        -- text = " ",
        color = "#ffffff50",
        bgcolor = "#ffffff00"
    })
end

minetest.register_on_joinplayer(function(player)
    -- bhk_main.update_player_formspec(player)
end)

function bhk_main.safe_set_inventory_list_size(player, list_name, size)
    local inv = player:get_inventory()
    local old_size = inv:get_size(list_name)
    local difference = size - old_size
    local list
    if difference ~= 0 then
        list = inv:get_list(list_name)
        inv:set_size(list_name, size)
    end
    -- when shrinking the inventory
    if difference < 0 then
        for i = #list - math.abs(difference), #list do
            local stack = list[i]
            if stack and stack:get_count() > 0 then
                -- now that the inv is shrunk, try to add the stacks back again
                stack = inv:add_item(list_name, stack)
                if stack:get_count() > 0 then
                    local pos = player:get_pos()
                    pos = pos + vector.new(
                        (math.random()*2-1) * 0.2,
                        (math.random()) * 0.2 + 0.1,
                        (math.random()*2-1) * 0.2
                    )
                    core.add_item(pos, stack)
                end
            end
        end
    end
end
