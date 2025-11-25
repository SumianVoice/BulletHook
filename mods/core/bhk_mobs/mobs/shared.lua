
local UP = vector.new(0, 1, 0)
local RIGHT = vector.new(1, 0, 0)

---@class bhk_walker_base
bhk_mobs.walker = {
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
}

---@param self bhk_walker_base
function bhk_mobs.walker.handle_pause(self, dtime)
	-- change animation speed based on pause
	if bhk_main.game_pause and not self._paused then
		self._paused = true
		self.object:set_velocity(vector.new(0, 0, 0))
		self.object:set_animation_frame_speed(0.3)
	elseif (not bhk_main.game_pause) and self._paused then
		self._paused = false
		self.object:set_animation_frame_speed(1.4)
	end
end

---@param self bhk_walker_base
function bhk_mobs.walker.handle_animations(self, dtime)
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
end

---@param self bhk_walker_base
function bhk_mobs.walker.aim_at(self, dtime, pos)
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
end

---@param self bhk_walker_base
function bhk_mobs.walker.check_fire_gun(self, dtime)
	local tpos = self._target and self._target.object:get_pos()
	if tpos and self._has_los and self._aim_pos
	and (bhk_mobpath.dist2(self._aim_pos, tpos) < 0.5^2) then
		local target_pos = tpos
		self._gun.pos = self:_get_muzzle_position()
		self._gun.dir = vector.direction(self._gun.pos, vector.offset(target_pos, 0, 1.5, 0))
		self._gun:signal_firing()
	end
end

---@param self bhk_walker_base
function bhk_mobs.walker.check_los(self, dtime)
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
end

---@param self bhk_walker_base
function bhk_mobs.walker.handle_default_on_step(self, dtime)
end


---@param self bhk_walker_base
function bhk_mobs.walker.rotate_to_movement(self, dtime)
	local fpos = self.object:get_pos()
	if vector.distance(fpos, self._last_pos or fpos) < 0.00001 then return end
	local tyaw = core.dir_to_yaw(vector.direction(fpos, self._last_pos or fpos))
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
