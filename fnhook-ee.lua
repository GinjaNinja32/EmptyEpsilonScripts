--- [`hook-sys`] Uses `fnhook` to provide EmptyEpsilon-specific function hooks.

--- Global hooks.
-- @section globalhooks

--- Triggered when a new entity is created.
-- @function newEntity
-- @tparam entity entity The entity that was created.

--- Hooked functions.
-- @section hooks

require "gn32/hook-sys"
require "gn32/fnhook"

for _, name in ipairs{
	--- Triggers the `newEntity` hook.
	-- @function Artifact
	"Artifact",
	--- Triggers the `newEntity` hook.
	-- @function Asteroid
	"Asteroid",
	--- Triggers the `newEntity` hook.
	-- @function BlackHole
	"BlackHole",
	--- Triggers the `newEntity` hook.
	-- @function Nebula
	"Nebula",
	--- Triggers the `newEntity` hook.
	-- @function Planet
	"Planet",
	--- Triggers the `newEntity` hook.
	-- @function ScanProbe
	"ScanProbe",
	--- Triggers the `newEntity` hook.
	-- @function CpuShip
	"CpuShip",
	--- Triggers the `newEntity` hook.
	-- @function PlayerSpaceship
	"PlayerSpaceship",
	--- Triggers the `newEntity` hook.
	-- @function SpaceStation
	"SpaceStation",
	--- Triggers the `newEntity` hook.
	-- @function SupplyDrop
	"SupplyDrop",
	--- Triggers the `newEntity` hook.
	-- @function VisualAsteroid
	"VisualAsteroid",
	--- Triggers the `newEntity` hook.
	-- @function WarpJammer
	"WarpJammer",
	--- Triggers the `newEntity` hook.
	-- @function WormHole
	"WormHole",
	--- Triggers the `newEntity` hook.
	-- @function Zone
	"Zone",
} do
	fnhook[name] = hook.trigger.newEntity
end
