-- Module: gn32/test/min-ee
-- Description: Provides minimal EE function set for testing purposes

-- require "gn32/utils"

-- utils for EE functions
local function makeCallback(asMethod)
	local cb

	local set
	if asMethod then
		set = function(self, callback)
			cb = callback
		end
	else
		set = function(callback)
			cb = callback
		end
	end
	local trigger = function(...)
		if cb then cb(...) end
	end

	return set, trigger
end
local function makeGetSet(asMethod, argn, ...)
	local v = {...}

	local get = function()
		return table.unpack(v)
	end
	local set = function(...)
		v = {}
		table.move({...}, 1, argn, 1, v)
	end

	if not asMethod then
		return get, set
	end

	return
		function(e) return get() end,
		function(e, ...) set(...); return e end
end
local function addGetSet(ent, field, argn, ...)
	ent["get"..field], ent["set"..field] = makeGetSet(true, argn, ...)
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

-- Entity
function G.Entity()
	local e = {}

	function e:isValid()
		return not self.destroyed
	end
	local onDestroy
	function e:onDestroyed(cb)
		onDestroy = cb
	end
	function e:destroy()
		self.destroyed = true
		if onDestroy then onDestroy(e) end
	end

	e.onDestruction, e.destruct = makeCallback(true)
	e.onExpiration,  e.expire   = makeCallback(true)

	addGetSet(e, "Velocity",        2, 0, 0)
	addGetSet(e, "AngularVelocity", 1, 0)
	addGetSet(e, "Position",        2, 0, 0)
	addGetSet(e, "Rotation",        1, 0)
	addGetSet(e, "CallSign",        1, nil)

	return e
end

function G.STBO()
	local s = Entity():setCallSign("STBO" .. math.random(100, 999))

	addGetSet(s, "Hull", 1, 0)
	addGetSet(s, "HullMax", 1, 0)

	s.systemData = {}
	s.getSystemData = function(s, sys)
		if not s.systemData[sys] then
			s.systemData[sys] = {}
		end
		return s.systemData[sys]
	end

	function s:getSystemHealthMax(sys)
		return self:getSystemData(sys).max or 1
	end
	function s:setSystemHealthMax(sys, h)
		self:getSystemData(sys).max = h
		return self
	end
	function s:getSystemHealth(sys)
		return self:getSystemData(sys).cur or 1
	end
	function s:setSystemHealth(sys, h)
		self:getSystemData(sys).cur = h
		return self
	end

	function s:setSystemPower(sys, p)
		self:getSystemData(sys).power = p
		return self
	end
	function s:getSystemPower(sys)
		return self:getSystemData(sys).power or 1
	end
	function s:setSystemPowerRequest(sys, p)
		self:getSystemData(sys).power_req = p
		return self
	end
	function s:getSystemPowerRequest(sys) -- TODO gn32-script branch only
		return self:getSystemData(sys).power_req or 1
	end

	return s
end

-- SpaceStation
function G.SpaceStation()
	local s = STBO():setCallSign("SS" .. math.random(100, 999))

	return s
end

-- SpaceShip
function G.SpaceShip()
	local s = STBO():setCallSign("SH" .. math.random(100, 999))

	addGetSet(s, "Energy", 1, 0)
	addGetSet(s, "MaxEnergy", 1, 0)

	addGetSet(s, "DockedWith", 1, nil)

	return s
end

-- CpuShip
function G.CpuShip()
	local s = SpaceShip():setCallSign("CPU" .. math.random(100, 999))

	return s
end

-- PlayerShip
G.onNewPlayerShip, G.newPlayerShip = makeCallback()
G.activePlayerShips = {}

function G.getActivePlayerShips()
	return activePlayerShips
end

function G.PlayerSpaceship()
	local s = SpaceShip():setCallSign("PS" .. math.random(100, 999))

	s.onProbeLaunch, s.probeLaunch = makeCallback(true)

	addGetSet(s, "MaxCoolant", 1, 10)
	addGetSet(s, "MaxScanProbeCount", 1, 10)
	addGetSet(s, "ScanProbeCount", 1, 10)

	s.customButtons = {}
	function s:addCustomButton(station, id, button, action)
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
	function s:addCustomInfo(station, id, info)
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
	function s:removeCustom(id)
		for i, v in ipairs(self.customButtons) do
			if v.id == id then
				table.remove(self.customButtons, i)
				return
			end
		end
	end

	return s
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
