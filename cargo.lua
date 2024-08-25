-- Module: gn32/cargo
-- Description: Adds inventory functionality to ships.
--[[
	To define items that can be carried by ships:
		cargo.addItems(
			{ id = "Ti", name = "titanium", desc = "a strong metal" },
			{ id = "Si", name = "silicon", desc = "a semiconductor" }
		)

	To enable a ship to carry cargo:
		ship.cargo = {}            -- unlimited space
		ship.cargo = {limit = 20}  -- can carry 20 items

	To create a cargo drop entity:
		CargoDrop("Ti")    -- can be picked up immediately
		CargoDrop("Ti", 5) -- cannot be picked up for 5 seconds


	The below functions also accept an optional final parameter `mult` which is applied as a multiplier to each entry.
	Each function returns whether the operation was successful unless otherwise specified.

	To add or remove cargo to a ship:
		cargo.adjust(ship, { Ti=2, Si=-1 })  -- add 2 Ti, remove 1 Si

	To remove cargo from a ship:
		cargo.use(ship, { Ti=2 })

	To check if a ship has at least specific cargo:
		cargo.has(ship, { Ti=2 })

	To check how many of a specific set of cargo a ship has:
		cargo.count(ship, { Ti=2, Si=1 })  -- how many times could the ship provide 2 Ti + 1 Si?

	To check if a ship has space to accept cargo:
		cargo.hasSpace(ship, 2)         -- space for 2 items
		cargo.hasSpace(ship, { Ti=2 })  -- space for this specific set of items

	To format a cargo list:
		cargo.formatShort({ Ti=2, Si=1 })  -- returns "1Si, 2Ti"
		cargo.formatLong({ Ti=2, Si=1 })   -- returns "1 silicon, 2 titanium"
]]

require "gn32/lang"

G.cargo = {}

cargo.items = {}

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

function cargo.count(ship, entries, mult)
	if not mult then mult = 1 end
	if not ship.cargo then return 0 end
	if ship.cargo.infinite then return 100 end
	if ship.cargo.items == nil then return 0 end

	local n

	for material, count in pairs(entries) do
		local amount = ship.cargo.items[material]
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

function cargo.has(ship, entries, mult)
	if not mult then mult = 1 end
	if not ship.cargo then return false end
	if ship.cargo.infinite then return true end
	if ship.cargo.items == nil then return false end

	for material, count in pairs(entries) do
		local amount = ship.cargo.items[material]
		if amount == nil or amount < count * mult then
			return false
		end
	end

	return true
end

function cargo.hasSpace(ship, n, mult)
	if not mult then mult = 1 end
	if not ship.cargo then return false end
	if not ship.cargo.limit then return true end

	if type(n) == "table" then
		-- list of items to check space for
		local sum = 0
		for k, v in pairs(n) do
			sum = sum + v
		end
		n = sum
	end

	local currentSum = 0
	if ship.cargo.items then
		for k, v in pairs(ship.cargo.items) do
			currentSum = currentSum + v
		end
	end

	if currentSum + n * mult > ship.cargo.limit then
		return false
	end

	return true
end

function cargo.use(ship, entries, mult)
	if not mult then mult = 1 end
	return cargo.adjust(ship, entries, -mult)
end

function cargo.adjust(ship, entries, mult)
	if not mult then mult = 1 end
	if not ship.cargo then return false end
	if ship.cargo.infinite then return true end
	if ship.cargo.items == nil then ship.cargo.items = {} end

	local deltaSum = 0

	for material, delta in pairs(entries) do
		if delta * mult < 0 then
			if (ship.cargo.items[material] or 0) < -delta * mult then return false end
		end

		deltaSum = deltaSum + delta * mult
	end

	if ship.cargo.limit then
		local currentSum = 0
		for k, v in pairs(ship.cargo.items) do
			currentSum = currentSum + v
		end

		if currentSum + deltaSum > ship.cargo.limit then return false end
	end

	for material, delta in pairs(entries) do
		ship.cargo.items[material] = (ship.cargo.items[material] or 0) + delta * mult
	end

	return true
end

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
