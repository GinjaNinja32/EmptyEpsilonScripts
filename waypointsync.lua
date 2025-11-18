--- [`hook-sys`] Sync waypoints from one ship to another.
-- Required hooks: `update`.

require "gn32/lang"

require "gn32/ecs"

--- Comps.
-- See `ecs` for details of how to apply comps to an entity.
-- @section Comps

--- Sync waypoints from `source` to this ship.
-- @table sync_waypoints
-- @field source The entity to sync from.
Comp("sync_waypoints"):setSchema({
	source = {_check = function(e) return e and type(e.isValid) == "function" and e:isValid() and type(e.getWaypointCount) == "function" end},
})

System("sync_waypoints")
	:addRequiredComps("sync_waypoints")
	:onUpdateEntity(function(delta, ent, comps)
		local src = comps.sync_waypoints.source

		if not src:isValid() or type(ent.getWaypointCount) ~= "function" then
			comps.sync_waypoints = nil
			return
		end

		local cur = ent:getWaypointCount()
		local trg = src:getWaypointCount()

		if cur > trg then
			for i = trg+1, cur do
				ent:commandRemoveWaypoint(i - 1)
			end
		end

		if cur < trg then
			for i = cur+1, trg do
				ent:commandAddWaypoint(src:getWaypoint(i))
			end
		end

		for i = 1, math.min(cur, trg) do
			ent:commandMoveWaypoint(i-1, src:getWaypoint(i))
		end
	end)
