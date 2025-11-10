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

function bhk_main.get_pointed_thing(itemstack, player)
	local eyepos = bhk_main.get_eyepos(player)
	local point = eyepos + (player:get_look_dir() * bhk_main.get_tool_range(itemstack))
	local ray = core.raycast(eyepos, point, false, false, nil)
	for pt in ray do
		if pt.type == "node" then
			return pt
		end
	end
end


bhk_main._pl = {}
function bhk_main.pi(player)
	if not core.is_player(player) then return end
	local pi = bhk_main._pl[player]
	if not pi then
		pi = {
			tasks={},
		}
		bhk_main._pl[player] = pi
	end
	return pi
end

bhk_main.task_max_count = 20

function bhk_main.queue_task_move(player, pos, pi)
	pi = pi or bhk_main.pi(player)
	if #pi.tasks >= bhk_main.task_max_count then return end
	local fplayer = pi.fplayer
	if not fplayer then return end
	local start_pos = pi.last_move_pos or fplayer.object:get_pos()
	local dist = vector.distance(start_pos, pos)
	if dist < 0.1 then return end
	local total = 0
	local dir = vector.direction(start_pos, pos)
	local segment_count = math.floor(dist / 0.2)
	for i = 1, segment_count do
		local take = math.min(0.2, dist - total)
		total = total + take
		table.insert(pi.tasks, {type = "move", pos = start_pos + (dir * total)})
		if total >= dist - 0.1 then break end
	end
	pi.last_move_pos = pos
end

function bhk_main.queue_task_look(player, pos, pi)
	core.log("LOOK")
	pi = pi or bhk_main.pi(player)
	if #pi.tasks >= bhk_main.task_max_count then
		core.log("OUT OF MOVES")
		return end
	local fplayer = assert(pi.fplayer)
	local start_yaw = pi.last_look_yaw or 0
	local yaw = core.dir_to_yaw(vector.direction(pi.last_move_pos or fplayer.object:get_pos(), pos))
	local dist = (bhk_main.angle_difference(start_yaw, yaw))
	if math.abs(dist) < 0.001 then
		core.log("TOO CLOSE")
		core.log(dump(dist))
		return end
	local segment_count = math.abs(math.ceil(dist / 0.2)) + 1
	for i = 1, segment_count do
		local to_yaw = start_yaw + dist * math.min(1, i/segment_count)
		local gui = nil
		table.insert(pi.tasks, {type = "look", yaw = to_yaw, gui = gui})
	end
	pi.last_look_yaw = yaw
	core.log("LOOK END")
end

function bhk_main.queue_task_wait(player, time, pi)
	pi = pi or bhk_main.pi(player)
	if #pi.tasks >= bhk_main.task_max_count then return end
end

core.register_tool("bhk_main:move_tool", {
    description = S("Move Tool"),
    inventory_image = "[fill:2x2:#f0f^[fill:1x1:1,0:#fff",
    wield_image = "blank.png",
    groups = {},
    on_use = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user)
		if not pointed_thing then return end
		bhk_main.queue_task_move(user, pointed_thing.intersection_point, pi)
    end,
    -- on_secondary_use = function(itemstack, user, pointed_thing) end,
    on_place = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user)
		if not pointed_thing then
			core.log("NO POINTED THING")
			return end
		bhk_main.queue_task_look(user, pointed_thing.intersection_point, pi)
    end,
	range = 100,
})



bhk_main.state = MFSM.new({
	_MFSM_states = {
        {
            name = "freeplay",
			on_step = function(self, dtime, meta)
				meta._t = (meta._t or 0) - dtime
				local nt = 0.1
				if meta._t > 0 then return else meta._t = meta._t + nt end
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					bhk_main.do_tasks(player, pi)
				end
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
	}
})
bhk_main.state:enable_globalstep()

bhk_main.state:set_state("freeplay", true, true)




core.register_globalstep(function(dtime)
	-- do return end
	for i, player in ipairs(core.get_connected_players()) do
		local pi = assert(bhk_main.pi(player))
		if not pi.fplayer then
			local pos = player:get_pos()
			pos.y = 49
			local obj = core.add_entity(pos, "bhk_main:fplayer")
			pi.fplayer = obj and obj:get_luaentity()
			if pi.fplayer then pi.fplayer._parent = player end
		end

		if not pi.fow_blocker then
			local pos = player:get_pos()
			pos.y = 52.51
			local obj = core.add_entity(pos, "bhk_main:fow_blocker")
			pi.fow_blocker = obj and obj:get_luaentity()
			if pi.fow_blocker then
				pi.fow_blocker._parent = player
				pi.fow_blocker._look_yaw = 0
				pi.fow_blocker._look_fov = math.pi/2
			end
		end
	end
end)



function bhk_main.do_tasks(player, pi)
	pi = pi or bhk_main.pi(player)
	local task = pi.tasks[1]
	if not task then return false end

	local fpos = pi.fplayer.object:get_pos()
	local bpos = pi.fow_blocker.object:get_pos()
	if task.type == "move" then
		local pos = vector.copy(task.pos)
		pos.y = fpos.y
		pi.fplayer.object:move_to(pos)
		pos.y = bpos.y
		pi.fow_blocker.object:move_to(pos)
	elseif task.type == "look" then
		pi.fplayer.object:set_yaw(task.yaw)
		-- pi.fow_blocker._look_pos = task.pos
		pi.fow_blocker._look_yaw = task.yaw
	end

	table.remove(pi.tasks, 1)
end



core.register_entity("bhk_main:fplayer", {
    initial_properties = {
        textures = {
			"[fill:2x2:#0f0",
			"[fill:2x2:#0f0",
			"[fill:2x2:#0f0",
			"[fill:2x2:#0f0",
			"[fill:2x2:#0f0",
			"[fill:2x2:#0f0",
		},
        visual = "cube",
		mesh = "",
        use_texture_alpha = true,
        pointable = false,
        physical = false,
        static_save = false,
    },
    on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
    end,
})

core.register_entity("bhk_main:fow_blocker", {
    initial_properties = {
        textures = {"[fill:2x2:#000000a0"},
        visual = "mesh",
		mesh = "bhk_fow_cover.glb",
        use_texture_alpha = true,
        pointable = false,
        physical = false,
        static_save = false,
    },
	_cur = -1,
	_look_yaw = 0,
	_look_fov = math.pi*3,
	_raycast_next = function(self)
		local num = 128
		self._cur = (self._cur + 1) % num
		-- self._cur = (self._cur + 1) % 32
		local yaw = -((self._cur) / num) * math.pi*2
		local max_dist = 40
		local dir = core.yaw_to_dir(yaw)
		local pos = self.object:get_pos()
		pos.y = 50
		local target_pos
		local pointed_thing
		if math.abs(bhk_main.angle_difference(self._look_yaw, yaw)) > (self._look_fov / 2) then
			target_pos = dir * 2
		else
			local ray = core.raycast(pos, pos + (dir * max_dist), false, false, nil)
			for pt in ray do
				if pt.type == "node" and core.get_item_group(core.get_node(pt.under), "solid") then
					pointed_thing = pt
					break
				end
			end
			if pointed_thing then
				local dist = vector.distance(pos, pointed_thing.intersection_point)
				target_pos = dir * dist
			else
				target_pos = dir * max_dist
			end
		end
		target_pos = target_pos * 10-- + (dir * 10)
		target_pos.y = 0
		pos = self.object:get_pos()
		-- bhk_main.debug_particle(pos + (target_pos/10), "#f0f", 2)
		self.object:set_bone_override(string.format("r.%03d", self._cur), {
			position = {
				vec = target_pos,
				interpolation = 0.2,
				-- absolute = true,
			}
		})
	end,
    on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
		-- local cl = os.clock()
		for i = 1, 128 do
			self:_raycast_next()
		end
		-- core.log(os.clock()-cl)
    end,
})
