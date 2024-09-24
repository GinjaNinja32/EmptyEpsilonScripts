--- Utilities for adding, removing, moving, and exchanging resources.
--
-- Terminology:
--
-- - A "source" is a kind of resource that might be exchanged, such as rep, coolant, or HVLI ammo. Each source has a key, such as `rep`, `coolant`, or `w_hvli`.
-- - A "resource list" is a table with source keys mapped to the data type for that source, e.g. `{rep = 5}` or `{w_hvli = 2, w_mine = 1}`
--
-- To define a source, see `exchange.sources`.
-- Source definition format:
--
--	{
--		-- Format `data` as a string, with a multiplier `mult`
--		format = function(data, mult) ... end,
--
--		-- Return true if `data` can be taken from ship at least `mult` times
--		canTake = function(ship, data, mult) ... end,
--
--		-- Take `data` from `ship`, `mult` times.
--		-- This function may assume that `canTake(ship, data, mult)` is true.
--		take = function(ship, data, mult) ... end,
--
--		-- Return true if `data` can be added to ship at least `mult` times
--		canAdd = function(ship, data, mult) ... end,
--
--		-- Add `data` to `ship`, `mult` times.
--		-- This function may assume that `canAdd(ship, data, mult)` is true.
--		add = function(ship, data, mult) ... end,
--	}
--
-- @pragma nostrip

require "gn32/lang"

G.exchange = {}

local sourcesList = {}

-- define functions first so that it goes above sources in the output

--- Functions.
-- @section function

--- Values.
-- @section values

--- A special value for all functions in this module; if passed in place of a `ship`, acts as an infinite source and sink for all sources.
exchange.infinite = {}

--- Sources
-- @section sources

--[[ SOURCES ]]

--- Mapping of source key => source.
-- To register a new source, assign to `exchange.sources[key]` with a source definition.
-- @table exchange.sources
exchange.sources = setmetatable({}, {
	__index = sourcesList,
	__newindex = function(_, key, val)
		if sourcesList[key] then
			error("duplicate exchange source key " .. key, 2)
		end
		val.key = key

		for _, k in ipairs{"format", "canTake", "take", "canAdd", "add"} do
			if type(val[k]) ~= "function" then
				error("exchange source " .. key .. " has non-function " .. k .. ": " .. type(val[k]))
			end
		end

		sourcesList[key] = val
	end
})

function exchange.autoGetSet(ty, sg, pl, ...) -- build an automatic get/set source based on a data type and singular/plural formats
	local args = {...}
	local argsn = #args + 1

	local get = "get" .. ty
	local set = "set" .. ty
	local getMax = "getMax" .. ty

	return {
		format = function(n, m)
			return string.format((n*m == 1) and sg or pl, n*m)
		end,
		canTake = function(ship, n, m)
			args[argsn] = nil
			local cur = ship[get](ship, table.unpack(args))
			if cur >= n * m then return true end
			return false, "empty"
		end,
		take = function(ship, n, m)
			args[argsn] = nil
			local cur = ship[get](ship, table.unpack(args))
			args[argsn] = cur - n * m
			ship[set](ship, table.unpack(args))
		end,
		canAdd = function(ship, n, m)
			if not ship[getMax] then
				getMax = "get" .. ty .. "Max"
			end
			if not ship[getMax] then
				return true
			end

			args[argsn] = nil
			local cur = ship[get](ship, table.unpack(args))
			local max = ship[getMax](ship, table.unpack(args))

			if (max - cur) >= n * m then return true end
			return false, "full"
		end,
		add = function(ship, n, m)
			args[argsn] = nil
			local cur = ship[get](ship, table.unpack(args))
			args[argsn] = cur + n * m
			ship[set](ship, table.unpack(args))
		end,
	}
end

--- Predefined Sources.
-- @section sources

--- Forwards method calls to its data.
-- The data format for this source is similar to the source definition format, with the `data` parameter removed and with all functions made optional.
-- @table custom
-- @field format `function(mult)`: Format this entry. If not present, omit this entry from the formatted list.
-- @field canTake `function(ship, mult)`: Return true if the entry can be taken. If not present, treat as returned `true`.
-- @field take `function(ship, mult)`: Take this entry. If not present, do nothing.
-- @field canAdd `function(ship, mult)`: Return true if the entry can be added. If not present, treat as returned `true`.
-- @field add `function(ship, mult)`: Add this entry. If not present, do nothing.
exchange.sources.custom = {
	format = function(data, mult)
		if data.format then return data.format(mult) end
		return nil
	end,
	canTake = function(ship, data, mult)
		if data.canTake then return data.canTake(ship, mult) end
		return true
	end,
	take = function(ship, data, mult)
		if data.take then data.take(ship, mult) end
	end,
	canAdd = function(ship, data, mult)
		if data.canAdd then return data.canAdd(ship, mult) end
		return true
	end,
	add = function(ship, data, mult)
		if data.add then data.add(ship, mult) end
	end,
}

--- Faction reputation points. Data type: number.
-- @table rep
exchange.sources.rep     = exchange.autoGetSet("ReputationPoints", "%d rep", "%d rep")
--- Ship energy. Data type: number.
-- @table energy
exchange.sources.energy  = exchange.autoGetSet("Energy",           "%d energy",     "%d energy")
--- Ship hull points. Data type: number.
-- @table hull
exchange.sources.hull    = exchange.autoGetSet("Hull",             "%d hull",       "%d hull")
--- Ship coolant. Data type: number, where 1 represents 10% coolant.
-- @table coolant
exchange.sources.coolant = exchange.autoGetSet("MaxCoolant",       "%d0%% coolant", "%d0%% coolant")
--- Ship scan probes. Data type: integer.
-- @table probe
exchange.sources.probe   = exchange.autoGetSet("ScanProbeCount",   "%d probe",      "%d probes")

--- HVLI ammunition. Data type: integer.
-- @table w_hvli
exchange.sources.w_hvli   = exchange.autoGetSet("WeaponStorage", "%d HVLI",   "%d HVLIs",   "HVLI")
--- Homing ammunition. Data type: integer.
-- @table w_homing
exchange.sources.w_homing = exchange.autoGetSet("WeaponStorage", "%d homing", "%d homings", "Homing")
--- Mine ammunition. Data type: integer.
-- @table w_mine
exchange.sources.w_mine   = exchange.autoGetSet("WeaponStorage", "%d mine",   "%d mines",   "Mine")
--- EMP ammunition. Data type: integer.
-- @table w_emp
exchange.sources.w_emp    = exchange.autoGetSet("WeaponStorage", "%d EMP",    "%d EMPs",    "EMP")
--- Nuke ammunition. Data type: integer.
-- @table w_nuke
exchange.sources.w_nuke   = exchange.autoGetSet("WeaponStorage", "%d nuke",   "%d nukes",   "Nuke")

-- if the doc is attached to `exchange.sources.cargo` then it shows the format, canTake etc, and I can't work out how to get it to not do that.

--- Ship `cargo`. Requires `cargo` to function. Data type: cargo list.
-- @table cargo
local _ = {}

exchange.sources.cargo = {
	format = function(c, m) return cargo.formatShort(c, m) end,
	canTake = function(ship, c, m)
		if cargo.has(ship, c, m) then return true end
		return false, cargo.formatShort(c, m)
	end,
	take = function(ship, c, m) cargo.use(ship, c, m) end,
	canAdd = function(ship, c, m)
		if cargo.hasSpace(ship, c, m) then return true end
		return false, "cargo full"
	end,
	add = function(ship, c, m) cargo.adjust(ship, c, m) end,
}

--[[ EXPORTS ]]

--- Functions.
-- @section function

--- Do something for each entry in a resource list. Primarily intended for internal use.  
-- If the provided function returns a non-nil first result for any entry, the iteration is terminated and the results of that call are returned from this function.
-- @param resources The resource list to iterate.
-- @param fn A `function(source, data)` to call for each entry.
-- @return The results of the first call of `fn` that returned a non-nil first result, or nil if no call had a non-nil first result.
function exchange.each(resources, fn)
	for ty, data in pairs(resources) do
		local source = sourcesList[ty]
		if not source then
			print("Exchange error: type " .. ty .. " not defined")
		else
			local res = {pcall(fn, source, data)}
			if not res[1] then
				print("Exchange error: type " .. ty .. " returned error: " .. tostring(res[2]))
			elseif res[2] ~= nil then
				table.remove(res, 1)
				return table.unpack(res)
			end
		end
	end
end

--- Format a resource list in a human-readable format, as a string such as `"3 energy, 5 HVLIs"`.
-- @param resources The resource list to format.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
function exchange.formatString(resources, mult)
	return table.concat(exchange.format(resources, mult), ", ")
end
--- Format a resource list in a human-readable format, as a table such as `{"3 energy", "5 HVLIs"}`.
-- @param resources The resource list to format.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
function exchange.format(resources, mult)
	mult = mult or 1
	local types = {}
	for ty, _ in pairs(resources) do table.insert(types, ty) end
	table.sort(types)

	local entries = {}
	for _, ty in ipairs(types) do
		local source = sourcesList[ty]
		if not source then
			print("Exchange error: type " .. ty .. " not defined")
		else
			local v = source.format(resources[ty], mult)
			if v then
				table.insert(entries, v)
			end
		end
	end

	return entries
end

--- Check whether a ship could supply resources.
-- @param ship The ship to check.
-- @param resources The resource list to check.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the ship could provide the resources; otherwise false
function exchange.canTake(ship, resources, mult) -- return true if the ship could supply the specified resources; otherwise, return false.
	if ship == exchange.infinite then return true end
	mult = mult or 1
	local bad, why = exchange.each(resources, function(source, data)
		local ok, why = source.canTake(ship, data, mult)
		if not ok then
			return true, why ~= "" and why or source.key
		end
	end)
	return not bad, why
end

--- Take resources from a ship.
-- The behaviour of this function is undefined if `exchange.canTake` would return false given the same arguments.
-- @param ship The ship to take from.
-- @param resources The resource list to take.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
function exchange.take(ship, resources, mult)
	if ship == exchange.infinite then return true end
	mult = mult or 1
	exchange.each(resources, function(source, data) source.take(ship, data, mult) end)
end

--- Attempt to take resources from a ship.
-- This operation is atomic; if any resources cannot be taken, then no resources are taken.
-- @param ship The ship to take from.
-- @param resources The resource list to take.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the resources were successfully taken; otherwise false
function exchange.tryTake(ship, resources, mult) -- if the ship can supply the specified resources, take them and return true; otherwise, return false.
	mult = mult or 1
	if not exchange.canTake(ship, resources, mult) then return false end
	exchange.take(ship, resources, mult)
	return true
end

--- Check whether a ship could accept resources.
-- @param ship The ship to check.
-- @param resources The resource list to check.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the ship could accept the resources; otherwise false
function exchange.canAdd(ship, resources, mult)
	if ship == exchange.infinite then return true end
	mult = mult or 1
	local bad, why = exchange.each(resources, function(source, data)
		local ok, why = source.canAdd(ship, data, mult)
		if not ok then
			return true, why ~= "" and why or source.key
		end
	end)
	return not bad, why
end

--- Add resources to a ship.
-- The behaviour of this function is undefined if `exchange.canAdd` would return false given the same arguments.
-- @param ship The ship to add to.
-- @param resources The resource list to add.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
function exchange.add(ship, resources, mult)
	if ship == exchange.infinite then return true end
	mult = mult or 1
	exchange.each(resources, function(source, data) source.add(ship, data, mult) end)
end

--- Attempt to add resources to a ship.
-- This operation is atomic; if any resources cannot be added, then no resources are added.
-- @param ship The ship to add to.
-- @param resources The resource list to add.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the resources were successfully added; otherwise false
function exchange.tryAdd(ship, resources, mult)
	mult = mult or 1
	if not exchange.canAdd(ship, resources, mult) then return false end
	exchange.add(ship, resources, mult)
	return true
end

--- Check whether a ship could swap one set of resources for another.
-- @param ship The ship to check.
-- @param from The resource list to swap from.
-- @param to The resource list to swap to.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
-- @return true if the ship could swap the resources; otherwise false
function exchange.canSwap(ship, from, to, mult)
	mult = mult or 1
	local ok, why = exchange.canTake(ship, from, mult)
	if not ok then return false, why end
	return exchange.canAdd(ship, to, mult)
end

--- Swap resources on a ship.
-- The behaviour of this function is undefined if `exchange.canSwap` would return false given the same arguments.
-- @param ship The ship to swap on.
-- @param from The resource list to swap from.
-- @param to The resource list to swap to.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
function exchange.swap(ship, from, to, mult)
	mult = mult or 1
	exchange.take(ship, from, mult)
	exchange.add(ship, to, mult)
end

--- Attempt to swap resources on a ship.
-- This operation is atomic; if any resources cannot be added or removed, then no resources are added or removed.
-- @param ship The ship to swap on.
-- @param from The resource list to swap from.
-- @param to The resource list to swap to.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
-- @return true if the resources were successfully added; otherwise false
function exchange.trySwap(ship, from, to, mult)
	mult = mult or 1
	if not exchange.canSwap(ship, from, to, mult) then return false end
	exchange.swap(ship, from, to, mult)
	return true
end

--- Check whether two ships could move resources from one to another.
-- @param shipFrom The ship to move resources from.
-- @param shipTo The ship to move resources to.
-- @param resources The resource list to move.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the ships could move the resources; otherwise false
function exchange.canMove(shipFrom, shipTo, resources, mult)
	mult = mult or 1
	local ok, why = exchange.canTake(shipFrom, resources, mult)
	if not ok then return false, why end
	return exchange.canAdd(shipTo, resources, mult)
end

--- Move resources from one ship to another.
-- The behaviour of this function is undefined if `exchange.canMove` would return false given the same arguments.
-- @param shipFrom The ship to move resources from.
-- @param shipTo The ship to move resources to.
-- @param resources The resource list to move.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
function exchange.move(shipFrom, shipTo, resources, mult)
	mult = mult or 1
	exchange.take(shipFrom, resources, mult)
	exchange.add(shipTo, resources, mult)
end

--- Attempt to move resources from one ship to another.
-- This operation is atomic; if any resources cannot be added or removed, then no resources are added or removed.
-- @param shipFrom The ship to move resources from.
-- @param shipTo The ship to move resources to.
-- @param resources The resource list to move.
-- @param mult A multiplier to apply to each entry in the resource list; default 1.
-- @return true if the resources were successfully moved; otherwise false
function exchange.tryMove(shipFrom, shipTo, resources, mult)
	mult = mult or 1
	if not exchange.canMove(shipFrom, shipTo, resources, mult) then return false end
	exchange.move(shipFrom, shipTo, resources, mult)
	return true
end

--- Check whether two ships could trade resources with each other.
-- @param shipA The first ship involved in the trade.
-- @param resourcesA The resources that shipA is providing to shipB.
-- @param shipB The second ship involved in the trade.
-- @param resourcesB The resources that shipB is providing to shipA.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
-- @return true if the ships could trade the resources; otherwise false
function exchange.canTrade(shipA, resourcesA, shipB, resourcesB, mult)
	mult = mult or 1
	local ok, why = exchange.canSwap(shipA, resourcesA, resourcesB, mult)
	if not ok then return false, why end
	return exchange.canSwap(shipB, resourcesB, resourcesA, mult)
end

--- Trade resources between two ships.
-- The behaviour of this function is undefined if `exchange.canTrade` would return false given the same arguments.
-- @param shipA The first ship involved in the trade.
-- @param resourcesA The resources that shipA is providing to shipB.
-- @param shipB The second ship involved in the trade.
-- @param resourcesB The resources that shipB is providing to shipA.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
function exchange.trade(shipA, resourcesA, shipB, resourcesB, mult)
	mult = mult or 1
	exchange.swap(shipA, resourcesA, resourcesB, mult)
	exchange.swap(shipB, resourcesB, resourcesA, mult)
end

--- Attempt to trade resources between two ships.
-- This operation is atomic; if any resources cannot be added or removed, then no resources are added or removed.
-- @param shipA The first ship involved in the trade.
-- @param resourcesA The resources that shipA is providing to shipB.
-- @param shipB The second ship involved in the trade.
-- @param resourcesB The resources that shipB is providing to shipA.
-- @param mult A multiplier to apply to each entry in each resource list; default 1.
-- @return true if the resources were successfully traded; otherwise false
function exchange.tryTrade(shipA, resourcesA, shipB, resourcesB, mult)
	mult = mult or 1
	local ok, why = exchange.canTrade(shipA, resourcesA, shipB, resourcesB, mult)
	if not ok then return false, why end
	exchange.trade(shipA, resourcesA, shipB, resourcesB, mult)
	return true
end
