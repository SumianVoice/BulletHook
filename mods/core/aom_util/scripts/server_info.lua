local S = minetest.get_translator(minetest.get_current_modname())
local save_path = minetest.get_worldpath()

local serverinfo = {
    dtimeavg = 0.1
}

minetest.register_chatcommand("serverinfo", {
    params = "",
    description = S("Tells you the avg step time"),
    privs = {},
    func = function(name, param)
        aom_util.get_abm_calls()
        -- TL: @1 is time in seconds ("0.021452")
        return true, "  " .. S("Server step avg: @1s", tostring(serverinfo.dtimeavg))
    end
})

minetest.register_globalstep(function (dtime)
    serverinfo.dtimeavg = (serverinfo.dtimeavg * 99 + dtime) / 100
end)
