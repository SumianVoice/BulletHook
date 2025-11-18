
bhk_main.player_on_join_state = "waiting"
if bhk_main.dev_mode then
	bhk_main.player_on_join_state = "dev"
end

bhk_main.playerstate_proto = {
	_MFSM_states = {
		{name = "dev"},
		{name = "waiting",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "start",
			on_step = function(self, dtime, meta)
			end,
			---@param self MFSM
			on_start = function(self, meta)
				if not core.is_player(self._MFSM_host) then return end
				self._MFSM_host:set_pos(vector.new(
					(bhk_main.gamearea_min.x + bhk_main.gamearea_max.x) * 0.5,
					bhk_main.get_game_area_floor() + 12,
					(bhk_main.gamearea_min.z + bhk_main.gamearea_max.z) * 0.5
				))
				self:set_state("planning", true, true)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "planning",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
		{name = "play",
			on_step = function(self, dtime, meta)
			end,
			on_start = function(self, meta)
			end,
			on_end = function(self, meta)
			end,
		},
	},
}

core.register_globalstep(function(dtime)
	for i, player in ipairs(core.get_connected_players()) do
		local pi = assert(bhk_main.pi(player))
		if not pi.MFSM then
			pi.MFSM = MFSM.new(bhk_main.playerstate_proto)
			pi.MFSM._MFSM_host = player
			if bhk_main.dev_mode then
				pi.MFSM:set_state("dev", true)
			else
				pi.MFSM:set_state(bhk_main.player_on_join_state, true)
			end
		else
			pi.MFSM:on_step(dtime)
		end
	end
end)

bhk_main.state = MFSM.new({
	_MFSM_states = {
        {name = "mapgen",
			---@param self MFSM
			on_step = function(self, dtime, meta)
				if not meta.mapgen_started then
					core.log("[mapgen] started")
					meta.mapgen_started = true
					bhk_mapgen.generate_map(9867, function()
						meta.ready = true
					end)
				end
				if meta.ready then
					core.log("[mapgen] ready")
					self:set_state("play", true, true)
				end
			end,
			---@param self MFSM
            on_start = function(self, meta)
				bhk_main.game_pause = true
            end,
			---@param self MFSM
            on_end = function(self, meta)
            end,
            protected = false,
        },
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
				bhk_main.game_pause = true
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
				local pos = bhk_main.gamearea_min + vector.new(5, 0, 5)
				local obj = core.add_entity(pos, "bhk_mobs:walker")
				local ent = obj and obj:get_luaentity()
				if ent then
					ent._team = 2
				end
            end,
            on_end = function(self, meta)
            end,
            protected = false,
        },
	}
})
bhk_main.state:enable_globalstep()

-- bhk_main.state:set_state("freeplay", true, true)
bhk_main.state:set_state("mapgen", true, true)
