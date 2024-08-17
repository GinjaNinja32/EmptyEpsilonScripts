-- Module: gn32/track
-- Description: Utility for tracking collections of entities
--[[
	To begin tracking an entity:
		track.set(
			coll,	-- The collection to track the entity in; must be usable as a table key
			entity,	-- The entity to track
			data	-- Optionally, data to store with this tracking entry
		)

	To retrieve data for a tracked entity:
		track.get(coll, entity)

	To retrieve a list of tracked entities and/or a map of entity data:
		entities, data = track.get(coll)

	To do something for each tracked entity:
		track.each(coll, function(entity, data) ... end)
]]

require "gn32/lang"

require "gn32/hook"

G.track = {}

local tracked = {}

function track.set(coll, entity, data)
	local e, d = track.get(coll)

	d[entity] = data

	for i, ent in ipairs(e) do
		if ent == entity then
			return
		end
	end

	table.insert(e, entity)

	hook.entity[entity].on.destroyed(function()
		track.remove(coll, entity)
	end)
end

function track.remove(coll, entity)
	local e, d = track.get(coll)
	for i, ent in pairs(e) do
		if ent == entity then
			table.remove(e, i)
			break
		end
	end
	d[entity] = nil
end

function track.get(coll, entity)
	if tracked[coll] == nil then
		tracked[coll] = {
			entities = {},
			data = {},
		}
	end

	if entity ~= nil then
		return tracked[coll].data[entity]
	end

	return tracked[coll].entities, tracked[coll].data
end

function track.each(coll, f)
	local e, d = track.get(coll)

	-- manual `ipairs`-like to allow entities to be removed/deleted while iterating
	local i = 1
	local ent = nil
	while true do
		if e[i] == ent then
			i = i + 1
		end

		ent = e[i]
		if ent == nil then
			break
		end

		f(ent, d[ent])
	end
end

function track.any(coll, f)
	local e, d = track.get(coll)

	for i, ent in pairs(e) do
		local v = f(ent, d[ent])
		if v then return v end
	end
end

local function trackCreate(f, ...)
	local colls = {...}
	return function()
		local e = f()
		for _, coll in ipairs(colls) do
			track.set(coll, e)
		end
		return e
	end
end

CpuShip = trackCreate(CpuShip, "cpuship", "ship")
PlayerSpaceship = trackCreate(PlayerSpaceship, "playership", "ship")
SpaceStation = trackCreate(SpaceStation, "station")
