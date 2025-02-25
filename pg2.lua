--- [`hook-sys`] Utility for procedurally generating maps of various kinds.
-- Required hooks: `update`.

require "gn32/random"
require "gn32/classutil"
require "gn32/hook-sys"
require "gn32/fnhook-ee"
require "gn32/action-gm"
require "gn32/noiseplane"
require "gn32/track"

local allMaps = {}

local function _key(cx, cy)
	return cx .. "," .. cy
end
local function _unkey(k)
	local cx, cy = string.match(k, "^(-?[0-9]+),(-?[0-9]+)$")
	return tonumber(cx), tonumber(cy)
end

--- Functions .
-- @section functions

local procmap
G.Procmap, procmap = deriveClass(NoisePlane)

function Procmap.get(name)
	for _, map in ipairs(allMaps) do
		if map.name == name then
			return map
		end
	end
end

--- Create a new Procmap.
-- Procmap derives from [`NoisePlane`](noiseplane.html#NoisePlane); all functions except `sample` may be called directly.
-- @function Procmap
-- @string[opt] name The name of the map for GM debug. If not provided, defaults to "Map &lt;n&gt;".
-- @return The new Procmap instance.
function procmap:_init(name)
	if not name then
		name = "Map " .. #allMaps
	end

	table.insert(allMaps, self)

	NoisePlane._instance._init(self)

	self.name = name
	self.entities = {}
	self.opCost = 0.5
	self.offsetX = 0
	self.offsetY = 0
	self.debug = false
end

--- Set the base offset for this procmap.
-- @int x The new x offset.
-- @int[opt] y The new y offset. If not specified, defaults to `x`.
-- @return self
function procmap:setOffset(x, y)
	self.offsetX = x
	self.offsetY = y or x
	return self
end

local currentProcmap
local currentKey
function hook.on.newEntity(e)
	if currentProcmap then
		table.insert(currentProcmap.entities[currentKey], e)
	end
end

--- Set an area to restrict chunk loading to.
-- @int x0 The lowest x chunk index to allow loading.
-- @int x1 The highest x chunk index to allow loading.
-- @int[opt] y0 The lowest y chunk index to allow loading. If not specified, defaults to `x0`.
-- @int[opt] y1 The highest y chunk index to allow loading. If not specified, defaults to `x1`.
-- @return self
function procmap:setBounds(x0, x1, y0, y1)
	self.bounds = {x0, x1, y0 or x0, y1 or x1}
	return self
end

-- Override the noisePlane implementation of _posFor to make the coordinates sector-scaled and offset.
function procmap:_posFor(cx, cy, csize)
	return {
		cx = cx,
		cy = cy,

		csize = csize * 20000,

		x0 = ( cx      * csize + self.offsetX) * 20000,
		x1 = ((cx + 1) * csize + self.offsetX) * 20000,
		y0 = ( cy      * csize + self.offsetY) * 20000,
		y1 = ((cy + 1) * csize + self.offsetY) * 20000,
	}
end

--- Load a chunk by index.
-- @int cx The x index of the chunk to load.
-- @int cy The y index of the chunk to load.
-- @return `true` if the chunk was loaded by this call; otherwise `false`.
function procmap:load(cx, cy)
	if self.bounds then
		if cx < self.bounds[1] or self.bounds[2] < cx
			or cy < self.bounds[3] or self.bounds[4] < cy then
			return false
		end
	end

	local k = _key(cx, cy)
	if self.entities[k] then
		return false
	end
	self.entities[k] = {}

	currentProcmap = self
	currentKey = k

	self:sample(cx, cy)

	currentProcmap = nil

	-- apply debug settings if needed
	if self.debug then
		for _, ent in ipairs(self.entities[k]) do
			if ent.pgSetDebug then
				ent:pgSetDebug(self.debug)
			end
		end
	end

	return true
end

--- Unload all currently-loaded chunks.
function procmap:unloadAll()
	for k, ents in pairs(self.entities) do
		for _, e in ipairs(ents) do
			e:destroy()
		end
		self.entities[k] = nil
	end
end

--- Unload a chunk by index.
-- @int cx The x index of the chunk to unload.
-- @int cy The y index of the chunk to unload.
-- @return `true` if the chunk was unloaded by this call; otherwise `false`.
function procmap:unload(cx, cy)
	local k = _key(cx, cy)
	if not self.entities[k] then
		return false
	end

	for _, e in ipairs(self.entities[k]) do
		e:destroy()
	end

	self.entities[k] = nil
	return true
end

--- Set the radius for loading and unloading chunks automatically near player ships.
-- The default for a newly constructed Procmap is equivalent to passing `nil` for all parameters.
-- @int[opt] loadRadius The radius beyond a player ship's long-range radar to load chunks, or nil to not load chunks around player ships.
-- @int[opt] unloadRadius The radius beyond a player ship's long-range radar to unload chunks, or nil to not unload chunks automatically.
-- @int[opt] probeRadius The radius beyond a probe's radar range to load chunks. If nil, defaults to `loadRadius`.
function procmap:loadNearPlayer(loadRadius, unloadRadius, probeRadius)
	self.loadRadius = loadRadius
	self.unloadRadius = unloadRadius
	self.probeRadius = probeRadius or loadRadius

	if loadRadius and unloadRadius then
		unloadRadius = math.max(loadRadius, unloadRadius)
	end
	return self
end

--- Set the maximum number of chunk load/unload operations per update call for this Procmap.
-- This maximum is converted into a cost per update and shared between all Procmap instances; in case of insufficient update budget, earlier instances take priority.
-- @number n The maximum number of load/unload operations per update call.
function procmap:maxOperationsPerUpdate(n)
	self.opCost = 1 / n
	return self
end

function hook.on.update(delta)
	local budget = 1
	if delta == 0 then
		budget = 5 -- we don't care as much about framedrops if we're paused
	end

	for _, map in ipairs(allMaps) do
		budget = map:_process(budget)
		if budget <= 0 then return end
	end
end

function procmap:_boundsForRadius(x, y, radius)
	local csize = self.layers[1].size

	local cx0 = math.floor(((x - radius) / 20000 - self.offsetX) / csize)
	local cx1 = math.floor(((x + radius) / 20000 - self.offsetX) / csize)
	local cy0 = math.floor(((y - radius) / 20000 - self.offsetY) / csize)
	local cy1 = math.floor(((y + radius) / 20000 - self.offsetY) / csize)

	return cx0, cx1, cy0, cy1
end

function procmap:_process(budget)
	local keep = {}

	if self.loadRadius or self.unloadRadius then
		for _, ship in ipairs(getActivePlayerShips()) do
			local sx, sy = ship:getPosition()
			if not sx then -- TODO ECS
				sx, sy = ship:getDockedWith():getPosition()
			end

			local rr = ship:getLongRangeRadarRange()

			if self.loadRadius then
				local cx0, cx1, cy0, cy1 = self:_boundsForRadius(sx, sy, rr + self.loadRadius)

				for x = cx0, cx1 do
					for y = cy0, cy1 do
						if self:load(x, y) then
							budget = budget - self.opCost
							if budget <= 0 then return budget end
						end
					end
				end
			end

			if self.unloadRadius then
				local cx0, cx1, cy0, cy1 = self:_boundsForRadius(sx, sy, rr + self.unloadRadius)

				for x = cx0, cx1 do
					for y = cy0, cy1 do
						keep[_key(x, y)] = true
					end
				end
			end
		end
	end

	if self.probeRadius then
		track.any("probe", function(probe)
			local px, py = probe:getPosition()

			local rr = 5000 -- probe radar range fixed in code

			local cx0, cx1, cy0, cy1 = self:_boundsForRadius(px, py, rr + self.probeRadius)

			for x = cx0, cx1 do
				for y = cy0, cy1 do
					if self:load(x, y) then
						budget = budget - self.opCost
						if budget <= 0 then return true end -- break out of `track.any`, recheck budget afterwards
					end
					keep[_key(x, y)] = true
				end
			end
		end)
		if budget <= 0 then return budget end
	end

	if self.unloadRadius then
		for k in pairs(self.entities) do
			if not keep[k] then
				local cx, cy = _unkey(k)
				self:unload(cx, cy)
				budget = budget - self.opCost
				if budget <= 0 then return budget end
			end
		end
	end

	return budget
end

--- Set the debug state for this Procmap.
-- @bool on Whether debug should be enabled.
function procmap:setDebug(on)
	self.debug = on
	for _, ents in pairs(self.entities) do
		for _, ent in ipairs(ents) do
			if ent.pgSetDebug then
				ent:pgSetDebug(on)
			end
		end
	end
end

-- DEBUG ZONE

local debugZone
G.DebugZone, debugZone = makeClass()

--- Create a new DebugZone.
-- DebugZone works like Zone, but is only visible when its containing Procmap's debug flag is enabled.
-- @function DebugZone
function debugZone:_init()
	if currentProcmap then
		table.insert(currentProcmap.entities[currentKey], self)
	end
end
--- Set the points for the DebugZone.
-- @param ... The points for the zone, as Zone:setPoints(...)
-- @return self
function debugZone:setPoints(...)
	self.points = {...}
	return self
end
--- Set the color for the DebugZone.
-- @number r The amount of red.
-- @number g The amount of green.
-- @number b The amount of blue.
-- @return self
function debugZone:setColor(r, g, b)
	self.color = {r, g, b}
	return self
end
--- Set the label for the DebugZone.
-- @string label The text label for the zone.
-- @return self
function debugZone:setLabel(label)
	self.label = label
	return self
end
function debugZone:pgSetDebug(on)
	if on and not self.zone then
		self.zone = Zone()
			:setPoints(table.unpack(self.points))

		if self.color then
			self.zone:setColor(table.unpack(self.color))
		end
		if self.label then
			self.zone:setLabel(self.label)
		end
	end

	if self.zone and not on then
		self.zone:destroy()
		self.zone = nil
	end
end
function debugZone:destroy()
	if self.zone then
		self.zone:destroy()
	end
end

-- GM MENU

require "gn32/gm-numerical"

gmMenu:add {
	button = "Procgen",
	action = {
		{
			button = "Reseed/Reload All",
			action = function()
				math.randomseed(random.genseed() ~ math.floor(1000000 * getScenarioTime()))
				globalseed = random.genseed()

				for _, map in ipairs(allMaps) do
					map:unloadAll()
				end
				return false
			end,
		},
		{
			button = "Reload All",
			action = function()
				for _, map in ipairs(allMaps) do
					map:unloadAll()
				end
				return false
			end,
		},
		{
			button = function()
				local debugOn = 0
				local debugOff = 0
				for _, map in ipairs(allMaps) do
					if map.debug then
						debugOn = debugOn + 1
					end
					if not map.debug then
						debugOff = debugOff + 1
					end
				end

				if debugOn > 0 and debugOff > 0 then
					return "Debug: " .. debugOn .. "/" .. #allMaps
				end
				return "Debug: " .. (debugOn > 0 and "ON" or "OFF")
			end,
			action = function()
				local debugOn = false
				for _, map in ipairs(allMaps) do
					if map.debug then
						debugOn = true
						break
					end
				end

				for _, map in ipairs(allMaps) do
					map:setDebug(not debugOn)
				end

				return false
			end,
		},
		{
			expand = function()
				local menu = {}

				for _, map in ipairs(allMaps) do
					table.insert(menu, {
						button = map.name,
						action = {
							{
								button = "Reseed/Reload",
								action = function()
									math.randomseed(random.genseed() ~ math.floor(1000000 * getScenarioTime()))
									map:setSeed(random.genseed())
									map:unloadAll()
									return false
								end,
							},
							{
								button = "Reload",
								action = function()
									map:unloadAll()
									return false
								end,
							},
							{
								button = function() return "Debug: " .. (map.debug and "ON" or "OFF") end,
								action = function()
									map:setDebug(not map.debug)
									return false
								end,
							},
							{
								button = function()
									local c = 0
									local e = 0
									for _, ents in pairs(map.entities) do
										c = c + 1
										for _ in ipairs(ents) do
											e = e + 1
										end
									end
									return "C:" .. c .. " E:" .. e
								end,
								action = false,
							},
							{
								when = function() return map.loadRadius end,
								expand = makeNumericalOperations(
									"Load Range",
									function() return map.loadRadius end,
									function() return math.floor(map.loadRadius / 1000) .. "U" end,
									function(n)
										map.loadRadius = math.max(1000, n)
										if map.unloadRadius < map.loadRadius then
											map.unloadRadius = map.loadRadius
										end
										return false
									end
								),
							},
							{
								when = function() return map.unloadRadius end,
								expand = makeNumericalOperations(
									"Unload Range",
									function() return map.unloadRadius end,
									function() return math.floor(map.unloadRadius / 1000) .. "U" end,
									function(n)
										map.unloadRadius = math.max(1000, n)
										if map.unloadRadius < map.loadRadius then
											map.loadRadius = map.unloadRadius
										end
										if map.unloadRadius < map.probeRadius then
											map.probeRadius = map.unloadRadius
										end
										return false
									end
								),
							},
							{
								when = function() return map.probeRadius end,
								expand = makeNumericalOperations(
									"Probe Range",
									function() return map.probeRadius end,
									function() return math.floor(map.probeRadius / 1000) .. "U" end,
									function(n)
										map.probeRadius = math.max(1000, n)
										if map.unloadRadius < map.probeRadius then
											map.unloadRadius = map.probeRadius
										end
										return false
									end
								),
							},
						},
					})
				end

				return menu
			end,
		}
	},
}
