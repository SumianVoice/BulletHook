
bhk_main.player_on_join_state = "waiting"
bhk_main.state_name = "mapgen"

bhk_main.playerstate_proto = {
	_MFSM_on_any_state_start = function(self, state_name)
		core.log(tostring(state_name))
	end,
	_MFSM_states = {
		{name = "dev"},
		{name = "waiting",
			on_step = function(self, dtime, meta)
				-- core.log("waiting")
				if bhk_main.state_name == "play" then
					self:set_state("start", true, true)
				end
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
				local player = self._MFSM_host
				local pi = assert(bhk_main.pi(player))

				core.log("[player start] start")
				player:set_pos(vector.new(
					(bhk_main.gamearea_min.x + bhk_main.gamearea_max.x) * 0.5,
					bhk_main.get_game_area_floor() + 12,
					(bhk_main.gamearea_min.z + bhk_main.gamearea_max.z) * 0.5
				))

				local pos = player:get_pos()
				if not pi.fplayer then
					pos.y = bhk_main.get_game_area_floor() + 0.5
					local obj = core.add_entity(pos, "bhk_main:fplayer")
					pi.fplayer = obj and obj:get_luaentity()
					if pi.fplayer then
						pi.fplayer.object:set_observers({[player:get_player_name()] = true})
						pi.fplayer._parent = player
					end
				end

				if not pi.fow_blocker then
					pos.y = bhk_main.get_game_area_floor() + 0.59 -- + 4.51
					local obj = core.add_entity(pos, "bhk_main:fow_blocker")
					pi.fow_blocker = obj and obj:get_luaentity()
					if pi.fow_blocker then
						pi.fow_blocker.object:set_observers({[player:get_player_name()] = true})
						pi.fow_blocker._parent = player
						pi.fow_blocker._look_yaw = 0
						pi.fow_blocker._view_fov = math.pi/2
					end
				end
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
				bhk_main.state_name = "mapgen"
				bhk_main.game_pause = true
            end,
			---@param self MFSM
            on_end = function(self, meta)
				core.log("[mapgen] ended")
				for i, player in ipairs(core.get_connected_players()) do
					local pi = assert(bhk_main.pi(player))
					core.log("setting state")
					bhk_main.player_on_join_state = "start"
					pi.MFSM:set_state("start", true, true)
				end
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
				bhk_main.state_name = "planning"
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
				bhk_main.state_name = "play"
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
bhk_main.state:set_state(bhk_main.state_name, true, true)
