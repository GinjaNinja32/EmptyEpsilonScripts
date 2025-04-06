--- [`hook-sys`] Utility for tracking collections of entities.
-- Required hooks: `newPlayerShip`, `probeLaunch`.
-- @pragma nostrip

require "gn32/lang"
require "gn32/classutil"
require "gn32/fnhook"
require "gn32/hook-sys"

local function checkEntity(e)
	if e == nil then
		return false
	end
	if e.isValid and not e:isValid() then
		return false
	end
	return true
end

local function assertEntity(e)
	if e == nil then
		error("nil entity", 3)
	end
	if e.isValid and not e:isValid() then
		error("destroyed entity", 3)
	end
end

local tracker, tracker_mt
G.Tracker, tracker, tracker_mt = makeClass()

--- Tracker
-- @section tracker

--- Create a new entity tracker.
-- @function Tracker
function tracker:_init()
	self.entities = {}
	self.data = {}
end

--- Add an entity to the tracked set.
-- @param entity The entity to track.
-- @param[opt] data The data to associate with the entity.
function tracker:set(entity, data)
	assertEntity(entity)

	self.data[entity] = data

	for _, ent in ipairs(self.entities) do
		if ent == entity then
			return
		end
	end

	table.insert(self.entities, entity)
end

--- Remove an entity from the tracked set.
-- @param entity The entity to stop tracking.
function tracker:remove(entity)
	for i, ent in ipairs(self.entities) do
		if ent == entity then
			table.remove(self.entities, i)
			break
		end
	end
	self.data[entity] = nil
end

--- Get the associated data for a tracked entity.
-- @param entity The entity to get data for.
-- @return The associated data for the entity, if tracked; otherwise `nil`.
function tracker:get(entity)
	if not checkEntity(entity) then
		return nil
	end
	return self.data[entity]
end

tracker_mt.__pairs = function(self)
	local idx = 1
	return function(self, last)
		if self.entities[idx] == last then
			idx = idx + 1
		end

		local ent = self.entities[idx]
		while ent and not checkEntity(ent) do
			table.remove(self.entities, idx)
			self.data[ent] = nil
			ent = self.entities[idx]
		end
		if not ent then
			return nil
		end
		return ent, self.data[ent]
	end, self, nil
end

--- Call a function for each tracked entity.
-- Entities may not be added or removed from the tracked set during execution, with the exception that `f` may remove its argument entity from the tracked set.
--
-- Note that trackers support `pairs`, iterating the same data; this function is equivalent to:
-- 	for entity, data in pairs(tracker) do
-- 		f(entity, data)
-- 	end
-- @param f A `function(entity, data)` to call for each tracked entity.
function tracker:each(f)
	for e, d in pairs(self) do
		f(e, d)
	end
end

--- Check whether any entity in a collection matches a predicate.
-- Entities may not be added or removed from the tracked set during execution.
-- @param f A `function(entity, data)` to call for each tracked entity.
-- @return The return values of the first invocation of `f` whose first return value was not `nil` or `false`, if any; otherwise `nil`.
function tracker:any(f)
	for e, d in pairs(self) do
		local vals = {f(e, d)}
		if vals[1] then
			return table.unpack(vals)
		end
	end
end


local named = {}

local function getNamed(name)
	if not named[name] then
		named[name] = Tracker()
	end

	return named[name]
end

--- Functions
-- @section functions

G.track = {}

--- Add an entity to the tracked set of a named tracker.
-- @tparam string name The name of the tracker.
-- @tparam entity entity The entity to track.
-- @param[opt] data The data to associate with the entity.
function track.set(name, entity, data)
	getNamed(name):set(entity, data)
end

--- Remove an entity from the tracked set of a named tracker.
-- @tparam string name The name of the tracker.
-- @tparam entity entity The entity to remove.
function track.remove(name, entity)
	getNamed(name):remove(entity)
end

--- Get the data associated with a tracked entity in a named tracker.
-- @tparam string name The name of the tracker.
-- @tparam entity entity The entity to get data for.
function track.get(name, entity)
	return getNamed(name):get(entity)
end

--- Call a function for each tracked entity in a named tracker.
-- This function has the same concurrency requirements as `tracker:each`.
-- @tparam string name The name of the tracker.
-- @param f A `function(entity, data)` to call for each tracked entity.
function track.each(name, f)
	getNamed(name):each(f)
end

--- Check whether any entity in a collection matches a predicate.
-- This function has the same concurrency requirements as `tracker:any`.
-- @tparam string name The name of the tracker.
-- @param f A `function(entity, data)` to call for each tracked entity.
-- @return The return values of the first invocation of `f` whose first return value was not `nil` or `false`, if any; otherwise `nil`.
function track.any(name, f)
	return getNamed(name):any(f)
end

--- Predefined named trackers.
-- Entities should not be added or removed from these trackers. They are provided for read access only.
-- @section named

--- Contains all existing instances of `CpuShip`.
-- @table cpuship

--- Contains all existing instances of `PlayerSpaceship`.
-- @table playership

--- Contains all existing instances of `CpuShip` or `PlayerSpaceship`.
-- @table ship

--- Contains all existing instances of `SpaceStation`.
-- @table station

--- Contains all existing instances of `ScanProbe`.
-- @table probe

function fnhook.CpuShip(sh)
	track.set("cpuship", sh)
	track.set("ship", sh)
end

function fnhook.PlayerSpaceship(sh)
	track.set("playership", sh)
	track.set("ship", sh)
end

function fnhook.SpaceStation(st)
	track.set("station", st)
end

function hook.on.newPlayerShip(sh)
	track.set("playership", sh)
	track.set("ship", sh)
end

function fnhook.ScanProbe(pr)
	track.set("probe", pr)
end

function hook.on.probeLaunch(sh, pr)
	track.set("probe", pr)
end
