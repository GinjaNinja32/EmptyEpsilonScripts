--- [`hook-sys`] Provides a Lua-side ECS.
-- Required hooks: `update`.

require "gn32/lang"
require "gn32/hook-sys"
require "gn32/classutil"

-- [[ GLOBAL DATA STORAGE ]]

-- component_key => Comp
local defs_component = {}

-- entity => component_key => component_data
local map_ent_comp_data = setmetatable({}, {__mode = "k"})
-- component_key => entity => component_data
local map_comp_ent_data = {}

-- entity.comp => entity
local ecomp_entity = setmetatable({}, {__mode = "kv"})

--- Entity
-- @section Entity

local ecompMetatable = {
	__index = function(ecomp, key)
		local def = defs_component[key]
		if not def then error("comp " .. key .. " is not defined", 2) end

		local ent = ecomp_entity[ecomp]
		if not ent or not ent:isValid() then error("attempt to access comps of destroyed entity", 2) end

		local data = map_ent_comp_data[ent] and map_ent_comp_data[ent][key]
		if not data then return nil end

		return setmetatable({}, {
			__index = function(_, k)
				return def:_readField(k, data[k], 2)
			end,
			__newindex = function(tbl, k, v)
				def:_validateWriteField(k, v, 3)
				data[k] = v
			end,
		})
	end,
	__newindex = function(ecomp, key, val)
		local def = defs_component[key]
		if not def then error("comp " .. key .. " is not defined", 2) end

		local ent = ecomp_entity[ecomp]
		if not ent or not ent:isValid() then error("attempt to access comps of destroyed entity", 2) end

		if val == nil then
			if map_ent_comp_data[ent] then
				map_ent_comp_data[ent][key] = nil
				map_comp_ent_data[key][ent] = nil
			end
			return
		end

		local t = {}

		for k, v in pairs(val) do
			t[k] = v
		end

		def:_validateObject(t, 3)

		if not map_ent_comp_data[ent] then map_ent_comp_data[ent] = {} end
		if not map_comp_ent_data[key] then map_comp_ent_data[key] = setmetatable({}, {__mode="k"}) end

		map_ent_comp_data[ent][key] = t
		map_comp_ent_data[key][ent] = t
	end,
}

if G.createEntity then
	local entity = getLuaEntityFunctionTable()

	--- [ECS] Get the comps associated with this entity.
	-- @return The comps for the entity.
	function entity:comps()
		local ec = setmetatable({}, ecompMetatable)

		ecomps_entity[ec] = self

		return ec
	end
end

G.comps = nil
--- Get the comps associated with an entity.
-- @param e the entity to get comps for
-- @return The comps for the entity.
function comps(e)
	local ec = setmetatable({}, ecompMetatable)

	ecomp_entity[ec] = e

	return ec
end

--- Comp
-- @section comp

local Comp, comp = makeClass()
G.Comp = Comp

--- Create a new Comp.
-- @function Comp
-- @param key The key of the new Comp.
-- @return The new Comp instance.
function comp:_init(key)
	self.key = key
	self.fields = {}

	defs_component[key] = self
end

--- Add a field to a comp, with an optional default and check.
-- @param name The name of the field.
-- @param default Optional. The default value of the field.
-- @param check Optional. A function(v) to check values of the field. The function should either return a bool (true = ok, false = bad value), or a string describing the problem.
-- @return self
function comp:addField(name, default, check)
	self.fields[name] = {default=default, check=check}
	return self
end

function comp:_readField(name, val, n)
	local fdef = self.fields[name]
	if not fdef then error("comp " .. self.key .. " has no field " .. name, n) end

	if val then return val end

	return fdef.default
end

function comp:_validateWriteField(name, val, n)
	local fdef = self.fields[name]
	if not fdef then error("comp " .. self.key .. " has no field " .. name, n) end

	if fdef.check then
		local e = fdef.check(val)
		if e ~= true and e ~= nil then
			if e == false then e = "bad value " .. tostring(val) end
			error("comp " .. self.key .. " field " .. name .. ": " .. e, n)
		end
	end
end

function comp:_validateObject(data, n)
	for k, v in pairs(data) do
		self:_validateWriteField(k, v, n+1)
	end

	for k, fdef in pairs(self.fields) do
		if not data[k] then
			self:_validateWriteField(k, fdef.default, n+1)
		end
	end
end

--- System
-- @section System

local all_systems = {}
local systems_by_name = {}

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
		if not data[req] then
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

local queryMetatable = {
	__pairs = function(t)
		local tbl = map_ent_comp_data
		if #t.sys.requiredComps > 0 then
			tbl = map_comp_ent_data[t.sys.requiredComps[1]] or {}
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
			sys:_update(delta)
			table.insert(doneList, sys)
			doneMap[sys.name] = true
			progress = true
		else
			table.insert(defer, sys)
		end
	end
end

hook.on.update = System.update
