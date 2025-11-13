
bhk_main.state = MFSM.new({
	_MFSM_states = {
        {
            name = "freeplay",
			on_step = function(self, dtime, meta)
				-- meta._t = (meta._t or 0) - dtime
				-- local nt = 0.1
				-- if meta._t > 0 then return else meta._t = meta._t + nt end
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					bhk_main.do_tasks(player, dtime, pi)
				end
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
        {
            name = "planning",
			---@param self MFSM
			on_step = function(self, dtime, meta)
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
				end
				if meta.state_time > 3 then
					self:set_state("play", true, true)
				end
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
        {
            name = "play",
			on_step = function(self, dtime, meta)
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					bhk_main.do_tasks(player, dtime, pi)
				end
				if meta.state_time > 3 then
					self:set_state("planning", true, true)
				end
			end,
            on_start = function(self, meta)
				bhk_main.game_pause = false
            end,
            on_end = function(self, meta)
				bhk_main.game_pause = true
            end,
            protected = true,
        },
	}
})
bhk_main.state:enable_globalstep()

-- bhk_main.state:set_state("freeplay", true, true)
bhk_main.state:set_state("planning", true, true)
