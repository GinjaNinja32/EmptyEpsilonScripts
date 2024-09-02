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
		"Single",
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
}
