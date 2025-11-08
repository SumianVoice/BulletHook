local S = minetest.get_translator(minetest.get_current_modname())

local function is_position_within_bounds(p)
    if math.abs(p.x) >= 32768 then return false end
    if math.abs(p.y) >= 32768 then return false end
    if math.abs(p.z) >= 32768 then return false end
    return true
end

function aom_util.find_biome(centerpos, biomename)
    local biomedef = minetest.registered_biomes[biomename]
    if not biomedef then return end
    local chsize = 20
    local searchsize = 40
    for x = -searchsize, searchsize do
    for y = -4, 4 do
    for z = -searchsize, searchsize do repeat
        local pos = vector.new(
            x * chsize + centerpos.x,
            y * chsize + centerpos.y,
            z * chsize + centerpos.z
        )
        if not is_position_within_bounds(pos) then break end
        local info = core.get_biome_data(pos)
        local biome = core.registered_biomes[core.get_biome_name(info.biome) or "nil"] --get_voronoi(nvheat, nvhumid)
        if biome and biome.name == biomedef.name then
            return pos
        end
    until true end end end
end

minetest.register_chatcommand("findbiome", {
    params = "(biomename)",
    description = S("Looks for a biome"),
    privs = {give = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local centerpos = player:get_pos()
        local biomepos = aom_util.find_biome(centerpos, param)
        if not biomepos then return false, S("Biome not valid, or none found.") end
        -- TL: @1 name of biome ("oak_forest_dense")
        return true, S("Found biome at @1", tostring(biomepos))
    end
})

minetest.register_chatcommand("gobiome", {
    params = "(biome_name)",
    description = S("Looks for a biome and teleports you there"),
    privs = {give = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local centerpos = player:get_pos()
        local biomepos = aom_util.find_biome(centerpos, param)
        if not biomepos then return false, S("Biome not valid, or none found.")
        else
            if not is_position_within_bounds(biomepos) then return false, "" end
            player:set_pos(biomepos)
        end
        return true, "Found biome at "..tostring(biomepos)
    end
})

