-- Module: gn32/drag
-- Description: Slows specified entities down over time, eventually stopping them.
--[[
	To apply drag to an entity:
		drag.apply(entity)      -- default slowdown parameter; retain 50% speed after 1 second
		drag.apply(entity, 0.8) -- retain 80% speed after 1 second
		drag.apply(entity, 0.4) -- retain 40% speed after 1 second

	When an entity's speed drops below 1 game unit per update (~0.06U/s), its speed is set to zero.
]]

require "gn32/hook-sys"

local entities = {}

G.drag = {
	apply = function(e, lambda)
		entities[e] = lambda or 0.5
	end
}

function hook.on.update(delta)
	for e, lambda in pairs(entities) do
		if not e:isValid() then
			entities[e] = nil
		else
			local x, y = e:getVelocity()

			local l = lambda ^ delta

			x = x * l
			y = y * l

			if x*x + y*y < 1 then
				x = 0
				y = 0
				entities[e] = nil
			end

			e:setVelocity(x, y)
		end
	end
end
