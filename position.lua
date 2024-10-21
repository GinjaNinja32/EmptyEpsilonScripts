--- Definitions and utilities for handling ship crew positions.
-- @pragma nostrip

require "gn32/lang"

--- A list of all primary positions (5-6 crew, 3-4 crew, single pilot)
-- @table position.all

--- A list of all primary 5-6 crew positions.
-- @table position.single

--- A list of all primary 3-4 crew positions.
-- @table position.combi

--- A mapping from positions in either 3-4 crew or 5-6 crew system to the equivalent position(s) in the other system.
--
-- e.g.  
-- `position.related["Helms"]` => `{"Tactical"}`  
-- `position.related["Tactical"]` => `{"Helms", "Weapons"}`
-- @table position.related

--- A mapping from positions in either 3-4 crew or 5-6 crew system to the equivalent position(s) in the 5-6 crew system.
--
-- e.g.  
-- `position.to_single["Helms"]` => `{"Helms"}`  
-- `position.to_single["Tactical"]` => `{"Helms", "Weapons"}`
-- @table position.to_single

--- A mapping from positions in either 3-4 crew or 5-6 crew system to the equivalent positions in either system.
--
-- e.g.  
-- `position.to_any["Helms"]` => `{"Helms", "Tactical"}`  
-- `position.to_any["Tactical"]` => `{"Helms", "Weapons", "Tactical"}`
-- @table position.to_any
local _ = {}

G.position = {
	all = {
		"Helms", "Weapons", "Engineering", "Science", "Relay",
		"Engineering+", "Tactical", "Operations",
		"Single", "DamageControl", "PowerManagement", "Database", "AltRelay", "ShipLog",
	},

	single = {
		"Helms", "Weapons", "Engineering", "Science", "Relay",
	},

	combi = {
		"Engineering+", "Tactical", "Operations",
	},

	related = {
		["Helms"] = {"Tactical"},
		["Weapons"] = {"Tactical"},
		["Engineering"] = {"Engineering+"},
		["Science"] = {"Operations"},
		["Relay"] = {"Operations"},

		["Engineering+"] = {"Engineering"},
		["Tactical"] = {"Helms", "Weapons"},
		["Operations"] = {"Science", "Relay"},
	},

	to_single = {
		["Helms"] = {"Helms"},
		["Weapons"] = {"Weapons"},
		["Engineering"] = {"Engineering"},
		["Science"] = {"Science"},
		["Relay"] = {"Relay"},

		["Engineering+"] = {"Engineering"},
		["Tactical"] = {"Helms", "Weapons"},
		["Operations"] = {"Science", "Relay"},
	},

	to_any = {
		["Helms"] = {"Helms", "Tactical"},
		["Weapons"] = {"Weapons", "Tactical"},
		["Engineering"] = {"Engineering", "Engineering+"},
		["Science"] = {"Science", "Operations"},
		["Relay"] = {"Relay", "Operations"},

		["Engineering+"] = {"Engineering", "Engineering+"},
		["Tactical"] = {"Helms", "Weapons", "Tactical"},
		["Operations"] = {"Science", "Relay", "Operations"},
	},

	--- A mapping from area to positions that handle that area.
	-- @table position.area_to_pos
	area_to_pos = {},
	--- A mapping from position to the areas it handles.
	-- @table position.pos_to_area
	pos_to_area = {},
}

local function define(area, ...)
	position.area_to_pos[area] = {...}
	for _, pos in ipairs{...} do
		if position.pos_to_area[pos] == nil then
			position.pos_to_area[pos] = {}
		end
		table.insert(position.pos_to_area[pos], area)
	end
end

--- Define a new area handled by a set of positions.
-- @param area The name of the new area.
-- @param ... The positions that handle this area.
function position.defineArea(area, ...)
	if position.area_to_pos[area] ~= nil then
		error("duplicate area name " .. area, 2)
	end
	define(area, ...)
end

--- Define a new area handled by a set of positions, unless the area has already been defined.
-- @param area The name of the new area.
-- @param ... The positions that handle this area.
function position.defineAreaDefault(area, ...)
	if position.area_to_pos[area] == nil then
		define(area, ...)
	end
end

--- Areas.
-- The areas defined in this module correspond to the parts of standard ship operations that are handled by each console; for example, missiles may be fired from Weapons, Tactical, or Single Pilot.
-- Other modules may define other areas by calling `position.defineArea` or `position.defineAreaDefault`; see their documentation for details on the areas they define.
-- @section Areas

--                  Area          5-6             3-4              Other

--- Move and turn the ship.
-- @table helms
position.defineArea("helms",      "Helms",        "Tactical",      "Single")
--- Select weapon targets, fire missiles.
-- @table weapons
position.defineArea("weapons",    "Weapons",      "Tactical",      "Single")
--- Raise, lower, and calibrate the shields.
-- @table shields
position.defineArea("shields",    "Weapons",      "Engineering+",  "Single")
--- Monitor and set system power and coolant levels.
-- @table power
position.defineArea("power",      "Engineering",  "Engineering+",  "PowerManagement")
--- View and repair system damage.
-- @table damage
position.defineArea("damage",     "Engineering",  "Engineering+",  "DamageControl")
--- Select and scan unknown entities, view data on scanned entities.
-- @table scan
position.defineArea("scan",       "Science",      "Operations")
--- View science database entries.
-- @table database
position.defineArea("database",   "Science",      "Operations",    "Database")
--- Add, remove, and move waypoints.
-- @table waypoints
position.defineArea("waypoints",  "Relay",        "Operations",    "AltRelay")
--- Launch scan probes.
-- @table probes
position.defineArea("probes",     "Relay",                         "AltRelay")
--- Hack other ships.
-- @table hack
position.defineArea("hack",       "Relay",                         "AltRelay")
--- View a non-ship-centred map.
-- @table map
position.defineArea("map",        "Relay",                         "AltRelay")
--- Hail other ships and stations, receive incoming hails.
-- @table comms
position.defineArea("comms",      "Relay",        "Operations",    "Single") -- plus CommsOnly, but that doesn't get custom buttons
