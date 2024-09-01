--- Integrates the `hook-sys` library into EmptyEpsilon, registering relevant events automatically.
-- For documentation on how to call the library, see `hook-sys`.
--
-- Global hooks:
--
-- - `init`: on scenario initialisation (no args)
-- - `update`: on scenario update (args: delta)
-- - `newPlayerShip`: on new player ship creation (args: ship)
-- - `probeLaunch`: when a player ship launches a probe (args: ship, probe)
--
-- Entity hooks:
--
-- - `destroyed`: when the entity is removed from the game by any means (args: entity)
-- - `destruction`: when the entity is destroyed by damage (args: entity)
-- - `expiration`: when the scan probe expires (args: entity)

require "gn32/lang"

require "gn32/hook-sys"

hook.entityEventRegistrationName = {
	destroyed = "onDestroyed",
	destruction = "onDestruction",
	expiration = "onExpiration",
}

function G.init()
	hook.trigger.init()
end

function G.update(delta)
	hook.trigger.update(delta)
end

if G.createEntity then
	local new_ps = {}
	-- TODO: ECS onNewPlayerShip does not work
	local ps = PlayerSpaceship
	PlayerSpaceship = function()
		local e = ps()
		table.insert(new_ps, e)
		return e
	end

	hook.on.update = function()
		for _, e in ipairs(new_ps) do
			hook.trigger.newPlayerShip(e)
			e:onProbeLaunch(hook.trigger.probeLaunch)
		end
		new_ps = {}
	end
else
	onNewPlayerShip(function(ship)
		hook.trigger.newPlayerShip(ship)
		ship:onProbeLaunch(hook.trigger.probeLaunch)
	end)
end
