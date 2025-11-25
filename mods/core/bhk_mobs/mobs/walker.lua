
local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class bhk_mob_walker:bhk_walker_base
local bhk_mob_walker = {
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

	---@param self bhk_mob_walker
	_on_damage = function(self, amount)
		self._hp = self._hp - amount
		if self._hp <= 0 then
			self.object:remove()
		end
	end,
	_MFSM_name = "walker",
	_MFSM_states = {
		{name = "idle",
			---@param self bhk_mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#555", 0.2)
				if self._paused then return end

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

				if self._int_target:on_timer(dtime) then
					bhk_mobs.get_target(self, nil)
				end
				if self._target then
					return MFSM.set_state(self, "attack", true, true)
				end
			end,
			on_start = function(self, meta)
				self.object:set_velocity(vector.new(0, 0, 0))
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "chase",
			---@param self bhk_mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#00f", 0.2)
				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

				bhk_mobs.walker.check_los(self, dtime)

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
					bhk_mobs.walker.rotate_to_movement(self, dtime)
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end
				bhk_mobs.walker.handle_animations(self, dtime)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "attack",
			---@param self bhk_mob_walker
			on_step = function(self, dtime, meta)
				bhk_main.debug_particle(vector.offset(self.object:get_pos(), 0, 3, 0), "#f00", 0.2)

				bhk_mobs.walker.handle_pause(self, dtime)

				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				local dist = bhk_mobs.get_target_dist(self)
				if not dist then self._target = nil end

				local fpos = self.object:get_pos()

				local tpos = self._target and self._target.object:get_pos()

				if tpos and dist and (dist > 7) then
					local dir = bhk_mobs.check_get_path_dir(self, tpos, false)
					self.object:set_velocity((dir or vector.new(0, 0, 0)) * self._move_speed)
					bhk_mobs.walker.rotate_to_movement(self, dtime)
				else
					self.object:set_velocity(vector.new(0, 0, 0))
				end


				if tpos and self._has_los then
					self._look_pos = tpos
					bhk_mobs.walker.aim_at(self, dtime, self._look_pos)
				elseif self._look_pos then
					bhk_mobs.walker.aim_at(self, dtime, self._look_pos)
				end

				bhk_mobs.walker.check_los(self, dtime)
				bhk_mobs.walker.handle_animations(self, dtime)
				-- bhk_mobs.walker.check_fire_gun(self, dtime)

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
	---@param self bhk_mob_walker
	---@param dtime number
	---@param moveresult table|nil
	---@return any
	on_step = function(self, dtime, moveresult)
		bhk_mobs.walker.handle_pause(self, dtime)

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
		self._int_target = bhk_main.InTimer.new(0.3)
		MFSM.set_state(self, "idle", true, true)
	end,
}

core.register_entity("bhk_mobs:walker", bhk_mob_walker)
