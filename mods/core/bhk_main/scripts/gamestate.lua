
bhk_main.player_on_join_state = "mapgen"
if bhk_main.dev_mode then
	bhk_main.player_on_join_state = "dev"
end

bhk_main.playerstate_proto = {
	_MFSM_states = {
		{name = "dev"},
		{name = "mapgen",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
				if core.is_player(self._MFSM_host) then
					self._MFSM_host:set_pos(vector.new(
						(bhk_main.gamearea_min.x + bhk_main.gamearea_max.x) * 0.5,
						bhk_main.get_game_area_floor() + 12,
						(bhk_main.gamearea_min.z + bhk_main.gamearea_max.z) * 0.5
					))
				end
			end,
			protected = false,
		},
		{name = "planning",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
			protected = false,
		},
		{name = "play",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
			protected = false,
		},
	},
}

core.register_globalstep(function(dtime)
	for i, player in ipairs(core.get_connected_players()) do
		local pi = assert(bhk_main.pi(player))
		if not pi.MFSM then
			pi.MFSM = MFSM.new(bhk_main.playerstate_proto)
			core.log(dump(pi.MFSM))
			pi.MFSM._MFSM_host = player
			pi.MFSM:set_state(bhk_main.player_on_join_state, true)
			pi.MFSM:set_state(bhk_main.player_on_join_state, false)
		else
			pi.MFSM:on_step(dtime)
		end
	end
end)

bhk_main.state = MFSM.new({
	_MFSM_states = {
        {name = "planning",
			---@param self MFSM
			on_step = function(self, dtime, meta)
				-- for i, player in ipairs(core.get_connected_players()) do
				-- 	local pi = assert(bhk_main.pi(player))
				-- end
				if meta.state_time > 3 then
					-- self:set_state("play", true, true)
				end
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = false,
        },
        {name = "play",
			on_step = function(self, dtime, meta)
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					bhk_main.do_tasks(player, dtime, pi)
				end
				if meta.state_time > 3 then
					-- self:set_state("planning", true, true)
				end
			end,
            on_start = function(self, meta)
				bhk_main.game_pause = false
            end,
            on_end = function(self, meta)
				bhk_main.game_pause = true
            end,
            protected = false,
        },
	}
})
bhk_main.state:enable_globalstep()

-- bhk_main.state:set_state("freeplay", true, true)
bhk_main.state:set_state("play", true, true)
