
---@class mob_walker
local mob_walker = {
    initial_properties = {
        textures = {
			"bhk_main_placeholder_16x.png^(bhk_meta_overlay_dirt_0.png^[multiply:#112^[opacity:160)",
		},
        visual = "mesh",
		mesh = "bhk_mob_walker.glb",
        use_texture_alpha = true,
        pointable = false,
        physical = false,
        static_save = false,
    },
	_team = 0,
	_is_active_character = true,
	_aim_pos = nil,
	_target = nil,
	_anim = nil,
	_paused = false,
	_cab_yaw = 0,
	_turret_yaw = 0,
	_MFSM_states = {
		{name = "idle",
			---@param self mob_walker|MFSM
			on_step = function(self, dtime, meta)
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
		},
		{name = "attack",
			---@param self mob_walker|MFSM
			on_step = function(self, dtime, meta)
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

		if self._paused then return end
    end,
	on_activate = function(self, staticdata)
	end,
}

core.register_entity("bhk_main:mob_walker", mob_walker)
