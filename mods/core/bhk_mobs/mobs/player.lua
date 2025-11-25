
local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class fplayer:bhk_walker_base
local fplayer = {
	initial_properties = {
		textures = {
			"bhk_fplayer_mech.png" ..
			"^(bhk_fplayer_fill.png^[multiply:#bab8ab)"..
			"^(bhk_fplayer_outline.png^[multiply:#d4d2c5)"..
			"^(bhk_fplayer_accent.png^[multiply:#bab8ab)"..
			"^(bhk_fplayer_gun.png^[multiply:#d8ae79)"..
			"^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
		},
		visual = "mesh",
		mesh = "bhk_fplayer.glb",
		use_texture_alpha = false,
		-- pointable = false,
		physical = false,
		static_save = false,
		selectionbox = {
			-0.6, 0,   -0.6,
			 0.6, 2.2,  0.6,
		},
	},
	-- customization
	_team = 1,
	_hp = 10,
	_view_fov = math.pi/2,
	_turret_move_speed = 3,
	_move_speed = 1,
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

	---@param self fplayer
	_on_damage = function(self, amount)
		self._hp = self._hp - amount
		if self._hp < 0 then
			self._is_active_character = false
		end
	end,
	---@param self fplayer
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
		local fpos = self.object:get_pos()
		local pi = assert(bhk_main.pi(self._parent))
		local last_look_pos = self._look_pos

		bhk_mobs.walker.handle_pause(self, dtime)

		-- don't do anything more if paused
		if self._paused then
			return
		end

		bhk_mobs.walker.check_los(self, dtime)
		bhk_mobs.walker.handle_animations(self, dtime)
		bhk_mobs.walker.check_fire_gun(self, dtime)

		bhk_mobs.walker.handle_default_on_step(self, dtime)
		bhk_mobs.walker.rotate_to_movement(self, dtime)

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
		self._last_pos = self.object:get_pos()
	end,
	on_activate = function(self, staticdata)
		self._gun = bhk_main.player_gun.new()
		self._int_los = bhk_main.InTimer.new(0.3)
	end,
}
core.register_entity("bhk_mobs:fplayer", fplayer)
