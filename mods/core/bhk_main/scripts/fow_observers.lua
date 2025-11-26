
local function process_ent_player_fow(e, player, observers)
	local pi = assert(bhk_main.pi(player))
	local name = player:get_player_name()
	local can_see = nil
	if not e._is_active_character then
		can_see = nil
	elseif not can_see and pi.fplayer then
		if bhk_mobs.has_los_to_target(pi.fplayer, e) then
			can_see = true
		end
	end
	if pi.fplayer == e then
		can_see = true
	end
	if can_see ~= (observers[name] or false) then
		observers[name] = can_see or nil
		return true
	else
		return false
	end
end

core.register_globalstep(function(dtime)
	local ents = core.get_objects_in_area(bhk_main.gamearea_min, bhk_main.gamearea_max)
	local conplayers = core.get_connected_players()
	for k, o in ipairs(ents) do
		local e = o:get_luaentity()
		if e and (e._is_active_character ~= nil) then
			local observers = o:get_observers() or {}
			local changes = false
			for i, player in ipairs(conplayers) do
				changes = changes or process_ent_player_fow(e, player, observers)
			end
			if changes then
				o:set_observers(observers)
			end
		end
	end
end)
