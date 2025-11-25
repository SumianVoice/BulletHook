
local UP = vector.new(0,1,0)
local ZERO = vector.new(0,0,0)

bhk_mobs.pathfinding_options = bhk_mobpath.Options.new({
	TRAVERSAL = function(p1, p2)
		local nodes = core.find_nodes_in_area(
			vector.offset(p2, -0, -1,-0),
			vector.offset(p2,  0, -1, 0),
			"group:full_solid"
		)
		if nodes and (#nodes < 1) then return false end
		nodes = core.find_nodes_in_area(
			vector.offset(p2, -0, 1,-0),
			vector.offset(p2,  0, 1, 0),
			"group:solid"
		)
		if nodes and (#nodes >= 1) then return false end
		return true
	end,
	max_search = 300,
	BEST_GUESS_SORT = function(a_node, b_node)
		return a_node.H + math.min(10, a_node.G) < b_node.H + math.min(10, b_node.G)
	end,
	-- cost from last node
	G = function(p1, p2, opt)
		local node = core.get_node_or_nil(p2)
		local extra_cost = node and core.get_item_group(node.name, "traversible_extra_cost") or 0
		-- avoid walls
		local nodes = core.find_nodes_in_area(
			vector.offset(p2, -1, 0,-1),
			vector.offset(p2,  1, 0, 1),
			"group:full_solid"
		)
		extra_cost = extra_cost + math.min(4, #nodes*2)
		return bhk_mobpath.dist2(p1, p2) + (extra_cost)^2
	end,
	-- distance or heuristic cost from target
	H = function(p, target)
		return bhk_mobpath.dist2(p, target)
	end,
	adjacent = { -- list of offsets to try to traverse
		vector.new( 1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new( 0, 0, 1),
		vector.new( 0, 0,-1),
	}
})
-- cached metatable stuff
bhk_mobs.__options_meta = {__index = bhk_mobs.pathfinding_options}

-- get the direction to the next point in a path to the target
-- recalculate if you run out of points or the target is far away
-- remove points from the path as you reach them
---@param self table
---@param target_pos table
---@param force boolean|nil
---@return table|nil
function bhk_mobs.check_get_path_dir(self, target_pos, force)
	local pos = self.object:get_pos()
	local allow_update = force
	allow_update = allow_update or ((self._path_cooldown or 0) <= 0)
	local wants_path = (not self._path) or (#self._path < 1)
	wants_path = wants_path or (self._last_target_pos
		and bhk_mobpath.dist2(self._last_target_pos, target_pos) > bhk_mobpath.dist2(pos, target_pos)*0.9)
	allow_update = allow_update and wants_path
	if allow_update then
		self._last_target_pos = target_pos
		self._path = bhk_mobpath.astar(
			pos, target_pos,
			setmetatable({}, bhk_mobs.__options_meta)
		)
		for i, p in ipairs(self._path) do
			bhk_main.debug_particle(p, "#f00", 1, UP*5, 2)
		end
		self._path_cooldown = 2
	end

	if self._path and (#self._path > 0) then
		local next_point_in_path = self._path[#self._path]
		local dir = vector.direction(pos, next_point_in_path)
		local d2 = bhk_mobpath.dist2(pos, next_point_in_path)
		if d2 < 0.5 then
			table.remove(self._path, #self._path)
		end
		return dir
	end
end

---@param pos1 table
---@param pos2 table
---@return boolean
function bhk_mobs.line_of_sight(self, pos1, pos2)
	local ray = core.raycast(pos1, pos2, false, false, nil)
	for pt in ray do
		if pt.type == "node" and core.get_item_group(core.get_node(pt.under), "solid") then
			return false
		end
	end
	return true
end

---@param self table
---@return number|nil
function bhk_mobs.get_target_dist(self)
	local tpos = self._target and self._target.object:get_pos()
	local dist = tpos and vector.distance(tpos, self.object:get_pos())
	return dist or nil
end

function bhk_mobs.has_los_to_target(self, target)
	local pos1 = self.object:get_pos()
	local pos2 = target.object:get_pos()
	if (not pos1) or (not pos2) then return false end
	pos1.y = pos1.y + 1.5
	pos2.y = pos2.y + 1.5
	local tdir = vector.direction(pos1, pos2)
	pos2 = pos2 + tdir
	local tyaw = core.dir_to_yaw(tdir)
	if math.abs(bhk_main.angle_difference((self._turret_yaw or 0), tyaw)) > (self._view_fov / 2) then
		return false
	end
	local ray = core.raycast(pos1, pos2, false, false, nil)
	for pt in ray do
		if pt.type == "node" and core.get_item_group(core.get_node(pt.under), "solid") then
			return false
		end
	end
	return true
end

function bhk_mobs.get_target(self, flags)
	if self._target then return self._target end
	local objects = core.get_objects_in_area(bhk_main.gamearea_min, bhk_main.gamearea_max)
	for i, o in ipairs(objects) do
		local ent = o:get_luaentity()
		if ent and ent._team and (ent._team ~= self._team)
		and (bhk_mobs.has_los_to_target(self, ent)) then
			self._target = ent
			return ent
		end
	end
end

function bhk_mobs.vector_move_toward(v, p, delta)
	return v + vector.direction(v, p) * math.min(delta, vector.distance(v, p))
end
