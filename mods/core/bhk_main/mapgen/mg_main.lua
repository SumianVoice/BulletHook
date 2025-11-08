local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)

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

minetest.register_on_mods_loaded(function()
    local on_gen_list = bhk_main.get_on_generate_node_list()
    for node_name, list in pairs(on_gen_list) do
        local contentid = minetest.get_content_id(node_name)
        -- cid[node_name] = contentid -- unused
        nam[contentid] = node_name
    end
    air = minetest.get_content_id("air")
end)

register_noise({
    name = "variant",
    np = {
        offset = 0.5,
        scale = 0.5,
        spread = {x = 1, y = 1, z = 1},
        seed = 678567 + minetest.get_mapgen_setting("seed"),
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
        seed = 87602 + minetest.get_mapgen_setting("seed"),
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

local schems = {
	{name=sch("bhk_0_open_0")},
	{name=sch("bhk_0_house_0")},
	{name=sch("bhk_0_house_1")},
}

function bhk_main.generators.main(minp, maxp)
	if math.round(minp.y/80) ~= 0 then return end
    local segsize = 16
    local chunk_width = bhk_main.chunk_width or 80
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")

    local sidelen = math.floor((chunk_width/segsize))
    local permapdims3d = {x = sidelen + 2, y = chunk_width + 2, z = sidelen + 2}

    -- get the perlin noise data
    for name, p in pairs(perlin) do
        p.perlin = ((p.sidelen == sidelen) and p.perlin) or minetest.get_perlin_map(p.np, permapdims3d)
        p.data = p.perlin:get_3d_map_flat(vector.ceil(vector.divide(minp, segsize)), p.data or {})
    end

    local ni = 1
    for z = 1, sidelen do
        for x = 1, sidelen do
            ----------------------
            -- ACTUAL PLACEMENT --
            ----------------------
            local rotation_index = (math.floor(92801747 * perlin.variant.data[ni]) % #rotations) + 1
            local rotation = rotations[rotation_index]
            for y = 1, 1 or math.ceil(chunk_width / segsize) do
                local cpos = vector.new(x + to_grid(minp.x, segsize), y + to_grid(minp.y, segsize), z + to_grid(minp.z, segsize))
				-- now place the schematic
				local si = perlin.variant.data[ni]
				local schem = schems[math.floor(#schems * si) % #schems + 1]
				if schem then
					if schem.rotation_offset then
						rotation_index = (rotation + schem.rotation_offset)
						rotation = rotations[rotation_index % 4 + 1]
					end
					local y_offset = schem.y_offset or 0
					local pos = vector.new((x-1)*segsize+minp.x, (y-1)*segsize+minp.y + y_offset, (z-1)*segsize+minp.z)
					local rot = (schem.rotation and rotations[schem.rotation % 4 + 1]) or rotation
					if schem.free_rotation then
						rot = rotations[(math.floor(92801747 * perlin.variant.data[ni]) % #rotations) + 1]
					end
					pos = pos + vector.new(segsize * 0.5, 0, segsize * 0.5)
					if not core.place_schematic_on_vmanip(vm, pos, schem.name, rot, nil, true, {
						place_center_x = true,
						place_center_z = true,
					}) then
						minetest.log("warning", "FAILED TO PLACE SCHEMATIC WHEN GENERATING")
					end
				else
					error(dump(schems))
				end
				ni = ni + 1
            end
        end
    end
    -- vm:set_data(data)
    minetest.generate_decorations(vm, minp, emax)
    minetest.generate_ores(vm, minp, emax)

	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

    vm:write_to_map()
    vm:calc_lighting()
    vm:update_liquids()

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
