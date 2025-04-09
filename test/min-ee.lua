-- Module: gn32/test/min-ee
-- Description: Provides minimal EE function set for testing purposes

-- require "gn32/utils"

-- utils for EE functions
local function makeCallback()
	local cb

	local set = function(callback)
		cb = callback
	end
	local trigger = function(...)
		if cb then cb(...) end
	end

	return set, trigger
end


-- Global data
G.scenarioTime = 42.123
G.getScenarioTime = function() return scenarioTime end

-- GM functions
G.resetGMFunctions = function()
	G.gmFunctions = {}
end
resetGMFunctions()

function G.addGMFunction(name, callback)
	for _, v in ipairs(gmFunctions) do
		if v.name == name then
			v.action = callback
			return
		end
	end

	table.insert(gmFunctions, {
		name = name,
		action = callback,
	})
end
function G.removeGMFunction(name)
	for i, v in ipairs(gmFunctions) do
		if v.name == name then
			table.remove(gmFunctions, i)
			return
		end
	end
end

local entity = {}
local entity_mt = {__index=entity}

local function add_cb(target, onAction, act, extra_fn)
	local cb_key = "cb_" .. act
	target[onAction] = function(self, cb)
		self[cb_key] = cb
		return self
	end
	target[act] = function(self, ...)
		if extra_fn then extra_fn(self) end
		if self[cb_key] then self[cb_key](self, ...) end
	end
end
local function add_getset(target, field, argn, ...)
	target[field] = {...}
	target["get"..field] = function(self)
		return table.unpack(self[field])
	end
	target["set"..field] = function(self, ...)
		local t = {}
		table.move({...}, 1, argn, 1, t)
		self[field] = t
		return self
	end
end

-- Entity
function entity:isValid() return not self.destroyed end
add_cb(entity, "onDestroyed", "destroy", function(e) e.destroyed = true end)
add_cb(entity, "onDestruction", "destruct")
add_cb(entity, "onExpiration", "expire")
add_getset(entity, "Velocity", 2, 0, 0)
add_getset(entity, "AngularVelocity", 1, 0)
add_getset(entity, "Position", 2, 0, 0)
add_getset(entity, "Rotation", 1, 0)
add_getset(entity, "CallSign", 1, nil)

local upvalueid = debug.upvalueid

function G.Entity()
	local ptr; ptr = upvalueid(function() return ptr end, 1)
	return setmetatable({__ptr=ptr}, entity_mt)
end

-- STBO
local stbo = setmetatable({}, entity_mt)
local stbo_mt = {__index=stbo}

add_getset(stbo, "Hull", 1, 0)
add_getset(stbo, "HullMax", 1, 0)

function stbo:getSystemData(sys)
	if self.systems == nil then
		self.systems = {}
	end
	if self.systems[sys] == nil then
		self.systems[sys] = {}
	end
	return self.systems[sys]
end
local function add_system_getset(field, default)
	stbo["getSystem"..field] = function(self, sys)
		return self:getSystemData(sys)[field] or default
	end
	stbo["setSystem"..field] = function(self, sys, v)
		self:getSystemData(sys)[field] = v
		return self
	end
end

add_system_getset("HealthMax", 1)
add_system_getset("Health", 1)
add_system_getset("Power", 1)
add_system_getset("PowerRequest", 1) -- gn32-script only

function G.STBO()
	return setmetatable({}, stbo_mt)
		:setCallSign("STBO" .. math.random(100, 999))
end

-- SpaceStation
function G.SpaceStation()
	return setmetatable({}, stbo_mt)
		:setCallSign("SS" .. math.random(100, 999))
end

-- SpaceShip
local spaceship = setmetatable({}, stbo_mt)
local spaceship_mt = {__index=spaceship}

add_getset(spaceship, "Energy", 1, 0)
add_getset(spaceship, "MaxEnergy", 1, 0)
add_getset(spaceship, "DockedWith", 1, nil)

function G.SpaceShip()
	return setmetatable({}, spaceship_mt)
		:setCallSign("SH" .. math.random(100, 999))
end

-- CpuShip
function G.CpuShip()
	return setmetatable({}, spaceship_mt)
		:setCallSign("CPU" .. math.random(100, 999))
end

-- PlayerSpaceship
G.onNewPlayerShip, G.newPlayerShip = makeCallback()
G.activePlayerShips = {}

function G.getActivePlayerShips()
	return activePlayerShips
end

local playership = setmetatable({}, spaceship_mt)
local playership_mt = {__index=playership}

function G.PlayerSpaceship()
	return setmetatable({}, playership_mt)
		:setCallSign("PS" .. math.random(100, 999))
end

add_cb(playership, "onProbeLaunch", "probeLaunch")

add_getset(playership, "MaxCoolant", 1, 10)
add_getset(playership, "MaxScanProbeCount", 1, 10)
add_getset(playership, "ScanProbeCount", 1, 10)

function playership:addCustomButton(station, id, button, action)
	if not self.customButtons then self.customButtons = {} end
	for _, v in ipairs(self.customButtons) do
		if v.id == id then
			v.station = station
			v.button = button
			v.action = action
			v.info = nil
			return
		end
	end

	table.insert(self.customButtons, {id=id, station=station, button=button, action=action})
end
function playership:addCustomInfo(station, id, info)
	if not self.customButtons then self.customButtons = {} end
	for _, v in ipairs(self.customButtons) do
		if v.id == id then
			v.station = station
			v.button = nil
			v.action = nil
			v.info = info
			return
		end
	end

	table.insert(self.customButtons, {id=id, station=station, info=info})
end
function playership:removeCustom(id)
	if not self.customButtons then return end
	for i, v in ipairs(self.customButtons) do
		if v.id == id then
			table.remove(self.customButtons, i)
			return
		end
	end
end

-- comms
function G.resetCommsData()
	G.commsData = {replies = {}}
end
resetCommsData()

function G.setCommsMessage(text)
	commsData.message = text
end

function G.addCommsReply(name, action)
	table.insert(commsData.replies, {name=name, action=action})
end


G.Artifact = Entity
G.Asteroid = Entity
G.BlackHole = Entity
G.Nebula = Entity
G.Planet = Entity
G.ScanProbe = Entity
G.SupplyDrop = Entity
G.VisualAsteroid = Entity
G.WarpJammer = Entity
G.WormHole = Entity
G.Zone = Entity
