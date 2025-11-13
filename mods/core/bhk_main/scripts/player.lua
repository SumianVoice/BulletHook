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
	for k = (i or #pi.tasks), 1, (forward and 1 or -1) do
		local task = pi.tasks[k]
		if task and task.type == (look_for_type or "move") then
			return forward and task.start_pos or task.pos
		end
	end
end

function bhk_main.queue_task_move(player, pos, pi)
	pi = pi or assert(bhk_main.pi(player))
	if #pi.tasks >= bhk_main.task_max_count then return end
	local fplayer = pi.fplayer
	if not fplayer then return end
	local start_pos = bhk_main.get_queue_next_pos(player, pi, nil, false) or fplayer.object:get_pos()
	local dist = vector.distance(start_pos, pos)
	if dist < 0.1 then return end

	local obj = core.add_entity(start_pos, "bhk_main:gui_task_move")
	local ent = obj and obj:get_luaentity()
	if ent then
		ent.object:set_observers({[player:get_player_name()] = true})
		ent:_set_target(pos)
		ent._parent = player
	end

	table.insert(pi.tasks, {type = "move", pos = pos, obj = obj, start_pos = start_pos, time = 0, time_total = dist/2})
end

function bhk_main.queue_task_look(player, pos, pi)
	pi = pi or assert(bhk_main.pi(player))
	if #pi.tasks >= bhk_main.task_max_count then return end
	local fplayer = assert(pi.fplayer)
	local start_pos = bhk_main.get_queue_next_pos(player, pi, nil, false, "look") or fplayer.object:get_pos()
	local last_move_pos = bhk_main.get_queue_next_pos(player, pi, nil, false) or fplayer.object:get_pos()

	table.insert(pi.tasks, {type = "look", pos = pos, start_pos = start_pos, time = 0, time_total = 1})

	local obj = core.add_entity(last_move_pos, "bhk_main:gui_task_look")
	local ent = obj and obj:get_luaentity()
	if ent then
		ent.object:set_observers({[player:get_player_name()] = true})
		ent:_set_target(pos)
		ent._parent = player
	end
	pi.tasks[#pi.tasks].obj = obj
end

function bhk_main.queue_task_wait(player, time, pi)
	pi = pi or assert(bhk_main.pi(player))
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

core.register_tool("bhk_main:move_undo", {
    description = S("Undo"),
    inventory_image = "[fill:2x2:#f00^[fill:1x1:1,0:#fff",
    wield_image = "blank.png",
    groups = {},
    -- on_secondary_use = function(itemstack, user, pointed_thing) end,
    on_place = function(itemstack, user, pointed_thing)
		local pi = bhk_main.pi(user)
		if not pi then return end
		if #pi.tasks < 1 then return end
		bhk_main.task_remove(user, pi, #pi.tasks)
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
			if pi.fplayer then
				pi.fplayer.object:set_observers({[player:get_player_name()] = true})
				pi.fplayer._parent = player
			end
		end

		if not pi.fow_blocker then
			local pos = player:get_pos()
			pos.y = 52.51
			local obj = core.add_entity(pos, "bhk_main:fow_blocker")
			pi.fow_blocker = obj and obj:get_luaentity()
			if pi.fow_blocker then
				pi.fow_blocker.object:set_observers({[player:get_player_name()] = true})
				pi.fow_blocker._parent = player
				pi.fow_blocker._look_yaw = 0
				pi.fow_blocker._look_fov = math.pi/2
			end
		end
	end
end)


function bhk_main.task_remove(player, pi, i)
	pi = pi or bhk_main.pi(player)
	if #pi.tasks < i then return end
	local task = table.remove(pi.tasks, i)
	if task.obj then
		task.obj:remove()
	end
end

function bhk_main.task_update(player, pi, i)
	pi = pi or bhk_main.pi(player)
	local task = table.remove(pi.tasks, i)
	if not task.obj then return end
	if task.type == "move" then
	elseif task.type == "look" then
	end
end



function bhk_main.do_tasks(player, dtime, pi)
	-- do return end
	pi = pi or bhk_main.pi(player)
	local task = pi.tasks[1]
	if not task then return false end
	task.time = math.min(task.time_total, math.max(0, task.time + dtime))
	local f = task.time / task.time_total

	local fpos = pi.fplayer.object:get_pos()
	local bpos = pi.fow_blocker.object:get_pos()

	if task.type == "move" then
		pi.move_target = task.pos
		local pos = (task.pos * f) + (task.start_pos * (1-f))
		pos.y = fpos.y
		pi.fplayer.object:move_to(pos, true)
		pos.y = bpos.y
		pi.fow_blocker.object:move_to(pos, true)

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
        use_texture_alpha = true,
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
        use_texture_alpha = true,
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

function bhk_main.get_target(self, range)
end

---@class fplayer
local fplayer = {
    initial_properties = {
        textures = {
			"bhk_fplayer.png^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
		},
        visual = "mesh",
		mesh = "bhk_fplayer.glb",
        use_texture_alpha = true,
        pointable = false,
        physical = false,
        static_save = false,
    },
	_team = 0,
	_is_active_character = true,
	_aim_pos = nil,
	_target = nil,
	_anim = nil,
	_paused = false,
	_parent = nil,
	_cab_yaw = 0,
	_turret_yaw = 0,
	---@param self fplayer
	---@param dtime number
	---@param moveresult table|nil
	---@return any
    on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end

		if bhk_main.game_pause and not self._paused then
			self._paused = true
			self.object:set_animation_frame_speed(0.3)
		elseif (not bhk_main.game_pause) and self._paused then
			self._paused = false
			self.object:set_animation_frame_speed(1)
		end

		if self._paused then return end

		local pi = assert(bhk_main.pi(self._parent))
		local last_move_pos = bhk_main.get_queue_next_pos(self._parent, pi, 1, true, "move")
		local last_look_pos = self._look_pos
		local fpos = self.object:get_pos()
		if last_move_pos then
			local tyaw = core.dir_to_yaw(vector.direction(fpos, last_move_pos))
			local yaw = bhk_main.angle_lerp(self._cab_yaw or 0, tyaw, 0.2)
			if math.abs(bhk_main.angle_difference(self._cab_yaw or 0, yaw)) > 0.01 then
				self._cab_yaw = yaw
				self.object:set_bone_override("cab", {
					rotation = {
						vec = vector.new(0, -yaw + math.pi, 0),
						interpolation = 0.8,
						absolute = true,
					}
				})
			end
		end

		local task = pi.tasks[1]
		if (task and task.type == "move") then
			if self._anim ~= "walk" then
				self.object:set_animation({x=20/24, y=59/24}, 1.4, 0.2, true)
				self._anim = "walk"
			end
		else
			if self._anim ~= "idle" then
				self.object:set_animation({x=0/24, y=19/24}, 1, 0.2, true)
				self._anim = "idle"
			end
		end

		if last_look_pos and not self._target then
			local tyaw = core.dir_to_yaw(vector.direction(fpos, last_look_pos))
			local yaw = bhk_main.angle_difference(self._turret_yaw or 0, tyaw)
			local amount = math.min(dtime * math.pi, math.abs(yaw))
			self._turret_yaw = ((self._turret_yaw or 0) + math.sign(yaw) * amount) % (math.pi*2)
			self.object:set_bone_override("turret", {
				rotation = {
					vec = vector.new(0, -self._turret_yaw, 0),
					interpolation = 0.1,
					absolute = true,
				}
			})
			pi.fow_blocker._look_yaw = self._turret_yaw
		end
    end,
	on_activate = function(self, staticdata)
	end,
}
core.register_entity("bhk_main:fplayer", fplayer)

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
