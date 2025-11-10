
bhk_main.state = MFSM.new({
	_MFSM_states = {
        {
            name = "freeplay",
			on_step = function(self, dtime, meta)
				meta._t = (meta._t or 0) - dtime
				local nt = 0.1
				if meta._t > 0 then return else meta._t = meta._t + nt end
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					bhk_main.do_tasks(player, pi)
				end
			end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
	}
})
bhk_main.state:enable_globalstep()

bhk_main.state:set_state("freeplay", true, true)
