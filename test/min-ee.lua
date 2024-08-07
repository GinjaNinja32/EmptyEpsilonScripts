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

	e.onDestroyed, e.destroy = makeCallback(true)
	e.onDestruction, e.destruct = makeCallback(true)
	e.onExpiration, e.expire = makeCallback(true)

	function e:getCallSign()
		return self.callsign
	end
	function e:setCallSign(cs)
		self.callsign = cs
		return self
	end

	return e
end

-- PlayerShip
G.onNewPlayerShip, G.newPlayerShip = makeCallback()

function G.PlayerShip()
	local s = Entity():setCallSign("PS" .. math.random(100, 999))

	s.onProbeLaunch, s.probeLaunch = makeCallback(true)

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
