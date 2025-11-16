local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_mobs = {}

dofile(mod_path .. "/helpers.lua")
dofile(mod_path .. "/mobs" .. "/walker.lua")
