
local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class mob_walker
local mob_walker = {
	initial_properties = {
		textures = {
			"bhk_fplayer_mech.png" ..
			"^(bhk_fplayer_fill.png^[multiply:#87c3d8)"..
			"^(bhk_fplayer_outline.png^[multiply:#e6f6ff)"..
			"^(bhk_fplayer_accent.png^[multiply:#b9d4ee)"..
			"^(bhk_fplayer_gun.png^[multiply:#fff7cf)"..
			"^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
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
	_turret_move_speed = 3,
	_move_speed = 2,
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
	_last_pos = nil,
	---@type GunDef|nil
	_gun = nil,
	-- animation and bone overrides
	_anim = nil,
	_cab_yaw = 0,
	_turret_yaw = 0,
	_turret_elevation = 0,
	-- mob only
	_has_los = false,
	_time_since_los = 0,
	_last_target_los_pos = nil,
	_path_cooldown = 0,
	_target_loss_time = 10,

	---@param self mob_walker
	_on_damage = function(self, amount)
		self._hp = self._hp - amount
		if self._hp <= 0 then
			self.object:remove()
		end
	end,
	---@param self mob_walker
	_get_muzzle_position = function(self)
		local pos = self.object:get_pos()
		local tpos = vector.rotate_around_axis(self._turret_offset, UP, self._turret_yaw)
		local moff = vector.rotate_around_axis(self._muzzle_offset, UP, self._turret_yaw)
		local mpos = tpos + vector.rotate_around_axis(moff, RIGHT, self._turret_elevation)
		return pos + mpos
	end,
	---@param self mob_walker
	_rotate_to_movement = function(self, dtime)
		local last_move_pos = self._last_pos
		local fpos = self.object:get_pos()
		local dir = vector.direction(fpos, last_move_pos)
		if vector.length(dir) < 0.0001 then return end
		if last_move_pos then
			local tyaw = core.dir_to_yaw(dir)
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
	_handle_animations = function(self, dtime)
		-- change animation speed based on pause
		if bhk_main.game_pause and not self._paused then
			self._paused = true
			self.object:set_velocity(vector.new(0, 0, 0))
			self.object:set_animation_frame_speed(0.3)
		elseif (not bhk_main.game_pause) and self._paused then
			self._paused = false
			self.object:set_animation_frame_speed(1.4)
		end

		if self._last_pos and (vector.distance(self.object:get_pos(), self._last_pos) > 0.00001) then
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

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

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

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

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

				if dist and (dist > 3) then
					local target_pos = self._target.object:get_pos()
					local dir = bhk_mobs.check_get_path_dir(self, target_pos, false)
					self.object:set_velocity((dir or vector.new(0, 0, 0)) * self._move_speed)
					self:_rotate_to_movement(dtime)
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end
				self:_handle_animations(dtime)
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

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

				self:_check_los(dtime)

				local fpos = self.object:get_pos()

				local tpos = self._target and self._target.object:get_pos()

				if tpos and dist and (dist > 7) then
					local dir = bhk_mobs.check_get_path_dir(self, tpos, false)
					self.object:set_velocity((dir or vector.new(0, 0, 0)) * self._move_speed)
					self:_rotate_to_movement(dtime)
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end
				self:_handle_animations(dtime)

				if tpos and self._has_los then
					self._look_pos = tpos
					self:_aim_at(dtime, self._look_pos)
				elseif self._look_pos then
					self:_aim_at(dtime, self._look_pos)
				end

				if tpos and self._has_los
				and (bhk_mobpath.dist2(self._aim_pos, tpos) < 0.5^2) then
					local target_pos = tpos
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
		self._last_pos = self.object:get_pos()
	end,
	on_activate = function(self, staticdata)
		self._gun = bhk_main.player_gun.new()
		self._int_los = bhk_main.InTimer.new(0.3)
		MFSM.set_state(self, "idle", true, true)
	end,
}

core.register_entity("bhk_mobs:walker", mob_walker)
