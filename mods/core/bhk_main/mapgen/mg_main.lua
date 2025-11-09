local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)
local S = core.get_translator(mod_name)

-------------------------------
--------- DECORATIONS ---------
-------------------------------

local perlin = {}
local function register_noise(p)
    perlin[p.name] = p
end

local cid = {}
local nam = {}
local air = nil

core.register_on_mods_loaded(function()
    local on_gen_list = bhk_main.get_on_generate_node_list()
    for node_name, list in pairs(on_gen_list) do
        local contentid = core.get_content_id(node_name)
        -- cid[node_name] = contentid -- unused
        nam[contentid] = node_name
    end
    air = core.get_content_id("air")
end)

register_noise({
    name = "variant",
    np = {
        offset = 0.5,
        scale = 0.5,
        spread = {x = 1, y = 1, z = 1},
        seed = 678567 + core.get_mapgen_setting("seed"),
        octaves = 1,
        persist = 0.1,
        lacunarity = 2.0,
    },
    perlin = nil,
    data = {},
})
register_noise({
    name = "biome",
    np = {
        offset = 0.5,
        scale = 0.5,
        spread = {x = 80, y = 80, z = 80},
        seed = 87602 + core.get_mapgen_setting("seed"),
        octaves = 1,
        persist = 0,
        lacunarity = 2.0,
    },
    perlin = nil,
    data = {},
})

local rotations = {
    "0", "90", "180", "270"
}

local function to_grid(n, seg)
    seg = seg or bhk_main.chunk_width or 80
    return math.floor((n+16)/seg)
end

local function sch(name)
    return (mod_path .. "/schematics/" .. name .. ".mts")
end


local schems = bhk_main.OptionList({
	{{name=sch("bhk_0_open_0")}, 1},
	{{name=sch("bhk_0_house_0")}, 1},
	{{name=sch("bhk_0_house_1")}, 1},

	{{name=sch("bhk_0_block_0")}, 1},
	{{name=sch("bhk_0_block_1")}, 1},
	{{name=sch("bhk_0_block_2")}, 2},

	{{name=sch("bhk_0_catwalk_0")}, 0.2},
	{{name=sch("bhk_0_catwalk_1")}, 0.2},
	{{name=sch("bhk_0_catwalk_2")}, 0.2},
}, 78)

function bhk_main.generators.main(minp, maxp)
    local segsize = 16
    local chunk_width = bhk_main.chunk_width or 80
    local vm, emin, emax = core.get_mapgen_object("voxelmanip")

	if math.floor(minp.y/80) ~= 0 then
        core.generate_decorations(vm, minp, emax)
        core.generate_ores(vm, minp, emax)
        vm:write_to_map()
        vm:calc_lighting()
        vm:update_liquids()
        core.fix_light(minp, emax)
        return
    end

    local sidelen = math.floor((chunk_width/segsize))
    local permapdims3d = {x = sidelen + 2, y = chunk_width + 2, z = sidelen + 2}

    -- get the perlin noise data
    for name, p in pairs(perlin) do
        p.perlin = ((p.sidelen == sidelen) and p.perlin) or core.get_perlin_map(p.np, permapdims3d)
        p.data = p.perlin:get_3d_map_flat(vector.ceil(vector.divide(minp, segsize)), p.data or {})
    end

    local ni = 1
    for z = 0, (chunk_width - 1), segsize do
        for x = 0, (chunk_width - 1), segsize do
            ----------------------
            -- ACTUAL PLACEMENT --
            ----------------------
            local rotation_index = (math.floor(92801747 * perlin.variant.data[ni]) % #rotations) + 1
            local rotation = rotations[rotation_index]
            for y = 0, 0 or (chunk_width - 1), segsize do
                -- local cpos = vector.new(x + to_grid(minp.x, segsize), y + to_grid(minp.y, segsize), z + to_grid(minp.z, segsize))
				-- now place the schematic
				local schem = schems:get_next_random()
				if schem then
					if schem.rotation_offset then
						rotation_index = (rotation + schem.rotation_offset)
						rotation = rotations[rotation_index % 4 + 1]
					end
					local y_offset = schem.y_offset or 0
					local pos = vector.new((x)+minp.x, (y)+minp.y + y_offset, (z)+minp.z)
					local rot = (schem.rotation and rotations[schem.rotation % 4 + 1]) or rotation
					if schem.free_rotation then
						rot = rotations[(math.floor(92801747 * perlin.variant.data[ni]) % #rotations) + 1]
					end
					pos = pos + vector.new(segsize * 0.5, 0, segsize * 0.5)
					if not core.place_schematic_on_vmanip(vm, pos, schem.name, rot, nil, true, {
						place_center_x = true,
						place_center_z = true,
					}) then
						core.log("warning", "FAILED TO PLACE SCHEMATIC WHEN GENERATING")
					end
				else
					error(dump(schems))
				end
				ni = ni + 1
            end
        end
    end
    -- vm:set_data(data)
    core.generate_decorations(vm, minp, emax)
    core.generate_ores(vm, minp, emax)

    vm:write_to_map()
    vm:calc_lighting()
    vm:update_liquids()

	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    for i in area:iterp(minp, emax) do
        local pos = area:position(i)
        local dv = data[i]
        local node_name = nam[dv]
        if node_name then
            bhk_main.on_generate_node(node_name, pos)
        end
    end
    -- vm:set_data(data)
    core.fix_light(minp, emax)
end
