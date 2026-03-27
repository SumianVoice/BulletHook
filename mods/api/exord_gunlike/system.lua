
exord_gunlike._pl = {}
local _pl = exord_gunlike._pl

function exord_gunlike.pi(player)
	if not _pl[player] then
		_pl[player] = {
			wl = {},
		}
	end
	return _pl[player]
end

local chars = {
	"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K",
	"L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
	"g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
}

local function get_random_string(len)
	local c = {}
	for i = 1, len do
		table.insert(c, chars[math.random(1, #chars)])
	end
	return table.concat(c)
end

local function get_new_uid(pi)
	local uid = ""
	for l = 1, 1000 do
		uid = get_random_string(8) -- 916,132,832 permutations should be enough
		if not pi.wl[uid] then return uid end
	end
end

---Gets a gun instance from an itemstack of a player
---@param itemstack table
---@param player table
---@return GunDef|nil
---@return boolean|nil
function exord_gunlike.wi(itemstack, player)
	local idef = itemstack:get_definition()
	if not idef._GunDef then return end
	local pi = exord_gunlike.pi(player)
	local meta = itemstack:get_meta()
	local uid = meta:get_string("uid")
	local is_init = false
	-- get a valid uid, try potentially many times in case you hit duplicate UIDs
	for i = 1, 1000 do
		local wi = pi.wl[uid]
		if (uid == "") then
			uid = get_new_uid(pi)
			meta:set_string("uid", uid)
			meta:set_string("description", uid)
			is_init = true
			-- core.log("NEW UID ASSIGNED TO STACK: " .. uid)
		end
		-- check uid is valid
		if (wi and wi.name == idef._GunDef.name) then
			return wi, is_init
		-- if valid but not tracked, track it
		elseif not wi then
			-- core.log("NEW WI WITH UID: " .. uid)
			pi.wl[uid] = idef._GunDef.new()
		end
	end
end

function exord_gunlike.vec3random(m, n)
	return vector.new(
		math.random() * (n-m) + m,
		math.random() * (n-m) + m,
		math.random() * (n-m) + m
	)
end

function exord_gunlike.dist2(p1, p2)
	return (p1.x - p2.x)^2 + (p1.z - p2.z)^2 + (p1.y - p2.y)^2
end


---@param player table
---@param itemstack table
---@param gd GunDef
---@param dtime number
function exord_gunlike.on_step_gun_itemstack(player, itemstack, gd, dtime)
	return gd:_on_step(dtime)
end

function exord_gunlike.on_step_player(player, dtime)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	local wield_i = player:get_wield_index()
	local wield_list = player:get_wield_list()
	for i, stack in ipairs(list) do
		local oldstack = ItemStack(stack)
		local gd, is_init = exord_gunlike.wi(stack, player)
		if gd then
			gd.is_wielded = (wield_i == i and wield_list == "main") or false
			gd._itemstack_index = i
			gd._itemstack_list = "main"
			gd.object = player
			stack = exord_gunlike.on_step_gun_itemstack(player, stack, gd, dtime) or stack
		end
		if is_init or (not oldstack:equals(stack)) then
			list[i] = stack
			-- core.log("changes made")
			inv:set_stack("main", i, stack)
		end
	end

	local pi = exord_gunlike.pi(player)
	for uid, wi in pairs(pi.wl) do
		local stack = inv:get_stack(wi._itemstack_list or "main", wi._itemstack_index)
		local idef = stack:get_definition()
		if (idef and idef._GunDef) and (stack:get_name() ~= wi.name or stack:get_meta():get_string("uid") ~= uid) then
		else
			-- core.log("removed wi for " .. uid)
			wi.removed = true
			wi:on_removed()
			pi.wl[uid] = nil
		end
	end
end

core.register_globalstep(function(dtime)
	for i, player in ipairs(core.get_connected_players()) do
		exord_gunlike.on_step_player(player, dtime)
	end
end)

