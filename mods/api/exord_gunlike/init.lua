local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

exord_gunlike = {}

dofile(mod_path .. "/Bullet.lua")
dofile(mod_path .. "/GunDef.lua")
dofile(mod_path .. "/system.lua")