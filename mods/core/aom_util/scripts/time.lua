local S = minetest.get_translator(minetest.get_current_modname())

aom_util.time = {}

aom_util.time.force_time = false

aom_util.time.mod_storage = core.get_mod_storage()
local mod_storage = aom_util.time.mod_storage

minetest.register_on_mods_loaded(function()
    aom_util.time.force_time = tonumber(mod_storage:get_string("force_time")) or nil
end)

function aom_util.time.force_set_time(time)
    aom_util.time.force_time = time
    mod_storage:set_string("force_time", tostring(time))
end

function aom_util.time.set_time(time)
    if aom_util.time.force_time then
        aom_util.time.force_set_time(false)
    end
    minetest.set_timeofday(time)
end

local on_globalstep = function(dtime)
    if aom_util.time.force_time then
        minetest.set_timeofday(aom_util.time.force_time)
        return
    end
end
minetest.register_globalstep(on_globalstep)

minetest.unregister_chatcommand("time")
minetest.register_chatcommand("time", {
    params = "/time lock 0.5 ... /time day ... /time night ... /time set 0.3",
    description = S("Forcibly sets the time and keeps it there. Uses sine scale, 0 midnight, 0.5 noon, 1 midnight."),
    privs = {},
    func = function(name, params)
        local param = string.split(params, " ")
        if param[1] == "day" then
            aom_util.time.set_time(0.25)
            return true, S("Setting time to day (0.25)")
        elseif param[1] == "night" then
            aom_util.time.set_time(0.8)
            return true, S("Setting time to night (0.8)")
        end
        if param[1] == "lock" then
            local num = tonumber(param[2])
            if num then
                aom_util.time.force_set_time(num % 1)
                return true, S("Forcing time to stay at " .. tostring(num % 1))
            else
                aom_util.time.force_set_time()
                return true, S("Releasing forced time.")
            end
        end
        if param[1] == "set" then
            local num = tonumber(param[2])
            if num then
                aom_util.time.set_time(num % 1)
                -- TL: @1 number 0-1 ("0.445")
                return true, S("Setting time to @1", (num % 1))
            else
                return false, S("Error, you must supply a number.")
            end
        end
    end
})

