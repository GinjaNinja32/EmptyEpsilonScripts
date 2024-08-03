-- Name: gn32/hook
-- Description: Integrates the hook library into EmptyEpsilon, registering relevant events automatically
--[[
	For documentation on how to call the library, see gn32/hook-sys.

	Global hooks:
		`init`: on scenario initialisation (no args)
		`update`: on scenario update (args: delta)
		`newPlayerShip`: on new player ship creation (args: ship)
		`probeLaunch`: when a player ship launches a probe (args: ship, probe)

	Entity hooks:
		`destroyed`: when the entity is removed from the game by any means (args: entity)
		`destruction`: when the entity is destroyed by damage (args: entity)
		`expiration`: when the scan probe expires (args: entity)
]]

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

onNewPlayerShip(function(ship)
	hook.trigger.newPlayerShip(ship)
	ship:onProbeLaunch(hook.trigger.probeLaunch)
end)
