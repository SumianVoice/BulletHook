
local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class mob_walker
local mob_walker = {
	initial_properties = {
		textures = {
			"bhk_fplayer.png^[hsl:20:0:0^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
		},
		visual = "mesh",
		mesh = "bhk_fplayer.glb",
		use_texture_alpha = true,
		-- pointable = false,
		physical = false,
		static_save = false,
		selectionbox = {
			-0.6, 0,   -0.6,
			 0.6, 2.2,  0.6,
		},
	},
	-- customization
	_team = 2,
	_hp = 10,
	_view_fov = math.pi/2,
	-- controls
	_look_pos = nil,
	_aim_pos = nil,
	_target = nil,
	_paused = false,
	-- backend
	_is_active_character = true,
	_parent = nil,
	_turret_offset = vector.new(0, 54, 0) / 32,
	_muzzle_offset = vector.new(0, 7, 33) / 32,
	---@type GunDef|nil
	_gun = nil,
	-- animation and bone overrides
	_anim = nil,
	_cab_yaw = 0,
	_turret_yaw = 0,
	_turret_elevation = 0,
	_turret_move_speed = 3,
	-- mob only
	_has_los = false,
	_time_since_los = 0,
	_last_target_los_pos = nil,
	_path_cooldown = 0,
	_target_loss_time = 10,

	---@param self mob_walker
	_get_muzzle_position = function(self)
		local pos = self.object:get_pos()
		local tpos = vector.rotate_around_axis(self._turret_offset, UP, self._turret_yaw)
		local moff = vector.rotate_around_axis(self._muzzle_offset, UP, self._turret_yaw)
		local mpos = tpos + vector.rotate_around_axis(moff, RIGHT, self._turret_elevation)
		return pos + mpos
	end,
	---@param self mob_walker
	_aim_at = function(self, dtime, pos)
		local fpos = self.object:get_pos()
		local spos = self._aim_pos or fpos
		self._aim_pos = bhk_main.vector_move_toward(spos, pos, dtime * self._turret_move_speed)

		local dir = vector.direction(fpos, self._aim_pos)
		local tyaw = core.dir_to_yaw(dir)
		self._turret_yaw = tyaw
		self.object:set_bone_override("turret", {
			rotation = {
				vec = vector.new(0, -self._turret_yaw, 0),
				interpolation = 0.1,
				absolute = true,
			}
		})
		bhk_main.debug_particle(self._aim_pos, "#fff", 0.2)
	end,
	---@param self mob_walker
	_move_toward = function(self, dtime, pos)
	end,
	---@param self mob_walker
	_check_los = function(self, dtime)
		if self._int_los:on_timer(dtime) then
			if self._target and bhk_mobs.has_los_to_target(self, self._target) then
				self._has_los = true
				self._time_since_los = 0
				if self._target then
					self._last_target_los_pos = self._target.object:get_pos()
				end
			else
				self._has_los = false
			end
		end
	end,
	_MFSM_name = "walker",
	_MFSM_states = {
		{name = "idle",
			---@param self mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#555", 0.2)
				if self._paused then return end
				if meta.int_target:on_timer(dtime) then
					bhk_mobs.get_target(self, nil)
				end
				if self._target then
					return MFSM.set_state(self, "attack", true, true)
				end
			end,
			on_start = function(self, meta)
				meta.int_target = bhk_main.InTimer.new(1)
				self.object:set_velocity(vector.new(0, 0, 0))
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "chase",
			---@param self mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#00f", 0.2)
				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				self:_check_los(dtime)

				if self._has_los then
					return MFSM.set_state(self, "attack", true, true)
				else
					self._time_since_los = self._time_since_los + dtime
				end
				if self._time_since_los > 3 then
					self._target = nil
				end

				if (not self._target) and (meta.state_time > self._target_loss_time) then
					return MFSM.set_state(self, "idle", true, true)
				end

				local dist = self._target and vector.distance(self._target.object:get_pos(), self.object:get_pos())

				if dist and (dist > 3) then
					local target_pos = self._target.object:get_pos()
					local dir = bhk_mobs.check_get_path_dir(self, target_pos, false)
					self.object:set_velocity(dir or vector.new(0, 0, 0))
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "attack",
			---@param self mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#f00", 0.2)
				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				self:_check_los(dtime)

				local fpos = self.object:get_pos()

				local dist = self._target and vector.distance(self._target.object:get_pos(), self.object:get_pos())
				if dist and (dist > 7) then
					local target_pos = self._target.object:get_pos()
					local dir = bhk_mobs.check_get_path_dir(self, target_pos, false)
					self.object:set_velocity(dir or vector.new(0, 0, 0))
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end

				if self._target and self._has_los then
					self._look_pos = self._target.object:get_pos()
					self:_aim_at(dtime, self._look_pos)
				elseif self._look_pos then
					self:_aim_at(dtime, self._look_pos)
				end

				if self._target and self._has_los
				and (bhk_mobpath.dist2(self._aim_pos, self._target.object:get_pos()) < 0.5^2) then
					local target_pos = self._target.object:get_pos()
					self._gun.pos = self:_get_muzzle_position()
					self._gun.dir = vector.direction(self._gun.pos, vector.offset(target_pos, 0, 1.5, 0))
					self._gun:signal_firing()
				end

				if (not self._has_los) and (meta.state_time > 1) then
					return MFSM.set_state(self, "chase", true, true)
				end
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
	},
	---@param self mob_walker
	---@param dtime number
	---@param moveresult table|nil
	---@return any
	on_step = function(self, dtime, moveresult)
		if bhk_main.game_pause and not self._paused then
			self._paused = true
			self.object:set_animation_frame_speed(0.3)
		elseif (not bhk_main.game_pause) and self._paused then
			self._paused = false
			self.object:set_animation_frame_speed(1)
		end
		if not self._paused then
			self._gun:_on_step(dtime)
			self._path_cooldown = math.max(0, self._path_cooldown - dtime)
		end

		MFSM.on_step(self, dtime)

		if self._target then
			bhk_main.debug_particle(self._aim_pos, "#0f0", 0.2)
		else
			bhk_main.debug_particle(self._aim_pos, "#f00", 0.2)
		end
	end,
	on_activate = function(self, staticdata)
		self._gun = bhk_main.player_gun.new()
		self._int_los = bhk_main.InTimer.new(0.3)
		MFSM.set_state(self, "idle", true, true)
	end,
}

core.register_entity("bhk_mobs:walker", mob_walker)
