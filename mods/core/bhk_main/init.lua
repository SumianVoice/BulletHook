local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main = {
    fullbright = false, --debug
    generator = "main",
	mg_name = nil,
    dev_mode = false,
    nodes_pointable = true,
	generators = {},
	flags = {
		doors_block_light = false,
	},
}

bhk_main._pl = {}
function bhk_main.pi(player)
	if not core.is_player(player) then return end
	local pi = bhk_main._pl[player]
	if not pi then
		pi = {
			tasks = {},
		}
		bhk_main._pl[player] = pi
	end
	return pi
end

bhk_main.mg_name = core.get_mapgen_setting("mg_name") or "singlenode"
bhk_main.dev_mode = (bhk_main.mg_name == "flat") or core.is_creative_enabled()

function bhk_main.debug_particle(pos, color, time, vel, size)
    -- do return end -- for debug purposes
    core.add_particle({
        size = size or 2,
        pos = pos,
        texture = "[fill:1x1:"..(color or "#fff"),
        velocity = vel or vector.new(0, 0, 0),
        expirationtime = time,
        glow = 14,
    })
end

dofile(mod_path .. "/scripts" .. "/gamestate.lua")
dofile(mod_path .. "/scripts" .. "/player.lua")
dofile(mod_path .. "/scripts" .. "/OptionList.lua")
dofile(mod_path .. "/scripts" .. "/creative.lua")
dofile(mod_path .. "/scripts" .. "/inventory.lua")
dofile(mod_path .. "/scripts" .. "/on_generate.lua")

dofile(mod_path .. "/nodes" .. "/nodes_system.lua")
dofile(mod_path .. "/nodes" .. "/main_nodes.lua")
dofile(mod_path .. "/nodes" .. "/decoration.lua")
dofile(mod_path .. "/nodes" .. "/furniture.lua")
dofile(mod_path .. "/nodes" .. "/lights.lua")
dofile(mod_path .. "/nodes" .. "/doors.lua")

dofile(mod_path .. "/mapgen" .. "/mg_main.lua")


function bhk_main.angle_difference(a0, a1)
    local max = math.pi * 2
    local da = (a1 - a0) % max
    return 2 * da % max - da
end

function bhk_main.angle_lerp(a0, a1, t)
    return a0 + bhk_main.angle_difference(a0, a1) * t
end

local _t = 0
core.register_globalstep(function(dtime)
	_t = _t + dtime; if _t > 1 then _t = _t - 1 else return end
	for i, player in ipairs(core.get_connected_players()) do
		local pos1 = vector.offset(player:get_pos(), -10, -10, -10)
		local pos2 = pos1 + vector.new(20, 20, 20)
		core.fix_light(pos1, pos2)
	end
end)

core.register_globalstep(function(dtime)
    core.set_timeofday(0.49)
end)

if bhk_main.mg_name == "flat" then
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:placeholder",
		wherein        = {"air", "group:liquid"},
		y_min = -32,
		y_max = 0,
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
else
	core.register_on_generated(bhk_main.generators.main)
	core.register_ore({
		ore_type       = "stratum",
		ore            = "bhk_main:black",
		wherein        = {"air", "group:liquid"},
		y_min = 47,
		y_max = 47,
	})
	core.set_mapgen_setting("mg_flags", "nocaves,nodungeons,light,decorations,nobiomes,ores", true)
end

core.register_on_joinplayer(function(player, last_login)
	player:set_sky({
		base_color = "#222",
		type = "plain",
		clouds = false,
	})
	if not bhk_main.dev_mode then
		player:set_sky({
			base_color = "#000",
			type = "plain",
			clouds = false,
		})
		-- player:set_fov(60, false, 0)
		-- player:set_camera({
		-- 	mode = "third",
		-- })
		-- player:set_eye_offset(
		-- 	vector.new(0,0,0),
		-- 	vector.new(0,15,-5),
		-- 	vector.new(0,0,0)
		-- )
		-- player:set_properties({
		-- 	collisionbox = {
		-- 		-0.3, -7, -0.3,
		-- 		0.3, -6, 0.3,
		-- 	},
		-- })
	end
end)


function bhk_main.get_eyepos(player)
    local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
    eyepos.y = eyepos.y + player:get_properties().eye_height
    return eyepos
end

function bhk_main.get_tool_range(itemstack)
    return ((itemstack and itemstack:get_definition().range)
	or core.registered_items[""].range or 4)
end

function bhk_main.get_pointed_thing(itemstack, player, lock_y)
	local eyepos = bhk_main.get_eyepos(player)
	local point = eyepos + (player:get_look_dir() * bhk_main.get_tool_range(itemstack))
	local ray = core.raycast(eyepos, point, false, false, nil)
	for pt in ray do
		if (pt.type == "node") and (math.abs(pt.intersection_point.y - 48) < 0.8) then
			return pt
		end
	end
end
