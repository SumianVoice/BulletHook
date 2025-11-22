
function bhk_main.do_muzzle_flash(pos, vel, count, force, size, exp)
    force = force or 1
    count = count or 30
    size = size or 1
    exp = exp or 1
    vel = vel * force
    local off = vector.new(1,1,1)
    core.add_particlespawner({
        amount = count,
        time = 0.00001,
        vertical = false,
        texpool = {
            {
                name = "explosion_anim.png",
                animation = {
                    type = "vertical_frames",
                    aspect_w = 8, aspect_h = 8,
                    length = exp * 1.1,
                }
            },
            {
                name = "explosion_anim.png",
                animation = {
                    type = "vertical_frames",
                    aspect_w = 8, aspect_h = 8,
                    length = exp * 1.5,
                }
            },
        },
        glow = 14,
        -- collisiondetection = true,
        minpos = pos,
        maxpos = pos,
        minvel = vel * 0.75 - off,
        maxvel = vel + off,
        minacc = vector.new(0, 0, 0),
        maxacc = vector.new(0, 0, 0),
        drag = vector.new(1, 1, 1),
        minexptime = exp,
        maxexptime = exp,
        minsize = 4 * size,
        maxsize = 32 * size,
    })
end

function bhk_main.do_proj_muzzle_flash_typical(pos, vel, player, force, count, size, exp)
    if count >= 3 then
        bhk_main.do_muzzle_flash(pos, vel, math.ceil(count/3), force*3, 0.4 * size, exp)
        bhk_main.do_muzzle_flash(pos, vel, math.ceil(count/3), force*2, 0.4 * size, exp)
        bhk_main.do_muzzle_flash(pos, vel, math.ceil(count/3), force, 0.4 * size, exp)
        return
    end
    for i = 1, count do
        local pv = vel:normalize() + bhk_main.vec3_randrange(-0.3, 0.3)
        pv = pv * vel:length() * (math.random()*0.5+1) * force
        core.add_particle({
            size = 32 * (size or 1) * 0.4 * (math.random()/2+0.5),
            pos = pos,
            texture = "explosion_anim.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 8, aspect_h = 8,
                length = exp * 1.2,
            },
            velocity = pv,
            expirationtime = exp,
            glow = 14,
        })
    end
end

bhk_main.sounds = {
    _sound_impact_close = {
        name = "bhk_main_generic_impact_close",
        gain = 0.1,
        max_hear_distance = 30,
    },
    _sound_impact = {
        name = "bhk_main_generic_impact",
        gain = 1,
        max_hear_distance = 30,
        pitch_random = 0.5
    },
    _sound_empty = {
        name = "bhk_main_pistol_empty",
        gain = 0.9,
        max_hear_distance = 20,
    },
    _sound_reload_start = {
        name = "bhk_main_pistol_empty",
        gain = 0.9,
        max_hear_distance = 20,
    },
    _sound_reload_end = {
        name = "bhk_main_pistol_cocked",
        gain = 0.9,
        max_hear_distance = 20,
    },
}

local function do_hit_particles(pos, dir)
    bhk_main.do_proj_muzzle_flash_typical(
        pos, dir * 2,
        nil, 0.1, 10, 0.5, 0.4
    )
    bhk_main.do_proj_muzzle_flash_typical(
        pos, dir * 6,
        nil, 0.3, 10, 0.2, 0.4
    )
end

---@type GunDef
bhk_main.player_gun = exord_gunlike.GunDef.new({
	name = "testgun",
	mag_cap = 10,
	fire_rpm = 100,
	-- reload_time = 0.5,
	-- chambered = 1,
	infinite = true,
	is_full_auto = true,
	penetrations = 1,
	---@type BulletDef
	BulletDef = exord_gunlike.BulletDef.new_def({
		speed = 20000,
		acceleration = vector.new(0, 0, 0),
		max_range = 100,
		max_time = 1,
        on_impact_entity = function(self, pointed_thing, is_final_impact)
            local o = pointed_thing.ref
            local e = o and o:get_luaentity()
            if not e then return end
            if e._on_damage then
                e:_on_damage(6)
                do_hit_particles(pointed_thing.intersection_point, -vector.normalize(self.velocity))
            end
        end,
		---@param self BulletDef
		on_impact_node = function(self, pointed_thing, is_final_impact)
            do_hit_particles(pointed_thing.intersection_point, -vector.normalize(self.velocity))
			if is_final_impact then
				local sdef = table.copy(bhk_main.sounds._sound_impact)
				sdef.pos = pointed_thing.intersection_point or pointed_thing.above
				sdef.gain = (sdef.gain or 1) * bhk_main.sound_gain_multiplier
				core.sound_play(bhk_main.sounds._sound_impact.name, sdef)
			end
			return true
		end,
	}),
	---@param self GunDef
	on_fire = function(self, pos, dir)
		bhk_main.do_proj_muzzle_flash_typical(pos, dir * 6, nil, 0.2, 20, 0.6, 1)
		bhk_main.do_proj_muzzle_flash_typical(pos, dir * 22, nil, 0.2, 20, 0.2, 0.4)
	end,
	---@param self GunDef
	get_fire_pos_dir = function(self)
		return self.pos, self.dir
	end,
	sound_fire = {
        name = "bhk_main_heavy_rifle",
        gain = 1 * bhk_main.sound_gain_multiplier,
        pitch = 1,
        max_hear_distance = 220,
    },
	sound_reload_start = {
        name = "bhk_main_reload_click_in",
        gain = 1 * bhk_main.sound_gain_multiplier,
        pitch = 1,
        max_hear_distance = 220,
	},
	sound_reload_end = {},
	sound_empty = {},
})

-- local gun = bhk_main.player_gun.new()

-- gun.dir = vector.new(0.2,-0.5,0.2)
-- gun.pos = vector.new(4, bhk_main.get_game_area_floor() + 13, 4)

-- local t = 0
-- core.register_globalstep(function(dtime)
-- 	gun:_on_step(dtime)
-- 	t = t + dtime
-- 	if t > 2 and t < 8 then
-- 		-- gun:fire_round(vector.new(80,80,60), vector.new(0.2,-0.5,0.2), nil)
-- 		gun:signal_firing()
-- 	end
-- end)

