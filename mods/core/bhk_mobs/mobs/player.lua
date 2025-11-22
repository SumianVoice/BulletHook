
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
	_aim_pos = nil,
	_target = nil,
	_anim = nil,
	_paused = false,
	_parent = nil,
	_cab_yaw = 0,
	_view_fov = math.pi/2,
	_turret_yaw = 0,
	_turret_elevation = 0,
	_turret_move_speed = 3,
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
	_rotate_to_movement = function(self, dtime)
		local pi = assert(bhk_main.pi(self._parent))
		local last_move_pos = bhk_main.get_queue_next_pos(self._parent, pi, 1, true, "move")
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
	end,
	---@param self fplayer
	---@param dtime number
	---@param moveresult table|nil
	---@return any
	on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
		local fpos = self.object:get_pos()
		local pi = assert(bhk_main.pi(self._parent))
		local last_look_pos = self._look_pos

		if not self._gun then self._gun = bhk_main.player_gun.new() end
		self._gun:_on_step(dtime)

		-- change animation speed based on pause
		if bhk_main.game_pause and not self._paused then
			self._paused = true
			self.object:set_velocity(vector.new(0, 0, 0))
			self.object:set_animation_frame_speed(0.3)
		elseif (not bhk_main.game_pause) and self._paused then
			self._paused = false
			self.object:set_animation_frame_speed(1.4)
		end

		-- don't do anything more if paused
		if self._paused then
			return
		end

		self:_rotate_to_movement(dtime)

		-- handle animations
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
			local spos = self._aim_pos or last_look_pos or fpos
			self._aim_pos = bhk_main.vector_move_toward(
				spos, self._target.object:get_pos(),
				dtime * self._turret_move_speed
			)
			bhk_main.debug_particle(self._aim_pos, "#f0f", 0.2)
		else
			if last_look_pos then
				local spos = self._aim_pos or last_look_pos or fpos
				self._aim_pos = bhk_main.vector_move_toward(
					spos, last_look_pos,
					dtime * self._turret_move_speed
				)
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
core.register_entity("bhk_mobs:fplayer", fplayer)
