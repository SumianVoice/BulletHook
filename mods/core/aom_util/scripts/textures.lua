function aom_util.texture_escape(texture)
    return texture:gsub(".", {["\\"] = "\\\\", ["^"] = "\\^", [":"] = "\\:"})
end

local ew = "#ababac"
local ns = "#d2d1d5"
local bo = "#777776"
local tile_map = {
	"",
	"^[multiply:"..bo,
	"^[multiply:"..ew,
	"^[multiply:"..ew,
	"^[multiply:"..ns,
	"^[multiply:"..ns,
}
-- unfck's node lighting.
-- Luanti hardcodes `light_source` nodes to be brighter on certain faces. This counteracts that.
function aom_util.node_light_unfck(texture)
	if type(texture) == "string" then
		return {
			texture,
			texture.."^[multiply:"..bo,
			texture.."^[multiply:"..ew,
			texture.."^[multiply:"..ew,
			texture.."^[multiply:"..ns,
			texture.."^[multiply:"..ns,
		}
	elseif type(texture) == "table" then
		local t = table.copy(texture)
		for i, tile in pairs(t) do
			if type(tile) == "table" then
				tile = table.copy(tile)
				t[i] = tile
				tile.name = tile.name .. tile_map[i]
			elseif type(tile) == "string" then
				t[i] = t[i] .. tile_map[i]
			end
		end
		return t
	end
end

