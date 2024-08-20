-- Module: gn32/position
-- Description: Definitions and utilities for handling ship crew positions
--[[
	Definitions:
		position.all: A list of all primary positions (3-4 or 5-6 crew)

		position.single: A list of all single-duty positions (5-6 crew)

		position.combi: A list of all combination-duty positions (3-4 crew)

		position.related: A mapping from crew positions to the related position(s) in the other system, e.g. Helms=>{Tactical}, Operations=>{Science,Relay}

		position.to_single: A mapping from crew positions to their single-duty equivalent(s), e.g. Helms=>{Helms}, Operations=>{Science,Relay}

		position.to_any: A mapping from crew positions to their equivalent(s) in any system, e.g. Helms=>{Helms,Tactical}, Operations=>{Science,Relay,Operations}
]]

require "gn32/lang"

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
