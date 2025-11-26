
core.register_entity("bhk_main:fow_blocker", {
	initial_properties = {
		textures = {"[fill:2x2:#000000a0"},
		visual = "mesh",
		mesh = "bhk_fow_cover.glb",
		use_texture_alpha = true,
		pointable = false,
		physical = false,
		static_save = false,
	},
	_cur = -1,
	_look_yaw = 0,
	_view_fov = math.pi*3,
	_raycast_next = function(self)
		local num = 128
		self._cur = (self._cur + 1) % num
		-- self._cur = (self._cur + 1) % 32
		local yaw = -((self._cur) / num) * math.pi*2
		local max_dist = 80
		local dir = core.yaw_to_dir(yaw)
		local pos = self.object:get_pos()
		pos.y = bhk_main.get_game_area_floor() + 2
		local target_pos
		local pointed_thing
		if math.abs(bhk_main.angle_difference(self._look_yaw, yaw)) > (self._view_fov / 2) then
			target_pos = dir * 2
		else
			local ray = core.raycast(pos, pos + (dir * max_dist), false, false, nil)
			for pt in ray do
				if pt.type == "node" and core.get_item_group(core.get_node(pt.under), "solid") then
					pointed_thing = pt
					break
				end
			end
			if pointed_thing then
				local dist = vector.distance(pos, pointed_thing.intersection_point)
				target_pos = dir * dist
			else
				target_pos = dir * max_dist
			end
		end
		target_pos = target_pos * 10-- + (dir * 10)
		target_pos.y = 0
		pos = self.object:get_pos()
		-- bhk_main.debug_particle(pos + (target_pos/10), "#f0f", 2)
		self.object:set_bone_override(string.format("r.%03d", self._cur), {
			position = {
				vec = target_pos,
				interpolation = 0.2,
				-- absolute = true,
			}
		})
	end,
	on_step = function(self, dtime, moveresult)
		if not core.is_player(self._parent) then
			return self.object:remove()
		end
		-- local cl = os.clock()
		for i = 1, 128 do
			self:_raycast_next()
		end
		-- core.log(os.clock()-cl)
	end,
})
