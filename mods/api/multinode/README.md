
# multinode
Allows larger than 1x1 nodes such as doors and other oversized objects to be easily defined.
You do not need to call any functions or hard-depend on this API under normal circumstances, but you should hard depend on it if your mod requires it to function correctly. Defining `_multinode` in your node definition is enough to trigger the API to handle the rest automatically.
```lua
core.register_node(name, {
	paramtype2 = "facedir",
	_multinode = {
		-- List of nodes to place and remove when placing and removing this node.
		-- In format `nodes[i] = {position, node, flags|nil}`. These can be any node.
		nodes = {
			{vector.new(1, 0, 0), {name="multinode:blocker"}, {optional=true}},
			{vector.new(1, 1, 0), {name="multinode:blocker"}, {optional=true}},
			{vector.new(0, 1, 0), {name="multinode:blocker"}, {optional=true}},
		},
		-- Whether to rotate the nodes above according to param2
		no_rotation = true or false and nil,
		-- Skips overriding `on_construct`, same flags for other `no_*` fields.
		no_on_construct = nil,
		no_on_destruct = nil,
		no_on_place = nil,
		-- Stops node checking and replacing its extra nodes when updated (by punch, place etc).
		no_on_node_update = nil,
		-- Stops node adding its extra nodes back if they are missing.
		no_add_nodes_again_on_update = nil,
		-- Stops node being destroyed when it detects a node missing and can't replace it.
		no_dig_if_missing_nodes = nil,
		-- If true, skips checking if all the `nodes` can be placed and just does it.
		-- Does not cause overwriting non-`buildable_to` nodes however.
		always_place = nil,
	},
	-- (optional) should return the pos and node as it would be placed, so that
	-- the api can tell where it should check for the nodes in `_multinode.node`.
	-- Returns nil if it can't place.
	_get_on_place_prediction = function(itemstack, placer, pointed_thing)
		--- [...]
		return pos, node -- or nil
	end,
})
```

