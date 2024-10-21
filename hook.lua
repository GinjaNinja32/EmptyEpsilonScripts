--- Integrates the `hook-sys` library into EmptyEpsilon, registering relevant events automatically.
-- For documentation on how to call the library, see `hook-sys`.
--
-- Modules targeting this library that do not use predefined entity hooks should import `hook-sys` and specify the hooks they require, to allow them to be used in scripts that do not wish to integrate `hook`.

--- Global hooks.
-- @section globalhooks

--- Triggered on scenario initialisation.
-- @function init

--- Triggered on scenario update.
-- @function update
-- @tparam number delta

--- Triggered when a player ship is created.
-- @function newPlayerShip
-- @tparam PlayerSpaceship ship

--- Triggered when a scan probe is launched from any ship.
-- @function probeLaunch
-- @tparam PlayerSpaceship ship
-- @tparam ScanProbe probe


--- Entity hooks.
-- @section entityhooks

--- Triggered when an entity is removed from the game by any means.
-- @function destroyed
-- @tparam entity entity

--- Triggered when an entity is destroyed by damage.
-- @function destruction
-- @tparam entity entity

--- Triggered when a scan probe expires.
-- @function expiration
-- @tparam entity entity

require "gn32/lang"

require "gn32/hook-sys"
require "gn32/fnhook"

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
	fnhook.PlayerSpaceship = function(e)
		table.insert(new_ps, e)
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
