--- Adds inventory functionality to ships.
--
-- Item definition format:
--	{
--		-- ID of the item.
--		-- Should be short and descriptive. Must not start with a number.
--		id = "Ti",
--
--		-- Name of the item. Should be in mid-sentence case.
--		name = "titanium",
--
--		-- Description of the item.
--		desc = "a strong metal",
--	}
--
-- To enable a ship to carry cargo:
--	comps(ship).cargo = {}            -- unlimited space
--	comps(ship).cargo = {limit = 20}  -- can carry 20 items
--
-- @pragma nostrip

require "gn32/lang"
require "gn32/ecs"

G.cargo = {}

cargo.items = {}

--- Comps.
-- See `ecs` for details of how to apply comps to an entity.
-- @section Comps

--- Allow an entity to hold cargo.
-- @table cargo
-- @bool[opt] infinite Whether this entity is an infinite source and sink of all cargo types. Default false.
-- @number[opt] limit The maximum number of items this entity can carry, or zero for unlimited. Default zero.
-- @tab[opt] items A map from cargo item ID to item quantity. Default empty.
Comp("cargo"):setSchema{
	infinite = {_type = "boolean", _default = false},
	limit = {
		_type = "number",
		_default = 0,
		_ge = 0,
		_check = function(v) return math.floor(v) == v end,
	},
	items = {
		_type = "table",
		_default = function() return {} end,
		_keys = {
			_type = "string",
			_check = function(v) return not not cargo.items[v] end,
		},
		_values = {
			_type = "number",
			_ge = 0,
			_check = function(v) return math.floor(v) == v end,
		},
	}
}

--- Functions.
-- @section functions

--- Add items that can be carried by ships.
-- @param ... A list of cargo item definitions.
function cargo.addItems(...)
	for _, item in ipairs{...} do
		if type(item.id) ~= "string" then
			error("item did not have a string id: " .. tostring(item.id), 2)
		end

		if cargo.items[item.id] then
			error("duplicate item id " .. item.id, 2)
		end

		for _, k in ipairs{"name", "desc"} do
			if type(item[k]) ~= "string" then
				error("item " .. item.id .. " did not have a string " .. k .. ": " .. tostring(item[k]), 2)
			end
		end

		cargo.items[item.id] = item
		table.insert(cargo.items, item)
	end
end

-- ENTITIES

--- Create a cargo drop entity.
-- @function CargoDrop
-- @param ty The cargo type held by this entity
-- @param timeout The timeout before this drop can be picked up; default 0.
G.CargoDrop = function(ty, timeout)
	local pickupAfter = getScenarioTime() + (timeout or 0)
	return Artifact()
		:setRadarTraceIcon("combatsat.png")
		:setRadarTraceColor(200, 200, 255)
		:onPlayerCollision(function(self, ship)
			if getScenarioTime() < pickupAfter then
				return
			end

			if cargo.adjust(ship, {[ty]=1}) then
				self:destroy()
			end
		end)
end

-- EXPORTS

--- Count how many times over a ship has some cargo.
-- @param ship The ship to check.
-- @param entries The base cargo to check for.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return The number of instances of the cargo the ship has.
function cargo.count(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return 0 end
	if c.infinite then return 100 end
	if c.items == nil then return 0 end

	local n

	for material, count in pairs(entries) do
		local amount = c.items[material]
		if amount == nil then
			return 0
		end

		local this_n = math.floor(amount / (count * mult))
		if n == nil or n > this_n then
			n = this_n
		end
	end

	return n
end

--- Check whether a ship has some cargo.
-- @param ship The ship to check.
-- @param entries The base cargo to check for.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return Whether the ship has at least the specified cargo.
function cargo.has(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if c.infinite then return true end
	if c.items == nil then return false end

	for material, count in pairs(entries) do
		local amount = c.items[material]
		if amount == nil or amount < count * mult then
			return false
		end
	end

	return true
end

--- Check whether a ship has space for some cargo.
-- @param ship The ship to check.
-- @param n The number of items to add, or the cargo to add.
-- @param mult The amount to multiply the base value by; default 1.
-- @return Whether the ship has space for the specified cargo.
function cargo.hasSpace(ship, n, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if not c.limit then return true end

	if type(n) == "table" then
		-- list of items to check space for
		local sum = 0
		for k, v in pairs(n) do
			sum = sum + v
		end
		n = sum
	end

	local currentSum = 0
	if c.items then
		for k, v in pairs(c.items) do
			currentSum = currentSum + v
		end
	end

	if currentSum + n * mult > c.limit then
		return false
	end

	return true
end

--- Attempt to remove cargo from a ship.
-- This operation is atomic; if the ship is missing any cargo from the list, then no cargo will be removed.
-- @param ship The ship to remove cargo from.
-- @param entries The base cargo to attempt to remove.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return Whether the cargo was successfully removed.
function cargo.use(ship, entries, mult)
	if not mult then mult = 1 end
	return cargo.adjust(ship, entries, -mult)
end

--- Adjust a ship's cargo by an amount.
-- This operation is atomic; if the ship is missing any removed cargo, or does not have space to accept added cargo, then no cargo will be adjusted.
-- @param ship The ship to adjust cargo for
-- @param entries The base cargo to attempt to adjust.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return Whether the cargo was successfully adjusted.
function cargo.adjust(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if c.infinite then return true end
	if c.items == nil then c.items = {} end

	local deltaSum = 0

	for material, delta in pairs(entries) do
		if delta * mult < 0 then
			if (c.items[material] or 0) < -delta * mult then return false end
		end

		deltaSum = deltaSum + delta * mult
	end

	if c.limit then
		local currentSum = 0
		for k, v in pairs(c.items) do
			currentSum = currentSum + v
		end

		if currentSum + deltaSum > c.limit then return false end
	end

	for material, delta in pairs(entries) do
		c.items[material] = (c.items[material] or 0) + delta * mult
	end

	return true
end

--- Format a cargo list in a short format such as `"3Ti, 2Si"`.
-- @param entries The base cargo to format.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return A short string describing the cargo.
function cargo.formatShort(entries, mult)
	if entries == nil then error("nil cargo entries", 2) end

	if not mult then mult = 1 end

	local res = {}

	for _, def in ipairs(cargo.items) do
		local c = entries[def.id]
		if c and c > 0 then
			table.insert(res, (c * mult) .. def.id)
		end
	end

	return table.concat(res, ", ")
end

--- Format a cargo list in a long format such as `"3 titanium, 2 silicon"`.
-- @param entries The base cargo to format.
-- @param mult The amount to multiply the base cargo by; default 1.
-- @return A string describing the cargo.
function cargo.formatLong(entries, mult)
	if not mult then mult = 1 end

	local res = {}

	for _, def in ipairs(cargo.items) do
		local c = entries[def.id]
		if c and c > 0 then
			table.insert(res, (c * mult) .. " " .. def.name)
		end
	end

	return table.concat(res, ", ")
end
