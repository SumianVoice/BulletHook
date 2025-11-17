
bhk_main.InTimer = {
	time = 0,
	interval = 1,
}

function bhk_main.InTimer.on_timer(self, dtime)
	self.time = self.time + dtime
	if self.time >= self.interval then
		self.time = self.time - self.interval
		return true
	end
end

bhk_main.InTimer.__meta = {
	__index = bhk_main.InTimer,
}

function bhk_main.InTimer.new(interval)
	return setmetatable({}, bhk_main.InTimer.__meta)
end
