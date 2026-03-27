
aom_util.player = aom_util.player or {}
local pl = {}

local function check_player(player)
    if not pl[player] then
        pl[player] = {}
    end
end

function aom_util.get_product(player)
    local product = 1
    for tag, def in pairs(pl[player]) do
        product = product * def.fov
    end
    return (product ~= 1 and product) or 0
end

-- player (objectref), def (table)
function aom_util.set_fov(player, def)
    check_player(player)
    local sf = pl[player]
    if (sf[def.tag] == nil) or (sf[def.tag].fov ~= def.fov) then
        sf[def.tag] = def
        local fov = aom_util.get_product(player)
        player:set_fov(fov, true, def.transition_time)
    end
end

function aom_util.has_fov(player, tag)
    if pl[player] and pl[player][tag] then
        return pl[player][tag]
    end
    return nil
end

-- player(objectref), tag (string)
function aom_util.unset_fov(player, tag)
    check_player(player)
    local sf = pl[player]
    if sf[tag] ~= nil then
        local def = table.copy(sf[tag])
        sf[tag] = nil
        local fov = aom_util.get_product(player)
        player:set_fov(fov, true, def.transition_time)
    end
end

--[[
aom_util.set_fov(player, {
    tag = "aom_telescope:zoom",
    fov = 0.2,
    transition_time = 0.1,
})
]]--
