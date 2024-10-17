--- [`hook`] Utility for tracking collections of entities.
-- @pragma nostrip

require "gn32/lang"

require "gn32/hook"

G.track = {}

local tracked = {}

--- Set tracking on an entity.
-- @param coll The collection to track the entity in.
-- @param entity The entity to track.
-- @param data Optional; data to store along with this tracking entry.
function track.set(coll, entity, data)
	if entity == nil then error("nil entity", 2) end

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

--- Stop tracking an entity.
-- @param coll The collection to stop tracking the entity in.
-- @param entity The entity to stop tracking.
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

--- Get the set of entities in a collection, or get the data associated with a specific entity.
-- @param coll The collection to read.
-- @param entity The entity to read data for, or omitted/nil to get the set of entities in the collection.
-- @return The data for the entity if passed, otherwise the collection of entities and mapping of data for this collection.
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

--- Do something for each tracked entity in a collection.
-- @param coll The collection to iterate.
-- @param f The function to call for each entity. Will be called with `(entity, data)`.
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

--- Check whether any entity in a collection matches a predicate.
-- @param coll The collection to check.
-- @param f The predicate to check for each entity.
-- @return The return value of the first invocation of `f` that returned a non-`false` non-`nil` value, if present; otherwise `nil`.
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

function hook.on.newPlayerShip(sh)
	track.set("playership", sh)
	track.set("ship", sh)
end
function hook.on.probeLaunch(sh, pr)
	track.set("probe", pr)
end
