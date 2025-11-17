
--[[
IS AN INSTANCE, DATA HOLDER FOR A GUN ITSELF
PURPOSE:
	TRACK ROUNDS
	TRACK CHAMBERED ROUNDS
	KEEP REF TO ITEM OR GUN DEF
]]

---@class GunDef
exord_gunlike.GunDef = {}
exord_gunlike.GunDef.sound_id_list = {}
exord_gunlike.GunDef.sid_loop = nil
exord_gunlike.GunDef.object = nil

-- functions

function exord_gunlike.GunDef.on_init(self)
	self.sound_id_list = {}
end

function exord_gunlike.GunDef.on_step(self, dtime)
	return nil, nil
end

function exord_gunlike.GunDef.on_fire(self, pos, dir) end

function exord_gunlike.GunDef.is_intend_fire(self)
	local player = self.player
	if self.is_wielded and core.is_player(player) and player:get_player_control().dig then
		return true
	end
	return false
end

function exord_gunlike.GunDef.signal_firing(self, dir_override)
	self.intent_firing = 1
	if dir_override then
		self.dir_override = dir_override
	end
end

function exord_gunlike.GunDef.sound_play_default(self, name, log)
	local spec = self[name]
	local id
	if spec ~= nil then
		spec = table.copy(spec)
		spec.object = self.object
		spec.pos = self.pos or (self.object and self.object:get_pos())
		id = core.sound_play(spec.name, spec, not log)
	end
	if log and id then
		table.insert(self.sound_id_list, id)
		table.insert(self.sound_id_list, 60)
	end
end

function exord_gunlike.GunDef.sound_stop_all(self, fade)
	for i = #self.sound_id_list-1, 1, -2 do
		local id = self.sound_id_list[i]
		if fade then
			core.sound_fade(id, fade, 0)
		else
			core.sound_stop(id)
		end
		table.remove(self.sound_id_list, i)
		table.remove(self.sound_id_list, i)
	end
end

function exord_gunlike.GunDef.sound_loop_start_fire(self, fade)
	local spec = self["sound_fire_loop"]
	if spec then
		spec = table.copy(spec)
		spec.object = self.object
		spec.pos = self.pos or (self.object and self.object:get_pos())
		if fade then
			local gain = spec.gain or 1
			spec.gain = 0.0001
			self.sid_loop = core.sound_play(spec.name, spec, false)
			core.sound_fade(self.sid_loop, fade, gain)
		else
			self.sid_loop = core.sound_play(spec.name, spec, false)
		end
	end
	spec = self["sound_fire_loop_start"]
	if spec then
		spec = table.copy(spec)
		spec.object = self.object
		spec.pos = self.pos or (self.object and self.object:get_pos())
		core.sound_play(spec.name, spec, true)
	end
end

function exord_gunlike.GunDef.sound_loop_stop_fire(self, fade)
	if not self.sid_loop then return end
	if fade then
		core.sound_fade(self.sid_loop, fade, 0)
	else
		core.sound_stop(self.sid_loop)
	end
	local spec = self["sound_fire_loop_end"]
	if spec then
		spec = table.copy(spec)
		spec.object = self.object
		spec.pos = self.pos or (self.object and self.object:get_pos())
		core.sound_play(spec.name, spec, true)
	end
end

function exord_gunlike.GunDef.on_start_firing(self, pos, dir)
	self:sound_loop_start_fire()
end

function exord_gunlike.GunDef.on_removed(self) end

function exord_gunlike.GunDef.fire_round(self, pos, dir, parent)
	-- core.log("fire")
	dir = vector.normalize(dir + exord_gunlike.vec3random(-1,1) * self.inaccuracy)
	local bullet = self.BulletDef:new(pos, dir)
	bullet.parent = parent
	self:on_fire(pos, dir)
	exord_gunlike.GunDef.sound_play_default(self, "sound_fire", false)
end

function exord_gunlike.GunDef.on_stop_firing(self)
	self:sound_loop_stop_fire()
end

function exord_gunlike.GunDef.get_fire_pos_dir(self)
	local player = self.player
	if not core.is_player(player) then return end
	local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
	eyepos.y = eyepos.y + player:get_properties().eye_height
	return eyepos, player:get_look_dir()
end

function exord_gunlike.GunDef.handle_reload(self, dtime)
	if self.t_reload <= 0 then return end
	self.t_reload = math.max(0, self.t_reload - dtime)
	if self.t_reload <= 0 then
		exord_gunlike.GunDef.end_reload(self)
	end
end

function exord_gunlike.GunDef.start_reload(self)
	self.t_reload = self.reload_time
	self.rounds = 0
	exord_gunlike.GunDef.sound_play_default(self, "sound_reload_start", true)
end

function exord_gunlike.GunDef.end_reload(self)
	core.log("reload")
	self.rounds = self.mag_cap
	self.chambered = 0
	exord_gunlike.GunDef.sound_play_default(self, "sound_reload_end", true)
end

function exord_gunlike.GunDef._on_step(self, dtime)
	if not self.init then
		self.init = true
		self:on_init()
	end

	exord_gunlike.GunDef.handle_reload(self, dtime)

	self.chambered = math.min(1, self.chambered) + dtime * self.fire_rpm / 60
	self.t_lock = self.t_lock - dtime

	if self.t_lock <= 0 and self:is_intend_fire() then
		if self.intent_firing == 0 then
			exord_gunlike.GunDef.sound_play_default(self, "sound_empty", false)
		end
		self.intent_firing = 1
		self.is_firing = true -- can be set manually to skip "is wielded" tests
	end

	local can_fire = self:on_step(dtime)

	-- allows forcing firing
	if can_fire ~= nil then
		self.is_firing = self.is_firing and can_fire
	end

	local rounds = self.rounds
	if self.infinite then rounds = 9999999 end
	self.is_firing = (self.intent_firing > 0) and (rounds > 0) and self.is_full_auto

	if self.is_firing and self.is_full_auto then
		local pos, dir = self:get_fire_pos_dir()
		if self.dir_override then
			dir = self.dir_override
			self.dir_override = nil -- only store for one step
		end
		if not self.was_firing then
			self:on_start_firing(pos, dir)
			-- core.log("START FIRING")
		end
		for i = 1, math.floor(self.chambered) do
			if rounds <= 0 then break end
			rounds = rounds - 1
			self.chambered = self.chambered - 1
			self:fire_round(pos, dir)
		end
	end

	if (rounds < 1) and (self.t_reload <= 0) and (self.chambered >= 1) then
		self:start_reload()
	end

	-- don't bother setting if infinite
	if not self.infinite then
		self.rounds = rounds
	end

	if self.was_firing and not self.is_firing then
		self:on_stop_firing()
		-- core.log("STOP FIRING")
	end

	for i = #self.sound_id_list-1, 1, -2 do
		self.sound_id_list[i+1] = self.sound_id_list[i+1] - dtime
		if self.sound_id_list[i+1] < 0 then
			table.remove(self.sound_id_list, i)
			table.remove(self.sound_id_list, i)
		end
	end

	self.was_firing = self.is_firing
	self.is_firing = false
	self.intent_firing = 0
end

-- params

---@type BulletDef | nil
exord_gunlike.GunDef.BulletDef = nil
exord_gunlike.GunDef.intent_firing = 0
exord_gunlike.GunDef.reload_time = 2
exord_gunlike.GunDef.dir_override = nil -- forces aim to be in this dir
exord_gunlike.GunDef.is_wielded = false -- if itemstack is selected
exord_gunlike.GunDef.init = false
exord_gunlike.GunDef.is_firing = false
exord_gunlike.GunDef.is_full_auto = true
exord_gunlike.GunDef.was_firing = false
exord_gunlike.GunDef.last_itemstack = nil
exord_gunlike.GunDef.name = "no_gun_name"
exord_gunlike.GunDef.mag_cap = 30
exord_gunlike.GunDef.fire_rpm = 900
exord_gunlike.GunDef.chambered = 0
exord_gunlike.GunDef.t_lock = 1 -- time when cannot fire
exord_gunlike.GunDef.infinite = false
exord_gunlike.GunDef.muzzle_velocity = 40
exord_gunlike.GunDef.inaccuracy = 0.01 -- factor of randomness added to normalised dir
exord_gunlike.GunDef.removed = false
exord_gunlike.GunDef.rounds = 0
exord_gunlike.GunDef.t_reload = 0
exord_gunlike.GunDef.player = nil
exord_gunlike.GunDef._itemstack_index = nil
exord_gunlike.GunDef._itemstack_list = nil
exord_gunlike.GunDef.pos = nil -- default pos
exord_gunlike.GunDef.dir = nil -- default dir

-- sounds

exord_gunlike.GunDef.sound_fire_loop = nil
exord_gunlike.GunDef.sound_fire_loop_end = nil
exord_gunlike.GunDef.sound_fire_loop_start = nil
exord_gunlike.GunDef.sound_fire = nil
exord_gunlike.GunDef.sound_reload_start = nil
exord_gunlike.GunDef.sound_reload_end = nil
exord_gunlike.GunDef.sound_empty = nil


function exord_gunlike.GunDef.new(def)
	local __meta = {__index = setmetatable(def, {__index = exord_gunlike.GunDef})}
	def.new = function(into)
		return setmetatable(into or {}, __meta)
	end
	return def
end
