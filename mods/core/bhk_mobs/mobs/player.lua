
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
	_tasks = {},
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
	---@param dtime number
	---@param moveresult table|nil
	---@return any
	on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
		local pi = assert(bhk_main.pi(self._parent))

		bhk_mobs.walker.handle_pause(self, dtime)
		-- don't do anything more if paused
		if self._paused then
			return
		end
		self._gun:_on_step(dtime)

		if self._target and not self._target.object:get_pos() then
			self._target = nil
		end

		if self._int_target:on_timer(dtime) then
			bhk_mobs.get_target(self, nil)
		end

		bhk_mobs.walker.check_los(self, dtime)
		bhk_mobs.walker.handle_animations(self, dtime)
		bhk_mobs.walker.rotate_to_movement(self, dtime)

		local tpos = self._target and self._target.object:get_pos()
		if tpos and self._has_los then
			self._look_pos = tpos
			bhk_mobs.walker.aim_at(self, dtime, self._look_pos, 5)
			bhk_mobs.walker.check_fire_gun(self, dtime)
		elseif self._look_pos then
			bhk_mobs.walker.aim_at(self, dtime, self._look_pos, 100)
		end

		if self._turret_yaw and pi.fow_blocker then
			pi.fow_blocker._look_yaw = self._turret_yaw
		end
		self._last_pos = self.object:get_pos()
	end,
	on_activate = function(self, staticdata)
		self._gun = bhk_main.player_gun.new()
		self._int_los = bhk_main.InTimer.new(0.1)
		self._int_target = bhk_main.InTimer.new(0.1)
		self._tasks = {}
	end,
}
core.register_entity("bhk_mobs:fplayer", fplayer)
