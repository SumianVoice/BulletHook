local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)

bhk_main.door = {}

-- bit.tobit, bit.tohex, bit.bnot, bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift, bit.arshift, bit.rol, bit.ror, bit.bswap

--[[

	00000011 -> 4dir (0-3)
	00000100 -> swing
	00001000 -> open/closed
	11110000 -> lock id (0-15 slots)
]]
---Turn a param2 number into a table.
---@param n number
---@return table
function bhk_main.door.explode_param2(n)
	return {
		dir4 = bit.band(0x3, n),							-- 00000011
		is_unlocked = bit.rshift(bit.band(0x4, n), 2) == 1,	-- 00000100
		lock_id = bit.rshift(bit.band(0xF8, n), 3),			-- 11111000
	}
end

---Turn a table value from `bhk_main.door.explode_param2` back into a param2 number.
---@param t table
---@return number
function bhk_main.door.combine_param2(t)
	return (
		(t.dir4) +
		(t.is_unlocked and 0x4 or 0) +
		bit.lshift(t.lock_id, 3)
	)
end

function bhk_main.door.on_timer(pos, elasped)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	local is_open = def._door_open
	if not is_open then return end
	local itemstack = ItemStack("")
	bhk_main.door.activate_door(pos, node, nil, itemstack, nil)
end

function bhk_main.door.on_wrong_key(pos, node, clicker, itemstack, pointed_thing, info)
	if (info.lock_id ~= 1) and clicker and core.is_player(clicker) then
		core.chat_send_player(clicker:get_player_name(), S("Missing key: @1", tostring(info.lock_id)))
	end
	local idef = itemstack:get_definition() or {}
	if idef._on_unlock_fail then
		idef._on_unlock_fail(itemstack, clicker, pointed_thing)
	else
		local def = core.registered_nodes[node.name]
		local door_handle_pos = pos + core.fourdir_to_dir((info.dir4 + (def._door_handle_rot or 1)) % 4)
		core.sound_play("bhk_key_rattle_0", {
			pos = door_handle_pos,
			gain = 0.3,
		})
	end
end

function bhk_main.door.on_correct_key(pos, node, clicker, itemstack, pointed_thing, info)
	local idef = itemstack:get_definition() or {}
	if idef._on_unlock then
		ret = idef._on_unlock(itemstack, clicker, pointed_thing)
	else
		local def = core.registered_nodes[node.name]
		local door_handle_pos = pos + core.fourdir_to_dir((info.dir4 + (def._door_handle_rot or 1)) % 4)
		core.sound_play("bhk_key_rattle_1", {
			pos = door_handle_pos,
			pitch = info.is_unlocked and 1 or 1.5,
		})
	end
end

function bhk_main.door.on_open_success(pos, node, clicker, itemstack, pointed_thing, info)
	local def = core.registered_nodes[node.name]
	local is_open = def._door_open
	local door_handle_pos = pos + core.fourdir_to_dir((info.dir4 + (def._door_handle_rot or 1)) % 4)
	if is_open then
		core.sound_play("bhk_door_opening_wood", {
			pos = door_handle_pos,
		})
	else
		core.sound_play("bhk_door_closing_wood_delay", {
			pos = door_handle_pos,
		})
	end
	if is_open and pointed_thing and bhk_main.flags.scary_doors and (not bhk_main.dev_mode) then
		core.get_node_timer(pos):start(
			((math.random(1, 1000) == 1) and bhk_main.flags.scary_doors and (3 + math.random()*5))
			or (60*60*2)
		)
	end
end

---Open/close a door. If holding a key, unlock or lock the door.
---Uses `on_rightclick` signature.
---@param pos table
---@param node table
---@param clicker table|nil
---@param itemstack table
---@param pointed_thing table|nil
---@return table|nil `itemstack`
function bhk_main.door.activate_door(pos, node, clicker, itemstack, pointed_thing)
	local old_node = table.copy(node)
	local info = bhk_main.door.explode_param2(node.param2)
	local def = core.registered_nodes[node.name]
	local ret
	if not def then return end
	local is_open = def._door_open
	local meta = itemstack:get_meta()
	local iname = itemstack:get_name()
	local id = tonumber(meta:get_string("keyid")) or core.get_item_group(iname, "key")
	local intention_open = true

	if (id == 0) and (not is_open) and (not info.is_unlocked) and clicker and core.is_player(clicker) then
		local p = clicker:get_pos()
		p.y = pos.y
		local door_dir = core.fourdir_to_dir(info.dir4)
		local player_dir = vector.direction(pos, p)
		local dot = vector.dot(door_dir, player_dir)
		if (dot > 0) and (info.lock_id > 1) then
			info.is_unlocked = not info.is_unlocked
			intention_open = false
			bhk_main.door.on_correct_key(pos, node, clicker, itemstack, pointed_thing, info)
		end
	end

	local needs_key = (info.lock_id > 0) and (not info.is_unlocked)
	local can_unlock = (info.lock_id == id) and (info.lock_id > 0)

	if id > 1 then
		if can_unlock then
			if core.get_item_group(iname, "keep_unlocked") > 0 then
				info.is_unlocked = not info.is_unlocked
				intention_open = false
			end
			bhk_main.door.on_correct_key(pos, node, clicker, itemstack, pointed_thing, info)
			local single_use = core.get_item_group(iname, "single_use")
			if (not ret) and (single_use > 0) and ((single_use == 1) or (math.random(1, single_use) == 1)) then
				ret = ItemStack(itemstack)
				ret:take_item(1)
			end
		end
	end
	-- can't open because no key
	if intention_open and needs_key then
		-- `lock_id==1` is always non-operable
		if (info.lock_id == 1) or ((not info.is_unlocked) and (not is_open)) then
			bhk_main.door.on_wrong_key(pos, node, clicker, itemstack, pointed_thing, info)
			if not bhk_main.dev_mode then return end
		end
	end
	-- actually open/close
	if intention_open then
		-- doesn't need to rotate anymore
		-- info.dir4 = (info.dir4 + (is_open and 1 or -1)) % 4
		is_open = not is_open
		node.name = def._door_alt
		bhk_main.door.on_open_success(pos, node, clicker, itemstack, pointed_thing, info)
	end
	-- finish up
	node.param2 = bhk_main.door.combine_param2(info)
	-- only spawn entity animated door if it's actually opening/closing
	if intention_open and (old_node.name ~= node.name) then
		bhk_main.door.open_with_entity(pos, old_node, node)
	else
		core.swap_node(pos, node)
		bhk_main.door.update_infotext(pos, info)
	end
	return ret
end


function bhk_main.door.open_with_entity(pos, from_node, to_node)
	local obj = core.add_entity(pos, "bhk_main:door_ENTITY")
	local ent = obj and obj:get_luaentity()
	if not ent then return end
	local from_info = bhk_main.door.explode_param2(from_node.param2)
	local from_def = core.registered_nodes[from_node.name]
	local to_info = bhk_main.door.explode_param2(to_node.param2)
	local to_def = core.registered_nodes[to_node.name]
	ent._door_pos = vector.copy(pos)
	ent._door_node = table.copy(to_node)
	ent._door_opening = to_def._door_open

	local textures = {}
	for i, tile in ipairs(from_def.tiles) do
		if type(tile) == "table" then
			textures[#textures+1] = tile.name
		else
			textures[#textures+1] = tile
		end
	end

	-- set mesh etc
	obj:set_properties({
		textures = textures,
		mesh = from_def._door_animated_mesh,
	})
	-- set animation
	local frame_range = from_def._door_animation_frames
	-- obj:set_yaw(-to_info.dir4 * math.pi/2)
	obj:set_bone_override("root", {
        rotation = {
            vec = vector.new(0, to_info.dir4 * math.pi/2, 0),
            interpolation = nil,
            absolute = false,
        }
	})
	obj:set_animation(frame_range, 24, 0, false)

	core.swap_node(pos, {name="air"})
end

local door_entity = {
	initial_properties = {
		physical = false,
		textures = {},
		visual = "mesh",
		mesh = "bhk_door_left_0.b3d",
		visual_size = {x=1.0, y=1.0},
		collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2,},
		use_texture_alpha = false,
		pointable = false,
		static_save = true,
	},
	_door_time = 20/24,
	_door_node = nil,
	_door_pos = nil,
	_door_opening = true,
	_remove_time = nil,
	_static_save = {
		"_door_node",
		"_door_pos",
		"_door_opening",
		"_remove_time",
	},
	-- force placement of opened / closed door
	_finish_openclose = function(self)
		local info = bhk_main.door.explode_param2(self._door_node.param2)
		core.swap_node(self._door_pos, self._door_node)
		if core.get_modpath("multinode") ~= nil then
			multinode.on_construct(self._door_pos)
		end
		bhk_main.door.update_infotext(self._door_pos, info)
		self._remove_time = 0.1
	end,
	on_step = function(self, dtime, moveresult)
		if self._remove_time then
			self._remove_time = self._remove_time - dtime
			if self._remove_time < 0 then
				return self.object:remove()
			end
		end
		if not self._door_time then return end
		if self._door_time < 0 then
			self._door_time = nil
			self:_finish_openclose()
		else self._door_time = self._door_time - dtime return end
	end,
	on_activate = function(self, staticdata, dtime_s)
		if (not staticdata) or (staticdata == "") then return end
		local data = core.deserialize(staticdata) or {}
		for k, v in pairs(data) do
			self[k] = v
		end
		if self._remove_time then return self.object:remove() end
		self:_finish_openclose()
	end,
	get_staticdata = function(self)
		local data = {}
		for i, k in ipairs(self._static_save) do
			data[k] = self[k]
		end
		return core.serialize(data)
	end,
}
core.register_entity("bhk_main:door_ENTITY", door_entity)

local s = 16
bhk_main.door.selection_box_closed_left = {
	type = "fixed",
	fixed = {
		-8/s, -24/s, -6/s,
		24/s,  24/s, -4/s,
	}
}
bhk_main.door.selection_box_closed_right = {
	type = "fixed",
	fixed = {
		-24/s, -24/s, -6/s,
		  8/s,  24/s, -4/s,
	}
}
bhk_main.door.selection_box_left_open = {
	type = "fixed",
	fixed = {
		-8/s, -24/s, -4/s,
		-6/s,  24/s, 28/s,
	}
}
bhk_main.door.selection_box_right_open = {
	type = "fixed",
	fixed = {
		6/s, -24/s, -4/s,
		8/s,  24/s, 28/s,
	}
}

bhk_main.door.collision_box_left_open = {
	type = "fixed",
	fixed = {
		-8/s, -24/s, 1/s,
		-6/s,  24/s, 24/s,
	}
}
bhk_main.door.collision_box_right_open = {
	type = "fixed",
	fixed = {
		6/s, -24/s, 0/s,
		8/s,  24/s, 24/s,
	}
}

function bhk_main.door.update_infotext(pos, info, meta)
	info = info or bhk_main.door.explode_param2(core.get_node(pos).param2)
	meta = meta or core.get_meta(pos)
	local key_name = ""
	do
		local keyitem = ItemStack("bhk_main:key_" .. info.lock_id)
		key_name = (keyitem:get_short_description()) or S("Unknown Key")
	end
	meta:set_string("infotext", table.concat({
		(
			(info.is_unlocked and (S"Unlocked" .. "\n"))
			or ((info.lock_id > 0) and (S"Locked" .. "\n")) or ""
		),
		(
			(info.lock_id == 0) and ""
			or (info.lock_id == 1) and ""
			--TL: @1 is name of a key ("Maintenance Key", "Storage Room Key"), @2 is a key number (key no. 2)
			or (info.lock_id > 1) and (S("Key: @1 (no. @2)", key_name, tostring(info.lock_id)) .. "\n")
			or ""
		),
	}))
end

function bhk_main.door.on_generated(pos)
	local node = core.get_node(pos)
	local info = bhk_main.door.explode_param2(node.param2)
	local meta = core.get_meta(pos)
	bhk_main.door.update_infotext(pos, info, meta)
end

core.register_node("bhk_main:door_blocker_active", {
	pointable = false, walkable = false,
	paramtype = bhk_main.flags.doors_block_light and "none" or "light",
	sunlight_propagates = not bhk_main.flags.doors_block_light,
	buildable_to = bhk_main.dev_mode,
	groups = { not_in_creative_inventory = 1, obstacle = 1, multinode_diggable = 1 },
	drawtype = bhk_main.dev_mode and "glasslike" or "airlike",
	tiles = {
		"[combine:64x64:0,0=blank.png" ..
		"^[fill:64x1:0,0:#fff" ..
		"^[fill:64x1:0,63:#fff" ..
		"^[fill:1x64:0,0:#fff" ..
		"^[fill:1x64:63,0:#fff" ..
		"^[multiply:#f00"
	},
})

core.register_node("bhk_main:door_blocker_inactive", {
	pointable = false, paramtype = "light", walkable = false,
	buildable_to = bhk_main.dev_mode,
	groups = { not_in_creative_inventory = 1, obstacle = 0, multinode_diggable = 1 },
	drawtype = bhk_main.dev_mode and "glasslike" or "airlike",
	tiles = {
		"[combine:64x64:0,0=blank.png" ..
		"^[fill:64x1:0,0:#fff" ..
		"^[fill:64x1:0,63:#fff" ..
		"^[fill:1x64:0,0:#fff" ..
		"^[fill:1x64:63,0:#fff" ..
		"^[multiply:#0f0"
	},
	sunlight_propagates = true,
})

local multinode_left = {
    nodes = {
        {vector.new( 0,-1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 0, 1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 1, 0, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 1,-1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 1, 1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 0,-1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 0, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
    },
	no_dig_if_missing_nodes = true,
}
local multinode_left_open = {
    nodes = {
        {vector.new( 0,-1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 0, 1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 1, 0, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 1,-1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 1, 1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 0,-1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 0, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
    },
	no_dig_if_missing_nodes = true,
}
local multinode_right = {
    nodes = {
        {vector.new( 0,-1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 0, 1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new(-1, 0, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new(-1,-1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new(-1, 1, 0), {name="bhk_main:door_blocker_active"}},
        {vector.new( 0,-1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 0, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
    },
	no_dig_if_missing_nodes = true,
}
local multinode_right_open = {
    nodes = {
        {vector.new( 0,-1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 0, 1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new(-1, 0, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new(-1,-1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new(-1, 1, 0), {name="bhk_main:door_blocker_inactive"}},
        {vector.new( 0,-1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 0, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
        {vector.new( 0, 1, 1), {name="bhk_main:door_blocker_inactive"}, {optional=true}},
    },
	no_dig_if_missing_nodes = true,
}

function bhk_main.door.register_door(name, i, def)
	local tile = {
		name = "bhk_door_" .. i .. ".png^[multiply:" .. def.color.main .. "^[hsl:0:-20:0" ..
		"^(bhk_door_handle_" .. i .. ".png^[multiply:" .. def.color.trim .. ")" ..
		"^(bhk_meta_overlay_dirt_3.png^[multiply:#222^[opacity:30)"
	}
	local tiles = def and def.get_tiles and def.get_tiles(def, i, name, def.color) or {
		tile, tile, {name="white.png"}
	}
	-- LEFT SIDE
	core.register_node("bhk_main:door_" .. name .. "_left_" .. i .. "", {
		description = "",
		pointable = bhk_main.nodes_pointable or false,
		groups = { solid = 1, door = 1, oddly_breakable_by_hand = 2,
			cracky = 1, furniture = 1, },
		tiles = tiles,
		drawtype = "mesh",
		mesh = "bhk_door_left_" .. i .. ".b3d",
		selection_box = bhk_main.door.selection_box_closed_left,
		collision_box = bhk_main.door.selection_box_closed_left,
		paramtype = bhk_main.flags.doors_block_light and "none" or "light",
		sunlight_propagates = not bhk_main.flags.doors_block_light,
		paramtype2 = "4dir",
		sounds = bhk_sounds.carpet(),
		on_rightclick = bhk_main.door.activate_door,
		on_timer = bhk_main.door.on_timer,
		_door_animated_mesh = "bhk_door_left_" .. i .. ".b3d",
		_door_animation_frames = {x=0, y=20},
		_door_alt = "bhk_main:door_" .. name .. "_left_open_" .. i .. "",
		_door_alt_dir = "bhk_main:door_" .. name .. "_right_" .. i .. "",
		_door_open = false,
		_door_handle_rot = 1,
		_multinode = multinode_left,
	})
	aom_tcraft.register_craft({
		output = "bhk_main:door_" .. name .. "_left_" .. i .. "",
		items = {unobtainable = 1}
	})
	core.register_node("bhk_main:door_" .. name .. "_left_open_" .. i .. "", {
		description = "",
		pointable = bhk_main.nodes_pointable or false,
		groups = { solid = 1, door = 1, oddly_breakable_by_hand = 2,
			cracky = 1, furniture = 1, not_in_creative_inventory = 1, },
		tiles = tiles,
		drawtype = "mesh",
		mesh = "bhk_door_left_open_" .. i .. ".obj",
		selection_box = bhk_main.door.selection_box_left_open,
		collision_box = bhk_main.door.collision_box_left_open,
		paramtype = "light",
		paramtype2 = "4dir",
		sunlight_propagates = true,
		sounds = bhk_sounds.carpet(),
		on_rightclick = bhk_main.door.activate_door,
		on_timer = bhk_main.door.on_timer,
		_door_animated_mesh = "bhk_door_left_" .. i .. ".b3d",
		_door_animation_frames = {x=20, y=40},
		_door_alt = "bhk_main:door_" .. name .. "_left_" .. i .. "",
		_door_alt_dir = "bhk_main:door_" .. name .. "_right_open_" .. i .. "",
		_door_open = true,
		_door_handle_rot = 1,
		_multinode = multinode_left_open,
	})


	-- RIGHT SIDE
	core.register_node("bhk_main:door_" .. name .. "_right_" .. i .. "", {
		description = "",
		pointable = bhk_main.nodes_pointable or false,
		groups = { solid = 1, door = 1, oddly_breakable_by_hand = 2,
			cracky = 1, furniture = 1, },
		tiles = tiles,
		drawtype = "mesh",
		mesh = "bhk_door_right_" .. i .. ".b3d",
		selection_box = bhk_main.door.selection_box_closed_right,
		collision_box = bhk_main.door.selection_box_closed_right,
		paramtype = bhk_main.flags.doors_block_light and "none" or "light",
		sunlight_propagates = not bhk_main.flags.doors_block_light,
		paramtype2 = "4dir",
		sounds = bhk_sounds.carpet(),
		on_rightclick = bhk_main.door.activate_door,
		on_timer = bhk_main.door.on_timer,
		_door_animated_mesh = "bhk_door_right_" .. i .. ".b3d",
		_door_animation_frames = {x=0, y=20},
		_door_alt = "bhk_main:door_" .. name .. "_right_open_" .. i .. "",
		_door_alt_dir = "bhk_main:door_" .. name .. "_left_open_" .. i .. "",
		_door_open = false,
		_door_handle_rot = -1,
		_multinode = multinode_right,
	})
	aom_tcraft.register_craft({
		output = "bhk_main:door_" .. name .. "_right_" .. i .. "",
		items = {unobtainable = 1}
	})
	core.register_node("bhk_main:door_" .. name .. "_right_open_" .. i .. "", {
	description = "",
		pointable = bhk_main.nodes_pointable or false,
		groups = { solid = 1, door = 1, oddly_breakable_by_hand = 2,
			cracky = 1, furniture = 1, not_in_creative_inventory = 1, },
		tiles = tiles,
		drawtype = "mesh",
		mesh = "bhk_door_right_open_" .. i .. ".obj",
		selection_box = bhk_main.door.selection_box_right_open,
		collision_box = bhk_main.door.collision_box_right_open,
		paramtype = "light",
		paramtype2 = "4dir",
		sunlight_propagates = true,
		sounds = bhk_sounds.carpet(),
		on_rightclick = bhk_main.door.activate_door,
		on_timer = bhk_main.door.on_timer,
		_door_animated_mesh = "bhk_door_right_" .. i .. ".b3d",
		_door_animation_frames = {x=20, y=40},
		_door_alt = "bhk_main:door_" .. name .. "_right_" .. i .. "",
		_door_alt_dir = "bhk_main:door_" .. name .. "_left_" .. i .. "",
		_door_open = true,
		_door_handle_rot = -1,
		_multinode = multinode_right_open,
	})
	bhk_main.register_on_generate_node("bhk_main:door_" .. name .. "_left_open_" .. i .. "", bhk_main.door.on_generated)
	bhk_main.register_on_generate_node("bhk_main:door_" .. name .. "_right_open_" .. i .. "", bhk_main.door.on_generated)
	bhk_main.register_on_generate_node("bhk_main:door_" .. name .. "_left_" .. i .. "", bhk_main.door.on_generated)
	bhk_main.register_on_generate_node("bhk_main:door_" .. name .. "_right_" .. i .. "", bhk_main.door.on_generated)
end

local function get_tiles(def, i, _variant, color)
	return {{
		name = "bhk_door_" .. 0 .. ".png^[multiply:" .. color.main .. "^[hsl:0:-20:0" ..
		"^(bhk_door_handle_" .. 0 .. ".png^[multiply:" .. color.trim .. ")" ..
		"^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:50)",
		backface_culling = true,
	}}
end

for variant, color in pairs(bhk_main.node_colors) do
	bhk_main.door.register_door(variant, 0, {
		color = color,
		get_tiles = get_tiles,
	})
end

for variant, color in pairs(bhk_main.node_colors) do
	bhk_main.door.register_door(variant, 1, {
		color = color,
		get_tiles = get_tiles,
	})
end

for variant, color in pairs(bhk_main.node_colors) do
	bhk_main.door.register_door(variant, 3, {
		color = color,
		get_tiles = get_tiles,
	})
end

for variant, color in pairs(bhk_main.node_colors) do
	bhk_main.door.register_door("kick_" .. variant, 1, {
		color = color,
		get_tiles = function(def, i, _variant, _color)
			return {{
				name = "bhk_door_" .. 0 .. ".png^[multiply:" .. _color.main ..
				"^(bhk_door_kick_" .. 0 .. ".png^[multiply:" .. _color.trim .. ")" ..
				"^[hsl:0:-20:0" ..
				"^(bhk_door_handle_" .. 0 .. ".png^[multiply:" .. _color.trim .. ")" ..
				"^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:50)",
				backface_culling = true,
			}}
		end,
	})
	bhk_main.door.register_door("kick_low_" .. variant, 1, {
		color = color,
		get_tiles = function(def, i, _variant, _color)
			return {{
				name = "bhk_door_" .. 0 .. ".png^[multiply:" .. _color.main ..
				"^(bhk_door_kick_" .. 0 .. ".png^[multiply:" .. _color.trim_low .. ")" ..
				"^[hsl:0:-20:0" ..
				"^(bhk_door_handle_" .. 0 .. ".png^[multiply:" .. _color.trim .. ")" ..
				"^(bhk_meta_overlay_dirt_0.png^[multiply:#222^[opacity:50)",
				backface_culling = true,
			}}
		end,
	})
end
