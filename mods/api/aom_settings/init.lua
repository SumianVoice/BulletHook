local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)


aom_settings = {}
aom_settings.form = {}

aom_settings.mod_storage = core.get_mod_storage()

--  API
dofile(mod_path .. "/settings.lua")

aom_settings.register_setting("menu_technical_names", false, S("Use technical names of settings"))
aom_settings.register_setting("sound_menu_volume", 1, S("Menu volume"))

aom_settings.register_setting("debug_enabled", false, S("Debug enabled"), "server")
aom_settings.register_setting("menu_commands", false, S("Allow player menu command"), "server")

dofile(mod_path .. "/formspec_system.lua")
dofile(mod_path .. "/formspec.lua")
