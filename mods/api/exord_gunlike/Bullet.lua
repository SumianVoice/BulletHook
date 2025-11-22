
---@class BulletDef
exord_gunlike.BulletDef = {}
exord_gunlike.bullet_list = {}

-- internal

function exord_gunlike.BulletDef.get_pos(self) return vector.copy(self.pos) end
function exord_gunlike.BulletDef.set_pos(self, pos) self.pos = vector.copy(pos) end
function exord_gunlike.BulletDef.get_velocity(self) return vector.copy(self.velocity) end
function exord_gunlike.BulletDef.set_velocity(self, vel) self.velocity = vector.copy(vel) end
function exord_gunlike.BulletDef.get_acceleration(self) return vector.copy(self.acceleration) end
function exord_gunlike.BulletDef.set_acceleration(self, acc) self.acceleration = vector.copy(acc) end

--general


function exord_gunlike.BulletDef.can_collide_node(self, pointed_thing)
	local node = core.get_node_or_nil(pointed_thing.under)
	local ndef = node and core.registered_nodes[node.name]
	if ndef and ndef.walkable then return true end
end

function exord_gunlike.BulletDef.can_collide_entity(self, entity)
end

function exord_gunlike.BulletDef.try_collide(self, pointed_thing)
	if (pointed_thing.type == "node") and (self.collided_nodes[tostring(pointed_thing.under)] == nil) then
		self.collided_nodes[tostring(pointed_thing.under)] = true
		return self:on_impact_node(pointed_thing, self.penetrations <= 1)
	else
		local entity = (pointed_thing.type == "object") and (pointed_thing.ref ~= self.parent) and pointed_thing.ref:get_luaentity()
		if entity and (self.collided_objects[pointed_thing.ref] == nil) then
			self.collided_objects[pointed_thing.ref] = true
			return self:on_impact_entity(pointed_thing, self.penetrations <= 1)
		end
	end

	return false
end

function exord_gunlike.BulletDef.on_impact_node(self, pointed_thing, is_final_impact)
	-- core.log("impact")
end
function exord_gunlike.BulletDef.on_impact_entity(self, pointed_thing, is_final_impact)
	-- core.log("impact")
end
function exord_gunlike.BulletDef.on_max_range_reached(self) end
function exord_gunlike.BulletDef.on_step(self, dtime)
	core.add_particle({
		pos = vector.offset(self.pos, 0, -0.1, 0),
		texture = "[fill:1x1:0,0:#fff",
		velocity = self.velocity * 0.9,
		acceleration = self.acceleration,
		size = 4,
		expirationtime = 1
	})
end
function exord_gunlike.BulletDef.remove(self) self.removed = true end

-- internal

function exord_gunlike.BulletDef._on_step(self, dtime)
	if not self.init then
		self.init = true
		self:set_velocity(self.dir * (self.speed + math.random() * self.speed_random))
		self.last_pos = self:get_pos()
		self.collided_objects = {}
		self.collided_nodes = {}
	else
		self.velocity = self.velocity + (self.acceleration * dtime)
		self.velocity = self.velocity * (0.5 ^ (dtime * self.drag))
		self.pos = self.pos + (self.velocity * dtime)
	end

	if self.timeout <= 0 then
		self:remove()
	elseif exord_gunlike.dist2(self.pos, self.start_pos) > self.max_range ^ 2 then
		self:remove()
	end

	local ray = core.raycast(self.last_pos, self.pos, true, true, nil)
	for pointed_thing in ray do
		if (self.penetrations > 0) and self:try_collide(pointed_thing) then
			self.penetrations = self.penetrations - 1
			if self.penetrations < 1 then
				self:remove()
			end
		end
	end

	self:on_step(dtime)

	self.timeout = self.timeout - dtime
	self.last_pos = self:get_pos()
end

-- params

exord_gunlike.BulletDef.collided_objects = nil
exord_gunlike.BulletDef.collided_nodes = nil
exord_gunlike.BulletDef.dir = vector.zero()
exord_gunlike.BulletDef.init = false
exord_gunlike.BulletDef.timeout = 10
exord_gunlike.BulletDef.parent = nil
exord_gunlike.BulletDef.last_pos = vector.zero()
exord_gunlike.BulletDef.penetrations = 1
exord_gunlike.BulletDef.removed = false

exord_gunlike.BulletDef.speed = 20
exord_gunlike.BulletDef.drag = 0.05
exord_gunlike.BulletDef.max_range = 20
exord_gunlike.BulletDef.speed_random = 0

exord_gunlike.BulletDef.pos = vector.zero()
exord_gunlike.BulletDef.velocity = vector.zero()
exord_gunlike.BulletDef.acceleration = vector.zero()

-- user params

exord_gunlike.BulletDef.start_pos = vector.zero()
exord_gunlike.BulletDef.Gun = nil
exord_gunlike.BulletDef.__meta = {__index = exord_gunlike.BulletDef}


function exord_gunlike.BulletDef.new(self, pos, dir)
	local ret = setmetatable({}, self.__meta)
	ret:set_pos(pos)
	ret.dir = dir
	ret.start_pos = vector.copy(pos)
	table.insert(exord_gunlike.bullet_list, ret)
	return ret
end

function exord_gunlike.BulletDef.new_def(def)
	def.__meta = {__index = setmetatable(def, exord_gunlike.BulletDef.__meta)}
	def.new = function(self, pos, dir)
		local ret = setmetatable({}, def.__meta)
		ret:set_pos(pos)
		ret.start_pos = vector.copy(pos)
		ret.dir = dir
		table.insert(exord_gunlike.bullet_list, ret)
		return ret
	end
	return def
end

core.register_globalstep(function(dtime)
	for i = #exord_gunlike.bullet_list, 1, -1 do
		local self = exord_gunlike.bullet_list[i]
		self:_on_step(dtime)
		if self.removed then
			table.remove(exord_gunlike.bullet_list, i)
		end
	end
end)

