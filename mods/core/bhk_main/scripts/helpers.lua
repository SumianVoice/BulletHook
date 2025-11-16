
function bhk_main.is_point_inside_game_area(p)
	return bhk_main.is_box_point_overlap(bhk_main.gamearea_min, bhk_main.gamearea_max, p)
end

function bhk_main.is_box_overlap_game_area(minp, maxp)
	return bhk_main.is_box_overlap(
		bhk_main.gamearea_min, bhk_main.gamearea_max, minp, maxp
	)
end

function bhk_main.get_game_area_floor()
	return bhk_main.gamearea_min.y
end

-- minp, maxp, point
-- true if point is contained within a:b
function bhk_main.is_box_point_overlap(a, b, p)
	return (
		p.x >= a.x and p.x <= b.x and
		p.y >= a.y and p.y <= b.y and
		p.z >= a.z and p.z <= b.z
	)
end

-- minp maxp, minp maxp
-- true if any overlap between boxes
function bhk_main.is_box_overlap(min1, max1, min2, max2)
	return (
		min1.x < max2.x and max1.x > min2.x and
		min1.y < max2.y and max1.y > min2.y and
		min1.z < max2.z and max1.z > min2.z
	)
end

function bhk_main.angle_difference(a0, a1)
    local max = math.pi * 2
    local da = (a1 - a0) % max
    return 2 * da % max - da
end

function bhk_main.angle_lerp(a0, a1, t)
    return a0 + bhk_main.angle_difference(a0, a1) * t
end

function bhk_main.get_eyepos(player)
    local eyepos = vector.add(player:get_pos(), vector.multiply(player:get_eye_offset(), 0.1))
    eyepos.y = eyepos.y + player:get_properties().eye_height
    return eyepos
end

function bhk_main.get_tool_range(itemstack)
    return ((itemstack and itemstack:get_definition().range)
	or core.registered_items[""].range or 4)
end

function bhk_main.get_pointed_thing(itemstack, player, lock_y)
	local eyepos = bhk_main.get_eyepos(player)
	local point = eyepos + (player:get_look_dir() * bhk_main.get_tool_range(itemstack))
	local ray = core.raycast(eyepos, point, false, false, nil)
	for pt in ray do
		if (pt.type == "node") and (math.abs(pt.intersection_point.y - bhk_main.get_game_area_floor()) < 0.8) then
			return pt
		end
	end
end
