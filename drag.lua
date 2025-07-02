--- [`hook-sys`] Slows down specified entities over time, eventually stopping them.
-- Required hooks: `update`.
--
-- When an entity's speed drops below 1 game unit per update (~0.06U/s), its speed is set to zero and its drag comp is removed. On non-ECS builds, its velocity comp is also removed.

require "gn32/ecs"

--- Comps.
-- See `ecs` for details of how to apply comps to an entity.
-- @section Comps


local c_velocity
if not G.createEntity then
	--- [non-`ECS`] Move an entity at a specified velocity.
	-- @table velocity
	-- @number x The x component of the velocity.
	-- @number y The y component of the velocity.
	Comp("velocity"):setSchema({
		x = {_type = "number"},
		y = {_type = "number"},
	})

	System("velocity")
		:addRequiredComps("velocity")
		:onUpdateEntity(function(delta, ent, comp)
			local x, y = ent:getPosition()
			ent:setPosition(x + comp.velocity.x * delta, y + comp.velocity.y * delta)
		end)
end

--- Apply drag to an entity.
-- @table drag
-- @number[opt] lambda What proportion of its speed the entity should retain after one second; default 0.5.
Comp("drag"):setSchema({
	lambda = {_default = 0.5, _type = "number", _gt = 0, _lt = 1},
})

System("drag")
	:addRequiredComps("drag")
	:onUpdateEntity(function(delta, ent, comp)
		local x, y
		if G.createEntity then
			x, y = table.unpack(ent.components.physics.velocity)
		else
			x, y = comp.velocity.x, comp.velocity.y
		end

		local l = comp.drag.lambda ^ delta

		x = x * l
		y = y * l

		if x*x + y*y < 1 then
			x = 0
			y = 0
			comp.drag = nil
		end

		if G.createEntity then
			ent.components.physics.velocity = {x, y}
		elseif x ~= 0 or y ~= 0 then
			comp.velocity.x = x
			comp.velocity.y = y
		else
			comp.velocity = nil
		end
	end)
