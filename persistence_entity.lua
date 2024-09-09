--- Helper functions and utilities for persisting entity data.

if not G.persistence then G.persistence = {} end

persistence.entity = {}

local defs = {
	name = {},
	key = {},
}

--- Functions.
-- @section functions

--- Define a persistable entity field.
-- @param name The name of the field. Must be unique.
-- @param key The storage key of the field. Must be unique. Should be short.
-- @param get Either the name of an entity method or a `function(e, ...)` to get the stored data from an entity. If a function, a second return value defines the default value.
-- @param set Either the name of an entity method or a `function(e, ..., val)` to set the stored data on an entity.
-- @param getDefaultM If `get` is the name of an entity method, then the name of an entity method to get the default value, or `nil`.
-- @param addArgs The value(s) to pass in place of `...` in `get`, `set`, and `getDefaultM`.
function persistence.entity.defineField(name, key, get, set, getDefaultM, addArgs)
	if defs.name[name] then
		error("duplicate entity field name for " .. name, 2)
	end
	if defs.key[key] then
		error("duplicate entity field key for " .. name .. ": " .. key, 2)
	end
	if type(get) == "string" then
		local getm = get
		if getDefaultM then
			get = function(e, ...) return e[getm](e, ...), e[getDefaultM](e, ...) end
		else
			get = function(e, ...) return e[getm](e, ...) end
		end
	elseif type(get) ~= "function" then
		error("entity field get must be a function", 2)
	end

	if type(set) == "string" then
		local setm = set
		set = function(e, ...) e[setm](e, ...) end
	elseif type(set) ~= "function" then
		error("entity field set must be a function", 2)
	end

	if addArgs ~= nil then
		local oldGet = get
		get = function(e) return oldGet(e, table.unpack(addArgs)) end
		local oldSet = set
		set = function(e, n)
			local args = {table.unpack(addArgs)}
			table.insert(args, n)
			return oldSet(e, table.unpack(args))
		end
	end

	-- unique! add it.
	local t = {name=name, key=key, get=get, set=set}

	defs.name[name] = t
	defs.key[key] = t
end

--- Persistable fields.
-- @section fields

--- Template.
-- @table template
persistence.entity.defineField("template",   "t", "getTemplate",       "setTemplate")
--- Callsign.
-- @table callsign
persistence.entity.defineField("callsign",   "c", "getCallSign",       "setCallSign")
--- Current hull.
-- @table hull
persistence.entity.defineField("hull",       "h", "getHull",           "setHull",           "getHullMax")
--- Max hull.
-- @table hullMax
persistence.entity.defineField("hullMax",    "H", "getHullMax",        "setHullMax")
--- Energy.
-- @table energy
persistence.entity.defineField("energy",     "e", "getEnergyLevel",    "setEnergyLevel",    "getEnergyLevelMax")
--- Max energy.
-- @table energyMax
persistence.entity.defineField("energyMax",  "E", "getEnergyLevelMax", "setEnergyLevelMax")
--- Total available coolant.
-- @table coolant
persistence.entity.defineField("coolant",    "T", "getMaxCoolant",     "setMaxCoolant")

--- HVLI ammunition.
-- @table hvli
persistence.entity.defineField("hvli",   "av", "getWeaponStorage", "setWeaponStorage", "getWeaponStorageMax", {"HVLI"})
--- Homing ammunition.
-- @table homing
persistence.entity.defineField("homing", "ah", "getWeaponStorage", "setWeaponStorage", "getWeaponStorageMax", {"Homing"})
--- EMP ammunition.
-- @table emp
persistence.entity.defineField("emp",    "ae", "getWeaponStorage", "setWeaponStorage", "getWeaponStorageMax", {"EMP"})
--- Nuke ammunition.
-- @table nuke
persistence.entity.defineField("nuke",   "an", "getWeaponStorage", "setWeaponStorage", "getWeaponStorageMax", {"Nuke"})
--- Mine ammunition.
-- @table mine
persistence.entity.defineField("mine",   "am", "getWeaponStorage", "setWeaponStorage", "getWeaponStorageMax", {"Mine"})

--- Current shields.
-- @table shield
persistence.entity.defineField("shield", "s",
	function(e)
		local data = {}
		for i = 0, e:getShieldCount()-1 do
			data[i+1] = persistence.ifChanged(e:getShieldLevel(i), e:getShieldMax(i))
		end
		return data
	end,
	function(e, data)
		local args = {}
		for i = 0, e:getShieldCount()-1 do
			local v = data[i+1]
			if v ~= nil then
				table.insert(args, v)
			else
				table.insert(args, e:getShieldMax(i))
			end
		end
		e:setShields(table.unpack(args))
	end
)
--- Max shields.
-- @table shieldMax
persistence.entity.defineField("shieldMax", "S",
	function(e)
		local data = {}
		for i = 0, e:getShieldCount()-1 do
			data[i+1] = e:getShieldMax(i)
		end
		return data
	end,
	function(e, data)
		local args = {}
		for i = 0, e:getShieldCount()-1 do
			local v = data[i+1]
			if v ~= nil then
				table.insert(args, v)
			else
				table.insert(args, e:getShieldMax(i))
			end
		end
		e:setShieldsMax(table.unpack(args))
	end
)
--- Position.
-- @table position
persistence.entity.defineField("position", "p",
	function(e)
		local x, y = e:getPosition()
		local r = e:getRotation()
		return {x, y, r}
	end,
	function(e, pos)
		local x, y, r = table.unpack(pos)
		e:setPosition(x, y):setRotation(r)
	end
)
--- Velocity.
-- @table velocity
persistence.entity.defineField("velocity", "v",
	function(e)
		local x, y = e:getVelocity()
		local r = e:getAngularVelocity()
		return {x, y, r}
	end,
	function(e, vel)
		local x, y, r = table.unpack(vel)
		e:setVelocity(x, y):setAngularVelocity(r)
	end
)

local systems = { "reactor", "beamweapons", "missilesystem", "maneuver", "impulse", "warp", "jumpdrive", "frontshield", "rearshield" }
local function defineSystemField(name, key, get, set, default)
	persistence.entity.defineField(name, key,
		function(e)
			local data = {}
			for i, sys in ipairs(systems) do
				local v = e[get](e, sys)

				local dv = default
				if type(dv) == "string" then
					dv = e[dv](e, sys)
				end

				if v ~= dv then
					data[i] = v
				end
			end
			return data
		end,
		function(e, data)
			for i, sys in ipairs(systems) do
				local v = data[i]

				if v == nil then
					v = default
					if type(v) == "string" then
						v = e[v](e, sys)
					end
				end

				if v ~= nil then
					e[set](e, sys, v)
				end
			end
		end
	)
end

--- System max health.
-- @table sysHealthMax
defineSystemField("sysHealthMax",  "sH", "getSystemHealthMax",      "setSystemHealthMax",             1)
--- System current health.
-- @table sysHealth
defineSystemField("sysHealth",     "sh", "getSystemHealth",         "setSystemHealth",                "getSystemHealthMax")
--- System hacked level.
-- @table sysHacked
defineSystemField("sysHacked",     "sk", "getSystemHackedLevel",    "setSystemHackedLevel",           0)
--- System heat level.
-- @table sysHeat
defineSystemField("sysHeat",       "st", "getSystemHeat",           "setSystemHeat",                  0)
--- System power request.
-- @table sysPowerReq
defineSystemField("sysPowerReq",   "sp", "getSystemPowerRequest",   "commandSetSystemPowerRequest",   1)
--- System power level.
-- @table sysPower
defineSystemField("sysPower",      "sP", "getSystemPower",          "setSystemPower",                 "getSystemPowerRequest")
--- System coolant request.
-- @table sysCoolantReq
defineSystemField("sysCoolantReq", "sc", "getSystemCoolantRequest", "commandSetSystemCoolantRequest", 0)
--- System coolant level.
-- @table sysCoolant
defineSystemField("sysCoolant",    "sC", "getSystemCoolant",        "setSystemCoolant",               "getSystemCoolantRequest")

--- Ship `cargo`.
-- @table cargo
persistence.entity.defineField("cargo", "C",
	function(ship) return comps(ship).cargo end,
	function(ship, n) comps(ship).cargo = n end
)

--- Functions.
-- @section functions

--- Save entity data to a table.
-- @param e The entity to save data from.
-- @param fields The list of fields to save.
-- @return A table containing the entity data.
function persistence.entity.save(e, fields)
	local data = {}

	for _, f in ipairs(fields) do
		local def = defs.name[f]
		if def == nil then
			print("Persistence error: field " .. f .. " not defined")
		else
			local ok, v, default = pcall(def.get, e)
			if ok then
				if v ~= default then
					data[def.key] = v
				end
			else
				print("Persistence error: saving field " .. def.name .. " (" .. def.key .. "): " .. tostring(v))
			end
		end
	end

	return data
end

--- Load entity data from a table.
-- @param e The entity to apply loaded data to.
-- @param fields The list of fields to load.
-- @param data A table containing the entity data.
function persistence.entity.load(e, fields, data)
	for _, f in ipairs(fields) do
		local def = defs.name[f]
		if def == nil then
			print("Persistence error: field " .. f .. " not defined")
		else
			local v = data[def.key]
			if v == nil then
				local ok, err, v2 = pcall(def.get, e)
				if not ok then
					print("Persistence error: checking field " .. def.name .. " (" .. def.key .. ") default: " .. tostring(err))
				else
					v = v2
				end
			end
			if v ~= nil then
				local ok, err = pcall(def.set, e, v)
				if not ok then
					print("Persistence error: loading field " .. def.name .. " (" .. def.key .. "): " .. tostring(err))
				end
			end
		end
	end
end

persistence.entity.cpushipFields = {
	"template",
	"position", "velocity",
	"callsign",
	"hull", "shield",
	"hvli", "homing", "emp", "nuke", "mine",
}

--- Save typical CpuShip data to a table.
-- Equivalent to `persistence.entity.save` with a preset list of fields.
-- @param e The CpuShip to save data from.
-- @return A table containing the entity data.
function persistence.entity.saveCpuShip(e) return persistence.entity.save(e, persistence.entity.cpushipFields) end
--- Load typical CpuShip data from a table.
-- Equivalent to `persistence.entity.load` with a preset list of fields.
-- @param e The CpuShip to apply loaded data to.
-- @param data A table containing the entity data.
function persistence.entity.loadCpuShip(e, data) persistence.entity.load(e, persistence.entity.cpushipFields, data) end

