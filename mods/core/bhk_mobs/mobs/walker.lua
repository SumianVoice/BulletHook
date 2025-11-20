
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
		pointable = false,
		physical = false,
		static_save = false,
	},
	_team = 2,
	_is_active_character = true,
	_look_pos = nil,
	_target = nil,
	_anim = nil,
	_paused = false,
	_cab_yaw = 0,
	_turret_yaw = 0,
	_turret_elevation = 0,
	_view_fov = math.pi/2,
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
	_MFSM_on_any_state_start = function(self, state_name)
		core.log("[walker state] ".. state_name)
	end,
	_look_at = function(self, dtime, pos)
	end,
	_chase = function(self, dtime, pos)
	end,
	_MFSM_name = "walker",
	_MFSM_states = {
		{name = "idle",
			---@param self mob_walker|MFSM
			on_step = function(self, dtime, meta)
				if self._paused then return end
				if not meta.int_target then
					-- core.log("no timer")
					return end
				assert(meta.int_target, dump(meta))
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
			---@param self mob_walker|MFSM
			on_step = function(self, dtime, meta)
				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				if not self._target then
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
				if meta.int_los:on_timer(dtime) then
					if self._target and not bhk_mobs.has_los_to_target(self, self._target) then
						self._target = nil
					end
				end
			end,
			on_start = function(self, meta)
				meta.int_los = bhk_main.InTimer.new(1)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "attack",
			---@param self mob_walker|MFSM
			on_step = function(self, dtime, meta)
				if self._paused then
					self.object:set_velocity(vector.new(0, 0, 0))
					return
				end

				local fpos = self.object:get_pos()
				if self._target then
					local target_pos = self._target.object:get_pos()
					if not self._look_pos then self._look_pos = self.object:get_pos() end
					self._look_pos = bhk_mobs.vector_move_toward(self._look_pos, target_pos, dtime * 3)
					self._gun.pos = self:_get_muzzle_position()
					self._gun.dir = vector.direction(self._gun.pos, vector.offset(target_pos, 0, 1.5, 0))
					self._gun:signal_firing()
				elseif self._look_pos then
					local dir = vector.direction(fpos, self._look_pos)
					local tyaw = core.dir_to_yaw(dir)
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

				if meta.int_los:on_timer(dtime) then
					if self._target and not bhk_mobs.has_los_to_target(self, self._target) then
						return MFSM.set_state(self, "chase", true, true)
					end
				end
			end,
			on_start = function(self, meta)
				meta.int_los = bhk_main.InTimer.new(1)
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
		end
		MFSM.on_step(self, dtime)
	end,
	on_activate = function(self, staticdata)
		self._gun = bhk_main.player_gun.new()
		MFSM.set_state(self, "idle", true, true)
	end,
}

core.register_entity("bhk_mobs:walker", mob_walker)
