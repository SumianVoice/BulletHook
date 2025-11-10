local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main.task_max_count = 50

function bhk_main.queue_task_move(player, pos, pi)
	pi = pi or bhk_main.pi(player)
	if #pi.tasks >= bhk_main.task_max_count then return end
	local fplayer = pi.fplayer
	if not fplayer then return end
	local start_pos = pi.last_move_pos or fplayer.object:get_pos()
	local dist = vector.distance(start_pos, pos)
	if dist < 0.1 then return end
	local cur_dist = 0
	local dir = vector.direction(start_pos, pos)
	local segment_count = math.floor(dist / 0.2)
	local last_pos = start_pos
	for i = 1, segment_count do
		local take = math.min(0.2, dist - cur_dist)
		cur_dist = cur_dist + take
		local target_pos = start_pos + (dir * cur_dist)

		local obj = core.add_entity(vector.offset(last_pos, 0, 0.1, 0), "bhk_main:gui_task_move")
		local ent = obj and obj:get_luaentity()
		if ent then
			ent:_set_target(target_pos)
			ent._parent = player
		end
		table.insert(pi.tasks, {type = "move", pos = target_pos, obj = obj})
		if cur_dist >= dist - 0.1 then break end
		last_pos = target_pos
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
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user, true)
		if not pointed_thing then return end
		bhk_main.queue_task_move(user, pointed_thing.intersection_point, pi)
    end,
    -- on_secondary_use = function(itemstack, user, pointed_thing) end,
    on_place = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user, true)
		if not pointed_thing then return end
		bhk_main.queue_task_look(user, pointed_thing.intersection_point, pi)
    end,
	range = 100,
})



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


function bhk_main.task_remove(player, pi, i)
	pi = pi or bhk_main.pi(player)
	local task = table.remove(pi.tasks, i)
	if task.obj then
		task.obj:remove()
	end
end



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

	bhk_main.task_remove(player, pi, 1)
end


core.register_entity("bhk_main:gui_task_move", {
    initial_properties = {
        textures = {
			"[fill:2x2:#05f",
		},
        visual = "mesh",
		mesh = "bhk_task_move.glb",
        use_texture_alpha = true,
        pointable = false,
        physical = false,
        static_save = false,
    },
	_set_target = function(self, tpos)
		local pos = self.object:get_pos()
		local yaw = core.dir_to_yaw(vector.direction(pos, tpos))
		local opos = (tpos - pos)
		self.object:set_bone_override("line_start", {
			rotation = {
				vec = vector.new(0, -yaw, 0),
				absolute = true,
			}
		})
		self.object:set_bone_override("line_end", {
			position = {
				vec = opos,
				interpolation = 1,
				absolute = true,
			},
			rotation = {
				vec = vector.new(0, -yaw, 0),
				absolute = true,
			}
		})
		self.object:set_bone_override("root", {
			scale = {
				vec = vector.new(10, 10, 10),
				interpolation = 1,
			}
		})
	end,
    on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
    end,
})

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
