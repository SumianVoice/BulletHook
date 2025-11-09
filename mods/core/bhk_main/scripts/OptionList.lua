
local rngs = {}

function bhk_main.get_random_number_generator(seed)
	local rand = PcgRandom(core.get_mapgen_setting("seed"), seed)
	return function()
		return ((rand:next() / 2147483647 + 1) / 0.5) % 1
	end
end

---@class OptionList
local __option_list = {
	total = 0,
	last_index = 1,
	last_value = "",
	pcgrandom = nil,
	type = "OptionList",
	---@param self OptionList
	---@return any
	get_next_random = function(self)
		local r = (((self.pcgrandom:next() / 2147483647 + 1) / 0.5) % 1) * self.total
		for i, entry in ipairs(self) do
			r = r - entry[2]
			if r <= 0 then
				self.last_index = i
				self.last_value = entry[1]
				return self.last_value
			end
		end
	end,
	get_next_sequential = function(self)
		self.last_index = (self.last_index % #self) + 1
		return self[self.last_index][1]
	end,
}

local __meta_option_list = {
	__index = __option_list
}

---@param t table
---@param seed number | nil
---@return OptionList
function bhk_main.OptionList(t, seed)
	if t.type == "OptionList" then return t end
	t = table.copy(t)
	t.pcgrandom = PcgRandom(core.get_mapgen_setting("seed"), seed or 0)
	t.total = 0
	for i, entry in ipairs(t) do
		t.total = t.total + (entry[2] or 0)
	end
	return setmetatable(t, __meta_option_list)
end
