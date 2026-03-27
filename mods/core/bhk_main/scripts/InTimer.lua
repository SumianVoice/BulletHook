
---@class InTimer
bhk_main.InTimer = {
	time = 0,
	interval = 1,
}

---True if interval has passed this tick.
---@param self InTimer
---@param dtime number
---@return boolean
function bhk_main.InTimer.on_timer(self, dtime)
	self.time = self.time + dtime
	if self.time >= self.interval then
		self.time = self.time - self.interval
		return true
	end
	return false
end

bhk_main.InTimer.__meta = {
	__index = bhk_main.InTimer,
}

---@param interval number
---@return InTimer
function bhk_main.InTimer.new(interval)
	local o = setmetatable({}, bhk_main.InTimer.__meta)
	o.interval = interval
	o.time = 0
	return o
end
