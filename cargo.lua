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

--- Terminology.
-- @section terminology

--- Any object that can be carried by a ship as cargo.
-- @table item

--- A table describing the properties of an item, such as its name and description.
-- Bulk cargo must have a single unique table. Fields not specified here are permitted and preserved.
-- @table item_definition
-- @string[opt] id The id of the item. Required if this definition is passed to `cargo.addItems`, otherwise forbidden. If present, should be short and descriptive, and must not start with a digit.
-- @string name The name of the item, in mid-sentence case.
-- @string desc The description of the item. May contain newlines.
local itemSchema = {
	_type = "table",
	-- _check rather than _fields so that a) other fields are permitted, and b) ecs doesn't turn the definition table into a schema-checking proxy
	_check = function(v)
		if v.id ~= nil then
			if type(v.id) ~= "string" then
				return "wrong-type id"
			end
			if v.id == "" or v.id:match("^%d") then
				return "empty or digit-prefixed id '" .. v.id .. "'"
			end
			if cargo.items[v.id] ~= v then
				return "duplicate or unregistered id '" .. v.id .. "'"
			end
		end
		if type(v.name) ~= "string" then
			return "missing or wrong-type name"
		end
		if type(v.desc) ~= "string" then
			return "missing or wrong-type desc"
		end
	end,
}

--- A string matching the `id` of any `item_definition` previously provided to `cargo.addItems`, or any `item_definition`.
-- @table item_specifier

--- A map from `item_specifier` to an integer item count, which may be zero or negative unless otherwise specified.
-- @table cargo_list

G.cargo = {}

cargo.items = {}


--- Comps.
-- See `ecs` for details of how to apply comps to an entity.
-- @section Comps

--- Allow an entity to hold cargo.
-- @table cargo
-- @bool[opt] infinite Whether this entity is an infinite source and sink of all items. Default false.
-- @number[opt] limit The maximum number of items this entity can carry, or zero for unlimited. Default zero.
-- @tab[opt] items A map from `item_definition` to item quantity. Default empty.
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
		_keys = itemSchema,
		_values = {
			_type = "number",
			_ge = 0,
			_check = function(v) return math.floor(v) == v end,
		},
	}
}

--- Functions.
-- @section functions

--- Add items that can be carried in bulk by ships.
-- @param ... A list of `item_definition`s, which must have id strings.
function cargo.addItems(...)
	for _, item in ipairs{...} do
		if type(item.id) ~= "string" then
			error("item did not have a string id: " .. tostring(item.id), 2)
		end
		if cargo.items[item.id] then
			error("duplicate item id " .. item.id, 2)
		end

		cargo.items[item.id] = item

		local err = schema.checkValue(item, itemSchema)
		if err then
			cargo.items[item.id] = nil -- schema required this, but we don't want to keep it if it failed
			error("item " .. item.id .. ": " .. err, 2)
		end

		table.insert(cargo.items, item)
	end
end

-- ENTITIES

--- Create a cargo drop entity.
-- @function CargoDrop
-- @param ty An `item_specifier` specifying the cargo type held by this entity
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

function cargo.resolve(item, err_n)
	if type(item) == "string" then
		if not cargo.items[item] then
			error("no such item " .. item, err_n+1)
		end
		return cargo.items[item]
	end

	local err = schema.checkValue(item, itemSchema)
	if err then
		error(err, err_n+1)
	end
	return item
end

-- EXPORTS

--- Iterate the cargo on a ship.
-- @param ship The ship to iterate the cargo of.
-- @return A Lua iterator over the cargo of the ship. This iterator will produce `item, count` pairs, where item is an `item_definition` and count is a non-negative integer.
function cargo.pairs(ship)
	local c = comps(ship).cargo
	if not c then return next, {}, nil end
	return pairs(c.items)
end

--- Count how many times over a ship has some cargo.
-- @param ship The ship to check.
-- @param entries The base `cargo_list` to check for.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return The number of instances of the cargo the ship has.
function cargo.count(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return 0 end
	if c.infinite then return 100 end

	local n

	for material, count in pairs(entries) do
		local amount = c.items[cargo.resolve(material, 2)]
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
-- @param entries The base `cargo_list` to check for.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return Whether the ship has at least the specified cargo.
function cargo.has(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if c.infinite then return true end

	for material, count in pairs(entries) do
		local amount = c.items[cargo.resolve(material, 2)]
		if amount == nil or amount < count * mult then
			return false
		end
	end

	return true
end

--- Check whether a ship has space for some cargo.
-- @param ship The ship to check.
-- @param n The base number of items to add, or the base `cargo_list` to add.
-- @param mult The amount to multiply the base counts by; default 1.
-- @return Whether the ship has space for the specified cargo.
function cargo.hasSpace(ship, n, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if c.limit == 0 then return true end

	if type(n) == "table" then
		-- list of items to check space for
		local sum = 0
		for k, v in pairs(n) do
			sum = sum + v
		end
		n = sum
	end

	local currentSum = 0
	for k, v in pairs(c.items) do
		currentSum = currentSum + v
	end

	if currentSum + n * mult > c.limit then
		return false
	end

	return true
end

--- Attempt to remove cargo from a ship.
-- This operation is atomic; if the ship is missing any cargo from the list, then no cargo will be removed.
-- @param ship The ship to remove cargo from.
-- @param entries The base `cargo_list` to attempt to remove.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return Whether the cargo was successfully removed.
function cargo.use(ship, entries, mult)
	if not mult then mult = 1 end
	return cargo.adjust(ship, entries, -mult)
end

--- Adjust a ship's cargo by an amount.
-- This operation is atomic; if the ship is missing any removed cargo, or does not have space to accept added cargo, then no cargo will be adjusted.
-- @param ship The ship to adjust cargo for
-- @param entries The base `cargo_list` to attempt to adjust.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return Whether the cargo was successfully adjusted.
function cargo.adjust(ship, entries, mult)
	if not mult then mult = 1 end
	local c = comps(ship).cargo
	if not c then return false end
	if c.infinite then return true end

	local deltaSum = 0

	for material, delta in pairs(entries) do
		if delta * mult < 0 then
			if (c.items[cargo.resolve(material, 2)] or 0) < -delta * mult then return false end
		end

		deltaSum = deltaSum + delta * mult
	end

	if c.limit > 0 then
		local currentSum = 0
		for k, v in pairs(c.items) do
			currentSum = currentSum + v
		end

		if currentSum + deltaSum > c.limit then return false end
	end

	for material, delta in pairs(entries) do
		material = cargo.resolve(material, 2)
		c.items[material] = (c.items[material] or 0) + delta * mult
	end

	return true
end

--- Format a cargo list in a short format such as `"3Ti, 2Si"`.
-- @param entries The base `cargo_list` to format.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return A short string describing the cargo.
function cargo.formatShort(entries, mult)
	if entries == nil then error("nil cargo entries", 2) end

	if not mult then mult = 1 end

	local res = {}

	for _, def in ipairs(cargo.items) do
		local c = entries[def] or entries[def.id]
		if c and c > 0 then
			table.insert(res, (c * mult) .. def.id)
		end
	end

	local nf = {}
	for item, count in pairs(entries) do
		item = cargo.resolve(item, 2)
		if not item.id then
			table.insert(nf, item.name)
		end
	end
	if nf[1] then
		table.sort(nf)
		table.insert(res, table.concat(nf, ", "))
	end

	return table.concat(res, ", ")
end

--- Format a cargo list in a long format such as `"3 titanium, 2 silicon"`.
-- @param entries The base `cargo_list` to format.
-- @param mult The amount to multiply the base cargo list counts by; default 1.
-- @return A string describing the cargo.
function cargo.formatLong(entries, mult)
	if not mult then mult = 1 end

	local res = {}

	for _, def in ipairs(cargo.items) do
		local c = entries[def] or entries[def.id]
		if c and c > 0 then
			table.insert(res, (c * mult) .. " " .. def.name)
		end
	end

	local nf = {}
	for item, count in pairs(entries) do
		item = cargo.resolve(item, 2)
		if not item.id then
			table.insert(nf, item.name)
		end
	end
	if nf[1] then
		table.sort(nf)
		table.insert(res, table.concat(nf, ", "))
	end

	return table.concat(res, ", ")
end
