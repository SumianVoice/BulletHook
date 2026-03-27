local example = {}

example.pathfinding_options = bhk_mobpath.Options.new({
	-- TRAVERSAL = function(p1, p2) return true end,
	-- BEST_GUESS_SORT = function(a_node, b_node) return (a_node.H < b_node.H) end,
	max_search = 300,
	BEST_GUESS_SORT = function(a_node, b_node)
		return a_node.H + math.min(10, a_node.G) < b_node.H + math.min(10, b_node.G)
	end,
	-- cost from last node
	G = function(p1, p2, opt)
		local node = minetest.get_node_or_nil(p2)
		local extra_cost = node and minetest.get_item_group(node.name, "traversible_extra_cost") or 0
		-- avoid walls
		local nodes = minetest.find_nodes_in_area(
			vector.offset(p2, -3, 0,-3),
			vector.offset(p2,  3, 0, 3),
			"group:traversible_extra_cost"
		)
		extra_cost = extra_cost + math.min(4, #nodes*2)

		nodes = minetest.find_nodes_in_area(
			vector.offset(p2, -2, -1,-2),
			vector.offset(p2,  2, -1, 2),
			"group:traversible_floor_extra_cost", true
		)
		local biggest_val = 0
		for nodename, list in pairs(nodes) do
			local groupval = minetest.get_item_group(nodename, "traversible_floor_extra_cost")
			local val = groupval
			if biggest_val < val then
				biggest_val = val
			end
		end
		extra_cost = extra_cost + biggest_val
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
local _options_meta = {__index = example.pathfinding_options}


local self
-- [...]
self._path = bhk_mobpath.astar(
	self.object:get_pos(), vector,
	setmetatable({custom_field = "custom value"}, _options_meta)
)

-- Or you can just use the defaults of course. The metatable is just to save on recreating the same table.
-- It allows you to input small differences.
-- In most cases you can skip this and just save a table and pass that to the function, as below:
local options = {
	-- [...]
}
bhk_mobpath.astar(vector, vector, options)
