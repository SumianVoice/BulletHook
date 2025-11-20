
function bhk_main.get_target(self, range)
end

local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class fplayer
local fplayer = {
	initial_properties = {
		textures = {
			"bhk_fplayer.png^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
		},
		visual = "mesh",
		mesh = "bhk_fplayer.glb",
		use_texture_alpha = false,
		pointable = false,
		physical = false,
		static_save = false,
	},
	_team = 1,
	_is_active_character = true,
	_look_pos = nil,
	_target = nil,
	_anim = nil,
	_paused = false,
	_parent = nil,
	_cab_yaw = 0,
	_view_fov = math.pi/2,
	_turret_yaw = 0,
	_turret_elevation = 0,
	---@type GunDef|nil
	_gun = nil,
	_turret_offset = vector.new(0, 54, 0) / 32,
	_muzzle_offset = vector.new(0, 7, 33) / 32,
	_get_muzzle_position = function(self)
		local pos = self.object:get_pos()
		local tpos = vector.rotate_around_axis(self._turret_offset, UP, self._turret_yaw)
		local moff = vector.rotate_around_axis(self._muzzle_offset, UP, self._turret_yaw)
		local mpos = tpos + vector.rotate_around_axis(moff, RIGHT, self._turret_elevation)
		return pos + mpos
	end,
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
			self.object:set_animation_frame_speed(1.4)
		end

		if self._paused then
			self.object:set_velocity(vector.new(0, 0, 0))
			return
		end

		if not self._gun then self._gun = bhk_main.player_gun.new() end
		self._gun:_on_step(dtime)

		local pi = assert(bhk_main.pi(self._parent))
		local last_move_pos = bhk_main.get_queue_next_pos(self._parent, pi, 1, true, "move")
		local last_look_pos = self._look_pos
		local fpos = self.object:get_pos()
		if last_move_pos then
			local tyaw = core.dir_to_yaw(vector.direction(fpos, last_move_pos))
			tyaw = (-tyaw + math.pi)
			local yaw = bhk_main.angle_lerp(self._cab_yaw or 0, tyaw, 0.09)
			if math.abs(bhk_main.angle_difference(self._cab_yaw or 0, yaw)) > 0.001 then
				self._cab_yaw = yaw
				self.object:set_bone_override("hips", {
					rotation = {
						vec = vector.new(0, yaw, 0),
						interpolation = dtime + 0.08,
						absolute = true,
					}
				})
			end
		end

		local task = pi.tasks[1]

		if (task and task.type == "move") then
			if self._anim ~= "walk" then
				self.object:set_animation({x=40/24, y=79/24}, 1.4, 0.2, true)
				self._anim = "walk"
			end
		else
			if self._anim ~= "idle" then
				self.object:set_animation({x=0/24, y=19/24}, 1, 0.2, true)
				self._anim = "idle"
			end
		end

		if self._target then
			--
		else
			if last_look_pos then
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
			end
		end
		if self._turret_yaw and pi.fow_blocker then
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
	_view_fov = math.pi*3,
	_raycast_next = function(self)
		local num = 128
		self._cur = (self._cur + 1) % num
		-- self._cur = (self._cur + 1) % 32
		local yaw = -((self._cur) / num) * math.pi*2
		local max_dist = 40
		local dir = core.yaw_to_dir(yaw)
		local pos = self.object:get_pos()
		pos.y = bhk_main.get_game_area_floor() + 2
		local target_pos
		local pointed_thing
		if math.abs(bhk_main.angle_difference(self._look_yaw, yaw)) > (self._view_fov / 2) then
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
