
```lua
local gundef = exord_gunlike.GunDef.new({
	name = "testgun",
	mag_cap = 30,
	fire_rpm = 600,
	-- chambered = 1,
	-- infinite = true,
	is_full_auto = true,
	penetrations = 1,
	BulletDef = exord_gunlike.BulletDef.new_def({
		speed = 20,
		acceleration = vector.new(0,-9,0),
		max_range = 100,
		max_time = 5,
		on_impact_node = function(self, pointed_thing, is_final_impact)
			if is_final_impact then
				core.log("hit node " .. tostring(self))
			end
			return true
		end,
	}),
	get_fire_pos_dir = function(self)
		return self.pos, self.dir
	end,
	sound_fire_loop_start = {
		name = "exord_gunlike_testsound",
		pitch = 1.5,
	},
	sound_fire_loop_end = {},
	sound_fire_loop = {},
	sound_fire = {},
	sound_reload_start = {},
	sound_reload_end = {},
	sound_empty = {},
})

local gun = gundef.new()
gun.dir = vector.new(0.2,-0.5,0.2)
gun.pos = vector.new(80,80,60)

local t = 0
core.register_globalstep(function(dtime)
	gun:_on_step(dtime)
	t = t + dtime
	if t > 2 and t < 5 then
		-- gun:fire_round(vector.new(80,80,60), vector.new(0.2,-0.5,0.2), nil)
		gun:signal_firing()
	end
end)
```