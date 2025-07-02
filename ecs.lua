--- [`hook-sys`] Provides a Lua-side ECS.
-- Required hooks: `update`.
--
-- To interact with comps defined by a library, see `comps`.
--
-- To define your own comps, see `Comp` and `System`.

require "gn32/lang"
require "gn32/hook-sys"
require "gn32/classutil"
require "gn32/schema"

-- [[ GLOBAL DATA STORAGE ]]

-- component_key => Comp
local defs_component = {}

-- entity => Comp => component_data
local map_ent_comp_data = setmetatable({}, {__mode = "k"})
-- Comp => entity => component_data
local map_comp_ent_data = setmetatable({}, {__mode = "k"})

-- entity.comp => entity
local ecomp_entity = setmetatable({}, {__mode = "kv"})

--- Entity.
-- An entity is a thing that exists in the world of EmptyEpsilon. On `master`, this is a SpaceObject; on `ECS`, an Entity.
-- @section Entity

local ecompMetatable = {
	__index = function(ecomp, key)
		local def = defs_component[key]
		if not def then error("comp " .. key .. " is not defined", 2) end

		local ent = ecomp_entity[ecomp]
		if not ent or not ent.isValid or not ent:isValid() then error("attempt to access comps of destroyed entity", 2) end

		local data = map_ent_comp_data[ent] and map_ent_comp_data[ent][def]
		if not data then return nil end

		return data
	end,
	__newindex = function(ecomp, key, val)
		local def = defs_component[key]
		if not def then error("comp " .. key .. " is not defined", 2) end

		local ent = ecomp_entity[ecomp]
		if not ent or not ent:isValid() then error("attempt to access comps of destroyed entity", 2) end

		if val == nil then
			if map_ent_comp_data[ent] then
				map_ent_comp_data[ent][def] = nil
			end
			if map_comp_ent_data[def] then
				map_comp_ent_data[def][ent] = nil
			end
			return
		end

		local t = schema.makeTable({_fields=def.schema}, ("comps.%s."):format(key))

		local ok, e = pcall(function()
			for k, v in pairs(val) do
				t[k] = v
			end
		end)
		if not ok then
			error(e:sub(e:find(": ")+2, -1), 2)
		end

		local e = schema.checkValue(t, {_fields=def.schema})
		if e then
			error(("comps.%s.%s"):format(key, e), 2)
		end

		if not map_ent_comp_data[ent] then map_ent_comp_data[ent] = setmetatable({}, {__mode="k"}) end
		if not map_comp_ent_data[def] then map_comp_ent_data[def] = setmetatable({}, {__mode="k"}) end

		map_ent_comp_data[ent][def] = t
		map_comp_ent_data[def][ent] = t
	end,
}

if G.createEntity then
	local entity = getLuaEntityFunctionTable()

	--- [ECS] Get the comps associated with this entity.
	-- @return The `EntityComps` for the entity.
	function entity:comps()
		local ec = setmetatable({}, ecompMetatable)

		ecomps_entity[ec] = self

		return ec
	end
end

G.comps = nil
--- Get the comps associated with an entity.
-- @param e the entity to get comps for
-- @return The `EntityComps` for the entity.
function comps(e)
	if not e or not e.isValid or not e:isValid() then error("attempt to access comps of destroyed entity", 2) end

	local ec = setmetatable({}, ecompMetatable)

	ecomp_entity[ec] = e

	return ec
end

--- Holds the comp instances associated with the entity it was accessed from.
--
-- - To set a comp, set `comps[name] = {...}`.
-- - To read a comp, read `comps[name]`.
-- - To edit a comp in-place, set the desired fields on `comps[name]`.
--
-- For example, with a hypothetical "position" comp defined as having fields "x" and "y":
--
-- - To set the position: `comps.position = {x = 1, y = 2}`
-- - To read the x coordinate: `local x = comps.position.x`
-- - To set only the y coordinate: `comps.position.y = 42`
--
-- For details of what fields are available on each comp, refer to the documentation for the specific comp.
-- @table EntityComps

--- Comp.
-- A Comp defines a collection of data that can be attached to an entity.
-- @section comp

local Comp, comp = makeClass()
G.Comp = Comp

--- Create a new Comp.
-- @function Comp
-- @param key The key of the new Comp.
-- @return The new Comp instance.
function comp:_init(key)
	self.key = key
	self.schema = {}

	defs_component[key] = self
end

--- Set the schema for a comp. If this method is not called, the comp will not permit any fields.
-- For details on the schema format, see `schema.tableSchema`.
-- @return self
function comp:setSchema(schema)
	if type(schema) ~= "table" then error("schema must be a table", 2) end
	self.schema = schema
	return self
end

--- Destroy this comp, removing it from all entities.
function comp:destroy()
	defs_component[self.key] = nil
end

--- System.
-- A `System` processes a set of entities, typically which share some set of comps and/or components in common.
-- @section System

local all_systems = {}
local systems_by_name = setmetatable({}, {__mode="v"})

local System, system = makeClass()
G.System = System

--- Create a new System.
-- @function System
-- @param name The name of the new System.
-- @return The new System instance.
function system:_init(name)
	self.name = name
	self.before = {}
	self.after = {}
	self.requiredComponents = {}
	self.requiredComps = {}

	table.insert(all_systems, self)
	systems_by_name[name] = self
end

--- [ECS] Add EE ECS components that are required on each entity this system processes.
-- @param ... The component names that are required.
-- @return self
function system:addRequiredComponents(...)
	for _, name in ipairs{...} do
		table.insert(self.requiredComponents, name)
	end
	return self
end

--- Add Lua ECS comps that are required on each entity this system processes.
-- If possible, the first such comp should be the least likely to appear, as it will be used to pre-filter the entity set.
-- @param ... The comp names that are required.
-- @return self
function system:addRequiredComps(...)
	for _, name in ipairs{...} do
		table.insert(self.requiredComps, name)
	end
	return self
end

--- Add a callback to call once per update call for this system.
-- @param fn The callback to use, which will be called with (delta, ents).
-- @return self
function system:onUpdateGlobal(fn)
	self.global = fn
	return self
end

--- Add a callback to call once per entity per update call for this system.
-- @param fn The callback to use, which will be called with (delta, ent, comps).
-- @return self
function system:onUpdateEntity(fn)
	self.entity = fn
	return self
end

--- Enforce that this system must run before another in each update.
-- @param name The name of the other system.
-- @return self
function system:runBefore(name)
	table.insert(self.before, name)
	return self
end

--- Enforce that this system must run after another in each update.
-- @param name The name of the other system.
-- @return self
function system:runAfter(name)
	table.insert(self.after, name)
	return self
end

function system:_entitySatisfiesRequirements(ent, data)
	for _, req in ipairs(self.requiredComps) do
		if not data[defs_component[req]] then
			return false
		end
	end

	for _, req in ipairs(self.requiredComponents) do
		if not ent.components[req] then
			return false
		end
	end

	return true
end

--- Destroy this system, stopping it from processing.
function system:destroy()
	systems_by_name[self.name] = nil
	for i, v in ipairs(all_systems) do
		if v == self then
			table.remove(all_systems, i)
			return
		end
	end
end

local queryMetatable = {
	__pairs = function(t)
		local tbl = map_ent_comp_data
		if #t.sys.requiredComps > 0 then
			local def = defs_component[t.sys.requiredComps[1]]
			tbl = map_comp_ent_data[def] or {}
		end

		return function(_, ent)
			while true do
				ent = next(tbl, ent)
				if ent == nil then return nil end

				if ent:isValid() then
					local data = map_ent_comp_data[ent]

					if t.sys:_entitySatisfiesRequirements(ent, data) then
						return ent, comps(ent)
					end
				end
			end
		end, t, nil
	end,
}

--- Query all entities that this system should process.
-- @return A table which when iterated over with `pairs()` will yield `ent, comps` pairs.
function system:query()
	return setmetatable({sys=self}, queryMetatable)
end

function system:_update(delta)
	if self.global or self.entity then
		local ents = self:query()

		if self.global then
			self.global(delta, ents)
		end

		if self.entity then
			for ent, comp in pairs(ents) do
				self.entity(delta, ent, comp)
			end
		end
	end
end

--- Efficiently query entities that have a specified comp.
-- @param comp The comp to query for.
-- @return A table which when iterated over with `pairs()` will yield `ent, comps` pairs.
function System.queryEntitiesWithComp(comp)
	return setmetatable({
		sys = {
			requiredComps = {comp},
			_entitySatisfiesRequirements = function() return true end,
		}
	}, queryMetatable)
end

function System.update(delta)
	local doneList = {}
	local doneMap = {}

	local queue = {}
	local defer = {}

	for i, sys in ipairs(all_systems) do
		queue[i] = sys

		-- convert any run-before constraints into run-after constraints on the other system
		if sys.before then
			for _, name in ipairs(sys.before) do
				local other = systems_by_name[name]
				if not other then
					print("gn32/ecs: ignoring run-before constraint " .. name .. " on " .. sys.name .. ": no such system")
				else
					table.insert(other.after, sys.name)
				end
			end
			sys.before = nil
		end
	end

	local progress = false
	local n = 0
	while true do
		if #queue == 0 then
			n = n + 1
			if #defer == 0 then
				-- replace the system list with the list we just completed, which is now in a valid run-order for all systems
				all_systems = doneList
				return n
			end

			if not progress then
				local s = "unsolvable constraints:\n"
				for _, sys in ipairs(defer) do
					s = s .. "system " .. sys.name .. " should run after " .. table.concat(sys.after, ", ") .. "\n"
				end
				error(s)
			end

			queue = defer
			defer = {}
			progress = false
		end

		local sys = queue[1]
		table.remove(queue, 1)

		local canRunNow = true
		for i, other in pairs(sys.after) do
			if not doneMap[other] then
				if not systems_by_name[other] then
					print("gn32/ecs: ignoring run-after constraint " .. other .. " on " .. sys.name .. ": no such system")
					sys.after[i] = nil
				else
					canRunNow = false
					break
				end
			end
		end

		if canRunNow then
			if debug.enabled.ecs then print("[ecs: " .. sys.name .. "]", "update") end
			local ok, err = pcall(sys._update, sys, delta)
			if not ok then
				print("gn32/ecs: update error in system: " .. sys.name .. ": " .. err)
			end
			table.insert(doneList, sys)
			doneMap[sys.name] = true
			progress = true
		else
			table.insert(defer, sys)
		end
	end
end

hook.on.update = System.update
