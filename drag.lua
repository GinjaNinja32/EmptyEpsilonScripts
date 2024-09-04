--- [`hook-sys`] Slows down specified entities over time, eventually stopping them.
-- Required hooks: `update`.
--
-- When an entity's speed drops below 1 game unit per update (~0.06U/s), its speed is set to zero and its drag comp is removed. On `master`, its velocity comp is also removed.

require "gn32/ecs"

--- Comps.
-- See `ecs` for details of how to apply comps to an entity.
-- @section Comps

--- Apply drag to an entity.
-- @table drag
-- @number[opt] lambda What proportion of its speed the entity should retain after one second; default 0.5.
Comp("drag"):setSchema({
	lambda = {_default = 0.5, _type = "number", _gt = 0, _lt = 1},
})

local dragSystem = System("drag")
	:addRequiredComps("drag")

if not G.createEntity then
	--- [`master`] Move an entity at a specified velocity.
	-- @table velocity
	-- @number x The x component of the velocity.
	-- @number y The y component of the velocity.
	Comp("velocity"):setSchema({
		x = {_type = "number"},
		y = {_type = "number"},
	})

	dragSystem:addRequiredComps("velocity")
end

dragSystem:onUpdateEntity(function(delta, ent, comps)
	local x, y
	if G.createEntity then
		x, y = table.unpack(ent.components.physics.linear_velocity)
	else
		x, y = comps.velocity.x, comps.velocity.y

		local px, py = ent:getPosition()
		ent:setPosition(px + x * delta, py + y * delta)
	end

	local l = comps.drag.lambda ^ delta

	x = x * l
	y = y * l

	if x*x + y*y < 1 then
		x = 0
		y = 0
		comps.drag = nil
	end

	if G.createEntity then
		ent.components.physics.linear_velocity = {x, y}
	elseif x ~= 0 or y ~= 0 then
		comps.velocity.x = x
		comps.velocity.y = y
	else
		comps.velocity = nil
	end
end)
