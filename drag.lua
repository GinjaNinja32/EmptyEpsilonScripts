--- Slows down specified entities over time, eventually stopping them. On non-ECS EmptyEpsilon, also provides an entity velocity comp.
-- To apply drag to an entity:
--    comps(ent).drag = {}  -- default slowdown parameter; retain 50% speed after 1 second
--    comps(ent).drag = {lambda = 0.8}  -- retain 80% speed after 1 second
--    comps(ent).drag = {lambda = 0.4}  -- retain 40% speed after 1 second
--
-- [non-ECS] To apply velocity to an entity:
--    comps(ent).velocity = {linear = {10, 20}}  -- set x velocity to 10 and y velocity to 20
--
-- When an entity's speed drops below 1 game unit per update (~0.06U/s), its speed is set to zero and its drag comp is removed. On non-ECS EE, its velocity comp is also removed.

require "gn32/ecs"

Comp("drag")
	:addField("lambda", 0.5, function(v) return type(v) == "number" and 0 < v and v < 1 end)

local dragSystem = System("drag")
	:addRequiredComps("drag")

if not G.createEntity then
	Comp("velocity")
		:addField("linear", {0, 0}, function(v) return type(v) == "table" and #v == 2 and type(v[1]) == "number" and type(v[2]) == "number" end)

	dragSystem:addRequiredComps("velocity")
end

dragSystem:onUpdateEntity(function(delta, ent, comps)
	local x, y
	if G.createEntity then
		x, y = table.unpack(ent.components.physics.linear_velocity)
	else
		x, y = table.unpack(comps.velocity.linear)

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
		comps.velocity.linear = {x, y}
	else
		comps.velocity = nil
	end
end)
