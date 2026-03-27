local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

bhk_main.task_max_count = 50
bhk_main.task_max_time = 5

---gets the connected position vector of the move queue
---@param player table `player`
---@param pi table|nil
---@param i number|nil
---@param forward boolean|nil
---@return table|nil 
function bhk_main.get_queue_next_pos(player, pi, i, forward, look_for_type)
	pi = pi or assert(bhk_main.pi(player))
	if not pi.fplayer then return end
	for k = (i or #pi.fplayer._tasks), 1, (forward and 1 or -1) do
		local task = pi.fplayer._tasks[k]
		if task and task.type == (look_for_type or "move") then
			return forward and task.start_pos or task.pos
		end
	end
end

function bhk_main.task_can_move(start_pos, pos)
	pos = vector.round(pos)
	start_pos = vector.round(start_pos)
	pos.y = bhk_main.get_game_area_floor() + 0.51
	start_pos.y = bhk_main.get_game_area_floor() + 0.51
	local dist = vector.distance(start_pos, pos)
	local dir = vector.direction(start_pos, pos)
	for i = 0, math.ceil(dist) do
		local p = (start_pos + (dir * i))
		p.y = bhk_main.get_game_area_floor()
		local n = core.get_node(p)
		if core.get_item_group(n.name, "full_solid") == 0 then return false end
		p.y = p.y + 1
		n = core.get_node(p)
		if core.get_item_group(n.name, "full_solid") > 0 then return false end
	end
	return true
end

function bhk_main.queue_task_move(player, pos, pi)
	pi = pi or assert(bhk_main.pi(player))
	if not pi.fplayer then return end
	if #pi.fplayer._tasks >= bhk_main.task_max_count then return end
	local fplayer = pi.fplayer
	if not fplayer then return end
	local start_pos = bhk_main.get_queue_next_pos(player, pi, nil, false) or fplayer.object:get_pos()
	local dist = vector.distance(start_pos, pos)
	if dist < 0.1 then return end

	if not bhk_main.task_can_move(start_pos, pos) then
		core.log("cannot move there")
		return
	end

	local obj = core.add_entity(start_pos, "bhk_main:gui_task_move")
	local ent = obj and obj:get_luaentity()
	if ent then
		ent.object:set_observers({[player:get_player_name()] = true})
		ent:_set_target(pos)
		ent._parent = player
	end

	table.insert(fplayer._tasks, {type = "move", pos = pos, obj = obj, start_pos = start_pos, time = 0, time_total = dist/2})
end

function bhk_main.queue_task_look(player, pos, pi)
	pi = pi or assert(bhk_main.pi(player))
	if not pi.fplayer then return end
	if #pi.fplayer._tasks >= bhk_main.task_max_count then return end
	local fplayer = assert(pi.fplayer)
	local start_pos = bhk_main.get_queue_next_pos(player, pi, nil, false, "look") or fplayer._look_pos or fplayer.object:get_pos()
	local last_move_pos = bhk_main.get_queue_next_pos(player, pi, nil, false) or fplayer.object:get_pos()

	table.insert(fplayer._tasks, {type = "look", pos = pos, start_pos = start_pos, time = 0, time_total = 1})

	local obj = core.add_entity(last_move_pos, "bhk_main:gui_task_look")
	local ent = obj and obj:get_luaentity()
	if ent then
		ent.object:set_observers({[player:get_player_name()] = true})
		ent:_set_target(pos)
		ent._parent = player
	end
	fplayer._tasks[#fplayer._tasks].obj = obj
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
		-- if not bhk_main.game_pause then return end
		bhk_main.queue_task_move(user, pointed_thing.intersection_point, pi)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user, true)
		if not pointed_thing then return end
		-- if not bhk_main.game_pause then return end
		bhk_main.queue_task_look(user, pointed_thing.intersection_point, pi)
	end,
	on_place = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		pointed_thing = bhk_main.get_pointed_thing(itemstack, user, true)
		if not pointed_thing then return end
		-- if not bhk_main.game_pause then return end
		bhk_main.queue_task_look(user, pointed_thing.intersection_point, pi)
	end,
	range = 100,
})

core.register_tool("bhk_main:move_undo", {
	description = S("Undo"),
	inventory_image = "[fill:2x2:#f00^[fill:1x1:1,0:#fff",
	wield_image = "blank.png",
	groups = {},
	-- on_secondary_use = function(itemstack, user, pointed_thing) end,
	on_place = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		if #pi.fplayer._tasks < 1 then return end
		-- if not bhk_main.game_pause then return end
		bhk_main.task_remove(user, pi, #pi.fplayer._tasks)
	end,
	range = 100,
})

core.register_tool("bhk_main:pause", {
	description = S("Toggle Pause"),
	inventory_image = "[fill:2x2:#ff0^[fill:1x1:1,0:#00f",
	wield_image = "blank.png",
	groups = {},
	-- on_secondary_use = function(itemstack, user, pointed_thing) end,
	on_place = function(itemstack, user, pointed_thing)
		if bhk_main.game_pause then
			core.log("unpause")
			bhk_main.state:set_state("play", true, true)
		else
			core.log("pause")
			bhk_main.state:set_state("planning", true, true)
		end
	end,
	range = 100,
})



core.register_globalstep(function(dtime)
	-- do return end
end)


function bhk_main.task_remove(player, pi, i)
	pi = pi or bhk_main.pi(player)
	if #pi.fplayer._tasks < i then return end
	local task = table.remove(pi.fplayer._tasks, i)
	if task.obj then
		task.obj:remove()
	end
end

function bhk_main.task_update(player, pi, i)
	pi = pi or bhk_main.pi(player)
	local task = table.remove(pi.fplayer._tasks, i)
	if not task.obj then return end
	if task.type == "move" then
	elseif task.type == "look" then
	end
end



function bhk_main.do_tasks(player, dtime, pi)
	pi.fplayer.object:set_velocity(vector.new(0,0,0))
	pi.fow_blocker.object:set_velocity(vector.new(0,0,0))
	if bhk_main.game_pause then return end
	-- do return end
	pi = pi or bhk_main.pi(player)
	local task = pi.fplayer._tasks[1]
	if not task then return false end
	task.time = math.min(task.time_total, math.max(0, task.time + dtime))
	local f = task.time / task.time_total

	local fpos = pi.fplayer.object:get_pos()
	local bpos = pi.fow_blocker.object:get_pos()

	if task.type == "move" then
		pi.move_target = task.pos
		local pos = (task.pos * f) + (task.start_pos * (1-f))
		pos.y = fpos.y
		local dir = vector.direction(fpos, task.pos)
		local dist = vector.distance(fpos, pos)
		-- pi.fplayer.object:move_to(pos, true)
		pi.fplayer.object:set_velocity(dir * (pi.fplayer._move_speed + 1 + (dist)))
		pos.y = bpos.y
		-- pi.fow_blocker.object:move_to(pos, true)

		bpos = pi.fow_blocker.object:get_pos()
		bpos.y = fpos.y
		dir = vector.direction(bpos, fpos)
		dist = vector.distance(bpos, fpos)
		pi.fow_blocker.object:set_velocity(dir * (pi.fplayer._move_speed + 1 + (dist)))

		if task.obj then
			local yaw = core.dir_to_yaw(vector.direction(fpos, pi.move_target))
			task.obj:set_bone_override("line_start", {
				position = {
					vec = (fpos - task.obj:get_pos()),
					interpolation = 0.2,
					absolute = true,
				},
				rotation = {
					vec = vector.new(0, -yaw, 0),
					absolute = true,
				},
			})
		end
	elseif task.type == "look" then
		local pos = (task.pos * f) + (task.start_pos * (1-f))
		pi.fplayer._look_pos = pos
		if not pi.fplayer._target then
			pi.fplayer._aim_pos = pos
		end
		bhk_main.debug_particle(pos, "#fff", 0.2)
	end

	if task.time >= task.time_total then
		bhk_main.task_remove(player, pi, 1)
	end
end


core.register_entity("bhk_main:gui_task_move", {
	initial_properties = {
		textures = {
			"[fill:2x2:#19f^[fill:2x2:#4af",
		},
		visual = "mesh",
		mesh = "bhk_task_move.glb",
		use_texture_alpha = false,
		pointable = false,
		physical = false,
		static_save = false,
		glow = 14,
	},
	_set_target = function(self, tpos)
		local pos = self.object:get_pos()
		local yaw = core.dir_to_yaw(vector.direction(pos, tpos))
		local opos = (tpos - pos)
		self.object:set_bone_override("line_start", {
			rotation = {
				vec = vector.new(0, -yaw, 0),
				absolute = true,
			},
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
			},
		})
		self.object:set_bone_override("root", {
			scale = {
				vec = vector.new(10, 10, 10),
				interpolation = 1,
			},
		})
	end,
	on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
	end,
})

core.register_entity("bhk_main:gui_task_look", {
	initial_properties = {
		textures = {
			"[fill:2x2:#fb0",
		},
		visual = "mesh",
		mesh = "bhk_task_look.glb",
		use_texture_alpha = false,
		pointable = false,
		physical = false,
		static_save = false,
		glow = 14,
	},
	_set_target = function(self, tpos)
		local pos = self.object:get_pos()
		local yaw = core.dir_to_yaw(vector.direction(pos, tpos))
		local opos = (tpos - pos)
		self.object:set_bone_override("line_start", {
			rotation = {
				vec = vector.new(0, -yaw, 0),
				absolute = true,
			},
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
			},
		})
		self.object:set_bone_override("root", {
			scale = {
				vec = vector.new(10, 10, 10),
				interpolation = 1,
			},
		})
	end,
	on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
	end,
})
