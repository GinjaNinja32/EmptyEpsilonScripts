-- Module: gn32/exchange
-- Description: Utilities for exchanging one set of resources for another, e.g. to craft or trade
--[[
	Resource list format:
		{<source> = <data>, ...}
		e.g.:
			{rep = 5}
			{w_hvli = 2, w_mine = 1}
			{cargo = {Pb = 2}, custom = {add = function(ship, m) for i = 1, m do a_thing() end end}}

	To define a source:
		exchange.sources.<key> = {
			format = function(data, m) ... end,        -- Format `data` as a string, after applying a multiplier `m`.
			canTake = function(ship, data, m) ... end, -- Return true if `data` can be taken from `ship` at least `m` times.
			take = function(ship, data, m) ... end,    -- Take `data` from `ship` `m` times. This function may assume that `canTake(ship, data, m) == true`.
			canAdd = function(ship, data, m) .. end,   -- Return true if `data` can be added to `ship` at least `m` times.
			add = function(ship, data, m) ... end,     -- Add `data` to `ship` `m` times. This function may assume that `canAdd(ship, data, m) == true`.
		}

	Predefined sources:
		key         data type    description
		---         ---------    -----------
		rep         number       Faction reputation points
		energy      number       Ship energy
		hull        number       Ship hull points
		coolant     number       Ship coolant; 1 represents 10% coolant
		probe       number       Scan probes
		w_hvli      number       HVLI ammo
		w_homing    number       Homing ammo
		w_mine      number       Mine ammo
		w_emp       number       EMP ammo
		w_nuke      number       Nuke ammo
		cargo       cargolist    Ship cargo (requires gn32/cargo)
		custom      table        Calls functions on its data table to enable one-off source functions. Function list as source definition, minus `data` parameter. If any source function is not present in the data table, it is assumed to succeed.
]]

require "gn32/lang"

G.exchange = {}

local sourcesList = {}

--[[ SOURCES ]]

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

exchange.sources.custom = {
	format = function(data, m)
		if data.format then return data.format(m) end
		return nil
	end,
	canTake = function(ship, data, m)
		if data.canTake then return data.canTake(ship, m) end
		return true
	end,
	take = function(ship, data, m)
		if data.take then data.take(ship, m) end
	end,
	canAdd = function(ship, data, m)
		if data.canAdd then return data.canAdd(ship, m) end
		return true
	end,
	add = function(ship, data, m)
		if data.add then data.add(ship, m) end
	end,
}

exchange.sources.rep     = exchange.autoGetSet("ReputationPoints", "%d rep", "%d rep")
exchange.sources.energy  = exchange.autoGetSet("Energy",           "%d energy",     "%d energy")
exchange.sources.hull    = exchange.autoGetSet("Hull",             "%d hull",       "%d hull")
exchange.sources.coolant = exchange.autoGetSet("MaxCoolant",       "%d0%% coolant", "%d0%% coolant")
exchange.sources.probe   = exchange.autoGetSet("ScanProbeCount",   "%d probe",      "%d probes")

exchange.sources.w_hvli   = exchange.autoGetSet("WeaponStorage", "%d HVLI",   "%d HVLIs",   "HVLI")
exchange.sources.w_homing = exchange.autoGetSet("WeaponStorage", "%d homing", "%d homings", "Homing")
exchange.sources.w_mine   = exchange.autoGetSet("WeaponStorage", "%d mine",   "%d mines",   "Mine")
exchange.sources.w_emp    = exchange.autoGetSet("WeaponStorage", "%d EMP",    "%d EMPs",    "EMP")
exchange.sources.w_nuke   = exchange.autoGetSet("WeaponStorage", "%d nuke",   "%d nukes",   "Nuke")

-- soft-depends: gn32/cargo
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

function exchange.each(resources, fn) -- do something for each entry in a resource list. Intended for internal use; exposed in case it's useful for some use case.
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

function exchange.formatString(resources, mult) -- format a list of resources in a human-readable format. returns a string, e.g. "3 energy, 5 HVLIs"
	return table.concat(exchange.format(resources, mult), ", ")
end
function exchange.format(resources, mult) -- format a list of resources in a human-readable format. returns a list of entries, e.g. {"3 energy", "5 HVLIs"}
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

function exchange.canTake(ship, resources, mult) -- return true if the ship could supply the specified resources; otherwise, return false.
	mult = mult or 1
	local bad, why = exchange.each(resources, function(source, data)
		local ok, why = source.canTake(ship, data, mult)
		if not ok then
			return true, why or source.key
		end
	end)
	return not bad, why
end

function exchange.take(ship, resources, mult) -- take the specified resources from the ship. Results undefined if `exchange.canTake(ship, resources)` would return false.
	mult = mult or 1
	exchange.each(resources, function(source, data) source.take(ship, data, mult) end)
end

function exchange.tryTake(ship, resources, mult) -- if the ship can supply the specified resources, take them and return true; otherwise, return false.
	mult = mult or 1
	if not exchange.canTake(ship, resources, mult) then return false end
	exchange.take(ship, resources, mult)
	return true
end

function exchange.canAdd(ship, resources, mult) -- return true if the ship could accept the specified resources; otherwise, return false.
	mult = mult or 1
	local bad, why = exchange.each(resources, function(source, data)
		local ok, why = source.canAdd(ship, data, mult)
		if not ok then
			return true, why or source.key
		end
	end)
	return not bad, why
end

function exchange.add(ship, resources, mult) -- add the specified resources to the ship. Results undefined if `exchange.canAdd(ship, resources)` would return false.
	mult = mult or 1
	exchange.each(resources, function(source, data) source.add(ship, data, mult) end)
end

function exchange.tryAdd(ship, resources, mult) -- if the ship can accept the specified resources, add them and return true; otherwise, return false.
	mult = mult or 1
	if not exchange.canAdd(ship, resources, mult) then return false end
	exchange.add(ship, resources, mult)
	return true
end

function exchange.canSwap(ship, from, to, mult) -- return true if the ship could swap the specified resources; otherwise; return false.
	mult = mult or 1
	local ok, why = exchange.canTake(ship, from, mult)
	if not ok then return false, why end
	return exchange.canAdd(ship, to, mult)
end

function exchange.swap(ship, from, to, mult) -- swap the specified resources on the ship. Results undefined if `exchange.canSwap(ship, from, to)` would return false.
	mult = mult or 1
	exchange.take(ship, from, mult)
	exchange.add(ship, to, mult)
end

function exchange.trySwap(ship, from, to, mult) -- if the ship can swap the specified resources, swap them and return true; otherwise, return false.
	mult = mult or 1
	if not exchange.canSwap(ship, from, to, mult) then return false end
	exchange.swap(ship, from, to, mult)
	return true
end
